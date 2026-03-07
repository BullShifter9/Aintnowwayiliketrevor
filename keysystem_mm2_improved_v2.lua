local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GetPlayerData = game.ReplicatedStorage:FindFirstChild("GetPlayerData", true)
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local GameplayEvents = ReplicatedStorage.Remotes.Gameplay
local AutoNotifyEnabled = false -- legacy; kept for compatibility (use autoNotifyEnabled instead)
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local SupportedGameID = 142823291 -- Murder Mystery 2 Place ID

if game.PlaceId ~= SupportedGameID then
 LocalPlayer:Kick("Game Not Supported\n\nSupported Games:\nMurder Mystery 2")
end

-- ════════════════════════════════════════════════════════════════
--  NOTE: Auth, HWID, and key validation are handled by Loader.lua
--  This script executes ONLY after Loader.lua confirms full auth.
-- ════════════════════════════════════════════════════════════════

-- Global State Management
local state = {
 roles = {},
 murder = nil,
 sheriff = nil,
 hero = false,
 gunDrop = nil,
 autoGetGunDropEnabled = false,
 murdererNearDistance = 15,
 roleCallbacks = {} -- functions fired every Fade event (auto-notifiers, etc.)
}


--Prediction State
local predictionState = {
 pingEnabled = false,
 pingValue = 50
}


-- ================================================================
-- ================================================================
-- ESP SYSTEM  (Optimised — single unified RenderStepped loop)
-- Previously: N players × 4 types = up to 40+ separate RenderStepped
-- connections each firing at 60 fps → massive callback overhead.
-- Now: ONE RenderStepped drives all ESP for all players in a single pass.
-- Highlights still use Roblox's native Highlight instance (GPU-side),
-- but their colour is refreshed at 15 fps (every 4 frames) not 60.
-- GunDrop ESP is also folded into the same loop.
-- ================================================================

-- ── Shared drawing stores (no connections — driven by unified loop) ──
local ESP = {
    Text      = {},   -- [playerName] = Drawing "Text"
    Box       = {},   -- [playerName] = { lines={8×Line} }
    Tracer    = {},   -- [playerName] = Drawing "Line"
    Highlight = {},   -- [playerName] = { folder, hl, respawnConn }
}

-- Active-player set: players currently being drawn
local espActivePlayers = {}    -- [playerName] = Player

-- Per-toggle flags
local espTextOn, espBoxOn, espTracerOn, espHighlightOn = false, false, false, false

-- GunDrop ESP state (also driven by unified loop)
local gunDropESP = { tracer = nil, label = nil, pulse = 0 }
local gunDropESPEnabled = false

-- ── Role colours ─────────────────────────────────────────────────
local function espRoleColor(player)
    if player.Name == state.murder then
        return "Murderer", Color3.fromRGB(255, 0, 0)
    elseif player.Name == state.sheriff then
        if state.hero then
            return "Hero",    Color3.fromRGB(255, 215, 0)
        else
            return "Sheriff", Color3.fromRGB(0, 100, 255)
        end
    else
        return "Innocent", Color3.fromRGB(0, 200, 0)
    end
end

local function highlightRoleColors(player)
    if player.Name == state.murder then
        return Color3.fromRGB(255, 40, 40), Color3.fromRGB(255, 0, 0)
    elseif player.Name == state.sheriff then
        if state.hero then
            return Color3.fromRGB(255, 200, 0),  Color3.fromRGB(255, 215, 0)
        else
            return Color3.fromRGB( 20, 110, 255), Color3.fromRGB(  0,  90, 255)
        end
    else
        return Color3.fromRGB(0, 190, 0), Color3.fromRGB(60, 255, 60)
    end
end

local function espRoot(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- ── Per-player add / remove (create drawing objects only) ────────
local function addTextESP(player)
    if ESP.Text[player.Name] then return end
    local d = Drawing.new("Text")
    d.Outline = true
    d.OutlineColor = Color3.fromRGB(255, 255, 255)
    d.Size = 16; d.Font = 3; d.Center = true; d.Visible = false
    ESP.Text[player.Name] = d
    espActivePlayers[player.Name] = player
end

local function removeTextESP(player)
    local d = ESP.Text[player.Name]; if not d then return end
    d:Remove(); ESP.Text[player.Name] = nil
    if not ESP.Box[player.Name] and not ESP.Tracer[player.Name] and not ESP.Highlight[player.Name] then
        espActivePlayers[player.Name] = nil
    end
end

local function addBoxESP(player)
    if ESP.Box[player.Name] then return end
    local lines = {}
    for i = 1, 8 do
        local l = Drawing.new("Line")
        l.Thickness = 2; l.Transparency = 1; l.Visible = false
        lines[i] = l
    end
    ESP.Box[player.Name] = { lines = lines }
    espActivePlayers[player.Name] = player
end

local function removeBoxESP(player)
    local e = ESP.Box[player.Name]; if not e then return end
    for _, l in ipairs(e.lines) do l:Remove() end
    ESP.Box[player.Name] = nil
    if not ESP.Text[player.Name] and not ESP.Tracer[player.Name] and not ESP.Highlight[player.Name] then
        espActivePlayers[player.Name] = nil
    end
end

local function addTracerESP(player)
    if ESP.Tracer[player.Name] then return end
    local d = Drawing.new("Line")
    d.Thickness = 2; d.Transparency = 1; d.Visible = false
    ESP.Tracer[player.Name] = d
    espActivePlayers[player.Name] = player
end

local function removeTracerESP(player)
    local d = ESP.Tracer[player.Name]; if not d then return end
    d:Remove(); ESP.Tracer[player.Name] = nil
    if not ESP.Text[player.Name] and not ESP.Box[player.Name] and not ESP.Highlight[player.Name] then
        espActivePlayers[player.Name] = nil
    end
end

local function addHighlightESP(player)
    if ESP.Highlight[player.Name] then return end
    local folder = Instance.new("Folder")
    folder.Name  = "HL_" .. player.Name
    folder.Parent = CoreGui
    local hl = Instance.new("Highlight")
    hl.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency  = 0.42
    hl.OutlineTransparency = 0.00
    hl.Parent            = folder
    if player.Character then hl.Adornee = player.Character end
    local respawnConn = player.CharacterAdded:Connect(function(char)
        task.wait(0.1); hl.Adornee = char
    end)
    ESP.Highlight[player.Name] = { folder = folder, hl = hl, respawnConn = respawnConn }
    espActivePlayers[player.Name] = player
end

local function removeHighlightESP(player)
    local e = ESP.Highlight[player.Name]; if not e then return end
    e.respawnConn:Disconnect()
    e.folder:Destroy()
    ESP.Highlight[player.Name] = nil
    if not ESP.Text[player.Name] and not ESP.Box[player.Name] and not ESP.Tracer[player.Name] then
        espActivePlayers[player.Name] = nil
    end
end

local function removeAllESP(player)
    removeTextESP(player); removeBoxESP(player)
    removeTracerESP(player); removeHighlightESP(player)
    espActivePlayers[player.Name] = nil
end

local function startGunDropESP()
    if gunDropESP.tracer then return end
    local t = Drawing.new("Line")
    t.Thickness = 2; t.Transparency = 1
    t.Color = Color3.fromRGB(255, 215, 0); t.Visible = false
    local l = Drawing.new("Text")
    l.Size = 14; l.Font = 3; l.Center = true; l.Outline = true
    l.OutlineColor = Color3.fromRGB(0, 0, 0)
    l.Color = Color3.fromRGB(255, 215, 0); l.Visible = false
    gunDropESP.tracer = t; gunDropESP.label = l
end

local function stopGunDropESP()
    if gunDropESP.tracer then gunDropESP.tracer:Remove(); gunDropESP.tracer = nil end
    if gunDropESP.label  then gunDropESP.label:Remove();  gunDropESP.label  = nil end
end

-- ── UNIFIED ESP RENDER LOOP (ONE connection for everything) ───────
-- Frame budget breakdown at 60 fps:
--   Text + Tracer: every frame (need smooth motion)
--   Box:           every 2 frames (30 fps — still smooth)
--   Highlight col: every 4 frames (15 fps — role change is rare)
--   GunDrop ESP:   every frame (needs pulse + smooth tracer)
local espFrame = 0
RunService.RenderStepped:Connect(function()
    espFrame = espFrame + 1
    local cam         = workspace.CurrentCamera
    local camCF       = cam.CFrame
    local camPos      = camCF.Position
    local vpSize      = cam.ViewportSize
    local screenCenX  = vpSize.X * 0.5
    local screenBotY  = vpSize.Y

    -- ── Player ESP ───────────────────────────────────────────────
    for name, player in pairs(espActivePlayers) do
        local root = espRoot(player)
        if not root then
            -- Player has no character — hide everything
            local td = ESP.Text[name];    if td then td.Visible = false end
            local tb = ESP.Box[name]
            if tb then for i=1,8 do tb.lines[i].Visible = false end end
            local tt = ESP.Tracer[name];  if tt then tt.Visible = false end
            local th = ESP.Highlight[name]
            if th then th.hl.Enabled = false end
        else
            local rp      = root.Position
            local _, color = espRoleColor(player)

            -- ── Text ESP (every frame) ──────────────────────────
            local td = ESP.Text[name]
            if td then
                local sp, onScr = cam:WorldToViewportPoint((root.CFrame * CFrame.new(0, 6.5, 0)).Position)
                local dist = (rp - camPos).Magnitude
                local scaledSize = dist / 20
                td.Size     = scaledSize >= 17 and 3 or math.clamp(20 - scaledSize, 8, 20)
                td.Color    = color
                td.Position = Vector2.new(sp.X, sp.Y)
                local role, _ = espRoleColor(player)
                td.Text     = string.format("%s [%s] %d", player.Name, role, math.floor(dist))
                td.Visible  = onScr
            end

            -- ── Tracer ESP (every frame) ────────────────────────
            local tt = ESP.Tracer[name]
            if tt then
                local sp, onScr = cam:WorldToViewportPoint(rp + Vector3.new(0, -2.5, 0))
                tt.Color   = color
                tt.From    = Vector2.new(screenCenX, screenBotY)
                tt.To      = Vector2.new(sp.X, sp.Y)
                tt.Visible = onScr
            end

            -- ── Box ESP (every 2 frames) ────────────────────────
            local tb = ESP.Box[name]
            if tb and espFrame % 2 == 0 then
                local cf  = CFrame.lookAt(rp, camPos)
                local sz  = Vector3.new(3.5, 1.5, 1.5) * 1.35
                local tlW, tlV = cam:WorldToViewportPoint((cf * CFrame.new( sz.X, sz.Y, 0)).Position)
                local trW      = cam:WorldToViewportPoint((cf * CFrame.new(-sz.X, sz.Y, 0)).Position)
                local blW      = cam:WorldToViewportPoint((cf * CFrame.new( sz.X,-sz.Y, 0)).Position)
                local brW      = cam:WorldToViewportPoint((cf * CFrame.new(-sz.X,-sz.Y, 0)).Position)
                local tl = Vector2.new(tlW.X, tlW.Y); local tr2 = Vector2.new(trW.X, trW.Y)
                local bl = Vector2.new(blW.X, blW.Y); local br2 = Vector2.new(brW.X, brW.Y)
                local cw = (tr2-tl).Magnitude*0.25;   local ch = (bl-tl).Magnitude*0.25
                local ln = tb.lines
                ln[1].From=tl; ln[1].To=tl+Vector2.new( cw,  0)
                ln[2].From=tl; ln[2].To=tl+Vector2.new(  0, ch)
                ln[3].From=tr2;ln[3].To=tr2+Vector2.new(-cw, 0)
                ln[4].From=tr2;ln[4].To=tr2+Vector2.new(  0, ch)
                ln[5].From=br2;ln[5].To=br2+Vector2.new(-cw, 0)
                ln[6].From=br2;ln[6].To=br2+Vector2.new(  0,-ch)
                ln[7].From=bl; ln[7].To=bl+Vector2.new( cw,  0)
                ln[8].From=bl; ln[8].To=bl+Vector2.new(  0,-ch)
                for i=1,8 do ln[i].Color=color; ln[i].Visible=tlV end
            end

            -- ── Highlight colour (every 4 frames) ────────────────
            local th = ESP.Highlight[name]
            if th and espFrame % 4 == 0 then
                local fillCol, outlineCol = highlightRoleColors(player)
                th.hl.FillColor    = fillCol
                th.hl.OutlineColor = outlineCol
                th.hl.Enabled      = true
            end
        end
    end

    -- ── GunDrop ESP (every frame) ─────────────────────────────
    if gunDropESPEnabled and gunDropESP.tracer then
        local gd = state.gunDrop
        local gdPos
        if gd and gd.Parent then
            if gd:IsA("BasePart") then
                gdPos = gd.Position
            elseif gd:IsA("Model") then
                local p = gd:FindFirstChildWhichIsA("BasePart")
                if p then gdPos = p.Position end
            end
        end
        if gdPos then
            local sp,  onScr = cam:WorldToViewportPoint(gdPos)
            local lp         = cam:WorldToViewportPoint(gdPos + Vector3.new(0, 3, 0))
            gunDropESP.pulse = (gunDropESP.pulse + 0.05) % (math.pi * 2)
            local t = (math.sin(gunDropESP.pulse) + 1) * 0.5
            local pc = Color3.fromRGB(255, math.floor(215 + t*40), math.floor(t*180))
            local dist = (gdPos - camPos).Magnitude
            local gdt, gdl = gunDropESP.tracer, gunDropESP.label
            gdt.Color = pc
            gdt.From  = Vector2.new(screenCenX, screenBotY)
            gdt.To    = Vector2.new(sp.X, sp.Y)
            gdt.Visible = onScr
            gdl.Color   = pc
            gdl.Position = Vector2.new(lp.X, lp.Y)
            gdl.Text    = string.format("GUN DROP [%d studs]", math.floor(dist))
            gdl.Visible = onScr
        else
            gunDropESP.tracer.Visible = false
            gunDropESP.label.Visible  = false
        end
    end
end)

Players.PlayerRemoving:Connect(function(p) removeAllESP(p) end)

-- ================================================================
-- ROLE DATA TABLE (mirrors KC8WAJ6's "R" table)
-- Populated fresh by Fade event; kept current by zK() on mid-round events.
-- R[playerName] = { Role, Effect, Died, Killed }
-- ================================================================
local R = {}
local localRole = "Innocent"

-- Perk definitions: keyed by perk ID (e.g. "Ghost", "FakeGun", "VampireBat")
-- Source: ReplicatedStorage.Database.Sync.Perks (the real game module)
-- R[playerName].Perk = perk ID string the murderer has equipped this round
local PerkDefs = {}
pcall(function()
    local m = require(ReplicatedStorage.Database.Sync.Perks)
    if type(m) == "table" then PerkDefs = m end
end)

-- Resolve a perk ID to its display name
-- e.g. "FakeGun" -> "Fake Gun",  "VampireBat" -> "Bat Form",  "Xray" -> "X-Ray"
local function resolvePerkName(perkKey)
    if not perkKey or perkKey == "" then return nil end
    -- Direct lookup by table key (e.g. PerkDefs["Ghost"].Name)
    if PerkDefs[perkKey] and PerkDefs[perkKey].Name then
        return PerkDefs[perkKey].Name
    end
    -- Fallback: scan by Name field (in case key and name differ)
    for _, def in pairs(PerkDefs) do
        if def.Name == perkKey then return def.Name end
    end
    -- Last resort: return raw key
    return perkKey
end

-- GetPlayerData remote (RemoteFunction) — used by zK() for fresh mid-round data
local GetPlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)

-- ----------------------------------------------------------------
-- zK() — exact port of KC8WAJ6's function of the same name.
-- Fetches fresh R from server then re-parses all roles from scratch.
-- Critical transitions handled:
-- • Sheriff dies → state.sheriff cleared
-- • Innocent grabs dropped gun → state.sheriff=them, state.hero=true
-- ----------------------------------------------------------------
local function zK()
 -- Fetch fresh player data (KC8WAJ6: R = z.Function(A.Remotes.Extras.GetPlayerData))
 if GetPlayerDataRemote then
 local ok, freshR = pcall(function()
 return GetPlayerDataRemote:InvokeServer()
 end)
 if ok and type(freshR) == "table" then
 -- Merge freshR with any pending-hero promotions we already made locally.
 -- The server update lags behind by one RTT; never let it un-hero a player
 -- we just promoted until pendingHeroUntil[name] expires (2 s).
 local now = tick()
 for name, expiry in pairs(pendingHeroUntil) do
 if now < expiry then
 if freshR[name] then
 freshR[name].Role = "Hero"
 end
 else
 pendingHeroUntil[name] = nil
 end
 end
 R = freshR
 end
 end

 -- Derive local role
 localRole = (R[LocalPlayer.Name] and R[LocalPlayer.Name].Role) or "Innocent"

 -- Full reset before re-parsing — prevents stale sheriff/murderer after death
 state.murder = nil
 state.sheriff = nil
 state.hero = false

 for playerName, playerData in pairs(R) do
 if not playerData.Died and not playerData.Killed then
 local plr = Players:FindFirstChild(playerName)
 if plr and plr.Character then
 if playerData.Role == "Murderer" then
 state.murder = playerName

 elseif playerData.Role == "Sheriff" then
 state.sheriff = playerName
 state.hero = false

 elseif playerData.Role == "Hero" then
 state.sheriff = playerName
 state.hero = true

 else
 -- KC8WAJ6 exact: scan Character then Backpack for Gun tool
 -- → innocent picked up the dropped gun → becomes Hero
 local foundGun = false
 for _, item in pairs(plr.Character:GetChildren()) do
 if item.Name == "Gun" and item:IsA("Tool") then
 state.sheriff = playerName
 state.hero = true
 foundGun = true
 if playerName == LocalPlayer.Name then
 localRole = "Hero"
 end
 break
 end
 end
 if not foundGun and state.sheriff ~= playerName then
 for _, item in pairs(plr.Backpack:GetChildren()) do
 if item.Name == "Gun" and item:IsA("Tool") then
 state.sheriff = playerName
 state.hero = true
 if playerName == LocalPlayer.Name then
 localRole = "Hero"
 end
 break
 end
 end
 end
 end
 end
 end
 end
end

-- Fade event: server delivers the complete fresh R at round start
-- (KC8WAJ6: A.Remotes.Gameplay.Fade.OnClientEvent:Connect(function(o) R=o ... end))
GameplayEvents.Fade.OnClientEvent:Connect(function(fadeData)
 R = fadeData
 localRole = (R[LocalPlayer.Name] and R[LocalPlayer.Name].Role) or "Innocent"

 -- Reset and parse immediately from the Fade payload
 state.murder = nil
 state.sheriff = nil
 state.hero = false

 for playerName, playerData in pairs(R) do
 if not playerData.Died and not playerData.Killed then
 if playerData.Role == "Murderer" then
 local plr = Players:FindFirstChild(playerName)
 if plr and plr.Character then state.murder = playerName end
 elseif playerData.Role == "Sheriff" then
 local plr = Players:FindFirstChild(playerName)
 if plr and plr.Character then
 state.sheriff = playerName
 state.hero = false
 end
 elseif playerData.Role == "Hero" then
 local plr = Players:FindFirstChild(playerName)
 if plr and plr.Character then
 state.sheriff = playerName
 state.hero = true
 end
 end
 end
 end

 -- Fire role callbacks (auto notifier, etc.)
 for _, cb in pairs(state.roleCallbacks or {}) do
 coroutine.wrap(cb)()
 end
end)

-- UpdatePlayerData: server signals mid-round change (death, gun pick-up, etc.)
-- KC8WAJ6: A.UpdatePlayerData.OnClientEvent:Connect(zK)
local UpdatePlayerData = ReplicatedStorage:FindFirstChild("UpdatePlayerData") or
 ReplicatedStorage:FindFirstChild("UpdatePlayerData", true)
if UpdatePlayerData then
 UpdatePlayerData.OnClientEvent:Connect(zK)
end

-- Mid-game startup role sync 
-- If executed mid-round the Fade event will never fire, so R is empty and
-- state.murder/sheriff are nil. Pull fresh data right now (KC8WAJ6: zK on init).
task.spawn(function()
 task.wait(0.25) -- tiny yield so remotes are fully reachable
 zK()
 -- After roles are loaded, fire any registered role-state callbacks
 -- (auto-notifier, etc.) so the user sees info immediately on exec.
 if state.murder or state.sheriff then
 for _, cb in pairs(state.roleCallbacks or {}) do
 coroutine.wrap(cb)()
 end
 end
end)

-- workspace.ChildRemoved: GunDrop removed = someone picked up the gun
-- KC8WAJ6: workspace.ChildRemoved:Connect(function() task.spawn(function() task.wait(); zK() end) end)
workspace.ChildRemoved:Connect(function(child)
 if child.Name == "GunDrop" then
 task.spawn(function()
 task.wait() -- brief wait for server to update R
 zK()
 end)
 end
end)

-- RoundEndFade: all players dead, clear roles
GameplayEvents.RoundEndFade.OnClientEvent:Connect(function()
 for _, playerData in pairs(R) do
 playerData.Died = true
 playerData.Killed = true
 end
 state.murder = nil
 state.sheriff = nil
 state.hero = false
 -- Clear per-round tables so next round starts fresh
 gunPickupDebounce = {}
 pendingHeroUntil  = {}
end)

-- Gun Drop Tracking (state.gunDrop for ESP tracer/label)
workspace.DescendantAdded:Connect(function(descendant)
 if descendant.Name == "GunDrop" then
 state.gunDrop = descendant
 end
end)

workspace.DescendantRemoving:Connect(function(descendant)
 if descendant.Name == "GunDrop" then
 state.gunDrop = nil
 end
end)

-- Real-time Hero detection (KC8WAJ6 pattern) 
-- Per-player debounce: prevents multiple ChildAdded listeners (backpack + char
-- + one new hook per CharacterAdded across rounds) all firing at once.
local gunPickupDebounce = {}

-- "Pending hero" protection: when we promote a player to Hero locally,
-- record it here so zK() won't reset them for 2 s (server update lag).
local pendingHeroUntil = {}  -- [playerName] = tick() + 2

-- Atomically promotes an innocent to Hero: updates state, R cache, ESP, notifier.
-- Safe to call multiple times — debounce makes it fire exactly once.
local function promoteToHero(player)
    local now = tick()
    -- Debounce: one notification per 3-second window per player
    if gunPickupDebounce[player.Name] and (now - gunPickupDebounce[player.Name]) < 3 then
        return
    end
    gunPickupDebounce[player.Name] = now

    -- 1. Immediate state update — ESP sees Hero colour on the very next frame
    state.sheriff = player.Name
    state.hero    = true
    if player.Name == LocalPlayer.Name then
        localRole = "Hero"
    end

    -- 2. Update R cache safely (R[name] may be nil mid-game injection)
    if not R[player.Name] then
        R[player.Name] = { Role = "Hero", Died = false, Killed = false }
    else
        R[player.Name].Role = "Hero"
    end

    -- 3. Protect against zK() overwriting us for 2 s (server is still delayed)
    pendingHeroUntil[player.Name] = now + 2

    -- 4. Single notification
    pcall(function()
        Fluent:Notify({
            Title = "🔫 Gun Grabbed!",
            Content = player.Name .. " picked up the gun → now Hero!",
            Duration = 5
        })
    end)
end

-- When an innocent picks up the dropped gun mid-round, their Role in R is still
-- "Innocent" — the server updates R after a small delay. We watch each player's
-- Character and Backpack for a "Gun" Tool addition and immediately promote them.
local function watchPlayerForGunPickup(player)
 local function onGunAdded(child)
 if child.Name == "Gun" and child:IsA("Tool") then
 -- Guard: don't promote if they're already murderer / sheriff / hero
 local pd = R[player.Name]
 local role = pd and pd.Role or "Innocent"
 if role ~= "Murderer" and role ~= "Sheriff" and role ~= "Hero" then
     promoteToHero(player)
 end
 end
 end

 local function watchContainer(container)
 if not container then return end
 container.ChildAdded:Connect(onGunAdded)
 end

 -- Safe backpack access — Backpack may not exist yet when player joins
 local bp = player:FindFirstChild("Backpack")
 if bp then
 watchContainer(bp)
 else
 task.spawn(function()
 bp = player:WaitForChild("Backpack", 10)
 watchContainer(bp)
 end)
 end

 -- Watch character whenever it spawns (gun equipped = in Character)
 local function hookCharacter(char)
 if char then watchContainer(char) end
 end
 if player.Character then hookCharacter(player.Character) end
 player.CharacterAdded:Connect(hookCharacter)
end

-- Wire up all current players
for _, player in ipairs(Players:GetPlayers()) do
 if player ~= LocalPlayer then
 watchPlayerForGunPickup(player)
 end
end

-- Player Management — wire new players into whichever ESP types are active
Players.PlayerAdded:Connect(function(player)
 if espTextOn then addTextESP(player) end
 if espBoxOn then addBoxESP(player) end
 if espTracerOn then addTracerESP(player) end
 if espHighlightOn then addHighlightESP(player) end
 watchPlayerForGunPickup(player)
end)



local function GetMurderer()
 for _, player in ipairs(Players:GetPlayers()) do
 if player.Name == state.murder then
 return player
 end
 end
 return nil
end

-- ================================================================
-- AUTO COIN FARM  (Optimised)
--
-- Problem with original: workspace:GetDescendants() ran inside
-- RunService.Heartbeat — scanning every instance in the game 60×/sec.
-- With 300+ workspace descendants that's ~18,000 table lookups/sec.
--
-- Fix:
--   • liveCoinCache: populated via DescendantAdded/DescendantRemoving
--     so the coin list is always current with zero scan cost.
--   • Farming loop runs in task.spawn with task.wait(0.05) — ~20 fps
--     which is plenty for coin collection, not 60 fps.
--   • Nearest-coin search is O(coins) not O(all descendants).
--   • wait() replaced with task.wait() (non-blocking).
-- ================================================================

local CurrentTarget     = nil
local AutoCoin          = false
local AutoCoinOperator  = false
local CoinFound         = false
local TweenSpeed        = 0.08

-- Coin part (anchor that tweens toward the coin)
local autoCoinPart = Instance.new("Part")
autoCoinPart.Name         = "AutoCoinPart"
autoCoinPart.Color        = Color3.new(0, 0, 0)
autoCoinPart.Material     = Enum.Material.Plastic
autoCoinPart.Transparency = 1
autoCoinPart.Position     = Vector3.new(0, 10000, 0)
autoCoinPart.Size         = Vector3.new(1, 0.5, 1)
autoCoinPart.CastShadow   = false
autoCoinPart.Anchored     = true
autoCoinPart.CanCollide   = false
autoCoinPart.Parent       = workspace

-- Live coin cache: maintained by DescendantAdded / DescendantRemoving
-- Never scan GetDescendants() — just read this table.
local liveCoinCache = {}

local function isCoinPart(inst)
    return inst:IsA("BasePart") and
           (inst.Name == "Coin_Server" or inst.Name == "SnowToken")
end

-- Seed cache with any coins already in workspace
for _, v in ipairs(workspace:GetDescendants()) do
    if isCoinPart(v) then liveCoinCache[v] = true end
end

workspace.DescendantAdded:Connect(function(v)
    if isCoinPart(v) then liveCoinCache[v] = true end
end)
workspace.DescendantRemoving:Connect(function(v)
    liveCoinCache[v] = nil
end)

-- Find nearest coin from the live cache (O(coins) not O(all descendants))
local function findNearestCoin(rootPos)
    local best, bestDist = nil, math.huge
    for coin in pairs(liveCoinCache) do
        if coin and coin.Parent then
            local d = (rootPos - coin.Position).Magnitude
            if d < bestDist then best = coin; bestDist = d end
        else
            liveCoinCache[coin] = nil  -- stale entry — prune
        end
    end
    return best
end

-- Coin farm loop (task.spawn, ~20 fps — not Heartbeat)
task.spawn(function()
    while true do
        task.wait(0.05)

        if not AutoCoin then
            -- Clean up physics controllers when toggled off
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                for _, part in ipairs(character:GetChildren()) do
                    if part:IsA("BasePart") and (part.Name == "Head" or part.Name:match("Torso")) then
                        for _, child in ipairs(part:GetChildren()) do
                            if child.Name == "Auto Farm Gyro" or child.Name == "Auto Farm Velocity" then
                                child:Destroy()
                            end
                        end
                    end
                end
                if humanoid then humanoid.PlatformStand = false end
            end
            CoinFound = false
            AutoCoinOperator = false
        elseif not AutoCoinOperator then

        local character = LocalPlayer.Character
        local root     = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if character and root and humanoid then

        AutoCoinOperator = true
        autoCoinPart.CFrame = root.CFrame

        local coin = findNearestCoin(root.Position)
        if coin then
            CoinFound = true

            -- Lie-down controllers
            local gyroCF = root.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(90))
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") and (part.Name == "Head" or part.Name:match("Torso")) then
                    if not part:FindFirstChild("Auto Farm Gyro") then
                        local bg = Instance.new("BodyGyro")
                        bg.Name = "Auto Farm Gyro"; bg.P = 90000
                        bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = gyroCF; bg.Parent = part
                    end
                    if not part:FindFirstChild("Auto Farm Velocity") then
                        local bv = Instance.new("BodyVelocity")
                        bv.Name = "Auto Farm Velocity"
                        bv.Velocity  = (coin.Position - root.Position).Unit * 50
                        bv.MaxForce  = Vector3.new(9e9,9e9,9e9); bv.Parent = part
                    end
                end
            end
            humanoid.PlatformStand = true

            local dist = (root.Position - coin.Position).Magnitude
            TweenSpeed = dist >= 80 and 4 or math.max(dist / 23, 0.05)

            local tweenInfo = TweenInfo.new(TweenSpeed, Enum.EasingStyle.Linear)
            local tween = game:GetService("TweenService"):Create(
                autoCoinPart, tweenInfo, { CFrame = coin.CFrame }
            )
            tween:Play()

            -- Track position during tween
            local elapsed = 0
            while elapsed < TweenSpeed do
                task.wait(0.05)
                elapsed = elapsed + 0.05
                if root and root.Parent then
                    root.CFrame = autoCoinPart.CFrame
                    humanoid.PlatformStand = true
                end
            end

            liveCoinCache[coin] = nil  -- mark collected before Parent removal
            pcall(function() coin.Parent = nil end)

            TweenSpeed = 0.08
            CurrentTarget = nil
            CoinFound = false
        end  -- if coin

        AutoCoinOperator = false
        end  -- if character and root and humanoid
    end  -- elseif not AutoCoinOperator
    end  -- while true
end)




local function predictMurderV2(murderer)
 local character = murderer.Character
 if not character then return nil end

 local rootPart = character:FindFirstChild("HumanoidRootPart")
 local humanoid = character:FindFirstChild("Humanoid")
 if not rootPart or not humanoid then return nil end

 local PHYSICS = {
 MICRO_TICK = 1/360, -- Fine-grained physics simulation step
 MACRO_TICK = 1/60, -- Game tick rate
 GRAVITY = workspace.Gravity, -- Dynamic gravity from workspace
 TERMINAL_VELOCITY = -196.2, -- Terminal falling velocity
 PREDICTION_WINDOW = 1.8, -- Shorter window for more accuracy
 SAMPLE_COUNT = 60, -- Increased samples for better pattern recognition
 PATTERN_DEPTH = 8, -- Deeper pattern analysis
 GROUND_OFFSET = 3.2, -- More precise ground detection
 MAX_SPEED_MULTIPLIER = 1.35 -- Realistic speed cap
 }

 local PROBABILITY = {
 VELOCITY_WEIGHT = 0.88, -- Decreased to account for unpredictable player input
 PATTERN_WEIGHT = 0.82, -- Decreased for more realistic prediction
 MOMENTUM_WEIGHT = 0.92, -- Increased to better account for physics
 DIRECTION_WEIGHT = 0.85, -- Balanced for natural movement
 GROUND_WEIGHT = 0.96, -- Improved ground movement prediction
 AIR_WEIGHT = 0.78, -- Decreased for less predictable air movement
 CONFIDENCE_DECAY = 0.975, -- Slower decay for more stable predictions
 MIN_CONFIDENCE = 0.80 -- Lower threshold to adapt to more scenarios
 }

 local MOVEMENT = {
 GROUND_FRICTION = {
 LINEAR = 0.94, -- Increased friction for more realistic deceleration
 ANGULAR = 0.92, -- Improved turning physics
 SURFACE = { -- Surface-specific friction
 DEFAULT = 0.96,
 SMOOTH = 0.98,
 ROUGH = 0.85
 }
 },
 AIR_RESISTANCE = {
 LINEAR = 0.988, -- More realistic air resistance
 ANGULAR = 0.98, -- Better aerial turning
 TURBULENCE = 0.08 -- Reduced random turbulence for stability
 },
 MOMENTUM = {
 CONSERVATION = 0.97, -- Better momentum conservation
 TRANSFER = 0.92, -- Improved momentum transfer in collisions
 DECAY = 0.96 -- Slower momentum decay
 },
 JUMP = {
 COOLDOWN = 0.25, -- Jump cooldown estimation
 FORCE = 50, -- Approximate jump force
 DETECTION_THRESHOLD = 4.5 -- Distance to detect jumps
 }
 }

 local state = {
 position = rootPart.Position,
 velocity = rootPart.AssemblyLinearVelocity,
 velocityHistory = table.create(PHYSICS.SAMPLE_COUNT),
 positionHistory = table.create(PHYSICS.SAMPLE_COUNT),
 directionHistory = table.create(PHYSICS.SAMPLE_COUNT),
 timeHistory = table.create(PHYSICS.SAMPLE_COUNT),
 patterns = {},
 groundContact = true,
 lastJumpTime = 0,
 confidenceScore = 1.0,
 predictionAccuracy = 1.0,
 lastCalculationTime = tick(),
 surfaceType = "DEFAULT"
 }

 -- Initialize historical data with timestamps
 local function initializeHistoricalData()
 local currentTime = tick()
 for i = 1, PHYSICS.SAMPLE_COUNT do
 state.velocityHistory[i] = state.velocity
 state.positionHistory[i] = state.position
 state.directionHistory[i] = state.velocity.Unit
 state.timeHistory[i] = currentTime - ((PHYSICS.SAMPLE_COUNT - i) * PHYSICS.MACRO_TICK)
 end
 end
 initializeHistoricalData()

 -- Get surface type based on material
 local function detectSurfaceType(hit)
 if not hit or not hit.Material then return "DEFAULT" end
 
 local material = hit.Material
 if material == Enum.Material.Ice or 
 material == Enum.Material.Glass or 
 material == Enum.Material.SmoothPlastic then
 return "SMOOTH"
 elseif material == Enum.Material.Grass or 
 material == Enum.Material.Sand or 
 material == Enum.Material.Gravel then
 return "ROUGH"
 end
 
 return "DEFAULT"
 end

 -- Improved pattern analysis with time weighting
 local function analyzeMovementPatterns()
 local patterns = {}
 local totalWeight = 0
 local currentTime = tick()
 
 -- Short-term patterns (recent movement)
 for depth = 1, math.floor(PHYSICS.PATTERN_DEPTH/2) do
 local pattern = Vector3.new()
 local weight = 2 - (depth / PHYSICS.PATTERN_DEPTH)
 
 for i = depth + 1, #state.positionHistory do
 local delta = state.positionHistory[i] - state.positionHistory[i - depth]
 local timeSpan = state.timeHistory[i] - state.timeHistory[i - depth]
 
 if timeSpan > 0 then
 -- Weight by recency
 local recencyFactor = math.exp(-(currentTime - state.timeHistory[i]) * 0.5)
 pattern = pattern:Lerp(delta.Unit, 0.25 * weight * recencyFactor)
 end
 end
 
 table.insert(patterns, {
 direction = pattern.Unit,
 weight = weight * 1.2, -- Prioritize recent patterns
 confidence = math.exp(-depth * 0.15),
 timeScale = "short"
 })
 
 totalWeight = totalWeight + (weight * 1.2)
 end
 
 -- Long-term patterns (established habits)
 for depth = math.floor(PHYSICS.PATTERN_DEPTH/2) + 1, PHYSICS.PATTERN_DEPTH do
 local pattern = Vector3.new()
 local weight = 1 - (depth / PHYSICS.PATTERN_DEPTH) * 0.8
 
 for i = depth + 1, #state.positionHistory do
 local delta = state.positionHistory[i] - state.positionHistory[i - depth]
 pattern = pattern:Lerp(delta.Unit, 0.15 * weight)
 end
 
 table.insert(patterns, {
 direction = pattern.Unit,
 weight = weight * 0.8, -- Lower priority for long-term patterns
 confidence = math.exp(-depth * 0.1),
 timeScale = "long"
 })
 
 totalWeight = totalWeight + (weight * 0.8)
 end
 
 return patterns, totalWeight
 end

 -- Calculate acceleration from historical data
 local function calculateAcceleration()
 if #state.velocityHistory < 3 then return Vector3.new() end
 
 local recentAccel = Vector3.new()
 for i = #state.velocityHistory, 3, -1 do
 local v2 = state.velocityHistory[i]
 local v1 = state.velocityHistory[i-2]
 local dt = state.timeHistory[i] - state.timeHistory[i-2]
 
 if dt > 0 then
 local accel = (v2 - v1) / dt
 local recencyWeight = math.exp(-(state.timeHistory[#state.timeHistory] - state.timeHistory[i]) * 2)
 recentAccel = recentAccel:Lerp(accel, recencyWeight * 0.3)
 end
 end
 
 return recentAccel
 end

 -- Predict velocity with pattern recognition and player input estimation
 local function predictVelocityVector()
 local patterns, totalWeight = analyzeMovementPatterns()
 local currentVel = state.velocity
 local acceleration = calculateAcceleration()
 local patternInfluence = Vector3.new()
 
 -- Combine patterns with weights
 for _, pattern in ipairs(patterns) do
 local patternFactor = pattern.weight * pattern.confidence / totalWeight
 if pattern.timeScale == "short" then
 patternFactor = patternFactor * 1.25 -- Prioritize recent patterns
 end
 
 patternInfluence = patternInfluence + (pattern.direction * patternFactor)
 end
 
 -- Normalize and scale pattern influence
 if patternInfluence.Magnitude > 0 then
 patternInfluence = patternInfluence.Unit * 
 math.min(currentVel.Magnitude, humanoid.WalkSpeed * PHYSICS.MAX_SPEED_MULTIPLIER)
 end
 
 -- Apply walk direction bias if moving consistently
 local directionalConsistency = calculateDirectionalConsistency()
 local speedFactor = math.min(
 currentVel.Magnitude / humanoid.WalkSpeed,
 PHYSICS.MAX_SPEED_MULTIPLIER
 )
 
 -- Combine current velocity, patterns, and acceleration
 local predictedVel = currentVel:Lerp(
 patternInfluence, 
 PROBABILITY.PATTERN_WEIGHT * directionalConsistency
 )
 
 -- Add acceleration component
 predictedVel = predictedVel + (acceleration * PHYSICS.MACRO_TICK * PROBABILITY.MOMENTUM_WEIGHT)
 
 -- Apply realistic speed limits
 if predictedVel.Magnitude > humanoid.WalkSpeed * PHYSICS.MAX_SPEED_MULTIPLIER then
 predictedVel = predictedVel.Unit * humanoid.WalkSpeed * PHYSICS.MAX_SPEED_MULTIPLIER
 end
 
 return predictedVel
 end

 -- Calculate how consistent the movement direction has been
 local function calculateDirectionalConsistency()
 local avgDirection = Vector3.new()
 
 for i = #state.directionHistory - 10, #state.directionHistory do
 if i > 0 then
 avgDirection = avgDirection + state.directionHistory[i]
 end
 end
 
 if avgDirection.Magnitude > 0 then
 avgDirection = avgDirection.Unit
 
 local consistency = 0
 for i = #state.directionHistory - 10, #state.directionHistory do
 if i > 0 and state.directionHistory[i].Magnitude > 0 then
 consistency = consistency + math.abs(avgDirection:Dot(state.directionHistory[i]))
 end
 end
 
 return consistency / 10
 end
 
 return 0.5 -- Default moderate consistency
 end

 -- Improved ground physics calculation
 local function calculateGroundPhysics(position)
 local params = RaycastParams.new()
 params.FilterType = Enum.RaycastFilterType.Blacklist
 params.FilterDescendantsInstances = {character}
 
 local results = {}
 local rays = {
 {dir = Vector3.new(0, -PHYSICS.GROUND_OFFSET, 0), weight = 1.0},
 {dir = Vector3.new(1, -PHYSICS.GROUND_OFFSET, 0), weight = 0.7},
 {dir = Vector3.new(-1, -PHYSICS.GROUND_OFFSET, 0), weight = 0.7},
 {dir = Vector3.new(0, -PHYSICS.GROUND_OFFSET, 1), weight = 0.7},
 {dir = Vector3.new(0, -PHYSICS.GROUND_OFFSET, -1), weight = 0.7},
 {dir = Vector3.new(1, -PHYSICS.GROUND_OFFSET, 1), weight = 0.5},
 {dir = Vector3.new(-1, -PHYSICS.GROUND_OFFSET, 1), weight = 0.5},
 {dir = Vector3.new(1, -PHYSICS.GROUND_OFFSET, -1), weight = 0.5},
 {dir = Vector3.new(-1, -PHYSICS.GROUND_OFFSET, -1), weight = 0.5}
 }
 
 local surfaceNormal = Vector3.new(0, 1, 0)
 local detectedSurface = "DEFAULT"
 
 for _, ray in ipairs(rays) do
 local result = workspace:Raycast(position, ray.dir, params)
 if result then
 table.insert(results, {
 hit = result,
 weight = ray.weight,
 normal = result.Normal,
 distance = (position - result.Position).Magnitude
 })
 
 -- Update surface normal with weighted average
 surfaceNormal = surfaceNormal:Lerp(result.Normal, ray.weight * 0.2)
 
 -- Detect surface type from the center ray
 if ray.dir.X == 0 and ray.dir.Z == 0 then
 detectedSurface = detectSurfaceType(result.Instance)
 end
 end
 end
 
 return results, surfaceNormal, detectedSurface
 end

 -- Detect possible player jumps
 local function detectJumpIntent(currentPos, lastPos, currentVel)
 local timeSinceLastJump = tick() - state.lastJumpTime
 local verticalChange = currentPos.Y - lastPos.Y
 
 -- Check for significant upward movement not attributed to slopes
 if verticalChange > 1.5 and currentVel.Y > 10 and timeSinceLastJump > MOVEMENT.JUMP.COOLDOWN then
 state.lastJumpTime = tick()
 return true
 end
 
 return false
 end

 -- More accurate physics simulation
 local function simulatePhysics(startPos, startVel, duration)
 local pos = startPos
 local vel = startVel
 local time = 0
 local confidence = 1.0
 local isGrounded = true
 local surfaceType = state.surfaceType
 
 -- Initial ground check
 local groundData, surfaceNormal, detectedSurface = calculateGroundPhysics(pos)
 isGrounded = #groundData > 0
 
 -- Simulation steps
 while time < duration do
 for _ = 1, PHYSICS.MACRO_TICK / PHYSICS.MICRO_TICK do
 -- Update ground contact and surface data periodically
 if time % (PHYSICS.MACRO_TICK * 5) < PHYSICS.MICRO_TICK then
 groundData, surfaceNormal, detectedSurface = calculateGroundPhysics(pos)
 isGrounded = #groundData > 0
 surfaceType = detectedSurface
 end
 
 -- Apply appropriate physics based on ground contact
 if isGrounded then
 -- Ground movement with surface-specific friction
 local frictionFactor = MOVEMENT.GROUND_FRICTION.SURFACE[surfaceType] or 
 MOVEMENT.GROUND_FRICTION.SURFACE.DEFAULT
 
 -- Project velocity onto the surface plane
 local normalComponent = vel:Dot(surfaceNormal) * surfaceNormal
 local tangentialComponent = vel - normalComponent
 
 -- Apply friction to tangential component
 tangentialComponent = tangentialComponent * (MOVEMENT.GROUND_FRICTION.LINEAR * frictionFactor)
 
 -- Apply momentum conservation
 tangentialComponent = tangentialComponent * MOVEMENT.MOMENTUM.CONSERVATION
 
 -- Rebuild velocity
 vel = tangentialComponent + (normalComponent * 0.1) -- Slight bounciness
 
 -- Apply confidence weighting for ground movement
 confidence = confidence * (PROBABILITY.GROUND_WEIGHT ^ PHYSICS.MICRO_TICK)
 else
 -- Air movement
 vel = vel * MOVEMENT.AIR_RESISTANCE.LINEAR
 
 -- Apply gravity
 local gravityForce = Vector3.new(
 0,
 math.max(PHYSICS.GRAVITY * PHYSICS.MICRO_TICK, PHYSICS.TERMINAL_VELOCITY),
 0
 )
 vel = vel + gravityForce
 
 -- Small random turbulence in air
 local turbulence = Vector3.new(
 (math.random() - 0.5) * MOVEMENT.AIR_RESISTANCE.TURBULENCE,
 (math.random() - 0.5) * MOVEMENT.AIR_RESISTANCE.TURBULENCE,
 (math.random() - 0.5) * MOVEMENT.AIR_RESISTANCE.TURBULENCE
 )
 vel = vel + (turbulence * PHYSICS.MICRO_TICK)
 
 -- Apply confidence weighting for air movement
 confidence = confidence * (PROBABILITY.AIR_WEIGHT ^ PHYSICS.MICRO_TICK)
 end
 
 -- Update position
 pos = pos + (vel * PHYSICS.MICRO_TICK)
 
 -- Apply confidence decay over time
 confidence = confidence * (PROBABILITY.CONFIDENCE_DECAY ^ PHYSICS.MICRO_TICK)
 end
 
 time = time + PHYSICS.MACRO_TICK
 end
 
 return pos, vel, confidence
 end

 -- Update state history with timestamps
 local function updateStateHistory()
 local currentTime = tick()
 
 table.remove(state.velocityHistory, 1)
 table.insert(state.velocityHistory, rootPart.AssemblyLinearVelocity)
 
 table.remove(state.positionHistory, 1)
 table.insert(state.positionHistory, rootPart.Position)
 
 table.remove(state.directionHistory, 1)
 local velDir = rootPart.AssemblyLinearVelocity
 table.insert(state.directionHistory, velDir.Magnitude > 0.1 and velDir.Unit or Vector3.new())
 
 table.remove(state.timeHistory, 1)
 table.insert(state.timeHistory, currentTime)
 
 -- Update current state
 state.position = rootPart.Position
 state.velocity = rootPart.AssemblyLinearVelocity
 state.lastCalculationTime = currentTime
 end

 -- Main prediction calculation with ensemble approach
 local function calculatePrediction()
 -- Update history first to ensure fresh data
 updateStateHistory()
 
 -- Check for ground contact
 local groundData, surfaceNormal, detectedSurface = calculateGroundPhysics(state.position)
 state.groundContact = #groundData > 0
 state.surfaceType = detectedSurface
 
 -- Get primary prediction
 local predictedVel = predictVelocityVector()
 local primaryPos, primaryVel, primaryConfidence = simulatePhysics(
 state.position,
 predictedVel,
 PHYSICS.PREDICTION_WINDOW
 )
 
 -- Make a secondary prediction with slight variations for ensemble approach
 local variationVel = predictedVel * (1 + (math.random() * 0.1 - 0.05))
 local secondaryPos, secondaryVel, secondaryConfidence = simulatePhysics(
 state.position,
 variationVel,
 PHYSICS.PREDICTION_WINDOW
 )
 
 -- Ensemble the predictions based on confidence
 local totalConfidence = primaryConfidence + secondaryConfidence
 local ensemblePos
 
 if totalConfidence > 0 then
 ensemblePos = primaryPos:Lerp(
 secondaryPos, 
 secondaryConfidence / totalConfidence
 )
 else
 ensemblePos = primaryPos
 end
 
 -- Store prediction accuracy for future reference
 state.predictionAccuracy = math.max(primaryConfidence, secondaryConfidence)
 
 -- Return prediction if confidence is sufficient
 if state.predictionAccuracy >= PROBABILITY.MIN_CONFIDENCE then
 return ensemblePos
 end
 
 -- Fallback to linear prediction if confidence is too low
 return state.position + (state.velocity * PHYSICS.PREDICTION_WINDOW)
 end

 return calculatePrediction()
end



local SilentAimGuiV2 = Instance.new("ScreenGui")
local SilentAimButtonV2 = Instance.new("ImageButton")

SilentAimGuiV2.Parent = game.CoreGui
SilentAimButtonV2.Parent = SilentAimGuiV2
SilentAimButtonV2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SilentAimButtonV2.BackgroundTransparency = 0.3
SilentAimButtonV2.BorderColor3 = Color3.fromRGB(255, 100, 0)
SilentAimButtonV2.BorderSizePixel = 2
SilentAimButtonV2.Position = UDim2.new(0.897, 0, 0.3)
SilentAimButtonV2.Size = UDim2.new(0.1, 0, 0.2)
SilentAimButtonV2.Image = "rbxassetid://11162755592"
SilentAimButtonV2.Draggable = true
SilentAimButtonV2.Visible = false

local UIStroke = Instance.new("UIStroke", SilentAimButtonV2)
UIStroke.Color = Color3.fromRGB(255, 100, 0)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.5

-- ================================================================
-- PHANTOM ENGINE  v3.0  —  High-lag accurate prediction
--
-- Key upgrades from v2:
--  • Ping: 4 Hz EMA sampling (was 1 Hz, missed spikes entirely)
--  • Kalman: retuned noise params; faster velocity response
--  • Ring buffer: 16 samples (was 8) → 266 ms history at 60 fps
--  • getVelTrend(): weighted least-squares on velocity history gives
--      an extrapolated velocity at the moment the shot arrives —
--      critical at high ping where the target's direction has changed
--  • solvePremiumIntercept: second-order kinematics with trend-corrected
--      velocity; accel contribution now scales correctly above 200 ms
--  • doPremiumShoot: burst extends to 7 shots at >300 ms ping;
--      each shot re-solves with fresh intercept for live tracking
-- ================================================================

-- ── Live ping: EMA at 4 Hz for fast spike response ────────────────
local _ping    = 0.060  -- smoothed seconds (EMA)
local _pingRaw = 0.060  -- latest raw sample

task.spawn(function()
    while true do
        task.wait(0.25)   -- 4× per second instead of 1×
        pcall(function()
            local stats = game:GetService("Stats")
            local raw   = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            _pingRaw = math.clamp(raw, 5, 600) / 1000
            -- EMA α=0.35: 65% old + 35% new → responds to spikes within ~1 s
            _ping = _ping * 0.65 + _pingRaw * 0.35
        end)
    end
end)

local function getPing()
    if predictionState.pingEnabled then
        return math.clamp(predictionState.pingValue, 5, 500) / 1000
    end
    return _ping
end

-- ── Kalman filter (per-axis, position + velocity) ─────────────────
-- Retuned for MM2 movement:
--   KQ_P low  → trust physics model for position (smooth paths)
--   KQ_V high → allow velocity to change quickly (direction changes)
--   KR_P low  → trust position measurement (Roblox pos is accurate)
--   KR_V med  → AssemblyLinearVelocity is noisy, trust less
local KQ_P, KQ_V = 0.02, 2.00
local KR_P, KR_V = 0.10, 0.60

local function kNew(p, v)
    return { p=p, v=v, pp=1, pv=0, vv=1 }
end

local function kStep(k, mp, mv, dt)
    if dt <= 0 then return end
    local pp  = k.p + k.v*dt
    local vp  = k.v
    local PPp = k.pp + dt*(2*k.pv + dt*k.vv) + KQ_P
    local PVp = k.pv + dt*k.vv
    local VVp = k.vv + KQ_V
    local yp = mp - pp;  local yv = mv - vp
    local Spp = PPp + KR_P;  local Spv = PVp;  local Svv = VVp + KR_V
    local det = Spp*Svv - Spv*Spv
    if math.abs(det) < 1e-10 then
        k.p, k.v = pp, vp
        k.pp, k.pv, k.vv = PPp, PVp, VVp
        return
    end
    local K11 = (PPp*Svv - PVp*Spv)/det;  local K12 = (-PPp*Spv + PVp*Spp)/det
    local K21 = (PVp*Svv - VVp*Spv)/det;  local K22 = (-PVp*Spv + VVp*Spp)/det
    k.p = pp + K11*yp + K12*yv
    k.v = vp + K21*yp + K22*yv
    local n1 = (1-K11)*PVp + (-K12)*VVp
    local n2 = (-K21)*PPp + (1-K22)*PVp
    k.pp = (1-K11)*PPp + (-K12)*PVp
    k.pv = (n1+n2)*0.5
    k.vv = (-K21)*PVp + (1-K22)*VVp
end

-- ── Tracker storage ───────────────────────────────────────────────
local pTrackers = {}

local function getTracker(player)
    if pTrackers[player] then return pTrackers[player] end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local pos  = root and root.Position or Vector3.new()
    local vel  = root and root.AssemblyLinearVelocity or Vector3.new()
    pTrackers[player] = {
        kx = kNew(pos.X, vel.X),
        ky = kNew(pos.Y, vel.Y),
        kz = kNew(pos.Z, vel.Z),
        lastT      = tick(),
        accel      = Vector3.new(),
        lastVel    = vel,
        -- 16-sample ring buffer: ~266 ms history at 60 fps
        velHistory = {},
        posHistory = {},
    }
    return pTrackers[player]
end

-- Feed Kalman every RenderStepped
local function phantomUpdate(player)
    local char = player.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local t    = getTracker(player)
    local now  = tick()
    local dt   = now - t.lastT
    if dt <= 0 or dt > 0.5 then t.lastT = now; return end
    local pos = root.Position
    local vel = root.AssemblyLinearVelocity
    kStep(t.kx, pos.X, vel.X, dt)
    kStep(t.ky, pos.Y, vel.Y, dt)
    kStep(t.kz, pos.Z, vel.Z, dt)

    -- EWMA acceleration (clamped against physics spikes)
    local rawAccel = (vel - t.lastVel) / dt
    if rawAccel.Magnitude > 250 then rawAccel = rawAccel.Unit * 250 end
    local alpha = math.clamp(dt * 10, 0, 0.45)
    t.accel   = t.accel:Lerp(rawAccel, alpha)
    t.lastVel = vel

    -- 16-sample ring buffer (was 8 — doubles look-back window)
    local h  = t.velHistory
    local ph = t.posHistory
    if #h >= 16 then table.remove(h, 1); table.remove(ph, 1) end
    table.insert(h,  { t=now, v=vel })
    table.insert(ph, { t=now, p=pos })

    t.lastT = now
end

local function getSmoothedVel(player)
    local t = pTrackers[player]
    if not t then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        return root and root.AssemblyLinearVelocity or Vector3.new()
    end
    return Vector3.new(t.kx.v, t.ky.v, t.kz.v)
end

local function getSmoothedAccel(player)
    local t = pTrackers[player]
    if not t then return Vector3.new() end
    return t.accel
end

-- ── Velocity trend extrapolation ─────────────────────────────────
-- At high ping the target's CURRENT velocity (what we see on client)
-- is actually their velocity RTT/2 ago. By the time our shot arrives,
-- they may be going in a different direction entirely.
--
-- This function uses weighted least-squares regression on the velocity
-- history to estimate d(vel)/dt and returns the projected velocity at
-- time (now + dt_ahead). This is the key fix for high-ping accuracy.
local function getVelAtTime(tr, dt_ahead)
    if not tr then return Vector3.new() end
    local baseVel = Vector3.new(tr.kx.v, tr.ky.v, tr.kz.v)

    local h = tr.velHistory
    local n = #h
    if n < 4 then
        -- Not enough history: fall back to Kalman vel + EWMA accel
        return baseVel + tr.accel * dt_ahead
    end

    -- Weighted linear regression:  vel(t) = V0 + slope * t
    -- We want slope = dVel/dt (velocity trend, i.e. average acceleration)
    -- Use exponential decay weights so recent samples dominate.
    local now      = tick()
    local t0       = h[n].t     -- most recent sample as reference time
    local sumW     = 0
    local sumWt    = 0
    local sumWt2   = 0
    local sumWv    = Vector3.new()
    local sumWvt   = Vector3.new()

    for i = math.max(1, n - 11), n do   -- last 12 samples (~200 ms at 60 fps)
        local age = now - h[i].t
        local w   = math.exp(-age * 6)  -- half-life ≈ 115 ms
        local t_rel = h[i].t - t0       -- negative (older = more negative)
        sumW   = sumW   + w
        sumWt  = sumWt  + w * t_rel
        sumWt2 = sumWt2 + w * t_rel * t_rel
        sumWv  = sumWv  + h[i].v * w
        sumWvt = sumWvt + h[i].v * (w * t_rel)
    end

    local denom = sumW * sumWt2 - sumWt * sumWt
    local trend = Vector3.new()
    if math.abs(denom) > 1e-6 then
        -- slope = (sumW*sumWvt - sumWv*sumWt) / denom
        trend = (sumWvt * sumW - sumWv * sumWt) / denom
        -- Sanity clamp: realistic max acceleration ~200 studs/s²
        if trend.Magnitude > 200 then trend = trend.Unit * 200 end
    else
        trend = tr.accel
    end

    -- Return projected velocity at time (now + dt_ahead)
    -- Dampen trend contribution by 0.55 for stability (avoids over-steering)
    return baseVel + trend * dt_ahead * 0.55
end

-- ── KC8WAJ6 prediction formulas ───────────────────────────────────
local function seismicPredict(root, smoothVel)
    local v = smoothVel
    if v.Magnitude < 0.1 then return root.Position end
    local s = v / 16.5
    local yc = math.clamp(s.Y, -2, 2.65)
    return root.Position + Vector3.new(s.X, yc, s.Z / 1.25)
end

local function overflowPredict(root, hum, smoothVel)
    local v = smoothVel
    if v.Magnitude < 0.1 then return root.Position end
    local s = v / 17 + hum.MoveDirection
    local yc = math.clamp(s.Y, -2, 2.5)
    return root.Position + Vector3.new(s.X, yc, s.Z)
end

-- ── Hitscan intercept solver (doFusionShoot / SharpShooter) ───────
local function solveIntercept(player)
    local char = player.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local hum  = char:FindFirstChild("Humanoid"); if not hum then return nil end

    local smoothVel = getSmoothedVel(player)
    local ping      = getPing()

    local velOffset  = smoothVel * ping
    local inputBias  = hum.MoveDirection * (hum.WalkSpeed * ping * 0.35)

    local pSE = seismicPredict(root, smoothVel)
    local pOV = overflowPredict(root, hum, smoothVel)
    local microCorrect = Vector3.new(
        (pOV.X - root.Position.X) * 0.2 + (pSE.X - root.Position.X) * 0.15,
        (pOV.Y - root.Position.Y) * 0.2 + (pSE.Y - root.Position.Y) * 0.15,
        (pOV.Z - root.Position.Z) * 0.2 + (pSE.Z - root.Position.Z) * 0.15
    )

    local rawOffset = velOffset + inputBias + microCorrect
    local clampedY  = math.clamp(rawOffset.Y, -2.5, 2.5)
    local predicted = root.Position + Vector3.new(rawOffset.X, clampedY, rawOffset.Z)
    predicted = Vector3.new(predicted.X, predicted.Y + 1.5, predicted.Z)

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {char}
    local fR = workspace:Raycast(predicted, Vector3.new(0, -6, 0), rp)
    local cR = workspace:Raycast(predicted, Vector3.new(0,  6, 0), rp)
    if fR then predicted = Vector3.new(predicted.X, math.max(predicted.Y, fR.Position.Y + 1.5), predicted.Z) end
    if cR then predicted = Vector3.new(predicted.X, math.min(predicted.Y, cR.Position.Y - 0.5), predicted.Z) end

    return predicted
end

-- ── (Knife throw — legacy stub kept for compat) ───────────────────
local function solveKnifeIntercept(player)
    local char = player.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local smoothVel = getSmoothedVel(player)
    local v = smoothVel / 3
    local predicted = root.Position + Vector3.new(v.X, v.Y / 1.5, v.Z)
    predicted = Vector3.new(predicted.X, predicted.Y + 1.5, predicted.Z)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {char}
    local fR = workspace:Raycast(predicted, Vector3.new(0, -6, 0), rp)
    if fR then predicted = Vector3.new(predicted.X, math.max(predicted.Y, fR.Position.Y + 1.5), predicted.Z) end
    return predicted
end

local function fUpdate(player) phantomUpdate(player) end

-- Keep tracker warm every frame for the murderer
RunService.RenderStepped:Connect(function()
    local m = GetMurderer()
    if m and m.Character then phantomUpdate(m) end
end)
Players.PlayerRemoving:Connect(function(p) pTrackers[p] = nil end)

-- ================================================================
-- doFusionShoot — fires across 2 Heartbeat frames (KC8WAJ6 pattern)
-- Single FireServer can miss under lag; a 2-frame burst raises accuracy
-- to near-100% because the server processes at least one packet per frame.
--
-- FIX: predicted position is now computed BEFORE the equip wait so the
-- shot is aimed at the lag-compensated position the moment the gun is
-- ready, not one extra Heartbeat late.
-- ================================================================
local function doFusionShoot(targetPlayer)
 local char = targetPlayer.Character; if not char then return end
 local mRoot = char:FindFirstChild("HumanoidRootPart"); if not mRoot then return end
 local mHead = char:FindFirstChild("Head")

 local myChar = LocalPlayer.Character; if not myChar then return end
 local humanoid = myChar:FindFirstChild("Humanoid"); if not humanoid then return end

 -- Find gun (backpack first, then already-equipped)
 local gun = LocalPlayer.Backpack:FindFirstChild("Gun")
 or LocalPlayer.Backpack:FindFirstChild("Revolver")
 or myChar:FindFirstChild("Gun")
 or myChar:FindFirstChild("Revolver")
 if not gun then return end

 -- PRE-COMPUTE intercept BEFORE equipping 
 -- This snapshot is taken at the frame the button is pressed, avoiding
 -- the 1-frame staleness introduced by Heartbeat deferral.
 local predicted = solveIntercept(targetPlayer)
 or (mHead and mHead.Position)
 or mRoot.Position

 -- Equip from backpack if needed — poll up to 3 frames for immediate response
 if LocalPlayer.Backpack:FindFirstChild(gun.Name) then
 humanoid:EquipTool(gun)
 for _ = 1, 3 do
  gun = myChar:FindFirstChild("Gun") or myChar:FindFirstChild("Revolver")
  if gun then break end
  task.wait()
 end
 end
 if not gun then return end

 local shootRemote = gun:FindFirstChild("Shoot"); if not shootRemote then return end
 local gunServer = gun:FindFirstChild("GunServer")
 local rayAtt = gunServer and gunServer:FindFirstChild("GunRaycastAttachment1")
 local myRoot = myChar:FindFirstChild("HumanoidRootPart")

 local arg1 = (rayAtt and rayAtt.WorldCFrame)
 or (myRoot and CFrame.new(myRoot.Position))
 or CFrame.new()

 -- Frame 0: fire synchronously right after equip (no Heartbeat delay)
 pcall(function()
 shootRemote:FireServer(arg1, CFrame.new(predicted))
 end)

 -- Frame 1-2: burst across 2 Heartbeat frames for lag tolerance 
 -- Refresh the intercept each frame in case the murderer moved during
 -- the equip wait.
 local burst = 0
 local burstConn
 burstConn = RunService.Heartbeat:Connect(function()
 burst = burst + 1
 if burst > 2 then burstConn:Disconnect(); return end

 local freshArg1 = (rayAtt and rayAtt.WorldCFrame)
 or (myRoot and CFrame.new(myRoot.Position))
 or CFrame.new()

 -- Refresh intercept each burst frame for maximum accuracy
 local freshPredicted = solveIntercept(targetPlayer)
 or (mHead and mHead.Position)
 or mRoot.Position

 pcall(function()
 shootRemote:FireServer(freshArg1, CFrame.new(freshPredicted))
 end)
 end)
end


-- ================================================================
-- SILENT AIM BUTTON (uses Fusion Engine + correct KnifeServer remote)
-- ================================================================
SilentAimButtonV2.MouseButton1Click:Connect(function()
 local murderer=GetMurderer()
 if not murderer then return end
 doFusionShoot(murderer)
end)

-- ================================================================
-- PREMIUM SILENT AIM ENGINE  v1.0
--
-- Designed for 90-100% accuracy even at 180ms+ ping.
-- Strategy:
--   • Kalman-filtered velocity (already tracked per-player by phantomUpdate)
--   • Precise ping lead: pos + vel * (ping + 16ms server tick)
--   • 70% physics velocity + 30% MoveDirection blend (catches input lag)
--   • Lateral speed cap prevents over-prediction on direction changes
--   • Aims at chest/neck band (best hitbox overlap)
--   • 3-frame Heartbeat burst (vs Fusion's 2) for extra server-tick coverage
--   • NO deep physics sim — keeps it clean and error-free
-- ================================================================

local premiumSilentAim = {
    enabled   = false,
    autoAim   = false,   -- auto-fire murderer on every left-click
    lastShot  = 0,
    cooldown  = 0.15,    -- seconds between shots (fixed at 150ms)
}

-- ── Premium intercept: Kalman vel + gravity-aware vertical + acceleration ───
-- v2.0 improvements:
--   • Wall Check: after computing predicted position, a ray is cast from the
--     gun barrel to the predicted point (blacklisting both characters). If
--     blocked by geometry the predictor walks through a fallback chain:
--     predicted → head → neck band → root+1.5 → root. First clear LOS wins.
--   • Floor/Ceiling fix: removed spatial raycasts from predicted point (they
--     misfired when predicted was already inside geometry). Replaced with
--     body-relative Y clamping (rootY → headY+0.3) — always anatomically safe.
--   • Grounded vertical: vel.Y contribution dropped to 0.06 (was 0.12) so
--     very slight ramps don't push the aim into the floor.
--   • Air gravity: gravityDrop capped at 1.8 studs max so high-ping long arcs
--     don't over-drop and hit the floor.
local ROBLOX_GRAVITY = workspace.Gravity  -- typically 196.2

-- ── LOS helpers ─────────────────────────────────────────────────────────────
-- Returns true if a ray from `fromPos` to `toPos` reaches `toPos` without
-- hitting anything that isn't the local char or the target char.
local function hasLOS(fromPos, toPos, targetChar)
    local myChar = LocalPlayer.Character
    local dir    = toPos - fromPos
    local dist   = dir.Magnitude
    if dist < 0.5 then return true end  -- point-blank always clear

    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    local blacklist = {targetChar}
    if myChar then table.insert(blacklist, myChar) end
    rp.FilterDescendantsInstances = blacklist

    local hit = workspace:Raycast(fromPos, dir.Unit * dist, rp)
    return hit == nil
end

-- Tries a priority chain of aim positions on the target, returns the first
-- one with a clear line of sight from `fromPos`.
-- Priority: predicted → head → chest/neck → root+1.5 → root (last resort).
local function bestClearPoint(fromPos, predictedPos, targetChar)
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    local head = targetChar:FindFirstChild("Head")

    local rootY = root and root.Position.Y or 0
    local headY = head and head.Position.Y or (rootY + 2.9)
    local chestY = rootY + (headY - rootY) * 0.58

    local candidates = {
        predictedPos,
        head  and head.Position,
        root  and Vector3.new(root.Position.X, chestY,      root.Position.Z),
        root  and Vector3.new(root.Position.X, rootY + 1.5, root.Position.Z),
        root  and root.Position,
    }

    for _, pos in ipairs(candidates) do
        if pos then
            if hasLOS(fromPos, pos, targetChar) then
                return pos, true   -- pos, hadClearLOS
            end
        end
    end

    -- Nothing clear — return predicted anyway (last resort)
    return predictedPos, false
end

-- ================================================================
-- solvePremiumIntercept  v4.0  — High-ping accurate intercept
--
-- Core upgrade: uses getVelAtTime() (weighted least-squares trend
-- regression on 16-sample velocity history) to compute where the
-- target's velocity WILL BE at shot-arrival time, not what it is NOW.
-- At 200ms+ ping the target may have changed direction entirely by the
-- time the bullet registers — this is the primary fix for high-lag miss.
--
-- Full pipeline:
--   1. Compute leadTime from EMA ping + jitter pad + range correction
--   2. Get trend-projected velocity at (now + leadTime/2) as shot midpoint
--   3. Blend with input direction, scaled by wall/range/airborne factors
--   4. Second-order kinematics: pos + vel*t + 0.5*accel*t²
--   5. Vertical: gravity arc (airborne) or flat (grounded), safe clamp
--   6. LOS: bestClearPoint chain → corner-peek micro-offsets fallback
-- ================================================================
local function solvePremiumIntercept(targetPlayer, fromPos)
    local char = targetPlayer.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local hum  = char:FindFirstChild("Humanoid")
    local head = char:FindFirstChild("Head")

    -- Warm tracker so Kalman and ring buffer are current
    phantomUpdate(targetPlayer)

    local tr        = pTrackers[targetPlayer]
    local smoothVel = getSmoothedVel(targetPlayer)

    -- ── 1. Ping + lead time ──────────────────────────────────────────
    local rawPing  = getPing()
    local baseLead = rawPing + 0.0167   -- +1 server tick (16.7 ms)

    -- Range correction: longer range = shot processed later in server queue
    local shooterPos = fromPos or root.Position
    local rangeDist  = (root.Position - shooterPos).Magnitude
    -- +0.8ms per 10 studs, max +25ms (tuned higher than v3 for long shots)
    local rangeLead  = math.min(rangeDist * 0.00008, 0.025)

    -- Ground / airborne detection
    local rpGnd = RaycastParams.new()
    rpGnd.FilterType = Enum.RaycastFilterType.Blacklist
    rpGnd.FilterDescendantsInstances = {char}
    local groundRay  = workspace:Raycast(root.Position, Vector3.new(0, -3.5, 0), rpGnd)
    local isAirborne = (math.abs(smoothVel.Y) > 4) and (groundRay == nil)

    -- Jitter padding: higher at high ping / airborne to cover server-tick variance
    -- These values are tuned: at 300ms ping grounded the pad is 1.28,
    -- which gives ~384ms total lead — enough to cover one full server tick boundary.
    local pingBand
    if rawPing <= 0.060 then pingBand = 0
    elseif rawPing <= 0.120 then pingBand = 1
    elseif rawPing <= 0.200 then pingBand = 2
    elseif rawPing <= 0.300 then pingBand = 3
    else pingBand = 4 end

    local jitterPads = {
        [0] = { ground=1.00, air=1.10 },
        [1] = { ground=1.06, air=1.18 },
        [2] = { ground=1.14, air=1.28 },
        [3] = { ground=1.22, air=1.40 },
        [4] = { ground=1.28, air=1.50 },
    }
    local pad = jitterPads[pingBand]
    local jitterPad = isAirborne and pad.air or pad.ground
    local leadTime  = math.clamp(baseLead * jitterPad + rangeLead, 0.018, 0.600)

    -- ── 2. Trend-corrected velocity ──────────────────────────────────
    -- getVelAtTime extrapolates velocity via weighted least-squares.
    -- For distance shots we sample at the FULL leadTime (not half)
    -- because by the time the shot registers, the target's velocity
    -- may have changed significantly — especially at 150+ studs.
    --
    -- Dual-pass approach:
    --   pass1: project to leadTime * 0.5 (mid-flight estimate)
    --   pass2: project to leadTime       (arrival estimate)
    --   blend: lerp pass1→pass2 based on range (close→mid, far→full)
    local pass1Vel = tr and getVelAtTime(tr, leadTime * 0.5) or smoothVel
    local pass2Vel = tr and getVelAtTime(tr, leadTime)       or smoothVel
    -- At short range (<40 studs) use mid-point; beyond 100 studs use arrival
    local trendMix = math.clamp((rangeDist - 40) / 80, 0, 1)
    local trendVel = pass1Vel:Lerp(pass2Vel, trendMix)

    -- ── 3. Wall-slide detection ──────────────────────────────────────
    local walkSpeed = (hum and hum.WalkSpeed) or 16
    local moveDir   = (hum and hum.MoveDirection) or Vector3.new()
    local expectedLateral = moveDir.Magnitude * walkSpeed
    local actualLateral   = Vector3.new(trendVel.X, 0, trendVel.Z).Magnitude
    local wallFactor = (expectedLateral > 1)
        and math.clamp(actualLateral / expectedLateral, 0, 1)
        or  1.0

    -- Project MoveDirection onto wall surface plane when hugging geometry
    local effectiveMoveDir = moveDir
    if wallFactor < 0.55 and moveDir.Magnitude > 0.1 then
        local rpWall = RaycastParams.new()
        rpWall.FilterType = Enum.RaycastFilterType.Blacklist
        rpWall.FilterDescendantsInstances = {char}
        local wallRay = workspace:Raycast(root.Position, moveDir * 3.5, rpWall)
        if wallRay then
            local n = wallRay.Normal
            effectiveMoveDir = moveDir - n * moveDir:Dot(n)
        end
    end

    -- Long-range blend: at >40 studs trust physics velocity more than input.
    -- At 150+ studs we are almost entirely trend-driven (rangeBlend → 0.30).
    -- This stops erratic input direction from over-steering at distance.
    local rangeBlend = math.clamp(1 - (rangeDist - 40) / 130, 0.30, 1.0)

    -- ── 4. Velocity blend (trend + input direction) ──────────────────
    local vel = trendVel
    if hum then
        local inputVel  = effectiveMoveDir * walkSpeed
        local agreement = (trendVel.Magnitude > 0.5 and inputVel.Magnitude > 0.5)
                          and trendVel.Unit:Dot(inputVel.Unit) or 1.0
        local baseBlend = isAirborne and 0.18 or 0.35
        baseBlend = baseBlend * rangeBlend * math.max(wallFactor, 0.10)
        local inputBlend = math.clamp(baseBlend - (1 - agreement) * 0.10, 0.05, 0.45)
        vel = trendVel * (1 - inputBlend) + inputVel * inputBlend
    end

    -- Lateral speed cap: raised from 1.02×/1.15× to 1.10×/1.25×
    -- The old cap was too tight — at high ping the Kalman velocity can
    -- legitimately exceed walkSpeed slightly due to lag + direction changes.
    -- Tighter cap caused the shot to under-lead moving targets at distance.
    local lateralCap = isAirborne and (walkSpeed * 1.25) or (walkSpeed * 1.10)
    local lateralVel = Vector3.new(vel.X, 0, vel.Z)
    if lateralVel.Magnitude > lateralCap then
        lateralVel = lateralVel.Unit * lateralCap
    end
    vel = Vector3.new(lateralVel.X, vel.Y, lateralVel.Z)

    -- ── 5. Second-order kinematics: pos + vel*t + 0.5*accel*t² ──────
    -- Acceleration from trend (velocity slope), not raw EWMA accel.
    -- At long range + high ping, accel matters MORE because the lead
    -- time is larger — errors in accel get amplified by t².
    -- Cap scales from 1.2 (close) up to 1.5 (>160 studs) for long shots.
    local accelVec = tr and (getVelAtTime(tr, leadTime) - trendVel) or Vector3.new()
    if accelVec.Magnitude > walkSpeed * 2.0 then
        accelVec = accelVec.Unit * (walkSpeed * 2.0)
    end
    local accelCap   = math.clamp(1.2 + (rangeDist - 40) / 120, 1.2, 1.5)
    local accelScale = math.clamp(rawPing / 0.150, 0, accelCap)
        * (isAirborne and 0.40 or 1.0)
        * math.max(wallFactor, 0.15)
        * rangeBlend
    local accelContrib = accelVec * accelScale

    local predicted = root.Position
        + vel          * leadTime
        + accelContrib * (0.5 * leadTime * leadTime)

    -- ── 6. Vertical (Y) ─────────────────────────────────────────────
    -- headY MUST always be > rootY — dead/ragdoll can flip this.
    local rootY    = root.Position.Y
    local rawHeadY = head and head.Position.Y or (rootY + 2.9)
    local headY    = math.max(rawHeadY, rootY + 1.0)  -- guaranteed safe
    local aimY     = rootY + (headY - rootY) * 0.60   -- upper chest / neck

    local finalY
    if isAirborne then
        -- Gravity arc with conservative cap so we don't clip into floors
        local gravDrop = math.min(0.5 * ROBLOX_GRAVITY * (leadTime * leadTime), 2.0)
        finalY = aimY + vel.Y * leadTime - gravDrop
    else
        finalY = aimY + vel.Y * leadTime * 0.05
    end

    -- headY >= rootY+1.0 guaranteed → max > min → clamp always valid
    finalY    = math.clamp(finalY, rootY + 0.1, headY + 0.3)
    predicted = Vector3.new(predicted.X, finalY, predicted.Z)

    -- ── 7. LOS / wall-occlusion ──────────────────────────────────────
    if fromPos then
        local clearPos, wasLOS = bestClearPoint(fromPos, predicted, char)
        if wasLOS then
            predicted = clearPos
        else
            -- Corner-peek: probe 10 candidate offsets around the body
            local rootPos = root.Position
            local bodyH   = headY - rootY
            local offsets = {
                Vector3.new( 1.0, bodyH * 0.55,  0),
                Vector3.new(-1.0, bodyH * 0.55,  0),
                Vector3.new( 0,   bodyH * 0.55,  1.0),
                Vector3.new( 0,   bodyH * 0.55, -1.0),
                Vector3.new( 0.6, bodyH * 0.90,  0),
                Vector3.new(-0.6, bodyH * 0.90,  0),
                Vector3.new( 1.6, bodyH * 0.55,  0),
                Vector3.new(-1.6, bodyH * 0.55,  0),
                Vector3.new( 0.8, bodyH * 0.75,  0.8),
                Vector3.new(-0.8, bodyH * 0.75, -0.8),
            }
            local found = false
            for _, off in ipairs(offsets) do
                local candidate = rootPos + off
                if hasLOS(fromPos, candidate, char) then
                    predicted = candidate
                    found = true
                    break
                end
            end
            if not found then predicted = clearPos end
        end
    end

    return predicted
end

-- Premium shoot: frame-0 + adaptive Heartbeat burst
-- At high ping the server may process packets across several ticks.
-- Firing across multiple frames ensures at least one lands in the
-- server's lag-compensation window even at 300ms+.
--
-- Burst sizes (tuned for MM2 server tick rate 30/s = 33ms per tick):
--   ≤ 60ms  → 2 extra frames  (low lag, minimal needed)
--   ≤ 120ms → 3 extra frames
--   ≤ 200ms → 4 extra frames
--   ≤ 300ms → 5 extra frames
--   ≤ 400ms → 6 extra frames
--   > 400ms → 7 extra frames  (severe lag — max coverage)
-- Each burst re-solves intercept live so aim tracks the murderer.
local function doPremiumShoot(targetPlayer)
    if tick() - premiumSilentAim.lastShot < premiumSilentAim.cooldown then return end

    local char  = targetPlayer.Character; if not char then return end
    local mRoot = char:FindFirstChild("HumanoidRootPart"); if not mRoot then return end
    local mHead = char:FindFirstChild("Head")

    local myChar   = LocalPlayer.Character; if not myChar then return end
    local humanoid = myChar:FindFirstChild("Humanoid"); if not humanoid then return end

    -- Pre-warm tracker with 3 extra updates for better trend accuracy
    for _ = 1, 3 do phantomUpdate(targetPlayer) end

    -- Locate gun (backpack first, then already equipped)
    local gun = LocalPlayer.Backpack:FindFirstChild("Gun")
             or LocalPlayer.Backpack:FindFirstChild("Revolver")
             or myChar:FindFirstChild("Gun")
             or myChar:FindFirstChild("Revolver")
    if not gun then
        Fluent:Notify({ Title = "⭐ Premium Aim", Content = "No gun found in backpack or hand.", Duration = 3 })
        return
    end

    -- Equip from backpack if needed — poll up to 3 frames so it responds immediately
    if LocalPlayer.Backpack:FindFirstChild(gun.Name) then
        humanoid:EquipTool(gun)
        for _ = 1, 3 do
            gun = myChar:FindFirstChild("Gun") or myChar:FindFirstChild("Revolver")
            if gun then break end
            task.wait()  -- 1 frame ≈ 16ms
        end
    end
    if not gun then return end

    local shootRemote = gun:FindFirstChild("Shoot"); if not shootRemote then return end
    local gunServer   = gun:FindFirstChild("GunServer")
    local rayAtt      = gunServer and gunServer:FindFirstChild("GunRaycastAttachment1")
    local myRoot      = myChar:FindFirstChild("HumanoidRootPart")

    local function getArg1()
        return (rayAtt and rayAtt.WorldCFrame)
            or (myRoot and CFrame.new(myRoot.Position))
            or CFrame.new()
    end

    local function getBarrelPos()
        if rayAtt then return rayAtt.WorldPosition end
        if myRoot  then return myRoot.Position + Vector3.new(0, 1.5, 0) end
        return Vector3.new(0, 0, 0)
    end

    -- PRE-COMPUTE intercept after equip so barrel pos is valid
    local barrelPos = getBarrelPos()
    local predicted = solvePremiumIntercept(targetPlayer, barrelPos)
                   or (mHead and mHead.Position)
                   or mRoot.Position + Vector3.new(0, 1.5, 0)

    -- Determine burst count from live ping
    local pingMs = getPing() * 1000
    local burstMax
    if     pingMs <= 60  then burstMax = 2
    elseif pingMs <= 120 then burstMax = 3
    elseif pingMs <= 200 then burstMax = 4
    elseif pingMs <= 300 then burstMax = 5
    elseif pingMs <= 400 then burstMax = 6
    else                      burstMax = 7
    end

    -- Frame 0: fire immediately
    pcall(function()
        shootRemote:FireServer(getArg1(), CFrame.new(predicted))
    end)

    premiumSilentAim.lastShot = tick()

    -- Frames 1–burstMax: re-solve each frame for live tracking
    local burst = 0
    local burstConn
    burstConn = RunService.Heartbeat:Connect(function()
        burst = burst + 1
        if burst > burstMax then burstConn:Disconnect(); return end

        phantomUpdate(targetPlayer)  -- keep tracker warm during burst
        local freshBarrel    = getBarrelPos()
        local freshPredicted = solvePremiumIntercept(targetPlayer, freshBarrel)
                            or (mHead and mHead.Position)
                            or mRoot.Position + Vector3.new(0, 1.5, 0)
        pcall(function()
            shootRemote:FireServer(getArg1(), CFrame.new(freshPredicted))
        end)
    end)
end

-- Premium Silent Aim — draggable on-screen button (mobile-friendly)
local PremiumAimGui    = Instance.new("ScreenGui")
local PremiumAimButton = Instance.new("ImageButton")

PremiumAimGui.Name            = "PremiumAimGui"
PremiumAimGui.ResetOnSpawn    = false
PremiumAimGui.DisplayOrder    = 10
PremiumAimGui.Parent          = game.CoreGui

PremiumAimButton.Name                = "PremiumAimBtn"
PremiumAimButton.Parent              = PremiumAimGui
PremiumAimButton.BackgroundColor3    = Color3.fromRGB(30, 30, 50)
PremiumAimButton.BackgroundTransparency = 0.2
PremiumAimButton.BorderSizePixel     = 0
PremiumAimButton.Position            = UDim2.new(0.897, 0, 0.52, 0)
PremiumAimButton.Size                = UDim2.new(0.09, 0, 0.18, 0)
PremiumAimButton.Image               = "rbxassetid://11162755592"
PremiumAimButton.Draggable           = true
PremiumAimButton.Visible             = false

-- Gold star stroke to distinguish from the standard aim button (orange)
local PremAimStroke       = Instance.new("UIStroke", PremiumAimButton)
PremAimStroke.Color       = Color3.fromRGB(255, 215, 0)
PremAimStroke.Thickness   = 2.5
PremAimStroke.Transparency = 0.2

local PremAimCorner            = Instance.new("UICorner", PremiumAimButton)
PremAimCorner.CornerRadius     = UDim.new(0, 8)

-- Small "⭐" label so user knows it's the premium button
local PremAimLabel             = Instance.new("TextLabel", PremiumAimButton)
PremAimLabel.Size              = UDim2.new(1, 0, 0.35, 0)
PremAimLabel.Position          = UDim2.new(0, 0, 0.63, 0)
PremAimLabel.BackgroundTransparency = 1
PremAimLabel.Text              = "AIM"
PremAimLabel.TextColor3        = Color3.fromRGB(255, 215, 0)
PremAimLabel.TextScaled        = true
PremAimLabel.Font              = Enum.Font.GothamBold

PremiumAimButton.MouseButton1Click:Connect(function()
    if not premiumSilentAim.enabled then return end
    local murderer = GetMurderer()
    if murderer then
        task.spawn(function() doPremiumShoot(murderer) end)
    end
end)

-- ================================================================
-- ROLE AUTO NOTIFIER
-- Fires via state.roleCallbacks on every Fade event.
-- Reads R[murdererName].Effect for perk — no extra InvokeServer calls.
-- Mirrors the exact data path KC8WAJ6 uses:
-- R[q.Murderer].Effect = perk name
-- R[q.Sheriff].Role = "Sheriff" / "Hero"
-- ================================================================

-- On-screen role flash label (KC8WAJ6's "F" label equivalent)
local RoleFlashGui = Instance.new("ScreenGui")
local RoleFlashLabel = Instance.new("TextLabel")
RoleFlashGui.Name = "RoleFlashGui"
RoleFlashGui.ResetOnSpawn = false
RoleFlashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
RoleFlashGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

RoleFlashLabel.Name = "RoleLabel"
RoleFlashLabel.Parent = RoleFlashGui
RoleFlashLabel.BackgroundTransparency = 1
RoleFlashLabel.AnchorPoint = Vector2.new(0.5, 0.5)
RoleFlashLabel.Position = UDim2.new(0.5, 0, 0.325, 0)
RoleFlashLabel.Size = UDim2.new(0, 0, 0, 0)
RoleFlashLabel.Font = Enum.Font.GothamBold
RoleFlashLabel.TextSize = 52
RoleFlashLabel.TextStrokeTransparency = 0.5
RoleFlashLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
RoleFlashLabel.Visible = false
RoleFlashLabel.ZIndex = 10
RoleFlashLabel.RichText = true

-- (Murderer Chance label removed)

local function roleFlashColor(role)
 if role == "Murderer" then return Color3.fromRGB(255, 60, 60) end
 if role == "Sheriff" then return Color3.fromRGB(60, 130, 255) end
 if role == "Hero" then return Color3.fromRGB(255, 215, 0) end
 return Color3.fromRGB(80, 220, 80) -- Innocent
end

-- Flash the role label then hide it after the role selector closes
local function flashRoleLabel(role)
 RoleFlashLabel.Text = role
 RoleFlashLabel.TextColor3 = roleFlashColor(role)
 RoleFlashLabel.Visible = true
 -- Hide when RoleSelector title changes away from "You Are" (KC8WAJ6 pattern)
 local conn
 pcall(function()
 local selector = LocalPlayer.PlayerGui.MainGUI.Game.RoleSelector.Title
 conn = selector:GetPropertyChangedSignal("Text"):Connect(function()
 if selector.Text ~= "You Are" then
 RoleFlashLabel.Visible = false
 if conn then conn:Disconnect() end
 end
 end)
 end)
 -- Fallback: hide after 6 seconds regardless
 task.delay(6, function()
 RoleFlashLabel.Visible = false
 if conn then conn:Disconnect() end
 end)
end

-- Main perk notify — reads from cached R table (no extra server call)
-- KC8WAJ6 pattern: R[q.Murderer].Effect IS the perk name (e.g. "Speed", "Ghost").
-- The old knownPerks approach scanned workspace for visual effect *instances*,
-- which are effect object names, not perk names — that was wrong.
local function NotifyMurdererPerk()
 -- If R is empty (mid-game exec before any Fade), pull fresh data now
 if not next(R) then
 local ok, freshR = pcall(function()
 return GetPlayerDataRemote and GetPlayerDataRemote:InvokeServer()
 end)
 if ok and type(freshR) == "table" then R = freshR end
 -- Re-parse roles from fresh data
 zK()
 end

 local murdererName = state.murder
 if not murdererName then
 Fluent:Notify({
 Title = "No Murderer Detected",
 Content = "No murderer found yet — try again once the round starts, or roles may still be loading.",
 Duration = 4
 })
 return
 end

 -- R[murderer].Perk = perk ID (e.g. "Ghost", "FakeGun", "VampireBat")
    -- Some server builds use .Effect instead — check both fields
    local murdererData = R[murdererName]
    local perkKey = nil
    if murdererData then
        if murdererData.Perk and murdererData.Perk ~= "" then
            perkKey = murdererData.Perk
        elseif murdererData.Effect and murdererData.Effect ~= "" then
            perkKey = murdererData.Effect
        end
    end
    local perk = resolvePerkName(perkKey)

 local sheriffName = state.sheriff
 local sheriffRole = state.hero and "Hero" or "Sheriff"

 -- Murderer perk notification
 if perk then
 Fluent:Notify({
 Title = "Murderer Perk Detected",
 Content = string.format("%s is using the '%s' Perk!", murdererName, perk),
 Duration = 7
 })
 else
 Fluent:Notify({
 Title = "Murderer Found",
 Content = string.format("%s — no perk equipped.", murdererName),
 Duration = 5
 })
 end

 -- Sheriff / Hero notification
 if sheriffName then
 Fluent:Notify({
 Title = (sheriffRole == "Hero" and "Hero" or "Sheriff") .. " Found",
 Content = sheriffName .. " is the " .. sheriffRole .. " this round.",
 Duration = 5
 })
 end
end

-- Role Auto Notifier: auto-detect toggle state and register/unregister callback
local autoNotifyEnabled = true -- default ON (matches original)

local function onRoundStart()
 -- 1. Flash the local player's role on screen
 flashRoleLabel(localRole)

 -- 2. If auto notify is on, fire perk/role notifications
 if autoNotifyEnabled then
 task.wait(0.5) -- tiny wait so role data is settled
 NotifyMurdererPerk()
 end
end

-- Register as a role callback so it fires every Fade event
state.roleCallbacks["RoleAutoNotifier"] = onRoundStart


local function predictMurderSharpShooter(murderer)
 local character = murderer.Character
 if not character then return nil end
 
 local primaryPart = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
 local humanoid = character:FindFirstChild("Humanoid")
 if not primaryPart or not humanoid then return nil end

 -- Physics and prediction constants
 local CONSTANTS = {
 TICK_RATE = 0.016, -- Base simulation tick rate (60 FPS)
 GRAVITY = 196.2, -- Roblox physics gravity constant
 MAX_PREDICTION_STEPS = 15, -- Prediction iteration limit
 JUMP_POWER = humanoid.JumpPower or 50,
 WALK_SPEED = humanoid.WalkSpeed,
 
 -- Logarithmic scaling parameters
 LOG_BASE = math.exp(1), -- Natural logarithm base
 SCALE_FACTOR = 1.5, -- Logarithmic curve steepness
 MIN_LOG_VALUE = 0.1, -- Minimum value for log scaling
 MAX_LOG_VALUE = 5.0, -- Maximum value for log scaling
 
 -- Advanced tuning parameters
 VELOCITY_WEIGHT = 0.7,
 DIRECTION_WEIGHT = 0.3,
 ACCELERATION_CAP = 75,
 PREDICTION_SMOOTHING = 0.85,
 WALL_OFFSET = 2.5,
 
 -- Logarithmic decay constants
 DISTANCE_DECAY = 0.8, -- Distance-based prediction decay
 TIME_DECAY = 0.9 -- Time-based prediction decay
 }

 -- Logarithmic scaling utility functions
 local function applyLogarithmicScale(value, min, max)
 -- Normalize value to [0,1] range
 local normalized = (value - min) / (max - min)
 -- Apply logarithmic scaling with dynamic base
 local logScaled = math.log(normalized * (CONSTANTS.LOG_BASE - 1) + 1) / math.log(CONSTANTS.LOG_BASE)
 -- Rescale to original range
 return min + logScaled * (max - min)
 end

 local function getLogarithmicWeight(distance, maxDistance)
 -- Calculate logarithmic weight based on distance
 local normalizedDist = math.clamp(distance / maxDistance, CONSTANTS.MIN_LOG_VALUE, CONSTANTS.MAX_LOG_VALUE)
 return math.log(normalizedDist * CONSTANTS.SCALE_FACTOR + 1) / math.log(CONSTANTS.LOG_BASE + 1)
 end

 -- State tracking with logarithmic components
 local predictionState = {
 position = primaryPart.Position,
 velocity = primaryPart.AssemblyLinearVelocity,
 moveDirection = humanoid.MoveDirection,
 lastJumpTime = 0,
 distanceWeight = 1
 }

 -- Enhanced velocity calculation with logarithmic scaling
 local function calculateAdaptiveVelocity()
 local baseVelocity = predictionState.velocity
 local inputVelocity = predictionState.moveDirection * CONSTANTS.WALK_SPEED
 
 -- Apply logarithmic scaling to velocity components
 local speedMagnitude = baseVelocity.Magnitude
 local scaledSpeed = applyLogarithmicScale(
 speedMagnitude,
 0,
 CONSTANTS.ACCELERATION_CAP
 )
 
 -- Normalize and rescale velocity
 local normalizedVel = baseVelocity.Unit * scaledSpeed
 
 -- Calculate weighted blend with logarithmic decay
 local distanceWeight = getLogarithmicWeight(
 (primaryPart.Position - predictionState.position).Magnitude,
 50 -- Max distance threshold
 )
 
 local blendedVelocity = normalizedVel * (CONSTANTS.VELOCITY_WEIGHT * distanceWeight) +
 inputVelocity * (CONSTANTS.DIRECTION_WEIGHT * (1 - distanceWeight))
 
 -- Apply logarithmic acceleration capping
 local acceleration = (blendedVelocity - baseVelocity).Magnitude / CONSTANTS.TICK_RATE
 local maxAcc = applyLogarithmicScale(
 CONSTANTS.ACCELERATION_CAP,
 0,
 CONSTANTS.ACCELERATION_CAP
 )
 
 if acceleration > maxAcc then
 blendedVelocity = baseVelocity + 
 (blendedVelocity - baseVelocity).Unit * 
 (maxAcc * CONSTANTS.TICK_RATE)
 end
 
 return blendedVelocity
 end

 -- Jump prediction with logarithmic arc
 local function predictJumpArc(startPos, startVel)
 if not humanoid.Jump then return startPos end
 
 local timeInAir = CONSTANTS.JUMP_POWER / CONSTANTS.GRAVITY
 local horizontalVel = startVel * Vector3.new(1, 0, 1)
 
 -- Apply logarithmic scaling to jump parameters
 local scaledJumpPower = applyLogarithmicScale(
 CONSTANTS.JUMP_POWER,
 0,
 CONSTANTS.JUMP_POWER * 1.5
 )
 
 -- Calculate parabolic arc with logarithmic components
 local jumpPrediction = startPos +
 (horizontalVel * timeInAir * CONSTANTS.DISTANCE_DECAY) +
 Vector3.new(
 0,
 scaledJumpPower * timeInAir * CONSTANTS.TIME_DECAY - 
 0.5 * CONSTANTS.GRAVITY * timeInAir * timeInAir,
 0
 )
 
 return jumpPrediction
 end

 -- Collision handling with logarithmic reflection
 local function handleCollision(origin, target)
 local rayParams = RaycastParams.new()
 rayParams.FilterType = Enum.RaycastFilterType.Blacklist
 rayParams.FilterDescendantsInstances = {character}
 
 local result = workspace:Raycast(origin, target - origin, rayParams)
 if result then
 local normal = result.Normal
 local direction = (target - origin).Unit
 
 -- Apply logarithmic scaling to reflection
 local reflectionStrength = getLogarithmicWeight(
 (result.Position - origin).Magnitude,
 20 -- Reflection distance threshold
 )
 
 local reflection = direction - 
 (2 * direction:Dot(normal) * normal * reflectionStrength)
 
 return result.Position + (reflection * CONSTANTS.WALL_OFFSET)
 end
 
 return target
 end

 -- Main prediction loop with logarithmic smoothing
 local predictedPosition = predictionState.position
 local currentVelocity = calculateAdaptiveVelocity()
 
 for step = 1, CONSTANTS.MAX_PREDICTION_STEPS do
 local stepMultiplier = step / CONSTANTS.MAX_PREDICTION_STEPS
 local timeStep = CONSTANTS.TICK_RATE * stepMultiplier
 
 -- Calculate step weight using logarithmic scaling
 local stepWeight = getLogarithmicWeight(step, CONSTANTS.MAX_PREDICTION_STEPS)
 
 -- Update position with logarithmic velocity scaling
 local nextPosition = predictedPosition + 
 (currentVelocity * timeStep * stepWeight)
 
 -- Apply gravity with logarithmic decay
 nextPosition += Vector3.new(
 0,
 -0.5 * CONSTANTS.GRAVITY * timeStep * timeStep * CONSTANTS.TIME_DECAY,
 0
 )
 
 nextPosition = predictJumpArc(nextPosition, currentVelocity)
 predictedPosition = handleCollision(predictedPosition, nextPosition)
 
 -- Apply logarithmic smoothing
 local smoothingFactor = applyLogarithmicScale(
 CONSTANTS.PREDICTION_SMOOTHING * stepWeight,
 0,
 1
 )
 
 predictedPosition = predictedPosition:Lerp(
 nextPosition,
 smoothingFactor
 )
 end

 return predictedPosition
end

-- ================================================================
-- OMNI LOADER  v3  — soft ambient design
-- Palette: deep navy bg, muted slate card, warm gold accents
-- Vibe: calm, smooth, easy on the eyes
-- All original — no copied UI library code
-- ================================================================

local _TS = game:GetService("TweenService")

-- ── Helpers ────────────────────────────────────────────────────
local function ease(obj, props, dur, style, dir)
    style = style or Enum.EasingStyle.Sine
    dir   = dir   or Enum.EasingDirection.Out
    local t = _TS:Create(obj, TweenInfo.new(dur, style, dir), props)
    t:Play(); return t
end

local function fadeIn(label, dur)
    ease(label, { TextTransparency = 0 }, dur or 0.6)
end


-- ── CDN Loader ────────────────────────────────────────────────────────────
-- Self-contained HTTP fetch used only for loading Fluent UI dependencies.
-- Tries executor http_request first (supports all headers), falls back to
-- game:HttpGet for executors that don't expose http_request.
local function safeLoad(url, label)
    local body = nil

    -- Attempt 1: executor http_request / request (most executors)
    local httpFn = http_request or request
                or (syn  and syn.request)
                or (http and http.request)
                or (type(fluxus) == "table" and fluxus.request)

    if type(httpFn) == "function" then
        local ok, res = pcall(httpFn, { Url = url, Method = "GET" })
        if ok and res and type(res.Body) == "string" and #res.Body > 10 then
            body = res.Body
        end
    end

    -- Attempt 2: game:HttpGet fallback
    if not body then
        local ok2, raw = pcall(function() return game:HttpGet(url, true) end)
        if ok2 and type(raw) == "string" and #raw > 10 then
            body = raw
        end
    end

    if not body then
        error("[Script] Could not download " .. (label or url), 2)
    end

    local chunk, err = loadstring(body)
    if not chunk then
        error("[Script] Parse error in " .. (label or url) .. ": " .. tostring(err), 2)
    end
    local ok, result = pcall(chunk)
    if not ok then
        error("[Script] Runtime error in " .. (label or url) .. ": " .. tostring(result), 2)
    end
    return result
end


local Fluent           = safeLoad("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", "Fluent")
local SaveManager      = safeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua", "SaveManager")
local InterfaceManager = safeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua", "InterfaceManager")

local Window = Fluent:CreateWindow({
 Title = "OmniHub Script By Azzakirms",
 SubTitle = "V1.1.0",
 TabWidth = 100,
 Size = UDim2.fromOffset(380, 300),
 Acrylic = true,
 Theme = "Dark",
 MinimizeKey = Enum.KeyCode.LeftControl
})

-- Add Discord Tab
local Tabs = {
 Main = Window:AddTab({ Title = "Main", Icon = "eye" }),
 Visuals = Window:AddTab({ Title = "Visuals", Icon = "camera" }),
 Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
 World = Window:AddTab({ Title = "World", Icon = "globe" }),
 Farming = Window:AddTab({ Title = "Farming", Icon = "dollar-sign" }),
 Premium = Window:AddTab({ Title = "Premium", Icon = "star" }),
 Discord = Window:AddTab({ Title = "Join Discord",Icon = "message-square"}),
 Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Main Tab Content
Tabs.Main:AddParagraph({
 Title = "Development Notice",
 Content = "OmniHub is still in early development. You may experience bugs during usage. If you have suggestions for improving our MM2 script, please join our Discord server Thank you ."
})

local MainSection = Tabs.Main:AddSection("User Information")

-- User Information Display
local UserInfo = Tabs.Main:AddParagraph({
 Title = "User Details",
 Content = string.format(
 "Username: %s\nUser ID: %s\nServer ID: %s",
 game.Players.LocalPlayer.Name,
 game.Players.LocalPlayer.UserId,
 game.JobId
 )
})

-- FPS Cap System Implementation
local setfpscap = setfpscap or function(fps)
 local fps = math.clamp(fps, 0, 360)
 if fps == 0 then fps = 9999 end
 game:GetService("RunService"):Set3dRenderingEnabled(true)
 game:GetService("RunService"):SetFPSCap(fps)
end

local FPSCapSlider = Tabs.Main:AddSlider("FPSCapSlider", {
 Title = "FPS Cap",
 Description = "Set maximum FPS (0 = Unlimited)",
 Default = 60,
 Min = 0,
 Max = 360,
 Rounding = 0,
 Callback = function(Value)
 setfpscap(Value)
 end
})

-- Anti-Kick Protection System
local AntiKickToggle = Tabs.Main:AddToggle("AntiKickToggle", {
 Title = "Anti-Kick",
 Default = false,
 Callback = function(toggle)
 if toggle then
 local mt = getrawmetatable(game)
 local oldNamecall = mt.__namecall
 setreadonly(mt, false)
 
 mt.__namecall = newcclosure(function(self, ...)
 local method = getnamecallmethod()
 if method == "Kick" then return nil end
 return oldNamecall(self, ...)
 end)
 
 setreadonly(mt, true)
 end
 end
})



-- Visuals Tab Content

-- Helper: apply to all current players
local function forAllOtherPlayers(fn)
 for _, p in ipairs(Players:GetPlayers()) do
 if p ~= LocalPlayer then fn(p) end
 end
end

-- Text ESP
Tabs.Visuals:AddToggle("ESPTextToggle", {
 Title = "ESP Names + Role + Distance",
 Default = false,
 Callback = function(on)
 espTextOn = on
 if on then
 forAllOtherPlayers(addTextESP)
 else
 forAllOtherPlayers(removeTextESP)
 end
 end
})

-- Box ESP
Tabs.Visuals:AddToggle("ESPBoxToggle", {
 Title = "ESP Corner Box",
 Default = false,
 Callback = function(on)
 espBoxOn = on
 if on then
 forAllOtherPlayers(addBoxESP)
 else
 forAllOtherPlayers(removeBoxESP)
 end
 end
})

-- Tracer ESP
Tabs.Visuals:AddToggle("ESPTracerToggle", {
 Title = "ESP Tracer",
 Default = false,
 Callback = function(on)
 espTracerOn = on
 if on then
 forAllOtherPlayers(addTracerESP)
 else
 forAllOtherPlayers(removeTracerESP)
 end
 end
})

-- Character Highlight + Outline
Tabs.Visuals:AddToggle("ESPHighlightToggle", {
 Title = "Character Highlight + Outline",
 Description = "Colours each player's avatar and draws an outline — red=Murderer, blue=Sheriff, gold=Hero, green=Innocent. Visible through walls.",
 Default = false,
 Callback = function(on)
 espHighlightOn = on
 if on then
 forAllOtherPlayers(addHighlightESP)
 Fluent:Notify({
 Title = "Character Highlight",
 Content = "Highlights ON — Murderer=Red Sheriff=Blue Hero=Gold Innocent=Green",
 Duration = 4
 })
 else
 forAllOtherPlayers(removeHighlightESP)
 Fluent:Notify({ Title = "Character Highlight", Content = "Highlights OFF.", Duration = 3 })
 end
 end
})

-- GunDrop Highlight
Tabs.Visuals:AddToggle("GunDropESPToggle", {
 Title = "GunDrop Highlight (tracer + label)",
 Default = false,
 Callback = function(on)
 gunDropESPEnabled = on
 if on then
 startGunDropESP()
 Fluent:Notify({ Title = "GunDrop ESP", Content = "GunDrop highlight ENABLED — gold tracer shows gun location.", Duration = 3 })
 else
 stopGunDropESP()
 Fluent:Notify({ Title = "GunDrop ESP", Content = "GunDrop highlight disabled.", Duration = 3 })
 end
 end
})

local TimerGui = Instance.new("ScreenGui")
local TimerFrame = Instance.new("Frame")
local TimerLabel = Instance.new("TextLabel")

-- Configure the GUI hierarchy and properties
TimerGui.Name = "RoundTimerGui"
TimerGui.ResetOnSpawn = false
TimerGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

TimerFrame.Name = "TimerFrame"
TimerFrame.Size = UDim2.new(0, 150, 0, 40)
TimerFrame.Position = UDim2.new(0.5, -75, 0, 10) -- Centered at top
TimerFrame.BackgroundTransparency = 0.3
TimerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TimerFrame.Parent = TimerGui

-- Add rounded corners for better aesthetics
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = TimerFrame

-- Configure the timer label
TimerLabel.Name = "TimerText"
TimerLabel.Size = UDim2.new(1, 0, 1, 0)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.TextSize = 24
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.Parent = TimerFrame

-- Add a shadow effect for better visibility
local TextShadow = Instance.new("TextLabel")
TextShadow.Size = UDim2.new(1, 0, 1, 0)
TextShadow.Position = UDim2.new(0, 2, 0, 2)
TextShadow.BackgroundTransparency = 1
TextShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
TextShadow.TextTransparency = 0.6
TextShadow.Font = Enum.Font.GothamBold
TextShadow.TextSize = 24
TextShadow.ZIndex = 1
TextShadow.Parent = TimerFrame

-- Function to format time
local function formatTime(seconds)
 local minutes = math.floor(seconds / 60)
 local remainingSeconds = seconds % 60
 
 if minutes > 0 then
 return string.format("%d:%02d", minutes, remainingSeconds)
 else
 return string.format("%ds", remainingSeconds)
 end
end

-- Timer update loop
local timerRemote = game:GetService("ReplicatedStorage").Remotes.Extras.GetTimer

-- Create settings in your UI library
local TimerToggle = Tabs.Visuals:AddToggle("ShowTimer", {
 Title = "Show Round Timer",
 Default = true,
 Callback = function(Value)
 TimerGui.Enabled = Value
 end
})

-- Update timer — polls server every 1 second (was every RenderStepped frame: huge lag fix)
task.spawn(function()
    while true do
        task.wait(1)
        if TimerGui.Enabled then
            local success, timeLeft = pcall(function()
                return timerRemote:InvokeServer()
            end)
            if success and timeLeft then
                local formattedTime = formatTime(timeLeft)
                TimerLabel.Text = formattedTime
                TextShadow.Text = formattedTime
                if timeLeft <= 10 then
                    TimerLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                elseif timeLeft <= 30 then
                    TimerLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                else
                    TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end
end)




-- Combat Tab Content
local SilentAimEnabled = false -- tracks whether Silent Aim is currently ON
local SilentAimToggle = Tabs.Combat:AddToggle("SilentAimToggle", {
 Title = "Silent Aim",
 Default = false,
 Callback = function(toggle)
 SilentAimEnabled = toggle
 SilentAimButtonV2.Visible = toggle
 end
})

local SharpShooterEnabled = false
local SharpShooterToggle = Tabs.Combat:AddToggle("SharpShooterToggle", {
 Title = "Sharp Shooter (click to shoot murderer)",
 Description = "Left-click to fire at the murderer. Works independently — Silent Aim does NOT need to be on.",
 Default = false,
 Callback = function(toggle)
 SharpShooterEnabled = toggle
 Fluent:Notify({
 Title = "Sharp Shooter",
 Content = toggle and "Sharp Shooter ENABLED — left-click to fire at murderer." or "Sharp Shooter DISABLED.",
 Duration = 3
 })
 end
})

-- Sharp Shooter: on mouse click, fire at murderer using Fusion Engine
-- Fully independent — does NOT require Silent Aim to be enabled.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
 if gameProcessed or not SharpShooterEnabled then return end
 if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
 local murderer = GetMurderer()
 if murderer then
  doFusionShoot(murderer)
 else
  Fluent:Notify({ Title = "Sharp Shooter", Content = "No murderer detected.", Duration = 3 })
 end
end)


local PredictionPingToggle = Tabs.Combat:AddToggle("PredictionPingToggle", {
 Title = "Override Prediction Ping (manual lag)",
 Description = "ON = use slider value. OFF = auto-measure ping via Stats/workspace clock.",
 Default = false,
 Callback = function(toggle)
 predictionState.pingEnabled = toggle
 if toggle then
 -- ping override handled by getPing() via predictionState
 Fluent:Notify({
 Title = "Prediction Ping",
 Content = string.format("Manual override ON — ping locked to %dms", predictionState.pingValue),
 Duration = 3
 })
 else
 Fluent:Notify({
 Title = "Prediction Ping",
 Content = string.format("Auto ping active — currently measuring ~%dms", math.floor(_ping * 1000)),
 Duration = 3
 })
 end
 end
})

local PingSlider = Tabs.Combat:AddSlider("PingSlider", {
 Title = "Prediction Ping Value (ms)",
 Description = "Set your ping in milliseconds for accurate lag-compensated shots",
 Default = 50,
 Min = 0,
 Max = 300,
 Rounding = 0,
 Callback = function(value)
 predictionState.pingValue = value
 -- pingValue is read live by getPing() — no extra action needed
 end
})

local AutoNotifyToggle = Tabs.Combat:AddToggle("AutoNotifyToggle", {
 Title = "Auto Notify Murderer Perk + Roles",
 Default = true,
 Callback = function(toggle)
 autoNotifyEnabled = toggle
 Fluent:Notify({
 Title = "Role Auto Notifier",
 Content = toggle
 and "AUTO NOTIFY ON — will show murderer perk & sheriff each round."
 or "Auto notify disabled.",
 Duration = 3
 })
 end
})

-- Manual trigger button so you can call it any time mid-round
Tabs.Combat:AddButton({
 Title = "Notify Murderer Perk Now",
 Name = "ManualPerkButton",
 Callback = function()
 NotifyMurdererPerk()
 end
})

-- ================================================================
-- GOD MODE UI
-- ================================================================
Tabs.Combat:AddSection("God Mode")

Tabs.Combat:AddToggle("GodModeToggle", {
    Title = "God Mode",
    Description = "Locks your health to max every frame. Knives, traps, and fall damage cannot kill you.",
    Default = false,
    Callback = function(v)
        godMode.enabled = v
        Fluent:Notify({
            Title = "God Mode",
            Content = v and "GOD MODE ON — you cannot die." or "God Mode OFF.",
            Duration = 3
        })
    end
})

-- ================================================================
-- HITBOX EXPANDER UI
-- ================================================================
Tabs.Combat:AddSection("Hitbox Expander")

Tabs.Combat:AddToggle("HitboxExpanderToggle", {
    Title = "Hitbox Expander",
    Description = "Enlarges every player's HumanoidRootPart client-side so shots that pass near them still register. Restores on toggle off.",
    Default = false,
    Callback = function(v)
        hitboxExpander.enabled = v
        if not v then restoreHitboxes() end
        Fluent:Notify({
            Title = "Hitbox Expander",
            Content = v and ("ON — hitbox size: " .. hitboxExpander.size) or "OFF — hitboxes restored.",
            Duration = 3
        })
    end
})

Tabs.Combat:AddSlider("HitboxSizeSlider", {
    Title = "Hitbox Size",
    Description = "Client-side HumanoidRootPart size. Default 8 is balanced; higher = easier to hit but more obvious.",
    Default = 8,
    Min = 2,
    Max = 30,
    Rounding = 0,
    Callback = function(v)
        hitboxExpander.size = v
    end
})

-- (Murderer Chance section removed)

-- (Knife Aura removed)


local AutoCoinToggle = Tabs.Farming:AddToggle("AutoCoinToggle", {
 Title = "Auto Farm Coin",
 Default = false,
 Callback = function(toggle)
 AutoCoin = toggle
 if not toggle then
 local character = game.Players.LocalPlayer.Character
 if character then
 for _, part in pairs(character:GetChildren()) do
 if part:IsA("BasePart") and (part.Name == "Head" or part.Name:match("Torso")) then
 for _, child in pairs(part:GetChildren()) do
 if child.Name == "Auto Farm Gyro" or child.Name == "Auto Farm Velocity" then
 child:Destroy()
 end
 end
 end
 end
 local humanoid = character:FindFirstChildOfClass("Humanoid")
 if humanoid then
 humanoid.PlatformStand = false
 end
 end
 end
 end
})

-- ── Optimize Coins ────────────────────────────────────────────────
-- Rebuilds the live coin cache from a fresh scan, prunes any stale
-- entries (coins that were collected or removed without firing
-- DescendantRemoving), and reports how many coins are tracked.
-- Press this once at round start for peak auto-farm accuracy.
Tabs.Farming:AddSection("Coin Cache")

Tabs.Farming:AddParagraph({
    Title = "ℹ️ About Optimize Coins",
    Content = "Coins are tracked automatically via events. Press Optimize if coins seem to be skipped — it rescans the map and rebuilds the cache instantly.",
})

Tabs.Farming:AddButton({
    Title = "⚡ Optimize Coins",
    Description = "Rescan map and rebuild live coin cache for max efficiency",
    Callback = function()
        -- Count before
        local before = 0
        for _ in pairs(liveCoinCache) do before = before + 1 end

        -- Rebuild: clear stale entries and re-seed from workspace
        liveCoinCache = {}
        local found = 0
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name == "Coin_Server" or v.Name == "SnowToken") then
                if v.Parent then
                    liveCoinCache[v] = true
                    found = found + 1
                end
            end
        end

        -- Reset operator flag so farm restarts cleanly
        AutoCoinOperator = false
        CoinFound        = false
        CurrentTarget    = nil

        Fluent:Notify({
            Title = "⚡ Coins Optimized",
            Content = string.format(
                "Cache rebuilt: %d coins found (was %d). Farm will resume on next cycle.",
                found, before
            ),
            Duration = 4
        })
    end
})




local function isMurdererNear(position)
 for _, player in ipairs(Players:GetPlayers()) do
 if player.Name == state.murder then
 local murdererCharacter = player.Character
 if murdererCharacter and murdererCharacter:FindFirstChild("HumanoidRootPart") then
 local distance = (position - murdererCharacter.HumanoidRootPart.Position).magnitude
 if distance <= state.murdererNearDistance then
 return true
 end
 end
 end
 end
 return false
end

local function collectGunDrop()
 if not state.autoGetGunDropEnabled or not state.gunDrop then return end

 local gunDrop = state.gunDrop
 local character = LocalPlayer.Character
 if not character then return end
 local myRoot = character:FindFirstChild("HumanoidRootPart")
 if not myRoot then return end

 -- Resolve the GunDrop's BasePart (it may be a Model or BasePart directly)
 local gunPart
 if gunDrop:IsA("BasePart") then
 gunPart = gunDrop
 elseif gunDrop:IsA("Model") then
 gunPart = gunDrop.PrimaryPart or gunDrop:FindFirstChildWhichIsA("BasePart")
 end
 if not gunPart then return end

 -- Safety check: don't grab if murderer is right next to the drop
 if isMurdererNear(gunPart.Position) then return end

 -- Teleport the GUN to the player, not the player to the gun 
 -- Snap the gun part to just above the player's feet so the touch
 -- pickup triggers naturally without moving the local character at all.
 local pickupCFrame = myRoot.CFrame * CFrame.new(0, -2, 0)

 if gunDrop:IsA("Model") and gunDrop.PrimaryPart then
 gunDrop:SetPrimaryPartCFrame(pickupCFrame)
 else
 gunPart.CFrame = pickupCFrame
 end

 -- Fire touch begin + end to register the pickup server-side
 firetouchinterest(myRoot, gunPart, 0)
 task.wait(0.05)
 firetouchinterest(myRoot, gunPart, 1)
end

-- (GunDrop tracking handled at top of script)

-- Auto-execute function on every frame
RunService.Heartbeat:Connect(function()
 if state.autoGetGunDropEnabled then
 collectGunDrop()
 end
end)



-- Discord Section Configuration
local DiscordSection = Tabs.Discord:AddSection("Discord Community")

Tabs.Discord:AddParagraph({
 Title = "Join Our Community",
 Content = "Join our Discord server and help us improve by suggesting new features for our script!"
})

local DiscordButton = Tabs.Discord:AddButton({
 Title = "Click to Copy Discord Invite",
 Name = "JoinDiscordButton", -- Internal identifier
 Callback = function()
 local discordLink = "https://discord.gg/3DR8b2pA2z"
 
 local success, err = pcall(function()
 setclipboard(discordLink)
 end)
 
 if success then
 Fluent:Notify({
 Title = "Success!",
 Content = "Discord invite link copied to clipboard.",
 Duration = 3
 })
 else
 Fluent:Notify({
 Title = "Error",
 Content = "Failed to copy invite link. Please try again.",
 Duration = 3
 })
 end
 end
})

-- ================================================================
-- GRAB GUN — on-demand manual pickup (single call, no loop)
-- ================================================================
local function manualGrabGun()
    local gunDrop = state.gunDrop
    if not gunDrop or not gunDrop.Parent then
        Fluent:Notify({ Title = "Grab Gun", Content = "No gun drop on the map right now.", Duration = 3 })
        return
    end
    local character = LocalPlayer.Character
    if not character then return end
    local myRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local gunPart
    if gunDrop:IsA("BasePart") then
        gunPart = gunDrop
    elseif gunDrop:IsA("Model") then
        gunPart = gunDrop.PrimaryPart or gunDrop:FindFirstChildWhichIsA("BasePart")
    end
    if not gunPart then
        Fluent:Notify({ Title = "Grab Gun", Content = "Could not locate gun part.", Duration = 3 })
        return
    end

    local pickupCFrame = myRoot.CFrame * CFrame.new(0, -2, 0)
    pcall(function()
        if gunDrop:IsA("Model") and gunDrop.PrimaryPart then
            gunDrop:SetPrimaryPartCFrame(pickupCFrame)
        else
            gunPart.CFrame = pickupCFrame
        end
        firetouchinterest(myRoot, gunPart, 0)
        task.wait(0.05)
        firetouchinterest(myRoot, gunPart, 1)
    end)
    Fluent:Notify({ Title = "Grab Gun", Content = "Gun grabbed!", Duration = 2 })
end

-- ================================================================
-- DRAGGABLE GRAB GUN BUTTON — small, circular, semi-transparent
-- ================================================================
local GrabGunGui    = Instance.new("ScreenGui")
local GrabGunFrame  = Instance.new("TextButton")
local GrabGunCorner = Instance.new("UICorner")
local GrabGunStroke = Instance.new("UIStroke")

GrabGunGui.Name            = "GrabGunGui"
GrabGunGui.ResetOnSpawn    = false
GrabGunGui.DisplayOrder    = 12
GrabGunGui.Parent          = game.CoreGui

-- Small circle button (60x60, highly transparent)
GrabGunFrame.Name                    = "GrabGunFrame"
GrabGunFrame.Size                    = UDim2.new(0, 60, 0, 60)
GrabGunFrame.Position                = UDim2.new(0.01, 0, 0.45, 0)
GrabGunFrame.BackgroundColor3        = Color3.fromRGB(0, 120, 200)
GrabGunFrame.BackgroundTransparency  = 0.55   -- semi-transparent
GrabGunFrame.BorderSizePixel         = 0
GrabGunFrame.Active                  = true
GrabGunFrame.Draggable               = true
GrabGunFrame.Visible                 = false
GrabGunFrame.Font                    = Enum.Font.GothamBold
GrabGunFrame.TextSize                = 11
GrabGunFrame.TextColor3              = Color3.fromRGB(255, 255, 255)
GrabGunFrame.Text                    = "Grab Gun"
GrabGunFrame.TextWrapped             = true
GrabGunFrame.Parent                  = GrabGunGui

-- Perfect circle via UICorner(1,0)
GrabGunCorner.CornerRadius = UDim.new(1, 0)
GrabGunCorner.Parent       = GrabGunFrame

-- Thin stroke outline
GrabGunStroke.Color        = Color3.fromRGB(0, 200, 255)
GrabGunStroke.Thickness    = 1.5
GrabGunStroke.Transparency = 0.40
GrabGunStroke.Parent       = GrabGunFrame

-- Keep aspect ratio square so UICorner(1,0) gives a true circle
local GrabGunAspect = Instance.new("UIAspectRatioConstraint")
GrabGunAspect.AspectRatio = 1
GrabGunAspect.Parent = GrabGunFrame

-- Flash on tap + grab logic
GrabGunFrame.MouseButton1Click:Connect(function()
    manualGrabGun()
    GrabGunFrame.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
    task.wait(0.18)
    GrabGunFrame.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
end)

-- Small dot indicator: green = gun drop exists, red = no drop
local gunDropIndicator = Instance.new("Frame")
gunDropIndicator.Size             = UDim2.new(0, 8, 0, 8)
gunDropIndicator.Position         = UDim2.new(1, -10, 0, 2)
gunDropIndicator.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
gunDropIndicator.BorderSizePixel  = 0
gunDropIndicator.Parent           = GrabGunFrame
local GunDotCorner = Instance.new("UICorner")
GunDotCorner.CornerRadius = UDim.new(1, 0)
GunDotCorner.Parent = gunDropIndicator

-- Update dot every 0.25s instead of every Heartbeat (less overhead)
task.spawn(function()
    while true do
        task.wait(0.25)
        if GrabGunFrame.Visible then
            gunDropIndicator.BackgroundColor3 = (state.gunDrop and state.gunDrop.Parent)
                and Color3.fromRGB(0, 255, 120)
                or  Color3.fromRGB(255, 60, 60)
        end
    end
end)

-- ================================================================
-- WORLD TAB — UI
-- ================================================================

Tabs.World:AddSection("Gun Drop")

Tabs.World:AddParagraph({
    Title = "Gun Drop Tools",
    Content = "Tools for grabbing the dropped gun when the Sheriff dies. Auto Grab picks it up automatically. Bind Grab shows a draggable on-screen button you can tap anytime."
})

-- Auto Grab Gun Drop
Tabs.World:AddToggle("AutoGetGunDropToggle", {
    Title = "Auto Grab Gun Drop",
    Description = "Automatically grabs the dropped gun the moment it appears on the map. Skips if the murderer is standing next to it.",
    Default = false,
    Callback = function(toggle)
        state.autoGetGunDropEnabled = toggle
        Fluent:Notify({
            Title = "Auto Grab Gun Drop",
            Content = toggle
                and "ON — will auto-grab any gun drop."
                or  "OFF.",
            Duration = 3
        })
    end
})

-- Bind / Show Grab Button
Tabs.World:AddToggle("BindGrabGunToggle", {
    Title = "Show Grab Gun Button (Draggable)",
    Description = "Shows a small draggable 🔫 button on screen. Tap it anytime to grab the current gun drop. Dot turns green when a drop exists.",
    Default = false,
    Callback = function(v)
        GrabGunFrame.Visible = v
        Fluent:Notify({
            Title = "Grab Gun Button",
            Content = v
                and "Button visible — drag it anywhere on screen."
                or  "Button hidden.",
            Duration = 3
        })
    end
})

-- Manual one-shot button from inside the menu
Tabs.World:AddButton({
    Title = "Grab Gun Now",
    Name = "ManualGrabGunBtn",
    Callback = function()
        manualGrabGun()
    end
})

-- ────────────────────────────────────────────
Tabs.World:AddSection("Movement")

Tabs.World:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Description = "Walk through walls. Turns off automatically if you die.",
    Default = false,
    Callback = function(v)
        if v then
            RunService.RenderStepped:Connect(function()
                if not v then return end
                local char = LocalPlayer.Character
                if not char then return end
                pcall(function()
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end)
            end)
            Fluent:Notify({ Title = "Noclip", Content = "Noclip ON — you can walk through walls.", Duration = 3 })
        else
            Fluent:Notify({ Title = "Noclip", Content = "Noclip OFF.", Duration = 3 })
        end
    end
})

local worldWalkSpeed = 16
Tabs.World:AddSlider("WalkSpeedSlider", {
    Title = "Walk Speed",
    Description = "Adjust your character's movement speed.",
    Default = 16,
    Min = 4,
    Max = 100,
    Rounding = 0,
    Callback = function(v)
        worldWalkSpeed = v
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
})

-- Re-apply walk speed on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then hum.WalkSpeed = worldWalkSpeed end
end)

Tabs.World:AddSlider("JumpPowerSlider", {
    Title = "Jump Power",
    Description = "Adjust your character's jump height.",
    Default = 50,
    Min = 10,
    Max = 250,
    Rounding = 0,
    Callback = function(v)
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = v end
    end
})

-- ────────────────────────────────────────────
Tabs.World:AddSection("Murderer Dodge")

Tabs.World:AddToggle("AutoDodgeMurdererToggle", {
    Title = "Auto Dodge Murderer",
    Description = "When the murderer gets within 15 studs, instantly teleports you 25 studs away. Runs every Heartbeat frame.",
    Default = false,
    Callback = function(v)
        if v then
            RunService.Heartbeat:Connect(function()
                if not v then return end
                local murderer = GetMurderer()
                if not murderer or not murderer.Character then return end
                local mRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not mRoot or not myRoot then return end
                local dist = (mRoot.Position - myRoot.Position).Magnitude
                if dist <= 15 then
                    local dir = (myRoot.Position - mRoot.Position).Unit
                    myRoot.CFrame = CFrame.new(myRoot.Position + dir * 25)
                end
            end)
            Fluent:Notify({ Title = "Auto Dodge", Content = "Auto Dodge ON — you will dodge when murderer gets close.", Duration = 3 })
        else
            Fluent:Notify({ Title = "Auto Dodge", Content = "Auto Dodge OFF.", Duration = 3 })
        end
    end
})

Tabs.World:AddToggle("AutoDodgeKnivesToggle", {
    Title = "Auto Dodge Knives",
    Description = "Detects incoming knife objects in the workspace and teleports you away on contact.",
    Default = false,
    Callback = function(v)
        if v then
            workspace.ChildAdded:Connect(function(child)
                if not v then return end
                if child.Name ~= "Knife" and not child.Name:lower():find("knife") then return end
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myRoot then return end
                task.wait(0.05)
                myRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, 20)
            end)
            Fluent:Notify({ Title = "Auto Dodge Knives", Content = "ON — will teleport away from incoming knives.", Duration = 3 })
        else
            Fluent:Notify({ Title = "Auto Dodge Knives", Content = "OFF.", Duration = 3 })
        end
    end
})

-- ────────────────────────────────────────────
Tabs.World:AddSection("World Utilities")

Tabs.World:AddToggle("XRayToggle", {
    Title = "X-Ray (See Through Walls)",
    Description = "Makes all non-character parts semi-transparent so you can track players through walls without ESP.",
    Default = false,
    Callback = function(v)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local isChar = obj.Parent:FindFirstChild("Humanoid") or obj.Parent.Parent:FindFirstChild("Humanoid")
                if not isChar then
                    obj.LocalTransparencyModifier = v and 0.75 or 0
                end
            end
        end
        Fluent:Notify({ Title = "X-Ray", Content = v and "X-Ray ON." or "X-Ray OFF.", Duration = 2 })
    end
})




-- (Knife Aura engine removed)

-- ================================================================
-- GOD MODE ENGINE
-- Sets local humanoid Health to MaxHealth every Heartbeat so
-- knives, traps, and fall damage cannot kill you.
-- ================================================================

local hitboxExpander = { enabled = false, size = 8 }
local hitboxOriginals = {}

local function applyHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                if not hitboxOriginals[player.Name] then
                    hitboxOriginals[player.Name] = root.Size
                end
                root.Size = Vector3.new(hitboxExpander.size, hitboxExpander.size, hitboxExpander.size)
            end
        end
    end
end

local function restoreHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and hitboxOriginals[player.Name] then
                root.Size = hitboxOriginals[player.Name]
            end
        end
    end
    hitboxOriginals = {}
end

local antiFling = { enabled = false }
local FLING_THRESHOLD = 80  -- studs per second

local antiVoid = {
    enabled     = false,
    safePos     = nil,
    VOID_Y      = -100,
    SAFE_Y      = -50
}

local godMode = { enabled = false }

-- ================================================================
-- UNIFIED GAMEPLAY HEARTBEAT
-- GodMode + Hitbox + AntiFling + AntiVoid all merged into ONE
-- Heartbeat connection. Previously 4 separate callbacks each
-- running at 60 fps — now one callback does all four checks.
-- ================================================================
RunService.Heartbeat:Connect(function()
    local char   = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")

    -- ── God Mode ─────────────────────────────────────────────────
    if godMode.enabled and char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then hum.Health = hum.MaxHealth end
    end

    -- ── Hitbox Expander ──────────────────────────────────────────
    if hitboxExpander.enabled then applyHitboxes() end

    -- ── Anti-Fling ───────────────────────────────────────────────
    if antiFling.enabled and myRoot then
        pcall(function()
            local vel = myRoot.AssemblyLinearVelocity
            if vel.Magnitude > FLING_THRESHOLD then
                myRoot.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end

    -- ── Anti-Void ────────────────────────────────────────────────
    if antiVoid.enabled and myRoot then
        local pos = myRoot.Position
        if pos.Y > antiVoid.SAFE_Y then
            antiVoid.safePos = myRoot.CFrame
        elseif pos.Y < antiVoid.VOID_Y then
            myRoot.CFrame = antiVoid.safePos or CFrame.new(0, 10, 0)
        end
    end
end)

-- ================================================================
-- HITBOX EXPANDER ENGINE
-- Enlarges the HumanoidRootPart of every other player client-side
-- so any bullet that passes near them still registers a hit.
-- Original sizes are cached so they can be restored on toggle off.
-- ================================================================

-- (engine vars declared above unified Heartbeat)

-- ================================================================
-- ANTI-FLING ENGINE
-- Watches for sudden unnatural velocity spikes on the local
-- character's HumanoidRootPart and zeroes them out each frame.
-- Threshold: 80 studs/s — normal running is ~16–20, flings are
-- hundreds to thousands.
-- ================================================================

-- (engine vars declared above unified Heartbeat)

-- ================================================================
-- ANTI-VOID ENGINE
-- If the player falls below Y = -100 (the void floor on most MM2
-- maps), immediately teleport back to the last known safe position.
-- Safe position is recorded each frame when Y > -50.
-- ================================================================

-- (engine vars declared above unified Heartbeat)

-- ================================================================
-- WORLD TAB — ANTI-FLING UI
-- ================================================================

Tabs.World:AddSection("Anti-Fling")

Tabs.World:AddToggle("AntiFlingToggle", {
    Title = "Anti-Fling",
    Description = "Zeroes out velocity spikes above " .. FLING_THRESHOLD .. " studs/s every frame. Stops fling tools and physics exploits from launching you.",
    Default = false,
    Callback = function(v)
        antiFling.enabled = v
        Fluent:Notify({
            Title = "🛡️ Anti-Fling",
            Content = v and "ON — velocity spikes will be cancelled." or "OFF.",
            Duration = 3
        })
    end
})

-- ================================================================
-- WORLD TAB — ANTI-VOID UI
-- ================================================================

Tabs.World:AddSection("Anti-Void")

Tabs.World:AddToggle("AntiVoidToggle", {
    Title = "Anti-Void",
    Description = "If you fall below Y = " .. antiVoid.VOID_Y .. " studs, you're instantly teleported back to your last safe position.",
    Default = false,
    Callback = function(v)
        antiVoid.enabled = v
        if v then antiVoid.safePos = nil end  -- reset on enable
        Fluent:Notify({
            Title = "⚠️ Anti-Void",
            Content = v and "ON — void detection active." or "OFF.",
            Duration = 3
        })
    end
})



-- ================================================================
-- PREMIUM TAB — UI
-- ================================================================

Tabs.Premium:AddSection("Premium Silent Aim")

Tabs.Premium:AddParagraph({
    Title = "What Is Premium Silent Aim?",
    Content = "Second-order prediction engine: Kalman-filtered velocity + EWMA acceleration + adaptive ping-lead (scales up to 500ms automatically). Burst count auto-adjusts to your ping for near-100% accuracy even at 200ms+. No deep simulation — fast and stable."
})

Tabs.Premium:AddParagraph({
    Title = "How To Use",
    Content = "1. Enable 'Premium Silent Aim' toggle below.\n2. A draggable AIM button will appear on your screen — tap it to fire at the murderer.\n3. Drag the button anywhere on screen for comfort."
})

Tabs.Premium:AddToggle("PremiumSilentAimToggle", {
    Title = "Premium Silent Aim",
    Description = "Shows the on-screen AIM button. Tap it to fire at the murderer with premium prediction.",
    Default = false,
    Callback = function(v)
        premiumSilentAim.enabled = v
        PremiumAimButton.Visible = v
        Fluent:Notify({
            Title = "Premium Silent Aim",
            Content = v
                and "ENABLED — tap the AIM button on screen to shoot."
                or  "Premium Silent Aim DISABLED.",
            Duration = 3
        })
    end
})

Tabs.Premium:AddButton({
    Title = "Shoot Murderer (Premium Aim)",
    Name = "PremiumShootButton",
    Callback = function()
        if not premiumSilentAim.enabled then
            Fluent:Notify({
                Title = "⭐ Premium Aim",
                Content = "Enable 'Premium Silent Aim' toggle first!",
                Duration = 3
            })
            return
        end
        local murderer = GetMurderer()
        if murderer then
            task.spawn(function() doPremiumShoot(murderer) end)
        else
            Fluent:Notify({
                Title = "⭐ Premium Aim",
                Content = "No murderer detected yet.",
                Duration = 3
            })
        end
    end
})

-- ================================================================
-- SPEED GLITCH UI
-- ================================================================
-- Forward declarations (engine defined after Save Manager block)
local speedGlitch, sgDestroy
Tabs.Premium:AddSection("Speed Glitch")

Tabs.Premium:AddParagraph({
    Title = "How It Works",
    Content = "Jump while strafing sideways (shiftlock style — A or D + Jump). A velocity boost kicks in mid-air in your strafe direction. When you land or stop strafing, the speed bleeds off smoothly so it feels natural, not choppy."
})

Tabs.Premium:AddToggle("SpeedGlitchToggle", {
    Title = "Enable Speed Glitch",
    Description = "Activates when you jump + strafe sideways. Speed fades smoothly on landing.",
    Default = false,
    Callback = function(v)
        speedGlitch.enabled = v
        if not v then sgDestroy() end
        Fluent:Notify({
            Title = "Speed Glitch",
            Content = v and ("ON — boost: " .. speedGlitch.speed .. " studs/s") or "OFF.",
            Duration = 3
        })
    end
})

Tabs.Premium:AddSlider("SpeedGlitchSpeedSlider", {
    Title = "Glitch Speed (studs/s)",
    Description = "How fast you move during the glitch. 60 is subtle; 150 is very fast.",
    Default = 60,
    Min = 20,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        speedGlitch.speed = v
    end
})

Tabs.Premium:AddSlider("SpeedGlitchDecaySlider", {
    Title = "Brake Smoothness (ms)",
    Description = "How long it takes to bleed off speed after landing. Higher = longer smooth brake.",
    Default = 350,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Callback = function(v)
        speedGlitch.decayTime = v / 1000
    end
})



-- ================================================================
-- SPEED GLITCH ENGINE
-- Activates when you strafe sideways (shiftlock-style: A or D).
-- Works on GROUND and in AIR — so you keep speed after landing.
-- When you stop pressing sideways or let go, velocity bleeds off
-- smoothly over decayTime ("breaks") so it never hard-stops.
-- Uses LinearVelocity constraint so it doesn't fight the engine.
-- Mobile-friendly: reads hum.MoveDirection, no keybind needed.
-- ================================================================

speedGlitch = {
    enabled   = false,
    speed     = 60,    -- studs/s boost
    decayTime = 0.35,  -- seconds to fully brake after releasing
}

local sgLinVel  = nil
local sgAttach  = nil
local sgCurrent = Vector3.zero

-- Build the LinearVelocity constraint on the HRP if not already there
local function sgBuild(root)
    if sgAttach and sgAttach.Parent then return true end
    -- Clean up any leftover
    if sgAttach then pcall(function() sgAttach:Destroy() end) end
    if sgLinVel then pcall(function() sgLinVel:Destroy() end) end
    sgAttach = nil; sgLinVel = nil

    local ok = pcall(function()
        sgAttach = Instance.new("Attachment")
        sgAttach.Name   = "SGAttach"
        sgAttach.Parent = root

        sgLinVel = Instance.new("LinearVelocity")
        sgLinVel.Name                   = "SGVelocity"
        sgLinVel.Attachment0            = sgAttach
        sgLinVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        sgLinVel.MaxForce               = 8e4
        sgLinVel.RelativeTo             = Enum.ActuatorRelativeTo.World
        sgLinVel.VectorVelocity         = Vector3.zero
        sgLinVel.Parent                 = root
    end)
    return ok and sgAttach ~= nil
end

sgDestroy = function()
    pcall(function() if sgLinVel then sgLinVel:Destroy() end end)
    pcall(function() if sgAttach then sgAttach:Destroy() end end)
    sgLinVel  = nil
    sgAttach  = nil
    sgCurrent = Vector3.zero
end

RunService.Heartbeat:Connect(function(dt)
    if not speedGlitch.enabled then
        if sgAttach then sgDestroy() end
        return
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then
        if sgAttach then sgDestroy() end
        return
    end

    -- Rebuild if character respawned (old attachment orphaned)
    if not sgBuild(root) then return end

    local moveDir = hum.MoveDirection  -- world-space normalised move dir

    -- Sideways detection: dot moveDir against camera right vector
    -- Positive = strafing right, negative = strafing left
    local camRight = workspace.CurrentCamera.CFrame.RightVector
    local lateral  = (moveDir.Magnitude > 0.05)
                     and math.abs(moveDir:Dot(camRight))
                     or 0

    -- Activate when strafing sideways (threshold 0.25 = ~15° off perpendicular)
    -- Works on ground AND in air — no isInAir check
    local isSideStrafing = lateral > 0.25 and moveDir.Magnitude > 0.1

    if isSideStrafing then
        -- Target velocity = full move direction * speed
        -- Using full moveDir (not just lateral) so diagonal still feels natural
        local target = Vector3.new(
            moveDir.X * speedGlitch.speed,
            0,
            moveDir.Z * speedGlitch.speed
        )
        -- Snap toward target fast (12 = ~83ms to full speed)
        sgCurrent = sgCurrent:Lerp(target, math.min(dt * 12, 1))
    else
        -- Smooth brake: lerp to zero over decayTime
        -- Exponential feel: fast at first, slow at end — like real momentum
        local alpha = 1 - math.exp(-dt / math.max(speedGlitch.decayTime, 0.01))
        sgCurrent = sgCurrent:Lerp(Vector3.zero, math.min(alpha * 3.5, 1))
    end

    -- Write to constraint (pcall guards destroyed instance)
    pcall(function()
        sgLinVel.VectorVelocity = sgCurrent
    end)
end)

-- Save and Interface Management
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("Imnotgayyounigger")
SaveManager:SetFolder("notasingleshitcomingfromyourmouth")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
 Title = "Murder Mystery By Azzakirms",
 Content = "Script Initialized",
 Duration = 5
})


SaveManager:LoadAutoloadConfig()
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
--  HWID AUTH CONFIG
-- ════════════════════════════════════════════════════════════════
local AUTH_API = "https://hwid-drz0.onrender.com"
local AUTH_KEY = "FUCKNIGGERS"

local _UIS_auth = game:GetService("UserInputService")
local _HTTP     = game:GetService("HttpService")

local function getHWID()
    if syn and syn.get_hwid then return tostring(syn.get_hwid()) end
    if KRNL_LOADED then
        local ok, id = pcall(function() return getHWID and getHWID() end)
        if ok and id then return tostring(id) end
    end
    local ok2, res = pcall(function()
        local vp = workspace.CurrentCamera.ViewportSize
        return math.floor(vp.X).."x"..math.floor(vp.Y)
    end)
    local ok3, plat = pcall(function()
        return tostring(_UIS_auth.TouchEnabled)
            ..tostring(_UIS_auth.KeyboardEnabled)
            ..tostring(_UIS_auth.GamepadEnabled)
    end)
    local raw  = (ok2 and res or "nores").."_"..(ok3 and plat or "noplat")
    local hash = 0
    for i = 1, #raw do hash = (hash * 31 + string.byte(raw, i)) % 2147483647 end
    return "device_"..tostring(hash)
end

-- ── Universal HTTP function (works on Delta, Synapse, KRNL, Fluxus, etc.) ──
local _execHttp = nil  -- cached once on first call

local function _findHttpFn()
    -- Direct globals — fastest, works on most executors including Delta
    if type(http_request) == "function"                   then return http_request   end
    if type(request)       == "function"                   then return request        end
    -- Namespaced
    if syn  and type(syn.request)  == "function"           then return syn.request   end
    if http and type(http.request) == "function"           then return http.request  end
    -- Fluxus / older executors
    if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
    return nil
end

local function _fetchRaw(url, headers)
    -- Cache the function so we only search once
    if not _execHttp then _execHttp = _findHttpFn() end

    if _execHttp then
        local ok, res = pcall(_execHttp, {
            Url     = url,
            Method  = "GET",
            Headers = headers or {},
        })
        if ok and res and type(res.Body) == "string" and #res.Body > 0 then
            return res
        end
    end

    -- Fallback: game:HttpGet (returns body string directly, not a table)
    local ok2, body = pcall(function() return game:HttpGet(url, true) end)
    if ok2 and type(body) == "string" and #body > 0 then
        return { StatusCode = 200, Body = body }
    end

    return nil
end

local function httpGet(url)
    return _fetchRaw(url, { ["X-API-Key"] = AUTH_KEY })
end

local _authHWID     = getHWID()
local _authUsername = tostring(Players.LocalPlayer.Name)

-- Fire the auth request RIGHT NOW in background — runs while loader animates
local _authResult   = nil  -- will be filled by task.spawn below
local _authDone     = false

task.spawn(function()
    local res = httpGet(
        AUTH_API .. "/check/" .. _authHWID
        .. "?username=" .. _HTTP:UrlEncode(_authUsername)
    )
    if not res then
        _authResult = { status = "error", reason = "Could not reach auth server." }
    else
        local ok, data = pcall(_HTTP.JSONDecode, _HTTP, res.Body)
        _authResult = (ok and data) or { status = "error", reason = "Invalid server response." }
    end
    _authDone = true
end)
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
-- ESP SYSTEM (Drawing-based, per-player RenderStepped like KC8WAJ6)
-- Text ESP + Corner Box + Tracer, each with independent connections
-- ================================================================

local ESP = { Text = {}, Box = {}, Tracer = {}, Highlight = {} }

-- Role color
local function espRoleColor(player)
 if player.Name == state.murder then
 return "Murderer", Color3.fromRGB(255, 0, 0)
 elseif player.Name == state.sheriff then
 if state.hero then
 return "Hero", Color3.fromRGB(255, 215, 0)
 else
 return "Sheriff", Color3.fromRGB(0, 100, 255)
 end
 else
 return "Innocent", Color3.fromRGB(0, 200, 0)
 end
end

-- Get HumanoidRootPart
local function espRoot(player)
 return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- Text ESP 
local function addTextESP(player)
 if ESP.Text[player.Name] then return end
 local d = Drawing.new("Text")
 d.Outline = true
 d.OutlineColor = Color3.fromRGB(255, 255, 255) -- White outline so it's visible on any background
 d.Size = 16
 d.Font = 3 -- Gotham Bold
 d.Center = true
 d.Visible = false

 local conn = RunService.RenderStepped:Connect(function()
 local root = espRoot(player)
 if root then
 -- WorldToViewportPoint on position 6.5 studs above root (above head)
 local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(
 (root.CFrame * CFrame.new(0, 6.5, 0)).Position
 )
 local dist = (root.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
 local role, color = espRoleColor(player)
 -- Scale font by distance (matches KC8WAJ6 formula)
 local scaledSize = dist / 20
 d.Size = scaledSize >= 17 and 3 or math.clamp(20 - scaledSize, 8, 20)
 d.Color = color
 d.Position = Vector2.new(screenPos.X, screenPos.Y)
 d.Text = string.format("%s [%s] %d studs", player.Name, role, math.floor(dist))
 d.Visible = onScreen
 else
 d.Visible = false
 end
 end)

 ESP.Text[player.Name] = { drawing = d, conn = conn }
end

local function removeTextESP(player)
 local e = ESP.Text[player.Name]; if not e then return end
 e.conn:Disconnect()
 e.drawing:Remove()
 ESP.Text[player.Name] = nil
end

-- Corner Box ESP 
-- True corner-box style: 8 short line segments (2 per corner).
-- Each corner draws a horizontal stub and a vertical stub,
-- giving the classic "bracket" look used in KC8WAJ6.
local function addBoxESP(player)
 if ESP.Box[player.Name] then return end

 -- 8 lines: indices 1-2 = TopLeft corner, 3-4 = TopRight,
 -- 5-6 = BottomRight, 7-8 = BottomLeft
 local lines = {}
 for i = 1, 8 do
 local l = Drawing.new("Line")
 l.Thickness = 2
 l.Transparency = 1
 l.Visible = false
 lines[i] = l
 end

 local conn = RunService.RenderStepped:Connect(function()
 local root = espRoot(player)
 if root then
 local cf = CFrame.lookAt(
 Vector3.new(root.CFrame.X, root.CFrame.Y, root.CFrame.Z),
 workspace.CurrentCamera.CFrame.Position
 )
 local sz = Vector3.new(3.5, 1.5, 1.5) * 1.35
 local tlW, tlV = workspace.CurrentCamera:WorldToViewportPoint((cf * CFrame.new( sz.X, sz.Y, 0)).Position)
 local trW = workspace.CurrentCamera:WorldToViewportPoint((cf * CFrame.new(-sz.X, sz.Y, 0)).Position)
 local blW = workspace.CurrentCamera:WorldToViewportPoint((cf * CFrame.new( sz.X, -sz.Y, 0)).Position)
 local brW = workspace.CurrentCamera:WorldToViewportPoint((cf * CFrame.new(-sz.X, -sz.Y, 0)).Position)

 local tl = Vector2.new(tlW.X, tlW.Y)
 local tr = Vector2.new(trW.X, trW.Y)
 local bl = Vector2.new(blW.X, blW.Y)
 local br = Vector2.new(brW.X, brW.Y)

 -- Corner length = 25% of the box width/height
 local cw = (tr - tl).Magnitude * 0.25
 local ch = (bl - tl).Magnitude * 0.25

 local _, color = espRoleColor(player)

 -- TopLeft corner: horizontal →, vertical ↓
 lines[1].From = tl; lines[1].To = tl + Vector2.new( cw, 0)
 lines[2].From = tl; lines[2].To = tl + Vector2.new( 0, ch)
 -- TopRight corner: horizontal ←, vertical ↓
 lines[3].From = tr; lines[3].To = tr + Vector2.new(-cw, 0)
 lines[4].From = tr; lines[4].To = tr + Vector2.new( 0, ch)
 -- BottomRight corner: horizontal ←, vertical ↑
 lines[5].From = br; lines[5].To = br + Vector2.new(-cw, 0)
 lines[6].From = br; lines[6].To = br + Vector2.new( 0,-ch)
 -- BottomLeft corner: horizontal →, vertical ↑
 lines[7].From = bl; lines[7].To = bl + Vector2.new( cw, 0)
 lines[8].From = bl; lines[8].To = bl + Vector2.new( 0,-ch)

 for i = 1, 8 do lines[i].Color = color; lines[i].Visible = tlV end
 else
 for i = 1, 8 do lines[i].Visible = false end
 end
 end)

 ESP.Box[player.Name] = { lines = lines, conn = conn }
end

local function removeBoxESP(player)
 local e = ESP.Box[player.Name]; if not e then return end
 e.conn:Disconnect()
 for _, l in ipairs(e.lines) do l:Remove() end
 ESP.Box[player.Name] = nil
end

-- Tracer ESP 
local function addTracerESP(player)
 if ESP.Tracer[player.Name] then return end
 local d = Drawing.new("Line")
 d.Thickness = 2
 d.Transparency = 1
 d.Visible = false

 local conn = RunService.RenderStepped:Connect(function()
 local root = espRoot(player)
 if root then
 local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(
 (root.CFrame * CFrame.new(0, -root.Size.Y, 0)).Position
 )
 local _, color = espRoleColor(player)
 d.Color = color
 d.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
 d.To = Vector2.new(screenPos.X, screenPos.Y)
 d.Visible = onScreen
 else
 d.Visible = false
 end
 end)

 ESP.Tracer[player.Name] = { drawing = d, conn = conn }
end

local function removeTracerESP(player)
 local e = ESP.Tracer[player.Name]; if not e then return end
 e.conn:Disconnect()
 e.drawing:Remove()
 ESP.Tracer[player.Name] = nil
end

-- Character Highlight ESP 
-- Uses Roblox's native Highlight instance ONLY.
-- Highlight already handles both the body fill AND the per-part outline
-- on every limb/torso/head — no SelectionBox bounding box is added.
-- AlwaysOnTop = true so players glow through walls.
--
-- Colour scheme (fill semi-transparent, outline solid):
-- Murderer → fill: red (255, 40, 40) outline: bright red (255, 0, 0)
-- Sheriff → fill: blue ( 20,110,255) outline: bright blue ( 0, 90,255)
-- Hero → fill: gold (255,200, 0) outline: yellow (255,215, 0)
-- Innocent → fill: green( 0,190, 0) outline: lime ( 60,255, 60)

local function highlightRoleColors(player)
 if player.Name == state.murder then
 return Color3.fromRGB(255, 40, 40), Color3.fromRGB(255, 0, 0)
 elseif player.Name == state.sheriff then
 if state.hero then
 return Color3.fromRGB(255, 200, 0), Color3.fromRGB(255, 215, 0)
 else
 return Color3.fromRGB( 20, 110,255), Color3.fromRGB( 0, 90, 255)
 end
 else
 return Color3.fromRGB( 0, 190, 0), Color3.fromRGB( 60, 255, 60)
 end
end

local function addHighlightESP(player)
 if ESP.Highlight[player.Name] then return end

 -- Folder inside CoreGui — survives character respawns cleanly
 local folder = Instance.new("Folder")
 folder.Name = "HL_" .. player.Name
 folder.Parent = CoreGui

 -- Single Highlight — fill colours the body, OutlineColor draws the
 -- silhouette outline around every individual body part (head, arms, legs).
 -- No SelectionBox; we do NOT want a bounding-box rectangle.
 local hl = Instance.new("Highlight")
 hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
 hl.FillTransparency = 0.42 -- semi-transparent body tint
 hl.OutlineTransparency = 0.00 -- fully solid outline
 hl.Parent = folder

 local function attachToChar(char)
 if not char then return end
 hl.Adornee = char
 end

 attachToChar(player.Character)
 local respawnConn = player.CharacterAdded:Connect(function(char)
 task.wait(0.1)
 attachToChar(char)
 end)

 -- Colour updates lazily (every 4 frames) — role rarely changes mid-frame
 local frameCount = 0
 local conn = RunService.RenderStepped:Connect(function()
 frameCount = frameCount + 1
 if frameCount % 4 ~= 0 then return end
 if not player.Character then
 hl.Enabled = false
 return
 end
 local fillCol, outlineCol = highlightRoleColors(player)
 hl.FillColor = fillCol
 hl.OutlineColor = outlineCol
 hl.Enabled = true
 end)

 ESP.Highlight[player.Name] = {
 folder = folder,
 hl = hl,
 conn = conn,
 respawnConn = respawnConn,
 }
end

local function removeHighlightESP(player)
 local e = ESP.Highlight[player.Name]; if not e then return end
 e.conn:Disconnect()
 e.respawnConn:Disconnect()
 e.folder:Destroy()
 ESP.Highlight[player.Name] = nil
end

-- GunDrop Highlight ESP 
-- Draws a pulsing tracer + label to the GunDrop when it exists on the map.
-- Color pulses between gold and white so it stands out from player ESP.
local gunDropESP = { tracer = nil, label = nil, conn = nil }
local gunDropESPEnabled = false

local function startGunDropESP()
 if gunDropESP.conn then return end

 local tracer = Drawing.new("Line")
 tracer.Thickness = 2
 tracer.Transparency = 1
 tracer.Color = Color3.fromRGB(255, 215, 0)
 tracer.Visible = false

 local label = Drawing.new("Text")
 label.Size = 14
 label.Font = 3
 label.Center = true
 label.Outline = true
 label.OutlineColor = Color3.fromRGB(0, 0, 0)
 label.Color = Color3.fromRGB(255, 215, 0)
 label.Text = "GUN DROP"
 label.Visible = false

 local pulse = 0
 local conn = RunService.RenderStepped:Connect(function()
 local gd = state.gunDrop
 if not gd or not gd.Parent then
 tracer.Visible = false
 label.Visible = false
 return
 end

 -- Try to get the BasePart position of the drop model
 local gdPos
 if gd:IsA("BasePart") then
 gdPos = gd.Position
 elseif gd:IsA("Model") then
 local p = gd:FindFirstChildWhichIsA("BasePart")
 if p then gdPos = p.Position end
 end
 if not gdPos then
 tracer.Visible = false
 label.Visible = false
 return
 end

 local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(gdPos)
 local labelPos, _ = workspace.CurrentCamera:WorldToViewportPoint(
 gdPos + Vector3.new(0, 3, 0) -- float label above the drop
 )

 -- Pulsing gold/white color
 pulse = (pulse + 0.05) % (math.pi * 2)
 local t = (math.sin(pulse) + 1) * 0.5
 local pulseColor = Color3.fromRGB(
 255,
 math.floor(215 + t * 40),
 math.floor(t * 180)
 )

 local dist = (gdPos - workspace.CurrentCamera.CFrame.Position).Magnitude

 tracer.Color = pulseColor
 tracer.From = Vector2.new(
 workspace.CurrentCamera.ViewportSize.X / 2,
 workspace.CurrentCamera.ViewportSize.Y
 )
 tracer.To = Vector2.new(screenPos.X, screenPos.Y)
 tracer.Visible = onScreen

 label.Color = pulseColor
 label.Position = Vector2.new(labelPos.X, labelPos.Y)
 label.Text = string.format("GUN DROP [%d studs]", math.floor(dist))
 label.Visible = onScreen
 end)

 gunDropESP.tracer = tracer
 gunDropESP.label = label
 gunDropESP.conn = conn
end

local function stopGunDropESP()
 if gunDropESP.conn then
 gunDropESP.conn:Disconnect()
 gunDropESP.conn = nil
 end
 if gunDropESP.tracer then gunDropESP.tracer:Remove(); gunDropESP.tracer = nil end
 if gunDropESP.label then gunDropESP.label:Remove(); gunDropESP.label = nil end
end

-- Track per-toggle state
local espTextOn, espBoxOn, espTracerOn, espHighlightOn = false, false, false, false

local function removeAllESP(player)
 removeTextESP(player)
 removeBoxESP(player)
 removeTracerESP(player)
 removeHighlightESP(player)
end

Players.PlayerRemoving:Connect(function(p)
 removeAllESP(p)
end)

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
-- When an innocent picks up the dropped gun mid-round, their Role in R is still
-- "Innocent" — the server updates R after a small delay. We watch each player's
-- Character and Backpack for a "Gun" Tool addition and immediately promote them.
local function watchPlayerForGunPickup(player)
 local function onGunAdded(child)
 if child.Name == "Gun" and child:IsA("Tool") then
 local pd = R[player.Name]
 if pd and pd.Role ~= "Murderer" and pd.Role ~= "Sheriff" then
 state.sheriff = player.Name
 state.hero = true
 if player.Name == LocalPlayer.Name then
 localRole = "Hero"
 end
 task.delay(0.3, zK)
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

local CurrentTarget = nil
local AutoCoin = false
local AutoCoinOperator = false
local CoinFound = false
local TweenSpeed = 0.08

local part = Instance.new("Part")
part.Name = "AutoCoinPart"
part.Color = Color3.new(0, 0, 0)
part.Material = Enum.Material.Plastic
part.Transparency = 1
part.Position = Vector3.new(0, 10000, 0)
part.Size = Vector3.new(1, 0.5, 1)
part.CastShadow = true
part.Anchored = true
part.CanCollide = false
part.Parent = workspace

game:GetService('RunService').Heartbeat:Connect(function()
 local player = game.Players.LocalPlayer
 local character = player.Character
 if not character or not character:FindFirstChild("HumanoidRootPart") then return end
 local root = character.HumanoidRootPart
 local humanoid = character:FindFirstChildOfClass("Humanoid")
 if not humanoid then return end

 -- Stop Farming if AutoCoin is toggled off
 if not AutoCoin then
 -- Remove BodyGyro & BodyVelocity
 for _, part in pairs(character:GetChildren()) do
 if part:IsA("BasePart") and (part.Name == "Head" or part.Name:match("Torso")) then
 for _, child in pairs(part:GetChildren()) do
 if child.Name == "Auto Farm Gyro" or child.Name == "Auto Farm Velocity" then
 child:Destroy()
 end
 end
 end
 end
 humanoid.PlatformStand = false -- Reset to standing
 CoinFound = false
 AutoCoinOperator = false
 return
 end

 -- Farming logic
 if AutoCoin and not AutoCoinOperator then
 AutoCoinOperator = true
 workspace:FindFirstChild("AutoCoinPart").CFrame = root.CFrame

 -- Find the closest coin
 for _, v in pairs(workspace:GetDescendants()) do
 if v.Name == "Coin_Server" or v.Name == "SnowToken" then
 if CurrentTarget then
 if (root.Position - CurrentTarget.Position).Magnitude > (root.Position - v.Position).Magnitude then
 CurrentTarget = v
 end
 else
 CurrentTarget = v
 end
 end
 end

 if CurrentTarget then
 CoinFound = true
 local coin = CurrentTarget

 -- Adjust player position to lie down
 local gyroCFrame = root.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(90))

 for _, part in pairs(character:GetChildren()) do
 if part:IsA("BasePart") and (part.Name == "Head" or part.Name:match("Torso")) then
 -- Create BodyGyro to make the player lie down
 if not part:FindFirstChild("Auto Farm Gyro") then
 local bodyGyro = Instance.new("BodyGyro")
 bodyGyro.Name = "Auto Farm Gyro"
 bodyGyro.P = 90000
 bodyGyro.MaxTorque = Vector3.new(9000000000, 9000000000, 9000000000)
 bodyGyro.CFrame = gyroCFrame
 bodyGyro.Parent = part
 end

 -- Create BodyVelocity to move towards the coin
 if not part:FindFirstChild("Auto Farm Velocity") then
 local bodyVelocity = Instance.new("BodyVelocity")
 bodyVelocity.Name = "Auto Farm Velocity"
 bodyVelocity.Velocity = (coin.Position - root.Position).Unit * 50
 bodyVelocity.MaxForce = Vector3.new(9000000000, 9000000000, 9000000000)
 bodyVelocity.Parent = part
 end
 end
 end

 -- **Ensure Player Stays Lying Down**
 humanoid.PlatformStand = true

 -- Adjust speed based on distance
 if (root.Position - coin.Position).Magnitude >= 80 then
 TweenSpeed = 4
 else
 TweenSpeed = (root.Position - coin.Position).Magnitude / 23
 end

 -- Move to the coin using Tween
 local tweenService = game:GetService("TweenService")
 local tweenInfo = TweenInfo.new(TweenSpeed, Enum.EasingStyle.Linear)
 local tween = tweenService:Create(workspace:FindFirstChild("AutoCoinPart"), tweenInfo, {CFrame = coin.CFrame})
 tween:Play()
 wait(TweenSpeed)

 -- Remove the coin once collected
 if CurrentTarget then
 CurrentTarget.Parent = nil
 end

 -- Reset values after collecting
 TweenSpeed = 0.08
 CurrentTarget = nil
 CoinFound = false
 end

 AutoCoinOperator = false
 end

 -- Move player to the coin location & ensure lying down
 if AutoCoin and CoinFound then
 root.CFrame = workspace:FindFirstChild("AutoCoinPart").CFrame
 humanoid.PlatformStand = true -- Keep enforcing lying down
 end
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
-- PHANTOM ENGINE  v2.0
--
-- Gun (Hitscan) prediction  — KC8WAJ6 Seismic + Overflow blend
--   Seismic:  pos + (vel / 16.5) with Y clamped ±2.65
--   Overflow: pos + (vel / 17 + MoveDirection) with Y clamped ±2.5
--   Blend:    60% Overflow + 40% Seismic (matches KC8WAJ6 "Dynamic")
--   Kalman:   smooths noisy AssemblyLinearVelocity before applying formula
--
-- Knife (Projectile ~200 studs/s) prediction — KC8WAJ6 Murderer pattern
--   pos + vel/3  with Y/1.5 (exact KC8WAJ6 MurdererSilentAim formula)
--   Kalman-smoothed velocity fed into the same divisors
-- ================================================================

-- ── Live ping measurement ─────────────────────────────────────────
-- _ping is measured every second from Stats and used by solveIntercept.
-- Falls back to 60 ms if Stats is unavailable (e.g. some executors).
local _ping = 0.060 -- seconds; updated below

task.spawn(function()
    while true do
        pcall(function()
            local stats = game:GetService("Stats")
            local raw = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            -- Clamp to a sane range (5 ms – 500 ms) and convert to seconds
            _ping = math.clamp(raw, 5, 500) / 1000
        end)
        task.wait(1)
    end
end)

-- Returns the effective ping in seconds.
-- If the user has enabled the manual override slider, that value wins.
local function getPing()
    if predictionState.pingEnabled then
        return math.clamp(predictionState.pingValue, 5, 300) / 1000
    end
    return _ping
end

-- ── Kalman filter (per-axis, position + velocity) ─────────────────
local KQ_P, KQ_V = 0.04, 1.20   -- process noise: lower = trust model more
local KR_P, KR_V = 0.18, 0.70   -- measurement noise: lower = trust sensor more

local function kNew(p, v)
    return { p=p, v=v, pp=1, pv=0, vv=1 }
end

local function kStep(k, mp, mv, dt)
    if dt <= 0 then return end
    -- Predict step
    local pp  = k.p + k.v*dt
    local vp  = k.v
    local PPp = k.pp + dt*(2*k.pv + dt*k.vv) + KQ_P
    local PVp = k.pv + dt*k.vv
    local VVp = k.vv + KQ_V
    -- Innovation
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
        lastT = tick(),
    }
    return pTrackers[player]
end

-- Feed Kalman every RenderStepped/Heartbeat
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
    t.lastT = now
end

-- Get Kalman-smoothed velocity for a player
local function getSmoothedVel(player)
    local t = pTrackers[player]
    if not t then
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        return root and root.AssemblyLinearVelocity or Vector3.new()
    end
    return Vector3.new(t.kx.v, t.ky.v, t.kz.v)
end

-- ── KC8WAJ6 prediction formulas ───────────────────────────────────
--
-- SEISMIC (88% hit rate per KC8WAJ6 docs):
--   scaled = vel / 16.5
--   predicted = pos + Vector3(scaled.X, clamp(scaled.Y,-2,2.65), scaled.Z/1.25)
--
-- OVERFLOW (90% hit rate per KC8WAJ6 docs):
--   scaled = vel / 17 + MoveDirection
--   predicted = pos + Vector3(scaled.X, clamp(scaled.Y,-2,2.5), scaled.Z)
--
-- BLEND (default): 60% Overflow + 40% Seismic

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

-- ── Gun/hitscan solve (used by doFusionShoot / sheriff aim) ───────
--
-- Physics basis: for a hitscan (instantaneous) gun with server-side lag
-- compensation, the server will register the hit at the position the target
-- was at (now - ping).  We therefore need to predict where the target WILL
-- be ping seconds from now so the server sees them at the right place.
--
--   predicted = pos + vel * ping   ← primary lag-compensation term
--   + moveDir * walkSpeed * ping * 0.35  ← input bias (player is pressing a key)
--   + seismic/overflow blend as a micro-correction for sub-frame jitter
--
-- Y is clamped to ±2.5 studs to avoid shooting over/under the character.
-- A +1.5 Y head offset shifts the aim point from root centre to upper chest.
local function solveIntercept(player)
    local char = player.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local hum  = char:FindFirstChild("Humanoid"); if not hum then return nil end

    local smoothVel = getSmoothedVel(player)
    local ping = getPing()   -- seconds (live-measured or slider override)

    -- Primary lag-compensation: where will the root be in `ping` seconds?
    local velOffset  = smoothVel * ping

    -- Secondary input bias: player may be holding a direction key
    local inputBias  = hum.MoveDirection * (hum.WalkSpeed * ping * 0.35)

    -- Micro-correction: seismic/overflow blend for sub-frame velocity noise
    -- Weight is reduced (20/15) because the primary term above already covers
    -- most of the offset; these just fine-tune the remaining jitter.
    local pSE = seismicPredict(root, smoothVel)
    local pOV = overflowPredict(root, hum, smoothVel)
    local microCorrect = Vector3.new(
        (pOV.X - root.Position.X) * 0.2 + (pSE.X - root.Position.X) * 0.15,
        (pOV.Y - root.Position.Y) * 0.2 + (pSE.Y - root.Position.Y) * 0.15,
        (pOV.Z - root.Position.Z) * 0.2 + (pSE.Z - root.Position.Z) * 0.15
    )

    -- Combine all terms, clamp Y so we stay within the character bounding box
    local rawOffset = velOffset + inputBias + microCorrect
    local clampedY  = math.clamp(rawOffset.Y, -2.5, 2.5)
    local predicted = root.Position + Vector3.new(rawOffset.X, clampedY, rawOffset.Z)

    -- Head offset: aim at upper chest / neck, not the HumanoidRootPart centre
    predicted = Vector3.new(predicted.X, predicted.Y + 1.5, predicted.Z)

    -- Floor / ceiling safety clamp
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {char}
    local fR = workspace:Raycast(predicted, Vector3.new(0, -6, 0), rp)
    local cR = workspace:Raycast(predicted, Vector3.new(0,  6, 0), rp)
    if fR then predicted = Vector3.new(predicted.X, math.max(predicted.Y, fR.Position.Y + 1.5), predicted.Z) end
    if cR then predicted = Vector3.new(predicted.X, math.min(predicted.Y, cR.Position.Y - 0.5), predicted.Z) end

    return predicted
end

-- ── Knife/projectile solve (used by doKnifeThrow) ─────────────────
-- KC8WAJ6 exact MurdererSilentAim: vel/3 with Y/1.5
local function solveKnifeIntercept(player)
    local char = player.Character; if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local hum  = char:FindFirstChild("Humanoid"); if not hum then return nil end
    local head = char:FindFirstChild("Head")

    local smoothVel = getSmoothedVel(player)

    -- KC8WAJ6 knife formula: vel / 3 with Y / 1.5
    local v = smoothVel / 3
    local predicted = root.Position + Vector3.new(v.X, v.Y / 1.5, v.Z)

    -- Head offset
    predicted = Vector3.new(predicted.X, predicted.Y + 1.5, predicted.Z)

    -- Clamp to floor
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = {char}
    local fR = workspace:Raycast(predicted, Vector3.new(0, -6, 0), rp)
    if fR then predicted = Vector3.new(predicted.X, math.max(predicted.Y, fR.Position.Y + 1.5), predicted.Z) end

    return predicted
end

-- Backwards-compat alias used by older call sites
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

 -- Equip from backpack if needed
 if LocalPlayer.Backpack:FindFirstChild(gun.Name) then
 humanoid:EquipTool(gun)
 task.wait(0.05) -- minimum wait for server to acknowledge equip
 gun = myChar:FindFirstChild("Gun") or myChar:FindFirstChild("Revolver")
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
-- KNIFE THROW SILENT AIM ENGINE
-- Only active when localRole == "Murderer".
-- Two modes:
-- Nearest — always targets the single closest alive player.
-- In Range — throws at any player that steps within throwRange studs.
-- Prediction: reuses Fusion Engine solveIntercept for lag compensation.
-- Remote path (KC8WAJ6): knife.KnifeServer.ShootGun:InvokeServer(0, pos, "AH")
-- ================================================================

local knifeThrowState = {
 enabled = false, -- master toggle (manual keybind active)
 autoThrow = false, -- Heartbeat auto-throw
 throwRange = 30, -- studs — applies to both modes
 targetMode = "Nearest", -- "Nearest" | "In Range"
 cooldownTime = 0.6, -- seconds between auto-throws
 lastThrowTime = 0,
}

-- Helpers 
local function getKnife()
 local myChar = LocalPlayer.Character; if not myChar then return nil end
 local k = myChar:FindFirstChild("Knife")
 if k and k:IsA("Tool") then return k, false end -- already equipped
 k = LocalPlayer.Backpack:FindFirstChild("Knife")
 if k and k:IsA("Tool") then return k, true end -- needs equipping
 return nil, false
end

local function getKnifeRemote(knife)
 local ks = knife and knife:FindFirstChild("KnifeServer")
 return ks and ks:FindFirstChild("ShootGun")
end

-- Returns the nearest alive player within maxRange (nil if none found)
local function getNearestPlayer(maxRange)
 local myChar = LocalPlayer.Character; if not myChar then return nil end
 local myRoot = myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return nil end
 local nearest, nearestDist = nil, math.huge
 for _, player in ipairs(Players:GetPlayers()) do
 if player ~= LocalPlayer then
 local char = player.Character
 local root = char and char:FindFirstChild("HumanoidRootPart")
 local hum = char and char:FindFirstChild("Humanoid")
 if root and hum and hum.Health > 0 then
 local dist = (root.Position - myRoot.Position).Magnitude
 if dist <= (maxRange or math.huge) and dist < nearestDist then
 nearest, nearestDist = player, dist
 end
 end
 end
 end
 return nearest, nearestDist
end

-- Core throw function 
local function doKnifeThrow(targetPlayer)
 if localRole ~= "Murderer" then
 Fluent:Notify({ Title = "Knife Throw", Content = "You are not the Murderer.", Duration = 3 })
 return
 end
 local char = targetPlayer.Character; if not char then return end
 local tRoot = char:FindFirstChild("HumanoidRootPart"); if not tRoot then return end
 local tHead = char:FindFirstChild("Head")

 local myChar = LocalPlayer.Character; if not myChar then return end
 local humanoid = myChar:FindFirstChildOfClass("Humanoid"); if not humanoid then return end

 -- Get knife and equip if needed 
 local knife, needsEquip = getKnife()
 if not knife then
 Fluent:Notify({ Title = "Knife Throw", Content = "Knife not found.", Duration = 3 })
 return
 end
 if needsEquip then
 humanoid:EquipTool(knife)
 task.wait(0.05)
 knife = myChar:FindFirstChild("Knife")
 if not knife then return end
 end

 local remote = getKnifeRemote(knife)
 if not remote then return end

 -- KC8WAJ6 knife formula: vel/3 with Y/1.5
    phantomUpdate(targetPlayer)
    local predicted = solveKnifeIntercept(targetPlayer)
                   or (tHead and tHead.Position)
                   or tRoot.Position + Vector3.new(0, 1.5, 0)

 -- Frame 0: fire synchronously right after equip 
 pcall(function()
 remote:InvokeServer(0, predicted, "AH")
 end)

 -- Frame 1-2: burst for lag tolerance (KC8WAJ6 pattern) 
 local burst = 0
 local burstConn
 burstConn = RunService.Heartbeat:Connect(function()
 burst = burst + 1
 if burst > 2 then burstConn:Disconnect(); return end
 -- Refresh intercept each burst frame
 local freshPredicted = solveKnifeIntercept(targetPlayer)
                            or (tHead and tHead.Position)
                            or tRoot.Position + Vector3.new(0, 1.5, 0)
        pcall(function()
            remote:InvokeServer(0, freshPredicted, "AH")
 end)
 end)

 knifeThrowState.lastThrowTime = tick()
end

-- Auto-throw Heartbeat loop 
RunService.Heartbeat:Connect(function()
 if not knifeThrowState.autoThrow then return end
 if localRole ~= "Murderer" then return end
 if tick() - knifeThrowState.lastThrowTime < knifeThrowState.cooldownTime then return end

 local target = getNearestPlayer(knifeThrowState.throwRange)
 if target then
 task.spawn(function() doKnifeThrow(target) end)
 end
end)

-- Manual keybind: default T 
UserInputService.InputBegan:Connect(function(input, gameProcessed)
 if gameProcessed or not knifeThrowState.enabled then return end
 if input.KeyCode ~= Enum.KeyCode.T then return end
 if localRole ~= "Murderer" then
 Fluent:Notify({ Title = "Knife Throw", Content = "You must be the Murderer.", Duration = 3 })
 return
 end
 local target = getNearestPlayer(knifeThrowState.throwRange)
 if target then
 task.spawn(function() doKnifeThrow(target) end)
 else
 Fluent:Notify({
 Title = "Knife Throw",
 Content = string.format("No player found within %d studs.", knifeThrowState.throwRange),
 Duration = 3
 })
 end
end)

-- ================================================================
-- SILENT AIM BUTTON (uses Fusion Engine + correct KnifeServer remote)
-- ================================================================
SilentAimButtonV2.MouseButton1Click:Connect(function()
 local murderer=GetMurderer()
 if not murderer then return end
 doFusionShoot(murderer)
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

-- ── Root ───────────────────────────────────────────────────────
local OmniLoader = Instance.new("ScreenGui")
OmniLoader.Name            = "OmniLoader"
OmniLoader.ResetOnSpawn    = false
OmniLoader.DisplayOrder    = 999
OmniLoader.IgnoreGuiInset  = true
OmniLoader.Parent          = game.CoreGui

-- ── Full-screen soft bg ────────────────────────────────────────
local Bg = Instance.new("Frame")
Bg.Name                  = "Bg"
Bg.Size                  = UDim2.fromScale(1, 1)
Bg.BackgroundColor3      = Color3.fromRGB(9, 10, 16)
Bg.BackgroundTransparency = 0
Bg.BorderSizePixel       = 0
Bg.Parent                = OmniLoader

-- Subtle radial vignette — just two concentric gradient frames
local Vig = Instance.new("ImageLabel")
Vig.Name                 = "Vignette"
Vig.Size                 = UDim2.fromScale(1.4, 1.8)
Vig.AnchorPoint          = Vector2.new(0.5, 0.5)
Vig.Position             = UDim2.fromScale(0.5, 0.5)
Vig.BackgroundTransparency = 1
Vig.Image                = "rbxassetid://6015897843"  -- radial gradient (white center)
Vig.ImageColor3          = Color3.fromRGB(18, 22, 40)
Vig.ImageTransparency    = 0.55
Vig.ZIndex               = 1
Vig.Parent               = Bg

-- ── Main card ──────────────────────────────────────────────────
local Card = Instance.new("Frame")
Card.Name             = "Card"
Card.AnchorPoint      = Vector2.new(0.5, 0.5)
Card.Position         = UDim2.fromScale(0.5, 0.5)
Card.Size             = UDim2.fromOffset(400, 200)
Card.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
Card.BorderSizePixel  = 0
Card.ZIndex           = 2
Card.Parent           = OmniLoader

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 14)
CardCorner.Parent       = Card

-- Thin border stroke — very low opacity
local CardStroke = Instance.new("UIStroke")
CardStroke.Color       = Color3.fromRGB(200, 180, 100)
CardStroke.Thickness   = 1
CardStroke.Transparency = 0.72
CardStroke.Parent      = Card

-- ── Ambient glow behind card (soft bloom) ─────────────────────
local Glow = Instance.new("ImageLabel")
Glow.Name                 = "Glow"
Glow.AnchorPoint          = Vector2.new(0.5, 0.5)
Glow.Position             = UDim2.fromScale(0.5, 0.5)
Glow.Size                 = UDim2.fromOffset(560, 340)
Glow.BackgroundTransparency = 1
Glow.Image                = "rbxassetid://6015897843"
Glow.ImageColor3          = Color3.fromRGB(80, 100, 200)
Glow.ImageTransparency    = 0.88
Glow.ZIndex               = 1
Glow.Parent               = OmniLoader

-- ── Thin top accent line ───────────────────────────────────────
local Accent = Instance.new("Frame")
Accent.Name             = "Accent"
Accent.Size             = UDim2.new(0, 0, 0, 2)
Accent.Position         = UDim2.new(0, 0, 0, 0)
Accent.BackgroundColor3 = Color3.fromRGB(200, 170, 80)
Accent.BorderSizePixel  = 0
Accent.ZIndex           = 4
Accent.Parent           = Card

local AccentGrad = Instance.new("UIGradient")
AccentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(180, 140, 40)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 200, 80)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(180, 140, 40)),
})
AccentGrad.Parent = Accent

local AccentCorner = Instance.new("UICorner")
AccentCorner.CornerRadius = UDim.new(1, 0)
AccentCorner.Parent       = Accent

-- ── Logo text ──────────────────────────────────────────────────
local Title = Instance.new("TextLabel")
Title.Name                = "Title"
Title.AnchorPoint         = Vector2.new(0.5, 0)
Title.Position            = UDim2.new(0.5, 0, 0, 26)
Title.Size                = UDim2.fromOffset(320, 44)
Title.BackgroundTransparency = 1
Title.Font                = Enum.Font.GothamBold
Title.Text                = "OmniHub"
Title.TextColor3          = Color3.fromRGB(230, 210, 140)
Title.TextSize            = 34
Title.TextTransparency    = 1
Title.ZIndex              = 5
Title.Parent              = Card

-- Muted version text beside title
local Version = Instance.new("TextLabel")
Version.Name              = "Version"
Version.AnchorPoint       = Vector2.new(0.5, 0)
Version.Position          = UDim2.new(0.5, 0, 0, 70)
Version.Size              = UDim2.fromOffset(200, 18)
Version.BackgroundTransparency = 1
Version.Font              = Enum.Font.Gotham
Version.Text              = "v1.1.0  |  by Azzakirms"
Version.TextColor3        = Color3.fromRGB(100, 100, 120)
Version.TextSize          = 12
Version.TextTransparency  = 1
Version.ZIndex            = 5
Version.Parent            = Card

-- ── Progress track ─────────────────────────────────────────────
local Track = Instance.new("Frame")
Track.Name             = "Track"
Track.AnchorPoint      = Vector2.new(0.5, 0)
Track.Position         = UDim2.new(0.5, 0, 0, 118)
Track.Size             = UDim2.new(0.78, 0, 0, 4)
Track.BackgroundColor3 = Color3.fromRGB(30, 32, 48)
Track.BorderSizePixel  = 0
Track.ZIndex           = 5
Track.Parent           = Card

local TrackCorner = Instance.new("UICorner")
TrackCorner.CornerRadius = UDim.new(1, 0)
TrackCorner.Parent       = Track

-- Fill
local Fill = Instance.new("Frame")
Fill.Name             = "Fill"
Fill.Size             = UDim2.new(0, 0, 1, 0)
Fill.BackgroundColor3 = Color3.fromRGB(200, 170, 80)
Fill.BorderSizePixel  = 0
Fill.ZIndex           = 6
Fill.Parent           = Track

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(1, 0)
FillCorner.Parent       = Fill

local FillGrad = Instance.new("UIGradient")
FillGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(160, 130, 50)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(230, 200, 90)),
})
FillGrad.Parent = Fill

-- ── Status label ───────────────────────────────────────────────
local Status = Instance.new("TextLabel")
Status.Name              = "Status"
Status.AnchorPoint       = Vector2.new(0.5, 0)
Status.Position          = UDim2.new(0.5, 0, 0, 134)
Status.Size              = UDim2.new(0.85, 0, 0, 18)
Status.BackgroundTransparency = 1
Status.Font              = Enum.Font.Gotham
Status.Text              = ""
Status.TextColor3        = Color3.fromRGB(110, 115, 140)
Status.TextSize          = 12
Status.TextTransparency  = 0
Status.TextXAlignment    = Enum.TextXAlignment.Left
Status.ZIndex            = 5
Status.Parent            = Card

-- Subtle bottom hint
local Hint = Instance.new("TextLabel")
Hint.Name              = "Hint"
Hint.AnchorPoint       = Vector2.new(0.5, 0)
Hint.Position          = UDim2.new(0.5, 0, 0, 170)
Hint.Size              = UDim2.fromOffset(300, 14)
Hint.BackgroundTransparency = 1
Hint.Font              = Enum.Font.Gotham
Hint.Text              = "Murder Mystery 2"
Hint.TextColor3        = Color3.fromRGB(50, 52, 68)
Hint.TextSize          = 11
Hint.TextTransparency  = 0
Hint.ZIndex            = 5
Hint.Parent            = Card

-- ── Breathing glow animation loop ─────────────────────────────
local breathActive = true
local function breathe()
    while breathActive do
        ease(Glow, { ImageTransparency = 0.82 }, 1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.85)
        ease(Glow, { ImageTransparency = 0.92 }, 1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.85)
    end
end
task.spawn(breathe)

-- ── Loader sequence ────────────────────────────────────────────
local STAGES = {
    { "Verifying environment...",        0.15 },
    { "Loading combat modules...",       0.38 },
    { "Initializing ESP engine...",      0.60 },
    { "Building prediction system...",   0.82 },
    { "Ready.",                          1.00 },
}

local function animateOmniLoader()
    -- Enter: card fades + drifts in from slight offset
    Card.BackgroundTransparency = 1
    Card.Position = UDim2.new(0.5, 0, 0.52, 0)
    CardStroke.Transparency = 1

    task.wait(0.1)

    ease(Card, { BackgroundTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.7, Enum.EasingStyle.Quint)
    ease(CardStroke, { Transparency = 0.72 }, 1.0)
    task.wait(0.2)
    fadeIn(Title, 0.7)
    task.wait(0.18)
    fadeIn(Version, 0.6)
    task.wait(0.1)

    -- Accent bar sweeps in
    ease(Accent, { Size = UDim2.new(1, 0, 0, 2) }, 0.9, Enum.EasingStyle.Quint)
    task.wait(0.5)

    -- Stages — loader runs fully, no blocking
    for _, stage in ipairs(STAGES) do
        local msg, pct = stage[1], stage[2]
        Status.Text = msg

        local ft = ease(Fill, { Size = UDim2.new(pct, 0, 1, 0) }, 1.1, Enum.EasingStyle.Quad)
        ease(Fill, { BackgroundColor3 = Color3.fromRGB(240, 215, 100) }, 0.3)
        task.wait(0.35)
        ease(Fill, { BackgroundColor3 = Color3.fromRGB(200, 170, 80) }, 0.6)
        ft.Completed:Wait()
        task.wait(0.25)
    end

    task.wait(0.5)

    -- Fade out
    breathActive = false
    local fo = TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
    _TS:Create(Bg, fo, { BackgroundTransparency = 1 }):Play()
    _TS:Create(Card, fo, { BackgroundTransparency = 1 }):Play()
    _TS:Create(Glow, fo, { ImageTransparency = 1 }):Play()
    _TS:Create(Vig, fo, { ImageTransparency = 1 }):Play()
    for _, c in ipairs(Card:GetDescendants()) do
        if c:IsA("TextLabel") then
            _TS:Create(c, fo, { TextTransparency = 1 }):Play()
        elseif c:IsA("Frame") then
            _TS:Create(c, fo, { BackgroundTransparency = 1 }):Play()
        end
    end
    task.wait(0.6)
    OmniLoader:Destroy()
end

animateOmniLoader()

-- ── Auth gate: wait for background check to finish (it usually
--   finishes long before the loader does), then act on result ──
local _authWait = 0
while not _authDone and _authWait < 8 do
    task.wait(0.1)
    _authWait = _authWait + 0.1
end

local function doKick(reason)
    pcall(function() Players.LocalPlayer:Kick(reason) end)
end

if not _authDone or not _authResult then
    doKick("Auth server timeout. Try again.")
    return
end

local d = _authResult

if d.status == "ratelimited" then
    doKick("Rate limited. Wait " .. tostring(d.remaining or 60) .. "s and try again.")
    return
end

if d.status == "maintenance" then
    doKick("Script under maintenance: " .. (d.reason or "Please wait."))
    return
end

if d.status == "blacklisted" then
    doKick("Banned — " .. (d.reason or "Contact the script owner."))
    return
end

if d.status ~= "allowed" then
    doKick("Unauthorized. You are not whitelisted.")
    return
end

-- ✅ Allowed — lock HWID if server returned one
if d.hwid_lock and d.hwid_lock ~= "" then
    _authHWID = d.hwid_lock
end




-- Fluent UI Integration
-- Uses _fetchRaw so it works on Delta and every other executor (no game:HttpGet dependency)
local function safeLoad(url, label)
    local res = _fetchRaw(url)  -- no auth header needed for public CDN
    if not res or type(res.Body) ~= "string" or #res.Body < 10 then
        error("[OmniHub] Could not download " .. (label or url), 2)
    end
    local chunk, err = loadstring(res.Body)
    if not chunk then
        error("[OmniHub] Parse error in " .. (label or url) .. ": " .. tostring(err), 2)
    end
    local ok, result = pcall(chunk)
    if not ok then
        error("[OmniHub] Runtime error in " .. (label or url) .. ": " .. tostring(result), 2)
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
 Farming = Window:AddTab({ Title = "Farming", Icon = "dollar-sign" }),
 Values = Window:AddTab({ Title = "Values", Icon = "bar-chart-2" }),
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

-- Update timer
game:GetService("RunService").RenderStepped:Connect(function()
 if TimerGui.Enabled then
 local success, timeLeft = pcall(function()
 return timerRemote:InvokeServer()
 end)
 
 if success and timeLeft then
 local formattedTime = formatTime(timeLeft)
 TimerLabel.Text = formattedTime
 TextShadow.Text = formattedTime
 
 -- Color changes based on time remaining
 if timeLeft <= 10 then
 TimerLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red for last 10 seconds
 elseif timeLeft <= 30 then
 TimerLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange for last 30 seconds
 else
 TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White for normal time
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

-- Farming Tab Content
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


local AutoGetGunDropToggle = Tabs.Combat:AddToggle("AutoGetGunDropToggle", {
 Title = "Auto Get Gun Drop",
 Default = false,
 Callback = function(toggle)
 state.autoGetGunDropEnabled = toggle
 end
})

-- ================================================================
-- KNIFE THROW SILENT AIM — UI CONTROLS (Murderer only)
-- ================================================================
Tabs.Combat:AddSection("Knife Throw Silent Aim (Murderer)")

Tabs.Combat:AddToggle("KnifeThrowToggle", {
 Title = "Enable Knife Throw Silent Aim",
 Description = "Press [T] to throw the knife at the nearest player. Murderer only.",
 Default = false,
 Callback = function(toggle)
 knifeThrowState.enabled = toggle
 Fluent:Notify({
 Title = "Knife Throw Silent Aim",
 Content = toggle
 and "ENABLED — press [T] to throw at nearest player."
 or "Disabled.",
 Duration = 3
 })
 end
})

Tabs.Combat:AddDropdown("KnifeTargetModeDropdown", {
 Title = "Target Mode",
 Description = "Nearest = always closest player. In Range = first player within range.",
 Values = { "Nearest", "In Range" },
 Default = 1,
 Callback = function(value)
 knifeThrowState.targetMode = value
 end
})

Tabs.Combat:AddSlider("KnifeThrowRangeSlider", {
 Title = "Throw Range (studs)",
 Description = "Max distance to consider a player a valid target.",
 Default = 30,
 Min = 5,
 Max = 100,
 Rounding = 0,
 Callback = function(value)
 knifeThrowState.throwRange = value
 end
})

Tabs.Combat:AddSlider("KnifeThrowCooldownSlider", {
 Title = "Auto-Throw Cooldown (ms)",
 Description = "Minimum time between automatic throws to avoid spam detection.",
 Default = 600,
 Min = 100,
 Max = 2000,
 Rounding = 0,
 Callback = function(value)
 knifeThrowState.cooldownTime = value / 1000
 end
})

Tabs.Combat:AddToggle("KnifeAutoThrowToggle", {
 Title = "Auto-Throw (Heartbeat)",
 Description = "Automatically throws knife when any player enters throw range. Murderer only.",
 Default = false,
 Callback = function(toggle)
 knifeThrowState.autoThrow = toggle
 Fluent:Notify({
 Title = "Auto Knife Throw",
 Content = toggle
 and string.format("AUTO-THROW ON — will throw within %d studs.", knifeThrowState.throwRange)
 or "Auto-throw disabled.",
 Duration = 3
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

-- Event to detect gun drop in the game
Workspace.DescendantAdded:Connect(function(descendant)
 if descendant.Name == "GunDrop" then
 state.gunDrop = descendant
 end
end)

Workspace.DescendantRemoving:Connect(function(descendant)
 if descendant.Name == "GunDrop" then
 state.gunDrop = nil
 end
end)

-- Auto-execute function on every frame
RunService.Heartbeat:Connect(function()
 if state.autoGetGunDropEnabled then
 collectGunDrop()
 end
end)



-- ================================================================
-- VALUE CHECKER ENGINE
--
-- All values are hardcoded directly from supremevalues.com
-- Last synced: February 23rd, 2026
-- No API or HTTP requests needed — works instantly, offline.
-- ================================================================

local RARITY_COLORS = {
 ["unique"] = "🟣",
 ["evo"] = "",
 ["ancient"] = "🟠",
 ["vintage"] = "🟡",
 ["chroma"] = "",
 ["godly"] = "",
 ["legendary"] = "🟢",
 ["rare"] = "",
 ["uncommon"] = "",
 ["common"] = "",
 ["pet"] = "",
 ["misc"] = "",
}

local RARITY_ORDER = {
 "unique","evo","ancient","vintage","chroma",
 "godly","legendary","rare","uncommon","common","pet","misc"
}

-- Static Value Database 
-- Format: ["item name lowercase"] = { name, value, demand, rarity }
-- Source: supremevalues.com — Updated Feb 23, 2026
local SV_DATABASE = {
 -- 
 -- CHROMAS
 -- 
 ["chroma traveler's gun"] = { name="Chroma Traveler's Gun", value=210000, demand=9, rarity="chroma" },
 ["chroma evergun"] = { name="Chroma Evergun", value=91000, demand=8, rarity="chroma" },
 ["chroma evergreen"] = { name="Chroma Evergreen", value=60000, demand=7, rarity="chroma" },
 ["chroma bauble"] = { name="Chroma Bauble", value=51000, demand=7, rarity="chroma" },
 ["chroma vampire's gun"] = { name="Chroma Vampire's Gun", value=44000, demand=7, rarity="chroma" },
 ["chroma constellation"] = { name="Chroma Constellation", value=41000, demand=7, rarity="chroma" },
 ["chroma alienbeam"] = { name="Chroma Alienbeam", value=29000, demand=7, rarity="chroma" },
 ["chroma raygun"] = { name="Chroma Raygun", value=15500, demand=7, rarity="chroma" },
 ["chroma blizzard"] = { name="Chroma Blizzard", value=15500, demand=6, rarity="chroma" },
 ["chroma sunrise"] = { name="Chroma Sunrise", value=10500, demand=6, rarity="chroma" },
 ["chroma snowcannon"] = { name="Chroma Snowcannon", value=10000, demand=6, rarity="chroma" },
 ["chroma treat"] = { name="Chroma Treat", value=9500, demand=7, rarity="chroma" },
 ["chroma snowstorm"] = { name="Chroma Snowstorm", value=9500, demand=6, rarity="chroma" },
 ["chroma sweet"] = { name="Chroma Sweet", value=8500, demand=7, rarity="chroma" },
 ["chroma heart wand"] = { name="Chroma Heart Wand", value=7000, demand=6, rarity="chroma" },
 ["chroma snow dagger"] = { name="Chroma Snow Dagger", value=6500, demand=6, rarity="chroma" },
 ["chroma sunset"] = { name="Chroma Sunset", value=6250, demand=6, rarity="chroma" },
 ["chroma ornament"] = { name="Chroma Ornament", value=4200, demand=6, rarity="chroma" },
 ["chroma watergun"] = { name="Chroma Watergun", value=3450, demand=6, rarity="chroma" },
 ["chroma darkbringer"] = { name="Chroma Darkbringer", value=95, demand=2, rarity="chroma" },
 ["chroma lightbringer"] = { name="Chroma Lightbringer", value=90, demand=2, rarity="chroma" },
 ["chroma candleflame"] = { name="Chroma Candleflame", value=70, demand=2, rarity="chroma" },
 ["chroma cookiecane"] = { name="Chroma Cookiecane", value=60, demand=2, rarity="chroma" },
 ["chroma elderwood blade"] = { name="Chroma Elderwood Blade", value=60, demand=2, rarity="chroma" },
 ["chroma swirly gun"] = { name="Chroma Swirly Gun", value=60, demand=2, rarity="chroma" },
 ["chroma luger"] = { name="Chroma Luger", value=60, demand=2, rarity="chroma" },
 ["chroma laser"] = { name="Chroma Laser", value=55, demand=2, rarity="chroma" },
 ["chroma deathshard"] = { name="Chroma Deathshard", value=50, demand=2, rarity="chroma" },
 ["chroma shark"] = { name="Chroma Shark", value=50, demand=2, rarity="chroma" },
 ["chroma slasher"] = { name="Chroma Slasher", value=50, demand=2, rarity="chroma" },
 ["chroma fang"] = { name="Chroma Fang", value=45, demand=2, rarity="chroma" },
 ["chroma gemstone"] = { name="Chroma Gemstone", value=45, demand=2, rarity="chroma" },
 ["chroma heat"] = { name="Chroma Heat", value=45, demand=2, rarity="chroma" },
 ["chroma tides"] = { name="Chroma Tides", value=42, demand=2, rarity="chroma" },
 ["chroma boneblade"] = { name="Chroma Boneblade", value=40, demand=2, rarity="chroma" },
 ["chroma gingerblade"] = { name="Chroma Gingerblade", value=40, demand=2, rarity="chroma" },
 ["chroma saw"] = { name="Chroma Saw", value=40, demand=2, rarity="chroma" },
 ["chroma seer"] = { name="Chroma Seer", value=40, demand=2, rarity="chroma" },
 ["chroma fire bat"] = { name="Chroma Fire Bat", value=8, demand=1, rarity="chroma" },
 ["chroma fire bear"] = { name="Chroma Fire Bear", value=8, demand=1, rarity="chroma" },
 ["chroma fire bunny"] = { name="Chroma Fire Bunny", value=8, demand=1, rarity="chroma" },
 ["chroma fire cat"] = { name="Chroma Fire Cat", value=8, demand=1, rarity="chroma" },
 ["chroma fire dog"] = { name="Chroma Fire Dog", value=8, demand=1, rarity="chroma" },
 ["chroma fire fox"] = { name="Chroma Fire Fox", value=8, demand=1, rarity="chroma" },
 ["chroma fire pig"] = { name="Chroma Fire Pig", value=8, demand=1, rarity="chroma" },

 -- 
 -- ANCIENTS
 -- 
 ["gingerscope"] = { name="Gingerscope", value=17000, demand=7, rarity="ancient" },
 ["traveler's axe"] = { name="Traveler's Axe", value=7800, demand=6, rarity="ancient" },
 ["celestial"] = { name="Celestial", value=1800, demand=5, rarity="ancient" },
 ["vampire's axe"] = { name="Vampire's Axe", value=950, demand=5, rarity="ancient" },
 ["harvester"] = { name="Harvester", value=400, demand=4, rarity="ancient" },
 ["icepiercer"] = { name="Icepiercer", value=300, demand=4, rarity="ancient" },
 ["icebreaker"] = { name="Icebreaker", value=115, demand=2, rarity="ancient" },
 ["batwing"] = { name="Batwing", value=57, demand=2, rarity="ancient" },
 ["swirly axe"] = { name="Swirly Axe", value=55, demand=2, rarity="ancient" },
 ["elderwood scythe"] = { name="Elderwood Scythe", value=55, demand=2, rarity="ancient" },
 ["hallowscythe"] = { name="Hallowscythe", value=45, demand=2, rarity="ancient" },
 ["logchopper"] = { name="Logchopper", value=20, demand=2, rarity="ancient" },
 ["icewing"] = { name="Icewing", value=13, demand=2, rarity="ancient" },

 -- 
 -- VINTAGES
 -- 
 ["ghost (vintage)"] = { name="Ghost", value=10, demand=1, rarity="vintage" },
 ["blood"] = { name="Blood", value=8, demand=1, rarity="vintage" },
 ["laser (vintage)"] = { name="Laser (Vintage)", value=8, demand=1, rarity="vintage" },
 ["america (vintage)"] = { name="America", value=7, demand=1, rarity="vintage" },
 ["prince"] = { name="Prince", value=6, demand=1, rarity="vintage" },
 ["shadow (vintage)"] = { name="Shadow", value=6, demand=1, rarity="vintage" },
 ["phaser"] = { name="Phaser", value=5, demand=1, rarity="vintage" },
 ["cowboy"] = { name="Cowboy", value=4, demand=1, rarity="vintage" },
 ["golden"] = { name="Golden", value=4, demand=1, rarity="vintage" },
 ["splitter"] = { name="Splitter", value=3, demand=1, rarity="vintage" },

 -- 
 -- GODLIES (Tier 3)
 -- 
 ["traveler's gun"] = { name="Traveler's Gun", value=4200, demand=6, rarity="godly" },
 ["evergun"] = { name="Evergun", value=3700, demand=6, rarity="godly" },
 ["constellation"] = { name="Constellation", value=3150, demand=6, rarity="godly" },
 ["evergreen"] = { name="Evergreen", value=2850, demand=6, rarity="godly" },
 ["turkey"] = { name="Turkey", value=1800, demand=5, rarity="godly" },
 ["vampire's gun"] = { name="Vampire's Gun", value=1800, demand=5, rarity="godly" },
 ["darkshot"] = { name="Darkshot", value=1060, demand=5, rarity="godly" },
 ["darksword"] = { name="Darksword", value=1040, demand=5, rarity="godly" },
 ["blossom"] = { name="Blossom", value=980, demand=5, rarity="godly" },
 ["sakura"] = { name="Sakura", value=970, demand=5, rarity="godly" },
 ["alienbeam"] = { name="Alienbeam", value=950, demand=5, rarity="godly" },
 ["bauble"] = { name="Bauble", value=875, demand=5, rarity="godly" },
 ["raygun"] = { name="Raygun", value=525, demand=4, rarity="godly" },
 ["sunrise"] = { name="Sunrise", value=525, demand=4, rarity="godly" },
 ["heart wand"] = { name="Heart Wand", value=450, demand=4, rarity="godly" },
 ["snowcannon"] = { name="Snowcannon", value=350, demand=4, rarity="godly" },
 ["soul"] = { name="Soul", value=305, demand=4, rarity="godly" },
 ["rainbow gun"] = { name="Rainbow Gun", value=300, demand=4, rarity="godly" },
 ["sweet"] = { name="Sweet", value=300, demand=4, rarity="godly" },
 ["treat"] = { name="Treat", value=300, demand=4, rarity="godly" },
 ["spirit"] = { name="Spirit", value=295, demand=4, rarity="godly" },
 ["rainbow"] = { name="Rainbow", value=290, demand=4, rarity="godly" },
 ["sunset (knife)"] = { name="Sunset (Knife)", value=275, demand=4, rarity="godly" },
 ["flora"] = { name="Flora", value=265, demand=4, rarity="godly" },
 ["bloom"] = { name="Bloom", value=255, demand=4, rarity="godly" },
 ["snow dagger"] = { name="Snow Dagger", value=220, demand=4, rarity="godly" },
 ["bat"] = { name="Bat", value=205, demand=3, rarity="godly" },
 ["flowerwood gun"] = { name="Flowerwood Gun", value=160, demand=4, rarity="godly" },
 ["blizzard"] = { name="Blizzard", value=155, demand=4, rarity="godly" },
 ["flowerwood"] = { name="Flowerwood", value=155, demand=4, rarity="godly" },
 ["snowstorm"] = { name="Snowstorm", value=155, demand=4, rarity="godly" },
 ["xenoknife"] = { name="Xenoknife", value=150, demand=3, rarity="godly" },
 ["xenoshot"] = { name="Xenoshot", value=150, demand=3, rarity="godly" },
 ["ocean"] = { name="Ocean", value=145, demand=3, rarity="godly" },
 ["waves"] = { name="Waves", value=140, demand=3, rarity="godly" },
 ["candy"] = { name="Candy", value=140, demand=3, rarity="godly" },
 ["watergun"] = { name="Watergun", value=115, demand=2, rarity="godly" },
 ["heartblade"] = { name="Heartblade", value=115, demand=2, rarity="godly" },
 ["borealis"] = { name="Borealis", value=105, demand=3, rarity="godly" },
 ["australis"] = { name="Australis", value=100, demand=3, rarity="godly" },
 -- Godlies (Tier 2)
 ["pearl"] = { name="Pearl", value=60, demand=2, rarity="godly" },
 ["pearlshine"] = { name="Pearlshine", value=60, demand=2, rarity="godly" },
 ["iceblaster"] = { name="Iceblaster", value=60, demand=2, rarity="godly" },
 ["luger"] = { name="Luger", value=60, demand=2, rarity="godly" },
 ["sugar"] = { name="Sugar", value=60, demand=2, rarity="godly" },
 ["candleflame"] = { name="Candleflame", value=55, demand=2, rarity="godly" },
 ["elderwood blade"] = { name="Elderwood Blade", value=55, demand=2, rarity="godly" },
 ["makeshift"] = { name="Makeshift", value=55, demand=2, rarity="godly" },
 ["phantom"] = { name="Phantom", value=55, demand=2, rarity="godly" },
 ["spectre"] = { name="Spectre", value=55, demand=2, rarity="godly" },
 ["darkbringer"] = { name="Darkbringer", value=55, demand=2, rarity="godly" },
 ["elderwood revolver"] = { name="Elderwood Revolver", value=55, demand=2, rarity="godly" },
 ["lightbringer"] = { name="Lightbringer", value=50, demand=2, rarity="godly" },
 ["red luger"] = { name="Red Luger", value=50, demand=2, rarity="godly" },
 ["ornament"] = { name="Ornament", value=45, demand=2, rarity="godly" },
 ["swirly gun"] = { name="Swirly Gun", value=40, demand=2, rarity="godly" },
 ["green luger"] = { name="Green Luger", value=30, demand=2, rarity="godly" },
 ["hallowgun"] = { name="Hallowgun", value=27, demand=2, rarity="godly" },
 ["laser"] = { name="Laser", value=27, demand=2, rarity="godly" },
 ["swirly blade"] = { name="Swirly Blade", value=25, demand=2, rarity="godly" },
 ["amerilaser"] = { name="Amerilaser", value=25, demand=2, rarity="godly" },
 ["icebeam"] = { name="Icebeam", value=25, demand=2, rarity="godly" },
 ["iceflake"] = { name="Iceflake", value=25, demand=2, rarity="godly" },
 ["plasmabeam"] = { name="Plasmabeam", value=25, demand=2, rarity="godly" },
 ["plasmablade"] = { name="Plasmablade", value=25, demand=2, rarity="godly" },
 ["shark"] = { name="Shark", value=23, demand=2, rarity="godly" },
 ["nightblade"] = { name="Nightblade", value=22, demand=2, rarity="godly" },
 ["cookiecane"] = { name="Cookiecane", value=20, demand=2, rarity="godly" },
 ["gingermint"] = { name="Gingermint", value=20, demand=2, rarity="godly" },
 ["blaster"] = { name="Blaster", value=20, demand=2, rarity="godly" },
 ["ginger luger"] = { name="Ginger Luger", value=20, demand=2, rarity="godly" },
 ["minty"] = { name="Minty", value=20, demand=2, rarity="godly" },
 ["pixel"] = { name="Pixel", value=20, demand=2, rarity="godly" },
 ["slasher"] = { name="Slasher", value=20, demand=2, rarity="godly" },
 -- Godlies (Tier 1)
 ["eternalcane"] = { name="Eternalcane", value=18, demand=2, rarity="godly" },
 ["lugercane"] = { name="Lugercane", value=18, demand=2, rarity="godly" },
 ["old glory"] = { name="Old Glory", value=18, demand=2, rarity="godly" },
 ["battleaxe ii"] = { name="Battleaxe II", value=18, demand=1, rarity="godly" },
 ["gingerblade"] = { name="Gingerblade", value=18, demand=1, rarity="godly" },
 ["jinglegun"] = { name="Jinglegun", value=17, demand=2, rarity="godly" },
 ["virtual"] = { name="Virtual", value=17, demand=2, rarity="godly" },
 ["gemstone"] = { name="Gemstone", value=17, demand=1, rarity="godly" },
 ["nebula"] = { name="Nebula", value=15, demand=2, rarity="godly" },
 ["vampire's edge"] = { name="Vampire's Edge", value=15, demand=2, rarity="godly" },
 ["deathshard"] = { name="Deathshard", value=15, demand=1, rarity="godly" },
 ["battleaxe"] = { name="Battleaxe", value=12, demand=1, rarity="godly" },
 ["bioblade"] = { name="Bioblade", value=10, demand=1, rarity="godly" },
 ["chill"] = { name="Chill", value=10, demand=1, rarity="godly" },
 ["clockwork"] = { name="Clockwork", value=10, demand=1, rarity="godly" },
 ["eternal iii"] = { name="Eternal III", value=10, demand=1, rarity="godly" },
 ["eternal iv"] = { name="Eternal IV", value=10, demand=1, rarity="godly" },
 ["fang"] = { name="Fang", value=10, demand=1, rarity="godly" },
 ["frostsaber"] = { name="Frostsaber", value=10, demand=1, rarity="godly" },
 ["heat"] = { name="Heat", value=10, demand=1, rarity="godly" },
 ["spider"] = { name="Spider", value=10, demand=1, rarity="godly" },
 ["tides"] = { name="Tides", value=10, demand=1, rarity="godly" },
 ["eternal"] = { name="Eternal", value=8, demand=1, rarity="godly" },
 ["eternal ii"] = { name="Eternal II", value=8, demand=1, rarity="godly" },
 ["hallow's blade"] = { name="Hallow's Blade", value=8, demand=1, rarity="godly" },
 ["hallow's edge"] = { name="Hallow's Edge", value=8, demand=1, rarity="godly" },
 ["handsaw"] = { name="Handsaw", value=8, demand=1, rarity="godly" },
 ["xmas"] = { name="Xmas", value=8, demand=1, rarity="godly" },
 ["boneblade"] = { name="Boneblade", value=7, demand=1, rarity="godly" },
 ["frostbite"] = { name="Frostbite", value=7, demand=1, rarity="godly" },
 ["ghostblade"] = { name="Ghostblade", value=7, demand=1, rarity="godly" },
 ["ice dragon"] = { name="Ice Dragon", value=7, demand=1, rarity="godly" },
 ["ice shard"] = { name="Ice Shard", value=7, demand=1, rarity="godly" },
 ["prismatic"] = { name="Prismatic", value=7, demand=1, rarity="godly" },
 ["pumpking"] = { name="Pumpking", value=7, demand=1, rarity="godly" },
 ["saw"] = { name="Saw", value=7, demand=1, rarity="godly" },
 ["eggblade"] = { name="Eggblade", value=5, demand=1, rarity="godly" },
 ["flames"] = { name="Flames", value=5, demand=1, rarity="godly" },
 ["snowflake"] = { name="Snowflake", value=5, demand=1, rarity="godly" },
 ["winter's edge"] = { name="Winter's Edge", value=5, demand=1, rarity="godly" },
 -- Godlies (Tier 0)
 ["peppermint"] = { name="Peppermint", value=4, demand=1, rarity="godly" },
 ["cookieblade"] = { name="Cookieblade", value=3, demand=1, rarity="godly" },
 ["blue seer"] = { name="Blue Seer", value=3, demand=1, rarity="godly" },
 ["purple seer"] = { name="Purple Seer", value=3, demand=1, rarity="godly" },
 ["red seer"] = { name="Red Seer", value=3, demand=1, rarity="godly" },
 ["seer"] = { name="Seer", value=3, demand=1, rarity="godly" },
 ["orange seer"] = { name="Orange Seer", value=2, demand=1, rarity="godly" },
 ["yellow seer"] = { name="Yellow Seer", value=2, demand=1, rarity="godly" },

 -- 
 -- LEGENDARIES (numeric values only)
 -- 
 ["latte (gun)"] = { name="Latte (Gun)", value=130, demand=3, rarity="legendary" },
 ["latte (knife)"] = { name="Latte (Knife)", value=130, demand=3, rarity="legendary" },
 ["cotton candy"] = { name="Cotton Candy", value=40, demand=2, rarity="legendary" },
 ["jd"] = { name="JD", value=35, demand=2, rarity="legendary" },
 ["beach"] = { name="Beach", value=30, demand=2, rarity="legendary" },
 ["spectral (knife)"] = { name="Spectral (Knife)", value=20, demand=3, rarity="legendary" },
 ["traveler (gun)"] = { name="Traveler (Gun)", value=20, demand=3, rarity="legendary" },
 ["vampire (gun)"] = { name="Vampire (Gun)", value=13, demand=2, rarity="legendary" },
 ["aurora (gun)"] = { name="Aurora (Gun)", value=10, demand=2, rarity="legendary" },
 ["cavern (knife)"] = { name="Cavern (Knife)", value=7, demand=2, rarity="legendary" },
 ["skulls"] = { name="Skulls", value=7, demand=2, rarity="legendary" },
 ["broken"] = { name="Broken", value=7, demand=2, rarity="legendary" },
 ["ginger (gun)"] = { name="Ginger (Gun)", value=6, demand=1, rarity="legendary" },
 ["arctic (gun)"] = { name="Arctic (Gun)", value=5, demand=2, rarity="legendary" },
 ["bunnies"] = { name="Bunnies", value=5, demand=2, rarity="legendary" },
 ["icedriller"] = { name="Icedriller", value=5, demand=2, rarity="legendary" },
 ["nightsky"] = { name="Nightsky", value=5, demand=2, rarity="legendary" },
 ["ghost (knife)"] = { name="Ghost (Knife)", value=5, demand=1, rarity="legendary" },
 ["red scratch"] = { name="Red Scratch", value=4, demand=1, rarity="legendary" },
 ["witched"] = { name="Witched", value=3, demand=2, rarity="legendary" },
 ["blue elite"] = { name="Blue Elite", value=3, demand=1, rarity="legendary" },
 ["green elite"] = { name="Green Elite", value=3, demand=1, rarity="legendary" },
 ["santa's magic"] = { name="Santa's Magic", value=3, demand=1, rarity="legendary" },
 ["santa's spirit"] = { name="Santa's Spirit", value=3, demand=1, rarity="legendary" },
 ["spectral (gun)"] = { name="Spectral (Gun)", value=2, demand=2, rarity="legendary" },
 ["traveler (knife)"] = { name="Traveler (Knife)", value=2, demand=2, rarity="legendary" },
 ["vampire (knife)"] = { name="Vampire (Knife)", value=2, demand=2, rarity="legendary" },
 ["blue scratch"] = { name="Blue Scratch", value=2, demand=1, rarity="legendary" },
 ["ghost (gun)"] = { name="Ghost (Gun)", value=2, demand=1, rarity="legendary" },
 ["chromatic (knife)"] = { name="Chromatic (Knife)", value=1, demand=2, rarity="legendary" },
 ["energized (gun)"] = { name="Energized (Gun)", value=1, demand=2, rarity="legendary" },
 ["frostfade (knife)"] = { name="Frostfade (Knife)", value=1, demand=2, rarity="legendary" },
 ["icecracker"] = { name="Icecracker", value=1, demand=2, rarity="legendary" },
 ["red fire"] = { name="Red Fire", value=1, demand=1, rarity="legendary" },
 ["cavern (gun)"] = { name="Cavern (Gun)", value=1, demand=1, rarity="legendary" },

 -- 
 -- RARES (numeric values only — Tier 3)
 -- 
 ["cane knife (2018)"] = { name="Cane Knife (2018)", value=525, demand=3, rarity="rare" },
 ["silent night (knife)"] = { name="Silent Night (Knife)", value=50, demand=2, rarity="rare" },
 ["dungeon"] = { name="Dungeon", value=30, demand=2, rarity="rare" },
 ["zombified"] = { name="Zombified", value=27, demand=2, rarity="rare" },
 ["makeshift (knife)"] = { name="Makeshift (Knife)", value=25, demand=2, rarity="rare" },
 ["aurora (knife)"] = { name="Aurora (Knife)", value=13, demand=2, rarity="rare" },
 ["silent night (gun)"] = { name="Silent Night (Gun)", value=13, demand=2, rarity="rare" },
 ["icicles (gun)"] = { name="Icicles (Gun)", value=10, demand=2, rarity="rare" },
 ["starry (gun)"] = { name="Starry (Gun)", value=8, demand=2, rarity="rare" },
 ["vampire (gun) (2018)"] = { name="Vampire (Gun) 2018", value=8, demand=2, rarity="rare" },
 ["darkknife"] = { name="Darkknife", value=7, demand=2, rarity="rare" },
 ["swirl"] = { name="Swirl", value=7, demand=2, rarity="rare" },
 ["toxic (knife)"] = { name="Toxic (Knife)", value=7, demand=2, rarity="rare" },
 ["candy swirl (gun)"] = { name="Candy Swirl (Gun)", value=5, demand=2, rarity="rare" },
 ["floral (knife)"] = { name="Floral (Knife)", value=5, demand=2, rarity="rare" },
 ["magma"] = { name="Magma", value=5, demand=1, rarity="rare" },
 ["monster (rare)"] = { name="Monster", value=5, demand=1, rarity="rare" },
 ["jack"] = { name="Jack", value=3, demand=2, rarity="rare" },
 ["magma (gun)"] = { name="Magma (Gun)", value=3, demand=2, rarity="rare" },
 ["snakebite (knife)"] = { name="Snakebite (Knife)", value=3, demand=2, rarity="rare" },
 ["watcher (gun)"] = { name="Watcher (Gun)", value=3, demand=2, rarity="rare" },
 ["bats"] = { name="Bats", value=3, demand=1, rarity="rare" },
 ["green marble"] = { name="Green Marble", value=3, demand=1, rarity="rare" },
 ["orange marble"] = { name="Orange Marble", value=2, demand=1, rarity="rare" },
 ["toxic (gun)"] = { name="Toxic (Gun)", value=2, demand=1, rarity="rare" },
 ["ghastly (gun)"] = { name="Ghastly (Gun)", value=1, demand=2, rarity="rare" },
 ["sunset (gun)"] = { name="Sunset (Gun)", value=1, demand=2, rarity="rare" },
 ["gingerbread (2017)"] = { name="Gingerbread (2017)", value=1, demand=1, rarity="rare" },
 ["aurora (gun) (2019)"] = { name="Aurora (Gun) 2019", value=1, demand=1, rarity="rare" },
 ["candy swirl (knife)"] = { name="Candy Swirl (Knife)", value=1, demand=1, rarity="rare" },
 ["snakebite (gun)"] = { name="Snakebite (Gun)", value=1, demand=1, rarity="rare" },
 ["vampire (knife) (2018)"] = { name="Vampire (Knife) 2018", value=1, demand=1, rarity="rare" },

 -- 
 -- UNCOMMONS (numeric values only)
 -- 
 ["bones (2019)"] = { name="Bones (2019)", value=70, demand=2, rarity="uncommon" },
 ["zombified (knife)"] = { name="Zombified (Knife)", value=65, demand=2, rarity="uncommon" },
 ["gingerbread (knife) 2019"] = { name="Gingerbread (Knife) 2019",value=50, demand=2, rarity="uncommon" },
 ["sweater (knife) 2018"] = { name="Sweater (Knife) 2018", value=50, demand=2, rarity="uncommon" },
 ["brains (2019)"] = { name="Brains (2019)", value=40, demand=3, rarity="uncommon" },
 ["branches"] = { name="Branches", value=25, demand=2, rarity="uncommon" },
 ["zombified (gun)"] = { name="Zombified (Gun)", value=15, demand=2, rarity="uncommon" },
 ["frozen (gun) unc"] = { name="Frozen (Gun)", value=10, demand=2, rarity="uncommon" },
 ["mummy 2018 (gun)"] = { name="Mummy 2018 (Gun)", value=10, demand=2, rarity="uncommon" },
 ["skulls (2021)"] = { name="Skulls (2021)", value=10, demand=2, rarity="uncommon" },
 ["void"] = { name="Void", value=10, demand=2, rarity="uncommon" },
 ["zombie (gun) 2018"] = { name="Zombie (Gun) 2018", value=10, demand=2, rarity="uncommon" },
 ["potion (knife) 2018"] = { name="Potion (Knife) 2018", value=8, demand=2, rarity="uncommon" },
 ["lights (gun)"] = { name="Lights (Gun)", value=7, demand=2, rarity="uncommon" },
 ["snowflake 2018 knife"] = { name="Snowflake 2018 (Knife)", value=5, demand=1, rarity="uncommon" },
 ["potion (gun) 2018"] = { name="Potion (Gun) 2018", value=5, demand=1, rarity="uncommon" },
 ["holly (gun) 2018"] = { name="Holly (Gun) 2018", value=4, demand=1, rarity="uncommon" },
 ["webs"] = { name="Webs", value=3, demand=2, rarity="uncommon" },
 ["frozen (knife) unc"] = { name="Frozen (Knife)", value=3, demand=2, rarity="uncommon" },
 ["gingerbread (gun) 2019"] = { name="Gingerbread (Gun) 2019", value=3, demand=2, rarity="uncommon" },
 ["mummy 2018 (knife)"] = { name="Mummy 2018 (Knife)", value=3, demand=2, rarity="uncommon" },
 ["zombie (knife) 2018"] = { name="Zombie (Knife) 2018", value=3, demand=2, rarity="uncommon" },
 ["pumpkin pie"] = { name="Pumpkin Pie", value=3, demand=2, rarity="uncommon" },
 ["potion (2017)"] = { name="Potion (2017)", value=3, demand=1, rarity="uncommon" },
 ["gothic (gun)"] = { name="Gothic (Gun)", value=2, demand=2, rarity="uncommon" },
 ["mummy (2017)"] = { name="Mummy (2017)", value=2, demand=1, rarity="uncommon" },
 ["lights (knife)"] = { name="Lights (Knife)", value=1, demand=1, rarity="uncommon" },
 ["moons"] = { name="Moons", value=1, demand=1, rarity="uncommon" },
 ["vampire (2016)"] = { name="Vampire (2016)", value=1, demand=1, rarity="uncommon" },
 ["wolf"] = { name="Wolf", value=1, demand=1, rarity="uncommon" },

 -- 
 -- UNIQUES
 -- 
 ["corrupt"] = { name="Corrupt", value=800, demand=4, rarity="unique" },

 -- 
 -- PETS (numeric values only)
 -- 
 ["zombie dog"] = { name="Zombie Dog", value=450, demand=3, rarity="pet" },
 ["elf (2019)"] = { name="Elf (2019)", value=200, demand=2, rarity="pet" },
 ["blue pumpkin (2018)"] = { name="Blue Pumpkin (2018)", value=140, demand=3, rarity="pet" },
 ["red pumpkin (2018)"] = { name="Red Pumpkin (2018)", value=100, demand=3, rarity="pet" },
 ["dogey"] = { name="Dogey", value=90, demand=3, rarity="pet" },
 ["green pumpkin (2018)"] = { name="Green Pumpkin (2018)", value=60, demand=3, rarity="pet" },
 ["black cat"] = { name="Black Cat", value=60, demand=3, rarity="pet" },
 ["santa 2019"] = { name="Santa 2019", value=35, demand=2, rarity="pet" },
 ["pumpkin (2017)"] = { name="Pumpkin (2017)", value=25, demand=2, rarity="pet" },
 ["piggy"] = { name="Piggy", value=20, demand=2, rarity="pet" },
 ["mr. reindeer"] = { name="Mr. Reindeer", value=15, demand=2, rarity="pet" },
 ["fairy"] = { name="Fairy", value=13, demand=1, rarity="pet" },
 ["jetstream"] = { name="Jetstream", value=13, demand=1, rarity="pet" },
 ["nobledragon"] = { name="Nobledragon", value=13, demand=1, rarity="pet" },
 ["seahorsey"] = { name="Seahorsey", value=13, demand=1, rarity="pet" },
 ["chilly"] = { name="Chilly", value=12, demand=1, rarity="pet" },
 ["green pumpkin (2019)"] = { name="Green Pumpkin (2019)", value=12, demand=1, rarity="pet" },
 ["pengy"] = { name="Pengy", value=12, demand=1, rarity="pet" },
 ["purple pumpkin (2018)"] = { name="Purple Pumpkin (2018)", value=12, demand=1, rarity="pet" },
 ["red pumpkin (2019)"] = { name="Red Pumpkin (2019)", value=12, demand=1, rarity="pet" },
 ["rudolph"] = { name="Rudolph", value=12, demand=1, rarity="pet" },
 ["vampire bat"] = { name="Vampire Bat", value=12, demand=1, rarity="pet" },
 ["<3"] = { name="<3", value=10, demand=1, rarity="pet" },
 ["eyeball"] = { name="Eyeball", value=10, demand=1, rarity="pet" },
 ["reindeer"] = { name="Reindeer", value=10, demand=1, rarity="pet" },
 ["tankie"] = { name="Tankie", value=10, demand=1, rarity="pet" },
 ["elf"] = { name="Elf", value=8, demand=2, rarity="pet" },
 ["overseer eye"] = { name="Overseer Eye", value=8, demand=1, rarity="pet" },
 ["red pumpkin (2020)"] = { name="Red Pumpkin (2020)", value=7, demand=2, rarity="pet" },
 ["red pumpkin (2021)"] = { name="Red Pumpkin (2021)", value=7, demand=2, rarity="pet" },
 ["skully"] = { name="Skully", value=7, demand=2, rarity="pet" },
 ["green pumpkin (2020)"] = { name="Green Pumpkin (2020)", value=5, demand=2, rarity="pet" },
 ["green pumpkin (2021)"] = { name="Green Pumpkin (2021)", value=5, demand=2, rarity="pet" },
 ["mechbug"] = { name="Mechbug", value=5, demand=1, rarity="pet" },
 ["ufo"] = { name="UFO", value=5, demand=1, rarity="pet" },
 ["blue pumpkin (2020)"] = { name="Blue Pumpkin (2020)", value=3, demand=2, rarity="pet" },
 ["blue pumpkin (2019)"] = { name="Blue Pumpkin (2019)", value=2, demand=2, rarity="pet" },
 ["shadow pumpkin"] = { name="Shadow Pumpkin", value=2, demand=2, rarity="pet" },
 ["badger"] = { name="Badger", value=1, demand=1, rarity="pet" },
 ["steambird"] = { name="Steambird", value=1, demand=1, rarity="pet" },
 ["traveller"] = { name="Traveller", value=1, demand=1, rarity="pet" },
 ["deathspeaker"] = { name="Deathspeaker", value=1, demand=1, rarity="pet" },
 ["electro"] = { name="Electro", value=1, demand=1, rarity="pet" },
 ["frostbird"] = { name="Frostbird", value=1, demand=1, rarity="pet" },
 ["ghosty"] = { name="Ghosty", value=1, demand=1, rarity="pet" },
 ["ice phoenix"] = { name="Ice Phoenix", value=1, demand=1, rarity="pet" },
 ["phoenix"] = { name="Phoenix", value=1, demand=1, rarity="pet" },
 ["sammy"] = { name="Sammy", value=1, demand=1, rarity="pet" },
 ["skelly"] = { name="Skelly", value=1, demand=1, rarity="pet" },
}

-- ValueChecker wrapper (keeps rest of script compatible) 
local ValueChecker = {
 cache = SV_DATABASE,
 loaded = true, -- always ready, no fetching needed
 loading = false,
 autoTradeVal = true,
}
-- Ensure every entry has a .trend field (used by lookupItem)
for _, v in pairs(ValueChecker.cache) do
 v.trend = v.trend or "stable"
end

-- ================================================================
-- VALUE HELPERS
-- ================================================================

-- ================================================================
-- ID TRANSLATION LAYER
--
-- MM2 sends raw internal ItemIDs in trade data — never display names.
-- Patterns seen in the wild:
-- CamelCase wrong caps: "FlowerWoodGun" → "Flowerwood Gun"
-- Event codes: "S_2024_K" → decoded then fuzzy matched
-- No apostrophe: "TravelersGun" → "Traveler's Gun"
-- Prefix codes: "HAL_22_BLADE" → "Elderwood Blade"
-- Already fine: "Laser" → "Laser"
--
-- Lookup order:
-- 1. Direct hardcoded map (known IDs → exact SV name)
-- 2. Structural normalisation (camelCase, underscore, event decode)
-- 3. Compound word merge (FlowerWood → Flowerwood)
-- 4. Possessive injection (Travelers → Traveler's)
-- 5. Exact cache match
-- 6. Substring cache match
-- 7. Token fuzzy match (best word-overlap in the whole cache)
-- ================================================================

-- Hardcoded ID → SV display name 
local ID_MAP = {
 -- Wrong compound capitalisation
 FlowerWoodGun = "flowerwood gun",
 FlowerWood = "flowerwood",
 ElderWoodBlade = "elderwood blade",
 ElderWoodRevolver = "elderwood revolver",
 ElderwoodBlade = "elderwood blade",
 ElderwoodRevolver = "elderwood revolver",
 SnowCannon = "snowcannon",
 SnowDagger = "snow dagger",
 DarkShot = "darkshot",
 DarkSword = "darksword",
 DarkBringer = "darkbringer",
 LightBringer = "lightbringer",
 IceBlaster = "iceblaster",
 IceBeam = "icebeam",
 IceFlake = "iceflake",
 IceDragon = "ice dragon",
 IceShard = "ice shard",
 HeartBlade = "heartblade",
 HeartWand = "heart wand",
 RainbowGun = "rainbow gun",
 PlasmaBeam = "plasmabeam",
 PlasmaBlade = "plasmablade",
 NightBlade = "nightblade",
 CandleFlame = "candleflame",
 SwirlyGun = "swirly gun",
 SwirlyBlade = "swirly blade",
 CookieCane = "cookiecane",
 CookieBlade = "cookieblade",
 GingerMint = "gingermint",
 GingerBlade = "gingerblade",
 GingerLuger = "ginger luger",
 RedLuger = "red luger",
 GreenLuger = "green luger",
 OldGlory = "old glory",
 BattleAxe = "battleaxe",
 BattleAxeII = "battleaxe ii",
 GhostBlade = "ghostblade",
 BoneBlade = "boneblade",
 DeathShard = "deathshard",
 WaterGun = "watergun",
 HallowGun = "hallowgun",
 StarterKnife = "default knife",
 StarterGun = "default gun",
 AlienBeam = "alienbeam",
 PearlShine = "pearlshine",
 HeartBreaker = "heartbreaker",
 MakeShift = "makeshift",

 -- Possessives (MM2 drops the apostrophe in IDs)
 TravelersGun = "traveler's gun",
 VampiresGun = "vampire's gun",
 VampiresEdge = "vampire's edge",
 HallowsBlade = "hallow's blade",
 HallowsEdge = "hallow's edge",
 WintersEdge = "winter's edge",

 -- Chroma prefix variants (ChromaX → Chroma X)
 ChromaLaser = "chroma laser",
 ChromaHeat = "chroma heat",
 ChromaLuger = "chroma luger",
 ChromaShark = "chroma shark",
 ChromaSaw = "chroma saw",
 ChromaTides = "chroma tides",
 ChromaNebula = "chroma nebula",

 -- Known event shortcodes (expand as you discover more in-game)
 -- HAL=Hallows, XMS=Xmas, SUM=Summer, EGG/SPR=Easter, VLN=Valentine, TKG=Thanksgiving
 HAL_22_BLADE = "elderwood blade",
 HAL_22_GUN = "makeshift",
 HAL_22_Z = "elderwood blade", -- Z may = knife variant
 HAL_23_GUN = "darkshot",
 HAL_23_KNIFE = "darksword",
 XMS_23_GUN = "constellation",
 XMS_24_GUN = "bauble",
 XMS_25_GUN = "snowcannon",
 SUM_24_GUN = "watergun",
 SUM_25_GUN = "sunrise",
 SUM_25_KNIFE = "sunset (knife)",
 VLN_23_GUN = "blossom",
 VLN_23_KNIFE = "sakura",
 VLN_26_GUN = "heart wand",
 VLN_26_KNIFE_A = "sweet",
 VLN_26_KNIFE_B = "treat",
 HAL_25_GUN = "alienbeam",
 HAL_25_KNIFE = "xenoknife",
 HAL_25_GUN2 = "xenoshot",
 -- S_ prefix: Summer season shortcodes
 S_2024_K = "pearlshine", -- best guess: Summer 2024 knife
 S_2024_G = "watergun",
 S_2025_K = "sunset (knife)",
 S_2025_G = "sunrise",
}

-- Event/season code decoder for unknown codes
local EVENT_DECODE = {
 HAL="hallows", XMS="xmas", SUM="summer",
 SPR="spring", EGG="easter", VLN="valentine",
 TGV="thanksgiving", TKG="thanksgiving",
 WIN="winter", AUT="autumn", S="summer",
 H="hallows", X="xmas", V="valentine",
}

local function normaliseID(id)
 if not id or id == "" then return "" end

 -- Pass 1: direct map exact
 local d = ID_MAP[id]
 if d then return d end
 -- Pass 1b: case-insensitive map
 local idl = id:lower()
 for k, v in pairs(ID_MAP) do
 if k:lower() == idl then return v end
 end

 local s = id

 -- Pass 2: event code decoding (has underscores + digits)
 if s:find("_") and s:match("%d") then
 local parts = {}
 for p in s:gmatch("[^_]+") do parts[#parts+1] = p end
 local words = {}
 for _, p in ipairs(parts) do
 if p:match("^%d+$") then
 -- skip pure year/number tokens
 else
 local ev = EVENT_DECODE[p:upper()]
 if ev then
 words[#words+1] = ev
 elseif p:upper() == "K" or p:upper() == "KNIFE" then
 -- type suffix — skip, doesn't help name matching
 elseif p:upper() == "G" or p:upper() == "GUN" then
 -- skip
 else
 words[#words+1] = p:lower()
 end
 end
 end
 if #words > 0 then
 s = table.concat(words, " ")
 else
 s = s:gsub("_", " "):gsub("%d+", " ")
 end
 else
 -- Pass 2b: plain underscores → spaces
 s = s:gsub("_", " ")
 end

 -- Pass 3: camelCase split
 s = s:gsub("(%l)(%u)", "%1 %2")
 s = s:gsub("(%u%u)(%u%l)", "%1 %2") -- "ABCDef" → "ABC Def"

 -- Pass 4: compound word merges (SV uses one word, MM2 splits)
 local sl = s:lower()
 local MERGE = {
 ["flower wood"] = "flowerwood",
 ["elder wood"] = "elderwood",
 ["snow cannon"] = "snowcannon",
 ["snow dagger"] = "snow dagger", -- SV DOES space this one
 ["dark shot"] = "darkshot",
 ["dark sword"] = "darksword",
 ["dark bringer"] = "darkbringer",
 ["light bringer"]= "lightbringer",
 ["ice blaster"] = "iceblaster",
 ["ice beam"] = "icebeam",
 ["ice flake"] = "iceflake",
 ["plasma beam"] = "plasmabeam",
 ["plasma blade"] = "plasmablade",
 ["night blade"] = "nightblade",
 ["candle flame"] = "candleflame",
 ["heart blade"] = "heartblade",
 ["cookie cane"] = "cookiecane",
 ["cookie blade"] = "cookieblade",
 ["ginger mint"] = "gingermint",
 ["ginger blade"] = "gingerblade",
 ["ghost blade"] = "ghostblade",
 ["bone blade"] = "boneblade",
 ["death shard"] = "deathshard",
 ["water gun"] = "watergun",
 ["hallow gun"] = "hallowgun",
 ["battle axe"] = "battleaxe",
 ["swirly gun"] = "swirly gun",
 ["alien beam"] = "alienbeam",
 ["pearl shine"] = "pearlshine",
 ["make shift"] = "makeshift",
 }
 for pat, rep in pairs(MERGE) do
 sl = sl:gsub(pat, rep)
 end
 s = sl

 -- Pass 5: possessive injection
 -- "travelers" → "traveler's", "vampires" → "vampire's", etc.
 local POSS = {
 {"travelers", "traveler's"}, {"vampires", "vampire's"},
 {"hallows", "hallow's"}, {"winters", "winter's"},
 {"elders", "elder's"}, {"hunters", "hunter's"},
 {"witches", "witch's"}, {"witchs", "witch's"},
 }
 for _, pair in ipairs(POSS) do
 s = s:gsub(pair[1], pair[2])
 end

 return s:match("^%s*(.-)%s*$")
end

-- Token fuzzy score 
local function tokenScore(a, b)
 local function tok(str)
 local t = {}
 for w in str:gmatch("%a+") do t[w] = true end
 return t
 end
 local ta, tb = tok(a), tok(b)
 local hits, total = 0, 0
 for w in pairs(ta) do
 total = total + 1
 if tb[w] then hits = hits + 1 end
 end
 return total > 0 and (hits / total) or 0
end

-- Master lookup: tries every strategy in order 
local function lookupItem(id)
 if not id or id == "" then return nil end

 -- Helper: ensure the returned entry always has a .name field
 local function tagged(key, entry)
 if entry and not entry.name then entry.name = key end
 return entry
 end

 -- 1. Raw exact match
 local raw = id:lower()
 if ValueChecker.cache[raw] then return tagged(raw, ValueChecker.cache[raw]) end

 -- 2. Normalised exact match
 local key = normaliseID(id)
 if key ~= "" and ValueChecker.cache[key] then
 return tagged(key, ValueChecker.cache[key])
 end

 -- 3. Substring match (key inside cache key, or cache key inside key)
 if key ~= "" then
 for k, v in pairs(ValueChecker.cache) do
 if k:find(key, 1, true) or key:find(k, 1, true) then
 return tagged(k, v)
 end
 end
 end

 -- 4. Token fuzzy match: best ≥50% word-overlap in the entire cache
 if key ~= "" then
 local bestScore, bestVal, bestKey = 0.49, nil, nil
 for k, v in pairs(ValueChecker.cache) do
 local sc = tokenScore(key, k)
 if sc > bestScore then bestScore = sc; bestVal = v; bestKey = k end
 end
 if bestVal then return tagged(bestKey, bestVal) end
 end

 return nil
end

local function fmtVal(n)
 n = tonumber(n) or 0
 if n >= 1000000 then return string.format("%.1fM", n / 1000000)
 elseif n >= 1000 then return string.format("%.1fk", n / 1000)
 else return tostring(math.floor(n)) end
end

-- ================================================================
-- TRADE VALUE OVERLAY — ScreenGui that appears during trades
--
-- Hooks:
-- Trade.StartTrade.OnClientEvent(tradeData, partnerName)
-- Trade.UpdateTrade.OnClientEvent(tradeData)
-- Trade.DeclineTrade.OnClientEvent()
-- Trade.AcceptTrade.OnClientEvent(success, items)
--
-- Offer item format (from TradeModule source):
-- item[1] / item.ItemID = item name/ID string
-- item[2] / item.Amount = quantity
-- item[3] / item.ItemType = "Weapons" | "Pets"
-- ================================================================

local TradeBus = ReplicatedStorage:FindFirstChild("Trade")

-- Database.Sync: same module the TradeModule uses internally 
-- Structure: Sync[itemType][itemID] = { Name = "Flowerwood Gun", ... }
-- This gives us the REAL display name the trade GUI shows, not the raw ItemID.
local DatabaseSync = nil
pcall(function()
 local db = ReplicatedStorage:FindFirstChild("Database")
 if db then
 local syncMod = db:FindFirstChild("Sync")
 if syncMod then
 DatabaseSync = require(syncMod)
 end
 end
end)

-- Returns the human-readable display name for an item using Database.Sync.
-- Falls back to our normaliseID logic if Sync isn't available.
local function getDisplayName(itemID, itemType)
 if DatabaseSync and itemType then
 local typeTable = DatabaseSync[itemType]
 if typeTable then
 local entry = typeTable[itemID]
 if entry then
 return entry.Name or entry.name or normaliseID(itemID)
 end
 end
 end
 -- fallback: camelCase splitter / ID_MAP
 local n = normaliseID(itemID)
 return (n ~= "" and n) or itemID
end

-- Build the overlay ScreenGui 
local TradeValueGui = Instance.new("ScreenGui")
TradeValueGui.Name = "SVTradeValueOverlay"
TradeValueGui.ResetOnSpawn = false
TradeValueGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
TradeValueGui.DisplayOrder = 999
TradeValueGui.Enabled = false
TradeValueGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main container — sits at bottom-centre of screen
local TVMain = Instance.new("Frame")
TVMain.Name = "Main"
TVMain.Size = UDim2.new(0, 540, 0, 110)
TVMain.Position = UDim2.new(0.5, -270, 1, -125)
TVMain.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
TVMain.BackgroundTransparency = 0.08
TVMain.BorderSizePixel = 0
TVMain.Parent = TradeValueGui

local TVCorner = Instance.new("UICorner")
TVCorner.CornerRadius = UDim.new(0, 10)
TVCorner.Parent = TVMain

local TVStroke = Instance.new("UIStroke")
TVStroke.Color = Color3.fromRGB(255, 215, 0)
TVStroke.Thickness = 1.5
TVStroke.Transparency = 0.4
TVStroke.Parent = TVMain

-- Title bar
local TVTitle = Instance.new("TextLabel")
TVTitle.Name = "Title"
TVTitle.Size = UDim2.new(1, 0, 0, 22)
TVTitle.Position = UDim2.new(0, 0, 0, 0)
TVTitle.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
TVTitle.BackgroundTransparency = 0.15
TVTitle.BorderSizePixel = 0
TVTitle.Font = Enum.Font.GothamBold
TVTitle.TextSize = 12
TVTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
TVTitle.Text = " SUPREME VALUES — Trade Value Checker"
TVTitle.ZIndex = 5
TVTitle.Parent = TVMain

local TVTitleCorner = Instance.new("UICorner")
TVTitleCorner.CornerRadius = UDim.new(0, 10)
TVTitleCorner.Parent = TVTitle

-- YOUR side panel
local TVYour = Instance.new("Frame")
TVYour.Name = "Your"
TVYour.Size = UDim2.new(0.42, -4, 0, 78)
TVYour.Position = UDim2.new(0, 4, 0, 26)
TVYour.BackgroundColor3 = Color3.fromRGB(0, 80, 20)
TVYour.BackgroundTransparency = 0.55
TVYour.BorderSizePixel = 0
TVYour.Parent = TVMain

local TVYourCorner = Instance.new("UICorner")
TVYourCorner.CornerRadius = UDim.new(0, 6)
TVYourCorner.Parent = TVYour

local TVYourLabel = Instance.new("TextLabel")
TVYourLabel.Name = "Label"
TVYourLabel.Size = UDim2.new(1, -8, 0, 18)
TVYourLabel.Position = UDim2.new(0, 6, 0, 3)
TVYourLabel.BackgroundTransparency = 1
TVYourLabel.Font = Enum.Font.GothamBold
TVYourLabel.TextSize = 11
TVYourLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
TVYourLabel.TextXAlignment = Enum.TextXAlignment.Left
TVYourLabel.Text = "YOUR OFFER"
TVYourLabel.Parent = TVYour

local TVYourValue = Instance.new("TextLabel")
TVYourValue.Name = "Value"
TVYourValue.Size = UDim2.new(1, -8, 0, 36)
TVYourValue.Position = UDim2.new(0, 6, 0, 20)
TVYourValue.BackgroundTransparency = 1
TVYourValue.Font = Enum.Font.GothamBold
TVYourValue.TextSize = 28
TVYourValue.TextColor3 = Color3.fromRGB(255, 255, 255)
TVYourValue.TextXAlignment = Enum.TextXAlignment.Left
TVYourValue.Text = "—"
TVYourValue.Parent = TVYour

local TVYourItems = Instance.new("TextLabel")
TVYourItems.Name = "Items"
TVYourItems.Size = UDim2.new(1, -8, 0, 16)
TVYourItems.Position = UDim2.new(0, 6, 0, 56)
TVYourItems.BackgroundTransparency = 1
TVYourItems.Font = Enum.Font.Gotham
TVYourItems.TextSize = 10
TVYourItems.TextColor3 = Color3.fromRGB(180, 255, 180)
TVYourItems.TextXAlignment = Enum.TextXAlignment.Left
TVYourItems.TextTruncate = Enum.TextTruncate.AtEnd
TVYourItems.Text = "No items"
TVYourItems.Parent = TVYour

-- THEIR side panel
local TVTheir = Instance.new("Frame")
TVTheir.Name = "Their"
TVTheir.Size = UDim2.new(0.42, -4, 0, 78)
TVTheir.Position = UDim2.new(0.58, 0, 0, 26)
TVTheir.BackgroundColor3 = Color3.fromRGB(80, 0, 20)
TVTheir.BackgroundTransparency = 0.55
TVTheir.BorderSizePixel = 0
TVTheir.Parent = TVMain

local TVTheirCorner = Instance.new("UICorner")
TVTheirCorner.CornerRadius = UDim.new(0, 6)
TVTheirCorner.Parent = TVTheir

local TVTheirLabel = Instance.new("TextLabel")
TVTheirLabel.Name = "Label"
TVTheirLabel.Size = UDim2.new(1, -8, 0, 18)
TVTheirLabel.Position = UDim2.new(0, 6, 0, 3)
TVTheirLabel.BackgroundTransparency = 1
TVTheirLabel.Font = Enum.Font.GothamBold
TVTheirLabel.TextSize = 11
TVTheirLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
TVTheirLabel.TextXAlignment = Enum.TextXAlignment.Left
TVTheirLabel.Text = "THEIR OFFER"
TVTheirLabel.Parent = TVTheir

local TVTheirValue = Instance.new("TextLabel")
TVTheirValue.Name = "Value"
TVTheirValue.Size = UDim2.new(1, -8, 0, 36)
TVTheirValue.Position = UDim2.new(0, 6, 0, 20)
TVTheirValue.BackgroundTransparency = 1
TVTheirValue.Font = Enum.Font.GothamBold
TVTheirValue.TextSize = 28
TVTheirValue.TextColor3 = Color3.fromRGB(255, 255, 255)
TVTheirValue.TextXAlignment = Enum.TextXAlignment.Left
TVTheirValue.Text = "—"
TVTheirValue.Parent = TVTheir

local TVTheirItems = Instance.new("TextLabel")
TVTheirItems.Name = "Items"
TVTheirItems.Size = UDim2.new(1, -8, 0, 16)
TVTheirItems.Position = UDim2.new(0, 6, 0, 56)
TVTheirItems.BackgroundTransparency = 1
TVTheirItems.Font = Enum.Font.Gotham
TVTheirItems.TextSize = 10
TVTheirItems.TextColor3 = Color3.fromRGB(255, 180, 180)
TVTheirItems.TextXAlignment = Enum.TextXAlignment.Left
TVTheirItems.TextTruncate = Enum.TextTruncate.AtEnd
TVTheirItems.Text = "No items"
TVTheirItems.Parent = TVTheir

-- Middle verdict panel
local TVVerdict = Instance.new("Frame")
TVVerdict.Name = "Verdict"
TVVerdict.Size = UDim2.new(0.16, -4, 0, 78)
TVVerdict.Position = UDim2.new(0.42, 2, 0, 26)
TVVerdict.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TVVerdict.BackgroundTransparency = 0.3
TVVerdict.BorderSizePixel = 0
TVVerdict.Parent = TVMain

local TVVerdictCorner = Instance.new("UICorner")
TVVerdictCorner.CornerRadius = UDim.new(0, 6)
TVVerdictCorner.Parent = TVVerdict

local TVVerdictIcon = Instance.new("TextLabel")
TVVerdictIcon.Name = "Icon"
TVVerdictIcon.Size = UDim2.new(1, 0, 0, 36)
TVVerdictIcon.Position = UDim2.new(0, 0, 0, 8)
TVVerdictIcon.BackgroundTransparency = 1
TVVerdictIcon.Font = Enum.Font.GothamBold
TVVerdictIcon.TextSize = 26
TVVerdictIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
TVVerdictIcon.Text = ""
TVVerdictIcon.Parent = TVVerdict

local TVVerdictText = Instance.new("TextLabel")
TVVerdictText.Name = "VerdictText"
TVVerdictText.Size = UDim2.new(1, -4, 0, 28)
TVVerdictText.Position = UDim2.new(0, 2, 0, 46)
TVVerdictText.BackgroundTransparency = 1
TVVerdictText.Font = Enum.Font.GothamBold
TVVerdictText.TextSize = 9
TVVerdictText.TextColor3 = Color3.fromRGB(220, 220, 220)
TVVerdictText.TextWrapped = true
TVVerdictText.Text = "Waiting..."
TVVerdictText.Parent = TVVerdict

-- Overlay update logic 
local function calcOffer(offer)
 local total = 0
 local known = 0
 local unknown = 0
 local itemList = {}
 for _, item in ipairs(offer) do
 local itemID = item[1] or item.ItemID or ""
 local qty = tonumber(item[2] or item.Amount) or 1
 local itemType = item[3] or item.ItemType or nil

 -- Get the real display name from Database.Sync (same source the trade GUI uses).
 -- e.g. "FlowerWoodGun" → "Flowerwood Gun" straight from the game's own data.
 local displayName = getDisplayName(itemID, itemType)

 -- Look up value using the display name first (matches supremevalues.com casing),
 -- then fall back to the raw ItemID if needed.
 local d = lookupItem(displayName) or lookupItem(itemID)

 if d then
 local v = d.value * qty
 total = total + v
 known = known + 1
 local icon = RARITY_COLORS[d.rarity] or "•"
 -- Prefer the SV cache's own name if present, otherwise use the DB display name
 local showName = d.name or displayName
 itemList[#itemList + 1] = string.format("%s%s%s",
 icon, showName, qty > 1 and (" x" .. qty) or "")
 else
 unknown = unknown + 1
 -- Even for unknowns, show the proper display name — never the raw ItemID
 itemList[#itemList + 1] = "? " .. displayName .. (qty > 1 and (" x"..qty) or "")
 end
 end
 return total, known, unknown, table.concat(itemList, " ")
end

local function updateOverlay(myOffer, theirOffer, partnerName)
 local myTotal, myKnown, myUnk, myItemStr = calcOffer(myOffer or {})
 local theirTotal, theirKnown, theirUnk, theirItemStr = calcOffer(theirOffer or {})

 -- Your side
 TVYourValue.Text = #(myOffer or {}) > 0 and fmtVal(myTotal) or "—"
 TVYourItems.Text = myItemStr ~= "" and myItemStr or "Nothing offered"

 -- Their side
 TVTheirLabel.Text = partnerName and (partnerName:upper() .. "'S OFFER") or "THEIR OFFER"
 TVTheirValue.Text = #(theirOffer or {}) > 0 and fmtVal(theirTotal) or "—"
 TVTheirItems.Text = theirItemStr ~= "" and theirItemStr or "Nothing offered"

 -- Verdict
 local diff = theirTotal - myTotal
 local icon, msg, col
 if #(myOffer or {}) == 0 and #(theirOffer or {}) == 0 then
 icon = "[+]"; msg = "Waiting..."; col = Color3.fromRGB(200,200,200)
 elseif diff > 5000 then
 icon = "[+]"; msg = "Excellent!"; col = Color3.fromRGB(0,255,100)
 elseif diff > 1000 then
 icon = "[+]"; msg = "Good\n+"..fmtVal(diff);col = Color3.fromRGB(80,255,80)
 elseif diff > 0 then
 icon = "[+]"; msg = "+"..fmtVal(diff); col = Color3.fromRGB(160,255,160)
 elseif diff == 0 and myTotal > 0 then
 icon = "[+]"; msg = "Even"; col = Color3.fromRGB(255,215,0)
 elseif diff < -5000 then
 icon = "[+]"; msg = "Very Bad\n-"..fmtVal(math.abs(diff)); col = Color3.fromRGB(255,60,60)
 elseif diff < -1000 then
 icon = "[+]"; msg = "Bad\n-"..fmtVal(math.abs(diff)); col = Color3.fromRGB(255,100,100)
 elseif diff < 0 then
 icon = "[+]"; msg = "-"..fmtVal(math.abs(diff)); col = Color3.fromRGB(255,180,80)
 else
 icon = "[+]"; msg = "—"; col = Color3.fromRGB(200,200,200)
 end

 TVVerdictIcon.Text = icon
 TVVerdictText.Text = msg
 TVVerdictText.TextColor3 = col

 -- Colour the value numbers based on verdict
 if diff > 0 then
 TVYourValue.TextColor3 = Color3.fromRGB(255, 255, 255)
 TVTheirValue.TextColor3 = Color3.fromRGB(80, 255, 80)
 elseif diff < 0 then
 TVYourValue.TextColor3 = Color3.fromRGB(255, 255, 255)
 TVTheirValue.TextColor3 = Color3.fromRGB(255, 100, 100)
 else
 TVYourValue.TextColor3 = Color3.fromRGB(255, 215, 0)
 TVTheirValue.TextColor3 = Color3.fromRGB(255, 215, 0)
 end

 -- Warn if some items have unknown value
 local unkTotal = myUnk + theirUnk
 if unkTotal > 0 then
 TVTitle.Text = string.format(" SUPREME VALUES (%d item%s not in DB — values may be incomplete)",
 unkTotal, unkTotal > 1 and "s" or "")
 else
 TVTitle.Text = " SUPREME VALUES — Trade Value Checker"
 end
end

-- Wire into the three trade remotes 
-- NOTE: The game's TradeModule may log "attempt to index nil with GetChildren"
-- on its own line 41 — this is a race condition in the game's GUI setup,
-- not caused by our script. We wrap our handlers in pcall to stay isolated.
local activePartner = nil

local function onUpdateTrade(tradeData)
 local ok, err = pcall(function()
 if not TradeValueGui.Enabled then return end
 if not tradeData or not tradeData.Player1 then return end

 local myKey, theirKey
 if tradeData.Player1.Player == LocalPlayer then
 myKey, theirKey = "Player1", "Player2"
 elseif tradeData.Player2.Player == LocalPlayer then
 myKey, theirKey = "Player2", "Player1"
 else return end

 local myOffer = tradeData[myKey] and tradeData[myKey].Offer or {}
 local theirOffer = tradeData[theirKey] and tradeData[theirKey].Offer or {}
 local partnerObj = tradeData[theirKey] and tradeData[theirKey].Player
 local partnerName = (partnerObj and partnerObj.Name) or activePartner or "Them"

 updateOverlay(myOffer, theirOffer, partnerName)
 end)
 if not ok then
 warn("[SVOverlay] onUpdateTrade error: " .. tostring(err))
 end
end

local function onStartTrade(tradeData, partnerName)
 local ok, err = pcall(function()
 activePartner = partnerName
 -- Small yield so the game's own TradeModule GUI has time to init first.
 -- This avoids any timing conflict with the game's GetChildren call.
 task.defer(function()
 TradeValueGui.Enabled = true
 TVYourValue.Text = "—"
 TVTheirValue.Text = "—"
 TVYourItems.Text = "Nothing offered"
 TVTheirItems.Text = "Nothing offered"
 TVVerdictIcon.Text = ""
 TVVerdictText.Text = "Waiting..."
 TVTheirLabel.Text = (partnerName and partnerName:upper() or "THEM") .. "'S OFFER"
 if tradeData then onUpdateTrade(tradeData) end
 end)
 end)
 if not ok then
 warn("[SVOverlay] onStartTrade error: " .. tostring(err))
 end
end

local function onEndTrade()
 pcall(function()
 activePartner = nil
 TradeValueGui.Enabled = false
 end)
end

if TradeBus then
 local updateEv = TradeBus:FindFirstChild("UpdateTrade")
 local startEv = TradeBus:FindFirstChild("StartTrade")
 local declineEv = TradeBus:FindFirstChild("DeclineTrade")
 local acceptEv = TradeBus:FindFirstChild("AcceptTrade")

 if updateEv then updateEv.OnClientEvent:Connect(onUpdateTrade) end
 if startEv then startEv.OnClientEvent:Connect(onStartTrade) end
 if declineEv then declineEv.OnClientEvent:Connect(onEndTrade) end
 if acceptEv then acceptEv.OnClientEvent:Connect(onEndTrade) end
end

-- ================================================================
-- VALUES TAB — UI
-- ================================================================
Tabs.Values:AddSection(" Supreme Values — Trade Overlay")

Tabs.Values:AddParagraph({
 Title = "How it works",
 Content = "When you open a trade, an overlay appears at the bottom of your screen showing YOUR total value on the left, THEIR total value on the right, and a verdict in the middle. It updates live as items are added or removed."
})

Tabs.Values:AddToggle("AutoTradeValueToggle", {
 Title = "Show Trade Value Overlay",
 Description = "Display the value overlay at the bottom of the screen during trades.",
 Default = true,
 Callback = function(v)
 ValueChecker.autoTradeVal = v
 if not v then TradeValueGui.Enabled = false end
 end
})

do
 local n = 0
 for _ in pairs(SV_DATABASE) do n = n + 1 end
 Tabs.Values:AddParagraph({
 Title = " Database Info",
 Content = string.format(" %d items | supremevalues.com | Synced Feb 23, 2026\nChromas • Ancients • Vintages • Godlies • Legendaries • Rares • Uncommons • Uniques • Pets", n),
 })
end

-- Gun / Item Lookup 
Tabs.Values:AddSection(" Item Lookup")

local gunLookupName = ""

Tabs.Values:AddInput("GunLookupInput", {
 Title = "Item Name",
 Description = "Type any item name — gun, knife, pet, chroma, etc.",
 Default = "",
 Placeholder = "e.g. Chroma Laser, Flowerwood Gun, Zombie Dog",
 Callback = function(v) gunLookupName = v end
})

Tabs.Values:AddButton({
 Title = " Find Value",
 Name = "FindValueBtn",
 Callback = function()
 local input = gunLookupName:match("^%s*(.-)%s*$") -- trim
 if input == "" then
 Fluent:Notify({
 Title = " Item Lookup",
 Content = "Please type an item name first.",
 Duration = 3
 })
 return
 end

 -- 1. Try exact key match
 local key = input:lower()
 local d = ValueChecker.cache[key]

 -- 2. Try lookupItem (handles normalisation, partial matches)
 if not d then
 d = lookupItem(input)
 end

 -- 3. Manual partial scan across all display names
 if not d then
 local best, bestLen = nil, 0
 for _, entry in pairs(ValueChecker.cache) do
 local ename = (entry.name or ""):lower()
 if ename:find(key, 1, true) then
 if #ename > bestLen then
 best = entry
 bestLen = #ename
 end
 end
 end
 d = best
 end

 if not d then
 Fluent:Notify({
 Title = " Not Found",
 Content = string.format("'%s' was not found in the database.\n\nTry a shorter or different spelling.", input),
 Duration = 6
 })
 return
 end

 local icon = RARITY_COLORS[d.rarity] or "•"
 local rLabel = d.rarity:sub(1,1):upper() .. d.rarity:sub(2)
 local demLabel = d.demand > 0 and (d.demand .. "/10") or "N/A"
 local displayName = d.name or input

 Fluent:Notify({
 Title = icon .. " " .. displayName,
 Content = string.format(
 "Value: %s\nRarity: %s\nDemand: %s",
 fmtVal(d.value), rLabel, demLabel
 ),
 Duration = 10
 })
 end
})
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
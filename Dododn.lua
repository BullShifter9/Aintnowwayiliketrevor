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
local AutoNotifyEnabled = false
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local SupportedGameID = 142823291

if game.PlaceId ~= SupportedGameID then
 LocalPlayer:Kick("Game Not Supported\n\nSupported Games:\nMurder Mystery 2")
end


local state = {
 roles = {},
 murder = nil,
 sheriff = nil,
 hero = false,
 gunDrop = nil,
 autoGetGunDropEnabled = false,
 murdererNearDistance = 15,
 roleCallbacks = {}
}


local predictionState = {
 pingEnabled = false,
 pingValue = 50
}


local ESP = {
    Text      = {},
    Box       = {},
    Tracer    = {},
    Highlight = {},
}

local espActivePlayers = {}

local espTextOn, espBoxOn, espTracerOn, espHighlightOn = false, false, false, false

local gunDropESP = { tracer = nil, label = nil, pulse = 0 }
local gunDropESPEnabled = false

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

local espFrame = 0
RunService.RenderStepped:Connect(function()
    espFrame = espFrame + 1
    local cam         = workspace.CurrentCamera
    local camCF       = cam.CFrame
    local camPos      = camCF.Position
    local vpSize      = cam.ViewportSize
    local screenCenX  = vpSize.X * 0.5
    local screenBotY  = vpSize.Y

    for name, player in pairs(espActivePlayers) do
        local root = espRoot(player)
        if not root then
            local td = ESP.Text[name];    if td then td.Visible = false end
            local tb = ESP.Box[name]
            if tb then for i=1,8 do tb.lines[i].Visible = false end end
            local tt = ESP.Tracer[name];  if tt then tt.Visible = false end
            local th = ESP.Highlight[name]
            if th then th.hl.Enabled = false end
        else
            local rp      = root.Position
            local _, color = espRoleColor(player)

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

            local tt = ESP.Tracer[name]
            if tt then
                local sp, onScr = cam:WorldToViewportPoint(rp + Vector3.new(0, -2.5, 0))
                tt.Color   = color
                tt.From    = Vector2.new(screenCenX, screenBotY)
                tt.To      = Vector2.new(sp.X, sp.Y)
                tt.Visible = onScr
            end

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

            local th = ESP.Highlight[name]
            if th and espFrame % 4 == 0 then
                local fillCol, outlineCol = highlightRoleColors(player)
                th.hl.FillColor    = fillCol
                th.hl.OutlineColor = outlineCol
                th.hl.Enabled      = true
            end
        end
    end

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

local R = {}
local localRole = "Innocent"

local gunPickupDebounce = {}
local pendingHeroUntil  = {}

local PerkDefs = {}
pcall(function()
    local m = require(ReplicatedStorage.Database.Sync.Perks)
    if type(m) == "table" then PerkDefs = m end
end)

local function resolvePerkName(perkKey)
    if not perkKey or perkKey == "" then return nil end
    if PerkDefs[perkKey] and PerkDefs[perkKey].Name then
        return PerkDefs[perkKey].Name
    end
    for _, def in pairs(PerkDefs) do
        if def.Name == perkKey then return def.Name end
    end
    return perkKey
end

local GetPlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)

local function zK()
 if GetPlayerDataRemote then
 local ok, freshR = pcall(function()
 return GetPlayerDataRemote:InvokeServer()
 end)
 if ok and type(freshR) == "table" then
 local now = tick()
 if type(pendingHeroUntil) == "table" then
 for name, expiry in pairs(pendingHeroUntil) do
 if now < expiry then
 if freshR[name] then freshR[name].Role = "Hero" end
 else
 pendingHeroUntil[name] = nil
 end
 end
 end
 R = freshR
 end
 end

 if type(R) ~= "table" then R = {} end

 localRole = (R[LocalPlayer.Name] and R[LocalPlayer.Name].Role) or "Innocent"

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
 local foundGun = false
 for _, item in pairs(plr.Character:GetChildren()) do
 if item.Name == "Gun" and item:IsA("Tool") then
 state.sheriff = playerName
 state.hero = true
 foundGun = true
 if playerName == LocalPlayer.Name then localRole = "Hero" end
 break
 end
 end
 if not foundGun then
 local bp = plr:FindFirstChild("Backpack")
 if bp then
 for _, item in pairs(bp:GetChildren()) do
 if item.Name == "Gun" and item:IsA("Tool") then
 state.sheriff = playerName
 state.hero = true
 if playerName == LocalPlayer.Name then localRole = "Hero" end
 break
 end
 end
 end
 end
 end
 end
 end
 end
end

GameplayEvents.Fade.OnClientEvent:Connect(function(fadeData)
 if type(fadeData) ~= "table" then return end
 R = fadeData
 if type(R) ~= "table" then R = {} end
 localRole = (R[LocalPlayer.Name] and R[LocalPlayer.Name].Role) or "Innocent"

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

 for _, cb in pairs(state.roleCallbacks or {}) do
 task.spawn(cb)
 end
end)

local UpdatePlayerData = ReplicatedStorage:FindFirstChild("UpdatePlayerData") or
 ReplicatedStorage:FindFirstChild("UpdatePlayerData", true)
if UpdatePlayerData then
 UpdatePlayerData.OnClientEvent:Connect(zK)
end

task.spawn(function()
 task.wait(0.5)
 zK()
 if state.murder or state.sheriff then
 for _, cb in pairs(state.roleCallbacks or {}) do
 task.spawn(cb)
 end
 end
end)

workspace.ChildRemoved:Connect(function(child)
 if child.Name == "GunDrop" then
 task.spawn(function()
 task.wait()
 zK()
 end)
 end
end)

GameplayEvents.RoundEndFade.OnClientEvent:Connect(function()
 if type(R) == "table" then
 for _, playerData in pairs(R) do
 playerData.Died = true
 playerData.Killed = true
 end
 end
 state.murder = nil
 state.sheriff = nil
 state.hero = false
 gunPickupDebounce = {}
 pendingHeroUntil  = {}
end)

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


local function promoteToHero(player)
    local now = tick()
    if gunPickupDebounce[player.Name] and (now - gunPickupDebounce[player.Name]) < 3 then
        return
    end
    gunPickupDebounce[player.Name] = now

    state.sheriff = player.Name
    state.hero    = true
    if player.Name == LocalPlayer.Name then
        localRole = "Hero"
    end

    if not R[player.Name] then
        R[player.Name] = { Role = "Hero", Died = false, Killed = false }
    else
        R[player.Name].Role = "Hero"
    end

    pendingHeroUntil[player.Name] = now + 2

    pcall(function()
        Fluent:Notify({
            Title = "🔫 Gun Grabbed!",
            Content = player.Name .. " picked up the gun → now Hero!",
            Duration = 5
        })
    end)
end

local function watchPlayerForGunPickup(player)
    local watchedContainers = {}

    local function onGunAdded(child)
        if child.Name == "Gun" and child:IsA("Tool") then
            local pd   = R[player.Name]
            local role = pd and pd.Role or "Innocent"
            if role ~= "Murderer" and role ~= "Sheriff" and role ~= "Hero" then
                promoteToHero(player)
            end
        end
    end

    -- Fired when gun leaves character (could be unequip→backpack, or true drop→workspace)
    local function onGunRemoved(child)
        if child.Name ~= "Gun" or not child:IsA("Tool") then return end
        if player.Name ~= state.sheriff then return end
        -- Wait a short moment then check if the gun landed in backpack (unequip) or truly disappeared (drop)
        task.spawn(function()
            task.wait(0.14)
            local bp = player:FindFirstChild("Backpack")
            local stillHasGun = false
            local char2 = player.Character
            if char2 then
                for _, item in ipairs(char2:GetChildren()) do
                    if item.Name == "Gun" and item:IsA("Tool") then stillHasGun = true; break end
                end
            end
            if not stillHasGun and bp then
                for _, item in ipairs(bp:GetChildren()) do
                    if item.Name == "Gun" and item:IsA("Tool") then stillHasGun = true; break end
                end
            end
            if not stillHasGun then
                -- Gun truly dropped into workspace (GunDrop)
                local sheriffRole = state.hero and "Hero" or "Sheriff"
                local who = state.sheriff or player.Name
                pcall(function()
                    Fluent:Notify({
                        Title = "⚠️ Gun Dropped!",
                        Content = who .. " (" .. sheriffRole .. ") dropped the gun!",
                        Duration = 6,
                    })
                end)
                -- Revert state so ESP + role tracking update immediately
                if state.sheriff == player.Name then
                    state.sheriff = nil
                    state.hero    = false
                    if R[player.Name] then R[player.Name].Role = "Innocent" end
                end
            end
        end)
    end

    local function watchContainer(container)
        if not container then return end
        if watchedContainers[container] then return end  -- avoid double-watching
        watchedContainers[container] = true
        container.ChildAdded:Connect(onGunAdded)
        container.ChildRemoved:Connect(onGunRemoved)
    end

    -- Watch initial backpack
    local bp = player:FindFirstChild("Backpack")
    if bp then
        watchContainer(bp)
    else
        task.spawn(function()
            bp = player:WaitForChild("Backpack", 10)
            watchContainer(bp)
        end)
    end

    local function hookCharacter(char)
        if not char then return end
        watchContainer(char)
        -- CharacterAdded creates a brand-new Backpack — watch it too
        task.spawn(function()
            task.wait(0.15)
            local newBp = player:FindFirstChild("Backpack")
            if newBp then watchContainer(newBp) end
        end)
    end
    if player.Character then hookCharacter(player.Character) end
    player.CharacterAdded:Connect(hookCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
 if player ~= LocalPlayer then
 watchPlayerForGunPickup(player)
 end
end

Players.PlayerAdded:Connect(function(player)
 if espTextOn then addTextESP(player) end
 if espBoxOn then addBoxESP(player) end
 if espTracerOn then addTracerESP(player) end
 if espHighlightOn then addHighlightESP(player) end
 watchPlayerForGunPickup(player)
end)

-- ── GunDrop pickup scan ────────────────────────────────────────────────────────
-- Now that promoteToHero is defined above, we can safely reference it from the
-- DescendantRemoving callback.  When a GunDrop leaves the workspace it means
-- someone picked it up; scan every non-local player 70ms later (server transfer
-- latency) and promote whoever now holds a Gun tool.
workspace.DescendantRemoving:Connect(function(descendant)
    if descendant.Name ~= "GunDrop" then return end
    task.spawn(function()
        task.wait(0.07)
        for _, scanPlayer in ipairs(Players:GetPlayers()) do
            if scanPlayer ~= LocalPlayer then
                local pd   = R[scanPlayer.Name]
                local role = pd and pd.Role or "Innocent"
                if role ~= "Murderer" and role ~= "Sheriff" and role ~= "Hero" then
                    local char2  = scanPlayer.Character
                    local bp2    = scanPlayer:FindFirstChild("Backpack")
                    local hasGun = false
                    if char2 then
                        for _, item in ipairs(char2:GetChildren()) do
                            if item.Name == "Gun" and item:IsA("Tool") then hasGun = true; break end
                        end
                    end
                    if not hasGun and bp2 then
                        for _, item in ipairs(bp2:GetChildren()) do
                            if item.Name == "Gun" and item:IsA("Tool") then hasGun = true; break end
                        end
                    end
                    if hasGun then promoteToHero(scanPlayer) end
                end
            end
        end
    end)
end)



local function GetMurderer()
 for _, player in ipairs(Players:GetPlayers()) do
 if player.Name == state.murder then
 return player
 end
 end
 return nil
end

-- ── Sheriff / Hero / Murderer Death Notifier ──────────────────────────────────
-- Inspired by KC8WAJ6: hook Humanoid.Died on every character so we can instantly
-- notify when a key role is eliminated, without waiting for server events.
local deathWatchers = {}  -- [playerName] = connection

local function hookPlayerDeath(player)
    local function attachDiedHook(char)
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            -- Wait for Humanoid to replicate (small delay for remote chars)
            task.spawn(function()
                hum = char:WaitForChild("Humanoid", 5)
                if not hum then return end
                hum.Died:Connect(function()
                    local roleName
                    if player.Name == state.murder then
                        roleName = "Murderer"
                    elseif player.Name == state.sheriff then
                        roleName = state.hero and "Hero" or "Sheriff"
                    end
                    if roleName then
                        -- Mark data so role system stays consistent
                        if R[player.Name] then R[player.Name].Died = true end
                        if player.Name == state.murder then
                            state.murder = nil
                        elseif player.Name == state.sheriff then
                            state.sheriff = nil
                            state.hero    = false
                        end
                        -- Notify
                        pcall(function()
                            local icon = roleName == "Murderer" and "🔪" or roleName == "Hero" and "🦸" or "🔫"
                            Fluent:Notify({
                                Title   = icon .. " " .. roleName .. " Eliminated!",
                                Content = player.Name .. " (" .. roleName .. ") has been killed.",
                                Duration = 7,
                            })
                        end)
                    end
                end)
            end)
            return
        end
        hum.Died:Connect(function()
            local roleName
            if player.Name == state.murder then
                roleName = "Murderer"
            elseif player.Name == state.sheriff then
                roleName = state.hero and "Hero" or "Sheriff"
            end
            if roleName then
                if R[player.Name] then R[player.Name].Died = true end
                if player.Name == state.murder then
                    state.murder = nil
                elseif player.Name == state.sheriff then
                    state.sheriff = nil
                    state.hero    = false
                end
                pcall(function()
                    local icon = roleName == "Murderer" and "🔪" or roleName == "Hero" and "🦸" or "🔫"
                    Fluent:Notify({
                        Title   = icon .. " " .. roleName .. " Eliminated!",
                        Content = player.Name .. " (" .. roleName .. ") has been killed.",
                        Duration = 7,
                    })
                end)
            end
        end)
    end

    if player.Character then attachDiedHook(player.Character) end
    local conn = player.CharacterAdded:Connect(function(char)
        task.wait(0.05)  -- brief wait so Humanoid replicates
        attachDiedHook(char)
    end)
    deathWatchers[player.Name] = conn
end

-- Hook all existing and future players
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then hookPlayerDeath(p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then hookPlayerDeath(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    local c = deathWatchers[p.Name]
    if c then c:Disconnect(); deathWatchers[p.Name] = nil end
end)
-- Clear watchers on round end
GameplayEvents.RoundEndFade.OnClientEvent:Connect(function()
    -- death hooks persist; the character will respawn with a fresh hook next round
end)




local CurrentTarget     = nil
local AutoCoin          = false
local AutoCoinOperator  = false
local CoinFound         = false
local TweenSpeed        = 0.08

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

local liveCoinCache = {}

local function isCoinPart(inst)
    return inst:IsA("BasePart") and
           (inst.Name == "Coin_Server" or inst.Name == "SnowToken")
end

for _, v in ipairs(workspace:GetDescendants()) do
    if isCoinPart(v) then liveCoinCache[v] = true end
end

workspace.DescendantAdded:Connect(function(v)
    if isCoinPart(v) then liveCoinCache[v] = true end
end)
workspace.DescendantRemoving:Connect(function(v)
    liveCoinCache[v] = nil
end)

local function findNearestCoin(rootPos)
    local best, bestDist = nil, math.huge
    for coin in pairs(liveCoinCache) do
        if coin and coin.Parent then
            local d = (rootPos - coin.Position).Magnitude
            if d < bestDist then best = coin; bestDist = d end
        else
            liveCoinCache[coin] = nil
        end
    end
    return best
end

task.spawn(function()
    while true do
        task.wait(0.05)

        if not AutoCoin then
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

            local elapsed = 0
            while elapsed < TweenSpeed do
                task.wait(0.05)
                elapsed = elapsed + 0.05
                if root and root.Parent then
                    root.CFrame = autoCoinPart.CFrame
                    humanoid.PlatformStand = true
                end
            end

            liveCoinCache[coin] = nil

            TweenSpeed = 0.08
            CurrentTarget = nil
            CoinFound = false
        end

        AutoCoinOperator = false
        end
    end
    end
end)


local function predictMurderV2(murderer)
 local character = murderer.Character
 if not character then return nil end

 local rootPart = character:FindFirstChild("HumanoidRootPart")
 local humanoid = character:FindFirstChild("Humanoid")
 if not rootPart or not humanoid then return nil end

 local PHYSICS = {
 MICRO_TICK = 1/360,
 MACRO_TICK = 1/60,
 GRAVITY = workspace.Gravity,
 TERMINAL_VELOCITY = -196.2,
 PREDICTION_WINDOW = 1.8,
 SAMPLE_COUNT = 60,
 PATTERN_DEPTH = 8,
 GROUND_OFFSET = 3.2,
 MAX_SPEED_MULTIPLIER = 1.35
 }

 local PROBABILITY = {
 VELOCITY_WEIGHT = 0.88,
 PATTERN_WEIGHT = 0.82,
 MOMENTUM_WEIGHT = 0.92,
 DIRECTION_WEIGHT = 0.85,
 GROUND_WEIGHT = 0.96,
 AIR_WEIGHT = 0.78,
 CONFIDENCE_DECAY = 0.975,
 MIN_CONFIDENCE = 0.80
 }

 local MOVEMENT = {
 GROUND_FRICTION = {
 LINEAR = 0.94,
 ANGULAR = 0.92,
 SURFACE = {
 DEFAULT = 0.96,
 SMOOTH = 0.98,
 ROUGH = 0.85
 }
 },
 AIR_RESISTANCE = {
 LINEAR = 0.988,
 ANGULAR = 0.98,
 TURBULENCE = 0.08
 },
 MOMENTUM = {
 CONSERVATION = 0.97,
 TRANSFER = 0.92,
 DECAY = 0.96
 },
 JUMP = {
 COOLDOWN = 0.25,
 FORCE = 50,
 DETECTION_THRESHOLD = 4.5
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

 local function analyzeMovementPatterns()
 local patterns = {}
 local totalWeight = 0
 local currentTime = tick()

 for depth = 1, math.floor(PHYSICS.PATTERN_DEPTH/2) do
 local pattern = Vector3.new()
 local weight = 2 - (depth / PHYSICS.PATTERN_DEPTH)

 for i = depth + 1, #state.positionHistory do
 local delta = state.positionHistory[i] - state.positionHistory[i - depth]
 local timeSpan = state.timeHistory[i] - state.timeHistory[i - depth]

 if timeSpan > 0 then
 local recencyFactor = math.exp(-(currentTime - state.timeHistory[i]) * 0.5)
 pattern = pattern:Lerp(delta.Unit, 0.25 * weight * recencyFactor)
 end
 end

 table.insert(patterns, {
 direction = pattern.Unit,
 weight = weight * 1.2,
 confidence = math.exp(-depth * 0.15),
 timeScale = "short"
 })

 totalWeight = totalWeight + (weight * 1.2)
 end

 for depth = math.floor(PHYSICS.PATTERN_DEPTH/2) + 1, PHYSICS.PATTERN_DEPTH do
 local pattern = Vector3.new()
 local weight = 1 - (depth / PHYSICS.PATTERN_DEPTH) * 0.8

 for i = depth + 1, #state.positionHistory do
 local delta = state.positionHistory[i] - state.positionHistory[i - depth]
 pattern = pattern:Lerp(delta.Unit, 0.15 * weight)
 end

 table.insert(patterns, {
 direction = pattern.Unit,
 weight = weight * 0.8,
 confidence = math.exp(-depth * 0.1),
 timeScale = "long"
 })

 totalWeight = totalWeight + (weight * 0.8)
 end

 return patterns, totalWeight
 end

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

 local function predictVelocityVector()
 local patterns, totalWeight = analyzeMovementPatterns()
 local currentVel = state.velocity
 local acceleration = calculateAcceleration()
 local patternInfluence = Vector3.new()

 for _, pattern in ipairs(patterns) do
 local patternFactor = pattern.weight * pattern.confidence / totalWeight
 if pattern.timeScale == "short" then
 patternFactor = patternFactor * 1.25
 end

 patternInfluence = patternInfluence + (pattern.direction * patternFactor)
 end

 if patternInfluence.Magnitude > 0 then
 patternInfluence = patternInfluence.Unit *
 math.min(currentVel.Magnitude, humanoid.WalkSpeed * PHYSICS.MAX_SPEED_MULTIPLIER)
 end

 local directionalConsistency = calculateDirectionalConsistency()
 local speedFactor = math.min(
 currentVel.Magnitude / humanoid.WalkSpeed,
 PHYSICS.MAX_SPEED_MULTIPLIER
 )

 local predictedVel = currentVel:Lerp(
 patternInfluence,
 PROBABILITY.PATTERN_WEIGHT * directionalConsistency
 )

 predictedVel = predictedVel + (acceleration * PHYSICS.MACRO_TICK * PROBABILITY.MOMENTUM_WEIGHT)

 if predictedVel.Magnitude > humanoid.WalkSpeed * PHYSICS.MAX_SPEED_MULTIPLIER then
 predictedVel = predictedVel.Unit * humanoid.WalkSpeed * PHYSICS.MAX_SPEED_MULTIPLIER
 end

 return predictedVel
 end

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

 return 0.5
 end

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

 surfaceNormal = surfaceNormal:Lerp(result.Normal, ray.weight * 0.2)

 if ray.dir.X == 0 and ray.dir.Z == 0 then
 detectedSurface = detectSurfaceType(result.Instance)
 end
 end
 end

 return results, surfaceNormal, detectedSurface
 end

 local function detectJumpIntent(currentPos, lastPos, currentVel)
 local timeSinceLastJump = tick() - state.lastJumpTime
 local verticalChange = currentPos.Y - lastPos.Y

 if verticalChange > 1.5 and currentVel.Y > 10 and timeSinceLastJump > MOVEMENT.JUMP.COOLDOWN then
 state.lastJumpTime = tick()
 return true
 end

 return false
 end

 local function simulatePhysics(startPos, startVel, duration)
 local pos = startPos
 local vel = startVel
 local time = 0
 local confidence = 1.0
 local isGrounded = true
 local surfaceType = state.surfaceType

 local groundData, surfaceNormal, detectedSurface = calculateGroundPhysics(pos)
 isGrounded = #groundData > 0

 while time < duration do
 for _ = 1, PHYSICS.MACRO_TICK / PHYSICS.MICRO_TICK do
 if time % (PHYSICS.MACRO_TICK * 5) < PHYSICS.MICRO_TICK then
 groundData, surfaceNormal, detectedSurface = calculateGroundPhysics(pos)
 isGrounded = #groundData > 0
 surfaceType = detectedSurface
 end

 if isGrounded then
 local frictionFactor = MOVEMENT.GROUND_FRICTION.SURFACE[surfaceType] or
 MOVEMENT.GROUND_FRICTION.SURFACE.DEFAULT

 local normalComponent = vel:Dot(surfaceNormal) * surfaceNormal
 local tangentialComponent = vel - normalComponent

 tangentialComponent = tangentialComponent * (MOVEMENT.GROUND_FRICTION.LINEAR * frictionFactor)

 tangentialComponent = tangentialComponent * MOVEMENT.MOMENTUM.CONSERVATION

 vel = tangentialComponent + (normalComponent * 0.1)

 confidence = confidence * (PROBABILITY.GROUND_WEIGHT ^ PHYSICS.MICRO_TICK)
 else
 vel = vel * MOVEMENT.AIR_RESISTANCE.LINEAR

 local gravityForce = Vector3.new(
 0,
 math.max(PHYSICS.GRAVITY * PHYSICS.MICRO_TICK, PHYSICS.TERMINAL_VELOCITY),
 0
 )
 vel = vel + gravityForce

 local turbulence = Vector3.new(
 (math.random() - 0.5) * MOVEMENT.AIR_RESISTANCE.TURBULENCE,
 (math.random() - 0.5) * MOVEMENT.AIR_RESISTANCE.TURBULENCE,
 (math.random() - 0.5) * MOVEMENT.AIR_RESISTANCE.TURBULENCE
 )
 vel = vel + (turbulence * PHYSICS.MICRO_TICK)

 confidence = confidence * (PROBABILITY.AIR_WEIGHT ^ PHYSICS.MICRO_TICK)
 end

 pos = pos + (vel * PHYSICS.MICRO_TICK)

 confidence = confidence * (PROBABILITY.CONFIDENCE_DECAY ^ PHYSICS.MICRO_TICK)
 end

 time = time + PHYSICS.MACRO_TICK
 end

 return pos, vel, confidence
 end

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

 state.position = rootPart.Position
 state.velocity = rootPart.AssemblyLinearVelocity
 state.lastCalculationTime = currentTime
 end

 local function calculatePrediction()
 updateStateHistory()

 local groundData, surfaceNormal, detectedSurface = calculateGroundPhysics(state.position)
 state.groundContact = #groundData > 0
 state.surfaceType = detectedSurface

 local predictedVel = predictVelocityVector()
 local primaryPos, primaryVel, primaryConfidence = simulatePhysics(
 state.position,
 predictedVel,
 PHYSICS.PREDICTION_WINDOW
 )

 local variationVel = predictedVel * (1 + (math.random() * 0.1 - 0.05))
 local secondaryPos, secondaryVel, secondaryConfidence = simulatePhysics(
 state.position,
 variationVel,
 PHYSICS.PREDICTION_WINDOW
 )

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

 state.predictionAccuracy = math.max(primaryConfidence, secondaryConfidence)

 if state.predictionAccuracy >= PROBABILITY.MIN_CONFIDENCE then
 return ensemblePos
 end

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


local _ping    = 0.060
local _pingRaw = 0.060

task.spawn(function()
    while true do
        task.wait(0.25)
        pcall(function()
            local stats = game:GetService("Stats")
            local raw   = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            _pingRaw = math.clamp(raw, 5, 600) / 1000
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
        lastT       = tick(),
        accel       = Vector3.new(),
        lastVel     = vel,
        velHistory  = {},
        posHistory  = {},
        jumpState   = "none",
        jumpStartVelY = 0,
        jumpStartT    = 0,
        jumpStartY    = 0,
        surfaceY      = pos.Y,
        surfaceT      = tick(),
        stableYFrames = 0,
    }
    return pTrackers[player]
end

local function phantomUpdate(player)
    local char = player.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local t    = getTracker(player)
    local now  = tick()
    local dt   = now - t.lastT
    if dt <= 0 or dt > 0.5 then t.lastT = now; return end
    local pos    = root.Position
    local vel    = root.AssemblyLinearVelocity
    local rawVelY = vel.Y

    kStep(t.kx, pos.X, vel.X, dt)
    kStep(t.ky, pos.Y, vel.Y, dt)
    kStep(t.kz, pos.Z, vel.Z, dt)

    local rawAccel = (vel - t.lastVel) / dt
    if rawAccel.Magnitude > 250 then rawAccel = rawAccel.Unit * 250 end
    local alpha = math.clamp(dt * 10, 0, 0.45)
    t.accel   = t.accel:Lerp(rawAccel, alpha)

    local prevVelY = t.lastVel.Y
    if t.jumpState == "none" then
        if rawVelY > 15 and prevVelY < 8 then
            t.jumpState    = "ascending"
            t.jumpStartVelY = rawVelY
            t.jumpStartT   = now
            t.jumpStartY   = pos.Y
        end
    elseif t.jumpState == "ascending" then
        if rawVelY > t.jumpStartVelY * 0.6 then
            t.jumpStartVelY = math.max(t.jumpStartVelY, rawVelY)
        end
        if rawVelY < 2.0 then
            t.jumpState = "peak"
        end
        if now - t.jumpStartT > 1.5 then t.jumpState = "none" end
    elseif t.jumpState == "peak" then
        if rawVelY < -2.0 then
            t.jumpState = "descending"
        end
    elseif t.jumpState == "descending" then
        if math.abs(rawVelY) < 2.0 and math.abs(pos.Y - t.surfaceY) < 1.5 then
            t.jumpState = "none"
        end
        if now - t.jumpStartT > 4.0 then t.jumpState = "none" end
    end

    local prevPos = #t.posHistory > 0 and t.posHistory[#t.posHistory].p or pos
    if math.abs(pos.Y - prevPos.Y) < 0.2 and math.abs(rawVelY) < 3.0 then
        t.stableYFrames = math.min(t.stableYFrames + 1, 30)
        if t.stableYFrames >= 3 then
            t.surfaceY = pos.Y
            t.surfaceT = now
        end
    else
        t.stableYFrames = 0
    end

    local h  = t.velHistory
    local ph = t.posHistory
    if #h >= 24 then table.remove(h, 1); table.remove(ph, 1) end
    table.insert(h,  { t=now, v=vel })
    table.insert(ph, { t=now, p=pos })

    t.lastVel = vel
    t.lastT   = now
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

local function getVelAtTime(tr, dt_ahead)
    if not tr then return Vector3.new() end
    local baseVel = Vector3.new(tr.kx.v, tr.ky.v, tr.kz.v)

    local h = tr.velHistory
    local n = #h
    if n < 4 then
        return baseVel + tr.accel * dt_ahead
    end

    local now = tick()
    local t0  = h[n].t
    local sumW, sumWt, sumWt2 = 0, 0, 0
    local sumWv  = Vector3.new()
    local sumWvt = Vector3.new()

    for i = math.max(1, n - 15), n do
        local age  = now - h[i].t
        local w    = math.exp(-age * 6)
        local t_rel = h[i].t - t0
        sumW   = sumW   + w
        sumWt  = sumWt  + w * t_rel
        sumWt2 = sumWt2 + w * t_rel * t_rel
        sumWv  = sumWv  + h[i].v * w
        sumWvt = sumWvt + h[i].v * (w * t_rel)
    end

    local denom = sumW * sumWt2 - sumWt * sumWt
    local trend = Vector3.new()
    if math.abs(denom) > 1e-6 then
        trend = (sumWvt * sumW - sumWv * sumWt) / denom
        if trend.Magnitude > 220 then trend = trend.Unit * 220 end
    else
        trend = tr.accel
    end

    local finalTrend = trend
    if tr.jumpState == "ascending" or tr.jumpState == "peak" then
        local elapsed = now - tr.jumpStartT
        local projVelY = tr.jumpStartVelY - ROBLOX_GRAVITY * (elapsed + dt_ahead)
        finalTrend = Vector3.new(trend.X, (projVelY - baseVel.Y) / math.max(dt_ahead, 0.001), trend.Z)
    elseif tr.jumpState == "descending" then
        finalTrend = Vector3.new(trend.X, -ROBLOX_GRAVITY, trend.Z)
    end

    return baseVel + finalTrend * dt_ahead
end

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

RunService.RenderStepped:Connect(function()
    local m = GetMurderer()
    if m and m.Character then phantomUpdate(m) end
end)
Players.PlayerRemoving:Connect(function(p) pTrackers[p] = nil end)

-- Free Silent Aim mode (declared here so doFusionShoot can reference it)
local freeSilentAimMode = "Normal"

local function doFusionShoot(targetPlayer)
 local char = targetPlayer.Character; if not char then return end
 local mRoot = char:FindFirstChild("HumanoidRootPart"); if not mRoot then return end
 local mHead = char:FindFirstChild("Head")

 local myChar = LocalPlayer.Character; if not myChar then return end
 local humanoid = myChar:FindFirstChild("Humanoid"); if not humanoid then return end

 local gun = LocalPlayer.Backpack:FindFirstChild("Gun")
 or LocalPlayer.Backpack:FindFirstChild("Revolver")
 or myChar:FindFirstChild("Gun")
 or myChar:FindFirstChild("Revolver")
 if not gun then return end

 -- ── Compute predicted aim position based on selected free-aim mode ──────────
 local predicted
 if freeSilentAimMode == "Dynamic" then
     -- Dynamic: simple velocity-based lead (ping + half-tick)
     phantomUpdate(targetPlayer)
     local ping      = getPing()
     local smoothVel = getSmoothedVel(targetPlayer)
     local lead      = ping + 0.017
     local velOff    = Vector3.new(smoothVel.X * lead, 0, smoothVel.Z * lead)
     -- Clamp vertical: conserved lateral momentum during jump, no gravity calc
     local velY      = math.clamp(smoothVel.Y * lead * 0.4, -2.0, 2.0)
     velOff          = Vector3.new(velOff.X, velY, velOff.Z)
     predicted       = mRoot.Position + velOff + Vector3.new(0, 1.5, 0)
     -- Clamp to within body height range
     local headY = mHead and mHead.Position.Y or (mRoot.Position.Y + 2.9)
     predicted   = Vector3.new(predicted.X,
                               math.clamp(predicted.Y, mRoot.Position.Y + 0.3, headY + 0.2),
                               predicted.Z)
 else
     -- Normal: raw shot, no prediction whatsoever
     local headPos = mHead and mHead.Position or (mRoot.Position + Vector3.new(0, 2.9, 0))
     predicted     = mRoot.Position + Vector3.new(0, 1.5, 0)
     _ = headPos -- referenced to suppress lint
 end

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

 pcall(function()
 shootRemote:FireServer(arg1, CFrame.new(predicted))
 end)

 -- Dynamic mode: 2 burst shots with re-predicted positions
 if freeSilentAimMode == "Dynamic" then
     local burst = 0
     local burstConn
     burstConn = RunService.Heartbeat:Connect(function()
         burst = burst + 1
         if burst > 2 then burstConn:Disconnect(); return end
         phantomUpdate(targetPlayer)
         local ping2     = getPing()
         local sv2       = getSmoothedVel(targetPlayer)
         local lead2     = ping2 + 0.017
         local vOff2     = Vector3.new(sv2.X * lead2, math.clamp(sv2.Y * lead2 * 0.4, -2, 2), sv2.Z * lead2)
         local freshPred = mRoot.Position + vOff2 + Vector3.new(0, 1.5, 0)
         local freshArg1 = (rayAtt and rayAtt.WorldCFrame)
                        or (myRoot and CFrame.new(myRoot.Position))
                        or CFrame.new()
         pcall(function() shootRemote:FireServer(freshArg1, CFrame.new(freshPred)) end)
     end)
 else
     -- Normal: one extra burst shot at the same static position
     local burst = 0
     local burstConn
     burstConn = RunService.Heartbeat:Connect(function()
         burst = burst + 1
         if burst > 2 then burstConn:Disconnect(); return end
         local freshArg1 = (rayAtt and rayAtt.WorldCFrame)
                        or (myRoot and CFrame.new(myRoot.Position))
                        or CFrame.new()
         pcall(function() shootRemote:FireServer(freshArg1, CFrame.new(predicted)) end)
     end)
 end
end


SilentAimButtonV2.MouseButton1Click:Connect(function()
 local murderer=GetMurderer()
 if not murderer then return end
 doFusionShoot(murderer)
end)


local premiumSilentAim = {
    enabled   = false,
    autoAim   = false,
    lastShot  = 0,
    cooldown  = 0.15,
}

local ROBLOX_GRAVITY = workspace.Gravity

local function hasLOS(fromPos, toPos, targetChar)
    local myChar = LocalPlayer.Character
    local dir    = toPos - fromPos
    local dist   = dir.Magnitude
    if dist < 0.5 then return true end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    local blacklist = {targetChar}
    if myChar then table.insert(blacklist, myChar) end
    rp.FilterDescendantsInstances = blacklist
    local hit = workspace:Raycast(fromPos, dir.Unit * dist, rp)
    return hit == nil
end

-- ── True character bounding box ────────────────────────────────────────────────
-- Scans all BaseParts of a character to find the real min/max Y and XZ centre.
-- This is critical for small/custom avatars where head-to-root distance is tiny
-- and a fixed body-height assumption produces completely wrong aim points.
local function measureCharBounds(char)
    local minY, maxY = math.huge, -math.huge
    local cxz = Vector3.new(); local n = 0
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            local half = p.Size.Y * 0.5
            local by   = p.Position.Y - half
            local ty   = p.Position.Y + half
            if by < minY then minY = by end
            if ty > maxY then maxY = ty end
            cxz = cxz + Vector3.new(p.Position.X, 0, p.Position.Z)
            n = n + 1
        end
    end
    if n == 0 then return nil, nil, nil end
    return minY, maxY, cxz / n
end

-- ── LOS-aware candidate finder ─────────────────────────────────────────────────
-- Given the predicted world position, try multiple body-relative points to find
-- one that isn't occluded by cover.  Works in body-height fractions so it scales
-- correctly for small avatars.
-- ── bestClearPoint ─────────────────────────────────────────────────────────────
-- First tries the predicted point directly. If occluded, tries a set of known-good
-- body positions (head, chest, pelvis, root) in order.  Falls back to the predicted
-- point if everything is occluded (e.g., full cover).
local function bestClearPoint(fromPos, predictedPos, targetChar)
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    local head = targetChar:FindFirstChild("Head")

    local rootY  = root and root.Position.Y or 0
    local headY  = head and head.Position.Y or (rootY + 2.9)
    local chestY = rootY + (headY - rootY) * 0.58

    local candidates = {
        predictedPos,
        head and head.Position,
        root and Vector3.new(root.Position.X, chestY,      root.Position.Z),
        root and Vector3.new(root.Position.X, rootY + 1.5, root.Position.Z),
        root and root.Position,
    }
    for _, pos in ipairs(candidates) do
        if pos and hasLOS(fromPos, pos, targetChar) then
            return pos, true
        end
    end
    return predictedPos, false
end

-- ── solvePremiumIntercept ──────────────────────────────────────────────────────
-- Full physics pipeline:
--   1. Build lead time from ping + jitter pad (by ping band) + range micro-lead
--   2. Dual-pass Kalman velocity blend for XZ prediction
--   3. Wall-hug raycast correction
--   4. Kalman/input agreement blend with range scaling
--   5. 2nd-order acceleration correction
--   6. Vertical (Y):
--        grounded   → stable surface aim (platformBase + bodyH*0.60)
--        ascending  → full parabolic arc from recorded jumpStartVelY
--        descending → kinematic gravity integration from current velY
--        generic air → kinematic gravity integration
--   7. LOS check → body-fraction grid fallback → raw-root last resort
--
-- FIXES vs original V3:
--   • [FIX-1] airborneAimY uses current rootY (not platformBase) so arc
--             displacement is added to the real airborne body centre
--   • [FIX-2] descending handled as its own branch with full gravity math
--   • [FIX-3] clickLatencyOffset injected into baseLead by doPremiumShoot
local function solvePremiumIntercept(targetPlayer, fromPos)
    local char = targetPlayer.Character;   if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return nil end
    local hum  = char:FindFirstChild("Humanoid")
    local head = char:FindFirstChild("Head")

    phantomUpdate(targetPlayer)
    local tr        = pTrackers[targetPlayer]
    local smoothVel = getSmoothedVel(targetPlayer)

    -- ── 1. Lead time ─────────────────────────────────────────────────────────
    local rawPing     = getPing()
    -- [FIX-3] click latency offset injected by doPremiumShoot (~33 ms for button tap)
    local clickOffset = premiumSilentAim._clickLatencyOffset or 0
    local baseLead    = rawPing + 0.0167 + clickOffset

    local shooterPos = fromPos or root.Position
    local rangeDist  = (root.Position - shooterPos).Magnitude
    local rangeLead  = math.min(rangeDist * 0.00008, 0.025)

    -- Ground detection: 5-ray cast around the base of the character
    local rpGnd = RaycastParams.new()
    rpGnd.FilterType = Enum.RaycastFilterType.Blacklist
    rpGnd.FilterDescendantsInstances = {char}
    local function castGnd(off)
        return workspace:Raycast(root.Position + off, Vector3.new(0, -5.2, 0), rpGnd)
    end
    local isOnGround =  castGnd(Vector3.new( 0,   0,    0)) ~= nil
    if not isOnGround then isOnGround = castGnd(Vector3.new( 0.6, 0.8,  0  )) ~= nil end
    if not isOnGround then isOnGround = castGnd(Vector3.new(-0.6, 0.8,  0  )) ~= nil end
    if not isOnGround then isOnGround = castGnd(Vector3.new( 0,   0.8,  0.6)) ~= nil end
    if not isOnGround then isOnGround = castGnd(Vector3.new( 0,   0.8, -0.6)) ~= nil end
    if not isOnGround and tr and tr.stableYFrames >= 4 then isOnGround = true end

    local rawVelY    = root.AssemblyLinearVelocity.Y
    local kalmanVelY = smoothVel.Y

    local isJumping  = (rawVelY > 4.0)  and not isOnGround
    local isFalling  = (rawVelY < -4.0) and not isOnGround
    local isAirborne = (isJumping or isFalling) and not isOnGround

    if tr then
        if     tr.jumpState == "ascending"  then isJumping=true;  isFalling=false; isAirborne=true; isOnGround=false
        elseif tr.jumpState == "peak"       then isJumping=false; isFalling=false; isAirborne=true; isOnGround=false
        elseif tr.jumpState == "descending" then isJumping=false; isFalling=true;  isAirborne=true; isOnGround=false
        end
    end

    -- Ping-band jitter pads calibrated to absorb server-tick jitter at each latency tier
    local pingBand = (rawPing <= 0.060) and 0
                  or (rawPing <= 0.120) and 1
                  or (rawPing <= 0.200) and 2
                  or (rawPing <= 0.300) and 3
                  or 4
    local jitterPads = {
        [0]={ground=1.00, ascending=1.18, descending=1.12},
        [1]={ground=1.06, ascending=1.26, descending=1.20},
        [2]={ground=1.14, ascending=1.36, descending=1.28},
        [3]={ground=1.22, ascending=1.48, descending=1.40},
        [4]={ground=1.28, ascending=1.60, descending=1.52},
    }
    local pad       = jitterPads[pingBand]
    local jitterPad = isJumping and pad.ascending
                   or (isFalling and pad.descending or pad.ground)
    local leadTime  = math.clamp(baseLead * jitterPad + rangeLead, 0.018, 0.700)

    -- ── 2. Lateral (XZ) velocity ─────────────────────────────────────────────
    local walkSpeed = (hum and hum.WalkSpeed) or 16
    local moveDir   = (hum and hum.MoveDirection) or Vector3.new()

    -- Dual-pass: short-term (50%) and full lead-time velocity, blended by range
    local pass1Vel = tr and getVelAtTime(tr, leadTime * 0.5) or smoothVel
    local pass2Vel = tr and getVelAtTime(tr, leadTime)       or smoothVel
    local trendMix = math.clamp((rangeDist - 40) / 80, 0, 1)
    local trendVel = pass1Vel:Lerp(pass2Vel, trendMix)

    -- Wall-hug: if observed lateral speed < expected from input, deflect off wall
    local expectedLateral = moveDir.Magnitude * walkSpeed
    local actualLateral   = Vector3.new(trendVel.X, 0, trendVel.Z).Magnitude
    local wallFactor = (expectedLateral > 1)
        and math.clamp(actualLateral / expectedLateral, 0, 1) or 1.0
    local effectiveMoveDir = moveDir
    if wallFactor < 0.55 and moveDir.Magnitude > 0.1 then
        local rpW = RaycastParams.new()
        rpW.FilterType = Enum.RaycastFilterType.Blacklist
        rpW.FilterDescendantsInstances = {char}
        local wRay = workspace:Raycast(root.Position, moveDir * 3.5, rpW)
        if wRay then
            local n = wRay.Normal
            effectiveMoveDir = moveDir - n * moveDir:Dot(n)
        end
    end

    -- Kalman / input-direction agreement blend, scaled by range
    local rangeBlend = math.clamp(1 - (rangeDist - 40) / 130, 0.30, 1.0)
    local vel = trendVel
    if hum then
        local inputVel  = effectiveMoveDir * walkSpeed
        local agreement = 1.0
        if trendVel.Magnitude > 0.5 and inputVel.Magnitude > 0.5 then
            agreement = trendVel.Unit:Dot(inputVel.Unit)
        end
        local baseBlend
        if isAirborne then
            baseBlend = 0.15   -- mid-air: trust physics (Kalman) over input
        elseif agreement > 0.85 then
            baseBlend = 0.50   -- moving in same direction: lean on input
        elseif agreement < 0.45 then
            baseBlend = 0.05   -- direction reversed: almost pure Kalman
        else
            baseBlend = 0.50 * ((agreement - 0.45) / 0.40)
        end
        baseBlend = math.clamp(baseBlend * rangeBlend * math.max(wallFactor, 0.10), 0.05, 0.50)
        vel = trendVel * (1 - baseBlend) + inputVel * baseBlend
    end

    -- Hard lateral speed cap
    local lateralCap = isAirborne and (walkSpeed * 1.30) or (walkSpeed * 1.10)
    local lv = Vector3.new(vel.X, 0, vel.Z)
    if lv.Magnitude > lateralCap then lv = lv.Unit * lateralCap end
    vel = Vector3.new(lv.X, vel.Y, lv.Z)

    -- 2nd-order acceleration correction
    local accelVec = tr and (getVelAtTime(tr, leadTime) - trendVel) or Vector3.new()
    accelVec = Vector3.new(accelVec.X, 0, accelVec.Z)
    if accelVec.Magnitude > walkSpeed * 2.0 then
        accelVec = accelVec.Unit * (walkSpeed * 2.0)
    end
    local accelCap   = math.clamp(1.2 + (rangeDist - 40) / 120, 1.2, 1.5)
    local accelScale = math.clamp(rawPing / 0.150, 0, accelCap)
        * (isAirborne and 0.40 or 1.0)
        * math.max(wallFactor, 0.15) * rangeBlend

    local predicted = root.Position
        + vel * leadTime
        + accelVec * (accelScale * 0.5 * leadTime * leadTime)

    -- ── 3. Vertical (Y) ──────────────────────────────────────────────────────
    local rootY    = root.Position.Y
    local rawHeadY = head and head.Position.Y or (rootY + 2.9)
    local headY    = math.max(rawHeadY, rootY + 1.0)
    local bodyH    = headY - rootY

    -- Ground aim: stable surface base so aim doesn't jitter on slopes
    local platformBase = (tr and tr.stableYFrames >= 3) and tr.surfaceY or rootY
    local groundAimY   = platformBase + bodyH * 0.60

    -- [FIX-1] Airborne aim: use CURRENT rootY, not platformBase
    -- Original bug: platformBase pointed to the ground far below the airborne target,
    -- making arcDisp additions land completely off the body.
    local airborneAimY = rootY + bodyH * 0.60

    local finalY
    if isAirborne then
        -- ── Ascending / at jump peak ──────────────────────────────────────────
        if tr and (tr.jumpState == "ascending" or tr.jumpState == "peak") then
            local elapsed  = math.max(tick() - tr.jumpStartT, 0)
            local tTotal   = elapsed + leadTime
            local arcTotal = tr.jumpStartVelY * tTotal - 0.5 * ROBLOX_GRAVITY * tTotal  * tTotal
            local arcSoFar = tr.jumpStartVelY * elapsed - 0.5 * ROBLOX_GRAVITY * elapsed * elapsed
            -- Arc delta = how much root will move vertically during leadTime
            local futureDisp = arcTotal - arcSoFar
            -- Add to CURRENT airborne body centre (FIX-1)
            finalY = airborneAimY + futureDisp

        -- [FIX-2] Descending: full kinematic gravity integration ──────────────
        elseif tr and tr.jumpState == "descending" then
            local gravDrop  = 0.5 * ROBLOX_GRAVITY * leadTime * leadTime
            local predRootY = rootY + kalmanVelY * leadTime - gravDrop
            finalY = predRootY + bodyH * 0.60

        -- ── Generic airborne (no tracked jump state) ─────────────────────────
        else
            local gravDrop  = 0.5 * ROBLOX_GRAVITY * leadTime * leadTime
            local predRootY = rootY + kalmanVelY * leadTime - gravDrop
            finalY = predRootY + bodyH * 0.60
        end

        -- Clamp to plausible body envelope at predicted time
        local predRootY = rootY + kalmanVelY * leadTime - 0.5 * ROBLOX_GRAVITY * leadTime * leadTime
        local predHeadY = predRootY + bodyH
        local clampMin  = math.min(predRootY + 0.15, rootY - 4.0)
        local clampMax  = math.max(predHeadY + 0.3,  headY + 4.0)
        finalY = math.clamp(finalY, clampMin, clampMax)
    else
        -- ── Grounded ─────────────────────────────────────────────────────────
        local velYContrib = (math.abs(rawVelY) >= 2.0) and (rawVelY * leadTime * 0.12) or 0
        finalY = groundAimY + velYContrib
        finalY = math.clamp(finalY, rootY + 0.2, headY + 0.3)
    end

    predicted = Vector3.new(predicted.X, finalY, predicted.Z)

    -- ── 4. LOS check with dense body-offset grid fallback ────────────────────
    if fromPos then
        local clearPos, wasLOS = bestClearPoint(fromPos, predicted, char)
        if wasLOS then
            predicted = clearPos
        else
            -- Dense body-fraction offset grid (14 candidates across chest/head/pelvis)
            local offsets = {
                Vector3.new( 1.0, bodyH*0.55,  0),   Vector3.new(-1.0, bodyH*0.55,  0),
                Vector3.new( 0,   bodyH*0.55,  1.0), Vector3.new( 0,   bodyH*0.55, -1.0),
                Vector3.new( 0.7, bodyH*0.90,  0),   Vector3.new(-0.7, bodyH*0.90,  0),
                Vector3.new( 1.6, bodyH*0.55,  0),   Vector3.new(-1.6, bodyH*0.55,  0),
                Vector3.new( 0.8, bodyH*0.75,  0.8), Vector3.new(-0.8, bodyH*0.75, -0.8),
                Vector3.new( 0.8, bodyH*0.75, -0.8), Vector3.new(-0.8, bodyH*0.75,  0.8),
                Vector3.new( 0,   bodyH*0.35,  1.2), Vector3.new( 0,   bodyH*0.35, -1.2),
            }
            local found = false
            for _, off in ipairs(offsets) do
                local cand = root.Position + off
                if hasLOS(fromPos, cand, char) then
                    predicted = cand; found = true; break
                end
            end
            if not found then predicted = clearPos end  -- stay at best-guess if fully covered
        end
    end

    return predicted
end

-- ── doPremiumShoot ─────────────────────────────────────────────────────────────
-- Fires the gun at the solved intercept point.
-- • task.spawn used by button → first shot fires next frame (acceptable)
-- • 10 phantom updates prime the Kalman filter before the solve
-- • click-latency offset of 33ms added to baseLead inside solver
-- • Airborne targets get +4 extra burst shots (arc changes every frame)
-- • lastShot stamped after the first FireServer so cooldown is accurate
local function doPremiumShoot(targetPlayer)
    if tick() - premiumSilentAim.lastShot < premiumSilentAim.cooldown then return end

    local char  = targetPlayer.Character; if not char then return end
    local mRoot = char:FindFirstChild("HumanoidRootPart"); if not mRoot then return end
    local mHead = char:FindFirstChild("Head")

    local myChar   = LocalPlayer.Character; if not myChar then return end
    local humanoid = myChar:FindFirstChild("Humanoid"); if not humanoid then return end

    -- Prime Kalman with 10 synchronous samples — critical for jump-arc accuracy
    for _ = 1, 10 do phantomUpdate(targetPlayer) end

    local tr             = pTrackers[targetPlayer]
    local targetAirborne = tr and (tr.jumpState == "ascending"
                                or tr.jumpState == "peak"
                                or tr.jumpState == "descending")

    local gun = LocalPlayer.Backpack:FindFirstChild("Gun")
             or LocalPlayer.Backpack:FindFirstChild("Revolver")
             or myChar:FindFirstChild("Gun")
             or myChar:FindFirstChild("Revolver")
    if not gun then
        Fluent:Notify({ Title = "⭐ Premium Aim", Content = "No gun found in backpack or hand.", Duration = 3 })
        return
    end

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

    local barrelPos = getBarrelPos()

    -- [FIX-3] Inject GUI click-latency offset into solver's baseLead
    premiumSilentAim._clickLatencyOffset = 0.033

    local predicted = solvePremiumIntercept(targetPlayer, barrelPos)
                   or (mHead and mHead.Position)
                   or mRoot.Position + Vector3.new(0, 1.5, 0)

    premiumSilentAim._clickLatencyOffset = nil

    -- Burst count scales with ping; airborne targets get +4 extra frames
    local pingMs = getPing() * 1000
    local burstBase
    if     pingMs <= 60  then burstBase = 2
    elseif pingMs <= 120 then burstBase = 3
    elseif pingMs <= 200 then burstBase = 4
    elseif pingMs <= 300 then burstBase = 5
    elseif pingMs <= 400 then burstBase = 6
    else                      burstBase = 7
    end
    local burstMax = targetAirborne and (burstBase + 4) or burstBase

    pcall(function()
        shootRemote:FireServer(getArg1(), CFrame.new(predicted))
    end)

    premiumSilentAim.lastShot = tick()

    local burst = 0
    local burstConn
    burstConn = RunService.Heartbeat:Connect(function()
        burst = burst + 1
        if burst > burstMax then burstConn:Disconnect(); return end

        phantomUpdate(targetPlayer)
        local freshBarrel = getBarrelPos()
        premiumSilentAim._clickLatencyOffset = 0.033
        local freshPredicted = solvePremiumIntercept(targetPlayer, freshBarrel)
                            or (mHead and mHead.Position)
                            or mRoot.Position + Vector3.new(0, 1.5, 0)
        premiumSilentAim._clickLatencyOffset = nil
        pcall(function()
            shootRemote:FireServer(getArg1(), CFrame.new(freshPredicted))
        end)
    end)
end

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

local PremAimStroke       = Instance.new("UIStroke", PremiumAimButton)
PremAimStroke.Color       = Color3.fromRGB(255, 215, 0)
PremAimStroke.Thickness   = 2.5
PremAimStroke.Transparency = 0.2

local PremAimCorner            = Instance.new("UICorner", PremiumAimButton)
PremAimCorner.CornerRadius     = UDim.new(0, 8)

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
        -- Fire directly on this frame — NO task.spawn (that adds ≥1 Heartbeat delay)
        doPremiumShoot(murderer)
    end
end)


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
 return Color3.fromRGB(80, 220, 80)
end

local function flashRoleLabel(role)
 RoleFlashLabel.Text = role
 RoleFlashLabel.TextColor3 = roleFlashColor(role)
 RoleFlashLabel.Visible = true
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
 task.delay(6, function()
 RoleFlashLabel.Visible = false
 if conn then conn:Disconnect() end
 end)
end

local function NotifyMurdererPerk()
 if not next(R) then
 local ok, freshR = pcall(function()
 return GetPlayerDataRemote and GetPlayerDataRemote:InvokeServer()
 end)
 if ok and type(freshR) == "table" then R = freshR end
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

 if sheriffName then
 Fluent:Notify({
 Title = (sheriffRole == "Hero" and "Hero" or "Sheriff") .. " Found",
 Content = sheriffName .. " is the " .. sheriffRole .. " this round.",
 Duration = 5
 })
 end
end

local autoNotifyEnabled = true

local function onRoundStart()
 flashRoleLabel(localRole)

 if autoNotifyEnabled then
 task.spawn(function()
 task.wait(0.8)
 NotifyMurdererPerk()
 end)
 end
end

state.roleCallbacks["RoleAutoNotifier"] = onRoundStart


local function predictMurderSharpShooter(murderer)
 local character = murderer.Character
 if not character then return nil end

 local primaryPart = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
 local humanoid = character:FindFirstChild("Humanoid")
 if not primaryPart or not humanoid then return nil end

 local CONSTANTS = {
 TICK_RATE = 0.016,
 GRAVITY = 196.2,
 MAX_PREDICTION_STEPS = 15,
 JUMP_POWER = humanoid.JumpPower or 50,
 WALK_SPEED = humanoid.WalkSpeed,

 LOG_BASE = math.exp(1),
 SCALE_FACTOR = 1.5,
 MIN_LOG_VALUE = 0.1,
 MAX_LOG_VALUE = 5.0,

 VELOCITY_WEIGHT = 0.7,
 DIRECTION_WEIGHT = 0.3,
 ACCELERATION_CAP = 75,
 PREDICTION_SMOOTHING = 0.85,
 WALL_OFFSET = 2.5,

 DISTANCE_DECAY = 0.8,
 TIME_DECAY = 0.9
 }

 local function applyLogarithmicScale(value, min, max)
 local normalized = (value - min) / (max - min)
 local logScaled = math.log(normalized * (CONSTANTS.LOG_BASE - 1) + 1) / math.log(CONSTANTS.LOG_BASE)
 return min + logScaled * (max - min)
 end

 local function getLogarithmicWeight(distance, maxDistance)
 local normalizedDist = math.clamp(distance / maxDistance, CONSTANTS.MIN_LOG_VALUE, CONSTANTS.MAX_LOG_VALUE)
 return math.log(normalizedDist * CONSTANTS.SCALE_FACTOR + 1) / math.log(CONSTANTS.LOG_BASE + 1)
 end

 local predictionState = {
 position = primaryPart.Position,
 velocity = primaryPart.AssemblyLinearVelocity,
 moveDirection = humanoid.MoveDirection,
 lastJumpTime = 0,
 distanceWeight = 1
 }

 local function calculateAdaptiveVelocity()
 local baseVelocity = predictionState.velocity
 local inputVelocity = predictionState.moveDirection * CONSTANTS.WALK_SPEED

 local speedMagnitude = baseVelocity.Magnitude
 local scaledSpeed = applyLogarithmicScale(
 speedMagnitude,
 0,
 CONSTANTS.ACCELERATION_CAP
 )

 local normalizedVel = baseVelocity.Unit * scaledSpeed

 local distanceWeight = getLogarithmicWeight(
 (primaryPart.Position - predictionState.position).Magnitude,
 50
 )

 local blendedVelocity = normalizedVel * (CONSTANTS.VELOCITY_WEIGHT * distanceWeight) +
 inputVelocity * (CONSTANTS.DIRECTION_WEIGHT * (1 - distanceWeight))

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

 local function predictJumpArc(startPos, startVel)
 if not humanoid.Jump then return startPos end

 local timeInAir = CONSTANTS.JUMP_POWER / CONSTANTS.GRAVITY
 local horizontalVel = startVel * Vector3.new(1, 0, 1)

 local scaledJumpPower = applyLogarithmicScale(
 CONSTANTS.JUMP_POWER,
 0,
 CONSTANTS.JUMP_POWER * 1.5
 )

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

 local function handleCollision(origin, target)
 local rayParams = RaycastParams.new()
 rayParams.FilterType = Enum.RaycastFilterType.Blacklist
 rayParams.FilterDescendantsInstances = {character}

 local result = workspace:Raycast(origin, target - origin, rayParams)
 if result then
 local normal = result.Normal
 local direction = (target - origin).Unit

 local reflectionStrength = getLogarithmicWeight(
 (result.Position - origin).Magnitude,
 20
 )

 local reflection = direction -
 (2 * direction:Dot(normal) * normal * reflectionStrength)

 return result.Position + (reflection * CONSTANTS.WALL_OFFSET)
 end

 return target
 end

 local predictedPosition = predictionState.position
 local currentVelocity = calculateAdaptiveVelocity()

 for step = 1, CONSTANTS.MAX_PREDICTION_STEPS do
 local stepMultiplier = step / CONSTANTS.MAX_PREDICTION_STEPS
 local timeStep = CONSTANTS.TICK_RATE * stepMultiplier

 local stepWeight = getLogarithmicWeight(step, CONSTANTS.MAX_PREDICTION_STEPS)

 local nextPosition = predictedPosition +
 (currentVelocity * timeStep * stepWeight)

 nextPosition += Vector3.new(
 0,
 -0.5 * CONSTANTS.GRAVITY * timeStep * timeStep * CONSTANTS.TIME_DECAY,
 0
 )

 nextPosition = predictJumpArc(nextPosition, currentVelocity)
 predictedPosition = handleCollision(predictedPosition, nextPosition)

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


local _TS = game:GetService("TweenService")

local function ease(obj, props, dur, style, dir)
    style = style or Enum.EasingStyle.Sine
    dir   = dir   or Enum.EasingDirection.Out
    local t = _TS:Create(obj, TweenInfo.new(dur, style, dir), props)
    t:Play(); return t
end

local function fadeIn(label, dur)
    ease(label, { TextTransparency = 0 }, dur or 0.6)
end


local function safeLoad(url, label)
    local body = nil

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

Tabs.Main:AddParagraph({
 Title = "Development Notice",
 Content = "OmniHub is still in early development. You may experience bugs during usage. If you have suggestions for improving our MM2 script, please join our Discord server Thank you ."
})

local MainSection = Tabs.Main:AddSection("User Information")

local UserInfo = Tabs.Main:AddParagraph({
 Title = "User Details",
 Content = string.format(
 "Username: %s\nUser ID: %s\nServer ID: %s",
 game.Players.LocalPlayer.Name,
 game.Players.LocalPlayer.UserId,
 game.JobId
 )
})

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


local function forAllOtherPlayers(fn)
 for _, p in ipairs(Players:GetPlayers()) do
 if p ~= LocalPlayer then fn(p) end
 end
end

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

Tabs.Visuals:AddToggle("ESPHighlightToggle", {
 Title = "Character Highlight + Outline",
 Description = "Highlights The Players.",
 Default = false,
 Callback = function(on)
 espHighlightOn = on
 if on then
 forAllOtherPlayers(addHighlightESP)
 Fluent:Notify({
 Title = "Character Highlight",
 Content = "ON",
 Duration = 3
 })
 else
 forAllOtherPlayers(removeHighlightESP)
 Fluent:Notify({ Title = "Character Highlight", Content = " OFF.", Duration = 3 })
 end
 end
})

Tabs.Visuals:AddToggle("GunDropESPToggle", {
 Title = "GunDrop Highlight",
 Default = false,
 Callback = function(on)
 gunDropESPEnabled = on
 if on then
 startGunDropESP()
 Fluent:Notify({ Title = "GunDrop ESP", Content = "ON", Duration = 3 })
 else
 stopGunDropESP()
 Fluent:Notify({ Title = "GunDrop ESP", Content = "OFF.", Duration = 3 })
 end
 end
})

local TimerGui = Instance.new("ScreenGui")
local TimerFrame = Instance.new("Frame")
local TimerLabel = Instance.new("TextLabel")

TimerGui.Name = "RoundTimerGui"
TimerGui.ResetOnSpawn = false
TimerGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

TimerFrame.Name = "TimerFrame"
TimerFrame.Size = UDim2.new(0, 150, 0, 40)
TimerFrame.Position = UDim2.new(0.5, -75, 0, 10)
TimerFrame.BackgroundTransparency = 0.3
TimerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TimerFrame.Parent = TimerGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = TimerFrame

TimerLabel.Name = "TimerText"
TimerLabel.Size = UDim2.new(1, 0, 1, 0)
TimerLabel.BackgroundTransparency = 1
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.TextSize = 24
TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.Parent = TimerFrame

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

local function formatTime(seconds)
 local minutes = math.floor(seconds / 60)
 local remainingSeconds = seconds % 60

 if minutes > 0 then
 return string.format("%d:%02d", minutes, remainingSeconds)
 else
 return string.format("%ds", remainingSeconds)
 end
end

local timerRemote = game:GetService("ReplicatedStorage").Remotes.Extras.GetTimer

local TimerToggle = Tabs.Visuals:AddToggle("ShowTimer", {
 Title = "Show Round Timer",
 Description = "This Is temporary not working",
 Default = true,
 Callback = function(Value)
 TimerGui.Enabled = Value
 end
})

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


local SilentAimEnabled = false
local SilentAimToggle = Tabs.Combat:AddToggle("SilentAimToggle", {
 Title = "Silent Aim",
 Default = false,
 Callback = function(toggle)
 SilentAimEnabled = toggle
 SilentAimButtonV2.Visible = toggle
 end
})

-- Free Silent Aim mode dropdown (variable declared earlier, before doFusionShoot)
Tabs.Combat:AddDropdown("FreeSilentAimModeDropdown", {
    Title       = "Free Silent Aim Mode",
    Description = "Normal: raw shot (no calc)  |  Dynamic: simple velocity-based lead",
    Values      = { "Normal", "Dynamic" },
    Default     = "Normal",
    Callback    = function(value)
        freeSilentAimMode = value
        Fluent:Notify({
            Title   = "Free Silent Aim Mode",
            Content = "Mode set to: " .. value,
            Duration = 3,
        })
    end,
})



local AutoNotifyToggle = Tabs.Combat:AddToggle("AutoNotifyToggle", {
 Title = "Auto Notify Murderer Perk + Roles",
 Default = true,
 Callback = function(toggle)
 autoNotifyEnabled = toggle
 Fluent:Notify({
 Title = "Role Auto Notifier",
 Content = toggle
 and "AUTO NOTIFY ON"
 or "Auto notify disabled.",
 Duration = 3
 })
 end
})

Tabs.Combat:AddButton({
 Title = "Notify Murderer Perk Now",
 Name = "ManualPerkButton",
 Callback = function()
 NotifyMurdererPerk()
 end
})

Tabs.Combat:AddSection("God Mode")

Tabs.Combat:AddToggle("GodModeToggle", {
    Title = "God Mode",
    Description = "Locks your health to max every frame. Knives, traps, and fall damage cannot kill you.",
    Default = false,
    Callback = function(v)
        godMode.enabled = v
        Fluent:Notify({
            Title = "God Mode",
            Content = v and "GOD MODE ON." or "God Mode OFF.",
            Duration = 3
        })
    end
})

Tabs.Combat:AddSection("Hitbox Expander")

Tabs.Combat:AddToggle("HitboxExpanderToggle", {
    Title = "Hitbox Expander",
    Description = "Expander.",
    Default = false,
    Callback = function(v)
        hitboxExpander.enabled = v
        if not v then restoreHitboxes() end
        Fluent:Notify({
            Title = "Hitbox Expander",
            Content = v and ("ON hitbox size: " .. hitboxExpander.size) or "OFF.",
            Duration = 3
        })
    end
})

Tabs.Combat:AddSlider("HitboxSizeSlider", {
    Title = "Hitbox Size",
    Description = "Sizes.",
    Default = 8,
    Min = 2,
    Max = 30,
    Rounding = 0,
    Callback = function(v)
        hitboxExpander.size = v
    end
})


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


local coinSortedList    = {}
local coinOptimizeCount = 0

local function optimizeCoinCache()
    local before = 0
    for _ in pairs(liveCoinCache) do before = before + 1 end

    local stale = 0
    for coin in pairs(liveCoinCache) do
        if not coin or not coin.Parent then
            liveCoinCache[coin] = nil
            stale = stale + 1
        end
    end

    local rescanned = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name == "Coin_Server" or v.Name == "SnowToken") then
            if v.Parent and not liveCoinCache[v] then
                liveCoinCache[v] = true
                rescanned = rescanned + 1
            end
        end
    end

    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myPos  = myRoot and myRoot.Position or Vector3.new(0, 0, 0)

    coinSortedList = {}
    for coin in pairs(liveCoinCache) do
        if coin and coin.Parent then
            table.insert(coinSortedList, {
                coin = coin,
                dist = (coin.Position - myPos).Magnitude
            })
        end
    end
    table.sort(coinSortedList, function(a, b) return a.dist < b.dist end)

    AutoCoinOperator = false
    CoinFound        = false
    CurrentTarget    = nil

    coinOptimizeCount = coinOptimizeCount + 1
    local after = 0
    for _ in pairs(liveCoinCache) do after = after + 1 end

    return before, after, stale, rescanned
end

state.roleCallbacks["CoinCacheOptimizer"] = function()
    task.spawn(function()
        task.wait(1.0)
        optimizeCoinCache()
    end)
end

Tabs.Farming:AddSection("Coin Optimizer")

Tabs.Farming:AddParagraph({
    Title = "ℹ️ Coin Optimizer",
    Content = "Optimize Coins!",
})

Tabs.Farming:AddButton({
    Title = "⚡ Optimize Coins",
    Description = "Optimizr",
    Callback = function()
        local before, after, stale, rescanned = optimizeCoinCache()
        Fluent:Notify({
            Title = "⚡ Coin Optimizer",
            Content = string.format(
                "Cache: %d → %d coins | Pruned: %d stale | Found: +%d new | Coin Optimizer | Run #%d",
                before, after, stale, rescanned, coinOptimizeCount
            ),
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

 local gunPart
 if gunDrop:IsA("BasePart") then
 gunPart = gunDrop
 elseif gunDrop:IsA("Model") then
 gunPart = gunDrop.PrimaryPart or gunDrop:FindFirstChildWhichIsA("BasePart")
 end
 if not gunPart then return end

 if isMurdererNear(gunPart.Position) then return end

 local pickupCFrame = myRoot.CFrame * CFrame.new(0, -2, 0)

 if gunDrop:IsA("Model") and gunDrop.PrimaryPart then
 gunDrop:SetPrimaryPartCFrame(pickupCFrame)
 else
 gunPart.CFrame = pickupCFrame
 end

 firetouchinterest(myRoot, gunPart, 0)
 task.wait(0.05)
 firetouchinterest(myRoot, gunPart, 1)
end


RunService.Heartbeat:Connect(function()
 if state.autoGetGunDropEnabled then
 collectGunDrop()
 end
end)


local DiscordSection = Tabs.Discord:AddSection("Discord Community")

Tabs.Discord:AddParagraph({
 Title = "Join Our Community",
 Content = "Join our Discord server and help us improve by suggesting new features for our script!"
})

local DiscordButton = Tabs.Discord:AddButton({
 Title = "Click to Copy Discord Invite",
 Name = "JoinDiscordButton",
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

local GrabGunGui    = Instance.new("ScreenGui")
local GrabGunFrame  = Instance.new("TextButton")
local GrabGunCorner = Instance.new("UICorner")
local GrabGunStroke = Instance.new("UIStroke")

GrabGunGui.Name            = "GrabGunGui"
GrabGunGui.ResetOnSpawn    = false
GrabGunGui.DisplayOrder    = 12
GrabGunGui.Parent          = game.CoreGui

GrabGunFrame.Name                    = "GrabGunFrame"
GrabGunFrame.Size                    = UDim2.new(0, 60, 0, 60)
GrabGunFrame.Position                = UDim2.new(0.01, 0, 0.45, 0)
GrabGunFrame.BackgroundColor3        = Color3.fromRGB(0, 120, 200)
GrabGunFrame.BackgroundTransparency  = 0.55
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

GrabGunCorner.CornerRadius = UDim.new(1, 0)
GrabGunCorner.Parent       = GrabGunFrame

GrabGunStroke.Color        = Color3.fromRGB(0, 200, 255)
GrabGunStroke.Thickness    = 1.5
GrabGunStroke.Transparency = 0.40
GrabGunStroke.Parent       = GrabGunFrame

local GrabGunAspect = Instance.new("UIAspectRatioConstraint")
GrabGunAspect.AspectRatio = 1
GrabGunAspect.Parent = GrabGunFrame

GrabGunFrame.MouseButton1Click:Connect(function()
    manualGrabGun()
    GrabGunFrame.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
    task.wait(0.18)
    GrabGunFrame.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
end)

local gunDropIndicator = Instance.new("Frame")
gunDropIndicator.Size             = UDim2.new(0, 8, 0, 8)
gunDropIndicator.Position         = UDim2.new(1, -10, 0, 2)
gunDropIndicator.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
gunDropIndicator.BorderSizePixel  = 0
gunDropIndicator.Parent           = GrabGunFrame
local GunDotCorner = Instance.new("UICorner")
GunDotCorner.CornerRadius = UDim.new(1, 0)
GunDotCorner.Parent = gunDropIndicator

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


Tabs.World:AddSection("Gun Drop")

Tabs.World:AddParagraph({
    Title = "Gun Drop Tools",
    Content = "Grabs Gun."
})

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

Tabs.World:AddToggle("BindGrabGunToggle", {
    Title = "Show Grab Gun Button (Draggable)",
    Description = "Show",
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

Tabs.World:AddButton({
    Title = "Grab Gun Now",
    Name = "ManualGrabGunBtn",
    Callback = function()
        manualGrabGun()
    end
})

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
            Fluent:Notify({ Title = "Noclip", Content = "Noclip ON.", Duration = 3 })
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

Tabs.World:AddSection("Murderer Dodge")

Tabs.World:AddToggle("AutoDodgeMurdererToggle", {
    Title = "Auto Dodge Murderer",
    Description = "When the murderer get near, instantly teleports you away.",
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
    Description = "Dodge.",
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

Tabs.World:AddSection("World Utilities")

Tabs.World:AddToggle("XRayToggle", {
    Title = "X-Ray",
    Description = "X ray",
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
local FLING_THRESHOLD = 80

local antiVoid = {
    enabled     = false,
    safePos     = nil,
    VOID_Y      = -100,
    SAFE_Y      = -50
}

local godMode = { enabled = false }

RunService.Heartbeat:Connect(function()
    local char   = LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")

    if godMode.enabled and char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then hum.Health = hum.MaxHealth end
    end

    if hitboxExpander.enabled then applyHitboxes() end

    if antiFling.enabled and myRoot then
        pcall(function()
            local vel = myRoot.AssemblyLinearVelocity
            if vel.Magnitude > FLING_THRESHOLD then
                myRoot.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end

    if antiVoid.enabled and myRoot then
        local pos = myRoot.Position
        if pos.Y > antiVoid.SAFE_Y then
            antiVoid.safePos = myRoot.CFrame
        elseif pos.Y < antiVoid.VOID_Y then
            myRoot.CFrame = antiVoid.safePos or CFrame.new(0, 10, 0)
        end
    end
end)


Tabs.World:AddSection("Anti-Fling")

Tabs.World:AddToggle("AntiFlingToggle", {
    Title = "Anti-Fling",
    Description = "antifling " .. FLING_THRESHOLD .. "anti .",
    Default = false,
    Callback = function(v)
        antiFling.enabled = v
        Fluent:Notify({
            Title = "Anti-Fling",
            Content = v and "ON " or "OFF.",
            Duration = 3
        })
    end
})


Tabs.World:AddSection("Anti-Void")

Tabs.World:AddToggle("AntiVoidToggle", {
    Title = "Anti-Void",
    Description = "If you fall below Y = " .. antiVoid.VOID_Y .. " studs, you're instantly teleported back to your last safe position.",
    Default = false,
    Callback = function(v)
        antiVoid.enabled = v
        if v then antiVoid.safePos = nil end
        Fluent:Notify({
            Title = "Anti-Void",
            Content = v and "ON — void detection active." or "OFF.",
            Duration = 3
        })
    end
})


Tabs.Premium:AddSection("Premium Silent Aim")

Tabs.Premium:AddParagraph({
    Title = "What Is Premium Silent Aim?",
    Content = "This Premium Is Free for Beta Testing!"
})

Tabs.Premium:AddParagraph({
    Title = "How To Use",
    Content = "Aim button Appears"
})

Tabs.Premium:AddToggle("PremiumSilentAimToggle", {
    Title = "Premium Silent Aim",
    Description = ".",
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
    Title = "Shoot Murderer",
    Name = "PremiumShootButton",
    Callback = function()
        if not premiumSilentAim.enabled then
            Fluent:Notify({
                Title = " Premium Aim",
                Content = "Enable 'Premium Silent Aim' toggle first!",
                Duration = 3
            })
            return
        end
        local murderer = GetMurderer()
        if murderer then
            doPremiumShoot(murderer)
        else
            Fluent:Notify({
                Title = " Premium Aim",
                Content = "No murderer detected yet.",
                Duration = 3
            })
        end
    end
})

local speedGlitch, sgDestroy
Tabs.Premium:AddSection("Speed Glitch")

Tabs.Premium:AddParagraph({
    Title = "DO NOTT USE THIS",
    Content = "DONT USE THIS"
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
    Title = "Glitch Speed",
    Description = "How fast you move during the glitch.",
    Default = 60,
    Min = 20,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        speedGlitch.speed = v
    end
})

Tabs.Premium:AddSlider("SpeedGlitchDecaySlider", {
    Title = "Brake Smoothness",
    Description = "Ho",
    Default = 350,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Callback = function(v)
        speedGlitch.decayTime = v / 1000
    end
})


speedGlitch = {
    enabled   = false,
    speed     = 60,
    decayTime = 0.35,
}

local sgLinVel  = nil
local sgAttach  = nil
local sgCurrent = Vector3.zero

local function sgBuild(root)
    if sgAttach and sgAttach.Parent then return true end
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

    if not sgBuild(root) then return end

    local moveDir = hum.MoveDirection

    local camRight = workspace.CurrentCamera.CFrame.RightVector
    local lateral  = (moveDir.Magnitude > 0.05)
                     and math.abs(moveDir:Dot(camRight))
                     or 0

    local isSideStrafing = lateral > 0.25 and moveDir.Magnitude > 0.1

    if isSideStrafing then
        local target = Vector3.new(
            moveDir.X * speedGlitch.speed,
            0,
            moveDir.Z * speedGlitch.speed
        )
        sgCurrent = sgCurrent:Lerp(target, math.min(dt * 12, 1))
    else
        local alpha = 1 - math.exp(-dt / math.max(speedGlitch.decayTime, 0.01))
        sgCurrent = sgCurrent:Lerp(Vector3.zero, math.min(alpha * 3.5, 1))
    end

    pcall(function()
        sgLinVel.VectorVelocity = sgCurrent
    end)
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("Mm2")
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

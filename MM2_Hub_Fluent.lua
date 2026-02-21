-- ============================================================
--   MURDER MYSTERY 2 HUB  |  Fluent UI
--   Shoot Remote: workspace[sheriffName].Gun.Shoot:FireServer(
--       [1] = CFrame(shooterPos, predictedTargetPos),
--       [2] = gun world CFrame
--   )
-- ============================================================

-- ─── Load Fluent ────────────────────────────────────────────
local Fluent           = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager      = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ─── Services ───────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer      = Players.LocalPlayer
local Camera           = Workspace.CurrentCamera

-- ─── State ──────────────────────────────────────────────────
local State = {
    MyRole         = "Unknown",
    MurdererPlayer = nil,
    SheriffPlayer  = nil,
    HeroPlayer     = nil,
    RoundActive    = false,
    RoundStart     = 0,
    -- Feature toggles
    ESPEnabled     = false,
    ChamsEnabled   = false,
    GunESPEnabled  = false,
    SilentAim      = false,
    -- Tuning
    Prediction     = 0.12,
    -- Colors
    MurdererColor  = Color3.fromRGB(255,  50,  50),
    SheriffColor   = Color3.fromRGB( 50, 150, 255),
    HeroColor      = Color3.fromRGB(255, 200,   0),
    InnocentColor  = Color3.fromRGB( 50, 255,  50),
    GunColor       = Color3.fromRGB(255, 220,   0),
}

local Options  -- assigned after Fluent window created

-- ═══════════════════════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════════════════════

local function getHRP(player)
    return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function isAlive(player)
    if not player or not player.Character then return false end
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getMurdererChance()
    local n = #Players:GetPlayers()
    if n < 3 then return 0 end
    return math.floor((1 / n) * 1000) / 10
end

local function getRoundTime()
    local rs = game:GetService("ReplicatedStorage")
    for _, v in ipairs({ Workspace:FindFirstChild("TimeLeft"), rs:FindFirstChild("TimeLeft"),
                         Workspace:FindFirstChild("RoundTimer"), rs:FindFirstChild("RoundTimer") }) do
        if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return math.max(0, math.floor(v.Value))
        end
    end
    return State.RoundActive and math.floor(tick() - State.RoundStart) or 0
end

local function isMurdererTool(name)
    return name and (name:find("knife") or name:find("murder") or name:find("blade") or name:find("saber"))
end

local function isGunTool(name)
    return name and (name:find("gun") or name:find("sheriff") or name:find("revolver") or name:find("pistol"))
end

local function getToolName(player)
    local char = player and player.Character
    if not char then return nil end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then return t.Name:lower(), t end
    end
end

local function scanRoles()
    State.MurdererPlayer = nil; State.SheriffPlayer = nil; State.HeroPlayer = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local n = getToolName(p)
        if isMurdererTool(n) then
            State.MurdererPlayer = p
        elseif isGunTool(n) then
            if not State.SheriffPlayer then State.SheriffPlayer = p else State.HeroPlayer = p end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  SHOOT REMOTE  (from octospy)
--
--  workspace[sheriffName].Gun.Shoot:FireServer(
--      [1] = CFrame.new(shooterPos, predictedMurdererPos),
--      [2] = gun.CFrame
--  )
-- ═══════════════════════════════════════════════════════════════

-- Find the player currently holding the gun
local function getGunHolder()
    local n = getToolName(LocalPlayer)
    if isGunTool(n) then return LocalPlayer end
    if State.SheriffPlayer and isAlive(State.SheriffPlayer) then return State.SheriffPlayer end
    if State.HeroPlayer    and isAlive(State.HeroPlayer)    then return State.HeroPlayer    end
    for _, p in ipairs(Players:GetPlayers()) do
        if isGunTool(getToolName(p)) then return p end
    end
end

-- Navigate: workspace[holderName].Gun.Shoot
local function getShootRemote()
    local holder = getGunHolder()
    if not holder then return nil, nil end

    local charModel = Workspace:FindFirstChild(holder.Name)
    if not charModel then return nil, nil end

    -- The Gun child (Tool named "Gun" or any Tool)
    local gun = charModel:FindFirstChild("Gun")
              or charModel:FindFirstChildWhichIsA("Tool")
    if not gun then return nil, nil end

    -- Shoot RemoteEvent
    local shoot = gun:FindFirstChild("Shoot")
    if not shoot then
        for _, v in ipairs(gun:GetDescendants()) do
            if v:IsA("RemoteEvent") then shoot = v; break end
        end
    end
    if not shoot then return nil, nil end

    -- Gun BasePart for arg[2]
    local gunPart = gun:FindFirstChildWhichIsA("BasePart")
                 or gun.PrimaryPart
                 or (gun:IsA("BasePart") and gun)

    return shoot, gunPart
end

-- Predicted position of the murderer
local function predictedMurdererPos()
    local m = State.MurdererPlayer
    if not m then scanRoles(); m = State.MurdererPlayer end
    if not m or not isAlive(m) then return nil end
    local hrp = getHRP(m)
    if not hrp then return nil end
    local vel = hrp.AssemblyLinearVelocity or Vector3.zero
    return hrp.Position + vel * State.Prediction
end

-- Build the exact two CFrame arguments
local function buildShootArgs(myHRP, gunPart)
    local targetPos = predictedMurdererPos()
    if not targetPos then return nil end
    -- arg[1]: from shooter position, oriented toward predicted murderer
    local arg1 = CFrame.new(myHRP.Position, targetPos)
    -- arg[2]: the gun's world CFrame (identity rotation when dropped, real CFrame when held)
    local arg2 = gunPart and gunPart.CFrame or CFrame.new(myHRP.Position)
    return arg1, arg2
end

-- One-click / button shoot
local function shootMurderer()
    local remote, gunPart = getShootRemote()
    if not remote then
        Fluent:Notify({ Title = "MM2 Hub", Content = "❌ Shoot remote not found!\nSomeone must have a gun equipped.", Duration = 5 })
        return
    end
    local myHRP = getHRP(LocalPlayer)
    if not myHRP then return end
    local arg1, arg2 = buildShootArgs(myHRP, gunPart)
    if not arg1 then
        Fluent:Notify({ Title = "MM2 Hub", Content = "❌ Murderer position unknown.", Duration = 4 })
        return
    end
    pcall(function() remote:FireServer(arg1, arg2) end)
    Fluent:Notify({
        Title   = "🎯 Shot Fired!",
        Content = "Fired at " .. (State.MurdererPlayer and State.MurdererPlayer.DisplayName or "murderer"),
        Duration = 3,
    })
end

-- ═══════════════════════════════════════════════════════════════
--  SILENT AIM  (hookmetamethod __namecall)
--
--  Intercepts every FireServer on a RemoteEvent named "Shoot"
--  whose parent is "Gun" inside a workspace character model.
--  Replaces arg[1] with our predicted aim CFrame,
--  arg[2] with the real gun CFrame — exact octospy match.
-- ═══════════════════════════════════════════════════════════════

local function setupSilentAim()
    if not hookmetamethod then
        warn("[MM2 Hub] hookmetamethod unavailable — Silent Aim requires a supported executor")
        return
    end

    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "FireServer"
        and State.SilentAim
        and self:IsA("RemoteEvent")
        and self.Name == "Shoot"
        then
            local gunModel  = self.Parent
            local charModel = gunModel and gunModel.Parent
            -- Confirm path: workspace[playerName].Gun.Shoot
            if gunModel and gunModel.Name == "Gun"
            and charModel and Workspace:FindFirstChild(charModel.Name) == charModel
            then
                local myHRP  = getHRP(LocalPlayer)
                if myHRP then
                    local gunPart  = gunModel:FindFirstChildWhichIsA("BasePart") or gunModel.PrimaryPart
                    local arg1, arg2 = buildShootArgs(myHRP, gunPart)
                    if arg1 then
                        return old(self, arg1, arg2)
                    end
                end
            end
        end
        return old(self, ...)
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  ESP  (Drawing API)
-- ═══════════════════════════════════════════════════════════════

local ESPStore = {}

local function w2s(pos)
    local sp, on, d = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), on, sp.Z
end

local function roleColor(player)
    if player == State.MurdererPlayer then return State.MurdererColor, "MURDERER" end
    if player == State.SheriffPlayer  then return State.SheriffColor,  "SHERIFF"  end
    if player == State.HeroPlayer     then return State.HeroColor,     "HERO"     end
    return State.InnocentColor, "INNOCENT"
end

local function newDrawing(type_, props)
    local d = Drawing.new(type_)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function ensureESP(player)
    if ESPStore[player] then return end
    ESPStore[player] = {
        box    = newDrawing("Square", { Filled=false, Thickness=1.5, Visible=false }),
        name   = newDrawing("Text",   { Size=13, Center=true, Outline=true, Font=Drawing.Fonts.UI, Visible=false }),
        dist   = newDrawing("Text",   { Size=11, Center=true, Outline=true, Font=Drawing.Fonts.UI, Visible=false }),
        tracer = newDrawing("Line",   { Thickness=1, Visible=false }),
    }
end

local function removeESP(player)
    if not ESPStore[player] then return end
    for _, v in pairs(ESPStore[player]) do pcall(v.Remove, v) end
    ESPStore[player] = nil
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not State.ESPEnabled then removeESP(player); continue end

        ensureESP(player)
        local e    = ESPStore[player]
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not hrp then
            for _, v in pairs(e) do pcall(function() v.Visible = false end) end
            continue
        end

        local rootSP, onScreen, depth = w2s(hrp.Position)
        local headSP = w2s(head and head.Position + Vector3.new(0,.6,0) or hrp.Position + Vector3.new(0,3,0))
        local feetSP = w2s(hrp.Position - Vector3.new(0,3,0))
        local dStuds = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
        local color, label = roleColor(player)

        if onScreen and depth > 0 then
            local h = math.abs(headSP.Y - feetSP.Y)
            local w = h * 0.45
            e.box.Position   = Vector2.new(rootSP.X - w/2, headSP.Y)
            e.box.Size       = Vector2.new(w, h);          e.box.Color    = color; e.box.Visible    = true
            e.name.Position  = Vector2.new(rootSP.X, headSP.Y - 15)
            e.name.Text      = "[" .. label .. "] " .. player.DisplayName
            e.name.Color     = color; e.name.Visible   = true
            e.dist.Position  = Vector2.new(rootSP.X, feetSP.Y + 2)
            e.dist.Text      = dStuds .. " studs"; e.dist.Color = color; e.dist.Visible = true
            e.tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            e.tracer.To      = rootSP; e.tracer.Color = color; e.tracer.Visible = true
        else
            for _, v in pairs(e) do pcall(function() v.Visible = false end) end
        end
    end
end

-- ─── Chams ──────────────────────────────────────────────────
local ChamStore = {}
local function updateChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char  = player.Character
        local color = roleColor(player)
        if not State.ChamsEnabled or not char then
            if ChamStore[player] then ChamStore[player]:Destroy(); ChamStore[player] = nil end
            continue
        end
        if not ChamStore[player] or not ChamStore[player].Parent then
            local sel = Instance.new("SelectionBox")
            sel.LineThickness = 0.05; sel.SurfaceTransparency = 0.75
            sel.Adornee = char; sel.Parent = char
            ChamStore[player] = sel
        end
        ChamStore[player].Color3 = color; ChamStore[player].SurfaceColor3 = color
    end
end

-- ─── Dropped Gun ESP ────────────────────────────────────────
local GunESPStore = {}
local function updateGunESP()
    local playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do playerNames[p.Name] = true end

    -- Stale cleanup
    for obj, d in pairs(GunESPStore) do
        if not obj or not obj.Parent then
            pcall(d.label.Remove, d.label); pcall(d.tracer.Remove, d.tracer)
            GunESPStore[obj] = nil
        end
    end

    if not State.GunESPEnabled then
        for _, d in pairs(GunESPStore) do
            pcall(function() d.label.Visible = false; d.tracer.Visible = false end)
        end
        return
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if playerNames[obj.Name] then continue end
        local n = obj.Name:lower()
        if obj:IsA("Tool") and isGunTool(n) then
            local part = obj:FindFirstChildWhichIsA("BasePart")
            if not part then continue end
            if not GunESPStore[obj] then
                GunESPStore[obj] = {
                    label  = newDrawing("Text", { Color=State.GunColor, Size=14, Center=true, Outline=true, Font=Drawing.Fonts.UI, Visible=false }),
                    tracer = newDrawing("Line", { Color=State.GunColor, Thickness=1.5, Visible=false }),
                }
            end
            local d = GunESPStore[obj]
            local sp, on, depth = w2s(part.Position)
            local dst = math.floor((Camera.CFrame.Position - part.Position).Magnitude)
            if on and depth > 0 then
                d.label.Position = Vector2.new(sp.X, sp.Y - 22)
                d.label.Text     = "GUN [" .. dst .. " studs]"
                d.label.Color    = State.GunColor; d.label.Visible = true
                d.tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                d.tracer.To      = sp; d.tracer.Color = State.GunColor; d.tracer.Visible = true
            else
                d.label.Visible  = false; d.tracer.Visible = false
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  ROLE WATCHERS
-- ═══════════════════════════════════════════════════════════════

local function notifyRole(role)
    if not Options or not Options.NotifyRole or not Options.NotifyRole.Value then return end
    local msgs = {
        Murderer = { "🔪 YOU ARE THE MURDERER", "Kill all innocents!\nChance was: " .. getMurdererChance() .. "%" },
        Sheriff  = { "🔫 YOU ARE THE SHERIFF",   "Shoot the murderer! Don't miss." },
        Hero     = { "🦸 YOU ARE THE HERO",       "The sheriff fell — avenge them!" },
        Innocent = { "😇 YOU ARE INNOCENT",       "Survive and collect coins." },
    }
    local m = msgs[role]
    if m then Fluent:Notify({ Title = m[1], Content = m[2], Duration = 8 }) end
end

local function watchChar(player, char)
    if not char then return end

    char.ChildAdded:Connect(function(child)
        if not child:IsA("Tool") then return end
        local n = child.Name:lower()

        if isMurdererTool(n) then
            State.MurdererPlayer = player
            if player == LocalPlayer then
                State.MyRole = "Murderer"
                notifyRole("Murderer")
            else
                if Options and Options.NotifyMurderer and Options.NotifyMurderer.Value then
                    Fluent:Notify({ Title = "🔪 Murderer Found!", Content = player.DisplayName .. " is the MURDERER!", Duration = 7 })
                end
            end
            if Options and Options.NotifyPerks and Options.NotifyPerks.Value then
                Fluent:Notify({ Title = "🗡️ Weapon", Content = "Weapon: " .. child.Name, Duration = 5 })
            end

        elseif isGunTool(n) then
            if player == LocalPlayer then
                if State.SheriffPlayer and State.SheriffPlayer ~= LocalPlayer then
                    State.HeroPlayer = LocalPlayer; State.MyRole = "Hero"; notifyRole("Hero")
                else
                    State.SheriffPlayer = LocalPlayer; State.MyRole = "Sheriff"; notifyRole("Sheriff")
                end
            else
                if not State.SheriffPlayer or State.SheriffPlayer == player then
                    State.SheriffPlayer = player
                    if Options and Options.NotifyMurderer and Options.NotifyMurderer.Value then
                        Fluent:Notify({ Title = "🔫 Sheriff Found", Content = player.DisplayName .. " is the Sheriff.", Duration = 5 })
                    end
                else
                    State.HeroPlayer = player
                    if Options and Options.NotifyMurderer and Options.NotifyMurderer.Value then
                        Fluent:Notify({ Title = "🦸 Hero Appeared!", Content = player.DisplayName .. " picked up the gun!", Duration = 6 })
                    end
                end
            end
        end
    end)

    char.ChildRemoved:Connect(function(child)
        if not child:IsA("Tool") then return end
        if isGunTool(child.Name:lower()) then
            if player == State.SheriffPlayer or player == State.HeroPlayer then
                if Options and Options.NotifyGunDrop and Options.NotifyGunDrop.Value then
                    Fluent:Notify({ Title = "🔫 Gun Dropped!", Content = player.DisplayName .. " dropped the gun!", Duration = 7 })
                end
            end
        end
    end)
end

local function initWatcher(player)
    if player.Character then task.spawn(watchChar, player, player.Character) end
    player.CharacterAdded:Connect(function(char)
        if player == LocalPlayer then
            State.MurdererPlayer = nil; State.SheriffPlayer = nil
            State.HeroPlayer = nil; State.MyRole = "Innocent"
            State.RoundActive = true; State.RoundStart = tick()
            task.delay(3, function()
                if State.MyRole == "Innocent" then notifyRole("Innocent") end
            end)
        end
        task.wait()
        watchChar(player, char)
    end)
end

local function initAllPlayers()
    for _, p in ipairs(Players:GetPlayers()) do initWatcher(p) end
    Players.PlayerAdded:Connect(initWatcher)
    Players.PlayerRemoving:Connect(function(p)
        removeESP(p)
        if ChamStore[p] then ChamStore[p]:Destroy(); ChamStore[p] = nil end
        if State.MurdererPlayer == p then State.MurdererPlayer = nil end
        if State.SheriffPlayer  == p then State.SheriffPlayer  = nil end
        if State.HeroPlayer     == p then State.HeroPlayer     = nil end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  UI
-- ═══════════════════════════════════════════════════════════════

local Window = Fluent:CreateWindow({
    Title       = "MM2 Hub",
    SubTitle    = "Murder Mystery 2",
    TabWidth    = 155,
    Size        = UDim2.fromOffset(620, 500),
    Acrylic     = true,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift,
})

local Tabs = {
    Main     = Window:AddTab({ Title = "Main",     Icon = "home"      }),
    ESP      = Window:AddTab({ Title = "ESP",       Icon = "eye"       }),
    Aimbot   = Window:AddTab({ Title = "Aimbot",    Icon = "crosshair" }),
    Notify   = Window:AddTab({ Title = "Notify",    Icon = "bell"      }),
    Settings = Window:AddTab({ Title = "Settings",  Icon = "settings"  }),
}

Options = Fluent.Options

-- ─── MAIN TAB ───────────────────────────────────────────────

Tabs.Main:AddParagraph({
    Title   = "MM2 Hub — Active",
    Content = "Press RightShift to toggle UI.",
})

local InfoPara = Tabs.Main:AddParagraph({ Title = "Round Info", Content = "Scanning..." })

local function refreshInfo()
    scanRoles()
    InfoPara.Title   = "Round Info"
    InfoPara.Content = string.format(
        "Players: %d  |  Murderer Chance: %.1f%%\n" ..
        "Murderer: %s\nSheriff: %s  |  Hero: %s\n" ..
        "Your Role: %s  |  Round Time: %ds",
        #Players:GetPlayers(), getMurdererChance(),
        State.MurdererPlayer and State.MurdererPlayer.DisplayName or "Unknown",
        State.SheriffPlayer  and State.SheriffPlayer.DisplayName  or "Unknown",
        State.HeroPlayer     and State.HeroPlayer.DisplayName     or "None",
        State.MyRole, getRoundTime()
    )
end

Tabs.Main:AddButton({ Title = "🔍 Refresh Info", Description = "Re-scan roles and update panel", Callback = function()
    refreshInfo()
    Fluent:Notify({ Title = "Refreshed", Content = "Murderer Chance: " .. getMurdererChance() .. "%", Duration = 4 })
end })

Tabs.Main:AddButton({ Title = "🎯 Shoot Murderer", Description = "Fire at murderer using the exact workspace remote path", Callback = shootMurderer })

-- ─── ESP TAB ────────────────────────────────────────────────

Tabs.ESP:AddToggle("ESPEnabled",   { Title = "Player ESP",       Description = "Box, name, distance, tracer — color-coded per role", Default = false }):OnChanged(function()
    State.ESPEnabled = Options.ESPEnabled.Value
    if not State.ESPEnabled then for p in pairs(ESPStore) do removeESP(p) end end
end)

Tabs.ESP:AddToggle("ChamsEnabled", { Title = "Chams / Outline",  Description = "SelectionBox highlights visible through walls",      Default = false }):OnChanged(function()
    State.ChamsEnabled = Options.ChamsEnabled.Value
    if not State.ChamsEnabled then for _, h in pairs(ChamStore) do h:Destroy() end; ChamStore = {} end
end)

Tabs.ESP:AddToggle("GunESPEnabled",{ Title = "Dropped Gun ESP",  Description = "Tracer + label on any gun lying on the ground",      Default = false }):OnChanged(function()
    State.GunESPEnabled = Options.GunESPEnabled.Value
end)

Tabs.ESP:AddColorpicker("MurdererColor", { Title = "Murderer Color", Default = Color3.fromRGB(255, 50,  50)  }):OnChanged(function() State.MurdererColor = Options.MurdererColor.Value end)
Tabs.ESP:AddColorpicker("SheriffColor",  { Title = "Sheriff Color",  Default = Color3.fromRGB(50,  150, 255) }):OnChanged(function() State.SheriffColor  = Options.SheriffColor.Value  end)
Tabs.ESP:AddColorpicker("HeroColor",     { Title = "Hero Color",     Default = Color3.fromRGB(255, 200, 0)   }):OnChanged(function() State.HeroColor     = Options.HeroColor.Value     end)
Tabs.ESP:AddColorpicker("InnocentColor", { Title = "Innocent Color", Default = Color3.fromRGB(50,  255, 50)  }):OnChanged(function() State.InnocentColor = Options.InnocentColor.Value end)
Tabs.ESP:AddColorpicker("GunColor",      { Title = "Gun ESP Color",  Default = Color3.fromRGB(255, 220, 0)   }):OnChanged(function() State.GunColor      = Options.GunColor.Value      end)

-- ─── AIMBOT TAB ─────────────────────────────────────────────

Tabs.Aimbot:AddParagraph({
    Title   = "How Silent Aim Works",
    Content =
        "Hooks __namecall. When FireServer is called on\n" ..
        "workspace[playerName].Gun.Shoot, the two CFrame\n" ..
        "args are replaced:\n\n" ..
        "  arg[1] = CFrame(myPos → murdererPredicted)\n" ..
        "  arg[2] = gun.CFrame\n\n" ..
        "Matches the exact structure captured by octospy.\n" ..
        "Requires hookmetamethod (Synapse / Fluxus / KRNL).",
})

Tabs.Aimbot:AddToggle("SilentAim", {
    Title       = "Silent Aim",
    Description = "Every gun shot auto-redirects to the murderer — no click change needed",
    Default     = false,
}):OnChanged(function() State.SilentAim = Options.SilentAim.Value end)

Tabs.Aimbot:AddSlider("Prediction", {
    Title       = "Prediction Factor",
    Description = "Seconds to lead the murderer's velocity (0.12 is a good default)",
    Default     = 0.12,
    Min         = 0,
    Max         = 0.5,
    Rounding    = 3,
    Callback    = function(v) State.Prediction = v end,
})

Tabs.Aimbot:AddButton({
    Title       = "🎯 Shoot Murderer (Manual)",
    Description = "One-click fire using workspace[sheriffName].Gun.Shoot path",
    Callback    = shootMurderer,
})

-- ─── NOTIFY TAB ─────────────────────────────────────────────

Tabs.Notify:AddToggle("NotifyRole",     { Title = "Role Notifier",          Description = "Alert your own role at round start",                  Default = true  })
Tabs.Notify:AddToggle("NotifyMurderer", { Title = "Murderer / Sheriff Alert",Description = "Notify when knife / gun detected on another player",  Default = true  })
Tabs.Notify:AddToggle("NotifyGunDrop",  { Title = "Gun Drop Alert",          Description = "Alert when sheriff or hero drops their gun",          Default = true  })
Tabs.Notify:AddToggle("NotifyPerks",    { Title = "Weapon / Perk Info",      Description = "Show the murderer's weapon name when equipped",       Default = false })
Tabs.Notify:AddToggle("NotifyTimer",    { Title = "Round Timer Alerts",      Description = "Notify at 60s / 30s / 10s remaining",                Default = true  })

-- ─── SETTINGS TAB ───────────────────────────────────────────

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("MM2Hub")
SaveManager:SetFolder("MM2Hub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- ═══════════════════════════════════════════════════════════════
--  LOOPS
-- ═══════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
    pcall(updateESP)
    pcall(updateChams)
    pcall(updateGunESP)
end)

local lastRefresh, lastTimerTick = 0, {}
RunService.Heartbeat:Connect(function()
    local now = tick()

    -- Info panel refresh every 3s
    if now - lastRefresh >= 3 then
        lastRefresh = now
        pcall(refreshInfo)

        -- Timer notifications
        if Options.NotifyTimer and Options.NotifyTimer.Value then
            local t = getRoundTime()
            for _, mark in ipairs({ 60, 30, 10 }) do
                if t == mark and now - (lastTimerTick[mark] or 0) > 5 then
                    lastTimerTick[mark] = now
                    Fluent:Notify({ Title = "⏱️ Timer", Content = mark .. "s remaining!", Duration = 4 })
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════════════════════

initAllPlayers()
scanRoles()
pcall(setupSilentAim)

Window:SelectTab(1)

Fluent:Notify({
    Title   = "✅ MM2 Hub Loaded",
    Content = "Murderer Chance: " .. getMurdererChance() .. "%\nRightShift to toggle UI.",
    Duration = 8,
})

SaveManager:LoadAutoloadConfig()

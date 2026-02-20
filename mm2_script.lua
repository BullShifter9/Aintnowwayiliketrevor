-- ====================================================
-- MM2 Script | Fluent UI | Mobile & PC Compatible
-- Features: ESP, Chams, Outline, Round Timer, 
--           Get Chance, Notify Role, Notify Perk,
--           Grab Gun, Break Gun, Steal Gun,
--           Sheriff Silent Aim (Dynamic/Regular/Seismic),
--           Sharp Shooter, Murderer Silent Aim,
--           Knife Aura, Kill All, Kill Sheriff
-- ====================================================

-- Services
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui    = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse  = LP:GetMouse()
local isMobile = UserInputService.TouchEnabled

-- ============ LOAD FLUENT UI ============
-- Primary URL: official Fluent releases build (confirmed correct from dawid-scripts/Fluent Example.lua)
-- Fallback URL: Fluent Reborn mirror in case GitHub releases is down
local Fluent
local ok_fluent, err_fluent = pcall(function()
    Fluent = loadstring(game:HttpGet(
        "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
    ))()
end)
if not ok_fluent or not Fluent then
    warn("[MM2Script] Primary Fluent load failed (" .. tostring(err_fluent) .. "), trying fallback...")
    local ok2, err2 = pcall(function()
        Fluent = loadstring(game:HttpGet("https://twix.cyou/Fluent.txt"))()
    end)
    if not ok2 or not Fluent then
        warn("[MM2Script] Both Fluent URLs failed: " .. tostring(err2))
        return
    end
end

-- ============ STATE ============
local State = {
    -- Roles
    Roles      = {},   -- { [playerName] = {Role, Effect, Dead, Killed} }
    Murderer   = "",
    Sheriff    = "",
    MyRole     = "Innocent",
    -- Visuals
    ESP        = false,
    ESPOutline = false,
    ESPCham    = false,
    -- Game
    ShowTimer       = false,
    NotifyRole      = false,
    AutoNotifyPerk  = false,
    -- Combat - Sheriff
    SheriffSilentAim   = false,
    SharpShooter       = false,
    SilentAimMethod    = "Dynamic",
    ShootingMurderer   = false,
    -- Combat - Murderer
    MurdSilentAim      = false,
    MurdTarget         = "Closest",
    KnifeAura          = false,
    KnifeRange         = 20,
    -- Gun
    AutoGrabGun = false,
    Grabbing    = false,
    AutoBreakGun = false,
    -- AntiKick
    AntiKick = false,
}

-- ============ TASKS ============
local Tasks = {}
local function MakeTask(id, signal, cb)
    if Tasks[id] then pcall(function() Tasks[id]:Disconnect() end) end
    Tasks[id] = signal:Connect(cb)
end
local function RemoveTask(id)
    if Tasks[id] then
        pcall(function() Tasks[id]:Disconnect() end)
        Tasks[id] = nil
    end
end

-- ============ UTILITIES ============
local function Notify(msg, dur)
    pcall(function()
        Fluent:Notify({ Title = "MM2 Script", Content = tostring(msg), Duration = dur or 5 })
    end)
end

local function GetRoot(player)
    if player and player.Character then
        return player.Character:FindFirstChild("HumanoidRootPart")
            or player.Character:FindFirstChild("PrimaryPart")
    end
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local data = State.Roles[player.Name]
    if data then
        return not data.Dead and not data.Killed
    end
    -- fallback: check humanoid
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function RoleColor(player)
    if not player then return Color3.fromRGB(120,200,120) end
    local data = State.Roles[player.Name]
    if not data then return Color3.fromRGB(120,200,120) end
    local role = data.Role or "Innocent"
    if role == "Murderer"                 then return Color3.fromRGB(255, 30,  30)
    elseif role == "Sheriff" or role == "Hero" then return Color3.fromRGB(30,  80,  255)
    elseif role == "Innocent"             then return Color3.fromRGB(30,  200, 30)
    else                                       return Color3.fromRGB(120, 200, 120) end
end

local function MoveTo(cf)
    local root = GetRoot(LP)
    if root then
        root.CFrame = cf
        if LP.Character and LP.Character.PrimaryPart then
            LP.Character:SetPrimaryPartCFrame(cf)
        end
    end
end

local function GetKnife()
    for _, t in pairs(LP.Character and LP.Character:GetChildren() or {}) do
        if t.Name == "Knife" and t:IsA("Tool") then return t end
    end
    for _, t in pairs(LP.Backpack:GetChildren()) do
        if t.Name == "Knife" and t:IsA("Tool") then
            t.Parent = LP.Character
            return t
        end
    end
end

local function GetGun()
    for _, t in pairs(LP.Character and LP.Character:GetChildren() or {}) do
        if t.Name == "Gun" and t:IsA("Tool") then return t, false end
    end
    for _, t in pairs(LP.Backpack:GetChildren()) do
        if t.Name == "Gun" and t:IsA("Tool") then
            t.Parent = LP.Character
            return t, true
        end
    end
    return nil, false
end

-- Returns the sheriff's gun tool (not equipping to our char)
local function GetSheriffGun()
    local sheriff = Players:FindFirstChild(State.Sheriff)
    if not sheriff then return end
    for _, t in pairs(sheriff.Character and sheriff.Character:GetChildren() or {}) do
        if t.Name == "Gun" and t:IsA("Tool") then return t end
    end
    for _, t in pairs(sheriff.Backpack:GetChildren()) do
        if t.Name == "Gun" and t:IsA("Tool") then return t end
    end
end

local function GetClosestPlayer()
    local closest, best = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local ok, d = pcall(function()
                return (GetRoot(p).Position - GetRoot(LP).Position).Magnitude
            end)
            if ok and d < best then closest = p; best = d end
        end
    end
    return closest
end

local function GetClosestToMouse()
    local closest, best = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local ok, d = pcall(function()
                return (GetRoot(p).Position - Mouse.Hit.Position).Magnitude
            end)
            if ok and d < best then closest = p; best = d end
        end
    end
    return closest
end

local function KillPlayer(target, knife)
    local root = GetRoot(target)
    if not root or not knife then return end
    pcall(function() knife.Stab:FireServer("Down") end)
    task.wait()
    pcall(function()
        firetouchinterest(root, knife.Handle, 0)
        firetouchinterest(root, knife.Handle, 1)
    end)
end

-- ============ REMOTES (safe fetch) ============
local function WFC(parent, name, timeout)
    timeout = timeout or 5
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout)
    end)
    return ok and result or nil
end

local RS_Remotes = WFC(ReplicatedStorage, "Remotes", 10)
local RS_UpdatePD = WFC(ReplicatedStorage, "UpdatePlayerData", 10)

local R_Extras   = RS_Remotes and WFC(RS_Remotes, "Extras", 5)
local R_Gameplay = RS_Remotes and WFC(RS_Remotes, "Gameplay", 5)

local Remote_GetTimer  = R_Extras   and WFC(R_Extras, "GetTimer", 5)
local Remote_GetChance = R_Extras   and WFC(R_Extras, "GetChance", 5)
local Remote_GetData2  = R_Extras   and WFC(R_Extras, "GetData2", 5)
local Remote_Fade      = R_Gameplay and WFC(R_Gameplay, "Fade", 5)
local Remote_RoundEnd  = R_Gameplay and WFC(R_Gameplay, "RoundEndFade", 5)

-- ============ ESP SYSTEM ============
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "MM2Script_ESP"
ESPFolder.Parent = workspace

-- Name ESP (Drawing)
local NameESPConns = {}
local NameESPObjs  = {}

local function CreateNameESP(player)
    if NameESPObjs[player.Name] then return end
    local txt = Drawing.new("Text")
    txt.Text    = player.Name
    txt.Size    = 16
    txt.Font    = 3
    txt.Outline = true
    txt.OutlineColor = Color3.fromRGB(0,0,0)
    txt.Center  = true
    txt.Transparency = 1
    txt.Visible = false
    NameESPObjs[player.Name] = txt

    NameESPConns[player.Name] = RunService.RenderStepped:Connect(function()
        if not State.ESP then txt.Visible = false; return end
        if player and player.Character then
            local root = GetRoot(player)
            if root then
                local pos, vis = Camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, 3.5, 0)).Position)
                local data = State.Roles[player.Name]
                local role = data and data.Role or ""
                txt.Text    = player.Name .. (role ~= "" and ("\n["..role.."]") or "")
                txt.Color   = RoleColor(player)
                txt.Position = Vector2.new(pos.X, pos.Y - 18)
                txt.Visible  = vis
            else
                txt.Visible = false
            end
        else
            txt.Visible = false
        end
    end)
end

local function RemoveNameESP(player)
    if NameESPConns[player.Name] then
        NameESPConns[player.Name]:Disconnect()
        NameESPConns[player.Name] = nil
    end
    if NameESPObjs[player.Name] then
        NameESPObjs[player.Name]:Remove()
        NameESPObjs[player.Name] = nil
    end
end

-- Box Outline ESP (Drawing Lines)
local BoxESPConns = {}
local BoxESPObjs  = {}

local function CreateBoxESP(player)
    if BoxESPObjs[player.Name] then return end
    local lines = {}
    for i = 1, 4 do
        local ln = Drawing.new("Line")
        ln.Thickness = 1.5
        ln.Transparency = 1
        ln.Visible = false
        lines[i] = ln
    end
    BoxESPObjs[player.Name] = lines

    BoxESPConns[player.Name] = RunService.RenderStepped:Connect(function()
        if not State.ESPOutline then
            for _, l in ipairs(lines) do l.Visible = false end
            return
        end
        if player and player.Character then
            local root = GetRoot(player)
            if root then
                local cf   = CFrame.lookAt(root.Position, Camera.CFrame.Position)
                local sx, sy = 2.5, 4.0
                local tl, tlv = Camera:WorldToViewportPoint((cf * CFrame.new(-sx,  sy, 0)).Position)
                local tr, _   = Camera:WorldToViewportPoint((cf * CFrame.new( sx,  sy, 0)).Position)
                local bl, _   = Camera:WorldToViewportPoint((cf * CFrame.new(-sx, -sy, 0)).Position)
                local br, _   = Camera:WorldToViewportPoint((cf * CFrame.new( sx, -sy, 0)).Position)
                local col = RoleColor(player)
                -- Top, Bottom, Left, Right
                lines[1].From = Vector2.new(tl.X,tl.Y); lines[1].To = Vector2.new(tr.X,tr.Y)
                lines[2].From = Vector2.new(bl.X,bl.Y); lines[2].To = Vector2.new(br.X,br.Y)
                lines[3].From = Vector2.new(tl.X,tl.Y); lines[3].To = Vector2.new(bl.X,bl.Y)
                lines[4].From = Vector2.new(tr.X,tr.Y); lines[4].To = Vector2.new(br.X,br.Y)
                for _, l in ipairs(lines) do l.Color = col; l.Visible = tlv end
            else
                for _, l in ipairs(lines) do l.Visible = false end
            end
        else
            for _, l in ipairs(lines) do l.Visible = false end
        end
    end)
end

local function RemoveBoxESP(player)
    if BoxESPConns[player.Name] then
        BoxESPConns[player.Name]:Disconnect()
        BoxESPConns[player.Name] = nil
    end
    if BoxESPObjs[player.Name] then
        for _, l in ipairs(BoxESPObjs[player.Name]) do pcall(function() l:Remove() end) end
        BoxESPObjs[player.Name] = nil
    end
end

-- Chams (BoxHandleAdornment)
local function CreateCham(player)
    if not player.Character then return end
    local folder = ESPFolder:FindFirstChild(player.Name)
    if folder then folder:Destroy() end
    folder = Instance.new("Folder")
    folder.Name = player.Name
    folder.Parent = ESPFolder
    for _, part in pairs(player.Character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local adorn = Instance.new("BoxHandleAdornment")
            adorn.Name   = part.Name
            adorn.Parent = folder
            adorn.Adornee = part
            adorn.Size   = part.Size + Vector3.new(0.05, 0.05, 0.05)
            adorn.Color3 = RoleColor(player)
            adorn.AlwaysOnTop = true
            adorn.Transparency = 0.5
            adorn.ZIndex = 5
        end
    end
end

local function RemoveCham(player)
    local folder = ESPFolder:FindFirstChild(player.Name)
    if folder then folder:Destroy() end
end

local function UpdateChamColors()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local folder = ESPFolder:FindFirstChild(p.Name)
            if folder then
                for _, adorn in pairs(folder:GetChildren()) do
                    if adorn:IsA("BoxHandleAdornment") then
                        adorn.Color3 = RoleColor(p)
                    end
                end
            end
        end
    end
end

-- ESP for players joining/leaving
Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    p.CharacterAdded:Connect(function()
        task.wait(1.5)
        if State.ESP        then CreateNameESP(p) end
        if State.ESPOutline then CreateBoxESP(p)  end
        if State.ESPCham    then CreateCham(p)    end
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    RemoveNameESP(p)
    RemoveBoxESP(p)
    RemoveCham(p)
end)

-- ============ ROUND TIMER ============
local TimerLabel = Instance.new("ScreenGui")
TimerLabel.Name = "MM2ScriptTimer"
TimerLabel.ResetOnSpawn = false
TimerLabel.Parent = LP.PlayerGui

local TimerFrame = Instance.new("Frame")
TimerFrame.Parent = TimerLabel
TimerFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
TimerFrame.BackgroundTransparency = 0.4
TimerFrame.BorderSizePixel = 0
TimerFrame.AnchorPoint = Vector2.new(0.5, 0)
TimerFrame.Position = UDim2.new(0.5, 0, 0.03, 0)
TimerFrame.Size = UDim2.new(0, 120, 0, 36)
TimerFrame.Visible = false

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = TimerFrame

local TimerText = Instance.new("TextLabel")
TimerText.Parent = TimerFrame
TimerText.BackgroundTransparency = 1
TimerText.Size = UDim2.new(1, 0, 1, 0)
TimerText.Font = Enum.Font.GothamBold
TimerText.TextSize = 18
TimerText.TextColor3 = Color3.fromRGB(255,255,255)
TimerText.Text = "0s"
TimerText.TextStrokeTransparency = 0.5
TimerText.ZIndex = 10

-- Timer coroutine
coroutine.wrap(function()
    while true do
        task.wait(1)
        if State.ShowTimer and Remote_GetTimer then
            local ok, t = pcall(function()
                return Remote_GetTimer:InvokeServer()
            end)
            if ok and type(t) == "number" and t > 0 then
                local mins = math.floor(t / 60)
                local secs = math.floor(t % 60)
                TimerText.Text = (mins > 0 and (mins.."m ") or "") .. secs .. "s"
                TimerText.TextColor3 = (t <= 30) and Color3.fromRGB(255,80,80) or Color3.fromRGB(255,255,255)
                TimerFrame.Visible = true
            else
                TimerFrame.Visible = false
            end
        else
            TimerFrame.Visible = false
        end
    end
end)()

-- ============ ROLE EVENT (Fade) ============
if Remote_Fade then
    Remote_Fade.OnClientEvent:Connect(function(roleData)
        if type(roleData) ~= "table" then return end
        State.Roles    = roleData
        State.Murderer = ""
        State.Sheriff  = ""

        for name, data in pairs(roleData) do
            if type(data) == "table" then
                if data.Role == "Murderer" then
                    State.Murderer = name
                elseif data.Role == "Sheriff" or data.Role == "Hero" then
                    State.Sheriff = name
                end
            end
        end

        local myData = roleData[LP.Name]
        State.MyRole = myData and myData.Role or "Innocent"

        -- Role notification
        if State.NotifyRole then
            task.wait(0.3)
            local msg = "Your Role: " .. State.MyRole
            if State.Murderer ~= "" then
                msg = msg .. "\nMurderer: " .. State.Murderer
            end
            if State.Sheriff ~= "" then
                msg = msg .. "\nSheriff: " .. State.Sheriff
            end
            Notify(msg, 8)
        end

        -- Auto notify murderer perk
        if State.AutoNotifyPerk and State.Murderer ~= "" then
            local mdata = roleData[State.Murderer]
            if mdata and mdata.Effect then
                Notify("Murderer Perk: " .. tostring(mdata.Effect), 6)
            end
        end

        -- Update cham colors since roles changed
        UpdateChamColors()
    end)
end

-- Round end reset
if Remote_RoundEnd then
    Remote_RoundEnd.OnClientEvent:Connect(function()
        State.Roles    = {}
        State.Murderer = ""
        State.Sheriff  = ""
        State.MyRole   = "Innocent"
    end)
end

-- ============ SILENT AIM HOOK ============
-- Hooks __namecall to intercept ShootGun (Sheriff) and Throw (Murderer knife)
local HookRef = nil
pcall(function()
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    HookRef = oldNC
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if checkcaller() then
            return oldNC(self, ...)
        end

        local args = { ... }

        -- Sheriff Silent Aim: intercept Gun's ShootGun InvokeServer
        if method == "InvokeServer" then
            if self.Name == "ShootGun" and self.Parent and self.Parent.Name == "KnifeServer" then
                if State.SheriffSilentAim and not State.ShootingMurderer then
                    local murderer = Players:FindFirstChild(State.Murderer)
                    if murderer and murderer.Character then
                        local targetPart = State.SharpShooter
                            and (murderer.Character.PrimaryPart or murderer.Character:FindFirstChild("HumanoidRootPart"))
                            or murderer.Character:FindFirstChild("HumanoidRootPart")
                        if targetPart then
                            args[1] = 0 -- distance override
                            local acc = State.SilentAimMethod
                            if acc == "Seismic" then
                                local vel = targetPart.AssemblyLinearVelocity
                                if vel.Magnitude < 0.1 then
                                    args[2] = targetPart.Position
                                else
                                    local v = (vel.Unit * targetPart.Velocity.Magnitude) / 16.5
                                    local vy = math.clamp(v.Y, -2, 2.65)
                                    args[2] = targetPart.Position + Vector3.new(v.X, vy, v.Z / 1.25)
                                end
                            elseif acc == "Dynamic" then
                                local hum = murderer.Character:FindFirstChildOfClass("Humanoid")
                                args[2] = targetPart.Position + (hum and hum.MoveDirection or Vector3.zero)
                            else -- Regular
                                args[2] = targetPart.Position
                            end
                            return oldNC(self, table.unpack(args))
                        end
                    end
                end
            end

        -- Murderer Silent Aim: intercept Knife Throw FireServer
        elseif method == "FireServer" then
            if self.Name == "Throw" and State.MurdSilentAim then
                local target = (State.MurdTarget == "Closest") and GetClosestPlayer() or GetClosestToMouse()
                if target and target.Character then
                    local root = target.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local vel = root.AssemblyLinearVelocity / 3
                        args[1] = CFrame.new(root.Position + Vector3.new(vel.X, vel.Y / 1.5, vel.Z))
                        return oldNC(self, table.unpack(args))
                    end
                end
            end

            -- Anti Kick
            if method == "Kick" and self == LP then
                if State.AntiKick then return end
            end
        end

        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ============ FLUENT WINDOW ============
local Window = Fluent:CreateWindow({
    Title     = "MM2 Script",
    SubTitle  = "ESP · Combat · Gun · Roles",
    TabWidth  = 145,
    Size      = UDim2.fromOffset(560, 480),
    Acrylic   = false, -- KEEP false for mobile compatibility
    Theme     = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals",  Icon = "eye"       }),
    Game    = Window:AddTab({ Title = "Game",     Icon = "clock"     }),
    Sheriff = Window:AddTab({ Title = "Sheriff",  Icon = "shield"    }),
    Murderer= Window:AddTab({ Title = "Murderer", Icon = "swords"    }),
    Gun     = Window:AddTab({ Title = "Gun",      Icon = "crosshair" }),
}

-- ================================================================
-- VISUALS TAB
-- ================================================================
Tabs.Visuals:AddParagraph({
    Title = "ESP Colors",
    Content = "Red = Murderer  |  Blue = Sheriff/Hero  |  Green = Innocent"
})

Tabs.Visuals:AddToggle("NameESP", {
    Title   = "Name ESP",
    Default = false,
    Callback = function(v)
        State.ESP = v
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                if v then CreateNameESP(p) else RemoveNameESP(p) end
            end
        end
    end
})

Tabs.Visuals:AddToggle("BoxESP", {
    Title   = "Box Outline ESP",
    Default = false,
    Callback = function(v)
        State.ESPOutline = v
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                if v then CreateBoxESP(p) else RemoveBoxESP(p) end
            end
        end
    end
})

Tabs.Visuals:AddToggle("ChamESP", {
    Title   = "Chams (See through walls)",
    Default = false,
    Callback = function(v)
        State.ESPCham = v
        if v then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP then
                    CreateCham(p)
                    p.CharacterAdded:Connect(function()
                        task.wait(1.5)
                        if State.ESPCham then CreateCham(p) end
                    end)
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do RemoveCham(p) end
        end
    end
})

-- ================================================================
-- GAME TAB
-- ================================================================
Tabs.Game:AddParagraph({
    Title = "Round Info",
    Content = "Role detection and round notifications"
})

Tabs.Game:AddToggle("RoundTimer", {
    Title   = "Show Round Timer",
    Default = false,
    Callback = function(v)
        State.ShowTimer = v
        if not v then TimerFrame.Visible = false end
    end
})

Tabs.Game:AddButton({
    Title = "Get Murderer Chance",
    Description = "Shows your % chance of being murderer next round",
    Callback = function()
        if not Remote_GetChance then Notify("GetChance remote not found"); return end
        local ok, chance = pcall(function() return Remote_GetChance:InvokeServer() end)
        if ok then
            Notify("Murderer Chance: " .. tostring(chance) .. "%")
        else
            Notify("Failed to get chance")
        end
    end
})

Tabs.Game:AddToggle("NotifyRole", {
    Title   = "Auto Notify Role on Round Start",
    Default = false,
    Callback = function(v)
        State.NotifyRole = v
    end
})

Tabs.Game:AddButton({
    Title = "Notify Murderer's Perk (Manual)",
    Description = "Tells you what perk the murderer is using right now",
    Callback = function()
        if State.Murderer == "" then Notify("No murderer detected"); return end
        local mdata = State.Roles[State.Murderer]
        if mdata and mdata.Effect and mdata.Effect ~= "" then
            Notify("Murderer: " .. State.Murderer .. "\nPerk: " .. tostring(mdata.Effect))
        else
            Notify("Murderer perk data not available yet")
        end
    end
})

Tabs.Game:AddToggle("AutoNotifyPerk", {
    Title   = "Auto Notify Murderer's Perk",
    Description = "Notifies you when a round starts with murderer's perk",
    Default = false,
    Callback = function(v)
        State.AutoNotifyPerk = v
    end
})

Tabs.Game:AddParagraph({ Title = "", Content = "" })

Tabs.Game:AddButton({
    Title = "Who is Murderer?",
    Callback = function()
        Notify(State.Murderer ~= "" and ("Murderer: " .. State.Murderer) or "No murderer assigned yet")
    end
})

Tabs.Game:AddButton({
    Title = "Who is Sheriff?",
    Callback = function()
        Notify(State.Sheriff ~= "" and ("Sheriff: " .. State.Sheriff) or "No sheriff assigned yet")
    end
})

Tabs.Game:AddButton({
    Title = "My Role?",
    Callback = function()
        Notify("Your Role: " .. State.MyRole)
    end
})

-- ================================================================
-- SHERIFF TAB (Silent Aim, Shoot Murderer)
-- ================================================================
Tabs.Sheriff:AddParagraph({
    Title = "Sheriff Silent Aim",
    Content = "Hooks your gun shot to redirect toward the murderer\nMethods: Dynamic (best for moving), Regular (stationary), Seismic (velocity prediction)"
})

Tabs.Sheriff:AddToggle("SheriffSA", {
    Title   = "Sheriff Silent Aim",
    Default = false,
    Callback = function(v)
        State.SheriffSilentAim = v
        Notify(v and "Silent Aim ON" or "Silent Aim OFF")
    end
})

Tabs.Sheriff:AddToggle("SharpShooter", {
    Title   = "Sharp Shooter",
    Description = "Aims at PrimaryPart instead of HumanoidRootPart (more accurate)",
    Default = false,
    Callback = function(v)
        State.SharpShooter = v
    end
})

Tabs.Sheriff:AddDropdown("SilentAimMethod", {
    Title   = "Silent Aim Method",
    Values  = { "Dynamic", "Regular", "Seismic" },
    Default = 1,
    Callback = function(v)
        State.SilentAimMethod = v
        Notify("Method set to: " .. v)
    end
})

Tabs.Sheriff:AddParagraph({
    Title = "Method Guide",
    Content = "Dynamic: Leads target's movement direction (good overall)\nRegular: Snaps directly to position (best for still targets)\nSeismic: Uses velocity math (best for running targets)"
})

Tabs.Sheriff:AddParagraph({ Title = "", Content = "" })

-- Helper: compute the aim position toward murderer using selected method
local function ComputeMurdererAimPos(murderer)
    local mroot = GetRoot(murderer)
    if not mroot then return nil end
    local acc = State.SilentAimMethod
    local targetPart = State.SharpShooter
        and (murderer.Character.PrimaryPart or mroot)
        or mroot
    local hum = murderer.Character:FindFirstChildOfClass("Humanoid")

    if acc == "Seismic" then
        local vel = targetPart.AssemblyLinearVelocity
        if vel.Magnitude < 0.1 then
            return targetPart.Position
        else
            local v  = (vel.Unit * vel.Magnitude) / 16.5
            local vy = math.clamp(v.Y, -2, 2.65)
            return targetPart.Position + Vector3.new(v.X, vy, v.Z / 1.25)
        end
    elseif acc == "Dynamic" then
        local moveDir = hum and hum.MoveDirection or Vector3.zero
        return targetPart.Position + moveDir
    else -- Regular
        return targetPart.Position
    end
end

Tabs.Sheriff:AddButton({
    Title = "Shoot Murderer",
    Description = "Fires your gun at the murderer using the selected aim method — no teleporting",
    Callback = function()
        local murderer = Players:FindFirstChild(State.Murderer)
        if not murderer or not murderer.Character then
            Notify("No murderer found / not alive"); return
        end
        local gun, fromBackpack = GetGun()
        if not gun then Notify("You have no gun!"); return end

        State.ShootingMurderer = true

        local aimPos = ComputeMurdererAimPos(murderer)
        if aimPos then
            pcall(function()
                gun.KnifeServer.ShootGun:InvokeServer(0, aimPos, "AH")
            end)
            Notify("Fired at murderer! (" .. State.SilentAimMethod .. ")")
        else
            Notify("Could not get murderer position")
        end

        task.wait(0.05)
        State.ShootingMurderer = false
        if fromBackpack and gun and gun.Parent then gun.Parent = LP.Backpack end
    end
})

-- Mobile button: Shoot Murderer
if isMobile then
    Tabs.Sheriff:AddToggle("ShootMurdMobileBtn", {
        Title   = "Mobile On-Screen: Shoot Murderer",
        Default = false,
        Callback = function(v)
            if v then
                ContextActionService:BindAction("MM2_ShootMurd",
                    function(_, state)
                        if state ~= Enum.UserInputState.Begin then return end
                        local murderer = Players:FindFirstChild(State.Murderer)
                        if not murderer or not murderer.Character then return end
                        local gun, fromBackpack = GetGun()
                        if not gun then return end
                        State.ShootingMurderer = true
                        local aimPos = ComputeMurdererAimPos(murderer)
                        if aimPos then
                            pcall(function()
                                gun.KnifeServer.ShootGun:InvokeServer(0, aimPos, "AH")
                            end)
                        end
                        task.wait(0.05)
                        State.ShootingMurderer = false
                        if fromBackpack and gun and gun.Parent then gun.Parent = LP.Backpack end
                    end,
                true, Enum.KeyCode.ButtonX)
                ContextActionService:SetTitle("MM2_ShootMurd", "Shoot")
                ContextActionService:SetPosition("MM2_ShootMurd", UDim2.new(1, -260, 0, -200))
            else
                ContextActionService:UnbindAction("MM2_ShootMurd")
            end
        end
    })
end

-- ================================================================
-- MURDERER TAB (Knife Aura, Kill, Silent Aim)
-- ================================================================
Tabs.Murderer:AddParagraph({
    Title = "Murderer Features",
    Content = "Most features require you to be the Murderer role"
})

Tabs.Murderer:AddToggle("MurdSilentAim", {
    Title   = "Murderer Silent Aim (Knife Throw)",
    Default = false,
    Callback = function(v)
        State.MurdSilentAim = v
    end
})

Tabs.Murderer:AddDropdown("MurdSATarget", {
    Title   = "Silent Aim Target Method",
    Values  = { "Closest", "Mouse Cursor" },
    Default = 1,
    Callback = function(v)
        State.MurdTarget = v
    end
})

Tabs.Murderer:AddToggle("KnifeAura", {
    Title   = "Knife Aura",
    Description = "Auto kills any player within range (Murderer only)",
    Default = false,
    Callback = function(v)
        State.KnifeAura = v
        if v then
            coroutine.wrap(function()
                while State.KnifeAura do
                    task.wait(0.15)
                    if State.MyRole == "Murderer" and LP.Character then
                        local knife = GetKnife()
                        if knife then
                            local myRoot = GetRoot(LP)
                            if myRoot then
                                for _, p in pairs(Players:GetPlayers()) do
                                    if p ~= LP and IsAlive(p) then
                                        local root = GetRoot(p)
                                        if root and (root.Position - myRoot.Position).Magnitude <= State.KnifeRange then
                                            KillPlayer(p, knife)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)()
        end
    end
})

Tabs.Murderer:AddSlider("KnifeRange", {
    Title   = "Knife Aura Range (studs)",
    Default = 20,
    Min     = 5,
    Max     = 60,
    Rounding = 1,
    Callback = function(v)
        State.KnifeRange = v
    end
})

Tabs.Murderer:AddButton({
    Title = "Kill Everyone",
    Description = "Kills all alive players instantly (must be Murderer)",
    Callback = function()
        if State.MyRole ~= "Murderer" then Notify("You are not the murderer!"); return end
        local knife = GetKnife()
        if not knife then Notify("No knife in inventory"); return end
        local count = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and IsAlive(p) then
                KillPlayer(p, knife)
                count = count + 1
                task.wait(0.05)
            end
        end
        Notify("Killed " .. count .. " players!")
    end
})

Tabs.Murderer:AddButton({
    Title = "Kill Sheriff",
    Callback = function()
        if State.MyRole ~= "Murderer" then Notify("You are not the murderer!"); return end
        local sheriff = Players:FindFirstChild(State.Sheriff)
        if not sheriff then Notify("No sheriff found"); return end
        local knife = GetKnife()
        if not knife then Notify("No knife found"); return end
        KillPlayer(sheriff, knife)
        Notify("Attacked sheriff!")
    end
})

Tabs.Murderer:AddButton({
    Title = "Kill Nearest Player",
    Callback = function()
        if State.MyRole ~= "Murderer" then Notify("You are not the murderer!"); return end
        local knife = GetKnife()
        if not knife then Notify("No knife found"); return end
        local target = GetClosestPlayer()
        if target then
            KillPlayer(target, knife)
            Notify("Attacked " .. target.Name)
        else
            Notify("No nearby players")
        end
    end
})

-- ================================================================
-- GUN TAB (Grab Gun, Break Gun, Steal)
-- ================================================================
Tabs.Gun:AddParagraph({
    Title = "Gun Controls",
    Content = "Grab dropped guns, break or steal sheriff's gun"
})

Tabs.Gun:AddToggle("AutoGrabGun", {
    Title   = "Auto Grab Dropped Gun",
    Description = "Teleports to gun when it drops and picks it up",
    Default = false,
    Callback = function(v)
        State.AutoGrabGun = v
        if v then
            MakeTask("AutoGrabGunWatcher", workspace.ChildAdded, function(child)
                if child.Name == "GunDrop" and not State.Grabbing then
                    State.Grabbing = true
                    local myPos = GetRoot(LP) and GetRoot(LP).CFrame
                    MakeTask("GrabGunLoop", RunService.Heartbeat, function()
                        if workspace:FindFirstChild("GunDrop") then
                            local drop = workspace:FindFirstChild("GunDrop")
                            if drop then MoveTo(drop.CFrame) end
                        else
                            RemoveTask("GrabGunLoop")
                            if myPos then
                                task.wait(0.1)
                                MoveTo(myPos)
                            end
                            State.Grabbing = false
                        end
                    end)
                end
            end)
            -- Check if already dropped
            if workspace:FindFirstChild("GunDrop") and not State.Grabbing then
                State.Grabbing = true
                local myPos = GetRoot(LP) and GetRoot(LP).CFrame
                MakeTask("GrabGunLoop", RunService.Heartbeat, function()
                    if workspace:FindFirstChild("GunDrop") then
                        local drop = workspace:FindFirstChild("GunDrop")
                        if drop then MoveTo(drop.CFrame) end
                    else
                        RemoveTask("GrabGunLoop")
                        if myPos then MoveTo(myPos) end
                        State.Grabbing = false
                    end
                end)
            end
        else
            RemoveTask("AutoGrabGunWatcher")
            RemoveTask("GrabGunLoop")
            State.Grabbing = false
        end
    end
})

Tabs.Gun:AddButton({
    Title = "Break Sheriff's Gun (Once)",
    Description = "Forces sheriff's gun to misfire/break",
    Callback = function()
        local gun = GetSheriffGun()
        if not gun then Notify("Sheriff has no gun currently"); return end
        local ok, err = pcall(function()
            gun.KnifeServer.ShootGun:InvokeServer(0, Vector3.new(), "AH")
        end)
        if ok or (not ok) then -- pcall catches success/error, we just try it
            Notify("Break gun attempt sent!")
        end
    end
})

Tabs.Gun:AddToggle("AutoBreakGun", {
    Title   = "Auto Break Gun (Loop)",
    Description = "Continuously breaks sheriff's gun every frame",
    Default = false,
    Callback = function(v)
        State.AutoBreakGun = v
        if v then
            MakeTask("AutoBreakGun", RunService.Stepped, function()
                local gun = GetSheriffGun()
                if gun then
                    pcall(function()
                        gun.KnifeServer.ShootGun:InvokeServer(0, Vector3.new(), "AH")
                    end)
                end
            end)
        else
            RemoveTask("AutoBreakGun")
        end
    end
})

-- Mobile break gun button
if isMobile then
    Tabs.Gun:AddToggle("BreakGunMobile", {
        Title   = "Mobile Button: Break Gun",
        Default = false,
        Callback = function(v)
            if v then
                ContextActionService:BindAction("MM2_BreakGun",
                    function(_, state)
                        if state ~= Enum.UserInputState.Begin then return end
                        local gun = GetSheriffGun()
                        if gun then
                            pcall(function()
                                gun.KnifeServer.ShootGun:InvokeServer(0, Vector3.new(), "AH")
                            end)
                        end
                    end,
                true, Enum.KeyCode.ButtonR1)
                ContextActionService:SetTitle("MM2_BreakGun", "Break Gun")
                ContextActionService:SetPosition("MM2_BreakGun", UDim2.new(1, -130, 0, -200))
            else
                ContextActionService:UnbindAction("MM2_BreakGun")
            end
        end
    })
end

Tabs.Gun:AddButton({
    Title = "Steal Sheriff's Gun (Spray Paint)",
    Description = "Requires SprayPaint toy in your inventory",
    Callback = function()
        local sheriff = Players:FindFirstChild(State.Sheriff)
        if not sheriff or not sheriff.Character then
            Notify("No sheriff found"); return
        end

        -- Find spray paint
        local spray = nil
        local sprayFromBackpack = false
        for _, t in pairs(LP.Character and LP.Character:GetChildren() or {}) do
            if t.Name == "SprayPaint" and t:IsA("Tool") then spray = t end
        end
        for _, t in pairs(LP.Backpack:GetChildren()) do
            if t.Name == "SprayPaint" and not spray and t:IsA("Tool") then
                spray = t
                spray.Parent = LP.Character
                sprayFromBackpack = true
            end
        end

        if not spray then
            Notify("You need SprayPaint toy equipped!\nGet it from your toys list.")
            return
        end

        local sheriffRoot = GetRoot(sheriff)
        if not sheriffRoot then return end

        -- Reset the sheriff (drop gun)
        pcall(function()
            spray.Remote:FireServer(0, Enum.NormalId.Right, 10, sheriffRoot, CFrame.new(0, -math.huge, 0))
        end)

        Notify("Attempting gun steal...")

        -- Wait for gun to drop
        local waited = 0
        while not workspace:FindFirstChild("GunDrop") and waited < 4 do
            task.wait(0.1)
            waited = waited + 0.1
        end

        if sprayFromBackpack and spray and spray.Parent then
            spray.Parent = LP.Backpack
        end

        if workspace:FindFirstChild("GunDrop") then
            State.Grabbing = true
            local myPos = GetRoot(LP) and GetRoot(LP).CFrame
            local grabConn
            grabConn = RunService.Heartbeat:Connect(function()
                local drop = workspace:FindFirstChild("GunDrop")
                if drop then
                    MoveTo(drop.CFrame)
                else
                    grabConn:Disconnect()
                    if myPos then MoveTo(myPos) end
                    State.Grabbing = false
                    Notify("Gun picked up!")
                end
            end)
        else
            Notify("Gun didn't drop. Make sure sheriff is alive and has gun!")
        end
    end
})

-- ================================================================
-- NOTIFY ON LOAD
-- ================================================================
Fluent:Notify({
    Title   = "MM2 Script",
    Content = "✓ Loaded! ESP, Silent Aim, Roles, Gun all ready.\nRole info updates on round start.",
    Duration = 6
})

-- Handle any players already in game getting ESP setup
task.spawn(function()
    task.wait(0.5)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            if State.ESP        then CreateNameESP(p) end
            if State.ESPOutline then CreateBoxESP(p)  end
            if State.ESPCham    then CreateCham(p)    end
            p.CharacterAdded:Connect(function()
                task.wait(1.5)
                if State.ESPCham then CreateCham(p) end
            end)
        end
    end
end)

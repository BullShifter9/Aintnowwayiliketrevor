--[[
╔═══════════════════════════════════════════════════════════════╗
║          O M N I H U B  ·  MM2 Main Script  v1.3             ║
║                   By Azzakirms                                ║
║               Powered by Fluent UI                            ║
╚═══════════════════════════════════════════════════════════════╝
--]]

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

------------------------------------------------------------
-- WATER LOADER
------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OmniHubLoader"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 250)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local dropShadow = Instance.new("ImageLabel")
dropShadow.Name = "DropShadow"
dropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
dropShadow.BackgroundTransparency = 1
dropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
dropShadow.Size = UDim2.new(1, 40, 1, 40)
dropShadow.ZIndex = 0
dropShadow.Image = "rbxassetid://6014261993"
dropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
dropShadow.ImageTransparency = 1
dropShadow.ScaleType = Enum.ScaleType.Slice
dropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
dropShadow.Parent = mainFrame

local waterContainer = Instance.new("Frame")
waterContainer.Name = "WaterContainer"
waterContainer.Size = UDim2.new(1, 0, 1, 0)
waterContainer.BackgroundTransparency = 1
waterContainer.ClipsDescendants = true
waterContainer.Parent = mainFrame

local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Size = UDim2.new(0, 100, 0, 100)
logo.Position = UDim2.new(0.5, 0, 0.3, 0)
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://122380482857500"
logo.ImageTransparency = 1
logo.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0.55, 0)
title.Font = Enum.Font.GothamBold
title.Text = "OMNIHUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 36
title.BackgroundTransparency = 1
title.TextTransparency = 1
title.Parent = mainFrame

local versionText = Instance.new("TextLabel")
versionText.Name = "Version"
versionText.Size = UDim2.new(1, 0, 0, 20)
versionText.Position = UDim2.new(0, 0, 0.67, 0)
versionText.Font = Enum.Font.Gotham
versionText.Text = "V1.3 • By Azzakirms"
versionText.TextColor3 = Color3.fromRGB(180, 180, 255)
versionText.TextSize = 14
versionText.BackgroundTransparency = 1
versionText.TextTransparency = 1
versionText.Parent = mainFrame

local statusText = Instance.new("TextLabel")
statusText.Name = "Status"
statusText.Size = UDim2.new(0.8, 0, 0, 20)
statusText.Position = UDim2.new(0.1, 0, 0.78, 0)
statusText.Font = Enum.Font.Gotham
statusText.Text = "Initializing..."
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextSize = 16
statusText.BackgroundTransparency = 1
statusText.TextTransparency = 1
statusText.Parent = mainFrame

local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.Size = UDim2.new(0.8, 0, 0, 10)
progressContainer.Position = UDim2.new(0.1, 0, 0.85, 0)
progressContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
progressContainer.BorderSizePixel = 0
progressContainer.BackgroundTransparency = 1
progressContainer.Parent = mainFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 5)
progressCorner.Parent = progressContainer

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
progressFill.BorderSizePixel = 0
progressFill.BackgroundTransparency = 1
progressFill.Parent = progressContainer

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 5)
fillCorner.Parent = progressFill

local progressGlow = Instance.new("ImageLabel")
progressGlow.Name = "ProgressGlow"
progressGlow.BackgroundTransparency = 1
progressGlow.Position = UDim2.new(0, -10, 0, -10)
progressGlow.Size = UDim2.new(1, 20, 1, 20)
progressGlow.ZIndex = 0
progressGlow.Image = "rbxassetid://5028857084"
progressGlow.ImageColor3 = Color3.fromRGB(79, 149, 255)
progressGlow.ImageTransparency = 1
progressGlow.Parent = progressFill

local fadeOut = Instance.new("NumberValue")
fadeOut.Name = "FadeOut"
fadeOut.Value = 0
fadeOut.Parent = screenGui

local function createWaterParticle(startPosition)
    local droplet = Instance.new("Frame")
    droplet.Size = UDim2.new(0, math.random(5, 20), 0, math.random(5, 20))
    droplet.Position = startPosition
    droplet.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
    droplet.BackgroundTransparency = math.random(2, 5) / 10
    droplet.BorderSizePixel = 0
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = droplet
    local dropletGlow = Instance.new("ImageLabel")
    dropletGlow.BackgroundTransparency = 1
    dropletGlow.Position = UDim2.new(0, -5, 0, -5)
    dropletGlow.Size = UDim2.new(1, 10, 1, 10)
    dropletGlow.ZIndex = 0
    dropletGlow.Image = "rbxassetid://5028857084"
    dropletGlow.ImageColor3 = Color3.fromRGB(79, 149, 255)
    dropletGlow.ImageTransparency = 0.7
    dropletGlow.Parent = droplet
    droplet.Parent = waterContainer
    return droplet
end

local function startLoader(onDone)
    for i = 1, 50 do
        local xPos = math.random(0, 450)
        local yPos = -20
        local startPosition = UDim2.new(0, xPos, 0, yPos)
        local droplet = createWaterParticle(startPosition)
        spawn(function()
            for j = 1, 20 do
                droplet.Position = UDim2.new(0, xPos, 0, yPos + j * 15)
                wait(0.005)
            end
            if i > 40 then
                mainFrame.BackgroundTransparency = (50 - i) / 10
                dropShadow.ImageTransparency = (50 - i) / 10
            end
            wait(0.3)
            droplet:Destroy()
        end)
        wait(0.03)
    end
    for i = 10, 0, -2 do
        title.TextTransparency = i / 10
        logo.ImageTransparency = i / 10
        versionText.TextTransparency = i / 10
        statusText.TextTransparency = i / 10
        progressContainer.BackgroundTransparency = i / 10
        progressFill.BackgroundTransparency = i / 10
        progressGlow.ImageTransparency = 0.7 + (i / 30)
        wait(0.02)
    end
    local loadingSteps = {
        "Checking Modules...",
        "Checking Script...",
        "Getting Common Information..."
    }
    for i, step in ipairs(loadingSteps) do
        statusText.Text = step
        local startFill = (i - 1) / 3
        local endFill = i / 3
        for j = 1, 10 do
            progressFill.Size = UDim2.new(startFill + ((endFill - startFill) * (j / 10)), 0, 1, 0)
            wait(0.1)
        end
    end
    statusText.Text = "Finalizing..."
    for _ = 1, 45 do
        progressFill.Size = UDim2.new(1, 0, 1, 0)
        wait(0.1)
    end
    for i = 0, 10, 2 do
        local t = i / 10
        title.TextTransparency = t
        logo.ImageTransparency = t
        versionText.TextTransparency = t
        statusText.TextTransparency = t
        progressContainer.BackgroundTransparency = t
        progressFill.BackgroundTransparency = t
        progressGlow.ImageTransparency = 0.7 + (i / 30)
        wait(0.02)
    end
    for i = 1, 50 do
        local xPos = math.random(0, 450)
        local yPos = math.random(0, 250)
        local droplet = createWaterParticle(UDim2.new(0, xPos, 0, yPos))
        spawn(function()
            for j = 1, 20 do
                droplet.Position = UDim2.new(0, xPos, 0, yPos + j * 15)
                wait(0.005)
            end
            if i > 10 then
                mainFrame.BackgroundTransparency = i / 50
                dropShadow.ImageTransparency = i / 50
            end
            wait(0.05)
            droplet:Destroy()
        end)
        wait(0.03)
    end
    local fadeOutTween = TweenService:Create(fadeOut,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Value = 1})
    fadeOutTween:Play()
    fadeOutTween.Completed:Wait()
    screenGui:Destroy()
    if onDone then onDone() end
end

------------------------------------------------------------
-- ESP SYSTEM
------------------------------------------------------------
local roles  = {}
local Murder, Sheriff, Hero = nil, nil, nil
local GunDrop = nil

local ESP = {
    Enabled = true,
    OutlineThickness = 3,
    MaxRenderDistance = 175,
    Colors = {
        Murderer = Color3.fromRGB(255, 0, 0),
        Sheriff  = Color3.fromRGB(0, 100, 255),
        Hero     = Color3.fromRGB(255, 215, 0),
        Innocent = Color3.fromRGB(50, 255, 100),
        GunDrop  = Color3.fromRGB(255, 255, 50),
    }
}

local HighlightFolder = Instance.new("Folder")
HighlightFolder.Name = "ESP_Highlights"
if syn and syn.protect_gui then
    syn.protect_gui(HighlightFolder)
    HighlightFolder.Parent = CoreGui
else
    HighlightFolder.Parent = CoreGui
end

local Highlights = {}

local function IsAlive(Player)
    for i, v in pairs(roles) do
        if Player.Name == i then
            return not (v.Killed or v.Dead)
        end
    end
    return false
end

local function GetPlayerColor(playerName)
    if playerName == Murder      then return ESP.Colors.Murderer
    elseif playerName == Sheriff then return ESP.Colors.Sheriff
    elseif playerName == Hero    then return ESP.Colors.Hero
    else                              return ESP.Colors.Innocent end
end

local function CreateOutline(player)
    if not player or not player.Parent then return nil end
    if Highlights[player] then return Highlights[player] end
    local highlight = Instance.new("Highlight")
    highlight.Name = player.Name
    highlight.FillTransparency = 0.85
    highlight.FillColor = GetPlayerColor(player.Name)
    highlight.OutlineColor = GetPlayerColor(player.Name)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = ESP.Enabled
    highlight.Parent = HighlightFolder
    if player.Name == Murder then
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        TweenService:Create(highlight, tweenInfo, {OutlineTransparency = 0.4}):Play()
    end
    Highlights[player] = highlight
    return highlight
end

local function RemoveOutline(player)
    local highlight = Highlights[player]
    if highlight then
        highlight:Destroy()
        Highlights[player] = nil
    end
end

local function UpdateESP()
    for player, highlight in pairs(Highlights) do
        if type(player) == "userdata" and player:IsA("Player") then
            highlight.Enabled = ESP.Enabled
        end
    end
    if not ESP.Enabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not IsAlive(player) then
            if Highlights[player] then Highlights[player].Enabled = false end
            continue
        end
        local distance = (character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
        if distance > ESP.MaxRenderDistance then
            if Highlights[player] then Highlights[player].Enabled = false end
            continue
        end
        local highlight = CreateOutline(player)
        if highlight then
            highlight.Adornee = character
            highlight.FillColor = GetPlayerColor(player.Name)
            highlight.OutlineColor = GetPlayerColor(player.Name)
            highlight.Enabled = true
        end
    end
    if GunDrop and GunDrop.Parent then
        if not Highlights.GunDrop then
            local h = Instance.new("Highlight")
            h.Name = "GunDrop"
            h.FillTransparency = 0.5
            h.FillColor = ESP.Colors.GunDrop
            h.OutlineColor = ESP.Colors.GunDrop
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Enabled = ESP.Enabled
            h.Parent = HighlightFolder
            Highlights.GunDrop = h
        end
        Highlights.GunDrop.Adornee = GunDrop
    elseif Highlights.GunDrop then
        Highlights.GunDrop:Destroy()
        Highlights.GunDrop = nil
    end
end

local function ToggleESP(state)
    ESP.Enabled = state
    for _, highlight in pairs(Highlights) do highlight.Enabled = state end
    if state then UpdateESP() end
end

------------------------------------------------------------
-- ROLE TRACKING  (dynamic FindFirstChild — your original)
------------------------------------------------------------
local RoleUpdateConnection = nil
local function SetupRoleTracking()
    if RoleUpdateConnection then RoleUpdateConnection:Disconnect(); RoleUpdateConnection = nil end
    RoleUpdateConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            if remote then
                roles = remote:InvokeServer()
                for i, v in pairs(roles) do
                    if     v.Role == "Murderer" then Murder  = i
                    elseif v.Role == "Sheriff"  then Sheriff = i
                    elseif v.Role == "Hero"     then Hero    = i end
                end
            end
        end)
    end)
end

------------------------------------------------------------
-- GUN TRACKING
------------------------------------------------------------
local GunTrackingConnections = {}
local function SetupGunTracking()
    for _, conn in pairs(GunTrackingConnections) do conn:Disconnect() end
    table.clear(GunTrackingConnections)
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name == "GunDrop" then GunDrop = item; break end
    end
    GunTrackingConnections[1] = workspace.ChildAdded:Connect(function(child)
        if child.Name == "GunDrop" then GunDrop = child end
    end)
    GunTrackingConnections[2] = workspace.ChildRemoved:Connect(function(child)
        if child == GunDrop then GunDrop = nil end
    end)
end

------------------------------------------------------------
-- PLAYER CONNECTIONS
------------------------------------------------------------
local PlayerAddedConnection    = nil
local PlayerRemovingConnection = nil
local function SetupPlayerConnections()
    if PlayerAddedConnection    then PlayerAddedConnection:Disconnect()    end
    if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end
    PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
        task.delay(1, function()
            if not player or not player.Parent then return end
            if player.Character then UpdateESP() end
            player.CharacterAdded:Connect(function() task.delay(0.5, UpdateESP) end)
        end)
    end)
    PlayerRemovingConnection = Players.PlayerRemoving:Connect(RemoveOutline)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function() task.delay(0.5, UpdateESP) end)
        end
    end
end

------------------------------------------------------------
-- ROUND TIMER  (real remote: Remotes.Extras.GetTimer)
------------------------------------------------------------
local timerRemote = ReplicatedStorage:WaitForChild("Remotes")
    :WaitForChild("Extras")
    :WaitForChild("GetTimer")

-- Timer UI
local timerGui = Instance.new("ScreenGui")
timerGui.Name = "RoundTimerDisplay"
timerGui.ResetOnSpawn = false
timerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(timerGui) end
pcall(function() timerGui.Parent = CoreGui end)
if not timerGui.Parent or timerGui.Parent ~= CoreGui then
    timerGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
timerGui.Enabled = false   -- hidden until toggled on

local timerContainer = Instance.new("Frame")
timerContainer.Name = "TimerContainer"
timerContainer.Size = UDim2.new(0, 150, 0, 40)
timerContainer.Position = UDim2.new(0.5, -75, 0, 10)  -- top center
timerContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
timerContainer.BackgroundTransparency = 0.2
timerContainer.BorderSizePixel = 0
timerContainer.Parent = timerGui

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 6)
timerCorner.Parent = timerContainer

local timerShadow = Instance.new("ImageLabel")
timerShadow.Name = "Shadow"
timerShadow.AnchorPoint = Vector2.new(0.5, 0.5)
timerShadow.BackgroundTransparency = 1
timerShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
timerShadow.Size = UDim2.new(1, 10, 1, 10)
timerShadow.ZIndex = -1
timerShadow.Image = "rbxassetid://5554236805"
timerShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
timerShadow.ImageTransparency = 0.4
timerShadow.ScaleType = Enum.ScaleType.Slice
timerShadow.SliceCenter = Rect.new(23, 23, 277, 277)
timerShadow.Parent = timerContainer

local timerTitleLabel = Instance.new("TextLabel")
timerTitleLabel.Name = "TitleLabel"
timerTitleLabel.Size = UDim2.new(1, 0, 0, 18)
timerTitleLabel.BackgroundTransparency = 1
timerTitleLabel.Text = "ROUND TIME"
timerTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerTitleLabel.TextSize = 12
timerTitleLabel.Font = Enum.Font.GothamBold
timerTitleLabel.Parent = timerContainer

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerText"
timerLabel.Size = UDim2.new(1, 0, 0, 22)
timerLabel.Position = UDim2.new(0, 0, 0, 18)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "--:--"
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextSize = 18
timerLabel.Font = Enum.Font.GothamSemibold
timerLabel.Parent = timerContainer

local function FormatTime(seconds)
    if not seconds or type(seconds) ~= "number" then return "--:--" end
    seconds = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local TimerDisplay = {
    Enabled       = false,
    RefreshRate   = 1,
    PulsingTween  = nil,
    TimerConnection = nil,
}

function TimerDisplay:Update()
    if not self.Enabled then return end
    local success, timeLeft = pcall(function()
        return timerRemote:InvokeServer()
    end)
    if success and timeLeft then
        timerLabel.Text = FormatTime(timeLeft)
        if timeLeft <= 10 then
            timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            if not self.PulsingTween then
                self.PulsingTween = TweenService:Create(timerLabel,
                    TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {TextSize = 22})
                self.PulsingTween:Play()
            end
        else
            timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            if self.PulsingTween then
                self.PulsingTween:Cancel()
                self.PulsingTween = nil
                timerLabel.TextSize = 18
            end
        end
    else
        timerLabel.Text = "--:--"
    end
end

function TimerDisplay:Start()
    if self.TimerConnection then
        self.TimerConnection:Disconnect()
        self.TimerConnection = nil
    end
    self.TimerConnection = RunService.Heartbeat:Connect(function()
        task.wait(self.RefreshRate)
        self:Update()
    end)
    timerGui.Enabled = true
end

function TimerDisplay:Stop()
    if self.TimerConnection then
        self.TimerConnection:Disconnect()
        self.TimerConnection = nil
    end
    if self.PulsingTween then
        self.PulsingTween:Cancel()
        self.PulsingTween = nil
        timerLabel.TextSize = 18
        timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    timerLabel.Text = "--:--"
    timerGui.Enabled = false
end

function TimerDisplay:Toggle(state)
    self.Enabled = state
    if state then self:Start() else self:Stop() end
end

------------------------------------------------------------
-- ROLE NOTIFIER  (shows YOUR role when round starts)
------------------------------------------------------------
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "RoleNotifications"
NotifGui.ResetOnSpawn = false
if syn and syn.protect_gui then syn.protect_gui(NotifGui) end
pcall(function() NotifGui.Parent = CoreGui end)
if not NotifGui.Parent or NotifGui.Parent ~= CoreGui then
    NotifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local NotifFrame = Instance.new("Frame")
NotifFrame.Name = "NotificationFrame"
NotifFrame.Size = UDim2.new(0, 250, 0, 120)
NotifFrame.Position = UDim2.new(0.5, -125, 0, -120)   -- starts off-screen
NotifFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
NotifFrame.BackgroundTransparency = 0.2
NotifFrame.BorderSizePixel = 0
NotifFrame.Visible = false
NotifFrame.Parent = NotifGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 8)
notifCorner.Parent = NotifFrame

local notifStroke = Instance.new("UIStroke")
notifStroke.Color = Color3.fromRGB(255, 255, 255)
notifStroke.Thickness = 1.5
notifStroke.Transparency = 0.5
notifStroke.Parent = NotifFrame

local notifTitle = Instance.new("TextLabel")
notifTitle.Name = "TitleLabel"
notifTitle.Size = UDim2.new(1, 0, 0, 30)
notifTitle.Position = UDim2.new(0, 0, 0, 0)
notifTitle.BackgroundTransparency = 1
notifTitle.Text = "YOUR ROLE"
notifTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
notifTitle.TextSize = 18
notifTitle.Font = Enum.Font.GothamBold
notifTitle.Parent = NotifFrame

local roleIcon = Instance.new("Frame")
roleIcon.Name = "RoleIcon"
roleIcon.Size = UDim2.new(0, 40, 0, 40)
roleIcon.Position = UDim2.new(0, 15, 0, 40)
roleIcon.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
roleIcon.BorderSizePixel = 0
roleIcon.Parent = NotifFrame
local roleIconCorner = Instance.new("UICorner")
roleIconCorner.CornerRadius = UDim.new(0, 8)
roleIconCorner.Parent = roleIcon

local roleLabel = Instance.new("TextLabel")
roleLabel.Name = "RoleLabel"
roleLabel.Size = UDim2.new(0, 150, 0, 50)
roleLabel.Position = UDim2.new(0, 70, 0, 45)
roleLabel.BackgroundTransparency = 1
roleLabel.Text = "Innocent"
roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roleLabel.TextSize = 20
roleLabel.Font = Enum.Font.GothamBold
roleLabel.TextXAlignment = Enum.TextXAlignment.Left
roleLabel.Parent = NotifFrame

local RoleNotify = {
    Enabled              = true,
    NotificationDuration = 4,
}

function RoleNotify:ShowNotification(role)
    if not self.Enabled then return end
    local roleColor
    if role == "Murderer" then
        roleColor = ESP.Colors.Murderer          -- red
    elseif role == "Sheriff" then
        roleColor = ESP.Colors.Sheriff           -- blue
    elseif role == "Hero" then
        roleColor = ESP.Colors.Hero              -- yellow (sheriff died, you picked up gun)
    elseif role == "Innocent" then
        roleColor = ESP.Colors.Innocent          -- green
    else
        roleColor = Color3.fromRGB(200, 200, 200)
    end

    roleIcon.BackgroundColor3 = roleColor
    roleLabel.Text = role
    NotifFrame.Position = UDim2.new(0.5, -125, 0, -120)
    NotifFrame.Visible = true

    -- Slide in
    local inTween = TweenService:Create(NotifFrame,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -125, 0.15, 0)})
    inTween:Play()

    -- Slide out after duration
    task.delay(self.NotificationDuration, function()
        local outTween = TweenService:Create(NotifFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -125, 0, -120)})
        outTween:Play()
        outTween.Completed:Connect(function()
            NotifFrame.Visible = false
        end)
    end)
end

function RoleNotify:Toggle(state)
    self.Enabled = state
end

-- Tracks local player's role and fires notification on change
local previousRole = nil
local RoleNotifyConnection = nil

local function SetupRoleNotifications()
    if RoleNotifyConnection then RoleNotifyConnection:Disconnect(); RoleNotifyConnection = nil end
    previousRole = nil
    RoleNotifyConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            local remote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
            if not remote then return end
            local playerData = remote:InvokeServer()
            local myData = playerData[LocalPlayer.Name]
            local myRole = myData and myData.Role
            if myRole and myRole ~= previousRole then
                previousRole = myRole
                RoleNotify:ShowNotification(myRole)
            end
        end)
    end)
end

------------------------------------------------------------
-- SILENT AIM — GetMurderer
------------------------------------------------------------
local function GetMurderer()
    local players = Players:GetPlayers()
    for _, player in ipairs(players) do
        if player.Character and player.Character:FindFirstChild("Knife") then return player end
    end
    for _, player in ipairs(players) do
        if player.Character and player.Backpack and player.Backpack:FindFirstChild("Knife") then return player end
    end
    for _, player in ipairs(players) do
        if player:GetAttribute("Role") == "Murderer" then return player end
    end
    for _, player in ipairs(players) do
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local animator = player.Character.Humanoid:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                    local name = track.Animation.Name:lower()
                    if name:match("knife") or name:match("stab") then return player end
                end
            end
        end
    end
    return nil
end

------------------------------------------------------------
-- SILENT AIM — Position prediction
------------------------------------------------------------
local function getPredictedPosition(murderer)
    local character = murderer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    local head     = character:FindFirstChild("Head")
    if not rootPart or not humanoid then return nil end

    local ok, ping = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    ping = ok and ping or 100

    local fps = 1 / RunService.RenderStepped:Wait()
    local pingCompensation = math.clamp(ping / 1000, 0.08, 0.35)
    local timeSkip = pingCompensation * (60 / math.clamp(fps, 30, 120))

    local state      = humanoid:GetState()
    local isAirborne = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
    local currentVelocity = rootPart.AssemblyLinearVelocity
    local moveDirection   = humanoid.MoveDirection
    local moveSpeed       = humanoid.WalkSpeed
    local position        = rootPart.Position

    if not _G.velocityHistory then _G.velocityHistory = {} end
    if not _G.velocityHistory[murderer.UserId] then
        _G.velocityHistory[murderer.UserId] = {positions={}, velocities={}, timestamps={}, lastJumpTime=0}
    end
    local history = _G.velocityHistory[murderer.UserId]
    table.insert(history.positions, position)
    table.insert(history.velocities, currentVelocity)
    table.insert(history.timestamps, tick())
    if #history.positions > 10 then
        table.remove(history.positions, 1)
        table.remove(history.velocities, 1)
        table.remove(history.timestamps, 1)
    end

    local acceleration = Vector3.new(0, 0, 0)
    if #history.velocities >= 3 then
        local v2 = history.velocities[#history.velocities]
        local v1 = history.velocities[#history.velocities - 2]
        local dt = history.timestamps[#history.timestamps] - history.timestamps[#history.timestamps - 2]
        if dt > 0 then acceleration = (v2 - v1) / dt end
    end

    local jumpPrediction = 0
    if humanoid.Jump then
        history.lastJumpTime = tick()
        jumpPrediction = humanoid.JumpPower * 0.5
    elseif tick() - history.lastJumpTime < 0.3 then
        jumpPrediction = humanoid.JumpPower * 0.75 * (1 - (tick() - history.lastJumpTime) / 0.3)
    end

    local predictedPosition = position
    local predictedVelocity = currentVelocity
    local subTimeSkip       = timeSkip / 5

    for _ = 1, 5 do
        local horizontalVelocity = Vector3.new(predictedVelocity.X, 0, predictedVelocity.Z)
        if moveDirection.Magnitude > 0.1 then
            horizontalVelocity = horizontalVelocity
                + (moveDirection * moveSpeed - horizontalVelocity) * (isAirborne and 0.6 or 1.0) * subTimeSkip * 10
        else
            horizontalVelocity = horizontalVelocity
                * (1 - (isAirborne and 0.02 or 0.8) * subTimeSkip * 10)
        end
        local verticalVelocity = predictedVelocity.Y
        if isAirborne then
            verticalVelocity = math.max(verticalVelocity - workspace.Gravity * subTimeSkip, -100)
        else
            verticalVelocity = verticalVelocity * 0.86
            if jumpPrediction > 0 then verticalVelocity = jumpPrediction; jumpPrediction = 0 end
        end
        predictedVelocity  = Vector3.new(horizontalVelocity.X, verticalVelocity, horizontalVelocity.Z) + acceleration * subTimeSkip
        predictedPosition  = predictedPosition + predictedVelocity * subTimeSkip

        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Blacklist
        rp.FilterDescendantsInstances = {character}

        local floorRay = workspace:Raycast(predictedPosition, Vector3.new(0, -humanoid.HipHeight - 0.5, 0), rp)
        if floorRay then
            predictedPosition = Vector3.new(predictedPosition.X, floorRay.Position.Y + humanoid.HipHeight, predictedPosition.Z)
            if predictedVelocity.Y < 0 then
                predictedVelocity = Vector3.new(predictedVelocity.X, 0, predictedVelocity.Z)
            end
        end
        for _, dir in pairs({Vector3.new(1,0,0), Vector3.new(-1,0,0), Vector3.new(0,0,1), Vector3.new(0,0,-1)}) do
            local wallRay = workspace:Raycast(predictedPosition, dir * 2, rp)
            if wallRay then
                local normal = wallRay.Normal
                predictedPosition = predictedPosition + normal * (2 - wallRay.Distance)
                local dot = predictedVelocity:Dot(normal)
                if dot < 0 then
                    predictedVelocity = (predictedVelocity - 2 * dot * normal) * 0.8
                end
            end
        end
    end

    if head then
        predictedPosition = predictedPosition + Vector3.new(0, (head.Position - rootPart.Position).Y * 0.8, 0)
    end
    if currentVelocity.Magnitude > moveSpeed * 1.5 then
        predictedPosition = predictedPosition + currentVelocity.Unit * currentVelocity.Magnitude * timeSkip * 0.5
    end
    if ping > 150 then
        predictedPosition = predictedPosition + predictedVelocity * (ping / 1000) * 0.3
    end
    return predictedPosition
end

------------------------------------------------------------
-- AIM BUTTON
------------------------------------------------------------
local AimGui = Instance.new("ScreenGui")
AimGui.Name = "OmniAimGui"
AimGui.ResetOnSpawn = false
pcall(function() AimGui.Parent = CoreGui end)
if not AimGui.Parent or AimGui.Parent ~= CoreGui then
    AimGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local AimButton = Instance.new("ImageButton")
AimButton.Parent = AimGui
AimButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimButton.BackgroundTransparency = 0.3
AimButton.BorderColor3 = Color3.fromRGB(255, 100, 0)
AimButton.BorderSizePixel = 2
AimButton.Position = UDim2.new(0.897, 0, 0.3, 0)
AimButton.Size = UDim2.new(0.1, 0, 0.2, 0)
AimButton.Image = "rbxassetid://11162755592"
AimButton.Draggable = true
AimButton.Visible = false

local aimStroke = Instance.new("UIStroke", AimButton)
aimStroke.Color = Color3.fromRGB(255, 100, 0)
aimStroke.Thickness = 2
aimStroke.Transparency = 0.5

AimButton.MouseButton1Click:Connect(function()
    local gun = LocalPlayer.Character and (
        LocalPlayer.Character:FindFirstChild("Gun")
        or LocalPlayer.Backpack:FindFirstChild("Gun")
    )
    if not gun then return end

    local murderer = GetMurderer()
    if not murderer then return end

    LocalPlayer.Character.Humanoid:EquipTool(gun)

    local predictedPos = getPredictedPosition(murderer)
    if predictedPos then
        local remote = gun:FindFirstChild("KnifeLocal")
            and gun.KnifeLocal:FindFirstChild("CreateBeam")
            and gun.KnifeLocal.CreateBeam:FindFirstChild("RemoteFunction")
        if remote then
            remote:InvokeServer(1, predictedPos, "AH2")
        end
    end
end)

------------------------------------------------------------
-- FLUENT WINDOW
------------------------------------------------------------
local Fluent           = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager      = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title       = "OmniHub Script By Azzakirms",
    SubTitle    = "V1.3",
    TabWidth    = 100,
    Size        = UDim2.fromOffset(380, 300),
    Acrylic     = true,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
    Main     = Window:AddTab({ Title = "Main",         Icon = "eye"            }),
    Visuals  = Window:AddTab({ Title = "Visuals",      Icon = "camera"         }),
    Combat   = Window:AddTab({ Title = "Combat",       Icon = "crosshair"      }),
    Farming  = Window:AddTab({ Title = "Farming",      Icon = "dollar-sign"    }),
    Premium  = Window:AddTab({ Title = "Premium",      Icon = "star"           }),
    Discord  = Window:AddTab({ Title = "Join Discord", Icon = "message-square" }),
    Settings = Window:AddTab({ Title = "Settings",     Icon = "settings"       }),
}

-- ── MAIN TAB ──────────────────────────────────────────────
Tabs.Main:AddParagraph({
    Title   = "OmniHub — MM2 Script Suite",
    Content = "Toggle GUI: LeftControl",
})

Tabs.Main:AddToggle("SilentAimToggle", {
    Title   = "Silent Aim",
    Default = false,
    Callback = function(toggle)
        AimButton.Visible = toggle
    end,
})

-- ── VISUALS TAB ───────────────────────────────────────────
Tabs.Visuals:AddSection("Character ESP")

Tabs.Visuals:AddToggle("ESPToggle", {
    Title   = "Esp Players",
    Default = ESP.Enabled,
    Callback = function(v) ToggleESP(v) end,
})

Tabs.Visuals:AddToggle("FillToggle", {
    Title   = "Fill Highlight",
    Default = true,
    Callback = function(v)
        for _, h in pairs(Highlights) do h.FillTransparency = v and 0.85 or 1 end
    end,
})

Tabs.Visuals:AddToggle("GunDropToggle", {
    Title   = "GunDrop ESP",
    Default = true,
    Callback = function(v)
        if Highlights.GunDrop then Highlights.GunDrop.Enabled = v end
    end,
})

Tabs.Visuals:AddSection("Role Notifier")

-- Shows a popup with YOUR role at the start of each round
Tabs.Visuals:AddToggle("RoleNotifyToggle", {
    Title   = "Role Notifier",
    Default = true,
    Callback = function(v) RoleNotify:Toggle(v) end,
})

-- ── COMBAT TAB ────────────────────────────────────────────
Tabs.Combat:AddParagraph({
    Title   = "Silent Aim",
    Content = "Enable Silent Aim from the Main tab.\nDrag the aim button anywhere on screen and tap it to fire at the murderer.",
})

-- ── FARMING TAB ───────────────────────────────────────────
Tabs.Farming:AddSection("Round Timer")

-- Shows a live on-screen timer at the top of the screen
Tabs.Farming:AddToggle("RoundTimerToggle", {
    Title       = "Round Timer",
    Description = "Displays the round time remaining at the top of your screen",
    Default     = false,
    Callback    = function(v) TimerDisplay:Toggle(v) end,
})

-- ── PREMIUM TAB ───────────────────────────────────────────
Tabs.Premium:AddParagraph({
    Title   = "Premium Features",
    Content = "Premium features coming soon.\nJoin the Discord for updates.",
})

-- ── DISCORD TAB ───────────────────────────────────────────
Tabs.Discord:AddParagraph({
    Title   = "Join Our Discord",
    Content = "Join the OmniHub Discord server for updates, support, and premium access.\ndiscord.gg/omnihub",
})

-- ── SETTINGS TAB ──────────────────────────────────────────
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("OmniHub/MM2")
SaveManager:BuildConfigSection(Tabs.Settings)

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("OmniHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

------------------------------------------------------------
-- INIT
------------------------------------------------------------
local function Initialize()
    SetupRoleTracking()
    SetupGunTracking()
    SetupPlayerConnections()
    SetupRoleNotifications()   -- role notifier starts tracking immediately

    local ESPUpdateConnection = RunService.RenderStepped:Connect(UpdateESP)

    local function cleanupFunction()
        if RoleUpdateConnection    then RoleUpdateConnection:Disconnect()    end
        if PlayerAddedConnection   then PlayerAddedConnection:Disconnect()   end
        if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end
        if ESPUpdateConnection     then ESPUpdateConnection:Disconnect()     end
        if RoleNotifyConnection    then RoleNotifyConnection:Disconnect()    end
        TimerDisplay:Stop()
        for _, conn in pairs(GunTrackingConnections) do conn:Disconnect() end
        for _, highlight in pairs(Highlights) do
            if highlight and highlight.Parent then highlight:Destroy() end
        end
        if HighlightFolder and HighlightFolder.Parent then HighlightFolder:Destroy() end
    end

    if getgenv then getgenv().OmniCleanup = cleanupFunction end

    SaveManager:LoadAutoloadConfig()

    Fluent:Notify({
        Title      = "OmniHub Loaded",
        Content    = "MM2 Script v1.3 is active",
        SubContent = "By Azzakirms",
        Duration   = 3,
    })
end

startLoader(Initialize)

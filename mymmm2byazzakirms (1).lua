--------------------------LOADER--------------------------

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OmniHubLoader"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = game:GetService("CoreGui")
else
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- ─── Backdrop (full screen dark overlay) ────────────────────────────────────
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.Position = UDim2.new(0, 0, 0, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
backdrop.BorderSizePixel = 0
backdrop.BackgroundTransparency = 1
backdrop.Parent = screenGui

-- ─── Animated background grid lines ────────────────────────────────────────
local gridContainer = Instance.new("Frame")
gridContainer.Name = "GridContainer"
gridContainer.Size = UDim2.new(1, 0, 1, 0)
gridContainer.BackgroundTransparency = 1
gridContainer.ClipsDescendants = true
gridContainer.Parent = backdrop

for col = 0, 12 do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 1, 1, 0)
    line.Position = UDim2.new(col / 12, 0, 0, 0)
    line.BackgroundColor3 = Color3.fromRGB(30, 35, 60)
    line.BackgroundTransparency = 0.7
    line.BorderSizePixel = 0
    line.Parent = gridContainer
end
for row = 0, 8 do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, row / 8, 0)
    line.BackgroundColor3 = Color3.fromRGB(30, 35, 60)
    line.BackgroundTransparency = 0.7
    line.BorderSizePixel = 0
    line.Parent = gridContainer
end

-- ─── Main card ──────────────────────────────────────────────────────────────
local card = Instance.new("Frame")
card.Name = "Card"
card.Size = UDim2.new(0, 480, 0, 300)
card.Position = UDim2.new(0.5, 0, 0.5, 40)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.BackgroundColor3 = Color3.fromRGB(13, 14, 22)
card.BorderSizePixel = 0
card.BackgroundTransparency = 1
card.Parent = backdrop

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 16)
cardCorner.Parent = card

-- Glowing border ring
local borderGlow = Instance.new("UIStroke")
borderGlow.Color = Color3.fromRGB(79, 149, 255)
borderGlow.Thickness = 1.5
borderGlow.Transparency = 0.3
borderGlow.Parent = card

-- Card inner gradient
local cardGradient = Instance.new("UIGradient")
cardGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 20, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 11, 20))
})
cardGradient.Rotation = 135
cardGradient.Parent = card

-- ─── Top accent bar ─────────────────────────────────────────────────────────
local accentBar = Instance.new("Frame")
accentBar.Name = "AccentBar"
accentBar.Size = UDim2.new(0, 0, 0, 3)
accentBar.Position = UDim2.new(0, 0, 0, 0)
accentBar.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
accentBar.BorderSizePixel = 0
accentBar.BackgroundTransparency = 1
accentBar.ZIndex = 5
accentBar.Parent = card

local accentCorner = Instance.new("UICorner")
accentCorner.CornerRadius = UDim.new(0, 2)
accentCorner.Parent = accentBar

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 80, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(79, 149, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 220, 180))
})
accentGradient.Parent = accentBar

-- ─── Logo / Icon area ────────────────────────────────────────────────────────
local iconBg = Instance.new("Frame")
iconBg.Name = "IconBg"
iconBg.Size = UDim2.new(0, 72, 0, 72)
iconBg.Position = UDim2.new(0.5, 0, 0, 38)
iconBg.AnchorPoint = Vector2.new(0.5, 0)
iconBg.BackgroundColor3 = Color3.fromRGB(25, 40, 80)
iconBg.BorderSizePixel = 0
iconBg.BackgroundTransparency = 1
iconBg.ZIndex = 4
iconBg.Parent = card

local iconBgCorner = Instance.new("UICorner")
iconBgCorner.CornerRadius = UDim.new(0, 14)
iconBgCorner.Parent = iconBg

local iconBgStroke = Instance.new("UIStroke")
iconBgStroke.Color = Color3.fromRGB(79, 149, 255)
iconBgStroke.Thickness = 1.5
iconBgStroke.Transparency = 0.5
iconBgStroke.Parent = iconBg

-- Icon (shield image or text fallback)
local iconLabel = Instance.new("TextLabel")
iconLabel.Name = "IconLabel"
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "⚡"
iconLabel.TextColor3 = Color3.fromRGB(79, 149, 255)
iconLabel.TextSize = 34
iconLabel.Font = Enum.Font.GothamBold
iconLabel.TextTransparency = 1
iconLabel.ZIndex = 5
iconLabel.Parent = iconBg

-- ─── Title text ─────────────────────────────────────────────────────────────
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -40, 0, 42)
titleLabel.Position = UDim2.new(0, 20, 0, 118)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "OMNIHUB"
titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
titleLabel.TextSize = 32
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextTransparency = 1
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.LetterSpacing = 6
titleLabel.ZIndex = 4
titleLabel.Parent = card

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 220, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
titleGradient.Parent = titleLabel

-- ─── Subtitle / Version ──────────────────────────────────────────────────────
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "Subtitle"
subtitleLabel.Size = UDim2.new(1, -40, 0, 22)
subtitleLabel.Position = UDim2.new(0, 20, 0, 157)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "MM2 Script Suite  ·  v1.1.5  ·  By Azzakirms"
subtitleLabel.TextColor3 = Color3.fromRGB(120, 140, 200)
subtitleLabel.TextSize = 13
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextTransparency = 1
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
subtitleLabel.ZIndex = 4
subtitleLabel.Parent = card

-- ─── Divider line ───────────────────────────────────────────────────────────
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(0, 0, 0, 1)
divider.Position = UDim2.new(0.5, 0, 0, 188)
divider.AnchorPoint = Vector2.new(0.5, 0)
divider.BackgroundColor3 = Color3.fromRGB(50, 60, 100)
divider.BorderSizePixel = 0
divider.BackgroundTransparency = 1
divider.ZIndex = 4
divider.Parent = card

-- ─── Status text ─────────────────────────────────────────────────────────────
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, -40, 0, 20)
statusLabel.Position = UDim2.new(0, 20, 0, 201)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Initializing..."
statusLabel.TextColor3 = Color3.fromRGB(100, 130, 200)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextTransparency = 1
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 4
statusLabel.Parent = card

-- Animated dots for status
local dotsLabel = Instance.new("TextLabel")
dotsLabel.Name = "Dots"
dotsLabel.Size = UDim2.new(0, 30, 0, 20)
dotsLabel.Position = UDim2.new(1, -55, 0, 201)
dotsLabel.BackgroundTransparency = 1
dotsLabel.Text = "..."
dotsLabel.TextColor3 = Color3.fromRGB(79, 149, 255)
dotsLabel.TextSize = 12
dotsLabel.Font = Enum.Font.GothamBold
dotsLabel.TextTransparency = 1
dotsLabel.ZIndex = 4
dotsLabel.Parent = card

-- ─── Progress bar track ─────────────────────────────────────────────────────
local progressTrack = Instance.new("Frame")
progressTrack.Name = "ProgressTrack"
progressTrack.Size = UDim2.new(1, -40, 0, 6)
progressTrack.Position = UDim2.new(0, 20, 0, 232)
progressTrack.BackgroundColor3 = Color3.fromRGB(25, 30, 55)
progressTrack.BorderSizePixel = 0
progressTrack.BackgroundTransparency = 1
progressTrack.ZIndex = 4
progressTrack.Parent = card

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(0, 3)
trackCorner.Parent = progressTrack

-- Progress fill
local progressFill = Instance.new("Frame")
progressFill.Name = "Fill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
progressFill.BorderSizePixel = 0
progressFill.BackgroundTransparency = 1
progressFill.ZIndex = 5
progressFill.Parent = progressTrack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 3)
fillCorner.Parent = progressFill

local fillGradient = Instance.new("UIGradient")
fillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 80, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(79, 149, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 220, 180))
})
fillGradient.Parent = progressFill

-- Progress shimmer (moving highlight)
local shimmer = Instance.new("Frame")
shimmer.Name = "Shimmer"
shimmer.Size = UDim2.new(0, 60, 1, 0)
shimmer.Position = UDim2.new(-0.5, 0, 0, 0)
shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shimmer.BackgroundTransparency = 0.6
shimmer.BorderSizePixel = 0
shimmer.ZIndex = 6
shimmer.ClipsDescendants = false
shimmer.Parent = progressFill

local shimmerGradient = Instance.new("UIGradient")
shimmerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
shimmerGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0.6),
    NumberSequenceKeypoint.new(1, 1)
})
shimmerGradient.Rotation = 0
shimmerGradient.Parent = shimmer

-- ─── Percent label ───────────────────────────────────────────────────────────
local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "Percent"
percentLabel.Size = UDim2.new(0, 50, 0, 20)
percentLabel.Position = UDim2.new(1, -50, 0, 225)
percentLabel.BackgroundTransparency = 1
percentLabel.Text = "0%"
percentLabel.TextColor3 = Color3.fromRGB(79, 149, 255)
percentLabel.TextSize = 11
percentLabel.Font = Enum.Font.GothamBold
percentLabel.TextTransparency = 1
percentLabel.TextXAlignment = Enum.TextXAlignment.Right
percentLabel.ZIndex = 4
percentLabel.Parent = card

-- ─── Bottom tag line ─────────────────────────────────────────────────────────
local tagLabel = Instance.new("TextLabel")
tagLabel.Name = "Tag"
tagLabel.Size = UDim2.new(1, -40, 0, 18)
tagLabel.Position = UDim2.new(0, 20, 0, 265)
tagLabel.BackgroundTransparency = 1
tagLabel.Text = "Secure  ·  Fast  ·  Undetected"
tagLabel.TextColor3 = Color3.fromRGB(50, 65, 110)
tagLabel.TextSize = 11
tagLabel.Font = Enum.Font.Gotham
tagLabel.TextTransparency = 1
tagLabel.TextXAlignment = Enum.TextXAlignment.Center
tagLabel.ZIndex = 4
tagLabel.Parent = card

-- ─── Helper: smooth tween wrapper ────────────────────────────────────────────
local function tween(inst, props, t, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    local ti = TweenInfo.new(t or 0.4, style, dir)
    TweenService:Create(inst, ti, props):Play()
end

local function tweenAwait(inst, props, t, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    local ti = TweenInfo.new(t or 0.4, style, dir)
    local tw = TweenService:Create(inst, ti, props)
    tw:Play()
    tw.Completed:Wait()
end

-- ─── Dot animation coroutine ─────────────────────────────────────────────────
local dotsRunning = true
local dotsCoro = coroutine.wrap(function()
    local patterns = {".", "..", "...", ".."}
    local i = 1
    while dotsRunning do
        dotsLabel.Text = patterns[i]
        i = (i % #patterns) + 1
        task.wait(0.4)
    end
end)

-- ─── Icon pulse loop ─────────────────────────────────────────────────────────
local iconPulseRunning = true
local iconPulseCoro = coroutine.wrap(function()
    while iconPulseRunning do
        tween(iconBgStroke, {Transparency = 0}, 0.8, Enum.EasingStyle.Sine)
        task.wait(0.9)
        tween(iconBgStroke, {Transparency = 0.7}, 0.8, Enum.EasingStyle.Sine)
        task.wait(0.9)
    end
end)

-- ─── Shimmer loop ────────────────────────────────────────────────────────────
local shimmerRunning = true
local function runShimmer()
    task.spawn(function()
        while shimmerRunning do
            shimmer.Position = UDim2.new(-0.3, 0, 0, 0)
            tween(shimmer, {Position = UDim2.new(1.3, 0, 0, 0)}, 1.2, Enum.EasingStyle.Linear)
            task.wait(2.2)
        end
    end)
end

-- ─── Set progress ────────────────────────────────────────────────────────────
local function setProgress(pct, label)
    if label then statusLabel.Text = label end
    percentLabel.Text = math.floor(pct * 100) .. "%"
    tweenAwait(progressFill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.55, Enum.EasingStyle.Quart)
end

-- ─── Main loader sequence ────────────────────────────────────────────────────
local function startLoader()
    -- Phase 1: Fade in backdrop
    tweenAwait(backdrop, {BackgroundTransparency = 0}, 0.35)

    -- Phase 2: Card slides in + fades
    tween(card, {
        BackgroundTransparency = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.wait(0.15)

    -- Phase 3: Accent bar sweeps across
    tween(accentBar, {BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 3)}, 0.5, Enum.EasingStyle.Quart)
    task.wait(0.3)

    -- Phase 4: Icon appears with bounce
    tween(iconBg, {BackgroundTransparency = 0}, 0.4, Enum.EasingStyle.Back)
    tween(iconLabel, {TextTransparency = 0}, 0.4)
    task.wait(0.35)

    -- Phase 5: Text elements fade in staggered
    tween(titleLabel, {TextTransparency = 0}, 0.4)
    task.wait(0.1)
    tween(subtitleLabel, {TextTransparency = 0}, 0.4)
    task.wait(0.15)
    tween(divider, {BackgroundTransparency = 0, Size = UDim2.new(0.7, 0, 0, 1)}, 0.45, Enum.EasingStyle.Quart)
    task.wait(0.2)

    -- Phase 6: Progress elements
    tween(progressTrack, {BackgroundTransparency = 0}, 0.3)
    tween(progressFill, {BackgroundTransparency = 0}, 0.3)
    tween(statusLabel, {TextTransparency = 0}, 0.3)
    tween(dotsLabel, {TextTransparency = 0}, 0.3)
    tween(percentLabel, {TextTransparency = 0}, 0.3)
    tween(tagLabel, {TextTransparency = 0.4}, 0.5)
    task.wait(0.4)

    -- Start loops
    dotsCoro()
    iconPulseCoro()
    runShimmer()

    -- ─── Loading steps ───────────────────────────────────────────────────────
    local steps = {
        {pct = 0.15, text = "Checking modules"},
        {pct = 0.32, text = "Verifying script integrity"},
        {pct = 0.50, text = "Fetching player data"},
        {pct = 0.65, text = "Loading ESP system"},
        {pct = 0.80, text = "Configuring combat modules"},
        {pct = 0.92, text = "Applying settings"},
        {pct = 1.00, text = "Ready"},
    }

    for _, step in ipairs(steps) do
        setProgress(step.pct, step.text)
        task.wait(0.45 + math.random() * 0.25)
    end

    dotsRunning  = false
    iconPulseRunning = false
    shimmerRunning = false
    dotsLabel.Text = "✓"
    tween(dotsLabel, {TextColor3 = Color3.fromRGB(0, 220, 140)}, 0.3)
    tween(borderGlow, {Color = Color3.fromRGB(0, 220, 140), Transparency = 0.1}, 0.5)
    task.wait(0.7)

    -- ─── Outro: card slides out + fades ────────────────────────────────────
    tween(tagLabel, {TextTransparency = 1}, 0.25)
    tween(statusLabel, {TextTransparency = 1}, 0.25)
    tween(dotsLabel, {TextTransparency = 1}, 0.25)
    tween(percentLabel, {TextTransparency = 1}, 0.25)
    tween(progressTrack, {BackgroundTransparency = 1}, 0.25)
    tween(progressFill, {BackgroundTransparency = 1}, 0.25)
    task.wait(0.15)
    tween(divider, {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 1)}, 0.3)
    tween(subtitleLabel, {TextTransparency = 1}, 0.3)
    tween(titleLabel, {TextTransparency = 1}, 0.3)
    tween(iconLabel, {TextTransparency = 1}, 0.3)
    tween(iconBg, {BackgroundTransparency = 1}, 0.3)
    task.wait(0.25)
    tween(accentBar, {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 3)}, 0.35)
    tween(card, {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, -30)
    }, 0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.wait(0.4)
    tweenAwait(backdrop, {BackgroundTransparency = 1}, 0.35)

    screenGui:Destroy()
end

task.spawn(startLoader)

------------------------------------------------------------
-- Core Services
------------------------------------------------------------
local Players       = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui       = game:GetService("CoreGui")
local LocalPlayer   = Players.LocalPlayer
local Camera        = workspace.CurrentCamera

-- ─── New Remote Paths ────────────────────────────────────────────────────────
local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local RemExtras     = Remotes:WaitForChild("Extras")
local RemGameplay   = Remotes:WaitForChild("Gameplay")

local GetChanceRemote    = RemExtras:WaitForChild("GetChance")
local GetTimerRemote     = RemExtras:WaitForChild("GetTimer")
local GetPlayerDataRemote= RemExtras:WaitForChild("GetPlayerData")
local RoundStartRemote   = RemGameplay:WaitForChild("RoundStart")

-- Role GUI path (local player)
local function GetRoleSelectGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local main = pg:FindFirstChild("MainGUI")
    if not main then return nil end
    local gameplay = main:FindFirstChild("Gameplay")
    if not gameplay then return nil end
    return gameplay:FindFirstChild("RoleSelect")
end

-- ─── Game-specific state tracking ──────────────────────────────────────────
local roles = {}
local Murder, Sheriff, Hero = nil, nil, nil
local GunDrop = nil

-- ─── ESP Configuration ───────────────────────────────────────────────────────
local ESP = {
    Enabled = true,
    MaxRenderDistance = 175,
    Colors = {
        Murderer = Color3.fromRGB(255, 0, 0),
        Sheriff  = Color3.fromRGB(0, 100, 255),
        Hero     = Color3.fromRGB(255, 215, 0),
        Innocent = Color3.fromRGB(50, 255, 100),
        GunDrop  = Color3.fromRGB(255, 255, 50)
    }
}

local HighlightFolder = Instance.new("Folder")
HighlightFolder.Name = "ESP_Highlights"
if syn and syn.protect_gui then
    syn.protect_gui(HighlightFolder)
end
HighlightFolder.Parent = CoreGui

local Highlights = {}

------------------------------------------------------------
-- Role helpers
------------------------------------------------------------
function IsAlive(Player)
    for i, v in pairs(roles) do
        if Player.Name == i then
            return not (v.Killed or v.Dead)
        end
    end
    return false
end

------------------------------------------------------------
-- Role tracking (updated path)
------------------------------------------------------------
local RoleUpdateConnection = nil
local function SetupRoleTracking()
    if RoleUpdateConnection then
        RoleUpdateConnection:Disconnect()
        RoleUpdateConnection = nil
    end

    RoleUpdateConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            -- Primary: server remote
            local data = GetPlayerDataRemote:InvokeServer()
            if data then
                roles = data
                for i, v in pairs(roles) do
                    if     v.Role == "Murderer" then Murder  = i
                    elseif v.Role == "Sheriff"  then Sheriff = i
                    elseif v.Role == "Hero"     then Hero    = i
                    end
                end
            end

            -- Secondary: read local player role from GUI
            local roleGui = GetRoleSelectGui()
            if roleGui then
                local roleText = roleGui:FindFirstChildWhichIsA("TextLabel")
                if roleText then
                    local txt = roleText.Text:lower()
                    if txt:find("murder") then
                        Murder = LocalPlayer.Name
                    elseif txt:find("sheriff") then
                        Sheriff = LocalPlayer.Name
                    elseif txt:find("hero") then
                        Hero = LocalPlayer.Name
                    end
                end
            end
        end)
    end)
end

-- Listen for round start to reset role state
RoundStartRemote.OnClientEvent:Connect(function()
    roles   = {}
    Murder  = nil
    Sheriff = nil
    Hero    = nil
end)

------------------------------------------------------------
-- Gun tracking
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
-- ESP helpers
------------------------------------------------------------
local function GetPlayerColor(name)
    if name == Murder  then return ESP.Colors.Murderer
    elseif name == Sheriff then return ESP.Colors.Sheriff
    elseif name == Hero    then return ESP.Colors.Hero
    else return ESP.Colors.Innocent end
end

local function CreateOutline(player)
    if not player or not player.Parent then return nil end
    if Highlights[player] then return Highlights[player] end

    local h = Instance.new("Highlight")
    h.Name                = player.Name
    h.FillTransparency    = 0.85
    h.FillColor           = GetPlayerColor(player.Name)
    h.OutlineColor        = GetPlayerColor(player.Name)
    h.OutlineTransparency = 0
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.Enabled             = ESP.Enabled
    h.Parent              = HighlightFolder

    if player.Name == Murder then
        local ti = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        TweenService:Create(h, ti, {OutlineTransparency = 0.4}):Play()
    end

    Highlights[player] = h
    return h
end

local function RemoveOutline(player)
    local h = Highlights[player]
    if h then h:Destroy(); Highlights[player] = nil end
end

local function UpdateESP()
    for player, highlight in pairs(Highlights) do
        if type(player) == "table" and player:IsA("Player") then
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

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
        if distance > ESP.MaxRenderDistance then
            if Highlights[player] then Highlights[player].Enabled = false end
            continue
        end

        local h = CreateOutline(player)
        if h then
            h.Adornee      = character
            h.FillColor    = GetPlayerColor(player.Name)
            h.OutlineColor = GetPlayerColor(player.Name)
            h.Enabled      = true
        end
    end

    -- GunDrop ESP
    if GunDrop and GunDrop.Parent then
        if not Highlights.GunDrop then
            local h = Instance.new("Highlight")
            h.Name                = "GunDrop"
            h.FillTransparency    = 0.5
            h.FillColor           = ESP.Colors.GunDrop
            h.OutlineColor        = ESP.Colors.GunDrop
            h.OutlineTransparency = 0
            h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
            h.Enabled             = ESP.Enabled
            h.Parent              = HighlightFolder
            Highlights.GunDrop    = h
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
-- Player connection setup
------------------------------------------------------------
local PlayerAddedConnection   = nil
local PlayerRemovingConnection = nil

local function SetupPlayerConnections()
    if PlayerAddedConnection   then PlayerAddedConnection:Disconnect()   end
    if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end

    PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
        task.delay(1, function()
            if not player or not player.Parent then return end
            if player.Character then UpdateESP() end
            player.CharacterAdded:Connect(function()
                task.delay(0.5, UpdateESP)
            end)
        end)
    end)

    PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        RemoveOutline(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                task.delay(0.5, UpdateESP)
            end)
        end
    end
end

------------------------------------------------------------
-- Silent Aim – predicted position
------------------------------------------------------------
local function getPredictedPosition(murderer)
    local character = murderer.Character
    if not character then return nil end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    local head     = character:FindFirstChild("Head")
    if not rootPart or not humanoid then return nil end

    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    local fps  = 1 / RunService.RenderStepped:Wait()
    local pingCompensation = math.clamp(ping / 1000, 0.08, 0.35)
    local timeSkip = pingCompensation * (60 / math.clamp(fps, 30, 120))

    local state      = humanoid:GetState()
    local isAirborne = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
    local currentVelocity = rootPart.AssemblyLinearVelocity
    local moveDirection   = humanoid.MoveDirection
    local moveSpeed       = humanoid.WalkSpeed
    local position        = rootPart.Position
    local gravity         = workspace.Gravity
    local terminalVelocity = -100
    local groundFriction  = 0.8
    local airResistance   = 0.02
    local jumpDecay       = 0.86

    if not _G.velocityHistory then _G.velocityHistory = {} end
    if not _G.velocityHistory[murderer.UserId] then
        _G.velocityHistory[murderer.UserId] = {
            positions = {}, velocities = {}, timestamps = {}, lastJumpTime = 0
        }
    end

    local history = _G.velocityHistory[murderer.UserId]
    table.insert(history.positions,  position)
    table.insert(history.velocities, currentVelocity)
    table.insert(history.timestamps, tick())

    if #history.positions > 10 then
        table.remove(history.positions,  1)
        table.remove(history.velocities, 1)
        table.remove(history.timestamps, 1)
    end

    local acceleration = Vector3.new(0, 0, 0)
    if #history.velocities >= 3 then
        local v2 = history.velocities[#history.velocities]
        local v1 = history.velocities[#history.velocities - 2]
        local t2 = history.timestamps[#history.timestamps]
        local t1 = history.timestamps[#history.timestamps - 2]
        local dt = t2 - t1
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
    local subSteps = 5
    local subTimeSkip = timeSkip / subSteps

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}

    for _ = 1, subSteps do
        local targetGroundVelocity = moveDirection * moveSpeed
        local horizontalVelocity  = Vector3.new(predictedVelocity.X, 0, predictedVelocity.Z)

        if moveDirection.Magnitude > 0.1 then
            local velocityDiff = targetGroundVelocity - horizontalVelocity
            local accelFactor  = isAirborne and 0.6 or 1.0
            horizontalVelocity = horizontalVelocity + velocityDiff * accelFactor * subTimeSkip * 10
        else
            horizontalVelocity = horizontalVelocity * (1 - (isAirborne and airResistance or groundFriction) * subTimeSkip * 10)
        end

        local verticalVelocity = predictedVelocity.Y
        if isAirborne then
            verticalVelocity = math.max(verticalVelocity - gravity * subTimeSkip, terminalVelocity)
        else
            verticalVelocity = verticalVelocity * jumpDecay
            if jumpPrediction > 0 then
                verticalVelocity = jumpPrediction
                jumpPrediction   = 0
            end
        end

        predictedVelocity   = Vector3.new(horizontalVelocity.X, verticalVelocity, horizontalVelocity.Z) + acceleration * subTimeSkip
        predictedPosition   = predictedPosition + predictedVelocity * subTimeSkip

        local floorRay = workspace:Raycast(predictedPosition, Vector3.new(0, -humanoid.HipHeight - 0.5, 0), raycastParams)
        if floorRay then
            predictedPosition = Vector3.new(predictedPosition.X, floorRay.Position.Y + humanoid.HipHeight, predictedPosition.Z)
            if predictedVelocity.Y < 0 then
                predictedVelocity = Vector3.new(predictedVelocity.X, 0, predictedVelocity.Z)
            end
        end

        for _, direction in pairs({Vector3.new(1,0,0), Vector3.new(-1,0,0), Vector3.new(0,0,1), Vector3.new(0,0,-1)}) do
            local wallRay = workspace:Raycast(predictedPosition, direction * 2, raycastParams)
            if wallRay then
                local normal      = wallRay.Normal
                local penetration = 2 - wallRay.Distance
                predictedPosition = predictedPosition + normal * penetration
                local dot = predictedVelocity:Dot(normal)
                if dot < 0 then
                    predictedVelocity = (predictedVelocity - 2 * dot * normal) * 0.8
                end
            end
        end
    end

    if head then
        local headOffset = (head.Position - rootPart.Position) * 0.8
        predictedPosition = predictedPosition + Vector3.new(0, headOffset.Y, 0)
    end

    if currentVelocity.Magnitude > moveSpeed * 1.5 then
        predictedPosition = predictedPosition + currentVelocity.Unit * currentVelocity.Magnitude * timeSkip * 0.5
    end

    if ping > 150 then
        predictedPosition = predictedPosition + predictedVelocity * (ping / 1000) * 0.3
    end

    return predictedPosition
end

local function GetMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Knife") then return player end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Backpack and player.Backpack:FindFirstChild("Knife") then return player end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("Role") == "Murderer" then return player end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local animator = player.Character.Humanoid:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                    if track.Animation.Name:lower():match("knife") or track.Animation.Name:lower():match("stab") then
                        return player
                    end
                end
            end
        end
    end
    return nil
end

------------------------------------------------------------
-- Fluent UI
------------------------------------------------------------
local Fluent          = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager     = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager= loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title        = "OmniHub Script By Azzakirms",
    SubTitle     = "V1.1.5",
    TabWidth     = 100,
    Size         = UDim2.fromOffset(380, 300),
    Acrylic      = true,
    Theme        = "Dark",
    MinimizeKey  = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main     = Window:AddTab({ Title = "Main",        Icon = "eye"           }),
    Visuals  = Window:AddTab({ Title = "Visuals",     Icon = "camera"        }),
    Combat   = Window:AddTab({ Title = "Combat",      Icon = "crosshair"     }),
    Farming  = Window:AddTab({ Title = "Farming",     Icon = "dollar-sign"   }),
    Premium  = Window:AddTab({ Title = "Premium",     Icon = "star"          }),
    Discord  = Window:AddTab({ Title = "Join Discord",Icon = "message-square"}),
    Settings = Window:AddTab({ Title = "Settings",    Icon = "settings"      })
}

-- ─── Visuals Tab ─────────────────────────────────────────────────────────────
Tabs.Visuals:AddSection("Character ESP")
Tabs.Visuals:AddToggle("ESPToggle", {
    Title    = "Esp Players",
    Default  = ESP.Enabled,
    Callback = function(Value) ToggleESP(Value) end
})

-- ─── Main Tab – Silent Aim ───────────────────────────────────────────────────
local AimGui    = Instance.new("ScreenGui")
local AimButton = Instance.new("ImageButton")
AimGui.Parent             = game.CoreGui
AimButton.Parent          = AimGui
AimButton.BackgroundColor3= Color3.fromRGB(50, 50, 50)
AimButton.BackgroundTransparency = 0.3
AimButton.BorderColor3    = Color3.fromRGB(255, 100, 0)
AimButton.BorderSizePixel = 2
AimButton.Position        = UDim2.new(0.897, 0, 0.3, 0)
AimButton.Size            = UDim2.new(0.1, 0, 0.2, 0)
AimButton.Image           = "rbxassetid://11162755592"
AimButton.Draggable       = true
AimButton.Visible         = false

local UIStroke = Instance.new("UIStroke", AimButton)
UIStroke.Color       = Color3.fromRGB(255, 100, 0)
UIStroke.Thickness   = 2
UIStroke.Transparency= 0.5

Tabs.Main:AddToggle("SilentAimToggle", {
    Title    = "Silent Aim",
    Default  = false,
    Callback = function(toggle) AimButton.Visible = toggle end
})

AimButton.MouseButton1Click:Connect(function()
    local gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if not gun then return end

    local murderer = GetMurderer()
    if not murderer then return end

    LocalPlayer.Character.Humanoid:EquipTool(gun)

    local predictedPos = getPredictedPosition(murderer)
    if predictedPos then
        -- Updated remote path for gun firing
        local shootRemote = gun:FindFirstChild("ShootEvent", true) or gun:FindFirstChildWhichIsA("RemoteEvent", true) or gun:FindFirstChildWhichIsA("RemoteFunction", true)
        if shootRemote then
            if shootRemote:IsA("RemoteFunction") then
                shootRemote:InvokeServer(1, predictedPos, "AH2")
            elseif shootRemote:IsA("RemoteEvent") then
                shootRemote:FireServer(1, predictedPos, "AH2")
            end
        end
    end
end)

-- ─── Farming Tab ─────────────────────────────────────────────────────────────
Tabs.Farming:AddSection("Round Info")

Tabs.Farming:AddButton({
    Title    = "Get Chance Info",
    Content  = "Fetch current chance data from server",
    Callback = function()
        local success, result = pcall(function()
            return GetChanceRemote:InvokeServer()
        end)
        if success and result then
            Fluent:Notify({
                Title   = "Chance Info",
                Content = tostring(result),
                Duration= 5
            })
        end
    end
})

Tabs.Farming:AddButton({
    Title    = "Get Round Timer",
    Content  = "Fetch the current round timer",
    Callback = function()
        local success, result = pcall(function()
            return GetTimerRemote:InvokeServer()
        end)
        if success and result then
            Fluent:Notify({
                Title   = "Round Timer",
                Content = "Time remaining: " .. tostring(result) .. "s",
                Duration= 4
            })
        end
    end
})

-- ─── Settings Tab ────────────────────────────────────────────────────────────
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("OmniHub/MM2")
SaveManager:BuildConfigSection(Tabs.Settings)

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("OmniHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

------------------------------------------------------------
-- Initialize
------------------------------------------------------------
local function Initialize()
    SetupRoleTracking()
    SetupGunTracking()
    SetupPlayerConnections()

    local ESPUpdateConnection = RunService.RenderStepped:Connect(UpdateESP)

    local cleanupFunction = function()
        if RoleUpdateConnection    then RoleUpdateConnection:Disconnect()    end
        if PlayerAddedConnection   then PlayerAddedConnection:Disconnect()   end
        if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end
        if ESPUpdateConnection     then ESPUpdateConnection:Disconnect()     end

        for _, conn in pairs(GunTrackingConnections) do conn:Disconnect() end

        for _, highlight in pairs(Highlights) do
            if highlight and highlight.Parent then highlight:Destroy() end
        end
        if HighlightFolder and HighlightFolder.Parent then
            HighlightFolder:Destroy()
        end
    end

    if getgenv then getgenv().ESPCleanupFunction = cleanupFunction end

    Fluent:Notify({
        Title    = "OmniHub Loaded",
        Content  = "ESP & modules are active",
        Duration = 3
    })

    SaveManager:LoadAutoloadConfig()
end

Initialize()

-- Ultra-Optimized Character Outline ESP for MM2
-- Core Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Game-specific state tracking
local roles = {}
local Murder, Sheriff, Hero = nil, nil, nil
local GunDrop = nil

-- ESP Configuration
local ESP = {
   Enabled = true,
   OutlineThickness = 3,
   MaxRenderDistance = 300,
   Colors = {
       Murderer = Color3.fromRGB(255, 0, 0),
       Sheriff = Color3.fromRGB(0, 100, 255),
       Hero = Color3.fromRGB(255, 215, 0),
       Innocent = Color3.fromRGB(50, 255, 100),
       GunDrop = Color3.fromRGB(255, 255, 50)
   }
}

-- FIX: Use proper container instance for client-side rendering
local HighlightFolder = Instance.new("Folder")
HighlightFolder.Name = "ESP_Highlights"
-- Use proper parent for client-side UI elements
if syn and syn.protect_gui then
    syn.protect_gui(HighlightFolder)
    HighlightFolder.Parent = game:GetService("CoreGui")
else
    HighlightFolder.Parent = CoreGui
end

-- Highlight object container with strict typing
local Highlights = {}

-- Game mechanics functions
function IsAlive(Player)
   for i, v in pairs(roles) do
       if Player.Name == i then
           return not (v.Killed or v.Dead)
       end
   end
   return false
end

-- FIX: Reliable role tracking with connection management
local RoleUpdateConnection = nil
local function SetupRoleTracking()
    -- Clear previous connection if it exists
    if RoleUpdateConnection then
        RoleUpdateConnection:Disconnect()
        RoleUpdateConnection = nil
    end
    
    -- Create new connection with proper error handling
    RoleUpdateConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            if ReplicatedStorage:FindFirstChild("GetPlayerData", true) then
                roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
                for i, v in pairs(roles) do
                    if v.Role == "Murderer" then Murder = i
                    elseif v.Role == "Sheriff" then Sheriff = i
                    elseif v.Role == "Hero" then Hero = i end
                end
            end
        end)
    end)
end

-- FIX: Reliable gun tracking
local GunTrackingConnections = {}
local function SetupGunTracking()
    -- Clear previous connections
    for _, conn in pairs(GunTrackingConnections) do
        conn:Disconnect()
    end
    table.clear(GunTrackingConnections)
    
    -- Check for existing gun drop
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name == "GunDrop" then
            GunDrop = item
            break
        end
    end
    
    -- Setup new connections
    GunTrackingConnections[1] = workspace.ChildAdded:Connect(function(child)
        if child.Name == "GunDrop" then GunDrop = child end
    end)
    
    GunTrackingConnections[2] = workspace.ChildRemoved:Connect(function(child)
        if child == GunDrop then GunDrop = nil end
    end)
end

-- Get role color mapping
local function GetPlayerColor(playerName)
   if playerName == Murder then return ESP.Colors.Murderer
   elseif playerName == Sheriff then return ESP.Colors.Sheriff
   elseif playerName == Hero then return ESP.Colors.Hero
   else return ESP.Colors.Innocent end
end

-- FIX: Create optimized character outline with proper error handling
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
   
   -- Apply pulsing effect to murderer for improved visibility
   if player.Name == Murder then
       local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
       local tween = TweenService:Create(highlight, tweenInfo, {OutlineTransparency = 0.4})
       tween:Play()
   end
   
   Highlights[player] = highlight
   return highlight
end

-- FIX: Reliable outline removal with proper cleanup
local function RemoveOutline(player)
   local highlight = Highlights[player]
   if highlight then
       highlight:Destroy()
       Highlights[player] = nil
   end
end

-- FIX: Enhanced ESP update function with proper validation
local function UpdateESP()
   -- Update highlights based on ESP.Enabled state
   for player, highlight in pairs(Highlights) do
       if type(player) == "table" and player:IsA("Player") then
           highlight.Enabled = ESP.Enabled
       end
   end
   
   -- Exit early if disabled
   if not ESP.Enabled then return end
   
   -- Update ESP for each player
   for _, player in ipairs(Players:GetPlayers()) do
       if player == LocalPlayer then continue end
       
       local character = player.Character
       if not character or not character:FindFirstChild("HumanoidRootPart") or not IsAlive(player) then
           if Highlights[player] then
               Highlights[player].Enabled = false
           end
           continue
       end
       
       -- Distance check for optimization
       local rootPart = character:FindFirstChild("HumanoidRootPart")
       local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
       
       if distance > ESP.MaxRenderDistance then
           if Highlights[player] then
               Highlights[player].Enabled = false
           end
           continue
       end
       
       -- Create or update outline
       local highlight = CreateOutline(player)
       if highlight then
           highlight.Adornee = character
           highlight.FillColor = GetPlayerColor(player.Name)
           highlight.OutlineColor = GetPlayerColor(player.Name)
           highlight.Enabled = true
       end
   end
   
   -- Gun Drop ESP handling
   if GunDrop and GunDrop.Parent then
       if not Highlights.GunDrop then
           local highlight = Instance.new("Highlight")
           highlight.Name = "GunDrop"
           highlight.FillTransparency = 0.5
           highlight.FillColor = ESP.Colors.GunDrop
           highlight.OutlineColor = ESP.Colors.GunDrop
           highlight.OutlineTransparency = 0
           highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
           highlight.Enabled = ESP.Enabled
           highlight.Parent = HighlightFolder
           
           Highlights.GunDrop = highlight
       end
       Highlights.GunDrop.Adornee = GunDrop
   elseif Highlights.GunDrop then
       Highlights.GunDrop:Destroy()
       Highlights.GunDrop = nil
   end
end

-- FIX: Enhanced player joining/leaving handlers
local PlayerAddedConnection = nil
local PlayerRemovingConnection = nil

local function SetupPlayerConnections()
    -- Clear previous connections
    if PlayerAddedConnection then PlayerAddedConnection:Disconnect() end
    if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end
    
    -- Setup new connections
    PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
        -- Force update highlights on player join
        task.delay(1, function()
            if not player or not player.Parent then return end
            if player.Character then
                UpdateESP()
            end
            
            player.CharacterAdded:Connect(function()
                task.delay(0.5, UpdateESP) -- Update after character loads
            end)
        end)
    end)
    
    PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        RemoveOutline(player)
    end)
    
    -- Setup character connections for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                task.delay(0.5, UpdateESP) -- Update after character loads
            end)
        end
    end
end

-- FIX: ESP Toggle function with proper state management
local function ToggleESP(state)
    ESP.Enabled = state
    
    -- Update all existing highlights
    for player, highlight in pairs(Highlights) do
        highlight.Enabled = state
    end
    
    -- Force immediate update
    if state then
        UpdateESP()
    end
end




-- Round Timer Module
local TimerDisplay = {
   Enabled = true,
   RefreshRate = 0.1, -- Timer update frequency
   TimerConnection = nil,
   TimerUI = nil
}

-- Cache services
local timerRemote = game:GetService("ReplicatedStorage").Remotes.Extras.GetTimer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Create UI elements for round timer
function TimerDisplay:Create()
   if self.TimerUI then return end
   
   -- Create container frame
   local timerFrame = Instance.new("ScreenGui")
   timerFrame.Name = "RoundTimerDisplay"
   timerFrame.ResetOnSpawn = false
   timerFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
   
   -- Protect GUI from detection (if exploit supports it)
   if syn and syn.protect_gui then
       syn.protect_gui(timerFrame)
       timerFrame.Parent = game:GetService("CoreGui")
   else
       timerFrame.Parent = game:GetService("CoreGui")
   end
   
   -- Create timer container
   local container = Instance.new("Frame")
   container.Name = "TimerContainer"
   container.Size = UDim2.new(0, 150, 0, 40)
   container.Position = UDim2.new(0.5, -75, 0, 10) -- Top center
   container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
   container.BackgroundTransparency = 0.2
   container.BorderSizePixel = 0
   container.Parent = timerFrame
   
   -- Add rounded corners
   local cornerRadius = Instance.new("UICorner")
   cornerRadius.CornerRadius = UDim.new(0, 6)
   cornerRadius.Parent = container
   
   -- Add drop shadow
   local shadow = Instance.new("ImageLabel")
   shadow.Name = "Shadow"
   shadow.AnchorPoint = Vector2.new(0.5, 0.5)
   shadow.BackgroundTransparency = 1
   shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
   shadow.Size = UDim2.new(1, 10, 1, 10)
   shadow.ZIndex = -1
   shadow.Image = "rbxassetid://5554236805"
   shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
   shadow.ImageTransparency = 0.4
   shadow.ScaleType = Enum.ScaleType.Slice
   shadow.SliceCenter = Rect.new(23, 23, 277, 277)
   shadow.Parent = container
   
   -- Create title label
   local titleLabel = Instance.new("TextLabel")
   titleLabel.Name = "TitleLabel"
   titleLabel.Size = UDim2.new(1, 0, 0, 18)
   titleLabel.BackgroundTransparency = 1
   titleLabel.Text = "ROUND TIME"
   titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
   titleLabel.TextSize = 12
   titleLabel.Font = Enum.Font.GothamBold
   titleLabel.Parent = container
   
   -- Create timer text
   local timerText = Instance.new("TextLabel")
   timerText.Name = "TimerText"
   timerText.Size = UDim2.new(1, 0, 0, 22)
   timerText.Position = UDim2.new(0, 0, 0, 18)
   timerText.BackgroundTransparency = 1
   timerText.Text = "--:--"
   timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
   timerText.TextSize = 18
   timerText.Font = Enum.Font.GothamSemibold
   timerText.Parent = container
   
   -- Store reference
   self.TimerUI = {
       ScreenGui = timerFrame,
       Container = container,
       TimerLabel = timerText
   }
   
   return self.TimerUI
end

-- Format time from seconds to MM:SS
local function FormatTime(seconds)
   if not seconds or type(seconds) ~= "number" then return "--:--" end
   
   seconds = math.max(0, math.floor(seconds))
   local minutes = math.floor(seconds / 60)
   seconds = seconds % 60
   
   return string.format("%02d:%02d", minutes, seconds)
end

-- Update timer display
function TimerDisplay:Update()
   if not self.TimerUI or not self.Enabled then return end
   
   -- Get current round time from remote
   local success, timeLeft = pcall(function()
       return timerRemote:InvokeServer()
   end)
   
   if success and timeLeft then
       -- Format and display time
       self.TimerUI.TimerLabel.Text = FormatTime(timeLeft)
       
       -- Add warning effect when time is running out
       if timeLeft <= 10 then
           self.TimerUI.TimerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
           
           -- Create pulsing effect for urgency
           if not self.PulsingTween then
               local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
               self.PulsingTween = TweenService:Create(
                   self.TimerUI.TimerLabel, 
                   tweenInfo, 
                   {TextSize = 22}
               )
               self.PulsingTween:Play()
           end
       else
           -- Reset to normal state
           self.TimerUI.TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
           if self.PulsingTween then
               self.PulsingTween:Cancel()
               self.PulsingTween = nil
               self.TimerUI.TimerLabel.TextSize = 18
           end
       end
   else
       -- Handle error state
       self.TimerUI.TimerLabel.Text = "--:--"
   end
end

-- Start timer updates
function TimerDisplay:Start()
   self:Create()
   
   -- Clean up existing connection
   if self.TimerConnection then
       self.TimerConnection:Disconnect()
       self.TimerConnection = nil
   end
   
   -- Create new update loop
   self.TimerConnection = RunService.Heartbeat:Connect(function()
       task.wait(self.RefreshRate)
       self:Update()
   end)
   
   -- Show UI
   if self.TimerUI then
       self.TimerUI.ScreenGui.Enabled = true
   end
end

-- Stop timer updates
function TimerDisplay:Stop()
   if self.TimerConnection then
       self.TimerConnection:Disconnect()
       self.TimerConnection = nil
   end
   
   -- Hide UI
   if self.TimerUI then
       self.TimerUI.ScreenGui.Enabled = false
   end
end

-- Toggle timer visibility
function TimerDisplay:Toggle(state)
   self.Enabled = state
   
   if state then
       self:Start()
   else
       self:Stop()
   end
end

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
       PREDICTION_WINDOW = 2.5,
       SAMPLE_COUNT = 45,
       PATTERN_DEPTH = 5,
       GROUND_OFFSET = 5,
       MAX_SPEED_MULTIPLIER = 1.5
   }

   local PROBABILITY = {
       VELOCITY_WEIGHT = 0.92,
       PATTERN_WEIGHT = 0.88,
       MOMENTUM_WEIGHT = 0.85,
       DIRECTION_WEIGHT = 0.90,
       GROUND_WEIGHT = 0.95,
       AIR_WEIGHT = 0.82,
       CONFIDENCE_DECAY = 0.98,
       MIN_CONFIDENCE = 0.85
   }

   local MOVEMENT = {
       GROUND_FRICTION = {
           LINEAR = 0.92,
           ANGULAR = 0.94,
           SURFACE = 0.96
       },
       AIR_RESISTANCE = {
           LINEAR = 0.985,
           ANGULAR = 0.975,
           TURBULENCE = 0.15
       },
       MOMENTUM = {
           CONSERVATION = 0.95,
           TRANSFER = 0.88,
           DECAY = 0.94
       }
   }

   local state = {
       position = rootPart.Position,
       velocity = rootPart.AssemblyLinearVelocity,
       velocityHistory = table.create(PHYSICS.SAMPLE_COUNT),
       positionHistory = table.create(PHYSICS.SAMPLE_COUNT),
       patterns = {},
       groundContact = true,
       lastJumpTime = 0,
       confidenceScore = 1.0,
       predictionAccuracy = 1.0,
       lastCalculationTime = tick()
   }

   local function initializeHistoricalData()
       for i = 1, PHYSICS.SAMPLE_COUNT do
           state.velocityHistory[i] = state.velocity
           state.positionHistory[i] = state.position
       end
   end
   initializeHistoricalData()

   local function analyzeMovementPatterns()
       local patterns = {}
       local totalWeight = 0
       
       for depth = 1, PHYSICS.PATTERN_DEPTH do
           local pattern = Vector3.new()
           local weight = 1 / depth
           
           for i = depth + 1, #state.positionHistory do
               local delta = state.positionHistory[i] - state.positionHistory[i - depth]
               pattern = pattern:Lerp(delta.Unit, 0.2 * weight)
           end
           
           table.insert(patterns, {
               direction = pattern.Unit,
               weight = weight,
               confidence = math.exp(-depth * 0.2)
           })
           
           totalWeight = totalWeight + weight
       end
       
       return patterns, totalWeight
   end

   local function predictVelocityVector()
       local patterns, totalWeight = analyzeMovementPatterns()
       local predictedVel = state.velocity
       local patternInfluence = Vector3.new()
       
       for _, pattern in ipairs(patterns) do
           patternInfluence = patternInfluence + 
               (pattern.direction * pattern.weight * pattern.confidence)
       end
       patternInfluence = patternInfluence / totalWeight
       
       local speedFactor = math.min(
           predictedVel.Magnitude / humanoid.WalkSpeed,
           PHYSICS.MAX_SPEED_MULTIPLIER
       )
       
       predictedVel = predictedVel:Lerp(
           patternInfluence * humanoid.WalkSpeed * speedFactor,
           PROBABILITY.PATTERN_WEIGHT
       )
       
       return predictedVel
   end

   local function calculateGroundPhysics(position)
       local params = RaycastParams.new()
       params.FilterType = Enum.RaycastFilterType.Blacklist
       params.FilterDescendantsInstances = {character}
       
       local results = {}
       local rays = {
           Vector3.new(0, -PHYSICS.GROUND_OFFSET, 0),
           Vector3.new(1, -PHYSICS.GROUND_OFFSET, 0),
           Vector3.new(-1, -PHYSICS.GROUND_OFFSET, 0),
           Vector3.new(0, -PHYSICS.GROUND_OFFSET, 1),
           Vector3.new(0, -PHYSICS.GROUND_OFFSET, -1)
       }
       
       for _, ray in ipairs(rays) do
           local result = workspace:Raycast(position, ray, params)
           if result then
               table.insert(results, result)
           end
       end
       
       return results
   end

   local function simulatePhysics(startPos, startVel, duration)
       local pos = startPos
       local vel = startVel
       local time = 0
       local confidence = 1.0
       
       while time < duration do
           for _ = 1, PHYSICS.MACRO_TICK / PHYSICS.MICRO_TICK do
               local groundData = calculateGroundPhysics(pos)
               local isGrounded = #groundData > 0
               
               if isGrounded then
                   vel = vel * MOVEMENT.GROUND_FRICTION.LINEAR
                   vel = Vector3.new(
                       vel.X * MOVEMENT.MOMENTUM.CONSERVATION,
                       0,
                       vel.Z * MOVEMENT.MOMENTUM.CONSERVATION
                   )
               else
                   vel = vel * MOVEMENT.AIR_RESISTANCE.LINEAR
                   vel = vel + Vector3.new(
                       0,
                       math.max(PHYSICS.GRAVITY * PHYSICS.MICRO_TICK, PHYSICS.TERMINAL_VELOCITY),
                       0
                   )
               end
               
               pos = pos + (vel * PHYSICS.MICRO_TICK)
               confidence = confidence * PROBABILITY.CONFIDENCE_DECAY
           end
           
           time = time + PHYSICS.MACRO_TICK
       end
       
       return pos, vel, confidence
   end

   local function updateStateHistory()
       table.remove(state.velocityHistory, 1)
       table.insert(state.velocityHistory, state.velocity)
       
       table.remove(state.positionHistory, 1)
       table.insert(state.positionHistory, state.position)
   end

   local function calculatePrediction()
       local predictedVel = predictVelocityVector()
       local finalPos, finalVel, confidence = simulatePhysics(
           state.position,
           predictedVel,
           PHYSICS.PREDICTION_WINDOW
       )
       
       updateStateHistory()
       
       state.predictionAccuracy = confidence
       state.lastCalculationTime = tick()
       
       if confidence >= PROBABILITY.MIN_CONFIDENCE then
           return finalPos
       end
       
       return state.position
   end

   return calculatePrediction()
end

-- Function to find the murderer in the game
local function GetMurderer()
    local Players = game:GetService("Players")
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Knife") then
            return player
        end
    end
    return nil
end

local RoleNotify = {
    Enabled = true,
    NotificationDuration = 4
}

-- Create role notification GUI
local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "RoleNotifications"
NotificationGui.ResetOnSpawn = false
-- Use proper parent for client-side UI elements
if syn and syn.protect_gui then
    syn.protect_gui(NotificationGui)
    NotificationGui.Parent = game:GetService("CoreGui")
else
    NotificationGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

local NotificationFrame = Instance.new("Frame")
NotificationFrame.Name = "NotificationFrame"
NotificationFrame.Size = UDim2.new(0, 250, 0, 120)
NotificationFrame.Position = UDim2.new(0.5, -125, 0.15, 0)
NotificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
NotificationFrame.BackgroundTransparency = 0.2
NotificationFrame.BorderSizePixel = 0
NotificationFrame.Visible = false
NotificationFrame.Parent = NotificationGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = NotificationFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.5
UIStroke.Parent = NotificationFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ROLE DETECTED"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = NotificationFrame

local RoleIcon = Instance.new("Frame")
RoleIcon.Name = "RoleIcon"
RoleIcon.Size = UDim2.new(0, 40, 0, 40)
RoleIcon.Position = UDim2.new(0, 15, 0, 40)
RoleIcon.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
RoleIcon.BorderSizePixel = 0
RoleIcon.Parent = NotificationFrame

local RoleIconCorner = Instance.new("UICorner")
RoleIconCorner.CornerRadius = UDim.new(0, 8)
RoleIconCorner.Parent = RoleIcon

local RoleLabel = Instance.new("TextLabel")
RoleLabel.Name = "RoleLabel"
RoleLabel.Size = UDim2.new(0, 150, 0, 25)
RoleLabel.Position = UDim2.new(0, 70, 0, 40)
RoleLabel.BackgroundTransparency = 1
RoleLabel.Text = "Murderer:"
RoleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RoleLabel.TextSize = 16
RoleLabel.Font = Enum.Font.GothamBold
RoleLabel.TextXAlignment = Enum.TextXAlignment.Left
RoleLabel.Parent = NotificationFrame

local PlayerLabel = Instance.new("TextLabel")
PlayerLabel.Name = "PlayerLabel"
PlayerLabel.Size = UDim2.new(0, 150, 0, 25)
PlayerLabel.Position = UDim2.new(0, 70, 0, 65)
PlayerLabel.BackgroundTransparency = 1
PlayerLabel.Text = "PlayerName"
PlayerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerLabel.TextSize = 14
PlayerLabel.Font = Enum.Font.Gotham
PlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerLabel.Parent = NotificationFrame

-- Function to show role notification
function RoleNotify:ShowNotification(role, playerName)
    -- Skip if disabled
    if not self.Enabled then return end
    
    -- Skip hero notifications
    if role == "Hero" then return end
    
    local roleColor
    if role == "Murderer" then
        roleColor = ESP.Colors.Murderer
    elseif role == "Sheriff" then
        roleColor = ESP.Colors.Sheriff
    elseif role == "Innocent" then
        roleColor = ESP.Colors.Innocent
    else
        roleColor = Color3.fromRGB(200, 200, 200)  -- Default color
    end
    
    -- Update notification UI
    RoleIcon.BackgroundColor3 = roleColor
    RoleLabel.Text = role .. ":"
    PlayerLabel.Text = playerName
    NotificationFrame.Visible = true
    
    -- Animation
    NotificationFrame.Position = UDim2.new(0.5, -125, 0, -120)
    local tween = game:GetService("TweenService"):Create(NotificationFrame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {Position = UDim2.new(0.5, -125, 0.15, 0)})
    tween:Play()
    
    -- Hide after duration
    task.delay(self.NotificationDuration, function()
        local hideTween = game:GetService("TweenService"):Create(NotificationFrame, 
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
            {Position = UDim2.new(0.5, -125, 0, -120)})
        hideTween:Play()
        hideTween.Completed:Connect(function()
            NotificationFrame.Visible = false
        end)
    end)
end

-- Toggle function
function RoleNotify:Toggle(state)
    self.Enabled = state
end

-- Role tracking variables for notification
local previousRoles = {}

-- Setup role tracking function
local RoleUpdateConnection = nil
local function SetupRoleNotifications()
    -- Clear previous connection if it exists
    if RoleUpdateConnection then
        RoleUpdateConnection:Disconnect()
        RoleUpdateConnection = nil
    end
    
    -- Reset previous roles
    previousRoles = {}
    
    -- Create new connection with proper error handling
    RoleUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        pcall(function()
            if game:GetService("ReplicatedStorage"):FindFirstChild("GetPlayerData", true) then
                local currentRoles = game:GetService("ReplicatedStorage"):FindFirstChild("GetPlayerData", true):InvokeServer()
                
                -- Process each player's role
                for playerName, playerData in pairs(currentRoles) do
                    -- Skip if we've already notified about this player's role
                    if previousRoles[playerName] == playerData.Role then
                        continue
                    end
                    
                    -- Store the new role
                    previousRoles[playerName] = playerData.Role
                    
                    -- Notify about the role
                    if playerData.Role == "Murderer" then
                        RoleNotify:ShowNotification("Murderer", playerName)
                    elseif playerData.Role == "Sheriff" then
                        RoleNotify:ShowNotification("Sheriff", playerName)
                    elseif playerData.Role == "Innocent" then
                        RoleNotify:ShowNotification("Innocent", playerName)
                    end
                    -- Hero role is intentionally skipped
                end
            end
        end)
    end)
end

-- Add role notification toggle to the UI


-- Initialize role notifications if enabled by default
local RoleNotify = {
    Enabled = true,
    NotificationDuration = 4
}

-- Create role notification GUI
local NotificationGui = Instance.new("ScreenGui")
NotificationGui.Name = "RoleNotifications"
NotificationGui.ResetOnSpawn = false
-- Use proper parent for client-side UI elements
if syn and syn.protect_gui then
    syn.protect_gui(NotificationGui)
    NotificationGui.Parent = game:GetService("CoreGui")
else
    NotificationGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

local NotificationFrame = Instance.new("Frame")
NotificationFrame.Name = "NotificationFrame"
NotificationFrame.Size = UDim2.new(0, 250, 0, 120)
NotificationFrame.Position = UDim2.new(0.5, -125, 0.15, 0)
NotificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
NotificationFrame.BackgroundTransparency = 0.2
NotificationFrame.BorderSizePixel = 0
NotificationFrame.Visible = false
NotificationFrame.Parent = NotificationGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = NotificationFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.5
UIStroke.Parent = NotificationFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "YOUR ROLE"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = NotificationFrame

local RoleIcon = Instance.new("Frame")
RoleIcon.Name = "RoleIcon"
RoleIcon.Size = UDim2.new(0, 40, 0, 40)
RoleIcon.Position = UDim2.new(0, 15, 0, 40)
RoleIcon.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
RoleIcon.BorderSizePixel = 0
RoleIcon.Parent = NotificationFrame

local RoleIconCorner = Instance.new("UICorner")
RoleIconCorner.CornerRadius = UDim.new(0, 8)
RoleIconCorner.Parent = RoleIcon

local RoleLabel = Instance.new("TextLabel")
RoleLabel.Name = "RoleLabel"
RoleLabel.Size = UDim2.new(0, 150, 0, 50)
RoleLabel.Position = UDim2.new(0, 70, 0, 45)
RoleLabel.BackgroundTransparency = 1
RoleLabel.Text = "Innocent"
RoleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RoleLabel.TextSize = 20
RoleLabel.Font = Enum.Font.GothamBold
RoleLabel.TextXAlignment = Enum.TextXAlignment.Left
RoleLabel.Parent = NotificationFrame

-- Function to show role notification
function RoleNotify:ShowNotification(role)
    -- Skip if disabled
    if not self.Enabled then return end
    
    -- Skip hero notifications if needed
    if role == "Hero" then return end
    
    local roleColor
    if role == "Murderer" then
        roleColor = ESP.Colors.Murderer or Color3.fromRGB(255, 0, 0)
    elseif role == "Sheriff" then
        roleColor = ESP.Colors.Sheriff or Color3.fromRGB(0, 0, 255)
    elseif role == "Innocent" then
        roleColor = ESP.Colors.Innocent or Color3.fromRGB(0, 255, 0)
    else
        roleColor = Color3.fromRGB(200, 200, 200)  -- Default color
    end
    
    -- Update notification UI
    RoleIcon.BackgroundColor3 = roleColor
    RoleLabel.Text = role
    NotificationFrame.Visible = true
    
    -- Animation
    NotificationFrame.Position = UDim2.new(0.5, -125, 0, -120)
    local tween = game:GetService("TweenService"):Create(NotificationFrame, 
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {Position = UDim2.new(0.5, -125, 0.15, 0)})
    tween:Play()
    
    -- Hide after duration
    task.delay(self.NotificationDuration, function()
        local hideTween = game:GetService("TweenService"):Create(NotificationFrame, 
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
            {Position = UDim2.new(0.5, -125, 0, -120)})
        hideTween:Play()
        hideTween.Completed:Connect(function()
            NotificationFrame.Visible = false
        end)
    end)
end

-- Toggle function
function RoleNotify:Toggle(state)
    self.Enabled = state
end

-- Track local player's role
local localPlayer = game.Players.LocalPlayer
local previousRole = nil
local RoleUpdateConnection = nil

-- Setup role tracking function
local function SetupRoleNotifications()
    -- Clear previous connection if it exists
    if RoleUpdateConnection then
        RoleUpdateConnection:Disconnect()
        RoleUpdateConnection = nil
    end
    
    -- Reset previous role
    previousRole = nil
    
    -- Create new connection with proper error handling
    RoleUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        pcall(function()
            if game:GetService("ReplicatedStorage"):FindFirstChild("GetPlayerData", true) then
                local playerData = game:GetService("ReplicatedStorage"):FindFirstChild("GetPlayerData", true):InvokeServer()
                
                -- Look for local player's data
                local localPlayerName = localPlayer.Name
                local myRole = playerData[localPlayerName] and playerData[localPlayerName].Role
                
                -- Only notify if role changes or is first detected
                if myRole and myRole ~= previousRole then
                    previousRole = myRole
                    RoleNotify:ShowNotification(myRole)
                end
            end
        end)
    end)
end

-------------------------------------LOADER----------------------------------LOADER-------------------------

-- OmniHub Loader with Enhanced Water Animation and Performance Optimization
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OmniHubLoader"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Performance and physics configuration
local MAX_PARTICLES = 50  -- Increased particle count
local PARTICLES_PER_BATCH = 7  -- More particles per batch for better visual effect
local WAVE_SPEED = 0.4  -- Slightly slower for more realistic wave motion
local WATER_VISCOSITY = 0.8  -- Controls water "thickness" (0-1)
local SPLASH_INTENSITY = 1.2  -- Controls splash size multiplier
local RIPPLE_FREQUENCY = 0.2  -- Controls frequency of ripple effects

-- Main container
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 250)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

-- Apply smooth corner radius
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Enhanced drop shadow with better blur
local dropShadow = Instance.new("ImageLabel")
dropShadow.Name = "DropShadow"
dropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
dropShadow.BackgroundTransparency = 1
dropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
dropShadow.Size = UDim2.new(1, 50, 1, 50)  -- Slightly larger shadow
dropShadow.ZIndex = 0
dropShadow.Image = "rbxassetid://6014261993"
dropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
dropShadow.ImageTransparency = 1
dropShadow.ScaleType = Enum.ScaleType.Slice
dropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
dropShadow.Parent = mainFrame

-- Water effect container with mask
local waterContainer = Instance.new("Frame")
waterContainer.Name = "WaterContainer"
waterContainer.Size = UDim2.new(1, 0, 1, 0)
waterContainer.BackgroundTransparency = 1
waterContainer.ClipsDescendants = true
waterContainer.Parent = mainFrame

-- Create a noise texture overlay for more realistic water
local noiseTexture = Instance.new("ImageLabel")
noiseTexture.Name = "NoiseTexture"
noiseTexture.Size = UDim2.new(1, 0, 1, 0)
noiseTexture.BackgroundTransparency = 1
noiseTexture.Image = "rbxassetid://8108458673"  -- Perlin noise texture
noiseTexture.ImageTransparency = 0.85
noiseTexture.Parent = waterContainer

-- Enhanced water level visual with depth
local waterLevel = Instance.new("Frame")
waterLevel.Name = "WaterLevel"
waterLevel.Size = UDim2.new(1, 0, 0, 0)
waterLevel.Position = UDim2.new(0, 0, 1, 0)
waterLevel.AnchorPoint = Vector2.new(0, 1)
waterLevel.BackgroundColor3 = Color3.fromRGB(70, 140, 240)  -- Slightly deeper blue
waterLevel.BackgroundTransparency = 0.1
waterLevel.BorderSizePixel = 0
waterLevel.Parent = waterContainer

-- Improved water gradient with more keypoints for depth
local waterGradient = Instance.new("UIGradient")
waterGradient.Rotation = 180
waterGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.4, 0.1),
    NumberSequenceKeypoint.new(0.7, 0.3),
    NumberSequenceKeypoint.new(0.9, 0.5),
    NumberSequenceKeypoint.new(1, 0.7)
})
waterGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 140, 240)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(90, 160, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 180, 255))
})
waterGradient.Parent = waterLevel

-- Enhanced wave system with multiple layers for more realistic water surface
local waterWave1 = Instance.new("ImageLabel")
waterWave1.Name = "WaterWave1"
waterWave1.Size = UDim2.new(2, 0, 0.15, 0)
waterWave1.Position = UDim2.new(0, 0, 0, 0)
waterWave1.BackgroundTransparency = 1
waterWave1.Image = "rbxassetid://6764361046"
waterWave1.ImageTransparency = 0.6
waterWave1.ImageColor3 = Color3.fromRGB(255, 255, 255)
waterWave1.Parent = waterLevel

local waterWave2 = Instance.new("ImageLabel")
waterWave2.Name = "WaterWave2"
waterWave2.Size = UDim2.new(2, 0, 0.25, 0)
waterWave2.Position = UDim2.new(-0.5, 0, 0.05, 0)
waterWave2.BackgroundTransparency = 1
waterWave2.Image = "rbxassetid://6764361046"
waterWave2.ImageTransparency = 0.7
waterWave2.ImageColor3 = Color3.fromRGB(180, 220, 255)
waterWave2.Parent = waterLevel

-- New subtle wave layer for added depth
local waterWave3 = Instance.new("ImageLabel")
waterWave3.Name = "WaterWave3"
waterWave3.Size = UDim2.new(1.5, 0, 0.2, 0)
waterWave3.Position = UDim2.new(-0.25, 0, 0.1, 0)
waterWave3.BackgroundTransparency = 1
waterWave3.Image = "rbxassetid://6764361046"
waterWave3.ImageTransparency = 0.8
waterWave3.ImageColor3 = Color3.fromRGB(200, 230, 255)
waterWave3.Parent = waterLevel

-- Water surface highlight for realistic light refraction
local waterSurface = Instance.new("Frame")
waterSurface.Name = "WaterSurface"
waterSurface.Size = UDim2.new(1, 0, 0, 3)
waterSurface.Position = UDim2.new(0, 0, 0, 0)
waterSurface.BackgroundColor3 = Color3.fromRGB(220, 240, 255)
waterSurface.BackgroundTransparency = 0.4
waterSurface.BorderSizePixel = 0
waterSurface.Parent = waterLevel

-- UI elements
local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Size = UDim2.new(0, 100, 0, 100)
logo.Position = UDim2.new(0.5, 0, 0.3, 0)
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://122380482857500" -- Replace with actual asset ID
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
versionText.Text = "V1.1.5 • By Azzakirms"
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

-- Enhanced progress bar with glow effect
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

-- Enhanced progress glow effect
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

-- Particle system with advanced physics
local particlePool = {}
local activeParticles = {}
local waterSurfaceY = 0  -- Current water surface Y position for physics calculations

-- Ripple effect system
local ripples = {}
local MAX_RIPPLES = 8

-- Create a ripple at the specified position
local function createRipple(posX, size)
    -- Find an available ripple slot or create a new one
    local ripple
    for i, r in ipairs(ripples) do
        if not r.active then
            ripple = r
            break
        end
    end
    
    if not ripple then
        if #ripples >= MAX_RIPPLES then return end
        
        ripple = {
            obj = Instance.new("ImageLabel"),
            active = false
        }
        
        ripple.obj.BackgroundTransparency = 1
        ripple.obj.Image = "rbxassetid://2092248396"  -- Circle image
        ripple.obj.ImageColor3 = Color3.fromRGB(255, 255, 255)
        ripple.obj.Parent = waterLevel
        
        table.insert(ripples, ripple)
    end
    
    -- Configure and animate the ripple
    ripple.active = true
    ripple.obj.Size = UDim2.new(0, 0, 0, 0)
    ripple.obj.Position = UDim2.new(0, posX - size/2, 0, 5)
    ripple.obj.ImageTransparency = 0.2
    
    -- Animate ripple expansion
    local expandTween = TweenService:Create(
        ripple.obj,
        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, size * 3, 0, size),
            ImageTransparency = 1,
            Position = UDim2.new(0, posX - size*1.5, 0, -5)
        }
    )
    
    expandTween:Play()
    
    expandTween.Completed:Connect(function()
        ripple.active = false
    end)
end

-- Pre-create particle objects with enhanced visuals
local function initializeParticlePool()
    for i = 1, MAX_PARTICLES do
        local droplet = Instance.new("Frame")
        droplet.Size = UDim2.new(0, 10, 0, 10)
        droplet.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
        droplet.BackgroundTransparency = 0.3
        droplet.BorderSizePixel = 0
        
        -- Make most particles circular, but some slightly oval for variety
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(math.random() > 0.2 and 1 or 0.8, 0)
        uiCorner.Parent = droplet
        
        -- Enhanced glow effect for water droplets
        local glow = Instance.new("ImageLabel")
        glow.BackgroundTransparency = 1
        glow.Position = UDim2.new(0, -5, 0, -5)
        glow.Size = UDim2.new(1, 10, 1, 10)
        glow.ZIndex = 0
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = Color3.fromRGB(120, 200, 255)
        glow.ImageTransparency = 0.6
        glow.Parent = droplet
        
        -- Create data table for physics simulation
        droplet.data = {
            velocityX = 0,
            velocityY = 0,
            gravity = 0.2 + math.random() * 0.1,
            mass = 0.5 + math.random() * 1,
            drag = WATER_VISCOSITY * (0.8 + math.random() * 0.4),
            isInWater = false
        }
        
        table.insert(particlePool, droplet)
    end
end

-- Enhanced particle management with physics
local function getParticle()
    if #particlePool > 0 then
        local particle = table.remove(particlePool)
        table.insert(activeParticles, particle)
        return particle
    elseif #activeParticles > 0 then
        -- Recycle oldest particle
        local oldest = table.remove(activeParticles, 1)
        table.insert(activeParticles, oldest)
        return oldest
    end
    return nil
end

-- Return particle to pool
local function recycleParticle(particle)
    for i, p in ipairs(activeParticles) do
        if p == particle then
            table.remove(activeParticles, i)
            particle.Parent = nil
            table.insert(particlePool, particle)
            break
        end
    end
end

-- Create water splash effect at specified position
local function createSplash(posX, posY, intensity, count)
    count = count or math.random(3, 7)
    intensity = intensity or 1
    
    for i = 1, count do
        local particle = getParticle()
        if not particle then continue end
        
        -- Configure particle appearance
        local size = (math.random(5, 10) * intensity * SPLASH_INTENSITY)
        local startX = posX + math.random(-10, 10) * intensity
        local startY = posY
        
        -- Apply realistic initial velocity for splash
        particle.data.velocityX = (math.random() - 0.5) * 6 * intensity
        particle.data.velocityY = -math.random(3, 7) * intensity
        particle.data.isInWater = false
        
        particle.Size = UDim2.new(0, size, 0, size)
        particle.Position = UDim2.new(0, startX, 0, startY)
        particle.BackgroundTransparency = 0.2 + math.random() * 0.3
        particle.Parent = waterContainer
        
        -- Create a ripple effect at the splash position
        if math.random() < 0.7 then
            createRipple(startX, size * 2)
        end
    end
end

-- Create and animate water particles with realistic physics
local function createWaterParticles(count, startYRange, speedRange, withPhysics)
    local batchSize = math.min(count, PARTICLES_PER_BATCH)
    local batchCount = math.ceil(count / batchSize)
    
    -- Process particles in smaller batches to reduce frame lag
    for batch = 1, batchCount do
        local particlesInBatch = (batch < batchCount) and batchSize or (count - (batch-1) * batchSize)
        
        for i = 1, particlesInBatch do
            local particle = getParticle()
            if not particle then continue end
            
            -- Configure particle appearance with variety
            local size = math.random(5, 15)
            local startX = math.random(0, 450)
            local startY = math.random(startYRange[1], startYRange[2])
            
            -- Apply realistic physics properties
            if withPhysics then
                particle.data.velocityX = (math.random() - 0.5) * 3
                particle.data.velocityY = math.random() * 2
                particle.data.isInWater = startY > waterSurfaceY
            else
                -- For simple animation with no physics
                local endY = startY + math.random(30, 70)
                local speed = math.random(speedRange[1] * 10, speedRange[2] * 10) / 10
                
                particle.Size = UDim2.new(0, size, 0, size)
                particle.Position = UDim2.new(0, startX, 0, startY)
                particle.BackgroundTransparency = math.random(2, 5) / 10
                particle.Parent = waterContainer
                
                -- Create simpler trajectory tween for non-physics particles
                local tween = TweenService:Create(
                    particle,
                    TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {Position = UDim2.new(0, startX + math.random(-30, 30), 0, endY)}
                )
                
                tween:Play()
                
                delay(speed, function()
                    recycleParticle(particle)
                end)
                
                continue  -- Skip physics setup for non-physics particles
            end
            
            particle.Size = UDim2.new(0, size, 0, size)
            particle.Position = UDim2.new(0, startX, 0, startY)
            particle.BackgroundTransparency = math.random(2, 5) / 10
            particle.Parent = waterContainer
            
            -- Set a timeout to recycle particles that might get stuck
            delay(5, function()
                if table.find(activeParticles, particle) then
                    recycleParticle(particle)
                end
            end)
        end
        
        if batch < batchCount then
            wait(0.01) -- Small yield between batches to distribute processing load
        end
    end
end

-- Physics update function for water particles
local function updateParticlePhysics(deltaTime)
    -- Calculate water surface position for collision detection
    local waterLevelPos = waterLevel.Position.Y.Offset
    local waterHeight = waterLevel.Size.Y.Offset
    waterSurfaceY = waterLevelPos - waterHeight
    
    -- Update each active particle with physics
    for i, particle in ipairs(activeParticles) do
        if not particle.data then continue end
        
        local pos = particle.Position
        local data = particle.data
        
        -- Check water collision
        local particleY = pos.Y.Offset
        local particleX = pos.X.Offset
        local wasInWater = data.isInWater
        data.isInWater = particleY >= waterSurfaceY
        
        -- Water entry splash effect
        if data.isInWater and not wasInWater and data.velocityY > 1 and math.random() < 0.7 then
            -- Create a small splash/ripple when entering water
            createRipple(particleX, particle.Size.X.Offset * 2)
        end
        
        -- Apply gravity if above water
        if not data.isInWater then
            data.velocityY = data.velocityY + data.gravity * deltaTime * 60
        else
            -- Apply buoyancy and water resistance
            local buoyancy = data.mass * 0.2
            data.velocityY = data.velocityY * (1 - data.drag * deltaTime * 4)
            data.velocityY = data.velocityY - buoyancy * deltaTime * 60
            
            -- Apply horizontal drag in water
            data.velocityX = data.velocityX * (1 - data.drag * deltaTime * 2)
        end
        
        -- Boundary collisions
        if particleX < 0 or particleX > 450 then
            data.velocityX = -data.velocityX * 0.8
            
            -- Keep particle in bounds
            if particleX < 0 then
                particleX = 0
            elseif particleX > 450 then
                particleX = 450
            end
        end
        
        -- Bottom boundary check (recycle if at bottom)
        if particleY > 250 then
            recycleParticle(particle)
            continue
        end
        
        -- Update particle position based on velocity
        local newX = particleX + data.velocityX
        local newY = particleY + data.velocityY
        
        particle.Position = UDim2.new(0, newX, 0, newY)
    end
end

-- Enhanced water wave animation with depth simulation
local waveConnection = nil
local physicsConnection = nil
local noiseConnection = nil

local function startWaterAnimations()
    local wave1Offset = 0
    local wave2Offset = 0.5
    local wave3Offset = 0.25
    local noiseOffset = 0
    
    -- Wave animation
    waveConnection = RunService.Heartbeat:Connect(function(deltaTime)
        -- Animate multiple wave layers at different speeds
        wave1Offset = (wave1Offset + deltaTime * WAVE_SPEED) % 1
        wave2Offset = (wave2Offset + deltaTime * WAVE_SPEED * 0.7) % 1
        wave3Offset = (wave3Offset + deltaTime * WAVE_SPEED * 0.5) % 1
        
        waterWave1.Position = UDim2.new(-wave1Offset, 0, 0, 0)
        waterWave2.Position = UDim2.new(-wave2Offset, 0, 0.05, 0)
        waterWave3.Position = UDim2.new(-wave3Offset, 0, 0.1, 0)
        
        -- Create occasional ripples for ambient water movement
        if math.random() < RIPPLE_FREQUENCY * deltaTime * 10 then
            createRipple(math.random(50, 400), math.random(20, 40))
        end
    end)
    
    -- Noise texture animation for water surface distortion
    noiseConnection = RunService.Heartbeat:Connect(function(deltaTime)
   noiseOffset = (noiseOffset + deltaTime * 0.1) % 1
   noiseTexture.Position = UDim2.new(noiseOffset, 0, -noiseOffset, 0)
   
   -- Apply subtle scaling to noise texture for more dynamic water effect
   local scaleFactor = 1 + math.sin(tick()) * 0.03
   noiseTexture.Size = UDim2.new(scaleFactor, 0, scaleFactor, 0)
   noiseTexture.ImageTransparency = 0.85 + math.sin(tick() * 1.5) * 0.05
end)

-- Physics update loop
physicsConnection = RunService.Heartbeat:Connect(updateParticlePhysics)
end

local function stopWaterAnimations()
   if waveConnection then waveConnection:Disconnect() end
   if physicsConnection then physicsConnection:Disconnect() end
   if noiseConnection then noiseConnection:Disconnect() end
   waveConnection = nil
   physicsConnection = nil
   noiseConnection = nil
end

-- Water level control function with fluid dynamics
local function animateWaterLevel(targetHeight, duration, withSplash)
   local currentHeight = waterLevel.Size.Y.Scale
   
   -- Create water rise/fall tween
   local waterTween = TweenService:Create(
       waterLevel,
       TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
       {Size = UDim2.new(1, 0, targetHeight, 0)}
   )
   
   -- Create splash effects during animation
   if withSplash then
       local isRising = targetHeight > currentHeight
       local splashCount = isRising and 5 or 3
       local splashDelay = duration / splashCount
       
       for i = 1, splashCount do
           delay(i * splashDelay, function()
               -- Create splashes at random positions along the water surface
               local splashCount = isRising and math.random(3, 6) or math.random(2, 4)
               local splashX = math.random(50, 400)
               local splashY = waterSurfaceY
               
               createSplash(splashX, splashY, isRising and 0.8 or 1.2, splashCount)
           end)
       end
   end
   
   waterTween:Play()
   return waterTween
end

-- Enhanced main loader function with improved transitions
local function startLoader()
   -- Initialize particle system
   initializeParticlePool()
   
   -- Start water animations
   startWaterAnimations()
   
   -- Begin with water surface glow and subtle ambient particles
   createWaterParticles(math.floor(MAX_PARTICLES/3), {-20, 0}, {1, 2}, false)
   
   -- Initial water rise animation with dynamic splash effects
   local waterRiseTween = animateWaterLevel(1, 2, true)
   
   -- Fade in UI background with subtle delay
   delay(0.5, function()
       -- Add subtle shake effect during water fill
       local originalPosition = mainFrame.Position
       local shakeIntensity = 2
       local shakeDuration = 1.5
       local startTime = tick()
       
       -- Apply subtle shaking during water rise
       local shakeConnection = RunService.Heartbeat:Connect(function()
           local elapsed = tick() - startTime
           if elapsed > shakeDuration then
               mainFrame.Position = originalPosition
               shakeConnection:Disconnect()
               return
           end
           
           local fadeOut = 1 - (elapsed / shakeDuration)
           local offsetX = math.sin(elapsed * 20) * shakeIntensity * fadeOut
           local offsetY = math.cos(elapsed * 15) * shakeIntensity * fadeOut
           
           mainFrame.Position = UDim2.new(
               originalPosition.X.Scale, 
               originalPosition.X.Offset + offsetX,
               originalPosition.Y.Scale, 
               originalPosition.Y.Offset + offsetY
           )
       end)
       
       -- Fade in main elements with improved transitions
       TweenService:Create(mainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0}):Play()
       TweenService:Create(dropShadow, TweenInfo.new(1.2, Enum.EasingStyle.Quad), {ImageTransparency = 0.2}):Play()
       
       -- Show UI elements with enhanced staggered animation
       delay(0.3, function()
           animateUI(true)
       end)
   end)
   
   -- Wait for initial animations to complete
   wait(2.5)
   
   -- Create ambient water particles during the loading process
   local ambientParticleInterval = 0.8
   local ambientParticleConnection = RunService.Heartbeat:Connect(function(deltaTime)
       ambientParticleInterval = ambientParticleInterval - deltaTime
       if ambientParticleInterval <= 0 then
           createWaterParticles(math.random(1, 3), {220, 240}, {0.5, 0.8}, true)
           ambientParticleInterval = 0.8 + math.random() * 0.5
       end
   end)
   
   -- Define loading steps with more detailed status messages
   local loadingSteps = {
       {text = "Checking Modules...", time = 1.2, ripples = true},
       {text = "Validating Script...", time = 1.0, ripples = false},
       {text = "Loading Game Information...", time = 1.5, ripples = true},
       {text = "Preparing User Interface...", time = 1.0, ripples = false},
       {text = "Finalizing Setup...", time = 1.8, ripples = true}
   }
   
   local totalTime = 0
   for _, step in ipairs(loadingSteps) do
       totalTime = totalTime + step.time
   end
   
   local elapsedTime = 0
   
   -- Process each loading step with enhanced visual feedback
   for i, step in ipairs(loadingSteps) do
       statusText.Text = step.text
       
       local startProgress = elapsedTime / totalTime
       elapsedTime = elapsedTime + step.time
       local endProgress = elapsedTime / totalTime
       
       -- Update progress bar with water-like animation
       local progressTween = updateLoadingProgress(startProgress, endProgress, step.time)
       
       -- Create water effects based on step type
       if step.ripples then
           -- Create extra ripples during this loading step
           for r = 1, math.random(2, 4) do
               delay(r * step.time / 5, function()
                   createRipple(math.random(100, 350), math.random(25, 45))
               end)
           end
       end
       
       -- Create ambient particles during loading
       createWaterParticles(math.min(5, MAX_PARTICLES), {220, 240}, {0.5, 0.8}, true)
       
       wait(step.time)
   end
   
   -- Disconnect ambient particle creation
   if ambientParticleConnection then
       ambientParticleConnection:Disconnect()
   end
   
   -- Brief pause at 100% with ripple effect celebration
   for i = 1, 5 do
       delay(i * 0.1, function()
           createRipple(100 + i * 60, 35)
       end)
   end
   wait(0.7)
   
   -- Begin outro transition with fade out UI
   animateUI(false)
   wait(0.8)
   
   -- Water drain animation with enhanced splash effects
   for i = 1, 3 do
       createSplash(math.random(100, 350), waterSurfaceY, 1.5, math.random(4, 8))
   end
   
   -- Dramatic water drain with particle effects
   createWaterParticles(MAX_PARTICLES, {50, 200}, {0.8, 1.5}, true)
   
   local drainWaterTween = animateWaterLevel(0, 1.8, true)
   
   -- Fade out background with slight delay
   delay(0.3, function()
       TweenService:Create(mainFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {BackgroundTransparency = 1}):Play()
       TweenService:Create(dropShadow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {ImageTransparency = 1}):Play()
   end)
   
   -- Wait for animations to complete
   wait(2)
   
   -- Stop animations and cleanup
   stopWaterAnimations()
   
   -- Clear particles and ripples
   for _, particle in ipairs(activeParticles) do
       particle:Destroy()
   end
   for _, particle in ipairs(particlePool) do
       particle:Destroy()
   end
   for _, ripple in ipairs(ripples) do
       if ripple.obj then
           ripple.obj:Destroy()
       end
   end
   
   -- Final cleanup
   screenGui:Destroy()
   
   -- Here you would load your main hub
   -- loadMainHub()
   print("OmniHub loading complete!")
end

-- Start the loader
startLoader()

----------------------TOGGLER FOR UI-------------------TOGGLER FOR UI------------

-- Create a draggable toggle button for OmniHub
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "OmniHubToggle"
ToggleGui.ResetOnSpawn = false
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Use proper parent based on environment
if syn and syn.protect_gui then
    syn.protect_gui(ToggleGui)
    ToggleGui.Parent = game:GetService("CoreGui")
else
    ToggleGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Create the toggle button
local ToggleButton = Instance.new("Frame")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0.05, 0, 0.5, -25) -- Left side, middle
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.BorderSizePixel = 0
ToggleButton.Active = true
ToggleButton.Parent = ToggleGui

-- Add visual elements
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0) -- Makes it circular
UICorner.Parent = ToggleButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 255)
UIStroke.Thickness = 2
UIStroke.Parent = ToggleButton

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
})
UIGradient.Parent = ToggleButton

-- Icon
local Icon = Instance.new("ImageLabel")
Icon.Name = "Icon"
Icon.Size = UDim2.new(0.6, 0, 0.6, 0)
Icon.Position = UDim2.new(0.2, 0, 0.2, 0)
Icon.BackgroundTransparency = 1
Icon.Image = "rbxassetid://7733658504" -- Hub/menu icon
Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
Icon.Parent = ToggleButton

-- Make the toggle button draggable (works for both PC and mobile)
local isDragging = false
local dragInput, dragStart, startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    ToggleButton.Position = UDim2.new(
        startPos.X.Scale, 
        startPos.X.Offset + delta.X, 
        startPos.Y.Scale, 
        startPos.Y.Offset + delta.Y
    )
end

-- Function to simulate pressing LeftControl
local function simulateLeftControl()
    -- Directly simulate the LeftControl key press
    -- This uses the keyboard input system to trigger the key that Fluent UI is listening for
    local UserInputService = game:GetService("UserInputService")
    local vim = game:GetService("VirtualInputManager")
    
    -- Use VirtualInputManager to simulate keyboard press (works in most executor environments)
    if vim then
        -- Key down
        vim:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        -- Small delay
        task.wait(0.05)
        -- Key up
        vim:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        
        -- This tracks the initial input to determine if it's a drag or click
        local startTime = tick()
        local initialPosition = input.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
                
                -- If moved less than 5 pixels and released within 0.3 seconds, treat as a click
                if (tick() - startTime < 0.3) and (input.Position - initialPosition).Magnitude < 5 then
                    simulateLeftControl()
                end
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and isDragging then
        updateInput(input)
    end
end)

-- Add hover effect
ToggleButton.MouseEnter:Connect(function()
    game:GetService("TweenService"):Create(UIStroke, 
        TweenInfo.new(0.3), 
        {Thickness = 3, Color = Color3.fromRGB(90, 90, 255)}):Play()
end)

ToggleButton.MouseLeave:Connect(function()
    game:GetService("TweenService"):Create(UIStroke, 
        TweenInfo.new(0.3), 
        {Thickness = 2, Color = Color3.fromRGB(60, 60, 255)}):Play()
end)

-- Initialize the toggle GUI with a bounce animation
ToggleButton.Size = UDim2.new(0, 0, 0, 0)
game:GetService("TweenService"):Create(ToggleButton, 
    TweenInfo.new(0.5, Enum.EasingStyle.Bounce), 
    {Size = UDim2.new(0, 50, 0, 50)}):Play()

---------------TOGGLER FOR UI-----------

-- Fluent UI Integration (preserved from original code)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
  Title = "OmniHub Script By Azzakirms",
  SubTitle = "V1.1.5",
  TabWidth = 100,
  Size = UDim2.fromOffset(380, 300),
  Acrylic = true,
  Theme = "Dark",
  MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create tabs
local Tabs = {
   Main = Window:AddTab({ Title = "Main", Icon = "eye" }),
   Visuals = Window:AddTab({ Title = "Visuals", Icon = "camera" }),
   Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
   Farming = Window:AddTab({ Title = "Farming", Icon = "dollar-sign" }),
   Premium = Window:AddTab({ Title = "Premium", Icon = "star" }),
   Discord = Window:AddTab({ Title = "Join Discord", Icon = "message-square" }),
   Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

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



-- Add ESP toggle to Visuals tab
Tabs.Visuals:AddSection("Character ESP")

-- FIX: Properly implement toggle callback
Tabs.Visuals:AddToggle("ESPToggle", {
   Title = "Esp Players",
   Default = ESP.Enabled,
   Callback = function(Value)
       ToggleESP(Value)
   end
})

Tabs.Visuals:AddToggle("RoleNotifyToggle", {
    Title = "Instant Role Notify",
    Default = RoleNotify.Enabled,
    Callback = function(Value)
        RoleNotify:Toggle(Value)
        
        -- Restart the notification system if enabled
        if Value and not RoleUpdateConnection then
            SetupRoleNotifications()
        elseif not Value and RoleUpdateConnection then
            RoleUpdateConnection:Disconnect()
            RoleUpdateConnection = nil
        end
    end
})

-- Add timer toggle to UI
Tabs.Visuals:AddToggle("TimerToggle", {
   Title = "Show Round Timer",
   Default = TimerDisplay.Enabled,
   Callback = function(Value)
       TimerDisplay:Toggle(Value)
   end
})

-- Initialize timer on script load
TimerDisplay:Start()




local SilentAimToggle = Tabs.Combat:AddToggle("SilentAimToggle", {
    Title = "Silent Aim",
    Default = false,
    Callback = function(toggle)
        _G.SilentAimEnabled = toggle
        
        if toggle then
            -- Monitor when gun is equipped
            local Players = game:GetService("Players")
            local localPlayer = Players.LocalPlayer
            
            -- Function to check for gun and shoot murderer
            local function autoShootMurderer()
                if not _G.SilentAimEnabled then return end
                
                local character = localPlayer.Character
                if not character then return end
                
                -- Check if gun is currently equipped
                local gun = character:FindFirstChild("Gun")
                if gun then
                    local murderer = GetMurderer()
                    if murderer then
                        local predictedPos = predictMurderV2(murderer)
                        if predictedPos then
                            gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, predictedPos, "AH2")
                        end
                    end
                end
            end
            
            -- Run the check on heartbeat
            _G.SilentAimConnection = game:GetService("RunService").Heartbeat:Connect(autoShootMurderer)
        else
            -- Clean up connection when toggled off
            if _G.SilentAimConnection then
                _G.SilentAimConnection:Disconnect()
                _G.SilentAimConnection = nil
            end
        end
    end
})

-- Initialize SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("OmniHub/MM2")
SaveManager:BuildConfigSection(Tabs.Settings)

-- Configure the InterfaceManager with Fluent
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("OmniHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

-- Create directory structure and files
pcall(function()
   -- Create main directories
   if not isfolder("OmniHub") then makefolder("OmniHub") end
   if not isfolder("OmniHub/MM2") then makefolder("OmniHub/MM2") end
   if not isfolder("OmniHub/language") then makefolder("OmniHub/language") end
   
   -- Create language file with specified content
   writefile("OmniHub/language/en-us.txt", "en-us")
   
   -- Create important.txt with specified message
   writefile("OmniHub/important.txt", "i created this Script By My Own Be Happy All the time")
   
   -- Create logs.txt with specified content
   writefile("OmniHub/logs.txt", "if you do anything malicious it goes here.")
   
   -- Create Discord.lua with invite link
   writefile("OmniHub/Discord.lua", "join https://discord.com/invite/3DR8b2pA2z LoL")
   
   -- HWID file with realistic format
   writefile("OmniHub/hwid.dat", string.format("%x%x%x-%x%x-%x%x-%x", 
       math.random(0x1000, 0xffff), 
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x100, 0xfff)))
end)

-- FIX: Proper initialization sequence
local function Initialize()
    -- Setup all connections
    SetupRoleTracking()
    SetupGunTracking()
    SetupPlayerConnections()
    
    -- Start ESP update loop with proper update frequency
    local ESPUpdateConnection = RunService.RenderStepped:Connect(UpdateESP)
    
    -- FIX: Proper cleanup without using BindToClose (client-side only)
    local cleanupFunction = function()
        -- Disconnect all connections
        if RoleUpdateConnection then RoleUpdateConnection:Disconnect() end
        if PlayerAddedConnection then PlayerAddedConnection:Disconnect() end
        if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end
        if ESPUpdateConnection then ESPUpdateConnection:Disconnect() end
        
        for _, conn in pairs(GunTrackingConnections) do
            conn:Disconnect()
        end
        
        -- Clean up all highlights
        for player, highlight in pairs(Highlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        
        -- Remove the highlight folder
        if HighlightFolder and HighlightFolder.Parent then
            HighlightFolder:Destroy()
        end
    end
    
    -- Register cleanup function for script termination
    if getgenv then
        getgenv().ESPCleanupFunction = cleanupFunction
    end
    
    -- Success notification
    Fluent:Notify({
       Title = "Enhanced ESP Loaded",
       Content = "Improved character outlines are now active",
       Duration = 3
    })
    
    -- Load saved configuration
    SaveManager:LoadAutoloadConfig()
end

-- Start the initialization process
Initialize()
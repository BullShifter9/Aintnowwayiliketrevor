-- MM2 Advanced Combat & ESP System
-- Developed by Azzakirms
-- High-Performance Roblox Murder Mystery Utility

-- Critical Service Initialization
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Performance Configuration
local CONFIG = {
    ESP_UPDATE_RATE = 0.2,
    RENDER_DISTANCE = 150,
    MAX_PLAYERS_RENDERED = 12,
    PREDICTION_ACCURACY = 0.85,
    OPTIMIZATION_LEVEL = 2  -- Advanced optimization
}

-- Advanced Theme Configuration
local Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Secondary = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(45, 45, 45),
    Text = Color3.fromRGB(255, 255, 255),
    NeonBlue = Color3.fromRGB(0, 255, 255),
    Success = Color3.fromRGB(0, 255, 128),
    Error = Color3.fromRGB(255, 75, 75)
}

-- Role Color Mapping
local ROLE_COLORS = {
    M = Color3.fromRGB(255, 0, 0),     -- Murderer
    S = Color3.fromRGB(0, 0, 255),     -- Sheriff
    H = Color3.fromRGB(102, 153, 0),   -- Hero
    I = Color3.fromRGB(0, 255, 0)      -- Innocent
}

-- Utility Functions
local function CreateElement(class, properties)
    local element = Instance.new(class)
    for prop, value in pairs(properties or {}) do
        element[prop] = value
    end
    return element
end

-- Advanced Dragging Module
local function CreateDraggable(gui, dragPoint)
    local dragging = false
    local offset, input

    local function update(input)
        local delta = input.Position - input.Origin
        gui.Position = UDim2.new(
            input.Start.X.Scale, 
            input.Start.X.Offset + delta.X, 
            input.Start.Y.Scale, 
            input.Start.Y.Offset + delta.Y
        )
    end

    dragPoint.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            offset = gui.Position
            input.Origin = input.Position
            input.Start = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                update(input)
            end
        end
    end)
end

-- Object Pooling System
local ObjectPool = {
    highlights = {},
    tags = {}
}

function ObjectPool.getHighlight()
    local highlight = table.remove(ObjectPool.highlights)
    if not highlight then
        highlight = Instance.new("Highlight")
    end
    return highlight
end

function ObjectPool.getTag()
    local tag = table.remove(ObjectPool.tags)
    if not tag then
        tag = Instance.new("BillboardGui")
        tag.AlwaysOnTop = true
        tag.Size = UDim2.new(0, 100, 0, 30)
        tag.StudsOffset = Vector3.new(0, 2, 0)
        
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.Parent = tag
    end
    return tag
end

-- Physics & Prediction Constants
local PHYSICS_CONSTANTS = {
    GRAVITY = 196.2,
    FRICTION_GROUND = 0.55,
    AIR_RESISTANCE = 0.035,
    PREDICTION_WINDOW = 0.75,
    PRECISION_SCALE = 15
}

-- ESP System Configuration
local ESPSystem = {
    enabled = false,
    lastUpdate = 0,
    connection = nil,
    activeESP = {},
    cachedRoles = {}
}

-- Role Update Mechanism
function ESPSystem.updateRoles()
    local success, data = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    
    if not success then 
        warn("[ESP] Role update failed")
        return 
    end
    
    table.clear(ESPSystem.cachedRoles)
    
    for name, info in pairs(data) do
        ESPSystem.cachedRoles[name] = {
            role = info.Role and info.Role:sub(1,1) or "I",
            alive = not (info.Killed or info.Dead)
        }
    end
end

return {
    CONFIG = CONFIG,
    Theme = Theme,
    CreateElement = CreateElement,
    CreateDraggable = CreateDraggable,
    ObjectPool = ObjectPool,
    ESPSystem = ESPSystem
}

-- Combat Prediction and Targeting Module
local CombatPrediction = {}

-- Advanced Velocity Simulation
function CombatPrediction.SimulateVelocity(currentVelocity, deltaTime)
    -- Non-linear velocity decay with exponential friction modeling
    local decayFactor = math.exp(-PHYSICS_CONSTANTS.FRICTION_GROUND * deltaTime)
    return Vector3.new(
        currentVelocity.X * decayFactor,
        currentVelocity.Y,  -- Vertical velocity less affected by friction
        currentVelocity.Z * decayFactor
    )
end

-- Comprehensive Trajectory Prediction Algorithm
function CombatPrediction.PredictTrajectory(murderer, localPlayer)
    -- Robust null-check to prevent potential runtime errors
    local character = murderer.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not (rootPart and humanoid) then return nil end
    
    -- State vector extraction with high-precision measurements
    local currentPosition = rootPart.Position
    local currentVelocity = rootPart.AssemblyLinearVelocity
    local moveDirection = humanoid.MoveDirection
    
    -- Configurable prediction window
    local predictionTime = PHYSICS_CONSTANTS.PREDICTION_WINDOW
    
    -- Advanced velocity simulation accounting for environmental factors
    local simulatedVelocity = CombatPrediction.SimulateVelocity(currentVelocity, predictionTime)
    
    -- Multi-dimensional trajectory calculation
    local gravitationalOffset = 0.5 * Vector3.new(0, -PHYSICS_CONSTANTS.GRAVITY, 0) * predictionTime^2
    local movementProjection = moveDirection * predictionTime * PHYSICS_CONSTANTS.PRECISION_SCALE
    
    -- Predictive position computation with multi-factor analysis
    local predictedPosition = currentPosition + 
        (simulatedVelocity * predictionTime) + 
        gravitationalOffset + 
        movementProjection
    
    -- Dynamic target acquisition
    local targetPosition = localPlayer.Character.HumanoidRootPart.Position
    local distanceToTarget = (targetPosition - predictedPosition).Magnitude
    
    -- Adaptive precision modulation
    local precisionModulator = math.min(distanceToTarget / 50, 1.2)
    
    -- Interpolated aim correction with contextual awareness
    local finalPredictedPosition = CFrame.new(predictedPosition):Lerp(
        CFrame.new(targetPosition), 
        1 - precisionModulator
    ).Position
    
    -- Stochastic refinement for subtle aim variation
    local temporalVariance = math.sin(tick() * 3) * 0.2
    local spatialVariance = math.cos(tick() * 2) * 0.15
    
    return finalPredictedPosition + Vector3.new(
        temporalVariance,
        spatialVariance,
        temporalVariance * 0.5
    )
end

-- Advanced Shot Attempt Mechanism
function CombatPrediction.AttemptShot(murderer)
    local localPlayer = Players.LocalPlayer
    
    -- Comprehensive validation layer
    if not (murderer and localPlayer.Character) then 
        warn("[Combat] Invalid shot parameters")
        return false 
    end
    
    -- Adaptive gun detection
    local gun = localPlayer.Character:FindFirstChild("Gun") or 
                localPlayer.Backpack:FindFirstChild("Gun")
    
    if not gun then 
        warn("[Combat] No gun found")
        return false 
    end
    
    -- Safe tool equipping with error handling
    if gun.Parent == localPlayer.Backpack then
        pcall(function()
            localPlayer.Character.Humanoid:EquipTool(gun)
        end)
        task.wait(0.1)
    end
    
    -- Predictive position calculation
    local predictedPosition = CombatPrediction.PredictTrajectory(murderer, localPlayer)
    
    if not predictedPosition then
        warn("[Combat] Position prediction failed")
        return false
    end
    
    -- Robust shot execution with multiple fallback methods
    local shotMethods = {
        function()
            return localPlayer.Character.Gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(
                1, predictedPosition, "AH2"
            )
        end,
        function()
            return localPlayer.Character.Gun.KnifeServer.ShootGun:InvokeServer(
                1, predictedPosition, "AH"
            )
        end
    }
    
    -- Iterative shot attempt with comprehensive error management
    for _, shotMethod in ipairs(shotMethods) do
        local success, result = pcall(shotMethod)
        if success then return true end
    end
    
    warn("[Combat] All shot methods failed")
    return false
end

-- Combat System Controller
local CombatSystem = {
    jumpPredict = false,
    pingValue = 100,
    predictionActive = false
}

-- Toggle Prediction Mode
function CombatSystem.TogglePrediction()
    CombatSystem.predictionActive = not CombatSystem.predictionActive
    return CombatSystem.predictionActive
end

-- Find Potential Murderer
function CombatSystem.FindMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Knife") then
            return player
        end
    end
    return nil
end

return {
    CombatPrediction = CombatPrediction,
    CombatSystem = CombatSystem
}

-- Advanced UI System for Murder Mystery 2
-- Developed with precision and performance optimization

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Import previous modules
local BaseModule = require(script.Parent.BaseModule)
local CombatModule = require(script.Parent.CombatModule)

-- UI Configuration Constants
local UI_CONFIG = {
    THEME = {
        PRIMARY_BG = Color3.fromRGB(25, 25, 25),
        SECONDARY_BG = Color3.fromRGB(35, 35, 35),
        ACCENT = Color3.fromRGB(60, 60, 60),
        TEXT_COLOR = Color3.fromRGB(220, 220, 220),
        HIGHLIGHT = Color3.fromRGB(0, 255, 128)
    },
    SIZING = {
        MAIN_WIDTH = 500,
        MAIN_HEIGHT = 600,
        BUTTON_HEIGHT = 40,
        ICON_SIZE = 50
    }
}

-- Advanced UI Creation Module
local UISystem = {}

-- Sophisticated Element Creation Wrapper
function UISystem.CreateStyledElement(elementType, properties)
    local element = Instance.new(elementType)
    
    -- Apply base styling
    element.BackgroundColor3 = UI_CONFIG.THEME.SECONDARY_BG
    element.BorderSizePixel = 0
    
    -- Apply custom properties
    for prop, value in pairs(properties or {}) do
        element[prop] = value
    end
    
    -- Add rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = element
    
    return element
end

-- Advanced Draggable Interface
function UISystem.MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
                                    startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Advanced ESP System for Murder Mystery 2
-- Developed with high-performance rendering and precision tracking

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Import previous modules
local BaseModule = require(script.Parent.BaseModule)
local UIModule = require(script.Parent.UIModule)

-- ESP Performance and Configuration
local ESP_CONFIG = {
    RENDER_DISTANCE = 250,    -- Maximum visibility range
    UPDATE_INTERVAL = 0.1,    -- Refresh rate for ESP updates
    MAX_PLAYERS = 12,         -- Maximum players to render
    OPTIMIZATION_LEVEL = 2    -- Advanced rendering optimization
}

-- Advanced ESP Rendering System
local ESPRenderer = {
    ActiveHighlights = {},    -- Cached highlight objects
    ActiveTrackers = {},      -- Player tracking containers
    Enabled = false           -- Global ESP state
}

-- Efficient Object Pooling for Highlights
function ESPRenderer.GetHighlightFromPool()
    local highlight = table.remove(ESPRenderer.ActiveHighlights)
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.OutlineTransparency = 0.5
        highlight.FillTransparency = 0.7
    end
    return highlight
end

-- Role-Based Color Mapping
function ESPRenderer.GetRoleColor(role)
    local colorMap = {
        M = Color3.fromRGB(255, 0, 0),     -- Murderer (Red)
        S = Color3.fromRGB(0, 0, 255),     -- Sheriff (Blue)
        H = Color3.fromRGB(0, 255, 0),     -- Hero (Green)
        I = Color3.fromRGB(255, 255, 0)    -- Innocent (Yellow)
    }
    return colorMap[role] or Color3.fromRGB(200, 200, 200)
end

-- Advanced Player Tracking Mechanism
function ESPRenderer.TrackPlayer(player, roleData)
    -- Validate player and character
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    -- Create or retrieve existing tracker
    local tracker = ESPRenderer.ActiveTrackers[player.Name]
    if not tracker then
        tracker = {
            Highlight = ESPRenderer.GetHighlightFromPool(),
            LastUpdate = 0
        }
        ESPRenderer.ActiveTrackers[player.Name] = tracker
    end

    -- Configure highlight properties
    local highlight = tracker.Highlight
    highlight.Parent = player.Character
    highlight.FillColor = ESPRenderer.GetRoleColor(roleData.role)
    highlight.OutlineColor = ESPRenderer.GetRoleColor(roleData.role)

    return tracker
end

-- Optimized ESP Update Routine
function ESPRenderer.UpdateESP()
    if not ESPRenderer.Enabled then return end

    local localPlayer = Players.LocalPlayer
    if not localPlayer or not localPlayer.Character then return end

    local currentTick = tick()
    local localPosition = localPlayer.Character.HumanoidRootPart.Position

    -- Efficient player scanning and rendering
    local renderedPlayers = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and renderedPlayers < ESP_CONFIG.MAX_PLAYERS then
            local character = player.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local distance = (rootPart.Position - localPosition).Magnitude
                    if distance <= ESP_CONFIG.RENDER_DISTANCE then
                        -- Retrieve role data (assuming previous implementation)
                        local roleData = BaseModule.ESPSystem.cachedRoles[player.Name]
                        if roleData and roleData.alive then
                            ESPRenderer.TrackPlayer(player, roleData)
                            renderedPlayers += 1
                        end
                    end
                end
            end
        end
    end
end

-- ESP Toggle Mechanism
function ESPRenderer.ToggleESP()
    ESPRenderer.Enabled = not ESPRenderer.Enabled
    
    if not ESPRenderer.Enabled then
        -- Clean up active trackers
        for _, tracker in pairs(ESPRenderer.ActiveTrackers) do
            if tracker.Highlight then
                tracker.Highlight.Parent = nil
                table.insert(ESPRenderer.ActiveHighlights, tracker.Highlight)
            end
        end
        ESPRenderer.ActiveTrackers = {}
    end
end

-- Continuous Update Connection
local function InitializeESPLoop()
    local updateConnection
    updateConnection = RunService.Heartbeat:Connect(function()
        if ESPRenderer.Enabled then
            ESPRenderer.UpdateESP()
        else
            if updateConnection then
                updateConnection:Disconnect()
            end
        end
    end)
end

-- Expose Module Functions
return {
    Renderer = ESPRenderer,
    Initialize = InitializeESPLoop,
    Config = ESP_CONFIG
}

-- Create Main UI Container
function UISystem.CreateMainUI()
    local screenGui = UISystem.CreateStyledElement("ScreenGui", {
        Name = "MM2EnhancedHUD",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    -- Attempt to protect GUI for exploit prevention
    pcall(function()
        if syn then 
            syn.protect_gui(screenGui) 
        end
    end)

    -- Parent to appropriate container
    screenGui.Parent = game:GetService("CoreGui")

    -- Main Container Frame
    local mainFrame = UISystem.CreateStyledElement("Frame", {
        Size = UDim2.new(0, UI_CONFIG.SIZING.MAIN_WIDTH, 
                         0, UI_CONFIG.SIZING.MAIN_HEIGHT),
        Position = UDim2.new(0.5, -UI_CONFIG.SIZING.MAIN_WIDTH/2, 
                              0.5, -UI_CONFIG.SIZING.MAIN_HEIGHT/2),
        BackgroundColor3 = UI_CONFIG.THEME.PRIMARY_BG,
        Parent = screenGui
    })

    -- Title Bar
    local titleBar = UISystem.CreateStyledElement("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = UI_CONFIG.THEME.SECONDARY_BG,
        Parent = mainFrame
    })

    local titleText = UISystem.CreateStyledElement("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        Text = "MM2 Enhanced",
        TextColor3 = UI_CONFIG.THEME.TEXT_COLOR,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        BackgroundTransparency = 1,
        Parent = titleBar
    })

    -- Make UI Draggable
    UISystem.MakeDraggable(mainFrame, titleBar)

    -- Tabs Container
    local tabContainer = UISystem.CreateStyledElement("Frame", {
        Size = UDim2.new(1, -20, 0, 50),
        Position = UDim2.new(0, 10, 0, 60),
        BackgroundColor3 = UI_CONFIG.THEME.ACCENT,
        Parent = mainFrame
    })

    -- Tab Creation Function
    local function CreateTab(name, onClick)
        local tabButton = UISystem.CreateStyledElement("TextButton", {
            Size = UDim2.new(0.25, -10, 1, 0),
            Text = name,
            TextColor3 = UI_CONFIG.THEME.TEXT_COLOR,
            BackgroundColor3 = UI_CONFIG.THEME.SECONDARY_BG,
            Parent = tabContainer
        })

        tabButton.MouseButton1Click:Connect(onClick or function() end)
        return tabButton
    end

    -- Create Tabs
    local espTab = CreateTab("ESP", function()
        print("ESP Tab Clicked")
    end)

    local combatTab = CreateTab("Combat", function()
        print("Combat Tab Clicked")
    end)

    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        Tabs = {
            ESP = espTab,
            Combat = combatTab
        }
    }
end

-- Initialize UI
local MainUI = UISystem.CreateMainUI()

return {
    UI = MainUI,
    CreateUI = UISystem.CreateMainUI
}

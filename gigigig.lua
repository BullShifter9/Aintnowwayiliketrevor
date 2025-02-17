local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GetPlayerData = game.ReplicatedStorage:FindFirstChild("GetPlayerData", true)
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local TrapSystem = ReplicatedStorage.TrapSystem
local LocalPlayer = Players.LocalPlayer
local GameplayEvents = ReplicatedStorage.Remotes.Gameplay
local AutoNotifyEnabled = true
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local SupportedGameID = 142823291  -- Murder Mystery 2 Place ID

if game.PlaceId ~= SupportedGameID then
    LocalPlayer:Kick("Game Not Supported\n\nSupported Games:\nMurder Mystery 2")
end

-- Global State Management
local state = {
   espEnabled = false,
   espColors = {
       murderer = Color3.fromRGB(255, 0, 0),
       sheriff = Color3.fromRGB(0, 0, 255),
       hero = Color3.fromRGB(255, 255, 0),
       innocent = Color3.fromRGB(0, 255, 0),
       gunDrop = Color3.fromRGB(128, 0, 128)
   },
   roles = {},
   murder = nil,
   sheriff = nil,
   hero = nil,
   gunDrop = nil,
   autoGetGunDropEnabled = false,
   originalPosition = nil,
   murdererNearDistance = 15
}


--Prediction State
local predictionState = {
   pingEnabled = false,
   pingValue = 50
}


-- ESP System Setup
local ESPFolder = Instance.new("Folder", CoreGui)
ESPFolder.Name = "ESPElements"

local ESPSystem = {
   pool = {},
   active = {},
   updateQueue = {}
}

-- ESP Pool Management
function ESPSystem.getFromPool()
   local esp = table.remove(ESPSystem.pool)
   if not esp then
       esp = {
           highlight = Instance.new("Highlight"),
           billboard = Instance.new("BillboardGui"),
           label = Instance.new("TextLabel")
       }
       
       esp.highlight.FillTransparency = 0.5
       esp.highlight.OutlineTransparency = 0
       
       esp.billboard.AlwaysOnTop = true
       esp.billboard.Size = UDim2.new(0, 200, 0, 50)
       esp.billboard.StudsOffset = Vector3.new(0, 3, 0)
       
       esp.label.BackgroundTransparency = 1
       esp.label.Size = UDim2.new(1, 0, 1, 0)
       esp.label.TextSize = 14
       esp.label.Font = Enum.Font.GothamBold
       
       esp.billboard.Parent = ESPFolder
       esp.highlight.Parent = ESPFolder
       esp.label.Parent = esp.billboard
   end
   return esp
end

function ESPSystem.returnToPool(esp)
   esp.highlight.Adornee = nil
   esp.billboard.Adornee = nil
   esp.label.Text = ""
   table.insert(ESPSystem.pool, esp)
end

-- Player ESP Update
function ESPSystem.updatePlayer(player)
   if player == LocalPlayer then return end
   
   local character = player.Character
   if not character or not character:FindFirstChild("HumanoidRootPart") then
       if ESPSystem.active[player] then
           ESPSystem.returnToPool(ESPSystem.active[player])
           ESPSystem.active[player] = nil
       end
       return
   end
   
   local role = "innocent"
   local color = state.espColors.innocent
   
   if player.Name == state.murder then
       role = "murderer"
       color = state.espColors.murderer
   elseif player.Name == state.sheriff then
       role = "sheriff"
       color = state.espColors.sheriff
   elseif player.Name == state.hero then
       role = "hero"
       color = state.espColors.hero
   end
   
   local esp = ESPSystem.active[player] or ESPSystem.getFromPool()
   ESPSystem.active[player] = esp
   
   esp.highlight.Adornee = character
   esp.billboard.Adornee = character:FindFirstChild("Head")
   esp.highlight.FillColor = color
   esp.highlight.OutlineColor = color
   esp.label.TextColor3 = color
   esp.label.Text = string.format("%s (%s)", player.Name, role:upper())
end

-- Gun Drop ESP
function ESPSystem.updateGunDrop()
   if not state.espEnabled or not state.gunDrop then return end
   
   local gunDropESP = ESPSystem.active["GunDrop"] or ESPSystem.getFromPool()
   ESPSystem.active["GunDrop"] = gunDropESP
   
   gunDropESP.highlight.Adornee = state.gunDrop
   gunDropESP.billboard.Adornee = state.gunDrop
   
   gunDropESP.highlight.FillColor = state.espColors.gunDrop
   gunDropESP.highlight.OutlineColor = state.espColors.gunDrop
   gunDropESP.highlight.FillTransparency = 0.7
   
   gunDropESP.label.TextColor3 = state.espColors.gunDrop
   gunDropESP.label.Text = "GUN DROP"
end

-- Role and Gun Drop Detection
RunService.Heartbeat:Connect(function()
   state.roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
   
   for playerName, playerData in pairs(state.roles) do
       if playerData.Role == "Murderer" then
           state.murder = playerName
       elseif playerData.Role == "Sheriff" then
           state.sheriff = playerName
       elseif playerData.Role == "Hero" then
           state.hero = playerName
       end
   end

   if state.espEnabled then
       for _, player in ipairs(Players:GetPlayers()) do
           ESPSystem.updatePlayer(player)
       end
       ESPSystem.updateGunDrop()
   end
end)

-- Gun Drop Tracking
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

-- Player Management
Players.PlayerAdded:Connect(function(player)
   if state.espEnabled then
       ESPSystem.updatePlayer(player)
   end
end)

Players.PlayerRemoving:Connect(function(player)
   if ESPSystem.active[player] then
       ESPSystem.returnToPool(ESPSystem.active[player])
       ESPSystem.active[player] = nil
   end
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
   -- Initial character validation
   local character = murderer.Character
   if not character then return nil end

   local rootPart = character:FindFirstChild("HumanoidRootPart")
   local humanoid = character:FindFirstChild("Humanoid")
   if not rootPart or not humanoid then return nil end

   -- Constants for ultra-precise physics calculations
   local PHYSICS = {
       TICK_RATE = 1/240,  -- Sub-millisecond precision
       GRAVITY = workspace.Gravity,
       BASE_JUMP_POWER = humanoid.JumpPower,
       WALK_SPEED = humanoid.WalkSpeed,
       MAX_PREDICTION_STEPS = 32,
       VELOCITY_SAMPLES = 24,
       PRECISION_THRESHOLD = 0.001
   }

   -- Targeting parameters with high confidence thresholds
   local TARGETING = {
       VELOCITY_WEIGHT = 0.95,
       DIRECTION_WEIGHT = 0.92,
       ACCELERATION_WEIGHT = 0.88,
       MOMENTUM_FACTOR = 0.85,
       PREDICTION_CONFIDENCE = 0.96,
       HIT_PROBABILITY = 0.98,
       ERROR_MARGIN = 0.02,
       VERTICAL_OFFSET = 4.2
   }

   -- Movement analysis parameters
   local MOVEMENT = {
       GROUND_FRICTION = 0.94,
       AIR_RESISTANCE = 0.97,
       TURN_SPEED_FACTOR = 0.92,
       ACCELERATION_CURVE = 0.90,
       DECELERATION_CURVE = 0.94,
       JUMP_PREDICTION = 0.96,
       MOVEMENT_SMOOTHING = 0.98
   }

   -- State tracking with confidence scoring
   local state = {
       position = rootPart.Position,
       velocity = rootPart.AssemblyLinearVelocity,
       velocityHistory = {},
       accelerationVector = Vector3.new(),
       moveDirection = humanoid.MoveDirection,
       isJumping = humanoid.Jump,
       lastGroundTime = 0,
       confidenceScore = 1.0,
       hitProbability = 1.0
   }

   -- Initialize velocity history buffer
   for i = 1, PHYSICS.VELOCITY_SAMPLES do
       table.insert(state.velocityHistory, state.velocity)
   end

   -- Calculate movement with probability weighting
   local function calculateProbabilisticMovement()
       local baseVel = state.velocity
       local targetVel = state.moveDirection * PHYSICS.WALK_SPEED
       
       -- Calculate weighted acceleration
       local acceleration = Vector3.new()
       local confidenceSum = 0
       
       for i = 2, #state.velocityHistory do
           local velDelta = state.velocityHistory[i] - state.velocityHistory[i-1]
           local confidence = 1 - ((i-1) / #state.velocityHistory)
           acceleration = acceleration + (velDelta * confidence * TARGETING.ACCELERATION_WEIGHT)
           confidenceSum = confidenceSum + confidence
       end
       
       acceleration = acceleration / confidenceSum
       
       -- Calculate predicted velocity
       local predictedVel = (baseVel * TARGETING.VELOCITY_WEIGHT) +
                           (targetVel * TARGETING.DIRECTION_WEIGHT) +
                           (acceleration * TARGETING.MOMENTUM_FACTOR)
       
       -- Update confidence score
       state.confidenceScore = math.min(
           state.confidenceScore * TARGETING.PREDICTION_CONFIDENCE,
           TARGETING.HIT_PROBABILITY
       )
       
       return predictedVel * state.confidenceScore
   end

   -- Analyze ground contact
   local function checkGroundContact()
       local params = RaycastParams.new()
       params.FilterType = Enum.RaycastFilterType.Blacklist
       params.FilterDescendantsInstances = {character}

       local result = workspace:Raycast(
           state.position,
           Vector3.new(0, -TARGETING.VERTICAL_OFFSET * 2, 0),
           params
       )

       if result then
           state.lastGroundTime = tick()
           return result.Position.Y
       end
       return nil
   end

   -- Predict final position with confidence thresholds
   local function predictFinalPosition()
       local simState = {
           pos = state.position,
           vel = calculateProbabilisticMovement(),
           confidence = state.confidenceScore
       }

       for step = 1, PHYSICS.MAX_PREDICTION_STEPS do
           local stepWeight = step / PHYSICS.MAX_PREDICTION_STEPS
           local precisionMultiplier = 1 - (stepWeight * (1 - MOVEMENT.MOVEMENT_SMOOTHING))
           
           -- Calculate movement with error margin
           local movement = simState.vel * PHYSICS.TICK_RATE * precisionMultiplier
           movement = movement * (1 - TARGETING.ERROR_MARGIN * stepWeight)
           
           -- Update position
           simState.pos = simState.pos + movement

           -- Apply gravity
           if not checkGroundContact() then
               simState.pos = simState.pos + Vector3.new(
                   0,
                   -0.5 * PHYSICS.GRAVITY * (PHYSICS.TICK_RATE ^ 2),
                   0
               )
           end

           -- Update confidence
           simState.confidence = simState.confidence * 
               (1 - stepWeight * (1 - TARGETING.PREDICTION_CONFIDENCE))
           
           -- Break if confidence drops too low
           if simState.confidence < TARGETING.PREDICTION_CONFIDENCE then
               break
           end
           
           -- Update velocity history
           table.remove(state.velocityHistory, 1)
           table.insert(state.velocityHistory, simState.vel)
       end

       -- Return position if confidence meets threshold
       if simState.confidence >= TARGETING.PREDICTION_CONFIDENCE then
           state.hitProbability = simState.confidence
           return simState.pos
       end
       
       return state.position
   end

   -- Execute final prediction
   local predictedPosition = predictFinalPosition()
   
   -- Return predicted position if probability threshold is met
   if state.hitProbability >= TARGETING.HIT_PROBABILITY then
       return predictedPosition
   end
   
   return state.position
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

-- Silent Aim V2 Button Click Event
SilentAimButtonV2.MouseButton1Click:Connect(function()
    local localPlayer = Players.LocalPlayer
    local gun = localPlayer.Character:FindFirstChild("Gun") or localPlayer.Backpack:FindFirstChild("Gun")

    if not gun then return end

    local murderer = GetMurderer()
    if not murderer then return end

    localPlayer.Character.Humanoid:EquipTool(gun)

    local predictedPos = predictMurderV2(murderer)
    if predictedPos then
        gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, predictedPos, "AH2")
    end
end)

local function NotifyMurdererPerk()
    if not AutoNotifyEnabled then
        return
    end

    local murdererPlayer = GetMurderer()

    if not murdererPlayer then
        Fluent:Notify({
            Title = "🕵️ Murderer Detection",
            Content = "No murderer found in current round.",
            Duration = 3
        })
        return
    end

    local knownPerks = {
        "Xray",
        "Footsteps",
        "Sleight",
        "Ninja",
        "Sprint",
        "Fake Gun",
        "Haste",
        "Trap",
        "Ghost"
    }

    local murdererFolder = workspace:FindFirstChild(murdererPlayer.Name)
    local detectedPerk = nil

    if murdererFolder then
        for _, perkName in ipairs(knownPerks) do
            if murdererFolder:FindFirstChild(perkName) then
                detectedPerk = perkName
                break
            end
        end
    end

    if detectedPerk then
        Fluent:Notify({
            Title = " Murderer Perk Detected",
            Content = string.format(
                "%s is using the %s Perk!", 
                murdererPlayer.Name, 
                detectedPerk
            ),
            Duration = 5
        })
    else
        Fluent:Notify({
            Title = " Murderer Found",
            Content = murdererPlayer.Name .. " detected, but no perk information available.",
            Duration = 4
        })
    end
end

GameplayEvents.RoundStart.OnClientEvent:Connect(function()
    task.wait(0.5)
    NotifyMurdererPerk()
end)


local function predictMurderSharpShooter(murderer)
   local character = murderer.Character
   if not character then return nil end
   
   local primaryPart = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
   local humanoid = character:FindFirstChild("Humanoid")
   if not primaryPart or not humanoid then return nil end

   -- Physics and prediction constants
   local CONSTANTS = {
       TICK_RATE = 0.016,            -- Base simulation tick rate (60 FPS)
       GRAVITY = 196.2,              -- Roblox physics gravity constant
       MAX_PREDICTION_STEPS = 15,     -- Prediction iteration limit
       JUMP_POWER = humanoid.JumpPower or 50,
       WALK_SPEED = humanoid.WalkSpeed,
       
       -- Logarithmic scaling parameters
       LOG_BASE = math.exp(1),       -- Natural logarithm base
       SCALE_FACTOR = 1.5,           -- Logarithmic curve steepness
       MIN_LOG_VALUE = 0.1,          -- Minimum value for log scaling
       MAX_LOG_VALUE = 5.0,          -- Maximum value for log scaling
       
       -- Advanced tuning parameters
       VELOCITY_WEIGHT = 0.7,
       DIRECTION_WEIGHT = 0.3,
       ACCELERATION_CAP = 75,
       PREDICTION_SMOOTHING = 0.85,
       WALL_OFFSET = 2.5,
       
       -- Logarithmic decay constants
       DISTANCE_DECAY = 0.8,         -- Distance-based prediction decay
       TIME_DECAY = 0.9              -- Time-based prediction decay
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



-- Fluent UI Integration
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

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
    Premium = Window:AddTab({ Title = "Premium", Icon = "star" }),
    Discord = Window:AddTab({ Title = "Join Discord", Icon = "message-square" }),
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
    Title = "Anti-Kick Protection",
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
local ESPToggle = Tabs.Visuals:AddToggle("ESPToggle", {
   Title = "Player ESP",
   Default = false 
})

ESPToggle:OnChanged(function()
   state.espEnabled = ESPToggle.Value
   
   if not state.espEnabled then
       for player, esp in pairs(ESPSystem.active) do
           ESPSystem.returnToPool(esp)
       end
       ESPSystem.active = {}
   end
end)

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

local TrapEspToggle = Tabs.Visuals:AddToggle("ShowTrapESP", {
    Title = "Show Trap ESP",
    Default = true,
    Callback = function(Value)
        for _, trap in pairs(workspace:GetChildren()) do
            if trap:FindFirstChild("TrapVisual") then
                if Value then
                    highlightTrap(trap.TrapVisual)
                else
                    removeHighlight(trap.TrapVisual)
                end
            end
        end
    end
})

local function highlightTrap(trapVisual)
    local highlight = Instance.new("Highlight")
    highlight.Name = "TrapHighlight"
    highlight.Adornee = trapVisual
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent = trapVisual
end

local function removeHighlight(trapVisual)
    local highlight = trapVisual:FindFirstChild("TrapHighlight")
    if highlight then
        highlight:Destroy()
    end
end

local function onTrapAdded(trap)
    if trap:FindFirstChild("TrapVisual") and TrapEspToggle.Value then
        highlightTrap(trap.TrapVisual)
    end
end

workspace.ChildAdded:Connect(onTrapAdded)


-- Combat Tab Content
local SilentAimToggle = Tabs.Combat:AddToggle("SilentAimToggle", {
    Title = "Silent Aim",
    Default = false,
    Callback = function(toggle)
        SilentAimButtonV2.Visible = toggle
    end
})

local SharpShooterToggle = Tabs.Combat:AddToggle("SharpShooterToggle", {
    Title = "Sharp Shooter",
    Default = false,
    Callback = function(toggle)
        SharpShooterEnabled = toggle
        Fluent:Notify({
            Title = "Sharp Shooter",
            Content = toggle and "Sharp Shooter is now ENABLED." or "Sharp Shooter is now DISABLED.",
            Duration = 3
        })
    end
})

-- Configure gun break functionality section
local GunSection = Tabs.Combat:AddSection("Gun Control Features")

-- Initialize state management
local autoBreakEnabled = false
local breakCooldown = 0.1 -- Configurable cooldown between break attempts

-- Core gun break implementation 
local function attemptGunBreak()
    local localPlayer = game.Players.LocalPlayer
    
    -- Validate gun existence
    local gun = localPlayer.Character and localPlayer.Character:FindFirstChild("Gun")
                or localPlayer.Backpack:FindFirstChild("Gun")
    
    if gun then
        -- Execute gun break through remote
        game:GetService("Players").KnifeServer.ShootGun:InvokeServer(1, "AH2")
    end
end

-- Auto break execution loop
local function autoBreakLoop()
    while autoBreakEnabled do
        local success, err = pcall(attemptGunBreak)
        if not success then
            -- Silent error handling to maintain loop
            task.wait(breakCooldown * 2) -- Increased cooldown on failure
        else
            task.wait(breakCooldown)
        end
    end
end

-- Toggle implementation
local AutoBreakToggle = Tabs.Combat:AddToggle("AutoBreakGunToggle", {
    Title = "Auto Break Gun",
    Default = false,
    Callback = function(toggle)
        autoBreakEnabled = toggle
        
        if toggle then
            -- Initialize break sequence
            task.spawn(autoBreakLoop)
            
            Fluent:Notify({
                Title = "Gun Break",
                Content = "Auto gun break enabled",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Gun Break",
                Content = "Auto gun break disabled",
                Duration = 2
            })
        end
    end
})

-- Cooldown configuration slider
local BreakDelaySlider = Tabs.Combat:AddSlider("BreakDelaySlider", {
    Title = "Break Attempt Delay",
    Default = 0.1,
    Min = 0.05,
    Max = 1.0,
    Rounding = 2,
    Callback = function(value)
        breakCooldown = value
    end
})

local PredictionPingToggle = Tabs.Combat:AddToggle("PredictionPingToggle", {
   Title = "Prediction Ping",
   Default = false,
   Callback = function(toggle)
       predictionState.pingEnabled = toggle
       Fluent:Notify({
           Title = "Prediction Ping",
           Content = toggle and "Prediction Ping Enabled" or "Prediction Ping Disabled",
           Duration = 3
       })
   end
})

local PingSlider = Tabs.Combat:AddSlider("PingSlider", {
   Title = "Prediction Ping Value",
   Description = "Adjust ping",
   Default = 50,
   Min = 0,
   Max = 300,
   Rounding = 0,
   Callback = function(value)
       predictionState.pingValue = value
   end
})

local AutoNotifyToggle = Tabs.Combat:AddToggle("AutoNotifyToggle", {
    Title = "Auto Notify Murderers Perk",
    Default = true,
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
    local gunDropPosition = gunDrop.Position
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    -- Store original position
    state.originalPosition = character.HumanoidRootPart.Position

    if isMurdererNear(gunDropPosition) then
        return
    end

    -- Move to gun instantly
    character.HumanoidRootPart.CFrame = CFrame.new(gunDropPosition)

    -- Simulate touch to pick up gun instantly
    firetouchinterest(character.HumanoidRootPart, gunDrop, 0)
    firetouchinterest(character.HumanoidRootPart, gunDrop, 1)

    -- Wait a brief moment to ensure gun is collected
    task.wait(0.1)

    -- Return to original position instantly
    character.HumanoidRootPart.CFrame = CFrame.new(state.originalPosition)
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

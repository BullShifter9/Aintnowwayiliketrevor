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
local AutoNotifyEnabled = true
local Players = game:GetService("Players")


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

local Loader = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local LoaderTitle = Instance.new("TextLabel") 
local Subtitle = Instance.new("TextLabel")
local LoadingBar = Instance.new("Frame")
local LoadingBarFill = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local UICorner_3 = Instance.new("UICorner")
local StatusText = Instance.new("TextLabel")
local GlowEffect = Instance.new("ImageLabel")

-- Set up hierarchy with enhanced dimensions
Loader.Name = "OmniLoader"
Loader.Parent = game.CoreGui

MainFrame.Name = "LoaderFrame"
MainFrame.Parent = Loader
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25) -- Slightly darker for better contrast
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150) -- Adjusted for larger size
MainFrame.Size = UDim2.new(0, 400, 0, 300) -- Increased size
MainFrame.ClipsDescendants = true

UICorner.CornerRadius = UDim.new(0, 12) -- Slightly larger corners
UICorner.Parent = MainFrame

GlowEffect.Name = "Glow"
GlowEffect.Parent = MainFrame
GlowEffect.BackgroundTransparency = 1
GlowEffect.Position = UDim2.new(0, -20, 0, -20)
GlowEffect.Size = UDim2.new(1, 40, 1, 40)
GlowEffect.Image = "rbxassetid://5028857084"
GlowEffect.ImageColor3 = Color3.fromRGB(255, 215, 0)
GlowEffect.ImageTransparency = 0.7 -- Slightly more visible glow

-- Enhanced text styling
LoaderTitle.Name = "Title"
LoaderTitle.Parent = MainFrame
LoaderTitle.BackgroundTransparency = 1
LoaderTitle.Position = UDim2.new(0, 0, 0.15, 0)
LoaderTitle.Size = UDim2.new(1, 0, 0, 40)
LoaderTitle.Font = Enum.Font.GothamBold
LoaderTitle.Text = "OmniHub"
LoaderTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
LoaderTitle.TextSize = 32 -- Larger text
LoaderTitle.TextStrokeTransparency = 0.8 -- Added subtle text stroke
LoaderTitle.TextStrokeColor3 = Color3.fromRGB(255, 215, 0)

Subtitle.Name = "Subtitle"
Subtitle.Parent = MainFrame
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.new(0, 0, 0.35, 0)
Subtitle.Size = UDim2.new(1, 0, 0, 25)
Subtitle.Font = Enum.Font.GothamSemibold -- Changed to semibold
Subtitle.Text = "Please Wait.. Also Join My Discord"
Subtitle.TextColor3 = Color3.fromRGB(220, 220, 220)
Subtitle.TextSize = 18

-- Enhanced loading bar
LoadingBar.Name = "LoadingBar"
LoadingBar.Parent = MainFrame
LoadingBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
LoadingBar.Position = UDim2.new(0.1, 0, 0.65, 0)
LoadingBar.Size = UDim2.new(0.8, 0, 0, 8) -- Slightly thicker

LoadingBarFill.Name = "Fill"
LoadingBarFill.Parent = LoadingBar
LoadingBarFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)

UICorner_2.CornerRadius = UDim.new(0, 4)
UICorner_2.Parent = LoadingBar

UICorner_3.CornerRadius = UDim.new(0, 4)
UICorner_3.Parent = LoadingBarFill

StatusText.Name = "Status"
StatusText.Parent = MainFrame
StatusText.BackgroundTransparency = 1
StatusText.Position = UDim2.new(0, 0, 0.8, 0)
StatusText.Size = UDim2.new(1, 0, 0, 25)
StatusText.Font = Enum.Font.GothamMedium
StatusText.Text = "Initializing..."
StatusText.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusText.TextSize = 16

-- Enhanced loading sequence
local TweenService = game:GetService("TweenService")

local function animateLoader()
   local loadingStages = {
       {"Verifying premium access...", 0.2},
       {"Loading core modules...", 0.4},
       {"Optimizing performance...", 0.6},
       {"Preparing user interface...", 0.8},
       {"Ready to launch...", 1}
   }

   for _, stage in ipairs(loadingStages) do
       StatusText.Text = stage[1]
       
       local fillTween = TweenService:Create(LoadingBarFill, 
           TweenInfo.new(2, Enum.EasingStyle.Linear), -- Changed to 5 seconds with Linear style
           {Size = UDim2.new(stage[2], 0, 1, 0)}
       )
       fillTween:Play()
       fillTween.Completed:Wait()
       task.wait(0.3) -- Small pause between stages
   end

   task.wait(0.6)
   
   -- Fade out animation remains the same
   local fadeOut = TweenService:Create(MainFrame,
       TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
       {BackgroundTransparency = 1}
   )
   
   for _, element in ipairs(MainFrame:GetDescendants()) do
       if element:IsA("TextLabel") then
           TweenService:Create(element,
               TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
               {TextTransparency = 1}
           ):Play()
       elseif element:IsA("Frame") and element.Name ~= "LoaderFrame" then
           TweenService:Create(element,
               TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
               {BackgroundTransparency = 1}
           ):Play()
       elseif element:IsA("ImageLabel") then
           TweenService:Create(element,
               TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
               {ImageTransparency = 1}
           ):Play()
       end
   end
   
   fadeOut:Play()
   fadeOut.Completed:Wait()
   
   Loader:Destroy()
end

-- Start the loading sequence
animateLoader()

if game.PlaceId ~= 142823291 then
    local player = game.Players.LocalPlayer
    player:Kick("\nGame Not Supported\n\nSupported Games:\n• Murder Mystery 2")
    return
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

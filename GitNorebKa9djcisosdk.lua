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
local BreakGunEnabled = false -- Default: Disabled

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

   -- Optimized physics constants
   local PHYSICS = {
       TICK_RATE = 1/60,
       GRAVITY = workspace.Gravity,
       BASE_JUMP_POWER = humanoid.JumpPower,
       WALK_SPEED = humanoid.WalkSpeed,
       MAX_PREDICTION_STEPS = 12
   }

   -- Advanced targeting parameters 
   local TARGETING = {
       VELOCITY_WEIGHT = 0.65,         -- Historical velocity influence
       DIRECTION_WEIGHT = 0.35,        -- Current direction influence
       RANDOM_DEVIATION = 0.15,        -- Maximum random trajectory deviation
       VERTICAL_OFFSET = 3.5,          -- Target height adjustment
       ACCELERATION_DAMPING = 0.85,    -- Smooth acceleration changes
       MIN_PREDICTION_DISTANCE = 5,    -- Minimum prediction range
       MAX_PREDICTION_DISTANCE = 100   -- Maximum prediction range
   }

   -- Initialize prediction state
   local state = {
       position = rootPart.Position,
       velocity = rootPart.AssemblyLinearVelocity,
       moveDirection = humanoid.MoveDirection,
       isJumping = humanoid.Jump,
       lastGroundTime = 0
   }

   -- Calculate adaptive velocity with momentum
   local function computeAdaptiveVelocity()
       local baseVel = state.velocity
       local inputVel = state.moveDirection * PHYSICS.WALK_SPEED
       
       -- Apply weighted velocity blending
       local blendedVel = (baseVel * TARGETING.VELOCITY_WEIGHT) + 
                         (inputVel * TARGETING.DIRECTION_WEIGHT)

       -- Add controlled random deviation for prediction uncertainty
       local deviation = Vector3.new(
           math.random(-100, 100) / 100 * TARGETING.RANDOM_DEVIATION,
           0,
           math.random(-100, 100) / 100 * TARGETING.RANDOM_DEVIATION
       )

       return blendedVel + (blendedVel * deviation)
   end

   -- Enhanced ground detection with caching
   local function checkGroundContact()
       local rayParams = RaycastParams.new()
       rayParams.FilterType = Enum.RaycastFilterType.Blacklist
       rayParams.FilterDescendantsInstances = {character}

       local result = workspace:Raycast(
           state.position,
           Vector3.new(0, -TARGETING.VERTICAL_OFFSET * 1.5, 0),
           rayParams
       )

       if result then
           state.lastGroundTime = tick()
           return result.Position.Y
       end
       return nil
   end

   -- Predictive jump trajectory calculation
   local function predictJumpArc()
       if not state.isJumping then return state.position end

       local timeInAir = (tick() - state.lastGroundTime)
       local jumpApex = PHYSICS.BASE_JUMP_POWER * timeInAir - 
                       (0.5 * PHYSICS.GRAVITY * timeInAir ^ 2)

       return state.position + Vector3.new(
           0,
           math.max(jumpApex, 0) * TARGETING.ACCELERATION_DAMPING,
           0
       )
   end

   -- Main prediction loop with collision handling
   local predictedPosition = state.position
   local currentVelocity = computeAdaptiveVelocity()

   for step = 1, PHYSICS.MAX_PREDICTION_STEPS do
       local stepWeight = step / PHYSICS.MAX_PREDICTION_STEPS
       
       -- Update position with velocity and gravity
       local nextPosition = predictedPosition + 
           (currentVelocity * PHYSICS.TICK_RATE * stepWeight)

       -- Apply gravity influence
       nextPosition = nextPosition + Vector3.new(
           0,
           -0.5 * PHYSICS.GRAVITY * PHYSICS.TICK_RATE ^ 2,
           0
       )

       -- Handle jump prediction
       if state.isJumping then
           nextPosition = predictJumpArc()
       end

       -- Ground collision correction
       local groundY = checkGroundContact()
       if groundY then
           nextPosition = Vector3.new(
               nextPosition.X,
               groundY + TARGETING.VERTICAL_OFFSET,
               nextPosition.Z
           )
       end

       predictedPosition = nextPosition
   end

   return predictedPosition
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
    
    local gunDropPosition = state.gunDrop.Position
    local originalPosition = LocalPlayer.Character.HumanoidRootPart.Position
    state.originalPosition = originalPosition
    
    if isMurdererNear(gunDropPosition) then
        return
    end
    
    -- Move to gun drop position
    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(gunDropPosition)
    
    -- Wait for a short duration to ensure the gun is picked up
    wait(1)
    
    -- Return to original position
    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(originalPosition)
end

-- Connect Events
RunService.Heartbeat:Connect(function()
    if state.autoGetGunDropEnabled then
        collectGunDrop()
    end
end)

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

local function predictMurderV3(murderer)
   local character = murderer.Character
   if not character then return nil end

   local rootPart = character:FindFirstChild("HumanoidRootPart")
   local humanoid = character:FindFirstChild("Humanoid") 
   if not rootPart or not humanoid then return nil end

   local PHYSICS = {
       TICK_RATE = 1/144,
       GRAVITY = workspace.Gravity,
       JUMP_POWER = humanoid.JumpPower,
       WALK_SPEED = humanoid.WalkSpeed,
       MAX_STEPS = 24,
       VELOCITY_SAMPLES = 12
   }

   local TARGETING = {
       VELOCITY_WEIGHT = 0.92,
       DIRECTION_WEIGHT = 0.88,
       ACCELERATION_WEIGHT = 0.85,
       MOMENTUM_FACTOR = 0.82,
       GROUND_OFFSET = 4.2
   }

   local AXIS_DIVIDERS = {
       X = {
           VELOCITY = 1.15,
           ACCELERATION = 1.08,
           MOMENTUM = 1.12
       },
       Y = {
           VELOCITY = 1.25,
           ACCELERATION = 1.15,
           MOMENTUM = 1.18,
           GRAVITY = 1.05
       },
       Z = {
           VELOCITY = 1.15,
           ACCELERATION = 1.08, 
           MOMENTUM = 1.12
       }
   }

   local state = {
       position = rootPart.Position,
       velocity = rootPart.AssemblyLinearVelocity,
       velocityHistory = {},
       moveDirection = humanoid.MoveDirection,
       isJumping = humanoid.Jump,
       lastGroundTime = 0,
       accelerationVector = Vector3.new(),
       momentumVector = Vector3.new(),
       axisVelocities = {
           x = Vector3.new(),
           y = Vector3.new(),
           z = Vector3.new()
       }
   }

   for i = 1, PHYSICS.VELOCITY_SAMPLES do
       table.insert(state.velocityHistory, state.velocity)
   end

   local function computeAxisVelocity(axis, baseVel)
       local dividers = AXIS_DIVIDERS[axis]
       local axisVel = baseVel * (TARGETING.VELOCITY_WEIGHT / dividers.VELOCITY)
       
       local axisAccel = Vector3.new()
       for i = 2, #state.velocityHistory do
           local velDelta = (state.velocityHistory[i] - state.velocityHistory[i-1])
           axisAccel = axisAccel + (velDelta / dividers.ACCELERATION)
       end
       
       local axisMomentum = axisAccel * (TARGETING.MOMENTUM_FACTOR / dividers.MOMENTUM)
       
       return axisVel + axisMomentum
   end

   local function simulateTrajectory()
       local simState = {
           pos = state.position,
           vel = state.velocity,
           accel = state.accelerationVector
       }

       simState.vel = Vector3.new(
           computeAxisVelocity("X", simState.vel.X).X,
           computeAxisVelocity("Y", simState.vel.Y).Y,
           computeAxisVelocity("Z", simState.vel.Z).Z
       )

       local function updateGroundContact()
           local params = RaycastParams.new()
           params.FilterType = Enum.RaycastFilterType.Blacklist
           params.FilterDescendantsInstances = {character}

           local result = workspace:Raycast(
               simState.pos,
               Vector3.new(0, -TARGETING.GROUND_OFFSET * 2.5, 0),
               params
           )

           if result then
               state.lastGroundTime = tick()
               return {
                   point = result.Position,
                   normal = result.Normal,
                   material = result.Material
               }
           end
           return nil
       end

       local function calculateJumpArc()
           if not state.isJumping then return simState.pos end

           local airTime = tick() - state.lastGroundTime
           local jumpForce = PHYSICS.JUMP_POWER / AXIS_DIVIDERS.Y.GRAVITY
           
           local verticalVel = jumpForce * math.exp(-airTime * 1.12)
           local gravityEffect = 0.5 * PHYSICS.GRAVITY * (airTime ^ 2) / AXIS_DIVIDERS.Y.GRAVITY
           
           return simState.pos + Vector3.new(
               0,
               math.max((verticalVel * airTime - gravityEffect), 0),
               0
           )
       end

       for step = 1, PHYSICS.MAX_STEPS do
           local stepWeight = step / PHYSICS.MAX_STEPS
           local stepMultiplier = 1 - (stepWeight * 0.15)

           simState.pos = simState.pos + (simState.vel * PHYSICS.TICK_RATE * stepMultiplier)

           if state.isJumping then
               simState.pos = calculateJumpArc()
           else
               simState.pos = simState.pos + Vector3.new(
                   0,
                   -0.5 * (PHYSICS.GRAVITY / AXIS_DIVIDERS.Y.GRAVITY) * (PHYSICS.TICK_RATE ^ 2),
                   0
               )
           end

           local groundInfo = updateGroundContact()
           if groundInfo then
               simState.pos = Vector3.new(
                   simState.pos.X,
                   groundInfo.point.Y + TARGETING.GROUND_OFFSET,
                   simState.pos.Z
               )

               local friction = workspace:GetMaterialProperties(groundInfo.material).Friction
               simState.vel = simState.vel * (1 - friction * stepMultiplier)
           end

           table.remove(state.velocityHistory, 1)
           table.insert(state.velocityHistory, simState.vel)
       end

       return simState.pos
   end

   return simulateTrajectory()
end

local SilentAimV3Button = Instance.new("ImageButton")
local SilentAimGuiV3 = Instance.new("ScreenGui")

SilentAimGuiV3.Parent = game.CoreGui
SilentAimV3Button.Parent = SilentAimGuiV3
SilentAimV3Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SilentAimV3Button.BackgroundTransparency = 0.3
SilentAimV3Button.BorderColor3 = Color3.fromRGB(255, 100, 0)  
SilentAimV3Button.BorderSizePixel = 2
SilentAimV3Button.Position = UDim2.new(0.897, 0, 0.3)
SilentAimV3Button.Size = UDim2.new(0.1, 0, 0.2)
SilentAimV3Button.Image = "rbxassetid://11162755592"
SilentAimV3Button.Draggable = true
SilentAimV3Button.Visible = false

local UIStroke = Instance.new("UIStroke", SilentAimV3Button)
UIStroke.Color = Color3.fromRGB(255, 100, 0)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.5

local function getTargetPosition(character)
   if not character then return nil end
   
   local targetPart = character:FindFirstChild(_G.SelectedTargetPart)
   if not targetPart then return nil end
   
   return predictMurderV3(character)
end

-- Fluent UI Integration
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
   Title = "OmniHub Script By Azzakirms",
   SubTitle = "V1.1.0",
   TabWidth = 100,
   Size = UDim2.fromOffset(380, 260),
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

local SilentAimV3 = Tabs.Combat:AddToggle("SilentAimV3", {
   Title = "Silent Aim V3",
   Default = false,
   Callback = function(toggle)
       SilentAimV3Button.Visible = toggle
   end
})

local TargetPartDropdown = Tabs.Combat:AddDropdown("TargetPartSelection", {
   Title = "Target Part",
   Values = {
       "LowerTorso",
       "RightHand",
       "RightUpperArm",
       "LeftUpperLeg"
   },
   Default = "LowerTorso",  -- Changed default to match new list
   Multi = false,
   Callback = function(selectedPart)
       _G.SelectedTargetPart = selectedPart
   end
})

SilentAimV3Button.MouseButton1Click:Connect(function()
   local localPlayer = game.Players.LocalPlayer
   local gun = localPlayer.Character:FindFirstChild("Gun") or localPlayer.Backpack:FindFirstChild("Gun")
   
   if not gun then return end
   
   local murderer = GetMurderer()
   if not murderer then return end
   
   local targetPos = getTargetPosition(murderer.Character)
   if targetPos then
       gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, targetPos, "AH2")
   end
end)

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
    Title = "Auto Coin",
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


local AutoGetGunDropToggle = Tabs.Farming:AddToggle("AutoGetGunDropToggle", {
    Title = "Auto Get Gun Drop",
    Default = false,
    Callback = function(toggle)
        state.autoGetGunDropEnabled = toggle
    end
})


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

-- Initialize Premium Tab
createPremiumTab()
SaveManager:LoadAutoloadConfig()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GetPlayerData = game.ReplicatedStorage:FindFirstChild("GetPlayerData", true)
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer


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
   gunDrop = nil
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

local function getPredictedPosition(murderer)
   local character = murderer.Character
   if not character then return nil end
   
   local rootPart = character:FindFirstChild("HumanoidRootPart")
   local humanoid = character:FindFirstChild("Humanoid")
   
   if not rootPart or not humanoid then return nil end
   
   -- Use ping value from prediction state when enabled
   local PingMultiplier = predictionState.pingEnabled and (predictionState.pingValue / 1000) or 0.1
   
   local SimulatedPosition = rootPart.Position
   local SimulatedVelocity = rootPart.AssemblyLinearVelocity
   local MoveDirection = humanoid.MoveDirection
   
   local Interval = PingMultiplier  -- Dynamically adjust interval based on ping
   local Gravity = 196.2
   local FrictionDeceleration = 10
   
   SimulatedPosition = SimulatedPosition + Vector3.new(
       SimulatedVelocity.X * Interval + 0.5 * FrictionDeceleration * MoveDirection.X * Interval^2,
       SimulatedVelocity.Y * Interval - 0.5 * Gravity * Interval^2,
       SimulatedVelocity.Z * Interval + 0.5 * FrictionDeceleration * MoveDirection.Z * Interval^2
   )
   
   local Axes = {"X", "Z"}
   for _, Axis in ipairs(Axes) do
       local Goal = MoveDirection[Axis] * 16.2001
       local CurrentVelocity = SimulatedVelocity[Axis]
       
       if math.abs(CurrentVelocity) > math.abs(Goal) then
           SimulatedVelocity = SimulatedVelocity - Vector3.new(
               Axis == "X" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval) or 0,
               0,
               Axis == "Z" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval) or 0
           )
       elseif math.abs(CurrentVelocity) < math.abs(Goal) then
           SimulatedVelocity = SimulatedVelocity + Vector3.new(
               Axis == "X" and (FrictionDeceleration * math.sign(Goal) * Interval) or 0,
               0,
               Axis == "Z" and (FrictionDeceleration * math.sign(Goal) * Interval) or 0
           )
       end
   end
   
   SimulatedVelocity = SimulatedVelocity + Vector3.new(0, -Gravity * Interval, 0)
   
   local RaycastParams = RaycastParams.new()
   RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
   RaycastParams.FilterDescendantsInstances = {character}
   
   local FloorCheck = workspace:Raycast(
       SimulatedPosition, 
       Vector3.new(0, -3, 0), 
       RaycastParams
   )
   
   local CeilingCheck = workspace:Raycast(
       SimulatedPosition, 
       Vector3.new(0, 3, 0), 
       RaycastParams
   )
   
   if FloorCheck then
       SimulatedPosition = Vector3.new(
           SimulatedPosition.X, 
           FloorCheck.Position.Y + 3, 
           SimulatedPosition.Z
       )
   elseif CeilingCheck then
       SimulatedPosition = Vector3.new(
           SimulatedPosition.X, 
           CeilingCheck.Position.Y - 2, 
           SimulatedPosition.Z
       )
   end
   
   if humanoid.Jump then
       SimulatedPosition = SimulatedPosition + Vector3.new(0, 5, 0)
   end
   
   return SimulatedPosition
end

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



local AimGui = Instance.new("ScreenGui")
local AimButton = Instance.new("ImageButton")

AimGui.Parent = game.CoreGui
AimButton.Parent = AimGui
AimButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimButton.BackgroundTransparency = 0.3
AimButton.BorderColor3 = Color3.fromRGB(255, 100, 0)
AimButton.BorderSizePixel = 2
AimButton.Position = UDim2.new(0.897, 0, 0.3)
AimButton.Size = UDim2.new(0.1, 0, 0.2)
AimButton.Image = "rbxassetid://11162755592"
AimButton.Draggable = true
AimButton.Visible = false

local UIStroke = Instance.new("UIStroke", AimButton)
UIStroke.Color = Color3.fromRGB(255, 100, 0)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.5

AimButton.MouseButton1Click:Connect(function()
   local localPlayer = Players.LocalPlayer
   local gun = localPlayer.Character:FindFirstChild("Gun") or localPlayer.Backpack:FindFirstChild("Gun")
   
   if not gun then return end
   
   local murderer = GetMurderer()
   if not murderer then return end
   
   localPlayer.Character.Humanoid:EquipTool(gun)
   
   local predictedPos = getPredictedPosition(murderer)
   if predictedPos then
       gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, predictedPos, "AH2")
   end
end)

local function predictMurderV2(murderer)
    local character = murderer.Character
    if not character then return nil end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")

    if not rootPart or not humanoid then return nil end

    -- Constants for prediction
    local Interval = 0.1 -- Fixed interval for prediction
    local Gravity = 196.2
    local FrictionDeceleration = 10
    local ProbabilityFactor = 0.7 -- Probability of the murderer continuing in the same direction

    -- Simulate position and velocity
    local SimulatedPosition = rootPart.Position
    local SimulatedVelocity = rootPart.AssemblyLinearVelocity
    local MoveDirection = humanoid.MoveDirection

    -- Apply probability-based adjustments to movement direction
    if math.random() > ProbabilityFactor then
        -- Simulate a sudden change in direction
        MoveDirection = Vector3.new(
            MoveDirection.X * (math.random() > 0.5 and -1 or 1),
            MoveDirection.Y,
            MoveDirection.Z * (math.random() > 0.5 and -1 or 1)
        )
    end

    -- Predict movement
    SimulatedPosition = SimulatedPosition + Vector3.new(
        SimulatedVelocity.X * Interval + 0.5 * FrictionDeceleration * MoveDirection.X * Interval^2,
        SimulatedVelocity.Y * Interval - 0.5 * Gravity * Interval^2,
        SimulatedVelocity.Z * Interval + 0.5 * FrictionDeceleration * MoveDirection.Z * Interval^2
    )

    -- Adjust velocity based on movement direction
    local Axes = {"X", "Z"}
    for _, Axis in ipairs(Axes) do
        local Goal = MoveDirection[Axis] * 16.2001
        local CurrentVelocity = SimulatedVelocity[Axis]

        if math.abs(CurrentVelocity) > math.abs(Goal) then
            SimulatedVelocity = SimulatedVelocity - Vector3.new(
                Axis == "X" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval) or 0,
                0,
                Axis == "Z" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval) or 0
            )
        elseif math.abs(CurrentVelocity) < math.abs(Goal) then
            SimulatedVelocity = SimulatedVelocity + Vector3.new(
                Axis == "X" and (FrictionDeceleration * math.sign(Goal) * Interval) or 0,
                0,
                Axis == "Z" and (FrictionDeceleration * math.sign(Goal) * Interval) or 0
            )
        end
    end

    -- Apply gravity
    SimulatedVelocity = SimulatedVelocity + Vector3.new(0, -Gravity * Interval, 0)

    -- Raycast to check for floor or ceiling
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    RaycastParams.FilterDescendantsInstances = {character}

    local FloorCheck = workspace:Raycast(
        SimulatedPosition, 
        Vector3.new(0, -3, 0), 
        RaycastParams
    )

    local CeilingCheck = workspace:Raycast(
        SimulatedPosition, 
        Vector3.new(0, 3, 0), 
        RaycastParams
    )

    -- Adjust position based on raycast results
    if FloorCheck then
        SimulatedPosition = Vector3.new(
            SimulatedPosition.X, 
            FloorCheck.Position.Y + 3, 
            SimulatedPosition.Z
        )
    elseif CeilingCheck then
        SimulatedPosition = Vector3.new(
            SimulatedPosition.X, 
            CeilingCheck.Position.Y - 2, 
            SimulatedPosition.Z
        )
    end

    -- Predict jump with probability
    if humanoid.Jump and math.random() < 0.5 then -- 50% chance of jumping again
        SimulatedPosition = SimulatedPosition + Vector3.new(0, 5, 0)
    end

    return SimulatedPosition
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

local function predictMurderV3(murderer, algorithmType)
    local character = murderer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return nil end

    -- Constants for prediction
    local Interval = 0.1 -- Fixed interval for prediction
    local Gravity = 196.2 -- Standard Roblox gravity
    local FrictionDeceleration = 10 -- Deceleration due to friction
    local JumpPower = humanoid.JumpPower -- Jump power of the humanoid
    local MaxVerticalOffset = 5 -- Maximum vertical offset to avoid shooting into the ground
    local MaxPredictionTime = 0.5 -- Maximum time to predict future position
    local AirResistance = 0.1 -- Air resistance factor

    -- Simulate position and velocity
    local SimulatedPosition = rootPart.Position
    local SimulatedVelocity = rootPart.AssemblyLinearVelocity
    local MoveDirection = humanoid.MoveDirection

    -- Function to predict jump height
    local function predictJumpHeight(jumpPower, gravity, interval)
        local initialVelocity = jumpPower / 100
        local time = 0
        local peakHeight = 0
        while true do
            local height = initialVelocity * time - 0.5 * gravity * time^2
            if height <= 0 then break end
            peakHeight = height
            time = time + interval
        end
        return peakHeight
    end

    -- Predict jump if the humanoid is jumping
    if humanoid.Jump then
        local jumpHeight = predictJumpHeight(JumpPower, Gravity, Interval)
        SimulatedPosition = SimulatedPosition + Vector3.new(0, jumpHeight, 0)
        SimulatedVelocity = SimulatedVelocity + Vector3.new(0, JumpPower / 100, 0)
    end

    -- Apply air resistance
    SimulatedVelocity = SimulatedVelocity * (1 - AirResistance * Interval)

    -- Algorithm-specific adjustments
    if algorithmType == "Algorithm" then
        -- Apply probability-based adjustments to movement direction (deterministic approach)
        local DirectionFactor = 1
        if humanoid.Jump or SimulatedVelocity.Magnitude > 50 then
            DirectionFactor = -1 -- Reverse direction if jumping or moving fast
        end

        -- Predict movement with refined acceleration handling
        local totalPredictionTime = 0
        while totalPredictionTime < MaxPredictionTime do
            SimulatedPosition = SimulatedPosition + Vector3.new(
                SimulatedVelocity.X * Interval + 0.5 * FrictionDeceleration * MoveDirection.X * Interval^2 * DirectionFactor,
                SimulatedVelocity.Y * Interval - 0.5 * Gravity * Interval^2,
                SimulatedVelocity.Z * Interval + 0.5 * FrictionDeceleration * MoveDirection.Z * Interval^2 * DirectionFactor
            )

            -- Adjust velocity based on movement direction with better deceleration
            local Axes = {"X", "Z"}
            for _, Axis in ipairs(Axes) do
                local Goal = MoveDirection[Axis] * 16.2001
                local CurrentVelocity = SimulatedVelocity[Axis]
                if math.abs(CurrentVelocity) > math.abs(Goal) then
                    SimulatedVelocity = SimulatedVelocity - Vector3.new(
                        Axis == "X" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval * 0.8) or 0,
                        0,
                        Axis == "Z" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval * 0.8) or 0
                    )
                elseif math.abs(CurrentVelocity) < math.abs(Goal) then
                    SimulatedVelocity = SimulatedVelocity + Vector3.new(
                        Axis == "X" and (FrictionDeceleration * math.sign(Goal) * Interval * 0.8) or 0,
                        0,
                        Axis == "Z" and (FrictionDeceleration * math.sign(Goal) * Interval * 0.8) or 0
                    )
                end
            end

            -- Apply gravity with slight dampening for realism
            SimulatedVelocity = SimulatedVelocity + Vector3.new(0, -Gravity * Interval * 0.95, 0)

            -- Apply air resistance
            SimulatedVelocity = SimulatedVelocity * (1 - AirResistance * Interval)

            totalPredictionTime = totalPredictionTime + Interval
        end

    elseif algorithmType == "Jet" then
        -- Jet mode is an aggressive version of Algorithm with faster speeds and sharper changes
        local JetFactor = 2.5 -- Multiplier for jet-like movement
        local JetHeightFactor = humanoid.Jump and 8 or 0 -- Higher jump height for jet-like behavior

        -- Predict movement with enhanced speed and vertical adjustment
        local totalPredictionTime = 0
        while totalPredictionTime < MaxPredictionTime do
            SimulatedPosition = SimulatedPosition + Vector3.new(
                SimulatedVelocity.X * Interval * JetFactor + 0.5 * FrictionDeceleration * MoveDirection.X * Interval^2,
                JetHeightFactor + SimulatedVelocity.Y * Interval - 0.5 * Gravity * Interval^2,
                SimulatedVelocity.Z * Interval * JetFactor + 0.5 * FrictionDeceleration * MoveDirection.Z * Interval^2
            )

            -- Adjust velocity with higher friction for sharp stops/starts
            local Axes = {"X", "Z"}
            for _, Axis in ipairs(Axes) do
                local Goal = MoveDirection[Axis] * 25 -- Higher goal speed for jet mode
                local CurrentVelocity = SimulatedVelocity[Axis]
                if math.abs(CurrentVelocity) > math.abs(Goal) then
                    SimulatedVelocity = SimulatedVelocity - Vector3.new(
                        Axis == "X" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval * 1.2) or 0,
                        0,
                        Axis == "Z" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval * 1.2) or 0
                    )
                elseif math.abs(CurrentVelocity) < math.abs(Goal) then
                    SimulatedVelocity = SimulatedVelocity + Vector3.new(
                        Axis == "X" and (FrictionDeceleration * math.sign(Goal) * Interval * 1.2) or 0,
                        0,
                        Axis == "Z" and (FrictionDeceleration * math.sign(Goal) * Interval * 1.2) or 0
                    )
                end
            end

            -- Apply gravity with reduced dampening for faster falls
            SimulatedVelocity = SimulatedVelocity + Vector3.new(0, -Gravity * Interval * 0.85, 0)

            -- Apply air resistance
            SimulatedVelocity = SimulatedVelocity * (1 - AirResistance * Interval)

            totalPredictionTime = totalPredictionTime + Interval
        end
    end

    -- Raycast to check for floor or ceiling
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    RaycastParams.FilterDescendantsInstances = {character}

    local FloorCheck = workspace:Raycast(SimulatedPosition, Vector3.new(0, -MaxVerticalOffset, 0), RaycastParams)
    local CeilingCheck = workspace:Raycast(SimulatedPosition, Vector3.new(0, MaxVerticalOffset, 0), RaycastParams)

    -- Adjust position based on raycast results
    if FloorCheck then
        SimulatedPosition = Vector3.new(SimulatedPosition.X, FloorCheck.Position.Y + 3, SimulatedPosition.Z)
        SimulatedVelocity = Vector3.new(SimulatedVelocity.X, 0, SimulatedVelocity.Z) -- Reset vertical velocity on landing
    elseif CeilingCheck then
        SimulatedPosition = Vector3.new(SimulatedPosition.X, CeilingCheck.Position.Y - 2, SimulatedPosition.Z)
        SimulatedVelocity = Vector3.new(SimulatedVelocity.X, 0, SimulatedVelocity.Z) -- Reset vertical velocity on hitting ceiling
    end

    -- Clamp vertical position to avoid shooting into the ground
    if SimulatedPosition.Y < rootPart.Position.Y - MaxVerticalOffset then
        SimulatedPosition = Vector3.new(SimulatedPosition.X, rootPart.Position.Y - MaxVerticalOffset, SimulatedPosition.Z)
        SimulatedVelocity = Vector3.new(SimulatedVelocity.X, 0, SimulatedVelocity.Z) -- Reset vertical velocity on ground
    end

    return SimulatedPosition
end

-- Silent Aim V3 GUI Button
local SilentAimGuiV3 = Instance.new("ScreenGui")
local SilentAimButtonV3 = Instance.new("ImageButton")

SilentAimGuiV3.Name = "SilentAimGuiV3"
SilentAimGuiV3.Parent = game.CoreGui

SilentAimButtonV3.Name = "SilentAimButtonV3"
SilentAimButtonV3.Parent = SilentAimGuiV3
SilentAimButtonV3.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SilentAimButtonV3.BackgroundTransparency = 0.3
SilentAimButtonV3.BorderColor3 = Color3.fromRGB(255, 100, 0)
SilentAimButtonV3.BorderSizePixel = 2
SilentAimButtonV3.Position = UDim2.new(0.897, 0, 0.5, 0)
SilentAimButtonV3.Size = UDim2.new(0.1, 0, 0.2, 0)
SilentAimButtonV3.Image = "rbxassetid://11162755592"
SilentAimButtonV3.Draggable = true
SilentAimButtonV3.Visible = false

local UIStroke = Instance.new("UIStroke", SilentAimButtonV3)
UIStroke.Color = Color3.fromRGB(255, 100, 0)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.5

local CollectionState = {
   enabled = false,
   collecting = false
}


-- Safety check function
local function IsSafeToCollect(humanoidRootPart)
    local murderer = GetMurderer()
    if murderer and murderer:FindFirstChild("HumanoidRootPart") then
        local distance = (murderer.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
        return distance > 10 -- Fixed safe distance of 20 studs
    end
    return true
end

-- Enhanced Collection Function with Safety Checks
local function GunDropCollector()
    local player = Players.LocalPlayer
    local character = player.Character
    if not character or CollectionState.collecting then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    if not IsSafeToCollect(humanoidRootPart) then
        Fluent:Notify({
            Title = "Grab Gun",
            Content = "Murderer too close",
            Duration = 2
        })
        return
    end
    
    CollectionState.collecting = true
    local originalCFrame = humanoidRootPart.CFrame
    
    local GunDrop = workspace:FindFirstChild("GunDrop", true)
    if GunDrop then
        local grabCooldown = player:FindFirstChild("GrabCooldown")
        if grabCooldown then grabCooldown:Destroy() end
        
        humanoidRootPart.CFrame = GunDrop.CFrame * CFrame.new(0, 0.5, 0)
        task.wait()
        
        for i = 1, 3 do
            if not IsSafeToCollect(humanoidRootPart) then
                break
            end
            if not GunDrop:IsDescendantOf(workspace) then break end
            game:GetService("ReplicatedStorage").RemoteEvents.GrabEvent:FireServer()
            task.wait()
        end
        
        humanoidRootPart.CFrame = originalCFrame
    end
    
    CollectionState.collecting = false
end


-- Fluent UI Integration
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
   Title = "OmniHub Script By Azzakirms",
   SubTitle = "NiggaTron",
   TabWidth = 160,
   Size = UDim2.fromOffset(580, 460),
   Acrylic = true,
   Theme = "Dark",
   MinimizeKey = Enum.KeyCode.LeftControl
})

-- Add Discord Tab
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "eye" }),
    Discord = Window:AddTab({ Title = "Join Discord", Icon = "message-square" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Tabs.Main:AddParagraph({
    Title = "Development Notice",
    Content = "OmniHub is still in early development. You may experience bugs during usage. If you have suggestions for improving our MM2 script, please join our Discord server Thank you ."
})

-- ESP Toggle
local ESPToggle = Tabs.Main:AddToggle("ESPToggle", {
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

local SilentAimToggle = Tabs.Main:AddToggle("SilentAimToggle", {
   Title = "Silent Aim",
   Default = false,
   Callback = function(toggle)
       AimButton.Visible = toggle
   end
})

local SilentAimToggle = Tabs.Main:AddToggle("SilentAimToggle", {
    Title = "Silent Aim2",
    Default = false,
    Callback = function(toggle)
        SilentAimButtonV2.Visible = toggle
    end
})

local SilentAimToggleV3 = Tabs.Main:AddToggle("SilentAimToggleV3", {
    Title = "Silent Aim 3",
    Default = false,
    Callback = function(toggle)
        SilentAimButtonV3.Visible = toggle
    end
})

-- Algorithm Type Dropdown
local SelectedAlgorithm = "Algorithm" -- Default algorithm
local SilentAimChoice = Tabs.Main:AddDropdown("SilentAimChoice", {
    Title = "Algorithm Type",
    Values = {"Algorithm", "Jet", "Simplified"},
    Default = "Algorithm",
    Callback = function(choice)
        SelectedAlgorithm = choice
    end
})

-- Constants for Simplified Prediction
local ShootOffset = 10 -- Adjust as needed
local OffsetToPingMult = 1.5 -- Adjust as needed

-- Silent Aim V3 Button Click Event
SilentAimButtonV3.MouseButton1Click:Connect(function()
    local localPlayer = game.Players.LocalPlayer
    local gun = localPlayer.Character:FindFirstChild("Gun") or localPlayer.Backpack:FindFirstChild("Gun")
    if not gun then return end
    local murderer = GetMurderer() -- Assume this function exists and returns the murderer
    if not murderer then return end

    -- Equip the gun if not already equipped
    if not localPlayer.Character:FindFirstChild("Gun") then
        local hum = localPlayer.Character:FindFirstChild("Humanoid")
        if localPlayer.Backpack:FindFirstChild("Gun") then
            hum:EquipTool(localPlayer.Backpack:FindFirstChild("Gun"))
        else
            return
        end
    end

    local predictedPos
    if SelectedAlgorithm == "Simplified" then
        predictedPos = predictMurderV3_Simplified(murderer, ShootOffset, OffsetToPingMult)
    else
        predictedPos = predictMurderV3(murderer, SelectedAlgorithm or "Algorithm")
    end

    if not predictedPos then return end

    -- Check for obstructions
    local characterRootPart = localPlayer.Character.HumanoidRootPart
    local rayDirection = predictedPos - characterRootPart.Position

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {localPlayer.Character}

    local hit = workspace:Raycast(characterRootPart.Position, rayDirection, raycastParams)
    if not hit or hit.Instance.Parent == murderer.Character then -- Check if nothing collides or if it collides with the murderer
        -- Aim at the predicted position
        local mouse = game.Players.LocalPlayer:GetMouse()
        mouse.Hit.p = predictedPos
        gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, predictedPos, "AH2")
    end
end)

local AutoGunToggle = Tabs.Main:AddToggle("AutoGunDropCollector", {
    Title = "Auto Get Gun Drop",
    Default = false,
    Callback = function(Value)
        CollectionState.enabled = Value
        
        if Value then
            task.spawn(function()
                while CollectionState.enabled and task.wait(0.1) do
                    GunDropCollector()
                end
            end)
            
            Fluent:Notify({
                Title = "Grab Gun",
                Content = "Grab Gun enabled",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Grab Gun",
                Content = "Grab Gun disabled",
                Duration = 2
            })
        end
    end
})

-- Prediction Ping Toggle
local PredictionPingToggle = Tabs.Main:AddToggle("PredictionPingToggle", {
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

-- Ping Slider
local PingSlider = Tabs.Main:AddSlider("PingSlider", {
   Title = "Prediction Ping Value",
   Description = "Adjust ping for more accurate prediction",
   Default = 50,
   Min = 0,
   Max = 300,
   Rounding = 0,
   Callback = function(value)
       predictionState.pingValue = value
   end
})


local AutoCoinToggle = Tabs.Main:AddToggle("AutoCoinToggle", {
  Title = "Auto Coin",
  Default = false,
  Callback = function(toggle)
      AutoCoin = toggle
      if not toggle then
          -- Stop farming immediately
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
                  humanoid.PlatformStand = false -- Reset to standing when stopping
              end
          end
      end
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

SaveManager:LoadAutoloadConfig()

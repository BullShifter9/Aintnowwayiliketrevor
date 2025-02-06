local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GetPlayerData = game.ReplicatedStorage:FindFirstChild("GetPlayerData", true)
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local GameplayEvents = ReplicatedStorage.Remotes.Gameplay
local AutoNotifyEnabled = true


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
            Title = "🔪 Murderer Perk Detected",
            Content = string.format(
                "%s is using the %s Perk!", 
                murdererPlayer.Name, 
                detectedPerk
            ),
            Duration = 5
        })
    else
        Fluent:Notify({
            Title = "🕵️ Murderer Found",
            Content = murdererPlayer.Name .. " detected, but no perk information available.",
            Duration = 4
        })
    end
end

GameplayEvents.RoundStart.OnClientEvent:Connect(function()
    task.wait(1)
    NotifyMurdererPerk()
end)


local function predictMurderSharpShooter(murderer)
    local character = murderer.Character
    if not character then return nil end
    local primaryPart = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not primaryPart or not humanoid then return nil end

    -- Constants for prediction
    local Interval = 0.02 -- Extremely small interval for high precision
    local Gravity = 196.2
    local MaxAcceleration = 50 -- Maximum acceleration for adaptive tracking
    local JumpVelocity = 50 -- Initial upward velocity for jumps
    local AdaptiveFactor = 0.8 -- Factor for adaptive velocity adjustment

    -- Get current position and velocity
    local CurrentPosition = primaryPart.Position
    local CurrentVelocity = primaryPart.AssemblyLinearVelocity
    local MoveDirection = humanoid.MoveDirection

    -- Adaptive velocity adjustment
    local PredictedVelocity = CurrentVelocity * AdaptiveFactor + MoveDirection * (1 - AdaptiveFactor)
    local PredictedPosition = CurrentPosition + PredictedVelocity * Interval

    -- Account for gravity
    PredictedPosition = PredictedPosition + Vector3.new(0, -0.5 * Gravity * Interval^2, 0)

    -- Predict jump arc
    if humanoid.Jump then
        local TimeInAir = JumpVelocity / Gravity
        local HorizontalVelocity = PredictedVelocity * Vector3.new(1, 0, 1) -- Only horizontal components
        local PredictedJumpPosition = PredictedPosition + HorizontalVelocity * TimeInAir + Vector3.new(0, JumpVelocity * TimeInAir - 0.5 * Gravity * TimeInAir^2, 0)
        PredictedPosition = PredictedJumpPosition
    end

    -- Raycast to detect obstacles
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    RaycastParams.FilterDescendantsInstances = {character}

    -- Check for walls or floors
    local WallCheck = workspace:Raycast(
        CurrentPosition,
        PredictedPosition - CurrentPosition,
        RaycastParams
    )

    if WallCheck then
        PredictedPosition = WallCheck.Position + (PredictedPosition - WallCheck.Position).Unit * 2 -- Adjust position near wall
    end

    -- Final adjustment for sharpness
    PredictedPosition = PredictedPosition + PredictedVelocity * 0.1 -- Fine-tune position

    return PredictedPosition
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

local function collectCoins()
    if not state.coinAuraEnabled then return end
    
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local nearestCoin = nil
    
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "Coin_Server" or v.Name == "SnowToken" then
            if nearestCoin then
                if (root.Position - nearestCoin.Position).Magnitude > (root.Position - v.Position).Magnitude then
                    nearestCoin = v
                end
            else
                nearestCoin = v
            end
        end
    end
    
    if nearestCoin and (root.Position - nearestCoin.Position).Magnitude <= state.coinAuraRadius then
        -- Trigger the coin collection
        firetouch(LocalPlayer.Character.HumanoidRootPart, nearestCoin)
        wait(0.1) -- Small delay to ensure the coin is collected
    end
end

local state = {
   skeletonEnabled = false,
   roles = {},
   murder = nil,
   sheriff = nil, 
   hero = nil,
   espColors = {
       murderer = Color3.fromRGB(255, 0, 0),
       sheriff = Color3.fromRGB(0, 0, 255), 
       hero = Color3.fromRGB(255, 255, 0),
       innocent = Color3.fromRGB(0, 255, 0)
   }
}

-- Skeleton ESP System Configuration
local SkeletonESP = {
   active = {},
   connections = {},
   config = {
       mainLineThickness = 1.5,
       glowLineThickness = 2.5,
       mainTransparency = 0.2,
       glowTransparency = 0.6,
       updateInterval = 2,
       zIndex = {glow = 1, main = 2}
   }
}

-- R15 Bone Structure Definition
local SKELETON_BONES = {
   primary = {
       {from = "Head", to = "UpperTorso"},
       {from = "UpperTorso", to = "LowerTorso"},
       {from = "UpperTorso", to = "LeftUpperArm"},
       {from = "UpperTorso", to = "RightUpperArm"},
       {from = "LowerTorso", to = "LeftUpperLeg"},
       {from = "LowerTorso", to = "RightUpperLeg"}
   },
   secondary = {
       {from = "LeftUpperArm", to = "LeftLowerArm"},
       {from = "LeftLowerArm", to = "LeftHand"},
       {from = "RightUpperArm", to = "RightLowerArm"},
       {from = "RightLowerArm", to = "RightHand"},
       {from = "LeftUpperLeg", to = "LeftLowerLeg"},
       {from = "LeftLowerLeg", to = "LeftFoot"},
       {from = "RightUpperLeg", to = "RightLowerLeg"},
       {from = "RightLowerLeg", to = "RightFoot"}
   }
}

-- Drawing Object Factory
local function createNeonLine()
   local glow = Drawing.new("Line")
   glow.Thickness = SkeletonESP.config.glowLineThickness
   glow.Transparency = 1 - SkeletonESP.config.glowTransparency
   glow.ZIndex = SkeletonESP.config.zIndex.glow

   local main = Drawing.new("Line")
   main.Thickness = SkeletonESP.config.mainLineThickness
   main.Transparency = 1 - SkeletonESP.config.mainTransparency
   main.ZIndex = SkeletonESP.config.zIndex.main

   return {glow = glow, main = main}
end

-- WorldToScreen Conversion
local function worldToScreen(position)
   local screenPos, onScreen = Camera:WorldToScreenPoint(position)
   return Vector2.new(screenPos.X, screenPos.Y), onScreen and screenPos.Z > 0
end

-- Initialize Player Skeleton
function SkeletonESP.initializePlayer(player)
   if SkeletonESP.active[player] then return end
   
   local lines = {
       primary = {},
       secondary = {}
   }

   for _ in ipairs(SKELETON_BONES.primary) do
       table.insert(lines.primary, createNeonLine())
   end
   
   for _ in ipairs(SKELETON_BONES.secondary) do
       table.insert(lines.secondary, createNeonLine())
   end

   SkeletonESP.active[player] = lines

   local frameCount = 0
   SkeletonESP.connections[player] = RunService.RenderStepped:Connect(function()
       if not state.skeletonEnabled then return end
       
       frameCount += 1
       if frameCount >= SkeletonESP.config.updateInterval then
           frameCount = 0
           SkeletonESP.updatePlayer(player)
       end
   end)
end

-- Update Player Skeleton
function SkeletonESP.updatePlayer(player)
   local lines = SkeletonESP.active[player]
   if not lines then return end

   local character = player.Character
   if not character then return end

   -- Determine role and color
   local baseColor = state.espColors.innocent
   if player.Name == state.murder then
       baseColor = state.espColors.murderer
   elseif player.Name == state.sheriff then
       baseColor = state.espColors.sheriff
   elseif player.Name == state.hero then
       baseColor = state.espColors.hero
   end

   -- Calculate glow color
   local glowColor = Color3.new(
       math.min(1, baseColor.R * 1.4),
       math.min(1, baseColor.G * 1.4),
       math.min(1, baseColor.B * 1.4)
   )

   -- Update bones
   local function updateBoneSet(boneSet, lineSet)
       for i, bone in ipairs(SKELETON_BONES[boneSet]) do
           local lineGroup = lineSet[i]
           local fromPart = character:FindFirstChild(bone.from)
           local toPart = character:FindFirstChild(bone.to)

           if fromPart and toPart then
               local from, fromVisible = worldToScreen(fromPart.Position)
               local to, toVisible = worldToScreen(toPart.Position)

               local visible = fromVisible and toVisible
               lineGroup.glow.Visible = visible
               lineGroup.main.Visible = visible

               if visible then
                   lineGroup.glow.From = from
                   lineGroup.glow.To = to
                   lineGroup.glow.Color = glowColor

                   lineGroup.main.From = from
                   lineGroup.main.To = to
                   lineGroup.main.Color = baseColor
               end
           else
               lineGroup.glow.Visible = false
               lineGroup.main.Visible = false
           end
       end
   end

   updateBoneSet("primary", lines.primary)
   updateBoneSet("secondary", lines.secondary)
end

-- Remove Player Cleanup
function SkeletonESP.removePlayer(player)
   if SkeletonESP.connections[player] then
       SkeletonESP.connections[player]:Disconnect()
       SkeletonESP.connections[player] = nil
   end

   if SkeletonESP.active[player] then
       for _, lineSet in pairs(SkeletonESP.active[player]) do
           for _, lineGroup in ipairs(lineSet) do
               lineGroup.glow:Remove()
               lineGroup.main:Remove()
           end
       end
       SkeletonESP.active[player] = nil
   end
end

-- Role Detection
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
end)

-- Player Lifecycle Management
Players.PlayerAdded:Connect(function(player)
   if player ~= LocalPlayer and state.skeletonEnabled then
       SkeletonESP.initializePlayer(player)
   end
end)

Players.PlayerRemoving:Connect(function(player)
   SkeletonESP.removePlayer(player)
end)


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
    Misc = Window:AddTab({ Title = "Misc", Icon = "tool" }),
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

local SkeletonESPToggle = Tabs.Main:AddToggle("SkeletonESPToggle", {
   Title = "Skeleton ESP",
   Default = false,
   Callback = function(toggle)
       state.skeletonEnabled = toggle
       
       if toggle then
           for _, player in ipairs(Players:GetPlayers()) do
               if player ~= LocalPlayer then
                   SkeletonESP.initializePlayer(player)
               end
           end
       else
           for player in pairs(SkeletonESP.active) do
               SkeletonESP.removePlayer(player)
           end
       end
   end
})

-- Cleanup
game:BindToClose(function()
   for player in pairs(SkeletonESP.active) do
       SkeletonESP.removePlayer(player)
   end
end)

local SilentAimToggle = Tabs.Main:AddToggle("SilentAimToggle", {
    Title = "Silent Aim",
    Default = false,
    Callback = function(toggle)
        SilentAimButtonV2.Visible = toggle
    end
})

local SharpShooterToggle = Tabs.Main:AddToggle("SharpShooterToggle", {
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

local AutoGetGunDropToggle = Tabs.Main:AddToggle("AutoGetGunDropToggle", {
    Title = "Auto Get Gun Drop",
    Default = false,
    Callback = function(toggle)
        state.autoGetGunDropEnabled = toggle
    end
})

local CoinAuraToggle = Tabs.Main:AddToggle("CoinAuraToggle", {
    Title = "Coin Aura",
    Default = false,
    Callback = function(toggle)
        state.coinAuraEnabled = toggle
    end
})

local AutoNotifyToggle = Tabs.Main:AddToggle("AutoNotifyToggle", {
    Title = "Auto Notify Murderers Perk",
    Default = true,
})

AutoNotifyToggle:OnChanged(function(state)
    AutoNotifyEnabled = state
    Fluent:Notify({
        Title = "Auto Notify",
        Content = state and " ENABLED." or " DISABLED.",
        Duration = 3
    })
end)

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
   Description = "Adjust ping",
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

local systemStates = {
    noClipConnection = nil,
    antiAFKConnection = nil,
    origNamecall = nil
}

-- X-Ray System Implementation
local XRayToggle = Tabs.Misc:AddToggle("XRayToggle", {
    Title = "X-Ray",
    Default = false,
    Callback = function(toggle)
        -- Implement X-Ray using LocalTransparencyModifier for better performance
        local transparencyValue = toggle and (XRayTransparency.Value / 100) or 0
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) then
                part.LocalTransparencyModifier = transparencyValue
            end
        end
    end
})

local XRayTransparency = Tabs.Misc:AddSlider("XRayTransparency", {
    Title = "X-Ray Transparency",
    Description = "Adjust X-Ray transparency level",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        if XRayToggle.Value then
            local transparencyValue = value / 100
            for _, part in ipairs(workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) then
                    part.LocalTransparencyModifier = transparencyValue
                end
            end
        end
    end
})

-- NoClip System Implementation using RunService.Stepped
local NoClipToggle = Tabs.Misc:AddToggle("NoClipToggle", {
    Title = "NoClip",
    Default = false,
    Callback = function(toggle)
        if toggle then
            systemStates.noClipConnection = RunService.Stepped:Connect(function()
                local character = LocalPlayer.Character
                if character then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if systemStates.noClipConnection then
                systemStates.noClipConnection:Disconnect()
                systemStates.noClipConnection = nil
                
                -- Restore collision states
                local character = LocalPlayer.Character
                if character then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end
    end
})

-- Anti-AFK System using VirtualUser service
local AntiAFKToggle = Tabs.Misc:AddToggle("AntiAFKToggle", {
    Title = "Anti-AFK",
    Default = false,
    Callback = function(toggle)
        if toggle then
            systemStates.antiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)  -- Using task.wait for better performance
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        else
            if systemStates.antiAFKConnection then
                systemStates.antiAFKConnection:Disconnect()
                systemStates.antiAFKConnection = nil
            end
        end
    end
})

-- Anti-Kick System using metatable hook
local AntiKickToggle = Tabs.Misc:AddToggle("AntiKickToggle", {
    Title = "Anti-Kick",
    Default = false,
    Callback = function(toggle)
        if toggle and not systemStates.origNamecall then
            systemStates.origNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "Kick" or method == "kick" then
                    return nil
                end
                return systemStates.origNamecall(self, ...)
            end)
        elseif not toggle and systemStates.origNamecall then
            hookmetamethod(game, "__namecall", systemStates.origNamecall)
            systemStates.origNamecall = nil
        end
    end
})

-- Character Movement Modifications
local WalkSpeedSlider = Tabs.Misc:AddSlider("WalkSpeedSlider", {
    Title = "Walk Speed",
    Description = "Adjust walking speed",
    Default = 16,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end
})

local JumpPowerSlider = Tabs.Misc:AddSlider("JumpPowerSlider", {
    Title = "Jump Power",
    Description = "Adjust jump power",
    Default = 50,
    Min = 50,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = value
        end
    end
})

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait()  -- Wait for Humanoid to initialize
    local humanoid = character:WaitForChild("Humanoid")
    if humanoid then
        -- Restore movement modifications
        humanoid.WalkSpeed = WalkSpeedSlider.Value
        humanoid.JumpPower = JumpPowerSlider.Value
    end
end)

-- Cleanup handler for proper system shutdown
game:BindToClose(function()
    for _, connection in pairs(systemStates) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    if systemStates.origNamecall then
        hookmetamethod(game, "__namecall", systemStates.origNamecall)
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

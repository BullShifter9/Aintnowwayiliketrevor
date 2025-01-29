local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
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

local flingPlayer = {
    enabled = false,
    originalPosition = nil,
    isDragging = false,
    dragStart = nil,
    startPos = nil
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

local function GetPlayer(name)
    name = name:lower()
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Name:lower():sub(1, #name) == name then
            return player
        end
    end
    return nil
end

-- Fling Execution Function
local function ExecuteFling(target)
    local player = game.Players.LocalPlayer
    local character = player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart then return end
    
    flingPlayer.originalPosition = humanoidRootPart.CFrame
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.P = math.huge
    
    local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
    bodyAngularVelocity.AngularVelocity = Vector3.new(math.huge, math.huge, math.huge)
    bodyAngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyAngularVelocity.P = math.huge
    
    bodyVelocity.Parent = humanoidRootPart
    bodyAngularVelocity.Parent = humanoidRootPart
    
    local targetChar = target.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    
    if targetRoot then
        humanoidRootPart.CFrame = targetRoot.CFrame
    end
    
    task.delay(1, function()
        bodyVelocity:Destroy()
        bodyAngularVelocity:Destroy()
        
        if flingPlayer.originalPosition then
            humanoidRootPart.CFrame = flingPlayer.originalPosition
            flingPlayer.originalPosition = nil
        end
    end)
end

-- Draggable GUI Implementation
local function MakeDraggable(gui)
    local UserInputService = game:GetService("UserInputService")
    local dragInput
    local dragStart
    local startPos
    
    local function UpdateDrag(input)
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    gui.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not flingPlayer.isDragging then
            flingPlayer.isDragging = true
            dragStart = input.Position
            startPos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    flingPlayer.isDragging = false
                end
            end)
        end
    end)
    
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if flingPlayer.isDragging and (input == dragInput) then
            UpdateDrag(input)
        end
    end)
end

-- Fling GUI Creation
local function CreateFlingGui()
    local FlingGui = Instance.new("ScreenGui")
    local MainFrame = Instance.new("Frame")
    local Title = Instance.new("TextLabel")
    local TargetBox = Instance.new("TextBox")
    local FlingButton = Instance.new("TextButton")

    FlingGui.Name = "FlingGui"
    FlingGui.Parent = game.CoreGui
    FlingGui.ResetOnSpawn = false

    MainFrame.Name = "MainFrame"
    MainFrame.Parent = FlingGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
    MainFrame.Size = UDim2.new(0, 250, 0, 150)

    -- Apply draggable functionality
    MakeDraggable(MainFrame)

    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 0, 0, 10)
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "DESTROY THEM"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 20

    TargetBox.Name = "TargetBox"
    TargetBox.Parent = MainFrame
    TargetBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    TargetBox.BorderSizePixel = 0
    TargetBox.Position = UDim2.new(0.1, 0, 0.4, 0)
    TargetBox.Size = UDim2.new(0.8, 0, 0, 30)
    TargetBox.Font = Enum.Font.Gotham
    TargetBox.PlaceholderText = "Enter target name..."
    TargetBox.Text = ""
    TargetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TargetBox.TextSize = 14

    FlingButton.Name = "FlingButton"
    FlingButton.Parent = MainFrame
    FlingButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    FlingButton.BorderSizePixel = 0
    FlingButton.Position = UDim2.new(0.2, 0, 0.7, 0)
    FlingButton.Size = UDim2.new(0.6, 0, 0, 30)
    FlingButton.Font = Enum.Font.GothamBold
    FlingButton.Text = "FLING"
    FlingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    FlingButton.TextSize = 16

    FlingButton.MouseButton1Click:Connect(function()
        local targetName = TargetBox.Text
        local target = GetPlayer(targetName)
        
        if target then
            ExecuteFling(target)
        else
            Fluent:Notify({
                Title = "Fling Error",
                Content = "Player not found!",
                Duration = 2
            })
        end
    end)

    return FlingGui
end

-- GUI Toggle Management
local flingGui = nil

local function ToggleFlingGui(visible)
    if visible then
        if not flingGui then
            flingGui = CreateFlingGui()
        end
        flingGui.Enabled = true
    else
        if flingGui then
            flingGui.Enabled = false
        end
    end
end

-- Fluent UI Integration
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
   Title = "Another Random Script😍",
   SubTitle = "NiggaTron",
   TabWidth = 160,
   Size = UDim2.fromOffset(580, 460),
   Acrylic = true,
   Theme = "Dark",
   MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
   Main = Window:AddTab({ Title = "Main", Icon = "eye" }),
   Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

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

local FlingToggle = Tabs.Main:AddToggle("FlingToggle", {
    Title = "Fling GUI",
    Default = false,
    Callback = function(Value)
        ToggleFlingGui(Value)
    end
})

local SilentAimToggle = Tabs.Main:AddToggle("SilentAimToggle", {
   Title = "Silent Aim",
   Default = false,
   Callback = function(toggle)
       AimButton.Visible = toggle
   end
})

local SilentAimToggle = Tabs.Main:AddToggle("SilentAimToggle", {
    Title = "Silent Aim",
    Default = false,
    Callback = function(toggle)
        SilentAimButtonV2.Visible = toggle
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



-- Save and Interface Management
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("MurderMysteryHack")
SaveManager:SetFolder("MurderMysteryHack")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
   Title = "Murder Mystery By Azzakirms",
   Content = "ESP Initialized!",
   Duration = 5
})

SaveManager:LoadAutoloadConfig()

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

local KnifeAuraSettings = {
    radius = 4.5,
    checkRate = 0.1,
    enabled = false
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
local target = nil
local AutoCoin = false
local AutoCoinOperator = false
local CoinFound = false
local TweenSpeed = 0.08

local part = Instance.new("Part")
local position = Vector3.new(0,10000,0)
part.Name = "AutoCoinPart"
part.Color = Color3.new(0,0,0)
part.Material = Enum.Material.Plastic
part.Transparency = 1
part.Position = position
part.Size = Vector3.new(1,0.5,1)
part.CastShadow = true
part.Anchored = true
part.CanCollide = false
part.Parent = workspace

game:GetService('RunService').Heartbeat:Connect(function()
   if AutoCoin == true and AutoCoinOperator == false then
       AutoCoinOperator = true
       local player = game.Players.LocalPlayer
       workspace:FindFirstChild("AutoCoinPart").CFrame = player.Character.HumanoidRootPart.CFrame
       
       for i,v in pairs(workspace:GetDescendants()) do
           if v.Name == "Coin_Server" or v.Name == "SnowToken" then
               if CurrentTarget then
                   if (player.Character.HumanoidRootPart.Position - CurrentTarget.Position).Magnitude > (player.Character.HumanoidRootPart.Position - v.Position).Magnitude then
                       CurrentTarget = v
                   end
               else
                   CurrentTarget = v
               end
           end
       end
       
       if CurrentTarget then
           local coin = CurrentTarget
           local character = player.Character
           local gyroCFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(90), 0, math.rad(90))

           for _, part in pairs(character:GetChildren()) do
               if part:IsA("BasePart") and (part.Name == "Head" or string.match(part.Name, "Torso")) then
                   local bodyGyro = Instance.new("BodyGyro")
                   bodyGyro.Name = "Auto Farm Gyro"
                   bodyGyro.P = 90000
                   bodyGyro.MaxTorque = Vector3.new(9000000000, 9000000000, 9000000000)
                   bodyGyro.CFrame = gyroCFrame
                   bodyGyro.Parent = part

                   local bodyVelocity = Instance.new("BodyVelocity")
                   bodyVelocity.Name = "Auto Farm Velocity"
                   bodyVelocity.Velocity = (coin.CFrame.Position - character.HumanoidRootPart.Position).Unit * 50
                   bodyVelocity.MaxForce = Vector3.new(9000000000, 9000000000, 9000000000)
                   bodyVelocity.Parent = part
               end
           end

           character.Humanoid.PlatformStand = true
           
           CoinFound = true
           if math.floor((character.HumanoidRootPart.Position - CurrentTarget.Position).magnitude) >= 80 then
               TweenSpeed = 4
           else
               TweenSpeed = math.floor((character.HumanoidRootPart.Position - CurrentTarget.Position).magnitude) / 23
           end
           
           local tweenService = game:GetService("TweenService")
           local tweenInfo = TweenInfo.new(TweenSpeed, Enum.EasingStyle.Linear)
           local tween = tweenService:Create(workspace:FindFirstChild("AutoCoinPart"), tweenInfo, {CFrame = CurrentTarget.CFrame})
           tween:Play()
           wait(TweenSpeed)
           
           if CurrentTarget then
               CurrentTarget.Parent = nil
           end
           
           TweenSpeed = 0.08
           target = nil
           CurrentTarget = nil
           CoinFound = false
           AutoCoinOperator = false
       end
   end
   
   if AutoCoin == true and CoinFound == true then
       game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace").AutoCoinPart.CFrame
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

local SilentAimV2Gui = Instance.new("ScreenGui")
local AimV2Button = Instance.new("ImageButton")

SilentAimV2Gui.Parent = game.CoreGui
AimV2Button.Parent = SilentAimV2Gui
AimV2Button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)  -- Different color to distinguish from V1
AimV2Button.BackgroundTransparency = 0.3
AimV2Button.BorderColor3 = Color3.fromRGB(100, 100, 255)  -- Blue border for V2
AimV2Button.BorderSizePixel = 2
AimV2Button.Position = UDim2.new(0.897, 0, 0.5)  -- Positioned below V1 button
AimV2Button.Size = UDim2.new(0.1, 0, 0.2)
AimV2Button.Image = "rbxassetid://11162755592"
AimV2Button.Draggable = true
AimV2Button.Visible = false

-- Add visual enhancement for V2 button
local UIStrokeV2 = Instance.new("UIStroke", AimV2Button)
UIStrokeV2.Color = Color3.fromRGB(100, 100, 255)
UIStrokeV2.Thickness = 2
UIStrokeV2.Transparency = 0.5

-- Prediction algorithm implementation
local function getSilentAimV2Position(target)
    local character = target.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return nil end

    -- Position history tracking
    if not target.RecentPositions then
        target.RecentPositions = {}
    end
    
    table.insert(target.RecentPositions, {
        position = rootPart.Position,
        timestamp = tick(),
        velocity = rootPart.AssemblyLinearVelocity
    })
    
    if #target.RecentPositions > 10 then
        table.remove(target.RecentPositions, 1)
    end

    -- Trajectory metrics calculation
    local function calculateTrajectoryMetrics()
        if #target.RecentPositions < 2 then return nil end
        
        local currentData = target.RecentPositions[#target.RecentPositions]
        local previousData = target.RecentPositions[#target.RecentPositions - 1]
        
        local timeDelta = currentData.timestamp - previousData.timestamp
        local acceleration = (currentData.velocity - previousData.velocity) / timeDelta
        
        return {
            acceleration = acceleration,
            timeDelta = timeDelta,
            averageSpeed = (currentData.velocity + previousData.velocity) / 2
        }
    end

    -- Prediction settings
    local PREDICTION_SETTINGS = {
        BASE_WINDOW = 0.15,
        MAX_SPEED = 16.2001,
        JUMP_POWER = 50,
        GRAVITY = 196.2,
        AIR_RESISTANCE = 0.85,
        TURN_RATE = 0.8
    }

    local metrics = calculateTrajectoryMetrics()
    local currentPosition = rootPart.Position
    local currentVelocity = rootPart.AssemblyLinearVelocity
    local moveDirection = humanoid.MoveDirection

    -- Trajectory prediction
    local function predictTrajectory()
        local predictedPosition = currentPosition
        local predictedVelocity = currentVelocity
        
        if metrics then
            predictedVelocity = predictedVelocity + metrics.acceleration * PREDICTION_SETTINGS.BASE_WINDOW
        end

        local movementComplexity = math.clamp(
            (currentVelocity.Magnitude / PREDICTION_SETTINGS.MAX_SPEED) + 
            (humanoid.Jump and 0.3 or 0) +
            (moveDirection.Magnitude * 0.2),
            0.5, 2
        )
        
        local adaptiveWindow = PREDICTION_SETTINGS.BASE_WINDOW * movementComplexity
        predictedPosition = predictedPosition + (predictedVelocity * adaptiveWindow)
        predictedVelocity = predictedVelocity * PREDICTION_SETTINGS.AIR_RESISTANCE

        local directionInfluence = moveDirection * (PREDICTION_SETTINGS.MAX_SPEED * adaptiveWindow)
        local turnFactor = Vector3.new(
            math.sign(directionInfluence.X) * math.min(math.abs(directionInfluence.X), PREDICTION_SETTINGS.TURN_RATE),
            0,
            math.sign(directionInfluence.Z) * math.min(math.abs(directionInfluence.Z), PREDICTION_SETTINGS.TURN_RATE)
        )
        
        predictedPosition = predictedPosition + turnFactor
        return predictedPosition, predictedVelocity
    end

    -- Jump trajectory prediction
    local function predictJumpTrajectory(basePosition, baseVelocity)
        if not humanoid.Jump and baseVelocity.Y <= 0 then
            return basePosition + Vector3.new(
                0,
                -PREDICTION_SETTINGS.GRAVITY * PREDICTION_SETTINGS.BASE_WINDOW^2 * 0.5,
                0
            )
        end

        local jumpPrediction = basePosition
        local jumpVelocity = math.max(baseVelocity.Y, 0)
        local jumpTime = PREDICTION_SETTINGS.BASE_WINDOW
        
        jumpPrediction = jumpPrediction + Vector3.new(
            0,
            jumpVelocity * jumpTime - 0.5 * PREDICTION_SETTINGS.GRAVITY * jumpTime^2,
            0
        )

        return jumpPrediction
    end

    -- Final position calculation
    local basePosition, predictedVelocity = predictTrajectory()
    local finalPosition = predictJumpTrajectory(basePosition, predictedVelocity)

    -- Collision detection
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {character}

    local groundRay = workspace:Raycast(
        finalPosition,
        Vector3.new(0, -5, 0),
        rayParams
    )

    if groundRay then
        finalPosition = Vector3.new(
            finalPosition.X,
            groundRay.Position.Y + 3,
            finalPosition.Z
        )
    end

    -- Historical accuracy adjustment
    if #target.RecentPositions >= 3 then
        local historicalOffset = target.RecentPositions[#target.RecentPositions].position -
                               target.RecentPositions[#target.RecentPositions - 2].position
        finalPosition = finalPosition + (historicalOffset * 0.15)
    end

    return finalPosition
end

-- Button click handler
AimV2Button.MouseButton1Click:Connect(function()
    local localPlayer = Players.LocalPlayer
    local gun = localPlayer.Character:FindFirstChild("Gun") or localPlayer.Backpack:FindFirstChild("Gun")
    
    if not gun then return end
    
    local murderer = GetMurderer()
    if not murderer then return end
    
    localPlayer.Character.Humanoid:EquipTool(gun)
    
    local predictedPos = getSilentAimV2Position(murderer)
    if predictedPos then
        gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, predictedPos, "AH2")
    end
end)

local function createKnifeAura()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    
    local function isValidTarget(player)
        return player ~= LocalPlayer 
            and player.Character 
            and player.Character:FindFirstChild("HumanoidRootPart")
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0
    end
    
    local function updateKnifeAura()
        if not KnifeAuraSettings.enabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local knife = character:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
        if not knife then return end
        
        if knife.Parent == LocalPlayer.Backpack then
            character.Humanoid:EquipTool(knife)
        end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if isValidTarget(player) then
                local targetRoot = player.Character.HumanoidRootPart
                local distance = (targetRoot.Position - rootPart.Position).Magnitude
                
                if distance <= KnifeAuraSettings.radius then
                    local knifeRemote = knife:FindFirstChild("KnifeServer", true) or 
                                      knife:FindFirstChild("KnifeRemote", true)
                    
                    if knifeRemote then
                        knifeRemote:FireServer(player.Character)
                    end
                end
            end
        end
    end
    
    local connection
    local function startAura()
        if connection then connection:Disconnect() end
        connection = RunService.Heartbeat:Connect(function()
            task.wait(KnifeAuraSettings.checkRate)
            updateKnifeAura()
        end)
    end
    
    local function stopAura()
        if connection then
            connection:Disconnect()
            connection = nil
        end
    end
    
    local function toggleKnifeAura(enabled)
        KnifeAuraSettings.enabled = enabled
        if enabled then
            startAura()
        else
            stopAura()
        end
    end
    
    LocalPlayer.CharacterRemoving:Connect(stopAura)
    
    return toggleKnifeAura
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

local SilentAimToggle = Tabs.Main:AddToggle("SilentAimToggle", {
   Title = "Silent Aim",
   Default = false,
   Callback = function(toggle)
       AimButton.Visible = toggle
   end
})

local SilentAimV2Toggle = Tabs.Main:AddToggle("SilentAimV2Toggle", {
    Title = "Silent Aim V2",
    Default = false,
    Callback = function(toggle)
        AimV2Button.Visible = toggle
    end
})

local KnifeAuraToggle = Tabs.Main:AddToggle("KnifeAuraToggle", {
    Title = "Knife Aura",
    Default = false,
    Callback = createKnifeAura()
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

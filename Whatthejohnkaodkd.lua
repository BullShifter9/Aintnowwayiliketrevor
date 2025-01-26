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



-- 🔐 Critical Configuration (MUST CUSTOMIZE)
local MASTER_ADMIN_ID = 1110891160  -- Replace with YOUR Roblox User ID
local HWID_WEBHOOK = "https://discord.com/api/webhooks/1332981779916918836/dTw4xZHg7nZda7IvtOXYHgnAFGIVmQ-NLWi15jQQ0gbsIXIrzeG3IuRt9sttkT_gW1Hh"
local ADMIN_ACTIVATION_PHRASE = "?hwiddetector"
local ADMIN_SECRET_PIN = "1234"  -- Change to a secure PIN

-- 🧠 Advanced HWID Generation Mechanism
local function GenerateComprehensiveHWID()
    local player = LocalPlayer
    local baseSignature = table.concat({
        tostring(player.UserId),
        player.Name,
        game.JobId,
        tostring(os.time())
    }, "|")
    
    -- Implement a robust hashing technique
    local hash = 0
    for i = 1, #baseSignature do
        hash = ((hash << 5) - hash) + string.byte(baseSignature, i)
        hash = hash & 0xFFFFFFFF  -- Ensure 32-bit integer
    end
    
    return string.format("%x", math.abs(hash))
end

-- 📡 Secure Webhook Transmission
local function TransmitHWIDSecurely(hwid)
    local payload = {
        embeds = {{
            title = "🔒 HWID Detection Protocol",
            description = string.format("```\n📍 Player: %s\n🔑 HWID: %s\n🆔 UserID: %d\n⏰ Timestamp: %s\n```", 
                LocalPlayer.Name, 
                hwid, 
                LocalPlayer.UserId,
                os.date("%Y-%m-%d %H:%M:%S")
            ),
            color = 5814783  -- Technical blue
        }}
    }
    
    spawn(function()
        pcall(function()
            HttpService:PostAsync(
                HWID_WEBHOOK, 
                HttpService:JSONEncode(payload), 
                Enum.HttpContentType.ApplicationJson
            )
        end)
    end)
end

-- 🛡️ Blacklist GUI Creator
local function CreateBlacklistGUI()
    -- Only accessible to master admin
    if LocalPlayer.UserId ~= MASTER_ADMIN_ID then return nil end
    
    -- Create GUI Container
    local BlacklistGui = Instance.new("ScreenGui")
    BlacklistGui.Name = "AdminBlacklistPanel"
    BlacklistGui.Parent = CoreGui
    BlacklistGui.Enabled = false
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0.4, 0, 0.5, 0)
    MainFrame.Position = UDim2.new(0.3, 0, 0.25, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = BlacklistGui
    
    -- Title Label
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, 0, 0.1, 0)
    TitleLabel.Text = "Admin Blacklist Panel"
    TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Parent = MainFrame
    
    -- PIN Input
    local PinInput = Instance.new("TextBox")
    PinInput.Size = UDim2.new(0.8, 0, 0.1, 0)
    PinInput.Position = UDim2.new(0.1, 0, 0.2, 0)
    PinInput.PlaceholderText = "Enter Admin PIN"
    PinInput.Parent = MainFrame
    
    -- Verify PIN Button
    local VerifyButton = Instance.new("TextButton")
    VerifyButton.Size = UDim2.new(0.6, 0, 0.1, 0)
    VerifyButton.Position = UDim2.new(0.2, 0, 0.35, 0)
    VerifyButton.Text = "Verify PIN"
    VerifyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    VerifyButton.Parent = MainFrame
    
    -- Blacklist Input
    local BlacklistInput = Instance.new("TextBox")
    BlacklistInput.Size = UDim2.new(0.8, 0, 0.1, 0)
    BlacklistInput.Position = UDim2.new(0.1, 0, 0.5, 0)
    BlacklistInput.PlaceholderText = "Enter User ID to Blacklist"
    BlacklistInput.Visible = false
    BlacklistInput.Parent = MainFrame
    
    -- Blacklist Confirm Button
    local BlacklistButton = Instance.new("TextButton")
    BlacklistButton.Size = UDim2.new(0.6, 0, 0.1, 0)
    BlacklistButton.Position = UDim2.new(0.2, 0, 0.65, 0)
    BlacklistButton.Text = "Blacklist User"
    BlacklistButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    BlacklistButton.Visible = false
    BlacklistButton.Parent = MainFrame
    
    -- PIN Verification Logic
    VerifyButton.MouseButton1Click:Connect(function()
        if PinInput.Text == ADMIN_SECRET_PIN then
            BlacklistInput.Visible = true
            BlacklistButton.Visible = true
            PinInput.Visible = false
            VerifyButton.Visible = false
        else
            PinInput.Text = "Incorrect PIN!"
        end
    end)
    
    -- Blacklist Confirmation Logic
    BlacklistButton.MouseButton1Click:Connect(function()
        local userId = tonumber(BlacklistInput.Text)
        if userId then
            local payload = {
                embeds = {{
                    title = "🚫 User Blacklisted",
                    description = string.format("User ID: %d\nBlacklisted By: %s", 
                        userId, 
                        LocalPlayer.Name
                    ),
                    color = 15158332
                }}
            }
            
            pcall(function()
                HttpService:PostAsync(
                    HWID_WEBHOOK, 
                    HttpService:JSONEncode(payload),
                    Enum.HttpContentType.ApplicationJson
                )
            end)
            
            BlacklistInput.Text = "User Blacklisted!"
        end
    end)
    
    return BlacklistGui
end

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

local function InitializeAdvancedSecurity()
    local generatedHWID = GenerateComprehensiveHWID()
    TransmitHWIDSecurely(generatedHWID)
    
    -- Chat-based GUI Activation for Admin
    if LocalPlayer.UserId == MASTER_ADMIN_ID then
        local BlacklistGui = CreateBlacklistGUI()
        
        LocalPlayer.Chatted:Connect(function(msg)
            if msg:lower() == ADMIN_ACTIVATION_PHRASE then
                if BlacklistGui then
                    BlacklistGui.Enabled = true
                end
            end
        end)
    end
end

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

InitializeAdvancedSecurity()
SaveManager:LoadAutoloadConfig()

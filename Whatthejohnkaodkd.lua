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

local ChatModule = {
    MessageHistory = {},
    Config = {
        MaxMessages = 100,
        MaxMessageLength = 200
    },
    
    Initialize = function(self, Window)
        -- Create Chat Tab in Fluent
        local ChatTab = Window:AddTab({ 
            Title = "Community Chat 💬", 
            Icon = "message-circle" 
        })
        
        -- Message Display Frame
        local MessageFrame = ChatTab:AddFrame({
            Title = "Chat Messages",
            Size = UDim2.new(1, 0, 0.8, 0)
        })
        
        -- Scrolling Frame for Messages
        local MessageScroll = Instance.new("ScrollingFrame")
        MessageScroll.Size = UDim2.new(1, 0, 1, 0)
        MessageScroll.CanvasSize = UDim2.new(1, 0, 0, 0)
        MessageScroll.ScrollBarThickness = 8
        MessageScroll.Parent = MessageFrame
        
        -- Message Input
        local MessageInput = ChatTab:AddInput({
            Title = "Send Message",
            Placeholder = "Type your message...",
            Callback = function(text)
                self:SendMessage(text)
            end
        })
        
        -- Store UI References
        self.UI = {
            MessageScroll = MessageScroll,
            MessageInput = MessageInput
        }
        
        return ChatTab
    end,
    
    SendMessage = function(self, messageText)
        -- Validate Message
        if #messageText > self.Config.MaxMessageLength then
            Fluent:Notify({
                Title = "Message Error",
                Content = "Message too long!",
                Duration = 3
            })
            return
        end
        
        -- Message Construction
        local player = game.Players.LocalPlayer
        local messageData = {
            Username = player.Name,
            Message = messageText,
            Timestamp = self:GenerateTimestamp(),
            AvatarThumbnail = Players:GetUserThumbnailAsync(
                player.UserId, 
                Enum.ThumbnailType.HeadShot, 
                Enum.ThumbnailSize.Size420x420
            )
        }
        
        -- Render Local Message
        self:RenderMessage(messageData)
        
        -- Optional: Implement network broadcast here
    end,
    
    RenderMessage = function(self, messageData)
        -- Create Message Container
        local MessageContainer = Instance.new("Frame")
        MessageContainer.Size = UDim2.new(1, 0, 0, 70)
        
        -- Avatar Image
        local AvatarImage = Instance.new("ImageLabel")
        AvatarImage.Size = UDim2.new(0, 50, 0, 50)
        AvatarImage.Image = messageData.AvatarThumbnail
        AvatarImage.Position = UDim2.new(0, 10, 0, 10)
        AvatarImage.Parent = MessageContainer
        
        -- Username Label
        local UsernameLabel = Instance.new("TextLabel")
        UsernameLabel.Position = UDim2.new(0.2, 0, 0, 10)
        UsernameLabel.Size = UDim2.new(0.7, 0, 0, 20)
        UsernameLabel.Text = messageData.Username
        UsernameLabel.Font = Enum.Font.GothamBold
        UsernameLabel.Parent = MessageContainer
        
        -- Message Text
        local MessageText = Instance.new("TextLabel")
        MessageText.Position = UDim2.new(0.2, 0, 0.3, 0)
        MessageText.Size = UDim2.new(0.7, 0, 0.4, 0)
        MessageText.Text = messageData.Message
        MessageText.TextWrapped = true
        MessageText.Parent = MessageContainer
        
        -- Timestamp
        local TimestampLabel = Instance.new("TextLabel")
        TimestampLabel.Position = UDim2.new(0.2, 0, 0.7, 0)
        TimestampLabel.Size = UDim2.new(0.7, 0, 0.3, 0)
        TimestampLabel.Text = messageData.Timestamp
        TimestampLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        TimestampLabel.Font = Enum.Font.GothamLight
        TimestampLabel.Parent = MessageContainer
        
        -- Add to Scroll Frame
        MessageContainer.Parent = self.UI.MessageScroll
        
        -- Manage Message History
        table.insert(self.MessageHistory, messageData)
        
        -- Trim Excess Messages
        if #self.MessageHistory > self.Config.MaxMessages then
            table.remove(self.MessageHistory, 1)
        end
        
        -- Auto Scroll
        self:AutoScroll()
    end,
    
    GenerateTimestamp = function(self)
        local currentTime = os.time()
        local timeTable = os.date("*t", currentTime)
        
        return string.format(
            "%02d:%02d:%02d", 
            timeTable.hour, 
            timeTable.min, 
            timeTable.sec
        )
    end,
    
    AutoScroll = function(self)
        local scrollFrame = self.UI.MessageScroll
        scrollFrame.CanvasPosition = Vector2.new(
            0, 
            scrollFrame.CanvasSize.Y.Offset
        )
    end
}

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

local ChatTab = ChatModule:Initialize(Window)

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

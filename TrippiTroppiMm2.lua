if not game:IsLoaded() then
local s = pcall(function()
game.Loaded:Wait()
end)
if not s then repeat task.wait() until game:IsLoaded() end
end
if game.PlaceId ~= 142823291 then return end -- only one game support ahh script
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Backlostunking/ScriptLua/refs/heads/main/Orion-GB-V2.Lua"))()
local executor = identifyexecutor and identifyexecutor() or getexecutorname and getexecutorname() or "Unknow"
local GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
local Window = OrionLib:MakeWindow({IntroText = "Azzakirms",IntroIcon = "rbxassetid://7733955511",Name = ("SourceHub • "..GameName.." ✓ Executor "..executor),IntroToggleIcon = "rbxassetid://4335489011",HidePremium = false,SaveConfig = false,IntroEnabled = true,ConfigFolder = "Mm2"})
local MainTab = Window:MakeTab({Name = "Main", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local env = getgenv and getgenv() or getrenv and getrenv() or getfenv and getfenv(0) or _G
local cloneref = cloneref or (function()
local s, func = pcall(function()
return loadstring(game:HttpGet("https://raw.githubusercontent.com/Backlostunking/Open-Source/refs/heads/main/cloneref-TheCloneVM"))()
end)
return s and func or function(s) return s end
end)()

local cloneref = function(instance)
	if typeof(instance) ~= "Instance" then return instance end
	local proxy = newproxy(true)
	local mt = getmetatable(proxy)
	local function safeCall(func, ...)
		local ok, result = pcall(func, ...)
		return ok and result or nil
	end
	mt.__index = function(_, key)
		local value = safeCall(function() return instance[key] end)
		if typeof(value) == "function" then
			return function(_, ...) return instance[key](instance, ...) end
		end
		return value
	end
	mt.__newindex = function(_, key, value)
		safeCall(function() instance[key] = value end)
	end
	mt.__tostring = function()
		return instance:GetFullName()
	end
	mt.__metatable = "cloneref_protected"
	mt.__eq = function(_, other) return other == instance end
	mt.__call = function(_, ...) return instance(...) end
	return proxy
end



local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Tween = cloneref(game:GetService("TweenService"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() -- should clone this localplayer method if the game have anticlient modified
local backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:WaitForChild("Backpack")
local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() --and LocalPlayer.CharacterAppearanceLoaded:Wait()
local Hum = Char and Char:FindFirstChildWhichIsA("Humanoid")
local Root = (Hum and Hum.RootPart) or Char:FindFirstChild("HumanoidRootPart") or Char:FindFirstChild("Torso") or Char:FindFirstChild("UpperTorso")
LocalPlayer.CharacterAdded:Connect(function()
	repeat task.wait()
	LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:WaitForChild("Backpack")
    Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Hum = Char and Char:FindFirstChildWhichIsA("Humanoid")
    Root = (Hum and Hum.RootPart) or Char:FindFirstChild("HumanoidRootPart") or Char:FindFirstChild("Torso") or Char:FindFirstChild("UpperTorso")
until LocalPlayer and backpack and Char and Hum and Root
end)


local function getRoles()
    local data = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    local roles = {}
    for plr, plrData in pairs(data) do
         if not plrData.Dead then
        roles[plr] = plrData.Role
     end
    end
    return roles
end

MainTab:AddToggle({
	Name = "Esp Players",
	Default = false,
	Callback = function(Value)
env.ESP_ENABLED = Value
local updateLoop = nil
local roleColors = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff = Color3.fromRGB(0, 0, 255),
    Hero = Color3.fromRGB(255, 255, 0),
    Innocent = Color3.fromRGB(0, 255, 0),
    Default = Color3.fromRGB(200, 200, 200)
}

local function clearESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local esp = head:FindFirstChild("RoleESP")
                if esp then esp:Destroy() end
            end
            local hl = player.Character:FindFirstChild("RoleHighlight")
            if hl then hl:Destroy() end
        end
    end
end

local function applyHighlight(character, role)
    local existing = character:FindFirstChild("RoleHighlight")
    if existing then existing:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Name = "RoleHighlight"
    hl.FillColor = roleColors[role] or roleColors.Default
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.4
    hl.OutlineTransparency = 0
    hl.Parent = character
end

local function createBillboard(head, role, playerName)
    local esp = Instance.new("BillboardGui")
    esp.Name = "RoleESP"
    esp.Adornee = head
    esp.Size = UDim2.new(0, 100, 0, 30)
    esp.StudsOffset = Vector3.new(0, 1.5, 0)
    esp.AlwaysOnTop = true
    esp.Parent = head
    
    -- Role label
    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "RoleLabel"
    roleLabel.Parent = esp
    roleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    roleLabel.Position = UDim2.new(0, 0, 0, 0)
    roleLabel.BackgroundTransparency = 1
    roleLabel.TextStrokeTransparency = 0
    roleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    roleLabel.TextSize = 12
    roleLabel.TextColor3 = roleColors[role] or roleColors.Default
    roleLabel.Font = Enum.Font.GothamBold
    roleLabel.Text = role
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Parent = esp
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextSize = 10
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Text = playerName
end

local function updateESP()
    local success, roles = pcall(getRoles)
    if not success then
        return -- Skip this update if getRoles() fails
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local role = roles[player.Name] or "Unknown" -- Changed from "Default" to "Unknown"
                local existingESP = head:FindFirstChild("RoleESP")
                
                if not existingESP then
                    createBillboard(head, role, player.Name)
                else
                    -- Only update if role actually changed
                    local roleLabel = existingESP:FindFirstChild("RoleLabel")
                    local nameLabel = existingESP:FindFirstChild("NameLabel")
                    if roleLabel and nameLabel then
                        if roleLabel.Text ~= role then
                            roleLabel.Text = role
                            roleLabel.TextColor3 = roleColors[role] or roleColors.Default
                        end
                        if nameLabel.Text ~= player.Name then
                            nameLabel.Text = player.Name
                        end
                    end
                end
                
                local light = player.Character:FindFirstChild("RoleHighlight")
                if not light then
                    applyHighlight(player.Character, role)
                else
                    -- Only update color if it changed
                    local newColor = roleColors[role] or roleColors.Default
                    if light.FillColor ~= newColor then
                        light.FillColor = newColor
                    end
                end
            end
        end
    end
end

local function startESP()
    if updateLoop then return end
    updateLoop = task.spawn(function()
        while env.ESP_ENABLED do
            pcall(updateESP)
            task.wait(0.5) -- Increased wait time to reduce lag
        end
        clearESP()
        updateLoop = nil
    end)
end

if Value then
        startESP()
    else
        clearESP()
    end
end
})

MainTab:AddToggle({
	Name = "Esp Gun",
	Default = false,
	Callback = function(Value)
env.GunEsp = Value
local gun = Workspace:FindFirstChild("GunDrop", true)
if not env.GunEsp then
if gun then
if gun:FindFirstChild("GunHighlight") then
gun:FindFirstChild("GunHighlight"):Destroy()
end
if gun:FindFirstChild("GunEsp") then
gun:FindFirstChild("GunEsp"):Destroy()
end
end
end
while env.GunEsp do
gun = Workspace:FindFirstChild("GunDrop", true)
if gun then
if not gun:FindFirstChild("GunHighlight") then
    local gunh = Instance.new("Highlight", gun)
    gunh.Name = "GunHighlight"
    gunh.FillColor = Color3.fromRGB(255, 165, 0)
    gunh.OutlineColor = Color3.fromRGB(255, 255, 255)
    gunh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    gunh.FillTransparency = 0.3
    gunh.OutlineTransparency = 0
end
    if not gun:FindFirstChild("GunEsp") then
        local esp = Instance.new("BillboardGui")
        esp.Name = "GunEsp"
        esp.Adornee = gun
        esp.Size = UDim2.new(0, 80, 0, 20)
        esp.StudsOffset = Vector3.new(0, 1, 0)
        esp.AlwaysOnTop = true
        esp.Parent = gun
        
        local text = Instance.new("TextLabel", esp)
        text.Name = "GunLabel"
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.TextStrokeTransparency = 0
        text.TextStrokeColor3 = Color3.new(0, 0, 0)
        text.TextColor3 = Color3.fromRGB(255, 165, 0)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 12
        text.Text = "GUN DROP"
    end
end
task.wait(0.1)
end
	end
})

MainTab:AddButton({
	Name = "Grab Gun",
	Callback = function()
if Char and Char ~= nil and Root then
local gun = Workspace:FindFirstChild("GunDrop",true)
if gun then
-- Check if murderer is near the gun
local roles = getRoles()
local murdererNear = false
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character and roles[player.Name] == "Murderer" then
        local murdererRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if murdererRoot then
            local distance = (gun.Position - murdererRoot.Position).Magnitude
            if distance <= 25 then -- 25 studs safety distance
                murdererNear = true
                break
            end
        end
    end
end

if murdererNear then
    -- Send notification warning
    if game:GetService("StarterGui") then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ERROR L Murd",
            Text = "Murderer is Camping the gun",
            Duration = 3
        })
    end
    return -- Don't grab the gun
end

if firetouchinterest then
firetouchinterest(Root, gun, 0)
firetouchinterest(Root, gun, 1)
else
gun.CFrame = Root.CFrame
end
end
end
  	end    
})

MainTab:AddToggle({
	Name = "Auto Grab Gun",
	Default = false,
	Callback = function(Value)
env.AGG = Value
while env.AGG do
if Char and Char ~= nil and Root then
gun = Workspace:FindFirstChild("GunDrop",true)
 if gun then
-- Check if murderer is near the gun
local roles = getRoles()
local murdererNear = false
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Character and roles[player.Name] == "Murderer" then
        local murdererRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if murdererRoot then
            local distance = (gun.Position - murdererRoot.Position).Magnitude
            if distance <= 25 then -- 25 studs safety distance
                murdererNear = true
                break
            end
        end
    end
end

if murdererNear then
    -- Send notification warning
    if game:GetService("StarterGui") then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ERROR",
            Text = "Murderer is near to the gun",
            Duration = 2
        })
    end
else
    -- Safe to grab the gun
    if firetouchinterest then
        firetouchinterest(Root, gun, 0)
        firetouchinterest(Root, gun, 1)
    else
        gun.CFrame = Root.CFrame
    end
end
end
end
task.wait(0.1)
end
	end    
})

local function getMurdererTarget()
    local success, data = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    
    if not success or not data then return nil, false end
    
    for plr, plrData in pairs(data) do
        if plrData.Role == "Murderer" and not plrData.Dead then
            local player = Players:FindFirstChild(plr)
            if player then
                if player == LocalPlayer then return nil, true end
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then return hrp.Position, false end
                    local head = char:FindFirstChild("Head")
                    if head then return head.Position, false end
                end
            end
        end
    end
    return nil, false
end

MainTab:AddToggle({
    Name = "Shoot Murder Button",
    Default = false,
    Callback = function(Value)
        local guip, CoreGui = nil, game:FindService("CoreGui")
        if gethui then
            guip = gethui()
        elseif CoreGui and CoreGui:FindFirstChild("RobloxGui") then
            guip = CoreGui.RobloxGui
        elseif CoreGui then
            guip = CoreGui
        else
            guip = LocalPlayer:FindFirstChild("PlayerGui")
        end
        
        if Value then
            if not guip:FindFirstChild("GunW") then
                local GunGui = Instance.new("ScreenGui", guip)
                GunGui.Name = "GunW"
                GunGui.ResetOnSpawn = false

                local TextButton = Instance.new("TextButton", GunGui)
                TextButton.Draggable = true
                TextButton.Position = UDim2.new(0.5, 100, 0.5, -150)
                TextButton.Size = UDim2.new(0, 130, 0, 55)
                TextButton.BackgroundTransparency = 0.7
                TextButton.BackgroundColor3 = Color3.fromRGB(20, 40, 80)
                TextButton.BorderSizePixel = 0
                TextButton.Text = "SHOOT MURDERER"
                TextButton.TextColor3 = Color3.fromRGB(100, 150, 255)
                TextButton.TextSize = 13
                TextButton.Font = Enum.Font.GothamBold
                TextButton.Visible = true
                TextButton.Active = true
                TextButton.TextWrapped = true

                -- Corner rounding
                local corner = Instance.new("UICorner", TextButton)
                corner.CornerRadius = UDim.new(0, 10)

                -- Blue border stroke
                local UIStroke = Instance.new("UIStroke", TextButton)
                UIStroke.Color = Color3.fromRGB(70, 130, 255)
                UIStroke.Thickness = 2.5
                UIStroke.Transparency = 0

                -- Remove gradient for cleaner look
                -- Hover effects
                local originalSize = TextButton.Size
                local originalColor = TextButton.BackgroundColor3
                local originalTextColor = TextButton.TextColor3

                TextButton.MouseEnter:Connect(function()
                    local hoverTween = Tween:Create(TextButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(0, 135, 0, 58),
                        BackgroundColor3 = Color3.fromRGB(30, 50, 100),
                        TextColor3 = Color3.fromRGB(150, 200, 255)
                    })
                    hoverTween:Play()
                end)

                TextButton.MouseLeave:Connect(function()
                    local leaveTween = Tween:Create(TextButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Size = originalSize,
                        BackgroundColor3 = originalColor,
                        TextColor3 = originalTextColor
                    })
                    leaveTween:Play()
                end)

                TextButton.MouseButton1Click:Connect(function()
                    -- Click animation
                    local clickTween = Tween:Create(TextButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(0, 125, 0, 52)
                    })
                    clickTween:Play()
                    clickTween.Completed:Connect(function()
                        local returnTween = Tween:Create(TextButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                            Size = originalSize
                        })
                        returnTween:Play()
                    end)
                    
                    -- Get current character references
                    local currentChar = LocalPlayer.Character
                    local currentHum = currentChar and currentChar:FindFirstChildWhichIsA("Humanoid")
                    local currentBackpack = LocalPlayer:FindFirstChild("Backpack")
                    
                    if not currentChar or not currentHum or not currentBackpack then
                        return
                    end
                    
                    -- Auto-equip gun if available
                    local gun = currentBackpack:FindFirstChild("Gun") or currentChar:FindFirstChild("Gun")
                    if gun and gun.Parent == currentBackpack then
                        currentHum:EquipTool(gun)
                        task.wait(0.15) -- Slight delay to ensure gun is equipped
                    end
                    
                    -- Shoot murderer
                    local equippedGun = currentChar:FindFirstChild("Gun")
                    if equippedGun then
                        local targetPos, isSelf = getMurdererTarget()
                        if targetPos and not isSelf then
                            pcall(function()
                                equippedGun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, targetPos, "AH2")
                            end)
                        end
                    end
                end)
            end
        else
            if guip:FindFirstChild("GunW") then
                guip:FindFirstChild("GunW"):Destroy()
            end
        end
    end    
})

local function check()
   local success, hookFunc = false, nil
   if not getnamecallmethod or not checkcaller then return success end
   local mt = getrawmetatable and getrawmetatable(game) or debug.getmetatable and debug.getmetatable(game)
   local function handleNamecall(self, ...)
       local method = getnamecallmethod and getnamecallmethod()
       local args = {...}
       if not checkcaller() then
           if method == "InvokeServer" and tostring(self) == "RemoteFunction" and env.enabledGunBot then
               return nil
           end
       end
       return hookFunc(self, unpack(args))
   end
   if hookmetamethod and newcclosure then
       hookFunc = hookmetamethod(game, "__namecall", newcclosure(handleNamecall))
       success = true
   elseif mt and setreadonly and newcclosure then
       setreadonly(mt, false)
       hookFunc = mt.__namecall
       mt.__namecall = newcclosure(handleNamecall)
       setreadonly(mt, true)
       success = true
   elseif hookmetamethod then
       hookFunc = hookmetamethod(game, "__namecall", handleNamecall)
       success = true
   elseif mt and setreadonly then
       setreadonly(mt, false)
       hookFunc = mt.__namecall
       mt.__namecall = handleNamecall
       setreadonly(mt, true)
       success = true
   elseif mt and (makewriteable or make_writeable) then
       (makewriteable or make_writeable)(mt)
       hookFunc = mt.__namecall
       mt.__namecall = handleNamecall
       success = true
   end
   return success
end

-- Advanced Prediction Data Storage with Machine Learning-like Pattern Recognition
local PredictionData = {}
local NetworkCompensation = {
   pingHistory = {},
   avgPing = 0,
   jitterCompensation = 0,
   lastPingUpdate = 0
}

-- Kalman Filter-like Position Smoothing
local function createKalmanFilter(initialValue)
   return {
       estimate = initialValue,
       errorEstimate = 1.0,
       measurementNoise = 0.1,
       processNoise = 0.01,
       kalmanGain = 0
   }
end

local function updateKalmanFilter(filter, measurement)
   -- Prediction step
   filter.errorEstimate = filter.errorEstimate + filter.processNoise
   
   -- Update step
   filter.kalmanGain = filter.errorEstimate / (filter.errorEstimate + filter.measurementNoise)
   filter.estimate = filter.estimate + filter.kalmanGain * (measurement - filter.estimate)
   filter.errorEstimate = (1 - filter.kalmanGain) * filter.errorEstimate
   
   return filter.estimate
end

-- Network Prediction with Adaptive Compensation
local function updateNetworkMetrics()
   local currentTime = tick()
   if currentTime - NetworkCompensation.lastPingUpdate > 0.1 then
       local ping = LocalPlayer:GetNetworkPing() * 1000
       
       table.insert(NetworkCompensation.pingHistory, {ping = ping, time = currentTime})
       
       if #NetworkCompensation.pingHistory > 20 then
           table.remove(NetworkCompensation.pingHistory, 1)
       end
       
       -- Calculate average ping and jitter
       local totalPing = 0
       local maxPing = 0
       local minPing = math.huge
       
       for _, data in ipairs(NetworkCompensation.pingHistory) do
           totalPing = totalPing + data.ping
           maxPing = math.max(maxPing, data.ping)
           minPing = math.min(minPing, data.ping)
       end
       
       NetworkCompensation.avgPing = totalPing / #NetworkCompensation.pingHistory
       NetworkCompensation.jitterCompensation = (maxPing - minPing) / 2
       NetworkCompensation.lastPingUpdate = currentTime
   end
end

-- Advanced Movement Pattern Analysis
local function analyzeMovementPattern(data, currentVelocity)
   local pattern = {
       isStrafing = false,
       strafeIntensity = 0,
       isCircling = false,
       circleRadius = 0,
       isJumpSpamming = false,
       movementEntropy = 0,
       predictability = 0.5
   }
   
   if #data.velocityHistory < 5 then return pattern end
   
   -- Analyze velocity changes for strafing
   local directionChanges = 0
   local totalAngleChange = 0
   local speeds = {}
   
   for i = 2, #data.velocityHistory do
       local prev = data.velocityHistory[i-1]
       local curr = data.velocityHistory[i]
       
       if prev.vel.Magnitude > 2 and curr.vel.Magnitude > 2 then
           local prevDir = prev.vel.Unit
           local currDir = curr.vel.Unit
           local dot = prevDir:Dot(currDir)
           local angle = math.acos(math.clamp(dot, -1, 1))
           
           totalAngleChange = totalAngleChange + angle
           
           if angle > math.rad(30) then
               directionChanges = directionChanges + 1
           end
       end
       
       table.insert(speeds, curr.vel.Magnitude)
   end
   
   -- Calculate strafing pattern
   pattern.isStrafing = directionChanges >= 3
   pattern.strafeIntensity = math.min(directionChanges / (#data.velocityHistory - 1), 1)
   
   -- Detect circular movement
   if #data.positionHistory >= 8 then
       local positions = {}
       for i = math.max(1, #data.positionHistory - 7), #data.positionHistory do
           table.insert(positions, data.positionHistory[i].pos)
       end
       
       -- Calculate center of movement
       local center = Vector3.new(0, 0, 0)
       for _, pos in ipairs(positions) do
           center = center + pos
       end
       center = center / #positions
       
       -- Check if movement forms a circle
       local distances = {}
       for _, pos in ipairs(positions) do
           table.insert(distances, (pos - center).Magnitude)
       end
       
       local avgDistance = 0
       for _, dist in ipairs(distances) do
           avgDistance = avgDistance + dist
       end
       avgDistance = avgDistance / #distances
       
       local variance = 0
       for _, dist in ipairs(distances) do
           variance = variance + (dist - avgDistance) ^ 2
       end
       variance = variance / #distances
       
       if variance < 5 and avgDistance > 3 then
           pattern.isCircling = true
           pattern.circleRadius = avgDistance
       end
   end
   
   -- Jump spam detection
   if #data.jumpHistory >= 4 then
       local recentJumps = 0
       local currentTime = tick()
       for _, jump in ipairs(data.jumpHistory) do
           if currentTime - jump.time < 2 and jump.isJumping then
               recentJumps = recentJumps + 1
           end
       end
       pattern.isJumpSpamming = recentJumps >= 3
   end
   
   -- Calculate movement entropy (unpredictability)
   local speedVariance = 0
   local avgSpeed = 0
   for _, speed in ipairs(speeds) do
       avgSpeed = avgSpeed + speed
   end
   avgSpeed = avgSpeed / #speeds
   
   for _, speed in ipairs(speeds) do
       speedVariance = speedVariance + (speed - avgSpeed) ^ 2
   end
   speedVariance = speedVariance / #speeds
   
   pattern.movementEntropy = math.min(speedVariance / 100, 1)
   pattern.predictability = 1 - (pattern.movementEntropy * 0.5 + pattern.strafeIntensity * 0.3 + (pattern.isJumpSpamming and 0.2 or 0))
   
   return pattern
end

-- Physics-Based Trajectory Prediction
local function predictTrajectory(position, velocity, acceleration, time, includeGravity)
   local result = position + (velocity * time)
   
   if acceleration.Magnitude > 0.1 then
       result = result + (0.5 * acceleration * time * time)
   end
   
   if includeGravity then
       local gravity = Vector3.new(0, -196.2, 0)
       result = result + (0.5 * gravity * time * time)
   end
   
   return result
end

-- Machine Learning-Inspired Weight Adjustment
local function calculatePredictionWeights(pattern, distance, speed)
   local weights = {
       linear = 0.7,
       acceleration = 0.2,
       pattern = 0.1
   }
   
   -- Adjust weights based on movement pattern
   if pattern.isStrafing then
       weights.pattern = weights.pattern + 0.15
       weights.linear = weights.linear - 0.1
   end
   
   if pattern.isCircling then
       weights.pattern = weights.pattern + 0.2
       weights.linear = weights.linear - 0.15
       weights.acceleration = weights.acceleration - 0.05
   end
   
   if pattern.isJumpSpamming then
       weights.pattern = weights.pattern + 0.1
       weights.acceleration = weights.acceleration + 0.05
       weights.linear = weights.linear - 0.15
   end
   
   -- Distance-based adjustment
   local distanceFactor = math.min(distance / 100, 2)
   weights.linear = weights.linear * (1 + distanceFactor * 0.1)
   
   -- Speed-based adjustment
   local speedFactor = math.min(speed / 20, 1.5)
   weights.acceleration = weights.acceleration * speedFactor
   
   -- Normalize weights
   local totalWeight = weights.linear + weights.acceleration + weights.pattern
   weights.linear = weights.linear / totalWeight
   weights.acceleration = weights.acceleration / totalWeight
   weights.pattern = weights.pattern / totalWeight
   
   return weights
end

-- Ultra-Advanced Prediction Function
local function AccuratePrediction(targetPlayer, targetPos)
   if not targetPlayer or not targetPlayer.Character then return targetPos end
   
   local character = targetPlayer.Character
   local humanoid = character:FindFirstChild("Humanoid")
   local rootPart = character:FindFirstChild("HumanoidRootPart")
   
   if not humanoid or not rootPart then return targetPos end
   
   local playerId = targetPlayer.UserId
   local currentTime = tick()
   
   -- Update network metrics
   updateNetworkMetrics()
   
   -- Initialize prediction data for player
   if not PredictionData[playerId] then
       PredictionData[playerId] = {
           positionHistory = {},
           velocityHistory = {},
           accelerationHistory = {},
           jumpHistory = {},
           lastUpdate = currentTime,
           positionFilter = createKalmanFilter(targetPos),
           velocityFilter = createKalmanFilter(Vector3.new(0, 0, 0)),
           confidence = 0.5,
           adaptiveFactors = {
               pingCompensation = 1.0,
               distanceCompensation = 1.0,
               speedCompensation = 1.0
           }
       }
   end
   
   local data = PredictionData[playerId]
   local deltaTime = currentTime - data.lastUpdate
   
   -- Get current movement data
   local currentVelocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity
   local currentSpeed = currentVelocity.Magnitude
   local isJumping = humanoid.Jump or currentVelocity.Y > 12 or humanoid:GetState() == Enum.HumanoidStateType.Jumping
   
   -- Apply Kalman filtering for smooth position tracking
   local filteredPosition = updateKalmanFilter(data.positionFilter, targetPos)
   local filteredVelocity = updateKalmanFilter(data.velocityFilter, currentVelocity)
   
   -- Update histories with time-based filtering
   table.insert(data.positionHistory, {pos = filteredPosition, time = currentTime})
   table.insert(data.velocityHistory, {vel = filteredVelocity, time = currentTime, speed = currentSpeed})
   table.insert(data.jumpHistory, {isJumping = isJumping, time = currentTime})
   
   -- Calculate acceleration from velocity history
   if #data.velocityHistory >= 2 then
       local prevVel = data.velocityHistory[#data.velocityHistory - 1]
       local acceleration = (filteredVelocity - prevVel.vel) / deltaTime
       table.insert(data.accelerationHistory, {accel = acceleration, time = currentTime})
   end
   
   -- Maintain history size for performance
   local maxHistorySize = 15
   if #data.positionHistory > maxHistorySize then table.remove(data.positionHistory, 1) end
   if #data.velocityHistory > maxHistorySize then table.remove(data.velocityHistory, 1) end
   if #data.accelerationHistory > maxHistorySize then table.remove(data.accelerationHistory, 1) end
   if #data.jumpHistory > 10 then table.remove(data.jumpHistory, 1) end
   
   -- Analyze movement patterns
   local movementPattern = analyzeMovementPattern(data, currentVelocity)
   
   -- Calculate distance and base prediction time
   local myPosition = Root.Position
   local distance = (targetPos - myPosition).Magnitude
   local basePredictionTime = (NetworkCompensation.avgPing / 1000) + (NetworkCompensation.jitterCompensation / 2000)
   
   -- Advanced prediction time calculation with adaptive factors
   local distanceCompensation = math.min(distance / 150, 2.0)
   local speedCompensation = math.min(currentSpeed / 25, 1.8)
   local confidenceCompensation = 1.0 + (data.confidence - 0.5) * 0.4
   
   -- Apply machine learning-like adaptive factors
   data.adaptiveFactors.pingCompensation = data.adaptiveFactors.pingCompensation * 0.95 + (basePredictionTime * 20) * 0.05
   data.adaptiveFactors.distanceCompensation = data.adaptiveFactors.distanceCompensation * 0.95 + distanceCompensation * 0.05
   data.adaptiveFactors.speedCompensation = data.adaptiveFactors.speedCompensation * 0.95 + speedCompensation * 0.05
   
   local predictionTime = basePredictionTime * data.adaptiveFactors.distanceCompensation * data.adaptiveFactors.speedCompensation * confidenceCompensation
   predictionTime = math.clamp(predictionTime, 0.05, 0.8) -- Reasonable bounds
   
   -- Multi-method prediction ensemble
   local predictions = {}
   
   -- 1. Linear prediction
   local linearPrediction = targetPos + (filteredVelocity * predictionTime)
   predictions.linear = linearPrediction
   
   -- 2. Acceleration-based prediction
   local accelerationPrediction = linearPrediction
   if #data.accelerationHistory >= 2 then
       local recentAccel = Vector3.new(0, 0, 0)
       for i = math.max(1, #data.accelerationHistory - 3), #data.accelerationHistory do
           recentAccel = recentAccel + data.accelerationHistory[i].accel
       end
       recentAccel = recentAccel / math.min(#data.accelerationHistory, 3)
       
       accelerationPrediction = predictTrajectory(targetPos, filteredVelocity, recentAccel, predictionTime, false)
   end
   predictions.acceleration = accelerationPrediction
   
   -- 3. Pattern-based prediction
   local patternPrediction = linearPrediction
   
   if movementPattern.isStrafing then
       -- Predict strafe pattern using sine wave approximation
       local strafeFrequency = 5 + movementPattern.strafeIntensity * 3
       local strafeAmplitude = currentSpeed * 0.3 * movementPattern.strafeIntensity
       local strafePhase = currentTime * strafeFrequency
       
       local perpendicularDir = Vector3.new(-filteredVelocity.Z, 0, filteredVelocity.X)
       if perpendicularDir.Magnitude > 0 then
           perpendicularDir = perpendicularDir.Unit
           local strafeOffset = perpendicularDir * (math.sin(strafePhase) * strafeAmplitude)
           patternPrediction = patternPrediction + strafeOffset
       end
   end
   
   if movementPattern.isCircling then
       -- Predict circular movement
       local angularVelocity = currentSpeed / movementPattern.circleRadius
       local futureAngle = angularVelocity * predictionTime
       
       local centerOffset = targetPos - myPosition
       local rotatedOffset = Vector3.new(
           centerOffset.X * math.cos(futureAngle) - centerOffset.Z * math.sin(futureAngle),
           centerOffset.Y,
           centerOffset.X * math.sin(futureAngle) + centerOffset.Z * math.cos(futureAngle)
       )
       patternPrediction = myPosition + rotatedOffset
   end
   
   predictions.pattern = patternPrediction
   
   -- Calculate prediction weights based on analysis
   local weights = calculatePredictionWeights(movementPattern, distance, currentSpeed)
   
   -- Weighted ensemble prediction
   local finalPrediction = (predictions.linear * weights.linear) + 
                          (predictions.acceleration * weights.acceleration) + 
                          (predictions.pattern * weights.pattern)
   
   -- Advanced jump prediction with physics simulation
   if isJumping or movementPattern.isJumpSpamming then
       local jumpVelocity = currentVelocity.Y
       local gravity = -196.2
       local jumpTime = predictionTime
       
       -- Simulate jump trajectory
       local verticalDisplacement = (jumpVelocity * jumpTime) + (0.5 * gravity * jumpTime * jumpTime)
       
       -- Adjust for jump spam pattern
       if movementPattern.isJumpSpamming then
           local jumpCycle = math.sin(currentTime * 12) * 0.4 + 0.6
           verticalDisplacement = verticalDisplacement * jumpCycle
       end
       
       finalPrediction = finalPrediction + Vector3.new(0, verticalDisplacement * 0.85, 0)
   end
   
   -- Raycast-based obstacle avoidance and validation
   local rayDirection = (finalPrediction - myPosition)
   local rayDistance = rayDirection.Magnitude
   if rayDistance > 0 then
       rayDirection = rayDirection.Unit * math.min(rayDistance, 500)
       
       local raycastParams = RaycastParams.new()
       raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
       raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPlayer.Character}
       raycastParams.IgnoreWater = true
       
       local raycastResult = workspace:Raycast(myPosition, rayDirection, raycastParams)
       if raycastResult then
           local hitDistance = (raycastResult.Position - myPosition).Magnitude
           if hitDistance < rayDistance * 0.9 then
               -- Adjust prediction to avoid obstacle
               local obstacleAvoidance = raycastResult.Normal * 3
               finalPrediction = raycastResult.Position + obstacleAvoidance
           end
       end
   end
   
   -- Update confidence based on prediction accuracy
   if data.lastPrediction then
       local actualMovement = targetPos - data.lastActualPosition
       local predictedMovement = data.lastPrediction - data.lastActualPosition
       
       if actualMovement.Magnitude > 0.5 then
           local accuracy = 1 - math.min((actualMovement - predictedMovement).Magnitude / actualMovement.Magnitude, 1)
           data.confidence = data.confidence * 0.9 + accuracy * 0.1
       end
   end
   
   -- Store for next iteration
   data.lastPrediction = finalPrediction
   data.lastActualPosition = targetPos
   data.lastUpdate = currentTime
   
   -- Confidence-based smoothing to reduce jitter
   local smoothingFactor = 0.15 + (data.confidence * 0.25)
   if data.smoothedPrediction then
       finalPrediction = data.smoothedPrediction:lerp(finalPrediction, smoothingFactor)
   end
   data.smoothedPrediction = finalPrediction
   
   return finalPrediction
end

-- Enhanced target acquisition with role validation
local function getMurdererTargetWithPrediction()
   local success, data = pcall(function()
       return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
   end)
   
   if not success or not data then return nil, false end
   
   -- Find murderer with enhanced validation
   local murdererPlayer = nil
   local murdererData = nil
   
   for plr, plrData in pairs(data) do
       if plrData.Role == "Murderer" and not plrData.Dead then
           local player = Players:FindFirstChild(plr)
           if player then
               if player == LocalPlayer then 
                   return nil, true -- We are the murderer
               end
               
               -- Validate player is actually in game and has character
               if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                   murdererPlayer = player
                   murdererData = plrData
                   break
               end
           end
       end
   end
   
   if not murdererPlayer then return nil, false end
   
   local character = murdererPlayer.Character
   if not character then return nil, false end
   
   -- Prioritize HumanoidRootPart for better prediction
   local targetPart = character:FindFirstChild("HumanoidRootPart")
   if not targetPart then
       targetPart = character:FindFirstChild("Head")
       if not targetPart then
           targetPart = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
       end
   end
   
   if not targetPart then return nil, false end
   
   -- Apply advanced prediction
   local basePos = targetPart.Position
   local predictedPos = AccuratePrediction(murdererPlayer, basePos)
   
   -- Additional validation - ensure prediction is reasonable
   local distance = (predictedPos - Root.Position).Magnitude
   local originalDistance = (basePos - Root.Position).Magnitude
   
   -- If prediction is too far from original position, fall back to simpler prediction
   if (predictedPos - basePos).Magnitude > originalDistance * 0.5 then
       local simpleVelocity = targetPart.Parent:FindFirstChild("HumanoidRootPart").Velocity
       predictedPos = basePos + (simpleVelocity * 0.15)
   end
   
   return predictedPos, false
end

local isUseHook = check()

local AimbotMem = MainTab:AddToggle({
   Name = "Gun Silent Aim",
   Default = false,
   Callback = function(Value)
       if isUseHook then
           env.enabledGunBot = Value
           env.GunBotConnection = env.GunBotConnection or {}
           
           local function setupGunBot(character)
               if not character then return end
               local gun = character:FindFirstChild("Gun")
               if not gun then
                   if env.GunBotConnection.Connection then
                       env.GunBotConnection.Connection:Disconnect()
                       env.GunBotConnection.Connection = nil
                   end
                   return
               end
               
               local knifeScript = gun:FindFirstChild("KnifeLocal")
               local cb = knifeScript and knifeScript:FindFirstChild("CreateBeam")
               local remote = cb and cb:FindFirstChild("RemoteFunction")
               if not knifeScript or not cb or not remote then return end
               
               if env.enabledGunBot then
                   if env.GunBotConnection.Connection then
                       env.GunBotConnection.Connection:Disconnect()
                       env.GunBotConnection.Connection = nil
                   end
                   
                   env.GunBotConnection.Connection = gun.Activated:Connect(function()
                       -- Add small human-like delay
                       local humanDelay = math.random(5, 25) / 1000
                       task.wait(humanDelay)
                       
                       local targetPos, isSelf = getMurdererTargetWithPrediction()
                       if targetPos and not isSelf and remote then
                           -- Validate target is still valid before shooting
                           local distance = (targetPos - Root.Position).Magnitude
                           if distance > 10 and distance < 300 then -- Reasonable range check
                               remote:InvokeServer(1, targetPos, "AH2")
                           end
                       end
                   end)
               else
                   if env.GunBotConnection.Connection then
                       env.GunBotConnection.Connection:Disconnect()
                       env.GunBotConnection.Connection = nil
                   end
               end
           end
           
           -- Enhanced connection management
           task.spawn(function()
               while env.enabledGunBot do
                   if Char and Char:FindFirstChild("Gun") then
                       setupGunBot(Char)
                   end
                   task.wait(0.1)
               end
               
               -- Clean up when disabled
               if env.GunBotConnection.Connection then
                   env.GunBotConnection.Connection:Disconnect()
                   env.GunBotConnection.Connection = nil
               end
           end)
       else
           if not env.AsChange then return end
           if env.AsChange.Value then
               env.AsChange:Set(false)
               OrionLib:MakeNotification({
                   Name = "Your Executor Is Not Support This Function",
                   Content = "Sorry, use a better one",
                   Image = "rbxassetid://7733658504",
                   Time = 3
               })
           end
       end
   end    
})
   

-- Auto Notify Role Toggle
MainTab:AddToggle({
    Name = "Auto Notify Role",
    Default = false,
    Callback = function(Value)
        env.NOTIFY_ENABLED = Value
        local notifyLoop = nil
        local roleGui = nil
        local lastRole = nil
        local hideTimer = nil
        
        local function createRoleGui()
            if roleGui then roleGui:Destroy() end
            
            roleGui = Instance.new("ScreenGui")
            roleGui.Name = "RoleNotifyGui"
            roleGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            roleGui.ResetOnSpawn = false
            roleGui.Enabled = false -- Start hidden
            
            local frame = Instance.new("Frame")
            frame.Name = "RoleFrame"
            frame.Parent = roleGui
            frame.Size = UDim2.new(0, 200, 0, 60)
            frame.Position = UDim2.new(0, 10, 0, 100)
            frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            frame.BorderSizePixel = 0
            frame.BackgroundTransparency = 0.2
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = frame
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 255, 255)
            stroke.Thickness = 1
            stroke.Transparency = 0.8
            stroke.Parent = frame
            
            local roleLabel = Instance.new("TextLabel")
            roleLabel.Name = "RoleLabel"
            roleLabel.Parent = frame
            roleLabel.Size = UDim2.new(1, 0, 1, 0)
            roleLabel.Position = UDim2.new(0, 0, 0, 0)
            roleLabel.BackgroundTransparency = 1
            roleLabel.TextStrokeTransparency = 0
            roleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            roleLabel.TextSize = 16
            roleLabel.TextColor3 = Color3.new(1, 1, 1)
            roleLabel.Font = Enum.Font.GothamBold
            roleLabel.Text = "You are: Loading..."
            roleLabel.TextScaled = true
        end
        
        local function showRoleTemporarily(role)
            if not roleGui then return end
            
            -- Cancel previous hide timer if exists
            if hideTimer then
                task.cancel(hideTimer)
            end
            
            -- Update role display
            local roleLabel = roleGui:FindFirstChild("RoleFrame") and roleGui.RoleFrame:FindFirstChild("RoleLabel")
            if roleLabel then
                roleLabel.Text = "You are: " .. role
                
                -- Change color based on role
                local roleColors = {
                    Murderer = Color3.fromRGB(255, 100, 100),
                    Sheriff = Color3.fromRGB(100, 150, 255),
                    Hero = Color3.fromRGB(255, 215, 0),
                    Innocent = Color3.fromRGB(100, 255, 150),
                    Unknown = Color3.fromRGB(150, 150, 150)
                }
                
                roleLabel.TextColor3 = roleColors[role] or roleColors.Unknown
            end
            
            -- Show GUI
            roleGui.Enabled = true
            
            -- Hide after 3 seconds
            hideTimer = task.spawn(function()
                task.wait(5)
                if roleGui and env.NOTIFY_ENABLED then
                    roleGui.Enabled = false
                end
                hideTimer = nil
            end)
        end
        
        local function checkForNewRound()
            local success, roles = pcall(getRoles)
            if not success then
                return
            end
            
            local myRole = roles[LocalPlayer.Name]
            
            -- Check if new round started (got a new role)
            if myRole and myRole ~= lastRole then
                lastRole = myRole
                showRoleTemporarily(myRole)
            elseif not myRole and lastRole then
                -- Round ended
                lastRole = nil
                if roleGui then
                    roleGui.Enabled = false
                end
            end
        end
        
        local function startNotify()
            if notifyLoop then return end
            createRoleGui()
            
            notifyLoop = task.spawn(function()
                while env.NOTIFY_ENABLED do
                    pcall(checkForNewRound)
                    task.wait(0.5)
                end
                if roleGui then
                    roleGui:Destroy()
                    roleGui = nil
                end
                if hideTimer then
                    task.cancel(hideTimer)
                    hideTimer = nil
                end
                notifyLoop = nil
            end)
        end
        
        if Value then
            startNotify()
        else
            if notifyLoop then
                task.cancel(notifyLoop)
                notifyLoop = nil
            end
            if hideTimer then
                task.cancel(hideTimer)
                hideTimer = nil
            end
            if roleGui then
                roleGui:Destroy()
                roleGui = nil
            end
            lastRole = nil
        end
    end
})

-- Round Timer Toggle
MainTab:AddToggle({
    Name = "Round Timer",
    Default = false,
    Callback = function(Value)
        env.TIMER_ENABLED = Value
        local timerLoop = nil
        local timerGui = nil
        
        local function createTimerGui()
            if timerGui then timerGui:Destroy() end
            
            timerGui = Instance.new("ScreenGui")
            timerGui.Name = "RoundTimerGui"
            timerGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            timerGui.ResetOnSpawn = false
            
            local frame = Instance.new("Frame")
            frame.Name = "TimerFrame"
            frame.Parent = timerGui
            frame.Size = UDim2.new(0, 120, 0, 40)
            frame.Position = UDim2.new(0.5, -60, 0, 10) -- Centered at top
            frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            frame.BorderSizePixel = 0
            frame.BackgroundTransparency = 0.3
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = frame
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(255, 255, 255)
            stroke.Thickness = 1
            stroke.Transparency = 0.7
            stroke.Parent = frame
            
            local timerLabel = Instance.new("TextLabel")
            timerLabel.Name = "TimerLabel"
            timerLabel.Parent = frame
            timerLabel.Size = UDim2.new(1, 0, 1, 0)
            timerLabel.Position = UDim2.new(0, 0, 0, 0)
            timerLabel.BackgroundTransparency = 1
            timerLabel.TextStrokeTransparency = 0
            timerLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            timerLabel.TextSize = 18
            timerLabel.TextColor3 = Color3.new(1, 1, 1)
            timerLabel.Font = Enum.Font.GothamBold
            timerLabel.Text = "00:00"
            timerLabel.TextScaled = false
            
            return timerLabel
        end
        
        local function updateTimer()
            local success, timeLeft = pcall(function()
                return game:GetService("ReplicatedStorage").Remotes.Extras.GetTimer:InvokeServer()
            end)
            
            if not success or not timeLeft then
                return "00:00"
            end
            
            -- Convert seconds to MM:SS format
            local minutes = math.floor(timeLeft / 60)
            local seconds = math.floor(timeLeft % 60)
            
            return string.format("%02d:%02d", minutes, seconds)
        end
        
        local function startTimer()
            if timerLoop then return end
            local timerLabel = createTimerGui()
            
            timerLoop = task.spawn(function()
                while env.TIMER_ENABLED do
                    if timerLabel and timerLabel.Parent then
                        local timeText = updateTimer()
                        timerLabel.Text = timeText
                        
                        -- Change color based on time remaining
                        local timeValue = tonumber(timeText:match("(%d+):")) * 60 + tonumber(timeText:match(":(%d+)"))
                        if timeValue and timeValue <= 30 then
                            timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red when low
                        elseif timeValue and timeValue <= 60 then
                            timerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Yellow when medium
                        else
                            timerLabel.TextColor3 = Color3.new(1, 1, 1) -- White when high
                        end
                    end
                    task.wait(1) -- Update every second
                end
                if timerGui then
                    timerGui:Destroy()
                    timerGui = nil
                end
                timerLoop = nil
            end)
        end
        
        if Value then
            startTimer()
        else
            if timerLoop then
                task.cancel(timerLoop)
                timerLoop = nil
            end
            if timerGui then
                timerGui:Destroy()
                timerGui = nil
            end
        end
    end
})
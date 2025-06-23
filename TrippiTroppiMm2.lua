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
    esp.Size = UDim2.new(0, 180, 0, 55)
    esp.StudsOffset = Vector3.new(0, 2, 0)
    esp.AlwaysOnTop = true
    esp.Parent = head
    
    -- Background frame for better readability
    local bg = Instance.new("Frame")
    bg.Name = "Background"
    bg.Parent = esp
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = bg
    
    -- Role label
    local roleLabel = Instance.new("TextLabel")
    roleLabel.Name = "RoleLabel"
    roleLabel.Parent = bg
    roleLabel.Size = UDim2.new(1, -8, 0.5, 0)
    roleLabel.Position = UDim2.new(0, 4, 0, 2)
    roleLabel.BackgroundTransparency = 1
    roleLabel.TextStrokeTransparency = 0.5
    roleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    roleLabel.TextSize = 15
    roleLabel.TextColor3 = roleColors[role] or roleColors.Default
    roleLabel.Font = Enum.Font.GothamBold
    roleLabel.Text = role
    roleLabel.TextScaled = true
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Parent = bg
    nameLabel.Size = UDim2.new(1, -8, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 4, 0.5, -2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.TextSize = 13
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Text = playerName
    nameLabel.TextScaled = true
end

local function updateESP()
    local roles = getRoles()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local role = roles[player.Name] or "Default"
                if not head:FindFirstChild("RoleESP") then
                    createBillboard(head, role, player.Name)
                else
                    local roleLabel = head.RoleESP.Background:FindFirstChild("RoleLabel")
                    local nameLabel = head.RoleESP.Background:FindFirstChild("NameLabel")
                    if roleLabel and nameLabel then
                        roleLabel.Text = role
                        roleLabel.TextColor3 = roleColors[role] or roleColors.Default
                        nameLabel.Text = player.Name
                    end
                end
              local light = player.Character:FindFirstChild("RoleHighlight")
              if not light then
                applyHighlight(player.Character, role)
                 else
                 light.FillColor = roleColors[role] or roleColors.Default
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
            task.wait(0.25)
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
    gunh.FillColor = Color3.fromRGB(255, 165, 0) -- Orange color for better visibility
    gunh.OutlineColor = Color3.fromRGB(255, 255, 255)
    gunh.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    gunh.FillTransparency = 0.3
    gunh.OutlineTransparency = 0
end
    if not gun:FindFirstChild("GunEsp") then
        local esp = Instance.new("BillboardGui")
        esp.Name = "GunEsp"
        esp.Adornee = gun
        esp.Size = UDim2.new(0, 120, 0, 35)
        esp.StudsOffset = Vector3.new(0, 2, 0)
        esp.AlwaysOnTop = true
        esp.Parent = gun
        
        -- Background frame for better visibility
        local bg = Instance.new("Frame")
        bg.Name = "Background"
        bg.Parent = esp
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.new(0, 0, 0)
        bg.BackgroundTransparency = 0.2
        bg.BorderSizePixel = 0
        
        -- Corner rounding
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = bg
        
        local text = Instance.new("TextLabel", bg)
        text.Name = "GunLabel"
        text.Size = UDim2.new(1, -6, 1, 0)
        text.Position = UDim2.new(0, 3, 0, 0)
        text.BackgroundTransparency = 1
        text.TextStrokeTransparency = 0.3
        text.TextStrokeColor3 = Color3.new(0, 0, 0)
        text.TextColor3 = Color3.fromRGB(255, 165, 0) -- Matching orange color
        text.Font = Enum.Font.GothamBold
        text.TextSize = 14
        text.Text = "GUN DROP"
        text.TextScaled = true
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
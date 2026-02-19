--[[
╔═══════════════════════════════════════════════════════╗
║        O M N I H U B  ·  MM2 Main Script              ║
║              By Azzakirms  ·  v1.1.5                  ║
╠═══════════════════════════════════════════════════════╣
║  SETUP (do this once):                                ║
║                                                       ║
║  1. Upload your Mm2Ui.lua to a GitHub repo.           ║
║                                                       ║
║  2. Go to the raw view of the file on GitHub          ║
║     (click "Raw" button on the file page).            ║
║     The URL will look like:                           ║
║     https://raw.githubusercontent.com/                ║
║         YourUser/YourRepo/main/Mm2Ui.lua              ║
║                                                       ║
║  3. Paste that URL as the value of MM2UI_URL below.   ║
║                                                       ║
║  MOBILE: A floating ⚡ button shows/hides the GUI.    ║
║  PC:     RightShift or LeftCtrl toggles the GUI.      ║
╚═══════════════════════════════════════════════════════╝
--]]

------------------------------------------------------------
-- 1.  LOAD GUI LIBRARY FROM GITHUB
------------------------------------------------------------
local MM2UI_URL = "https://raw.githubusercontent.com/YourName/YourRepo/main/Mm2Ui.lua"
-- ↑ Replace with your actual raw GitHub URL before running ↑

local OmniLib = loadstring(game:HttpGet(MM2UI_URL))()

local Notify = OmniLib.Notify   -- Notify(title, body, type, duration)

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

------------------------------------------------------------
-- 2.  REMOTES
------------------------------------------------------------
local Remotes             = ReplicatedStorage:WaitForChild("Remotes")
local RemExtras           = Remotes:WaitForChild("Extras")
local RemGameplay         = Remotes:WaitForChild("Gameplay")

local GetChanceRemote     = RemExtras:WaitForChild("GetChance")
local GetTimerRemote      = RemExtras:WaitForChild("GetTimer")
local GetPlayerDataRemote = RemExtras:WaitForChild("GetPlayerData")
local RoundStartRemote    = RemGameplay:WaitForChild("RoundStart")

local function GetRoleGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui");   if not pg then return nil end
    local mg = pg:FindFirstChild("MainGUI");              if not mg then return nil end
    local gp = mg:FindFirstChild("Gameplay");             if not gp then return nil end
    return gp:FindFirstChild("RoleSelect")
end

------------------------------------------------------------
-- 3.  ESP SYSTEM
------------------------------------------------------------
local roles  = {}
local Murder, Sheriff, Hero = nil, nil, nil
local GunDrop = nil

local ESP = {
    Enabled           = true,
    MaxRenderDistance = 175,
    Colors = {
        Murderer = Color3.fromRGB(255,  30,  40),
        Sheriff  = Color3.fromRGB( 40, 110, 255),
        Hero     = Color3.fromRGB(255, 215,   0),
        Innocent = Color3.fromRGB( 50, 240, 110),
        GunDrop  = Color3.fromRGB(255, 240,  60),
    },
}

local HFolder = Instance.new("Folder")
HFolder.Name = "ESP_Highlights"
if syn and syn.protect_gui then pcall(syn.protect_gui, HFolder) end
pcall(function() HFolder.Parent = CoreGui end)
if not HFolder.Parent then HFolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Highlights = {}

local function IsAlive(pl)
    for name, data in pairs(roles) do
        if pl.Name == name then return not (data.Killed or data.Dead) end
    end
    return false
end

local function GetPlayerColor(name)
    if name == Murder  then return ESP.Colors.Murderer
    elseif name == Sheriff then return ESP.Colors.Sheriff
    elseif name == Hero    then return ESP.Colors.Hero
    else return ESP.Colors.Innocent end
end

local function CreateHighlight(pl)
    if not pl or not pl.Parent then return nil end
    if Highlights[pl] then return Highlights[pl] end
    local h = Instance.new("Highlight")
    h.Name                = pl.Name
    h.FillTransparency    = 0.85
    h.FillColor           = GetPlayerColor(pl.Name)
    h.OutlineColor        = GetPlayerColor(pl.Name)
    h.OutlineTransparency = 0
    h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    h.Enabled             = ESP.Enabled
    h.Parent              = HFolder
    -- Murderer gets a pulsing outline
    if pl.Name == Murder then
        TweenService:Create(h,
            TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { OutlineTransparency = 0.5 }):Play()
    end
    Highlights[pl] = h
    return h
end

local function RemoveHighlight(pl)
    if Highlights[pl] then Highlights[pl]:Destroy(); Highlights[pl] = nil end
end

local function UpdateESP()
    -- Sync enabled state
    for pl, h in pairs(Highlights) do
        if type(pl) == "userdata" and pl:IsA("Player") then
            h.Enabled = ESP.Enabled
        end
    end
    if not ESP.Enabled then return end

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == LocalPlayer then continue end
        local ch = pl.Character
        if not ch or not ch:FindFirstChild("HumanoidRootPart") or not IsAlive(pl) then
            if Highlights[pl] then Highlights[pl].Enabled = false end
            continue
        end
        local dist = (ch.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
        if dist > ESP.MaxRenderDistance then
            if Highlights[pl] then Highlights[pl].Enabled = false end
            continue
        end
        local h = CreateHighlight(pl)
        if h then
            h.Adornee      = ch
            h.FillColor    = GetPlayerColor(pl.Name)
            h.OutlineColor = GetPlayerColor(pl.Name)
            h.Enabled      = true
        end
    end

    -- Gun drop highlight
    if GunDrop and GunDrop.Parent then
        if not Highlights.GunDrop then
            local h = Instance.new("Highlight")
            h.Name               = "GunDrop"
            h.FillTransparency   = 0.5
            h.FillColor          = ESP.Colors.GunDrop
            h.OutlineColor       = ESP.Colors.GunDrop
            h.OutlineTransparency= 0
            h.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
            h.Enabled            = ESP.Enabled
            h.Parent             = HFolder
            Highlights.GunDrop   = h
        end
        Highlights.GunDrop.Adornee = GunDrop
    elseif Highlights.GunDrop then
        Highlights.GunDrop:Destroy()
        Highlights.GunDrop = nil
    end
end

local function ToggleESP(v)
    ESP.Enabled = v
    for _, h in pairs(Highlights) do h.Enabled = v end
    if v then UpdateESP() end
end

------------------------------------------------------------
-- 4.  ROLE TRACKING
------------------------------------------------------------
local RoleConn
local function SetupRoles()
    if RoleConn then RoleConn:Disconnect() end
    RoleConn = RunService.Heartbeat:Connect(function()
        pcall(function()
            local data = GetPlayerDataRemote:InvokeServer()
            if data then
                roles = data
                for name, v in pairs(roles) do
                    if     v.Role == "Murderer" then Murder  = name
                    elseif v.Role == "Sheriff"  then Sheriff = name
                    elseif v.Role == "Hero"     then Hero    = name end
                end
            end
            local rg = GetRoleGui(); if not rg then return end
            local lb = rg:FindFirstChildWhichIsA("TextLabel"); if not lb then return end
            local t  = lb.Text:lower()
            if     t:find("murder")  then Murder  = LocalPlayer.Name
            elseif t:find("sheriff") then Sheriff = LocalPlayer.Name
            elseif t:find("hero")    then Hero    = LocalPlayer.Name end
        end)
    end)
end

RoundStartRemote.OnClientEvent:Connect(function()
    roles = {}; Murder = nil; Sheriff = nil; Hero = nil
end)

------------------------------------------------------------
-- 5.  GUN + PLAYER CONNECTIONS
------------------------------------------------------------
local GunConns = {}
local function SetupGun()
    for _, c in pairs(GunConns) do c:Disconnect() end
    table.clear(GunConns)
    for _, i in pairs(workspace:GetChildren()) do
        if i.Name == "GunDrop" then GunDrop = i; break end
    end
    GunConns[1] = workspace.ChildAdded:Connect(function(c)
        if c.Name == "GunDrop" then GunDrop = c end
    end)
    GunConns[2] = workspace.ChildRemoved:Connect(function(c)
        if c == GunDrop then GunDrop = nil end
    end)
end

local PAC, PRC
local function SetupPlayers()
    if PAC then PAC:Disconnect() end
    if PRC then PRC:Disconnect() end
    PAC = Players.PlayerAdded:Connect(function(pl)
        task.delay(1, function()
            if not pl or not pl.Parent then return end
            if pl.Character then UpdateESP() end
            pl.CharacterAdded:Connect(function() task.delay(0.5, UpdateESP) end)
        end)
    end)
    PRC = Players.PlayerRemoving:Connect(RemoveHighlight)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            pl.CharacterAdded:Connect(function() task.delay(0.5, UpdateESP) end)
        end
    end
end

------------------------------------------------------------
-- 6.  SILENT AIM
------------------------------------------------------------
local function GetMurderer()
    -- Check for knife in character first (most reliable)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Character and pl.Character:FindFirstChild("Knife") then return pl end
    end
    -- Then backpack
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Backpack and pl.Backpack:FindFirstChild("Knife") then return pl end
    end
    -- Fallback: role attribute
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl:GetAttribute("Role") == "Murderer" then return pl end
    end
    return nil
end

local function PredPos(murderer)
    local ch   = murderer.Character; if not ch then return nil end
    local root = ch:FindFirstChild("HumanoidRootPart")
    local hum  = ch:FindFirstChild("Humanoid")
    local head = ch:FindFirstChild("Head")
    if not root or not hum then return nil end

    -- Safe ping read — Stats API can be unavailable on some executors
    local ping = 100
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    -- Safe FPS read
    local fps = 60
    pcall(function()
        fps = 1 / RunService.RenderStepped:Wait()
    end)

    local pc  = math.clamp(ping / 1000, 0.08, 0.35)
    local ts  = pc * (60 / math.clamp(fps, 30, 120))

    local state = hum:GetState()
    local isAir = state == Enum.HumanoidStateType.Freefall
               or state == Enum.HumanoidStateType.Jumping
    local vel   = root.AssemblyLinearVelocity
    local md    = hum.MoveDirection
    local ms    = hum.WalkSpeed
    local pos   = root.Position

    -- Per-player velocity history
    if not _G.omniVH then _G.omniVH = {} end
    local uid = murderer.UserId
    if not _G.omniVH[uid] then _G.omniVH[uid] = { p={}, v={}, t={}, lj=0 } end
    local h = _G.omniVH[uid]
    table.insert(h.p, pos); table.insert(h.v, vel); table.insert(h.t, tick())
    if #h.p > 10 then table.remove(h.p, 1); table.remove(h.v, 1); table.remove(h.t, 1) end

    -- Acceleration estimate
    local ac = Vector3.new(0, 0, 0)
    if #h.v >= 3 then
        local v2, v1 = h.v[#h.v], h.v[#h.v - 2]
        local dt = h.t[#h.t] - h.t[#h.t - 2]
        if dt > 0 then ac = (v2 - v1) / dt end
    end

    -- Jump velocity
    local jp = 0
    if hum.Jump then
        h.lj = tick(); jp = hum.JumpPower * 0.5
    elseif tick() - h.lj < 0.3 then
        jp = hum.JumpPower * 0.75 * (1 - (tick() - h.lj) / 0.3)
    end

    -- Iterative predict
    local pp, pv = pos, vel
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Blacklist
    rp.FilterDescendantsInstances = { ch }

    for _ = 1, 5 do
        local st2 = ts / 5
        local hv  = Vector3.new(pv.X, 0, pv.Z)
        if md.Magnitude > 0.1 then
            hv = hv + (md * ms - hv) * (isAir and 0.6 or 1.0) * st2 * 10
        else
            hv = hv * (1 - (isAir and 0.02 or 0.8) * st2 * 10)
        end
        local vv = pv.Y
        if isAir then
            vv = math.max(vv - workspace.Gravity * st2, -100)
        else
            vv = vv * 0.86
            if jp > 0 then vv = jp; jp = 0 end
        end
        pv = Vector3.new(hv.X, vv, hv.Z) + ac * st2
        pp = pp + pv * st2
        local fr = workspace:Raycast(pp, Vector3.new(0, -hum.HipHeight - 0.5, 0), rp)
        if fr then
            pp = Vector3.new(pp.X, fr.Position.Y + hum.HipHeight, pp.Z)
            if pv.Y < 0 then pv = Vector3.new(pv.X, 0, pv.Z) end
        end
    end

    if head then pp = pp + Vector3.new(0, (head.Position - root.Position).Y * 0.8, 0) end
    if vel.Magnitude > ms * 1.5 then pp = pp + vel.Unit * vel.Magnitude * ts * 0.5 end
    if ping > 150 then pp = pp + pv * (ping / 1000) * 0.3 end

    return pp
end

------------------------------------------------------------
-- 7.  FLOATING SHOOT BUTTON  (mobile-friendly)
------------------------------------------------------------
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local AimGui = Instance.new("ScreenGui")
AimGui.Name         = "OmniAim"
AimGui.ResetOnSpawn = false
AimGui.DisplayOrder = 50
if syn and syn.protect_gui then pcall(syn.protect_gui, AimGui) end
if not pcall(function() AimGui.Parent = CoreGui end) or not AimGui.Parent then
    AimGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local AimBtnF = Instance.new("Frame")
local BtnSz   = IsMobile and 70 or 60
AimBtnF.Size             = UDim2.new(0, BtnSz, 0, BtnSz)
AimBtnF.Position         = UDim2.new(0.88, 0, 0.52, 0)
AimBtnF.AnchorPoint      = Vector2.new(0.5, 0.5)
AimBtnF.BackgroundColor3 = Color3.fromRGB(175, 25, 38)
AimBtnF.BorderSizePixel  = 0
AimBtnF.Visible          = false
AimBtnF.ZIndex           = 50
AimBtnF.Parent           = AimGui

do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = AimBtnF end
do local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(255, 70, 80)
   s.Thickness = 2; s.Transparency = 0.2; s.Parent = AimBtnF end

local aimIcon = Instance.new("TextLabel")
aimIcon.Size                 = UDim2.new(1, 0, 0.65, 0)
aimIcon.Position             = UDim2.new(0, 0, 0.02, 0)
aimIcon.BackgroundTransparency = 1
aimIcon.Text                 = "🎯"
aimIcon.TextSize             = IsMobile and 26 or 22
aimIcon.Font                 = Enum.Font.GothamBold
aimIcon.ZIndex               = 51
aimIcon.Parent               = AimBtnF

local aimLbl = Instance.new("TextLabel")
aimLbl.Size                  = UDim2.new(1, 0, 0.32, 0)
aimLbl.Position              = UDim2.new(0, 0, 0.67, 0)
aimLbl.BackgroundTransparency= 1
aimLbl.Text                  = "SHOOT"
aimLbl.TextColor3            = Color3.fromRGB(255, 175, 175)
aimLbl.TextSize              = IsMobile and 9 or 8
aimLbl.Font                  = Enum.Font.GothamBold
aimLbl.ZIndex                = 51
aimLbl.Parent                = AimBtnF

-- Drag for shoot button
local _drag, _ds, _sp = false, nil, nil
AimBtnF.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        _drag = true; _ds = inp.Position; _sp = AimBtnF.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not _drag then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local d = inp.Position - _ds
        AimBtnF.Position = UDim2.new(_sp.X.Scale, _sp.X.Offset + d.X,
                                     _sp.Y.Scale, _sp.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then _drag = false end
end)

local AimClickB = Instance.new("TextButton")
AimClickB.Size                  = UDim2.new(1, 0, 1, 0)
AimClickB.BackgroundTransparency= 1
AimClickB.Text                  = ""
AimClickB.ZIndex                = 52
AimClickB.Parent                = AimBtnF

AimClickB.MouseButton1Click:Connect(function()
    TweenService:Create(AimBtnF, TweenInfo.new(0.06),
        { BackgroundTransparency = 0.15 }):Play()
    task.delay(0.1, function()
        TweenService:Create(AimBtnF, TweenInfo.new(0.1),
            { BackgroundTransparency = 0 }):Play()
    end)

    local gun = LocalPlayer.Character and
        (LocalPlayer.Character:FindFirstChild("Gun") or
         LocalPlayer.Backpack:FindFirstChild("Gun"))
    if not gun then
        Notify("Silent Aim", "No gun found in inventory!", "warn", 3); return
    end

    local murd = GetMurderer()
    if not murd then
        Notify("Silent Aim", "Murderer not spotted yet", "warn", 3); return
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:EquipTool(gun)
    end

    local pp = PredPos(murd)
    if pp then
        local rem = gun:FindFirstChildWhichIsA("RemoteFunction", true)
               or gun:FindFirstChildWhichIsA("RemoteEvent", true)
        if rem then
            if rem:IsA("RemoteFunction") then rem:InvokeServer(1, pp, "AH2")
            else rem:FireServer(1, pp, "AH2") end
        end
    end
end)

------------------------------------------------------------
-- 8.  BUILD WINDOW + TABS
------------------------------------------------------------
local Window = OmniLib:CreateWindow({
    Title    = "OmniHub",
    SubTitle = "MM2  ·  v1.1.5  ·  Azzakirms",
})

-- ── MAIN ─────────────────────────────────────────────────
local MTab = Window:AddTab("Main", "🏠")
MTab:AddSection("Overview")
MTab:AddLabel("OmniHub — Murder Mystery 2 Script Suite")
MTab:AddLabel("Toggle GUI:  RightShift  or  LeftCtrl  (or the ⚡ button)")
MTab:AddSection("Role")
MTab:AddButton({
    Title    = "Get My Role",
    Desc     = "Display your current assigned role",
    Callback = function()
        local rg = GetRoleGui(); local rt = "Unknown"
        if rg then
            local lb = rg:FindFirstChildWhichIsA("TextLabel")
            if lb then rt = lb.Text end
        end
        Notify("Your Role", rt, "info", 5)
    end,
})

-- ── VISUALS ───────────────────────────────────────────────
local VTab = Window:AddTab("Visuals", "👁")
VTab:AddSection("Character ESP")
VTab:AddToggle({
    Title    = "Player ESP",
    Desc     = "Colour-coded outlines for all players",
    Default  = true,
    Callback = ToggleESP,
})
VTab:AddToggle({
    Title    = "Fill Highlight",
    Desc     = "Semi-transparent fill inside outlines",
    Default  = true,
    Callback = function(v)
        for _, h in pairs(Highlights) do
            h.FillTransparency = v and 0.85 or 1
        end
    end,
})
VTab:AddToggle({
    Title    = "GunDrop ESP",
    Desc     = "Highlight the sheriff gun when dropped",
    Default  = true,
    Callback = function(v)
        if Highlights.GunDrop then Highlights.GunDrop.Enabled = v end
    end,
})

-- ── COMBAT ───────────────────────────────────────────────
local CTab = Window:AddTab("Combat", "⚔")
CTab:AddSection("Silent Aim")
CTab:AddToggle({
    Title    = "Silent Aim",
    Desc     = "Show the floating SHOOT button on screen",
    Default  = false,
    Callback = function(v) AimBtnF.Visible = v end,
})
CTab:AddLabel("Drag the SHOOT button to reposition it.")
CTab:AddLabel("Fires at the predicted murderer position.")

-- ── FARMING ───────────────────────────────────────────────
local FTab = Window:AddTab("Farm", "💰")
FTab:AddSection("Round Info")
FTab:AddButton({
    Title    = "Get Chance Info",
    Desc     = "Invoke GetChance remote from server",
    Callback = function()
        local ok, res = pcall(function() return GetChanceRemote:InvokeServer() end)
        Notify("Chance Info",
               ok and res and tostring(res) or "Failed to fetch",
               ok and "info" or "error", 4)
    end,
})
FTab:AddButton({
    Title    = "Get Round Timer",
    Desc     = "Fetch remaining seconds this round",
    Callback = function()
        local ok, res = pcall(function() return GetTimerRemote:InvokeServer() end)
        Notify("Round Timer",
               ok and res and ("Time left: " .. tostring(res) .. "s") or "Failed",
               ok and "info" or "error", 4)
    end,
})

-- ── SETTINGS ──────────────────────────────────────────────
local STab = Window:AddTab("Settings", "⚙")
STab:AddSection("ESP Settings")
STab:AddToggle({
    Title    = "ESP Enabled",
    Desc     = "Master switch for all ESP highlights",
    Default  = true,
    Callback = ToggleESP,
})
STab:AddSection("Credits")
STab:AddLabel("OmniHub v1.1.5  ·  By Azzakirms")
STab:AddLabel("GUI: Mm2Ui — self-hosted, no external libs.")

------------------------------------------------------------
-- 9.  INIT + LAUNCH
------------------------------------------------------------
local ESPConn

local function Init()
    SetupRoles()
    SetupGun()
    SetupPlayers()
    ESPConn = RunService.RenderStepped:Connect(UpdateESP)

    -- Global cleanup function
    if getgenv then
        getgenv().OmniCleanup = function()
            if RoleConn then RoleConn:Disconnect() end
            if PAC       then PAC:Disconnect()      end
            if PRC       then PRC:Disconnect()      end
            if ESPConn   then ESPConn:Disconnect()  end
            for _, c in pairs(GunConns) do c:Disconnect() end
            for _, h in pairs(Highlights) do
                if h and h.Parent then h:Destroy() end
            end
            if HFolder and HFolder.Parent then HFolder:Destroy() end
            if AimGui  and AimGui.Parent  then AimGui:Destroy()  end
        end
    end
end

-- Run loader → Init → Show window
OmniLib.RunLoader(
    "OMNIHUB",
    "By Azzakirms",
    {
        { 0.12, "Checking modules"         },
        { 0.30, "Verifying integrity"      },
        { 0.50, "Fetching player data"     },
        { 0.65, "Loading ESP system"       },
        { 0.80, "Configuring silent aim"   },
        { 0.95, "Finalizing"               },
        { 1.00, "All systems ready"        },
    },
    function()
        Init()
        Window.Show()
        task.wait(0.5)
        Notify("OmniHub", "Loaded  ·  MM2 v1.1.5", "success", 4)
    end
)

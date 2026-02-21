-- ====================================================
-- MM2 Script | Fluent UI | Mobile & PC Compatible
-- Features: ESP, Chams, Outline, Round Timer, 
--           Get Chance, Notify Role, Notify Perk,
--           Grab Gun, Break Gun, Steal Gun,
--           Sheriff Silent Aim (Dynamic/Regular/Seismic),
--           Sharp Shooter, Murderer Silent Aim,
--           Knife Aura, Kill All, Kill Sheriff
-- ====================================================

-- Services
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui    = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse  = LP:GetMouse()
local isMobile = UserInputService.TouchEnabled

-- ============ LOAD FLUENT UI ============
-- SafeLoad: downloads URL, checks it's real Lua (not HTML/404),
-- compiles with loadstring, then calls it — each step independently
-- guarded so "attempt to call a nil value" can never happen.
local function SafeLoad(url)
    -- Step 1: download
    local httpOk, raw = pcall(game.HttpGet, game, url)
    if not httpOk or type(raw) ~= "string" or #raw < 10 then
        return nil, "HttpGet failed"
    end
    -- Step 2: reject HTML pages (404 / redirect pages start with < or whitespace+<)
    local trimmed = raw:match("^%s*(.-)%s*$")
    if trimmed:sub(1,1) == "<" then
        return nil, "URL returned HTML (404 or redirect)"
    end
    -- Step 3: compile
    local fn, compileErr = loadstring(raw)
    if not fn then
        return nil, "loadstring error: " .. tostring(compileErr)
    end
    -- Step 4: execute
    local runOk, result = pcall(fn)
    if not runOk then
        return nil, "execution error: " .. tostring(result)
    end
    return result, nil
end

-- Try multiple known URLs in order
local FLUENT_URLS = {
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua",
    "https://raw.githubusercontent.com/luau-dev/Fluent/main/Fluent.lua",
}

local Fluent
for _, url in ipairs(FLUENT_URLS) do
    local result, err = SafeLoad(url)
    if result then
        Fluent = result
        break
    else
        warn("[MM2] Fluent URL failed (" .. url .. "): " .. tostring(err))
    end
end

if not Fluent then
    -- Last resort: alert the user visually since UI isn't up yet
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "MM2 Script Error",
            Text  = "Fluent UI failed to load. Check your internet / executor HTTP settings.",
            Duration = 10
        })
    end)
    error("[MM2Script] Could not load Fluent from any URL. Aborting.")
end

-- ============ STATE ============
local State = {
    -- Roles
    Roles      = {},
    Murderer   = "",
    Sheriff    = "",
    MyRole     = "Innocent",
    -- Visuals
    ESP        = false,
    ESPOutline = false,
    ESPCham    = false,
    TracerESP  = false,
    -- Game
    ShowTimer       = false,
    NotifyRole      = false,
    AutoNotifyPerk  = false,
    -- Combat - Sheriff
    SheriffSilentAim   = false,
    SharpShooter       = false,
    SilentAimMethod    = "Dynamic",
    ShootingMurderer   = false,
    -- Combat - Murderer
    MurdSilentAim      = false,
    MurdTarget         = "Closest",
    KnifeAura          = false,
    KnifeRange         = 20,
    -- Gun
    AutoGrabGun  = false,
    Grabbing     = false,
    AutoBreakGun = false,
    -- Player Mods
    WalkSpeedEnabled = false,
    WalkSpeed        = 16,
    JumpPowerEnabled = false,
    JumpPower        = 50,
    Fly              = false,
    FlySpeed         = 50,
    InfiniteJump     = false,
    DoubleJump       = false,
    ShiftRun         = false,
    ShiftRunSpeed    = 28,
    Noclip           = false,
    Float            = false,
    TwoLives         = false,
    -- Survival
    AutoDodgeKnives  = false,
    AntiFling        = false,
    AntiVoid         = false,
    -- World
    FPSBoost         = false,
    Headless         = false,
    XrayEnabled      = false,
    XrayTransparency = 0.75,
    AutoDeleteBody   = false,
    DisableTrap      = false,
    -- Combat Misc
    Hitbox     = false,
    HitboxSize = 5,
    AimLock    = false,
    AutoDodge  = false,
    -- Chat
    SeeDeadChat = false,
    SpamChat    = false,
    SpamText    = "hi",
    SpamDelay   = 0.25,
    -- Anti
    AntiKick = false,
    AntiAFK  = false,
    -- Farm
    AutoFarm          = false,
    FarmCoinType      = "Coin",
    FarmSpeedMethod   = "Automatic",
    ManualFarmSpeed   = 3,
    FastFarm          = false,
    StealthFarm       = false,
    FarmDoneTP        = "Map",
    KillAllWhenDone   = false,
    ShootMurdWhenDone = false,
    ResetWhenDone     = false,
    PreviousCoin      = nil,
    NoReplicateCoin   = 0,
    FarmSTOP          = true,
    CurrentTween      = nil,
    Elapse            = {s=0, m=0, h=0, d=0},
    CoinBag           = 0,
    EggBag            = 0,
}

-- ============ TASKS ============
local Tasks = {}
local function MakeTask(id, signal, cb)
    if Tasks[id] then pcall(function() Tasks[id]:Disconnect() end) end
    Tasks[id] = signal:Connect(cb)
end
local function RemoveTask(id)
    if Tasks[id] then
        pcall(function() Tasks[id]:Disconnect() end)
        Tasks[id] = nil
    end
end

-- ============ UTILITIES ============
local function Notify(msg, dur)
    pcall(function()
        Fluent:Notify({ Title = "MM2 Script", Content = tostring(msg), Duration = dur or 5 })
    end)
end

local function GetRoot(player)
    if player and player.Character then
        return player.Character:FindFirstChild("HumanoidRootPart")
            or player.Character:FindFirstChild("PrimaryPart")
    end
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local data = State.Roles[player.Name]
    if data then
        return not data.Dead and not data.Killed
    end
    -- fallback: check humanoid
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function RoleColor(player)
    if not player then return Color3.fromRGB(120,200,120) end
    local data = State.Roles[player.Name]
    if not data then return Color3.fromRGB(120,200,120) end
    local role = data.Role or "Innocent"
    if role == "Murderer"                 then return Color3.fromRGB(255, 30,  30)
    elseif role == "Sheriff" or role == "Hero" then return Color3.fromRGB(30,  80,  255)
    elseif role == "Innocent"             then return Color3.fromRGB(30,  200, 30)
    else                                       return Color3.fromRGB(120, 200, 120) end
end

local function MoveTo(cf)
    local root = GetRoot(LP)
    if root then
        root.CFrame = cf
        if LP.Character and LP.Character.PrimaryPart then
            LP.Character:SetPrimaryPartCFrame(cf)
        end
    end
end

local function GetKnife()
    for _, t in pairs(LP.Character and LP.Character:GetChildren() or {}) do
        if t.Name == "Knife" and t:IsA("Tool") then return t end
    end
    for _, t in pairs(LP.Backpack:GetChildren()) do
        if t.Name == "Knife" and t:IsA("Tool") then
            t.Parent = LP.Character
            return t
        end
    end
end

local function GetGun()
    for _, t in pairs(LP.Character and LP.Character:GetChildren() or {}) do
        if t.Name == "Gun" and t:IsA("Tool") then return t, false end
    end
    for _, t in pairs(LP.Backpack:GetChildren()) do
        if t.Name == "Gun" and t:IsA("Tool") then
            t.Parent = LP.Character
            return t, true
        end
    end
    return nil, false
end

-- Returns the sheriff's gun tool (not equipping to our char)
local function GetSheriffGun()
    local sheriff = Players:FindFirstChild(State.Sheriff)
    if not sheriff then return end
    for _, t in pairs(sheriff.Character and sheriff.Character:GetChildren() or {}) do
        if t.Name == "Gun" and t:IsA("Tool") then return t end
    end
    for _, t in pairs(sheriff.Backpack:GetChildren()) do
        if t.Name == "Gun" and t:IsA("Tool") then return t end
    end
end

-- ============ GUN SHOOT FUNCTIONS ============
-- Spy confirmed the gun call format is:
--   Gun.Shoot:FireServer(shooterCFrame, CFrame.new(targetPos))
-- arg[1] = shooter CFrame (we use HumanoidRootPart.CFrame or Camera.CFrame)
-- arg[2] = target position as CFrame
-- No capture needed — we know the format and build it fresh every shot.

-- Get the Shoot RemoteEvent from any gun tool (ours or sheriff's)
local function FindShootRemote(gunTool)
    if not gunTool then return nil end
    local direct = gunTool:FindFirstChild("Shoot")
    if direct and direct:IsA("RemoteEvent") then return direct end
    for _, d in ipairs(gunTool:GetDescendants()) do
        if d:IsA("RemoteEvent") then return d end
    end
    return nil
end

-- Fire our gun at a world position using the confirmed format
local function FireGunAt(targetPos)
    local gun = GetGun()
    if not gun then return false, "nogun" end
    local remote = FindShootRemote(gun)
    if not remote then return false, "noremote" end
    local root = GetRoot(LP)
    local shooterCF = root and root.CFrame or Camera.CFrame
    local ok, err = pcall(function()
        remote:FireServer(shooterCF, CFrame.new(targetPos))
    end)
    return ok, tostring(err)
end

local function GetClosestPlayer()
    local closest, best = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local ok, d = pcall(function()
                return (GetRoot(p).Position - GetRoot(LP).Position).Magnitude
            end)
            if ok and d < best then closest = p; best = d end
        end
    end
    return closest
end

local function GetClosestToMouse()
    local closest, best = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local ok, d = pcall(function()
                return (GetRoot(p).Position - Mouse.Hit.Position).Magnitude
            end)
            if ok and d < best then closest = p; best = d end
        end
    end
    return closest
end

local function KillPlayer(target, knife)
    local root = GetRoot(target)
    if not root or not knife then return end
    pcall(function() knife.Stab:FireServer("Down") end)
    task.wait()
    pcall(function()
        firetouchinterest(root, knife.Handle, 0)
        firetouchinterest(root, knife.Handle, 1)
    end)
end

-- ============ REMOTES (safe fetch) ============
local function WFC(parent, name, timeout)
    timeout = timeout or 5
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout)
    end)
    return ok and result or nil
end

local RS_Remotes = WFC(ReplicatedStorage, "Remotes", 10)
local RS_UpdatePD = WFC(ReplicatedStorage, "UpdatePlayerData", 10)

local R_Extras   = RS_Remotes and WFC(RS_Remotes, "Extras", 5)
local R_Gameplay = RS_Remotes and WFC(RS_Remotes, "Gameplay", 5)

local Remote_GetTimer  = R_Extras   and WFC(R_Extras, "GetTimer", 5)
local Remote_GetChance = R_Extras   and WFC(R_Extras, "GetChance", 5)
local Remote_GetData2  = R_Extras   and WFC(R_Extras, "GetData2", 5)
local Remote_Fade      = R_Gameplay and WFC(R_Gameplay, "Fade", 5)
local Remote_RoundEnd  = R_Gameplay and WFC(R_Gameplay, "RoundEndFade", 5)

-- ============ ESP SYSTEM ============
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "MM2Script_ESP"
ESPFolder.Parent = workspace

-- Name ESP (Drawing)
local NameESPConns = {}
local NameESPObjs  = {}

local function CreateNameESP(player)
    if NameESPObjs[player.Name] then return end
    local txt = Drawing.new("Text")
    txt.Text    = player.Name
    txt.Size    = 16
    txt.Font    = 3
    txt.Outline = true
    txt.OutlineColor = Color3.fromRGB(0,0,0)
    txt.Center  = true
    txt.Transparency = 1
    txt.Visible = false
    NameESPObjs[player.Name] = txt

    NameESPConns[player.Name] = RunService.RenderStepped:Connect(function()
        if not State.ESP then txt.Visible = false; return end
        if player and player.Character then
            local root = GetRoot(player)
            if root then
                local pos, vis = Camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, 3.5, 0)).Position)
                local data = State.Roles[player.Name]
                local role = data and data.Role or ""
                txt.Text    = player.Name .. (role ~= "" and ("\n["..role.."]") or "")
                txt.Color   = RoleColor(player)
                txt.Position = Vector2.new(pos.X, pos.Y - 18)
                txt.Visible  = vis
            else
                txt.Visible = false
            end
        else
            txt.Visible = false
        end
    end)
end

local function RemoveNameESP(player)
    if NameESPConns[player.Name] then
        NameESPConns[player.Name]:Disconnect()
        NameESPConns[player.Name] = nil
    end
    if NameESPObjs[player.Name] then
        NameESPObjs[player.Name]:Remove()
        NameESPObjs[player.Name] = nil
    end
end

-- Box Outline ESP (Drawing Lines)
local BoxESPConns = {}
local BoxESPObjs  = {}

local function CreateBoxESP(player)
    if BoxESPObjs[player.Name] then return end
    local lines = {}
    for i = 1, 4 do
        local ln = Drawing.new("Line")
        ln.Thickness = 1.5
        ln.Transparency = 1
        ln.Visible = false
        lines[i] = ln
    end
    BoxESPObjs[player.Name] = lines

    BoxESPConns[player.Name] = RunService.RenderStepped:Connect(function()
        if not State.ESPOutline then
            for _, l in ipairs(lines) do l.Visible = false end
            return
        end
        if player and player.Character then
            local root = GetRoot(player)
            if root then
                local cf   = CFrame.lookAt(root.Position, Camera.CFrame.Position)
                local sx, sy = 2.5, 4.0
                local tl, tlv = Camera:WorldToViewportPoint((cf * CFrame.new(-sx,  sy, 0)).Position)
                local tr, _   = Camera:WorldToViewportPoint((cf * CFrame.new( sx,  sy, 0)).Position)
                local bl, _   = Camera:WorldToViewportPoint((cf * CFrame.new(-sx, -sy, 0)).Position)
                local br, _   = Camera:WorldToViewportPoint((cf * CFrame.new( sx, -sy, 0)).Position)
                local col = RoleColor(player)
                -- Top, Bottom, Left, Right
                lines[1].From = Vector2.new(tl.X,tl.Y); lines[1].To = Vector2.new(tr.X,tr.Y)
                lines[2].From = Vector2.new(bl.X,bl.Y); lines[2].To = Vector2.new(br.X,br.Y)
                lines[3].From = Vector2.new(tl.X,tl.Y); lines[3].To = Vector2.new(bl.X,bl.Y)
                lines[4].From = Vector2.new(tr.X,tr.Y); lines[4].To = Vector2.new(br.X,br.Y)
                for _, l in ipairs(lines) do l.Color = col; l.Visible = tlv end
            else
                for _, l in ipairs(lines) do l.Visible = false end
            end
        else
            for _, l in ipairs(lines) do l.Visible = false end
        end
    end)
end

local function RemoveBoxESP(player)
    if BoxESPConns[player.Name] then
        BoxESPConns[player.Name]:Disconnect()
        BoxESPConns[player.Name] = nil
    end
    if BoxESPObjs[player.Name] then
        for _, l in ipairs(BoxESPObjs[player.Name]) do pcall(function() l:Remove() end) end
        BoxESPObjs[player.Name] = nil
    end
end

-- Chams (BoxHandleAdornment)
local function CreateCham(player)
    if not player.Character then return end
    local folder = ESPFolder:FindFirstChild(player.Name)
    if folder then folder:Destroy() end
    folder = Instance.new("Folder")
    folder.Name = player.Name
    folder.Parent = ESPFolder
    for _, part in pairs(player.Character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local adorn = Instance.new("BoxHandleAdornment")
            adorn.Name   = part.Name
            adorn.Parent = folder
            adorn.Adornee = part
            adorn.Size   = part.Size + Vector3.new(0.05, 0.05, 0.05)
            adorn.Color3 = RoleColor(player)
            adorn.AlwaysOnTop = true
            adorn.Transparency = 0.5
            adorn.ZIndex = 5
        end
    end
end

local function RemoveCham(player)
    local folder = ESPFolder:FindFirstChild(player.Name)
    if folder then folder:Destroy() end
end

local function UpdateChamColors()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            local folder = ESPFolder:FindFirstChild(p.Name)
            if folder then
                for _, adorn in pairs(folder:GetChildren()) do
                    if adorn:IsA("BoxHandleAdornment") then
                        adorn.Color3 = RoleColor(p)
                    end
                end
            end
        end
    end
end

-- ESP for players joining/leaving
Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    p.CharacterAdded:Connect(function()
        task.wait(1.5)
        if State.ESP        then CreateNameESP(p) end
        if State.ESPOutline then CreateBoxESP(p)  end
        if State.ESPCham    then CreateCham(p)    end
    end)
end)
Players.PlayerRemoving:Connect(function(p)
    RemoveNameESP(p)
    RemoveBoxESP(p)
    RemoveCham(p)
end)

-- ============ ROUND TIMER ============
local TimerLabel = Instance.new("ScreenGui")
TimerLabel.Name = "MM2ScriptTimer"
TimerLabel.ResetOnSpawn = false
TimerLabel.Parent = LP.PlayerGui

local TimerFrame = Instance.new("Frame")
TimerFrame.Parent = TimerLabel
TimerFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
TimerFrame.BackgroundTransparency = 0.4
TimerFrame.BorderSizePixel = 0
TimerFrame.AnchorPoint = Vector2.new(0.5, 0)
TimerFrame.Position = UDim2.new(0.5, 0, 0.03, 0)
TimerFrame.Size = UDim2.new(0, 120, 0, 36)
TimerFrame.Visible = false

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = TimerFrame

local TimerText = Instance.new("TextLabel")
TimerText.Parent = TimerFrame
TimerText.BackgroundTransparency = 1
TimerText.Size = UDim2.new(1, 0, 1, 0)
TimerText.Font = Enum.Font.GothamBold
TimerText.TextSize = 18
TimerText.TextColor3 = Color3.fromRGB(255,255,255)
TimerText.Text = "0s"
TimerText.TextStrokeTransparency = 0.5
TimerText.ZIndex = 10

-- Timer coroutine
coroutine.wrap(function()
    while true do
        task.wait(1)
        if State.ShowTimer and Remote_GetTimer then
            local ok, t = pcall(function()
                return Remote_GetTimer:InvokeServer()
            end)
            if ok and type(t) == "number" and t > 0 then
                local mins = math.floor(t / 60)
                local secs = math.floor(t % 60)
                TimerText.Text = (mins > 0 and (mins.."m ") or "") .. secs .. "s"
                TimerText.TextColor3 = (t <= 30) and Color3.fromRGB(255,80,80) or Color3.fromRGB(255,255,255)
                TimerFrame.Visible = true
            else
                TimerFrame.Visible = false
            end
        else
            TimerFrame.Visible = false
        end
    end
end)()

-- ============ ROLE EVENT (Fade) ============
if Remote_Fade then
    Remote_Fade.OnClientEvent:Connect(function(roleData)
        if type(roleData) ~= "table" then return end
        State.Roles    = roleData
        State.Murderer = ""
        State.Sheriff  = ""

        for name, data in pairs(roleData) do
            if type(data) == "table" then
                if data.Role == "Murderer" then
                    State.Murderer = name
                elseif data.Role == "Sheriff" or data.Role == "Hero" then
                    State.Sheriff = name
                end
            end
        end

        local myData = roleData[LP.Name]
        State.MyRole = myData and myData.Role or "Innocent"

        -- Role notification
        if State.NotifyRole then
            task.wait(0.3)
            local msg = "Your Role: " .. State.MyRole
            if State.Murderer ~= "" then
                msg = msg .. "\nMurderer: " .. State.Murderer
            end
            if State.Sheriff ~= "" then
                msg = msg .. "\nSheriff: " .. State.Sheriff
            end
            Notify(msg, 8)
        end

        -- Auto notify murderer perk
        if State.AutoNotifyPerk and State.Murderer ~= "" then
            local mdata = roleData[State.Murderer]
            if mdata and mdata.Effect then
                Notify("Murderer Perk: " .. tostring(mdata.Effect), 6)
            end
        end

        -- Update cham colors since roles changed
        UpdateChamColors()
    end)
end

-- Round end reset
if Remote_RoundEnd then
    Remote_RoundEnd.OnClientEvent:Connect(function()
        State.Roles    = {}
        State.Murderer = ""
        State.Sheriff  = ""
        State.MyRole   = "Innocent"
    end)
end

-- ============ NAMECALL HOOK ============
-- TWO things in one hook:
--  1. SILENT AIM — intercepts Gun.Shoot:FireServer and redirects arg[2] (target CFrame)
--                  toward the murderer when Sheriff Silent Aim is enabled
--  2. MURDERER KNIFE SILENT AIM — intercepts Throw:FireServer
--  3. ANTI-KICK — blocks Kick on our player
pcall(function()
    local mt   = getrawmetatable(game)
    local _old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if checkcaller() then return _old(self, ...) end

        local args = { ... }

        if method == "FireServer" then

            -- ── SHERIFF SILENT AIM ──
            -- Gun.Shoot:FireServer(shooterCF, targetCF)
            -- We intercept when self.Name == "Shoot" and it lives inside our Gun tool.
            -- arg[1] = shooter CFrame (leave untouched)
            -- arg[2] = target CFrame  (replace with predicted murderer CFrame)
            if self.Name == "Shoot" and not State.ShootingMurderer then
                -- Confirm this Shoot remote belongs to our Gun
                local parent = self.Parent
                local isOurGun = parent and parent.Name == "Gun"
                    and (parent.Parent == LP.Character or parent.Parent == LP.Backpack)
                if isOurGun and State.SheriffSilentAim then
                    local murderer = Players:FindFirstChild(State.Murderer)
                    if murderer and murderer.Character then
                        local targetPart = State.SharpShooter
                            and (murderer.Character.PrimaryPart
                                or murderer.Character:FindFirstChild("HumanoidRootPart"))
                            or murderer.Character:FindFirstChild("HumanoidRootPart")
                        if targetPart then
                            local acc = State.SilentAimMethod
                            local aimPos
                            if acc == "Seismic" then
                                local vel = targetPart.AssemblyLinearVelocity
                                if vel.Magnitude < 0.1 then
                                    aimPos = targetPart.Position
                                else
                                    local v  = vel / 16.5
                                    local vy = math.clamp(v.Y, -2, 2.65)
                                    aimPos = targetPart.Position + Vector3.new(v.X, vy, v.Z / 1.25)
                                end
                            elseif acc == "Dynamic" then
                                local hum = murderer.Character:FindFirstChildOfClass("Humanoid")
                                aimPos = targetPart.Position + (hum and hum.MoveDirection or Vector3.zero)
                            else
                                aimPos = targetPart.Position
                            end
                            -- Keep arg[1] (shooter CFrame) untouched, replace arg[2]
                            args[2] = CFrame.new(aimPos)
                            return _old(self, table.unpack(args))
                        end
                    end
                end
            end

            -- ── MURDERER SILENT AIM (knife throw) ──
            if self.Name == "Throw" and State.MurdSilentAim then
                local target = (State.MurdTarget == "Closest")
                    and GetClosestPlayer()
                    or GetClosestToMouse()
                if target and target.Character then
                    local root = target.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local vel = root.AssemblyLinearVelocity / 3
                        args[1] = CFrame.new(
                            root.Position + Vector3.new(vel.X, vel.Y / 1.5, vel.Z)
                        )
                        return _old(self, table.unpack(args))
                    end
                end
            end

        elseif method == "Kick" then
            if self == LP and State.AntiKick then return end
        end

        return _old(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ============ FLUENT WINDOW ============
local Window = Fluent:CreateWindow({
    Title     = "MM2 Script",
    SubTitle  = "ESP · Combat · Gun · Roles",
    TabWidth  = 145,
    Size      = UDim2.fromOffset(560, 480),
    Acrylic   = false, -- KEEP false for mobile compatibility
    Theme     = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals",  Icon = "eye"       }),
    Game    = Window:AddTab({ Title = "Game",     Icon = "clock"     }),
    Sheriff = Window:AddTab({ Title = "Sheriff",  Icon = "shield"    }),
    Murderer= Window:AddTab({ Title = "Murderer", Icon = "swords"    }),
    Gun     = Window:AddTab({ Title = "Gun",      Icon = "crosshair" }),
    Farm    = Window:AddTab({ Title = "Farm",     Icon = "leaf"      }),
    Teleport= Window:AddTab({ Title = "Teleport", Icon = "map-pin"   }),
    Misc    = Window:AddTab({ Title = "Misc",     Icon = "settings"  }),
    Settings= Window:AddTab({ Title = "Settings", Icon = "info"      }),
}

-- ================================================================
-- VISUALS TAB
-- ================================================================
Tabs.Visuals:AddParagraph({
    Title = "ESP Colors",
    Content = "Red = Murderer  |  Blue = Sheriff/Hero  |  Green = Innocent"
})

Tabs.Visuals:AddToggle("NameESP", {
    Title   = "Name ESP",
    Default = false,
    Callback = function(v)
        State.ESP = v
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                if v then CreateNameESP(p) else RemoveNameESP(p) end
            end
        end
    end
})

Tabs.Visuals:AddToggle("BoxESP", {
    Title   = "Box Outline ESP",
    Default = false,
    Callback = function(v)
        State.ESPOutline = v
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP then
                if v then CreateBoxESP(p) else RemoveBoxESP(p) end
            end
        end
    end
})

Tabs.Visuals:AddToggle("ChamESP", {
    Title   = "Chams (See through walls)",
    Default = false,
    Callback = function(v)
        State.ESPCham = v
        if v then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP then
                    CreateCham(p)
                    p.CharacterAdded:Connect(function()
                        task.wait(1.5)
                        if State.ESPCham then CreateCham(p) end
                    end)
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do RemoveCham(p) end
        end
    end
})

-- ── Coin / Dropped Gun Visual ──
Tabs.Visuals:AddParagraph({ Title = "Coins & Dropped Gun", Content = "Visual helpers for farming and gun pickup" })

Tabs.Visuals:AddToggle("ChamCoins", {
    Title   = "Chams on Coins",
    Default = false,
    Callback = function(v)
        State.ChamCoins = v
        if v then
            MakeTask("ChamCoinsLoop", RunService.RenderStepped, function()
                local map = workspace:FindFirstChild("Normal")
                if map and map:FindFirstChild("CoinContainer") then
                    for _, coin in pairs(map.CoinContainer:GetChildren()) do
                        if coin.Name == "Coin_Server" and not coin:FindFirstChild("MM2Cham") then
                            local vis = coin:FindFirstChild("CoinVisual")
                            if vis then
                                local adorn = Instance.new("BoxHandleAdornment")
                                adorn.Name = "MM2Cham"
                                adorn.Parent = coin
                                adorn.Adornee = coin
                                adorn.Size = Vector3.new(1.5, 1.5, 1.5)
                                adorn.Color3 = Color3.fromRGB(0, 255, 100)
                                adorn.AlwaysOnTop = true
                                adorn.Transparency = 0.45
                                adorn.ZIndex = 10
                            end
                        end
                    end
                end
            end)
        else
            RemoveTask("ChamCoinsLoop")
            local map = workspace:FindFirstChild("Normal")
            if map and map:FindFirstChild("CoinContainer") then
                for _, coin in pairs(map.CoinContainer:GetChildren()) do
                    local c = coin:FindFirstChild("MM2Cham")
                    if c then c:Destroy() end
                end
            end
        end
    end
})

Tabs.Visuals:AddToggle("ESPCoins", {
    Title   = "ESP Labels on Coins",
    Default = false,
    Callback = function(v)
        State.ESPCoins = v
        if v then
            MakeTask("ESPCoinsLoop", RunService.RenderStepped, function()
                local map = workspace:FindFirstChild("Normal")
                if map and map:FindFirstChild("CoinContainer") then
                    for _, coin in pairs(map.CoinContainer:GetChildren()) do
                        if coin.Name == "Coin_Server" and not coin:FindFirstChild("MM2ESP") then
                            local vis = coin:FindFirstChild("CoinVisual")
                            if vis then
                                local bb = Instance.new("BillboardGui")
                                local lbl = Instance.new("TextLabel")
                                bb.Name = "MM2ESP"
                                bb.Parent = coin
                                bb.AlwaysOnTop = true
                                bb.ExtentsOffset = Vector3.new(0, 5.5, 0)
                                bb.Size = UDim2.new(0, 150, 0, 40)
                                lbl.Parent = bb
                                lbl.BackgroundTransparency = 1
                                lbl.Size = UDim2.new(1,0,1,0)
                                lbl.Font = Enum.Font.GothamBold
                                lbl.TextSize = 13
                                lbl.TextColor3 = Color3.fromRGB(0, 255, 100)
                                lbl.Text = vis.ClassName ~= "MeshPart" and "Coin" or "Egg"
                            end
                        end
                    end
                end
            end)
        else
            RemoveTask("ESPCoinsLoop")
            local map = workspace:FindFirstChild("Normal")
            if map and map:FindFirstChild("CoinContainer") then
                for _, coin in pairs(map.CoinContainer:GetChildren()) do
                    local e = coin:FindFirstChild("MM2ESP")
                    if e then e:Destroy() end
                end
            end
        end
    end
})

Tabs.Visuals:AddToggle("ChamDroppedGun", {
    Title   = "Cham on Dropped Gun",
    Default = false,
    Callback = function(v)
        State.ChamDroppedGun = v
        local function AddGunCham(part)
            if not part:FindFirstChild("MM2GunCham") then
                local a = Instance.new("BoxHandleAdornment")
                a.Name = "MM2GunCham"
                a.Parent = part
                a.Adornee = part
                a.Size = part.Size
                a.Color3 = Color3.fromRGB(30, 80, 255)
                a.AlwaysOnTop = true
                a.Transparency = 0.45
                a.ZIndex = 10
            end
        end
        if v then
            local drop = workspace:FindFirstChild("GunDrop")
            if drop then AddGunCham(drop) end
            MakeTask("ChamDroppedGunAdded", workspace.ChildAdded, function(c)
                if c.Name == "GunDrop" then AddGunCham(c) end
            end)
        else
            RemoveTask("ChamDroppedGunAdded")
            local drop = workspace:FindFirstChild("GunDrop")
            if drop then
                local c = drop:FindFirstChild("MM2GunCham")
                if c then c:Destroy() end
            end
        end
    end
})

Tabs.Visuals:AddToggle("ESPDroppedGun", {
    Title   = "ESP Label on Dropped Gun",
    Default = false,
    Callback = function(v)
        State.ESPDroppedGun = v
        local function AddGunESP(part)
            if not part:FindFirstChild("MM2GunESP") then
                local bb  = Instance.new("BillboardGui")
                local lbl = Instance.new("TextLabel")
                bb.Name = "MM2GunESP"
                bb.Parent = part
                bb.AlwaysOnTop = true
                bb.ExtentsOffset = Vector3.new(0, 5.5, 0)
                bb.Size = UDim2.new(0, 150, 0, 40)
                lbl.Parent = bb
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 14
                lbl.TextColor3 = Color3.fromRGB(30, 80, 255)
                lbl.Text = "Dropped Gun"
            end
        end
        if v then
            local drop = workspace:FindFirstChild("GunDrop")
            if drop then AddGunESP(drop) end
            MakeTask("ESPDroppedGunAdded", workspace.ChildAdded, function(c)
                if c.Name == "GunDrop" then AddGunESP(c) end
            end)
            MakeTask("ESPDroppedGunRemoved", workspace.ChildRemoved, function(c)
                if c.Name == "GunDrop" then
                    local e = c:FindFirstChild("MM2GunESP")
                    if e then e:Destroy() end
                end
            end)
        else
            RemoveTask("ESPDroppedGunAdded")
            RemoveTask("ESPDroppedGunRemoved")
            local drop = workspace:FindFirstChild("GunDrop")
            if drop then
                local e = drop:FindFirstChild("MM2GunESP")
                if e then e:Destroy() end
            end
        end
    end
})

-- ================================================================
-- GAME TAB
-- ================================================================
Tabs.Game:AddParagraph({
    Title = "Round Info",
    Content = "Role detection and round notifications"
})

Tabs.Game:AddToggle("RoundTimer", {
    Title   = "Show Round Timer",
    Default = false,
    Callback = function(v)
        State.ShowTimer = v
        if not v then TimerFrame.Visible = false end
    end
})

Tabs.Game:AddButton({
    Title = "Get Murderer Chance",
    Description = "Shows your % chance of being murderer next round",
    Callback = function()
        if not Remote_GetChance then Notify("GetChance remote not found"); return end
        local ok, chance = pcall(function() return Remote_GetChance:InvokeServer() end)
        if ok then
            Notify("Murderer Chance: " .. tostring(chance) .. "%")
        else
            Notify("Failed to get chance")
        end
    end
})

Tabs.Game:AddToggle("NotifyRole", {
    Title   = "Auto Notify Role on Round Start",
    Default = false,
    Callback = function(v)
        State.NotifyRole = v
    end
})

Tabs.Game:AddButton({
    Title = "Notify Murderer's Perk (Manual)",
    Description = "Tells you what perk the murderer is using right now",
    Callback = function()
        if State.Murderer == "" then Notify("No murderer detected"); return end
        local mdata = State.Roles[State.Murderer]
        if mdata and mdata.Effect and mdata.Effect ~= "" then
            Notify("Murderer: " .. State.Murderer .. "\nPerk: " .. tostring(mdata.Effect))
        else
            Notify("Murderer perk data not available yet")
        end
    end
})

Tabs.Game:AddToggle("AutoNotifyPerk", {
    Title   = "Auto Notify Murderer's Perk",
    Description = "Notifies you when a round starts with murderer's perk",
    Default = false,
    Callback = function(v)
        State.AutoNotifyPerk = v
    end
})

Tabs.Game:AddParagraph({ Title = "", Content = "" })

Tabs.Game:AddButton({
    Title = "Who is Murderer?",
    Callback = function()
        Notify(State.Murderer ~= "" and ("Murderer: " .. State.Murderer) or "No murderer assigned yet")
    end
})

Tabs.Game:AddButton({
    Title = "Who is Sheriff?",
    Callback = function()
        Notify(State.Sheriff ~= "" and ("Sheriff: " .. State.Sheriff) or "No sheriff assigned yet")
    end
})

Tabs.Game:AddButton({
    Title = "My Role?",
    Callback = function()
        Notify("Your Role: " .. State.MyRole)
    end
})

-- ================================================================
-- SHERIFF TAB (Silent Aim, Shoot Murderer)
-- ================================================================
Tabs.Sheriff:AddParagraph({
    Title = "Sheriff Silent Aim",
    Content = "When enabled, every shot you fire automatically redirects to the murderer.\nDynamic = best all-round | Regular = still targets | Seismic = sprinting"
})

Tabs.Sheriff:AddToggle("SheriffSA", {
    Title   = "Sheriff Silent Aim",
    Default = false,
    Callback = function(v)
        State.SheriffSilentAim = v
        Notify(v and "Silent Aim ON" or "Silent Aim OFF")
    end
})

Tabs.Sheriff:AddToggle("SharpShooter", {
    Title   = "Sharp Shooter",
    Description = "Aims at PrimaryPart instead of HumanoidRootPart (slightly more accurate)",
    Default = false,
    Callback = function(v)
        State.SharpShooter = v
    end
})

Tabs.Sheriff:AddDropdown("SilentAimMethod", {
    Title   = "Silent Aim Method",
    Values  = { "Dynamic", "Regular", "Seismic" },
    Default = 1,
    Callback = function(v)
        State.SilentAimMethod = v
        Notify("Method: " .. v)
    end
})

Tabs.Sheriff:AddParagraph({ Title = "", Content = "" })

-- Computes predicted aim position using selected method
local function ComputeMurdererAimPos(murderer)
    local mroot = GetRoot(murderer)
    if not mroot then return nil end
    local targetPart = State.SharpShooter
        and (murderer.Character.PrimaryPart or mroot)
        or mroot
    local hum = murderer.Character:FindFirstChildOfClass("Humanoid")
    local acc = State.SilentAimMethod
    if acc == "Seismic" then
        local vel = targetPart.AssemblyLinearVelocity
        if vel.Magnitude < 0.1 then
            return targetPart.Position
        end
        local v  = vel / 16.5
        local vy = math.clamp(v.Y, -2, 2.65)
        return targetPart.Position + Vector3.new(v.X, vy, v.Z / 1.25)
    elseif acc == "Dynamic" then
        return targetPart.Position + (hum and hum.MoveDirection or Vector3.zero)
    end
    return targetPart.Position
end

Tabs.Sheriff:AddButton({
    Title = "Shoot Murderer",
    Description = "Fires at the murderer using predicted aim position. Just works — no setup needed.",
    Callback = function()
        local murderer = Players:FindFirstChild(State.Murderer)
        if not murderer or not murderer.Character then
            Notify("No murderer found / not alive"); return
        end
        local aimPos = ComputeMurdererAimPos(murderer)
        if not aimPos then Notify("Could not compute aim position"); return end
        State.ShootingMurderer = true
        local ok, err = FireGunAt(aimPos)
        task.wait(0.05)
        State.ShootingMurderer = false
        Notify(ok and ("Fired at " .. State.Murderer .. " (" .. State.SilentAimMethod .. ")")
                   or ("Sent (err: " .. tostring(err) .. ")"))
    end
})

-- Mobile on-screen button
if isMobile then
    Tabs.Sheriff:AddToggle("ShootMurdMobileBtn", {
        Title   = "Mobile On-Screen Button: Shoot Murderer",
        Default = false,
        Callback = function(v)
            if v then
                ContextActionService:BindAction("MM2_ShootMurd",
                    function(_, state)
                        if state ~= Enum.UserInputState.Begin then return end
                        local murderer = Players:FindFirstChild(State.Murderer)
                        if not murderer or not murderer.Character then return end
                        local aimPos = ComputeMurdererAimPos(murderer)
                        if not aimPos then return end
                        State.ShootingMurderer = true
                        FireGunAt(aimPos)
                        task.wait(0.05)
                        State.ShootingMurderer = false
                    end,
                true, Enum.KeyCode.ButtonX)
                ContextActionService:SetTitle("MM2_ShootMurd", "Shoot")
                ContextActionService:SetPosition("MM2_ShootMurd", UDim2.new(1, -260, 0, -200))
            else
                ContextActionService:UnbindAction("MM2_ShootMurd")
            end
        end
    })
end

-- ================================================================
-- MURDERER TAB (Knife Aura, Kill, Silent Aim)
-- ================================================================
Tabs.Murderer:AddParagraph({
    Title = "Murderer Features",
    Content = "Most features require you to be the Murderer role"
})

Tabs.Murderer:AddToggle("MurdSilentAim", {
    Title   = "Murderer Silent Aim (Knife Throw)",
    Default = false,
    Callback = function(v)
        State.MurdSilentAim = v
    end
})

Tabs.Murderer:AddDropdown("MurdSATarget", {
    Title   = "Silent Aim Target Method",
    Values  = { "Closest", "Mouse Cursor" },
    Default = 1,
    Callback = function(v)
        State.MurdTarget = v
    end
})

Tabs.Murderer:AddToggle("KnifeAura", {
    Title   = "Knife Aura",
    Description = "Auto kills any player within range (Murderer only)",
    Default = false,
    Callback = function(v)
        State.KnifeAura = v
        if v then
            coroutine.wrap(function()
                while State.KnifeAura do
                    task.wait(0.15)
                    if State.MyRole == "Murderer" and LP.Character then
                        local knife = GetKnife()
                        if knife then
                            local myRoot = GetRoot(LP)
                            if myRoot then
                                for _, p in pairs(Players:GetPlayers()) do
                                    if p ~= LP and IsAlive(p) then
                                        local root = GetRoot(p)
                                        if root and (root.Position - myRoot.Position).Magnitude <= State.KnifeRange then
                                            KillPlayer(p, knife)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)()
        end
    end
})

Tabs.Murderer:AddSlider("KnifeRange", {
    Title   = "Knife Aura Range (studs)",
    Default = 20,
    Min     = 5,
    Max     = 60,
    Rounding = 1,
    Callback = function(v)
        State.KnifeRange = v
    end
})

Tabs.Murderer:AddButton({
    Title = "Kill Everyone",
    Description = "Kills all alive players instantly (must be Murderer)",
    Callback = function()
        if State.MyRole ~= "Murderer" then Notify("You are not the murderer!"); return end
        local knife = GetKnife()
        if not knife then Notify("No knife in inventory"); return end
        local count = 0
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and IsAlive(p) then
                KillPlayer(p, knife)
                count = count + 1
                task.wait(0.05)
            end
        end
        Notify("Killed " .. count .. " players!")
    end
})

Tabs.Murderer:AddButton({
    Title = "Kill Sheriff",
    Callback = function()
        if State.MyRole ~= "Murderer" then Notify("You are not the murderer!"); return end
        local sheriff = Players:FindFirstChild(State.Sheriff)
        if not sheriff then Notify("No sheriff found"); return end
        local knife = GetKnife()
        if not knife then Notify("No knife found"); return end
        KillPlayer(sheriff, knife)
        Notify("Attacked sheriff!")
    end
})

Tabs.Murderer:AddButton({
    Title = "Kill Nearest Player",
    Callback = function()
        if State.MyRole ~= "Murderer" then Notify("You are not the murderer!"); return end
        local knife = GetKnife()
        if not knife then Notify("No knife found"); return end
        local target = GetClosestPlayer()
        if target then
            KillPlayer(target, knife)
            Notify("Attacked " .. target.Name)
        else
            Notify("No nearby players")
        end
    end
})

-- ================================================================
-- GUN TAB (Grab Gun, Break Gun, Steal)
-- ================================================================
Tabs.Gun:AddParagraph({
    Title = "Gun Controls",
    Content = "Grab dropped guns, break or steal sheriff's gun"
})

Tabs.Gun:AddToggle("AutoGrabGun", {
    Title   = "Auto Grab Dropped Gun",
    Description = "Teleports to gun when it drops and picks it up",
    Default = false,
    Callback = function(v)
        State.AutoGrabGun = v
        if v then
            MakeTask("AutoGrabGunWatcher", workspace.ChildAdded, function(child)
                if child.Name == "GunDrop" and not State.Grabbing then
                    State.Grabbing = true
                    local myPos = GetRoot(LP) and GetRoot(LP).CFrame
                    MakeTask("GrabGunLoop", RunService.Heartbeat, function()
                        if workspace:FindFirstChild("GunDrop") then
                            local drop = workspace:FindFirstChild("GunDrop")
                            if drop then MoveTo(drop.CFrame) end
                        else
                            RemoveTask("GrabGunLoop")
                            if myPos then
                                task.wait(0.1)
                                MoveTo(myPos)
                            end
                            State.Grabbing = false
                        end
                    end)
                end
            end)
            -- Check if already dropped
            if workspace:FindFirstChild("GunDrop") and not State.Grabbing then
                State.Grabbing = true
                local myPos = GetRoot(LP) and GetRoot(LP).CFrame
                MakeTask("GrabGunLoop", RunService.Heartbeat, function()
                    if workspace:FindFirstChild("GunDrop") then
                        local drop = workspace:FindFirstChild("GunDrop")
                        if drop then MoveTo(drop.CFrame) end
                    else
                        RemoveTask("GrabGunLoop")
                        if myPos then MoveTo(myPos) end
                        State.Grabbing = false
                    end
                end)
            end
        else
            RemoveTask("AutoGrabGunWatcher")
            RemoveTask("GrabGunLoop")
            State.Grabbing = false
        end
    end
})

Tabs.Gun:AddButton({
    Title = "Break Sheriff's Gun (Once)",
    Description = "Forces sheriff's gun to misfire/break — auto-detects remote path",
    Callback = function()
        local gunTool = GetSheriffGun()
        if not gunTool then Notify("Sheriff has no gun currently"); return end
        local remote = FindShootRemote(gunTool)
        if not remote then Notify("Could not find Shoot remote in sheriff gun"); return end
        -- Send zeroed CFrames → server treats it as a shot to (0,0,0), wastes their ammo
        pcall(function()
            remote:FireServer(CFrame.new(), CFrame.new())
        end)
        Notify("Break gun attempt sent!")
    end
})

Tabs.Gun:AddToggle("AutoBreakGun", {
    Title   = "Auto Break Gun (Loop)",
    Description = "Continuously breaks sheriff's gun every frame",
    Default = false,
    Callback = function(v)
        State.AutoBreakGun = v
        if v then
            MakeTask("AutoBreakGun", RunService.Stepped, function()
                local gunTool = GetSheriffGun()
                if gunTool then
                    local remote = FindShootRemote(gunTool)
                    if remote then
                        pcall(function()
                            remote:FireServer(CFrame.new(), CFrame.new())
                        end)
                    end
                end
            end)
        else
            RemoveTask("AutoBreakGun")
        end
    end
})

-- Mobile break gun button
if isMobile then
    Tabs.Gun:AddToggle("BreakGunMobile", {
        Title   = "Mobile Button: Break Gun",
        Default = false,
        Callback = function(v)
            if v then
                ContextActionService:BindAction("MM2_BreakGun",
                    function(_, state)
                        if state ~= Enum.UserInputState.Begin then return end
                        local gunTool = GetSheriffGun()
                        if gunTool then
                            local remote = FindShootRemote(gunTool)
                            if remote then
                                pcall(function()
                                    remote:FireServer(CFrame.new(), CFrame.new())
                                end)
                            end
                        end
                    end,
                true, Enum.KeyCode.ButtonR1)
                ContextActionService:SetTitle("MM2_BreakGun", "Break Gun")
                ContextActionService:SetPosition("MM2_BreakGun", UDim2.new(1, -130, 0, -200))
            else
                ContextActionService:UnbindAction("MM2_BreakGun")
            end
        end
    })
end

Tabs.Gun:AddButton({
    Title = "Steal Sheriff's Gun (Spray Paint)",
    Description = "Requires SprayPaint toy in your inventory",
    Callback = function()
        local sheriff = Players:FindFirstChild(State.Sheriff)
        if not sheriff or not sheriff.Character then
            Notify("No sheriff found"); return
        end

        -- Find spray paint
        local spray = nil
        local sprayFromBackpack = false
        for _, t in pairs(LP.Character and LP.Character:GetChildren() or {}) do
            if t.Name == "SprayPaint" and t:IsA("Tool") then spray = t end
        end
        for _, t in pairs(LP.Backpack:GetChildren()) do
            if t.Name == "SprayPaint" and not spray and t:IsA("Tool") then
                spray = t
                spray.Parent = LP.Character
                sprayFromBackpack = true
            end
        end

        if not spray then
            Notify("You need SprayPaint toy equipped!\nGet it from your toys list.")
            return
        end

        local sheriffRoot = GetRoot(sheriff)
        if not sheriffRoot then return end

        -- Reset the sheriff (drop gun)
        pcall(function()
            spray.Remote:FireServer(0, Enum.NormalId.Right, 10, sheriffRoot, CFrame.new(0, -math.huge, 0))
        end)

        Notify("Attempting gun steal...")

        -- Wait for gun to drop
        local waited = 0
        while not workspace:FindFirstChild("GunDrop") and waited < 4 do
            task.wait(0.1)
            waited = waited + 0.1
        end

        if sprayFromBackpack and spray and spray.Parent then
            spray.Parent = LP.Backpack
        end

        if workspace:FindFirstChild("GunDrop") then
            State.Grabbing = true
            local myPos = GetRoot(LP) and GetRoot(LP).CFrame
            local grabConn
            grabConn = RunService.Heartbeat:Connect(function()
                local drop = workspace:FindFirstChild("GunDrop")
                if drop then
                    MoveTo(drop.CFrame)
                else
                    grabConn:Disconnect()
                    if myPos then MoveTo(myPos) end
                    State.Grabbing = false
                    Notify("Gun picked up!")
                end
            end)
        else
            Notify("Gun didn't drop. Make sure sheriff is alive and has gun!")
        end
    end
})

-- ================================================================
-- FARM TAB
-- ================================================================
-- Farm state
State.AutoFarm       = false
State.FarmCoinType   = "Coin"        -- "Coin", "Egg", "Coin and Egg"
State.FarmSpeedMode  = "Automatic"   -- "Automatic", "Manual"
State.ManualFarmSpeed= 3
State.FastFarm       = false
State.SafeMode       = false
State.StealthFarm    = false
State.FarmDoneTP     = "Map"         -- "Map","Lobby","Void (Safe)","Above Map"
State.FarmPrevCoin   = nil
State.FarmSTOP       = true
State.FarmCoinsCollected = 0
State.FarmEggsCollected  = 0
State.FarmStartTime  = 0

-- Helper: get the current active map
local function GetMap()
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "Normal" then return v end
    end
end

-- Helper: get nearest uncollected coin (skipping last one to avoid loop)
local function GetNearestCoin(skipCoin)
    local map = GetMap()
    if not map or not map:FindFirstChild("CoinContainer") then return nil end
    local best, bestDist = nil, math.huge
    local myPos = GetRoot(LP) and GetRoot(LP).Position or Vector3.zero
    for _, coin in pairs(map.CoinContainer:GetChildren()) do
        if coin.Name == "Coin_Server" and coin ~= skipCoin then
            local vis = coin:FindFirstChild("CoinVisual")
            if vis then
                local coinKind = vis.ClassName ~= "MeshPart" and "Coin" or "Egg"
                local wanted = (State.FarmCoinType == "Coin and Egg")
                    or (State.FarmCoinType == coinKind)
                if wanted then
                    local d = (coin.CFrame.Position - myPos).Magnitude
                    if d < bestDist then
                        bestDist = d
                        best = coin
                    end
                end
            end
        end
    end
    return best
end

-- Farm elapsed label
local FarmElapsedLabel = Tabs.Farm:AddParagraph({ Title = "Farm Stats", Content = "Idle" })
coroutine.wrap(function()
    while true do
        task.wait(1)
        if FarmElapsedLabel then
            pcall(function()
                if State.AutoFarm and State.FarmStartTime > 0 then
                    local elapsed = math.floor(tick() - State.FarmStartTime)
                    local h = math.floor(elapsed/3600)
                    local m = math.floor((elapsed%3600)/60)
                    local s = elapsed % 60
                    FarmElapsedLabel:SetContent(
                        string.format("Running: %dh %dm %ds", h, m, s) ..
                        "\nCoins: " .. State.FarmCoinsCollected ..
                        "  |  Eggs: " .. State.FarmEggsCollected
                    )
                else
                    FarmElapsedLabel:SetContent(
                        "Idle\nCoins collected: " .. State.FarmCoinsCollected ..
                        "  |  Eggs: " .. State.FarmEggsCollected
                    )
                end
            end)
        end
    end
end)()

Tabs.Farm:AddToggle("AutoFarm", {
    Title   = "Auto Farm",
    Description = "Automatically collects coins/eggs. Murderer must be alive during round.",
    Default = false,
    Callback = function(v)
        State.AutoFarm = v
        if v then
            State.FarmStartTime = tick()
            State.FarmPrevCoin  = nil
            State.FarmSTOP      = true
            coroutine.wrap(function()
                while State.AutoFarm do
                    task.wait(0.05)
                    pcall(function()
                        local murderer = Players:FindFirstChild(State.Murderer)
                        -- Only farm when murderer is alive and round is active
                        local roundActive = murderer and murderer.Character
                        if not roundActive or not IsAlive(LP) then
                            if not State.FarmSTOP then
                                State.FarmSTOP = true
                                State.FarmPrevCoin = nil
                                -- Return to safe position when done
                                local map = GetMap()
                                if State.FarmDoneTP == "Map" and map then
                                    for _, sp in pairs(map.Spawns:GetChildren()) do
                                        if sp.Name == "Spawn" or sp.Name == "PlayerSpawn" then
                                            MoveTo(CFrame.new(sp.CFrame.X, sp.CFrame.Y + 5, sp.CFrame.Z))
                                            break
                                        end
                                    end
                                elseif State.FarmDoneTP == "Lobby" then
                                    MoveTo(CFrame.new(-110, 140, 10))
                                elseif State.FarmDoneTP == "Void (Safe)" then
                                    MoveTo(CFrame.new(99999, 99999, 99999))
                                end
                                -- When Done actions
                                if State.MyRole == "Murderer" and State.KillAllWhenDone then
                                    local knife = GetKnife()
                                    if knife then
                                        for _, p in pairs(Players:GetPlayers()) do
                                            if p ~= LP then KillPlayer(p, knife) end
                                        end
                                    end
                                elseif State.MyRole == "Sheriff" and State.ShootMurdWhenDone then
                                    local murd = Players:FindFirstChild(State.Murderer)
                                    if murd and murd.Character then
                                        local aimPos = ComputeMurdererAimPos and ComputeMurdererAimPos(murd)
                                        if aimPos then
                                            local gun, fb = GetGun()
                                            State.ShootingMurderer = true
                                            FireGunAt(aimPos)
                                            task.wait(0.05)
                                            State.ShootingMurderer = false
                                            if fb and gun and gun.Parent then gun.Parent = LP.Backpack end
                                        end
                                    end
                                end
                                if State.ResetWhenDone then
                                    if LP.Character then
                                        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                                        if hum then hum.Health = 0 end
                                    end
                                end
                            end
                            return
                        end

                        local coin = GetNearestCoin(State.FarmPrevCoin)
                        if not coin then return end
                        State.FarmPrevCoin = coin
                        State.FarmSTOP     = false

                        local coinPos = coin.CFrame.Position
                        local myPos   = GetRoot(LP) and GetRoot(LP).Position or Vector3.zero
                        local dist    = (coinPos - myPos).Magnitude

                        -- Speed calculation
                        local speed
                        if State.FarmSpeedMode == "Manual" then
                            speed = State.ManualFarmSpeed
                        else
                            speed = State.FastFarm and (dist * 0.0385) or (dist * 0.0415)
                            if speed > 10 then speed = 3 end
                            if speed < 0.05 then speed = 0.05 end
                        end

                        -- Tween to coin
                        local root = GetRoot(LP)
                        if not root then return end
                        local targetCF = CFrame.new(coinPos) * CFrame.Angles(math.rad(90), 0, math.rad(90))
                        local TweenService = game:GetService("TweenService")
                        local tween = TweenService:Create(root,
                            TweenInfo.new(speed, Enum.EasingStyle.Linear),
                            { CFrame = targetCF }
                        )
                        tween:Play()
                        task.wait(speed + 0.1)

                        -- Count what we collected
                        local vis = coin:FindFirstChild("CoinVisual")
                        if vis then
                            if vis.ClassName ~= "MeshPart" then
                                State.FarmCoinsCollected = State.FarmCoinsCollected + 1
                            else
                                State.FarmEggsCollected = State.FarmEggsCollected + 1
                            end
                        end
                    end)
                end
            end)()
        else
            State.FarmSTOP = true
        end
    end
})

Tabs.Farm:AddDropdown("FarmCoinType", {
    Title   = "Collect Type",
    Values  = { "Coin", "Egg", "Coin and Egg" },
    Default = 1,
    Callback = function(v) State.FarmCoinType = v end
})

Tabs.Farm:AddDropdown("FarmSpeedMode", {
    Title   = "Farm Speed Mode",
    Values  = { "Automatic", "Manual" },
    Default = 1,
    Callback = function(v) State.FarmSpeedMode = v end
})

Tabs.Farm:AddSlider("ManualFarmSpeed", {
    Title   = "Manual Farm Speed (seconds)",
    Min = 0.1, Max = 10, Default = 3, Rounding = 1,
    Callback = function(v) State.ManualFarmSpeed = v end
})

Tabs.Farm:AddToggle("FastFarm", {
    Title   = "Fast Farm",
    Description = "Faster tween speed for short distances",
    Default = false,
    Callback = function(v) State.FastFarm = v end
})

Tabs.Farm:AddToggle("StealthFarm", {
    Title   = "Stealth When Farming",
    Description = "Activates Ghost perk stealth while farming (requires Ghost perk)",
    Default = false,
    Callback = function(v)
        State.StealthFarm = v
        pcall(function()
            ReplicatedStorage.Remotes.Gameplay.Stealth:FireServer(v)
        end)
    end
})

Tabs.Farm:AddDropdown("FarmDoneTP", {
    Title   = "Teleport When Done Farming",
    Values  = { "Map", "Lobby", "Void (Safe)", "Above Map" },
    Default = 1,
    Callback = function(v) State.FarmDoneTP = v end
})

Tabs.Farm:AddButton({
    Title = "Reset Farm Counters",
    Callback = function()
        State.FarmCoinsCollected = 0
        State.FarmEggsCollected  = 0
        State.FarmStartTime      = 0
        Notify("Farm counters reset!")
    end
})

-- ================================================================
-- TELEPORT TAB
-- ================================================================
local function TPTo(cf)
    MoveTo(cf)
end

local function GetMapSpawnCF()
    local map = GetMap()
    if map then
        for _, sp in pairs(map.Spawns:GetChildren()) do
            if sp.Name == "Spawn" or sp.Name == "PlayerSpawn" then
                return CFrame.new(sp.CFrame.X, sp.CFrame.Y + 5, sp.CFrame.Z)
            end
        end
    end
end

Tabs.Teleport:AddParagraph({ Title = "Map TPs", Content = "Teleport to various locations in the current round" })

Tabs.Teleport:AddButton({
    Title = "TP to Map (Round Spawn)",
    Callback = function()
        local cf = GetMapSpawnCF()
        if cf then TPTo(cf) else Notify("Map spawn not found") end
    end
})

Tabs.Teleport:AddButton({
    Title = "TP to Lobby",
    Callback = function()
        TPTo(CFrame.new(-110, 140, 10))
    end
})

Tabs.Teleport:AddButton({
    Title = "TP to Voting Area",
    Callback = function()
        TPTo(CFrame.new(-108, 140, 83))
    end
})

Tabs.Teleport:AddButton({
    Title = "TP to Void (Safe — no death)",
    Description = "Creates an invisible floor so you don't die",
    Callback = function()
        TPTo(CFrame.new(99999, 99999, 99999))
        if LP.Character and not LP.Character:FindFirstChild("SafeVoidFloor") then
            local floor = Instance.new("Part")
            floor.Name = "SafeVoidFloor"
            floor.Parent = LP.Character
            floor.CFrame = CFrame.new(99999, 99995, 99999)
            floor.Anchored = true
            floor.Size = Vector3.new(300, 0.1, 300)
            floor.Transparency = 0.5
            floor.CanCollide = true
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "TP to Murderer",
    Callback = function()
        local murd = Players:FindFirstChild(State.Murderer)
        if murd and murd.Character then
            local root = GetRoot(murd)
            if root then TPTo(root.CFrame) end
        else
            Notify("No murderer found / not alive")
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "TP to Sheriff",
    Callback = function()
        local sher = Players:FindFirstChild(State.Sheriff)
        if sher and sher.Character then
            local root = GetRoot(sher)
            if root then TPTo(root.CFrame) end
        else
            Notify("No sheriff found / not alive")
        end
    end
})

-- Player TP dropdown
local playerTPNames = {}
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LP then table.insert(playerTPNames, p.Name) end
end
if #playerTPNames == 0 then playerTPNames = {"(no players yet)"} end

Tabs.Teleport:AddDropdown("TPtoPlayerDropdown", {
    Title   = "TP to Player",
    Values  = playerTPNames,
    Default = 1,
    Callback = function(v)
        local target = Players:FindFirstChild(v)
        if target and target.Character then
            local root = GetRoot(target)
            if root then
                TPTo(root.CFrame * CFrame.new(0, 0, 3))
                Notify("Teleported to " .. v)
            end
        else
            Notify("Player not found or no character")
        end
    end
})

-- ================================================================
-- MISC TAB
-- ================================================================
State.Noclip         = false
State.Fly            = false
State.FlySpeed       = 50
State.Hitbox         = false
State.HitboxSize     = 5
State.AimLock        = false
State.SeeDeadChat    = false
State.SpamChat       = false
State.SpamText       = ""
State.SpamDelay      = 0.25
State.AutoDodge      = false
State.AntiAFK        = false
State.AlwaysAlive    = false

Tabs.Misc:AddParagraph({ Title = "Movement", Content = "Noclip, Fly, Speed modifiers" })

Tabs.Misc:AddToggle("NoclipToggle", {
    Title   = "Noclip",
    Default = false,
    Callback = function(v)
        State.Noclip = v
        if v then
            MakeTask("Noclip", RunService.RenderStepped, function()
                if LP.Character and State.Noclip then
                    for _, part in pairs(LP.Character:GetChildren()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            RemoveTask("Noclip")
        end
    end
})

Tabs.Misc:AddToggle("FlyToggle", {
    Title   = "Fly",
    Default = false,
    Callback = function(v)
        State.Fly = v
        if v then
            local char   = LP.Character
            if not char then return end
            local hrp    = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
            if not hrp then return end
            local hum    = char:FindFirstChildOfClass("Humanoid")
            if not hum then return end

            -- Disable humanoid states to allow free movement
            for _, s in pairs({
                Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Jumping,
                Enum.HumanoidStateType.Running,  Enum.HumanoidStateType.RunningNoPhysics,
                Enum.HumanoidStateType.Landed,   Enum.HumanoidStateType.FallingDown,
            }) do pcall(function() hum:SetStateEnabled(s, false) end) end
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
            hum.PlatformStand = true

            local bv = Instance.new("BodyVelocity")
            local bg = Instance.new("BodyGyro")
            bv.Name = "MM2FlyBV"; bv.Parent = hrp
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.zero
            bg.Name = "MM2FlyBG"; bg.Parent = hrp
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 90000
            bg.CFrame = hrp.CFrame

            MakeTask("FlyLoop", RunService.Heartbeat, function()
                if not State.Fly or not LP.Character then
                    RemoveTask("FlyLoop")
                    local bvr = hrp:FindFirstChild("MM2FlyBV")
                    local bgr = hrp:FindFirstChild("MM2FlyBG")
                    if bvr then bvr:Destroy() end
                    if bgr then bgr:Destroy() end
                    pcall(function() hum.PlatformStand = false end)
                    return
                end
                local cam = workspace.CurrentCamera
                local spd = State.FlySpeed
                local mv  = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0,1,0) end
                bv.Velocity = mv.Magnitude > 0 and (mv.Unit * spd) or Vector3.zero
                bg.CFrame = cam.CFrame
            end)
        else
            RemoveTask("FlyLoop")
            if LP.Character then
                local hrp = LP.Character:FindFirstChild("HumanoidRootPart") or LP.Character:FindFirstChild("UpperTorso")
                if hrp then
                    local bvr = hrp:FindFirstChild("MM2FlyBV")
                    local bgr = hrp:FindFirstChild("MM2FlyBG")
                    if bvr then bvr:Destroy() end
                    if bgr then bgr:Destroy() end
                end
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.PlatformStand = false
                    for _, s in pairs({
                        Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.Jumping,
                        Enum.HumanoidStateType.Running,  Enum.HumanoidStateType.RunningNoPhysics,
                        Enum.HumanoidStateType.Landed,   Enum.HumanoidStateType.FallingDown,
                    }) do pcall(function() hum:SetStateEnabled(s, true) end) end
                end
            end
        end
    end
})

Tabs.Misc:AddSlider("FlySpeedSlider", {
    Title = "Fly Speed", Min = 5, Max = 200, Default = 50, Rounding = 1,
    Callback = function(v) State.FlySpeed = v end
})

Tabs.Misc:AddParagraph({ Title = "", Content = "" })
Tabs.Misc:AddParagraph({ Title = "Combat Misc", Content = "Hitbox, Aim Lock, Auto Dodge" })

Tabs.Misc:AddToggle("HitboxToggle", {
    Title   = "Hitbox Expander",
    Default = false,
    Callback = function(v)
        State.Hitbox = v
        if v then
            MakeTask("HitboxLoop", RunService.RenderStepped, function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                            hrp.Transparency = 0.4
                            hrp.CanCollide = false
                        end
                    end
                end
            end)
        else
            RemoveTask("HitboxLoop")
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(2, 1, 1)
                        hrp.Transparency = 1
                        hrp.CanCollide = true
                    end
                end
            end
        end
    end
})

Tabs.Misc:AddSlider("HitboxSizeSlider", {
    Title = "Hitbox Size", Min = 1, Max = 30, Default = 5, Rounding = 1,
    Callback = function(v) State.HitboxSize = v end
})

Tabs.Misc:AddToggle("AimLockMurderer", {
    Title   = "Aim Lock (Camera on Murderer)",
    Description = "Camera automatically faces the murderer",
    Default = false,
    Callback = function(v)
        State.AimLock = v
        if v then
            MakeTask("AimLock", RunService.Heartbeat, function()
                local murd = Players:FindFirstChild(State.Murderer)
                if murd and murd.Character then
                    local root = GetRoot(murd)
                    if root and IsAlive(murd) then
                        workspace.CurrentCamera.CFrame = CFrame.new(
                            workspace.CurrentCamera.CFrame.Position, root.Position
                        )
                    end
                end
            end)
        else
            RemoveTask("AimLock")
        end
    end
})

Tabs.Misc:AddToggle("AutoDodge", {
    Title   = "Auto Dodge Murderer",
    Description = "Teleports away when murderer gets within 15 studs",
    Default = false,
    Callback = function(v)
        State.AutoDodge = v
        if v then
            MakeTask("AutoDodge", RunService.Heartbeat, function()
                pcall(function()
                    local murd = Players:FindFirstChild(State.Murderer)
                    if murd and murd.Character and IsAlive(murd) and IsAlive(LP) then
                        local myRoot = GetRoot(LP)
                        local mRoot  = GetRoot(murd)
                        if myRoot and mRoot then
                            local dist = (mRoot.Position - myRoot.Position).Magnitude
                            if dist <= 15 then
                                local awayDir = (myRoot.Position - mRoot.Position).Unit
                                MoveTo(CFrame.new(myRoot.Position + awayDir * 25))
                            end
                        end
                    end
                end)
            end)
        else
            RemoveTask("AutoDodge")
        end
    end
})

Tabs.Misc:AddParagraph({ Title = "", Content = "" })
Tabs.Misc:AddParagraph({ Title = "Chat & Social", Content = "Chat utilities" })

Tabs.Misc:AddToggle("SeeDeadChat", {
    Title   = "See Dead Chat",
    Description = "Shows chat from dead players in your local chat",
    Default = false,
    Callback = function(v)
        State.SeeDeadChat = v
        if v then
            local StarterGuiSvc = game:GetService("StarterGui")
            local function ShowMsg(plr, msg)
                pcall(function()
                    if not IsAlive(plr) and IsAlive(LP) then
                        StarterGuiSvc:SetCore("ChatMakeSystemMessage", {
                            Text  = "[Dead] [" .. plr.Name .. "]: " .. msg,
                            Color = Color3.fromRGB(128, 128, 128)
                        })
                    end
                end)
            end
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP then
                    MakeTask("DeadChat_" .. p.Name, p.Chatted, function(msg)
                        if State.SeeDeadChat then ShowMsg(p, msg) end
                    end)
                end
            end
            MakeTask("DeadChatAdded", Players.PlayerAdded, function(p)
                MakeTask("DeadChat_" .. p.Name, p.Chatted, function(msg)
                    if State.SeeDeadChat then ShowMsg(p, msg) end
                end)
            end)
            MakeTask("DeadChatRemoved", Players.PlayerRemoving, function(p)
                RemoveTask("DeadChat_" .. p.Name)
            end)
        else
            for _, p in pairs(Players:GetPlayers()) do
                RemoveTask("DeadChat_" .. p.Name)
            end
            RemoveTask("DeadChatAdded")
            RemoveTask("DeadChatRemoved")
        end
    end
})

Tabs.Misc:AddToggle("SpamChatToggle", {
    Title   = "Chat Spammer",
    Default = false,
    Callback = function(v)
        State.SpamChat = v
        if v then
            coroutine.wrap(function()
                while State.SpamChat do
                    task.wait(State.SpamDelay)
                    pcall(function()
                        local chatRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                            and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                        if chatRemote and State.SpamText ~= "" then
                            chatRemote:FireServer(State.SpamText, "All")
                        end
                    end)
                end
            end)()
        end
    end
})

Tabs.Misc:AddParagraph({ Title = "Chat Text & Delay", Content = "Set the message and speed for chat spam" })

Tabs.Misc:AddSlider("SpamDelay", {
    Title = "Spam Delay (seconds x0.01)", Min = 1, Max = 100, Default = 25, Rounding = 1,
    Callback = function(v) State.SpamDelay = v / 100 end
})

Tabs.Misc:AddToggle("AntiAFK", {
    Title   = "Anti AFK",
    Default = false,
    Callback = function(v)
        State.AntiAFK = v
        if v then
            MakeTask("AntiAFK", LP.Idled, function()
                if State.AntiAFK then
                    local VU = game:GetService("VirtualUser")
                    pcall(function() VU:ClickButton2(Vector2.zero) end)
                end
            end)
        else
            RemoveTask("AntiAFK")
        end
    end
})

-- ================================================================
-- MISC TAB — PLAYER MODS (WalkSpeed, JumpPower, Infinite Jump etc.)
-- ================================================================

-- These are appended after the existing Misc content above

Tabs.Misc:AddParagraph({ Title = "Player Mods", Content = "Speed, Jump, Infinite Jump, Shift Run, Double Jump, Two Lives, Float" })

Tabs.Misc:AddToggle("WalkSpeedToggle", {
    Title   = "Enable WalkSpeed",
    Default = false,
    Callback = function(v)
        State.WalkSpeedEnabled = v
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v and State.WalkSpeed or 16 end
        end
        MakeTask("WalkSpeedRespawn", LP.CharacterAdded, function(char)
            task.wait(0.3)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and State.WalkSpeedEnabled then hum.WalkSpeed = State.WalkSpeed end
        end)
    end
})

Tabs.Misc:AddSlider("WalkSpeedSlider", {
    Title = "Walk Speed", Min = 1, Max = 255, Default = 16, Rounding = 1,
    Callback = function(v)
        State.WalkSpeed = v
        if State.WalkSpeedEnabled and LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

Tabs.Misc:AddToggle("JumpPowerToggle", {
    Title   = "Enable JumpPower",
    Default = false,
    Callback = function(v)
        State.JumpPowerEnabled = v
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v and State.JumpPower or 50 end
        end
        MakeTask("JumpPowerRespawn", LP.CharacterAdded, function(char)
            task.wait(0.3)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and State.JumpPowerEnabled then hum.JumpPower = State.JumpPower end
        end)
    end
})

Tabs.Misc:AddSlider("JumpPowerSlider", {
    Title = "Jump Power", Min = 1, Max = 255, Default = 50, Rounding = 1,
    Callback = function(v)
        State.JumpPower = v
        if State.JumpPowerEnabled and LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end
    end
})

Tabs.Misc:AddToggle("InfiniteJumpToggle", {
    Title   = "Infinite Jump",
    Default = false,
    Callback = function(v)
        State.InfiniteJump = v
        if v then
            MakeTask("InfJump", game:GetService("UserInputService").JumpRequest, function()
                if State.InfiniteJump and LP.Character then
                    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        else
            RemoveTask("InfJump")
        end
    end
})

Tabs.Misc:AddToggle("DoubleJumpToggle", {
    Title   = "Double Jump",
    Description = "Allows a second jump while airborne",
    Default = false,
    Callback = function(v)
        State.DoubleJump = v
        if v then
            local lastJump = false
            if LP.Character then
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.StateChanged:Connect(function(_, new)
                        if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Jumping then
                            lastJump = false
                        end
                    end)
                end
            end
            MakeTask("DoubleJump", game:GetService("UserInputService").JumpRequest, function()
                if not State.DoubleJump then RemoveTask("DoubleJump") return end
                if not lastJump and LP.Character then
                    lastJump = true
                    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        else
            RemoveTask("DoubleJump")
        end
    end
})

Tabs.Misc:AddToggle("ShiftRunToggle", {
    Title   = "Shift Run (hold Shift to sprint)",
    Default = false,
    Callback = function(v)
        State.ShiftRun = v
        if v then
            MakeTask("ShiftRun", RunService.Heartbeat, function()
                if not LP.Character then return end
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    hum.WalkSpeed = State.ShiftRunSpeed
                else
                    hum.WalkSpeed = State.WalkSpeedEnabled and State.WalkSpeed or 16
                end
            end)
        else
            RemoveTask("ShiftRun")
            if LP.Character then
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = State.WalkSpeedEnabled and State.WalkSpeed or 16 end
            end
        end
    end
})

Tabs.Misc:AddSlider("ShiftRunSpeedSlider", {
    Title = "Sprint Speed", Min = 16, Max = 100, Default = 28, Rounding = 1,
    Callback = function(v) State.ShiftRunSpeed = v end
})

Tabs.Misc:AddToggle("TwoLivesToggle", {
    Title   = "Two Lives",
    Description = "Revives you once per round when you die (client-side, may not always work)",
    Default = false,
    Callback = function(v)
        State.TwoLives = v
        if v then
            coroutine.wrap(function()
                while State.TwoLives do
                    task.wait(0.1)
                    pcall(function()
                        if LP.Character then
                            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health <= 0 then
                                hum:ChangeState(11)
                                task.wait(2.5)
                                hum.Health = 100
                                task.wait(1)
                                hum:ChangeState(1)
                                State.TwoLives = false  -- once per round
                            end
                        end
                    end)
                end
            end)()
        end
    end
})

Tabs.Misc:AddToggle("FloatToggle", {
    Title   = "Float",
    Description = "Hovers slightly above the ground",
    Default = false,
    Callback = function(v)
        State.Float = v
        if v then
            coroutine.wrap(function()
                while State.Float do
                    task.wait()
                    pcall(function()
                        local root = GetRoot(LP)
                        if root then
                            root.CFrame = root.CFrame * CFrame.new(0, 0.5, 0)
                        end
                    end)
                end
            end)()
        end
    end
})

Tabs.Misc:AddParagraph({ Title = "", Content = "" })
Tabs.Misc:AddParagraph({ Title = "Survival", Content = "Auto Dodge Knives, Anti-Fling, Anti-Void" })

Tabs.Misc:AddToggle("AutoDodgeKnives", {
    Title   = "Auto Dodge Thrown Knives",
    Description = "Moves sideways when a thrown knife gets within 15 studs",
    Default = false,
    Callback = function(v)
        State.AutoDodgeKnives = v
        if v then
            MakeTask("AutoDodgeKnives", workspace.ChildAdded, function(obj)
                if not State.AutoDodgeKnives then return end
                if obj.Name == "ThrowingKnife" and obj:IsA("Model") and State.MyRole ~= "Murderer" then
                    coroutine.wrap(function()
                        local done = false
                        while not done and obj and obj.Parent do
                            task.wait()
                            local root = GetRoot(LP)
                            if root then
                                local ok, pivot = pcall(function() return obj:GetPivot() end)
                                if ok then
                                    local dist = (root.Position - pivot.Position).Magnitude
                                    if dist < 15 then
                                        local dx = root.Position.X - pivot.Position.X
                                        root.CFrame = root.CFrame * CFrame.new(-dx * 3, 0, 0)
                                        done = true
                                    end
                                end
                            end
                        end
                    end)()
                end
            end)
        else
            RemoveTask("AutoDodgeKnives")
        end
    end
})

Tabs.Misc:AddToggle("AntiFlingToggle", {
    Title   = "Anti-Fling",
    Description = "Resets your CFrame if you get flung far away",
    Default = false,
    Callback = function(v)
        State.AntiFling = v
        local lastGoodPos = nil
        if v then
            MakeTask("AntiFling", RunService.Heartbeat, function()
                if not State.AntiFling then return end
                local root = GetRoot(LP)
                if not root then return end
                if root.Position.Magnitude < 5000 then
                    lastGoodPos = root.CFrame
                else
                    if lastGoodPos then
                        root.CFrame = lastGoodPos
                    end
                end
            end)
        else
            RemoveTask("AntiFling")
        end
    end
})

Tabs.Misc:AddToggle("AntiVoidToggle", {
    Title   = "Anti-Void",
    Description = "Teleports you back to spawn if you fall into the void (Y < -100)",
    Default = false,
    Callback = function(v)
        State.AntiVoid = v
        if v then
            MakeTask("AntiVoid", RunService.Heartbeat, function()
                if not State.AntiVoid then return end
                local root = GetRoot(LP)
                if root and root.Position.Y < -100 then
                    -- Try to find a spawn point
                    local map = workspace:FindFirstChildWhichIsA("Folder")
                    local spawnCF = CFrame.new(0, 10, 0)
                    if map then
                        local spawns = map:FindFirstChild("Spawns")
                        if spawns then
                            for _, s in pairs(spawns:GetChildren()) do
                                if s.Name == "Spawn" or s.Name == "PlayerSpawn" then
                                    spawnCF = s.CFrame + Vector3.new(0, 5, 0)
                                    break
                                end
                            end
                        end
                    end
                    root.CFrame = spawnCF
                end
            end)
        else
            RemoveTask("AntiVoid")
        end
    end
})

Tabs.Misc:AddParagraph({ Title = "", Content = "" })
Tabs.Misc:AddParagraph({ Title = "World / Visual Tweaks", Content = "FPS Boost, X-ray, Headless, FOV" })

Tabs.Misc:AddButton({
    Title = "FPS Boost",
    Description = "Disables decals, textures, particles and hides decorative parts",
    Callback = function()
        local count = 0
        for _, obj in pairs(workspace:GetDescendants()) do
            local ok = pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                    count += 1
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 1
                    count += 1
                elseif obj:IsA("Explosion") then
                    obj.BlastPressure = 0
                end
            end)
            _ = ok -- suppress unused warning
        end
        -- Also reduce render quality
        pcall(function() settings().Rendering.QualityLevel = 1 end)
        Notify("FPS Boost applied! Cleared " .. count .. " effects")
    end
})

Tabs.Misc:AddToggle("XrayToggle", {
    Title   = "X-ray (see through map)",
    Default = false,
    Callback = function(v)
        State.XrayEnabled = v
        for _, obj in pairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart"
                   and not obj:FindFirstAncestorOfClass("Model") then
                    if v then
                        obj:SetAttribute("_xray_orig_trans", obj.Transparency)
                        obj.Transparency = State.XrayTransparency
                    else
                        local orig = obj:GetAttribute("_xray_orig_trans")
                        if orig ~= nil then obj.Transparency = orig end
                    end
                end
            end)
        end
    end
})

Tabs.Misc:AddSlider("XrayTransSlider", {
    Title = "X-ray Transparency", Min = 1, Max = 99, Default = 75, Rounding = 1,
    Callback = function(v) State.XrayTransparency = v / 100 end
})

Tabs.Misc:AddToggle("HeadlessToggle", {
    Title   = "Headless (client-side)",
    Default = false,
    Callback = function(v)
        State.Headless = v
        if LP.Character then
            local head = LP.Character:FindFirstChild("Head")
            if head then
                head.Transparency = v and 1 or 0
                for _, d in pairs(head:GetChildren()) do
                    if d:IsA("Decal") then d.Transparency = v and 1 or 0 end
                end
            end
        end
    end
})

Tabs.Misc:AddSlider("FOVSlider", {
    Title = "FOV", Min = 30, Max = 120, Default = 70, Rounding = 1,
    Callback = function(v)
        workspace.CurrentCamera.FieldOfView = v
    end
})

Tabs.Misc:AddButton({
    Title = "Reset FOV",
    Callback = function()
        workspace.CurrentCamera.FieldOfView = 70
        Notify("FOV reset to 70")
    end
})

Tabs.Misc:AddParagraph({ Title = "", Content = "" })
Tabs.Misc:AddParagraph({ Title = "Game Utilities", Content = "Auto Delete Dead Body, Disable Trap, Always Alive Chat" })

Tabs.Misc:AddToggle("AutoDeleteBody", {
    Title   = "Auto Delete Dead Body",
    Description = "Deletes the Raggy corpse model to reduce lag/clutter",
    Default = false,
    Callback = function(v)
        State.AutoDeleteBody = v
        if v then
            MakeTask("AutoDeleteBody", RunService.Stepped, function()
                if not State.AutoDeleteBody then return end
                local raggy = workspace:FindFirstChild("Raggy")
                if raggy then pcall(function() raggy:Destroy() end) end
            end)
        else
            RemoveTask("AutoDeleteBody")
        end
    end
})

Tabs.Misc:AddToggle("DisableTrapToggle", {
    Title   = "Disable Traps",
    Description = "Destroys trap models placed by other players (only affects your client)",
    Default = false,
    Callback = function(v)
        State.DisableTrap = v
        if v then
            MakeTask("DisableTrap", RunService.Stepped, function()
                if not State.DisableTrap then return end
                pcall(function()
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LP and p.Character then
                            for _, obj in pairs(p.Character:GetChildren()) do
                                if obj.Name == "Trap" and obj:IsA("Model") then
                                    obj:Destroy()
                                end
                            end
                        end
                    end
                end)
            end)
        else
            RemoveTask("DisableTrap")
        end
    end
})

Tabs.Misc:AddToggle("AlwaysAliveChatToggle", {
    Title   = "Always Alive Chat",
    Description = "Allows you to chat even when dead",
    Default = false,
    Callback = function(v)
        if v then
            pcall(function()
                local gui = LP.PlayerGui:FindFirstChild("BubbleChat") or LP.PlayerGui:FindFirstChildOfClass("ScreenGui")
                -- Enable chat buttons regardless of alive state
                LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") and
                LP.Character:FindFirstChildOfClass("Humanoid"):SetAttribute("CanChat", true)
            end)
            Notify("Always Alive Chat: ON
(Works best if you were alive when toggled)")
        end
    end
})

-- ================================================================
-- VISUALS TAB EXTRAS — Tracer ESP
-- (Appended here since it needs to reference Tracer table already existing)
-- ================================================================
Tabs.Visuals:AddParagraph({ Title = "Tracer", Content = "Lines from bottom of screen to each player" })

local TracerObjects = {}

local function CreateTracer(p)
    if TracerObjects[p.Name] then return end
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Transparency = 1
    line.Visible = false
    TracerObjects[p.Name] = {
        Line = line,
        Conn = RunService.RenderStepped:Connect(function()
            if not State.TracerESP or not p.Character then
                line.Visible = false
                return
            end
            local root = GetRoot(p)
            if not root then line.Visible = false return end
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
            if onScreen then
                line.From  = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                line.To    = Vector2.new(screenPos.X, screenPos.Y)
                line.Color = RoleColor(p)
                line.Visible = true
            else
                line.Visible = false
            end
        end)
    }
end

local function RemoveTracer(p)
    if TracerObjects[p.Name] then
        pcall(function() TracerObjects[p.Name].Line:Remove() end)
        pcall(function() TracerObjects[p.Name].Conn:Disconnect() end)
        TracerObjects[p.Name] = nil
    end
end

Tabs.Visuals:AddToggle("TracerESP", {
    Title   = "Tracer Lines",
    Default = false,
    Callback = function(v)
        State.TracerESP = v
        if v then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP then CreateTracer(p) end
            end
            MakeTask("TracerAdded",   Players.PlayerAdded,   function(p) CreateTracer(p) end)
            MakeTask("TracerRemoved", Players.PlayerRemoving, function(p) RemoveTracer(p) end)
        else
            for _, p in pairs(Players:GetPlayers()) do RemoveTracer(p) end
            RemoveTask("TracerAdded")
            RemoveTask("TracerRemoved")
        end
    end
})

-- ================================================================
-- FARM TAB EXTRAS — When Done Farming actions
-- ================================================================
Tabs.Farm:AddParagraph({ Title = "When Done Farming", Content = "Actions to perform when your coin/egg bag is full" })

Tabs.Farm:AddToggle("KillAllWhenDone", {
    Title   = "Kill Everyone (Murderer only)",
    Default = false,
    Callback = function(v) State.KillAllWhenDone = v end
})

Tabs.Farm:AddToggle("ShootMurdWhenDone", {
    Title   = "Shoot Murderer (Sheriff only)",
    Description = "Auto-fires at murderer when round ends (Sheriff only)",
    Default = false,
    Callback = function(v) State.ShootMurdWhenDone = v end
})

Tabs.Farm:AddToggle("ResetWhenDone", {
    Title   = "Reset (Die) When Done",
    Default = false,
    Callback = function(v) State.ResetWhenDone = v end
})

-- ================================================================
-- SETTINGS TAB
-- ================================================================
Tabs.Settings:AddParagraph({
    Title = "MM2 Script",
    Content = "All-in-one script — ESP, Farm, Silent Aim, Combat, Gun, Misc\nMobile + PC compatible | No premium gates"
})

Tabs.Settings:AddParagraph({
    Title = "Executor",
    Content = (pcall(identifyexecutor) and identifyexecutor() or "Unknown")
})

Tabs.Settings:AddButton({
    Title = "Reset Script State",
    Description = "Clears all toggles and resets internal state (does not re-execute)",
    Callback = function()
        -- Turn off all active loops
        local loopsToKill = {
            "Noclip","FlyLoop","HitboxLoop","AimLock","AutoDodge",
            "AutoBreakGun","AutoGrabGunWatcher","GrabGunLoop",
            "KnifeAuraLoop","AutoKillEveryone","AntiAFK",
            "ChamCoinsLoop","ESPCoinsLoop","ChamDroppedGunAdded",
            "ESPDroppedGunAdded","ESPDroppedGunRemoved"
        }
        for _, id in pairs(loopsToKill) do
            pcall(function() RemoveTask(id) end)
        end
        State.AutoFarm = false
        State.Fly = false
        State.Noclip = false
        State.Hitbox = false
        State.AimLock = false
        State.AutoDodge = false
        State.SpamChat = false
        State.AntiKick = false
        Notify("State reset!")
    end
})

Tabs.Settings:AddToggle("AntiKickSettings", {
    Title   = "Anti-Kick",
    Description = "Blocks server-side Kick calls on your player",
    Default = false,
    Callback = function(v) State.AntiKick = v end
})

Tabs.Settings:AddParagraph({
    Title = "Keybinds (PC)",
    Content = "RightControl  — Hide/Show UI\nC — Shoot Murderer (hold gun first)\nJ — Break Sheriff Gun"
})

Tabs.Settings:AddParagraph({
    Title = "How to use Gun Features",
    Content = "All gun features work automatically.\nJust pick up your gun and use Shoot Murderer or enable Silent Aim.\nNo setup or capture needed."
})
Fluent:Notify({
    Title   = "MM2 Script",
    Content = "✓ Loaded! ESP, Silent Aim, Roles, Gun all ready.\nRole info updates on round start.",
    Duration = 6
})

-- Handle any players already in game getting ESP setup
task.spawn(function()
    task.wait(0.5)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP then
            if State.ESP        then CreateNameESP(p) end
            if State.ESPOutline then CreateBoxESP(p)  end
            if State.ESPCham    then CreateCham(p)    end
            p.CharacterAdded:Connect(function()
                task.wait(1.5)
                if State.ESPCham then CreateCham(p) end
            end)
        end
    end
end)

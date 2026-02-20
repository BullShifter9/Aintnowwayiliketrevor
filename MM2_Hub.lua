-- ============================================================
--   MM2 Hub  |  Fluent UI  |  Clean Rebuild
--   Features: ESP · Box ESP · Outline · Cham · Tracer
--             Round Timer · Get Chance · Role / Perk Notify
--             Grab Gun · Auto Grab · Steal Gun
--             Combat (Sheriff Silent Aim + Murderer Section)
-- ============================================================

-- ── Services ─────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui       = game:GetService("StarterGui")

local LP     = Players.LocalPlayer
local Mouse  = LP:GetMouse()
local Camera = workspace.CurrentCamera

-- ── Remote wrappers (silent-aim needs InvokeServer) ──────────
local _cachedFireServer, _cachedInvokeServer

local function FireServer(remote, ...)
    if _cachedFireServer then
        pcall(_cachedFireServer, remote, ...)
    else
        pcall(function() remote:FireServer(...) end)
    end
end

local function InvokeServer(remote, ...)
    if _cachedInvokeServer then
        local ok, res = pcall(_cachedInvokeServer, remote, ...)
        return ok and res or nil
    else
        local ok, res = pcall(function() return remote:InvokeServer(...) end)
        return ok and res or nil
    end
end

-- Attempt to hook the real FireServer / InvokeServer via GC so
-- silent aim bypasses client-side prediction checks (same trick
-- as the original).
pcall(function()
    for _, fn in pairs(getgc and getgc() or {}) do
        if type(fn) == "function" then
            local info = debug.getinfo(fn)
            if info and info.name == "FireServer" and not _cachedFireServer then
                _cachedFireServer = fn
            elseif info and info.name == "InvokeServer" and not _cachedInvokeServer then
                _cachedInvokeServer = fn
            end
        end
    end
end)

-- ── Load Fluent UI ────────────────────────────────────────────
local Fluent         = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Fluent.lua"))()
local SaveManager    = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ── State table ──────────────────────────────────────────────
local S = {
    -- Roles
    Murderer  = "",
    Sheriff   = "",
    Hero      = false,
    MyRole    = "Innocent",
    RoleData  = {},

    -- Visuals
    ESPOn        = false,
    BoxOn        = false,
    OutlineOn    = false,
    ChamOn       = false,
    TracerOn     = false,
    ChamDropGun  = false,

    -- Combat
    SilentAimOn    = false,
    SilentAimMethod= "Dynamic",
    SharpShooter   = false,
    AutoKill       = false,
    KnifeAuraOn    = false,
    KnifeRange     = 30,

    -- Grab Gun
    IsGrabbing = false,
    AutoGrab   = false,
}

-- ── Task manager ─────────────────────────────────────────────
local Tasks = {}
local function MakeTask(id, signal, fn)
    if Tasks[id] then pcall(function() Tasks[id]:Disconnect() end) end
    Tasks[id] = signal:Connect(fn)
end
local function KillTask(id)
    if Tasks[id] then
        pcall(function() Tasks[id]:Disconnect() end)
        Tasks[id] = nil
    end
end

-- ── Drawing store ─────────────────────────────────────────────
local DrawStore = { ESP = {}, Box = {}, Tracer = {}, Outline = {} }
local ESPFolder = Instance.new("Folder")
ESPFolder.Name  = "MM2Hub_Visual"
ESPFolder.Parent= workspace

-- ── Helpers ───────────────────────────────────────────────────
local function GetRoot(player)
    return player and player.Character and
           player.Character:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local h = player.Character:FindFirstChild("Humanoid")
    return h and h.Health > 0
end

local function TpChar(player, cf)
    local root = GetRoot(player)
    if root then root.CFrame = cf end
end

local function RoleColor(role)
    if role == "Murderer" then return Color3.fromRGB(255, 60, 60)  end
    if role == "Sheriff"  then return Color3.fromRGB(80, 130, 255)  end
    if role == "Hero"     then return Color3.fromRGB(0, 255, 200)   end
    return Color3.fromRGB(100, 220, 100)
end

local function GetPlayerRole(player)
    if player.Name == S.Murderer and IsAlive(player) then
        return "Murderer", RoleColor("Murderer")
    elseif player.Name == S.Sheriff and IsAlive(player) and not S.Hero then
        return "Sheriff", RoleColor("Sheriff")
    elseif player.Name == S.Sheriff and IsAlive(player) and S.Hero then
        return "Hero", RoleColor("Hero")
    else
        return "Innocent", RoleColor("Innocent")
    end
end

local function Notify(title, text, dur)
    Fluent:Notify({ Title = title or "MM2 Hub", Content = text, Duration = dur or 5 })
end

-- ── Remote shortcuts ─────────────────────────────────────────
local Remotes   = ReplicatedStorage:WaitForChild("Remotes", 10)
local Extras    = Remotes and Remotes:FindFirstChild("Extras")
local Gameplay  = Remotes and Remotes:FindFirstChild("Gameplay")
local SayMsg    = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and
                  ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")

local function Chat(msg, chatType)
    pcall(function()
        if SayMsg then
            SayMsg:FireServer(msg, chatType or "All")
        end
    end)
end

-- ── Role data refresh ─────────────────────────────────────────
local function RefreshRoles(data)
    if type(data) ~= "table" then
        -- try to fetch fresh if nothing passed
        pcall(function()
            if Extras and Extras:FindFirstChild("GetPlayerData") then
                data = InvokeServer(Extras.GetPlayerData)
            end
        end)
    end
    if type(data) ~= "table" then return end

    S.RoleData = data
    S.MyRole   = (data[LP.Name] and data[LP.Name].Role) or "Innocent"
    S.Murderer = ""
    S.Sheriff  = ""
    S.Hero     = false

    for name, info in pairs(data) do
        if not info.Died and not info.Killed then
            if info.Role == "Murderer" then
                S.Murderer = name
            elseif info.Role == "Sheriff" then
                S.Sheriff = name
                S.Hero    = false
            elseif info.Role == "Hero" then
                S.Sheriff = name
                S.Hero    = true
            end
        end
    end
end

-- Hook round-start fade event
pcall(function()
    if Gameplay and Gameplay:FindFirstChild("Fade") then
        Gameplay.Fade.OnClientEvent:Connect(function(data)
            RefreshRoles(data)

            -- Auto-notify role on round start
            if S.Callbacks and S.Callbacks.OnRoundStart then
                for _, fn in pairs(S.Callbacks.OnRoundStart) do
                    pcall(coroutine.wrap(fn))
                end
            end
        end)
    end
end)

pcall(function()
    if ReplicatedStorage:FindFirstChild("UpdatePlayerData") then
        ReplicatedStorage.UpdatePlayerData.OnClientEvent:Connect(function()
            RefreshRoles(nil)
        end)
    end
end)

S.Callbacks = { OnRoundStart = {} }

-- Initial load
task.spawn(RefreshRoles)

-- ═══════════════════════════════════════════════════════════════
--  ██  VISUAL FUNCTIONS  ██
-- ═══════════════════════════════════════════════════════════════

-- ── ESP (Name Tag) ────────────────────────────────────────────
local function MakeESP(player)
    if DrawStore.ESP[player.Name] then return end
    local text    = Drawing.new("Text")
    text.Size     = 14
    text.Font     = Drawing.Fonts.Plex
    text.Outline  = true
    text.OutlineColor = Color3.fromRGB(0, 0, 0)
    text.Center   = true
    text.Visible  = false

    local conn = RunService.RenderStepped:Connect(function()
        if player and player.Character then
            local root = GetRoot(player)
            if root then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.5, 0))
                local dist = (Camera.CFrame.Position - root.Position).Magnitude
                local sizeScale = math.clamp(20 - dist / 20, 5, 20)
                local _, color = GetPlayerRole(player)
                text.Color    = color
                text.Text     = player.Name
                text.Size     = sizeScale
                text.Position = Vector2.new(pos.X, pos.Y)
                text.Visible  = onScreen and S.ESPOn
            else
                text.Visible = false
            end
        else
            text.Visible = false
        end
    end)

    DrawStore.ESP[player.Name] = { text = text, conn = conn }
end

local function RemoveESP(player)
    local d = DrawStore.ESP[player.Name]
    if d then
        pcall(function() d.text:Remove() end)
        pcall(function() d.conn:Disconnect() end)
        DrawStore.ESP[player.Name] = nil
    end
end

-- ── Box ESP (Corner Lines) ────────────────────────────────────
local function MakeBox(player)
    if DrawStore.Box[player.Name] then return end

    local function NewLine()
        local l = Drawing.new("Line")
        l.Thickness    = 2
        l.Transparency = 1
        l.Visible      = false
        return l
    end

    local corners = {
        TopLeft     = NewLine(), TopRight    = NewLine(),
        BottomLeft  = NewLine(), BottomRight = NewLine(),
    }

    local conn = RunService.RenderStepped:Connect(function()
        if player and player.Character then
            local root = GetRoot(player)
            if root then
                local cf    = CFrame.lookAt(root.CFrame.Position, Camera.CFrame.Position)
                local ext   = Vector3.new(3.5, 1.5, 1.5) * 1.35
                local tl, tlV = Camera:WorldToViewportPoint((cf *  CFrame.new( ext.X,  ext.Y, 0)).Position)
                local tr, trV = Camera:WorldToViewportPoint((cf *  CFrame.new(-ext.X,  ext.Y, 0)).Position)
                local bl, blV = Camera:WorldToViewportPoint((cf *  CFrame.new( ext.X, -ext.Y, 0)).Position)
                local br, brV = Camera:WorldToViewportPoint((cf *  CFrame.new(-ext.X, -ext.Y, 0)).Position)

                local _, col = GetPlayerRole(player)
                for _, line in pairs(corners) do line.Color = col end

                corners.TopLeft.From     = Vector2.new(tl.X, tl.Y)
                corners.TopLeft.To       = Vector2.new(tr.X, tr.Y)
                corners.TopLeft.Visible  = tlV and S.BoxOn

                corners.TopRight.From    = Vector2.new(tr.X, tr.Y)
                corners.TopRight.To      = Vector2.new(br.X, br.Y)
                corners.TopRight.Visible = trV and S.BoxOn

                corners.BottomLeft.From    = Vector2.new(bl.X, bl.Y)
                corners.BottomLeft.To      = Vector2.new(tl.X, tl.Y)
                corners.BottomLeft.Visible = blV and S.BoxOn

                corners.BottomRight.From    = Vector2.new(br.X, br.Y)
                corners.BottomRight.To      = Vector2.new(bl.X, bl.Y)
                corners.BottomRight.Visible = brV and S.BoxOn
            else
                for _, l in pairs(corners) do l.Visible = false end
            end
        else
            for _, l in pairs(corners) do l.Visible = false end
        end
    end)

    DrawStore.Box[player.Name] = { corners = corners, conn = conn }
end

local function RemoveBox(player)
    local d = DrawStore.Box[player.Name]
    if d then
        for _, l in pairs(d.corners) do pcall(function() l:Remove() end) end
        pcall(function() d.conn:Disconnect() end)
        DrawStore.Box[player.Name] = nil
    end
end

-- ── Tracer ────────────────────────────────────────────────────
local function MakeTracer(player)
    if DrawStore.Tracer[player.Name] then return end

    local line        = Drawing.new("Line")
    line.Thickness    = 1.5
    line.Transparency = 1
    line.Visible      = false

    local conn = RunService.RenderStepped:Connect(function()
        if player and player.Character then
            local root = GetRoot(player)
            if root then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                local _, col = GetPlayerRole(player)
                line.Color   = col
                line.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To      = Vector2.new(pos.X, pos.Y)
                line.Visible = onScreen and S.TracerOn
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end)

    DrawStore.Tracer[player.Name] = { line = line, conn = conn }
end

local function RemoveTracer(player)
    local d = DrawStore.Tracer[player.Name]
    if d then
        pcall(function() d.line:Remove() end)
        pcall(function() d.conn:Disconnect() end)
        DrawStore.Tracer[player.Name] = nil
    end
end

-- ── Outline (SelectionBox) ────────────────────────────────────
local function MakeOutline(player)
    local folder = ESPFolder:FindFirstChild(player.Name) or Instance.new("Folder", ESPFolder)
    folder.Name  = player.Name
    if folder:FindFirstChild("Outline") then return end

    local function buildBox()
        if not player.Character then return end
        local sel  = Instance.new("SelectionBox")
        sel.Name   = "Outline"
        sel.Parent = folder
        sel.SurfaceTransparency = 1
        sel.LineThickness       = 0.05
        sel.Adornee             = player.Character

        local updateColor = RunService.RenderStepped:Connect(function()
            if sel and sel.Parent then
                local _, col = GetPlayerRole(player)
                sel.Color3  = col
                sel.Visible = S.OutlineOn
            end
        end)

        folder:SetAttribute("OutlineConn", true)
        DrawStore.Outline[player.Name] = { sel = sel, conn = updateColor }
    end

    buildBox()
    MakeTask("OutlineCharAdded_" .. player.Name, player.CharacterAdded, function()
        task.wait(1)
        local d = DrawStore.Outline[player.Name]
        if d then pcall(function() d.sel:Destroy() end); pcall(function() d.conn:Disconnect() end) end
        DrawStore.Outline[player.Name] = nil
        buildBox()
    end)
end

local function RemoveOutline(player)
    local d = DrawStore.Outline[player.Name]
    if d then
        pcall(function() d.sel:Destroy() end)
        pcall(function() d.conn:Disconnect() end)
        DrawStore.Outline[player.Name] = nil
    end
    KillTask("OutlineCharAdded_" .. player.Name)
    local folder = ESPFolder:FindFirstChild(player.Name)
    if folder then folder:Destroy() end
end

-- ── Cham (BoxHandleAdornment) ─────────────────────────────────
local function MakeCham(player)
    local folder = ESPFolder:FindFirstChild(player.Name) or Instance.new("Folder", ESPFolder)
    folder.Name  = player.Name

    local function buildCham()
        if not player.Character then return end
        local chamFolder = folder:FindFirstChild("Cham") or Instance.new("Folder", folder)
        chamFolder.Name = "Cham"

        for _, part in ipairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                local bha = chamFolder:FindFirstChild(part.Name) or Instance.new("BoxHandleAdornment")
                local _, col = GetPlayerRole(player)
                bha.Name         = part.Name
                bha.Parent       = chamFolder
                bha.Adornee      = part
                bha.Size         = part.Size
                bha.Color3       = col
                bha.AlwaysOnTop  = true
                bha.Transparency = 0.5
                bha.ZIndex       = 10
            end
        end
    end

    buildCham()
    MakeTask("ChamCharAdded_" .. player.Name, player.CharacterAdded, function()
        task.wait(2)
        buildCham()
    end)
end

local function RemoveCham(player)
    KillTask("ChamCharAdded_" .. player.Name)
    local folder = ESPFolder:FindFirstChild(player.Name)
    if folder then
        local c = folder:FindFirstChild("Cham")
        if c then c:Destroy() end
    end
end

-- Update cham colors every render step (role can change mid-round)
RunService.RenderStepped:Connect(function()
    if not S.ChamOn then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            local folder = ESPFolder:FindFirstChild(player.Name)
            if folder then
                local cham = folder:FindFirstChild("Cham")
                if cham then
                    local _, col = GetPlayerRole(player)
                    for _, bha in ipairs(cham:GetChildren()) do
                        if bha:IsA("BoxHandleAdornment") then
                            bha.Color3  = col
                            bha.Visible = S.ChamOn
                        end
                    end
                end
            end
        end
    end
end)

-- ── Dropped Gun Cham ─────────────────────────────────────────
local function StartDropGunCham()
    local function addGunCham(gun)
        if gun.Name ~= "GunDrop" then return end
        local gunFolder = ESPFolder:FindFirstChild("_GunDrop") or Instance.new("Folder", ESPFolder)
        gunFolder.Name  = "_GunDrop"
        local bha = gunFolder:FindFirstChild("bha") or Instance.new("BoxHandleAdornment")
        bha.Name         = "bha"
        bha.Parent       = gunFolder
        bha.Adornee      = gun
        bha.Size         = gun:IsA("BasePart") and gun.Size or Vector3.new(2,1,2)
        bha.Color3       = RoleColor("Sheriff")
        bha.AlwaysOnTop  = true
        bha.Transparency = 0.35
        bha.ZIndex       = 10
    end

    MakeTask("ChamDropGun_Added",   workspace.ChildAdded,   addGunCham)
    MakeTask("ChamDropGun_Removed", workspace.ChildRemoved, function(obj)
        if obj.Name == "GunDrop" then
            local f = ESPFolder:FindFirstChild("_GunDrop")
            if f then f:Destroy() end
        end
    end)

    if workspace:FindFirstChild("GunDrop") then
        addGunCham(workspace.GunDrop)
    end
end

local function StopDropGunCham()
    KillTask("ChamDropGun_Added")
    KillTask("ChamDropGun_Removed")
    local f = ESPFolder:FindFirstChild("_GunDrop")
    if f then f:Destroy() end
end

-- ── Enable/disable visual for all players ─────────────────────
local function ApplyVisualAll(buildFn, removeFn, flag)
    if flag then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then buildFn(p) end
        end
        MakeTask("Visual_PlayerAdded_" .. tostring(buildFn), Players.PlayerAdded, buildFn)
        MakeTask("Visual_PlayerRemoved_" .. tostring(removeFn), Players.PlayerRemoving, removeFn)
    else
        KillTask("Visual_PlayerAdded_" .. tostring(buildFn))
        KillTask("Visual_PlayerRemoved_" .. tostring(removeFn))
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then removeFn(p) end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  ██  COMBAT FUNCTIONS  ██
-- ═══════════════════════════════════════════════════════════════

local function GetGun(player)
    local p = player or LP
    for _, t in ipairs(p.Character and p.Character:GetChildren() or {}) do
        if t.Name == "Gun" and t:IsA("Tool") then return t end
    end
    for _, t in ipairs(p.Backpack:GetChildren()) do
        if t.Name == "Gun" and t:IsA("Tool") then return t end
    end
end

local function GetKnife(player)
    local p = player or LP
    for _, t in ipairs(p.Character and p.Character:GetChildren() or {}) do
        if t.Name == "Knife" and t:IsA("Tool") then return t end
    end
    for _, t in ipairs(p.Backpack:GetChildren()) do
        if t.Name == "Knife" and t:IsA("Tool") then return t end
    end
end

-- Stab helper (same as original HK function)
local function StabPlayer(target, knife)
    local root = GetRoot(target)
    if not root or not knife then return end
    pcall(function() FireServer(knife.Stab, "Down") end)
    task.spawn(function()
        pcall(function()
            firetouchinterest(root, knife.Handle, 0)
            firetouchinterest(root, knife.Handle, 1)
        end)
    end)
end

-- Shoot at position (Sheriff silent aim core)
local function ShootAt(gun, targetPos, method)
    if not gun then return end

    local shootRemote = gun:FindFirstChild("KnifeServer") and
                        gun.KnifeServer:FindFirstChild("ShootGun")
    if not shootRemote then return end

    if method == "Dynamic" then
        -- Leads target based on their current velocity/movement
        local murderer = Players:FindFirstChild(S.Murderer)
        if murderer and murderer.Character then
            local hum   = murderer.Character:FindFirstChild("Humanoid")
            local root  = GetRoot(murderer)
            if root and hum then
                local predicted = (root.CFrame + (hum.MoveDirection * hum.WalkSpeed) / 16).Position
                InvokeServer(shootRemote, 0, predicted, "AH")
            else
                InvokeServer(shootRemote, 0, targetPos, "AH")
            end
        else
            InvokeServer(shootRemote, 0, targetPos, "AH")
        end

    elseif method == "SharpShooter" then
        -- Very precise – aims directly at HRP centre
        InvokeServer(shootRemote, 0, targetPos, "AH")
        task.wait(0.05)
        InvokeServer(shootRemote, 0, targetPos, "AH") -- double tap

    else -- Regular
        InvokeServer(shootRemote, 0, targetPos, "AH")
    end
end

-- Silent Aim loop for sheriff (fires every frame when toggle is on)
local SilentAimConn
local function StartSilentAim()
    if SilentAimConn then SilentAimConn:Disconnect() end
    SilentAimConn = RunService.Heartbeat:Connect(function()
        if not S.SilentAimOn then return end
        if S.MyRole ~= "Sheriff" and S.MyRole ~= "Hero" then return end
        if not IsAlive(LP) then return end

        -- Equip gun if in backpack
        local gun = GetGun(LP)
        if not gun then return end
        local wasInBag = gun.Parent == LP.Backpack
        if wasInBag then gun.Parent = LP.Character end

        local murderer = Players:FindFirstChild(S.Murderer)
        if murderer and IsAlive(murderer) then
            local root = GetRoot(murderer)
            if root then
                local method = S.SharpShooter and "SharpShooter" or S.SilentAimMethod
                ShootAt(gun, root.Position, method)
            end
        end

        if wasInBag then gun.Parent = LP.Backpack end
    end)
end

local function StopSilentAim()
    if SilentAimConn then
        SilentAimConn:Disconnect()
        SilentAimConn = nil
    end
end

-- ── Grab Gun ──────────────────────────────────────────────────
local function DoGrabGun()
    local gun = workspace:FindFirstChild("GunDrop")
    if not gun then
        Notify("MM2 Hub", "Gun hasn't dropped yet.", 3)
        return
    end
    if not IsAlive(LP) then
        Notify("MM2 Hub", "You're not alive!", 3)
        return
    end
    if S.Murderer == LP.Name then
        Notify("MM2 Hub", "You are the murderer!", 3)
        return
    end
    if S.IsGrabbing then return end

    task.spawn(function()
        S.IsGrabbing = true
        local oldCF  = GetRoot(LP) and GetRoot(LP).CFrame

        MakeTask("GrabGun_Move", RunService.Heartbeat, function()
            if S.IsGrabbing and GetRoot(LP) then
                GetRoot(LP).CFrame              = gun.CFrame
                LP.Character.Humanoid.PlatformStand = false
            end
        end)

        repeat task.wait() until not workspace:FindFirstChild("GunDrop")

        KillTask("GrabGun_Move")
        if oldCF and GetRoot(LP) then
            GetRoot(LP).CFrame = oldCF
        end
        LP.Character.Humanoid.PlatformStand = false
        LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        S.IsGrabbing = false
        Notify("MM2 Hub", "Gun grabbed!", 3)
    end)
end

-- Auto Grab Gun
local function StartAutoGrab()
    MakeTask("AutoGrabGun_Watcher", RunService.Heartbeat, function()
        if not S.AutoGrab then return end
        local gun      = workspace:FindFirstChild("GunDrop")
        local murderer = Players:FindFirstChild(S.Murderer)
        if not gun or not IsAlive(LP) then return end
        if S.IsGrabbing then return end
        -- Don't grab if murderer is camping the gun (within 10 studs)
        if murderer and IsAlive(murderer) and GetRoot(murderer) then
            local dist = (GetRoot(murderer).Position - gun.Position).Magnitude
            if dist <= 10 then return end
        end
        DoGrabGun()
    end)
end

-- Steal Gun via SprayPaint exploit (mirrors original Steal Gun button)
local function StealGun()
    local sheriff = Players:FindFirstChild(S.Sheriff)
    if not sheriff or not IsAlive(sheriff) then
        Notify("MM2 Hub", "No sheriff detected.", 3)
        return
    end
    local sherRoot = GetRoot(sheriff)
    if not sherRoot then return end

    -- Need SprayPaint tool
    local sprayTool
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t.Name == "SprayPaint" and t:IsA("Tool") then sprayTool = t end
    end
    if not sprayTool then
        for _, t in ipairs(LP.Character and LP.Character:GetChildren() or {}) do
            if t.Name == "SprayPaint" and t:IsA("Tool") then sprayTool = t end
        end
    end

    if not sprayTool then
        -- Try to replicate toy first
        pcall(function()
            if Extras and Extras:FindFirstChild("ReplicateToy") then
                InvokeServer(Extras.ReplicateToy, "SprayPaint")
            end
        end)
        task.wait(0.2)
        for _, t in ipairs(LP.Backpack:GetChildren()) do
            if t.Name == "SprayPaint" and t:IsA("Tool") then sprayTool = t end
        end
    end

    if not sprayTool then
        Notify("MM2 Hub", "You need SprayPaint toy for Steal Gun!", 4)
        return
    end

    local sprayRemote = sprayTool:FindFirstChild("Remote")
    if not sprayRemote then return end

    -- Fling gun down so it drops
    FireServer(sprayRemote, 0, Enum.NormalId.Right, 10, sherRoot, CFrame.new(0, -math.huge, 0))

    -- Wait for GunDrop then grab it
    local waited = 0
    repeat
        task.wait(0.05)
        waited = waited + 1
    until workspace:FindFirstChild("GunDrop") or waited >= 40

    if workspace:FindFirstChild("GunDrop") then
        DoGrabGun()
    end
end

-- ── Kill helpers ──────────────────────────────────────────────
local function KillAll()
    if S.MyRole ~= "Murderer" then return end
    local knife = GetKnife(LP)
    if not knife then return end
    if knife.Parent == LP.Backpack then knife.Parent = LP.Character end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and IsAlive(p) then
            StabPlayer(p, knife)
        end
    end
end

local function ShootMurderer()
    if S.MyRole ~= "Sheriff" and S.MyRole ~= "Hero" then return end
    local murderer = Players:FindFirstChild(S.Murderer)
    if not murderer or not IsAlive(murderer) then
        Notify("MM2 Hub", "No murderer to shoot.", 3)
        return
    end

    local gun = GetGun(LP)
    if not gun then
        Notify("MM2 Hub", "No gun equipped!", 3)
        return
    end

    local wasInBag = gun.Parent == LP.Backpack
    if wasInBag then gun.Parent = LP.Character end

    local savedCF = GetRoot(LP) and GetRoot(LP).CFrame
    -- Teleport close to murderer
    local murdRoot = GetRoot(murderer)
    if murdRoot then
        TpChar(LP, murdRoot.CFrame * CFrame.new(0, 0, 5))
        task.wait(0.2)
        ShootAt(gun, murdRoot.Position, S.SilentAimMethod)
    end

    task.wait()
    if savedCF and GetRoot(LP) then
        GetRoot(LP).CFrame = savedCF
    end
    if wasInBag then gun.Parent = LP.Backpack end
end

-- ═══════════════════════════════════════════════════════════════
--  ██  TIMER / CHANCE / ROLE NOTIFY  ██
-- ═══════════════════════════════════════════════════════════════

-- Timer drawing
local timerDraw = Drawing.new("Text")
timerDraw.Size      = 22
timerDraw.Font      = Drawing.Fonts.Plex
timerDraw.Outline   = true
timerDraw.Center    = true
timerDraw.Color     = Color3.fromRGB(255, 255, 255)
timerDraw.Position  = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 0.1)
timerDraw.Visible   = false

local function FormatTime(secs)
    local m = math.floor(secs / 60)
    local s = secs % 60
    if m > 0 then return m .. "m " .. s .. "s" end
    return s .. "s"
end

local function StartRoundTimer()
    MakeTask("RoundTimer", RunService.Heartbeat, function()
        if not S.TimerOn then timerDraw.Visible = false return end
        pcall(function()
            if Extras and Extras:FindFirstChild("GetTimer") then
                local t = InvokeServer(Extras.GetTimer) or 0
                if t < 1 then
                    timerDraw.Visible = false
                else
                    timerDraw.Visible   = true
                    timerDraw.Text      = "⏱ " .. FormatTime(math.floor(t))
                    timerDraw.Color     = t < 30 and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
                end
            end
        end)
    end)
end

-- ── Notify functions ─────────────────────────────────────────
local function NotifyRole()
    pcall(function()
        local role = S.MyRole
        local col  = RoleColor(role)
        Notify("Your Role", "You are: " .. role, 6)
        -- Also show murderer + sheriff
        if S.Murderer ~= "" then
            task.wait(0.5)
            Notify("Murderer", S.Murderer, 5)
        end
        if S.Sheriff ~= "" then
            task.wait(0.5)
            Notify(S.Hero and "Hero" or "Sheriff", S.Sheriff, 5)
        end
    end)
end

local function NotifyMurdererPerk()
    pcall(function()
        local data = S.RoleData[S.Murderer]
        if S.Murderer ~= "" and data and data.Effect then
            Notify("Murderer Perk", S.Murderer .. " is using: " .. tostring(data.Effect), 5)
        else
            Notify("MM2 Hub", "No murderer perk data found.", 3)
        end
    end)
end

local function GetChance()
    pcall(function()
        if Extras and Extras:FindFirstChild("GetChance") then
            local chance = InvokeServer(Extras.GetChance)
            Notify("Murderer Chance", "Your chance: " .. tostring(chance) .. "%", 5)
        else
            Notify("MM2 Hub", "GetChance remote not found.", 3)
        end
    end)
end

-- ── Register auto-notify callbacks on round start ─────────────
S.Callbacks.OnRoundStart.AutoNotifyRole = nil
S.Callbacks.OnRoundStart.AutoNotifyPerk = nil

-- ═══════════════════════════════════════════════════════════════
--  ██  FLUENT WINDOW  ██
-- ═══════════════════════════════════════════════════════════════

local Window = Fluent:CreateWindow({
    Title        = "MM2 Hub",
    SubTitle     = "by rebuild",
    TabWidth     = 160,
    Size         = UDim2.fromOffset(560, 420),
    Acrylic      = true,
    Theme        = "Dark",
    MinimizeKey  = Enum.KeyCode.RightBracket,
})

-- ── Tabs ──────────────────────────────────────────────────────
local Tabs = {
    Visuals  = Window:AddTab({ Title = "Visuals",  Icon = "eye" }),
    Info     = Window:AddTab({ Title = "Info",     Icon = "info" }),
    Gun      = Window:AddTab({ Title = "Gun",      Icon = "crosshair" }),
    Combat   = Window:AddTab({ Title = "Combat",   Icon = "sword" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
}

-- ─────────────────────────────────────────────────────────────
--  TAB: VISUALS
-- ─────────────────────────────────────────────────────────────
local VisTab = Tabs.Visuals

VisTab:AddParagraph({ Title = "Role Colours", Content = "Red = Murderer | Blue = Sheriff | Teal = Hero | Green = Innocent" })

VisTab:AddSection("ESP")

VisTab:AddToggle("ESPToggle", {
    Title   = "Name ESP",
    Default = false,
    Callback = function(v)
        S.ESPOn = v
        ApplyVisualAll(MakeESP, RemoveESP, v)
    end,
})

VisTab:AddToggle("TracerToggle", {
    Title   = "Tracers",
    Default = false,
    Callback = function(v)
        S.TracerOn = v
        ApplyVisualAll(MakeTracer, RemoveTracer, v)
    end,
})

VisTab:AddSection("Box / Outline")

VisTab:AddToggle("BoxToggle", {
    Title   = "Box ESP",
    Default = false,
    Callback = function(v)
        S.BoxOn = v
        ApplyVisualAll(MakeBox, RemoveBox, v)
    end,
})

VisTab:AddToggle("OutlineToggle", {
    Title   = "Outline (SelectionBox)",
    Default = false,
    Callback = function(v)
        S.OutlineOn = v
        ApplyVisualAll(MakeOutline, RemoveOutline, v)
    end,
})

VisTab:AddSection("Chams")

VisTab:AddToggle("ChamToggle", {
    Title   = "Cham Everyone",
    Default = false,
    Callback = function(v)
        S.ChamOn = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then MakeCham(p) end
            end
            MakeTask("Cham_Added",   Players.PlayerAdded,   MakeCham)
            MakeTask("Cham_Removed", Players.PlayerRemoving, RemoveCham)
        else
            KillTask("Cham_Added")
            KillTask("Cham_Removed")
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then RemoveCham(p) end
            end
        end
    end,
})

VisTab:AddToggle("ChamDropGunToggle", {
    Title   = "Cham Dropped Gun",
    Default = false,
    Callback = function(v)
        S.ChamDropGun = v
        if v then StartDropGunCham() else StopDropGunCham() end
    end,
})

-- ─────────────────────────────────────────────────────────────
--  TAB: INFO  (Timer / Chance / Role Notify)
-- ─────────────────────────────────────────────────────────────
local InfoTab = Tabs.Info

InfoTab:AddSection("Round Info")

InfoTab:AddToggle("TimerToggle", {
    Title   = "Show Round Timer",
    Default = false,
    Callback = function(v)
        S.TimerOn = v
        if v then
            StartRoundTimer()
        else
            KillTask("RoundTimer")
            timerDraw.Visible = false
        end
    end,
})

InfoTab:AddButton({
    Title   = "Get Murderer Chance",
    Description = "Shows your current murderer chance %",
    Callback = GetChance,
})

InfoTab:AddSection("Role Notify")

InfoTab:AddButton({
    Title    = "Notify Role Now",
    Description = "Shows your role and who is murderer/sheriff",
    Callback = NotifyRole,
})

InfoTab:AddToggle("AutoNotifyRole", {
    Title   = "Auto Notify Role (on round start)",
    Default = false,
    Callback = function(v)
        S.Callbacks.OnRoundStart.AutoNotifyRole = v and NotifyRole or nil
    end,
})

InfoTab:AddSection("Murderer Perk")

InfoTab:AddButton({
    Title    = "Notify Murderer Perk",
    Description = "Shows which perk the murderer is using",
    Callback  = NotifyMurdererPerk,
})

InfoTab:AddToggle("AutoNotifyPerk", {
    Title   = "Auto Notify Murderer Perk (on round start)",
    Default = false,
    Callback = function(v)
        S.Callbacks.OnRoundStart.AutoNotifyPerk = v and NotifyMurdererPerk or nil
    end,
})

InfoTab:AddSection("Status Labels")

local MurdLabel  = InfoTab:AddParagraph({ Title = "Murderer",  Content = "None" })
local SherLabel  = InfoTab:AddParagraph({ Title = "Sheriff",   Content = "None" })
local RoleLabel  = InfoTab:AddParagraph({ Title = "Your Role", Content = "Innocent" })

RunService.Heartbeat:Connect(function()
    pcall(function()
        MurdLabel:SetDesc(S.Murderer ~= "" and S.Murderer or "None detected")
        SherLabel:SetDesc((S.Sheriff ~= "" and S.Sheriff or "None detected") ..
                          (S.Hero and "  (Hero)" or ""))
        RoleLabel:SetDesc(S.MyRole)
    end)
end)

-- ─────────────────────────────────────────────────────────────
--  TAB: GUN  (Grab Gun + related)
-- ─────────────────────────────────────────────────────────────
local GunTab = Tabs.Gun

local GunStatusLabel = GunTab:AddParagraph({ Title = "Gun Status", Content = "Not Dropped" })

RunService.RenderStepped:Connect(function()
    pcall(function()
        local dropped = workspace:FindFirstChild("GunDrop") ~= nil
        GunStatusLabel:SetDesc(dropped and "✅ DROPPED - Ready to grab!" or "❌ Not Dropped")
    end)
end)

GunTab:AddSection("Grab Gun")

GunTab:AddButton({
    Title       = "Grab Gun  [G]",
    Description = "Teleport to the dropped gun and pick it up",
    Callback    = DoGrabGun,
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        DoGrabGun()
    end
end)

GunTab:AddToggle("AutoGrabToggle", {
    Title       = "Auto Grab Gun",
    Description = "Automatically grabs gun when it drops (won't grab if murderer is camping it)",
    Default     = false,
    Callback    = function(v)
        S.AutoGrab = v
        if v then StartAutoGrab() else KillTask("AutoGrabGun_Watcher") end
    end,
})

GunTab:AddSection("Steal Gun")

GunTab:AddButton({
    Title       = "Steal Gun",
    Description = "Uses SprayPaint to knock the gun from sheriff then grabs it (needs SprayPaint toy)",
    Callback    = StealGun,
})

GunTab:AddSection("Spectate")

GunTab:AddButton({
    Title    = "Spectate Gun Drop",
    Callback = function()
        local gun = workspace:FindFirstChild("GunDrop")
        if gun then
            workspace.CurrentCamera.CameraSubject = gun
        else
            Notify("MM2 Hub", "Gun hasn't dropped yet.", 3)
        end
    end,
})

GunTab:AddButton({
    Title    = "Unspectate",
    Callback = function()
        if LP.Character then
            workspace.CurrentCamera.CameraSubject = LP.Character:FindFirstChild("Humanoid")
        end
    end,
})

-- ─────────────────────────────────────────────────────────────
--  TAB: COMBAT
-- ─────────────────────────────────────────────────────────────
local CombTab = Tabs.Combat

-- ── SHERIFF Section ────────────────────────────────────────
CombTab:AddSection("Sheriff / Hero")

CombTab:AddToggle("SharpShooterToggle", {
    Title       = "Sharp Shooter",
    Description = "Fires two shots directly at HRP centre for higher accuracy",
    Default     = false,
    Callback    = function(v)
        S.SharpShooter = v
    end,
})

CombTab:AddToggle("SilentAimToggle", {
    Title       = "Sheriff Silent Aim",
    Description = "Auto-fires at murderer using the selected method when you have a gun",
    Default     = false,
    Callback    = function(v)
        S.SilentAimOn = v
        if v then StartSilentAim() else StopSilentAim() end
    end,
})

CombTab:AddDropdown("SilentAimMethod", {
    Title   = "Silent Aim Method",
    Values  = { "Dynamic", "Regular" },
    Default = "Dynamic",
    Callback = function(v)
        S.SilentAimMethod = v
        Notify("MM2 Hub", "Silent Aim method: " .. v, 3)
    end,
})

CombTab:AddParagraph({
    Title   = "Method Info",
    Content = "Dynamic → leads the target (predicts movement). Regular → shoots direct at HRP. SharpShooter fires twice for reliability.",
})

CombTab:AddButton({
    Title       = "Shoot Murderer  [C]",
    Description = "One-shot the murderer right now (teleports close, shoots, teleports back)",
    Callback    = ShootMurderer,
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.C then
        ShootMurderer()
    end
end)

-- ── MURDERER Section ────────────────────────────────────────
CombTab:AddSection("Murderer")

CombTab:AddToggle("AutoKillToggle", {
    Title       = "Auto Kill Everyone",
    Description = "Automatically stabs all alive players while you are murderer",
    Default     = false,
    Callback    = function(v)
        S.AutoKill = v
        if v then
            MakeTask("AutoKill_Loop", RunService.Heartbeat, function()
                if not S.AutoKill then return end
                if S.MyRole ~= "Murderer" then return end
                if not IsAlive(LP) then return end
                local knife = GetKnife(LP)
                if not knife then return end
                if knife.Parent == LP.Backpack then knife.Parent = LP.Character end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and IsAlive(p) then
                        StabPlayer(p, knife)
                    end
                end
            end)
        else
            KillTask("AutoKill_Loop")
        end
    end,
})

CombTab:AddToggle("KnifeAuraToggle", {
    Title       = "Knife Aura",
    Description = "Automatically stabs players within range",
    Default     = false,
    Callback    = function(v)
        S.KnifeAuraOn = v
    end,
})

CombTab:AddSlider("KnifeRangeSlider", {
    Title   = "Knife Aura Range",
    Min     = 5,
    Max     = 100,
    Default = 30,
    Callback = function(v)
        S.KnifeRange = v
    end,
})

CombTab:AddButton({
    Title    = "Kill Everyone Now  [B]",
    Callback = KillAll,
})

CombTab:AddButton({
    Title    = "Kill Sheriff",
    Callback = function()
        if S.MyRole ~= "Murderer" then return end
        local knife = GetKnife(LP)
        if not knife then return end
        if knife.Parent == LP.Backpack then knife.Parent = LP.Character end
        local sheriff = Players:FindFirstChild(S.Sheriff)
        if sheriff and IsAlive(sheriff) then
            StabPlayer(sheriff, knife)
        else
            Notify("MM2 Hub", "No sheriff detected.", 3)
        end
    end,
})

CombTab:AddButton({
    Title    = "Kill Murderer (Knife)",
    Description = "For when you're an innocent who picked up a knife",
    Callback = function()
        local knife = GetKnife(LP)
        if not knife then Notify("MM2 Hub", "No knife found!", 3) return end
        if knife.Parent == LP.Backpack then knife.Parent = LP.Character end
        local murderer = Players:FindFirstChild(S.Murderer)
        if murderer and IsAlive(murderer) then
            StabPlayer(murderer, knife)
        else
            Notify("MM2 Hub", "No murderer detected.", 3)
        end
    end,
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.B then KillAll() end
end)

-- ── KNIFE AURA loop ─────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.15)
        if S.KnifeAuraOn and S.MyRole == "Murderer" and IsAlive(LP) then
            local knife = GetKnife(LP)
            if knife then
                local myRoot = GetRoot(LP)
                if myRoot then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and IsAlive(p) then
                            local root = GetRoot(p)
                            if root and (root.Position - myRoot.Position).Magnitude <= S.KnifeRange then
                                StabPlayer(p, knife)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
--  TAB: SETTINGS
-- ─────────────────────────────────────────────────────────────
local SettTab = Tabs.Settings

SettTab:AddSection("UI")

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(SettTab)

SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreList({ "SilentAimMethod" })
SaveManager:BuildConfigSection(SettTab)
SaveManager:LoadAutoloadConfig()

SettTab:AddParagraph({
    Title   = "Keybinds",
    Content = "G → Grab Gun\nC → Shoot Murderer\nB → Kill Everyone\n] → Toggle GUI",
})

-- ── Finished loading ─────────────────────────────────────────
Window:SelectTab(1)
Notify("MM2 Hub", "Loaded! Press ] to toggle GUI.", 5)

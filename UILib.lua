--[[
    UILib v4.1
    Fixes:
      - Drag: offset-tracked (window stays exactly where you grabbed it)
      - Spring lerp on PC (snappy, not laggy), direct on mobile
      - Named configs so multiple scripts can have separate saves
      - Dropdown uses ScrollingFrame — no more cut-off lists
      - 5x syntax checked
--]]

local UILib = {}
UILib.__index = UILib

-- ── Services ────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local SoundService     = game:GetService("SoundService")
local HttpService      = game:GetService("HttpService")
local LP               = Players.LocalPlayer
local Cam              = workspace.CurrentCamera

-- ── Device detection ────────────────────────────────────────────────────────
-- Touch = mobile/tablet. If mouse is ALSO present (Windows touch screen) treat as PC.
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- ── State ───────────────────────────────────────────────────────────────────
local _st = {
    windows          = {},
    activeTheme      = "Dark Minimal",
    theme            = nil,
    soundEnabled     = true,
    reduceMotion     = false,
    componentCount   = 0,
    configData       = {},
    configName       = "default",
    hwid             = "UNKNOWN",
    hwid_status      = "PENDING",
    lastAnnouncement = "",
    debugPanel       = nil,
}

-- ── Themes ──────────────────────────────────────────────────────────────────
local THEMES = {
    ["Dark Minimal"] = {
        Background  = Color3.fromRGB(12, 12, 14),
        Surface     = Color3.fromRGB(20, 20, 24),
        Elevated    = Color3.fromRGB(30, 30, 36),
        Border      = Color3.fromRGB(45, 45, 55),
        Accent      = Color3.fromRGB(99, 102, 241),
        AccentHover = Color3.fromRGB(129, 132, 255),
        AccentText  = Color3.fromRGB(255, 255, 255),
        Text        = Color3.fromRGB(230, 230, 235),
        SubText     = Color3.fromRGB(140, 140, 155),
        Danger      = Color3.fromRGB(239, 68, 68),
        Success     = Color3.fromRGB(34, 197, 94),
        Warning     = Color3.fromRGB(234, 179, 8),
    },
    ["Midnight Blue"] = {
        Background  = Color3.fromRGB(8, 12, 28),
        Surface     = Color3.fromRGB(14, 20, 45),
        Elevated    = Color3.fromRGB(22, 32, 65),
        Border      = Color3.fromRGB(35, 50, 95),
        Accent      = Color3.fromRGB(56, 189, 248),
        AccentHover = Color3.fromRGB(96, 210, 255),
        AccentText  = Color3.fromRGB(8, 12, 28),
        Text        = Color3.fromRGB(220, 235, 255),
        SubText     = Color3.fromRGB(110, 140, 190),
        Danger      = Color3.fromRGB(239, 68, 68),
        Success     = Color3.fromRGB(34, 197, 94),
        Warning     = Color3.fromRGB(234, 179, 8),
    },
    ["Soft Purple"] = {
        Background  = Color3.fromRGB(15, 10, 25),
        Surface     = Color3.fromRGB(24, 16, 40),
        Elevated    = Color3.fromRGB(36, 24, 60),
        Border      = Color3.fromRGB(60, 40, 95),
        Accent      = Color3.fromRGB(168, 85, 247),
        AccentHover = Color3.fromRGB(192, 120, 255),
        AccentText  = Color3.fromRGB(255, 255, 255),
        Text        = Color3.fromRGB(235, 220, 255),
        SubText     = Color3.fromRGB(150, 120, 190),
        Danger      = Color3.fromRGB(239, 68, 68),
        Success     = Color3.fromRGB(34, 197, 94),
        Warning     = Color3.fromRGB(234, 179, 8),
    },
    ["Emerald Green"] = {
        Background  = Color3.fromRGB(5, 15, 10),
        Surface     = Color3.fromRGB(10, 24, 16),
        Elevated    = Color3.fromRGB(16, 36, 24),
        Border      = Color3.fromRGB(28, 60, 40),
        Accent      = Color3.fromRGB(16, 185, 129),
        AccentHover = Color3.fromRGB(52, 211, 153),
        AccentText  = Color3.fromRGB(5, 15, 10),
        Text        = Color3.fromRGB(210, 245, 225),
        SubText     = Color3.fromRGB(100, 160, 130),
        Danger      = Color3.fromRGB(239, 68, 68),
        Success     = Color3.fromRGB(16, 185, 129),
        Warning     = Color3.fromRGB(234, 179, 8),
    },
    ["Light Clean"] = {
        Background  = Color3.fromRGB(245, 246, 250),
        Surface     = Color3.fromRGB(255, 255, 255),
        Elevated    = Color3.fromRGB(240, 241, 246),
        Border      = Color3.fromRGB(215, 216, 225),
        Accent      = Color3.fromRGB(99, 102, 241),
        AccentHover = Color3.fromRGB(79, 82, 221),
        AccentText  = Color3.fromRGB(255, 255, 255),
        Text        = Color3.fromRGB(20, 20, 30),
        SubText     = Color3.fromRGB(100, 100, 120),
        Danger      = Color3.fromRGB(220, 50, 50),
        Success     = Color3.fromRGB(22, 163, 74),
        Warning     = Color3.fromRGB(202, 138, 4),
    },
    ["Cyber Accent"] = {
        Background  = Color3.fromRGB(6, 6, 10),
        Surface     = Color3.fromRGB(12, 12, 18),
        Elevated    = Color3.fromRGB(20, 20, 28),
        Border      = Color3.fromRGB(0, 255, 180),
        Accent      = Color3.fromRGB(0, 255, 180),
        AccentHover = Color3.fromRGB(80, 255, 210),
        AccentText  = Color3.fromRGB(6, 6, 10),
        Text        = Color3.fromRGB(200, 255, 240),
        SubText     = Color3.fromRGB(80, 180, 150),
        Danger      = Color3.fromRGB(255, 50, 80),
        Success     = Color3.fromRGB(0, 255, 180),
        Warning     = Color3.fromRGB(255, 200, 0),
    },
}

-- ── Constants ────────────────────────────────────────────────────────────────
local ANIM = {
    Fast   = 0.12,
    Normal = 0.20,
    Slow   = 0.28,
    Ease   = Enum.EasingStyle.Quint,
    Out    = Enum.EasingDirection.Out,
    InOut  = Enum.EasingDirection.InOut,
}

local SP
if IS_MOBILE then
    SP = { xs = 5, sm = 10, md = 18, lg = 28, xl = 36 }
else
    SP = { xs = 4, sm = 8,  md = 16, lg = 24, xl = 32 }
end

local FONT = {
    Title   = { size = IS_MOBILE and 18 or 20, font = Enum.Font.GothamBold },
    Section = { size = IS_MOBILE and 13 or 14, font = Enum.Font.GothamSemibold },
    Body    = { size = 13,                      font = Enum.Font.Gotham },
    Small   = { size = 11,                      font = Enum.Font.Gotham },
    Mono    = { size = 11,                      font = Enum.Font.Code },
}

local ROW_H   = IS_MOBILE and 48 or 42
local TITLE_H = IS_MOBILE and 54 or 50
local TAB_W   = IS_MOBILE and 120 or 130

local RADIUS = {
    Window = UDim.new(0, 12),
    Panel  = UDim.new(0, 8),
    Button = UDim.new(0, 6),
    Pill   = UDim.new(1, 0),
    Tag    = UDim.new(0, 4),
}

-- ── Utility helpers ─────────────────────────────────────────────────────────
local function tw(obj, props, dur, style, dir)
    if _st.reduceMotion then dur = 0 end
    TweenService:Create(obj,
        TweenInfo.new(dur or ANIM.Normal, style or ANIM.Ease, dir or ANIM.Out),
        props
    ):Play()
end

local function new(cls, props)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do
        o[k] = v
    end
    return o
end

local function applyCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or RADIUS.Panel
    c.Parent = p
    return c
end

local function applyStroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color           = col
    s.Thickness       = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = p
    return s
end

local function applyPad(p, t, r, b, l)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or SP.md)
    u.PaddingRight  = UDim.new(0, r or SP.md)
    u.PaddingBottom = UDim.new(0, b or SP.md)
    u.PaddingLeft   = UDim.new(0, l or SP.md)
    u.Parent        = p
    return u
end

local function applyList(p, spacing, dir)
    local l = Instance.new("UIListLayout")
    l.Padding             = UDim.new(0, spacing or SP.sm)
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = Enum.VerticalAlignment.Top
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent              = p
    return l
end

local function getVP()
    return Cam.ViewportSize
end

-- Keeps UDim2 within screen bounds
local function clampToScreen(pos, absSize)
    local vp = getVP()
    local x  = math.clamp(pos.X.Offset, 0, math.max(0, vp.X - absSize.X))
    local y  = math.clamp(pos.Y.Offset, 0, math.max(0, vp.Y - absSize.Y))
    return UDim2.new(0, x, 0, y)
end

-- ── DRAG SYSTEM ─────────────────────────────────────────────────────────────
--
-- THE FIX: track dragOffset = (inputPos - frame.AbsolutePosition) at drag start.
-- Each move: newPos = inputPos - dragOffset.
-- This means the window NEVER jumps — it stays exactly where you grabbed it.
--
-- PC:     RenderStepped spring lerp (alpha 0.82) — feels snappy but silky.
-- Mobile: Direct assignment each frame — finger IS position, no lag wanted.
--
local function makeDraggable(handle, target)
    local dragging    = false
    local dragOffset  = Vector2.new(0, 0)   -- where inside the frame was clicked
    local goalPos     = Vector2.new(0, 0)   -- target world position (clamped)
    local renderConn  = nil

    local function stopDrag()
        dragging = false
        if renderConn then
            renderConn:Disconnect()
            renderConn = nil
        end
    end

    local function startDrag(inputPos)
        dragging   = true
        -- Offset from top-left of the target frame to where input began
        local ap   = target.AbsolutePosition
        dragOffset = Vector2.new(inputPos.X - ap.X, inputPos.Y - ap.Y)
        -- Initialise goalPos at current position so there is zero initial lerp error
        goalPos    = Vector2.new(ap.X, ap.Y)

        if IS_MOBILE then
            -- Mobile: update position directly in InputChanged — no lerp
            -- RenderStepped conn not needed
        else
            -- PC: lerp on every render frame toward goalPos
            renderConn = RunService.RenderStepped:Connect(function()
                if not dragging then return end
                local cur = target.AbsolutePosition
                -- Spring factor 0.82: moves 82% of remaining distance per frame
                -- At 60 fps this gives sub-1-frame visual lag, but feels smooth
                local alpha = 0.82
                local nx = cur.X + (goalPos.X - cur.X) * alpha
                local ny = cur.Y + (goalPos.Y - cur.Y) * alpha
                target.Position = UDim2.new(0, nx, 0, ny)
            end)
        end
    end

    local function moveDrag(inputPos)
        if not dragging then return end
        -- Desired top-left of target = inputPos minus the saved grab offset
        local raw = Vector2.new(inputPos.X - dragOffset.X, inputPos.Y - dragOffset.Y)
        -- Clamp so window cannot leave screen
        local sz  = target.AbsoluteSize
        local vp  = getVP()
        local cx  = math.clamp(raw.X, 0, math.max(0, vp.X - sz.X))
        local cy  = math.clamp(raw.Y, 0, math.max(0, vp.Y - sz.Y))

        if IS_MOBILE then
            -- Direct: finger position = window position, zero lag
            target.Position = UDim2.new(0, cx, 0, cy)
        else
            -- Update goal; RenderStepped lerps toward it
            goalPos = Vector2.new(cx, cy)
        end
    end

    -- InputBegan on the handle (titlebar / float button)
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag(inp.Position)
        elseif inp.UserInputType == Enum.UserInputType.Touch then
            if not dragging then
                startDrag(inp.Position)
            end
        end
    end)

    -- Global InputChanged (tracks finger / mouse outside the handle)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            moveDrag(inp.Position)
        end
    end)

    -- InputEnded — release drag
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            stopDrag()
        end
    end)
end

-- ── Sound ────────────────────────────────────────────────────────────────────
local _sounds = {}
local SOUND_IDS = {
    click  = "rbxassetid://876939830",
    toggle = "rbxassetid://876939830",
    open   = "rbxassetid://896458806",
    close  = "rbxassetid://896458806",
    notify = "rbxassetid://4590657835",
    error  = "rbxassetid://4773870682",
}
for k, v in pairs(SOUND_IDS) do
    pcall(function()
        local s            = Instance.new("Sound")
        s.SoundId          = v
        s.Volume           = 0.3
        s.RollOffMaxDistance = 0
        s.Parent           = SoundService
        _sounds[k]         = s
    end)
end
local function playSound(name)
    if _st.soundEnabled and _sounds[name] then
        _sounds[name]:Play()
    end
end

-- ── ScreenGui ────────────────────────────────────────────────────────────────
local ScreenGui = new("ScreenGui", {
    Name           = "UILib_Root",
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
})
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LP.PlayerGui
end

if IS_MOBILE then
    local vp    = getVP()
    local scale = math.min(vp.X / 540, vp.Y / 430, 1)
    if scale < 0.95 then
        new("UIScale", { Scale = scale, Parent = ScreenGui })
    end
end

-- Notification layer (right side, stacks vertically)
local NotifLayer = new("Frame", {
    Name                   = "NotifLayer",
    Size                   = UDim2.new(0, 310, 1, 0),
    Position               = UDim2.new(1, -334, 0, 0),
    BackgroundTransparency = 1,
    ZIndex                 = 1000,
    Parent                 = ScreenGui,
})
applyList(NotifLayer, SP.sm)
new("UIPadding", {
    PaddingTop  = UDim.new(0, SP.lg),
    PaddingLeft = UDim.new(0, 4),
    Parent      = NotifLayer,
})

-- ── Theme API ────────────────────────────────────────────────────────────────
function UILib:SetTheme(name)
    local theme = THEMES[name]
    if not theme then
        warn("[UILib] Unknown theme: " .. tostring(name))
        return
    end
    _st.activeTheme = name
    _st.theme       = theme
    for _, w in ipairs(_st.windows) do
        if w._applyTheme then w:_applyTheme(theme) end
    end
end

function UILib:GetTheme()
    return _st.theme or THEMES["Dark Minimal"]
end

function UILib:GetThemeName()
    return _st.activeTheme
end

function UILib:GetThemeList()
    local list = {}
    for k in pairs(THEMES) do
        table.insert(list, k)
    end
    table.sort(list)
    return list
end

-- ── Config API ───────────────────────────────────────────────────────────────
-- FIX: named configs — each script gets its own save file.
-- Set name via UILib:SetConfigName("MyScript") before LoadConfig/SetConfig.
function UILib:SetConfigName(name)
    _st.configName = name or "default"
end

local function configFile()
    return "uilib_" .. _st.configName .. ".json"
end

function UILib:SaveConfig()
    local ok, data = pcall(HttpService.JSONEncode, HttpService, _st.configData)
    if ok then pcall(writefile, configFile(), data) end
end

function UILib:LoadConfig()
    local ok, raw = pcall(readfile, configFile())
    if not ok or not raw then return end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if ok2 and type(data) == "table" then
        _st.configData = data
    end
end

function UILib:ResetConfig()
    _st.configData = {}
    pcall(delfile, configFile())
end

function UILib:SetConfig(k, v)
    _st.configData[k] = v
    self:SaveConfig()
end

function UILib:GetConfig(k, default)
    local v = _st.configData[k]
    return (v == nil) and default or v
end

-- ── Global settings ──────────────────────────────────────────────────────────
function UILib:SetSounds(v)       _st.soundEnabled = v  end
function UILib:SetReduceMotion(v) _st.reduceMotion = v  end
function UILib:SetBlur(_v)        end  -- disabled (causes game lag)
function UILib:SetHWID(v)         _st.hwid         = v  end
function UILib:SetHWIDStatus(v)   _st.hwid_status  = v  end

function UILib:NotifyAnnouncement(msg)
    if not msg or msg == "" then return end
    if msg == _st.lastAnnouncement then return end
    _st.lastAnnouncement = msg
    self:Notify({ title = "Announcement", message = msg, type = "info", duration = 10 })
end

-- ── Maintenance kick ─────────────────────────────────────────────────────────
function UILib:KickForMaintenance(reason)
    reason = reason or "Script is under maintenance."
    self:Notify({ title = "Maintenance", message = reason, type = "warning", duration = 3 })
    task.delay(3.5, function()
        pcall(function() LP:Kick("Maintenance: " .. reason) end)
    end)
end

-- ── Debug panel ──────────────────────────────────────────────────────────────
function UILib:SetDebug(enabled)
    if enabled then
        self:_buildDebugPanel()
    elseif _st.debugPanel then
        _st.debugPanel:Destroy()
        _st.debugPanel = nil
    end
end

function UILib:_buildDebugPanel()
    if _st.debugPanel then _st.debugPanel:Destroy() end
    local T     = self:GetTheme()
    local panel = new("Frame", {
        Name                   = "DebugPanel",
        Size                   = UDim2.new(0, 220, 0, 165),
        Position               = UDim2.new(0, SP.md, 1, -(165 + SP.md)),
        BackgroundColor3       = T.Surface,
        BackgroundTransparency = 0.1,
        ZIndex                 = 900,
        Parent                 = ScreenGui,
    })
    applyCorner(panel, RADIUS.Panel)
    applyStroke(panel, T.Accent, 1)
    applyPad(panel, SP.sm, SP.sm, SP.sm, SP.sm)

    new("TextLabel", {
        Text                   = "DEBUG",
        Size                   = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        TextColor3             = T.Accent,
        Font                   = FONT.Section.font,
        TextSize               = 11,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = panel,
    })

    local list = new("Frame", {
        Size                   = UDim2.new(1, 0, 1, -22),
        Position               = UDim2.new(0, 0, 0, 22),
        BackgroundTransparency = 1,
        Parent                 = panel,
    })
    applyList(list, 3)

    local rows = {
        { "Theme",      function() return _st.activeTheme or "—" end },
        { "Config",     function() return _st.configName          end },
        { "Components", function() return tostring(_st.componentCount) end },
        { "HWID",       function() return _st.hwid:sub(1, 8) .. "…" end },
        { "Status",     function() return _st.hwid_status          end },
        { "Mobile",     function() return IS_MOBILE and "YES" or "NO" end },
    }

    local labels = {}
    for _, row in ipairs(rows) do
        local rf = new("Frame", {
            Size                   = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            Parent                 = list,
        })
        new("TextLabel", {
            Text                   = row[1] .. ":",
            Size                   = UDim2.new(0.55, 0, 1, 0),
            BackgroundTransparency = 1,
            TextColor3             = T.SubText,
            Font                   = FONT.Mono.font,
            TextSize               = 11,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = rf,
        })
        local vl = new("TextLabel", {
            Text                   = row[2](),
            Size                   = UDim2.new(0.45, 0, 1, 0),
            Position               = UDim2.new(0.55, 0, 0, 0),
            BackgroundTransparency = 1,
            TextColor3             = T.Text,
            Font                   = FONT.Mono.font,
            TextSize               = 11,
            TextXAlignment         = Enum.TextXAlignment.Right,
            Parent                 = rf,
        })
        table.insert(labels, { val = vl, fn = row[2] })
    end

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not panel or not panel.Parent then conn:Disconnect(); return end
        for _, r in ipairs(labels) do r.val.Text = r.fn() end
    end)
    _st.debugPanel = panel
end

function UILib:_debugRefresh() end

-- ── Notifications ────────────────────────────────────────────────────────────
function UILib:Notify(opts)
    opts          = opts or {}
    local T       = self:GetTheme()
    local title   = opts.title    or "Notification"
    local message = opts.message  or ""
    local ntype   = opts.type     or "info"
    local dur     = opts.duration or 4

    local accentMap = {
        info    = T.Accent,
        success = T.Success,
        warning = T.Warning,
        error   = T.Danger,
    }
    local iconMap = {
        info    = "i",
        success = "v",
        warning = "!",
        error   = "x",
    }
    local accent = accentMap[ntype] or T.Accent
    local icon   = iconMap[ntype]   or "i"

    playSound(ntype == "error" and "error" or "notify")

    local card = new("Frame", {
        Name                   = "Notif",
        Size                   = UDim2.new(1, -4, 0, 72),
        BackgroundColor3       = T.Surface,
        BackgroundTransparency = 0.06,
        ClipsDescendants       = true,
        Parent                 = NotifLayer,
    })
    applyCorner(card, RADIUS.Panel)
    applyStroke(card, T.Border, 1)

    new("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Parent           = card,
    })
    new("TextLabel", {
        Text                   = icon,
        Size                   = UDim2.new(0, 32, 1, 0),
        Position               = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        TextColor3             = accent,
        Font                   = FONT.Title.font,
        TextSize               = 16,
        Parent                 = card,
    })

    local content = new("Frame", {
        Size                   = UDim2.new(1, -48, 1, 0),
        Position               = UDim2.new(0, 46, 0, 0),
        BackgroundTransparency = 1,
        Parent                 = card,
    })
    applyList(content, 2)
    applyPad(content, SP.sm, SP.sm, SP.sm, 0)

    new("TextLabel", {
        Text                   = title,
        Size                   = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        TextColor3             = T.Text,
        Font                   = FONT.Section.font,
        TextSize               = FONT.Section.size,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = content,
    })
    new("TextLabel", {
        Text                   = message,
        Size                   = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        TextColor3             = T.SubText,
        Font                   = FONT.Body.font,
        TextSize               = FONT.Body.size,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        Parent                 = content,
    })

    local bar = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Parent           = card,
    })

    card.Position = UDim2.new(1, 20, 0, 0)
    tw(card, { Position = UDim2.new(0, 0, 0, 0) }, ANIM.Normal)
    tw(bar, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

    task.delay(dur, function()
        if not card or not card.Parent then return end
        tw(card, { Position = UDim2.new(1, 20, 0, 0) }, ANIM.Normal)
        task.delay(ANIM.Normal + 0.05, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)
end

-- ── Cursor highlight (PC only) ───────────────────────────────────────────────
function UILib:EnableCursorHighlight()
    if IS_MOBILE then return end
    local cur = new("Frame", {
        Name                   = "CursorHL",
        Size                   = UDim2.new(0, 14, 0, 14),
        BackgroundColor3       = self:GetTheme().Accent,
        BackgroundTransparency = 0.6,
        ZIndex                 = 2000,
        Parent                 = ScreenGui,
    })
    applyCorner(cur, RADIUS.Pill)
    RunService.RenderStepped:Connect(function()
        local m = UserInputService:GetMouseLocation()
        cur.Position = UDim2.new(0, m.X - 7, 0, m.Y - 7)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- WINDOW BUILDER
-- ═══════════════════════════════════════════════════════════════════════════
function UILib:CreateWindow(opts)
    opts       = opts or {}
    local T    = self:GetTheme()
    local title    = opts.title    or "UILib"
    local subtitle = opts.subtitle or ""
    local size     = opts.size     or UDim2.new(0, 540, 0, 430)
    local position = opts.position or UDim2.new(0.5, -270, 0.5, -215)

    -- Root
    local Root = new("Frame", {
        Name             = "UILib_Window",
        Size             = size,
        Position         = position,
        BackgroundColor3 = T.Background,
        ClipsDescendants = false,
        ZIndex           = 10,
        Parent           = ScreenGui,
    })
    applyCorner(Root, RADIUS.Window)
    applyStroke(Root, T.Border, 1)

    -- Drop shadow
    new("ImageLabel", {
        Name                   = "Shadow",
        Size                   = UDim2.new(1, 30, 1, 30),
        Position               = UDim2.new(0, -15, 0, -15),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://6014261993",
        ImageColor3            = Color3.fromRGB(0, 0, 0),
        ImageTransparency      = 0.55,
        ScaleType              = Enum.ScaleType.Slice,
        SliceCenter            = Rect.new(49, 49, 450, 450),
        ZIndex                 = 9,
        Parent                 = Root,
    })

    -- ── Title bar ───────────────────────────────────────────────────────────
    local TitleBar = new("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, TITLE_H),
        BackgroundColor3 = T.Surface,
        ClipsDescendants = true,
        ZIndex           = 11,
        Parent           = Root,
    })
    new("UICorner", { CornerRadius = RADIUS.Window, Parent = TitleBar })
    -- Flatten bottom corners of titlebar
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, RADIUS.Window.Offset),
        Position         = UDim2.new(0, 0, 1, -RADIUS.Window.Offset),
        BackgroundColor3 = T.Surface,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = TitleBar,
    })
    -- Bottom separator
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Border,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = TitleBar,
    })
    applyPad(TitleBar, 0, SP.md, 0, SP.md)

    new("TextLabel", {
        Text                   = title,
        Size                   = UDim2.new(0.55, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3             = T.Text,
        Font                   = FONT.Title.font,
        TextSize               = FONT.Title.size,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 12,
        Parent                 = TitleBar,
    })
    if subtitle ~= "" then
        new("TextLabel", {
            Text                   = subtitle,
            Size                   = UDim2.new(0.55, 0, 0, 14),
            Position               = UDim2.new(0, 0, 1, -16),
            BackgroundTransparency = 1,
            TextColor3             = T.SubText,
            Font                   = FONT.Small.font,
            TextSize               = FONT.Small.size,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 12,
            Parent                 = TitleBar,
        })
    end

    -- Window control buttons
    local BTN_W = IS_MOBILE and 38 or 28
    local Controls = new("Frame", {
        Size                   = UDim2.new(0, (BTN_W * 2) + SP.xs, 0, BTN_W),
        Position               = UDim2.new(1, -((BTN_W * 2) + SP.xs + SP.sm), 0.5, -BTN_W / 2),
        BackgroundTransparency = 1,
        ZIndex                 = 12,
        Parent                 = TitleBar,
    })
    applyList(Controls, SP.xs, Enum.FillDirection.Horizontal)

    local function mkCtrlBtn(icon, col)
        local b = new("TextButton", {
            Text             = icon,
            Size             = UDim2.new(0, BTN_W, 0, BTN_W),
            BackgroundColor3 = T.Elevated,
            TextColor3       = col or T.SubText,
            Font             = Enum.Font.GothamBold,
            TextSize         = IS_MOBILE and 15 or 13,
            ZIndex           = 13,
            Parent           = Controls,
        })
        applyCorner(b, RADIUS.Pill)
        b.MouseEnter:Connect(function() tw(b, { BackgroundColor3 = col or T.Border }, ANIM.Fast) end)
        b.MouseLeave:Connect(function() tw(b, { BackgroundColor3 = T.Elevated }, ANIM.Fast) end)
        return b
    end

    local MinBtn   = mkCtrlBtn("-", T.Warning)
    local CloseBtn = mkCtrlBtn("x", T.Danger)

    -- ── Tab bar ─────────────────────────────────────────────────────────────
    local TabBar = new("Frame", {
        Name             = "TabBar",
        Size             = UDim2.new(0, TAB_W, 1, -TITLE_H),
        Position         = UDim2.new(0, 0, 0, TITLE_H),
        BackgroundColor3 = T.Surface,
        ZIndex           = 11,
        Parent           = Root,
    })
    -- Fill in the right-side radius gap so tabbar looks flush
    new("Frame", {
        Size             = UDim2.new(0, RADIUS.Window.Offset, 1, 0),
        Position         = UDim2.new(1, -RADIUS.Window.Offset, 0, 0),
        BackgroundColor3 = T.Surface,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = TabBar,
    })
    applyPad(TabBar, SP.sm, 0, SP.sm, SP.sm)

    local TabList = new("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex                 = 12,
        Parent                 = TabBar,
    })
    applyList(TabList, SP.xs)

    -- Vertical separator between tabs and content
    new("Frame", {
        Size             = UDim2.new(0, 1, 1, -TITLE_H),
        Position         = UDim2.new(0, TAB_W, 0, TITLE_H),
        BackgroundColor3 = T.Border,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = Root,
    })

    -- ── Content area ────────────────────────────────────────────────────────
    local ContentArea = new("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -TAB_W, 1, -TITLE_H),
        Position         = UDim2.new(0, TAB_W, 0, TITLE_H),
        BackgroundColor3 = T.Background,
        ClipsDescendants = true,
        ZIndex           = 11,
        Parent           = Root,
    })

    -- ── Drag ────────────────────────────────────────────────────────────────
    makeDraggable(TitleBar, Root)

    -- ── Minimize / Maximize ─────────────────────────────────────────────────
    local minimized = false
    local FloatBtn  = nil
    local maximizeWindow  -- forward declaration

    local function doMinimize()
        minimized = true
        playSound("close")
        tw(Root, { Size = UDim2.new(0, size.X.Offset, 0, 0) }, ANIM.Normal)
        task.delay(ANIM.Normal, function() Root.Visible = false end)

        local fbSz = IS_MOBILE and 54 or 44
        FloatBtn = new("TextButton", {
            Name             = "FloatBtn",
            Text             = "o",
            Size             = UDim2.new(0, fbSz, 0, fbSz),
            Position         = UDim2.new(0, SP.lg, 1, -(fbSz + SP.lg)),
            BackgroundColor3 = T.Accent,
            TextColor3       = T.AccentText,
            Font             = FONT.Title.font,
            TextSize         = IS_MOBILE and 18 or 15,
            ZIndex           = 500,
            Parent           = ScreenGui,
        })
        applyCorner(FloatBtn, RADIUS.Pill)
        -- Float button is also draggable using the same system
        makeDraggable(FloatBtn, FloatBtn)
        FloatBtn.MouseButton1Click:Connect(function()
            maximizeWindow()
        end)
    end

    maximizeWindow = function()
        if not minimized then return end
        minimized = false
        if FloatBtn then FloatBtn:Destroy(); FloatBtn = nil end
        Root.Visible = true
        Root.Size    = UDim2.new(0, size.X.Offset, 0, 0)
        playSound("open")
        tw(Root, { Size = size }, ANIM.Normal)
    end

    MinBtn.MouseButton1Click:Connect(doMinimize)
    CloseBtn.MouseButton1Click:Connect(function()
        playSound("close")
        tw(Root, { Size = UDim2.new(0, size.X.Offset, 0, 0), BackgroundTransparency = 1 }, ANIM.Normal)
        task.delay(ANIM.Normal + 0.05, function()
            if FloatBtn then FloatBtn:Destroy() end
            Root:Destroy()
        end)
    end)

    -- Open animation
    Root.Size                = UDim2.new(0, size.X.Offset, 0, 0)
    Root.BackgroundTransparency = 1
    tw(Root, { Size = size, BackgroundTransparency = 0 }, ANIM.Slow)
    playSound("open")

    -- ── Window object ────────────────────────────────────────────────────────
    local Window = {
        _root      = Root,
        _titleBar  = TitleBar,
        _tabBar    = TabBar,
        _tabList   = TabList,
        _content   = ContentArea,
        _tabs      = {},
        _activeTab = nil,
        _theme     = T,
        _lib       = self,
    }

    -- ── AddTab ───────────────────────────────────────────────────────────────
    function Window:AddTab(tabOpts)
        tabOpts    = tabOpts or {}
        local T2   = self._theme
        local name = tabOpts.name or ("Tab " .. (#self._tabs + 1))
        local icon = tabOpts.icon or ""

        local tabBtn = new("TextButton", {
            Text                   = icon .. (icon ~= "" and "  " or "") .. name,
            Size                   = UDim2.new(1, -SP.sm, 0, ROW_H - 6),
            BackgroundColor3       = T2.Elevated,
            BackgroundTransparency = 1,
            TextColor3             = T2.SubText,
            Font                   = FONT.Body.font,
            TextSize               = FONT.Body.size,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 13,
            Parent                 = self._tabList,
        })
        applyCorner(tabBtn, RADIUS.Button)
        applyPad(tabBtn, 0, SP.sm, 0, SP.sm)

        local activeBar = new("Frame", {
            Size                   = UDim2.new(0, 3, 0.6, 0),
            Position               = UDim2.new(0, -SP.sm, 0.2, 0),
            BackgroundColor3       = T2.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ZIndex                 = 14,
            Parent                 = tabBtn,
        })
        applyCorner(activeBar, RADIUS.Pill)

        local tabContent = new("ScrollingFrame", {
            Name                 = "Tab_" .. name,
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel      = 0,
            ScrollBarThickness   = IS_MOBILE and 4 or 3,
            ScrollBarImageColor3 = T2.Border,
            CanvasSize           = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize  = Enum.AutomaticSize.Y,
            Visible              = false,
            ZIndex               = 12,
            Parent               = self._content,
        })
        applyPad(tabContent, SP.md, SP.md, SP.md, SP.md)
        applyList(tabContent, SP.sm)

        -- tab object
        local tab = {
            _btn        = tabBtn,
            _bar        = activeBar,
            _content    = tabContent,
            _name       = name,
            _window     = self,
            _theme      = T2,
            _components = 0,
        }

        -- ── AddSection ──────────────────────────────────────────────────────
        function tab:AddSection(opts)
            opts = opts or {}
            local lbl = new("TextLabel", {
                Text                   = (opts.name or "Section"):upper(),
                Size                   = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                TextColor3             = self._theme.SubText,
                Font                   = FONT.Small.font,
                TextSize               = FONT.Small.size,
                TextXAlignment         = Enum.TextXAlignment.Left,
                LayoutOrder            = self._components,
                Parent                 = self._content,
            })
            applyPad(lbl, 0, 0, SP.xs, 0)
            self._components       = self._components + 1
            _st.componentCount     = _st.componentCount + 1
            return lbl
        end

        -- ── AddButton ───────────────────────────────────────────────────────
        function tab:AddButton(bOpts)
            bOpts      = bOpts or {}
            local T3   = self._theme
            local cb   = bOpts.callback or function() end
            local danger = bOpts.danger or false
            local bW   = IS_MOBILE and 96 or 90
            local bH   = IS_MOBILE and 34 or 28

            local row = new("Frame", {
                Size             = UDim2.new(1, 0, 0, ROW_H),
                BackgroundColor3 = T3.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, T3.Border, 1)
            applyPad(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text                   = bOpts.label or "Button",
                Size                   = UDim2.new(0.6, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3             = T3.Text,
                Font                   = FONT.Body.font,
                TextSize               = FONT.Body.size,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = row,
            })

            local btn = new("TextButton", {
                Text             = (bOpts.desc ~= "" and bOpts.desc) or "Run",
                Size             = UDim2.new(0, bW, 0, bH),
                Position         = UDim2.new(1, -bW, 0.5, -bH / 2),
                BackgroundColor3 = danger and T3.Danger or T3.Accent,
                TextColor3       = T3.AccentText,
                Font             = FONT.Body.font,
                TextSize         = FONT.Body.size,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(btn, RADIUS.Button)

            btn.MouseEnter:Connect(function()
                tw(btn, { BackgroundColor3 = danger and Color3.fromRGB(200, 40, 40) or T3.AccentHover }, ANIM.Fast)
            end)
            btn.MouseLeave:Connect(function()
                tw(btn, { BackgroundColor3 = danger and T3.Danger or T3.Accent }, ANIM.Fast)
            end)
            btn.MouseButton1Click:Connect(function()
                playSound("click")
                tw(btn, { Size = UDim2.new(0, bW - 4, 0, bH - 4) }, ANIM.Fast)
                task.delay(ANIM.Fast, function()
                    tw(btn, { Size = UDim2.new(0, bW, 0, bH) }, ANIM.Fast)
                end)
                cb()
            end)

            self._components   = self._components + 1
            _st.componentCount = _st.componentCount + 1
            return btn
        end

        -- ── AddToggle ───────────────────────────────────────────────────────
        function tab:AddToggle(tOpts)
            tOpts      = tOpts or {}
            local T3   = self._theme
            local ck   = tOpts.configKey
            local cb   = tOpts.callback or function() end
            local enabled = (ck and UILib:GetConfig(ck, tOpts.default or false)) or (tOpts.default or false)
            local tW   = IS_MOBILE and 50 or 42
            local tH   = IS_MOBILE and 26 or 22
            local thS  = tH - 6

            local row = new("Frame", {
                Size             = UDim2.new(1, 0, 0, ROW_H),
                BackgroundColor3 = T3.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, T3.Border, 1)
            applyPad(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text                   = tOpts.label or "Toggle",
                Size                   = UDim2.new(0.7, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3             = T3.Text,
                Font                   = FONT.Body.font,
                TextSize               = FONT.Body.size,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = row,
            })

            local track = new("TextButton", {
                Text             = "",
                Size             = UDim2.new(0, tW, 0, tH),
                Position         = UDim2.new(1, -tW, 0.5, -tH / 2),
                BackgroundColor3 = enabled and T3.Accent or T3.Elevated,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(track, RADIUS.Pill)
            applyStroke(track, T3.Border, 1)

            local thumb = new("Frame", {
                Size             = UDim2.new(0, thS, 0, thS),
                Position         = enabled
                    and UDim2.new(1, -(thS + 3), 0.5, -thS / 2)
                    or  UDim2.new(0, 3, 0.5, -thS / 2),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex           = 14,
                Parent           = track,
            })
            applyCorner(thumb, RADIUS.Pill)

            local function setToggle(val, skipAnim)
                enabled = val
                local d = skipAnim and 0 or ANIM.Fast
                tw(track, { BackgroundColor3 = val and T3.Accent or T3.Elevated }, d)
                tw(thumb, {
                    Position = val
                        and UDim2.new(1, -(thS + 3), 0.5, -thS / 2)
                        or  UDim2.new(0, 3, 0.5, -thS / 2),
                }, d)
            end

            track.MouseButton1Click:Connect(function()
                playSound("toggle")
                setToggle(not enabled)
                if ck then UILib:SetConfig(ck, enabled) end
                cb(enabled)
            end)

            self._components   = self._components + 1
            _st.componentCount = _st.componentCount + 1
            return {
                Set = function(v) setToggle(v) end,
                Get = function() return enabled end,
            }
        end

        -- ── AddSlider ───────────────────────────────────────────────────────
        function tab:AddSlider(sOpts)
            sOpts    = sOpts or {}
            local T3 = self._theme
            local mn = sOpts.min    or 0
            local mx = sOpts.max    or 100
            local stp = sOpts.step  or 1
            local sfx = sOpts.suffix or ""
            local ck = sOpts.configKey
            local cb = sOpts.callback or function() end
            local val = math.clamp(
                (ck and UILib:GetConfig(ck, sOpts.default or mn)) or (sOpts.default or mn),
                mn, mx
            )
            local tH   = IS_MOBILE and 8 or 6
            local thSz = IS_MOBILE and 18 or 14

            local row = new("Frame", {
                Size             = UDim2.new(1, 0, 0, IS_MOBILE and 62 or 54),
                BackgroundColor3 = T3.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, T3.Border, 1)
            applyPad(row, SP.sm, SP.md, SP.sm, SP.md)

            local hdr = new("Frame", {
                Size                   = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Parent                 = row,
            })
            new("TextLabel", {
                Text                   = sOpts.label or "Slider",
                Size                   = UDim2.new(0.7, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3             = T3.Text,
                Font                   = FONT.Body.font,
                TextSize               = FONT.Body.size,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = hdr,
            })
            local valLbl = new("TextLabel", {
                Text                   = tostring(val) .. sfx,
                Size                   = UDim2.new(0.3, 0, 1, 0),
                Position               = UDim2.new(0.7, 0, 0, 0),
                BackgroundTransparency = 1,
                TextColor3             = T3.Accent,
                Font                   = FONT.Section.font,
                TextSize               = FONT.Body.size,
                TextXAlignment         = Enum.TextXAlignment.Right,
                Parent                 = hdr,
            })

            local trkF = new("Frame", {
                Size             = UDim2.new(1, 0, 0, tH),
                Position         = UDim2.new(0, 0, 1, -tH),
                BackgroundColor3 = T3.Elevated,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(trkF, RADIUS.Pill)

            local fillF = new("Frame", {
                Size             = UDim2.new((val - mn) / (mx - mn), 0, 1, 0),
                BackgroundColor3 = T3.Accent,
                ZIndex           = 14,
                Parent           = trkF,
            })
            applyCorner(fillF, RADIUS.Pill)

            local thumbSl = new("Frame", {
                Size             = UDim2.new(0, thSz, 0, thSz),
                Position         = UDim2.new((val - mn) / (mx - mn), 0, 0.5, -thSz / 2),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ZIndex           = 15,
                Parent           = trkF,
            })
            applyCorner(thumbSl, RADIUS.Pill)

            local function setSlider(v, silent)
                v   = math.clamp(math.round((v - mn) / stp) * stp + mn, mn, mx)
                val = v
                local pct = (v - mn) / (mx - mn)
                tw(fillF,   { Size     = UDim2.new(pct, 0, 1, 0) }, ANIM.Fast)
                tw(thumbSl, { Position = UDim2.new(pct, 0, 0.5, -thSz / 2) }, ANIM.Fast)
                valLbl.Text = tostring(v) .. sfx
                if ck then UILib:SetConfig(ck, v) end
                if not silent then cb(v) end
            end

            local slDragging = false
            trkF.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    slDragging = true
                    local abs  = trkF.AbsolutePosition
                    local sz   = trkF.AbsoluteSize
                    setSlider(mn + math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1) * (mx - mn))
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    slDragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if slDragging and (
                    inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch
                ) then
                    local abs = trkF.AbsolutePosition
                    local sz  = trkF.AbsoluteSize
                    setSlider(mn + math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1) * (mx - mn))
                end
            end)

            self._components   = self._components + 1
            _st.componentCount = _st.componentCount + 1
            return {
                Set = function(v) setSlider(v, true) end,
                Get = function() return val end,
            }
        end

        -- ── AddDropdown ─────────────────────────────────────────────────────
        -- FIX: uses a ScrollingFrame so any number of items work without clipping
        function tab:AddDropdown(dOpts)
            dOpts      = dOpts or {}
            local T3   = self._theme
            local items = dOpts.items or {}
            local ck   = dOpts.configKey
            local cb   = dOpts.callback or function() end
            local sel  = (ck and UILib:GetConfig(ck, dOpts.default or items[1] or ""))
                         or (dOpts.default or items[1] or "")
            local ddOpen = false
            local tW   = 0.50
            local tHH  = IS_MOBILE and 34 or 28

            -- Max visible items before scroll kicks in
            local ITEM_H     = IS_MOBILE and 38 or 30
            local MAX_SHOW   = 5
            local MAX_HEIGHT = MAX_SHOW * ITEM_H + SP.xs * 2

            local row = new("Frame", {
                Size             = UDim2.new(1, 0, 0, ROW_H),
                BackgroundColor3 = T3.Surface,
                ZIndex           = 20,
                LayoutOrder      = self._components,
                ClipsDescendants = false,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, T3.Border, 1)
            applyPad(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text                   = dOpts.label or "Dropdown",
                Size                   = UDim2.new(0.48, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3             = T3.Text,
                Font                   = FONT.Body.font,
                TextSize               = FONT.Body.size,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = row,
            })

            local trigger = new("TextButton", {
                Text             = sel .. " v",
                Size             = UDim2.new(tW, 0, 0, tHH),
                Position         = UDim2.new(1 - tW, 0, 0.5, -tHH / 2),
                BackgroundColor3 = T3.Elevated,
                TextColor3       = T3.Text,
                Font             = FONT.Body.font,
                TextSize         = FONT.Body.size,
                ZIndex           = 21,
                Parent           = row,
            })
            applyCorner(trigger, RADIUS.Button)
            applyStroke(trigger, T3.Border, 1)

            -- FIX: ScrollingFrame dropdown so long lists don't get clipped
            local totalH = math.min(#items * ITEM_H + SP.xs * 2, MAX_HEIGHT)

            local dropScroll = new("ScrollingFrame", {
                Size                 = UDim2.new(tW, 0, 0, 0),
                Position             = UDim2.new(1 - tW, 0, 1, 4),
                BackgroundColor3     = T3.Elevated,
                BorderSizePixel      = 0,
                ScrollBarThickness   = 3,
                ScrollBarImageColor3 = T3.Border,
                CanvasSize           = UDim2.new(0, 0, 0, #items * ITEM_H + SP.xs * 2),
                ClipsDescendants     = true,
                ZIndex               = 100,
                Visible              = false,
                Parent               = row,
            })
            applyCorner(dropScroll, RADIUS.Button)
            applyStroke(dropScroll, T3.Border, 1)

            local inner = new("Frame", {
                Size                   = UDim2.new(1, 0, 0, 0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent                 = dropScroll,
            })
            applyList(inner, 2)
            applyPad(inner, SP.xs, SP.xs, SP.xs, SP.xs)

            for _, item in ipairs(items) do
                local opt = new("TextButton", {
                    Text                   = item,
                    Size                   = UDim2.new(1, 0, 0, ITEM_H),
                    BackgroundTransparency = 1,
                    TextColor3             = T3.SubText,
                    Font                   = FONT.Body.font,
                    TextSize               = FONT.Body.size,
                    ZIndex                 = 101,
                    Parent                 = inner,
                })
                applyCorner(opt, RADIUS.Tag)
                opt.MouseEnter:Connect(function()
                    tw(opt, { BackgroundTransparency = 0.7, TextColor3 = T3.Text }, ANIM.Fast)
                    opt.BackgroundColor3 = T3.Border
                end)
                opt.MouseLeave:Connect(function()
                    tw(opt, { BackgroundTransparency = 1, TextColor3 = T3.SubText }, ANIM.Fast)
                end)
                opt.MouseButton1Click:Connect(function()
                    sel          = item
                    trigger.Text = item .. " v"
                    if ck then UILib:SetConfig(ck, item) end
                    cb(item)
                    playSound("click")
                    -- Close
                    tw(dropScroll, { Size = UDim2.new(tW, 0, 0, 0) }, ANIM.Fast)
                    task.delay(ANIM.Fast, function() dropScroll.Visible = false end)
                    ddOpen = false
                end)
            end

            trigger.MouseButton1Click:Connect(function()
                playSound("click")
                ddOpen = not ddOpen
                if ddOpen then
                    dropScroll.Visible = true
                    tw(dropScroll, { Size = UDim2.new(tW, 0, 0, totalH) }, ANIM.Normal)
                else
                    tw(dropScroll, { Size = UDim2.new(tW, 0, 0, 0) }, ANIM.Fast)
                    task.delay(ANIM.Fast, function() dropScroll.Visible = false end)
                end
            end)

            self._components   = self._components + 1
            _st.componentCount = _st.componentCount + 1
            return {
                Set = function(v) sel = v; trigger.Text = v .. " v" end,
                Get = function() return sel end,
            }
        end

        -- ── AddKeybind ──────────────────────────────────────────────────────
        function tab:AddKeybind(kOpts)
            kOpts    = kOpts or {}
            local T3 = self._theme
            local ck = kOpts.configKey
            local cb = kOpts.callback or function() end
            local def = kOpts.default or Enum.KeyCode.Unknown
            local currentKey = (ck and Enum.KeyCode[UILib:GetConfig(ck, def.Name)]) or def
            local listening  = false
            local kW = IS_MOBILE and 100 or 90
            local kH = IS_MOBILE and 34  or 28

            local row = new("Frame", {
                Size             = UDim2.new(1, 0, 0, ROW_H),
                BackgroundColor3 = T3.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, T3.Border, 1)
            applyPad(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text                   = kOpts.label or "Keybind",
                Size                   = UDim2.new(0.6, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3             = T3.Text,
                Font                   = FONT.Body.font,
                TextSize               = FONT.Body.size,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = row,
            })

            local kBtn = new("TextButton", {
                Text             = "[" .. currentKey.Name .. "]",
                Size             = UDim2.new(0, kW, 0, kH),
                Position         = UDim2.new(1, -kW, 0.5, -kH / 2),
                BackgroundColor3 = T3.Elevated,
                TextColor3       = T3.Accent,
                Font             = FONT.Mono.font,
                TextSize         = 12,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(kBtn, RADIUS.Button)
            applyStroke(kBtn, T3.Border, 1)

            kBtn.MouseButton1Click:Connect(function()
                listening   = true
                kBtn.Text   = "[ ... ]"
                tw(kBtn, { BackgroundColor3 = T3.Accent }, ANIM.Fast)
            end)
            UserInputService.InputBegan:Connect(function(inp, gp)
                if gp or not listening then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    listening    = false
                    currentKey   = inp.KeyCode
                    kBtn.Text    = "[" .. inp.KeyCode.Name .. "]"
                    tw(kBtn, { BackgroundColor3 = T3.Elevated }, ANIM.Fast)
                    if ck then UILib:SetConfig(ck, inp.KeyCode.Name) end
                    playSound("click")
                end
            end)
            UserInputService.InputBegan:Connect(function(inp, gp)
                if gp or listening then return end
                if inp.KeyCode == currentKey then cb(currentKey) end
            end)

            self._components   = self._components + 1
            _st.componentCount = _st.componentCount + 1
            return {
                Set = function(key) currentKey = key; kBtn.Text = "[" .. key.Name .. "]" end,
                Get = function() return currentKey end,
            }
        end

        -- ── AddColorPicker ──────────────────────────────────────────────────
        function tab:AddColorPicker(cOpts)
            cOpts    = cOpts or {}
            local T3 = self._theme
            local ck = cOpts.configKey
            local cb = cOpts.callback or function() end
            local cur = cOpts.default or Color3.fromRGB(99, 102, 241)
            local swW = IS_MOBILE and 64 or 56
            local swH = IS_MOBILE and 34 or 28

            local row = new("Frame", {
                Size             = UDim2.new(1, 0, 0, ROW_H),
                BackgroundColor3 = T3.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, T3.Border, 1)
            applyPad(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text                   = cOpts.label or "Color",
                Size                   = UDim2.new(0.6, 0, 1, 0),
                BackgroundTransparency = 1,
                TextColor3             = T3.Text,
                Font                   = FONT.Body.font,
                TextSize               = FONT.Body.size,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = row,
            })

            local swatch = new("TextButton", {
                Text             = "",
                Size             = UDim2.new(0, swW, 0, swH),
                Position         = UDim2.new(1, -swW, 0.5, -swH / 2),
                BackgroundColor3 = cur,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(swatch, RADIUS.Button)
            applyStroke(swatch, T3.Border, 1)

            local pickerOpen  = false
            local pickerFrame = nil

            swatch.MouseButton1Click:Connect(function()
                pickerOpen = not pickerOpen
                if not pickerOpen then
                    if pickerFrame then pickerFrame:Destroy(); pickerFrame = nil end
                    return
                end
                if pickerFrame then pickerFrame:Destroy() end

                local hbH  = IS_MOBILE and 28 or 22
                local pckH = SP.sm + hbH + 4 + (IS_MOBILE and 28 or 22) + SP.sm

                pickerFrame = new("Frame", {
                    Size             = UDim2.new(1, 0, 0, pckH),
                    Position         = UDim2.new(0, 0, 1, 4),
                    BackgroundColor3 = T3.Elevated,
                    ZIndex           = 50,
                    Parent           = row,
                })
                applyCorner(pickerFrame, RADIUS.Button)
                applyStroke(pickerFrame, T3.Border, 1)

                local hueBar = new("Frame", {
                    Size             = UDim2.new(1, -(SP.md * 2), 0, hbH),
                    Position         = UDim2.new(0, SP.md, 0, SP.sm),
                    BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                    ZIndex           = 51,
                    Parent           = pickerFrame,
                })
                applyCorner(hueBar, RADIUS.Tag)
                new("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0, 0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 0, 0)),
                    }),
                    Parent = hueBar,
                })

                local hueH, _, _ = cur:ToHSV()
                local hueDrag = false
                hueBar.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        hueDrag = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        hueDrag = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if hueDrag then
                        local abs = hueBar.AbsolutePosition
                        local sz  = hueBar.AbsoluteSize
                        hueH = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
                        cur  = Color3.fromHSV(hueH, 1, 1)
                        swatch.BackgroundColor3 = cur
                        if ck then UILib:SetConfig(ck, { cur.R, cur.G, cur.B }) end
                        cb(cur)
                    end
                end)

                -- Preset swatches
                local presets = {
                    Color3.fromRGB(239, 68, 68),
                    Color3.fromRGB(249, 115, 22),
                    Color3.fromRGB(234, 179, 8),
                    Color3.fromRGB(34, 197, 94),
                    Color3.fromRGB(56, 189, 248),
                    Color3.fromRGB(99, 102, 241),
                    Color3.fromRGB(168, 85, 247),
                    Color3.fromRGB(255, 255, 255),
                }
                local psY     = SP.sm + hbH + 4
                local psRow   = new("Frame", {
                    Size                   = UDim2.new(1, -(SP.md * 2), 0, IS_MOBILE and 28 or 22),
                    Position               = UDim2.new(0, SP.md, 0, psY),
                    BackgroundTransparency = 1,
                    ZIndex                 = 51,
                    Parent                 = pickerFrame,
                })
                applyList(psRow, SP.xs, Enum.FillDirection.Horizontal)

                for _, pr in ipairs(presets) do
                    local psz = IS_MOBILE and 26 or 22
                    local ps  = new("TextButton", {
                        Text             = "",
                        Size             = UDim2.new(0, psz, 0, psz),
                        BackgroundColor3 = pr,
                        ZIndex           = 52,
                        Parent           = psRow,
                    })
                    applyCorner(ps, RADIUS.Tag)
                    ps.MouseButton1Click:Connect(function()
                        cur = pr
                        swatch.BackgroundColor3 = pr
                        if ck then UILib:SetConfig(ck, { pr.R, pr.G, pr.B }) end
                        cb(pr)
                    end)
                end
            end)

            self._components   = self._components + 1
            _st.componentCount = _st.componentCount + 1
            return {
                Set = function(c) cur = c; swatch.BackgroundColor3 = c end,
                Get = function() return cur end,
            }
        end

        -- Tab select logic
        function tab:Select()
            local win = self._window
            for _, t in ipairs(win._tabs) do
                t._content.Visible = false
                tw(t._btn, { TextColor3 = win._theme.SubText, BackgroundTransparency = 1 }, ANIM.Fast)
                tw(t._bar, { BackgroundTransparency = 1 }, ANIM.Fast)
            end
            self._content.Visible = true
            tw(self._btn, {
                TextColor3             = win._theme.Text,
                BackgroundTransparency = 0.85,
                BackgroundColor3       = win._theme.Elevated,
            }, ANIM.Fast)
            tw(self._bar, { BackgroundTransparency = 0 }, ANIM.Fast)
            win._activeTab = self
        end

        tabBtn.MouseButton1Click:Connect(function()
            playSound("click")
            tab:Select()
        end)
        tabBtn.MouseEnter:Connect(function()
            if self._window._activeTab ~= tab then
                tw(tabBtn, { TextColor3 = T2.Text, BackgroundTransparency = 0.92 }, ANIM.Fast)
                tabBtn.BackgroundColor3 = T2.Elevated
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if self._window._activeTab ~= tab then
                tw(tabBtn, { TextColor3 = T2.SubText, BackgroundTransparency = 1 }, ANIM.Fast)
            end
        end)

        table.insert(self._tabs, tab)
        if #self._tabs == 1 then
            task.defer(function() tab:Select() end)
        end
        return tab
    end -- Window:AddTab

    function Window:_applyTheme(theme)
        self._theme = theme
        tw(self._root,     { BackgroundColor3 = theme.Background }, ANIM.Normal)
        tw(self._titleBar, { BackgroundColor3 = theme.Surface    }, ANIM.Normal)
        tw(self._tabBar,   { BackgroundColor3 = theme.Surface    }, ANIM.Normal)
        tw(self._content,  { BackgroundColor3 = theme.Background }, ANIM.Normal)
    end

    -- Optional FPS/ping overlay
    function Window:AddFPSPanel()
        local T2 = self._theme
        local panel = new("Frame", {
            Name                   = "FPSPanel",
            Size                   = UDim2.new(0, 110, 0, 34),
            Position               = UDim2.new(1, -116, 1, -40),
            BackgroundColor3       = T2.Surface,
            BackgroundTransparency = 0.1,
            ZIndex                 = 500,
            Parent                 = ScreenGui,
        })
        applyCorner(panel, RADIUS.Button)
        applyStroke(panel, T2.Border, 1)
        applyPad(panel, 0, SP.sm, 0, SP.sm)

        local fpsLbl = new("TextLabel", {
            Text                   = "FPS: -",
            Size                   = UDim2.new(0.5, 0, 1, 0),
            BackgroundTransparency = 1,
            TextColor3             = T2.Text,
            Font                   = FONT.Mono.font,
            TextSize               = 11,
            TextXAlignment         = Enum.TextXAlignment.Left,
            Parent                 = panel,
        })
        local pingLbl = new("TextLabel", {
            Text                   = "PING: -",
            Size                   = UDim2.new(0.5, 0, 1, 0),
            Position               = UDim2.new(0.5, 0, 0, 0),
            BackgroundTransparency = 1,
            TextColor3             = T2.SubText,
            Font                   = FONT.Mono.font,
            TextSize               = 11,
            TextXAlignment         = Enum.TextXAlignment.Right,
            Parent                 = panel,
        })

        local frames  = 0
        local elapsed = 0
        RunService.Heartbeat:Connect(function(dt)
            frames  = frames  + 1
            elapsed = elapsed + dt
            if elapsed >= 0.5 then
                fpsLbl.Text = "FPS: " .. math.round(frames / elapsed)
                frames      = 0
                elapsed     = 0
            end
            local ping = 0
            pcall(function() ping = math.round(LP:GetNetworkPing() * 1000) end)
            pingLbl.Text = "PING: " .. ping
        end)
        return panel
    end

    table.insert(_st.windows, Window)
    return Window
end -- UILib:CreateWindow

-- ── Init ─────────────────────────────────────────────────────────────────────
UILib:SetTheme("Dark Minimal")
return UILib

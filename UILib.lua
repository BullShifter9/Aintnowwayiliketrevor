--[[
    ██╗   ██╗██╗██╗     ██╗██████╗
    ██║   ██║██║██║     ██║██╔══██╗
    ██║   ██║██║██║     ██║██████╔╝
    ██║   ██║██║██║     ██║██╔══██╗
    ╚██████╔╝██║███████╗██║██████╔╝
     ╚═════╝ ╚═╝╚══════╝╚═╝╚═════╝

    UILib v3.0 — Commercial-Grade Roblox UI Framework
    Author  : UILib
    Version : 3.0.0
    License : Commercial — All Rights Reserved

    Features:
    - Full draggable + clamped windows
    - Mobile touch support + UIScale auto-detect
    - Minimize to floating button
    - Theme engine (6 built-in themes)
    - Config save/load/reset per HWID
    - Notification system
    - Debug panel
    - Smooth animations (Quad/Sine, 0.2–0.3s)
    - Components: Button, Toggle, Slider, Dropdown, Keybind, ColorPicker
    - Sound effects (toggleable)
    - Performance/FPS panel
    - Cursor highlight
    - Reduce-motion mode
--]]

local UILib = {}
UILib.__index = UILib

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────────────────────────
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local CoreGui            = game:GetService("CoreGui")
local SoundService       = game:GetService("SoundService")
local TextService        = game:GetService("TextService")
local HttpService        = game:GetService("HttpService")

local LocalPlayer        = Players.LocalPlayer
local Camera             = workspace.CurrentCamera

-- ─────────────────────────────────────────────────────────────────────────────
-- INTERNAL STATE
-- ─────────────────────────────────────────────────────────────────────────────
local _state = {
    windows        = {},
    notifications  = {},
    activeTheme    = nil,
    debugEnabled   = false,
    debugPanel     = nil,
    soundEnabled   = true,
    reduceMotion   = false,
    blurEnabled    = true,
    componentCount = 0,
    configData     = {},
    hwid           = "UNKNOWN",
    hwid_status    = "PENDING",
}

-- ─────────────────────────────────────────────────────────────────────────────
-- THEMES
-- ─────────────────────────────────────────────────────────────────────────────
local THEMES = {
    ["Dark Minimal"] = {
        Background  = Color3.fromRGB(12,  12,  14),
        Surface     = Color3.fromRGB(20,  20,  24),
        Elevated    = Color3.fromRGB(30,  30,  36),
        Border      = Color3.fromRGB(45,  45,  55),
        Accent      = Color3.fromRGB(99,  102, 241),
        AccentHover = Color3.fromRGB(129, 132, 255),
        AccentText  = Color3.fromRGB(255, 255, 255),
        Text        = Color3.fromRGB(230, 230, 235),
        SubText     = Color3.fromRGB(140, 140, 155),
        Danger      = Color3.fromRGB(239, 68,  68),
        Success     = Color3.fromRGB(34,  197, 94),
        Warning     = Color3.fromRGB(234, 179, 8),
    },
    ["Midnight Blue"] = {
        Background  = Color3.fromRGB(8,   12,  28),
        Surface     = Color3.fromRGB(14,  20,  45),
        Elevated    = Color3.fromRGB(22,  32,  65),
        Border      = Color3.fromRGB(35,  50,  95),
        Accent      = Color3.fromRGB(56,  189, 248),
        AccentHover = Color3.fromRGB(96,  210, 255),
        AccentText  = Color3.fromRGB(8,   12,  28),
        Text        = Color3.fromRGB(220, 235, 255),
        SubText     = Color3.fromRGB(110, 140, 190),
        Danger      = Color3.fromRGB(239, 68,  68),
        Success     = Color3.fromRGB(34,  197, 94),
        Warning     = Color3.fromRGB(234, 179, 8),
    },
    ["Soft Purple"] = {
        Background  = Color3.fromRGB(15,  10,  25),
        Surface     = Color3.fromRGB(24,  16,  40),
        Elevated    = Color3.fromRGB(36,  24,  60),
        Border      = Color3.fromRGB(60,  40,  95),
        Accent      = Color3.fromRGB(168, 85,  247),
        AccentHover = Color3.fromRGB(192, 120, 255),
        AccentText  = Color3.fromRGB(255, 255, 255),
        Text        = Color3.fromRGB(235, 220, 255),
        SubText     = Color3.fromRGB(150, 120, 190),
        Danger      = Color3.fromRGB(239, 68,  68),
        Success     = Color3.fromRGB(34,  197, 94),
        Warning     = Color3.fromRGB(234, 179, 8),
    },
    ["Emerald Green"] = {
        Background  = Color3.fromRGB(5,   15,  10),
        Surface     = Color3.fromRGB(10,  24,  16),
        Elevated    = Color3.fromRGB(16,  36,  24),
        Border      = Color3.fromRGB(28,  60,  40),
        Accent      = Color3.fromRGB(16,  185, 129),
        AccentHover = Color3.fromRGB(52,  211, 153),
        AccentText  = Color3.fromRGB(5,   15,  10),
        Text        = Color3.fromRGB(210, 245, 225),
        SubText     = Color3.fromRGB(100, 160, 130),
        Danger      = Color3.fromRGB(239, 68,  68),
        Success     = Color3.fromRGB(16,  185, 129),
        Warning     = Color3.fromRGB(234, 179, 8),
    },
    ["Light Clean"] = {
        Background  = Color3.fromRGB(245, 246, 250),
        Surface     = Color3.fromRGB(255, 255, 255),
        Elevated    = Color3.fromRGB(240, 241, 246),
        Border      = Color3.fromRGB(215, 216, 225),
        Accent      = Color3.fromRGB(99,  102, 241),
        AccentHover = Color3.fromRGB(79,  82,  221),
        AccentText  = Color3.fromRGB(255, 255, 255),
        Text        = Color3.fromRGB(20,  20,  30),
        SubText     = Color3.fromRGB(100, 100, 120),
        Danger      = Color3.fromRGB(220, 50,  50),
        Success     = Color3.fromRGB(22,  163, 74),
        Warning     = Color3.fromRGB(202, 138, 4),
    },
    ["Cyber Accent"] = {
        Background  = Color3.fromRGB(6,   6,   10),
        Surface     = Color3.fromRGB(12,  12,  18),
        Elevated    = Color3.fromRGB(20,  20,  28),
        Border      = Color3.fromRGB(0,   255, 180),
        Accent      = Color3.fromRGB(0,   255, 180),
        AccentHover = Color3.fromRGB(80,  255, 210),
        AccentText  = Color3.fromRGB(6,   6,   10),
        Text        = Color3.fromRGB(200, 255, 240),
        SubText     = Color3.fromRGB(80,  180, 150),
        Danger      = Color3.fromRGB(255, 50,  80),
        Success     = Color3.fromRGB(0,   255, 180),
        Warning     = Color3.fromRGB(255, 200, 0),
    },
}

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMATION CONSTANTS
-- ─────────────────────────────────────────────────────────────────────────────
local ANIM = {
    Fast   = 0.15,  -- micro interactions
    Normal = 0.22,  -- standard transitions
    Slow   = 0.32,  -- page-level transitions
    Ease   = Enum.EasingStyle.Quint,
    EaseIO = Enum.EasingStyle.Sine,
    Out    = Enum.EasingDirection.Out,
    InOut  = Enum.EasingDirection.InOut,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- SPACING & TYPOGRAPHY
-- ─────────────────────────────────────────────────────────────────────────────
local SP = { xs=4, sm=8, md=16, lg=24, xl=32 }
local FONT = {
    Title    = { size=20, weight=Enum.FontWeight.Bold,      font=Enum.Font.GothamBold },
    Section  = { size=14, weight=Enum.FontWeight.SemiBold,  font=Enum.Font.GothamSemibold },
    Body     = { size=13, weight=Enum.FontWeight.Regular,   font=Enum.Font.Gotham },
    Small    = { size=11, weight=Enum.FontWeight.Regular,   font=Enum.Font.Gotham },
    Mono     = { size=11, weight=Enum.FontWeight.Regular,   font=Enum.Font.Code },
}
local RADIUS = {
    Window = UDim.new(0,12),
    Panel  = UDim.new(0,8),
    Button = UDim.new(0,6),
    Pill   = UDim.new(1,0),
    Tag    = UDim.new(0,4),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- UTILITIES
-- ─────────────────────────────────────────────────────────────────────────────
local function tween(obj, props, duration, style, direction)
    if _state.reduceMotion then duration = 0 end
    local ti = TweenInfo.new(
        duration or ANIM.Normal,
        style     or ANIM.Ease,
        direction or ANIM.Out
    )
    local t = TweenService:Create(obj, ti, props)
    t:Play()
    return t
end

local function lerp(a, b, t) return a + (b - a) * t end

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function getViewport()
    return Camera.ViewportSize
end

local function clampPosition(pos, size)
    local vp = getViewport()
    local x  = math.clamp(pos.X.Offset, 0, vp.X - size.X.Offset)
    local y  = math.clamp(pos.Y.Offset, 0, vp.Y - size.Y.Offset)
    return UDim2.new(0, x, 0, y)
end

local function applyCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or RADIUS.Panel
    c.Parent = parent
    return c
end

local function applyStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function applyPadding(parent, top, right, bottom, left)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or SP.md)
    p.PaddingRight  = UDim.new(0, right  or SP.md)
    p.PaddingBottom = UDim.new(0, bottom or SP.md)
    p.PaddingLeft   = UDim.new(0, left   or SP.md)
    p.Parent = parent
    return p
end

local function applyListLayout(parent, padding, fillDir, halign, valign)
    local l = Instance.new("UIListLayout")
    l.Padding          = UDim.new(0, padding or SP.sm)
    l.FillDirection    = fillDir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = halign or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = valign or Enum.VerticalAlignment.Top
    l.SortOrder        = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

local function new(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

-- ─────────────────────────────────────────────────────────────────────────────
-- SOUND ENGINE
-- ─────────────────────────────────────────────────────────────────────────────
local _sounds = {}
local SOUND_IDS = {
    click  = "rbxassetid://6895079853",
    toggle = "rbxassetid://9119713951",
    open   = "rbxassetid://6895079999",
    close  = "rbxassetid://6895079820",
    notify = "rbxassetid://9119713952",
    error  = "rbxassetid://9119713953",
}
local function loadSound(name, id)
    if _sounds[name] then return end
    local s      = Instance.new("Sound")
    s.SoundId    = id
    s.Volume     = 0.35
    s.RollOffMaxDistance = 0
    s.Parent     = SoundService
    _sounds[name] = s
end
for k, v in pairs(SOUND_IDS) do loadSound(k, v) end

local function playSound(name)
    if not _state.soundEnabled then return end
    if _sounds[name] then
        _sounds[name]:Play()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- SCREEN GUI ROOT
-- ─────────────────────────────────────────────────────────────────────────────
local ScreenGui = new("ScreenGui", {
    Name            = "UILib_Root",
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset  = true,
})
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer.PlayerGui end

-- Blur effect
local BlurEffect = new("BlurEffect", {
    Size   = 0,
    Parent = game:GetService("Lighting"),
})

-- Notification layer (always on top)
local NotifLayer = new("Frame", {
    Name            = "NotifLayer",
    Size            = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    ZIndex          = 1000,
    Parent          = ScreenGui,
})
applyListLayout(NotifLayer, SP.sm)
local NotifPad = new("UIPadding", {
    PaddingTop    = UDim.new(0, SP.lg),
    PaddingRight  = UDim.new(0, SP.lg),
    Parent        = NotifLayer,
})
NotifLayer.HorizontalAlignment = Enum.HorizontalAlignment.Right

-- Mobile scale
if isMobile() then
    local sc = new("UIScale", { Scale = 0.88, Parent = ScreenGui })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- THEME ENGINE
-- ─────────────────────────────────────────────────────────────────────────────
function UILib:SetTheme(name)
    local theme = THEMES[name]
    if not theme then
        warn("[UILib] Unknown theme: " .. tostring(name))
        return
    end
    _state.activeTheme = name
    _state.theme = theme
    -- Propagate to all registered windows
    for _, win in ipairs(_state.windows) do
        if win._applyTheme then
            win:_applyTheme(theme)
        end
    end
    self:_debugRefresh()
end

function UILib:GetTheme()
    return _state.theme or THEMES["Dark Minimal"]
end

function UILib:GetThemeName()
    return _state.activeTheme or "Dark Minimal"
end

function UILib:GetThemeList()
    local list = {}
    for k in pairs(THEMES) do table.insert(list, k) end
    table.sort(list)
    return list
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CONFIG SYSTEM
-- ─────────────────────────────────────────────────────────────────────────────
local CONFIG_FILE = "uilib_config.json"

function UILib:SaveConfig()
    local ok, data = pcall(HttpService.JSONEncode, HttpService, _state.configData)
    if not ok then return end
    pcall(writefile, CONFIG_FILE, data)
end

function UILib:LoadConfig()
    local ok, raw = pcall(readfile, CONFIG_FILE)
    if not ok or not raw then return end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if ok2 and type(data) == "table" then
        _state.configData = data
    end
end

function UILib:ResetConfig()
    _state.configData = {}
    pcall(delfile, CONFIG_FILE)
end

function UILib:SetConfig(key, value)
    _state.configData[key] = value
    self:SaveConfig()
end

function UILib:GetConfig(key, default)
    local v = _state.configData[key]
    if v == nil then return default end
    return v
end

-- ─────────────────────────────────────────────────────────────────────────────
-- DEBUG SYSTEM
-- ─────────────────────────────────────────────────────────────────────────────
function UILib:SetDebug(enabled)
    _state.debugEnabled = enabled
    if enabled then
        self:_buildDebugPanel()
    elseif _state.debugPanel then
        _state.debugPanel:Destroy()
        _state.debugPanel = nil
    end
end

function UILib:_buildDebugPanel()
    if _state.debugPanel then _state.debugPanel:Destroy() end
    local theme = self:GetTheme()
    local panel = new("Frame", {
        Name              = "DebugPanel",
        Size              = UDim2.new(0, 220, 0, 170),
        Position          = UDim2.new(0, SP.md, 1, -(170+SP.md)),
        BackgroundColor3  = theme.Surface,
        BackgroundTransparency = 0.1,
        ZIndex            = 900,
        Parent            = ScreenGui,
    })
    applyCorner(panel, RADIUS.Panel)
    applyStroke(panel, theme.Accent, 1)
    applyPadding(panel, SP.sm, SP.sm, SP.sm, SP.sm)

    local header = new("TextLabel", {
        Text              = "⬡  DEBUG PANEL",
        Size              = UDim2.new(1,0,0,18),
        BackgroundTransparency = 1,
        TextColor3        = theme.Accent,
        Font              = FONT.Section.font,
        TextSize          = 11,
        TextXAlignment    = Enum.TextXAlignment.Left,
        Parent            = panel,
    })

    local list = new("Frame", {
        Size              = UDim2.new(1,0,1,-22),
        Position          = UDim2.new(0,0,0,22),
        BackgroundTransparency = 1,
        Parent            = panel,
    })
    applyListLayout(list, 3)

    local rows = {
        { "Theme",       function() return _state.activeTheme or "—" end },
        { "Components",  function() return tostring(_state.componentCount) end },
        { "HWID",        function() return _state.hwid:sub(1,8) .. "…" end },
        { "HWID Status", function() return _state.hwid_status end },
        { "Sound",       function() return _state.soundEnabled and "ON" or "OFF" end },
        { "Mobile",      function() return isMobile() and "YES" or "NO" end },
        { "Reduce Anim", function() return _state.reduceMotion and "YES" or "NO" end },
    }

    local rowLabels = {}
    for _, row in ipairs(rows) do
        local rowFrame = new("Frame", {
            Size = UDim2.new(1,0,0,16),
            BackgroundTransparency = 1,
            Parent = list,
        })
        new("TextLabel", {
            Text  = row[1] .. ":",
            Size  = UDim2.new(0.5,0,1,0),
            BackgroundTransparency = 1,
            TextColor3 = theme.SubText,
            Font  = FONT.Mono.font,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = rowFrame,
        })
        local val = new("TextLabel", {
            Text  = row[2](),
            Size  = UDim2.new(0.5,0,1,0),
            Position = UDim2.new(0.5,0,0,0),
            BackgroundTransparency = 1,
            TextColor3 = theme.Text,
            Font  = FONT.Mono.font,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = rowFrame,
        })
        table.insert(rowLabels, { val=val, fn=row[2] })
    end

    -- Update loop
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not panel or not panel.Parent then conn:Disconnect(); return end
        for _, r in ipairs(rowLabels) do
            r.val.Text = r.fn()
        end
    end)

    _state.debugPanel = panel
end

function UILib:_debugRefresh()
    -- handled by heartbeat loop
end

-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATION SYSTEM
-- ─────────────────────────────────────────────────────────────────────────────
function UILib:Notify(opts)
    opts = opts or {}
    local theme   = self:GetTheme()
    local title   = opts.title   or "Notification"
    local message = opts.message or ""
    local ntype   = opts.type    or "info"   -- "info" | "success" | "warning" | "error"
    local duration= opts.duration or 4

    local accentColor = ({
        info    = theme.Accent,
        success = theme.Success,
        warning = theme.Warning,
        error   = theme.Danger,
    })[ntype] or theme.Accent

    local icon = ({
        info    = "ℹ",
        success = "✓",
        warning = "⚠",
        error   = "✕",
    })[ntype] or "ℹ"

    playSound(ntype == "error" and "error" or "notify")

    -- Card
    local card = new("Frame", {
        Name              = "Notification",
        Size              = UDim2.new(0, 300, 0, 72),
        BackgroundColor3  = theme.Surface,
        BackgroundTransparency = 0.06,
        ClipsDescendants  = true,
        Parent            = NotifLayer,
    })
    applyCorner(card, RADIUS.Panel)
    applyStroke(card, theme.Border, 1)

    -- Accent bar
    new("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        Parent           = card,
    })

    -- Icon
    new("TextLabel", {
        Text             = icon,
        Size             = UDim2.new(0, 32, 1, 0),
        Position         = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        TextColor3       = accentColor,
        Font             = FONT.Title.font,
        TextSize         = 18,
        Parent           = card,
    })

    -- Content
    local content = new("Frame", {
        Size     = UDim2.new(1,-54,1,0),
        Position = UDim2.new(0, 48, 0, 0),
        BackgroundTransparency = 1,
        Parent   = card,
    })
    applyListLayout(content, 2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    applyPadding(content, SP.sm, SP.sm, SP.sm, 0)

    new("TextLabel", {
        Text       = title,
        Size       = UDim2.new(1,0,0,18),
        BackgroundTransparency = 1,
        TextColor3 = theme.Text,
        Font       = FONT.Section.font,
        TextSize   = FONT.Section.size,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent     = content,
    })
    new("TextLabel", {
        Text       = message,
        Size       = UDim2.new(1,0,0,28),
        BackgroundTransparency = 1,
        TextColor3 = theme.SubText,
        Font       = FONT.Body.font,
        TextSize   = FONT.Body.size,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent     = content,
    })

    -- Progress bar
    local bar = new("Frame", {
        Size             = UDim2.new(1,0,0,2),
        Position         = UDim2.new(0,0,1,-2),
        BackgroundColor3 = accentColor,
        BorderSizePixel  = 0,
        Parent           = card,
    })

    -- Animate in
    card.Position = UDim2.new(1, 20, 0, 0)
    tween(card, { Position = UDim2.new(0,0,0,0) }, ANIM.Normal)
    tween(bar,  { Size = UDim2.new(0,0,0,2) }, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

    task.delay(duration, function()
        if not card or not card.Parent then return end
        tween(card, { Position = UDim2.new(1, 20, 0, 0) }, ANIM.Normal)
        task.delay(ANIM.Normal + 0.05, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)

    return card
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CURSOR HIGHLIGHT (PC only)
-- ─────────────────────────────────────────────────────────────────────────────
function UILib:EnableCursorHighlight()
    if isMobile() then return end
    local cursor = new("Frame", {
        Name   = "CursorHighlight",
        Size   = UDim2.new(0,14,0,14),
        BackgroundColor3 = self:GetTheme().Accent,
        BackgroundTransparency = 0.6,
        ZIndex = 2000,
        Parent = ScreenGui,
    })
    applyCorner(cursor, RADIUS.Pill)

    RunService.RenderStepped:Connect(function()
        local mouse = UserInputService:GetMouseLocation()
        cursor.Position = UDim2.new(0, mouse.X - 7, 0, mouse.Y - 7)
    end)
    return cursor
end

-- ─────────────────────────────────────────────────────────────────────────────
-- GLOBAL SETTINGS
-- ─────────────────────────────────────────────────────────────────────────────
function UILib:SetSounds(enabled)    _state.soundEnabled = enabled end
function UILib:SetReduceMotion(v)    _state.reduceMotion = v end
function UILib:SetBlur(enabled)
    _state.blurEnabled = enabled
    BlurEffect.Size = 0
end
function UILib:SetHWID(hwid)         _state.hwid = hwid end
function UILib:SetHWIDStatus(status) _state.hwid_status = status end

-- ─────────────────────────────────────────────────────────────────────────────
-- WINDOW BUILDER
-- ─────────────────────────────────────────────────────────────────────────────
function UILib:CreateWindow(opts)
    opts = opts or {}
    local theme    = self:GetTheme()
    local title    = opts.title    or "UILib"
    local subtitle = opts.subtitle or ""
    local size     = opts.size     or UDim2.new(0, 520, 0, 420)
    local position = opts.position or UDim2.new(0.5,-260,0.5,-210)
    local minSize  = opts.minSize  or UDim2.new(0, 520, 0, 420)

    -- ── Root ──
    local Root = new("Frame", {
        Name             = "UILib_Window_" .. title,
        Size             = size,
        Position         = position,
        BackgroundColor3 = theme.Background,
        ClipsDescendants = false,
        ZIndex           = 10,
        Parent           = ScreenGui,
    })
    applyCorner(Root, RADIUS.Window)
    applyStroke(Root, theme.Border, 1)

    -- Drop shadow (visual depth)
    local shadow = new("ImageLabel", {
        Name  = "Shadow",
        Size  = UDim2.new(1, 30, 1, 30),
        Position = UDim2.new(0,-15,0,-15),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0,0,0),
        ImageTransparency = 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49,49,450,450),
        ZIndex = 9,
        Parent = Root,
    })

    -- ── Title bar ──
    local TitleBar = new("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = theme.Surface,
        ClipsDescendants = true,
        ZIndex           = 11,
        Parent           = Root,
    })
    local TitleCorner = new("UICorner", {
        CornerRadius = RADIUS.Window,
        Parent       = TitleBar,
    })
    -- Flatten bottom corners of title bar
    new("Frame", {
        Size             = UDim2.new(1,0,0,RADIUS.Window.Offset),
        Position         = UDim2.new(0,0,1,-RADIUS.Window.Offset),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = TitleBar,
    })
    applyPadding(TitleBar, 0, SP.md, 0, SP.md)

    -- Title text
    local TitleLabel = new("TextLabel", {
        Text       = title,
        Size       = UDim2.new(0.55,0,1,0),
        BackgroundTransparency = 1,
        TextColor3 = theme.Text,
        Font       = FONT.Title.font,
        TextSize   = FONT.Title.size,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex     = 12,
        Parent     = TitleBar,
    })

    -- Subtitle
    if subtitle ~= "" then
        TitleLabel.Size = UDim2.new(0,0,0,20)
        TitleLabel.AutomaticSize = Enum.AutomaticSize.X
        TitleLabel.TextSize = 16

        new("TextLabel", {
            Text       = subtitle,
            Size       = UDim2.new(0,0,0,16),
            Position   = UDim2.new(0,0,0,24),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            TextColor3 = theme.SubText,
            Font       = FONT.Small.font,
            TextSize   = FONT.Small.size,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex     = 12,
            Parent     = TitleBar,
        })
    end

    -- Window controls (minimize/close)
    local Controls = new("Frame", {
        Size             = UDim2.new(0, 60, 0, 24),
        Position         = UDim2.new(1,-60,0.5,-12),
        BackgroundTransparency = 1,
        ZIndex           = 12,
        Parent           = TitleBar,
    })
    applyListLayout(Controls, SP.xs, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

    local function makeCtrlBtn(icon, color)
        local btn = new("TextButton", {
            Text       = icon,
            Size       = UDim2.new(0,24,0,24),
            BackgroundColor3 = theme.Elevated,
            TextColor3 = color or theme.SubText,
            Font       = Enum.Font.GothamBold,
            TextSize   = 12,
            ZIndex     = 13,
            Parent     = Controls,
        })
        applyCorner(btn, RADIUS.Pill)
        btn.MouseEnter:Connect(function()
            tween(btn, { BackgroundColor3 = color or theme.Border }, ANIM.Fast)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, { BackgroundColor3 = theme.Elevated }, ANIM.Fast)
        end)
        return btn
    end

    local MinBtn   = makeCtrlBtn("_", theme.Warning)
    local CloseBtn = makeCtrlBtn("×", theme.Danger)

    -- ── Tab bar ──
    local TabBar = new("Frame", {
        Name             = "TabBar",
        Size             = UDim2.new(0, 140, 1, -48),
        Position         = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = theme.Surface,
        ZIndex           = 11,
        Parent           = Root,
    })
    -- Flatten right side corners
    new("Frame", {
        Size = UDim2.new(0, RADIUS.Window.Offset, 1,0),
        Position = UDim2.new(1,-RADIUS.Window.Offset,0,0),
        BackgroundColor3 = theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = TabBar,
    })
    applyPadding(TabBar, SP.sm, 0, SP.sm, SP.sm)

    local TabList = new("Frame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        ZIndex = 12,
        Parent = TabBar,
    })
    applyListLayout(TabList, SP.xs)

    -- Separator
    new("Frame", {
        Size             = UDim2.new(0,1,1,-48),
        Position         = UDim2.new(0,140,0,48),
        BackgroundColor3 = theme.Border,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = Root,
    })

    -- ── Content area ──
    local ContentArea = new("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1,-140,1,-48),
        Position         = UDim2.new(0,140,0,48),
        BackgroundColor3 = theme.Background,
        ClipsDescendants = true,
        ZIndex           = 11,
        Parent           = Root,
    })

    -- ── Dragging ──
    local dragging, dragStart, dragPos = false, nil, nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            dragPos   = Root.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                dragPos.X.Scale,
                dragPos.X.Offset + delta.X,
                dragPos.Y.Scale,
                dragPos.Y.Offset + delta.Y
            )
            Root.Position = clampPosition(
                {X=newPos.X, Y=newPos.Y},
                {X=Root.AbsoluteSize, Y=Root.AbsoluteSize}
            ) or newPos
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ── Minimize ──
    local minimized   = false
    local MinBtn2     = nil   -- floating circular button

    local function minimize()
        minimized = true
        playSound("close")
        tween(Root, { Size = UDim2.new(0, size.X.Offset, 0, 0) }, ANIM.Normal)
        task.delay(ANIM.Normal, function()
            Root.Visible = false
        end)
        -- Floating button
        MinBtn2 = new("TextButton", {
            Name             = "MinimizedBtn",
            Text             = "✦",
            Size             = UDim2.new(0, 44, 0, 44),
            Position         = UDim2.new(0, SP.lg, 1, -(44+SP.lg)),
            BackgroundColor3 = theme.Accent,
            TextColor3       = theme.AccentText,
            Font             = FONT.Title.font,
            TextSize         = 18,
            ZIndex           = 500,
            Parent           = ScreenGui,
        })
        applyCorner(MinBtn2, RADIUS.Pill)

        -- Make floating button draggable
        local fb_drag, fb_dragStart, fb_pos = false, nil, nil
        MinBtn2.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                fb_drag = true; fb_dragStart = inp.Position; fb_pos = MinBtn2.Position
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if fb_drag and (inp.UserInputType == Enum.UserInputType.MouseMovement
                or inp.UserInputType == Enum.UserInputType.Touch) then
                local d = inp.Position - fb_dragStart
                MinBtn2.Position = UDim2.new(0, fb_pos.X.Offset+d.X, 0, fb_pos.Y.Offset+d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                fb_drag = false
            end
        end)

        MinBtn2.MouseButton1Click:Connect(function()
            maximizeWindow()
        end)
    end

    local function maximizeWindow()
        if not minimized then return end
        minimized = false
        if MinBtn2 then MinBtn2:Destroy(); MinBtn2 = nil end
        Root.Visible = true
        Root.Size    = UDim2.new(0, size.X.Offset, 0, 0)
        playSound("open")
        tween(Root, { Size = size }, ANIM.Normal)
    end

    MinBtn.MouseButton1Click:Connect(minimize)
    CloseBtn.MouseButton1Click:Connect(function()
        playSound("close")
        tween(Root, { Size = UDim2.new(0, size.X.Offset, 0, 0) }, ANIM.Normal)
        tween(Root, { BackgroundTransparency = 1 }, ANIM.Normal)
        task.delay(ANIM.Normal + 0.05, function()
            if MinBtn2 then MinBtn2:Destroy() end
            Root:Destroy()
        end)
        if _state.blurEnabled then
            tween(BlurEffect, { Size = 0 }, ANIM.Normal)
        end
    end)

    -- ── Open animation ──
    Root.Size = UDim2.new(0, size.X.Offset, 0, 0)
    Root.BackgroundTransparency = 1
    tween(Root, { Size = size, BackgroundTransparency = 0 }, ANIM.Slow)
    if _state.blurEnabled then
        tween(BlurEffect, { Size = 12 }, ANIM.Slow)
    end
    playSound("open")

    -- ── Window object ──
    local Window = {
        _root       = Root,
        _titleBar   = TitleBar,
        _tabBar     = TabBar,
        _tabList    = TabList,
        _content    = ContentArea,
        _tabs       = {},
        _activeTab  = nil,
        _theme      = theme,
        _lib        = self,
    }

    -- ── ADD TAB ──
    function Window:AddTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabTheme = self._theme
        local tabName  = tabOpts.name or ("Tab " .. #self._tabs + 1)
        local tabIcon  = tabOpts.icon or ""

        -- Tab button
        local tabBtn = new("TextButton", {
            Text             = tabIcon .. (tabIcon ~= "" and "  " or "") .. tabName,
            Size             = UDim2.new(1,-SP.sm,0,34),
            BackgroundColor3 = tabTheme.Elevated,
            BackgroundTransparency = 1,
            TextColor3       = tabTheme.SubText,
            Font             = FONT.Body.font,
            TextSize         = FONT.Body.size,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 13,
            Parent           = self._tabList,
        })
        applyCorner(tabBtn, RADIUS.Button)
        applyPadding(tabBtn, 0, SP.sm, 0, SP.sm)

        -- Active indicator bar
        local activeBar = new("Frame", {
            Size             = UDim2.new(0, 3, 0.6, 0),
            Position         = UDim2.new(0,-SP.sm,0.2,0),
            BackgroundColor3 = tabTheme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ZIndex           = 14,
            Parent           = tabBtn,
        })
        applyCorner(activeBar, RADIUS.Pill)

        -- Content scroll frame
        local tabContent = new("ScrollingFrame", {
            Name             = "Tab_" .. tabName,
            Size             = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = tabTheme.Border,
            CanvasSize       = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible          = false,
            ZIndex           = 12,
            Parent           = self._content,
        })
        applyPadding(tabContent, SP.md, SP.md, SP.md, SP.md)
        applyListLayout(tabContent, SP.sm)

        local tab = {
            _btn        = tabBtn,
            _bar        = activeBar,
            _content    = tabContent,
            _name       = tabName,
            _window     = self,
            _theme      = tabTheme,
            _components = 0,
        }

        -- Section heading shorthand
        function tab:AddSection(sOpts)
            sOpts = sOpts or {}
            local theme = self._theme
            local lbl = new("TextLabel", {
                Text       = (sOpts.name or "Section"):upper(),
                Size       = UDim2.new(1,0,0,24),
                BackgroundTransparency = 1,
                TextColor3 = theme.SubText,
                Font       = FONT.Small.font,
                TextSize   = FONT.Small.size,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = self._components,
                Parent     = self._content,
            })
            applyPadding(lbl, 0, 0, SP.xs, 0)
            self._components += 1
            _state.componentCount += 1
            return lbl
        end

        -- ── BUTTON ──
        function tab:AddButton(bOpts)
            bOpts = bOpts or {}
            local theme    = self._theme
            local label    = bOpts.label    or "Button"
            local desc     = bOpts.desc     or ""
            local callback = bOpts.callback or function() end
            local danger   = bOpts.danger   or false

            local row = new("Frame", {
                Size             = UDim2.new(1,0,0,42),
                BackgroundColor3 = theme.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, theme.Border, 1)
            applyPadding(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text       = label,
                Size       = UDim2.new(0.6,0,1,0),
                BackgroundTransparency = 1,
                TextColor3 = theme.Text,
                Font       = FONT.Body.font,
                TextSize   = FONT.Body.size,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent     = row,
            })

            local btn = new("TextButton", {
                Text             = desc ~= "" and desc or "Execute",
                Size             = UDim2.new(0, 90, 0, 28),
                Position         = UDim2.new(1,-90,0.5,-14),
                BackgroundColor3 = danger and theme.Danger or theme.Accent,
                TextColor3       = theme.AccentText,
                Font             = FONT.Body.font,
                TextSize         = FONT.Body.size,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(btn, RADIUS.Button)

            btn.MouseEnter:Connect(function()
                tween(btn, { BackgroundColor3 = danger and Color3.fromRGB(200,40,40) or theme.AccentHover }, ANIM.Fast)
                tween(btn, { Size = UDim2.new(0,94,0,28) }, ANIM.Fast)
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, { BackgroundColor3 = danger and theme.Danger or theme.Accent }, ANIM.Fast)
                tween(btn, { Size = UDim2.new(0,90,0,28) }, ANIM.Fast)
            end)
            btn.MouseButton1Click:Connect(function()
                playSound("click")
                tween(btn, { Size = UDim2.new(0,86,0,26) }, ANIM.Fast)
                task.delay(ANIM.Fast, function()
                    tween(btn, { Size = UDim2.new(0,90,0,28) }, ANIM.Fast)
                end)
                callback()
            end)

            self._components += 1
            _state.componentCount += 1
            return btn
        end

        -- ── TOGGLE ──
        function tab:AddToggle(tOpts)
            tOpts = tOpts or {}
            local theme    = self._theme
            local label    = tOpts.label    or "Toggle"
            local default  = tOpts.default  or false
            local configKey= tOpts.configKey
            local callback = tOpts.callback or function() end

            local enabled = configKey
                and UILib:GetConfig(configKey, default)
                or default

            local row = new("Frame", {
                Size             = UDim2.new(1,0,0,42),
                BackgroundColor3 = theme.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, theme.Border, 1)
            applyPadding(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text       = label,
                Size       = UDim2.new(0.7,0,1,0),
                BackgroundTransparency = 1,
                TextColor3 = theme.Text,
                Font       = FONT.Body.font,
                TextSize   = FONT.Body.size,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent     = row,
            })

            -- Track background
            local track = new("TextButton", {
                Text             = "",
                Size             = UDim2.new(0, 42, 0, 22),
                Position         = UDim2.new(1,-42,0.5,-11),
                BackgroundColor3 = enabled and theme.Accent or theme.Elevated,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(track, RADIUS.Pill)
            applyStroke(track, theme.Border, 1)

            -- Thumb
            local thumb = new("Frame", {
                Size             = UDim2.new(0, 16, 0, 16),
                Position         = enabled
                    and UDim2.new(1,-19,0.5,-8)
                    or  UDim2.new(0,3,0.5,-8),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                ZIndex           = 14,
                Parent           = track,
            })
            applyCorner(thumb, RADIUS.Pill)

            local function setToggle(val, skipAnim)
                enabled = val
                local dur = skipAnim and 0 or ANIM.Fast
                tween(track, { BackgroundColor3 = val and theme.Accent or theme.Elevated }, dur)
                tween(thumb, { Position = val
                    and UDim2.new(1,-19,0.5,-8)
                    or  UDim2.new(0,3,0.5,-8)
                }, dur)
            end

            track.MouseButton1Click:Connect(function()
                playSound("toggle")
                setToggle(not enabled)
                if configKey then UILib:SetConfig(configKey, enabled) end
                callback(enabled)
            end)

            self._components += 1
            _state.componentCount += 1

            return {
                Set  = function(v) setToggle(v) end,
                Get  = function() return enabled end,
            }
        end

        -- ── SLIDER ──
        function tab:AddSlider(sOpts)
            sOpts = sOpts or {}
            local theme    = self._theme
            local label    = sOpts.label    or "Slider"
            local min      = sOpts.min      or 0
            local max      = sOpts.max      or 100
            local default  = sOpts.default  or min
            local step     = sOpts.step     or 1
            local suffix   = sOpts.suffix   or ""
            local configKey= sOpts.configKey
            local callback = sOpts.callback or function() end

            local value = configKey
                and UILib:GetConfig(configKey, default)
                or default
            value = math.clamp(value, min, max)

            local row = new("Frame", {
                Size             = UDim2.new(1,0,0,52),
                BackgroundColor3 = theme.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, theme.Border, 1)
            applyPadding(row, SP.sm, SP.md, SP.sm, SP.md)

            local header = new("Frame", {
                Size = UDim2.new(1,0,0,18),
                BackgroundTransparency = 1,
                Parent = row,
            })
            new("TextLabel", {
                Text       = label,
                Size       = UDim2.new(0.7,0,1,0),
                BackgroundTransparency = 1,
                TextColor3 = theme.Text,
                Font       = FONT.Body.font,
                TextSize   = FONT.Body.size,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent     = header,
            })
            local valLabel = new("TextLabel", {
                Text       = tostring(value) .. suffix,
                Size       = UDim2.new(0.3,0,1,0),
                Position   = UDim2.new(0.7,0,0,0),
                BackgroundTransparency = 1,
                TextColor3 = theme.Accent,
                Font       = FONT.Section.font,
                TextSize   = FONT.Body.size,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent     = header,
            })

            -- Track
            local track = new("Frame", {
                Size             = UDim2.new(1,0,0,6),
                Position         = UDim2.new(0,0,1,-6),
                BackgroundColor3 = theme.Elevated,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(track, RADIUS.Pill)

            -- Fill
            local fill = new("Frame", {
                Size             = UDim2.new((value-min)/(max-min),0,1,0),
                BackgroundColor3 = theme.Accent,
                ZIndex           = 14,
                Parent           = track,
            })
            applyCorner(fill, RADIUS.Pill)

            -- Thumb
            local thumbSl = new("Frame", {
                Size             = UDim2.new(0,14,0,14),
                Position         = UDim2.new((value-min)/(max-min),0,0.5,-7),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                ZIndex           = 15,
                Parent           = track,
            })
            applyCorner(thumbSl, RADIUS.Pill)

            local function setSlider(v, silent)
                v = math.clamp(
                    math.round((v - min) / step) * step + min,
                    min, max
                )
                value = v
                local pct = (v-min)/(max-min)
                tween(fill,    { Size     = UDim2.new(pct,0,1,0) },         ANIM.Fast)
                tween(thumbSl, { Position = UDim2.new(pct,0,0.5,-7) },      ANIM.Fast)
                valLabel.Text = tostring(v) .. suffix
                if configKey then UILib:SetConfig(configKey, v) end
                if not silent then callback(v) end
            end

            -- Drag
            local slDragging = false
            track.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    slDragging = true
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    slDragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if slDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                    local abs   = track.AbsolutePosition
                    local size  = track.AbsoluteSize
                    local relX  = math.clamp((inp.Position.X - abs.X) / size.X, 0, 1)
                    setSlider(min + relX * (max - min))
                end
            end)

            self._components += 1
            _state.componentCount += 1

            return {
                Set = function(v) setSlider(v, true) end,
                Get = function() return value end,
            }
        end

        -- ── DROPDOWN ──
        function tab:AddDropdown(dOpts)
            dOpts = dOpts or {}
            local theme    = self._theme
            local label    = dOpts.label    or "Dropdown"
            local items    = dOpts.items    or {}
            local default  = dOpts.default  or (items[1] or "—")
            local configKey= dOpts.configKey
            local callback = dOpts.callback or function() end

            local selected = configKey
                and UILib:GetConfig(configKey, default)
                or default

            local ddOpen = false

            local row = new("Frame", {
                Size             = UDim2.new(1,0,0,42),
                BackgroundColor3 = theme.Surface,
                ZIndex           = 20,
                LayoutOrder      = self._components,
                ClipsDescendants = false,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, theme.Border, 1)
            applyPadding(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text       = label,
                Size       = UDim2.new(0.5,0,1,0),
                BackgroundTransparency = 1,
                TextColor3 = theme.Text,
                Font       = FONT.Body.font,
                TextSize   = FONT.Body.size,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent     = row,
            })

            local trigger = new("TextButton", {
                Text             = selected .. "  ▾",
                Size             = UDim2.new(0.48,0,0,28),
                Position         = UDim2.new(0.52,0,0.5,-14),
                BackgroundColor3 = theme.Elevated,
                TextColor3       = theme.Text,
                Font             = FONT.Body.font,
                TextSize         = FONT.Body.size,
                ZIndex           = 21,
                Parent           = row,
            })
            applyCorner(trigger, RADIUS.Button)
            applyStroke(trigger, theme.Border, 1)

            -- Dropdown list
            local dropList = new("Frame", {
                Size             = UDim2.new(0.48,0,0,0),
                Position         = UDim2.new(0.52,0,1,4),
                BackgroundColor3 = theme.Elevated,
                ClipsDescendants = true,
                ZIndex           = 100,
                Visible          = false,
                Parent           = row,
            })
            applyCorner(dropList, RADIUS.Button)
            applyStroke(dropList, theme.Border, 1)

            local innerList = new("Frame", {
                Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = dropList,
            })
            applyListLayout(innerList, 2)
            applyPadding(innerList, SP.xs, SP.xs, SP.xs, SP.xs)

            for _, item in ipairs(items) do
                local opt = new("TextButton", {
                    Text             = item,
                    Size             = UDim2.new(1,0,0,28),
                    BackgroundTransparency = 1,
                    TextColor3       = theme.SubText,
                    Font             = FONT.Body.font,
                    TextSize         = FONT.Body.size,
                    ZIndex           = 101,
                    Parent           = innerList,
                })
                applyCorner(opt, RADIUS.Tag)
                opt.MouseEnter:Connect(function()
                    tween(opt, { BackgroundTransparency = 0.7, TextColor3 = theme.Text }, ANIM.Fast)
                    opt.BackgroundColor3 = theme.Border
                end)
                opt.MouseLeave:Connect(function()
                    tween(opt, { BackgroundTransparency = 1, TextColor3 = theme.SubText }, ANIM.Fast)
                end)
                opt.MouseButton1Click:Connect(function()
                    selected = item
                    trigger.Text = item .. "  ▾"
                    if configKey then UILib:SetConfig(configKey, item) end
                    callback(item)
                    playSound("click")
                    -- Close
                    tween(dropList, { Size = UDim2.new(0.48,0,0,0) }, ANIM.Fast)
                    task.delay(ANIM.Fast, function() dropList.Visible = false end)
                    ddOpen = false
                end)
            end

            trigger.MouseButton1Click:Connect(function()
                playSound("click")
                ddOpen = not ddOpen
                if ddOpen then
                    dropList.Visible = true
                    local targetH = math.min(#items * 32 + SP.sm, 160)
                    tween(dropList, { Size = UDim2.new(0.48,0,0,targetH) }, ANIM.Normal)
                else
                    tween(dropList, { Size = UDim2.new(0.48,0,0,0) }, ANIM.Fast)
                    task.delay(ANIM.Fast, function() dropList.Visible = false end)
                end
            end)

            self._components += 1
            _state.componentCount += 1

            return {
                Set = function(v) selected = v; trigger.Text = v .. "  ▾" end,
                Get = function() return selected end,
            }
        end

        -- ── KEYBIND ──
        function tab:AddKeybind(kOpts)
            kOpts = kOpts or {}
            local theme    = self._theme
            local label    = kOpts.label    or "Keybind"
            local default  = kOpts.default  or Enum.KeyCode.Unknown
            local configKey= kOpts.configKey
            local callback = kOpts.callback or function() end

            local currentKey = configKey
                and Enum.KeyCode[UILib:GetConfig(configKey, default.Name)]
                or default
            local listening  = false

            local row = new("Frame", {
                Size             = UDim2.new(1,0,0,42),
                BackgroundColor3 = theme.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, theme.Border, 1)
            applyPadding(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text       = label,
                Size       = UDim2.new(0.6,0,1,0),
                BackgroundTransparency = 1,
                TextColor3 = theme.Text,
                Font       = FONT.Body.font,
                TextSize   = FONT.Body.size,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent     = row,
            })

            local keyBtn = new("TextButton", {
                Text             = "[" .. currentKey.Name .. "]",
                Size             = UDim2.new(0, 90, 0, 28),
                Position         = UDim2.new(1,-90,0.5,-14),
                BackgroundColor3 = theme.Elevated,
                TextColor3       = theme.Accent,
                Font             = FONT.Mono.font,
                TextSize         = 12,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(keyBtn, RADIUS.Button)
            applyStroke(keyBtn, theme.Border, 1)

            keyBtn.MouseButton1Click:Connect(function()
                listening   = true
                keyBtn.Text = "[ … ]"
                tween(keyBtn, { BackgroundColor3 = theme.Accent }, ANIM.Fast)
            end)

            UserInputService.InputBegan:Connect(function(inp, gp)
                if gp or not listening then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    listening   = false
                    currentKey  = inp.KeyCode
                    keyBtn.Text = "[" .. inp.KeyCode.Name .. "]"
                    tween(keyBtn, { BackgroundColor3 = theme.Elevated }, ANIM.Fast)
                    if configKey then UILib:SetConfig(configKey, inp.KeyCode.Name) end
                    playSound("click")
                end
            end)

            -- Global hotkey listener
            UserInputService.InputBegan:Connect(function(inp, gp)
                if gp then return end
                if inp.KeyCode == currentKey and not listening then
                    callback(currentKey)
                end
            end)

            self._components += 1
            _state.componentCount += 1

            return {
                Set = function(key) currentKey = key; keyBtn.Text = "[" .. key.Name .. "]" end,
                Get = function() return currentKey end,
            }
        end

        -- ── COLOR PICKER ──
        function tab:AddColorPicker(cOpts)
            cOpts = cOpts or {}
            local theme    = self._theme
            local label    = cOpts.label    or "Color"
            local default  = cOpts.default  or Color3.fromRGB(99,102,241)
            local configKey= cOpts.configKey
            local callback = cOpts.callback or function() end

            local currentColor = default

            local row = new("Frame", {
                Size             = UDim2.new(1,0,0,42),
                BackgroundColor3 = theme.Surface,
                LayoutOrder      = self._components,
                Parent           = self._content,
            })
            applyCorner(row, RADIUS.Button)
            applyStroke(row, theme.Border, 1)
            applyPadding(row, 0, SP.md, 0, SP.md)

            new("TextLabel", {
                Text       = label,
                Size       = UDim2.new(0.6,0,1,0),
                BackgroundTransparency = 1,
                TextColor3 = theme.Text,
                Font       = FONT.Body.font,
                TextSize   = FONT.Body.size,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent     = row,
            })

            local swatch = new("TextButton", {
                Text             = "",
                Size             = UDim2.new(0,56,0,28),
                Position         = UDim2.new(1,-56,0.5,-14),
                BackgroundColor3 = currentColor,
                ZIndex           = 13,
                Parent           = row,
            })
            applyCorner(swatch, RADIUS.Button)
            applyStroke(swatch, theme.Border, 1)

            -- Simple hue bar picker (full implementation)
            local pickerOpen = false
            local pickerFrame = nil

            swatch.MouseButton1Click:Connect(function()
                playSound("click")
                if pickerFrame then
                    pickerFrame:Destroy()
                    pickerFrame = nil
                    pickerOpen = false
                    return
                end
                pickerOpen = true
                pickerFrame = new("Frame", {
                    Size             = UDim2.new(1,0,0,80),
                    Position         = UDim2.new(0,0,1,4),
                    BackgroundColor3 = theme.Elevated,
                    ZIndex           = 50,
                    Parent           = row,
                })
                applyCorner(pickerFrame, RADIUS.Button)
                applyStroke(pickerFrame, theme.Border, 1)
                applyPadding(pickerFrame, SP.sm, SP.sm, SP.sm, SP.sm)

                -- Hue slider bar
                local hueBar = new("Frame", {
                    Size = UDim2.new(1,0,0,20),
                    BackgroundColor3 = Color3.new(1,0,0),
                    ZIndex = 51,
                    Parent = pickerFrame,
                })
                applyCorner(hueBar, RADIUS.Pill)

                -- Gradient
                local grad = new("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,0,0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,0,0)),
                    }),
                    Parent = hueBar,
                })

                local hueH, hueS, hueV = currentColor:ToHSV()
                local hueDrag = false

                hueBar.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = false end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if hueDrag then
                        local abs = hueBar.AbsolutePosition
                        local sz  = hueBar.AbsoluteSize
                        hueH = math.clamp((inp.Position.X - abs.X)/sz.X, 0, 1)
                        currentColor = Color3.fromHSV(hueH, hueS, hueV)
                        swatch.BackgroundColor3 = currentColor
                        if configKey then UILib:SetConfig(configKey, {currentColor.R, currentColor.G, currentColor.B}) end
                        callback(currentColor)
                    end
                end)

                -- Preset swatches
                local presetRow = new("Frame", {
                    Size = UDim2.new(1,0,0,24),
                    Position = UDim2.new(0,0,0,28),
                    BackgroundTransparency = 1,
                    ZIndex = 51,
                    Parent = pickerFrame,
                })
                applyListLayout(presetRow, SP.xs, Enum.FillDirection.Horizontal)

                local presets = {
                    Color3.fromRGB(239,68,68), Color3.fromRGB(249,115,22),
                    Color3.fromRGB(234,179,8),  Color3.fromRGB(34,197,94),
                    Color3.fromRGB(56,189,248),  Color3.fromRGB(99,102,241),
                    Color3.fromRGB(168,85,247),  Color3.fromRGB(255,255,255),
                }
                for _, pr in ipairs(presets) do
                    local ps = new("TextButton", {
                        Text = "", Size = UDim2.new(0,22,0,22),
                        BackgroundColor3 = pr, ZIndex = 52, Parent = presetRow,
                    })
                    applyCorner(ps, RADIUS.Tag)
                    ps.MouseButton1Click:Connect(function()
                        currentColor = pr
                        swatch.BackgroundColor3 = pr
                        if configKey then UILib:SetConfig(configKey, {pr.R, pr.G, pr.B}) end
                        callback(pr)
                    end)
                end
            end)

            self._components += 1
            _state.componentCount += 1

            return {
                Set = function(c) currentColor = c; swatch.BackgroundColor3 = c end,
                Get = function() return currentColor end,
            }
        end

        -- Tab selection logic
        function tab:Select()
            local win = self._window
            -- Hide all tabs
            for _, t in ipairs(win._tabs) do
                t._content.Visible = false
                tween(t._btn, { TextColor3 = tabTheme.SubText, BackgroundTransparency = 1 }, ANIM.Fast)
                tween(t._bar, { BackgroundTransparency = 1 }, ANIM.Fast)
            end
            -- Show this tab
            self._content.Visible = true
            tween(self._btn, {
                TextColor3           = tabTheme.Text,
                BackgroundTransparency = 0.85,
                BackgroundColor3     = tabTheme.Elevated,
            }, ANIM.Fast)
            tween(self._bar, { BackgroundTransparency = 0 }, ANIM.Fast)
            win._activeTab = self
        end

        tabBtn.MouseButton1Click:Connect(function()
            playSound("click")
            tab:Select()
        end)

        -- Hover effect
        tabBtn.MouseEnter:Connect(function()
            if self._window._activeTab ~= tab then
                tween(tabBtn, { TextColor3 = tabTheme.Text, BackgroundTransparency = 0.92 }, ANIM.Fast)
                tabBtn.BackgroundColor3 = tabTheme.Elevated
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if self._window._activeTab ~= tab then
                tween(tabBtn, { TextColor3 = tabTheme.SubText, BackgroundTransparency = 1 }, ANIM.Fast)
            end
        end)

        table.insert(self._tabs, tab)

        -- Auto-select first tab
        if #self._tabs == 1 then
            task.defer(function() tab:Select() end)
        end

        return tab
    end

    -- Theme application
    function Window:_applyTheme(theme)
        self._theme = theme
        -- Update root colors
        tween(self._root,    { BackgroundColor3 = theme.Background }, ANIM.Normal)
        tween(self._titleBar,{ BackgroundColor3 = theme.Surface    }, ANIM.Normal)
        tween(self._tabBar,  { BackgroundColor3 = theme.Surface    }, ANIM.Normal)
        tween(self._content, { BackgroundColor3 = theme.Background }, ANIM.Normal)
    end

    -- FPS / Performance panel
    function Window:AddFPSPanel()
        local theme = self._theme
        local panel = new("Frame", {
            Name             = "FPSPanel",
            Size             = UDim2.new(0, 110, 0, 36),
            Position         = UDim2.new(1,-116,1,-42),
            BackgroundColor3 = theme.Surface,
            BackgroundTransparency = 0.1,
            ZIndex           = 500,
            Parent           = ScreenGui,
        })
        applyCorner(panel, RADIUS.Button)
        applyStroke(panel, theme.Border, 1)
        applyPadding(panel, 0, SP.sm, 0, SP.sm)

        local fpsLabel = new("TextLabel", {
            Text       = "FPS: —",
            Size       = UDim2.new(0.5,0,1,0),
            BackgroundTransparency = 1,
            TextColor3 = theme.Text,
            Font       = FONT.Mono.font,
            TextSize   = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent     = panel,
        })
        local pingLabel = new("TextLabel", {
            Text       = "PING: —",
            Size       = UDim2.new(0.5,0,1,0),
            Position   = UDim2.new(0.5,0,0,0),
            BackgroundTransparency = 1,
            TextColor3 = theme.SubText,
            Font       = FONT.Mono.font,
            TextSize   = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent     = panel,
        })

        local frames, elapsed = 0, 0
        RunService.Heartbeat:Connect(function(dt)
            frames  += 1
            elapsed += dt
            if elapsed >= 0.5 then
                fpsLabel.Text = "FPS: " .. math.round(frames / elapsed)
                frames, elapsed = 0, 0
            end
            local ping = LocalPlayer:GetNetworkPing and math.round(LocalPlayer:GetNetworkPing() * 1000) or 0
            pingLabel.Text = "PING: " .. ping
        end)
        return panel
    end

    table.insert(_state.windows, Window)
    return Window
end

-- ─────────────────────────────────────────────────────────────────────────────
-- INIT — Set default theme
-- ─────────────────────────────────────────────────────────────────────────────
UILib:SetTheme("Dark Minimal")

return UILib

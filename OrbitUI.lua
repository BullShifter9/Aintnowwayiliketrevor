--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║               ORBIT UI LIBRARY  v1.0.0                       ║
    ║       Premium Single-File Roblox Luau UI Framework            ║
    ║       Amethyst Theme  |  Gamepass Premium  |  Mobile          ║
    ╚═══════════════════════════════════════════════════════════════╝

    Usage:
        local Orbit = loadstring(game:HttpGet("https://raw.githubusercontent.com/..."))()
        local Window = Orbit:CreateWindow({ Title = "My Script", Theme = "Amethyst" })
        local Tab = Window:CreateTab({ Name = "Main", Icon = "rbxassetid://..." })
        Tab:AddButton({ Title = "Click Me", Callback = function() end })

    SECURITY NOTE (Premium / Gamepass):
        Client-side Gamepass checks use MarketplaceService:UserOwnsGamePassAsync(),
        which is a remote call to Roblox servers. While this is more reliable than a
        simple boolean, it can still be bypassed by:
            1. Memory-editing tools that patch the function's return value.
            2. Script injection that overwrites the PremiumManager.IsPremium flag.
            3. Executor hooks that intercept the MarketplaceService call.
        These bypasses only affect the LOCAL CLIENT's UI. Never use this check to gate
        anything with real value (economy, items, abilities) — always validate on the server.
        The check here is purely for UI/UX gating.
--]]

-- ─────────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────────
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService        = game:GetService("HttpService")

local LocalPlayer  = Players.LocalPlayer
local Camera       = workspace.CurrentCamera

-- ─────────────────────────────────────────────────────────────
-- UTILITY HELPERS
-- ─────────────────────────────────────────────────────────────
local Util = {}

function Util.Tween(instance, duration, style, dir, props)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    local ti = TweenInfo.new(duration, style, dir)
    local t  = TweenService:Create(instance, ti, props)
    t:Play()
    return t
end

function Util.TweenBounce(instance, duration, props)
    return Util.Tween(instance, duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out, props)
end

function Util.New(className, props, children)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    if props and props.Parent then
        obj.Parent = props.Parent
    end
    return obj
end

function Util.AddCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

function Util.AddStroke(parent, color, trans, thickness)
    local s = Instance.new("UIStroke")
    s.Color             = color or Color3.fromRGB(255, 255, 255)
    s.Transparency      = trans or 0.85
    s.Thickness         = thickness or 1
    s.ApplyStrokeMode   = Enum.ApplyStrokeMode.Border
    s.Parent            = parent
    return s
end

function Util.AddPadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.Parent        = parent
    return p
end

function Util.AddListLayout(parent, padding, dir)
    local l = Instance.new("UIListLayout")
    l.Padding             = UDim.new(0, padding or 6)
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.Parent              = parent
    return l
end

-- ─────────────────────────────────────────────────────────────
-- THEME MANAGER  (Amethyst + extensible)
-- ─────────────────────────────────────────────────────────────
local ThemeManager = {}
ThemeManager._registry   = {} -- { instance: {prop: colorKey} }
ThemeManager._theme      = "Amethyst"

ThemeManager.Themes = {
    Amethyst = {
        -- Window backgrounds
        Background      = Color3.fromRGB(16, 12, 24),
        Surface         = Color3.fromRGB(24, 18, 38),
        SurfaceLight    = Color3.fromRGB(34, 26, 54),
        SurfaceHover    = Color3.fromRGB(44, 34, 68),

        -- Accent
        Accent          = Color3.fromRGB(97, 62, 167),
        AccentLight     = Color3.fromRGB(128, 88, 208),
        AccentDim       = Color3.fromRGB(70, 44, 120),

        -- Borders
        Border          = Color3.fromRGB(58, 46, 82),
        BorderLight     = Color3.fromRGB(90, 72, 118),

        -- Sidebar
        TabBg           = Color3.fromRGB(20, 15, 32),
        TabSelected     = Color3.fromRGB(40, 30, 64),
        TabHover        = Color3.fromRGB(32, 24, 52),
        SidebarBorder   = Color3.fromRGB(50, 40, 72),

        -- Elements
        Element         = Color3.fromRGB(28, 22, 44),
        ElementHover    = Color3.fromRGB(38, 30, 58),
        ElementStroke   = Color3.fromRGB(52, 42, 76),

        -- Toggle
        ToggleOff       = Color3.fromRGB(48, 38, 72),
        ToggleOn        = Color3.fromRGB(97, 62, 167),
        ToggleKnob      = Color3.fromRGB(220, 210, 240),

        -- Slider
        SliderRail      = Color3.fromRGB(42, 32, 66),
        SliderFill      = Color3.fromRGB(97, 62, 167),
        SliderKnob      = Color3.fromRGB(200, 185, 230),

        -- Dropdown
        DropdownBg      = Color3.fromRGB(30, 22, 48),
        DropdownItem    = Color3.fromRGB(38, 28, 60),
        DropdownHover   = Color3.fromRGB(52, 40, 82),

        -- Input
        InputBg         = Color3.fromRGB(26, 20, 42),
        InputFocused    = Color3.fromRGB(36, 28, 60),

        -- Notifications
        NotifBg         = Color3.fromRGB(28, 20, 46),
        NotifBorder     = Color3.fromRGB(80, 58, 128),

        -- Text
        Text            = Color3.fromRGB(240, 236, 252),
        SubText         = Color3.fromRGB(170, 160, 196),
        DimText         = Color3.fromRGB(120, 110, 148),
        AccentText      = Color3.fromRGB(175, 145, 235),

        -- Title bar
        TitleBar        = Color3.fromRGB(20, 15, 32),
        TitleBarLine    = Color3.fromRGB(58, 46, 82),

        -- Premium
        PremiumGold     = Color3.fromRGB(255, 195, 60),
        PremiumLock     = Color3.fromRGB(130, 110, 160),

        -- Section divider
        SectionLine     = Color3.fromRGB(48, 38, 72),
        SectionText     = Color3.fromRGB(140, 120, 175),
    },
}

-- Register instance property for live theme updates
function ThemeManager:Tag(instance, props)
    self._registry[instance] = props
    self:_apply(instance, props)
end

function ThemeManager:_apply(instance, props)
    local t = self.Themes[self._theme]
    if not t then return end
    for prop, colorKey in pairs(props) do
        local color = t[colorKey]
        if color then
            pcall(function() instance[prop] = color end)
        end
    end
end

function ThemeManager:Get(key)
    local t = self.Themes[self._theme]
    return t and t[key] or Color3.fromRGB(255, 255, 255)
end

function ThemeManager:SetTheme(name)
    if not self.Themes[name] then return end
    self._theme = name
    for instance, props in pairs(self._registry) do
        if instance and instance.Parent then
            self:_apply(instance, props)
        else
            self._registry[instance] = nil
        end
    end
end

function ThemeManager:Unregister(instance)
    self._registry[instance] = nil
end

-- ─────────────────────────────────────────────────────────────
-- STATE MANAGER
-- ─────────────────────────────────────────────────────────────
local StateManager = {}
StateManager.Flags = {}
StateManager._listeners = {}

function StateManager:Set(key, value)
    self.Flags[key] = value
    if self._listeners[key] then
        for _, cb in ipairs(self._listeners[key]) do
            pcall(cb, value)
        end
    end
end

function StateManager:Get(key)
    return self.Flags[key]
end

function StateManager:Listen(key, callback)
    if not self._listeners[key] then
        self._listeners[key] = {}
    end
    table.insert(self._listeners[key], callback)
end

function StateManager:Unlisten(key)
    self._listeners[key] = nil
end

-- ─────────────────────────────────────────────────────────────
-- ANIMATION MANAGER
-- ─────────────────────────────────────────────────────────────
local AnimationManager = {}

-- Hover enter/leave effect for element frames
function AnimationManager.HoverEffect(frame, normalColor, hoverColor)
    frame.MouseEnter:Connect(function()
        Util.Tween(frame, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            BackgroundColor3 = hoverColor
        })
    end)
    frame.MouseLeave:Connect(function()
        Util.Tween(frame, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            BackgroundColor3 = normalColor
        })
    end)
end

-- Press feedback for buttons
function AnimationManager.PressEffect(frame, normalColor, pressColor)
    frame.MouseButton1Down:Connect(function()
        Util.Tween(frame, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            BackgroundColor3 = pressColor
        })
    end)
    frame.MouseButton1Up:Connect(function()
        Util.Tween(frame, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            BackgroundColor3 = normalColor
        })
    end)
end

-- ─────────────────────────────────────────────────────────────
-- PREMIUM MANAGER
-- ─────────────────────────────────────────────────────────────
local PremiumManager = {}
PremiumManager._cache = {} -- { [gamepassId] = bool }

--[[
    SECURITY NOTE (Repeated for developer awareness):
    UserOwnsGamePassAsync sends a real HTTP request to Roblox.
    A determined exploiter can:
      - Hook the function at the C-level to always return true.
      - Modify the _cache table via the executor console.
      - Patch the pcall result to override the boolean.
    This is client-only UI gating. Do NOT use for server economy/logic.
]]
function PremiumManager:Check(userId, gamepassId, callback)
    -- Return cached result immediately if available (avoids repeat calls)
    if self._cache[gamepassId] ~= nil then
        callback(self._cache[gamepassId])
        return
    end

    -- Async check via task.spawn to avoid freezing UI
    task.spawn(function()
        local success, owned = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
        end)
        local result = success and owned or false
        self._cache[gamepassId] = result
        callback(result)
    end)
end

function PremiumManager:PromptPurchase(userId, gamepassId)
    pcall(function()
        MarketplaceService:PromptGamePassPurchase(LocalPlayer, gamepassId)
    end)
end

-- ─────────────────────────────────────────────────────────────
-- CONFIG MANAGER
-- ─────────────────────────────────────────────────────────────
local ConfigManager = {}
ConfigManager._fileName = "OrbitUI_Config.json"

function ConfigManager:Save(data)
    -- Note: Premium state is intentionally excluded from saves.
    -- It must always be re-validated against Gamepass on load.
    local clean = {}
    for k, v in pairs(data) do
        if k ~= "_premium" then
            clean[k] = v
        end
    end
    local encoded = HttpService:JSONEncode(clean)
    -- writefile is available in most executors
    pcall(function()
        writefile(self._fileName, encoded)
    end)
end

function ConfigManager:Load()
    local ok, content = pcall(function()
        return readfile(self._fileName)
    end)
    if not ok or not content then return {} end
    local decoded = {}
    pcall(function()
        decoded = HttpService:JSONDecode(content)
    end)
    return decoded
end

function ConfigManager:Reset()
    pcall(function()
        writefile(self._fileName, "{}")
    end)
end

-- ─────────────────────────────────────────────────────────────
-- NOTIFICATION SYSTEM
-- ─────────────────────────────────────────────────────────────
local NotificationSystem = {}
NotificationSystem._holder = nil
NotificationSystem._queue  = {}
NotificationSystem._count  = 0

function NotificationSystem:Init(screenGui)
    self._holder = Util.New("Frame", {
        Name              = "NotifHolder",
        AnchorPoint       = Vector2.new(1, 1),
        Position          = UDim2.new(1, -16, 1, -16),
        Size              = UDim2.new(0, 300, 1, -32),
        BackgroundTransparency = 1,
        Parent            = screenGui,
        ZIndex            = 100,
    })

    local layout = Util.AddListLayout(self._holder, 10)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
end

function NotificationSystem:Send(config)
    config = config or {}
    local title    = config.Title    or "Notification"
    local content  = config.Content  or ""
    local duration = config.Duration or 4
    local type_    = config.Type     or "Info" -- Info | Success | Warning | Error

    local T = ThemeManager

    -- Accent color per type
    local typeColor = T:Get("Accent")
    if type_ == "Success" then typeColor = Color3.fromRGB(80, 190, 120)
    elseif type_ == "Warning" then typeColor = Color3.fromRGB(220, 160, 40)
    elseif type_ == "Error" then typeColor = Color3.fromRGB(210, 65, 65)
    end

    -- Notification container
    local notif = Util.New("Frame", {
        Name            = "Notification",
        Size            = UDim2.new(1, 0, 0, 0),
        AutomaticSize   = Enum.AutomaticSize.Y,
        BackgroundColor3 = T:Get("NotifBg"),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent          = self._holder,
        ZIndex          = 101,
        LayoutOrder     = 0,
    })
    Util.AddCorner(notif, 10)
    local stroke = Util.AddStroke(notif, T:Get("NotifBorder"), 0.5, 1)

    -- Left accent bar
    local bar = Util.New("Frame", {
        Name             = "Bar",
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = typeColor,
        BorderSizePixel  = 0,
        Parent           = notif,
        ZIndex           = 102,
    })
    Util.AddCorner(bar, 3)

    -- Content area
    local inner = Util.New("Frame", {
        Name             = "Inner",
        Position         = UDim2.new(0, 11, 0, 0),
        Size             = UDim2.new(1, -11, 1, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent           = notif,
        ZIndex           = 102,
    })
    Util.AddPadding(inner, 10, 10, 4, 8)

    local titleLabel = Util.New("TextLabel", {
        Name             = "Title",
        Size             = UDim2.new(1, 0, 0, 16),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text             = title,
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextColor3       = T:Get("Text"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        Parent           = inner,
        ZIndex           = 103,
    })
    T:Tag(titleLabel, {TextColor3 = "Text"})

    local contentLabel = Util.New("TextLabel", {
        Name             = "Content",
        LayoutOrder      = 1,
        Size             = UDim2.new(1, 0, 0, 14),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text             = content,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextColor3       = T:Get("SubText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        Parent           = inner,
        ZIndex           = 103,
    })
    T:Tag(contentLabel, {TextColor3 = "SubText"})

    local innerLayout = Util.AddListLayout(inner, 4)
    innerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    -- Progress bar at bottom
    local progressBg = Util.New("Frame", {
        Name             = "ProgressBg",
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = T:Get("Border"),
        BorderSizePixel  = 0,
        Parent           = notif,
        ZIndex           = 103,
    })
    local progressFill = Util.New("Frame", {
        Name             = "Fill",
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = typeColor,
        BorderSizePixel  = 0,
        Parent           = progressBg,
        ZIndex           = 104,
    })

    -- Animate in
    Util.Tween(notif, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
        BackgroundTransparency = 0.12
    })
    Util.Tween(stroke, 0.22, nil, nil, { Transparency = 0.5 })

    -- Progress drain tween
    Util.Tween(progressFill, duration - 0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {
        Size = UDim2.new(0, 0, 1, 0)
    })

    -- Animate out after duration
    task.delay(duration - 0.3, function()
        Util.Tween(notif, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            BackgroundTransparency = 1
        })
        Util.Tween(stroke, 0.25, nil, nil, { Transparency = 1 })
        task.delay(0.3, function()
            if notif and notif.Parent then
                notif:Destroy()
            end
        end)
    end)
end

-- ─────────────────────────────────────────────────────────────
-- ELEMENT BUILDER (shared UI component factory)
-- ─────────────────────────────────────────────────────────────
local function BuildElementFrame(container, title, desc, withButton)
    local T = ThemeManager
    local height = (desc and desc ~= "") and 54 or 38

    local frame = Util.New("TextButton", {
        Name             = "Element_" .. title,
        Size             = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = T:Get("Element"),
        AutoButtonColor  = false,
        Text             = "",
        Parent           = container,
    })
    Util.AddCorner(frame, 8)
    Util.AddStroke(frame, T:Get("ElementStroke"), 0.7, 1)
    T:Tag(frame, {BackgroundColor3 = "Element"})

    AnimationManager.HoverEffect(frame, T:Get("Element"), T:Get("ElementHover"))

    local titleLabel = Util.New("TextLabel", {
        Name             = "Title",
        AnchorPoint      = Vector2.new(0, 0),
        Position         = UDim2.new(0, 10, 0, (height == 38) and 11 or 8),
        Size             = UDim2.new(1, -120, 0, 16),
        BackgroundTransparency = 1,
        Text             = title,
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 13,
        TextColor3       = T:Get("Text"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        Parent           = frame,
    })
    T:Tag(titleLabel, {TextColor3 = "Text"})

    local descLabel
    if desc and desc ~= "" then
        descLabel = Util.New("TextLabel", {
            Name             = "Desc",
            AnchorPoint      = Vector2.new(0, 0),
            Position         = UDim2.new(0, 10, 0, 28),
            Size             = UDim2.new(1, -120, 0, 14),
            BackgroundTransparency = 1,
            Text             = desc,
            Font             = Enum.Font.Gotham,
            TextSize         = 11,
            TextColor3       = T:Get("SubText"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextTruncate     = Enum.TextTruncate.AtEnd,
            Parent           = frame,
        })
        T:Tag(descLabel, {TextColor3 = "SubText"})
    end

    return frame, titleLabel, descLabel
end

-- ─────────────────────────────────────────────────────────────
-- TAB ELEMENT METHODS (all components added to a Tab)
-- ─────────────────────────────────────────────────────────────
local ElementMethods = {}

-- ── Button ──────────────────────────────────────────────────
function ElementMethods:AddButton(config)
    assert(config and config.Title, "[Orbit] Button requires Title")
    config.Callback = config.Callback or function() end
    local T = ThemeManager

    local frame, titleLabel = BuildElementFrame(self._container, config.Title, config.Desc)

    -- Arrow icon on right
    local icon = Util.New("TextLabel", {
        Name             = "Arrow",
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -10, 0.5, 0),
        Size             = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
        Text             = "›",
        Font             = Enum.Font.GothamBold,
        TextSize         = 18,
        TextColor3       = T:Get("AccentText"),
        Parent           = frame,
    })
    T:Tag(icon, {TextColor3 = "AccentText"})

    AnimationManager.PressEffect(frame, T:Get("Element"), T:Get("AccentDim"))

    frame.MouseButton1Click:Connect(function()
        pcall(config.Callback)
    end)

    local obj = {Type = "Button", _frame = frame}
    function obj:SetTitle(t) titleLabel.Text = t end
    return obj
end

-- ── Toggle ───────────────────────────────────────────────────
function ElementMethods:AddToggle(config)
    assert(config and config.Title, "[Orbit] Toggle requires Title")
    config.Callback = config.Callback or function() end
    local T = ThemeManager

    local frame, titleLabel = BuildElementFrame(self._container, config.Title, config.Desc)

    -- Toggle pill
    local pill = Util.New("Frame", {
        Name             = "Pill",
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -10, 0.5, 0),
        Size             = UDim2.new(0, 38, 0, 20),
        BackgroundColor3 = T:Get("ToggleOff"),
        Parent           = frame,
    })
    Util.AddCorner(pill, 10)
    Util.AddStroke(pill, T:Get("Border"), 0.6, 1)
    T:Tag(pill, {BackgroundColor3 = "ToggleOff"})

    -- Knob
    local knob = Util.New("Frame", {
        Name             = "Knob",
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 3, 0.5, 0),
        Size             = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = T:Get("ToggleKnob"),
        Parent           = pill,
    })
    Util.AddCorner(knob, 7)
    T:Tag(knob, {BackgroundColor3 = "ToggleKnob"})

    local toggle = {
        Type     = "Toggle",
        Value    = config.Default or false,
        _frame   = frame,
        _pill    = pill,
        _knob    = knob,
        _cb      = config.Callback,
        _flagKey = config.Flag,
    }

    local function applyVisual(val)
        local targetX = val and 21 or 3
        local pillColor = val and T:Get("ToggleOn") or T:Get("ToggleOff")
        Util.Tween(knob, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            Position = UDim2.new(0, targetX, 0.5, 0)
        })
        Util.Tween(pill, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            BackgroundColor3 = pillColor
        })
    end

    function toggle:SetValue(val)
        self.Value = val
        applyVisual(val)
        if self._flagKey then StateManager:Set(self._flagKey, val) end
        pcall(self._cb, val)
    end

    function toggle:GetValue() return self.Value end
    function toggle:SetTitle(t) titleLabel.Text = t end

    -- Apply default
    applyVisual(toggle.Value)
    if toggle._flagKey then StateManager:Set(toggle._flagKey, toggle.Value) end

    frame.MouseButton1Click:Connect(function()
        toggle:SetValue(not toggle.Value)
    end)

    return toggle
end

-- ── Slider ───────────────────────────────────────────────────
function ElementMethods:AddSlider(config)
    assert(config and config.Title, "[Orbit] Slider requires Title")
    assert(config.Min ~= nil and config.Max ~= nil, "[Orbit] Slider requires Min and Max")
    config.Default  = config.Default  or config.Min
    config.Rounding = config.Rounding or 1
    config.Callback = config.Callback or function() end
    local T = ThemeManager

    local frame = Util.New("Frame", {
        Name             = "Slider_" .. config.Title,
        Size             = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = T:Get("Element"),
        Parent           = self._container,
    })
    Util.AddCorner(frame, 8)
    Util.AddStroke(frame, T:Get("ElementStroke"), 0.7, 1)
    T:Tag(frame, {BackgroundColor3 = "Element"})
    AnimationManager.HoverEffect(frame, T:Get("Element"), T:Get("ElementHover"))

    local titleLabel = Util.New("TextLabel", {
        Name             = "Title",
        Position         = UDim2.new(0, 10, 0, 8),
        Size             = UDim2.new(0.7, -10, 0, 16),
        BackgroundTransparency = 1,
        Text             = config.Title,
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 13,
        TextColor3       = T:Get("Text"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = frame,
    })
    T:Tag(titleLabel, {TextColor3 = "Text"})

    local valueLabel = Util.New("TextLabel", {
        Name             = "Value",
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, -10, 0, 8),
        Size             = UDim2.new(0.3, 0, 0, 16),
        BackgroundTransparency = 1,
        Text             = tostring(config.Default),
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 12,
        TextColor3       = T:Get("AccentText"),
        TextXAlignment   = Enum.TextXAlignment.Right,
        Parent           = frame,
    })
    T:Tag(valueLabel, {TextColor3 = "AccentText"})

    -- Rail
    local railBg = Util.New("Frame", {
        Name             = "RailBg",
        AnchorPoint      = Vector2.new(0, 0),
        Position         = UDim2.new(0, 10, 0, 34),
        Size             = UDim2.new(1, -20, 0, 5),
        BackgroundColor3 = T:Get("SliderRail"),
        Parent           = frame,
    })
    Util.AddCorner(railBg, 3)
    T:Tag(railBg, {BackgroundColor3 = "SliderRail"})

    local railFill = Util.New("Frame", {
        Name             = "Fill",
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T:Get("SliderFill"),
        Parent           = railBg,
    })
    Util.AddCorner(railFill, 3)
    T:Tag(railFill, {BackgroundColor3 = "SliderFill"})

    -- Knob
    local sliderKnob = Util.New("Frame", {
        Name             = "Knob",
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = T:Get("SliderKnob"),
        Parent           = railBg,
    })
    Util.AddCorner(sliderKnob, 7)
    T:Tag(sliderKnob, {BackgroundColor3 = "SliderKnob"})

    local slider = {
        Type     = "Slider",
        Value    = config.Default,
        Min      = config.Min,
        Max      = config.Max,
        Rounding = config.Rounding,
        _frame   = frame,
        _cb      = config.Callback,
        _flagKey = config.Flag,
    }

    local dragging = false

    local function updateSlider(val)
        local clamped  = math.clamp(val, slider.Min, slider.Max)
        local rounded  = math.floor(clamped / slider.Rounding + 0.5) * slider.Rounding
        slider.Value   = rounded
        local pct      = (rounded - slider.Min) / (slider.Max - slider.Min)
        railFill.Size  = UDim2.new(pct, 0, 1, 0)
        sliderKnob.Position = UDim2.new(pct, 0, 0.5, 0)
        valueLabel.Text = tostring(rounded)
        if slider._flagKey then StateManager:Set(slider._flagKey, rounded) end
    end

    local function onInput(input)
        local rel   = input.Position.X - railBg.AbsolutePosition.X
        local pct   = math.clamp(rel / railBg.AbsoluteSize.X, 0, 1)
        local val   = slider.Min + pct * (slider.Max - slider.Min)
        updateSlider(val)
        pcall(slider._cb, slider.Value)
    end

    railBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            onInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            onInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    updateSlider(config.Default)
    if slider._flagKey then StateManager:Set(slider._flagKey, slider.Value) end

    function slider:SetValue(val)
        updateSlider(val)
    end
    function slider:GetValue() return self.Value end
    function slider:SetTitle(t) titleLabel.Text = t end

    return slider
end

-- ── Dropdown ─────────────────────────────────────────────────
function ElementMethods:AddDropdown(config)
    assert(config and config.Title, "[Orbit] Dropdown requires Title")
    config.Options  = config.Options  or {}
    config.Default  = config.Default  or (config.Options[1] or "")
    config.Callback = config.Callback or function() end
    local T = ThemeManager

    local frame = Util.New("Frame", {
        Name             = "Dropdown_" .. config.Title,
        Size             = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = T:Get("Element"),
        ClipsDescendants = false,
        Parent           = self._container,
    })
    Util.AddCorner(frame, 8)
    Util.AddStroke(frame, T:Get("ElementStroke"), 0.7, 1)
    T:Tag(frame, {BackgroundColor3 = "Element"})

    local titleLabel = Util.New("TextLabel", {
        Position         = UDim2.new(0, 10, 0, 12),
        Size             = UDim2.new(0.5, -10, 0, 16),
        BackgroundTransparency = 1,
        Text             = config.Title,
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 13,
        TextColor3       = T:Get("Text"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = frame,
    })
    T:Tag(titleLabel, {TextColor3 = "Text"})

    -- Display box (right side)
    local display = Util.New("TextButton", {
        Name             = "Display",
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -8, 0.5, 0),
        Size             = UDim2.new(0, 150, 0, 26),
        BackgroundColor3 = T:Get("DropdownBg"),
        AutoButtonColor  = false,
        Text             = "",
        Parent           = frame,
    })
    Util.AddCorner(display, 6)
    Util.AddStroke(display, T:Get("Border"), 0.6, 1)
    T:Tag(display, {BackgroundColor3 = "DropdownBg"})

    local displayText = Util.New("TextLabel", {
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 8, 0.5, 0),
        Size             = UDim2.new(1, -28, 0, 14),
        BackgroundTransparency = 1,
        Text             = config.Default,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextColor3       = T:Get("Text"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        Parent           = display,
    })
    T:Tag(displayText, {TextColor3 = "Text"})

    local chevron = Util.New("TextLabel", {
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -6, 0.5, 0),
        Size             = UDim2.new(0, 16, 0, 16),
        BackgroundTransparency = 1,
        Text             = "▾",
        Font             = Enum.Font.GothamBold,
        TextSize         = 12,
        TextColor3       = T:Get("SubText"),
        Parent           = display,
    })
    T:Tag(chevron, {TextColor3 = "SubText"})

    -- Dropdown list (floats below)
    local listHolder = Util.New("Frame", {
        Name             = "ListHolder",
        AnchorPoint      = Vector2.new(0, 0),
        Position         = UDim2.new(0, 0, 1, 4),
        Size             = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = T:Get("DropdownBg"),
        ClipsDescendants = true,
        Visible          = false,
        ZIndex           = 20,
        Parent           = frame,
    })
    Util.AddCorner(listHolder, 8)
    Util.AddStroke(listHolder, T:Get("Border"), 0.5, 1)
    T:Tag(listHolder, {BackgroundColor3 = "DropdownBg"})

    local list = Util.New("ScrollingFrame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T:Get("Accent"),
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        Parent           = listHolder,
    })
    Util.AddListLayout(list, 2)
    Util.AddPadding(list, 4, 4, 4, 4)

    local dropdown = {
        Type     = "Dropdown",
        Value    = config.Default,
        Options  = config.Options,
        _frame   = frame,
        _cb      = config.Callback,
        _flagKey = config.Flag,
        _open    = false,
    }

    local function buildList()
        -- Clear existing
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local itemH = 28
        local totalH = math.min(#dropdown.Options * (itemH + 2) + 8, 160)
        list.CanvasSize = UDim2.new(0, 0, 0, #dropdown.Options * (itemH + 2) + 8)

        for _, opt in ipairs(dropdown.Options) do
            local item = Util.New("TextButton", {
                Name             = "Item_" .. opt,
                Size             = UDim2.new(1, -8, 0, itemH),
                BackgroundColor3 = opt == dropdown.Value and T:Get("SurfaceHover") or T:Get("DropdownItem"),
                AutoButtonColor  = false,
                Text             = opt,
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextColor3       = opt == dropdown.Value and T:Get("AccentText") or T:Get("Text"),
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 21,
                Parent           = list,
            })
            Util.AddCorner(item, 5)
            Util.AddPadding(item, 0, 0, 8, 0)
            T:Tag(item, {TextColor3 = opt == dropdown.Value and "AccentText" or "Text"})
            AnimationManager.HoverEffect(item, T:Get("DropdownItem"), T:Get("DropdownHover"))

            item.MouseButton1Click:Connect(function()
                dropdown.Value = opt
                displayText.Text = opt
                dropdown:Close()
                if dropdown._flagKey then StateManager:Set(dropdown._flagKey, opt) end
                pcall(dropdown._cb, opt)
                buildList()
            end)
        end

        return totalH
    end

    function dropdown:Open()
        self._open = true
        listHolder.Visible = true
        local h = buildList()
        Util.Tween(listHolder, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            Size = UDim2.new(1, 0, 0, h)
        })
        Util.Tween(chevron, 0.15, nil, nil, {Rotation = 180})
    end

    function dropdown:Close()
        self._open = false
        Util.Tween(listHolder, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            Size = UDim2.new(1, 0, 0, 0)
        })
        Util.Tween(chevron, 0.15, nil, nil, {Rotation = 0})
        task.delay(0.16, function()
            if not self._open then listHolder.Visible = false end
        end)
    end

    function dropdown:SetOptions(opts)
        self.Options = opts
        if self._open then buildList() end
    end

    function dropdown:SetValue(val)
        self.Value = val
        displayText.Text = val
        if self._flagKey then StateManager:Set(self._flagKey, val) end
    end

    function dropdown:GetValue() return self.Value end

    display.MouseButton1Click:Connect(function()
        if dropdown._open then dropdown:Close() else dropdown:Open() end
    end)

    if dropdown._flagKey then StateManager:Set(dropdown._flagKey, dropdown.Value) end
    buildList()

    return dropdown
end

-- ── Paragraph ────────────────────────────────────────────────
function ElementMethods:AddParagraph(config)
    config = config or {}
    local T = ThemeManager

    local frame = Util.New("Frame", {
        Name             = "Para_" .. (config.Title or ""),
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundColor3 = T:Get("Element"),
        Parent           = self._container,
    })
    Util.AddCorner(frame, 8)
    Util.AddStroke(frame, T:Get("ElementStroke"), 0.7, 1)
    Util.AddPadding(frame, 10, 10, 10, 10)
    T:Tag(frame, {BackgroundColor3 = "Element"})

    local layout = Util.AddListLayout(frame, 4)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    if config.Title and config.Title ~= "" then
        local t = Util.New("TextLabel", {
            Name             = "PTitle",
            Size             = UDim2.new(1, 0, 0, 16),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text             = config.Title,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 13,
            TextColor3       = T:Get("Text"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            Parent           = frame,
        })
        T:Tag(t, {TextColor3 = "Text"})
    end

    local content = Util.New("TextLabel", {
        Name             = "PContent",
        Size             = UDim2.new(1, 0, 0, 14),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text             = config.Content or "",
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextColor3       = T:Get("SubText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        RichText         = true,
        Parent           = frame,
    })
    T:Tag(content, {TextColor3 = "SubText"})

    local obj = {Type = "Paragraph", _frame = frame}
    function obj:SetContent(t) content.Text = t end
    return obj
end

-- ── Label ────────────────────────────────────────────────────
function ElementMethods:AddLabel(config)
    config = config or {}
    local T = ThemeManager

    local label = Util.New("TextLabel", {
        Name             = "Label",
        Size             = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text             = config.Text or "",
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextColor3       = T:Get("DimText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        RichText         = true,
        Parent           = self._container,
    })
    Util.AddPadding(label, 0, 0, 10, 0)
    T:Tag(label, {TextColor3 = "DimText"})

    local obj = {Type = "Label", _frame = label}
    function obj:SetText(t) label.Text = t end
    return obj
end

-- ── Section Divider ───────────────────────────────────────────
function ElementMethods:AddSection(config)
    config = config or {}
    local T = ThemeManager

    local section = Util.New("Frame", {
        Name             = "Section",
        Size             = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent           = self._container,
    })

    -- Left accent mark
    local mark = Util.New("Frame", {
        Name             = "Mark",
        Size             = UDim2.new(0, 3, 0, 14),
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = T:Get("Accent"),
        Parent           = section,
    })
    Util.AddCorner(mark, 2)
    T:Tag(mark, {BackgroundColor3 = "Accent"})

    local sectionTitle = Util.New("TextLabel", {
        Name             = "STitle",
        Position         = UDim2.new(0, 10, 0, 0),
        Size             = UDim2.new(1, -10, 1, 0),
        BackgroundTransparency = 1,
        Text             = config.Title or "",
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = T:Get("SectionText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = section,
    })
    T:Tag(sectionTitle, {TextColor3 = "SectionText"})

    -- Horizontal line
    local line = Util.New("Frame", {
        Name             = "Line",
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T:Get("SectionLine"),
        Parent           = section,
    })
    T:Tag(line, {BackgroundColor3 = "SectionLine"})

    return {Type = "Section", _frame = section}
end

-- ── Keybind ───────────────────────────────────────────────────
function ElementMethods:AddKeybind(config)
    assert(config and config.Title, "[Orbit] Keybind requires Title")
    config.Default  = config.Default  or Enum.KeyCode.Unknown
    config.Callback = config.Callback or function() end
    local T = ThemeManager

    local frame, titleLabel = BuildElementFrame(self._container, config.Title, config.Desc)

    local display = Util.New("TextButton", {
        Name             = "KeyDisplay",
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -8, 0.5, 0),
        Size             = UDim2.new(0, 70, 0, 24),
        BackgroundColor3 = T:Get("DropdownBg"),
        AutoButtonColor  = false,
        Text             = config.Default.Name,
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 11,
        TextColor3       = T:Get("AccentText"),
        Parent           = frame,
    })
    Util.AddCorner(display, 5)
    Util.AddStroke(display, T:Get("Border"), 0.6, 1)
    T:Tag(display, {BackgroundColor3 = "DropdownBg"})
    T:Tag(display, {TextColor3 = "AccentText"})

    local keybind = {
        Type     = "Keybind",
        Value    = config.Default,
        _picking = false,
        _frame   = frame,
        _cb      = config.Callback,
        _flagKey = config.Flag,
    }

    if keybind._flagKey then StateManager:Set(keybind._flagKey, keybind.Value) end

    display.MouseButton1Click:Connect(function()
        if keybind._picking then return end
        keybind._picking = true
        display.Text = "..."
        display.TextColor3 = T:Get("SubText")
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if keybind._picking then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybind._picking = false
                keybind.Value = input.KeyCode
                display.Text = input.KeyCode.Name
                display.TextColor3 = T:Get("AccentText")
                if keybind._flagKey then StateManager:Set(keybind._flagKey, input.KeyCode) end
                pcall(keybind._cb, input.KeyCode)
            end
        else
            if not gpe and input.KeyCode == keybind.Value then
                pcall(keybind._cb, keybind.Value)
            end
        end
    end)

    function keybind:SetValue(kc)
        self.Value = kc
        display.Text = kc.Name
    end
    function keybind:GetValue() return self.Value end
    function keybind:SetTitle(t) titleLabel.Text = t end

    return keybind
end

-- ── Input Box ────────────────────────────────────────────────
function ElementMethods:AddInput(config)
    assert(config and config.Title, "[Orbit] Input requires Title")
    config.Placeholder = config.Placeholder or "Enter text..."
    config.Callback    = config.Callback    or function() end
    local T = ThemeManager

    local frame = Util.New("Frame", {
        Name             = "Input_" .. config.Title,
        Size             = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = T:Get("Element"),
        Parent           = self._container,
    })
    Util.AddCorner(frame, 8)
    Util.AddStroke(frame, T:Get("ElementStroke"), 0.7, 1)
    T:Tag(frame, {BackgroundColor3 = "Element"})
    AnimationManager.HoverEffect(frame, T:Get("Element"), T:Get("ElementHover"))

    local titleLabel = Util.New("TextLabel", {
        Position         = UDim2.new(0, 10, 0, 7),
        Size             = UDim2.new(1, -20, 0, 14),
        BackgroundTransparency = 1,
        Text             = config.Title,
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 12,
        TextColor3       = T:Get("SubText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = frame,
    })
    T:Tag(titleLabel, {TextColor3 = "SubText"})

    local inputBg = Util.New("Frame", {
        Name             = "InputBg",
        Position         = UDim2.new(0, 8, 0, 26),
        Size             = UDim2.new(1, -16, 0, 22),
        BackgroundColor3 = T:Get("InputBg"),
        Parent           = frame,
    })
    Util.AddCorner(inputBg, 5)
    Util.AddStroke(inputBg, T:Get("Border"), 0.5, 1)
    T:Tag(inputBg, {BackgroundColor3 = "InputBg"})

    local box = Util.New("TextBox", {
        Name             = "Box",
        Position         = UDim2.new(0, 6, 0, 0),
        Size             = UDim2.new(1, -12, 1, 0),
        BackgroundTransparency = 1,
        Text             = config.Default or "",
        PlaceholderText  = config.Placeholder,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextColor3       = T:Get("Text"),
        PlaceholderColor3 = T:Get("DimText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent           = inputBg,
    })
    T:Tag(box, {TextColor3 = "Text"})

    local stroke = inputBg:FindFirstChildOfClass("UIStroke")

    box.Focused:Connect(function()
        Util.Tween(inputBg, 0.15, nil, nil, {BackgroundColor3 = T:Get("InputFocused")})
        if stroke then
            Util.Tween(stroke, 0.15, nil, nil, {Color = T:Get("Accent"), Transparency = 0.3})
        end
    end)

    box.FocusLost:Connect(function(enter)
        Util.Tween(inputBg, 0.15, nil, nil, {BackgroundColor3 = T:Get("InputBg")})
        if stroke then
            Util.Tween(stroke, 0.15, nil, nil, {Color = T:Get("Border"), Transparency = 0.5})
        end
        if enter then
            pcall(config.Callback, box.Text)
        end
    end)

    local input = {
        Type  = "Input",
        _frame = frame,
        _box  = box,
    }
    function input:GetValue() return box.Text end
    function input:SetValue(v) box.Text = v end
    function input:SetTitle(t) titleLabel.Text = t end
    return input
end

-- ─────────────────────────────────────────────────────────────
-- MAIN LIBRARY
-- ─────────────────────────────────────────────────────────────
local Library = {}
Library.Flags    = StateManager.Flags
Library.Version  = "1.0.0"
Library._windows = {}

-- ── Helper: create the ScreenGui safely ──────────────────────
local function createScreenGui(title)
    local gui
    -- Try executor's gethui first (avoids ScreenGui destruction on reset)
    pcall(function()
        if type(gethui) == "function" then
            gui = Util.New("ScreenGui", {
                Name           = title,
                ResetOnSpawn   = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                Parent         = gethui(),
            })
        end
    end)
    -- Fall back to CoreGui
    if not gui then
        pcall(function()
            gui = Util.New("ScreenGui", {
                Name           = title,
                ResetOnSpawn   = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                Parent         = game:GetService("CoreGui"),
            })
        end)
    end
    -- Final fallback to PlayerGui
    if not gui then
        gui = Util.New("ScreenGui", {
            Name           = title,
            ResetOnSpawn   = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent         = LocalPlayer:WaitForChild("PlayerGui"),
        })
    end
    return gui
end

-- ── Create Window ────────────────────────────────────────────
function Library:CreateWindow(config)
    config = config or {}
    assert(config.Title, "[Orbit] Window requires Title")
    config.Theme    = config.Theme    or "Amethyst"
    config.Size     = config.Size     or Vector2.new(580, 400)
    config.Position = config.Position or nil -- nil = center

    -- Apply initial theme
    ThemeManager:SetTheme(config.Theme)
    local T = ThemeManager

    -- ── ScreenGui ──
    local gui = createScreenGui("OrbitUI_" .. config.Title)
    NotificationSystem:Init(gui)

    local vp = Camera.ViewportSize
    local winW, winH = config.Size.X, config.Size.Y
    local startX = config.Position and config.Position.X or (vp.X / 2 - winW / 2)
    local startY = config.Position and config.Position.Y or (vp.Y / 2 - winH / 2)

    -- ── Root frame ──
    local root = Util.New("Frame", {
        Name             = "OrbitWindow",
        Size             = UDim2.fromOffset(winW, winH),
        Position         = UDim2.fromOffset(startX, startY),
        BackgroundColor3 = T:Get("Background"),
        BorderSizePixel  = 0,
        Parent           = gui,
    })
    Util.AddCorner(root, 12)
    Util.AddStroke(root, T:Get("Border"), 0.5, 1)
    T:Tag(root, {BackgroundColor3 = "Background"})

    -- Drop shadow
    local shadow = Util.New("ImageLabel", {
        Name             = "Shadow",
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 6),
        Size             = UDim2.new(1, 36, 1, 36),
        BackgroundTransparency = 1,
        Image            = "rbxassetid://6015897843",
        ImageColor3      = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.55,
        ScaleType        = Enum.ScaleType.Slice,
        SliceCenter      = Rect.new(49, 49, 450, 450),
        ZIndex           = -1,
        Parent           = root,
    })

    -- ── Title Bar ──────────────────────────────────────────
    local titleBar = Util.New("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = T:Get("TitleBar"),
        BorderSizePixel  = 0,
        Parent           = root,
        ZIndex           = 3,
    })
    -- Rounded only on top
    Util.AddCorner(titleBar, 12)

    -- Extend bottom of title bar to cover lower corners
    local titleBarExtend = Util.New("Frame", {
        Name             = "TitleBarExt",
        Position         = UDim2.new(0, 0, 0, 36),
        Size             = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = T:Get("TitleBar"),
        BorderSizePixel  = 0,
        Parent           = root,
        ZIndex           = 3,
    })
    T:Tag(titleBar,       {BackgroundColor3 = "TitleBar"})
    T:Tag(titleBarExtend, {BackgroundColor3 = "TitleBar"})

    -- Title bar bottom border line
    local titleLine = Util.New("Frame", {
        Name             = "TitleLine",
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T:Get("TitleBarLine"),
        BorderSizePixel  = 0,
        Parent           = titleBarExtend,
        ZIndex           = 3,
    })
    T:Tag(titleLine, {BackgroundColor3 = "TitleBarLine"})

    -- Logo / accent dot
    local accentDot = Util.New("Frame", {
        Name             = "AccentDot",
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 14, 0.5, 0),
        Size             = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = T:Get("Accent"),
        BorderSizePixel  = 0,
        Parent           = titleBar,
        ZIndex           = 4,
    })
    Util.AddCorner(accentDot, 4)
    T:Tag(accentDot, {BackgroundColor3 = "Accent"})

    local titleLabel = Util.New("TextLabel", {
        Name             = "WindowTitle",
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 28, 0.5, 0),
        Size             = UDim2.new(0.6, -28, 0, 18),
        BackgroundTransparency = 1,
        Text             = config.Title,
        Font             = Enum.Font.GothamBold,
        TextSize         = 14,
        TextColor3       = T:Get("Text"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = titleBar,
        ZIndex           = 4,
    })
    T:Tag(titleLabel, {TextColor3 = "Text"})

    local subLabel
    if config.SubTitle then
        subLabel = Util.New("TextLabel", {
            Name             = "SubTitle",
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 28, 0.5, 10),
            Size             = UDim2.new(0.6, -28, 0, 12),
            BackgroundTransparency = 1,
            Text             = config.SubTitle,
            Font             = Enum.Font.Gotham,
            TextSize         = 11,
            TextColor3       = T:Get("SubText"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = titleBar,
            ZIndex           = 4,
        })
        T:Tag(subLabel, {TextColor3 = "SubText"})
        titleLabel.Position = UDim2.new(0, 28, 0.5, -7)
    end

    -- Close + Minimize buttons on right of title bar
    local function makeTitleBtn(offsetX, symbol, color)
        local btn = Util.New("TextButton", {
            Name             = symbol,
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, -offsetX, 0.5, 0),
            Size             = UDim2.new(0, 26, 0, 26),
            BackgroundColor3 = T:Get("Surface"),
            AutoButtonColor  = false,
            Text             = symbol,
            Font             = Enum.Font.GothamBold,
            TextSize         = 12,
            TextColor3       = color,
            Parent           = titleBar,
            ZIndex           = 5,
        })
        Util.AddCorner(btn, 13)
        T:Tag(btn, {BackgroundColor3 = "Surface"})
        AnimationManager.HoverEffect(btn, T:Get("Surface"), T:Get("SurfaceHover"))
        AnimationManager.PressEffect(btn, T:Get("Surface"), T:Get("SurfaceLight"))
        return btn
    end

    local closeBtn    = makeTitleBtn(10, "✕", Color3.fromRGB(220, 80, 80))
    local minimizeBtn = makeTitleBtn(42, "—", T:Get("SubText"))

    -- ── Sidebar ────────────────────────────────────────────
    local SIDEBAR_W = 148

    local sidebar = Util.New("Frame", {
        Name             = "Sidebar",
        Position         = UDim2.new(0, 0, 0, 48),
        Size             = UDim2.new(0, SIDEBAR_W, 1, -48),
        BackgroundColor3 = T:Get("TabBg"),
        BorderSizePixel  = 0,
        Parent           = root,
        ZIndex           = 2,
    })
    -- Rounded on bottom-left only
    Util.AddCorner(sidebar, 12)
    local sidebarTopCover = Util.New("Frame", {
        Name             = "SidebarTopCover",
        Size             = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = T:Get("TabBg"),
        BorderSizePixel  = 0,
        Parent           = sidebar,
    })
    T:Tag(sidebar,          {BackgroundColor3 = "TabBg"})
    T:Tag(sidebarTopCover,  {BackgroundColor3 = "TabBg"})

    -- Right border of sidebar
    local sidebarBorder = Util.New("Frame", {
        Name             = "SBorder",
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = T:Get("SidebarBorder"),
        BorderSizePixel  = 0,
        Parent           = sidebar,
    })
    T:Tag(sidebarBorder, {BackgroundColor3 = "SidebarBorder"})

    -- Tab scroll frame inside sidebar
    local tabScroll = Util.New("ScrollingFrame", {
        Name             = "TabScroll",
        Position         = UDim2.new(0, 0, 0, 12),
        Size             = UDim2.new(1, -1, 1, -12),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T:Get("Accent"),
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent           = sidebar,
        ZIndex           = 3,
    })
    local tabLayout = Util.AddListLayout(tabScroll, 3)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Util.AddPadding(tabScroll, 6, 6, 6, 6)

    -- Auto-canvas on tab list changes
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 12)
    end)

    -- Active tab indicator (left accent bar)
    local tabIndicator = Util.New("Frame", {
        Name             = "Indicator",
        AnchorPoint      = Vector2.new(0, 0),
        Position         = UDim2.new(0, 0, 0, 18),
        Size             = UDim2.new(0, 3, 0, 20),
        BackgroundColor3 = T:Get("Accent"),
        BorderSizePixel  = 0,
        Parent           = sidebar,
        ZIndex           = 4,
    })
    Util.AddCorner(tabIndicator, 2)
    T:Tag(tabIndicator, {BackgroundColor3 = "Accent"})

    -- ── Content Area ───────────────────────────────────────
    local contentArea = Util.New("Frame", {
        Name             = "ContentArea",
        Position         = UDim2.new(0, SIDEBAR_W, 0, 48),
        Size             = UDim2.new(1, -SIDEBAR_W, 1, -48),
        BackgroundColor3 = T:Get("Surface"),
        BorderSizePixel  = 0,
        Parent           = root,
        ZIndex           = 2,
        ClipsDescendants = true,
    })
    Util.AddCorner(contentArea, 12)
    local contentTopCover = Util.New("Frame", {
        Name             = "ContentTopCover",
        Size             = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = T:Get("Surface"),
        BorderSizePixel  = 0,
        Parent           = contentArea,
    })
    local contentLeftCover = Util.New("Frame", {
        Name             = "ContentLeftCover",
        Size             = UDim2.new(0, 12, 1, 0),
        BackgroundColor3 = T:Get("Surface"),
        BorderSizePixel  = 0,
        Parent           = contentArea,
    })
    T:Tag(contentArea,        {BackgroundColor3 = "Surface"})
    T:Tag(contentTopCover,    {BackgroundColor3 = "Surface"})
    T:Tag(contentLeftCover,   {BackgroundColor3 = "Surface"})

    -- Container holder (pages live here)
    local containerHolder = Util.New("Frame", {
        Name             = "ContainerHolder",
        Size             = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent           = contentArea,
        ZIndex           = 2,
    })

    -- ── Mini Square (minimized state) ─────────────────────
    -- Very small rounded square, draggable, click to restore
    local miniSquare = Util.New("TextButton", {
        Name             = "MiniSquare",
        Position         = UDim2.fromOffset(startX, startY),
        Size             = UDim2.fromOffset(42, 42),
        BackgroundColor3 = T:Get("Accent"),
        AutoButtonColor  = false,
        Text             = "",
        Visible          = false,
        ZIndex           = 50,
        Parent           = gui,
    })
    Util.AddCorner(miniSquare, 11)
    Util.AddStroke(miniSquare, T:Get("AccentLight"), 0.4, 1)
    T:Tag(miniSquare, {BackgroundColor3 = "Accent"})

    -- Logo glyph inside mini square
    local miniGlyph = Util.New("TextLabel", {
        Name             = "Glyph",
        Size             = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text             = "◉",
        Font             = Enum.Font.GothamBold,
        TextSize         = 18,
        TextColor3       = Color3.fromRGB(255, 255, 255),
        Parent           = miniSquare,
        ZIndex           = 51,
    })

    -- Mini square glow pulse (subtle)
    task.spawn(function()
        while miniSquare and miniSquare.Parent do
            if miniSquare.Visible then
                Util.Tween(miniSquare, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                    {BackgroundColor3 = T:Get("AccentLight")})
                task.wait(0.85)
                if not miniSquare.Visible then break end
                Util.Tween(miniSquare, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                    {BackgroundColor3 = T:Get("Accent")})
                task.wait(0.85)
            else
                task.wait(0.2)
            end
        end
    end)

    -- ── Window Object ──────────────────────────────────────
    local Window = {
        _gui        = gui,
        _root       = root,
        _sidebar    = sidebar,
        _tabs       = {},
        _tabCount   = 0,
        _activeTab  = nil,
        _minimized  = false,
        _miniPos    = Vector2.new(startX, startY),
        _connections = {},
    }

    -- ── Drag logic (title bar) ──────────────────────────────
    do
        local dragging, dragStart, startPos = false, nil, nil

        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                dragStart = input.Position
                startPos  = root.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                root.Position = UDim2.fromOffset(
                    startPos.X.Offset + delta.X,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- ── Drag logic (mini square) ────────────────────────────
    do
        local dragging, dragStart, startPos = false, nil, nil

        miniSquare.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                dragStart = input.Position
                startPos  = miniSquare.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        -- Save mini position so restore places window nearby
                        Window._miniPos = Vector2.new(
                            miniSquare.Position.X.Offset,
                            miniSquare.Position.Y.Offset
                        )
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                miniSquare.Position = UDim2.fromOffset(
                    startPos.X.Offset + delta.X,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- ── Open animation ─────────────────────────────────────
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromOffset(winW * 0.92, winH * 0.92)
    root.Position = UDim2.fromOffset(startX + winW * 0.04, startY + winH * 0.04)
    task.wait(0.02)
    Util.TweenBounce(root, 0.32, {
        BackgroundTransparency = 0,
        Size     = UDim2.fromOffset(winW, winH),
        Position = UDim2.fromOffset(startX, startY),
    })

    -- ── Minimize / Restore ──────────────────────────────────
    local function minimize()
        if Window._minimized then return end
        Window._minimized = true
        -- Position mini square at window's top-left
        miniSquare.Position = UDim2.fromOffset(
            root.Position.X.Offset,
            root.Position.Y.Offset
        )
        -- Animate window out
        Util.Tween(root, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            Size     = UDim2.fromOffset(42, 42),
            Position = miniSquare.Position,
            BackgroundTransparency = 1,
        })
        task.delay(0.18, function()
            root.Visible = false
            miniSquare.Visible = true
            -- Pop in mini square
            miniSquare.Size = UDim2.fromOffset(28, 28)
            Util.TweenBounce(miniSquare, 0.22, {Size = UDim2.fromOffset(42, 42)})
        end)
    end

    local function restore()
        if not Window._minimized then return end
        Window._minimized = false
        -- Restore window position to mini square position
        root.Position = miniSquare.Position
        root.Size     = UDim2.fromOffset(42, 42)
        root.BackgroundTransparency = 1
        root.Visible  = true
        -- Animate mini square out
        Util.Tween(miniSquare, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            Size = UDim2.fromOffset(0, 0)
        })
        task.delay(0.12, function()
            miniSquare.Visible = false
            miniSquare.Size = UDim2.fromOffset(42, 42)
        end)
        -- Animate window in
        Util.TweenBounce(root, 0.3, {
            BackgroundTransparency = 0,
            Size     = UDim2.fromOffset(winW, winH),
            Position = UDim2.fromOffset(
                math.clamp(Window._miniPos.X, 0, vp.X - winW),
                math.clamp(Window._miniPos.Y, 0, vp.Y - winH)
            ),
        })
    end

    minimizeBtn.MouseButton1Click:Connect(minimize)
    miniSquare.MouseButton1Click:Connect(restore)
    closeBtn.MouseButton1Click:Connect(function()
        Window:Destroy()
    end)

    -- ── Tab Selector animation helper ──────────────────────
    local function moveIndicator(tabFrame)
        local targetY = tabFrame.AbsolutePosition.Y - sidebar.AbsolutePosition.Y - 12
        Util.Tween(tabIndicator, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            Position = UDim2.new(0, 0, 0, targetY + 8),
            Size     = UDim2.new(0, 3, 0, tabFrame.AbsoluteSize.Y - 16),
        })
    end

    -- ── Tab content transition ──────────────────────────────
    local function switchTab(newTab)
        if Window._activeTab == newTab then return end
        -- Hide current tab content
        if Window._activeTab then
            local old = Window._activeTab
            old._btn.BackgroundTransparency = 1
            old._btn.BackgroundColor3 = T:Get("TabBg")
            Util.Tween(old._content, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                Position = UDim2.fromOffset(12, 0),
                GroupTransparency = 1,
            })
            task.delay(0.13, function()
                if old._content then old._content.Visible = false end
            end)
        end
        Window._activeTab = newTab
        -- Show new tab content
        newTab._content.Visible = true
        newTab._content.GroupTransparency = 1
        newTab._content.Position = UDim2.fromOffset(18, 0)
        Util.Tween(newTab._content, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            Position = UDim2.fromOffset(0, 0),
            GroupTransparency = 0,
        })
        -- Highlight tab button
        Util.Tween(newTab._btn, 0.15, nil, nil, {
            BackgroundColor3     = T:Get("TabSelected"),
            BackgroundTransparency = 0,
        })
        -- Move indicator
        moveIndicator(newTab._btn)
    end

    -- ── CreateTab ──────────────────────────────────────────
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        assert(tabConfig.Name, "[Orbit] Tab requires Name")
        local tabT = ThemeManager
        Window._tabCount = Window._tabCount + 1
        local idx = Window._tabCount

        -- Tab button
        local tabBtn = Util.New("TextButton", {
            Name             = "Tab_" .. tabConfig.Name,
            Size             = UDim2.new(1, -2, 0, 34),
            BackgroundColor3 = tabT:Get("TabBg"),
            BackgroundTransparency = 1,
            AutoButtonColor  = false,
            Text             = "",
            Parent           = tabScroll,
            ZIndex           = 4,
        })
        Util.AddCorner(tabBtn, 7)
        tabT:Tag(tabBtn, {BackgroundColor3 = "TabBg"})

        -- Icon (if provided)
        local iconOffset = 8
        if tabConfig.Icon and tabConfig.Icon ~= "" then
            local ico = Util.New("ImageLabel", {
                Name             = "Icon",
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = UDim2.new(0, 8, 0.5, 0),
                Size             = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                Image            = tabConfig.Icon,
                ImageColor3      = tabT:Get("SubText"),
                Parent           = tabBtn,
                ZIndex           = 5,
            })
            tabT:Tag(ico, {ImageColor3 = "SubText"})
            iconOffset = 30
        end

        local tabLabel = Util.New("TextLabel", {
            Name             = "TabLabel",
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, iconOffset, 0.5, 0),
            Size             = UDim2.new(1, -iconOffset - 8, 0, 14),
            BackgroundTransparency = 1,
            Text             = tabConfig.Name,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 12,
            TextColor3       = tabT:Get("SubText"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = tabBtn,
            ZIndex           = 5,
        })
        tabT:Tag(tabLabel, {TextColor3 = "SubText"})

        -- Tab hover
        tabBtn.MouseEnter:Connect(function()
            if Window._activeTab and Window._activeTab._btn == tabBtn then return end
            Util.Tween(tabBtn, 0.12, nil, nil, {
                BackgroundColor3 = tabT:Get("TabHover"),
                BackgroundTransparency = 0,
            })
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._activeTab and Window._activeTab._btn == tabBtn then return end
            Util.Tween(tabBtn, 0.12, nil, nil, {BackgroundTransparency = 1})
        end)

        -- Tab content (CanvasGroup for fade animation)
        local content = Util.New("CanvasGroup", {
            Name             = "Content_" .. tabConfig.Name,
            Size             = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            GroupTransparency = 1,
            Visible          = false,
            Parent           = containerHolder,
            ZIndex           = 2,
        })

        -- Scrolling frame inside CanvasGroup
        local scroll = Util.New("ScrollingFrame", {
            Name             = "Scroll",
            Size             = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = tabT:Get("Accent"),
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent           = content,
        })
        Util.AddPadding(scroll, 10, 10, 12, 12)
        local scrollLayout = Util.AddListLayout(scroll, 6)

        scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 20)
        end)

        local Tab = {
            Type       = "Tab",
            Name       = tabConfig.Name,
            _btn       = tabBtn,
            _content   = content,
            _container = scroll,
            _index     = idx,
        }

        tabBtn.MouseButton1Click:Connect(function()
            switchTab(Tab)
            -- Update label color
            tabLabel.TextColor3 = tabT:Get("Text")
        end)

        -- Restore subtext on other tabs
        for _, t in ipairs(Window._tabs) do
            if t._btn and t._btn ~= tabBtn then
                local lbl = t._btn:FindFirstChild("TabLabel")
                if lbl then tabT:Tag(lbl, {TextColor3 = "SubText"}) end
            end
        end

        table.insert(Window._tabs, Tab)

        -- Select first tab automatically
        if #Window._tabs == 1 then
            task.defer(function() switchTab(Tab) end)
        end

        -- Mix in element methods
        for name, fn in pairs(ElementMethods) do
            Tab[name] = fn
        end

        return Tab
    end

    -- ── CreatePremiumTab ───────────────────────────────────
    function Window:CreatePremiumTab(tabConfig)
        tabConfig = tabConfig or {}
        assert(tabConfig.Name,       "[Orbit] PremiumTab requires Name")
        assert(tabConfig.GamepassId, "[Orbit] PremiumTab requires GamepassId")
        local tabT = ThemeManager

        Window._tabCount = Window._tabCount + 1
        local idx = Window._tabCount
        local unlocked = false

        -- Tab button (locked look)
        local tabBtn = Util.New("TextButton", {
            Name             = "PremiumTab_" .. tabConfig.Name,
            Size             = UDim2.new(1, -2, 0, 34),
            BackgroundColor3 = tabT:Get("TabBg"),
            BackgroundTransparency = 1,
            AutoButtonColor  = false,
            Text             = "",
            Parent           = tabScroll,
            ZIndex           = 4,
        })
        Util.AddCorner(tabBtn, 7)
        tabT:Tag(tabBtn, {BackgroundColor3 = "TabBg"})

        -- Lock icon
        local lockIcon = Util.New("ImageLabel", {
            Name             = "LockIcon",
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 8, 0.5, 0),
            Size             = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Image            = "rbxassetid://6031094678",
            ImageColor3      = tabT:Get("PremiumLock"),
            Parent           = tabBtn,
            ZIndex           = 5,
        })
        tabT:Tag(lockIcon, {ImageColor3 = "PremiumLock"})

        -- Premium badge (hidden until unlocked)
        local premBadge = Util.New("Frame", {
            Name             = "PremBadge",
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, -4, 0.5, 0),
            Size             = UDim2.fromOffset(28, 14),
            BackgroundColor3 = tabT:Get("PremiumGold"),
            Visible          = false,
            Parent           = tabBtn,
            ZIndex           = 6,
        })
        Util.AddCorner(premBadge, 4)
        local premBadgeText = Util.New("TextLabel", {
            Size             = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text             = "PRO",
            Font             = Enum.Font.GothamBold,
            TextSize         = 8,
            TextColor3       = Color3.fromRGB(30, 20, 10),
            Parent           = premBadge,
            ZIndex           = 7,
        })

        local tabLabel = Util.New("TextLabel", {
            Name             = "TabLabel",
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 28, 0.5, 0),
            Size             = UDim2.new(1, -64, 0, 14),
            BackgroundTransparency = 1,
            Text             = tabConfig.Name,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 12,
            TextColor3       = tabT:Get("PremiumLock"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            Parent           = tabBtn,
            ZIndex           = 5,
        })
        tabT:Tag(tabLabel, {TextColor3 = "PremiumLock"})

        -- Premium content frame
        local content = Util.New("CanvasGroup", {
            Name             = "PremContent_" .. tabConfig.Name,
            Size             = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            GroupTransparency = 1,
            Visible          = false,
            Parent           = containerHolder,
            ZIndex           = 2,
        })

        local scroll = Util.New("ScrollingFrame", {
            Size             = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = tabT:Get("PremiumGold"),
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent           = content,
        })
        Util.AddPadding(scroll, 10, 10, 12, 12)
        local scrollLayout = Util.AddListLayout(scroll, 6)
        scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 20)
        end)

        -- Locked overlay (shown when not premium)
        local lockedOverlay = Util.New("Frame", {
            Name             = "LockedOverlay",
            Size             = UDim2.fromScale(1, 1),
            BackgroundColor3 = T:Get("Surface"),
            BackgroundTransparency = 0.1,
            Visible          = true,
            ZIndex           = 10,
            Parent           = content,
        })
        Util.AddCorner(lockedOverlay, 10)

        local lockCenter = Util.New("Frame", {
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.fromScale(0.5, 0.45),
            Size             = UDim2.fromOffset(200, 100),
            BackgroundTransparency = 1,
            Parent           = lockedOverlay,
            ZIndex           = 11,
        })
        local bigLock = Util.New("ImageLabel", {
            AnchorPoint      = Vector2.new(0.5, 0),
            Position         = UDim2.fromScale(0.5, 0),
            Size             = UDim2.fromOffset(36, 36),
            BackgroundTransparency = 1,
            Image            = "rbxassetid://6031094678",
            ImageColor3      = tabT:Get("PremiumGold"),
            Parent           = lockCenter,
            ZIndex           = 11,
        })
        local lockMsg = Util.New("TextLabel", {
            AnchorPoint      = Vector2.new(0.5, 0),
            Position         = UDim2.new(0.5, 0, 0, 44),
            Size             = UDim2.fromOffset(200, 20),
            BackgroundTransparency = 1,
            Text             = "Premium Required",
            Font             = Enum.Font.GothamBold,
            TextSize         = 14,
            TextColor3       = tabT:Get("Text"),
            Parent           = lockCenter,
            ZIndex           = 11,
        })
        tabT:Tag(lockMsg, {TextColor3 = "Text"})

        local purchaseBtn = Util.New("TextButton", {
            AnchorPoint      = Vector2.new(0.5, 0),
            Position         = UDim2.new(0.5, 0, 0, 72),
            Size             = UDim2.fromOffset(140, 28),
            BackgroundColor3 = tabT:Get("PremiumGold"),
            AutoButtonColor  = false,
            Text             = "Get Premium",
            Font             = Enum.Font.GothamBold,
            TextSize         = 12,
            TextColor3       = Color3.fromRGB(30, 20, 10),
            Parent           = lockCenter,
            ZIndex           = 11,
        })
        Util.AddCorner(purchaseBtn, 6)

        purchaseBtn.MouseButton1Click:Connect(function()
            PremiumManager:PromptPurchase(LocalPlayer.UserId, tabConfig.GamepassId)
        end)

        local PremiumTab = {
            Type       = "PremiumTab",
            Name       = tabConfig.Name,
            _btn       = tabBtn,
            _content   = content,
            _container = scroll,
            _index     = idx,
            _unlocked  = false,
        }

        -- ── Run Gamepass Check ──────────────────────────────
        -- Note: this runs asynchronously. Tab will appear locked
        -- until the Roblox server responds.
        PremiumManager:Check(LocalPlayer.UserId, tabConfig.GamepassId, function(owned)
            if owned then
                unlocked = true
                PremiumTab._unlocked = true

                -- Visual: show as unlocked
                lockedOverlay.Visible = false
                premBadge.Visible     = true
                lockIcon.Visible      = false

                -- Use real icon if provided
                if tabConfig.Icon and tabConfig.Icon ~= "" then
                    local ico = Util.New("ImageLabel", {
                        Name             = "Icon",
                        AnchorPoint      = Vector2.new(0, 0.5),
                        Position         = UDim2.new(0, 8, 0.5, 0),
                        Size             = UDim2.fromOffset(16, 16),
                        BackgroundTransparency = 1,
                        Image            = tabConfig.Icon,
                        ImageColor3      = tabT:Get("PremiumGold"),
                        Parent           = tabBtn,
                        ZIndex           = 5,
                    })
                    tabT:Tag(ico, {ImageColor3 = "PremiumGold"})
                end

                tabLabel.TextColor3 = tabT:Get("PremiumGold")
                tabT:Tag(tabLabel, {TextColor3 = "PremiumGold"})

                NotificationSystem:Send({
                    Title   = "Premium Active",
                    Content = "Welcome to Premium! All features unlocked.",
                    Type    = "Success",
                    Duration = 4,
                })
            else
                -- Keep locked state, clicking shows notification
                NotificationSystem:Send({
                    Title   = "Premium Required",
                    Content = "Purchase the Gamepass to unlock this tab.",
                    Type    = "Warning",
                    Duration = 3,
                })
            end
        end)

        -- Tab click handler
        tabBtn.MouseButton1Click:Connect(function()
            if not PremiumTab._unlocked then
                -- Show locked overlay content briefly
                if Window._activeTab ~= PremiumTab then
                    -- Navigate to tab but show lock overlay
                    switchTab(PremiumTab)
                else
                    NotificationSystem:Send({
                        Title   = "You are not Premium.",
                        Content = "Purchase the Gamepass to unlock this content.",
                        Type    = "Warning",
                        Duration = 3,
                    })
                end
                return
            end
            switchTab(PremiumTab)
        end)

        tabBtn.MouseEnter:Connect(function()
            if Window._activeTab and Window._activeTab._btn == tabBtn then return end
            Util.Tween(tabBtn, 0.12, nil, nil, {
                BackgroundColor3 = tabT:Get("TabHover"),
                BackgroundTransparency = 0,
            })
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._activeTab and Window._activeTab._btn == tabBtn then return end
            Util.Tween(tabBtn, 0.12, nil, nil, {BackgroundTransparency = 1})
        end)

        table.insert(Window._tabs, PremiumTab)

        -- Mix in element methods (only accessible if unlocked)
        for name, fn in pairs(ElementMethods) do
            PremiumTab[name] = function(self, ...)
                if not PremiumTab._unlocked then
                    warn("[Orbit] Cannot add elements to locked Premium tab.")
                    return {}
                end
                return fn(self, ...)
            end
        end

        return PremiumTab
    end

    -- ── Notify shortcut ────────────────────────────────────
    function Window:Notify(config)
        NotificationSystem:Send(config)
    end

    -- ── Theme switching ────────────────────────────────────
    function Window:SetTheme(name)
        ThemeManager:SetTheme(name)
    end

    -- ── Minimize / Restore public API ─────────────────────
    function Window:Minimize()
        minimize()
    end

    function Window:Restore()
        restore()
    end

    -- ── Destroy ────────────────────────────────────────────
    function Window:Destroy()
        Util.Tween(root, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(winW * 0.9, winH * 0.9),
        })
        task.delay(0.22, function()
            gui:Destroy()
            -- Clean up theme registry entries for this window
            for k, _ in pairs(ThemeManager._registry) do
                if k and not k.Parent then
                    ThemeManager._registry[k] = nil
                end
            end
        end)
    end

    table.insert(Library._windows, Window)
    return Window
end

-- ── Notify at library level (before any window) ──────────────
function Library:Notify(config)
    NotificationSystem:Send(config)
end

-- ── GetFlag / SetFlag ─────────────────────────────────────────
function Library:GetFlag(key)
    return StateManager:Get(key)
end

function Library:SetFlag(key, value)
    StateManager:Set(key, value)
end

-- ── Config helpers ────────────────────────────────────────────
function Library:SaveConfig()
    ConfigManager:Save(StateManager.Flags)
end

function Library:LoadConfig()
    local data = ConfigManager:Load()
    for k, v in pairs(data) do
        StateManager:Set(k, v)
    end
    return data
end

function Library:ResetConfig()
    ConfigManager:Reset()
end

-- ── Expose sub-managers for advanced use ─────────────────────
Library.Theme    = ThemeManager
Library.State    = StateManager
Library.Premium  = PremiumManager

return Library

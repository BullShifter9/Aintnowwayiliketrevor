--[[
╔══════════════════════════════════════════════════════════════════╗
║                   ORBIT UI  v2.0  —  Amethyst                   ║
║     Single-File Premium Roblox Luau UI Library                   ║
║     Fluent-Inspired  |  Lucide Icons  |  Spring Animations        ║
╚══════════════════════════════════════════════════════════════════╝

    USAGE:
        local Orbit = loadstring(game:HttpGet("https://raw.githubusercontent.com/..."))()
        local Window = Orbit:CreateWindow({ Title = "My Hub", Theme = "Amethyst" })
        local Tab = Window:CreateTab({ Name = "Main", Icon = "home" })
        Tab:AddButton({ Title = "Click Me", Callback = function() end })

    ICONS:  Uses the full Lucide icon set (same as Fluent UI).
            Pass the icon name as a string: "home", "settings", "sword", etc.
            Or pass a direct asset id: "rbxassetid://12345"

    SECURITY (Premium / Gamepass):
        UserOwnsGamePassAsync fires a real HTTP request to Roblox servers.
        It CAN be bypassed client-side via memory editing or function hooking.
        This is purely a UI gating mechanism. Never rely on client-side checks
        for anything server-authoritative (economy, abilities, data).
--]]

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────────────────────────
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService        = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ─────────────────────────────────────────────────────────────────────────────
-- LUCIDE ICON PACK  (confirmed IDs from Fluent UI source)
-- Usage: Library:GetIcon("settings") or Library:GetIcon("lucide-settings")
-- ─────────────────────────────────────────────────────────────────────────────
local Icons = {
    -- Window controls (Fluent Assets.lua — confirmed)
    ["close"]                           = "rbxassetid://9886659671",
    ["minimize"]                        = "rbxassetid://9886659276",
    ["maximize"]                        = "rbxassetid://9886659406",
    ["restore"]                         = "rbxassetid://9886659001",
    -- Commonly used Lucide icons (all IDs directly from Fluent compiled source)
    ["lucide-accessibility"]            = "rbxassetid://10709751939",
    ["lucide-activity"]                 = "rbxassetid://10709752035",
    ["lucide-alert-circle"]             = "rbxassetid://10709752996",
    ["lucide-alert-triangle"]           = "rbxassetid://10709753149",
    ["lucide-anchor"]                   = "rbxassetid://10709761530",
    ["lucide-aperture"]                 = "rbxassetid://10709761813",
    ["lucide-archive"]                  = "rbxassetid://10709762233",
    ["lucide-arrow-down"]               = "rbxassetid://10709767827",
    ["lucide-arrow-left"]               = "rbxassetid://10709768114",
    ["lucide-arrow-right"]              = "rbxassetid://10709768347",
    ["lucide-arrow-up"]                 = "rbxassetid://10709768939",
    ["lucide-award"]                    = "rbxassetid://10709769406",
    ["lucide-axe"]                      = "rbxassetid://10709769508",
    ["lucide-bar-chart"]                = "rbxassetid://10709773755",
    ["lucide-battery"]                  = "rbxassetid://10709774640",
    ["lucide-bell"]                     = "rbxassetid://10709775704",
    ["lucide-bell-off"]                 = "rbxassetid://10709775320",
    ["lucide-bell-ring"]                = "rbxassetid://10709775560",
    ["lucide-bluetooth"]                = "rbxassetid://10709776655",
    ["lucide-bomb"]                     = "rbxassetid://10709781460",
    ["lucide-book"]                     = "rbxassetid://10709781824",
    ["lucide-book-open"]                = "rbxassetid://10709781717",
    ["lucide-bookmark"]                 = "rbxassetid://10709782154",
    ["lucide-bot"]                      = "rbxassetid://10709782230",
    ["lucide-box"]                      = "rbxassetid://10709782497",
    ["lucide-briefcase"]                = "rbxassetid://10709782662",
    ["lucide-brush"]                    = "rbxassetid://10709782758",
    ["lucide-bug"]                      = "rbxassetid://10709782845",
    ["lucide-building"]                 = "rbxassetid://10709783051",
    ["lucide-calculator"]               = "rbxassetid://10709783311",
    ["lucide-calendar"]                 = "rbxassetid://10709789505",
    ["lucide-camera"]                   = "rbxassetid://10709789686",
    ["lucide-check"]                    = "rbxassetid://10709790644",
    ["lucide-check-circle"]             = "rbxassetid://10709790387",
    ["lucide-chevron-down"]             = "rbxassetid://10709790948",
    ["lucide-chevron-left"]             = "rbxassetid://10709791281",
    ["lucide-chevron-right"]            = "rbxassetid://10709791437",
    ["lucide-chevron-up"]               = "rbxassetid://10709791523",
    ["lucide-circle"]                   = "rbxassetid://10709798174",
    ["lucide-clipboard"]                = "rbxassetid://10709799288",
    ["lucide-clock"]                    = "rbxassetid://10709805144",
    ["lucide-cloud"]                    = "rbxassetid://10709806740",
    ["lucide-code"]                     = "rbxassetid://10709810463",
    ["lucide-cog"]                      = "rbxassetid://10709810948",
    ["lucide-command"]                  = "rbxassetid://10709811365",
    ["lucide-compass"]                  = "rbxassetid://10709811445",
    ["lucide-copy"]                     = "rbxassetid://10709812159",
    ["lucide-cpu"]                      = "rbxassetid://10709813383",
    ["lucide-crosshair"]                = "rbxassetid://10709818534",
    ["lucide-crown"]                    = "rbxassetid://10709818626",
    ["lucide-database"]                 = "rbxassetid://10709818996",
    ["lucide-diamond"]                  = "rbxassetid://10709819149",
    ["lucide-dollar-sign"]              = "rbxassetid://10723343958",
    ["lucide-download"]                 = "rbxassetid://10723344270",
    ["lucide-edit"]                     = "rbxassetid://10734883598",
    ["lucide-edit-2"]                   = "rbxassetid://10723344885",
    ["lucide-eye"]                      = "rbxassetid://10723346959",
    ["lucide-eye-off"]                  = "rbxassetid://10723346871",
    ["lucide-feather"]                  = "rbxassetid://10723354671",
    ["lucide-file"]                     = "rbxassetid://10723374641",
    ["lucide-file-text"]                = "rbxassetid://10723367380",
    ["lucide-filter"]                   = "rbxassetid://10723375128",
    ["lucide-flag"]                     = "rbxassetid://10723375890",
    ["lucide-flame"]                    = "rbxassetid://10723376114",
    ["lucide-folder"]                   = "rbxassetid://10723387563",
    ["lucide-folder-open"]              = "rbxassetid://10723386277",
    ["lucide-gamepad"]                  = "rbxassetid://10723395457",
    ["lucide-gamepad-2"]                = "rbxassetid://10723395215",
    ["lucide-gauge"]                    = "rbxassetid://10723395708",
    ["lucide-gem"]                      = "rbxassetid://10723396000",
    ["lucide-ghost"]                    = "rbxassetid://10723396107",
    ["lucide-gift"]                     = "rbxassetid://10723396402",
    ["lucide-globe"]                    = "rbxassetid://10723404337",
    ["lucide-grid"]                     = "rbxassetid://10723404936",
    ["lucide-hammer"]                   = "rbxassetid://10723405360",
    ["lucide-hard-drive"]               = "rbxassetid://10723405749",
    ["lucide-hash"]                     = "rbxassetid://10723405975",
    ["lucide-headphones"]               = "rbxassetid://10723406165",
    ["lucide-heart"]                    = "rbxassetid://10723406885",
    ["lucide-help-circle"]              = "rbxassetid://10723406988",
    ["lucide-hexagon"]                  = "rbxassetid://10723407092",
    ["lucide-home"]                     = "rbxassetid://10723407389",
    ["lucide-image"]                    = "rbxassetid://10723415040",
    ["lucide-info"]                     = "rbxassetid://10723415903",
    ["lucide-key"]                      = "rbxassetid://10723416652",
    ["lucide-keyboard"]                 = "rbxassetid://10723416765",
    ["lucide-layers"]                   = "rbxassetid://10723424505",
    ["lucide-layout"]                   = "rbxassetid://10723425376",
    ["lucide-layout-dashboard"]         = "rbxassetid://10723424646",
    ["lucide-layout-grid"]              = "rbxassetid://10723424838",
    ["lucide-leaf"]                     = "rbxassetid://10723425539",
    ["lucide-lightbulb"]                = "rbxassetid://10723425852",
    ["lucide-link"]                     = "rbxassetid://10723426722",
    ["lucide-list"]                     = "rbxassetid://10723433811",
    ["lucide-lock"]                     = "rbxassetid://10723434711",
    ["lucide-log-in"]                   = "rbxassetid://10723434830",
    ["lucide-log-out"]                  = "rbxassetid://10723434906",
    ["lucide-mail"]                     = "rbxassetid://10734885430",
    ["lucide-map"]                      = "rbxassetid://10734886202",
    ["lucide-map-pin"]                  = "rbxassetid://10734886004",
    ["lucide-maximize"]                 = "rbxassetid://10734886735",
    ["lucide-medal"]                    = "rbxassetid://10734887072",
    ["lucide-menu"]                     = "rbxassetid://10734887784",
    ["lucide-message-circle"]           = "rbxassetid://10734888000",
    ["lucide-message-square"]           = "rbxassetid://10734888228",
    ["lucide-mic"]                      = "rbxassetid://10734888864",
    ["lucide-minus"]                    = "rbxassetid://10734896206",
    ["lucide-minus-circle"]             = "rbxassetid://10734895856",
    ["lucide-monitor"]                  = "rbxassetid://10734896881",
    ["lucide-moon"]                     = "rbxassetid://10734897102",
    ["lucide-more-horizontal"]          = "rbxassetid://10734897250",
    ["lucide-more-vertical"]            = "rbxassetid://10734897387",
    ["lucide-mouse"]                    = "rbxassetid://10734898592",
    ["lucide-move"]                     = "rbxassetid://10734900011",
    ["lucide-music"]                    = "rbxassetid://10734905958",
    ["lucide-navigation"]               = "rbxassetid://10734906744",
    ["lucide-network"]                  = "rbxassetid://10734906975",
    ["lucide-package"]                  = "rbxassetid://10734909540",
    ["lucide-palette"]                  = "rbxassetid://10734910430",
    ["lucide-pencil"]                   = "rbxassetid://10734919691",
    ["lucide-phone"]                    = "rbxassetid://10734921524",
    ["lucide-pie-chart"]                = "rbxassetid://10734921727",
    ["lucide-pin"]                      = "rbxassetid://10734922324",
    ["lucide-play"]                     = "rbxassetid://10734923549",
    ["lucide-play-circle"]              = "rbxassetid://10734923214",
    ["lucide-plus"]                     = "rbxassetid://10734924532",
    ["lucide-plus-circle"]              = "rbxassetid://10734923868",
    ["lucide-power"]                    = "rbxassetid://10734930466",
    ["lucide-puzzle"]                   = "rbxassetid://10734930886",
    ["lucide-refresh-ccw"]              = "rbxassetid://10734933056",
    ["lucide-refresh-cw"]               = "rbxassetid://10734933222",
    ["lucide-rocket"]                   = "rbxassetid://10734934585",
    ["lucide-rotate-ccw"]               = "rbxassetid://10734940376",
    ["lucide-rotate-cw"]                = "rbxassetid://10734940654",
    ["lucide-save"]                     = "rbxassetid://10734941499",
    ["lucide-search"]                   = "rbxassetid://10734943674",
    ["lucide-send"]                     = "rbxassetid://10734943902",
    ["lucide-server"]                   = "rbxassetid://10734949856",
    ["lucide-settings"]                 = "rbxassetid://10734950309",
    ["lucide-settings-2"]               = "rbxassetid://10734950020",
    ["lucide-share"]                    = "rbxassetid://10734950813",
    ["lucide-shield"]                   = "rbxassetid://10734951847",
    ["lucide-shield-check"]             = "rbxassetid://10734951367",
    ["lucide-shuffle"]                  = "rbxassetid://10734953451",
    ["lucide-sidebar"]                  = "rbxassetid://10734954301",
    ["lucide-signal"]                   = "rbxassetid://10734961133",
    ["lucide-skull"]                    = "rbxassetid://10734962068",
    ["lucide-sliders"]                  = "rbxassetid://10734963400",
    ["lucide-sliders-horizontal"]       = "rbxassetid://10734963191",
    ["lucide-smartphone"]               = "rbxassetid://10734963940",
    ["lucide-smile"]                    = "rbxassetid://10734964441",
    ["lucide-star"]                     = "rbxassetid://10734966248",
    ["lucide-star-off"]                 = "rbxassetid://10734966097",
    ["lucide-sun"]                      = "rbxassetid://10734974297",
    ["lucide-sword"]                    = "rbxassetid://10734975486",
    ["lucide-swords"]                   = "rbxassetid://10734975692",
    ["lucide-tag"]                      = "rbxassetid://10734976528",
    ["lucide-target"]                   = "rbxassetid://10734977012",
    ["lucide-terminal"]                 = "rbxassetid://10734982144",
    ["lucide-thumbs-up"]                = "rbxassetid://10734983629",
    ["lucide-timer"]                    = "rbxassetid://10734984606",
    ["lucide-toggle-left"]              = "rbxassetid://10734984834",
    ["lucide-toggle-right"]             = "rbxassetid://10734985040",
    ["lucide-trash"]                    = "rbxassetid://10747362393",
    ["lucide-trash-2"]                  = "rbxassetid://10747362241",
    ["lucide-trending-up"]              = "rbxassetid://10747363465",
    ["lucide-trending-down"]            = "rbxassetid://10747363205",
    ["lucide-trophy"]                   = "rbxassetid://10747363809",
    ["lucide-truck"]                    = "rbxassetid://10747364031",
    ["lucide-tv"]                       = "rbxassetid://10747364593",
    ["lucide-unlock"]                   = "rbxassetid://10747366027",
    ["lucide-upload"]                   = "rbxassetid://10747366434",
    ["lucide-user"]                     = "rbxassetid://10747373176",
    ["lucide-user-check"]               = "rbxassetid://10747371901",
    ["lucide-user-plus"]                = "rbxassetid://10747372702",
    ["lucide-users"]                    = "rbxassetid://10747373426",
    ["lucide-video"]                    = "rbxassetid://10747374938",
    ["lucide-volume"]                   = "rbxassetid://10747376008",
    ["lucide-volume-2"]                 = "rbxassetid://10747375679",
    ["lucide-wallet"]                   = "rbxassetid://10747376205",
    ["lucide-wand"]                     = "rbxassetid://10747376565",
    ["lucide-wand-2"]                   = "rbxassetid://10747376349",
    ["lucide-watch"]                    = "rbxassetid://10747376722",
    ["lucide-wifi"]                     = "rbxassetid://10747382504",
    ["lucide-wifi-off"]                 = "rbxassetid://10747382268",
    ["lucide-wind"]                     = "rbxassetid://10747382750",
    ["lucide-wrench"]                   = "rbxassetid://10747383470",
    ["lucide-x"]                        = "rbxassetid://10747384394",
    ["lucide-x-circle"]                 = "rbxassetid://10747383819",
    ["lucide-zoom-in"]                  = "rbxassetid://10747384552",
    ["lucide-zoom-out"]                 = "rbxassetid://10747384679",
}

-- Resolve icon name → rbxassetid string
local function GetIcon(name)
    if not name or name == "" then return nil end
    -- Direct asset URLs pass through unchanged
    if name:sub(1, 13) == "rbxassetid://" then return name end
    if name:sub(1, 7) == "http://" or name:sub(1, 8) == "https://" then return name end
    -- Try exact match first
    if Icons[name] then return Icons[name] end
    -- Try with lucide- prefix
    if Icons["lucide-" .. name] then return Icons["lucide-" .. name] end
    return nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- UTILITY
-- ─────────────────────────────────────────────────────────────────────────────
local Util = {}

function Util.Tween(obj, t, style, dir, props)
    local ti = TweenInfo.new(t,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, ti, props)
    tw:Play()
    return tw
end

-- "Spring" feel – Back easing overshoots slightly then settles
function Util.Spring(obj, t, props)
    return Util.Tween(obj, t, Enum.EasingStyle.Back, Enum.EasingDirection.Out, props)
end

function Util.New(cls, props, children)
    local obj = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then pcall(function() obj[k] = v end) end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

function Util.Corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

function Util.Stroke(parent, color, alpha, thick)
    local s = Instance.new("UIStroke")
    s.Color           = color or Color3.new(1, 1, 1)
    s.Transparency    = alpha or 0.8
    s.Thickness       = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = parent
    return s
end

function Util.Pad(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.Parent        = parent
    return p
end

function Util.List(parent, pad, dir, halign)
    local l = Instance.new("UIListLayout")
    l.Padding             = UDim.new(0, pad or 6)
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.FillDirection       = dir    or Enum.FillDirection.Vertical
    l.HorizontalAlignment = halign or Enum.HorizontalAlignment.Center
    l.Parent              = parent
    return l
end

function Util.Scale(parent)
    local s = Instance.new("UIScale")
    s.Scale  = 1
    s.Parent = parent
    return s
end

-- ─────────────────────────────────────────────────────────────────────────────
-- THEME MANAGER  –  Amethyst (exact Fluent values)
-- ─────────────────────────────────────────────────────────────────────────────
local ThemeManager = {}
ThemeManager._reg   = {}  -- { [instance] = { propertyName = "ColorKey", ... } }
ThemeManager._theme = "Amethyst"

ThemeManager.Themes = {
    Amethyst = {
        -- From Fluent's Amethyst.lua + AcrylicMain base
        Accent              = Color3.fromRGB(97,  62,  167),
        AccentLight         = Color3.fromRGB(128, 90,  210),
        AccentDim           = Color3.fromRGB(70,  44,  120),

        -- Window / surfaces  (AcrylicMain = RGB 20,20,20 base)
        Background          = Color3.fromRGB(20,  20,  20),
        Surface             = Color3.fromRGB(24,  18,  36),

        -- Sidebar  (slightly purple-tinted dark)
        TabBg               = Color3.fromRGB(21,  15,  32),
        TabSelected         = Color3.fromRGB(160, 140, 180),  -- Fluent Tab color
        TabHover            = Color3.fromRGB(160, 140, 180),

        -- Elements  (key: semi-transparent over dark background)
        Element             = Color3.fromRGB(140, 120, 160),  -- Fluent Element
        ElementBorder       = Color3.fromRGB(60,  50,  70),   -- Fluent ElementBorder
        ElementTransparency = 0.87,                           -- Fluent ElementTransparency
        HoverChange         = 0.04,                           -- Fluent HoverChange

        -- Borders
        Border              = Color3.fromRGB(95,  75,  110),  -- Fluent TitleBarLine used
        BorderDim           = Color3.fromRGB(60,  50,  70),

        -- Toggle
        ToggleSlider        = Color3.fromRGB(140, 120, 160),  -- Fluent ToggleSlider
        ToggleToggled       = Color3.fromRGB(0,   0,   0),    -- Fluent ToggleToggled (knob when on)

        -- Slider
        SliderRail          = Color3.fromRGB(140, 120, 160),  -- Fluent SliderRail

        -- Dropdown
        DropdownFrame       = Color3.fromRGB(170, 160, 200),  -- Fluent DropdownFrame
        DropdownHolder      = Color3.fromRGB(60,  45,  80),   -- Fluent DropdownHolder
        DropdownBorder      = Color3.fromRGB(50,  40,  65),   -- Fluent DropdownBorder
        DropdownOption      = Color3.fromRGB(140, 120, 160),  -- Fluent DropdownOption

        -- Keybind / Input
        Keybind             = Color3.fromRGB(140, 120, 160),  -- Fluent Keybind
        Input               = Color3.fromRGB(140, 120, 160),  -- Fluent Input
        InputFocused        = Color3.fromRGB(20,  10,  30),   -- Fluent InputFocused
        InputIndicator      = Color3.fromRGB(170, 150, 190),  -- Fluent InputIndicator

        -- Titlebar
        TitleBar            = Color3.fromRGB(21,  15,  32),
        TitleBarLine        = Color3.fromRGB(95,  75,  110),  -- Fluent TitleBarLine

        -- Text
        Text                = Color3.fromRGB(240, 240, 240),  -- Fluent Text
        SubText             = Color3.fromRGB(170, 170, 170),  -- Fluent SubText

        -- Notifications
        NotifBg             = Color3.fromRGB(24,  18,  40),
        NotifBorder         = Color3.fromRGB(95,  75,  110),

        -- Section
        SectionText         = Color3.fromRGB(130, 110, 160),

        -- Premium
        PremiumGold         = Color3.fromRGB(255, 195, 60),
        PremiumLock         = Color3.fromRGB(130, 110, 160),
    },
}

function ThemeManager:Tag(obj, props)
    self._reg[obj] = props
    self:_apply(obj, props)
end

function ThemeManager:_apply(obj, props)
    local t = self.Themes[self._theme]
    if not t then return end
    for prop, key in pairs(props) do
        local v = t[key]
        if v ~= nil then pcall(function() obj[prop] = v end) end
    end
end

function ThemeManager:Get(key)
    local t = self.Themes[self._theme]
    return (t and t[key]) or Color3.new(1, 1, 1)
end

function ThemeManager:GetF(key)
    local t = self.Themes[self._theme]
    return (t and t[key]) or 0
end

function ThemeManager:SetTheme(name)
    if not self.Themes[name] then return end
    self._theme = name
    for obj, props in pairs(self._reg) do
        if obj and obj.Parent then self:_apply(obj, props)
        else self._reg[obj] = nil end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- STATE MANAGER
-- ─────────────────────────────────────────────────────────────────────────────
local StateManager = {}
StateManager.Flags     = {}
StateManager._watchers = {}

function StateManager:Set(key, val)
    self.Flags[key] = val
    if self._watchers[key] then
        for _, cb in ipairs(self._watchers[key]) do pcall(cb, val) end
    end
end
function StateManager:Get(key) return self.Flags[key] end
function StateManager:Watch(key, cb)
    self._watchers[key] = self._watchers[key] or {}
    table.insert(self._watchers[key], cb)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMATION HELPERS
-- ─────────────────────────────────────────────────────────────────────────────
local Anim = {}

-- Spring motor simulation: smooth transparency change like Flipper.Spring
-- Returns a "motor" table with :Set(target) method
function Anim.TransparencyMotor(obj, prop, init)
    local motor = { _target = init, _current = init }
    pcall(function() obj[prop] = init end)
    function motor:Set(target)
        self._target = target
        Util.Tween(obj, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {[prop] = target})
    end
    function motor:SetInstant(target)
        self._target   = target
        self._current  = target
        pcall(function() obj[prop] = target end)
    end
    return motor
end

-- Fluent-exact element hover: transparency change via spring motor
function Anim.ElementHover(frame, isClickable)
    local T      = ThemeManager
    local base   = T:GetF("ElementTransparency")
    local delta  = T:GetF("HoverChange")
    local motor  = Anim.TransparencyMotor(frame, "BackgroundTransparency", base)

    frame.MouseEnter:Connect(function()
        motor:Set(base - delta)
    end)
    frame.MouseLeave:Connect(function()
        motor:Set(base)
    end)

    if isClickable then
        frame.MouseButton1Down:Connect(function()
            motor:Set(base + delta)
        end)
        frame.MouseButton1Up:Connect(function()
            motor:Set(base - delta)
        end)
    end

    return motor
end

-- UIScale-based press effect (adds tactile feel to buttons)
function Anim.ScalePress(frame)
    local sc = Util.Scale(frame)
    frame.MouseButton1Down:Connect(function()
        Util.Tween(sc, 0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Scale = 0.96})
    end)
    local function release()
        Util.Spring(sc, 0.22, {Scale = 1.0})
    end
    frame.MouseButton1Up:Connect(release)
    frame.MouseLeave:Connect(function()
        if sc.Scale < 1 then release() end
    end)
    return sc
end

-- Ripple click effect (circle expands from click point and fades)
function Anim.Ripple(frame, accentColor)
    frame.MouseButton1Click:Connect(function(x, y)
        -- Only run if frame hasn't been destroyed
        if not frame or not frame.Parent then return end
        local absPos  = frame.AbsolutePosition
        local absSize = frame.AbsoluteSize
        local relX = x - absPos.X
        local relY = y - absPos.Y
        -- Clamp within frame
        relX = math.clamp(relX, 0, absSize.X)
        relY = math.clamp(relY, 0, absSize.Y)

        local ripple = Util.New("Frame", {
            Name              = "Ripple",
            AnchorPoint       = Vector2.new(0.5, 0.5),
            Position          = UDim2.fromOffset(relX, relY),
            Size              = UDim2.fromOffset(0, 0),
            BackgroundColor3  = accentColor or ThemeManager:Get("Accent"),
            BackgroundTransparency = 0.7,
            BorderSizePixel   = 0,
            ZIndex            = frame.ZIndex + 1,
            Parent            = frame,
        })
        Util.Corner(ripple, 9999)

        local maxD = math.max(absSize.X, absSize.Y) * 2
        Util.Tween(ripple, 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            Size                   = UDim2.fromOffset(maxD, maxD),
            BackgroundTransparency = 1,
        })
        game:GetService("Debris"):AddItem(ripple, 0.5)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- PREMIUM MANAGER
-- ─────────────────────────────────────────────────────────────────────────────
local PremiumManager = {}
PremiumManager._cache = {}

function PremiumManager:Check(userId, gpId, cb)
    if self._cache[gpId] ~= nil then cb(self._cache[gpId]) ; return end
    task.spawn(function()
        local ok, owned = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(userId, gpId)
        end)
        local result = ok and owned or false
        self._cache[gpId] = result
        cb(result)
    end)
end

function PremiumManager:Prompt(gpId)
    pcall(function()
        MarketplaceService:PromptGamePassPurchase(LocalPlayer, gpId)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CONFIG MANAGER
-- ─────────────────────────────────────────────────────────────────────────────
local ConfigManager = {}
ConfigManager._file = "OrbitUI_Config.json"

function ConfigManager:Save(flags)
    -- NOTE: Premium state intentionally excluded — always re-validate on load
    local clean = {}
    for k, v in pairs(flags) do
        if k ~= "_premium" then clean[k] = v end
    end
    pcall(function() writefile(self._file, HttpService:JSONEncode(clean)) end)
end

function ConfigManager:Load()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(self._file))
    end)
    return (ok and data) or {}
end

function ConfigManager:Reset()
    pcall(function() writefile(self._file, "{}") end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATION SYSTEM  (Fluent-style slide-in from right)
-- ─────────────────────────────────────────────────────────────────────────────
local NotifSystem = {}
NotifSystem._holder = nil

function NotifSystem:Init(gui)
    -- Stack anchored at bottom-right, exactly like Fluent
    self._holder = Util.New("Frame", {
        Name              = "NotifHolder",
        Position          = UDim2.new(1, -30, 1, -30),
        Size              = UDim2.new(0, 310, 1, -30),
        AnchorPoint       = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        ZIndex            = 100,
        Parent            = gui,
    })
    local layout = Util.List(self._holder, 12)
    layout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
end

function NotifSystem:Send(cfg)
    cfg = cfg or {}
    local title    = cfg.Title    or "Notification"
    local content  = cfg.Content  or ""
    local sub      = cfg.SubContent or ""
    local duration = cfg.Duration or 4
    local T        = ThemeManager

    -- Type accent bar color
    local barClr = T:Get("Accent")
    if cfg.Type == "Success" then barClr = Color3.fromRGB(76,  190, 120)
    elseif cfg.Type == "Warning" then barClr = Color3.fromRGB(220, 160, 40)
    elseif cfg.Type == "Error"   then barClr = Color3.fromRGB(210, 65,  65)
    end

    -- Outer holder (auto-sizes to content, used for layout)
    local holder = Util.New("Frame", {
        Name              = "NHolder",
        Size              = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
        Parent            = self._holder,
        ZIndex            = 101,
        ClipsDescendants  = false,
    })

    -- Root frame (slides in from right, starts off-screen)
    local root = Util.New("Frame", {
        Name              = "NRoot",
        Size              = UDim2.fromScale(1, 1),
        Position          = UDim2.new(1, 60, 0, 0),  -- off-screen right
        BackgroundColor3  = T:Get("NotifBg"),
        BackgroundTransparency = 0,
        ZIndex            = 102,
        Parent            = holder,
    })
    Util.Corner(root, 6)
    Util.Stroke(root, T:Get("NotifBorder"), 0.5, 1)
    T:Tag(root, {BackgroundColor3 = "NotifBg"})

    -- Left accent bar (1px left border in accent color)
    local bar = Util.New("Frame", {
        Size             = UDim2.new(0, 3, 1, -12),
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = barClr,
        BorderSizePixel  = 0,
        ZIndex           = 103,
        Parent           = root,
    })
    Util.Corner(bar, 3)

    -- Title
    local titleLbl = Util.New("TextLabel", {
        Position         = UDim2.new(0, 14, 0, 14),
        Size             = UDim2.new(1, -40, 0, 13),
        BackgroundTransparency = 1,
        Text             = title,
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextColor3       = T:Get("Text"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        ZIndex           = 103,
        Parent           = root,
    })
    T:Tag(titleLbl, {TextColor3 = "Text"})

    -- Content
    local contentLbl = Util.New("TextLabel", {
        Position         = UDim2.new(0, 14, 0, 34),
        Size             = UDim2.new(1, -28, 0, 14),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text             = content,
        Font             = Enum.Font.Gotham,
        TextSize         = 13,
        TextColor3       = T:Get("SubText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        ZIndex           = 103,
        Parent           = root,
        Visible          = content ~= "",
    })
    T:Tag(contentLbl, {TextColor3 = "SubText"})

    -- SubContent
    if sub ~= "" then
        Util.New("TextLabel", {
            Position         = UDim2.new(0, 14, 0, 54),
            Size             = UDim2.new(1, -28, 0, 12),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text             = sub,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextColor3       = T:Get("SubText"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            ZIndex           = 103,
            Parent           = root,
        })
    end

    -- Close button (✕ top right)
    local closeBtn = Util.New("ImageButton", {
        Name              = "CloseBtn",
        AnchorPoint       = Vector2.new(1, 0),
        Position          = UDim2.new(1, -8, 0, 10),
        Size              = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Image             = Icons["close"] or "",
        ImageColor3       = T:Get("SubText"),
        ZIndex            = 104,
        Parent            = root,
    })
    T:Tag(closeBtn, {ImageColor3 = "SubText"})

    -- Progress bar
    local progBg = Util.New("Frame", {
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = T:Get("BorderDim"),
        BorderSizePixel  = 0,
        ZIndex           = 103,
        Parent           = root,
    })
    local progFill = Util.New("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = barClr,
        BorderSizePixel  = 0,
        ZIndex           = 104,
        Parent           = progBg,
    })

    -- Auto-size holder to match content
    task.defer(function()
        if root and root.Parent then
            holder.Size = UDim2.new(1, 0, 0, root.AbsoluteSize.Y)
        end
    end)

    -- Slide-in animation (spring from right, Fluent-style)
    Util.Spring(root, 0.35, {Position = UDim2.new(0, 0, 0, 0)})

    -- Progress drain
    Util.Tween(progFill, duration - 0.3, Enum.EasingStyle.Linear, nil,
        {Size = UDim2.new(0, 0, 1, 0)})

    local closed = false
    local function close()
        if closed then return end
        closed = true
        Util.Tween(root, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In,
            {Position = UDim2.new(1, 60, 0, 0)})
        task.delay(0.25, function()
            if holder and holder.Parent then holder:Destroy() end
        end)
    end

    closeBtn.MouseButton1Click:Connect(close)
    task.delay(duration, close)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ELEMENT FACTORY  (Fluent-exact semi-transparent style)
-- ─────────────────────────────────────────────────────────────────────────────
-- Fluent elements: BackgroundColor3 = Element (RGB 140,120,160),
--                  BackgroundTransparency = 0.87, UICorner = 4px, UIStroke (ElementBorder)
local function MakeElement(container, title, desc, isClickable)
    local T = ThemeManager
    local ET = T:GetF("ElementTransparency")

    local frame = Util.New("TextButton", {
        Name             = "Elem_" .. title,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundColor3 = T:Get("Element"),
        BackgroundTransparency = ET,
        AutoButtonColor  = false,
        Text             = "",
        Parent           = container,
        ClipsDescendants = true,
    })
    Util.Corner(frame, 4)  -- Fluent uses 4px radius on elements
    local stroke = Util.Stroke(frame, T:Get("ElementBorder"), 0.5, 1)
    T:Tag(frame,  {BackgroundColor3 = "Element"})
    T:Tag(stroke, {Color = "ElementBorder"})

    -- Label holder (mirrors Fluent's Component/Element.lua layout)
    local labelHolder = Util.New("Frame", {
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Position         = UDim2.fromOffset(10, 0),
        Size             = UDim2.new(1, -28, 0, 0),
        Parent           = frame,
    })
    Util.List(labelHolder, 0)
    Util.Pad(labelHolder, 13, 13, 0, 0)

    local titleLbl = Util.New("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text             = title,
        Font             = Enum.Font.GothamMedium,
        TextSize         = 13,
        TextColor3       = T:Get("Text"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = labelHolder,
    })
    T:Tag(titleLbl, {TextColor3 = "Text"})

    local descLbl
    if desc and desc ~= "" then
        descLbl = Util.New("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 12),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text             = desc,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextColor3       = T:Get("SubText"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            Parent           = labelHolder,
        })
        T:Tag(descLbl, {TextColor3 = "SubText"})
    end

    -- Spring motor hover effect (exactly matching Fluent)
    Anim.ElementHover(frame, isClickable)

    return frame, titleLbl, descLbl, labelHolder
end

-- ─────────────────────────────────────────────────────────────────────────────
-- COMPONENT METHODS  (mixed into Tab and Section objects)
-- ─────────────────────────────────────────────────────────────────────────────
local Components = {}

-- ── Button ────────────────────────────────────────────────────────────────────
function Components:AddButton(cfg)
    assert(cfg and cfg.Title, "[Orbit] Button.Title required")
    cfg.Callback = cfg.Callback or function() end
    local T = ThemeManager

    local frame, titleLbl, _, lh = MakeElement(self._container, cfg.Title, cfg.Description, true)

    -- Chevron-right icon on the far right (Fluent style)
    local arrowImg = GetIcon("chevron-right")
    local arrow = Util.New("ImageLabel", {
        Name             = "Arrow",
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -10, 0.5, 0),
        Size             = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Image            = arrowImg or "",
        ImageColor3      = T:Get("SubText"),
        Parent           = frame,
        ZIndex           = frame.ZIndex + 1,
    })
    T:Tag(arrow, {ImageColor3 = "SubText"})

    -- Scale press + ripple animations
    Anim.ScalePress(frame)
    Anim.Ripple(frame, T:Get("Accent"))

    -- Subtle arrow nudge on hover
    frame.MouseEnter:Connect(function()
        Util.Tween(arrow, 0.15, nil, nil, {ImageColor3 = T:Get("Accent")})
        Util.Tween(arrow, 0.18, Enum.EasingStyle.Back, nil, {Position = UDim2.new(1, -6, 0.5, 0)})
    end)
    frame.MouseLeave:Connect(function()
        Util.Tween(arrow, 0.15, nil, nil, {ImageColor3 = T:Get("SubText")})
        Util.Tween(arrow, 0.15, nil, nil, {Position = UDim2.new(1, -10, 0.5, 0)})
    end)

    frame.MouseButton1Click:Connect(function() pcall(cfg.Callback) end)

    local obj = {Type = "Button", _frame = frame}
    function obj:SetTitle(t)  titleLbl.Text = t end
    function obj:SetDesc(d)
        if _ then _.Text = d end
    end
    return obj
end

-- ── Toggle ────────────────────────────────────────────────────────────────────
-- Exact Fluent implementation: pill starts transparent (off), fills with Accent (on)
-- Circle knob uses rbxasset circle image, moves from x=2 to x=19
function Components:AddToggle(cfg)
    assert(cfg and cfg.Title, "[Orbit] Toggle.Title required")
    cfg.Callback = cfg.Callback or function() end
    local T = ThemeManager

    local frame, titleLbl = MakeElement(self._container, cfg.Title, cfg.Description, true)

    -- Circle knob (Fluent: http://www.roblox.com/asset/?id=12266946128)
    local knobImg = Util.New("ImageLabel", {
        Name             = "Knob",
        AnchorPoint      = Vector2.new(0, 0.5),
        Size             = UDim2.fromOffset(14, 14),
        Position         = UDim2.new(0, 2, 0.5, 0),
        Image            = "http://www.roblox.com/asset/?id=12266946128",
        ImageTransparency = 0.5,
        BackgroundTransparency = 1,
        ImageColor3      = T:Get("ToggleSlider"),
    })
    T:Tag(knobImg, {ImageColor3 = "ToggleSlider"})

    -- Pill border stroke (toggles between ToggleSlider and Accent color)
    local pillBorder = Util.New("UIStroke", {
        Transparency  = 0.5,
        Color         = T:Get("ToggleSlider"),
    })
    T:Tag(pillBorder, {Color = "ToggleSlider"})

    -- Pill frame (Fluent: 36×18, BackgroundTransparency starts at 1)
    local pill = Util.New("Frame", {
        Name             = "Pill",
        Size             = UDim2.fromOffset(36, 18),
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -10, 0.5, 0),
        BackgroundColor3 = T:Get("Accent"),
        BackgroundTransparency = 1,  -- transparent when off
        Parent           = frame,
        ZIndex           = frame.ZIndex + 1,
    }, {
        Util.New("UICorner", {CornerRadius = UDim.new(0, 9)}),
        pillBorder,
        knobImg,
    })
    T:Tag(pill, {BackgroundColor3 = "Accent"})

    local toggle = {
        Type     = "Toggle",
        Value    = cfg.Default or false,
        _frame   = frame,
        _cb      = cfg.Callback,
        _key     = cfg.Flag,
    }

    function toggle:SetValue(val)
        val = not not val
        self.Value = val

        -- Exactly matches Fluent toggle animation
        -- Border: uses Accent when on, ToggleSlider when off
        if val then
            pillBorder.Color = T:Get("Accent")
            T:Tag(pillBorder, {Color = "Accent"})
            knobImg.ImageColor3 = T:Get("ToggleToggled")
            T:Tag(knobImg, {ImageColor3 = "ToggleToggled"})
        else
            pillBorder.Color = T:Get("ToggleSlider")
            T:Tag(pillBorder, {Color = "ToggleSlider"})
            knobImg.ImageColor3 = T:Get("ToggleSlider")
            T:Tag(knobImg, {ImageColor3 = "ToggleSlider"})
        end

        -- Knob slides (Quint, 0.25s — exact Fluent)
        Util.Tween(knobImg, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Position = UDim2.new(0, val and 19 or 2, 0.5, 0)
        })
        -- Pill fills in (Quint, 0.25s — exact Fluent)
        Util.Tween(pill, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            BackgroundTransparency = val and 0 or 1
        })
        knobImg.ImageTransparency = val and 0 or 0.5

        if self._key then StateManager:Set(self._key, val) end
        pcall(self._cb, val)
    end

    function toggle:GetValue() return self.Value end
    function toggle:SetTitle(t) titleLbl.Text = t end

    -- Apply default state
    toggle:SetValue(toggle.Value)

    frame.MouseButton1Click:Connect(function()
        toggle:SetValue(not toggle.Value)
    end)

    return toggle
end

-- ── Slider ────────────────────────────────────────────────────────────────────
-- Matches Fluent exactly: value display left, rail right (max 150px wide)
-- Circle dot uses same asset as toggle knob
function Components:AddSlider(cfg)
    assert(cfg and cfg.Title, "[Orbit] Slider.Title required")
    assert(cfg.Default ~= nil and cfg.Min ~= nil and cfg.Max ~= nil and cfg.Rounding,
        "[Orbit] Slider requires Default, Min, Max, and Rounding")
    cfg.Callback = cfg.Callback or function() end
    local T = ThemeManager

    local frame, titleLbl = MakeElement(self._container, cfg.Title, cfg.Description, false)

    -- Slider dot (same circle asset as toggle)
    local dot = Util.New("ImageLabel", {
        Name             = "Dot",
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, -7, 0.5, 0),
        Size             = UDim2.fromOffset(14, 14),
        Image            = "http://www.roblox.com/asset/?id=12266946128",
        BackgroundTransparency = 1,
        ImageColor3      = T:Get("Accent"),
        ZIndex           = frame.ZIndex + 3,
    })
    T:Tag(dot, {ImageColor3 = "Accent"})

    -- Rail "ghost" frame (position offset so dot sits on it)
    local rail = Util.New("Frame", {
        Name             = "Rail",
        BackgroundTransparency = 1,
        Position         = UDim2.fromOffset(7, 0),
        Size             = UDim2.new(1, -14, 1, 0),
        ZIndex           = frame.ZIndex + 2,
    }, {dot})

    -- Value display text (left side of inner)
    local valLbl = Util.New("TextLabel", {
        Name             = "Val",
        Font             = Enum.Font.Gotham,
        Text             = tostring(cfg.Default),
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Size             = UDim2.new(0, 100, 0, 14),
        Position         = UDim2.new(0, -4, 0.5, 0),
        AnchorPoint      = Vector2.new(1, 0.5),
        ZIndex           = frame.ZIndex + 2,
        ImageColor3      = T:Get("SubText"),
    })
    T:Tag(valLbl, {TextColor3 = "SubText"})

    -- Fill bar
    local fill = Util.New("Frame", {
        Name             = "Fill",
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T:Get("Accent"),
        ZIndex           = frame.ZIndex + 2,
    }, {Util.New("UICorner", {CornerRadius = UDim.new(1, 0)})})
    T:Tag(fill, {BackgroundColor3 = "Accent"})

    -- Inner rail bar (Fluent: max width 150px, right-aligned inside element)
    local inner = Util.New("Frame", {
        Name             = "Inner",
        Size             = UDim2.new(1, 0, 0, 4),
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -10, 0.5, 0),
        BackgroundTransparency = 0.4,
        BackgroundColor3 = T:Get("SliderRail"),
        Parent           = frame,
        ZIndex           = frame.ZIndex + 1,
        ClipsDescendants = false,
    }, {
        Util.New("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Util.New("UISizeConstraint", {MaxSize = Vector2.new(150, math.huge)}),
        valLbl,
        fill,
        rail,
    })
    T:Tag(inner, {BackgroundColor3 = "SliderRail"})

    local slider = {
        Type     = "Slider",
        Value    = cfg.Default,
        Min      = cfg.Min,
        Max      = cfg.Max,
        Rounding = cfg.Rounding,
        _frame   = frame,
        _cb      = cfg.Callback,
        _key     = cfg.Flag,
        _dragging = false,
    }

    function slider:SetValue(val)
        val = math.clamp(val, self.Min, self.Max)
        val = math.floor(val / self.Rounding + 0.5) * self.Rounding
        self.Value  = val
        local pct   = (val - self.Min) / (self.Max - self.Min)
        dot.Position  = UDim2.new(pct, -7, 0.5, 0)
        fill.Size     = UDim2.fromScale(pct, 1)
        valLbl.Text   = tostring(val)
        if self._key then StateManager:Set(self._key, val) end
        pcall(self._cb, val)
    end
    function slider:GetValue() return self.Value end
    function slider:SetTitle(t) titleLbl.Text = t end

    local function onInput(input)
        local rel = input.Position.X - rail.AbsolutePosition.X
        local pct = math.clamp(rel / rail.AbsoluteSize.X, 0, 1)
        slider:SetValue(cfg.Min + pct * (cfg.Max - cfg.Min))
    end

    dot.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            slider._dragging = true
        end
    end)
    dot.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            slider._dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if slider._dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch) then
            onInput(inp)
        end
    end)

    slider:SetValue(cfg.Default)
    return slider
end

-- ── Dropdown ─────────────────────────────────────────────────────────────────
-- Fluent-exact: inner box right-aligned (160×30), holder drops below, ClipsDescendants
function Components:AddDropdown(cfg)
    assert(cfg and cfg.Title, "[Orbit] Dropdown.Title required")
    cfg.Options  = cfg.Options  or {}
    cfg.Default  = cfg.Default  or cfg.Options[1] or ""
    cfg.Callback = cfg.Callback or function() end
    local T = ThemeManager

    local frame, titleLbl = MakeElement(self._container, cfg.Title, cfg.Description, false)
    frame.ClipsDescendants = false  -- Allow dropdown to overflow

    -- Resize descLabel to leave room for dropdown (Fluent: "DescLabel.Size = UDim2.new(1,-170,0,14)")
    local descLbl = frame:FindFirstChild("Elem_" .. cfg.Title, true)
    -- (labelHolder already constrains via padding)

    -- Value display text
    local dispText = Util.New("TextLabel", {
        Font             = Enum.Font.Gotham,
        Text             = tostring(cfg.Default),
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        Size             = UDim2.new(1, -30, 0, 14),
        Position         = UDim2.new(0, 8, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        ZIndex           = frame.ZIndex + 2,
    })
    T:Tag(dispText, {TextColor3 = "Text"})

    -- Chevron-down icon
    local chevron = Util.New("ImageLabel", {
        Name             = "Chev",
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -8, 0.5, 0),
        Size             = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Image            = Icons["lucide-chevron-down"] or "",
        ImageColor3      = T:Get("SubText"),
        ZIndex           = frame.ZIndex + 2,
    })
    T:Tag(chevron, {ImageColor3 = "SubText"})

    -- Inner button  (Fluent: 160×30, right side)
    local innerBtn = Util.New("TextButton", {
        Size             = UDim2.fromOffset(160, 30),
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -10, 0.5, 0),
        BackgroundColor3 = T:Get("DropdownFrame"),
        BackgroundTransparency = 0.9,
        AutoButtonColor  = false,
        Text             = "",
        Parent           = frame,
        ZIndex           = frame.ZIndex + 1,
    }, {
        Util.New("UICorner", {CornerRadius = UDim.new(0, 5)}),
        Util.New("UIStroke", {
            Transparency  = 0.5,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color         = T:Get("DropdownBorder"),
        }),
        dispText,
        chevron,
    })
    T:Tag(innerBtn, {BackgroundColor3 = "DropdownFrame"})

    -- Options holder  (Fluent: DropdownHolder color, drops below)
    local optHolder = Util.New("Frame", {
        Name             = "DropList",
        Position         = UDim2.new(0, 0, 1, 4),
        Size             = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = T:Get("DropdownHolder"),
        ClipsDescendants = true,
        Visible          = false,
        ZIndex           = 30,
        Parent           = frame,
    })
    Util.Corner(optHolder, 5)
    Util.Stroke(optHolder, T:Get("DropdownBorder"), 0.5, 1)
    T:Tag(optHolder, {BackgroundColor3 = "DropdownHolder"})

    local optScroll = Util.New("ScrollingFrame", {
        Size             = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T:Get("Accent"),
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        Parent           = optHolder,
    })
    local optLayout = Util.List(optScroll, 2)
    Util.Pad(optScroll, 4, 4, 4, 4)

    local drop = {
        Type     = "Dropdown",
        Value    = cfg.Default,
        Options  = cfg.Options,
        _frame   = frame,
        _cb      = cfg.Callback,
        _key     = cfg.Flag,
        _open    = false,
    }

    local ITEM_H = 28

    local function rebuildList()
        for _, c in ipairs(optScroll:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        for _, opt in ipairs(drop.Options) do
            local isSelected = (opt == drop.Value)
            local item = Util.New("TextButton", {
                Size             = UDim2.new(1, -8, 0, ITEM_H),
                BackgroundColor3 = isSelected and T:Get("Accent") or T:Get("DropdownOption"),
                BackgroundTransparency = isSelected and 0.85 or 0.92,
                AutoButtonColor  = false,
                Text             = opt,
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextColor3       = isSelected and T:Get("Accent") or T:Get("Text"),
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 31,
                Parent           = optScroll,
            })
            Util.Corner(item, 4)
            Util.Pad(item, 0, 0, 8, 0)
            if isSelected then T:Tag(item, {TextColor3 = "Accent"})
            else T:Tag(item, {TextColor3 = "Text"}) end

            item.MouseEnter:Connect(function()
                if opt ~= drop.Value then
                    Util.Tween(item, 0.1, nil, nil, {BackgroundTransparency = 0.80})
                end
            end)
            item.MouseLeave:Connect(function()
                if opt ~= drop.Value then
                    Util.Tween(item, 0.12, nil, nil, {BackgroundTransparency = 0.92})
                end
            end)

            item.MouseButton1Click:Connect(function()
                drop.Value = opt
                dispText.Text = opt
                if drop._key then StateManager:Set(drop._key, opt) end
                pcall(drop._cb, opt)
                drop:Close()
                rebuildList()
            end)
        end

        local contentH = #drop.Options * (ITEM_H + 2) + 8
        optScroll.CanvasSize = UDim2.new(0, 0, 0, contentH)
        return math.min(contentH, 160)
    end

    function drop:Open()
        self._open = true
        optHolder.Visible = true
        local h = rebuildList()
        Util.Tween(optHolder, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out,
            {Size = UDim2.new(1, 0, 0, h)})
        Util.Tween(chevron, 0.15, nil, nil, {Rotation = 180})
    end

    function drop:Close()
        self._open = false
        Util.Tween(optHolder, 0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.In,
            {Size = UDim2.new(1, 0, 0, 0)})
        Util.Tween(chevron, 0.15, nil, nil, {Rotation = 0})
        task.delay(0.15, function()
            if not self._open and optHolder and optHolder.Parent then
                optHolder.Visible = false
            end
        end)
    end

    function drop:SetValue(v)
        self.Value  = v
        dispText.Text = v
        if self._key then StateManager:Set(self._key, v) end
        if self._open then rebuildList() end
    end
    function drop:SetOptions(opts) self.Options = opts ; if self._open then rebuildList() end end
    function drop:GetValue() return self.Value end
    function drop:SetTitle(t) titleLbl.Text = t end

    innerBtn.MouseButton1Click:Connect(function()
        if drop._open then drop:Close() else drop:Open() end
    end)

    if drop._key then StateManager:Set(drop._key, drop.Value) end
    rebuildList()
    return drop
end

-- ── Paragraph ─────────────────────────────────────────────────────────────────
function Components:AddParagraph(cfg)
    cfg = cfg or {}
    local T = ThemeManager
    local ET = T:GetF("ElementTransparency")

    local frame = Util.New("Frame", {
        Name             = "Para",
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundColor3 = T:Get("Element"),
        BackgroundTransparency = ET,
        Parent           = self._container,
    })
    Util.Corner(frame, 4)
    local stroke = Util.Stroke(frame, T:Get("ElementBorder"), 0.5, 1)
    T:Tag(frame,  {BackgroundColor3 = "Element"})
    T:Tag(stroke, {Color = "ElementBorder"})
    Util.Pad(frame, 13, 13, 10, 10)

    local layout = Util.List(frame, 4)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    if cfg.Title and cfg.Title ~= "" then
        local t = Util.New("TextLabel", {
            Size             = UDim2.new(1, 0, 0, 14),
            AutomaticSize    = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text             = cfg.Title,
            Font             = Enum.Font.GothamMedium,
            TextSize         = 13,
            TextColor3       = T:Get("Text"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            Parent           = frame,
        })
        T:Tag(t, {TextColor3 = "Text"})
    end

    local content = Util.New("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 14),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text             = cfg.Content or "",
        Font             = Enum.Font.Gotham,
        TextSize         = 13,
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

-- ── Label ─────────────────────────────────────────────────────────────────────
function Components:AddLabel(cfg)
    cfg = cfg or {}
    local T = ThemeManager
    local lbl = Util.New("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text             = cfg.Text or "",
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextColor3       = T:Get("SubText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        RichText         = true,
        Parent           = self._container,
    })
    Util.Pad(lbl, 0, 0, 10, 0)
    T:Tag(lbl, {TextColor3 = "SubText"})

    local obj = {Type = "Label", _frame = lbl}
    function obj:SetText(t) lbl.Text = t end
    return obj
end

-- ── Section ───────────────────────────────────────────────────────────────────
function Components:AddSection(cfg)
    cfg = cfg or {}
    local T = ThemeManager

    local section = Util.New("Frame", {
        Name             = "Section",
        Size             = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent           = self._container,
    })

    -- Bold section text left-aligned
    local lbl = Util.New("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 14),
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 0, 0.45, 0),
        BackgroundTransparency = 1,
        Text             = (cfg.Title or ""):upper(),
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        TextColor3       = T:Get("SectionText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        Parent           = section,
    })
    T:Tag(lbl, {TextColor3 = "SectionText"})

    -- Horizontal separator line below text
    local line = Util.New("Frame", {
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T:Get("ElementBorder"),
        BackgroundTransparency = 0.5,
        BorderSizePixel  = 0,
        Parent           = section,
    })
    T:Tag(line, {BackgroundColor3 = "ElementBorder"})

    return {Type = "Section", _frame = section}
end

-- ── Keybind ───────────────────────────────────────────────────────────────────
function Components:AddKeybind(cfg)
    assert(cfg and cfg.Title, "[Orbit] Keybind.Title required")
    cfg.Default  = cfg.Default  or Enum.KeyCode.Unknown
    cfg.Callback = cfg.Callback or function() end
    local T = ThemeManager

    local frame, titleLbl = MakeElement(self._container, cfg.Title, cfg.Description, true)

    -- Key display button  (Fluent: Keybind color, auto-width)
    local dispBtn = Util.New("TextButton", {
        Name             = "KeyDisp",
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -10, 0.5, 0),
        Size             = UDim2.fromOffset(0, 28),
        AutomaticSize    = Enum.AutomaticSize.X,
        BackgroundColor3 = T:Get("Keybind"),
        BackgroundTransparency = 0.9,
        AutoButtonColor  = false,
        Text             = cfg.Default.Name,
        Font             = Enum.Font.GothamSemibold,
        TextSize         = 12,
        TextColor3       = T:Get("SubText"),
        Parent           = frame,
        ZIndex           = frame.ZIndex + 1,
    })
    Util.Corner(dispBtn, 4)
    Util.Stroke(dispBtn, T:Get("ElementBorder"), 0.5, 1)
    Util.Pad(dispBtn, 0, 0, 8, 8)
    T:Tag(dispBtn, {BackgroundColor3 = "Keybind", TextColor3 = "SubText"})

    local kb = {
        Type     = "Keybind",
        Value    = cfg.Default,
        _picking = false,
        _cb      = cfg.Callback,
        _key     = cfg.Flag,
    }

    if kb._key then StateManager:Set(kb._key, kb.Value) end

    dispBtn.MouseButton1Click:Connect(function()
        if kb._picking then return end
        kb._picking    = true
        dispBtn.Text   = "..."
        dispBtn.TextColor3 = T:Get("Accent")
    end)

    UserInputService.InputBegan:Connect(function(inp, gpe)
        if kb._picking then
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                kb._picking = false
                kb.Value    = inp.KeyCode
                dispBtn.Text = inp.KeyCode.Name
                dispBtn.TextColor3 = T:Get("SubText")
                if kb._key then StateManager:Set(kb._key, inp.KeyCode) end
                pcall(kb._cb, inp.KeyCode)
            end
        elseif not gpe and inp.KeyCode == kb.Value then
            pcall(kb._cb, kb.Value)
        end
    end)

    function kb:SetValue(kc)
        self.Value  = kc
        dispBtn.Text = kc.Name
    end
    function kb:GetValue() return self.Value end
    function kb:SetTitle(t) titleLbl.Text = t end
    return kb
end

-- ── Input ─────────────────────────────────────────────────────────────────────
-- Fluent style: inline text box right side (160×30)
function Components:AddInput(cfg)
    assert(cfg and cfg.Title, "[Orbit] Input.Title required")
    cfg.Callback    = cfg.Callback    or function() end
    cfg.Placeholder = cfg.Placeholder or ""
    local T = ThemeManager

    local frame, titleLbl = MakeElement(self._container, cfg.Title, cfg.Description, false)

    -- Textbox container  (Fluent: same style as dropdown inner)
    local boxFrame = Util.New("Frame", {
        Name             = "InputFrame",
        Size             = UDim2.fromOffset(160, 30),
        AnchorPoint      = Vector2.new(1, 0.5),
        Position         = UDim2.new(1, -10, 0.5, 0),
        BackgroundColor3 = T:Get("Input"),
        BackgroundTransparency = 0.9,
        Parent           = frame,
        ZIndex           = frame.ZIndex + 1,
    })
    Util.Corner(boxFrame, 4)
    local boxStroke = Util.Stroke(boxFrame, T:Get("ElementBorder"), 0.5, 1)
    T:Tag(boxFrame, {BackgroundColor3 = "Input"})

    -- Bottom line indicator (Fluent: InputIndicator)
    local indicator = Util.New("Frame", {
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(0, 0, 0, 1.5),  -- starts at 0 width, expands on focus
        BackgroundColor3 = T:Get("Accent"),
        BorderSizePixel  = 0,
        ZIndex           = frame.ZIndex + 2,
        Parent           = boxFrame,
    })
    T:Tag(indicator, {BackgroundColor3 = "Accent"})

    local box = Util.New("TextBox", {
        Name             = "Box",
        Size             = UDim2.new(1, -12, 1, 0),
        Position         = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text             = cfg.Default or "",
        PlaceholderText  = cfg.Placeholder,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextColor3       = T:Get("Text"),
        PlaceholderColor3 = T:Get("SubText"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex           = frame.ZIndex + 2,
        Parent           = boxFrame,
    })
    T:Tag(box, {TextColor3 = "Text", PlaceholderColor3 = "SubText"})

    -- Focus animations (indicator expands, background shifts)
    box.Focused:Connect(function()
        Util.Tween(boxFrame, 0.15, nil, nil, {BackgroundTransparency = 0.75})
        Util.Tween(boxStroke, 0.15, nil, nil, {Color = T:Get("Accent"), Transparency = 0.3})
        Util.Tween(indicator, 0.2, Enum.EasingStyle.Quart, nil,
            {Size = UDim2.new(1, 0, 0, 1.5)})
    end)
    box.FocusLost:Connect(function(enter)
        Util.Tween(boxFrame, 0.15, nil, nil, {BackgroundTransparency = 0.9})
        Util.Tween(boxStroke, 0.15, nil, nil, {Color = T:Get("ElementBorder"), Transparency = 0.5})
        Util.Tween(indicator, 0.15, nil, nil, {Size = UDim2.new(0, 0, 0, 1.5)})
        if enter then pcall(cfg.Callback, box.Text) end
    end)

    local inp = {Type = "Input", _frame = frame, _box = box}
    function inp:GetValue() return box.Text end
    function inp:SetValue(v) box.Text = v end
    function inp:SetTitle(t) titleLbl.Text = t end
    return inp
end

-- ─────────────────────────────────────────────────────────────────────────────
-- MAIN LIBRARY
-- ─────────────────────────────────────────────────────────────────────────────
local Library = {}
Library.Flags   = StateManager.Flags
Library.Version = "2.0.0"
Library.Theme   = ThemeManager
Library.State   = StateManager
Library.Premium = PremiumManager

-- ── ScreenGui helper ─────────────────────────────────────────────────────────
local function makeGui(title)
    local gui
    pcall(function()
        if type(gethui) == "function" then
            gui = Util.New("ScreenGui", {
                Name = title, ResetOnSpawn = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                Parent = gethui(),
            })
        end
    end)
    if not gui then
        pcall(function()
            gui = Util.New("ScreenGui", {
                Name = title, ResetOnSpawn = false,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                Parent = game:GetService("CoreGui"),
            })
        end)
    end
    if not gui then
        gui = Util.New("ScreenGui", {
            Name = title, ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = LocalPlayer:WaitForChild("PlayerGui"),
        })
    end
    return gui
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CreateWindow
-- ─────────────────────────────────────────────────────────────────────────────
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    assert(cfg.Title, "[Orbit] Window.Title required")
    cfg.Theme    = cfg.Theme    or "Amethyst"
    cfg.Size     = cfg.Size     or Vector2.new(580, 460)  -- Fluent default
    cfg.TabWidth = cfg.TabWidth or 160                    -- Fluent default

    ThemeManager:SetTheme(cfg.Theme)
    local T   = ThemeManager
    local W   = cfg.Size.X
    local H   = cfg.Size.Y
    local TW  = cfg.TabWidth
    local vp  = Camera.ViewportSize
    local spX = cfg.Position and cfg.Position.X or (vp.X / 2 - W / 2)
    local spY = cfg.Position and cfg.Position.Y or (vp.Y / 2 - H / 2)

    local gui = makeGui("OrbitUI_" .. cfg.Title)
    NotifSystem:Init(gui)

    -- ── Root (AcrylicMain = RGB 20,20,20) ───────────────────────────────────
    local root = Util.New("Frame", {
        Name             = "OrbitWindow",
        Size             = UDim2.fromOffset(W, H),
        Position         = UDim2.fromOffset(spX, spY),
        BackgroundColor3 = T:Get("Background"),
        BorderSizePixel  = 0,
        Parent           = gui,
    })
    Util.Corner(root, 8)

    -- Window border (Fluent: AcrylicBorder = RGB 110,90,130)
    Util.Stroke(root, Color3.fromRGB(110, 90, 130), 0.6, 1)
    T:Tag(root, {BackgroundColor3 = "Background"})

    -- Amethyst gradient overlay on entire window  (AcrylicGradient)
    local winGrad = Util.New("UIGradient", {
        Color    = ColorSequence.new(
            Color3.fromRGB(85, 57, 139),  -- Fluent AcrylicGradient top
            Color3.fromRGB(40, 25, 65)    -- Fluent AcrylicGradient bottom
        ),
        Rotation  = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.88),  -- ~12% visible at top
            NumberSequenceKeypoint.new(1, 0.92),  -- ~8% visible at bottom
        }),
        Parent   = root,
    })

    -- Drop shadow
    Util.New("ImageLabel", {
        Name             = "Shadow",
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.5, 8),
        Size             = UDim2.new(1, 40, 1, 40),
        BackgroundTransparency = 1,
        Image            = "rbxassetid://6015897843",
        ImageColor3      = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType        = Enum.ScaleType.Slice,
        SliceCenter      = Rect.new(49, 49, 450, 450),
        ZIndex           = -1,
        Parent           = root,
    })

    -- ── TitleBar (42px, Fluent exact height) ─────────────────────────────────
    local titleBar = Util.New("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent           = root,
        ZIndex           = 3,
    })

    -- Title row: icon + title + subtitle inline (Fluent layout)
    local titleRow = Util.New("Frame", {
        Size             = UDim2.new(1, -(34*3)-16, 1, 0),
        Position         = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        ZIndex           = 4,
        Parent           = titleBar,
    })
    local rowLayout = Util.List(titleRow, 5, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left)
    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local titleLbl = Util.New("TextLabel", {
        Size             = UDim2.fromScale(0, 1),
        AutomaticSize    = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text             = cfg.Title,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextColor3       = T:Get("Text"),
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 4,
        Parent           = titleRow,
    })
    T:Tag(titleLbl, {TextColor3 = "Text"})

    if cfg.SubTitle then
        local subLbl = Util.New("TextLabel", {
            Size             = UDim2.fromScale(0, 1),
            AutomaticSize    = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text             = cfg.SubTitle,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextTransparency = 0.4,
            TextColor3       = T:Get("Text"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 4,
            Parent           = titleRow,
        })
        T:Tag(subLbl, {TextColor3 = "Text"})
    end

    -- Titlebar bottom separator line  (Fluent: TitleBarLine)
    local titleLine = Util.New("Frame", {
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T:Get("TitleBarLine"),
        BackgroundTransparency = 0.5,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = titleBar,
    })
    T:Tag(titleLine, {BackgroundColor3 = "TitleBarLine"})

    -- Window control buttons (Fluent BarButton style: 34×(H-8), UICorner 7)
    local function makeBarBtn(icon, offsetX, callback)
        local btn = Util.New("TextButton", {
            Size             = UDim2.new(0, 34, 1, -8),
            AnchorPoint      = Vector2.new(1, 0),
            Position         = UDim2.new(1, -offsetX, 0, 4),
            BackgroundTransparency = 1,
            BackgroundColor3 = T:Get("Text"),
            AutoButtonColor  = false,
            Text             = "",
            ZIndex           = 5,
            Parent           = titleBar,
        }, {
            Util.New("UICorner", {CornerRadius = UDim.new(0, 7)}),
            Util.New("ImageLabel", {
                Name             = "Icon",
                Image            = Icons[icon] or "",
                Size             = UDim2.fromOffset(16, 16),
                Position         = UDim2.fromScale(0.5, 0.5),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageColor3      = T:Get("Text"),
                ZIndex           = 6,
            }),
        })
        T:Tag(btn, {BackgroundColor3 = "Text"})
        T:Tag(btn:FindFirstChild("Icon"), {ImageColor3 = "Text"})

        -- Spring motor hover (Fluent: 0.94 on hover, 1 on leave, 0.96 on press)
        local motor = Anim.TransparencyMotor(btn, "BackgroundTransparency", 1)
        btn.MouseEnter:Connect(function()    motor:Set(0.94) end)
        btn.MouseLeave:Connect(function()    motor:Set(1) end)
        btn.MouseButton1Down:Connect(function() motor:Set(0.96) end)
        btn.MouseButton1Up:Connect(function()   motor:Set(0.94) end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local closeBtn    = makeBarBtn("close",    4,  function() end)  -- wired below
    local minimizeBtn = makeBarBtn("minimize", 40, function() end)  -- wired below

    -- ── Sidebar ───────────────────────────────────────────────────────────────
    local sidebar = Util.New("Frame", {
        Name             = "Sidebar",
        Position         = UDim2.new(0, 0, 0, 42),
        Size             = UDim2.new(0, TW, 1, -42),
        BackgroundColor3 = T:Get("TabBg"),
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = root,
    })
    -- Round bottom-left corner only (cover top-left)
    Util.Corner(sidebar, 8)
    Util.New("Frame", {
        Size             = UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = T:Get("TabBg"),
        BorderSizePixel  = 0,
        Parent           = sidebar,
    })
    T:Tag(sidebar, {BackgroundColor3 = "TabBg"})

    -- Sidebar subtle gradient overlay
    Util.New("UIGradient", {
        Color    = ColorSequence.new(
            Color3.fromRGB(85, 57, 139),
            Color3.fromRGB(40, 25, 65)
        ),
        Rotation  = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.88),
            NumberSequenceKeypoint.new(1, 0.94),
        }),
        Parent   = sidebar,
    })

    -- Right border of sidebar  (TitleBarLine color, like Fluent)
    Util.New("Frame", {
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = T:Get("TitleBarLine"),
        BackgroundTransparency = 0.5,
        BorderSizePixel  = 0,
        Parent           = sidebar,
    })

    -- Tab scroll frame (fills sidebar below a little top padding)
    local tabScroll = Util.New("ScrollingFrame", {
        Position         = UDim2.new(0, 0, 0, 8),
        Size             = UDim2.new(1, -1, 1, -8),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = T:Get("Accent"),
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex           = 3,
        Parent           = sidebar,
    })
    local tabLayout = Util.List(tabScroll, 4)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Util.Pad(tabScroll, 4, 4, 8, 8)

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabScroll.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
    end)

    -- Animated left selector bar (Fluent uses this exact element)
    local selector = Util.New("Frame", {
        Name             = "Selector",
        Size             = UDim2.fromOffset(4, 0),
        Position         = UDim2.fromOffset(0, 17),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = T:Get("Accent"),
        BorderSizePixel  = 0,
        ZIndex           = 4,
        Parent           = sidebar,
    })
    Util.Corner(selector, 2)
    T:Tag(selector, {BackgroundColor3 = "Accent"})

    -- Tab name display in content header (Fluent: TabDisplay, GothamSSm SemiBold size 28)
    local tabDisplay = Util.New("TextLabel", {
        Name             = "TabDisplay",
        RichText         = true,
        Text             = "",
        Font             = Enum.Font.GothamBold,
        TextSize         = 18,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextYAlignment   = Enum.TextYAlignment.Center,
        Size             = UDim2.new(1, -(TW + 26) - 16, 0, 28),
        Position         = UDim2.fromOffset(TW + 26, 52),
        BackgroundTransparency = 1,
        ZIndex           = 3,
        Parent           = root,
    })
    T:Tag(tabDisplay, {TextColor3 = "Text"})

    -- ── Content area ──────────────────────────────────────────────────────────
    local contentArea = Util.New("Frame", {
        Name             = "Content",
        Position         = UDim2.new(0, TW, 0, 42),
        Size             = UDim2.new(1, -TW, 1, -42),
        BackgroundColor3 = T:Get("Surface"),
        BorderSizePixel  = 0,
        ZIndex           = 1,
        ClipsDescendants = true,
        Parent           = root,
    })
    Util.Corner(contentArea, 8)
    Util.New("Frame", {
        Size             = UDim2.new(1, 0, 0, 8),
        BackgroundColor3 = T:Get("Surface"),
        BorderSizePixel  = 0,
        Parent           = contentArea,
    })
    Util.New("Frame", {
        Size             = UDim2.new(0, 8, 1, 0),
        BackgroundColor3 = T:Get("Surface"),
        BorderSizePixel  = 0,
        Parent           = contentArea,
    })
    T:Tag(contentArea, {BackgroundColor3 = "Surface"})

    -- Container holder (pages live here)
    local containerHolder = Util.New("Frame", {
        Size             = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex           = 2,
        Parent           = contentArea,
    })

    -- Canvas group for tab switch fade animation (Fluent: ContainerAnim)
    local containerAnim = Util.New("CanvasGroup", {
        Size             = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        GroupTransparency = 0,
        ZIndex           = 2,
        Parent           = containerHolder,
    })

    -- ── Mini Square (minimized state — VERY small, ~36×36) ──────────────────
    local miniSq = Util.New("TextButton", {
        Name             = "MiniSquare",
        Position         = UDim2.fromOffset(spX, spY),
        Size             = UDim2.fromOffset(36, 36),
        BackgroundColor3 = T:Get("Accent"),
        AutoButtonColor  = false,
        Text             = "",
        Visible          = false,
        ZIndex           = 50,
        Parent           = gui,
    })
    Util.Corner(miniSq, 9)
    Util.Stroke(miniSq, T:Get("AccentLight"), 0.3, 1)
    T:Tag(miniSq, {BackgroundColor3 = "Accent"})

    -- Orbit glyph inside mini square
    Util.New("ImageLabel", {
        AnchorPoint       = Vector2.new(0.5, 0.5),
        Position          = UDim2.fromScale(0.5, 0.5),
        Size              = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Image             = Icons["lucide-layout-dashboard"] or "",
        ImageColor3       = Color3.fromRGB(255, 255, 255),
        ZIndex            = 51,
        Parent            = miniSq,
    })

    -- Pulse glow on mini square while minimized
    task.spawn(function()
        while miniSq and miniSq.Parent do
            task.wait(0.05)
            if not miniSq.Visible then task.wait(0.3) ; continue end
            Util.Tween(miniSq, 0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                {BackgroundColor3 = T:Get("AccentLight")})
            task.wait(0.9)
            if miniSq.Visible then
                Util.Tween(miniSq, 0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                    {BackgroundColor3 = T:Get("Accent")})
                task.wait(0.9)
            end
        end
    end)

    -- ── Window Object ─────────────────────────────────────────────────────────
    local Window = {
        _gui       = gui,
        _root      = root,
        _tabs      = {},
        _tabCount  = 0,
        _active    = nil,
        _minimized = false,
        _miniPos   = Vector2.new(spX, spY),
    }

    -- ── Dragging (title bar) ──────────────────────────────────────────────────
    do
        local dragging, ds, startPos = false, nil, nil
        titleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true ; ds = inp.Position ; startPos = root.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if not dragging then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseMovement
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = inp.Position - ds
            root.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
        end)
    end

    -- ── Dragging (mini square) ────────────────────────────────────────────────
    do
        local dragging, ds, startPos = false, nil, nil
        miniSq.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true ; ds = inp.Position ; startPos = miniSq.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        Window._miniPos = Vector2.new(
                            miniSq.Position.X.Offset, miniSq.Position.Y.Offset)
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if not dragging then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseMovement
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = inp.Position - ds
            miniSq.Position = UDim2.fromOffset(
                startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
        end)
    end

    -- ── Minimize / Restore ────────────────────────────────────────────────────
    local function minimize()
        if Window._minimized then return end
        Window._minimized = true
        miniSq.Position = UDim2.fromOffset(root.Position.X.Offset, root.Position.Y.Offset)
        Util.Tween(root, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            Size = UDim2.fromOffset(36, 36),
            BackgroundTransparency = 1,
        })
        task.delay(0.16, function()
            root.Visible  = false
            miniSq.Visible = true
            miniSq.Size    = UDim2.fromOffset(24, 24)
            Util.Spring(miniSq, 0.25, {Size = UDim2.fromOffset(36, 36)})
        end)
    end

    local function restore()
        if not Window._minimized then return end
        Window._minimized = false
        root.Position = miniSq.Position
        root.Size     = UDim2.fromOffset(36, 36)
        root.BackgroundTransparency = 1
        root.Visible  = true
        Util.Tween(miniSq, 0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.In,
            {Size = UDim2.fromOffset(0, 0)})
        task.delay(0.1, function()
            miniSq.Visible = false
            miniSq.Size    = UDim2.fromOffset(36, 36)
        end)
        Util.Spring(root, 0.3, {
            BackgroundTransparency = 0,
            Size     = UDim2.fromOffset(W, H),
            Position = UDim2.fromOffset(
                math.clamp(Window._miniPos.X, 0, vp.X - W),
                math.clamp(Window._miniPos.Y, 0, vp.Y - H)),
        })
    end

    minimizeBtn.MouseButton1Click:Connect(minimize)
    miniSq.MouseButton1Click:Connect(restore)
    closeBtn.MouseButton1Click:Connect(function() Window:Destroy() end)

    -- ── Selector bar animation ────────────────────────────────────────────────
    -- Exactly Fluent: selector Y position animates, size stretches proportionally
    local lastSelectorY  = 17
    local lastSelectorT  = tick()

    local function moveSelector(tabFrame)
        local relY     = tabFrame.AbsolutePosition.Y - sidebar.AbsolutePosition.Y - 8
        local now      = tick()
        local dt       = now - lastSelectorT
        local stretch  = math.abs(relY - lastSelectorY) / math.max(dt * 60, 1)
        lastSelectorY  = relY
        lastSelectorT  = now

        -- Animate position
        Util.Tween(selector, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            Position = UDim2.fromOffset(0, relY + tabFrame.AbsoluteSize.Y * 0.1),
            Size     = UDim2.fromOffset(4, tabFrame.AbsoluteSize.Y * 0.8),
        })
    end

    -- ── Tab content switch animation (Fluent: ContainerAnim fade+slide) ───────
    local function switchTab(newTab)
        if Window._active == newTab then return end

        -- De-highlight previous
        if Window._active then
            local oldBtn = Window._active._btn
            Util.Tween(oldBtn, 0.15, nil, nil, {BackgroundTransparency = 1})
            local oldLbl = oldBtn:FindFirstChild("TabLabel")
            if oldLbl then T:Tag(oldLbl, {TextColor3 = "SubText"}) end
            -- Icon de-highlight
            local oldIco = oldBtn:FindFirstChild("TabIcon")
            if oldIco then T:Tag(oldIco, {ImageColor3 = "SubText"}) end
        end

        Window._active = newTab

        -- Fluent: fade old content out + slide, then show new
        task.spawn(function()
            containerAnim.GroupTransparency = 0
            -- Slide out
            Util.Tween(containerAnim, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                GroupTransparency = 1,
                Position = UDim2.fromOffset(6, 0),
            })
            task.wait(0.1)
            -- Switch visible tabs
            for _, tab in ipairs(Window._tabs) do
                if tab._scroll then tab._scroll.Visible = false end
            end
            if newTab._scroll then newTab._scroll.Visible = true end
            tabDisplay.Text = newTab.Name
            containerAnim.Position = UDim2.fromOffset(-6, 0)
            -- Slide in
            Util.Tween(containerAnim, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
                GroupTransparency = 0,
                Position = UDim2.fromOffset(0, 0),
            })
        end)

        -- Highlight new tab button
        Util.Tween(newTab._btn, 0.15, nil, nil, {BackgroundTransparency = 0.85})
        local lbl = newTab._btn:FindFirstChild("TabLabel")
        if lbl then
            Util.Tween(lbl, 0.12, nil, nil, {TextColor3 = T:Get("Text")})
        end
        local ico = newTab._btn:FindFirstChild("TabIcon")
        if ico then
            Util.Tween(ico, 0.12, nil, nil, {ImageColor3 = T:Get("Accent")})
        end

        moveSelector(newTab._btn)
    end

    -- ── Open animation (scale + fade with spring) ─────────────────────────────
    root.BackgroundTransparency = 1
    root.Size     = UDim2.fromOffset(W * 0.93, H * 0.93)
    root.Position = UDim2.fromOffset(spX + W * 0.035, spY + H * 0.035)
    task.defer(function()
        Util.Spring(root, 0.3, {
            BackgroundTransparency = 0,
            Size     = UDim2.fromOffset(W, H),
            Position = UDim2.fromOffset(spX, spY),
        })
    end)

    -- ── CreateTab ──────────────────────────────────────────────────────────────
    function Window:CreateTab(tabCfg)
        tabCfg = tabCfg or {}
        assert(tabCfg.Name, "[Orbit] Tab.Name required")
        Window._tabCount = Window._tabCount + 1

        local iconId = GetIcon(tabCfg.Icon)

        -- Tab button
        local tabBtn = Util.New("TextButton", {
            Name             = "TabBtn_" .. tabCfg.Name,
            Size             = UDim2.new(1, -2, 0, 34),
            BackgroundColor3 = T:Get("TabSelected"),
            BackgroundTransparency = 1,
            AutoButtonColor  = false,
            Text             = "",
            ZIndex           = 4,
            Parent           = tabScroll,
        })
        Util.Corner(tabBtn, 6)
        T:Tag(tabBtn, {BackgroundColor3 = "TabSelected"})

        -- Icon
        local iconOffsetX = 10
        if iconId then
            local ico = Util.New("ImageLabel", {
                Name             = "TabIcon",
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = UDim2.new(0, 8, 0.5, 0),
                Size             = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                Image            = iconId,
                ImageColor3      = T:Get("SubText"),
                ZIndex           = 5,
                Parent           = tabBtn,
            })
            T:Tag(ico, {ImageColor3 = "SubText"})
            iconOffsetX = 30
        end

        local tabLbl = Util.New("TextLabel", {
            Name             = "TabLabel",
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, iconOffsetX, 0.5, 0),
            Size             = UDim2.new(1, -(iconOffsetX + 8), 0, 14),
            BackgroundTransparency = 1,
            Text             = tabCfg.Name,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextColor3       = T:Get("SubText"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 5,
            Parent           = tabBtn,
        })
        T:Tag(tabLbl, {TextColor3 = "SubText"})

        -- Tab hover (spring motor, Fluent-exact)
        local tabMotor = Anim.TransparencyMotor(tabBtn, "BackgroundTransparency", 1)
        tabBtn.MouseEnter:Connect(function()
            if Window._active and Window._active._btn == tabBtn then return end
            tabMotor:Set(0.92)
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._active and Window._active._btn == tabBtn then return end
            tabMotor:Set(1)
        end)

        -- Content scroll frame
        local scroll = Util.New("ScrollingFrame", {
            Name             = "Scroll_" .. tabCfg.Name,
            Size             = UDim2.new(1, 0, 1, -54),
            Position         = UDim2.new(0, 0, 0, 54),
            BackgroundTransparency = 1,
            BottomImage      = "rbxassetid://6889812791",
            MidImage         = "rbxassetid://6889812721",
            TopImage         = "rbxassetid://6276641225",
            ScrollBarImageColor3 = T:Get("SubText"),
            ScrollBarImageTransparency = 0.95,
            ScrollBarThickness = 3,
            BorderSizePixel  = 0,
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible          = false,
            ZIndex           = 2,
            Parent           = containerAnim,
        })
        local scrollLayout = Util.List(scroll, 5)
        scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        Util.Pad(scroll, 1, 1, 1, 10)

        scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 2)
        end)

        local Tab = {
            Type       = "Tab",
            Name       = tabCfg.Name,
            _btn       = tabBtn,
            _scroll    = scroll,
            _container = scroll,
        }

        tabBtn.MouseButton1Click:Connect(function()
            switchTab(Tab)
        end)

        table.insert(Window._tabs, Tab)

        -- Auto-select first tab
        if #Window._tabs == 1 then
            task.defer(function() switchTab(Tab) end)
        end

        -- Mix in components
        for name, fn in pairs(Components) do
            Tab[name] = fn
        end

        return Tab
    end

    -- ── CreatePremiumTab ───────────────────────────────────────────────────────
    function Window:CreatePremiumTab(tabCfg)
        tabCfg = tabCfg or {}
        assert(tabCfg.Name,       "[Orbit] PremiumTab.Name required")
        assert(tabCfg.GamepassId, "[Orbit] PremiumTab.GamepassId required")

        Window._tabCount = Window._tabCount + 1
        local unlocked = false

        -- Tab button (locked look — golden lock tint)
        local tabBtn = Util.New("TextButton", {
            Name             = "PremBtn_" .. tabCfg.Name,
            Size             = UDim2.new(1, -2, 0, 34),
            BackgroundColor3 = T:Get("TabSelected"),
            BackgroundTransparency = 1,
            AutoButtonColor  = false,
            Text             = "",
            ZIndex           = 4,
            Parent           = tabScroll,
        })
        Util.Corner(tabBtn, 6)
        T:Tag(tabBtn, {BackgroundColor3 = "TabSelected"})

        -- Lock icon (gold tint when locked)
        local lockIco = Util.New("ImageLabel", {
            Name             = "TabIcon",
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 8, 0.5, 0),
            Size             = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Image            = Icons["lucide-lock"] or "",
            ImageColor3      = T:Get("PremiumLock"),
            ZIndex           = 5,
            Parent           = tabBtn,
        })

        -- PRO badge (hidden until unlocked)
        local badge = Util.New("Frame", {
            Name             = "Badge",
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, -4, 0.5, 0),
            Size             = UDim2.fromOffset(28, 14),
            BackgroundColor3 = T:Get("PremiumGold"),
            Visible          = false,
            ZIndex           = 6,
            Parent           = tabBtn,
        })
        Util.Corner(badge, 4)
        Util.New("TextLabel", {
            Size             = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text             = "PRO",
            Font             = Enum.Font.GothamBold,
            TextSize         = 8,
            TextColor3       = Color3.fromRGB(30, 20, 10),
            ZIndex           = 7,
            Parent           = badge,
        })

        local tabLbl = Util.New("TextLabel", {
            Name             = "TabLabel",
            AnchorPoint      = Vector2.new(0, 0.5),
            Position         = UDim2.new(0, 30, 0.5, 0),
            Size             = UDim2.new(1, -68, 0, 14),
            BackgroundTransparency = 1,
            Text             = tabCfg.Name,
            Font             = Enum.Font.Gotham,
            TextSize         = 12,
            TextColor3       = T:Get("PremiumLock"),
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 5,
            Parent           = tabBtn,
        })

        -- Content scroll (same as normal tab)
        local scroll = Util.New("ScrollingFrame", {
            Name             = "PremScroll_" .. tabCfg.Name,
            Size             = UDim2.new(1, 0, 1, -54),
            Position         = UDim2.new(0, 0, 0, 54),
            BackgroundTransparency = 1,
            ScrollBarImageColor3 = T:Get("PremiumGold"),
            ScrollBarImageTransparency = 0.8,
            ScrollBarThickness = 3,
            BorderSizePixel  = 0,
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible          = false,
            ZIndex           = 2,
            Parent           = containerAnim,
        })
        local scrollLayout = Util.List(scroll, 5)
        scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        Util.Pad(scroll, 1, 1, 1, 10)
        scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 2)
        end)

        -- Lock overlay frame (shown while not premium)
        local lockOverlay = Util.New("Frame", {
            Name             = "LockOverlay",
            Size             = UDim2.fromScale(1, 1),
            BackgroundColor3 = T:Get("Surface"),
            BackgroundTransparency = 0.05,
            ZIndex           = 15,
            Parent           = scroll,
        })
        Util.Corner(lockOverlay, 8)

        -- Lock center UI
        local lockCenter = Util.New("Frame", {
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.fromScale(0.5, 0.42),
            Size             = UDim2.fromOffset(220, 120),
            BackgroundTransparency = 1,
            ZIndex           = 16,
            Parent           = lockOverlay,
        })
        Util.New("ImageLabel", {
            AnchorPoint      = Vector2.new(0.5, 0),
            Position         = UDim2.fromScale(0.5, 0),
            Size             = UDim2.fromOffset(32, 32),
            BackgroundTransparency = 1,
            Image            = Icons["lucide-lock"] or "",
            ImageColor3      = T:Get("PremiumGold"),
            ZIndex           = 17,
            Parent           = lockCenter,
        })
        Util.New("TextLabel", {
            AnchorPoint      = Vector2.new(0.5, 0),
            Position         = UDim2.new(0.5, 0, 0, 40),
            Size             = UDim2.fromOffset(200, 18),
            BackgroundTransparency = 1,
            Text             = "Premium Required",
            Font             = Enum.Font.GothamBold,
            TextSize         = 14,
            TextColor3       = T:Get("Text"),
            ZIndex           = 17,
            Parent           = lockCenter,
        })
        local purchBtn = Util.New("TextButton", {
            AnchorPoint      = Vector2.new(0.5, 0),
            Position         = UDim2.new(0.5, 0, 0, 68),
            Size             = UDim2.fromOffset(150, 30),
            BackgroundColor3 = T:Get("PremiumGold"),
            AutoButtonColor  = false,
            Text             = "✦  Get Premium",
            Font             = Enum.Font.GothamBold,
            TextSize         = 12,
            TextColor3       = Color3.fromRGB(30, 20, 5),
            ZIndex           = 17,
            Parent           = lockCenter,
        })
        Util.Corner(purchBtn, 6)
        Anim.ScalePress(purchBtn)

        purchBtn.MouseButton1Click:Connect(function()
            PremiumManager:Prompt(tabCfg.GamepassId)
        end)

        local PremTab = {
            Type       = "PremiumTab",
            Name       = tabCfg.Name,
            _btn       = tabBtn,
            _scroll    = scroll,
            _container = scroll,
            _unlocked  = false,
        }

        -- ── Gamepass validation (async, fires immediately) ──────────────────
        PremiumManager:Check(LocalPlayer.UserId, tabCfg.GamepassId, function(owned)
            if owned then
                unlocked = true
                PremTab._unlocked = true
                lockOverlay.Visible = false
                badge.Visible       = true
                lockIco.Visible     = false

                -- Swap to real icon if provided
                if tabCfg.Icon then
                    local realId = GetIcon(tabCfg.Icon)
                    if realId then
                        lockIco.Image      = realId
                        lockIco.ImageColor3 = T:Get("PremiumGold")
                        lockIco.Size       = UDim2.fromOffset(16, 16)
                        lockIco.Visible    = true
                    end
                end

                tabLbl.TextColor3 = T:Get("PremiumGold")
                T:Tag(tabLbl, {TextColor3 = "PremiumGold"})

                NotifSystem:Send({
                    Title   = "✦ Premium Active",
                    Content = "Welcome back! All premium features unlocked.",
                    Type    = "Success",
                    Duration = 4,
                })
            end
        end)

        -- Hover
        local premMotor = Anim.TransparencyMotor(tabBtn, "BackgroundTransparency", 1)
        tabBtn.MouseEnter:Connect(function()
            if Window._active and Window._active._btn == tabBtn then return end
            premMotor:Set(0.92)
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._active and Window._active._btn == tabBtn then return end
            premMotor:Set(1)
        end)

        tabBtn.MouseButton1Click:Connect(function()
            if not PremTab._unlocked then
                -- Show locked content view with overlay
                switchTab(PremTab)
                NotifSystem:Send({
                    Title   = "🔒 You are not Premium.",
                    Content = "Purchase the Gamepass to unlock this tab.",
                    Type    = "Warning",
                    Duration = 3,
                })
                return
            end
            switchTab(PremTab)
        end)

        table.insert(Window._tabs, PremTab)

        -- Components locked unless premium
        for name, fn in pairs(Components) do
            PremTab[name] = function(self, ...)
                if not PremTab._unlocked then
                    warn("[Orbit] Cannot add to locked Premium tab")
                    return {Type = "Locked"}
                end
                return fn(self, ...)
            end
        end

        return PremTab
    end

    -- ── Public API ────────────────────────────────────────────────────────────
    function Window:Notify(cfg)  NotifSystem:Send(cfg) end
    function Window:SetTheme(n)  ThemeManager:SetTheme(n) end
    function Window:Minimize()   minimize() end
    function Window:Restore()    restore() end
    function Window:SelectTab(n)
        if Window._tabs[n] then switchTab(Window._tabs[n]) end
    end

    function Window:Destroy()
        Util.Tween(root, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(W * 0.93, H * 0.93),
        })
        task.delay(0.22, function()
            if gui and gui.Parent then gui:Destroy() end
        end)
    end

    return Window
end

-- ─────────────────────────────────────────────────────────────────────────────
-- LIBRARY PUBLIC API
-- ─────────────────────────────────────────────────────────────────────────────
function Library:Notify(cfg)   NotifSystem:Send(cfg) end
function Library:GetFlag(k)    return StateManager:Get(k) end
function Library:SetFlag(k, v) StateManager:Set(k, v) end
function Library:SaveConfig()  ConfigManager:Save(StateManager.Flags) end
function Library:LoadConfig()
    local data = ConfigManager:Load()
    for k, v in pairs(data) do StateManager:Set(k, v) end
    return data
end
function Library:ResetConfig() ConfigManager:Reset() end
function Library:GetIcon(name) return GetIcon(name) end

return Library

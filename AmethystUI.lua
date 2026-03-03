--[[
    AmethystUI - Professional Roblox UI Library
    Amethyst Theme | Executor Compatible | Single File
    Inspired by Fluent UI's Amethyst color palette
]]

local AmethystUI = {}
AmethystUI.__index = AmethystUI

-- ============================================================
-- SERVICES
-- ============================================================
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService         = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Camera      = workspace.CurrentCamera

-- ============================================================
-- AMETHYST THEME (Faithful to Fluent's Amethyst palette)
-- ============================================================
local Theme = {
    Accent            = Color3.fromRGB(97, 62, 167),
    AccentLight       = Color3.fromRGB(130, 95, 200),
    AccentDark        = Color3.fromRGB(68, 40, 120),

    Background        = Color3.fromRGB(18, 12, 28),
    BackgroundSecond  = Color3.fromRGB(26, 18, 40),
    BackgroundThird   = Color3.fromRGB(35, 24, 54),

    Border            = Color3.fromRGB(95, 75, 115),
    BorderLight       = Color3.fromRGB(110, 90, 130),
    BorderDark        = Color3.fromRGB(60, 45, 80),

    TabBg             = Color3.fromRGB(28, 20, 44),
    TabActive         = Color3.fromRGB(50, 35, 78),
    TabHover          = Color3.fromRGB(38, 27, 60),
    TabText           = Color3.fromRGB(160, 140, 180),

    ElementBg         = Color3.fromRGB(32, 22, 50),
    ElementBorder     = Color3.fromRGB(60, 50, 72),
    ElementHover      = Color3.fromRGB(42, 30, 64),

    ToggleOn          = Color3.fromRGB(97, 62, 167),
    ToggleOff         = Color3.fromRGB(55, 42, 75),
    ToggleKnob        = Color3.fromRGB(240, 235, 255),

    SliderRail        = Color3.fromRGB(55, 42, 80),
    SliderFill        = Color3.fromRGB(97, 62, 167),
    SliderKnob        = Color3.fromRGB(200, 180, 230),

    Text              = Color3.fromRGB(240, 235, 255),
    TextSub           = Color3.fromRGB(170, 155, 190),
    TextDim           = Color3.fromRGB(120, 105, 140),
    TextDisabled      = Color3.fromRGB(80, 68, 100),

    SectionLine       = Color3.fromRGB(65, 50, 88),
    GlowColor         = Color3.fromRGB(97, 62, 167),

    Minimize          = Color3.fromRGB(40, 30, 62),
    MinimizeBorder    = Color3.fromRGB(97, 62, 167),
}

-- ============================================================
-- ICON REGISTRY (Valid Roblox Asset IDs from Lucide set)
-- ============================================================
local Icons = {
    ["home"]          = "rbxassetid://10709790681",
    ["settings"]      = "rbxassetid://10709793185",
    ["star"]          = "rbxassetid://10709798778",
    ["user"]          = "rbxassetid://10709802053",
    ["shield"]        = "rbxassetid://10709797015",
    ["sword"]         = "rbxassetid://10709798883",
    ["zap"]           = "rbxassetid://10709803543",
    ["eye"]           = "rbxassetid://10709787100",
    ["lock"]          = "rbxassetid://10709791712",
    ["unlock"]        = "rbxassetid://10709802157",
    ["crown"]         = "rbxassetid://10709783905",
    ["gem"]           = "rbxassetid://10709788042",
    ["fire"]          = "rbxassetid://10710744019",
    ["award"]         = "rbxassetid://10709769406",
    ["bell"]          = "rbxassetid://10709771516",
    ["info"]          = "rbxassetid://10709790155",
    ["alert"]         = "rbxassetid://10709753149",
    ["check"]         = "rbxassetid://10709776821",
    ["x"]             = "rbxassetid://10709803441",
    ["plus"]          = "rbxassetid://10709795600",
    ["minus"]         = "rbxassetid://10709793403",
    ["arrow-right"]   = "rbxassetid://10709768347",
    ["arrow-left"]    = "rbxassetid://10709768114",
    ["chevron-right"] = "rbxassetid://10709779052",
    ["chevron-down"]  = "rbxassetid://10709778861",
    ["menu"]          = "rbxassetid://10709793004",
    ["layers"]        = "rbxassetid://10709791205",
    ["globe"]         = "rbxassetid://10709788490",
    ["map"]           = "rbxassetid://10709792570",
    ["cpu"]           = "rbxassetid://10709783741",
    ["gamepad"]       = "rbxassetid://10709787921",
    ["target"]        = "rbxassetid://10709799155",
    ["crosshair"]     = "rbxassetid://10709784051",
    ["package"]       = "rbxassetid://10709795100",
    ["tool"]          = "rbxassetid://10709799795",
    ["code"]          = "rbxassetid://10709782460",
    ["terminal"]      = "rbxassetid://10709799359",
    ["activity"]      = "rbxassetid://10709752035",
    ["trending-up"]   = "rbxassetid://10709800107",
    ["bar-chart"]     = "rbxassetid://10709773755",
    ["list"]          = "rbxassetid://10709791598",
    ["grip"]          = "rbxassetid://10709788699",
    ["minimize"]      = "rbxassetid://10709793503",
    ["maximize"]      = "rbxassetid://10709793005",
    ["refresh"]       = "rbxassetid://10709796551",
    ["rotate-cw"]     = "rbxassetid://10709797103",
    ["trash"]         = "rbxassetid://10709800403",
    ["save"]          = "rbxassetid://10709797415",
    ["download"]      = "rbxassetid://10709785701",
    ["upload"]        = "rbxassetid://10709802257",
    ["link"]          = "rbxassetid://10709791496",
    ["copy"]          = "rbxassetid://10709783602",
    ["edit"]          = "rbxassetid://10709786296",
    ["search"]        = "rbxassetid://10709797497",
    ["filter"]        = "rbxassetid://10709787516",
    ["sort"]          = "rbxassetid://10709798682",
    ["music"]         = "rbxassetid://10709793893",
    ["volume"]        = "rbxassetid://10709802549",
    ["image"]         = "rbxassetid://10709789652",
    ["video"]         = "rbxassetid://10709802353",
    ["mic"]           = "rbxassetid://10709793203",
    ["wifi"]          = "rbxassetid://10709802877",
    ["bluetooth"]     = "rbxassetid://10709772099",
    ["battery"]       = "rbxassetid://10709771006",
    ["cloud"]         = "rbxassetid://10709782161",
    ["database"]      = "rbxassetid://10709784641",
    ["server"]        = "rbxassetid://10709797716",
    ["monitor"]       = "rbxassetid://10709793602",
    ["smartphone"]    = "rbxassetid://10709797816",
    ["tablet"]        = "rbxassetid://10709799005",
    ["printer"]       = "rbxassetid://10709795700",
    ["clipboard"]     = "rbxassetid://10709781861",
    ["calendar"]      = "rbxassetid://10709774793",
    ["clock"]         = "rbxassetid://10709782001",
    ["timer"]         = "rbxassetid://10709799594",
    ["map-pin"]       = "rbxassetid://10709792671",
    ["compass"]       = "rbxassetid://10709782762",
    ["flag"]          = "rbxassetid://10709787614",
    ["bookmark"]      = "rbxassetid://10709772301",
    ["tag"]           = "rbxassetid://10709799005",
    ["hash"]          = "rbxassetid://10709789054",
    ["at-sign"]       = "rbxassetid://10709769286",
    ["mail"]          = "rbxassetid://10709792470",
    ["message"]       = "rbxassetid://10709793104",
    ["chat"]          = "rbxassetid://10709776121",
    ["heart"]         = "rbxassetid://10709789254",
    ["thumbs-up"]     = "rbxassetid://10709799494",
    ["smile"]         = "rbxassetid://10709797916",
    ["sun"]           = "rbxassetid://10709798883",
    ["moon"]          = "rbxassetid://10709793702",
    ["cloud-rain"]    = "rbxassetid://10709782261",
    ["wind"]          = "rbxassetid://10709803041",
    ["droplet"]       = "rbxassetid://10709785902",
    ["anchor"]        = "rbxassetid://10709761530",
    ["aperture"]      = "rbxassetid://10709761813",
    ["box"]           = "rbxassetid://10709772601",
    ["circle"]        = "rbxassetid://10709780761",
    ["square"]        = "rbxassetid://10709798282",
    ["triangle"]      = "rbxassetid://10709800207",
    ["hex"]           = "rbxassetid://10709789354",
    ["octagon"]       = "rbxassetid://10709794801",
    ["grid"]          = "rbxassetid://10709788799",
    ["columns"]       = "rbxassetid://10709782562",
    ["layout"]        = "rbxassetid://10709791305",
    ["sidebar"]       = "rbxassetid://10709797116",
    ["panel"]         = "rbxassetid://10709795200",
    ["folder"]        = "rbxassetid://10709787716",
    ["file"]          = "rbxassetid://10709787314",
    ["paper"]         = "rbxassetid://10709795300",
    ["book"]          = "rbxassetid://10709772201",
    ["library"]       = "rbxassetid://10709791498",
    ["pen"]           = "rbxassetid://10709795400",
    ["feather"]       = "rbxassetid://10709787214",
    ["type"]          = "rbxassetid://10709801157",
    ["align-left"]    = "rbxassetid://10709759764",
    ["align-center"]  = "rbxassetid://10709753570",
    ["bold"]          = "rbxassetid://10709772000",
    ["italic"]        = "rbxassetid://10709790255",
    ["underline"]     = "rbxassetid://10709801957",
    ["key"]           = "rbxassetid://10709790781",
    ["power"]         = "rbxassetid://10709795500",
    ["pause"]         = "rbxassetid://10709795200",
    ["play"]          = "rbxassetid://10709795400",
    ["stop"]          = "rbxassetid://10709798682",
    ["skip-forward"]  = "rbxassetid://10709797516",
    ["skip-back"]     = "rbxassetid://10709797316",
    ["shuffle"]       = "rbxassetid://10709797216",
    ["repeat"]        = "rbxassetid://10709796651",
    ["radio"]         = "rbxassetid://10709796150",
    ["cast"]          = "rbxassetid://10709775893",
    ["rss"]           = "rbxassetid://10709797203",
    ["share"]         = "rbxassetid://10709797016",
    ["send"]          = "rbxassetid://10709797616",
    ["inbox"]         = "rbxassetid://10709789952",
    ["archive"]       = "rbxassetid://10709762233",
    ["delete"]        = "rbxassetid://10709784941",
    ["alert-circle"]  = "rbxassetid://10709752996",
    ["help-circle"]   = "rbxassetid://10709789454",
    ["slash"]         = "rbxassetid://10709797816",
    ["loader"]        = "rbxassetid://10709791702",
    ["more-h"]        = "rbxassetid://10709793803",
    ["more-v"]        = "rbxassetid://10709793903",
    ["external-link"] = "rbxassetid://10709787000",
    ["log-in"]        = "rbxassetid://10709791900",
    ["log-out"]       = "rbxassetid://10709792000",
    ["user-plus"]     = "rbxassetid://10709802153",
    ["users"]         = "rbxassetid://10709802253",
    ["move"]          = "rbxassetid://10709794001",
    ["maximize2"]     = "rbxassetid://10709793005",
    ["minimize2"]     = "rbxassetid://10709793503",
    ["expand"]        = "rbxassetid://10709786800",
    ["shrink"]        = "rbxassetid://10709797116",
    ["zoom-in"]       = "rbxassetid://10709803643",
    ["zoom-out"]      = "rbxassetid://10709803743",
    ["crop"]          = "rbxassetid://10709784151",
    ["scissors"]      = "rbxassetid://10709797497",
    ["git-branch"]    = "rbxassetid://10709788191",
    ["git-commit"]    = "rbxassetid://10709788291",
    ["git-merge"]     = "rbxassetid://10709788391",
    ["git-pull"]      = "rbxassetid://10709788491",
    ["github"]        = "rbxassetid://10709788591",
    ["twitter"]       = "rbxassetid://10709800307",
    ["facebook"]      = "rbxassetid://10709786997",
    ["instagram"]     = "rbxassetid://10709790055",
    ["youtube"]       = "rbxassetid://10709803343",
    ["twitch"]        = "rbxassetid://10709800207",
    ["discord"]       = "rbxassetid://10709785401",
    ["slack"]         = "rbxassetid://10709797716",
    ["trello"]        = "rbxassetid://10709800107",
    ["figma"]         = "rbxassetid://10709787414",
    ["framer"]        = "rbxassetid://10709787814",
    ["codepen"]       = "rbxassetid://10709782360",
    ["codesandbox"]   = "rbxassetid://10709782461",
    ["chrome"]        = "rbxassetid://10709780761",
    ["firefox"]       = "rbxassetid://10709787614",
    ["coffee"]        = "rbxassetid://10709782261",
    ["pizza"]         = "rbxassetid://10709795500",
    ["shoppingcart"]  = "rbxassetid://10709797116",
    ["gift"]          = "rbxassetid://10709788091",
    ["trophy"]        = "rbxassetid://10709800007",
    ["dice"]          = "rbxassetid://10709785201",
    ["sword-crossed"] = "rbxassetid://10709798983",
    ["shield-off"]    = "rbxassetid://10709797115",
    ["weapon"]        = "rbxassetid://10709803041",
    ["magic-wand"]    = "rbxassetid://10709792370",
    ["sparkles"]      = "rbxassetid://10709798082",
    ["wand"]          = "rbxassetid://10709802649",
    ["flask"]         = "rbxassetid://10709787714",
    ["atom"]          = "rbxassetid://10709769508",
    ["radiation"]     = "rbxassetid://10709796050",
    ["biohazard"]     = "rbxassetid://10709771716",
    ["skull"]         = "rbxassetid://10709797916",
    ["ghost"]         = "rbxassetid://10709787921",
    ["bug"]           = "rbxassetid://10709773555",
    ["robot"]         = "rbxassetid://10709797003",
    ["cpu-chip"]      = "rbxassetid://10709783741",
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================
local function GetIcon(name)
    if not name or name == "" then return nil end
    return Icons[name:lower()] or nil
end

local function Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function QuintTween(obj, t, props)
    return Tween(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
end

local function QuadTween(obj, t, props)
    return Tween(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

local function Round(n, dec)
    dec = dec or 0
    local m = 10^dec
    return math.floor(n * m + 0.5) / m
end

local function SafeCallback(cb, ...)
    if type(cb) == "function" then
        local ok, err = pcall(cb, ...)
        if not ok then
            warn("[AmethystUI] Callback error: " .. tostring(err))
        end
    end
end

-- ============================================================
-- UI CREATION HELPERS
-- ============================================================
local function New(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        if child then child.Parent = obj end
    end
    if props and props.Parent then
        obj.Parent = props.Parent
    end
    return obj
end

local function Corner(radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function Stroke(color, thickness, trans)
    return New("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Padding(t, b, l, r)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
        PaddingRight  = UDim.new(0, r or 0),
    })
end

local function ListLayout(dir, align, padding, sort)
    return New("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
        SortOrder           = sort or Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, padding or 0),
    })
end

local function Label(text, size, color, font, xa, ya, bgTrans)
    return New("TextLabel", {
        Text                = text or "",
        TextSize            = size or 13,
        TextColor3          = color or Theme.Text,
        TextTransparency    = 0,
        FontFace            = font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
        TextXAlignment      = xa or Enum.TextXAlignment.Left,
        TextYAlignment      = ya or Enum.TextYAlignment.Center,
        BackgroundTransparency = bgTrans ~= nil and bgTrans or 1,
        TextWrapped         = true,
        RichText            = true,
    })
end

-- ============================================================
-- SCREEN GUI SETUP
-- ============================================================
local function CreateScreenGui()
    -- Remove existing instances on reload
    local existing = LocalPlayer:FindFirstChild("PlayerGui")
    if existing then
        local old = existing:FindFirstChild("AmethystUI")
        if old then old:Destroy() end
    end

    local ScreenGui = New("ScreenGui", {
        Name                  = "AmethystUI",
        ZIndexBehavior        = Enum.ZIndexBehavior.Sibling,
        DisplayOrder          = 999,
        ResetOnSpawn          = false,
        IgnoreGuiInset        = true,
        Parent                = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui"),
    })
    return ScreenGui
end

-- ============================================================
-- WINDOW
-- ============================================================
function AmethystUI:CreateWindow(config)
    config = config or {}
    local title    = config.Title    or "AmethystUI"
    local subtitle = config.SubTitle or ""
    local winW     = config.Width    or 580
    local winH     = config.Height   or 460
    local tabW     = config.TabWidth or 150

    local ScreenGui = CreateScreenGui()
    local vp = Camera.ViewportSize
    local startX = math.floor(vp.X / 2 - winW / 2)
    local startY = math.floor(vp.Y / 2 - winH / 2)

    -- ── Scale wrapper for mobile ─────────────────────────────
    local ScaleContainer = New("Frame", {
        Name                 = "ScaleContainer",
        Size                 = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent               = ScreenGui,
    })

    -- Dynamic mobile scaling: shrink UI if screen is smaller than 600px wide
    local UIScaleObj = New("UIScale", {
        Scale  = 1,
        Parent = ScaleContainer,
    })

    local function UpdateScale()
        local vps = Camera.ViewportSize
        local baseW = 900
        local scaleF = math.clamp(vps.X / baseW, 0.55, 1)
        UIScaleObj.Scale = scaleF
    end

    UpdateScale()
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)

    -- ── Main Window Frame ────────────────────────────────────
    local WindowFrame = New("Frame", {
        Name                = "Window",
        Size                = UDim2.fromOffset(winW, winH),
        Position            = UDim2.fromOffset(startX, startY),
        BackgroundColor3    = Theme.Background,
        BackgroundTransparency = 0,
        BorderSizePixel     = 0,
        ClipsDescendants    = false,
        Parent              = ScaleContainer,
    }, {
        Corner(10),
        Stroke(Theme.Border, 1, 0),
    })

    -- Gradient overlay on window
    local WinGradient = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.BackgroundThird or Color3.fromRGB(35, 24, 54)),
            ColorSequenceKeypoint.new(1, Theme.Background),
        }),
        Rotation = 145,
        Parent = WindowFrame,
    })

    -- ── Title Bar ────────────────────────────────────────────
    local TitleBar = New("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.BackgroundSecond,
        BackgroundTransparency = 0,
        ZIndex           = 5,
        Parent           = WindowFrame,
    }, {
        Corner(10),
        New("Frame", { -- Cover bottom corners
            Size             = UDim2.new(1, 0, 0, 10),
            Position         = UDim2.new(0, 0, 1, -10),
            BackgroundColor3 = Theme.BackgroundSecond,
            BackgroundTransparency = 0,
            BorderSizePixel  = 0,
            ZIndex           = 4,
        }),
        New("Frame", { -- Bottom border line
            Size             = UDim2.new(1, 0, 0, 1),
            Position         = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = Theme.Border,
            BorderSizePixel  = 0,
            ZIndex           = 6,
        }),
    })

    -- Accent bar (left edge of titlebar)
    New("Frame", {
        Size             = UDim2.fromOffset(3, 22),
        Position         = UDim2.new(0, 12, 0.5, -11),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 7,
        Parent           = TitleBar,
    }, { Corner(2) })

    -- Title text
    local TitleLabel = Label(title, 15, Theme.Text,
        Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold))
    TitleLabel.Size      = UDim2.new(1, -90, 0, 20)
    TitleLabel.Position  = UDim2.fromOffset(22, 8)
    TitleLabel.ZIndex    = 7
    TitleLabel.Parent    = TitleBar

    -- Sub-title text
    local SubLabel = Label(subtitle, 11, Theme.TextSub)
    SubLabel.Size     = UDim2.new(1, -90, 0, 14)
    SubLabel.Position = UDim2.fromOffset(22, 28)
    SubLabel.ZIndex   = 7
    SubLabel.Parent   = TitleBar

    -- Minimize button
    local MinimizeBtn = New("TextButton", {
        Size             = UDim2.fromOffset(28, 28),
        Position         = UDim2.new(1, -38, 0.5, -14),
        BackgroundColor3 = Theme.ElementBg,
        BackgroundTransparency = 0,
        Text             = "",
        ZIndex           = 8,
        Parent           = TitleBar,
    }, {
        Corner(6),
        Stroke(Theme.Border, 1, 0.3),
        New("ImageLabel", {
            Size               = UDim2.fromOffset(14, 14),
            Position           = UDim2.new(0.5, -7, 0.5, -7),
            BackgroundTransparency = 1,
            Image              = Icons["minimize2"] or "rbxassetid://10709793503",
            ImageColor3        = Theme.TextSub,
            ZIndex             = 9,
        }),
    })

    -- ── Left Tab Panel ───────────────────────────────────────
    local TabPanel = New("Frame", {
        Name             = "TabPanel",
        Size             = UDim2.new(0, tabW, 1, -48),
        Position         = UDim2.fromOffset(0, 48),
        BackgroundColor3 = Theme.TabBg,
        BackgroundTransparency = 0,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = WindowFrame,
    }, {
        New("Frame", { -- Right border line
            Size             = UDim2.fromOffset(1, 0),
            Position         = UDim2.new(1, -1, 0, 0),
            BackgroundColor3 = Theme.Border,
            BorderSizePixel  = 0,
        }),
        -- Bottom left corner cover
        New("Frame", {
            Size             = UDim2.new(0, tabW, 0, 10),
            Position         = UDim2.new(0, 0, 1, -10),
            BackgroundColor3 = Theme.TabBg,
            BackgroundTransparency = 0,
            BorderSizePixel  = 0,
        }),
    })

    -- Active tab selection bar
    local TabSelector = New("Frame", {
        Size             = UDim2.fromOffset(3, 24),
        Position         = UDim2.fromOffset(0, 8),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        Parent           = TabPanel,
    }, { Corner(2) })

    -- Scrolling frame for tabs
    local TabScroll = New("ScrollingFrame", {
        Name                   = "TabScroll",
        Size                   = UDim2.new(1, 0, 1, -8),
        Position               = UDim2.fromOffset(0, 8),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 2,
        ScrollBarImageColor3   = Theme.Accent,
        ScrollBarImageTransparency = 0.5,
        CanvasSize             = UDim2.fromScale(0, 0),
        ScrollingDirection     = Enum.ScrollingDirection.Y,
        ZIndex                 = 4,
        Parent                 = TabPanel,
    }, {
        ListLayout(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, 2),
        Padding(4, 4, 6, 6),
    })

    -- Auto-size tab scroll canvas
    TabScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabScroll.CanvasSize = UDim2.new(0, 0, 0,
            TabScroll.UIListLayout.AbsoluteContentSize.Y + 8)
    end)

    -- ── Content Area ─────────────────────────────────────────
    local ContentArea = New("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -tabW - 1, 1, -48),
        Position         = UDim2.new(0, tabW + 1, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex           = 3,
        Parent           = WindowFrame,
    })

    -- ── Minimize Orb (tiny rounded square) ───────────────────
    local MinOrb = New("TextButton", {
        Name             = "MinimizeOrb",
        Size             = UDim2.fromOffset(42, 42),
        Position         = UDim2.fromOffset(startX, startY),
        BackgroundColor3 = Theme.Minimize,
        BackgroundTransparency = 0,
        Text             = "",
        Visible          = false,
        ZIndex           = 50,
        Parent           = ScaleContainer,
    }, {
        Corner(10),
        Stroke(Theme.MinimizeBorder, 1.5, 0),
        New("ImageLabel", {
            Size               = UDim2.fromOffset(22, 22),
            Position           = UDim2.new(0.5, -11, 0.5, -11),
            BackgroundTransparency = 1,
            Image              = Icons["layers"] or "rbxassetid://10709791205",
            ImageColor3        = Theme.Accent,
            ZIndex             = 51,
        }),
    })

    -- Glow effect on MinOrb
    New("UIGradient", {
        Color    = ColorSequence.new(Theme.Accent, Theme.AccentDark),
        Rotation = 45,
        Parent   = MinOrb,
    })

    -- ── Window State ─────────────────────────────────────────
    local Window = {
        Frame        = WindowFrame,
        TitleBar     = TitleBar,
        TabPanel     = TabPanel,
        TabScroll    = TabScroll,
        TabSelector  = TabSelector,
        ContentArea  = ContentArea,
        MinOrb       = MinOrb,
        ScreenGui    = ScreenGui,
        Tabs         = {},
        ActiveTab    = nil,
        Minimized    = false,
        Options      = {},
    }

    -- ── Dragging Logic ───────────────────────────────────────
    do
        local dragging = false
        local dragStart, startPos

        TitleBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                dragStart = inp.Position
                startPos  = WindowFrame.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (
                inp.UserInputType == Enum.UserInputType.MouseMovement or
                inp.UserInputType == Enum.UserInputType.Touch
            ) then
                local delta = inp.Position - dragStart
                WindowFrame.Position = UDim2.fromOffset(
                    startPos.X.Offset + delta.X,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- MinOrb dragging
    do
        local dragging = false
        local dragStart, startPos

        MinOrb.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging  = true
                dragStart = inp.Position
                startPos  = MinOrb.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (
                inp.UserInputType == Enum.UserInputType.MouseMovement or
                inp.UserInputType == Enum.UserInputType.Touch
            ) then
                local delta = inp.Position - dragStart
                MinOrb.Position = UDim2.fromOffset(
                    startPos.X.Offset + delta.X,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    -- ── Minimize / Maximize ──────────────────────────────────
    local function DoMinimize()
        Window.Minimized = true
        -- Save orb position near window
        local wp = WindowFrame.Position
        MinOrb.Position = UDim2.fromOffset(wp.X.Offset + 4, wp.Y.Offset + 4)

        -- Shrink window to nothing then hide
        QuintTween(WindowFrame, 0.28, {
            Size = UDim2.fromOffset(winW, 0),
            BackgroundTransparency = 0.35,
        })
        task.delay(0.28, function()
            WindowFrame.Visible = false
            WindowFrame.Size = UDim2.fromOffset(winW, winH)
            WindowFrame.BackgroundTransparency = 0
            MinOrb.Visible = true
            QuintTween(MinOrb, 0.22, {
                Size = UDim2.fromOffset(42, 42),
                BackgroundTransparency = 0,
            })
        end)
    end

    local function DoMaximize()
        Window.Minimized = false
        -- Fade orb out
        QuintTween(MinOrb, 0.16, {
            Size = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
        })
        task.delay(0.16, function()
            MinOrb.Visible = false
            MinOrb.Size = UDim2.fromOffset(42, 42)
            MinOrb.BackgroundTransparency = 0
            WindowFrame.Visible = true
            WindowFrame.Size = UDim2.fromOffset(winW, 0)
            WindowFrame.BackgroundTransparency = 0
            QuintTween(WindowFrame, 0.28, {
                Size = UDim2.fromOffset(winW, winH),
            })
        end)
    end

    MinimizeBtn.MouseButton1Click:Connect(DoMinimize)
    MinOrb.MouseButton1Click:Connect(DoMaximize)

    -- Hover effects on MinimizeBtn
    MinimizeBtn.MouseEnter:Connect(function()
        QuadTween(MinimizeBtn, 0.12, { BackgroundColor3 = Theme.ElementHover })
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        QuadTween(MinimizeBtn, 0.12, { BackgroundColor3 = Theme.ElementBg })
    end)

    -- Open animation
    WindowFrame.Size = UDim2.fromOffset(winW, 0)
    WindowFrame.BackgroundTransparency = 0.6
    QuintTween(WindowFrame, 0.35, {
        Size                = UDim2.fromOffset(winW, winH),
        BackgroundTransparency = 0,
    })

    -- ── Tab Selector Animation ───────────────────────────────
    function Window:AnimateSelector(tabBtn)
        local relY = tabBtn.AbsolutePosition.Y - TabPanel.AbsolutePosition.Y
            + TabScroll.CanvasPosition.Y - 8
        local h = tabBtn.AbsoluteSize.Y - 8
        QuintTween(TabSelector, 0.22, {
            Position = UDim2.fromOffset(0, relY + 4),
            Size     = UDim2.fromOffset(3, h),
        })
    end

    -- ── Add Tab ──────────────────────────────────────────────
    function Window:AddTab(cfg)
        cfg = cfg or {}
        local tabTitle = cfg.Title or "Tab"
        local tabIcon  = cfg.Icon  or nil
        local iconId   = GetIcon(tabIcon)

        -- Tab button
        local TabBtn = New("TextButton", {
            Name             = "Tab_" .. tabTitle,
            Size             = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Theme.TabBg,
            BackgroundTransparency = 1,
            Text             = "",
            AutoButtonColor  = false,
            ZIndex           = 5,
            Parent           = TabScroll,
        }, { Corner(7) })

        -- Icon (optional)
        local IconImg = nil
        if iconId then
            IconImg = New("ImageLabel", {
                Size               = UDim2.fromOffset(16, 16),
                Position           = UDim2.fromOffset(10, 9),
                BackgroundTransparency = 1,
                Image              = iconId,
                ImageColor3        = Theme.TabText,
                ZIndex             = 6,
                Parent             = TabBtn,
            })
        end

        -- Tab label
        local TabLabel = Label(tabTitle, 12, Theme.TabText)
        TabLabel.Size     = UDim2.new(1, iconId and -34 or -16, 1, 0)
        TabLabel.Position = UDim2.fromOffset(iconId and 32 or 12, 0)
        TabLabel.ZIndex   = 6
        TabLabel.Parent   = TabBtn
        TabLabel.TextTransparency = 0

        -- Tab container (scrolling content)
        local TabContainer = New("ScrollingFrame", {
            Name                   = "Container_" .. tabTitle,
            Size                   = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = Theme.Accent,
            ScrollBarImageTransparency = 0.4,
            CanvasSize             = UDim2.fromScale(0, 0),
            ScrollingDirection     = Enum.ScrollingDirection.Y,
            Visible                = false,
            ZIndex                 = 4,
            Parent                 = ContentArea,
        }, {
            ListLayout(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, 5),
            Padding(10, 10, 10, 10),
        })

        TabContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContainer.CanvasSize = UDim2.new(0, 0, 0,
                TabContainer.UIListLayout.AbsoluteContentSize.Y + 20)
        end)

        local Tab = {
            Button    = TabBtn,
            Container = TabContainer,
            Label     = TabLabel,
            Icon      = IconImg,
            Window    = Window,
        }

        -- Select tab
        local function SelectThis()
            -- Deselect current
            if Window.ActiveTab and Window.ActiveTab ~= Tab then
                local old = Window.ActiveTab
                old.Container.Visible = false
                QuadTween(old.Button, 0.15, { BackgroundTransparency = 1 })
                old.Label.TextColor3 = Theme.TabText
                if old.Icon then old.Icon.ImageColor3 = Theme.TabText end
            end

            Window.ActiveTab = Tab
            Tab.Container.Visible = true
            QuadTween(TabBtn, 0.15, {
                BackgroundColor3 = Theme.TabActive,
                BackgroundTransparency = 0,
            })
            Tab.Label.TextColor3 = Theme.Text
            Tab.Label.TextTransparency = 0
            if IconImg then IconImg.ImageColor3 = Theme.Accent end
            Window:AnimateSelector(TabBtn)
        end

        TabBtn.MouseButton1Click:Connect(SelectThis)

        TabBtn.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                QuadTween(TabBtn, 0.12, {
                    BackgroundColor3 = Theme.TabHover,
                    BackgroundTransparency = 0,
                })
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                QuadTween(TabBtn, 0.12, { BackgroundTransparency = 1 })
            end
        end)

        table.insert(Window.Tabs, Tab)

        -- Auto-select first tab
        if #Window.Tabs == 1 then
            task.defer(SelectThis)
        end

        -- ── Element creation methods ─────────────────────────

        -- Internal: create base element frame
        local function MakeElementFrame(cfg2, hasRight)
            local h = cfg2.Description and 52 or 38
            local EFrame = New("TextButton", {
                Size             = UDim2.new(1, 0, 0, h),
                BackgroundColor3 = Theme.ElementBg,
                BackgroundTransparency = 0,
                AutoButtonColor  = false,
                Text             = "",
                ZIndex           = 5,
                Parent           = TabContainer,
            }, {
                Corner(8),
                Stroke(Theme.ElementBorder, 1, 0.2),
            })

            local TitleL = Label(cfg2.Title or "", 13, Theme.Text,
                Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium))
            TitleL.Size     = UDim2.new(1, hasRight and -90 or -12, 0, 18)
            TitleL.Position = UDim2.fromOffset(12, cfg2.Description and 8 or 10)
            TitleL.ZIndex   = 6
            TitleL.TextTransparency = 0
            TitleL.Parent   = EFrame

            local DescL = nil
            if cfg2.Description then
                DescL = Label(cfg2.Description, 11, Theme.TextSub)
                DescL.Size     = UDim2.new(1, hasRight and -90 or -12, 0, 14)
                DescL.Position = UDim2.fromOffset(12, 28)
                DescL.ZIndex   = 6
                DescL.TextTransparency = 0
                DescL.Parent   = EFrame
            end

            -- Hover
            EFrame.MouseEnter:Connect(function()
                QuadTween(EFrame, 0.12, { BackgroundColor3 = Theme.ElementHover })
            end)
            EFrame.MouseLeave:Connect(function()
                QuadTween(EFrame, 0.12, { BackgroundColor3 = Theme.ElementBg })
            end)

            return EFrame, TitleL, DescL
        end

        -- ── BUTTON ───────────────────────────────────────────
        function Tab:AddButton(cfg2)
            cfg2 = cfg2 or {}
            assert(cfg2.Title, "AddButton: Title required")
            local cb = cfg2.Callback or function() end

            local EFrame, TitleL = MakeElementFrame(cfg2, true)

            -- Arrow icon
            New("ImageLabel", {
                Size               = UDim2.fromOffset(16, 16),
                Position           = UDim2.new(1, -12, 0.5, -8),
                BackgroundTransparency = 1,
                Image              = Icons["arrow-right"] or "rbxassetid://10709768347",
                ImageColor3        = Theme.TextDim,
                ZIndex             = 7,
                Parent             = EFrame,
            })

            EFrame.MouseButton1Click:Connect(function()
                -- Click flash
                QuadTween(EFrame, 0.06, { BackgroundColor3 = Theme.AccentDark })
                QuadTween(EFrame, 0.15, { BackgroundColor3 = Theme.ElementHover })
                SafeCallback(cb)
            end)

            return {
                SetTitle = function(_, t)
                    TitleL.Text = t
                    TitleL.TextTransparency = 0
                end,
            }
        end

        -- ── TOGGLE ───────────────────────────────────────────
        function Tab:AddToggle(id, cfg2)
            cfg2 = cfg2 or {}
            assert(cfg2.Title, "AddToggle: Title required")
            local cb = cfg2.Callback or function() end
            local val = cfg2.Default == true

            local EFrame, TitleL = MakeElementFrame(cfg2, true)

            -- Track frame (background pill)
            local Track = New("Frame", {
                Size             = UDim2.fromOffset(38, 20),
                Position         = UDim2.new(1, -12, 0.5, -10),
                BackgroundColor3 = val and Theme.ToggleOn or Theme.ToggleOff,
                BorderSizePixel  = 0,
                ZIndex           = 7,
                Parent           = EFrame,
            }, {
                Corner(10),
                Stroke(val and Theme.Accent or Theme.BorderDark or Color3.fromRGB(60,50,80), 1, 0.2),
            })

            -- Knob
            local Knob = New("Frame", {
                Size             = UDim2.fromOffset(14, 14),
                Position         = UDim2.fromOffset(val and 21 or 3, 3),
                BackgroundColor3 = Theme.ToggleKnob,
                BorderSizePixel  = 0,
                ZIndex           = 8,
                Parent           = Track,
            }, { Corner(7) })

            local ToggleObj = {
                Value    = val,
                Callback = cb,
                Track    = Track,
                Knob     = Knob,
                Changed  = nil,
            }

            local function Refresh()
                QuintTween(Track, 0.22, {
                    BackgroundColor3 = ToggleObj.Value and Theme.ToggleOn or Theme.ToggleOff,
                })
                QuintTween(Knob, 0.22, {
                    Position = UDim2.fromOffset(ToggleObj.Value and 21 or 3, 3),
                })
                local stroke = Track:FindFirstChildOfClass("UIStroke")
                if stroke then
                    QuadTween(stroke, 0.22, {
                        Color = ToggleObj.Value and Theme.Accent or Theme.Border,
                    })
                end
                SafeCallback(ToggleObj.Callback, ToggleObj.Value)
                SafeCallback(ToggleObj.Changed, ToggleObj.Value)
            end

            function ToggleObj:SetValue(v)
                self.Value = not not v
                Refresh()
            end

            function ToggleObj:OnChanged(fn)
                self.Changed = fn
            end

            EFrame.MouseButton1Click:Connect(function()
                ToggleObj:SetValue(not ToggleObj.Value)
            end)
            Track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    ToggleObj:SetValue(not ToggleObj.Value)
                end
            end)

            if id then
                Window.Options[id] = ToggleObj
            end
            return ToggleObj
        end

        -- ── SLIDER ───────────────────────────────────────────
        function Tab:AddSlider(id, cfg2)
            cfg2 = cfg2 or {}
            assert(cfg2.Title, "AddSlider: Title required")
            local cb      = cfg2.Callback or function() end
            local minVal  = cfg2.Min      or 0
            local maxVal  = cfg2.Max      or 100
            local defVal  = cfg2.Default  or minVal
            local rounding = cfg2.Rounding or 0

            local h = (cfg2.Description and 62 or 50)
            local EFrame = New("TextButton", {
                Size             = UDim2.new(1, 0, 0, h),
                BackgroundColor3 = Theme.ElementBg,
                BackgroundTransparency = 0,
                AutoButtonColor  = false,
                Text             = "",
                ZIndex           = 5,
                Parent           = TabContainer,
            }, {
                Corner(8),
                Stroke(Theme.ElementBorder, 1, 0.2),
            })

            EFrame.MouseEnter:Connect(function()
                QuadTween(EFrame, 0.12, { BackgroundColor3 = Theme.ElementHover })
            end)
            EFrame.MouseLeave:Connect(function()
                QuadTween(EFrame, 0.12, { BackgroundColor3 = Theme.ElementBg })
            end)

            local TitleL = Label(cfg2.Title, 13, Theme.Text,
                Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium))
            TitleL.Size     = UDim2.new(1, -80, 0, 16)
            TitleL.Position = UDim2.fromOffset(12, cfg2.Description and 8 or 6)
            TitleL.ZIndex   = 6
            TitleL.TextTransparency = 0
            TitleL.Parent   = EFrame

            if cfg2.Description then
                local DescL = Label(cfg2.Description, 11, Theme.TextSub)
                DescL.Size     = UDim2.new(1, -80, 0, 14)
                DescL.Position = UDim2.fromOffset(12, 24)
                DescL.ZIndex   = 6
                DescL.TextTransparency = 0
                DescL.Parent   = EFrame
            end

            -- Value display
            local ValLabel = Label(tostring(defVal), 11, Theme.TextSub)
            ValLabel.Size            = UDim2.fromOffset(60, 14)
            ValLabel.Position        = UDim2.new(1, -72, 0, cfg2.Description and 8 or 6)
            ValLabel.ZIndex          = 6
            ValLabel.TextTransparency= 0
            ValLabel.TextXAlignment  = Enum.TextXAlignment.Right
            ValLabel.Parent          = EFrame

            -- Rail
            local Rail = New("Frame", {
                Size             = UDim2.new(1, -24, 0, 4),
                Position         = UDim2.new(0, 12, 1, -14),
                BackgroundColor3 = Theme.SliderRail,
                BackgroundTransparency = 0,
                ZIndex           = 6,
                Parent           = EFrame,
            }, { Corner(2) })

            -- Fill
            local Fill = New("Frame", {
                Size             = UDim2.fromScale(0, 1),
                BackgroundColor3 = Theme.SliderFill,
                BorderSizePixel  = 0,
                ZIndex           = 7,
                Parent           = Rail,
            }, { Corner(2) })

            -- Knob
            local SliderKnob = New("Frame", {
                Size             = UDim2.fromOffset(14, 14),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                Position         = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = Theme.SliderKnob,
                BorderSizePixel  = 0,
                ZIndex           = 8,
                Parent           = Rail,
            }, {
                Corner(7),
                Stroke(Theme.Accent, 1.5, 0),
            })

            local SliderObj = {
                Value    = defVal,
                Min      = minVal,
                Max      = maxVal,
                Rounding = rounding,
                Callback = cb,
                Changed  = nil,
            }

            local function UpdateSlider(v)
                local clamped = math.clamp(v, minVal, maxVal)
                local rounded = Round(clamped, rounding)
                SliderObj.Value = rounded
                local pct = (rounded - minVal) / (maxVal - minVal)
                Fill.Size = UDim2.fromScale(pct, 1)
                SliderKnob.Position = UDim2.new(pct, 0, 0.5, 0)
                ValLabel.Text = tostring(rounded)
                ValLabel.TextTransparency = 0
                SafeCallback(SliderObj.Callback, rounded)
                SafeCallback(SliderObj.Changed, rounded)
            end

            function SliderObj:SetValue(v)
                UpdateSlider(v)
            end

            function SliderObj:OnChanged(fn)
                self.Changed = fn
            end

            -- Drag logic
            local dragging = false

            local function HandleDrag(pos)
                local railAbsX = Rail.AbsolutePosition.X
                local railAbsW = Rail.AbsoluteSize.X
                local pct = math.clamp((pos.X - railAbsX) / railAbsW, 0, 1)
                UpdateSlider(minVal + (maxVal - minVal) * pct)
            end

            Rail.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    HandleDrag(inp.Position)
                end
            end)

            SliderKnob.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)

            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(inp)
                if dragging and (
                    inp.UserInputType == Enum.UserInputType.MouseMovement or
                    inp.UserInputType == Enum.UserInputType.Touch
                ) then
                    HandleDrag(inp.Position)
                end
            end)

            UpdateSlider(defVal)

            if id then
                Window.Options[id] = SliderObj
            end
            return SliderObj
        end

        -- ── PARAGRAPH ────────────────────────────────────────
        function Tab:AddParagraph(cfg2)
            cfg2 = cfg2 or {}
            assert(cfg2.Title, "AddParagraph: Title required")
            local content = cfg2.Content or ""

            local PFrame = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.ElementBg,
                BackgroundTransparency = 0.15,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = TabContainer,
            }, {
                Corner(8),
                Stroke(Theme.ElementBorder, 1, 0.4),
                Padding(10, 10, 12, 12),
            })

            local TitleL = Label(cfg2.Title, 13, Theme.Text,
                Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold))
            TitleL.Size     = UDim2.new(1, 0, 0, 18)
            TitleL.ZIndex   = 6
            TitleL.TextTransparency = 0
            TitleL.Parent   = PFrame

            local ContentL = Label(content, 12, Theme.TextSub)
            ContentL.Size          = UDim2.new(1, 0, 0, 0)
            ContentL.Position      = UDim2.fromOffset(0, 22)
            ContentL.AutomaticSize = Enum.AutomaticSize.Y
            ContentL.ZIndex        = 6
            ContentL.TextTransparency = 0
            ContentL.TextYAlignment   = Enum.TextYAlignment.Top
            ContentL.Parent           = PFrame

            local ParagraphObj = {}

            function ParagraphObj:SetContent(txt)
                ContentL.Text = txt
                ContentL.TextTransparency = 0
            end

            function ParagraphObj:SetTitle(txt)
                TitleL.Text = txt
                TitleL.TextTransparency = 0
            end

            function ParagraphObj:SetVisible(v)
                PFrame.Visible = v
            end

            return ParagraphObj
        end

        -- ── LABEL ────────────────────────────────────────────
        function Tab:AddLabel(cfg2)
            cfg2 = cfg2 or {}
            local text  = type(cfg2) == "string" and cfg2 or (cfg2.Text or cfg2.Title or "")
            local color = (type(cfg2) == "table" and cfg2.Color) or Theme.Text

            local LFrame = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = TabContainer,
            })

            local Lbl = Label(text, 13, color)
            Lbl.Size     = UDim2.new(1, -12, 1, 0)
            Lbl.Position = UDim2.fromOffset(12, 0)
            Lbl.ZIndex   = 6
            Lbl.TextTransparency = 0
            Lbl.Parent   = LFrame

            local LabelObj = {}
            function LabelObj:SetText(t)
                Lbl.Text = t
                Lbl.TextTransparency = 0
            end
            function LabelObj:SetColor(c)
                Lbl.TextColor3 = c
            end
            return LabelObj
        end

        -- ── SECTION DIVIDER ──────────────────────────────────
        function Tab:AddSection(cfg2)
            cfg2 = cfg2 or {}
            local text = type(cfg2) == "string" and cfg2 or (cfg2.Title or "")

            local SFrame = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                ZIndex           = 5,
                Parent           = TabContainer,
            })

            -- Line
            New("Frame", {
                Size             = UDim2.new(1, -12, 0, 1),
                Position         = UDim2.new(0, 6, 0.5, 0),
                BackgroundColor3 = Theme.SectionLine,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = SFrame,
            })

            if text ~= "" then
                -- White background behind text so line doesn't show through
                local BgFrame = New("Frame", {
                    Size             = UDim2.new(0, 0, 1, 0),
                    AutomaticSize    = Enum.AutomaticSize.X,
                    Position         = UDim2.fromOffset(16, 0),
                    BackgroundColor3 = Theme.Background,
                    BackgroundTransparency = 0,
                    BorderSizePixel  = 0,
                    ZIndex           = 6,
                    Parent           = SFrame,
                }, { Padding(0, 0, 4, 4) })

                local SLabel = Label(text, 11, Theme.TextDim)
                SLabel.Size     = UDim2.new(0, 0, 1, 0)
                SLabel.AutomaticSize = Enum.AutomaticSize.X
                SLabel.ZIndex   = 7
                SLabel.TextTransparency = 0
                SLabel.Parent   = BgFrame
            end
        end

        return Tab
    end

    -- ── Premium Tab ──────────────────────────────────────────
    function Window:AddPremiumTab(cfg)
        cfg = cfg or {}
        local gamepassId = cfg.GamepassId
        assert(gamepassId, "AddPremiumTab: GamepassId required")

        local PremiumTab = self:AddTab({
            Title = cfg.Title or "Premium",
            Icon  = cfg.Icon  or "crown",
        })

        -- State: not verified until checked
        local ownershipVerified = false
        local ownershipResult   = false

        -- Premium gate overlay
        local GateFrame = New("Frame", {
            Size             = UDim2.fromScale(1, 1),
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 0.05,
            ZIndex           = 20,
            Parent           = PremiumTab.Container,
        }, {
            Corner(8),
        })

        -- Gate icon
        New("ImageLabel", {
            Size               = UDim2.fromOffset(40, 40),
            AnchorPoint        = Vector2.new(0.5, 0),
            Position           = UDim2.new(0.5, 0, 0, 30),
            BackgroundTransparency = 1,
            Image              = Icons["lock"] or "rbxassetid://10709791712",
            ImageColor3        = Theme.Accent,
            ZIndex             = 21,
            Parent             = GateFrame,
        })

        local GateTitle = Label("Premium Required", 15, Theme.Text,
            Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold))
        GateTitle.Size     = UDim2.new(1, -20, 0, 22)
        GateTitle.Position = UDim2.new(0, 10, 0, 80)
        GateTitle.ZIndex   = 21
        GateTitle.TextXAlignment = Enum.TextXAlignment.Center
        GateTitle.TextTransparency = 0
        GateTitle.Parent   = GateFrame

        local GateSub = Label("You do not own the required gamepass.", 12, Theme.TextSub)
        GateSub.Size     = UDim2.new(1, -20, 0, 40)
        GateSub.Position = UDim2.new(0, 10, 0, 106)
        GateSub.ZIndex   = 21
        GateSub.TextXAlignment = Enum.TextXAlignment.Center
        GateSub.TextTransparency = 0
        GateSub.TextWrapped = true
        GateSub.Parent   = GateFrame

        -- Buy button
        local BuyBtn = New("TextButton", {
            Size             = UDim2.fromOffset(160, 34),
            AnchorPoint      = Vector2.new(0.5, 0),
            Position         = UDim2.new(0.5, 0, 0, 155),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0,
            Text             = "",
            ZIndex           = 22,
            Parent           = GateFrame,
        }, {
            Corner(8),
            Label("Get Premium", 13, Theme.Text,
                Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
                Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 1),
        })

        -- Make the text visible inside the button
        local BuyLbl = Label("Get Premium", 13, Theme.Text,
            Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
            Enum.TextXAlignment.Center)
        BuyLbl.Size     = UDim2.fromScale(1, 1)
        BuyLbl.ZIndex   = 23
        BuyLbl.TextTransparency = 0
        BuyLbl.Parent   = BuyBtn

        BuyBtn.MouseButton1Click:Connect(function()
            MarketplaceService:PromptGamePassPurchase(LocalPlayer, gamepassId)
        end)

        BuyBtn.MouseEnter:Connect(function()
            QuadTween(BuyBtn, 0.12, { BackgroundColor3 = Theme.AccentLight })
        end)
        BuyBtn.MouseLeave:Connect(function()
            QuadTween(BuyBtn, 0.12, { BackgroundColor3 = Theme.Accent })
        end)

        -- Check ownership
        local function CheckOwnership()
            local ok, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, gamepassId)
            end)
            if ok and owns then
                ownershipVerified = true
                ownershipResult   = true
                -- Hide gate
                QuintTween(GateFrame, 0.3, { BackgroundTransparency = 1 })
                task.delay(0.3, function()
                    GateFrame.Visible = false
                end)
            else
                ownershipVerified = true
                ownershipResult   = false
                GateSub.Text = "You do not own this gamepass.\nPurchase to unlock Premium."
                GateSub.TextTransparency = 0
            end
        end

        task.spawn(CheckOwnership)

        -- Re-check on gamepass purchase
        MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gpId, purchased)
            if player == LocalPlayer and gpId == gamepassId and purchased then
                CheckOwnership()
            end
        end)

        -- Internal: guard function for premium elements
        local function PremiumGuard(cb)
            return function(...)
                -- Double-check on each invocation
                local ok, owns = pcall(function()
                    return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, gamepassId)
                end)
                if ok and owns then
                    ownershipResult = true
                    SafeCallback(cb, ...)
                else
                    ownershipResult = false
                    warn("[AmethystUI] Premium action blocked: gamepass not owned.")
                end
            end
        end

        -- Wrapped add methods that guard callbacks
        local PremiumTabWrapper = setmetatable({}, {
            __index = function(_, key)
                local raw = PremiumTab[key]
                if type(raw) ~= "function" then return raw end
                -- Wrap method
                return function(self2, ...)
                    if not ownershipResult then
                        warn("[AmethystUI] Premium element '" .. tostring(key) .. "' ignored – not owned.")
                        return {}
                    end
                    return raw(PremiumTab, ...)
                end
            end
        })

        -- Provide ungated add that wraps callbacks but still builds UI
        function PremiumTabWrapper:AddButton(cfg2)
            cfg2 = cfg2 or {}
            local origCb = cfg2.Callback
            cfg2.Callback = PremiumGuard(origCb)
            return PremiumTab:AddButton(cfg2)
        end

        function PremiumTabWrapper:AddToggle(id, cfg2)
            cfg2 = cfg2 or {}
            local origCb = cfg2.Callback
            cfg2.Callback = PremiumGuard(origCb)
            return PremiumTab:AddToggle(id, cfg2)
        end

        function PremiumTabWrapper:AddSlider(id, cfg2)
            cfg2 = cfg2 or {}
            local origCb = cfg2.Callback
            cfg2.Callback = PremiumGuard(origCb)
            return PremiumTab:AddSlider(id, cfg2)
        end

        function PremiumTabWrapper:AddParagraph(cfg2)
            return PremiumTab:AddParagraph(cfg2)
        end

        function PremiumTabWrapper:AddLabel(cfg2)
            return PremiumTab:AddLabel(cfg2)
        end

        function PremiumTabWrapper:AddSection(cfg2)
            return PremiumTab:AddSection(cfg2)
        end

        function PremiumTabWrapper:IsOwned()
            return ownershipResult
        end

        return PremiumTabWrapper
    end

    -- ── Destroy ──────────────────────────────────────────────
    function Window:Destroy()
        ScreenGui:Destroy()
    end

    return Window
end

-- ============================================================
-- LIBRARY RETURN
-- ============================================================
AmethystUI.Icons   = Icons
AmethystUI.Theme   = Theme
AmethystUI.Version = "1.0.0"
AmethystUI.Options = {}  -- Populated by Toggle/Slider ids

return AmethystUI


-- ============================================================
-- ============================================================
--
--     ███████╗ █████╗ ███╗   ███╗██████╗ ██╗     ███████╗
--     ██╔════╝██╔══██╗████╗ ████║██╔══██╗██║     ██╔════╝
--     ███████╗███████║██╔████╔██║██████╔╝██║     █████╗
--     ╚════██║██╔══██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝
--     ███████║██║  ██║██║ ╚═╝ ██║██║     ███████╗███████╗
--     ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝
--
--              SAMPLE SCRIPT — COPY & RUN IN EXECUTOR
-- ============================================================
-- ============================================================

--[[

-- ============================================================
-- AMETHYST UI — SAMPLE SCRIPT
-- Load from GitHub and run this to see all features in action.
-- ============================================================

local AmethystUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/AmethystUI.lua"
))()

-- ============================================================
-- CREATE WINDOW
-- ============================================================
local Window = AmethystUI:CreateWindow({
    Title    = "Amethyst Demo",
    SubTitle = "by AmethystUI",
    Width    = 580,
    Height   = 460,
    TabWidth = 148,
})

-- Keep Options reference
local Options = Window.Options

-- ============================================================
-- TAB: MAIN
-- ============================================================
local MainTab = Window:AddTab({
    Title = "Main",
    Icon  = "home",
})

MainTab:AddParagraph({
    Title   = "Welcome",
    Content = "This is AmethystUI — a professional Roblox UI library\nfaithfully matching the Fluent Amethyst theme.",
})

MainTab:AddSection("Actions")

MainTab:AddButton({
    Title       = "Click Me",
    Description = "Prints a message to the output",
    Callback    = function()
        print("[AmethystUI] Button clicked!")
    end,
})

MainTab:AddButton({
    Title    = "Another Button",
    Callback = function()
        print("[AmethystUI] Another button fired!")
    end,
})

MainTab:AddSection("Toggles")

local MyToggle = MainTab:AddToggle("MyToggle", {
    Title       = "God Mode",
    Description = "Enable invincibility",
    Default     = false,
    Callback    = function(value)
        print("[AmethystUI] Toggle =", value)
    end,
})

MyToggle:OnChanged(function(value)
    print("[AmethystUI] Toggle changed externally =", value)
end)

-- Programmatically set after 3 seconds
task.delay(3, function()
    MyToggle:SetValue(true)
end)

MainTab:AddToggle("SpeedToggle", {
    Title    = "Speed Boost",
    Default  = true,
    Callback = function(value)
        print("[AmethystUI] Speed boost =", value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = value and 32 or 16
        end
    end,
})

MainTab:AddSection("Sliders")

local MySlider = MainTab:AddSlider("MySlider", {
    Title       = "Walk Speed",
    Description = "Adjust character walk speed",
    Min         = 4,
    Max         = 200,
    Default     = 16,
    Rounding    = 0,
    Callback    = function(value)
        print("[AmethystUI] Slider =", value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = value
        end
    end,
})

MySlider:OnChanged(function(value)
    print("[AmethystUI] Slider changed =", value)
end)

local JumpSlider = MainTab:AddSlider("JumpPower", {
    Title    = "Jump Power",
    Min      = 7,
    Max      = 250,
    Default  = 50,
    Rounding = 1,
    Callback = function(value)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = value
        end
    end,
})

-- ============================================================
-- TAB: SETTINGS
-- ============================================================
local SettingsTab = Window:AddTab({
    Title = "Settings",
    Icon  = "settings",
})

SettingsTab:AddParagraph({
    Title   = "Configuration",
    Content = "Adjust your preferences here.",
})

SettingsTab:AddSection("Visual")

SettingsTab:AddToggle("UIVisible", {
    Title    = "Show UI",
    Default  = true,
    Callback = function(value)
        print("[AmethystUI] UI Visible =", value)
    end,
})

SettingsTab:AddSlider("Opacity", {
    Title    = "Opacity",
    Min      = 10,
    Max      = 100,
    Default  = 100,
    Rounding = 0,
    Callback = function(value)
        print("[AmethystUI] Opacity =", value)
    end,
})

SettingsTab:AddSection("Info")

SettingsTab:AddLabel({
    Text  = "AmethystUI v1.0.0",
    Color = AmethystUI.Theme.TextDim,
})

-- ============================================================
-- TAB: PREMIUM (Replace 0000000 with your real Gamepass ID)
-- ============================================================
local PremiumTab = Window:AddPremiumTab({
    Title      = "Premium",
    Icon       = "crown",
    GamepassId = 0000000,  -- << REPLACE WITH YOUR GAMEPASS ID
})

-- These elements are guarded by double-checked ownership
PremiumTab:AddParagraph({
    Title   = "Exclusive Features",
    Content = "These features are only available to Premium members.",
})

PremiumTab:AddSection("Premium Actions")

PremiumTab:AddButton({
    Title       = "Premium Button",
    Description = "Only fires if you own the gamepass",
    Callback    = function()
        print("[AmethystUI] Premium Button fired!")
    end,
})

PremiumTab:AddToggle("PremiumToggle", {
    Title       = "Premium Toggle",
    Description = "Exclusive premium toggle",
    Default     = false,
    Callback    = function(value)
        print("[AmethystUI] Premium Toggle =", value)
    end,
})

PremiumTab:AddSlider("PremiumSlider", {
    Title    = "Premium Slider",
    Min      = 0,
    Max      = 10,
    Default  = 5,
    Rounding = 1,
    Callback = function(value)
        print("[AmethystUI] Premium Slider =", value)
    end,
})

-- ============================================================
-- ACCESSING OPTIONS BY ID
-- ============================================================
-- After elements are created with an ID you can access them:
--
--   Options.MyToggle:SetValue(true)
--   Options.MySlider:SetValue(50)
--   print(Options.MyToggle.Value)
--
-- ============================================================

print("[AmethystUI] Sample script loaded successfully!")

]]

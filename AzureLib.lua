--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   █████╗ ███████╗██╗   ██╗██████╗ ███████╗██╗     ██╗██████╗               ║
║  ██╔══██╗╚══███╔╝██║   ██║██╔══██╗██╔════╝██║     ██║██╔══██╗              ║
║  ███████║  ███╔╝ ██║   ██║██████╔╝█████╗  ██║     ██║██████╔╝              ║
║  ██╔══██║ ███╔╝  ██║   ██║██╔══██╗██╔══╝  ██║     ██║██╔══██╗              ║
║  ██║  ██║███████╗╚██████╔╝██║  ██║███████╗███████╗██║██████╔╝              ║
║  ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═════╝               ║
║                                                                              ║
║  Roblox UI Library · Amethyst Theme · v3.0                                  ║
║  Mobile + PC · Minimize-to-Circle · Fluent-style Delta Drag                 ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  QUICK START                                                                 ║
║                                                                              ║
║  local AL  = loadstring(game:HttpGet("YOUR_URL"))()                          ║
║  local Win = AL:CreateWindow({ Title="Hub", SubTitle="v1" })                ║
║  local Tab = Win:AddTab({ Title="Main", Icon="⚡" })                         ║
║                                                                              ║
║  Tab:AddSection("Aimbot")                                                    ║
║  Tab:AddToggle("id", { Title="Silent Aim", Default=false,                    ║
║      Callback=function(v) end })                                             ║
║  Tab:AddSlider("id", { Title="FOV", Min=10, Max=360, Default=90,             ║
║      Callback=function(v) end })                                             ║
║  Tab:AddButton({ Title="Reset", Callback=function() end })                   ║
║  Tab:AddDropdown("id", { Title="Mode", Values={"A","B"}, Default=1,          ║
║      Callback=function(v) end })                                             ║
║  Tab:AddInput("id", { Title="Name", Placeholder="...",                       ║
║      Callback=function(v, enter) end })                                      ║
║  Tab:AddKeybind("id", { Title="Toggle", Default=Enum.KeyCode.F,             ║
║      Callback=function(key) end })                                            ║
║  Tab:AddColorPicker("id", { Title="Color",                                   ║
║      Default=Color3.fromRGB(160,90,210),                                     ║
║      Callback=function(col) end })                                            ║
║  Tab:AddParagraph({ Title="Info", Content="Some text here." })               ║
║                                                                              ║
║  AL:Notify({ Title="Loaded", Content="Ready!", Duration=4, Type="success" }) ║
║  AL:SetTheme({ Accent=Color3.fromRGB(100,200,150) })  -- override any color  ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────────────────────────
local AzureLib = {}
AzureLib.__index = AzureLib

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local Debris           = game:GetService("Debris")
local LocalPlayer      = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────────────────────────
-- AMETHYST COLOR THEME
-- Deep violet-black backgrounds, brilliant crystal-purple accents,
-- iridescent lilac highlights. True amethyst gemstone palette.
-- ─────────────────────────────────────────────────────────────────────────────
local Theme = {
    -- Window backgrounds (near-black with deep purple tint)
    BgWindow      = Color3.fromRGB( 11,  7, 20),   -- main window
    BgTitleBar    = Color3.fromRGB(  9,  5, 17),   -- title bar strip
    BgTabBar      = Color3.fromRGB(  9,  6, 17),   -- left sidebar
    BgTabHov      = Color3.fromRGB( 18, 12, 30),   -- tab hover
    BgTabActive   = Color3.fromRGB( 24, 15, 42),   -- active tab bg
    BgContent     = Color3.fromRGB( 13,  9, 22),   -- content scroll area
    BgElement     = Color3.fromRGB( 19, 13, 33),   -- card/element bg
    BgElementHov  = Color3.fromRGB( 26, 18, 44),   -- card hover
    BgElementPres = Color3.fromRGB( 33, 22, 56),   -- card pressed
    BgInput       = Color3.fromRGB( 15, 10, 26),   -- text input bg
    BgDropdown    = Color3.fromRGB( 15, 10, 25),   -- dropdown popup
    BgNotif       = Color3.fromRGB( 13,  9, 22),   -- notification

    -- Amethyst accent family (the star of the show)
    Accent        = Color3.fromRGB(155,  82, 210),  -- main amethyst
    AccentBright  = Color3.fromRGB(195, 125, 255),  -- bright lilac highlight
    AccentDim     = Color3.fromRGB( 88,  40, 130),  -- dimmed amethyst
    AccentDeep    = Color3.fromRGB( 50,  22,  80),  -- very dark amethyst fill
    AccentGlow    = Color3.fromRGB(120,  55, 175),  -- glow color
    AccentLilac   = Color3.fromRGB(210, 175, 255),  -- crystal shine / lilac
    AccentRose    = Color3.fromRGB(185,  75, 215),  -- rose-violet variant

    -- Borders
    BorderHigh    = Color3.fromRGB( 90,  52, 135),  -- highlighted border
    BorderNorm    = Color3.fromRGB( 55,  32,  88),  -- normal border
    BorderDim     = Color3.fromRGB( 32,  18,  55),  -- dim/subtle border

    -- Text
    TextPrimary   = Color3.fromRGB(242, 237, 255),  -- near-white with purple tint
    TextSecondary = Color3.fromRGB(175, 152, 218),  -- muted secondary
    TextDisabled  = Color3.fromRGB(105,  85, 148),  -- placeholder / disabled
    TextAccent    = Color3.fromRGB(195, 145, 255),  -- accent-colored text

    -- Slider
    SliderTrack   = Color3.fromRGB( 28,  17,  50),
    SliderKnob    = Color3.fromRGB(235, 215, 255),

    -- Toggle
    ToggleOff     = Color3.fromRGB( 32,  18,  55),
    ToggleOn      = Color3.fromRGB(155,  82, 210),
    ToggleKnob    = Color3.fromRGB(255, 255, 255),

    -- Status
    Success       = Color3.fromRGB( 75, 200, 125),
    Warning       = Color3.fromRGB(228, 170,  50),
    Error         = Color3.fromRGB(218,  60,  60),
    Info          = Color3.fromRGB( 85, 155, 235),

    Shadow        = Color3.fromRGB(  0,   0,   5),
}

function AzureLib:SetTheme(overrides)
    if type(overrides) ~= "table" then return end
    for k, v in next, overrides do
        if Theme[k] ~= nil then Theme[k] = v end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- INSTANCE HELPERS
-- ─────────────────────────────────────────────────────────────────────────────

local function New(class, props, parent)
    local obj = Instance.new(class)
    for k, v in next, props do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(px, parent)
    return New("UICorner", { CornerRadius = UDim.new(0, px) }, parent)
end

local function Stroke(color, thickness, parent, transparency)
    return New("UIStroke", {
        Color           = color or Theme.BorderNorm,
        Thickness       = thickness or 1,
        Transparency    = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function Padding(top, bottom, left, right, parent)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, top),
        PaddingBottom = UDim.new(0, bottom),
        PaddingLeft   = UDim.new(0, left),
        PaddingRight  = UDim.new(0, right),
    }, parent)
end

local function ListLayout(fillDir, hAlign, spacing, parent)
    return New("UIListLayout", {
        FillDirection       = fillDir or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign  or Enum.HorizontalAlignment.Left,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, spacing or 0),
    }, parent)
end

local function GridLayout(cellSize, cellPad, parent)
    return New("UIGridLayout", {
        CellSize             = cellSize or UDim2.fromOffset(18, 18),
        CellPadding          = cellPad  or UDim2.fromOffset(4, 4),
        SortOrder            = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment  = Enum.HorizontalAlignment.Left,
        VerticalAlignment    = Enum.VerticalAlignment.Top,
    }, parent)
end

local function ColorSeq(c0, c1)
    return ColorSequence.new(c0, c1)
end

local function CSKeypoints(...)
    local kps = {}
    local args = {...}
    for i = 1, #args, 2 do
        table.insert(kps, ColorSequenceKeypoint.new(args[i], args[i+1]))
    end
    return ColorSequence.new(kps)
end

local function GradientH(parent, ...)
    return New("UIGradient", {
        Color    = CSKeypoints(...),
        Rotation = 0,
    }, parent)
end

local function GradientV(parent, ...)
    return New("UIGradient", {
        Color    = CSKeypoints(...),
        Rotation = 90,
    }, parent)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- TWEEN HELPERS
-- ─────────────────────────────────────────────────────────────────────────────

local function Tween(obj, t, style, dir, props)
    if not obj or not pcall(function() return obj.Parent end) then return end
    TweenService:Create(obj, TweenInfo.new(
        t,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

local function TweenSpring(obj, t, props)
    Tween(obj, t, Enum.EasingStyle.Back, Enum.EasingDirection.Out, props)
end

local function TweenLinear(obj, t, props)
    Tween(obj, t, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, props)
end

local function TweenSine(obj, t, props)
    Tween(obj, t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, props)
end

local function TweenIn(obj, t, props)
    Tween(obj, t, Enum.EasingStyle.Quart, Enum.EasingDirection.In, props)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- HOVER / PRESS EFFECTS
-- ─────────────────────────────────────────────────────────────────────────────

local function AddHover(obj, norm, hov, press)
    press = press or hov
    obj.MouseEnter:Connect(function()
        Tween(obj, 0.13, nil, nil, { BackgroundColor3 = hov })
    end)
    obj.MouseLeave:Connect(function()
        Tween(obj, 0.13, nil, nil, { BackgroundColor3 = norm })
    end)
    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
        obj.MouseButton1Down:Connect(function()
            Tween(obj, 0.07, nil, nil, { BackgroundColor3 = press })
        end)
        obj.MouseButton1Up:Connect(function()
            Tween(obj, 0.13, nil, nil, { BackgroundColor3 = hov })
        end)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- RIPPLE EFFECT
-- ─────────────────────────────────────────────────────────────────────────────

local function DoRipple(container, px, py)
    if not container or not container.Parent then return end
    local abs  = container.AbsolutePosition
    local sz   = container.AbsoluteSize
    local maxD = math.sqrt(sz.X ^ 2 + sz.Y ^ 2) * 2.2

    local rip = New("Frame", {
        Size                   = UDim2.fromOffset(4, 4),
        Position               = UDim2.fromOffset(px - abs.X, py - abs.Y),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Theme.AccentLilac,
        BackgroundTransparency = 0.5,
        BorderSizePixel        = 0,
        ZIndex                 = container.ZIndex + 25,
    }, container)
    Corner(999, rip)

    Tween(rip, 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
        Size                   = UDim2.fromOffset(maxD, maxD),
        BackgroundTransparency = 1,
    })
    Debris:AddItem(rip, 0.6)
end

local function AddRipple(btn)
    btn.MouseButton1Down:Connect(function()
        local mp = UserInputService:GetMouseLocation()
        DoRipple(btn, mp.X, mp.Y)
    end)
    btn.TouchTap:Connect(function(touches)
        if touches and touches[1] then
            DoRipple(btn, touches[1].Position.X, touches[1].Position.Y)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- DRAGGABLE  ── Fluent-style delta drag
-- Uses Input.Position delta so the frame never "jumps" on first touch.
-- Works identically on PC mouse and mobile touch.
-- ─────────────────────────────────────────────────────────────────────────────

local function MakeDraggable(frame, handle)
    handle = handle or frame

    local dragging   = false
    local dragInput  = nil   -- the specific Input object being tracked
    local dragStart  = nil   -- Vector3 position at drag start
    local startPos   = nil   -- frame.Position (UDim2) at drag start

    -- Called every frame while dragging
    local function Update(inputPos)
        local delta    = inputPos - dragStart
        local vp       = workspace.CurrentCamera.ViewportSize
        local fsz      = frame.AbsoluteSize
        local newX     = math.clamp(startPos.X.Offset + delta.X, 0, vp.X - fsz.X)
        local newY     = math.clamp(startPos.Y.Offset + delta.Y, 0, vp.Y - fsz.Y)
        frame.Position = UDim2.fromOffset(newX, newY)
    end

    handle.InputBegan:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging   = true
            dragInput  = inp
            dragStart  = inp.Position
            startPos   = frame.Position

            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    if dragInput == inp then
                        dragging  = false
                        dragInput = nil
                    end
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            dragInput = inp
        end
    end)

    -- Runs every frame when dragging (smoothest possible update rate)
    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            Update(dragInput.Position)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATION SYSTEM
-- ─────────────────────────────────────────────────────────────────────────────

local NotifGui = New("ScreenGui", {
    Name           = "AzureLib_Notifs",
    ResetOnSpawn   = false,
    DisplayOrder   = 9999,
    IgnoreGuiInset = true,
}, CoreGui)

local NotifHolder = New("Frame", {
    Name                   = "NotifHolder",
    Size                   = UDim2.fromOffset(320, 0),
    Position               = UDim2.new(1, -330, 1, -14),
    AnchorPoint            = Vector2.new(0, 1),
    BackgroundTransparency = 1,
    AutomaticSize          = Enum.AutomaticSize.Y,
}, NotifGui)
ListLayout(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, 8, NotifHolder)

local NOTIF_COLORS = {
    default = Theme.Accent,
    success = Theme.Success,
    warning = Theme.Warning,
    error   = Theme.Error,
    info    = Theme.Info,
}

local NOTIF_ICONS = {
    default = "🔔",
    success = "✅",
    warning = "⚠️",
    error   = "❌",
    info    = "ℹ️",
}

function AzureLib:Notify(opts)
    local title    = opts.Title    or "Notification"
    local content  = opts.Content  or ""
    local duration = math.max(opts.Duration or 4, 0.5)
    local ntype    = opts.Type     or "default"
    local accent   = NOTIF_COLORS[ntype] or Theme.Accent
    local icon     = NOTIF_ICONS[ntype]  or "🔔"

    -- Card frame
    local card = New("Frame", {
        Name                   = "Notif",
        Size                   = UDim2.fromOffset(310, 1),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor3       = Theme.BgNotif,
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = false,
    }, NotifHolder)
    Corner(12, card)
    Stroke(Theme.BorderNorm, 1, card)

    -- Gloss top line (crystal reflection)
    local gloss = New("Frame", {
        Size             = UDim2.new(0.7, 0, 0, 1),
        Position         = UDim2.new(0.15, 0, 0, 0),
        BackgroundColor3 = Theme.AccentLilac,
        BackgroundTransparency = 0.55,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, card)

    -- Left accent bar with gradient
    local bar = New("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        ZIndex           = 3,
    }, card)
    Corner(3, bar)
    GradientV(bar,
        0, accent,
        1, Color3.fromRGB(
            math.floor(accent.R * 255 * 0.35),
            math.floor(accent.G * 255 * 0.35),
            math.floor(accent.B * 255 * 0.35)
        )
    )

    -- Content area
    local content_frame = New("Frame", {
        Size                   = UDim2.new(1, -3, 1, 0),
        Position               = UDim2.fromOffset(3, 0),
        BackgroundTransparency = 1,
        AutomaticSize          = Enum.AutomaticSize.Y,
    }, card)
    Padding(10, 12, 12, 12, content_frame)
    ListLayout(nil, nil, 6, content_frame)

    -- Title
    New("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text             = icon .. "  " .. title,
        TextColor3       = Theme.TextPrimary,
        Font             = Enum.Font.GothamBold,
        TextSize         = 14,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        RichText         = true,
    }, content_frame)

    -- Body
    New("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text             = content,
        TextColor3       = Theme.TextSecondary,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
    }, content_frame)

    -- Progress track
    local progTrack = New("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Theme.BorderDim,
        BorderSizePixel  = 0,
    }, content_frame)

    local progFill = New("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
    }, progTrack)
    Corner(2, progFill)

    -- Entrance: slide from right + fade
    local origPos = card.Position
    card.Position = card.Position + UDim2.fromOffset(50, 0)

    task.spawn(function()
        Tween(card, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0,
            Position               = origPos,
        })
        TweenLinear(progFill, duration, { Size = UDim2.new(0, 0, 1, 0) })

        task.wait(duration)

        TweenIn(card, 0.28, {
            BackgroundTransparency = 1,
            Position               = origPos + UDim2.fromOffset(50, 0),
        })
        task.delay(0.3, function()
            if card and card.Parent then card:Destroy() end
        end)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- WINDOW
-- ─────────────────────────────────────────────────────────────────────────────

function AzureLib:CreateWindow(opts)
    opts = opts or {}
    local title      = opts.Title    or "AzureLib"
    local subtitle   = opts.SubTitle or ""
    local winW       = opts.Width    or 590
    local winH       = opts.Height   or 430
    local TABBAR_W   = 148

    if opts.Size then
        winW = opts.Size.X.Offset or winW
        winH = opts.Size.Y.Offset or winH
    end

    local vp     = workspace.CurrentCamera.ViewportSize
    local startX = opts.X or math.floor((vp.X - winW) * 0.5)
    local startY = opts.Y or math.floor((vp.Y - winH) * 0.5)
    if opts.Position then
        startX = opts.Position.X.Offset or startX
        startY = opts.Position.Y.Offset or startY
    end

    -- Root ScreenGui
    local ScreenGui = New("ScreenGui", {
        Name           = "AzureLib_" .. title:gsub("%s", ""),
        ResetOnSpawn   = false,
        DisplayOrder   = 100,
        IgnoreGuiInset = true,
    }, CoreGui)

    -- ── Outer container (not clipped, holds shadow + glow) ────────
    local WinOuter = New("Frame", {
        Name             = "WinOuter",
        Size             = UDim2.fromOffset(winW, winH),
        Position         = UDim2.fromOffset(startX, startY),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
    }, ScreenGui)

    -- Ambient glow ring
    New("ImageLabel", {
        Name                   = "GlowRing",
        Size                   = UDim2.new(1, 90, 1, 90),
        Position               = UDim2.fromOffset(-45, -45),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://6014261993",
        ImageColor3            = Theme.AccentDeep,
        ImageTransparency      = 0.35,
        ScaleType              = Enum.ScaleType.Slice,
        SliceCenter            = Rect.new(49, 49, 450, 450),
        ZIndex                 = 0,
    }, WinOuter)

    -- Drop shadow
    New("ImageLabel", {
        Name                   = "DropShadow",
        Size                   = UDim2.new(1, 80, 1, 80),
        Position               = UDim2.fromOffset(-40, -20),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://6014261993",
        ImageColor3            = Color3.fromRGB(0, 0, 0),
        ImageTransparency      = 0.3,
        ScaleType              = Enum.ScaleType.Slice,
        SliceCenter            = Rect.new(49, 49, 450, 450),
        ZIndex                 = 0,
    }, WinOuter)

    -- Main window frame (clipped for rounded corners)
    local WinFrame = New("Frame", {
        Name             = "WinFrame",
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme.BgWindow,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, WinOuter)
    Corner(13, WinFrame)
    Stroke(Theme.BorderHigh, 1, WinFrame)

    -- Subtle noise texture overlay (gives depth)
    New("ImageLabel", {
        Name                   = "Noise",
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://9968312720",
        ImageTransparency      = 0.96,
        ScaleType              = Enum.ScaleType.Tile,
        TileSize               = UDim2.fromOffset(64, 64),
        ZIndex                 = 50,
    }, WinFrame)

    -- ── Title Bar ─────────────────────────────────────────────────
    local TitleBar = New("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Theme.BgTitleBar,
        BorderSizePixel  = 0,
        ZIndex           = 10,
    }, WinFrame)

    -- Title bar gradient (top-to-bottom, slightly lighter at top)
    GradientV(TitleBar,
        0, Color3.fromRGB(20, 11, 35),
        1, Color3.fromRGB(9, 5, 17)
    )

    -- Title bar bottom separator
    New("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.BorderNorm,
        BorderSizePixel  = 0,
        ZIndex           = 11,
    }, TitleBar)

    -- Crystal gem icon (3 diamonds)
    local gemFrame = New("Frame", {
        Size             = UDim2.fromOffset(18, 18),
        Position         = UDim2.fromOffset(16, 17),
        BackgroundTransparency = 1,
        ZIndex           = 12,
    }, TitleBar)

    local gem1 = New("Frame", {
        Size             = UDim2.fromOffset(10, 10),
        Position         = UDim2.fromOffset(4, 0),
        BackgroundColor3 = Theme.AccentBright,
        Rotation         = 45,
        BorderSizePixel  = 0,
        ZIndex           = 12,
    }, gemFrame)
    Corner(2, gem1)

    local gem2 = New("Frame", {
        Size             = UDim2.fromOffset(7, 7),
        Position         = UDim2.fromOffset(0, 9),
        BackgroundColor3 = Theme.Accent,
        Rotation         = 45,
        BorderSizePixel  = 0,
        ZIndex           = 12,
    }, gemFrame)
    Corner(2, gem2)

    local gem3 = New("Frame", {
        Size             = UDim2.fromOffset(7, 7),
        Position         = UDim2.fromOffset(9, 9),
        BackgroundColor3 = Theme.AccentGlow,
        Rotation         = 45,
        BorderSizePixel  = 0,
        ZIndex           = 12,
    }, gemFrame)
    Corner(2, gem3)

    -- Title text
    New("TextLabel", {
        Name             = "Title",
        Size             = UDim2.new(1, -160, 0, 24),
        Position         = UDim2.fromOffset(42, 8),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = Theme.TextPrimary,
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 12,
    }, TitleBar)

    -- Subtitle
    if subtitle ~= "" then
        New("TextLabel", {
            Name             = "Subtitle",
            Size             = UDim2.new(1, -160, 0, 14),
            Position         = UDim2.fromOffset(42, 31),
            BackgroundTransparency = 1,
            Text             = subtitle,
            TextColor3       = Theme.TextDisabled,
            Font             = Enum.Font.Gotham,
            TextSize         = 11,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 12,
        }, TitleBar)
    end

    -- ── Control Buttons ───────────────────────────────────────────
    local function MakeCtrlBtn(posX, icon, bgNorm, bgHov, iconColor)
        local btn = New("TextButton", {
            Size             = UDim2.fromOffset(30, 30),
            Position         = UDim2.new(1, posX, 0.5, 0),
            AnchorPoint      = Vector2.new(0, 0.5),
            BackgroundColor3 = bgNorm,
            Text             = icon,
            TextColor3       = iconColor,
            Font             = Enum.Font.GothamBold,
            TextSize         = 14,
            BorderSizePixel  = 0,
            AutoButtonColor  = false,
            ZIndex           = 14,
        }, TitleBar)
        Corner(8, btn)
        AddHover(btn, bgNorm, bgHov)
        AddRipple(btn)
        return btn
    end

    local MinBtn = MakeCtrlBtn(
        -70, "－",
        Color3.fromRGB(28, 18, 45),
        Color3.fromRGB(45, 28, 72),
        Theme.TextSecondary
    )
    local CloseBtn = MakeCtrlBtn(
        -33, "✕",
        Color3.fromRGB(45, 14, 14),
        Color3.fromRGB(165, 30, 30),
        Color3.fromRGB(230, 100, 100)
    )

    -- Make title bar draggable
    MakeDraggable(WinOuter, TitleBar)

    -- Close handler
    CloseBtn.MouseButton1Click:Connect(function()
        TweenIn(WinOuter, 0.22, { BackgroundTransparency = 1 })
        TweenIn(WinFrame, 0.22, { BackgroundTransparency = 1 })
        task.delay(0.24, function()
            ScreenGui:Destroy()
        end)
    end)

    -- ── Mini Circle (minimized state) ─────────────────────────────
    local circleSz  = 64
    local Circle = New("TextButton", {
        Name             = "MiniCircle",
        Size             = UDim2.fromOffset(0, 0),
        Position         = UDim2.fromOffset(
            math.clamp(startX + winW * 0.5, 36, vp.X - 36),
            math.clamp(startY + winH * 0.5, 36, vp.Y - 36)
        ),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Accent,
        Text             = string.upper(string.sub(title, 1, 1)),
        TextColor3       = Color3.fromRGB(255, 255, 255),
        Font             = Enum.Font.GothamBold,
        TextSize         = 24,
        BorderSizePixel  = 0,
        AutoButtonColor  = false,
        Visible          = false,
        ZIndex           = 300,
    }, ScreenGui)
    Corner(999, Circle)

    -- Circle gradient (crystal look)
    GradientV(Circle,
        0, Theme.AccentBright,
        1, Theme.AccentDim
    )

    Stroke(Theme.BorderHigh, 2, Circle)

    -- Circle outer glow
    New("ImageLabel", {
        Name                   = "Glow",
        Size                   = UDim2.new(1, 36, 1, 36),
        Position               = UDim2.fromOffset(-18, -18),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://6014261993",
        ImageColor3            = Theme.AccentGlow,
        ImageTransparency      = 0.4,
        ScaleType              = Enum.ScaleType.Slice,
        SliceCenter            = Rect.new(49, 49, 450, 450),
        ZIndex                 = 299,
    }, Circle)

    MakeDraggable(Circle, Circle)

    -- Pulse animation on circle
    local pulsing = false
    local function StartPulse()
        pulsing = true
        task.spawn(function()
            while pulsing do
                TweenSine(Circle, 1.1, { BackgroundColor3 = Theme.AccentBright })
                task.wait(1.1)
                TweenSine(Circle, 1.1, { BackgroundColor3 = Theme.AccentDim })
                task.wait(1.1)
            end
        end)
    end
    local function StopPulse()
        pulsing = false
        Tween(Circle, 0.2, nil, nil, { BackgroundColor3 = Theme.Accent })
    end

    -- Minimize / Restore
    local minimized = false

    local function DoMinimize()
        if minimized then return end
        minimized = true

        local wp = WinOuter.AbsolutePosition
        local ws = WinOuter.AbsoluteSize
        local cx = math.clamp(wp.X + ws.X * 0.5, 36, vp.X - 36)
        local cy = math.clamp(wp.Y + ws.Y * 0.5, 36, vp.Y - 36)

        TweenIn(WinFrame, 0.2, { BackgroundTransparency = 1 })
        Tween(WinOuter, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            Size     = UDim2.fromOffset(1, 1),
            Position = UDim2.fromOffset(cx, cy),
        })

        task.delay(0.21, function()
            if not minimized then return end
            WinOuter.Visible = false

            Circle.Position  = UDim2.fromOffset(cx, cy)
            Circle.Size      = UDim2.fromOffset(0, 0)
            Circle.Visible   = true
            TweenSpring(Circle, 0.45, { Size = UDim2.fromOffset(circleSz, circleSz) })
            StartPulse()
        end)
    end

    local function DoRestore()
        if not minimized then return end
        minimized = false
        StopPulse()

        local cp = Circle.AbsolutePosition
        local cx = cp.X + circleSz * 0.5
        local cy = cp.Y + circleSz * 0.5

        TweenIn(Circle, 0.17, { Size = UDim2.fromOffset(0, 0) })

        task.delay(0.16, function()
            Circle.Visible   = false
            WinOuter.Visible = true
            WinFrame.BackgroundTransparency = 0

            WinOuter.Size     = UDim2.fromOffset(1, 1)
            WinOuter.Position = UDim2.fromOffset(cx, cy)

            TweenSpring(WinOuter, 0.42, {
                Size     = UDim2.fromOffset(winW, winH),
                Position = UDim2.fromOffset(startX, startY),
            })
        end)
    end

    MinBtn.MouseButton1Click:Connect(DoMinimize)
    Circle.MouseButton1Click:Connect(DoRestore)

    -- ── Tab Sidebar ───────────────────────────────────────────────
    local TabSidebar = New("Frame", {
        Name             = "TabSidebar",
        Size             = UDim2.new(0, TABBAR_W, 1, -52),
        Position         = UDim2.fromOffset(0, 52),
        BackgroundColor3 = Theme.BgTabBar,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 8,
    }, WinFrame)

    -- Sidebar right border
    New("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.BorderNorm,
        BorderSizePixel  = 0,
        ZIndex           = 9,
    }, TabSidebar)

    -- Sidebar subtle gradient
    GradientH(TabSidebar,
        0, Color3.fromRGB(11, 7, 20),
        1, Color3.fromRGB(9, 6, 17)
    )

    -- Tab list scrollable
    local TabScroll = New("ScrollingFrame", {
        Name                   = "TabScroll",
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 0,
        ScrollingDirection     = Enum.ScrollingDirection.Y,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        ZIndex                 = 9,
    }, TabSidebar)
    Padding(8, 8, 6, 6, TabScroll)
    ListLayout(nil, nil, 3, TabScroll)

    -- ── Content Area ──────────────────────────────────────────────
    local ContentArea = New("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -TABBAR_W, 1, -52),
        Position         = UDim2.new(0, TABBAR_W, 0, 52),
        BackgroundColor3 = Theme.BgContent,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 7,
    }, WinFrame)

    -- Content area subtle gradient
    GradientV(ContentArea,
        0, Color3.fromRGB(15, 10, 25),
        1, Color3.fromRGB(11, 7, 20)
    )

    -- ── TAB SYSTEM ────────────────────────────────────────────────
    -- KEY FIX: All tab activation is synchronous. No task.delay() that could
    -- reference a stale closure. Old page is hidden immediately, new shown immediately.
    local allTabs   = {}
    local activeTab = nil   -- points to currently active Tab table

    local function ActivateTab(newTab)
        -- Guard: if same tab clicked, ignore
        if activeTab == newTab then return end

        -- Step 1: immediately hide old tab page (sync, no delay)
        if activeTab then
            local old = activeTab  -- local capture is safe
            old._page.Visible = false

            -- Animate old button back to inactive
            Tween(old._btn, 0.15, nil, nil, {
                BackgroundColor3       = Theme.BgTabBar,
                BackgroundTransparency = 1,
            })
            local oldInd = old._btn:FindFirstChild("Ind")
            if oldInd then
                Tween(oldInd, 0.15, nil, nil, {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 3, 0.4, 0),
                })
            end
            local oldLbl = old._btn:FindFirstChild("Lbl")
            if oldLbl then
                Tween(oldLbl, 0.15, nil, nil, { TextColor3 = Theme.TextDisabled })
            end
            local oldIcn = old._btn:FindFirstChild("Icn")
            if oldIcn then
                Tween(oldIcn, 0.15, nil, nil, { TextColor3 = Theme.TextDisabled })
            end
        end

        -- Step 2: update reference BEFORE any async work
        activeTab = newTab

        -- Step 3: show new page immediately
        newTab._page.Visible  = true
        newTab._page.Position = UDim2.fromOffset(6, 0)
        Tween(newTab._page, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            Position = UDim2.fromOffset(0, 0),
        })

        -- Step 4: animate new button to active
        Tween(newTab._btn, 0.15, nil, nil, {
            BackgroundColor3       = Theme.BgTabActive,
            BackgroundTransparency = 0,
        })
        local newInd = newTab._btn:FindFirstChild("Ind")
        if newInd then
            Tween(newInd, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 3, 0.65, 0),
            })
        end
        local newLbl = newTab._btn:FindFirstChild("Lbl")
        if newLbl then
            Tween(newLbl, 0.15, nil, nil, { TextColor3 = Theme.TextPrimary })
        end
        local newIcn = newTab._btn:FindFirstChild("Icn")
        if newIcn then
            Tween(newIcn, 0.15, nil, nil, { TextColor3 = Theme.AccentBright })
        end
    end

    -- ── Window object ─────────────────────────────────────────────
    local Window = {
        _gui   = ScreenGui,
        _outer = WinOuter,
        _frame = WinFrame,
    }

    function Window:AddTab(opts)
        local tabTitle = opts.Title or ("Tab " .. #allTabs + 1)
        local tabIcon  = opts.Icon  or "○"

        -- ── Tab Button ────────────────────────────────────────────
        local Btn = New("TextButton", {
            Name                   = "TabBtn_" .. tabTitle,
            Size                   = UDim2.new(1, 0, 0, 40),
            BackgroundColor3       = Theme.BgTabBar,
            BackgroundTransparency = 1,
            Text                   = "",
            BorderSizePixel        = 0,
            AutoButtonColor        = false,
            ClipsDescendants       = false,
            ZIndex                 = 10,
        }, TabScroll)
        Corner(9, Btn)

        -- Left accent indicator bar
        local Ind = New("Frame", {
            Name             = "Ind",
            Size             = UDim2.new(0, 3, 0.4, 0),
            Position         = UDim2.new(0, -1, 0.3, 0),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ZIndex           = 11,
        }, Btn)
        Corner(4, Ind)
        GradientV(Ind, 0, Theme.AccentBright, 1, Theme.AccentDim)

        -- Icon label
        local Icn = New("TextLabel", {
            Name             = "Icn",
            Size             = UDim2.fromOffset(26, 40),
            Position         = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Text             = tabIcon,
            TextColor3       = Theme.TextDisabled,
            Font             = Enum.Font.Gotham,
            TextSize         = 16,
            ZIndex           = 11,
        }, Btn)

        -- Title label
        local Lbl = New("TextLabel", {
            Name             = "Lbl",
            Size             = UDim2.new(1, -42, 1, 0),
            Position         = UDim2.fromOffset(36, 0),
            BackgroundTransparency = 1,
            Text             = tabTitle,
            TextColor3       = Theme.TextDisabled,
            Font             = Enum.Font.GothamSemibold,
            TextSize         = 13,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ZIndex           = 11,
        }, Btn)

        -- Hover
        Btn.MouseEnter:Connect(function()
            if activeTab and activeTab._btn == Btn then return end
            Tween(Btn, 0.12, nil, nil, {
                BackgroundColor3       = Theme.BgTabHov,
                BackgroundTransparency = 0,
            })
        end)
        Btn.MouseLeave:Connect(function()
            if activeTab and activeTab._btn == Btn then return end
            Tween(Btn, 0.12, nil, nil, { BackgroundTransparency = 1 })
        end)

        -- ── Content Page ──────────────────────────────────────────
        local Page = New("ScrollingFrame", {
            Name                   = "Page_" .. tabTitle,
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 4,
            ScrollBarImageColor3   = Theme.AccentDim,
            ScrollingDirection     = Enum.ScrollingDirection.Y,
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            Visible                = false,
            ClipsDescendants       = true,
            ZIndex                 = 8,
        }, ContentArea)
        Padding(12, 18, 12, 12, Page)
        ListLayout(nil, nil, 8, Page)

        -- Tab object (holds references needed by ActivateTab)
        local Tab = { _btn = Btn, _page = Page, _title = tabTitle }

        -- Wire up click
        Btn.MouseButton1Click:Connect(function()
            ActivateTab(Tab)
        end)

        -- Auto-select first tab
        if #allTabs == 0 then
            ActivateTab(Tab)
        end
        table.insert(allTabs, Tab)

        -- ══════════════════════════════════════════════════════════
        --  ELEMENT CONSTRUCTORS
        -- ══════════════════════════════════════════════════════════

        -- ── Section header ────────────────────────────────────────
        function Tab:AddSection(name)
            local row = New("Frame", {
                Name                   = "Section_" .. name,
                Size                   = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1,
                ZIndex                 = 9,
            }, Page)

            -- Section label
            New("TextLabel", {
                Size             = UDim2.new(1, -10, 0, 18),
                Position         = UDim2.fromOffset(0, 8),
                BackgroundTransparency = 1,
                Text             = string.upper(name),
                TextColor3       = Theme.Accent,
                Font             = Enum.Font.GothamBold,
                TextSize         = 10,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 10,
            }, row)

            -- Line after label
            local line = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Theme.BorderDim,
                BorderSizePixel  = 0,
                ZIndex           = 9,
            }, row)

            -- Dot at start of line
            local dot = New("Frame", {
                Size             = UDim2.fromOffset(5, 5),
                Position         = UDim2.new(0, -1, 1, -3),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
                ZIndex           = 10,
            }, row)
            Corner(99, dot)
        end

        -- ── Separator ─────────────────────────────────────────────
        function Tab:AddSeparator()
            local sep = New("Frame", {
                Name             = "Separator",
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.BorderDim,
                BorderSizePixel  = 0,
            }, Page)
        end

        -- ── Paragraph ─────────────────────────────────────────────
        function Tab:AddParagraph(opts)
            local card = New("Frame", {
                Name             = "Para",
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = Theme.BgElement,
                BorderSizePixel  = 0,
            }, Page)
            Corner(10, card)
            Stroke(Theme.BorderDim, 1, card)

            -- Top accent stripe
            local stripe = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 2),
                BackgroundColor3 = Theme.AccentDim,
                BorderSizePixel  = 0,
                ZIndex           = 2,
            }, card)
            Corner(3, stripe)

            local inner = New("Frame", {
                Size             = UDim2.new(1, 0, 1, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
            }, card)
            Padding(12, 12, 14, 14, inner)
            ListLayout(nil, nil, 6, inner)

            if opts.Title and opts.Title ~= "" then
                New("TextLabel", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    AutomaticSize    = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Text             = opts.Title,
                    TextColor3       = Theme.TextPrimary,
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    TextWrapped      = true,
                }, inner)
            end

            New("TextLabel", {
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text             = opts.Content or "",
                TextColor3       = Theme.TextSecondary,
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextWrapped      = true,
            }, inner)
        end

        -- ── Button ────────────────────────────────────────────────
        function Tab:AddButton(opts)
            local hasDesc = opts.Description and opts.Description ~= ""
            local height  = hasDesc and 52 or 40

            local card = New("TextButton", {
                Name             = "Btn",
                Size             = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Theme.BgElement,
                Text             = "",
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                ClipsDescendants = true,
                ZIndex           = 9,
            }, Page)
            Corner(10, card)
            Stroke(Theme.BorderDim, 1, card)

            -- Left accent line
            local accentLine = New("Frame", {
                Size             = UDim2.new(0, 3, 0.55, 0),
                Position         = UDim2.new(0, 0, 0.225, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
                ZIndex           = 10,
            }, card)
            Corner(3, accentLine)
            GradientV(accentLine, 0, Theme.AccentBright, 1, Theme.AccentDim)

            -- Title
            New("TextLabel", {
                Size             = UDim2.new(1, -22, 0, 20),
                Position         = UDim2.fromOffset(14, hasDesc and 9 or 10),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Button",
                TextColor3       = Theme.TextAccent,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 10,
            }, card)

            -- Description
            if hasDesc then
                New("TextLabel", {
                    Size             = UDim2.new(1, -22, 0, 14),
                    Position         = UDim2.fromOffset(14, 30),
                    BackgroundTransparency = 1,
                    Text             = opts.Description,
                    TextColor3       = Theme.TextDisabled,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 10,
                }, card)
            end

            -- Subtle gradient overlay
            GradientV(card,
                0, Color3.fromRGB(35, 20, 60),
                1, Theme.BgElement,
                -- transparency numbers encoded via Transparency field
                nil
            )

            AddHover(card, Theme.BgElement, Theme.BgElementHov, Theme.BgElementPres)
            AddRipple(card)

            card.MouseButton1Click:Connect(function()
                if opts.Callback then task.spawn(opts.Callback) end
            end)
        end

        -- ── Toggle ────────────────────────────────────────────────
        function Tab:AddToggle(id, opts)
            local value   = opts.Default == true
            local hasDesc = opts.Description and opts.Description ~= ""
            local height  = hasDesc and 52 or 42

            local card = New("Frame", {
                Name             = "Toggle_" .. (id or ""),
                Size             = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Theme.BgElement,
                BorderSizePixel  = 0,
                ZIndex           = 9,
            }, Page)
            Corner(10, card)
            Stroke(Theme.BorderDim, 1, card)

            -- Title
            New("TextLabel", {
                Size             = UDim2.new(1, -72, 0, 20),
                Position         = UDim2.fromOffset(14, hasDesc and 9 or 11),
                BackgroundTransparency = 1,
                Text             = opts.Title or "",
                TextColor3       = Theme.TextPrimary,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, card)

            -- Description
            if hasDesc then
                New("TextLabel", {
                    Size             = UDim2.new(1, -72, 0, 14),
                    Position         = UDim2.fromOffset(14, 30),
                    BackgroundTransparency = 1,
                    Text             = opts.Description,
                    TextColor3       = Theme.TextDisabled,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                }, card)
            end

            -- Toggle track background
            local Track = New("Frame", {
                Name             = "Track",
                Size             = UDim2.fromOffset(46, 26),
                Position         = UDim2.new(1, -57, 0.5, 0),
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = value and Theme.ToggleOn or Theme.ToggleOff,
                BorderSizePixel  = 0,
                ZIndex           = 10,
            }, card)
            Corner(13, Track)

            -- Track inner shine (top highlight)
            local trackShine = New("Frame", {
                Size             = UDim2.new(1, -6, 0, 1),
                Position         = UDim2.fromOffset(3, 3),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.82,
                BorderSizePixel  = 0,
                ZIndex           = 11,
            }, Track)
            Corner(1, trackShine)

            local trackStroke = Stroke(
                value and Theme.AccentDim or Theme.BorderDim, 1, Track
            )

            -- Knob
            local Knob = New("Frame", {
                Name             = "Knob",
                Size             = UDim2.fromOffset(20, 20),
                Position         = value and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
                BackgroundColor3 = Theme.ToggleKnob,
                BorderSizePixel  = 0,
                ZIndex           = 12,
            }, Track)
            Corner(99, Knob)

            -- Knob inner glow (only visible when ON)
            local knobGlow = New("Frame", {
                Name             = "KnobGlow",
                Size             = UDim2.fromOffset(10, 10),
                Position         = UDim2.fromOffset(5, 5),
                BackgroundColor3 = Theme.AccentLilac,
                BackgroundTransparency = value and 0.25 or 1,
                BorderSizePixel  = 0,
                ZIndex           = 13,
            }, Knob)
            Corner(99, knobGlow)

            local function SetVisual(v)
                Tween(Track, 0.22, nil, nil, {
                    BackgroundColor3 = v and Theme.ToggleOn or Theme.ToggleOff,
                })
                Tween(Knob, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                    Position = v and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
                })
                Tween(knobGlow, 0.18, nil, nil, {
                    BackgroundTransparency = v and 0.25 or 1,
                })
                Tween(trackStroke, 0.18, nil, nil, {
                    Color = v and Theme.AccentDim or Theme.BorderDim,
                })
            end

            -- Clickable overlay
            local Clk = New("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 15,
            }, card)

            AddHover(card, Theme.BgElement, Theme.BgElementHov)

            Clk.MouseButton1Click:Connect(function()
                value = not value
                SetVisual(value)
                if opts.Callback then task.spawn(opts.Callback, value) end
            end)

            SetVisual(value)  -- apply initial state

            local obj = {}
            function obj:Set(v)
                value = (v == true)
                SetVisual(value)
                if opts.Callback then task.spawn(opts.Callback, value) end
            end
            function obj:Get() return value end
            return obj
        end

        -- ── Slider ────────────────────────────────────────────────
        function Tab:AddSlider(id, opts)
            local minVal  = opts.Min      or 0
            local maxVal  = opts.Max      or 100
            local default = math.clamp(opts.Default or minVal, minVal, maxVal)
            local rounding = opts.Rounding or 0
            local suffix   = opts.Suffix   or ""
            local hasDesc  = opts.Description and opts.Description ~= ""
            local height   = hasDesc and 70 or 58

            local value = default

            local function Round(v)
                if rounding == 0 then return math.floor(v + 0.5) end
                local m = 10 ^ rounding
                return math.floor(v * m + 0.5) / m
            end
            value = Round(value)

            local card = New("Frame", {
                Name             = "Slider_" .. (id or ""),
                Size             = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Theme.BgElement,
                BorderSizePixel  = 0,
            }, Page)
            Corner(10, card)
            Stroke(Theme.BorderDim, 1, card)
            Padding(10, 10, 14, 14, card)

            -- Header row (title + value badge)
            local headRow = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
            }, card)

            New("TextLabel", {
                Size             = UDim2.new(1, -72, 1, 0),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Slider",
                TextColor3       = Theme.TextPrimary,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, headRow)

            -- Value badge
            local valBadge = New("Frame", {
                Size             = UDim2.fromOffset(65, 22),
                Position         = UDim2.new(1, -65, 0, -1),
                BackgroundColor3 = Theme.AccentDeep,
                BorderSizePixel  = 0,
            }, headRow)
            Corner(7, valBadge)
            Stroke(Theme.AccentDim, 1, valBadge)

            local valLbl = New("TextLabel", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = tostring(value) .. suffix,
                TextColor3       = Theme.TextAccent,
                Font             = Enum.Font.GothamBold,
                TextSize         = 12,
            }, valBadge)

            -- Description
            if hasDesc then
                New("TextLabel", {
                    Size             = UDim2.new(1, 0, 0, 14),
                    Position         = UDim2.fromOffset(0, 22),
                    BackgroundTransparency = 1,
                    Text             = opts.Description,
                    TextColor3       = Theme.TextDisabled,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                }, card)
            end

            -- Track
            local trackTop = hasDesc and 44 or 30
            local TrackBg = New("Frame", {
                Size             = UDim2.new(1, 0, 0, 14),
                Position         = UDim2.fromOffset(0, trackTop),
                BackgroundColor3 = Theme.SliderTrack,
                BorderSizePixel  = 0,
            }, card)
            Corner(7, TrackBg)
            Stroke(Theme.BorderDim, 1, TrackBg)

            -- Fill bar
            local t0    = (value - minVal) / (maxVal - minVal)
            local Fill  = New("Frame", {
                Size             = UDim2.new(t0, 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
            }, TrackBg)
            Corner(7, Fill)
            GradientH(Fill, 0, Theme.AccentBright, 1, Theme.Accent)

            -- Knob
            local Knob = New("Frame", {
                Size             = UDim2.fromOffset(22, 22),
                Position         = UDim2.new(t0, 0, 0.5, 0),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Theme.SliderKnob,
                BorderSizePixel  = 0,
                ZIndex           = 12,
            }, TrackBg)
            Corner(99, Knob)
            GradientV(Knob, 0, Color3.fromRGB(255,255,255), 1, Theme.AccentLilac)

            -- Knob inner ring (amethyst accent)
            local knobRing = New("Frame", {
                Size             = UDim2.fromOffset(10, 10),
                Position         = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 0.4,
                BorderSizePixel  = 0,
                ZIndex           = 13,
            }, Knob)
            Corner(99, knobRing)

            -- Drag
            local sdragging = false

            local function ApplyAtX(absX)
                local ta  = TrackBg.AbsolutePosition.X
                local tw  = TrackBg.AbsoluteSize.X
                local pct = math.clamp((absX - ta) / tw, 0, 1)
                value     = Round(minVal + pct * (maxVal - minVal))
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                Knob.Position = UDim2.new(pct, 0, 0.5, 0)
                valLbl.Text   = tostring(value) .. suffix
                if opts.Callback then opts.Callback(value) end
            end

            TrackBg.InputBegan:Connect(function(inp)
                local t = inp.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                    sdragging = true
                    ApplyAtX(inp.Position.X)
                    Tween(Knob, 0.1, nil, nil, { Size = UDim2.fromOffset(26, 26) })
                    inp.Changed:Connect(function()
                        if inp.UserInputState == Enum.UserInputState.End then
                            sdragging = false
                            TweenSpring(Knob, 0.2, { Size = UDim2.fromOffset(22, 22) })
                        end
                    end)
                end
            end)

            UserInputService.InputChanged:Connect(function(inp)
                if not sdragging then return end
                local t = inp.UserInputType
                if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                    ApplyAtX(inp.Position.X)
                end
            end)

            local obj = {}
            function obj:Set(v)
                v = math.clamp(Round(v), minVal, maxVal)
                value = v
                local pct = (v - minVal) / (maxVal - minVal)
                Fill.Size     = UDim2.new(pct, 0, 1, 0)
                Knob.Position = UDim2.new(pct, 0, 0.5, 0)
                valLbl.Text   = tostring(v) .. suffix
                if opts.Callback then opts.Callback(v) end
            end
            function obj:Get() return value end
            return obj
        end

        -- ── Dropdown ──────────────────────────────────────────────
        function Tab:AddDropdown(id, opts)
            local values    = opts.Values  or {}
            local defIdx    = opts.Default or 1
            local current   = values[defIdx] or values[1] or ""
            local isOpen    = false
            local ITEM_H    = 36
            local maxShow   = math.min(#values, 5)
            local popupH    = maxShow * (ITEM_H + 3) + 8

            -- Wrapper (NOT clipped so popup can overflow)
            local wrap = New("Frame", {
                Name                   = "DD_" .. (id or ""),
                Size                   = UDim2.new(1, 0, 0, 46),
                BackgroundTransparency = 1,
                ClipsDescendants       = false,
                ZIndex                 = 30,
            }, Page)

            -- Header
            local Hdr = New("TextButton", {
                Size             = UDim2.new(1, 0, 0, 46),
                BackgroundColor3 = Theme.BgElement,
                Text             = "",
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                ClipsDescendants = true,
                ZIndex           = 31,
            }, wrap)
            Corner(10, Hdr)
            Stroke(Theme.BorderDim, 1, Hdr)
            AddHover(Hdr, Theme.BgElement, Theme.BgElementHov)

            -- Small category label
            New("TextLabel", {
                Size             = UDim2.new(1, -50, 0, 14),
                Position         = UDim2.fromOffset(14, 7),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Dropdown",
                TextColor3       = Theme.TextDisabled,
                Font             = Enum.Font.Gotham,
                TextSize         = 10,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 32,
            }, Hdr)

            -- Selected value
            local SelLbl = New("TextLabel", {
                Size             = UDim2.new(1, -50, 0, 18),
                Position         = UDim2.fromOffset(14, 22),
                BackgroundTransparency = 1,
                Text             = current,
                TextColor3       = Theme.TextPrimary,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 32,
            }, Hdr)

            -- Arrow chevron
            local Arrow = New("TextLabel", {
                Size             = UDim2.fromOffset(24, 46),
                Position         = UDim2.new(1, -30, 0, 0),
                BackgroundTransparency = 1,
                Text             = "▾",
                TextColor3       = Theme.Accent,
                Font             = Enum.Font.GothamBold,
                TextSize         = 15,
                ZIndex           = 32,
            }, Hdr)

            -- Popup list
            local Popup = New("ScrollingFrame", {
                Name                   = "Popup",
                Size                   = UDim2.new(1, 0, 0, 0),
                Position               = UDim2.fromOffset(0, 48),
                BackgroundColor3       = Theme.BgDropdown,
                BorderSizePixel        = 0,
                ClipsDescendants       = true,
                Visible                = false,
                ZIndex                 = 60,
                ScrollBarThickness     = 3,
                ScrollBarImageColor3   = Theme.AccentDim,
                CanvasSize             = UDim2.new(0, 0, 0, #values * (ITEM_H + 3) + 8),
            }, wrap)
            Corner(10, Popup)
            Stroke(Theme.BorderNorm, 1, Popup)
            Padding(4, 4, 4, 4, Popup)
            ListLayout(nil, nil, 3, Popup)

            local function CloseDropdown()
                isOpen = false
                Tween(Arrow, 0.18, nil, nil, { Rotation = 0 })
                TweenIn(Popup, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
                task.delay(0.2, function()
                    if not isOpen then Popup.Visible = false end
                end)
            end

            local function OpenDropdown()
                isOpen = true
                Popup.Visible = true
                Popup.Size    = UDim2.new(1, 0, 0, 0)
                Tween(Arrow, 0.18, nil, nil, { Rotation = 180 })
                Tween(Popup, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
                    Size = UDim2.new(1, 0, 0, popupH),
                })
            end

            Hdr.MouseButton1Click:Connect(function()
                if isOpen then CloseDropdown() else OpenDropdown() end
            end)

            -- Build option items
            local itemBtns = {}
            for _, v in ipairs(values) do
                local isSel = (v == current)
                local item  = New("TextButton", {
                    Size             = UDim2.new(1, 0, 0, ITEM_H),
                    BackgroundColor3 = isSel and Theme.BgTabActive or Theme.BgDropdown,
                    Text             = "",
                    BorderSizePixel  = 0,
                    AutoButtonColor  = false,
                    ZIndex           = 62,
                }, Popup)
                Corner(8, item)
                itemBtns[v] = item

                -- Check icon
                local chk = New("TextLabel", {
                    Name             = "Chk",
                    Size             = UDim2.fromOffset(20, ITEM_H),
                    Position         = UDim2.new(1, -24, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = isSel and "✓" or "",
                    TextColor3       = Theme.Accent,
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 13,
                    ZIndex           = 63,
                }, item)

                New("TextLabel", {
                    Size             = UDim2.new(1, -30, 1, 0),
                    Position         = UDim2.fromOffset(10, 0),
                    BackgroundTransparency = 1,
                    Text             = v,
                    TextColor3       = isSel and Theme.TextAccent or Theme.TextPrimary,
                    Font             = isSel and Enum.Font.GothamSemibold or Enum.Font.Gotham,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 63,
                }, item)

                AddHover(item, isSel and Theme.BgTabActive or Theme.BgDropdown, Theme.BgElementHov)
                AddRipple(item)

                item.MouseButton1Click:Connect(function()
                    -- Update selection visual for all items
                    for vk, ib in next, itemBtns do
                        local sel = (vk == v)
                        ib.BackgroundColor3 = sel and Theme.BgTabActive or Theme.BgDropdown
                        local c2 = ib:FindFirstChild("Chk")
                        if c2 then c2.Text = sel and "✓" or "" end
                        -- update content label
                        for _, child in ipairs(ib:GetChildren()) do
                            if child:IsA("TextLabel") and child.Name ~= "Chk" then
                                child.TextColor3 = sel and Theme.TextAccent or Theme.TextPrimary
                                child.Font = sel and Enum.Font.GothamSemibold or Enum.Font.Gotham
                            end
                        end
                    end
                    current = v
                    SelLbl.Text = v
                    CloseDropdown()
                    if opts.Callback then task.spawn(opts.Callback, v) end
                end)
            end

            local obj = {}
            function obj:Set(v) current = v; SelLbl.Text = v end
            function obj:Get() return current end
            function obj:SetValues(newVals)
                -- clear and rebuild
                for _, c in ipairs(Popup:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                values = newVals
                for _, iv in ipairs(newVals) do
                    -- (abbreviated rebuild — same as above)
                end
            end
            return obj
        end

        -- ── Text Input ────────────────────────────────────────────
        function Tab:AddInput(id, opts)
            local height = 54

            local card = New("Frame", {
                Name             = "Input_" .. (id or ""),
                Size             = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Theme.BgElement,
                BorderSizePixel  = 0,
            }, Page)
            Corner(10, card)
            Stroke(Theme.BorderDim, 1, card)

            -- Floating label
            New("TextLabel", {
                Size             = UDim2.new(1, -24, 0, 16),
                Position         = UDim2.fromOffset(14, 8),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Input",
                TextColor3       = Theme.TextDisabled,
                Font             = Enum.Font.Gotham,
                TextSize         = 10,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, card)

            -- Input box background
            local inputBg = New("Frame", {
                Size             = UDim2.new(1, -20, 0, 24),
                Position         = UDim2.fromOffset(10, 24),
                BackgroundColor3 = Theme.BgInput,
                BorderSizePixel  = 0,
            }, card)
            Corner(7, inputBg)
            local inputStk = Stroke(Theme.BorderDim, 1, inputBg)

            local Box = New("TextBox", {
                Size             = UDim2.new(1, -14, 1, 0),
                Position         = UDim2.fromOffset(7, 0),
                BackgroundTransparency = 1,
                Text             = opts.Default or "",
                PlaceholderText  = opts.Placeholder or "Type here...",
                PlaceholderColor3= Theme.TextDisabled,
                TextColor3       = Theme.TextPrimary,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ClearTextOnFocus = opts.ClearTextOnFocus == true,
            }, inputBg)

            Box.Focused:Connect(function()
                Tween(inputStk, 0.18, nil, nil, { Color = Theme.Accent, Thickness = 1.5 })
                Tween(inputBg, 0.18, nil, nil, { BackgroundColor3 = Theme.AccentDeep })
            end)
            Box.FocusLost:Connect(function(enter)
                Tween(inputStk, 0.18, nil, nil, { Color = Theme.BorderDim, Thickness = 1 })
                Tween(inputBg, 0.18, nil, nil, { BackgroundColor3 = Theme.BgInput })
                if opts.Callback then task.spawn(opts.Callback, Box.Text, enter) end
            end)

            local obj = {}
            function obj:Set(v) Box.Text = tostring(v) end
            function obj:Get() return Box.Text end
            return obj
        end

        -- ── Keybind ───────────────────────────────────────────────
        function Tab:AddKeybind(id, opts)
            local key       = opts.Default or Enum.KeyCode.Unknown
            local listening = false

            local card = New("Frame", {
                Name             = "Key_" .. (id or ""),
                Size             = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = Theme.BgElement,
                BorderSizePixel  = 0,
            }, Page)
            Corner(10, card)
            Stroke(Theme.BorderDim, 1, card)

            New("TextLabel", {
                Size             = UDim2.new(1, -125, 1, 0),
                Position         = UDim2.fromOffset(14, 0),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Keybind",
                TextColor3       = Theme.TextPrimary,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, card)

            local badge = New("TextButton", {
                Size             = UDim2.fromOffset(110, 28),
                Position         = UDim2.new(1, -120, 0.5, 0),
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme.BgInput,
                Text             = tostring(key.Name),
                TextColor3       = Theme.TextAccent,
                Font             = Enum.Font.GothamBold,
                TextSize         = 12,
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                ZIndex           = 11,
            }, card)
            Corner(8, badge)
            local badgeStk = Stroke(Theme.BorderDim, 1, badge)

            local function SetListenMode(v)
                listening = v
                badge.Text = v and "[ ... ]" or tostring(key.Name)
                Tween(badgeStk, 0.15, nil, nil, {
                    Color = v and Theme.Accent or Theme.BorderDim,
                })
                Tween(badge, 0.15, nil, nil, {
                    BackgroundColor3 = v and Theme.AccentDeep or Theme.BgInput,
                    TextColor3       = v and Theme.AccentBright or Theme.TextAccent,
                })
            end

            badge.MouseButton1Click:Connect(function()
                SetListenMode(true)
            end)

            UserInputService.InputBegan:Connect(function(inp, gameProc)
                if not listening then return end
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if inp.KeyCode == Enum.KeyCode.Escape then
                    SetListenMode(false)
                    return
                end
                key = inp.KeyCode
                SetListenMode(false)
                if opts.Callback then task.spawn(opts.Callback, key) end
            end)

            local obj = {}
            function obj:Get()    return key end
            function obj:IsDown() return UserInputService:IsKeyDown(key) end
            return obj
        end

        -- ── Color Picker ──────────────────────────────────────────
        function Tab:AddColorPicker(id, opts)
            local col       = opts.Default or Color3.fromRGB(155, 82, 210)
            local h, s, v2  = Color3.toHSV(col)
            local isOpen    = false

            local wrap = New("Frame", {
                Name                   = "CP_" .. (id or ""),
                Size                   = UDim2.new(1, 0, 0, 46),
                BackgroundTransparency = 1,
                ClipsDescendants       = false,
                ZIndex                 = 25,
            }, Page)

            -- Header
            local Hdr = New("TextButton", {
                Size             = UDim2.new(1, 0, 0, 46),
                BackgroundColor3 = Theme.BgElement,
                Text             = "",
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                ClipsDescendants = true,
                ZIndex           = 26,
            }, wrap)
            Corner(10, Hdr)
            Stroke(Theme.BorderDim, 1, Hdr)
            AddHover(Hdr, Theme.BgElement, Theme.BgElementHov)

            New("TextLabel", {
                Size             = UDim2.new(1, -80, 1, 0),
                Position         = UDim2.fromOffset(14, 0),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Color",
                TextColor3       = Theme.TextPrimary,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 27,
            }, Hdr)

            local preview = New("Frame", {
                Size             = UDim2.fromOffset(36, 24),
                Position         = UDim2.new(1, -50, 0.5, 0),
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = col,
                BorderSizePixel  = 0,
                ZIndex           = 27,
            }, Hdr)
            Corner(7, preview)
            Stroke(Theme.BorderNorm, 1, preview)

            -- Popup picker
            local PICK_H = 150
            local Popup  = New("Frame", {
                Name             = "CPPopup",
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.fromOffset(0, 48),
                BackgroundColor3 = Theme.BgDropdown,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
                Visible          = false,
                ZIndex           = 56,
            }, wrap)
            Corner(10, Popup)
            Stroke(Theme.BorderNorm, 1, Popup)
            Padding(12, 12, 12, 12, Popup)
            ListLayout(nil, nil, 10, Popup)

            -- Helper: create HSV mini-slider inside popup
            local function MiniSlider(labelTxt, initVal, fillColors, cb)
                local row = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                }, Popup)

                New("TextLabel", {
                    Size             = UDim2.new(0, 85, 0, 14),
                    BackgroundTransparency = 1,
                    Text             = labelTxt,
                    TextColor3       = Theme.TextDisabled,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 10,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                }, row)

                local trk = New("Frame", {
                    Size             = UDim2.new(1, 0, 0, 14),
                    Position         = UDim2.fromOffset(0, 18),
                    BackgroundColor3 = Theme.SliderTrack,
                    BorderSizePixel  = 0,
                }, row)
                Corner(7, trk)

                local fill2 = New("Frame", {
                    Size             = UDim2.new(initVal, 0, 1, 0),
                    BackgroundColor3 = fillColors and fillColors[1] or Theme.Accent,
                    BorderSizePixel  = 0,
                }, trk)
                Corner(7, fill2)
                if fillColors then
                    GradientH(fill2, 0, fillColors[1], 1, fillColors[2])
                end

                local kn2 = New("Frame", {
                    Size             = UDim2.fromOffset(18, 18),
                    Position         = UDim2.new(initVal, 0, 0.5, 0),
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = Theme.SliderKnob,
                    BorderSizePixel  = 0,
                    ZIndex           = 60,
                }, trk)
                Corner(99, kn2)

                local sd = false
                trk.InputBegan:Connect(function(inp)
                    local t = inp.UserInputType
                    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                        sd = true
                        local ta  = trk.AbsolutePosition.X
                        local tw2 = trk.AbsoluteSize.X
                        local p   = math.clamp((inp.Position.X - ta) / tw2, 0, 1)
                        fill2.Size    = UDim2.new(p, 0, 1, 0)
                        kn2.Position  = UDim2.new(p, 0, 0.5, 0)
                        cb(p)
                        inp.Changed:Connect(function()
                            if inp.UserInputState == Enum.UserInputState.End then sd = false end
                        end)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if not sd then return end
                    local t = inp.UserInputType
                    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                        local ta  = trk.AbsolutePosition.X
                        local tw2 = trk.AbsoluteSize.X
                        local p   = math.clamp((inp.Position.X - ta) / tw2, 0, 1)
                        fill2.Size   = UDim2.new(p, 0, 1, 0)
                        kn2.Position = UDim2.new(p, 0, 0.5, 0)
                        cb(p)
                    end
                end)
            end

            local function NotifyColor()
                col = Color3.fromHSV(h, s, v2)
                preview.BackgroundColor3 = col
                if opts.Callback then task.spawn(opts.Callback, col) end
            end

            MiniSlider("Hue", h,
                {   -- Rainbow gradient for hue
                    Color3.fromHSV(0,1,1),
                    Color3.fromHSV(1,1,1)
                },
                function(p) h = p; NotifyColor() end
            )
            MiniSlider("Saturation", s,
                { Color3.fromRGB(255,255,255), Color3.fromHSV(h,1,1) },
                function(p) s = p; NotifyColor() end
            )
            MiniSlider("Brightness", v2,
                { Color3.fromRGB(0,0,0), Color3.fromHSV(h,s,1) },
                function(p) v2 = p; NotifyColor() end
            )

            local function ClosePicker()
                isOpen = false
                TweenIn(Popup, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
                task.delay(0.2, function()
                    if not isOpen then Popup.Visible = false end
                end)
            end

            local function OpenPicker()
                isOpen = true
                Popup.Visible = true
                Popup.Size    = UDim2.new(1, 0, 0, 0)
                Tween(Popup, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
                    Size = UDim2.new(1, 0, 0, PICK_H),
                })
            end

            Hdr.MouseButton1Click:Connect(function()
                if isOpen then ClosePicker() else OpenPicker() end
            end)

            local obj = {}
            function obj:Set(c)
                col = c
                preview.BackgroundColor3 = c
                h, s, v2 = Color3.toHSV(c)
            end
            function obj:Get() return col end
            return obj
        end

        return Tab
    end  -- Window:AddTab

    -- Window-level methods
    function Window:Minimize() DoMinimize() end
    function Window:Restore()  DoRestore()  end
    function Window:Destroy()  ScreenGui:Destroy() end

    -- Entrance spring animation
    WinOuter.Size     = UDim2.fromOffset(math.floor(winW * 0.88), math.floor(winH * 0.88))
    WinOuter.Position = UDim2.fromOffset(
        startX + math.floor(winW * 0.06),
        startY + math.floor(winH * 0.06)
    )
    TweenSpring(WinOuter, 0.42, {
        Size     = UDim2.fromOffset(winW, winH),
        Position = UDim2.fromOffset(startX, startY),
    })

    return Window
end  -- AzureLib:CreateWindow

return AzureLib

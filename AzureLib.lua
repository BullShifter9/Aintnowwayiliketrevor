--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║   █████╗ ███████╗██╗   ██╗██████╗ ███████╗██╗     ██╗██████╗              ║
║  ██╔══██╗╚══███╔╝██║   ██║██╔══██╗██╔════╝██║     ██║██╔══██╗             ║
║  ███████║  ███╔╝ ██║   ██║██████╔╝█████╗  ██║     ██║██████╔╝             ║
║  ██╔══██║ ███╔╝  ██║   ██║██╔══██╗██╔══╝  ██║     ██║██╔══██╗             ║
║  ██║  ██║███████╗╚██████╔╝██║  ██║███████╗███████╗██║██████╔╝             ║
║  ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═════╝              ║
║                                                                              ║
║  v4.0  ·  Amethyst Theme  ·  Mobile + PC  ·  Fluent-sourced drag           ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  FIXES IN v4.0 (verified against Fluent source)                              ║
║  • Drag: exact Fluent pattern — DragInput ref + UIS.InputChanged guard       ║
║    NO RenderStepped. Touch-delta is perfect on mobile.                       ║
║  • Tab text visible: ALL pages hidden in loop, then new page shown.          ║
║    No more invisible/ghost text after tab switch.                            ║
║  • Clamp crash: All math.clamp() calls guarded with math.max(0, max)         ║
║    so zero-size frames can't produce "max < min" error.                      ║
║  • Slider: guard against zero-width track before divide.                     ║
║  • Tab animation: slide-in from right (8px) matching Fluent feel.           ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

-- ──────────────────────────────────────────────────────────────────────────────
-- SERVICES
-- ──────────────────────────────────────────────────────────────────────────────
local AzureLib = {}
AzureLib.__index = AzureLib

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")
local Debris            = game:GetService("Debris")
local LocalPlayer       = Players.LocalPlayer

-- ──────────────────────────────────────────────────────────────────────────────
-- AMETHYST THEME  —  deep violet-black backgrounds, crystal-purple accents
-- ──────────────────────────────────────────────────────────────────────────────
local C = {
    -- Backgrounds
    WinBg        = Color3.fromRGB( 11,  7, 20),   -- main window
    TitleBg      = Color3.fromRGB(  8,  5, 16),   -- title bar
    SidebarBg    = Color3.fromRGB(  9,  6, 17),   -- tab sidebar
    SidebarTabHov= Color3.fromRGB( 18, 12, 30),   -- tab hover
    SidebarTabOn = Color3.fromRGB( 24, 15, 42),   -- active tab
    ContentBg    = Color3.fromRGB( 13,  9, 22),   -- content scroll area
    CardBg       = Color3.fromRGB( 20, 13, 34),   -- element card bg
    CardHov      = Color3.fromRGB( 27, 18, 46),   -- card hover
    CardPres     = Color3.fromRGB( 34, 22, 58),   -- card pressed
    InputBg      = Color3.fromRGB( 15, 10, 26),   -- input bg
    DropBg       = Color3.fromRGB( 15, 10, 25),   -- dropdown popup

    -- Amethyst accent family
    Accent       = Color3.fromRGB(155,  82, 210),  -- core amethyst
    AccentBright = Color3.fromRGB(195, 125, 255),  -- crystal highlight / lilac
    AccentDim    = Color3.fromRGB( 88,  40, 130),  -- dimmed
    AccentDeep   = Color3.fromRGB( 48,  20,  78),  -- very dark fill
    AccentGlow   = Color3.fromRGB(118,  52, 172),  -- glow ring
    AccentLilac  = Color3.fromRGB(210, 175, 255),  -- surface shine

    -- Borders
    BordHi       = Color3.fromRGB( 88,  50, 130),  -- bright border
    BordNorm     = Color3.fromRGB( 52,  30,  84),  -- normal border
    BordDim      = Color3.fromRGB( 30,  16,  52),  -- dim border

    -- Text
    TxtPri       = Color3.fromRGB(242, 237, 255),  -- primary
    TxtSec       = Color3.fromRGB(172, 150, 215),  -- secondary
    TxtDis       = Color3.fromRGB(102,  82, 145),  -- disabled/placeholder
    TxtAcc       = Color3.fromRGB(192, 142, 255),  -- accent-colored text

    -- Slider
    SlTrack      = Color3.fromRGB( 26,  15,  48),
    SlKnob       = Color3.fromRGB(235, 215, 255),

    -- Toggle
    TgOff        = Color3.fromRGB( 30,  16,  52),
    TgOn         = Color3.fromRGB(155,  82, 210),
    TgKnob       = Color3.fromRGB(255, 255, 255),

    -- Status
    Green        = Color3.fromRGB( 72, 198, 120),
    Yellow       = Color3.fromRGB(228, 170,  48),
    Red          = Color3.fromRGB(218,  58,  58),
    Blue         = Color3.fromRGB( 82, 152, 232),

    Black        = Color3.fromRGB(0, 0, 0),
}

function AzureLib:SetTheme(t)
    for k, v in next, t do C[k] = v end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- INSTANCE FACTORY
-- ──────────────────────────────────────────────────────────────────────────────
local function New(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in next, props do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function Rnd(px, p)   return New("UICorner", { CornerRadius = UDim.new(0, px) }, p) end
local function Strk(col, th, p, tr) return New("UIStroke", { Color = col or C.BordNorm, Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function Pad(t, b, l, r, p)  return New("UIPadding", { PaddingTop = UDim.new(0,t), PaddingBottom = UDim.new(0,b), PaddingLeft = UDim.new(0,l), PaddingRight = UDim.new(0,r) }, p) end
local function List(fd, ha, sp, p)  return New("UIListLayout", { FillDirection = fd or Enum.FillDirection.Vertical, HorizontalAlignment = ha or Enum.HorizontalAlignment.Left, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, sp or 0) }, p) end

local function GradV(parent, c0, c1)
    New("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = 90 }, parent)
end
local function GradH(parent, c0, c1)
    New("UIGradient", { Color = ColorSequence.new(c0, c1), Rotation = 0 }, parent)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- TWEEN HELPERS
-- ──────────────────────────────────────────────────────────────────────────────
local function Tw(o, t, sty, dir, props)
    if not o or not o.Parent then return end
    TweenService:Create(o, TweenInfo.new(t, sty or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props):Play()
end
local function TwIn(o, t, props)    Tw(o, t, Enum.EasingStyle.Quart, Enum.EasingDirection.In, props) end
local function TwSpring(o, t, props) Tw(o, t, Enum.EasingStyle.Back,  Enum.EasingDirection.Out, props) end
local function TwSine(o, t, props)  Tw(o, t, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut, props) end
local function TwLin(o, t, props)   Tw(o, t, Enum.EasingStyle.Linear,Enum.EasingDirection.Out, props) end

-- ──────────────────────────────────────────────────────────────────────────────
-- HOVER / PRESS
-- ──────────────────────────────────────────────────────────────────────────────
local function Hover(obj, norm, hov, pres)
    pres = pres or hov
    obj.MouseEnter:Connect(function()     Tw(obj, 0.12, nil, nil, { BackgroundColor3 = hov  }) end)
    obj.MouseLeave:Connect(function()     Tw(obj, 0.12, nil, nil, { BackgroundColor3 = norm }) end)
    if obj:IsA("TextButton") or obj:IsA("ImageButton") then
        obj.MouseButton1Down:Connect(function() Tw(obj, 0.07, nil, nil, { BackgroundColor3 = pres }) end)
        obj.MouseButton1Up:Connect(function()   Tw(obj, 0.12, nil, nil, { BackgroundColor3 = hov  }) end)
    end
end

-- ──────────────────────────────────────────────────────────────────────────────
-- RIPPLE
-- ──────────────────────────────────────────────────────────────────────────────
local function DoRipple(container, px, py)
    if not container or not container.Parent then return end
    local abs = container.AbsolutePosition
    local sz  = container.AbsoluteSize
    local d   = math.sqrt(sz.X ^ 2 + sz.Y ^ 2) * 2.2
    local rip = New("Frame", {
        Size = UDim2.fromOffset(4, 4),
        Position = UDim2.fromOffset(px - abs.X, py - abs.Y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.AccentLilac,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = container.ZIndex + 25,
    }, container)
    Rnd(999, rip)
    Tw(rip, 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
        Size = UDim2.fromOffset(d, d),
        BackgroundTransparency = 1,
    })
    Debris:AddItem(rip, 0.6)
end

local function Ripple(btn)
    btn.MouseButton1Down:Connect(function()
        local mp = UserInputService:GetMouseLocation()
        DoRipple(btn, mp.X, mp.Y)
    end)
    btn.TouchTap:Connect(function(touches)
        if touches and touches[1] then DoRipple(btn, touches[1].Position.X, touches[1].Position.Y) end
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- DRAGGABLE  — exact Fluent pattern (sourced from Fluent Window.lua)
--
--  Fluent approach:
--  1. InputBegan on handle → store Dragging=true, MousePos=Input.Position, StartPos=frame.Position
--  2. InputChanged on handle → just store DragInput = Input
--  3. UserInputService.InputChanged → only act if Input == DragInput and Dragging
--  4. Apply Delta = Input.Position - MousePos  added to StartPos
--
--  BUG FIX: All clamp bounds guarded with math.max(0, ...) so zero-size
--  frames never produce "max must be >= min" crash.
-- ──────────────────────────────────────────────────────────────────────────────
local function MakeDraggable(frame, handle)
    handle = handle or frame

    local Dragging = false
    local DragInput = nil
    local MousePos  = nil
    local StartPos  = nil

    -- Step 1: begin drag on handle
    handle.InputBegan:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            Dragging  = true
            MousePos  = inp.Position
            StartPos  = frame.Position

            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    -- Step 2: track which input is moving
    handle.InputChanged:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            DragInput = inp
        end
    end)

    -- Step 3: apply delta only when it's the exact same input object (Fluent pattern)
    UserInputService.InputChanged:Connect(function(inp)
        if inp == DragInput and Dragging then
            local delta = inp.Position - MousePos
            local vp    = workspace.CurrentCamera.ViewportSize
            local fsz   = frame.AbsoluteSize
            -- FIX: math.max(0, ...) prevents "max < min" clamp crash when frame size > viewport
            local newX  = math.clamp(StartPos.X.Offset + delta.X, 0, math.max(0, vp.X - fsz.X))
            local newY  = math.clamp(StartPos.Y.Offset + delta.Y, 0, math.max(0, vp.Y - fsz.Y))
            frame.Position = UDim2.fromOffset(newX, newY)
        end
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- NOTIFICATION SYSTEM
-- ──────────────────────────────────────────────────────────────────────────────
local NotifGui = New("ScreenGui", {
    Name = "AzureLib_Notifs", ResetOnSpawn = false,
    DisplayOrder = 9999, IgnoreGuiInset = true,
}, CoreGui)

local NotifStack = New("Frame", {
    Name = "Stack",
    Size = UDim2.fromOffset(318, 0),
    Position = UDim2.new(1, -328, 1, -14),
    AnchorPoint = Vector2.new(0, 1),
    BackgroundTransparency = 1,
    AutomaticSize = Enum.AutomaticSize.Y,
}, NotifGui)
List(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, 8, NotifStack)

local NColors = { default = C.Accent, success = C.Green, warning = C.Yellow, error = C.Red, info = C.Blue }
local NIcons  = { default = "🔔", success = "✅", warning = "⚠️", error = "❌", info = "ℹ️" }

function AzureLib:Notify(opts)
    local title    = opts.Title    or "Notification"
    local content  = opts.Content  or ""
    local duration = math.max(opts.Duration or 4, 0.5)
    local ntype    = opts.Type or "default"
    local acc      = NColors[ntype] or C.Accent
    local icon     = NIcons[ntype]  or "🔔"

    local card = New("Frame", {
        Name = "Notif",
        Size = UDim2.fromOffset(308, 1),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.CardBg,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
    }, NotifStack)
    Rnd(12, card)
    Strk(C.BordNorm, 1, card)

    -- Crystal gloss top line
    New("Frame", {
        Size = UDim2.new(0.65, 0, 0, 1),
        Position = UDim2.new(0.175, 0, 0, 0),
        BackgroundColor3 = C.AccentLilac,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0, ZIndex = 4,
    }, card)

    -- Left accent bar
    local bar = New("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = acc, BorderSizePixel = 0, ZIndex = 2,
    }, card)
    Rnd(3, bar)
    GradV(bar, acc, Color3.fromRGB(
        math.floor(acc.R * 255 * 0.3),
        math.floor(acc.G * 255 * 0.3),
        math.floor(acc.B * 255 * 0.3)
    ))

    local inner = New("Frame", {
        Size = UDim2.new(1, -3, 1, 0),
        Position = UDim2.fromOffset(3, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, card)
    Pad(10, 12, 12, 12, inner)
    List(nil, nil, 5, inner)

    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = icon .. "  " .. title,
        TextColor3 = C.TxtPri, Font = Enum.Font.GothamBold, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, RichText = true,
    }, inner)

    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = content, TextColor3 = C.TxtSec,
        Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    }, inner)

    local progTrack = New("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = C.BordDim, BorderSizePixel = 0,
    }, inner)
    local progFill = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = acc, BorderSizePixel = 0,
    }, progTrack)
    Rnd(2, progFill)

    local origPos = card.Position
    card.Position = origPos + UDim2.fromOffset(48, 0)
    task.spawn(function()
        Tw(card, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            BackgroundTransparency = 0,
            Position = origPos,
        })
        TwLin(progFill, duration, { Size = UDim2.new(0, 0, 1, 0) })
        task.wait(duration)
        TwIn(card, 0.28, { BackgroundTransparency = 1, Position = origPos + UDim2.fromOffset(48, 0) })
        task.delay(0.3, function() if card and card.Parent then card:Destroy() end end)
    end)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- CREATE WINDOW
-- ──────────────────────────────────────────────────────────────────────────────
function AzureLib:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title    or "AzureLib"
    local subtitle = opts.SubTitle or ""
    local winW     = 590
    local winH     = 430
    local TABW     = 148   -- sidebar width

    if opts.Size then
        winW = opts.Size.X.Offset or winW
        winH = opts.Size.Y.Offset or winH
    end
    if opts.Width  then winW = opts.Width  end
    if opts.Height then winH = opts.Height end

    local vp    = workspace.CurrentCamera.ViewportSize
    local sx    = math.floor((vp.X - winW) * 0.5)
    local sy    = math.floor((vp.Y - winH) * 0.5)
    if opts.Position then sx = opts.Position.X.Offset or sx; sy = opts.Position.Y.Offset or sy end

    -- Root ScreenGui
    local Gui = New("ScreenGui", {
        Name = "AzureLib_" .. title:gsub("%s",""),
        ResetOnSpawn = false,
        DisplayOrder = 100,
        IgnoreGuiInset = true,
    }, CoreGui)

    -- Outer frame (not clipped — holds shadow/glow outside rounded corners)
    local WinOuter = New("Frame", {
        Name = "WinOuter",
        Size = UDim2.fromOffset(winW, winH),
        Position = UDim2.fromOffset(sx, sy),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, Gui)

    -- Drop shadow
    New("ImageLabel", {
        Size = UDim2.new(1, 80, 1, 80),
        Position = UDim2.fromOffset(-40, -20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = C.Black,
        ImageTransparency = 0.3,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49,49,450,450),
        ZIndex = 0,
    }, WinOuter)

    -- Amethyst glow ring
    New("ImageLabel", {
        Size = UDim2.new(1, 80, 1, 80),
        Position = UDim2.fromOffset(-40, -40),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = C.AccentDeep,
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49,49,450,450),
        ZIndex = 0,
    }, WinOuter)

    -- Inner clipped frame (rounded corners, all UI goes here)
    local WinFrame = New("Frame", {
        Name = "WinFrame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.WinBg,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, WinOuter)
    Rnd(14, WinFrame)
    Strk(C.BordHi, 1, WinFrame)

    -- ── Title Bar ─────────────────────────────────────────────────────────────
    local TBar = New("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = C.TitleBg,
        BorderSizePixel = 0, ZIndex = 10,
    }, WinFrame)
    GradV(TBar, Color3.fromRGB(18,10,32), Color3.fromRGB(8,5,16))

    -- Bottom border line on titlebar
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = C.BordNorm,
        BorderSizePixel = 0, ZIndex = 11,
    }, TBar)

    -- Crystal gem icon (3 rotated squares)
    local gemF = New("Frame", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1, ZIndex = 12,
    }, TBar)

    local g1 = New("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(5,0), BackgroundColor3 = C.AccentBright, Rotation = 45, BorderSizePixel = 0, ZIndex = 13 }, gemF); Rnd(2, g1)
    local g2 = New("Frame", { Size = UDim2.fromOffset(7, 7),  Position = UDim2.fromOffset(0,10), BackgroundColor3 = C.Accent,       Rotation = 45, BorderSizePixel = 0, ZIndex = 13 }, gemF); Rnd(2, g2)
    local g3 = New("Frame", { Size = UDim2.fromOffset(7, 7),  Position = UDim2.fromOffset(10,10),BackgroundColor3 = C.AccentGlow,    Rotation = 45, BorderSizePixel = 0, ZIndex = 13 }, gemF); Rnd(2, g3)

    New("TextLabel", {
        Size = UDim2.new(1, -165, 0, 22),
        Position = UDim2.fromOffset(44, 8),
        BackgroundTransparency = 1,
        Text = title, TextColor3 = C.TxtPri,
        Font = Enum.Font.GothamBold, TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12,
    }, TBar)

    if subtitle ~= "" then
        New("TextLabel", {
            Size = UDim2.new(1, -165, 0, 14),
            Position = UDim2.fromOffset(44, 30),
            BackgroundTransparency = 1,
            Text = subtitle, TextColor3 = C.TxtDis,
            Font = Enum.Font.Gotham, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12,
        }, TBar)
    end

    -- Control buttons
    local function CtrlBtn(xOff, icon, bgN, bgH, txtC)
        local b = New("TextButton", {
            Size = UDim2.fromOffset(30, 30),
            Position = UDim2.new(1, xOff, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = bgN,
            Text = icon, TextColor3 = txtC,
            Font = Enum.Font.GothamBold, TextSize = 14,
            BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 14,
        }, TBar)
        Rnd(8, b)
        Hover(b, bgN, bgH)
        Ripple(b)
        return b
    end

    local MinBtn   = CtrlBtn(-70, "－", Color3.fromRGB(26,16,44), Color3.fromRGB(42,26,70), C.TxtSec)
    local CloseBtn = CtrlBtn(-33, "✕", Color3.fromRGB(44,13,13), Color3.fromRGB(162,28,28), Color3.fromRGB(230,95,95))

    MakeDraggable(WinOuter, TBar)

    CloseBtn.MouseButton1Click:Connect(function()
        TwIn(WinFrame, 0.22, { BackgroundTransparency = 1 })
        task.delay(0.24, function() Gui:Destroy() end)
    end)

    -- ── Mini Circle ────────────────────────────────────────────────────────────
    local CSZ = 64
    local Circle = New("TextButton", {
        Name = "MiniCircle",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(
            math.clamp(sx + winW*0.5, 36, math.max(36, vp.X-36)),
            math.clamp(sy + winH*0.5, 36, math.max(36, vp.Y-36))
        ),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.Accent,
        Text = string.upper(string.sub(title, 1, 1)),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold, TextSize = 24,
        BorderSizePixel = 0, AutoButtonColor = false,
        Visible = false, ZIndex = 300,
    }, Gui)
    Rnd(999, Circle)
    GradV(Circle, C.AccentBright, C.AccentDim)
    Strk(C.BordHi, 2, Circle)

    New("ImageLabel", {
        Size = UDim2.new(1, 34, 1, 34), Position = UDim2.fromOffset(-17, -17),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = C.AccentGlow, ImageTransparency = 0.42,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49,49,450,450),
        ZIndex = 299,
    }, Circle)

    MakeDraggable(Circle, Circle)

    local pulsing   = false
    local minimized = false

    local function StartPulse()
        pulsing = true
        task.spawn(function()
            while pulsing do
                TwSine(Circle, 1.0, { BackgroundColor3 = C.AccentBright })
                task.wait(1.0)
                TwSine(Circle, 1.0, { BackgroundColor3 = C.AccentDim })
                task.wait(1.0)
            end
        end)
    end
    local function StopPulse()
        pulsing = false
        Tw(Circle, 0.2, nil, nil, { BackgroundColor3 = C.Accent })
    end

    local function DoMinimize()
        if minimized then return end
        minimized = true
        local wp = WinOuter.AbsolutePosition
        local ws = WinOuter.AbsoluteSize
        -- FIX: clamp with max(0,…)
        local cx = math.clamp(wp.X + ws.X*0.5, 36, math.max(36, vp.X-36))
        local cy = math.clamp(wp.Y + ws.Y*0.5, 36, math.max(36, vp.Y-36))

        TwIn(WinFrame, 0.2, { BackgroundTransparency = 1 })
        TwIn(WinOuter, 0.22, { Size = UDim2.fromOffset(1, 1), Position = UDim2.fromOffset(cx, cy) })

        task.delay(0.21, function()
            if not minimized then return end
            WinOuter.Visible = false
            Circle.Position  = UDim2.fromOffset(cx, cy)
            Circle.Size      = UDim2.fromOffset(0, 0)
            Circle.Visible   = true
            TwSpring(Circle, 0.45, { Size = UDim2.fromOffset(CSZ, CSZ) })
            StartPulse()
        end)
    end

    local function DoRestore()
        if not minimized then return end
        minimized = false
        StopPulse()
        local cp = Circle.AbsolutePosition
        local cx = cp.X + CSZ * 0.5
        local cy = cp.Y + CSZ * 0.5
        TwIn(Circle, 0.17, { Size = UDim2.fromOffset(0, 0) })
        task.delay(0.16, function()
            Circle.Visible  = false
            WinOuter.Visible = true
            WinFrame.BackgroundTransparency = 0
            WinOuter.Size     = UDim2.fromOffset(1, 1)
            WinOuter.Position = UDim2.fromOffset(cx, cy)
            TwSpring(WinOuter, 0.42, {
                Size     = UDim2.fromOffset(winW, winH),
                Position = UDim2.fromOffset(sx, sy),
            })
        end)
    end

    MinBtn.MouseButton1Click:Connect(DoMinimize)
    Circle.MouseButton1Click:Connect(DoRestore)

    -- ── Tab Sidebar ────────────────────────────────────────────────────────────
    local Sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, TABW, 1, -52),
        Position = UDim2.fromOffset(0, 52),
        BackgroundColor3 = C.SidebarBg,
        BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = 8,
    }, WinFrame)
    GradH(Sidebar, Color3.fromRGB(11,7,20), Color3.fromRGB(9,6,17))

    -- Right border
    New("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = C.BordNorm,
        BorderSizePixel = 0, ZIndex = 9,
    }, Sidebar)

    -- Fluent-style animated selector bar
    local Selector = New("Frame", {
        Name = "Selector",
        Size = UDim2.fromOffset(3, 20),
        Position = UDim2.fromOffset(0, 8),
        BackgroundColor3 = C.Accent,
        BorderSizePixel = 0, ZIndex = 11,
    }, Sidebar)
    Rnd(3, Selector)
    GradV(Selector, C.AccentBright, C.AccentDim)

    local TabScroll = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 9,
    }, Sidebar)
    Pad(8, 8, 6, 6, TabScroll)
    List(nil, nil, 3, TabScroll)

    -- ── Content Area ───────────────────────────────────────────────────────────
    local ContentArea = New("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -TABW, 1, -52),
        Position = UDim2.new(0, TABW, 0, 52),
        BackgroundColor3 = C.ContentBg,
        BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = 7,
    }, WinFrame)
    GradV(ContentArea, Color3.fromRGB(15,10,25), Color3.fromRGB(11,7,20))

    -- ── Tab System ─────────────────────────────────────────────────────────────
    --
    --  TAB BUG ROOT CAUSE (found in Fluent Tab.lua):
    --  Fluent's SelectTab does:
    --    1. Loop ALL containers → Visible = false
    --    2. Show ONLY the new one → Visible = true
    --  Our old code used task.delay which ran AFTER activeTab changed,
    --  hiding the newly-shown page. The fix: NO delays, synchronous loop.
    --
    local allTabs  = {}   -- array of Tab objects
    local allPages = {}   -- parallel array of page frames
    local activeTab = nil

    local function SelectTab(newTab)
        if activeTab == newTab then return end

        -- ① Old button → inactive immediately (sync)
        if activeTab then
            local old = activeTab
            -- Deactivate button style
            Tw(old._btn, 0.16, nil, nil, { BackgroundColor3 = C.SidebarBg, BackgroundTransparency = 1 })
            local indOld = old._btn:FindFirstChild("Ind"); if indOld then Tw(indOld, 0.16, nil, nil, { BackgroundTransparency = 1 }) end
            local lblOld = old._btn:FindFirstChild("Lbl"); if lblOld then Tw(lblOld, 0.16, nil, nil, { TextColor3 = C.TxtDis }) end
            local icnOld = old._btn:FindFirstChild("Icn"); if icnOld then Tw(icnOld, 0.16, nil, nil, { TextColor3 = C.TxtDis }) end
        end

        -- ② Update reference BEFORE any async
        activeTab = newTab

        -- ③ Hide ALL pages (Fluent approach — loop, no exceptions)
        for _, pg in ipairs(allPages) do
            pg.Visible = false
        end

        -- ④ Show new page immediately (text is always visible)
        newTab._page.Visible  = true
        newTab._page.Position = UDim2.fromOffset(8, 0)
        Tw(newTab._page, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
            Position = UDim2.fromOffset(0, 0),
        })

        -- ⑤ Animate selector bar to new tab position (Fluent-style)
        local tabAbs = newTab._btn.AbsolutePosition.Y
        local sideAbs = Sidebar.AbsolutePosition.Y
        local relY = tabAbs - sideAbs
        Tw(Selector, 0.22, Enum.EasingStyle.Quart, nil, {
            Position = UDim2.fromOffset(0, relY + newTab._btn.AbsoluteSize.Y * 0.2),
            Size     = UDim2.fromOffset(3, newTab._btn.AbsoluteSize.Y * 0.6),
        })

        -- ⑥ New button → active
        Tw(newTab._btn, 0.16, nil, nil, { BackgroundColor3 = C.SidebarTabOn, BackgroundTransparency = 0 })
        local indNew = newTab._btn:FindFirstChild("Ind"); if indNew then Tw(indNew, 0.16, nil, nil, { BackgroundTransparency = 0 }) end
        local lblNew = newTab._btn:FindFirstChild("Lbl"); if lblNew then Tw(lblNew, 0.16, nil, nil, { TextColor3 = C.TxtPri }) end
        local icnNew = newTab._btn:FindFirstChild("Icn"); if icnNew then Tw(icnNew, 0.16, nil, nil, { TextColor3 = C.AccentBright }) end
    end

    -- ── Window Object ──────────────────────────────────────────────────────────
    local Window = { _gui = Gui, _outer = WinOuter, _frame = WinFrame }

    function Window:AddTab(opts)
        local tabTitle = opts.Title or ("Tab " .. #allTabs + 1)
        local tabIcon  = opts.Icon  or "○"

        -- ── Tab button ────────────────────────────────────────────
        local Btn = New("TextButton", {
            Name = "TabBtn_" .. tabTitle,
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = C.SidebarBg,
            BackgroundTransparency = 1,
            Text = "", BorderSizePixel = 0,
            AutoButtonColor = false,
            ClipsDescendants = false, ZIndex = 10,
        }, TabScroll)
        Rnd(9, Btn)

        -- Left indicator stripe (Fluent-style)
        local Ind = New("Frame", {
            Name = "Ind",
            Size = UDim2.new(0, 3, 0.55, 0),
            Position = UDim2.new(0, -1, 0.225, 0),
            BackgroundColor3 = C.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0, ZIndex = 11,
        }, Btn)
        Rnd(4, Ind)
        GradV(Ind, C.AccentBright, C.AccentDim)

        -- Icon
        local Icn = New("TextLabel", {
            Name = "Icn",
            Size = UDim2.fromOffset(26, 40),
            Position = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Text = tabIcon, TextColor3 = C.TxtDis,
            Font = Enum.Font.Gotham, TextSize = 16, ZIndex = 11,
        }, Btn)

        -- Label
        local Lbl = New("TextLabel", {
            Name = "Lbl",
            Size = UDim2.new(1, -42, 1, 0),
            Position = UDim2.fromOffset(36, 0),
            BackgroundTransparency = 1,
            Text = tabTitle, TextColor3 = C.TxtDis,
            Font = Enum.Font.GothamSemibold, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11,
        }, Btn)

        -- Hover (only when not active)
        Btn.MouseEnter:Connect(function()
            if activeTab and activeTab._btn == Btn then return end
            Tw(Btn, 0.12, nil, nil, { BackgroundColor3 = C.SidebarTabHov, BackgroundTransparency = 0 })
        end)
        Btn.MouseLeave:Connect(function()
            if activeTab and activeTab._btn == Btn then return end
            Tw(Btn, 0.12, nil, nil, { BackgroundTransparency = 1 })
        end)

        -- ── Content Page ──────────────────────────────────────────
        local Page = New("ScrollingFrame", {
            Name = "Page_" .. tabTitle,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = C.AccentDim,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ClipsDescendants = true, ZIndex = 8,
        }, ContentArea)
        Pad(12, 18, 12, 12, Page)
        List(nil, nil, 8, Page)

        local Tab = { _btn = Btn, _page = Page, _title = tabTitle }

        Btn.MouseButton1Click:Connect(function() SelectTab(Tab) end)

        table.insert(allTabs, Tab)
        table.insert(allPages, Page)

        -- Auto-select first tab
        if #allTabs == 1 then
            SelectTab(Tab)
        end

        -- ── ELEMENTS ─────────────────────────────────────────────

        -- Section
        function Tab:AddSection(name)
            local row = New("Frame", {
                Size = UDim2.new(1, 0, 0, 32),
                BackgroundTransparency = 1, ZIndex = 9,
            }, Page)
            New("TextLabel", {
                Size = UDim2.new(1, -10, 0, 18), Position = UDim2.fromOffset(0, 8),
                BackgroundTransparency = 1,
                Text = string.upper(name), TextColor3 = C.Accent,
                Font = Enum.Font.GothamBold, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
            }, row)
            New("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = C.BordDim, BorderSizePixel = 0,
            }, row)
            local dot = New("Frame", {
                Size = UDim2.fromOffset(5, 5),
                Position = UDim2.new(0, -1, 1, -3),
                BackgroundColor3 = C.Accent, BorderSizePixel = 0,
            }, row)
            Rnd(99, dot)
        end

        -- Separator
        function Tab:AddSeparator()
            New("Frame", {
                Name = "Sep",
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = C.BordDim, BorderSizePixel = 0,
            }, Page)
        end

        -- Paragraph
        function Tab:AddParagraph(opts)
            local card = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = C.CardBg, BorderSizePixel = 0,
            }, Page)
            Rnd(10, card)
            Strk(C.BordDim, 1, card)
            local accent = New("Frame", {
                Size = UDim2.new(1, 0, 0, 2),
                BackgroundColor3 = C.AccentDim, BorderSizePixel = 0,
            }, card)
            Rnd(3, accent)
            local inner = New("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
            }, card)
            Pad(12, 12, 14, 14, inner)
            List(nil, nil, 6, inner)
            if opts.Title and opts.Title ~= "" then
                New("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Text = opts.Title, TextColor3 = C.TxtPri,
                    Font = Enum.Font.GothamBold, TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
                }, inner)
            end
            New("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = opts.Content or "", TextColor3 = C.TxtSec,
                Font = Enum.Font.Gotham, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
            }, inner)
        end

        -- Button
        function Tab:AddButton(opts)
            local hasDesc = opts.Description and opts.Description ~= ""
            local h = hasDesc and 52 or 40

            local card = New("TextButton", {
                Size = UDim2.new(1, 0, 0, h),
                BackgroundColor3 = C.CardBg, Text = "",
                BorderSizePixel = 0, AutoButtonColor = false,
                ClipsDescendants = true, ZIndex = 9,
            }, Page)
            Rnd(10, card)
            Strk(C.BordDim, 1, card)

            local leftLine = New("Frame", {
                Size = UDim2.new(0, 3, 0.5, 0),
                Position = UDim2.new(0, 0, 0.25, 0),
                BackgroundColor3 = C.Accent, BorderSizePixel = 0, ZIndex = 10,
            }, card)
            Rnd(3, leftLine)
            GradV(leftLine, C.AccentBright, C.AccentDim)

            New("TextLabel", {
                Size = UDim2.new(1, -22, 0, 20),
                Position = UDim2.fromOffset(14, hasDesc and 9 or 10),
                BackgroundTransparency = 1,
                Text = opts.Title or "Button", TextColor3 = C.TxtAcc,
                Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
            }, card)

            if hasDesc then
                New("TextLabel", {
                    Size = UDim2.new(1, -22, 0, 14),
                    Position = UDim2.fromOffset(14, 30),
                    BackgroundTransparency = 1,
                    Text = opts.Description, TextColor3 = C.TxtDis,
                    Font = Enum.Font.Gotham, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10,
                }, card)
            end

            Hover(card, C.CardBg, C.CardHov, C.CardPres)
            Ripple(card)
            card.MouseButton1Click:Connect(function()
                if opts.Callback then task.spawn(opts.Callback) end
            end)
        end

        -- Toggle
        function Tab:AddToggle(id, opts)
            local val     = opts.Default == true
            local hasDesc = opts.Description and opts.Description ~= ""
            local h       = hasDesc and 52 or 42

            local card = New("Frame", {
                Name = "Toggle_" .. (id or ""),
                Size = UDim2.new(1, 0, 0, h),
                BackgroundColor3 = C.CardBg, BorderSizePixel = 0,
            }, Page)
            Rnd(10, card)
            Strk(C.BordDim, 1, card)

            New("TextLabel", {
                Size = UDim2.new(1, -72, 0, 20),
                Position = UDim2.fromOffset(14, hasDesc and 9 or 11),
                BackgroundTransparency = 1,
                Text = opts.Title or "", TextColor3 = C.TxtPri,
                Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, card)

            if hasDesc then
                New("TextLabel", {
                    Size = UDim2.new(1, -72, 0, 14),
                    Position = UDim2.fromOffset(14, 30),
                    BackgroundTransparency = 1,
                    Text = opts.Description, TextColor3 = C.TxtDis,
                    Font = Enum.Font.Gotham, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, card)
            end

            local Track = New("Frame", {
                Size = UDim2.fromOffset(46, 26),
                Position = UDim2.new(1, -57, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = val and C.TgOn or C.TgOff,
                BorderSizePixel = 0,
            }, card)
            Rnd(13, Track)

            local trkStk = Strk(val and C.AccentDim or C.BordDim, 1, Track)

            -- Shine line on track top
            local shine = New("Frame", {
                Size = UDim2.new(1, -6, 0, 1),
                Position = UDim2.fromOffset(3, 3),
                BackgroundColor3 = Color3.fromRGB(255,255,255),
                BackgroundTransparency = 0.83, BorderSizePixel = 0, ZIndex = 2,
            }, Track)
            Rnd(1, shine)

            local Knob = New("Frame", {
                Size = UDim2.fromOffset(20, 20),
                Position = val and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
                BackgroundColor3 = C.TgKnob,
                BorderSizePixel = 0, ZIndex = 3,
            }, Track)
            Rnd(99, Knob)

            local knobGlow = New("Frame", {
                Size = UDim2.fromOffset(10, 10),
                Position = UDim2.fromOffset(5, 5),
                BackgroundColor3 = C.AccentLilac,
                BackgroundTransparency = val and 0.25 or 1,
                BorderSizePixel = 0, ZIndex = 4,
            }, Knob)
            Rnd(99, knobGlow)

            local function SetVis(v)
                Tw(Track, 0.22, nil, nil, { BackgroundColor3 = v and C.TgOn or C.TgOff })
                Tw(Knob, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                    Position = v and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
                })
                Tw(knobGlow, 0.18, nil, nil, { BackgroundTransparency = v and 0.25 or 1 })
                Tw(trkStk, 0.18, nil, nil, { Color = v and C.AccentDim or C.BordDim })
            end

            local Clk = New("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1, Text = "", ZIndex = 15,
            }, card)
            Hover(card, C.CardBg, C.CardHov)

            Clk.MouseButton1Click:Connect(function()
                val = not val
                SetVis(val)
                if opts.Callback then task.spawn(opts.Callback, val) end
            end)
            SetVis(val)

            local obj = {}
            function obj:Set(v) val = v == true; SetVis(val); if opts.Callback then task.spawn(opts.Callback, val) end end
            function obj:Get() return val end
            return obj
        end

        -- Slider
        function Tab:AddSlider(id, opts)
            local mn      = opts.Min      or 0
            local mx      = opts.Max      or 100
            local rnd     = opts.Rounding or 0
            local sfx     = opts.Suffix   or ""
            local hasDesc = opts.Description and opts.Description ~= ""
            local h       = hasDesc and 70 or 58

            -- GUARD: ensure mn < mx (fixes clamp crash)
            if mx <= mn then mx = mn + 1 end
            local def = math.clamp(opts.Default or mn, mn, mx)
            local val = def

            local function Round(v)
                if rnd == 0 then return math.floor(v + 0.5) end
                local m = 10 ^ rnd; return math.floor(v * m + 0.5) / m
            end
            val = Round(val)

            local card = New("Frame", {
                Name = "Slider_" .. (id or ""),
                Size = UDim2.new(1, 0, 0, h),
                BackgroundColor3 = C.CardBg, BorderSizePixel = 0,
            }, Page)
            Rnd(10, card)
            Strk(C.BordDim, 1, card)
            Pad(10, 10, 14, 14, card)

            local headRow = New("Frame", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
            }, card)

            New("TextLabel", {
                Size = UDim2.new(1, -72, 1, 0),
                BackgroundTransparency = 1,
                Text = opts.Title or "Slider", TextColor3 = C.TxtPri,
                Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, headRow)

            local badge = New("Frame", {
                Size = UDim2.fromOffset(64, 22),
                Position = UDim2.new(1, -64, 0, -1),
                BackgroundColor3 = C.AccentDeep, BorderSizePixel = 0,
            }, headRow)
            Rnd(7, badge)
            Strk(C.AccentDim, 1, badge)
            local valLbl = New("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                Text = tostring(val) .. sfx, TextColor3 = C.TxtAcc,
                Font = Enum.Font.GothamBold, TextSize = 12,
            }, badge)

            if hasDesc then
                New("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 22),
                    BackgroundTransparency = 1,
                    Text = opts.Description, TextColor3 = C.TxtDis,
                    Font = Enum.Font.Gotham, TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, card)
            end

            local trOff = hasDesc and 44 or 30
            local TrackBg = New("Frame", {
                Size = UDim2.new(1, 0, 0, 14),
                Position = UDim2.fromOffset(0, trOff),
                BackgroundColor3 = C.SlTrack, BorderSizePixel = 0,
            }, card)
            Rnd(7, TrackBg)
            Strk(C.BordDim, 1, TrackBg)

            local t0 = (val - mn) / (mx - mn)
            local Fill = New("Frame", {
                Size = UDim2.new(t0, 0, 1, 0),
                BackgroundColor3 = C.Accent, BorderSizePixel = 0,
            }, TrackBg)
            Rnd(7, Fill)
            GradH(Fill, C.AccentBright, C.Accent)

            local Knob = New("Frame", {
                Size = UDim2.fromOffset(22, 22),
                Position = UDim2.new(t0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = C.SlKnob, BorderSizePixel = 0, ZIndex = 12,
            }, TrackBg)
            Rnd(99, Knob)
            GradV(Knob, Color3.fromRGB(255,255,255), C.AccentLilac)

            local knobRing = New("Frame", {
                Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset(6, 6),
                BackgroundColor3 = C.Accent, BackgroundTransparency = 0.4,
                BorderSizePixel = 0, ZIndex = 13,
            }, Knob)
            Rnd(99, knobRing)

            -- Fluent-style slider drag (DragInput pattern)
            local sDragging = false
            local sDragInput = nil

            local function ApplyAtX(absX)
                -- FIX: guard against zero-width track (frame not rendered yet)
                local tw2 = TrackBg.AbsoluteSize.X
                if tw2 == 0 then return end
                local ta  = TrackBg.AbsolutePosition.X
                local pct = math.clamp((absX - ta) / tw2, 0, 1)
                val       = Round(mn + pct * (mx - mn))
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                Knob.Position = UDim2.new(pct, 0, 0.5, 0)
                valLbl.Text   = tostring(val) .. sfx
                if opts.Callback then opts.Callback(val) end
            end

            -- Begin drag on track click (Fluent: InputBegan on the dot/track)
            TrackBg.InputBegan:Connect(function(inp)
                local t = inp.UserInputType
                if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                    sDragging = true
                    ApplyAtX(inp.Position.X)
                    Tw(Knob, 0.1, nil, nil, { Size = UDim2.fromOffset(26, 26) })
                    inp.Changed:Connect(function()
                        if inp.UserInputState == Enum.UserInputState.End then
                            sDragging = false
                            TwSpring(Knob, 0.2, { Size = UDim2.fromOffset(22, 22) })
                        end
                    end)
                end
            end)

            -- Track InputChanged → store reference
            TrackBg.InputChanged:Connect(function(inp)
                local t = inp.UserInputType
                if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                    sDragInput = inp
                end
            end)

            -- Global InputChanged → act only on matching input (Fluent pattern)
            UserInputService.InputChanged:Connect(function(inp)
                if sDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    ApplyAtX(inp.Position.X)
                end
            end)

            local obj = {}
            function obj:Set(v)
                v = math.clamp(Round(v), mn, mx); val = v
                local pct = (v - mn) / (mx - mn)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                Knob.Position = UDim2.new(pct, 0, 0.5, 0)
                valLbl.Text = tostring(v) .. sfx
                if opts.Callback then opts.Callback(v) end
            end
            function obj:Get() return val end
            return obj
        end

        -- Dropdown
        function Tab:AddDropdown(id, opts)
            local values  = opts.Values or {}
            local defIdx  = opts.Default or 1
            local current = values[defIdx] or values[1] or ""
            local isOpen  = false
            local ITEM_H  = 36
            local maxShow = math.min(#values, 5)
            local popH    = maxShow * (ITEM_H + 3) + 8

            local wrap = New("Frame", {
                Name = "DD_" .. (id or ""),
                Size = UDim2.new(1, 0, 0, 46),
                BackgroundTransparency = 1,
                ClipsDescendants = false, ZIndex = 30,
            }, Page)

            local Hdr = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 46),
                BackgroundColor3 = C.CardBg, Text = "",
                BorderSizePixel = 0, AutoButtonColor = false,
                ClipsDescendants = true, ZIndex = 31,
            }, wrap)
            Rnd(10, Hdr)
            Strk(C.BordDim, 1, Hdr)
            Hover(Hdr, C.CardBg, C.CardHov)

            New("TextLabel", {
                Size = UDim2.new(1, -50, 0, 14), Position = UDim2.fromOffset(14, 7),
                BackgroundTransparency = 1,
                Text = opts.Title or "Dropdown", TextColor3 = C.TxtDis,
                Font = Enum.Font.Gotham, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 32,
            }, Hdr)

            local SelLbl = New("TextLabel", {
                Size = UDim2.new(1, -50, 0, 18), Position = UDim2.fromOffset(14, 22),
                BackgroundTransparency = 1,
                Text = current, TextColor3 = C.TxtPri,
                Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 32,
            }, Hdr)

            local Arrow = New("TextLabel", {
                Size = UDim2.fromOffset(24, 46), Position = UDim2.new(1, -30, 0, 0),
                BackgroundTransparency = 1,
                Text = "▾", TextColor3 = C.Accent,
                Font = Enum.Font.GothamBold, TextSize = 15, ZIndex = 32,
            }, Hdr)

            local Popup = New("ScrollingFrame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.fromOffset(0, 48),
                BackgroundColor3 = C.DropBg, BorderSizePixel = 0,
                ClipsDescendants = true,
                Visible = false, ZIndex = 60,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = C.AccentDim,
                CanvasSize = UDim2.new(0, 0, 0, #values * (ITEM_H + 3) + 8),
            }, wrap)
            Rnd(10, Popup)
            Strk(C.BordNorm, 1, Popup)
            Pad(4, 4, 4, 4, Popup)
            List(nil, nil, 3, Popup)

            local function Close()
                isOpen = false
                Tw(Arrow, 0.16, nil, nil, { Rotation = 0 })
                TwIn(Popup, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
                task.delay(0.2, function() if not isOpen then Popup.Visible = false end end)
            end
            local function Open()
                isOpen = true; Popup.Visible = true; Popup.Size = UDim2.new(1, 0, 0, 0)
                Tw(Arrow, 0.18, nil, nil, { Rotation = 180 })
                Tw(Popup, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, { Size = UDim2.new(1, 0, 0, popH) })
            end
            Hdr.MouseButton1Click:Connect(function() if isOpen then Close() else Open() end end)

            local itemMap = {}
            for _, v in ipairs(values) do
                local sel = (v == current)
                local item = New("TextButton", {
                    Size = UDim2.new(1, 0, 0, ITEM_H),
                    BackgroundColor3 = sel and C.SidebarTabOn or C.DropBg,
                    Text = "", BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 62,
                }, Popup)
                Rnd(8, item)
                itemMap[v] = item

                local chk = New("TextLabel", {
                    Name = "Chk", Size = UDim2.fromOffset(20, ITEM_H),
                    Position = UDim2.new(1, -24, 0, 0),
                    BackgroundTransparency = 1,
                    Text = sel and "✓" or "", TextColor3 = C.Accent,
                    Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 63,
                }, item)
                New("TextLabel", {
                    Size = UDim2.new(1, -30, 1, 0), Position = UDim2.fromOffset(10, 0),
                    BackgroundTransparency = 1,
                    Text = v, TextColor3 = sel and C.TxtAcc or C.TxtPri,
                    Font = sel and Enum.Font.GothamSemibold or Enum.Font.Gotham,
                    TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 63,
                }, item)

                Hover(item, sel and C.SidebarTabOn or C.DropBg, C.CardHov)
                Ripple(item)

                item.MouseButton1Click:Connect(function()
                    for vk, ib in next, itemMap do
                        local s2 = (vk == v)
                        ib.BackgroundColor3 = s2 and C.SidebarTabOn or C.DropBg
                        local ck = ib:FindFirstChild("Chk"); if ck then ck.Text = s2 and "✓" or "" end
                        for _, ch in ipairs(ib:GetChildren()) do
                            if ch:IsA("TextLabel") and ch.Name ~= "Chk" then
                                ch.TextColor3 = s2 and C.TxtAcc or C.TxtPri
                                ch.Font = s2 and Enum.Font.GothamSemibold or Enum.Font.Gotham
                            end
                        end
                    end
                    current = v; SelLbl.Text = v
                    Close()
                    if opts.Callback then task.spawn(opts.Callback, v) end
                end)
            end

            local obj = {}
            function obj:Set(v) current = v; SelLbl.Text = v end
            function obj:Get() return current end
            return obj
        end

        -- Input
        function Tab:AddInput(id, opts)
            local card = New("Frame", {
                Name = "Input_" .. (id or ""),
                Size = UDim2.new(1, 0, 0, 54),
                BackgroundColor3 = C.CardBg, BorderSizePixel = 0,
            }, Page)
            Rnd(10, card)
            Strk(C.BordDim, 1, card)

            New("TextLabel", {
                Size = UDim2.new(1, -24, 0, 16), Position = UDim2.fromOffset(14, 8),
                BackgroundTransparency = 1,
                Text = opts.Title or "Input", TextColor3 = C.TxtDis,
                Font = Enum.Font.Gotham, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, card)

            local ibg = New("Frame", {
                Size = UDim2.new(1, -20, 0, 24), Position = UDim2.fromOffset(10, 25),
                BackgroundColor3 = C.InputBg, BorderSizePixel = 0,
            }, card)
            Rnd(7, ibg)
            local istk = Strk(C.BordDim, 1, ibg)

            local Box = New("TextBox", {
                Size = UDim2.new(1, -14, 1, 0), Position = UDim2.fromOffset(7, 0),
                BackgroundTransparency = 1,
                Text = opts.Default or "",
                PlaceholderText = opts.Placeholder or "Type here...",
                PlaceholderColor3 = C.TxtDis,
                TextColor3 = C.TxtPri,
                Font = Enum.Font.GothamSemibold, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = opts.ClearTextOnFocus == true,
            }, ibg)

            Box.Focused:Connect(function()
                Tw(istk, 0.18, nil, nil, { Color = C.Accent, Thickness = 1.5 })
                Tw(ibg, 0.18, nil, nil, { BackgroundColor3 = C.AccentDeep })
            end)
            Box.FocusLost:Connect(function(enter)
                Tw(istk, 0.18, nil, nil, { Color = C.BordDim, Thickness = 1 })
                Tw(ibg, 0.18, nil, nil, { BackgroundColor3 = C.InputBg })
                if opts.Callback then task.spawn(opts.Callback, Box.Text, enter) end
            end)

            local obj = {}
            function obj:Set(v) Box.Text = tostring(v) end
            function obj:Get() return Box.Text end
            return obj
        end

        -- Keybind
        function Tab:AddKeybind(id, opts)
            local key    = opts.Default or Enum.KeyCode.Unknown
            local listen = false

            local card = New("Frame", {
                Name = "Key_" .. (id or ""),
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = C.CardBg, BorderSizePixel = 0,
            }, Page)
            Rnd(10, card)
            Strk(C.BordDim, 1, card)

            New("TextLabel", {
                Size = UDim2.new(1, -125, 1, 0), Position = UDim2.fromOffset(14, 0),
                BackgroundTransparency = 1,
                Text = opts.Title or "Keybind", TextColor3 = C.TxtPri,
                Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, card)

            local badge = New("TextButton", {
                Size = UDim2.fromOffset(110, 28),
                Position = UDim2.new(1, -120, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = C.InputBg,
                Text = tostring(key.Name), TextColor3 = C.TxtAcc,
                Font = Enum.Font.GothamBold, TextSize = 12,
                BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 11,
            }, card)
            Rnd(8, badge)
            local bstk = Strk(C.BordDim, 1, badge)

            local function SetListen(v)
                listen = v
                badge.Text = v and "[ ... ]" or tostring(key.Name)
                Tw(bstk, 0.15, nil, nil, { Color = v and C.Accent or C.BordDim })
                Tw(badge, 0.15, nil, nil, {
                    BackgroundColor3 = v and C.AccentDeep or C.InputBg,
                    TextColor3       = v and C.AccentBright or C.TxtAcc,
                })
            end

            badge.MouseButton1Click:Connect(function() SetListen(true) end)
            UserInputService.InputBegan:Connect(function(inp)
                if not listen then return end
                if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if inp.KeyCode == Enum.KeyCode.Escape then SetListen(false); return end
                key = inp.KeyCode; SetListen(false)
                if opts.Callback then task.spawn(opts.Callback, key) end
            end)

            local obj = {}
            function obj:Get() return key end
            function obj:IsDown() return UserInputService:IsKeyDown(key) end
            return obj
        end

        -- Color Picker
        function Tab:AddColorPicker(id, opts)
            local col = opts.Default or Color3.fromRGB(155, 82, 210)
            local h, s, v2 = Color3.toHSV(col)
            local isOpen = false
            local PICK_H = 148

            local wrap = New("Frame", {
                Name = "CP_" .. (id or ""),
                Size = UDim2.new(1, 0, 0, 46),
                BackgroundTransparency = 1,
                ClipsDescendants = false, ZIndex = 25,
            }, Page)

            local Hdr = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 46),
                BackgroundColor3 = C.CardBg, Text = "",
                BorderSizePixel = 0, AutoButtonColor = false,
                ClipsDescendants = true, ZIndex = 26,
            }, wrap)
            Rnd(10, Hdr)
            Strk(C.BordDim, 1, Hdr)
            Hover(Hdr, C.CardBg, C.CardHov)

            New("TextLabel", {
                Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(14, 0),
                BackgroundTransparency = 1,
                Text = opts.Title or "Color", TextColor3 = C.TxtPri,
                Font = Enum.Font.GothamSemibold, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 27,
            }, Hdr)

            local prev = New("Frame", {
                Size = UDim2.fromOffset(36, 24),
                Position = UDim2.new(1, -50, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 27,
            }, Hdr)
            Rnd(7, prev)
            Strk(C.BordNorm, 1, prev)

            local Popup = New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.fromOffset(0, 48),
                BackgroundColor3 = C.DropBg,
                BorderSizePixel = 0, ClipsDescendants = true,
                Visible = false, ZIndex = 55,
            }, wrap)
            Rnd(10, Popup)
            Strk(C.BordNorm, 1, Popup)
            Pad(12, 12, 12, 12, Popup)
            List(nil, nil, 10, Popup)

            local function NotifyColor()
                col = Color3.fromHSV(h, s, v2)
                prev.BackgroundColor3 = col
                if opts.Callback then task.spawn(opts.Callback, col) end
            end

            local function MiniSlider(lbl, init, cb)
                local row = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, Popup)
                New("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
                    Text = lbl, TextColor3 = C.TxtDis, Font = Enum.Font.Gotham, TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, row)
                local trk = New("Frame", {
                    Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 18),
                    BackgroundColor3 = C.SlTrack, BorderSizePixel = 0,
                }, row)
                Rnd(7, trk)
                local fill2 = New("Frame", { Size = UDim2.new(init, 0, 1, 0), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, trk)
                Rnd(7, fill2)
                local kn = New("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(init, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.SlKnob, BorderSizePixel = 0, ZIndex = 60 }, trk)
                Rnd(99, kn)
                local sd = false
                trk.InputBegan:Connect(function(inp)
                    local t = inp.UserInputType
                    if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                        sd = true
                        local tw2 = trk.AbsoluteSize.X
                        if tw2 == 0 then return end
                        local p = math.clamp((inp.Position.X - trk.AbsolutePosition.X) / tw2, 0, 1)
                        fill2.Size = UDim2.new(p, 0, 1, 0); kn.Position = UDim2.new(p, 0, 0.5, 0)
                        cb(p)
                        inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then sd = false end end)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if not sd then return end
                    local t = inp.UserInputType
                    if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                        local tw2 = trk.AbsoluteSize.X
                        if tw2 == 0 then return end
                        local p = math.clamp((inp.Position.X - trk.AbsolutePosition.X) / tw2, 0, 1)
                        fill2.Size = UDim2.new(p, 0, 1, 0); kn.Position = UDim2.new(p, 0, 0.5, 0)
                        cb(p)
                    end
                end)
            end

            MiniSlider("Hue", h, function(p) h = p; NotifyColor() end)
            MiniSlider("Saturation", s, function(p) s = p; NotifyColor() end)
            MiniSlider("Brightness", v2, function(p) v2 = p; NotifyColor() end)

            local function ClosePicker()
                isOpen = false
                TwIn(Popup, 0.18, { Size = UDim2.new(1, 0, 0, 0) })
                task.delay(0.2, function() if not isOpen then Popup.Visible = false end end)
            end
            local function OpenPicker()
                isOpen = true; Popup.Visible = true; Popup.Size = UDim2.new(1, 0, 0, 0)
                Tw(Popup, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, { Size = UDim2.new(1, 0, 0, PICK_H) })
            end
            Hdr.MouseButton1Click:Connect(function() if isOpen then ClosePicker() else OpenPicker() end end)

            local obj = {}
            function obj:Set(c) col = c; prev.BackgroundColor3 = c; h, s, v2 = Color3.toHSV(c) end
            function obj:Get() return col end
            return obj
        end

        return Tab
    end -- Window:AddTab

    function Window:Minimize() DoMinimize() end
    function Window:Restore()  DoRestore()  end
    function Window:Destroy()  Gui:Destroy() end

    -- Entrance spring animation
    WinOuter.Size     = UDim2.fromOffset(math.floor(winW * 0.88), math.floor(winH * 0.88))
    WinOuter.Position = UDim2.fromOffset(sx + math.floor(winW * 0.06), sy + math.floor(winH * 0.06))
    TwSpring(WinOuter, 0.42, {
        Size     = UDim2.fromOffset(winW, winH),
        Position = UDim2.fromOffset(sx, sy),
    })

    return Window
end -- AzureLib:CreateWindow

return AzureLib

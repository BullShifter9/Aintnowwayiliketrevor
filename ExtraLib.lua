-- ======================================================================
--   ExtraLib v2.0  |  By ExtraBlox
--   Professional Roblox UI Library
--   PC & Mobile Compatible | Optimized | Smooth Animations
-- ======================================================================

local ExtraLib    = {}
ExtraLib.__index  = ExtraLib

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local S        = IsMobile and 1.12 or 1

-- ======================================================================
--  THEME
-- ======================================================================

local Theme = {
    Bg          = Color3.fromRGB(9,   9,   14),
    BgSecondary = Color3.fromRGB(15,  15,  22),
    BgTertiary  = Color3.fromRGB(21,  21,  32),
    BgHover     = Color3.fromRGB(26,  26,  40),
    Accent      = Color3.fromRGB(0,   255, 234),
    AccentDim   = Color3.fromRGB(0,   180, 165),
    Purple      = Color3.fromRGB(157, 0,   255),
    PurpleDim   = Color3.fromRGB(110, 0,   180),
    Pink        = Color3.fromRGB(255, 0,   128),
    PinkDim     = Color3.fromRGB(180, 0,   90),
    Green       = Color3.fromRGB(0,   220, 110),
    Red         = Color3.fromRGB(255, 55,  90),
    Yellow      = Color3.fromRGB(255, 210, 0),
    Text        = Color3.fromRGB(220, 220, 240),
    TextSub     = Color3.fromRGB(155, 155, 185),
    TextMuted   = Color3.fromRGB(85,  85,  120),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0,   0,   0),
    Border      = Color3.fromRGB(0,   255, 234),
    BorderMuted = Color3.fromRGB(30,  30,  48),
}

-- ======================================================================
--  TWEEN PRESETS
-- ======================================================================

local TI = {
    Fast    = TweenInfo.new(0.15, Enum.EasingStyle.Quart,   Enum.EasingDirection.Out),
    Normal  = TweenInfo.new(0.25, Enum.EasingStyle.Quart,   Enum.EasingDirection.Out),
    Smooth  = TweenInfo.new(0.35, Enum.EasingStyle.Quart,   Enum.EasingDirection.Out),
    Bounce  = TweenInfo.new(0.45, Enum.EasingStyle.Back,    Enum.EasingDirection.Out),
    Spring  = TweenInfo.new(0.55, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    Slow    = TweenInfo.new(0.6,  Enum.EasingStyle.Quart,   Enum.EasingDirection.Out),
    Linear  = TweenInfo.new(0.2,  Enum.EasingStyle.Linear,  Enum.EasingDirection.Out),
    Sine    = TweenInfo.new(0.3,  Enum.EasingStyle.Sine,    Enum.EasingDirection.Out),
}

local function Tween(obj, props, preset)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, preset or TI.Normal, props):Play()
end

-- ======================================================================
--  INSTANCE HELPERS
-- ======================================================================

local function Make(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    for _, c in pairs(children or {}) do c.Parent = obj end
    return obj
end

local function Corner(r)
    return Make("UICorner", { CornerRadius = UDim.new(0, r or 8) })
end

local function Stroke(col, thick, trans)
    return Make("UIStroke", {
        Color        = col or Theme.Border,
        Thickness    = thick or 1,
        Transparency = trans or 0.6,
    })
end

local function Pad(t, b, l, r)
    return Make("UIPadding", {
        PaddingTop    = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft   = UDim.new(0, l or 8),
        PaddingRight  = UDim.new(0, r or 8),
    })
end

local function ListLayout(dir, h, v, pad)
    return Make("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = h   or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = v   or Enum.VerticalAlignment.Top,
        Padding             = UDim.new(0, pad or 0),
        SortOrder           = Enum.SortOrder.LayoutOrder,
    })
end

-- ======================================================================
--  RIPPLE EFFECT
-- ======================================================================

local function AddRipple(btn, col)
    col = col or Color3.fromRGB(255, 255, 255)
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local abs  = btn.AbsoluteSize
        local pos  = btn.AbsolutePosition
        local ix   = inp.Position.X - pos.X
        local iy   = inp.Position.Y - pos.Y
        local size = math.max(abs.X, abs.Y) * 2.2
        local rip  = Make("Frame", {
            Size                   = UDim2.new(0, 0, 0, 0),
            Position               = UDim2.new(0, ix, 0, iy),
            AnchorPoint            = Vector2.new(0.5, 0.5),
            BackgroundColor3       = col,
            BackgroundTransparency = 0.75,
            BorderSizePixel        = 0,
            ZIndex                 = btn.ZIndex + 2,
            Parent                 = btn,
        }, { Corner(999) })
        Tween(rip, {
            Size                   = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1,
        }, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
        task.delay(0.56, function() if rip and rip.Parent then rip:Destroy() end end)
    end)
end

-- ======================================================================
--  GLOW PULSE
-- ======================================================================

local function PulseGlow(frame, col, minT, maxT, speed)
    col   = col   or Theme.Accent
    minT  = minT  or 0.5
    maxT  = maxT  or 0.9
    speed = speed or 1.2
    local st = Stroke(col, 1, minT)
    st.Parent = frame
    task.spawn(function()
        while frame and frame.Parent do
            Tween(st, {Transparency = maxT}, TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(speed)
            Tween(st, {Transparency = minT}, TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(speed)
        end
    end)
    return st
end

-- ======================================================================
--  SCREEN GUI
-- ======================================================================

local function GetGui()
    local gui = Instance.new("ScreenGui")
    gui.Name            = "ExtraLibV2"
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder    = 999
    gui.IgnoreGuiInset  = true
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    return gui
end

-- ======================================================================
--  NOTIFICATION SYSTEM
-- ======================================================================

local NotifGui   = nil
local NotifStack = {}
local NOTIF_GAP  = 8

local function GetNotifGui()
    if not NotifGui or not NotifGui.Parent then
        NotifGui = Instance.new("ScreenGui")
        NotifGui.Name            = "ExtraLibNotifs"
        NotifGui.ResetOnSpawn    = false
        NotifGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
        NotifGui.DisplayOrder    = 1000
        NotifGui.IgnoreGuiInset  = true
        local ok = pcall(function() NotifGui.Parent = game:GetService("CoreGui") end)
        if not ok then NotifGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    end
    return NotifGui
end

local function RepositionNotifs()
    local yOff = 16
    for i = #NotifStack, 1, -1 do
        local n = NotifStack[i]
        if n and n.Parent then
            Tween(n, { Position = UDim2.new(1, -10, 0, yOff) }, TI.Smooth)
            yOff = yOff + n.AbsoluteSize.Y + NOTIF_GAP
        end
    end
end

local function SendNotification(cfg)
    cfg = cfg or {}
    local ntitle    = cfg.Title    or "Notification"
    local ntext     = cfg.Text     or ""
    local nduration = cfg.Duration or 3.5
    local ntype     = cfg.Type     or "info"
    local nicon     = cfg.Icon

    local typeColor = ntype == "success" and Theme.Green
                   or ntype == "error"   and Theme.Red
                   or ntype == "warning" and Theme.Yellow
                   or Theme.Accent

    local nW  = math.floor(290 * S)
    local nH  = math.floor(72 * S)
    local ng  = GetNotifGui()

    local N = Make("Frame", {
        Name             = "Notif",
        Size             = UDim2.new(0, nW, 0, nH),
        Position         = UDim2.new(1, nW + 20, 0, 16),
        AnchorPoint      = Vector2.new(1, 0),
        BackgroundColor3 = Theme.BgSecondary,
        BorderSizePixel  = 0,
        ZIndex           = 200,
        ClipsDescendants = false,
        Parent           = ng,
    }, { Corner(12) })

    PulseGlow(N, typeColor, 0.55, 0.85, 1.5)

    Make("Frame", {
        Size             = UDim2.new(0, 3, 0.6, 0),
        Position         = UDim2.new(0, 0, 0.2, 0),
        BackgroundColor3 = typeColor,
        BorderSizePixel  = 0,
        ZIndex           = 202,
        Parent           = N,
    }, { Corner(2) })

    local iconX = 14
    if nicon then
        Make("TextLabel", {
            Size             = UDim2.new(0, math.floor(28 * S), 0, math.floor(28 * S)),
            Position         = UDim2.new(0, 12, 0.5, -math.floor(14 * S)),
            BackgroundColor3 = Color3.fromRGB(
                math.floor(typeColor.R * 255 * 0.12),
                math.floor(typeColor.G * 255 * 0.12),
                math.floor(typeColor.B * 255 * 0.12)
            ),
            BorderSizePixel  = 0,
            Text             = nicon,
            TextColor3       = typeColor,
            TextSize         = math.floor(14 * S),
            Font             = Enum.Font.GothamBold,
            ZIndex           = 202,
            Parent           = N,
        }, { Corner(8) })
        iconX = math.floor(48 * S)
    end

    Make("TextLabel", {
        Size             = UDim2.new(1, -(iconX + 14), 0, math.floor(22 * S)),
        Position         = UDim2.new(0, iconX, 0, math.floor(10 * S)),
        BackgroundTransparency = 1,
        Text             = ntitle,
        TextColor3       = typeColor,
        TextSize         = math.floor(12 * S),
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 202,
        Parent           = N,
    })

    Make("TextLabel", {
        Size             = UDim2.new(1, -(iconX + 14), 0, math.floor(28 * S)),
        Position         = UDim2.new(0, iconX, 0, math.floor(32 * S)),
        BackgroundTransparency = 1,
        Text             = ntext,
        TextColor3       = Theme.TextSub,
        TextSize         = math.floor(11 * S),
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        ZIndex           = 202,
        Parent           = N,
    })

    local Bar = Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = typeColor,
        BorderSizePixel  = 0,
        ZIndex           = 202,
        Parent           = N,
    }, { Corner(2) })

    table.insert(NotifStack, N)
    RepositionNotifs()

    Tween(N, { Position = UDim2.new(1, -10, 0, 16) }, TI.Bounce)
    Tween(Bar, { Size = UDim2.new(0, 0, 0, 2) },
        TweenInfo.new(nduration, Enum.EasingStyle.Linear))

    task.delay(nduration, function()
        Tween(N, {
            Position             = UDim2.new(1, nW + 20, 0, 16),
            BackgroundTransparency = 1,
        }, TI.Smooth)
        task.delay(0.36, function()
            local idx = table.find(NotifStack, N)
            if idx then table.remove(NotifStack, idx) end
            if N and N.Parent then N:Destroy() end
            RepositionNotifs()
        end)
    end)
end

-- ======================================================================
--  CREATE WINDOW
-- ======================================================================

function ExtraLib:CreateWindow(cfg)
    cfg = cfg or {}
    local title    = cfg.Title    or "ExtraLib"
    local subtitle = cfg.Subtitle or "Hub"
    local W        = math.floor((IsMobile and 340 or 490) * (cfg.Width  or 1))
    local H        = math.floor((IsMobile and 420 or 520) * (cfg.Height or 1))
    local TITLE_H  = math.floor(54 * S)
    local TABBAR_H = math.floor(38 * S)
    local CONTENT_Y = TITLE_H + TABBAR_H

    local ScreenGui = GetGui()

    local Shadow = Make("ImageLabel", {
        Name                   = "Shadow",
        Size                   = UDim2.new(0, W + 60, 0, H + 60),
        Position               = UDim2.new(0.5, -(W/2) - 30, 0.5, -(H/2) - 30),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://5028857084",
        ImageColor3            = Theme.Accent,
        ImageTransparency      = 0.88,
        ZIndex                 = 0,
        Parent                 = ScreenGui,
    })

    local Win = Make("Frame", {
        Name             = "Window",
        Size             = UDim2.new(0, W, 0, 0),
        Position         = UDim2.new(0.5, -W/2, 0.5, -H/2),
        BackgroundColor3 = Theme.Bg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 2,
        Parent           = ScreenGui,
    }, { Corner(14), Stroke(Theme.Border, 1, 0.72) })

    Make("Frame", {
        Size             = UDim2.new(1.4, 0, 0.35, 0),
        Position         = UDim2.new(-0.2, 0, -0.1, 0),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.93,
        BorderSizePixel  = 0,
        ZIndex           = 1,
        Parent           = Win,
    }, {
        Corner(999),
        Make("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(0, 255, 234)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(157, 0, 255)),
                ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 0, 128)),
            }),
            Rotation    = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0,   0.6),
                NumberSequenceKeypoint.new(0.5, 0.2),
                NumberSequenceKeypoint.new(1,   0.6),
            }),
        }),
    })

    -- ── Title bar ──────────────────────────────────────────────────
    local TitleBar = Make("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, TITLE_H),
        BackgroundColor3 = Theme.BgSecondary,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = Win,
    })

    Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.White,
        BorderSizePixel  = 0,
        ZIndex           = 6,
        Parent           = TitleBar,
    }, {
        Make("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,   255, 234)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(157, 0,   255)),
                ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 0,   128)),
            }),
        }),
    })

    local Orb = Make("Frame", {
        Size             = UDim2.new(0, math.floor(26 * S), 0, math.floor(26 * S)),
        Position         = UDim2.new(0, 14, 0.5, -math.floor(13 * S)),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 7,
        Parent           = TitleBar,
    }, {
        Corner(999),
        Make("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Purple), Rotation = 45 }),
    })

    task.spawn(function()
        local grow = false
        while Orb and Orb.Parent do
            grow = not grow
            Tween(Orb, {
                BackgroundTransparency = grow and 0.3 or 0,
                Size     = grow and UDim2.new(0, math.floor(28 * S), 0, math.floor(28 * S))
                               or UDim2.new(0, math.floor(26 * S), 0, math.floor(26 * S)),
                Position = grow and UDim2.new(0, 13, 0.5, -math.floor(14 * S))
                               or UDim2.new(0, 14, 0.5, -math.floor(13 * S)),
            }, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(0.8)
        end
    end)

    Make("TextLabel", {
        Size             = UDim2.new(0, W - 120, 0, math.floor(22 * S)),
        Position         = UDim2.new(0, math.floor(48 * S), 0, math.floor(7 * S)),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = Theme.White,
        TextSize         = math.floor(15 * S),
        Font             = Enum.Font.GothamBold,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 7,
        Parent           = TitleBar,
    })

    Make("TextLabel", {
        Size             = UDim2.new(0, W - 120, 0, math.floor(16 * S)),
        Position         = UDim2.new(0, math.floor(48 * S), 0, math.floor(30 * S)),
        BackgroundTransparency = 1,
        Text             = subtitle,
        TextColor3       = Theme.TextMuted,
        TextSize         = math.floor(10 * S),
        Font             = Enum.Font.Gotham,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 7,
        Parent           = TitleBar,
    })

    local function WinBtn(xOff, bg, txt, col)
        local b = Make("TextButton", {
            Size             = UDim2.new(0, math.floor(26 * S), 0, math.floor(26 * S)),
            Position         = UDim2.new(1, xOff, 0.5, -math.floor(13 * S)),
            BackgroundColor3 = bg,
            BackgroundTransparency = 0.65,
            Text             = txt,
            TextColor3       = col or Theme.White,
            TextSize         = math.floor(11 * S),
            Font             = Enum.Font.GothamBold,
            BorderSizePixel  = 0,
            ZIndex           = 8,
            AutoButtonColor  = false,
            Parent           = TitleBar,
        }, { Corner(6) })
        b.MouseEnter:Connect(function() Tween(b, {BackgroundTransparency = 0.15}, TI.Fast) end)
        b.MouseLeave:Connect(function() Tween(b, {BackgroundTransparency = 0.65}, TI.Fast) end)
        AddRipple(b, col or Theme.White)
        return b
    end

    local CloseBtn = WinBtn(-math.floor(36 * S), Theme.Pink,   "✕", Theme.White)
    local MinBtn   = WinBtn(-math.floor(68 * S), Theme.Accent, "─", Theme.Accent)

    local minimised = false
    MinBtn.MouseButton1Click:Connect(function()
        minimised = not minimised
        Tween(Win, {
            Size = minimised and UDim2.new(0, W, 0, TITLE_H) or UDim2.new(0, W, 0, H)
        }, TI.Bounce)
        Tween(Shadow, {
            Size = minimised and UDim2.new(0, W + 20, 0, TITLE_H + 20)
                              or UDim2.new(0, W + 60, 0, H + 60),
        }, TI.Bounce)
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Win,    {Size = UDim2.new(0, W, 0, 0), BackgroundTransparency = 1}, TI.Smooth)
        Tween(Shadow, {ImageTransparency = 1}, TI.Smooth)
        task.delay(0.36, function() ScreenGui:Destroy() end)
    end)

    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = i.Position
            startPos  = Win.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - dragStart
            Win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
            Shadow.Position = UDim2.new(Win.Position.X.Scale, Win.Position.X.Offset - 30,
                                        Win.Position.Y.Scale, Win.Position.Y.Offset - 30)
        end
    end)

    -- ── Tab bar ────────────────────────────────────────────────────
    local TabBar = Make("Frame", {
        Name             = "TabBar",
        Size             = UDim2.new(1, 0, 0, TABBAR_H),
        Position         = UDim2.new(0, 0, 0, TITLE_H),
        BackgroundColor3 = Theme.BgSecondary,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
        ZIndex           = 5,
        Parent           = Win,
    })

    local TabScroll = Make("ScrollingFrame", {
        Size                   = UDim2.new(1, -8, 1, 0),
        Position               = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 0,
        ScrollingDirection     = Enum.ScrollingDirection.X,
        ZIndex                 = 6,
        Parent                 = TabBar,
    }, {
        ListLayout(Enum.FillDirection.Horizontal,
                   Enum.HorizontalAlignment.Left,
                   Enum.VerticalAlignment.Center, 4),
        Pad(4, 4, 4, 4),
    })

    local tabLayout = TabScroll:FindFirstChildOfClass("UIListLayout")
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabScroll.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 8, 0, 0)
    end)

    local TabIndicator = Make("Frame", {
        Size             = UDim2.new(0, 60, 0, 2),
        Position         = UDim2.new(0, 4, 1, -2),
        BackgroundColor3 = Theme.White,
        BorderSizePixel  = 0,
        ZIndex           = 7,
        Parent           = TabBar,
    }, {
        Corner(2),
        Make("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   Theme.Accent),
                ColorSequenceKeypoint.new(0.5, Theme.Purple),
                ColorSequenceKeypoint.new(1,   Theme.Pink),
            }),
        }),
    })

    Make("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.BorderMuted,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = TabBar,
    })

    -- ── Content area ───────────────────────────────────────────────
    local ContentClip = Make("Frame", {
        Name             = "ContentClip",
        Size             = UDim2.new(1, 0, 1, -CONTENT_Y),
        Position         = UDim2.new(0, 0, 0, CONTENT_Y),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex           = 2,
        Parent           = Win,
    })

    Tween(Win, {Size = UDim2.new(0, W, 0, H)}, TI.Bounce)

    -- ==================================================================
    --  WINDOW OBJECT
    -- ==================================================================

    local WinObj   = {}
    WinObj._tabs   = {}
    WinObj._active = nil
    WinObj._gui    = ScreenGui

    function WinObj:Notify(c) SendNotification(c) end

    -- ==================================================================
    --  CREATE TAB
    -- ==================================================================

    function WinObj:CreateTab(name, icon)
        local tabBtnW = IsMobile and math.floor(90 * S) or math.floor(100 * S)

        local TabBtn = Make("TextButton", {
            Size             = UDim2.new(0, tabBtnW, 1, -8),
            BackgroundColor3 = Theme.BgTertiary,
            BackgroundTransparency = 1,
            Text             = (icon and icon.." " or "")..name,
            TextColor3       = Theme.TextMuted,
            TextSize         = math.floor(11 * S),
            Font             = Enum.Font.GothamSemibold,
            BorderSizePixel  = 0,
            ZIndex           = 7,
            AutoButtonColor  = false,
            Parent           = TabScroll,
        }, { Corner(7) })

        local TabPage = Make("Frame", {
            Size             = UDim2.new(1, 0, 1, 0),
            Position         = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex           = 3,
            Parent           = ContentClip,
        })

        local Scroll = Make("ScrollingFrame", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = Theme.Accent,
            ScrollBarImageTransparency = 0.45,
            ZIndex                 = 3,
            Parent                 = TabPage,
        }, {
            ListLayout(nil, nil, nil, 7),
            Pad(10, 14, 12, 12),
        })

        local scrollLayout = Scroll:FindFirstChildOfClass("UIListLayout")
        scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 24)
        end)

        local TabObj = {
            _btn    = TabBtn,
            _page   = TabPage,
            _scroll = Scroll,
            _win    = self,
            _name   = name,
        }

        local function ActivateTab()
            for i, t in ipairs(self._tabs) do
                if t ~= TabObj then
                    local tIdx = table.find(self._tabs, TabObj) or 1
                    local goLeft = i < tIdx
                    Tween(t._page, {
                        Position = goLeft and UDim2.new(-1.05, 0, 0, 0) or UDim2.new(1.05, 0, 0, 0),
                    }, TI.Smooth)
                    Tween(t._btn, {
                        TextColor3           = Theme.TextMuted,
                        BackgroundTransparency = 1,
                    }, TI.Fast)
                end
            end

            local prevIdx = self._active and table.find(self._tabs, self._active) or 0
            local thisIdx = table.find(self._tabs, TabObj) or 1
            TabPage.Position = thisIdx > prevIdx and UDim2.new(1.05, 0, 0, 0) or UDim2.new(-1.05, 0, 0, 0)
            Tween(TabPage, {Position = UDim2.new(0, 0, 0, 0)}, TI.Smooth)
            Tween(TabBtn,  {TextColor3 = Theme.Accent, BackgroundTransparency = 0.84}, TI.Fast)

            task.defer(function()
                local bPos = TabBtn.AbsolutePosition
                local bSze = TabBtn.AbsoluteSize
                local barX = bPos.X - TabBar.AbsolutePosition.X
                Tween(TabIndicator, {
                    Position = UDim2.new(0, barX, 1, -2),
                    Size     = UDim2.new(0, bSze.X, 0, 2),
                }, TI.Smooth)
            end)

            self._active = TabObj
        end

        TabBtn.MouseButton1Click:Connect(function()
            if self._active == TabObj then return end
            ActivateTab()
        end)
        TabBtn.MouseEnter:Connect(function()
            if self._active ~= TabObj then
                Tween(TabBtn, {BackgroundTransparency = 0.92}, TI.Fast)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if self._active ~= TabObj then
                Tween(TabBtn, {BackgroundTransparency = 1}, TI.Fast)
            end
        end)

        AddRipple(TabBtn, Theme.Accent)
        table.insert(self._tabs, TabObj)

        if #self._tabs == 1 then
            TabPage.Position = UDim2.new(0, 0, 0, 0)
            Tween(TabBtn, {TextColor3 = Theme.Accent, BackgroundTransparency = 0.84}, TI.Fast)
            task.defer(function()
                local bPos = TabBtn.AbsolutePosition
                local bSze = TabBtn.AbsoluteSize
                local barX = bPos.X - TabBar.AbsolutePosition.X
                TabIndicator.Position = UDim2.new(0, barX, 1, -2)
                TabIndicator.Size     = UDim2.new(0, bSze.X, 0, 2)
            end)
            self._active = TabObj
        else
            TabPage.Position = UDim2.new(1, 0, 0, 0)
        end

        -- ================================================================
        --  ELEMENT FACTORIES
        -- ================================================================

        local EH  = math.floor(42 * S)
        local EH2 = math.floor(56 * S)

        local function BaseElem(h)
            return Make("Frame", {
                Size             = UDim2.new(1, 0, 0, h or EH),
                BackgroundColor3 = Theme.BgSecondary,
                BorderSizePixel  = 0,
                LayoutOrder      = #Scroll:GetChildren(),
                Parent           = Scroll,
            }, { Corner(9) })
        end

        -- ── Section ──────────────────────────────────────────────────
        function TabObj:CreateSection(label)
            local sec = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, math.floor(32 * S)),
                BackgroundTransparency = 1,
                LayoutOrder      = #Scroll:GetChildren(),
                Parent           = Scroll,
            })
            Make("TextLabel", {
                Size             = UDim2.new(0, 0, 1, 0),
                AutomaticSize    = Enum.AutomaticSize.X,
                BackgroundTransparency = 1,
                Text             = "  "..label:upper().."  ",
                TextColor3       = Theme.Accent,
                TextSize         = math.floor(9 * S),
                Font             = Enum.Font.GothamBold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 3,
                Parent           = sec,
            })
            Make("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Theme.White,
                BorderSizePixel  = 0,
                ZIndex           = 2,
                Parent           = sec,
            }, {
                Make("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,   Theme.Accent),
                        ColorSequenceKeypoint.new(0.5, Theme.Purple),
                        ColorSequenceKeypoint.new(1,   Theme.Bg),
                    }),
                }),
            })
        end

        -- ── Label ────────────────────────────────────────────────────
        function TabObj:CreateLabel(text)
            Make("TextLabel", {
                Size             = UDim2.new(1, 0, 0, math.floor(28 * S)),
                BackgroundTransparency = 1,
                Text             = text,
                TextColor3       = Theme.TextMuted,
                TextSize         = math.floor(12 * S),
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextWrapped      = true,
                LayoutOrder      = #Scroll:GetChildren(),
                Parent           = Scroll,
            })
        end

        -- ── Button ───────────────────────────────────────────────────
        function TabObj:CreateButton(c2)
            c2 = c2 or {}
            local bname  = c2.Name     or "Button"
            local bsub   = c2.Sub
            local bicon  = c2.Icon
            local cb     = c2.Callback or function() end
            local bcolor = c2.Color    or Theme.Accent

            local bH  = bsub and EH2 or EH
            local Btn = BaseElem(bH)
            Stroke(bcolor, 1, 0.78).Parent = Btn

            local AccBar = Make("Frame", {
                Size             = UDim2.new(0, 3, 0.5, 0),
                Position         = UDim2.new(0, 0, 0.25, 0),
                BackgroundColor3 = bcolor,
                BorderSizePixel  = 0,
                ZIndex           = 4,
                Parent           = Btn,
            }, { Corner(2) })

            if bicon then
                Make("TextLabel", {
                    Size             = UDim2.new(0, math.floor(26 * S), 0, math.floor(26 * S)),
                    Position         = UDim2.new(0, 14, 0.5, -math.floor(13 * S)),
                    BackgroundColor3 = Color3.fromRGB(
                        math.floor(bcolor.R * 255 * 0.12),
                        math.floor(bcolor.G * 255 * 0.12),
                        math.floor(bcolor.B * 255 * 0.12)
                    ),
                    BorderSizePixel  = 0,
                    Text             = bicon,
                    TextColor3       = bcolor,
                    TextSize         = math.floor(13 * S),
                    Font             = Enum.Font.GothamBold,
                    ZIndex           = 4,
                    Parent           = Btn,
                }, { Corner(6) })
            end

            local textX = bicon and math.floor(50 * S) or 14
            Make("TextLabel", {
                Size             = UDim2.new(1, -(textX + 30), 0, bsub and math.floor(22 * S) or bH),
                Position         = UDim2.new(0, textX, 0, bsub and math.floor(8 * S) or 0),
                BackgroundTransparency = 1,
                Text             = bname,
                TextColor3       = Theme.Text,
                TextSize         = math.floor(13 * S),
                Font             = Enum.Font.GothamSemibold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 4,
                Parent           = Btn,
            })

            if bsub then
                Make("TextLabel", {
                    Size             = UDim2.new(1, -(textX + 30), 0, math.floor(18 * S)),
                    Position         = UDim2.new(0, textX, 0, math.floor(28 * S)),
                    BackgroundTransparency = 1,
                    Text             = bsub,
                    TextColor3       = Theme.TextMuted,
                    TextSize         = math.floor(10 * S),
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 4,
                    Parent           = Btn,
                })
            end

            Make("TextLabel", {
                Size             = UDim2.new(0, 24, 1, 0),
                Position         = UDim2.new(1, -26, 0, 0),
                BackgroundTransparency = 1,
                Text             = "›",
                TextColor3       = bcolor,
                TextSize         = math.floor(20 * S),
                Font             = Enum.Font.GothamBold,
                ZIndex           = 4,
                Parent           = Btn,
            })

            local HitBox = Make("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 5,
                AutoButtonColor  = false,
                Parent           = Btn,
            })

            HitBox.MouseEnter:Connect(function()
                Tween(Btn,    {BackgroundColor3 = Theme.BgHover}, TI.Fast)
                Tween(AccBar, {Size = UDim2.new(0, 3, 0.7, 0), Position = UDim2.new(0, 0, 0.15, 0)}, TI.Fast)
            end)
            HitBox.MouseLeave:Connect(function()
                Tween(Btn,    {BackgroundColor3 = Theme.BgSecondary}, TI.Fast)
                Tween(AccBar, {Size = UDim2.new(0, 3, 0.5, 0), Position = UDim2.new(0, 0, 0.25, 0)}, TI.Fast)
            end)
            HitBox.MouseButton1Click:Connect(function()
                Tween(Btn, {BackgroundColor3 = Color3.fromRGB(
                    math.floor(bcolor.R * 255 * 0.1),
                    math.floor(bcolor.G * 255 * 0.1),
                    math.floor(bcolor.B * 255 * 0.1)
                )}, TI.Fast)
                task.delay(0.14, function() Tween(Btn, {BackgroundColor3 = Theme.BgSecondary}, TI.Normal) end)
                cb()
            end)
            AddRipple(HitBox, bcolor)
        end

        -- ── Toggle ───────────────────────────────────────────────────
        function TabObj:CreateToggle(c2)
            c2 = c2 or {}
            local tname = c2.Name     or "Toggle"
            local tsub  = c2.Sub
            local state = c2.Default  or false
            local cb    = c2.Callback or function() end

            local tH  = tsub and EH2 or EH
            local Row = BaseElem(tH)
            local rowStroke = Stroke(state and Theme.Accent or Theme.BorderMuted, 1, state and 0.6 or 0.2)
            rowStroke.Parent = Row

            Make("TextLabel", {
                Size             = UDim2.new(1, -70, 0, tsub and math.floor(22 * S) or tH),
                Position         = UDim2.new(0, 14, 0, tsub and math.floor(8 * S) or 0),
                BackgroundTransparency = 1,
                Text             = tname,
                TextColor3       = Theme.Text,
                TextSize         = math.floor(13 * S),
                Font             = Enum.Font.GothamSemibold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 4,
                Parent           = Row,
            })

            if tsub then
                Make("TextLabel", {
                    Size             = UDim2.new(1, -70, 0, math.floor(18 * S)),
                    Position         = UDim2.new(0, 14, 0, math.floor(28 * S)),
                    BackgroundTransparency = 1,
                    Text             = tsub,
                    TextColor3       = Theme.TextMuted,
                    TextSize         = math.floor(10 * S),
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 4,
                    Parent           = Row,
                })
            end

            local tw = math.floor(44 * S)
            local th = math.floor(24 * S)
            local Track = Make("Frame", {
                Size             = UDim2.new(0, tw, 0, th),
                Position         = UDim2.new(1, -(tw + 12), 0.5, -th/2),
                BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(30, 30, 46),
                BorderSizePixel  = 0,
                ZIndex           = 4,
                Parent           = Row,
            }, { Corner(th/2) })

            local TrackGlow = Make("UIStroke", {
                Color        = Theme.Accent,
                Thickness    = 1,
                Transparency = state and 0.5 or 1,
                Parent       = Track,
            })

            local ks   = th - 4
            local Knob = Make("Frame", {
                Size             = UDim2.new(0, ks, 0, ks),
                Position         = state and UDim2.new(1, -(ks + 2), 0.5, -ks/2) or UDim2.new(0, 2, 0.5, -ks/2),
                BackgroundColor3 = Theme.White,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = Track,
            }, { Corner(ks/2) })

            local HitBox = Make("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 6,
                AutoButtonColor  = false,
                Parent           = Row,
            })

            local function Refresh(skip)
                local onPos  = UDim2.new(1, -(ks + 2), 0.5, -ks/2)
                local offPos = UDim2.new(0, 2, 0.5, -ks/2)
                local ti     = skip and TI.Fast or TI.Smooth
                Tween(Track,      {BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(30, 30, 46)}, ti)
                Tween(Knob,       {Position = state and onPos or offPos}, ti)
                Tween(TrackGlow,  {Transparency = state and 0.5 or 1}, ti)
                Tween(rowStroke,  {
                    Color        = state and Theme.Accent or Theme.BorderMuted,
                    Transparency = state and 0.6 or 0.2,
                }, ti)
                if not skip then
                    Tween(Knob, {Size = UDim2.new(0, ks + 4, 0, ks + 4)}, TI.Fast)
                    task.delay(0.16, function() Tween(Knob, {Size = UDim2.new(0, ks, 0, ks)}, TI.Bounce) end)
                end
                cb(state)
            end

            HitBox.MouseButton1Click:Connect(function() state = not state; Refresh(false) end)

            local Obj = {}
            function Obj:Set(v) state = v; Refresh(true) end
            function Obj:Get()  return state end
            return Obj
        end

        -- ── Slider ───────────────────────────────────────────────────
        function TabObj:CreateSlider(c2)
            c2 = c2 or {}
            local sname = c2.Name     or "Slider"
            local ssub  = c2.Sub
            local smin  = c2.Min      or 0
            local smax  = c2.Max      or 100
            local sdef  = c2.Default  or smin
            local sdec  = c2.Decimals or 0
            local scol  = c2.Color    or Theme.Accent
            local cb    = c2.Callback or function() end
            local val   = math.clamp(sdef, smin, smax)
            local fmt   = sdec > 0 and ("%."..sdec.."f") or "%d"

            local cH   = math.floor(58 * S)
            local Cont = BaseElem(cH)
            Stroke(scol, 1, 0.78).Parent = Cont
            Pad(10, 10, 14, 14).Parent   = Cont

            Make("TextLabel", {
                Size             = UDim2.new(0.6, 0, 0, math.floor(18 * S)),
                BackgroundTransparency = 1,
                Text             = sname,
                TextColor3       = Theme.Text,
                TextSize         = math.floor(13 * S),
                Font             = Enum.Font.GothamSemibold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 4,
                Parent           = Cont,
            })

            local ValLbl = Make("TextLabel", {
                Size             = UDim2.new(0.4, 0, 0, math.floor(18 * S)),
                Position         = UDim2.new(0.6, 0, 0, 0),
                BackgroundTransparency = 1,
                Text             = string.format(fmt, val),
                TextColor3       = scol,
                TextSize         = math.floor(13 * S),
                Font             = Enum.Font.GothamBold,
                TextXAlignment   = Enum.TextXAlignment.Right,
                ZIndex           = 4,
                Parent           = Cont,
            })

            if ssub then
                Make("TextLabel", {
                    Size             = UDim2.new(1, 0, 0, math.floor(14 * S)),
                    Position         = UDim2.new(0, 0, 0, math.floor(20 * S)),
                    BackgroundTransparency = 1,
                    Text             = ssub,
                    TextColor3       = Theme.TextMuted,
                    TextSize         = math.floor(10 * S),
                    Font             = Enum.Font.Gotham,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 4,
                    Parent           = Cont,
                })
            end

            local trkH = math.floor(5 * S)
            local Track = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, trkH),
                Position         = UDim2.new(0, 0, 1, -math.floor(14 * S)),
                BackgroundColor3 = Color3.fromRGB(30, 30, 46),
                BorderSizePixel  = 0,
                ZIndex           = 4,
                Parent           = Cont,
            }, { Corner(3) })

            local pct  = (val - smin) / (smax - smin)
            local Fill = Make("Frame", {
                Size             = UDim2.new(pct, 0, 1, 0),
                BackgroundColor3 = scol,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = Track,
            }, {
                Corner(3),
                Make("UIGradient", {Color = ColorSequence.new(scol, Theme.Purple), Rotation = 0}),
            })

            local ks   = math.floor(16 * S)
            local Knob = Make("Frame", {
                Size             = UDim2.new(0, ks, 0, ks),
                Position         = UDim2.new(pct, -ks/2, 0.5, -ks/2),
                BackgroundColor3 = Theme.White,
                BorderSizePixel  = 0,
                ZIndex           = 6,
                Parent           = Track,
            }, {
                Corner(ks/2),
                Make("UIStroke", {Color = scol, Thickness = 2, Transparency = 0.3}),
            })

            local Tooltip = Make("Frame", {
                Size             = UDim2.new(0, math.floor(40 * S), 0, math.floor(22 * S)),
                Position         = UDim2.new(pct, -math.floor(20 * S), 0, -math.floor(28 * S)),
                BackgroundColor3 = Theme.BgTertiary,
                BorderSizePixel  = 0,
                ZIndex           = 8,
                Visible          = false,
                Parent           = Track,
            }, {
                Corner(5),
                Stroke(scol, 1, 0.6),
            })

            local TipLbl = Make("TextLabel", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = string.format(fmt, val),
                TextColor3       = scol,
                TextSize         = math.floor(10 * S),
                Font             = Enum.Font.GothamBold,
                ZIndex           = 9,
                Parent           = Tooltip,
            })

            local SliderHit = Make("TextButton", {
                Size             = UDim2.new(1, 0, 0, math.floor(28 * S)),
                Position         = UDim2.new(0, 0, 1, -math.floor(20 * S)),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 7,
                AutoButtonColor  = false,
                Parent           = Cont,
            })

            local sliding = false
            local function UpdateSlider(i)
                local rx  = math.clamp((i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local raw = smin + (smax - smin) * rx
                if sdec == 0 then
                    val = math.floor(raw)
                else
                    local m = 10 ^ sdec
                    val = math.floor(raw * m + 0.5) / m
                end
                local str     = string.format(fmt, val)
                ValLbl.Text   = str
                TipLbl.Text   = str
                Fill.Size     = UDim2.new(rx, 0, 1, 0)
                Knob.Position = UDim2.new(rx, -ks/2, 0.5, -ks/2)
                Tooltip.Position = UDim2.new(rx, -math.floor(20 * S), 0, -math.floor(28 * S))
                cb(val)
            end

            SliderHit.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    Tooltip.Visible = true
                    Tween(Knob, {Size = UDim2.new(0, ks + 4, 0, ks + 4)}, TI.Fast)
                    UpdateSlider(i)
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if not sliding then return end
                if i.UserInputType == Enum.UserInputType.MouseMovement
                or i.UserInputType == Enum.UserInputType.Touch then UpdateSlider(i) end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    if sliding then
                        sliding = false
                        Tooltip.Visible = false
                        Tween(Knob, {Size = UDim2.new(0, ks, 0, ks)}, TI.Bounce)
                    end
                end
            end)
            SliderHit.MouseEnter:Connect(function() Tween(Knob, {Size = UDim2.new(0, ks + 2, 0, ks + 2)}, TI.Fast) end)
            SliderHit.MouseLeave:Connect(function()
                if not sliding then Tween(Knob, {Size = UDim2.new(0, ks, 0, ks)}, TI.Fast) end
            end)

            local Obj = {}
            function Obj:Set(v)
                val = math.clamp(v, smin, smax)
                local rx = (val - smin) / (smax - smin)
                ValLbl.Text = string.format(fmt, val)
                Tween(Fill, {Size = UDim2.new(rx, 0, 1, 0)}, TI.Smooth)
                Tween(Knob, {Position = UDim2.new(rx, -ks/2, 0.5, -ks/2)}, TI.Smooth)
                cb(val)
            end
            function Obj:Get() return val end
            return Obj
        end

        -- ── Dropdown ─────────────────────────────────────────────────
        function TabObj:CreateDropdown(c2)
            c2 = c2 or {}
            local dname  = c2.Name     or "Dropdown"
            local opts   = c2.Options  or {}
            local ddef   = c2.Default  or opts[1]
            local dmulti = c2.Multi    or false
            local cb     = c2.Callback or function() end
            local sel    = dmulti and {} or ddef
            local open   = false

            local optH  = math.floor(34 * S)
            local listH = math.min(#opts, 6) * (optH + 3) + 8

            local Wrap = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, EH),
                BackgroundTransparency = 1,
                ClipsDescendants = false,
                ZIndex           = 5,
                LayoutOrder      = #Scroll:GetChildren(),
                Parent           = Scroll,
            })

            local Header = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, EH),
                BackgroundColor3 = Theme.BgSecondary,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = Wrap,
            }, { Corner(9), Stroke(Theme.Accent, 1, 0.78) })

            Make("TextLabel", {
                Size             = UDim2.new(0.42, 0, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text             = dname,
                TextColor3       = Theme.TextMuted,
                TextSize         = math.floor(11 * S),
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 6,
                Parent           = Header,
            })

            local SelLbl = Make("TextLabel", {
                Size             = UDim2.new(0.44, 0, 1, 0),
                Position         = UDim2.new(0.44, 0, 0, 0),
                BackgroundTransparency = 1,
                Text             = dmulti and "None selected" or (ddef or "Select..."),
                TextColor3       = Theme.Accent,
                TextSize         = math.floor(12 * S),
                Font             = Enum.Font.GothamSemibold,
                TextXAlignment   = Enum.TextXAlignment.Right,
                TextTruncate     = Enum.TextTruncate.AtEnd,
                ZIndex           = 6,
                Parent           = Header,
            })

            local Arrow = Make("TextLabel", {
                Size             = UDim2.new(0, 20, 1, 0),
                Position         = UDim2.new(1, -22, 0, 0),
                BackgroundTransparency = 1,
                Text             = "▾",
                TextColor3       = Theme.Accent,
                TextSize         = math.floor(14 * S),
                Font             = Enum.Font.GothamBold,
                ZIndex           = 6,
                Parent           = Header,
            })

            local ListFrame = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Theme.BgTertiary,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
                ZIndex           = 12,
                Visible          = false,
                Parent           = Wrap,
            }, { Corner(9), Stroke(Theme.Accent, 1, 0.7) })

            local OptionScroll = Make("ScrollingFrame", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                ScrollBarThickness     = 3,
                ScrollBarImageColor3   = Theme.Accent,
                ScrollBarImageTransparency = 0.5,
                ZIndex                 = 13,
                Parent                 = ListFrame,
            }, { ListLayout(nil, nil, nil, 3), Pad(4, 4, 4, 4) })

            local optLayout = OptionScroll:FindFirstChildOfClass("UIListLayout")
            optLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                OptionScroll.CanvasSize = UDim2.new(0, 0, 0, optLayout.AbsoluteContentSize.Y + 8)
            end)

            local function RefreshSel()
                if dmulti then
                    SelLbl.Text = #sel == 0 and "None selected" or (#sel == 1 and sel[1] or #sel.." selected")
                else
                    SelLbl.Text = sel or "Select..."
                end
            end

            for _, opt in ipairs(opts) do
                local isOn = dmulti and table.find(sel, opt) or (opt == sel)
                local OBtn = Make("TextButton", {
                    Size             = UDim2.new(1, 0, 0, optH),
                    BackgroundColor3 = isOn and Theme.BgHover or Theme.BgSecondary,
                    BackgroundTransparency = isOn and 0.2 or 1,
                    Text             = "",
                    BorderSizePixel  = 0,
                    ZIndex           = 14,
                    AutoButtonColor  = false,
                    Parent           = OptionScroll,
                }, { Corner(6) })

                Make("TextLabel", {
                    Size             = UDim2.new(1, -14, 1, 0),
                    Position         = UDim2.new(0, 12, 0, 0),
                    BackgroundTransparency = 1,
                    Text             = opt,
                    TextColor3       = isOn and Theme.Accent or Theme.Text,
                    TextSize         = math.floor(12 * S),
                    Font             = Enum.Font.GothamSemibold,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 15,
                    Parent           = OBtn,
                })

                OBtn.MouseEnter:Connect(function()
                    local on = dmulti and table.find(sel, opt) or (opt == sel)
                    if not on then Tween(OBtn, {BackgroundTransparency = 0.82}, TI.Fast) end
                end)
                OBtn.MouseLeave:Connect(function()
                    local on = dmulti and table.find(sel, opt) or (opt == sel)
                    Tween(OBtn, {BackgroundTransparency = on and 0.2 or 1}, TI.Fast)
                end)

                OBtn.MouseButton1Click:Connect(function()
                    if dmulti then
                        local idx = table.find(sel, opt)
                        if idx then table.remove(sel, idx) else table.insert(sel, opt) end
                        for _, c in ipairs(OptionScroll:GetChildren()) do
                            if c:IsA("TextButton") then
                                local lbl = c:FindFirstChildOfClass("TextLabel")
                                if lbl then
                                    local on2 = table.find(sel, lbl.Text) ~= nil
                                    Tween(c,   {BackgroundTransparency = on2 and 0.2 or 1}, TI.Fast)
                                    Tween(lbl, {TextColor3 = on2 and Theme.Accent or Theme.Text}, TI.Fast)
                                end
                            end
                        end
                        RefreshSel(); cb(sel)
                    else
                        sel  = opt
                        open = false
                        RefreshSel()
                        Tween(Arrow,     {Rotation = 0}, TI.Normal)
                        Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, TI.Smooth)
                        task.delay(0.36, function() ListFrame.Visible = false; Wrap.Size = UDim2.new(1, 0, 0, EH) end)
                        for _, c in ipairs(OptionScroll:GetChildren()) do
                            if c:IsA("TextButton") then
                                local lbl = c:FindFirstChildOfClass("TextLabel")
                                if lbl then
                                    local on2 = lbl.Text == opt
                                    Tween(c,   {BackgroundTransparency = on2 and 0.2 or 1}, TI.Fast)
                                    Tween(lbl, {TextColor3 = on2 and Theme.Accent or Theme.Text}, TI.Fast)
                                end
                            end
                        end
                        cb(opt)
                    end
                end)
                AddRipple(OBtn, Theme.Accent)
            end

            local HitBox = Make("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 7,
                AutoButtonColor  = false,
                Parent           = Header,
            })
            AddRipple(HitBox, Theme.Accent)
            HitBox.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    ListFrame.Visible = true; ListFrame.Size = UDim2.new(1, 0, 0, 0)
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, listH)}, TI.Bounce)
                    Tween(Arrow, {Rotation = 180}, TI.Normal)
                    Wrap.Size = UDim2.new(1, 0, 0, EH + listH + 8)
                else
                    Tween(Arrow, {Rotation = 0}, TI.Normal)
                    Tween(ListFrame, {Size = UDim2.new(1, 0, 0, 0)}, TI.Smooth)
                    task.delay(0.36, function() ListFrame.Visible = false; Wrap.Size = UDim2.new(1, 0, 0, EH) end)
                end
            end)

            local Obj = {}
            function Obj:Set(v) sel = v; RefreshSel(); cb(v) end
            function Obj:Get()  return sel end
            return Obj
        end

        -- ── Input ────────────────────────────────────────────────────
        function TabObj:CreateInput(c2)
            c2 = c2 or {}
            local iname  = c2.Name        or "Input"
            local iph    = c2.Placeholder or "Type here..."
            local cb     = c2.Callback    or function() end

            local Row = BaseElem(EH)
            local rowStroke = Stroke(Theme.Accent, 1, 0.78)
            rowStroke.Parent = Row

            Make("TextLabel", {
                Size             = UDim2.new(0.36, 0, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text             = iname,
                TextColor3       = Theme.TextMuted,
                TextSize         = math.floor(11 * S),
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 4,
                Parent           = Row,
            })

            local Box = Make("TextBox", {
                Size             = UDim2.new(0.59, 0, 1, -10),
                Position         = UDim2.new(0.39, 0, 0, 5),
                BackgroundColor3 = Theme.BgTertiary,
                Text             = "",
                PlaceholderText  = iph,
                TextColor3       = Theme.Text,
                PlaceholderColor3 = Theme.TextMuted,
                TextSize         = math.floor(12 * S),
                Font             = Enum.Font.Gotham,
                BorderSizePixel  = 0,
                ClearTextOnFocus = false,
                ZIndex           = 4,
                Parent           = Row,
            }, { Corner(7), Pad(0, 0, 10, 10) })

            Box.Focused:Connect(function()
                Tween(rowStroke, {Transparency = 0.3}, TI.Fast)
                Tween(Row, {BackgroundColor3 = Theme.BgHover}, TI.Fast)
            end)
            Box.FocusLost:Connect(function(enter)
                Tween(rowStroke, {Transparency = 0.78}, TI.Fast)
                Tween(Row, {BackgroundColor3 = Theme.BgSecondary}, TI.Fast)
                if enter then cb(Box.Text) end
            end)

            local Obj = {}
            function Obj:Get()   return Box.Text end
            function Obj:Set(v)  Box.Text = v end
            function Obj:Clear() Box.Text = "" end
            return Obj
        end

        -- ── Color Picker ─────────────────────────────────────────────
        function TabObj:CreateColorPicker(c2)
            c2 = c2 or {}
            local cpname = c2.Name     or "Color"
            local cpdef  = c2.Default  or Color3.fromRGB(0, 255, 234)
            local cb     = c2.Callback or function() end
            local H, S2, V = Color3.toHSV(cpdef)
            local open     = false
            local pickerH  = math.floor(148 * S)

            local Wrap = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, EH),
                BackgroundTransparency = 1,
                ClipsDescendants = false,
                ZIndex           = 5,
                LayoutOrder      = #Scroll:GetChildren(),
                Parent           = Scroll,
            })

            local Header = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, EH),
                BackgroundColor3 = Theme.BgSecondary,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                Parent           = Wrap,
            }, { Corner(9), Stroke(Theme.Accent, 1, 0.78) })

            Make("TextLabel", {
                Size             = UDim2.new(0.5, 0, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text             = cpname,
                TextColor3       = Theme.Text,
                TextSize         = math.floor(13 * S),
                Font             = Enum.Font.GothamSemibold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 6,
                Parent           = Header,
            })

            local Preview = Make("Frame", {
                Size             = UDim2.new(0, math.floor(28 * S), 0, math.floor(20 * S)),
                Position         = UDim2.new(1, -math.floor(50 * S), 0.5, -math.floor(10 * S)),
                BackgroundColor3 = cpdef,
                BorderSizePixel  = 0,
                ZIndex           = 6,
                Parent           = Header,
            }, { Corner(5), Stroke(Theme.White, 1, 0.7) })

            Make("TextLabel", {
                Size             = UDim2.new(0, 20, 1, 0),
                Position         = UDim2.new(1, -24, 0, 0),
                BackgroundTransparency = 1,
                Text             = "▾",
                TextColor3       = Theme.Accent,
                TextSize         = math.floor(14 * S),
                Font             = Enum.Font.GothamBold,
                ZIndex           = 6,
                Parent           = Header,
            })

            local Panel = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.new(0, 0, 1, 4),
                BackgroundColor3 = Theme.BgTertiary,
                ClipsDescendants = true,
                BorderSizePixel  = 0,
                ZIndex           = 10,
                Visible          = false,
                Parent           = Wrap,
            }, { Corner(9), Stroke(Theme.Accent, 1, 0.7) })

            local HueBar = Make("Frame", {
                Size             = UDim2.new(1, -20, 0, math.floor(14 * S)),
                Position         = UDim2.new(0, 10, 0, math.floor(10 * S)),
                BackgroundColor3 = Theme.White,
                BorderSizePixel  = 0,
                ZIndex           = 11,
                Parent           = Panel,
            }, {
                Corner(4),
                Make("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,     Color3.fromHSV(0,     1, 1)),
                        ColorSequenceKeypoint.new(0.167, Color3.fromHSV(0.167, 1, 1)),
                        ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
                        ColorSequenceKeypoint.new(0.5,   Color3.fromHSV(0.5,   1, 1)),
                        ColorSequenceKeypoint.new(0.667, Color3.fromHSV(0.667, 1, 1)),
                        ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
                        ColorSequenceKeypoint.new(1,     Color3.fromHSV(1,     1, 1)),
                    }),
                }),
            })

            local HueKnob = Make("Frame", {
                Size             = UDim2.new(0, math.floor(8 * S), 1, 4),
                Position         = UDim2.new(H, -math.floor(4 * S), 0, -2),
                BackgroundColor3 = Theme.White,
                BorderSizePixel  = 0,
                ZIndex           = 12,
                Parent           = HueBar,
            }, { Corner(3), Stroke(Theme.Black, 1, 0.5) })

            local SatVal = Make("Frame", {
                Size             = UDim2.new(1, -20, 0, math.floor(70 * S)),
                Position         = UDim2.new(0, 10, 0, math.floor(34 * S)),
                BackgroundColor3 = Color3.fromHSV(H, 1, 1),
                BorderSizePixel  = 0,
                ZIndex           = 11,
                Parent           = Panel,
            }, {
                Corner(6),
                Make("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromHSV(H, 1, 1))}),
                Make("Frame", {
                    Size             = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Theme.Black,
                    BorderSizePixel  = 0,
                    ZIndex           = 12,
                }, {
                    Make("UIGradient", {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        }),
                        Rotation = 90,
                    }),
                }),
            })

            local SVKnob = Make("Frame", {
                Size             = UDim2.new(0, math.floor(12 * S), 0, math.floor(12 * S)),
                Position         = UDim2.new(S2, -math.floor(6 * S), 1 - V, -math.floor(6 * S)),
                BackgroundColor3 = Color3.fromHSV(H, S2, V),
                BorderSizePixel  = 0,
                ZIndex           = 13,
                Parent           = SatVal,
            }, { Corner(999), Stroke(Theme.White, 2, 0.3) })

            local function RefreshColor()
                local c = Color3.fromHSV(H, S2, V)
                Preview.BackgroundColor3 = c
                SVKnob.BackgroundColor3  = c
                SatVal.BackgroundColor3  = Color3.fromHSV(H, 1, 1)
                local g = SatVal:FindFirstChildOfClass("UIGradient")
                if g then g.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromHSV(H,1,1)) end
                cb(c)
            end

            local hueDrag, svDrag = false, false

            HueBar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    hueDrag = true
                    H = math.clamp((i.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                    HueKnob.Position = UDim2.new(H, -math.floor(4 * S), 0, -2)
                    RefreshColor()
                end
            end)
            SatVal.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    svDrag = true
                    S2 = math.clamp((i.Position.X - SatVal.AbsolutePosition.X) / SatVal.AbsoluteSize.X, 0, 1)
                    V  = 1 - math.clamp((i.Position.Y - SatVal.AbsolutePosition.Y) / SatVal.AbsoluteSize.Y, 0, 1)
                    SVKnob.Position = UDim2.new(S2, -math.floor(6 * S), 1 - V, -math.floor(6 * S))
                    RefreshColor()
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType ~= Enum.UserInputType.MouseMovement
                and i.UserInputType ~= Enum.UserInputType.Touch then return end
                if hueDrag then
                    H = math.clamp((i.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                    HueKnob.Position = UDim2.new(H, -math.floor(4 * S), 0, -2)
                    RefreshColor()
                end
                if svDrag then
                    S2 = math.clamp((i.Position.X - SatVal.AbsolutePosition.X) / SatVal.AbsoluteSize.X, 0, 1)
                    V  = 1 - math.clamp((i.Position.Y - SatVal.AbsolutePosition.Y) / SatVal.AbsoluteSize.Y, 0, 1)
                    SVKnob.Position = UDim2.new(S2, -math.floor(6 * S), 1 - V, -math.floor(6 * S))
                    RefreshColor()
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1
                or i.UserInputType == Enum.UserInputType.Touch then
                    hueDrag = false; svDrag = false
                end
            end)

            local HitBox = Make("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 7,
                AutoButtonColor  = false,
                Parent           = Header,
            })
            AddRipple(HitBox, Theme.Accent)
            HitBox.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    Panel.Visible = true; Panel.Size = UDim2.new(1, 0, 0, 0)
                    Tween(Panel, {Size = UDim2.new(1, 0, 0, pickerH)}, TI.Bounce)
                    Wrap.Size = UDim2.new(1, 0, 0, EH + pickerH + 8)
                else
                    Tween(Panel, {Size = UDim2.new(1, 0, 0, 0)}, TI.Smooth)
                    task.delay(0.36, function() Panel.Visible = false; Wrap.Size = UDim2.new(1, 0, 0, EH) end)
                end
            end)

            local Obj = {}
            function Obj:Get() return Color3.fromHSV(H, S2, V) end
            function Obj:Set(c)
                H, S2, V = Color3.toHSV(c)
                HueKnob.Position = UDim2.new(H,  -math.floor(4 * S), 0,     -2)
                SVKnob.Position  = UDim2.new(S2, -math.floor(6 * S), 1 - V, -math.floor(6 * S))
                RefreshColor()
            end
            return Obj
        end

        -- ── Keybind ──────────────────────────────────────────────────
        function TabObj:CreateKeybind(c2)
            c2 = c2 or {}
            local kname   = c2.Name     or "Keybind"
            local kdef    = c2.Default  or Enum.KeyCode.F
            local cb      = c2.Callback or function() end
            local current = kdef
            local binding = false

            local Row = BaseElem(EH)
            Stroke(Theme.Purple, 1, 0.78).Parent = Row

            Make("TextLabel", {
                Size             = UDim2.new(0.55, 0, 1, 0),
                Position         = UDim2.new(0, 14, 0, 0),
                BackgroundTransparency = 1,
                Text             = kname,
                TextColor3       = Theme.Text,
                TextSize         = math.floor(13 * S),
                Font             = Enum.Font.GothamSemibold,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 4,
                Parent           = Row,
            })

            local KeyLbl = Make("TextButton", {
                Size             = UDim2.new(0, math.floor(72 * S), 0, math.floor(26 * S)),
                Position         = UDim2.new(1, -math.floor(82 * S), 0.5, -math.floor(13 * S)),
                BackgroundColor3 = Theme.BgTertiary,
                Text             = tostring(current):gsub("Enum.KeyCode.", ""),
                TextColor3       = Theme.Purple,
                TextSize         = math.floor(11 * S),
                Font             = Enum.Font.GothamBold,
                BorderSizePixel  = 0,
                ZIndex           = 5,
                AutoButtonColor  = false,
                Parent           = Row,
            }, { Corner(6), Stroke(Theme.Purple, 1, 0.6) })

            KeyLbl.MouseButton1Click:Connect(function()
                binding = true
                KeyLbl.Text       = "..."
                KeyLbl.TextColor3 = Theme.Pink
                Tween(KeyLbl, {BackgroundColor3 = Color3.fromRGB(30, 0, 20)}, TI.Fast)
            end)

            UserInputService.InputBegan:Connect(function(i, gp)
                if not binding or gp then return end
                if i.UserInputType == Enum.UserInputType.Keyboard then
                    binding   = false
                    current   = i.KeyCode
                    local kstr = tostring(i.KeyCode):gsub("Enum.KeyCode.", "")
                    KeyLbl.Text       = kstr
                    KeyLbl.TextColor3 = Theme.Purple
                    Tween(KeyLbl, {BackgroundColor3 = Theme.BgTertiary}, TI.Fast)
                    cb(current)
                end
            end)

            local Obj = {}
            function Obj:Get() return current end
            function Obj:Set(k)
                current = k
                KeyLbl.Text = tostring(k):gsub("Enum.KeyCode.", "")
            end
            return Obj
        end

        return TabObj
    end

    return WinObj
end

-- ======================================================================
--  Global notify
-- ======================================================================
function ExtraLib:Notify(c) SendNotification(c) end

return ExtraLib

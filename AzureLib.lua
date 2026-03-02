--[[
    ╔══════════════════════════════════════════════════════╗
    ║  AzureLib — Roblox UI Library                       ║
    ║  Theme: Amethyst  |  Mobile Ready  |  v1.0          ║
    ║  • Minimize → floating circle, click to restore     ║
    ║  • Smooth drag (mouse + touch)                      ║
    ║  • Ripple buttons, animated toggles & sliders       ║
    ║  • Toast notifications                              ║
    ╚══════════════════════════════════════════════════════╝

    USAGE:
        local AzureLib = loadstring(game:HttpGet("URL"))()

        local Window = AzureLib:CreateWindow({
            Title    = "My Script",
            SubTitle = "by you",
        })

        local Tab = Window:AddTab({ Title = "Main", Icon = "⚡" })
        Tab:AddSection("Combat")
        Tab:AddToggle("SilentAim", {
            Title    = "Silent Aim",
            Default  = false,
            Callback = function(v) print(v) end,
        })

        AzureLib:Notify({ Title = "Loaded", Content = "Script ready!", Duration = 4 })
]]

local AzureLib = {}
AzureLib.__index = AzureLib

-- ─────────────────────────────────────────────────────────────────
-- SERVICES
-- ─────────────────────────────────────────────────────────────────
local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS  = game:GetService("RunService")
local LP  = game:GetService("Players").LocalPlayer

-- ─────────────────────────────────────────────────────────────────
-- AMETHYST THEME
-- ─────────────────────────────────────────────────────────────────
local C = {
    WinBg       = Color3.fromRGB(12,  9, 20),
    TitleBar    = Color3.fromRGB(18, 13, 30),
    TabBg       = Color3.fromRGB(15, 11, 25),
    TabHov      = Color3.fromRGB(26, 19, 42),
    TabActive   = Color3.fromRGB(32, 23, 52),
    ContentBg   = Color3.fromRGB(14, 10, 23),
    ElemBg      = Color3.fromRGB(22, 16, 36),
    ElemHov     = Color3.fromRGB(30, 22, 48),
    Accent      = Color3.fromRGB(155, 89, 182),
    AccentHov   = Color3.fromRGB(176, 112, 202),
    AccentDim   = Color3.fromRGB(85,  44, 115),
    AccentGlow  = Color3.fromRGB(120, 60, 160),
    Border      = Color3.fromRGB(60,  42, 90),
    BorderDim   = Color3.fromRGB(38,  26, 60),
    TextPri     = Color3.fromRGB(242, 238, 255),
    TextSec     = Color3.fromRGB(165, 148, 205),
    TextMut     = Color3.fromRGB(105,  90, 142),
    SliderTrack = Color3.fromRGB(35,  25, 55),
    ToggleOff   = Color3.fromRGB(35,  25, 55),
    NotifBg     = Color3.fromRGB(20,  15, 33),
    Success     = Color3.fromRGB(80, 195, 125),
    Warning     = Color3.fromRGB(228, 172, 55),
    Error       = Color3.fromRGB(218, 65,  65),
}

-- ─────────────────────────────────────────────────────────────────
-- INSTANCE HELPERS
-- ─────────────────────────────────────────────────────────────────
local function make(cls, props, parent)
    local i = Instance.new(cls)
    for k, v in next, props or {} do i[k] = v end
    if parent then i.Parent = parent end
    return i
end

local function corner(r, p)
    return make("UICorner", { CornerRadius = UDim.new(0, r) }, p)
end

local function stroke(col, th, p)
    return make("UIStroke", { Color = col, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p)
end

local function pad(t, b, l, r, p)
    return make("UIPadding", {
        PaddingTop    = UDim.new(0, t),
        PaddingBottom = UDim.new(0, b),
        PaddingLeft   = UDim.new(0, l),
        PaddingRight  = UDim.new(0, r),
    }, p)
end

local function list(fd, ha, sp, p)
    return make("UIListLayout", {
        FillDirection       = fd or Enum.FillDirection.Vertical,
        HorizontalAlignment = ha or Enum.HorizontalAlignment.Left,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, sp or 0),
    }, p)
end

-- ─────────────────────────────────────────────────────────────────
-- TWEEN HELPERS
-- ─────────────────────────────────────────────────────────────────
local function tw(obj, t, style, dir, props)
    TS:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out), props):Play()
end

local function springTw(obj, t, props)
    tw(obj, t, Enum.EasingStyle.Back, Enum.EasingDirection.Out, props)
end

-- ─────────────────────────────────────────────────────────────────
-- HOVER ANIMATION
-- ─────────────────────────────────────────────────────────────────
local function addHover(btn, norm, hov)
    btn.MouseEnter:Connect(function()  tw(btn, 0.13, nil, nil, { BackgroundColor3 = hov }) end)
    btn.MouseLeave:Connect(function()  tw(btn, 0.13, nil, nil, { BackgroundColor3 = norm }) end)
end

-- ─────────────────────────────────────────────────────────────────
-- RIPPLE EFFECT (click feedback)
-- ─────────────────────────────────────────────────────────────────
local function addRipple(btn)
    local function doRipple(x, y)
        local abs = btn.AbsolutePosition
        local sz  = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2
        local rx  = (x - abs.X)
        local ry  = (y - abs.Y)
        local rip = make("Frame", {
            Size                 = UDim2.fromOffset(0, 0),
            Position             = UDim2.fromOffset(rx, ry),
            AnchorPoint          = Vector2.new(0.5, 0.5),
            BackgroundColor3     = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.75,
            ZIndex               = btn.ZIndex + 10,
            ClipsDescendants     = false,
        }, btn)
        corner(999, rip)
        tw(rip, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
            Size                 = UDim2.fromOffset(sz, sz),
            BackgroundTransparency = 1,
        })
        game:GetService("Debris"):AddItem(rip, 0.45)
    end
    btn.MouseButton1Click:Connect(function()
        local mp = UIS:GetMouseLocation()
        doRipple(mp.X, mp.Y)
    end)
    btn.TouchTap:Connect(function(touches)
        if touches[1] then doRipple(touches[1].Position.X, touches[1].Position.Y) end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- DRAGGABLE (mouse + touch, clamped to viewport)
-- ─────────────────────────────────────────────────────────────────
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging   = false
    local dragOffset = Vector2.zero

    local function start(pos)
        dragging   = true
        dragOffset = pos - Vector2.new(
            frame.AbsolutePosition.X,
            frame.AbsolutePosition.Y
        )
    end
    local function move(pos)
        if not dragging then return end
        local vp   = workspace.CurrentCamera.ViewportSize
        local sz   = frame.AbsoluteSize
        local np   = pos - dragOffset
        frame.Position = UDim2.fromOffset(
            math.clamp(np.X, 0, vp.X - sz.X),
            math.clamp(np.Y, 0, vp.Y - sz.Y)
        )
    end
    local function stop() dragging = false end

    handle.InputBegan:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            start(Vector2.new(inp.Position.X, inp.Position.Y))
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then stop() end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        local t = inp.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            move(Vector2.new(inp.Position.X, inp.Position.Y))
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- NOTIFICATION SYSTEM
-- ─────────────────────────────────────────────────────────────────
local NotifGui = make("ScreenGui", {
    Name           = "AzureLibNotifs",
    ResetOnSpawn   = false,
    DisplayOrder   = 999,
    IgnoreGuiInset = true,
}, game:GetService("CoreGui"))

local NotifHolder = make("Frame", {
    Name                 = "NotifHolder",
    Size                 = UDim2.fromOffset(300, 0),
    Position             = UDim2.new(1, -310, 1, -10),
    AnchorPoint          = Vector2.new(0, 1),
    BackgroundTransparency = 1,
    AutomaticSize        = Enum.AutomaticSize.Y,
}, NotifGui)
list(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, 6, NotifHolder)

local NOTIF_ICONS = { default = "🔔", success = "✅", warning = "⚠️", error = "❌" }

function AzureLib:Notify(opts)
    local title    = opts.Title    or "Notice"
    local content  = opts.Content  or ""
    local duration = opts.Duration or 4
    local ntype    = opts.Type     or "default"
    local icon     = NOTIF_ICONS[ntype] or NOTIF_ICONS.default
    local accentC  = (ntype == "success" and C.Success)
                  or (ntype == "warning" and C.Warning)
                  or (ntype == "error"   and C.Error)
                  or C.Accent

    local card = make("Frame", {
        Name                 = "Notif",
        Size                 = UDim2.fromOffset(290, 1),
        AutomaticSize        = Enum.AutomaticSize.Y,
        BackgroundColor3     = C.NotifBg,
        BackgroundTransparency = 1,
        ClipsDescendants     = false,
    }, NotifHolder)
    corner(10, card)
    stroke(C.BorderDim, 1, card)

    -- accent left bar
    make("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentC,
        BorderSizePixel  = 0,
    }, card)
    corner(3, (card:FindFirstChildWhichIsA("Frame") or card))

    local inner = make("Frame", {
        Size             = UDim2.new(1, -3, 1, 0),
        Position         = UDim2.fromOffset(3, 0),
        BackgroundTransparency = 1,
        AutomaticSize    = Enum.AutomaticSize.Y,
    }, card)
    pad(10, 10, 10, 10, inner)

    make("TextLabel", {
        Size             = UDim2.new(1, -22, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text             = icon .. "  " .. title,
        TextColor3       = C.TextPri,
        Font             = Enum.Font.GothamBold,
        TextSize         = 14,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        RichText         = true,
    }, inner)

    make("TextLabel", {
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        Position         = UDim2.fromOffset(0, 22),
        BackgroundTransparency = 1,
        Text             = content,
        TextColor3       = C.TextSec,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
    }, inner)

    -- progress bar
    local progress = make("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = accentC,
        BorderSizePixel  = 0,
    }, card)

    -- animate in
    tw(card, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {
        BackgroundTransparency = 0,
    })
    tw(progress, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {
        Size = UDim2.new(0, 0, 0, 2),
    })

    task.delay(duration, function()
        tw(card, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In, {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(290, 0),
        })
        task.delay(0.3, function() card:Destroy() end)
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- CREATE WINDOW
-- ─────────────────────────────────────────────────────────────────
function AzureLib:CreateWindow(opts)
    local title    = opts.Title    or "Azure"
    local subtitle = opts.SubTitle or ""
    local winW     = (opts.Size and opts.Size.X.Offset) or 560
    local winH     = (opts.Size and opts.Size.Y.Offset) or 390
    local vp       = workspace.CurrentCamera.ViewportSize
    local startX   = opts.Position and opts.Position.X.Offset or math.floor((vp.X - winW) / 2)
    local startY   = opts.Position and opts.Position.Y.Offset or math.floor((vp.Y - winH) / 2)

    -- Root ScreenGui
    local sg = make("ScreenGui", {
        Name           = "AzureLib_" .. title,
        ResetOnSpawn   = false,
        DisplayOrder   = 100,
        IgnoreGuiInset = true,
    }, game:GetService("CoreGui"))

    -- UIScale for minimize animation
    local scale = make("UIScale", { Scale = 1 })

    -- Main window frame
    local win = make("Frame", {
        Name             = "Window",
        Size             = UDim2.fromOffset(winW, winH),
        Position         = UDim2.fromOffset(startX, startY),
        BackgroundColor3 = C.WinBg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, sg)
    scale.Parent = win
    corner(12, win)
    stroke(C.Border, 1, win)

    -- Drop shadow
    local shadow = make("ImageLabel", {
        Name                 = "Shadow",
        Size                 = UDim2.new(1, 40, 1, 40),
        Position             = UDim2.fromOffset(-20, -10),
        BackgroundTransparency = 1,
        Image                = "rbxassetid://6014261993",
        ImageColor3          = Color3.fromRGB(0, 0, 0),
        ImageTransparency    = 0.5,
        ScaleType            = Enum.ScaleType.Slice,
        SliceCenter          = Rect.new(49, 49, 450, 450),
        ZIndex               = 0,
    }, win)

    -- ── Title Bar ─────────────────────────────────────────────────
    local titleBar = make("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = C.TitleBar,
        BorderSizePixel  = 0,
        ZIndex           = 5,
    }, win)
    -- bottom border on title bar
    make("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
    }, titleBar)

    -- Title text
    make("TextLabel", {
        Size             = UDim2.new(1, -100, 1, 0),
        Position         = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Text             = title .. (subtitle ~= "" and ("  <font color='#9B59B6' size='13'>" .. subtitle .. "</font>") or ""),
        RichText         = true,
        TextColor3       = C.TextPri,
        Font             = Enum.Font.GothamBold,
        TextSize         = 15,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 6,
    }, titleBar)

    -- Minimize button
    local minBtn = make("TextButton", {
        Size             = UDim2.fromOffset(30, 30),
        Position         = UDim2.new(1, -68, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = C.ElemBg,
        Text             = "–",
        TextColor3       = C.TextSec,
        Font             = Enum.Font.GothamBold,
        TextSize         = 18,
        BorderSizePixel  = 0,
        ZIndex           = 7,
        AutoButtonColor  = false,
    }, titleBar)
    corner(8, minBtn)
    addHover(minBtn, C.ElemBg, C.ElemHov)

    -- Close button
    local closeBtn = make("TextButton", {
        Size             = UDim2.fromOffset(30, 30),
        Position         = UDim2.new(1, -32, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(50, 20, 20),
        Text             = "✕",
        TextColor3       = Color3.fromRGB(220, 100, 100),
        Font             = Enum.Font.GothamBold,
        TextSize         = 14,
        BorderSizePixel  = 0,
        ZIndex           = 7,
        AutoButtonColor  = false,
    }, titleBar)
    corner(8, closeBtn)
    addHover(closeBtn, Color3.fromRGB(50, 20, 20), Color3.fromRGB(180, 40, 40))
    closeBtn.MouseButton1Click:Connect(function()
        tw(win, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In,
            { BackgroundTransparency = 1 })
        tw(scale, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In,
            { Scale = 0.85 })
        task.delay(0.22, function() sg:Destroy() end)
    end)

    makeDraggable(win, titleBar)

    -- ── Mini Circle (shown when minimized) ────────────────────────
    local miniCircle = make("TextButton", {
        Name             = "MiniCircle",
        Size             = UDim2.fromOffset(0, 0),
        Position         = UDim2.fromOffset(startX, startY),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.Accent,
        Text             = string.sub(title, 1, 1):upper(),
        TextColor3       = Color3.fromRGB(255, 255, 255),
        Font             = Enum.Font.GothamBold,
        TextSize         = 20,
        BorderSizePixel  = 0,
        AutoButtonColor  = false,
        Visible          = false,
        ZIndex           = 200,
    }, sg)
    corner(999, miniCircle)
    stroke(C.AccentHov, 2, miniCircle)
    make("UIScale", { Scale = 1 }, miniCircle)
    makeDraggable(miniCircle, miniCircle)

    -- pulse glow on mini circle
    local glowing = false
    local function startPulse()
        glowing = true
        task.spawn(function()
            while glowing do
                tw(miniCircle, 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                    { BackgroundColor3 = C.AccentHov })
                task.wait(0.7)
                tw(miniCircle, 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                    { BackgroundColor3 = C.AccentDim })
                task.wait(0.7)
            end
        end)
    end
    local function stopPulse()
        glowing = false
        tw(miniCircle, 0.2, nil, nil, { BackgroundColor3 = C.Accent })
    end

    local minimized = false

    local function minimize()
        minimized = true
        -- save window center for circle spawn position
        local wp = win.AbsolutePosition
        local ws = win.AbsoluteSize
        local cx = wp.X + ws.X * 0.5
        local cy = wp.Y + ws.Y * 0.5

        tw(scale, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In, { Scale = 0 })
        task.delay(0.15, function()
            win.Visible = false
            -- spawn mini circle at window center
            miniCircle.Position = UDim2.fromOffset(cx, cy)
            miniCircle.Size     = UDim2.fromOffset(0, 0)
            miniCircle.Visible  = true
            springTw(miniCircle, 0.4, { Size = UDim2.fromOffset(58, 58) })
            startPulse()
        end)
    end

    local function restore()
        minimized = false
        stopPulse()
        -- animate circle out
        tw(miniCircle, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In,
            { Size = UDim2.fromOffset(0, 0) })
        task.delay(0.16, function()
            miniCircle.Visible = false
            win.Visible        = true
            scale.Scale        = 0
            tw(scale, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, { Scale = 1 })
        end)
    end

    minBtn.MouseButton1Click:Connect(minimize)
    miniCircle.MouseButton1Click:Connect(restore)

    -- ── Tab Bar (left sidebar) ─────────────────────────────────────
    local tabBar = make("Frame", {
        Name             = "TabBar",
        Size             = UDim2.new(0, 130, 1, -46),
        Position         = UDim2.new(0, 0, 0, 46),
        BackgroundColor3 = C.TabBg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, win)
    -- right border
    make("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = C.Border,
        BorderSizePixel  = 0,
    }, tabBar)

    local tabScroll = make("ScrollingFrame", {
        Size                    = UDim2.new(1, 0, 1, -10),
        Position                = UDim2.fromOffset(0, 6),
        BackgroundTransparency  = 1,
        ScrollBarThickness      = 0,
        ScrollingDirection      = Enum.ScrollingDirection.Y,
        CanvasSize              = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize     = Enum.AutomaticSize.Y,
        BorderSizePixel         = 0,
    }, tabBar)
    pad(4, 4, 6, 6, tabScroll)
    list(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, 3, tabScroll)

    -- ── Content Area ───────────────────────────────────────────────
    local contentArea = make("Frame", {
        Name             = "ContentArea",
        Size             = UDim2.new(1, -131, 1, -46),
        Position         = UDim2.new(0, 131, 0, 46),
        BackgroundColor3 = C.ContentBg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, win)

    -- ── Window object ──────────────────────────────────────────────
    local Window    = {}
    local tabs      = {}
    local activeTab = nil

    local function setActiveTab(tabObj)
        if activeTab == tabObj then return end
        -- deactivate old
        if activeTab then
            tw(activeTab._btn, 0.15, nil, nil, { BackgroundColor3 = Color3.fromRGB(0,0,0) })
            activeTab._btn.BackgroundTransparency = 1
            local ind = activeTab._btn:FindFirstChild("Indicator")
            if ind then tw(ind, 0.15, nil, nil, { BackgroundTransparency = 1 }) end
            local lbl = activeTab._btn:FindFirstChild("Label")
            if lbl then tw(lbl, 0.15, nil, nil, { TextColor3 = C.TextSec }) end
            -- fade out
            tw(activeTab._page, 0.15, nil, nil, { BackgroundTransparency = 1 })
            task.delay(0.15, function()
                activeTab._page.Visible = false
            end)
        end
        activeTab = tabObj
        -- activate new
        tabObj._btn.BackgroundTransparency = 0
        tw(tabObj._btn, 0.15, nil, nil, { BackgroundColor3 = C.TabActive })
        local ind = tabObj._btn:FindFirstChild("Indicator")
        if ind then tw(ind, 0.15, nil, nil, { BackgroundTransparency = 0 }) end
        local lbl = tabObj._btn:FindFirstChild("Label")
        if lbl then tw(lbl, 0.15, nil, nil, { TextColor3 = C.TextPri }) end
        -- fade in
        tabObj._page.Visible          = true
        tabObj._page.BackgroundTransparency = 1
        tw(tabObj._page, 0.2, nil, nil, { BackgroundTransparency = 0 })
    end

    function Window:AddTab(opts)
        local tabTitle = opts.Title or "Tab"
        local tabIcon  = opts.Icon  or ""

        -- Tab button
        local btn = make("TextButton", {
            Name                 = tabTitle,
            Size                 = UDim2.new(1, 0, 0, 36),
            BackgroundColor3     = C.TabActive,
            BackgroundTransparency = 1,
            Text                 = "",
            BorderSizePixel      = 0,
            AutoButtonColor      = false,
            ClipsDescendants     = false,
        }, tabScroll)
        corner(8, btn)

        -- Accent indicator on left
        local indicator = make("Frame", {
            Name             = "Indicator",
            Size             = UDim2.new(0, 3, 0.6, 0),
            Position         = UDim2.new(0, -2, 0.2, 0),
            BackgroundColor3 = C.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
        }, btn)
        corner(4, indicator)

        -- Icon + label row
        make("TextLabel", {
            Name             = "Icon",
            Size             = UDim2.fromOffset(22, 36),
            Position         = UDim2.fromOffset(8, 0),
            BackgroundTransparency = 1,
            Text             = tabIcon,
            TextColor3       = C.TextSec,
            Font             = Enum.Font.Gotham,
            TextSize         = 15,
        }, btn)

        make("TextLabel", {
            Name             = "Label",
            Size             = UDim2.new(1, -35, 1, 0),
            Position         = UDim2.fromOffset(32, 0),
            BackgroundTransparency = 1,
            Text             = tabTitle,
            TextColor3       = C.TextSec,
            Font             = Enum.Font.Gotham,
            TextSize         = 13,
            TextXAlignment   = Enum.TextXAlignment.Left,
        }, btn)

        -- Hover highlight
        btn.MouseEnter:Connect(function()
            if activeTab and activeTab._btn == btn then return end
            tw(btn, 0.12, nil, nil, { BackgroundColor3 = C.TabHov, BackgroundTransparency = 0 })
        end)
        btn.MouseLeave:Connect(function()
            if activeTab and activeTab._btn == btn then return end
            tw(btn, 0.12, nil, nil, { BackgroundTransparency = 1 })
        end)

        -- Content page
        local page = make("ScrollingFrame", {
            Name                   = tabTitle .. "_Page",
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundColor3       = C.ContentBg,
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = C.Accent,
            ScrollingDirection     = Enum.ScrollingDirection.Y,
            CanvasSize             = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize    = Enum.AutomaticSize.Y,
            Visible                = false,
            ClipsDescendants       = true,
        }, contentArea)
        pad(10, 14, 12, 12, page)
        list(Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, 6, page)

        local Tab = { _btn = btn, _page = page }

        btn.MouseButton1Click:Connect(function()
            setActiveTab(Tab)
        end)

        -- auto-select first tab
        if #tabs == 0 then
            setActiveTab(Tab)
        end
        table.insert(tabs, Tab)

        -- ── ELEMENTS ──────────────────────────────────────────────

        function Tab:AddSection(name)
            local row = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
            }, page)
            make("TextLabel", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = name,
                TextColor3       = C.Accent,
                Font             = Enum.Font.GothamBold,
                TextSize         = 11,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, row)
            make("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = C.BorderDim,
                BorderSizePixel  = 0,
            }, row)
        end

        function Tab:AddParagraph(opts)
            local frame = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = C.ElemBg,
                BorderSizePixel  = 0,
            }, page)
            corner(8, frame)
            stroke(C.BorderDim, 1, frame)
            pad(10, 10, 12, 12, frame)
            list(nil, nil, 4, frame)

            if opts.Title and opts.Title ~= "" then
                make("TextLabel", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    AutomaticSize    = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Text             = opts.Title,
                    TextColor3       = C.TextPri,
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    TextWrapped      = true,
                }, frame)
            end
            make("TextLabel", {
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text             = opts.Content or "",
                TextColor3       = C.TextSec,
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextWrapped      = true,
            }, frame)
        end

        function Tab:AddButton(opts)
            local btn2 = make("TextButton", {
                Size             = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = C.ElemBg,
                Text             = "",
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                ClipsDescendants = true,
            }, page)
            corner(8, btn2)
            stroke(C.BorderDim, 1, btn2)

            make("TextLabel", {
                Size             = UDim2.new(1, -20, 1, 0),
                Position         = UDim2.fromOffset(12, 0),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Button",
                TextColor3       = C.Accent,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, btn2)

            addHover(btn2, C.ElemBg, C.ElemHov)
            addRipple(btn2)
            btn2.MouseButton1Click:Connect(function()
                if opts.Callback then opts.Callback() end
            end)
        end

        function Tab:AddToggle(id, opts)
            local value = opts.Default or false

            local row = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = C.ElemBg,
                BorderSizePixel  = 0,
                ClipsDescendants = false,
            }, page)
            corner(8, row)
            stroke(C.BorderDim, 1, row)
            addHover(row, C.ElemBg, C.ElemHov)

            -- Labels
            make("TextLabel", {
                Size             = UDim2.new(1, -60, 0, 0),
                Position         = UDim2.fromOffset(12, 10),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text             = opts.Title or "",
                TextColor3       = C.TextPri,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                TextWrapped      = true,
            }, row)

            if opts.Description and opts.Description ~= "" then
                make("TextLabel", {
                    Size             = UDim2.new(1, -60, 0, 0),
                    Position         = UDim2.fromOffset(12, 25),
                    AutomaticSize    = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Text             = opts.Description,
                    TextColor3       = C.TextSec,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    TextWrapped      = true,
                }, row)
            end

            -- Toggle track
            local track = make("Frame", {
                Size             = UDim2.fromOffset(38, 22),
                Position         = UDim2.new(1, -50, 0.5, 0),
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = value and C.Accent or C.ToggleOff,
                BorderSizePixel  = 0,
            }, row)
            corner(11, track)

            -- Toggle knob
            local knob = make("Frame", {
                Size             = UDim2.fromOffset(16, 16),
                Position         = value and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel  = 0,
            }, track)
            corner(99, knob)
            make("UIDropShadowEffect" ~= "x" and "Frame" or "Frame", {
                Size             = UDim2.fromOffset(12, 12),
                Position         = UDim2.fromOffset(2, 2),
                BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                BackgroundTransparency = 1,
            }, knob) -- placeholder for shadow (Roblox limitation)

            local function updateVisual(v)
                tw(track, 0.2, nil, nil, { BackgroundColor3 = v and C.Accent or C.ToggleOff })
                tw(knob,  0.2, Enum.EasingStyle.Quart, nil,
                    { Position = v and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3) })
            end

            local clickArea = make("TextButton", {
                Size             = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text             = "",
                ZIndex           = 10,
            }, row)

            clickArea.MouseButton1Click:Connect(function()
                value = not value
                updateVisual(value)
                if opts.Callback then opts.Callback(value) end
            end)

            if value then updateVisual(true) end

            local ToggleObj = {}
            function ToggleObj:Set(v)
                value = v
                updateVisual(v)
                if opts.Callback then opts.Callback(v) end
            end
            function ToggleObj:Get() return value end
            return ToggleObj
        end

        function Tab:AddSlider(id, opts)
            local min     = opts.Min     or 0
            local max     = opts.Max     or 100
            local default = opts.Default or min
            local round   = opts.Rounding or 0
            local value   = default

            local function roundVal(v)
                if round == 0 then return math.floor(v + 0.5) end
                local m = 10 ^ round
                return math.floor(v * m + 0.5) / m
            end

            local frame = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 56),
                BackgroundColor3 = C.ElemBg,
                BorderSizePixel  = 0,
            }, page)
            corner(8, frame)
            stroke(C.BorderDim, 1, frame)
            pad(10, 10, 12, 12, frame)

            local titleRow = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
            }, frame)

            make("TextLabel", {
                Size             = UDim2.new(1, -50, 1, 0),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Slider",
                TextColor3       = C.TextPri,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, titleRow)

            local valLabel = make("TextLabel", {
                Size             = UDim2.new(0, 48, 1, 0),
                Position         = UDim2.new(1, -48, 0, 0),
                BackgroundTransparency = 1,
                Text             = tostring(roundVal(value)),
                TextColor3       = C.Accent,
                Font             = Enum.Font.GothamBold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Right,
            }, titleRow)

            -- Track
            local track = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 6),
                Position         = UDim2.fromOffset(0, 22),
                BackgroundColor3 = C.SliderTrack,
                BorderSizePixel  = 0,
            }, frame)
            corner(4, track)

            -- Fill
            local fill = make("Frame", {
                Size             = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = C.Accent,
                BorderSizePixel  = 0,
            }, track)
            corner(4, fill)

            -- Knob
            local knob = make("Frame", {
                Size             = UDim2.fromOffset(16, 16),
                Position         = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel  = 0,
                ZIndex           = 3,
            }, track)
            corner(99, knob)

            -- Drag logic
            local dragging = false

            local function setFromX(absX)
                local trackAbs = track.AbsolutePosition.X
                local trackW   = track.AbsoluteSize.X
                local t2       = math.clamp((absX - trackAbs) / trackW, 0, 1)
                value          = roundVal(min + t2 * (max - min))
                fill.Size      = UDim2.new(t2, 0, 1, 0)
                knob.Position  = UDim2.new(t2, 0, 0.5, 0)
                valLabel.Text  = tostring(value)
                if opts.Callback then opts.Callback(value) end
            end

            track.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    setFromX(inp.Position.X)
                    tw(knob, 0.1, nil, nil, { Size = UDim2.fromOffset(20, 20) })
                    inp.Changed:Connect(function()
                        if inp.UserInputState == Enum.UserInputState.End then
                            dragging = false
                            tw(knob, 0.15, nil, nil, { Size = UDim2.fromOffset(16, 16) })
                        end
                    end)
                end
            end)
            UIS.InputChanged:Connect(function(inp)
                if not dragging then return end
                if inp.UserInputType == Enum.UserInputType.MouseMovement
                or inp.UserInputType == Enum.UserInputType.Touch then
                    setFromX(inp.Position.X)
                end
            end)

            local SliderObj = {}
            function SliderObj:Set(v)
                v     = math.clamp(roundVal(v), min, max)
                value = v
                local t2 = (v - min) / (max - min)
                fill.Size      = UDim2.new(t2, 0, 1, 0)
                knob.Position  = UDim2.new(t2, 0, 0.5, 0)
                valLabel.Text  = tostring(v)
                if opts.Callback then opts.Callback(v) end
            end
            function SliderObj:Get() return value end
            return SliderObj
        end

        function Tab:AddDropdown(id, opts)
            local values  = opts.Values  or {}
            local defIdx  = opts.Default or 1
            local current = values[defIdx] or (values[1] or "")
            local open    = false

            local wrap = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 38),
                BackgroundTransparency = 1,
                ClipsDescendants = false,
                ZIndex           = 20,
            }, page)

            local header = make("TextButton", {
                Size             = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = C.ElemBg,
                Text             = "",
                BorderSizePixel  = 0,
                AutoButtonColor  = false,
                ClipsDescendants = true,
                ZIndex           = 20,
            }, wrap)
            corner(8, header)
            stroke(C.BorderDim, 1, header)
            addHover(header, C.ElemBg, C.ElemHov)

            make("TextLabel", {
                Size             = UDim2.new(1, -50, 1, 0),
                Position         = UDim2.fromOffset(12, 0),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Dropdown",
                TextColor3       = C.TextSec,
                Font             = Enum.Font.Gotham,
                TextSize         = 12,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 21,
            }, header)

            local selLabel = make("TextLabel", {
                Size             = UDim2.new(1, -30, 1, 0),
                Position         = UDim2.fromOffset(12, 0),
                BackgroundTransparency = 1,
                Text             = current,
                TextColor3       = C.TextPri,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ZIndex           = 22,
            }, header)

            -- Arrow
            local arrow = make("TextLabel", {
                Size             = UDim2.fromOffset(20, 38),
                Position         = UDim2.new(1, -24, 0, 0),
                BackgroundTransparency = 1,
                Text             = "▾",
                TextColor3       = C.Accent,
                Font             = Enum.Font.GothamBold,
                TextSize         = 14,
                ZIndex           = 22,
            }, header)

            -- Dropdown list
            local list2 = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                Position         = UDim2.fromOffset(0, 40),
                BackgroundColor3 = C.ElemBg,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
                ZIndex           = 50,
                Visible          = false,
            }, wrap)
            corner(8, list2)
            stroke(C.Border, 1, list2)
            local listLayout2 = list(nil, nil, 0, list2)

            local function closeDD()
                open = false
                tw(arrow, 0.15, nil, nil, { Rotation = 0 })
                tw(list2, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In,
                    { Size = UDim2.new(1, 0, 0, 0) })
                task.delay(0.16, function() list2.Visible = false end)
            end

            local itemH = 32
            local function openDD()
                open = true
                list2.Visible = true
                list2.Size    = UDim2.new(1, 0, 0, 0)
                tw(arrow, 0.15, nil, nil, { Rotation = 180 })
                tw(list2, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out,
                    { Size = UDim2.new(1, 0, 0, #values * itemH + 6) })
            end

            header.MouseButton1Click:Connect(function()
                if open then closeDD() else openDD() end
            end)

            for _, v in ipairs(values) do
                local item = make("TextButton", {
                    Size             = UDim2.new(1, 0, 0, itemH),
                    BackgroundColor3 = C.ElemBg,
                    Text             = "",
                    BorderSizePixel  = 0,
                    AutoButtonColor  = false,
                    ZIndex           = 51,
                }, list2)

                make("TextLabel", {
                    Size             = UDim2.new(1, -20, 1, 0),
                    Position         = UDim2.fromOffset(12, 0),
                    BackgroundTransparency = 1,
                    Text             = v,
                    TextColor3       = (v == current) and C.Accent or C.TextPri,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 13,
                    TextXAlignment   = Enum.TextXAlignment.Left,
                    ZIndex           = 52,
                }, item)

                addHover(item, C.ElemBg, C.ElemHov)
                item.MouseButton1Click:Connect(function()
                    current        = v
                    selLabel.Text  = v
                    -- update label colors
                    for _, child in ipairs(list2:GetChildren()) do
                        if child:IsA("TextButton") then
                            local lbl2 = child:FindFirstChildWhichIsA("TextLabel")
                            if lbl2 then
                                lbl2.TextColor3 = (lbl2.Text == v) and C.Accent or C.TextPri
                            end
                        end
                    end
                    closeDD()
                    if opts.Callback then opts.Callback(v) end
                end)
            end

            local DDObj = {}
            function DDObj:Set(v) current = v; selLabel.Text = v end
            function DDObj:Get() return current end
            return DDObj
        end

        function Tab:AddInput(id, opts)
            local frame = make("Frame", {
                Size             = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = C.ElemBg,
                BorderSizePixel  = 0,
            }, page)
            corner(8, frame)
            stroke(C.BorderDim, 1, frame)

            make("TextLabel", {
                Size             = UDim2.new(1, -20, 0, 18),
                Position         = UDim2.fromOffset(12, 6),
                BackgroundTransparency = 1,
                Text             = opts.Title or "Input",
                TextColor3       = C.TextSec,
                Font             = Enum.Font.Gotham,
                TextSize         = 11,
                TextXAlignment   = Enum.TextXAlignment.Left,
            }, frame)

            local box = make("TextBox", {
                Size             = UDim2.new(1, -20, 0, 18),
                Position         = UDim2.fromOffset(12, 22),
                BackgroundTransparency = 1,
                Text             = opts.Default or "",
                PlaceholderText  = opts.Placeholder or "Enter value...",
                PlaceholderColor3 = C.TextMut,
                TextColor3       = C.TextPri,
                Font             = Enum.Font.GothamSemibold,
                TextSize         = 13,
                TextXAlignment   = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
            }, frame)

            -- bottom border that lights up on focus
            local focusBorder = make("Frame", {
                Size             = UDim2.new(0, 0, 0, 1),
                Position         = UDim2.new(0, 10, 1, -1),
                BackgroundColor3 = C.Accent,
                BorderSizePixel  = 0,
            }, frame)

            box.Focused:Connect(function()
                tw(focusBorder, 0.2, nil, nil, { Size = UDim2.new(1, -20, 0, 1) })
            end)
            box.FocusLost:Connect(function(enter)
                tw(focusBorder, 0.2, nil, nil, { Size = UDim2.new(0, 0, 0, 1) })
                if opts.Callback then opts.Callback(box.Text, enter) end
            end)

            local InputObj = {}
            function InputObj:Set(v) box.Text = v end
            function InputObj:Get() return box.Text end
            return InputObj
        end

        return Tab
    end -- AddTab

    function Window:Minimize() minimize() end
    function Window:Restore()  restore()  end

    return Window
end -- CreateWindow

return AzureLib

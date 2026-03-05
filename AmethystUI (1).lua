--[[
╔══════════════════════════════════════════════════════════╗
║           AmethystUI  ·  v2.0  ·  Executor Ready         ║
║      Faithful Fluent Amethyst Theme  ·  Single File      ║
╚══════════════════════════════════════════════════════════╝
    Icons   : Verified Lucide IDs from Fluent/Icons.lua
    Theme   : Direct port of Fluent's Amethyst palette
    Notifs  : Slide-in stack, auto-dismiss, type colours
    Elements: Button · Toggle · Slider · Input · Paragraph
              Label · Section · Premium Tab
]]

-- ══════════════════════════════════════
--               SERVICES
-- ══════════════════════════════════════
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ══════════════════════════════════════
--    AMETHYST THEME  (from Fluent source)
-- ══════════════════════════════════════
local T = {
    Accent          = Color3.fromRGB(97,  62,  167),
    AccentHover     = Color3.fromRGB(115, 78,  190),
    AccentDark      = Color3.fromRGB(68,  40,  120),
    AccentGlow      = Color3.fromRGB(85,  57,  139),

    WindowBg        = Color3.fromRGB(20,  18,  28),
    WindowBg2       = Color3.fromRGB(30,  22,  45),
    GradientTop     = Color3.fromRGB(85,  57,  139),
    GradientBot     = Color3.fromRGB(40,  25,  65),

    TitleBarBg      = Color3.fromRGB(28,  20,  44),
    TitleBarLine    = Color3.fromRGB(95,  75,  110),

    TabBg           = Color3.fromRGB(25,  18,  40),
    TabActive       = Color3.fromRGB(52,  38,  80),
    TabHover        = Color3.fromRGB(38,  28,  62),
    TabText         = Color3.fromRGB(160, 140, 180),

    ElementColor    = Color3.fromRGB(140, 120, 160),
    ElementBorder   = Color3.fromRGB(60,  50,  70),
    ElementBorder2  = Color3.fromRGB(100, 90,  110),

    ToggleSlider    = Color3.fromRGB(140, 120, 160),
    ToggleOn        = Color3.fromRGB(97,  62,  167),
    ToggleKnob      = Color3.fromRGB(255, 250, 255),
    ToggleKnobOn    = Color3.fromRGB(20,  10,  35),

    SliderRail      = Color3.fromRGB(140, 120, 160),
    SliderFill      = Color3.fromRGB(97,  62,  167),

    InputFocused    = Color3.fromRGB(20,  10,  30),
    InputIndicator  = Color3.fromRGB(170, 150, 190),
    InputBorder     = Color3.fromRGB(100, 90,  110),

    Text            = Color3.fromRGB(240, 240, 240),
    SubText         = Color3.fromRGB(170, 170, 170),
    TextDim         = Color3.fromRGB(120, 105, 140),

    NotifBg         = Color3.fromRGB(30,  22,  48),
    NotifBorder     = Color3.fromRGB(85,  65,  110),

    SectionLine     = Color3.fromRGB(65,  50,  88),
}

local ETRANS      = 0.87
local ETRANS_HVR  = 0.83
local ETRANS_DOWN = 0.91

-- ══════════════════════════════════════
--   VERIFIED ICONS (Fluent/Icons.lua)
-- ══════════════════════════════════════
local Icons = {
    ["home"]           = "rbxassetid://10723407389",
    ["settings"]       = "rbxassetid://10734950309",
    ["menu"]           = "rbxassetid://10734887784",
    ["list"]           = "rbxassetid://10723433811",
    ["grid"]           = "rbxassetid://10723404936",
    ["layers"]         = "rbxassetid://10723424505",
    ["move"]           = "rbxassetid://10734900011",
    ["maximize"]       = "rbxassetid://10734886735",
    ["maximize-2"]     = "rbxassetid://10734886496",
    ["minimize"]       = "rbxassetid://10734895698",
    ["minimize-2"]     = "rbxassetid://10734895530",
    ["expand"]         = "rbxassetid://10723346553",
    ["shrink"]         = "rbxassetid://10734953073",
    ["x"]              = "rbxassetid://10747384394",
    ["check"]          = "rbxassetid://10709790644",
    ["plus"]           = "rbxassetid://10734924532",
    ["chevron-right"]  = "rbxassetid://10709791437",
    ["chevron-down"]   = "rbxassetid://10709790948",
    ["arrow-right"]    = "rbxassetid://10709768347",
    ["arrow-left"]     = "rbxassetid://10709768114",
    ["arrow-up"]       = "rbxassetid://10709768939",
    ["arrow-down"]     = "rbxassetid://10709767827",
    ["loader"]         = "rbxassetid://10723434070",
    ["slash"]          = "rbxassetid://10734962600",
    ["user"]           = "rbxassetid://10747373176",
    ["users"]          = "rbxassetid://10747373426",
    ["user-plus"]      = "rbxassetid://10747372702",
    ["smile"]          = "rbxassetid://10734964441",
    ["shield"]         = "rbxassetid://10734951847",
    ["lock"]           = "rbxassetid://10723434711",
    ["unlock"]         = "rbxassetid://10747366027",
    ["key"]            = "rbxassetid://10723416652",
    ["eye"]            = "rbxassetid://10723346959",
    ["eye-off"]        = "rbxassetid://10723346871",
    ["sword"]          = "rbxassetid://10734975486",
    ["target"]         = "rbxassetid://10734977012",
    ["gamepad"]        = "rbxassetid://10723395457",
    ["trophy"]         = "rbxassetid://10747363809",
    ["crown"]          = "rbxassetid://10709818626",
    ["star"]           = "rbxassetid://10734966248",
    ["gem"]            = "rbxassetid://10723396000",
    ["award"]          = "rbxassetid://10709769406",
    ["gift"]           = "rbxassetid://10723396402",
    ["flag"]           = "rbxassetid://10723375890",
    ["anchor"]         = "rbxassetid://10709761530",
    ["skull"]          = "rbxassetid://10734962068",
    ["ghost"]          = "rbxassetid://10723396107",
    ["wand"]           = "rbxassetid://10747376565",
    ["aperture"]       = "rbxassetid://10709761813",
    ["info"]           = "rbxassetid://10723415903",
    ["alert"]          = "rbxassetid://10709753149",
    ["bell"]           = "rbxassetid://10709775704",
    ["activity"]       = "rbxassetid://10709752035",
    ["sun"]            = "rbxassetid://10734974297",
    ["moon"]           = "rbxassetid://10734897102",
    ["cloud"]          = "rbxassetid://10709806740",
    ["cloud-rain"]     = "rbxassetid://10709806277",
    ["cloud-snow"]     = "rbxassetid://10709806374",
    ["heart"]          = "rbxassetid://10723406885",
    ["coffee"]         = "rbxassetid://10709810814",
    ["bookmark"]       = "rbxassetid://10709782154",
    ["tag"]            = "rbxassetid://10734976528",
    ["cpu"]            = "rbxassetid://10709813383",
    ["database"]       = "rbxassetid://10709818996",
    ["server"]         = "rbxassetid://10734949856",
    ["monitor"]        = "rbxassetid://10734896881",
    ["smartphone"]     = "rbxassetid://10734963940",
    ["tablet"]         = "rbxassetid://10734976394",
    ["wifi"]           = "rbxassetid://10747382504",
    ["bluetooth"]      = "rbxassetid://10709776655",
    ["battery"]        = "rbxassetid://10709774640",
    ["power"]          = "rbxassetid://10734930466",
    ["terminal"]       = "rbxassetid://10734982144",
    ["code"]           = "rbxassetid://10709810463",
    ["bug"]            = "rbxassetid://10709782845",
    ["globe"]          = "rbxassetid://10723404337",
    ["compass"]        = "rbxassetid://10709811445",
    ["map"]            = "rbxassetid://10734886202",
    ["map-pin"]        = "rbxassetid://10734886004",
    ["folder"]         = "rbxassetid://10723387563",
    ["archive"]        = "rbxassetid://10709762233",
    ["trash"]          = "rbxassetid://10747362393",
    ["save"]           = "rbxassetid://10734941499",
    ["download"]       = "rbxassetid://10723344270",
    ["upload"]         = "rbxassetid://10747366434",
    ["copy"]           = "rbxassetid://10709812159",
    ["clipboard"]      = "rbxassetid://10709799288",
    ["link"]           = "rbxassetid://10723426722",
    ["edit"]           = "rbxassetid://10734883598",
    ["edit-2"]         = "rbxassetid://10723344885",
    ["feather"]        = "rbxassetid://10723354671",
    ["book"]           = "rbxassetid://10709781824",
    ["box"]            = "rbxassetid://10709782497",
    ["inbox"]          = "rbxassetid://10723415335",
    ["mail"]           = "rbxassetid://10734885430",
    ["send"]           = "rbxassetid://10734943902",
    ["share"]          = "rbxassetid://10734950813",
    ["rss"]            = "rbxassetid://10734940825",
    ["at-sign"]        = "rbxassetid://10709769286",
    ["image"]          = "rbxassetid://10723415040",
    ["video"]          = "rbxassetid://10747374938",
    ["mic"]            = "rbxassetid://10734888864",
    ["music"]          = "rbxassetid://10734905958",
    ["volume"]         = "rbxassetid://10747376008",
    ["play"]           = "rbxassetid://10734923549",
    ["pause"]          = "rbxassetid://10734919336",
    ["repeat"]         = "rbxassetid://10734933966",
    ["shuffle"]        = "rbxassetid://10734953451",
    ["cast"]           = "rbxassetid://10709790097",
    ["radio"]          = "rbxassetid://10734931596",
    ["bar-chart"]      = "rbxassetid://10709773755",
    ["search"]         = "rbxassetid://10734943674",
    ["filter"]         = "rbxassetid://10723375128",
    ["scissors"]       = "rbxassetid://10734942778",
    ["crop"]           = "rbxassetid://10709818245",
    ["printer"]        = "rbxassetid://10734930632",
    ["type"]           = "rbxassetid://10747364761",
    ["bold"]           = "rbxassetid://10747813908",
    ["italic"]         = "rbxassetid://10723416195",
    ["underline"]      = "rbxassetid://10747365191",
    ["circle"]         = "rbxassetid://10709798174",
    ["square"]         = "rbxassetid://10734965702",
    ["delete"]         = "rbxassetid://10709819059",
    ["refresh"]        = "rbxassetid://10734933966",
    ["clock"]          = "rbxassetid://10709805144",
    ["timer"]          = "rbxassetid://10734984606",
    ["calendar"]       = "rbxassetid://10709789505",
    ["bar-chart-2"]    = "rbxassetid://10709773755",
    ["zap"]            = "rbxassetid://10747384394",
    ["trending-up"]    = "rbxassetid://10709752035",
}

-- ══════════════════════════════════════
--            HELPERS
-- ══════════════════════════════════════
local function GetIcon(name)
    if not name or name == "" then return nil end
    return Icons[name:lower()]
end

local function Tween(o, ti, props)
    local t = TweenService:Create(o, ti, props)
    t:Play(); return t
end

local TI_FAST   = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_MED    = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.42, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TI_SPRING = TweenInfo.new(0.5,  Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TI_NOTIF  = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function SafeCB(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, e = pcall(fn, ...)
    if not ok then warn("[AmethystUI] callback error: "..tostring(e)) end
end

local function Round(n, d)
    d = d or 0; local m = 10^d
    return math.floor(n * m + 0.5) / m
end

-- Instance factory
local function New(cls, props, children)
    local o = Instance.new(cls)
    for k,v in pairs(props or {}) do
        if k ~= "Parent" then pcall(function() o[k]=v end) end
    end
    for _,c in ipairs(children or {}) do if c then c.Parent = o end end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function Corner(r)
    return New("UICorner",{CornerRadius=UDim.new(0,r or 8)})
end
local function Stroke(col,thick,trans)
    return New("UIStroke",{
        Color=col or T.ElementBorder, Thickness=thick or 1,
        Transparency=trans or 0, ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
    })
end
local function Pad(t,b,l,r)
    return New("UIPadding",{
        PaddingTop=UDim.new(0,t or 0), PaddingBottom=UDim.new(0,b or 0),
        PaddingLeft=UDim.new(0,l or 0), PaddingRight=UDim.new(0,r or 0),
    })
end
local function VList(gap, ha)
    return New("UIListLayout",{
        FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=ha or Enum.HorizontalAlignment.Left,
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,gap or 0),
    })
end

local GothamMed  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local GothamSemi = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
local GothamReg  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular)

local function Lbl(text, size, col, font, xa, ya)
    return New("TextLabel",{
        Text=text or "", TextSize=size or 13,
        TextColor3=col or T.Text, TextTransparency=0,
        FontFace=font or GothamReg,
        TextXAlignment=xa or Enum.TextXAlignment.Left,
        TextYAlignment=ya or Enum.TextYAlignment.Center,
        BackgroundTransparency=1, TextWrapped=true, RichText=true,
    })
end

local function Img(id, sz, col)
    return New("ImageLabel",{
        Image=id or "", Size=sz or UDim2.fromOffset(16,16),
        ImageColor3=col or T.Text, BackgroundTransparency=1,
        ScaleType=Enum.ScaleType.Fit,
    })
end

-- Hover/press spring effect for elements
local function ElemHover(f)
    f.MouseEnter:Connect(function()
        Tween(f, TI_FAST, {BackgroundTransparency=ETRANS_HVR})
    end)
    f.MouseLeave:Connect(function()
        Tween(f, TI_FAST, {BackgroundTransparency=ETRANS})
    end)
    f.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            Tween(f, TI_FAST, {BackgroundTransparency=ETRANS_DOWN})
        end
    end)
    f.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            Tween(f, TI_FAST, {BackgroundTransparency=ETRANS_HVR})
        end
    end)
end

-- ══════════════════════════════════════
--   DRAG SYSTEM  (mobile-optimised)
-- ══════════════════════════════════════
-- Three improvements over a naive start-position approach:
--
--  1. DELTA ACCUMULATION
--     Instead of newPos = startPos + (currentPos - origin), we do
--     pendingPos += eachDelta on every input event. If the finger
--     moves faster than the event rate no distance is lost.
--
--  2. TOUCH ID TRACKING
--     We store the exact InputObject that started the drag and only
--     respond to that object in InputChanged. A second finger touching
--     the screen can never hijack or jitter the drag.
--
--  3. RENDERSTEP APPLICATION
--     Input callbacks set pendingPos; the actual .Position write happens
--     once per render frame in RenderStepped so the visual is always in
--     sync with the GPU frame, not mid-frame or multiple times per frame.
--
local function Draggable(handle, target)
    local dragging     = false
    local activeInput  = nil          -- the exact InputObject driving this drag
    local pendingPos   = nil          -- desired position, written on RenderStepped
    local lastInputPos = Vector3.zero -- previous input position for delta calc

    -- Snapshot anchor-aware absolute position as pure pixel offsets.
    -- Required so that a scale-based Position like UDim2.new(0.5,0,0.5,0)
    -- (which has Offset==0) doesn't snap the window to the top-left.
    local function snapToAbsolute()
        local ap  = target.AnchorPoint
        local abs = target.AbsolutePosition
            + Vector2.new(target.AbsoluteSize.X * ap.X,
                          target.AbsoluteSize.Y * ap.Y)
        target.Position = UDim2.fromOffset(abs.X, abs.Y)
        pendingPos = target.Position
    end

    handle.InputBegan:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseButton1 or
            i.UserInputType == Enum.UserInputType.Touch) and not dragging then
            dragging      = true
            activeInput   = i
            lastInputPos  = i.Position
            snapToAbsolute()
            -- Release when this specific input ends
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    if activeInput == i then
                        dragging    = false
                        activeInput = nil
                    end
                end
            end)
        end
    end)

    -- Accumulate delta only from the exact touch/mouse that started the drag
    UserInputService.InputChanged:Connect(function(i)
        if not dragging or i ~= activeInput then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local delta = i.Position - lastInputPos
            lastInputPos = i.Position
            if pendingPos then
                pendingPos = UDim2.fromOffset(
                    pendingPos.X.Offset + delta.X,
                    pendingPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    -- Apply position once per render frame — smooth, no mid-frame writes
    RunService.RenderStepped:Connect(function()
        if dragging and pendingPos then
            target.Position = pendingPos
        end
    end)

    -- Bulletproof safety release (covers fast taps that skip i.Changed)
    UserInputService.InputEnded:Connect(function(i)
        if i == activeInput then
            dragging    = false
            activeInput = nil
        end
    end)
end

-- ══════════════════════════════════════
--          LIBRARY ROOT
-- ══════════════════════════════════════
local Library = {}
Library.__index = Library
Library.Icons   = Icons
Library.Theme   = T
Library.Version = "2.0.0"

local _NotifHolder = nil

-- ══════════════════════════════════════
--         NOTIFICATION SYSTEM
-- ══════════════════════════════════════
function Library:Notify(cfg)
    cfg = cfg or {}
    if not _NotifHolder then return end

    local title      = cfg.Title      or "Notification"
    local content    = cfg.Content    or ""
    local sub        = cfg.SubContent or ""
    local duration   = cfg.Duration
    local ntype      = cfg.Type or "info"

    local stripeCol = ({
        info    = T.Accent,
        success = Color3.fromRGB(72, 190, 120),
        warning = Color3.fromRGB(220, 165, 40),
        error   = Color3.fromRGB(210, 65,  65),
    })[ntype] or T.Accent

    local typeIcon = ({
        info    = Icons["info"],
        success = Icons["check"],
        warning = Icons["alert"],
        error   = Icons["x"],
    })[ntype] or Icons["bell"]

    -- Slot
    local Slot = New("Frame",{
        Name="NotifSlot",
        Size=UDim2.new(1,0,0,0),
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,
        Parent=_NotifHolder,
    })

    -- Card (slides in from right)
    local Card = New("Frame",{
        Name="Card",
        Size=UDim2.new(1,0,0,0),
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=T.NotifBg,
        BackgroundTransparency=0,
        Position=UDim2.new(1.2,0,0,0),
        ClipsDescendants=false,
        Parent=Slot,
    },{
        Corner(10),
        Stroke(T.NotifBorder, 1, 0.3),
        Pad(11, 11, 12, 12),
    })

    -- Card bg gradient
    New("UIGradient",{
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(46,32,70)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(26,18,44)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20,14,34)),
        }),
        Rotation=135,
        Parent=Card,
    })

    -- Accent stripe (left)
    New("Frame",{
        Size=UDim2.new(0,3,1,-14),
        Position=UDim2.fromOffset(0,7),
        BackgroundColor3=stripeCol,
        BorderSizePixel=0,
        ZIndex=5,
        Parent=Card,
    },{Corner(2)})

    -- Content holder
    local Body = New("Frame",{
        Size=UDim2.new(1,0,0,0),
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,
        Position=UDim2.fromOffset(12,0),
        ZIndex=5,
        Parent=Card,
    },{VList(3)})
    Body.UIListLayout.HorizontalAlignment=Enum.HorizontalAlignment.Left

    -- Title row
    local TRow=New("Frame",{
        Size=UDim2.new(1,-22,0,18),
        BackgroundTransparency=1,
        ZIndex=6,
        Parent=Body,
    })
    if typeIcon then
        local ico=Img(typeIcon, UDim2.fromOffset(13,13), stripeCol)
        ico.Position=UDim2.fromOffset(0,2)
        ico.ZIndex=7; ico.Parent=TRow
    end
    local TitleL=Lbl(title,13,T.Text,GothamSemi)
    TitleL.Size=UDim2.new(1,-17,1,0)
    TitleL.Position=UDim2.fromOffset(17,0)
    TitleL.TextTransparency=0; TitleL.ZIndex=7; TitleL.Parent=TRow

    if content~="" then
        local CL=Lbl(content,12,T.SubText)
        CL.Size=UDim2.new(1,-4,0,0)
        CL.AutomaticSize=Enum.AutomaticSize.Y
        CL.TextTransparency=0
        CL.TextYAlignment=Enum.TextYAlignment.Top
        CL.ZIndex=6; CL.Parent=Body
    end
    if sub~="" then
        local SL=Lbl(sub,11,T.TextDim)
        SL.Size=UDim2.new(1,-4,0,0)
        SL.AutomaticSize=Enum.AutomaticSize.Y
        SL.TextTransparency=0
        SL.TextYAlignment=Enum.TextYAlignment.Top
        SL.ZIndex=6; SL.Parent=Body
    end

    -- Progress bar
    local ProgFill=nil
    if duration then
        local PT=New("Frame",{
            Size=UDim2.new(1,-4,0,2),
            BackgroundColor3=T.SectionLine,
            BackgroundTransparency=0.3,
            ZIndex=6,
            Parent=Body,
        },{Corner(1)})
        ProgFill=New("Frame",{
            Size=UDim2.fromScale(1,1),
            BackgroundColor3=stripeCol,
            BackgroundTransparency=0,
            Parent=PT,
        },{Corner(1)})
    end

    -- Close button
    local CloseBtn=New("TextButton",{
        Size=UDim2.fromOffset(18,18),
        AnchorPoint=Vector2.new(1,0),
        Position=UDim2.new(1,0,0,0),
        BackgroundTransparency=1,
        Text="", ZIndex=8,
        Parent=Card,
    })
    local CloseIco=Img(Icons["x"] or "", UDim2.fromOffset(11,11), T.TextDim)
    CloseIco.AnchorPoint=Vector2.new(0.5,0.5)
    CloseIco.Position=UDim2.new(0.5,0,0.5,0)
    CloseIco.ZIndex=9; CloseIco.Parent=CloseBtn
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseIco,TI_FAST,{ImageColor3=T.Text})
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseIco,TI_FAST,{ImageColor3=T.TextDim})
    end)

    local closed=false
    local function Close()
        if closed then return end; closed=true
        Tween(Card,TI_NOTIF,{Position=UDim2.new(1.2,0,0,0)})
        Tween(Card,TI_MED,{BackgroundTransparency=1})
        task.delay(0.42,function() pcall(function() Slot:Destroy() end) end)
    end

    CloseBtn.MouseButton1Click:Connect(Close)

    -- Slide in with bounce
    task.defer(function()
        Tween(Card, TI_BOUNCE, {Position=UDim2.fromOffset(0,0)})
    end)

    -- Duration drain
    if duration then
        task.spawn(function()
            local steps=60
            for i=steps,0,-1 do
                if closed then break end
                if ProgFill then
                    ProgFill.Size=UDim2.fromScale(i/steps,1)
                end
                task.wait(duration/steps)
            end
            Close()
        end)
    end

    return {Close=Close}
end

-- ══════════════════════════════════════
--          CREATE WINDOW
-- ══════════════════════════════════════
function Library:CreateWindow(cfg)
    cfg=cfg or {}
    local title    = cfg.Title    or "AmethystUI"
    local subtitle = cfg.SubTitle or ""
    local winW     = cfg.Width    or 580
    local winH     = cfg.Height   or 460
    local tabW     = cfg.TabWidth or 154

    -- ScreenGui
    local pGui = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    local old  = pGui:FindFirstChild("AmethystUI_v2")
    if old then old:Destroy() end

    local SGui = New("ScreenGui",{
        Name="AmethystUI_v2",
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        DisplayOrder=999,
        ResetOnSpawn=false,
        IgnoreGuiInset=true,
        Parent=pGui,
    })

    -- Notification holder (bottom-right)
    _NotifHolder = New("Frame",{
        Name="NotifHolder",
        AnchorPoint=Vector2.new(1,1),
        Position=UDim2.new(1,-16,1,-16),
        Size=UDim2.new(0,304,1,-16),
        BackgroundTransparency=1,
        ZIndex=100,
        Parent=SGui,
    },{
        New("UIListLayout",{
            HorizontalAlignment=Enum.HorizontalAlignment.Center,
            VerticalAlignment=Enum.VerticalAlignment.Bottom,
            SortOrder=Enum.SortOrder.LayoutOrder,
            Padding=UDim.new(0,8),
        })
    })

    -- Root frame (no UIScale here — scaling is applied to Win directly)
    local Root=New("Frame",{
        Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1,
        Parent=SGui,
    })

    -- Window frame (AnchorPoint 0.5,0.5 keeps it centred; UIScale on Win
    -- scales from the window's own centre so it stays centred on all screens)
    local Win=New("Frame",{
        Name="Window",
        Size=UDim2.fromOffset(winW,winH),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(0.5,0,0.5,0),
        BackgroundColor3=T.WindowBg,
        BorderSizePixel=0,
        ClipsDescendants=false,
        Parent=Root,
    },{
        Corner(12),
        Stroke(T.TitleBarLine,1,0.3),
    })

    -- Scale for mobile — applied to Win so it scales around its own centre
    local UIScl=New("UIScale",{Scale=1,Parent=Win})
    local function UpdateScale()
        UIScl.Scale=math.clamp(Camera.ViewportSize.X/1080, 0.5, 1.2)
    end
    UpdateScale()
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)

    -- Window gradient (AcrylicGradient colours)
    New("UIGradient",{
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,T.GradientTop),
            ColorSequenceKeypoint.new(1,T.GradientBot),
        }),
        Rotation=135,
        Parent=Win,
    })

    -- ── Title Bar ──────────────────────────────────────────
    local TBar=New("Frame",{
        Size=UDim2.new(1,0,0,44),
        BackgroundColor3=T.TitleBarBg,
        BorderSizePixel=0,
        ZIndex=6,
        Parent=Win,
    },{Corner(12)})
    -- Cover bottom rounded corners
    New("Frame",{
        Size=UDim2.new(1,0,0,12),
        Position=UDim2.new(0,0,1,-12),
        BackgroundColor3=T.TitleBarBg,
        BorderSizePixel=0,
        ZIndex=5,
        Parent=TBar,
    })
    -- Bottom border line (TitleBarLine)
    New("Frame",{
        Size=UDim2.new(1,0,0,1),
        Position=UDim2.new(0,0,1,-1),
        BackgroundColor3=T.TitleBarLine,
        BackgroundTransparency=0.35,
        BorderSizePixel=0,
        ZIndex=7,
        Parent=TBar,
    })

    -- Accent mark + glow
    New("Frame",{
        Size=UDim2.fromOffset(10,28),
        AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,10,0.5,0),
        BackgroundColor3=T.Accent,
        BackgroundTransparency=0.55,
        ZIndex=7,
        Parent=TBar,
    },{Corner(6)})
    New("Frame",{
        Size=UDim2.fromOffset(4,22),
        AnchorPoint=Vector2.new(0,0.5),
        Position=UDim2.new(0,13,0.5,0),
        BackgroundColor3=T.Accent,
        BorderSizePixel=0,
        ZIndex=8,
        Parent=TBar,
    },{Corner(2)})

    -- Title + subtitle
    local TitleLbl=Lbl(title,14,T.Text,GothamSemi)
    TitleLbl.Size=UDim2.new(1,-120,0,18)
    TitleLbl.Position=UDim2.fromOffset(26,6)
    TitleLbl.ZIndex=8; TitleLbl.TextTransparency=0; TitleLbl.Parent=TBar

    local SubLbl=Lbl(subtitle,11,T.SubText)
    SubLbl.Size=UDim2.new(1,-120,0,14)
    SubLbl.Position=UDim2.fromOffset(26,26)
    SubLbl.ZIndex=8; SubLbl.TextTransparency=0; SubLbl.Parent=TBar

    -- TitleBar control buttons
    local function CtrlBtn(iconId, posX, hoverCol)
        local btn=New("TextButton",{
            Size=UDim2.fromOffset(28,28),
            AnchorPoint=Vector2.new(1,0.5),
            Position=UDim2.new(1,posX,0.5,0),
            BackgroundColor3=T.TabHover,
            BackgroundTransparency=1,
            Text="", AutoButtonColor=false,
            ZIndex=9,
            Parent=TBar,
        },{
            Corner(7),
            Stroke(T.ElementBorder,1,0.6),
        })
        local ico=Img(iconId, UDim2.fromOffset(13,13), T.SubText)
        ico.AnchorPoint=Vector2.new(0.5,0.5)
        ico.Position=UDim2.new(0.5,0,0.5,0)
        ico.ZIndex=10; ico.Parent=btn
        btn.MouseEnter:Connect(function()
            Tween(btn,TI_FAST,{BackgroundColor3=hoverCol or T.TabHover, BackgroundTransparency=0})
            Tween(ico,TI_FAST,{ImageColor3=T.Text})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn,TI_FAST,{BackgroundTransparency=1})
            Tween(ico,TI_FAST,{ImageColor3=T.SubText})
        end)
        return btn,ico
    end

    local BtnClose,BtnCloseIco = CtrlBtn(Icons["x"] or "",        -8,   Color3.fromRGB(200,60,60))
    local BtnMinim,BtnMinimIco = CtrlBtn(Icons["minimize-2"] or "",-42,  T.TabHover)

    -- ── Tab panel ──────────────────────────────────────────
    local TabPanel=New("Frame",{
        Size=UDim2.new(0,tabW,1,-44),
        Position=UDim2.fromOffset(0,44),
        BackgroundColor3=T.TabBg,
        BorderSizePixel=0,
        ZIndex=4,
        Parent=Win,
    })
    -- Cover top corner
    New("Frame",{Size=UDim2.new(1,0,0,12),BackgroundColor3=T.TabBg,
        BorderSizePixel=0,ZIndex=3,Parent=TabPanel})
    -- Right border
    New("Frame",{
        Size=UDim2.fromOffset(1,0),
        Position=UDim2.new(1,-1,0,0),
        BackgroundColor3=T.TitleBarLine,
        BackgroundTransparency=0.45,
        BorderSizePixel=0,
        ZIndex=5,
        Parent=TabPanel,
    })

    -- Animated selector bar
    local TabSel=New("Frame",{
        Size=UDim2.fromOffset(3,26),
        Position=UDim2.fromOffset(0,12),
        BackgroundColor3=T.Accent,
        BorderSizePixel=0,
        ZIndex=10,
        Parent=TabPanel,
    },{Corner(2)})
    -- Glow on selector (must share the same initial Position as TabSel)
    local SelGlow=New("Frame",{
        Size=UDim2.fromOffset(10,26),
        Position=UDim2.fromOffset(0,12),   -- matches TabSel's starting position
        BackgroundColor3=T.Accent,
        BackgroundTransparency=0.65,
        BorderSizePixel=0,
        ZIndex=9,
        Parent=TabPanel,
    },{Corner(6)})
    TabSel:GetPropertyChangedSignal("Position"):Connect(function()
        SelGlow.Position=TabSel.Position
    end)
    TabSel:GetPropertyChangedSignal("Size"):Connect(function()
        SelGlow.Size=UDim2.fromOffset(10,TabSel.AbsoluteSize.Y)
    end)

    -- Tab scroll
    local TabScroll=New("ScrollingFrame",{
        Size=UDim2.new(1,0,1,-8),
        Position=UDim2.fromOffset(0,8),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ScrollBarThickness=2,
        ScrollBarImageColor3=T.Accent,
        ScrollBarImageTransparency=0.5,
        CanvasSize=UDim2.fromScale(0,0),
        ScrollingDirection=Enum.ScrollingDirection.Y,
        ZIndex=5,
        Parent=TabPanel,
    },{VList(2),Pad(4,4,6,6)})
    TabScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabScroll.CanvasSize=UDim2.new(0,0,0,
            TabScroll.UIListLayout.AbsoluteContentSize.Y+8)
    end)

    -- ── Content area ───────────────────────────────────────
    local ContentArea=New("Frame",{
        Size=UDim2.new(1,-tabW-1,1,-44),
        Position=UDim2.new(0,tabW+1,0,44),
        BackgroundTransparency=1,
        ClipsDescendants=true,
        ZIndex=3,
        Parent=Win,
    })

    -- ── Minimize orb ───────────────────────────────────────
    local MinOrb=New("TextButton",{
        Size=UDim2.fromOffset(46,46),
        AnchorPoint=Vector2.new(0,0),
        Position=UDim2.fromOffset(20,20),
        BackgroundColor3=T.TabBg,
        BackgroundTransparency=0,
        Text="", AutoButtonColor=false,
        Visible=false, ZIndex=200,
        Parent=Root,
    },{
        Corner(12),
        Stroke(T.Accent,1.5,0),
    })
    New("UIGradient",{
        Color=ColorSequence.new(T.AccentGlow,T.GradientBot),
        Rotation=135, Parent=MinOrb,
    })
    local OrbIco=Img(Icons["layers"] or "", UDim2.fromOffset(22,22), T.Accent)
    OrbIco.AnchorPoint=Vector2.new(0.5,0.5)
    OrbIco.Position=UDim2.new(0.5,0,0.5,0)
    OrbIco.ZIndex=201; OrbIco.Parent=MinOrb
    MinOrb.MouseEnter:Connect(function()
        Tween(MinOrb,TI_FAST,{BackgroundColor3=T.TabActive})
        Tween(OrbIco,TI_FAST,{ImageColor3=T.AccentHover})
    end)
    MinOrb.MouseLeave:Connect(function()
        Tween(MinOrb,TI_FAST,{BackgroundColor3=T.TabBg})
        Tween(OrbIco,TI_FAST,{ImageColor3=T.Accent})
    end)

    -- Window object
    local Window={
        Frame=Win, TitleBar=TBar,
        TabPanel=TabPanel, TabScroll=TabScroll,
        TabSelector=TabSel, ContentArea=ContentArea,
        MinOrb=MinOrb, ScreenGui=SGui,
        Tabs={}, ActiveTab=nil,
        Minimized=false, Options={},
    }
    function Window:Notify(c) return Library:Notify(c) end

    -- Drag: title bar and minimise orb only
    Draggable(TBar,  Win)
    Draggable(MinOrb, MinOrb)

    -- Minimize / Maximize
    local function DoMin()
        Window.Minimized=true
        -- Use AbsolutePosition so it works with AnchorPoint centering
        local ap = Win.AbsolutePosition
        MinOrb.Position = UDim2.fromOffset(ap.X + 4, ap.Y + 4)
        MinOrb.Size = UDim2.fromOffset(0, 0)
        Tween(Win, TI_MED, { Size = UDim2.fromOffset(winW, 0) })
        task.delay(0.28, function()
            Win.Visible = false
            Win.Size = UDim2.fromOffset(winW, winH)
            MinOrb.Visible = true
            Tween(MinOrb, TI_BOUNCE, { Size = UDim2.fromOffset(46, 46) })
        end)
    end
    local function DoMax()
        Window.Minimized = false
        Tween(MinOrb, TI_FAST, { Size = UDim2.fromOffset(0, 0) })
        task.delay(0.15, function()
            MinOrb.Visible = false
            MinOrb.Size = UDim2.fromOffset(46, 46)
            Win.Visible = true
            Win.Size = UDim2.fromOffset(winW, 0)
            Tween(Win, TI_BOUNCE, { Size = UDim2.fromOffset(winW, winH) })
        end)
    end

    local function DoClose()
        -- Smooth close: shrink + fade, then destroy
        local TI_CLOSE = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        Tween(Win, TI_CLOSE, {
            Size                = UDim2.fromOffset(winW * 0.92, winH * 0.92),
            BackgroundTransparency = 0.85,
        })
        -- Also fade all direct children
        for _, child in ipairs(Win:GetChildren()) do
            if child:IsA("GuiObject") then
                Tween(child, TI_CLOSE, { BackgroundTransparency = 1 })
            end
        end
        task.delay(0.34, function()
            SGui:Destroy()
        end)
    end

    BtnMinim.MouseButton1Click:Connect(DoMin)
    MinOrb.MouseButton1Click:Connect(DoMax)
    BtnClose.MouseButton1Click:Connect(DoClose)

    -- Open animation: scale up from center (AnchorPoint stays at 0.5,0.5)
    Win.Size = UDim2.fromOffset(winW * 0.85, winH * 0.85)
    Win.BackgroundTransparency = 0.6
    Tween(Win, TI_BOUNCE, {
        Size = UDim2.fromOffset(winW, winH),
        BackgroundTransparency = 0,
    })

    -- Selector animation
    -- AbsolutePosition already reflects visual screen pos (scroll included),
    -- so we just subtract TabPanel's top edge — no CanvasPosition needed.
    function Window:_AnimSel(btn)
        -- AbsolutePosition/AbsoluteSize are in real screen pixels (post-UIScale).
        -- Position offsets are in local pre-scale coords, so we must divide by
        -- UIScl.Scale to get the correct value on every screen size.
        local scale = UIScl.Scale
        local relY  = (btn.AbsolutePosition.Y - TabPanel.AbsolutePosition.Y) / scale
        local h     = math.max(btn.AbsoluteSize.Y - 8, 16) / scale
        local yPos  = relY + 4
        Tween(TabSel, TI_MED, {
            Position = UDim2.fromOffset(0, yPos),
            Size     = UDim2.fromOffset(3, h),
        })
        Tween(SelGlow, TI_MED, {
            Position = UDim2.fromOffset(0, yPos),
            Size     = UDim2.fromOffset(10, h),
        })
    end

    -- ══════════════════════════════════════
    --              ADD TAB
    -- ══════════════════════════════════════
    function Window:AddTab(tabCfg)
        tabCfg=tabCfg or {}
        local tabTitle=tabCfg.Title or "Tab"
        local iconId  =GetIcon(tabCfg.Icon)

        -- Tab button
        local TabBtn=New("TextButton",{
            Size=UDim2.new(1,0,0,34),
            BackgroundColor3=T.TabHover,
            BackgroundTransparency=1,
            Text="", AutoButtonColor=false,
            ZIndex=6, Parent=TabScroll,
        },{Corner(7)})

        local TabIco=nil
        if iconId then
            TabIco=Img(iconId, UDim2.fromOffset(15,15), T.TabText)
            TabIco.AnchorPoint=Vector2.new(0,0.5)
            TabIco.Position=UDim2.new(0,10,0.5,0)
            TabIco.ZIndex=7; TabIco.Parent=TabBtn
        end

        local TabLbl=Lbl(tabTitle,12,T.TabText,GothamMed)
        TabLbl.Size=UDim2.new(1,iconId and -34 or -16,1,0)
        TabLbl.Position=UDim2.fromOffset(iconId and 32 or 12,0)
        TabLbl.TextTransparency=0; TabLbl.ZIndex=7; TabLbl.Parent=TabBtn

        -- Container
        -- AutomaticCanvasSize=Y: Roblox automatically keeps CanvasSize in sync
        --   with content — far more reliable than manual AbsoluteContentSize tracking
        --   which can lag, fire at zero, or miss updates when a tab first shows.
        -- ElasticBehavior=Never: prevents the rubber-band bounce-back on mobile
        --   that makes the last few elements snap back out of reach.
        local Container=New("ScrollingFrame",{
            Size=UDim2.fromScale(1,1),
            BackgroundTransparency=1,
            BorderSizePixel=0,
            ScrollBarThickness=3,
            ScrollBarImageColor3=T.Accent,
            ScrollBarImageTransparency=0.4,
            CanvasSize=UDim2.fromScale(0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ElasticBehavior=Enum.ElasticBehavior.Never,
            ScrollingDirection=Enum.ScrollingDirection.Y,
            Visible=false, ZIndex=4,
            Parent=ContentArea,
        },{VList(5),Pad(10,10,10,10)})

        -- Keep a manual fallback for older executors that don't support
        -- AutomaticCanvasSize; the signal fires any time content changes.
        local function UpdateCanvas()
            task.defer(function()
                Container.CanvasSize = UDim2.new(0, 0, 0,
                    Container.UIListLayout.AbsoluteContentSize.Y + 20)
            end)
        end
        Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

        local Tab={
            Button=TabBtn, Container=Container,
            Label=TabLbl, Icon=TabIco,
        }

        local function Select()
            if Window.ActiveTab==Tab then return end
            if Window.ActiveTab then
                local o=Window.ActiveTab
                o.Container.Visible=false
                Tween(o.Button,TI_FAST,{BackgroundTransparency=1})
                o.Label.TextColor3=T.TabText
                o.Label.TextTransparency=0.15
                if o.Icon then Tween(o.Icon,TI_FAST,{ImageColor3=T.TabText}) end
            end
            Window.ActiveTab=Tab
            Container.Visible=true
            task.defer(UpdateCanvas)   -- force scroll recalc after layout settles
            Tween(TabBtn,TI_MED,{
                BackgroundColor3=T.TabActive,
                BackgroundTransparency=0,
            })
            TabLbl.TextColor3=T.Text; TabLbl.TextTransparency=0
            if TabIco then Tween(TabIco,TI_FAST,{ImageColor3=T.Accent}) end
            Window:_AnimSel(TabBtn)
        end
        Tab.Select=Select

        TabBtn.MouseButton1Click:Connect(Select)
        TabBtn.MouseEnter:Connect(function()
            if Window.ActiveTab~=Tab then
                Tween(TabBtn,TI_FAST,{BackgroundColor3=T.TabHover,BackgroundTransparency=0})
                TabLbl.TextColor3=T.Text
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if Window.ActiveTab~=Tab then
                Tween(TabBtn,TI_FAST,{BackgroundTransparency=1})
                TabLbl.TextColor3=T.TabText
            end
        end)

        table.insert(Window.Tabs,Tab)
        if #Window.Tabs==1 then task.defer(Select) end

        -- ══════════════════════════════════════
        --           ELEMENT HELPERS
        -- ══════════════════════════════════════
        local function BaseFrame(cfg2, rightW)
            rightW=rightW or 0
            local hasDesc=cfg2 and cfg2.Description and cfg2.Description~=""
            local h=hasDesc and 54 or 38

            local F=New("TextButton",{
                Size=UDim2.new(1,0,0,h),
                BackgroundColor3=T.ElementColor,
                BackgroundTransparency=ETRANS,
                AutoButtonColor=false, Text="",
                ZIndex=5, Parent=Container,
            },{
                Corner(6),
                Stroke(T.ElementBorder,1,0.55),
            })
            ElemHover(F)

            local LH=New("Frame",{
                Size=UDim2.new(1,-(rightW+12),1,0),
                Position=UDim2.fromOffset(12,0),
                BackgroundTransparency=1,
                ZIndex=6, Parent=F,
            },{
                VList(2),
                Pad(hasDesc and 10 or 0, hasDesc and 10 or 0,0,0),
            })
            LH.UIListLayout.HorizontalAlignment=Enum.HorizontalAlignment.Left

            local TL=Lbl(cfg2 and cfg2.Title or "",13,T.Text,GothamMed)
            TL.Size=UDim2.new(1,0,0,16); TL.TextTransparency=0; TL.Parent=LH

            local DL=nil
            if hasDesc then
                DL=Lbl(cfg2.Description,11,T.SubText)
                DL.Size=UDim2.new(1,0,0,14); DL.TextTransparency=0
                DL.TextYAlignment=Enum.TextYAlignment.Top; DL.Parent=LH
            end
            return F,TL,DL
        end

        -- ──────────────── BUTTON ─────────────────────────────
        function Tab:AddButton(cfg2)
            cfg2=cfg2 or {}
            assert(cfg2.Title,"AddButton: needs Title")
            local cb=cfg2.Callback or function() end

            local F,TL=BaseFrame(cfg2, 46)

            -- Right badge
            local Badge=New("Frame",{
                Size=UDim2.fromOffset(32,26),
                AnchorPoint=Vector2.new(1,0.5),
                Position=UDim2.new(1,-10,0.5,0),
                BackgroundColor3=T.AccentDark,
                BackgroundTransparency=0.35,
                ZIndex=7, Parent=F,
            },{
                Corner(6),
                Stroke(T.Accent,1,0.5),
            })
            local ChevIco=Img(Icons["chevron-right"] or "",
                UDim2.fromOffset(12,12), T.SubText)
            ChevIco.AnchorPoint=Vector2.new(0.5,0.5)
            ChevIco.Position=UDim2.new(0.5,0,0.5,0)
            ChevIco.ZIndex=8; ChevIco.Parent=Badge

            F.MouseButton1Click:Connect(function()
                Tween(F,TI_FAST,{BackgroundTransparency=ETRANS_DOWN})
                Tween(Badge,TI_FAST,{BackgroundColor3=T.Accent,BackgroundTransparency=0})
                Tween(ChevIco,TI_FAST,{ImageColor3=T.Text})
                task.delay(0.15,function()
                    Tween(F,TI_MED,{BackgroundTransparency=ETRANS})
                    Tween(Badge,TI_MED,{BackgroundColor3=T.AccentDark,BackgroundTransparency=0.35})
                    Tween(ChevIco,TI_MED,{ImageColor3=T.SubText})
                end)
                SafeCB(cb)
            end)
            F.MouseEnter:Connect(function()
                Tween(ChevIco,TI_FAST,{ImageColor3=T.Accent})
            end)
            F.MouseLeave:Connect(function()
                Tween(ChevIco,TI_FAST,{ImageColor3=T.SubText})
            end)

            return {
                SetTitle=function(_,t) TL.Text=t; TL.TextTransparency=0 end,
                SetCallback=function(_,fn) cb=fn end,
            }
        end

        -- ──────────────── TOGGLE ─────────────────────────────
        function Tab:AddToggle(id, cfg2)
            cfg2=cfg2 or {}
            assert(cfg2.Title,"AddToggle: needs Title")
            local cb=cfg2.Callback or function() end
            local val=cfg2.Default==true

            local F,TL=BaseFrame(cfg2, 56)

            local Track=New("Frame",{
                Size=UDim2.fromOffset(40,20),
                AnchorPoint=Vector2.new(1,0.5),
                Position=UDim2.new(1,-12,0.5,0),
                BackgroundColor3=val and T.ToggleOn or T.ToggleSlider,
                BackgroundTransparency=val and 0 or 0.45,
                BorderSizePixel=0,
                ZIndex=7, Parent=F,
            },{
                Corner(10),
                Stroke(val and T.Accent or T.ElementBorder,1,val and 0.2 or 0.5),
            })

            local Knob=New("Frame",{
                Size=UDim2.fromOffset(14,14),
                Position=UDim2.fromOffset(val and 23 or 3, 3),
                BackgroundColor3=val and T.ToggleKnobOn or T.ToggleKnob,
                BorderSizePixel=0,
                ZIndex=8, Parent=Track,
            },{
                Corner(7),
            })

            -- Knob glow (accent ring when on)
            local KGlow=New("Frame",{
                Size=UDim2.fromOffset(18,18),
                AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(0.5,0,0.5,0),
                BackgroundColor3=T.Accent,
                BackgroundTransparency=val and 0.55 or 1,
                BorderSizePixel=0,
                ZIndex=7, Parent=Knob,
            },{Corner(9)})

            local Tog={Value=val,Callback=cb,Changed=nil}

            local function Refresh()
                local v=Tog.Value
                Tween(Track,TI_MED,{
                    BackgroundColor3=v and T.ToggleOn or T.ToggleSlider,
                    BackgroundTransparency=v and 0 or 0.45,
                })
                Tween(Knob,TI_MED,{
                    Position=UDim2.fromOffset(v and 23 or 3, 3),
                    BackgroundColor3=v and T.ToggleKnobOn or T.ToggleKnob,
                })
                Tween(KGlow,TI_MED,{BackgroundTransparency=v and 0.55 or 1})
                local stk=Track:FindFirstChildOfClass("UIStroke")
                if stk then
                    Tween(stk,TI_MED,{
                        Color=v and T.Accent or T.ElementBorder,
                        Transparency=v and 0.2 or 0.5,
                    })
                end
                SafeCB(Tog.Callback,Tog.Value)
                SafeCB(Tog.Changed, Tog.Value)
            end

            function Tog:SetValue(v) self.Value=not not v; Refresh() end
            function Tog:OnChanged(fn) self.Changed=fn end

            -- Single click listener with debounce so rapid taps can't
            -- flip the toggle twice before the animation settles.
            local _togBusy = false
            F.MouseButton1Click:Connect(function()
                if _togBusy then return end
                _togBusy = true
                Tog:SetValue(not Tog.Value)
                task.delay(0.22, function() _togBusy = false end)
            end)
            -- NOTE: Track.InputBegan was intentionally removed.
            -- It caused a double-fire on click because F.MouseButton1Click
            -- already bubbles up through Track. Keeping only one listener
            -- fixes the "toggle enables and disables at the same time" bug.

            if id then Window.Options[id]=Tog end
            return Tog
        end

        -- ──────────────── SLIDER ─────────────────────────────
        function Tab:AddSlider(id, cfg2)
            cfg2=cfg2 or {}
            assert(cfg2.Title,"AddSlider: needs Title")
            local cb=cfg2.Callback or function() end
            local mn=cfg2.Min or 0
            local mx=cfg2.Max or 100
            local def=math.clamp(cfg2.Default or mn,mn,mx)
            local rnd=cfg2.Rounding or 0
            local hasDesc=cfg2.Description and cfg2.Description~=""
            local eH=hasDesc and 65 or 53

            local F=New("TextButton",{
                Size=UDim2.new(1,0,0,eH),
                BackgroundColor3=T.ElementColor,
                BackgroundTransparency=ETRANS,
                AutoButtonColor=false, Text="",
                ZIndex=5, Parent=Container,
            },{
                Corner(6),
                Stroke(T.ElementBorder,1,0.55),
            })
            ElemHover(F)

            local TL=Lbl(cfg2.Title,13,T.Text,GothamMed)
            TL.Size=UDim2.new(1,-80,0,16)
            TL.Position=UDim2.fromOffset(12,hasDesc and 8 or 7)
            TL.ZIndex=6; TL.TextTransparency=0; TL.Parent=F

            if hasDesc then
                local DL=Lbl(cfg2.Description,11,T.SubText)
                DL.Size=UDim2.new(1,-80,0,13)
                DL.Position=UDim2.fromOffset(12,24)
                DL.ZIndex=6; DL.TextTransparency=0
                DL.TextYAlignment=Enum.TextYAlignment.Top
                DL.Parent=F
            end

            -- Value badge (right of title)
            local VBadge=New("Frame",{
                Size=UDim2.fromOffset(56,20),
                AnchorPoint=Vector2.new(1,0),
                Position=UDim2.new(1,-12,0,hasDesc and 8 or 7),
                BackgroundColor3=T.AccentDark,
                BackgroundTransparency=0.35,
                ZIndex=7, Parent=F,
            },{
                Corner(5),
                Stroke(T.Accent,1,0.55),
            })
            local VLbl=Lbl(tostring(def),11,T.Text,GothamMed,Enum.TextXAlignment.Center)
            VLbl.Size=UDim2.fromScale(1,1); VLbl.ZIndex=8; VLbl.TextTransparency=0
            VLbl.Parent=VBadge

            -- Rail
            local Rail=New("Frame",{
                Size=UDim2.new(1,-24,0,5),
                Position=UDim2.new(0,12,1,-14),
                BackgroundColor3=T.SliderRail,
                BackgroundTransparency=0.65,
                ZIndex=6, Parent=F,
            },{Corner(3)})

            -- Fill (gradient)
            local Fill=New("Frame",{
                Size=UDim2.fromScale(0,1),
                BackgroundColor3=T.SliderFill,
                ZIndex=7, Parent=Rail,
            },{
                Corner(3),
                New("UIGradient",{
                    Color=ColorSequence.new(T.AccentHover,T.Accent),
                    Rotation=0,
                }),
            })

            -- Knob
            local Knob=New("Frame",{
                Size=UDim2.fromOffset(16,16),
                AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(0,0,0.5,0),
                BackgroundColor3=T.Text,
                BorderSizePixel=0,
                ZIndex=9, Parent=Rail,
            },{
                Corner(8),
                Stroke(T.Accent,2,0),
            })
            New("Frame",{
                Size=UDim2.fromOffset(6,6),
                AnchorPoint=Vector2.new(0.5,0.5),
                Position=UDim2.new(0.5,0,0.5,0),
                BackgroundColor3=T.Accent,
                BorderSizePixel=0,
                ZIndex=10, Parent=Knob,
            },{Corner(3)})

            local Sld={Value=def,Min=mn,Max=mx,Rounding=rnd,Callback=cb,Changed=nil}

            local function Upd(v)
                local c=Round(math.clamp(v,mn,mx),rnd)
                Sld.Value=c
                local pct=(c-mn)/(mx-mn)
                Fill.Size=UDim2.fromScale(pct,1)
                Knob.Position=UDim2.new(pct,0,0.5,0)
                VLbl.Text=tostring(c); VLbl.TextTransparency=0
                SafeCB(Sld.Callback,c); SafeCB(Sld.Changed,c)
            end

            function Sld:SetValue(v) Upd(v) end
            function Sld:OnChanged(fn) self.Changed=fn end

            local drag=false
            local function DragPos(pos)
                local ax=Rail.AbsolutePosition.X
                local aw=Rail.AbsoluteSize.X
                local pct=math.clamp((pos.X-ax)/aw,0,1)
                Upd(mn+(mx-mn)*pct)
            end

            Rail.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1
                or i.UserInputType==Enum.UserInputType.Touch then
                    drag=true; DragPos(i.Position)
                end
            end)
            Knob.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1
                or i.UserInputType==Enum.UserInputType.Touch then drag=true end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1
                or i.UserInputType==Enum.UserInputType.Touch then drag=false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if drag and (i.UserInputType==Enum.UserInputType.MouseMovement
                or i.UserInputType==Enum.UserInputType.Touch) then
                    DragPos(i.Position)
                end
            end)

            Upd(def)
            if id then Window.Options[id]=Sld end
            return Sld
        end

        -- ──────────────── INPUT / TEXTBOX ────────────────────
        function Tab:AddInput(id, cfg2)
            cfg2=cfg2 or {}
            assert(cfg2.Title,"AddInput: needs Title")
            local cb=cfg2.Callback or function() end
            local onFin=cfg2.OnFinished or function() end
            local defVal=cfg2.Default or ""
            local numeric=cfg2.Numeric or false
            local ph=cfg2.Placeholder or "Type here..."
            local maxLen=cfg2.MaxLength or 0
            local hasDesc=cfg2.Description and cfg2.Description~=""

            local eH=hasDesc and 74 or 60
            local F=New("TextButton",{
                Size=UDim2.new(1,0,0,eH),
                BackgroundColor3=T.ElementColor,
                BackgroundTransparency=ETRANS,
                AutoButtonColor=false, Text="",
                ZIndex=5, Parent=Container,
            },{
                Corner(6),
                Stroke(T.ElementBorder,1,0.55),
            })
            ElemHover(F)

            local TL=Lbl(cfg2.Title,13,T.Text,GothamMed)
            TL.Size=UDim2.new(1,-12,0,16)
            TL.Position=UDim2.fromOffset(12,8)
            TL.ZIndex=6; TL.TextTransparency=0; TL.Parent=F

            if hasDesc then
                local DL=Lbl(cfg2.Description,11,T.SubText)
                DL.Size=UDim2.new(1,-12,0,13)
                DL.Position=UDim2.fromOffset(12,24)
                DL.ZIndex=6; DL.TextTransparency=0
                DL.TextYAlignment=Enum.TextYAlignment.Top
                DL.Parent=F
            end

            -- Textbox container
            local BoxWrap=New("Frame",{
                Size=UDim2.new(1,-24,0,28),
                Position=UDim2.new(0,12,1,-36),
                BackgroundColor3=T.InputFocused,
                BackgroundTransparency=0,
                ZIndex=7, Parent=F,
            },{
                Corner(5),
                Stroke(T.InputBorder,1,0.4),
            })

            -- Fluent-style bottom indicator
            local Indicator=New("Frame",{
                Size=UDim2.new(1,-4,0,1),
                AnchorPoint=Vector2.new(0,1),
                Position=UDim2.new(0,2,1,0),
                BackgroundColor3=T.InputIndicator,
                BackgroundTransparency=0.5,
                ZIndex=9, Parent=BoxWrap,
            },{Corner(1)})

            local TBox=New("TextBox",{
                Size=UDim2.new(1,-18,1,0),
                Position=UDim2.fromOffset(8,0),
                BackgroundTransparency=1,
                FontFace=GothamReg,
                TextSize=12,
                TextColor3=T.Text,
                TextTransparency=0,
                PlaceholderText=ph,
                PlaceholderColor3=T.SubText,
                TextXAlignment=Enum.TextXAlignment.Left,
                Text=defVal,
                ClearTextOnFocus=false,
                ZIndex=8, Parent=BoxWrap,
            })

            -- Focus animation
            TBox.Focused:Connect(function()
                Tween(BoxWrap,TI_FAST,{BackgroundColor3=T.InputFocused})
                local stk=BoxWrap:FindFirstChildOfClass("UIStroke")
                if stk then Tween(stk,TI_FAST,{Color=T.Accent,Transparency=0.15}) end
                Tween(Indicator,TI_FAST,{
                    BackgroundColor3=T.Accent,
                    BackgroundTransparency=0,
                    Size=UDim2.new(1,-2,0,2),
                    Position=UDim2.new(0,1,1,0),
                })
            end)
            TBox.FocusLost:Connect(function(enter)
                local stk=BoxWrap:FindFirstChildOfClass("UIStroke")
                if stk then Tween(stk,TI_FAST,{Color=T.InputBorder,Transparency=0.4}) end
                Tween(Indicator,TI_FAST,{
                    BackgroundColor3=T.InputIndicator,
                    BackgroundTransparency=0.5,
                    Size=UDim2.new(1,-4,0,1),
                    Position=UDim2.new(0,2,1,0),
                })
                if enter then SafeCB(onFin,TBox.Text) end
            end)

            local Inp={Value=defVal,Callback=cb,Changed=nil}
            TBox:GetPropertyChangedSignal("Text"):Connect(function()
                local txt=TBox.Text
                if maxLen>0 and #txt>maxLen then
                    txt=txt:sub(1,maxLen); TBox.Text=txt
                end
                if numeric and txt~="" and not tonumber(txt) then
                    TBox.Text=Inp.Value; return
                end
                Inp.Value=txt
                SafeCB(Inp.Callback,txt)
                SafeCB(Inp.Changed, txt)
            end)
            function Inp:SetValue(v) TBox.Text=tostring(v); self.Value=TBox.Text end
            function Inp:OnChanged(fn) self.Changed=fn end

            F.MouseButton1Click:Connect(function() TBox:CaptureFocus() end)

            if id then Window.Options[id]=Inp end
            return Inp
        end

        -- ──────────────── PARAGRAPH ──────────────────────────
        function Tab:AddParagraph(cfg2)
            cfg2=cfg2 or {}
            assert(cfg2.Title,"AddParagraph: needs Title")

            local P=New("Frame",{
                Size=UDim2.new(1,0,0,0),
                AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=T.ElementColor,
                BackgroundTransparency=0.92,
                ZIndex=5, Parent=Container,
            },{
                Corner(6),
                Stroke(T.ElementBorder,1,0.6),
                Pad(10,10,14,14),
            })
            New("UIGradient",{
                Color=ColorSequence.new({
                    ColorSequenceKeypoint.new(0,Color3.fromRGB(55,38,82)),
                    ColorSequenceKeypoint.new(1,Color3.fromRGB(28,20,46)),
                }),
                Rotation=135, Parent=P,
            })
            -- Left stripe
            New("Frame",{
                Size=UDim2.new(0,2,1,-16),
                Position=UDim2.fromOffset(0,8),
                BackgroundColor3=T.Accent,
                BackgroundTransparency=0.35,
                ZIndex=6, Parent=P,
            },{Corner(1)})

            local Inner=New("Frame",{
                Size=UDim2.new(1,0,0,0),
                AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1,
                Position=UDim2.fromOffset(10,0),
                ZIndex=6, Parent=P,
            },{VList(4)})
            Inner.UIListLayout.HorizontalAlignment=Enum.HorizontalAlignment.Left

            local TL=Lbl(cfg2.Title,13,T.Text,GothamSemi)
            TL.Size=UDim2.new(1,0,0,18); TL.TextTransparency=0; TL.Parent=Inner

            local BL=Lbl(cfg2.Content or "",12,T.SubText)
            BL.Size=UDim2.new(1,0,0,0); BL.AutomaticSize=Enum.AutomaticSize.Y
            BL.TextTransparency=0; BL.TextYAlignment=Enum.TextYAlignment.Top
            BL.Parent=Inner

            local Obj={}
            function Obj:SetTitle(t) TL.Text=t; TL.TextTransparency=0 end
            function Obj:SetContent(t) BL.Text=t; BL.TextTransparency=0 end
            function Obj:SetVisible(v) P.Visible=v end
            return Obj
        end

        -- ──────────────── LABEL ──────────────────────────────
        function Tab:AddLabel(cfg2)
            local text=type(cfg2)=="string" and cfg2 or (cfg2.Text or cfg2.Title or "")
            local col=(type(cfg2)=="table" and cfg2.Color) or T.TextDim

            local F=New("Frame",{
                Size=UDim2.new(1,0,0,24),
                BackgroundTransparency=1,
                ZIndex=5, Parent=Container,
            })
            local L=Lbl(text,12,col)
            L.Size=UDim2.new(1,-12,1,0)
            L.Position=UDim2.fromOffset(12,0)
            L.ZIndex=6; L.TextTransparency=0; L.Parent=F

            local O={}
            function O:SetText(t) L.Text=t; L.TextTransparency=0 end
            function O:SetColor(c) L.TextColor3=c end
            return O
        end

        -- ──────────────── SECTION ────────────────────────────
        function Tab:AddSection(cfg2)
            local text=type(cfg2)=="string" and cfg2 or (cfg2.Title or "")

            local SF=New("Frame",{
                Size=UDim2.new(1,0,0,30),
                BackgroundTransparency=1,
                ZIndex=5, Parent=Container,
            })
            -- Section text (Fluent uses bold heading, not just a line)
            local SL=Lbl(text,13,T.Text,GothamSemi)
            SL.Size=UDim2.new(1,-12,0,16)
            SL.Position=UDim2.fromOffset(12,6)
            SL.ZIndex=6; SL.TextTransparency=0; SL.Parent=SF

            -- Underline
            New("Frame",{
                Size=UDim2.new(1,-12,0,1),
                Position=UDim2.new(0,6,1,-1),
                BackgroundColor3=T.SectionLine,
                BackgroundTransparency=0.25,
                ZIndex=5, Parent=SF,
            },{Corner(1)})
        end

        return Tab
    end  -- Window:AddTab

    -- ══════════════════════════════════════
    --           PREMIUM TAB
    -- ══════════════════════════════════════
    function Window:AddPremiumTab(cfg)
        cfg=cfg or {}
        assert(cfg.GamepassId,"AddPremiumTab: needs GamepassId")
        local gpId=cfg.GamepassId
        local owned,verified=false,false

        local PTab=self:AddTab({Title=cfg.Title or "Premium",Icon=cfg.Icon or "crown"})

        -- Gate overlay — parented to ContentArea (NOT the Container) so it
        -- never scrolls. Visibility is synced to the premium tab's container.
        local Gate=New("Frame",{
            Size=UDim2.fromScale(1,1),
            BackgroundColor3=T.WindowBg,
            BackgroundTransparency=0.02,
            ZIndex=30, Visible=false,
            Parent=ContentArea,
        },{Corner(8)})
        New("UIGradient",{
            Color=ColorSequence.new({
                ColorSequenceKeypoint.new(0,Color3.fromRGB(38,28,58)),
                ColorSequenceKeypoint.new(1,Color3.fromRGB(18,12,30)),
            }),
            Rotation=135, Parent=Gate,
        })

        -- Lock icon + glow
        New("Frame",{
            Size=UDim2.fromOffset(76,76),
            AnchorPoint=Vector2.new(0.5,0),
            Position=UDim2.new(0.5,0,0,22),
            BackgroundColor3=T.Accent,
            BackgroundTransparency=0.8,
            ZIndex=30, Parent=Gate,
        },{Corner(38)})
        local LockIco=Img(Icons["lock"] or "",UDim2.fromOffset(42,42),T.Accent)
        LockIco.AnchorPoint=Vector2.new(0.5,0)
        LockIco.Position=UDim2.new(0.5,0,0,27)
        LockIco.ZIndex=31; LockIco.Parent=Gate

        local GTL=Lbl("Premium Required",16,T.Text,GothamSemi,Enum.TextXAlignment.Center)
        GTL.Size=UDim2.new(1,-20,0,22)
        GTL.Position=UDim2.new(0,10,0,82)
        GTL.ZIndex=31; GTL.TextTransparency=0; GTL.Parent=Gate

        local GSL=Lbl(
            "You do not own this gamepass.\nPurchase it to unlock premium features.",
            12,T.SubText,GothamReg,Enum.TextXAlignment.Center)
        GSL.Size=UDim2.new(1,-40,0,36)
        GSL.Position=UDim2.new(0,20,0,110)
        GSL.ZIndex=31; GSL.TextTransparency=0; GSL.TextWrapped=true; GSL.Parent=Gate

        -- Buy button
        local BuyBtn=New("TextButton",{
            Size=UDim2.fromOffset(172,36),
            AnchorPoint=Vector2.new(0.5,0),
            Position=UDim2.new(0.5,0,0,160),
            BackgroundColor3=T.Accent,
            Text="", ZIndex=32,
            Parent=Gate,
        },{
            Corner(9),
            Stroke(T.AccentHover,1,0.4),
            New("UIGradient",{
                Color=ColorSequence.new(T.AccentHover,T.AccentDark),
                Rotation=90,
            }),
        })
        local BuyL=Lbl("Get Premium",13,T.Text,GothamSemi,Enum.TextXAlignment.Center)
        BuyL.Size=UDim2.fromScale(1,1); BuyL.ZIndex=33; BuyL.TextTransparency=0
        BuyL.Parent=BuyBtn
        BuyBtn.MouseEnter:Connect(function() Tween(BuyBtn,TI_FAST,{BackgroundColor3=T.AccentHover}) end)
        BuyBtn.MouseLeave:Connect(function() Tween(BuyBtn,TI_FAST,{BackgroundColor3=T.Accent}) end)
        BuyBtn.MouseButton1Click:Connect(function()
            MarketplaceService:PromptGamePassPurchase(LocalPlayer,gpId)
        end)

        local function CheckOwn()
            local ok,res=pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId,gpId)
            end)
            verified=true; owned=ok and res or false
            if owned then
                Tween(Gate,TI_MED,{BackgroundTransparency=1})
                task.delay(0.35,function() Gate.Visible=false end)
                Library:Notify({
                    Title="Premium Unlocked",
                    Content="Your premium features are now active.",
                    Type="success", Duration=5,
                })
            end
        end
        task.spawn(CheckOwn)

        -- Show/hide Gate in lockstep with the Premium tab's Container.
        -- This is what keeps the gate from appearing on other tabs and
        -- ensures it overlays correctly when Premium is selected.
        PTab.Container:GetPropertyChangedSignal("Visible"):Connect(function()
            if not owned then
                Gate.Visible = PTab.Container.Visible
            end
        end)

        MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p,gp,bought)
            if p==LocalPlayer and gp==gpId and bought then CheckOwn() end
        end)

        local function Guard(fn)
            return function(...)
                local ok2,res2=pcall(function()
                    return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId,gpId)
                end)
                if ok2 and res2 then owned=true; SafeCB(fn,...)
                else owned=false; warn("[AmethystUI] Premium blocked – not owned.") end
            end
        end

        local W={}
        function W:AddButton(c)  c.Callback=Guard(c.Callback) return PTab:AddButton(c) end
        function W:AddToggle(i,c) c.Callback=Guard(c.Callback) return PTab:AddToggle(i,c) end
        function W:AddSlider(i,c) c.Callback=Guard(c.Callback) return PTab:AddSlider(i,c) end
        function W:AddInput(i,c)  c.Callback=Guard(c.Callback) return PTab:AddInput(i,c) end
        function W:AddParagraph(c) return PTab:AddParagraph(c) end
        function W:AddLabel(c)    return PTab:AddLabel(c) end
        function W:AddSection(c)  return PTab:AddSection(c) end
        function W:IsOwned()      return owned end
        function W:Select()       PTab.Select() end
        return W
    end

    function Window:Destroy() DoClose() end
    self.Options=Window.Options
    return Window
end

return Library

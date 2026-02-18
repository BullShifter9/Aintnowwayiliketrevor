--[[
╔═══════════════════════════════════════════════════════╗
║              O M N I L I B  ·  GUI Library            ║
║          Custom Roblox UI · Mobile Compatible         ║
║                    By Azzakirms                       ║
╚═══════════════════════════════════════════════════════╝

  USAGE (in your script):
    local OmniLib = loadstring(game:HttpGet("YOUR_RAW_GITHUB_LINK"))()

    local Window = OmniLib:CreateWindow({
        Title    = "MyHub",
        SubTitle = "v1.0",
    })

    local Tab = Window:AddTab("Visuals", "👁")

    Tab:AddSection("ESP")
    Tab:AddToggle({ Title="Player ESP", Desc="Show outlines", Default=true, Callback=function(v) end })
    Tab:AddButton({ Title="Do Thing",   Desc="Click me",      Callback=function() end })
    Tab:AddLabel("Some info text here")

    OmniLib:Notify("Title", "Body text", "success", 4)
    -- types: "info" | "success" | "warn" | "error"
--]]

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

------------------------------------------------------------
-- THEME
------------------------------------------------------------
local T = {
    BG0     = Color3.fromRGB(8,   9,  16),
    BG1     = Color3.fromRGB(13,  15,  26),
    BG2     = Color3.fromRGB(18,  21,  38),
    BG3     = Color3.fromRGB(24,  28,  50),
    BG4     = Color3.fromRGB(32,  37,  66),
    Accent  = Color3.fromRGB(82,  148, 255),
    AccentB = Color3.fromRGB(0,   210, 170),
    AccentC = Color3.fromRGB(140,  80, 255),
    TextHi  = Color3.fromRGB(235, 240, 255),
    TextMid = Color3.fromRGB(150, 165, 210),
    TextLow = Color3.fromRGB(80,   95, 145),
    Green   = Color3.fromRGB(50,  220, 130),
    Red     = Color3.fromRGB(255,  70,  80),
    Yellow  = Color3.fromRGB(255, 200,  50),
    Sep     = Color3.fromRGB(28,   33,  60),
    R       = UDim.new(0, 8),
    RLg     = UDim.new(0, 14),
}

------------------------------------------------------------
-- INTERNAL HELPERS
------------------------------------------------------------
local function Tw(inst, props, t, sty, dir)
    sty = sty or Enum.EasingStyle.Quart
    dir = dir  or Enum.EasingDirection.Out
    return TweenService:Create(inst, TweenInfo.new(t or 0.3, sty, dir), props)
end
local function TwPlay(inst, props, t, sty, dir)
    Tw(inst, props, t, sty, dir):Play()
end
local function TwWait(inst, props, t, sty, dir)
    -- NOTE: never use Completed:Wait() — it hangs on many executors.
    -- Play tween + sleep for its duration instead.
    Tw(inst, props, t, sty, dir):Play()
    task.wait(t or 0.3)
end

local function N(class, props)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do
        i[k] = v
    end
    return i
end

local function Cor(r, p)
    local c = N("UICorner", { CornerRadius = r or T.R })
    c.Parent = p; return c
end

local function Stk(col, th, tr, p)
    local s = N("UIStroke", { Color = col, Thickness = th or 1, Transparency = tr or 0 })
    s.Parent = p; return s
end

local function Grad(cols, rot, p)
    local kp = {}
    for i, v in ipairs(cols) do
        kp[i] = ColorSequenceKeypoint.new((i-1)/(#cols-1), v)
    end
    local g = N("UIGradient", { Color = ColorSequence.new(kp), Rotation = rot or 0 })
    g.Parent = p; return g
end

local function List(sp, dir, p)
    local l = N("UIListLayout", {
        SortOrder     = Enum.SortOrder.LayoutOrder,
        FillDirection = dir or Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, sp or 6),
    })
    l.Parent = p; return l
end

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

------------------------------------------------------------
-- DRAG UTIL  (mouse + touch)
------------------------------------------------------------
local function Draggable(handle, target)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = inp.Position; sp = target.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not drag then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - ds
            target.Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
end

------------------------------------------------------------
-- SAFE GUI PARENT
------------------------------------------------------------
local function SafeGui(name, order)
    local sg = N("ScreenGui", {
        Name           = name,
        ResetOnSpawn   = false,
        DisplayOrder   = order or 10,
        IgnoreGuiInset = true,
    })
    if syn and syn.protect_gui then syn.protect_gui(sg) end
    local ok = pcall(function() sg.Parent = CoreGui end)
    if not ok or not sg.Parent then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    return sg
end

------------------------------------------------------------
-- ════════════════════════════════════════
--        L O A D E R  (v2 — Glitch/Neon)
-- ════════════════════════════════════════
-- Transparent background, floating neon card.
-- Segmented bar replaces the bugged fill-from-0 bar.
-- No Completed:Wait — safe on all executors.
------------------------------------------------------------
local LoaderGui = SafeGui("OmniLoader", 999)

-- Fully transparent backdrop (clear background as requested)
local Cover = N("Frame", {
    Size                  = UDim2.new(1,0,1,0),
    BackgroundTransparency= 1,
    BorderSizePixel       = 0,
    Parent                = LoaderGui,
})

-- Soft dark vignette behind card only (not full screen)
local Vignette = N("Frame", {
    Size            = UDim2.new(0, IsMobile and 360 or 480, 0, IsMobile and 300 or 340),
    Position        = UDim2.new(0.5,0,1.3,0),   -- starts below screen
    AnchorPoint     = Vector2.new(0.5,0.5),
    BackgroundColor3= Color3.fromRGB(0,0,0),
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
    ZIndex          = 2,
    Parent          = Cover,
})
Cor(UDim.new(0,24), Vignette)

-- Glowing border card
local CW = IsMobile and 300 or 380
local CH = IsMobile and 240 or 270

local Card = N("Frame", {
    Size            = UDim2.new(0, CW, 0, CH),
    Position        = UDim2.new(0.5,0,1.3,0),   -- starts below screen
    AnchorPoint     = Vector2.new(0.5,0.5),
    BackgroundColor3= Color3.fromRGB(6,8,18),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    ZIndex          = 3,
    Parent          = Cover,
})
Cor(UDim.new(0,16), Card)

-- Animated neon border (strokes cycle color in RunLoader)
local CardStk = Stk(T.Accent, 2, 0, Card)

-- Top accent stripe
local TopStripe = N("Frame", {
    Size            = UDim2.new(0,0,0,2),
    BackgroundColor3= T.Accent,
    BorderSizePixel = 0,
    ZIndex          = 4,
    Parent          = Card,
})
Cor(UDim.new(0,2), TopStripe)
Grad({T.AccentC, T.Accent, T.AccentB}, 0, TopStripe)

-- Inner glass sheen
local Sheen = N("Frame", {
    Size            = UDim2.new(1,0,0.45,0),
    Position        = UDim2.new(0,0,0,0),
    BackgroundColor3= Color3.fromRGB(255,255,255),
    BackgroundTransparency = 0.96,
    BorderSizePixel = 0,
    ZIndex          = 4,
    Parent          = Card,
})
Cor(UDim.new(0,16), Sheen)

-- Icon box
local IB = N("Frame", {
    Size            = UDim2.new(0,52,0,52),
    Position        = UDim2.new(0.5,0,0,18),
    AnchorPoint     = Vector2.new(0.5,0),
    BackgroundColor3= Color3.fromRGB(10,14,30),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex          = 5,
    Parent          = Card,
})
Cor(UDim.new(0,12), IB)
local IBStk = Stk(T.Accent, 1.5, 0.2, IB)

local ILbl = N("TextLabel", {
    Size                = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Text                = "◈",
    TextColor3          = T.Accent,
    TextSize            = 26,
    Font                = Enum.Font.GothamBold,
    ZIndex              = 6,
    Parent              = IB,
})

-- Title
local LTitle = N("TextLabel", {
    Size                = UDim2.new(1,-24,0,32),
    Position            = UDim2.new(0,12,0,80),
    BackgroundTransparency = 1,
    Text                = "OMNIHUB",
    TextColor3          = T.TextHi,
    TextSize            = IsMobile and 22 or 26,
    Font                = Enum.Font.GothamBold,
    TextXAlignment      = Enum.TextXAlignment.Center,
    ZIndex              = 5,
    Parent              = Card,
})

-- Subtitle / version
local LSub = N("TextLabel", {
    Size                = UDim2.new(1,-24,0,14),
    Position            = UDim2.new(0,12,0,114),
    BackgroundTransparency = 1,
    Text                = "By Azzakirms",
    TextColor3          = T.TextLow,
    TextSize            = 10,
    Font                = Enum.Font.Gotham,
    TextXAlignment      = Enum.TextXAlignment.Center,
    ZIndex              = 5,
    Parent              = Card,
})

-- Divider
N("Frame", {
    Size            = UDim2.new(0.6,0,0,1),
    Position        = UDim2.new(0.2,0,0,136),
    BackgroundColor3= T.Sep,
    BorderSizePixel = 0,
    ZIndex          = 5,
    Parent          = Card,
})

-- Status + percentage row
local LStat = N("TextLabel", {
    Size                = UDim2.new(1,-52,0,14),
    Position            = UDim2.new(0,14,0,145),
    BackgroundTransparency = 1,
    Text                = "Initializing",
    TextColor3          = T.TextMid,
    TextSize            = 10,
    Font                = Enum.Font.Gotham,
    TextXAlignment      = Enum.TextXAlignment.Left,
    ZIndex              = 5,
    Parent              = Card,
})

local LPct = N("TextLabel", {
    Size                = UDim2.new(0,40,0,14),
    Position            = UDim2.new(1,-52,0,145),
    BackgroundTransparency = 1,
    Text                = "0%",
    TextColor3          = T.Accent,
    TextSize            = 10,
    Font                = Enum.Font.GothamBold,
    TextXAlignment      = Enum.TextXAlignment.Right,
    ZIndex              = 5,
    Parent              = Card,
})

-- ── Segmented progress bar (10 blocks) ───────────────────────────────
-- Segments are filled individually — no UDim2.new(pct,0,1,0) bug.
local SEG_COUNT  = 10
local SEG_GAP    = 4
local BAR_H      = 8
local BAR_Y      = 168
local BAR_W      = CW - 28   -- total bar width

local SegBar = N("Frame", {
    Size            = UDim2.new(0, BAR_W, 0, BAR_H),
    Position        = UDim2.new(0, 14, 0, BAR_Y),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex          = 5,
    Parent          = Card,
})

local segW = math.floor((BAR_W - (SEG_COUNT-1)*SEG_GAP) / SEG_COUNT)
local Segs = {}
for i = 1, SEG_COUNT do
    local x = (i-1) * (segW + SEG_GAP)
    local s = N("Frame", {
        Size            = UDim2.new(0, segW, 1, 0),
        Position        = UDim2.new(0, x, 0, 0),
        BackgroundColor3= Color3.fromRGB(22,28,55),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex          = 6,
        Parent          = SegBar,
    })
    Cor(UDim.new(0,3), s)
    Segs[i] = s
end

-- Footer tagline
N("TextLabel", {
    Size                = UDim2.new(1,-24,0,12),
    Position            = UDim2.new(0,12,0,188),
    BackgroundTransparency = 1,
    Text                = "secure  ·  fast  ·  undetected",
    TextColor3          = T.TextLow,
    TextSize            = 9,
    Font                = Enum.Font.Gotham,
    TextXAlignment      = Enum.TextXAlignment.Center,
    ZIndex              = 5,
    Parent              = Card,
})

-- Moving scan-line effect
local ScanLine = N("Frame", {
    Size            = UDim2.new(1,0,0,1),
    Position        = UDim2.new(0,0,0,0),
    BackgroundColor3= T.Accent,
    BackgroundTransparency = 0.65,
    BorderSizePixel = 0,
    ZIndex          = 7,
    Parent          = Card,
})

------------------------------------------------------------
-- LOADER RUNNER
------------------------------------------------------------
local function RunLoader(title, subtitle, steps, done)
    LTitle.Text = title    or "OMNIHUB"
    LSub.Text   = subtitle or "By Azzakirms"

    -- Track filled segments (0 = none lit, 10 = all lit)
    local filledSegs = 0

    local function setSegments(targetPct)
        -- targetPct: 0.0 – 1.0
        local target = math.max(0, math.min(SEG_COUNT, math.floor(targetPct * SEG_COUNT + 0.5)))
        -- always advance, never go backward
        if target <= filledSegs then
            -- still update label
            LPct.Text = math.floor(targetPct * 100) .. "%"
            return
        end
        -- light up one segment at a time
        for i = filledSegs + 1, target do
            Segs[i].BackgroundColor3 = T.Accent
            Grad({T.AccentC, T.Accent, T.AccentB}, 0, Segs[i])
            -- pulse the new seg briefly
            TwPlay(Segs[i], {BackgroundTransparency=0.35}, 0.08)
            task.wait(0.06)
            TwPlay(Segs[i], {BackgroundTransparency=0}, 0.1)
            task.wait(0.04)
        end
        filledSegs = target
        LPct.Text  = math.floor(targetPct * 100) .. "%"
    end

    -- ── slide card in ────────────────────────────────────────────────
    TwPlay(Card,     {Position = UDim2.new(0.5,0,0.5,0)}, 0.55,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TwPlay(Vignette, {Position = UDim2.new(0.5,0,0.5,0)}, 0.55,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.wait(0.38)
    TwPlay(TopStripe, {Size = UDim2.new(1,0,0,2)}, 0.45)
    task.wait(0.5)

    -- ── neon border color cycle (fire and forget) ─────────────────────
    local borderActive = true
    task.spawn(function()
        local colors = {T.Accent, T.AccentC, T.AccentB, T.Accent}
        local ci = 1
        while borderActive do
            ci = (ci % #colors) + 1
            TwPlay(CardStk, {Color=colors[ci]}, 1.2, Enum.EasingStyle.Sine)
            TwPlay(IBStk,   {Color=colors[ci]}, 1.2, Enum.EasingStyle.Sine)
            task.wait(1.3)
        end
    end)

    -- ── scan-line (fire and forget) ────────────────────────────────────
    local scanActive = true
    task.spawn(function()
        while scanActive do
            ScanLine.Position = UDim2.new(0,0,0,0)
            TwPlay(ScanLine, {Position=UDim2.new(0,0,1,-1)}, 1.5, Enum.EasingStyle.Linear)
            task.wait(2.2)
        end
    end)

    -- ── icon glitch blink (fire and forget) ────────────────────────────
    local glitchActive = true
    local glyphSet = {"◈","⬡","◆","◈"}
    task.spawn(function()
        local gi = 1
        while glitchActive do
            task.wait(1.2 + math.random() * 0.8)
            -- quick glitch flash
            for _ = 1, 3 do
                gi = (gi % #glyphSet) + 1
                ILbl.Text = glyphSet[gi]
                TwPlay(ILbl, {TextTransparency=0.6}, 0.04)
                task.wait(0.05)
                TwPlay(ILbl, {TextTransparency=0}, 0.04)
                task.wait(0.05)
            end
            ILbl.Text = "◈"
        end
    end)

    -- ── dots on status (fire and forget) ──────────────────────────────
    local dotActive = true
    local dotBase   = "Initializing"
    local dotPat    = {"","·","··","···"}
    local di        = 0
    task.spawn(function()
        while dotActive do
            di = (di % #dotPat) + 1
            LStat.Text = dotBase .. dotPat[di]
            task.wait(0.3)
        end
    end)

    -- ── step helper ───────────────────────────────────────────────────
    local function setStep(pct, label)
        dotActive = false
        task.wait(0.04)
        dotBase   = label
        di        = 0
        LStat.Text= label
        dotActive = true
        setSegments(pct)
        task.wait(0.08)
    end

    -- ── steps ─────────────────────────────────────────────────────────
    steps = steps or {
        {0.15, "Checking modules"},
        {0.35, "Loading assets"},
        {0.60, "Applying configuration"},
        {0.85, "Connecting remotes"},
        {1.00, "Ready"},
    }

    for _, s in ipairs(steps) do
        setStep(s[1], s[2])
        task.wait(0.22 + math.random() * 0.18)
    end

    -- ── finish ────────────────────────────────────────────────────────
    borderActive  = false
    scanActive    = false
    glitchActive  = false
    dotActive     = false
    task.wait(0.04)

    -- Flash all segments green
    for i = 1, SEG_COUNT do
        Segs[i].BackgroundColor3 = T.Green
        TwPlay(Segs[i], {BackgroundTransparency=0.25}, 0.06)
        task.wait(0.03)
        TwPlay(Segs[i], {BackgroundTransparency=0}, 0.08)
    end
    LStat.Text = "✓  All systems ready"
    TwPlay(LStat,   {TextColor3 = T.Green},  0.3)
    TwPlay(ILbl,    {TextColor3 = T.Green},  0.3)
    TwPlay(CardStk, {Color = T.Green},       0.3)
    TwPlay(IBStk,   {Color = T.Green, Transparency=0}, 0.3)
    LPct.Text = "100%"
    task.wait(0.9)

    -- ── outro: card slides up and fades ───────────────────────────────
    TwPlay(Card, {
        Position             = UDim2.new(0.5,0,0.28,0),
        BackgroundTransparency = 1,
    }, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    TwPlay(Vignette, {
        Position             = UDim2.new(0.5,0,0.28,0),
        BackgroundTransparency = 1,
    }, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.wait(0.42)

    LoaderGui:Destroy()
    if done then done() end
end

------------------------------------------------------------
-- ════════════════════════════════════════
--     MAIN GUI SYSTEM
-- ════════════════════════════════════════
------------------------------------------------------------
local MainGui = SafeGui("OmniHub", 10)

------------------------------------------------------------
-- NOTIFICATIONS
------------------------------------------------------------
local NHolder = N("Frame", {
    Size = UDim2.new(0,290,1,0),
    Position = UDim2.new(1,-298,0,0),
    BackgroundTransparency = 1,
    ZIndex = 200,
    Parent = MainGui,
})
List(8, nil, NHolder)
local nhPad = N("UIPadding",{PaddingTop=UDim.new(0,12)}); nhPad.Parent=NHolder

local function Notify(title, body, ntype, dur)
    dur   = dur   or 4
    ntype = ntype or "info"
    local ac = ntype=="success" and T.Green
            or ntype=="warn"    and T.Yellow
            or ntype=="error"   and T.Red
            or T.Accent

    local nf = N("Frame",{
        Size=UDim2.new(1,0,0,60),
        BackgroundColor3=T.BG2,
        BorderSizePixel=0,
        BackgroundTransparency=1,
        ZIndex=201,
        Parent=NHolder,
    })
    Cor(T.R, nf)
    Stk(ac, 1, 0.5, nf)

    local bar = N("Frame",{
        Size=UDim2.new(0,3,1,-10),
        Position=UDim2.new(0,0,0,5),
        BackgroundColor3=ac,
        BorderSizePixel=0,
        ZIndex=202,
        Parent=nf,
    })
    Cor(UDim.new(0,2), bar)

    N("TextLabel",{
        Size=UDim2.new(1,-16,0,18),
        Position=UDim2.new(0,12,0,7),
        BackgroundTransparency=1,
        Text=title,
        TextColor3=T.TextHi,
        TextSize=13,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=202,
        Parent=nf,
    })
    N("TextLabel",{
        Size=UDim2.new(1,-16,0,26),
        Position=UDim2.new(0,12,0,27),
        BackgroundTransparency=1,
        Text=body or "",
        TextColor3=T.TextMid,
        TextSize=11,
        Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true,
        ZIndex=202,
        Parent=nf,
    })

    nf.Position = UDim2.new(1.1,0,0,0)
    TwPlay(nf,{BackgroundTransparency=0,Position=UDim2.new(0,0,0,0)},0.35,Enum.EasingStyle.Back)
    task.delay(dur, function()
        TwPlay(nf,{BackgroundTransparency=1,Position=UDim2.new(1.1,0,0,0)},0.28)
        task.wait(0.3)
        nf:Destroy()
    end)
end

------------------------------------------------------------
-- WINDOW
------------------------------------------------------------
local function CreateWindow(cfg)
    cfg = cfg or {}
    local title    = cfg.Title    or "OmniHub"
    local subtitle = cfg.SubTitle or ""

    local WW = IsMobile and 340 or 560
    local WH = IsMobile and 480 or 370
    local SW = IsMobile and 56  or 155

    local Win = N("Frame",{
        Size=UDim2.new(0,WW,0,WH),
        Position=UDim2.new(0.5,-WW/2,0.5,-WH/2),
        BackgroundColor3=T.BG1,
        BorderSizePixel=0,
        ZIndex=10,
        Parent=MainGui,
        Visible=false,
    })
    Cor(T.RLg, Win)
    Stk(T.Accent, 1.5, 0.6, Win)

    -- ── TOP BAR ──────────────────────────────────────────
    local TB = N("Frame",{
        Size=UDim2.new(1,0,0,36),
        BackgroundColor3=T.BG2,
        BorderSizePixel=0,
        ZIndex=11,
        Parent=Win,
    })
    Cor(T.RLg, TB)
    -- square off bottom corners of topbar
    N("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),
        BackgroundColor3=T.BG2,BorderSizePixel=0,ZIndex=11,Parent=TB})

    Draggable(TB, Win)

    local TStrip = N("Frame",{Size=UDim2.new(0,0,0,2),BackgroundColor3=T.Accent,BorderSizePixel=0,ZIndex=12,Parent=TB})
    Cor(T.RLg, TStrip)
    Grad({T.AccentC,T.Accent,T.AccentB}, 0, TStrip)
    TwPlay(TStrip,{Size=UDim2.new(1,0,0,2)},0.5)  -- sweep on open

    local LM = N("TextLabel",{
        Size=UDim2.new(0,24,0,24),Position=UDim2.new(0,8,0.5,0),
        AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=T.BG3,BorderSizePixel=0,
        Text="⚡",TextColor3=T.Accent,TextSize=12,Font=Enum.Font.GothamBold,
        ZIndex=12,Parent=TB,
    })
    Cor(UDim.new(0,5), LM)

    N("TextLabel",{
        Size=UDim2.new(0,IsMobile and 80 or 110,1,0),
        Position=UDim2.new(0,38,0,0),
        BackgroundTransparency=1,Text=title:upper(),
        TextColor3=T.TextHi,TextSize=IsMobile and 12 or 13,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        LetterSpacing=3,ZIndex=12,Parent=TB,
    })

    if subtitle~="" and not IsMobile then
        N("TextLabel",{
            Size=UDim2.new(0,80,1,0),Position=UDim2.new(0,155,0,0),
            BackgroundTransparency=1,Text=subtitle,
            TextColor3=T.TextLow,TextSize=10,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=TB,
        })
    end

    -- window buttons
    local function WinBtn(xOff, col, lbl)
        local b = N("TextButton",{
            Size=UDim2.new(0,24,0,24),
            Position=UDim2.new(1,xOff,0.5,0),
            AnchorPoint=Vector2.new(1,0.5),
            BackgroundColor3=col,BackgroundTransparency=0.35,
            BorderSizePixel=0,
            Text=lbl,TextColor3=T.TextHi,TextSize=12,Font=Enum.Font.GothamBold,
            ZIndex=12,Parent=TB,
        })
        Cor(UDim.new(0,6), b)
        b.MouseEnter:Connect(function() TwPlay(b,{BackgroundTransparency=0},0.15) end)
        b.MouseLeave:Connect(function() TwPlay(b,{BackgroundTransparency=0.35},0.15) end)
        return b
    end

    local CloseB = WinBtn(-8,  T.Red,    "✕")
    local MinB   = WinBtn(-36, T.Yellow, "─")

    local minimized = false
    MinB.MouseButton1Click:Connect(function()
        minimized = not minimized
        TwPlay(Win,{Size=UDim2.new(0,WW,0,minimized and 36 or WH)},0.3,Enum.EasingStyle.Quart)
    end)
    CloseB.MouseButton1Click:Connect(function()
        TwPlay(Win,{BackgroundTransparency=1,Size=UDim2.new(0,WW,0,0)},0.25,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
        task.delay(0.28,function()
            Win.Visible=false
            Win.Size=UDim2.new(0,WW,0,WH)
            Win.BackgroundTransparency=0
        end)
    end)

    -- ── SIDEBAR ───────────────────────────────────────────
    local Side = N("Frame",{
        Size=UDim2.new(0,SW,1,-36),Position=UDim2.new(0,0,0,36),
        BackgroundColor3=T.BG2,BorderSizePixel=0,ZIndex=11,Parent=Win,
    })
    N("Frame",{Size=UDim2.new(0,14,1,0),Position=UDim2.new(1,-14,0,0),
        BackgroundColor3=T.BG2,BorderSizePixel=0,ZIndex=10,Parent=Side})
    N("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,0,1,-14),
        BackgroundColor3=T.BG2,BorderSizePixel=0,ZIndex=10,Parent=Side})

    local SideScroll = N("ScrollingFrame",{
        Size=UDim2.new(1,0,1,-8),Position=UDim2.new(0,0,0,6),
        BackgroundTransparency=1,BorderSizePixel=0,
        ScrollBarThickness=0,ZIndex=12,Parent=Side,
    })
    List(4, nil, SideScroll)
    local ssp = N("UIPadding",{PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)})
    ssp.Parent = SideScroll

    -- ── CONTENT AREA ──────────────────────────────────────
    local Content = N("Frame",{
        Size=UDim2.new(1,-SW,1,-36),Position=UDim2.new(0,SW,0,36),
        BackgroundColor3=T.BG1,BorderSizePixel=0,
        ZIndex=11,ClipsDescendants=true,Parent=Win,
    })
    N("Frame",{Size=UDim2.new(0,14,1,0),Position=UDim2.new(0,0,0,0),
        BackgroundColor3=T.BG1,BorderSizePixel=0,ZIndex=10,Parent=Content})

    -- ── TAB + ELEMENT SYSTEM ──────────────────────────────
    local Pages     = {}
    local TabBtns   = {}
    local ActiveTab = nil

    local function MakePage()
        local sf = N("ScrollingFrame",{
            Size=UDim2.new(1,-12,1,-8),Position=UDim2.new(0,6,0,5),
            BackgroundTransparency=1,BorderSizePixel=0,
            ScrollBarThickness=3,
            ScrollBarImageColor3=T.Accent,
            ScrollBarImageTransparency=0.45,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ZIndex=12,Parent=Content,Visible=false,
        })
        List(5, nil, sf)
        return sf
    end

    -- SECTION
    local function _Section(page, t)
        local f = N("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,
            LayoutOrder=#page:GetChildren()+1,ZIndex=13,Parent=page})
        N("TextLabel",{Size=UDim2.new(1,-4,1,0),BackgroundTransparency=1,
            Text=t:upper(),TextColor3=T.Accent,TextSize=9,
            Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,
            LetterSpacing=3,ZIndex=13,Parent=f})
        N("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
            BackgroundColor3=T.Sep,BorderSizePixel=0,ZIndex=13,Parent=f})
    end

    -- TOGGLE
    local function _Toggle(page, cfg)
        local on = cfg.Default or false
        local h  = cfg.Desc and 50 or 40
        local c  = N("Frame",{Size=UDim2.new(1,0,0,h),BackgroundColor3=T.BG3,
            BorderSizePixel=0,LayoutOrder=#page:GetChildren()+1,ZIndex=13,Parent=page})
        Cor(T.R, c)
        N("TextLabel",{Size=UDim2.new(1,-54,0,18),Position=UDim2.new(0,10,0,cfg.Desc and 7 or 11),
            BackgroundTransparency=1,Text=cfg.Title or "Toggle",TextColor3=T.TextHi,
            TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=14,Parent=c})
        if cfg.Desc then
            N("TextLabel",{Size=UDim2.new(1,-54,0,14),Position=UDim2.new(0,10,0,26),
                BackgroundTransparency=1,Text=cfg.Desc,TextColor3=T.TextLow,
                TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
                ZIndex=14,Parent=c})
        end

        local tr = N("Frame",{Size=UDim2.new(0,34,0,18),Position=UDim2.new(1,-44,0.5,0),
            AnchorPoint=Vector2.new(1,0.5),BackgroundColor3=T.BG4,BorderSizePixel=0,ZIndex=14,Parent=c})
        Cor(UDim.new(1,0), tr)

        local kn = N("Frame",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,3,0.5,0),
            AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=T.TextMid,BorderSizePixel=0,ZIndex=15,Parent=tr})
        Cor(UDim.new(1,0), kn)

        local function setState(v, silent)
            on = v
            if on then
                TwPlay(tr,{BackgroundColor3=T.Accent},0.18)
                TwPlay(kn,{Position=UDim2.new(1,-15,0.5,0),BackgroundColor3=Color3.fromRGB(255,255,255)},0.18)
            else
                TwPlay(tr,{BackgroundColor3=T.BG4},0.18)
                TwPlay(kn,{Position=UDim2.new(0,3,0.5,0),BackgroundColor3=T.TextMid},0.18)
            end
            if not silent and cfg.Callback then cfg.Callback(on) end
        end
        setState(on, true)

        local btn = N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text="",ZIndex=16,Parent=c})
        btn.MouseButton1Click:Connect(function() setState(not on) end)
        c.MouseEnter:Connect(function() TwPlay(c,{BackgroundColor3=T.BG4},0.12) end)
        c.MouseLeave:Connect(function() TwPlay(c,{BackgroundColor3=T.BG3},0.12) end)

        return { Set=setState, Get=function() return on end }
    end

    -- BUTTON
    local function _Button(page, cfg)
        local h  = cfg.Desc and 50 or 40
        local c  = N("Frame",{Size=UDim2.new(1,0,0,h),BackgroundColor3=T.BG3,
            BorderSizePixel=0,LayoutOrder=#page:GetChildren()+1,ZIndex=13,Parent=page})
        Cor(T.R, c)
        N("TextLabel",{Size=UDim2.new(1,-50,0,18),Position=UDim2.new(0,10,0,cfg.Desc and 7 or 11),
            BackgroundTransparency=1,Text=cfg.Title or "Button",TextColor3=T.TextHi,
            TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=14,Parent=c})
        if cfg.Desc then
            N("TextLabel",{Size=UDim2.new(1,-50,0,14),Position=UDim2.new(0,10,0,26),
                BackgroundTransparency=1,Text=cfg.Desc,TextColor3=T.TextLow,
                TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
                ZIndex=14,Parent=c})
        end

        local arr = N("TextLabel",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-36,0.5,0),
            AnchorPoint=Vector2.new(1,0.5),BackgroundColor3=T.BG4,
            Text="›",TextColor3=T.Accent,TextSize=17,Font=Enum.Font.GothamBold,
            ZIndex=14,Parent=c})
        Cor(UDim.new(0,6), arr)

        local btn = N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text="",ZIndex=16,Parent=c})

        c.MouseEnter:Connect(function()
            TwPlay(c,{BackgroundColor3=T.BG4},0.12)
            TwPlay(arr,{BackgroundColor3=T.Accent},0.12)
        end)
        c.MouseLeave:Connect(function()
            TwPlay(c,{BackgroundColor3=T.BG3},0.12)
            TwPlay(arr,{BackgroundColor3=T.BG4},0.12)
        end)
        btn.MouseButton1Click:Connect(function()
            TwPlay(c,{BackgroundColor3=Color3.fromRGB(28,48,88)},0.07)
            task.delay(0.12,function() TwPlay(c,{BackgroundColor3=T.BG4},0.12) end)
            if cfg.Callback then cfg.Callback() end
        end)
    end

    -- LABEL
    local function _Label(page, text)
        N("TextLabel",{
            Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,
            Text=text,TextColor3=T.TextMid,TextSize=11,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,
            LayoutOrder=#page:GetChildren()+1,ZIndex=13,Parent=page,
        })
    end

    -- ADD TAB
    local function AddTab(tabTitle, icon)
        local page  = MakePage()
        local order = #TabBtns + 1
        local BH    = IsMobile and 44 or 34

        local tb = N("TextButton",{
            Size=UDim2.new(1,0,0,BH),BackgroundColor3=T.BG2,
            BackgroundTransparency=0,BorderSizePixel=0,
            Text="",LayoutOrder=order,ZIndex=13,Parent=SideScroll,
        })
        Cor(T.R, tb)

        local ind = N("Frame",{Size=UDim2.new(0,3,0.5,0),Position=UDim2.new(0,0,0.25,0),
            BackgroundColor3=T.Accent,BorderSizePixel=0,ZIndex=15,Visible=false,Parent=tb})
        Cor(UDim.new(0,2), ind)

        local ic = N("TextLabel",{
            Size=UDim2.new(0,22,1,0),Position=UDim2.new(0,IsMobile and 5 or 8,0,0),
            BackgroundTransparency=1,Text=icon or "·",TextColor3=T.TextLow,
            TextSize=IsMobile and 17 or 14,Font=Enum.Font.GothamBold,
            Name="Icon",ZIndex=14,Parent=tb,
        })

        local tx
        if not IsMobile then
            tx = N("TextLabel",{
                Size=UDim2.new(1,-32,1,0),Position=UDim2.new(0,30,0,0),
                BackgroundTransparency=1,Text=tabTitle,TextColor3=T.TextMid,
                TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
                Name="Label",ZIndex=14,Parent=tb,
            })
        end

        local function Activate()
            if ActiveTab and TabBtns[ActiveTab] then
                local old = TabBtns[ActiveTab]
                TwPlay(old.frame,{BackgroundColor3=T.BG2},0.18)
                old.ind.Visible = false
                TwPlay(old.ic,{TextColor3=T.TextLow},0.18)
                if old.tx then TwPlay(old.tx,{TextColor3=T.TextMid},0.18) end
                Pages[ActiveTab].Visible = false
            end
            ActiveTab = tabTitle
            TwPlay(tb,{BackgroundColor3=T.BG3},0.18)
            ind.Visible = true
            TwPlay(ic,{TextColor3=T.Accent},0.18)
            if tx then TwPlay(tx,{TextColor3=T.TextHi},0.18) end
            page.Visible = true
        end

        tb.MouseButton1Click:Connect(Activate)
        tb.MouseEnter:Connect(function()
            if ActiveTab ~= tabTitle then TwPlay(tb,{BackgroundColor3=Color3.fromRGB(22,26,48)},0.12) end
        end)
        tb.MouseLeave:Connect(function()
            if ActiveTab ~= tabTitle then TwPlay(tb,{BackgroundColor3=T.BG2},0.12) end
        end)

        TabBtns[tabTitle] = {frame=tb, ind=ind, ic=ic, tx=tx}
        Pages[tabTitle]   = page

        if order == 1 then task.defer(Activate) end

        -- return tab API
        return {
            AddSection = function(_, t)   _Section(page, t) end,
            AddToggle  = function(_, cfg) return _Toggle(page, cfg) end,
            AddButton  = function(_, cfg) _Button(page, cfg) end,
            AddLabel   = function(_, t)   _Label(page, t) end,
        }
    end

    -- Key toggle (RightShift / LeftCtrl)
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Enum.KeyCode.RightShift
        or inp.KeyCode == Enum.KeyCode.LeftControl then
            if not Win.Visible then
                Win.Visible = true
                Win.Size    = UDim2.new(0,WW,0,0)
                TwPlay(Win,{Size=UDim2.new(0,WW,0,WH)},0.35,Enum.EasingStyle.Back)
            else
                TwPlay(Win,{Size=UDim2.new(0,WW,0,0)},0.25,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
                task.delay(0.27,function()
                    Win.Visible = false
                    Win.Size    = UDim2.new(0,WW,0,WH)
                end)
            end
        end
    end)

    -- Window API
    return {
        AddTab = AddTab,
        Show   = function()
            Win.Visible = true
            Win.Size    = UDim2.new(0,WW,0,0)
            Win.BackgroundTransparency = 1
            TwPlay(Win,{Size=UDim2.new(0,WW,0,WH),BackgroundTransparency=0},0.42,Enum.EasingStyle.Back)
        end,
        Hide   = function()
            TwPlay(Win,{BackgroundTransparency=1,Size=UDim2.new(0,WW,0,0)},0.25,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
            task.delay(0.28,function() Win.Visible=false; Win.Size=UDim2.new(0,WW,0,WH); Win.BackgroundTransparency=0 end)
        end,
    }
end

------------------------------------------------------------
-- PUBLIC API
------------------------------------------------------------
local OmniLib = {
    Notify       = Notify,
    CreateWindow = CreateWindow,
    RunLoader    = RunLoader,
}

return OmniLib

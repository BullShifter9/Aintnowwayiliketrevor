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
    local tw = Tw(inst, props, t, sty, dir)
    tw:Play(); tw.Completed:Wait()
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
--        L O A D E R
-- ════════════════════════════════════════
------------------------------------------------------------
local LoaderGui = SafeGui("OmniLoader", 999)

local Cover = N("Frame", {
    Size = UDim2.new(1,0,1,0),
    BackgroundColor3 = T.BG0,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Parent = LoaderGui,
})

-- radial glow (single image, no grid of boxes)
local BGGlow = N("ImageLabel", {
    Size = UDim2.new(0, 700, 0, 700),
    Position = UDim2.new(0.5,0,0.5,0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://5028857084",
    ImageColor3 = T.Accent,
    ImageTransparency = 0.88,
    ZIndex = 2,
    Parent = Cover,
})

local CW = IsMobile and 310 or 400
local CH = IsMobile and 250 or 270

local Card = N("Frame", {
    Size = UDim2.new(0, CW, 0, CH),
    Position = UDim2.new(0.5,0,0.72,0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = T.BG1,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = Cover,
})
Cor(T.RLg, Card)
Stk(T.Accent, 1.5, 0.55, Card)

local TopStrip = N("Frame", {
    Size = UDim2.new(0,0,0,2),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = Card,
})
Cor(UDim.new(0,2), TopStrip)
Grad({T.AccentC, T.Accent, T.AccentB}, 0, TopStrip)

local IB = N("Frame", {
    Size = UDim2.new(0,56,0,56),
    Position = UDim2.new(0.5,0,0,22),
    AnchorPoint = Vector2.new(0.5,0),
    BackgroundColor3 = T.BG3,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = Card,
})
Cor(UDim.new(0,12), IB)
local IBStk = Stk(T.Accent, 1.5, 0.25, IB)
local ILbl = N("TextLabel", {
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Text = "⚡",
    TextColor3 = T.Accent,
    TextSize = 28,
    Font = Enum.Font.GothamBold,
    ZIndex = 5,
    Parent = IB,
})

local LTitle = N("TextLabel", {
    Size = UDim2.new(1,-30,0,36),
    Position = UDim2.new(0,15,0,87),
    BackgroundTransparency = 1,
    Text = "OMNIHUB",
    TextColor3 = T.TextHi,
    TextSize = IsMobile and 24 or 28,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 4,
    Parent = Card,
})

local LSub = N("TextLabel", {
    Size = UDim2.new(1,-30,0,16),
    Position = UDim2.new(0,15,0,126),
    BackgroundTransparency = 1,
    Text = "Loading...",
    TextColor3 = T.TextLow,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 4,
    Parent = Card,
})

N("Frame", {
    Size = UDim2.new(0.5,0,0,1),
    Position = UDim2.new(0.25,0,0,151),
    BackgroundColor3 = T.Sep,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = Card,
})

local LStat = N("TextLabel", {
    Size = UDim2.new(1,-40,0,15),
    Position = UDim2.new(0,15,0,161),
    BackgroundTransparency = 1,
    Text = "Initializing...",
    TextColor3 = T.TextMid,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
    Parent = Card,
})

local LPct = N("TextLabel", {
    Size = UDim2.new(0,38,0,15),
    Position = UDim2.new(1,-52,0,161),
    BackgroundTransparency = 1,
    Text = "0%",
    TextColor3 = T.Accent,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 4,
    Parent = Card,
})

local PT = N("Frame", {
    Size = UDim2.new(1,-30,0,5),
    Position = UDim2.new(0,15,0,184),
    BackgroundColor3 = T.BG3,
    BorderSizePixel = 0,
    ZIndex = 4,
    Parent = Card,
})
Cor(UDim.new(0,3), PT)

local PF = N("Frame", {
    Size = UDim2.new(0,0,1,0),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0,
    ZIndex = 5,
    Parent = PT,
})
Cor(UDim.new(0,3), PF)
Grad({T.AccentC, T.Accent, T.AccentB}, 0, PF)

local Shim = N("Frame", {
    Size = UDim2.new(0,45,1,0),
    Position = UDim2.new(-0.5,0,0,0),
    BackgroundColor3 = Color3.fromRGB(255,255,255),
    BackgroundTransparency = 0.72,
    BorderSizePixel = 0,
    ZIndex = 6,
    Parent = PF,
})
local shimGrad = N("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.55),
        NumberSequenceKeypoint.new(1, 1),
    }),
})
shimGrad.Parent = Shim

N("TextLabel", {
    Size = UDim2.new(1,-30,0,13),
    Position = UDim2.new(0,15,0,198),
    BackgroundTransparency = 1,
    Text = "Secure  ·  Fast  ·  Undetected",
    TextColor3 = T.TextLow,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 4,
    Parent = Card,
})

------------------------------------------------------------
-- LOADER RUNNER
------------------------------------------------------------
local function RunLoader(title, subtitle, steps, done)
    LTitle.Text = title    or "OMNIHUB"
    LSub.Text   = subtitle or "By Azzakirms"

    -- slide in
    TwPlay(Card, {Position=UDim2.new(0.5,0,0.5,0)}, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TwPlay(BGGlow, {ImageTransparency=0.82}, 0.5)
    task.wait(0.3)
    TwPlay(TopStrip, {Size=UDim2.new(1,0,0,2)}, 0.45)
    task.wait(0.5)

    local ip = true
    task.spawn(function()
        while ip do
            TwPlay(IBStk,{Transparency=0},0.7,Enum.EasingStyle.Sine)
            task.wait(0.85)
            TwPlay(IBStk,{Transparency=0.7},0.7,Enum.EasingStyle.Sine)
            task.wait(0.85)
        end
    end)

    local sl = true
    task.spawn(function()
        while sl do
            Shim.Position = UDim2.new(-0.35,0,0,0)
            TwPlay(Shim,{Position=UDim2.new(1.35,0,0,0)},1,Enum.EasingStyle.Linear)
            task.wait(1.9)
        end
    end)

    local dl = true; local dotsI = 0
    task.spawn(function()
        local dp={" ","·  ","·· ","···"}
        while dl do
            dotsI=(dotsI%#dp)+1
            local base = LStat.Text:gsub("[· ]+$","")
            LStat.Text = base..dp[dotsI]
            task.wait(0.32)
        end
    end)

    local function setStep(pct, label)
        dl=false; task.wait(0.04)
        LStat.Text = label
        LPct.Text  = math.floor(pct*100).."%"
        dl=true
        TwWait(PF,{Size=UDim2.new(pct,0,1,0)},0.48)
    end

    steps = steps or {
        {0.15,"Checking modules"},
        {0.35,"Loading assets"},
        {0.60,"Applying configuration"},
        {0.85,"Connecting remotes"},
        {1.00,"Ready"},
    }
    for _, s in ipairs(steps) do
        setStep(s[1], s[2])
        task.wait(0.28 + math.random()*0.18)
    end

    ip=false; sl=false; dl=false
    LStat.Text = "✓  Loaded successfully"
    TwPlay(LStat,{TextColor3=T.Green},0.3)
    TwPlay(ILbl, {TextColor3=T.Green},0.3)
    TwPlay(IBStk,{Color=T.Green, Transparency=0},0.3)
    task.wait(0.8)

    TwPlay(Card,{Position=UDim2.new(0.5,0,0.32,0),BackgroundTransparency=1},0.38,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
    TwWait(Cover,{BackgroundTransparency=1},0.35)
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
        TwWait(nf,{BackgroundTransparency=1,Position=UDim2.new(1.1,0,0,0)},0.28)
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

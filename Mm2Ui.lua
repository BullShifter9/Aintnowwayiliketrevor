--[[
╔══════════════════════════════════════════════════════════════╗
║                 M M 2 U I  ·  GUI Library                    ║
║        Mobile + PC  ·  Drop-in OmniLib replacement           ║
║                      By Azzakirms                            ║
╠══════════════════════════════════════════════════════════════╣
║  USAGE:                                                      ║
║  local Lib = loadstring(game:HttpGet("RAW_GITHUB_URL"))()    ║
║                                                              ║
║  local Notify = Lib.Notify                                   ║
║  Notify("Title", "Body", "success", 4)                       ║
║  -- types: "info" | "success" | "warn" | "error"            ║
║                                                              ║
║  local Win = Lib:CreateWindow({ Title="Hub", SubTitle="v1" })║
║  local Tab = Win:AddTab("Visuals", "")                    ║
║  Tab:AddSection("ESP")                                       ║
║  Tab:AddToggle({ Title="ESP", Desc="...", Default=true,      ║
║                  Callback=function(v) end })                 ║
║  Tab:AddButton({ Title="Go", Desc="...",                     ║
║                  Callback=function() end })                  ║
║  Tab:AddLabel("Info text here")                              ║
║                                                              ║
║  Lib.RunLoader("TITLE", "Subtitle", steps, function()        ║
║      Win.Show()  -- show window after loader done            ║
║  end)                                                        ║
║                                                              ║
║  MOBILE : A floating button shows/hides the window.          ║
║  PC     : RightShift or LeftCtrl toggles visibility.         ║
╚══════════════════════════════════════════════════════════════╝
--]]

-- Services
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- Platform
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Theme: MM2 crimson + dark charcoal
local T = {
    BG0     = Color3.fromRGB( 10,  10,  11),
    BG1     = Color3.fromRGB( 15,  14,  16),
    BG2     = Color3.fromRGB( 21,  20,  22),
    BG3     = Color3.fromRGB( 28,  26,  30),
    BG4     = Color3.fromRGB( 38,  35,  42),
    Accent  = Color3.fromRGB(210,  42,  48),
    AccentB = Color3.fromRGB(255,  88,  55),
    AccentC = Color3.fromRGB(240,  20,  70),
    TextHi  = Color3.fromRGB(238, 232, 228),
    TextMid = Color3.fromRGB(155, 145, 140),
    TextLow = Color3.fromRGB( 75,  68,  72),
    Green   = Color3.fromRGB( 48, 205, 105),
    Red     = Color3.fromRGB(215,  48,  52),
    Yellow  = Color3.fromRGB(255, 185,  40),
    Sep     = Color3.fromRGB( 32,  30,  34),
    R       = UDim.new(0, 7),
    RLg     = UDim.new(0, 12),
    RSm     = UDim.new(0, 4),
}

-- Helpers
local function TwPlay(inst, props, t, sty, dir)
    TweenService:Create(inst, TweenInfo.new(
        t   or 0.22,
        sty or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out
    ), props):Play()
end

local function N(class, props)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do pcall(function() i[k] = v end) end
    return i
end

local function Cor(r, p)
    return N("UICorner", { CornerRadius = r or T.R, Parent = p })
end

local function Stk(col, th, tr, p)
    return N("UIStroke", { Color=col, Thickness=th or 1, Transparency=tr or 0, Parent=p })
end

local function Grad(cols, rot, p)
    local kp = {}
    for i, v in ipairs(cols) do
        kp[i] = ColorSequenceKeypoint.new((i-1)/math.max(#cols-1,1), v)
    end
    return N("UIGradient", { Color=ColorSequence.new(kp), Rotation=rot or 0, Parent=p })
end

local function ListLayout(sp, dir, p)
    return N("UIListLayout", {
        SortOrder     = Enum.SortOrder.LayoutOrder,
        FillDirection = dir or Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, sp or 5),
        Parent        = p,
    })
end

-- Drag helper — returns dragged() fn so callers can tell tap vs drag
local function MakeDraggable(handle, target)
    local active, sPos, sUDim, moved = false, nil, nil, false
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        active = true; moved = false
        sPos   = inp.Position
        sUDim  = target.Position
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not active then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = inp.Position - sPos
        if d.Magnitude > 5 then
            moved = true
            target.Position = UDim2.new(
                sUDim.X.Scale, sUDim.X.Offset + d.X,
                sUDim.Y.Scale, sUDim.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then active = false end
    end)
    return function() return moved end
end

local function SafeGui(name, order)
    local sg = N("ScreenGui", {
        Name=name, ResetOnSpawn=false, DisplayOrder=order or 10, IgnoreGuiInset=true
    })
    if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
    if not pcall(function() sg.Parent = CoreGui end) or not sg.Parent then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    return sg
end

-- ══ NOTIFICATIONS ════════════════════════════════════════════════════
local NotifGui = SafeGui("Mm2Ui_Notify", 500)
local NW       = IsMobile and 268 or 302
local NHolder  = N("Frame", {
    Size                  = UDim2.new(0, NW, 1, 0),
    Position              = UDim2.new(1, -(NW + 8), 0, 0),
    BackgroundTransparency= 1,
    ZIndex                = 501,
    Parent                = NotifGui,
})
ListLayout(7, nil, NHolder)
N("UIPadding", { PaddingTop=UDim.new(0, IsMobile and 8 or 12), Parent=NHolder })

local function Notify(title, body, ntype, dur)
    dur   = dur   or 4
    ntype = ntype or "info"
    local ac = ntype=="success" and T.Green
            or ntype=="warn"    and T.Yellow
            or ntype=="error"   and T.Red
            or T.Accent
    local icon = ntype=="success" and "v"
              or ntype=="warn"    and "!"
              or ntype=="error"   and "x"
              or "i"
    local cardH = IsMobile and 60 or 64
    local nf = N("Frame", {
        Size=UDim2.new(1,0,0,cardH), BackgroundColor3=T.BG2,
        BackgroundTransparency=1, BorderSizePixel=0, ZIndex=502, Parent=NHolder,
    })
    Cor(T.R, nf); Stk(ac, 1, 0.5, nf)
    N("Frame", {
        Size=UDim2.new(0,3,1,-10), Position=UDim2.new(0,0,0,5),
        BackgroundColor3=ac, BorderSizePixel=0, ZIndex=503, Parent=nf,
    })
    local ib = N("Frame", {
        Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,11,0.5,0),
        AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=ac,
        BackgroundTransparency=0.78, BorderSizePixel=0, ZIndex=503, Parent=nf,
    })
    Cor(UDim.new(1,0), ib)
    N("TextLabel",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text=icon,
        TextColor3=ac, TextSize=10, Font=Enum.Font.GothamBold, ZIndex=504, Parent=ib,
    })
    N("TextLabel",{
        Size=UDim2.new(1,-42,0,16), Position=UDim2.new(0,38,0,7),
        BackgroundTransparency=1, Text=title or "",
        TextColor3=T.TextHi, TextSize=IsMobile and 11 or 12,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=503, Parent=nf,
    })
    N("TextLabel",{
        Size=UDim2.new(1,-42,0,cardH-28), Position=UDim2.new(0,38,0,25),
        BackgroundTransparency=1, Text=body or "",
        TextColor3=T.TextMid, TextSize=IsMobile and 9 or 10,
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true, ZIndex=503, Parent=nf,
    })
    nf.Position = UDim2.new(1.1, 0, 0, 0)
    TwPlay(nf, { BackgroundTransparency=0, Position=UDim2.new(0,0,0,0) },
           0.3, Enum.EasingStyle.Back)
    task.delay(dur, function()
        if not nf or not nf.Parent then return end
        TwPlay(nf, { BackgroundTransparency=1, Position=UDim2.new(1.1,0,0,0) }, 0.25)
        task.wait(0.3)
        if nf and nf.Parent then nf:Destroy() end
    end)
end

-- ══ LOADER ═══════════════════════════════════════════════════════════
local function RunLoader(title, subtitle, steps, done)
    local LGui = SafeGui("Mm2Ui_Loader", 999)
    local CW   = IsMobile and 305 or 375
    local CH   = IsMobile and 245 or 265

    local Cover = N("Frame",{
        Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.38, BorderSizePixel=0, Parent=LGui,
    })
    local Card = N("Frame",{
        Size=UDim2.new(0,CW,0,CH), Position=UDim2.new(0.5,0,1.5,0),
        AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=T.BG1,
        BorderSizePixel=0, ZIndex=3, Parent=Cover,
    })
    Cor(UDim.new(0,14), Card)
    local CStk = Stk(T.Accent, 1.5, 0, Card)

    local TStripe = N("Frame",{
        Size=UDim2.new(0,0,0,2), BackgroundColor3=T.Accent,
        BorderSizePixel=0, ZIndex=4, Parent=Card,
    })
    Cor(T.RSm, TStripe)
    Grad({T.Accent, T.AccentB, T.AccentC}, 0, TStripe)

    N("Frame",{
        Size=UDim2.new(1,0,0.38,0), BackgroundColor3=Color3.fromRGB(255,255,255),
        BackgroundTransparency=0.94, BorderSizePixel=0, ZIndex=4, Parent=Card,
    })

    local IBox = N("Frame",{
        Size=UDim2.new(0,50,0,50), Position=UDim2.new(0.5,0,0,16),
        AnchorPoint=Vector2.new(0.5,0), BackgroundColor3=T.BG3,
        BorderSizePixel=0, ZIndex=5, Parent=Card,
    })
    Cor(UDim.new(0,11), IBox)
    local IStk = Stk(T.Accent, 1.5, 0.25, IBox)
    local ILbl = N("TextLabel",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="o",
        TextColor3=T.Accent, TextSize=24, Font=Enum.Font.GothamBold,
        ZIndex=6, Parent=IBox,
    })

    N("TextLabel",{
        Size=UDim2.new(1,-20,0,30), Position=UDim2.new(0,10,0,76),
        BackgroundTransparency=1, Text=title or "LOADING",
        TextColor3=T.TextHi, TextSize=IsMobile and 20 or 24,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Center,
        ZIndex=5, Parent=Card,
    })
    N("TextLabel",{
        Size=UDim2.new(1,-20,0,14), Position=UDim2.new(0,10,0,108),
        BackgroundTransparency=1, Text=subtitle or "",
        TextColor3=T.TextLow, TextSize=9, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=5, Parent=Card,
    })
    N("Frame",{
        Size=UDim2.new(0.5,0,0,1), Position=UDim2.new(0.25,0,0,130),
        BackgroundColor3=T.Sep, BorderSizePixel=0, ZIndex=5, Parent=Card,
    })

    local LStat = N("TextLabel",{
        Size=UDim2.new(1,-50,0,13), Position=UDim2.new(0,12,0,138),
        BackgroundTransparency=1, Text="Initializing",
        TextColor3=T.TextMid, TextSize=9, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5, Parent=Card,
    })
    local LPct = N("TextLabel",{
        Size=UDim2.new(0,38,0,13), Position=UDim2.new(1,-50,0,138),
        BackgroundTransparency=1, Text="0%",
        TextColor3=T.Accent, TextSize=9, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=5, Parent=Card,
    })

    -- Segmented progress bar
    local SEG_N=10; local SEG_G=3; local BAR_H=7
    local BAR_Y=158; local BAR_W=CW-24
    local SegBar = N("Frame",{
        Size=UDim2.new(0,BAR_W,0,BAR_H), Position=UDim2.new(0,12,0,BAR_Y),
        BackgroundTransparency=1, BorderSizePixel=0, ZIndex=5, Parent=Card,
    })
    local segW = math.floor((BAR_W-(SEG_N-1)*SEG_G)/SEG_N)
    local Segs = {}
    for i=1,SEG_N do
        local x=(i-1)*(segW+SEG_G)
        local s=N("Frame",{
            Size=UDim2.new(0,segW,1,0), Position=UDim2.new(0,x,0,0),
            BackgroundColor3=T.BG4, BackgroundTransparency=0.3,
            BorderSizePixel=0, ZIndex=6, Parent=SegBar,
        })
        Cor(UDim.new(0,3), s); Segs[i]=s
    end
    N("TextLabel",{
        Size=UDim2.new(1,-20,0,11), Position=UDim2.new(0,10,0,BAR_Y+BAR_H+10),
        BackgroundTransparency=1, Text="omnihub  by azzakirms",
        TextColor3=T.TextLow, TextSize=8, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=5, Parent=Card,
    })
    local ScanLine=N("Frame",{
        Size=UDim2.new(1,0,0,1), BackgroundColor3=T.Accent,
        BackgroundTransparency=0.72, BorderSizePixel=0, ZIndex=7, Parent=Card,
    })

    task.spawn(function()
        TwPlay(Card,  {Position=UDim2.new(0.5,0,0.5,0)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        task.wait(0.38)
        TwPlay(TStripe, {Size=UDim2.new(1,0,0,2)}, 0.4)
        task.wait(0.45)

        local borderOn=true
        task.spawn(function()
            local cols={T.Accent,T.AccentB,T.AccentC,T.Accent}; local ci=1
            while borderOn do
                ci=(ci%#cols)+1
                TwPlay(CStk, {Color=cols[ci]}, 1.1, Enum.EasingStyle.Sine)
                TwPlay(IStk, {Color=cols[ci]}, 1.1, Enum.EasingStyle.Sine)
                task.wait(1.25)
            end
        end)

        local scanOn=true
        task.spawn(function()
            while scanOn do
                ScanLine.Position=UDim2.new(0,0,0,0)
                TwPlay(ScanLine,{Position=UDim2.new(0,0,1,-1)},1.5,Enum.EasingStyle.Linear)
                task.wait(2.1)
            end
        end)

        local glitchOn=true
        local glyphs={"o","*","+","o"}
        task.spawn(function()
            local gi=1
            while glitchOn do
                task.wait(1.0+math.random()*0.8)
                for _=1,2 do
                    gi=(gi%#glyphs)+1; ILbl.Text=glyphs[gi]
                    TwPlay(ILbl,{TextTransparency=0.6},0.04); task.wait(0.07)
                    TwPlay(ILbl,{TextTransparency=0},0.04);   task.wait(0.07)
                end
                ILbl.Text="o"
            end
        end)

        local dotOn=true; local dotBase="Initializing"
        local dotPat={"",".","..",".,."}; local di=0
        task.spawn(function()
            while dotOn do
                di=(di%#dotPat)+1
                if LStat and LStat.Parent then LStat.Text=dotBase..dotPat[di] end
                task.wait(0.3)
            end
        end)

        local filled=0
        local function fillTo(pct)
            local target=math.max(0,math.min(SEG_N,math.floor(pct*SEG_N+0.5)))
            LPct.Text=math.floor(pct*100).."%"
            if target<=filled then return end
            for i=filled+1,target do
                if Segs[i] and Segs[i].Parent then
                    Segs[i].BackgroundColor3=T.Accent
                    Grad({T.Accent,T.AccentB},0,Segs[i])
                    TwPlay(Segs[i],{BackgroundTransparency=0},0.1)
                    task.wait(0.045)
                end
            end
            filled=target
        end
        local function runStep(pct, label)
            dotOn=false; task.wait(0.04)
            dotBase=label; di=0; LStat.Text=label; dotOn=true
            fillTo(pct); task.wait(0.06)
        end

        steps = steps or {
            {0.15,"Checking modules"},{0.35,"Loading assets"},
            {0.60,"Connecting remotes"},{0.85,"Preparing ESP"},{1.00,"Ready"},
        }
        for _,s in ipairs(steps) do
            runStep(s[1], s[2])
            task.wait(0.20+math.random()*0.15)
        end

        borderOn=false; scanOn=false; glitchOn=false; dotOn=false
        task.wait(0.04)

        for i=1,SEG_N do
            if Segs[i] and Segs[i].Parent then
                Segs[i].BackgroundColor3=T.Green
                TwPlay(Segs[i],{BackgroundTransparency=0},0.07)
                task.wait(0.025)
            end
        end
        if LStat and LStat.Parent then
            LStat.Text="v  All systems ready"
            TwPlay(LStat,  {TextColor3=T.Green},0.28)
            TwPlay(ILbl,   {TextColor3=T.Green},0.28)
            TwPlay(CStk,   {Color=T.Green},0.28)
        end
        LPct.Text="100%"; task.wait(0.88)

        TwPlay(Card,  {Position=UDim2.new(0.5,0,0.26,0),BackgroundTransparency=1},
               0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        TwPlay(Cover, {BackgroundTransparency=1}, 0.36)
        task.wait(0.4)
        pcall(function() LGui:Destroy() end)
        if type(done)=="function" then done() end
    end)
end

-- ══ MAIN WINDOW ══════════════════════════════════════════════════════
local MainGui = SafeGui("Mm2Ui_Main", 10)

local function CreateWindow(_, cfg)
    cfg = type(cfg)=="table" and cfg or {}
    local title    = cfg.Title    or "OmniHub"
    local subtitle = cfg.SubTitle or ""

    local WW = IsMobile and 335 or 570
    local WH = IsMobile and 480 or 385
    local SW = IsMobile and 80  or 155
    local TH = IsMobile and 42  or 38   -- titlebar height

    local Win = N("Frame",{
        Size=UDim2.new(0,WW,0,WH), Position=UDim2.new(0.5,-WW/2,0.5,-WH/2),
        BackgroundColor3=T.BG1, BorderSizePixel=0, ZIndex=10,
        Visible=false, Parent=MainGui,
    })
    Cor(T.RLg, Win); Stk(T.Accent, 1.5, 0.6, Win)

    -- Title bar
    local TB = N("Frame",{
        Size=UDim2.new(1,0,0,TH), BackgroundColor3=T.BG2,
        BorderSizePixel=0, ZIndex=11, Parent=Win,
    })
    Cor(T.RLg, TB)
    N("Frame",{
        Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14),
        BackgroundColor3=T.BG2, BorderSizePixel=0, ZIndex=11, Parent=TB,
    })
    MakeDraggable(TB, Win)

    local TStrip = N("Frame",{
        Size=UDim2.new(0,0,0,2), BackgroundColor3=T.Accent,
        BorderSizePixel=0, ZIndex=12, Parent=TB,
    })
    Cor(T.RSm, TStrip)
    Grad({T.Accent,T.AccentB,T.AccentC}, 0, TStrip)

    local HIcon = N("TextLabel",{
        Size=UDim2.new(0,24,0,24), Position=UDim2.new(0,8,0.5,0),
        AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=T.BG3,
        BorderSizePixel=0, Text="!", TextColor3=T.Accent,
        TextSize=11, Font=Enum.Font.GothamBold, ZIndex=12, Parent=TB,
    })
    Cor(UDim.new(0,5), HIcon)

    N("TextLabel",{
        Size=UDim2.new(0,IsMobile and 110 or 140,1,0), Position=UDim2.new(0,38,0,0),
        BackgroundTransparency=1, Text=title:upper(), TextColor3=T.TextHi,
        TextSize=IsMobile and 11 or 12, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12, Parent=TB,
    })
    if subtitle~="" and not IsMobile then
        N("TextLabel",{
            Size=UDim2.new(0,140,1,0), Position=UDim2.new(0,186,0,0),
            BackgroundTransparency=1, Text=subtitle,
            TextColor3=T.TextLow, TextSize=9, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12, Parent=TB,
        })
    end

    local bSz  = IsMobile and 28 or 24
    local function WinBtn(xOff, col, lbl)
        local b = N("TextButton",{
            Size=UDim2.new(0,bSz,0,bSz), Position=UDim2.new(1,xOff,0.5,0),
            AnchorPoint=Vector2.new(1,0.5), BackgroundColor3=col,
            BackgroundTransparency=0.35, BorderSizePixel=0,
            Text=lbl, TextColor3=T.TextHi, TextSize=10,
            Font=Enum.Font.GothamBold, ZIndex=12, Parent=TB,
        })
        Cor(UDim.new(0,6), b)
        b.MouseEnter:Connect(function() TwPlay(b,{BackgroundTransparency=0},0.12) end)
        b.MouseLeave:Connect(function() TwPlay(b,{BackgroundTransparency=0.35},0.12) end)
        return b
    end
    local CloseB = WinBtn(-6,             T.Red,    "x")
    local MinB   = WinBtn(-6-bSz-4,       T.Yellow, "-")

    local minimized = false
    MinB.MouseButton1Click:Connect(function()
        minimized = not minimized
        TwPlay(Win,{Size=UDim2.new(0,WW,0,minimized and TH or WH)},0.25)
    end)

    local function hideWindow()
        TwPlay(Win,{Size=UDim2.new(0,WW,0,0)},0.22,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
        task.delay(0.25,function()
            Win.Visible=false; Win.Size=UDim2.new(0,WW,0,WH)
        end)
    end
    local function showWindow()
        Win.Visible=true; Win.Size=UDim2.new(0,WW,0,0)
        TwPlay(Win,{Size=UDim2.new(0,WW,0,WH)},0.38,Enum.EasingStyle.Back)
        TwPlay(TStrip,{Size=UDim2.new(1,0,0,2)},0.5)
    end
    CloseB.MouseButton1Click:Connect(hideWindow)

    -- Sidebar
    local Side = N("Frame",{
        Size=UDim2.new(0,SW,1,-TH), Position=UDim2.new(0,0,0,TH),
        BackgroundColor3=T.BG2, BorderSizePixel=0, ZIndex=11, Parent=Win,
    })
    N("Frame",{
        Size=UDim2.new(0,12,1,0), Position=UDim2.new(1,-12,0,0),
        BackgroundColor3=T.BG2, BorderSizePixel=0, ZIndex=10, Parent=Side,
    })
    local SideScroll = N("ScrollingFrame",{
        Size=UDim2.new(1,0,1,-6), Position=UDim2.new(0,0,0,4),
        BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=0,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ZIndex=12, Parent=Side,
    })
    ListLayout(3, nil, SideScroll)
    N("UIPadding",{PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),Parent=SideScroll})

    -- Content
    local Content = N("Frame",{
        Size=UDim2.new(1,-SW,1,-TH), Position=UDim2.new(0,SW,0,TH),
        BackgroundColor3=T.BG1, BorderSizePixel=0, ZIndex=11,
        ClipsDescendants=true, Parent=Win,
    })
    N("Frame",{
        Size=UDim2.new(0,12,1,0), BackgroundColor3=T.BG1,
        BorderSizePixel=0, ZIndex=10, Parent=Content,
    })

    local Pages={}, TabBtns={}, ActiveTab=nil

    local function MakePage()
        local sf = N("ScrollingFrame",{
            Size=UDim2.new(1,-10,1,-8), Position=UDim2.new(0,5,0,4),
            BackgroundTransparency=1, BorderSizePixel=0,
            ScrollBarThickness=3, ScrollBarImageColor3=T.Accent,
            ScrollBarImageTransparency=0.45,
            CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
            ZIndex=12, Visible=false, Parent=Content,
        })
        ListLayout(4, nil, sf)
        N("UIPadding",{
            PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,6),
            PaddingTop=UDim.new(0,3), Parent=sf,
        })
        return sf
    end

    local function _Section(page, t)
        local f=N("Frame",{
            Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
            LayoutOrder=#page:GetChildren()+1, ZIndex=13, Parent=page,
        })
        N("TextLabel",{
            Size=UDim2.new(1,-4,1,0), BackgroundTransparency=1,
            Text=t and t:upper() or "", TextColor3=T.Accent, TextSize=9,
            Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=13, Parent=f,
        })
        N("Frame",{
            Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
            BackgroundColor3=T.Sep, BorderSizePixel=0, ZIndex=13, Parent=f,
        })
    end

    local function _Toggle(page, cfg2)
        local on   = cfg2.Default or false
        local rH   = IsMobile and 58 or 50
        local trkW = IsMobile and 42 or 36
        local trkH = IsMobile and 22 or 18
        local kSz  = IsMobile and 16 or 12
        local c = N("Frame",{
            Size=UDim2.new(1,0,0,rH), BackgroundColor3=T.BG3,
            BorderSizePixel=0, LayoutOrder=#page:GetChildren()+1, ZIndex=13, Parent=page,
        })
        Cor(T.R, c)
        N("TextLabel",{
            Size=UDim2.new(1,-(trkW+16),0,16),
            Position=UDim2.new(0,10,0,cfg2.Desc and 9 or (rH/2-8)),
            BackgroundTransparency=1, Text=cfg2.Title or "Toggle",
            TextColor3=T.TextHi, TextSize=IsMobile and 12 or 11,
            Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=14, Parent=c,
        })
        if cfg2.Desc then
            N("TextLabel",{
                Size=UDim2.new(1,-(trkW+16),0,13), Position=UDim2.new(0,10,0,28),
                BackgroundTransparency=1, Text=cfg2.Desc, TextColor3=T.TextLow,
                TextSize=IsMobile and 10 or 9, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14, Parent=c,
            })
        end
        local tr = N("Frame",{
            Size=UDim2.new(0,trkW,0,trkH), Position=UDim2.new(1,-(trkW+10),0.5,0),
            AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=T.BG4,
            BorderSizePixel=0, ZIndex=14, Parent=c,
        })
        Cor(UDim.new(1,0), tr)
        local kn = N("Frame",{
            Size=UDim2.new(0,kSz,0,kSz), Position=UDim2.new(0,3,0.5,0),
            AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=T.TextMid,
            BorderSizePixel=0, ZIndex=15, Parent=tr,
        })
        Cor(UDim.new(1,0), kn)
        local function setState(v, silent)
            on=v
            if on then
                TwPlay(tr,{BackgroundColor3=T.Accent},0.18)
                TwPlay(kn,{Position=UDim2.new(1,-(kSz+3),0.5,0),BackgroundColor3=Color3.fromRGB(255,255,255)},0.18)
            else
                TwPlay(tr,{BackgroundColor3=T.BG4},0.18)
                TwPlay(kn,{Position=UDim2.new(0,3,0.5,0),BackgroundColor3=T.TextMid},0.18)
            end
            if not silent and cfg2.Callback then pcall(cfg2.Callback, on) end
        end
        setState(on, true)
        local btn=N("TextButton",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text="", ZIndex=16, Parent=c,
        })
        btn.MouseButton1Click:Connect(function() setState(not on) end)
        c.MouseEnter:Connect(function() TwPlay(c,{BackgroundColor3=T.BG4},0.12) end)
        c.MouseLeave:Connect(function() TwPlay(c,{BackgroundColor3=T.BG3},0.12) end)
        return { Set=setState, Get=function() return on end }
    end

    local function _Button(page, cfg2)
        local rH = IsMobile and 58 or 50
        local c = N("Frame",{
            Size=UDim2.new(1,0,0,rH), BackgroundColor3=T.BG3,
            BorderSizePixel=0, LayoutOrder=#page:GetChildren()+1, ZIndex=13, Parent=page,
        })
        Cor(T.R, c)
        N("TextLabel",{
            Size=UDim2.new(1,-44,0,16), Position=UDim2.new(0,10,0,cfg2.Desc and 9 or (rH/2-8)),
            BackgroundTransparency=1, Text=cfg2.Title or "Button",
            TextColor3=T.TextHi, TextSize=IsMobile and 12 or 11,
            Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=14, Parent=c,
        })
        if cfg2.Desc then
            N("TextLabel",{
                Size=UDim2.new(1,-44,0,13), Position=UDim2.new(0,10,0,28),
                BackgroundTransparency=1, Text=cfg2.Desc, TextColor3=T.TextLow,
                TextSize=IsMobile and 10 or 9, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14, Parent=c,
            })
        end
        local arr=N("TextLabel",{
            Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-34,0.5,0),
            AnchorPoint=Vector2.new(1,0.5), BackgroundColor3=T.BG4,
            Text=">", TextColor3=T.Accent, TextSize=17,
            Font=Enum.Font.GothamBold, ZIndex=14, Parent=c,
        })
        Cor(UDim.new(0,5), arr)
        local btn=N("TextButton",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=16, Parent=c,
        })
        c.MouseEnter:Connect(function()
            TwPlay(c,{BackgroundColor3=T.BG4},0.12)
            TwPlay(arr,{BackgroundColor3=T.Accent},0.12)
        end)
        c.MouseLeave:Connect(function()
            TwPlay(c,{BackgroundColor3=T.BG3},0.12)
            TwPlay(arr,{BackgroundColor3=T.BG4},0.12)
        end)
        btn.MouseButton1Click:Connect(function()
            TwPlay(c,{BackgroundColor3=Color3.fromRGB(50,18,20)},0.06)
            task.delay(0.12,function() TwPlay(c,{BackgroundColor3=T.BG4},0.12) end)
            if cfg2.Callback then pcall(cfg2.Callback) end
        end)
    end

    local function _Label(page, text)
        N("TextLabel",{
            Size=UDim2.new(1,0,0,IsMobile and 22 or 20), BackgroundTransparency=1,
            Text=text or "", TextColor3=T.TextMid, TextSize=IsMobile and 10 or 9,
            Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
            TextWrapped=true, LayoutOrder=#page:GetChildren()+1, ZIndex=13, Parent=page,
        })
    end

    local function AddTab(_, tabTitle, icon)
        local page  = MakePage()
        local order = #TabBtns + 1
        local BH    = IsMobile and 54 or 40

        local tb = N("TextButton",{
            Size=UDim2.new(1,0,0,BH), BackgroundColor3=T.BG2,
            BorderSizePixel=0, Text="", LayoutOrder=order, ZIndex=13, Parent=SideScroll,
        })
        Cor(T.R, tb)

        local ind = N("Frame",{
            Size=UDim2.new(0,3,0.45,0), Position=UDim2.new(0,0,0.275,0),
            BackgroundColor3=T.Accent, BorderSizePixel=0,
            ZIndex=15, Visible=false, Parent=tb,
        })
        Cor(UDim.new(0,2), ind)

        local ic = N("TextLabel",{
            Size=UDim2.new(1,0,0,IsMobile and 22 or 18),
            Position=UDim2.new(0,0,0,IsMobile and 6 or 5),
            BackgroundTransparency=1, Text=icon or ".",
            TextColor3=T.TextLow, TextSize=IsMobile and 15 or 13,
            Font=Enum.Font.GothamBold, ZIndex=14, Parent=tb,
        })

        local tx = N("TextLabel",{
            Size=UDim2.new(1,-2,0,11), Position=UDim2.new(0,1,0,BH-15),
            BackgroundTransparency=1, Text=tabTitle:sub(1, IsMobile and 6 or 14),
            TextColor3=T.TextLow, TextSize=IsMobile and 8 or 9,
            Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Center,
            ZIndex=14, Parent=tb,
        })

        local function Activate()
            if ActiveTab and TabBtns[ActiveTab] then
                local old=TabBtns[ActiveTab]
                TwPlay(old.frame,{BackgroundColor3=T.BG2},0.16)
                old.ind.Visible=false
                TwPlay(old.ic,{TextColor3=T.TextLow},0.16)
                TwPlay(old.tx,{TextColor3=T.TextLow},0.16)
                Pages[ActiveTab].Visible=false
            end
            ActiveTab=tabTitle
            TwPlay(tb,{BackgroundColor3=T.BG3},0.16)
            ind.Visible=true
            TwPlay(ic,{TextColor3=T.Accent},0.16)
            TwPlay(tx,{TextColor3=T.TextMid},0.16)
            page.Visible=true
        end

        tb.MouseButton1Click:Connect(Activate)
        tb.MouseEnter:Connect(function()
            if ActiveTab~=tabTitle then
                TwPlay(tb,{BackgroundColor3=Color3.fromRGB(28,26,32)},0.12)
            end
        end)
        tb.MouseLeave:Connect(function()
            if ActiveTab~=tabTitle then TwPlay(tb,{BackgroundColor3=T.BG2},0.12) end
        end)
        TabBtns[tabTitle]={frame=tb,ind=ind,ic=ic,tx=tx}
        Pages[tabTitle]=page
        if order==1 then task.defer(Activate) end

        return {
            AddSection = function(_,t)     _Section(page,t)        end,
            AddToggle  = function(_,cfg2)  return _Toggle(page,cfg2)  end,
            AddButton  = function(_,cfg2)  _Button(page,cfg2)      end,
            AddLabel   = function(_,t)     _Label(page,t)          end,
        }
    end

    -- PC keyboard shortcut
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode==Enum.KeyCode.RightShift
        or inp.KeyCode==Enum.KeyCode.LeftControl then
            if Win.Visible then hideWindow() else showWindow() end
        end
    end)

    -- Mobile/PC FAB toggle button
    local FAB = N("TextButton",{
        Size=UDim2.new(0,44,0,44), Position=UDim2.new(0,12,1,-60),
        AnchorPoint=Vector2.new(0,1), BackgroundColor3=T.Accent,
        BorderSizePixel=0, Text="!", TextColor3=Color3.fromRGB(255,255,255),
        TextSize=18, Font=Enum.Font.GothamBold, ZIndex=20, Parent=MainGui,
    })
    Cor(UDim.new(0,10), FAB)
    Stk(T.AccentB, 1.5, 0.3, FAB)

    local fabStart, fabUDim, fabMoved = nil, nil, false
    FAB.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.Touch
        and inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        fabStart=inp.Position; fabUDim=FAB.Position; fabMoved=false
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not fabStart then return end
        if inp.UserInputType~=Enum.UserInputType.Touch
        and inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local d=inp.Position-fabStart
        if d.Magnitude>7 then
            fabMoved=true
            FAB.Position=UDim2.new(fabUDim.X.Scale,fabUDim.X.Offset+d.X,
                                   fabUDim.Y.Scale,fabUDim.Y.Offset+d.Y)
        end
    end)
    FAB.InputEnded:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.Touch
        and inp.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        local wasMoved=fabMoved; fabStart=nil; fabMoved=false
        if not wasMoved then
            if Win.Visible then hideWindow() else showWindow() end
        end
    end)

    -- Pulse FAB when window is hidden
    task.spawn(function()
        while true do
            task.wait(3.5)
            if not Win.Visible then
                TwPlay(FAB,{BackgroundTransparency=0.38},0.3)
                task.wait(0.38)
                TwPlay(FAB,{BackgroundTransparency=0},0.3)
            end
        end
    end)

    return {
        AddTab = AddTab,
        Show   = function() showWindow() end,
        Hide   = function() hideWindow() end,
    }
end

-- ══ PUBLIC API ═══════════════════════════════════════════════════════
return {
    Notify       = Notify,
    CreateWindow = CreateWindow,
    RunLoader    = RunLoader,
}

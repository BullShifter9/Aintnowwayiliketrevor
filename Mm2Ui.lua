--[[
╔══════════════════════════════════════════════════════════════╗
║                M M 2 U I  ·  GUI Library                     ║
║         Modern Roblox UI · Mobile + PC Compatible            ║
║                      By Azzakirms                            ║
╠══════════════════════════════════════════════════════════════╣
║  API (drop-in OmniLib replacement):                          ║
║                                                              ║
║  local Lib = loadstring(game:HttpGet("RAW_GITHUB_URL"))()    ║
║                                                              ║
║  -- Notifications (call directly, no colon):                 ║
║  local Notify = Lib.Notify                                   ║
║  Notify("Title","Body","success",4)                          ║
║  -- types: "info" | "success" | "warn" | "error"            ║
║                                                              ║
║  -- Window (use colon):                                      ║
║  local Win = Lib:CreateWindow({ Title="Hub", SubTitle="v1" })║
║  local Tab = Win:AddTab("Visuals", "👁")                    ║
║  Tab:AddSection("ESP")                                       ║
║  Tab:AddToggle({ Title="ESP", Desc="...", Default=true,      ║
║                  Callback=function(v) end })                 ║
║  Tab:AddButton({ Title="Go", Desc="...",                     ║
║                  Callback=function() end })                  ║
║  Tab:AddLabel("Info text here")                              ║
║                                                              ║
║  -- Loader (call directly, no colon):                        ║
║  Lib.RunLoader("TITLE","Subtitle", steps, function()         ║
║      Win.Show()  -- show window when done                    ║
║  end)                                                        ║
╚══════════════════════════════════════════════════════════════╝
--]]

-- ┌───────────────────────────────────┐
-- │  SERVICES                         │
-- └───────────────────────────────────┘
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ┌───────────────────────────────────┐
-- │  THEME                            │
-- └───────────────────────────────────┘
local T = {
    BG0     = Color3.fromRGB(8,    9,   16),
    BG1     = Color3.fromRGB(13,  15,   26),
    BG2     = Color3.fromRGB(18,  21,   38),
    BG3     = Color3.fromRGB(24,  28,   50),
    BG4     = Color3.fromRGB(32,  37,   66),
    Accent  = Color3.fromRGB(82,  148,  255),
    AccentB = Color3.fromRGB(0,   210,  170),
    AccentC = Color3.fromRGB(140,  80,  255),
    TextHi  = Color3.fromRGB(235, 240,  255),
    TextMid = Color3.fromRGB(150, 165,  210),
    TextLow = Color3.fromRGB(80,   95,  145),
    Green   = Color3.fromRGB(50,  220,  130),
    Red     = Color3.fromRGB(255,  70,   80),
    Yellow  = Color3.fromRGB(255, 200,   50),
    Sep     = Color3.fromRGB(28,   33,   60),
    R       = UDim.new(0, 8),
    RLg     = UDim.new(0, 14),
    RSm     = UDim.new(0, 5),
}

-- ┌───────────────────────────────────┐
-- │  INTERNAL HELPERS                 │
-- └───────────────────────────────────┘
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function Tw(inst, props, t, sty, dir)
    sty = sty or Enum.EasingStyle.Quart
    dir = dir  or Enum.EasingDirection.Out
    return TweenService:Create(inst, TweenInfo.new(t or 0.25, sty, dir), props)
end

local function TwPlay(inst, props, t, sty, dir)
    Tw(inst, props, t, sty, dir):Play()
end

-- Instance factory
local function N(class, props)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do
        pcall(function() i[k] = v end)
    end
    return i
end

local function Cor(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or T.R
    c.Parent = p
    return c
end

local function Stk(col, th, tr, p)
    local s = N("UIStroke", { Color=col, Thickness=th or 1, Transparency=tr or 0 })
    s.Parent = p
    return s
end

local function Grad(cols, rot, p)
    local kp = {}
    for i, v in ipairs(cols) do
        kp[i] = ColorSequenceKeypoint.new((i-1)/(math.max(#cols-1,1)), v)
    end
    local g = N("UIGradient", { Color=ColorSequence.new(kp), Rotation=rot or 0 })
    g.Parent = p
    return g
end

local function List(sp, dir, p)
    local l = N("UIListLayout", {
        SortOrder     = Enum.SortOrder.LayoutOrder,
        FillDirection = dir or Enum.FillDirection.Vertical,
        Padding       = UDim.new(0, sp or 6),
    })
    l.Parent = p
    return l
end

-- Drag helper (works on mouse + touch)
local function MakeDraggable(handle, target)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            ds   = inp.Position
            sp   = target.Position
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

-- Safe ScreenGui parent (CoreGui preferred, falls back to PlayerGui)
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

-- ╔════════════════════════════════════════════════════════════╗
-- ║                   N O T I F I C A T I O N S               ║
-- ╚════════════════════════════════════════════════════════════╝
local NotifGui = SafeGui("Mm2Ui_Notify", 500)

local NHolder = N("Frame", {
    Size                  = UDim2.new(0, 300, 1, 0),
    Position              = UDim2.new(1, -308, 0, 0),
    BackgroundTransparency= 1,
    ZIndex                = 501,
    Parent                = NotifGui,
})
List(8, nil, NHolder)
local _nhPad = N("UIPadding", { PaddingTop = UDim.new(0, 12) })
_nhPad.Parent = NHolder

local function Notify(title, body, ntype, dur)
    dur   = dur   or 4
    ntype = ntype or "info"

    local ac = ntype == "success" and T.Green
            or ntype == "warn"    and T.Yellow
            or ntype == "error"   and T.Red
            or T.Accent

    -- Card
    local nf = N("Frame", {
        Size                  = UDim2.new(1, 0, 0, 66),
        BackgroundColor3      = T.BG2,
        BackgroundTransparency= 1,          -- starts transparent
        BorderSizePixel       = 0,
        ZIndex                = 502,
        Parent                = NHolder,
    })
    Cor(T.R, nf)
    Stk(ac, 1, 0.45, nf)

    -- Left accent bar
    N("Frame", {
        Size             = UDim2.new(0, 3, 1, -12),
        Position         = UDim2.new(0, 0, 0, 6),
        BackgroundColor3 = ac,
        BorderSizePixel  = 0,
        ZIndex           = 503,
        Parent           = nf,
    })

    -- Type icon
    local icon = ntype=="success" and "✓"
              or ntype=="warn"    and "⚠"
              or ntype=="error"   and "✕"
              or "ℹ"
    N("TextLabel", {
        Size                  = UDim2.new(0, 22, 0, 22),
        Position              = UDim2.new(0, 12, 0, 8),
        BackgroundColor3      = ac,
        BackgroundTransparency= 0.8,
        BorderSizePixel       = 0,
        Text                  = icon,
        TextColor3            = ac,
        TextSize              = 13,
        Font                  = Enum.Font.GothamBold,
        ZIndex                = 503,
        Parent                = nf,
    })

    -- Title
    N("TextLabel", {
        Size                  = UDim2.new(1, -46, 0, 18),
        Position              = UDim2.new(0, 42, 0, 7),
        BackgroundTransparency= 1,
        Text                  = title or "",
        TextColor3            = T.TextHi,
        TextSize              = 13,
        Font                  = Enum.Font.GothamBold,
        TextXAlignment        = Enum.TextXAlignment.Left,
        ZIndex                = 503,
        Parent                = nf,
    })

    -- Body
    N("TextLabel", {
        Size                  = UDim2.new(1, -46, 0, 30),
        Position              = UDim2.new(0, 42, 0, 28),
        BackgroundTransparency= 1,
        Text                  = body or "",
        TextColor3            = T.TextMid,
        TextSize              = 11,
        Font                  = Enum.Font.Gotham,
        TextXAlignment        = Enum.TextXAlignment.Left,
        TextWrapped           = true,
        ZIndex                = 503,
        Parent                = nf,
    })

    -- Slide in from right + fade
    nf.Position = UDim2.new(1.05, 0, 0, 0)
    TwPlay(nf, { BackgroundTransparency=0, Position=UDim2.new(0, 0, 0, 0) },
           0.35, Enum.EasingStyle.Back)

    -- Auto-dismiss
    task.delay(dur, function()
        if not nf or not nf.Parent then return end
        TwPlay(nf, { BackgroundTransparency=1, Position=UDim2.new(1.05, 0, 0, 0) }, 0.28)
        task.wait(0.32)
        if nf and nf.Parent then nf:Destroy() end
    end)
end

-- ╔════════════════════════════════════════════════════════════╗
-- ║                L O A D E R                                ║
-- ╚════════════════════════════════════════════════════════════╝
local function RunLoader(title, subtitle, steps, done)
    -- Create loader GUI fresh each call so it can be GC'd after
    local LGui = SafeGui("Mm2Ui_Loader", 999)

    -- Transparent full-screen cover
    local Cover = N("Frame", {
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency= 1,
        BorderSizePixel       = 0,
        Parent                = LGui,
    })

    -- Dim vignette behind card
    local CW = IsMobile and 310 or 390
    local CH = IsMobile and 250 or 280

    local Vignette = N("Frame", {
        Size                  = UDim2.new(0, CW + 80, 0, CH + 70),
        Position              = UDim2.new(0.5, 0, 1.4, 0),
        AnchorPoint           = Vector2.new(0.5, 0.5),
        BackgroundColor3      = T.BG0,
        BackgroundTransparency= 0.45,
        BorderSizePixel       = 0,
        ZIndex                = 2,
        Parent                = Cover,
    })
    Cor(UDim.new(0, 28), Vignette)

    -- Glowing card
    local Card = N("Frame", {
        Size                  = UDim2.new(0, CW, 0, CH),
        Position              = UDim2.new(0.5, 0, 1.4, 0),
        AnchorPoint           = Vector2.new(0.5, 0.5),
        BackgroundColor3      = Color3.fromRGB(6, 8, 18),
        BackgroundTransparency= 0.06,
        BorderSizePixel       = 0,
        ZIndex                = 3,
        Parent                = Cover,
    })
    Cor(UDim.new(0, 18), Card)
    local CardStk = Stk(T.Accent, 2, 0, Card)

    -- Top accent stripe (grows in)
    local TopStripe = N("Frame", {
        Size             = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 4,
        Parent           = Card,
    })
    Cor(UDim.new(0, 2), TopStripe)
    Grad({ T.AccentC, T.Accent, T.AccentB }, 0, TopStripe)

    -- Glass sheen
    N("Frame", {
        Size                  = UDim2.new(1, 0, 0.42, 0),
        BackgroundColor3      = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency= 0.95,
        BorderSizePixel       = 0,
        ZIndex                = 4,
        Parent                = Card,
    })

    -- Icon box
    local IB = N("Frame", {
        Size             = UDim2.new(0, 54, 0, 54),
        Position         = UDim2.new(0.5, 0, 0, 18),
        AnchorPoint      = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(8, 12, 28),
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = Card,
    })
    Cor(UDim.new(0, 13), IB)
    local IBStk = Stk(T.Accent, 1.5, 0.2, IB)

    local ILbl = N("TextLabel", {
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency= 1,
        Text                  = "◈",
        TextColor3            = T.Accent,
        TextSize              = 28,
        Font                  = Enum.Font.GothamBold,
        ZIndex                = 6,
        Parent                = IB,
    })

    -- Title / subtitle
    local LTitle = N("TextLabel", {
        Size                  = UDim2.new(1, -24, 0, 34),
        Position              = UDim2.new(0, 12, 0, 84),
        BackgroundTransparency= 1,
        Text                  = title or "LOADING",
        TextColor3            = T.TextHi,
        TextSize              = IsMobile and 22 or 27,
        Font                  = Enum.Font.GothamBold,
        TextXAlignment        = Enum.TextXAlignment.Center,
        ZIndex                = 5,
        Parent                = Card,
    })

    local LSub = N("TextLabel", {
        Size                  = UDim2.new(1, -24, 0, 14),
        Position              = UDim2.new(0, 12, 0, 120),
        BackgroundTransparency= 1,
        Text                  = subtitle or "",
        TextColor3            = T.TextLow,
        TextSize              = 10,
        Font                  = Enum.Font.Gotham,
        TextXAlignment        = Enum.TextXAlignment.Center,
        ZIndex                = 5,
        Parent                = Card,
    })

    -- Divider
    N("Frame", {
        Size             = UDim2.new(0.55, 0, 0, 1),
        Position         = UDim2.new(0.225, 0, 0, 142),
        BackgroundColor3 = T.Sep,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = Card,
    })

    -- Status + percentage
    local LStat = N("TextLabel", {
        Size                  = UDim2.new(1, -58, 0, 14),
        Position              = UDim2.new(0, 14, 0, 150),
        BackgroundTransparency= 1,
        Text                  = "Initializing",
        TextColor3            = T.TextMid,
        TextSize              = 10,
        Font                  = Enum.Font.Gotham,
        TextXAlignment        = Enum.TextXAlignment.Left,
        ZIndex                = 5,
        Parent                = Card,
    })

    local LPct = N("TextLabel", {
        Size                  = UDim2.new(0, 44, 0, 14),
        Position              = UDim2.new(1, -56, 0, 150),
        BackgroundTransparency= 1,
        Text                  = "0%",
        TextColor3            = T.Accent,
        TextSize              = 10,
        Font                  = Enum.Font.GothamBold,
        TextXAlignment        = Enum.TextXAlignment.Right,
        ZIndex                = 5,
        Parent                = Card,
    })

    -- ── Segmented progress bar ─────────────────────────────────────────
    local SEG_COUNT = 10
    local SEG_GAP   = 4
    local BAR_H     = 8
    local BAR_Y     = 172
    local BAR_W     = CW - 28

    local SegBar = N("Frame", {
        Size                  = UDim2.new(0, BAR_W, 0, BAR_H),
        Position              = UDim2.new(0, 14, 0, BAR_Y),
        BackgroundTransparency= 1,
        BorderSizePixel       = 0,
        ZIndex                = 5,
        Parent                = Card,
    })

    local segW = math.floor((BAR_W - (SEG_COUNT - 1) * SEG_GAP) / SEG_COUNT)
    local Segs = {}
    for i = 1, SEG_COUNT do
        local x = (i - 1) * (segW + SEG_GAP)
        local s = N("Frame", {
            Size             = UDim2.new(0, segW, 1, 0),
            Position         = UDim2.new(0, x, 0, 0),
            BackgroundColor3 = Color3.fromRGB(22, 28, 55),
            BorderSizePixel  = 0,
            ZIndex           = 6,
            Parent           = SegBar,
        })
        Cor(UDim.new(0, 3), s)
        Segs[i] = s
    end

    -- Footer
    N("TextLabel", {
        Size                  = UDim2.new(1, -24, 0, 12),
        Position              = UDim2.new(0, 12, 0, 192),
        BackgroundTransparency= 1,
        Text                  = "secure  ·  fast  ·  undetected",
        TextColor3            = T.TextLow,
        TextSize              = 9,
        Font                  = Enum.Font.Gotham,
        TextXAlignment        = Enum.TextXAlignment.Center,
        ZIndex                = 5,
        Parent                = Card,
    })

    -- Scan line effect
    local ScanLine = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.Accent,
        BackgroundTransparency = 0.65,
        BorderSizePixel  = 0,
        ZIndex           = 7,
        Parent           = Card,
    })

    -- ── Loader logic runs in a coroutine so it doesn't block ──────────
    task.spawn(function()
        -- Slide card in
        TwPlay(Vignette, { Position = UDim2.new(0.5, 0, 0.5, 0) },
               0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TwPlay(Card,     { Position = UDim2.new(0.5, 0, 0.5, 0) },
               0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        task.wait(0.42)
        TwPlay(TopStripe, { Size = UDim2.new(1, 0, 0, 2) }, 0.45)
        task.wait(0.5)

        -- Neon border cycle (fire-and-forget)
        local borderActive = true
        task.spawn(function()
            local colors = { T.Accent, T.AccentC, T.AccentB, T.Accent }
            local ci = 1
            while borderActive do
                ci = (ci % #colors) + 1
                TwPlay(CardStk, { Color = colors[ci] }, 1.2, Enum.EasingStyle.Sine)
                TwPlay(IBStk,   { Color = colors[ci] }, 1.2, Enum.EasingStyle.Sine)
                task.wait(1.35)
            end
        end)

        -- Scan-line loop (fire-and-forget)
        local scanActive = true
        task.spawn(function()
            while scanActive do
                ScanLine.Position = UDim2.new(0, 0, 0, 0)
                TwPlay(ScanLine, { Position = UDim2.new(0, 0, 1, -1) },
                       1.6, Enum.EasingStyle.Linear)
                task.wait(2.3)
            end
        end)

        -- Icon glitch blink (fire-and-forget)
        local glitchActive = true
        local glyphs = { "◈", "⬡", "◆", "◈" }
        task.spawn(function()
            local gi = 1
            while glitchActive do
                task.wait(1.2 + math.random() * 0.9)
                for _ = 1, 3 do
                    gi = (gi % #glyphs) + 1
                    ILbl.Text = glyphs[gi]
                    TwPlay(ILbl, { TextTransparency = 0.55 }, 0.04)
                    task.wait(0.06)
                    TwPlay(ILbl, { TextTransparency = 0 },    0.04)
                    task.wait(0.06)
                end
                ILbl.Text = "◈"
            end
        end)

        -- Status dots (fire-and-forget)
        local dotActive = true
        local dotBase   = "Initializing"
        local dotPat    = { "", "·", "··", "···" }
        local di        = 0
        task.spawn(function()
            while dotActive do
                di = (di % #dotPat) + 1
                if LStat and LStat.Parent then
                    LStat.Text = dotBase .. dotPat[di]
                end
                task.wait(0.32)
            end
        end)

        -- Segment fill helper
        local filledSegs = 0
        local function setSegments(targetPct)
            local target = math.max(0, math.min(SEG_COUNT,
                math.floor(targetPct * SEG_COUNT + 0.5)))
            LPct.Text = math.floor(targetPct * 100) .. "%"
            if target <= filledSegs then return end
            for i = filledSegs + 1, target do
                Segs[i].BackgroundColor3 = T.Accent
                Grad({ T.AccentC, T.Accent, T.AccentB }, 0, Segs[i])
                TwPlay(Segs[i], { BackgroundTransparency = 0.35 }, 0.07)
                task.wait(0.05)
                TwPlay(Segs[i], { BackgroundTransparency = 0 },    0.1)
                task.wait(0.04)
            end
            filledSegs = target
        end

        -- Step helper
        local function setStep(pct, label)
            dotActive = false
            task.wait(0.05)
            dotBase    = label
            di         = 0
            LStat.Text = label
            dotActive  = true
            setSegments(pct)
            task.wait(0.08)
        end

        -- Default steps if none provided
        steps = steps or {
            { 0.15, "Checking modules"       },
            { 0.35, "Loading assets"         },
            { 0.60, "Applying configuration" },
            { 0.85, "Connecting remotes"     },
            { 1.00, "Ready"                  },
        }

        -- Run each step
        for _, s in ipairs(steps) do
            setStep(s[1], s[2])
            task.wait(0.22 + math.random() * 0.18)
        end

        -- Stop all loops
        borderActive  = false
        scanActive    = false
        glitchActive  = false
        dotActive     = false
        task.wait(0.05)

        -- Flash segments green
        for i = 1, SEG_COUNT do
            if Segs[i] and Segs[i].Parent then
                Segs[i].BackgroundColor3 = T.Green
                TwPlay(Segs[i], { BackgroundTransparency = 0.25 }, 0.06)
                task.wait(0.03)
                TwPlay(Segs[i], { BackgroundTransparency = 0 },    0.08)
            end
        end

        if LStat and LStat.Parent then
            LStat.Text = "✓  All systems ready"
            TwPlay(LStat,   { TextColor3 = T.Green }, 0.3)
            TwPlay(ILbl,    { TextColor3 = T.Green }, 0.3)
            TwPlay(CardStk, { Color      = T.Green }, 0.3)
            TwPlay(IBStk,   { Color = T.Green, Transparency = 0 }, 0.3)
        end
        LPct.Text = "100%"
        task.wait(0.95)

        -- Outro: slide up + fade
        TwPlay(Card, {
            Position              = UDim2.new(0.5, 0, 0.28, 0),
            BackgroundTransparency= 1,
        }, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        TwPlay(Vignette, {
            Position              = UDim2.new(0.5, 0, 0.28, 0),
            BackgroundTransparency= 1,
        }, 0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.wait(0.44)

        -- Destroy loader
        pcall(function() LGui:Destroy() end)

        -- Fire done callback
        if type(done) == "function" then
            done()
        end
    end)
end

-- ╔════════════════════════════════════════════════════════════╗
-- ║                  M A I N  W I N D O W                     ║
-- ╚════════════════════════════════════════════════════════════╝
local MainGui = SafeGui("Mm2Ui_Main", 10)

local function CreateWindow(_, cfg)
    -- first arg is self (from colon call) — intentionally ignored via _
    cfg      = type(cfg) == "table" and cfg or {}
    local title    = cfg.Title    or "Mm2Ui"
    local subtitle = cfg.SubTitle or ""

    local WW = IsMobile and 340 or 580
    local WH = IsMobile and 490 or 390
    local SW = IsMobile and 58  or 160

    -- ── Root window frame ─────────────────────────────────────────────
    local Win = N("Frame", {
        Size             = UDim2.new(0, WW, 0, WH),
        Position         = UDim2.new(0.5, -WW/2, 0.5, -WH/2),
        BackgroundColor3 = T.BG1,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        Parent           = MainGui,
        Visible          = false,
    })
    Cor(T.RLg, Win)
    Stk(T.Accent, 1.5, 0.55, Win)

    -- ── Top bar ───────────────────────────────────────────────────────
    local TB = N("Frame", {
        Size             = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = T.BG2,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = Win,
    })
    Cor(T.RLg, TB)
    -- Square off bottom of title bar so it meets the sidebar cleanly
    N("Frame", {
        Size             = UDim2.new(1, 0, 0, 16),
        Position         = UDim2.new(0, 0, 1, -16),
        BackgroundColor3 = T.BG2,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = TB,
    })

    MakeDraggable(TB, Win)

    -- Animated accent stripe under title
    local TStrip = N("Frame", {
        Size             = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 12,
        Parent           = TB,
    })
    Cor(T.RSm, TStrip)
    Grad({ T.AccentC, T.Accent, T.AccentB }, 0, TStrip)

    -- Lightning bolt icon
    local LM = N("TextLabel", {
        Size             = UDim2.new(0, 26, 0, 26),
        Position         = UDim2.new(0, 8, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = T.BG3,
        BorderSizePixel  = 0,
        Text             = "⚡",
        TextColor3       = T.Accent,
        TextSize         = 12,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 12,
        Parent           = TB,
    })
    Cor(UDim.new(0, 5), LM)

    -- Title label
    N("TextLabel", {
        Size              = UDim2.new(0, IsMobile and 90 or 130, 1, 0),
        Position          = UDim2.new(0, 40, 0, 0),
        BackgroundTransparency = 1,
        Text              = title:upper(),
        TextColor3        = T.TextHi,
        TextSize          = IsMobile and 12 or 13,
        Font              = Enum.Font.GothamBold,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 12,
        Parent            = TB,
    })

    -- Subtitle (desktop only)
    if subtitle ~= "" and not IsMobile then
        N("TextLabel", {
            Size              = UDim2.new(0, 120, 1, 0),
            Position          = UDim2.new(0, 178, 0, 0),
            BackgroundTransparency = 1,
            Text              = subtitle,
            TextColor3        = T.TextLow,
            TextSize          = 10,
            Font              = Enum.Font.Gotham,
            TextXAlignment    = Enum.TextXAlignment.Left,
            ZIndex            = 12,
            Parent            = TB,
        })
    end

    -- Window buttons (Minimize / Close)
    local function WinBtn(xOff, col, lbl)
        local b = N("TextButton", {
            Size                  = UDim2.new(0, 26, 0, 26),
            Position              = UDim2.new(1, xOff, 0.5, 0),
            AnchorPoint           = Vector2.new(1, 0.5),
            BackgroundColor3      = col,
            BackgroundTransparency= 0.3,
            BorderSizePixel       = 0,
            Text                  = lbl,
            TextColor3            = T.TextHi,
            TextSize              = 12,
            Font                  = Enum.Font.GothamBold,
            ZIndex                = 12,
            Parent                = TB,
        })
        Cor(UDim.new(0, 6), b)
        b.MouseEnter:Connect(function() TwPlay(b, { BackgroundTransparency = 0 }, 0.14) end)
        b.MouseLeave:Connect(function() TwPlay(b, { BackgroundTransparency = 0.3 }, 0.14) end)
        return b
    end

    local CloseB = WinBtn(-8,  T.Red,    "✕")
    local MinB   = WinBtn(-38, T.Yellow, "─")

    local minimized = false
    MinB.MouseButton1Click:Connect(function()
        minimized = not minimized
        TwPlay(Win, { Size = UDim2.new(0, WW, 0, minimized and 38 or WH) },
               0.28, Enum.EasingStyle.Quart)
    end)

    CloseB.MouseButton1Click:Connect(function()
        TwPlay(Win, { BackgroundTransparency = 1, Size = UDim2.new(0, WW, 0, 0) },
               0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.28, function()
            Win.Visible = false
            Win.Size    = UDim2.new(0, WW, 0, WH)
            Win.BackgroundTransparency = 0
        end)
    end)

    -- ── Sidebar ───────────────────────────────────────────────────────
    local Side = N("Frame", {
        Size             = UDim2.new(0, SW, 1, -38),
        Position         = UDim2.new(0, 0, 0, 38),
        BackgroundColor3 = T.BG2,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = Win,
    })
    -- Square off the right edge where it meets content
    N("Frame", {
        Size             = UDim2.new(0, 14, 1, 0),
        Position         = UDim2.new(1, -14, 0, 0),
        BackgroundColor3 = T.BG2,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        Parent           = Side,
    })

    local SideScroll = N("ScrollingFrame", {
        Size              = UDim2.new(1, 0, 1, -8),
        Position          = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        BorderSizePixel   = 0,
        ScrollBarThickness = 0,
        ZIndex            = 12,
        Parent            = Side,
    })
    List(4, nil, SideScroll)
    local _ssPad = N("UIPadding", {
        PaddingLeft  = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
    })
    _ssPad.Parent = SideScroll

    -- ── Content area ──────────────────────────────────────────────────
    local Content = N("Frame", {
        Size             = UDim2.new(1, -SW, 1, -38),
        Position         = UDim2.new(0, SW, 0, 38),
        BackgroundColor3 = T.BG1,
        BorderSizePixel  = 0,
        ZIndex           = 11,
        ClipsDescendants = true,
        Parent           = Win,
    })
    -- Fill corner where sidebar meets content
    N("Frame", {
        Size             = UDim2.new(0, 14, 1, 0),
        BackgroundColor3 = T.BG1,
        BorderSizePixel  = 0,
        ZIndex           = 10,
        Parent           = Content,
    })

    -- Tab tracking
    local Pages     = {}
    local TabBtns   = {}
    local ActiveTab = nil

    -- Create a scrollable page in the content area
    local function MakePage()
        local sf = N("ScrollingFrame", {
            Size              = UDim2.new(1, -12, 1, -8),
            Position          = UDim2.new(0, 6, 0, 5),
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.Accent,
            ScrollBarImageTransparency = 0.4,
            CanvasSize        = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex            = 12,
            Parent            = Content,
            Visible           = false,
        })
        List(5, nil, sf)
        return sf
    end

    -- ── Element builders ──────────────────────────────────────────────

    local function _Section(page, t)
        local f = N("Frame", {
            Size                  = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency= 1,
            LayoutOrder           = #page:GetChildren() + 1,
            ZIndex                = 13,
            Parent                = page,
        })
        N("TextLabel", {
            Size                  = UDim2.new(1, -4, 1, 0),
            BackgroundTransparency= 1,
            Text                  = t and t:upper() or "",
            TextColor3            = T.Accent,
            TextSize              = 9,
            Font                  = Enum.Font.GothamBold,
            TextXAlignment        = Enum.TextXAlignment.Left,
            ZIndex                = 13,
            Parent                = f,
        })
        N("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            Position         = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = T.Sep,
            BorderSizePixel  = 0,
            ZIndex           = 13,
            Parent           = f,
        })
    end

    local function _Toggle(page, cfg)
        local on = cfg.Default or false
        local h  = cfg.Desc and 52 or 42

        local c = N("Frame", {
            Size             = UDim2.new(1, 0, 0, h),
            BackgroundColor3 = T.BG3,
            BorderSizePixel  = 0,
            LayoutOrder      = #page:GetChildren() + 1,
            ZIndex           = 13,
            Parent           = page,
        })
        Cor(T.R, c)

        N("TextLabel", {
            Size                  = UDim2.new(1, -56, 0, 18),
            Position              = UDim2.new(0, 10, 0, cfg.Desc and 8 or 12),
            BackgroundTransparency= 1,
            Text                  = cfg.Title or "Toggle",
            TextColor3            = T.TextHi,
            TextSize              = 12,
            Font                  = Enum.Font.GothamBold,
            TextXAlignment        = Enum.TextXAlignment.Left,
            ZIndex                = 14,
            Parent                = c,
        })

        if cfg.Desc then
            N("TextLabel", {
                Size                  = UDim2.new(1, -56, 0, 14),
                Position              = UDim2.new(0, 10, 0, 28),
                BackgroundTransparency= 1,
                Text                  = cfg.Desc,
                TextColor3            = T.TextLow,
                TextSize              = 10,
                Font                  = Enum.Font.Gotham,
                TextXAlignment        = Enum.TextXAlignment.Left,
                ZIndex                = 14,
                Parent                = c,
            })
        end

        -- Toggle track
        local tr = N("Frame", {
            Size             = UDim2.new(0, 36, 0, 20),
            Position         = UDim2.new(1, -46, 0.5, 0),
            AnchorPoint      = Vector2.new(1, 0.5),
            BackgroundColor3 = T.BG4,
            BorderSizePixel  = 0,
            ZIndex           = 14,
            Parent           = c,
        })
        Cor(UDim.new(1, 0), tr)

        -- Toggle knob
        local kn = N("Frame", {
            Size             = UDim2.new(0, 14, 0, 14),
            Position         = UDim2.new(0, 3, 0.5, 0),
            AnchorPoint      = Vector2.new(0, 0.5),
            BackgroundColor3 = T.TextMid,
            BorderSizePixel  = 0,
            ZIndex           = 15,
            Parent           = tr,
        })
        Cor(UDim.new(1, 0), kn)

        local function setState(v, silent)
            on = v
            if on then
                TwPlay(tr, { BackgroundColor3 = T.Accent },                             0.18)
                TwPlay(kn, { Position = UDim2.new(1, -17, 0.5, 0),
                             BackgroundColor3 = Color3.fromRGB(255, 255, 255) },        0.18)
            else
                TwPlay(tr, { BackgroundColor3 = T.BG4 },                               0.18)
                TwPlay(kn, { Position = UDim2.new(0, 3, 0.5, 0),
                             BackgroundColor3 = T.TextMid },                            0.18)
            end
            if not silent and cfg.Callback then
                pcall(cfg.Callback, on)
            end
        end

        setState(on, true)

        local btn = N("TextButton", {
            Size                  = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency= 1,
            Text                  = "",
            ZIndex                = 16,
            Parent                = c,
        })
        btn.MouseButton1Click:Connect(function() setState(not on) end)

        c.MouseEnter:Connect(function() TwPlay(c, { BackgroundColor3 = T.BG4 }, 0.12) end)
        c.MouseLeave:Connect(function() TwPlay(c, { BackgroundColor3 = T.BG3 }, 0.12) end)

        return {
            Set = setState,
            Get = function() return on end,
        }
    end

    local function _Button(page, cfg)
        local h = cfg.Desc and 52 or 42

        local c = N("Frame", {
            Size             = UDim2.new(1, 0, 0, h),
            BackgroundColor3 = T.BG3,
            BorderSizePixel  = 0,
            LayoutOrder      = #page:GetChildren() + 1,
            ZIndex           = 13,
            Parent           = page,
        })
        Cor(T.R, c)

        N("TextLabel", {
            Size                  = UDim2.new(1, -50, 0, 18),
            Position              = UDim2.new(0, 10, 0, cfg.Desc and 8 or 12),
            BackgroundTransparency= 1,
            Text                  = cfg.Title or "Button",
            TextColor3            = T.TextHi,
            TextSize              = 12,
            Font                  = Enum.Font.GothamBold,
            TextXAlignment        = Enum.TextXAlignment.Left,
            ZIndex                = 14,
            Parent                = c,
        })

        if cfg.Desc then
            N("TextLabel", {
                Size                  = UDim2.new(1, -50, 0, 14),
                Position              = UDim2.new(0, 10, 0, 28),
                BackgroundTransparency= 1,
                Text                  = cfg.Desc,
                TextColor3            = T.TextLow,
                TextSize              = 10,
                Font                  = Enum.Font.Gotham,
                TextXAlignment        = Enum.TextXAlignment.Left,
                ZIndex                = 14,
                Parent                = c,
            })
        end

        -- Arrow indicator
        local arr = N("TextLabel", {
            Size             = UDim2.new(0, 28, 0, 28),
            Position         = UDim2.new(1, -36, 0.5, 0),
            AnchorPoint      = Vector2.new(1, 0.5),
            BackgroundColor3 = T.BG4,
            Text             = "›",
            TextColor3       = T.Accent,
            TextSize         = 18,
            Font             = Enum.Font.GothamBold,
            ZIndex           = 14,
            Parent           = c,
        })
        Cor(UDim.new(0, 6), arr)

        local btn = N("TextButton", {
            Size                  = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency= 1,
            Text                  = "",
            ZIndex                = 16,
            Parent                = c,
        })

        c.MouseEnter:Connect(function()
            TwPlay(c,   { BackgroundColor3 = T.BG4 },    0.12)
            TwPlay(arr, { BackgroundColor3 = T.Accent },  0.12)
        end)
        c.MouseLeave:Connect(function()
            TwPlay(c,   { BackgroundColor3 = T.BG3 },    0.12)
            TwPlay(arr, { BackgroundColor3 = T.BG4 },    0.12)
        end)

        btn.MouseButton1Click:Connect(function()
            TwPlay(c, { BackgroundColor3 = Color3.fromRGB(26, 46, 88) }, 0.07)
            task.delay(0.13, function()
                TwPlay(c, { BackgroundColor3 = T.BG4 }, 0.12)
            end)
            if cfg.Callback then pcall(cfg.Callback) end
        end)
    end

    local function _Label(page, text)
        N("TextLabel", {
            Size                  = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency= 1,
            Text                  = text or "",
            TextColor3            = T.TextMid,
            TextSize              = 11,
            Font                  = Enum.Font.Gotham,
            TextXAlignment        = Enum.TextXAlignment.Left,
            TextWrapped           = true,
            LayoutOrder           = #page:GetChildren() + 1,
            ZIndex                = 13,
            Parent                = page,
        })
    end

    -- ── AddTab ────────────────────────────────────────────────────────
    local function AddTab(_, tabTitle, icon)
        -- _ = self (from colon call) — intentionally ignored
        local page  = MakePage()
        local order = #TabBtns + 1
        local BH    = IsMobile and 46 or 36

        -- Sidebar button
        local tb = N("TextButton", {
            Size                  = UDim2.new(1, 0, 0, BH),
            BackgroundColor3      = T.BG2,
            BackgroundTransparency= 0,
            BorderSizePixel       = 0,
            Text                  = "",
            LayoutOrder           = order,
            ZIndex                = 13,
            Parent                = SideScroll,
        })
        Cor(T.R, tb)

        -- Active indicator bar
        local ind = N("Frame", {
            Size             = UDim2.new(0, 3, 0.5, 0),
            Position         = UDim2.new(0, 0, 0.25, 0),
            BackgroundColor3 = T.Accent,
            BorderSizePixel  = 0,
            ZIndex           = 15,
            Visible          = false,
            Parent           = tb,
        })
        Cor(UDim.new(0, 2), ind)

        -- Icon
        local ic = N("TextLabel", {
            Size                  = UDim2.new(0, 22, 1, 0),
            Position              = UDim2.new(0, IsMobile and 5 or 10, 0, 0),
            BackgroundTransparency= 1,
            Text                  = icon or "·",
            TextColor3            = T.TextLow,
            TextSize              = IsMobile and 17 or 14,
            Font                  = Enum.Font.GothamBold,
            ZIndex                = 14,
            Parent                = tb,
        })

        -- Label (desktop only)
        local tx
        if not IsMobile then
            tx = N("TextLabel", {
                Size                  = UDim2.new(1, -34, 1, 0),
                Position              = UDim2.new(0, 32, 0, 0),
                BackgroundTransparency= 1,
                Text                  = tabTitle,
                TextColor3            = T.TextMid,
                TextSize              = 11,
                Font                  = Enum.Font.Gotham,
                TextXAlignment        = Enum.TextXAlignment.Left,
                ZIndex                = 14,
                Parent                = tb,
            })
        end

        -- Activate this tab
        local function Activate()
            if ActiveTab and TabBtns[ActiveTab] then
                local old = TabBtns[ActiveTab]
                TwPlay(old.frame, { BackgroundColor3 = T.BG2 }, 0.18)
                old.ind.Visible = false
                TwPlay(old.ic, { TextColor3 = T.TextLow }, 0.18)
                if old.tx then TwPlay(old.tx, { TextColor3 = T.TextMid }, 0.18) end
                Pages[ActiveTab].Visible = false
            end
            ActiveTab    = tabTitle
            TwPlay(tb, { BackgroundColor3 = T.BG3 }, 0.18)
            ind.Visible  = true
            TwPlay(ic, { TextColor3 = T.Accent }, 0.18)
            if tx then TwPlay(tx, { TextColor3 = T.TextHi }, 0.18) end
            page.Visible = true
        end

        tb.MouseButton1Click:Connect(Activate)
        tb.MouseEnter:Connect(function()
            if ActiveTab ~= tabTitle then
                TwPlay(tb, { BackgroundColor3 = Color3.fromRGB(22, 26, 50) }, 0.12)
            end
        end)
        tb.MouseLeave:Connect(function()
            if ActiveTab ~= tabTitle then
                TwPlay(tb, { BackgroundColor3 = T.BG2 }, 0.12)
            end
        end)

        TabBtns[tabTitle] = { frame = tb, ind = ind, ic = ic, tx = tx }
        Pages[tabTitle]   = page

        -- Auto-activate first tab
        if order == 1 then task.defer(Activate) end

        -- Tab API (methods use _ to absorb self from colon calls)
        return {
            AddSection = function(_, t)    _Section(page, t)       end,
            AddToggle  = function(_, cfg2) return _Toggle(page, cfg2) end,
            AddButton  = function(_, cfg2) _Button(page, cfg2)     end,
            AddLabel   = function(_, t)    _Label(page, t)         end,
        }
    end

    -- ── Keyboard shortcut: RightShift or LeftCtrl ─────────────────────
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if gpe then return end
        if inp.KeyCode == Enum.KeyCode.RightShift
        or inp.KeyCode == Enum.KeyCode.LeftControl then
            if not Win.Visible then
                Win.Visible = true
                Win.Size    = UDim2.new(0, WW, 0, 0)
                TwPlay(Win, { Size = UDim2.new(0, WW, 0, WH) },
                       0.35, Enum.EasingStyle.Back)
            else
                TwPlay(Win, { Size = UDim2.new(0, WW, 0, 0) },
                       0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                task.delay(0.27, function()
                    Win.Visible = false
                    Win.Size    = UDim2.new(0, WW, 0, WH)
                end)
            end
        end
    end)

    -- ── Window API ────────────────────────────────────────────────────
    return {
        AddTab = AddTab,

        -- Call without colon: Window.Show()
        Show = function()
            Win.Visible = true
            Win.Size    = UDim2.new(0, WW, 0, 0)
            Win.BackgroundTransparency = 1
            TwPlay(Win, { Size = UDim2.new(0, WW, 0, WH), BackgroundTransparency = 0 },
                   0.42, Enum.EasingStyle.Back)
            TwPlay(TStrip, { Size = UDim2.new(1, 0, 0, 2) }, 0.5)
        end,

        Hide = function()
            TwPlay(Win, { BackgroundTransparency = 1, Size = UDim2.new(0, WW, 0, 0) },
                   0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            task.delay(0.28, function()
                Win.Visible = false
                Win.Size    = UDim2.new(0, WW, 0, WH)
                Win.BackgroundTransparency = 0
            end)
        end,
    }
end

-- ╔════════════════════════════════════════════════════════════╗
-- ║                  P U B L I C  A P I                       ║
-- ╚════════════════════════════════════════════════════════════╝
--
--  Notify      → called directly:  Notify("t","b","success",4)
--  CreateWindow → called with colon: Lib:CreateWindow({...})
--  RunLoader   → called directly:  Lib.RunLoader("T","S",steps,cb)
--
local Mm2Ui = {
    Notify       = Notify,
    CreateWindow = CreateWindow,
    RunLoader    = RunLoader,
}

return Mm2Ui

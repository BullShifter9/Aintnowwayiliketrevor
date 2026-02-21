--[[
    OverdriveUI Library
    Replica of the Overdrive H UI style seen in Roblox
    
    COMPONENTS:
      - Window (draggable, minimizable)
      - Home Tab (Profile Card, FPS Card, Ping Card)
      - Navigation Tabs (bottom icon bar)
      - Sections (two-column layout, green header + subtitle)
      - Toggle (animated pill switch)
      - Button (hover + click animation)
      - Slider (draggable with value label)
      - Dropdown (expandable list)
      - Label (name + colored value)
      - InfoDisplay (large value display card)
      - Notifications (slide-in toast with progress bar)

    USAGE EXAMPLE at the bottom of this file.
--]]

local OverdriveUI = {}
OverdriveUI.__index = OverdriveUI

-- ══════════════════════════════════════════
--  Services
-- ══════════════════════════════════════════
local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local RunService      = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════
--  Color Palette
-- ══════════════════════════════════════════
local C = {
    Bg              = Color3.fromRGB(12, 18, 42),
    BgCard          = Color3.fromRGB(16, 23, 50),
    BgDark          = Color3.fromRGB(9, 13, 32),
    Border          = Color3.fromRGB(0, 210, 175),
    BorderPink      = Color3.fromRGB(220, 0, 210),
    BorderPurple    = Color3.fromRGB(130, 0, 230),
    NavBg           = Color3.fromRGB(10, 38, 50),
    NavActive       = Color3.fromRGB(0, 75, 65),
    Text            = Color3.fromRGB(220, 222, 235),
    TextDim         = Color3.fromRGB(130, 140, 165),
    Green           = Color3.fromRGB(0, 235, 105),
    Blue            = Color3.fromRGB(0, 185, 255),
    Teal            = Color3.fromRGB(0, 220, 180),
    ToggleOff       = Color3.fromRGB(48, 54, 75),
    ToggleOn        = Color3.fromRGB(0, 165, 255),
    SliderFill      = Color3.fromRGB(0, 180, 255),
    SliderTrack     = Color3.fromRGB(28, 38, 72),
    BtnBg           = Color3.fromRGB(20, 30, 68),
    BtnHover        = Color3.fromRGB(28, 44, 95),
    SectionTitle    = Color3.fromRGB(0, 235, 120),
    White           = Color3.fromRGB(255, 255, 255),
}

-- ══════════════════════════════════════════
--  Utility Functions
-- ══════════════════════════════════════════
local function New(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            pcall(function() obj[k] = v end)
        end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj, props, t, style, dir)
    local info = TweenInfo.new(
        t or 0.2,
        style or Enum.EasingStyle.Quad,
        dir   or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, info, props):Play()
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function GetGui()
    -- Try getting a safe parent
    if pcall(function() return game:GetService("CoreGui") end) then
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok then return cg end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ══════════════════════════════════════════
--  Library Constructor
-- ══════════════════════════════════════════
function OverdriveUI.new(config)
    local self = setmetatable({}, OverdriveUI)

    config          = config or {}
    self.Title      = config.Title      or "Overdrive H"
    self.ScriptName = config.ScriptName or "Script"
    self.Version    = config.Version    or "1.0"
    self._tabs      = {}
    self._homeTab   = nil
    self._startTime = tick()
    self._visible   = true

    -- ── ScreenGui ──────────────────────────
    self._gui = New("ScreenGui", {
        Name              = "OverdriveUI",
        ResetOnSpawn      = false,
        ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset    = true,
        Parent            = GetGui()
    })

    -- ── Main Window ───────────────────────
    self._win = New("Frame", {
        Name                 = "Window",
        Size                 = UDim2.new(0, 720, 0, 570),
        Position             = UDim2.new(0.5, -360, 0.5, -285),
        BackgroundColor3     = C.Bg,
        BackgroundTransparency = 0.06,
        BorderSizePixel      = 0,
        ClipsDescendants     = true,
        Parent               = self._gui
    })
    New("UICorner",  { CornerRadius = UDim.new(0, 12), Parent = self._win })
    New("UIStroke",  { Color = C.Border, Thickness = 1.5, Parent = self._win })

    -- Background gradient overlay
    local bgOverlay = New("Frame", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 0.45,
        BorderSizePixel = 0, ZIndex = 0, Parent = self._win
    })
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(8,  14, 58)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(5,  18, 52)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(14, 9,  48))
        }),
        Rotation = 140, Parent = bgOverlay
    })

    -- ── Header ────────────────────────────
    local hdr = New("Frame", {
        Name = "Header", Size = UDim2.new(1,0,0,64),
        BackgroundColor3 = C.BgDark, BackgroundTransparency = 0.08,
        BorderSizePixel = 0, ZIndex = 5, Parent = self._win
    })
    New("UICorner", { CornerRadius = UDim.new(0, 12), Parent = hdr })

    -- Gradient divider line
    local divLine = New("Frame", {
        Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,1,-2),
        BackgroundColor3 = C.Border, BackgroundTransparency = 0.1,
        BorderSizePixel = 0, ZIndex = 6, Parent = hdr
    })
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   C.Teal),
            ColorSequenceKeypoint.new(0.5, C.BorderPurple),
            ColorSequenceKeypoint.new(1,   C.Teal),
        }),
        Parent = divLine
    })

    -- Script name (top-left small)
    New("TextLabel", {
        Size = UDim2.new(0,220,0,18), Position = UDim2.new(0,14,0,8),
        Text = self.Version .. "  |  " .. self.ScriptName,
        TextColor3 = C.TextDim, TextSize = 11, Font = Enum.Font.GothamMedium,
        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7, Parent = hdr
    })

    -- Title (large, bottom-left of header)
    New("TextLabel", {
        Size = UDim2.new(0,240,0,32), Position = UDim2.new(0,14,0,26),
        Text = self.Title,
        TextColor3 = C.White, TextSize = 24, Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7, Parent = hdr
    })

    -- Timer (center)
    self._timerLbl = New("TextLabel", {
        Size = UDim2.new(0,110,0,28), Position = UDim2.new(0.5,-55,0,18),
        Text = "0s", TextColor3 = C.White, TextSize = 15,
        Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1, ZIndex = 7, Parent = hdr
    })

    -- Center icon (the character/logo button)
    local centerIcon = New("TextButton", {
        Size = UDim2.new(0,44,0,44), Position = UDim2.new(0.5,-22,0,-10),
        Text = "👤", TextSize = 20, Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(200,200,255),
        BackgroundColor3 = Color3.fromRGB(18,14,40),
        BorderSizePixel = 0, ZIndex = 8, Parent = hdr
    })
    New("UICorner", { CornerRadius = UDim.new(0,8), Parent = centerIcon })
    New("UIStroke", { Color = C.BorderPurple, Thickness = 2, Parent = centerIcon })

    -- User info panel (right side of header)
    local uPanel = New("Frame", {
        Size = UDim2.new(0,195,0,46), Position = UDim2.new(1,-258,0,9),
        BackgroundColor3 = Color3.fromRGB(14,18,44),
        BackgroundTransparency = 0.08, BorderSizePixel = 0,
        ZIndex = 7, Parent = hdr
    })
    New("UICorner", { CornerRadius = UDim.new(0,8), Parent = uPanel })
    New("UIStroke", { Color = C.BorderPink, Thickness = 1.5, Parent = uPanel })

    New("TextLabel", {
        Size = UDim2.new(1,-42,0,14), Position = UDim2.new(0,7,0,4),
        Text = "Logged in as", TextColor3 = C.TextDim, TextSize = 10,
        Font = Enum.Font.Gotham, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8, Parent = uPanel
    })
    New("TextLabel", {
        Size = UDim2.new(1,-42,0,20), Position = UDim2.new(0,7,0,20),
        Text = LocalPlayer.Name, TextColor3 = C.Text, TextSize = 13,
        Font = Enum.Font.GothamBold, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8, Parent = uPanel
    })

    local avatarImg = New("ImageLabel", {
        Size = UDim2.new(0,36,0,36), Position = UDim2.new(1,-40,0.5,-18),
        BackgroundColor3 = Color3.fromRGB(28,30,55), BorderSizePixel = 0,
        Image = "rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=150&h=150",
        ZIndex = 8, Parent = uPanel
    })
    New("UICorner", { CornerRadius = UDim.new(0,6), Parent = avatarImg })

    -- Minimize button
    local minBtn = New("TextButton", {
        Size = UDim2.new(0,46,0,46), Position = UDim2.new(1,-55,0,9),
        Text = "↩", TextSize = 18, Font = Enum.Font.GothamBold,
        TextColor3 = C.Text, BackgroundColor3 = Color3.fromRGB(18,22,50),
        BorderSizePixel = 0, ZIndex = 7, Parent = hdr
    })
    New("UICorner", { CornerRadius = UDim.new(0,8), Parent = minBtn })
    New("UIStroke", { Color = C.BorderPink, Thickness = 1.5, Parent = minBtn })

    minBtn.MouseButton1Click:Connect(function()
        self._visible = not self._visible
        self._content.Visible = self._visible
        self._navBar.Visible  = self._visible
        Tween(self._win, {
            Size = self._visible
                and UDim2.new(0,720,0,570)
                or  UDim2.new(0,720,0,68)
        }, 0.3, Enum.EasingStyle.Back)
    end)

    -- ── Content Area ──────────────────────
    self._content = New("Frame", {
        Name = "Content", Size = UDim2.new(1,0,1,-136),
        Position = UDim2.new(0,0,0,66),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ZIndex = 3, Parent = self._win
    })

    -- ── Nav Bar (bottom) ──────────────────
    self._navBar = New("Frame", {
        Name = "NavBar", Size = UDim2.new(1,-24,0,60),
        Position = UDim2.new(0,12,1,-70),
        BackgroundColor3 = C.NavBg, BackgroundTransparency = 0.08,
        BorderSizePixel = 0, ZIndex = 5, Parent = self._win
    })
    New("UICorner", { CornerRadius = UDim.new(0,12), Parent = self._navBar })
    New("UIStroke", { Color = C.Border, Thickness = 1.5, Parent = self._navBar })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0,5), Parent = self._navBar
    })

    -- Draggable
    MakeDraggable(self._win, hdr)

    -- Timer loop
    RunService.Heartbeat:Connect(function()
        local e = tick() - self._startTime
        local m = math.floor(e / 60)
        local s = math.floor(e % 60)
        self._timerLbl.Text = m > 0
            and (m.."m:"..string.format("%02d",s).."s")
            or  (s.."s")
    end)

    -- ── Toast Notification ────────────────
    self._toast = New("Frame", {
        Name = "Toast", Size = UDim2.new(0,290,0,74),
        Position = UDim2.new(0,-300,1,-84),
        BackgroundColor3 = C.BgCard, BackgroundTransparency = 0.05,
        BorderSizePixel = 0, ZIndex = 100, Parent = self._gui
    })
    New("UICorner", { CornerRadius = UDim.new(0,10), Parent = self._toast })
    New("UIStroke", { Color = Color3.fromRGB(0,210,80), Thickness = 1.5, Parent = self._toast })

    local toastIconBg = New("Frame", {
        Size = UDim2.new(0,36,0,36), Position = UDim2.new(0,10,0.5,-18),
        BackgroundColor3 = Color3.fromRGB(0,55,22), BorderSizePixel = 0,
        ZIndex = 101, Parent = self._toast
    })
    New("UICorner", { CornerRadius = UDim.new(0,8), Parent = toastIconBg })
    New("TextLabel", {
        Size = UDim2.new(1,0,1,0), Text = "✔",
        TextColor3 = Color3.fromRGB(0,225,85), TextSize = 20,
        Font = Enum.Font.GothamBold, BackgroundTransparency = 1,
        ZIndex = 102, Parent = toastIconBg
    })

    self._toastTitle = New("TextLabel", {
        Size = UDim2.new(1,-58,0,22), Position = UDim2.new(0,52,0,8),
        Text = "Notification", TextColor3 = C.Text, TextSize = 13,
        Font = Enum.Font.GothamBold, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101, Parent = self._toast
    })
    self._toastMsg = New("TextLabel", {
        Size = UDim2.new(1,-58,0,34), Position = UDim2.new(0,52,0,30),
        Text = "", TextColor3 = C.TextDim, TextSize = 11,
        Font = Enum.Font.Gotham, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, ZIndex = 101, Parent = self._toast
    })

    self._toastBar = New("Frame", {
        Size = UDim2.new(1,0,0,3), Position = UDim2.new(0,0,1,-3),
        BackgroundColor3 = Color3.fromRGB(0,210,80), BorderSizePixel = 0,
        ZIndex = 102, Parent = self._toast
    })
    New("UICorner", { CornerRadius = UDim.new(0,2), Parent = self._toastBar })

    return self
end

-- ══════════════════════════════════════════
--  Notify
-- ══════════════════════════════════════════
function OverdriveUI:Notify(title, message, duration)
    duration = duration or 4
    self._toastTitle.Text = title   or "Notification"
    self._toastMsg.Text   = message or ""

    -- Slide in
    Tween(self._toast, { Position = UDim2.new(0,12,1,-84) }, 0.4,
          Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    -- Reset bar then shrink
    self._toastBar.Size = UDim2.new(1,0,0,3)
    Tween(self._toastBar, { Size = UDim2.new(0,0,0,3) }, duration,
          Enum.EasingStyle.Linear)

    task.delay(duration, function()
        Tween(self._toast, { Position = UDim2.new(0,-300,1,-84) }, 0.4,
              Enum.EasingStyle.Back, Enum.EasingDirection.In)
    end)
end

-- ══════════════════════════════════════════
--  Home Tab
-- ══════════════════════════════════════════
function OverdriveUI:AddHomeTab(config)
    config = config or {}
    local tab = { Name = "Home", Icon = config.Icon or "🏠", _lib = self }
    self._homeTab = tab

    tab._page = New("Frame", {
        Name = "HomePage", Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Visible = true, ZIndex = 4, Parent = self._content
    })

    -- ── Profile card ──
    local profCard = New("Frame", {
        Size = UDim2.new(0,315,0,94), Position = UDim2.new(0,10,0,12),
        BackgroundColor3 = C.BgCard, BackgroundTransparency = 0.08,
        BorderSizePixel = 0, ZIndex = 5, Parent = tab._page
    })
    New("UICorner", { CornerRadius = UDim.new(0,10), Parent = profCard })
    New("UIStroke", { Color = C.BorderPink, Thickness = 1.5, Parent = profCard })

    local ava = New("ImageLabel", {
        Size = UDim2.new(0,72,0,72), Position = UDim2.new(0,10,0,11),
        BackgroundColor3 = Color3.fromRGB(28,32,62),
        BorderSizePixel = 0,
        Image = "rbxthumb://type=AvatarBust&id="..LocalPlayer.UserId.."&w=150&h=150",
        ZIndex = 6, Parent = profCard
    })
    New("UICorner", { CornerRadius = UDim.new(0,8), Parent = ava })

    New("TextLabel", {
        Size = UDim2.new(1,-95,0,24), Position = UDim2.new(0,92,0,12),
        Text = LocalPlayer.DisplayName, TextColor3 = C.White,
        TextSize = 17, Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6, Parent = profCard
    })
    New("TextLabel", {
        Size = UDim2.new(1,-95,0,18), Position = UDim2.new(0,92,0,36),
        Text = LocalPlayer.Name, TextColor3 = C.TextDim,
        TextSize = 12, Font = Enum.Font.Gotham,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6, Parent = profCard
    })
    New("TextLabel", {
        Size = UDim2.new(1,-95,0,18), Position = UDim2.new(0,92,0,58),
        Text = config.Tags or "User",
        TextColor3 = C.Green, TextSize = 12, Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6, Parent = profCard
    })

    -- ── FPS Card ──
    local fpsCard = New("Frame", {
        Size = UDim2.new(0,348,0,94), Position = UDim2.new(0,342,0,12),
        BackgroundColor3 = C.BgCard, BackgroundTransparency = 0.08,
        BorderSizePixel = 0, ZIndex = 5, Parent = tab._page
    })
    New("UICorner", { CornerRadius = UDim.new(0,10), Parent = fpsCard })
    New("UIStroke", { Color = C.BorderPink, Thickness = 1.5, Parent = fpsCard })

    New("TextLabel", {
        Size = UDim2.new(0.6,0,0,22), Position = UDim2.new(0,14,0,10),
        Text = "FPS", TextColor3 = C.TextDim, TextSize = 14,
        Font = Enum.Font.GothamMedium, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = fpsCard
    })
    New("TextLabel", {
        Size = UDim2.new(0,26,0,26), Position = UDim2.new(1,-36,0,8),
        Text = "⚡", TextSize = 18, Font = Enum.Font.GothamBold,
        TextColor3 = C.Green, BackgroundTransparency = 1,
        ZIndex = 6, Parent = fpsCard
    })

    local fpsLbl = New("TextLabel", {
        Size = UDim2.new(1,-14,0,48), Position = UDim2.new(0,14,0,36),
        Text = "0", TextColor3 = C.Green, TextSize = 40,
        Font = Enum.Font.GothamBold, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = fpsCard
    })

    -- ── Ping Card ──
    local pingCard = New("Frame", {
        Size = UDim2.new(0,348,0,94), Position = UDim2.new(0,342,0,118),
        BackgroundColor3 = C.BgCard, BackgroundTransparency = 0.08,
        BorderSizePixel = 0, ZIndex = 5, Parent = tab._page
    })
    New("UICorner", { CornerRadius = UDim.new(0,10), Parent = pingCard })
    New("UIStroke", { Color = C.BorderPink, Thickness = 1.5, Parent = pingCard })

    New("TextLabel", {
        Size = UDim2.new(0.7,0,0,22), Position = UDim2.new(0,14,0,10),
        Text = "Network Ping", TextColor3 = C.TextDim, TextSize = 14,
        Font = Enum.Font.GothamMedium, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = pingCard
    })
    New("TextLabel", {
        Size = UDim2.new(0,26,0,26), Position = UDim2.new(1,-36,0,8),
        Text = "📶", TextSize = 15, Font = Enum.Font.GothamBold,
        TextColor3 = C.Blue, BackgroundTransparency = 1,
        ZIndex = 6, Parent = pingCard
    })

    local pingLbl = New("TextLabel", {
        Size = UDim2.new(1,-14,0,48), Position = UDim2.new(0,14,0,36),
        Text = "0ms", TextColor3 = C.Green, TextSize = 40,
        Font = Enum.Font.GothamBold, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = pingCard
    })

    -- FPS counter
    local fCount, fLast = 0, tick()
    RunService.Heartbeat:Connect(function()
        fCount += 1
        local now = tick()
        if now - fLast >= 0.4 then
            fpsLbl.Text = string.format("%.2f", fCount / (now - fLast))
            fCount, fLast = 0, now
        end
    end)
    -- Ping updater
    task.spawn(function()
        while self._gui.Parent do
            task.wait(1)
            local ok, ping = pcall(function()
                return LocalPlayer:GetNetworkPing() * 1000
            end)
            pingLbl.Text = ok and string.format("%.2f", ping).."ms" or "N/A"
        end
    end)

    -- Home nav button
    local navBtn = New("TextButton", {
        Name = "HomeNav", Size = UDim2.new(0,54,0,48),
        Text = tab.Icon, TextSize = 22, Font = Enum.Font.GothamBold,
        TextColor3 = C.Teal, BackgroundColor3 = C.NavActive,
        BackgroundTransparency = 0.1, BorderSizePixel = 0,
        ZIndex = 6, Parent = self._navBar
    })
    New("UICorner", { CornerRadius = UDim.new(0,8), Parent = navBtn })
    New("UIStroke", { Color = C.Teal, Thickness = 2, Parent = navBtn })

    tab._navBtn = navBtn
    navBtn.MouseButton1Click:Connect(function() self:_ShowHome() end)

    self:_ShowHome()
    return tab
end

function OverdriveUI:_ShowHome()
    -- Hide all tab pages
    for _, t in ipairs(self._tabs) do
        t._page.Visible = false
        self:_SetNavActive(t._navBtn, false)
    end
    if self._homeTab then
        self._homeTab._page.Visible = true
        self:_SetNavActive(self._homeTab._navBtn, true)
    end
end

function OverdriveUI:_SetNavActive(btn, active)
    if not btn then return end
    local stroke = btn:FindFirstChildOfClass("UIStroke")
    if active then
        btn.BackgroundColor3 = C.NavActive
        if stroke then stroke.Color = C.Teal; stroke.Thickness = 2 end
    else
        btn.BackgroundColor3 = C.NavBg
        if stroke then stroke.Color = C.Border; stroke.Thickness = 1 end
    end
end

-- ══════════════════════════════════════════
--  Add Tab
-- ══════════════════════════════════════════
function OverdriveUI:AddTab(config)
    config = config or {}
    local tab = {
        Name     = config.Name or "Tab",
        Icon     = config.Icon or "🔧",
        _lib     = self,
        _sections = {}
    }

    -- Scrollable page
    tab._page = New("ScrollingFrame", {
        Name = tab.Name.."Page",
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.Teal,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, ZIndex = 4, Parent = self._content
    })

    -- Page top (back + title)
    local titleBar = New("Frame", {
        Size = UDim2.new(1,0,0,40),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        LayoutOrder = 0, ZIndex = 5, Parent = tab._page
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10),
        PaddingTop = UDim.new(0,6), Parent = titleBar
    })

    local backBtn = New("TextButton", {
        Size = UDim2.new(0,32,0,32), Position = UDim2.new(0,0,0,4),
        Text = "<", TextSize = 18, Font = Enum.Font.GothamBold,
        TextColor3 = C.Text, BackgroundTransparency = 1,
        ZIndex = 6, Parent = titleBar
    })
    New("TextLabel", {
        Size = UDim2.new(1,-40,1,0), Position = UDim2.new(0,36,0,0),
        Text = tab.Name, TextColor3 = C.Text, TextSize = 18,
        Font = Enum.Font.GothamBold, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = titleBar
    })
    backBtn.MouseButton1Click:Connect(function() self:_ShowHome() end)

    -- Two-column holder
    tab._colFrame = New("Frame", {
        Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        LayoutOrder = 1, ZIndex = 4, Parent = tab._page
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10),
        PaddingBottom = UDim.new(0,10), Parent = tab._colFrame
    })

    tab._leftCol = New("Frame", {
        Name = "Left", Size = UDim2.new(0.5,-5,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0,0,0,0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ZIndex = 4, Parent = tab._colFrame
    })
    New("UIListLayout", {
        Padding = UDim.new(0,8), FillDirection = Enum.FillDirection.Vertical,
        Parent = tab._leftCol
    })

    tab._rightCol = New("Frame", {
        Name = "Right", Size = UDim2.new(0.5,-5,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0.5,5,0,0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ZIndex = 4, Parent = tab._colFrame
    })
    New("UIListLayout", {
        Padding = UDim.new(0,8), FillDirection = Enum.FillDirection.Vertical,
        Parent = tab._rightCol
    })

    -- Nav button
    local navBtn = New("TextButton", {
        Name = tab.Name.."Nav", Size = UDim2.new(0,54,0,48),
        Text = tab.Icon, TextSize = 22, Font = Enum.Font.GothamBold,
        TextColor3 = C.Teal, BackgroundColor3 = C.NavBg,
        BackgroundTransparency = 0.1, BorderSizePixel = 0,
        ZIndex = 6, Parent = self._navBar
    })
    New("UICorner", { CornerRadius = UDim.new(0,8), Parent = navBtn })
    New("UIStroke", { Color = C.Border, Thickness = 1, Parent = navBtn })

    tab._navBtn = navBtn
    navBtn.MouseButton1Click:Connect(function()
        -- Hide everything
        if self._homeTab then self._homeTab._page.Visible = false end
        self:_SetNavActive(self._homeTab and self._homeTab._navBtn, false)
        for _, t in ipairs(self._tabs) do
            t._page.Visible = false
            self:_SetNavActive(t._navBtn, false)
        end
        tab._page.Visible = true
        self:_SetNavActive(navBtn, true)
    end)

    table.insert(self._tabs, tab)

    -- Return a section adder
    local tabProxy = {}
    function tabProxy:AddSection(cfg)
        return OverdriveUI._AddSection(self._lib, tab, cfg)
    end
    tabProxy._lib = self
    tabProxy._tab = tab
    setmetatable(tabProxy, {
        __index = function(_, k) return tab[k] end
    })
    return tabProxy
end

-- ══════════════════════════════════════════
--  Add Section
-- ══════════════════════════════════════════
function OverdriveUI:_AddSection(tab, config)
    config = config or {}
    local sec = {
        Name     = config.Name     or "Section",
        Subtitle = config.Subtitle or "",
        Side     = config.Side     or "Left",
        _order   = 1,
        _tab     = tab,
        _lib     = self,
    }

    local col = (sec.Side == "Right") and tab._rightCol or tab._leftCol

    sec._frame = New("Frame", {
        Name = sec.Name.."Sec",
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.BgCard, BackgroundTransparency = 0.06,
        BorderSizePixel = 0, ZIndex = 5, Parent = col
    })
    New("UICorner", { CornerRadius = UDim.new(0,10), Parent = sec._frame })
    New("UIStroke", { Color = Color3.fromRGB(28,45,88), Thickness = 1, Parent = sec._frame })

    New("UIListLayout", {
        Padding = UDim.new(0,6), FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = sec._frame
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10),
        PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,12),
        Parent = sec._frame
    })

    -- Section header
    local headerH = 26 + (sec.Subtitle ~= "" and 18 or 0)
    local secHdr = New("Frame", {
        Size = UDim2.new(1,0,0,headerH), BackgroundTransparency = 1,
        LayoutOrder = 0, ZIndex = 6, Parent = sec._frame
    })
    New("TextLabel", {
        Size = UDim2.new(1,0,0,24), Position = UDim2.new(0,0,0,0),
        Text = sec.Name:upper(), TextColor3 = C.SectionTitle,
        TextSize = 16, Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7, Parent = secHdr
    })
    if sec.Subtitle ~= "" then
        New("TextLabel", {
            Size = UDim2.new(1,0,0,16), Position = UDim2.new(0,0,0,26),
            Text = sec.Subtitle:upper(), TextColor3 = C.TextDim,
            TextSize = 10, Font = Enum.Font.GothamMedium,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7, Parent = secHdr
        })
    end

    -- ── TOGGLE ────────────────────────────
    function sec:AddToggle(cfg)
        cfg = cfg or {}
        local row = New("Frame", {
            Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1,
            BorderSizePixel = 0, LayoutOrder = self._order, ZIndex = 7,
            Parent = self._frame
        })
        self._order = self._order + 1

        New("TextLabel", {
            Size = UDim2.new(1,-56,1,0),
            Text = cfg.Name or "Toggle", TextColor3 = C.Text,
            TextSize = 13, Font = Enum.Font.GothamMedium,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8, Parent = row
        })

        local state = cfg.Default == true

        local pill = New("Frame", {
            Size = UDim2.new(0,44,0,24),
            Position = UDim2.new(1,-46,0.5,-12),
            BackgroundColor3 = state and C.ToggleOn or C.ToggleOff,
            BorderSizePixel = 0, ZIndex = 8, Parent = row
        })
        New("UICorner", { CornerRadius = UDim.new(1,0), Parent = pill })

        local dot = New("Frame", {
            Size = UDim2.new(0,18,0,18),
            Position = state
                and UDim2.new(1,-21,0.5,-9)
                or  UDim2.new(0, 3, 0.5,-9),
            BackgroundColor3 = C.White, BorderSizePixel = 0,
            ZIndex = 9, Parent = pill
        })
        New("UICorner", { CornerRadius = UDim.new(1,0), Parent = dot })

        local clickArea = New("TextButton", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
            Text = "", ZIndex = 10, Parent = pill
        })
        clickArea.MouseButton1Click:Connect(function()
            state = not state
            Tween(pill, { BackgroundColor3 = state and C.ToggleOn or C.ToggleOff }, 0.18)
            Tween(dot,  { Position = state
                and UDim2.new(1,-21,0.5,-9)
                or  UDim2.new(0, 3, 0.5,-9)
            }, 0.18)
            if cfg.Callback then cfg.Callback(state) end
        end)

        local obj = {}
        function obj:Set(v)
            state = v
            Tween(pill, { BackgroundColor3 = state and C.ToggleOn or C.ToggleOff }, 0.18)
            Tween(dot,  { Position = state
                and UDim2.new(1,-21,0.5,-9)
                or  UDim2.new(0, 3, 0.5,-9)
            }, 0.18)
        end
        function obj:Get() return state end
        return obj
    end

    -- ── BUTTON ────────────────────────────
    function sec:AddButton(cfg)
        cfg = cfg or {}
        local btn = New("TextButton", {
            Size = UDim2.new(1,0,0,38),
            BackgroundColor3 = C.BtnBg, BorderSizePixel = 0,
            Text = cfg.Name or "Button", TextColor3 = C.Text,
            TextSize = 14, Font = Enum.Font.GothamBold,
            LayoutOrder = self._order, ZIndex = 7, Parent = self._frame
        })
        self._order = self._order + 1
        New("UICorner", { CornerRadius = UDim.new(0,8), Parent = btn })
        New("UIStroke", { Color = Color3.fromRGB(38,52,100), Thickness = 1, Parent = btn })

        btn.MouseEnter:Connect(function()
            Tween(btn, { BackgroundColor3 = C.BtnHover }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, { BackgroundColor3 = C.BtnBg }, 0.15)
        end)
        btn.MouseButton1Click:Connect(function()
            Tween(btn, { BackgroundColor3 = C.Teal }, 0.1)
            task.delay(0.18, function()
                Tween(btn, { BackgroundColor3 = C.BtnBg }, 0.2)
            end)
            if cfg.Callback then cfg.Callback() end
        end)

        return btn
    end

    -- ── SLIDER ────────────────────────────
    function sec:AddSlider(cfg)
        cfg = cfg or {}
        local min  = cfg.Min     or 0
        local max  = cfg.Max     or 100
        local val  = math.clamp(cfg.Default or min, min, max)
        local isInt = cfg.Integer == true

        local container = New("Frame", {
            Size = UDim2.new(1,0,0,50), BackgroundTransparency = 1,
            BorderSizePixel = 0, LayoutOrder = self._order, ZIndex = 7,
            Parent = self._frame
        })
        self._order = self._order + 1

        -- Label row
        New("TextLabel", {
            Size = UDim2.new(0.7,0,0,20), Position = UDim2.new(0,0,0,0),
            Text = cfg.Name or "Slider", TextColor3 = C.Text,
            TextSize = 13, Font = Enum.Font.GothamMedium,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8, Parent = container
        })
        local valLbl = New("TextLabel", {
            Size = UDim2.new(0.3,0,0,20), Position = UDim2.new(0.7,0,0,0),
            Text = isInt and tostring(math.round(val)) or string.format("%.1f", val),
            TextColor3 = C.Blue, TextSize = 13, Font = Enum.Font.GothamBold,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 8, Parent = container
        })

        -- Track
        local track = New("Frame", {
            Size = UDim2.new(1,0,0,8), Position = UDim2.new(0,0,0,30),
            BackgroundColor3 = C.SliderTrack, BorderSizePixel = 0,
            ZIndex = 7, Parent = container
        })
        New("UICorner", { CornerRadius = UDim.new(1,0), Parent = track })

        local pct = (val - min) / (max - min)
        local fill = New("Frame", {
            Size = UDim2.new(pct,0,1,0),
            BackgroundColor3 = C.SliderFill, BorderSizePixel = 0,
            ZIndex = 8, Parent = track
        })
        New("UICorner", { CornerRadius = UDim.new(1,0), Parent = fill })

        local thumb = New("Frame", {
            Size = UDim2.new(0,18,0,18),
            Position = UDim2.new(pct,-9,0.5,-9),
            BackgroundColor3 = C.White, BorderSizePixel = 0,
            ZIndex = 9, Parent = track
        })
        New("UICorner", { CornerRadius = UDim.new(1,0), Parent = thumb })
        New("UIStroke", { Color = C.Blue, Thickness = 1.5, Parent = thumb })

        local hitbox = New("TextButton", {
            Size = UDim2.new(1,0,0,24), Position = UDim2.new(0,0,0.5,-12),
            BackgroundTransparency = 1, Text = "", ZIndex = 10, Parent = track
        })

        local dragging = false
        local function updateSlider(inputX)
            local abs = track.AbsolutePosition
            local sz  = track.AbsoluteSize
            local p   = math.clamp((inputX - abs.X) / sz.X, 0, 1)
            val = min + (max - min) * p
            if isInt then val = math.round(val) end
            fill.Size           = UDim2.new(p, 0, 1, 0)
            thumb.Position      = UDim2.new(p,-9,0.5,-9)
            valLbl.Text         = isInt and tostring(math.round(val)) or string.format("%.1f", val)
            if cfg.Callback then cfg.Callback(val) end
        end

        hitbox.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateSlider(inp.Position.X)
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
                updateSlider(inp.Position.X)
            end
        end)

        local obj = {}
        function obj:Set(v)
            val = math.clamp(v, min, max)
            local p = (val - min) / (max - min)
            fill.Size      = UDim2.new(p, 0, 1, 0)
            thumb.Position = UDim2.new(p,-9,0.5,-9)
            valLbl.Text    = isInt and tostring(math.round(val)) or string.format("%.1f", val)
        end
        function obj:Get() return val end
        return obj
    end

    -- ── DROPDOWN ──────────────────────────
    function sec:AddDropdown(cfg)
        cfg = cfg or {}
        local options  = cfg.Options or {}
        local selected = cfg.Default or (options[1] or "Select")
        local open     = false

        local wrap = New("Frame", {
            Size = UDim2.new(1,0,0,58), BackgroundTransparency = 1,
            ClipsDescendants = false, BorderSizePixel = 0,
            LayoutOrder = self._order, ZIndex = 7, Parent = self._frame
        })
        self._order = self._order + 1

        New("TextLabel", {
            Size = UDim2.new(1,0,0,18), Position = UDim2.new(0,0,0,0),
            Text = cfg.Name or "Dropdown", TextColor3 = C.TextDim,
            TextSize = 11, Font = Enum.Font.GothamMedium,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8, Parent = wrap
        })

        local mainBtn = New("TextButton", {
            Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,20),
            BackgroundColor3 = C.BtnBg, BorderSizePixel = 0, Text = "",
            ZIndex = 8, Parent = wrap
        })
        New("UICorner", { CornerRadius = UDim.new(0,8), Parent = mainBtn })
        New("UIStroke", { Color = Color3.fromRGB(38,52,100), Thickness = 1, Parent = mainBtn })

        local selLbl = New("TextLabel", {
            Size = UDim2.new(1,-36,1,0), Position = UDim2.new(0,10,0,0),
            Text = selected, TextColor3 = C.Text, TextSize = 13,
            Font = Enum.Font.GothamMedium, BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9, Parent = mainBtn
        })
        New("TextLabel", {
            Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-28,0.5,-12),
            Text = "▼", TextSize = 11, Font = Enum.Font.GothamBold,
            TextColor3 = C.TextDim, BackgroundTransparency = 1,
            ZIndex = 9, Parent = mainBtn
        })

        local list = New("Frame", {
            Size = UDim2.new(1,0,0,#options*32),
            Position = UDim2.new(0,0,1,4),
            BackgroundColor3 = Color3.fromRGB(16,24,54),
            BorderSizePixel = 0, Visible = false,
            ZIndex = 20, ClipsDescendants = true, Parent = mainBtn
        })
        New("UICorner", { CornerRadius = UDim.new(0,8), Parent = list })
        New("UIStroke", { Color = Color3.fromRGB(38,52,100), Thickness = 1, Parent = list })
        New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

        for i, opt in ipairs(options) do
            local ob = New("TextButton", {
                Size = UDim2.new(1,0,0,32), LayoutOrder = i,
                BackgroundTransparency = 1, Text = opt,
                TextColor3 = C.Text, TextSize = 13,
                Font = Enum.Font.GothamMedium, ZIndex = 21, Parent = list
            })
            ob.MouseEnter:Connect(function()
                ob.BackgroundTransparency = 0.7
                ob.BackgroundColor3 = Color3.fromRGB(30,42,88)
            end)
            ob.MouseLeave:Connect(function()
                ob.BackgroundTransparency = 1
            end)
            ob.MouseButton1Click:Connect(function()
                selected  = opt
                selLbl.Text = opt
                list.Visible = false
                open = false
                if cfg.Callback then cfg.Callback(opt) end
            end)
        end

        mainBtn.MouseButton1Click:Connect(function()
            open = not open
            list.Visible = open
        end)

        local obj = {}
        function obj:Set(v) selected = v; selLbl.Text = v end
        function obj:Get() return selected end
        return obj
    end

    -- ── LABEL ─────────────────────────────
    function sec:AddLabel(cfg)
        cfg = cfg or {}
        local row = New("Frame", {
            Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1,
            BorderSizePixel = 0, LayoutOrder = self._order, ZIndex = 7,
            Parent = self._frame
        })
        self._order = self._order + 1

        New("TextLabel", {
            Size = UDim2.new(0.58,0,1,0),
            Text = cfg.Name or "Label", TextColor3 = C.Text,
            TextSize = 13, Font = Enum.Font.GothamMedium,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8, Parent = row
        })
        local valLbl = New("TextLabel", {
            Size = UDim2.new(0.42,0,1,0), Position = UDim2.new(0.58,0,0,0),
            Text = tostring(cfg.Value or ""),
            TextColor3 = cfg.Color or C.Green, TextSize = 13,
            Font = Enum.Font.GothamBold, BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 8, Parent = row
        })

        local obj = {}
        function obj:Set(v, col)
            valLbl.Text = tostring(v)
            if col then valLbl.TextColor3 = col end
        end
        function obj:Get() return valLbl.Text end
        return obj
    end

    -- ── INFO DISPLAY CARD ─────────────────
    function sec:AddInfoDisplay(cfg)
        cfg = cfg or {}
        local card = New("Frame", {
            Size = UDim2.new(1,0,0,66),
            BackgroundColor3 = Color3.fromRGB(12,18,44),
            BackgroundTransparency = 0.04, BorderSizePixel = 0,
            LayoutOrder = self._order, ZIndex = 7, Parent = self._frame
        })
        self._order = self._order + 1
        New("UICorner", { CornerRadius = UDim.new(0,8), Parent = card })

        New("TextLabel", {
            Size = UDim2.new(1,-36,0,22), Position = UDim2.new(0,12,0,6),
            Text = cfg.Name or "Info", TextColor3 = C.TextDim,
            TextSize = 13, Font = Enum.Font.GothamMedium,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8, Parent = card
        })
        if cfg.Icon then
            New("TextLabel", {
                Size = UDim2.new(0,26,0,26), Position = UDim2.new(1,-30,0,4),
                Text = cfg.Icon, TextSize = 16, Font = Enum.Font.GothamBold,
                TextColor3 = cfg.IconColor or C.Green,
                BackgroundTransparency = 1, ZIndex = 8, Parent = card
            })
        end
        local valLbl = New("TextLabel", {
            Size = UDim2.new(1,-14,0,34), Position = UDim2.new(0,12,0,26),
            Text = tostring(cfg.Value or "0"),
            TextColor3 = cfg.Color or C.Green, TextSize = 28,
            Font = Enum.Font.GothamBold, BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 8, Parent = card
        })

        local obj = {}
        function obj:Set(v, col)
            valLbl.Text = tostring(v)
            if col then valLbl.TextColor3 = col end
        end
        function obj:Get() return valLbl.Text end
        return obj
    end

    -- ── SEPARATOR ─────────────────────────
    function sec:AddSeparator()
        local sep = New("Frame", {
            Size = UDim2.new(1,0,0,1),
            BackgroundColor3 = Color3.fromRGB(40,55,90),
            BorderSizePixel = 0, LayoutOrder = self._order, ZIndex = 7,
            Parent = self._frame
        })
        self._order = self._order + 1
        return sep
    end

    table.insert(tab._sections, sec)
    return sec
end

-- ══════════════════════════════════════════
--  Destroy
-- ══════════════════════════════════════════
function OverdriveUI:Destroy()
    if self._gui then self._gui:Destroy() end
end

-- ══════════════════════════════════════════
--  Return
-- ══════════════════════════════════════════
return OverdriveUI


--[[
╔══════════════════════════════════════════════════════════╗
║               EXAMPLE USAGE                              ║
╚══════════════════════════════════════════════════════════╝

local UI = loadstring(game:HttpGet("YOUR_RAW_URL"))()

-- Create the window
local window = UI.new({
    Title      = "Overdrive H",
    ScriptName = "Murder Mystery 2",
    Version    = "2.9",
})

-- Home tab (shows profile, FPS, ping)
window:AddHomeTab({
    Icon = "🏠",
    Tags = "Premium & Exclusive",
})

-- Show a notification
window:Notify("Overdrive", "Script has been loaded! Took 0.5 seconds.", 5)

-- Add a tab
local mainTab = window:AddTab({ Name = "Main", Icon = "⚙️" })

-- Left section
local selfMods = mainTab:AddSection({
    Name     = "Self Mods",
    Subtitle = "Universal",
    Side     = "Left",
})

local wsToggle = selfMods:AddToggle({
    Name     = "Enable WalkSpeed",
    Default  = false,
    Callback = function(v)
        if v then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 32
        else
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
})

local wsSlider = selfMods:AddSlider({
    Name     = "WalkSpeed",
    Min      = 16,
    Max      = 200,
    Default  = 16,
    Integer  = true,
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
})

-- Right section
local serverSec = mainTab:AddSection({
    Name     = "Server",
    Subtitle = "MM2 / MMV",
    Side     = "Right",
})

serverSec:AddToggle({
    Name     = "Show Round Timer",
    Default  = true,
    Callback = function(v)
        print("Show Round Timer:", v)
    end
})

serverSec:AddToggle({
    Name     = "Instant Role Notify",
    Default  = true,
    Callback = function(v)
        print("Instant Role Notify:", v)
    end
})

-- Add a Combat tab with dropdowns and sliders
local combatTab = window:AddTab({ Name = "Combat", Icon = "⚔️" })

local aimlockSec = combatTab:AddSection({
    Name     = "Aimlock",
    Subtitle = "Universal",
    Side     = "Left",
})

local aimToggle = aimlockSec:AddToggle({
    Name    = "Enable Aimlock",
    Default = false,
    Callback = function(v)
        print("Aimlock:", v)
    end
})

aimlockSec:AddDropdown({
    Name    = "Target Aimpart",
    Options = { "HumanoidRootPart", "Head", "Torso", "LeftArm", "RightArm" },
    Default = "HumanoidRootPart",
    Callback = function(v)
        print("Aimpart:", v)
    end
})

local offsetsSec = combatTab:AddSection({
    Name     = "Offsets",
    Subtitle = "Universal",
    Side     = "Right",
})

offsetsSec:AddSlider({
    Name    = "Y Position Offset (%)",
    Min     = -100,
    Max     = 100,
    Default = -7,
    Integer = true,
    Callback = function(v)
        print("Y Offset:", v)
    end
})

offsetsSec:AddSlider({
    Name    = "Z Position Offset (%)",
    Min     = -100,
    Max     = 100,
    Default = 0,
    Integer = true,
    Callback = function(v)
        print("Z Offset:", v)
    end
})

-- Visuals tab
local visualsTab = window:AddTab({ Name = "Visuals", Icon = "👁️" })

local chamSec = visualsTab:AddSection({
    Name     = "Cham",
    Subtitle = "Universal",
    Side     = "Left",
})

chamSec:AddToggle({ Name = "Cham Everyone",     Default = false })
chamSec:AddToggle({ Name = "Cham Murderer Only", Default = false })
chamSec:AddToggle({ Name = "Cham Sheriff Only",  Default = false })

local espSec = visualsTab:AddSection({
    Name     = "ESP",
    Subtitle = "Universal",
    Side     = "Right",
})

espSec:AddToggle({ Name = "ESP Everyone",     Default = true  })
espSec:AddToggle({ Name = "ESP Murderer Only", Default = false })
espSec:AddToggle({ Name = "ESP Sheriff Only",  Default = false })

-- World tab with info labels
local worldTab = window:AddTab({ Name = "World", Icon = "🌐" })

local serverInfoSec = worldTab:AddSection({
    Name     = "Server",
    Subtitle = "MM2 / MMV",
    Side     = "Left",
})

local murdererLbl = serverInfoSec:AddLabel({
    Name  = "Murderer is:",
    Value = "Unknown",
    Color = Color3.fromRGB(255, 80, 80),
})

local heroLbl = serverInfoSec:AddLabel({
    Name  = "Hero is:",
    Value = "Unknown",
    Color = Color3.fromRGB(80, 200, 255),
})

local gunLbl = serverInfoSec:AddLabel({
    Name  = "Gun Status:",
    Value = "Not Dropped",
    Color = Color3.fromRGB(255, 80, 80),
})

serverInfoSec:AddSeparator()

serverInfoSec:AddButton({
    Name     = "Grab Gun",
    Callback = function()
        print("Grabbing gun!")
    end
})

local miscSec = worldTab:AddSection({
    Name     = "Miscellaneous",
    Subtitle = "Universal / MM2 / MMV",
    Side     = "Right",
})

miscSec:AddButton({ Name = "FPS Boost",        Callback = function() print("FPS Boost") end })
miscSec:AddButton({ Name = "Less Lag",         Callback = function() print("Less Lag")  end })
miscSec:AddToggle({ Name = "No Shadows",       Default = false })
miscSec:AddButton({ Name = "Remove Barriers",  Callback = function() print("Remove Barriers") end })

-- Example: update label values live
task.spawn(function()
    while true do
        task.wait(3)
        -- murdererLbl:Set("PlayerName", Color3.fromRGB(255,80,80))
    end
end)

]]

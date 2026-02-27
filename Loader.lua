--[[
    ████████╗  ██╗  ██╗ ██████╗  ██╗████████╗
       ██╔══╝  ██║  ██║██╔═══██╗ ██║╚══██╔══╝
       ██║     ███████║██║   ██║ ██║   ██║
       ██║     ██╔══██║██║   ██║ ██║   ██║
       ██║     ██║  ██║╚██████╔╝ ██║   ██║
       ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═╝   ╚═╝

    UILib HWID Loader v3.0
    — Secure device fingerprint generation
    — API verification with animated progress UI
    — Background polling thread (3s interval)
    — Kick on blacklist / force_shutdown support
    — Discord bot command relay support
--]]

-- ── CONFIG — edit before deploying ──────────────────────────────────────────
local CONFIG = {
    API_URL         = "https://hwid-drz0.onrender.com",  -- ← your Render URL
    API_KEY         = "FUCKNIGGERS",             -- ← match server
    POLL_INTERVAL   = 3,    -- seconds between /poll calls
    TIMEOUT         = 12,   -- HTTP timeout in seconds
    HWID_FILE       = "uilib_hwid.dat",   -- persisted via writefile
    RETRY_MAX       = 3,    -- retries on server_error
}

-- ── SERVICES ─────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService     = game:GetService("SoundService")

local LP = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────────────────────────
-- HWID ENGINE
-- Generates a stable 12–16 char lowercase alphanumeric fingerprint.
-- Persisted via writefile so it survives account switches.
-- ─────────────────────────────────────────────────────────────────────────────
local function generateHWID()
    -- Length: random between 12 and 16
    local len = math.random(12, 16)
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local result = {}

    -- Seeded with device-stable data where possible
    local seed = 0
    -- Use viewport size as a minor device signal
    local vp = workspace.CurrentCamera.ViewportSize
    seed = seed + (vp.X * 31) + (vp.Y * 97)
    -- Mix with tick for uniqueness on first generation
    seed = seed + math.floor(tick() * 1000) % 999983
    math.randomseed(seed)

    for i = 1, len do
        local idx = math.random(1, #chars)
        table.insert(result, chars:sub(idx, idx))
    end

    return table.concat(result)
end

local function getOrCreateHWID()
    -- Try executor persistence first (survives account switch)
    local ok, stored = pcall(readfile, CONFIG.HWID_FILE)
    if ok and stored and #stored >= 12 and stored:match("^[a-z0-9]+$") then
        return stored
    end

    -- Generate new HWID
    local hwid = generateHWID()
    pcall(writefile, CONFIG.HWID_FILE, hwid)
    return hwid
end

local HWID    = getOrCreateHWID()
local USERNAME = LP.Name
local USER_ID  = tostring(LP.UserId)
local GAME_ID  = tostring(game.GameId)

-- ─────────────────────────────────────────────────────────────────────────────
-- LOADER UI BUILDER
-- ─────────────────────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "UILib_Loader"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LP.PlayerGui end

-- Background overlay (full screen, blurred feel)
local Overlay = Instance.new("Frame")
Overlay.Size                  = UDim2.new(1,0,1,0)
Overlay.BackgroundColor3      = Color3.fromRGB(6,6,9)
Overlay.BackgroundTransparency= 0.15
Overlay.ZIndex                = 1
Overlay.Parent                = ScreenGui

-- Noise texture for depth
local Noise = Instance.new("ImageLabel")
Noise.Size                    = UDim2.new(1,0,1,0)
Noise.BackgroundTransparency  = 1
Noise.Image                   = "rbxassetid://9896295127"
Noise.ImageTransparency       = 0.92
Noise.ImageColor3             = Color3.fromRGB(180,180,255)
Noise.ZIndex                  = 2
Noise.Parent                  = Overlay

-- Center card
local Card = Instance.new("Frame")
Card.Name                     = "LoaderCard"
Card.Size                     = UDim2.new(0,360,0,220)
Card.Position                 = UDim2.new(0.5,-180,0.5,-110)
Card.BackgroundColor3         = Color3.fromRGB(14,14,18)
Card.BackgroundTransparency   = 1  -- starts invisible
Card.ZIndex                   = 10
Card.Parent                   = ScreenGui

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0,14)
CardCorner.Parent       = Card

local CardStroke = Instance.new("UIStroke")
CardStroke.Color     = Color3.fromRGB(60,60,80)
CardStroke.Thickness = 1
CardStroke.Parent    = Card

-- Accent glow bar at top of card
local GlowBar = Instance.new("Frame")
GlowBar.Size             = UDim2.new(0,0,0,2)
GlowBar.Position         = UDim2.new(0.5,0,0,0)
GlowBar.AnchorPoint      = Vector2.new(0.5,0)
GlowBar.BackgroundColor3 = Color3.fromRGB(99,102,241)
GlowBar.BorderSizePixel  = 0
GlowBar.ZIndex           = 11
GlowBar.Parent           = Card
local GlowBarCorner      = Instance.new("UICorner")
GlowBarCorner.CornerRadius = UDim.new(0,2)
GlowBarCorner.Parent       = GlowBar

-- Lock icon (animated)
local LockFrame = Instance.new("Frame")
LockFrame.Size             = UDim2.new(0,48,0,48)
LockFrame.Position         = UDim2.new(0.5,-24,0,28)
LockFrame.BackgroundColor3 = Color3.fromRGB(24,24,32)
LockFrame.ZIndex           = 11
LockFrame.Parent           = Card
Instance.new("UICorner",LockFrame).CornerRadius = UDim.new(0,10)
local LockStroke = Instance.new("UIStroke")
LockStroke.Color     = Color3.fromRGB(99,102,241)
LockStroke.Thickness = 1.5
LockStroke.Parent    = LockFrame

local LockIcon = Instance.new("TextLabel")
LockIcon.Text       = "🔒"
LockIcon.Size       = UDim2.new(1,0,1,0)
LockIcon.BackgroundTransparency = 1
LockIcon.TextColor3 = Color3.fromRGB(255,255,255)
LockIcon.Font       = Enum.Font.GothamBold
LockIcon.TextSize   = 22
LockIcon.ZIndex     = 12
LockIcon.Parent     = LockFrame

-- App name
local AppName = Instance.new("TextLabel")
AppName.Text       = "UILib"
AppName.Size       = UDim2.new(1,0,0,22)
AppName.Position   = UDim2.new(0,0,0,86)
AppName.BackgroundTransparency = 1
AppName.TextColor3 = Color3.fromRGB(230,230,240)
AppName.Font       = Enum.Font.GothamBold
AppName.TextSize   = 18
AppName.ZIndex     = 11
AppName.Parent     = Card

-- Status line
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text       = "Initializing…"
StatusLabel.Size       = UDim2.new(1,-40,0,16)
StatusLabel.Position   = UDim2.new(0,20,0,114)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(140,140,165)
StatusLabel.Font       = Enum.Font.Gotham
StatusLabel.TextSize   = 12
StatusLabel.ZIndex     = 11
StatusLabel.Parent     = Card

-- Progress bar track
local BarTrack = Instance.new("Frame")
BarTrack.Size             = UDim2.new(1,-40,0,4)
BarTrack.Position         = UDim2.new(0,20,0,138)
BarTrack.BackgroundColor3 = Color3.fromRGB(32,32,42)
BarTrack.BorderSizePixel  = 0
BarTrack.ZIndex           = 11
BarTrack.Parent           = Card
Instance.new("UICorner",BarTrack).CornerRadius = UDim.new(1,0)

local BarFill = Instance.new("Frame")
BarFill.Size             = UDim2.new(0,0,1,0)
BarFill.BackgroundColor3 = Color3.fromRGB(99,102,241)
BarFill.BorderSizePixel  = 0
BarFill.ZIndex           = 12
BarFill.Parent           = BarTrack
Instance.new("UICorner",BarFill).CornerRadius = UDim.new(1,0)

-- HWID fingerprint display
local HwidLabel = Instance.new("TextLabel")
HwidLabel.Text       = "ID: " .. HWID:sub(1,8) .. "…"
HwidLabel.Size       = UDim2.new(1,-40,0,14)
HwidLabel.Position   = UDim2.new(0,20,0,154)
HwidLabel.BackgroundTransparency = 1
HwidLabel.TextColor3 = Color3.fromRGB(70,70,95)
HwidLabel.Font       = Enum.Font.Code
HwidLabel.TextSize   = 10
HwidLabel.ZIndex     = 11
HwidLabel.Parent     = Card

-- Version / build
local VerLabel = Instance.new("TextLabel")
VerLabel.Text       = "v3.0.0  ·  Secure"
VerLabel.Size       = UDim2.new(1,-40,0,14)
VerLabel.Position   = UDim2.new(0,20,0,172)
VerLabel.BackgroundTransparency = 1
VerLabel.TextColor3 = Color3.fromRGB(55,55,75)
VerLabel.Font       = Enum.Font.Gotham
VerLabel.TextSize   = 10
VerLabel.ZIndex     = 11
VerLabel.Parent     = Card

-- Retry button (hidden by default)
local RetryBtn = Instance.new("TextButton")
RetryBtn.Text            = "⟳  Retry"
RetryBtn.Size            = UDim2.new(0,100,0,32)
RetryBtn.Position        = UDim2.new(0.5,-50,1,-46)
RetryBtn.BackgroundColor3= Color3.fromRGB(99,102,241)
RetryBtn.TextColor3      = Color3.fromRGB(255,255,255)
RetryBtn.Font            = Enum.Font.GothamSemibold
RetryBtn.TextSize        = 13
RetryBtn.Visible         = false
RetryBtn.ZIndex          = 12
RetryBtn.Parent          = Card
Instance.new("UICorner",RetryBtn).CornerRadius = UDim.new(0,6)

-- ─────────────────────────────────────────────────────────────────────────────
-- ANIMATION HELPERS
-- ─────────────────────────────────────────────────────────────────────────────
local function tw(obj, props, dur, style, dir)
    local ti = TweenInfo.new(
        dur   or 0.22,
        style or Enum.EasingStyle.Quint,
        dir   or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, ti, props)
    t:Play()
    return t
end

local function setStatus(msg)
    tw(StatusLabel, { TextColor3 = Color3.fromRGB(140,140,165) }, 0.1)
    task.delay(0.12, function()
        StatusLabel.Text = msg
        tw(StatusLabel, { TextColor3 = Color3.fromRGB(180,180,210) }, 0.15)
    end)
end

local function setProgress(pct, duration)
    tw(BarFill, { Size = UDim2.new(pct,0,1,0) }, duration or 0.35)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- OPEN ANIMATION
-- ─────────────────────────────────────────────────────────────────────────────
local function playOpenAnim()
    -- Card fade + slide up
    Card.Position = UDim2.new(0.5,-180,0.5,-90)
    Card.BackgroundTransparency = 1
    tw(Card, { BackgroundTransparency = 0, Position = UDim2.new(0.5,-180,0.5,-110) }, 0.5,
        Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    -- Glow bar sweep
    task.delay(0.3, function()
        tw(GlowBar, { Size = UDim2.new(1,0,0,2) }, 0.6, Enum.EasingStyle.Sine)
    end)

    -- Lock icon pulse
    task.spawn(function()
        while true do
            task.wait(1.6)
            tw(LockFrame, { BackgroundColor3 = Color3.fromRGB(40,40,65) }, 0.4)
            task.wait(0.45)
            tw(LockFrame, { BackgroundColor3 = Color3.fromRGB(24,24,32) }, 0.6)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- STATUS SCREENS
-- ─────────────────────────────────────────────────────────────────────────────
local function showBlacklistedScreen(reason)
    CardStroke.Color     = Color3.fromRGB(220,50,50)
    LockIcon.Text        = "🚫"
    AppName.Text         = "Access Denied"
    AppName.TextColor3   = Color3.fromRGB(239,68,68)
    StatusLabel.Text     = reason or "Your device has been blocked."
    StatusLabel.TextColor3 = Color3.fromRGB(239,68,68)
    BarFill.BackgroundColor3 = Color3.fromRGB(239,68,68)
    setProgress(1)
    tw(GlowBar, { BackgroundColor3 = Color3.fromRGB(239,68,68) }, 0.3)
    HwidLabel.Text       = "HWID: " .. HWID

    task.delay(3, function()
        LP:Kick("🚫 Device blacklisted. Contact support.")
    end)
end

local function showExpiredScreen()
    CardStroke.Color   = Color3.fromRGB(234,179,8)
    LockIcon.Text      = "⏰"
    AppName.Text       = "License Expired"
    AppName.TextColor3 = Color3.fromRGB(234,179,8)
    StatusLabel.Text   = "Your license has expired. Please renew."
    StatusLabel.TextColor3 = Color3.fromRGB(234,179,8)
    tw(GlowBar, { BackgroundColor3 = Color3.fromRGB(234,179,8) }, 0.3)
end

local function showNotFoundScreen()
    CardStroke.Color   = Color3.fromRGB(100,100,130)
    LockIcon.Text      = "❓"
    AppName.Text       = "License Not Found"
    AppName.TextColor3 = Color3.fromRGB(200,200,220)
    StatusLabel.Text   = "No license found for this device."
    tw(GlowBar, { BackgroundColor3 = Color3.fromRGB(100,100,130) }, 0.3)
end

local function showSuccessAndClose(callback)
    CardStroke.Color   = Color3.fromRGB(34,197,94)
    LockIcon.Text      = "✓"
    AppName.TextColor3 = Color3.fromRGB(34,197,94)
    setStatus("Access granted.")
    tw(GlowBar, { BackgroundColor3 = Color3.fromRGB(34,197,94) }, 0.3)
    setProgress(1, 0.3)

    task.delay(0.8, function()
        -- Exit animation
        tw(Card,    { BackgroundTransparency = 1, Position = UDim2.new(0.5,-180,0.5,-130) }, 0.4)
        tw(Overlay, { BackgroundTransparency = 1 }, 0.5)
        task.delay(0.55, function()
            ScreenGui:Destroy()
            if callback then callback() end
        end)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- HTTP HELPER
-- ─────────────────────────────────────────────────────────────────────────────
local function httpPost(endpoint, payload)
    local url  = CONFIG.API_URL .. endpoint
    local body = HttpService:JSONEncode(payload)
    local ok, res = pcall(HttpService.RequestAsync, HttpService, {
        Url     = url,
        Method  = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["X-API-Key"]    = CONFIG.API_KEY,
        },
        Body    = body,
    })
    if not ok then return nil, "request_failed" end
    if res.StatusCode == 403 then return nil, "unauthorized" end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not ok2 then return nil, "parse_error" end
    return data, nil
end

local function httpGet(endpoint)
    local url  = CONFIG.API_URL .. endpoint
    local ok, res = pcall(HttpService.RequestAsync, HttpService, {
        Url     = url,
        Method  = "GET",
        Headers = { ["X-API-Key"] = CONFIG.API_KEY },
    })
    if not ok then return nil, "request_failed" end
    if res.StatusCode == 403 then return nil, "unauthorized" end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not ok2 then return nil, "parse_error" end
    return data, nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- VERIFICATION FLOW
-- ─────────────────────────────────────────────────────────────────────────────
local function verify(onSuccess)
    playOpenAnim()
    task.wait(0.5)

    -- Stage 1: fingerprint
    setStatus("Generating secure fingerprint…")
    setProgress(0.18, 0.4)
    task.wait(0.65)

    -- Stage 2: connecting
    setStatus("Connecting to secure server…")
    setProgress(0.42, 0.4)
    task.wait(0.5)

    -- Stage 3: validating
    setStatus("Validating device…")
    setProgress(0.68, 0.3)

    -- API call with retries
    local response, err
    for attempt = 1, CONFIG.RETRY_MAX do
        response, err = httpPost("/check/" .. HWID, {
            username = USERNAME,
            user_id  = USER_ID,
            game_id  = GAME_ID,
            hwid     = HWID,
        })
        if response then break end
        if attempt < CONFIG.RETRY_MAX then
            setStatus("Server error — retrying (" .. attempt .. "/" .. CONFIG.RETRY_MAX .. ")…")
            task.wait(1.5)
        end
    end

    -- Handle response
    if not response then
        -- Server error path
        setStatus("Could not reach server.")
        setProgress(0.68)
        RetryBtn.Visible = true
        RetryBtn.MouseButton1Click:Connect(function()
            RetryBtn.Visible = false
            setProgress(0.42)
            verify(onSuccess)
        end)
        return
    end

    local status = response.status

    if status == "allowed" then
        setProgress(0.88, 0.2)
        task.wait(0.15)
        setStatus("Device verified ✓")
        showSuccessAndClose(function()
            onSuccess(response)
        end)

    elseif status == "blacklisted" then
        setProgress(1, 0.1)
        showBlacklistedScreen(response.reason)

    elseif status == "expired" then
        setProgress(1, 0.2)
        showExpiredScreen()

    elseif status == "maintenance" then
        setStatus("⚙  " .. (response.reason or "Maintenance in progress…"))
        LockIcon.Text = "⚙"
        AppName.Text  = "Maintenance"
        setProgress(1, 0.3)
        tw(GlowBar, { BackgroundColor3 = Color3.fromRGB(234,179,8) }, 0.3)

    elseif status == "ratelimited" then
        local remaining = response.remaining or 60
        setProgress(0.5)
        LockIcon.Text = "⏳"
        -- Live countdown — updates every second, then re-verifies automatically
        task.spawn(function()
            while remaining > 0 do
                setStatus("Rate limited — retrying in " .. remaining .. "s…")
                task.wait(1)
                remaining -= 1
            end
            setStatus("Retrying…")
            setProgress(0.42, 0.3)
            task.wait(0.3)
            verify(onSuccess)
        end)

    else
        showNotFoundScreen()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- BACKGROUND POLLING THREAD
-- Runs every POLL_INTERVAL seconds after successful verification.
-- Handles: blacklist, force_shutdown, run_command, update_config
-- ─────────────────────────────────────────────────────────────────────────────
local function startPolling(UILibRef)
    task.spawn(function()
        while true do
            task.wait(CONFIG.POLL_INTERVAL)

            local data, err = httpGet("/poll/" .. HWID .. "?username=" .. USERNAME)
            if not data then
                -- Silent fail — network hiccup, retry next cycle
                continue
            end

            local pStatus = data.status

            if pStatus == "blacklisted" then
                -- Immediate kick
                LP:Kick("🚫 Access revoked. Contact support.")
                break

            elseif pStatus == "maintenance" then
                -- Show notification then kick the player
                if UILibRef and UILibRef.KickForMaintenance then
                    UILibRef:KickForMaintenance(data.reason or "Script is under maintenance.")
                else
                    task.delay(3, function()
                        LP:Kick("Maintenance: " .. (data.reason or "Check back later."))
                    end)
                end
                break

            elseif pStatus == "force_shutdown" then
                if UILibRef and UILibRef._root then
                    UILibRef._root:Destroy()
                end
                break

            elseif pStatus == "run_command" then
                -- Execute Lua command relayed from Discord bot
                -- SECURITY: only trusted commands from verified API
                local cmd = data.command
                if cmd and type(cmd) == "string" and #cmd < 2000 then
                    local fn, loadErr = loadstring(cmd)
                    if fn then
                        local ok2, runErr = pcall(fn)
                        if not ok2 then
                            warn("[UILib Poll] Command error:", runErr)
                        end
                    else
                        warn("[UILib Poll] Load error:", loadErr)
                    end
                end

            elseif pStatus == "update_config" then
                -- Merge new config values from API
                if UILibRef and data.config and type(data.config) == "table" then
                    for k, v in pairs(data.config) do
                        UILibRef:SetConfig(k, v)
                    end
                    if UILibRef.Notify then
                        UILibRef:Notify({
                            title   = "Config Updated",
                            message = "Settings synchronized from server.",
                            type    = "info",
                        })
                    end
                end
            end

            -- Update announcement if present (dedup handled inside NotifyAnnouncement)
            if data.message and data.message ~= "" and UILibRef and UILibRef.NotifyAnnouncement then
                UILibRef:NotifyAnnouncement(data.message)
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- PUBLIC API
-- ─────────────────────────────────────────────────────────────────────────────
local Loader = {}

---@param callback fun(apiResponse: table)  Called after successful verification with API data
function Loader:Start(callback)
    verify(function(response)
        callback(response)
    end)
end

---@param UILibRef table  Pass your UILib instance to enable polling integration
function Loader:StartPolling(UILibRef)
    startPolling(UILibRef)
end

---@return string HWID
function Loader:GetHWID()
    return HWID
end

return Loader

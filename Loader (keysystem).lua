-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║                        SECURE HWID LOADER v2.0                          ║
-- ║                   Production-Ready Key System Loader                     ║
-- ║           All validation is server-side. No trust on client.            ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 1 ── CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════
-- Only values in this block should ever need to be changed.

local CFG = {
    -- ── API ───────────────────────────────────────────────────────────────
    API_BASE    = "https://hwid-drz0.onrender.com",   -- no trailing slash
    API_KEY     = "FUCKNIGGERS",                -- X-API-Key header

    -- ── Key site ──────────────────────────────────────────────────────────
    -- Users are sent here first. Your site runs bot-check → Linkvertise →
    -- calls /key/generate on the backend, then shows a confirmation page.
    SITE_URL    = "https://yoursite.com",

    -- ── Local cache file ──────────────────────────────────────────────────
    -- Stored on the executor's local disk so the user is not prompted every
    -- single session. Backend always re-validates — we never trust this alone.
    CACHE_FILE  = "loader_cache.json",

    -- ── Polling ───────────────────────────────────────────────────────────
    -- How often (seconds) the loader polls /key/validate while waiting for
    -- the user to complete the Linkvertise flow in their browser.
    POLL_INTERVAL   = 4,    -- seconds between each poll
    POLL_TIMEOUT    = 300,  -- give up after 5 minutes (300 s)

    -- ── Rate limit retry ──────────────────────────────────────────────────
    RATELIMIT_WAIT  = 65,   -- seconds to wait when server says ratelimited

    -- ── Script to load after auth ─────────────────────────────────────────
    -- Replace with a raw URL to your protected main script.
    PROTECTED_URL   = "https://raw.githubusercontent.com/BullShifter9/Aintnowwayiliketrevor/refs/heads/main/keysystem%20mm2.lua",
}

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 2 ── SERVICE REFERENCES  (cached once — avoids repeated indexing)
-- ════════════════════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 3 ── INTEGRITY  (basic anti-tamper surface check)
-- ════════════════════════════════════════════════════════════════════════════
-- We verify that critical services still exist and haven't been redirected
-- by a hook or wrapper. A tampered executor often replaces HttpService with
-- a spy table; checking its ClassName catches most naive attempts.

local function _integrityCheck()
    local ok = true
    if typeof(HttpService)      ~= "Instance" then ok = false end
    if typeof(UserInputService) ~= "Instance" then ok = false end
    if HttpService.ClassName    ~= "HttpService"      then ok = false end
    if UserInputService.ClassName ~= "UserInputService" then ok = false end
    -- Ensure we are in the correct game context (not a spoofed Studio run)
    if RunService:IsServer() then ok = false end
    return ok
end

if not _integrityCheck() then
    error("[Loader] Integrity check failed. Possible tampered environment.", 0)
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 4 ── HWID GENERATION
-- ════════════════════════════════════════════════════════════════════════════
-- Priority: Synapse X → Krnl → Fluxus/Wave → hardware fingerprint.
-- The fingerprint is built from display + input + render signals — all of
-- which are hardware-bound and do NOT change when the Roblox account changes.
-- The same device will always produce the same HWID regardless of who is
-- logged in, which is the core of the account-switch bypass prevention.

local function generateHWID()
    -- ── Tier 1: executor-native HWID (most reliable) ─────────────────────
    if syn and type(syn.get_hwid) == "function" then
        local ok, id = pcall(syn.get_hwid)
        if ok and id and tostring(id) ~= "" then
            return ("SYN_" .. tostring(id)):upper()
        end
    end

    if KRNL_LOADED and type(getHWID) == "function" then
        local ok, id = pcall(getHWID)
        if ok and id and tostring(id) ~= "" then
            return ("KRN_" .. tostring(id)):upper()
        end
    end

    if type(fluxus) == "table" and type(fluxus.get_hwid) == "function" then
        local ok, id = pcall(fluxus.get_hwid)
        if ok and id and tostring(id) ~= "" then
            return ("FLX_" .. tostring(id)):upper()
        end
    end

    -- ── Tier 2: hardware fingerprint ──────────────────────────────────────
    -- Collects several hardware-bound signals and mixes them with djb2.
    -- Signals chosen because they reflect the physical device, not the user.

    local signals = {}

    -- Display resolution — set by the GPU/display, not the account
    local ok1, vp = pcall(function()
        local v = workspace.CurrentCamera.ViewportSize
        return string.format("%dx%d", math.floor(v.X), math.floor(v.Y))
    end)
    signals[#signals + 1] = ok1 and vp or "NO_VP"

    -- Input device profile — keyboard/mouse vs mobile touchscreen vs VR
    local ok2, inp = pcall(function()
        return tostring(UserInputService.TouchEnabled)
            .. tostring(UserInputService.KeyboardEnabled)
            .. tostring(UserInputService.MouseEnabled)
            .. tostring(UserInputService.GamepadEnabled)
            .. tostring(UserInputService.VREnabled)
    end)
    signals[#signals + 1] = ok2 and inp or "NO_INP"

    -- Rendering quality level — GPU capability indicator
    local ok3, rq = pcall(function()
        return tostring(settings().Rendering.QualityLevel)
    end)
    signals[#signals + 1] = ok3 and rq or "NO_RQ"

    -- Streaming enabled — reflects game/engine config on this client
    local ok4, se = pcall(function()
        return tostring(workspace.StreamingEnabled)
    end)
    signals[#signals + 1] = ok4 and se or "NO_SE"

    -- Platform detection (additional input layer)
    local ok5, plat = pcall(function()
        return tostring(UserInputService:GetPlatform())
    end)
    signals[#signals + 1] = ok5 and plat or "NO_PLAT"

    local raw = table.concat(signals, "|")

    -- djb2 hash (better distribution than naive polynomial)
    local h = 5381
    for i = 1, #raw do
        h = ((h * 33) + string.byte(raw, i)) % 4294967295
    end

    -- Second pass for avalanche effect (reduces collision probability)
    local raw2 = string.format("%s|PASS2|%d", raw, h)
    local h2   = 5381
    for i = 1, #raw2 do
        h2 = ((h2 * 33) + string.byte(raw2, i)) % 4294967295
    end

    return string.format("DEV_%08X%08X", h, h2):upper()
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 5 ── HTTP UTILITIES
-- ════════════════════════════════════════════════════════════════════════════
-- Detects the correct http_request function for the running executor once,
-- then caches it. Falls back to game:HttpGet for GET-only calls.

local _httpFn = nil

local function _detectHttpFn()
    if type(http_request)  == "function"                             then return http_request  end
    if type(request)        == "function"                            then return request       end
    if syn  and type(syn.request)  == "function"                     then return syn.request  end
    if http and type(http.request) == "function"                     then return http.request  end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
    if type(KRNL_LOADED) ~= "nil" and type(request) == "function"   then return request       end
    return nil
end

local function _rawRequest(method, url, body)
    if not _httpFn then _httpFn = _detectHttpFn() end

    local headers = {
        ["X-API-Key"]    = CFG.API_KEY,
        ["Content-Type"] = "application/json",
        ["User-Agent"]   = "SecureLoader/2.0",
    }

    if _httpFn then
        local payload = {
            Url     = url,
            Method  = method,
            Headers = headers,
        }
        if body then
            payload.Body = HttpService:JSONEncode(body)
        end
        local ok, res = pcall(_httpFn, payload)
        if ok and res and type(res.Body) == "string" and #res.Body > 0 then
            return res.StatusCode or 200, res.Body
        end
    end

    -- GET fallback — game:HttpGet ignores headers (no api-key) but still
    -- useful for polling endpoints on executors with no http_request
    if method == "GET" then
        local ok2, body2 = pcall(function() return game:HttpGet(url, true) end)
        if ok2 and type(body2) == "string" and #body2 > 0 then
            return 200, body2
        end
    end

    return 0, nil -- total failure
end

-- Thin wrappers — always return (success: bool, data: table|nil, rawBody: string|nil)
local function apiGet(endpoint)
    local code, raw = _rawRequest("GET", CFG.API_BASE .. endpoint)
    if not raw then return false, nil, nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    return ok and data ~= nil, ok and data or nil, raw
end

local function apiPost(endpoint, body)
    local code, raw = _rawRequest("POST", CFG.API_BASE .. endpoint, body)
    if not raw then return false, nil, nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    return ok and data ~= nil, ok and data or nil, raw
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 6 ── LOCAL KEY CACHE  (disk — executor writefile/readfile)
-- ════════════════════════════════════════════════════════════════════════════
-- Caches the HWID and expiration locally so returning users skip the
-- Linkvertise step if their key is still valid. Backend ALWAYS re-validates —
-- the local cache only prevents unnecessary UI interruption.

local function storeKey(hwid, expiresAt)
    -- expiresAt is an ISO-8601 string (from the API)
    if type(writefile) ~= "function" then return end
    local payload = HttpService:JSONEncode({
        hwid       = hwid,
        expires_at = expiresAt,
        stored_at  = os.time(),
    })
    pcall(writefile, CFG.CACHE_FILE, payload)
end

local function loadCachedKey()
    -- Returns {hwid, expires_at} or nil
    if type(readfile) ~= "function" then return nil end
    local ok, raw = pcall(readfile, CFG.CACHE_FILE)
    if not ok or not raw or raw == "" then return nil end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or type(data) ~= "table" then return nil end
    return data
end

local function clearCachedKey()
    if type(delfile) == "function" then
        pcall(delfile, CFG.CACHE_FILE)
    elseif type(writefile) == "function" then
        pcall(writefile, CFG.CACHE_FILE, "{}")
    end
end

-- ── isExpired ────────────────────────────────────────────────────────────
-- Parses an ISO-8601 datetime string and compares against current UTC time.
-- We only use this as a pre-check to avoid an unnecessary API round-trip.
-- The backend is the authoritative source — we always confirm server-side.

local function parseISOTimestamp(iso)
    -- Format: YYYY-MM-DDTHH:MM:SS[.ffffff]
    if type(iso) ~= "string" then return nil end
    local Y, M, D, h, m, s = iso:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    if not Y then return nil end
    -- Approximate UTC epoch — accurate enough for a 24-hour key check
    local days  = (tonumber(Y) - 1970) * 365
              + math.floor((tonumber(Y) - 1969) / 4)   -- leap years
              + (({0,31,59,90,120,151,181,212,243,273,304,334})[tonumber(M)] or 0)
              + tonumber(D) - 1
    return days * 86400
         + tonumber(h) * 3600
         + tonumber(m) * 60
         + tonumber(s)
end

local function isExpired(expiresAt)
    local exp = parseISOTimestamp(expiresAt)
    if not exp then return true end   -- unparseable → treat as expired
    return os.time() >= exp           -- conservative: expired on-the-dot counts
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 7 ── UI SYSTEM
-- ════════════════════════════════════════════════════════════════════════════
-- Minimal, clean loader UI. Appears only when user interaction is needed.
-- All other states are handled silently in the background.

local _GUI = nil  -- reference kept so we can destroy/update it

local function _safeParentGui(gui)
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10)
    end
end

-- Colour palette
local CLRS = {
    bg       = Color3.fromRGB(10,  11,  16),
    card     = Color3.fromRGB(15,  16,  24),
    border   = Color3.fromRGB(30,  32,  48),
    accent   = Color3.fromRGB(88,  101, 242),  -- Discord blurple
    accentHv = Color3.fromRGB(108, 121, 255),
    success  = Color3.fromRGB(59,  165, 93),
    warning  = Color3.fromRGB(250, 166, 26),
    error    = Color3.fromRGB(237, 66,  69),
    text     = Color3.fromRGB(220, 222, 230),
    muted    = Color3.fromRGB(130, 133, 155),
    white    = Color3.fromRGB(255, 255, 255),
}

local function _makeCorner(r, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = parent
    return c
end

local function _makeStroke(color, thickness, parent)
    local s = Instance.new("UIStroke")
    s.Color     = color
    s.Thickness = thickness
    s.Parent    = parent
    return s
end

local function _label(props, parent)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font        = props.font     or Enum.Font.GothamBold
    l.TextSize    = props.size     or 14
    l.TextColor3  = props.color    or CLRS.text
    l.Text        = props.text     or ""
    l.Size        = props.sz       or UDim2.new(1, 0, 0, 20)
    l.Position    = props.pos      or UDim2.new(0, 0, 0, 0)
    l.TextXAlignment = props.align or Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.ZIndex      = props.z        or 4
    l.RichText    = props.rich     or false
    l.Parent      = parent
    return l
end

local function _button(props, parent)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Font        = props.font  or Enum.Font.GothamBold
    b.TextSize    = props.size  or 14
    b.TextColor3  = props.textC or CLRS.white
    b.Text        = props.text  or "Button"
    b.Size        = props.sz    or UDim2.new(1, 0, 0, 42)
    b.Position    = props.pos   or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3 = props.bg or CLRS.accent
    b.ZIndex      = props.z     or 4
    b.Active      = true
    _makeCorner(props.r or 9, b)
    b.Parent = parent

    local baseColor = b.BackgroundColor3
    local hvColor   = props.bgHv or CLRS.accentHv
    b.MouseEnter:Connect(function()  if b.Active then b.BackgroundColor3 = hvColor   end end)
    b.MouseLeave:Connect(function()  if b.Active then b.BackgroundColor3 = baseColor end end)

    return b
end

-- ── createLoaderUI ────────────────────────────────────────────────────────
-- Builds the main loader card. Returns a table of references to update live.

local function createLoaderUI()
    if _GUI then pcall(function() _GUI:Destroy() end) end

    local sg = Instance.new("ScreenGui")
    sg.Name           = "_SecureLoader"
    sg.ResetOnSpawn   = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 99999

    -- Dark overlay
    local overlay = Instance.new("Frame")
    overlay.Size                   = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel        = 0
    overlay.ZIndex                 = 2
    overlay.Parent                 = sg

    -- Card frame
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0, 440, 0, 0)  -- height driven by content
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.Position         = UDim2.new(0.5, -220, 0.5, -100)
    card.BackgroundColor3 = CLRS.card
    card.BorderSizePixel  = 0
    card.ZIndex           = 3
    card.ClipsDescendants = false
    _makeCorner(16, card)
    _makeStroke(CLRS.border, 1.5, card)
    card.Parent = overlay

    -- Accent top bar (gradient)
    local accentBar = Instance.new("Frame")
    accentBar.Size             = UDim2.new(1, 0, 0, 4)
    accentBar.Position         = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = CLRS.accent
    accentBar.BorderSizePixel  = 0
    accentBar.ZIndex           = 5
    _makeCorner(16, accentBar)
    accentBar.Parent = card

    -- Content padding frame
    local content = Instance.new("Frame")
    content.Size              = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize     = Enum.AutomaticSize.Y
    content.Position          = UDim2.new(0, 0, 0, 4)
    content.BackgroundTransparency = 1
    content.ZIndex            = 4
    content.Parent            = card

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft   = UDim.new(0, 22)
    padding.PaddingRight  = UDim.new(0, 22)
    padding.PaddingTop    = UDim.new(0, 22)
    padding.PaddingBottom = UDim.new(0, 22)
    padding.Parent        = content

    local layout = Instance.new("UIListLayout")
    layout.SortOrder    = Enum.SortOrder.LayoutOrder
    layout.Padding      = UDim.new(0, 12)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Parent       = content

    -- ── Header row (icon + title + subtitle) ─────────────────────────────
    local headerFrame = Instance.new("Frame")
    headerFrame.Size              = UDim2.new(1, 0, 0, 52)
    headerFrame.BackgroundTransparency = 1
    headerFrame.LayoutOrder       = 1
    headerFrame.ZIndex            = 4
    headerFrame.Parent            = content

    local icon = _label({
        text  = "🔐",
        size  = 28,
        sz    = UDim2.new(0, 36, 0, 52),
        pos   = UDim2.new(0, 0, 0, 0),
        align = Enum.TextXAlignment.Left,
        z     = 4,
    }, headerFrame)

    _label({
        text  = "Secure Loader",
        size  = 18,
        color = CLRS.white,
        sz    = UDim2.new(1, -44, 0, 26),
        pos   = UDim2.new(0, 44, 0, 2),
        align = Enum.TextXAlignment.Left,
        z     = 4,
    }, headerFrame)

    local subtitleLbl = _label({
        text  = "Initializing…",
        size  = 12,
        color = CLRS.muted,
        sz    = UDim2.new(1, -44, 0, 18),
        pos   = UDim2.new(0, 44, 0, 30),
        align = Enum.TextXAlignment.Left,
        font  = Enum.Font.Gotham,
        z     = 4,
    }, headerFrame)

    -- ── Divider ───────────────────────────────────────────────────────────
    local div = Instance.new("Frame")
    div.Size             = UDim2.new(1, 0, 0, 1)
    div.BackgroundColor3 = CLRS.border
    div.BorderSizePixel  = 0
    div.LayoutOrder      = 2
    div.ZIndex           = 4
    div.Parent           = content

    -- ── Status row ────────────────────────────────────────────────────────
    local statusFrame = Instance.new("Frame")
    statusFrame.Size              = UDim2.new(1, 0, 0, 0)
    statusFrame.AutomaticSize     = Enum.AutomaticSize.Y
    statusFrame.BackgroundColor3  = Color3.fromRGB(18, 19, 30)
    statusFrame.BorderSizePixel   = 0
    statusFrame.LayoutOrder       = 3
    statusFrame.ZIndex            = 4
    _makeCorner(10, statusFrame)
    statusFrame.Parent = content

    local sPad = Instance.new("UIPadding")
    sPad.PaddingLeft   = UDim.new(0, 14)
    sPad.PaddingRight  = UDim.new(0, 14)
    sPad.PaddingTop    = UDim.new(0, 12)
    sPad.PaddingBottom = UDim.new(0, 12)
    sPad.Parent        = statusFrame

    local statusIconLbl = _label({
        text  = "⏳",
        size  = 18,
        sz    = UDim2.new(0, 24, 0, 24),
        pos   = UDim2.new(0, 0, 0, 0),
        z     = 4,
    }, statusFrame)

    local statusTextLbl = _label({
        text  = "Checking HWID…",
        size  = 13,
        color = CLRS.text,
        sz    = UDim2.new(1, -32, 0, 24),
        pos   = UDim2.new(0, 32, 0, 0),
        font  = Enum.Font.Gotham,
        z     = 4,
    }, statusFrame)

    -- ── Progress bar ──────────────────────────────────────────────────────
    local progressTrack = Instance.new("Frame")
    progressTrack.Size             = UDim2.new(1, 0, 0, 5)
    progressTrack.BackgroundColor3 = CLRS.border
    progressTrack.BorderSizePixel  = 0
    progressTrack.LayoutOrder      = 4
    progressTrack.ZIndex           = 4
    _makeCorner(4, progressTrack)
    progressTrack.Parent = content

    local progressFill = Instance.new("Frame")
    progressFill.Size             = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = CLRS.accent
    progressFill.BorderSizePixel  = 0
    progressFill.ZIndex           = 5
    _makeCorner(4, progressFill)
    progressFill.Parent = progressTrack

    -- ── Key link frame (hidden until needed) ─────────────────────────────
    local linkFrame = Instance.new("Frame")
    linkFrame.Size              = UDim2.new(1, 0, 0, 0)
    linkFrame.AutomaticSize     = Enum.AutomaticSize.Y
    linkFrame.BackgroundTransparency = 1
    linkFrame.LayoutOrder       = 5
    linkFrame.Visible           = false
    linkFrame.ZIndex            = 4
    linkFrame.Parent            = content

    local lfLayout = Instance.new("UIListLayout")
    lfLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    lfLayout.Padding       = UDim.new(0, 8)
    lfLayout.FillDirection = Enum.FillDirection.Vertical
    lfLayout.Parent        = linkFrame

    local linkInfoLbl = _label({
        text  = "📋  Your key link has been opened in your browser.\nComplete the Linkvertise steps, then return — the loader will detect your key automatically.",
        size  = 12,
        color = CLRS.muted,
        sz    = UDim2.new(1, 0, 0, 48),
        font  = Enum.Font.Gotham,
        z     = 4,
        rich  = false,
        LayoutOrder = 1,
    }, linkFrame)

    -- HWID display chip
    local hwidFrame = Instance.new("Frame")
    hwidFrame.Size             = UDim2.new(1, 0, 0, 34)
    hwidFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 30)
    hwidFrame.BorderSizePixel  = 0
    hwidFrame.LayoutOrder      = 2
    hwidFrame.ZIndex           = 4
    _makeCorner(8, hwidFrame)
    _makeStroke(CLRS.border, 1, hwidFrame)
    hwidFrame.Parent = linkFrame

    local hwidPad = Instance.new("UIPadding")
    hwidPad.PaddingLeft  = UDim.new(0, 10)
    hwidPad.PaddingRight = UDim.new(0, 10)
    hwidPad.Parent       = hwidFrame

    local hwidLbl = _label({
        text  = "HWID: …",
        size  = 11,
        color = CLRS.muted,
        sz    = UDim2.new(1, 0, 1, 0),
        font  = Enum.Font.GothamMono,
        z     = 5,
    }, hwidFrame)

    -- Copy link button
    local copyBtn = _button({
        text  = "🔗  Copy Key Link",
        sz    = UDim2.new(1, 0, 0, 40),
        bg    = Color3.fromRGB(24, 25, 40),
        bgHv  = Color3.fromRGB(32, 33, 56),
        textC = CLRS.accent,
        size  = 13,
        z     = 4,
        LayoutOrder = 3,
    }, linkFrame)
    _makeStroke(CLRS.accent, 1, copyBtn)

    -- Poll status label
    local pollLbl = _label({
        text  = "⏳  Waiting for key activation…  (0 / 300 s)",
        size  = 11,
        color = CLRS.muted,
        sz    = UDim2.new(1, 0, 0, 18),
        font  = Enum.Font.GothamMono,
        z     = 4,
        LayoutOrder = 4,
    }, linkFrame)

    -- ── Footer ────────────────────────────────────────────────────────────
    local footerLbl = _label({
        text  = "Secure Loader v2.0  •  All validation is server-side.",
        size  = 10,
        color = Color3.fromRGB(60, 62, 80),
        sz    = UDim2.new(1, 0, 0, 16),
        font  = Enum.Font.Gotham,
        align = Enum.TextXAlignment.Center,
        z     = 4,
        LayoutOrder = 6,
    }, content)

    _safeParentGui(sg)
    _GUI = sg

    -- ── Public interface returned to callers ──────────────────────────────
    return {
        gui         = sg,
        subtitle    = subtitleLbl,
        statusIcon  = statusIconLbl,
        statusText  = statusTextLbl,
        fill        = progressFill,
        linkFrame   = linkFrame,
        hwidLbl     = hwidLbl,
        copyBtn     = copyBtn,
        pollLbl     = pollLbl,
    }
end

-- ── UI helper: smooth progress bar ───────────────────────────────────────
local function setProgress(ui, pct, color)
    if not ui or not ui.fill then return end
    pct = math.clamp(pct, 0, 1)
    ui.fill.Size             = UDim2.new(pct, 0, 1, 0)
    ui.fill.BackgroundColor3 = color or CLRS.accent
end

-- ── UI helper: set status row ─────────────────────────────────────────────
local function setStatus(ui, icon, text, color)
    if not ui then return end
    ui.statusIcon.Text  = icon or "⏳"
    ui.statusText.Text  = text or ""
    ui.statusText.TextColor3 = color or CLRS.text
end

-- ── UI helper: update subtitle ────────────────────────────────────────────
local function setSubtitle(ui, text)
    if ui and ui.subtitle then ui.subtitle.Text = text end
end

-- ── destroyUI ────────────────────────────────────────────────────────────
local function destroyUI()
    if _GUI then
        pcall(function() _GUI:Destroy() end)
        _GUI = nil
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 8 ── KEY VALIDATION  (server-round-trip)
-- ════════════════════════════════════════════════════════════════════════════

-- validateKey: asks the backend whether this HWID currently has an active,
-- unexpired key. Returns a standardised result table:
--   { ok=bool, status=string, expiresAt=string|nil, remainingSec=number|nil }

local function validateKey(hwid)
    local ok, data = apiGet("/key/validate/" .. hwid)
    if not ok or not data then
        return { ok = false, status = "network_error" }
    end

    if data.valid then
        return {
            ok           = true,
            status       = "valid",
            expiresAt    = data.expires_at,
            remainingSec = data.remaining_seconds,
        }
    end

    return {
        ok     = false,
        status = data.reason or "no_key",
        keyUrl = data.key_url,
    }
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 9 ── HWID AUTH  (blacklist / maintenance / rate-limit check)
-- ════════════════════════════════════════════════════════════════════════════
-- Separate from key validation — the HWID check handles admin bans,
-- maintenance mode, and per-device rate limiting.

local function checkHWIDAuth(hwid, username)
    local ok, data = apiGet(
        "/check/" .. hwid
        .. "?username=" .. HttpService:UrlEncode(username)
    )
    if not ok or not data then
        return { ok = false, status = "network_error" }
    end

    local s = data.status or "error"
    if s == "allowed" then
        return { ok = true, status = "allowed", announcement = data.announcement }
    elseif s == "blacklisted" then
        return { ok = false, status = "blacklisted", reason = data.reason }
    elseif s == "maintenance" then
        return { ok = false, status = "maintenance", reason = data.reason, endTime = data.end_time }
    elseif s == "ratelimited" then
        return { ok = false, status = "ratelimited", remaining = data.remaining }
    else
        return { ok = false, status = s, reason = data.reason }
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 10 ── KEY REQUEST  (Linkvertise → poll loop)
-- ════════════════════════════════════════════════════════════════════════════
-- requestKey opens the key site in the user's browser, then polls the
-- backend every POLL_INTERVAL seconds until:
--   a) /key/validate returns valid=true  (user completed Linkvertise)
--   b) POLL_TIMEOUT seconds elapse      (user gave up / timed out)
-- Returns true if a key was acquired, false otherwise.

local function requestKey(hwid, ui)
    local keyUrl = CFG.SITE_URL .. "/getkey?hwid=" .. hwid

    -- Show link UI
    if ui then
        ui.linkFrame.Visible = true
        ui.hwidLbl.Text      = "HWID: " .. hwid
        setSubtitle(ui, "Complete Linkvertise to get your key")
        setStatus(ui, "🌐", "Waiting for key activation in your browser…", CLRS.warning)
        setProgress(ui, 0.33, CLRS.warning)

        -- Wire up copy button
        ui.copyBtn.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(keyUrl) end)
            local prev = ui.copyBtn.Text
            ui.copyBtn.Text = "✅  Copied!"
            task.delay(2.5, function()
                if ui.copyBtn and ui.copyBtn.Parent then
                    ui.copyBtn.Text = prev
                end
            end)
        end)
    end

    -- Try to open the browser
    local openOk = false
    if type(syn) == "table" and type(syn.open_url_in_browser) == "function" then
        openOk = pcall(syn.open_url_in_browser, keyUrl)
    end
    if not openOk and type(open_url_in_browser) == "function" then
        openOk = pcall(open_url_in_browser, keyUrl)
    end
    if not openOk then
        -- Fallback: copy to clipboard so user can paste manually
        pcall(function() setclipboard(keyUrl) end)
        if ui then
            setStatus(ui, "📋",
                "Could not auto-open browser. Link copied to clipboard — paste in your browser.",
                CLRS.warning)
        end
    end

    -- ── Poll loop ─────────────────────────────────────────────────────────
    local elapsed = 0
    while elapsed < CFG.POLL_TIMEOUT do
        task.wait(CFG.POLL_INTERVAL)
        elapsed = elapsed + CFG.POLL_INTERVAL

        if ui then
            ui.pollLbl.Text = string.format(
                "⏳  Waiting for key activation…  (%d / %d s)",
                elapsed, CFG.POLL_TIMEOUT
            )
            -- Gentle pulse on progress bar
            local pulse = 0.2 + 0.15 * math.abs(math.sin(elapsed / 8))
            setProgress(ui, pulse, CLRS.warning)
        end

        local result = validateKey(hwid)
        if result.ok then
            -- Key confirmed — cache it locally and return
            storeKey(hwid, result.expiresAt)
            if ui then
                setStatus(ui, "✅", "Key activated successfully!", CLRS.success)
                setProgress(ui, 1, CLRS.success)
                ui.linkFrame.Visible = false
                task.wait(0.8)
            end
            return true
        end
    end

    -- Timed out
    if ui then
        setStatus(ui, "❌",
            "Key request timed out. Restart the script and try again.",
            CLRS.error)
        setProgress(ui, 1, CLRS.error)
    end
    return false
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 11 ── UNLOCK  (load protected script after full auth)
-- ════════════════════════════════════════════════════════════════════════════

local function unlockFeatures(announcement)
    destroyUI()

    -- Display announcement if the server sent one
    if announcement and announcement ~= "" then
        task.spawn(function()
            task.wait(1)
            -- Notify using StarterGui if available, else print
            local ok = pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title    = "📢 Announcement",
                    Text     = announcement,
                    Duration = 10,
                })
            end)
            if not ok then
                print("[Loader] Announcement:", announcement)
            end
        end)
    end

    -- Load protected script
    if CFG.PROTECTED_URL and CFG.PROTECTED_URL ~= "" then
        local res = _fetchRaw and _fetchRaw(CFG.PROTECTED_URL) or nil
        -- If _fetchRaw isn't available yet, use httpGet fallback
        if not res then
            local _, raw = _rawRequest("GET", CFG.PROTECTED_URL)
            if raw and #raw > 20 then
                res = { Body = raw }
            end
        end

        if res and res.Body and #res.Body > 20 then
            local chunk, err = loadstring(res.Body)
            if chunk then
                local runOk, runErr = pcall(chunk)
                if not runOk then
                    warn("[Loader] Protected script runtime error:", runErr)
                end
            else
                warn("[Loader] Failed to compile protected script:", err)
            end
        else
            warn("[Loader] Could not download protected script from:", CFG.PROTECTED_URL)
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 12 ── MAIN BOOT SEQUENCE
-- ════════════════════════════════════════════════════════════════════════════
-- Steps:
--   1. Integrity check (done above at load — script would have errored already)
--   2. Generate HWID
--   3. Build UI
--   4. Check local cache → pre-validate expiry
--   5. Validate with backend:
--        • No local key or locally expired → go to Linkvertise flow
--        • Local key present → confirm with backend
--   6. HWID auth check (blacklist / maintenance / rate limit)
--   7. Launch protected script

task.spawn(function()

    -- ── Step 2: Generate HWID ─────────────────────────────────────────────
    local hwid    = generateHWID()
    local username = tostring(LocalPlayer.Name)

    -- ── Step 3: Build UI ──────────────────────────────────────────────────
    local ui = createLoaderUI()
    setSubtitle(ui, "Generating device fingerprint…")
    setStatus(ui, "🔍", "Identifying device…", CLRS.muted)
    setProgress(ui, 0.08)
    task.wait(0.3)

    -- ── Step 4: Check local cache ─────────────────────────────────────────
    setStatus(ui, "💾", "Checking local key cache…", CLRS.muted)
    setProgress(ui, 0.15)
    task.wait(0.2)

    local cached       = loadCachedKey()
    local locallyValid = false

    if cached and cached.hwid == hwid then
        if cached.expires_at and not isExpired(cached.expires_at) then
            locallyValid = true
            setStatus(ui, "📂", "Cached key found. Verifying with server…", CLRS.muted)
        else
            -- Expired locally — purge cache
            clearCachedKey()
            setStatus(ui, "🗑️", "Cached key expired. Requesting new key…", CLRS.warning)
            setProgress(ui, 0.18, CLRS.warning)
        end
    elseif cached and cached.hwid ~= hwid then
        -- Cache belongs to a different device (or HWID changed) — clear it
        clearCachedKey()
        setStatus(ui, "⚠️", "Device mismatch in cache. Clearing…", CLRS.warning)
        task.wait(0.4)
    end

    setProgress(ui, 0.25)
    task.wait(0.2)

    -- ── Step 5: Backend key validation ────────────────────────────────────
    setSubtitle(ui, "Validating key with server…")
    setStatus(ui, "🔐", "Connecting to key server…", CLRS.muted)
    setProgress(ui, 0.35)

    local keyResult = validateKey(hwid)

    if keyResult.ok then
        -- Valid key confirmed by server
        storeKey(hwid, keyResult.expiresAt)
        local mins = keyResult.remainingSec and math.floor(keyResult.remainingSec / 60) or "?"
        setStatus(ui, "✅",
            string.format("Key valid  •  %s min remaining", mins),
            CLRS.success)
        setProgress(ui, 0.7, CLRS.success)
        task.wait(0.4)

    elseif keyResult.status == "network_error" then
        -- Can't reach server — don't fall back to local trust alone; abort
        setStatus(ui, "❌",
            "Cannot reach the key server. Check your connection and retry.",
            CLRS.error)
        setProgress(ui, 1, CLRS.error)
        setSubtitle(ui, "Connection failed.")
        return  -- abort

    else
        -- No valid key on server → Linkvertise flow
        setProgress(ui, 0.33, CLRS.warning)
        setSubtitle(ui, "No active key found.")

        local acquired = requestKey(hwid, ui)
        if not acquired then
            setSubtitle(ui, "Key acquisition failed.")
            return  -- abort
        end
    end

    -- ── Step 6: HWID Auth (blacklist / maintenance / rate-limit) ──────────
    setSubtitle(ui, "Authenticating device…")
    setStatus(ui, "🛡️", "Running HWID auth check…", CLRS.muted)
    setProgress(ui, 0.80)
    task.wait(0.2)

    local authResult = checkHWIDAuth(hwid, username)

    if not authResult.ok then
        local icon, msg, color

        if authResult.status == "blacklisted" then
            icon  = "🚫"
            msg   = "You are banned: " .. (authResult.reason or "No reason given.")
            color = CLRS.error
            clearCachedKey()

        elseif authResult.status == "maintenance" then
            icon  = "🔧"
            msg   = "Script under maintenance: " .. (authResult.reason or "Please wait.")
            color = CLRS.warning

        elseif authResult.status == "ratelimited" then
            icon  = "⏱️"
            local wait = authResult.remaining or CFG.RATELIMIT_WAIT
            msg   = string.format("Rate limited. Wait %d seconds and re-execute.", wait)
            color = CLRS.warning

        elseif authResult.status == "network_error" then
            icon  = "❌"
            msg   = "Auth server unreachable. Check your connection."
            color = CLRS.error

        else
            icon  = "❌"
            msg   = "Auth failed: " .. (authResult.reason or authResult.status)
            color = CLRS.error
        end

        setStatus(ui, icon, msg, color)
        setProgress(ui, 1, color)
        setSubtitle(ui, "Authentication denied.")
        return  -- abort
    end

    -- ── Step 7: All checks passed → unlock ────────────────────────────────
    setStatus(ui, "✅", "All checks passed. Loading script…", CLRS.success)
    setProgress(ui, 1, CLRS.success)
    setSubtitle(ui, "Welcome, " .. username .. "!")
    task.wait(0.9)

    unlockFeatures(authResult.announcement)

end)

-- ════════════════════════════════════════════════════════════════════════════
-- END OF LOADER
-- Execution continues inside unlockFeatures() → protected script is loaded
-- after all server-side gates are cleared.
-- ════════════════════════════════════════════════════════════════════════════

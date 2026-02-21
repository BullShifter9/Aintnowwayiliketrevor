-- ======================================================================
--   ExtraLib v2.0 — Example Script
--   Execute this to test every element in the library
-- ======================================================================

local ExtraLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/ExtraLib.lua"
))()

local Players   = game:GetService("Players")
local Lighting  = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Window = ExtraLib:CreateWindow({
    Title    = "ExtraBlox Hub",
    Subtitle = "v2.0 — Script Hub",
})

-- ======================================================================
--  TAB 1 — PLAYER
-- ======================================================================

local PlayerTab = Window:CreateTab("Player", "🎮")

PlayerTab:CreateSection("Movement")

local SpeedToggle = PlayerTab:CreateToggle({
    Name     = "Speed Hack",
    Sub      = "Modifies your walk speed",
    Default  = false,
    Callback = function(state)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = state and SpeedSlider:Get() or 16
            end
        end
        Window:Notify({
            Title = "Speed Hack",
            Text  = state and "Speed enabled!" or "Speed reset to default.",
            Type  = state and "success" or "info",
            Icon  = state and "⚡" or "🚶",
        })
    end,
})

local SpeedSlider = PlayerTab:CreateSlider({
    Name     = "Walk Speed",
    Sub      = "Default: 16",
    Min      = 16,
    Max      = 300,
    Default  = 16,
    Color    = Color3.fromRGB(0, 255, 234),
    Callback = function(val)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and SpeedToggle:Get() then
                hum.WalkSpeed = val
            end
        end
    end,
})

local JumpToggle = PlayerTab:CreateToggle({
    Name     = "Jump Hack",
    Default  = false,
    Callback = function(state)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpPower = state and JumpSlider:Get() or 50
            end
        end
    end,
})

local JumpSlider = PlayerTab:CreateSlider({
    Name     = "Jump Power",
    Min      = 50,
    Max      = 600,
    Default  = 50,
    Color    = Color3.fromRGB(157, 0, 255),
    Callback = function(val)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and JumpToggle:Get() then
                hum.JumpPower = val
            end
        end
    end,
})

PlayerTab:CreateSection("Actions")

PlayerTab:CreateButton({
    Name     = "Teleport to Spawn",
    Sub      = "Moves you to the spawn point",
    Icon     = "🏠",
    Color    = Color3.fromRGB(0, 255, 234),
    Callback = function()
        local char  = LocalPlayer.Character
        local spawn = workspace:FindFirstChild("SpawnLocation")
        if char and spawn then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0) end
        end
        Window:Notify({
            Title = "Teleported",
            Text  = "Moved to spawn location.",
            Type  = "success",
            Icon  = "🏠",
        })
    end,
})

PlayerTab:CreateButton({
    Name     = "Reset Character",
    Sub      = "Kills and respawns your character",
    Icon     = "💀",
    Color    = Color3.fromRGB(255, 55, 90),
    Callback = function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end,
})

PlayerTab:CreateButton({
    Name     = "Fly (Toggle)",
    Icon     = "🕊️",
    Color    = Color3.fromRGB(157, 0, 255),
    Callback = function()
        Window:Notify({
            Title = "Fly",
            Text  = "Add your fly script logic here.",
            Type  = "info",
            Icon  = "🕊️",
        })
    end,
})

PlayerTab:CreateSection("Info")

PlayerTab:CreateLabel("Changes take effect immediately. Some servers may kick for speed hacks.")

-- ======================================================================
--  TAB 2 — VISUAL
-- ======================================================================

local VisualTab = Window:CreateTab("Visual", "🎨")

VisualTab:CreateSection("Rendering")

local FogToggle = VisualTab:CreateToggle({
    Name     = "Remove Fog",
    Default  = false,
    Callback = function(state)
        Lighting.FogEnd   = state and 1e9 or 100000
        Lighting.FogStart = state and 1e9 or 0
    end,
})

local BrightSlider = VisualTab:CreateSlider({
    Name     = "Brightness",
    Min      = 0,
    Max      = 10,
    Default  = 2,
    Decimals = 1,
    Color    = Color3.fromRGB(255, 210, 0),
    Callback = function(val)
        Lighting.Brightness = val
    end,
})

local AmbientPicker = VisualTab:CreateColorPicker({
    Name     = "Ambient Color",
    Default  = Color3.fromRGB(70, 70, 80),
    Callback = function(col)
        Lighting.Ambient = col
    end,
})

VisualTab:CreateSection("Environment")

local TimeDropdown = VisualTab:CreateDropdown({
    Name     = "Time of Day",
    Options  = {"Dawn (6:00)", "Morning (9:00)", "Noon (14:00)", "Sunset (18:00)", "Night (22:00)"},
    Default  = "Noon (14:00)",
    Callback = function(val)
        local times = {
            ["Dawn (6:00)"]    = 6,
            ["Morning (9:00)"] = 9,
            ["Noon (14:00)"]   = 14,
            ["Sunset (18:00)"] = 18,
            ["Night (22:00)"]  = 22,
        }
        if times[val] then
            Lighting.ClockTime = times[val]
        end
        Window:Notify({
            Title = "Time Changed",
            Text  = "Set to "..val,
            Type  = "success",
            Icon  = "🌤️",
        })
    end,
})

local WeatherDropdown = VisualTab:CreateDropdown({
    Name     = "Weather Effects",
    Options  = {"None", "Rain", "Snow", "Storm"},
    Default  = "None",
    Callback = function(val)
        Window:Notify({
            Title = "Weather",
            Text  = "Weather set to: "..val,
            Type  = "info",
        })
    end,
})

VisualTab:CreateSection("Fullbright")

VisualTab:CreateButton({
    Name     = "Enable Fullbright",
    Icon     = "💡",
    Color    = Color3.fromRGB(255, 210, 0),
    Callback = function()
        Lighting.Brightness   = 10
        Lighting.ClockTime    = 14
        Lighting.FogEnd       = 1e9
        Lighting.FogStart     = 1e9
        Lighting.GlobalShadows = false
        Window:Notify({
            Title = "Fullbright",
            Text  = "Fullbright enabled!",
            Type  = "success",
            Icon  = "💡",
        })
    end,
})

VisualTab:CreateButton({
    Name     = "Reset Lighting",
    Icon     = "🔄",
    Callback = function()
        Lighting.Brightness    = 2
        Lighting.ClockTime     = 14
        Lighting.FogEnd        = 100000
        Lighting.FogStart      = 0
        Lighting.GlobalShadows = true
        Window:Notify({
            Title = "Lighting Reset",
            Text  = "Restored to defaults.",
            Type  = "info",
        })
    end,
})

-- ======================================================================
--  TAB 3 — ESP
-- ======================================================================

local EspTab = Window:CreateTab("ESP", "👁️")

EspTab:CreateSection("Player ESP")

local PlayerEsp = EspTab:CreateToggle({
    Name     = "Player ESP",
    Sub      = "Highlight all players",
    Default  = false,
    Callback = function(state)
        Window:Notify({
            Title = "Player ESP",
            Text  = state and "ESP enabled for all players." or "ESP disabled.",
            Type  = state and "success" or "error",
            Icon  = "👁️",
        })
    end,
})

local NameEsp = EspTab:CreateToggle({
    Name     = "Name Tags",
    Default  = false,
    Callback = function(state)
        Window:Notify({
            Title = "Name Tags",
            Text  = state and "Name tags visible." or "Name tags hidden.",
            Type  = state and "success" or "info",
        })
    end,
})

local TeamCheck = EspTab:CreateToggle({
    Name     = "Team Check",
    Sub      = "Skip teammates in ESP",
    Default  = true,
    Callback = function(state)
    end,
})

EspTab:CreateSection("Customization")

local EspColorPicker = EspTab:CreateColorPicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(0, 255, 234),
    Callback = function(col)
        Window:Notify({
            Title = "ESP Color",
            Text  = "Color updated!",
            Type  = "success",
        })
    end,
})

local EspDistSlider = EspTab:CreateSlider({
    Name     = "Max Distance",
    Sub      = "Studs",
    Min      = 50,
    Max      = 2000,
    Default  = 500,
    Color    = Color3.fromRGB(0, 255, 234),
    Callback = function(val)
    end,
})

local EspFilter = EspTab:CreateDropdown({
    Name     = "Filter",
    Options  = {"All Players", "Enemies Only", "Teammates Only"},
    Default  = "All Players",
    Callback = function(val)
        Window:Notify({
            Title = "ESP Filter",
            Text  = "Filtering: "..val,
            Type  = "info",
        })
    end,
})

-- ======================================================================
--  TAB 4 — MISC
-- ======================================================================

local MiscTab = Window:CreateTab("Misc", "⚙️")

MiscTab:CreateSection("Settings")

local HotKeyBind = MiscTab:CreateKeybind({
    Name     = "Toggle UI",
    Default  = Enum.KeyCode.RightShift,
    Callback = function(key)
        Window:Notify({
            Title = "Keybind Set",
            Text  = "UI toggle: "..tostring(key):gsub("Enum.KeyCode.", ""),
            Type  = "success",
            Icon  = "⌨️",
        })
    end,
})

local DisplayInput = MiscTab:CreateInput({
    Name        = "Hub Title",
    Placeholder = "Custom title...",
    Callback    = function(text)
        if text ~= "" then
            Window:Notify({
                Title = "Title Changed",
                Text  = "Set to: "..text,
                Type  = "success",
            })
        end
    end,
})

local MultiDropdown = MiscTab:CreateDropdown({
    Name     = "Tags",
    Options  = {"AFK", "Grinding", "PvP", "Helper", "Scripter"},
    Multi    = true,
    Callback = function(selected)
        Window:Notify({
            Title = "Tags Updated",
            Text  = "Selected: "..#selected.." tags",
            Type  = "info",
        })
    end,
})

MiscTab:CreateSection("Notifications")

MiscTab:CreateButton({
    Name     = "Test Info",
    Icon     = "ℹ️",
    Callback = function()
        Window:Notify({Title = "Info", Text = "This is an info notification.", Type = "info", Icon = "ℹ️"})
    end,
})

MiscTab:CreateButton({
    Name     = "Test Success",
    Icon     = "✅",
    Color    = Color3.fromRGB(0, 220, 110),
    Callback = function()
        Window:Notify({Title = "Success!", Text = "Everything worked perfectly.", Type = "success", Icon = "✅"})
    end,
})

MiscTab:CreateButton({
    Name     = "Test Warning",
    Icon     = "⚠️",
    Color    = Color3.fromRGB(255, 210, 0),
    Callback = function()
        Window:Notify({Title = "Warning", Text = "Proceed with caution.", Type = "warning", Icon = "⚠️"})
    end,
})

MiscTab:CreateButton({
    Name     = "Test Error",
    Icon     = "❌",
    Color    = Color3.fromRGB(255, 55, 90),
    Callback = function()
        Window:Notify({Title = "Error", Text = "Something went wrong!", Type = "error", Icon = "❌"})
    end,
})

MiscTab:CreateSection("About")

MiscTab:CreateLabel("ExtraLib v2.0 by ExtraBlox")
MiscTab:CreateLabel("Smooth animations, sliding tabs, mobile support.")
MiscTab:CreateLabel("All elements: Button, Toggle, Slider, Dropdown,")
MiscTab:CreateLabel("Input, ColorPicker, Keybind, Section, Label.")

-- ======================================================================
--  STARTUP
-- ======================================================================

task.wait(0.9)
Window:Notify({
    Title    = "Welcome!",
    Text     = "ExtraBlox Hub v2.0 loaded.",
    Type     = "success",
    Icon     = "🚀",
    Duration = 4,
})

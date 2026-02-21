local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/BullShifter9/Aintnowwayiliketrevor/refs/heads/main/OverdriveUI.lua"))()

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

--[[
    ModernUI Library
    A feature-rich, animated UI library for Roblox
    
    Features:
    - Animated toggles, buttons, sliders
    - Dropdown menus
    - Clean, modern design
    - Smooth tweening
    - Responsive layout
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UI Configuration
local THEME = {
    Background = Color3.fromRGB(35, 35, 45),
    Container = Color3.fromRGB(45, 45, 55),
    Primary = Color3.fromRGB(80, 115, 255),
    Secondary = Color3.fromRGB(60, 60, 75),
    Text = Color3.fromRGB(235, 235, 255),
    Shadow = Color3.fromRGB(25, 25, 35),
    Success = Color3.fromRGB(85, 210, 130),
    Error = Color3.fromRGB(240, 90, 90),
}

local CONSTANTS = {
    CornerRadius = UDim.new(0, 6),
    ToggleSize = UDim2.new(0, 40, 0, 20),
    ButtonHeight = UDim2.new(0, 35),
    SliderHeight = UDim2.new(0, 20),
    DropdownHeight = UDim2.new(0, 30),
    ElementSpacing = UDim.new(0, 10),
    ContainerPadding = UDim.new(0, 15),
    TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

-- Utility Functions
local Library = {}

function Library:CreateShadow(frame)
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.BackgroundColor3 = THEME.Shadow
    shadow.BorderSizePixel = 0
    shadow.Position = UDim2.new(0, 2, 0, 2)
    shadow.Size = frame.Size
    shadow.ZIndex = frame.ZIndex - 1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CONSTANTS.CornerRadius
    corner.Parent = shadow
    
    shadow.Parent = frame
    
    -- Update shadow when frame changes
    frame:GetPropertyChangedSignal("Size"):Connect(function()
        shadow.Size = frame.Size
    end)
    
    return shadow
end

function Library:Tween(instance, properties)
    local tween = TweenService:Create(instance, CONSTANTS.TweenInfo, properties)
    tween:Play()
    return tween
end

function Library:CreateDraggable(gui)
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Main UI Creation
function Library:CreateWindow(config)
    config = config or {}
    local title = config.Title or "Modern UI"
    local size = config.Size or UDim2.new(0, 420, 0, 460)
    
    -- Create main GUI
    local ModernUI = Instance.new("ScreenGui")
    ModernUI.Name = "ModernUI"
    ModernUI.ResetOnSpawn = false
    
    -- Parent appropriately depending on core/client context
    if RunService:IsStudio() then
        ModernUI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    else
        ModernUI.Parent = game.CoreGui
    end
    
    -- Main frame
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.BackgroundColor3 = THEME.Background
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
    Main.Size = size
    Main.ZIndex = 10
    Main.Parent = ModernUI
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = CONSTANTS.CornerRadius
    corner.Parent = Main
    
    Library:CreateShadow(Main)
    Library:CreateDraggable(Main)
    
    -- Title bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.BackgroundColor3 = THEME.Container
    TitleBar.BorderSizePixel = 0
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.ZIndex = 11
    TitleBar.Parent = Main
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = CONSTANTS.CornerRadius
    titleCorner.Parent = TitleBar
    
    local titleBottomFrame = Instance.new("Frame")
    titleBottomFrame.Name = "BottomFrame"
    titleBottomFrame.BackgroundColor3 = THEME.Container
    titleBottomFrame.BorderSizePixel = 0
    titleBottomFrame.Position = UDim2.new(0, 0, 0.5, 0)
    titleBottomFrame.Size = UDim2.new(1, 0, 0.5, 0)
    titleBottomFrame.ZIndex = 11
    titleBottomFrame.Parent = TitleBar
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "TitleText"
    TitleText.BackgroundTransparency = 1
    TitleText.Position = UDim2.new(0, 15, 0, 0)
    TitleText.Size = UDim2.new(1, -30, 1, 0)
    TitleText.ZIndex = 12
    TitleText.Font = Enum.Font.GothamSemibold
    TitleText.Text = title
    TitleText.TextColor3 = THEME.Text
    TitleText.TextSize = 14
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Close button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.BackgroundTransparency = 1
    CloseButton.Position = UDim2.new(1, -40, 0, 0)
    CloseButton.Size = UDim2.new(0, 40, 1, 0)
    CloseButton.ZIndex = 12
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "×"
    CloseButton.TextColor3 = THEME.Text
    CloseButton.TextSize = 20
    CloseButton.Parent = TitleBar
    
    CloseButton.MouseEnter:Connect(function()
        Library:Tween(CloseButton, {TextColor3 = THEME.Error})
    end)
    
    CloseButton.MouseLeave:Connect(function()
        Library:Tween(CloseButton, {TextColor3 = THEME.Text})
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        Library:Tween(Main, {Size = UDim2.new(0, size.X.Offset, 0, 0), Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, 0)})
        wait(CONSTANTS.TweenInfo.Time)
        ModernUI:Destroy()
    end)
    
    -- Container
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.BackgroundColor3 = THEME.Container
    Container.BorderSizePixel = 0
    Container.Position = UDim2.new(0, 10, 0, 50)
    Container.Size = UDim2.new(1, -20, 1, -60)
    Container.ZIndex = 11
    Container.Parent = Main
    
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = CONSTANTS.CornerRadius
    containerCorner.Parent = Container
    
    Library:CreateShadow(Container)
    
    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Name = "ScrollingFrame"
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollingFrame.ZIndex = 12
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.ScrollBarThickness = 3
    ScrollingFrame.ScrollBarImageColor3 = THEME.Primary
    ScrollingFrame.Parent = Container
    
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = CONSTANTS.ElementSpacing
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = ScrollingFrame
    
    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingBottom = CONSTANTS.ContainerPadding
    UIPadding.PaddingLeft = CONSTANTS.ContainerPadding
    UIPadding.PaddingRight = CONSTANTS.ContainerPadding
    UIPadding.PaddingTop = CONSTANTS.ContainerPadding
    UIPadding.Parent = ScrollingFrame
    
    -- Auto-update canvas size
    UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + UIPadding.PaddingTop.Offset + UIPadding.PaddingBottom.Offset)
    end)
    
    -- Tab management
    local tabSystem = {}
    local tabs = {}
    local currentTab = nil
    
    function tabSystem:CreateTab(name)
        local tab = {}
        tab.Name = name
        tab.Content = {}
        
        local tabButton = Instance.new("TextButton")
        tabButton.Name = name.."Tab"
        tabButton.BackgroundColor3 = THEME.Secondary
        tabButton.BorderSizePixel = 0
        tabButton.Size = UDim2.new(0, 100, 0, 30)
        tabButton.ZIndex = 12
        tabButton.Font = Enum.Font.Gotham
        tabButton.Text = name
        tabButton.TextColor3 = THEME.Text
        tabButton.TextSize = 12
        tabButton.Parent = ScrollingFrame
        
        local tabButtonCorner = Instance.new("UICorner")
        tabButtonCorner.CornerRadius = UDim.new(0, 4)
        tabButtonCorner.Parent = tabButton
        
        local tabContainer = Instance.new("Frame")
        tabContainer.Name = name.."Container"
        tabContainer.BackgroundTransparency = 1
        tabContainer.Size = UDim2.new(1, -30, 0, 0) -- Height will be auto-adjusted by UIListLayout
        tabContainer.ZIndex = 12
        tabContainer.Visible = false
        tabContainer.Parent = ScrollingFrame
        
        local tabUIListLayout = Instance.new("UIListLayout")
        tabUIListLayout.Padding = CONSTANTS.ElementSpacing
        tabUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tabUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabUIListLayout.Parent = tabContainer
        
        -- Auto-update container size
        tabUIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContainer.Size = UDim2.new(1, -30, 0, tabUIListLayout.AbsoluteContentSize.Y)
        end)
        
        tabButton.MouseButton1Click:Connect(function()
            if currentTab then
                currentTab.Container.Visible = false
                Library:Tween(currentTab.Button, {BackgroundColor3 = THEME.Secondary})
            end
            
            tabContainer.Visible = true
            Library:Tween(tabButton, {BackgroundColor3 = THEME.Primary})
            currentTab = {Button = tabButton, Container = tabContainer}
        end)
        
        -- UI Components
        function tab:CreateToggle(config)
            local toggle = {}
            toggle.Name = config.Name or "Toggle"
            toggle.Value = config.Default or false
            toggle.Callback = config.Callback or function() end
            
            local toggleFrame = Instance.new("Frame")
            toggleFrame.Name = toggle.Name.."Frame"
            toggleFrame.BackgroundColor3 = THEME.Secondary
            toggleFrame.BorderSizePixel = 0
            toggleFrame.Size = UDim2.new(1, 0, 0, 40)
            toggleFrame.ZIndex = 12
            toggleFrame.Parent = tabContainer
            
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 4)
            toggleCorner.Parent = toggleFrame
            
            local toggleLabel = Instance.new("TextLabel")
            toggleLabel.Name = "Label"
            toggleLabel.BackgroundTransparency = 1
            toggleLabel.Position = UDim2.new(0, 10, 0, 0)
            toggleLabel.Size = UDim2.new(1, -60, 1, 0)
            toggleLabel.ZIndex = 13
            toggleLabel.Font = Enum.Font.Gotham
            toggleLabel.Text = toggle.Name
            toggleLabel.TextColor3 = THEME.Text
            toggleLabel.TextSize = 14
            toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            toggleLabel.Parent = toggleFrame
            
            local toggleButton = Instance.new("Frame")
            toggleButton.Name = "ToggleButton"
            toggleButton.BackgroundColor3 = toggle.Value and THEME.Success or THEME.Error
            toggleButton.BorderSizePixel = 0
            toggleButton.Position = UDim2.new(1, -50, 0.5, -10)
            toggleButton.Size = CONSTANTS.ToggleSize
            toggleButton.ZIndex = 13
            toggleButton.Parent = toggleFrame
            
            local toggleButtonCorner = Instance.new("UICorner")
            toggleButtonCorner.CornerRadius = UDim.new(1, 0)
            toggleButtonCorner.Parent = toggleButton
            
            local toggleCircle = Instance.new("Frame")
            toggleCircle.Name = "Circle"
            toggleCircle.BackgroundColor3 = THEME.Text
            toggleCircle.BorderSizePixel = 0
            toggleCircle.Position = UDim2.new(0, toggle.Value and 20 or 2, 0.5, -8)
            toggleCircle.Size = UDim2.new(0, 16, 0, 16)
            toggleCircle.ZIndex = 14
            toggleCircle.Parent = toggleButton
            
            local toggleCircleCorner = Instance.new("UICorner")
            toggleCircleCorner.CornerRadius = UDim.new(1, 0)
            toggleCircleCorner.Parent = toggleCircle
            
            -- Functionality
            toggleButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    toggle.Value = not toggle.Value
                    
                    -- Animate
                    if toggle.Value then
                        Library:Tween(toggleButton, {BackgroundColor3 = THEME.Success})
                        Library:Tween(toggleCircle, {Position = UDim2.new(0, 20, 0.5, -8)})
                    else
                        Library:Tween(toggleButton, {BackgroundColor3 = THEME.Error})
                        Library:Tween(toggleCircle, {Position = UDim2.new(0, 2, 0.5, -8)})
                    end
                    
                    -- Callback
                    toggle.Callback(toggle.Value)
                end
            end)
            
            function toggle:Set(value)
                toggle.Value = value
                
                if toggle.Value then
                    Library:Tween(toggleButton, {BackgroundColor3 = THEME.Success})
                    Library:Tween(toggleCircle, {Position = UDim2.new(0, 20, 0.5, -8)})
                else
                    Library:Tween(toggleButton, {BackgroundColor3 = THEME.Error})
                    Library:Tween(toggleCircle, {Position = UDim2.new(0, 2, 0.5, -8)})
                end
                
                toggle.Callback(toggle.Value)
            end
            
            return toggle
        end
        
        function tab:CreateButton(config)
            local button = {}
            button.Name = config.Name or "Button"
            button.Callback = config.Callback or function() end
            
            local buttonFrame = Instance.new("Frame")
            buttonFrame.Name = button.Name.."Frame"
            buttonFrame.BackgroundColor3 = THEME.Secondary
            buttonFrame.BorderSizePixel = 0
            buttonFrame.Size = UDim2.new(1, 0, 0, 35)
            buttonFrame.ZIndex = 12
            buttonFrame.Parent = tabContainer
            
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 4)
            buttonCorner.Parent = buttonFrame
            
            local buttonButton = Instance.new("TextButton")
            buttonButton.Name = "Button"
            buttonButton.BackgroundColor3 = THEME.Primary
            buttonButton.BackgroundTransparency = 0
            buttonButton.BorderSizePixel = 0
            buttonButton.Position = UDim2.new(0, 0, 0, 0)
            buttonButton.Size = UDim2.new(1, 0, 1, 0)
            buttonButton.ZIndex = 13
            buttonButton.Font = Enum.Font.GothamSemibold
            buttonButton.Text = button.Name
            buttonButton.TextColor3 = THEME.Text
            buttonButton.TextSize = 14
            buttonButton.Parent = buttonFrame
            
            local buttonButtonCorner = Instance.new("UICorner")
            buttonButtonCorner.CornerRadius = UDim.new(0, 4)
            buttonButtonCorner.Parent = buttonButton
            
            -- Hover and click effects
            buttonButton.MouseEnter:Connect(function()
                Library:Tween(buttonButton, {BackgroundTransparency = 0.2})
            end)
            
            buttonButton.MouseLeave:Connect(function()
                Library:Tween(buttonButton, {BackgroundTransparency = 0})
            end)
            
            buttonButton.MouseButton1Down:Connect(function()
                Library:Tween(buttonButton, {Size = UDim2.new(0.95, 0, 0.95, 0), Position = UDim2.new(0.025, 0, 0.025, 0)})
            end)
            
            buttonButton.MouseButton1Up:Connect(function()
                Library:Tween(buttonButton, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)})
                button.Callback()
            end)
            
            return button
        end
        
        function tab:CreateSlider(config)
            local slider = {}
            slider.Name = config.Name or "Slider"
            slider.Min = config.Min or 0
            slider.Max = config.Max or 100
            slider.Value = config.Default or slider.Min
            slider.Callback = config.Callback or function() end
            
            -- Clamp initial value
            slider.Value = math.clamp(slider.Value, slider.Min, slider.Max)
            
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Name = slider.Name.."Frame"
            sliderFrame.BackgroundColor3 = THEME.Secondary
            sliderFrame.BorderSizePixel = 0
            sliderFrame.Size = UDim2.new(1, 0, 0, 60)
            sliderFrame.ZIndex = 12
            sliderFrame.Parent = tabContainer
            
            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 4)
            sliderCorner.Parent = sliderFrame
            
            local sliderLabel = Instance.new("TextLabel")
            sliderLabel.Name = "Label"
            sliderLabel.BackgroundTransparency = 1
            sliderLabel.Position = UDim2.new(0, 10, 0, 5)
            sliderLabel.Size = UDim2.new(1, -20, 0, 20)
            sliderLabel.ZIndex = 13
            sliderLabel.Font = Enum.Font.Gotham
            sliderLabel.Text = slider.Name
            sliderLabel.TextColor3 = THEME.Text
            sliderLabel.TextSize = 14
            sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            sliderLabel.Parent = sliderFrame
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Name = "Value"
            valueLabel.BackgroundTransparency = 1
            valueLabel.Position = UDim2.new(1, -50, 0, 5)
            valueLabel.Size = UDim2.new(0, 40, 0, 20)
            valueLabel.ZIndex = 13
            valueLabel.Font = Enum.Font.GothamSemibold
            valueLabel.Text = tostring(slider.Value)
            valueLabel.TextColor3 = THEME.Primary
            valueLabel.TextSize = 14
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.Parent = sliderFrame
            
            local sliderBG = Instance.new("Frame")
            sliderBG.Name = "SliderBG"
            sliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            sliderBG.BorderSizePixel = 0
            sliderBG.Position = UDim2.new(0, 10, 0, 35)
            sliderBG.Size = UDim2.new(1, -20, 0, 10)
            sliderBG.ZIndex = 13
            sliderBG.Parent = sliderFrame
            
            local sliderBGCorner = Instance.new("UICorner")
            sliderBGCorner.CornerRadius = UDim.new(1, 0)
            sliderBGCorner.Parent = sliderBG
            
            local sliderFill = Instance.new("Frame")
            sliderFill.Name = "Fill"
            sliderFill.BackgroundColor3 = THEME.Primary
            sliderFill.BorderSizePixel = 0
            sliderFill.Size = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), 0, 1, 0)
            sliderFill.ZIndex = 14
            sliderFill.Parent = sliderBG
            
            local sliderFillCorner = Instance.new("UICorner")
            sliderFillCorner.CornerRadius = UDim.new(1, 0)
            sliderFillCorner.Parent = sliderFill
            
            local sliderCircle = Instance.new("Frame")
            sliderCircle.Name = "Circle"
            sliderCircle.BackgroundColor3 = THEME.Text
            sliderCircle.BorderSizePixel = 0
            sliderCircle.Position = UDim2.new((slider.Value - slider.Min) / (slider.Max - slider.Min), -6, 0.5, -6)
            sliderCircle.Size = UDim2.new(0, 12, 0, 12)
            sliderCircle.ZIndex = 15
            sliderCircle.Parent = sliderBG
            
            local sliderCircleCorner = Instance.new("UICorner")
            sliderCircleCorner.CornerRadius = UDim.new(1, 0)
            sliderCircleCorner.Parent = sliderCircle
            
            -- Slider functionality
            local function updateSlider(input)
                local sizeX = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
                sliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
                sliderCircle.Position = UDim2.new(sizeX, -6, 0.5, -6)
                
                local value = math.floor(slider.Min + ((slider.Max - slider.Min) * sizeX))
                valueLabel.Text = tostring(value)
                slider.Value = value
                slider.Callback(value)
            end
            
            sliderBG.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    updateSlider(input)
                    
                    local connection
                    connection = RunService.RenderStepped:Connect(function()
                        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                            updateSlider({Position = UserInputService:GetMouseLocation()})
                        else
                            connection:Disconnect()
                        end
                    end)
                end
            end)
            
            function slider:Set(value)
                value = math.clamp(value, slider.Min, slider.Max)
                slider.Value = value
                
                local sizeX = (value - slider.Min) / (slider.Max - slider.Min)
                sliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
                sliderCircle.Position = UDim2.new(sizeX, -6, 0.5, -6)
                valueLabel.Text = tostring(value)
                
                slider.Callback(value)
            end
            
            return slider
        end
        
        function tab:CreateDropdown(config)
            local dropdown = {}
            dropdown.Name = config.Name or "Dropdown"
            dropdown.Options = config.Options or {}
            dropdown.Default = config.Default
            dropdown.Value = config.Default or dropdown.Options[1] or ""
            dropdown.Callback = config.Callback or function() end
            dropdown.Open = false
            
            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Name = dropdown.Name.."Frame"
            dropdownFrame.BackgroundColor3 = THEME.Secondary
            dropdownFrame.BorderSizePixel = 0
            dropdownFrame.Size = UDim2.new(1, 0, 0, 70) -- Initial size, will change
            dropdownFrame.ZIndex = 12
            dropdownFrame.ClipsDescendants = true
            dropdownFrame.Parent = tabContainer
            
            local dropdownCorner = Instance.new("UICorner")
            dropdownCorner.CornerRadius = UDim.new(0, 4)
            dropdownCorner.Parent = dropdownFrame
            
            local dropdownLabel = Instance.new("TextLabel")
            dropdownLabel.Name = "Label"
            dropdownLabel.BackgroundTransparency = 1
            dropdownLabel.Position = UDim2.new(0, 10, 0, 5)
            dropdownLabel.Size = UDim2.new(1, -20, 0, 20)
            dropdownLabel.ZIndex = 13
            dropdownLabel.Font = Enum.Font.Gotham
            dropdownLabel.Text = dropdown.Name
            dropdownLabel.TextColor3 = THEME.Text
            dropdownLabel.TextSize = 14
            dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            dropdownLabel.Parent = dropdownFrame
            
            local dropdownButton = Instance.new("TextButton")
            dropdownButton.Name = "DropdownButton"
            dropdownButton.BackgroundColor3 = THEME.Container
            dropdownButton.BorderSizePixel = 0
            dropdownButton.Position = UDim2.new(0, 10, 0, 30)
            dropdownButton.Size = UDim2.new(1, -20, 0, 30)
            dropdownButton.ZIndex = 13
            dropdownButton.Font = Enum.Font.Gotham
            dropdownButton.Text = dropdown.Value
            dropdownButton.TextColor3 = THEME.Text
            dropdownButton.TextSize = 14
            dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
            dropdownButton.TextTruncate = Enum.TextTruncate.AtEnd
            dropdownButton.Parent = dropdownFrame
            
            local dropdownPadding = Instance.new("UIPadding")
            dropdownPadding.PaddingLeft = UDim.new(0, 10)
            dropdownPadding.Parent = dropdownButton
            
            local dropdownButtonCorner = Instance.new("UICorner")
            dropdownButtonCorner.CornerRadius = UDim.new(0, 4)
            dropdownButtonCorner.Parent = dropdownButton
            
            local dropdownIcon = Instance.new("ImageLabel")
            dropdownIcon.Name = "Icon"
            dropdownIcon.BackgroundTransparency = 1
            dropdownIcon.Position = UDim2.new(1, -25, 0.5, -8)
            dropdownIcon.Size = UDim2.new(0, 16, 0, 16)
            dropdownIcon.ZIndex = 14
            dropdownIcon.Image = "rbxassetid://3926305904"
            dropdownIcon.ImageRectOffset = Vector2.new(484, 204)
            dropdownIcon.ImageRectSize = Vector2.new(36, 36)
            dropdownIcon.Rotation = 0
            dropdownIcon.Parent = dropdownButton
            
            -- Options container
            local optionsFrame = Instance.new("Frame")
            optionsFrame.Name = "OptionsFrame"
            optionsFrame.BackgroundColor3 = THEME.Container
            optionsFrame.BorderSizePixel = 0
            optionsFrame.Position = UDim2.new(0, 10, 0, 65)
            optionsFrame.Size = UDim2.new(1, -20, 0, 0) -- Will be resized
            optionsFrame.ZIndex = 15
            optionsFrame.Visible = false
            optionsFrame.Parent = dropdownFrame
            
            local optionsCorner = Instance.new("UICorner")
            optionsCorner.CornerRadius = UDim.new(0, 4)
            optionsCorner.Parent = optionsFrame
            
            local optionsList = Instance.new("ScrollingFrame")
            optionsList.Name = "OptionsList"
            optionsList.BackgroundTransparency = 1
            optionsList.BorderSizePixel = 0
            optionsList.Size = UDim2.new(1, 0, 1, 0)
            optionsList.ZIndex = 16
            optionsList.CanvasSize = UDim2.new(0, 0, 0, 0)
            optionsList.ScrollBarThickness = 3
            optionsList.ScrollBarImageColor3 = THEME.Primary
            optionsList.Parent = optionsFrame
            
            local optionsListLayout = Instance.new("UIListLayout")
            optionsListLayout.Padding = UDim.new(0, 2)
            optionsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            optionsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optionsListLayout.Parent = optionsList
            
            local optionsListPadding = Instance.new("UIPadding")
            optionsListPadding.PaddingTop = UDim.new(0, 5)
            optionsListPadding.PaddingBottom = UDim.new(0, 5)
            optionsListPadding.PaddingLeft = UDim.new(0, 5)
            optionsListPadding.PaddingRight = UDim.new(0, 5)
            optionsListPadding.Parent = optionsList
            
            -- Create option buttons
            local function createOptions()
                -- Clear existing options
                for _, child in pairs(optionsList:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                
                -- Create new options
                for i, option in ipairs(dropdown.Options) do
                    local optionButton = Instance.new("TextButton")
                    optionButton.Name = option
                    optionButton.BackgroundColor3 = THEME.Secondary
                    optionButton.BackgroundTransparency = 0.5
                    optionButton.BorderSizePixel = 0
                    optionButton.Size = UDim2.new(1, -10, 0, 25)
                    optionButton.ZIndex = 17
                    optionButton.Font = Enum.Font.Gotham
                    optionButton.Text = option
                    optionButton.TextColor3 = option == dropdown.Value and THEME.Primary or THEME.Text
                    optionButton.TextSize = 14
                    optionButton.Parent = optionsList
                    
                    local optionButtonCorner = Instance.new("UICorner")
                    optionButtonCorner.CornerRadius = UDim.new(0, 4)
                    optionButtonCorner.Parent = optionButton
                    
                    -- Hover effect
                    optionButton.MouseEnter:Connect(function()
                        if option ~= dropdown.Value then
                            Library:Tween(optionButton, {BackgroundTransparency = 0.2})
                        end
                    end)
                    
                    optionButton.MouseLeave:Connect(function()
                        if option ~= dropdown.Value then
                            Library:Tween(optionButton, {BackgroundTransparency = 0.5})
                        end
                    end)
                    
                    -- Selection
                    optionButton.MouseButton1Click:Connect(function()
                        dropdown.Value = option
                        dropdownButton.Text = option
                        
                        -- Update option colors
                        for _, child in pairs(optionsList:GetChildren()) do
                            if child:IsA("TextButton") then
                                child.TextColor3 = child.Name == option and THEME.Primary or THEME.Text
                            end
                        end
                        
                        -- Close dropdown with animation
                        Library:Tween(dropdownIcon, {Rotation = 0})
                        Library:Tween(optionsFrame, {Size = UDim2.new(1, -20, 0, 0)})
                        Library:Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 70)})
                        
                        dropdown.Open = false
                        dropdown.Callback(option)
                        
                        task.delay(0.2, function()
                            optionsFrame.Visible = false
                        end)
                    end)
                end
                
                -- Update canvas size
                optionsList.CanvasSize = UDim2.new(0, 0, 0, optionsListLayout.AbsoluteContentSize.Y + 10)
            end
            
            -- Toggle dropdown
            dropdownButton.MouseButton1Click:Connect(function()
                dropdown.Open = not dropdown.Open
                
                if dropdown.Open then
                    -- Show options with animation
                    optionsFrame.Visible = true
                    optionsFrame.Size = UDim2.new(1, -20, 0, 0)
                    
                    local optionsHeight = math.min(120, #dropdown.Options * 25 + 20)
                    Library:Tween(dropdownIcon, {Rotation = 180})
                    Library:Tween(optionsFrame, {Size = UDim2.new(1, -20, 0, optionsHeight)})
                    Library:Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 70 + optionsHeight)})
                else
                    -- Hide options with animation
                    Library:Tween(dropdownIcon, {Rotation = 0})
                    Library:Tween(optionsFrame, {Size = UDim2.new(1, -20, 0, 0)})
                    Library:Tween(dropdownFrame, {Size = UDim2.new(1, 0, 0, 70)})
                    
                    task.delay(0.2, function()
                        optionsFrame.Visible = false
                    end)
                end
            end)
            
            -- Initialize options
            createOptions()
            
            function dropdown:SetOptions(options)
                dropdown.Options = options
                createOptions()
            end
            
            function dropdown:Set(value)
                if table.find(dropdown.Options, value) then
                    dropdown.Value = value
                    dropdownButton.Text = value
                    
                    -- Update option colors when refreshing options
                    createOptions()
                    dropdown.Callback(value)
                end
            end
            
            return dropdown
        end
        
        function tab:CreateInput(config)
            local input = {}
            input.Name = config.Name or "Input"
            input.PlaceholderText = config.PlaceholderText or "Enter text..."
            input.Default = config.Default or ""
            input.Callback = config.Callback or function() end
            
            local inputFrame = Instance.new("Frame")
            inputFrame.Name = input.Name.."Frame"
            inputFrame.BackgroundColor3 = THEME.Secondary
            inputFrame.BorderSizePixel = 0
            inputFrame.Size = UDim2.new(1, 0, 0, 70)
            inputFrame.ZIndex = 12
            inputFrame.Parent = tabContainer
            
            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 4)
            inputCorner.Parent = inputFrame
            
            local inputLabel = Instance.new("TextLabel")
            inputLabel.Name = "Label"
            inputLabel.BackgroundTransparency = 1
            inputLabel.Position = UDim2.new(0, 10, 0, 5)
            inputLabel.Size = UDim2.new(1, -20, 0, 20)
            inputLabel.ZIndex = 13
            inputLabel.Font = Enum.Font.Gotham
            inputLabel.Text = input.Name
            inputLabel.TextColor3 = THEME.Text
            inputLabel.TextSize = 14
            inputLabel.TextXAlignment = Enum.TextXAlignment.Left
            inputLabel.Parent = inputFrame
            
            local inputBox = Instance.new("TextBox")
            inputBox.Name = "InputBox"
            inputBox.BackgroundColor3 = THEME.Container
            inputBox.BorderSizePixel = 0
            inputBox.Position = UDim2.new(0, 10, 0, 30)
            inputBox.Size = UDim2.new(1, -20, 0, 30)
            inputBox.ZIndex = 13
            inputBox.Font = Enum.Font.Gotham
            inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
            inputBox.PlaceholderText = input.PlaceholderText
            inputBox.Text = input.Default
            inputBox.TextColor3 = THEME.Text
            inputBox.TextSize = 14
            inputBox.TextXAlignment = Enum.TextXAlignment.Left
            inputBox.ClearTextOnFocus = false
            inputBox.Parent = inputFrame
            
            local inputPadding = Instance.new("UIPadding")
            inputPadding.PaddingLeft = UDim.new(0, 10)
            inputPadding.Parent = inputBox
            
            local inputBoxCorner = Instance.new("UICorner")
            inputBoxCorner.CornerRadius = UDim.new(0, 4)
            inputBoxCorner.Parent = inputBox
            
            -- Functionality
            inputBox.Focused:Connect(function()
                Library:Tween(inputBox, {BorderSizePixel = 1, BorderColor3 = THEME.Primary})
            end)
            
            inputBox.FocusLost:Connect(function(enterPressed)
                Library:Tween(inputBox, {BorderSizePixel = 0})
                input.Callback(inputBox.Text, enterPressed)
            end)
            
            function input:Set(value)
                inputBox.Text = value
                input.Callback(value, false)
            end
            
            return input
        end
        
        function tab:CreateColorPicker(config)
            local colorPicker = {}
            colorPicker.Name = config.Name or "Color Picker"
            colorPicker.Default = config.Default or Color3.fromRGB(255, 255, 255)
            colorPicker.Callback = config.Callback or function() end
            colorPicker.Value = colorPicker.Default
            colorPicker.Open = false
            
            local colorPickerFrame = Instance.new("Frame")
            colorPickerFrame.Name = colorPicker.Name.."Frame"
            colorPickerFrame.BackgroundColor3 = THEME.Secondary
            colorPickerFrame.BorderSizePixel = 0
            colorPickerFrame.Size = UDim2.new(1, 0, 0, 70)
            colorPickerFrame.ZIndex = 12
            colorPickerFrame.ClipsDescendants = true
            colorPickerFrame.Parent = tabContainer
            
            local colorPickerCorner = Instance.new("UICorner")
            colorPickerCorner.CornerRadius = UDim.new(0, 4)
            colorPickerCorner.Parent = colorPickerFrame
            
            local colorPickerLabel = Instance.new("TextLabel")
            colorPickerLabel.Name = "Label"
            colorPickerLabel.BackgroundTransparency = 1
            colorPickerLabel.Position = UDim2.new(0, 10, 0, 5)
            colorPickerLabel.Size = UDim2.new(1, -60, 0, 20)
            colorPickerLabel.ZIndex = 13
            colorPickerLabel.Font = Enum.Font.Gotham
            colorPickerLabel.Text = colorPicker.Name
            colorPickerLabel.TextColor3 = THEME.Text
            colorPickerLabel.TextSize = 14
            colorPickerLabel.TextXAlignment = Enum.TextXAlignment.Left
            colorPickerLabel.Parent = colorPickerFrame
            
            local colorDisplay = Instance.new("Frame")
            colorDisplay.Name = "ColorDisplay"
            colorDisplay.BackgroundColor3 = colorPicker.Value
            colorDisplay.BorderSizePixel = 0
            colorDisplay.Position = UDim2.new(1, -50, 0, 5)
            colorDisplay.Size = UDim2.new(0, 40, 0, 20)
            colorDisplay.ZIndex = 13
            colorDisplay.Parent = colorPickerFrame
            
            local colorDisplayCorner = Instance.new("UICorner")
            colorDisplayCorner.CornerRadius = UDim.new(0, 4)
            colorDisplayCorner.Parent = colorDisplay
            
            local pickerButton = Instance.new("TextButton")
            pickerButton.Name = "PickerButton"
            pickerButton.BackgroundColor3 = THEME.Container
            pickerButton.BorderSizePixel = 0
            pickerButton.Position = UDim2.new(0, 10, 0, 30)
            pickerButton.Size = UDim2.new(1, -20, 0, 30)
            pickerButton.ZIndex = 13
            pickerButton.Font = Enum.Font.Gotham
            pickerButton.Text = "Select Color"
            pickerButton.TextColor3 = THEME.Text
            pickerButton.TextSize = 14
            pickerButton.Parent = colorPickerFrame
            
            local pickerButtonCorner = Instance.new("UICorner")
            pickerButtonCorner.CornerRadius = UDim.new(0, 4)
            pickerButtonCorner.Parent = pickerButton
            
            -- Color picker UI (expanded when clicked)
            local pickerExpanded = Instance.new("Frame")
            pickerExpanded.Name = "PickerExpanded"
            pickerExpanded.BackgroundColor3 = THEME.Container
            pickerExpanded.BorderSizePixel = 0
            pickerExpanded.Position = UDim2.new(0, 10, 0, 65)
            pickerExpanded.Size = UDim2.new(1, -20, 0, 0)
            pickerExpanded.ZIndex = 15
            pickerExpanded.Visible = false
            pickerExpanded.Parent = colorPickerFrame
            
            local pickerExpandedCorner = Instance.new("UICorner")
            pickerExpandedCorner.CornerRadius = UDim.new(0, 4)
            pickerExpandedCorner.Parent = pickerExpanded
            
            -- Hue, Saturation, Value sliders implementation
            local function createColorSlider(name, position, color)
                local sliderFrame = Instance.new("Frame")
                sliderFrame.Name = name.."SliderFrame"
                sliderFrame.BackgroundTransparency = 1
                sliderFrame.Position = position
                sliderFrame.Size = UDim2.new(1, -20, 0, 30)
                sliderFrame.ZIndex = 16
                sliderFrame.Parent = pickerExpanded
                
                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Name = "Label"
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.Position = UDim2.new(0, 0, 0, 0)
                sliderLabel.Size = UDim2.new(0, 30, 1, 0)
                sliderLabel.ZIndex = 17
                sliderLabel.Font = Enum.Font.GothamSemibold
                sliderLabel.Text = string.sub(name, 1, 1)
                sliderLabel.TextColor3 = THEME.Text
                sliderLabel.TextSize = 14
                sliderLabel.Parent = sliderFrame
                
                local sliderBG = Instance.new("Frame")
                sliderBG.Name = "SliderBG"
                sliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                sliderBG.BorderSizePixel = 0
                sliderBG.Position = UDim2.new(0, 30, 0.5, -5)
                sliderBG.Size = UDim2.new(1, -40, 0, 10)
                sliderBG.ZIndex = 17
                sliderBG.Parent = sliderFrame
                
                local sliderBGCorner = Instance.new("UICorner")
                sliderBGCorner.CornerRadius = UDim.new(1, 0)
                sliderBGCorner.Parent = sliderBG
                
                -- Create a gradient for the slider
                local sliderGradient = Instance.new("UIGradient")
                sliderGradient.Name = "SliderGradient"
                sliderGradient.Color = color
                sliderGradient.Parent = sliderBG
                
                local sliderCircle = Instance.new("Frame")
                sliderCircle.Name = "Circle"
                sliderCircle.BackgroundColor3 = THEME.Text
                sliderCircle.BorderSizePixel = 0
                sliderCircle.Position = UDim2.new(0.5, -6, 0.5, -6)
                sliderCircle.Size = UDim2.new(0, 12, 0, 12)
                sliderCircle.ZIndex = 19
                sliderCircle.Parent = sliderBG
                
                local sliderCircleCorner = Instance.new("UICorner")
                sliderCircleCorner.CornerRadius = UDim.new(1, 0)
                sliderCircleCorner.Parent = sliderCircle
                
                return {
                    Frame = sliderFrame,
                    Background = sliderBG,
                    Circle = sliderCircle,
                    Gradient = sliderGradient
                }
            end
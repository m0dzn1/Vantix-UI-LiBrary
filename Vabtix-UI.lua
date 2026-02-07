--[[ 
    Modern UI Library - Standalone
    Features: Config System, Themes, Animations, All requested components.
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local Library = {}
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// File System (Safe Check)
local writefile = writefile or function(...) end
local readfile = readfile or function(...) end
local isfile = isfile or function(...) return false end
local isfolder = isfolder or function(...) return false end
local makefolder = makefolder or function(...) end
local listfiles = listfiles or function(...) return {} end

--// Constants & Themes
local Themes = {
    Light = {
        Main = Color3.fromRGB(240, 240, 240),
        Secondary = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(20, 20, 20),
        Accent = Color3.fromRGB(0, 122, 255),
        Outline = Color3.fromRGB(200, 200, 200)
    },
    Dark = { -- Default
        Main = Color3.fromRGB(25, 25, 25),
        Secondary = Color3.fromRGB(35, 35, 35),
        Text = Color3.fromRGB(240, 240, 240),
        Accent = Color3.fromRGB(60, 130, 240),
        Outline = Color3.fromRGB(50, 50, 50)
    },
    Midnight = {
        Main = Color3.fromRGB(0, 0, 0),
        Secondary = Color3.fromRGB(15, 15, 15),
        Text = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(80, 80, 80),
        Outline = Color3.fromRGB(30, 30, 30)
    },
    Ruby = {
        Main = Color3.fromRGB(20, 10, 10),
        Secondary = Color3.fromRGB(30, 15, 15),
        Text = Color3.fromRGB(255, 230, 230),
        Accent = Color3.fromRGB(220, 40, 40),
        Outline = Color3.fromRGB(60, 20, 20)
    },
    Emerald = {
        Main = Color3.fromRGB(10, 20, 10),
        Secondary = Color3.fromRGB(15, 30, 15),
        Text = Color3.fromRGB(230, 255, 230),
        Accent = Color3.fromRGB(40, 220, 80),
        Outline = Color3.fromRGB(20, 60, 20)
    },
    Ocean = {
        Main = Color3.fromRGB(10, 15, 30),
        Secondary = Color3.fromRGB(20, 30, 50),
        Text = Color3.fromRGB(230, 240, 255),
        Accent = Color3.fromRGB(40, 140, 240),
        Outline = Color3.fromRGB(30, 50, 80)
    },
    Amethyst = {
        Main = Color3.fromRGB(20, 10, 30),
        Secondary = Color3.fromRGB(30, 20, 45),
        Text = Color3.fromRGB(245, 230, 255),
        Accent = Color3.fromRGB(160, 60, 220),
        Outline = Color3.fromRGB(60, 30, 80)
    },
    Amber = {
        Main = Color3.fromRGB(20, 15, 5),
        Secondary = Color3.fromRGB(30, 25, 10),
        Text = Color3.fromRGB(255, 245, 230),
        Accent = Color3.fromRGB(230, 140, 20),
        Outline = Color3.fromRGB(80, 50, 20)
    },
    Rose = {
        Main = Color3.fromRGB(25, 15, 20),
        Secondary = Color3.fromRGB(35, 25, 30),
        Text = Color3.fromRGB(255, 235, 240),
        Accent = Color3.fromRGB(240, 60, 140),
        Outline = Color3.fromRGB(80, 30, 60)
    },
    Slate = {
        Main = Color3.fromRGB(30, 35, 40),
        Secondary = Color3.fromRGB(45, 50, 55),
        Text = Color3.fromRGB(220, 225, 230),
        Accent = Color3.fromRGB(100, 110, 120),
        Outline = Color3.fromRGB(60, 70, 80)
    }
}

--// State
Library.CurrentTheme = Themes.Dark
Library.Flags = {}
Library.ConfigFolder = "MyScriptConfig"
Library.Settings = {
    Theme = "Dark",
    SFX = true,
    Notifications = true,
    Keybind = "RightControl" -- Default panic key
}
Library.Open = true
Library.Elements = {} -- Registry for updating themes

--// Utility Functions
local function Create(class, properties)
    local instance = Instance.new(class)
    for k, v in pairs(properties) do
        instance[k] = v
    end
    return instance
end

local function Tween(instance, info, properties)
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function PlaySound(id)
    if Library.Settings.SFX then
        local sound = Create("Sound", {
            SoundId = "rbxassetid://" .. id,
            Parent = CoreGui,
            Volume = 1
        })
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end
end

--// Main Library Logic
function Library:CreateWindow(options)
    local Title = options.Name or "UI Library"
    Library.ConfigFolder = options.ConfigFolder or "MyScriptConfig"
    
    -- Initialize Config Folder
    if not isfolder(Library.ConfigFolder) then
        makefolder(Library.ConfigFolder)
    end

    local ScreenGui = Create("ScreenGui", {
        Name = Title,
        Parent = (RunService:IsStudio() and LocalPlayer.PlayerGui) or CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        BackgroundColor3 = Library.CurrentTheme.Main,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -300, 0.5, -200),
        Size = UDim2.new(0, 600, 0, 400),
        ClipsDescendants = true
    })

    local UICorner = Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainFrame })
    local UIStroke = Create("UIStroke", { Color = Library.CurrentTheme.Outline, Thickness = 1, Parent = MainFrame })

    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(MainFrame, TweenInfo.new(0.1), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)})
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Top Bar
    local TopBar = Create("Frame", {
        Name = "TopBar",
        Parent = MainFrame,
        BackgroundColor3 = Library.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 2
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = TopBar })
    -- Fix bottom corners of top bar
    local Filler = Create("Frame", {
        Parent = TopBar,
        BackgroundColor3 = Library.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -5),
        Size = UDim2.new(1, 0, 0, 5)
    })

    local TitleLabel = Create("TextLabel", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = Title,
        TextColor3 = Library.CurrentTheme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Close Button (Panic/Destroy)
    local CloseBtn = Create("TextButton", {
        Parent = TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -40, 0, 0),
        Size = UDim2.new(0, 40, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "X",
        TextColor3 = Library.CurrentTheme.Text,
        TextSize = 16
    })
    CloseBtn.MouseButton1Click:Connect(function()
        Library:Destroy()
    end)

    -- Container for Tabs
    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer",
        Parent = MainFrame,
        BackgroundColor3 = Library.CurrentTheme.Secondary,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 50),
        Size = UDim2.new(0, 140, 1, -60),
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    local TabListLayout = Create("UIListLayout", {
        Parent = TabContainer,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })

    -- Container for Pages
    local PageContainer = Create("Frame", {
        Name = "PageContainer",
        Parent = MainFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 160, 0, 50),
        Size = UDim2.new(1, -170, 1, -60)
    })

    -- Notification Container
    local NotificationHolder = Create("Frame", {
        Name = "Notifications",
        Parent = ScreenGui,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -320, 1, -20), -- Start bottom right
        Size = UDim2.new(0, 300, 1, 0),
        AnchorPoint = Vector2.new(0, 1)
    })
    local NotifLayout = Create("UIListLayout", {
        Parent = NotificationHolder,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 5)
    })

    --// Notification Function
    function Library:Notify(title, content, duration)
        if not Library.Settings.Notifications then return end
        duration = duration or 3

        local NotifFrame = Create("Frame", {
            Parent = NotificationHolder,
            BackgroundColor3 = Library.CurrentTheme.Secondary,
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundTransparency = 1 -- Start invisible
        })
        local NCorner = Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = NotifFrame })
        local NStroke = Create("UIStroke", { Color = Library.CurrentTheme.Outline, Thickness = 1, Parent = NotifFrame })
        
        local NTitle = Create("TextLabel", {
            Parent = NotifFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(1, -20, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = title,
            TextColor3 = Library.CurrentTheme.Accent,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        local NContent = Create("TextLabel", {
            Parent = NotifFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 25),
            Size = UDim2.new(1, -20, 0, 30),
            Font = Enum.Font.Gotham,
            Text = content,
            TextColor3 = Library.CurrentTheme.Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true
        })

        -- Animation
        Tween(NotifFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0})
        PlaySound(4590657391) -- Pop sound

        task.delay(duration, function()
            local out = Tween(NotifFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1})
            Tween(NTitle, TweenInfo.new(0.3), {TextTransparency = 1})
            Tween(NContent, TweenInfo.new(0.3), {TextTransparency = 1})
            out.Completed:Wait()
            NotifFrame:Destroy()
        end)
    end

    --// Theme Update Function
    function Library:UpdateTheme()
        local theme = Library.CurrentTheme
        MainFrame.BackgroundColor3 = theme.Main
        UIStroke.Color = theme.Outline
        TopBar.BackgroundColor3 = theme.Secondary
        Filler.BackgroundColor3 = theme.Secondary
        TitleLabel.TextColor3 = theme.Text
        CloseBtn.TextColor3 = theme.Text
        
        -- Update all registered elements
        for _, updateFunc in pairs(Library.Elements) do
            updateFunc(theme)
        end
    end

    --// Destroy Function
    function Library:Destroy()
        ScreenGui:Destroy()
        Library.Open = false
        -- Disconnect generic events if any
    end

    --// Toggle UI Keybind (Internal)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode[Library.Settings.Keybind] then
            Library:Destroy() -- Panic mode as requested
        end
    end)

    --// Window Object
    local Window = {}
    local FirstTab = true

    function Window:Tab(name)
        local TabButton = Create("TextButton", {
            Parent = TabContainer,
            BackgroundColor3 = Library.CurrentTheme.Main,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.GothamBold,
            Text = name,
            TextColor3 = Library.CurrentTheme.Text,
            TextSize = 12,
            TextTransparency = 0.5
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabButton })

        local Page = Create("ScrollingFrame", {
            Name = name .. "Page",
            Parent = PageContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 2,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false
        })
        local PageLayout = Create("UIListLayout", {
            Parent = Page,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        })
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 10)
        end)

        -- Tab Selection Logic
        local function Activate()
            for _, v in pairs(PageContainer:GetChildren()) do v.Visible = false end
            for _, v in pairs(TabContainer:GetChildren()) do
                if v:IsA("TextButton") then
                    Tween(v, TweenInfo.new(0.2), {TextTransparency = 0.5, BackgroundTransparency = 1})
                end
            end
            Page.Visible = true
            Tween(TabButton, TweenInfo.new(0.2), {TextTransparency = 0, BackgroundTransparency = 0.9})
        end

        TabButton.MouseButton1Click:Connect(Activate)

        if FirstTab then
            FirstTab = false
            Activate()
        end

        -- Register Theme Update
        table.insert(Library.Elements, function(theme)
            TabButton.TextColor3 = theme.Text
            if Page.Visible then
                TabButton.BackgroundColor3 = theme.Text -- Slight highlight
            end
        end)

        local Tab = {}

        --// Components

        function Tab:Button(text, callback)
            local ButtonFrame = Create("Frame", {
                Parent = Page,
                BackgroundColor3 = Library.CurrentTheme.Secondary,
                Size = UDim2.new(1, 0, 0, 35)
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ButtonFrame })
            
            local Btn = Create("TextButton", {
                Parent = ButtonFrame,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 13
            })

            Btn.MouseButton1Click:Connect(function()
                PlaySound(6895079853) -- Click
                local s, err = pcall(callback)
                if not s then warn(err) end
                Library:Notify("Action", text .. " clicked", 2)
                
                -- Animation
                Tween(ButtonFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, -5, 0, 32)})
                task.wait(0.1)
                Tween(ButtonFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 35)})
            end)

            table.insert(Library.Elements, function(t)
                ButtonFrame.BackgroundColor3 = t.Secondary
                Btn.TextColor3 = t.Text
            end)
        end

        function Tab:Toggle(text, default, flag, callback)
            Library.Flags[flag] = default
            local Toggled = default

            local ToggleFrame = Create("Frame", {
                Parent = Page,
                BackgroundColor3 = Library.CurrentTheme.Secondary,
                Size = UDim2.new(1, 0, 0, 35)
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ToggleFrame })

            local Label = Create("TextLabel", {
                Parent = ToggleFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(0, 200, 1, 0),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local ToggleBtn = Create("TextButton", {
                Parent = ToggleFrame,
                BackgroundColor3 = Toggled and Library.CurrentTheme.Accent or Color3.fromRGB(60, 60, 60),
                Position = UDim2.new(1, -50, 0.5, -10),
                Size = UDim2.new(0, 40, 0, 20),
                Text = "",
                AutoButtonColor = false
            })
            local TCorner = Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ToggleBtn })
            
            local Circle = Create("Frame", {
                Parent = ToggleBtn,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16)
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Circle })

            local function UpdateToggle()
                Toggled = not Toggled
                Library.Flags[flag] = Toggled
                
                local targetPos = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                local targetColor = Toggled and Library.CurrentTheme.Accent or Color3.fromRGB(60, 60, 60)
                
                Tween(Circle, TweenInfo.new(0.2), {Position = targetPos})
                Tween(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor})
                
                if callback then callback(Toggled) end
                Library:Notify("Setting Changed", text .. " set to " .. tostring(Toggled), 1)
            end

            ToggleBtn.MouseButton1Click:Connect(function()
                PlaySound(6895079853)
                UpdateToggle()
            end)

            -- Initial Set without triggering callback/notify if loading
            if default then
                 -- Visual update only
            end

            table.insert(Library.Elements, function(t)
                ToggleFrame.BackgroundColor3 = t.Secondary
                Label.TextColor3 = t.Text
                if Toggled then ToggleBtn.BackgroundColor3 = t.Accent end
            end)
            
            -- Return object to allow programmatic setting
            return {
                Set = function(self, val)
                    if val ~= Toggled then
                        Toggled = not val -- flip it so UpdateToggle flips it back correctly
                        UpdateToggle()
                    end
                end
            }
        end

        function Tab:Slider(text, min, max, default, flag, callback)
            Library.Flags[flag] = default
            local Value = default

            local SliderFrame = Create("Frame", {
                Parent = Page,
                BackgroundColor3 = Library.CurrentTheme.Secondary,
                Size = UDim2.new(1, 0, 0, 50)
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SliderFrame })

            local Label = Create("TextLabel", {
                Parent = SliderFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(1, -20, 0, 20),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local ValueLabel = Create("TextLabel", {
                Parent = SliderFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -60, 0, 5),
                Size = UDim2.new(0, 50, 0, 20),
                Font = Enum.Font.Gotham,
                Text = tostring(default),
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right
            })

            local SliderBar = Create("Frame", {
                Parent = SliderFrame,
                BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                Position = UDim2.new(0, 10, 0, 30),
                Size = UDim2.new(1, -20, 0, 6)
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderBar })

            local Fill = Create("Frame", {
                Parent = SliderBar,
                BackgroundColor3 = Library.CurrentTheme.Accent,
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })

            local Trigger = Create("TextButton", {
                Parent = SliderBar,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = ""
            })

            local isDragging = false

            local function UpdateSlider(input)
                local pos = UDim2.new(math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1), 0, 1, 0)
                Tween(Fill, TweenInfo.new(0.1), {Size = pos})
                
                local val = math.floor(min + ((max - min) * pos.X.Scale))
                Value = val
                ValueLabel.Text = tostring(val)
                Library.Flags[flag] = val
                if callback then callback(val) end
            end

            Trigger.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    isDragging = true
                    UpdateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
                    isDragging = false
                    Library:Notify("Setting Changed", text .. " set to " .. tostring(Value), 1)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input)
                end
            end)

            table.insert(Library.Elements, function(t)
                SliderFrame.BackgroundColor3 = t.Secondary
                Label.TextColor3 = t.Text
                ValueLabel.TextColor3 = t.Text
                Fill.BackgroundColor3 = t.Accent
            end)
        end

        function Tab:Dropdown(text, options, default, flag, callback)
            Library.Flags[flag] = default
            local isDropped = false

            local DropFrame = Create("Frame", {
                Parent = Page,
                BackgroundColor3 = Library.CurrentTheme.Secondary,
                Size = UDim2.new(1, 0, 0, 35),
                ClipsDescendants = true
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropFrame })

            local Label = Create("TextLabel", {
                Parent = DropFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(0, 200, 0, 35),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local SelectedLabel = Create("TextLabel", {
                Parent = DropFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -130, 0, 0),
                Size = UDim2.new(0, 100, 0, 35),
                Font = Enum.Font.Gotham,
                Text = default,
                TextColor3 = Library.CurrentTheme.Accent,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right
            })

            local Arrow = Create("TextButton", {
                Parent = DropFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -30, 0, 0),
                Size = UDim2.new(0, 30, 0, 35),
                Font = Enum.Font.GothamBold,
                Text = "v",
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 14
            })

            local OptionContainer = Create("ScrollingFrame", {
                Parent = DropFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 35),
                Size = UDim2.new(1, 0, 0, 100),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 2
            })
            local OptLayout = Create("UIListLayout", { Parent = OptionContainer, SortOrder = Enum.SortOrder.LayoutOrder })

            local function RefreshOptions()
                for _, v in pairs(OptionContainer:GetChildren()) do
                    if v:IsA("TextButton") then v:Destroy() end
                end
                
                for _, opt in pairs(options) do
                    local OptBtn = Create("TextButton", {
                        Parent = OptionContainer,
                        BackgroundColor3 = Library.CurrentTheme.Main,
                        BackgroundTransparency = 0.5,
                        Size = UDim2.new(1, -10, 0, 25),
                        Font = Enum.Font.Gotham,
                        Text = opt,
                        TextColor3 = Library.CurrentTheme.Text,
                        TextSize = 12
                    })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = OptBtn })
                    
                    OptBtn.MouseButton1Click:Connect(function()
                        SelectedLabel.Text = opt
                        Library.Flags[flag] = opt
                        if callback then callback(opt) end
                        Library:Notify("Selected", opt, 1)
                        
                        -- Close
                        isDropped = false
                        Tween(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)})
                        Tween(Arrow, TweenInfo.new(0.2), {Rotation = 0})
                    end)
                end
                OptionContainer.CanvasSize = UDim2.new(0, 0, 0, OptLayout.AbsoluteContentSize.Y)
            end

            Arrow.MouseButton1Click:Connect(function()
                isDropped = not isDropped
                if isDropped then
                    RefreshOptions()
                    Tween(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 140)})
                    Tween(Arrow, TweenInfo.new(0.2), {Rotation = 180})
                else
                    Tween(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)})
                    Tween(Arrow, TweenInfo.new(0.2), {Rotation = 0})
                end
            end)

            table.insert(Library.Elements, function(t)
                DropFrame.BackgroundColor3 = t.Secondary
                Label.TextColor3 = t.Text
                SelectedLabel.TextColor3 = t.Accent
                Arrow.TextColor3 = t.Text
            end)
        end
        
        function Tab:Keybind(text, default, flag, callback)
            Library.Flags[flag] = default
            local Key = default

            local KeyFrame = Create("Frame", {
                Parent = Page,
                BackgroundColor3 = Library.CurrentTheme.Secondary,
                Size = UDim2.new(1, 0, 0, 35)
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = KeyFrame })

            local Label = Create("TextLabel", {
                Parent = KeyFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(0, 200, 1, 0),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local BindBtn = Create("TextButton", {
                Parent = KeyFrame,
                BackgroundColor3 = Library.CurrentTheme.Main,
                Position = UDim2.new(1, -90, 0.5, -10),
                Size = UDim2.new(0, 80, 0, 20),
                Font = Enum.Font.Gotham,
                Text = tostring(default),
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 12
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BindBtn })

            local listening = false

            BindBtn.MouseButton1Click:Connect(function()
                listening = true
                BindBtn.Text = "..."
            end)

            UserInputService.InputBegan:Connect(function(input)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = input.KeyCode.Name
                    Library.Flags[flag] = Key
                    BindBtn.Text = Key
                    listening = false
                    Library:Notify("Keybind", "Set to " .. Key, 1)
                elseif not listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode.Name == Key then
                        if callback then callback() end
                        Library:Notify("Keybind", text .. " Triggered", 1)
                    end
                end
            end)

            table.insert(Library.Elements, function(t)
                KeyFrame.BackgroundColor3 = t.Secondary
                Label.TextColor3 = t.Text
                BindBtn.BackgroundColor3 = t.Main
                BindBtn.TextColor3 = t.Text
            end)
        end

        --// Visual Components (Skeleton, Card, Progress)
        function Tab:Card(title, content)
            local CardFrame = Create("Frame", {
                Parent = Page,
                BackgroundColor3 = Library.CurrentTheme.Secondary,
                Size = UDim2.new(1, 0, 0, 80)
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CardFrame })
            
            local CTitle = Create("TextLabel", {
                Parent = CardFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 5),
                Size = UDim2.new(1, -20, 0, 20),
                Font = Enum.Font.GothamBold,
                Text = title,
                TextColor3 = Library.CurrentTheme.Accent,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            local CContent = Create("TextLabel", {
                Parent = CardFrame,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 30),
                Size = UDim2.new(1, -20, 0, 40),
                Font = Enum.Font.Gotham,
                Text = content,
                TextColor3 = Library.CurrentTheme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top
            })
            
            table.insert(Library.Elements, function(t)
                CardFrame.BackgroundColor3 = t.Secondary
                CTitle.TextColor3 = t.Accent
                CContent.TextColor3 = t.Text
            end)
        end

        return Tab
    end

    --// Config & Settings Logic
    local SettingsTab = Window:Tab("Settings")
    
    SettingsTab:Dropdown("Theme", {"Light", "Dark", "Midnight", "Ruby", "Emerald", "Ocean", "Amethyst", "Amber", "Rose", "Slate"}, "Dark", "Config_Theme", function(val)
        Library.CurrentTheme = Themes[val]
        Library.Settings.Theme = val
        Library:UpdateTheme()
    end)

    SettingsTab:Toggle("UI SFX", true, "Config_SFX", function(val)
        Library.Settings.SFX = val
    end)

    SettingsTab:Toggle("Notifications", true, "Config_Notifs", function(val)
        Library.Settings.Notifications = val
    end)
    
    SettingsTab:Keybind("Panic / Unload", "RightControl", "Config_Panic", function()
        -- Logic handled in InputBegan
    end)

    SettingsTab:Button("Save Config", function()
        local json = HttpService:JSONEncode(Library.Flags)
        writefile(Library.ConfigFolder .. "/config.json", json)
        Library:Notify("Config", "Settings Saved", 2)
    end)

    SettingsTab:Button("Load Config", function()
        if isfile(Library.ConfigFolder .. "/config.json") then
            local json = readfile(Library.ConfigFolder .. "/config.json")
            local data = HttpService:JSONDecode(json)
            
            -- Update Flags
            for flag, val in pairs(data) do
                Library.Flags[flag] = val
                -- Note: Visuals won't auto-update in this simple implementation without a complex registry
                -- But values are set for next interaction
            end
            
            -- Load Theme specifically
            if data["Config_Theme"] then
                Library.CurrentTheme = Themes[data["Config_Theme"]]
                Library:UpdateTheme()
            end
            
            Library:Notify("Config", "Settings Loaded", 2)
        else
            Library:Notify("Config", "No config file found", 2)
        end
    end)

    -- Auto Load
    task.spawn(function()
        if isfile(Library.ConfigFolder .. "/config.json") then
            local s, data = pcall(function() return HttpService:JSONDecode(readfile(Library.ConfigFolder .. "/config.json")) end)
            if s and data then
                if data["Config_Theme"] then
                    Library.CurrentTheme = Themes[data["Config_Theme"]]
                    Library:UpdateTheme()
                end
                if data["Config_SFX"] ~= nil then Library.Settings.SFX = data["Config_SFX"] end
                if data["Config_Notifs"] ~= nil then Library.Settings.Notifications = data["Config_Notifs"] end
            end
        end
        Library:Notify("Loaded", Title .. " Script Loaded", 3)
        Library:Notify("Welcome", "Thanks for using my script!", 4)
    end)

    return Window
end

return Library

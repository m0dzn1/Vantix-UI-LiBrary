local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Library = {}
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// Signals
Library.OnUnload = Instance.new("BindableEvent")

--// File System Safety
local writefile = writefile or function(...) end
local readfile = readfile or function(...) end
local isfile = isfile or function(...) return false end
local isfolder = isfolder or function(...) return false end
local makefolder = makefolder or function(...) end
local listfiles = listfiles or function(...) return {} end

--// UI Parent Check
local function GetParent()
    local success, result = pcall(function() return game:GetService("CoreGui") end)
    if success then return result end
    return LocalPlayer:WaitForChild("PlayerGui")
end

--// Themes
local Themes = {
    Modern = {
        Main = Color3.fromRGB(20, 20, 25),
        Sidebar = Color3.fromRGB(15, 15, 20),
        Content = Color3.fromRGB(20, 20, 25),
        Text = Color3.fromRGB(240, 240, 240),
        TextDark = Color3.fromRGB(140, 140, 140),
        Accent = Color3.fromRGB(90, 100, 240), -- Vibrant Blurple
        Outline = Color3.fromRGB(40, 40, 45),
        Separator = Color3.fromRGB(35, 35, 40),
        Element = Color3.fromRGB(25, 25, 30),
        Hover = Color3.fromRGB(35, 35, 40)
    }
}

Library.Theme = Themes.Modern
Library.Flags = {}
Library.FolderName = "ModernUIConfig"
Library.IsVisible = true
Library.Settings = {SFX = true, Notifications = true}
Library.Elements = {} 
Library.Connections = {} -- Store connections to disconnect on unload

--// Utility
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local function Tween(inst, info, props)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function PlaySound(id)
    if Library.Settings.SFX then
        local s = Create("Sound", {SoundId = "rbxassetid://"..id, Parent = GetParent(), Volume = 1})
        s:Play(); s.Ended:Connect(function() s:Destroy() end)
    end
end

--// Notification System
local NotifHolder = Create("Frame", {
    Name = "ModernUI_Notifications", Parent = GetParent(), BackgroundTransparency = 1,
    Position = UDim2.new(1, -20, 1, -20), Size = UDim2.new(0, 300, 1, 0),
    AnchorPoint = Vector2.new(1, 1), ZIndex = 1000
})
local NotifLayout = Create("UIListLayout", {
    Parent = NotifHolder, SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8)
})

function Library:Notify(title, text, duration)
    if not Library.Settings.Notifications then return end
    
    local NFrame = Create("Frame", {
        Parent = NotifHolder, BackgroundColor3 = Library.Theme.Sidebar,
        Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, BorderSizePixel = 0
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = NFrame })
    Create("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = NFrame })
    
    local NBar = Create("Frame", {
        Parent = NFrame, BackgroundColor3 = Library.Theme.Accent,
        Size = UDim2.new(0, 3, 1, 0)
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = NBar })

    local NTitle = Create("TextLabel", {
        Parent = NFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 8),
        Size = UDim2.new(1, -20, 0, 15), Font = Enum.Font.GothamBold,
        Text = title, TextColor3 = Library.Theme.Accent, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local NText = Create("TextLabel", {
        Parent = NFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 25),
        Size = UDim2.new(1, -20, 0, 15), Font = Enum.Font.Gotham,
        Text = text, TextColor3 = Library.Theme.Text, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true
    })

    Tween(NFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 50)})
    PlaySound(4590657391)
    
    task.delay(duration or 3, function()
        if not NFrame.Parent then return end
        local t = Tween(NFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)})
        t.Completed:Wait()
        NFrame:Destroy()
    end)
end

--// Main Window
function Library:CreateWindow(options)
    local Title = options.Name or "UI Library"
    Library.FolderName = options.ConfigFolder or "MyScriptConfig"
    if not isfolder(Library.FolderName) then makefolder(Library.FolderName) end

    local ScreenGui = Create("ScreenGui", { Name = Title, Parent = GetParent(), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    
    local MainScale = Create("Frame", {
        Name = "MainScale", Parent = ScreenGui, BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -325, 0.5, -225), Size = UDim2.new(0, 650, 0, 450)
    })

    local MainFrame = Create("Frame", {
        Name = "MainFrame", Parent = MainScale, BackgroundColor3 = Library.Theme.Main,
        Size = UDim2.new(1, 0, 1, 0), ClipsDescendants = true
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainFrame })
    local MainStroke = Create("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = MainFrame })

    -- Dragging
    local dragging, dragInput, dragStart, startPos
    table.insert(Library.Connections, MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = MainScale.Position
        end
    end))
    table.insert(Library.Connections, MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end))
    table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(MainScale, TweenInfo.new(0.05), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)})
        end
    end))
    table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))

    --// Sidebar
    local Sidebar = Create("Frame", {
        Name = "Sidebar", Parent = MainFrame, BackgroundColor3 = Library.Theme.Sidebar,
        Size = UDim2.new(0, 180, 1, 0), BorderSizePixel = 0
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Sidebar })
    Create("Frame", { Parent = Sidebar, BackgroundColor3 = Library.Theme.Sidebar, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BorderSizePixel = 0 })

    -- Title
    local TitleLabel = Create("TextLabel", {
        Parent = Sidebar, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -15, 0, 50), Font = Enum.Font.GothamBold,
        Text = Title, TextColor3 = Library.Theme.Text, TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    Create("Frame", { Parent = Sidebar, BackgroundColor3 = Library.Theme.Separator, Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(1, -20, 0, 1), BorderSizePixel = 0 })

    -- Tab Container
    local TabContainer = Create("ScrollingFrame", {
        Name = "TabContainer", Parent = Sidebar, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 55), Size = UDim2.new(1, 0, 1, -165),
        CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0
    })
    local TabLayout = Create("UIListLayout", { Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })
    Create("UIPadding", { Parent = TabContainer, PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 10) })

    Create("Frame", { Parent = Sidebar, BackgroundColor3 = Library.Theme.Separator, Position = UDim2.new(0, 10, 1, -110), Size = UDim2.new(1, -20, 0, 1), BorderSizePixel = 0 })

    -- Bottom Container
    local BottomContainer = Create("Frame", {
        Parent = Sidebar, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 1, -105), Size = UDim2.new(1, 0, 0, 60)
    })
    local BottomLayout = Create("UIListLayout", { Parent = BottomContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center })

    -- Profile
    local ProfileFrame = Create("Frame", {
        Parent = Sidebar, BackgroundColor3 = Library.Theme.Main,
        Position = UDim2.new(0, 0, 1, -45), Size = UDim2.new(1, 0, 0, 45), BorderSizePixel = 0
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ProfileFrame })
    
    local ProfileImg = Create("ImageLabel", {
        Parent = ProfileFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(0, 29, 0, 29), Image = "rbxassetid://0"
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ProfileImg })
    
    task.spawn(function()
        local s, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
        if s then ProfileImg.Image = img end
    end)

    local DisplayName = Create("TextLabel", {
        Parent = ProfileFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 45, 0, 5),
        Size = UDim2.new(1, -50, 0, 15), Font = Enum.Font.GothamBold,
        Text = LocalPlayer.DisplayName, TextColor3 = Library.Theme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
    })
    local UserName = Create("TextLabel", {
        Parent = ProfileFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 45, 0, 20),
        Size = UDim2.new(1, -50, 0, 15), Font = Enum.Font.Gotham,
        Text = "@" .. LocalPlayer.Name, TextColor3 = Library.Theme.TextDark, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Content
    local Content = Create("Frame", {
        Parent = MainFrame, BackgroundColor3 = Library.Theme.Content,
        Position = UDim2.new(0, 180, 0, 0), Size = UDim2.new(1, -180, 1, 0), BorderSizePixel = 0
    })

    -- Close / Panic Button
    local CloseBtn = Create("TextButton", {
        Parent = MainFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -30, 0, 10),
        Size = UDim2.new(0, 20, 0, 20), Font = Enum.Font.GothamBold,
        Text = "X", TextColor3 = Library.Theme.TextDark, TextSize = 14, ZIndex = 5
    })
    
    --// Panic Logic
    function Library:Unload()
        Library.OnUnload:Fire() -- Signal user script to reset
        for _, conn in pairs(Library.Connections) do conn:Disconnect() end
        ScreenGui:Destroy()
        NotifHolder:Destroy()
        Library.Open = false
    end
    
    CloseBtn.MouseButton1Click:Connect(function() Library:Unload() end)

    function Library:ToggleUI()
        Library.IsVisible = not Library.IsVisible
        if Library.IsVisible then
            MainScale.Visible = true
            Tween(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 650, 0, 450)})
        else
            local t = Tween(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
            t.Completed:Connect(function() if not Library.IsVisible then MainScale.Visible = false end end)
        end
    end

    --// Tab System
    local Window = {}
    local FirstTab = true

    function Window:Tab(name, isBottom)
        local Page = Create("ScrollingFrame", {
            Name = name.."Page", Parent = Content, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false
        })
        local PageLayout = Create("UIListLayout", { Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
        Create("UIPadding", { Parent = Page, PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20) })

        local ParentContainer = isBottom and BottomContainer or TabContainer
        local TabBtn = Create("TextButton", {
            Parent = ParentContainer, BackgroundTransparency = 1,
            Size = UDim2.new(isBottom and 0.9 or 1, isBottom and 0 or -10, 0, 25),
            Font = Enum.Font.GothamBold, Text = isBottom and name or "  "..name,
            TextColor3 = Library.Theme.TextDark, TextSize = 13,
            TextXAlignment = isBottom and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        })
        if not isBottom then Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = TabBtn }) end

        local function Activate()
            for _, v in pairs(Content:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _, v in pairs(TabContainer:GetChildren()) do if v:IsA("TextButton") then Tween(v, TweenInfo.new(0.2), {TextColor3 = Library.Theme.TextDark, BackgroundTransparency = 1}) end end
            for _, v in pairs(BottomContainer:GetChildren()) do if v:IsA("TextButton") then Tween(v, TweenInfo.new(0.2), {TextColor3 = Library.Theme.TextDark}) end end
            
            Page.Visible = true
            Tween(TabBtn, TweenInfo.new(0.2), {TextColor3 = Library.Theme.Accent, BackgroundTransparency = isBottom and 1 or 0.95, BackgroundColor3 = Library.Theme.Accent})
        end

        TabBtn.MouseButton1Click:Connect(Activate)
        if FirstTab and not isBottom then FirstTab = false; Activate() end

        local Tab = {}

        --// Components
        function Tab:Button(text, callback)
            local Frame = Create("Frame", { Parent = Page, BackgroundColor3 = Library.Theme.Element, Size = UDim2.new(1, 0, 0, 35) })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Frame })
            Create("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = Frame })
            local Btn = Create("TextButton", { Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.Theme.Text, TextSize = 13 })
            
            Btn.MouseButton1Click:Connect(function()
                PlaySound(6895079853)
                Tween(Frame, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme.Hover})
                task.delay(0.1, function() Tween(Frame, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme.Element}) end)
                Library:Notify("Button", text, "")
                pcall(callback)
            end)
        end

        function Tab:Toggle(text, default, keybind, flag, callback)
            Library.Flags[flag] = default
            local Toggled = default
            local Key = keybind or nil

            local Frame = Create("Frame", { Parent = Page, BackgroundColor3 = Library.Theme.Element, Size = UDim2.new(1, 0, 0, 35) })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Frame })
            Create("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = Frame })
            
            local Label = Create("TextLabel", { Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -80, 1, 0), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
            
            local Switch = Create("Frame", { Parent = Frame, BackgroundColor3 = Toggled and Library.Theme.Accent or Color3.fromRGB(50,50,50), Position = UDim2.new(1, -45, 0.5, -10), Size = UDim2.new(0, 35, 0, 20) })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Switch })
            local Circle = Create("Frame", { Parent = Switch, BackgroundColor3 = Color3.new(1,1,1), Position = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Circle })
            local Trigger = Create("TextButton", { Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "" })
            local KeyLabel = Create("TextButton", { Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(1, -70, 0, 0), Size = UDim2.new(0, 20, 1, 0), Font = Enum.Font.GothamBold, Text = Key and "["..Key.."]" or "", TextColor3 = Library.Theme.TextDark, TextSize = 11 })

            local function Update()
                Toggled = not Toggled
                Library.Flags[flag] = Toggled
                Tween(Circle, TweenInfo.new(0.2), {Position = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
                Tween(Switch, TweenInfo.new(0.2), {BackgroundColor3 = Toggled and Library.Theme.Accent or Color3.fromRGB(50,50,50)})
                Library:Notify("Toggle", text, Toggled)
                if callback then callback(Toggled) end
            end

            Trigger.MouseButton1Click:Connect(function() PlaySound(6895079853); Update() end)

            local listening = false
            KeyLabel.MouseButton1Click:Connect(function() listening = true; KeyLabel.Text = "..." end)
            table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = input.KeyCode.Name; KeyLabel.Text = "["..Key.."]"; listening = false
                    Library:Notify("Keybind", text, Key)
                elseif not listening and input.UserInputType == Enum.UserInputType.Keyboard and Key and input.KeyCode.Name == Key then
                    Update()
                end
            end))

            if default then callback(true) end
        end

        function Tab:Slider(text, min, max, default, flag, callback)
            Library.Flags[flag] = default
            local Frame = Create("Frame", { Parent = Page, BackgroundColor3 = Library.Theme.Element, Size = UDim2.new(1, 0, 0, 50) })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Frame })
            Create("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = Frame })
            
            local Label = Create("TextLabel", { Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
            local ValLabel = Create("TextLabel", { Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(1, -60, 0, 5), Size = UDim2.new(0, 50, 0, 20), Font = Enum.Font.Gotham, Text = tostring(default), TextColor3 = Library.Theme.TextDark, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
            local Bar = Create("Frame", { Parent = Frame, BackgroundColor3 = Color3.fromRGB(40,40,45), Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 6) })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Bar })
            local Fill = Create("Frame", { Parent = Bar, BackgroundColor3 = Library.Theme.Accent, Size = UDim2.new((default-min)/(max-min), 0, 1, 0) })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })
            local Trigger = Create("TextButton", { Parent = Bar, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "" })

            local dragging = false
            local function Update(input)
                local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + ((max - min) * pos))
                Tween(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos, 0, 1, 0)})
                ValLabel.Text = tostring(val)
                Library.Flags[flag] = val
                if callback then callback(val) end
            end
            
            table.insert(Library.Connections, Trigger.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; Update(i) end end))
            table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 and dragging then dragging = false; Library:Notify("Slider", text, Library.Flags[flag]) end end))
            table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end end))
        end

        function Tab:Dropdown(text, options, default, flag, callback)
            Library.Flags[flag] = default
            local Dropped = false
            local Frame = Create("Frame", { Parent = Page, BackgroundColor3 = Library.Theme.Element, Size = UDim2.new(1, 0, 0, 35), ClipsDescendants = true, ZIndex = 2 })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Frame })
            Create("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = Frame })
            
            local Label = Create("TextLabel", { Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 150, 0, 35), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
            local Selected = Create("TextLabel", { Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(1, -140, 0, 0), Size = UDim2.new(0, 110, 0, 35), Font = Enum.Font.Gotham, Text = default, TextColor3 = Library.Theme.Accent, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
            local Arrow = Create("TextLabel", { Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(1, -25, 0, 0), Size = UDim2.new(0, 25, 0, 35), Font = Enum.Font.GothamBold, Text = "v", TextColor3 = Library.Theme.Text, TextSize = 14 })
            local Trigger = Create("TextButton", { Parent = Frame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), Text = "" })
            local List = Create("ScrollingFrame", { Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 35), Size = UDim2.new(1, 0, 0, 100), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y })
            Create("UIListLayout", { Parent = List, SortOrder = Enum.SortOrder.LayoutOrder })

            local function Refresh(opts)
                for _, v in pairs(List:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                for _, opt in pairs(opts) do
                    local Btn = Create("TextButton", { Parent = List, BackgroundColor3 = Library.Theme.Main, BackgroundTransparency = 0.5, Size = UDim2.new(1, -10, 0, 25), Font = Enum.Font.Gotham, Text = opt, TextColor3 = Library.Theme.Text, TextSize = 12 })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Btn })
                    Btn.MouseButton1Click:Connect(function()
                        Selected.Text = opt; Library.Flags[flag] = opt; Dropped = false
                        Tween(Frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}); Tween(Arrow, TweenInfo.new(0.2), {Rotation = 0})
                        Library:Notify("Dropdown", text, opt); if callback then callback(opt) end
                    end)
                end
            end
            Refresh(options)
            Trigger.MouseButton1Click:Connect(function() Dropped = not Dropped; Tween(Frame, TweenInfo.new(0.2), {Size = Dropped and UDim2.new(1, 0, 0, 140) or UDim2.new(1, 0, 0, 35)}); Tween(Arrow, TweenInfo.new(0.2), {Rotation = Dropped and 180 or 0}) end)
        end

        function Tab:Input(text, placeholder, flag, callback)
            Library.Flags[flag] = ""
            local Frame = Create("Frame", { Parent = Page, BackgroundColor3 = Library.Theme.Element, Size = UDim2.new(1, 0, 0, 35) })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Frame })
            Create("UIStroke", { Color = Library.Theme.Outline, Thickness = 1, Parent = Frame })
            local Label = Create("TextLabel", { Parent = Frame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 100, 1, 0), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
            local Box = Create("TextBox", { Parent = Frame, BackgroundColor3 = Library.Theme.Main, Position = UDim2.new(1, -160, 0.5, -12), Size = UDim2.new(0, 150, 0, 24), Font = Enum.Font.Gotham, Text = "", PlaceholderText = placeholder, TextColor3 = Library.Theme.Text, TextSize = 12 })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Box })
            Box.FocusLost:Connect(function() Library.Flags[flag] = Box.Text; Library:Notify("Input", text, Box.Text); if callback then callback(Box.Text) end end)
        end

        return Tab
    end

    --// Forced Tabs
    local ConfigTab = Window:Tab("Config", true)
    local SettingsTab = Window:Tab("Settings", true)

    -- Config Logic
    local ConfigName = ""
    ConfigTab:Input("Config Name", "Type name...", "CfgName", function(v) ConfigName = v end)
    
    local ConfigList = {}
    local function RefreshConfigs()
        ConfigList = {}
        if isfolder(Library.FolderName) then
            for _, file in pairs(listfiles(Library.FolderName)) do
                if file:sub(-5) == ".json" then table.insert(ConfigList, file:match("([^/]+)%.json$")) end
            end
        end
    end
    RefreshConfigs()

    ConfigTab:Dropdown("Select Config", ConfigList, "None", "CfgSelect", function(v) ConfigName = v end)
    ConfigTab:Button("Save Config", function()
        if ConfigName == "" then return end
        writefile(Library.FolderName.."/"..ConfigName..".json", HttpService:JSONEncode(Library.Flags))
        RefreshConfigs()
        Library:Notify("System", "Saved Config", ConfigName)
    end)
    ConfigTab:Button("Load Config", function()
        if isfile(Library.FolderName.."/"..ConfigName..".json") then
            local data = HttpService:JSONDecode(readfile(Library.FolderName.."/"..ConfigName..".json"))
            for k,v in pairs(data) do Library.Flags[k] = v end
            Library:Notify("System", "Loaded Config", ConfigName)
        end
    end)
    ConfigTab:Button("Refresh List", RefreshConfigs)

    -- Settings Logic
    SettingsTab:Toggle("SFX", true, nil, "SFX", function(v) Library.Settings.SFX = v end)
    SettingsTab:Toggle("Notifications", true, nil, "Notifs", function(v) Library.Settings.Notifications = v end)
    
    return Window
end

return Library

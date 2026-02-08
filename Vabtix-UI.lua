--[[ 
    Modern UI Library - Standalone (Fixed & Optimized)
    - Fixed Profile Loading
    - Fixed Scrolling (AutomaticCanvasSize)
    - Removed "Temp" hack (Clean Component System)
    - Smooth Animations
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Library = {}
local LocalPlayer = Players.LocalPlayer

--// File System Safety
local writefile = writefile or function(...) end
local readfile = readfile or function(...) end
local isfile = isfile or function(...) return false end
local isfolder = isfolder or function(...) return false end
local makefolder = makefolder or function(...) end
local listfiles = listfiles or function(...) return {} end

--// Themes
local Themes = {
    Light = { Main = Color3.fromRGB(240, 240, 240), Secondary = Color3.fromRGB(255, 255, 255), Text = Color3.fromRGB(20, 20, 20), Accent = Color3.fromRGB(0, 122, 255), Outline = Color3.fromRGB(200, 200, 200) },
    Dark = { Main = Color3.fromRGB(25, 25, 25), Secondary = Color3.fromRGB(35, 35, 35), Text = Color3.fromRGB(240, 240, 240), Accent = Color3.fromRGB(60, 130, 240), Outline = Color3.fromRGB(50, 50, 50) },
    Midnight = { Main = Color3.fromRGB(0, 0, 0), Secondary = Color3.fromRGB(15, 15, 15), Text = Color3.fromRGB(255, 255, 255), Accent = Color3.fromRGB(90, 90, 90), Outline = Color3.fromRGB(30, 30, 30) },
    Ruby = { Main = Color3.fromRGB(20, 10, 10), Secondary = Color3.fromRGB(30, 15, 15), Text = Color3.fromRGB(255, 230, 230), Accent = Color3.fromRGB(220, 40, 40), Outline = Color3.fromRGB(60, 20, 20) },
    Emerald = { Main = Color3.fromRGB(10, 20, 10), Secondary = Color3.fromRGB(15, 30, 15), Text = Color3.fromRGB(230, 255, 230), Accent = Color3.fromRGB(40, 220, 80), Outline = Color3.fromRGB(20, 60, 20) },
    Ocean = { Main = Color3.fromRGB(10, 15, 30), Secondary = Color3.fromRGB(20, 30, 50), Text = Color3.fromRGB(230, 240, 255), Accent = Color3.fromRGB(40, 140, 240), Outline = Color3.fromRGB(30, 50, 80) },
}

--// State
Library.CurrentTheme = Themes.Dark
Library.Flags = {}
Library.Elements = {} -- For theme updates
Library.FolderName = "MyScriptConfig"
Library.IsVisible = true
Library.Settings = { Theme = "Dark", SFX = true, Notifications = true, ToggleKey = Enum.KeyCode.RightControl }

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
        local s = Create("Sound", { SoundId = "rbxassetid://"..id, Parent = CoreGui, Volume = 1 })
        s:Play(); s.Ended:Connect(function() s:Destroy() end)
    end
end

--// Component System (Shared Logic)
function Library:RegisterComponents(TabObject, PageFrame)
    
    function TabObject:Button(text, callback)
        local BtnFrame = Create("Frame", { Parent = PageFrame, BackgroundColor3 = Library.CurrentTheme.Secondary, Size = UDim2.new(1, 0, 0, 35) })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = BtnFrame })
        local Btn = Create("TextButton", { Parent = BtnFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.CurrentTheme.Text, TextSize = 13 })
        
        Btn.MouseButton1Click:Connect(function()
            PlaySound(6895079853)
            Tween(BtnFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, -4, 0, 32)})
            task.wait(0.1)
            Tween(BtnFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 35)})
            pcall(callback)
        end)
        table.insert(Library.Elements, function(t) BtnFrame.BackgroundColor3 = t.Secondary; Btn.TextColor3 = t.Text end)
    end

    function TabObject:Toggle(text, default, flag, callback)
        Library.Flags[flag] = default
        local Toggled = default
        local ToggleFrame = Create("Frame", { Parent = PageFrame, BackgroundColor3 = Library.CurrentTheme.Secondary, Size = UDim2.new(1, 0, 0, 35) })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ToggleFrame })
        local Label = Create("TextLabel", { Parent = ToggleFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -60, 1, 0), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
        local Switch = Create("Frame", { Parent = ToggleFrame, BackgroundColor3 = Toggled and Library.CurrentTheme.Accent or Color3.fromRGB(60,60,60), Position = UDim2.new(1, -50, 0.5, -10), Size = UDim2.new(0, 40, 0, 20) })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Switch })
        local Circle = Create("Frame", { Parent = Switch, BackgroundColor3 = Color3.new(1,1,1), Position = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), Size = UDim2.new(0, 16, 0, 16) })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Circle })
        local Btn = Create("TextButton", { Parent = ToggleFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "" })

        local function Update()
            Toggled = not Toggled
            Library.Flags[flag] = Toggled
            Tween(Circle, TweenInfo.new(0.2), {Position = Toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
            Tween(Switch, TweenInfo.new(0.2), {BackgroundColor3 = Toggled and Library.CurrentTheme.Accent or Color3.fromRGB(60,60,60)})
            if callback then callback(Toggled) end
        end
        Btn.MouseButton1Click:Connect(function() PlaySound(6895079853); Update() end)
        
        local obj = { Set = function(self, val) if val ~= Toggled then Toggled = not val; Update() end end }
        Library.Flags[flag.."_Object"] = obj
        table.insert(Library.Elements, function(t) ToggleFrame.BackgroundColor3 = t.Secondary; Label.TextColor3 = t.Text; if Toggled then Switch.BackgroundColor3 = t.Accent end end)
        return obj
    end

    function TabObject:Slider(text, min, max, default, flag, callback)
        Library.Flags[flag] = default
        local SliderFrame = Create("Frame", { Parent = PageFrame, BackgroundColor3 = Library.CurrentTheme.Secondary, Size = UDim2.new(1, 0, 0, 50) })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SliderFrame })
        local Label = Create("TextLabel", { Parent = SliderFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
        local ValLabel = Create("TextLabel", { Parent = SliderFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -60, 0, 5), Size = UDim2.new(0, 50, 0, 20), Font = Enum.Font.Gotham, Text = tostring(default), TextColor3 = Library.CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
        local Bar = Create("Frame", { Parent = SliderFrame, BackgroundColor3 = Color3.fromRGB(60,60,60), Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 6) })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Bar })
        local Fill = Create("Frame", { Parent = Bar, BackgroundColor3 = Library.CurrentTheme.Accent, Size = UDim2.new((default-min)/(max-min), 0, 1, 0) })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })
        local Btn = Create("TextButton", { Parent = Bar, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "" })

        local dragging = false
        local function Update(input)
            local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + ((max - min) * pos))
            Tween(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos, 0, 1, 0)})
            ValLabel.Text = tostring(val)
            Library.Flags[flag] = val
            if callback then callback(val) end
        end
        Btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; Update(i) end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
        UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then Update(i) end end)

        local obj = { Set = function(self, val) 
            local pos = (val - min) / (max - min)
            Tween(Fill, TweenInfo.new(0.1), {Size = UDim2.new(pos, 0, 1, 0)})
            ValLabel.Text = tostring(val)
            Library.Flags[flag] = val
            if callback then callback(val) end
        end }
        Library.Flags[flag.."_Object"] = obj
        table.insert(Library.Elements, function(t) SliderFrame.BackgroundColor3 = t.Secondary; Label.TextColor3 = t.Text; ValLabel.TextColor3 = t.Text; Fill.BackgroundColor3 = t.Accent end)
        return obj
    end

    function TabObject:Dropdown(text, options, default, flag, callback)
        Library.Flags[flag] = default
        local Dropped = false
        local DropFrame = Create("Frame", { Parent = PageFrame, BackgroundColor3 = Library.CurrentTheme.Secondary, Size = UDim2.new(1, 0, 0, 35), ClipsDescendants = true, ZIndex = 2 })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropFrame })
        local Label = Create("TextLabel", { Parent = DropFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 150, 0, 35), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
        local Selected = Create("TextLabel", { Parent = DropFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -140, 0, 0), Size = UDim2.new(0, 110, 0, 35), Font = Enum.Font.Gotham, Text = default, TextColor3 = Library.CurrentTheme.Accent, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right })
        local Arrow = Create("TextLabel", { Parent = DropFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -25, 0, 0), Size = UDim2.new(0, 25, 0, 35), Font = Enum.Font.GothamBold, Text = "v", TextColor3 = Library.CurrentTheme.Text, TextSize = 14 })
        local Btn = Create("TextButton", { Parent = DropFrame, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 35), Text = "" })
        
        local List = Create("ScrollingFrame", { Parent = DropFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 35), Size = UDim2.new(1, 0, 0, 100), CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y })
        local ListLayout = Create("UIListLayout", { Parent = List, SortOrder = Enum.SortOrder.LayoutOrder })

        local function Refresh(opts)
            for _, v in pairs(List:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            for _, opt in pairs(opts) do
                local OBtn = Create("TextButton", { Parent = List, BackgroundColor3 = Library.CurrentTheme.Main, BackgroundTransparency = 0.5, Size = UDim2.new(1, -10, 0, 25), Font = Enum.Font.Gotham, Text = opt, TextColor3 = Library.CurrentTheme.Text, TextSize = 12 })
                Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = OBtn })
                OBtn.MouseButton1Click:Connect(function()
                    Selected.Text = opt; Library.Flags[flag] = opt; if callback then callback(opt) end
                    Dropped = false; Tween(DropFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}); Tween(Arrow, TweenInfo.new(0.2), {Rotation = 0})
                end)
            end
        end
        Refresh(options)

        Btn.MouseButton1Click:Connect(function()
            Dropped = not Dropped
            Tween(DropFrame, TweenInfo.new(0.2), {Size = Dropped and UDim2.new(1, 0, 0, 140) or UDim2.new(1, 0, 0, 35)})
            Tween(Arrow, TweenInfo.new(0.2), {Rotation = Dropped and 180 or 0})
        end)

        local obj = { Refresh = function(self, newOpts) Refresh(newOpts) end }
        Library.Flags[flag.."_Object"] = obj
        table.insert(Library.Elements, function(t) DropFrame.BackgroundColor3 = t.Secondary; Label.TextColor3 = t.Text; Selected.TextColor3 = t.Accent; Arrow.TextColor3 = t.Text end)
        return obj
    end

    function TabObject:Input(text, placeholder, flag, callback)
        Library.Flags[flag] = ""
        local InputFrame = Create("Frame", { Parent = PageFrame, BackgroundColor3 = Library.CurrentTheme.Secondary, Size = UDim2.new(1, 0, 0, 35) })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = InputFrame })
        local Label = Create("TextLabel", { Parent = InputFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 100, 1, 0), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
        local Box = Create("TextBox", { Parent = InputFrame, BackgroundColor3 = Library.CurrentTheme.Main, Position = UDim2.new(1, -160, 0.5, -12), Size = UDim2.new(0, 150, 0, 24), Font = Enum.Font.Gotham, Text = "", PlaceholderText = placeholder, TextColor3 = Library.CurrentTheme.Text, TextSize = 12 })
        Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Box })

        Box.FocusLost:Connect(function()
            Library.Flags[flag] = Box.Text
            if callback then callback(Box.Text) end
        end)
        table.insert(Library.Elements, function(t) InputFrame.BackgroundColor3 = t.Secondary; Label.TextColor3 = t.Text; Box.BackgroundColor3 = t.Main; Box.TextColor3 = t.Text end)
    end

    function TabObject:Keybind(text, default, flag, callback)
        Library.Flags[flag] = default
        local Key = default
        local KeyFrame = Create("Frame", { Parent = PageFrame, BackgroundColor3 = Library.CurrentTheme.Secondary, Size = UDim2.new(1, 0, 0, 35) })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = KeyFrame })
        local Label = Create("TextLabel", { Parent = KeyFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -100, 1, 0), Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
        local BindBtn = Create("TextButton", { Parent = KeyFrame, BackgroundColor3 = Library.CurrentTheme.Main, Position = UDim2.new(1, -90, 0.5, -10), Size = UDim2.new(0, 80, 0, 20), Font = Enum.Font.Gotham, Text = tostring(default), TextColor3 = Library.CurrentTheme.Text, TextSize = 12 })
        Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BindBtn })

        local listening = false
        BindBtn.MouseButton1Click:Connect(function() listening = true; BindBtn.Text = "..." end)
        UserInputService.InputBegan:Connect(function(input)
            if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                Key = input.KeyCode.Name; Library.Flags[flag] = Key; BindBtn.Text = Key; listening = false
                Library:Notify("Keybind", "Set to "..Key, 1)
            elseif not listening and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Key then
                if callback then callback() end
            end
        end)
        table.insert(Library.Elements, function(t) KeyFrame.BackgroundColor3 = t.Secondary; Label.TextColor3 = t.Text; BindBtn.BackgroundColor3 = t.Main; BindBtn.TextColor3 = t.Text end)
    end

    function TabObject:Card(title, content)
        local Card = Create("Frame", { Parent = PageFrame, BackgroundColor3 = Library.CurrentTheme.Secondary, Size = UDim2.new(1, 0, 0, 80) })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Card })
        Create("TextLabel", { Parent = Card, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20), Font = Enum.Font.GothamBold, Text = title, TextColor3 = Library.CurrentTheme.Accent, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
        Create("TextLabel", { Parent = Card, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 30), Size = UDim2.new(1, -20, 0, 40), Font = Enum.Font.Gotham, Text = content, TextColor3 = Library.CurrentTheme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
        table.insert(Library.Elements, function(t) Card.BackgroundColor3 = t.Secondary end)
    end
end

--// Main Window
function Library:CreateWindow(options)
    local Title = options.Name or "UI Library"
    Library.FolderName = options.ConfigFolder or "MyScriptConfig"
    
    if not isfolder(Library.FolderName) then makefolder(Library.FolderName) end

    local ScreenGui = Create("ScreenGui", { Name = Title, Parent = CoreGui, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false })
    
    local MainScale = Create("Frame", {
        Name = "MainScale", Parent = ScreenGui, BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -350, 0.5, -225), Size = UDim2.new(0, 700, 0, 450)
    })

    local MainFrame = Create("Frame", {
        Name = "MainFrame", Parent = MainScale, BackgroundColor3 = Library.CurrentTheme.Main,
        Size = UDim2.new(1, 0, 1, 0), ClipsDescendants = true
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
    local UIStroke = Create("UIStroke", { Color = Library.CurrentTheme.Outline, Thickness = 1, Parent = MainFrame })

    -- Dragging
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = MainScale.Position
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(MainScale, TweenInfo.new(0.05), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)})
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Sidebar
    local Sidebar = Create("Frame", {
        Name = "Sidebar", Parent = MainFrame, BackgroundColor3 = Library.CurrentTheme.Secondary,
        Size = UDim2.new(0, 180, 1, 0), ZIndex = 2
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Sidebar })
    Create("Frame", { Parent = Sidebar, BackgroundColor3 = Library.CurrentTheme.Secondary, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BorderSizePixel = 0 })

    local SidebarTitle = Create("TextLabel", {
        Parent = Sidebar, BackgroundTransparency = 1, Position = UDim2.new(0, 15, 0, 15), Size = UDim2.new(1, -30, 0, 30),
        Font = Enum.Font.GothamBold, Text = Title, TextColor3 = Library.CurrentTheme.Text, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Tab Container
    local TabScroll = Create("ScrollingFrame", {
        Parent = Sidebar, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 60), Size = UDim2.new(1, 0, 1, -130),
        CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    local TabLayout = Create("UIListLayout", { Parent = TabScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })
    Create("UIPadding", { Parent = TabScroll, PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 10) })

    local BottomTabHolder = Create("Frame", {
        Parent = Sidebar, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 1, -125), Size = UDim2.new(1, -20, 0, 70)
    })
    local BottomLayout = Create("UIListLayout", { Parent = BottomTabHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })

    -- User Profile (Fixed)
    local ProfileFrame = Create("Frame", {
        Parent = Sidebar, BackgroundColor3 = Library.CurrentTheme.Main, Position = UDim2.new(0, 10, 1, -50), Size = UDim2.new(1, -20, 0, 40)
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ProfileFrame })
    
    local ProfileImg = Create("ImageLabel", {
        Parent = ProfileFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 5, 0, 5), Size = UDim2.new(0, 30, 0, 30),
        Image = "rbxassetid://0" -- Placeholder
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ProfileImg })

    -- Async Load Profile
    task.spawn(function()
        local s, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
        if s then ProfileImg.Image = img end
    end)

    local DisplayName = Create("TextLabel", {
        Parent = ProfileFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 40, 0, 2), Size = UDim2.new(1, -45, 0, 18),
        Font = Enum.Font.GothamBold, Text = LocalPlayer.DisplayName, TextColor3 = Library.CurrentTheme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left
    })
    local UserName = Create("TextLabel", {
        Parent = ProfileFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 40, 0, 20), Size = UDim2.new(1, -45, 0, 15),
        Font = Enum.Font.Gotham, Text = "@" .. LocalPlayer.Name, TextColor3 = Library.CurrentTheme.Accent, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left
    })

    local ContentArea = Create("Frame", {
        Parent = MainFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 190, 0, 0), Size = UDim2.new(1, -190, 1, 0)
    })

    local CloseBtn = Create("TextButton", {
        Parent = MainFrame, BackgroundTransparency = 1, Position = UDim2.new(1, -35, 0, 10), Size = UDim2.new(0, 25, 0, 25),
        Font = Enum.Font.GothamBold, Text = "X", TextColor3 = Library.CurrentTheme.Text, TextSize = 16
    })
    CloseBtn.MouseButton1Click:Connect(function() Library:Destroy() end)

    -- Notifications
    local NotifHolder = Create("Frame", {
        Parent = ScreenGui, BackgroundTransparency = 1, Position = UDim2.new(1, -20, 1, -20), Size = UDim2.new(0, 300, 1, 0), AnchorPoint = Vector2.new(1, 1)
    })
    local NotifLayout = Create("UIListLayout", { Parent = NotifHolder, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 5) })

    function Library:Notify(title, text, duration)
        if not Library.Settings.Notifications then return end
        local NFrame = Create("Frame", {
            Parent = NotifHolder, BackgroundColor3 = Library.CurrentTheme.Secondary, Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = NFrame })
        Create("UIStroke", { Color = Library.CurrentTheme.Outline, Thickness = 1, Parent = NFrame })
        
        local NTitle = Create("TextLabel", {
            Parent = NFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(1, -20, 0, 20),
            Font = Enum.Font.GothamBold, Text = title, TextColor3 = Library.CurrentTheme.Accent, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
        })
        local NText = Create("TextLabel", {
            Parent = NFrame, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 25), Size = UDim2.new(1, -20, 0, 30),
            Font = Enum.Font.Gotham, Text = text, TextColor3 = Library.CurrentTheme.Text, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true
        })

        Tween(NFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 60)})
        PlaySound(4590657391)

        task.delay(duration or 3, function()
            local t = Tween(NFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)})
            t.Completed:Wait()
            NFrame:Destroy()
        end)
    end

    function Library:UpdateTheme()
        local t = Library.CurrentTheme
        MainFrame.BackgroundColor3 = t.Main
        UIStroke.Color = t.Outline
        Sidebar.BackgroundColor3 = t.Secondary
        SidebarTitle.TextColor3 = t.Text
        ProfileFrame.BackgroundColor3 = t.Main
        DisplayName.TextColor3 = t.Text
        UserName.TextColor3 = t.Accent
        CloseBtn.TextColor3 = t.Text
        for _, func in pairs(Library.Elements) do func(t) end
    end

    function Library:ToggleUI()
        Library.IsVisible = not Library.IsVisible
        if Library.IsVisible then
            MainScale.Visible = true
            Tween(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 700, 0, 450)})
        else
            local t = Tween(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
            t.Completed:Connect(function() if not Library.IsVisible then MainScale.Visible = false end end)
        end
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Library.Settings.ToggleKey then Library:ToggleUI() end
    end)

    function Library:Destroy()
        ScreenGui:Destroy()
        Library.Open = false
    end

    -- Tab Logic
    local Window = {}
    local FirstTab = true

    function Window:Tab(name)
        local Page = Create("ScrollingFrame", {
            Name = name.."Page", Parent = ContentArea, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        local PageLayout = Create("UIListLayout", { Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
        Create("UIPadding", { Parent = Page, PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20) })
        
        local TabBtn = Create("TextButton", {
            Parent = TabScroll, BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 30),
            Font = Enum.Font.GothamBold, Text = "  " .. name, TextColor3 = Library.CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 0.5
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBtn })

        local function Activate()
            for _, v in pairs(ContentArea:GetChildren()) do v.Visible = false end
            for _, v in pairs(TabScroll:GetChildren()) do if v:IsA("TextButton") then Tween(v, TweenInfo.new(0.2), {TextTransparency = 0.5, BackgroundTransparency = 1}) end end
            for _, v in pairs(BottomTabHolder:GetChildren()) do if v:IsA("TextButton") then Tween(v, TweenInfo.new(0.2), {TextTransparency = 0.5, BackgroundTransparency = 1}) end end
            
            Page.Visible = true
            Tween(TabBtn, TweenInfo.new(0.2), {TextTransparency = 0, BackgroundTransparency = 0.9, BackgroundColor3 = Library.CurrentTheme.Text})
        end

        TabBtn.MouseButton1Click:Connect(Activate)
        if FirstTab then FirstTab = false; Activate() end

        table.insert(Library.Elements, function(t)
            TabBtn.TextColor3 = t.Text
            if Page.Visible then TabBtn.BackgroundColor3 = t.Text end
        end)

        local Tab = {}
        Library:RegisterComponents(Tab, Page)
        return Tab
    end

    -- Bottom Tabs (Config & Settings)
    local function CreateBottomTab(name)
        local Page = Create("ScrollingFrame", {
            Name = name.."Page", Parent = ContentArea, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        local PageLayout = Create("UIListLayout", { Parent = Page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
        Create("UIPadding", { Parent = Page, PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 20) })

        local TabBtn = Create("TextButton", {
            Parent = BottomTabHolder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.GothamBold, Text = "  " .. name, TextColor3 = Library.CurrentTheme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 0.5
        })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBtn })

        TabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(ContentArea:GetChildren()) do v.Visible = false end
            for _, v in pairs(TabScroll:GetChildren()) do if v:IsA("TextButton") then Tween(v, TweenInfo.new(0.2), {TextTransparency = 0.5, BackgroundTransparency = 1}) end end
            for _, v in pairs(BottomTabHolder:GetChildren()) do if v:IsA("TextButton") then Tween(v, TweenInfo.new(0.2), {TextTransparency = 0.5, BackgroundTransparency = 1}) end end
            Page.Visible = true
            Tween(TabBtn, TweenInfo.new(0.2), {TextTransparency = 0, BackgroundTransparency = 0.9, BackgroundColor3 = Library.CurrentTheme.Text})
        end)

        table.insert(Library.Elements, function(t) TabBtn.TextColor3 = t.Text; if Page.Visible then TabBtn.BackgroundColor3 = t.Text end end)
        
        local Tab = {}
        Library:RegisterComponents(Tab, Page)
        return Tab
    end

    -- Config Tab
    local ConfigTab = CreateBottomTab("Configs")
    local ConfigName = ""
    ConfigTab:Input("Config Name", "Type name...", "ConfigNameInput", function(val) ConfigName = val end)
    
    local ConfigList = {}
    local function RefreshConfigs()
        ConfigList = {}
        if isfolder(Library.FolderName) then
            for _, file in pairs(listfiles(Library.FolderName)) do
                if file:sub(-5) == ".json" then table.insert(ConfigList, file:match("([^/]+)%.json$")) end
            end
        end
        if Library.Flags["ConfigList_Object"] then Library.Flags["ConfigList_Object"]:Refresh(ConfigList) end
    end

    ConfigTab:Dropdown("Select Config", ConfigList, "None", "ConfigList", function(val) ConfigName = val end)
    ConfigTab:Button("Save Config", function()
        if ConfigName == "" then return Library:Notify("Error", "Enter a name!", 2) end
        local json = HttpService:JSONEncode(Library.Flags)
        writefile(Library.FolderName .. "/" .. ConfigName .. ".json", json)
        RefreshConfigs()
        Library:Notify("Success", "Saved " .. ConfigName, 2)
    end)
    ConfigTab:Button("Load Config", function()
        if isfile(Library.FolderName .. "/" .. ConfigName .. ".json") then
            local json = readfile(Library.FolderName .. "/" .. ConfigName .. ".json")
            local data = HttpService:JSONDecode(json)
            for flag, val in pairs(data) do
                Library.Flags[flag] = val
                if Library.Flags[flag.."_Object"] and Library.Flags[flag.."_Object"].Set then Library.Flags[flag.."_Object"]:Set(val) end
            end
            Library:Notify("Success", "Loaded " .. ConfigName, 2)
        else
            Library:Notify("Error", "Config not found", 2)
        end
    end)
    ConfigTab:Button("Refresh List", RefreshConfigs)
    RefreshConfigs()

    -- Settings Tab
    local SettingsTab = CreateBottomTab("Settings")
    SettingsTab:Dropdown("Theme", {"Light", "Dark", "Midnight", "Ruby", "Emerald", "Ocean"}, "Dark", "Settings_Theme", function(val)
        Library.CurrentTheme = Themes[val]
        Library:UpdateTheme()
    end)
    SettingsTab:Toggle("UI SFX", true, "Settings_SFX", function(val) Library.Settings.SFX = val end)
    SettingsTab:Toggle("Notifications", true, "Settings_Notif", function(val) Library.Settings.Notifications = val end)
    SettingsTab:Keybind("Toggle UI", "RightControl", "Settings_Key", function() Library:ToggleUI() end)

    Library:Notify("Loaded", Title .. " Script Loaded", 3)
    Library:Notify("Welcome", "Thanks for using my script!", 4)

    return Window
end

return Library

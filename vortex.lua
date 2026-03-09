-- Services 
local InputService  = game:GetService("UserInputService")
local HttpService   = game:GetService("HttpService")
local GuiService    = game:GetService("GuiService")
local RunService    = game:GetService("RunService")
local CoreGui       = game:GetService("CoreGui")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")
local Players       = game:GetService("Players")

local lp            = Players.LocalPlayer
local mouse         = lp:GetMouse()

-- Short aliases
local vec2          = Vector2.new
local dim2          = UDim2.new
local dim           = UDim.new
local rect          = Rect.new
local dim_offset    = UDim2.fromOffset
local rgb           = Color3.fromRGB
local hex           = Color3.fromHex

-- Library init / globals
getgenv().Vortex = getgenv().Vortex or {}
local Vortex = getgenv().Vortex

Vortex.Directory    = "Vortex"
Vortex.Folders      = {"/configs"}
Vortex.Flags        = {}
Vortex.ConfigFlags  = {}
Vortex.Connections  = {}
Vortex.DynamicTheming = {}
Vortex.Notifications= {Notifs = {}}
Vortex.__index      = Vortex

local Flags          = Vortex.Flags
local ConfigFlags    = Vortex.ConfigFlags
local Notifications  = Vortex.Notifications

-- Theme customized to match the image (Black and Red with Red Glow)
local themes = {
    preset = {
        accent       = rgb(255, 0, 0),     -- Pure Red for active toggles
        glow         = rgb(255, 0, 0),     -- Red Glow behind the window
        
        background   = rgb(20, 20, 20),    -- Main black/dark grey background (Right side)
        sidebar      = rgb(12, 12, 12),    -- Darker black for the left sidebar
        section      = rgb(28, 28, 28),    -- Elements/Dropdowns background
        element      = rgb(40, 40, 40),    -- Lighter grey for hover states
        
        outline      = rgb(255, 0, 0),     -- Red Borders
        text         = rgb(255, 255, 255), -- White text
        subtext      = rgb(170, 170, 170), -- Light grey for subtext
        
        tab_active   = rgb(255, 0, 0),     -- Highlighted tab (Red)
        tab_inactive = rgb(12, 12, 12),    -- Normal tab (Black)
    },
    utility = {}
}

for property, _ in themes.preset do
    themes.utility[property] = {
        BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}, Color = {}, ScrollBarImageColor3 = {}
    }
end

local Keys = {
    [Enum.KeyCode.LeftShift] = "LS", [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC", [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS", [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent", [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC", [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2", [Enum.UserInputType.MouseButton3] = "MB3"
}

for _, path in Vortex.Folders do
    pcall(function() makefolder(Vortex.Directory .. path) end)
end

-- Helpers
function Vortex:Tween(Object, Properties, Info)
    if not Object then return end
    local tween = TweenService:Create(Object, Info or TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), Properties)
    tween:Play()
    return tween
end

function Vortex:Create(instance, options)
    local ins = Instance.new(instance)
    for prop, value in options do ins[prop] = value end
    if ins:IsA("TextButton") or ins:IsA("ImageButton") then ins.AutoButtonColor = false end
    return ins
end

function Vortex:Themify(instance, theme, property)
    if not themes.utility[theme] then return end
    table.insert(themes.utility[theme][property], instance)
    instance[property] = themes.preset[theme]
end

function Vortex:Lighten(color, amount)
    return Color3.new(math.clamp(color.R + amount, 0, 1), math.clamp(color.G + amount, 0, 1), math.clamp(color.B + amount, 0, 1))
end

function Vortex:RefreshTheme(theme, color3)
    themes.preset[theme] = color3
    for property, instances in themes.utility[theme] do
        for _, object in instances do
            object[property] = color3
        end
    end
    for _, updateFunc in ipairs(Vortex.DynamicTheming) do
        updateFunc()
    end
end

-- Window Construction
function Vortex:Window(properties)
    local Cfg = {
        Title = properties.Title or properties.title or "VortexHub", 
        Size = properties.Size or properties.size or dim2(0, 650, 0, 450), 
        TabInfo = nil, Items = {}, Tweening = false, IsSwitchingTab = false;
    }

    if Vortex.Gui then Vortex.Gui:Destroy() end
    if Vortex.Other then Vortex.Other:Destroy() end
    if Vortex.ToggleGui then Vortex.ToggleGui:Destroy() end

    Vortex.Gui = Vortex:Create("ScreenGui", { Parent = CoreGui, Name = "Vortex", Enabled = true, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    Vortex.Other = Vortex:Create("ScreenGui", { Parent = CoreGui, Name = "VortexOther", Enabled = false, IgnoreGuiInset = true })
    
    local Items = Cfg.Items
    local uiVisible = true

    Items.Wrapper = Vortex:Create("Frame", {
        Parent = Vortex.Gui, Position = dim2(0.5, -Cfg.Size.X.Offset / 2, 0.5, -Cfg.Size.Y.Offset / 2),
        Size = Cfg.Size, BackgroundTransparency = 1, BorderSizePixel = 0
    })
    
    -- Red Glow Effect
    Items.Glow = Vortex:Create("ImageLabel", {
        Parent = Items.Wrapper, Position = dim2(0, -15, 0, -15), Size = dim2(1, 30, 1, 30),
        BackgroundTransparency = 1, Image = "rbxassetid://5028857084", ImageColor3 = themes.preset.glow,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(24, 24, 276, 276), ZIndex = 0
    })
    Vortex:Themify(Items.Glow, "glow", "ImageColor3")

    Items.Window = Vortex:Create("Frame", {
        Parent = Items.Wrapper, Position = dim2(0, 0, 0, 0), Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 1, ClipsDescendants = true
    })
    Vortex:Themify(Items.Window, "background", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 10) })
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    -- Top Window Controls
    Items.TopBar = Vortex:Create("Frame", { Parent = Items.Window, Size = dim2(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 10, Active = true })
    local ctrlLayout = Vortex:Create("UIListLayout", {Parent = Items.TopBar, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = dim(0, 12)})
    Vortex:Create("UIPadding", {Parent = Items.TopBar, PaddingRight = dim(0, 16)})
    
    local closeBtn = Vortex:Create("TextButton", {Parent = Items.TopBar, Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Text = "✕", TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 12, LayoutOrder = 3})
    local maxBtn = Vortex:Create("TextButton", {Parent = Items.TopBar, Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Text = "▢", TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 12, LayoutOrder = 2})
    local minBtn = Vortex:Create("TextButton", {Parent = Items.TopBar, Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Text = "—", TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 12, LayoutOrder = 1})
    
    Vortex:Themify(closeBtn, "text", "TextColor3")
    Vortex:Themify(maxBtn, "text", "TextColor3")
    Vortex:Themify(minBtn, "text", "TextColor3")

    -- Sidebar Area (Left)
    Items.Sidebar = Vortex:Create("Frame", { 
        Parent = Items.Window, Size = dim2(0, 180, 1, 0), BackgroundColor3 = themes.preset.sidebar, BorderSizePixel = 0, ZIndex = 2 
    })
    Vortex:Themify(Items.Sidebar, "sidebar", "BackgroundColor3")

    -- Sidebar Header / Logo
    Items.Header = Vortex:Create("Frame", { Parent = Items.Sidebar, Size = dim2(1, 0, 0, 60), BackgroundTransparency = 1 })
    
    Items.LogoIcon = Vortex:Create("TextLabel", {
        Parent = Items.Header, Text = "$", TextColor3 = themes.preset.text, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 15, 0.5, 0), Size = dim2(0, 20, 0, 20),
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.ExtraBold), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center
    })
    Vortex:Themify(Items.LogoIcon, "text", "TextColor3")

    Items.LogoText = Vortex:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.text, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 40, 0.5, 0), Size = dim2(1, -40, 0, 20),
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
    })
    Vortex:Themify(Items.LogoText, "text", "TextColor3")

    -- Tab Holder (Vertical)
    Items.TabHolder = Vortex:Create("ScrollingFrame", { 
        Parent = Items.Sidebar, Position = dim2(0, 0, 0, 60), Size = dim2(1, 0, 1, -120), 
        BackgroundTransparency = 1, ScrollBarThickness = 0, BorderSizePixel = 0
    })
    Vortex:Create("UIListLayout", { Parent = Items.TabHolder, FillDirection = Enum.FillDirection.Vertical, Padding = dim(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center })
    Vortex:Create("UIPadding", { Parent = Items.TabHolder, PaddingTop = dim(0, 5), PaddingLeft = dim(0, 10), PaddingRight = dim(0, 10) })

    -- Profile Footer
    Items.Footer = Vortex:Create("Frame", { 
        Parent = Items.Sidebar, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 60), BackgroundTransparency = 1 
    })
    
    local headshot = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
    Items.AvatarFrame = Vortex:Create("Frame", {
        Parent = Items.Footer, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 15, 0.5, 0), Size = dim2(0, 32, 0, 32), BackgroundColor3 = themes.preset.element, BorderSizePixel = 0
    })
    Vortex:Themify(Items.AvatarFrame, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.AvatarFrame, CornerRadius = dim(1, 0) })
    Items.Avatar = Vortex:Create("ImageLabel", { Parent = Items.AvatarFrame, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Image = headshot })
    Vortex:Create("UICorner", { Parent = Items.Avatar, CornerRadius = dim(1, 0) })

    Items.Username = Vortex:Create("TextLabel", {
        Parent = Items.Footer, Text = "Anonymous", TextColor3 = themes.preset.text, AnchorPoint = vec2(0, 0), Position = dim2(0, 55, 0, 16), Size = dim2(0, 100, 0, 14),
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left
    })
    Vortex:Themify(Items.Username, "text", "TextColor3")

    Items.Subname = Vortex:Create("TextLabel", {
        Parent = Items.Footer, Text = "@anonymous", TextColor3 = themes.preset.subtext, AnchorPoint = vec2(0, 0), Position = dim2(0, 55, 0, 30), Size = dim2(0, 100, 0, 12),
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left
    })
    Vortex:Themify(Items.Subname, "subtext", "TextColor3")

    -- Content Area (Right Side)
    Items.PageHolder = Vortex:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 180, 0, 30), Size = dim2(1, -180, 1, -30), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Dragging Logic
    local Dragging, DragInput, DragStart, StartPos
    Items.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true; DragStart = input.Position; StartPos = Items.Wrapper.Position
        end
    end)
    Items.TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - DragStart
            Items.Wrapper.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
        end
    end)

    function Cfg.ToggleMenu(bool)
        if Cfg.Tweening then return end
        if bool == nil then uiVisible = not uiVisible else uiVisible = bool end
        
        if uiVisible then
            Items.Wrapper.Visible = true
            Vortex:Tween(Items.Wrapper, {Size = Cfg.Size}, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            Vortex:Tween(Items.Window, {BackgroundTransparency = 0}, TweenInfo.new(0.3))
            Vortex:Tween(Items.Glow, {ImageTransparency = 0}, TweenInfo.new(0.3))
        else
            Vortex:Tween(Items.Wrapper, {Size = dim2(0, Cfg.Size.X.Offset, 0, 0)}, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In))
            Vortex:Tween(Items.Window, {BackgroundTransparency = 1}, TweenInfo.new(0.3))
            Vortex:Tween(Items.Glow, {ImageTransparency = 1}, TweenInfo.new(0.3))
            task.delay(0.4, function() Items.Wrapper.Visible = false end)
        end
    end

    return setmetatable(Cfg, Vortex)
end

-- Tabs
function Vortex:Tab(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Tab", 
        Icon = properties.Icon or properties.icon or "rbxassetid://11293977610", 
        Hidden = properties.Hidden or properties.hidden or false, 
        Items = {} 
    }
    if tonumber(Cfg.Icon) then Cfg.Icon = "rbxassetid://" .. tostring(Cfg.Icon) end
    local Items = Cfg.Items

    if not Cfg.Hidden then
        Items.Button = Vortex:Create("TextButton", { 
            Parent = self.Items.TabHolder, Size = dim2(1, 0, 0, 32), 
            BackgroundColor3 = themes.preset.tab_active, BackgroundTransparency = 1, 
            Text = "", AutoButtonColor = false, ZIndex = 5 
        })
        Vortex:Themify(Items.Button, "tab_active", "BackgroundColor3")
        Vortex:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })
        
        Items.IconImg = Vortex:Create("ImageLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 10, 0.5, 0),
            Size = dim2(0, 16, 0, 16), BackgroundTransparency = 1, 
            Image = Cfg.Icon, ImageColor3 = themes.preset.text, ZIndex = 6 
        })
        Vortex:Themify(Items.IconImg, "text", "ImageColor3")

        Items.Label = Vortex:Create("TextLabel", {
            Parent = Items.Button, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 36, 0.5, 0), Size = dim2(1, -40, 0, 14),
            BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6
        })
        Vortex:Themify(Items.Label, "text", "TextColor3")
        
        Items.Button.MouseEnter:Connect(function()
            if self.TabInfo ~= Cfg.Items then Vortex:Tween(Items.Button, {BackgroundTransparency = 0.5}, TweenInfo.new(0.2)) end
        end)
        Items.Button.MouseLeave:Connect(function()
            if self.TabInfo ~= Cfg.Items then Vortex:Tween(Items.Button, {BackgroundTransparency = 1}, TweenInfo.new(0.2)) end
        end)
    end

    Items.Pages = Vortex:Create("CanvasGroup", { Parent = Vortex.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    Vortex:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 10) })
    Vortex:Create("UIPadding", { Parent = Items.Pages, PaddingTop = dim(0, 5), PaddingBottom = dim(0, 15), PaddingRight = dim(0, 15), PaddingLeft = dim(0, 15) })

    Items.Left = Vortex:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -5, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Vortex:Create("UIListLayout", { Parent = Items.Left, Padding = dim(0, 8) })

    Items.Right = Vortex:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -5, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 0, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Vortex:Create("UIListLayout", { Parent = Items.Right, Padding = dim(0, 8) })

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg.Items then return end
        local oldTab = self.TabInfo
        self.IsSwitchingTab = true
        self.TabInfo = Cfg.Items

        local buttonTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        if oldTab and oldTab.Button then Vortex:Tween(oldTab.Button, {BackgroundTransparency = 1}, buttonTween) end
        if Items.Button then Vortex:Tween(Items.Button, {BackgroundTransparency = 0}, buttonTween) end
        
        task.spawn(function()
            if oldTab then
                Vortex:Tween(oldTab.Pages, {GroupTransparency = 1, Position = dim2(0, 0, 0, 10)}, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                task.wait(0.2)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = Vortex.Other
            end

            Items.Pages.Position = dim2(0, 0, 0, -10) 
            Items.Pages.GroupTransparency = 1
            Items.Pages.Parent = self.Items.PageHolder
            Items.Pages.Visible = true

            Vortex:Tween(Items.Pages, {GroupTransparency = 0, Position = dim2(0, 0, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            task.wait(0.3)
            
            Items.Pages.GroupTransparency = 0 
            self.IsSwitchingTab = false
        end)
    end

    if Items.Button then Items.Button.MouseButton1Down:Connect(Cfg.OpenTab) end
    if not self.TabInfo and not Cfg.Hidden then Cfg.OpenTab() end
    return setmetatable(Cfg, Vortex)
end

-- Sections
function Vortex:Section(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Section", 
        Side = properties.Side or properties.side or "Left", 
        Items = {} 
    }
    Cfg.Side = (Cfg.Side:lower() == "right") and "Right" or "Left"
    local Items = Cfg.Items

    Items.Section = Vortex:Create("Frame", { 
        Parent = self.Items[Cfg.Side], Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundTransparency = 1, BorderSizePixel = 0 
    })

    Items.Header = Vortex:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 25), BackgroundTransparency = 1 })
    
    Items.Title = Vortex:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 0, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, 0, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Vortex:Themify(Items.Title, "text", "TextColor3")

    Items.Container = Vortex:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 25), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Vortex:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

    return setmetatable(Cfg, Vortex)
end

-- Toggles (Pill style with subtitle support)
function Vortex:Toggle(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Toggle", 
        Subtitle = properties.Subtitle or properties.subtitle or "",
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items
    local hasSub = Cfg.Subtitle ~= ""
    local height = hasSub and 50 or 34

    Items.Button = Vortex:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, height), 
        BackgroundColor3 = themes.preset.section, AutoButtonColor = false, Text = ""
    })
    Vortex:Themify(Items.Button, "section", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })

    Items.Title = Vortex:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 10, 0, hasSub and 10 or (height/2 - 7)), Size = dim2(1, -60, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextXAlignment = Enum.TextXAlignment.Left 
    })
    Vortex:Themify(Items.Title, "text", "TextColor3")

    if hasSub then
        Items.Sub = Vortex:Create("TextLabel", { 
            Parent = Items.Button, Position = dim2(0, 10, 0, 26), Size = dim2(1, -60, 0, 24), 
            BackgroundTransparency = 1, Text = Cfg.Subtitle, TextColor3 = themes.preset.subtext, TextSize = 11, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true
        })
        Vortex:Themify(Items.Sub, "subtext", "TextColor3")
    end

    -- Pill Background
    Items.SwitchBg = Vortex:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -10, 0.5, 0), Size = dim2(0, 36, 0, 18), 
        BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    Vortex:Create("UICorner", { Parent = Items.SwitchBg, CornerRadius = dim(1, 0) })
    
    -- Knob
    Items.SwitchKnob = Vortex:Create("Frame", {
        Parent = Items.SwitchBg, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 2, 0.5, 0),
        Size = dim2(0, 14, 0, 14), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0
    })
    Vortex:Create("UICorner", { Parent = Items.SwitchKnob, CornerRadius = dim(1, 0) })

    local State = false
    function Cfg.set(bool)
        State = bool
        if State then
            Vortex:Tween(Items.SwitchBg, {BackgroundColor3 = themes.preset.accent}, TweenInfo.new(0.2))
            Vortex:Tween(Items.SwitchKnob, {Position = dim2(1, -16, 0.5, 0)}, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        else
            Vortex:Tween(Items.SwitchBg, {BackgroundColor3 = themes.preset.element}, TweenInfo.new(0.2))
            Vortex:Tween(Items.SwitchKnob, {Position = dim2(0, 2, 0.5, 0)}, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        end
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    table.insert(Vortex.DynamicTheming, function()
        if State then Items.SwitchBg.BackgroundColor3 = themes.preset.accent else Items.SwitchBg.BackgroundColor3 = themes.preset.element end
    end)

    Items.Button.MouseButton1Click:Connect(function() Cfg.set(not State) end)
    if Cfg.Default then Cfg.set(true) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    return setmetatable(Cfg, Vortex)
end

function Vortex:Button(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Button", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Vortex:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 34), BackgroundColor3 = themes.preset.section, 
        Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), AutoButtonColor = false 
    })
    Vortex:Themify(Items.Button, "section", "BackgroundColor3")
    Vortex:Themify(Items.Button, "text", "TextColor3")
    Vortex:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })

    Items.Button.MouseEnter:Connect(function()
        Vortex:Tween(Items.Button, {BackgroundColor3 = Vortex:Lighten(themes.preset.section, 0.05)}, TweenInfo.new(0.2))
    end)
    Items.Button.MouseLeave:Connect(function()
        Vortex:Tween(Items.Button, {BackgroundColor3 = themes.preset.section}, TweenInfo.new(0.2))
    end)

    Items.Button.MouseButton1Click:Connect(function()
        Vortex:Tween(Items.Button, {Size = dim2(1, -4, 0, 30)}, TweenInfo.new(0.1, Enum.EasingStyle.Quint))
        task.wait(0.1)
        Vortex:Tween(Items.Button, {Size = dim2(1, 0, 0, 34)}, TweenInfo.new(0.3, Enum.EasingStyle.Back))
        Cfg.Callback()
    end)
    return setmetatable(Cfg, Vortex)
end

function Vortex:Dropdown(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Dropdown", 
        Flag = properties.Flag or properties.flag, 
        Options = properties.Options or properties.options or properties.items or {}, 
        Default = properties.Default or properties.default, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items
    
    Items.Container = Vortex:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 36), BackgroundTransparency = 1 })

    Items.Main = Vortex:Create("TextButton", { 
        Parent = Items.Container, Position = dim2(0, 0, 0, 0), Size = dim2(1, 0, 1, 0), 
        BackgroundColor3 = themes.preset.section, Text = "", AutoButtonColor = false 
    })
    Vortex:Themify(Items.Main, "section", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Main, CornerRadius = dim(0, 6) })

    Items.SelectedText = Vortex:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 10, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, Text = Cfg.Name .. " ...", TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Items.SelectedText, "text", "TextColor3")
    
    Items.Icon = Vortex:Create("TextLabel", { Parent = Items.Main, Position = dim2(1, -20, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Text = "▼", TextColor3 = themes.preset.subtext, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize=10 })
    Vortex:Themify(Items.Icon, "subtext", "TextColor3")

    Items.DropFrame = Vortex:Create("Frame", { 
        Parent = Vortex.Gui, Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    Vortex:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 6) })

    Items.Scroll = Vortex:Create("ScrollingFrame", { 
        Parent = Items.DropFrame, Size = dim2(1, 0, 1, -8), Position = dim2(0, 0, 0, 4), 
        BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = themes.preset.subtext, BorderSizePixel = 0, ZIndex = 201 
    })
    Vortex:Create("UIListLayout", { Parent = Items.Scroll, SortOrder = Enum.SortOrder.LayoutOrder })

    local Open = false
    local isTweening = false

    function Cfg.UpdatePosition()
        local absPos = Items.Main.AbsolutePosition
        local absSize = Items.Main.AbsoluteSize
        Items.DropFrame.Position = dim2(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
        Items.Scroll.CanvasSize = dim2(0, 0, 0, #Cfg.Options * 28)
    end

    local function ToggleDropdown()
        if isTweening then return end
        Open = not Open
        isTweening = true

        if Open then
            Items.DropFrame.Visible = true
            Cfg.UpdatePosition()
            Items.DropFrame.Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)
            local targetHeight = math.clamp(#Cfg.Options * 28 + 8, 0, 150)
            Vortex:Tween(Items.Icon, {Rotation = 180}, TweenInfo.new(0.3, Enum.EasingStyle.Back))
            local tw = Vortex:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, targetHeight)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            Vortex:Tween(Items.Icon, {Rotation = 0}, TweenInfo.new(0.3, Enum.EasingStyle.Back))
            local tw = Vortex:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, 0)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    Items.Main.MouseButton1Click:Connect(ToggleDropdown)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0, s0 = Items.DropFrame.AbsolutePosition, Items.DropFrame.AbsoluteSize
                local p1, s1 = Items.Main.AbsolutePosition, Items.Main.AbsoluteSize
                
                if not (mx >= p0.X and mx <= p0.X + s0.X and my >= p0.Y and my <= p0.Y + s0.Y) and 
                   not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    ToggleDropdown()
                end
            end
        end
    end)

    local OptionBtns = {}
    function Cfg.RefreshOptions(newList)
        Cfg.Options = newList or Cfg.Options
        for _, btn in ipairs(OptionBtns) do btn:Destroy() end
        table.clear(OptionBtns)
        for _, opt in ipairs(Cfg.Options) do
            local btn = Vortex:Create("TextButton", { 
                Parent = Items.Scroll, Size = dim2(1, 0, 0, 28), BackgroundTransparency = 1, 
                Text = tostring(opt), TextColor3 = themes.preset.subtext, TextSize = 13, 
                FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202 
            })
            Vortex:Themify(btn, "subtext", "TextColor3")
            local padding = Vortex:Create("UIPadding", {Parent = btn, PaddingLeft = dim(0, 10)})
            
            btn.MouseEnter:Connect(function() Vortex:Tween(btn, {TextColor3 = themes.preset.text}, TweenInfo.new(0.2)) end)
            btn.MouseLeave:Connect(function() Vortex:Tween(btn, {TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2)) end)
            btn.MouseButton1Click:Connect(function() Cfg.set(opt); ToggleDropdown() end)
            table.insert(OptionBtns, btn)
        end
    end

    function Cfg.set(val)
        Items.SelectedText.Text = Cfg.Name .. " - " .. tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end

    Cfg.RefreshOptions(Cfg.Options)
    if Cfg.Default then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

    RunService.RenderStepped:Connect(function() 
        if Open or isTweening then 
            Items.DropFrame.Position = dim2(0, Items.Main.AbsolutePosition.X, 0, Items.Main.AbsolutePosition.Y + Items.Main.AbsoluteSize.Y + 4)
        end 
    end)
    return setmetatable(Cfg, Vortex)
end

function Vortex:Slider(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Slider", 
        Flag = properties.Flag or properties.flag, 
        Min = properties.Min or properties.min or 0, 
        Max = properties.Max or properties.max or 100, 
        Default = properties.Default or properties.default or properties.Value or properties.value or 0, 
        Increment = properties.Increment or properties.increment or 1, 
        Suffix = properties.Suffix or properties.suffix or "", 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Vortex:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 48), BackgroundColor3 = themes.preset.section, BorderSizePixel = 0 })
    Vortex:Themify(Items.Container, "section", "BackgroundColor3")
    Vortex:Create("UICorner", {Parent = Items.Container, CornerRadius = dim(0, 6)})

    Items.Title = Vortex:Create("TextLabel", { Parent = Items.Container, Position = dim2(0, 10, 0, 0), Size = dim2(1, -20, 0, 26), BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Items.Title, "text", "TextColor3")

    Items.Val = Vortex:Create("TextLabel", { Parent = Items.Container, Position = dim2(0, 10, 0, 0), Size = dim2(1, -20, 0, 26), BackgroundTransparency = 1, Text = tostring(Cfg.Default)..Cfg.Suffix, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextXAlignment = Enum.TextXAlignment.Right })
    Vortex:Themify(Items.Val, "subtext", "TextColor3")

    Items.Track = Vortex:Create("TextButton", { Parent = Items.Container, Position = dim2(0, 10, 0, 32), Size = dim2(1, -20, 0, 6), BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false })
    Vortex:Themify(Items.Track, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Track, CornerRadius = dim(1, 0) })

    Items.Fill = Vortex:Create("Frame", { Parent = Items.Track, Size = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.accent })
    Vortex:Themify(Items.Fill, "accent", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Fill, CornerRadius = dim(1, 0) })
    
    Items.Knob = Vortex:Create("Frame", { Parent = Items.Fill, AnchorPoint = vec2(0.5, 0.5), Position = dim2(1, 0, 0.5, 0), Size = dim2(0, 12, 0, 12), BackgroundColor3 = rgb(255,255,255) })
    Vortex:Create("UICorner", { Parent = Items.Knob, CornerRadius = dim(1, 0) })
    
    local Value = Cfg.Default
    function Cfg.set(val)
        Value = math.clamp(math.round(val / Cfg.Increment) * Cfg.Increment, Cfg.Min, Cfg.Max)
        Items.Val.Text = tostring(Value) .. Cfg.Suffix
        Vortex:Tween(Items.Fill, {Size = dim2((Value - Cfg.Min) / (Cfg.Max - Cfg.Min), 0, 1, 0)}, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        if Cfg.Flag then Flags[Cfg.Flag] = Value end
        Cfg.Callback(Value)
    end

    local Dragging = false
    Items.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            Dragging = true; 
            Vortex:Tween(Items.Knob, {Size = dim2(0, 16, 0, 16)}, TweenInfo.new(0.2, Enum.EasingStyle.Back))
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1)) 
        end
    end)
    InputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            Dragging = false 
            Vortex:Tween(Items.Knob, {Size = dim2(0, 12, 0, 12)}, TweenInfo.new(0.2, Enum.EasingStyle.Back))
        end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Cfg.set(Cfg.Min + (Cfg.Max - Cfg.Min) * math.clamp((input.Position.X - Items.Track.AbsolutePosition.X) / Items.Track.AbsoluteSize.X, 0, 1))
        end
    end)

    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Vortex)
end

function Vortex:Textbox(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "", 
        Placeholder = properties.Placeholder or properties.placeholder or "Enter text...", 
        Default = properties.Default or properties.default or "", 
        Flag = properties.Flag or properties.flag, 
        Numeric = properties.Numeric or properties.numeric or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Vortex:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 36), BackgroundTransparency = 1 })
    Items.Bg = Vortex:Create("Frame", { Parent = Items.Container, Size = dim2(1, 0, 1, 0), BackgroundColor3 = themes.preset.section })
    Vortex:Themify(Items.Bg, "section", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Bg, CornerRadius = dim(0, 6) })
    
    Items.Input = Vortex:Create("TextBox", { 
        Parent = Items.Bg, Position = dim2(0, 10, 0, 0), Size = dim2(1, -20, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
    })
    Vortex:Themify(Items.Input, "text", "TextColor3")

    function Cfg.set(val)
        if Cfg.Numeric and tonumber(val) == nil and val ~= "" then return end
        Items.Input.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end
    Items.Input.FocusLost:Connect(function() Cfg.set(Items.Input.Text) end)
    
    if Cfg.Default ~= "" then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Vortex)
end

function Vortex:Label(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Label", 
        Wrapped = properties.Wrapped or properties.wrapped or false, 
        Items = {} 
    }
    local Items = Cfg.Items
    Items.Title = Vortex:Create("TextLabel", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, Cfg.Wrapped and 26 or 18), BackgroundTransparency = 1, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextWrapped = Cfg.Wrapped, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, 
        TextYAlignment = Cfg.Wrapped and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center 
    })
    Vortex:Themify(Items.Title, "subtext", "TextColor3")
    function Cfg.set(val) Items.Title.Text = tostring(val) end
    return setmetatable(Cfg, Vortex)
end

function Vortex:Keybind(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Keybind", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or Enum.KeyCode.Unknown, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    
    local Container = Vortex:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 36), BackgroundColor3 = themes.preset.section, BorderSizePixel = 0 })
    Vortex:Themify(Container, "section", "BackgroundColor3")
    Vortex:Create("UICorner", {Parent = Container, CornerRadius = dim(0, 6)})

    local Title = Vortex:Create("TextLabel", { Parent = Container, Position = dim2(0, 10, 0, 0), Size = dim2(1, -60, 1, 0), BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Title, "text", "TextColor3")

    local KeyBtn = Vortex:Create("TextButton", { Parent = Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -6, 0.5, 0), Size = dim2(0, 45, 0, 24), BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.text, Text = Keys[Cfg.Default] or "None", TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), })
    Vortex:Themify(KeyBtn, "element", "BackgroundColor3")
    Vortex:Themify(KeyBtn, "text", "TextColor3")
    Vortex:Create("UICorner", {Parent = KeyBtn, CornerRadius = dim(0, 4)})

    local binding = false
    KeyBtn.MouseButton1Click:Connect(function() binding = true; KeyBtn.Text = "..." end)
    
    InputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed and not binding then return end
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                binding = false; Cfg.set(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                binding = false; Cfg.set(input.UserInputType)
            end
        elseif (input.KeyCode == Cfg.Default or input.UserInputType == Cfg.Default) and not binding then
            Cfg.Callback()
        end
    end)
    
    function Cfg.set(val)
        if not val or type(val) == "boolean" then return end
        Cfg.Default = val
        local keyName = Keys[val] or (typeof(val) == "EnumItem" and val.Name) or tostring(val)
        KeyBtn.Text = keyName
        if Cfg.Flag then Flags[Cfg.Flag] = val end
    end
    
    Cfg.set(Cfg.Default)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Vortex)
end

function Vortex:Colorpicker(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Color",
        Color = properties.Color or properties.color or rgb(255, 255, 255), 
        Callback = properties.Callback or properties.callback or function() end, 
        Flag = properties.Flag or properties.flag, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Container = Vortex:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 36), BackgroundColor3 = themes.preset.section, BorderSizePixel = 0 })
    Vortex:Themify(Items.Container, "section", "BackgroundColor3")
    Vortex:Create("UICorner", {Parent = Items.Container, CornerRadius = dim(0, 6)})

    Items.Title = Vortex:Create("TextLabel", { Parent = Items.Container, Position = dim2(0, 10, 0, 0), Size = dim2(1, -60, 1, 0), BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Items.Title, "text", "TextColor3")

    local btn = Vortex:Create("TextButton", { Parent = Items.Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -6, 0.5, 0), Size = dim2(0, 40, 0, 20), BackgroundColor3 = Cfg.Color, Text = "" })
    Vortex:Create("UICorner", {Parent = btn, CornerRadius = dim(0, 4)})

    local h, s, v = Color3.toHSV(Cfg.Color)
    
    Items.DropFrame = Vortex:Create("Frame", { Parent = Vortex.Gui, Size = dim2(0, 160, 0, 0), BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true })
    Vortex:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 6) })

    Items.SVMap = Vortex:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 10, 0, 10), Size = dim2(1, -20, 1, -44), AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 201 })
    Vortex:Create("UICorner", { Parent = Items.SVMap, CornerRadius = dim(0, 4) })
    Items.SVImage = Vortex:Create("ImageLabel", { Parent = Items.SVMap, Size = dim2(1, 0, 1, 0), Image = "rbxassetid://4155801252", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 202 })
    Vortex:Create("UICorner", { Parent = Items.SVImage, CornerRadius = dim(0, 4) })
    
    Items.SVKnob = Vortex:Create("Frame", { Parent = Items.SVMap, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 6, 0, 6), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Vortex:Create("UICorner", { Parent = Items.SVKnob, CornerRadius = dim(1, 0) })

    Items.HueBar = Vortex:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 10, 1, -24), Size = dim2(1, -20, 0, 14), AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = rgb(255, 255, 255), ZIndex = 201 })
    Vortex:Create("UICorner", { Parent = Items.HueBar, CornerRadius = dim(0, 4) })
    Vortex:Create("UIGradient", { Parent = Items.HueBar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255,0,0)), ColorSequenceKeypoint.new(0.167, rgb(255,0,255)), ColorSequenceKeypoint.new(0.333, rgb(0,0,255)), ColorSequenceKeypoint.new(0.5, rgb(0,255,255)), ColorSequenceKeypoint.new(0.667, rgb(0,255,0)), ColorSequenceKeypoint.new(0.833, rgb(255,255,0)), ColorSequenceKeypoint.new(1, rgb(255,0,0))}) })
    
    Items.HueKnob = Vortex:Create("Frame", { Parent = Items.HueBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 4, 1, 6), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Vortex:Create("UICorner", {Parent = Items.HueKnob, CornerRadius = dim(1, 0)})

    local Open = false
    local isTweening = false

    local function Toggle() 
        if isTweening then return end
        Open = not Open
        isTweening = true
        
        if Open then
            Items.DropFrame.Visible = true
            local tw = Vortex:Tween(Items.DropFrame, {Size = dim2(0, 160, 0, 150)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            local tw = Vortex:Tween(Items.DropFrame, {Size = dim2(0, 160, 0, 0)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
            Items.DropFrame.Visible = false
        end
        isTweening = false
    end
    btn.MouseButton1Click:Connect(Toggle)

    InputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Open and not isTweening then
                local mx, my = input.Position.X, input.Position.Y
                local p0, s0 = Items.DropFrame.AbsolutePosition, dim2(0, 160, 0, 150)
                local p1, s1 = btn.AbsolutePosition, btn.AbsoluteSize
                if not (mx >= p0.X and mx <= p0.X + s0.X.Offset and my >= p0.Y and my <= p0.Y + s0.Y.Offset) and not (mx >= p1.X and mx <= p1.X + s1.X and my >= p1.Y and my <= p1.Y + s1.Y) then
                    Toggle()
                end
            end
        end
    end)

    function Cfg.set(color3)
        Cfg.Color = color3
        btn.BackgroundColor3 = color3
        if Cfg.Flag then Flags[Cfg.Flag] = color3 end
        Cfg.Callback(color3)
    end

    local svDragging, hueDragging = false, false
    Items.SVMap.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = true end end)
    Items.HueBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hueDragging = true end end)
    InputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then svDragging = false; hueDragging = false end end)

    InputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if svDragging then
                local x = math.clamp((input.Position.X - Items.SVMap.AbsolutePosition.X) / Items.SVMap.AbsoluteSize.X, 0, 1)
                local y = math.clamp((input.Position.Y - Items.SVMap.AbsolutePosition.Y) / Items.SVMap.AbsoluteSize.Y, 0, 1)
                s, v = x, 1 - y
                Vortex:Tween(Items.SVKnob, {Position = dim2(x, 0, y, 0)}, TweenInfo.new(0.05))
                Cfg.set(Color3.fromHSV(h, s, v))
            elseif hueDragging then
                local x = math.clamp((input.Position.X - Items.HueBar.AbsolutePosition.X) / Items.HueBar.AbsoluteSize.X, 0, 1)
                h = 1 - x
                Vortex:Tween(Items.HueKnob, {Position = dim2(x, 0, 0.5, 0)}, TweenInfo.new(0.05))
                Items.SVMap.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                Cfg.set(Color3.fromHSV(h, s, v))
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if Open or isTweening then Items.DropFrame.Position = dim2(0, btn.AbsolutePosition.X - 160 + btn.AbsoluteSize.X, 0, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 4) end
    end)
    
    Items.SVKnob.Position = dim2(s, 0, 1 - v, 0)
    Items.HueKnob.Position = dim2(1 - h, 0, 0.5, 0)
    
    Cfg.set(Cfg.Color)
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end
    return setmetatable(Cfg, Vortex)
end

-- Notifications
function Notifications:RefreshNotifications()
    local offset = 50
    for _, v in ipairs(Notifications.Notifs) do
        local ySize = math.max(v.AbsoluteSize.Y, 36)
        Vortex:Tween(v, {Position = dim_offset(20, offset)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        offset += (ySize + 10)
    end
end

function Notifications:Create(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Notification"; 
        Lifetime = properties.LifeTime or properties.lifetime or 2.5; 
        Items = {}; 
    }
    local Items = Cfg.Items
   
    Items.Outline = Vortex:Create("Frame", { Parent = Vortex.Gui; Position = dim_offset(-500, 50); Size = dim2(0, 300, 0, 0); AutomaticSize = Enum.AutomaticSize.Y; BackgroundColor3 = themes.preset.background; BorderSizePixel = 0; ZIndex = 300, ClipsDescendants = true })
    Vortex:Themify(Items.Outline, "background", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Outline, CornerRadius = dim(0, 6) })
   
    Items.Name = Vortex:Create("TextLabel", {
        Parent = Items.Outline; Text = Cfg.Name; TextColor3 = themes.preset.text; FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium);
        BackgroundTransparency = 1; Size = dim2(1, 0, 1, 0); AutomaticSize = Enum.AutomaticSize.None; TextWrapped = true; TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 302
    })
    Vortex:Themify(Items.Name, "text", "TextColor3")
   
    Vortex:Create("UIPadding", { Parent = Items.Name; PaddingTop = dim(0, 12); PaddingBottom = dim(0, 12); PaddingRight = dim(0, 14); PaddingLeft = dim(0, 14); })
   
    Items.TimeBar = Vortex:Create("Frame", { Parent = Items.Outline, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 3), BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 303 })
    Vortex:Themify(Items.TimeBar, "accent", "BackgroundColor3")
    table.insert(Notifications.Notifs, Items.Outline)
   
    task.spawn(function()
        RunService.RenderStepped:Wait()
        Items.Outline.Position = dim_offset(-Items.Outline.AbsoluteSize.X - 20, 50)
        Notifications:RefreshNotifications()
        Vortex:Tween(Items.TimeBar, {Size = dim2(0, 0, 0, 3)}, TweenInfo.new(Cfg.Lifetime, Enum.EasingStyle.Linear))
        task.wait(Cfg.Lifetime)
        Vortex:Tween(Items.Outline, {Position = dim_offset(-Items.Outline.AbsoluteSize.X - 50, Items.Outline.Position.Y.Offset)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In))
        task.wait(0.4)
        local idx = table.find(Notifications.Notifs, Items.Outline)
        if idx then table.remove(Notifications.Notifs, idx) end
        Items.Outline:Destroy()
        task.wait(0.05)
        Notifications:RefreshNotifications()
    end)
end

-- Save and Load System
function Vortex:GetConfig()
    local g = {}
    for Idx, Value in Flags do g[Idx] = Value end
    return HttpService:JSONEncode(g)
end

function Vortex:LoadConfig(JSON)
    local g = HttpService:JSONDecode(JSON)
    for Idx, Value in g do
        if Idx == "config_Name_list" or Idx == "config_Name_text" then continue end
        local Function = ConfigFlags[Idx]
        if Function then Function(Value) end
    end
end

local ConfigHolder
function Vortex:UpdateConfigList()
    if not ConfigHolder then return end
    local List = {}
    for _, file in listfiles(Vortex.Directory .. "/configs") do
        local Name = file:gsub(Vortex.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(Vortex.Directory .. "\\configs\\", "")
        List[#List + 1] = Name
    end
    ConfigHolder.RefreshOptions(List)
end

function Vortex:Configs(window)
    local Text

    local Tab = window:Tab({ Name = "Settings", Icon = "11293977610", Hidden = true })
    window.SettingsTabOpen = Tab.OpenTab

    local Section = Tab:Section({Name = "Configs", Side = "Left"})

    ConfigHolder = Section:Dropdown({
        Name = "Available Configs",
        Options = {},
        Callback = function(option) if Text then Text.set(option) end end,
        Flag = "config_Name_list"
    })

    Vortex:UpdateConfigList()

    Text = Section:Textbox({ Name = "Config Name:", Flag = "config_Name_text", Default = "" })

    Section:Button({
        Name = "Save Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            writefile(Vortex.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg", Vortex:GetConfig())
            Vortex:UpdateConfigList()
            Notifications:Create({Name = "Saved Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Load Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            Vortex:LoadConfig(readfile(Vortex.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg"))
            Vortex:UpdateConfigList()
            Notifications:Create({Name = "Loaded Config: " .. Flags["config_Name_text"]})
        end
    })

    Section:Button({
        Name = "Delete Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            delfile(Vortex.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg")
            Vortex:UpdateConfigList()
            Notifications:Create({Name = "Deleted Config: " .. Flags["config_Name_text"]})
        end
    })

    local SectionRight = Tab:Section({Name = "Theme Settings", Side = "Right"})

    SectionRight:Colorpicker({Name = "Accent Color", Callback = function(color3) Vortex:RefreshTheme("accent", color3) end, Color = themes.preset.accent })
    SectionRight:Colorpicker({Name = "Background", Callback = function(color3) Vortex:RefreshTheme("background", color3) end, Color = themes.preset.background })
    SectionRight:Colorpicker({Name = "Sidebar Color", Callback = function(color3) Vortex:RefreshTheme("sidebar", color3) end, Color = themes.preset.sidebar })

    window.Tweening = true
    SectionRight:Keybind({
        Name = "Menu Bind",
        Callback = function(bool) if window.Tweening then return end window.ToggleMenu(bool) end,
        Default = Enum.KeyCode.RightShift
    })

    task.delay(1, function() window.Tweening = false end)
end

return Vortex

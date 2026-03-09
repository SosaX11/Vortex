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

-- Glassy Deep Crimson Theme (Perfectly matching the image)
local themes = {
    preset = {
        accent       = rgb(255, 200, 50),  -- Gold/Yellow for active toggles (Knob)
        
        background   = rgb(80, 15, 20),    -- Main glassy crimson background
        section      = rgb(110, 30, 35),   -- Button/Dropdown backgrounds
        element      = rgb(60, 10, 15),    -- Darker insets (Toggle backgrounds, etc.)
        
        outline      = rgb(160, 50, 60),   -- Very subtle borders
        text         = rgb(255, 255, 255), -- White primary text
        subtext      = rgb(230, 180, 185), -- Soft pinkish-white subtext
        
        tab_active   = rgb(130, 35, 45),   -- Highlighted tab background
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

function Vortex:RefreshTheme(theme, color3)
    themes.preset[theme] = color3
    for property, instances in themes.utility[theme] do
        for _, object in instances do object[property] = color3 end
    end
    for _, updateFunc in ipairs(Vortex.DynamicTheming) do updateFunc() end
end

-- Window Construction
function Vortex:Window(properties)
    local Cfg = {
        Title = properties.Title or properties.title or "VortexHub", 
        Size = properties.Size or properties.size or dim2(0, 680, 0, 480), 
        TabInfo = nil, Items = {}, Tweening = false, IsSwitchingTab = false;
    }

    if Vortex.Gui then Vortex.Gui:Destroy() end
    if Vortex.Other then Vortex.Other:Destroy() end

    Vortex.Gui = Vortex:Create("ScreenGui", { Parent = CoreGui, Name = "Vortex", Enabled = true, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    Vortex.Other = Vortex:Create("ScreenGui", { Parent = CoreGui, Name = "VortexOther", Enabled = false, IgnoreGuiInset = true })
    
    local Items = Cfg.Items
    local uiVisible = true

    Items.Wrapper = Vortex:Create("Frame", {
        Parent = Vortex.Gui, Position = dim2(0.5, -Cfg.Size.X.Offset / 2, 0.5, -Cfg.Size.Y.Offset / 2),
        Size = Cfg.Size, BackgroundTransparency = 1, BorderSizePixel = 0
    })
    
    -- Drop Shadow / Glow
    Items.Glow = Vortex:Create("ImageLabel", {
        Parent = Items.Wrapper, Position = dim2(0, -20, 0, -20), Size = dim2(1, 40, 1, 40),
        BackgroundTransparency = 1, Image = "rbxassetid://5028857084", ImageColor3 = rgb(255, 0, 0), ImageTransparency = 0.6,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(24, 24, 276, 276), ZIndex = 0
    })

    Items.Window = Vortex:Create("Frame", {
        Parent = Items.Wrapper, Position = dim2(0, 0, 0, 0), Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 1, ClipsDescendants = true
    })
    Vortex:Themify(Items.Window, "background", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 12) })
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1.5, Transparency = 0.5 }), "outline", "Color")

    -- Top Window Controls (Updated with clean icons)
    Items.TopBar = Vortex:Create("Frame", { Parent = Items.Window, Size = dim2(1, 0, 0, 35), BackgroundTransparency = 1, ZIndex = 10, Active = true })
    Vortex:Create("UIListLayout", {Parent = Items.TopBar, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = dim(0, 12)})
    Vortex:Create("UIPadding", {Parent = Items.TopBar, PaddingRight = dim(0, 16)})
    
    local closeBtn = Vortex:Create("ImageButton", {Parent = Items.TopBar, Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Image = "rbxassetid://10747384394", LayoutOrder = 3})
    local maxBtn = Vortex:Create("ImageButton", {Parent = Items.TopBar, Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Image = "rbxassetid://10747381665", LayoutOrder = 2})
    local minBtn = Vortex:Create("ImageButton", {Parent = Items.TopBar, Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Image = "rbxassetid://10747381486", LayoutOrder = 1})
    
    Vortex:Themify(closeBtn, "text", "ImageColor3")
    Vortex:Themify(maxBtn, "text", "ImageColor3")
    Vortex:Themify(minBtn, "text", "ImageColor3")

    -- Sidebar Area
    Items.Sidebar = Vortex:Create("Frame", { 
        Parent = Items.Window, Size = dim2(0, 180, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 
    })

    -- Sidebar Header / Logo
    Items.Header = Vortex:Create("Frame", { Parent = Items.Sidebar, Size = dim2(1, 0, 0, 60), BackgroundTransparency = 1 })
    
    Items.LogoIcon = Vortex:Create("TextLabel", {
        Parent = Items.Header, Text = "$", TextColor3 = themes.preset.text, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 15, 0.5, 0), Size = dim2(0, 24, 0, 24),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center
    })
    Vortex:Themify(Items.LogoIcon, "text", "TextColor3")

    Items.LogoText = Vortex:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.text, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 45, 0.5, 0), Size = dim2(1, -45, 0, 20),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
    })
    Vortex:Themify(Items.LogoText, "text", "TextColor3")

    -- Tab Holder
    Items.TabHolder = Vortex:Create("ScrollingFrame", { 
        Parent = Items.Sidebar, Position = dim2(0, 0, 0, 60), Size = dim2(1, 0, 1, -130), 
        BackgroundTransparency = 1, ScrollBarThickness = 0, BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Vortex:Create("UIListLayout", { Parent = Items.TabHolder, FillDirection = Enum.FillDirection.Vertical, Padding = dim(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center })
    Vortex:Create("UIPadding", { Parent = Items.TabHolder, PaddingTop = dim(0, 5), PaddingLeft = dim(0, 10), PaddingRight = dim(0, 10) })

    -- Profile Footer
    Items.Footer = Vortex:Create("Frame", { 
        Parent = Items.Sidebar, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 70), BackgroundTransparency = 1 
    })
    
    local headshot = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
    Items.AvatarFrame = Vortex:Create("Frame", {
        Parent = Items.Footer, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 15, 0.5, 0), Size = dim2(0, 32, 0, 32), BackgroundColor3 = themes.preset.element, BackgroundTransparency = 0.3, BorderSizePixel = 0
    })
    Vortex:Themify(Items.AvatarFrame, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.AvatarFrame, CornerRadius = dim(1, 0) })
    Items.Avatar = Vortex:Create("ImageLabel", { Parent = Items.AvatarFrame, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Image = headshot })
    Vortex:Create("UICorner", { Parent = Items.Avatar, CornerRadius = dim(1, 0) })

    Items.Username = Vortex:Create("TextLabel", {
        Parent = Items.Footer, Text = lp.DisplayName, TextColor3 = themes.preset.text, AnchorPoint = vec2(0, 0), Position = dim2(0, 55, 0, 18), Size = dim2(0, 110, 0, 16),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
    })
    Vortex:Themify(Items.Username, "text", "TextColor3")

    Items.Subname = Vortex:Create("TextLabel", {
        Parent = Items.Footer, Text = "@" .. lp.Name, TextColor3 = themes.preset.subtext, AnchorPoint = vec2(0, 0), Position = dim2(0, 55, 0, 34), Size = dim2(0, 110, 0, 14),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd
    })
    Vortex:Themify(Items.Subname, "subtext", "TextColor3")

    -- Content Area
    Items.PageHolder = Vortex:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 180, 0, 35), Size = dim2(1, -180, 1, -35), 
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
            Vortex:Tween(Items.Window, {BackgroundTransparency = 0.15}, TweenInfo.new(0.3))
            Vortex:Tween(Items.Glow, {ImageTransparency = 0.6}, TweenInfo.new(0.3))
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
            Parent = self.Items.TabHolder, Size = dim2(1, 0, 0, 34), 
            BackgroundColor3 = themes.preset.tab_active, BackgroundTransparency = 1, 
            Text = "", AutoButtonColor = false, ZIndex = 5 
        })
        Vortex:Themify(Items.Button, "tab_active", "BackgroundColor3")
        Vortex:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })
        
        Items.IconImg = Vortex:Create("ImageLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 10, 0.5, 0),
            Size = dim2(0, 16, 0, 16), BackgroundTransparency = 1, 
            Image = Cfg.Icon, ImageColor3 = themes.preset.subtext, ZIndex = 6 
        })
        Vortex:Themify(Items.IconImg, "subtext", "ImageColor3")

        Items.Label = Vortex:Create("TextLabel", {
            Parent = Items.Button, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 36, 0.5, 0), Size = dim2(1, -40, 0, 14),
            BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6
        })
        Vortex:Themify(Items.Label, "subtext", "TextColor3")
        
        Items.Button.MouseEnter:Connect(function()
            if self.TabInfo ~= Cfg.Items then Vortex:Tween(Items.Button, {BackgroundTransparency = 0.8}, TweenInfo.new(0.2)) end
        end)
        Items.Button.MouseLeave:Connect(function()
            if self.TabInfo ~= Cfg.Items then Vortex:Tween(Items.Button, {BackgroundTransparency = 1}, TweenInfo.new(0.2)) end
        end)
    end

    -- Fixed CanvasGroup issue by replacing it entirely with a standard Frame container
    Items.Pages = Vortex:Create("Frame", { Parent = Vortex.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false })
    
    -- Using Single Column to exactly match the image layout
    Items.Content = Vortex:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 2, ScrollBarImageColor3 = themes.preset.outline, BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Vortex:Themify(Items.Content, "outline", "ScrollBarImageColor3")
    Vortex:Create("UIListLayout", { Parent = Items.Content, Padding = dim(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center })
    Vortex:Create("UIPadding", { Parent = Items.Content, PaddingTop = dim(0, 5), PaddingBottom = dim(0, 15), PaddingRight = dim(0, 15), PaddingLeft = dim(0, 5) })

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg.Items then return end
        local oldTab = self.TabInfo
        self.IsSwitchingTab = true
        self.TabInfo = Cfg.Items

        local buttonTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        if oldTab and oldTab.Button then 
            Vortex:Tween(oldTab.Button, {BackgroundTransparency = 1}, buttonTween) 
            Vortex:Tween(oldTab.Label, {TextColor3 = themes.preset.subtext, Font = Enum.Font.GothamMedium}, buttonTween)
            Vortex:Tween(oldTab.IconImg, {ImageColor3 = themes.preset.subtext}, buttonTween)
        end
        
        if Items.Button then 
            Vortex:Tween(Items.Button, {BackgroundTransparency = 0.4}, buttonTween) 
            Vortex:Tween(Items.Label, {TextColor3 = themes.preset.text, Font = Enum.Font.GothamBold}, buttonTween)
            Vortex:Tween(Items.IconImg, {ImageColor3 = themes.preset.text}, buttonTween)
        end
        
        if oldTab then
            oldTab.Pages.Visible = false
            oldTab.Pages.Parent = Vortex.Other
        end

        Items.Pages.Parent = self.Items.PageHolder
        Items.Pages.Visible = true
        
        -- Small slide-up animation effect
        Items.Content.Position = dim2(0, 0, 0, 15)
        Vortex:Tween(Items.Content, {Position = dim2(0, 0, 0, 0)}, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
        
        self.IsSwitchingTab = false
    end

    if Items.Button then Items.Button.MouseButton1Down:Connect(Cfg.OpenTab) end
    if not self.TabInfo and not Cfg.Hidden then Cfg.OpenTab() end
    return setmetatable(Cfg, Vortex)
end

-- Sections
function Vortex:Section(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Section", 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Section = Vortex:Create("Frame", { 
        Parent = self.Items.Content, Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundTransparency = 1, BorderSizePixel = 0 
    })

    Items.Header = Vortex:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 25), BackgroundTransparency = 1 })
    
    Items.Title = Vortex:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 2, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, 0, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Vortex:Themify(Items.Title, "text", "TextColor3")

    Items.Container = Vortex:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 25), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Vortex:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })

    return setmetatable(Cfg, Vortex)
end

-- Toggles (Perfected matching the image)
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
    local height = hasSub and 50 or 36

    Items.Button = Vortex:Create("TextButton", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, height), 
        BackgroundColor3 = themes.preset.section, BackgroundTransparency = 0.5, AutoButtonColor = false, Text = ""
    })
    Vortex:Themify(Items.Button, "section", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.Button, Color = themes.preset.outline, Transparency = 0.5, Thickness = 1 }), "outline", "Color")

    Items.Title = Vortex:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 12, 0, hasSub and 10 or (height/2 - 7)), Size = dim2(1, -60, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Vortex:Themify(Items.Title, "text", "TextColor3")

    if hasSub then
        Items.Sub = Vortex:Create("TextLabel", { 
            Parent = Items.Button, Position = dim2(0, 12, 0, 26), Size = dim2(1, -60, 0, 24), 
            BackgroundTransparency = 1, Text = Cfg.Subtitle, TextColor3 = themes.preset.subtext, TextSize = 10, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true
        })
        Vortex:Themify(Items.Sub, "subtext", "TextColor3")
    end

    -- Inset Pill Background
    Items.SwitchBg = Vortex:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -12, 0.5, 0), Size = dim2(0, 32, 0, 18), 
        BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    Vortex:Themify(Items.SwitchBg, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.SwitchBg, CornerRadius = dim(1, 0) })
    
    -- Knob
    Items.SwitchKnob = Vortex:Create("Frame", {
        Parent = Items.SwitchBg, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 2, 0.5, 0),
        Size = dim2(0, 14, 0, 14), BackgroundColor3 = themes.preset.subtext, BorderSizePixel = 0
    })
    Vortex:Themify(Items.SwitchKnob, "subtext", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.SwitchKnob, CornerRadius = dim(1, 0) })

    local State = false
    function Cfg.set(bool)
        State = bool
        if State then
            Vortex:Tween(Items.SwitchKnob, {Position = dim2(1, -16, 0.5, 0), BackgroundColor3 = themes.preset.accent}, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        else
            Vortex:Tween(Items.SwitchKnob, {Position = dim2(0, 2, 0.5, 0), BackgroundColor3 = themes.preset.subtext}, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        end
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    table.insert(Vortex.DynamicTheming, function()
        if State then Items.SwitchKnob.BackgroundColor3 = themes.preset.accent else Items.SwitchKnob.BackgroundColor3 = themes.preset.subtext end
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
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 34), BackgroundColor3 = themes.preset.section, BackgroundTransparency = 0.5,
        Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 12, Font = Enum.Font.GothamBold, AutoButtonColor = false 
    })
    Vortex:Themify(Items.Button, "section", "BackgroundColor3")
    Vortex:Themify(Items.Button, "text", "TextColor3")
    Vortex:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 6) })
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.Button, Color = themes.preset.outline, Transparency = 0.5, Thickness = 1 }), "outline", "Color")

    Items.Button.MouseEnter:Connect(function()
        Vortex:Tween(Items.Button, {BackgroundTransparency = 0.2}, TweenInfo.new(0.2))
    end)
    Items.Button.MouseLeave:Connect(function()
        Vortex:Tween(Items.Button, {BackgroundTransparency = 0.5}, TweenInfo.new(0.2))
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
    
    Items.Container = Vortex:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 50), BackgroundTransparency = 1 })

    Items.Title = Vortex:Create("TextLabel", { Parent = Items.Container, Position = dim2(0, 4, 0, 0), Size = dim2(1, -8, 0, 16), BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Items.Title, "text", "TextColor3")

    Items.Main = Vortex:Create("TextButton", { 
        Parent = Items.Container, Position = dim2(0, 0, 0, 20), Size = dim2(1, 0, 0, 30), 
        BackgroundColor3 = themes.preset.section, BackgroundTransparency = 0.5, Text = "", AutoButtonColor = false 
    })
    Vortex:Themify(Items.Main, "section", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Main, CornerRadius = dim(0, 6) })
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.Main, Color = themes.preset.outline, Transparency = 0.5, Thickness = 1 }), "outline", "Color")

    Items.SelectedText = Vortex:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 12, 0, 0), Size = dim2(1, -36, 1, 0), BackgroundTransparency = 1, Text = "Select...", TextColor3 = themes.preset.subtext, TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Items.SelectedText, "subtext", "TextColor3")
    
    Items.Icon = Vortex:Create("TextLabel", { Parent = Items.Main, Position = dim2(1, -20, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Text = "↕", TextColor3 = themes.preset.subtext, Font = Enum.Font.GothamBold, TextSize = 12 })
    Vortex:Themify(Items.Icon, "subtext", "TextColor3")

    Items.DropFrame = Vortex:Create("Frame", { 
        Parent = Vortex.Gui, Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    Vortex:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 6) })
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.DropFrame, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Scroll = Vortex:Create("ScrollingFrame", { 
        Parent = Items.DropFrame, Size = dim2(1, 0, 1, -8), Position = dim2(0, 0, 0, 4), 
        BackgroundTransparency = 1, ScrollBarThickness = 2, ScrollBarImageColor3 = themes.preset.outline, BorderSizePixel = 0, ZIndex = 201 
    })
    Vortex:Themify(Items.Scroll, "outline", "ScrollBarImageColor3")
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
            local targetHeight = math.clamp(#Cfg.Options * 28 + 8, 0, 140)
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
                Text = tostring(opt), TextColor3 = themes.preset.subtext, TextSize = 12, 
                Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 202 
            })
            Vortex:Themify(btn, "subtext", "TextColor3")
            local padding = Vortex:Create("UIPadding", {Parent = btn, PaddingLeft = dim(0, 12)})
            
            btn.MouseEnter:Connect(function() Vortex:Tween(btn, {TextColor3 = themes.preset.text}, TweenInfo.new(0.2)) end)
            btn.MouseLeave:Connect(function() Vortex:Tween(btn, {TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2)) end)
            btn.MouseButton1Click:Connect(function() Cfg.set(opt); ToggleDropdown() end)
            table.insert(OptionBtns, btn)
        end
    end

    function Cfg.set(val)
        Items.SelectedText.Text = tostring(val)
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

    Items.Container = Vortex:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 48), BackgroundColor3 = themes.preset.section, BackgroundTransparency = 0.5, BorderSizePixel = 0 })
    Vortex:Themify(Items.Container, "section", "BackgroundColor3")
    Vortex:Create("UICorner", {Parent = Items.Container, CornerRadius = dim(0, 6)})
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.Container, Color = themes.preset.outline, Transparency = 0.5, Thickness = 1 }), "outline", "Color")

    Items.Title = Vortex:Create("TextLabel", { Parent = Items.Container, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 0, 26), BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Items.Title, "text", "TextColor3")

    Items.Val = Vortex:Create("TextLabel", { Parent = Items.Container, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 0, 26), BackgroundTransparency = 1, Text = tostring(Cfg.Default)..Cfg.Suffix, TextColor3 = themes.preset.subtext, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right })
    Vortex:Themify(Items.Val, "subtext", "TextColor3")

    Items.Track = Vortex:Create("TextButton", { Parent = Items.Container, Position = dim2(0, 12, 0, 32), Size = dim2(1, -24, 0, 6), BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false })
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
    Items.Bg = Vortex:Create("Frame", { Parent = Items.Container, Size = dim2(1, 0, 1, 0), BackgroundColor3 = themes.preset.section, BackgroundTransparency = 0.5 })
    Vortex:Themify(Items.Bg, "section", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Bg, CornerRadius = dim(0, 6) })
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.Bg, Color = themes.preset.outline, Transparency = 0.5, Thickness = 1 }), "outline", "Color")
    
    Items.Input = Vortex:Create("TextBox", { 
        Parent = Items.Bg, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
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
        Parent = self.Items.Container, Size = dim2(1, 0, 0, Cfg.Wrapped and 26 or 16), BackgroundTransparency = 1, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 12, TextWrapped = Cfg.Wrapped, 
        Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, 
        TextYAlignment = Cfg.Wrapped and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center 
    })
    Vortex:Themify(Items.Title, "subtext", "TextColor3")
    function Cfg.set(val) Items.Title.Text = tostring(val) end
    return setmetatable(Cfg, Vortex)
end

-- Save and Load System / Settings Config Tab
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

    local Tab = window:Tab({ Name = "Settings", Icon = "10734950309", Hidden = false })
    window.SettingsTabOpen = Tab.OpenTab

    local Section = Tab:Section({Name = "Configs"})

    ConfigHolder = Section:Dropdown({
        Name = "Available Configs",
        Options = {},
        Callback = function(option) if Text then Text.set(option) end end,
        Flag = "config_Name_list"
    })

    Vortex:UpdateConfigList()

    Text = Section:Textbox({ Name = "Config Name", Flag = "config_Name_text", Default = "" })

    Section:Button({
        Name = "Save Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            writefile(Vortex.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg", Vortex:GetConfig())
            Vortex:UpdateConfigList()
        end
    })

    Section:Button({
        Name = "Load Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            Vortex:LoadConfig(readfile(Vortex.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg"))
            Vortex:UpdateConfigList()
        end
    })

    Section:Button({
        Name = "Delete Config",
        Callback = function()
            if Flags["config_Name_text"] == "" then return end
            delfile(Vortex.Directory .. "/configs/" .. Flags["config_Name_text"] .. ".cfg")
            Vortex:UpdateConfigList()
        end
    })

    local SectionRight = Tab:Section({Name = "UI Preferences"})

    window.Tweening = true
    SectionRight:Keybind({
        Name = "Menu Bind",
        Callback = function(bool) if window.Tweening then return end window.ToggleMenu(bool) end,
        Default = Enum.KeyCode.RightShift
    })

    task.delay(1, function() window.Tweening = false end)
end

return Vortex

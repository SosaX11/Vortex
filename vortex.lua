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
Vortex.DynamicTheming = {} -- Added to track dynamic toggle updates
Vortex.Notifications= {Notifs = {}}
Vortex.__index      = Vortex

local Flags          = Vortex.Flags
local ConfigFlags    = Vortex.ConfigFlags
local Notifications  = Vortex.Notifications

local themes = {
    preset = {
        accent       = rgb(200, 30, 30),
        glow         = rgb(200, 30, 30),
        
        background   = rgb(16, 8, 8),
        section      = rgb(22, 12, 12),
        element      = rgb(30, 16, 16),
        
        outline      = rgb(55, 35, 35),
        text         = rgb(245, 245, 245),
        subtext      = rgb(170, 160, 160),
        
        tab_active   = rgb(180, 35, 35),
        tab_inactive = rgb(18, 18, 20),
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

-- misc helpers ok 
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

-- sexy color lightener for hover effects
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

function Vortex:Resizify(Parent)
    local UIS = game:GetService("UserInputService")
    local Resizing = Vortex:Create("TextButton", {
        AnchorPoint = vec2(1, 1), Position = dim2(1, 0, 1, 0), Size = dim2(0, 20, 0, 20),
        BorderSizePixel = 0, BackgroundTransparency = 1, Text = "", Parent = Parent, ZIndex = 999,
    })
    
    local grip = Vortex:Create("ImageLabel", {
        Parent = Resizing, AnchorPoint = vec2(1, 1), Position = dim2(1, -4, 1, -4), Size = dim2(0, 10, 0, 10),
        BackgroundTransparency = 1, Image = "rbxthumb://type=Asset&id=6153965706&w=150&h=150", ImageColor3 = themes.preset.subtext, ImageTransparency = 0.5
    })

    local IsResizing, StartInputPos, StartSize = false, nil, nil
    local MIN_SIZE = vec2(600, 450)
    local MAX_SIZE = vec2(1000, 800)

    Resizing.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            IsResizing = true; StartInputPos = input.Position; StartSize = Parent.AbsoluteSize
        end
    end)
    Resizing.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then IsResizing = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if not IsResizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - StartInputPos
            Parent.Size = UDim2.fromOffset(math.clamp(StartSize.X + delta.X, MIN_SIZE.X, MAX_SIZE.X), math.clamp(StartSize.Y + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y))
        end
    end)
end

-- window hahaa
function Vortex:Window(properties)
    local Cfg = {
        Title = properties.Title or properties.title or properties.Prefix or "Vortex", 
        Subtitle = properties.Subtitle or properties.subtitle or properties.Suffix or "",
        Logo = properties.Logo or properties.logo or "rbxthumb://type=Asset&id=140047555271064&w=150&h=150",
        Size = properties.Size or properties.size or dim2(0, 720, 0, 500), 
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
    
    Items.Glow = Vortex:Create("ImageLabel", {
        ImageColor3 = themes.preset.glow,
        ScaleType = Enum.ScaleType.Slice,
        ImageTransparency = 0.65, 
        BorderColor3 = rgb(0, 0, 0),
        Parent = Items.Wrapper,
        Name = "\0",
        Size = dim2(1, 40, 1, 40),       
        Image = "rbxassetid://18245826428",
        BackgroundTransparency = 1,
        Position = dim2(0, -20, 0, -20), 
        BackgroundColor3 = rgb(255, 255, 255),
        BorderSizePixel = 0,
        SliceCenter = rect(vec2(21, 21), vec2(79, 79)),
        ZIndex = 0
    })
    Vortex:Themify(Items.Glow, "glow", "ImageColor3")

    Items.Window = Vortex:Create("Frame", {
        Parent = Items.Wrapper, Position = dim2(0, 0, 0, 0), Size = dim2(1, 0, 1, 0),
        BackgroundColor3 = themes.preset.background, BorderSizePixel = 0, ZIndex = 1, ClipsDescendants = true
    })
    Vortex:Themify(Items.Window, "background", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Window, CornerRadius = dim(0, 8) }) -- Smoother radius
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.Window, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.Header = Vortex:Create("Frame", { Parent = Items.Window, Size = dim2(1, 0, 0, 55), BackgroundTransparency = 1, Active = true, ZIndex = 2 })
    
    -- Aesthetic Header underline
    Vortex:Themify(Vortex:Create("Frame", {Parent = Items.Header, Size = dim2(1, 0, 0, 1), Position = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.outline, BorderSizePixel = 0}), "outline", "BackgroundColor3")

    if Cfg.Logo and Cfg.Logo ~= "" then
        -- Custom Image Logo
        Items.LogoBlock = Vortex:Create("ImageLabel", {
            Parent = Items.Header, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 20, 0.5, 0), 
            Size = dim2(0, 36, 0, 36), 
            BackgroundTransparency = 1, BorderSizePixel = 0, Image = Cfg.Logo, 
            ScaleType = Enum.ScaleType.Fit, -- This prevents blurriness and stretching
            ZIndex = 4
        })
    else
        -- Default placeholder Logo
        Items.LogoBlock = Vortex:Create("Frame", {
            Parent = Items.Header, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 20, 0.5, 0), 
            Size = dim2(0, 26, 0, 26), 
            BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 4
        })
        Vortex:Create("UICorner", { Parent = Items.LogoBlock, CornerRadius = dim(0, 6) })
        Vortex:Themify(Items.LogoBlock, "accent", "BackgroundColor3")
        Vortex:Create("UIGradient", { Parent = Items.LogoBlock, Rotation = 45, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255, 255, 255)), ColorSequenceKeypoint.new(1, rgb(180, 180, 180))}) })
    end

    Items.LogoText = Vortex:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Title, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 66, 0, 14), -- Shifted right to fit 36x36 logo
        Size = dim2(0, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Vortex:Themify(Items.LogoText, "text", "TextColor3")

    Items.SubLogoText = Vortex:Create("TextLabel", {
        Parent = Items.Header, Text = Cfg.Subtitle, TextColor3 = themes.preset.subtext,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 66, 0, 28), -- Shifted right to fit 36x36 logo
        Size = dim2(0, 0, 0, 12), AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4
    })
    Vortex:Themify(Items.SubLogoText, "subtext", "TextColor3")

    Items.TabHolder = Vortex:Create("Frame", { 
        Parent = Items.Header, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -20, 0.5, 0),
        Size = dim2(1, -200, 1, 0), BackgroundTransparency = 1, ZIndex = 4
    })
    Vortex:Create("UIListLayout", { Parent = Items.TabHolder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = dim(0, 8) })

    Items.Footer = Vortex:Create("Frame", { 
        Parent = Items.Window, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), 
        Size = dim2(1, 0, 0, 55), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 
    })
    Vortex:Themify(Vortex:Create("Frame", {Parent = Items.Footer, Size = dim2(1, 0, 0, 1), Position = dim2(0, 0, 0, 0), BackgroundColor3 = themes.preset.outline, BorderSizePixel = 0}), "outline", "BackgroundColor3")


    local headshot = "rbxthumb://type=AvatarHeadShot&id="..lp.UserId.."&w=48&h=48"
    Items.AvatarFrame = Vortex:Create("Frame", {
        Parent = Items.Footer, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 20, 0.5, 0), 
        Size = dim2(0, 30, 0, 30), BackgroundColor3 = themes.preset.element, BorderSizePixel = 0, ZIndex = 5
    })
    Vortex:Themify(Items.AvatarFrame, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.AvatarFrame, CornerRadius = dim(1, 0) }) -- Circle avatar
    
    Items.Avatar = Vortex:Create("ImageLabel", { 
        Parent = Items.AvatarFrame, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0), 
        Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Image = headshot, ZIndex = 6 
    })
    Vortex:Create("UICorner", { Parent = Items.Avatar, CornerRadius = dim(1, 0) })

    Items.Username = Vortex:Create("TextLabel", {
        Parent = Items.Footer, Text = lp.Name, TextColor3 = themes.preset.text,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 60, 0, 13), Size = dim2(0, 200, 0, 14),
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5
    })
    Vortex:Themify(Items.Username, "text", "TextColor3")

    Items.Status = Vortex:Create("TextLabel", {
        Parent = Items.Footer, Text = "Status : Premium", TextColor3 = themes.preset.accent,
        AnchorPoint = vec2(0, 0), Position = dim2(0, 60, 0, 28), Size = dim2(0, 200, 0, 12),
        BackgroundTransparency = 1, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5
    })
    Vortex:Themify(Items.Status, "accent", "TextColor3")

    Items.SettingsBtn = Vortex:Create("ImageButton", {
        Parent = Items.Footer, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -25, 0.5, 0),
        Size = dim2(0, 18, 0, 18), BackgroundTransparency = 1, Image = "rbxassetid://11293977610", ImageColor3 = themes.preset.subtext, ZIndex = 5
    })
    Vortex:Themify(Items.SettingsBtn, "subtext", "ImageColor3")
    
    -- Hover effect for settings button
    Items.SettingsBtn.MouseEnter:Connect(function() Vortex:Tween(Items.SettingsBtn, {ImageColor3 = themes.preset.text}, TweenInfo.new(0.2)) end)
    Items.SettingsBtn.MouseLeave:Connect(function() Vortex:Tween(Items.SettingsBtn, {ImageColor3 = themes.preset.subtext}, TweenInfo.new(0.2)) end)

    Items.SettingsBtn.MouseButton1Click:Connect(function()
        Vortex:Tween(Items.SettingsBtn, {Rotation = Items.SettingsBtn.Rotation + 90}, TweenInfo.new(0.3, Enum.EasingStyle.Back))
        if Cfg.SettingsTabOpen then Cfg.SettingsTabOpen() end
    end)

    Items.PageHolder = Vortex:Create("Frame", { 
        Parent = Items.Window, Position = dim2(0, 0, 0, 55), Size = dim2(1, 0, 1, -110), 
        BackgroundTransparency = 1, ClipsDescendants = true 
    })

    -- Dragging Logic
    local Dragging, DragInput, DragStart, StartPos
    Items.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true; DragStart = input.Position; StartPos = Items.Wrapper.Position
        end
    end)
    Items.Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Dragging = false end
    end)
    InputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - DragStart
            Items.Wrapper.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
        end
    end)
    Vortex:Resizify(Items.Wrapper)

    function Cfg.ToggleMenu(bool)
        if Cfg.Tweening then return end
        if bool == nil then uiVisible = not uiVisible else uiVisible = bool end
        
        if uiVisible then
            Items.Wrapper.Visible = true
            Vortex:Tween(Items.Wrapper, {Size = Cfg.Size}, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
            Vortex:Tween(Items.Window, {BackgroundTransparency = 0}, TweenInfo.new(0.3))
        else
            Vortex:Tween(Items.Wrapper, {Size = dim2(0, Cfg.Size.X.Offset, 0, 0)}, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In))
            Vortex:Tween(Items.Window, {BackgroundTransparency = 1}, TweenInfo.new(0.3))
            task.delay(0.4, function() Items.Wrapper.Visible = false end)
        end
    end

    if InputService.TouchEnabled then
        Vortex.ToggleGui = Vortex:Create("ScreenGui", { Parent = CoreGui, Name = "VortexToggle", IgnoreGuiInset = true })
        local ToggleButton = Vortex:Create("ImageButton", {
            Name = "ToggleButton", Parent = Vortex.ToggleGui, Position = UDim2.new(1, -80, 0, 150), Size = UDim2.new(0, 55, 0, 55),
            BackgroundTransparency = 0.2, BackgroundColor3 = themes.preset.element, Image = "rbxassetid://140047555271064", ZIndex = 10000,
        })
        Vortex:Create("UICorner", { Parent = ToggleButton, CornerRadius = dim(0, 16) })
        Vortex:Themify(ToggleButton, "element", "BackgroundColor3")
        Vortex:Themify(Vortex:Create("UIStroke", { Parent = ToggleButton, Color = themes.preset.outline, Thickness = 1.5 }), "outline", "Color")

        local isTDrag, tDragStart, tStartPos, hasTDragged = false, nil, nil, false
        ToggleButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = true; hasTDragged = false; tDragStart = input.Position; tStartPos = ToggleButton.Position
                Vortex:Tween(ToggleButton, {Size = dim2(0, 45, 0, 45)}, TweenInfo.new(0.2))
            end
        end)
        ToggleButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isTDrag = false; 
                Vortex:Tween(ToggleButton, {Size = dim2(0, 55, 0, 55)}, TweenInfo.new(0.2, Enum.EasingStyle.Back))
                if not hasTDragged then Cfg.ToggleMenu() end
            end
        end)
        InputService.InputChanged:Connect(function(input)
            if isTDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - tDragStart
                if delta.Magnitude > 5 then hasTDragged = true; ToggleButton.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y) end
            end
        end)
    end

    return setmetatable(Cfg, Vortex)
end

-- tabs okk :joy:
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
            Parent = self.Items.TabHolder, Size = dim2(0, 32, 0, 32), 
            BackgroundColor3 = themes.preset.tab_active,
            BackgroundTransparency = 1, 
            Text = "", AutoButtonColor = false, ZIndex = 5 
        })
        Vortex:Themify(Items.Button, "tab_active", "BackgroundColor3")
        Vortex:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 8) })
        
        Items.IconImg = Vortex:Create("ImageLabel", { 
            Parent = Items.Button, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
            Size = dim2(0, 16, 0, 16), BackgroundTransparency = 1, 
            Image = Cfg.Icon, ImageColor3 = themes.preset.subtext, ZIndex = 6 
        })
        Vortex:Themify(Items.IconImg, "subtext", "ImageColor3")
        
        -- Tab Hover animation
        Items.Button.MouseEnter:Connect(function()
            if self.TabInfo ~= Cfg.Items then
                Vortex:Tween(Items.IconImg, {ImageColor3 = themes.preset.text, Size = dim2(0, 18, 0, 18)}, TweenInfo.new(0.2))
            end
        end)
        Items.Button.MouseLeave:Connect(function()
            if self.TabInfo ~= Cfg.Items then
                Vortex:Tween(Items.IconImg, {ImageColor3 = themes.preset.subtext, Size = dim2(0, 16, 0, 16)}, TweenInfo.new(0.2))
            end
        end)
    end

    Items.Pages = Vortex:Create("CanvasGroup", { Parent = Vortex.Other, Size = dim2(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
    Vortex:Create("UIListLayout", { Parent = Items.Pages, FillDirection = Enum.FillDirection.Horizontal, Padding = dim(0, 16) })
    Vortex:Create("UIPadding", { Parent = Items.Pages, PaddingTop = dim(0, 14), PaddingBottom = dim(0, 14), PaddingRight = dim(0, 20), PaddingLeft = dim(0, 20) })

    Items.Left = Vortex:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -8, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 2, ScrollBarImageColor3 = themes.preset.subtext, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Vortex:Themify(Items.Left, "subtext", "ScrollBarImageColor3")
    Vortex:Create("UIListLayout", { Parent = Items.Left, Padding = dim(0, 16) })
    Vortex:Create("UIPadding", { Parent = Items.Left, PaddingBottom = dim(0, 10), PaddingRight = dim(0, 4) })

    Items.Right = Vortex:Create("ScrollingFrame", { 
        Parent = Items.Pages, Size = dim2(0.5, -8, 1, 0), BackgroundTransparency = 1, 
        ScrollBarThickness = 2, ScrollBarImageColor3 = themes.preset.subtext, CanvasSize = dim2(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Vortex:Themify(Items.Right, "subtext", "ScrollBarImageColor3")
    Vortex:Create("UIListLayout", { Parent = Items.Right, Padding = dim(0, 16) })
    Vortex:Create("UIPadding", { Parent = Items.Right, PaddingBottom = dim(0, 10), PaddingRight = dim(0, 4) })

    function Cfg.OpenTab()
        if self.IsSwitchingTab or self.TabInfo == Cfg.Items then return end
        local oldTab = self.TabInfo
        self.IsSwitchingTab = true
        self.TabInfo = Cfg.Items

        local buttonTween = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        if oldTab and oldTab.Button then
            Vortex:Tween(oldTab.Button, {BackgroundTransparency = 1}, buttonTween)
            Vortex:Tween(oldTab.IconImg, {ImageColor3 = themes.preset.subtext, Size = dim2(0, 16, 0, 16)}, buttonTween)
        end

        if Items.Button then 
            Vortex:Tween(Items.Button, {BackgroundTransparency = 0}, buttonTween)
            Vortex:Tween(Items.IconImg, {ImageColor3 = rgb(255, 255, 255), Size = dim2(0, 18, 0, 18)}, buttonTween) 
        end
        
        task.spawn(function()
            if oldTab then
                Vortex:Tween(oldTab.Pages, {GroupTransparency = 1, Position = dim2(0, 0, 0, 15)}, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
                task.wait(0.2)
                oldTab.Pages.Visible = false
                oldTab.Pages.Parent = Vortex.Other
            end

            Items.Pages.Position = dim2(0, 0, 0, -15) 
            Items.Pages.GroupTransparency = 1
            Items.Pages.Parent = self.Items.PageHolder
            Items.Pages.Visible = true

            Vortex:Tween(Items.Pages, {GroupTransparency = 0, Position = dim2(0, 0, 0, 0)}, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
            task.wait(0.4)
            
            Items.Pages.GroupTransparency = 0 
            self.IsSwitchingTab = false
        end)
    end

    if Items.Button then Items.Button.MouseButton1Down:Connect(Cfg.OpenTab) end
    if not self.TabInfo and not Cfg.Hidden then Cfg.OpenTab() end
    return setmetatable(Cfg, Vortex)
end

-- sections okk
function Vortex:Section(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Section", 
        Side = properties.Side or properties.side or "Left", 
        Icon = properties.Icon or properties.icon or "rbxassetid://11293977610", 
        RightIcon = properties.RightIcon or properties.righticon or "rbxassetid://11293977610", 
        Items = {} 
    }
    Cfg.Side = (Cfg.Side:lower() == "right") and "Right" or "Left"
    local Items = Cfg.Items

    Items.Section = Vortex:Create("Frame", { 
        Parent = self.Items[Cfg.Side], Size = dim2(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundColor3 = themes.preset.section, BorderSizePixel = 0, ClipsDescendants = true 
    })
    Vortex:Themify(Items.Section, "section", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Section, CornerRadius = dim(0, 8) })
    Vortex:Themify(Vortex:Create("UIStroke", {Parent = Items.Section, Color = themes.preset.outline, Thickness = 1}), "outline", "Color")

    -- Sexy Gradient Red/Accent Line
    Items.AccentLine = Vortex:Create("Frame", {
        Parent = Items.Section, Size = dim2(0, 3, 1, 0), Position = dim2(0, 0, 0, 0),
        BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 2
    })
    Vortex:Themify(Items.AccentLine, "accent", "BackgroundColor3")
    Vortex:Create("UIGradient", {
        Parent = Items.AccentLine, Rotation = 90,
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    })

    Items.Header = Vortex:Create("Frame", { Parent = Items.Section, Size = dim2(1, 0, 0, 40), BackgroundTransparency = 1 })
    
    Items.Icon = Vortex:Create("ImageLabel", {
        Parent = Items.Header, Position = dim2(0, 18, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 16, 0, 16),
        BackgroundTransparency = 1, Image = Cfg.Icon, ImageColor3 = themes.preset.subtext
    })
    Vortex:Themify(Items.Icon, "subtext", "ImageColor3")

    Items.Title = Vortex:Create("TextLabel", { 
        Parent = Items.Header, Position = dim2(0, 42, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -70, 0, 14), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.text, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left 
    })
    Vortex:Themify(Items.Title, "text", "TextColor3")

    Items.Chevron = Vortex:Create("ImageLabel", {
        Parent = Items.Header, Position = dim2(1, -16, 0.5, 0), AnchorPoint = vec2(1, 0.5), Size = dim2(0, 14, 0, 14),
        BackgroundTransparency = 1, Image = Cfg.RightIcon, ImageColor3 = themes.preset.subtext, 
        Rotation = (Cfg.RightIcon == "rbxassetid://11293977610") and 180 or 0 
    })
    Vortex:Themify(Items.Chevron, "subtext", "ImageColor3")

    Items.Container = Vortex:Create("Frame", { 
        Parent = Items.Section, Position = dim2(0, 0, 0, 40), Size = dim2(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 
    })
    Vortex:Create("UIListLayout", { Parent = Items.Container, Padding = dim(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    Vortex:Create("UIPadding", { Parent = Items.Container, PaddingBottom = dim(0, 14), PaddingLeft = dim(0, 16), PaddingRight = dim(0, 16) })

    return setmetatable(Cfg, Vortex)
end

-- elements okk
function Vortex:Toggle(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Toggle", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or false, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local Items = Cfg.Items

    Items.Button = Vortex:Create("TextButton", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 24), BackgroundTransparency = 1, Text = "" })
    
    Items.Checkbox = Vortex:Create("Frame", { 
        Parent = Items.Button, AnchorPoint = vec2(0, 0.5), Position = dim2(0, 6, 0.5, 0), Size = dim2(0, 18, 0, 18), 
        BackgroundColor3 = themes.preset.element, BorderSizePixel = 0 
    })
    Vortex:Create("UICorner", { Parent = Items.Checkbox, CornerRadius = dim(0, 4) })
    Items.Stroke = Vortex:Create("UIStroke", { Parent = Items.Checkbox, Color = themes.preset.outline, Thickness = 1 })
    Vortex:Themify(Items.Stroke, "outline", "Color")

    -- Sexy Checkmark Icon
    Items.CheckIcon = Vortex:Create("ImageLabel", {
        Parent = Items.Checkbox, AnchorPoint = vec2(0.5, 0.5), Position = dim2(0.5, 0, 0.5, 0),
        Size = dim2(0, 0, 0, 0), BackgroundTransparency = 1, Image = "rbxassetid://10709790644", ImageColor3 = rgb(255,255,255), ImageTransparency = 1
    })

    Items.Title = Vortex:Create("TextLabel", { 
        Parent = Items.Button, Position = dim2(0, 34, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(1, -34, 1, 0), 
        BackgroundTransparency = 1, Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left 
    })

    local State = false
    function Cfg.set(bool)
        State = bool
        if State then
            Vortex:Tween(Items.Checkbox, {BackgroundColor3 = themes.preset.accent}, TweenInfo.new(0.2))
            Vortex:Tween(Items.Stroke, {Color = themes.preset.accent}, TweenInfo.new(0.2))
            Vortex:Tween(Items.Title, {TextColor3 = themes.preset.text}, TweenInfo.new(0.2))
            Vortex:Tween(Items.CheckIcon, {Size = dim2(0, 12, 0, 12), ImageTransparency = 0}, TweenInfo.new(0.3, Enum.EasingStyle.Back))
        else
            Vortex:Tween(Items.Checkbox, {BackgroundColor3 = themes.preset.element}, TweenInfo.new(0.2))
            Vortex:Tween(Items.Stroke, {Color = themes.preset.outline}, TweenInfo.new(0.2))
            Vortex:Tween(Items.Title, {TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2))
            Vortex:Tween(Items.CheckIcon, {Size = dim2(0, 0, 0, 0), ImageTransparency = 1}, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In))
        end
        if Cfg.Flag then Flags[Cfg.Flag] = State end
        Cfg.Callback(State)
    end

    -- Hover effect
    Items.Button.MouseEnter:Connect(function() 
        if not State then Vortex:Tween(Items.Title, {TextColor3 = themes.preset.text}, TweenInfo.new(0.2)) end
    end)
    Items.Button.MouseLeave:Connect(function() 
        if not State then Vortex:Tween(Items.Title, {TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2)) end
    end)

    table.insert(Vortex.DynamicTheming, function()
        Items.Checkbox.BackgroundColor3 = State and themes.preset.accent or themes.preset.element
        Items.Title.TextColor3 = State and themes.preset.text or themes.preset.subtext
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
        Parent = self.Items.Container, Size = dim2(1, 0, 0, 32), BackgroundColor3 = themes.preset.element, 
        Text = Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), AutoButtonColor = false 
    })
    Vortex:Themify(Items.Button, "element", "BackgroundColor3")
    Vortex:Themify(Items.Button, "subtext", "TextColor3")
    Items.Stroke = Vortex:Create("UIStroke", { Parent = Items.Button, Color = themes.preset.outline, Thickness = 1 })
    Vortex:Themify(Items.Stroke, "outline", "Color")

    Vortex:Create("UICorner", { Parent = Items.Button, CornerRadius = dim(0, 4) })

    Items.Button.MouseEnter:Connect(function()
        Vortex:Tween(Items.Button, {BackgroundColor3 = Vortex:Lighten(themes.preset.element, 0.05), TextColor3 = themes.preset.text}, TweenInfo.new(0.2))
        Vortex:Tween(Items.Stroke, {Color = Vortex:Lighten(themes.preset.outline, 0.1)}, TweenInfo.new(0.2))
    end)
    Items.Button.MouseLeave:Connect(function()
        Vortex:Tween(Items.Button, {BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2))
        Vortex:Tween(Items.Stroke, {Color = themes.preset.outline}, TweenInfo.new(0.2))
    end)

    Items.Button.MouseButton1Click:Connect(function()
        Vortex:Tween(Items.Button, {Size = dim2(1, -4, 0, 28)}, TweenInfo.new(0.1, Enum.EasingStyle.Quint))
        task.wait(0.1)
        Vortex:Tween(Items.Button, {Size = dim2(1, 0, 0, 32)}, TweenInfo.new(0.3, Enum.EasingStyle.Back))
        Cfg.Callback()
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

    Items.Container = Vortex:Create("Frame", { Parent = self.Items.Container, Size = dim2(1, 0, 0, 42), BackgroundTransparency = 1 })
    Items.Title = Vortex:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 20), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Items.Title, "subtext", "TextColor3")

    Items.Val = Vortex:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 20), BackgroundTransparency = 1, Text = tostring(Cfg.Default)..Cfg.Suffix, TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold), TextXAlignment = Enum.TextXAlignment.Right })
    Vortex:Themify(Items.Val, "text", "TextColor3")

    Items.Track = Vortex:Create("TextButton", { Parent = Items.Container, Position = dim2(0, 4, 0, 26), Size = dim2(1, -8, 0, 6), BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false })
    Vortex:Themify(Items.Track, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Track, CornerRadius = dim(1, 0) })
    Vortex:Themify(Vortex:Create("UIStroke", {Parent = Items.Track, Color = themes.preset.outline}), "outline", "Color")

    Items.Fill = Vortex:Create("Frame", { Parent = Items.Track, Size = dim2(0, 0, 1, 0), BackgroundColor3 = themes.preset.accent })
    Vortex:Themify(Items.Fill, "accent", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Fill, CornerRadius = dim(1, 0) })
    -- Gradient for premium feel
    Vortex:Create("UIGradient", { Parent = Items.Fill, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255,255,255)), ColorSequenceKeypoint.new(1, rgb(200,200,200))}) })
    
    Items.Knob = Vortex:Create("Frame", { Parent = Items.Fill, AnchorPoint = vec2(0.5, 0.5), Position = dim2(1, 0, 0.5, 0), Size = dim2(0, 12, 0, 12), BackgroundColor3 = rgb(255,255,255) })
    Vortex:Create("UICorner", { Parent = Items.Knob, CornerRadius = dim(1, 0) })
    Vortex:Create("UIStroke", { Parent = Items.Knob, Color = rgb(0,0,0), Transparency = 0.5 }) -- Drop shadow feel
    
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
    Items.Bg = Vortex:Create("Frame", { Parent = Items.Container, Size = dim2(1, 0, 1, 0), BackgroundColor3 = themes.preset.element })
    Vortex:Themify(Items.Bg, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Bg, CornerRadius = dim(0, 4) })
    
    Items.Stroke = Vortex:Create("UIStroke", {Parent = Items.Bg, Color = themes.preset.outline, Thickness = 1})
    Vortex:Themify(Items.Stroke, "outline", "Color")

    Items.Input = Vortex:Create("TextBox", { 
        Parent = Items.Bg, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, 
        Text = Cfg.Default, PlaceholderText = Cfg.Placeholder, TextColor3 = themes.preset.text, PlaceholderColor3 = themes.preset.subtext, 
        TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false 
    })
    Vortex:Themify(Items.Input, "text", "TextColor3")

    -- Sexy focus highlight
    Items.Input.Focused:Connect(function() 
        Vortex:Tween(Items.Stroke, {Color = themes.preset.accent}, TweenInfo.new(0.3)) 
    end)
    Items.Input.FocusLost:Connect(function() 
        Vortex:Tween(Items.Stroke, {Color = themes.preset.outline}, TweenInfo.new(0.3)) 
        Cfg.set(Items.Input.Text) 
    end)

    function Cfg.set(val)
        if Cfg.Numeric and tonumber(val) == nil and val ~= "" then return end
        Items.Input.Text = tostring(val)
        if Cfg.Flag then Flags[Cfg.Flag] = val end
        Cfg.Callback(val)
    end
    
    if Cfg.Default ~= "" then Cfg.set(Cfg.Default) end
    if Cfg.Flag then ConfigFlags[Cfg.Flag] = Cfg.set end

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
    Items.Title = Vortex:Create("TextLabel", { Parent = Items.Container, Size = dim2(1, 0, 0, 16), BackgroundTransparency = 1, Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Items.Title, "subtext", "TextColor3")

    Items.Main = Vortex:Create("TextButton", { 
        Parent = Items.Container, Position = dim2(0, 0, 0, 20), Size = dim2(1, 0, 0, 30), 
        BackgroundColor3 = themes.preset.element, Text = "", AutoButtonColor = false 
    })
    Vortex:Themify(Items.Main, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.Main, CornerRadius = dim(0, 4) })
    Items.MainStroke = Vortex:Create("UIStroke", { Parent = Items.Main, Color = themes.preset.outline, Thickness = 1 })
    Vortex:Themify(Items.MainStroke, "outline", "Color")

    Items.SelectedText = Vortex:Create("TextLabel", { Parent = Items.Main, Position = dim2(0, 12, 0, 0), Size = dim2(1, -24, 1, 0), BackgroundTransparency = 1, Text = "...", TextColor3 = themes.preset.text, TextSize = 13, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold), TextXAlignment = Enum.TextXAlignment.Left })
    Vortex:Themify(Items.SelectedText, "text", "TextColor3")
    
    Items.Icon = Vortex:Create("ImageLabel", { Parent = Items.Main, Position = dim2(1, -20, 0.5, 0), AnchorPoint = vec2(0, 0.5), Size = dim2(0, 12, 0, 12), BackgroundTransparency = 1, Image = "rbxassetid://11293977610", ImageColor3 = themes.preset.subtext, Rotation = 180 })

    Items.DropFrame = Vortex:Create("Frame", { 
        Parent = Vortex.Gui, Size = dim2(1, 0, 0, 0), Position = dim2(0, 0, 0, 0), 
        BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true 
    })
    Vortex:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 4) })
    Items.DropStroke = Vortex:Create("UIStroke", { Parent = Items.DropFrame, Color = themes.preset.outline, Thickness = 1 })
    Vortex:Themify(Items.DropStroke, "outline", "Color")

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
            Vortex:Tween(Items.Icon, {Rotation = 0}, TweenInfo.new(0.3, Enum.EasingStyle.Back))
            Vortex:Tween(Items.MainStroke, {Color = themes.preset.accent}, TweenInfo.new(0.3))
            local tw = Vortex:Tween(Items.DropFrame, {Size = dim2(0, Items.Main.AbsoluteSize.X, 0, targetHeight)}, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
            tw.Completed:Wait()
        else
            Vortex:Tween(Items.Icon, {Rotation = 180}, TweenInfo.new(0.3, Enum.EasingStyle.Back))
            Vortex:Tween(Items.MainStroke, {Color = themes.preset.outline}, TweenInfo.new(0.3))
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
            local padding = Vortex:Create("UIPadding", {Parent = btn, PaddingLeft = dim(0, 12)})
            
            -- Sexy slide hover effect
            btn.MouseEnter:Connect(function()
                Vortex:Tween(btn, {TextColor3 = themes.preset.text}, TweenInfo.new(0.2))
                Vortex:Tween(padding, {PaddingLeft = dim(0, 18)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint))
            end)
            btn.MouseLeave:Connect(function()
                Vortex:Tween(btn, {TextColor3 = themes.preset.subtext}, TweenInfo.new(0.2))
                Vortex:Tween(padding, {PaddingLeft = dim(0, 12)}, TweenInfo.new(0.3, Enum.EasingStyle.Quint))
            end)

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

function Vortex:Label(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Label", 
        Wrapped = properties.Wrapped or properties.wrapped or false, 
        Items = {} 
    }
    local Items = Cfg.Items
    Items.Title = Vortex:Create("TextLabel", { 
        Parent = self.Items.Container, Size = dim2(1, 0, 0, Cfg.Wrapped and 26 or 18), BackgroundTransparency = 1, 
        Text = "  " .. Cfg.Name, TextColor3 = themes.preset.subtext, TextSize = 13, TextWrapped = Cfg.Wrapped, 
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), TextXAlignment = Enum.TextXAlignment.Left, 
        TextYAlignment = Cfg.Wrapped and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center 
    })
    Vortex:Themify(Items.Title, "subtext", "TextColor3")
    
    function Cfg.set(val) Items.Title.Text = "  " .. tostring(val) end
    return setmetatable(Cfg, Vortex)
end

function Vortex:Colorpicker(properties)
    local Cfg = { 
        Color = properties.Color or properties.color or rgb(255, 255, 255), 
        Callback = properties.Callback or properties.callback or function() end, 
        Flag = properties.Flag or properties.flag, 
        Items = {} 
    }
    local Items = Cfg.Items

    local btn = Vortex:Create("TextButton", { Parent = self.Items.Title or self.Items.Button or self.Items.Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -6, 0.5, 0), Size = dim2(0, 36, 0, 16), BackgroundColor3 = Cfg.Color, Text = "" })
    Vortex:Create("UICorner", {Parent = btn, CornerRadius = dim(0, 4)})
    Vortex:Themify(Vortex:Create("UIStroke", {Parent = btn, Color = themes.preset.outline, Thickness = 1}), "outline", "Color")

    local h, s, v = Color3.toHSV(Cfg.Color)
    
    Items.DropFrame = Vortex:Create("Frame", { Parent = Vortex.Gui, Size = dim2(0, 160, 0, 0), BackgroundColor3 = themes.preset.element, Visible = false, ZIndex = 200, ClipsDescendants = true })
    Vortex:Themify(Items.DropFrame, "element", "BackgroundColor3")
    Vortex:Create("UICorner", { Parent = Items.DropFrame, CornerRadius = dim(0, 6) })
    Vortex:Themify(Vortex:Create("UIStroke", { Parent = Items.DropFrame, Color = themes.preset.outline, Thickness = 1 }), "outline", "Color")

    Items.SVMap = Vortex:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 10, 0, 10), Size = dim2(1, -20, 1, -44), AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 201 })
    Vortex:Create("UICorner", { Parent = Items.SVMap, CornerRadius = dim(0, 4) })
    Items.SVImage = Vortex:Create("ImageLabel", { Parent = Items.SVMap, Size = dim2(1, 0, 1, 0), Image = "rbxassetid://4155801252", BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 202 })
    Vortex:Create("UICorner", { Parent = Items.SVImage, CornerRadius = dim(0, 4) })
    
    Items.SVKnob = Vortex:Create("Frame", { Parent = Items.SVMap, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 6, 0, 6), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Vortex:Create("UICorner", { Parent = Items.SVKnob, CornerRadius = dim(1, 0) })
    Vortex:Create("UIStroke", { Parent = Items.SVKnob, Color = rgb(0,0,0), Thickness = 1.5 })

    Items.HueBar = Vortex:Create("TextButton", { Parent = Items.DropFrame, Position = dim2(0, 10, 1, -24), Size = dim2(1, -20, 0, 14), AutoButtonColor = false, Text = "", BorderSizePixel = 0, BackgroundColor3 = rgb(255, 255, 255), ZIndex = 201 })
    Vortex:Create("UICorner", { Parent = Items.HueBar, CornerRadius = dim(0, 4) })
    Vortex:Create("UIGradient", { Parent = Items.HueBar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255,0,0)), ColorSequenceKeypoint.new(0.167, rgb(255,0,255)), ColorSequenceKeypoint.new(0.333, rgb(0,0,255)), ColorSequenceKeypoint.new(0.5, rgb(0,255,255)), ColorSequenceKeypoint.new(0.667, rgb(0,255,0)), ColorSequenceKeypoint.new(0.833, rgb(255,255,0)), ColorSequenceKeypoint.new(1, rgb(255,0,0))}) })
    
    Items.HueKnob = Vortex:Create("Frame", { Parent = Items.HueBar, AnchorPoint = vec2(0.5, 0.5), Size = dim2(0, 4, 1, 6), BackgroundColor3 = rgb(255,255,255), ZIndex = 203 })
    Vortex:Create("UICorner", {Parent = Items.HueKnob, CornerRadius = dim(1, 0)})
    Vortex:Create("UIStroke", { Parent = Items.HueKnob, Color = rgb(0,0,0) })

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

function Vortex:Keybind(properties)
    local Cfg = { 
        Name = properties.Name or properties.name or "Keybind", 
        Flag = properties.Flag or properties.flag, 
        Default = properties.Default or properties.default or Enum.KeyCode.Unknown, 
        Callback = properties.Callback or properties.callback or function() end, 
        Items = {} 
    }
    local KeyBtn = Vortex:Create("TextButton", { Parent = self.Items.Title or self.Items.Container, AnchorPoint = vec2(1, 0.5), Position = dim2(1, -6, 0.5, 0), Size = dim2(0, 45, 0, 18), BackgroundColor3 = themes.preset.element, TextColor3 = themes.preset.text, Text = Keys[Cfg.Default] or "None", TextSize = 12, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium), })
    Vortex:Themify(KeyBtn, "element", "BackgroundColor3")
    Vortex:Themify(KeyBtn, "text", "TextColor3")
    Vortex:Create("UICorner", {Parent = KeyBtn, CornerRadius = dim(0, 4)})
    local stroke = Vortex:Create("UIStroke", {Parent = KeyBtn, Color = themes.preset.outline, Thickness = 1})
    Vortex:Themify(stroke, "outline", "Color")

    KeyBtn.MouseEnter:Connect(function() Vortex:Tween(KeyBtn, {BackgroundColor3 = Vortex:Lighten(themes.preset.element, 0.05)}, TweenInfo.new(0.2)) end)
    KeyBtn.MouseLeave:Connect(function() Vortex:Tween(KeyBtn, {BackgroundColor3 = themes.preset.element}, TweenInfo.new(0.2)) end)

    local binding = false
    KeyBtn.MouseButton1Click:Connect(function() binding = true; KeyBtn.Text = "..." ; Vortex:Tween(stroke, {Color = themes.preset.accent}, TweenInfo.new(0.2)) end)
    
    InputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed and not binding then return end
        if binding then
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                binding = false; Cfg.set(input.KeyCode)
                Vortex:Tween(stroke, {Color = themes.preset.outline}, TweenInfo.new(0.2))
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                binding = false; Cfg.set(input.UserInputType)
                Vortex:Tween(stroke, {Color = themes.preset.outline}, TweenInfo.new(0.2))
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

-- notifs
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
    Vortex:Themify(Vortex:Create("UIStroke", {Parent = Items.Outline, Color = themes.preset.outline, Thickness = 1}), "outline", "Color")
   
    Items.Name = Vortex:Create("TextLabel", {
        Parent = Items.Outline; Text = Cfg.Name; TextColor3 = themes.preset.text; FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium);
        BackgroundTransparency = 1; Size = dim2(1, 0, 1, 0); AutomaticSize = Enum.AutomaticSize.None; TextWrapped = true; TextSize = 13; TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 302
    })
    Vortex:Themify(Items.Name, "text", "TextColor3")
   
    Vortex:Create("UIPadding", { Parent = Items.Name; PaddingTop = dim(0, 12); PaddingBottom = dim(0, 12); PaddingRight = dim(0, 14); PaddingLeft = dim(0, 14); })
   
    Items.TimeBar = Vortex:Create("Frame", { Parent = Items.Outline, AnchorPoint = vec2(0, 1), Position = dim2(0, 0, 1, 0), Size = dim2(1, 0, 0, 3), BackgroundColor3 = themes.preset.accent, BorderSizePixel = 0, ZIndex = 303 })
    Vortex:Themify(Items.TimeBar, "accent", "BackgroundColor3")
    Vortex:Create("UIGradient", { Parent = Items.TimeBar, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, rgb(255, 255, 255)), ColorSequenceKeypoint.new(1, rgb(150, 150, 150))}) })
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

-- save and load stuff yes
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

-- configs and server menu 
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

    local Tab = window:Tab({ Name = "", Hidden = true })
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

    SectionRight:Label({Name = "Accent Color"}):Colorpicker({ Callback = function(color3) Vortex:RefreshTheme("accent", color3) end, Color = themes.preset.accent })
    SectionRight:Label({Name = "Glow Color"}):Colorpicker({ Callback = function(color3) Vortex:RefreshTheme("glow", color3) end, Color = themes.preset.glow })
    SectionRight:Label({Name = "Background Color"}):Colorpicker({ Callback = function(color3) Vortex:RefreshTheme("background", color3) end, Color = themes.preset.background })
    SectionRight:Label({Name = "Section Color"}):Colorpicker({ Callback = function(color3) Vortex:RefreshTheme("section", color3) end, Color = themes.preset.section })
    SectionRight:Label({Name = "Element Color"}):Colorpicker({ Callback = function(color3) Vortex:RefreshTheme("element", color3) end, Color = themes.preset.element })
    SectionRight:Label({Name = "Text Color"}):Colorpicker({ Callback = function(color3) Vortex:RefreshTheme("text", color3) end, Color = themes.preset.text })

    window.Tweening = true
    SectionRight:Label({Name = "Menu Bind"}):Keybind({
        Name = "Menu Bind",
        Callback = function(bool) if window.Tweening then return end window.ToggleMenu(bool) end,
        Default = Enum.KeyCode.RightShift
    })

task.delay(1, function() window.Tweening = false end)

    local ServerSection = Tab:Section({Name = "Server", Side = "Right"})

    ServerSection:Button({ Name = "Rejoin Server", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer) end })

    ServerSection:Button({
        Name = "Server Hop",
        Callback = function()
            local servers, cursor = {}, ""
            repeat
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local data = HttpService:JSONDecode(game:HttpGet(url))
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then table.insert(servers, server) end
                end
                cursor = data.nextPageCursor
            until not cursor or #servers > 0
            if #servers > 0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)].id, Players.LocalPlayer) end
        end
    })

    ServerSection:Button({
        Name = "Join Lowest Server",
        Callback = function()
            local lowestServer, cursor = nil, ""
            repeat
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (cursor ~= "" and "&cursor=" .. cursor or "")
                local data = HttpService:JSONDecode(game:HttpGet(url))
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and server.playing > 0 and server.playing < server.maxPlayers then
                        lowestServer = server.id
                        break
                    end
                end
                cursor = data.nextPageCursor
            until lowestServer or not cursor
            if lowestServer then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, lowestServer, Players.LocalPlayer) end
        end
    })
end

return Vortex

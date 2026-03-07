# 🌀 Vortex UI Library

**Vortex** is a Roblox UI library designed to make building clean and responsive interfaces easy. It includes built-in configs, notifications, and theme customization.

# Installation

Load the library at the top of your script.

```lua
local Vortex = loadstring(game:HttpGet("https://raw.githubusercontent.com/SosaX11/Vortex/refs/heads/main/vortex.lua"))()
```

---

# Creating a Window

The window is the main container for the UI.

```lua
local Window = Vortex:Window({
    Title = "Vortex Hub",
    Subtitle = "Premium Script",
    Logo = "rbxassetid://YOUR_IMAGE",
    Size = UDim2.new(0, 720, 0, 500) -- optional
})
```

---

# Tabs

Tabs organize features into categories.

The `Icon` field supports both normal asset IDs and `rbxthumb` thumbnails.

```lua
local MainTab = Window:Tab({
    Name = "Main",
    Icon = "rbxthumb://type=Asset&id=ASSET_ID&w=150&h=150"
})
```

Supported formats:

```
rbxassetid://ASSET_ID
rbxthumb://type=Asset&id=ASSET_ID&w=150&h=150
```

---

# Sections

Sections divide elements into columns inside a tab.

```lua
local PlayerSection = MainTab:Section({
    Name = "Player Features",
    Side = "Left" -- Left or Right
})
```

---

# Elements

All UI elements are created inside sections.

---

## Button

```lua
PlayerSection:Button({
    Name = "Kill Player",
    Callback = function()
        print("Button clicked")
    end
})
```

---

## Toggle

```lua
PlayerSection:Toggle({
    Name = "Auto Farm",
    Flag = "AutoFarmToggle",
    Default = false,
    Callback = function(state)
        print("Auto Farm:", state)
    end
})
```

---

## Slider

```lua
PlayerSection:Slider({
    Name = "WalkSpeed",
    Flag = "WS_Slider",
    Min = 16,
    Max = 100,
    Default = 16,
    Increment = 1,
    Suffix = " WS",
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end
})
```

---

## Textbox

```lua
PlayerSection:Textbox({
    Name = "Target Player",
    Placeholder = "Enter username...",
    Default = "",
    Flag = "TargetBox",
    Numeric = false,
    Callback = function(text)
        print("Target:", text)
    end
})
```

---

## Dropdown

```lua
local WeaponDropdown = PlayerSection:Dropdown({
    Name = "Select Weapon",
    Flag = "WeaponDrop",
    Options = {"Sword", "Gun", "Knife"},
    Default = "Sword",
    Callback = function(option)
        print("Selected:", option)
    end
})
```

Updating dropdown options later:

```lua
WeaponDropdown.RefreshOptions({"Item1","Item2"})
```

---

## Keybind

```lua
PlayerSection:Keybind({
    Name = "Aimbot Key",
    Flag = "AimbotKey",
    Default = Enum.UserInputType.MouseButton2,
    Callback = function()
        print("Key pressed")
    end
})
```

---

## Label & Colorpicker

```lua
PlayerSection:Label({
    Name = "ESP Settings"
}):Colorpicker({
    Color = Color3.fromRGB(255,0,0),
    Flag = "ESPColor",
    Callback = function(color)
        print(color)
    end
})
```

---

# Notifications

Vortex includes a built in notification system.

```lua
Vortex.Notifications:Create({
    Name = "Script injected successfully",
    Lifetime = 3
})
```

---

# Configs & Settings

Vortex automatically generates a **settings/config tab**.

Call this at the end of your script:

```lua
Vortex:Configs(Window)
```

This adds:

* Config saving / loading / deleting
* UI color customization
* Server hop
* Rejoin button

Configs use the **Flag values** assigned to elements.

---

# Full Example

```lua
local Vortex = loadstring(game:HttpGet("https://raw.githubusercontent.com/SosaX11/Vortex/refs/heads/main/vortex.lua"))()

local Window = Vortex:Window({
    Title = "Vortex",
    Subtitle = "Example Script",
    Size = UDim2.new(0, 600, 0, 450)
})

local MainTab = Window:Tab({
    Name = "Combat",
    Icon = "rbxthumb://type=Asset&id=ASSET_ID&w=150&h=150"
})

local MovementTab = Window:Tab({
    Name = "Movement"
})

local AimbotSection = MainTab:Section({
    Name = "Aimbot Settings",
    Side = "Left"
})

local VisualSection = MainTab:Section({
    Name = "Visuals",
    Side = "Right"
})

AimbotSection:Toggle({
    Name = "Enable Aimbot",
    Flag = "AimbotToggle",
    Default = false,
    Callback = function(state)
        print("Aimbot:", state)
    end
})

AimbotSection:Keybind({
    Name = "Target Lock Bind",
    Flag = "LockBind",
    Default = Enum.KeyCode.E,
    Callback = function()
        print("Locked on target")
    end
})

VisualSection:Label({
    Name = "Enemy Chams"
}):Colorpicker({
    Color = Color3.fromRGB(255,0,0),
    Flag = "ChamColor",
    Callback = function(color)
        print("Color changed")
    end
})

Vortex.Notifications:Create({
    Name = "Vortex example loaded",
    Lifetime = 3
})

Vortex:Configs(Window)

## Credits
Created and coded by **Havez**.  
All rights reserved.


```

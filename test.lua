--[[
    CustomUI Library for Roblox
    A feature-complete UI library matching the Leny-UI API.
    
    Usage:
        local Library = loadstring(game:HttpGetAsync("YOUR_RAW_URL"))()
        Library.new({...})
    
    Features:
        - Window with tabs, subtabs, sections (Single/Double layout)
        - Toggle, Keybind, Slider, ColorPicker, Dropdown, Button, TextBox
        - Addon elements on Toggle
        - Notifications
        - Flags system (shared.Flags)
        - Manager tab (theme changer, config save/load)
        - Full theme support
--]]

-- // Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- // Flags
if not shared.Flags then shared.Flags = {} end
local Flags = shared.Flags
Flags.Toggle   = Flags.Toggle   or {}
Flags.Keybind  = Flags.Keybind  or {}
Flags.Slider   = Flags.Slider   or {}
Flags.Picker   = Flags.Picker   or {}
Flags.Dropdown = Flags.Dropdown or {}
Flags.TextBox  = Flags.TextBox  or {}

-- // Library table
local Library = {}
Library.__index = Library

-- // Default Theme
Library.Theme = {
    PrimaryBackgroundColor  = Color3.fromRGB(18, 18, 24),
    SecondaryBackgroundColor = Color3.fromRGB(24, 24, 32),
    TertiaryBackgroundColor  = Color3.fromRGB(30, 30, 40),
    TabBackgroundColor       = Color3.fromRGB(14, 14, 20),
    PrimaryTextColor         = Color3.fromRGB(235, 235, 245),
    SecondaryTextColor       = Color3.fromRGB(140, 140, 165),
    PrimaryColor             = Color3.fromRGB(85, 105, 215),
    ScrollingBarImageColor   = Color3.fromRGB(60, 60, 80),
    Line                     = Color3.fromRGB(40, 40, 55),
}

-- // Utility
local function Tween(obj, props, t, style, dir)
    local info = TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function Create(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function MakeDraggable(topbar, frame)
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function RippleEffect(button, theme)
    local ripple = Create("Frame", {
        Size = UDim2.new(0,0,0,0),
        Position = UDim2.new(0.5,0,0.5,0),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = button.ZIndex + 1,
        ClipsDescendants = false,
        Parent = button,
    })
    Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = ripple})
    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    Tween(ripple, {Size = UDim2.new(0,size,0,size), BackgroundTransparency = 1}, 0.4)
    task.delay(0.4, function() ripple:Destroy() end)
end

-- // ScreenGui Setup
local ScreenGui
pcall(function()
    ScreenGui = CoreGui:FindFirstChild("CustomUILibrary")
    if ScreenGui then ScreenGui:Destroy() end
end)
ScreenGui = Create("ScreenGui", {
    Name            = "CustomUILibrary",
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    DisplayOrder    = 999,
    Parent          = CoreGui,
})

-- // Notification Container
local NotifContainer = Create("Frame", {
    Name            = "NotifContainer",
    Size            = UDim2.new(0,320,1,0),
    Position        = UDim2.new(1,-330,0,0),
    BackgroundTransparency = 1,
    Parent          = ScreenGui,
})
Create("UIListLayout", {
    SortOrder       = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding         = UDim.new(0,8),
    Parent          = NotifContainer,
})
Create("UIPadding", {
    PaddingBottom   = UDim.new(0,12),
    Parent          = NotifContainer,
})

-- // Main Window holder
local WindowFrame  -- set by Library.new
local CurrentTheme = {}

-- ============================================================
-- Library.new
-- ============================================================
function Library.new(config)
    -- Merge theme
    for k, v in pairs(Library.Theme) do
        CurrentTheme[k] = config[k] or v
    end

    local sizeX    = config.sizeX    or 770
    local sizeY    = config.sizeY    or 600
    local title    = config.title    or "UI"
    local tabWidth = config.tabWidth or 200

    -- // Root window
    WindowFrame = Create("Frame", {
        Name            = "Window",
        Size            = UDim2.new(0, sizeX, 0, sizeY),
        Position        = UDim2.new(0.5, -sizeX/2, 0.5, -sizeY/2),
        BackgroundColor3 = CurrentTheme.PrimaryBackgroundColor,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent          = ScreenGui,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = WindowFrame})
    -- Drop shadow
    local shadow = Create("ImageLabel", {
        Name   = "Shadow",
        Size   = UDim2.new(1,30,1,30),
        Position = UDim2.new(0,-15,0,-15),
        BackgroundTransparency = 1,
        Image  = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0,0,0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23,23,277,277),
        ZIndex = WindowFrame.ZIndex - 1,
        Parent = WindowFrame,
    })

    -- // Top bar
    local TopBar = Create("Frame", {
        Name            = "TopBar",
        Size            = UDim2.new(1,0,0,46),
        BackgroundColor3 = CurrentTheme.SecondaryBackgroundColor,
        BorderSizePixel = 0,
        ZIndex          = 2,
        Parent          = WindowFrame,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = TopBar})
    -- Fix bottom corners
    Create("Frame", {
        Size = UDim2.new(1,0,0,8),
        Position = UDim2.new(0,0,1,-8),
        BackgroundColor3 = CurrentTheme.SecondaryBackgroundColor,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = TopBar,
    })

    local TitleLabel = Create("TextLabel", {
        Name            = "Title",
        Size            = UDim2.new(1,-16,1,0),
        Position        = UDim2.new(0,16,0,0),
        BackgroundTransparency = 1,
        Text            = title,
        TextColor3      = CurrentTheme.PrimaryTextColor,
        Font            = Enum.Font.GothamBold,
        TextSize        = 18,
        TextXAlignment  = Enum.TextXAlignment.Left,
        ZIndex          = 3,
        Parent          = TopBar,
    })

    -- Close button
    local CloseBtn = Create("TextButton", {
        Name            = "Close",
        Size            = UDim2.new(0,28,0,28),
        Position        = UDim2.new(1,-38,0.5,-14),
        BackgroundColor3 = Color3.fromRGB(200,60,60),
        BorderSizePixel = 0,
        Text            = "×",
        TextColor3      = Color3.fromRGB(255,255,255),
        Font            = Enum.Font.GothamBold,
        TextSize        = 16,
        ZIndex          = 4,
        Parent          = TopBar,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = CloseBtn})
    CloseBtn.MouseButton1Click:Connect(function()
        WindowFrame.Visible = false
    end)

    -- Minimise button
    local MinBtn = Create("TextButton", {
        Name            = "Minimise",
        Size            = UDim2.new(0,28,0,28),
        Position        = UDim2.new(1,-72,0.5,-14),
        BackgroundColor3 = Color3.fromRGB(200,160,40),
        BorderSizePixel = 0,
        Text            = "–",
        TextColor3      = Color3.fromRGB(255,255,255),
        Font            = Enum.Font.GothamBold,
        TextSize        = 16,
        ZIndex          = 4,
        Parent          = TopBar,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = MinBtn})

    -- // Body (below topbar)
    local Body = Create("Frame", {
        Name            = "Body",
        Size            = UDim2.new(1,0,1,-46),
        Position        = UDim2.new(0,0,0,46),
        BackgroundTransparency = 1,
        Parent          = WindowFrame,
    })

    -- // Left sidebar
    local Sidebar = Create("Frame", {
        Name            = "Sidebar",
        Size            = UDim2.new(0,tabWidth,1,0),
        BackgroundColor3 = CurrentTheme.TabBackgroundColor,
        BorderSizePixel = 0,
        Parent          = Body,
    })

    local SidebarList = Create("ScrollingFrame", {
        Name            = "List",
        Size            = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = CurrentTheme.ScrollingBarImageColor,
        CanvasSize      = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent          = Sidebar,
    })
    local SidebarPad = Create("UIPadding", {
        PaddingTop    = UDim.new(0,8),
        PaddingLeft   = UDim.new(0,6),
        PaddingRight  = UDim.new(0,6),
        Parent        = SidebarList,
    })
    local SidebarLayout = Create("UIListLayout", {
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0,2),
        Parent        = SidebarList,
    })

    -- // Content area
    local ContentArea = Create("Frame", {
        Name            = "ContentArea",
        Size            = UDim2.new(1,-tabWidth,1,0),
        Position        = UDim2.new(0,tabWidth,0,0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent          = Body,
    })

    -- Divider between sidebar and content
    Create("Frame", {
        Size  = UDim2.new(0,1,1,0),
        Position = UDim2.new(0,0,0,0),
        BackgroundColor3 = CurrentTheme.Line,
        BorderSizePixel = 0,
        Parent = ContentArea,
    })

    MakeDraggable(TopBar, WindowFrame)

    -- Minimise logic
    local minimised = false
    MinBtn.MouseButton1Click:Connect(function()
        minimised = not minimised
        Tween(WindowFrame, {Size = minimised
            and UDim2.new(0,sizeX,0,46)
            or  UDim2.new(0,sizeX,0,sizeY)}, 0.25)
    end)

    -- Store on library for createLabel / createTab / createManager
    Library._sidebar      = SidebarList
    Library._sidebarWidth = tabWidth
    Library._contentArea  = ContentArea
    Library._theme        = CurrentTheme
    Library._tabList      = {}
    Library._labelOrder   = 0

    return Library
end

-- ============================================================
-- Notify
-- ============================================================
function Library:notify(config)
    local theme  = CurrentTheme
    local title  = config.title   or "Notification"
    local text   = config.text    or ""
    local sizeY  = config.sizeY   or 80
    local maxX   = config.maxSizeX or 300

    local frame = Create("Frame", {
        Name            = "Notif",
        Size            = UDim2.new(0, maxX, 0, sizeY),
        BackgroundColor3 = theme.SecondaryBackgroundColor,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Parent          = NotifContainer,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = frame})
    -- Accent line
    Create("Frame", {
        Size  = UDim2.new(0,3,1,-16),
        Position = UDim2.new(0,0,0,8),
        BackgroundColor3 = theme.PrimaryColor,
        BorderSizePixel = 0,
        Parent = frame,
    })

    Create("TextLabel", {
        Size  = UDim2.new(1,-20,0,20),
        Position = UDim2.new(0,14,0,10),
        BackgroundTransparency = 1,
        Text  = title,
        TextColor3 = theme.PrimaryTextColor,
        Font  = Enum.Font.GothamBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    Create("TextLabel", {
        Size  = UDim2.new(1,-20,1,-38),
        Position = UDim2.new(0,14,0,30),
        BackgroundTransparency = 1,
        Text  = text,
        TextColor3 = theme.SecondaryTextColor,
        Font  = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = frame,
    })

    Tween(frame, {BackgroundTransparency = 0}, 0.2)
    task.delay(4, function()
        Tween(frame, {BackgroundTransparency = 1}, 0.3)
        task.delay(0.3, function() frame:Destroy() end)
    end)
end

-- ============================================================
-- createLabel  (sidebar section header)
-- ============================================================
function Library:createLabel(config)
    local theme = self._theme
    Library._labelOrder = Library._labelOrder + 1
    local lbl = Create("TextLabel", {
        Name  = "Label_"..config.text,
        Size  = UDim2.new(1,0,0,22),
        BackgroundTransparency = 1,
        Text  = config.text:upper(),
        TextColor3 = theme.SecondaryTextColor,
        Font  = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = Library._labelOrder * 100,
        Parent = self._sidebar,
    })
    Create("UIPadding", {PaddingLeft = UDim.new(0,4), Parent = lbl})
    return lbl
end

-- ============================================================
-- createTab
-- ============================================================
function Library:createTab(config)
    local theme = self._theme
    Library._labelOrder = Library._labelOrder + 1

    -- Tab button in sidebar
    local tabBtn = Create("TextButton", {
        Name  = "Tab_"..config.text,
        Size  = UDim2.new(1,0,0,36),
        BackgroundColor3 = theme.TertiaryBackgroundColor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text  = "",
        AutoButtonColor = false,
        LayoutOrder = Library._labelOrder * 100,
        Parent = self._sidebar,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = tabBtn})

    -- Icon
    if config.icon then
        local icon = Create("ImageLabel", {
            Size  = UDim2.new(0,20,0,20),
            Position = UDim2.new(0,8,0.5,-10),
            BackgroundTransparency = 1,
            Image = "rbxassetid://"..config.icon,
            Parent = tabBtn,
        })
    end

    local textOffsetX = config.icon and 34 or 10
    local tabText = Create("TextLabel", {
        Size  = UDim2.new(1,-textOffsetX-4,1,0),
        Position = UDim2.new(0,textOffsetX,0,0),
        BackgroundTransparency = 1,
        Text  = config.text,
        TextColor3 = theme.SecondaryTextColor,
        Font  = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tabBtn,
    })

    -- Tab content frame inside ContentArea
    local tabFrame = Create("Frame", {
        Name  = "TabFrame_"..config.text,
        Size  = UDim2.new(1,-1,1,0),
        Position = UDim2.new(0,1,0,0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self._contentArea,
    })

    -- Tab header
    local tabHeader = Create("Frame", {
        Name  = "Header",
        Size  = UDim2.new(1,0,0,44),
        BackgroundColor3 = theme.SecondaryBackgroundColor,
        BorderSizePixel = 0,
        Parent = tabFrame,
    })
    Create("TextLabel", {
        Size  = UDim2.new(1,-16,1,0),
        Position = UDim2.new(0,16,0,0),
        BackgroundTransparency = 1,
        Text  = config.text,
        TextColor3 = theme.PrimaryTextColor,
        Font  = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tabHeader,
    })
    Create("Frame", {
        Size  = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = theme.Line,
        BorderSizePixel = 0,
        Parent = tabHeader,
    })

    -- SubTab bar
    local subTabBar = Create("Frame", {
        Name  = "SubTabBar",
        Size  = UDim2.new(1,0,0,36),
        Position = UDim2.new(0,0,0,44),
        BackgroundColor3 = theme.SecondaryBackgroundColor,
        BorderSizePixel = 0,
        Parent = tabFrame,
    })
    local subTabList = Create("ScrollingFrame", {
        Size  = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        Parent = subTabBar,
    })
    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder     = Enum.SortOrder.LayoutOrder,
        Padding       = UDim.new(0,0),
        Parent        = subTabList,
    })
    Create("UIPadding", {PaddingLeft = UDim.new(0,10), Parent = subTabList})
    Create("Frame", {
        Size  = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = theme.Line,
        BorderSizePixel = 0,
        Parent = subTabBar,
    })

    -- SubTab content container
    local subTabContent = Create("Frame", {
        Name  = "SubTabContent",
        Size  = UDim2.new(1,0,1,-80),
        Position = UDim2.new(0,0,0,80),
        BackgroundTransparency = 1,
        Parent = tabFrame,
    })

    -- Tab object
    local Tab = {
        _frame      = tabFrame,
        _subTabBar  = subTabList,
        _subContent = subTabContent,
        _theme      = theme,
        _subTabs    = {},
        _activeSubTab = nil,
    }

    -- Select / deselect helpers
    local function selectTab()
        -- Hide all other tabs
        for _, t in pairs(Library._tabList) do
            t._frame.Visible = false
            t._btnText.TextColor3 = theme.SecondaryTextColor
            Tween(t._btn, {BackgroundTransparency = 1}, 0.12)
        end
        tabFrame.Visible = true
        tabText.TextColor3 = theme.PrimaryTextColor
        Tween(tabBtn, {BackgroundTransparency = 0}, 0.12)
    end

    Tab._btn     = tabBtn
    Tab._btnText = tabText

    tabBtn.MouseButton1Click:Connect(selectTab)

    tabBtn.MouseEnter:Connect(function()
        if tabFrame.Visible then return end
        Tween(tabBtn, {BackgroundTransparency = 0.7}, 0.1)
        tabText.TextColor3 = theme.PrimaryTextColor
    end)
    tabBtn.MouseLeave:Connect(function()
        if tabFrame.Visible then return end
        Tween(tabBtn, {BackgroundTransparency = 1}, 0.1)
        tabText.TextColor3 = theme.SecondaryTextColor
    end)

    table.insert(Library._tabList, Tab)

    -- Select first tab automatically
    if #Library._tabList == 1 then
        tabFrame.Visible = true
        tabText.TextColor3 = theme.PrimaryTextColor
        Tween(tabBtn, {BackgroundTransparency = 0}, 0)
    end

    -- --------------------------------------------------------
    -- createSubTab
    -- --------------------------------------------------------
    function Tab:createSubTab(cfg)
        local stText = cfg.text or "Page"
        local style  = cfg.sectionStyle or "Single"

        local stBtn = Create("TextButton", {
            Name  = "SubTab_"..stText,
            Size  = UDim2.new(0,0,1,0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text  = "",
            AutoButtonColor = false,
            Parent = self._subTabBar,
        })
        Create("UIPadding", {PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),Parent=stBtn})
        local stLabel = Create("TextLabel", {
            Size  = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Text  = stText,
            TextColor3 = theme.SecondaryTextColor,
            Font  = Enum.Font.Gotham,
            TextSize = 13,
            Parent = stBtn,
        })
        -- Active indicator line
        local stIndicator = Create("Frame", {
            Size  = UDim2.new(1,0,0,2),
            Position = UDim2.new(0,0,1,-2),
            BackgroundColor3 = theme.PrimaryColor,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            Parent = stBtn,
        })

        -- Content frame for this subtab
        local stFrame = Create("Frame", {
            Name  = "SubContent_"..stText,
            Size  = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = self._subContent,
        })

        -- Section container (single or double)
        local sectionsScroll = Create("ScrollingFrame", {
            Name  = "Sections",
            Size  = UDim2.new(1,-16,1,-8),
            Position = UDim2.new(0,8,0,8),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.ScrollingBarImageColor,
            CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = stFrame,
        })
        local sectionsLayout
        if style == "Double" then
            sectionsLayout = Create("UIGridLayout", {
                CellSize  = UDim2.new(0.5,-6,0,0),
                CellPaddingX = UDim.new(0,8),
                CellPaddingY = UDim.new(0,8),
                StartCorner = Enum.StartCorner.TopLeft,
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = sectionsScroll,
            })
            -- Auto height for grid
            sectionsScroll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sectionsScroll.CanvasSize = UDim2.new(0,0,0,sectionsScroll.AbsoluteContentSize.Y)
            end)
        else
            sectionsLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0,8),
                Parent    = sectionsScroll,
            })
            sectionsScroll.UIListLayout = sectionsLayout
        end

        local SubTab = {
            _frame    = stFrame,
            _scroll   = sectionsScroll,
            _style    = style,
            _theme    = theme,
            _order    = 0,
        }

        local function selectSubTab()
            for _, st in pairs(Tab._subTabs) do
                st._frame.Visible = false
                st._label.TextColor3 = theme.SecondaryTextColor
                Tween(st._indicator, {BackgroundTransparency = 1}, 0.12)
            end
            stFrame.Visible = true
            stLabel.TextColor3 = theme.PrimaryColor
            Tween(stIndicator, {BackgroundTransparency = 0}, 0.12)
        end

        SubTab._label     = stLabel
        SubTab._indicator = stIndicator

        stBtn.MouseButton1Click:Connect(selectSubTab)

        table.insert(Tab._subTabs, SubTab)
        if #Tab._subTabs == 1 then selectSubTab() end

        -- --------------------------------------------------------
        -- createSection
        -- --------------------------------------------------------
        function SubTab:createSection(scfg)
            self._order = self._order + 1
            local sText = scfg.text or "Section"

            local sFrame = Create("Frame", {
                Name  = "Section_"..sText,
                Size  = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = theme.TertiaryBackgroundColor,
                BorderSizePixel = 0,
                LayoutOrder = self._order,
                Parent = self._scroll,
            })
            Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = sFrame})
            Create("UIPadding", {
                PaddingTop    = UDim.new(0,8),
                PaddingBottom = UDim.new(0,10),
                PaddingLeft   = UDim.new(0,10),
                PaddingRight  = UDim.new(0,10),
                Parent        = sFrame,
            })

            local sHeader = Create("TextLabel", {
                Name  = "SectionHeader",
                Size  = UDim2.new(1,0,0,22),
                BackgroundTransparency = 1,
                Text  = sText,
                TextColor3 = theme.PrimaryTextColor,
                Font  = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 0,
                Parent = sFrame,
            })

            local sContent = Create("Frame", {
                Name  = "Content",
                Size  = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 1,
                Parent = sFrame,
            })
            local sLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0,2),
                Parent    = sContent,
            })

            local mainLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0,0),
                Parent    = sFrame,
            })

            local Section = {
                _frame  = sFrame,
                _content = sContent,
                _theme  = theme,
                _order  = 0,
            }

            -- Helper: row frame
            local function makeRow(parent, ord)
                local row = Create("Frame", {
                    Size  = UDim2.new(1,0,0,34),
                    BackgroundTransparency = 1,
                    LayoutOrder = ord,
                    Parent = parent,
                })
                return row
            end

            -- =====================================================
            -- createToggle
            -- =====================================================
            function Section:createToggle(tcfg)
                self._order = self._order + 1
                local tText  = tcfg.text     or "Toggle"
                local tState = tcfg.state    or false
                local tCb    = tcfg.callback or function() end

                local row = makeRow(self._content, self._order)

                local lbl = Create("TextLabel", {
                    Size  = UDim2.new(1,-50,1,0),
                    BackgroundTransparency = 1,
                    Text  = tText,
                    TextColor3 = theme.PrimaryTextColor,
                    Font  = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })

                -- Track: addon gear icon
                local addonBtn = Create("TextButton", {
                    Size  = UDim2.new(0,20,0,20),
                    Position = UDim2.new(1,-46,0.5,-10),
                    BackgroundTransparency = 1,
                    Text  = "⚙",
                    TextColor3 = theme.SecondaryTextColor,
                    Font  = Enum.Font.Gotham,
                    TextSize = 13,
                    Visible = false,
                    Parent = row,
                })

                -- Toggle pill
                local pill = Create("Frame", {
                    Size  = UDim2.new(0,36,0,20),
                    Position = UDim2.new(1,-36,0.5,-10),
                    BackgroundColor3 = tState and theme.PrimaryColor or theme.SecondaryBackgroundColor,
                    BorderSizePixel = 0,
                    Parent = row,
                })
                Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = pill})
                local circle = Create("Frame", {
                    Size  = UDim2.new(0,14,0,14),
                    Position = tState and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BorderSizePixel = 0,
                    Parent = pill,
                })
                Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = circle})

                local state = tState

                -- Addon container (hidden, expands below)
                local addonContainer = Create("Frame", {
                    Size  = UDim2.new(1,0,0,0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    LayoutOrder = self._order + 0.5,
                    Visible = false,
                    Parent = self._content,
                })
                Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0),Parent=addonContainer})
                Create("UIPadding", {PaddingLeft=UDim.new(0,14),Parent=addonContainer})

                local function toggle()
                    state = not state
                    Tween(pill, {BackgroundColor3 = state and theme.PrimaryColor or theme.SecondaryBackgroundColor}, 0.15)
                    Tween(circle, {Position = state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}, 0.15)
                    tCb(state)
                    if Flags.Toggle[tText] then end
                end

                pill.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
                end)
                row.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
                end)

                -- Addon gear toggle
                addonBtn.MouseButton1Click:Connect(function()
                    addonContainer.Visible = not addonContainer.Visible
                end)

                local ToggleObj = {
                    _row       = row,
                    _addonCont = addonContainer,
                    _theme     = theme,
                    _order     = 0,
                    _section   = self,
                }

                -- Register flag
                Flags.Toggle[tText] = {
                    getState = function() return state end,
                    updateState = function(_, cfg2)
                        if cfg2.state ~= nil then
                            state = cfg2.state
                            Tween(pill, {BackgroundColor3 = state and theme.PrimaryColor or Color3.fromRGB(40,40,60)}, 0.15)
                            Tween(circle, {Position = state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}, 0.15)
                        end
                    end,
                }

                -- Addon helpers (shared with Section)
                local function makeAddonSection()
                    addonBtn.Visible = true
                    local aFrame = Create("Frame", {
                        Size = UDim2.new(1,0,0,0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        LayoutOrder = ToggleObj._order,
                        Parent = addonContainer,
                    })
                    Create("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0),Parent=aFrame})
                    return aFrame
                end

                -- Addon methods mirror Section methods but render in addonContainer
                function ToggleObj:createToggle(cfg2)
                    self._order = self._order + 1
                    local aSection = {_content = makeAddonSection(), _theme = theme, _order = 0}
                    -- re-use Section method by copying and calling
                    local tmp = {
                        _content = addonContainer,
                        _theme   = theme,
                        _order   = self._order * 10,
                    }
                    setmetatable(tmp, {__index = Section})
                    return Section.createToggle(tmp, cfg2 and cfg2 or {text="Toggle",state=false,callback=function()end})
                end
                function ToggleObj:createSlider(cfg2)
                    self._order = self._order + 1
                    local tmp = {_content=addonContainer,_theme=theme,_order=self._order*10}
                    setmetatable(tmp,{__index=Section})
                    return Section.createSlider(tmp, cfg2 and cfg2 or {text="Slider",min=0,max=100,step=1,callback=function()end})
                end
                function ToggleObj:createPicker(cfg2)
                    self._order = self._order + 1
                    local tmp = {_content=addonContainer,_theme=theme,_order=self._order*10}
                    setmetatable(tmp,{__index=Section})
                    return Section.createPicker(tmp, cfg2 and cfg2 or {text="Picker",default=Color3.fromRGB(255,255,255),callback=function()end})
                end
                function ToggleObj:createDropdown(cfg2)
                    self._order = self._order + 1
                    local tmp = {_content=addonContainer,_theme=theme,_order=self._order*10}
                    setmetatable(tmp,{__index=Section})
                    return Section.createDropdown(tmp, cfg2 and cfg2 or {text="Dropdown",list={},default={},multiple=false,callback=function()end})
                end

                return ToggleObj
            end

            -- =====================================================
            -- createKeybind
            -- =====================================================
            function Section:createKeybind(kcfg)
                self._order = self._order + 1
                local kText    = kcfg.text     or "Keybind"
                local kDefault = kcfg.default  or "None"
                local kOnHeld  = kcfg.onHeld   or false
                local kCb      = kcfg.callback or function() end

                local row = makeRow(self._content, self._order)
                Create("TextLabel", {
                    Size  = UDim2.new(0.6,0,1,0),
                    BackgroundTransparency = 1,
                    Text  = kText,
                    TextColor3 = theme.PrimaryTextColor,
                    Font  = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })

                local bindLabel = Create("TextButton", {
                    Size  = UDim2.new(0,0,0,22),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Position = UDim2.new(1,0,0.5,-11),
                    AnchorPoint = Vector2.new(1,0),
                    BackgroundColor3 = theme.SecondaryBackgroundColor,
                    BorderSizePixel = 0,
                    Text  = kDefault,
                    TextColor3 = theme.SecondaryTextColor,
                    Font  = Enum.Font.Gotham,
                    TextSize = 11,
                    AutoButtonColor = false,
                    Parent = row,
                })
                Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=bindLabel})
                Create("UIPadding",{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),Parent=bindLabel})

                local currentKey = kDefault
                local listening  = false

                bindLabel.MouseButton1Click:Connect(function()
                    listening = true
                    bindLabel.Text = "..."
                    bindLabel.TextColor3 = theme.PrimaryColor
                end)

                UserInputService.InputBegan:Connect(function(inp, gp)
                    if not listening then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = inp.KeyCode.Name
                        bindLabel.Text = currentKey
                        bindLabel.TextColor3 = theme.SecondaryTextColor
                        listening = false
                        kCb(currentKey)
                    end
                end)

                if kOnHeld then
                    UserInputService.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            if inp.KeyCode.Name == currentKey then kCb(currentKey) end
                        end
                    end)
                end

                local KeybindObj = {
                    getKeybind = function() return currentKey end,
                    updateKeybind = function(_, cfg2)
                        if cfg2.bind then
                            currentKey = cfg2.bind
                            bindLabel.Text = currentKey
                        end
                    end,
                }
                Flags.Keybind[kText] = KeybindObj
                return KeybindObj
            end

            -- =====================================================
            -- createSlider
            -- =====================================================
            function Section:createSlider(scfg)
                self._order = self._order + 1
                local sText = scfg.text     or "Slider"
                local sMin  = scfg.min      or 0
                local sMax  = scfg.max      or 100
                local sStep = scfg.step     or 1
                local sCb   = scfg.callback or function() end
                local sDef  = scfg.default  or sMin

                -- 2-row height
                local container = Create("Frame", {
                    Size  = UDim2.new(1,0,0,50),
                    BackgroundTransparency = 1,
                    LayoutOrder = self._order,
                    Parent = self._content,
                })

                -- Top row: label + value
                local topRow = Create("Frame", {
                    Size  = UDim2.new(1,0,0,26),
                    BackgroundTransparency = 1,
                    Parent = container,
                })
                Create("TextLabel", {
                    Size  = UDim2.new(1,-30,1,0),
                    BackgroundTransparency = 1,
                    Text  = sText,
                    TextColor3 = theme.PrimaryTextColor,
                    Font  = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = topRow,
                })
                local valLbl = Create("TextLabel", {
                    Size  = UDim2.new(0,30,1,0),
                    Position = UDim2.new(1,-30,0,0),
                    BackgroundTransparency = 1,
                    Text  = tostring(sDef),
                    TextColor3 = theme.SecondaryTextColor,
                    Font  = Enum.Font.Gotham,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = topRow,
                })

                -- Track
                local track = Create("Frame", {
                    Size  = UDim2.new(1,0,0,4),
                    Position = UDim2.new(0,0,0,30),
                    BackgroundColor3 = theme.SecondaryBackgroundColor,
                    BorderSizePixel = 0,
                    Parent = container,
                })
                Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=track})
                local fill = Create("Frame", {
                    Size  = UDim2.new(0,0,1,0),
                    BackgroundColor3 = theme.PrimaryColor,
                    BorderSizePixel = 0,
                    Parent = track,
                })
                Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=fill})
                local knob = Create("Frame", {
                    Size  = UDim2.new(0,14,0,14),
                    Position = UDim2.new(0,-7,0.5,-7),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BorderSizePixel = 0,
                    Parent = track,
                })
                Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=knob})

                local value = sDef
                local dragging = false

                local function setValue(v)
                    v = math.clamp(math.round(v/sStep)*sStep, sMin, sMax)
                    value = v
                    local pct = (v - sMin)/(sMax - sMin)
                    Tween(fill, {Size = UDim2.new(pct,0,1,0)}, 0.05)
                    Tween(knob, {Position = UDim2.new(pct,-7,0.5,-7)}, 0.05)
                    valLbl.Text = tostring(v)
                    sCb(v)
                end
                setValue(sDef)

                track.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                track.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = (inp.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X
                        setValue(sMin + (sMax-sMin)*math.clamp(rel,0,1))
                    end
                end)

                local SliderObj = {
                    getValue = function() return value end,
                    updateValue = function(_, cfg2)
                        if cfg2.value then setValue(cfg2.value) end
                    end,
                }
                Flags.Slider[sText] = SliderObj
                return SliderObj
            end

            -- =====================================================
            -- createPicker (Color Picker)
            -- =====================================================
            function Section:createPicker(pcfg)
                self._order = self._order + 1
                local pText = pcfg.text     or "ColorPicker"
                local pDef  = pcfg.default  or Color3.fromRGB(255,255,255)
                local pCb   = pcfg.callback or function() end

                local row = makeRow(self._content, self._order)
                Create("TextLabel", {
                    Size  = UDim2.new(1,-40,1,0),
                    BackgroundTransparency = 1,
                    Text  = pText,
                    TextColor3 = theme.PrimaryTextColor,
                    Font  = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = row,
                })

                local swatch = Create("TextButton", {
                    Size  = UDim2.new(0,24,0,24),
                    Position = UDim2.new(1,-24,0.5,-12),
                    BackgroundColor3 = pDef,
                    BorderSizePixel = 0,
                    Text  = "",
                    AutoButtonColor = false,
                    Parent = row,
                })
                Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=swatch})
                Create("UIStroke",{Color=theme.Line,Thickness=1,Parent=swatch})

                -- Picker popup
                local popup = Create("Frame", {
                    Name  = "ColorPopup",
                    Size  = UDim2.new(0,200,0,230),
                    Position = UDim2.new(1,-200,1,4),
                    BackgroundColor3 = theme.SecondaryBackgroundColor,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 20,
                    Parent = row,
                })
                Create("UICorner",{CornerRadius=UDim.new(0,8),Parent=popup})
                Create("UIStroke",{Color=theme.Line,Thickness=1,Parent=popup})

                -- H/S/V sliders inside popup
                local function makePickerSlider(parent, label, yPos, color)
                    local lbl = Create("TextLabel", {
                        Size = UDim2.new(1,-10,0,14),
                        Position = UDim2.new(0,8,0,yPos),
                        BackgroundTransparency=1,
                        Text=label, TextColor3=theme.SecondaryTextColor,
                        Font=Enum.Font.Gotham, TextSize=10,
                        TextXAlignment=Enum.TextXAlignment.Left,
                        ZIndex=21, Parent=parent,
                    })
                    local tr = Create("Frame",{
                        Size=UDim2.new(1,-16,0,6),
                        Position=UDim2.new(0,8,0,yPos+16),
                        BackgroundColor3=theme.TertiaryBackgroundColor,
                        BorderSizePixel=0, ZIndex=21, Parent=parent,
                    })
                    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=tr})
                    local fl = Create("Frame",{
                        Size=UDim2.new(0,0,1,0),
                        BackgroundColor3=color or theme.PrimaryColor,
                        BorderSizePixel=0,ZIndex=22,Parent=tr,
                    })
                    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=fl})
                    local kn = Create("Frame",{
                        Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,-6,0.5,-6),
                        BackgroundColor3=Color3.fromRGB(255,255,255),
                        BorderSizePixel=0,ZIndex=23,Parent=tr,
                    })
                    Create("UICorner",{CornerRadius=UDim.new(1,0),Parent=kn})
                    return tr, fl, kn
                end

                local h, s, v = Color3.toHSV(pDef)
                local hTrack,hFill,hKnob = makePickerSlider(popup,"Hue",10,Color3.fromRGB(255,0,0))
                local sTrack,sFill,sKnob = makePickerSlider(popup,"Saturation",46,Color3.fromRGB(200,200,200))
                local vTrack,vFill,vKnob = makePickerSlider(popup,"Value",82,Color3.fromRGB(100,100,100))

                local previewFrame = Create("Frame",{
                    Size=UDim2.new(1,-16,0,40),
                    Position=UDim2.new(0,8,0,126),
                    BackgroundColor3=pDef,
                    BorderSizePixel=0,ZIndex=21,Parent=popup,
                })
                Create("UICorner",{CornerRadius=UDim.new(0,6),Parent=previewFrame})

                local hexBox = Create("TextBox",{
                    Size=UDim2.new(1,-16,0,24),
                    Position=UDim2.new(0,8,0,176),
                    BackgroundColor3=theme.TertiaryBackgroundColor,
                    BorderSizePixel=0,ZIndex=21,
                    Text=string.format("#%02X%02X%02X",math.floor(pDef.R*255),math.floor(pDef.G*255),math.floor(pDef.B*255)),
                    TextColor3=theme.PrimaryTextColor,
                    Font=Enum.Font.Code,TextSize=12,
                    Parent=popup,
                })
                Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=hexBox})

                local currentColor = pDef

                local function updateColor()
                    currentColor = Color3.fromHSV(h,s,v)
                    swatch.BackgroundColor3 = currentColor
                    previewFrame.BackgroundColor3 = currentColor
                    hexBox.Text = string.format("#%02X%02X%02X",
                        math.floor(currentColor.R*255),
                        math.floor(currentColor.G*255),
                        math.floor(currentColor.B*255))
                    hFill.Size = UDim2.new(h,0,1,0)
                    hKnob.Position = UDim2.new(h,-6,0.5,-6)
                    sFill.Size = UDim2.new(s,0,1,0)
                    sKnob.Position = UDim2.new(s,-6,0.5,-6)
                    vFill.Size = UDim2.new(v,0,1,0)
                    vKnob.Position = UDim2.new(v,-6,0.5,-6)
                    pCb(currentColor)
                end
                updateColor()

                local function makeTrackDrag(track, onUpdate)
                    local d = false
                    track.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then d=true end
                    end)
                    track.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then d=false end
                    end)
                    UserInputService.InputChanged:Connect(function(inp)
                        if d and inp.UserInputType == Enum.UserInputType.MouseMovement then
                            local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                            onUpdate(rel)
                            updateColor()
                        end
                    end)
                end
                makeTrackDrag(hTrack, function(val) h=val end)
                makeTrackDrag(sTrack, function(val) s=val end)
                makeTrackDrag(vTrack, function(val) v=val end)

                swatch.MouseButton1Click:Connect(function()
                    popup.Visible = not popup.Visible
                end)

                local PickerObj = {
                    getColor = function() return currentColor end,
                    updateColor = function(_, cfg2)
                        if cfg2.color then
                            h,s,v = Color3.toHSV(cfg2.color)
                            updateColor()
                        end
                    end,
                }
                Flags.Picker[pText] = PickerObj
                return PickerObj
            end

            -- =====================================================
            -- createDropdown
            -- =====================================================
            function Section:createDropdown(dcfg)
                self._order = self._order + 1
                local dText     = dcfg.text     or "Dropdown"
                local dList     = dcfg.list     or {}
                local dDefault  = dcfg.default  or {}
                local dMultiple = dcfg.multiple or false
                local dCb       = dcfg.callback or function() end

                -- header row
                local headerRow = makeRow(self._content, self._order)
                Create("TextLabel",{
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    Text=dText,
                    TextColor3=theme.PrimaryTextColor,
                    Font=Enum.Font.Gotham,
                    TextSize=12,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Parent=headerRow,
                })

                -- dropdown button
                self._order = self._order + 0.5
                local dropBtn = Create("TextButton",{
                    Size=UDim2.new(1,0,0,30),
                    BackgroundColor3=theme.SecondaryBackgroundColor,
                    BorderSizePixel=0,
                    Text="",
                    AutoButtonColor=false,
                    LayoutOrder=self._order,
                    Parent=self._content,
                })
                Create("UICorner",{CornerRadius=UDim.new(0,6),Parent=dropBtn})

                local selectedLabel = Create("TextLabel",{
                    Size=UDim2.new(1,-30,1,0),
                    Position=UDim2.new(0,10,0,0),
                    BackgroundTransparency=1,
                    Text="",
                    TextColor3=theme.SecondaryTextColor,
                    Font=Enum.Font.Gotham,
                    TextSize=12,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Parent=dropBtn,
                })
                local arrow = Create("TextLabel",{
                    Size=UDim2.new(0,20,1,0),
                    Position=UDim2.new(1,-24,0,0),
                    BackgroundTransparency=1,
                    Text="▾",
                    TextColor3=theme.SecondaryTextColor,
                    Font=Enum.Font.Gotham,
                    TextSize=12,
                    Parent=dropBtn,
                })

                -- dropdown list
                local listFrame = Create("Frame",{
                    Size=UDim2.new(1,0,0,0),
                    BackgroundColor3=theme.SecondaryBackgroundColor,
                    BorderSizePixel=0,
                    Visible=false,
                    ZIndex=15,
                    ClipsDescendants=true,
                    LayoutOrder=self._order+0.1,
                    Parent=self._content,
                })
                Create("UICorner",{CornerRadius=UDim.new(0,6),Parent=listFrame})
                local listScroll = Create("ScrollingFrame",{
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    BorderSizePixel=0,
                    ScrollBarThickness=2,
                    ScrollBarImageColor3=theme.ScrollingBarImageColor,
                    CanvasSize=UDim2.new(0,0,0,0),
                    AutomaticCanvasSize=Enum.AutomaticSize.Y,
                    ZIndex=16,
                    Parent=listFrame,
                })
                Create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0),Parent=listScroll})

                local selected = {}
                for _, v in pairs(dDefault) do selected[tostring(v)] = true end

                local function getDisplayText()
                    local t = {}
                    for k, _ in pairs(selected) do table.insert(t, k) end
                    return table.concat(t, ", ")
                end

                local function fireCallback()
                    if dMultiple then
                        local t = {}
                        for k, _ in pairs(selected) do table.insert(t, k) end
                        dCb(t)
                    else
                        local k = next(selected)
                        dCb(k)
                    end
                    selectedLabel.Text = getDisplayText()
                end

                local function rebuildList(list)
                    for _, c in pairs(listScroll:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, item in pairs(list) do
                        local itemStr = tostring(item)
                        local itemBtn = Create("TextButton",{
                            Size=UDim2.new(1,0,0,28),
                            BackgroundColor3=theme.TertiaryBackgroundColor,
                            BackgroundTransparency=selected[itemStr] and 0 or 1,
                            BorderSizePixel=0,
                            Text=itemStr,
                            TextColor3=selected[itemStr] and theme.PrimaryColor or theme.PrimaryTextColor,
                            Font=Enum.Font.Gotham,
                            TextSize=12,
                            AutoButtonColor=false,
                            ZIndex=17,
                            Parent=listScroll,
                        })
                        itemBtn.MouseButton1Click:Connect(function()
                            if dMultiple then
                                selected[itemStr] = not selected[itemStr] or nil
                            else
                                selected = {}
                                selected[itemStr] = true
                                listFrame.Visible = false
                            end
                            -- refresh colors
                            for _, c2 in pairs(listScroll:GetChildren()) do
                                if c2:IsA("TextButton") then
                                    local isSel = selected[c2.Text]
                                    c2.BackgroundTransparency = isSel and 0 or 1
                                    c2.TextColor3 = isSel and theme.PrimaryColor or theme.PrimaryTextColor
                                end
                            end
                            fireCallback()
                        end)
                    end
                    -- size list
                    local h2 = math.min(#list * 28, 140)
                    listFrame.Size = UDim2.new(1,0,0,h2)
                end

                local currentList = dList
                rebuildList(currentList)
                selectedLabel.Text = getDisplayText()

                local open = false
                dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    listFrame.Visible = open
                    arrow.Text = open and "▴" or "▾"
                end)

                local DropObj = {
                    getList  = function() return currentList end,
                    getValue = function()
                        if dMultiple then
                            local t={}
                            for k,_ in pairs(selected) do table.insert(t,k) end
                            return t
                        else
                            return next(selected)
                        end
                    end,
                    updateList = function(_, cfg2)
                        if cfg2.list then
                            currentList = cfg2.list
                            selected = {}
                            for _, v in pairs(cfg2.default or {}) do selected[tostring(v)]=true end
                            rebuildList(currentList)
                            selectedLabel.Text = getDisplayText()
                        end
                    end,
                }
                Flags.Dropdown[dText] = DropObj
                return DropObj
            end

            -- =====================================================
            -- createButton
            -- =====================================================
            function Section:createButton(bcfg)
                self._order = self._order + 1
                local bText = bcfg.text     or "Button"
                local bCb   = bcfg.callback or function() end

                local btn = Create("TextButton",{
                    Size=UDim2.new(1,0,0,32),
                    BackgroundColor3=theme.SecondaryBackgroundColor,
                    BorderSizePixel=0,
                    Text=bText,
                    TextColor3=theme.PrimaryTextColor,
                    Font=Enum.Font.GothamBold,
                    TextSize=12,
                    AutoButtonColor=false,
                    ClipsDescendants=true,
                    LayoutOrder=self._order,
                    Parent=self._content,
                })
                Create("UICorner",{CornerRadius=UDim.new(0,6),Parent=btn})
                Create("UIStroke",{Color=theme.Line,Thickness=1,Parent=btn})

                btn.MouseEnter:Connect(function()
                    Tween(btn,{BackgroundColor3=theme.TertiaryBackgroundColor},0.1)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn,{BackgroundColor3=theme.SecondaryBackgroundColor},0.1)
                end)
                btn.MouseButton1Click:Connect(function()
                    RippleEffect(btn)
                    bCb()
                end)

                return btn
            end

            -- =====================================================
            -- createTextBox
            -- =====================================================
            function Section:createTextBox(tbcfg)
                self._order = self._order + 1
                local tbText = tbcfg.text     or "TextBox"
                local tbDef  = tbcfg.default  or ""
                local tbCb   = tbcfg.callback or function() end

                local row = makeRow(self._content, self._order)
                Create("TextLabel",{
                    Size=UDim2.new(1,-80,1,0),
                    BackgroundTransparency=1,
                    Text=tbText,
                    TextColor3=theme.PrimaryTextColor,
                    Font=Enum.Font.Gotham,
                    TextSize=12,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Parent=row,
                })

                local box = Create("TextBox",{
                    Size=UDim2.new(0,60,0,24),
                    Position=UDim2.new(1,-60,0.5,-12),
                    BackgroundColor3=theme.SecondaryBackgroundColor,
                    BorderSizePixel=0,
                    Text=tbDef,
                    TextColor3=theme.SecondaryTextColor,
                    Font=Enum.Font.Gotham,
                    TextSize=11,
                    ClearTextOnFocus=false,
                    Parent=row,
                })
                Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=box})

                box.FocusLost:Connect(function(enter)
                    tbCb(box.Text)
                end)

                local TBObj = {
                    getText = function() return box.Text end,
                    updateText = function(_, cfg2)
                        if cfg2.text then box.Text = cfg2.text end
                    end,
                }
                Flags.TextBox[tbText] = TBObj
                return TBObj
            end

            return Section
        end -- createSection

        return SubTab
    end -- createSubTab

    return Tab
end -- createTab

-- ============================================================
-- createManager
-- ============================================================
function Library:createManager(cfg)
    local theme = self._theme
    local icon  = cfg.icon      or nil
    local folder = cfg.folderName or "UIConfig"

    -- Create folder
    local ok = pcall(function()
        if not isfolder(folder) then makefolder(folder) end
    end)

    -- Manager tab
    local manTab = self:createTab({text="Manager", icon=icon})
    local manPage = manTab:createSubTab({text="Config",sectionStyle="Single"})
    local cfgSection = manPage:createSection({text="Config Manager",position="Left"})

    -- Config name input
    local configName = "default"
    local nameBox = cfgSection:createTextBox({
        text = "Config Name",
        default = "default",
        callback = function(t) configName = t end,
    })

    cfgSection:createButton({
        text = "Save Config",
        callback = function()
            local data = {}
            -- Save toggles
            for k, v in pairs(Flags.Toggle) do
                data["Toggle_"..k] = v:getState()
            end
            for k, v in pairs(Flags.Slider) do
                data["Slider_"..k] = v:getValue()
            end
            for k, v in pairs(Flags.Keybind) do
                data["Keybind_"..k] = v:getKeybind()
            end
            for k, v in pairs(Flags.Dropdown) do
                local val = v:getValue()
                data["Dropdown_"..k] = type(val)=="table" and table.concat(val,",") or tostring(val or "")
            end
            local serialized = game:GetService("HttpService"):JSONEncode(data)
            pcall(function()
                writefile(folder.."/"..configName..".json", serialized)
            end)
            self:notify({title="Config Saved", text="Saved: "..configName, sizeY=70})
        end,
    })

    cfgSection:createButton({
        text = "Load Config",
        callback = function()
            pcall(function()
                local raw = readfile(folder.."/"..configName..".json")
                local data = game:GetService("HttpService"):JSONDecode(raw)
                for k, v in pairs(data) do
                    if k:sub(1,7)=="Toggle_" then
                        local name = k:sub(8)
                        if Flags.Toggle[name] then Flags.Toggle[name]:updateState({state=v}) end
                    elseif k:sub(1,7)=="Slider_" then
                        local name = k:sub(8)
                        if Flags.Slider[name] then Flags.Slider[name]:updateValue({value=v}) end
                    elseif k:sub(1,8)=="Keybind_" then
                        local name = k:sub(9)
                        if Flags.Keybind[name] then Flags.Keybind[name]:updateKeybind({bind=v}) end
                    end
                end
                self:notify({title="Config Loaded", text="Loaded: "..configName, sizeY=70})
            end)
        end,
    })

    -- Theme section
    local themeManPage = manTab:createSubTab({text="Theme",sectionStyle="Single"})
    local themeSection = themeManPage:createSection({text="Theme Editor",position="Left"})

    themeSection:createPicker({
        text="Primary Color",
        default=theme.PrimaryColor,
        callback=function(c)
            theme.PrimaryColor = c
        end,
    })
    themeSection:createPicker({
        text="Background",
        default=theme.PrimaryBackgroundColor,
        callback=function(c)
            theme.PrimaryBackgroundColor = c
            if WindowFrame then WindowFrame.BackgroundColor3 = c end
        end,
    })
end

return Library

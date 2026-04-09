--[[
    CustomUI Library — Roblox LUAU
    Styled to match screenshot exactly:
      - Very dark window (#12121a)
      - Darker sidebar (#0e0e14)
      - Section label above tabs ("MAIN")
      - Tab rows with 20x20 icon + text, blue highlight when active
      - Content area: tab title header bar, subtab bar with blue underline indicator
      - Section cards with rounded corners
      - All element styles matched pixel-for-pixel
    
    API identical to Leny-UI:
        Library.new({...})
        Library:notify({...})
        Library:createLabel({text})
        Library:createTab({text, icon})
        Tab:createSubTab({text, sectionStyle})
        SubTab:createSection({text, position})
        Section:createToggle / createKeybind / createSlider / createPicker
                createDropdown / createButton / createTextBox
        Toggle:createToggle / createSlider / createPicker / createDropdown
        shared.Flags.*
        Library:createManager({folderName, icon})
--]]

-- // Services
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- // Flags
if not shared.Flags then shared.Flags = {} end
local Flags = shared.Flags
Flags.Toggle   = Flags.Toggle   or {}
Flags.Keybind  = Flags.Keybind  or {}
Flags.Slider   = Flags.Slider   or {}
Flags.Picker   = Flags.Picker   or {}
Flags.Dropdown = Flags.Dropdown or {}
Flags.TextBox  = Flags.TextBox  or {}

-- // Library
local Library = {}
Library.__index = Library

-- // Theme — colors pulled from screenshot
Library.Theme = {
    PrimaryBackgroundColor   = Color3.fromRGB(13, 13, 18),
    SecondaryBackgroundColor = Color3.fromRGB(18, 18, 26),
    TertiaryBackgroundColor  = Color3.fromRGB(24, 24, 34),
    TabBackgroundColor       = Color3.fromRGB(11, 11, 16),
    ElementBackgroundColor   = Color3.fromRGB(20, 20, 30),
    HeaderBackgroundColor    = Color3.fromRGB(18, 18, 26),
    PrimaryTextColor         = Color3.fromRGB(235, 235, 245),
    SecondaryTextColor       = Color3.fromRGB(110, 110, 140),
    PrimaryColor             = Color3.fromRGB(80, 100, 210),
    ScrollingBarImageColor   = Color3.fromRGB(50, 50, 70),
    Line                     = Color3.fromRGB(30, 30, 44),
    ToggleOff                = Color3.fromRGB(38, 38, 54),
    KeybindBg                = Color3.fromRGB(24, 24, 36),
}

-- // Util
local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.14, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props):Play()
end

local function New(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    for _, c in pairs(children or {}) do c.Parent = o end
    return o
end

local function Corner(r, parent)
    return New("UICorner", {CornerRadius = UDim.new(0, r), Parent = parent})
end

local function Stroke(color, thickness, parent)
    return New("UIStroke", {Color = color, Thickness = thickness, Parent = parent})
end

local function Pad(t, b, l, r, parent)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, t),
        PaddingBottom = UDim.new(0, b),
        PaddingLeft   = UDim.new(0, l),
        PaddingRight  = UDim.new(0, r),
        Parent        = parent,
    })
end

local function ListLayout(parent, padding, dir, halign, valign)
    return New("UIListLayout", {
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, padding or 0),
        FillDirection       = dir    or Enum.FillDirection.Vertical,
        HorizontalAlignment = halign or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = valign or Enum.VerticalAlignment.Top,
        Parent              = parent,
    })
end

local function MakeDraggable(handle, frame)
    local drag, start, origin
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true; start = i.Position; origin = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - start
            frame.Position = UDim2.new(
                origin.X.Scale, origin.X.Offset + d.X,
                origin.Y.Scale, origin.Y.Offset + d.Y)
        end
    end)
end

local function Ripple(btn)
    local r = New("Frame", {
        Size = UDim2.new(0,0,0,0), AnchorPoint = Vector2.new(.5,.5),
        Position = UDim2.new(.5,0,.5,0),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0.75, BorderSizePixel = 0,
        ZIndex = btn.ZIndex + 2, ClipsDescendants = false, Parent = btn,
    })
    Corner(999, r)
    local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.2
    Tween(r, {Size = UDim2.new(0,sz,0,sz), BackgroundTransparency = 1}, 0.4)
    task.delay(0.4, function() r:Destroy() end)
end

-- // ScreenGui
local ScreenGui
pcall(function()
    local old = CoreGui:FindFirstChild("CustomUILib")
    if old then old:Destroy() end
end)
ScreenGui = New("ScreenGui", {
    Name = "CustomUILib", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999, Parent = CoreGui,
})

-- // Notification container (bottom-right)
local NotifHolder = New("Frame", {
    Name = "NotifHolder", Size = UDim2.new(0,310,1,0),
    Position = UDim2.new(1,-320,0,0),
    BackgroundTransparency = 1, Parent = ScreenGui,
})
New("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0,6), Parent = NotifHolder,
})
Pad(0, 14, 0, 0, NotifHolder)

-- Window state
local WinFrame
local Theme = Library.Theme

-- ============================================================
-- Library.new
-- ============================================================
function Library.new(cfg)
    local T = Library.Theme
    for k, v in pairs(T) do
        if cfg[k] then T[k] = cfg[k] end
    end
    Theme = T

    local W      = cfg.sizeX    or 770
    local H      = cfg.sizeY    or 600
    local title  = cfg.title    or "UI"
    local tabW   = cfg.tabWidth or 200

    -- Root window
    WinFrame = New("Frame", {
        Name = "Window", Size = UDim2.new(0,W,0,H),
        Position = UDim2.new(0.5,-W/2, 0.5,-H/2),
        BackgroundColor3 = T.PrimaryBackgroundColor,
        BorderSizePixel = 0, ClipsDescendants = false, Parent = ScreenGui,
    })
    Corner(8, WinFrame)
    Stroke(T.Line, 1, WinFrame)

    -- Top bar
    local TopBar = New("Frame", {
        Name = "TopBar", Size = UDim2.new(1,0,0,44),
        BackgroundColor3 = T.SecondaryBackgroundColor,
        BorderSizePixel = 0, ZIndex = 3, Parent = WinFrame,
    })
    Corner(8, TopBar)
    New("Frame", {
        Size = UDim2.new(1,0,0,10), Position = UDim2.new(0,0,1,-10),
        BackgroundColor3 = T.SecondaryBackgroundColor,
        BorderSizePixel = 0, ZIndex = 3, Parent = TopBar,
    })
    New("Frame", {
        Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = T.Line, BorderSizePixel = 0, ZIndex = 4, Parent = TopBar,
    })
    New("TextLabel", {
        Size = UDim2.new(1,-100,1,0), Position = UDim2.new(0,14,0,0),
        BackgroundTransparency = 1, Text = title,
        TextColor3 = T.PrimaryTextColor, Font = Enum.Font.GothamBold,
        TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = TopBar,
    })

    local CloseBtn = New("TextButton", {
        Size = UDim2.new(0,26,0,26), Position = UDim2.new(1,-36,0.5,-13),
        BackgroundColor3 = Color3.fromRGB(185,55,55), BorderSizePixel = 0,
        Text = "x", TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold, TextSize = 12,
        AutoButtonColor = false, ZIndex = 5, Parent = TopBar,
    })
    Corner(5, CloseBtn)
    CloseBtn.MouseButton1Click:Connect(function() WinFrame.Visible = false end)

    local MinBtn = New("TextButton", {
        Size = UDim2.new(0,26,0,26), Position = UDim2.new(1,-68,0.5,-13),
        BackgroundColor3 = Color3.fromRGB(185,145,35), BorderSizePixel = 0,
        Text = "-", TextColor3 = Color3.fromRGB(255,255,255),
        Font = Enum.Font.GothamBold, TextSize = 14,
        AutoButtonColor = false, ZIndex = 5, Parent = TopBar,
    })
    Corner(5, MinBtn)
    local minimised = false
    MinBtn.MouseButton1Click:Connect(function()
        minimised = not minimised
        Tween(WinFrame, {
            Size = minimised and UDim2.new(0,W,0,44) or UDim2.new(0,W,0,H)
        }, 0.22)
    end)

    MakeDraggable(TopBar, WinFrame)

    -- Body
    local Body = New("Frame", {
        Name = "Body", Size = UDim2.new(1,0,1,-44), Position = UDim2.new(0,0,0,44),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = WinFrame,
    })

    -- Sidebar
    local Sidebar = New("Frame", {
        Name = "Sidebar", Size = UDim2.new(0,tabW,1,0),
        BackgroundColor3 = T.TabBackgroundColor, BorderSizePixel = 0, Parent = Body,
    })
    New("Frame", {
        Size = UDim2.new(0,1,1,0), Position = UDim2.new(1,-1,0,0),
        BackgroundColor3 = T.Line, BorderSizePixel = 0, Parent = Sidebar,
    })

    local SideScroll = New("ScrollingFrame", {
        Name = "SideScroll", Size = UDim2.new(1,-1,1,0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 2, ScrollBarImageColor3 = T.ScrollingBarImageColor,
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = Sidebar,
    })
    ListLayout(SideScroll, 1)
    Pad(10, 8, 0, 0, SideScroll)

    -- Content area
    local ContentArea = New("Frame", {
        Name = "ContentArea", Size = UDim2.new(1,-tabW,1,0),
        Position = UDim2.new(0,tabW,0,0),
        BackgroundColor3 = T.PrimaryBackgroundColor,
        BorderSizePixel = 0, ClipsDescendants = true, Parent = Body,
    })

    Library._sidebar    = SideScroll
    Library._content    = ContentArea
    Library._theme      = T
    Library._tabList    = {}
    Library._labelOrder = 0

    return Library
end

-- ============================================================
-- notify
-- ============================================================
function Library:notify(cfg)
    local T    = self._theme or Theme
    local maxX = cfg.maxSizeX or 300
    local sY   = cfg.sizeY   or 76

    local f = New("Frame", {
        Name = "Notif", Size = UDim2.new(0,maxX,0,sY),
        BackgroundColor3 = T.SecondaryBackgroundColor,
        BackgroundTransparency = 1, BorderSizePixel = 0, Parent = NotifHolder,
    })
    Corner(7, f)
    Stroke(T.Line, 1, f)

    New("Frame", {
        Size = UDim2.new(0,3,1,-14), Position = UDim2.new(0,0,0,7),
        BackgroundColor3 = T.PrimaryColor, BorderSizePixel = 0, Parent = f,
    })
    New("TextLabel", {
        Size = UDim2.new(1,-16,0,18), Position = UDim2.new(0,12,0,10),
        BackgroundTransparency = 1, Text = cfg.title or "Notification",
        TextColor3 = T.PrimaryTextColor, Font = Enum.Font.GothamBold,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
    })
    New("TextLabel", {
        Size = UDim2.new(1,-16,1,-34), Position = UDim2.new(0,12,0,28),
        BackgroundTransparency = 1, Text = cfg.text or "",
        TextColor3 = T.SecondaryTextColor, Font = Enum.Font.Gotham,
        TextSize = 11, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Parent = f,
    })

    Tween(f, {BackgroundTransparency = 0}, 0.18)
    task.delay(3.6, function()
        Tween(f, {BackgroundTransparency = 1}, 0.25)
        task.delay(0.25, function() f:Destroy() end)
    end)
end

-- ============================================================
-- createLabel  (sidebar section header like "MAIN")
-- ============================================================
function Library:createLabel(cfg)
    local T = self._theme or Theme
    Library._labelOrder = Library._labelOrder + 1

    local lbl = New("TextLabel", {
        Name = "SideLabel", Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1,
        Text = (cfg.text or ""):upper(),
        TextColor3 = T.SecondaryTextColor, Font = Enum.Font.GothamBold,
        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = Library._labelOrder * 100, Parent = self._sidebar,
    })
    Pad(0, 0, 10, 0, lbl)
    return lbl
end

-- ============================================================
-- createTab
-- ============================================================
function Library:createTab(cfg)
    local T = self._theme or Theme
    Library._labelOrder = Library._labelOrder + 1

    -- Sidebar button
    local tabBtn = New("TextButton", {
        Name = "TabBtn_" .. cfg.text,
        Size = UDim2.new(1,-12,0,34),
        BackgroundColor3 = T.PrimaryColor,
        BackgroundTransparency = 1,
        BorderSizePixel = 0, Text = "",
        AutoButtonColor = false,
        LayoutOrder = Library._labelOrder * 100,
        Parent = self._sidebar,
    })
    Corner(6, tabBtn)
    Pad(0, 0, 6, 6, tabBtn)

    local iconImg = New("ImageLabel", {
        Size = UDim2.new(0,18,0,18), Position = UDim2.new(0,0,0.5,-9),
        BackgroundTransparency = 1,
        Image = cfg.icon and ("rbxassetid://" .. cfg.icon) or "",
        ImageColor3 = T.SecondaryTextColor,
        Parent = tabBtn,
    })

    local txtOff = cfg.icon and 26 or 2
    local tabTxt = New("TextLabel", {
        Size = UDim2.new(1,-txtOff,1,0), Position = UDim2.new(0,txtOff,0,0),
        BackgroundTransparency = 1, Text = cfg.text,
        TextColor3 = T.SecondaryTextColor, Font = Enum.Font.Gotham,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = tabBtn,
    })

    -- Tab content frame
    local tabFrame = New("Frame", {
        Name = "TabFrame_" .. cfg.text,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1, Visible = false, Parent = self._content,
    })

    -- Header
    local header = New("Frame", {
        Size = UDim2.new(1,0,0,44),
        BackgroundColor3 = T.SecondaryBackgroundColor,
        BorderSizePixel = 0, Parent = tabFrame,
    })
    New("Frame", {
        Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = T.Line, BorderSizePixel = 0, Parent = header,
    })
    New("TextLabel", {
        Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,16,0,0),
        BackgroundTransparency = 1, Text = cfg.text,
        TextColor3 = T.PrimaryTextColor, Font = Enum.Font.GothamBold,
        TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })

    -- SubTab bar
    local subBarBg = New("Frame", {
        Size = UDim2.new(1,0,0,34), Position = UDim2.new(0,0,0,44),
        BackgroundColor3 = T.SecondaryBackgroundColor,
        BorderSizePixel = 0, Parent = tabFrame,
    })
    New("Frame", {
        Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,-1),
        BackgroundColor3 = T.Line, BorderSizePixel = 0, Parent = subBarBg,
    })
    local subBarScroll = New("ScrollingFrame", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.X,
        Parent = subBarBg,
    })
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,0), Parent = subBarScroll,
    })
    Pad(0, 0, 12, 0, subBarScroll)

    -- SubTab content host
    local subHost = New("Frame", {
        Size = UDim2.new(1,0,1,-78), Position = UDim2.new(0,0,0,78),
        BackgroundTransparency = 1, Parent = tabFrame,
    })

    local Tab = {
        _frame   = tabFrame,
        _subBar  = subBarScroll,
        _subHost = subHost,
        _theme   = T,
        _subTabs = {},
        _btn     = tabBtn,
        _btnTxt  = tabTxt,
        _btnIcon = iconImg,
    }

    local function selectTab()
        for _, ot in pairs(Library._tabList) do
            ot._frame.Visible = false
            ot._btnTxt.TextColor3  = T.SecondaryTextColor
            ot._btnIcon.ImageColor3 = T.SecondaryTextColor
            Tween(ot._btn, {BackgroundTransparency = 1}, 0.12)
        end
        tabFrame.Visible = true
        tabTxt.TextColor3  = T.PrimaryTextColor
        iconImg.ImageColor3 = T.PrimaryColor
        Tween(tabBtn, {BackgroundTransparency = 0.88}, 0.12)
    end

    tabBtn.MouseButton1Click:Connect(selectTab)
    tabBtn.MouseEnter:Connect(function()
        if tabFrame.Visible then return end
        Tween(tabBtn, {BackgroundTransparency = 0.94}, 0.1)
        tabTxt.TextColor3 = T.PrimaryTextColor
    end)
    tabBtn.MouseLeave:Connect(function()
        if tabFrame.Visible then return end
        Tween(tabBtn, {BackgroundTransparency = 1}, 0.1)
        tabTxt.TextColor3 = T.SecondaryTextColor
    end)

    table.insert(Library._tabList, Tab)
    if #Library._tabList == 1 then selectTab() end

    -- ============================================================
    -- createSubTab
    -- ============================================================
    function Tab:createSubTab(cfg2)
        local stText = cfg2.text          or "Page"
        local style  = cfg2.sectionStyle  or "Single"

        local stBtn = New("TextButton", {
            Size = UDim2.new(0,0,1,0), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Text = "", AutoButtonColor = false, Parent = self._subBar,
        })
        Pad(0, 0, 14, 14, stBtn)

        local stLbl = New("TextLabel", {
            Size = UDim2.new(1,0,1,-2), BackgroundTransparency = 1,
            Text = stText, TextColor3 = T.SecondaryTextColor,
            Font = Enum.Font.Gotham, TextSize = 13, Parent = stBtn,
        })

        local stLine = New("Frame", {
            Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,1,-2),
            BackgroundColor3 = T.PrimaryColor, BackgroundTransparency = 1,
            BorderSizePixel = 0, Parent = stBtn,
        })

        local stFrame = New("Frame", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
            Visible = false, Parent = self._subHost,
        })

        local sectScroll = New("ScrollingFrame", {
            Size = UDim2.new(1,-14,1,-10), Position = UDim2.new(0,7,0,7),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.ScrollingBarImageColor,
            CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = stFrame,
        })

        if style == "Double" then
            New("UIGridLayout", {
                CellSize = UDim2.new(0.5,-5,0,0),
                AutomaticCellSize = Enum.AutomaticSize.Y,
                CellPaddingX = UDim.new(0,6), CellPaddingY = UDim.new(0,6),
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder, Parent = sectScroll,
            })
            sectScroll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                sectScroll.CanvasSize = UDim2.new(0,0,0,sectScroll.AbsoluteContentSize.Y+6)
            end)
        else
            ListLayout(sectScroll, 6)
        end

        local SubTab = {
            _frame  = stFrame,
            _scroll = sectScroll,
            _style  = style,
            _theme  = T,
            _order  = 0,
            _lbl    = stLbl,
            _line   = stLine,
        }

        local function selectSubTab()
            for _, st in pairs(Tab._subTabs) do
                st._frame.Visible  = false
                st._lbl.TextColor3 = T.SecondaryTextColor
                Tween(st._line, {BackgroundTransparency = 1}, 0.12)
            end
            stFrame.Visible    = true
            stLbl.TextColor3   = T.PrimaryColor
            Tween(stLine, {BackgroundTransparency = 0}, 0.12)
        end

        stBtn.MouseButton1Click:Connect(selectSubTab)
        table.insert(Tab._subTabs, SubTab)
        if #Tab._subTabs == 1 then selectSubTab() end

        -- ============================================================
        -- createSection
        -- ============================================================
        function SubTab:createSection(scfg)
            self._order = self._order + 1
            local sText = scfg.text or "Section"

            local card = New("Frame", {
                Name = "Sect_" .. sText,
                Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = T.TertiaryBackgroundColor,
                BorderSizePixel = 0, LayoutOrder = self._order, Parent = self._scroll,
            })
            Corner(8, card)
            Stroke(T.Line, 1, card)
            Pad(8, 10, 10, 10, card)
            ListLayout(card, 0)

            New("TextLabel", {
                Name = "SectTitle", Size = UDim2.new(1,0,0,24),
                BackgroundTransparency = 1, Text = sText,
                TextColor3 = T.PrimaryTextColor, Font = Enum.Font.GothamBold,
                TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 0, Parent = card,
            })

            local content = New("Frame", {
                Name = "Content", Size = UDim2.new(1,0,0,0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, LayoutOrder = 1, Parent = card,
            })
            ListLayout(content, 0)

            local Section = {_content = content, _theme = T, _order = 0}

            local function Row(parent, ord, h)
                return New("Frame", {
                    Size = UDim2.new(1,0,0,h or 32),
                    BackgroundTransparency = 1, LayoutOrder = ord, Parent = parent,
                })
            end

            -- =====================================================
            -- createToggle
            -- =====================================================
            function Section:createToggle(tcfg)
                self._order = self._order + 1
                local tText  = tcfg.text     or "Toggle"
                local tState = tcfg.state    or false
                local tCb    = tcfg.callback or function() end

                local row = Row(self._content, self._order, 32)

                local gearBtn = New("TextButton", {
                    Size = UDim2.new(0,18,0,18), Position = UDim2.new(1,-46,0.5,-9),
                    BackgroundTransparency = 1, Text = "o",
                    TextColor3 = T.SecondaryTextColor, Font = Enum.Font.Gotham,
                    TextSize = 14, Visible = false, Parent = row,
                })

                New("TextLabel", {
                    Size = UDim2.new(1,-52,1,0), BackgroundTransparency = 1,
                    Text = tText, TextColor3 = T.PrimaryTextColor,
                    Font = Enum.Font.Gotham, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })

                local pill = New("Frame", {
                    Size = UDim2.new(0,34,0,18), Position = UDim2.new(1,-34,0.5,-9),
                    BackgroundColor3 = tState and T.PrimaryColor or T.ToggleOff,
                    BorderSizePixel = 0, Parent = row,
                })
                Corner(999, pill)

                local nub = New("Frame", {
                    Size = UDim2.new(0,12,0,12),
                    Position = tState and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6),
                    BackgroundColor3 = Color3.fromRGB(255,255,255),
                    BorderSizePixel = 0, Parent = pill,
                })
                Corner(999, nub)

                local state = tState

                local addonCont = New("Frame", {
                    Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1, Visible = false,
                    LayoutOrder = self._order + 0.5, Parent = self._content,
                })
                ListLayout(addonCont, 0)
                Pad(0, 0, 12, 0, addonCont)

                local function doToggle()
                    state = not state
                    Tween(pill, {BackgroundColor3 = state and T.PrimaryColor or T.ToggleOff}, 0.14)
                    Tween(nub,  {Position = state and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)}, 0.14)
                    tCb(state)
                end

                pill.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then doToggle() end
                end)
                row.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then doToggle() end
                end)

                gearBtn.MouseButton1Click:Connect(function()
                    addonCont.Visible = not addonCont.Visible
                end)

                local TogObj = {
                    _addonCont  = addonCont,
                    _theme      = T,
                    _order      = 0,
                    getState    = function() return state end,
                    updateState = function(_, c2)
                        if c2.state ~= nil then
                            state = c2.state
                            Tween(pill, {BackgroundColor3 = state and T.PrimaryColor or T.ToggleOff}, 0.14)
                            Tween(nub,  {Position = state and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)}, 0.14)
                        end
                    end,
                }

                Flags.Toggle[tText] = TogObj

                local function addonSect()
                    gearBtn.Visible = true
                    local tmp = {_content = addonCont, _theme = T, _order = TogObj._order}
                    setmetatable(tmp, {__index = Section})
                    TogObj._order = TogObj._order + 1
                    return tmp
                end

                function TogObj:createToggle(c2)
                    return Section.createToggle(addonSect(), c2 or {})
                end
                function TogObj:createSlider(c2)
                    return Section.createSlider(addonSect(), c2 or {})
                end
                function TogObj:createPicker(c2)
                    return Section.createPicker(addonSect(), c2 or {})
                end
                function TogObj:createDropdown(c2)
                    return Section.createDropdown(addonSect(), c2 or {})
                end

                return TogObj
            end

            -- =====================================================
            -- createKeybind
            -- =====================================================
            function Section:createKeybind(kcfg)
                self._order = self._order + 1
                local kText = kcfg.text     or "Keybind"
                local kDef  = kcfg.default  or "None"
                local kHeld = kcfg.onHeld   or false
                local kCb   = kcfg.callback or function() end

                local row = Row(self._content, self._order, 32)

                New("TextLabel", {
                    Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1,
                    Text = kText, TextColor3 = T.PrimaryTextColor,
                    Font = Enum.Font.Gotham, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })

                local pill = New("TextButton", {
                    Size = UDim2.new(0,0,0,22), AutomaticSize = Enum.AutomaticSize.X,
                    AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,0,0.5,0),
                    BackgroundColor3 = T.KeybindBg, BorderSizePixel = 0,
                    Text = kDef, TextColor3 = T.PrimaryColor,
                    Font = Enum.Font.Gotham, TextSize = 11,
                    AutoButtonColor = false, Parent = row,
                })
                Corner(4, pill)
                Stroke(T.Line, 1, pill)
                Pad(0, 0, 7, 7, pill)

                local curKey    = kDef
                local listening = false

                pill.MouseButton1Click:Connect(function()
                    listening = true
                    pill.Text = "..."
                    pill.TextColor3 = T.SecondaryTextColor
                end)

                UserInputService.InputBegan:Connect(function(inp, gp)
                    if not listening then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        curKey = inp.KeyCode.Name
                        pill.Text = curKey
                        pill.TextColor3 = T.PrimaryColor
                        listening = false
                        kCb(curKey)
                    end
                end)

                if kHeld then
                    UserInputService.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            if inp.KeyCode.Name == curKey then kCb(curKey) end
                        end
                    end)
                end

                local KObj = {
                    getKeybind    = function() return curKey end,
                    updateKeybind = function(_, c2)
                        if c2.bind then curKey = c2.bind; pill.Text = curKey end
                    end,
                }
                Flags.Keybind[kText] = KObj
                return KObj
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
                local sDef  = scfg.default  or sMin
                local sCb   = scfg.callback or function() end

                local cont = New("Frame", {
                    Size = UDim2.new(1,0,0,46), BackgroundTransparency = 1,
                    LayoutOrder = self._order, Parent = self._content,
                })

                local topRow = New("Frame", {
                    Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1, Parent = cont,
                })
                New("TextLabel", {
                    Size = UDim2.new(1,-36,1,0), BackgroundTransparency = 1,
                    Text = sText, TextColor3 = T.PrimaryTextColor,
                    Font = Enum.Font.Gotham, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = topRow,
                })

                local valBadge = New("Frame", {
                    Size = UDim2.new(0,30,0,18),
                    AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,0,0.5,0),
                    BackgroundColor3 = T.KeybindBg, BorderSizePixel = 0, Parent = topRow,
                })
                Corner(4, valBadge)
                Stroke(T.Line, 1, valBadge)
                local valLbl = New("TextLabel", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                    Text = tostring(sDef), TextColor3 = T.SecondaryTextColor,
                    Font = Enum.Font.Gotham, TextSize = 11, Parent = valBadge,
                })

                local track = New("Frame", {
                    Size = UDim2.new(1,0,0,4), Position = UDim2.new(0,0,0,28),
                    BackgroundColor3 = T.ToggleOff, BorderSizePixel = 0, Parent = cont,
                })
                Corner(999, track)

                local fill = New("Frame", {
                    Size = UDim2.new(0,0,1,0), BackgroundColor3 = T.PrimaryColor,
                    BorderSizePixel = 0, Parent = track,
                })
                Corner(999, fill)

                local knob = New("Frame", {
                    Size = UDim2.new(0,14,0,14),
                    AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,0,0.5,0),
                    BackgroundColor3 = Color3.fromRGB(220,220,235),
                    BorderSizePixel = 0, Parent = track,
                })
                Corner(999, knob)
                Stroke(T.Line, 1, knob)

                local val      = sDef
                local dragging = false

                local function setVal(v)
                    v = math.clamp(math.round(v / sStep) * sStep, sMin, sMax)
                    val = v
                    local pct = (sMax ~= sMin) and (v - sMin) / (sMax - sMin) or 0
                    Tween(fill, {Size = UDim2.new(pct,0,1,0)}, 0.05)
                    Tween(knob, {Position = UDim2.new(pct,0,0.5,0)}, 0.05)
                    valLbl.Text = tostring(v)
                    sCb(v)
                end
                setVal(sDef)

                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        setVal(sMin + (sMax - sMin) * rel)
                    end
                end)
                track.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                knob.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                knob.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        setVal(sMin + (sMax - sMin) * rel)
                    end
                end)

                local SObj = {
                    getValue    = function() return val end,
                    updateValue = function(_, c2)
                        if c2.value then setVal(c2.value) end
                    end,
                }
                Flags.Slider[sText] = SObj
                return SObj
            end

            -- =====================================================
            -- createPicker
            -- =====================================================
            function Section:createPicker(pcfg)
                self._order = self._order + 1
                local pText = pcfg.text     or "ColorPicker"
                local pDef  = pcfg.default  or Color3.fromRGB(255,255,255)
                local pCb   = pcfg.callback or function() end

                local row = Row(self._content, self._order, 32)

                New("TextLabel", {
                    Size = UDim2.new(1,-36,1,0), BackgroundTransparency = 1,
                    Text = pText, TextColor3 = T.PrimaryTextColor,
                    Font = Enum.Font.Gotham, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })

                local swatch = New("TextButton", {
                    Size = UDim2.new(0,22,0,22),
                    AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,0,0.5,0),
                    BackgroundColor3 = pDef, BorderSizePixel = 0,
                    Text = "", AutoButtonColor = false, Parent = row,
                })
                Corner(4, swatch)
                Stroke(T.Line, 1, swatch)

                local popup = New("Frame", {
                    Size = UDim2.new(0,206,0,190),
                    AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,1,4),
                    BackgroundColor3 = T.SecondaryBackgroundColor,
                    BorderSizePixel = 0, Visible = false, ZIndex = 30, Parent = row,
                })
                Corner(8, popup)
                Stroke(T.Line, 1, popup)

                local function makeHSVTrack(parent, lbl, yOff, tColor)
                    New("TextLabel", {
                        Size = UDim2.new(1,-12,0,13), Position = UDim2.new(0,8,0,yOff),
                        BackgroundTransparency = 1, Text = lbl,
                        TextColor3 = T.SecondaryTextColor, Font = Enum.Font.Gotham,
                        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 31, Parent = parent,
                    })
                    local tr = New("Frame", {
                        Size = UDim2.new(1,-16,0,5), Position = UDim2.new(0,8,0,yOff+15),
                        BackgroundColor3 = T.ToggleOff, BorderSizePixel = 0, ZIndex = 31, Parent = parent,
                    })
                    Corner(999, tr)
                    local fl = New("Frame", {
                        Size = UDim2.new(0,0,1,0), BackgroundColor3 = tColor or T.PrimaryColor,
                        BorderSizePixel = 0, ZIndex = 32, Parent = tr,
                    })
                    Corner(999, fl)
                    local kn = New("Frame", {
                        Size = UDim2.new(0,12,0,12),
                        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0,0,0.5,0),
                        BackgroundColor3 = Color3.fromRGB(220,220,235),
                        BorderSizePixel = 0, ZIndex = 33, Parent = tr,
                    })
                    Corner(999, kn)
                    Stroke(T.Line, 1, kn)
                    return tr, fl, kn
                end

                local h, s, v = Color3.toHSV(pDef)
                local hTr,hFl,hKn = makeHSVTrack(popup,"Hue",       8,  Color3.fromRGB(200,50,50))
                local sTr,sFl,sKn = makeHSVTrack(popup,"Saturation",40, Color3.fromRGB(170,170,170))
                local vTr,vFl,vKn = makeHSVTrack(popup,"Value",      72, Color3.fromRGB(120,120,120))

                local preview = New("Frame", {
                    Size = UDim2.new(1,-16,0,30), Position = UDim2.new(0,8,0,106),
                    BackgroundColor3 = pDef, BorderSizePixel = 0, ZIndex = 31, Parent = popup,
                })
                Corner(6, preview)

                local hexBox = New("TextBox", {
                    Size = UDim2.new(1,-16,0,22), Position = UDim2.new(0,8,0,144),
                    BackgroundColor3 = T.ElementBackgroundColor, BorderSizePixel = 0,
                    Text = string.format("#%02X%02X%02X",
                        math.floor(pDef.R*255), math.floor(pDef.G*255), math.floor(pDef.B*255)),
                    TextColor3 = T.PrimaryTextColor, Font = Enum.Font.Code,
                    TextSize = 11, ClearTextOnFocus = false, ZIndex = 31, Parent = popup,
                })
                Corner(4, hexBox)
                Stroke(T.Line, 1, hexBox)

                local curColor = pDef

                local function sync()
                    curColor = Color3.fromHSV(h, s, v)
                    swatch.BackgroundColor3  = curColor
                    preview.BackgroundColor3 = curColor
                    hexBox.Text = string.format("#%02X%02X%02X",
                        math.floor(curColor.R*255), math.floor(curColor.G*255), math.floor(curColor.B*255))
                    hFl.Size = UDim2.new(h,0,1,0); hKn.Position = UDim2.new(h,0,0.5,0)
                    sFl.Size = UDim2.new(s,0,1,0); sKn.Position = UDim2.new(s,0,0.5,0)
                    vFl.Size = UDim2.new(v,0,1,0); vKn.Position = UDim2.new(v,0,0.5,0)
                    pCb(curColor)
                end
                sync()

                local function dragTrack(tr, onV)
                    local d = false
                    tr.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then
                            d = true
                            onV(math.clamp((i.Position.X - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1))
                            sync()
                        end
                    end)
                    tr.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end
                    end)
                    UserInputService.InputChanged:Connect(function(i)
                        if d and i.UserInputType == Enum.UserInputType.MouseMovement then
                            onV(math.clamp((i.Position.X - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1))
                            sync()
                        end
                    end)
                end

                dragTrack(hTr, function(val) h = val end)
                dragTrack(sTr, function(val) s = val end)
                dragTrack(vTr, function(val) v = val end)

                swatch.MouseButton1Click:Connect(function()
                    popup.Visible = not popup.Visible
                end)

                local PObj = {
                    getColor    = function() return curColor end,
                    updateColor = function(_, c2)
                        if c2.color then h, s, v = Color3.toHSV(c2.color); sync() end
                    end,
                }
                Flags.Picker[pText] = PObj
                return PObj
            end

            -- =====================================================
            -- createDropdown
            -- =====================================================
            function Section:createDropdown(dcfg)
                self._order = self._order + 1
                local dText  = dcfg.text     or "Dropdown"
                local dList  = dcfg.list     or {}
                local dDef   = dcfg.default  or {}
                local dMulti = dcfg.multiple or false
                local dCb    = dcfg.callback or function() end

                local labelRow = Row(self._content, self._order, 28)
                New("TextLabel", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                    Text = dText, TextColor3 = T.PrimaryTextColor,
                    Font = Enum.Font.Gotham, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = labelRow,
                })

                self._order = self._order + 0.5

                local dropBtn = New("TextButton", {
                    Size = UDim2.new(1,0,0,28),
                    BackgroundColor3 = T.ElementBackgroundColor,
                    BorderSizePixel = 0, Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = self._order, Parent = self._content,
                })
                Corner(6, dropBtn)
                Stroke(T.Line, 1, dropBtn)

                local selLbl = New("TextLabel", {
                    Size = UDim2.new(1,-28,1,0), Position = UDim2.new(0,10,0,0),
                    BackgroundTransparency = 1, Text = "",
                    TextColor3 = T.SecondaryTextColor, Font = Enum.Font.Gotham,
                    TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = dropBtn,
                })
                New("TextLabel", {
                    Size = UDim2.new(0,18,1,0), Position = UDim2.new(1,-22,0,0),
                    BackgroundTransparency = 1, Text = "v",
                    TextColor3 = T.SecondaryTextColor, Font = Enum.Font.Gotham,
                    TextSize = 12, Parent = dropBtn,
                })

                self._order = self._order + 0.1
                local listFrame = New("Frame", {
                    Size = UDim2.new(1,0,0,0),
                    BackgroundColor3 = T.ElementBackgroundColor,
                    BorderSizePixel = 0, Visible = false, ZIndex = 20,
                    LayoutOrder = self._order, Parent = self._content,
                })
                Corner(6, listFrame)
                Stroke(T.Line, 1, listFrame)

                local listScroll = New("ScrollingFrame", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                    BorderSizePixel = 0, ScrollBarThickness = 2,
                    ScrollBarImageColor3 = T.ScrollingBarImageColor,
                    CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 21, Parent = listFrame,
                })
                ListLayout(listScroll, 0)

                local selected = {}
                for _, vv in pairs(dDef) do selected[tostring(vv)] = true end

                local function displayText()
                    local t = {}
                    for k in pairs(selected) do table.insert(t, k) end
                    table.sort(t)
                    return table.concat(t, ", ")
                end

                local function fireCb()
                    selLbl.Text = displayText()
                    if dMulti then
                        local t = {}
                        for k in pairs(selected) do table.insert(t, k) end
                        dCb(t)
                    else
                        dCb(next(selected))
                    end
                end

                local function rebuild(list)
                    for _, c in pairs(listScroll:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, item in pairs(list) do
                        local iStr = tostring(item)
                        local iBtn = New("TextButton", {
                            Size = UDim2.new(1,0,0,26),
                            BackgroundColor3 = T.TertiaryBackgroundColor,
                            BackgroundTransparency = selected[iStr] and 0 or 1,
                            BorderSizePixel = 0, Text = iStr,
                            TextColor3 = selected[iStr] and T.PrimaryColor or T.PrimaryTextColor,
                            Font = Enum.Font.Gotham, TextSize = 12,
                            AutoButtonColor = false, ZIndex = 22, Parent = listScroll,
                        })
                        Pad(0, 0, 10, 0, iBtn)
                        iBtn.MouseButton1Click:Connect(function()
                            if dMulti then
                                if selected[iStr] then selected[iStr] = nil else selected[iStr] = true end
                            else
                                selected = {}; selected[iStr] = true
                                listFrame.Visible = false
                            end
                            for _, c2 in pairs(listScroll:GetChildren()) do
                                if c2:IsA("TextButton") then
                                    local sel = selected[c2.Text]
                                    c2.BackgroundTransparency = sel and 0 or 1
                                    c2.TextColor3 = sel and T.PrimaryColor or T.PrimaryTextColor
                                end
                            end
                            fireCb()
                        end)
                    end
                    listFrame.Size = UDim2.new(1,0,0, math.min(#list * 26, 130))
                end

                local curList = dList
                rebuild(curList)
                selLbl.Text = displayText()

                local open = false
                dropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    listFrame.Visible = open
                end)

                local DObj = {
                    getList  = function() return curList end,
                    getValue = function()
                        if dMulti then
                            local t = {}
                            for k in pairs(selected) do table.insert(t, k) end
                            return t
                        else
                            return next(selected)
                        end
                    end,
                    updateList = function(_, c2)
                        if not c2.list then return end
                        curList = c2.list; selected = {}
                        for _, vv in pairs(c2.default or {}) do selected[tostring(vv)] = true end
                        rebuild(curList); selLbl.Text = displayText()
                    end,
                }
                Flags.Dropdown[dText] = DObj
                return DObj
            end

            -- =====================================================
            -- createButton
            -- =====================================================
            function Section:createButton(bcfg)
                self._order = self._order + 1
                local bText = bcfg.text     or "Button"
                local bCb   = bcfg.callback or function() end

                local btn = New("TextButton", {
                    Size = UDim2.new(1,0,0,30),
                    BackgroundColor3 = T.ElementBackgroundColor,
                    BorderSizePixel = 0, Text = bText,
                    TextColor3 = T.PrimaryTextColor, Font = Enum.Font.GothamBold,
                    TextSize = 12, AutoButtonColor = false, ClipsDescendants = true,
                    LayoutOrder = self._order, Parent = self._content,
                })
                Corner(6, btn)
                Stroke(T.Line, 1, btn)

                btn.MouseEnter:Connect(function()
                    Tween(btn, {BackgroundColor3 = T.TertiaryBackgroundColor}, 0.1)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, {BackgroundColor3 = T.ElementBackgroundColor}, 0.1)
                end)
                btn.MouseButton1Click:Connect(function()
                    Ripple(btn); bCb()
                end)

                return btn
            end

            -- =====================================================
            -- createTextBox
            -- =====================================================
            function Section:createTextBox(tcfg)
                self._order = self._order + 1
                local tText = tcfg.text     or "TextBox"
                local tDef  = tcfg.default  or ""
                local tCb   = tcfg.callback or function() end

                local row = Row(self._content, self._order, 32)

                New("TextLabel", {
                    Size = UDim2.new(1,-80,1,0), BackgroundTransparency = 1,
                    Text = tText, TextColor3 = T.PrimaryTextColor,
                    Font = Enum.Font.Gotham, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                })

                local box = New("TextBox", {
                    Size = UDim2.new(0,54,0,22),
                    AnchorPoint = Vector2.new(1,0.5), Position = UDim2.new(1,0,0.5,0),
                    BackgroundColor3 = T.KeybindBg, BorderSizePixel = 0,
                    Text = tDef, TextColor3 = T.SecondaryTextColor,
                    Font = Enum.Font.Gotham, TextSize = 11,
                    ClearTextOnFocus = false, Parent = row,
                })
                Corner(4, box)
                Stroke(T.Line, 1, box)
                Pad(0, 0, 6, 6, box)

                box.FocusLost:Connect(function() tCb(box.Text) end)

                local TObj = {
                    getText    = function() return box.Text end,
                    updateText = function(_, c2)
                        if c2.text then box.Text = c2.text end
                    end,
                }
                Flags.TextBox[tText] = TObj
                return TObj
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
    local T      = self._theme or Theme
    local folder = cfg.folderName or "UIConfigs"
    local icon   = cfg.icon

    pcall(function()
        if not isfolder(folder) then makefolder(folder) end
    end)

    local manTab  = self:createTab({text = "Manager", icon = icon})
    local cfgPage = manTab:createSubTab({text = "Config", sectionStyle = "Single"})
    local cfgSect = cfgPage:createSection({text = "Config Manager", position = "Left"})

    local cfgName = "default"
    cfgSect:createTextBox({
        text = "Config Name", default = "default",
        callback = function(t) cfgName = t end,
    })
    cfgSect:createButton({
        text = "Save Config",
        callback = function()
            local data = {}
            for k, v in pairs(Flags.Toggle)   do data["Toggle_"  .. k] = v:getState()   end
            for k, v in pairs(Flags.Slider)   do data["Slider_"  .. k] = v:getValue()   end
            for k, v in pairs(Flags.Keybind)  do data["Keybind_" .. k] = v:getKeybind() end
            for k, v in pairs(Flags.Dropdown) do
                local val = v:getValue()
                data["Dropdown_" .. k] = type(val) == "table" and table.concat(val, ",") or tostring(val or "")
            end
            pcall(function()
                writefile(folder .. "/" .. cfgName .. ".json", HttpService:JSONEncode(data))
            end)
            self:notify({title = "Saved", text = cfgName .. ".json", sizeY = 64})
        end,
    })
    cfgSect:createButton({
        text = "Load Config",
        callback = function()
            pcall(function()
                local d = HttpService:JSONDecode(readfile(folder .. "/" .. cfgName .. ".json"))
                for k, v in pairs(d) do
                    if k:sub(1,7) == "Toggle_"  and Flags.Toggle[k:sub(8)]  then
                        Flags.Toggle[k:sub(8)]:updateState({state = v})
                    end
                    if k:sub(1,7) == "Slider_"  and Flags.Slider[k:sub(8)]  then
                        Flags.Slider[k:sub(8)]:updateValue({value = v})
                    end
                    if k:sub(1,8) == "Keybind_" and Flags.Keybind[k:sub(9)] then
                        Flags.Keybind[k:sub(9)]:updateKeybind({bind = v})
                    end
                end
                self:notify({title = "Loaded", text = cfgName .. ".json", sizeY = 64})
            end)
        end,
    })

    local thPage = manTab:createSubTab({text = "Theme", sectionStyle = "Single"})
    local thSect = thPage:createSection({text = "Theme Editor", position = "Left"})

    thSect:createPicker({
        text = "Accent Color", default = T.PrimaryColor,
        callback = function(c) T.PrimaryColor = c end,
    })
    thSect:createPicker({
        text = "Background", default = T.PrimaryBackgroundColor,
        callback = function(c)
            T.PrimaryBackgroundColor = c
            if WinFrame then WinFrame.BackgroundColor3 = c end
        end,
    })
    thSect:createPicker({
        text = "Sidebar Color", default = T.TabBackgroundColor,
        callback = function(c) T.TabBackgroundColor = c end,
    })
end

return Library

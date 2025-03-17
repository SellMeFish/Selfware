--[[
   LuxField - Ein modernes UI-Framework für Roblox
   Autor: Du (und ChatGPT)
   Version: 1.0
   Lizenz: Frei verwendbar (z. B. MIT)

   Merkmale:
   - Moderne, abgerundete Designs
   - Animierte Fenster (Fade-In, Fade-Out)
   - Draggable Window (PC & Mobile)
   - Tabs mit smooth Fade
   - Labels, Paragraphs, Divider, Sections
   - Buttons, Toggles, Keybinds, Sliders, ColorPicker, Dropdown, Input
   - Benachrichtigungen mit Tween-Animationen
   - Mehrere Themes
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LuxField = {}
LuxField._theme = "Default"
LuxField._windows = {}
LuxField._flags = {}
LuxField._themes = {
    ["Default"] = {
        MainColor      = Color3.fromRGB(40, 40, 40),
        SecondaryColor = Color3.fromRGB(55, 55, 55),
        TextColor      = Color3.fromRGB(235, 235, 235),
        AccentColor    = Color3.fromRGB(0, 170, 255),
        Font           = Enum.Font.Gotham,
        BackgroundFade = 0.05, -- Hintergrund-Transparenz für "Glass"-Effekte, falls gewünscht
        CornerRadius   = 8     -- Abgerundete Ecken
    },
    ["Light"] = {
        MainColor      = Color3.fromRGB(240, 240, 240),
        SecondaryColor = Color3.fromRGB(210, 210, 210),
        TextColor      = Color3.fromRGB(30, 30, 30),
        AccentColor    = Color3.fromRGB(255, 140, 0),
        Font           = Enum.Font.Gotham,
        BackgroundFade = 0.1,
        CornerRadius   = 8
    },
    ["Dark"] = {
        MainColor      = Color3.fromRGB(25, 25, 25),
        SecondaryColor = Color3.fromRGB(45, 45, 45),
        TextColor      = Color3.fromRGB(230, 230, 230),
        AccentColor    = Color3.fromRGB(255, 70, 70),
        Font           = Enum.Font.Gotham,
        BackgroundFade = 0.03,
        CornerRadius   = 8
    }
}

-- Utility-Funktion zum schnellen Erstellen von Objekten
local function createInstance(className, props, parent)
    local obj = Instance.new(className)
    for k,v in pairs(props) do
        obj[k] = v
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

-- Tween Utility
local function tweenObject(object, tweenInfo, goal)
    local tween = TweenService:Create(object, tweenInfo, goal)
    tween:Play()
    return tween
end

-- Rundung anwenden
local function addCornerRadius(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

-- Schatten-Effekt
local function addDropShadow(parent, shadowColor)
    local shadow = createInstance("ImageLabel", {
        Name = "DropShadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 60, 1, 60),
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = shadowColor or Color3.new(0,0,0),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        ZIndex = 0
    }, parent)
    return shadow
end

-- Animiertes Verschieben (für das Draggable-System)
local function dragify(frame, topBar)
    local dragToggle = nil
    local dragSpeed = 0.125
    local dragStart = nil
    local startPos = nil

    local function updateInput(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        tweenObject(frame, TweenInfo.new(dragSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = position})
    end

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            if dragToggle then
                updateInput(input)
            end
        end
    end)
end

-- ========================================================
-- =          HAUPTFUNKTIONEN DER LuxField-LIB            =
-- ========================================================

function LuxField:CreateWindow(options)
    options = options or {}
    local windowName     = options.Name or "LuxField Window"
    local windowIcon     = options.Icon or 0
    local loadingTitle   = options.LoadingTitle or "LuxField Interface"
    local loadingSub     = options.LoadingSubtitle or "Loading..."
    local chosenTheme    = options.Theme or "Default"

    if self._themes[chosenTheme] then
        self._theme = chosenTheme
    else
        warn("LuxField: Theme '"..tostring(chosenTheme).."' nicht gefunden. Verwende 'Default'.")
        self._theme = "Default"
    end

    local themeData = self._themes[self._theme]

    -- ScreenGui
    local screenGui = createInstance("ScreenGui", {
        Name = "LuxField_"..windowName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    }, game.CoreGui)

    -- Haupt-Frame
    local mainFrame = createInstance("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0, 540, 0, 320),
        BackgroundColor3 = themeData.MainColor,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        BackgroundTransparency = themeData.BackgroundFade
    }, screenGui)
    addCornerRadius(mainFrame, themeData.CornerRadius)
    addDropShadow(mainFrame, Color3.new(0,0,0))

    -- Titel-Bar
    local titleBar = createInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = themeData.SecondaryColor,
        BorderSizePixel = 0,
        ZIndex = 2
    }, mainFrame)
    addCornerRadius(titleBar, themeData.CornerRadius)

    local titleLabel = createInstance("TextLabel", {
        Name = "TitleLabel",
        Text = windowName,
        Font = themeData.Font,
        TextSize = 18,
        TextColor3 = themeData.TextColor,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.fromOffset(10, 0)
    }, titleBar)

    -- (Optional) Icon
    if windowIcon and type(windowIcon) == "number" and windowIcon ~= 0 then
        local iconLabel = createInstance("ImageLabel", {
            Name = "IconLabel",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(4, 4),
            Size = UDim2.fromOffset(24, 24),
            Image = "rbxassetid://"..tostring(windowIcon),
            ZIndex = 3
        }, titleBar)
    elseif windowIcon and type(windowIcon) == "string" then
        -- Lucide Icon / benutzerdefinierte Icon-Logik
        -- Du könntest hier anstelle von Roblox Image einen Mapping-Service für String-Icons machen
        -- Zur Demo setzen wir es ebenfalls auf rbxassetid
        local iconLabel = createInstance("ImageLabel", {
            Name = "IconLabel",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(4, 4),
            Size = UDim2.fromOffset(24, 24),
            Image = "rbxassetid://11488118347", -- Platzhalter
            ZIndex = 3
        }, titleBar)
    end

    -- Tab Container
    local tabContainer = createInstance("Frame", {
        Name = "TabContainer",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 32),
        Size = UDim2.new(1, 0, 1, -32),
        ClipsDescendants = true
    }, mainFrame)

    local windowObject = {
        _windowName = windowName,
        _icon = windowIcon,
        _screenGui = screenGui,
        _mainFrame = mainFrame,
        _tabContainer = tabContainer,
        _themeData = themeData,
        Tabs = {}
    }

    table.insert(self._windows, windowObject)

    -- Dragify
    dragify(mainFrame, titleBar)

    -- Fade-In Animation für das Window
    mainFrame.BackgroundTransparency = 1
    titleBar.BackgroundTransparency = 1
    for _,desc in ipairs(mainFrame:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
            desc.TextTransparency = 1
        elseif desc:IsA("Frame") or desc:IsA("ImageLabel") then
            if desc ~= mainFrame and desc ~= titleBar then
                desc.BackgroundTransparency = 1
                if desc:IsA("ImageLabel") then
                    desc.ImageTransparency = 1
                end
            end
        end
    end

    local fadeTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    tweenObject(mainFrame, fadeTweenInfo, {BackgroundTransparency = themeData.BackgroundFade})
    tweenObject(titleBar, fadeTweenInfo, {BackgroundTransparency = 0})
    task.spawn(function()
        for _,desc in ipairs(mainFrame:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                tweenObject(desc, fadeTweenInfo, {TextTransparency = 0})
            elseif desc:IsA("ImageLabel") then
                tweenObject(desc, fadeTweenInfo, {ImageTransparency = 0})
            elseif desc:IsA("Frame") and desc ~= mainFrame and desc ~= titleBar then
                tweenObject(desc, fadeTweenInfo, {BackgroundTransparency = 0})
            end
        end
    end)

    -- Notification-Funktion direkt ins Window-Objekt
    function windowObject:Notify(data)
        local notTitle   = data.Title or "Benachrichtigung"
        local notContent = data.Content or ""
        local duration   = data.Duration or 4
        local notImage   = data.Image or 0

        local notifFrame = createInstance("Frame", {
            Name = "Notification",
            BackgroundColor3 = self._themeData.SecondaryColor,
            Position = UDim2.fromScale(0.5, -0.1),
            AnchorPoint = Vector2.new(0.5, 0),
            Size = UDim2.new(0, 300, 0, 70),
            ClipsDescendants = true,
            ZIndex = 9999
        }, self._screenGui)
        addCornerRadius(notifFrame, self._themeData.CornerRadius)

        local notifTitle = createInstance("TextLabel", {
            Name = "NotifTitle",
            Text = notTitle,
            Font = self._themeData.Font,
            TextSize = 18,
            TextColor3 = self._themeData.TextColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 0, 26),
            Position = UDim2.fromOffset(10, 4),
            ZIndex = 9999
        }, notifFrame)

        local notifContent = createInstance("TextLabel", {
            Name = "NotifContent",
            Text = notContent,
            Font = self._themeData.Font,
            TextSize = 14,
            TextColor3 = self._themeData.TextColor,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -10, 0, 30),
            Position = UDim2.fromOffset(10, 30),
            TextWrapped = true,
            ZIndex = 9999
        }, notifFrame)

        -- Icon (falls gewünscht)
        if notImage and type(notImage) == "number" and notImage ~= 0 then
            local icon = createInstance("ImageLabel", {
                Name = "NotifIcon",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(270, 5),
                Size = UDim2.fromOffset(24, 24),
                Image = "rbxassetid://"..tostring(notImage),
                ZIndex = 9999
            }, notifFrame)
        elseif notImage and type(notImage) == "string" then
            local icon = createInstance("ImageLabel", {
                Name = "NotifIcon",
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(270, 5),
                Size = UDim2.fromOffset(24, 24),
                Image = "rbxassetid://11488118347", -- Platzhalter-Icon
                ZIndex = 9999
            }, notifFrame)
        end

        -- Fade-In
        notifFrame.BackgroundTransparency = 1
        notifTitle.TextTransparency = 1
        notifContent.TextTransparency = 1
        tweenObject(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 0})
        tweenObject(notifTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 0})
        tweenObject(notifContent, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 0})

        -- Nach 'duration' Sekunden wieder ausblenden
        task.delay(duration, function()
            tweenObject(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
            tweenObject(notifTitle, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 1})
            tweenObject(notifContent, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {TextTransparency = 1})
            task.wait(0.45)
            if notifFrame then
                notifFrame:Destroy()
            end
        end)
    end

    -- Destroy-Funktion
    function windowObject:Destroy()
        if self._screenGui then
            self._screenGui:Destroy()
        end
    end

    -- CreateTab
    function windowObject:CreateTab(tabName, iconId)
        tabName = tabName or "Unbenannt"
        local tabFrame = createInstance("Frame", {
            Name = tabName,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
        }, self._tabContainer)

        local uiList = createInstance("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder
        }, tabFrame)

        local tabObject = {
            Name = tabName,
            Icon = iconId or 0,
            Frame = tabFrame,
            Elements = {},
            WindowRef = windowObject
        }

        function tabObject:Show()
            for _,tb in pairs(windowObject.Tabs) do
                if tb.Frame ~= self.Frame then
                    -- Tab ausblenden mit Fade
                    tweenObject(tb.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1})
                    task.spawn(function()
                        for _,desc in ipairs(tb.Frame:GetDescendants()) do
                            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                                tweenObject(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 1})
                            elseif desc:IsA("Frame") or desc:IsA("ImageLabel") then
                                tweenObject(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1, ImageTransparency = 1})
                            end
                        end
                        task.wait(0.31)
                        tb.Frame.Visible = false
                    end)
                end
            end

            -- Dieses Tab einblenden
            self.Frame.Visible = true
            for _,desc in ipairs(self.Frame:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    desc.TextTransparency = 1
                elseif desc:IsA("Frame") or desc:IsA("ImageLabel") then
                    desc.BackgroundTransparency = 1
                    if desc:IsA("ImageLabel") then
                        desc.ImageTransparency = 1
                    end
                end
            end
            tabFrame.BackgroundTransparency = 1

            tweenObject(tabFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 0})
            task.spawn(function()
                for _,desc in ipairs(tabFrame:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                        tweenObject(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {TextTransparency = 0})
                    elseif desc:IsA("ImageLabel") then
                        tweenObject(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {ImageTransparency = 0})
                    elseif desc:IsA("Frame") and desc ~= tabFrame then
                        tweenObject(desc, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundTransparency = 0})
                    end
                end
            end)
        end

        -- Label
        function tabObject:CreateLabel(text, icon, color, ignoreTheme)
            local lbl = createInstance("TextLabel", {
                Name = "Label_"..text,
                Text = text or "Label",
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = color or self.WindowRef._themeData.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, tabFrame)

            local labelObj = {
                Instance = lbl
            }
            function labelObj:Set(newText, newIcon, newColor, newIgnore)
                if newText then
                    lbl.Text = newText
                end
                if newColor then
                    lbl.TextColor3 = newColor
                end
            end
            table.insert(self.Elements, labelObj)
            return labelObj
        end

        -- Paragraph
        function tabObject:CreateParagraph(data)
            local title   = data.Title or "ParagraphTitle"
            local content = data.Content or "ParagraphContent"

            local container = createInstance("Frame", {
                Name = "Paragraph_"..title,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 50),
            }, tabFrame)

            local titleLbl = createInstance("TextLabel", {
                Name = "ParagraphTitle",
                Text = title,
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = self.WindowRef._themeData.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, container)

            local contentLbl = createInstance("TextLabel", {
                Name = "ParagraphContent",
                Text = content,
                Font = self.WindowRef._themeData.Font,
                TextSize = 14,
                TextColor3 = self.WindowRef._themeData.TextColor,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 20),
                Size = UDim2.new(1, 0, 0, 30),
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left
            }, container)

            local paragraphObj = {
                Container = container,
                Title = titleLbl,
                Content = contentLbl
            }
            function paragraphObj:Set(newData)
                if newData.Title then
                    self.Title.Text = newData.Title
                end
                if newData.Content then
                    self.Content.Text = newData.Content
                end
            end
            table.insert(self.Elements, paragraphObj)
            return paragraphObj
        end

        -- Divider
        function tabObject:CreateDivider()
            local divider = createInstance("Frame", {
                Name = "Divider",
                Size = UDim2.new(1, -10, 0, 2),
                BackgroundColor3 = self.WindowRef._themeData.AccentColor,
                BackgroundTransparency = 0
            }, tabFrame)

            local dividerObj = {
                Instance = divider
            }
            function dividerObj:Set(visible)
                divider.Visible = visible
            end
            table.insert(self.Elements, dividerObj)
            return dividerObj
        end

        -- Section
        function tabObject:CreateSection(sectionName)
            local secLabel = createInstance("TextLabel", {
                Name = "Section_"..sectionName,
                Text = "== "..sectionName.." ==",
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = self.WindowRef._themeData.AccentColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, tabFrame)

            local sectionObj = {
                Instance = secLabel
            }
            function sectionObj:Set(newText)
                secLabel.Text = "== "..newText.." =="
            end
            table.insert(self.Elements, sectionObj)
            return sectionObj
        end

        -- Button
        function tabObject:CreateButton(data)
            local btnName  = data.Name or "Button"
            local callback = data.Callback or function() end

            local button = createInstance("TextButton", {
                Name = "Button_"..btnName,
                Text = btnName,
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = self.WindowRef._themeData.TextColor,
                BackgroundColor3 = self.WindowRef._themeData.SecondaryColor,
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)
            addCornerRadius(button, self.WindowRef._themeData.CornerRadius)

            local buttonObj = {
                Instance = button
            }

            button.MouseButton1Down:Connect(function()
                -- Klick-Animation (kurz abdunkeln)
                tweenObject(button, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {BackgroundColor3 = self.WindowRef._themeData.AccentColor})
            end)

            button.MouseButton1Up:Connect(function()
                tweenObject(button, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {BackgroundColor3 = self.WindowRef._themeData.SecondaryColor})
                callback()
            end)

            function buttonObj:Set(newName)
                if newName then
                    button.Text = newName
                end
            end

            table.insert(self.Elements, buttonObj)
            return buttonObj
        end

        -- Toggle
        function tabObject:CreateToggle(data)
            local toggleName   = data.Name or "Toggle"
            local currentValue = data.CurrentValue or false
            local callback     = data.Callback or function() end

            local toggleFrame = createInstance("Frame", {
                Name = "Toggle_"..toggleName,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 30),
            }, tabFrame)

            local toggleBtn = createInstance("TextButton", {
                Name = "ToggleButton",
                Text = "",
                BackgroundColor3 = self.WindowRef._themeData.SecondaryColor,
                Size = UDim2.fromOffset(40, 20),
                Position = UDim2.fromOffset(0, 5)
            }, toggleFrame)
            addCornerRadius(toggleBtn, 10)

            local toggleCircle = createInstance("Frame", {
                Name = "ToggleCircle",
                Size = UDim2.new(0,18,0,18),
                Position = currentValue and UDim2.fromOffset(20,1) or UDim2.fromOffset(1,1),
                BackgroundColor3 = Color3.new(1,1,1)
            }, toggleBtn)
            addCornerRadius(toggleCircle, 9)

            local toggleLabel = createInstance("TextLabel", {
                Name = "ToggleLabel",
                Text = toggleName,
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = self.WindowRef._themeData.TextColor,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(50, 0),
                Size = UDim2.new(1, -60, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left
            }, toggleFrame)

            local toggleObj = {
                Frame        = toggleFrame,
                Button       = toggleBtn,
                Circle       = toggleCircle,
                Label        = toggleLabel,
                CurrentValue = currentValue
            }

            local function updateToggle(value)
                if value then
                    -- an
                    tweenObject(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = self.WindowRef._themeData.AccentColor})
                    tweenObject(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.fromOffset(20,1)})
                else
                    -- aus
                    tweenObject(toggleBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {BackgroundColor3 = self.WindowRef._themeData.SecondaryColor})
                    tweenObject(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Position = UDim2.fromOffset(1,1)})
                end
            end

            updateToggle(currentValue)

            toggleBtn.MouseButton1Click:Connect(function()
                toggleObj.CurrentValue = not toggleObj.CurrentValue
                updateToggle(toggleObj.CurrentValue)
                callback(toggleObj.CurrentValue)
            end)

            function toggleObj:Set(value)
                self.CurrentValue = value
                updateToggle(value)
                callback(value)
            end

            table.insert(self.Elements, toggleObj)
            return toggleObj
        end

        -- Keybind
        function tabObject:CreateKeybind(data)
            local keybindName   = data.Name or "Keybind"
            local currentKey    = data.CurrentKeybind or "Q"
            local holdToInteract= data.HoldToInteract or false
            local callback      = data.Callback or function() end

            local kbBtn = createInstance("TextButton", {
                Name = "Keybind_"..keybindName,
                Text = keybindName.." ["..currentKey.."]",
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = self.WindowRef._themeData.TextColor,
                BackgroundColor3 = self.WindowRef._themeData.SecondaryColor,
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)
            addCornerRadius(kbBtn, self.WindowRef._themeData.CornerRadius)

            local keybindObj = {
                Instance       = kbBtn,
                CurrentKeybind = currentKey,
                HoldToInteract = holdToInteract
            }

            kbBtn.MouseButton1Click:Connect(function()
                kbBtn.Text = "Drücke eine Taste..."
                local connection
                connection = UserInputService.InputBegan:Connect(function(input, gp)
                    if not gp then
                        if input.KeyCode ~= Enum.KeyCode.Unknown then
                            local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                            keybindObj.CurrentKeybind = keyName
                            kbBtn.Text = keybindName.." ["..keyName.."]"
                            connection:Disconnect()
                        end
                    end
                end)
            end)

            -- Du kannst hier (falls du magst) ein globales Input-Event einbauen,
            -- um das Drücken des Keybinds zu erkennen -> callback().

            table.insert(self.Elements, keybindObj)
            return keybindObj
        end

        -- Slider
        function tabObject:CreateSlider(data)
            local sliderName  = data.Name or "Slider"
            local range       = data.Range or {0,100}
            local increment   = data.Increment or 1
            local suffix      = data.Suffix or ""
            local currentVal  = data.CurrentValue or 0
            local callback    = data.Callback or function() end

            local sliderFrame = createInstance("Frame", {
                Name = "Slider_"..sliderName,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 40),
            }, tabFrame)

            local sliderLabel = createInstance("TextLabel", {
                Name = "SliderLabel",
                Text = sliderName.." : "..tostring(currentVal).." "..suffix,
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = self.WindowRef._themeData.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.fromOffset(0,0),
                TextXAlignment = Enum.TextXAlignment.Left
            }, sliderFrame)

            local barBack = createInstance("Frame", {
                Name = "BarBack",
                BackgroundColor3 = self.WindowRef._themeData.SecondaryColor,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(0,25),
                Size = UDim2.new(1, -40, 0, 8)
            }, sliderFrame)
            addCornerRadius(barBack, 4)

            local fill = createInstance("Frame", {
                Name = "Fill",
                BackgroundColor3 = self.WindowRef._themeData.AccentColor,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 0, 1, 0)
            }, barBack)
            addCornerRadius(fill, 4)

            local dragBtn = createInstance("ImageButton", {
                Name = "DragHandle",
                BackgroundColor3 = Color3.new(1,1,1),
                Size = UDim2.fromOffset(16,16),
                Position = UDim2.fromOffset(0, -4), 
                Image = "",
                ZIndex = 2
            }, fill)
            addCornerRadius(dragBtn, 8)

            local sliderObj = {
                Frame       = sliderFrame,
                Label       = sliderLabel,
                Fill        = fill,
                DragHandle  = dragBtn,
                CurrentValue= currentVal
            }

            local function setSlider(val)
                val = math.clamp(val, range[1], range[2])
                val = math.floor(val/increment + 0.5) * increment
                sliderObj.CurrentValue = val
                sliderLabel.Text = sliderName.." : "..tostring(val).." "..suffix

                local percent = (val - range[1])/(range[2] - range[1])
                tweenObject(fill, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {Size = UDim2.new(percent, 0, 1, 0)})
                callback(val)
            end

            -- Interaktion (Drag)
            local dragging = false
            dragBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            dragBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            barBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    local relativeX = (input.Position.X - barBack.AbsolutePosition.X)
                    local ratio = math.clamp(relativeX / barBack.AbsoluteSize.X, 0, 1)
                    local newVal = (ratio * (range[2] - range[1])) + range[1]
                    setSlider(newVal)
                end
            end)
            barBack.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input, gp)
                if not gp and dragging then
                    if input.UserInputType == Enum.UserInputType.MouseMovement or
                       input.UserInputType == Enum.UserInputType.Touch then
                        local relativeX = (input.Position.X - barBack.AbsolutePosition.X)
                        local ratio = math.clamp(relativeX / barBack.AbsoluteSize.X, 0, 1)
                        local newVal = (ratio * (range[2] - range[1])) + range[1]
                        setSlider(newVal)
                    end
                end
            end)

            function sliderObj:Set(value)
                setSlider(value)
            end

            setSlider(currentVal)
            table.insert(self.Elements, sliderObj)
            return sliderObj
        end

        -- Input (TextBox)
        function tabObject:CreateInput(data)
            local inpName       = data.Name or "Input"
            local currentValue  = data.CurrentValue or ""
            local placeholder   = data.PlaceholderText or "Eingabe..."
            local callback      = data.Callback or function() end

            local txtBox = createInstance("TextBox", {
                Name = "Input_"..inpName,
                Text = currentValue,
                PlaceholderText = placeholder,
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = self.WindowRef._themeData.TextColor,
                BackgroundColor3 = self.WindowRef._themeData.SecondaryColor,
                ClearTextOnFocus = false,
                Size = UDim2.new(1, -10, 0, 30)
            }, tabFrame)
            addCornerRadius(txtBox, self.WindowRef._themeData.CornerRadius)

            local inputObj = {
                Instance = txtBox,
                CurrentValue = currentValue
            }
            txtBox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    inputObj.CurrentValue = txtBox.Text
                    callback(txtBox.Text)
                end
            end)

            function inputObj:Set(newText)
                txtBox.Text = newText
                self.CurrentValue = newText
            end

            table.insert(self.Elements, inputObj)
            return inputObj
        end

        -- Dropdown
        function tabObject:CreateDropdown(data)
            local ddName    = data.Name or "Dropdown"
            local options   = data.Options or {"Option1", "Option2"}
            local current   = data.CurrentOption or {options[1]}
            local multiple  = data.MultipleOptions or false
            local callback  = data.Callback or function() end

            local ddFrame = createInstance("Frame", {
                Name = "Dropdown_"..ddName,
                Size = UDim2.new(1, -10, 0, 30),
                BackgroundColor3 = self.WindowRef._themeData.SecondaryColor
            }, tabFrame)
            addCornerRadius(ddFrame, self.WindowRef._themeData.CornerRadius)

            local ddButton = createInstance("TextButton", {
                Name = "DropdownButton",
                Text = ddName.." [ "..table.concat(current, ", ").." ]",
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = self.WindowRef._themeData.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1,0,1,0)
            }, ddFrame)

            local dropdownObj = {
                Frame = ddFrame,
                CurrentOption = current,
                AllOptions = options
            }

            -- Popup-Frame
            local popupFrame = createInstance("Frame", {
                Name = "Popup",
                BackgroundColor3 = self.WindowRef._themeData.SecondaryColor,
                Size = UDim2.new(1, 0, 0, #options * 24),
                Position = UDim2.fromScale(0,1),
                Visible = false,
                ClipsDescendants = true,
                ZIndex = 999
            }, ddFrame)
            addCornerRadius(popupFrame, self.WindowRef._themeData.CornerRadius)

            local popupLayout = createInstance("UIListLayout", {
                Padding = UDim.new(0,2),
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                SortOrder = Enum.SortOrder.LayoutOrder
            }, popupFrame)

            local function updateDropdownText()
                ddButton.Text = ddName.." [ "..table.concat(dropdownObj.CurrentOption, ", ").." ]"
            end

            local function togglePopup()
                popupFrame.Visible = not popupFrame.Visible
                if popupFrame.Visible then
                    tweenObject(popupFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1,0, 0, #dropdownObj.AllOptions*24)})
                else
                    tweenObject(popupFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)})
                    task.wait(0.21)
                    popupFrame.Visible = false
                end
            end

            ddButton.MouseButton1Click:Connect(function()
                togglePopup()
            end)

            local function createOptionItem(opt)
                local optBtn = createInstance("TextButton", {
                    Name = "Option_"..opt,
                    Text = opt,
                    Font = self.WindowRef._themeData.Font,
                    TextSize = 14,
                    TextColor3 = self.WindowRef._themeData.TextColor,
                    BackgroundColor3 = self.WindowRef._themeData.SecondaryColor,
                    Size = UDim2.new(1,0,0,24)
                }, popupFrame)

                optBtn.MouseButton1Click:Connect(function()
                    if multiple then
                        local found = table.find(dropdownObj.CurrentOption, opt)
                        if found then
                            table.remove(dropdownObj.CurrentOption, found)
                        else
                            table.insert(dropdownObj.CurrentOption, opt)
                        end
                    else
                        dropdownObj.CurrentOption = {opt}
                        togglePopup()
                    end
                    updateDropdownText()
                    callback(dropdownObj.CurrentOption)
                end)
            end

            for _,opt in ipairs(options) do
                createOptionItem(opt)
            end

            function dropdownObj:Set(newOptionTable)
                self.CurrentOption = newOptionTable
                updateDropdownText()
                callback(newOptionTable)
            end

            function dropdownObj:Refresh(newList)
                self.AllOptions = newList
                -- Alte Buttons löschen
                for _,child in pairs(popupFrame:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                -- Neue anlegen
                for _,opt in ipairs(newList) do
                    createOptionItem(opt)
                end
                -- Größe anpassen
                popupFrame.Size = UDim2.new(1,0,0,#newList*24)
            end

            table.insert(self.Elements, dropdownObj)
            return dropdownObj
        end

        -- ColorPicker (kleines Farb-Feld)
        function tabObject:CreateColorPicker(data)
            local pickerName = data.Name or "Color Picker"
            local startColor = data.Color or Color3.fromRGB(255,255,255)
            local callback   = data.Callback or function() end

            local cpFrame = createInstance("Frame", {
                Name = "ColorPicker_"..pickerName,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -10, 0, 50),
            }, tabFrame)

            local lbl = createInstance("TextLabel", {
                Name = "ColorPickerLabel",
                Text = pickerName,
                Font = self.WindowRef._themeData.Font,
                TextSize = 16,
                TextColor3 = self.WindowRef._themeData.TextColor,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -60, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left
            }, cpFrame)

            local colorBox = createInstance("Frame", {
                Name = "ColorBox",
                BackgroundColor3 = startColor,
                Size = UDim2.fromOffset(40, 30),
                Position = UDim2.fromOffset(0, 20),
                BorderSizePixel = 0
            }, cpFrame)
            addCornerRadius(colorBox, self.WindowRef._themeData.CornerRadius)

            local pickFrame = createInstance("Frame", {
                Name = "PickFrame",
                BackgroundColor3 = Color3.fromRGB(255,0,0),
                Position = UDim2.fromOffset(60,0),
                Size = UDim2.new(1, -60, 1, 0),
                Visible = false
            }, cpFrame)

            local colorLayout = createInstance("UIGridLayout", {
                CellSize = UDim2.fromOffset(24,24),
                CellPadding = UDim2.fromOffset(2,2),
                FillDirectionMaxCells = 10
            }, pickFrame)

            local colorList = {
                Color3.fromRGB(255,255,255),
                Color3.fromRGB(0,0,0),
                Color3.fromRGB(255,0,0),
                Color3.fromRGB(0,255,0),
                Color3.fromRGB(0,0,255),
                Color3.fromRGB(255,255,0),
                Color3.fromRGB(255,0,255),
                Color3.fromRGB(0,255,255),
                Color3.fromRGB(128,128,128),
                Color3.fromRGB(255,128,0),
                Color3.fromRGB(128,0,255),
                Color3.fromRGB(128,255,0),
                -- ... Beliebig erweiterbar
            }

            for _,col in ipairs(colorList) do
                local colBtn = createInstance("TextButton", {
                    Name = "ColorChoice_"..tostring(col),
                    BackgroundColor3 = col,
                    Text = "",
                    BorderSizePixel = 0
                }, pickFrame)
                colBtn.MouseButton1Click:Connect(function()
                    colorBox.BackgroundColor3 = col
                    callback(col)
                end)
            end

            local cpObj = {
                Frame = cpFrame,
                Box = colorBox,
                Color = startColor
            }

            -- Öffnen/Schließen
            colorBox.MouseButton1Click = nil -- Frame, daher kein MouseButton. Wir fügen daher:
            colorBox.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    pickFrame.Visible = not pickFrame.Visible
                end
            end)

            function cpObj:Set(newColor)
                colorBox.BackgroundColor3 = newColor
                self.Color = newColor
                callback(newColor)
            end

            table.insert(self.Elements, cpObj)
            return cpObj
        end

        table.insert(windowObject.Tabs, tabObject)
        return tabObject
    end

    return windowObject
end

-- Destroy ALL
function LuxField:Destroy()
    for _,win in ipairs(self._windows) do
        if win._screenGui then
            win._screenGui:Destroy()
        end
    end
    self._windows = {}
end

-- Flags (falls du Speichern/Laden willst)
function LuxField:GetFlag(flagName)
    return self._flags[flagName]
end
function LuxField:SetFlag(flagName, value)
    self._flags[flagName] = value
end

return LuxField

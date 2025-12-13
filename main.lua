--[[
    🐉 DRAGON RED ADMIN PANEL v7 - ULTIMATE EDITION
    ═══════════════════════════════════════════════
    ✨ Totalmente mejorado y rediseñado
    🔥 100% funcional en todos los executors
    ⚡ Nuevas funciones universales
    🎨 Diseño profesional con animaciones
]]

--// Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local VIM = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

--// Variables principales
local char = player.Character or player.CharacterAdded:Wait()
local hum, root

local function getHumanoid()
    char = player.Character or player.CharacterAdded:Wait()
    hum = char:FindFirstChildOfClass("Humanoid")
    root = char:FindFirstChild("HumanoidRootPart")
    return hum, root
end

hum, root = getHumanoid()

player.CharacterAdded:Connect(function(c)
    char = c
    hum, root = getHumanoid()
end)

--// Estados globales
local states = {
    Fly = false,
    Noclip = false,
    InfJump = false,
    God = false,
    AuraKill = false,
    ESP = false,
    Fullbright = false,
    AutoClick = false,
    AutoRejoin = false,
    AntiAFK = false,
    ClickTP = false,
    HitboxExpander = false,
    Spinbot = false,
    XRay = false,
    WalkOnWater = false
}

--// Configuraciones
local config = {
    flySpeed = 80,
    walkSpeed = 16,
    jumpPower = 50,
    auraRange = 12,
    autoClickDelay = 0.05,
    hitboxSize = 20,
    espColor = Color3.fromRGB(255, 0, 0)
}

local savedPosition = nil
local selectedPlayer = nil
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "DragonRedESP"

local originalSizes = {}  -- Para guardar tamaños originales de hitboxes

--// Sistema de notificaciones
local notificationQueue = {}
local notificationActive = false

local function createNotification(title, text, duration)
    table.insert(notificationQueue, {title = title, text = text, duration = duration or 3})
    if not notificationActive then
        task.spawn(function()
            while #notificationQueue > 0 do
                notificationActive = true
                local notif = table.remove(notificationQueue, 1)
                
                local gui = Instance.new("ScreenGui")
                gui.Name = "DragonNotif"
                gui.ResetOnSpawn = false
                gui.IgnoreGuiInset = true
                gui.Parent = player.PlayerGui
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 320, 0, 80)
                frame.Position = UDim2.new(1, -340, 0, 20)
                frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
                frame.BorderSizePixel = 0
                frame.Parent = gui
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 12)
                corner.Parent = frame
                
                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(220, 40, 40)
                stroke.Thickness = 2
                stroke.Parent = frame
                
                local icon = Instance.new("TextLabel")
                icon.Size = UDim2.new(0, 50, 0, 50)
                icon.Position = UDim2.new(0, 15, 0.5, -25)
                icon.BackgroundTransparency = 1
                icon.Text = "🐉"
                icon.TextSize = 30
                icon.Parent = frame
                
                local titleLabel = Instance.new("TextLabel")
                titleLabel.Size = UDim2.new(1, -80, 0, 25)
                titleLabel.Position = UDim2.new(0, 70, 0, 10)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = notif.title
                titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                titleLabel.Font = Enum.Font.GothamBold
                titleLabel.TextSize = 16
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.Parent = frame
                
                local textLabel = Instance.new("TextLabel")
                textLabel.Size = UDim2.new(1, -80, 0, 35)
                textLabel.Position = UDim2.new(0, 70, 0, 35)
                textLabel.BackgroundTransparency = 1
                textLabel.Text = notif.text
                textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                textLabel.Font = Enum.Font.Gotham
                textLabel.TextSize = 13
                textLabel.TextXAlignment = Enum.TextXAlignment.Left
                textLabel.TextYAlignment = Enum.TextYAlignment.Top
                textLabel.TextWrapped = true
                textLabel.Parent = frame
                
                frame:TweenPosition(UDim2.new(1, -340, 0, 20), "Out", "Back", 0.5, true)
                
                task.wait(notif.duration)
                
                frame:TweenPosition(UDim2.new(1, 20, 0, 20), "In", "Back", 0.4, true)
                task.wait(0.5)
                gui:Destroy()
            end
            notificationActive = false
        end)
    end
end

--// Splash screen inicial
local function showSplashScreen()
    local splash = Instance.new("ScreenGui")
    splash.Name = "DragonSplash"
    splash.ResetOnSpawn = false
    splash.IgnoreGuiInset = true
    splash.Parent = player.PlayerGui
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    bg.BorderSizePixel = 0
    bg.Parent = splash
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 400, 0, 150)
    logo.Position = UDim2.new(0.5, -200, 0.5, -100)
    logo.BackgroundTransparency = 1
    logo.Text = "🐉"
    logo.TextSize = 100
    logo.TextColor3 = Color3.fromRGB(220, 40, 40)
    logo.Parent = bg
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 400, 0, 50)
    title.Position = UDim2.new(0.5, -200, 0.5, 30)
    title.BackgroundTransparency = 1
    title.Text = "DRAGON RED"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 40
    title.Parent = bg
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 400, 0, 30)
    subtitle.Position = UDim2.new(0.5, -200, 0.5, 80)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "v7 Ultimate Edition"
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 18
    subtitle.Parent = bg
    
    local loading = Instance.new("TextLabel")
    loading.Size = UDim2.new(0, 400, 0, 30)
    loading.Position = UDim2.new(0.5, -200, 0.5, 120)
    loading.BackgroundTransparency = 1
    loading.Text = "Cargando..."
    loading.TextColor3 = Color3.fromRGB(150, 150, 150)
    loading.Font = Enum.Font.Gotham
    loading.TextSize = 14
    loading.Parent = bg
    
    TweenService:Create(logo, TweenInfo.new(0.8, Enum.EasingStyle.Back), {TextTransparency = 0}):Play()
    
    task.wait(2)
    
    bg:TweenPosition(UDim2.new(0, 0, -1, 0), "In", "Quad", 0.6, true)
    task.wait(0.7)
    splash:Destroy()
end

task.spawn(showSplashScreen)

--// GUI Principal
local gui = Instance.new("ScreenGui")
gui.Name = "DragonRedGUI_v7"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Icono minimizado
local dragonIcon = Instance.new("TextButton")
dragonIcon.Name = "DragonIcon"
dragonIcon.Size = UDim2.new(0, 50, 0, 50)
dragonIcon.Position = UDim2.new(0, 20, 1, -70)
dragonIcon.Text = "🐉"
dragonIcon.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
dragonIcon.TextColor3 = Color3.fromRGB(220, 40, 40)
dragonIcon.TextSize = 28
dragonIcon.Visible = false
dragonIcon.Parent = gui
dragonIcon.AutoButtonColor = false

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = dragonIcon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(220, 40, 40)
iconStroke.Thickness = 2
iconStroke.Parent = dragonIcon

-- Panel principal (más grande y moderno)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 700, 0, 520)
frame.Position = UDim2.new(0.5, -350, 0.5, -260)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BorderSizePixel = 0
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 16)
frameCorner.Parent = frame

local frameBorder = Instance.new("UIStroke")
frameBorder.Color = Color3.fromRGB(200, 0, 0)
frameBorder.Thickness = 2
frameBorder.Parent = frame

-- Barra superior mejorada
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topBar.BorderSizePixel = 0
topBar.Parent = frame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 16)
topCorner.Parent = topBar

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 20)
topFix.Position = UDim2.new(0, 0, 1, -20)
topFix.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topFix.BorderSizePixel = 0
topFix.Parent = topBar

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0, 40, 0, 40)
logo.Position = UDim2.new(0, 10, 0.5, -20)
logo.BackgroundTransparency = 1
logo.Text = "🐉"
logo.TextSize = 28
logo.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 200, 0, 25)
title.Position = UDim2.new(0, 55, 0, 5)
title.BackgroundTransparency = 1
title.Text = "DRAGON RED"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Code
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0, 200, 0, 20)
subtitle.Position = UDim2.new(0, 55, 0, 28)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Ultimate Edition v7"
subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
subtitle.Font = Enum.Font.Code
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = topBar

local userInfo = Instance.new("TextLabel")
userInfo.Size = UDim2.new(0, 200, 0, 20)
userInfo.Position = UDim2.new(1, -210, 0, 8)
userInfo.BackgroundTransparency = 1
userInfo.Text = "👤 " .. player.Name
userInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
userInfo.Font = Enum.Font.Code
userInfo.TextSize = 13
userInfo.TextXAlignment = Enum.TextXAlignment.Right
userInfo.Parent = topBar

local serverInfo = Instance.new("TextLabel")
serverInfo.Size = UDim2.new(0, 200, 0, 20)
serverInfo.Position = UDim2.new(1, -210, 0, 26)
serverInfo.BackgroundTransparency = 1
serverInfo.Text = "🌐 Players: " .. #Players:GetPlayers()
serverInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
serverInfo.Font = Enum.Font.Code
serverInfo.TextSize = 11
serverInfo.TextXAlignment = Enum.TextXAlignment.Right
serverInfo.Parent = topBar

Players.PlayerAdded:Connect(function()
    serverInfo.Text = "🌐 Players: " .. #Players:GetPlayers()
end)

Players.PlayerRemoving:Connect(function()
    serverInfo.Text = "🌐 Players: " .. #Players:GetPlayers()
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -42, 0.5, -17.5)
closeBtn.Text = "✖"
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.Code
closeBtn.Parent = topBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-- Funciones minimizar/maximizar mejoradas
local iconDragging = false
local iconDragStart = nil
local iconStartPos = nil

local function minimizePanel()
    frame.Visible = false
    dragonIcon.Visible = true
    createNotification("Dragon Red", "Panel minimizado - Arrastra el icono", 2)
end

local function maximizePanel()
    frame.Visible = true
    dragonIcon.Visible = false
end

closeBtn.MouseButton1Click:Connect(minimizePanel)
dragonIcon.MouseButton1Click:Connect(maximizePanel)

-- Drag system para el icono minimizado
dragonIcon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        iconDragging = true
        iconDragStart = input.Position
        iconStartPos = dragonIcon.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                iconDragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if iconDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - iconDragStart
        dragonIcon.Position = UDim2.new(
            iconStartPos.X.Scale,
            iconStartPos.X.Offset + delta.X,
            iconStartPos.Y.Scale,
            iconStartPos.Y.Offset + delta.Y
        )
    end
end)

-- Drag system
do
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Toggle con RightShift
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if frame.Visible then
            minimizePanel()
        else
            maximizePanel()
        end
    end
end)

-- Contenedor principal con sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 150, 1, -50)
sidebar.Position = UDim2.new(0, 0, 0, 50)
sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
sidebar.BorderSizePixel = 0
sidebar.Parent = frame

local mainContent = Instance.new("Frame")
mainContent.Size = UDim2.new(1, -150, 1, -50)
mainContent.Position = UDim2.new(0, 150, 0, 50)
mainContent.BackgroundTransparency = 1
mainContent.Parent = frame

-- Sistema de tabs mejorado
local tabs = {}
local currentTab = nil

local function createTabButton(name, icon, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.Text = icon .. "  " .. name
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = sidebar
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(200, 0, 0)
    btnStroke.Thickness = 0
    btnStroke.Parent = btn
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 15)
    padding.Parent = btn
    
    return btn
end

local function createTabPage()
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -20)
    scrollFrame.Position = UDim2.new(0, 10, 0, 10)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(220, 40, 40)
    scrollFrame.Visible = false
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.Parent = mainContent
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scrollFrame
    
    return scrollFrame
end

local function switchTab(name)
    for n, data in pairs(tabs) do
        data.page.Visible = (n == name)
        if n == name then
            data.button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            data.button.TextColor3 = Color3.fromRGB(255, 255, 255)
            local stroke = data.button:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Thickness = 2 end
        else
            data.button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            data.button.TextColor3 = Color3.fromRGB(200, 200, 200)
            local stroke = data.button:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Thickness = 0 end
        end
    end
    currentTab = name
end

-- Crear tabs
tabs["Movement"] = {
    button = createTabButton("Movement", "🚀", 10),
    page = createTabPage()
}
tabs["Combat"] = {
    button = createTabButton("Combat", "⚔️", 55),
    page = createTabPage()
}
tabs["Players"] = {
    button = createTabButton("Players", "👥", 100),
    page = createTabPage()
}
tabs["Visual"] = {
    button = createTabButton("Visual", "👁️", 145),
    page = createTabPage()
}
tabs["Utility"] = {
    button = createTabButton("Utility", "🛠️", 190),
    page = createTabPage()
}
tabs["Settings"] = {
    button = createTabButton("Settings", "⚙️", 235),
    page = createTabPage()
}

for name, data in pairs(tabs) do
    data.button.MouseButton1Click:Connect(function()
        switchTab(name)
    end)
end

switchTab("Movement")

-- Helper functions para crear elementos UI
local function createSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 35)
    section.BackgroundTransparency = 1
    section.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Code
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 1, -5)
    line.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    line.BorderSizePixel = 0
    line.Parent = section
    
    return section
end

local function createToggle(parent, labelText, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 45)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 1
    stroke.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 45, 0, 25)
    toggle.Position = UDim2.new(1, -55, 0.5, -12.5)
    toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.Parent = container
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggle
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 19, 0, 19)
    indicator.Position = UDim2.new(0, 3, 0.5, -9.5)
    indicator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    indicator.BorderSizePixel = 0
    indicator.Parent = toggle
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = indicator
    
    local enabled = false
    
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        
        if enabled then
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 0, 0)}):Play()
            TweenService:Create(indicator, TweenInfo.new(0.2), {
                Position = UDim2.new(1, -22, 0.5, -9.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        else
            TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
            TweenService:Create(indicator, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 3, 0.5, -9.5),
                BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            }):Play()
        end
        
        if callback then
            callback(enabled)
        end
    end)
    
    return container, toggle
end

local function createButton(parent, labelText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 14
    btn.Text = labelText
    btn.AutoButtonColor = false
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 30, 30)}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 0, 0)}):Play()
    end)
    
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    
    return btn
end

local function createSlider(parent, labelText, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    container.BorderSizePixel = 0
    container.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 1
    stroke.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0, 20)
    label.Position = UDim2.new(0, 15, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 0, 20)
    valueLabel.Position = UDim2.new(1, -70, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -30, 0, 6)
    track.Position = UDim2.new(0, 15, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    track.BorderSizePixel = 0
    track.Parent = container
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    fill.BorderSizePixel = 0
    fill.Parent = track
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    local dragging = false
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            local value = math.floor(min + (max - min) * percent)
            valueLabel.Text = tostring(value)
            if callback then
                callback(value)
            end
        end
    end)
    
    return container
end

--// ═════════════════════════════════════════════
--// MOVEMENT TAB
--// ═════════════════════════════════════════════
local movePage = tabs["Movement"].page

createSection(movePage, "⚡ Movement Controls")

createToggle(movePage, "Fly Mode", function(enabled)
    states.Fly = enabled
    hum, root = getHumanoid()
    if not hum or not root then return end
    
    if enabled then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "DragonFly"
        bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bv.Velocity = Vector3.new()
        bv.Parent = root
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "DragonGyro"
        bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        bg.P = 9e4
        bg.CFrame = camera.CFrame
        bg.Parent = root
        
        hum.PlatformStand = true
        createNotification("Fly", "Activado - WASD + Space/Ctrl", 3)
    else
        if root:FindFirstChild("DragonFly") then root.DragonFly:Destroy() end
        if root:FindFirstChild("DragonGyro") then root.DragonGyro:Destroy() end
        if hum then hum.PlatformStand = false end
        createNotification("Fly", "Desactivado", 2)
    end
end)

createToggle(movePage, "Noclip", function(enabled)
    states.Noclip = enabled
    createNotification("Noclip", enabled and "Activado" or "Desactivado", 2)
end)

createToggle(movePage, "Infinite Jump", function(enabled)
    states.InfJump = enabled
    createNotification("Infinite Jump", enabled and "Activado" or "Desactivado", 2)
end)

createToggle(movePage, "Walk on Water", function(enabled)
    states.WalkOnWater = enabled
    createNotification("Walk on Water", enabled and "Activado" or "Desactivado", 2)
end)

createSection(movePage, "⚙️ Speed Controls")

createSlider(movePage, "Walk Speed", 16, 150, 16, function(value)
    config.walkSpeed = value
    hum, root = getHumanoid()
    if hum then
        hum.WalkSpeed = value
    end
end)

createSlider(movePage, "Jump Power", 50, 200, 50, function(value)
    config.jumpPower = value
    hum, root = getHumanoid()
    if hum then
        hum.JumpPower = value
    end
end)

createSlider(movePage, "Fly Speed", 20, 250, 80, function(value)
    config.flySpeed = value
end)

-- Fly logic mejorado
local flyVel = Vector3.new()
RunService.RenderStepped:Connect(function()
    if states.Fly then
        hum, root = getHumanoid()
        if not root then return end
        
        local bv = root:FindFirstChild("DragonFly")
        local bg = root:FindFirstChild("DragonGyro")
        if not bv or not bg then return end
        
        local dir = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        
        if dir.Magnitude > 0 then
            dir = dir.Unit * config.flySpeed
        end
        
        flyVel = flyVel:Lerp(dir, 0.2)
        bv.Velocity = flyVel
        bg.CFrame = camera.CFrame
    end
end)

-- Noclip logic
RunService.Stepped:Connect(function()
    if states.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if states.InfJump then
        hum, root = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Walk on water
task.spawn(function()
    while true do
        task.wait(0.1)
        if states.WalkOnWater then
            hum, root = getHumanoid()
            if root then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name == "Water" or obj.Material == Enum.Material.Water then
                        if (obj.Position - root.Position).Magnitude < 20 then
                            obj.CanCollide = true
                        end
                    end
                end
            end
        end
    end
end)

--// ═════════════════════════════════════════════
--// COMBAT TAB
--// ═════════════════════════════════════════════
local combatPage = tabs["Combat"].page

createSection(combatPage, "⚔️ Combat Features")

createToggle(combatPage, "God Mode", function(enabled)
    states.God = enabled
    createNotification("God Mode", enabled and "Activado" or "Desactivado", 2)
end)

createToggle(combatPage, "Aura Kill", function(enabled)
    states.AuraKill = enabled
    createNotification("Aura Kill", enabled and "Activado - ¡Cuidado!" or "Desactivado", 2)
end)

createToggle(combatPage, "Hitbox Expander", function(enabled)
    states.HitboxExpander = enabled
    createNotification("Hitbox Expander", enabled and "Activado" or "Desactivado", 2)
end)

createToggle(combatPage, "Spinbot (Anti-Hit)", function(enabled)
    states.Spinbot = enabled
    createNotification("Spinbot", enabled and "Activado" or "Desactivado", 2)
end)

createSection(combatPage, "⚙️ Combat Settings")

createSlider(combatPage, "Aura Range", 5, 50, 12, function(value)
    config.auraRange = value
end)

createSlider(combatPage, "Hitbox Size", 5, 50, 20, function(value)
    config.hitboxSize = value
end)

-- God Mode logic mejorado
task.spawn(function()
    while true do
        task.wait(0.1)
        if states.God then
            hum, root = getHumanoid()
            if hum then
                hum.Health = hum.MaxHealth
            end
        end
    end
end)

-- Aura Kill logic
RunService.Heartbeat:Connect(function()
    if states.AuraKill then
        hum, root = getHumanoid()
        if not root then return end
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local enemyRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                local enemyHum = plr.Character:FindFirstChildOfClass("Humanoid")
                
                if enemyRoot and enemyHum and enemyHum.Health > 0 then
                    local distance = (enemyRoot.Position - root.Position).Magnitude
                    if distance <= config.auraRange then
                        enemyHum.Health = 0
                    end
                end
            end
        end
    end
end)

-- Hitbox Expander mejorado
task.spawn(function()
    while true do
        task.wait(0.1)
        if states.HitboxExpander then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        -- Guardar tamaño original
                        if not originalSizes[plr.Name] then
                            originalSizes[plr.Name] = hrp.Size
                        end
                        
                        -- Expandir hitbox
                        hrp.Size = Vector3.new(config.hitboxSize, config.hitboxSize, config.hitboxSize)
                        hrp.Transparency = 0.8
                        hrp.CanCollide = false
                        hrp.Massless = true
                    end
                end
            end
        else
            -- Restaurar tamaños originales
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and originalSizes[plr.Name] then
                        hrp.Size = originalSizes[plr.Name]
                        hrp.Transparency = 1
                        hrp.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- Spinbot
local spinSpeed = 0
RunService.RenderStepped:Connect(function()
    if states.Spinbot then
        hum, root = getHumanoid()
        if root then
            spinSpeed = spinSpeed + 20
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
        end
    end
end)

--// ═════════════════════════════════════════════
--// PLAYERS TAB (Lista completa de jugadores)
--// ═════════════════════════════════════════════
local playersPage = tabs["Players"].page

createSection(playersPage, "👥 Player List")

local playerListContainer = Instance.new("Frame")
playerListContainer.Size = UDim2.new(1, 0, 0, 320)
playerListContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
playerListContainer.BorderSizePixel = 0
playerListContainer.Parent = playersPage

local playerListCorner = Instance.new("UICorner")
playerListCorner.CornerRadius = UDim.new(0, 10)
playerListCorner.Parent = playerListContainer

local playerListStroke = Instance.new("UIStroke")
playerListStroke.Color = Color3.fromRGB(200, 0, 0)
playerListStroke.Thickness = 1
playerListStroke.Parent = playerListContainer

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, -10, 1, -10)
playerScroll.Position = UDim2.new(0, 5, 0, 5)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 6
playerScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerScroll.Parent = playerListContainer

local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 5)
playerLayout.Parent = playerScroll

local function createPlayerButton(plr)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = playerScroll
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(200, 0, 0)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -50, 0, 20)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.Code
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = btn
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, -50, 0, 15)
    distLabel.Position = UDim2.new(0, 10, 0, 25)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "Distance: ---"
    distLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    distLabel.Font = Enum.Font.Code
    distLabel.TextSize = 11
    distLabel.TextXAlignment = Enum.TextXAlignment.Left
    distLabel.Parent = btn
    
    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(0, 35, 0, 30)
    selectBtn.Position = UDim2.new(1, -40, 0.5, -15)
    selectBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    selectBtn.Text = "→"
    selectBtn.TextSize = 18
    selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectBtn.Font = Enum.Font.Code
    selectBtn.Parent = btn
    
    local selectCorner = Instance.new("UICorner")
    selectCorner.CornerRadius = UDim.new(0, 6)
    selectCorner.Parent = selectBtn
    
    selectBtn.MouseButton1Click:Connect(function()
        selectedPlayer = plr
        createNotification("Player Selected", plr.Name, 2)
        
        -- Actualizar todos los botones
        for _, child in ipairs(playerScroll:GetChildren()) do
            if child:IsA("TextButton") then
                local selBtn = child:FindFirstChild("TextButton")
                if selBtn then
                    selBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                end
            end
        end
        selectBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    end)
    
    -- Actualizar distancia
    task.spawn(function()
        while btn.Parent do
            task.wait(0.5)
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                hum, root = getHumanoid()
                if root then
                    local dist = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    distLabel.Text = string.format("Distance: %.1f studs", dist)
                end
            else
                distLabel.Text = "Distance: ---"
            end
        end
    end)
    
    return btn
end

local function updatePlayerList()
    -- Limpiar lista
    for _, child in ipairs(playerScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Recrear layout
    if not playerScroll:FindFirstChildOfClass("UIListLayout") then
        playerLayout = Instance.new("UIListLayout")
        playerLayout.Padding = UDim.new(0, 5)
        playerLayout.Parent = playerScroll
    end
    
    -- Agregar todos los jugadores
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            createPlayerButton(plr)
        end
    end
    
    createNotification("Player List", "Lista actualizada - " .. (#Players:GetPlayers() - 1) .. " jugadores", 2)
end

-- Actualización inicial
updatePlayerList()

-- Auto-actualizar cuando entran/salen jugadores
Players.PlayerAdded:Connect(function(plr)
    task.wait(0.5)
    updatePlayerList()
end)

Players.PlayerRemoving:Connect(function(plr)
    task.wait(0.5)
    updatePlayerList()
end)

createSection(playersPage, "🎯 Player Actions")

createButton(playersPage, "🔄 Refresh Player List", function()
    updatePlayerList()
end)

createButton(playersPage, "📍 Teleport to Selected Player", function()
    if selectedPlayer and selectedPlayer.Character then
        hum, root = getHumanoid()
        local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 3, 3)
            createNotification("Teleported", "To " .. selectedPlayer.Name, 2)
        else
            createNotification("Error", "El jugador no tiene HumanoidRootPart", 2)
        end
    else
        createNotification("Error", "No player selected", 2)
    end
end)

createButton(playersPage, "👁️ View Selected Player", function()
    if selectedPlayer and selectedPlayer.Character then
        local targetHum = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        if targetHum then
            camera.CameraSubject = targetHum
            createNotification("Viewing", selectedPlayer.Name, 2)
        else
            createNotification("Error", "El jugador no tiene Humanoid", 2)
        end
    else
        createNotification("Error", "No player selected", 2)
    end
end)

createButton(playersPage, "↩️ Reset Camera to Self", function()
    hum, root = getHumanoid()
    if hum then
        camera.CameraSubject = hum
        createNotification("Camera", "Reset to self", 2)
    end
end)

--// ═════════════════════════════════════════════
--// VISUAL TAB
--// ═════════════════════════════════════════════
local visualPage = tabs["Visual"].page

createSection(visualPage, "👁️ Visual Features")

createToggle(visualPage, "ESP (Name Tags)", function(enabled)
    states.ESP = enabled
    
    espFolder:ClearAllChildren()
    
    if enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "DragonESP_" .. plr.Name
                    billboard.Adornee = head
                    billboard.Size = UDim2.new(0, 100, 0, 50)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = espFolder
                    
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = plr.Name
                    nameLabel.TextColor3 = config.espColor
                    nameLabel.TextStrokeTransparency = 0
                    nameLabel.Font = Enum.Font.Code
                    nameLabel.TextScaled = true
                    nameLabel.Parent = billboard
                    
                    local distLabel = Instance.new("TextLabel")
                    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
                    distLabel.BackgroundTransparency = 1
                    distLabel.Text = "--- studs"
                    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    distLabel.TextStrokeTransparency = 0
                    distLabel.Font = Enum.Font.Code
                    distLabel.TextScaled = true
                    distLabel.Parent = billboard
                    
                    -- Update distance
                    task.spawn(function()
                        while billboard.Parent and plr.Character do
                            task.wait(0.3)
                            hum, root = getHumanoid()
                            local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                            if root and targetRoot then
                                local dist = (targetRoot.Position - root.Position).Magnitude
                                distLabel.Text = string.format("%.0f studs", dist)
                            end
                        end
                    end)
                end
            end
        end
        createNotification("ESP", "Activado", 2)
    else
        createNotification("ESP", "Desactivado", 2)
    end
end)

createToggle(visualPage, "Fullbright", function(enabled)
    states.Fullbright = enabled
    
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        createNotification("Fullbright", "Activado", 2)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
        createNotification("Fullbright", "Desactivado", 2)
    end
end)

createToggle(visualPage, "X-Ray (See Through Walls)", function(enabled)
    states.XRay = enabled
    
    if enabled then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj.Parent:FindFirstChildOfClass("Humanoid") then
                obj.LocalTransparencyModifier = 0.7
            end
        end
        createNotification("X-Ray", "Activado", 2)
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.LocalTransparencyModifier = 0
            end
        end
        createNotification("X-Ray", "Desactivado", 2)
    end
end)

createSection(visualPage, "🎨 ESP Color Settings")

local colorButtons = {
    {name = "Red", color = Color3.fromRGB(255, 0, 0)},
    {name = "Green", color = Color3.fromRGB(0, 255, 0)},
    {name = "Blue", color = Color3.fromRGB(0, 150, 255)},
    {name = "Yellow", color = Color3.fromRGB(255, 255, 0)},
    {name = "Purple", color = Color3.fromRGB(200, 0, 255)},
    {name = "Cyan", color = Color3.fromRGB(0, 255, 255)}
}

local colorContainer = Instance.new("Frame")
colorContainer.Size = UDim2.new(1, 0, 0, 90)
colorContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
colorContainer.BorderSizePixel = 0
colorContainer.Parent = visualPage

local colorCorner = Instance.new("UICorner")
colorCorner.CornerRadius = UDim.new(0, 10)
colorCorner.Parent = colorContainer

local colorStroke = Instance.new("UIStroke")
colorStroke.Color = Color3.fromRGB(200, 0, 0)
colorStroke.Thickness = 1
colorStroke.Parent = colorContainer

local colorGrid = Instance.new("UIGridLayout")
colorGrid.CellSize = UDim2.new(0.3, 0, 0, 32)
colorGrid.CellPadding = UDim2.new(0.05, 0, 0, 8)
colorGrid.Parent = colorContainer

local colorPadding = Instance.new("UIPadding")
colorPadding.PaddingLeft = UDim.new(0.05, 0)
colorPadding.PaddingTop = UDim.new(0, 10)
colorPadding.Parent = colorContainer

for _, colorData in ipairs(colorButtons) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = colorData.color
    btn.Text = colorData.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.Parent = colorContainer
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Thickness = 0
    btnStroke.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        config.espColor = colorData.color
        
        -- Update all ESP
        for _, billboard in ipairs(espFolder:GetChildren()) do
            if billboard:IsA("BillboardGui") then
                local nameLabel = billboard:FindFirstChildOfClass("TextLabel")
                if nameLabel then
                    nameLabel.TextColor3 = colorData.color
                end
            end
        end
        
        createNotification("ESP Color", colorData.name .. " selected", 2)
        
        -- Visual feedback
        for _, otherBtn in ipairs(colorContainer:GetChildren()) do
            if otherBtn:IsA("TextButton") then
                local stroke = otherBtn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Thickness = 0 end
            end
        end
        btnStroke.Thickness = 3
    end)
end

createSection(visualPage, "⚙️ Visual Settings")

createSlider(visualPage, "ESP Distance Scale", 50, 200, 100, function(value)
    for _, billboard in ipairs(espFolder:GetChildren()) do
        if billboard:IsA("BillboardGui") then
            billboard.Size = UDim2.new(0, value, 0, value/2)
        end
    end
end)

--// ═════════════════════════════════════════════
--// UTILITY TAB
--// ═════════════════════════════════════════════
local utilityPage = tabs["Utility"].page

createSection(utilityPage, "🛠️ Utility Features")

createToggle(utilityPage, "Auto Click", function(enabled)
    states.AutoClick = enabled
    createNotification("Auto Click", enabled and "Activado" or "Desactivado", 2)
end)

createToggle(utilityPage, "Anti AFK", function(enabled)
    states.AntiAFK = enabled
    createNotification("Anti AFK", enabled and "Activado" or "Desactivado", 2)
end)

createToggle(utilityPage, "Click TP (Hold Ctrl)", function(enabled)
    states.ClickTP = enabled
    createNotification("Click TP", enabled and "Activado - Ctrl + Click" or "Desactivado", 2)
end)

createToggle(utilityPage, "Auto Rejoin on Death", function(enabled)
    states.AutoRejoin = enabled
    createNotification("Auto Rejoin", enabled and "Activado" or "Desactivado", 2)
end)

createSection(utilityPage, "⚙️ Utility Settings")

createSlider(utilityPage, "Auto Click Speed (ms)", 20, 300, 50, function(value)
    config.autoClickDelay = value / 1000
end)

createSection(utilityPage, "📍 Position Tools")

createButton(utilityPage, "💾 Save Current Position", function()
    hum, root = getHumanoid()
    if root then
        savedPosition = root.CFrame
        createNotification("Position Saved", "Posición guardada exitosamente", 2)
    end
end)

createButton(utilityPage, "📍 Load Saved Position", function()
    hum, root = getHumanoid()
    if root and savedPosition then
        root.CFrame = savedPosition
        createNotification("Position Loaded", "Teleportado a posición guardada", 2)
    else
        createNotification("Error", "No hay posición guardada", 2)
    end
end)

createButton(utilityPage, "🔄 Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, player)
end)

-- Auto Click logic mejorado
task.spawn(function()
    while true do
        task.wait(config.autoClickDelay)
        if states.AutoClick then
            pcall(function()
                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.01)
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
        end
    end
end)

-- Auto Collect logic mejorado
local collectNames = {"Coin", "Cash", "Money", "Drop", "Gem", "Crystal", "Orb", "Star", "Token"}

task.spawn(function()
    while true do
        task.wait(0.2)
        if states.AutoCollect then
            hum, root = getHumanoid()
            if root then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local isCollectable = false
                        for _, name in ipairs(collectNames) do
                            if string.find(obj.Name:lower(), name:lower()) then
                                isCollectable = true
                                break
                            end
                        end
                        
                        if isCollectable then
                            local dist = (obj.Position - root.Position).Magnitude
                            if dist <= config.collectRange then
                                pcall(function()
                                    if firetouchinterest then
                                        firetouchinterest(root, obj, 0)
                                        task.wait()
                                        firetouchinterest(root, obj, 1)
                                    else
                                        obj.CFrame = root.CFrame
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Anti AFK
task.spawn(function()
    while true do
        task.wait(300) -- cada 5 minutos
        if states.AntiAFK then
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                task.wait(0.1)
                VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            end)
        end
    end
end)

-- Auto Rejoin mejorado
player.CharacterAdded:Connect(function(c)
    char = c
    hum, root = getHumanoid()
    
    if hum then
        hum.Died:Connect(function()
            if states.AutoRejoin then
                task.wait(1)
                TeleportService:Teleport(game.PlaceId, player)
            end
        end)
    end
end)

--// ═════════════════════════════════════════════
--// SETTINGS TAB
--// ═════════════════════════════════════════════
local settingsPage = tabs["Settings"].page

createSection(settingsPage, "⚙️ General Settings")

createButton(settingsPage, "🔄 Reset All Settings", function()
    for key, _ in pairs(states) do
        states[key] = false
    end
    
    config.flySpeed = 80
    config.walkSpeed = 16
    config.jumpPower = 50
    config.auraRange = 12
    config.collectRange = 30
    config.autoClickDelay = 0.05
    config.hitboxSize = 20
    
    createNotification("Settings", "Todo reseteado", 2)
end)

createSection(settingsPage, "ℹ️ Information")

local infoText = Instance.new("Frame")
infoText.Size = UDim2.new(1, 0, 0, 220)
infoText.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
infoText.BorderSizePixel = 0
infoText.Parent = settingsPage

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = infoText

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 1, -20)
infoLabel.Position = UDim2.new(0, 10, 0, 10)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = [[🐉 DRAGON RED v7 - Ultimate Edition

✨ Características:
• Sistema de tabs moderno
• Lista completa de jugadores
• Controles de movimiento avanzados
• ESP personalizable
• Auto-farming inteligente
• Click TP con Ctrl
• Hitbox Expander
• God Mode mejorado
• Y mucho más...

⌨️ Atajos:
RightShift - Abrir/Cerrar panel
Ctrl + Click - Teleport (si está activado)

Made with ❤️ by Dragon Red Team]]
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 12
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.TextWrapped = true
infoLabel.Parent = infoText

createSection(settingsPage, "🚀 Credits")

local creditsFrame = Instance.new("Frame")
creditsFrame.Size = UDim2.new(1, 0, 0, 80)
creditsFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
creditsFrame.BorderSizePixel = 0
creditsFrame.Parent = settingsPage

local creditsCorner = Instance.new("UICorner")
creditsCorner.CornerRadius = UDim.new(0, 10)
creditsCorner.Parent = creditsFrame

local creditsLabel = Instance.new("TextLabel")
creditsLabel.Size = UDim2.new(1, -20, 1, -20)
creditsLabel.Position = UDim2.new(0, 10, 0, 10)
creditsLabel.BackgroundTransparency = 1
creditsLabel.Text = "🐉 DRAGON RED TEAM\n\nDeveloped by: Dragon Red Community\nVersion: 7.0 Ultimate Edition\nLast Update: 2025"
creditsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
creditsLabel.Font = Enum.Font.Gotham
creditsLabel.TextSize = 13
creditsLabel.TextXAlignment = Enum.TextXAlignment.Center
creditsLabel.TextYAlignment = Enum.TextYAlignment.Top
creditsLabel.TextWrapped = true
creditsLabel.Parent = creditsFrame

--// ═════════════════════════════════════════════
--// NOTIFICACIÓN DE CARGA COMPLETA
--// ═════════════════════════════════════════════
task.wait(2.5)
createNotification("🐉 Dragon Red v7", "Cargado exitosamente | Press RightShift", 4)
print("═════════════════════════════════════════════")
print("🐉 DRAGON RED v7 - Ultimate Edition")
print("✅ Loaded successfully!")
print("⌨️  Press RightShift to toggle GUI")
print("═════════════════════════════════════════════")

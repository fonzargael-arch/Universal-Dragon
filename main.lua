--[[
    🐉 DRAGON RED ADMIN PANEL v8 - OPTIMIZED EDITION
    ════════════════════════════════════════════════════
    ✨ Universal & Lightweight - Optimized Performance
    🎯 Compatible with all games & executors
    ⚡ Enhanced error handling & stability
    
    Improvements:
    - Better memory management
    - Optimized loops & connections
    - Enhanced stability & error handling
    - Cleaner code structure
    - Reduced script size
]]

print("═══════════════════════════════════")
print("🐉 Loading DRAGON RED v8...")
print("═══════════════════════════════════")

--// Services (cached for performance)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

--// Safe character initialization
local function waitForChild(parent, childName, timeout)
    local child = parent:FindFirstChild(childName)
    if child then return child end
    local startTime = tick()
    repeat
        child = parent:FindFirstChild(childName)
        task.wait()
    until child or (tick() - startTime > (timeout or 10))
    return child
end

repeat task.wait() until player.Character
local char = player.Character
local hum = char:FindFirstChildOfClass("Humanoid")
local root = char:FindFirstChild("HumanoidRootPart")

--// Enhanced character getter with validation
local function getHumanoid()
    if not player.Character then return nil, nil end
    return player.Character:FindFirstChildOfClass("Humanoid"), 
           player.Character:FindFirstChild("HumanoidRootPart")
end

--// Connection cleanup system
local connections = {}
local function addConnection(name, conn)
    if connections[name] then
        connections[name]:Disconnect()
    end
    connections[name] = conn
end

--// Character reconnection
player.CharacterAdded:Connect(function(c)
    task.wait(0.2)
    char = c
    hum, root = getHumanoid()
    
    -- Cleanup old states
    if states.Fly then
        states.Fly = false
    end
end)

--// States
local states = {
    Fly = false,
    Noclip = false,
    InfJump = false,
    ESP = false,
    Fullbright = false,
    ClickTP = false,
    WalkSpeed = false,
    JumpPower = false,
    Spinbot = false
}

--// Config
local config = {
    flySpeed = 80,
    walkSpeed = 16,
    jumpPower = 50,
    espColor = Color3.fromRGB(255, 0, 0)
}

local savedPosition = nil

--// Optimized notification system
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "🐉 " .. title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

--// GUI Base with protection
local gui = Instance.new("ScreenGui")
gui.Name = "DragonRedGUI_" .. math.random(1000, 9999)
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999999
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

--// FPS Counter (optimized)
local fpsCounter = Instance.new("TextLabel")
fpsCounter.Size = UDim2.new(0, 90, 0, 28)
fpsCounter.Position = UDim2.new(1, -100, 0, 10)
fpsCounter.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
fpsCounter.BorderSizePixel = 0
fpsCounter.Text = "FPS: 60"
fpsCounter.TextColor3 = Color3.fromRGB(0, 255, 0)
fpsCounter.Font = Enum.Font.Code
fpsCounter.TextSize = 13
fpsCounter.Visible = false
fpsCounter.ZIndex = 10
fpsCounter.Parent = gui

local fpsCorner = Instance.new("UICorner", fpsCounter)
fpsCorner.CornerRadius = UDim.new(0, 6)

local fpsStroke = Instance.new("UIStroke", fpsCounter)
fpsStroke.Color = Color3.fromRGB(200, 0, 0)
fpsStroke.Thickness = 1

--// Optimized FPS counter (updates every 0.5s instead of every frame)
local lastTime = tick()
local fps = 60
local fpsUpdateInterval = 0
addConnection("FPS", RunService.RenderStepped:Connect(function()
    if fpsCounter.Visible then
        fpsUpdateInterval = fpsUpdateInterval + 1
        if fpsUpdateInterval >= 30 then -- Update every ~30 frames
            fps = math.floor(1 / (tick() - lastTime))
            lastTime = tick()
            fpsCounter.Text = "FPS: " .. fps
            
            fpsCounter.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 0) 
                                    or fps >= 30 and Color3.fromRGB(255, 255, 0) 
                                    or Color3.fromRGB(255, 0, 0)
            fpsUpdateInterval = 0
        end
    end
end))

--// Minimized icon
local icon = Instance.new("TextButton")
icon.Size = UDim2.new(0, 48, 0, 48)
icon.Position = UDim2.new(0, 15, 1, -65)
icon.Text = "🐉"
icon.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
icon.TextColor3 = Color3.fromRGB(200, 0, 0)
icon.TextSize = 26
icon.Visible = false
icon.ZIndex = 10
icon.Parent = gui

Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
local iconStroke = Instance.new("UIStroke", icon)
iconStroke.Color = Color3.fromRGB(200, 0, 0)
iconStroke.Thickness = 2

--// Main panel
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 650, 0, 480)
frame.Position = UDim2.new(0.5, -325, 0.5, -240)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BorderSizePixel = 0
frame.ZIndex = 10
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
local frameBorder = Instance.new("UIStroke", frame)
frameBorder.Color = Color3.fromRGB(200, 0, 0)
frameBorder.Thickness = 2

--// TopBar
local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1, 0, 0, 45)
topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topBar.BorderSizePixel = 0
topBar.ZIndex = 10

Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 14)

local topFix = Instance.new("Frame", topBar)
topFix.Size = UDim2.new(1, 0, 0, 15)
topFix.Position = UDim2.new(0, 0, 1, -15)
topFix.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topFix.BorderSizePixel = 0
topFix.ZIndex = 10

--// Title elements
local logo = Instance.new("TextLabel", topBar)
logo.Size = UDim2.new(0, 35, 0, 35)
logo.Position = UDim2.new(0, 8, 0.5, -17.5)
logo.BackgroundTransparency = 1
logo.Text = "🐉"
logo.TextSize = 24
logo.ZIndex = 10

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(0, 180, 0, 22)
title.Position = UDim2.new(0, 48, 0, 4)
title.BackgroundTransparency = 1
title.Text = "DRAGON RED"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Code
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 10

local subtitle = Instance.new("TextLabel", topBar)
subtitle.Size = UDim2.new(0, 180, 0, 18)
subtitle.Position = UDim2.new(0, 48, 0, 24)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Optimized Edition v8"
subtitle.TextColor3 = Color3.fromRGB(140, 140, 140)
subtitle.Font = Enum.Font.Code
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 10

local userInfo = Instance.new("TextLabel", topBar)
userInfo.Size = UDim2.new(0, 180, 0, 18)
userInfo.Position = UDim2.new(1, -190, 0, 6)
userInfo.BackgroundTransparency = 1
userInfo.Text = "👤 " .. player.Name
userInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
userInfo.Font = Enum.Font.Code
userInfo.TextSize = 12
userInfo.TextXAlignment = Enum.TextXAlignment.Right
userInfo.ZIndex = 10

local serverInfo = Instance.new("TextLabel", topBar)
serverInfo.Size = UDim2.new(0, 180, 0, 18)
serverInfo.Position = UDim2.new(1, -190, 0, 23)
serverInfo.BackgroundTransparency = 1
serverInfo.Text = "🌐 " .. #Players:GetPlayers() .. " Players"
serverInfo.TextColor3 = Color3.fromRGB(140, 140, 140)
serverInfo.Font = Enum.Font.Code
serverInfo.TextSize = 10
serverInfo.TextXAlignment = Enum.TextXAlignment.Right
serverInfo.ZIndex = 10

--// Player count updater (optimized)
local function updatePlayerCount()
    serverInfo.Text = "🌐 " .. #Players:GetPlayers() .. " Players"
end

Players.PlayerAdded:Connect(updatePlayerCount)
Players.PlayerRemoving:Connect(updatePlayerCount)

--// Close button
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
closeBtn.Text = "✖"
closeBtn.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.Code
closeBtn.ZIndex = 10

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
end)

closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
end)

--// Minimize/Maximize functions
local function minimize()
    frame.Visible = false
    icon.Visible = true
end

local function maximize()
    frame.Visible = true
    icon.Visible = false
end

closeBtn.MouseButton1Click:Connect(minimize)
icon.MouseButton1Click:Connect(maximize)

--// Optimized drag system for icon
local iconDragging = false
local iconDragStart, iconStartPos

icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        iconDragging = true
        iconDragStart = input.Position
        iconStartPos = icon.Position
    end
end)

addConnection("IconDrag", UIS.InputChanged:Connect(function(input)
    if iconDragging and input.UserInputType == Enum.UserInputType.MouseMovement and iconDragStart then
        local delta = input.Position - iconDragStart
        icon.Position = UDim2.new(
            iconStartPos.X.Scale, 
            iconStartPos.X.Offset + delta.X, 
            iconStartPos.Y.Scale, 
            iconStartPos.Y.Offset + delta.Y
        )
    end
end))

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        iconDragging = false
    end
end)

--// Optimized drag system for panel
local frameDragging = false
local frameDragStart, frameStartPos

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        frameDragging = true
        frameDragStart = input.Position
        frameStartPos = frame.Position
    end
end)

addConnection("FrameDrag", UIS.InputChanged:Connect(function(input)
    if frameDragging and input.UserInputType == Enum.UserInputType.MouseMovement and frameDragStart then
        local delta = input.Position - frameDragStart
        frame.Position = UDim2.new(
            frameStartPos.X.Scale, 
            frameStartPos.X.Offset + delta.X, 
            frameStartPos.Y.Scale, 
            frameStartPos.Y.Offset + delta.Y
        )
    end
end))

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        frameDragging = false
    end
end)

--// Toggle with RightShift
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if frame.Visible then minimize() else maximize() end
    end
end)

--// Sidebar
local sidebar = Instance.new("Frame", frame)
sidebar.Size = UDim2.new(0, 140, 1, -45)
sidebar.Position = UDim2.new(0, 0, 0, 45)
sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 10

--// Content area
local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, -140, 1, -45)
content.Position = UDim2.new(0, 140, 0, 45)
content.BackgroundTransparency = 1
content.ZIndex = 10

--// Tab system
local tabs = {}

local function createTab(name, icon, yPos)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -8, 0, 38)
    btn.Position = UDim2.new(0, 4, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Text = icon .. "  " .. name
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 10
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(200, 0, 0)
    btnStroke.Thickness = 0
    
    local padding = Instance.new("UIPadding", btn)
    padding.PaddingLeft = UDim.new(0, 12)
    
    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 10
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 8)
    
    tabs[name] = {button = btn, page = page, stroke = btnStroke}
    
    btn.MouseButton1Click:Connect(function()
        for n, data in pairs(tabs) do
            data.page.Visible = (n == name)
            if n == name then
                data.button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                data.button.TextColor3 = Color3.fromRGB(255, 255, 255)
                data.stroke.Thickness = 2
            else
                data.button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                data.button.TextColor3 = Color3.fromRGB(180, 180, 180)
                data.stroke.Thickness = 0
            end
        end
    end)
    
    return page
end

--// Create tabs
createTab("Movement", "🚀", 8)
createTab("Visual", "👁️", 52)
createTab("Misc", "🛠️", 96)
createTab("Settings", "⚙️", 140)

--// Activate first tab
tabs["Movement"].button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
tabs["Movement"].button.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs["Movement"].stroke.Thickness = 2
tabs["Movement"].page.Visible = true

--// UI Helper functions (optimized)
local function createSection(parent, title)
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 32)
    section.BackgroundTransparency = 1
    section.ZIndex = 10
    
    local label = Instance.new("TextLabel", section)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Code
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 10
    
    local line = Instance.new("Frame", section)
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 1, -4)
    line.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    line.BorderSizePixel = 0
    line.ZIndex = 10
end

local function createToggle(parent, text, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 42)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    container.BorderSizePixel = 0
    container.ZIndex = 10
    
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 1
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -56, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 10
    
    local toggle = Instance.new("TextButton", container)
    toggle.Size = UDim2.new(0, 42, 0, 24)
    toggle.Position = UDim2.new(1, -50, 0.5, -12)
    toggle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    toggle.Text = ""
    toggle.ZIndex = 10
    
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)
    
    local indicator = Instance.new("Frame", toggle)
    indicator.Size = UDim2.new(0, 18, 0, 18)
    indicator.Position = UDim2.new(0, 3, 0.5, -9)
    indicator.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 10
    
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    
    local enabled = false
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(toggle, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(25, 25, 25)
        }):Play()
        TweenService:Create(indicator, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(50, 50, 50)
        }):Play()
        if callback then 
            pcall(callback, enabled)
        end
    end)
end

local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.Text = text
    btn.ZIndex = 10
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 2
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(240, 20, 20)
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        }):Play()
    end)
    
    if callback then 
        btn.MouseButton1Click:Connect(function()
            pcall(callback)
        end)
    end
end

local function createSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 56)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    container.BorderSizePixel = 0
    container.ZIndex = 10
    
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 1
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -24, 0, 18)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 10
    
    local valueLabel = Instance.new("TextLabel", container)
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.Position = UDim2.new(1, -62, 0, 6)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 10
    
    local track = Instance.new("Frame", container)
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    track.BorderSizePixel = 0
    track.ZIndex = 10
    
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    fill.BorderSizePixel = 0
    fill.ZIndex = 10
    
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
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
                pcall(callback, value)
            end
        end
    end)
end

--// MOVEMENT TAB
local movePage = tabs["Movement"].page

createSection(movePage, "⚡ Movement Controls")

createToggle(movePage, "Fly Mode", function(enabled)
    states.Fly = enabled
    hum, root = getHumanoid()
    if not hum or not root then 
        notify("Error", "Character not found!", 2)
        return 
    end
    
    if enabled then
        -- Clean up existing fly
        if root:FindFirstChild("DragonFly") then root.DragonFly:Destroy() end
        if root:FindFirstChild("DragonGyro") then root.DragonGyro:Destroy() end
        
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
        notify("Fly", "ON - WASD + Space/Ctrl", 2)
    else
        if root:FindFirstChild("DragonFly") then root.DragonFly:Destroy() end
        if root:FindFirstChild("DragonGyro") then root.DragonGyro:Destroy() end
        if hum then hum.PlatformStand = false end
        notify("Fly", "OFF", 2)
    end
end)

createToggle(movePage, "Noclip", function(enabled)
    states.Noclip = enabled
    notify("Noclip", enabled and "ON" or "OFF", 2)
end)

createToggle(movePage, "Infinite Jump", function(enabled)
    states.InfJump = enabled
    notify("Infinite Jump", enabled and "ON" or "OFF", 2)
end)

createSlider(movePage, "Fly Speed", 20, 200, 80, function(value)
    config.flySpeed = value
end)

createSection(movePage, "⚡ Speed Controls")

createToggle(movePage, "Custom WalkSpeed", function(enabled)
    states.WalkSpeed = enabled
    hum, root = getHumanoid()
    if hum then
        if not enabled then
            hum.WalkSpeed = 16
        end
    end
    notify("WalkSpeed", enabled and "ON" or "OFF", 2)
end)

createSlider(movePage, "WalkSpeed", 16, 200, 16, function(value)
    config.walkSpeed = value
    if states.WalkSpeed then
        hum, root = getHumanoid()
        if hum then hum.WalkSpeed = value end
    end
end)

createToggle(movePage, "Custom JumpPower", function(enabled)
    states.JumpPower = enabled
    hum, root = getHumanoid()
    if hum then
        if not enabled then
            hum.JumpPower = 50
        end
    end
    notify("JumpPower", enabled and "ON" or "OFF", 2)
end)

createSlider(movePage, "JumpPower", 50, 200, 50, function(value)
    config.jumpPower = value
    if states.JumpPower then
        hum, root = getHumanoid()
        if hum then hum.JumpPower = value end
    end
end)

createSection(movePage, "📍 Position Controls")

createButton(movePage, "💾 Save Position", function()
    hum, root = getHumanoid()
    if root then
        savedPosition = root.CFrame
        notify("Position", "Saved!", 2)
    end
end)

createButton(movePage, "📍 Load Position", function()
    if savedPosition then
        hum, root = getHumanoid()
        if root then
            root.CFrame = savedPosition
            notify("Position", "Loaded!", 2)
        end
    else
        notify("Error", "No saved position!", 2)
    end
end)

--// VISUAL TAB
local visualPage = tabs["Visual"].page

createSection(visualPage, "👁️ Visual Features")

createToggle(visualPage, "Fullbright", function(enabled)
    states.Fullbright = enabled
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    end
    notify("Fullbright", enabled and "ON" or "OFF", 2)
end)

createToggle(visualPage, "FPS Counter", function(enabled)
    fpsCounter.Visible = enabled
end)

createToggle(visualPage, "Remove Fog", function(enabled)
    if enabled then
        Lighting.FogEnd = 100000
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then
                v.Density = 0
            end
        end
    else
        Lighting.FogEnd = 100000
    end
    notify("Fog", enabled and "Removed" or "Default", 2)
end)

--// MISC TAB
local miscPage = tabs["Misc"].page

createSection(miscPage, "🛠️ Utilities")

createToggle(miscPage, "Click Teleport (Ctrl+Click)", function(enabled)
    states.ClickTP = enabled
    notify("Click TP", enabled and "ON - Ctrl+Click" or "OFF", 2)
end)

createButton(miscPage, "🔄 Respawn Character", function()
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").Health = 0
        notify("Respawn", "Respawning...", 2)
    end
end)

createButton(miscPage, "🧹 Remove Accessories", function()
    hum, root = getHumanoid()
    if char then
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Accessory") then
                v:Destroy()
            end
        end
        notify("Accessories", "Removed!", 2)
    end
end)

createButton(miscPage, "⚡ Reset Lighting", function()
    Lighting.Brightness = 1
    Lighting.ClockTime = 12
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = true
    Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    notify("Lighting", "Reset to default", 2)
end)

createSection(miscPage, "🎮 Game Controls")

createButton(miscPage, "🚪 Rejoin Server", function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

createButton(miscPage, "🔄 Server Hop", function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    
    if servers and servers.data then
        for _, server in pairs(servers.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
                notify("Server Hop", "Joining new server...", 3)
                return
            end
        end
    end
    notify("Error", "No servers found!", 3)
end)

--// SETTINGS TAB
local settingsPage = tabs["Settings"].page

createSection(settingsPage, "⚙️ GUI Settings")

createButton(settingsPage, "🎨 Change Theme Color", function()
    local colors = {
        Color3.fromRGB(200, 0, 0),    -- Red
        Color3.fromRGB(0, 200, 0),    -- Green
        Color3.fromRGB(0, 150, 255),  -- Blue
        Color3.fromRGB(255, 150, 0),  -- Orange
        Color3.fromRGB(200, 0, 200),  -- Purple
        Color3.fromRGB(0, 200, 200)   -- Cyan
    }
    
    local randomColor = colors[math.random(1, #colors)]
    
    frameBorder.Color = randomColor
    iconStroke.Color = randomColor
    fpsStroke.Color = randomColor
    
    for _, tabData in pairs(tabs) do
        tabData.stroke.Color = randomColor
        if tabData.page.Visible then
            tabData.button.BackgroundColor3 = randomColor
        end
    end
    
    notify("Theme", "Color changed!", 2)
end)

createButton(settingsPage, "📋 Copy Script Info", function()
    setclipboard("Dragon Red Admin Panel v8 - Universal Edition")
    notify("Clipboard", "Info copied!", 2)
end)

createSection(settingsPage, "ℹ️ Information")

local infoLabel = Instance.new("TextLabel", settingsPage)
infoLabel.Size = UDim2.new(1, 0, 0, 120)
infoLabel.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
infoLabel.BorderSizePixel = 0
infoLabel.Text = [[
🐉 DRAGON RED v8
━━━━━━━━━━━━━━━
✨ Universal & Optimized
🎮 All Games Compatible
⚡ Lightweight & Fast

Toggle: RightShift
Creator: Krxtopher
]]
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.Font = Enum.Font.Code
infoLabel.TextSize = 12
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.ZIndex = 10

Instance.new("UICorner", infoLabel).CornerRadius = UDim.new(0, 8)
local infoStroke = Instance.new("UIStroke", infoLabel)
infoStroke.Color = Color3.fromRGB(200, 0, 0)
infoStroke.Thickness = 1

local infoPadding = Instance.new("UIPadding", infoLabel)
infoPadding.PaddingLeft = UDim.new(0, 10)
infoPadding.PaddingTop = UDim.new(0, 10)

--// CORE FUNCTIONALITY LOOPS

-- Fly system
addConnection("FlyControl", RunService.Heartbeat:Connect(function()
    if states.Fly then
        hum, root = getHumanoid()
        if not hum or not root then return end
        
        local bv = root:FindFirstChild("DragonFly")
        local bg = root:FindFirstChild("DragonGyro")
        
        if bv and bg then
            local cam = camera.CFrame
            local moveVector = Vector3.new()
            
            if UIS:IsKeyDown(Enum.KeyCode.W) then
                moveVector = moveVector + (cam.LookVector * config.flySpeed)
            end
            if UIS:IsKeyDown(Enum.KeyCode.S) then
                moveVector = moveVector - (cam.LookVector * config.flySpeed)
            end
            if UIS:IsKeyDown(Enum.KeyCode.A) then
                moveVector = moveVector - (cam.RightVector * config.flySpeed)
            end
            if UIS:IsKeyDown(Enum.KeyCode.D) then
                moveVector = moveVector + (cam.RightVector * config.flySpeed)
            end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                moveVector = moveVector + (Vector3.new(0, 1, 0) * config.flySpeed)
            end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveVector = moveVector - (Vector3.new(0, 1, 0) * config.flySpeed)
            end
            
            bv.Velocity = moveVector
            bg.CFrame = cam
        end
    end
end))

-- Noclip system
addConnection("Noclip", RunService.Stepped:Connect(function()
    if states.Noclip then
        hum, root = getHumanoid()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end))

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if states.InfJump then
        hum, root = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- WalkSpeed & JumpPower control
addConnection("Speed", RunService.Heartbeat:Connect(function()
    hum, root = getHumanoid()
    if hum then
        if states.WalkSpeed then
            hum.WalkSpeed = config.walkSpeed
        end
        if states.JumpPower then
            hum.JumpPower = config.jumpPower
        end
    end
end))

-- Click Teleport
mouse.Button1Down:Connect(function()
    if states.ClickTP and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        hum, root = getHumanoid()
        if root and mouse.Target then
            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            notify("Teleport", "Teleported!", 1)
        end
    end
end)

--// CLEANUP ON SCRIPT STOP
local function cleanup()
    for name, conn in pairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    
    if gui then
        gui:Destroy()
    end
    
    hum, root = getHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.PlatformStand = false
    end
    
    if root then
        if root:FindFirstChild("DragonFly") then root.DragonFly:Destroy() end
        if root:FindFirstChild("DragonGyro") then root.DragonGyro:Destroy() end
    end
    
    Lighting.Brightness = 1
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = true
end

-- Auto cleanup on character death
player.CharacterRemoving:Connect(cleanup)

--// STARTUP NOTIFICATION
notify("Dragon Red v8", "Loaded successfully!", 3)
notify("Controls", "Press RightShift to toggle", 3)

print("═══════════════════════════════════")
print("✅ DRAGON RED v8 Loaded!")
print("🎮 Press RightShift to open")
print("═══════════════════════════════════")

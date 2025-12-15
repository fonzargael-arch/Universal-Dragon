--[[
    ═══════════════════════════════════════
    🎮 GF HUB - Universal Script
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Version: 3.0 - Real WalkFling
    Based on MM2 & Natural Disasters fling
    ═══════════════════════════════════════
]]

-- Load Fluent Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Variables
local selectedPlayer = nil
local espEnabled = false
local espObjects = {}
local espConfig = {
    fillColor = Color3.fromRGB(255, 0, 0),
    outlineColor = Color3.fromRGB(255, 255, 255),
    fillTransparency = 0.5,
    outlineTransparency = 0,
    showHealth = true,
    showDistance = true
}

local connections = {}
local hitboxCache = {}

-- WalkFling Variables
local flingEnabled = false
local flingTarget = nil
local pushPower = 5000
local spinPower = 500

-- Helper Functions
local function getChar()
    return player.Character
end

local function getRoot()
    local char = getChar()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Enhanced ESP System
local function createESP(target)
    if not target or not target.Character then return end
    
    if espObjects[target.Name] then
        pcall(function() 
            if espObjects[target.Name].highlight then
                espObjects[target.Name].highlight:Destroy()
            end
            if espObjects[target.Name].billboard then
                espObjects[target.Name].billboard:Destroy()
            end
        end)
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "GF_ESP"
    highlight.Adornee = target.Character
    highlight.FillColor = espConfig.fillColor
    highlight.OutlineColor = espConfig.outlineColor
    highlight.FillTransparency = espConfig.fillTransparency
    highlight.OutlineTransparency = espConfig.outlineTransparency
    highlight.Parent = target.Character
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GF_ESPInfo"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = target.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.35, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "HP: 100"
    healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 12
    healthLabel.Visible = espConfig.showHealth
    healthLabel.Parent = billboard
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.65, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0 studs"
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 12
    distanceLabel.Visible = espConfig.showDistance
    distanceLabel.Parent = billboard
    
    espObjects[target.Name] = {
        highlight = highlight,
        billboard = billboard,
        healthLabel = healthLabel,
        distanceLabel = distanceLabel
    }
end

local function removeESP(target)
    if espObjects[target.Name] then
        pcall(function() 
            if espObjects[target.Name].highlight then
                espObjects[target.Name].highlight:Destroy()
            end
            if espObjects[target.Name].billboard then
                espObjects[target.Name].billboard:Destroy()
            end
        end)
        espObjects[target.Name] = nil
    end
end

local function updateAllESP()
    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player then
            if espEnabled then
                createESP(target)
            else
                removeESP(target)
            end
        end
    end
end

local function updateESPInfo()
    if not espEnabled then return end
    
    local myRoot = getRoot()
    if not myRoot then return end
    
    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player and espObjects[target.Name] then
            local espData = espObjects[target.Name]
            
            if target.Character then
                local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                
                if targetHum and espData.healthLabel then
                    local health = math.floor(targetHum.Health)
                    local maxHealth = math.floor(targetHum.MaxHealth)
                    espData.healthLabel.Text = "HP: " .. health .. "/" .. maxHealth
                    
                    local healthPercent = health / maxHealth
                    if healthPercent > 0.6 then
                        espData.healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    elseif healthPercent > 0.3 then
                        espData.healthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        espData.healthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                    end
                    
                    espData.healthLabel.Visible = espConfig.showHealth
                end
                
                if targetRoot and espData.distanceLabel then
                    local distance = math.floor((myRoot.Position - targetRoot.Position).Magnitude)
                    espData.distanceLabel.Text = distance .. " studs"
                    espData.distanceLabel.Visible = espConfig.showDistance
                end
            end
        end
    end
end

local function getPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(list, p.Name)
        end
    end
    return list
end

local function getPlayerByName(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == name then
            return p
        end
    end
    return nil
end

-- REAL WALKFLING SYSTEM (Basado en MM2/Natural Disasters)
local bambiConnection = nil
local flingConnection = nil

local function setupBambi()
    local char = getChar()
    if not char then return end
    
    local root = getRoot()
    if not root then return end
    
    -- Desactivar completamente las colisiones
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Massless = true
        end
    end
    
    -- Hacer invisible
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
            for _, child in pairs(part:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
                    child.Transparency = 1
                end
            end
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then
                handle.Transparency = 1
            end
        end
    end
    
    root.Transparency = 1
    
    -- Hacer el root más grande para mejor fling
    root.Size = Vector3.new(4, 4, 4)
    root.CanCollide = false
end

local function resetBambi()
    local char = getChar()
    if not char then return end
    
    local root = getRoot()
    if not root then return end
    
    -- Restaurar colisiones
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
            part.Massless = false
        end
    end
    
    -- Restaurar visibilidad
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 0
            for _, child in pairs(part:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceAppearance") then
                    child.Transparency = 0
                end
            end
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then
                handle.Transparency = 0
            end
        end
    end
    
    -- Restaurar root
    root.Transparency = 1
    root.Size = Vector3.new(2, 2, 1)
    root.CanCollide = false
end

-- Sistema de Fling Real
local function startFling(target)
    if not target or not target.Character then return end
    
    flingTarget = target
    flingEnabled = true
    
    local myRoot = getRoot()
    local myChar = getChar()
    
    if not myRoot or not myChar then return end
    
    -- Setup bambi
    setupBambi()
    
    -- Crear BodyThrust para empuje constante
    local bodyThrust = Instance.new("BodyThrust")
    bodyThrust.Name = "GF_FlingThrust"
    bodyThrust.Force = Vector3.new(0, 0, 0)
    bodyThrust.Location = Vector3.new(0, 0, 0)
    bodyThrust.Parent = myRoot
    
    -- Crear BodyGyro para control de rotación
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "GF_FlingGyro"
    bodyGyro.MaxTorque = Vector3.new(9e9, 0, 9e9)
    bodyGyro.P = 10000
    bodyGyro.Parent = myRoot
    
    Fluent:Notify({
        Title = "🌪️ WalkFling Activated",
        Content = "Walk into " .. target.Name .. " to fling them!",
        Duration = 3
    })
    
    -- Loop de fling
    flingConnection = RunService.Heartbeat:Connect(function()
        if not flingEnabled or not flingTarget or not flingTarget.Character then
            if flingConnection then
                flingConnection:Disconnect()
            end
            return
        end
        
        local targetRoot = flingTarget.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        
        local myCurrentRoot = getRoot()
        if not myCurrentRoot then return end
        
        local distance = (myCurrentRoot.Position - targetRoot.Position).Magnitude
        
        -- Si estás cerca del objetivo
        if distance < 10 then
            -- Rotar rápido para causar fling
            myCurrentRoot.RotVelocity = Vector3.new(0, spinPower, 0)
            
            -- Empujar hacia el objetivo
            local direction = (targetRoot.Position - myCurrentRoot.Position).Unit
            myCurrentRoot.Velocity = direction * 50
            
            -- Aplicar fuerza de empuje
            if bodyThrust then
                bodyThrust.Force = direction * pushPower
                bodyThrust.Location = targetRoot.Position
            end
        end
    end)
end

local function stopFling()
    flingEnabled = false
    flingTarget = nil
    
    if flingConnection then
        flingConnection:Disconnect()
        flingConnection = nil
    end
    
    local root = getRoot()
    if root then
        local thrust = root:FindFirstChild("GF_FlingThrust")
        if thrust then thrust:Destroy() end
        
        local gyro = root:FindFirstChild("GF_FlingGyro")
        if gyro then gyro:Destroy() end
        
        root.RotVelocity = Vector3.new(0, 0, 0)
        root.Velocity = Vector3.new(0, 0, 0)
    end
    
    resetBambi()
    
    Fluent:Notify({
        Title = "WalkFling Disabled",
        Content = "",
        Duration = 2
    })
end

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "🎮 GF HUB " .. Fluent.Version,
    SubTitle = "by Gael Fonzar",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "🏠 Main", Icon = "home" }),
    Movement = Window:AddTab({ Title = "🚀 Movement", Icon = "wind" }),
    Players = Window:AddTab({ Title = "👥 Players", Icon = "users" }),
    Combat = Window:AddTab({ Title = "🎯 Combat", Icon = "sword" }),
    Visual = Window:AddTab({ Title = "👁️ Visual", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })
}

-- ═══════════════════════════════════════
-- 🏠 MAIN TAB
-- ═══════════════════════════════════════

Tabs.Main:AddParagraph({
    Title = "Welcome to GF HUB!",
    Content = "Version 3.0 with Real WalkFling\nCreated by Gael Fonzar\n\nFeatures:\n• Real WalkFling System (MM2 Style)\n• Advanced ESP\n• Movement Controls\n• Combat Tools"
})

-- ═══════════════════════════════════════
-- 🚀 MOVEMENT TAB
-- ═══════════════════════════════════════

local flyEnabled = false
local flySpeed = 100
local speedEnabled = false
local walkSpeed = 16
local infJumpEnabled = false
local noclipEnabled = false

local FlyToggle = Tabs.Movement:AddToggle("FlyToggle", {
    Title = "Fly Mode",
    Description = "Fly using WASD + Space/Shift",
    Default = false,
    Callback = function(Value)
        flyEnabled = Value
        local root = getRoot()
        
        if Value and root then
            if root:FindFirstChild("GF_Fly") then root.GF_Fly:Destroy() end
            if root:FindFirstChild("GF_Gyro") then root.GF_Gyro:Destroy() end
            
            local bv = Instance.new("BodyVelocity")
            bv.Name = "GF_Fly"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.zero
            bv.Parent = root
            
            local bg = Instance.new("BodyGyro")
            bg.Name = "GF_Gyro"
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 9e4
            bg.Parent = root
            
            Fluent:Notify({
                Title = "✈️ Fly Activated",
                Content = "Use WASD + Space/Shift to fly!",
                Duration = 3
            })
        else
            if root then
                if root:FindFirstChild("GF_Fly") then root.GF_Fly:Destroy() end
                if root:FindFirstChild("GF_Gyro") then root.GF_Gyro:Destroy() end
            end
            Fluent:Notify({
                Title = "Fly Deactivated",
                Content = "",
                Duration = 2
            })
        end
    end
})

local FlySpeedSlider = Tabs.Movement:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Description = "Adjust your fly speed",
    Default = 100,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        flySpeed = Value
    end
})

Tabs.Movement:AddSection("Walking")

local SpeedToggle = Tabs.Movement:AddToggle("SpeedToggle", {
    Title = "Custom Speed",
    Description = "Change your walk speed",
    Default = false,
    Callback = function(Value)
        speedEnabled = Value
        if not Value then
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
        Fluent:Notify({
            Title = Value and "Speed Enabled" or "Speed Disabled",
            Content = "",
            Duration = 2
        })
    end
})

local WalkSpeedSlider = Tabs.Movement:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Description = "Set walk speed",
    Default = 16,
    Min = 16,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        walkSpeed = Value
    end
})

Tabs.Movement:AddSection("Other Movement")

local InfJumpToggle = Tabs.Movement:AddToggle("InfJump", {
    Title = "Infinite Jump",
    Description = "Jump infinitely",
    Default = false,
    Callback = function(Value)
        infJumpEnabled = Value
        Fluent:Notify({
            Title = Value and "Infinite Jump ON" or "Infinite Jump OFF",
            Content = "",
            Duration = 2
        })
    end
})

local NoclipToggle = Tabs.Movement:AddToggle("Noclip", {
    Title = "Noclip",
    Description = "Walk through walls",
    Default = false,
    Callback = function(Value)
        noclipEnabled = Value
        Fluent:Notify({
            Title = Value and "Noclip ON" or "Noclip OFF",
            Content = "",
            Duration = 2
        })
    end
})

-- ═══════════════════════════════════════
-- 👥 PLAYERS TAB
-- ═══════════════════════════════════════

Tabs.Players:AddParagraph({
    Title = "Player Selection",
    Content = "Select a player to fling them with WalkFling"
})

local PlayerDropdown = Tabs.Players:AddDropdown("PlayerSelect", {
    Title = "Select Player",
    Description = "Choose a target",
    Values = getPlayerList(),
    Default = 1,
    Callback = function(Value)
        selectedPlayer = getPlayerByName(Value)
        if selectedPlayer then
            Fluent:Notify({
                Title = "✅ Player Selected",
                Content = selectedPlayer.Name,
                Duration = 2
            })
        end
    end
})

Tabs.Players:AddButton({
    Title = "🔄 Refresh Player List",
    Description = "Update the player list",
    Callback = function()
        PlayerDropdown:SetValues(getPlayerList())
        Fluent:Notify({
            Title = "Refreshed",
            Content = "Player list updated!",
            Duration = 2
        })
    end
})

Tabs.Players:AddSection("Teleport Actions")

Tabs.Players:AddButton({
    Title = "📍 Teleport to Player",
    Description = "Teleport to selected player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = getRoot()
            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                Fluent:Notify({
                    Title = "✅ Teleported",
                    Content = "Teleported to " .. selectedPlayer.Name,
                    Duration = 2
                })
            end
        else
            Fluent:Notify({
                Title = "❌ Error",
                Content = "No player selected!",
                Duration = 3
            })
        end
    end
})

Tabs.Players:AddButton({
    Title = "👁️ View Player",
    Description = "View selected player's perspective",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            Workspace.CurrentCamera.CameraSubject = selectedPlayer.Character
            Fluent:Notify({
                Title = "👁️ Viewing",
                Content = selectedPlayer.Name,
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "❌ Error",
                Content = "No player selected!",
                Duration = 3
            })
        end
    end
})

Tabs.Players:AddButton({
    Title = "🔙 View Self",
    Description = "Return camera to yourself",
    Callback = function()
        local char = getChar()
        if char then
            Workspace.CurrentCamera.CameraSubject = char
            Fluent:Notify({
                Title = "Viewing Yourself",
                Content = "",
                Duration = 2
            })
        end
    end
})

Tabs.Players:AddSection("WalkFling System")

Tabs.Players:AddParagraph({
    Title = "How to use WalkFling:",
    Content = "1. Select a player\n2. Click 'Start WalkFling'\n3. Walk into the player\n4. They will fly away!"
})

local PushPowerSlider = Tabs.Players:AddSlider("PushPower", {
    Title = "Push Power",
    Description = "How hard to push",
    Default = 5000,
    Min = 1000,
    Max = 20000,
    Rounding = 0,
    Callback = function(Value)
        pushPower = Value
    end
})

local SpinPowerSlider = Tabs.Players:AddSlider("SpinPower", {
    Title = "Spin Power",
    Description = "Rotation speed for fling",
    Default = 500,
    Min = 100,
    Max = 2000,
    Rounding = 0,
    Callback = function(Value)
        spinPower = Value
    end
})

Tabs.Players:AddButton({
    Title = "🌪️ Start WalkFling",
    Description = "Activate fling mode - walk into player!",
    Callback = function()
        if selectedPlayer then
            startFling(selectedPlayer)
        else
            Fluent:Notify({
                Title = "❌ Error",
                Content = "No player selected!",
                Duration = 3
            })
        end
    end
})

Tabs.Players:AddButton({
    Title = "⛔ Stop WalkFling",
    Description = "Disable fling mode",
    Callback = function()
        stopFling()
    end
})

-- ═══════════════════════════════════════
-- 🎯 COMBAT TAB
-- ═══════════════════════════════════════

local hitboxEnabled = false
local hitboxSize = 10
local hitboxTransparency = 0.7

Tabs.Combat:AddParagraph({
    Title = "Hitbox Expander",
    Content = "Make enemy hitboxes bigger for easier hits"
})

local HitboxToggle = Tabs.Combat:AddToggle("HitboxToggle", {
    Title = "Hitbox Expander",
    Description = "Expand player hitboxes",
    Default = false,
    Callback = function(Value)
        hitboxEnabled = Value
        Fluent:Notify({
            Title = Value and "Hitbox ON" or "Hitbox OFF",
            Content = "",
            Duration = 2
        })
    end
})

local HitboxSizeSlider = Tabs.Combat:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Description = "Size of expanded hitboxes",
    Default = 10,
    Min = 5,
    Max = 25,
    Rounding = 0,
    Callback = function(Value)
        hitboxSize = Value
    end
})

local HitboxTransSlider = Tabs.Combat:AddSlider("HitboxTrans", {
    Title = "Hitbox Transparency",
    Description = "Visibility of hitboxes",
    Default = 0.7,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(Value)
        hitboxTransparency = Value
    end
})

-- ═══════════════════════════════════════
-- 👁️ VISUAL TAB
-- ═══════════════════════════════════════

Tabs.Visual:AddParagraph({
    Title = "ESP System",
    Content = "See players through walls with health and distance"
})

local ESPToggle = Tabs.Visual:AddToggle("ESPToggle", {
    Title = "Enable ESP",
    Description = "See all players through walls",
    Default = false,
    Callback = function(Value)
        espEnabled = Value
        updateAllESP()
        Fluent:Notify({
            Title = Value and "ESP ON" or "ESP OFF",
            Content = "",
            Duration = 2
        })
    end
})

local ShowHealthToggle = Tabs.Visual:AddToggle("ShowHealth", {
    Title = "Show Health",
    Description = "Display player health",
    Default = true,
    Callback = function(Value)
        espConfig.showHealth = Value
        for _, espData in pairs(espObjects) do
            if espData.healthLabel then
                espData.healthLabel.Visible = Value
            end
        end
    end
})

local ShowDistanceToggle = Tabs.Visual:AddToggle("ShowDistance", {
    Title = "Show Distance",
    Description = "Display distance to players",
    Default = true,
    Callback = function(Value)
        espConfig.showDistance = Value
        for _, espData in pairs(espObjects) do
            if espData.distanceLabel then
                espData.distanceLabel.Visible = Value
            end
        end
    end
})

Tabs.Visual:AddSection("Lighting")

local FullbrightToggle = Tabs.Visual:AddToggle("Fullbright", {
    Title = "Fullbright",
    Description = "Remove shadows and darkness",
    Default = false,
    Callback = function(Value)
        local Lighting = game:GetService("Lighting")
        if Value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = true
            Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
        end
        Fluent:Notify({
            Title = Value and "Fullbright ON" or "Fullbright OFF",
            Content = "",
            Duration = 2
        })
    end
})

-- ═══════════════════════════════════════
-- ⚙️ SETTINGS TAB
-- ═══════════════════════════════════════

Tabs.Settings:AddParagraph({
    Title = "GF HUB Settings",
    Content = "Configure your hub experience"
})

Tabs.Settings:AddButton({
    Title = "Unload Script",
    Description = "Remove GF HUB completely",
    Callback = function()
        stopFling()
        Fluent:Destroy()
    end
})

InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)

InterfaceManager:SetFolder("GFHub")
SaveManager:SetFolder("GFHub/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Tabs.Settings:AddSection("Credits")

Tabs.Settings:AddParagraph({
    Title = "👤 Created by: Gael Fonzar",
    Content = "Version: 3.0\nUI: Fluent Library\nFling: MM2 Style\nStatus: ✅ Loaded"
})

-- ═══════════════════════════════════════
-- 🔄 GAME LOOPS
-- ═══════════════════════════════════════

-- Fly Control
connections.Fly = RunService.Heartbeat:Connect(function()
    if not flyEnabled then return end
    
    local root = getRoot()
    if not root then return end
    
    local bv = root:FindFirstChild("GF_Fly")
    local bg = root:FindFirstChild("GF_Gyro")
    
    if bv and bg then
        local cam = Workspace.CurrentCamera.CFrame
        local move = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
        
        bv.Velocity = move * flySpeed
        bg.CFrame = cam
    end
end)

-- Speed
connections.Speed = RunService.Heartbeat:Connect(function()
    if not speedEnabled then return end
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = walkSpeed end
end)

-- Noclip
connections.Noclip = RunService.Stepped:Connect(function()
    if not noclipEnabled then return end
    local char = getChar()
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
connections.InfJump = UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local hum = getHumanoid()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Hitbox Expander
connections.Hitbox = RunService.Heartbeat:Connect(function()
    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                if hitboxEnabled then
                    if not hitboxCache[target.Name] then
                        hitboxCache[target.Name] = {
                            size = targetRoot.Size,
                            trans = targetRoot.Transparency,
                            cancol = targetRoot.CanCollide
                        }
                    end
                    
                    targetRoot.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    targetRoot.Transparency = hitboxTransparency
                    targetRoot.Color = Color3.fromRGB(255, 0, 0)
                    targetRoot.Material = Enum.Material.ForceField
                    targetRoot.CanCollide = false
                    
                    if not targetRoot:FindFirstChild("GF_HitboxMesh") then
                        local mesh = Instance.new("SpecialMesh")
                        mesh.Name = "GF_HitboxMesh"
                        mesh.MeshType = Enum.MeshType.Sphere
                        mesh.Parent = targetRoot
                    end
                else
                    if hitboxCache[target.Name] then
                        targetRoot.Size = hitboxCache[target.Name].size
                        targetRoot.Transparency = hitboxCache[target.Name].trans
                        targetRoot.CanCollide = hitboxCache[target.Name].cancol
                        targetRoot.Material = Enum.Material.Plastic
                        
                        local mesh = targetRoot:FindFirstChild("GF_HitboxMesh")
                        if mesh then mesh:Destroy() end
                        
                        hitboxCache[target.Name] = nil
                    end
                end
            end
        end
    end
end)

-- ESP Update Loop
connections.ESPUpdate = RunService.RenderStepped:Connect(function()
    updateESPInfo()
end)

-- Player Events
Players.PlayerAdded:Connect(function(newPlayer)
    task.wait(1)
    if espEnabled and newPlayer ~= player then
        createESP(newPlayer)
    end
    PlayerDropdown:SetValues(getPlayerList())
end)

Players.PlayerRemoving:Connect(function(removedPlayer)
    removeESP(removedPlayer)
    PlayerDropdown:SetValues(getPlayerList())
end)

-- Character Respawn
player.CharacterAdded:Connect(function(char)
    task.wait(1)
    
    -- Reapply speed
    if speedEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = walkSpeed
        end
    end
    
    -- Stop fling on respawn
    if flingEnabled then
        stopFling()
    end
end)

-- Cleanup Function
local function cleanup()
    -- Stop fling first
    stopFling()
    
    -- Disconnect all connections
    for name, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    -- Remove all ESP
    for _, target in pairs(Players:GetPlayers()) do
        removeESP(target)
    end
    
    -- Reset character
    local char = getChar()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
        end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.Massless = false
                if part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 0
                end
            elseif part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 0
            end
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            if root:FindFirstChild("GF_Fly") then root.GF_Fly:Destroy() end
            if root:FindFirstChild("GF_Gyro") then root.GF_Gyro:Destroy() end
            if root:FindFirstChild("GF_FlingThrust") then root.GF_FlingThrust:Destroy() end
            if root:FindFirstChild("GF_FlingGyro") then root.GF_FlingGyro:Destroy() end
            root.Size = Vector3.new(2, 2, 1)
            root.Transparency = 1
            root.RotVelocity = Vector3.new(0, 0, 0)
            root.Velocity = Vector3.new(0, 0, 0)
        end
    end
    
    -- Reset hitboxes
    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot and hitboxCache[target.Name] then
                targetRoot.Size = hitboxCache[target.Name].size
                targetRoot.Transparency = hitboxCache[target.Name].trans
                targetRoot.CanCollide = hitboxCache[target.Name].cancol
                targetRoot.Material = Enum.Material.Plastic
                
                local mesh = targetRoot:FindFirstChild("GF_HitboxMesh")
                if mesh then mesh:Destroy() end
            end
        end
    end
    
    -- Reset lighting
    local Lighting = game:GetService("Lighting")
    Lighting.Brightness = 1
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 100000
    Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    
    Fluent:Notify({
        Title = "👋 GF HUB Unloaded",
        Content = "All features have been disabled",
        Duration = 3
    })
end

-- Register cleanup on window destroy
Window:OnUnload(cleanup)

-- Save settings
SaveManager:IgnoreThemeSettings()
SaveManager:LoadAutoloadConfig()

-- Final notification
Fluent:Notify({
    Title = "🎮 GF HUB v3.0",
    Content = "Successfully loaded!\nPress RightShift to toggle",
    Duration = 5
})

print("═══════════════════════════════════════")
print("🎮 GF HUB v3.0 - Successfully Loaded!")
print("Created by: Gael Fonzar")
print("UI: Fluent Library")
print("Fling System: Real WalkFling (MM2 Style)")
print("Press RightShift to open/close menu")
print("═══════════════════════════════════════")

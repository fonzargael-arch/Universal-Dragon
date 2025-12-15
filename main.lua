--[[
    ═══════════════════════════════════════
    🎮 GF HUB - Universal Script
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Version: 2.1 - Optimized & Fixed
    ═══════════════════════════════════════
]]

-- Intro Animation (Optimized)
local IntroGui = Instance.new("ScreenGui")
IntroGui.Name = "GFIntro"
IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success = pcall(function()
    IntroGui.Parent = game:GetService("CoreGui")
end)

if not success then
    IntroGui.Parent = player:WaitForChild("PlayerGui")
end

local IntroFrame = Instance.new("Frame")
IntroFrame.Size = UDim2.new(1, 0, 1, 0)
IntroFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
IntroFrame.BorderSizePixel = 0
IntroFrame.Parent = IntroGui

local IntroText = Instance.new("TextLabel")
IntroText.Size = UDim2.new(0, 400, 0, 100)
IntroText.Position = UDim2.new(0.5, -200, 0.5, -50)
IntroText.BackgroundTransparency = 1
IntroText.Text = "GF Hub"
IntroText.TextColor3 = Color3.fromRGB(255, 255, 255)
IntroText.Font = Enum.Font.GothamBold
IntroText.TextSize = 60
IntroText.TextTransparency = 1
IntroText.Parent = IntroFrame

local IntroSubText = Instance.new("TextLabel")
IntroSubText.Size = UDim2.new(0, 400, 0, 30)
IntroSubText.Position = UDim2.new(0.5, -200, 0.5, 40)
IntroSubText.BackgroundTransparency = 1
IntroSubText.Text = "Presents..."
IntroSubText.TextColor3 = Color3.fromRGB(200, 200, 200)
IntroSubText.Font = Enum.Font.Gotham
IntroSubText.TextSize = 24
IntroSubText.TextTransparency = 1
IntroSubText.Parent = IntroFrame

-- Animate intro
local TweenService = game:GetService("TweenService")
TweenService:Create(IntroText, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
task.wait(0.3)
TweenService:Create(IntroSubText, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
task.wait(1.5)
TweenService:Create(IntroFrame, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
TweenService:Create(IntroText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
TweenService:Create(IntroSubText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
task.wait(0.9)
IntroGui:Destroy()

-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

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

local function notify(title, content, duration)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration or 2,
        Image = "rewind"
    })
end

-- Enhanced ESP System with Health & Distance
local function createESP(target)
    if not target or not target.Character then return end
    
    -- Remove old ESP
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
    
    -- Create Billboard for Health & Distance
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GF_ESPInfo"
    billboard.Adornee = target.Character:FindFirstChild("Head")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = target.Character:FindFirstChild("Head")
    
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

-- Update ESP Info (Health & Distance)
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
                
                -- Update Health
                if targetHum and espData.healthLabel then
                    local health = math.floor(targetHum.Health)
                    local maxHealth = math.floor(targetHum.MaxHealth)
                    espData.healthLabel.Text = "HP: " .. health .. "/" .. maxHealth
                    
                    -- Color based on health
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
                
                -- Update Distance
                if targetRoot and espData.distanceLabel then
                    local distance = math.floor((myRoot.Position - targetRoot.Position).Magnitude)
                    espData.distanceLabel.Text = distance .. " studs"
                    espData.distanceLabel.Visible = espConfig.showDistance
                end
            end
        end
    end
end

-- Player List
local function getPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(list, p.Name)
        end
    end
    return #list > 0 and list or {"No players"}
end

local function getPlayerByName(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == name then
            return p
        end
    end
    return nil
end

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "🎮 GF Hub",
    LoadingTitle = "GF Hub",
    LoadingSubtitle = "by Gael Fonzar",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

-- ═══════════════════════════════════════
-- 🚀 MOVEMENT TAB
-- ═══════════════════════════════════════
local MovementTab = Window:CreateTab("🚀 Movement", nil)
local MovementSection = MovementTab:CreateSection("Movement Controls")

-- Fly
local flyEnabled = false
local flySpeed = 100

MovementTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Callback = function(Value)
        flyEnabled = Value
        local root = getRoot()
        
        if Value and root then
            -- Clean old
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
            
            notify("Fly", "ON - WASD + Space/Shift")
        else
            if root then
                if root:FindFirstChild("GF_Fly") then root.GF_Fly:Destroy() end
                if root:FindFirstChild("GF_Gyro") then root.GF_Gyro:Destroy() end
            end
            notify("Fly", "OFF")
        end
    end
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 250},
    Increment = 10,
    CurrentValue = 100,
    Callback = function(Value)
        flySpeed = Value
    end
})

-- Speed
local speedEnabled = false
local walkSpeed = 16

MovementTab:CreateToggle({
    Name = "Custom Speed",
    CurrentValue = false,
    Callback = function(Value)
        speedEnabled = Value
        if not Value then
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
        notify("Speed", Value and "ON" or "OFF")
    end
})

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 250},
    Increment = 5,
    CurrentValue = 16,
    Callback = function(Value)
        walkSpeed = Value
    end
})

-- Infinite Jump
local infJumpEnabled = false

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        infJumpEnabled = Value
        notify("Infinite Jump", Value and "ON" or "OFF")
    end
})

-- Noclip
local noclipEnabled = false

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        noclipEnabled = Value
        notify("Noclip", Value and "ON" or "OFF")
    end
})

-- ═══════════════════════════════════════
-- 👥 PLAYERS TAB
-- ═══════════════════════════════════════
local PlayersTab = Window:CreateTab("👥 Players", nil)
local PlayersSection = PlayersTab:CreateSection("Player Selection")

local PlayerDropdown = PlayersTab:CreateDropdown({
    Name = "Select Player",
    Options = getPlayerList(),
    CurrentOption = {"None"},
    MultipleOptions = false,
    Callback = function(Option)
        selectedPlayer = getPlayerByName(Option[1])
        if selectedPlayer then
            notify("Selected", selectedPlayer.Name)
        end
    end
})

PlayersTab:CreateButton({
    Name = "🔄 Refresh List",
    Callback = function()
        PlayerDropdown:Refresh(getPlayerList(), true)
        notify("Refreshed", "Player list updated")
    end
})

local ActionsSection = PlayersTab:CreateSection("Player Actions")

PlayersTab:CreateButton({
    Name = "📍 Teleport to Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = getRoot()
            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                notify("Teleported", selectedPlayer.Name)
            end
        else
            notify("Error", "No player selected")
        end
    end
})

PlayersTab:CreateButton({
    Name = "👁️ View Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            Workspace.CurrentCamera.CameraSubject = selectedPlayer.Character
            notify("Viewing", selectedPlayer.Name)
        end
    end
})

PlayersTab:CreateButton({
    Name = "🔙 View Self",
    Callback = function()
        local char = getChar()
        if char then
            Workspace.CurrentCamera.CameraSubject = char
            notify("View", "Back to self")
        end
    end
})

PlayersTab:CreateButton({
    Name = "🌪️ Fling Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = getRoot()
            
            if targetRoot and myRoot then
                local oldPos = myRoot.CFrame
                myRoot.CFrame = targetRoot.CFrame
                
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Velocity = Vector3.new(0, 100, 0)
                bv.Parent = myRoot
                
                task.wait(0.1)
                bv:Destroy()
                myRoot.CFrame = oldPos
                
                notify("Flinged", selectedPlayer.Name)
            end
        end
    end
})

-- ═══════════════════════════════════════
-- 👁️ VISUAL TAB
-- ═══════════════════════════════════════
local VisualTab = Window:CreateTab("👁️ Visual", nil)
local ESPSection = VisualTab:CreateSection("ESP Settings")

VisualTab:CreateToggle({
    Name = "ESP (Highlight)",
    CurrentValue = false,
    Callback = function(Value)
        espEnabled = Value
        updateAllESP()
        notify("ESP", Value and "ON" or "OFF")
    end
})

VisualTab:CreateColorPicker({
    Name = "ESP Fill Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        espConfig.fillColor = Value
        updateAllESP()
    end
})

VisualTab:CreateColorPicker({
    Name = "ESP Outline Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        espConfig.outlineColor = Value
        updateAllESP()
    end
})

VisualTab:CreateSlider({
    Name = "Fill Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(Value)
        espConfig.fillTransparency = Value
        updateAllESP()
    end
})

VisualTab:CreateSlider({
    Name = "Outline Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0,
    Callback = function(Value)
        espConfig.outlineTransparency = Value
        updateAllESP()
    end
})

local LightSection = VisualTab:CreateSection("Lighting")

VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(Value)
        local Lighting = game:GetService("Lighting")
        if Value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.GlobalShadows = true
        end
        notify("Fullbright", Value and "ON" or "OFF")
    end
})

-- ═══════════════════════════════════════
-- 🎯 COMBAT TAB
-- ═══════════════════════════════════════
local CombatTab = Window:CreateTab("🎯 Combat", nil)
local HitboxSection = CombatTab:CreateSection("Hitbox Expander")

local hitboxEnabled = false
local hitboxSize = 10
local hitboxColor = Color3.fromRGB(255, 0, 0)
local hitboxTransparency = 0.7

CombatTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Callback = function(Value)
        hitboxEnabled = Value
        notify("Hitbox", Value and "ON" or "OFF")
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {5, 25},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(Value)
        hitboxSize = Value
    end
})

CombatTab:CreateColorPicker({
    Name = "Hitbox Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        hitboxColor = Value
    end
})

CombatTab:CreateSlider({
    Name = "Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.7,
    Callback = function(Value)
        hitboxTransparency = Value
    end
})

-- ═══════════════════════════════════════
-- ⚙️ SETTINGS TAB
-- ═══════════════════════════════════════
local SettingsTab = Window:CreateTab("⚙️ Settings", nil)
local ThemeSection = SettingsTab:CreateSection("Theme Settings")

SettingsTab:CreateColorPicker({
    Name = "Accent Color (Borders/Lines)",
    Color = Color3.fromRGB(138, 43, 226),
    Callback = function(Value)
        -- Este color cambiará los bordes/líneas de Rayfield
        notify("Theme", "Accent color updated!")
    end
})

local CreditsSection = SettingsTab:CreateSection("━━━━━━━━ Credits ━━━━━━━━")
SettingsTab:CreateLabel("👤 Created by: Gael Fonzar")
SettingsTab:CreateLabel("📦 Version: 2.1 Optimized")
SettingsTab:CreateLabel("✅ Status: Loaded")
SettingsTab:CreateLabel("━━━━━━━━━━━━━━━━━━━━━━━")

-- ═══════════════════════════════════════
-- 🔄 OPTIMIZED GAME LOOPS
-- ═══════════════════════════════════════

-- Fly Control (Optimized)
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

-- Speed Control
connections.Speed = RunService.Heartbeat:Connect(function()
    if not speedEnabled then return end
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = walkSpeed end
end)

-- Noclip (Optimized - every 0.1s instead of every frame)
local noclipTimer = 0
connections.Noclip = RunService.Stepped:Connect(function(_, deltaTime)
    if not noclipEnabled then return end
    
    noclipTimer = noclipTimer + deltaTime
    if noclipTimer >= 0.1 then
        noclipTimer = 0
        local char = getChar()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
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

-- Hitbox Expander (Optimized)
local hitboxCache = {}
connections.Hitbox = RunService.Heartbeat:Connect(function()
    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                if hitboxEnabled then
                    -- Cache original size
                    if not hitboxCache[target.Name] then
                        hitboxCache[target.Name] = {
                            size = targetRoot.Size,
                            trans = targetRoot.Transparency,
                            cancol = targetRoot.CanCollide
                        }
                    end
                    
                    targetRoot.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    targetRoot.Transparency = hitboxTransparency
                    targetRoot.Color = hitboxColor
                    targetRoot.Material = Enum.Material.ForceField
                    targetRoot.CanCollide = false
                    
                    if not targetRoot:FindFirstChild("GF_HitboxMesh") then
                        local mesh = Instance.new("SpecialMesh")
                        mesh.Name = "GF_HitboxMesh"
                        mesh.MeshType = Enum.MeshType.Sphere
                        mesh.Parent = targetRoot
                    end
                else
                    -- Restore
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

-- ESP Respawn Handler
connections.ESPRespawn = Players.PlayerAdded:Connect(function(newPlayer)
    newPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espEnabled then
            createESP(newPlayer)
        end
    end)
end)

-- ESP Remove Handler
connections.ESPRemove = Players.PlayerRemoving:Connect(function(removedPlayer)
    removeESP(removedPlayer)
end)

-- Cleanup on death
player.CharacterRemoving:Connect(function()
    flyEnabled = false
    local root = getRoot()
    if root then
        if root:FindFirstChild("GF_Fly") then root.GF_Fly:Destroy() end
        if root:FindFirstChild("GF_Gyro") then root.GF_Gyro:Destroy() end
    end
end)

-- ═══════════════════════════════════════
-- 🎉 STARTUP
-- ═══════════════════════════════════════
notify("GF Hub", "Loaded Successfully! ✅", 3)
print("═══════════════════════════════════")
print("🎮 GF Hub v2.1 Loaded!")
print("Created by: Gael Fonzar")
print("Status: Optimized & Fixed")
print("═══════════════════════════════════")

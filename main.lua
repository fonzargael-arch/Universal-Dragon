--[[
    ═══════════════════════════════════════
    🎮 GF HUB - Universal Script
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Version: 3.0 - Linoria UI
    Best customization & performance
    ═══════════════════════════════════════
]]

-- Intro Animation
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local IntroGui = Instance.new("ScreenGui")
IntroGui.Name = "GFIntro"
IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
IntroGui.IgnoreGuiInset = true

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

TweenService:Create(IntroText, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
task.wait(0.3)
TweenService:Create(IntroSubText, TweenInfo.new(0.8), {TextTransparency = 0}):Play()
task.wait(1.5)
TweenService:Create(IntroFrame, TweenInfo.new(0.8), {BackgroundTransparency = 1}):Play()
TweenService:Create(IntroText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
TweenService:Create(IntroSubText, TweenInfo.new(0.8), {TextTransparency = 1}):Play()
task.wait(0.9)
IntroGui:Destroy()

-- Load Linoria Library
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

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
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    -- Create Billboard for Health & Distance
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

-- Update ESP Info
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

-- Create Window
local Window = Library:CreateWindow({
    Title = '🎮 GF Hub v3.0',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Create Tabs
local Tabs = {
    Movement = Window:AddTab('🚀 Movement'),
    Players = Window:AddTab('👥 Players'),
    Visual = Window:AddTab('👁️ Visual'),
    Combat = Window:AddTab('🎯 Combat'),
    Settings = Window:AddTab('⚙️ Settings')
}

-- ═══════════════════════════════════════
-- 🚀 MOVEMENT TAB
-- ═══════════════════════════════════════
local MovementBox = Tabs.Movement:AddLeftGroupbox('Movement Controls')

-- Fly
local flyEnabled = false
local flySpeed = 100

MovementBox:AddToggle('FlyToggle', {
    Text = 'Fly Mode',
    Default = false,
    Tooltip = 'Fly using WASD + Space/Shift',
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
            
            Library:Notify('Fly activated! Use WASD + Space/Shift', 3)
        else
            if root then
                if root:FindFirstChild("GF_Fly") then root.GF_Fly:Destroy() end
                if root:FindFirstChild("GF_Gyro") then root.GF_Gyro:Destroy() end
            end
            Library:Notify('Fly deactivated', 2)
        end
    end
})

MovementBox:AddSlider('FlySpeed', {
    Text = 'Fly Speed',
    Default = 100,
    Min = 10,
    Max = 250,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        flySpeed = Value
    end
})

MovementBox:AddDivider()

-- Speed
local speedEnabled = false
local walkSpeed = 16

MovementBox:AddToggle('SpeedToggle', {
    Text = 'Custom Speed',
    Default = false,
    Tooltip = 'Change your walk speed',
    Callback = function(Value)
        speedEnabled = Value
        if not Value then
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
        Library:Notify('Speed ' .. (Value and 'enabled' or 'disabled'), 2)
    end
})

MovementBox:AddSlider('WalkSpeed', {
    Text = 'Walk Speed',
    Default = 16,
    Min = 16,
    Max = 250,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        walkSpeed = Value
    end
})

MovementBox:AddDivider()

-- Infinite Jump
local infJumpEnabled = false

MovementBox:AddToggle('InfJump', {
    Text = 'Infinite Jump',
    Default = false,
    Callback = function(Value)
        infJumpEnabled = Value
        Library:Notify('Infinite Jump ' .. (Value and 'ON' or 'OFF'), 2)
    end
})

-- Noclip
local noclipEnabled = false

MovementBox:AddToggle('Noclip', {
    Text = 'Noclip',
    Default = false,
    Callback = function(Value)
        noclipEnabled = Value
        Library:Notify('Noclip ' .. (Value and 'ON' or 'OFF'), 2)
    end
})

-- ═══════════════════════════════════════
-- 👥 PLAYERS TAB
-- ═══════════════════════════════════════
local PlayerBox = Tabs.Players:AddLeftGroupbox('Player Selection')

PlayerBox:AddDropdown('PlayerSelect', {
    Values = getPlayerList(),
    Default = 1,
    Multi = false,
    Text = 'Select Player',
    Tooltip = 'Choose a player to interact with',
    Callback = function(Value)
        selectedPlayer = getPlayerByName(Value)
        if selectedPlayer then
            Library:Notify('Selected: ' .. selectedPlayer.Name, 2)
        end
    end
})

PlayerBox:AddButton({
    Text = '🔄 Refresh Players',
    Func = function()
        Options.PlayerSelect:SetValues(getPlayerList())
        Library:Notify('Player list refreshed!', 2)
    end,
    DoubleClick = false
})

local ActionsBox = Tabs.Players:AddRightGroupbox('Player Actions')

ActionsBox:AddButton({
    Text = '📍 Teleport to Player',
    Func = function()
        if selectedPlayer and selectedPlayer.Character then
            local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = getRoot()
            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                Library:Notify('Teleported to ' .. selectedPlayer.Name, 2)
            end
        else
            Library:Notify('No player selected!', 3)
        end
    end
})

ActionsBox:AddButton({
    Text = '👁️ View Player',
    Func = function()
        if selectedPlayer and selectedPlayer.Character then
            Workspace.CurrentCamera.CameraSubject = selectedPlayer.Character
            Library:Notify('Viewing ' .. selectedPlayer.Name, 2)
        else
            Library:Notify('No player selected!', 3)
        end
    end
})

ActionsBox:AddButton({
    Text = '🔙 View Self',
    Func = function()
        local char = getChar()
        if char then
            Workspace.CurrentCamera.CameraSubject = char
            Library:Notify('Viewing yourself', 2)
        end
    end
})

ActionsBox:AddButton({
    Text = '🌪️ Fling Player',
    Func = function()
        if not selectedPlayer or not selectedPlayer.Character then
            Library:Notify('No player selected!', 3)
            return
        end
        
        local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myRoot = getRoot()
        local myChar = getChar()
        
        if not targetRoot or not myRoot or not myChar then
            Library:Notify('Character not found!', 3)
            return
        end
        
        local originalPos = myRoot.CFrame
        
        for _, part in pairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.zero
        bv.Parent = myRoot
        
        myRoot.CFrame = targetRoot.CFrame
        
        task.wait(0.05)
        bv.Velocity = Vector3.new(math.random(-100, 100), 200, math.random(-100, 100))
        
        task.wait(0.15)
        
        if bv and bv.Parent then
            bv:Destroy()
        end
        
        task.wait(0.1)
        myRoot.CFrame = originalPos
        
        for _, part in pairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        
        Library:Notify('Flinged ' .. selectedPlayer.Name .. '!', 2)
    end
})

-- ═══════════════════════════════════════
-- 👁️ VISUAL TAB
-- ═══════════════════════════════════════
local ESPBox = Tabs.Visual:AddLeftGroupbox('ESP Settings')

ESPBox:AddToggle('ESPToggle', {
    Text = 'Enable ESP',
    Default = false,
    Callback = function(Value)
        espEnabled = Value
        updateAllESP()
        Library:Notify('ESP ' .. (Value and 'ON' or 'OFF'), 2)
    end
})

ESPBox:AddToggle('ShowHealth', {
    Text = 'Show Health',
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

ESPBox:AddToggle('ShowDistance', {
    Text = 'Show Distance',
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

ESPBox:AddLabel('Fill Color'):AddColorPicker('ESPFillColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'ESP Fill Color',
    Transparency = 0,
    Callback = function(Value)
        espConfig.fillColor = Value
        updateAllESP()
    end
})

ESPBox:AddLabel('Outline Color'):AddColorPicker('ESPOutlineColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'ESP Outline Color',
    Transparency = 0,
    Callback = function(Value)
        espConfig.outlineColor = Value
        updateAllESP()
    end
})

ESPBox:AddSlider('ESPFillTrans', {
    Text = 'Fill Transparency',
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        espConfig.fillTransparency = Value
        updateAllESP()
    end
})

ESPBox:AddSlider('ESPOutlineTrans', {
    Text = 'Outline Transparency',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        espConfig.outlineTransparency = Value
        updateAllESP()
    end
})

local LightBox = Tabs.Visual:AddRightGroupbox('Lighting')

LightBox:AddToggle('Fullbright', {
    Text = 'Fullbright',
    Default = false,
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
        Library:Notify('Fullbright ' .. (Value and 'ON' or 'OFF'), 2)
    end
})

-- ═══════════════════════════════════════
-- 🎯 COMBAT TAB
-- ═══════════════════════════════════════
local HitboxBox = Tabs.Combat:AddLeftGroupbox('Hitbox Expander')

local hitboxEnabled = false
local hitboxSize = 10
local hitboxColor = Color3.fromRGB(255, 0, 0)
local hitboxTransparency = 0.7

HitboxBox:AddToggle('HitboxToggle', {
    Text = 'Hitbox Expander',
    Default = false,
    Callback = function(Value)
        hitboxEnabled = Value
        Library:Notify('Hitbox ' .. (Value and 'ON' or 'OFF'), 2)
    end
})

HitboxBox:AddSlider('HitboxSize', {
    Text = 'Hitbox Size',
    Default = 10,
    Min = 5,
    Max = 25,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        hitboxSize = Value
    end
})

HitboxBox:AddLabel('Hitbox Color'):AddColorPicker('HitboxColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Hitbox Color',
    Transparency = 0.7,
    Callback = function(Value)
        hitboxColor = Value
    end
})

HitboxBox:AddSlider('HitboxTrans', {
    Text = 'Transparency',
    Default = 0.7,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        hitboxTransparency = Value
    end
})

-- ═══════════════════════════════════════
-- ⚙️ SETTINGS TAB
-- ═══════════════════════════════════════
local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'RightShift', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

ThemeManager:SetFolder('GFHub')
SaveManager:SetFolder('GFHub/configs')

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

local CreditsBox = Tabs.Settings:AddRightGroupbox('Credits')
CreditsBox:AddLabel('━━━━━━━━━━━━━━━━━━')
CreditsBox:AddLabel('👤 Created by: Gael Fonzar')
CreditsBox:AddLabel('📦 Version: 3.0 - Linoria UI')
CreditsBox:AddLabel('✅ Status: Loaded')
CreditsBox:AddLabel('━━━━━━━━━━━━━━━━━━')

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

-- Hitbox
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

-- Player Added/Removed Events
Players.PlayerAdded:Connect(function(newPlayer)
    task.wait(1)
    if espEnabled and newPlayer ~= player then
        createESP(newPlayer)
    end
    Options.PlayerSelect:SetValues(getPlayerList())
end)

Players.PlayerRemoving:Connect(function(removedPlayer)
    removeESP(removedPlayer)
    Options.PlayerSelect:SetValues(getPlayerList())
end)

-- Character Added Events
player.CharacterAdded:Connect(function(char)
    task.wait(1)
    -- Reapply speed if enabled
    if speedEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = walkSpeed
        end
    end
end)

-- Cleanup on script unload
local function cleanup()
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
    
    -- Reset character properties
    local char = getChar()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
        end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            if root:FindFirstChild("GF_Fly") then root.GF_Fly:Destroy() end
            if root:FindFirstChild("GF_Gyro") then root.GF_Gyro:Destroy() end
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
    
    Library:Notify('GF Hub v3.0 unloaded successfully!', 3)
end

-- Register cleanup
Library:OnUnload(cleanup)

-- Final notification
Library:Notify('🎮 GF Hub v3.0 loaded successfully!', 5)
print('═══════════════════════════════════════')
print('🎮 GF Hub v3.0 - Loaded')
print('Created by: Gael Fonzar')
print('Press RightShift to toggle menu')
print('═══════════════════════════════════════')

--[[
    ═══════════════════════════════════════
    🎮 GF HUB - Universal Script v4.0
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Theme: Black + Red Accent
    Features: Bring Player, Kill Aura, Hit
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

local player = Players.LocalPlayer

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

-- Bring Player Variables
local bringEnabled = false
local bringLoop = false
local bringSpeed = 0.5

-- Kill Aura Variables
local killAuraEnabled = false
local killAuraRange = 20
local killAuraSpeed = 0.1

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

-- BRING PLAYER TO YOU
local function bringPlayer(target)
    if not target or not target.Character then
        Fluent:Notify({
            Title = "❌ Error",
            Content = "Player not found!",
            Duration = 2
        })
        return
    end
    
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local myRoot = getRoot()
    
    if not targetRoot or not myRoot then return end
    
    -- Teleport player to you
    targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
    
    Fluent:Notify({
        Title = "✅ Brought",
        Content = target.Name .. " teleported to you!",
        Duration = 2
    })
end

local function startBringLoop()
    bringLoop = true
    
    task.spawn(function()
        while bringLoop and bringEnabled and selectedPlayer do
            if selectedPlayer and selectedPlayer.Character then
                local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = getRoot()
                
                if targetRoot and myRoot then
                    targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
                end
            end
            
            task.wait(bringSpeed)
        end
    end)
end

local function stopBringLoop()
    bringLoop = false
    bringEnabled = false
end

-- KILL AURA SYSTEM
local function hitPlayer(target)
    if not target or not target.Character then return end
    
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
    local myRoot = getRoot()
    
    if not targetRoot or not targetHum or not myRoot then return end
    
    -- Check if in range
    local distance = (myRoot.Position - targetRoot.Position).Magnitude
    if distance > killAuraRange then return end
    
    -- Method 1: Teleport behind and hit
    local originalPos = myRoot.CFrame
    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    
    task.wait(0.05)
    
    -- Simulate punch/hit
    local tool = player.Character:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
    
    task.wait(0.05)
    myRoot.CFrame = originalPos
end

local function killAuraLoop()
    while killAuraEnabled do
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= player and target.Character then
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = getRoot()
                
                if targetRoot and myRoot then
                    local distance = (myRoot.Position - targetRoot.Position).Magnitude
                    
                    if distance <= killAuraRange then
                        hitPlayer(target)
                    end
                end
            end
        end
        
        task.wait(killAuraSpeed)
    end
end

-- Create Window with Dark Theme
local Window = Fluent:CreateWindow({
    Title = "🎮 GF HUB v4.0",
    SubTitle = "by Gael Fonzar",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 480),
    Acrylic = false, -- Disable for solid black
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

-- Apply Custom Dark Theme (Black + Red)
pcall(function()
    local gui = game:GetService("CoreGui"):FindFirstChild("FluentUI") or player.PlayerGui:FindFirstChild("FluentUI")
    if gui then
        for _, obj in pairs(gui:GetDescendants()) do
            -- Make background pure black
            if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
                obj.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            end
            
            -- Make accent colors red
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                obj.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            end
            
            -- Red text accents
            if obj:IsA("TextLabel") and obj.Name:find("Title") then
                obj.TextColor3 = Color3.fromRGB(255, 50, 50)
            end
        end
    end
end)

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "🏠 Main", Icon = "home" }),
    Movement = Window:AddTab({ Title = "🚀 Movement", Icon = "wind" }),
    Players = Window:AddTab({ Title = "👥 Players", Icon = "users" }),
    Combat = Window:AddTab({ Title = "⚔️ Combat", Icon = "sword" }),
    Visual = Window:AddTab({ Title = "👁️ Visual", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })
}

-- ═══════════════════════════════════════
-- 🏠 MAIN TAB
-- ═══════════════════════════════════════

Tabs.Main:AddParagraph({
    Title = "🎮 Welcome to GF HUB v4.0!",
    Content = "Dark Theme Edition\n\nNew Features:\n• Bring Player to You\n• Kill Aura\n• One-Hit Kill\n• Black + Red Theme"
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
    Title = "✈️ Fly Mode",
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
                Title = "✈️ Fly ON",
                Content = "Use WASD + Space/Shift",
                Duration = 2
            })
        else
            if root then
                if root:FindFirstChild("GF_Fly") then root.GF_Fly:Destroy() end
                if root:FindFirstChild("GF_Gyro") then root.GF_Gyro:Destroy() end
            end
        end
    end
})

Tabs.Movement:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Default = 100,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        flySpeed = Value
    end
})

Tabs.Movement:AddSection("Walking")

Tabs.Movement:AddToggle("SpeedToggle", {
    Title = "🏃 Custom Speed",
    Default = false,
    Callback = function(Value)
        speedEnabled = Value
        if not Value then
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
    end
})

Tabs.Movement:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        walkSpeed = Value
    end
})

Tabs.Movement:AddSection("Other")

Tabs.Movement:AddToggle("InfJump", {
    Title = "♾️ Infinite Jump",
    Default = false,
    Callback = function(Value)
        infJumpEnabled = Value
    end
})

Tabs.Movement:AddToggle("Noclip", {
    Title = "👻 Noclip",
    Default = false,
    Callback = function(Value)
        noclipEnabled = Value
    end
})

-- ═══════════════════════════════════════
-- 👥 PLAYERS TAB
-- ═══════════════════════════════════════

Tabs.Players:AddParagraph({
    Title = "👥 Player Control",
    Content = "Select and control other players"
})

local PlayerDropdown = Tabs.Players:AddDropdown("PlayerSelect", {
    Title = "Select Player",
    Values = getPlayerList(),
    Default = 1,
    Callback = function(Value)
        selectedPlayer = getPlayerByName(Value)
        if selectedPlayer then
            Fluent:Notify({
                Title = "✅ Selected",
                Content = selectedPlayer.Name,
                Duration = 2
            })
        end
    end
})

Tabs.Players:AddButton({
    Title = "🔄 Refresh List",
    Callback = function()
        PlayerDropdown:SetValues(getPlayerList())
        Fluent:Notify({
            Title = "✅ Refreshed",
            Content = "Player list updated",
            Duration = 2
        })
    end
})

Tabs.Players:AddSection("Teleport")

Tabs.Players:AddButton({
    Title = "📍 Teleport to Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = getRoot()
            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                Fluent:Notify({
                    Title = "✅ Teleported",
                    Content = "To " .. selectedPlayer.Name,
                    Duration = 2
                })
            end
        else
            Fluent:Notify({
                Title = "❌ Error",
                Content = "No player selected!",
                Duration = 2
            })
        end
    end
})

Tabs.Players:AddSection("Bring Player")

Tabs.Players:AddButton({
    Title = "🧲 Bring Player Once",
    Description = "Teleport player to you (one time)",
    Callback = function()
        if selectedPlayer then
            bringPlayer(selectedPlayer)
        else
            Fluent:Notify({
                Title = "❌ Error",
                Content = "No player selected!",
                Duration = 2
            })
        end
    end
})

local BringLoopToggle = Tabs.Players:AddToggle("BringLoop", {
    Title = "🔄 Bring Player (Loop)",
    Description = "Keep player near you",
    Default = false,
    Callback = function(Value)
        bringEnabled = Value
        
        if Value then
            if not selectedPlayer then
                Fluent:Notify({
                    Title = "❌ Error",
                    Content = "Select a player first!",
                    Duration = 2
                })
                BringLoopToggle:SetValue(false)
                return
            end
            
            Fluent:Notify({
                Title = "🧲 Bring Loop ON",
                Content = selectedPlayer.Name .. " stuck to you!",
                Duration = 2
            })
            startBringLoop()
        else
            stopBringLoop()
            Fluent:Notify({
                Title = "Bring Loop OFF",
                Content = "",
                Duration = 2
            })
        end
    end
})

Tabs.Players:AddSlider("BringSpeed", {
    Title = "Bring Speed",
    Description = "Lower = Faster updates",
    Default = 0.5,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        bringSpeed = Value
    end
})

Tabs.Players:AddSection("Camera")

Tabs.Players:AddButton({
    Title = "👁️ View Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            Workspace.CurrentCamera.CameraSubject = selectedPlayer.Character
        end
    end
})

Tabs.Players:AddButton({
    Title = "🔙 View Self",
    Callback = function()
        local char = getChar()
        if char then
            Workspace.CurrentCamera.CameraSubject = char
        end
    end
})

-- ═══════════════════════════════════════
-- ⚔️ COMBAT TAB
-- ═══════════════════════════════════════

Tabs.Combat:AddParagraph({
    Title = "⚔️ Combat System",
    Content = "Kill aura and hitbox tools"
})

local KillAuraToggle = Tabs.Combat:AddToggle("KillAura", {
    Title = "💀 Kill Aura",
    Description = "Auto hit nearby players",
    Default = false,
    Callback = function(Value)
        killAuraEnabled = Value
        
        if Value then
            Fluent:Notify({
                Title = "💀 Kill Aura ON",
                Content = "Hitting players in range",
                Duration = 2
            })
            task.spawn(killAuraLoop)
        else
            Fluent:Notify({
                Title = "Kill Aura OFF",
                Content = "",
                Duration = 2
            })
        end
    end
})

Tabs.Combat:AddSlider("KillAuraRange", {
    Title = "Kill Aura Range",
    Description = "Attack range in studs",
    Default = 20,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Callback = function(Value)
        killAuraRange = Value
    end
})

Tabs.Combat:AddSlider("KillAuraSpeed", {
    Title = "Attack Speed",
    Description = "Lower = Faster",
    Default = 0.1,
    Min = 0.05,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        killAuraSpeed = Value
    end
})

Tabs.Combat:AddSection("Manual Hit")

Tabs.Combat:AddButton({
    Title = "👊 Hit Selected Player",
    Description = "One-time hit on selected player",
    Callback = function()
        if selectedPlayer then
            hitPlayer(selectedPlayer)
            Fluent:Notify({
                Title = "💥 Hit!",
                Content = "Attacked " .. selectedPlayer.Name,
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "❌ Error",
                Content = "No player selected!",
                Duration = 2
            })
        end
    end
})

Tabs.Combat:AddSection("Hitbox Expander")

local hitboxEnabled = false
local hitboxSize = 10

Tabs.Combat:AddToggle("HitboxToggle", {
    Title = "📦 Hitbox Expander",
    Default = false,
    Callback = function(Value)
        hitboxEnabled = Value
    end
})

Tabs.Combat:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Default = 10,
    Min = 5,
    Max = 25,
    Rounding = 0,
    Callback = function(Value)
        hitboxSize = Value
    end
})

-- ═══════════════════════════════════════
-- 👁️ VISUAL TAB
-- ═══════════════════════════════════════

Tabs.Visual:AddParagraph({
    Title = "👁️ ESP System",
    Content = "See players through walls"
})

Tabs.Visual:AddToggle("ESPToggle", {
    Title = "👁️ Enable ESP",
    Default = false,
    Callback = function(Value)
        espEnabled = Value
        updateAllESP()
    end
})

Tabs.Visual:AddToggle("ShowHealth", {
    Title = "❤️ Show Health",
    Default = true,
    Callback = function(Value)
        espConfig.showHealth = Value
    end
})

Tabs.Visual:AddToggle("ShowDistance", {
    Title = "📏 Show Distance",
    Default = true,
    Callback = function(Value)
        espConfig.showDistance = Value
    end
})

Tabs.Visual:AddSection("Lighting")

Tabs.Visual:AddToggle("Fullbright", {
    Title = "💡 Fullbright",
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
    end
})

-- ═══════════════════════════════════════
-- ⚙️ SETTINGS TAB
-- ═══════════════════════════════════════

Tabs.Settings:AddButton({
    Title = "🗑️ Unload Script",
    Callback = function()
        Fluent:Destroy()
    end
})

InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("GFHub")
SaveManager:SetFolder("GFHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Tabs.Settings:AddSection("Info")

Tabs.Settings:AddParagraph({
    Title = "👤 GF HUB v4.0",
    Content = "Created by: Gael Fonzar\nTheme: Dark + Red\nStatus: ✅ Loaded"
})

-- ═══════════════════════════════════════
-- 🔄 LOOPS
-- ═══════════════════════════════════════

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

connections.Speed = RunService.Heartbeat:Connect(function()
    if not speedEnabled then return end
    local hum = getHumanoid()
    if hum then hum.WalkSpeed = walkSpeed end
end)

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

connections.InfJump = UserInputService.JumpRequest:Connect(function()
    if not infJumpEnabled then return end
    local hum = getHumanoid()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

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
                    targetRoot.Transparency = 0.7
                    targetRoot.Color = Color3.fromRGB(255, 0, 0)
                    targetRoot.CanCollide = false
                else
                    if hitboxCache[target.Name] then
                        targetRoot.Size = hitboxCache[target.Name].size
                        targetRoot.Transparency = hitboxCache[target.Name].trans
                        targetRoot.CanCollide = hitboxCache[target.Name].cancol
                        hitboxCache[target.Name] = nil
                    end
                end
            end
        end
    end
end)

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
    
    if speedEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = walkSpeed
        end
    end
    
    if bringEnabled then
        stopBringLoop()
    end
    
    if killAuraEnabled then
        killAuraEnabled = false
    end
end)

-- Cleanup
local function cleanup()
    stopBringLoop()
    killAuraEnabled = false
    
    for name, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    for _, target in pairs(Players:GetPlayers()) do
        removeESP(target)
    end
    
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
            root.Velocity = Vector3.new(0, 0, 0)
        end
    end
    
    for _, target in pairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot and hitboxCache[target.Name] then
                targetRoot.Size = hitboxCache[target.Name].size
                targetRoot.Transparency = hitboxCache[target.Name].trans
                targetRoot.CanCollide = hitboxCache[target.Name].cancol
            end
        end
    end
    
    local Lighting = game:GetService("Lighting")
    Lighting.Brightness = 1
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = true
    
    Fluent:Notify({
        Title = "👋 Unloaded",
        Content = "GF HUB removed",
        Duration = 2
    })
end

Window:OnUnload(cleanup)

SaveManager:IgnoreThemeSettings()
SaveManager:LoadAutoloadConfig()

-- Final notification
Fluent:Notify({
    Title = "🎮 GF HUB v4.0",
    Content = "Dark Theme Edition\nPress RightShift to toggle",
    Duration = 4
})

print("════════════════════════════════")
print("🎮 GF HUB v4.0 - Dark Theme")
print("Created by: Gael Fonzar")
print("Theme: Black + Red Accent")
print("Features:")
print("• Bring Player to You")
print("• Kill Aura System")
print("• One-Hit Kill")
print("• Hitbox Expander")
print("• ESP System")
print("Press RightShift to open")
print("════════════════════════════════")

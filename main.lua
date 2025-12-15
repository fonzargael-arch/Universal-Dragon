--[[
    ═══════════════════════════════════════
    🎮 GF HUB - Universal Script
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Version: 2.0 Enhanced
    ═══════════════════════════════════════
]]

-- Intro Animation
local IntroGui = Instance.new("ScreenGui")
IntroGui.Name = "GFIntro"
IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
IntroGui.Parent = game:GetService("CoreGui")

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
game:GetService("TweenService"):Create(IntroText, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    TextTransparency = 0
}):Play()

wait(0.5)

game:GetService("TweenService"):Create(IntroSubText, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    TextTransparency = 0
}):Play()

wait(2)

game:GetService("TweenService"):Create(IntroFrame, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 1
}):Play()

game:GetService("TweenService"):Create(IntroText, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    TextTransparency = 1
}):Play()

game:GetService("TweenService"):Create(IntroSubText, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    TextTransparency = 1
}):Play()

wait(1)
IntroGui:Destroy()

-- Load Rayfield Library with custom theme
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
    outlineTransparency = 0
}

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
        Duration = duration or 3,
        Image = "rewind"
    })
end

-- Enhanced ESP System
local function createESP(target)
    if not target or not target.Character then return end
    
    -- Remove old ESP if exists
    if espObjects[target.Name] then
        espObjects[target.Name]:Destroy()
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "GF_ESP"
    highlight.Adornee = target.Character
    highlight.FillColor = espConfig.fillColor
    highlight.OutlineColor = espConfig.outlineColor
    highlight.FillTransparency = espConfig.fillTransparency
    highlight.OutlineTransparency = espConfig.outlineTransparency
    highlight.Parent = target.Character
    
    espObjects[target.Name] = highlight
    
    -- Reconnect on respawn
    target.CharacterAdded:Connect(function(char)
        if espEnabled then
            task.wait(0.5)
            createESP(target)
        end
    end)
end

local function removeESP(target)
    if espObjects[target.Name] then
        espObjects[target.Name]:Destroy()
        espObjects[target.Name] = nil
    end
end

local function updateESP()
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

-- Create Window with Black Theme
local Window = Rayfield:CreateWindow({
    Name = "🎮 GF Hub",
    LoadingTitle = "GF Hub",
    LoadingSubtitle = "by Gael Fonzar",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GFHub",
        FileName = "GFHub_Config"
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false,
    Theme = {
        Background = Color3.fromRGB(15, 15, 15),
        Topbar = Color3.fromRGB(20, 20, 20),
        Shadow = Color3.fromRGB(0, 0, 0)
    }
})

-- ═══════════════════════════════════════
-- 🚀 MOVEMENT TAB
-- ═══════════════════════════════════════
local MovementTab = Window:CreateTab("🚀 Movement", "rocket")

local MovementSection = MovementTab:CreateSection("Movement Controls")

-- Fly
local flyEnabled = false
local flySpeed = 100

local FlyToggle = MovementTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        flyEnabled = Value
        local root = getRoot()
        local hum = getHumanoid()
        
        if Value and root and hum then
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
            
            notify("Fly", "Activated! Use WASD + Space/Shift")
        else
            if root then
                if root:FindFirstChild("GF_Fly") then root.GF_Fly:Destroy() end
                if root:FindFirstChild("GF_Gyro") then root.GF_Gyro:Destroy() end
            end
            notify("Fly", "Deactivated")
        end
    end
})

local FlySpeedSlider = MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 10,
    CurrentValue = 100,
    Flag = "FlySpeed",
    Callback = function(Value)
        flySpeed = Value
    end
})

-- Speed
local speedEnabled = false
local walkSpeed = 16

local SpeedToggle = MovementTab:CreateToggle({
    Name = "Custom Speed",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(Value)
        speedEnabled = Value
        if not Value then
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end
    end
})

local SpeedSlider = MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 300},
    Increment = 5,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        walkSpeed = Value
    end
})

-- Infinite Jump
local infJumpEnabled = false

local InfJumpToggle = MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(Value)
        infJumpEnabled = Value
        notify("Infinite Jump", Value and "Activated" or "Deactivated")
    end
})

-- Noclip
local noclipEnabled = false

local NoclipToggle = MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        noclipEnabled = Value
        notify("Noclip", Value and "Activated" or "Deactivated")
    end
})

-- ═══════════════════════════════════════
-- 👥 PLAYERS TAB
-- ═══════════════════════════════════════
local PlayersTab = Window:CreateTab("👥 Players", "users")

local PlayersSection = PlayersTab:CreateSection("Player Selection")

local PlayerDropdown = PlayersTab:CreateDropdown({
    Name = "Select Player",
    Options = getPlayerList(),
    CurrentOption = {"None"},
    MultipleOptions = false,
    Flag = "SelectedPlayer",
    Callback = function(Option)
        selectedPlayer = getPlayerByName(Option[1])
        if selectedPlayer then
            notify("Player Selected", selectedPlayer.Name)
        end
    end
})

local RefreshButton = PlayersTab:CreateButton({
    Name = "🔄 Refresh Player List",
    Callback = function()
        PlayerDropdown:Refresh(getPlayerList(), true)
        notify("Players", "List refreshed!")
    end
})

local PlayerActionsSection = PlayersTab:CreateSection("Player Actions")

local TeleportButton = PlayersTab:CreateButton({
    Name = "📍 Teleport to Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = getRoot()
            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                notify("Teleport", "Teleported to " .. selectedPlayer.Name)
            end
        else
            notify("Error", "No player selected or player unavailable")
        end
    end
})

local ViewButton = PlayersTab:CreateButton({
    Name = "👁️ View Player",
    Callback = function()
        if selectedPlayer and selectedPlayer.Character then
            workspace.CurrentCamera.CameraSubject = selectedPlayer.Character
            notify("View", "Viewing " .. selectedPlayer.Name)
        else
            notify("Error", "No player selected")
        end
    end
})

local UnviewButton = PlayersTab:CreateButton({
    Name = "🔙 View Self",
    Callback = function()
        local char = getChar()
        if char then
            workspace.CurrentCamera.CameraSubject = char
            notify("View", "Viewing yourself")
        end
    end
})

local FlingButton = PlayersTab:CreateButton({
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
                
                notify("Fling", "Flinged " .. selectedPlayer.Name)
            end
        else
            notify("Error", "No player selected")
        end
    end
})

-- ═══════════════════════════════════════
-- 👁️ VISUAL TAB
-- ═══════════════════════════════════════
local VisualTab = Window:CreateTab("👁️ Visual", "eye")

local ESPSection = VisualTab:CreateSection("ESP Settings")

local ESPToggle = VisualTab:CreateToggle({
    Name = "ESP (Highlight)",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        espEnabled = Value
        updateESP()
        notify("ESP", Value and "Activated" or "Deactivated")
    end
})

local ESPFillColorPicker = VisualTab:CreateColorPicker({
    Name = "ESP Fill Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPFillColor",
    Callback = function(Value)
        espConfig.fillColor = Value
        updateESP()
    end
})

local ESPOutlineColorPicker = VisualTab:CreateColorPicker({
    Name = "ESP Outline Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPOutlineColor",
    Callback = function(Value)
        espConfig.outlineColor = Value
        updateESP()
    end
})

local ESPFillTransSlider = VisualTab:CreateSlider({
    Name = "ESP Fill Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Flag = "ESPFillTrans",
    Callback = function(Value)
        espConfig.fillTransparency = Value
        updateESP()
    end
})

local ESPOutlineTransSlider = VisualTab:CreateSlider({
    Name = "ESP Outline Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0,
    Flag = "ESPOutlineTrans",
    Callback = function(Value)
        espConfig.outlineTransparency = Value
        updateESP()
    end
})

local LightingSection = VisualTab:CreateSection("Lighting")

local FullbrightToggle = VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
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
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = true
        end
        notify("Fullbright", Value and "Activated" or "Deactivated")
    end
})

-- ═══════════════════════════════════════
-- 🎯 COMBAT TAB
-- ═══════════════════════════════════════
local CombatTab = Window:CreateTab("🎯 Combat", "shield")

local HitboxSection = CombatTab:CreateSection("Hitbox Settings")

local hitboxEnabled = false
local hitboxSize = 10
local hitboxColor = Color3.fromRGB(255, 0, 0)
local hitboxTransparency = 0.7

local HitboxToggle = CombatTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Flag = "Hitbox",
    Callback = function(Value)
        hitboxEnabled = Value
        notify("Hitbox", Value and "Activated" or "Deactivated")
    end
})

local HitboxSlider = CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 10,
    Flag = "HitboxSize",
    Callback = function(Value)
        hitboxSize = Value
    end
})

local HitboxColorPicker = CombatTab:CreateColorPicker({
    Name = "Hitbox Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "HitboxColor",
    Callback = function(Value)
        hitboxColor = Value
    end
})

local HitboxTransSlider = CombatTab:CreateSlider({
    Name = "Hitbox Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.7,
    Flag = "HitboxTrans",
    Callback = function(Value)
        hitboxTransparency = Value
    end
})

-- ═══════════════════════════════════════
-- ⚙️ SETTINGS TAB
-- ═══════════════════════════════════════
local SettingsTab = Window:CreateTab("⚙️ Settings", "settings")

local SettingsSection = SettingsTab:CreateSection("GUI Settings")

local CreditsSection = SettingsTab:CreateSection("Credits")

local CreditsLabel = SettingsTab:CreateLabel("━━━━━━━━━━━━━━━━━━━━")
local CreatorLabel = SettingsTab:CreateLabel("👤 Created by: Gael Fonzar")
local VersionLabel = SettingsTab:CreateLabel("📦 Version: 2.0 Enhanced")
local StatusLabel = SettingsTab:CreateLabel("✅ Status: Loaded Successfully")
local CreditsLabel2 = SettingsTab:CreateLabel("━━━━━━━━━━━━━━━━━━━━")

-- ═══════════════════════════════════════
-- 🔄 GAME LOOPS
-- ═══════════════════════════════════════

-- Fly Control
RunService.Heartbeat:Connect(function()
    if flyEnabled then
        local root = getRoot()
        if root then
            local bv = root:FindFirstChild("GF_Fly")
            local bg = root:FindFirstChild("GF_Gyro")
            
            if bv and bg then
                local cam = workspace.CurrentCamera.CFrame
                local moveDirection = Vector3.zero
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDirection = moveDirection + cam.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDirection = moveDirection - cam.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDirection = moveDirection - cam.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDirection = moveDirection + cam.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end
                
                bv.Velocity = moveDirection * flySpeed
                bg.CFrame = cam
            end
        end
    end
end)

-- Speed Control
RunService.Heartbeat:Connect(function()
    if speedEnabled then
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = walkSpeed
        end
    end
end)

-- Noclip
RunService.Stepped:Connect(function()
    if noclipEnabled then
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
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Enhanced Hitbox Expander with Sphere
RunService.Heartbeat:Connect(function()
    if hitboxEnabled then
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= player and target.Character then
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    -- Size expansion
                    targetRoot.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    targetRoot.Transparency = hitboxTransparency
                    targetRoot.Color = hitboxColor
                    targetRoot.Material = Enum.Material.ForceField
                    targetRoot.CanCollide = false
                    
                    -- Create sphere shape if doesn't exist
                    if not targetRoot:FindFirstChild("GF_HitboxMesh") then
                        local mesh = Instance.new("SpecialMesh")
                        mesh.Name = "GF_HitboxMesh"
                        mesh.MeshType = Enum.MeshType.Sphere
                        mesh.Parent = targetRoot
                    end
                end
            end
        end
    else
        -- Restore original hitboxes
        for _, target in pairs(Players:GetPlayers()) do
            if target ~= player and target.Character then
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    targetRoot.Size = Vector3.new(2, 2, 1)
                    targetRoot.Transparency = 1
                    targetRoot.CanCollide = true
                    targetRoot.Material = Enum.Material.Plastic
                    
                    local mesh = targetRoot:FindFirstChild("GF_HitboxMesh")
                    if mesh then
                        mesh:Destroy()
                    end
                end
            end
        end
    end
end)

-- ESP Update on player events
Players.PlayerAdded:Connect(function(newPlayer)
    if espEnabled then
        newPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            if espEnabled then
                createESP(newPlayer)
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(function(removedPlayer)
    removeESP(removedPlayer)
end)

-- ═══════════════════════════════════════
-- 🎉 STARTUP
-- ═══════════════════════════════════════
notify("GF Hub", "Loaded Successfully! ✅", 5)
print("═══════════════════════════════════")
print("🎮 GF Hub Enhanced Edition Loaded!")
print("Created by: Gael Fonzar")
print("Version: 2.0")
print("═══════════════════════════════════")

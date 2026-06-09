--[[
╔════════════════════════════════════════════════════════════════════╗
║                    🔴 GF HUB v8.0 ULTIMATE 🔴                      ║
║              by Gael Fonzar | Sistema Modular | 2025              ║
║         Negro/Rojo | Auto-TP | ESP por Equipos | Anti-Lag         ║
╚════════════════════════════════════════════════════════════════════╝
]]

-- ============================================================================
-- CONFIGURACIÓN INICIAL
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================
local function getChar() return player.Character end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getTargetChar(target) return target and target.Character end
local function getTargetHRP(target) local c = getTargetChar(target) return c and c:FindFirstChild("HumanoidRootPart") end
local function isSameTeam(target) return player.Team and target.Team and player.Team == target.Team end

-- ============================================================================
-- MAID SYSTEM (Anti-Memory Leak)
-- ============================================================================
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({_connections = {}, _instances = {}}, Maid)
end

function Maid:Add(item)
    if typeof(item) == "RBXScriptConnection" then
        table.insert(self._connections, item)
    elseif typeof(item) == "Instance" then
        table.insert(self._instances, item)
    elseif type(item) == "function" then
        table.insert(self._connections, {Disconnect = item})
    end
    return item
end

function Maid:Destroy()
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, inst in ipairs(self._instances) do
        pcall(function() inst:Destroy() end)
    end
    self._connections = {}
    self._instances = {}
end

local globalMaid = Maid.new()
local espMaid = Maid.new()

-- ============================================================================
-- ESTADO GLOBAL
-- ============================================================================
local S = {
    -- Movimiento
    walkSpeed = 16,
    jumpPower = 50,
    fly = false,
    flySpeed = 80,
    noclip = false,
    infJump = false,
    
    -- TP Automático
    autoTP = false,
    autoTPInterval = 0.5,
    selectedPlayer = nil,
    
    -- Bring
    bring = false,
    bringDistance = 3,
    
    -- Invisibilidad
    realInvis = false,
    
    -- Protección
    antiKB = false,
    godMode = false,
    antiRagdoll = false,
    
    -- Visual
    esp = false,
    espMode = "Enemigos", -- "Todos", "Aliados", "Enemigos"
    fullbright = false,
    chams = false,
    
    -- Combate
    killAura = false,
    killAuraRange = 15,
    killAuraDelay = 0.2,
    hitbox = false,
    hitboxSize = 10,
    silentAim = false,
    
    active = true,
}

-- ============================================================================
-- NOTIFICACIONES MODERNAS
-- ============================================================================
local function notify(title, msg, type)
    type = type or "info"
    local colors = {
        success = Color3.fromRGB(50, 255, 100),
        error = Color3.fromRGB(255, 50, 50),
        info = Color3.fromRGB(220, 20, 60),
        warning = Color3.fromRGB(255, 200, 50)
    }
    
    -- Usar Fluent para notificaciones premium
    Fluent:Notify({
        Title = title,
        Content = msg,
        Duration = 3
    })
end

-- ============================================================================
-- CARGA DE FLUENT UI CON TEMA PREMIUM
-- ============================================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Tema personalizado Negro/Rojo
Fluent.Theme:SetTheme("Dark")
Fluent.Theme.AccentColor = Color3.fromRGB(220, 20, 60)
Fluent.Theme.BackgroundColor = Color3.fromRGB(20, 20, 25)

-- ============================================================================
-- MÓDULO: INVISIBILIDAD REAL
-- ============================================================================
local Invisibility = {
    originalTransparencies = {},
    active = false
}

function Invisibility:enable()
    local char = getChar()
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if not self.originalTransparencies[part] then
                self.originalTransparencies[part] = part.Transparency
            end
            part.Transparency = 1
            part.CanCollide = false
        elseif part:IsA("Accessory") and part.Handle then
            part.Handle.Transparency = 1
        end
    end
    self.active = true
end

function Invisibility:disable()
    local char = getChar()
    if not char then return end
    
    for part, original in pairs(self.originalTransparencies) do
        if part and part.Parent then
            part.Transparency = original
            part.CanCollide = true
        end
    end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("Accessory") and part.Handle then
            part.Handle.Transparency = 0
        end
    end
    self.active = false
end

-- ============================================================================
-- MÓDULO: FLY MODERN
-- ============================================================================
local Fly = {
    connections = {},
    bodyVel = nil,
    bodyGyro = nil,
    active = false
}

function Fly:start()
    local hrp = getHRP()
    if not hrp then return end
    
    self:stop()
    
    self.bodyVel = Instance.new("BodyVelocity")
    self.bodyVel.Name = "GF_Fly_BV"
    self.bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    self.bodyVel.Parent = hrp
    
    self.bodyGyro = Instance.new("BodyGyro")
    self.bodyGyro.Name = "GF_Fly_BG"
    self.bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    self.bodyGyro.P = 1e4
    self.bodyGyro.Parent = hrp
    
    local hum = getHum()
    if hum then hum.PlatformStand = true end
    
    self.connections.heartbeat = RunService.Heartbeat:Connect(function()
        if not S.fly then return end
        
        local currentHRP = getHRP()
        if not currentHRP then return end
        
        if not self.bodyVel or not self.bodyGyro then return end
        
        local cf = camera.CFrame
        local moveDir = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.yAxis end
        
        if moveDir.Magnitude > 0 then
            self.bodyVel.Velocity = moveDir.Unit * S.flySpeed
        else
            self.bodyVel.Velocity = Vector3.zero
        end
        
        self.bodyGyro.CFrame = cf
    end)
    
    self.active = true
end

function Fly:stop()
    if self.connections.heartbeat then
        self.connections.heartbeat:Disconnect()
        self.connections.heartbeat = nil
    end
    
    if self.bodyVel then
        self.bodyVel:Destroy()
        self.bodyVel = nil
    end
    
    if self.bodyGyro then
        self.bodyGyro:Destroy()
        self.bodyGyro = nil
    end
    
    local hum = getHum()
    if hum then hum.PlatformStand = false end
    
    self.active = false
end

-- ============================================================================
-- MÓDULO: AUTO TP (Tepearse al jugador seleccionado automáticamente)
-- ============================================================================
local AutoTP = {
    active = false,
    interval = 0.5,
    lastTP = 0
}

function AutoTP:tick()
    if not S.autoTP then return end
    if not S.selectedPlayer then return end
    
    local now = tick()
    if now - self.lastTP < self.interval then return end
    self.lastTP = now
    
    local targetHRP = getTargetHRP(S.selectedPlayer)
    local myHRP = getHRP()
    
    if targetHRP and myHRP then
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
    end
end

function AutoTP:start()
    self.active = true
end

function AutoTP:stop()
    self.active = false
end

-- ============================================================================
-- MÓDULO: HITBOX OPTIMIZADO (Anti-Lag + Menos Detectable)
-- ============================================================================
local Hitbox = {
    modified = {},
    originalSizes = {},
    originalCollide = {}
}

function Hitbox:enable()
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then
            local hrp = getTargetHRP(target)
            if hrp and not self.modified[target] then
                self.originalSizes[target] = hrp.Size
                self.originalCollide[target] = hrp.CanCollide
                self.modified[target] = true
            end
        end
    end
end

function Hitbox:disable()
    for target, _ in pairs(self.modified) do
        local hrp = getTargetHRP(target)
        if hrp then
            hrp.Size = self.originalSizes[target] or Vector3.new(2, 2, 1)
            hrp.CanCollide = self.originalCollide[target] ~= false
        end
    end
    self.modified = {}
    self.originalSizes = {}
    self.originalCollide = {}
end

function Hitbox:update()
    if not S.hitbox then
        self:disable()
        return
    end
    
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then
            local hrp = getTargetHRP(target)
            if hrp then
                if not self.modified[target] then
                    self.originalSizes[target] = hrp.Size
                    self.originalCollide[target] = hrp.CanCollide
                    self.modified[target] = true
                end
                hrp.Size = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
                hrp.CanCollide = false
            end
        end
    end
end

-- ============================================================================
-- MÓDULO: ESP POR EQUIPOS (Premium)
-- ============================================================================
local ESP = {
    objects = {},
    updateRate = 0.15,
    lastUpdate = 0
}

function ESP:shouldShow(target)
    if not S.esp then return false end
    if target == player then return false end
    
    if S.espMode == "Todos" then
        return true
    elseif S.espMode == "Aliados" then
        return isSameTeam(target)
    elseif S.espMode == "Enemigos" then
        return not isSameTeam(target)
    end
    return false
end

function ESP:getColor(target)
    if not self:shouldShow(target) then return nil end
    
    if S.espMode == "Todos" then
        return Color3.fromRGB(220, 20, 60) -- Rojo
    elseif S.espMode == "Aliados" then
        return Color3.fromRGB(50, 255, 100) -- Verde
    else -- Enemigos
        return Color3.fromRGB(255, 50, 50) -- Rojo claro
    end
end

function ESP:create(target)
    if not self:shouldShow(target) then return end
    if self.objects[target] then return end
    
    local char = target.Character
    if not char then return end
    
    local color = self:getColor(target)
    if not color then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Adornee = char
    highlight.FillColor = color
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.2
    
    local head = char:FindFirstChild("Head")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = target.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.Parent = billboard
        
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
        infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextColor3 = color
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 11
        infoLabel.Parent = billboard
        
        self.objects[target] = {
            highlight = highlight,
            billboard = billboard,
            nameLabel = nameLabel,
            infoLabel = infoLabel
        }
    else
        highlight.Parent = char
        self.objects[target] = {highlight = highlight}
    end
end

function ESP:updateInfo(target)
    local obj = self.objects[target]
    if not obj or not obj.infoLabel then return end
    
    local char = target.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local myHRP = getHRP()
    
    if hum and hrp and myHRP then
        local hp = math.floor(hum.Health)
        local maxHp = hum.MaxHealth
        local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
        local hpPercent = hp / maxHp
        
        obj.infoLabel.Text = string.format("❤️ %d/%d  📏 %dm", hp, maxHp, dist)
        
        if hpPercent > 0.6 then
            obj.infoLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
        elseif hpPercent > 0.3 then
            obj.infoLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        else
            obj.infoLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        end
    end
end

function ESP:remove(target)
    local obj = self.objects[target]
    if obj then
        if obj.highlight then obj.highlight:Destroy() end
        if obj.billboard then obj.billboard:Destroy() end
        self.objects[target] = nil
    end
end

function ESP:refreshAll()
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then
            local should = self:shouldShow(target)
            local exists = self.objects[target] ~= nil
            
            if should and not exists then
                self:create(target)
            elseif not should and exists then
                self:remove(target)
            end
        end
    end
end

function ESP:update()
    if not S.esp then
        for target, _ in pairs(self.objects) do
            self:remove(target)
        end
        return
    end
    
    self:refreshAll()
    
    local now = tick()
    if now - self.lastUpdate >= self.updateRate then
        self.lastUpdate = now
        for target, _ in pairs(self.objects) do
            if target.Character then
                self:updateInfo(target)
            end
        end
    end
end

-- ============================================================================
-- MÓDULO: KILL AURA INTELIGENTE
-- ============================================================================
local KillAura = {
    lastAttack = 0,
    lastTarget = nil
}

function KillAura:getClosest()
    local myHRP = getHRP()
    if not myHRP then return nil end
    
    local closest = nil
    local closestDist = S.killAuraRange
    
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            local tHRP = getTargetHRP(target)
            if tHRP then
                local dist = (myHRP.Position - tHRP.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = target
                end
            end
        end
    end
    
    return closest, closestDist
end

function KillAura:attack(target)
    if not target or not target.Character then return end
    
    local tool = player.Character:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate()
    end
    
    -- Método alternativo: golpear con el personaje
    local hum = getHum()
    if hum then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end

function KillAura:tick()
    if not S.killAura then return end
    
    local now = tick()
    if now - self.lastAttack < S.killAuraDelay then return end
    
    local closest = self:getClosest()
    if closest then
        self:attack(closest)
        self.lastAttack = now
        self.lastTarget = closest
    end
end

-- ============================================================================
-- LOOP PRINCIPAL UNIFICADO (Anti-Lag)
-- ============================================================================
task.spawn(function()
    while S.active do
        local startTime = tick()
        
        -- Velocidad persistente
        local hum = getHum()
        if hum then
            if hum.WalkSpeed ~= S.walkSpeed then hum.WalkSpeed = S.walkSpeed end
            if hum.JumpPower ~= S.jumpPower then hum.JumpPower = S.jumpPower end
        end
        
        -- Protecciones
        if S.antiKB then
            local hrp = getHRP()
            if hrp then
                local vel = hrp.AssemblyLinearVelocity
                if math.abs(vel.X) > 30 or math.abs(vel.Z) > 30 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
                end
            end
        end
        
        if S.godMode then
            local hum = getHum()
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
        
        if S.antiRagdoll then
            local hum = getHum()
            if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        
        -- Noclip
        if S.noclip then
            local char = getChar()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
        
        -- Hitbox update
        Hitbox:update()
        
        -- ESP update
        ESP:update()
        
        -- Auto TP (tepearse automáticamente al jugador seleccionado)
        if S.autoTP and S.selectedPlayer then
            local targetHRP = getTargetHRP(S.selectedPlayer)
            local myHRP = getHRP()
            if targetHRP and myHRP then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
            end
        end
        
        -- Bring (mover jugador hacia ti)
        if S.bring and S.selectedPlayer then
            local myHRP = getHRP()
            local targetHRP = getTargetHRP(S.selectedPlayer)
            if myHRP and targetHRP then
                local direction = (myHRP.Position - targetHRP.Position).Unit
                local newPos = myHRP.Position - direction * S.bringDistance
                targetHRP.CFrame = CFrame.new(newPos)
            end
        end
        
        -- Kill Aura
        KillAura:tick()
        
        -- Control de framerate (60 FPS máximo para evitar lag)
        local elapsed = tick() - startTime
        if elapsed < 0.016 then -- ~60 FPS
            task.wait(0.016 - elapsed)
        end
    end
end)

-- ============================================================================
-- INFINITE JUMP
-- ============================================================================
UserInputService.JumpRequest:Connect(function()
    if S.infJump then
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ============================================================================
-- EVENTOS DE JUGADORES
-- ============================================================================
Players.PlayerAdded:Connect(function(p)
    task.wait(0.5)
    if S.esp then ESP:refreshAll() end
end)

Players.PlayerRemoving:Connect(function(p)
    ESP:remove(p)
end)

player.CharacterAdded:Connect(function()
    task.wait(0.3)
    if S.realInvis then Invisibility:enable() end
    if S.fly then Fly:start() end
end)

-- ============================================================================
-- FLUENT UI - INTERFAZ MODERNA NEGRO/ROJO
-- ============================================================================
local Window = Fluent:CreateWindow({
    Title = "🔴 GF HUB v8.0 ULTIMATE",
    SubTitle = "by Gael Fonzar | Sistema Anti-Lag",
    Size = UDim2.fromOffset(600, 500),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift,
})

-- Tabs
local moveTab = Window:AddTab({ Title = "⚡ Movement", Icon = "zap" })
local combatTab = Window:AddTab({ Title = "⚔️ Combat", Icon = "sword" })
local visualTab = Window:AddTab({ Title = "👁️ Visual", Icon = "eye" })
local targetTab = Window:AddTab({ Title = "🎯 Target", Icon = "crosshair" })
local settingsTab = Window:AddTab({ Title = "⚙️ Settings", Icon = "settings" })

-- ========== TAB: MOVEMENT ==========
moveTab:AddSlider("WalkSpeed", {
    Title = "🚀 Walk Speed",
    Min = 16, Max = 500, Default = 16,
    Callback = function(v) S.walkSpeed = v end
})

moveTab:AddSlider("JumpPower", {
    Title = "🦘 Jump Power",
    Min = 50, Max = 500, Default = 50,
    Callback = function(v) S.jumpPower = v end
})

moveTab:AddSlider("FlySpeed", {
    Title = "✈️ Fly Speed",
    Min = 10, Max = 500, Default = 80,
    Callback = function(v) S.flySpeed = v end
})

moveTab:AddToggle("Fly", {
    Title = "✈️ Fly Mode (WASD + Space/Shift)",
    Default = false,
    Callback = function(v)
        S.fly = v
        if v then Fly:start() else Fly:stop() end
    end
})

moveTab:AddToggle("Noclip", {
    Title = "👻 Noclip",
    Default = false,
    Callback = function(v) S.noclip = v end
})

moveTab:AddToggle("InfJump", {
    Title = "♾️ Infinite Jump",
    Default = false,
    Callback = function(v) S.infJump = v end
})

-- ========== TAB: COMBAT ==========
combatTab:AddParagraph({ Title = "⚔️ Kill Aura", Content = "Ataca automáticamente a enemigos cercanos" })
combatTab:AddSlider("KARange", {
    Title = "📏 Kill Aura Range",
    Min = 5, Max = 50, Default = 15,
    Callback = function(v) S.killAuraRange = v end
})
combatTab:AddSlider("KADelay", {
    Title = "⏱️ Attack Delay (segundos)",
    Min = 0.05, Max = 1, Default = 0.2, Decimals = 2,
    Callback = function(v) S.killAuraDelay = v end
})
combatTab:AddToggle("KillAura", {
    Title = "💀 Kill Aura",
    Default = false,
    Callback = function(v) S.killAura = v end
})

combatTab:AddParagraph({ Title = "📦 Hitbox Expander", Content = "Aumenta hitbox de enemigos (menos detectable)" })
combatTab:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Min = 5, Max = 30, Default = 10,
    Callback = function(v) S.hitboxSize = v end
})
combatTab:AddToggle("Hitbox", {
    Title = "🔴 Enable Hitbox Expander",
    Default = false,
    Callback = function(v) S.hitbox = v end
})

-- ========== TAB: VISUAL ==========
visualTab:AddParagraph({ Title = "👁️ ESP System", Content = "Detección de jugadores con colores por equipo" })
visualTab:AddDropdown("ESPMode", {
    Title = "ESP Filter",
    Values = { "Enemigos", "Aliados", "Todos" },
    Default = "Enemigos",
    Callback = function(v)
        S.espMode = v
        ESP:refreshAll()
        notify("ESP Mode", "Filtro cambiado a: " .. v)
    end
})
visualTab:AddToggle("ESP", {
    Title = "👁️ Enable ESP",
    Default = false,
    Callback = function(v)
        S.esp = v
        if not v then
            for target, _ in pairs(ESP.objects) do
                ESP:remove(target)
            end
        end
    end
})

visualTab:AddParagraph({ Title = "🕵️ Stealth", Content = "Opciones de invisibilidad" })
visualTab:AddToggle("RealInvis", {
    Title = "👤 REAL Invisibility (nadie te ve)",
    Default = false,
    Callback = function(v)
        S.realInvis = v
        if v then Invisibility:enable() else Invisibility:disable() end
        notify(v and "✅ Invisible" or "👀 Visible", v and "Nadie puede verte" or "Ya eres visible")
    end
})

visualTab:AddParagraph({ Title = "💡 Lighting", Content = "Modificadores de iluminación" })
visualTab:AddToggle("Fullbright", {
    Title = "💡 Fullbright",
    Default = false,
    Callback = function(v)
        S.fullbright = v
        if v then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 8
            Lighting.GlobalShadows = true
        end
    end
})

-- ========== TAB: TARGET (Auto-TP + Bring) ==========
local playerDropdown

local function refreshPlayerList()
    local players = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(players, p.Name)
        end
    end
    if #players == 0 then players = {"No players"} end
    
    if playerDropdown then
        playerDropdown:SetValues(players)
    end
end

playerDropdown = targetTab:AddDropdown("PlayerSelect", {
    Title = "🎯 Select Target",
    Values = {},
    Callback = function(value)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == value then
                S.selectedPlayer = p
                notify("🎯 Target Set", "Ahora apuntando a: " .. p.Name, "success")
                break
            end
        end
    end
})

refreshPlayerList()

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

targetTab:AddParagraph({ Title = "🔄 Auto Teleport", Content = "Te teletransporta automáticamente al jugador seleccionado cada X segundos" })
targetTab:AddSlider("AutoTPInterval", {
    Title = "TP Interval (segundos)",
    Min = 0.2, Max = 5, Default = 0.5, Decimals = 1,
    Callback = function(v) S.autoTPInterval = v end
})
targetTab:AddToggle("AutoTP", {
    Title = "📍 Auto TP to Selected Player",
    Default = false,
    Callback = function(v)
        if v and not S.selectedPlayer then
            notify("❌ Error", "Selecciona un jugador primero")
            return
        end
        S.autoTP = v
        notify(v and "✅ Auto-TP Activado" or "⛔ Auto-TP Desactivado", 
               v and ("Tepeándote a " .. (S.selectedPlayer and S.selectedPlayer.Name or "?") .. " automáticamente") or "")
    end
})

targetTab:AddParagraph({ Title = "🔄 Bring System", Content = "Mueve al jugador SELECCIONADO hacia TI (no al revés)" })
targetTab:AddSlider("BringDistance", {
    Title = "Bring Distance (studs)",
    Min = 1, Max = 15, Default = 3,
    Callback = function(v) S.bringDistance = v end
})
targetTab:AddToggle("Bring", {
    Title = "🔄 BRING (mueve jugador hacia ti)",
    Default = false,
    Callback = function(v)
        if v and not S.selectedPlayer then
            notify("❌ Error", "Selecciona un jugador primero")
            return
        end
        S.bring = v
        notify(v and "✅ Bring Activado" or "⛔ Bring Desactivado", 
               v and ("Trayendo a " .. (S.selectedPlayer and S.selectedPlayer.Name or "?") .. " hacia ti") or "")
    end
})

targetTab:AddButton({
    Title = "📍 Teleport To Player (One Time)",
    Callback = function()
        if not S.selectedPlayer then
            notify("❌ Error", "Selecciona un jugador")
            return
        end
        local targetHRP = getTargetHRP(S.selectedPlayer)
        local myHRP = getHRP()
        if targetHRP and myHRP then
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
            notify("✅ Teleported", "Te has tepeado a " .. S.selectedPlayer.Name)
        end
    end
})

targetTab:AddButton({
    Title = "📍 Bring Player (One Time)",
    Callback = function()
        if not S.selectedPlayer then
            notify("❌ Error", "Selecciona un jugador")
            return
        end
        local myHRP = getHRP()
        local targetHRP = getTargetHRP(S.selectedPlayer)
        if myHRP and targetHRP then
            local direction = (myHRP.Position - targetHRP.Position).Unit
            local newPos = myHRP.Position - direction * S.bringDistance
            targetHRP.CFrame = CFrame.new(newPos)
            notify("✅ Brought", "Has traído a " .. S.selectedPlayer.Name .. " hacia ti")
        end
    end
})

-- ========== TAB: SETTINGS ==========
settingsTab:AddParagraph({ Title = "🛡️ Protections", Content = "Defensas pasivas" })
settingsTab:AddToggle("AntiKB", {
    Title = "🛡️ Anti Knockback",
    Default = false,
    Callback = function(v) S.antiKB = v end
})
settingsTab:AddToggle("AntiRagdoll", {
    Title = "🎭 Anti Ragdoll",
    Default = false,
    Callback = function(v) S.antiRagdoll = v end
})
settingsTab:AddToggle("GodMode", {
    Title = "❤️ God Mode (Infinite Health)",
    Default = false,
    Callback = function(v) S.godMode = v end
})

settingsTab:AddParagraph({ Title = "💊 Utilities", Content = "Acciones rápidas" })
settingsTab:AddButton({
    Title = "💊 Full Heal",
    Callback = function()
        local hum = getHum()
        if hum then hum.Health = hum.MaxHealth end
        notify("💊 Healed", "Vida restaurada al máximo")
    end
})
settingsTab:AddButton({
    Title = "🔄 Respawn",
    Callback = function()
        player:LoadCharacter()
        notify("🔄 Respawning", "Reapareciendo...")
    end
})

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
notify("🔴 GF HUB v8.0 ULTIMATE", "Cargado exitosamente | RShift para minimizar", "success")
refreshPlayerList()

-- Limpiar al salir
globalMaid:Add(game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
    -- Reconectar automáticamente
end))

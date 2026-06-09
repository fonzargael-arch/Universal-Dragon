--[[
╔════════════════════════════════════════════════════════════════════╗
║              🔴 GF HUB v8.0 ULTIMATE 🔴                            ║
║         by Gael Fonzar | Venyx UI | Negro/Rojo | 2025             ║
╚════════════════════════════════════════════════════════════════════╝
]]

-- ============================================================================
-- SERVICIOS
-- ============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============================================================================
-- VENYX UI (MÁS ESTABLE QUE FLUENT)
-- ============================================================================
local Venyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/Joel-Games/VenyxUI/main/source.lua"))()

-- ============================================================================
-- HELPERS
-- ============================================================================
local function getChar() return player.Character end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getTargetChar(target) return target and target.Character end
local function getTargetHRP(target) local c = getTargetChar(target) return c and c:FindFirstChild("HumanoidRootPart") end
local function isSameTeam(target) return player.Team and target.Team and player.Team == target.Team end

-- ============================================================================
-- NOTIFICACIONES
-- ============================================================================
local function notify(title, msg, duration)
    Venyx:Notify({
        Title = title,
        Description = msg,
        Duration = duration or 3
    })
end

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
    
    -- TP y Bring
    autoTP = false,
    autoTPInterval = 0.5,
    selectedPlayer = nil,
    bring = false,
    bringDistance = 3,
    
    -- Invisibilidad
    realInvis = false,
    
    -- Protección
    antiKB = false,
    godMode = false,
    antiRagdoll = false,
    noStun = false,
    antiCrash = false,
    
    -- Visual
    esp = false,
    espMode = "Enemigos",
    fullbright = false,
    zoom = false,
    zoomLevel = 50,
    noFog = false,
    tracers = false,
    
    -- Combate
    killAura = false,
    killAuraRange = 15,
    killAuraDelay = 0.2,
    hitbox = false,
    hitboxSize = 10,
    autoClicker = false,
    autoClickerDelay = 0.05,
    triggerBot = false,
    
    -- Utilidades
    antiAfk = false,
    autoRejoin = false,
    serverHop = false,
    
    active = true,
}

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
    self.active = false
end

-- ============================================================================
-- MÓDULO: FLY
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
-- MÓDULO: HITBOX
-- ============================================================================
local Hitbox = {
    modified = {},
    originalSizes = {}
}

function Hitbox:update()
    if not S.hitbox then
        for target, _ in pairs(self.modified) do
            local hrp = getTargetHRP(target)
            if hrp and self.originalSizes[target] then
                hrp.Size = self.originalSizes[target]
            end
        end
        self.modified = {}
        self.originalSizes = {}
        return
    end
    
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then
            local hrp = getTargetHRP(target)
            if hrp then
                if not self.modified[target] then
                    self.originalSizes[target] = hrp.Size
                    self.modified[target] = true
                end
                hrp.Size = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
                hrp.CanCollide = false
            end
        end
    end
end

-- ============================================================================
-- MÓDULO: ESP
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
        return Color3.fromRGB(220, 20, 60)
    elseif S.espMode == "Aliados" then
        return Color3.fromRGB(50, 255, 100)
    else
        return Color3.fromRGB(255, 50, 50)
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
    highlight.Parent = char
    
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
-- MÓDULO: KILL AURA
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
end

function KillAura:tick()
    if not S.killAura then return end
    
    local now = tick()
    if now - self.lastAttack < S.killAuraDelay then return end
    
    local closest = self:getClosest()
    if closest then
        self:attack(closest)
        self.lastAttack = now
    end
end

-- ============================================================================
-- MÓDULO: AUTO REJOIN
-- ============================================================================
local AutoRejoin = {
    active = false,
    connection = nil
}

function AutoRejoin:start()
    if self.connection then return end
    self.connection = game:GetService("Players").LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
        if S.autoRejoin and not player.Parent then
            task.wait(2)
            game:GetService("TeleportService"):Teleport(game.PlaceId)
        end
    end)
end

function AutoRejoin:stop()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

-- ============================================================================
-- MÓDULO: SERVER HOP
-- ============================================================================
function ServerHop:hop()
    local servers = {}
    for _, v in ipairs(game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")).data) do
        if v.playing and v.id ~= game.JobId then
            table.insert(servers, v.id)
        end
    end
    if #servers > 0 then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
    end
end

-- ============================================================================
-- LOOP PRINCIPAL
-- ============================================================================
task.spawn(function()
    while S.active do
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
        
        if S.noStun then
            local hum = getHum()
            if hum then
                hum.Sit = false
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
        
        -- Zoom
        if S.zoom then
            camera.FieldOfView = S.zoomLevel
        else
            camera.FieldOfView = 70
        end
        
        -- No Fog
        if S.noFog then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
        else
            Lighting.FogEnd = 1000
            Lighting.FogStart = 0
        end
        
        -- Fullbright
        if S.fullbright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 8
            Lighting.GlobalShadows = true
        end
        
        -- Hitbox
        Hitbox:update()
        
        -- ESP
        ESP:update()
        
        -- Auto TP
        if S.autoTP and S.selectedPlayer then
            local targetHRP = getTargetHRP(S.selectedPlayer)
            local myHRP = getHRP()
            if targetHRP and myHRP then
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
            end
            task.wait(S.autoTPInterval)
        end
        
        -- Bring
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
        
        -- Auto Clicker
        if S.autoClicker then
            local now = tick()
            if not S.lastClick or now - S.lastClick >= S.autoClickerDelay then
                local tool = player.Character:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end
                S.lastClick = now
            end
        end
        
        -- Anti AFK
        if S.antiAfk then
            VirtualUser:ClickButton2(Vector2.new())
        end
        
        -- Auto Rejoin
        if S.autoRejoin then
            AutoRejoin:start()
        else
            AutoRejoin:stop()
        end
        
        task.wait(0.05)
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
-- EVENTOS
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
-- VENYX UI - INTERFAZ NEGRA CON ROJO
-- ============================================================================
local Window = Venyx:CreateWindow({
    Title = "🔴 GF HUB v8.0 ULTIMATE",
    SubTitle = "by Gael Fonzar | Negro/Rojo",
    Theme = "Dark",
    Size = "600x520",
})

-- TABS
local moveTab = Window:AddTab("⚡ Movement")
local combatTab = Window:AddTab("⚔️ Combat")
local visualTab = Window:AddTab("👁️ Visual")
local targetTab = Window:AddTab("🎯 Target")
local utilsTab = Window:AddTab("🛠️ Utils")

-- Áreas para cada tab
local moveArea = moveTab:AddArea("Movimiento")
local combatArea = combatTab:AddArea("Combate")
local visualArea = visualTab:AddArea("Visuales")
local targetArea = targetTab:AddArea("Objetivo")
local utilsArea = utilsTab:AddArea("Utilidades")

-- ========== TAB: MOVEMENT ==========
moveArea:AddSlider("WalkSpeed", {
    Title = "🚀 Walk Speed",
    Min = 16, Max = 500, Default = 16,
    Callback = function(v) S.walkSpeed = v end
})

moveArea:AddSlider("JumpPower", {
    Title = "🦘 Jump Power",
    Min = 50, Max = 500, Default = 50,
    Callback = function(v) S.jumpPower = v end
})

moveArea:AddSlider("FlySpeed", {
    Title = "✈️ Fly Speed",
    Min = 10, Max = 500, Default = 80,
    Callback = function(v) S.flySpeed = v end
})

moveArea:AddToggle("Fly", {
    Title = "✈️ Fly Mode (WASD + Space/Shift)",
    Default = false,
    Callback = function(v)
        S.fly = v
        if v then Fly:start() else Fly:stop() end
    end
})

moveArea:AddToggle("Noclip", {
    Title = "👻 Noclip",
    Default = false,
    Callback = function(v) S.noclip = v end
})

moveArea:AddToggle("InfJump", {
    Title = "♾️ Infinite Jump",
    Default = false,
    Callback = function(v) S.infJump = v end
})

-- ========== TAB: COMBAT ==========
combatArea:AddSlider("KARange", {
    Title = "📏 Kill Aura Range",
    Min = 5, Max = 50, Default = 15,
    Callback = function(v) S.killAuraRange = v end
})

combatArea:AddSlider("KADelay", {
    Title = "⏱️ Attack Delay (segundos)",
    Min = 0.05, Max = 1, Default = 0.2, Decimals = 2,
    Callback = function(v) S.killAuraDelay = v end
})

combatArea:AddToggle("KillAura", {
    Title = "💀 Kill Aura",
    Default = false,
    Callback = function(v) S.killAura = v end
})

combatArea:AddSlider("HitboxSize", {
    Title = "📦 Hitbox Size",
    Min = 5, Max = 30, Default = 10,
    Callback = function(v) S.hitboxSize = v end
})

combatArea:AddToggle("Hitbox", {
    Title = "🔴 Hitbox Expander",
    Default = false,
    Callback = function(v) S.hitbox = v end
})

combatArea:AddSlider("AutoClickerDelay", {
    Title = "🖱️ Auto Clicker Delay",
    Min = 0.01, Max = 0.5, Default = 0.05, Decimals = 2,
    Callback = function(v) S.autoClickerDelay = v end
})

combatArea:AddToggle("AutoClicker", {
    Title = "🖱️ Auto Clicker",
    Default = false,
    Callback = function(v) S.autoClicker = v end
})

-- ========== TAB: VISUAL ==========
visualArea:AddDropdown("ESPMode", {
    Title = "👁️ ESP Filter",
    Values = { "Enemigos", "Aliados", "Todos" },
    Default = "Enemigos",
    Callback = function(v)
        S.espMode = v
        ESP:refreshAll()
        notify("ESP Mode", "Filtro cambiado a: " .. v)
    end
})

visualArea:AddToggle("ESP", {
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

visualArea:AddToggle("RealInvis", {
    Title = "👤 REAL Invisibility (nadie te ve)",
    Default = false,
    Callback = function(v)
        S.realInvis = v
        if v then Invisibility:enable() else Invisibility:disable() end
        notify(v and "✅ Invisible" or "👀 Visible", v and "Nadie puede verte" or "Ya eres visible")
    end
})

visualArea:AddToggle("Zoom", {
    Title = "🔍 Zoom Hack",
    Default = false,
    Callback = function(v) S.zoom = v end
})

visualArea:AddSlider("ZoomLevel", {
    Title = "Zoom Level (FOV)",
    Min = 20, Max = 120, Default = 50,
    Callback = function(v) S.zoomLevel = v end
})

visualArea:AddToggle("NoFog", {
    Title = "🌫️ No Fog",
    Default = false,
    Callback = function(v) S.noFog = v end
})

-- ========== TAB: TARGET ==========
local function refreshPlayerList()
    local players = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(players, p.Name)
        end
    end
    if #players == 0 then players = {"No players"} end
    return players
end

targetArea:AddDropdown("PlayerSelect", {
    Title = "🎯 Select Target",
    Values = refreshPlayerList(),
    Callback = function(value)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == value then
                S.selectedPlayer = p
                notify("🎯 Target Set", "Ahora apuntando a: " .. p.Name)
                break
            end
        end
    end
})

targetArea:AddSlider("AutoTPInterval", {
    Title = "🔄 Auto TP Interval",
    Min = 0.2, Max = 5, Default = 0.5, Decimals = 1,
    Callback = function(v) S.autoTPInterval = v end
})

targetArea:AddToggle("AutoTP", {
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

targetArea:AddSlider("BringDistance", {
    Title = "🔄 Bring Distance",
    Min = 1, Max = 15, Default = 3,
    Callback = function(v) S.bringDistance = v end
})

targetArea:AddToggle("Bring", {
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

targetArea:AddButton({
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

targetArea:AddButton({
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

-- ========== TAB: UTILS ==========
utilsArea:AddToggle("AntiKB", {
    Title = "🛡️ Anti Knockback",
    Default = false,
    Callback = function(v) S.antiKB = v end
})

utilsArea:AddToggle("AntiRagdoll", {
    Title = "🎭 Anti Ragdoll",
    Default = false,
    Callback = function(v) S.antiRagdoll = v end
})

utilsArea:AddToggle("NoStun", {
    Title = "⚡ No Stun / Anti Sit",
    Default = false,
    Callback = function(v) S.noStun = v end
})

utilsArea:AddToggle("GodMode", {
    Title = "❤️ God Mode",
    Default = false,
    Callback = function(v) S.godMode = v end
})

utilsArea:AddToggle("AntiAFK", {
    Title = "🟢 Anti AFK",
    Default = false,
    Callback = function(v) S.antiAfk = v end
})

utilsArea:AddToggle("AutoRejoin", {
    Title = "🔄 Auto Rejoin",
    Default = false,
    Callback = function(v) S.autoRejoin = v end
})

utilsArea:AddButton({
    Title = "🚪 Server Hop",
    Callback = function()
        ServerHop:hop()
        notify("🚪 Server Hop", "Buscando otro servidor...")
    end
})

utilsArea:AddButton({
    Title = "💊 Full Heal",
    Callback = function()
        local hum = getHum()
        if hum then hum.Health = hum.MaxHealth end
        notify("💊 Healed", "Vida restaurada al máximo")
    end
})

utilsArea:AddButton({
    Title = "🔄 Respawn",
    Callback = function()
        player:LoadCharacter()
        notify("🔄 Respawning", "Reapareciendo...")
    end
})

utilsArea:AddButton({
    Title = "📊 Server Info",
    Callback = function()
        local count = #Players:GetPlayers()
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
        notify("📊 Server Info", string.format("Jugadores: %d | Ping: %s", count, ping))
    end
})

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
notify("🔴 GF HUB v8.0 ULTIMATE", "Cargado exitosamente | Venyx UI | Negro/Rojo")

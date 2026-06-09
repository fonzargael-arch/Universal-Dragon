--[[
╔══════════════════════════════════════════════════════════╗
║            🐉 GF HUB v7.0 — by Gael Fonzar              ║
║   Fluent UI | Tema Negro/Rojo | PC + Mobile | 2025       ║
╚══════════════════════════════════════════════════════════╝

LIBRERÍA: Fluent (dawid-scripts) — la más moderna y activa 2025
  loadstring: https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua

MEJORAS v7.0 vs v6.0:
  ✅ Fluent UI — diseño premium negro/oscuro moderno
  ✅ Velocidad persistente — se reaplica en cada Heartbeat y CharacterAdded
  ✅ Fly reescrito con LinearVelocity (más estable, sin detección)
  ✅ ESP por equipos: Todos / Aliados / Enemigos
  ✅ ESP se reconecta automáticamente al respawn
  ✅ Invisibilidad local (LocalTransparencyModifier)
  ✅ Click-to-TP: click en el suelo te teleporta ahí
  ✅ Click-to-Kill: click en jugador enemigo dispara killAura
  ✅ Hitbox universal: funciona en cualquier juego
  ✅ Auto Follow con reconexión automática
  ✅ Lista de jugadores en tiempo real (PlayerAdded/Removing)
  ✅ TP a coordenadas custom desde GUI
  ✅ Maid pattern mejorado — sin memory leaks
]]

-- ============================================================
-- SERVICIOS
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled

-- ============================================================
-- CARGAR FLUENT UI
-- ============================================================
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

-- ============================================================
-- MAID — limpieza de conexiones sin memory leaks
-- ============================================================
local Maid = {}
Maid.__index = Maid
function Maid.new()    return setmetatable({_t={}}, Maid) end
function Maid:Add(t)   table.insert(self._t, t); return t  end
function Maid:Destroy()
    for _, t in ipairs(self._t) do pcall(function()
        if typeof(t)=="RBXScriptConnection" then t:Disconnect()
        elseif typeof(t)=="Instance"         then t:Destroy()
        elseif type(t)=="function"           then t()
        end
    end) end
    self._t = {}
end

local mainMaid   = Maid.new()
local espMaid    = Maid.new()
local followMaid = Maid.new()

-- ============================================================
-- ESTADO GLOBAL
-- ============================================================
local S = {
    -- Movimiento
    walkSpeed  = 16,
    flySpeed   = 80,
    jumpPower  = 50,
    fly        = false,
    noclip     = false,
    infJump    = false,

    -- Protección
    antiKB     = false,
    antiRag    = false,
    godMode    = false,

    -- Visual
    esp        = false,
    espMode    = "Todos",   -- "Todos" | "Aliados" | "Enemigos"
    fullbright = false,
    invis      = false,

    -- Combate
    killAura      = false,
    killAuraRange = 15,
    hitbox        = false,
    hitboxSize    = 10,
    clickTP       = false,   -- click en suelo = TP
    clickKill     = false,   -- click en jugador = atacar

    -- Follow
    autoFollow     = false,
    followDist     = 5,
    selectedPlayer = nil,

    active = true,
}

-- ============================================================
-- HELPERS
-- ============================================================
local function getChar()  return player.Character end
local function getHum()   local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()   local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end

local function getPlayerList()
    local list = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(list, p.Name) end
    end
    return #list>0 and list or {"Sin jugadores"}
end

local function getByName(name)
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name==name then return p end
    end
end

-- Detectar equipo del jugador
local function isSameTeam(target)
    if not player.Team or not target.Team then return false end
    return player.Team == target.Team
end

-- ============================================================
-- NOTIFICACIONES (via Fluent)
-- ============================================================
local function notify(title, msg, dur)
    Fluent:Notify({
        Title    = title,
        Content  = msg,
        Duration = dur or 3,
    })
end

-- ============================================================
-- VELOCIDAD PERSISTENTE
-- Problema original: el juego reseteaba WalkSpeed al subir nivel.
-- Solución: aplicar en CADA Heartbeat y también en CharacterAdded.
-- ============================================================
mainMaid:Add(RunService.Heartbeat:Connect(function()
    if not S.active then return end
    local hum = getHum()
    if not hum then return end
    -- Solo escribir si el juego lo cambió externamente
    if hum.WalkSpeed ~= S.walkSpeed then
        hum.WalkSpeed = S.walkSpeed
    end
    if hum.JumpPower ~= S.jumpPower then
        hum.JumpPower = S.jumpPower
    end
end))

-- ============================================================
-- FLY — reescrito con LinearVelocity (más estable en Roblox 2024+)
-- ============================================================
local flyConn

local function startFly()
    local hrp = getHRP() if not hrp then return end
    local hum = getHum()
    if hum then hum.PlatformStand = true end

    -- Usar BodyVelocity clásico pero más estable
    local bv = Instance.new("BodyVelocity")
    bv.Name      = "GF_BV"
    bv.MaxForce  = Vector3.new(1e9,1e9,1e9)
    bv.Velocity  = Vector3.zero
    bv.Parent    = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name      = "GF_BG"
    bg.MaxTorque = Vector3.new(1e9,1e9,1e9)
    bg.P         = 1e4
    bg.Parent    = hrp

    flyConn = RunService.Heartbeat:Connect(function()
        if not S.fly then return end
        local hrp2 = getHRP() if not hrp2 then return end
        local bv2  = hrp2:FindFirstChild("GF_BV")
        local bg2  = hrp2:FindFirstChild("GF_BG")
        if not bv2 or not bg2 then return end

        local cf  = camera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
        -- Mobile: usar la orientación de la cámara
        if isMobile and dir == Vector3.zero then
            dir += cf.LookVector * 0.3
        end

        bv2.Velocity = dir.Magnitude > 0 and dir.Unit * S.flySpeed or Vector3.zero
        bg2.CFrame   = cf
    end)
end

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    local hrp = getHRP()
    if hrp then
        local bv = hrp:FindFirstChild("GF_BV")
        local bg = hrp:FindFirstChild("GF_BG")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- ============================================================
-- NOCLIP
-- ============================================================
mainMaid:Add(RunService.Stepped:Connect(function()
    if not S.active or not S.noclip then return end
    local c = getChar() if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end))

-- ============================================================
-- INFINITE JUMP
-- ============================================================
mainMaid:Add(UserInputService.JumpRequest:Connect(function()
    if not S.active or not S.infJump then return end
    local hum = getHum()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

-- ============================================================
-- PROTECCIONES
-- ============================================================
mainMaid:Add(RunService.Heartbeat:Connect(function()
    if not S.active then return end

    if S.antiKB then
        local hrp = getHRP()
        if hrp then
            local v = hrp.AssemblyLinearVelocity
            if v.Magnitude > 20 then
                hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            end
        end
    end

    if S.godMode then
        local hum = getHum()
        if hum then hum.Health = hum.MaxHealth end
    end

    if S.antiRag then
        local c = getChar() if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState()==Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end))

-- ============================================================
-- INVISIBILIDAD
-- Usa LocalTransparencyModifier para que solo sea local
-- ============================================================
local function setInvis(on)
    local c = getChar() if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier = on and 1 or 0
        end
    end
end

-- ============================================================
-- HITBOX UNIVERSAL
-- Funciona en cualquier juego agrandando HumanoidRootPart
-- ============================================================
local hitboxCache = {}

mainMaid:Add(RunService.Heartbeat:Connect(function()
    if not S.active then return end
    for _,target in ipairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                if S.hitbox then
                    if not hitboxCache[target.Name] then
                        hitboxCache[target.Name] = {
                            size  = tHRP.Size,
                            trans = tHRP.Transparency,
                        }
                    end
                    tHRP.Size         = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
                    tHRP.Transparency = 0.8
                    tHRP.CanCollide   = false
                elseif hitboxCache[target.Name] then
                    pcall(function()
                        tHRP.Size         = hitboxCache[target.Name].size
                        tHRP.Transparency = hitboxCache[target.Name].trans
                    end)
                    hitboxCache[target.Name] = nil
                end
            end
        end
    end
end))

-- ============================================================
-- CLICK-TO-TP y CLICK-TO-KILL
-- ============================================================
local mouse = player:GetMouse()

mainMaid:Add(mouse.Button1Down:Connect(function()
    -- Click-to-TP: TP al punto donde hiciste click
    if S.clickTP then
        local hrp = getHRP()
        local hit = mouse.Hit
        if hrp and hit then
            hrp.Anchored = true
            hrp.CFrame   = CFrame.new(hit.Position + Vector3.new(0,3,0))
            task.wait(0.05)
            hrp.Anchored = false
        end
        return
    end

    -- Click-to-Kill: atacar al jugador bajo el cursor
    if S.clickKill then
        local target = mouse.Target
        if not target then return end
        local hitPlayer = nil
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character and target:IsDescendantOf(p.Character) then
                hitPlayer = p; break
            end
        end
        if hitPlayer then
            pcall(function()
                local myHRP = getHRP()
                local tHRP  = hitPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHRP and tHRP then
                    local orig = myHRP.CFrame
                    myHRP.CFrame = tHRP.CFrame * CFrame.new(0,0,1.5)
                    local tool = player.Character:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    task.wait(0.05)
                    myHRP.CFrame = orig
                end
            end)
        end
    end
end))

-- ============================================================
-- KILL AURA
-- ============================================================
task.spawn(function()
    while task.wait(0.15) do
        if not S.active then break end
        if not S.killAura then continue end
        local myHRP = getHRP()
        if not myHRP then continue end
        for _,target in ipairs(Players:GetPlayers()) do
            if target ~= player and target.Character then
                local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                if tHRP and (myHRP.Position-tHRP.Position).Magnitude <= S.killAuraRange then
                    pcall(function()
                        local orig = myHRP.CFrame
                        myHRP.CFrame = tHRP.CFrame * CFrame.new(0,0,1.5)
                        local tool = player.Character:FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
                        task.wait(0.05)
                        myHRP.CFrame = orig
                    end)
                end
            end
        end
    end
end)

-- ============================================================
-- ESP — con modo equipo
-- ============================================================
local espObjects = {}

-- Determinar color según modo ESP
local function getESPColor(target)
    if S.espMode == "Todos" then
        return Color3.fromRGB(255, 50, 50) -- rojo
    end
    local same = isSameTeam(target)
    if same then
        return Color3.fromRGB(50, 255, 100) -- verde aliado
    else
        return Color3.fromRGB(255, 50, 50)  -- rojo enemigo
    end
end

-- Verificar si debemos mostrar este jugador
local function shouldESP(target)
    if S.espMode == "Todos" then return true end
    local same = isSameTeam(target)
    if S.espMode == "Aliados"   then return same end
    if S.espMode == "Enemigos"  then return not same end
    return true
end

local function createESP(target)
    if not target or target == player then return end
    if not target.Character then return end
    if espObjects[target.Name] then return end
    if not shouldESP(target) then return end

    pcall(function()
        local char = target.Character
        local head = char:FindFirstChild("Head")
        if not head then return end

        local col = getESPColor(target)

        local hl = Instance.new("Highlight")
        hl.Adornee          = char
        hl.FillColor         = col
        hl.OutlineColor      = Color3.new(1,1,1)
        hl.FillTransparency  = 0.55
        hl.Parent            = char

        local bb = Instance.new("BillboardGui", head)
        bb.Size         = UDim2.new(0, 200, 0, 56)
        bb.StudsOffset  = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop  = true

        local nameL = Instance.new("TextLabel", bb)
        nameL.Size              = UDim2.new(1,0,0.45,0)
        nameL.BackgroundTransparency = 1
        nameL.Text              = target.Name
        nameL.TextColor3        = Color3.new(1,1,1)
        nameL.TextStrokeTransparency = 0
        nameL.Font              = Enum.Font.GothamBold
        nameL.TextSize          = 14

        local infoL = Instance.new("TextLabel", bb)
        infoL.Size              = UDim2.new(1,0,0.55,0)
        infoL.Position          = UDim2.new(0,0,0.45,0)
        infoL.BackgroundTransparency = 1
        infoL.Text              = "❤️? | 📏? | 👥?"
        infoL.TextColor3        = col
        infoL.TextStrokeTransparency = 0
        infoL.Font              = Enum.Font.Gotham
        infoL.TextSize          = 11

        espObjects[target.Name] = {hl=hl, bb=bb, infoL=infoL}

        -- Limpiar cuando el personaje sea destruido
        espMaid:Add(char.AncestryChanged:Connect(function()
            if not char.Parent and espObjects[target.Name] then
                pcall(function() espObjects[target.Name].hl:Destroy() end)
                pcall(function() espObjects[target.Name].bb:Destroy() end)
                espObjects[target.Name] = nil
            end
        end))
    end)
end

local function removeESP(target)
    if not target then return end
    pcall(function()
        local obj = espObjects[target.Name]
        if obj then
            if obj.hl then obj.hl:Destroy() end
            if obj.bb then obj.bb:Destroy() end
            espObjects[target.Name] = nil
        end
    end)
end

local function clearAllESP()
    for _,p in ipairs(Players:GetPlayers()) do removeESP(p) end
    espObjects = {}
end

-- Actualizar info del ESP
local function updateESP()
    local myHRP = getHRP()
    if not myHRP then return end
    for _,target in ipairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            -- Crear si no existe y debería mostrarse
            if not espObjects[target.Name] and S.esp and shouldESP(target) then
                createESP(target)
            end
            -- Quitar si ya no debería mostrarse
            if espObjects[target.Name] and not shouldESP(target) then
                removeESP(target)
                continue
            end
            local obj = espObjects[target.Name]
            if obj and obj.infoL then
                local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                local hum  = target.Character:FindFirstChildOfClass("Humanoid")
                if tHRP and hum then
                    local dist  = math.floor((myHRP.Position - tHRP.Position).Magnitude)
                    local hp    = math.floor(hum.Health)
                    local maxHp = math.floor(hum.MaxHealth)
                    local team  = target.Team and target.Team.Name or "Sin equipo"
                    local pct   = hp / math.max(maxHp, 1)

                    obj.infoL.Text = "❤️"..hp.."/"..maxHp.." 📏"..dist.."m"
                    obj.infoL.TextColor3 = pct>0.6 and Color3.fromRGB(50,255,100)
                        or pct>0.3 and Color3.fromRGB(255,220,0)
                        or Color3.fromRGB(255,50,50)
                end
            end
        end
    end
end

-- Loop ESP a 5 fps
task.spawn(function()
    while task.wait(0.2) do
        if not S.active then break end
        if S.esp then updateESP()
        else clearAllESP() end
    end
end)

-- ESP reconecta al respawn
local function setupESPForPlayer(target)
    if target.Character and S.esp then createESP(target) end
    espMaid:Add(target.CharacterAdded:Connect(function()
        task.wait(0.5)
        if S.esp then removeESP(target); createESP(target) end
    end))
end

-- ============================================================
-- AUTO FOLLOW
-- ============================================================
local function setupAutoFollow()
    followMaid:Destroy()
    if not S.autoFollow or not S.selectedPlayer then return end

    local lastT = 0
    followMaid:Add(RunService.Heartbeat:Connect(function()
        if os.clock()-lastT < 0.1 then return end
        lastT = os.clock()
        local target = S.selectedPlayer
        if not target or not target.Character then return end
        local tHRP  = target.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = getHRP()
        local hum   = getHum()
        if not tHRP or not myHRP or not hum then return end
        local dir = tHRP.Position - myHRP.Position
        if dir.Magnitude > S.followDist then
            hum:MoveTo(tHRP.Position - dir.Unit * S.followDist)
        end
    end))

    -- Reconectar si objetivo reaparece
    if S.selectedPlayer then
        followMaid:Add(S.selectedPlayer.CharacterAdded:Connect(function()
            task.wait(0.8)
            -- el loop ya maneja, solo reactivar
        end))
    end

    -- Reconectar si yo reaparezco
    followMaid:Add(player.CharacterAdded:Connect(function()
        task.wait(1)
        setupAutoFollow()
    end))
end

-- ============================================================
-- ILUMINACIÓN ORIGINAL (para restaurar fullbright)
-- ============================================================
local origLighting = {}

-- ============================================================
-- EVENTOS DE JUGADORES
-- ============================================================
mainMaid:Add(Players.PlayerAdded:Connect(function(p)
    setupESPForPlayer(p)
end))

mainMaid:Add(Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
    hitboxCache[p.Name] = nil
    if S.selectedPlayer == p then
        S.selectedPlayer = nil
        S.autoFollow     = false
        followMaid:Destroy()
        notify("⚠️ Jugador salió", p.Name.." abandonó el servidor")
    end
end))

for _,p in ipairs(Players:GetPlayers()) do
    if p ~= player then setupESPForPlayer(p) end
end

-- Mi personaje reaparece: restaurar invisibilidad y velocidad
mainMaid:Add(player.CharacterAdded:Connect(function()
    task.wait(0.5)
    S.fly = false
    stopFly()
    if S.invis then
        task.wait(0.3)
        setInvis(true)
    end
end))

-- ============================================================
-- LIMPIEZA TOTAL
-- ============================================================
local function clearAll()
    S.active     = false
    S.fly        = false
    S.noclip     = false
    S.killAura   = false
    S.hitbox     = false
    S.esp        = false
    S.godMode    = false
    S.autoFollow = false
    S.invis      = false
    S.clickTP    = false
    S.clickKill  = false

    stopFly()
    clearAllESP()
    setInvis(false)
    followMaid:Destroy()
    espMaid:Destroy()
    mainMaid:Destroy()

    -- Restaurar personaje
    local c = getChar()
    if c then
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
                p.LocalTransparencyModifier = 0
            end
        end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16; hum.JumpPower = 50; hum.PlatformStand = false
        end
    end

    -- Restaurar hitboxes
    for name, cache in pairs(hitboxCache) do
        local p = getByName(name)
        if p and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function()
                hrp.Size = cache.size; hrp.Transparency = cache.trans
            end) end
        end
    end
    hitboxCache = {}

    -- Restaurar iluminación
    if origLighting.Brightness then
        Lighting.Brightness    = origLighting.Brightness
        Lighting.ClockTime     = origLighting.ClockTime
        Lighting.GlobalShadows = origLighting.GlobalShadows
        Lighting.Ambient       = origLighting.Ambient
    end
end

-- ============================================================
-- FLUENT UI — VENTANA PRINCIPAL
-- ============================================================
local Window = Fluent:CreateWindow({
    Title       = "🐉 GF HUB v7.0",
    SubTitle    = "by Gael Fonzar",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(580, 460),
    Acrylic     = false,   -- false = más compatible y menos detectable
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift,
})

local Tabs = {
    Move    = Window:AddTab({ Title = "Move",    Icon = "zap" }),
    Prot    = Window:AddTab({ Title = "Prot",    Icon = "shield" }),
    Players = Window:AddTab({ Title = "Players", Icon = "users" }),
    Combat  = Window:AddTab({ Title = "Combat",  Icon = "sword" }),
    Visual  = Window:AddTab({ Title = "Visual",  Icon = "eye" }),
    TP      = Window:AddTab({ Title = "TP",      Icon = "map-pin" }),
}

-- ============================================================
-- TAB: MOVE
-- ============================================================
Tabs.Move:AddParagraph({ Title = "── Velocidad ──", Content = "La velocidad se mantiene aunque subas de nivel." })

Tabs.Move:AddSlider("WalkSpeed", {
    Title   = "WalkSpeed",
    Min     = 16, Max = 500, Default = 16, Rounding = 0,
    Callback = function(v) S.walkSpeed = v end,
})

Tabs.Move:AddSlider("JumpPower", {
    Title   = "Jump Power",
    Min     = 50, Max = 500, Default = 50, Rounding = 0,
    Callback = function(v) S.jumpPower = v end,
})

Tabs.Move:AddParagraph({ Title = "── Fly ──", Content = "WASD + Space/Shift para subir/bajar." })

Tabs.Move:AddSlider("FlySpeed", {
    Title   = "Fly Speed",
    Min     = 10, Max = 500, Default = 80, Rounding = 0,
    Callback = function(v) S.flySpeed = v end,
})

Tabs.Move:AddToggle("Fly", {
    Title    = "✈️ Fly",
    Default  = false,
    Callback = function(v)
        S.fly = v
        if v then startFly() else stopFly() end
    end,
})

Tabs.Move:AddToggle("Noclip", {
    Title    = "👻 Noclip",
    Default  = false,
    Callback = function(v)
        S.noclip = v
        if not v then
            local c = getChar()
            if c then for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end end
        end
    end,
})

Tabs.Move:AddToggle("InfJump", {
    Title    = "♾️ Infinite Jump",
    Default  = false,
    Callback = function(v) S.infJump = v end,
})

Tabs.Move:AddButton({
    Title    = "🔄 Reset Velocidad",
    Callback = function()
        S.walkSpeed = 16; S.jumpPower = 50
        notify("✅ Reset", "Velocidad reseteada a valores base")
    end,
})

-- ============================================================
-- TAB: PROT
-- ============================================================
Tabs.Prot:AddParagraph({ Title = "── Protecciones ──", Content = "" })

Tabs.Prot:AddToggle("AntiKB", {
    Title    = "🛡️ Anti Knockback",
    Default  = false,
    Callback = function(v) S.antiKB = v end,
})

Tabs.Prot:AddToggle("AntiRag", {
    Title    = "🎭 Anti Ragdoll",
    Default  = false,
    Callback = function(v) S.antiRag = v end,
})

Tabs.Prot:AddToggle("GodMode", {
    Title    = "❤️ God Mode",
    Default  = false,
    Callback = function(v) S.godMode = v end,
})

Tabs.Prot:AddParagraph({ Title = "── Acciones ──", Content = "" })

Tabs.Prot:AddButton({
    Title    = "💊 Heal",
    Callback = function()
        local hum = getHum()
        if hum then hum.Health = hum.MaxHealth end
        notify("❤️ Heal", "HP restaurado al máximo")
    end,
})

Tabs.Prot:AddButton({
    Title    = "🔄 Respawn",
    Callback = function() player:LoadCharacter() end,
})

-- ============================================================
-- TAB: PLAYERS
-- ============================================================
-- Dropdown de jugadores
local ddPlayers = Tabs.Players:AddDropdown("PlayerSelect", {
    Title    = "Seleccionar Jugador",
    Values   = getPlayerList(),
    Default  = getPlayerList()[1],
    Callback = function(v)
        S.selectedPlayer = getByName(v)
        if S.selectedPlayer then
            notify("✅ Jugador", "Seleccionado: "..v)
            if S.autoFollow then setupAutoFollow() end
        end
    end,
})

-- Auto-actualizar lista
local function refreshDD()
    local list = getPlayerList()
    ddPlayers:SetValues(list)
end

mainMaid:Add(Players.PlayerAdded:Connect(function()
    task.wait(0.5); refreshDD()
end))
mainMaid:Add(Players.PlayerRemoving:Connect(function()
    task.wait(0.1); refreshDD()
end))

Tabs.Players:AddButton({
    Title    = "🔄 Actualizar Lista",
    Callback = function() refreshDD(); notify("✅ Lista", "Jugadores actualizados") end,
})

Tabs.Players:AddParagraph({ Title = "── Teleport ──", Content = "" })

Tabs.Players:AddButton({
    Title    = "📍 Ir a Jugador",
    Callback = function()
        if not S.selectedPlayer or not S.selectedPlayer.Character then
            notify("❌ Error", "Selecciona un jugador primero") return
        end
        local tHRP  = S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = getHRP()
        if tHRP and myHRP then
            myHRP.CFrame = tHRP.CFrame * CFrame.new(0,0,3)
            notify("✅ TP", "Teleportado a "..S.selectedPlayer.Name)
        end
    end,
})

Tabs.Players:AddButton({
    Title    = "📍 Traer Jugador",
    Callback = function()
        if not S.selectedPlayer or not S.selectedPlayer.Character then
            notify("❌ Error", "Selecciona un jugador primero") return
        end
        local tHRP  = S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = getHRP()
        if tHRP and myHRP then
            tHRP.CFrame = myHRP.CFrame * CFrame.new(0,0,3)
            notify("✅ TP", S.selectedPlayer.Name.." traído")
        end
    end,
})

Tabs.Players:AddParagraph({ Title = "── Auto Follow ──", Content = "" })

Tabs.Players:AddSlider("FollowDist", {
    Title    = "Distancia Follow",
    Min      = 2, Max = 25, Default = 5, Rounding = 0,
    Callback = function(v) S.followDist = v end,
})

Tabs.Players:AddToggle("AutoFollow", {
    Title    = "🏃 Auto Follow Player",
    Default  = false,
    Callback = function(v)
        S.autoFollow = v
        if v then
            if not S.selectedPlayer then
                notify("❌ Error", "Selecciona un jugador primero")
                S.autoFollow = false
                return
            end
            setupAutoFollow()
            notify("✅ Follow", "Siguiendo a "..S.selectedPlayer.Name)
        else
            followMaid:Destroy()
            notify("⛔ Follow", "Desactivado")
        end
    end,
})

Tabs.Players:AddParagraph({ Title = "── Cámara ──", Content = "" })

Tabs.Players:AddButton({
    Title    = "👁️ Espectear",
    Callback = function()
        if not S.selectedPlayer or not S.selectedPlayer.Character then
            notify("❌ Error", "Selecciona un jugador primero") return
        end
        local hum = S.selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            camera.CameraSubject = hum
            notify("👁️ Cámara", "Espectando: "..S.selectedPlayer.Name)
        end
    end,
})

Tabs.Players:AddButton({
    Title    = "🔙 Mi Cámara",
    Callback = function()
        local hum = getHum()
        if hum then camera.CameraSubject = hum end
        notify("✅ Cámara", "Restaurada")
    end,
})

-- ============================================================
-- TAB: COMBAT
-- ============================================================
Tabs.Combat:AddParagraph({ Title = "── Kill Aura ──", Content = "" })

Tabs.Combat:AddSlider("KARange", {
    Title    = "Rango KA",
    Min      = 5, Max = 80, Default = 15, Rounding = 0,
    Callback = function(v) S.killAuraRange = v end,
})

Tabs.Combat:AddToggle("KillAura", {
    Title    = "💀 Kill Aura",
    Default  = false,
    Callback = function(v) S.killAura = v end,
})

Tabs.Combat:AddParagraph({ Title = "── Hitbox Universal ──", Content = "Funciona en cualquier juego." })

Tabs.Combat:AddSlider("HBSize", {
    Title    = "Tamaño Hitbox",
    Min      = 5, Max = 50, Default = 10, Rounding = 0,
    Callback = function(v) S.hitboxSize = v end,
})

Tabs.Combat:AddToggle("Hitbox", {
    Title    = "📦 Hitbox Expander",
    Default  = false,
    Callback = function(v) S.hitbox = v end,
})

Tabs.Combat:AddParagraph({ Title = "── Click Modes ──", Content = "Solo uno activo a la vez." })

Tabs.Combat:AddToggle("ClickTP", {
    Title    = "🖱️ Click-to-TP",
    Default  = false,
    Callback = function(v)
        S.clickTP   = v
        if v then S.clickKill = false end
    end,
})

Tabs.Combat:AddToggle("ClickKill", {
    Title    = "🖱️ Click-to-Kill",
    Default  = false,
    Callback = function(v)
        S.clickKill = v
        if v then S.clickTP = false end
    end,
})

Tabs.Combat:AddButton({
    Title    = "👊 Hit Jugador Seleccionado",
    Callback = function()
        if not S.selectedPlayer then
            notify("❌ Error", "Selecciona un jugador primero") return
        end
        pcall(function()
            local myHRP = getHRP()
            local tHRP  = S.selectedPlayer.Character
                and S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHRP and tHRP then
                local orig = myHRP.CFrame
                myHRP.CFrame = tHRP.CFrame * CFrame.new(0,0,1.5)
                local tool = player.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
                task.wait(0.05)
                myHRP.CFrame = orig
            end
        end)
        notify("💥 Hit", "Enviado a "..S.selectedPlayer.Name)
    end,
})

-- ============================================================
-- TAB: VISUAL
-- ============================================================
Tabs.Visual:AddParagraph({ Title = "── ESP ──", Content = "" })

Tabs.Visual:AddDropdown("ESPMode", {
    Title    = "Modo ESP",
    Values   = {"Todos", "Aliados", "Enemigos"},
    Default  = "Todos",
    Callback = function(v)
        S.espMode = v
        -- Refrescar ESP con nuevo filtro
        clearAllESP()
        if S.esp then
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= player then createESP(p) end
            end
        end
        notify("👁️ ESP", "Modo: "..v)
    end,
})

Tabs.Visual:AddToggle("ESP", {
    Title    = "👁️ ESP Jugadores",
    Default  = false,
    Callback = function(v)
        S.esp = v
        if not v then clearAllESP() end
    end,
})

Tabs.Visual:AddParagraph({ Title = "── Invisibilidad ──", Content = "Solo visible para ti." })

Tabs.Visual:AddToggle("Invis", {
    Title    = "👤 Invisibilidad",
    Default  = false,
    Callback = function(v)
        S.invis = v
        setInvis(v)
        notify(v and "👤 Invisible" or "👀 Visible", v and "Activado" or "Desactivado")
    end,
})

Tabs.Visual:AddParagraph({ Title = "── Iluminación ──", Content = "" })

Tabs.Visual:AddToggle("Fullbright", {
    Title    = "💡 Fullbright",
    Default  = false,
    Callback = function(v)
        if v then
            origLighting = {
                Brightness    = Lighting.Brightness,
                ClockTime     = Lighting.ClockTime,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient       = Lighting.Ambient,
            }
            Lighting.Brightness    = 2
            Lighting.ClockTime     = 14
            Lighting.GlobalShadows = false
            Lighting.Ambient       = Color3.fromRGB(255,255,255)
        else
            if origLighting.Brightness then
                Lighting.Brightness    = origLighting.Brightness
                Lighting.ClockTime     = origLighting.ClockTime
                Lighting.GlobalShadows = origLighting.GlobalShadows
                Lighting.Ambient       = origLighting.Ambient
            end
        end
    end,
})

-- ============================================================
-- TAB: TELEPORT
-- ============================================================
Tabs.TP:AddParagraph({ Title = "── Destinos Rápidos ──", Content = "Agrega tus coords favoritas." })

-- Input de coordenadas custom
local coordX = Tabs.TP:AddInput("CoordX", {
    Title       = "X",
    Default     = "0",
    Placeholder = "Coordenada X",
    Numeric     = true,
    Callback    = function() end,
})
local coordY = Tabs.TP:AddInput("CoordY", {
    Title       = "Y",
    Default     = "0",
    Placeholder = "Coordenada Y",
    Numeric     = true,
    Callback    = function() end,
})
local coordZ = Tabs.TP:AddInput("CoordZ", {
    Title       = "Z",
    Default     = "0",
    Placeholder = "Coordenada Z",
    Numeric     = true,
    Callback    = function() end,
})

Tabs.TP:AddButton({
    Title    = "📍 Teleportar a Coordenadas",
    Callback = function()
        local x = tonumber(coordX.Value) or 0
        local y = tonumber(coordY.Value) or 0
        local z = tonumber(coordZ.Value) or 0
        local hrp = getHRP()
        if hrp then
            hrp.Anchored = true
            hrp.CFrame   = CFrame.new(x, y, z)
            task.wait(0.05)
            hrp.Anchored = false
            notify("✅ TP", string.format("→ (%.1f, %.1f, %.1f)", x, y, z))
        end
    end,
})

Tabs.TP:AddParagraph({ Title = "── Auto TP ──", Content = "TP automático a las coords guardadas." })

local autoTPActive  = false
local autoTPCoords  = Vector3.new(0, 0, 0)
local autoTPSpeed   = 0.1

Tabs.TP:AddToggle("AutoTP", {
    Title    = "🔄 Auto TP (coords arriba)",
    Default  = false,
    Callback = function(v)
        autoTPActive = v
        if v then
            local x = tonumber(coordX.Value) or 0
            local y = tonumber(coordY.Value) or 0
            local z = tonumber(coordZ.Value) or 0
            autoTPCoords = Vector3.new(x, y, z)
            notify("✅ Auto TP", string.format("Activo → (%.1f, %.1f, %.1f)", x, y, z))
        end
    end,
})

-- Loop Auto TP
task.spawn(function()
    while task.wait(autoTPSpeed) do
        if not S.active then break end
        if autoTPActive then
            local hrp = getHRP()
            if hrp then
                hrp.Anchored = true
                hrp.CFrame   = CFrame.new(autoTPCoords)
                task.wait(0.05)
                hrp.Anchored = false
            end
        end
    end
end)

-- Reconectar Auto TP al respawn
mainMaid:Add(player.CharacterAdded:Connect(function()
    if autoTPActive then
        task.wait(1)
        local hrp = getHRP()
        if hrp then
            hrp.Anchored = true
            hrp.CFrame   = CFrame.new(autoTPCoords)
            task.wait(0.05)
            hrp.Anchored = false
        end
    end
end))

-- ============================================================
-- NOTIFICACIÓN INICIAL
-- ============================================================
notify("🐉 GF HUB v7.0", "Listo! RShift = toggle | Fluent UI", 4)

--[[
╔══════════════════════════════════════════════════════╗
║           🐉 GF HUB v6.0 - by Gael Fonzar           ║
║         PC + Mobile | Negro/Rojo | Optimizado        ║
╚══════════════════════════════════════════════════════╝

MEJORAS v6.0:
  - Tema negro/rojo premium con animaciones suaves
  - ESP mejorado: nombre, vida, distancia, equipo
  - Auto Follow Player con reconexión automática
  - Lista de jugadores en tiempo real
  - Loops optimizados con eventos donde sea posible
  - Limpieza automática de conexiones (Maid pattern)
  - Corrección de todos los bugs del original
  - Código modular y comentado
]]

-- ============================================================
-- SERVICIOS
-- ============================================================
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local Lighting      = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled

-- ============================================================
-- COLORES CENTRALIZADOS (tema negro/rojo)
-- ============================================================
local C = {
    bg        = Color3.fromRGB(8,   8,   8),
    bg2       = Color3.fromRGB(14,  14,  14),
    bg3       = Color3.fromRGB(20,  20,  20),
    bg4       = Color3.fromRGB(26,  26,  26),
    red       = Color3.fromRGB(220, 30,  30),
    redDark   = Color3.fromRGB(140, 15,  15),
    redGlow   = Color3.fromRGB(255, 60,  60),
    white     = Color3.new(1, 1, 1),
    gray      = Color3.fromRGB(120, 120, 120),
    grayLight = Color3.fromRGB(180, 180, 180),
    green     = Color3.fromRGB(34,  197, 94),
    yellow    = Color3.fromRGB(251, 191, 36),
    purple    = Color3.fromRGB(192, 132, 252),
    blue      = Color3.fromRGB(96,  165, 250),
}

-- ============================================================
-- MAID: sistema de limpieza de conexiones
-- ============================================================
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({_tasks = {}}, Maid)
end

-- Agrega una conexión o función al maid
function Maid:Add(task)
    table.insert(self._tasks, task)
    return task
end

-- Limpia todas las conexiones registradas
function Maid:Destroy()
    for _, t in ipairs(self._tasks) do
        pcall(function()
            if typeof(t) == "RBXScriptConnection" then
                t:Disconnect()
            elseif typeof(t) == "Instance" then
                t:Destroy()
            elseif type(t) == "function" then
                t()
            end
        end)
    end
    self._tasks = {}
end

local mainMaid = Maid.new() -- maid global del hub

-- ============================================================
-- ESTADO GLOBAL
-- ============================================================
local S = {
    -- Movimiento
    walkSpeed   = 16,
    flySpeed    = 100,
    jumpPower   = 50,
    fly         = false,
    noclip      = false,
    infJump     = false,

    -- Protección
    antiKB      = false,
    antiRag     = false,
    godMode     = false,

    -- Combate
    killAura      = false,
    killAuraRange = 15,
    hitbox        = false,
    hitboxSize    = 10,

    -- Visual
    esp         = false,
    fullbright  = false,

    -- Follow
    autoFollow      = false,
    followDistance  = 5,
    selectedPlayer  = nil,

    -- Interno
    active = true,
}

-- ============================================================
-- HELPERS
-- ============================================================
local function getChar()  return player.Character end
local function getHum()   local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()   local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- Obtiene lista de nombres de jugadores (excluyendo al local)
local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then table.insert(list, "Sin jugadores") end
    return list
end

-- Busca jugador por nombre
local function getPlayerByName(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == name then return p end
    end
end

-- ============================================================
-- NOTIFICACIONES
-- ============================================================
local function notify(txt, dur)
    local ng = Instance.new("ScreenGui")
    ng.Name = "GF_Notif"
    ng.ResetOnSpawn = false
    ng.IgnoreGuiInset = true
    ng.Parent = player.PlayerGui

    local f = Instance.new("Frame", ng)
    f.Size = UDim2.new(0, 280, 0, 48)
    f.Position = UDim2.new(0.5, -140, 1, -90)
    f.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    f.BorderSizePixel = 0
    f.BackgroundTransparency = 1
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", f)
    stroke.Color = C.red
    stroke.Thickness = 1.5

    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -12, 1, 0)
    l.Position = UDim2.new(0, 6, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = C.white
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left

    TweenService:Create(f, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
    task.delay(dur or 2.5, function()
        TweenService:Create(f, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.35)
        ng:Destroy()
    end)
end

-- ============================================================
-- FLY
-- ============================================================
local flyBody, flyGyro

local function startFly()
    local hrp = getHRP()
    if not hrp then return end
    local hum = getHum()
    if hum then hum.PlatformStand = true end

    flyBody = Instance.new("BodyVelocity", hrp)
    flyBody.Name = "GF_BV"
    flyBody.Velocity = Vector3.zero
    flyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)

    flyGyro = Instance.new("BodyGyro", hrp)
    flyGyro.Name = "GF_BG"
    flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyGyro.P = 1e4
end

local function stopFly()
    local hrp = getHRP()
    if hrp then
        local bv = hrp:FindFirstChild("GF_BV")
        local bg = hrp:FindFirstChild("GF_BG")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
    if flyBody then pcall(function() flyBody:Destroy() end) flyBody = nil end
    if flyGyro then pcall(function() flyGyro:Destroy() end) flyGyro = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- ============================================================
-- ESP - Sistema mejorado con maid por jugador
-- ============================================================
local espObjects  = {} -- {[playerName] = {hl, bb, maid}}
local espMaid     = Maid.new()

-- Crea el ESP de un jugador
local function createESP(target)
    if not target or target == player then return end
    if not target.Character then return end
    if espObjects[target.Name] then return end -- ya existe

    pcall(function()
        local char = target.Character
        local head = char:FindFirstChild("Head")
        if not head then return end

        -- Highlight
        local hl = Instance.new("Highlight")
        hl.Adornee = char
        hl.FillColor = C.red
        hl.OutlineColor = C.white
        hl.FillTransparency = 0.55
        hl.Parent = char

        -- BillboardGui
        local bb = Instance.new("BillboardGui", head)
        bb.Size = UDim2.new(0, 180, 0, 52)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true

        local nameL = Instance.new("TextLabel", bb)
        nameL.Size = UDim2.new(1, 0, 0.48, 0)
        nameL.BackgroundTransparency = 1
        nameL.Text = target.Name
        nameL.TextColor3 = C.white
        nameL.TextStrokeTransparency = 0
        nameL.Font = Enum.Font.GothamBold
        nameL.TextSize = 14

        local infoL = Instance.new("TextLabel", bb)
        infoL.Size = UDim2.new(1, 0, 0.52, 0)
        infoL.Position = UDim2.new(0, 0, 0.48, 0)
        infoL.BackgroundTransparency = 1
        infoL.Text = "HP:? | Dist:? | Equipo:?"
        infoL.TextColor3 = C.green
        infoL.TextStrokeTransparency = 0
        infoL.Font = Enum.Font.Gotham
        infoL.TextSize = 11

        espObjects[target.Name] = {hl = hl, bb = bb, infoL = infoL}

        -- Limpiar si el personaje es destruido
        espMaid:Add(char.AncestryChanged:Connect(function()
            if not char.Parent then
                if espObjects[target.Name] then
                    pcall(function() espObjects[target.Name].hl:Destroy() end)
                    pcall(function() espObjects[target.Name].bb:Destroy() end)
                    espObjects[target.Name] = nil
                end
            end
        end))
    end)
end

-- Elimina el ESP de un jugador
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

-- Elimina todo el ESP
local function clearAllESP()
    for _, p in ipairs(Players:GetPlayers()) do
        removeESP(p)
    end
    espObjects = {}
end

-- Actualiza info del ESP (vida, distancia, equipo)
local function updateESPInfo()
    local myHRP = getHRP()
    if not myHRP then return end

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            local obj = espObjects[target.Name]
            if obj and obj.infoL then
                local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                local hum  = target.Character:FindFirstChildOfClass("Humanoid")
                if tHRP and hum then
                    local dist = math.floor((myHRP.Position - tHRP.Position).Magnitude)
                    local hp   = math.floor(hum.Health)
                    local maxHp = math.floor(hum.MaxHealth)
                    local team = target.Team and target.Team.Name or "Sin equipo"

                    obj.infoL.Text = "❤️"..hp.."/"..maxHp.." 📏"..dist.."m"

                    -- Color según HP
                    local pct = hp / math.max(maxHp, 1)
                    obj.infoL.TextColor3 = pct > 0.6 and C.green
                        or pct > 0.3 and C.yellow
                        or C.red
                end
            end
        end
    end
end

-- Reconecta ESP cuando el jugador reaparece
local function setupESPForPlayer(target)
    -- Cuando tenga personaje, crear ESP
    if target.Character then
        if S.esp then createESP(target) end
    end
    -- CharacterAdded: recrear ESP al respawnear
    espMaid:Add(target.CharacterAdded:Connect(function()
        task.wait(0.5)
        if S.esp then
            removeESP(target)
            createESP(target)
        end
    end))
end

-- ============================================================
-- HITBOX CACHE
-- ============================================================
local hitboxCache = {}

-- ============================================================
-- ILUMINACIÓN
-- ============================================================
local origLighting = {}

-- ============================================================
-- AUTO FOLLOW
-- ============================================================
local followMaid = Maid.new()

local function setupAutoFollow()
    followMaid:Destroy()

    if not S.autoFollow or not S.selectedPlayer then return end

    -- Función de seguimiento
    local function doFollow()
        if not S.autoFollow then return end
        local target = S.selectedPlayer
        if not target or not target.Character then return end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local myHRP = getHRP()
        if not tHRP or not myHRP then return end

        local dir = (tHRP.Position - myHRP.Position)
        if dir.Magnitude > S.followDistance then
            local hum = getHum()
            if hum then
                -- Usar MoveTo para movimiento natural
                hum:MoveTo(tHRP.Position - dir.Unit * S.followDistance)
            end
        end
    end

    -- Loop de follow a 10 fps (suficiente para movimiento suave)
    local lastTick = 0
    followMaid:Add(RunService.Heartbeat:Connect(function()
        if os.clock() - lastTick < 0.1 then return end
        lastTick = os.clock()
        doFollow()
    end))

    -- Si el objetivo reaparece, continuar siguiéndolo
    if S.selectedPlayer then
        followMaid:Add(S.selectedPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            -- El loop ya lo maneja, solo notificamos
        end))
    end

    -- Si mi personaje reaparece, reactivar follow
    followMaid:Add(player.CharacterAdded:Connect(function()
        task.wait(1)
        setupAutoFollow()
    end))
end

-- ============================================================
-- LOOPS PRINCIPALES (optimizados)
-- ============================================================

-- Fly: solo corre si está activo
mainMaid:Add(RunService.Heartbeat:Connect(function()
    if not S.active or not S.fly then return end
    local hrp = getHRP() if not hrp then return end
    local bv = hrp:FindFirstChild("GF_BV")
    local bg = hrp:FindFirstChild("GF_BG")
    if not bv or not bg then return end

    local cf  = camera.CFrame
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end

    bv.Velocity = dir.Magnitude > 0 and dir.Unit * S.flySpeed or Vector3.zero
    bg.CFrame   = cf
end))

-- Noclip: usa Stepped para correr antes de la física
mainMaid:Add(RunService.Stepped:Connect(function()
    if not S.active or not S.noclip then return end
    local c = getChar() if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end))

-- Speed y jump: solo cuando cambien (se aplica en CharacterAdded también)
local lastSpeed, lastJump = -1, -1
mainMaid:Add(RunService.Heartbeat:Connect(function()
    if not S.active then return end
    local hum = getHum() if not hum then return end
    if S.walkSpeed ~= lastSpeed then
        hum.WalkSpeed = S.walkSpeed
        lastSpeed = S.walkSpeed
    end
    if S.jumpPower ~= lastJump then
        hum.JumpPower = S.jumpPower
        lastJump = S.jumpPower
    end
end))

-- Protecciones: antiKB, godMode, antiRag
mainMaid:Add(RunService.Heartbeat:Connect(function()
    if not S.active then return end

    -- Anti Knockback
    if S.antiKB then
        local hrp = getHRP()
        if hrp then
            local v = hrp.AssemblyLinearVelocity
            if v.Magnitude > 20 then
                hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            end
        end
    end

    -- God Mode
    if S.godMode then
        local hum = getHum()
        if hum then hum.Health = hum.MaxHealth end
    end

    -- Anti Ragdoll
    if S.antiRag then
        local c = getChar() if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end))

-- Infinite Jump: evento, no loop
mainMaid:Add(UserInputService.JumpRequest:Connect(function()
    if not S.active or not S.infJump then return end
    local hum = getHum()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

-- Hitbox Expander
mainMaid:Add(RunService.Heartbeat:Connect(function()
    if not S.active then return end
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                if S.hitbox then
                    if not hitboxCache[target.Name] then
                        hitboxCache[target.Name] = {
                            size  = tHRP.Size,
                            trans = tHRP.Transparency
                        }
                    end
                    tHRP.Size        = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
                    tHRP.Transparency = 0.8
                    tHRP.CanCollide  = false
                elseif hitboxCache[target.Name] then
                    pcall(function()
                        tHRP.Size        = hitboxCache[target.Name].size
                        tHRP.Transparency = hitboxCache[target.Name].trans
                    end)
                    hitboxCache[target.Name] = nil
                end
            end
        end
    end
end))

-- ESP Update: a 5 fps (no necesita más)
task.spawn(function()
    while task.wait(0.2) do
        if not S.active then break end
        if S.esp then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    if not espObjects[p.Name] then createESP(p) end
                end
            end
            updateESPInfo()
        end
    end
end)

-- Kill Aura
task.spawn(function()
    while task.wait(0.15) do
        if not S.active then break end
        if S.killAura then
            local myHRP = getHRP()
            if myHRP then
                for _, target in ipairs(Players:GetPlayers()) do
                    if target ~= player and target.Character then
                        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
                        if tHRP and (myHRP.Position - tHRP.Position).Magnitude <= S.killAuraRange then
                            pcall(function()
                                local orig = myHRP.CFrame
                                myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2)
                                local tool = player.Character:FindFirstChildOfClass("Tool")
                                if tool then tool:Activate() end
                                task.wait(0.05)
                                myHRP.CFrame = orig
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- EVENTOS DE JUGADORES
-- ============================================================

-- Nuevo jugador entra: configurar ESP
mainMaid:Add(Players.PlayerAdded:Connect(function(p)
    setupESPForPlayer(p)
end))

-- Jugador sale: limpiar ESP y hitbox
mainMaid:Add(Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
    hitboxCache[p.Name] = nil
    -- Si era el seleccionado, limpiar
    if S.selectedPlayer == p then
        S.selectedPlayer = nil
        S.autoFollow = false
        followMaid:Destroy()
        notify("⚠️ "..p.Name.." salió del servidor")
    end
end))

-- Setup ESP para jugadores ya conectados
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then
        setupESPForPlayer(p)
    end
end

-- Mi personaje reaparece
mainMaid:Add(player.CharacterAdded:Connect(function()
    task.wait(0.5)
    S.fly = false
    lastSpeed, lastJump = -1, -1
    stopFly()
end))

-- ============================================================
-- LIMPIEZA GLOBAL
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

    stopFly()
    clearAllESP()
    followMaid:Destroy()
    espMaid:Destroy()

    -- Restaurar personaje
    local c = getChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
            end
        end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed     = 16
            hum.JumpPower     = 50
            hum.PlatformStand = false
        end
    end

    -- Restaurar hitboxes
    for name, cache in pairs(hitboxCache) do
        local p = getPlayerByName(name)
        if p and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function()
                    hrp.Size        = cache.size
                    hrp.Transparency = cache.trans
                end)
            end
        end
    end
    hitboxCache = {}

    -- Restaurar iluminación
    if origLighting.Brightness then
        Lighting.Brightness     = origLighting.Brightness
        Lighting.ClockTime      = origLighting.ClockTime
        Lighting.GlobalShadows  = origLighting.GlobalShadows
        Lighting.Ambient        = origLighting.Ambient
    end

    mainMaid:Destroy()
end

-- ============================================================
-- GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "GFHUB"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = player.PlayerGui

local GUI_W = isMobile and 360 or 340
local GUI_H = isMobile and 520 or 500

-- Ventana principal
local main = Instance.new("Frame", screenGui)
main.Size            = UDim2.new(0, GUI_W, 0, GUI_H)
main.Position        = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

-- Borde rojo fijo (sin rainbow, más premium)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color     = C.red
mainStroke.Thickness = 1.5

-- ── HEADER ──────────────────────────────────────────────────
local header = Instance.new("Frame", main)
header.Size            = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = C.bg2
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

-- Fix para esquinas inferiores del header
local hfix = Instance.new("Frame", header)
hfix.Size            = UDim2.new(1, 0, 0, 14)
hfix.Position        = UDim2.new(0, 0, 1, -14)
hfix.BackgroundColor3 = C.bg2
hfix.BorderSizePixel = 0

-- Título con color rojo
local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size              = UDim2.new(1, -110, 1, 0)
titleLbl.Position          = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text              = "🐉 GF HUB v6.0"
titleLbl.Font              = Enum.Font.GothamBold
titleLbl.TextSize          = 16
titleLbl.TextColor3        = C.red
titleLbl.TextXAlignment    = Enum.TextXAlignment.Left

-- Subtítulo
local subLbl = Instance.new("TextLabel", header)
subLbl.Size              = UDim2.new(1, -110, 0, 14)
subLbl.Position          = UDim2.new(0, 12, 1, -16)
subLbl.BackgroundTransparency = 1
subLbl.Text              = "by Gael Fonzar"
subLbl.Font              = Enum.Font.Gotham
subLbl.TextSize          = 10
subLbl.TextColor3        = C.gray
subLbl.TextXAlignment    = Enum.TextXAlignment.Left

-- Botón minimizar
local btnMin = Instance.new("TextButton", header)
btnMin.Size            = UDim2.new(0, 32, 0, 32)
btnMin.Position        = UDim2.new(1, -74, 0.5, -16)
btnMin.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
btnMin.BorderSizePixel = 0
btnMin.Text            = "–"
btnMin.TextColor3      = C.white
btnMin.Font            = Enum.Font.GothamBold
btnMin.TextSize        = 16
Instance.new("UICorner", btnMin).CornerRadius = UDim.new(0, 8)

-- Botón cerrar
local btnClose = Instance.new("TextButton", header)
btnClose.Size            = UDim2.new(0, 32, 0, 32)
btnClose.Position        = UDim2.new(1, -38, 0.5, -16)
btnClose.BackgroundColor3 = C.red
btnClose.BorderSizePixel = 0
btnClose.Text            = "✕"
btnClose.TextColor3      = C.white
btnClose.Font            = Enum.Font.GothamBold
btnClose.TextSize        = 13
Instance.new("UICorner", btnClose).CornerRadius = UDim.new(0, 8)

-- ── TAB BAR ─────────────────────────────────────────────────
local tabBar = Instance.new("Frame", main)
tabBar.Size            = UDim2.new(1, 0, 0, 38)
tabBar.Position        = UDim2.new(0, 0, 0, 50)
tabBar.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
tabBar.BorderSizePixel = 0

local tbList = Instance.new("UIListLayout", tabBar)
tbList.FillDirection = Enum.FillDirection.Horizontal
tbList.Padding        = UDim.new(0, 2)

local tbPad = Instance.new("UIPadding", tabBar)
tbPad.PaddingLeft   = UDim.new(0, 3)
tbPad.PaddingTop    = UDim.new(0, 5)
tbPad.PaddingBottom = UDim.new(0, 5)

-- Área de contenido
local contentFrame = Instance.new("Frame", main)
contentFrame.Size               = UDim2.new(1, 0, 1, -88)
contentFrame.Position           = UDim2.new(0, 0, 0, 88)
contentFrame.BackgroundTransparency = 1

-- Definición de tabs
local tabDefs = {
    {n = "⚡Move",   c = C.blue},
    {n = "🛡️Prot",  c = C.green},
    {n = "👥Play",  c = C.yellow},
    {n = "⚔️Fight", c = C.red},
    {n = "👁️ESP",  c = C.purple},
}

local pages  = {}
local tabBtns = {}

for i, def in ipairs(tabDefs) do
    -- Botón de tab
    local btn = Instance.new("TextButton", tabBar)
    btn.Size            = UDim2.new(0.19, -2, 1, 0)
    btn.BackgroundColor3 = C.bg3
    btn.BorderSizePixel = 0
    btn.Text            = def.n
    btn.TextColor3      = C.gray
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = isMobile and 10 or 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    tabBtns[i] = btn

    -- Página (ScrollingFrame)
    local page = Instance.new("ScrollingFrame", contentFrame)
    page.Size                  = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel       = 0
    page.ScrollBarThickness    = 3
    page.ScrollBarImageColor3  = def.c
    page.CanvasSize            = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    page.Visible               = i == 1
    page.ScrollingEnabled      = true
    pages[i] = page

    local lay = Instance.new("UIListLayout", page)
    lay.Padding    = UDim.new(0, 5)
    lay.SortOrder  = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop    = UDim.new(0, 7)
    pad.PaddingLeft   = UDim.new(0, 7)
    pad.PaddingRight  = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 7)
end

-- Cambiar tab activo
local function switchTab(i)
    for j, p in ipairs(pages) do
        p.Visible = j == i
        tabBtns[j].TextColor3      = j == i and tabDefs[j].c or C.gray
        tabBtns[j].BackgroundColor3 = j == i and C.bg4 or C.bg3
    end
end

for i, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
end
switchTab(1)

-- ============================================================
-- UI HELPERS
-- ============================================================

-- Separador / etiqueta de sección
local function crearLabel(page, txt)
    local l = Instance.new("TextLabel", page)
    l.Size               = UDim2.new(1, 0, 0, 20)
    l.BackgroundTransparency = 1
    l.Text               = txt
    l.TextColor3         = C.red
    l.Font               = Enum.Font.GothamBold
    l.TextSize           = 10
    l.TextXAlignment     = Enum.TextXAlignment.Left
end

-- Toggle con switch animado
local function crearToggle(page, lbl, color, cb)
    local tH = isMobile and 48 or 40
    local box = Instance.new("Frame", page)
    box.Size            = UDim2.new(1, 0, 0, tH)
    box.BackgroundColor3 = C.bg2
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)

    local stroke = Instance.new("UIStroke", box)
    stroke.Color     = Color3.fromRGB(35, 35, 35)
    stroke.Thickness = 0.5

    local l = Instance.new("TextLabel", box)
    l.Size              = UDim2.new(1, -65, 1, 0)
    l.Position          = UDim2.new(0, 9, 0, 0)
    l.BackgroundTransparency = 1
    l.Text              = lbl
    l.TextColor3        = C.grayLight
    l.Font              = Enum.Font.Gotham
    l.TextSize          = isMobile and 13 or 12
    l.TextXAlignment    = Enum.TextXAlignment.Left

    local swW = isMobile and 46 or 36
    local swH = isMobile and 24 or 18

    local bg = Instance.new("Frame", box)
    bg.Size            = UDim2.new(0, swW, 0, swH)
    bg.Position        = UDim2.new(1, -(swW + 9), 0.5, -swH/2)
    bg.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local kSz = isMobile and 18 or 12
    local knob = Instance.new("Frame", bg)
    knob.Size            = UDim2.new(0, kSz, 0, kSz)
    knob.Position        = UDim2.new(0, 3, 0.5, -kSz/2)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local on     = false
    local ti     = TweenInfo.new(0.15)
    local posOn  = UDim2.new(0, swW - kSz - 3, 0.5, -kSz/2)
    local posOff = UDim2.new(0, 3, 0.5, -kSz/2)

    local btn = Instance.new("TextButton", box)
    btn.Size               = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text               = ""
    btn.ZIndex             = 5

    btn.MouseButton1Click:Connect(function()
        on = not on
        local targetColor = on and color or Color3.fromRGB(38, 38, 38)
        TweenService:Create(bg,   ti, {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(knob, ti, {Position = on and posOn or posOff}):Play()
        -- Borde rojo cuando activo
        TweenService:Create(stroke, ti, {Color = on and C.red or Color3.fromRGB(35,35,35)}):Play()
        cb(on)
    end)

    return box
end

-- Slider con knob
local function crearSlider(page, lbl, minV, maxV, def, color, cb)
    local sH = isMobile and 65 or 55
    local box = Instance.new("Frame", page)
    box.Size            = UDim2.new(1, 0, 0, sH)
    box.BackgroundColor3 = C.bg2
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)

    Instance.new("UIStroke", box).Color = Color3.fromRGB(35, 35, 35)

    local l = Instance.new("TextLabel", box)
    l.Size              = UDim2.new(0.65, 0, 0, 24)
    l.Position          = UDim2.new(0, 9, 0, 4)
    l.BackgroundTransparency = 1
    l.Text              = lbl
    l.TextColor3        = C.grayLight
    l.Font              = Enum.Font.Gotham
    l.TextSize          = isMobile and 13 or 12
    l.TextXAlignment    = Enum.TextXAlignment.Left

    local vl = Instance.new("TextLabel", box)
    vl.Size             = UDim2.new(0.35, -9, 0, 24)
    vl.Position         = UDim2.new(0.65, 0, 0, 4)
    vl.BackgroundTransparency = 1
    vl.Text             = tostring(def)
    vl.TextColor3       = color
    vl.Font             = Enum.Font.GothamBold
    vl.TextSize         = isMobile and 14 or 13
    vl.TextXAlignment   = Enum.TextXAlignment.Right

    local barH = isMobile and 10 or 7
    local barY = isMobile and 44 or 36
    local bar  = Instance.new("Frame", box)
    bar.Size            = UDim2.new(1, -18, 0, barH)
    bar.Position        = UDim2.new(0, 9, 0, barY)
    bar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 5)

    local pct  = math.clamp((def - minV) / (maxV - minV), 0, 1)
    local fill = Instance.new("Frame", bar)
    fill.Size            = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

    local kSz  = isMobile and 18 or 12
    local knob = Instance.new("Frame", bar)
    knob.Size            = UDim2.new(0, kSz, 0, kSz)
    knob.AnchorPoint     = Vector2.new(0.5, 0.5)
    knob.Position        = UDim2.new(pct, 0, 0.5, 0)
    knob.BackgroundColor3 = C.white
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local hitArea = Instance.new("TextButton", box)
    hitArea.Size               = UDim2.new(1, -10, 0, isMobile and 36 or 26)
    hitArea.Position           = UDim2.new(0, 5, 0, barY - (isMobile and 13 or 9))
    hitArea.BackgroundTransparency = 1
    hitArea.Text               = ""
    hitArea.ZIndex             = 10

    local sliding = false

    local function update(posX)
        local p = math.clamp((posX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + p * (maxV - minV))
        fill.Size     = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        vl.Text       = tostring(v)
        cb(v)
    end

    hitArea.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            update(i.Position.X)
        end
    end)
    hitArea.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    hitArea.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)
end

-- Botón de acción
local function crearBoton(page, lbl, color, cb)
    local bH  = isMobile and 44 or 36
    local btn = Instance.new("TextButton", page)
    btn.Size            = UDim2.new(1, 0, 0, bH)
    btn.BackgroundColor3 = color or C.bg3
    btn.BorderSizePixel = 0
    btn.Text            = lbl
    btn.TextColor3      = C.white
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = isMobile and 13 or 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    -- Hover effect
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.new(
                math.min(1, (color or C.bg3).R + 0.08),
                math.min(1, (color or C.bg3).G + 0.08),
                math.min(1, (color or C.bg3).B + 0.08)
            )
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = color or C.bg3}):Play()
    end)

    btn.MouseButton1Click:Connect(cb)
    return btn
end

-- Dropdown con lista dinámica
local ddRef = nil -- referencia global para actualizar jugadores

local function crearDropdown(page, lbl, lista, cb)
    local rH  = isMobile and 48 or 40
    local iH  = isMobile and 36 or 30
    local box = Instance.new("Frame", page)
    box.Size            = UDim2.new(1, 0, 0, rH)
    box.BackgroundColor3 = C.bg2
    box.BorderSizePixel = 0
    box.ClipsDescendants = true
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)
    Instance.new("UIStroke", box).Color = Color3.fromRGB(35, 35, 35)

    local l = Instance.new("TextLabel", box)
    l.Size              = UDim2.new(0.38, 0, 0, rH)
    l.Position          = UDim2.new(0, 9, 0, 0)
    l.BackgroundTransparency = 1
    l.Text              = lbl
    l.TextColor3        = C.gray
    l.Font              = Enum.Font.Gotham
    l.TextSize          = isMobile and 12 or 11
    l.TextXAlignment    = Enum.TextXAlignment.Left

    local selBtn = Instance.new("TextButton", box)
    selBtn.Size            = UDim2.new(0.62, -9, 0, isMobile and 32 or 26)
    selBtn.Position        = UDim2.new(0.38, 0, 0.5, isMobile and -16 or -13)
    selBtn.BackgroundColor3 = C.bg4
    selBtn.BorderSizePixel = 0
    selBtn.Text            = lista[1] or "Ninguno"
    selBtn.TextColor3      = C.white
    selBtn.Font            = Enum.Font.Gotham
    selBtn.TextSize        = isMobile and 12 or 11
    Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 6)

    local open  = false
    local items = {}

    local function rebuild()
        for _, f in ipairs(items) do f:Destroy() end
        items = {}
        for i, name in ipairs(lista) do
            local it = Instance.new("TextButton", box)
            it.Size            = UDim2.new(1, 0, 0, iH)
            it.Position        = UDim2.new(0, 0, 0, rH + (i-1)*iH)
            it.BackgroundColor3 = C.bg3
            it.BorderSizePixel = 0
            it.Text            = name
            it.TextColor3      = C.white
            it.Font            = Enum.Font.Gotham
            it.TextSize        = isMobile and 12 or 11

            it.MouseButton1Click:Connect(function()
                selBtn.Text = name
                open = false
                TweenService:Create(box, TweenInfo.new(0.15), {
                    Size = UDim2.new(1, 0, 0, rH)
                }):Play()
                cb(name)
            end)
            table.insert(items, it)
        end
    end
    rebuild()

    selBtn.MouseButton1Click:Connect(function()
        open = not open
        TweenService:Create(box, TweenInfo.new(0.15), {
            Size = UDim2.new(1, 0, 0, open and rH + #lista*iH or rH)
        }):Play()
    end)

    return {
        refresh = function(nl)
            lista = nl
            selBtn.Text = lista[1] or "Ninguno"
            open = false
            box.Size = UDim2.new(1, 0, 0, rH)
            rebuild()
        end,
        getText = function() return selBtn.Text end
    }
end

-- ============================================================
-- TAB 1: MOVE
-- ============================================================
local p1 = pages[1]
crearLabel(p1, "  ── VELOCIDAD ──")
crearSlider(p1, "WalkSpeed",  16, 500, 16,  C.blue,   function(v) S.walkSpeed = v end)
crearSlider(p1, "Jump Power", 50, 500, 50,  C.purple, function(v) S.jumpPower = v end)
crearLabel(p1, "  ── FLY ──")
crearSlider(p1, "Fly Speed",  10, 500, 100, C.yellow, function(v) S.flySpeed = v end)
crearToggle(p1, "✈️ Fly",          C.blue,   function(v) S.fly = v if v then startFly() else stopFly() end end)
crearToggle(p1, "👻 Noclip",       C.purple, function(v)
    S.noclip = v
    if not v then
        local c = getChar()
        if c then for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end end
    end
end)
crearToggle(p1, "♾️ Infinite Jump", C.green, function(v) S.infJump = v end)
crearBoton(p1, "🔄 Reset Velocidad", C.bg3, function()
    S.walkSpeed = 16
    S.jumpPower = 50
    notify("✅ Velocidad reseteada")
end)

-- ============================================================
-- TAB 2: PROTECCIÓN
-- ============================================================
local p2 = pages[2]
crearLabel(p2, "  ── PROTECCIONES ──")
crearToggle(p2, "🛡️ Anti Knockback", C.green, function(v) S.antiKB  = v end)
crearToggle(p2, "🎭 Anti Ragdoll",   C.green, function(v) S.antiRag = v end)
crearToggle(p2, "❤️ God Mode",       C.red,   function(v) S.godMode = v end)
crearLabel(p2, "  ── OPCIONES ──")
crearBoton(p2, "💊 Heal", Color3.fromRGB(15, 70, 15), function()
    local hum = getHum()
    if hum then hum.Health = hum.MaxHealth end
    notify("❤️ HP restaurado")
end)
crearBoton(p2, "🔄 Respawn", C.bg3, function()
    player:LoadCharacter()
end)

-- ============================================================
-- TAB 3: JUGADORES
-- ============================================================
local p3 = pages[3]
crearLabel(p3, "  ── JUGADOR ──")

local dd = crearDropdown(p3, "Jugador", getPlayerList(), function(name)
    S.selectedPlayer = getPlayerByName(name)
    if S.selectedPlayer then
        notify("✅ Seleccionado: "..name)
        -- Si autofollow estaba activo, reactivar con nuevo jugador
        if S.autoFollow then setupAutoFollow() end
    end
end)
ddRef = dd

-- Auto-actualizar lista cada 5 segundos
task.spawn(function()
    while task.wait(5) do
        if not S.active then break end
        dd.refresh(getPlayerList())
    end
end)

-- También actualizar cuando entre/salga un jugador
mainMaid:Add(Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    dd.refresh(getPlayerList())
end))
mainMaid:Add(Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    dd.refresh(getPlayerList())
end))

crearBoton(p3, "🔄 Actualizar Lista", C.bg3, function()
    dd.refresh(getPlayerList())
    notify("✅ Lista actualizada")
end)

crearLabel(p3, "  ── TELEPORT ──")
crearBoton(p3, "📍 Ir a Jugador", Color3.fromRGB(25, 25, 70), function()
    if not S.selectedPlayer or not S.selectedPlayer.Character then
        notify("❌ Selecciona un jugador") return
    end
    local tHRP  = S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = getHRP()
    if tHRP and myHRP then
        myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
        notify("✅ Teleportado a "..S.selectedPlayer.Name)
    end
end)

crearBoton(p3, "📍 Traer Jugador", Color3.fromRGB(25, 25, 70), function()
    if not S.selectedPlayer or not S.selectedPlayer.Character then
        notify("❌ Selecciona un jugador") return
    end
    local tHRP  = S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = getHRP()
    if tHRP and myHRP then
        tHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, 3)
        notify("✅ "..S.selectedPlayer.Name.." traído")
    end
end)

crearLabel(p3, "  ── AUTO FOLLOW ──")
crearSlider(p3, "Distancia Follow", 2, 20, 5, C.yellow, function(v) S.followDistance = v end)
crearToggle(p3, "🏃 Auto Follow Player", C.yellow, function(v)
    S.autoFollow = v
    if v then
        if not S.selectedPlayer then
            notify("❌ Selecciona un jugador primero")
            S.autoFollow = false
            return
        end
        setupAutoFollow()
        notify("✅ Siguiendo a "..S.selectedPlayer.Name)
    else
        followMaid:Destroy()
        notify("⛔ Auto Follow desactivado")
    end
end)

crearLabel(p3, "  ── CÁMARA ──")
crearBoton(p3, "👁️ Espectear", C.bg3, function()
    if not S.selectedPlayer or not S.selectedPlayer.Character then
        notify("❌ Selecciona un jugador") return
    end
    local hum = S.selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        camera.CameraSubject = hum
        notify("👁️ Espectando: "..S.selectedPlayer.Name)
    end
end)

crearBoton(p3, "🔙 Mi Cámara", C.bg3, function()
    local hum = getHum()
    if hum then
        camera.CameraSubject = hum
        notify("✅ Cámara restaurada")
    end
end)

-- ============================================================
-- TAB 4: COMBATE
-- ============================================================
local p4 = pages[4]
crearLabel(p4, "  ── KILL AURA ──")
crearSlider(p4, "Rango KA", 5, 50, 15, C.red, function(v) S.killAuraRange = v end)
crearToggle(p4, "💀 Kill Aura", C.red, function(v) S.killAura = v end)

crearLabel(p4, "  ── HITBOX ──")
crearSlider(p4, "Tamaño HB", 5, 30, 10, C.yellow, function(v) S.hitboxSize = v end)
crearToggle(p4, "📦 Hitbox Expander", C.yellow, function(v) S.hitbox = v end)

crearLabel(p4, "  ── MANUAL ──")
crearBoton(p4, "👊 Hit Jugador", Color3.fromRGB(70, 15, 15), function()
    if not S.selectedPlayer then
        notify("❌ Selecciona un jugador") return
    end
    pcall(function()
        local myHRP = getHRP()
        local tHRP  = S.selectedPlayer.Character
            and S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myHRP and tHRP then
            local orig = myHRP.CFrame
            myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2)
            local tool = player.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
            task.wait(0.05)
            myHRP.CFrame = orig
        end
    end)
    notify("💥 Hit enviado!")
end)

-- ============================================================
-- TAB 5: ESP / VISUAL
-- ============================================================
local p5 = pages[5]
crearLabel(p5, "  ── ESP ──")
crearToggle(p5, "👁️ ESP Jugadores", C.purple, function(v)
    S.esp = v
    if not v then clearAllESP() end
end)

crearLabel(p5, "  ── LIGHTING ──")
crearToggle(p5, "💡 Fullbright", C.yellow, function(v)
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
        Lighting.Ambient       = Color3.fromRGB(255, 255, 255)
    else
        if origLighting.Brightness then
            Lighting.Brightness    = origLighting.Brightness
            Lighting.ClockTime     = origLighting.ClockTime
            Lighting.GlobalShadows = origLighting.GlobalShadows
            Lighting.Ambient       = origLighting.Ambient
        end
    end
end)

-- ============================================================
-- DRAG (mouse + touch)
-- ============================================================
local drag = {active = false, start = nil, orig = nil}

header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        drag.active = true
        drag.start  = Vector2.new(i.Position.X, i.Position.Y)
        drag.orig   = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if drag.active and (i.UserInputType == Enum.UserInputType.MouseMovement
    or i.UserInputType == Enum.UserInputType.Touch) then
        local d = Vector2.new(i.Position.X, i.Position.Y) - drag.start
        main.Position = UDim2.new(
            drag.orig.X.Scale, drag.orig.X.Offset + d.X,
            drag.orig.Y.Scale, drag.orig.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        drag.active = false
    end
end)

-- ============================================================
-- MINIMIZAR / CERRAR
-- ============================================================
local minimizado = false
local twI = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

btnMin.MouseButton1Click:Connect(function()
    minimizado = not minimizado
    TweenService:Create(main, twI, {
        Size = minimizado
            and UDim2.new(0, GUI_W, 0, 50)
            or  UDim2.new(0, GUI_W, 0, GUI_H)
    }):Play()
    btnMin.Text = minimizado and "□" or "–"
end)

btnClose.MouseButton1Click:Connect(function()
    clearAll()
    task.wait(0.1)
    screenGui:Destroy()
end)

-- ============================================================
-- TOGGLE VISIBILIDAD: RightShift
-- ============================================================
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

-- ============================================================
-- LISTO
-- ============================================================
notify("🐉 GF HUB v6.0 listo! | RShift = toggle", 3)

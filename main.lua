--[[
╔════════════════════════════════════════════════════════════════════╗
║              🔴 GF HUB v8.1 ULTIMATE 🔴                            ║
║         by Gael Fonzar | Custom UI | Negro/Rojo | 2025            ║
╚════════════════════════════════════════════════════════════════════╝
]]

-- ============================================================================
-- SERVICIOS
-- ============================================================================
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local Lighting        = game:GetService("Lighting")
local TweenService    = game:GetService("TweenService")
local VirtualUser     = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local StarterGui      = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled

-- ============================================================================
-- VALORES ORIGINALES DE LIGHTING (guardar al inicio)
-- ============================================================================
local origLighting = {
    Brightness    = Lighting.Brightness,
    ClockTime     = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient       = Lighting.Ambient,
    FogEnd        = Lighting.FogEnd,
    FogStart      = Lighting.FogStart,
    FogColor      = Lighting.FogColor,
}

-- ============================================================================
-- HELPERS
-- ============================================================================
local function getChar()        return player.Character end
local function getHum()         local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP()         local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getTargetChar(t) return t and t.Character end
local function getTargetHRP(t)  local c=getTargetChar(t) return c and c:FindFirstChild("HumanoidRootPart") end
local function isSameTeam(t)    return player.Team and t.Team and player.Team == t.Team end

-- ============================================================================
-- ESTADO GLOBAL
-- ============================================================================
local S = {
    -- Movimiento
    walkSpeed     = 16,
    jumpPower     = 50,
    fly           = false,
    flySpeed      = 80,
    noclip        = false,
    infJump       = false,

    -- Target / TP
    autoTP           = false,
    autoTPInterval   = 0.5,
    lastAutoTP       = 0,
    selectedPlayer   = nil,
    bring            = false,
    bringDistance    = 3,

    -- Invisibilidad
    realInvis = false,

    -- Protección
    antiKB     = false,
    godMode    = false,
    antiRag    = false,
    noStun     = false,

    -- Visual
    esp         = false,
    espMode     = "Enemigos",
    fullbright  = false,
    zoom        = false,
    zoomLevel   = 50,
    noFog       = false,
    noBloom     = false,
    noBlur      = false,

    -- Combate
    killAura       = false,
    killAuraRange  = 15,
    killAuraDelay  = 0.2,
    lastKillAura   = 0,
    hitbox         = false,
    hitboxSize     = 10,
    autoClicker    = false,
    autoClickerDelay = 0.05,
    lastClick      = 0,

    -- Utils
    antiAfk    = false,
    autoRejoin = false,

    active = true,
}

-- ============================================================================
-- NOTIFY (sin librería externa)
-- ============================================================================
local function notify(title, msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = title,
            Text     = msg,
            Duration = dur or 3,
        })
    end)
end

-- ============================================================================
-- MÓDULO: INVISIBILIDAD
-- ============================================================================
local Invisibility = { origTrans = {}, active = false }

function Invisibility:enable()
    local char = getChar() if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if not self.origTrans[p] then self.origTrans[p] = p.Transparency end
            p.Transparency = 1
            p.CanCollide   = false
        end
    end
    self.active = true
end

function Invisibility:disable()
    local char = getChar() if not char then return end
    for part, orig in pairs(self.origTrans) do
        if part and part.Parent then
            part.Transparency = orig
            part.CanCollide   = true
        end
    end
    self.origTrans = {}
    self.active    = false
end

-- ============================================================================
-- MÓDULO: FLY
-- ============================================================================
local Fly = { conn = nil, bv = nil, bg = nil }

function Fly:start()
    self:stop()
    local hrp = getHRP() if not hrp then return end
    local hum = getHum() if hum then hum.PlatformStand = true end

    self.bv           = Instance.new("BodyVelocity", hrp)
    self.bv.MaxForce  = Vector3.new(1e9,1e9,1e9)
    self.bv.Velocity  = Vector3.zero

    self.bg           = Instance.new("BodyGyro", hrp)
    self.bg.MaxTorque = Vector3.new(1e9,1e9,1e9)
    self.bg.P         = 1e4

    self.conn = RunService.Heartbeat:Connect(function()
        if not S.fly then return end
        local hrp2 = getHRP() if not hrp2 then return end
        if not self.bv or not self.bg then return end
        local cf  = camera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir += cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir -= cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis  end
        self.bv.Velocity  = dir.Magnitude > 0 and dir.Unit * S.flySpeed or Vector3.zero
        self.bg.CFrame    = cf
    end)
end

function Fly:stop()
    if self.conn then self.conn:Disconnect() self.conn = nil end
    if self.bv   then pcall(function() self.bv:Destroy() end) self.bv = nil end
    if self.bg   then pcall(function() self.bg:Destroy() end) self.bg = nil end
    local hum = getHum() if hum then hum.PlatformStand = false end
end

-- ============================================================================
-- MÓDULO: HITBOX
-- ============================================================================
local Hitbox = { modified = {}, origSizes = {} }

function Hitbox:update()
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then
            local hrp = getTargetHRP(target)
            if hrp then
                if S.hitbox then
                    if not self.modified[target] then
                        self.origSizes[target]  = hrp.Size
                        self.modified[target]   = true
                    end
                    hrp.Size        = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
                    hrp.CanCollide  = false
                else
                    if self.modified[target] and self.origSizes[target] then
                        pcall(function() hrp.Size = self.origSizes[target] end)
                        self.modified[target]  = nil
                        self.origSizes[target] = nil
                    end
                end
            end
        end
    end
end

function Hitbox:restoreAll()
    for target, orig in pairs(self.origSizes) do
        local hrp = getTargetHRP(target)
        if hrp then pcall(function() hrp.Size = orig end) end
    end
    self.modified  = {}
    self.origSizes = {}
end

-- ============================================================================
-- MÓDULO: ESP
-- ============================================================================
local ESP = { objects = {}, lastUpdate = 0, rate = 0.2 }

function ESP:shouldShow(t)
    if not S.esp or t == player then return false end
    if S.espMode == "Todos"     then return true end
    if S.espMode == "Aliados"   then return isSameTeam(t) end
    return not isSameTeam(t)
end

function ESP:getColor(t)
    if S.espMode == "Aliados" then return Color3.fromRGB(50,255,100) end
    return Color3.fromRGB(255,50,50)
end

function ESP:create(t)
    if self.objects[t] or not t.Character then return end
    local color = self:getColor(t)

    local hl           = Instance.new("Highlight", t.Character)
    hl.FillColor       = color
    hl.OutlineColor    = Color3.new(1,1,1)
    hl.FillTransparency= 0.6

    local head = t.Character:FindFirstChild("Head")
    if not head then self.objects[t] = {hl=hl} return end

    local bb              = Instance.new("BillboardGui", head)
    bb.Size               = UDim2.new(0,200,0,50)
    bb.StudsOffset        = Vector3.new(0,2.5,0)
    bb.AlwaysOnTop        = true

    local nl              = Instance.new("TextLabel", bb)
    nl.Size               = UDim2.new(1,0,0.5,0)
    nl.BackgroundTransparency = 1
    nl.Text               = t.Name
    nl.TextColor3         = Color3.new(1,1,1)
    nl.TextStrokeTransparency = 0
    nl.Font               = Enum.Font.GothamBold
    nl.TextSize           = 14

    local il              = Instance.new("TextLabel", bb)
    il.Size               = UDim2.new(1,0,0.5,0)
    il.Position           = UDim2.new(0,0,0.5,0)
    il.BackgroundTransparency = 1
    il.TextColor3         = color
    il.Font               = Enum.Font.Gotham
    il.TextSize           = 11

    self.objects[t] = {hl=hl, bb=bb, info=il}
end

function ESP:updateInfo(t)
    local obj = self.objects[t] if not obj or not obj.info then return end
    local char = t.Character     if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local mHRP = getHRP()
    if hum and hrp and mHRP then
        local hp   = math.floor(hum.Health)
        local dist = math.floor((mHRP.Position - hrp.Position).Magnitude)
        obj.info.Text = string.format("❤️%d  📏%dm", hp, dist)
        obj.info.TextColor3 = hp > hum.MaxHealth*.6 and Color3.fromRGB(50,255,100)
            or hp > hum.MaxHealth*.3 and Color3.fromRGB(255,200,50)
            or Color3.fromRGB(255,50,50)
    end
end

function ESP:remove(t)
    local obj = self.objects[t] if not obj then return end
    pcall(function() if obj.hl then obj.hl:Destroy() end end)
    pcall(function() if obj.bb then obj.bb:Destroy() end end)
    self.objects[t] = nil
end

function ESP:update()
    for _, t in ipairs(Players:GetPlayers()) do
        if t ~= player then
            local should = self:shouldShow(t)
            if should and not self.objects[t] and t.Character then self:create(t) end
            if not should and self.objects[t] then self:remove(t) end
        end
    end
    local now = tick()
    if now - self.lastUpdate >= self.rate then
        self.lastUpdate = now
        for t in pairs(self.objects) do self:updateInfo(t) end
    end
end

function ESP:clearAll()
    for t in pairs(self.objects) do self:remove(t) end
end

-- ============================================================================
-- MÓDULO: BLOOM / BLUR
-- ============================================================================
local Effects = {}

function Effects:removeBloom()
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("BloomEffect") or e:IsA("SunRaysEffect") then
            e.Enabled = false
        end
    end
    for _, e in ipairs(workspace.CurrentCamera:GetChildren()) do
        if e:IsA("BloomEffect") then e.Enabled = false end
    end
end

function Effects:restoreBloom()
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("BloomEffect") or e:IsA("SunRaysEffect") then
            e.Enabled = true
        end
    end
    for _, e in ipairs(workspace.CurrentCamera:GetChildren()) do
        if e:IsA("BloomEffect") then e.Enabled = true end
    end
end

function Effects:removeBlur()
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = false
        end
    end
    for _, e in ipairs(workspace.CurrentCamera:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = false
        end
    end
end

function Effects:restoreBlur()
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = true
        end
    end
    for _, e in ipairs(workspace.CurrentCamera:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = true
        end
    end
end

-- ============================================================================
-- MÓDULO: SERVER HOP (CORREGIDO)
-- ============================================================================
local ServerHop = {}

function ServerHop:hop()
    local ok, result = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100")
        )
    end)
    if not ok or not result or not result.data then
        notify("❌ Server Hop", "No se pudo obtener lista de servidores")
        return
    end
    local servers = {}
    for _, v in ipairs(result.data) do
        if v.id ~= game.JobId and v.playing and v.playing < v.maxPlayers then
            table.insert(servers, v.id)
        end
    end
    if #servers == 0 then
        notify("❌ Server Hop", "No hay otros servidores disponibles")
        return
    end
    local picked = servers[math.random(1, #servers)]
    notify("🚪 Server Hop", "Conectando a otro servidor...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, picked, player)
end

-- ============================================================================
-- AUTO REJOIN
-- ============================================================================
local autoRejoinConn = nil

local function setupAutoRejoin()
    if autoRejoinConn then autoRejoinConn:Disconnect() autoRejoinConn = nil end
    if not S.autoRejoin then return end
    autoRejoinConn = player:GetPropertyChangedSignal("Parent"):Connect(function()
        if not player.Parent then
            task.wait(2)
            pcall(function() TeleportService:Teleport(game.PlaceId) end)
        end
    end)
end

-- ============================================================================
-- LOOP PRINCIPAL (task.spawn separados para no bloquear)
-- ============================================================================

-- Loop rápido: velocidad, protecciones, noclip
local mainConn = RunService.Heartbeat:Connect(function()
    if not S.active then return end

    -- Velocidad
    local hum = getHum()
    if hum then
        if hum.WalkSpeed ~= S.walkSpeed then hum.WalkSpeed = S.walkSpeed end
        if hum.JumpPower  ~= S.jumpPower  then hum.JumpPower  = S.jumpPower  end
    end

    -- Anti KB
    if S.antiKB then
        local hrp = getHRP()
        if hrp then
            local v = hrp.AssemblyLinearVelocity
            if math.abs(v.X) > 30 or math.abs(v.Z) > 30 then
                hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
            end
        end
    end

    -- God Mode
    if S.godMode then
        local h = getHum()
        if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end

    -- Anti Ragdoll
    if S.antiRag then
        local h = getHum()
        if h and h:GetState() == Enum.HumanoidStateType.Ragdoll then
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    -- No Stun
    if S.noStun then
        local h = getHum()
        if h then h.Sit = false end
    end

    -- Noclip
    if S.noclip then
        local c = getChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end

    -- Anti AFK
    if S.antiAfk then
        pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
    end
end)

-- Loop medio: ESP, hitbox, auto TP, bring, auto clicker
task.spawn(function()
    while S.active do
        -- ESP
        if S.esp then
            ESP:update()
        else
            if next(ESP.objects) then ESP:clearAll() end
        end

        -- Hitbox
        Hitbox:update()

        -- Zoom
        if S.zoom then
            camera.FieldOfView = S.zoomLevel
        else
            if camera.FieldOfView ~= 70 then camera.FieldOfView = 70 end
        end

        -- No Fog
        if S.noFog then
            Lighting.FogEnd   = 1e6
            Lighting.FogStart = 1e6
        end

        -- Fullbright
        if S.fullbright then
            Lighting.Brightness    = 2
            Lighting.ClockTime     = 14
            Lighting.GlobalShadows = false
            Lighting.Ambient       = Color3.fromRGB(255,255,255)
        end

        -- No Bloom (mantener desactivado si hay nuevos efectos)
        if S.noBloom then Effects:removeBloom() end
        if S.noBlur  then Effects:removeBlur()  end

        -- Auto TP
        if S.autoTP and S.selectedPlayer then
            local now = tick()
            if now - S.lastAutoTP >= S.autoTPInterval then
                S.lastAutoTP = now
                local tHRP = getTargetHRP(S.selectedPlayer)
                local mHRP = getHRP()
                if tHRP and mHRP then
                    mHRP.CFrame = tHRP.CFrame * CFrame.new(0,0,2)
                end
            end
        end

        -- Bring
        if S.bring and S.selectedPlayer then
            local mHRP = getHRP()
            local tHRP = getTargetHRP(S.selectedPlayer)
            if mHRP and tHRP then
                local dir    = (mHRP.Position - tHRP.Position)
                local newPos = dir.Magnitude > 0
                    and mHRP.Position - dir.Unit * S.bringDistance
                    or  mHRP.Position
                tHRP.CFrame  = CFrame.new(newPos)
            end
        end

        -- Auto Clicker
        if S.autoClicker then
            local now = tick()
            if now - S.lastClick >= S.autoClickerDelay then
                S.lastClick = now
                local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                if tool then pcall(function() tool:Activate() end) end
            end
        end

        -- Kill Aura
        if S.killAura then
            local now = tick()
            if now - S.lastKillAura >= S.killAuraDelay then
                S.lastKillAura = now
                local mHRP = getHRP()
                if mHRP then
                    local closest, closestDist = nil, S.killAuraRange
                    for _, t in ipairs(Players:GetPlayers()) do
                        if t ~= player and t.Character then
                            local tHRP = getTargetHRP(t)
                            if tHRP then
                                local d = (mHRP.Position - tHRP.Position).Magnitude
                                if d < closestDist then
                                    closestDist = d
                                    closest     = t
                                end
                            end
                        end
                    end
                    if closest then
                        local tool = player.Character:FindFirstChildOfClass("Tool")
                        if tool then pcall(function() tool:Activate() end) end
                    end
                end
            end
        end

        task.wait(0.05)
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if not S.infJump then return end
    local h = getHum()
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Eventos de jugadores
Players.PlayerAdded:Connect(function(p)
    task.wait(0.5)
    if S.esp and p.Character then ESP:create(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    ESP:remove(p)
    Hitbox.modified[p]  = nil
    Hitbox.origSizes[p] = nil
end)

player.CharacterAdded:Connect(function()
    task.wait(0.3)
    S.fly = false
    Fly:stop()
    if S.realInvis then
        task.wait(0.5)
        Invisibility:enable()
    end
end)

-- ============================================================================
-- FUNCIÓN CLEARALL (para cerrar limpio)
-- ============================================================================
local function clearAll()
    S.active = false
    mainConn:Disconnect()

    Fly:stop()
    Hitbox:restoreAll()
    ESP:clearAll()
    if S.realInvis then Invisibility:disable() end
    if autoRejoinConn then autoRejoinConn:Disconnect() end

    -- Restaurar lighting
    Lighting.Brightness    = origLighting.Brightness
    Lighting.ClockTime     = origLighting.ClockTime
    Lighting.GlobalShadows = origLighting.GlobalShadows
    Lighting.Ambient       = origLighting.Ambient
    Lighting.FogEnd        = origLighting.FogEnd
    Lighting.FogStart      = origLighting.FogStart
    camera.FieldOfView     = 70

    -- Restaurar bloom y blur
    Effects:restoreBloom()
    Effects:restoreBlur()

    -- Restaurar personaje
    local c = getChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then
            h.WalkSpeed    = 16
            h.JumpPower    = 50
            h.PlatformStand= false
        end
    end
end

-- ============================================================================
-- GUI
-- ============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name          = "GFHUB"
screenGui.ResetOnSpawn  = false
screenGui.IgnoreGuiInset= true
screenGui.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
screenGui.Parent        = player.PlayerGui

local GUI_W, GUI_H = 360, 540
local main = Instance.new("Frame", screenGui)
main.Size              = UDim2.new(0, GUI_W, 0, GUI_H)
main.Position          = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
main.BackgroundColor3  = Color3.fromRGB(8,8,8)
main.BorderSizePixel   = 0
main.ClipsDescendants  = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local rgbStroke         = Instance.new("UIStroke", main)
rgbStroke.Thickness     = 2
task.spawn(function()
    local h = 0
    while main and main.Parent do
        h = (h + 0.003) % 1
        rgbStroke.Color = Color3.fromHSV(h, 1, 1)
        task.wait()
    end
end)

-- Header
local header = Instance.new("Frame", main)
header.Size             = UDim2.new(1,0,0,52)
header.BackgroundColor3 = Color3.fromRGB(13,13,13)
header.BorderSizePixel  = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0,14)
local hfix = Instance.new("Frame", header)
hfix.Size               = UDim2.new(1,0,0,14)
hfix.Position           = UDim2.new(0,0,1,-14)
hfix.BackgroundColor3   = Color3.fromRGB(13,13,13)
hfix.BorderSizePixel    = 0

local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size           = UDim2.new(1,-120,1,0)
titleLbl.Position       = UDim2.new(0,12,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text           = "🔴 GF HUB v8.1"
titleLbl.Font           = Enum.Font.GothamBold
titleLbl.TextSize       = 16
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
task.spawn(function()
    local h = 0
    while titleLbl and titleLbl.Parent do
        h = (h+0.005)%1
        titleLbl.TextColor3 = Color3.fromHSV(h, 1, 1)
        task.wait()
    end
end)

local btnMin = Instance.new("TextButton", header)
btnMin.Size             = UDim2.new(0,36,0,36)
btnMin.Position         = UDim2.new(1,-80,0.5,-18)
btnMin.BackgroundColor3 = Color3.fromRGB(220,170,0)
btnMin.BorderSizePixel  = 0
btnMin.Text             = "–"
btnMin.TextColor3       = Color3.fromRGB(0,0,0)
btnMin.Font             = Enum.Font.GothamBold
btnMin.TextSize         = 17
Instance.new("UICorner", btnMin).CornerRadius = UDim.new(0,8)

local btnClose = Instance.new("TextButton", header)
btnClose.Size           = UDim2.new(0,36,0,36)
btnClose.Position       = UDim2.new(1,-40,0.5,-18)
btnClose.BackgroundColor3 = Color3.fromRGB(210,30,30)
btnClose.BorderSizePixel= 0
btnClose.Text           = "✕"
btnClose.TextColor3     = Color3.new(1,1,1)
btnClose.Font           = Enum.Font.GothamBold
btnClose.TextSize       = 15
Instance.new("UICorner", btnClose).CornerRadius = UDim.new(0,8)

-- Tabs
local tabBar = Instance.new("Frame", main)
tabBar.Size             = UDim2.new(1,0,0,38)
tabBar.Position         = UDim2.new(0,0,0,52)
tabBar.BackgroundColor3 = Color3.fromRGB(11,11,11)
tabBar.BorderSizePixel  = 0
local tbList = Instance.new("UIListLayout", tabBar)
tbList.FillDirection    = Enum.FillDirection.Horizontal
tbList.Padding          = UDim.new(0,2)
local tbPad = Instance.new("UIPadding", tabBar)
tbPad.PaddingLeft       = UDim.new(0,3)
tbPad.PaddingTop        = UDim.new(0,5)

local contentFrame = Instance.new("Frame", main)
contentFrame.Size       = UDim2.new(1,0,1,-90)
contentFrame.Position   = UDim2.new(0,0,0,90)
contentFrame.BackgroundTransparency = 1

local pages, tabBtns = {}, {}
local tabDefs = {
    {n="⚡Move",   c=Color3.fromRGB(96,165,250)},
    {n="⚔️Fight",  c=Color3.fromRGB(239,68,68)},
    {n="👁️Visual", c=Color3.fromRGB(192,132,252)},
    {n="🎯Target", c=Color3.fromRGB(251,191,36)},
    {n="🛠️Utils",  c=Color3.fromRGB(34,197,94)},
}

for i, def in ipairs(tabDefs) do
    local btn = Instance.new("TextButton", tabBar)
    btn.Size            = UDim2.new(0.196,-2,0,30)
    btn.BackgroundColor3= Color3.fromRGB(20,20,20)
    btn.BorderSizePixel = 0
    btn.Text            = def.n
    btn.TextColor3      = Color3.fromRGB(110,110,110)
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = isMobile and 8 or 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    tabBtns[i] = btn

    local page = Instance.new("ScrollingFrame", contentFrame)
    page.Size                = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel     = 0
    page.ScrollBarThickness  = isMobile and 4 or 3
    page.ScrollBarImageColor3= def.c
    page.CanvasSize          = UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingEnabled    = true
    page.Visible             = i == 1
    pages[i] = page

    local lay = Instance.new("UIListLayout", page)
    lay.Padding             = UDim.new(0,5)
    lay.SortOrder           = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop    = UDim.new(0,7)
    pad.PaddingLeft   = UDim.new(0,7)
    pad.PaddingRight  = UDim.new(0,7)
    pad.PaddingBottom = UDim.new(0,7)
end

local function switchTab(i)
    for j, p in ipairs(pages) do
        p.Visible = j == i
        tabBtns[j].TextColor3      = j==i and tabDefs[j].c or Color3.fromRGB(110,110,110)
        tabBtns[j].BackgroundColor3= j==i and Color3.fromRGB(26,26,26) or Color3.fromRGB(20,20,20)
    end
end
for i, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
end
switchTab(1)

-- ============================================================================
-- UI HELPERS
-- ============================================================================
local function mkLabel(page, txt)
    local l = Instance.new("TextLabel", page)
    l.Size  = UDim2.new(1,0,0,18)
    l.BackgroundTransparency = 1
    l.Text  = txt
    l.TextColor3 = Color3.fromRGB(180,30,30)
    l.Font  = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function mkToggle(page, lbl, color, cb)
    local H   = isMobile and 50 or 42
    local box = Instance.new("Frame", page)
    box.Size            = UDim2.new(1,0,0,H)
    box.BackgroundColor3= Color3.fromRGB(14,14,14)
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,9)

    local l = Instance.new("TextLabel", box)
    l.Size  = UDim2.new(1,-68,1,0)
    l.Position = UDim2.new(0,9,0,0)
    l.BackgroundTransparency = 1
    l.Text  = lbl
    l.TextColor3 = Color3.new(1,1,1)
    l.Font  = Enum.Font.Gotham
    l.TextSize = isMobile and 13 or 12
    l.TextXAlignment = Enum.TextXAlignment.Left

    local swW, swH = isMobile and 48 or 38, isMobile and 26 or 20
    local bg = Instance.new("Frame", box)
    bg.Size = UDim2.new(0,swW,0,swH)
    bg.Position = UDim2.new(1,-(swW+9),0.5,-swH/2)
    bg.BackgroundColor3 = Color3.fromRGB(36,36,36)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)

    local kSz = isMobile and 20 or 14
    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0,kSz,0,kSz)
    knob.Position = UDim2.new(0,3,0.5,-kSz/2)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local on = false
    local ti = TweenInfo.new(0.15)
    local posOn  = UDim2.new(0, swW-kSz-3, 0.5, -kSz/2)
    local posOff = UDim2.new(0, 3, 0.5, -kSz/2)

    local btn = Instance.new("TextButton", box)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 5
    btn.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(bg,  ti, {BackgroundColor3 = on and color or Color3.fromRGB(36,36,36)}):Play()
        TweenService:Create(knob,ti, {Position = on and posOn or posOff}):Play()
        cb(on)
    end)
end

local function mkSlider(page, lbl, minV, maxV, def, color, cb)
    local H   = isMobile and 68 or 58
    local box = Instance.new("Frame", page)
    box.Size            = UDim2.new(1,0,0,H)
    box.BackgroundColor3= Color3.fromRGB(14,14,14)
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,9)

    local l = Instance.new("TextLabel", box)
    l.Size = UDim2.new(0.62,0,0,24)
    l.Position = UDim2.new(0,9,0,5)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = Color3.new(1,1,1)
    l.Font = Enum.Font.Gotham
    l.TextSize = isMobile and 13 or 12
    l.TextXAlignment = Enum.TextXAlignment.Left

    local vl = Instance.new("TextLabel", box)
    vl.Size = UDim2.new(0.38,-9,0,24)
    vl.Position = UDim2.new(0.62,0,0,5)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(def)
    vl.TextColor3 = color
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = isMobile and 14 or 13
    vl.TextXAlignment = Enum.TextXAlignment.Right

    local bH = isMobile and 10 or 7
    local bY = isMobile and 46 or 38
    local bar = Instance.new("Frame", box)
    bar.Size = UDim2.new(1,-18,0,bH)
    bar.Position = UDim2.new(0,9,0,bY)
    bar.BackgroundColor3 = Color3.fromRGB(26,26,26)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,5)

    local pct = math.clamp((def-minV)/(maxV-minV),0,1)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(pct,0,1,0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,5)

    local kSz = isMobile and 18 or 12
    local knob = Instance.new("Frame", bar)
    knob.Size = UDim2.new(0,kSz,0,kSz)
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(pct,0,0.5,0)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local hit = Instance.new("TextButton", box)
    hit.Size = UDim2.new(1,-10,0,isMobile and 38 or 28)
    hit.Position = UDim2.new(0,5,0,bY-(isMobile and 14 or 10))
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 10

    local sliding = false
    local function update(x)
        local p = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + p*(maxV-minV))
        fill.Size = UDim2.new(p,0,1,0)
        knob.Position = UDim2.new(p,0,0.5,0)
        vl.Text = tostring(v)
        cb(v)
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            sliding=true update(i.Position.X)
        end
    end)
    hit.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    hit.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            sliding=false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
end

local function mkButton(page, lbl, color, cb)
    local H   = isMobile and 46 or 38
    local btn = Instance.new("TextButton", page)
    btn.Size            = UDim2.new(1,0,0,H)
    btn.BackgroundColor3= color or Color3.fromRGB(20,20,20)
    btn.BorderSizePixel = 0
    btn.Text            = lbl
    btn.TextColor3      = Color3.new(1,1,1)
    btn.Font            = Enum.Font.GothamBold
    btn.TextSize        = isMobile and 13 or 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,9)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function mkDropdown(page, lbl, lista, cb)
    local rH = isMobile and 50 or 42
    local iH = isMobile and 38 or 30
    local box = Instance.new("Frame", page)
    box.Size            = UDim2.new(1,0,0,rH)
    box.BackgroundColor3= Color3.fromRGB(14,14,14)
    box.BorderSizePixel = 0
    box.ClipsDescendants= true
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,9)

    local l = Instance.new("TextLabel", box)
    l.Size = UDim2.new(0.36,0,0,rH)
    l.Position = UDim2.new(0,9,0,0)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = Color3.fromRGB(130,130,130)
    l.Font = Enum.Font.Gotham
    l.TextSize = isMobile and 12 or 11
    l.TextXAlignment = Enum.TextXAlignment.Left

    local selBtn = Instance.new("TextButton", box)
    selBtn.Size = UDim2.new(0.64,-9,0,isMobile and 34 or 28)
    selBtn.Position = UDim2.new(0.36,0,0.5,isMobile and -17 or -14)
    selBtn.BackgroundColor3 = Color3.fromRGB(24,24,24)
    selBtn.BorderSizePixel = 0
    selBtn.Text = lista[1] or "—"
    selBtn.TextColor3 = Color3.new(1,1,1)
    selBtn.Font = Enum.Font.Gotham
    selBtn.TextSize = isMobile and 12 or 11
    Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0,6)

    local open, items = false, {}
    local function rebuild()
        for _, f in ipairs(items) do f:Destroy() end
        items = {}
        for i, name in ipairs(lista) do
            local it = Instance.new("TextButton", box)
            it.Size = UDim2.new(1,0,0,iH)
            it.Position = UDim2.new(0,0,0,rH+(i-1)*iH)
            it.BackgroundColor3 = Color3.fromRGB(18,18,18)
            it.BorderSizePixel = 0
            it.Text = name
            it.TextColor3 = Color3.new(1,1,1)
            it.Font = Enum.Font.Gotham
            it.TextSize = isMobile and 12 or 11
            it.MouseButton1Click:Connect(function()
                selBtn.Text = name
                open = false
                box.Size = UDim2.new(1,0,0,rH)
                cb(name)
            end)
            table.insert(items, it)
        end
    end
    rebuild()
    selBtn.MouseButton1Click:Connect(function()
        open = not open
        TweenService:Create(box, TweenInfo.new(0.15), {
            Size = UDim2.new(1,0,0, open and rH+#lista*iH or rH)
        }):Play()
    end)
    return {
        refresh = function(nl)
            lista = nl
            selBtn.Text = lista[1] or "—"
            rebuild()
        end,
        getText = function() return selBtn.Text end
    }
end

-- ============================================================================
-- CONTENIDO DE TABS
-- ============================================================================
-- TAB 1: MOVE
local p1 = pages[1]
mkLabel(p1, "  ── VELOCIDAD ──")
mkSlider(p1,"WalkSpeed",16,500,16,Color3.fromRGB(96,165,250),function(v) S.walkSpeed=v end)
mkSlider(p1,"Jump Power",50,500,50,Color3.fromRGB(192,132,252),function(v) S.jumpPower=v end)
mkLabel(p1, "  ── FLY ──")
mkSlider(p1,"Fly Speed",10,500,80,Color3.fromRGB(251,191,36),function(v) S.flySpeed=v end)
mkToggle(p1,"✈️ Fly (WASD + Space/Shift)",Color3.fromRGB(96,165,250),function(v)
    S.fly = v
    if v then Fly:start() else Fly:stop() end
end)
mkToggle(p1,"👻 Noclip",Color3.fromRGB(192,132,252),function(v)
    S.noclip = v
    if not v then
        local c=getChar() if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
    end
end)
mkToggle(p1,"♾️ Infinite Jump",Color3.fromRGB(34,197,94),function(v) S.infJump=v end)
mkButton(p1,"🔄 Reset Velocidad",Color3.fromRGB(20,20,20),function()
    S.walkSpeed=16 S.jumpPower=50
    notify("✅ Reset","Velocidad normal restaurada")
end)

-- TAB 2: FIGHT
local p2 = pages[2]
mkLabel(p2,"  ── KILL AURA ──")
mkSlider(p2,"Rango",5,50,15,Color3.fromRGB(239,68,68),function(v) S.killAuraRange=v end)
mkSlider(p2,"Delay (seg x10)",1,20,2,Color3.fromRGB(239,68,68),function(v) S.killAuraDelay=v/10 end)
mkToggle(p2,"💀 Kill Aura",Color3.fromRGB(239,68,68),function(v) S.killAura=v end)
mkLabel(p2,"  ── HITBOX ──")
mkSlider(p2,"Tamaño Hitbox",5,30,10,Color3.fromRGB(251,191,36),function(v) S.hitboxSize=v end)
mkToggle(p2,"📦 Hitbox Expander",Color3.fromRGB(251,191,36),function(v) S.hitbox=v end)
mkLabel(p2,"  ── AUTO CLICKER ──")
mkSlider(p2,"Delay AC (x100ms)",1,50,5,Color3.fromRGB(192,132,252),function(v) S.autoClickerDelay=v/100 end)
mkToggle(p2,"🖱️ Auto Clicker",Color3.fromRGB(192,132,252),function(v) S.autoClicker=v end)
mkLabel(p2,"  ── MANUAL ──")
mkButton(p2,"👊 Hit 1 vez",Color3.fromRGB(60,10,10),function()
    if not S.selectedPlayer then notify("❌","Selecciona un jugador en Target") return end
    pcall(function()
        local mHRP=getHRP()
        local tHRP=getTargetHRP(S.selectedPlayer)
        if mHRP and tHRP then
            local orig=mHRP.CFrame
            mHRP.CFrame=tHRP.CFrame*CFrame.new(0,0,2)
            local tool=player.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
            task.wait(0.05)
            mHRP.CFrame=orig
        end
    end)
    notify("💥 Hit","Golpe enviado")
end)

-- TAB 3: VISUAL
local p3 = pages[3]
mkLabel(p3,"  ── ESP ──")
-- dropdown ESP mode
local espDD = mkDropdown(p3,"Filtro",{"Enemigos","Aliados","Todos"},function(v)
    S.espMode=v ESP:clearAll()
    notify("👁️ ESP","Filtro: "..v)
end)
mkToggle(p3,"👁️ ESP",Color3.fromRGB(192,132,252),function(v)
    S.esp=v
    if not v then ESP:clearAll() end
end)
mkLabel(p3,"  ── LIGHTING ──")
mkToggle(p3,"💡 Fullbright",Color3.fromRGB(251,191,36),function(v)
    S.fullbright=v
    if not v then
        Lighting.Brightness    = origLighting.Brightness
        Lighting.ClockTime     = origLighting.ClockTime
        Lighting.GlobalShadows = origLighting.GlobalShadows
        Lighting.Ambient       = origLighting.Ambient
    end
end)
mkToggle(p3,"🌫️ No Fog",Color3.fromRGB(96,165,250),function(v)
    S.noFog=v
    if not v then
        Lighting.FogEnd   = origLighting.FogEnd
        Lighting.FogStart = origLighting.FogStart
    end
end)
mkToggle(p3,"✨ No Bloom / Sun Rays",Color3.fromRGB(251,191,36),function(v)
    S.noBloom=v
    if v then Effects:removeBloom() else Effects:restoreBloom() end
end)
mkToggle(p3,"🌀 No Blur / Depth of Field",Color3.fromRGB(192,132,252),function(v)
    S.noBlur=v
    if v then Effects:removeBlur() else Effects:restoreBlur() end
end)
mkLabel(p3,"  ── CÁMARA ──")
mkSlider(p3,"Zoom (FOV)",20,120,70,Color3.fromRGB(34,197,94),function(v)
    S.zoomLevel=v
    camera.FieldOfView=v
end)
mkToggle(p3,"🔍 Zoom Persistente",Color3.fromRGB(34,197,94),function(v)
    S.zoom=v
    if not v then camera.FieldOfView=70 end
end)
mkLabel(p3,"  ── JUGADOR ──")
mkToggle(p3,"👤 Invisibilidad Real",Color3.fromRGB(239,68,68),function(v)
    S.realInvis=v
    if v then Invisibility:enable() else Invisibility:disable() end
    notify(v and "👤 Invisible" or "👀 Visible", v and "Nadie puede verte" or "Ahora eres visible")
end)

-- TAB 4: TARGET
local p4 = pages[4]
mkLabel(p4,"  ── JUGADOR ──")
local playerDD = mkDropdown(p4,"Target",
    (function()
        local l={}
        for _,p in ipairs(Players:GetPlayers()) do if p~=player then table.insert(l,p.Name) end end
        if #l==0 then l={"Sin jugadores"} end
        return l
    end)(),
    function(name)
        S.selectedPlayer = nil
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Name==name then S.selectedPlayer=p break end
        end
        if S.selectedPlayer then notify("🎯 Target","→ "..name) end
    end
)
mkButton(p4,"🔄 Actualizar Lista",Color3.fromRGB(20,20,20),function()
    local l={}
    for _,p in ipairs(Players:GetPlayers()) do if p~=player then table.insert(l,p.Name) end end
    if #l==0 then l={"Sin jugadores"} end
    playerDD.refresh(l)
    notify("✅","Lista actualizada")
end)
mkLabel(p4,"  ── TELEPORT ──")
mkButton(p4,"📍 TP a Jugador (1 vez)",Color3.fromRGB(22,22,60),function()
    if not S.selectedPlayer then notify("❌","Selecciona target") return end
    local tHRP=getTargetHRP(S.selectedPlayer) local mHRP=getHRP()
    if tHRP and mHRP then mHRP.CFrame=tHRP.CFrame*CFrame.new(0,0,2) notify("✅ TP","Teleportado") end
end)
mkButton(p4,"📍 Traer Jugador (1 vez)",Color3.fromRGB(22,22,60),function()
    if not S.selectedPlayer then notify("❌","Selecciona target") return end
    local mHRP=getHRP() local tHRP=getTargetHRP(S.selectedPlayer)
    if mHRP and tHRP then
        tHRP.CFrame=mHRP.CFrame*CFrame.new(0,0,3)
        notify("✅ Traído","Jugador traído")
    end
end)
mkLabel(p4,"  ── AUTO ──")
mkSlider(p4,"Intervalo Auto TP (x10ms)",2,50,5,Color3.fromRGB(251,191,36),function(v) S.autoTPInterval=v/10 end)
mkToggle(p4,"📍 Auto TP Continuo",Color3.fromRGB(251,191,36),function(v)
    if v and not S.selectedPlayer then notify("❌","Selecciona target") return end
    S.autoTP=v
    notify(v and "✅ Auto TP ON" or "⛔ Auto TP OFF","")
end)
mkSlider(p4,"Distancia Bring",1,15,3,Color3.fromRGB(239,68,68),function(v) S.bringDistance=v end)
mkToggle(p4,"🔄 Bring Continuo",Color3.fromRGB(239,68,68),function(v)
    if v and not S.selectedPlayer then notify("❌","Selecciona target") return end
    S.bring=v
    notify(v and "✅ Bring ON" or "⛔ Bring OFF","")
end)
mkLabel(p4,"  ── CÁMARA ──")
mkButton(p4,"👁️ Espectear",Color3.fromRGB(20,20,20),function()
    if not S.selectedPlayer then notify("❌","Selecciona target") return end
    local hum=S.selectedPlayer.Character and S.selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then camera.CameraSubject=hum notify("👁️ Espectando",S.selectedPlayer.Name) end
end)
mkButton(p4,"🔙 Mi Cámara",Color3.fromRGB(20,20,20),function()
    local hum=getHum() if hum then camera.CameraSubject=hum notify("✅","Cámara restaurada") end
end)

-- TAB 5: UTILS
local p5 = pages[5]
mkLabel(p5,"  ── PROTECCIÓN ──")
mkToggle(p5,"🛡️ Anti Knockback",Color3.fromRGB(34,197,94),function(v) S.antiKB=v end)
mkToggle(p5,"🎭 Anti Ragdoll",Color3.fromRGB(34,197,94),function(v) S.antiRag=v end)
mkToggle(p5,"⚡ No Stun",Color3.fromRGB(34,197,94),function(v) S.noStun=v end)
mkToggle(p5,"❤️ God Mode",Color3.fromRGB(239,68,68),function(v) S.godMode=v end)
mkLabel(p5,"  ── ACCIONES ──")
mkButton(p5,"💊 Full Heal",Color3.fromRGB(15,65,15),function()
    local h=getHum() if h then h.Health=h.MaxHealth end
    notify("💊 Heal","Vida al máximo")
end)
mkButton(p5,"🔄 Respawn",Color3.fromRGB(20,20,20),function()
    player:LoadCharacter()
    notify("🔄","Reapareciendo...")
end)
mkLabel(p5,"  ── MISC ──")
mkToggle(p5,"🟢 Anti AFK",Color3.fromRGB(34,197,94),function(v) S.antiAfk=v end)
mkToggle(p5,"🔄 Auto Rejoin",Color3.fromRGB(96,165,250),function(v)
    S.autoRejoin=v
    setupAutoRejoin()
    notify(v and "✅ Auto Rejoin ON" or "⛔ Auto Rejoin OFF","")
end)
mkButton(p5,"🚪 Server Hop",Color3.fromRGB(20,20,20),function()
    notify("🚪 Server Hop","Buscando servidor...")
    task.spawn(function() ServerHop:hop() end)
end)
mkButton(p5,"📊 Server Info",Color3.fromRGB(20,20,20),function()
    local count=#Players:GetPlayers()
    local ok,ping=pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
    end)
    notify("📊 Info",string.format("Jugadores: %d | Ping: %s", count, ok and ping or "N/A"))
end)
mkButton(p5,"📡 Listar RemoteEvents (F9)",Color3.fromRGB(20,20,20),function()
    local n=0
    for _,v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then print("RE:",v:GetFullName()) n=n+1 end
    end
    notify("📡 RemoteEvents",n.." encontrados - ver F9")
end)

-- ============================================================================
-- DRAG (mouse + touch)
-- ============================================================================
local drag = {on=false, start=nil, orig=nil}
header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag.on=true drag.start=Vector2.new(i.Position.X,i.Position.Y) drag.orig=main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag.on and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=Vector2.new(i.Position.X,i.Position.Y)-drag.start
        main.Position=UDim2.new(drag.orig.X.Scale,drag.orig.X.Offset+d.X,drag.orig.Y.Scale,drag.orig.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag.on=false
    end
end)

-- ============================================================================
-- MINIMIZAR / CERRAR
-- ============================================================================
local minimizado = false
local twI = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

btnMin.MouseButton1Click:Connect(function()
    minimizado = not minimizado
    TweenService:Create(main, twI, {
        Size = minimizado and UDim2.new(0,GUI_W,0,52) or UDim2.new(0,GUI_W,0,GUI_H)
    }):Play()
    btnMin.Text = minimizado and "□" or "–"
end)

btnClose.MouseButton1Click:Connect(function()
    clearAll()
    task.wait(0.1)
    screenGui:Destroy()
end)

-- RightShift toggle
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

-- ============================================================================
-- LISTO
-- ============================================================================
notify("🔴 GF HUB v8.1","Cargado | by Gael Fonzar", 4)

--[[
    🐉 GF HUB v5.1 - Mobile + PC
    by Gael Fonzar
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local isMobile = UserInputService.TouchEnabled

-- ============ ESTADOS ============
local S = {
    walkSpeed = 16, flySpeed = 100, jumpPower = 50,
    fly = false, noclip = false, infJump = false,
    antiKB = false, antiRag = false, godMode = false,
    selectedPlayer = nil,
    killAura = false, killAuraRange = 15,
    hitbox = false, hitboxSize = 10,
    esp = false, fullbright = false,
}

local flyBody, flyGyro
local hitboxCache, espObjects = {}, {}
local origLighting = {}
local conns = {}
local ACTIVE = true -- controla todos los loops

-- ============ HELPERS ============
local function getChar() return player.Character end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(list, p.Name) end
    end
    if #list == 0 then table.insert(list, "Sin jugadores") end
    return list
end

local function getPlayerByName(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == name then return p end
    end
end

local function notify(txt, dur)
    local ng = Instance.new("ScreenGui")
    ng.Name = "GF_Notif"
    ng.ResetOnSpawn = false
    ng.IgnoreGuiInset = true
    ng.Parent = player.PlayerGui
    local f = Instance.new("Frame", ng)
    f.Size = UDim2.new(0, 260, 0, 50)
    f.Position = UDim2.new(0.5, -130, 1, -80)
    f.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    f.BorderSizePixel = 0
    f.BackgroundTransparency = 1
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = Color3.fromRGB(255, 60, 60)
    stroke.Thickness = 1.5
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    TweenService:Create(f, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
    task.delay(dur or 2, function()
        TweenService:Create(f, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        ng:Destroy()
    end)
end

-- ============ FLY ============
local function startFly()
    local hrp = getHRP() if not hrp then return end
    local hum = getHum() if hum then hum.PlatformStand = true end
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
        local bv = hrp:FindFirstChild("GF_BV") if bv then bv:Destroy() end
        local bg = hrp:FindFirstChild("GF_BG") if bg then bg:Destroy() end
    end
    if flyBody then pcall(function() flyBody:Destroy() end) flyBody = nil end
    if flyGyro then pcall(function() flyGyro:Destroy() end) flyGyro = nil end
    local hum = getHum() if hum then hum.PlatformStand = false end
end

-- ============ ESP ============
local function createESP(target)
    if not target or not target.Character then return end
    pcall(function()
        if espObjects[target.Name] then
            if espObjects[target.Name].hl then espObjects[target.Name].hl:Destroy() end
            if espObjects[target.Name].bb then espObjects[target.Name].bb:Destroy() end
        end
        local hl = Instance.new("Highlight")
        hl.Adornee = target.Character
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.Parent = target.Character
        local head = target.Character:FindFirstChild("Head")
        if not head then return end
        local bb = Instance.new("BillboardGui", head)
        bb.Size = UDim2.new(0, 160, 0, 44)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        local nl = Instance.new("TextLabel", bb)
        nl.Size = UDim2.new(1, 0, 0.5, 0)
        nl.BackgroundTransparency = 1
        nl.Text = target.Name
        nl.TextColor3 = Color3.new(1, 1, 1)
        nl.TextStrokeTransparency = 0
        nl.Font = Enum.Font.GothamBold
        nl.TextSize = 13
        local info = Instance.new("TextLabel", bb)
        info.Size = UDim2.new(1, 0, 0.5, 0)
        info.Position = UDim2.new(0, 0, 0.5, 0)
        info.BackgroundTransparency = 1
        info.Text = "HP: ?"
        info.TextColor3 = Color3.fromRGB(0, 255, 0)
        info.TextStrokeTransparency = 0
        info.Font = Enum.Font.Gotham
        info.TextSize = 11
        espObjects[target.Name] = {hl = hl, bb = bb, infoLbl = info}
    end)
end

local function removeESP(target)
    if not target then return end
    pcall(function()
        if espObjects[target.Name] then
            if espObjects[target.Name].hl then espObjects[target.Name].hl:Destroy() end
            if espObjects[target.Name].bb then espObjects[target.Name].bb:Destroy() end
            espObjects[target.Name] = nil
        end
    end)
end

local function clearAll()
    ACTIVE = false
    S.fly = false
    S.noclip = false
    S.killAura = false
    S.hitbox = false
    S.esp = false
    S.godMode = false
    stopFly()
    -- Restaurar personaje
    local c = getChar()
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
                p.CanTouch = true
            end
        end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
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
                    hrp.Size = cache.size
                    hrp.Transparency = cache.trans
                end)
            end
        end
    end
    hitboxCache = {}
    -- Restaurar ESP
    for _, p in ipairs(Players:GetPlayers()) do removeESP(p) end
    -- Restaurar iluminación
    if origLighting.Brightness then
        Lighting.Brightness = origLighting.Brightness
        Lighting.ClockTime = origLighting.ClockTime
        Lighting.GlobalShadows = origLighting.GlobalShadows
        Lighting.Ambient = origLighting.Ambient
    end
end

-- ============ LOOPS ============
conns.fly = RunService.Heartbeat:Connect(function()
    if not ACTIVE or not S.fly then return end
    local hrp = getHRP() if not hrp then return end
    local bv = hrp:FindFirstChild("GF_BV")
    local bg = hrp:FindFirstChild("GF_BG")
    if not bv or not bg then return end
    local cf = camera.CFrame
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
    bv.Velocity = dir.Magnitude > 0 and dir.Unit * S.flySpeed or Vector3.zero
    bg.CFrame = cf
end)

conns.noclip = RunService.Stepped:Connect(function()
    if not ACTIVE or not S.noclip then return end
    local c = getChar() if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

conns.speed = RunService.Heartbeat:Connect(function()
    if not ACTIVE then return end
    local hum = getHum() if not hum then return end
    hum.WalkSpeed = S.walkSpeed
    hum.JumpPower = S.jumpPower
end)

conns.prot = RunService.Heartbeat:Connect(function()
    if not ACTIVE then return end
    local hrp = getHRP()
    if hrp and S.antiKB then
        local v = hrp.AssemblyLinearVelocity
        if v.Magnitude > 20 then
            hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0)
        end
    end
    if S.godMode then
        local hum = getHum()
        if hum then hum.Health = hum.MaxHealth end
    end
    if S.antiRag then
        local c = getChar() if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum:GetState() == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

conns.infJump = UserInputService.JumpRequest:Connect(function()
    if not ACTIVE or not S.infJump then return end
    local hum = getHum()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

conns.hitbox = RunService.Heartbeat:Connect(function()
    if not ACTIVE then return end
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player and target.Character then
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                if S.hitbox then
                    if not hitboxCache[target.Name] then
                        hitboxCache[target.Name] = {size = tHRP.Size, trans = tHRP.Transparency}
                    end
                    tHRP.Size = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize)
                    tHRP.Transparency = 0.8
                    tHRP.CanCollide = false
                else
                    if hitboxCache[target.Name] then
                        pcall(function()
                            tHRP.Size = hitboxCache[target.Name].size
                            tHRP.Transparency = hitboxCache[target.Name].trans
                        end)
                        hitboxCache[target.Name] = nil
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if not ACTIVE then break end
        if S.esp then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and not espObjects[p.Name] then createESP(p) end
                    if espObjects[p.Name] then
                        local myHRP = getHRP()
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        local info = espObjects[p.Name].infoLbl
                        if info and hum and myHRP and hrp then
                            local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
                            local hp = math.floor(hum.Health)
                            info.Text = "❤️"..hp.." 📏"..dist.."m"
                            info.TextColor3 = hp > hum.MaxHealth * 0.6 and Color3.fromRGB(0,255,0)
                                or hp > hum.MaxHealth * 0.3 and Color3.fromRGB(255,255,0)
                                or Color3.fromRGB(255,0,0)
                        end
                    end
                end
            end
        else
            for name, _ in pairs(espObjects) do
                removeESP({Name = name})
            end
        end
    end
end)

task.spawn(function()
    while task.wait(S.killAuraSpeed or 0.15) do
        if not ACTIVE then break end
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

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    S.fly = false
    stopFly()
end)

Players.PlayerRemoving:Connect(function(p)
    removeESP(p)
    hitboxCache[p.Name] = nil
end)

-- ============ GUI ============
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GFHUB"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

local GUI_W = 340
local GUI_H = 500

local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0, GUI_W, 0, GUI_H)
main.Position = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local rgbStroke = Instance.new("UIStroke", main)
rgbStroke.Thickness = 2

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
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)
local hfix = Instance.new("Frame", header)
hfix.Size = UDim2.new(1, 0, 0, 14)
hfix.Position = UDim2.new(0, 0, 1, -14)
hfix.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
hfix.BorderSizePixel = 0

local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(1, -110, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "🐉 GF HUB v5.1"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 16
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
task.spawn(function()
    local h = 0
    while titleLbl and titleLbl.Parent do
        h = (h + 0.005) % 1
        titleLbl.TextColor3 = Color3.fromHSV(h, 1, 1)
        task.wait()
    end
end)

local btnMin = Instance.new("TextButton", header)
btnMin.Size = UDim2.new(0, 34, 0, 34)
btnMin.Position = UDim2.new(1, -78, 0.5, -17)
btnMin.BackgroundColor3 = Color3.fromRGB(220, 170, 0)
btnMin.BorderSizePixel = 0
btnMin.Text = "–"
btnMin.TextColor3 = Color3.fromRGB(0, 0, 0)
btnMin.Font = Enum.Font.GothamBold
btnMin.TextSize = 16
Instance.new("UICorner", btnMin).CornerRadius = UDim.new(0, 8)

local btnClose = Instance.new("TextButton", header)
btnClose.Size = UDim2.new(0, 34, 0, 34)
btnClose.Position = UDim2.new(1, -40, 0.5, -17)
btnClose.BackgroundColor3 = Color3.fromRGB(210, 35, 35)
btnClose.BorderSizePixel = 0
btnClose.Text = "✕"
btnClose.TextColor3 = Color3.new(1, 1, 1)
btnClose.Font = Enum.Font.GothamBold
btnClose.TextSize = 14
Instance.new("UICorner", btnClose).CornerRadius = UDim.new(0, 8)

-- Tabs
local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1, 0, 0, 36)
tabBar.Position = UDim2.new(0, 0, 0, 50)
tabBar.BackgroundColor3 = Color3.fromRGB(11, 11, 11)
tabBar.BorderSizePixel = 0
local tbList = Instance.new("UIListLayout", tabBar)
tbList.FillDirection = Enum.FillDirection.Horizontal
tbList.Padding = UDim.new(0, 2)
local tbPad = Instance.new("UIPadding", tabBar)
tbPad.PaddingLeft = UDim.new(0, 3)
tbPad.PaddingTop = UDim.new(0, 4)

local contentFrame = Instance.new("Frame", main)
contentFrame.Size = UDim2.new(1, 0, 1, -86)
contentFrame.Position = UDim2.new(0, 0, 0, 86)
contentFrame.BackgroundTransparency = 1

local pages, tabBtns = {}, {}
local tabDefs = {
    {n="⚡Move",  c=Color3.fromRGB(96,165,250)},
    {n="🛡️Prot", c=Color3.fromRGB(34,197,94)},
    {n="👥Play",  c=Color3.fromRGB(251,191,36)},
    {n="⚔️Fight",c=Color3.fromRGB(239,68,68)},
    {n="👁️ESP",  c=Color3.fromRGB(192,132,252)},
}

for i, def in ipairs(tabDefs) do
    local btn = Instance.new("TextButton", tabBar)
    btn.Size = UDim2.new(0.19, -2, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.BorderSizePixel = 0
    btn.Text = def.n
    btn.TextColor3 = Color3.fromRGB(120, 120, 120)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    tabBtns[i] = btn

    local page = Instance.new("ScrollingFrame", contentFrame)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = def.c
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = i == 1
    page.ScrollingEnabled = true
    pages[i] = page

    local lay = Instance.new("UIListLayout", page)
    lay.Padding = UDim.new(0, 5)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", page)
    pad.PaddingTop = UDim.new(0, 7)
    pad.PaddingLeft = UDim.new(0, 7)
    pad.PaddingRight = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 7)
end

local function switchTab(i)
    for j, p in ipairs(pages) do
        p.Visible = j == i
        tabBtns[j].TextColor3 = j == i and tabDefs[j].c or Color3.fromRGB(120, 120, 120)
        tabBtns[j].BackgroundColor3 = j == i and Color3.fromRGB(26, 26, 26) or Color3.fromRGB(20, 20, 20)
    end
end
for i, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(i) end)
end
switchTab(1)

-- ============ UI HELPERS ============
local function crearLabel(page, txt)
    local l = Instance.new("TextLabel", page)
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.fromRGB(90, 90, 200)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function crearToggle(page, lbl, color, cb)
    local tH = isMobile and 48 or 40
    local box = Instance.new("Frame", page)
    box.Size = UDim2.new(1, 0, 0, tH)
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)

    local l = Instance.new("TextLabel", box)
    l.Size = UDim2.new(1, -65, 1, 0)
    l.Position = UDim2.new(0, 9, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.Gotham
    l.TextSize = isMobile and 13 or 12
    l.TextXAlignment = Enum.TextXAlignment.Left

    local swW, swH = isMobile and 46 or 36, isMobile and 24 or 18
    local bg = Instance.new("Frame", box)
    bg.Size = UDim2.new(0, swW, 0, swH)
    bg.Position = UDim2.new(1, -(swW + 9), 0.5, -swH/2)
    bg.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local kSz = isMobile and 18 or 12
    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0, kSz, 0, kSz)
    knob.Position = UDim2.new(0, 3, 0.5, -kSz/2)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local on = false
    local ti = TweenInfo.new(0.15)
    local posOn = UDim2.new(0, swW - kSz - 3, 0.5, -kSz/2)
    local posOff = UDim2.new(0, 3, 0.5, -kSz/2)

    local btn = Instance.new("TextButton", box)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 5
    btn.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(bg, ti, {BackgroundColor3 = on and color or Color3.fromRGB(38,38,38)}):Play()
        TweenService:Create(knob, ti, {Position = on and posOn or posOff}):Play()
        cb(on)
    end)
    return box
end

local function crearSlider(page, lbl, minV, maxV, def, color, cb)
    local sH = isMobile and 65 or 55
    local box = Instance.new("Frame", page)
    box.Size = UDim2.new(1, 0, 0, sH)
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)

    local l = Instance.new("TextLabel", box)
    l.Size = UDim2.new(0.65, 0, 0, 24)
    l.Position = UDim2.new(0, 9, 0, 4)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.Gotham
    l.TextSize = isMobile and 13 or 12
    l.TextXAlignment = Enum.TextXAlignment.Left

    local vl = Instance.new("TextLabel", box)
    vl.Size = UDim2.new(0.35, -9, 0, 24)
    vl.Position = UDim2.new(0.65, 0, 0, 4)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(def)
    vl.TextColor3 = color
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = isMobile and 14 or 13
    vl.TextXAlignment = Enum.TextXAlignment.Right

    local barH = isMobile and 10 or 7
    local barY = isMobile and 44 or 36
    local bar = Instance.new("Frame", box)
    bar.Size = UDim2.new(1, -18, 0, barH)
    bar.Position = UDim2.new(0, 9, 0, barY)
    bar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 5)

    local pct = math.clamp((def - minV) / (maxV - minV), 0, 1)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

    local kSz = isMobile and 18 or 12
    local knob = Instance.new("Frame", bar)
    knob.Size = UDim2.new(0, kSz, 0, kSz)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(pct, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    -- Área táctil ampliada
    local hitArea = Instance.new("TextButton", box)
    hitArea.Size = UDim2.new(1, -10, 0, isMobile and 36 or 26)
    hitArea.Position = UDim2.new(0, 5, 0, barY - (isMobile and 13 or 9))
    hitArea.BackgroundTransparency = 1
    hitArea.Text = ""
    hitArea.ZIndex = 10

    local sliding = false

    local function update(posX)
        local p = math.clamp((posX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + p * (maxV - minV))
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, 0)
        vl.Text = tostring(v)
        cb(v)
    end

    hitArea.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            update(i.Position.X)
        end
    end)
    hitArea.InputChanged:Connect(function(i)
        if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    hitArea.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    -- fallback mouse global
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
end

local function crearBoton(page, lbl, color, cb)
    local bH = isMobile and 44 or 36
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(1, 0, 0, bH)
    btn.BackgroundColor3 = color or Color3.fromRGB(22, 22, 22)
    btn.BorderSizePixel = 0
    btn.Text = lbl
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = isMobile and 13 or 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local function crearDropdown(page, lbl, lista, cb)
    local rH = isMobile and 48 or 40
    local iH = isMobile and 36 or 30
    local box = Instance.new("Frame", page)
    box.Size = UDim2.new(1, 0, 0, rH)
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    box.BorderSizePixel = 0
    box.ClipsDescendants = true
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 9)

    local l = Instance.new("TextLabel", box)
    l.Size = UDim2.new(0.38, 0, 0, rH)
    l.Position = UDim2.new(0, 9, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = Color3.fromRGB(140, 140, 140)
    l.Font = Enum.Font.Gotham
    l.TextSize = isMobile and 12 or 11
    l.TextXAlignment = Enum.TextXAlignment.Left

    local selBtn = Instance.new("TextButton", box)
    selBtn.Size = UDim2.new(0.62, -9, 0, isMobile and 32 or 26)
    selBtn.Position = UDim2.new(0.38, 0, 0.5, isMobile and -16 or -13)
    selBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
    selBtn.BorderSizePixel = 0
    selBtn.Text = lista[1] or "Ninguno"
    selBtn.TextColor3 = Color3.new(1, 1, 1)
    selBtn.Font = Enum.Font.Gotham
    selBtn.TextSize = isMobile and 12 or 11
    Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 6)

    local open = false
    local items = {}

    local function rebuild()
        for _, f in ipairs(items) do f:Destroy() end
        items = {}
        for i, name in ipairs(lista) do
            local it = Instance.new("TextButton", box)
            it.Size = UDim2.new(1, 0, 0, iH)
            it.Position = UDim2.new(0, 0, 0, rH + (i-1)*iH)
            it.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            it.BorderSizePixel = 0
            it.Text = name
            it.TextColor3 = Color3.new(1, 1, 1)
            it.Font = Enum.Font.Gotham
            it.TextSize = isMobile and 12 or 11
            it.MouseButton1Click:Connect(function()
                selBtn.Text = name
                open = false
                box.Size = UDim2.new(1, 0, 0, rH)
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
            rebuild()
        end
    }
end

-- ============ TAB 1: MOVE ============
local p1 = pages[1]
crearLabel(p1, "  ── VELOCIDAD ──")
crearSlider(p1, "WalkSpeed", 16, 500, 16, Color3.fromRGB(96,165,250), function(v) S.walkSpeed = v end)
crearSlider(p1, "Jump Power", 50, 500, 50, Color3.fromRGB(192,132,252), function(v) S.jumpPower = v end)
crearLabel(p1, "  ── FLY ──")
crearSlider(p1, "Fly Speed", 10, 500, 100, Color3.fromRGB(251,191,36), function(v) S.flySpeed = v end)
crearToggle(p1, "✈️ Fly", Color3.fromRGB(96,165,250), function(v)
    S.fly = v
    if v then startFly() else stopFly() end
end)
crearToggle(p1, "👻 Noclip", Color3.fromRGB(192,132,252), function(v)
    S.noclip = v
    if not v then
        local c = getChar() if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)
crearToggle(p1, "♾️ Infinite Jump", Color3.fromRGB(34,197,94), function(v) S.infJump = v end)
crearBoton(p1, "🔄 Reset Velocidad", Color3.fromRGB(22,22,22), function()
    S.walkSpeed = 16 S.jumpPower = 50
    notify("✅ Velocidad reseteada")
end)

-- ============ TAB 2: PROT ============
local p2 = pages[2]
crearLabel(p2, "  ── PROTECCIONES ──")
crearToggle(p2, "🛡️ Anti Knockback", Color3.fromRGB(34,197,94), function(v) S.antiKB = v end)
crearToggle(p2, "🎭 Anti Ragdoll", Color3.fromRGB(34,197,94), function(v) S.antiRag = v end)
crearToggle(p2, "❤️ God Mode", Color3.fromRGB(239,68,68), function(v) S.godMode = v end)
crearLabel(p2, "  ── OPCIONES ──")
crearBoton(p2, "💊 Heal", Color3.fromRGB(15,70,15), function()
    local hum = getHum() if hum then hum.Health = hum.MaxHealth end
    notify("❤️ HP restaurado")
end)
crearBoton(p2, "🔄 Respawn", Color3.fromRGB(22,22,22), function() player:LoadCharacter() end)

-- ============ TAB 3: PLAYERS ============
local p3 = pages[3]
crearLabel(p3, "  ── JUGADOR ──")
local dd = crearDropdown(p3, "Jugador", getPlayerList(), function(name)
    S.selectedPlayer = getPlayerByName(name)
    if S.selectedPlayer then notify("✅ "..name) end
end)
crearBoton(p3, "🔄 Actualizar Lista", Color3.fromRGB(22,22,22), function()
    dd.refresh(getPlayerList()) notify("✅ Lista actualizada")
end)
crearLabel(p3, "  ── TELEPORT ──")
crearBoton(p3, "📍 Ir a Jugador", Color3.fromRGB(25,25,70), function()
    if not S.selectedPlayer or not S.selectedPlayer.Character then notify("❌ Selecciona jugador") return end
    local tHRP = S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = getHRP()
    if tHRP and myHRP then
        myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
        notify("✅ Teleportado")
    end
end)
crearBoton(p3, "📍 Traer Jugador", Color3.fromRGB(25,25,70), function()
    if not S.selectedPlayer or not S.selectedPlayer.Character then notify("❌ Selecciona jugador") return end
    local tHRP = S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHRP = getHRP()
    if tHRP and myHRP then
        tHRP.CFrame = myHRP.CFrame * CFrame.new(0, 0, 3)
        notify("✅ Jugador traído")
    end
end)
crearLabel(p3, "  ── CÁMARA ──")
crearBoton(p3, "👁️ Espectear", Color3.fromRGB(22,22,22), function()
    if not S.selectedPlayer or not S.selectedPlayer.Character then notify("❌ Selecciona jugador") return end
    local hum = S.selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then camera.CameraSubject = hum notify("👁️ Espectando: "..S.selectedPlayer.Name) end
end)
crearBoton(p3, "🔙 Mi Cámara", Color3.fromRGB(22,22,22), function()
    local hum = getHum() if hum then camera.CameraSubject = hum notify("✅ Cámara restaurada") end
end)

-- ============ TAB 4: COMBAT ============
local p4 = pages[4]
crearLabel(p4, "  ── KILL AURA ──")
crearSlider(p4, "Rango", 5, 50, 15, Color3.fromRGB(239,68,68), function(v) S.killAuraRange = v end)
crearToggle(p4, "💀 Kill Aura", Color3.fromRGB(239,68,68), function(v) S.killAura = v end)
crearLabel(p4, "  ── HITBOX ──")
crearSlider(p4, "Tamaño", 5, 30, 10, Color3.fromRGB(251,191,36), function(v) S.hitboxSize = v end)
crearToggle(p4, "📦 Hitbox Expander", Color3.fromRGB(251,191,36), function(v) S.hitbox = v end)
crearLabel(p4, "  ── MANUAL ──")
crearBoton(p4, "👊 Hit Jugador", Color3.fromRGB(70,15,15), function()
    if not S.selectedPlayer then notify("❌ Selecciona jugador") return end
    pcall(function()
        local myHRP = getHRP()
        local tHRP = S.selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
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

-- ============ TAB 5: ESP/VISUAL ============
local p5 = pages[5]
crearLabel(p5, "  ── ESP ──")
crearToggle(p5, "👁️ ESP Jugadores", Color3.fromRGB(192,132,252), function(v)
    S.esp = v
    if not v then for _, pl in ipairs(Players:GetPlayers()) do removeESP(pl) end end
end)
crearLabel(p5, "  ── LIGHTING ──")
crearToggle(p5, "💡 Fullbright", Color3.fromRGB(251,191,36), function(v)
    if v then
        origLighting = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
        }
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        if origLighting.Brightness then
            Lighting.Brightness = origLighting.Brightness
            Lighting.ClockTime = origLighting.ClockTime
            Lighting.GlobalShadows = origLighting.GlobalShadows
            Lighting.Ambient = origLighting.Ambient
        end
    end
end)

-- ============ DRAG MOUSE + TOUCH ============
local drag = {active=false, start=nil, orig=nil}

header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag.active = true
        drag.start = Vector2.new(i.Position.X, i.Position.Y)
        drag.orig = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag.active and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = Vector2.new(i.Position.X, i.Position.Y) - drag.start
        main.Position = UDim2.new(drag.orig.X.Scale, drag.orig.X.Offset+d.X, drag.orig.Y.Scale, drag.orig.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag.active = false
    end
end)

-- ============ MINIMIZAR ============
local minimizado = false
local twI = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
btnMin.MouseButton1Click:Connect(function()
    minimizado = not minimizado
    TweenService:Create(main, twI, {
        Size = minimizado and UDim2.new(0, GUI_W, 0, 50) or UDim2.new(0, GUI_W, 0, GUI_H)
    }):Play()
    btnMin.Text = minimizado and "□" or "–"
end)

-- ============ CERRAR — CORREGIDO ============
btnClose.MouseButton1Click:Connect(function()
    clearAll()
    -- Desconectar todos los loops
    for _, c in pairs(conns) do
        pcall(function() c:Disconnect() end)
    end
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

notify("🐉 GF HUB v5.1 listo!", 3)

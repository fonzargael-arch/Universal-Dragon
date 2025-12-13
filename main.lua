--[[
    🐉 DRAGON RED ADMIN PANEL v5
    - Tecla para abrir/cerrar: RightShift
    - Botón X minimiza (no lo mata)
    - Visual mejorado, secciones separadas
    - Más checks para evitar errores en juegos distintos
    - Mantiene: Fly, Noclip, Infinite Jump, God, Aura Kill, ESP
]]

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local function getHumanoid()
    char = player.Character or player.CharacterAdded:Wait()
    local h = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return h, root
end

local hum, root = getHumanoid()

player.CharacterAdded:Connect(function(c)
    char = c
    hum, root = getHumanoid()
end)

-- Estados
local states = {
    Fly = false,
    Noclip = false,
    InfJump = false,
    God = false,
    AuraKill = false,
    ESP = false
}

-- Variables
local flySpeed = 60
local flyBoost = 0
local walkSpeed = 16
local auraRange = 12

local bv, bg
local espFolder = Instance.new("Folder")
espFolder.Name = "DragonRedESP"
espFolder.Parent = workspace

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "DragonRedGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 540)
frame.Position = UDim2.new(0.05,0,0.5,-270)
frame.BackgroundColor3 = Color3.fromRGB(8,8,8)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(200,0,0)
stroke.Thickness = 2

TweenService:Create(
    stroke,
    TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Color = Color3.fromRGB(255,60,60) }
):Play()

frame.Position = UDim2.new(-0.4,0,0.5,-270)
frame:TweenPosition(UDim2.new(0.05,0,0.5,-270),"Out","Back",0.7,true)

-- Barra superior
local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1,0,0,40)
topBar.BackgroundColor3 = Color3.fromRGB(15,15,15)
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1,-80,1,0)
title.Position = UDim2.new(0,15,0,0)
title.BackgroundTransparency = 1
title.Text = "DRAGON RED v5"
title.TextColor3 = Color3.fromRGB(220,30,30)
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = Instance.new("TextLabel", topBar)
subtitle.Size = UDim2.new(1,-80,1,0)
subtitle.Position = UDim2.new(0,15,0,18)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Aggressive Admin Panel"
subtitle.TextColor3 = Color3.fromRGB(150,150,150)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local close = Instance.new("TextButton", topBar)
close.Size = UDim2.new(0,30,0,30)
close.Position = UDim2.new(1,-35,0.5,-15)
close.Text = "—"
close.BackgroundTransparency = 1
close.TextColor3 = Color3.fromRGB(200,0,0)
close.TextSize = 22
close.Font = Enum.Font.GothamBold

-- Minimiza pero no destruye
close.MouseButton1Click:Connect(function()
    frame.Visible = false
end)

-- Arrastrar ventana
do
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Tecla para mostrar/ocultar GUI (RightShift)
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        frame.Visible = not frame.Visible
    end
end)

-- Contenedor principal
local main = Instance.new("Frame", frame)
main.Size = UDim2.new(1,-20,1,-60)
main.Position = UDim2.new(0,10,0,50)
main.BackgroundTransparency = 1

-- Subtítulos secciones
local movementLabel = Instance.new("TextLabel", main)
movementLabel.Size = UDim2.new(1,0,0,18)
movementLabel.Position = UDim2.new(0,0,0,0)
movementLabel.BackgroundTransparency = 1
movementLabel.Text = "MOVEMENT"
movementLabel.Font = Enum.Font.GothamBold
movementLabel.TextColor3 = Color3.fromRGB(200,0,0)
movementLabel.TextSize = 14
movementLabel.TextXAlignment = Enum.TextXAlignment.Left

local combatLabel = Instance.new("TextLabel", main)
combatLabel.Size = UDim2.new(1,0,0,18)
combatLabel.Position = UDim2.new(0,0,0,150)
combatLabel.BackgroundTransparency = 1
combatLabel.Text = "COMBAT"
combatLabel.Font = Enum.Font.GothamBold
combatLabel.TextColor3 = Color3.fromRGB(200,0,0)
combatLabel.TextSize = 14
combatLabel.TextXAlignment = Enum.TextXAlignment.Left

local visualLabel = Instance.new("TextLabel", main)
visualLabel.Size = UDim2.new(1,0,0,18)
visualLabel.Position = UDim2.new(0,0,0,280)
visualLabel.BackgroundTransparency = 1
visualLabel.Text = "VISUAL"
visualLabel.Font = Enum.Font.GothamBold
visualLabel.TextColor3 = Color3.fromRGB(200,0,0)
visualLabel.TextSize = 14
visualLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Helpers GUI
local function toggleButton(parent, text, y)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.9,0,0,32)
    btn.Position = UDim2.new(0.05,0,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = text .. ": OFF"
    btn.AutoButtonColor = false

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,7)
    local bstroke = Instance.new("UIStroke", btn)
    bstroke.Color = Color3.fromRGB(180,0,0)
    bstroke.Thickness = 1

    return btn
end

local function slider(parent, text, y, min, max, default, callback)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(0.9,0,0,16)
    lbl.Position = UDim2.new(0.05,0,0,y)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local bar = Instance.new("Frame", parent)
    bar.Size = UDim2.new(0.9,0,0,7)
    bar.Position = UDim2.new(0.05,0,0,y+18)
    bar.BackgroundColor3 = Color3.fromRGB(30,30,30)
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(200,0,0)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local dragging = false

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local p = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(p,0,1,0)
            local val = math.floor(min + (max-min)*p)
            callback(val)
        end
    end)
end

-- Botones movimientos
local flyBtn = toggleButton(main, "Fly", 25)
local noclipBtn = toggleButton(main, "Noclip", 65)
local jumpBtn = toggleButton(main, "Infinite Jump", 105)
local godBtn = toggleButton(main, "God Mode", 145)

-- Botones combate
local auraBtn = toggleButton(main, "Aura Kill", 175)
slider(main, "Walk Speed", 215, 10, 100, 16, function(v)
    walkSpeed = v
    if hum then
        hum.WalkSpeed = v
    end
end)

slider(main, "Fly Speed", 245, 20, 200, 60, function(v)
    flySpeed = v
end)

slider(main, "Aura Range", 275, 5, 50, 12, function(v)
    auraRange = v
end)

-- Botones visual
local espBtn = toggleButton(main, "ESP", 305)

-- FUNCIONES

local function setButtonState(btn, name, on)
    states[name] = on
    btn.Text = name .. ": " .. (on and "ON" or "OFF")
    btn.BackgroundColor3 = on and Color3.fromRGB(40,0,0) or Color3.fromRGB(20,20,20)
end

-- Fly
local function toggleFly()
    local newState = not states.Fly
    setButtonState(flyBtn, "Fly", newState)

    hum, root = getHumanoid()
    if not hum or not root then return end

    if newState then
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e6,1e6,1e6)
        bv.Velocity = Vector3.new()
        bv.Parent = root

        bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1e6,1e6,1e6)
        bg.CFrame = workspace.CurrentCamera.CFrame
        bg.Parent = root
    else
        flyBoost = 0
        if bv then bv:Destroy() bv = nil end
        if bg then bg:Destroy() bg = nil end
    end
end

flyBtn.MouseButton1Click:Connect(toggleFly)

RunService.RenderStepped:Connect(function()
    if states.Fly then
        hum, root = getHumanoid()
        if hum and root and bv and bg then
            local cam = workspace.CurrentCamera
            flyBoost = math.clamp(flyBoost + 2, 0, flySpeed)
            bv.Velocity = cam.CFrame.LookVector * flyBoost
            bg.CFrame = cam.CFrame
            hum.PlatformStand = true
        end
    else
        flyBoost = 0
        if hum then hum.PlatformStand = false end
    end
end)

-- Noclip
noclipBtn.MouseButton1Click:Connect(function()
    setButtonState(noclipBtn, "Noclip", not states.Noclip)
end)

RunService.Stepped:Connect(function()
    if states.Noclip then
        hum, root = getHumanoid()
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end
    end
end)

-- Infinite Jump
jumpBtn.MouseButton1Click:Connect(function()
    setButtonState(jumpBtn, "Infinite Jump", not states.InfJump)
end)

UIS.JumpRequest:Connect(function()
    if states.InfJump then
        hum, root = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- God Mode
godBtn.MouseButton1Click:Connect(function()
    hum, root = getHumanoid()
    local newState = not states.God
    setButtonState(godBtn, "God Mode", newState)

    if hum then
        if newState then
            hum.MaxHealth = math.huge
            hum.Health = hum.MaxHealth
        else
            hum.MaxHealth = 100
        end
    end
end)

-- Aura Kill
auraBtn.MouseButton1Click:Connect(function()
    setButtonState(auraBtn, "Aura Kill", not states.AuraKill)
end)

RunService.Heartbeat:Connect(function()
    if not states.AuraKill then return end

    hum, root = getHumanoid()
    if not root then return end

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local h = plr.Character:FindFirstChildOfClass("Humanoid")

            if hrp and h and h.Health > 0 then
                if (hrp.Position - root.Position).Magnitude <= auraRange then
                    h.Health = 0
                end
            end
        end
    end
end)

-- ESP
local function clearESP()
    espFolder:ClearAllChildren()
end

local function createESP(plr)
    if not plr.Character then return end
    local head = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.Size = UDim2.new(0,100,0,40)
    bb.AlwaysOnTop = true
    bb.Parent = espFolder

    local tl = Instance.new("TextLabel", bb)
    tl.Size = UDim2.new(1,0,1,0)
    tl.BackgroundTransparency = 1
    tl.Text = plr.Name
    tl.TextColor3 = Color3.fromRGB(255,0,0)
    tl.TextStrokeTransparency = 0
    tl.Font = Enum.Font.GothamBold
    tl.TextScaled = true
end

espBtn.MouseButton1Click:Connect(function()
    local newState = not states.ESP
    setButtonState(espBtn, "ESP", newState)

    clearESP()
    if newState then
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                createESP(plr)
            end
        end

        Players.PlayerAdded:Connect(function(plr)
            if states.ESP and plr ~= player then
                plr.CharacterAdded:Connect(function()
                    task.wait(1)
                    if states.ESP then
                        createESP(plr)
                    end
                end)
            end
        end)
    end
end)

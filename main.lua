--[[
    🐉 DRAGON RED ADMIN PANEL v4 (Aggressive Edition)
    - Sliders sin spam
    - Fly agresivo con aceleración
    - Aura Kill optimizado
    - ESP sin lag
    - Código modular y limpio
]]

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

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
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "DragonRedESP"

-- GUI
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "DragonRedGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 520)
frame.Position = UDim2.new(0.05,0,0.5,-260)
frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(200,0,0)
stroke.Thickness = 2

TweenService:Create(
    stroke,
    TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    { Color = Color3.fromRGB(255,60,60) }
):Play()

frame.Position = UDim2.new(-0.4,0,0.5,-260)
frame:TweenPosition(UDim2.new(0.05,0,0.5,-260),"Out","Back",0.7,true)

-- Título
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-40,0,40)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "DRAGON RED v4"
title.TextColor3 = Color3.fromRGB(220,0,0)
title.Font = Enum.Font.GothamBlack
title.TextSize = 24

-- Botón cerrar
local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0,30,0,30)
close.Position = UDim2.new(1,-35,0,5)
close.Text = "✖"
close.BackgroundTransparency = 1
close.TextColor3 = Color3.fromRGB(200,0,0)
close.TextSize = 20
close.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Helpers GUI
local function toggleButton(text, y)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.9,0,0,36)
    btn.Position = UDim2.new(0.05,0,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 15
    btn.Text = text .. ": OFF"

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(180,0,0)

    return btn
end

local function slider(text, y, min, max, default, callback)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.9,0,0,20)
    lbl.Position = UDim2.new(0.05,0,0,y)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.TextSize = 14

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0.9,0,0,8)
    bar.Position = UDim2.new(0.05,0,0,y+22)
    bar.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(200,0,0)
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

-- Botones
local flyBtn = toggleButton("Fly", 50)
local noclipBtn = toggleButton("Noclip", 95)
local jumpBtn = toggleButton("Infinite Jump", 140)
local godBtn = toggleButton("God Mode", 185)
local auraBtn = toggleButton("Aura Kill", 230)
local espBtn = toggleButton("ESP", 275)

slider("Speed", 325, 10, 100, 16, function(v)
    walkSpeed = v
    hum.WalkSpeed = v
end)

slider("Fly Speed", 380, 20, 200, 60, function(v)
    flySpeed = v
end)

slider("Aura Range", 435, 5, 40, 12, function(v)
    auraRange = v
end)

-- Funciones
local function toggleFly()
    states.Fly = not states.Fly
    flyBtn.Text = "Fly: " .. (states.Fly and "ON" or "OFF")

    if states.Fly then
        bv = Instance.new("BodyVelocity", root)
        bv.MaxForce = Vector3.new(1e6,1e6,1e6)

        bg = Instance.new("BodyGyro", root)
        bg.MaxTorque = Vector3.new(1e6,1e6,1e6)
    else
        if bv then bv:Destroy() bv = nil end
        if bg then bg:Destroy() bg = nil end
    end
end

flyBtn.MouseButton1Click:Connect(toggleFly)

-- Fly agresivo con aceleración
RunService.RenderStepped:Connect(function()
    if states.Fly and bv then
        local cam = workspace.CurrentCamera
        flyBoost = math.clamp(flyBoost + 2, 0, flySpeed)
        bv.Velocity = cam.CFrame.LookVector * flyBoost
        bg.CFrame = cam.CFrame
    else
        flyBoost = 0
    end
end)

noclipBtn.MouseButton1Click:Connect(function()
    states.Noclip = not states.Noclip
    noclipBtn.Text = "Noclip: " .. (states.Noclip and "ON" or "OFF")
end)

RunService.Stepped:Connect(function()
    if states.Noclip then
        for _,p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

jumpBtn.MouseButton1Click:Connect(function()
    states.InfJump = not states.InfJump
    jumpBtn.Text = "Infinite Jump: " .. (states.InfJump and "ON" or "OFF")
end)

UIS.JumpRequest:Connect(function()
    if states.InfJump then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

godBtn.MouseButton1Click:Connect(function()
    states.God = not states.God
    godBtn.Text = "God Mode: " .. (states.God and "ON" or "OFF")

    if states.God then
        hum.MaxHealth = math.huge
        hum.Health = hum.MaxHealth
    else
        hum.MaxHealth = 100
    end
end)

-- Aura Kill agresivo
RunService.Heartbeat:Connect(function()
    if not states.AuraKill then return end

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local h = plr.Character:FindFirstChild("Humanoid")

            if hrp and h then
                if (hrp.Position - root.Position).Magnitude <= auraRange then
                    h.Health = 0
                end
            end
        end
    end
end)

auraBtn.MouseButton1Click:Connect(function()
    states.AuraKill = not states.AuraKill
    auraBtn.Text = "Aura Kill: " .. (states.AuraKill and "ON" or "OFF")
end)

-- ESP
local function clearESP()
    espFolder:ClearAllChildren()
end

local function createESP(plr)
    if not plr.Character or not plr.Character:FindFirstChild("Head") then return end

    local bb = Instance.new("BillboardGui", espFolder)
    bb.Adornee = plr.Character.Head
    bb.Size = UDim2.new(0,100,0,40)
    bb.AlwaysOnTop = true

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
    states.ESP = not states.ESP
    espBtn.Text = "ESP: " .. (states.ESP and "ON" or "OFF")

    clearESP()

    if states.ESP then
        for _,plr in pairs(Players:GetPlayers()) do
            if plr ~= player then createESP(plr) end
        end
    end
end)


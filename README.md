--[[
 🐉 DRAGON RED ADMIN PANEL v2 🐉
 Negro | Bordes rojos animados
 Toggle ON/OFF, cerrar con ❌, Fly controlado, Speed editable
 Incluye: Fly, Noclip, Infinite Jump, Speed, God, TP, Kill All
]]

-- Loadstring inicio (EJEMPLO con link GitHub - NO FUNCIONA)
pcall(function()
    loadstring(game:HttpGet(
        "https://github.com/fonzargael-arch/Universal-Dragon/blob/fc5fee5f36b4900a0563fe60341949d8555e5e10/README.md"
    ))()
end)

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
    God = false
}

local flySpeed = 60
local walkSpeed = 16
local bv, bg

-- GUI
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "DragonRedGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 420)
frame.Position = UDim2.new(0.05,0,0.5,-210)
frame.BackgroundColor3 = Color3.fromRGB(0,0,0)

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(200,0,0)
stroke.Thickness = 2

-- Animación stroke
TweenService:Create(stroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Color = Color3.fromRGB(255,60,60)
}):Play()

-- Entrada animada
frame.Position = UDim2.new(-0.4,0,0.5,-210)
frame:TweenPosition(UDim2.new(0.05,0,0.5,-210),"Out","Back",0.7,true)

-- Título
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-40,0,40)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "DRAGON RED"
title.TextColor3 = Color3.fromRGB(220,0,0)
title.Font = Enum.Font.GothamBlack
title.TextSize = 24

-- Cerrar
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

-- Función toggle
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
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(180,0,0)

    return btn
end

-- Slider
local function slider(text, y, min, max, default, callback)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.9,0,0,20)
    lbl.Position = UDim2.new(0.05,0,0,y)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. default
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
            local p = math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            fill.Size = UDim2.new(p,0,1,0)
            local val = math.floor(min + (max-min)*p)
            lbl.Text = text .. ": " .. val
            callback(val)
        end
    end)
end

-- BOTONES
local flyBtn = toggleButton("Fly", 50)
local noclipBtn = toggleButton("Noclip", 95)
local jumpBtn = toggleButton("Infinite Jump", 140)
local godBtn = toggleButton("God Mode", 185)

-- Sliders
slider("Speed", 235, 10, 100, 16, function(v)
    walkSpeed = v
    hum.WalkSpeed = v
end)

slider("Fly Speed", 290, 20, 150, 60, function(v)
    flySpeed = v
end)

-- Funciones
flyBtn.MouseButton1Click:Connect(function()
    states.Fly = not states.Fly
    flyBtn.Text = "Fly: " .. (states.Fly and "ON" or "OFF")

    if states.Fly then
        bv = Instance.new("BodyVelocity", root)
        bv.MaxForce = Vector3.new(1e5,1e5,1e5)
        bg = Instance.new("BodyGyro", root)
        bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    else
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
end)

RunService.RenderStepped:Connect(function()
    if states.Fly and bv then
        local cam = workspace.CurrentCamera
        bv.Velocity = cam.CFrame.LookVector * flySpeed
        bg.CFrame = cam.CFrame
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
    if states.God then hum.MaxHealth = math.huge hum.Health = hum.MaxHealth else hum.MaxHealth = 100 end
end)


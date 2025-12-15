local dragging = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            local value = math.floor(min + (max - min) * percent)
            valueLabel.Text = tostring(value)
            if callback then callback(value) end
        end
    end)
end

--// ═════════════════════════════════════════════
--// MOVEMENT TAB
--// ═════════════════════════════════════════════
local movePage = tabs["Movement"].page

createSection(movePage, "⚡ Movement Controls")

createToggle(movePage, "Fly Mode", function(enabled)
    states.Fly = enabled
    hum, root = getHumanoid()
    if not hum or not root then return end
    
    if enabled then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "DragonFly"
        bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bv.Velocity = Vector3.new()
        bv.Parent = root
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "DragonGyro"
        bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        bg.P = 9e4
        bg.CFrame = camera.CFrame
        bg.Parent = root
        
        hum.PlatformStand = true
        notify("Fly", "Activado - WASD + Space/Ctrl", 2)
    else
        if root:FindFirstChild("DragonFly") then root.DragonFly:Destroy() end
        if root:FindFirstChild("DragonGyro") then root.DragonGyro:Destroy() end
        if hum then hum.PlatformStand = false end
        notify("Fly", "Desactivado", 2)
    end
end)

createToggle(movePage, "Noclip", function(enabled)
    states.Noclip = enabled
    notify("Noclip", enabled and "Activado" or "Desactivado", 2)
end)

createToggle(movePage, "Infinite Jump", function(enabled)
    states.InfJump = enabled
    notify("Infinite Jump", enabled and "Activado" or "Desactivado", 2)
end)

createSection(movePage, "⚙️ Speed Settings")

createSlider(movePage, "Walk Speed", 16, 150, 16, function(value)
    config.walkSpeed = value
    if states.WalkSpeed then
        hum, root = getHumanoid()
        if hum then hum.WalkSpeed = value end
    end
end)

createToggle(movePage, "Enable Custom Walk Speed", function(enabled)
    states.WalkSpeed = enabled
    hum, root = getHumanoid()
    if hum then
        if enabled then
            hum.WalkSpeed = config.walkSpeed
        else
            hum.WalkSpeed = 16
        end
    end
    notify("Walk Speed", enabled and ("Activado: " .. config.walkSpeed) or "Desactivado", 2)
end)

createSlider(movePage, "Jump Power", 50, 200, 50, function(value)
    config.jumpPower = value
    if states.JumpPower then
        hum, root = getHumanoid()
        if hum then hum.JumpPower = value end
    end
end)

createToggle(movePage, "Enable Custom Jump Power", function(enabled)
    states.JumpPower = enabled
    hum, root = getHumanoid()
    if hum then
        if enabled then
            hum.JumpPower = config.jumpPower
        else
            hum.JumpPower = 50
        end
    end
    notify("Jump Power", enabled and ("Activado: " .. config.jumpPower) or "Desactivado", 2)
end)

createSlider(movePage, "Fly Speed", 20, 250, 80, function(value)
    config.flySpeed = value
end)

-- Fly logic
local flyVel = Vector3.new()
RunService.RenderStepped:Connect(function()
    if states.Fly then
        hum, root = getHumanoid()
        if not root then return end
        
        local bv = root:FindFirstChild("DragonFly")
        local bg = root:FindFirstChild("DragonGyro")
        if not bv or not bg then return end
        
        local dir = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        
        if dir.Magnitude > 0 then
            dir = dir.Unit * config.flySpeed
        end
        
        flyVel = flyVel:Lerp(dir, 0.2)
        bv.Velocity = flyVel
        bg.CFrame = camera.CFrame
    end
end)

-- Noclip logic
RunService.Stepped:Connect(function()
    if states.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if states.InfJump then
        hum, root = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

--// ═════════════════════════════════════════════
--// PLAYERS TAB
--// ═════════════════════════════════════════════
local playersPage = tabs["Players"].page

createSection(playersPage, "👥 Player List")

local playerListContainer = Instance.new("Frame", playersPage)
playerListContainer.Size = UDim2.new(1, 0, 0, 280)
playerListContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
playerListContainer.BorderSizePixel = 0
playerListContainer.ZIndex = 999999

Instance.new("UICorner", playerListContainer).CornerRadius = UDim.new(0, 8)
local playerListStroke = Instance.new("UIStroke", playerListContainer)
playerListStroke.Color = Color3.fromRGB(200, 0, 0)
playerListStroke.Thickness = 1

local playerScroll = Instance.new("ScrollingFrame", playerListContainer)
playerScroll.Size = UDim2.new(1, -8, 1, -8)
playerScroll.Position = UDim2.new(0, 4, 0, 4)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 5
playerScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerScroll.ZIndex = 999999

local playerLayout = Instance.new("UIListLayout", playerScroll)
playerLayout.Padding = UDim.new(0, 4)

local function createPlayerButton(plr)
    local btn = Instance.new("TextButton", playerScroll)
    btn.Size = UDim2.new(1, -8, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 999999
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(200, 0, 0)
    btnStroke.Thickness = 1
    
    local nameLabel = Instance.new("TextLabel", btn)
    nameLabel.Size = UDim2.new(1, -45, 0, 18)
    nameLabel.Position = UDim2.new(0, 8, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.Code
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 999999
    
    local distLabel = Instance.new("TextLabel", btn)
    distLabel.Size = UDim2.new(1, -45, 0, 14)
    distLabel.Position = UDim2.new(0, 8, 0, 22)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "Distance: ---"
    distLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    distLabel.Font = Enum.Font.Code
    distLabel.TextSize = 10
    distLabel.TextXAlignment = Enum.TextXAlignment.Left
    distLabel.ZIndex = 999999
    
    local selectBtn = Instance.new("TextButton", btn)
    selectBtn.Size = UDim2.new(0, 32, 0, 28)
    selectBtn.Position = UDim2.new(1, -36, 0.5, -14)
    selectBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    selectBtn.Text = "→"
    selectBtn.TextSize = 16
    selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectBtn.Font = Enum.Font.Code
    selectBtn.ZIndex = 999999
    
    Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 5)
    
    selectBtn.MouseButton1Click:Connect(function()
        selectedPlayer = plr
        notify("Player Selected", plr.Name, 2)
        
        for _, child in ipairs(playerScroll:GetChildren()) do
            if child:IsA("TextButton") then
                local sel = child:FindFirstChild("TextButton")
                if sel then
                    sel.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                end
            end
        end
        selectBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    end)
    
    task.spawn(function()
        while btn.Parent do
            task.wait(0.5)
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                hum, root = getHumanoid()
                if root then
                    local dist = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    distLabel.Text = string.format("Distance: %.0f", dist)
                end
            else
                distLabel.Text = "Distance: ---"
            end
        end
    end)
end

local function updatePlayerList()
    for _, child in ipairs(playerScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    if not playerScroll:FindFirstChildOfClass("UIListLayout") then
        playerLayout = Instance.new("UIListLayout", playerScroll)
        playerLayout.Padding = UDim.new(0, 4)
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            createPlayerButton(plr)
        end
    end
end

-- Cargar lista inicial SIN notificación
updatePlayerList()

createSection(playersPage, "🎯 Player Actions")

createButton(playersPage, "🔄 Refresh Player List", function()
    updatePlayerList()
    notify("Player List", (#Players:GetPlayers() - 1) .. " jugadores", 2)
end)

createButton(playersPage, "📍 Teleport to Selected", function()
    if selectedPlayer and selectedPlayer.Character then
        hum, root = getHumanoid()
        local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 3, 3)
            notify("Teleported", "To " .. selectedPlayer.Name, 2)
        else
            notify("Error", "No se pudo teleportar", 2)
        end
    else
        notify("Error", "No player selected", 2)
    end
end)

createButton(playersPage, "👁️ View Selected Player", function()
    if selectedPlayer and selectedPlayer.Character then
        local targetHum = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        if targetHum then
            camera.CameraSubject = targetHum
            notify("Viewing", selectedPlayer.Name, 2)
        else
            notify("Error", "No se pudo ver", 2)
        end
    else
        notify("Error", "No player selected", 2)
    end
end)

createButton(playersPage, "↩️ Reset Camera", function()
    hum, root = getHumanoid()
    if hum then
        camera.CameraSubject = hum
        notify("Camera", "Reset to self", 2)
    end
end)

--// ═════════════════════════════════════════════
--// VISUAL TAB (ESP MEJORADO - PERSISTENTE)
--// ═════════════════════════════════════════════
local visualPage = tabs["Visual"].page

createSection(visualPage, "👁️ Visual Features")

-- Función para crear ESP de un jugador
local function createESPForPlayer(plr)
    if plr == player then return end
    
    -- Eliminar ESP anterior si existe
    local oldESP = espFolder:FindFirstChild("DragonESP_" .. plr.Name)
    if oldESP then oldESP:Destroy() end
    
    -- Esperar a que tenga personaje
    if not plr.Character then
        plr.CharacterAdded:Wait()
    end
    
    local function setupESP()
        if not states.ESP then return end
        
        local head = plr.Character:FindFirstChild("Head")
        if not head then return end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DragonESP_" .. plr.Name
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.Parent = espFolder
        
        local nameLabel = Instance.new("TextLabel", billboard)
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.Name
        nameLabel.TextColor3 = config.espColor
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Enum.Font.Code
        nameLabel.TextScaled = true
        
        local distLabel = Instance.new("TextLabel", billboard)
        distLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "---"
        distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        distLabel.TextStrokeTransparency = 0
        distLabel.Font = Enum.Font.Code
        distLabel.TextScaled = true
        
        task.spawn(function()
            while billboard.Parent and plr.Character and states.ESP do
                task.wait(0.3)
                hum, root = getHumanoid()
                local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                if root and targetRoot then
                    local dist = (targetRoot.Position - root.Position).Magnitude
                    distLabel.Text = string.format("%.0f studs", dist)
                end
            end
        end)
    end
    
    setupESP()
    
    -- Reconectar ESP cuando el jugador respawnee
    plr.CharacterAdded:Connect(function()
        if states.ESP then
            task.wait(0.5)
            setupESP()
        end
    end)
end

createToggle(visualPage, "ESP (Name Tags)", function(enabled)
    states.ESP = enabled
    
    if enabled then
        -- Crear ESP para todos los jugadores actuales
        for _, plr in ipairs(Players:GetPlayers()) do
            createESPForPlayer(plr)
        end
        
        -- Crear ESP para jugadores que entren
        Players.PlayerAdded:Connect(function(plr)
            if states.ESP then
                plr.CharacterAdded:Connect(function()
                    task.wait(0.5)
                    createESPForPlayer(plr)
                end)
            end
        end)
        
        notify("ESP", "Activado - Persistente", 2)
    else
        espFolder:ClearAllChildren()
        notify("ESP", "Desactivado", 2)
    end
end)

createToggle(visualPage, "Fullbright", function(enabled)
    states.Fullbright = enabled
    
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        notify("Fullbright", "Activado", 2)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
        notify("Fullbright", "Desactivado", 2)
    end
end)

createSection(visualPage, "🎨 ESP Color")

local colorButtons = {
    {name = "Red", color = Color3.fromRGB(255, 0, 0)},
    {name = "Green", color = Color3.fromRGB(0, 255, 0)},
    {name = "Blue", color = Color3.fromRGB(0, 150, 255)},
    {name = "Yellow", color = Color3.fromRGB(255, 255, 0)},
    {name = "Purple", color = Color3.fromRGB(200, 0, 255)},
    {name = "Cyan", color = Color3.fromRGB(0, 255, 255)}
}

local colorContainer = Instance.new("Frame", visualPage)
colorContainer.Size = UDim2.new(1, 0, 0, 85)
colorContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
colorContainer.BorderSizePixel = 0
colorContainer.ZIndex = 999999

Instance.new("UICorner", colorContainer).CornerRadius = UDim.new(0, 8)
local colorStroke = Instance.new("UIStroke", colorContainer)
colorStroke.Color = Color3.fromRGB(200, 0, 0)
colorStroke.Thickness = 1

local colorGrid = Instance.new("UIGridLayout", colorContainer)
colorGrid.CellSize = UDim2.new(0.3, 0, 0, 30)
colorGrid.CellPadding = UDim2.new(0.05, 0, 0, 8)

local colorPadding = Instance.new("UIPadding", colorContainer)
colorPadding.PaddingLeft = UDim.new(0.05, 0)
colorPadding.PaddingTop = UDim.new(0, 8)

for _, colorData in ipairs(colorButtons) do
    local btn = Instance.new("TextButton", colorContainer)
    btn.BackgroundColor3 = colorData.color
    btn.Text = colorData.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.ZIndex = 999999
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Thickness = 0
    
    btn.MouseButton1Click:Connect(function()
        config.espColor = colorData.color
        
        for _, billboard in ipairs(espFolder:GetChildren()) do
            if billboard:IsA("BillboardGui") then
                local nameLabel = billboard:FindFirstChildOfClass("TextLabel")
                if nameLabel then
                    nameLabel.TextColor3 = colorData.color
                end
            end
        end
        
        notify("ESP Color", colorData.name, 2)
        
        for _, otherBtn in ipairs(colorContainer:GetChildren()) do
            if otherBtn:IsA("TextButton") then
                local stroke = otherBtn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Thickness = 0 end
            end
        end
        btnStroke.Thickness = 3
    end)
end

--// ═════════════════════════════════════════════
--// MISC TAB (MEJORADO)
--// ═════════════════════════════════════════════
local miscPage = tabs["Misc"].page

createSection(miscPage, "🛠️ Misc Features")

createToggle(miscPage, "Click TP (Hold Ctrl)", function(enabled)
    states.ClickTP = enabled
    notify("Click TP", enabled and "Ctrl + Click para TP" or "Desactivado", 2)
end)

createSection(miscPage, "📍 Position Tools")

createButton(miscPage, "💾 Save Position", function()
    hum, root = getHumanoid()
    if root then
        savedPosition = root.CFrame
        notify("Position", "Guardada", 2)
    end
end)

createButton(miscPage, "📍 Load Position", function()
    hum, root = getHumanoid()
    if root and savedPosition then
        root.CFrame = savedPosition
        notify("Position", "Cargada", 2)
    else
        notify("Error", "No hay posición guardada", 2)
    end
end)

createButton(miscPage, "🔄 Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, player)
end)

createButton(miscPage, "💀 Respawn Character", function()
    if char then
        char:BreakJoints()
        notify("Respawn", "Reapareciendo...", 2)
    end
end)

createSection(miscPage, "⚔️ Combat Actions")

createToggle(miscPage, "Hitbox Expander", function(enabled)
    states.HitboxExpander = enabled
    if not enabled then
        for playerName, originalSize in pairs(originalSizes) do
            pcall(function()
                local plr = Players:FindFirstChild(playerName)
                if plr and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = originalSize
                        hrp.Transparency = 1
                    end
                end
            end)
        end
        originalSizes = {}
    end
    notify("Hitbox Expander", enabled and "Activado" or "Desactivado", 2)
end)

createSlider(miscPage, "Hitbox Size", 5, 50, 20, function(value)
    config.hitboxSize = value
end)

createToggle(miscPage, "Spinbot (Anti-Hit)", function(enabled)
    states.Spinbot = enabled
    notify("Spinbot", enabled and "Activado" or "Desactivado", 2)
end)

createButton(miscPage, "🔥 Kill All Players", function()
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            pcall(function()
                local enemyHum = plr.Character:FindFirstChildOfClass("Humanoid")
                if enemyHum then
                    enemyHum.Health = 0
                    count = count + 1
                end
            end)
        end
    end
    notify("Kill All", count .. " jugadores eliminados", 2)
end)

createButton(miscPage, "⚡ Kill Selected Player", function()
    if selectedPlayer and selectedPlayer.Character then
        pcall(function()
            local enemyHum = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
            if enemyHum then
                enemyHum.Health = 0
                notify("Kill", selectedPlayer.Name .. " eliminado", 2)
            else
                notify("Error", "No tiene Humanoid", 2)
            end
        end)
    else
        notify("Error", "No player selected", 2)
    end
end)

-- Click TP
mouse.Button1Down:Connect(function()
    if states.ClickTP and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        hum, root = getHumanoid()
        if root and mouse.Target then
            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)

-- Hitbox Expander (optimizado)
task.spawn(function()
    while true do
        task.wait(2)
        if states.HitboxExpander then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    pcall(function()
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            if not originalSizes[plr.Name] then
                                originalSizes[plr.Name] = hrp.Size
                            end
                            hrp.Size = Vector3.new(config.hitboxSize, config.hitboxSize, config.hitboxSize)
                            hrp.Transparency = 0.5
                            hrp.CanCollide = false
                            hrp.Massless = true
                        end
                    end)
                end
            end
        end
    end
end)

-- Spinbot
local spinSpeed = 0
RunService.RenderStepped:Connect(function()
    if states.Spinbot then
        hum, root = getHumanoid()
        if root then
            spinSpeed = spinSpeed + 20
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
        end
    end
end)

--// ═════════════════════════════════════════════
--// SETTINGS TAB
--// ═════════════════════════════════════════════
local settingsPage = tabs["Settings"].page

createSection(settingsPage, "⚙️ Settings")

createToggle(settingsPage, "Show FPS Counter", function(enabled)
    fpsCounter.Visible = enabled
end)

createToggle(settingsPage, "Remove Fog", function(enabled)
    if enabled then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 10000
        Lighting.FogStart = 0
    end
    notify("Fog", enabled and "Removido" or "Restaurado", 2)
end)

createSection(settingsPage, "🎮 Quick Actions")

createButton(settingsPage, "📋 Copy Game ID", function()
    if setclipboard then
        setclipboard(tostring(game.PlaceId))
        notify("Clipboard", "Game ID copiado", 2)
    else
        notify("Error", "No soportado", 2)
    end
end)

createButton(settingsPage, "🧹 Clear All ESP", function()
    espFolder:ClearAllChildren()
    notify("ESP", "Limpiado", 2)
end)

createButton(settingsPage, "📸 Low Graphics", function()
    settings().Rendering.QualityLevel = 1
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
            v.Enabled = false
        end
    end
    notify("Graphics", "Reducidos para +FPS", 2)
end)

createButton(settingsPage, "🔄 Reset Settings", function()
    for key in pairs(states) do
        states[key] = false
    end
    config.flySpeed = 80
    config.walkSpeed = 16
    config.jumpPower = 50
    notify("Settings", "Reseteado", 2)
end)

createSection(settingsPage, "ℹ️ Info")

local infoBox = Instance.new("Frame", settingsPage)
infoBox.Size = UDim2.new(1, 0, 0, 200)
infoBox.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
infoBox.BorderSizePixel = 0
infoBox.ZIndex = 999999

Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0, 8)
local infoStroke = Instance.new("UIStroke", infoBox)
infoStroke.Color = Color3.fromRGB(200, 0, 0)
infoStroke.Thickness = 1

local infoLabel = Instance.new("TextLabel", infoBox)
infoLabel.Size = UDim2.new(1, -16, 1, -16)
infoLabel.Position = UDim2.new(0, 8, 0, 8)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = [[🐉 DRAGON RED v7 - Universal Edition

✨ Características:
• Fly Mode con velocidad ajustable
• Noclip para atravesar paredes
• Infinite Jump
• ESP personalizable con distancia
• Click TP (Ctrl + Click)
• FPS Counter
• Control de velocidad/salto
• Sistema de jugadores completo
• Hitbox Expander
• Kill All / Kill Selected

⌨️ Atajos:
• RightShift - Toggle GUI
• Ctrl + Click - Teleport

🎯 Script universal optimizado
Sin lag • Anti-kick • Ligero

Created by: Krxtopher]]
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.Font = Enum.Font.Code
infoLabel.TextSize = 11
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextXAlignment.Top
infoLabel.TextWrapped = true
infoLabel.ZIndex = 999999

--// Carga completa
notify("🐉 Dragon Red v7", "Loaded by Krxtopher • RightShift to toggle", 3)
print("═══════════════════════════════════")
print("🐉 DRAGON RED v7 - Universal Edition")
print("✅ Created by: Krxtopher")
print("⌨️ Press RightShift to toggle")
print("═══════════════════════════════════")--[[
    🐉 DRAGON RED ADMIN PANEL v7 - ULTIMATE EDITION
    ═══════════════════════════════════════════════
    ✨ Script universal para todos los juegos
    🎯 Enfocado en ayudar al jugador
    ⚡ Optimizado y sin lag
    🎨 Diseño moderno y profesional
    
    Created by: Krxtopher
]]

--// Servicios (optimizado)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

--// Variables principales
local char = player.Character or player.CharacterAdded:Wait()
local hum, root

local function getHumanoid()
    char = player.Character or player.CharacterAdded:Wait()
    hum = char:FindFirstChildOfClass("Humanoid")
    root = char:FindFirstChild("HumanoidRootPart")
    return hum, root
end

hum, root = getHumanoid()

-- Reconexión automática
player.CharacterAdded:Connect(function(c)
    char = c
    task.wait(0.1)
    hum, root = getHumanoid()
    
    -- Reaplicar velocidades si están activas
    if states.WalkSpeed and hum then
        hum.WalkSpeed = config.walkSpeed
    end
    if states.JumpPower and hum then
        hum.JumpPower = config.jumpPower
    end
end)

--// Estados
local states = {
    Fly = false,
    Noclip = false,
    InfJump = false,
    ESP = false,
    Fullbright = false,
    ClickTP = false,
    WalkSpeed = false,
    JumpPower = false,
    HitboxExpander = false,
    Spinbot = false
}

--// Configuración
local config = {
    flySpeed = 80,
    walkSpeed = 16,
    jumpPower = 50,
    espColor = Color3.fromRGB(255, 0, 0),
    hitboxSize = 20
}

local savedPosition = nil
local selectedPlayer = nil
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "DragonESP"

local originalSizes = {} -- Para guardar tamaños originales de hitboxes

--// Sistema de notificaciones (ultra ligero)
local function notify(title, text, duration)
    task.spawn(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "DragonNotif"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 999999999
        
        pcall(function()
            gui.Parent = player.PlayerGui
        end)
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 70)
        frame.Position = UDim2.new(1, 20, 0, 20)
        frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Color3.fromRGB(200, 0, 0)
        stroke.Thickness = 2
        
        local icon = Instance.new("TextLabel", frame)
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 10, 0.5, -20)
        icon.BackgroundTransparency = 1
        icon.Text = "🐉"
        icon.TextSize = 24
        
        local titleLabel = Instance.new("TextLabel", frame)
        titleLabel.Size = UDim2.new(1, -60, 0, 20)
        titleLabel.Position = UDim2.new(0, 55, 0, 10)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.Font = Enum.Font.Code
        titleLabel.TextSize = 14
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local textLabel = Instance.new("TextLabel", frame)
        textLabel.Size = UDim2.new(1, -60, 0, 30)
        textLabel.Position = UDim2.new(0, 55, 0, 30)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        textLabel.Font = Enum.Font.Code
        textLabel.TextSize = 12
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextWrapped = true
        
        frame:TweenPosition(UDim2.new(1, -320, 0, 20), "Out", "Back", 0.4, true)
        task.wait(duration or 3)
        frame:TweenPosition(UDim2.new(1, 20, 0, 20), "In", "Back", 0.3, true)
        task.wait(0.4)
        gui:Destroy()
    end)
end

--// GUI Principal con prioridad máxima
local gui = Instance.new("ScreenGui")
gui.Name = "DragonRedGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999999 -- Prioridad sobre todas las demás GUIs
gui.Parent = player.PlayerGui

-- FPS Counter
local fpsCounter = Instance.new("TextLabel")
fpsCounter.Size = UDim2.new(0, 90, 0, 28)
fpsCounter.Position = UDim2.new(1, -100, 0, 10)
fpsCounter.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
fpsCounter.BorderSizePixel = 0
fpsCounter.Text = "FPS: 60"
fpsCounter.TextColor3 = Color3.fromRGB(0, 255, 0)
fpsCounter.Font = Enum.Font.Code
fpsCounter.TextSize = 13
fpsCounter.Visible = false
fpsCounter.Parent = gui
fpsCounter.ZIndex = 999999

local fpsCorner = Instance.new("UICorner")
fpsCorner.CornerRadius = UDim.new(0, 6)
fpsCorner.Parent = fpsCounter

local fpsStroke = Instance.new("UIStroke")
fpsStroke.Color = Color3.fromRGB(200, 0, 0)
fpsStroke.Thickness = 1
fpsStroke.Parent = fpsCounter

-- Actualizar FPS (optimizado)
local lastTime = tick()
local fps = 60
RunService.RenderStepped:Connect(function()
    if fpsCounter.Visible then
        fps = math.floor(1 / (tick() - lastTime))
        lastTime = tick()
        fpsCounter.Text = "FPS: " .. fps
        
        if fps >= 50 then
            fpsCounter.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif fps >= 30 then
            fpsCounter.TextColor3 = Color3.fromRGB(255, 255, 0)
        else
            fpsCounter.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end)

-- Icono minimizado (DRAGGABLE)
local icon = Instance.new("TextButton")
icon.Size = UDim2.new(0, 48, 0, 48)
icon.Position = UDim2.new(0, 15, 1, -65)
icon.Text = "🐉"
icon.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
icon.TextColor3 = Color3.fromRGB(200, 0, 0)
icon.TextSize = 26
icon.Visible = false
icon.Parent = gui
icon.AutoButtonColor = false
icon.Active = true
icon.Draggable = false
icon.ZIndex = 999999

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = icon

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(200, 0, 0)
iconStroke.Thickness = 2
iconStroke.Parent = icon

-- Panel principal (más limpio)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 650, 0, 480)
frame.Position = UDim2.new(0.5, -325, 0.5, -240)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = false
frame.Parent = gui
frame.ZIndex = 999999

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local frameBorder = Instance.new("UIStroke")
frameBorder.Color = Color3.fromRGB(200, 0, 0)
frameBorder.Thickness = 2
frameBorder.Parent = frame

-- TopBar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 45)
topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.ZIndex = 999999
topBar.Parent = frame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 14)
topCorner.Parent = topBar

local topFix = Instance.new("Frame")
topFix.Size = UDim2.new(1, 0, 0, 15)
topFix.Position = UDim2.new(0, 0, 1, -15)
topFix.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topFix.BorderSizePixel = 0
topFix.ZIndex = 999999
topFix.Parent = topBar

local logo = Instance.new("TextLabel", topBar)
logo.Size = UDim2.new(0, 35, 0, 35)
logo.Position = UDim2.new(0, 8, 0.5, -17.5)
logo.BackgroundTransparency = 1
logo.Text = "🐉"
logo.TextSize = 24
logo.ZIndex = 999999

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(0, 180, 0, 22)
title.Position = UDim2.new(0, 48, 0, 4)
title.BackgroundTransparency = 1
title.Text = "DRAGON RED"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Code
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 999999

local subtitle = Instance.new("TextLabel", topBar)
subtitle.Size = UDim2.new(0, 180, 0, 18)
subtitle.Position = UDim2.new(0, 48, 0, 24)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Universal Edition v7"
subtitle.TextColor3 = Color3.fromRGB(140, 140, 140)
subtitle.Font = Enum.Font.Code
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 999999

local userInfo = Instance.new("TextLabel", topBar)
userInfo.Size = UDim2.new(0, 180, 0, 18)
userInfo.Position = UDim2.new(1, -190, 0, 6)
userInfo.BackgroundTransparency = 1
userInfo.Text = "👤 " .. player.Name
userInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
userInfo.Font = Enum.Font.Code
userInfo.TextSize = 12
userInfo.TextXAlignment = Enum.TextXAlignment.Right
userInfo.ZIndex = 999999

local serverInfo = Instance.new("TextLabel", topBar)
serverInfo.Size = UDim2.new(0, 180, 0, 18)
serverInfo.Position = UDim2.new(1, -190, 0, 23)
serverInfo.BackgroundTransparency = 1
serverInfo.Text = "🌐 " .. #Players:GetPlayers() .. " Players"
serverInfo.TextColor3 = Color3.fromRGB(140, 140, 140)
serverInfo.Font = Enum.Font.Code
serverInfo.TextSize = 10
serverInfo.TextXAlignment = Enum.TextXAlignment.Right
serverInfo.ZIndex = 999999

Players.PlayerAdded:Connect(function()
    serverInfo.Text = "🌐 " .. #Players:GetPlayers() .. " Players"
end)

Players.PlayerRemoving:Connect(function()
    serverInfo.Text = "🌐 " .. #Players:GetPlayers() .. " Players"
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
closeBtn.Text = "✖"
closeBtn.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.Code
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 999999
closeBtn.Parent = topBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
end)

closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
end)

-- Variables para drag
local iconDragging = false
local iconDragStart, iconStartPos
local frameDragging = false
local frameDragStart, frameStartPos

-- Funciones minimizar/maximizar
local function minimize()
    frame.Visible = false
    icon.Visible = true
end

local function maximize()
    frame.Visible = true
    icon.Visible = false
end

closeBtn.MouseButton1Click:Connect(minimize)
icon.MouseButton1Click:Connect(maximize)

-- Drag system para el ICONO (cuando está minimizado)
icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        iconDragging = true
        iconDragStart = input.Position
        iconStartPos = icon.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                iconDragging = false
            end
        end)
    end
end)

-- Drag system para el PANEL (barra superior)
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        frameDragging = true
        frameDragStart = input.Position
        frameStartPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                frameDragging = false
            end
        end)
    end
end)

-- Handler de movimiento unificado
UIS.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        -- Drag del icono
        if iconDragging and iconDragStart then
            local delta = input.Position - iconDragStart
            icon.Position = UDim2.new(
                iconStartPos.X.Scale,
                iconStartPos.X.Offset + delta.X,
                iconStartPos.Y.Scale,
                iconStartPos.Y.Offset + delta.Y
            )
        end
        
        -- Drag del panel
        if frameDragging and frameDragStart then
            local delta = input.Position - frameDragStart
            frame.Position = UDim2.new(
                frameStartPos.X.Scale,
                frameStartPos.X.Offset + delta.X,
                frameStartPos.Y.Scale,
                frameStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

-- Asegurar que el drag se detenga al soltar el mouse
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        iconDragging = false
        frameDragging = false
    end
end)

-- Toggle con RightShift
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if frame.Visible then 
            minimize() 
        else 
            maximize() 
        end
    end
end)

-- Sidebar y contenido
local sidebar = Instance.new("Frame", frame)
sidebar.Size = UDim2.new(0, 140, 1, -45)
sidebar.Position = UDim2.new(0, 0, 0, 45)
sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 999999

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, -140, 1, -45)
content.Position = UDim2.new(0, 140, 0, 45)
content.BackgroundTransparency = 1
content.ZIndex = 999999

-- Sistema de tabs (limpio)
local tabs = {}
local currentTab = nil

local function createTab(name, icon, yPos)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -8, 0, 38)
    btn.Position = UDim2.new(0, 4, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Text = icon .. "  " .. name
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.ZIndex = 999999
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 0
    
    local padding = Instance.new("UIPadding", btn)
    padding.PaddingLeft = UDim.new(0, 12)
    
    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 999999
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 8)
    
    tabs[name] = {button = btn, page = page, stroke = stroke}
    
    btn.MouseButton1Click:Connect(function()
        for n, data in pairs(tabs) do
            data.page.Visible = (n == name)
            if n == name then
                data.button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                data.button.TextColor3 = Color3.fromRGB(255, 255, 255)
                data.stroke.Thickness = 2
            else
                data.button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                data.button.TextColor3 = Color3.fromRGB(180, 180, 180)
                data.stroke.Thickness = 0
            end
        end
    end)
end

-- Crear tabs
createTab("Movement", "🚀", 8)
createTab("Players", "👥", 52)
createTab("Visual", "👁️", 96)
createTab("Misc", "🛠️", 140)
createTab("Settings", "⚙️", 184)

-- Activar primer tab
tabs["Movement"].button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
tabs["Movement"].button.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs["Movement"].stroke.Thickness = 2
tabs["Movement"].page.Visible = true

-- Helper functions UI (optimizados)
local function createSection(parent, title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 32)
    section.BackgroundTransparency = 1
    section.ZIndex = 999999
    section.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Code
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 999999
    label.Parent = section
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 1, -4)
    line.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    line.BorderSizePixel = 0
    line.ZIndex = 999999
    line.Parent = section
end

local function createToggle(parent, text, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 42)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    container.BorderSizePixel = 0
    container.ZIndex = 999999
    container.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 1
    stroke.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -56, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 999999
    label.Parent = container
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 42, 0, 24)
    toggle.Position = UDim2.new(1, -50, 0.5, -12)
    toggle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.ZIndex = 999999
    toggle.Parent = container
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggle
    
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 18, 0, 18)
    indicator.Position = UDim2.new(0, 3, 0.5, -9)
    indicator.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 999999
    indicator.Parent = toggle
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = indicator
    
    local enabled = false
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(25, 25, 25)}):Play()
        TweenService:Create(indicator, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(50, 50, 50)
        }):Play()
        if callback then callback(enabled) end
    end)
end

local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.Text = text
    btn.AutoButtonColor = false
    btn.ZIndex = 999999
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 2
    stroke.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(240, 20, 20)}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 0, 0)}):Play()
    end)
    
    if callback then btn.MouseButton1Click:Connect(callback) end
end

local function createSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 56)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    container.BorderSizePixel = 0
    container.ZIndex = 999999
    container.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 1
    stroke.Parent = container
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 0, 18)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 999999
    label.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.Position = UDim2.new(1, -62, 0, 6)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 999999
    valueLabel.Parent = container
    
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    track.BorderSizePixel = 0
    track.ZIndex = 999999
    track.Parent = container
    
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    fill.BorderSizePixel = 0
    fill.ZIndex = 999999
    fill.Parent = track
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    local dragging = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging--[[
    🐉 DRAGON RED ADMIN PANEL v7 - ULTIMATE EDITION
    ═══════════════════════════════════════════════
    ✨ Script universal para todos los juegos
    🎯 Enfocado en ayudar al jugador
    ⚡ Optimizado y sin lag
    🎨 Diseño moderno y profesional
    
    Created by: Krxtopher
]]

--// Servicios (optimizado)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

--// Variables principales
local char = player.Character or player.CharacterAdded:Wait()
local hum, root

local function getHumanoid()
    char = player.Character or player.CharacterAdded:Wait()
    hum = char:FindFirstChildOfClass("Humanoid")
    root = char:FindFirstChild("HumanoidRootPart")
    return hum, root
end

hum, root = getHumanoid()

-- Reconexión automática
player.CharacterAdded:Connect(function(c)
    char = c
    task.wait(0.1)
    hum, root = getHumanoid()
    
    -- Reaplicar velocidades si están activas
    if states.WalkSpeed and hum then
        hum.WalkSpeed = config.walkSpeed
    end
    if states.JumpPower and hum then
        hum.JumpPower = config.jumpPower
    end
end)

--// Estados
local states = {
    Fly = false,
    Noclip = false,
    InfJump = false,
    ESP = false,
    Fullbright = false,
    ClickTP = false,
    WalkSpeed = false,
    JumpPower = false,
    HitboxExpander = false,
    Spinbot = false
}

--// Configuración
local config = {
    flySpeed = 80,
    walkSpeed = 16,
    jumpPower = 50,
    espColor = Color3.fromRGB(255, 0, 0),
    hitboxSize = 20
}

local savedPosition = nil
local selectedPlayer = nil
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "DragonESP"

local originalSizes = {} -- Para guardar tamaños originales de hitboxes

--// Sistema de notificaciones (ultra ligero)
local function notify(title, text, duration)
    task.spawn(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "DragonNotif"
        gui.ResetOnSpawn = false
        
        pcall(function()
            gui.Parent = player.PlayerGui
        end)
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 70)
        frame.Position = UDim2.new(1, 20, 0, 20)
        frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Color3.fromRGB(200, 0, 0)
        stroke.Thickness = 2
        
        local icon = Instance.new("TextLabel", frame)
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 10, 0.5, -20)
        icon.BackgroundTransparency = 1
        icon.Text = "🐉"
        icon.TextSize = 24
        
        local titleLabel = Instance.new("TextLabel", frame)
        titleLabel.Size = UDim2.new(1, -60, 0, 20)
        titleLabel.Position = UDim2.new(0, 55, 0, 10)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.Font = Enum.Font.Code
        titleLabel.TextSize = 14
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local textLabel = Instance.new("TextLabel", frame)
        textLabel.Size = UDim2.new(1, -60, 0, 30)
        textLabel.Position = UDim2.new(0, 55, 0, 30)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        textLabel.Font = Enum.Font.Code
        textLabel.TextSize = 12
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextWrapped = true
        
        frame:TweenPosition(UDim2.new(1, -320, 0, 20), "Out", "Back", 0.4, true)
        task.wait(duration or 3)
        frame:TweenPosition(UDim2.new(1, 20, 0, 20), "In", "Back", 0.3, true)
        task.wait(0.4)
        gui:Destroy()
    end)
end

--// GUI Principal
local gui = Instance.new("ScreenGui")
gui.Name = "DragonRedGUI"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

-- FPS Counter
local fpsCounter = Instance.new("TextLabel")
fpsCounter.Size = UDim2.new(0, 90, 0, 28)
fpsCounter.Position = UDim2.new(1, -100, 0, 10)
fpsCounter.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
fpsCounter.BorderSizePixel = 0
fpsCounter.Text = "FPS: 60"
fpsCounter.TextColor3 = Color3.fromRGB(0, 255, 0)
fpsCounter.Font = Enum.Font.Code
fpsCounter.TextSize = 13
fpsCounter.Visible = false
fpsCounter.Parent = gui

Instance.new("UICorner", fpsCounter).CornerRadius = UDim.new(0, 6)
local fpsStroke = Instance.new("UIStroke", fpsCounter)
fpsStroke.Color = Color3.fromRGB(200, 0, 0)
fpsStroke.Thickness = 1

-- Actualizar FPS (optimizado)
local lastTime = tick()
local fps = 60
RunService.RenderStepped:Connect(function()
    if fpsCounter.Visible then
        fps = math.floor(1 / (tick() - lastTime))
        lastTime = tick()
        fpsCounter.Text = "FPS: " .. fps
        
        if fps >= 50 then
            fpsCounter.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif fps >= 30 then
            fpsCounter.TextColor3 = Color3.fromRGB(255, 255, 0)
        else
            fpsCounter.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end
end)

-- Icono minimizado
local icon = Instance.new("TextButton")
icon.Size = UDim2.new(0, 48, 0, 48)
icon.Position = UDim2.new(0, 15, 1, -65)
icon.Text = "🐉"
icon.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
icon.TextColor3 = Color3.fromRGB(200, 0, 0)
icon.TextSize = 26
icon.Visible = false
icon.Parent = gui
icon.AutoButtonColor = false

Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
local iconStroke = Instance.new("UIStroke", icon)
iconStroke.Color = Color3.fromRGB(200, 0, 0)
iconStroke.Thickness = 2

-- Panel principal (más limpio)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 650, 0, 480)
frame.Position = UDim2.new(0.5, -325, 0.5, -240)
frame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
local frameBorder = Instance.new("UIStroke", frame)
frameBorder.Color = Color3.fromRGB(200, 0, 0)
frameBorder.Thickness = 2

-- TopBar
local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1, 0, 0, 45)
topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topBar.BorderSizePixel = 0

Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 14)

local topFix = Instance.new("Frame", topBar)
topFix.Size = UDim2.new(1, 0, 0, 15)
topFix.Position = UDim2.new(0, 0, 1, -15)
topFix.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
topFix.BorderSizePixel = 0

local logo = Instance.new("TextLabel", topBar)
logo.Size = UDim2.new(0, 35, 0, 35)
logo.Position = UDim2.new(0, 8, 0.5, -17.5)
logo.BackgroundTransparency = 1
logo.Text = "🐉"
logo.TextSize = 24

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(0, 180, 0, 22)
title.Position = UDim2.new(0, 48, 0, 4)
title.BackgroundTransparency = 1
title.Text = "DRAGON RED"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.Code
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = Instance.new("TextLabel", topBar)
subtitle.Size = UDim2.new(0, 180, 0, 18)
subtitle.Position = UDim2.new(0, 48, 0, 24)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Universal Edition v7"
subtitle.TextColor3 = Color3.fromRGB(140, 140, 140)
subtitle.Font = Enum.Font.Code
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left

local userInfo = Instance.new("TextLabel", topBar)
userInfo.Size = UDim2.new(0, 180, 0, 18)
userInfo.Position = UDim2.new(1, -190, 0, 6)
userInfo.BackgroundTransparency = 1
userInfo.Text = "👤 " .. player.Name
userInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
userInfo.Font = Enum.Font.Code
userInfo.TextSize = 12
userInfo.TextXAlignment = Enum.TextXAlignment.Right

local serverInfo = Instance.new("TextLabel", topBar)
serverInfo.Size = UDim2.new(0, 180, 0, 18)
serverInfo.Position = UDim2.new(1, -190, 0, 23)
serverInfo.BackgroundTransparency = 1
serverInfo.Text = "🌐 " .. #Players:GetPlayers() .. " Players"
serverInfo.TextColor3 = Color3.fromRGB(140, 140, 140)
serverInfo.Font = Enum.Font.Code
serverInfo.TextSize = 10
serverInfo.TextXAlignment = Enum.TextXAlignment.Right

Players.PlayerAdded:Connect(function()
    serverInfo.Text = "🌐 " .. #Players:GetPlayers() .. " Players"
end)

Players.PlayerRemoving:Connect(function()
    serverInfo.Text = "🌐 " .. #Players:GetPlayers() .. " Players"
end)

local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
closeBtn.Text = "✖"
closeBtn.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.Code

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Funciones minimizar/maximizar
local iconDragging = false
local iconDragStart, iconStartPos

local function minimize()
    frame.Visible = false
    icon.Visible = true
    notify("Dragon Red", "Panel minimizado", 2)
end

local function maximize()
    frame.Visible = true
    icon.Visible = false
end

closeBtn.MouseButton1Click:Connect(minimize)
icon.MouseButton1Click:Connect(maximize)

-- Drag icono
icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        iconDragging = true
        iconDragStart = input.Position
        iconStartPos = icon.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if iconDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - iconDragStart
        icon.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X, iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        iconDragging = false
    end
end)

-- Drag panel
local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Toggle con RightShift
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if frame.Visible then minimize() else maximize() end
    end
end)

-- Sidebar y contenido
local sidebar = Instance.new("Frame", frame)
sidebar.Size = UDim2.new(0, 140, 1, -45)
sidebar.Position = UDim2.new(0, 0, 0, 45)
sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
sidebar.BorderSizePixel = 0

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, -140, 1, -45)
content.Position = UDim2.new(0, 140, 0, 45)
content.BackgroundTransparency = 1

-- Sistema de tabs (limpio)
local tabs = {}
local currentTab = nil

local function createTab(name, icon, yPos)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -8, 0, 38)
    btn.Position = UDim2.new(0, 4, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Text = icon .. "  " .. name
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 0
    
    local padding = Instance.new("UIPadding", btn)
    padding.PaddingLeft = UDim.new(0, 12)
    
    local page = Instance.new("ScrollingFrame", content)
    page.Size = UDim2.new(1, -16, 1, -16)
    page.Position = UDim2.new(0, 8, 0, 8)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 8)
    
    tabs[name] = {button = btn, page = page, stroke = stroke}
    
    btn.MouseButton1Click:Connect(function()
        for n, data in pairs(tabs) do
            data.page.Visible = (n == name)
            if n == name then
                data.button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                data.button.TextColor3 = Color3.fromRGB(255, 255, 255)
                data.stroke.Thickness = 2
            else
                data.button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                data.button.TextColor3 = Color3.fromRGB(180, 180, 180)
                data.stroke.Thickness = 0
            end
        end
    end)
end

-- Crear tabs
createTab("Movement", "🚀", 8)
createTab("Players", "👥", 52)
createTab("Visual", "👁️", 96)
createTab("Misc", "🛠️", 140)
createTab("Settings", "⚙️", 184)

-- Activar primer tab
tabs["Movement"].button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
tabs["Movement"].button.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs["Movement"].stroke.Thickness = 2
tabs["Movement"].page.Visible = true

-- Helper functions UI (optimizados)
local function createSection(parent, title)
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(1, 0, 0, 32)
    section.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", section)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Code
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local line = Instance.new("Frame", section)
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 1, -4)
    line.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    line.BorderSizePixel = 0
end

local function createToggle(parent, text, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 42)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    container.BorderSizePixel = 0
    
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 1
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -56, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local toggle = Instance.new("TextButton", container)
    toggle.Size = UDim2.new(0, 42, 0, 24)
    toggle.Position = UDim2.new(1, -50, 0.5, -12)
    toggle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    toggle.Text = ""
    toggle.AutoButtonColor = false
    
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)
    
    local indicator = Instance.new("Frame", toggle)
    indicator.Size = UDim2.new(0, 18, 0, 18)
    indicator.Position = UDim2.new(0, 3, 0.5, -9)
    indicator.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    indicator.BorderSizePixel = 0
    
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    
    local enabled = false
    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(25, 25, 25)}):Play()
        TweenService:Create(indicator, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(50, 50, 50)
        }):Play()
        if callback then callback(enabled) end
    end)
end

local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 13
    btn.Text = text
    btn.AutoButtonColor = false
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 2
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(240, 20, 20)}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 0, 0)}):Play()
    end)
    
    if callback then btn.MouseButton1Click:Connect(callback) end
end

local function createSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 56)
    container.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    container.BorderSizePixel = 0
    
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 1
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -24, 0, 18)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueLabel = Instance.new("TextLabel", container)
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.Position = UDim2.new(1, -62, 0, 6)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local track = Instance.new("Frame", container)
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    track.BorderSizePixel = 0
    
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    fill.BorderSizePixel = 0
    
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            local value = math.floor(min + (max - min) * percent)
            valueLabel.Text = tostring(value)
            if callback then callback(value) end
        end
    end)
end

--// ═════════════════════════════════════════════
--// MOVEMENT TAB
--// ═════════════════════════════════════════════
local movePage = tabs["Movement"].page

createSection(movePage, "⚡ Movement Controls")

createToggle(movePage, "Fly Mode", function(enabled)
    states.Fly = enabled
    hum, root = getHumanoid()
    if not hum or not root then return end
    
    if enabled then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "DragonFly"
        bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bv.Velocity = Vector3.new()
        bv.Parent = root
        
        local bg = Instance.new("BodyGyro")
        bg.Name = "DragonGyro"
        bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        bg.P = 9e4
        bg.CFrame = camera.CFrame
        bg.Parent = root
        
        hum.PlatformStand = true
        notify("Fly", "Activado - WASD + Space/Ctrl", 2)
    else
        if root:FindFirstChild("DragonFly") then root.DragonFly:Destroy() end
        if root:FindFirstChild("DragonGyro") then root.DragonGyro:Destroy() end
        if hum then hum.PlatformStand = false end
        notify("Fly", "Desactivado", 2)
    end
end)

createToggle(movePage, "Noclip", function(enabled)
    states.Noclip = enabled
    notify("Noclip", enabled and "Activado" or "Desactivado", 2)
end)

createToggle(movePage, "Infinite Jump", function(enabled)
    states.InfJump = enabled
    notify("Infinite Jump", enabled and "Activado" or "Desactivado", 2)
end)

createSection(movePage, "⚙️ Speed Settings")

createSlider(movePage, "Walk Speed", 16, 150, 16, function(value)
    config.walkSpeed = value
    if states.WalkSpeed then
        hum, root = getHumanoid()
        if hum then hum.WalkSpeed = value end
    end
end)

createToggle(movePage, "Enable Custom Walk Speed", function(enabled)
    states.WalkSpeed = enabled
    hum, root = getHumanoid()
    if hum then
        if enabled then
            hum.WalkSpeed = config.walkSpeed
        else
            hum.WalkSpeed = 16
        end
    end
    notify("Walk Speed", enabled and ("Activado: " .. config.walkSpeed) or "Desactivado", 2)
end)

createSlider(movePage, "Jump Power", 50, 200, 50, function(value)
    config.jumpPower = value
    if states.JumpPower then
        hum, root = getHumanoid()
        if hum then hum.JumpPower = value end
    end
end)

createToggle(movePage, "Enable Custom Jump Power", function(enabled)
    states.JumpPower = enabled
    hum, root = getHumanoid()
    if hum then
        if enabled then
            hum.JumpPower = config.jumpPower
        else
            hum.JumpPower = 50
        end
    end
    notify("Jump Power", enabled and ("Activado: " .. config.jumpPower) or "Desactivado", 2)
end)

createSlider(movePage, "Fly Speed", 20, 250, 80, function(value)
    config.flySpeed = value
end)

-- Fly logic
local flyVel = Vector3.new()
RunService.RenderStepped:Connect(function()
    if states.Fly then
        hum, root = getHumanoid()
        if not root then return end
        
        local bv = root:FindFirstChild("DragonFly")
        local bg = root:FindFirstChild("DragonGyro")
        if not bv or not bg then return end
        
        local dir = Vector3.new()
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        
        if dir.Magnitude > 0 then
            dir = dir.Unit * config.flySpeed
        end
        
        flyVel = flyVel:Lerp(dir, 0.2)
        bv.Velocity = flyVel
        bg.CFrame = camera.CFrame
    end
end)

-- Noclip logic
RunService.Stepped:Connect(function()
    if states.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if states.InfJump then
        hum, root = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

--// ═════════════════════════════════════════════
--// PLAYERS TAB
--// ═════════════════════════════════════════════
local playersPage = tabs["Players"].page

createSection(playersPage, "👥 Player List")

local playerListContainer = Instance.new("Frame", playersPage)
playerListContainer.Size = UDim2.new(1, 0, 0, 280)
playerListContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
playerListContainer.BorderSizePixel = 0

Instance.new("UICorner", playerListContainer).CornerRadius = UDim.new(0, 8)
local playerListStroke = Instance.new("UIStroke", playerListContainer)
playerListStroke.Color = Color3.fromRGB(200, 0, 0)
playerListStroke.Thickness = 1

local playerScroll = Instance.new("ScrollingFrame", playerListContainer)
playerScroll.Size = UDim2.new(1, -8, 1, -8)
playerScroll.Position = UDim2.new(0, 4, 0, 4)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 5
playerScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 0, 0)
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local playerLayout = Instance.new("UIListLayout", playerScroll)
playerLayout.Padding = UDim.new(0, 4)

local function createPlayerButton(plr)
    local btn = Instance.new("TextButton", playerScroll)
    btn.Size = UDim2.new(1, -8, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Text = ""
    btn.AutoButtonColor = false
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(200, 0, 0)
    btnStroke.Thickness = 1
    
    local nameLabel = Instance.new("TextLabel", btn)
    nameLabel.Size = UDim2.new(1, -45, 0, 18)
    nameLabel.Position = UDim2.new(0, 8, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.Code
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local distLabel = Instance.new("TextLabel", btn)
    distLabel.Size = UDim2.new(1, -45, 0, 14)
    distLabel.Position = UDim2.new(0, 8, 0, 22)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "Distance: ---"
    distLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    distLabel.Font = Enum.Font.Code
    distLabel.TextSize = 10
    distLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local selectBtn = Instance.new("TextButton", btn)
    selectBtn.Size = UDim2.new(0, 32, 0, 28)
    selectBtn.Position = UDim2.new(1, -36, 0.5, -14)
    selectBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    selectBtn.Text = "→"
    selectBtn.TextSize = 16
    selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    selectBtn.Font = Enum.Font.Code
    
    Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 5)
    
    selectBtn.MouseButton1Click:Connect(function()
        selectedPlayer = plr
        notify("Player Selected", plr.Name, 2)
        
        for _, child in ipairs(playerScroll:GetChildren()) do
            if child:IsA("TextButton") then
                local sel = child:FindFirstChild("TextButton")
                if sel then
                    sel.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                end
            end
        end
        selectBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
    end)
    
    task.spawn(function()
        while btn.Parent do
            task.wait(0.5)
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                hum, root = getHumanoid()
                if root then
                    local dist = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    distLabel.Text = string.format("Distance: %.0f", dist)
                end
            else
                distLabel.Text = "Distance: ---"
            end
        end
    end)
end

local function updatePlayerList()
    for _, child in ipairs(playerScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    if not playerScroll:FindFirstChildOfClass("UIListLayout") then
        playerLayout = Instance.new("UIListLayout", playerScroll)
        playerLayout.Padding = UDim.new(0, 4)
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            createPlayerButton(plr)
        end
    end
    
    notify("Player List", (#Players:GetPlayers() - 1) .. " jugadores", 2)
end

-- Cargar lista inicial
updatePlayerList()

createSection(playersPage, "🎯 Player Actions")

createButton(playersPage, "🔄 Refresh Player List", updatePlayerList)

createButton(playersPage, "📍 Teleport to Selected", function()
    if selectedPlayer and selectedPlayer.Character then
        hum, root = getHumanoid()
        local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 3, 3)
            notify("Teleported", "To " .. selectedPlayer.Name, 2)
        else
            notify("Error", "No se pudo teleportar", 2)
        end
    else
        notify("Error", "No player selected", 2)
    end
end)

createButton(playersPage, "👁️ View Selected Player", function()
    if selectedPlayer and selectedPlayer.Character then
        local targetHum = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        if targetHum then
            camera.CameraSubject = targetHum
            notify("Viewing", selectedPlayer.Name, 2)
        else
            notify("Error", "No se pudo ver", 2)
        end
    else
        notify("Error", "No player selected", 2)
    end
end)

createButton(playersPage, "↩️ Reset Camera", function()
    hum, root = getHumanoid()
    if hum then
        camera.CameraSubject = hum
        notify("Camera", "Reset to self", 2)
    end
end)

--// ═════════════════════════════════════════════
--// VISUAL TAB
--// ═════════════════════════════════════════════
local visualPage = tabs["Visual"].page

createSection(visualPage, "👁️ Visual Features")

createToggle(visualPage, "ESP (Name Tags)", function(enabled)
    states.ESP = enabled
    
    espFolder:ClearAllChildren()
    
    if enabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "DragonESP_" .. plr.Name
                    billboard.Adornee = head
                    billboard.Size = UDim2.new(0, 100, 0, 50)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = espFolder
                    
                    local nameLabel = Instance.new("TextLabel", billboard)
                    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = plr.Name
                    nameLabel.TextColor3 = config.espColor
                    nameLabel.TextStrokeTransparency = 0
                    nameLabel.Font = Enum.Font.Code
                    nameLabel.TextScaled = true
                    
                    local distLabel = Instance.new("TextLabel", billboard)
                    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
                    distLabel.BackgroundTransparency = 1
                    distLabel.Text = "---"
                    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    distLabel.TextStrokeTransparency = 0
                    distLabel.Font = Enum.Font.Code
                    distLabel.TextScaled = true
                    
                    task.spawn(function()
                        while billboard.Parent and plr.Character do
                            task.wait(0.3)
                            hum, root = getHumanoid()
                            local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                            if root and targetRoot then
                                local dist = (targetRoot.Position - root.Position).Magnitude
                                distLabel.Text = string.format("%.0f studs", dist)
                            end
                        end
                    end)
                end
            end
        end
        notify("ESP", "Activado", 2)
    else
        notify("ESP", "Desactivado", 2)
    end
end)

createToggle(visualPage, "Fullbright", function(enabled)
    states.Fullbright = enabled
    
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        notify("Fullbright", "Activado", 2)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
        notify("Fullbright", "Desactivado", 2)
    end
end)

createSection(visualPage, "🎨 ESP Color")

local colorButtons = {
    {name = "Red", color = Color3.fromRGB(255, 0, 0)},
    {name = "Green", color = Color3.fromRGB(0, 255, 0)},
    {name = "Blue", color = Color3.fromRGB(0, 150, 255)},
    {name = "Yellow", color = Color3.fromRGB(255, 255, 0)},
    {name = "Purple", color = Color3.fromRGB(200, 0, 255)},
    {name = "Cyan", color = Color3.fromRGB(0, 255, 255)}
}

local colorContainer = Instance.new("Frame", visualPage)
colorContainer.Size = UDim2.new(1, 0, 0, 85)
colorContainer.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
colorContainer.BorderSizePixel = 0

Instance.new("UICorner", colorContainer).CornerRadius = UDim.new(0, 8)
local colorStroke = Instance.new("UIStroke", colorContainer)
colorStroke.Color = Color3.fromRGB(200, 0, 0)
colorStroke.Thickness = 1

local colorGrid = Instance.new("UIGridLayout", colorContainer)
colorGrid.CellSize = UDim2.new(0.3, 0, 0, 30)
colorGrid.CellPadding = UDim2.new(0.05, 0, 0, 8)

local colorPadding = Instance.new("UIPadding", colorContainer)
colorPadding.PaddingLeft = UDim.new(0.05, 0)
colorPadding.PaddingTop = UDim.new(0, 8)

for _, colorData in ipairs(colorButtons) do
    local btn = Instance.new("TextButton", colorContainer)
    btn.BackgroundColor3 = colorData.color
    btn.Text = colorData.name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Code
    btn.TextSize = 11
    btn.AutoButtonColor = false
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(255, 255, 255)
    btnStroke.Thickness = 0
    
    btn.MouseButton1Click:Connect(function()
        config.espColor = colorData.color
        
        for _, billboard in ipairs(espFolder:GetChildren()) do
            if billboard:IsA("BillboardGui") then
                local nameLabel = billboard:FindFirstChildOfClass("TextLabel")
                if nameLabel then
                    nameLabel.TextColor3 = colorData.color
                end
            end
        end
        
        notify("ESP Color", colorData.name, 2)
        
        for _, otherBtn in ipairs(colorContainer:GetChildren()) do
            if otherBtn:IsA("TextButton") then
                local stroke = otherBtn:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Thickness = 0 end
            end
        end
        btnStroke.Thickness = 3
    end)
end

--// ═════════════════════════════════════════════
--// MISC TAB
--// ═════════════════════════════════════════════
local miscPage = tabs["Misc"].page

createSection(miscPage, "🛠️ Misc Features")

createToggle(miscPage, "Click TP (Hold Ctrl)", function(enabled)
    states.ClickTP = enabled
    notify("Click TP", enabled and "Ctrl + Click para TP" or "Desactivado", 2)
end)

createSection(miscPage, "📍 Position Tools")

createButton(miscPage, "💾 Save Position", function()
    hum, root = getHumanoid()
    if root then
        savedPosition = root.CFrame
        notify("Position", "Guardada", 2)
    end
end)

createButton(miscPage, "📍 Load Position", function()
    hum, root = getHumanoid()
    if root and savedPosition then
        root.CFrame = savedPosition
        notify("Position", "Cargada", 2)
    else
        notify("Error", "No hay posición guardada", 2)
    end
end)

createButton(miscPage, "🔄 Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, player)
end)

createButton(miscPage, "💀 Respawn Character", function()
    if char then
        char:BreakJoints()
        notify("Respawn", "Reapareciendo...", 2)
    end
end)

createSection(miscPage, "⚔️ Combat Actions")

createToggle(miscPage, "Hitbox Expander", function(enabled)
    states.HitboxExpander = enabled
    if not enabled then
        -- Restaurar todas las hitboxes al desactivar
        for playerName, originalSize in pairs(originalSizes) do
            pcall(function()
                local plr = Players:FindFirstChild(playerName)
                if plr and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = originalSize
                        hrp.Transparency = 1
                    end
                end
            end)
        end
        originalSizes = {}
    end
    notify("Hitbox Expander", enabled and "Activado" or "Desactivado", 2)
end)

createSlider(miscPage, "Hitbox Size", 5, 50, 20, function(value)
    config.hitboxSize = value
end)

createToggle(miscPage, "Spinbot (Anti-Hit)", function(enabled)
    states.Spinbot = enabled
    notify("Spinbot", enabled and "Activado" or "Desactivado", 2)
end)

createButton(miscPage, "🔥 Kill All Players", function()
    local count = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local enemyHum = plr.Character:FindFirstChildOfClass("Humanoid")
            if enemyHum then
                pcall(function()
                    enemyHum.Health = 0
                    count = count + 1
                end)
            end
        end
    end
    notify("Kill All", count .. " jugadores eliminados", 2)
end)

createButton(miscPage, "⚡ Kill Selected Player", function()
    if selectedPlayer and selectedPlayer.Character then
        local enemyHum = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        if enemyHum then
            pcall(function()
                enemyHum.Health = 0
                notify("Kill", selectedPlayer.Name .. " eliminado", 2)
            end)
        else
            notify("Error", "No se pudo eliminar", 2)
        end
    else
        notify("Error", "No player selected", 2)
    end
end)

-- Click TP
mouse.Button1Down:Connect(function()
    if states.ClickTP and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        hum, root = getHumanoid()
        if root and mouse.Target then
            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            notify("Click TP", "Teleportado", 1)
        end
    end
end)

-- Hitbox Expander (optimizado anti-kick)
task.spawn(function()
    while true do
        task.wait(1) -- Lento para evitar detección
        if states.HitboxExpander then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    pcall(function()
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            if not originalSizes[plr.Name] then
                                originalSizes[plr.Name] = hrp.Size
                            end
                            
                            hrp.Size = Vector3.new(config.hitboxSize, config.hitboxSize, config.hitboxSize)
                            hrp.Transparency = 1
                            hrp.CanCollide = false
                            hrp.Massless = true
                        end
                    end)
                end
            end
        end
    end
end)

-- Spinbot
local spinSpeed = 0
RunService.RenderStepped:Connect(function()
    if states.Spinbot then
        hum, root = getHumanoid()
        if root then
            spinSpeed = spinSpeed + 20
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
        end
    end
end)

--// ═════════════════════════════════════════════
--// SETTINGS TAB
--// ═════════════════════════════════════════════
local settingsPage = tabs["Settings"].page

createSection(settingsPage, "⚙️ Settings")

createToggle(settingsPage, "Show FPS Counter", function(enabled)
    fpsCounter.Visible = enabled
end)

createToggle(settingsPage, "Remove Fog", function(enabled)
    if enabled then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 10000
        Lighting.FogStart = 0
    end
    notify("Fog", enabled and "Removido" or "Restaurado", 2)
end)

createSection(settingsPage, "🎮 Quick Actions")

createButton(settingsPage, "📋 Copy Game ID", function()
    if setclipboard then
        setclipboard(tostring(game.PlaceId))
        notify("Clipboard", "Game ID copiado", 2)
    else
        notify("Error", "No soportado", 2)
    end
end)

createButton(settingsPage, "🧹 Clear All ESP", function()
    espFolder:ClearAllChildren()
    notify("ESP", "Limpiado", 2)
end)

createButton(settingsPage, "📸 Low Graphics", function()
    settings().Rendering.QualityLevel = 1
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
            v.Enabled = false
        end
    end
    notify("Graphics", "Reducidos para +FPS", 2)
end)

createButton(settingsPage, "🔄 Reset Settings", function()
    for key in pairs(states) do
        states[key] = false
    end
    config.flySpeed = 80
    config.walkSpeed = 16
    config.jumpPower = 50
    notify("Settings", "Reseteado", 2)
end)

createSection(settingsPage, "ℹ️ Info")

local infoBox = Instance.new("Frame", settingsPage)
infoBox.Size = UDim2.new(1, 0, 0, 200)
infoBox.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
infoBox.BorderSizePixel = 0

Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0, 8)
local infoStroke = Instance.new("UIStroke", infoBox)
infoStroke.Color = Color3.fromRGB(200, 0, 0)
infoStroke.Thickness = 1

local infoLabel = Instance.new("TextLabel", infoBox)
infoLabel.Size = UDim2.new(1, -16, 1, -16)
infoLabel.Position = UDim2.new(0, 8, 0, 8)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = [[🐉 DRAGON RED v7 - Universal Edition

✨ Características:
• Fly Mode con velocidad ajustable
• Noclip para atravesar paredes
• Infinite Jump
• ESP personalizable con distancia
• Click TP (Ctrl + Click)
• FPS Counter
• Control de velocidad/salto
• Sistema de jugadores completo

⌨️ Atajos:
• RightShift - Toggle GUI
• Ctrl + Click - Teleport

🎯 Script universal optimizado
Sin lag • Anti-kick • Ligero]]
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.Font = Enum.Font.Code
infoLabel.TextSize = 11
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextXAlignment.Top
infoLabel.TextWrapped = true

--// Carga completa
notify("🐉 Dragon Red v7", "Loaded by Krxtopher • RightShift to toggle", 3)
print("═══════════════════════════════════")
print("🐉 DRAGON RED v7 - Universal Edition")
print("✅ Created by: Krxtopher")
print("⌨️ Press RightShift to toggle")
print("═══════════════════════════════════")

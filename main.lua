local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local placeId = game.PlaceId
local camera = workspace.CurrentCamera

local PVP_PLACE_IDS = {
    [5289429734] = true,
    [5480112241] = true,
    [4524359706] = true,
    [5468388011] = true,
    [3826587512] = true
}

local PVE_PLACE_IDS = {
    [3701546109] = true
}

local function loadRemoteScript(url)
    task.spawn(function()
        loadstring(game:HttpGet(url .. "?v=" .. tostring(os.time())))()
    end)
end

local function loadPvp()
    loadRemoteScript("https://raw.githubusercontent.com/HiIxX0Dexter0XxIiH/Roblox-Dexter-Scripts/main/brm5-pvp/main.lua")
end

local function loadPve()
    loadRemoteScript("https://raw.githubusercontent.com/HiIxX0Dexter0XxIiH/Roblox-Dexter-Scripts/main/brm5-pve/main.lua")
end

-- Bypass / Indetectável Básico
local guiName = ""
for _ = 1, 16 do guiName = guiName .. string.char(math.random(97, 122)) end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.ResetOnSpawn = false

-- Esconde a GUI do anti-cheat usando o CoreGui ou gethui se o executor suportar
local success, err = pcall(function()
    if gethui then
        screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = CoreGui
    else
        screenGui.Parent = CoreGui
    end
end)
if not success then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 505)
frame.Position = UDim2.new(0.5, -160, 0.5, -252)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "Select a Mode"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = frame

local function createButton(name, text, color, posY)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0.8, 0, 0, 45)
    button.Position = UDim2.new(0.1, 0, 0, posY)
    button.BackgroundColor3 = color
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 20
    button.AutoButtonColor = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    button.Parent = frame
    return button
end

local pvpButton = createButton("PVPButton", "PVP", Color3.fromRGB(200, 60, 60), 60)
local pveButton = createButton("PVEButton", "PVE", Color3.fromRGB(60, 200, 60), 115)
local flyButton = createButton("FlyButton", "Fly: OFF", Color3.fromRGB(70, 70, 200), 170)
local noclipButton = createButton("NoClipButton", "NoClip: OFF", Color3.fromRGB(150, 50, 150), 225)
local fovButton = createButton("FOVButton", "FOV: 70", Color3.fromRGB(200, 140, 50), 280)
local silentAimButton = createButton("SilentAimButton", "Silent Aim: OFF", Color3.fromRGB(200, 50, 50), 335)
local espButton = createButton("ESPButton", "ESP: OFF", Color3.fromRGB(50, 200, 200), 390)

local flyEnabled = false
local flying = false
local flySpeed = 60
local noclipEnabled = false
local silentAimEnabled = false
local espEnabled = false
local currentFov = 70

-- TARGETS LOGIC (PLAYERS + NPCs)
local cachedTargets = {}
local function updateTargetsCache()
    local newTargets = {}
    
    -- Jogadores
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if p.Team and player.Team and p.Team == player.Team then continue end
            table.insert(newTargets, p.Character)
        end
    end

    -- NPCs (PVE)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") and obj.Health > 0 then
            local char = obj.Parent
            if char ~= player.Character and not Players:GetPlayerFromCharacter(char) then
                if char:FindFirstChild("Head") then
                    table.insert(newTargets, char)
                end
            end
        end
    end
    
    cachedTargets = newTargets
end

task.spawn(function()
    while task.wait(1) do
        updateTargetsCache()
    end
end)

-- ESP LOGIC
local ESP_Boxes = {}

local function createEspBox(char)
    if ESP_Boxes[char] then return end
    
    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.fromRGB(255, 255, 255)
    Box.Thickness = 1
    Box.Transparency = 1
    Box.Filled = false

    local Name = Drawing.new("Text")
    Name.Visible = false
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Size = 16
    Name.Center = true
    Name.Outline = true
    Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local HealthBar = Drawing.new("Line")
    HealthBar.Visible = false
    HealthBar.Thickness = 2
    HealthBar.Color = Color3.fromRGB(0, 255, 0)
    
    local HealthBarOutline = Drawing.new("Line")
    HealthBarOutline.Visible = false
    HealthBarOutline.Thickness = 4
    HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)

    ESP_Boxes[char] = {Box = Box, Name = Name, HealthBar = HealthBar, HealthBarOutline = HealthBarOutline}
end

local function removeEspBox(char)
    if ESP_Boxes[char] then
        ESP_Boxes[char].Box:Remove()
        ESP_Boxes[char].Name:Remove()
        ESP_Boxes[char].HealthBar:Remove()
        ESP_Boxes[char].HealthBarOutline:Remove()
        ESP_Boxes[char] = nil
    end
end

RunService.RenderStepped:Connect(function()
    -- Limpa ESP de quem morreu ou sumiu
    for char, items in pairs(ESP_Boxes) do
        local found = false
        for _, t in ipairs(cachedTargets) do
            if t == char then
                found = true
                break
            end
        end
        if not found or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            removeEspBox(char)
        end
    end

    if espEnabled then
        for _, char in ipairs(cachedTargets) do
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                createEspBox(char)
                local items = ESP_Boxes[char]
                
                local hrp = char.HumanoidRootPart
                local head = char:FindFirstChild("Head") or hrp
                
                local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                local headVector, _ = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legVector, _ = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                if onScreen then
                    local boxHeight = legVector.Y - headVector.Y
                    local boxWidth = boxHeight / 2
                    
                    local healthPercentage = char.Humanoid.Health / char.Humanoid.MaxHealth
                    local color = Color3.fromRGB(255 - (healthPercentage * 255), healthPercentage * 255, 0)

                    items.Box.Size = Vector2.new(boxWidth, boxHeight)
                    items.Box.Position = Vector2.new(vector.X - boxWidth / 2, headVector.Y)
                    items.Box.Color = color
                    items.Box.Visible = true

                    local distance = 0
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        distance = math.floor((hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude)
                    end
                    items.Name.Text = string.format("%s [%d]", char.Name, distance)
                    items.Name.Position = Vector2.new(vector.X, headVector.Y - 20)
                    items.Name.Color = color
                    items.Name.Visible = true
                    
                    items.HealthBarOutline.From = Vector2.new(vector.X - boxWidth / 2 - 5, headVector.Y)
                    items.HealthBarOutline.To = Vector2.new(vector.X - boxWidth / 2 - 5, legVector.Y)
                    items.HealthBarOutline.Visible = true
                    
                    items.HealthBar.From = Vector2.new(vector.X - boxWidth / 2 - 5, legVector.Y - (boxHeight * healthPercentage))
                    items.HealthBar.To = Vector2.new(vector.X - boxWidth / 2 - 5, legVector.Y)
                    items.HealthBar.Color = color
                    items.HealthBar.Visible = true
                else
                    items.Box.Visible = false
                    items.Name.Visible = false
                    items.HealthBar.Visible = false
                    items.HealthBarOutline.Visible = false
                end
            end
        end
    else
        for char, items in pairs(ESP_Boxes) do
            items.Box.Visible = false
            items.Name.Visible = false
            items.HealthBar.Visible = false
            items.HealthBarOutline.Visible = false
        end
    end
end)

espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        espButton.Text = "ESP: ON"
    else
        espButton.Text = "ESP: OFF"
    end
end)


-- SILENT AIM & FOV CIRCLE LOGIC
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Visible = false
fovCircle.Radius = currentFov * 2
fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

local function isVisible(targetPart)
    local character = player.Character
    if not character or not character:FindFirstChild("Head") then return false end
    
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local rayResult = workspace:Raycast(origin, direction, raycastParams)
    return rayResult and rayResult.Instance and rayResult.Instance:IsDescendantOf(targetPart.Parent) or not rayResult
end

local function getClosestTarget()
    local closestTarget = nil
    local shortestDistance = fovCircle.Radius

    for _, char in ipairs(cachedTargets) do
        if char and char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local pos, onScreen = camera:WorldToViewportPoint(char.Head.Position)
            if onScreen then
                local magnitude = (Vector2.new(pos.X, pos.Y) - Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)).Magnitude
                if magnitude < shortestDistance then
                    if isVisible(char.Head) then
                        closestTarget = char
                        shortestDistance = magnitude
                    end
                end
            end
        end
    end
    return closestTarget
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if silentAimEnabled and not checkcaller() then
        if method == "Raycast" then
            local closestTarget = getClosestTarget()
            if closestTarget and closestTarget:FindFirstChild("Head") then
                args[2] = (closestTarget.Head.Position - args[1]).Unit * 1000
            end
        elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" or method == "FindPartOnRay" then
            local closestTarget = getClosestTarget()
            if closestTarget and closestTarget:FindFirstChild("Head") then
                local origin = args[1].Origin
                args[1] = Ray.new(origin, (closestTarget.Head.Position - origin).Unit * 1000)
            end
        end
    end

    return oldNamecall(self, unpack(args))
end)

silentAimButton.MouseButton1Click:Connect(function()
    silentAimEnabled = not silentAimEnabled
    if silentAimEnabled then
        silentAimButton.Text = "Silent Aim: ON"
        fovCircle.Visible = true
    else
        silentAimButton.Text = "Silent Aim: OFF"
        fovCircle.Visible = false
    end
end)

local flyConnection
local noclipConnection

local keys = {W = false, A = false, S = false, D = false, Q = false, E = false}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode
    if keys[key.Name] ~= nil then
        keys[key.Name] = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local key = input.KeyCode
    if keys[key.Name] ~= nil then
        keys[key.Name] = false
    end
end)

local function startFly()
    flying = true
    flyConnection = RunService.Heartbeat:Connect(function(dt)
        if not flying or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart
        local cam = workspace.CurrentCamera
        local moveDirection = Vector3.zero

        if keys.W then moveDirection += cam.CFrame.LookVector end
        if keys.S then moveDirection -= cam.CFrame.LookVector end
        if keys.A then moveDirection -= cam.CFrame.RightVector end
        if keys.D then moveDirection += cam.CFrame.RightVector end
        if keys.E then moveDirection += Vector3.new(0, 1, 0) end
        if keys.Q then moveDirection -= Vector3.new(0, 1, 0) end

        if moveDirection.Magnitude > 0 then
            hrp.Velocity = moveDirection.Unit * flySpeed
        else
            hrp.Velocity = Vector3.zero
        end
        
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
    end)
end

local function stopFly()
    flying = false
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

flyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    if flyEnabled then
        flyButton.Text = "Fly: ON"
        startFly()
    else
        flyButton.Text = "Fly: OFF"
        stopFly()
    end
end)

noclipButton.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        noclipButton.Text = "NoClip: ON"
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                local character = player.Character
                if character then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        noclipButton.Text = "NoClip: OFF"
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if silentAimEnabled then
        fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    end
end)

fovButton.MouseButton1Click:Connect(function()
    currentFov += 10
    if currentFov > 120 then
        currentFov = 70
    end
    camera.FieldOfView = currentFov
    fovButton.Text = "FOV: " .. tostring(currentFov)
    fovCircle.Radius = currentFov * 2 
end)

local function onModeSelected(mode)
    pvpButton.Visible = false
    pveButton.Visible = false
    
    if mode == "PVE" then
        title.Text = "PVE Mode Loaded"
        loadPve()
    else
        title.Text = "PVP Mode Loaded"
        loadPvp()
    end
    
    -- Ajustar posições para a interface ficar compacta e manter os botões
    flyButton.Position = UDim2.new(0.1, 0, 0, 60)
    noclipButton.Position = UDim2.new(0.1, 0, 0, 115)
    fovButton.Position = UDim2.new(0.1, 0, 0, 170)
    silentAimButton.Position = UDim2.new(0.1, 0, 0, 225)
    espButton.Position = UDim2.new(0.1, 0, 0, 280)
    
    frame.Size = UDim2.new(0, 320, 0, 340)
end

pvpButton.MouseButton1Click:Connect(function() onModeSelected("PVP") end)
pveButton.MouseButton1Click:Connect(function() onModeSelected("PVE") end)

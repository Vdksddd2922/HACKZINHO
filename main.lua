local player = game:GetService("Players").LocalPlayer
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

-- O menu sempre abrirá primeiro para escolha manual, pois os retornos automáticos foram removidos.

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModeSelectionGUI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 395)
frame.Position = UDim2.new(0.5, -160, 0.5, -197)
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

local flyEnabled = false
local flying = false
local flySpeed = 60
local noclipEnabled = false

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local bodyVelocity
local bodyGyro

local keys = {W = false, A = false, S = false, D = false, Q = false, E = false}

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode
    if keys[key.Name] ~= nil then
        keys[key.Name] = true
    end
end)

UIS.InputEnded:Connect(function(input)
    local key = input.KeyCode
    if keys[key.Name] ~= nil then
        keys[key.Name] = false
    end
end)

local function startFly()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    flying = true

    RunService.RenderStepped:Connect(function()
        if not flying then return end

        local cam = workspace.CurrentCamera
        local moveDirection = Vector3.zero

        if keys.W then
            moveDirection += cam.CFrame.LookVector
        end
        if keys.S then
            moveDirection -= cam.CFrame.LookVector
        end
        if keys.A then
            moveDirection -= cam.CFrame.RightVector
        end
        if keys.D then
            moveDirection += cam.CFrame.RightVector
        end
        if keys.E then
            moveDirection += Vector3.new(0, 1, 0)
        end
        if keys.Q then
            moveDirection -= Vector3.new(0, 1, 0)
        end

        bodyVelocity.Velocity = moveDirection * flySpeed
        bodyGyro.CFrame = cam.CFrame
    end)
end

local function stopFly()
    flying = false
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
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
    else
        noclipButton.Text = "NoClip: OFF"
    end
end)

RunService.Stepped:Connect(function()
    if noclipEnabled then
        local character = player.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

local currentFov = 70

fovButton.MouseButton1Click:Connect(function()
    currentFov += 10
    if currentFov > 120 then
        currentFov = 70
    end
    camera.FieldOfView = currentFov
    fovButton.Text = "FOV: " .. tostring(currentFov)
end)

local function setLoadingState(pvpText, pveText)
    pvpButton.AutoButtonColor = false
    pveButton.AutoButtonColor = false
    pvpButton.Text = pvpText
    pveButton.Text = pveText
    screenGui:Destroy()
end

local function onPvpSelected()
    setLoadingState("Loading...", "Please wait...")
    loadPvp()
end

local function onPveSelected()
    setLoadingState("Please wait...", "Loading...")
    loadPve()
end

pvpButton.MouseButton1Click:Connect(onPvpSelected)
pveButton.MouseButton1Click:Connect(onPveSelected)

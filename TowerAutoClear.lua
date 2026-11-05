--========================================
-- +1 GUN FORGE
-- MULTI TARGET HUB V1
-- SCRIPT BARU
--========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ENV = getgenv and getgenv() or _G

-- Hentikan script versi sebelumnya
if ENV.GunForgeMultiTargetStop then
    ENV.GunForgeMultiTargetStop()
end

local settings = {
    Enabled = false,
    AttackDelay = 0.2,
    ScanDelay = 0.4,
    MaxDistance = 250,
    AttackDistance = 18
}

local running = true
local currentTarget = nil

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "GunForgeMultiTarget"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 160)
frame.Position = UDim2.new(0.5, -140, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(20, 22, 35)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -45, 0, 40)
title.BackgroundTransparency = 1
title.Text = "GUN FORGE | MULTI TARGET"
title.TextColor3 = Color3.fromRGB(0, 255, 180)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 35)
status.Position = UDim2.new(0, 10, 0, 42)
status.BackgroundTransparency = 1
status.Text = "Status: OFF"
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 13
status.Parent = frame

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -30, 0, 45)
toggle.Position = UDim2.new(0, 15, 0, 85)
toggle.BackgroundColor3 = Color3.fromRGB(150, 40, 50)
toggle.Text = "MULTI TARGET: OFF"
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.TextSize = 15
toggle.Font = Enum.Font.GothamBold
toggle.Parent = frame

Instance.new("UICorner", toggle).CornerRadius =
    UDim.new(0, 8)

-- MINIMIZE
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0, 30, 0, 30)
minimize.Position = UDim2.new(1, -35, 0, 5)
minimize.Text = "-"
minimize.TextSize = 20
minimize.Parent = frame

local minimized = false

minimize.MouseButton1Click:Connect(function()
    minimized = not minimized

    frame.Size = minimized
        and UDim2.new(0, 280, 0, 40)
        or UDim2.new(0, 280, 0, 160)

    status.Visible = not minimized
    toggle.Visible = not minimized
    minimize.Text = minimized and "+" or "-"
end)

-- CHARACTER
local function getCharacter()
    local character = player.Character
    if not character then return end

    local humanoid =
        character:FindFirstChildOfClass("Humanoid")

    local root =
        character:FindFirstChild("HumanoidRootPart")

    return character, humanoid, root
end

-- VALIDATE TARGET
local function isAlive(model)
    if not model or not model.Parent then
        return false
    end

    local humanoid =
        model:FindFirstChildOfClass("Humanoid")

    local root =
        model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart

    return humanoid ~= nil
        and humanoid.Health > 0
        and root ~= nil
end

-- FIND MONSTER
local function findEnemy()
    local character, humanoid, root =
        getCharacter()

    if not root or not humanoid
        or humanoid.Health <= 0 then
        return nil
    end

    local nearest = nil
    local nearestDistance = settings.MaxDistance

    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Humanoid")
            and object.Health > 0 then

            local model = object.Parent

            if model
                and model:IsA("Model")
                and model ~= character
                and not Players:GetPlayerFromCharacter(model)
            then
                local enemyRoot =
                    model:FindFirstChild("HumanoidRootPart")
                    or model.PrimaryPart

                if enemyRoot then
                    local distance =
                        (root.Position - enemyRoot.Position).Magnitude

                    if distance < nearestDistance then
                        nearest = model
                        nearestDistance = distance
                    end
                end
            end
        end
    end

    return nearest
end

-- CAMERA LOCK
local cameraConnection =
    RunService:BindToRenderStep(
        "GunForgeMultiTargetAim",
        Enum.RenderPriority.Camera.Value + 1,
        function()
            if not settings.Enabled
                or not isAlive(currentTarget) then
                return
            end

            local camera = workspace.CurrentCamera

            local targetPart =
                currentTarget:FindFirstChild("Head")
                or currentTarget:FindFirstChild("HumanoidRootPart")
                or currentTarget.PrimaryPart

            if camera and targetPart then
                camera.CFrame = CFrame.lookAt(
                    camera.CFrame.Position,
                    targetPart.Position
                )
            end
        end
    )

-- ATTACK LOOP
task.spawn(function()
    while running do
        if settings.Enabled then
            local character, humanoid, root =
                getCharacter()

            if character and humanoid and root
                and humanoid.Health > 0 then

                if not isAlive(currentTarget) then
                    currentTarget = findEnemy()
                end

                if currentTarget then
                    local targetRoot =
                        currentTarget:FindFirstChild("HumanoidRootPart")
                        or currentTarget.PrimaryPart

                    if targetRoot then
                        local distance =
                            (root.Position - targetRoot.Position).Magnitude

                        status.Text = "Target: " .. currentTarget.Name

                        if distance > settings.MaxDistance then
                            currentTarget = nil
                        elseif distance > settings.AttackDistance then
                            humanoid:MoveTo(targetRoot.Position)
                        else
                            humanoid:MoveTo(root.Position)

                            local tool =
                                character:FindFirstChildOfClass("Tool")

                            if tool then
                                tool:Activate()
                            else
                                status.Text = "Equip Rocket Storm"
                            end
                        end
                    end
                else
                    status.Text = "No monsters detected"
                end
            else
                status.Text = "Waiting for character"
            end
        end

        task.wait(settings.AttackDelay)
    end
end)

-- TOGGLE
toggle.MouseButton1Click:Connect(function()
    settings.Enabled = not settings.Enabled

    if settings.Enabled then
        currentTarget = nil
        toggle.Text = "MULTI TARGET: ON"
        toggle.BackgroundColor3 =
            Color3.fromRGB(30, 160, 90)
    else
        currentTarget = nil
        toggle.Text = "MULTI TARGET: OFF"
        toggle.BackgroundColor3 =
            Color3.fromRGB(150, 40, 50)
        status.Text = "Status: OFF"
    end
end)

-- CLEANUP
ENV.GunForgeMultiTargetStop = function()
    running = false
    settings.Enabled = false
    currentTarget = nil

    RunService:UnbindFromRenderStep(
        "GunForgeMultiTargetAim"
    )

    gui:Destroy()
end

print("Gun Forge Multi Target V1 Loaded")500000500000

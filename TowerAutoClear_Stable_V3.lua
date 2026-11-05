-- +1 GUN FORGE | TOWER AUTO CLEAR V3 (reconstructed)
-- Based on the earlier working V1 + Camera Lock V2 + Minimize V3.
-- This is a reconstructed copy, not a verified byte-for-byte GitHub revision.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SETTINGS = {
    TargetDistance = 150,
    AttackDistance = 12,
    MoveInterval = 0.4
}

local env = (getgenv and getgenv()) or _G
if type(env.GunForgeTowerStop) == "function" then
    pcall(env.GunForgeTowerStop)
end

local old = playerGui:FindFirstChild("TowerAutoClearV3")
if old then old:Destroy() end
pcall(function() RunService:UnbindFromRenderStep("GunForgeTowerAim") end)

local Enabled = false
local Running = true
local currentTarget = nil

local gui = Instance.new("ScreenGui")
gui.Name = "TowerAutoClearV3"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 175)
frame.Position = UDim2.new(0.5, -140, 0.5, -85)
frame.BackgroundColor3 = Color3.fromRGB(18, 20, 32)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -45, 0, 40)
title.BackgroundTransparency = 1
title.Text = "GUN FORGE | TOWER V3"
title.TextColor3 = Color3.fromRGB(0, 255, 170)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 35)
status.Position = UDim2.new(0, 10, 0, 42)
status.BackgroundTransparency = 1
status.Text = "Status: Disabled"
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 14
status.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -30, 0, 45)
button.Position = UDim2.new(0, 15, 0, 85)
button.BackgroundColor3 = Color3.fromRGB(170, 45, 55)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "AUTO CLEAR: OFF"
button.Parent = frame
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 30, 0, 30)
minimizeButton.Position = UDim2.new(1, -35, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 50, 70)
minimizeButton.Text = "—"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.TextSize = 20
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Parent = frame
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(0, 8)

local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    frame.Size = minimized and UDim2.new(0, 280, 0, 40) or UDim2.new(0, 280, 0, 175)
    status.Visible = not minimized
    button.Visible = not minimized
    minimizeButton.Text = minimized and "+" or "—"
end)

local function getCharacter()
    local character = player.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end

local function findEnemy()
    local character, humanoid, root = getCharacter()
    if not root or not humanoid or humanoid.Health <= 0 then return nil end
    local closest = nil
    local shortest = SETTINGS.TargetDistance
    for _, object in ipairs(workspace:GetDescendants()) do
        if object:IsA("Humanoid") then
            local model = object.Parent
            if model and model:IsA("Model") and model ~= character
                and object.Health > 0 and not Players:GetPlayerFromCharacter(model) then
                local enemyRoot = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                if enemyRoot then
                    local distance = (root.Position - enemyRoot.Position).Magnitude
                    if distance < shortest then
                        shortest = distance
                        closest = model
                    end
                end
            end
        end
    end
    return closest
end

local function attackEnemy()
    local character = player.Character
    if not character then return end
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then tool:Activate() end
end

RunService:BindToRenderStep("GunForgeTowerAim", Enum.RenderPriority.Camera.Value + 1, function()
    if not Running or not Enabled or not currentTarget then return end
    local humanoid = currentTarget:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        currentTarget = nil
        return
    end
    local targetPart = currentTarget:FindFirstChild("Head")
        or currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget.PrimaryPart
    local camera = workspace.CurrentCamera
    if camera and targetPart then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
    end
end)

task.spawn(function()
    while Running do
        if Enabled then
            local character, humanoid, root = getCharacter()
            if humanoid and root and humanoid.Health > 0 then
                local enemy = findEnemy()
                currentTarget = enemy
                if enemy then
                    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
                    if enemyRoot then
                        local distance = (root.Position - enemyRoot.Position).Magnitude
                        status.Text = "Target: " .. enemy.Name
                        if distance > SETTINGS.AttackDistance then
                            humanoid:MoveTo(enemyRoot.Position)
                        else
                            humanoid:MoveTo(root.Position)
                            attackEnemy()
                        end
                    end
                else
                    status.Text = "Waiting for enemies / next floor"
                end
            else
                status.Text = "Waiting for character"
            end
        end
        task.wait(SETTINGS.MoveInterval)
    end
end)

button.MouseButton1Click:Connect(function()
    Enabled = not Enabled
    if Enabled then
        button.Text = "AUTO CLEAR: ON"
        button.BackgroundColor3 = Color3.fromRGB(30, 160, 95)
        status.Text = "Searching for enemies..."
    else
        currentTarget = nil
        button.Text = "AUTO CLEAR: OFF"
        button.BackgroundColor3 = Color3.fromRGB(170, 45, 55)
        status.Text = "Status: Disabled"
        local _, humanoid, root = getCharacter()
        if humanoid and root then humanoid:MoveTo(root.Position) end
    end
end)

env.GunForgeTowerStop = function()
    Running = false
    Enabled = false
    currentTarget = nil
    pcall(function() RunService:UnbindFromRenderStep("GunForgeTowerAim") end)
    if gui.Parent then gui:Destroy() end
end

print("Gun Forge Tower Auto Clear V3 Loaded")

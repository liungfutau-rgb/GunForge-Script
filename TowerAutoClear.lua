--====================================
-- +1 GUN FORGE
-- TOWER AUTO CLEAR V1
-- Generic NPC Combat Automation
--====================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local SETTINGS = {
    AttackDelay = 0.25,
    TargetDistance = 150,
    AttackDistance = 12,
    MoveInterval = 0.4
}

local Enabled = false
local Running = true
local currentTarget = nil

-- REMOVE OLD GUI
local oldGui = player.PlayerGui:FindFirstChild("TowerAutoClearV1")

if oldGui then
    oldGui:Destroy()
end

-- CREATE GUI
local gui = Instance.new("ScreenGui")
gui.Name = "TowerAutoClearV1"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 175)
frame.Position = UDim2.new(0.5, -140, 0.5, -85)
frame.BackgroundColor3 = Color3.fromRGB(18, 20, 32)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "GUN FORGE | TOWER V1"
title.TextColor3 = Color3.fromRGB(0, 255, 170)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.Parent = frame

-- STATUS
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 35)
status.Position = UDim2.new(0, 10, 0, 42)
status.BackgroundTransparency = 1
status.Text = "Status: Disabled"
status.TextColor3 = Color3.new(1, 1, 1)
status.TextSize = 14
status.Parent = frame

-- BUTTON
local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -30, 0, 45)
button.Position = UDim2.new(0, 15, 0, 85)
button.BackgroundColor3 = Color3.fromRGB(170, 45, 55)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "AUTO CLEAR: OFF"
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = button

local function getCharacter()
    local character = player.Character

    if not character then
        return nil, nil, nil
    end

    local humanoid =
        character:FindFirstChildOfClass("Humanoid")

    local root =
        character:FindFirstChild("HumanoidRootPart")

    return character, humanoid, root
end

-- FIND NEAREST NPC
local function findEnemy()

    local character, humanoid, root =
        getCharacter()

    if not root or not humanoid then
        return nil
    end

    if humanoid.Health <= 0 then
        return nil
    end

    local closest = nil
    local shortest = SETTINGS.TargetDistance

    for _, object in ipairs(workspace:GetDescendants()) do

        if object:IsA("Humanoid") then

            local model = object.Parent

            if model
                and model:IsA("Model")
                and model ~= character
                and object.Health > 0
                and not Players:GetPlayerFromCharacter(model)
            then

                local enemyRoot =
                    model:FindFirstChild("HumanoidRootPart")
                    or model.PrimaryPart

                if enemyRoot then

                    local distance =
                        (root.Position - enemyRoot.Position).Magnitude

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

-- ATTACK USING EQUIPPED TOOL
local function attackEnemy()

    local character = player.Character

    if not character then
        return
    end

    local tool =
        character:FindFirstChildOfClass("Tool")

    if tool then
        tool:Activate()
    end
end
--====================================
-- CAMERA LOCK V2
--====================================

RunService:BindToRenderStep(
    "GunForgeTowerAim",
    Enum.RenderPriority.Camera.Value + 1,
    function()

        if not Enabled or not currentTarget then
            return
        end

        local humanoid =
            currentTarget:FindFirstChildOfClass("Humanoid")

        if not humanoid or humanoid.Health <= 0 then
            currentTarget = nil
            return
        end

        local targetPart =
            currentTarget:FindFirstChild("Head")
            or currentTarget:FindFirstChild("HumanoidRootPart")
            or currentTarget.PrimaryPart

        local camera = workspace.CurrentCamera

        if targetPart and camera then

            local cameraPosition = camera.CFrame.Position

            camera.CFrame = CFrame.lookAt(
                cameraPosition,
                targetPart.Position
            )

        end
    end
)

-- AUTO CLEAR LOOP
task.spawn(function()

    while Running do

        if Enabled then

            local character, humanoid, root =
                getCharacter()

            if humanoid and root and humanoid.Health > 0 then

                local enemy = findEnemy()
                currentTarget = enemy
                if enemy then

                    local enemyRoot =
                        enemy:FindFirstChild("HumanoidRootPart")
                        or enemy.PrimaryPart

                    if enemyRoot then

                        local distance =
                            (root.Position - enemyRoot.Position).Magnitude

                        status.Text = "Target: " .. enemy.Name

                        if distance > SETTINGS.AttackDistance then

                            humanoid:MoveTo(
                                enemyRoot.Position
                            )

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

-- BUTTON FUNCTION
button.MouseButton1Click:Connect(function()

    Enabled = not Enabled

    if Enabled then

        button.Text = "AUTO CLEAR: ON"
        button.BackgroundColor3 =
            Color3.fromRGB(30, 160, 95)

        status.Text = "Searching for enemies..."

    else

        button.Text = "AUTO CLEAR: OFF"
        button.BackgroundColor3 =
            Color3.fromRGB(170, 45, 55)

        status.Text = "Status: Disabled"

        local _, humanoid, root = getCharacter()

        if humanoid and root then
            humanoid:MoveTo(root.Position)
        end

    end

end)

print("Gun Forge Tower Auto Clear V1 Loaded")

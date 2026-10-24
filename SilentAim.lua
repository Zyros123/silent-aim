-- Aim Assist Duels (con camara)
-- Al disparar apunta al enemigo VISIBLE | U = ON/OFF | Sin menu

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local enabled = true
local FOV = 320
local MAX_DIST = 500

print("Loaded! | Aim Assist Duels | U = ON/OFF")

local function isEnemy(plr)
    if not plr or plr == LocalPlayer then return false end
    if LocalPlayer.Team and plr.Team then
        return plr.Team ~= LocalPlayer.Team
    end
    if LocalPlayer.TeamColor and plr.TeamColor then
        return plr.TeamColor ~= LocalPlayer.TeamColor
    end
    return true
end

local function hasLineOfSight(fromPos, toPart)
    local direction = toPart.Position - fromPos
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {}
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then table.insert(filter, p.Character) end
    end
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = true
    local hit = Workspace:Raycast(fromPos, direction, params)
    if not hit then return true end
    return (hit.Position - fromPos).Magnitude >= direction.Magnitude - 3
end

local function getBestTarget()
    if not enabled then return nil end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

    local myRoot = char.HumanoidRootPart
    local origin = Camera.CFrame.Position
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local best, bestDist = nil, FOV

    for _, plr in pairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character then
            local enemy = plr.Character
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local head = enemy:FindFirstChild("Head")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            local aim = head or root

            if hum and hum.Health > 0 and aim and root then
                if (root.Position - myRoot.Position).Magnitude <= MAX_DIST then
                    local sp, on = Camera:WorldToViewportPoint(aim.Position)
                    if on and sp.Z > 0 then
                        local d = (mousePos - Vector2.new(sp.X, sp.Y)).Magnitude
                        if d < bestDist and hasLineOfSight(origin, aim) then
                            bestDist = d
                            best = aim
                        end
                    end
                end
            end
        end
    end
    return best
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.U then
        enabled = not enabled
        print(enabled and "Aim Assist: ON" or "Aim Assist: OFF")
    end
end)

local holding = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holding = false
    end
end)

-- Al mantener clic: camara al enemigo visible (asi la bala pega)
RunService.RenderStepped:Connect(function()
    if not enabled or not holding then return end
    local t = getBestTarget()
    if t then
        pcall(function()
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
        end)
    end
end)

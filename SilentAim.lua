-- Silent Aim Visible (sin menu)
-- Solo enemigos visibles (no paredes)
-- Tecla U = activar / desactivar

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local enabled = true
local FOV = 180
local MAX_DIST = 400

print("Loaded! | Silent Aim Visible | U = ON/OFF")

local function isEnemy(plr)
    if not plr or plr == LocalPlayer then return false end
    if LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then
        return false
    end
    if LocalPlayer.TeamColor and plr.TeamColor and LocalPlayer.TeamColor == plr.TeamColor then
        return false
    end
    return true
end

local function hasLineOfSight(fromPos, toPart)
    local direction = (toPart.Position - fromPos)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {LocalPlayer.Character}
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character then
            table.insert(filter, p.Character)
        end
    end
    rayParams.FilterDescendantsInstances = filter
    rayParams.IgnoreWater = true

    local result = Workspace:Raycast(fromPos, direction, rayParams)
    if not result then
        return true
    end
    local distToTarget = direction.Magnitude
    local distToHit = (result.Position - fromPos).Magnitude
    return distToHit >= distToTarget - 2
end

local function getBestTarget()
    if not enabled then return nil end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myRoot = char.HumanoidRootPart
    local origin = Camera.CFrame.Position
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local best = nil
    local bestDist = FOV

    for _, plr in pairs(Players:GetPlayers()) do
        if isEnemy(plr) and plr.Character then
            local enemy = plr.Character
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local head = enemy:FindFirstChild("Head")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            local aimPart = head or root

            if hum and hum.Health > 0 and aimPart and root then
                local dist3d = (root.Position - myRoot.Position).Magnitude
                if dist3d <= MAX_DIST then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                    if onScreen and screenPos.Z > 0 then
                        local d = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if d < bestDist then
                            if hasLineOfSight(origin, aimPart) then
                                bestDist = d
                                best = aimPart
                            end
                        end
                    end
                end
            end
        end
    end

    return best
end

-- Tecla U = toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.U then
        enabled = not enabled
        if enabled then
            print("Silent Aim: ON")
        else
            print("Silent Aim: OFF")
        end
    end
end)

pcall(function()
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if not checkcaller() and self == Mouse then
            if key == "Hit" or key == "Target" then
                local target = getBestTarget()
                if target then
                    if key == "Hit" then
                        return target.CFrame
                    end
                    if key == "Target" then
                        return target
                    end
                end
            end
        end
        return oldIndex(self, key)
    end)
end)

pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and method == "FindPartOnRayWithIgnoreList" then
            local args = {...}
            local target = getBestTarget()
            if target and args[1] then
                local origin = args[1].Origin
                local newDir = (target.Position - origin).Unit * args[1].Direction.Magnitude
                args[1] = Ray.new(origin, newDir)
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
end)

-- Silent Aim Visible para Duels (Asesinos VS Sheriffs)
-- Solo enemigos visibles | Tecla U = ON/OFF | Sin menu

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

local enabled = true
local FOV = 250
local MAX_DIST = 500

print("Loaded! | Silent Aim Duels | U = ON/OFF")

local function isEnemy(plr)
    if not plr or plr == LocalPlayer then return false end
    -- Teams de duelos
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

-- Tecla U
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.U then
        enabled = not enabled
        print(enabled and "Silent Aim: ON" or "Silent Aim: OFF")
    end
end)

-- 1) Mouse.Hit / Mouse.Target / Mouse.UnitRay
pcall(function()
    local old
    old = hookmetamethod(game, "__index", function(self, key)
        if not checkcaller() and self == Mouse and enabled then
            local t = getBestTarget()
            if t then
                if key == "Hit" then
                    return t.CFrame
                elseif key == "Target" then
                    return t
                elseif key == "UnitRay" then
                    local origin = Camera.CFrame.Position
                    return Ray.new(origin, (t.Position - origin).Unit)
                end
            end
        end
        return old(self, key)
    end)
end)

-- 2) Raycasts clasicos del juego
pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and enabled then
            if method == "FindPartOnRayWithIgnoreList"
                or method == "FindPartOnRay"
                or method == "FindPartOnRayWithWhitelist" then
                local args = {...}
                local t = getBestTarget()
                if t and typeof(args[1]) == "Ray" then
                    local origin = args[1].Origin
                    local len = args[1].Direction.Magnitude
                    if len < 1 then len = 1000 end
                    args[1] = Ray.new(origin, (t.Position - origin).Unit * len)
                    return old(self, unpack(args))
                end
            end
            if method == "Raycast" and self == Workspace then
                local args = {...}
                local t = getBestTarget()
                if t and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                    local origin = args[1]
                    local len = args[2].Magnitude
                    if len < 1 then len = 1000 end
                    args[2] = (t.Position - origin).Unit * len
                    return old(self, unpack(args))
                end
            end
        end
        return old(self, ...)
    end)
end)

-- 3) Ayuda extra: al hacer clic, mueve un poco la camara al enemigo visible
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not enabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local t = getBestTarget()
        if t then
            pcall(function()
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
            end)
        end
    end
end)

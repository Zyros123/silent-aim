-- SILENT AIM puro: disparas y pega al enemigo visible. No mueve la cámara.
-- Solo redirige el raycast del disparo. Click izquierdo = disparar.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
-- ====== CONFIG ======
local FOV = 400              -- radio en píxeles (solo agarra enemigos dentro de esto)
local HITBOX_SIZE = 10       -- agranda hitbox para asegurar el impacto
local VISIBLE_ONLY = true    -- true = solo enemigos visibles en pantalla
-- ====================
-- Saber si está vivo
local function isAlive(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end
-- Obtener enemigos (jugadores + NPCs)
local function getTargets()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isAlive(plr.Character) then
            table.insert(list, plr.Character)
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and isAlive(obj) then
            if not Players:GetPlayerFromCharacter(obj) then
                table.insert(list, obj)
            end
        end
    end
    return list
end
-- Enemigo más cercano al centro de la pantalla (o al cursor)
local function getClosest()
    local closest, shortest = nil, FOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, model in ipairs(getTargets()) do
        local part = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
        if part then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen or not VISIBLE_ONLY then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = part
                end
            end
        end
    end
    return closest
end
-- Hitbox expander
RunService.Heartbeat:Connect(function()
    for _, model in ipairs(getTargets()) do
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                if part.Size.Magnitude < HITBOX_SIZE then
                    part.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
                    part.CanCollide = false
                    part.Transparency = 0.7
                end
            end
        end
    end
end)
-- HOOK: intercepta el raycast del disparo y lo redirige al enemigo
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
        local target = getClosest()
        if target then
            if method == "Raycast" and args[1] then
                local ray = args[1]
                local origin = ray.Origin
                local dir = (target.Position - origin)
                args[1] = Ray.new(origin, dir.Unit * dir.Magnitude * 2)
            elseif method:find("FindPartOnRay") then
                local ray = args[1]
                if ray then
                    local origin = ray.Origin
                    local dir = (target.Position - origin)
                    args[1] = Ray.new(origin, dir.Unit * dir.Magnitude * 2)
                end
            end
        end
    end
    
    return oldNamecall(self, table.unpack(args))
end)
setreadonly(mt, true)
print("[SilentAim] Listo. Dispara y pega automaticamente al enemigo visible.")

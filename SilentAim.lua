loadstring([[
-- Tiger Bot Duels (Triggerbot)
-- Dispara solo cuando apuntas al enemigo | U = ON/OFF

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local enabled = true
local DELAY = 0.06
local lastFire = 0

print("Loaded! | Tiger Bot Duels | U = ON/OFF")

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

local function isKnife(tool)
    if not tool then return false end
    local n = string.lower(tool.Name)
    return string.find(n, "knife") or string.find(n, "cuchillo") or string.find(n, "blade")
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.U then
        enabled = not enabled
        print(enabled and "Tiger Bot: ON" or "Tiger Bot: OFF")
    end
end)

while true do
    task.wait(0.03)
    if not enabled then continue end
    if tick() - lastFire < DELAY then continue end

    local char = LocalPlayer.Character
    if not char then continue end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then continue end
    if isKnife(tool) then continue end -- cuchillo: no auto clic

    local target = Mouse.Target
    if not target then continue end

    local model = target.Parent
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    if not hum and model and model.Parent then
        model = model.Parent
        hum = model:FindFirstChildOfClass("Humanoid")
    end

    if hum and hum.Health > 0 and model ~= char then
        local plr = Players:GetPlayerFromCharacter(model)
        if plr and isEnemy(plr) then
            lastFire = tick()
            pcall(mouse1click)
        end
    end
end
]])()

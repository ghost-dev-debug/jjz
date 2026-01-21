-- PlaceId Check
if game.PlaceId ~= 128451689942376 then return end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Damage Remote
local DamageRemote = ReplicatedStorage
    .NetworkComm
    .CombatService
    .DamageCharacter_Method

-- NPC Path
local NPCFolder = ReplicatedStorage
    .Assets
    .Models
    .Characters
    .Humanoid
    .NPCs

-- Load Mercury
local Mercury = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"
))()

-- GUI
local GUI = Mercury:Create{
    Name = "Ghost Hub | [⚡] Jujutsu: Zero",
    Size = UDim2.fromOffset(600, 400),
    Theme = Mercury.Themes.Dark
}

-- ================= VARIABLES =================
local SelectedNPC = "Bully1"
local AutoKill = false

-- Damage Arg Cache
local CachedArgs = nil
local LastHitTime = 0
local WaitingForNewHit = true

-- ================= TAB =================
local FarmTab = GUI:Tab{
    Name = "Farm",
    Icon = "rbxassetid://4483345998"
}

FarmTab:Label{
    Text = "Hit NPC once manually to capture damage data"
}

-- ================= CAPTURE DAMAGE ARGS =================
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if self == DamageRemote and method == "InvokeServer" then
        CachedArgs = args
        LastHitTime = tick()
        WaitingForNewHit = false
        warn("✅ Damage args captured / refreshed")
    end

    return old(self, ...)
end)

setreadonly(mt, true)

-- ================= AUTO KILL (SERVER + AUTO REFRESH) =================
FarmTab:Toggle{
    Name = "Auto Kill (Server + Auto Refresh)",
    StartingState = false,
    Callback = function(v)
        AutoKill = v
        task.spawn(function()
            while AutoKill do
                -- If no valid args → wait for manual hit
                if not CachedArgs or WaitingForNewHit then
                    task.wait(0.5)
                    continue
                end

                for _,npc in ipairs(NPCFolder:GetChildren()) do
                    if npc.Name == SelectedNPC then
                        local humanoid = npc:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            local success = pcall(function()
                                DamageRemote:InvokeServer(
                                    CachedArgs[1],
                                    CachedArgs[2],
                                    CachedArgs[3]
                                )
                            end)

                            -- If server rejected → force refresh
                            if not success then
                                warn("⚠️ Damage failed, waiting for new hit")
                                WaitingForNewHit = true
                            end
                        end
                    end
                end

                -- If args too old (weapon/skill change safeguard)
                if tick() - LastHitTime > 20 then
                    warn("🔄 Damage args expired, hit NPC again")
                    WaitingForNewHit = true
                end

                task.wait(0.25)
            end
        end)
    end
}

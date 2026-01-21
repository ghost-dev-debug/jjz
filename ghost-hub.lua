--==================================================
-- PlaceId Check
--==================================================
if game.PlaceId ~= 128451689942376 then return end

--==================================================
-- Services
--==================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- Quest Services
--==================================================
local QuestService = ReplicatedStorage.NetworkComm.QuestService
local AcceptQuest = QuestService.AcceptQuest_Method
local QuestFinishedSignal = QuestService.QuestFinished_Signal

--==================================================
-- Damage Remote
--==================================================
local DamageRemote = ReplicatedStorage
    .NetworkComm
    .CombatService
    .DamageCharacter_Method

--==================================================
-- NPC Path
--==================================================
local NPCFolder = ReplicatedStorage
    .Assets
    .Models
    .Characters
    .Humanoid
    .NPCs

--==================================================
-- Load Mercury
--==================================================
local Mercury = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"
))()

--==================================================
-- GUI
--==================================================
local GUI = Mercury:Create{
    Name = "Ghost Hub | [⚡] Jujutsu: Zero",
    Size = UDim2.fromOffset(600, 400),
    Theme = Mercury.Themes.Dark
}

--==================================================
-- Variables
--==================================================
local SelectedQuest = "Bully1"

local AutoQuest = false
local AutoKill = false

-- Quest state
local QuestCompleted = true

-- Damage cache
local CachedArgs = nil
local LastHitTime = 0
local WaitingForNewHit = true

--==================================================
-- Tab
--==================================================
local FarmTab = GUI:Tab{
    Name = "Farm",
    Icon = "rbxassetid://4483345998"
}

--==================================================
-- Info Label
--==================================================
FarmTab:Label{
    Text = "Hit Bully1 ONCE manually to capture damage data"
}

--==================================================
-- Dropdown
--==================================================
FarmTab:Dropdown{
    Name = "Select Quest",
    StartingText = "Bully1",
    Items = {"Bully1"},
    Callback = function(v)
        SelectedQuest = v
    end
}

--==================================================
-- Quest Finished Listener (STABLE)
--==================================================
QuestFinishedSignal.OnClientEvent:Connect(function(questName)
    if questName == SelectedQuest then
        QuestCompleted = true
    end
end)

--==================================================
-- Auto Quest (FIXED, NO ABORT)
--==================================================
FarmTab:Toggle{
    Name = "Auto Quest",
    StartingState = false,
    Callback = function(v)
        AutoQuest = v
        task.spawn(function()
            while AutoQuest do
                if QuestCompleted then
                    QuestCompleted = false
                    pcall(function()
                        AcceptQuest:InvokeServer(SelectedQuest)
                    end)
                end
                task.wait(1)
            end
        end)
    end
}

--==================================================
-- Capture Damage Args (AUTO REFRESH)
--==================================================
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

--==================================================
-- Auto Kill (SERVER-SIDE + FAILSAFE)
--==================================================
FarmTab:Toggle{
    Name = "Auto Kill (Server Damage)",
    StartingState = false,
    Callback = function(v)
        AutoKill = v
        task.spawn(function()
            while AutoKill do
                -- No valid args → wait for manual hit
                if not CachedArgs or WaitingForNewHit then
                    task.wait(0.4)
                    continue
                end

                for _,npc in ipairs(NPCFolder:GetChildren()) do
                    if npc.Name == SelectedQuest then
                        local humanoid = npc:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            local success = pcall(function()
                                DamageRemote:InvokeServer(
                                    CachedArgs[1],
                                    CachedArgs[2],
                                    CachedArgs[3]
                                )
                            end)

                            if not success then
                                warn("⚠️ Damage failed, waiting for new hit")
                                WaitingForNewHit = true
                            end
                        end
                    end
                end

                -- Auto expire protection (weapon / skill change)
                if tick() - LastHitTime > 20 then
                    warn("🔄 Damage args expired, hit NPC again")
                    WaitingForNewHit = true
                end

                task.wait(0.25)
            end
        end)
    end
}

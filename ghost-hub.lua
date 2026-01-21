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
    Size = UDim2.fromOffset(650, 450),
    Theme = Mercury.Themes.Dark
}

--==================================================
-- Variables
--==================================================
local SelectedQuest = "Bully1"

local AutoQuest = false
local AutoKill = false
local AutoRefresh = true -- future use

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
-- SECTION: QUEST
--==================================================
FarmTab:Label{ Text = "🧠 Quest Settings" }

FarmTab:Dropdown{
    Name = "Select Quest / NPC",
    StartingText = "Bully1",
    Items = {
        "Bully1"
        -- "Bully2",
        -- "Bully3"
    },
    Callback = function(v)
        SelectedQuest = v
    end
}

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
-- Quest Finish Listener
--==================================================
QuestFinishedSignal.OnClientEvent:Connect(function(questName)
    if questName == SelectedQuest then
        QuestCompleted = true
    end
end)

--==================================================
-- SECTION: COMBAT
--==================================================
FarmTab:Label{ Text = "⚔️ Combat / Kill Settings" }

FarmTab:Toggle{
    Name = "Auto Kill (Server Damage)",
    StartingState = false,
    Callback = function(v)
        AutoKill = v
        task.spawn(function()
            while AutoKill do
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
                                WaitingForNewHit = true
                            end
                        end
                    end
                end

                if tick() - LastHitTime > 20 then
                    WaitingForNewHit = true
                end

                task.wait(0.25)
            end
        end)
    end
}

FarmTab:Toggle{
    Name = "Auto Refresh Damage (recommended)",
    StartingState = true,
    Callback = function(v)
        AutoRefresh = v
    end
}

FarmTab:Label{
    Text = "ℹ️ Hit NPC ONCE manually to capture damage data"
}

--==================================================
-- Damage Arg Capture
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

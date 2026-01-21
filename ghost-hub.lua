--=============================================
-- PlaceId Check
--=============================================
if game.PlaceId ~= 128451689942376 then return end

--=============================================
-- Services
--=============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

--=============================================
-- Quest Services
--=============================================
local QuestService = ReplicatedStorage.NetworkComm.QuestService
local AcceptQuest = QuestService.AcceptQuest_Method
local QuestFinishedSignal = QuestService.QuestFinished_Signal

--=============================================
-- Damage Remote
--=============================================
local DamageRemote = ReplicatedStorage
    .NetworkComm
    .CombatService
    .DamageCharacter_Method

--=============================================
-- NPC Path
--=============================================
local NPCFolder = ReplicatedStorage
    .Assets
    .Models
    .Characters
    .Humanoid
    .NPCs

--=============================================
-- Load Mercury GUI
--=============================================
local Mercury = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"
))()

local GUI = Mercury:Create{
    Name = "Ghost Hub | [⚡] Jujutsu: Zero",
    Size = UDim2.fromOffset(650, 450),
    Theme = Mercury.Themes.Dark
}

--=============================================
-- Variables
--=============================================
local SelectedQuest = "Bully1"
local AutoQuest = false
local AutoKill = false
local QuestCompleted = true

--=============================================
-- Farm Tab
--=============================================
local FarmTab = GUI:Tab{
    Name = "Farm",
    Icon = "rbxassetid://4483345998"
}

--=============================================
-- Quest Section
--=============================================
FarmTab:Label{ Text = "🧠 Quest Settings" }

FarmTab:Dropdown{
    Name = "Select Quest / NPC",
    StartingText = "Bully1",
    Items = {"Bully1"},
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

-- Quest Finished Listener
QuestFinishedSignal.OnClientEvent:Connect(function(questName)
    if questName == SelectedQuest then
        QuestCompleted = true
    end
end)

--=============================================
-- Combat Section
--=============================================
FarmTab:Label{ Text = "⚔️ Combat / AutoKill Settings" }

FarmTab:Toggle{
    Name = "Auto Kill (AFK Server Damage)",
    StartingState = false,
    Callback = function(v)
        AutoKill = v
        task.spawn(function()
            while AutoKill do
                for _, npc in ipairs(NPCFolder:GetChildren()) do
                    if npc.Name == SelectedQuest then
                        local humanoid = npc:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 then
                            pcall(function()
                                -- Dynamische AFK Damage Args
                                local args = {
                                    [1] = {Target = humanoid}, -- Target Humanoid
                                    [2] = true,                -- Valid hit
                                    [3] = {Damage = 9999}      -- Damage hoch genug für Instant Kill
                                }
                                DamageRemote:InvokeServer(args[1], args[2], args[3])
                            end)
                        end
                    end
                end
                task.wait(0.25)
            end
        end)
    end
}

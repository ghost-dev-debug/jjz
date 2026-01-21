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
-- Remotes
--==================================================
local QuestService = ReplicatedStorage.NetworkComm.QuestService
local AcceptQuest = QuestService.AcceptQuest_Method
local QuestFinishedSignal = QuestService.QuestFinished_Signal

local DamageRemote = ReplicatedStorage
    .NetworkComm
    .CombatService
    .DamageCharacter_Method

--==================================================
-- NPC Folder
--==================================================
local NPCFolder = ReplicatedStorage
    .Assets
    .Models
    .Characters
    .Humanoid
    .NPCs

--==================================================
-- Mercury GUI
--==================================================
local Mercury = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"
))()

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
local QuestReady = true

-- Damage Cache
local CachedArgs = nil

--==================================================
-- Hook Damage (CAPTURE REAL SERVER ARGS)
--==================================================
local mt = getrawmetatable(game)
setreadonly(mt,false)

local old = mt.__namecall
mt.__namecall = newcclosure(function(self,...)
    local args = {...}
    local method = getnamecallmethod()

    if method == "InvokeServer"
       and self == DamageRemote
       and not CachedArgs then

        CachedArgs = args
        warn("✅ Damage Args gecached – AutoKill bereit")
    end

    return old(self,...)
end)

setreadonly(mt,true)

--==================================================
-- GUI TAB
--==================================================
local FarmTab = GUI:Tab{
    Name = "Farm",
    Icon = "rbxassetid://4483345998"
}

FarmTab:Dropdown{
    Name = "Select Quest",
    StartingText = "Bully1",
    Items = {"Bully1"},
    Callback = function(v)
        SelectedQuest = v
    end
}

--==================================================
-- AUTO QUEST (STABIL)
--==================================================
FarmTab:Toggle{
    Name = "Auto Quest",
    StartingState = false,
    Callback = function(v)
        AutoQuest = v
        task.spawn(function()
            while AutoQuest do
                if QuestReady then
                    QuestReady = false
                    pcall(function()
                        AcceptQuest:InvokeServer(SelectedQuest)
                    end)
                end
                task.wait(1)
            end
        end)
    end
}

QuestFinishedSignal.OnClientEvent:Connect(function(name)
    if name == SelectedQuest then
        QuestReady = true
    end
end)

--==================================================
-- AUTO KILL (AFTER 1 HIT)
--==================================================
FarmTab:Toggle{
    Name = "Auto Kill (AFK Server Damage)",
    StartingState = false,
    Callback = function(v)
        AutoKill = v
        task.spawn(function()
            while AutoKill do
                if CachedArgs then
                    for _,npc in ipairs(NPCFolder:GetChildren()) do
                        if npc.Name == SelectedQuest then
                            local hum = npc:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                -- Reuse REAL server-validated args
                                CachedArgs[1].Target = hum
                                pcall(function()
                                    DamageRemote:InvokeServer(
                                        CachedArgs[1],
                                        CachedArgs[2],
                                        CachedArgs[3]
                                    )
                                end)
                            end
                        end
                    end
                end
                task.wait(0.25)
            end
        end)
    end
}

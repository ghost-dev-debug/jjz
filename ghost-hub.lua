--// PlaceId Check
if game.PlaceId ~= 123821081589134 then return end

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

--// Mercury GUI
local Mercury = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deeeity/mercury-lib/master/src.lua"
))()

local GUI = Mercury:Create{
    Name = "Ghost Hub | Auto Break",
    Size = UDim2.fromOffset(600, 400),
    Theme = Mercury.Themes.Dark
}

local FarmTab = GUI:Tab{
    Name = "Auto Farm",
    Icon = "rbxassetid://4483345998"
}

--// Break Remote
local BreakEvent = ReplicatedStorage.Remotes.Break

--// Settings
local AutoBreak = false
local LoopDelay = 0.2 -- Default Speed

--// Speed Slider
FarmTab:Slider{
    Name = "Break Speed",
    Default = 20,        -- UI Wert
    Min = 1,
    Max = 60,
    Callback = function(value)
        -- kleiner Wert = schneller
        LoopDelay = math.clamp(1 / value, 0.02, 1)
    end
}

--// Auto Break Toggle
FarmTab:Toggle{
    Name = "Auto Break",
    StartingState = false,
    Callback = function(state)
        AutoBreak = state
        task.spawn(function()
            while AutoBreak do
                local char = Player.Character
                local ragdoll = char
                    and char:FindFirstChild("Ragdoll")
                    and char.Ragdoll:FindFirstChild("Default")

                if ragdoll then
                    firesignal(BreakEvent.OnClientEvent, ragdoll.Head, "Head", 1, 8, false, false)
                    firesignal(BreakEvent.OnClientEvent, ragdoll["Left Arm"], "Left Arm", 1, 3, false, false)
                    firesignal(BreakEvent.OnClientEvent, ragdoll["Right Arm"], "Right Arm", 1, 3, false, false)
                    firesignal(BreakEvent.OnClientEvent, ragdoll.Torso, "Torso", 1, 5, false, false)
                    firesignal(BreakEvent.OnClientEvent, ragdoll["Right Leg"], "Right Leg", 1, 3, false, false)
                    firesignal(BreakEvent.OnClientEvent, ragdoll["Left Leg"], "Left Leg", 1, 3, false, false)
                end

                task.wait(LoopDelay)
            end
        end)
    end
}

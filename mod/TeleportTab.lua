-- TeleportTab.lua - External Teleport Tab for Draconic Hub
-- Modified to work with your existing script structure

-- Services
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Variables
local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId

-- Helper functions
local function createNotification(title, content, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = duration or 5
    })
end

-- Teleport Module
local TeleportModule = (function()
    -- MAP DATABASE
    local mapSpots = {
        ["DesertBus"] = {
            Far = CFrame.new(1350.6390380859375, -66.57595825195312, 913.889404296875, 0.08861260116100311, 0,
                0.9960662126541138, 0, 1.0000001192092896, 0, -0.9960662126541138, 0, 0.08861260116100311),
            Sky = CFrame.new(29.76473045349121, 69.4240493774414, -178.1037139892578, 0.6581460237503052, 0,
                0.7528902888298035, 0, 1, 0, -0.752890408039093, 0, 0.6581459641456604)
        },
        -- Add more maps as needed
    }

    local function validateCharacter()
        local char = player.Character
        if not char then
            createNotification("Teleport Error", "Character not found!", 2)
            return nil, nil
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            createNotification("Teleport Error", "HumanoidRootPart not found!", 2)
            return nil, nil
        end

        return char, hrp
    end

    local function safeTeleport(hrp, targetPosition, filterInstances)
        filterInstances = filterInstances or {}
        local teleportPos = targetPosition + Vector3.new(0, 5, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = filterInstances
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

        local ray = workspace:Raycast(teleportPos, Vector3.new(0, -10, 0), raycastParams)
        if ray then
            teleportPos = ray.Position + Vector3.new(0, 3, 0)
        end

        hrp.CFrame = CFrame.new(teleportPos)
        return true
    end

    local function getCurrentMap()
        local gameFolder = workspace:FindFirstChild("Game")
        if gameFolder then
            local mapFolder = gameFolder:FindFirstChild("Map")
            if mapFolder then
                local mapName = mapFolder:GetAttribute("MapName")
                if mapName and mapName ~= "" then
                    return mapName
                end
            end
        end
        return "Unknown"
    end

    local function placeTeleporter(cframe)
        if not cframe then
            createNotification("Teleport Error", "Invalid teleporter position!", 2)
            return false
        end

        task.spawn(function()
            local args = {
                [1] = 0,
                [2] = 16
            }
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("ToolAction"):FireServer(unpack(args))

            task.wait(1)

            local args2 = {
                [1] = 1,
                [2] = {
                    [1] = "Teleporter",
                    [2] = cframe
                }
            }
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("ToolAction"):FireServer(unpack(args2))

            task.wait(1)

            local args3 = {
                [1] = 0,
                [2] = 15
            }
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("ToolAction"):FireServer(unpack(args3))

            createNotification("Teleporter Placed", "Teleporter successfully placed!", 2)
        end)

        return true
    end

    return {
        GetCurrentMap = getCurrentMap,
        HasMapData = function(mapName)
            return mapSpots[mapName] ~= nil
        end,
        GetMapSpot = function(mapName, spotType)
            if not mapSpots[mapName] then return nil end
            return mapSpots[mapName][spotType]
        end,
        TeleportPlayer = function(spotType)
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end
            local mapName = getCurrentMap()

            if mapName == "Unknown" then
                createNotification("Teleport Error", "Could not detect map name!", 2)
                return false
            end

            if not mapSpots[mapName] then
                createNotification("Teleport Error", "Map '" .. mapName .. "' not in database!", 3)
                return false
            end

            local cframe = mapSpots[mapName][spotType]
            if not cframe then
                createNotification("Teleport Error", "No " .. spotType .. " spot found for " .. mapName, 3)
                return false
            end

            createNotification("Teleporting", "Teleporting to " .. spotType .. " for " .. mapName .. "...", 2)
            return safeTeleport(hrp, cframe.Position, { char })
        end,
        PlaceTeleporter = function(spotType)
            local mapName = getCurrentMap()

            if mapName == "Unknown" then
                createNotification("Teleport Error", "Could not detect map name!", 2)
                return false
            end

            if not mapSpots[mapName] then
                createNotification("Teleport Error", "Map '" .. mapName .. "' not in database!", 3)
                return false
            end

            local cframe = mapSpots[mapName][spotType]
            if not cframe then
                createNotification("Teleport Error", "No " .. spotType .. " spot found for " .. mapName, 3)
                return false
            end

            createNotification("Placing Teleporter", "Placing " .. spotType .. " teleporter for " .. mapName .. "...", 2)
            return placeTeleporter(cframe)
        end
    }
end)()

-- Main function to create Teleport Tab
local function CreateTeleportTab(Window, Fluent)
    local TeleportTab = Window:AddTab({ Title = "Teleport", Icon = "navigation" })
    
    -- Auto Place Teleporter Section
    local autoPlaceTeleporterEnabled = false
    local autoPlaceTeleporterType = "Far"
    
    -- Auto Place System
    local gameStats = workspace:WaitForChild("Game"):WaitForChild("Stats")
    local lastLoadProgress = 0
    local isProcessingMapChange = false
    
    gameStats:GetAttributeChangedSignal("RoundStarted"):Connect(function()
        if not autoPlaceTeleporterEnabled then return end
        local roundStarted = gameStats:GetAttribute("RoundStarted")
        local roundsCompleted = gameStats:GetAttribute("RoundsCompleted") or 0
        if not roundStarted and roundsCompleted < 3 then
            task.spawn(function()
                task.wait(3)
                local character = player.Character or player.CharacterAdded:Wait()
                character:WaitForChild("HumanoidRootPart")
                task.wait(1)
                TeleportModule.PlaceTeleporter(autoPlaceTeleporterType)
                createNotification("Auto Place", "Round " .. roundsCompleted .. " done", 2)
            end)
        end
    end)
    
    -- UI Elements
    TeleportTab:AddSection("Auto Place Teleporter")
    
    local autoPlaceToggle = TeleportTab:AddToggle("AutoPlaceTeleporterToggle", {
        Title = "Auto Place Every Round",
        Description = "Automatically place teleporter when round starts",
        Default = false
    })
    
    autoPlaceToggle:OnChanged(function(value)
        autoPlaceTeleporterEnabled = value
        if value then
            Fluent:Notify({
                Title = "Auto Place Enabled",
                Content = "Will place " .. autoPlaceTeleporterType .. " teleporter every round",
                Duration = 3
            })
        end
    end)
    
    local typeDropdown = TeleportTab:AddDropdown("TeleporterTypeDropdown", {
        Title = "Teleporter Type",
        Description = "Select teleporter placement type",
        Values = { "Far", "Sky" },
        Default = "Far"
    })
    
    typeDropdown:OnChanged(function(value)
        autoPlaceTeleporterType = value
        Fluent:Notify({
            Title = "Type Changed",
            Content = "Auto place will use " .. value .. " spot",
            Duration = 2
        })
    end)
    
    TeleportTab:AddSection("Teleport to Spot")
    
    TeleportTab:AddButton({
        Title = "Place Teleporter Far",
        Description = "Place at safe far spot for current map",
        Callback = function()
            TeleportModule.PlaceTeleporter("Far")
        end
    })
    
    TeleportTab:AddButton({
        Title = "Place Teleporter Sky",
        Description = "Place at sky position for current map",
        Callback = function()
            TeleportModule.PlaceTeleporter("Sky")
        end
    })
    
    TeleportTab:AddButton({
        Title = "Teleport Player To Sky",
        Description = "Teleport player to sky directly",
        Callback = function()
            TeleportModule.TeleportPlayer("Sky")
        end
    })
    
    TeleportTab:AddButton({
        Title = "Teleport Player To Far",
        Description = "Teleport player to far directly",
        Callback = function()
            TeleportModule.TeleportPlayer("Far")
        end
    })
    
    TeleportTab:AddSection("Objective Teleports")
    
    TeleportTab:AddButton({
        Title = "Teleport to Objective",
        Description = "Teleport to a random objective",
        Callback = function()
            -- TeleportFeaturesModule.TeleportToRandomObjective()
            createNotification("Coming Soon", "Feature will be implemented soon", 2)
        end
    })
    
    TeleportTab:AddButton({
        Title = "Teleport to Nearest Ticket",
        Description = "Teleport to the closest ticket",
        Callback = function()
            -- TeleportFeaturesModule.TeleportToNearestTicket()
            createNotification("Coming Soon", "Feature will be implemented soon", 2)
        end
    })
    
    TeleportTab:AddSection("Player Teleports")
    
    local function getPlayerList()
        local playerNames = {}
        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= player then
                table.insert(playerNames, pl.Name)
            end
        end
        table.sort(playerNames)
        return #playerNames > 0 and playerNames or { "No players available" }
    end
    
    local selectedPlayerName = nil
    
    local playerDropdown = TeleportTab:AddDropdown("PlayerListDropdown", {
        Title = "Select Player",
        Values = getPlayerList(),
        Default = getPlayerList()[1] or "No players available"
    })
    
    playerDropdown:OnChanged(function(value)
        if value ~= "No players available" then
            selectedPlayerName = value
        end
    end)
    
    local function refreshPlayerDropdown()
        local playerList = getPlayerList()
        playerDropdown:SetValues(playerList)
        if playerList[1] and playerList[1] ~= "No players available" then
            if not selectedPlayerName or not table.find(playerList, selectedPlayerName) then
                selectedPlayerName = playerList[1]
                playerDropdown:SetValue(selectedPlayerName)
            end
        else
            selectedPlayerName = nil
        end
    end
    
    Players.PlayerAdded:Connect(function()
        task.wait(0.5)
        refreshPlayerDropdown()
    end)
    
    Players.PlayerRemoving:Connect(function()
        task.wait(0.1)
        refreshPlayerDropdown()
    end)
    
    TeleportTab:AddButton({
        Title = "Teleport to Selected Player",
        Description = "Teleport to the player selected in dropdown",
        Callback = function()
            if not selectedPlayerName or selectedPlayerName == "No players available" then
                createNotification("Error", "No player selected!", 2)
                return
            end
            
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                createNotification("Error", "Character not found!", 2)
                return
            end
            
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            if not targetPlayer or not targetPlayer.Character then
                createNotification("Error", selectedPlayerName .. " not found!", 2)
                refreshPlayerDropdown()
                return
            end
            
            local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not targetHRP then
                createNotification("Error", selectedPlayerName .. " has no HumanoidRootPart!", 2)
                return
            end
            
            char.HumanoidRootPart.CFrame = targetHRP.CFrame
            createNotification("Success", "Teleported to " .. selectedPlayerName, 2)
        end
    })
    
    TeleportTab:AddButton({
        Title = "Refresh Player List",
        Description = "Update the player list manually",
        Callback = function()
            refreshPlayerDropdown()
            Fluent:Notify({
                Title = "Player List",
                Content = "Player list refreshed!",
                Duration = 2
            })
        end
    })
    
    TeleportTab:AddButton({
        Title = "Teleport to Random Player",
        Description = "Teleport to a random player",
        Callback = function()
            local players = {}
            for _, pl in pairs(Players:GetPlayers()) do
                if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    table.insert(players, pl)
                end
            end
            
            if #players == 0 then
                createNotification("Error", "No other players found!", 2)
                return
            end
            
            local randomPlayer = players[math.random(1, #players)]
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame
                createNotification("Success", "Teleported to " .. randomPlayer.Name, 2)
            end
        end
    })
    
    TeleportTab:AddSection("Downed Player Teleports")
    
    TeleportTab:AddButton({
        Title = "Teleport to Nearest Downed Player",
        Description = "Automatically teleport to the closest downed player",
        Callback = function()
            createNotification("Coming Soon", "Feature will be implemented soon", 2)
        end
    })
    
    return TeleportTab
end

return CreateTeleportTab

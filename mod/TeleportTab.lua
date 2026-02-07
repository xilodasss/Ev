-- TeleportTab.lua
-- External file for Teleport Tab functionality

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

-- Helper functions (assuming these are defined in main script)
local function Info(title, content, duration)
    -- Implementation from main script
end

local function Success(title, content, duration)
    -- Implementation from main script
end

local function Error(title, content, duration)
    -- Implementation from main script
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
        -- Add more maps here as needed
    }

    local function validateCharacter()
        local char = player.Character
        if not char then
            Error("Teleport", "Character not found!", 2)
            return nil, nil
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            Error("Teleport", "HumanoidRootPart not found!", 2)
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
            Error("Teleport", "Invalid teleporter position!", 2)
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

            Success("Teleporter Placed", "Teleporter successfully placed!", 2)
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
                Error("Teleport", "Could not detect map name!", 2)
                return false
            end

            if not mapSpots[mapName] then
                Error("Teleport", "Map '" .. mapName .. "' not in database!", 3)
                return false
            end

            local cframe = mapSpots[mapName][spotType]
            if not cframe then
                Error("Teleport", "No " .. spotType .. " spot found for " .. mapName, 3)
                return false
            end

            Info("Teleporting", "Teleporting to " .. spotType .. " for " .. mapName .. "...", 2)
            return safeTeleport(hrp, cframe.Position, { char })
        end,
        PlaceTeleporter = function(spotType)
            local mapName = getCurrentMap()

            if mapName == "Unknown" then
                Error("Teleport", "Could not detect map name!", 2)
                return false
            end

            if not mapSpots[mapName] then
                Error("Teleport", "Map '" .. mapName .. "' not in database!", 3)
                return false
            end

            local cframe = mapSpots[mapName][spotType]
            if not cframe then
                Error("Teleport", "No " .. spotType .. " spot found for " .. mapName, 3)
                return false
            end

            Info("Placing Teleporter", "Placing " .. spotType .. " teleporter for " .. mapName .. "...", 2)
            return placeTeleporter(cframe)
        end
    }
end)()

-- Auto Place Teleporter System
local autoPlaceTeleporterEnabled = false
local autoPlaceTeleporterType = "Far"
local gameStats = workspace:WaitForChild("Game"):WaitForChild("Stats")
local gameMap = workspace:WaitForChild("Game"):WaitForChild("Map")

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
            Info("Auto Place", "Round " .. roundsCompleted .. " done", 2)
        end)
    end
end)

local lastLoadProgress = 0
local isProcessingMapChange = false

gameStats:GetAttributeChangedSignal("LoadProgress"):Connect(function()
    if not autoPlaceTeleporterEnabled then return end
    if isProcessingMapChange then return end
    local loadProgress = gameStats:GetAttribute("LoadProgress") or 0
    if lastLoadProgress == 0 and loadProgress > 1000 then
        local currentMapName = TeleportModule.GetCurrentMap()
        if not TeleportModule.HasMapData(currentMapName) then
            if currentMapName ~= "Unknown" then
                Info("Auto Place", "Map '" .. currentMapName .. "' not in database", 2)
            end
            lastLoadProgress = loadProgress
            return
        end
        isProcessingMapChange = true

        task.spawn(function()
            local timer = nil
            repeat
                task.wait(0.5)
                timer = gameStats:GetAttribute("Timer")
            until timer and timer > 0
            local character = player.Character or player.CharacterAdded:Wait()
            character:WaitForChild("HumanoidRootPart")
            task.wait(1)
            TeleportModule.PlaceTeleporter(autoPlaceTeleporterType)
            Info("Auto Place", "New map: " .. currentMapName, 2)
            task.wait(2)
            isProcessingMapChange = false
        end)
    end
    if loadProgress == 0 then
        lastLoadProgress = 0
    elseif loadProgress > 1000 then
        lastLoadProgress = loadProgress
    end
end)

-- Teleport Features Module
local TeleportFeaturesModule = (function()
    local function validateCharacter()
        local char = player.Character
        if not char then
            Error("Teleport", "Character not found!", 2)
            return nil, nil
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            Error("Teleport", "HumanoidRootPart not found!", 2)
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

    local function findNearestTicketInternal()
        local gameFolder = workspace:FindFirstChild("Game")
        if not gameFolder then return nil end

        local effects = gameFolder:FindFirstChild("Effects")
        if not effects then return nil end

        local tickets = effects:FindFirstChild("Tickets")
        if not tickets then return nil end

        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

        local hrp = char.HumanoidRootPart
        local nearestTicket = nil
        local nearestDistance = math.huge

        for _, ticket in pairs(tickets:GetChildren()) do
            if ticket:IsA("BasePart") or ticket:IsA("Model") then
                local ticketPart = ticket:IsA("Model") and ticket:FindFirstChild("HumanoidRootPart") or ticket
                if ticketPart and ticketPart:IsA("BasePart") then
                    local dist = (hrp.Position - ticketPart.Position).Magnitude
                    if dist < nearestDistance then
                        nearestDistance = dist
                        nearestTicket = ticketPart
                    end
                end
            end
        end

        return nearestTicket
    end

    local function isPlayerDowned(pl)
        if not pl or not pl.Character then return false end
        local char = pl.Character
        if char:GetAttribute("Downed") then return true end
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.Health <= 0 then return true end
        return false
    end

    local function findNearestDownedPlayer()
        local char, hrp = validateCharacter()
        if not char or not hrp then return nil end

        local nearestPlayer = nil
        local nearestDistance = math.huge

        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                if isPlayerDowned(pl) then
                    local dist = (hrp.Position - pl.Character.HumanoidRootPart.Position).Magnitude
                    if dist < nearestDistance then
                        nearestDistance = dist
                        nearestPlayer = pl
                    end
                end
            end
        end

        return nearestPlayer, nearestDistance
    end

    return {
        TeleportToRandomObjective = function()
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local objectives = {}
            local gameFolder = workspace:FindFirstChild("Game")
            if not gameFolder then
                Error("Teleport", "Game folder not found!", 2)
                return false
            end

            local mapFolder = gameFolder:FindFirstChild("Map")
            if not mapFolder then
                Error("Teleport", "Map folder not found!", 2)
                return false
            end

            local partsFolder = mapFolder:FindFirstChild("Parts")
            if not partsFolder then
                Error("Teleport", "Parts folder not found!", 2)
                return false
            end

            local objectivesFolder = partsFolder:FindFirstChild("Objectives")
            if not objectivesFolder then
                Error("Teleport", "Objectives folder not found!", 2)
                return false
            end

            for _, obj in pairs(objectivesFolder:GetChildren()) do
                if obj:IsA("Model") then
                    local primaryPart = obj.PrimaryPart
                    if not primaryPart then
                        for _, part in pairs(obj:GetChildren()) do
                            if part:IsA("BasePart") then
                                primaryPart = part
                                break
                            end
                        end
                    end

                    if primaryPart then
                        table.insert(objectives, {
                            Name = obj.Name,
                            Part = primaryPart
                        })
                    end
                end
            end

            if #objectives == 0 then
                Error("Teleport", "No objectives found!", 2)
                return false
            end

            local selectedObjective = objectives[math.random(1, #objectives)]
            safeTeleport(hrp, selectedObjective.Part.Position, { char })
            Success("Teleport", "Teleported to " .. selectedObjective.Name, 2)
            return true
        end,

        FindNearestTicket = findNearestTicketInternal,

        TeleportToNearestTicket = function()
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local ticket = findNearestTicketInternal()
            if not ticket then
                Error("Teleport", "No tickets found!", 2)
                return false
            end

            safeTeleport(hrp, ticket.Position, { char })
            Success("Teleport", "Teleported to nearest ticket!", 2)
            return true
        end,

        GetPlayerList = function()
            local playerNames = {}
            for _, pl in pairs(Players:GetPlayers()) do
                if pl ~= player then
                    table.insert(playerNames, pl.Name)
                end
            end
            table.sort(playerNames)
            return #playerNames > 0 and playerNames or { "No players available" }
        end,

        TeleportToPlayer = function(playerName)
            if not playerName or playerName == "No players available" then
                Error("Teleport", "No player selected!", 2)
                return false
            end

            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local targetPlayer = Players:FindFirstChild(playerName)
            if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                Error("Teleport", playerName .. " not found or no character!", 2)
                return false
            end

            local targetHRP = targetPlayer.Character.HumanoidRootPart
            safeTeleport(hrp, targetHRP.Position, { char, targetPlayer.Character })
            Success("Teleport", "Teleported to " .. playerName, 2)
            return true
        end,

        TeleportToRandomPlayer = function()
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local players = {}
            for _, pl in pairs(Players:GetPlayers()) do
                if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    table.insert(players, pl)
                end
            end

            if #players == 0 then
                Error("Teleport", "No other players found!", 2)
                return false
            end

            local randomPlayer = players[math.random(1, #players)]
            local targetHRP = randomPlayer.Character.HumanoidRootPart
            safeTeleport(hrp, targetHRP.Position, { char, randomPlayer.Character })
            Success("Teleport", "Teleported to " .. randomPlayer.Name, 2)
            return true
        end,

        IsPlayerDowned = isPlayerDowned,
        FindNearestDownedPlayer = findNearestDownedPlayer,

        TeleportToNearestDowned = function()
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local nearestPlayer, distance = findNearestDownedPlayer()
            if not nearestPlayer then
                Error("Teleport", "No downed players found!", 2)
                return false
            end

            local targetHRP = nearestPlayer.Character.HumanoidRootPart
            safeTeleport(hrp, targetHRP.Position, { char, nearestPlayer.Character })
            Success("Teleport", "Teleported to " .. nearestPlayer.Name .. " (" .. math.floor(distance) .. " studs)", 2)
            return true
        end,
    }
end)()

-- Main function to create Teleport Tab
local function CreateTeleportTab(Window, Fluent)
    local TeleportTab = Window:AddTab({ Title = "Teleport", Icon = "navigation" })
    
    TeleportTab:AddSection("Auto Place Teleporter")
    
    TeleportTab:AddToggle("AutoPlaceTeleporterToggle", {
        Title = "Auto Place Every Round",
        Description = "Automatically place teleporter when round starts",
        Default = false,
        Callback = function(value)
            autoPlaceTeleporterEnabled = value
            if value then
                Fluent:Notify({
                    Title = "Auto Place Enabled",
                    Content = "Will place " .. autoPlaceTeleporterType .. " teleporter every round",
                    Duration = 3
                })
            end
        end
    })
    
    TeleportTab:AddDropdown("TeleporterTypeDropdown", {
        Title = "Teleporter Type",
        Description = "Select teleporter placement type",
        Values = { "Far", "Sky" },
        Default = "Far",
        Callback = function(value)
            autoPlaceTeleporterType = value
            Fluent:Notify({
                Title = "Type Changed",
                Content = "Auto place will use " .. value .. " spot",
                Duration = 2
            })
        end
    })
    
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
            TeleportFeaturesModule.TeleportToRandomObjective()
        end
    })
    
    TeleportTab:AddButton({
        Title = "Teleport to Nearest Ticket",
        Description = "Teleport to the closest ticket",
        Callback = function()
            TeleportFeaturesModule.TeleportToNearestTicket()
        end
    })
    
    TeleportTab:AddSection("Player Teleports")
    
    local selectedPlayerName = nil
    local PlayerListDropdown = nil
    
    local function refreshPlayerDropdown()
        if PlayerListDropdown then
            local playerList = TeleportFeaturesModule.GetPlayerList()
            PlayerListDropdown:SetValues(playerList)
            if playerList[1] and playerList[1] ~= "No players available" then
                if not selectedPlayerName or not table.find(playerList, selectedPlayerName) then
                    selectedPlayerName = playerList[1]
                    PlayerListDropdown:SetValue(selectedPlayerName)
                end
            else
                selectedPlayerName = nil
            end
        end
    end
    
    PlayerListDropdown = TeleportTab:AddDropdown("PlayerListDropdown", {
        Title = "Select Player",
        Values = TeleportFeaturesModule.GetPlayerList(),
        Default = TeleportFeaturesModule.GetPlayerList()[1] or "No players available",
        Callback = function(value)
            if value ~= "No players available" then
                selectedPlayerName = value
            end
        end
    })
    
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
            if TeleportFeaturesModule.TeleportToPlayer(selectedPlayerName) then
            else
                refreshPlayerDropdown()
            end
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
            TeleportFeaturesModule.TeleportToRandomPlayer()
        end
    })
    
    TeleportTab:AddSection("Downed Player Teleports")
    
    TeleportTab:AddButton({
        Title = "Teleport to Nearest Downed Player",
        Description = "Automatically teleport to the closest downed player",
        Callback = function()
            TeleportFeaturesModule.TeleportToNearestDowned()
        end
    })
    
    return TeleportTab
end

return CreateTeleportTab

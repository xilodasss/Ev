-- Load Obsidian UI Library
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- ==================== LOAD EXTERNAL MODULES ====================
-- Path ke repository GitHub Anda
local modulesRepo = "https://raw.githubusercontent.com/xilodasss/Ev/main/games/evade/modules/"

-- Load semua modules
local Utils = loadstring(game:HttpGet(modulesRepo .. "Utils.lua"))()
local AntiLagModule = loadstring(game:HttpGet(modulesRepo .. "AntiLag.lua"))()
local GunFunctionsModule = loadstring(game:HttpGet(modulesRepo .. "GunFunctions.lua"))()
local IruzHub = loadstring(game:HttpGet(modulesRepo .. "IruzHub.lua"))()
local KeybindManager = loadstring(game:HttpGet(modulesRepo .. "KeybindManager.lua"))()
local TeleportModule = loadstring(game:HttpGet(modulesRepo .. "Teleport.lua"))()

-- Import SafeWrapper dan helper functions dari Utils
local SafeWrapper = Utils.SafeWrapper
local safeGetCharacter = Utils.safeGetCharacter
local safeGetHumanoid = Utils.safeGetHumanoid
local isPlayerDowned = Utils.isPlayerDowned

-- ==================== DEBUG INFO ====================
print("=== DEBUG: Script mulai dijalankan ===")
print("Script path:", debug.getinfo(1).source)

-- ==================== READONLY TABLE ERROR FIX ====================
debug.setmetatable(nil, {
    __newindex = function() end,  -- Ignore semua write attempts ke nil
})

-- Safe table modification
local originalRawset = rawset
rawset = function(t, k, v)
    local success = pcall(originalRawset, t, k, v)
    return success
end

-- ==================== ENHANCED ERROR HANDLING ====================
local DEBUG_MODE = false

local function DebugLog(message, ...)
    if DEBUG_MODE then
        print("[Iruz Debug]:", message, ...)
    end
end

-- ==================== SERVICES ====================
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")
local placeId = game.PlaceId
local jobId = game.JobId

-- ==================== GLOBAL VARIABLES ====================
local Confirmed = false
local autoRespawnMethod = nil
local respawnConnection
local lastSavedPosition
local infiniteSlideEnabled = false
local slideFrictionValue = -8
local slideConnection
local cachedTables = {}
local plrModel
local autoCarryButton
local autoCarryConnection
local autoHelpConnection
local playerESPThread
local nextbotESPThread
local tracerThread
local tracerLines = {}
local lagSwitchEnabled = false
local lagDuration = 0.5

-- ==================== IRUZ HUB VARIABLES ====================
local flying = false
local flyLoop = nil
local antiNextbotConnection = nil
local antiNextbotEnabled = false
local antiNextbotDistance = 50
local teleportType = "Distance"
local teleportDistance = 20
local PathfindingService = game:GetService("PathfindingService")
local gravityEnabled = false
local originalGravity = workspace.Gravity
local gravityValue = 10
local AutoDrinkConnection = nil
local autoDrinkEnabled = false
local drinkDelay = 0.5
local bhopConnection = nil
local bhopLoaded = false
local frictionTables = {}
local CharacterDH = nil
local HumanoidDH = nil
local HumanoidRootPartDH = nil
local LastJump = 0
local GROUND_CHECK_DISTANCE = 3.5
local MAX_SLOPE_ANGLE = 45
local isLagActive = false
local lagDelayValue = 0.1
local lagIntensity = 1000000
local lagSwitchMode = "Normal"
local cameraStretchConnection = nil
local stretchHorizontal = 0.80
local stretchVertical = 0.80
local cameraStretchEnabled = false
local noFogEnabled = false
local originalFogEnd = nil
local originalAtmospheres = {}
local fpsTimerEnabled = true

-- ==================== HOLD SPACE JUMP VARIABLES ====================
getgenv().autoJumpEnabled = false
getgenv().bhopMode = "Normal"
getgenv().bhopAccelValue = -0.1
getgenv().jumpInterval = 0.1
getgenv().autoJumpType = "Normal"

-- Teleport variables
local autoPlaceTeleporterEnabled = false
local autoPlaceTeleporterType = "Far"
local gameStats = workspace:WaitForChild("Game"):WaitForChild("Stats")
local gameMap = workspace:WaitForChild("Game"):WaitForChild("Map")

-- ==================== SETUP THEMEMANAGER DAN SAVEMANAGER ====================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("IruzEvade")

-- ==================== AUTO SELF REVIVE MODULE ====================
local AutoSelfReviveModule = (function()
    local enabled = false
    local method = "Spawnpoint"
    local connections = {}
    local lastSavedPosition = nil
    local hasRevived = false
    local isReviving = false

    local function cleanupConnections()
        for _, conn in pairs(connections) do
            if conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
        connections = {}
    end

    local function handleDowned(character)
        if not character or not character:IsDescendantOf(workspace) then return end
        
        local isDowned = character:GetAttribute("Downed")
        if isDowned and not isReviving then
            isReviving = true

            if method == "Spawnpoint" then
                if not hasRevived then
                    hasRevived = true
                    pcall(function()
                        ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                    end)
                    Library:Notify({
                        Title = "Auto Self Revive",
                        Description = "Reviving at spawnpoint...",
                        Time = 2,
                    })

                    task.delay(10, function()
                        hasRevived = false
                    end)
                    task.delay(1, function()
                        isReviving = false
                    end)
                else
                    isReviving = false
                end
            elseif method == "Fake Revive" then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    lastSavedPosition = hrp.Position
                end

                task.spawn(function()
                    pcall(function()
                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Player"):WaitForChild("ChangePlayerMode")
                            :FireServer(true)
                    end)

                    Library:Notify({
                        Title = "Auto Self Revive",
                        Description = "Saving position and reviving...",
                        Time = 2,
                    })

                    local newCharacter
                    repeat
                        newCharacter = player.Character
                        task.wait()
                    until newCharacter and newCharacter:FindFirstChild("HumanoidRootPart") and newCharacter ~= character

                    if newCharacter then
                        local newHRP = newCharacter:FindFirstChild("HumanoidRootPart")
                        if lastSavedPosition and newHRP then
                            task.wait(0.1)
                            newHRP.CFrame = CFrame.new(lastSavedPosition)
                            Library:Notify({
                                Title = "Auto Self Revive",
                                Description = "Teleported back to saved position!",
                                Time = 2,
                            })
                        end
                    end

                    isReviving = false
                end)
            end
        end
    end

    local function setupCharacter(character)
        if not character or not character:IsDescendantOf(workspace) then return end

        task.wait(0.5)

        local downedConnection = character:GetAttributeChangedSignal("Downed"):Connect(function()
            handleDowned(character)
        end)

        table.insert(connections, downedConnection)
    end

    local function start()
        if enabled then return end
        enabled = true

        cleanupConnections()

        local character = safeGetCharacter(player)
        if character then
            setupCharacter(character)
        end

        local charAddedConnection = player.CharacterAdded:Connect(function(newChar)
            setupCharacter(newChar)
        end)

        table.insert(connections, charAddedConnection)

        Library:Notify({
            Title = "Auto Self Revive",
            Description = "Enabled with method: " .. method,
            Time = 2,
        })
    end

    local function stop()
        if not enabled then return end
        enabled = false

        cleanupConnections()
        hasRevived = false
        isReviving = false
        lastSavedPosition = nil

        Library:Notify({
            Title = "Auto Self Revive",
            Description = "Disabled",
            Time = 2,
        })
    end

    return {
        Start = SafeWrapper("AutoSelfRevive.Start", start),
        Stop = SafeWrapper("AutoSelfRevive.Stop", stop),
        SetMethod = function(newMethod)
            method = newMethod
            if enabled then
                Library:Notify({
                    Title = "Auto Self Revive",
                    Description = "Method changed to: " .. newMethod,
                    Time = 2,
                })
            end
        end,
        IsEnabled = function()
            return enabled
        end
    }
end)()

-- ==================== FAST REVIVE MODULE ====================
local FastReviveModule = (function()
    local enabled = false
    local method = "Interact"
    local reviveRange = 10
    local loopDelay = 0.15
    local reviveLoopHandle = nil
    local interactHookConnection = nil
    local keyboardConnection = nil
    
    local function getInteractEvent()
        local success, event = pcall(function()
            return ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact")
        end)
        return success and event or nil
    end

    local function startAutoMethod()
        if reviveLoopHandle then return end

        reviveLoopHandle = task.spawn(function()
            while enabled and method == "Auto" do
                local interactEvent = getInteractEvent()
                if not interactEvent then
                    task.wait(1)
                    continue
                end
                
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local myHRP = player.Character.HumanoidRootPart
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= player then
                            local char = safeGetCharacter(plr)
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                if isPlayerDowned(plr) then
                                    local hrp = char.HumanoidRootPart
                                    local success, dist = pcall(function()
                                        return (myHRP.Position - hrp.Position).Magnitude
                                    end)
                                    if success and dist and dist <= reviveRange then
                                        pcall(function()
                                            interactEvent:FireServer("Revive", true, plr.Name)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(loopDelay)
            end
            reviveLoopHandle = nil
        end)
    end

    local function stopAutoMethod()
        if reviveLoopHandle then
            task.cancel(reviveLoopHandle)
            reviveLoopHandle = nil
        end
    end

    local function startInteractMethod()
        if interactHookConnection then return end

        local eventsFolder = player.PlayerScripts:WaitForChild("Events")
        local tempEventsFolder = eventsFolder:WaitForChild("temporary_events")
        local useKeybind = tempEventsFolder:WaitForChild("UseKeybind")

        interactHookConnection = useKeybind.Event:Connect(function(...)
            local args = { ... }

            if args[1] and type(args[1]) == "table" then
                local keyData = args[1]

                if keyData.Key == "Interact" and keyData.Down == true and enabled then
                    task.spawn(function()
                        for _, plr in pairs(Players:GetPlayers()) do
                            if plr ~= player then
                                pcall(function()
                                    getInteractEvent():FireServer("Revive", true, plr.Name)
                                end)
                                task.wait(0.1)
                            end
                        end
                    end)
                end
            end
        end)

        keyboardConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or not enabled then return end

            if input.KeyCode == Enum.KeyCode.E then
                task.spawn(function()
                    for _, plr in pairs(Players:GetPlayers()) do
                        if plr ~= player then
                            pcall(function()
                                getInteractEvent():FireServer("Revive", true, plr.Name)
                            end)
                            task.wait(0.1)
                        end
                    end
                end)
            end
        end)
    end

    local function stopInteractMethod()
        if interactHookConnection then
            interactHookConnection:Disconnect()
            interactHookConnection = nil
        end
        if keyboardConnection then
            keyboardConnection:Disconnect()
            keyboardConnection = nil
        end
    end

    local function start()
        enabled = true
        if method == "Auto" then
            stopInteractMethod()
            startAutoMethod()
        elseif method == "Interact" then
            stopAutoMethod()
            startInteractMethod()
        end
    end

    local function stop()
        enabled = false
        stopAutoMethod()
        stopInteractMethod()
    end

    local function setMethod(newMethod)
        local wasEnabled = enabled
        stop()
        method = newMethod
        if wasEnabled then
            start()
        end
    end

    return {
        Start = SafeWrapper("FastRevive.Start", start),
        Stop = SafeWrapper("FastRevive.Stop", stop),
        SetMethod = SafeWrapper("FastRevive.SetMethod", setMethod)
    }
end)()

-- ==================== AUTO FARM MODULE ====================
local AutoFarmModule = (function()
    local securityPart = nil
    local connections = {
        autoWin = nil,
        farmMoney = nil,
        farmMoneyInstant = nil,
        farmTickets = nil
    }
    local activeStates = {
        autoWin = false,
        farmMoney = false,
        farmTickets = false
    }

    local function createSecurityPart()
        if workspace:FindFirstChild("SecurityPart") then
            return workspace.SecurityPart
        end

        securityPart = Instance.new("Part")
        securityPart.Name = "SecurityPart"
        securityPart.Size = Vector3.new(10, 1, 10)
        securityPart.Position = Vector3.new(5000, 5000, 5000)
        securityPart.Anchored = true
        securityPart.CanCollide = true
        securityPart.Transparency = 0.9
        securityPart.Material = Enum.Material.Neon
        securityPart.BrickColor = BrickColor.new("Bright green")
        securityPart.Parent = workspace

        return securityPart
    end

    local function removeSecurityPart()
        if not activeStates.autoWin and not activeStates.farmMoney and not activeStates.farmTickets then
            if securityPart and securityPart.Parent then
                securityPart:Destroy()
            end
            securityPart = nil
        end
    end

    local function getPlayerFromModel(model)
        for _, pl in pairs(Players:GetPlayers()) do
            if pl.Character == model or (pl.Character and pl.Character.Name == model.Name) then
                return pl
            end
        end
        return nil
    end

    local function startFarmMoney()
        if connections.farmMoney then return end

        local security = createSecurityPart()
        activeStates.farmMoney = true

        connections.farmMoneyInstant = task.spawn(function()
            while activeStates.farmMoney do
                local myChar = safeGetCharacter(player)
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    local myHrp = myChar.HumanoidRootPart
                    for _, pl in ipairs(Players:GetPlayers()) do
                        if pl ~= player and isPlayerDowned(pl) then
                            local char = safeGetCharacter(pl)
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                local success, dist = pcall(function()
                                    return (myHrp.Position - char.HumanoidRootPart.Position).Magnitude
                                end)
                                if success and dist and dist <= 10 then
                                    pcall(function()
                                        ReplicatedStorage.Events.Character.Interact:FireServer("Revive", true, pl.Name)
                                    end)
                                end
                            end
                        end
                    end
                end
                task.wait(0.15)
            end
        end)

        connections.farmMoney = RunService.Heartbeat:Connect(function()
            local secPart = workspace:FindFirstChild("SecurityPart")
            if not secPart then return end

            local char = safeGetCharacter(player)
            if not char then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local downedPlayerFound = false
            local playersInGame = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")

            if playersInGame then
                for _, v in pairs(playersInGame:GetChildren()) do
                    if v:IsA("Model") and v:GetAttribute("Downed") and not v:GetAttribute("Carried") then
                        if v:FindFirstChild("RagdollConstraints") then
                            continue
                        end

                        local vHrp = v:FindFirstChild("HumanoidRootPart")
                        if vHrp then
                            hrp.CFrame = vHrp.CFrame + Vector3.new(0, 3, 0)

                            local targetPlayer = getPlayerFromModel(v)
                            pcall(function()
                                if targetPlayer then
                                    ReplicatedStorage.Events.Character.Interact:FireServer("Revive", true,
                                        targetPlayer.Name)
                                end
                            end)
                            task.wait(0.5)
                            downedPlayerFound = true
                            break
                        end
                    end
                end
            end

            if not downedPlayerFound then
                hrp.CFrame = secPart.CFrame + Vector3.new(0, 3, 0)
            end
        end)
    end

    local function stopFarmMoney()
        activeStates.farmMoney = false
        if connections.farmMoneyInstant then
            task.cancel(connections.farmMoneyInstant)
            connections.farmMoneyInstant = nil
        end
        if connections.farmMoney then
            connections.farmMoney:Disconnect()
            connections.farmMoney = nil
        end
        removeSecurityPart()
    end

    return {
        StartFarmMoney = SafeWrapper("AutoFarm.StartFarmMoney", startFarmMoney),
        StopFarmMoney = SafeWrapper("AutoFarm.StopFarmMoney", stopFarmMoney),
        StopAll = SafeWrapper("AutoFarm.StopAll", function()
            stopFarmMoney()
        end)
    }
end)()

-- ==================== TELEPORT FEATURES MODULE ====================
local TeleportFeaturesModule = (function()
    local function validateCharacter()
        local char = safeGetCharacter(player)
        if not char then
            Library:Notify({
                Title = "Teleport",
                Description = "Character not found!",
                Time = 2,
            })
            return nil, nil
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            Library:Notify({
                Title = "Teleport",
                Description = "HumanoidRootPart not found!",
                Time = 2,
            })
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

        local char = safeGetCharacter(player)
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

    local function findNearestDownedPlayer()
        local char, hrp = validateCharacter()
        if not char or not hrp then return nil end

        local nearestPlayer = nil
        local nearestDistance = math.huge

        for _, pl in pairs(Players:GetPlayers()) do
            if pl ~= player then
                local plChar = safeGetCharacter(pl)
                if plChar and plChar:FindFirstChild("HumanoidRootPart") then
                    if isPlayerDowned(pl) then
                        local dist = (hrp.Position - plChar.HumanoidRootPart.Position).Magnitude
                        if dist < nearestDistance then
                            nearestDistance = dist
                            nearestPlayer = pl
                        end
                    end
                end
            end
        end

        return nearestPlayer, nearestDistance
    end

    local function findNearestTicket()
        return findNearestTicketInternal()
    end

    return {
        TeleportToRandomObjective = SafeWrapper("TeleportFeatures.TeleportToRandomObjective", function()
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local objectives = {}
            local gameFolder = workspace:FindFirstChild("Game")
            if not gameFolder then
                Library:Notify({
                    Title = "Teleport",
                    Description = "Game folder not found!",
                    Time = 2,
                })
                return false
            end

            local mapFolder = gameFolder:FindFirstChild("Map")
            if not mapFolder then
                Library:Notify({
                    Title = "Teleport",
                    Description = "Map folder not found!",
                    Time = 2,
                })
                return false
            end

            local partsFolder = mapFolder:FindFirstChild("Parts")
            if not partsFolder then
                Library:Notify({
                    Title = "Teleport",
                    Description = "Parts folder not found!",
                    Time = 2,
                })
                return false
            end

            local objectivesFolder = partsFolder:FindFirstChild("Objectives")
            if not objectivesFolder then
                Library:Notify({
                    Title = "Teleport",
                    Description = "Objectives folder not found!",
                    Time = 2,
                })
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
                Library:Notify({
                    Title = "Teleport",
                    Description = "No objectives found!",
                    Time = 2,
                })
                return false
            end

            local selectedObjective = objectives[math.random(1, #objectives)]
            safeTeleport(hrp, selectedObjective.Part.Position, { char })
            Library:Notify({
                Title = "Teleport",
                Description = "Teleported to " .. selectedObjective.Name,
                Time = 2,
            })
            return true
        end),

        FindNearestTicket = findNearestTicket,

        TeleportToNearestTicket = SafeWrapper("TeleportFeatures.TeleportToNearestTicket", function()
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local ticket = findNearestTicketInternal()
            if not ticket then
                Library:Notify({
                    Title = "Teleport",
                    Description = "No tickets found!",
                    Time = 2,
                })
                return false
            end

            safeTeleport(hrp, ticket.Position, { char })
            Library:Notify({
                Title = "Teleport",
                Description = "Teleported to nearest ticket!",
                Time = 2,
            })
            return true
        end),

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

        TeleportToPlayer = SafeWrapper("TeleportFeatures.TeleportToPlayer", function(playerName)
            if not playerName or playerName == "No players available" then
                Library:Notify({
                    Title = "Teleport",
                    Description = "No player selected!",
                    Time = 2,
                })
                return false
            end

            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local targetPlayer = Players:FindFirstChild(playerName)
            if not targetPlayer then
                Library:Notify({
                    Title = "Teleport",
                    Description = playerName .. " not found!",
                    Time = 2,
                })
                return false
            end

            local targetChar = safeGetCharacter(targetPlayer)
            if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
                Library:Notify({
                    Title = "Teleport",
                    Description = playerName .. " has no character!",
                    Time = 2,
                })
                return false
            end

            local targetHRP = targetChar.HumanoidRootPart
            safeTeleport(hrp, targetHRP.Position, { char, targetChar })
            Library:Notify({
                Title = "Teleport",
                Description = "Teleported to " .. playerName,
                Time = 2,
            })
            return true
        end),

        TeleportToRandomPlayer = SafeWrapper("TeleportFeatures.TeleportToRandomPlayer", function()
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local players = {}
            for _, pl in pairs(Players:GetPlayers()) do
                if pl ~= player then
                    local plChar = safeGetCharacter(pl)
                    if plChar and plChar:FindFirstChild("HumanoidRootPart") then
                        table.insert(players, pl)
                    end
                end
            end

            if #players == 0 then
                Library:Notify({
                    Title = "Teleport",
                    Description = "No other players found!",
                    Time = 2,
                })
                return false
            end

            local randomPlayer = players[math.random(1, #players)]
            local targetChar = safeGetCharacter(randomPlayer)
            local targetHRP = targetChar.HumanoidRootPart
            safeTeleport(hrp, targetHRP.Position, { char, targetChar })
            Library:Notify({
                Title = "Teleport",
                Description = "Teleported to " .. randomPlayer.Name,
                Time = 2,
            })
            return true
        end),

        FindNearestDownedPlayer = findNearestDownedPlayer,

        TeleportToNearestDowned = SafeWrapper("TeleportFeatures.TeleportToNearestDowned", function()
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end

            local nearestPlayer, distance = findNearestDownedPlayer()
            if not nearestPlayer then
                Library:Notify({
                    Title = "Teleport",
                    Description = "No downed players found!",
                    Time = 2,
                })
                return false
            end

            local targetChar = safeGetCharacter(nearestPlayer)
            local targetHRP = targetChar.HumanoidRootPart
            safeTeleport(hrp, targetHRP.Position, { char, targetChar })
            Library:Notify({
                Title = "Teleport",
                Description = "Teleported to " .. nearestPlayer.Name .. " (" .. math.floor(distance) .. " studs)",
                Time = 2,
            })
            return true
        end),
    }
end)()

-- ==================== FPS TIMER MODULE ====================
local function createSimpleTimer()
    local StatsService = game:GetService("Stats")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "IruzFPS"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    if not pcall(function() screenGui.Parent = player:WaitForChild("PlayerGui") end) then
        return nil
    end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 147, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 0.7
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            frame.BackgroundTransparency = 0.5
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    frame.BackgroundTransparency = 0.7
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    
    local statsText = Instance.new("TextLabel")
    statsText.Size = UDim2.new(1, -10, 0.5, 0)
    statsText.Position = UDim2.new(0, 5, 0, 0)
    statsText.BackgroundTransparency = 1
    statsText.TextColor3 = Color3.new(1, 1, 1)
    statsText.Font = Enum.Font.GothamBold
    statsText.TextSize = 14
    statsText.TextXAlignment = Enum.TextXAlignment.Center
    statsText.Text = "FPS: 60 | Ping: 0ms"
    statsText.Parent = frame
    
    local timerText = Instance.new("TextLabel")
    timerText.Size = UDim2.new(1, -10, 0.5, 0)
    timerText.Position = UDim2.new(0, 5, 0.5, 0)
    timerText.BackgroundTransparency = 1
    timerText.TextColor3 = Color3.new(1, 1, 1)
    timerText.Font = Enum.Font.GothamBold
    timerText.TextSize = 14
    timerText.TextXAlignment = Enum.TextXAlignment.Center
    timerText.Text = "Client Time: 0h 0m 0s"
    timerText.Parent = frame
    
    local startTime = tick()
    local frameCount = 0
    local lastUpdate = tick()
    local currentFPS = 0
    
    local function getPing()
        local ping = 0
        
        pcall(function()
            local stats = StatsService
            local networkStats = stats:FindFirstChild("Network")
            if networkStats then
                local serverStats = networkStats:FindFirstChild("ServerStatsItem")
                if serverStats then
                    ping = math.floor(serverStats:GetValue())
                end
            end
        end)
        
        if ping == 0 then
            pcall(function()
                local performanceStats = StatsService:FindFirstChild("PerformanceStats")
                if performanceStats then
                    local pingStat = performanceStats:FindFirstChild("Ping")
                    if pingStat then
                        ping = math.floor(pingStat:GetValue())
                    end
                end
            end)
        end
        
        if ping == 0 then
            ping = 50
        end
        
        return ping
    end
    
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        
        local currentTime = tick()
        
        if currentTime - lastUpdate >= 0.5 then
            currentFPS = math.floor(frameCount / (currentTime - lastUpdate))
            frameCount = 0
            lastUpdate = currentTime
            
            local ping = getPing()
            statsText.Text = string.format("FPS: %d | Ping: %dms", currentFPS, ping)
        end
        
        local elapsed = currentTime - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)
        
        timerText.Text = string.format("Client Time: %dh %dm %ds", hours, minutes, seconds)
    end)
    
    return screenGui
end

-- ==================== SERVER UTILITIES ====================
local function getServerLink()
    return string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)
end

local function joinServerByPlaceId(targetPlaceId, modeName)
    local success, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
            targetPlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)

    if success and servers and servers.data and #servers.data > 0 then
        local availableServers = {}
        for _, server in ipairs(servers.data) do
            if server.playing < server.maxPlayers then
                table.insert(availableServers, server)
            end
        end

        if #availableServers > 0 then
            table.sort(availableServers, function(a, b) return a.playing > b.playing end)
            local targetServer = availableServers[1]

            Library:Notify({
                Title = "Joining " .. modeName,
                Description = "Teleporting to server with " ..
                    targetServer.playing .. "/" .. targetServer.maxPlayers .. " players",
                Time = 3,
            })

            TeleportService:TeleportToPlaceInstance(targetPlaceId, targetServer.id, player)
        else
            Library:Notify({
                Title = "Join Failed",
                Description = "No available " .. modeName .. " servers found!",
                Time = 3,
            })
        end
    else
        Library:Notify({
            Title = "Join Failed",
            Description = "Could not fetch " .. modeName .. " servers!",
            Time = 3,
        })
    end
end

-- ==================== CREATE WINDOW ====================
local Window = Library:CreateWindow({
    Title = "Iruz - Evade | Modded",
    Footer = "version: 1.5.1 Modded",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- ==================== TABS ====================
local Tabs = {
    Info = Window:AddTab("Info", "info"),
    Main = Window:AddTab("Main", "zap"),
    Teleport = Window:AddTab("Teleport", "navigation"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Server = Window:AddTab("Server", "server"),
    Misc = Window:AddTab("Misc", "settings"),
    Keybinds = Window:AddTab("Keybinds", "keyboard"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- ==================== TAB INFO ====================
local CommunityGroup = Tabs.Info:AddLeftGroupbox("Discord & Community", "users")
CommunityGroup:AddLabel("Join our Discord for:")
CommunityGroup:AddLabel("- Latest script updates")
CommunityGroup:AddLabel("- Support & help")
CommunityGroup:AddLabel("- Bug reports")
CommunityGroup:AddLabel("- Feature requests")
CommunityGroup:AddLabel("- Community chat")
CommunityGroup:AddDivider()
CommunityGroup:AddButton({
    Text = "Copy Discord Link",
    Func = SafeWrapper("CopyDiscord", function()
        local discordLink = "https://discord.gg/kJ552CMBx4"
        local success = pcall(function()
            setclipboard(discordLink)
        end)

        if success then
            Library:Notify({
                Title = "Discord Link Copied!",
                Description = "Link copied to clipboard!",
                Time = 3,
            })
        else
            Library:Notify({
                Title = "Discord Link",
                Description = "Join: " .. discordLink,
                Time = 4,
            })
        end
    end),
    DoubleClick = false,
})
CommunityGroup:AddButton({
    Text = "Join Discord Server",
    Func = SafeWrapper("JoinDiscord", function()
        Library:Notify({
            Title = "Discord Server",
            Description = "Join: discord.gg/kJ552CMBx4",
            Time = 4,
        })
    end),
    DoubleClick = false,
})

local CreditsGroup = Tabs.Info:AddRightGroupbox("Credits", "heart")
CreditsGroup:AddLabel("Script Created by:")
CreditsGroup:AddLabel("• Iruz Team")
CreditsGroup:AddLabel("• Iruz Hub Integration")
CreditsGroup:AddDivider()
CreditsGroup:AddLabel("Special Thanks:")
CreditsGroup:AddLabel("• Obsidian UI Library")
CreditsGroup:AddLabel("• All testers & contributors")
CreditsGroup:AddLabel("• Discord community")
CreditsGroup:AddDivider()
CreditsGroup:AddLabel("Version:")
CreditsGroup:AddLabel("Iruz Evade 1.5.1")
CreditsGroup:AddLabel("Iruz Edition")
CreditsGroup:AddDivider()
CreditsGroup:AddButton({
    Text = "Report Bug",
    Func = SafeWrapper("ReportBug", function()
        Library:Notify({
            Title = "Bug Report",
            Description = "Please report bugs in Discord",
            Time = 3,
        })
    end),
    DoubleClick = false,
})

local KeybindGroup = Tabs.Info:AddLeftGroupbox("Keybind Features", "keyboard")
KeybindGroup:AddLabel("MAIN KEYBINDS")
KeybindGroup:AddLabel("Menu Toggle: RightShift")
KeybindGroup:AddDivider()
KeybindGroup:AddLabel("Iruz FEATURES")
KeybindGroup:AddLabel("Fly: Customizable in Keybinds tab")
KeybindGroup:AddLabel("Anti Nextbot: Customizable in Keybinds tab")
KeybindGroup:AddLabel("Gravity: Customizable in Keybinds tab")
KeybindGroup:AddLabel("Auto Drink: Customizable in Keybinds tab")
KeybindGroup:AddLabel("Lag Switch: Customizable in Keybinds tab")
KeybindGroup:AddLabel("Camera Stretch: Customizable in Keybinds tab")
KeybindGroup:AddDivider()
KeybindGroup:AddLabel("HOLD KEYS")
KeybindGroup:AddLabel("Hold Space Jump: Space (Hold)")

local TipsGroup = Tabs.Info:AddRightGroupbox("Quick Tips", "lightbulb")
TipsGroup:AddLabel("HOW TO USE KEYBINDS:")
TipsGroup:AddLabel("1. Go to 'Keybinds' tab to customize")
TipsGroup:AddLabel("2. Set your preferred keys")
TipsGroup:AddLabel("3. All changes save automatically")
TipsGroup:AddDivider()
TipsGroup:AddLabel("TIPS:")
TipsGroup:AddLabel("- Fly: WASD + Space/Shift")
TipsGroup:AddLabel("- Hold Space Jump: Enable toggle then hold Space")
TipsGroup:AddLabel("- Gravity: Adjust with modifier keys")
TipsGroup:AddLabel("- Camera Stretch: Toggle effect")
TipsGroup:AddDivider()
TipsGroup:AddButton({
    Text = "Go to Keybinds Tab",
    Func = SafeWrapper("GoToKeybinds", function()
        Window:SelectTab(Tabs.Keybinds)
    end),
    DoubleClick = false,
})

-- ==================== KEYBINDS TAB ====================
local KeybindMainGroup = Tabs.Keybinds:AddLeftGroupbox("Iruz Hub Keybinds", "keyboard")

local keyOptions = {
    "F", "G", "H", "J", "K", "L", "N", "M", 
    "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",
    "A", "S", "D", "Z", "X", "C", "V", "B",
    "LeftControl", "RightControl", "LeftAlt", "RightAlt", "LeftShift", "RightShift",
    "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
    "Space", "Tab", "CapsLock", "Escape"
}

-- Fly Keybind
KeybindMainGroup:AddLabel("Fly Key")
KeybindMainGroup:AddDropdown("FlyKeyDropdown", {
    Values = keyOptions,
    Default = "F",
    Text = "Select Key",
    Callback = SafeWrapper("FlyKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode then
            KeybindManager:SetKeybind("Fly", keyCode)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Fly key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- Anti Nextbot Keybind
KeybindMainGroup:AddLabel("Anti Nextbot Key")
KeybindMainGroup:AddDropdown("AntiNextbotKeyDropdown", {
    Values = keyOptions,
    Default = "N",
    Text = "Select Key",
    Callback = SafeWrapper("AntiNextbotKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode then
            KeybindManager:SetKeybind("AntiNextbot", keyCode)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Anti Nextbot key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- Gravity Keybind
KeybindMainGroup:AddLabel("Gravity Key")
KeybindMainGroup:AddDropdown("GravityKeyDropdown", {
    Values = keyOptions,
    Default = "G",
    Text = "Select Key",
    Callback = SafeWrapper("GravityKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode then
            KeybindManager:SetKeybind("Gravity", keyCode)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Gravity key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- Auto Drink Keybind
KeybindMainGroup:AddLabel("Auto Drink Key")
KeybindMainGroup:AddDropdown("AutoDrinkKeyDropdown", {
    Values = keyOptions,
    Default = "D",
    Text = "Select Key",
    Callback = SafeWrapper("AutoDrinkKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode then
            KeybindManager:SetKeybind("AutoDrink", keyCode)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Auto Drink key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- Lag Switch Keybind
KeybindMainGroup:AddLabel("Lag Switch Key")
KeybindMainGroup:AddDropdown("LagSwitchKeyDropdown", {
    Values = keyOptions,
    Default = "L",
    Text = "Select Key",
    Callback = SafeWrapper("LagSwitchKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode then
            KeybindManager:SetKeybind("LagSwitch", keyCode)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Lag Switch key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- Camera Stretch Keybind
KeybindMainGroup:AddLabel("Camera Stretch Key")
KeybindMainGroup:AddDropdown("CameraStretchKeyDropdown", {
    Values = keyOptions,
    Default = "T",
    Text = "Select Key",
    Callback = SafeWrapper("CameraStretchKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode then
            KeybindManager:SetKeybind("CameraStretch", keyCode)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Camera Stretch key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- Infinite Slide Keybind
KeybindMainGroup:AddLabel("Infinite Slide Key")
KeybindMainGroup:AddDropdown("InfiniteSlideKeyDropdown", {
    Values = keyOptions,
    Default = "I",
    Text = "Select Key",
    Callback = SafeWrapper("InfiniteSlideKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode then
            KeybindManager:SetKeybind("InfiniteSlide", keyCode)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Infinite Slide key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- ==================== COMBINATION KEYBINDS ====================
local ComboKeybindGroup = Tabs.Keybinds:AddRightGroupbox("Combination Keybinds", "keyboard")

local modifierOptions = {"LeftControl", "RightControl", "LeftAlt", "RightAlt", "LeftShift", "RightShift"}

-- No Fog
ComboKeybindGroup:AddLabel("No Fog (Ctrl + F)")
ComboKeybindGroup:AddDropdown("NoFogModifierDropdown", {
    Values = modifierOptions,
    Default = "LeftControl",
    Text = "Modifier Key",
    Callback = SafeWrapper("NoFogModifierCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("NoFog") then
            local current = KeybindManager:GetKeybind("NoFog")
            current[1] = keyCode
            KeybindManager:SetKeybind("NoFog", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "No Fog modifier set to: " .. value,
                Time = 2,
            })
        end
    end)
})

ComboKeybindGroup:AddDropdown("NoFogKeyDropdown", {
    Values = keyOptions,
    Default = "F",
    Text = "Main Key",
    Callback = SafeWrapper("NoFogKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("NoFog") then
            local current = KeybindManager:GetKeybind("NoFog")
            current[2] = keyCode
            KeybindManager:SetKeybind("NoFog", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "No Fog key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- No Camera Shake
ComboKeybindGroup:AddLabel("No Camera Shake (Ctrl + S)")
ComboKeybindGroup:AddDropdown("NoShakeModifierDropdown", {
    Values = modifierOptions,
    Default = "LeftControl",
    Text = "Modifier Key",
    Callback = SafeWrapper("NoShakeModifierCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("NoCameraShake") then
            local current = KeybindManager:GetKeybind("NoCameraShake")
            current[1] = keyCode
            KeybindManager:SetKeybind("NoCameraShake", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "No Camera Shake modifier set to: " .. value,
                Time = 2,
            })
        end
    end)
})

ComboKeybindGroup:AddDropdown("NoShakeKeyDropdown", {
    Values = keyOptions,
    Default = "S",
    Text = "Main Key",
    Callback = SafeWrapper("NoShakeKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("NoCameraShake") then
            local current = KeybindManager:GetKeybind("NoCameraShake")
            current[2] = keyCode
            KeybindManager:SetKeybind("NoCameraShake", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "No Camera Shake key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- FPS Timer
ComboKeybindGroup:AddLabel("FPS Timer (Ctrl + H)")
ComboKeybindGroup:AddDropdown("FpsTimerModifierDropdown", {
    Values = modifierOptions,
    Default = "LeftControl",
    Text = "Modifier Key",
    Callback = SafeWrapper("FpsTimerModifierCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("FpsTimer") then
            local current = KeybindManager:GetKeybind("FpsTimer")
            current[1] = keyCode
            KeybindManager:SetKeybind("FpsTimer", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "FPS Timer modifier set to: " .. value,
                Time = 2,
            })
        end
    end)
})

ComboKeybindGroup:AddDropdown("FpsTimerKeyDropdown", {
    Values = keyOptions,
    Default = "H",
    Text = "Main Key",
    Callback = SafeWrapper("FpsTimerKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("FpsTimer") then
            local current = KeybindManager:GetKeybind("FpsTimer")
            current[2] = keyCode
            KeybindManager:SetKeybind("FpsTimer", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "FPS Timer key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- ==================== UTILITY KEYBINDS ====================
local UtilityKeybindGroup = Tabs.Keybinds:AddRightGroupbox("Utility Keybinds", "settings")

-- Toggle Lag Enable
UtilityKeybindGroup:AddLabel("Toggle Lag Enable")
UtilityKeybindGroup:AddDropdown("ToggleLagKeyDropdown", {
    Values = keyOptions,
    Default = "F12",
    Text = "Select Key",
    Callback = SafeWrapper("ToggleLagKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode then
            KeybindManager:SetKeybind("ToggleLagEnable", keyCode)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Toggle Lag Enable key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- Increase Gravity
UtilityKeybindGroup:AddLabel("Increase Gravity (Ctrl + G)")
UtilityKeybindGroup:AddDropdown("IncGravityModifierDropdown", {
    Values = modifierOptions,
    Default = "LeftControl",
    Text = "Modifier Key",
    Callback = SafeWrapper("IncGravityModifierCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("IncreaseGravity") then
            local current = KeybindManager:GetKeybind("IncreaseGravity")
            current[1] = keyCode
            KeybindManager:SetKeybind("IncreaseGravity", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Increase Gravity modifier set to: " .. value,
                Time = 2,
            })
        end
    end)
})

UtilityKeybindGroup:AddDropdown("IncGravityKeyDropdown", {
    Values = keyOptions,
    Default = "G",
    Text = "Main Key",
    Callback = SafeWrapper("IncGravityKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("IncreaseGravity") then
            local current = KeybindManager:GetKeybind("IncreaseGravity")
            current[2] = keyCode
            KeybindManager:SetKeybind("IncreaseGravity", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Increase Gravity key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- Decrease Gravity
UtilityKeybindGroup:AddLabel("Decrease Gravity (Alt + G)")
UtilityKeybindGroup:AddDropdown("DecGravityModifierDropdown", {
    Values = modifierOptions,
    Default = "LeftAlt",
    Text = "Modifier Key",
    Callback = SafeWrapper("DecGravityModifierCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("DecreaseGravity") then
            local current = KeybindManager:GetKeybind("DecreaseGravity")
            current[1] = keyCode
            KeybindManager:SetKeybind("DecreaseGravity", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Decrease Gravity modifier set to: " .. value,
                Time = 2,
            })
        end
    end)
})

UtilityKeybindGroup:AddDropdown("DecGravityKeyDropdown", {
    Values = keyOptions,
    Default = "G",
    Text = "Main Key",
    Callback = SafeWrapper("DecGravityKeyCallback", function(value)
        local keyCode = Enum.KeyCode[value]
        if keyCode and KeybindManager:GetKeybind("DecreaseGravity") then
            local current = KeybindManager:GetKeybind("DecreaseGravity")
            current[2] = keyCode
            KeybindManager:SetKeybind("DecreaseGravity", current)
            Library:Notify({
                Title = "Keybind Updated",
                Description = "Decrease Gravity key set to: " .. value,
                Time = 2,
            })
        end
    end)
})

-- Reset All Keybinds Button
UtilityKeybindGroup:AddDivider()
UtilityKeybindGroup:AddButton({
    Text = "Reset All to Default",
    Func = SafeWrapper("ResetKeybinds", function()
        KeybindManager:ResetToDefault()
        Library:Notify({
            Title = "Keybinds Reset",
            Description = "All keybinds reset to default",
            Time = 3,
        })
    end),
    DoubleClick = true,
})

-- ==================== MAIN TAB ====================
-- Auto Features
local AutoGroup = Tabs.Main:AddLeftGroupbox("Auto Features", "zap")
AutoGroup:AddToggle("AutoSelfRevive", {
    Text = "Auto Self Revive",
    Default = false,
    Callback = SafeWrapper("AutoSelfReviveToggle", function(state)
        if state then
            AutoSelfReviveModule.Start()
        else
            AutoSelfReviveModule.Stop()
        end
    end)
})

AutoGroup:AddDropdown("SelfReviveMethod", {
    Values = { "Spawnpoint", "Fake Revive" },
    Default = "Spawnpoint",
    Text = "Self Revive Method",
    Callback = SafeWrapper("SelfReviveMethodCallback", function(value)
        AutoSelfReviveModule.SetMethod(value)
    end)
})

AutoGroup:AddDivider()

AutoGroup:AddToggle("FastRevive", {
    Text = "Fast Revive",
    Default = false,
    Callback = SafeWrapper("FastReviveToggle", function(state)
        if state then
            FastReviveModule.Start()
        else
            FastReviveModule.Stop()
        end
    end)
})

AutoGroup:AddDropdown("FastReviveMethod", {
    Values = { "Auto", "Interact" },
    Default = "Interact",
    Text = "Fast Revive Method",
    Callback = SafeWrapper("FastReviveMethodCallback", function(value)
        FastReviveModule.SetMethod(value)
    end)
})

AutoGroup:AddDivider()

AutoGroup:AddToggle("AutoFarmMoney", {
    Text = "Auto Farm Money",
    Default = false,
    Callback = SafeWrapper("AutoFarmMoneyToggle", function(state)
        if state then
            AutoFarmModule.StartFarmMoney()
        else
            AutoFarmModule.StopFarmMoney()
        end
    end)
})

-- Movement
local MovementGroup = Tabs.Main:AddRightGroupbox("Movement", "move")
MovementGroup:AddToggle("HoldSpaceJump", {
    Text = "Hold Space Jump",
    Default = false,
    Callback = SafeWrapper("HoldSpaceJumpToggle", function(state)
        getgenv().autoJumpEnabled = state
        
        if state then
            IruzHub.LoadBhop(
                getgenv().autoJumpEnabled,
                getgenv().bhopMode,
                getgenv().bhopAccelValue,
                getgenv().jumpInterval,
                getgenv().autoJumpType,
                Library
            )
            Library:Notify({
                Title = "Hold Space Jump",
                Description = "✓ Enabled\n✓ Hold Space key to bunny hop\n✓ Works only when key is held",
                Time = 4,
            })
        else
            IruzHub.UnloadBhop(Library)
            Library:Notify({
                Title = "Hold Space Jump",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

MovementGroup:AddDropdown("BhopMode", {
    Values = { "Normal", "Acceleration" },
    Default = "Normal",
    Text = "Jump Mode",
    Callback = SafeWrapper("BhopModeCallback", function(value)
        getgenv().bhopMode = value
        if getgenv().autoJumpEnabled then
            IruzHub.UnloadBhop(Library)
            IruzHub.LoadBhop(
                getgenv().autoJumpEnabled,
                getgenv().bhopMode,
                getgenv().bhopAccelValue,
                getgenv().jumpInterval,
                getgenv().autoJumpType,
                Library
            )
        end
        
        if value == "Acceleration" then
            Library:Notify({
                Title = "Acceleration Mode",
                Description = "✓ Reduced friction when jumping\n✓ Faster movement while holding space",
                Time = 3,
            })
        end
    end)
})

MovementGroup:AddSlider("BhopAcceleration", {
    Text = "Acceleration Strength",
    Default = -0.1,
    Min = -5,
    Max = -0.01,
    Rounding = 2,
    Callback = SafeWrapper("BhopAccelerationCallback", function(value)
        getgenv().bhopAccelValue = value
    end)
})

MovementGroup:AddDivider()

MovementGroup:AddDropdown("JumpType", {
    Values = { "Normal", "Realistic" },
    Default = "Normal",
    Text = "Jump Type",
    Callback = SafeWrapper("JumpTypeCallback", function(value)
        getgenv().autoJumpType = value
    end)
})

MovementGroup:AddSlider("JumpInterval", {
    Text = "Jump Interval",
    Default = 0.1,
    Min = 0.05,
    Max = 0.5,
    Rounding = 2,
    Suffix = "s",
    Callback = SafeWrapper("JumpIntervalCallback", function(value)
        getgenv().jumpInterval = value
    end)
})

MovementGroup:AddDivider()

MovementGroup:AddToggle("InfiniteSlide", {
    Text = "Infinite Slide",
    Default = false,
    Callback = SafeWrapper("InfiniteSlideToggle", function(state)
        infiniteSlideEnabled = state
        
        local keys = {
            "Friction", "AirStrafeAcceleration", "JumpHeight", "RunDeaccel",
            "JumpSpeedMultiplier", "JumpCap", "SprintCap", "WalkSpeedMultiplier",
            "BhopEnabled", "Speed", "AirAcceleration", "RunAccel", "SprintAcceleration"
        }

        local function hasAll(tbl)
            if type(tbl) ~= "table" then return false end
            for _, k in ipairs(keys) do
                if rawget(tbl, k) == nil then
                    return false
                end
            end
            return true
        end

        local function setFriction(value)
            for _, t in ipairs(cachedTables) do
                pcall(function() t.Friction = value end)
            end
        end

        local function updatePlayerModel()
            local GameFolder = workspace:FindFirstChild("Game")
            plrModel = GameFolder and GameFolder:FindFirstChild("Players") and GameFolder.Players:FindFirstChild(player.Name)
        end

        local function onHeartbeat()
            if not infiniteSlideEnabled then return end
            if not plrModel then
                setFriction(5)
                return
            end
            
            local success, currentState = pcall(function()
                return plrModel:GetAttribute("State")
            end)
            
            if success and currentState == "Slide" then
                pcall(function() plrModel:SetAttribute("State", "EmotingSlide") end)
                setFriction(slideFrictionValue)
            elseif success and currentState == "EmotingSlide" then
                setFriction(slideFrictionValue)
            else
                setFriction(5)
            end
        end

        if state then
            for _, obj in ipairs(getgc(true)) do
                if hasAll(obj) then
                    table.insert(cachedTables, obj)
                end
            end
            
            updatePlayerModel()
            
            if slideConnection then
                slideConnection:Disconnect()
            end
            
            slideConnection = RunService.Heartbeat:Connect(onHeartbeat)
            player.CharacterAdded:Connect(function()
                task.wait(0.1)
                updatePlayerModel()
            end)
        else
            if slideConnection then
                slideConnection:Disconnect()
                slideConnection = nil
            end
            setFriction(5)
            cachedTables = {}
            plrModel = nil
        end
    end)
})

MovementGroup:AddSlider("SlideSpeed", {
    Text = "Slide Speed",
    Default = -8,
    Min = -500,
    Max = -1,
    Rounding = 0,
    Callback = SafeWrapper("SlideSpeedCallback", function(value)
        slideFrictionValue = value
    end)
})

MovementGroup:AddDivider()
MovementGroup:AddSlider("Speed", {
    Text = "Speed",
    Default = 1500,
    Min = 1500,
    Max = 10000,
    Rounding = 0,
    Callback = SafeWrapper("SpeedCallback", function(val)
        local requiredFields = {
            Friction=true, AirStrafeAcceleration=true, JumpHeight=true, RunDeaccel=true,
            JumpSpeedMultiplier=true, JumpCap=true, SprintCap=true, WalkSpeedMultiplier=true,
            BhopEnabled=true, Speed=true, AirAcceleration=true, RunAccel=true, SprintAcceleration=true
        }
        
        local function getMatchingTables()
            local matched = {}
            for _, obj in pairs(getgc(true)) do
                if typeof(obj) == "table" then
                    local ok = true
                    for field in pairs(requiredFields) do
                        if rawget(obj, field) == nil then
                            ok = false
                            break
                        end
                    end
                    if ok then
                        table.insert(matched, obj)
                    end
                end
            end
            return matched
        end
        
        for _, tableObj in ipairs(getMatchingTables()) do
            pcall(function() tableObj.Speed = val end)
        end
    end)
})

MovementGroup:AddSlider("JumpCap", {
    Text = "Jump Cap",
    Default = 1,
    Min = 0.1,
    Max = 5000,
    Rounding = 1,
    Callback = SafeWrapper("JumpCapCallback", function(val)
        local requiredFields = {
            Friction=true, AirStrafeAcceleration=true, JumpHeight=true, RunDeaccel=true,
            JumpSpeedMultiplier=true, JumpCap=true, SprintCap=true, WalkSpeedMultiplier=true,
            BhopEnabled=true, Speed=true, AirAcceleration=true, RunAccel=true, SprintAcceleration=true
        }
        
        local function getMatchingTables()
            local matched = {}
            for _, obj in pairs(getgc(true)) do
                if typeof(obj) == "table" then
                    local ok = true
                    for field in pairs(requiredFields) do
                        if rawget(obj, field) == nil then
                            ok = false
                            break
                        end
                    end
                    if ok then
                        table.insert(matched, obj)
                    end
                end
            end
            return matched
        end
        
        for _, tableObj in ipairs(getMatchingTables()) do
            pcall(function() tableObj.JumpCap = val end)
        end
    end)
})

MovementGroup:AddSlider("StrafeAccel", {
    Text = "Strafe Acceleration",
    Default = 187,
    Min = 1,
    Max = 1000000,
    Rounding = 0,
    Callback = SafeWrapper("StrafeAccelCallback", function(val)
        local requiredFields = {
            Friction=true, AirStrafeAcceleration=true, JumpHeight=true, RunDeaccel=true,
            JumpSpeedMultiplier=true, JumpCap=true, SprintCap=true, WalkSpeedMultiplier=true,
            BhopEnabled=true, Speed=true, AirAcceleration=true, RunAccel=true, SprintAcceleration=true
        }
        
        local function getMatchingTables()
            local matched = {}
            for _, obj in pairs(getgc(true)) do
                if typeof(obj) == "table" then
                    local ok = true
                    for field in pairs(requiredFields) do
                        if rawget(obj, field) == nil then
                            ok = false
                            break
                        end
                    end
                    if ok then
                        table.insert(matched, obj)
                    end
                end
            end
            return matched
        end
        
        for _, tableObj in ipairs(getMatchingTables()) do
            pcall(function() tableObj.AirStrafeAcceleration = val end)
        end
    end)
})

-- ==================== TELEPORT TAB ====================
local TeleportAutoGroup = Tabs.Teleport:AddLeftGroupbox("Auto Place Teleporter", "repeat")
TeleportAutoGroup:AddToggle("AutoPlaceTeleporter", {
    Text = "Auto Place Every Round",
    Default = false,
    Callback = SafeWrapper("AutoPlaceTeleporterToggle", function(value)
        autoPlaceTeleporterEnabled = value
        if value then
            Library:Notify({
                Title = "Auto Place Enabled",
                Description = "Will place " .. autoPlaceTeleporterType .. " teleporter every round",
                Time = 3,
            })
        end
    end)
})

TeleportAutoGroup:AddDropdown("TeleporterType", {
    Values = { "Far", "Sky" },
    Default = "Far",
    Text = "Teleporter Type",
    Callback = SafeWrapper("TeleporterTypeCallback", function(value)
        autoPlaceTeleporterType = value
        Library:Notify({
            Title = "Type Changed",
            Description = "Auto place will use " .. value .. " spot",
            Time = 2,
        })
    end)
})

local TeleportPlaceGroup = Tabs.Teleport:AddLeftGroupbox("Teleport to Spot", "map-pin")
TeleportPlaceGroup:AddButton({
    Text = "Place Teleporter Far",
    Func = SafeWrapper("PlaceTeleporterFar", function()
        TeleportModule.PlaceTeleporter("Far", Library)
    end),
    DoubleClick = false,
})
TeleportPlaceGroup:AddButton({
    Text = "Place Teleporter Sky",
    Func = SafeWrapper("PlaceTeleporterSky", function()
        TeleportModule.PlaceTeleporter("Sky", Library)
    end),
    DoubleClick = false,
})
TeleportPlaceGroup:AddButton({
    Text = "Teleport Player To Sky",
    Func = SafeWrapper("TeleportToSky", function()
        TeleportModule.TeleportPlayer("Sky", Library)
    end),
    DoubleClick = false,
})
TeleportPlaceGroup:AddButton({
    Text = "Teleport Player To Far",
    Func = SafeWrapper("TeleportToFar", function()
        TeleportModule.TeleportPlayer("Far", Library)
    end),
    DoubleClick = false,
})

local TeleportObjectiveGroup = Tabs.Teleport:AddRightGroupbox("Objective Teleports", "target")
TeleportObjectiveGroup:AddButton({
    Text = "Teleport to Objective",
    Func = SafeWrapper("TeleportToObjective", function()
        TeleportFeaturesModule.TeleportToRandomObjective()
    end),
    DoubleClick = false,
})
TeleportObjectiveGroup:AddButton({
    Text = "Teleport to Nearest Ticket",
    Func = SafeWrapper("TeleportToNearestTicket", function()
        TeleportFeaturesModule.TeleportToNearestTicket()
    end),
    DoubleClick = false,
})

local TeleportPlayerGroup = Tabs.Teleport:AddRightGroupbox("Player Teleports", "users")
local playerList = TeleportFeaturesModule.GetPlayerList()
local selectedPlayerName = playerList[1] or "No players available"

local PlayerDropdown = TeleportPlayerGroup:AddDropdown("PlayerList", {
    Values = playerList,
    Default = selectedPlayerName,
    Text = "Select Player",
    Callback = SafeWrapper("PlayerListCallback", function(value)
        if value ~= "No players available" then
            selectedPlayerName = value
        end
    end)
})

TeleportPlayerGroup:AddButton({
    Text = "Teleport to Selected Player",
    Func = SafeWrapper("TeleportToSelectedPlayer", function()
        TeleportFeaturesModule.TeleportToPlayer(selectedPlayerName)
    end),
    DoubleClick = false,
})
TeleportPlayerGroup:AddButton({
    Text = "Refresh Player List",
    Func = SafeWrapper("RefreshPlayerList", function()
        local newList = TeleportFeaturesModule.GetPlayerList()
        PlayerDropdown:SetValues(newList)
        if newList[1] then
            selectedPlayerName = newList[1]
            PlayerDropdown:SetValue(newList[1])
        end
        Library:Notify({
            Title = "Player List",
            Description = "Player list refreshed!",
            Time = 2,
        })
    end),
    DoubleClick = false,
})
TeleportPlayerGroup:AddButton({
    Text = "Teleport to Random Player",
    Func = SafeWrapper("TeleportToRandomPlayer", function()
        TeleportFeaturesModule.TeleportToRandomPlayer()
    end),
    DoubleClick = false,
})

local TeleportDownedGroup = Tabs.Teleport:AddRightGroupbox("Downed Player Teleports", "heart")
TeleportDownedGroup:AddButton({
    Text = "Teleport to Nearest Downed Player",
    Func = SafeWrapper("TeleportToNearestDowned", function()
        TeleportFeaturesModule.TeleportToNearestDowned()
    end),
    DoubleClick = false,
})

-- ==================== VISUALS TAB ====================
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("ESP", "eye")
ESPGroup:AddToggle("ESPPlayer", {
    Text = "ESP Player",
    Default = false,
    Callback = SafeWrapper("ESPPlayerToggle", function(state)
        local function getDistance(pos)
            local char = safeGetCharacter(player)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            return hrp and (pos - hrp.Position).Magnitude or nil
        end

        local function createPlayerESP(part)
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "PlayerESP"
            billboard.Adornee = part
            billboard.Size = UDim2.new(0, 180, 0, 25)
            billboard.StudsOffset = Vector3.new(0, 3.2, 0)
            billboard.AlwaysOnTop = true
            billboard.LightInfluence = 0
            billboard.Parent = part
            
            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextStrokeTransparency = 0.25
            label.TextScaled = true
            label.RichText = true
            label.Font = Enum.Font.GothamSemibold
            label.Text = ""
            label.TextColor3 = Color3.fromRGB(100, 180, 255)
            label.Parent = billboard
            
            return label
        end

        local function removeAllESPs()
            local folder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
            if folder then
                for _, char in ipairs(folder:GetChildren()) do
                    if char:IsA("Model") then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local existing = hrp:FindFirstChild("PlayerESP")
                            if existing then
                                existing:Destroy()
                            end
                        end
                    end
                end
            end
        end

        if state then
            if playerESPThread then
                coroutine.close(playerESPThread)
            end
            
            playerESPThread = coroutine.create(function()
                while state do
                    local folder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
                    if folder then
                        for _, char in ipairs(folder:GetChildren()) do
                            if char:IsA("Model") and char:GetAttribute("Team") ~= "Nextbot" and char.Name ~= player.Name then
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    local espGui = hrp:FindFirstChild("PlayerESP")
                                    local label = espGui and espGui:FindFirstChild("Label") or createPlayerESP(hrp)
                                    local dist = getDistance(hrp.Position) or 0
                                    local downed = char:GetAttribute("Downed")
                                    local downedTime = tonumber(char:GetAttribute("DownedTimeLeft")) or 0
                                    local name = char.Name
                                    local displayText, color
                                    
                                    if downed == true then
                                        color = Color3.fromRGB(255, 120, 120)
                                        displayText = string.format('%s <font size="16">(Downed %.0f)</font>', name, downedTime)
                                    else
                                        color = Color3.fromRGB(120, 255, 120)
                                        displayText = string.format('%s\n%.0f studs', name, dist)
                                    end
                                    
                                    if label.Text ~= displayText or label.TextColor3 ~= color then
                                        label.Text = displayText
                                        label.TextColor3 = color
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
            
            coroutine.resume(playerESPThread)
        else
            removeAllESPs()
            if playerESPThread then
                coroutine.close(playerESPThread)
                playerESPThread = nil
            end
        end
    end)
})

ESPGroup:AddDivider()
ESPGroup:AddToggle("ESPNextbot", {
    Text = "ESP Nextbot",
    Default = false,
    Callback = SafeWrapper("ESPNextbotToggle", function(state)
        local function getDistance(pos)
            local char = safeGetCharacter(player)
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            return hrp and (pos - hrp.Position).Magnitude or nil
        end

        local function getESPPart(obj)
            if obj:IsA("BasePart") then
                return obj
            elseif obj:IsA("Model") then
                return obj:FindFirstChild("Root") or obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            end
        end

        local function getColorByDistance(dist)
            if dist <= 12 then
                return Color3.fromRGB(50, 50, 50)
            elseif dist <= 60 then
                local t = (dist - 12) / 48
                return Color3.fromRGB(255, 120 + (255 - 120) * t, 120)
            else
                return Color3.fromRGB(200, 150, 255)
            end
        end

        local function createESP(part)
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "NextbotESP"
            billboard.Adornee = part
            billboard.Size = UDim2.new(0, 180, 0, 25)
            billboard.StudsOffset = Vector3.new(0, 3.2, 0)
            billboard.AlwaysOnTop = true
            billboard.LightInfluence = 0
            billboard.Parent = part
            
            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextStrokeTransparency = 0.25
            label.TextScaled = true
            label.Font = Enum.Font.GothamSemibold
            label.Text = ""
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.Parent = billboard
            
            return billboard
        end

        local function removeAllNextbotESP()
            local folder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
            if folder then
                for _, npc in ipairs(folder:GetChildren()) do
                    local part = getESPPart(npc)
                    if part then
                        local existing = part:FindFirstChild("NextbotESP")
                        if existing then
                            existing:Destroy()
                        end
                    end
                end
            end
        end

        if state then
            if nextbotESPThread then
                coroutine.close(nextbotESPThread)
            end
            
            nextbotESPThread = coroutine.create(function()
                while state do
                    local folder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
                    if folder then
                        for _, npc in ipairs(folder:GetChildren()) do
                            if npc:GetAttribute("Team") == "Nextbot" then
                                local part = getESPPart(npc)
                                if part then
                                    local billboard = part:FindFirstChild("NextbotESP") or createESP(part)
                                    local label = billboard:FindFirstChild("Label")
                                    if label then
                                        local dist = getDistance(part.Position)
                                        label.Text = dist and string.format("%s\n%.0f studs", npc.Name, dist) or npc.Name
                                        label.TextColor3 = dist and getColorByDistance(dist) or Color3.fromRGB(255, 255, 255)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
            
            coroutine.resume(nextbotESPThread)
        else
            removeAllNextbotESP()
            if nextbotESPThread then
                coroutine.close(nextbotESPThread)
                nextbotESPThread = nil
            end
        end
    end)
})

local TracerGroup = Tabs.Visuals:AddRightGroupbox("Tracers", "target")
TracerGroup:AddToggle("TracerDowned", {
    Text = "Tracer Downed Players",
    Default = false,
    Callback = SafeWrapper("TracerDownedToggle", function(state)
        local Camera = workspace.CurrentCamera
        
        local function cleanup()
            for _, line in ipairs(tracerLines) do
                if line then
                    line:Remove()
                end
            end
            tracerLines = {}
        end

        if state then
            if tracerThread then
                coroutine.close(tracerThread)
            end
            
            tracerThread = coroutine.create(function()
                while state do
                    cleanup()
                    local folder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
                    if folder then
                        for _, char in ipairs(folder:GetChildren()) do
                            if char:IsA("Model") and char:GetAttribute("Team") ~= "Nextbot" and char.Name ~= player.Name and char:GetAttribute("Downed") == true then
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if hrp and Camera then
                                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                                    if onScreen then
                                        local tracer = Drawing.new("Line")
                                        tracer.Color = Color3.fromRGB(255, 120, 120)
                                        tracer.Thickness = 2
                                        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                        tracer.To = Vector2.new(pos.X, pos.Y)
                                        tracer.ZIndex = 1
                                        tracer.Visible = true
                                        table.insert(tracerLines, tracer)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.05)
                end
            end)
            
            coroutine.resume(tracerThread)
        else
            if tracerThread then
                coroutine.close(tracerThread)
                tracerThread = nil
            end
            cleanup()
        end
    end)
})

local GunFunctionsGroup = Tabs.Visuals:AddLeftGroupbox("Gun Functions", "zap")
GunFunctionsGroup:AddDivider()
GunFunctionsGroup:AddLabel("ENHANCE YOUR WEAPONS")

GunFunctionsGroup:AddButton({
    Text = "Enhance GrappleHook",
    Func = SafeWrapper("EnhanceGrappleHook", function()
        GunFunctionsModule.EnhanceGrappleHook(Library)
    end),
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "Enhance Breacher (Portal Gun)",
    Func = SafeWrapper("EnhanceBreacher", function()
        GunFunctionsModule.EnhanceBreacher(Library)
    end),
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "Enhance Smoke Grenade",
    Func = SafeWrapper("EnhanceSmokeGrenade", function()
        GunFunctionsModule.EnhanceSmokeGrenade(Library)
    end),
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "Enhance Boombox",
    Func = SafeWrapper("EnhanceBoombox", function()
        GunFunctionsModule.EnhanceBoombox(Library)
    end),
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "Enhance All Weapons",
    Func = SafeWrapper("EnhanceAll", function()
        GunFunctionsModule.EnhanceAll(Library)
    end),
    DoubleClick = false,
})

-- Status display
local statusLabel = GunFunctionsGroup:AddLabel("Status: No weapons enhanced")

-- Update function untuk status
local function updateGunStatus()
    local status = {}
    if GunFunctionsModule.IsEnhanced("GrappleHook") then
        table.insert(status, "GrappleHook ✓")
    end
    if GunFunctionsModule.IsEnhanced("Breacher") then
        table.insert(status, "Portal Gun ✓")
    end
    if GunFunctionsModule.IsEnhanced("SmokeGrenade") then
        table.insert(status, "Smoke Grenade ✓")
    end
    if GunFunctionsModule.IsEnhanced("Boombox") then
        table.insert(status, "Boombox ✓")
    end
    
    if #status > 0 then
        statusLabel:SetText("Enhanced: " .. table.concat(status, ", "))
    else
        statusLabel:SetText("Status: No weapons enhanced")
    end
end

-- Run status update periodically
task.spawn(function()
    while true do
        updateGunStatus()
        task.wait(2)
    end
end)

local VisualGroup = Tabs.Visuals:AddRightGroupbox("Visual Enhancements", "sun")
local originalLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime
}

VisualGroup:AddToggle("Fullbright", {
    Text = "Fullbright",
    Default = false,
    Callback = SafeWrapper("FullbrightToggle", function(state)
        if state then
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 999999
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.ClockTime = 14
        else
            Lighting.Brightness = originalLighting.Brightness
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.Ambient = originalLighting.Ambient
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            Lighting.ClockTime = originalLighting.ClockTime
        end
    end)
})

VisualGroup:AddToggle("SuperFullbright", {
    Text = "Super Full Brightness",
    Default = false,
    Callback = SafeWrapper("SuperFullbrightToggle", function(state)
        if state then
            Lighting.Brightness = 15
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        else
            Lighting.Brightness = originalLighting.Brightness
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.Ambient = originalLighting.Ambient
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        end
    end)
})

VisualGroup:AddToggle("NoFog", {
    Text = "No Fog",
    Default = false,
    Callback = SafeWrapper("NoFogToggle", function(state)
        if state then
            Lighting.FogEnd = 1000000
            Lighting.FogStart = 999999
        else
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.FogStart = originalLighting.FogStart
        end
    end)
})

-- ==================== SERVER TAB ====================
local ServerInfoGroup = Tabs.Server:AddLeftGroupbox("Server Info", "info")
local gameModeName = "Loading..."
local gameModeParagraph = ServerInfoGroup:AddLabel("Game Mode: " .. gameModeName)

task.spawn(function()
    local success, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(placeId)
    end)
    if success and productInfo then
        local fullName = productInfo.Name
        if fullName:find("Evade %- ") then
            gameModeName = fullName:match("Evade %- (.+)") or fullName
        else
            gameModeName = fullName
        end
        gameModeParagraph:SetText("Game Mode: " .. gameModeName)
    else
        gameModeName = "Unknown"
        gameModeParagraph:SetText("Game Mode: " .. gameModeName)
    end
end)

ServerInfoGroup:AddButton({
    Text = "Copy Server Link",
    Func = SafeWrapper("CopyServerLink", function()
        local serverLink = getServerLink()
        local success, errorMsg = pcall(function()
            setclipboard(serverLink)
        end)

        if success then
            Library:Notify({
                Title = "Link Copied",
                Description = "Server invite link copied to clipboard!",
                Time = 3,
            })
        else
            Library:Notify({
                Title = "Copy Failed",
                Description = "Your executor doesn't support setclipboard",
                Time = 3,
            })
        end
    end),
    DoubleClick = false,
})

local numPlayers = #Players:GetPlayers()
local maxPlayers = Players.MaxPlayers
ServerInfoGroup:AddLabel("Players: " .. numPlayers .. " / " .. maxPlayers)
ServerInfoGroup:AddLabel("Server ID: " .. jobId)
ServerInfoGroup:AddLabel("Place ID: " .. tostring(placeId))

local ServerActionsGroup = Tabs.Server:AddLeftGroupbox("Quick Actions", "zap")
ServerActionsGroup:AddButton({
    Text = "Rejoin Server",
    Func = SafeWrapper("RejoinServer", function()
        TeleportService:Teleport(game.PlaceId, player)
    end),
    DoubleClick = false,
})
ServerActionsGroup:AddButton({
    Text = "Server Hop",
    Func = SafeWrapper("ServerHop", function()
        local success, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
                placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)

        if success and servers and servers.data and #servers.data > 0 then
            local filteredServers = {}
            for _, server in ipairs(servers.data) do
                if server.playing >= 5 then
                    table.insert(filteredServers, server)
                end
            end

            if #filteredServers > 0 then
                local randomServer = filteredServers[math.random(1, #filteredServers)]
                TeleportService:TeleportToPlaceInstance(placeId, randomServer.id, player)
            else
                Library:Notify({
                    Title = "Server Hop Failed",
                    Description = "No servers with 5+ players found!",
                    Time = 3,
                })
            end
        else
            Library:Notify({
                Title = "Server Hop Failed",
                Description = "Could not fetch servers!",
                Time = 3,
            })
        end
    end),
    DoubleClick = false,
})
ServerActionsGroup:AddButton({
    Text = "Hop to Small Server",
    Func = SafeWrapper("HopToSmallServer", function()
        local success, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
                placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)

        if success and servers and servers.data and #servers.data > 0 then
            table.sort(servers.data, function(a, b) return a.playing < b.playing end)
            if servers.data[1] then
                TeleportService:TeleportToPlaceInstance(placeId, servers.data[1].id, player)
            end
        else
            Library:Notify({
                Title = "Server Hop Failed",
                Description = "Could not fetch servers!",
                Time = 3,
            })
        end
    end),
    DoubleClick = false,
})

local ServerJoinGroup = Tabs.Server:AddRightGroupbox("Join Server", "log-in")
ServerJoinGroup:AddButton({
    Text = "Join Big Team",
    Func = SafeWrapper("JoinBigTeam", function()
        joinServerByPlaceId(10324346056, "Big Team")
    end),
    DoubleClick = false,
})
ServerJoinGroup:AddButton({
    Text = "Join Casual",
    Func = SafeWrapper("JoinCasual", function()
        joinServerByPlaceId(10662542523, "Casual")
    end),
    DoubleClick = false,
})
ServerJoinGroup:AddButton({
    Text = "Join Social Space",
    Func = SafeWrapper("JoinSocialSpace", function()
        joinServerByPlaceId(10324347967, "Social Space")
    end),
    DoubleClick = false,
})
ServerJoinGroup:AddButton({
    Text = "Join Player Nextbots",
    Func = SafeWrapper("JoinPlayerNextbots", function()
        joinServerByPlaceId(121271605799901, "Player Nextbots")
    end),
    DoubleClick = false,
})
ServerJoinGroup:AddButton({
    Text = "Join VC Only",
    Func = SafeWrapper("JoinVCO", function()
        joinServerByPlaceId(10808838353, "VC Only")
    end),
    DoubleClick = false,
})
ServerJoinGroup:AddButton({
    Text = "Join Pro",
    Func = SafeWrapper("JoinPro", function()
        joinServerByPlaceId(11353528705, "Pro")
    end),
    DoubleClick = false,
})

local CustomServerGroup = Tabs.Server:AddRightGroupbox("Custom Server", "key")
local customServerCode = ""
CustomServerGroup:AddInput("CustomServerCode", {
    Default = "",
    Placeholder = "Enter custom server passcode",
    Numeric = false,
    Finished = false,
    Text = "Custom Server Code",
    Callback = SafeWrapper("CustomServerCodeCallback", function(value)
        customServerCode = value
    end)
})

CustomServerGroup:AddButton({
    Text = "Join Custom Server",
    Func = SafeWrapper("JoinCustomServer", function()
        if customServerCode == "" then
            Library:Notify({
                Title = "Join Failed",
                Description = "Please enter a custom server code!",
                Time = 3,
            })
            return
        end

        local success, result = pcall(function()
            return game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("CustomServers")
                :WaitForChild("JoinPasscode"):InvokeServer(customServerCode)
        end)

        if success then
            Library:Notify({
                Title = "Joining Custom Server",
                Description = "Attempting to join with code: " .. customServerCode,
                Time = 3,
            })
        else
            Library:Notify({
                Title = "Join Failed",
                Description = "Invalid code or server unavailable!",
                Time = 3,
            })
        end
    end),
    DoubleClick = false,
})

-- ==================== MISC TAB ====================
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Lag Switch", "zap")
MiscGroup:AddToggle("LagSwitch", {
    Text = "Lag Switch",
    Default = false,
    Callback = SafeWrapper("LagSwitchToggle", function(state)
        lagSwitchEnabled = state
        if state then
            Library:Notify({
                Title = "Lag Switch",
                Description = "Enabled - Duration: " .. lagDuration .. "s",
                Time = 3,
            })
            
            task.spawn(function()
                while lagSwitchEnabled do
                    local startTime = tick()
                    
                    for _, v in pairs(Players:GetPlayers()) do
                        if v ~= player then
                            pcall(function()
                            end)
                        end
                    end
                    
                    task.wait(lagDuration)
                    task.wait(0.1)
                end
            end)
        else
            Library:Notify({
                Title = "Lag Switch",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

MiscGroup:AddSlider("LagDuration", {
    Text = "Lag Duration",
    Default = 0.5,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Suffix = "s",
    Callback = SafeWrapper("LagDurationCallback", function(value)
        lagDuration = value
    end)
})

local CarryGroup = Tabs.Misc:AddLeftGroupbox("Auto Carry & Help", "users")
CarryGroup:AddToggle("AutoCarry", {
    Text = "Auto Carry",
    Default = false,
    Callback = SafeWrapper("AutoCarryToggle", function(state)
        getgenv().autoCarryEnabled = state
        if state then
            if autoCarryConnection then
                autoCarryConnection:Disconnect()
            end
            
            autoCarryConnection = RunService.Heartbeat:Connect(function()
                if not getgenv().autoCarryEnabled then return end
                local char = safeGetCharacter(player)
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                for _, other in ipairs(Players:GetPlayers()) do
                    if other ~= player then
                        local otherChar = safeGetCharacter(other)
                        if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
                            local dist = (hrp.Position - otherChar.HumanoidRootPart.Position).Magnitude
                            if dist <= 20 then
                                pcall(function()
                                    ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact"):FireServer("Carry", nil, other.Name)
                                end)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end)
            
            Library:Notify({
                Title = "Auto Carry",
                Description = "Enabled",
                Time = 2,
            })
        else
            if autoCarryConnection then
                autoCarryConnection:Disconnect()
                autoCarryConnection = nil
            end
            Library:Notify({
                Title = "Auto Carry",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

CarryGroup:AddToggle("AutoHelp", {
    Text = "Auto Help",
    Default = false,
    Callback = SafeWrapper("AutoHelpToggle", function(state)
        getgenv().autoHelpEnabled = state
        if state then
            if autoHelpConnection then
                autoHelpConnection:Disconnect()
            end
            
            autoHelpConnection = RunService.Heartbeat:Connect(function()
                if not getgenv().autoHelpEnabled then return end
                local char = safeGetCharacter(player)
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                for _, other in ipairs(Players:GetPlayers()) do
                    if other ~= player then
                        local otherChar = safeGetCharacter(other)
                        if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
                            local dist = (hrp.Position - otherChar.HumanoidRootPart.Position).Magnitude
                            local downed = otherChar:GetAttribute("Downed")
                            if dist <= 20 and downed == true then
                                pcall(function()
                                    ReplicatedStorage:WaitForChild("Events"):WaitForChild("Revive"):FireServer(otherChar, "Revive")
                                end)
                                task.wait(1)
                            end
                        end
                    end
                end
            end)
            
            Library:Notify({
                Title = "Auto Help",
                Description = "Enabled",
                Time = 2,
            })
        else
            if autoHelpConnection then
                autoHelpConnection:Disconnect()
                autoHelpConnection = nil
            end
            Library:Notify({
                Title = "Auto Help",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

local PerfGroup = Tabs.Misc:AddRightGroupbox("Performance", "zap")
PerfGroup:AddButton({
    Text = "FPS Boost",
    Func = SafeWrapper("FPSBoost", function()
        AntiLagModule.ApplyFPSBoost(Library)
    end),
    DoubleClick = false,
})
PerfGroup:AddButton({
    Text = "Anti Lag 1",
    Func = SafeWrapper("AntiLag1", function()
        AntiLagModule.ApplyAntiLag1(Library)
    end),
    DoubleClick = false,
})
PerfGroup:AddButton({
    Text = "Anti Lag 2",
    Func = SafeWrapper("AntiLag2", function()
        AntiLagModule.ApplyAntiLag2(Library)
    end),
    DoubleClick = false,
})
PerfGroup:AddButton({
    Text = "Remove Textures",
    Func = SafeWrapper("RemoveTextures", function()
        AntiLagModule.ApplyRemoveTexture(Library)
    end),
    DoubleClick = false,
})

local UtilGroup = Tabs.Misc:AddRightGroupbox("Utilities", "shield")

local function startAntiAFK()
    local Players = game:GetService("Players")
    local VirtualUser = game:GetService("VirtualUser")
    local player = Players.LocalPlayer
    
    player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

task.spawn(function()
    task.wait(2)
    local success, err = pcall(startAntiAFK)
    if not success then
        warn("Anti-AFK Setup Error:", err)
    end
end)

UtilGroup:AddToggle("AntiAFK", {
    Text = "Anti-AFK",
    Default = true,
    Callback = SafeWrapper("AntiAFKToggle", function(state)
        if state then
            startAntiAFK()
            Library:Notify({
                Title = "Anti-AFK",
                Description = "Enabled",
                Time = 2,
            })
        else
            Library:Notify({
                Title = "Anti-AFK",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

UtilGroup:AddButton({
    Text = "Remove Invisible Walls",
    Func = SafeWrapper("RemoveInvisibleWalls", function()
        local gameFolder = workspace:FindFirstChild("Game")
        if gameFolder then
            local mapFolder = gameFolder:FindFirstChild("Map")
            if mapFolder then
                local invisParts = mapFolder:FindFirstChild("InvisParts")
                if invisParts then
                    local count = 0
                    for _, wall in pairs(invisParts:GetChildren()) do
                        wall:Destroy()
                        count = count + 1
                    end
                    Library:Notify({
                        Title = "Invisible Walls",
                        Description = "Removed " .. count .. " invisible walls!",
                        Time = 3,
                    })
                else
                    Library:Notify({
                        Title = "Invisible Walls",
                        Description = "InvisParts folder not found!",
                        Time = 3,
                    })
                end
            end
        end
    end),
    DoubleClick = false,
})

-- ==================== IRUZ HUB FEATURES UI ====================
local IruzGroup = Tabs.Misc:AddLeftGroupbox("Iruz Features", "zap")
IruzGroup:AddToggle("IruzFly", {
    Text = "Iruz Fly",
    Default = false,
    Callback = SafeWrapper("IruzFlyToggle", function(state)
        if state then
            local success, err = IruzHub.StartFlying()
            if success then
                if not flyLoop then
                    flyLoop = RunService.RenderStepped:Connect(IruzHub.UpdateFly)
                end
                Library:Notify({
                    Title = "Iruz Fly",
                    Description = "Enabled (WASD + Space/Shift)",
                    Time = 2,
                })
            else
                Library:Notify({
                    Title = "Fly Error",
                    Description = err or "Failed to start flying",
                    Time = 2,
                })
                if Toggles.IruzFly then
                    Toggles.IruzFly:SetValue(false)
                end
            end
        else
            IruzHub.StopFlying()
            if flyLoop then
                flyLoop:Disconnect()
                flyLoop = nil
            end
            Library:Notify({
                Title = "Iruz Fly",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

IruzGroup:AddDivider()
IruzGroup:AddToggle("IruzAntiNextbot", {
    Text = "Anti Nextbot",
    Default = false,
    Callback = SafeWrapper("IruzAntiNextbotToggle", function(state)
        IruzHub.SetAntiNextbotEnabled(state)
        if state then
            if not antiNextbotConnection then
                antiNextbotConnection = RunService.Heartbeat:Connect(IruzHub.HandleAntiNextbot)
            end
            Library:Notify({
                Title = "Anti Nextbot",
                Description = "Enabled - Range: " .. IruzHub.GetAntiNextbotDistance() .. " studs",
                Time = 2,
            })
        else
            if antiNextbotConnection then
                antiNextbotConnection:Disconnect()
                antiNextbotConnection = nil
            end
            Library:Notify({
                Title = "Anti Nextbot",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

IruzGroup:AddSlider("AntiNextbotRange", {
    Text = "Detection Range",
    Default = 50,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Suffix = " studs",
    Callback = SafeWrapper("AntiNextbotRangeCallback", function(value)
        IruzHub.SetAntiNextbotDistance(value)
    end)
})

IruzGroup:AddDivider()
IruzGroup:AddToggle("IruzGravity", {
    Text = "Custom Gravity",
    Default = false,
    Callback = SafeWrapper("IruzGravityToggle", function(state)
        gravityEnabled = IruzHub.ToggleGravity()
        Library:Notify({
            Title = "Gravity",
            Description = gravityEnabled and "Enabled: " .. IruzHub.GetGravityValue() or "Disabled",
            Time = 2,
        })
    end)
})

IruzGroup:AddSlider("GravityValue", {
    Text = "Gravity Strength",
    Default = 10,
    Min = 1,
    Max = 196.2,
    Rounding = 1,
    Callback = SafeWrapper("GravityValueCallback", function(value)
        IruzHub.SetGravityValue(value)
    end)
})

IruzGroup:AddDivider()
IruzGroup:AddToggle("IruzAutoDrink", {
    Text = "Auto Drink Cola",
    Default = false,
    Callback = SafeWrapper("IruzAutoDrinkToggle", function(state)
        IruzHub.SetAutoDrinkEnabled(state)
        if state then
            IruzHub.StartAutoDrink()
            Library:Notify({
                Title = "Auto Drink",
                Description = "Enabled - Delay: " .. IruzHub.GetDrinkDelay() .. "s",
                Time = 2,
            })
        else
            IruzHub.StopAutoDrink()
            Library:Notify({
                Title = "Auto Drink",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

IruzGroup:AddSlider("DrinkDelay", {
    Text = "Drink Delay",
    Default = 0.5,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Suffix = "s",
    Callback = SafeWrapper("DrinkDelayCallback", function(value)
        IruzHub.SetDrinkDelay(value)
    end)
})

local AdvancedIruzGroup = Tabs.Misc:AddRightGroupbox("Iruz Advanced", "cpu")
AdvancedIruzGroup:AddToggle("CameraStretch", {
    Text = "Camera Stretch",
    Default = false,
    Callback = SafeWrapper("CameraStretchToggle", function(state)
        IruzHub.SetCameraStretchEnabled(state)
        if state then
            IruzHub.SetupCameraStretch()
            Library:Notify({
                Title = "Camera Stretch",
                Description = "Enabled",
                Time = 2,
            })
        else
            Library:Notify({
                Title = "Camera Stretch",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

AdvancedIruzGroup:AddSlider("StretchHorizontal", {
    Text = "Horizontal Stretch",
    Default = 0.80,
    Min = 0.1,
    Max = 2,
    Rounding = 2,
    Callback = SafeWrapper("StretchHorizontalCallback", function(value)
        IruzHub.SetStretchHorizontal(value)
    end)
})

AdvancedIruzGroup:AddSlider("StretchVertical", {
    Text = "Vertical Stretch",
    Default = 0.80,
    Min = 0.1,
    Max = 2,
    Rounding = 2,
    Callback = SafeWrapper("StretchVerticalCallback", function(value)
        IruzHub.SetStretchVertical(value)
    end)
})

AdvancedIruzGroup:AddDivider()
AdvancedIruzGroup:AddToggle("NoCameraShake", {
    Text = "No Camera Shake",
    Default = false,
    Callback = SafeWrapper("NoCameraShakeToggle", function(state)
        if state then
            local stableCamera = IruzHub.CreateStableCamera()
            if stableCamera then
                stableCamera:Start()
                Library:Notify({
                    Title = "No Camera Shake",
                    Description = "Enabled",
                    Time = 2,
                })
            end
        else
            local stableCamera = IruzHub.GetStableCamera()
            if stableCamera then
                stableCamera:Stop()
            end
            Library:Notify({
                Title = "No Camera Shake",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

AdvancedIruzGroup:AddToggle("IruzNoFog", {
    Text = "No Fog & Atmosphere",
    Default = false,
    Callback = SafeWrapper("IruzNoFogToggle", function(state)
        IruzHub.SetNoFogEnabled(state)
        Library:Notify({
            Title = "No Fog",
            Description = state and "Enabled" or "Disabled",
            Time = 2,
        })
    end)
})

AdvancedIruzGroup:AddDivider()
AdvancedIruzGroup:AddToggle("IruzLagSwitch", {
    Text = "Iruz Lag Switch",
    Default = false,
    Callback = SafeWrapper("IruzLagSwitchToggle", function(state)
        if lagSwitchEnabled ~= state then
            lagSwitchEnabled = state
            Library:Notify({
                Title = "Lag Switch",
                Description = state and "Enabled (Press your custom key to activate)" or "Disabled",
                Time = 2,
            })
        end
    end)
})

AdvancedIruzGroup:AddSlider("LagDelay", {
    Text = "Lag Duration",
    Default = 0.1,
    Min = 0.05,
    Max = 5,
    Rounding = 2,
    Suffix = "s",
    Callback = SafeWrapper("LagDelayCallback", function(value)
        IruzHub.SetLagDelay(value)
    end)
})

AdvancedIruzGroup:AddSlider("LagIntensity", {
    Text = "Lag Intensity",
    Default = 1000000,
    Min = 100000,
    Max = 10000000,
    Rounding = 0,
    Callback = SafeWrapper("LagIntensityCallback", function(value)
        IruzHub.SetLagIntensity(value)
    end)
})

AdvancedIruzGroup:AddDropdown("LagMode", {
    Values = { "Normal", "Demon" },
    Default = "Normal",
    Text = "Lag Mode",
    Callback = SafeWrapper("LagModeCallback", function(value)
        IruzHub.SetLagMode(value)
    end)
})

-- ==================== UI SETTINGS TAB ====================
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:BuildConfigSection(Tabs["UI Settings"])

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = SafeWrapper("KeybindMenuOpenToggle", function(value)
        Library.KeybindFrame.Visible = value
    end),
})
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = SafeWrapper("ShowCustomCursorToggle", function(Value)
        Library.ShowCustomCursor = Value
    end),
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = SafeWrapper("NotificationSideCallback", function(Value)
        Library:SetNotifySide(Value)
    end),
})
MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = SafeWrapper("DPICallback", function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
    end),
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- ==================== LOAD AUTOLOAD CONFIG ====================
task.spawn(function()
    task.wait(2)
    SaveManager:LoadAutoloadConfig()
end)

-- ==================== BACKGROUND LOOPS ====================
task.spawn(function()
    while true do
        if getgenv().autoJumpEnabled then
            if getgenv().bhopMode == "Acceleration" then
                local friction = getgenv().bhopAccelValue or -0.1
                
                for _, t in pairs(getgc(true)) do
                    if type(t) == "table" and rawget(t, "Friction") then
                        t.Friction = friction
                    end
                end
            else
                -- Reset friction if needed
                for _, e in ipairs(frictionTables) do
                    if e.obj and type(e.obj) == "table" and rawget(e.obj, "Friction") then
                        e.obj.Friction = e.original
                    end
                end
                frictionTables = {}
            end
        end
        task.wait(0.15)
    end
end)

-- Character connection untuk auto jump
local characterConnection = nil
characterConnection = player.CharacterAdded:Connect(function(character)
    CharacterDH = character
    task.wait(0.5)
    HumanoidDH = safeGetHumanoid(character)
    HumanoidRootPartDH = character:FindFirstChild("HumanoidRootPart")
    
    IruzHub.SetCharacterReferences(CharacterDH, HumanoidDH, HumanoidRootPartDH)
    
    if getgenv().autoJumpEnabled then
        task.wait(1)
        IruzHub.LoadBhop(
            getgenv().autoJumpEnabled,
            getgenv().bhopMode,
            getgenv().bhopAccelValue,
            getgenv().jumpInterval,
            getgenv().autoJumpType,
            Library
        )
    end
end)

-- ==================== CUSTOM KEYBIND SYSTEM ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- FLY (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("Fly")) then
        local flyToggle = not IruzHub.IsFlying()
        
        if flyToggle then
            local success, err = IruzHub.StartFlying()
            if success then
                if not flyLoop then
                    flyLoop = RunService.RenderStepped:Connect(IruzHub.UpdateFly)
                end
                Library:Notify({
                    Title = "Iruz Fly",
                    Description = "Enabled (WASD + Space/Shift)",
                    Time = 2,
                })
            else
                Library:Notify({
                    Title = "Fly Error",
                    Description = err or "Failed to start flying",
                    Time = 2,
                })
                flyToggle = false
            end
        else
            IruzHub.StopFlying()
            if flyLoop then
                flyLoop:Disconnect()
                flyLoop = nil
            end
            Library:Notify({
                Title = "Iruz Fly",
                Description = "Disabled",
                Time = 2,
            })
        end
        
        if Toggles.IruzFly then
            Toggles.IruzFly:SetValue(flyToggle)
        end
    end
    
    -- ANTI NEXTBOT (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("AntiNextbot")) then
        local antiNextbotToggle = not IruzHub.GetAntiNextbotEnabled()
        IruzHub.SetAntiNextbotEnabled(antiNextbotToggle)
        
        if antiNextbotToggle then
            if not antiNextbotConnection then
                antiNextbotConnection = RunService.Heartbeat:Connect(IruzHub.HandleAntiNextbot)
            end
            Library:Notify({
                Title = "Anti Nextbot",
                Description = "Enabled - Range: " .. IruzHub.GetAntiNextbotDistance() .. " studs",
                Time = 2,
            })
        else
            if antiNextbotConnection then
                antiNextbotConnection:Disconnect()
                antiNextbotConnection = nil
            end
            Library:Notify({
                Title = "Anti Nextbot",
                Description = "Disabled",
                Time = 2,
            })
        end
        
        if Toggles.IruzAntiNextbot then
            Toggles.IruzAntiNextbot:SetValue(antiNextbotToggle)
        end
    end
    
    -- GRAVITY (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("Gravity")) then
        if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("IncreaseGravity")) then
            local currentValue = IruzHub.GetGravityValue()
            IruzHub.SetGravityValue(currentValue + 5)
            if IruzHub.IsGravityEnabled() then
                workspace.Gravity = IruzHub.GetGravityValue()
            end
            Library:Notify({
                Title = "Gravity",
                Description = "Increased to: " .. IruzHub.GetGravityValue(),
                Time = 1,
            })
        elseif KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("DecreaseGravity")) then
            local currentValue = IruzHub.GetGravityValue()
            IruzHub.SetGravityValue(math.max(1, currentValue - 5))
            if IruzHub.IsGravityEnabled() then
                workspace.Gravity = IruzHub.GetGravityValue()
            end
            Library:Notify({
                Title = "Gravity",
                Description = "Decreased to: " .. IruzHub.GetGravityValue(),
                Time = 1,
            })
        else
            local gravityToggle = IruzHub.ToggleGravity()
            Library:Notify({
                Title = "Gravity",
                Description = gravityToggle and "Enabled: " .. IruzHub.GetGravityValue() or "Disabled",
                Time = 2,
            })
        end
        
        if Toggles.IruzGravity then
            Toggles.IruzGravity:SetValue(IruzHub.IsGravityEnabled())
        end
    end
    
    -- AUTO DRINK (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("AutoDrink")) then
        local autoDrinkToggle = not IruzHub.GetAutoDrinkEnabled()
        IruzHub.SetAutoDrinkEnabled(autoDrinkToggle)
        
        if autoDrinkToggle then
            IruzHub.StartAutoDrink()
            Library:Notify({
                Title = "Auto Drink",
                Description = "Enabled - Delay: " .. IruzHub.GetDrinkDelay() .. "s",
                Time = 2,
            })
        else
            IruzHub.StopAutoDrink()
            Library:Notify({
                Title = "Auto Drink",
                Description = "Disabled",
                Time = 2,
            })
        end
        
        if Toggles.IruzAutoDrink then
            Toggles.IruzAutoDrink:SetValue(autoDrinkToggle)
        end
    end
    
    -- LAG SWITCH (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("LagSwitch")) then
        if lagSwitchEnabled then
            IruzHub.ToggleLagSwitch()
            Library:Notify({
                Title = "Iruz Lag",
                Description = "Activated - Mode: " .. IruzHub.GetLagMode(),
                Time = 2,
            })
        end
    end
    
    -- TOGGLE LAG SWITCH ENABLE (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("ToggleLagEnable")) then
        lagSwitchEnabled = not lagSwitchEnabled
        Library:Notify({
            Title = "Lag Switch",
            Description = lagSwitchEnabled and "Enabled (Press your custom key to activate)" or "Disabled",
            Time = 2,
        })
        
        if Toggles.IruzLagSwitch then
            Toggles.IruzLagSwitch:SetValue(lagSwitchEnabled)
        end
    end
    
    -- CAMERA STRETCH (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("CameraStretch")) then
        local cameraStretchToggle = not IruzHub.GetCameraStretchEnabled()
        IruzHub.SetCameraStretchEnabled(cameraStretchToggle)
        
        if cameraStretchToggle then
            IruzHub.SetupCameraStretch()
            Library:Notify({
                Title = "Camera Stretch",
                Description = "Enabled",
                Time = 2,
            })
        else
            Library:Notify({
                Title = "Camera Stretch",
                Description = "Disabled",
                Time = 2,
            })
        end
        
        if Toggles.CameraStretch then
            Toggles.CameraStretch:SetValue(cameraStretchToggle)
        end
    end
    
    -- INFINITE SLIDE (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("InfiniteSlide")) then
        infiniteSlideEnabled = not infiniteSlideEnabled
        
        local keys = {
            "Friction", "AirStrafeAcceleration", "JumpHeight", "RunDeaccel",
            "JumpSpeedMultiplier", "JumpCap", "SprintCap", "WalkSpeedMultiplier",
            "BhopEnabled", "Speed", "AirAcceleration", "RunAccel", "SprintAcceleration"
        }

        local function hasAll(tbl)
            if type(tbl) ~= "table" then return false end
            for _, k in ipairs(keys) do
                if rawget(tbl, k) == nil then
                    return false
                end
            end
            return true
        end

        local function setFriction(value)
            for _, t in ipairs(cachedTables) do
                pcall(function() t.Friction = value end)
            end
        end

        local function updatePlayerModel()
            local GameFolder = workspace:FindFirstChild("Game")
            plrModel = GameFolder and GameFolder:FindFirstChild("Players") and GameFolder.Players:FindFirstChild(player.Name)
        end

        local function onHeartbeat()
            if not infiniteSlideEnabled then return end
            if not plrModel then
                setFriction(5)
                return
            end
            
            local success, currentState = pcall(function()
                return plrModel:GetAttribute("State")
            end)
            
            if success and currentState == "Slide" then
                pcall(function() plrModel:SetAttribute("State", "EmotingSlide") end)
                setFriction(slideFrictionValue)
            elseif success and currentState == "EmotingSlide" then
                setFriction(slideFrictionValue)
            else
                setFriction(5)
            end
        end

        if infiniteSlideEnabled then
            for _, obj in ipairs(getgc(true)) do
                if hasAll(obj) then
                    table.insert(cachedTables, obj)
                end
            end
            
            updatePlayerModel()
            
            if slideConnection then
                slideConnection:Disconnect()
            end
            
            slideConnection = RunService.Heartbeat:Connect(onHeartbeat)
            player.CharacterAdded:Connect(function()
                task.wait(0.1)
                updatePlayerModel()
            end)
            
            Library:Notify({
                Title = "Infinite Slide",
                Description = "Enabled - Speed: " .. slideFrictionValue,
                Time = 2,
            })
        else
            if slideConnection then
                slideConnection:Disconnect()
                slideConnection = nil
            end
            setFriction(5)
            cachedTables = {}
            plrModel = nil
            
            Library:Notify({
                Title = "Infinite Slide",
                Description = "Disabled",
                Time = 2,
            })
        end
        
        if Toggles.InfiniteSlide then
            Toggles.InfiniteSlide:SetValue(infiniteSlideEnabled)
        end
    end
    
    -- NO FOG (Custom Combination Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("NoFog")) then
        local noFogToggle = not IruzHub.GetNoFogEnabled()
        IruzHub.SetNoFogEnabled(noFogToggle)
        Library:Notify({
            Title = "No Fog",
            Description = noFogToggle and "Enabled" or "Disabled",
            Time = 2,
        })
        
        if Toggles.IruzNoFog then
            Toggles.IruzNoFog:SetValue(noFogToggle)
        end
    end
    
    -- NO CAMERA SHAKE (Custom Combination Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("NoCameraShake")) then
        local stableCamera = IruzHub.GetStableCamera()
        if stableCamera then
            stableCamera:Stop()
            Library:Notify({
                Title = "No Camera Shake",
                Description = "Disabled",
                Time = 2,
            })
        else
            stableCamera = IruzHub.CreateStableCamera()
            if stableCamera then
                stableCamera:Start()
                Library:Notify({
                    Title = "No Camera Shake",
                    Description = "Enabled",
                    Time = 2,
                })
            end
        end
        
        if Toggles.NoCameraShake then
            Toggles.NoCameraShake:SetValue(IruzHub.GetStableCamera() ~= nil)
        end
    end
    
    -- FPS TIMER TOGGLE (Custom Combination Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager:GetKeybind("FpsTimer")) then
        fpsTimerEnabled = not fpsTimerEnabled
        local timerGUI = player.PlayerGui:FindFirstChild("IruzFPS")
        if timerGUI then
            timerGUI.Enabled = fpsTimerEnabled
            Library:Notify({
                Title = "FPS Timer",
                Description = fpsTimerEnabled and "Enabled" or "Disabled",
                Time = 2,
            })
        end
    end
end)

-- ==================== CHARACTER TRACKING ====================
RunService.Heartbeat:Connect(function()
    local currentChar = safeGetCharacter(player)
    if not CharacterDH or CharacterDH ~= currentChar or not CharacterDH:IsDescendantOf(workspace) then
        CharacterDH = currentChar
        if CharacterDH and CharacterDH:IsDescendantOf(workspace) then
            HumanoidDH = safeGetHumanoid(CharacterDH)
            HumanoidRootPartDH = CharacterDH:FindFirstChild("HumanoidRootPart")
            
            -- Update IruzHub references
            IruzHub.SetCharacterReferences(CharacterDH, HumanoidDH, HumanoidRootPartDH)
        else
            CharacterDH = nil
            HumanoidDH = nil
            HumanoidRootPartDH = nil
            IruzHub.SetCharacterReferences(nil, nil, nil)
        end
    end
end)

player.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    if character and character:IsDescendantOf(workspace) then
        CharacterDH = character
        
        local humanoid = character:FindFirstChildOfClass("Humanoid") or 
                         character:WaitForChild("Humanoid", 2)
        local hrp = character:FindFirstChild("HumanoidRootPart") or 
                    character:WaitForChild("HumanoidRootPart", 2)
        
        if humanoid and hrp then
            HumanoidDH = humanoid
            HumanoidRootPartDH = hrp
            
            IruzHub.SetCharacterReferences(CharacterDH, HumanoidDH, HumanoidRootPartDH)
            
            if IruzHub.IsFlying() then
                task.wait(1)
                IruzHub.StartFlying()
            end
        else
            warn("[Character Load] Humanoid or HRP not found")
        end
    end
end)

player.CharacterRemoving:Connect(function()
    if IruzHub.IsFlying() then
        IruzHub.StopFlying()
        if flyLoop then
            flyLoop:Disconnect()
            flyLoop = nil
        end
    end
end)

-- Auto Place Teleporter Event
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
                Library:Notify({
                    Title = "Auto Place",
                    Description = "Map '" .. currentMapName .. "' not in database",
                    Time = 2,
                })
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
            local character = safeGetCharacter(player) or player.CharacterAdded:Wait()
            character:WaitForChild("HumanoidRootPart")
            task.wait(1)
            TeleportModule.PlaceTeleporter(autoPlaceTeleporterType, Library)
            Library:Notify({
                Title = "Auto Place",
                Description = "New map: " .. currentMapName,
                Time = 2,
            })
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

gameStats:GetAttributeChangedSignal("RoundStarted"):Connect(function()
    if not autoPlaceTeleporterEnabled then return end
    local roundStarted = gameStats:GetAttribute("RoundStarted")
    local roundsCompleted = gameStats:GetAttribute("RoundsCompleted") or 0
    if not roundStarted and roundsCompleted < 3 then
        task.spawn(function()
            task.wait(3)
            local character = safeGetCharacter(player) or player.CharacterAdded:Wait()
            character:WaitForChild("HumanoidRootPart")
            task.wait(1)
            TeleportModule.PlaceTeleporter(autoPlaceTeleporterType, Library)
            Library:Notify({
                Title = "Auto Place",
                Description = "Round " .. roundsCompleted .. " done",
                Time = 2,
            })
        end)
    end
end)

-- ==================== GLOBAL ERROR HANDLER ====================
local function globalErrorHandler(err)
    warn("[Iruz Global Error Handler]:", err)
    print(debug.traceback())
    
    if IruzHub.IsFlying() then
        print("[Auto-Recovery] Disabling fly due to error...")
        IruzHub.StopFlying()
        if Toggles.IruzFly then
            Toggles.IruzFly:SetValue(false)
        end
    end
    
    if IruzHub.GetAntiNextbotEnabled() then
        print("[Auto-Recovery] Disabling anti-nextbot due to error...")
        IruzHub.SetAntiNextbotEnabled(false)
        if antiNextbotConnection then
            antiNextbotConnection:Disconnect()
            antiNextbotConnection = nil
        end
        if Toggles.IruzAntiNextbot then
            Toggles.IruzAntiNextbot:SetValue(false)
        end
    end
    
    CharacterDH = nil
    HumanoidDH = nil
    HumanoidRootPartDH = nil
    IruzHub.SetCharacterReferences(nil, nil, nil)
    
    Library:Notify({
        Title = "System Recovery",
        Description = "Auto-recovered from an error",
        Time = 3,
    })
end

-- ==================== FIXED READONLY TABLE ISSUE ====================
local function safeModifyTables()
    local function protectTable(t)
        return setmetatable({}, {
            __index = t,
            __newindex = function(self, key, value)
                if rawget(t, key) ~= nil then
                    rawset(t, key, value)
                end
            end
        })
    end

    local function modifyTableSafely(tableObj, key, value)
        local success, result = pcall(function()
            tableObj[key] = value
        end)
        
        if not success then
            pcall(function()
                rawset(tableObj, key, value)
            end)
        end
    end

    local function getMovementTables()
        local tables = {}
        
        for _, obj in pairs(getgc(true)) do
            if type(obj) == "table" then
                if rawget(obj, "Speed") and rawget(obj, "JumpHeight") then
                    table.insert(tables, protectTable(obj))
                end
            end
        end
        
        return tables
    end

    local function applySpeedModification(speedValue)
        local movementTables = getMovementTables()
        
        for _, tableObj in ipairs(movementTables) do
            modifyTableSafely(tableObj, "Speed", speedValue)
            modifyTableSafely(tableObj, "WalkSpeedMultiplier", 1)
        end
    end

    local function applyJumpModification(jumpValue)
        local movementTables = getMovementTables()
        
        for _, tableObj in ipairs(movementTables) do
            modifyTableSafely(tableObj, "JumpHeight", jumpValue)
            modifyTableSafely(tableObj, "JumpCap", jumpValue)
        end
    end

    return {
        ApplySpeed = applySpeedModification,
        ApplyJump = applyJumpModification,
        GetMovementTables = getMovementTables
    }
end

local SafeTableModifier = safeModifyTables()

-- ==================== CLEANUP ON SCRIPT END ====================
Library:OnUnload(function()
    print("Unloading Iruz Evade...")
    
    if respawnConnection then
        respawnConnection:Disconnect()
    end
    if playerESPThread then
        coroutine.close(playerESPThread)
    end
    if nextbotESPThread then
        coroutine.close(nextbotESPThread)
    end
    if tracerThread then
        coroutine.close(tracerThread)
    end
    if autoCarryConnection then
        autoCarryConnection:Disconnect()
    end
    if autoHelpConnection then
        autoHelpConnection:Disconnect()
    end
    if slideConnection then
        slideConnection:Disconnect()
    end
    
    local folder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
    if folder then
        for _, char in ipairs(folder:GetChildren()) do
            if char:IsA("Model") then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local esp = hrp:FindFirstChild("PlayerESP")
                    if esp then esp:Destroy() end
                    local nextbotESP = hrp:FindFirstChild("NextbotESP")
                    if nextbotESP then nextbotESP:Destroy() end
                end
            end
        end
    end
    
    for _, line in ipairs(tracerLines) do
        if line then
            line:Remove()
        end
    end
    
    AutoSelfReviveModule.Stop()
    FastReviveModule.Stop()
    AutoFarmModule.StopAll()
    
    Lighting.Brightness = originalLighting.Brightness
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    Lighting.ClockTime = originalLighting.ClockTime
    
    print("Unloading Iruz Hub features...")
    
    -- Cleanup IruzHub
    IruzHub.Cleanup()
    
    print("Iruz Hub features unloaded!")
    print("Iruz Evade unloaded successfully!")
end)

-- ==================== INITIALIZATION ====================
originalGravity = workspace.Gravity
createSimpleTimer()

task.wait(1)
if player.Character then
    CharacterDH = player.Character
    HumanoidDH = safeGetHumanoid(player.Character)
    HumanoidRootPartDH = player.Character:FindFirstChild("HumanoidRootPart")
    IruzHub.SetCharacterReferences(CharacterDH, HumanoidDH, HumanoidRootPartDH)
end

task.spawn(function()
    task.wait(3)
    Library:Notify({
        Title = "Iruz Evade - Iruz Edition",
        Description = "Enhanced Error Handling Activated!\n\n✓ Fixed Humanoid errors\n✓ Auto-recovery system\n✓ Stable performance\n✓ Read-only table protection",
        Time = 6,
    })
end)

print("🔥 Iruz Evade Script Loaded Successfully! 🔥")

local success, err = pcall(startAntiAFK)
if not success then
    warn("Failed to start Anti-AFK:", err)
end

-- BERHENTI DI SINI, jangan ada kode lain setelah ini

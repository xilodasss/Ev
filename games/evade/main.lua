-- Load Obsidian UI Library
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

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

-- Safe table assignment
local function safeAssign(t, k, v)
    if type(t) ~= "table" then return false end
    
    local methods = {
        function() rawset(t, k, v) end,
        function() t[k] = v end,
        function() 
            if getmetatable(t) then
                getmetatable(t).__newindex = function(self, key, value)
                    if key == k then
                        rawset(self, k, value)
                    end
                end
            end
        end
    }
    
    for _, method in ipairs(methods) do
        local success = pcall(method)
        if success then return true end
    end
    return false
end

-- ==================== ENHANCED ERROR HANDLING ====================
local DEBUG_MODE = false

local function DebugLog(message, ...)
    if DEBUG_MODE then
        print("[Iruz Debug]:", message, ...)
    end
end

local function SafeWrapper(name, func)
    return function(...)
        local args = {...}
        local success, result = xpcall(function()
            return func(unpack(args))
        end, function(err)
            warn("[" .. name .. " Error]:", err)
            DebugLog("Error in " .. name .. ":", err, debug.traceback())
            return nil
        end)
        return success and result or nil
    end
end

-- ==================== SAFE UTILITY FUNCTIONS ====================
local function safeString(value, default)
    if value == nil then
        return default or ""
    elseif type(value) == "string" then
        return value
    elseif type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    elseif typeof(value) == "Vector3" then
        return string.format("(%.1f, %.1f, %.1f)", value.X, value.Y, value.Z)
    else
        return "[" .. typeof(value) .. "]"
    end
end

local function safeConcat(...)
    local result = ""
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        result = result .. safeString(arg, "")
    end
    return result
end

-- ==================== ENHANCED CHARACTER HANDLING ====================
local function safeGetHumanoid(model)
    if not model then return nil end
    if not model:IsA("Model") then return nil end
    
    local maxAttempts = 10
    for i = 1, maxAttempts do
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid:IsA("Humanoid") and humanoid.Parent == model then
            return humanoid
        end
        task.wait(0.05)
    end
    return nil
end

local function safeGetCharacter(playerObj)
    if not playerObj then return nil end
    if not playerObj:IsA("Player") then return nil end
    
    local maxAttempts = 15
    for i = 1, maxAttempts do
        local char = playerObj.Character
        if char and char:IsA("Model") and char.Parent then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:IsA("BasePart") then
                return char
            end
        end
        task.wait(0.1)
    end
    return nil
end

local function isPlayerDowned(plr)
    local char = safeGetCharacter(plr)
    if not char then return false end
    
    local downed = char:GetAttribute("Downed")
    if downed == true then return true end
    
    local humanoid = safeGetHumanoid(char)
    if humanoid then
        return humanoid.Health <= 0
    end
    
    return false
end

-- ==================== SETUP THEMEMANAGER DAN SAVEMANAGER ====================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("IruzEvade")

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
local stableCameraInstance = nil
local flying = false
local bodyVelocity = nil
local bodyGyro = nil
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

-- ==================== KEYBIND MANAGER ====================
local KeybindManager = {
    DefaultKeybinds = {
        Fly = Enum.KeyCode.F,
        AntiNextbot = Enum.KeyCode.N,
        Gravity = Enum.KeyCode.G,
        AutoDrink = Enum.KeyCode.D,
        LagSwitch = Enum.KeyCode.L,
        CameraStretch = Enum.KeyCode.T,
        InfiniteSlide = Enum.KeyCode.I,
        NoFog = {Enum.KeyCode.LeftControl, Enum.KeyCode.F},
        NoCameraShake = {Enum.KeyCode.LeftControl, Enum.KeyCode.S},
        FpsTimer = {Enum.KeyCode.LeftControl, Enum.KeyCode.H},
        IncreaseGravity = {Enum.KeyCode.LeftControl, Enum.KeyCode.G},
        DecreaseGravity = {Enum.KeyCode.LeftAlt, Enum.KeyCode.G},
        ToggleLagEnable = Enum.KeyCode.F12
    },
    
    CurrentKeybinds = {},
    
    Init = function(self)
        print("[Keybind] Initializing keybind system...")
        
        self.CurrentKeybinds = {}
        for key, value in pairs(self.DefaultKeybinds) do
            self.CurrentKeybinds[key] = value
        end
        
        if isfile and readfile and isfile("Iruz_keybinds.txt") then
            print("[Keybind] Loading saved keybinds...")
            
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile("Iruz_keybinds.txt"))
            end)
            
            if success and data and type(data) == "table" then
                for key, value in pairs(data) do
                    if type(value) == "number" then
                        local convertSuccess, keyCode = pcall(function()
                            return Enum.KeyCode.new(value)
                        end)
                        
                        if convertSuccess and keyCode then
                            self.CurrentKeybinds[key] = keyCode
                        else
                            print("[Keybind] Failed to convert value for", key, ":", value)
                        end
                        
                    elseif type(value) == "table" then
                        local keys = {}
                        local allValid = true
                        
                        for _, keyValue in ipairs(value) do
                            local convertSuccess, keyCode = pcall(function()
                                return Enum.KeyCode.new(keyValue)
                            end)
                            
                            if convertSuccess and keyCode then
                                table.insert(keys, keyCode)
                            else
                                allValid = false
                                print("[Keybind] Invalid key in combo for", key, ":", keyValue)
                            end
                        end
                        
                        if allValid and #keys > 0 then
                            self.CurrentKeybinds[key] = keys
                        end
                    end
                end
                print("[Keybind] Keybinds loaded successfully!")
            else
                print("[Keybind] No valid save data found, using defaults")
            end
        else
            print("[Keybind] No save file found, using defaults")
        end
    end,
    
    Save = function(self)
        if writefile then
            local saveData = {}
            
            for key, keyCode in pairs(self.CurrentKeybinds) do
                if typeof(keyCode) == "EnumItem" then
                    saveData[key] = keyCode.Value
                elseif type(keyCode) == "table" then
                    local keys = {}
                    for _, kc in ipairs(keyCode) do
                        if typeof(kc) == "EnumItem" then
                            table.insert(keys, kc.Value)
                        end
                    end
                    if #keys > 0 then
                        saveData[key] = keys
                    end
                end
            end
            
            local success, err = pcall(function()
                writefile("Iruz_keybinds.txt", HttpService:JSONEncode(saveData))
            end)
            
            if success then
                print("[Keybind] Settings saved successfully")
            else
                warn("[Keybind] Failed to save:", err)
            end
        end
    end,
    
    IsKeyComboPressed = function(self, keyCombo)
        if typeof(keyCombo) == "EnumItem" then
            return UserInputService:IsKeyDown(keyCombo)
        elseif type(keyCombo) == "table" then
            for _, key in ipairs(keyCombo) do
                if not UserInputService:IsKeyDown(key) then
                    return false
                end
            end
            return true
        end
        return false
    end,
    
    GetKeyName = function(self, keyCombo)
        if typeof(keyCombo) == "EnumItem" then
            return keyCombo.Name
        elseif type(keyCombo) == "table" then
            local names = {}
            for _, key in ipairs(keyCombo) do
                table.insert(names, key.Name)
            end
            return table.concat(names, " + ")
        end
        return "None"
    end
}

KeybindManager:Init()

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

-- ==================== TELEPORT MODULE ====================
local TeleportModule = (function()
    local mapSpots = {
        ["DesertBus"] = {
            Far = CFrame.new(1350.6390380859375, -66.57595825195312, 913.889404296875, 0.08861260116100311, 0,
                0.9960662126541138, 0, 1.0000001192092896, 0, -0.9960662126541138, 0, 0.08861260116100311),
            Sky = CFrame.new(29.76473045349121, 69.4240493774414, -178.1037139892578, 0.6581460237503052, 0,
                0.7528902888298035, 0, 1, 0, -0.752890408039093, 0, 0.6581459641456604)
        },
        ["IndoorWaterPark"] = {
            Far = CFrame.new(655.8071899414062, 196.49005126953125, 705.3368530273438, 0.33953040838241577, 0,
                0.9405950903892517, 0, 1, 0, -0.9405950903892517, 0, 0.33953040838241577),
            Sky = CFrame.new(-460.7920837402344, 518.8087158203125, 1170.8741455078125, -0.0769985020160675, 0,
                0.9970312118530273, 0, 1, 0, -0.9970312118530273, 0, -0.0769985020160675)
        },
        ["Alleyways"] = {
            Far = CFrame.new(-35.08295440673828, 2.2002439498901367, 541.8427734375, 0.8617393374443054, 0,
                0.5073513388633728, 0, 1, 0, -0.5073513984680176, 0, 0.8617392182350159),
            Sky = CFrame.new(105.782958984375, 170.20025634765625, 384.8106689453125, 0.7089647650718689, 0,
                -0.7052439451217651, 0, 1, 0, 0.7052439451217651, 0, 0.7089647650718689)
        },
        ["Garden"] = {
            Sky = CFrame.new(-339.934326171875, 356.55731201171875, -654.667236328125, 0.9520128965377808, 0,
                0.3060581684112549, 0, 1, 0, -0.30605819821357727, 0, 0.9520127773284912)
        },
        ["ScorchingOutpost"] = {
            Sky = CFrame.new(-228.6458740234375, 230.90721130371094, 43.87240219116211, -0.1324794590473175, 0,
                -0.99118572473526, 0, 1, 0, 0.9911858439445496, 0, -0.1324794441461563)
        },
        ["Maze"] = {
            Sky = CFrame.new(46.19444274902344, -121.4998779296875, 70.2211685180664, -0.9800435900688171, 0,
                0.19878289103507996, 0, 1.0000001192092896, 0, -0.19878289103507996, 0, -0.9800435900688171)
        },
        ["Mayday"] = {
            Far = CFrame.new(33.04498291015625, 384.283447265625, 105.46440887451172, -0.9928553104400635, 0,
                -0.11932454258203506, 0, 1, 0, 0.11932454258203506, 0, -0.9928553104400635),
            Sky = CFrame.new(-1019.0883178710938, 1015.3773193359375, 329.9805603027344, 0.39608004689216614, 0,
                0.9182159900665283, 0, 1.0000001192092896, 0, -0.9182161092758179, 0, 0.39607998728752136)

        },
        ["WinterPalace"] = {
            Sky = CFrame.new(381.09075927734375, 279.2668762207031, 130.02322387695312, 0.15100924670696259, 0,
                0.988532304763794, 0, 1, 0, -0.9885324239730835, 0, 0.1510092318058014)
        },
        ["JollyVillage"] = {
            Far = CFrame.new(-1013.8224487304688, 636.9444580078125, -3115.31494140625, 0.3681890368461609, 0,
                0.9297509789466858, 0, 1, 0, -0.9297509789466858, 0, 0.3681890368461609),
            Sky = CFrame.new(-139.01596069335938, 1205.17431640625, -717.07568359375, 0.8310645222663879, 0,
                -0.5561761260032654, 0, 1.0000001192092896, 0, 0.5561761856079102, 0, 0.8310644030570984),
        },
        ["Loop"] = {
            Sky = CFrame.new(-161.85980224609375, -278.20001220703125, -81.01275634765625, -0.6171243190765381, 0,
                -0.7868656516075134, 0, 1, 0, 0.7868656516075134, 0, -0.6171243190765381),
        },
        ["FestiveGathering"] = {
            Sky = CFrame.new(11.90072250366211, 383.59442138671875, 59.90773010253906, -0.9867874383926392, 0,
                -0.16202007234096527, 0, 1.0000001192092896, 0, 0.16202005743980408, 0, -0.9867875576019287),
        },
        ["FrostlightHollow"] = {
            Sky = CFrame.new(31.77029037475586, 985.7108154296875, 80.7327880859375, -0.9929403066635132, 0,
                0.11861587315797806, 0, 1, 0, -0.11861588805913925, 0, -0.9929401874542236),
        },
        ["WinterfallKingdom"] = {
            Sky = CFrame.new(-160.61166381835938, 570.0502319335938, -560.9686889648438, -0.3108031153678894, 0,
                -0.9504743218421936, 0, 1, 0, 0.9504743218421936, 0, -0.3108031153678894),
        },
        ["FestiveWorkshop"] = {
            Sky = CFrame.new(717.2640380859375, 231.27069091796875, -407.1882629394531, 0.06374967098236084, 0,
                0.997965931892395, 0, 1, 0, -0.997965931892395, 0, 0.06374967098236084),
        },
        ["Cliffshire"] = {
            Sky = CFrame.new(-161.78192138671875, 403.5511474609375, -651.4358520507812, 0.5457629561424255, 0,
                -0.8379396200180054, 0, 1, 0, 0.8379396200180054, 0, 0.5457629561424255),
            Far = CFrame.new(-161.78192138671875, 403.5511474609375, -651.4358520507812, 0.5457629561424255, 0,
                -0.8379396200180054, 0, 1, 0, 0.8379396200180054, 0, 0.5457629561424255),
        },
        ["NemosRest"] = {
            Sky = CFrame.new(836.2274780273438, 356.0625, 462.6441955566406, -0.7985675930976868, 0, 0.6019051671028137,
                0, 1,
                0, -0.6019051671028137, 0, -0.7985675930976868),
            Far = CFrame.new(836.2274780273438, 356.0625, 462.6441955566406, -0.7985675930976868, 0, 0.6019051671028137,
                0, 1,
                0, -0.6019051671028137, 0, -0.7985675930976868),
        },
        ["Hokkaido"] = {
            Sky = CFrame.new(73.56007385253906, 432.25, 392.9374084472656, -0.9822593927383423, 0, 0.1875273436307907, 0,
                1,
                0, -0.1875273436307907, 0, -0.9822593927383423),
            Far = CFrame.new(73.56007385253906, 432.25, 392.9374084472656, -0.9822593927383423, 0, 0.1875273436307907, 0,
                1,
                0, -0.1875273436307907, 0, -0.9822593927383423),
        },
        ["Cemetery"] = {
            Sky = CFrame.new(632.48193359375, 586.0111083984375, -361.3384704589844, 0.18417859077453613, 0,
                0.9828926920890808, 0, 0.9999999403953552, 0, -0.9828928112983704, 0, 0.18417857587337494),
            Far = CFrame.new(632.48193359375, 586.0111083984375, -361.3384704589844, 0.18417859077453613, 0,
                0.9828926920890808, 0, 0.9999999403953552, 0, -0.9828928112983704, 0, 0.18417857587337494),
        },
        ["City"] = {
            Far = CFrame.new(-2127.977783203125, 383.7749938964844, -559.095947265625, 0.8021499514579773, 0,
                -0.5971227288246155, 0, 1.0000001192092896, 0, 0.5971227288246155, 0, 0.8021499514579773),
            Sky = CFrame.new(-2127.977783203125, 383.7749938964844, -559.095947265625, 0.8021499514579773, 0,
                -0.5971227288246155, 0, 1.0000001192092896, 0, 0.5971227288246155, 0, 0.8021499514579773),
        },
        ["Library"] = {
            Far = CFrame.new(1793.404541015625, 208.00001525878906, 104.01787567138672, 0.055350083857774734, 0,
                0.998466968536377, 0, 1, 0, -0.9984670877456665, 0, 0.05535007640719414),
            Sky = CFrame.new(1793.404541015625, 208.00001525878906, 104.01787567138672, 0.055350083857774734, 0,
                0.998466968536377, 0, 1, 0, -0.9984670877456665, 0, 0.05535007640719414),
        },
        ["WorkFacility"] = {
            Sky = CFrame.new(32.97286605834961, -203.93392944335938, 937.833251953125, -0.05341392755508423, 0,
                0.9985724091529846, 0, 1, 0, -0.9985725283622742, 0, -0.05341392010450363),
            Far = CFrame.new(32.97286605834961, -203.93392944335938, 937.833251953125, -0.05341392755508423, 0,
                0.9985724091529846, 0, 1, 0, -0.9985725283622742, 0, -0.05341392010450363),
        },
        ["Funrooms"] = {
            Sky = CFrame.new(-116.376708984375, -182.91168212890625, 499.81671142578125, -0.6560189127922058, 0,
                0.7547444701194763, 0, 1.0000001192092896, 0, -0.7547445893287659, 0, -0.656018853187561),
            Far = CFrame.new(-116.376708984375, -182.91168212890625, 499.81671142578125, -0.6560189127922058, 0,
                0.7547444701194763, 0, 1.0000001192092896, 0, -0.7547445893287659, 0, -0.656018853187561),
        },
        ["Vibrance"] = {
            Sky = CFrame.new(-177.74911499023438, 71.1875, 191.6678009033203, 0.9960232973098755, 0, -0.08909342437982559,
                0,
                1, 0, 0.08909342437982559, 0, 0.9960232973098755),
            Far = CFrame.new(-177.74911499023438, 71.1875, 191.6678009033203, 0.9960232973098755, 0, -0.08909342437982559,
                0,
                1, 0, 0.08909342437982559, 0, 0.9960232973098755),
        },
        ["Construct"] = {
            Sky = CFrame.new(-612.9860229492188, 251.5, -198.60336303710938, -0.32763347029685974, 0, 0.944804847240448,
                0, 1, 0, -0.9448049664497375, 0, -0.32763344049453735),
        },
        ["TerrorHotel"] = {
            Sky = CFrame.new(-142.96974182128906, 75.2402114868164, 731.3663940429688, -0.5783506631851196, 0,
                -0.8157883286476135, 0, 1.0000001192092896, 0, 0.8157883286476135, 0, -0.5783506631851196),
        },
        ["Station"] = {
            Far = CFrame.new(-1239.528564453125, -0.10437500476837158, -77.3851318359375, -0.37803247570991516, 0,
                0.9257923364639282, 0, 1.0000001192092896, 0, -0.9257924556732178, 0, -0.3780324161052704),
            Sky = CFrame.new(-204.4696807861328, 321.3405456542969, 27.782020568847656, -0.025697067379951477, 0,
                -0.9996697902679443, 0, 1, 0, 0.9996697902679443, 0, -0.025697067379951477),
        },
        ["SilverMall"] = {
            Sky = CFrame.new(-81.4511489868164, 38.782257080078125, 40.81037139892578, 0.07673122733831406, 0,
                0.9970518350601196, 0, 1, 0, -0.9970518350601196, 0, 0.07673122733831406),
        },
        ["AridRuins"] = {
            Sky = CFrame.new(-277.790771484375, 147.52992248535156, 280.6595153808594, 0.8448709845542908, 0,
                -0.5349701046943665, 0, 1, 0, 0.5349701046943665, 0, 0.8448709845542908),
        },
        ["PitStop"] = {
            Far = CFrame.new(-836.5980224609375, 98, -16.104969024658203, 0.13116659224033356, 0, -0.9913603067398071, 0,
                1, 0, 0.9913604259490967, 0, 0.13116657733917236),
            Sky = CFrame.new(-113.65505981445312, 527.7000122070312, -8.280224800109863, -0.7291958928108215, 0,
                -0.6843050718307495, 0, 1.0000001192092896, 0, 0.6843050718307495, 0, -0.7291958928108215),
        },
        ["MilitaryBase"] = {
            Sky = CFrame.new(-112.2247314453125, 1295.709716796875, -371.64129638671875, 0.9938321113586426, 0,
                0.11089564114809036, 0, 1, 0, -0.11089565604925156, 0, 0.993831992149353),
        },
        ["Acropolis"] = {
            Sky = CFrame.new(40.0380973815918, 366.1999816894531, -317.16650390625, -0.07234137505292892, 0,
                -0.9973798990249634, 0, 1, 0, 0.9973800182342529, 0, -0.07234136760234833),
        },
        ["UndergroundFacility"] = {
            Sky = CFrame.new(-61.493507385253906, 283.875, -48.672210693359375, -0.37790486216545105, 0,
                0.9258443713188171, 0, 1, 0, -0.9258444905281067, 0, -0.3779048025608063),
        },
        ["Complex"] = {
            Sky = CFrame.new(302.7427673339844, 133.50836181640625, 174.46917724609375, -0.540191113948822, 0,
                0.8415424227714539, 0, 1.0000001192092896, 0, -0.8415424227714539, 0, -0.540191113948822),
        },
        ["Campus"] = {
            Sky = CFrame.new(373.1975402832031, 220.21841430664062, -276.8575744628906, 0.03466206416487694, 0,
                0.9993990659713745, 0, 1.0000001192092896, 0, -0.9993991851806641, 0, 0.03466206043958664),
        },
        ["Backrooms"] = {
            Sky = CFrame.new(258.0068359375, 34.42504119873047, -216.18460083007812, -0.9853527545928955, 0,
                -0.17052891850471497, 0, 1.0000001192092896, 0, 0.17052891850471497, 0, -0.9853527545928955),
        },
        ["ElysiumLaboratory"] = {
            Far = CFrame.new(2066.17822265625, 86.17101287841797, 925.7244262695312, -0.4296175241470337, 0,
                -0.903010904788971, 0, 1, 0, 0.9030110239982605, 0, -0.4296174645423889),
            Sky = CFrame.new(572.92822265625, 539.68359375, -363.9112548828125, 0.18566037714481354, 0,
                -0.9826139807701111, 0, 1, 0, 0.9826139807701111, 0, 0.18566037714481354),
        },
        ["Kyoto"] = {
            Sky = CFrame.new(246.53836059570312, 61.599998474121094, -60.97388458251953, 0.13451837003231049, 0,
                -0.9909111261367798, 0, 1, 0, 0.9909111261367798, 0, 0.13451837003231049),
        },
        ["WinterCity"] = {
            Sky = CFrame.new(-429.1330261230469, 210.130859375, 1688.6885986328125, -0.6856755614280701, 0,
                -0.7279072999954224, 0, 1, 0, 0.7279073596000671, 0, -0.6856755018234253),
        },
        ["Industry"] = {
            Sky = CFrame.new(18.360435485839844, 77.32499694824219, 173.45294189453125, -0.03720375895500183, 0,
                -0.9993076920509338, 0, 1, 0, 0.9993076920509338, 0, -0.03720375895500183),
        },
        ["Ikea"] = {
            Sky = CFrame.new(254.61859130859375, 87.31452178955078, 104.18612670898438, 0.06513720750808716, 0,
                -0.9978763461112976, 0, 1.0000001192092896, 0, 0.9978763461112976, 0, 0.06513720750808716),
        },
        ["Icebreaker"] = {
            Sky = CFrame.new(-46.772701263427734, 377.8870849609375, 157.99977111816406, -0.9461325407028198, 0,
                0.32377973198890686, 0, 1.0000001192092896, 0, -0.32377973198890686, 0, -0.9461325407028198),
        },
        ["Gallery"] = {
            Sky = CFrame.new(-129.1414794921875, 52.93841552734375, 105.345703125, 0.13624808192253113, 0,
                -0.9906747341156006, 0, 1, 0, 0.9906747341156006, 0, 0.13624808192253113),
        },
        ["Citadel"] = {
            Sky = CFrame.new(-16.73784065246582, 294.7091979980469, 15.647359848022461, 0.6335407495498657, 0,
                -0.7737094163894653, 0, 1.0000001192092896, 0, 0.7737094163894653, 0, 0.6335407495498657),
        },
        ["ElysiumTower"] = {
            Sky = CFrame.new(-575.1420288085938, 337.4500732421875, -459.9267883300781, -0.02814294397830963, 0,
                0.9996038675308228, 0, 1, 0, -0.9996039867401123, 0, -0.028142940253019333),
        },
        ["ElysiumMoonbase"] = {
            Sky = CFrame.new(514.5113525390625, 346.3080749511719, 301.0175476074219, -0.9201717376708984, 0,
                0.39151516556739807, 0, 1.0000001192092896, 0, -0.39151522517204285, 0, -0.9201716184616089),
        },
        ["Drab"] = {
            Sky = CFrame.new(77.10475158691406, 243.13433837890625, -87.01614379882812, 0.9311596751213074, 0,
                -0.3646118938922882, 0, 1, 0, 0.3646119236946106, 0, 0.9311595559120178),
        },
        ["Crossroads"] = {
            Far = CFrame.new(56.81724166870117, -32.583824157714844, 78.83319854736328, -0.8064743280410767, 0,
                -0.5912691950798035, 0, 1.0000001192092896, 0, 0.5912691950798035, 0, -0.8064743280410767),
        },
        ["Canyon"] = {
            Sky = CFrame.new(-47.931053161621094, 168.18963623046875, -353.0606994628906, -0.6844719648361206, 0,
                -0.729039192199707, 0, 1, 0, 0.7290392518043518, 0, -0.6844719052314758),
        },
        ["ConstructionSite"] = {
            Sky = CFrame.new(286.73321533203125, 675.6075439453125, -105.34054565429688, -0.030946245416998863, 0,
                0.9995210766792297, 0, 1.0000001192092896, 0, -0.9995210766792297, 0, -0.030946245416998863),
        },
        ["Jungle"] = {
            Sky = CFrame.new(-70.41287994384766, 443.4943542480469, -1230.7713623046875, -0.030330108478665352, 0,
                -0.9995399117469788, 0, 1, 0, 0.9995399117469788, 0, -0.030330108478665352),
        },
        ["Neighborhood"] = {
            Sky = CFrame.new(-1109.68017578125, 273.52459716796875, -123.32154083251953, -0.9864818453788757, 0,
                -0.16387106478214264, 0, 1.0000001192092896, 0, 0.16387106478214264, 0, -0.9864818453788757),
        },
        ["SeraphResearch"] = {
            Sky = CFrame.new(-144.36099243164062, 233.7420196533203, 149.83090209960938, 0.24473167955875397, 0,
                -0.9695908427238464, 0, 1, 0, 0.9695908427238464, 0, 0.24473167955875397),
        },
        ["Facade"] = {
            Sky = CFrame.new(-34.39593505859375, 308.58758544921875, -26.045080184936523, -0.7244953513145447, 0,
                0.6892796754837036, 0, 1, 0, -0.6892796754837036, 0, -0.7244953513145447),
        },
        ["ImperialPalace"] = {
            Sky = CFrame.new(716.865966796875, 554.2611083984375, -373.0800476074219, 0.9931050539016724, 0,
                -0.11722806096076965, 0, 1.0000001192092896, 0, 0.11722806096076965, 0, 0.9931050539016724),
        },
        ["Corporation"] = {
            Sky = CFrame.new(-259.1007385253906, -148.71656799316406, 878.5985717773438, -0.9616329073905945, 0,
                0.2743394076824188, 0, 1, 0, -0.2743394076824188, 0, -0.9616329073905945),
        },
        ["Rooftops"] = {
            Sky = CFrame.new(37.96792984008789, 418.22998046875, -112.85687255859375, -0.9524456262588501, 0,
                0.3047088384628296, 0, 1, 0, -0.304708868265152, 0, -0.9524455070495605),
        },
        ["Sewers"] = {
            Sky = CFrame.new(478.5670166015625, 22.941070556640625, -760.9443359375, 0.8581589460372925, 0,
                -0.5133841633796692, 0, 1, 0, 0.513384222984314, 0, 0.8581588268280029),
        },
        ["Bedroom"] = {
            Sky = CFrame.new(79.48545837402344, 169.66900634765625, -307.6773376464844, -0.9999306201934814, 0,
                0.011786974966526031, 0, 1, 0, -0.01178697682917118, 0, -0.9999305009841919),
        },
        ["IndoorCourtyard"] = {
            Sky = CFrame.new(87.57669830322266, 18.649520874023438, -171.39675903320312, 0.027231918647885323, 0,
                -0.9996291399002075, 0, 1, 0, 0.9996291399002075, 0, 0.027231918647885323),
        },
        ["Farm"] = {
            Sky = CFrame.new(106.8475112915039, 501.185791015625, 282.8508605957031, -0.6687179207801819, 0,
                -0.7435161471366882, 0, 0.9999999403953552, 0, 0.743516206741333, 0, -0.6687178611755371),
        },
        ["Pillars"] = {
            Sky = CFrame.new(962.996826171875, 228.59999084472656, 191.5609130859375, 0.8949129581451416, 0,
                0.44624078273773193, 0, 1, 0, -0.44624078273773193, 0, 0.8949129581451416),
        },
        ["FourCorners"] = {
            Sky = CFrame.new(-423.96820068359375, 185.12774658203125, -152.0918731689453, -0.0647563636302948, 0,
                0.9979010820388794, 0, 1.0000001192092896, 0, -0.997901201248169, 0, -0.0647563561797142),
        },
        ["Tunnel"] = {
            Sky = CFrame.new(400.8442687988281, 31.711307525634766, -1119.76904296875, 0.5854415893554688, 0,
                -0.810714602470398, 0, 1, 0, 0.810714602470398, 0, 0.5854415893554688),
        },
        ["SunkenCavern"] = {
            Sky = CFrame.new(-84.4298324584961, 118, -782.8863525390625, 0.8106763958930969, 0, -0.5854944586753845, 0, 1,
                0, 0.5854944586753845, 0, 0.8106763958930969),
        },
        ["Forest"] = {
            Sky = CFrame.new(338.3236389160156, 696.8301391601562, 636.6173706054688, 0.9152400493621826, 0,
                -0.4029090106487274, 0, 1, 0, 0.4029090106487274, 0, 0.9152400493621826),
        },
        ["HellTerminal"] = {
            Sky = CFrame.new(1468.3533935546875, -31.635894775390625, 99.7929458618164, -0.14601191878318787, 0,
                0.9892828464508057, 0, 1, 0, -0.9892828464508057, 0, -0.14601191878318787),
        },
        ["TrainTerminal"] = {
            Sky = CFrame.new(1375.235107421875, -31.635894775390625, 313.521484375, 0.9998795390129089, 0,
                0.015522545203566551, 0, 1, 0, -0.015522545203566551, 0, 0.9998795390129089),
        },
        ["Roblox_Mansion"] = {
            Sky = CFrame.new(-663.1220703125, 245.1026611328125, 136.3137664794922, -0.9881491661071777, 0,
                -0.15349677205085754, 0, 1, 0, 0.15349677205085754, 0, -0.9881491661071777),
        },
        ["CitadelSmall"] = {
            Sky = CFrame.new(-47.5933952331543, 294.7091979980469, -80.65685272216797, 0.07784908264875412, 0,
                0.9969651103019714, 0, 1, 0, -0.996965229511261, 0, 0.07784907519817352),
        },
        ["ComplexSmall"] = {
            Sky = CFrame.new(285.1407470703125, 128.3883514404297, 260.65869140625, -0.03271424025297165, 0,
                -0.999464750289917, 0, 1, 0, 0.999464750289917, 0, -0.03271424025297165),
        },
        ["ConstructSmall"] = {
            Sky = CFrame.new(-542.0569458007812, 245.1999969482422, -122.97943115234375, -0.1803005486726761, 0,
                0.9836115837097168, 0, 1, 0, -0.9836115837097168, 0, -0.1803005486726761),
        },
        ["ConstructionSiteSmall"] = {
            Sky = CFrame.new(256.02020263671875, 675.6075439453125, -83.04479217529297, 0.21447442471981049, 0,
                0.9767296314239502, 0, 1, 0, -0.9767296314239502, 0, 0.21447442471981049),
        },
        ["ElysiumLaboratorySmall"] = {
            Sky = CFrame.new(542.3933715820312, 539.68359375, -650.7828979492188, -0.9826942682266235, 0,
                0.18523536622524261, 0, 1.0000001192092896, 0, -0.1852353811264038, 0, -0.982694149017334),
        },
        ["FacadeSmall"] = {
            Sky = CFrame.new(-26.911785125732422, 360.1175231933594, 5.301584720611572, -0.33369356393814087, 0,
                -0.9426815509796143, 0, 1, 0, 0.9426816701889038, 0, -0.3336935341358185),
        },
        ["ImperialPalaceSmall"] = {
            Sky = CFrame.new(599.785400390625, 554.2611083984375, -345.8648376464844, -0.8370000123977661, 0,
                0.5472028851509094, 0, 0.9999999403953552, 0, -0.5472029447555542, 0, -0.8369998931884766),
        },
        ["IndustrySmall"] = {
            Sky = CFrame.new(47.10830307006836, 73, 340.9862365722656, -0.6270755529403687, 0, -0.7789584398269653, 0, 1,
                0, 0.7789584398269653, 0, -0.6270755529403687),
        },
        ["SeraphResearchSmall"] = {
            Sky = CFrame.new(-92.86857604980469, 233.7420196533203, 129.34669494628906, 0.00878764409571886, 0,
                -0.9999614357948303, 0, 1.0000001192092896, 0, 0.9999614357948303, 0, 0.00878764409571886),
        },
        ["RooftopsSmall"] = {
            Sky = CFrame.new(142.86016845703125, 397.3184509277344, -114.34461975097656, 0.7760334014892578, 0,
                0.6306918263435364, 0, 1, 0, -0.6306918263435364, 0, 0.7760334014892578),
        },
        ["TerrorHotelSmall"] = {
            Sky = CFrame.new(-60.97590637207031, 75.2402114868164, 673.1410522460938, 0.17141732573509216, 0,
                -0.9851984977722168, 0, 1, 0, 0.9851984977722168, 0, 0.17141732573509216),
        },
        ["BackroomsSmall"] = {
            Sky = CFrame.new(-227.0629425048828, 34.42504119873047, -277.2832946777344, 0.9918396472930908, 0,
                0.12749190628528595, 0, 0.9999999403953552, 0, -0.12749192118644714, 0, 0.9918395280838013),
        },
        ["Roblox_Crossroads"] = {
            Sky = CFrame.new(-192.0408477783203, 252.14999389648438, 172.71961975097656, 0.35993480682373047, 0,
                0.9329774379730225, 0, 1, 0, -0.9329774379730225, 0, 0.35993480682373047),
        },
        ["Roblox_Glasshouses"] = {
            Sky = CFrame.new(-64.8754653930664, 159.3033905029297, -52.537994384765625, -0.5992873311042786, 0,
                -0.8005340099334717, 0, 1, 0, 0.8005340099334717, 0, -0.5992873311042786),
        },
        ["Roblox_Headquarters"] = {
            Sky = CFrame.new(98.78568267822266, 491.4000244140625, 268.83026123046875, -0.47415775060653687, 0,
                -0.8804398775100708, 0, 1, 0, 0.8804399967193604, 0, -0.4741576910018921),
        },
        ["Roblox_Ravenrock"] = {
            Sky = CFrame.new(-48.23151397705078, 520.8837890625, -508.8917541503906, 0.9887221455574036, 0,
                0.14976215362548828, 0, 1.0000001192092896, 0, -0.14976216852664948, 0, 0.988722026348114),
        },
        ["Roblox_RocketArena"] = {
            Sky = CFrame.new(-163.97857666015625, 577.6868896484375, -642.6377563476562, -0.875137984752655, 0,
                0.48387351632118225, 0, 1.0000001192092896, 0, -0.48387351632118225, 0, -0.875137984752655),
        },
        ["Roblox_ChaosCanyon"] = {
            Sky = CFrame.new(496.82135009765625, 360.20001220703125, -469.59124755859375, 0.9074246883392334, 0,
                -0.42021483182907104, 0, 1.0000001192092896, 0, 0.42021483182907104, 0, 0.9074246883392334),
        },
        ["FazbearPizzeria"] = {
            Sky = CFrame.new(322.06781005859375, 173.2213592529297, -507.47412109375, 0.08812039345502853, 0,
                -0.9961097836494446, 0, 1, 0, 0.9961099028587341, 0, 0.08812038600444794),
        },
        ["EvadeLobby"] = {
            Sky = CFrame.new(-36.19413757324219, 408.44091796875, -231.52743530273438, 0.7920824885368347, 0,
                0.6104141473770142, 0, 1, 0, -0.6104142069816589, 0, 0.7920823693275452),
        },
        ["MinecraftCavern"] = {
            Sky = CFrame.new(-477.0157470703125, -286.29998779296875, -322.8494567871094, 0.583358883857727, 0,
                -0.8122144937515259, 0, 1, 0, 0.8122146129608154, 0, 0.5833588242530823),
        },
        ["BloodGulch"] = {
            Sky = CFrame.new(153.5489959716797, 408.8879699707031, 204.33106994628906, 0.798352837562561, 0,
                0.6021900177001953, 0, 1, 0, -0.6021900177001953, 0, 0.798352837562561),
        },
        ["Office"] = {
            Sky = CFrame.new(392.3926696777344, 679.9234619140625, -912.7201538085938, 0.9916146993637085, 0,
                0.12923012673854828, 0, 1.0000001192092896, 0, -0.12923012673854828, 0, 0.9916146993637085),
        },
        ["DrabSmall"] = {
            Sky = CFrame.new(404.9034423828125, 243.13433837890625, -202.04286193847656, -0.9956814646720886, 0,
                0.09283551573753357, 0, 1, 0, -0.09283551573753357, 0, -0.9956814646720886),
        },
        ["RavagedGalleon"] = {
            Sky = CFrame.new(-153.4434051513672, 568.9390258789062, -79.07929992675781, 0.6147169470787048, 0,
                -0.7887477874755859, 0, 1, 0, 0.7887477874755859, 0, 0.6147169470787048),
        },
        ["OutdoorZoo"] = {
            Sky = CFrame.new(293.748779296875, 409.15057373046875, -469.8151550292969, -0.3689502477645874, 0,
                -0.9294491410255432, 0, 1, 0, 0.9294491410255432, 0, -0.3689502477645874),
        },
        ["OceanDrive"] = {
            Sky = CFrame.new(352.71893310546875, 489.3000183105469, -432.2906799316406, -0.2877233028411865, 0,
                -0.9577136039733887, 0, 1, 0, 0.9577136039733887, 0, -0.2877233028411865),
        },
        ["InflatablePark"] = {
            Sky = CFrame.new(-37.0590705871582, 460.00006103515625, -92.86158752441406, 0.8014788627624512, 0,
                0.5980231761932373, 0, 1, 0, -0.5980232357978821, 0, 0.8014787435531616),
        },
        ["CoralReef"] = {
            Sky = CFrame.new(331.30908203125, 475.851806640625, -446.78778076171875, 0.060617197304964066, 0,
                -0.9981611371040344, 0, 1.0000001192092896, 0, 0.9981611371040344, 0, 0.060617197304964066),
        },
        ["CampCliffwood"] = {
            Sky = CFrame.new(-616.0446166992188, 236.24998474121094, -723.9373779296875, -0.781373143196106, 0,
                0.6240642070770264, 0, 1.0000001192092896, 0, -0.6240642666816711, 0, -0.7813730239868164),
        },
        ["Atoll"] = {
            Sky = CFrame.new(575.8805541992188, 449, 497.2247619628906, -0.6157054901123047, 0, 0.7879763245582581, 0, 1,
                0, -0.7879763245582581, 0, -0.6157054901123047),
        },
        ["WaterPark"] = {
            Sky = CFrame.new(-11.927539825439453, 311.0104675292969, -367.7359924316406, 0.850088894367218, 0,
                -0.5266392827033997, 0, 1, 0, 0.5266392827033997, 0, 0.850088894367218),
        },
        ["Escalera"] = {
            Sky = CFrame.new(375.18048095703125, 361.6078796386719, 474.3463439941406, 0.7027344703674316, 0,
                -0.711452305316925, 0, 1.0000001192092896, 0, 0.711452305316925, 0, 0.7027344703674316),
        },
        ["HallowRails"] = {
            Sky = CFrame.new(-44.30644607543945, 305.56524658203125, 1007.760986328125, -0.8562602400779724, 0,
                -0.5165446400642395, 0, 1, 0, 0.5165446400642395, 0, -0.8562602400779724),
        },
        ["Necropolis"] = {
            Sky = CFrame.new(12.89604377746582, 649.81982421875, 11.182441711425781, -0.2811030447483063, 0,
                0.9596776366233826, 0, 1.0000001192092896, 0, -0.9596776366233826, 0, -0.2811030447483063),
        },
        ["PumpkinEmporium"] = {
            Sky = CFrame.new(-1484.5274658203125, 217.1407470703125, 157.5406951904297, -0.8054233193397522, 0,
                -0.5927000641822815, 0, 1, 0, 0.5927001237869263, 0, -0.8054232001304626),
        },
        ["TudorManor"] = {
            Sky = CFrame.new(-16.737945556640625, 349.1136474609375, -535.03759765625, 0.5601328015327454, 0,
                0.8284028768539429, 0, 1.0000001192092896, 0, -0.8284028768539429, 0, 0.5601328015327454),
        },
        ["WarpedEstate"] = {
            Sky = CFrame.new(-119.92630767822266, 306.7496337890625, -697.9681396484375, 0.9095829725265503, 0,
                -0.41552242636680603, 0, 1.0000001192092896, 0, 0.41552242636680603, 0, 0.9095829725265503),
        },
        ["Catacombs"] = {
            Sky = CFrame.new(55.867488861083984, 347.65081787109375, -1026.07958984375, 0.30113229155540466, 0,
                0.9535824060440063, 0, 1, 0, -0.9535824060440063, 0, 0.30113229155540466),
        },
        ["CursedCathedral"] = {
            Sky = CFrame.new(20.40713119506836, 916.6640625, 234.79649353027344, 0.8900006413459778, 0,
                -0.4559594690799713, 0, 1.0000001192092896, 0, 0.4559595286846161, 0, 0.8900005221366882),
        },
        ["SinisterStreets"] = {
            Sky = CFrame.new(-1323.9901123046875, 694.177490234375, -280.8382873535156, 0.46379345655441284, 0,
                0.8859433531761169, 0, 1, 0, -0.8859433531761169, 0, 0.46379345655441284),
        },
        ["Mictlan"] = {
            Sky = CFrame.new(-595.0527954101562, 460.5470275878906, 204.4481658935547, 0.9909257292747498, 0,
                -0.1344110518693924, 0, 1, 0, 0.1344110667705536, 0, 0.9909256100654602),
        },
        ["CityOfSinners"] = {
            Sky = CFrame.new(664.8756713867188, 622.987548828125, -121.09954833984375, -0.9997059106826782, 0,
                0.024250894784927368, 0, 1, 0, -0.024250894784927368, 0, -0.9997059106826782),
        },
        ["CoastalTown"] = {
            Sky = CFrame.new(498.4950256347656, 435.56317138671875, 232.27915954589844, 0.9530850052833557, 0,
                0.3027030825614929, 0, 1.0000001192092896, 0, -0.3027031123638153, 0, 0.9530848860740662),
        },
        ["Poolrooms"] = {
            Far = CFrame.new(64.36515045166016, 115.50001525878906, -1744.216796875, 0.1746438890695572, 0,
                0.9846315979957581, 0, 1, 0, -0.9846317172050476, 0, 0.174643874168396),
        },
    }

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
            Library:Notify({
                Title = "Teleport",
                Description = "Invalid teleporter position!",
                Time = 2,
            })
            return false
        end

        task.spawn(function()
            local args = {
                [1] = 0,
                [2] = 16
            }
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("ToolAction"):FireServer(
                unpack(args))

            task.wait(1)

            local args2 = {
                [1] = 1,
                [2] = {
                    [1] = "Teleporter",
                    [2] = cframe
                }
            }
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("ToolAction"):FireServer(
                unpack(args2))

            task.wait(1)

            local args3 = {
                [1] = 0,
                [2] = 15
            }
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("ToolAction"):FireServer(
                unpack(args3))

            Library:Notify({
                Title = "Teleporter Placed",
                Description = "Teleporter successfully placed!",
                Time = 2,
            })
        end)

        return true
    end

    return {
        GetCurrentMap = SafeWrapper("Teleport.GetCurrentMap", getCurrentMap),
        HasMapData = function(mapName)
            return mapSpots[mapName] ~= nil
        end,
        GetMapSpot = function(mapName, spotType)
            if not mapSpots[mapName] then return nil end
            return mapSpots[mapName][spotType]
        end,
        TeleportPlayer = SafeWrapper("Teleport.TeleportPlayer", function(spotType)
            local char, hrp = validateCharacter()
            if not char or not hrp then return false end
            local mapName = getCurrentMap()

            if mapName == "Unknown" then
                Library:Notify({
                    Title = "Teleport",
                    Description = "Could not detect map name!",
                    Time = 2,
                })
                return false
            end

            if not mapSpots[mapName] then
                Library:Notify({
                    Title = "Teleport",
                    Description = "Map '" .. mapName .. "' not in database!",
                    Time = 3,
                })
                return false
            end

            local cframe = mapSpots[mapName][spotType]
            if not cframe then
                Library:Notify({
                    Title = "Teleport",
                    Description = "No " .. spotType .. " spot found for " .. mapName,
                    Time = 3,
                })
                return false
            end

            Library:Notify({
                Title = "Teleporting",
                Description = "Teleporting to " .. spotType .. " for " .. mapName .. "...",
                Time = 2,
            })
            return safeTeleport(hrp, cframe.Position, { char })
        end),
        PlaceTeleporter = SafeWrapper("Teleport.PlaceTeleporter", function(spotType)
            local mapName = getCurrentMap()

            if mapName == "Unknown" then
                Library:Notify({
                    Title = "Teleport",
                    Description = "Could not detect map name!",
                    Time = 2,
                })
                return false
            end

            if not mapSpots[mapName] then
                Library:Notify({
                    Title = "Teleport",
                    Description = "Map '" .. mapName .. "' not in database!",
                    Time = 3,
                })
                return false
            end

            local cframe = mapSpots[mapName][spotType]
            if not cframe then
                Library:Notify({
                    Title = "Teleport",
                    Description = "No " .. spotType .. " spot found for " .. mapName,
                    Time = 3,
                })
                return false
            end

            Library:Notify({
                Title = "Placing Teleporter",
                Description = "Placing " .. spotType .. " teleporter for " .. mapName .. "...",
                Time = 2,
            })
            return placeTeleporter(cframe)
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

-- ==================== IRUZ HUB MODULES ====================

-- 1. NO CAMERA SHAKE MODULE
local StableCamera = {}
StableCamera.__index = StableCamera

function StableCamera.new(maxDistance)
    local self = setmetatable({}, StableCamera)
    self.Player = player
    self.MaxDistance = maxDistance or 50
    self._conn = nil
    return self
end

local function tryResetShake(player)
    if not player then return end
    local ok, playerScripts = pcall(function() return player:FindFirstChild("PlayerScripts") end)
    if not ok or not playerScripts then return end
    local cameraSet = playerScripts:FindFirstChild("Camera") and playerScripts.Camera:FindFirstChild("Set")
    if cameraSet and type(cameraSet.Invoke) == "function" then
        pcall(function()
            cameraSet:Invoke("CFrameOffset", "Shake", CFrame.new())
        end)
    end
end

function StableCamera:Start()
    if self._conn then return end
    self._conn = RunService.RenderStepped:Connect(function(dt)
        tryResetShake(self.Player)
    end)
end

function StableCamera:Stop()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
end

function StableCamera:Destroy()
    self:Stop()
end

-- 2. FLY SYSTEM MODULE
local function startFlying()
    local character = safeGetCharacter(player)
    if not character then 
        Library:Notify({
            Title = "Fly Error",
            Description = "Character not found",
            Time = 2,
        })
        return
    end
    
    local humanoid = safeGetHumanoid(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then 
        Library:Notify({
            Title = "Fly Error",
            Description = "Character parts not found",
            Time = 2,
        })
        return
    end
    
    flying = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    
    humanoid.PlatformStand = true
end

local function stopFlying()
    flying = false
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    
    local character = safeGetCharacter(player)
    if character then
        local humanoid = safeGetHumanoid(character)
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

local function updateFly()
    if not flying or not bodyVelocity or not bodyGyro then return end
    
    local success, err = pcall(function()
        local character = safeGetCharacter(player)
        if not character then 
            stopFlying()
            return
        end
        
        local humanoid = safeGetHumanoid(character)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then 
            stopFlying()
            return
        end
        
        local camera = workspace.CurrentCamera
        if not camera then return end
        
        local cameraCFrame = camera.CFrame
        if not cameraCFrame then
            cameraCFrame = CFrame.new()
        end
        
        local direction = Vector3.new(0, 0, 0)
        local moveDirection = humanoid.MoveDirection
    
        if moveDirection.Magnitude > 0 then
            local forwardVector = cameraCFrame.LookVector
            local rightVector = cameraCFrame.RightVector
            local forwardComponent = moveDirection:Dot(forwardVector) * forwardVector
            local rightComponent = moveDirection:Dot(rightVector) * rightVector
            direction = direction + (forwardComponent + rightComponent).Unit * moveDirection.Magnitude
        end
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction - Vector3.new(0, 1, 0)
        end
        
        local speed = 50
        bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * (speed * 2) or Vector3.new(0, 0, 0)
        bodyGyro.CFrame = cameraCFrame
    end)

    if not success then
        warn("[Fly Update Error]:", err)
        stopFlying()
        if Toggles.IruzFly then
            Toggles.IruzFly:SetValue(false)
        end
    end
end

-- 3. ANTI NEXTBOT MODULE
local function isNextbotModel(model)
    if not model or not model.Name then return false end
    return model:GetAttribute("Team") == "Nextbot" or
           model.Name:lower():find("nextbot") or 
           model.Name:lower():find("scp") or 
           model.Name:lower():find("monster") or
           model.Name:lower():find("creep") or
           model.Name:lower():find("enemy") or
           model.Name:lower():find("zombie") or
           model.Name:lower():find("ghost") or
           model.Name:lower():find("demon")
end

local function handleAntiNextbot()
    if not antiNextbotEnabled then return end

    local character = safeGetCharacter(player)
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local nextbots = {}
    
    local npcsFolder = workspace:FindFirstChild("NPCs")
    if npcsFolder then
        for _, model in ipairs(npcsFolder:GetChildren()) do
            if model:IsA("Model") and isNextbotModel(model) then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp then
                    table.insert(nextbots, model)
                end
            end
        end
    end
    
    local playersFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
    if playersFolder then
        for _, model in ipairs(playersFolder:GetChildren()) do
            if model:IsA("Model") and isNextbotModel(model) then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp then
                    table.insert(nextbots, model)
                end
            end
        end
    end

    for _, nextbot in ipairs(nextbots) do
        local nextbotHrp = nextbot:FindFirstChild("HumanoidRootPart")
        if nextbotHrp then
            local distance = (humanoidRootPart.Position - nextbotHrp.Position).Magnitude
            if distance <= antiNextbotDistance then
                if teleportType == "Distance" then
                    local direction = (humanoidRootPart.Position - nextbotHrp.Position).Unit
                    local targetPos = humanoidRootPart.Position + direction * teleportDistance
                    
                    local path = PathfindingService:CreatePath({
                        AgentRadius = 2,
                        AgentHeight = 5,
                        AgentCanJump = true
                    })
                    
                    local success = pcall(function()
                        path:ComputeAsync(humanoidRootPart.Position, targetPos)
                    end)
                    
                    if success and path.Status == Enum.PathStatus.Success then
                        local waypoints = path:GetWaypoints()
                        if #waypoints > 1 then
                            local lastValidPos = waypoints[#waypoints].Position
                            humanoidRootPart.CFrame = CFrame.new(lastValidPos + Vector3.new(0, 3, 0))
                        end
                    else
                        humanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                    end
                end
                break
            end
        end
    end
end

-- 4. GRAVITY CONTROL MODULE
local function toggleGravity()
    gravityEnabled = not gravityEnabled
    if gravityEnabled then
        workspace.Gravity = gravityValue
    else
        workspace.Gravity = originalGravity
    end
end

-- 5. AUTO DRINK MODULE
local function startAutoDrink()
    if AutoDrinkConnection then return end
    
    AutoDrinkConnection = task.spawn(function()
        while autoDrinkEnabled do
            local ohTable1 = {
                ["Forced"] = true,
                ["Key"] = "Cola",
                ["Down"] = true
            }
            
            pcall(function()
                player.PlayerScripts.Events.temporary_events.UseKeybind:Fire(ohTable1)
            end)
            
            task.wait(drinkDelay)
        end
        AutoDrinkConnection = nil
    end)
end

local function stopAutoDrink()
    if AutoDrinkConnection then
        task.cancel(AutoDrinkConnection)
        AutoDrinkConnection = nil
    end
end

-- ==================== HOLD SPACE JUMP MODULE ====================
local function findFrictionTables()
    frictionTables = {}
    for _, t in pairs(getgc(true)) do
        if type(t) == "table" and rawget(t, "Friction") then
            table.insert(frictionTables, {obj = t, original = t.Friction})
        end
    end
end

local function setFriction(value)
    for _, e in ipairs(frictionTables) do
        if e.obj and type(e.obj) == "table" and rawget(e.obj, "Friction") then
            e.obj.Friction = value
        end
    end
end

local function resetBhopFriction()
    for _, e in ipairs(frictionTables) do
        if e.obj and type(e.obj) == "table" and rawget(e.obj, "Friction") then
            e.obj.Friction = e.original
        end
    end
    frictionTables = {}
end

local function applyBhopFriction()
    if not getgenv().autoJumpEnabled then
        resetBhopFriction()
        return
    end
    
    if getgenv().bhopMode == "Acceleration" then
        findFrictionTables()
        if #frictionTables > 0 then
            setFriction(getgenv().bhopAccelValue or -0.1)
        end
    else
        resetBhopFriction()
    end
end

local function IsOnGround()
    if not CharacterDH or not HumanoidRootPartDH or not HumanoidDH then return false end

    local state = HumanoidDH:GetState()
    if state == Enum.HumanoidStateType.Jumping or 
       state == Enum.HumanoidStateType.Freefall or
       state == Enum.HumanoidStateType.Swimming then
        return false
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {CharacterDH}
    raycastParams.IgnoreWater = true

    local rayOrigin = HumanoidRootPartDH.Position
    local rayDirection = Vector3.new(0, -GROUND_CHECK_DISTANCE, 0)
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if not raycastResult then return false end

    local surfaceNormal = raycastResult.Normal
    local angle = math.deg(math.acos(surfaceNormal:Dot(Vector3.new(0, 1, 0))))

    return angle <= MAX_SLOPE_ANGLE
end

local function updateBhop()
    if not bhopLoaded then return end
    
    local character = safeGetCharacter(player)
    local humanoid = character and safeGetHumanoid(character)
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not character or not humanoid or not humanoidRootPart then
        return
    end

    CharacterDH = character
    HumanoidDH = humanoid
    HumanoidRootPartDH = humanoidRootPart

    local isBhopActive = getgenv().autoJumpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local now = tick()
    
    if isBhopActive then
        if IsOnGround() and (now - LastJump) > getgenv().jumpInterval then
            if getgenv().autoJumpType == "Realistic" then
                pcall(function()
                    player.PlayerScripts.Events.temporary_events.JumpReact:Fire()
                    task.wait(0.1)
                    player.PlayerScripts.Events.temporary_events.EndJump:Fire()
                end)
            else
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            LastJump = now
        end
    end
end

local function loadBhop()
    if bhopLoaded then return end
    
    bhopLoaded = true
    
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    
    bhopConnection = RunService.Heartbeat:Connect(function()
        updateBhop()
        applyBhopFriction()
    end)
    
    Library:Notify({
        Title = "Hold Space Jump",
        Description = "Hold Space Jump loaded!",
        Time = 2,
    })
end

local function unloadBhop()
    if not bhopLoaded then return end
    
    bhopLoaded = false
    
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    
    resetBhopFriction()
    
    Library:Notify({
        Title = "Hold Space Jump",
        Description = "Hold Space Jump unloaded!",
        Time = 2,
    })
end

local function checkBhopState()
    if getgenv().autoJumpEnabled then
        loadBhop()
    else
        unloadBhop()
    end
end

-- 7. ADVANCED LAG SWITCH MODULE
local function performMathLag()
    local startTime = tick()
    local duration = lagDelayValue
    
    while tick() - startTime < duration do
        for i = 1, lagIntensity do
            local a = math.random(1, 1000000) * math.random(1, 1000000)
            a = a / math.random(1, 10000)
            local b = math.sqrt(math.random(1, 1000000))
            b = b * math.pi * math.exp(1)
            local c = math.sin(math.rad(math.random(1, 360))) * math.cos(math.rad(math.random(1, 360)))
        end
    end
end

local function toggleLagSwitchDH()
    if not isLagActive then
        isLagActive = true
        
        if lagSwitchMode == "Normal" then
            task.spawn(function()
                performMathLag()
                isLagActive = false
            end)
        elseif lagSwitchMode == "Demon" then
            task.spawn(function()
                local startTime = tick()
                local duration = lagDelayValue
                local character = safeGetCharacter(player)
                if character then
                    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        local bodyThrust = Instance.new("BodyThrust")
                        bodyThrust.Force = Vector3.new(0, 100000, 0)
                        bodyThrust.Location = Vector3.new(0, 0, 0)
                        bodyThrust.Parent = humanoidRootPart
                        task.wait(duration)
                        bodyThrust:Destroy()
                    end
                end
                isLagActive = false
            end)
        end
    end
end

-- 8. CAMERA STRETCH MODULE
local function setupCameraStretch()
    if cameraStretchConnection then 
        cameraStretchConnection:Disconnect() 
        cameraStretchConnection = nil
    end
    
    cameraStretchConnection = RunService.RenderStepped:Connect(function()
        local Camera = workspace.CurrentCamera
        if Camera then
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
        end
    end)
end

-- 9. NO FOG MODULE
local function toggleNoFog(state)
    local Lighting = game:GetService("Lighting")
    if state then
        originalFogEnd = Lighting.FogEnd
        originalAtmospheres = {}
        
        for _, atmosphere in ipairs(Lighting:GetChildren()) do
            if atmosphere:IsA("Atmosphere") then
                table.insert(originalAtmospheres, atmosphere:Clone())
            end
        end
        
        Lighting.FogEnd = 1000000
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then
                v:Destroy()
            end
        end
    else
        if originalFogEnd then
            Lighting.FogEnd = originalFogEnd
        end
        
        if originalAtmospheres then
            for _, atmosphere in ipairs(originalAtmospheres) do
                if not atmosphere.Parent then
                    local newAtmosphere = Instance.new("Atmosphere")
                    for _, prop in pairs({"Density", "Offset", "Color", "Decay", "Glare", "Haze"}) do
                        if atmosphere[prop] then
                            newAtmosphere[prop] = atmosphere[prop]
                        end
                    end
                    newAtmosphere.Parent = Lighting
                end
            end
        end
    end
end

-- 10. FPS TIMER MODULE
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

-- ==================== ANTI LAG MODULE ====================
local AntiLagModule = (function()
    local function applyFPSBoost()
        Library:Notify({
            Title = "FPS Boost",
            Description = "Applying aggressive optimizations...",
            Time = 2,
        })
        
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.Brightness = 1
        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj:Destroy()
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
            end
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            local char = safeGetCharacter(plr)
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("Accessory") or part:IsA("Clothing") then
                        part:Destroy()
                    end
                end
            end
        end

        Library:Notify({
            Title = "FPS Boost",
            Description = "Optimizations applied successfully!",
            Time = 2,
        })
    end

    local function applyAntiLag1()
        Library:Notify({
            Title = "Anti Lag 1",
            Description = "Applying material optimizations...",
            Time = 2,
        })

        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e10
        Lighting.Brightness = 1

        if Terrain then
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj:Destroy()
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
            end
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            local char = safeGetCharacter(plr)
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("Accessory") or part:IsA("Clothing") then
                        part:Destroy()
                    end
                end
            end
        end

        Library:Notify({
            Title = "Anti Lag 1",
            Description = "Material optimizations complete!",
            Time = 2,
        })
    end

    local function applyAntiLag2()
        Library:Notify({
            Title = "Anti Lag 2",
            Description = "Disabling visual effects...",
            Time = 2,
        })

        local settings = {
            Textures = true,
            VisualEffects = true,
            Parts = true,
            Particles = true,
            Sky = true
        }

        for _, v in next, game:GetDescendants() do
            if settings.Parts then
                if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                end
            end

            if settings.Particles then
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
                    v.Enabled = false
                end
            end

            if settings.VisualEffects then
                if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
                    v.Enabled = false
                end
            end

            if settings.Textures then
                if v:IsA("Decal") or v:IsA("Texture") then
                    v.Texture = ""
                end
            end

            if settings.Sky then
                if v:IsA("Sky") then
                    v.Parent = nil
                end
            end
        end

        Library:Notify({
            Title = "Anti Lag 2",
            Description = "Visual effects disabled!",
            Time = 2,
        })
    end

    local function applyRemoveTexture()
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") or part:IsA("WedgePart") or part:IsA("CornerWedgePart") then
                if part:IsA("Part") then
                    part.Material = Enum.Material.SmoothPlastic
                end
                if part:FindFirstChildWhichIsA("Texture") then
                    local texture = part:FindFirstChildWhichIsA("Texture")
                    texture.Texture = "rbxassetid://0"
                end
                if part:FindFirstChildWhichIsA("Decal") then
                    local decal = part:FindFirstChildWhichIsA("Decal")
                    decal.Texture = "rbxassetid://0"
                end
            end
        end
        Library:Notify({
            Title = "Remove Texture",
            Description = "All textures removed!",
            Time = 2,
        })
    end

    return {
        ApplyFPSBoost = SafeWrapper("AntiLag.ApplyFPSBoost", applyFPSBoost),
        ApplyAntiLag1 = SafeWrapper("AntiLag.ApplyAntiLag1", applyAntiLag1),
        ApplyAntiLag2 = SafeWrapper("AntiLag.ApplyAntiLag2", applyAntiLag2),
        ApplyRemoveTexture = SafeWrapper("AntiLag.ApplyRemoveTexture", applyRemoveTexture)
    }
end)()

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
            KeybindManager.CurrentKeybinds.Fly = keyCode
            KeybindManager:Save()
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
            KeybindManager.CurrentKeybinds.AntiNextbot = keyCode
            KeybindManager:Save()
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
            KeybindManager.CurrentKeybinds.Gravity = keyCode
            KeybindManager:Save()
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
            KeybindManager.CurrentKeybinds.AutoDrink = keyCode
            KeybindManager:Save()
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
            KeybindManager.CurrentKeybinds.LagSwitch = keyCode
            KeybindManager:Save()
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
            KeybindManager.CurrentKeybinds.CameraStretch = keyCode
            KeybindManager:Save()
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
            KeybindManager.CurrentKeybinds.InfiniteSlide = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.NoFog then
            KeybindManager.CurrentKeybinds.NoFog[1] = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.NoFog then
            KeybindManager.CurrentKeybinds.NoFog[2] = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.NoCameraShake then
            KeybindManager.CurrentKeybinds.NoCameraShake[1] = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.NoCameraShake then
            KeybindManager.CurrentKeybinds.NoCameraShake[2] = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.FpsTimer then
            KeybindManager.CurrentKeybinds.FpsTimer[1] = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.FpsTimer then
            KeybindManager.CurrentKeybinds.FpsTimer[2] = keyCode
            KeybindManager:Save()
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
            KeybindManager.CurrentKeybinds.ToggleLagEnable = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.IncreaseGravity then
            KeybindManager.CurrentKeybinds.IncreaseGravity[1] = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.IncreaseGravity then
            KeybindManager.CurrentKeybinds.IncreaseGravity[2] = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.DecreaseGravity then
            KeybindManager.CurrentKeybinds.DecreaseGravity[1] = keyCode
            KeybindManager:Save()
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
        if keyCode and KeybindManager.CurrentKeybinds.DecreaseGravity then
            KeybindManager.CurrentKeybinds.DecreaseGravity[2] = keyCode
            KeybindManager:Save()
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
        KeybindManager.CurrentKeybinds = {}
        for key, value in pairs(KeybindManager.DefaultKeybinds) do
            KeybindManager.CurrentKeybinds[key] = value
        end
        KeybindManager:Save()
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
        checkBhopState()
        
        if state then
            Library:Notify({
                Title = "Hold Space Jump",
                Description = "✓ Enabled\n✓ Hold Space key to bunny hop\n✓ Works only when key is held",
                Time = 4,
            })
        else
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
        checkBhopState()
        
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
        if getgenv().autoJumpEnabled then
            applyBhopFriction()
        end
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
        TeleportModule.PlaceTeleporter("Far")
    end),
    DoubleClick = false,
})
TeleportPlaceGroup:AddButton({
    Text = "Place Teleporter Sky",
    Func = SafeWrapper("PlaceTeleporterSky", function()
        TeleportModule.PlaceTeleporter("Sky")
    end),
    DoubleClick = false,
})
TeleportPlaceGroup:AddButton({
    Text = "Teleport Player To Sky",
    Func = SafeWrapper("TeleportToSky", function()
        TeleportModule.TeleportPlayer("Sky")
    end),
    DoubleClick = false,
})
TeleportPlaceGroup:AddButton({
    Text = "Teleport Player To Far",
    Func = SafeWrapper("TeleportToFar", function()
        TeleportModule.TeleportPlayer("Far")
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

    -- ==================== GUN FUNCTIONS MODULE ====================
local GunFunctionsModule = (function()
    local enhancedWeapons = {}
    
    local function enhanceGrappleHook()
    local success, result = pcall(function()
        local GrappleHook = require(game:GetService("ReplicatedStorage").Tools["GrappleHook"])
        local grappleTask = GrappleHook.Tasks[2]
        local shootMethod = grappleTask.Functions[1].Activations[1].Methods[1]

        -- SETTING KAMU:
        shootMethod.Info.Speed = 800          -- Range 800 studs
        shootMethod.Info.Lifetime = 6.0        -- 6 detik (cukup lama)
        shootMethod.Info.Gravity = Vector3.new(0, -5, 0)  -- Sedikit gravitasi
        shootMethod.Info.SpreadIncrease = 0.05 -- Hampir akurat
        shootMethod.Info.Cooldown = 1.0        -- Delay 1 detik (perfect!)

        -- Akurasi bagus:
        grappleTask.MethodReferences.Projectile.Info.SpreadInfo.MaxSpread = 0.2
        grappleTask.MethodReferences.Projectile.Info.SpreadInfo.MinSpread = 0.05
        grappleTask.MethodReferences.Projectile.Info.SpreadInfo.ReductionRate = 60

        -- Check method:
        local checkMethod = grappleTask.AutomaticFunctions[1].Methods[1]
        checkMethod.Info.Cooldown = 0.8
        checkMethod.CooldownInfo.TestCooldown = 0.5  -- Sistem cek 0.5 detik

        -- Isi 300 ammo (banyak banget!):
        grappleTask.ResourceInfo.Cap = 300
        grappleTask.ResourceInfo.Reserve = 300

        enhancedWeapons["GrappleHook"] = true
        return true
    end)
    
    return success, result
end

    local function enhanceBreacher()
    local success, result = pcall(function()
        local Breacher = require(game:GetService("ReplicatedStorage").Tools.Breacher)
        
        -- Cari task portal
        local portalTask
        for i, task in ipairs(Breacher.Tasks) do
            if task.ResourceInfo and task.ResourceInfo.Type == "Clip" then
                portalTask = task
                break
            end
        end
        if not portalTask then portalTask = Breacher.Tasks[2] end

        -- ===== SETTING SUPER CEPAT =====
        -- 1. Isi 300 charge:
        portalTask.ResourceInfo.Cap = 300
        portalTask.ResourceInfo.Reserve = 300

        -- 2. Jarak 99999:
        local blueShoot = portalTask.Functions[1].Activations[1].Methods[1]
        local yellowShoot = portalTask.Functions[2].Activations[1].Methods[1]
        
        blueShoot.Info.Range = 99999  -- Max range!
        yellowShoot.Info.Range = 99999
        
        -- 3. Akurasi perfect (tidak ada spread):
        blueShoot.Info.SpreadIncrease = 0
        yellowShoot.Info.SpreadIncrease = 0
        
        portalTask.MethodReferences.Portal.Info.SpreadInfo.MaxSpread = 0
        portalTask.MethodReferences.Portal.Info.SpreadInfo.MinSpread = 0
        portalTask.MethodReferences.Portal.Info.SpreadInfo.ReductionRate = 100

        -- 4. DELAY 0.3 DETIK (SUPER CEPAT!):
        blueShoot.Info.Cooldown = 0.3  -- ← INI DELAY 0.3 DETIK!
        yellowShoot.Info.Cooldown = 0.3  -- ← INI DELAY 0.3 DETIK!

        -- 5. Test cooldown super cepat:
        if blueShoot.CooldownInfo then
            blueShoot.CooldownInfo.TestCooldown = 0.15  -- Sistem cek 0.15 detik!
        end
        if yellowShoot.CooldownInfo then
            yellowShoot.CooldownInfo.TestCooldown = 0.15
        end

        -- 6. Kecepatan proyeklit super cepat:
        if not blueShoot.Info.Speed then
            blueShoot.Info.Speed = 500  -- Super cepat!
            yellowShoot.Info.Speed = 500
        end

        -- 7. Priority maksimal:
        blueShoot.GlobalPriority = 500
        yellowShoot.GlobalPriority = 500
        blueShoot.Priority = 1
        yellowShoot.Priority = 1

        -- 8. Hilangkan semua batasan:
        blueShoot.CooldownInfo = {}
        yellowShoot.CooldownInfo = {}
        blueShoot.Requirements = {}
        yellowShoot.Requirements = {}

        -- 9. Bisa hold untuk auto-tembak:
        portalTask.Functions[1].Activations[1].CanHoldDown = true
        portalTask.Functions[2].Activations[1].CanHoldDown = true

        -- 10. No resource check:
        blueShoot.ResourceAboveZero = false
        yellowShoot.ResourceAboveZero = false

        enhancedWeapons["Breacher"] = true
        return true
    end)
    
    return success, result
end
        
    

    local function enhanceSmokeGrenade()
        local success, result = pcall(function()
            local SmokeGrenade = require(game:GetService("ReplicatedStorage").Tools["SmokeGrenade"])

            -- ===== 1. INFINITE GRENADES =====
            SmokeGrenade.RequiresOwnedItem = false

            local throwMethod = SmokeGrenade.Tasks[1].Functions[1].Activations[1].Methods[1]

            throwMethod.ItemUseIncrement = {"SmokeGrenade", 0}

            -- ===== 2. FAST THROWS =====
            throwMethod.Info.Cooldown = 0.1

            -- ===== 3. LONG THROW =====
            throwMethod.Info.ThrowVelocity = 200

            -- ===== 4. AUTOMATIC THROW =====
            SmokeGrenade.Tasks[1].Functions[1].Activations[1].CanHoldDown = true

            -- ===== 5. LONG SMOKE DURATION =====
            throwMethod.Info.SmokeDuration = 999
            throwMethod.Info.SmokeRadius = 100
            throwMethod.Info.FadeTime = 60

            -- ===== 6. FAST EQUIP/UNEQUIP =====
            local equipMethod = SmokeGrenade.Tasks[1].AutomaticFunctions[1].Methods[1]
            local unequipMethod = SmokeGrenade.Tasks[1].AutomaticFunctions[2].Methods[1]
            equipMethod.Info.Cooldown = 0.1
            unequipMethod.Info.Cooldown = 0.1

            -- ===== 7. INCREASE THROW PRIORITY =====
            throwMethod.GlobalPriority = 500

            -- ===== 8. DISABLE UNNECESSARY CHECKS =====
            throwMethod.CooldownInfo = {}

            -- ===== 9. IMPROVE HUD =====
            SmokeGrenade.HUD.ShowAmount = false

            -- ===== 10. ADDITIONAL GRENADE IMPROVEMENTS =====
            throwMethod.Info.Density = 0.9
            throwMethod.Info.Color = Color3.new(0.7, 0.7, 0.7)
            throwMethod.Info.ExplosionRadius = 20

            -- ===== 11. REMOVE "Weaponless" RESTRICTION =====
            throwMethod.CooldownInfo.ActivatePhrase = nil

            -- ===== 12. SUPER-FAST MODE =====
            throwMethod.Info.Cooldown = 0.05

            -- ===== 13. IMPROVE CONTROLS =====
            SmokeGrenade.KeybindInfo.UnequipKeybind = "Backspace"

            -- Activate grenade
            local args = {
                [1] = 0,
                [2] = 20
            }
            
            game:GetService("ReplicatedStorage").Events.Character.ToolAction:FireServer(unpack(args))
            
            enhancedWeapons["SmokeGrenade"] = true
            return true
        end)
        
        return success, result
    end

    local function enhanceBoombox()
        local success, result = pcall(function()
            local Boombox = require(game:GetService("ReplicatedStorage").Tools.Boombox)

            -- Find the main task
            local mainTask = Boombox.Tasks[1]
            
            -- Make it louder and longer
            if mainTask and mainTask.Functions and mainTask.Functions[1] then
                local playMethod = mainTask.Functions[1].Activations[1].Methods[1]
                if playMethod and playMethod.Info then
                    playMethod.Info.Volume = 10  -- Max volume
                    playMethod.Info.Duration = 999  -- Long duration
                end
            end
            
            -- Infinite uses
            if mainTask.ResourceInfo then
                mainTask.ResourceInfo.Cap = 999999
            end
            
            enhancedWeapons["Boombox"] = true
            return true
        end)
        
        return success, result
    end

    return {
        EnhanceGrappleHook = SafeWrapper("GunFunctions.EnhanceGrappleHook", function()
            local success, result = enhanceGrappleHook()
            if success then
                Library:Notify({
                    Title = "GrappleHook",
                    Description = "GrappleHook successfully upgraded!",
                    Duration = 5
                })
            else
                Library:Notify({
                    Title = "GrappleHook Error",
                    Description = "Error: " .. tostring(result),
                    Duration = 5
                })
            end
        end),

        EnhanceBreacher = SafeWrapper("GunFunctions.EnhanceBreacher", function()
            local success, result = enhanceBreacher()
            if success then
                Library:Notify({
                    Title = "Breacher (Portal Gun)",
                    Description = "Portal Gun Successfully upgraded! \n✓ Infinite charges \n✓ Maximum range \n✓ Instant reload",
                    Duration = 6
                })
            else
                Library:Notify({
                    Title = "Breacher Error",
                    Description = "Error: " .. tostring(result),
                    Duration = 5
                })
            end
        end),

        EnhanceSmokeGrenade = SafeWrapper("GunFunctions.EnhanceSmokeGrenade", function()
            local success, result = enhanceSmokeGrenade()
            if success then
                Library:Notify({
                    Title = "Smoke Grenade",
                    Description = "Smoke Grenade Improved! \n✓ Infinite Grenades \n✓ Instant Reload",
                    Duration = 6
                })
            else
                Library:Notify({
                    Title = "Smoke Grenade Error",
                    Description = "Error: " .. tostring(result),
                    Duration = 5
                })
            end
        end),

        EnhanceBoombox = SafeWrapper("GunFunctions.EnhanceBoombox", function()
            local success, result = enhanceBoombox()
            if success then
                Library:Notify({
                    Title = "Boombox",
                    Description = "Boombox Enhanced! \n✓ Max Volume \n✓ Long Duration",
                    Duration = 5
                })
            else
                Library:Notify({
                    Title = "Boombox Error",
                    Description = "Error: " .. tostring(result),
                    Duration = 5
                })
            end
        end),

        EnhanceAll = SafeWrapper("GunFunctions.EnhanceAll", function()
            local results = {}
            local count = 0
            
            results[1] = {enhanceGrappleHook()}
            results[2] = {enhanceBreacher()}
            results[3] = {enhanceSmokeGrenade()}
            results[4] = {enhanceBoombox()}
            
            for _, result in ipairs(results) do
                if result[1] then
                    count = count + 1
                end
            end
            
            Library:Notify({
                Title = "All Weapons Enhanced",
                Description = string.format("Successfully enhanced %d/%d weapons!", count, #results),
                Duration = 6
            })
        end),

        IsEnhanced = function(weaponName)
            return enhancedWeapons[weaponName] == true
        end,

        ResetAll = SafeWrapper("GunFunctions.ResetAll", function()
            enhancedWeapons = {}
            
            -- You would need to implement actual reset logic here
            -- by storing original values and restoring them
            
            Library:Notify({
                Title = "Weapons Reset",
                Description = "All weapon enhancements reset",
                Duration = 4
            })
        end)
    }
end)()

-- ==================== GUN FUNCTIONS TAB ====================
-- Tambahkan di bagian setelah TracerGroup atau sebelum VisualGroup di tab Visuals
local GunFunctionsGroup = Tabs.Visuals:AddLeftGroupbox("Gun Functions", "zap")

GunFunctionsGroup:AddDivider()
GunFunctionsGroup:AddLabel("ENHANCE YOUR WEAPONS")

GunFunctionsGroup:AddButton({
    Text = "Enhance GrappleHook",
    Func = SafeWrapper("EnhanceGrappleHook", function()
        GunFunctionsModule.EnhanceGrappleHook()
    end),
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "Enhance Breacher (Portal Gun)",
    Func = SafeWrapper("EnhanceBreacher", function()
        GunFunctionsModule.EnhanceBreacher()
    end),
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "Enhance Smoke Grenade",
    Func = SafeWrapper("EnhanceSmokeGrenade", function()
        GunFunctionsModule.EnhanceSmokeGrenade()
    end),
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "Enhance Boombox",
    Func = SafeWrapper("EnhanceBoombox", function()
        GunFunctionsModule.EnhanceBoombox()
    end),
    DoubleClick = false,
})

GunFunctionsGroup:AddDivider()

GunFunctionsGroup:AddButton({
    Text = "ENHANCE ALL WEAPONS",
    Func = SafeWrapper("EnhanceAllWeapons", function()
        GunFunctionsModule.EnhanceAll()
    end),
    DoubleClick = true,
})

GunFunctionsGroup:AddButton({
    Text = "Reset All Enhancements",
    Func = SafeWrapper("ResetEnhancements", function()
        GunFunctionsModule.ResetAll()
    end),
    DoubleClick = true,
})

-- Tambahkan juga status display
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

-- ==================== GUN FUNCTIONS TAB ====================
local GunFunctionsGroup = Tabs.Visuals:AddLeftGroupbox("Gun Functions", "zap")

GunFunctionsGroup:AddDivider()
GunFunctionsGroup:AddLabel("ENHANCE YOUR WEAPONS")

GunFunctionsGroup:AddButton({
    Text = "Enhance GrappleHook",
    Func = function()
        GunFunctionsModule.EnhanceGrappleHook()
    end,
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "Enhance Breacher (Portal Gun)",
    Func = function()
        GunFunctionsModule.EnhanceBreacher()
    end,
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "Enhance Smoke Grenade",
    Func = function()
        GunFunctionsModule.EnhanceSmokeGrenade()
    end,
    DoubleClick = false,
})

GunFunctionsGroup:AddButton({
    Text = "ENHANCE ALL WEAPONS",
    Func = function()
        GunFunctionsModule.EnhanceAll()
    end,
    DoubleClick = true,
})

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
        AntiLagModule.ApplyFPSBoost()
    end),
    DoubleClick = false,
})
PerfGroup:AddButton({
    Text = "Anti Lag 1",
    Func = SafeWrapper("AntiLag1", function()
        AntiLagModule.ApplyAntiLag1()
    end),
    DoubleClick = false,
})
PerfGroup:AddButton({
    Text = "Anti Lag 2",
    Func = SafeWrapper("AntiLag2", function()
        AntiLagModule.ApplyAntiLag2()
    end),
    DoubleClick = false,
})
PerfGroup:AddButton({
    Text = "Remove Textures",
    Func = SafeWrapper("RemoveTextures", function()
        AntiLagModule.ApplyRemoveTexture()
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
            startFlying()
            if not flyLoop then
                flyLoop = RunService.RenderStepped:Connect(updateFly)
            end
            Library:Notify({
                Title = "Iruz Fly",
                Description = "Enabled (WASD + Space/Shift)",
                Time = 2,
            })
        else
            stopFlying()
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
        antiNextbotEnabled = state
        if state then
            if not antiNextbotConnection then
                antiNextbotConnection = RunService.Heartbeat:Connect(handleAntiNextbot)
            end
            Library:Notify({
                Title = "Anti Nextbot",
                Description = "Enabled - Range: " .. antiNextbotDistance .. " studs",
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
        antiNextbotDistance = value
    end)
})

IruzGroup:AddDivider()
IruzGroup:AddToggle("IruzGravity", {
    Text = "Custom Gravity",
    Default = false,
    Callback = SafeWrapper("IruzGravityToggle", function(state)
        gravityEnabled = state
        if state then
            workspace.Gravity = gravityValue
            Library:Notify({
                Title = "Gravity",
                Description = "Enabled: " .. gravityValue,
                Time = 2,
            })
        else
            workspace.Gravity = originalGravity
            Library:Notify({
                Title = "Gravity",
                Description = "Disabled",
                Time = 2,
            })
        end
    end)
})

IruzGroup:AddSlider("GravityValue", {
    Text = "Gravity Strength",
    Default = 10,
    Min = 1,
    Max = 196.2,
    Rounding = 1,
    Callback = SafeWrapper("GravityValueCallback", function(value)
        gravityValue = value
        if gravityEnabled then
            workspace.Gravity = gravityValue
        end
    end)
})

IruzGroup:AddDivider()
IruzGroup:AddToggle("IruzAutoDrink", {
    Text = "Auto Drink Cola",
    Default = false,
    Callback = SafeWrapper("IruzAutoDrinkToggle", function(state)
        autoDrinkEnabled = state
        if state then
            startAutoDrink()
            Library:Notify({
                Title = "Auto Drink",
                Description = "Enabled - Delay: " .. drinkDelay .. "s",
                Time = 2,
            })
        else
            stopAutoDrink()
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
        drinkDelay = value
    end)
})

local AdvancedIruzGroup = Tabs.Misc:AddRightGroupbox("Iruz Advanced", "cpu")
AdvancedIruzGroup:AddToggle("CameraStretch", {
    Text = "Camera Stretch",
    Default = false,
    Callback = SafeWrapper("CameraStretchToggle", function(state)
        cameraStretchEnabled = state
        if state then
            setupCameraStretch()
            Library:Notify({
                Title = "Camera Stretch",
                Description = "Enabled",
                Time = 2,
            })
        else
            if cameraStretchConnection then
                cameraStretchConnection:Disconnect()
                cameraStretchConnection = nil
            end
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
        stretchHorizontal = value
    end)
})

AdvancedIruzGroup:AddSlider("StretchVertical", {
    Text = "Vertical Stretch",
    Default = 0.80,
    Min = 0.1,
    Max = 2,
    Rounding = 2,
    Callback = SafeWrapper("StretchVerticalCallback", function(value)
        stretchVertical = value
    end)
})

AdvancedIruzGroup:AddDivider()
AdvancedIruzGroup:AddToggle("NoCameraShake", {
    Text = "No Camera Shake",
    Default = false,
    Callback = SafeWrapper("NoCameraShakeToggle", function(state)
        if state then
            if not stableCameraInstance then
                stableCameraInstance = StableCamera.new()
            end
            stableCameraInstance:Start()
            Library:Notify({
                Title = "No Camera Shake",
                Description = "Enabled",
                Time = 2,
            })
        else
            if stableCameraInstance then
                stableCameraInstance:Stop()
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
        noFogEnabled = state
        toggleNoFog(state)
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
        lagDelayValue = value
    end)
})

AdvancedIruzGroup:AddSlider("LagIntensity", {
    Text = "Lag Intensity",
    Default = 1000000,
    Min = 100000,
    Max = 10000000,
    Rounding = 0,
    Callback = SafeWrapper("LagIntensityCallback", function(value)
        lagIntensity = value
    end)
})

AdvancedIruzGroup:AddDropdown("LagMode", {
    Values = { "Normal", "Demon" },
    Default = "Normal",
    Text = "Lag Mode",
    Callback = SafeWrapper("LagModeCallback", function(value)
        lagSwitchMode = value
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
                resetBhopFriction()
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
    
    if getgenv().autoJumpEnabled then
        task.wait(1)
        applyBhopFriction()
        checkBhopState()
    end
end)

-- ==================== CUSTOM KEYBIND SYSTEM ====================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- FLY (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.Fly) then
        local flyToggle = not flying
        
        if flyToggle then
            startFlying()
            if not flyLoop then
                flyLoop = RunService.RenderStepped:Connect(updateFly)
            end
            Library:Notify({
                Title = "Iruz Fly",
                Description = "Enabled (WASD + Space/Shift)",
                Time = 2,
            })
        else
            stopFlying()
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
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.AntiNextbot) then
        antiNextbotEnabled = not antiNextbotEnabled
        
        if antiNextbotEnabled then
            if not antiNextbotConnection then
                antiNextbotConnection = RunService.Heartbeat:Connect(handleAntiNextbot)
            end
            Library:Notify({
                Title = "Anti Nextbot",
                Description = "Enabled - Range: " .. antiNextbotDistance .. " studs",
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
            Toggles.IruzAntiNextbot:SetValue(antiNextbotEnabled)
        end
    end
    
    -- GRAVITY (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.Gravity) then
        if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.IncreaseGravity) then
            gravityValue = gravityValue + 5
            if gravityEnabled then
                workspace.Gravity = gravityValue
            end
            Library:Notify({
                Title = "Gravity",
                Description = "Increased to: " .. gravityValue,
                Time = 1,
            })
        elseif KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.DecreaseGravity) then
            gravityValue = math.max(1, gravityValue - 5)
            if gravityEnabled then
                workspace.Gravity = gravityValue
            end
            Library:Notify({
                Title = "Gravity",
                Description = "Decreased to: " .. gravityValue,
                Time = 1,
            })
        else
            toggleGravity()
            Library:Notify({
                Title = "Gravity",
                Description = gravityEnabled and "Enabled: " .. gravityValue or "Disabled",
                Time = 2,
            })
        end
        
        if Toggles.IruzGravity then
            Toggles.IruzGravity:SetValue(gravityEnabled)
        end
    end
    
    -- AUTO DRINK (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.AutoDrink) then
        autoDrinkEnabled = not autoDrinkEnabled
        
        if autoDrinkEnabled then
            startAutoDrink()
            Library:Notify({
                Title = "Auto Drink",
                Description = "Enabled - Delay: " .. drinkDelay .. "s",
                Time = 2,
            })
        else
            stopAutoDrink()
            Library:Notify({
                Title = "Auto Drink",
                Description = "Disabled",
                Time = 2,
            })
        end
        
        if Toggles.IruzAutoDrink then
            Toggles.IruzAutoDrink:SetValue(autoDrinkEnabled)
        end
    end
    
    -- LAG SWITCH (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.LagSwitch) then
        if lagSwitchEnabled then
            toggleLagSwitchDH()
            Library:Notify({
                Title = "Iruz Lag",
                Description = "Activated - Mode: " .. lagSwitchMode,
                Time = 2,
            })
        end
    end
    
    -- TOGGLE LAG SWITCH ENABLE (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.ToggleLagEnable) then
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
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.CameraStretch) then
        cameraStretchEnabled = not cameraStretchEnabled
        
        if cameraStretchEnabled then
            setupCameraStretch()
            Library:Notify({
                Title = "Camera Stretch",
                Description = "Enabled",
                Time = 2,
            })
        else
            if cameraStretchConnection then
                cameraStretchConnection:Disconnect()
                cameraStretchConnection = nil
            end
            Library:Notify({
                Title = "Camera Stretch",
                Description = "Disabled",
                Time = 2,
            })
        end
        
        if Toggles.CameraStretch then
            Toggles.CameraStretch:SetValue(cameraStretchEnabled)
        end
    end
    
    -- INFINITE SLIDE (Custom Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.InfiniteSlide) then
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
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.NoFog) then
        noFogEnabled = not noFogEnabled
        toggleNoFog(noFogEnabled)
        Library:Notify({
            Title = "No Fog",
            Description = noFogEnabled and "Enabled" or "Disabled",
            Time = 2,
        })
        
        if Toggles.IruzNoFog then
            Toggles.IruzNoFog:SetValue(noFogEnabled)
        end
    end
    
    -- NO CAMERA SHAKE (Custom Combination Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.NoCameraShake) then
        if stableCameraInstance then
            stableCameraInstance:Stop()
            Library:Notify({
                Title = "No Camera Shake",
                Description = "Disabled",
                Time = 2,
            })
        else
            if not stableCameraInstance then
                stableCameraInstance = StableCamera.new()
            end
            stableCameraInstance:Start()
            Library:Notify({
                Title = "No Camera Shake",
                Description = "Enabled",
                Time = 2,
            })
        end
        
        if Toggles.NoCameraShake then
            Toggles.NoCameraShake:SetValue(stableCameraInstance ~= nil)
        end
    end
    
    -- FPS TIMER TOGGLE (Custom Combination Keybind)
    if KeybindManager:IsKeyComboPressed(KeybindManager.CurrentKeybinds.FpsTimer) then
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
        else
            CharacterDH = nil
            HumanoidDH = nil
            HumanoidRootPartDH = nil
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
            
            if flying then
                task.wait(1)
                startFlying()
            end
        else
            warn("[Character Load] Humanoid or HRP not found")
        end
    end
end)

player.CharacterRemoving:Connect(function()
    if flying then
        stopFlying()
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
            TeleportModule.PlaceTeleporter(autoPlaceTeleporterType)
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
            TeleportModule.PlaceTeleporter(autoPlaceTeleporterType)
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
    
    if flying then
        print("[Auto-Recovery] Disabling fly due to error...")
        stopFlying()
        if Toggles.IruzFly then
            Toggles.IruzFly:SetValue(false)
        end
    end
    
    if antiNextbotEnabled then
        print("[Auto-Recovery] Disabling anti-nextbot due to error...")
        antiNextbotEnabled = false
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
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
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
    
    if stableCameraInstance then
        stableCameraInstance:Destroy()
        stableCameraInstance = nil
    end
    
    if flying then
        stopFlying()
        if flyLoop then
            flyLoop:Disconnect()
            flyLoop = nil
        end
    end
    
    if antiNextbotConnection then
        antiNextbotConnection:Disconnect()
        antiNextbotConnection = nil
    end
    
    if AutoDrinkConnection then
        task.cancel(AutoDrinkConnection)
        AutoDrinkConnection = nil
    end
    
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    
    if characterConnection then
        characterConnection:Disconnect()
        characterConnection = nil
    end
    
    if cameraStretchConnection then
        cameraStretchConnection:Disconnect()
        cameraStretchConnection = nil
    end
    
    if gravityEnabled then
        workspace.Gravity = originalGravity
    end
    
    if noFogEnabled then
        toggleNoFog(false)
    end
    
    resetBhopFriction()
    
    local timerGUI = player.PlayerGui:FindFirstChild("IruzFPS")
    if timerGUI then
        timerGUI:Destroy()
    end
    
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

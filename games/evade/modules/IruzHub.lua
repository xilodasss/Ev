-- IruzHub.lua
local IruzHub = {}

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Local variables
local player = Players.LocalPlayer
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

-- Import SafeWrapper dari Utils jika ada, jika tidak buat sendiri
local function SafeWrapper(name, func)
    return function(...)
        local args = {...}
        local success, result = xpcall(function()
            return func(unpack(args))
        end, function(err)
            warn("[" .. name .. " Error]:", err)
            return nil
        end)
        return success and result or nil
    end
end

-- Helper functions
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

-- ==================== STABLE CAMERA MODULE ====================
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

-- ==================== FLY SYSTEM ====================
local function startFlying()
    local character = safeGetCharacter(player)
    if not character then 
        return false, "Character not found"
    end
    
    local humanoid = safeGetHumanoid(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then 
        return false, "Character parts not found"
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
    return true
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
        return false, err
    end
    return true
end

-- ==================== ANTI NEXTBOT ====================
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

-- ==================== GRAVITY CONTROL ====================
local function toggleGravity()
    gravityEnabled = not gravityEnabled
    if gravityEnabled then
        workspace.Gravity = gravityValue
    else
        workspace.Gravity = originalGravity
    end
    return gravityEnabled
end

-- ==================== AUTO DRINK ====================
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

-- ==================== BUNNY HOP (HOLD SPACE JUMP) ====================
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

local function updateBhop(autoJumpEnabled, jumpInterval, autoJumpType)
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

    local isBhopActive = autoJumpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space)
    local now = tick()
    
    if isBhopActive then
        if IsOnGround() and (now - LastJump) > jumpInterval then
            if autoJumpType == "Realistic" then
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

local function loadBhop(autoJumpEnabled, bhopMode, bhopAccelValue, jumpInterval, autoJumpType, Library)
    if bhopLoaded then return end
    
    bhopLoaded = true
    
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    
    bhopConnection = RunService.Heartbeat:Connect(function()
        updateBhop(autoJumpEnabled, jumpInterval, autoJumpType)
        
        if autoJumpEnabled and bhopMode == "Acceleration" then
            findFrictionTables()
            if #frictionTables > 0 then
                setFriction(bhopAccelValue or -0.1)
            end
        else
            resetBhopFriction()
        end
    end)
    
    if Library then
        Library:Notify({
            Title = "Hold Space Jump",
            Description = "Hold Space Jump loaded!",
            Time = 2,
        })
    end
end

local function unloadBhop(Library)
    if not bhopLoaded then return end
    
    bhopLoaded = false
    
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    
    resetBhopFriction()
    
    if Library then
        Library:Notify({
            Title = "Hold Space Jump",
            Description = "Hold Space Jump unloaded!",
            Time = 2,
        })
    end
end

-- ==================== LAG SWITCH ====================
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

-- ==================== CAMERA STRETCH ====================
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

-- ==================== NO FOG ====================
local function toggleNoFog(state)
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
    noFogEnabled = state
end

-- ==================== PUBLIC API ====================
IruzHub = {
    -- Fly system
    StartFlying = SafeWrapper("IruzHub.StartFlying", startFlying),
    StopFlying = SafeWrapper("IruzHub.StopFlying", stopFlying),
    UpdateFly = SafeWrapper("IruzHub.UpdateFly", updateFly),
    IsFlying = function() return flying end,
    
    -- Anti Nextbot
    SetAntiNextbotEnabled = function(state) antiNextbotEnabled = state end,
    GetAntiNextbotEnabled = function() return antiNextbotEnabled end,
    SetAntiNextbotDistance = function(distance) antiNextbotDistance = distance end,
    GetAntiNextbotDistance = function() return antiNextbotDistance end,
    HandleAntiNextbot = SafeWrapper("IruzHub.HandleAntiNextbot", handleAntiNextbot),
    
    -- Gravity
    ToggleGravity = SafeWrapper("IruzHub.ToggleGravity", toggleGravity),
    SetGravityValue = function(value) 
        gravityValue = value
        if gravityEnabled then
            workspace.Gravity = gravityValue
        end
    end,
    GetGravityValue = function() return gravityValue end,
    IsGravityEnabled = function() return gravityEnabled end,
    
    -- Auto Drink
    SetAutoDrinkEnabled = function(state) autoDrinkEnabled = state end,
    GetAutoDrinkEnabled = function() return autoDrinkEnabled end,
    SetDrinkDelay = function(delay) drinkDelay = delay end,
    GetDrinkDelay = function() return drinkDelay end,
    StartAutoDrink = SafeWrapper("IruzHub.StartAutoDrink", startAutoDrink),
    StopAutoDrink = SafeWrapper("IruzHub.StopAutoDrink", stopAutoDrink),
    
    -- Bunny Hop
    LoadBhop = SafeWrapper("IruzHub.LoadBhop", function(autoJumpEnabled, bhopMode, bhopAccelValue, jumpInterval, autoJumpType, Library)
        loadBhop(autoJumpEnabled, bhopMode, bhopAccelValue, jumpInterval, autoJumpType, Library)
    end),
    UnloadBhop = SafeWrapper("IruzHub.UnloadBhop", function(Library)
        unloadBhop(Library)
    end),
    IsBhopLoaded = function() return bhopLoaded end,
    SetCharacterReferences = function(char, humanoid, hrp)
        CharacterDH = char
        HumanoidDH = humanoid
        HumanoidRootPartDH = hrp
    end,
    
    -- Lag Switch
    ToggleLagSwitch = SafeWrapper("IruzHub.ToggleLagSwitch", toggleLagSwitchDH),
    SetLagDelay = function(delay) lagDelayValue = delay end,
    GetLagDelay = function() return lagDelayValue end,
    SetLagIntensity = function(intensity) lagIntensity = intensity end,
    GetLagIntensity = function() return lagIntensity end,
    SetLagMode = function(mode) lagSwitchMode = mode end,
    GetLagMode = function() return lagSwitchMode end,
    IsLagActive = function() return isLagActive end,
    
    -- Camera Stretch
    SetCameraStretchEnabled = function(state) cameraStretchEnabled = state end,
    GetCameraStretchEnabled = function() return cameraStretchEnabled end,
    SetStretchHorizontal = function(value) stretchHorizontal = value end,
    GetStretchHorizontal = function() return stretchHorizontal end,
    SetStretchVertical = function(value) stretchVertical = value end,
    GetStretchVertical = function() return stretchVertical end,
    SetupCameraStretch = SafeWrapper("IruzHub.SetupCameraStretch", setupCameraStretch),
    
    -- No Fog
    SetNoFogEnabled = function(state) toggleNoFog(state) end,
    GetNoFogEnabled = function() return noFogEnabled end,
    
    -- Stable Camera
    CreateStableCamera = function(maxDistance)
        stableCameraInstance = StableCamera.new(maxDistance)
        return stableCameraInstance
    end,
    GetStableCamera = function() return stableCameraInstance end,
    
    -- Cleanup
    Cleanup = SafeWrapper("IruzHub.Cleanup", function()
        -- Stop flying
        if flying then
            stopFlying()
            if flyLoop then
                flyLoop:Disconnect()
                flyLoop = nil
            end
        end
        
        -- Stop anti nextbot
        if antiNextbotConnection then
            antiNextbotConnection:Disconnect()
            antiNextbotConnection = nil
        end
        
        -- Stop auto drink
        if AutoDrinkConnection then
            task.cancel(AutoDrinkConnection)
            AutoDrinkConnection = nil
        end
        
        -- Stop bhop
        if bhopConnection then
            bhopConnection:Disconnect()
            bhopConnection = nil
        end
        
        -- Stop camera stretch
        if cameraStretchConnection then
            cameraStretchConnection:Disconnect()
            cameraStretchConnection = nil
        end
        
        -- Reset gravity
        if gravityEnabled then
            workspace.Gravity = originalGravity
        end
        
        -- Reset fog
        if noFogEnabled then
            toggleNoFog(false)
        end
        
        -- Reset friction
        resetBhopFriction()
        
        -- Destroy stable camera
        if stableCameraInstance then
            stableCameraInstance:Destroy()
            stableCameraInstance = nil
        end
    end)
}

return IruzHub

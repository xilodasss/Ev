-- GunFunctions.lua
local GunFunctionsModule = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Safe wrapper function
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

-- Local variables
local enhancedWeapons = {}

-- Enhance GrappleHook
local function enhanceGrappleHook()
    local success, result = pcall(function()
        local GrappleHook = require(ReplicatedStorage.Tools["GrappleHook"])
        local grappleTask = GrappleHook.Tasks[2]
        local shootMethod = grappleTask.Functions[1].Activations[1].Methods[1]

        -- SETTING KAMU:
        shootMethod.Info.Speed = 8000
        shootMethod.Info.Lifetime = 6.0
        shootMethod.Info.Gravity = Vector3.new(0, -5, 0)
        shootMethod.Info.SpreadIncrease = 0.05
        shootMethod.Info.Cooldown = 0.8

        -- Akurasi bagus:
        grappleTask.MethodReferences.Projectile.Info.SpreadInfo.MaxSpread = 0.2
        grappleTask.MethodReferences.Projectile.Info.SpreadInfo.MinSpread = 0.05
        grappleTask.MethodReferences.Projectile.Info.SpreadInfo.ReductionRate = 60

        -- Check method:
        local checkMethod = grappleTask.AutomaticFunctions[1].Methods[1]
        checkMethod.Info.Cooldown = 0.8
        checkMethod.CooldownInfo.TestCooldown = 0.5

        -- Isi 300 ammo:
        grappleTask.ResourceInfo.Cap = 300
        grappleTask.ResourceInfo.Reserve = 300

        enhancedWeapons["GrappleHook"] = true
        return true
    end)
    
    return success, result
end

-- Enhance Breacher (Portal Gun)
local function enhanceBreacher()
    local success, result = pcall(function()
        local Breacher = require(ReplicatedStorage.Tools.Breacher)
        
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
        
        blueShoot.Info.Range = 999999
        yellowShoot.Info.Range = 999999
        
        -- 3. Akurasi perfect:
        blueShoot.Info.SpreadIncrease = 0
        yellowShoot.Info.SpreadIncrease = 0
        
        portalTask.MethodReferences.Portal.Info.SpreadInfo.MaxSpread = 0
        portalTask.MethodReferences.Portal.Info.SpreadInfo.MinSpread = 0
        portalTask.MethodReferences.Portal.Info.SpreadInfo.ReductionRate = 100

        -- 4. DELAY 0.4 DETIK:
        blueShoot.Info.Cooldown = 0.4
        yellowShoot.Info.Cooldown = 0.4

        -- 5. Test cooldown super cepat:
        if blueShoot.CooldownInfo then
            blueShoot.CooldownInfo.TestCooldown = 0.15
        end
        if yellowShoot.CooldownInfo then
            yellowShoot.CooldownInfo.TestCooldown = 0.15
        end

        -- 6. Kecepatan proyektil super cepat:
        if not blueShoot.Info.Speed then
            blueShoot.Info.Speed = 500
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

-- Enhance Smoke Grenade
local function enhanceSmokeGrenade()
    local success, result = pcall(function()
        local SmokeGrenade = require(ReplicatedStorage.Tools["SmokeGrenade"])

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
        
        ReplicatedStorage.Events.Character.ToolAction:FireServer(unpack(args))
        
        enhancedWeapons["SmokeGrenade"] = true
        return true
    end)
    
    return success, result
end

-- Enhance Boombox
local function enhanceBoombox()
    local success, result = pcall(function()
        local Boombox = require(ReplicatedStorage.Tools.Boombox)

        -- Find the main task
        local mainTask = Boombox.Tasks[1]
        
        -- Make it louder and longer
        if mainTask and mainTask.Functions and mainTask.Functions[1] then
            local playMethod = mainTask.Functions[1].Activations[1].Methods[1]
            if playMethod and playMethod.Info then
                playMethod.Info.Volume = 10
                playMethod.Info.Duration = 999
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

-- Public functions
function GunFunctionsModule.EnhanceGrappleHook(Library)
    local success, result = enhanceGrappleHook()
    if success and Library then
        Library:Notify({
            Title = "GrappleHook",
            Description = "GrappleHook successfully upgraded!",
            Duration = 5
        })
    elseif not success and Library then
        Library:Notify({
            Title = "GrappleHook Error",
            Description = "Error: " .. tostring(result),
            Duration = 5
        })
    end
    return success
end

function GunFunctionsModule.EnhanceBreacher(Library)
    local success, result = enhanceBreacher()
    if success and Library then
        Library:Notify({
            Title = "Breacher (Portal Gun)",
            Description = "Portal Gun Successfully upgraded! \n✓ Infinite charges \n✓ Maximum range \n✓ Instant reload",
            Duration = 6
        })
    elseif not success and Library then
        Library:Notify({
            Title = "Breacher Error",
            Description = "Error: " .. tostring(result),
            Duration = 5
        })
    end
    return success
end

function GunFunctionsModule.EnhanceSmokeGrenade(Library)
    local success, result = enhanceSmokeGrenade()
    if success and Library then
        Library:Notify({
            Title = "Smoke Grenade",
            Description = "Smoke Grenade Improved! \n✓ Infinite Grenades \n✓ Instant Reload",
            Duration = 6
        })
    elseif not success and Library then
        Library:Notify({
            Title = "Smoke Grenade Error",
            Description = "Error: " .. tostring(result),
            Duration = 5
        })
    end
    return success
end

function GunFunctionsModule.EnhanceBoombox(Library)
    local success, result = enhanceBoombox()
    if success and Library then
        Library:Notify({
            Title = "Boombox",
            Description = "Boombox Enhanced! \n✓ Max Volume \n✓ Long Duration",
            Duration = 5
        })
    elseif not success and Library then
        Library:Notify({
            Title = "Boombox Error",
            Description = "Error: " .. tostring(result),
            Duration = 5
        })
    end
    return success
end

function GunFunctionsModule.EnhanceAll(Library)
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
    
    if Library then
        Library:Notify({
            Title = "All Weapons Enhanced",
            Description = string.format("Successfully enhanced %d/%d weapons!", count, #results),
            Duration = 6
        })
    end
    return count
end

function GunFunctionsModule.IsEnhanced(weaponName)
    return enhancedWeapons[weaponName] == true
end

function GunFunctionsModule.ResetAll(Library)
    enhancedWeapons = {}
    
    if Library then
        Library:Notify({
            Title = "Weapons Reset",
            Description = "All weapon enhancements reset",
            Duration = 4
        })
    end
end

-- Wrap semua functions
GunFunctionsModule.EnhanceGrappleHook = SafeWrapper("GunFunctions.EnhanceGrappleHook", GunFunctionsModule.EnhanceGrappleHook)
GunFunctionsModule.EnhanceBreacher = SafeWrapper("GunFunctions.EnhanceBreacher", GunFunctionsModule.EnhanceBreacher)
GunFunctionsModule.EnhanceSmokeGrenade = SafeWrapper("GunFunctions.EnhanceSmokeGrenade", GunFunctionsModule.EnhanceSmokeGrenade)
GunFunctionsModule.EnhanceBoombox = SafeWrapper("GunFunctions.EnhanceBoombox", GunFunctionsModule.EnhanceBoombox)
GunFunctionsModule.EnhanceAll = SafeWrapper("GunFunctions.EnhanceAll", GunFunctionsModule.EnhanceAll)
GunFunctionsModule.ResetAll = SafeWrapper("GunFunctions.ResetAll", GunFunctionsModule.ResetAll)

return GunFunctionsModule

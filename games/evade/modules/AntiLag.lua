-- AntiLag.lua
local AntiLagModule = {}

-- Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local workspace = game:GetService("Workspace")

-- Local variables
local originalLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime
}

-- Safe wrapper function (imported from Utils)
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

-- Helper function untuk mendapatkan character
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

-- Function utama
function AntiLagModule.ApplyFPSBoost(Library)
    if Library then
        Library:Notify({
            Title = "FPS Boost",
            Description = "Applying aggressive optimizations...",
            Time = 2,
        })
    end
    
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

    if Library then
        Library:Notify({
            Title = "FPS Boost",
            Description = "Optimizations applied successfully!",
            Time = 2,
        })
    end
end

function AntiLagModule.ApplyAntiLag1(Library)
    if Library then
        Library:Notify({
            Title = "Anti Lag 1",
            Description = "Applying material optimizations...",
            Time = 2,
        })
    end

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

    if Library then
        Library:Notify({
            Title = "Anti Lag 1",
            Description = "Material optimizations complete!",
            Time = 2,
        })
    end
end

function AntiLagModule.ApplyAntiLag2(Library)
    if Library then
        Library:Notify({
            Title = "Anti Lag 2",
            Description = "Disabling visual effects...",
            Time = 2,
        })
    end

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

    if Library then
        Library:Notify({
            Title = "Anti Lag 2",
            Description = "Visual effects disabled!",
            Time = 2,
        })
    end
end

function AntiLagModule.ApplyRemoveTexture(Library)
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
    
    if Library then
        Library:Notify({
            Title = "Remove Texture",
            Description = "All textures removed!",
            Time = 2,
        })
    end
end

-- Wrap semua functions dengan SafeWrapper
AntiLagModule.ApplyFPSBoost = SafeWrapper("AntiLag.ApplyFPSBoost", AntiLagModule.ApplyFPSBoost)
AntiLagModule.ApplyAntiLag1 = SafeWrapper("AntiLag.ApplyAntiLag1", AntiLagModule.ApplyAntiLag1)
AntiLagModule.ApplyAntiLag2 = SafeWrapper("AntiLag.ApplyAntiLag2", AntiLagModule.ApplyAntiLag2)
AntiLagModule.ApplyRemoveTexture = SafeWrapper("AntiLag.ApplyRemoveTexture", AntiLagModule.ApplyRemoveTexture)

return AntiLagModule

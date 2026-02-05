-- Utils.lua
local Utils = {}

-- Services
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

-- Local variables
local player = Players.LocalPlayer

-- ==================== SAFE WRAPPER ====================
function Utils.SafeWrapper(name, func)
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

-- ==================== DEBUG LOG ====================
function Utils.DebugLog(message, ...)
    local DEBUG_MODE = false
    if DEBUG_MODE then
        print("[Iruz Debug]:", message, ...)
    end
end

-- ==================== CHARACTER HANDLING ====================
function Utils.safeGetHumanoid(model)
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

function Utils.safeGetCharacter(playerObj)
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

function Utils.isPlayerDowned(plr)
    local char = Utils.safeGetCharacter(plr)
    if not char then return false end
    
    local downed = char:GetAttribute("Downed")
    if downed == true then return true end
    
    local humanoid = Utils.safeGetHumanoid(char)
    if humanoid then
        return humanoid.Health <= 0
    end
    
    return false
end

-- ==================== STRING UTILITIES ====================
function Utils.safeString(value, default)
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

function Utils.safeConcat(...)
    local result = ""
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        result = result .. Utils.safeString(arg, "")
    end
    return result
end

-- ==================== TABLE UTILITIES ====================
function Utils.safeAssign(t, k, v)
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

-- ==================== RAYCAST UTILITIES ====================
function Utils.isOnGround(character, hrp, groundCheckDistance, maxSlopeAngle)
    if not character or not hrp then return false end
    
    local humanoid = Utils.safeGetHumanoid(character)
    if humanoid then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or 
           state == Enum.HumanoidStateType.Freefall or
           state == Enum.HumanoidStateType.Swimming then
            return false
        end
    end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.IgnoreWater = true
    
    local rayOrigin = hrp.Position
    local rayDirection = Vector3.new(0, -groundCheckDistance, 0)
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if not raycastResult then return false end
    
    local surfaceNormal = raycastResult.Normal
    local angle = math.deg(math.acos(surfaceNormal:Dot(Vector3.new(0, 1, 0))))
    
    return angle <= maxSlopeAngle
end

-- ==================== DISTANCE CALCULATION ====================
function Utils.getDistance(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    return (pos1 - pos2).Magnitude
end

function Utils.getDistanceFromPlayer(targetPos)
    local char = Utils.safeGetCharacter(player)
    if not char then return math.huge end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return math.huge end
    
    return Utils.getDistance(hrp.Position, targetPos)
end

-- ==================== COLOR UTILITIES ====================
function Utils.getColorByDistance(distance)
    if distance <= 12 then
        return Color3.fromRGB(50, 50, 50)
    elseif distance <= 60 then
        local t = (distance - 12) / 48
        return Color3.fromRGB(255, 120 + (255 - 120) * t, 120)
    else
        return Color3.fromRGB(200, 150, 255)
    end
end

function Utils.LerpColor(color1, color2, t)
    return Color3.new(
        color1.R + (color2.R - color1.R) * t,
        color1.G + (color2.G - color1.G) * t,
        color1.B + (color2.B - color1.B) * t
    )
end

-- ==================== VALIDATION UTILITIES ====================
function Utils.validateCharacter()
    local char = Utils.safeGetCharacter(player)
    if not char then
        return nil, nil, "Character not found"
    end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil, nil, "HumanoidRootPart not found"
    end
    
    return char, hrp, nil
end

-- ==================== NOTIFICATION WRAPPER ====================
function Utils.Notify(Library, title, description, duration)
    if Library and Library.Notify then
        Library:Notify({
            Title = title,
            Description = description,
            Time = duration or 3
        })
    else
        warn("[Notification]:", title, "-", description)
    end
end

return Utils

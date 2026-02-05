-- KeybindManager.lua
local KeybindManager = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Default keybinds
KeybindManager.DefaultKeybinds = {
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
}

-- Current keybinds
KeybindManager.CurrentKeybinds = {}

-- Initialize keybind system
function KeybindManager:Init()
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
end

-- Save keybinds to file
function KeybindManager:Save()
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
end

-- Check if key combination is pressed
function KeybindManager:IsKeyComboPressed(keyCombo)
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
end

-- Get key name(s)
function KeybindManager:GetKeyName(keyCombo)
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

-- Set a keybind
function KeybindManager:SetKeybind(keyName, keyCode)
    if keyName and keyCode then
        self.CurrentKeybinds[keyName] = keyCode
        self:Save()
        return true
    end
    return false
end

-- Get a keybind
function KeybindManager:GetKeybind(keyName)
    return self.CurrentKeybinds[keyName]
end

-- Reset all keybinds to default
function KeybindManager:ResetToDefault()
    self.CurrentKeybinds = {}
    for key, value in pairs(self.DefaultKeybinds) do
        self.CurrentKeybinds[key] = value
    end
    self:Save()
    return true
end

-- Initialize on load
KeybindManager:Init()

return KeybindManager

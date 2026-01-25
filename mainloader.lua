local GITHUB_BASE = "https://raw.githubusercontent.com/xilodasss/Ev/main"

local SUPPORTED_GAMES = {
    ["Evade"] = {
        script = "/games/evade/main.lua",
        placeIds = {
            10324346056,     -- Big Team
            9872472334,      -- Evade
            10662542523,     -- Casual
            10324347967,     -- Social Space
            121271605799901, -- Player Nextbots
            10808838353,     -- VC Only
            11353528705,     -- Pro
            99214917572799,  -- Custom Servers
        }
    }
}

local UNIVERSAL_SCRIPT = "/universal/main.lua"


local function createLoadingUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XilodasXLoaderUI"
    ScreenGui.DisplayOrder = 999
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 320, 0, 140)
    Frame.Position = UDim2.new(0.5, -160, 0.5, -70)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Frame.BorderSizePixel = 0

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "Xilodass Loader"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -20, 0, 20)
    Status.Position = UDim2.new(0, 10, 0, 50)
    Status.BackgroundTransparency = 1
    Status.Text = "Initializing..."
    Status.TextColor3 = Color3.fromRGB(200, 200, 200)
    Status.TextSize = 14
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Frame

    local GameName = Instance.new("TextLabel")
    GameName.Size = UDim2.new(1, -20, 0, 16)
    GameName.Position = UDim2.new(0, 10, 0, 75)
    GameName.BackgroundTransparency = 1
    GameName.Text = "Detecting game..."
    GameName.TextColor3 = Color3.fromRGB(150, 150, 150)
    GameName.TextSize = 12
    GameName.Font = Enum.Font.Gotham
    GameName.TextXAlignment = Enum.TextXAlignment.Left
    GameName.Parent = Frame

    local ProgressBG = Instance.new("Frame")
    ProgressBG.Size = UDim2.new(1, -20, 0, 4)
    ProgressBG.Position = UDim2.new(0, 10, 0, 110)
    ProgressBG.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ProgressBG.BorderSizePixel = 0

    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, 2)
    ProgressCorner.Parent = ProgressBG

    local Progress = Instance.new("Frame")
    Progress.Size = UDim2.new(0, 0, 1, 0)
    Progress.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    Progress.BorderSizePixel = 0

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 2)
    FillCorner.Parent = Progress

    Progress.Parent = ProgressBG
    ProgressBG.Parent = Frame
    Frame.Parent = ScreenGui

    local function updateStatus(text)
        Status.Text = text
    end

    local function updateGame(text)
        GameName.Text = text
    end

    local function updateProgress(percent)
        Progress:TweenSize(
            UDim2.new(percent, 0, 1, 0),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
    end

    local function close()
        ScreenGui:Destroy()
    end

    return {
        updateStatus = updateStatus,
        updateGame = updateGame,
        updateProgress = updateProgress,
        close = close
    }
end

local function fetchScript(url)
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    
    if not success then
        -- Coba dengan cache buster
        local cacheBuster = string.format("?v=%d", tick())
        success, result = pcall(function()
            return game:HttpGet(url .. cacheBuster, true)
        end)
    end
    
    return success and result or nil
end


local function main()
    -- Buat UI dulu
    local ui = createLoadingUI()
    ui.updateStatus("Starting loader...")
    ui.updateProgress(0.1)
    task.wait(0.5)

    -- Deteksi game
    ui.updateStatus("Detecting game...")
    ui.updateProgress(0.2)
    
    local currentPlaceId = game.PlaceId
    local selectedGame = nil
    local scriptPath = nil

    for gameName, gameData in pairs(SUPPORTED_GAMES) do
        for _, placeId in ipairs(gameData.placeIds) do
            if currentPlaceId == placeId then
                selectedGame = gameName
                scriptPath = gameData.script
                ui.updateGame("Game: " .. gameName)
                break
            end
        end
        if selectedGame then break end
    end

    if not selectedGame then
        selectedGame = "Universal"
        scriptPath = UNIVERSAL_SCRIPT
        ui.updateGame("Game: Universal Script")
    end

    -- Download script
    ui.updateStatus("Downloading script...")
    ui.updateProgress(0.4)
    
    local scriptUrl = GITHUB_BASE .. scriptPath
    print("[DEBUG] Downloading from:", scriptUrl)
    
    local scriptContent = fetchScript(scriptUrl)

    if not scriptContent then
        ui.updateStatus("❌ Download failed!")
        ui.updateGame("Check internet connection")
        ui.updateProgress(0)
        task.wait(3)
        ui.close()
        
        -- Tampilkan notifikasi error
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Xilodass Loader",
            Text = "Failed to download script!",
            Duration = 5
        })
        return
    end

    -- Execute script
    ui.updateStatus("Loading " .. selectedGame .. "...")
    ui.updateProgress(0.7)
    
    print("[DEBUG] Script length:", #scriptContent)
    
    local success, err = pcall(function()
        loadstring(scriptContent)()
    end)

    if success then
        ui.updateStatus("✅ " .. selectedGame .. " loaded!")
        ui.updateProgress(1)
        task.wait(1.5)
        ui.close()

        -- Success notification
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Xilodass Loader",
            Text = selectedGame .. " loaded successfully!",
            Duration = 3
        })
        
        print("[SUCCESS] Loader completed!")
    else
        ui.updateStatus("❌ Execution error!")
        ui.updateGame("Error: " .. tostring(err):sub(1, 40))
        ui.updateProgress(0)
        
        print("[ERROR]", err)
        
        task.wait(5)
        ui.close()
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Xilodass Loader",
            Text = "Script execution failed!",
            Duration = 5
        })
    end
end

-- Error handling untuk seluruh loader
local success, err = pcall(main)
if not success then
    warn("[LOADER CRASHED]:", err)
    
    -- Tampilkan error sederhana
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Loader Crashed",
        Text = "Check console for details",
        Duration = 5
    })
end

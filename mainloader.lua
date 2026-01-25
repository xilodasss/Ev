local GITHUB_BASE = "https://raw.githubusercontent.com/xilodasss/Ev/main"

local SUPPORTED_GAMES = {
    ["Evade"] = {
        script = "/games/evade/main.lua",
        placeIds = {
            10324346056, 9872472334, 10662542523, 10324347967,
            121271605799901, 10808838353, 11353528705, 99214917572799
        }
    }
}

local UNIVERSAL_SCRIPT = "/universal/main.lua"

-- Obsidian UI Loader
local function createObsidianUI()
    -- Load Obsidian UI Library
    local Obsidian = loadstring(game:HttpGet("https://raw.githubusercontent.com/strawbberrys/Obsidian/main/Source.lua"))()
    local Window = Obsidian:CreateWindow({
        Name = "Xilodass Loader",
        Theme = "Dark",
        Size = UDim2.new(0, 450, 0, 350),
        Position = UDim2.new(0.5, -225, 0.5, -175)
    })

    -- Main Tab
    local MainTab = Window:CreateTab("Loader")
    
    -- Header Section
    local HeaderSection = MainTab:CreateSection("Status")
    
    -- Game Info Display
    local GameLabel = MainTab:CreateLabel("Detecting game...")
    GameLabel.TextSize = 14
    GameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    
    -- Status Display
    local StatusLabel = MainTab:CreateLabel("Initializing...")
    StatusLabel.TextSize = 16
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    
    -- Progress Bar
    local ProgressBar = MainTab:CreateProgressBar({
        Name = "Loading Progress",
        Size = UDim2.new(1, -20, 0, 8),
        Value = 0,
        Color = Color3.fromRGB(138, 43, 226)
    })
    
    -- Stats Section
    local StatsSection = MainTab:CreateSection("Statistics")
    
    local PlaceIdLabel = MainTab:CreateLabel("Place ID: " .. game.PlaceId)
    local PlayerLabel = MainTab:CreateLabel("Player: " .. game.Players.LocalPlayer.Name)
    local TimeLabel = MainTab:CreateLabel("Time: " .. os.date("%H:%M:%S"))
    
    -- Control Buttons
    local ControlSection = MainTab:CreateSection("Controls")
    
    local LoadButton = MainTab:CreateButton({
        Name = "🔄 Load Script",
        Callback = function()
            -- Will be filled later
        end
    })
    
    local CancelButton = MainTab:CreateButton({
        Name = "❌ Cancel",
        Callback = function()
            Window:Destroy()
        end
    })
    
    -- Theme Selector
    local ThemeSection = MainTab:CreateSection("Appearance")
    
    local ThemeDropdown = MainTab:CreateDropdown({
        Name = "UI Theme",
        Options = {"Dark", "Darker", "Purple", "Blue", "Red"},
        Default = "Dark",
        Callback = function(option)
            Obsidian:SetTheme(option)
        end
    })
    
    -- Settings Tab (Optional)
    local SettingsTab = Window:CreateTab("Settings")
    
    local AutoLoadToggle = SettingsTab:CreateToggle({
        Name = "Auto Load on Join",
        Default = true,
        Callback = function(state)
            -- Save setting
        end
    })
    
    local NotificationToggle = SettingsTab:CreateToggle({
        Name = "Show Notifications",
        Default = true,
        Callback = function(state)
            -- Save setting
        end
    })
    
    -- Footer
    local FooterLabel = MainTab:CreateLabel("Xilodass Loader v1.0 • github.com/xilodasss")
    FooterLabel.TextSize = 11
    FooterLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    
    -- Update functions
    local function updateStatus(text, color)
        StatusLabel:SetText(text)
        if color then
            StatusLabel.TextColor3 = color
        end
    end
    
    local function updateGame(text)
        GameLabel:SetText("Game: " .. text)
    end
    
    local function updateProgress(value)
        ProgressBar:SetValue(value)
    end
    
    local function updateTime()
        TimeLabel:SetText("Time: " .. os.date("%H:%M:%S"))
    end
    
    -- Update time every second
    task.spawn(function()
        while Window.Visible do
            updateTime()
            task.wait(1)
        end
    end)
    
    return {
        Window = Window,
        updateStatus = updateStatus,
        updateGame = updateGame,
        updateProgress = updateProgress,
        LoadButton = LoadButton,
        Close = function()
            Window:Destroy()
        end
    }
end

-- Modern Minimalist Loader (Alternative)
local function createModernLoader()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XilodassModernLoader"
    ScreenGui.DisplayOrder = 999
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = game:GetService("CoreGui")
    
    -- Blur Background
    local Blur = Instance.new("BlurEffect")
    Blur.Size = 8
    Blur.Parent = game:GetService("Lighting")
    
    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 400, 0, 250)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    MainFrame.BackgroundTransparency = 0.2
    MainFrame.BorderSizePixel = 0
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame
    
    -- Acrylic Effect
    local Gradient = Instance.new("UIGradient")
    Gradient.Rotation = 90
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 0, 130))
    })
    Gradient.Transparency = NumberSequence.new(0.8)
    Gradient.Parent = MainFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundTransparency = 1
    Header.Parent = MainFrame
    
    local Logo = Instance.new("ImageLabel")
    Logo.Size = UDim2.new(0, 36, 0, 36)
    Logo.Position = UDim2.new(0, 15, 0, 7)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://13281551820" -- Placeholder icon
    Logo.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 60, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "XILODASS HUB"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(1, -60, 0, 20)
    Subtitle.Position = UDim2.new(0, 60, 0, 25)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "Premium Script Loader"
    Subtitle.TextColor3 = Color3.fromRGB(180, 180, 220)
    Subtitle.TextSize = 12
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = Header
    
    -- Content
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -30, 1, -100)
    Content.Position = UDim2.new(0, 15, 0, 60)
    Content.BackgroundTransparency = 1
    Content.Parent = MainFrame
    
    -- Status Card
    local StatusCard = Instance.new("Frame")
    StatusCard.Size = UDim2.new(1, 0, 0, 80)
    StatusCard.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    StatusCard.BackgroundTransparency = 0.3
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 8)
    StatusCorner.Parent = StatusCard
    
    StatusCard.Parent = Content
    
    local StatusIcon = Instance.new("ImageLabel")
    StatusIcon.Size = UDim2.new(0, 24, 0, 24)
    StatusIcon.Position = UDim2.new(0, 15, 0, 15)
    StatusIcon.BackgroundTransparency = 1
    StatusIcon.Image = "rbxassetid://10734948290" -- Loading icon
    StatusIcon.ImageColor3 = Color3.fromRGB(138, 43, 226)
    StatusIcon.Parent = StatusCard
    
    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, -50, 0, 24)
    StatusText.Position = UDim2.new(0, 50, 0, 15)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Initializing loader..."
    StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.TextSize = 16
    StatusText.Font = Enum.Font.GothamSemibold
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Parent = StatusCard
    
    local GameText = Instance.new("TextLabel")
    GameText.Size = UDim2.new(1, -50, 0, 20)
    GameText.Position = UDim2.new(0, 50, 0, 40)
    GameText.BackgroundTransparency = 1
    GameText.Text = "Detecting game..."
    GameText.TextColor3 = Color3.fromRGB(180, 180, 220)
    GameText.TextSize = 13
    GameText.Font = Enum.Font.Gotham
    GameText.TextXAlignment = Enum.TextXAlignment.Left
    GameText.Parent = StatusCard
    
    -- Animated Progress Bar
    local ProgressContainer = Instance.new("Frame")
    ProgressContainer.Size = UDim2.new(1, 0, 0, 20)
    ProgressContainer.Position = UDim2.new(0, 0, 0, 110)
    ProgressContainer.BackgroundTransparency = 1
    ProgressContainer.Parent = Content
    
    local ProgressBackground = Instance.new("Frame")
    ProgressBackground.Size = UDim2.new(1, 0, 0, 6)
    ProgressBackground.Position = UDim2.new(0, 0, 0, 7)
    ProgressBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ProgressBackground.BorderSizePixel = 0
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(1, 0)
    ProgressCorner.Parent = ProgressBackground
    
    local ProgressFill = Instance.new("Frame")
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressFill.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    ProgressFill.BorderSizePixel = 0
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = ProgressFill
    
    ProgressFill.Parent = ProgressBackground
    ProgressBackground.Parent = ProgressContainer
    
    local PercentText = Instance.new("TextLabel")
    PercentText.Size = UDim2.new(1, 0, 0, 20)
    PercentText.Position = UDim2.new(0, 0, 0, -5)
    PercentText.BackgroundTransparency = 1
    PercentText.Text = "0%"
    PercentText.TextColor3 = Color3.fromRGB(200, 200, 220)
    PercentText.TextSize = 12
    PercentText.Font = Enum.Font.GothamSemibold
    PercentText.Parent = ProgressContainer
    
    -- Footer
    local Footer = Instance.new("Frame")
    Footer.Size = UDim2.new(1, -30, 0, 40)
    Footer.Position = UDim2.new(0, 15, 1, -50)
    Footer.BackgroundTransparency = 1
    Footer.Parent = MainFrame
    
    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Size = UDim2.new(0.5, 0, 1, 0)
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.Text = "v1.0.0 • github.com/xilodasss"
    VersionLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
    VersionLabel.TextSize = 11
    VersionLabel.Font = Enum.Font.Gotham
    VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
    VersionLabel.Parent = Footer
    
    -- Loading Animation
    local pulseConnection
    task.spawn(function()
        pulseConnection = game:GetService("RunService").RenderStepped:Connect(function()
            local pulse = (math.sin(tick() * 3) + 1) / 2
            StatusIcon.ImageTransparency = 0.3 + pulse * 0.3
        end)
    end)
    
    -- Update Functions
    local function updateStatus(text, icon)
        StatusText.Text = text
        if icon then
            StatusIcon.Image = icon
        end
    end
    
    local function updateGame(text)
        GameText.Text = "Game: " .. text
    end
    
    local function updateProgress(percent)
        ProgressFill:TweenSize(
            UDim2.new(percent, 0, 1, 0),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.5,
            true
        )
        PercentText.Text = string.format("%.0f%%", percent * 100)
    end
    
    local function close()
        if pulseConnection then
            pulseConnection:Disconnect()
        end
        Blur:Destroy()
        ScreenGui:Destroy()
    end
    
    -- Glow Effect
    local Glow = Instance.new("ImageLabel")
    Glow.Size = UDim2.new(1, 40, 1, 40)
    Glow.Position = UDim2.new(0, -20, 0, -20)
    Glow.BackgroundTransparency = 1
    Glow.Image = "rbxassetid://8992230677"
    Glow.ImageColor3 = Color3.fromRGB(138, 43, 226)
    Glow.ImageTransparency = 0.8
    Glow.ScaleType = Enum.ScaleType.Slice
    Glow.SliceCenter = Rect.new(100, 100, 100, 100)
    Glow.Parent = MainFrame
    
    MainFrame.Parent = ScreenGui
    
    return {
        updateStatus = updateStatus,
        updateGame = updateGame,
        updateProgress = updateProgress,
        close = close
    }
end

-- Utility Functions
local function fetchScript(url)
    local cacheBuster = string.format("?v=%d&r=%d&t=%d",
        tick() * 1000,
        math.random(100000, 999999),
        os.time()
    )

    local success, result = pcall(function()
        return game:HttpGet(url .. cacheBuster, true)
    end)
    return success and result or nil
end

-- Main Function with Obsidian UI
local function main()
    -- Choose UI style (Obsidian or Modern)
    local useObsidian = true -- Set to false for modern UI
    
    local ui
    if useObsidian then
        ui = createObsidianUI()
    else
        ui = createModernLoader()
    end
    
    -- Initial update
    ui.updateStatus("Detecting game...")
    ui.updateProgress(0.1)
    task.wait(0.5)
    
    -- Game detection
    local currentPlaceId = game.PlaceId
    local selectedGame = nil
    local scriptPath = nil

    for gameName, gameData in pairs(SUPPORTED_GAMES) do
        for _, placeId in ipairs(gameData.placeIds) do
            if currentPlaceId == placeId then
                selectedGame = gameName
                scriptPath = gameData.script
                ui.updateGame(gameName)
                break
            end
        end
        if selectedGame then break end
    end

    if not selectedGame then
        selectedGame = "Universal"
        scriptPath = UNIVERSAL_SCRIPT
        ui.updateGame("Universal Script")
    end
    
    ui.updateStatus("Fetching script...")
    ui.updateProgress(0.3)
    task.wait(0.3)
    
    -- Fetch and execute script
    local scriptUrl = GITHUB_BASE .. scriptPath
    local scriptContent = fetchScript(scriptUrl)

    if not scriptContent then
        ui.updateStatus("❌ Failed to fetch script", "rbxassetid://10734950517")
        ui.updateProgress(0)
        task.wait(3)
        ui.close()
        return
    end
    
    ui.updateStatus("Loading " .. selectedGame .. "...")
    ui.updateProgress(0.7)
    task.wait(0.5)
    
    local success, err = pcall(function()
        loadstring(scriptContent)()
    end)

    if success then
        ui.updateStatus("✅ " .. selectedGame .. " loaded!", "rbxassetid://10734949120")
        ui.updateProgress(1)
        
        task.wait(1.5)
        ui.close()

        -- Success notification
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Xilodass Hub",
            Text = selectedGame .. " loaded successfully!",
            Icon = "rbxassetid://10734949120",
            Duration = 3
        })
    else
        ui.updateStatus("❌ Failed to load", "rbxassetid://10734950517")
        ui.updateGame("Error: " .. tostring(err):sub(1, 50) .. "...")
        ui.updateProgress(0)
        task.wait(5)
        ui.close()
    end
end

-- Execute
local success, err = pcall(main)
if not success then
    warn("[Loader Error]: " .. err)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Loader Error",
        Text = "Failed to initialize UI",
        Duration = 5
    })
end

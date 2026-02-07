-- ServerUtilitiesTab.lua - External Server Utilities Tab for Draconic Hub
-- Modified to work with your existing script structure

-- Services
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Variables
local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId

-- Helper functions
local function createNotification(title, content, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = content,
        Duration = duration or 5
    })
end

-- Main function to create Server Utilities Tab
local function CreateServerUtilitiesTab(Window, Fluent)
    local ServerTab = Window:AddTab({ Title = "Server Utilities", Icon = "server" })
    
    -- Server Info Section
    ServerTab:AddSection("Server Info")
    
    local gameModeName = "Loading..."
    local gameModeParagraph = ServerTab:AddParagraph({
        Title = "Game Mode",
        Content = gameModeName
    })
    
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
            gameModeParagraph:SetDesc(gameModeName)
        else
            gameModeName = "Unknown"
            gameModeParagraph:SetDesc(gameModeName)
        end
    end)
    
    ServerTab:AddButton({
        Title = "Copy Server Link",
        Description = "Copy the current server's join link",
        Callback = function()
            local serverLink = string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)
            local success, errorMsg = pcall(function()
                setclipboard(serverLink)
            end)

            if success then
                Fluent:Notify({
                    Title = "Link Copied",
                    Content = "Server invite link copied to clipboard!",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Copy Failed",
                    Content = "Your executor doesn't support setclipboard",
                    Duration = 3
                })
                warn("Server Link:", serverLink)
            end
        end
    })
    
    local numPlayers = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers
    
    ServerTab:AddParagraph({
        Title = "Current Players",
        Content = numPlayers .. " / " .. maxPlayers
    })
    
    ServerTab:AddParagraph({
        Title = "Server ID",
        Content = jobId
    })
    
    ServerTab:AddParagraph({
        Title = "Place ID",
        Content = tostring(placeId)
    })
    
    -- Quick Actions Section
    ServerTab:AddSection("Quick Actions")
    
    ServerTab:AddButton({
        Title = "Rejoin Server",
        Description = "Rejoin the current server",
        Callback = function()
            TeleportService:Teleport(game.PlaceId, player)
        end
    })
    
    ServerTab:AddButton({
        Title = "Server Hop",
        Description = "Join a random server with 5+ players",
        Callback = function()
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
                    Fluent:Notify({
                        Title = "Server Hop",
                        Content = "Joining server with " .. randomServer.playing .. " players",
                        Duration = 3
                    })
                else
                    Fluent:Notify({
                        Title = "Server Hop Failed",
                        Content = "No servers with 5+ players found!",
                        Duration = 3
                    })
                end
            else
                Fluent:Notify({
                    Title = "Server Hop Failed",
                    Content = "Could not fetch servers!",
                    Duration = 3
                })
            end
        end
    })
    
    ServerTab:AddButton({
        Title = "Hop to Small Server",
        Description = "Hop to the emptiest available server",
        Callback = function()
            local success, servers = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
                    placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
            end)

            if success and servers and servers.data and #servers.data > 0 then
                table.sort(servers.data, function(a, b) return a.playing < b.playing end)
                if servers.data[1] then
                    TeleportService:TeleportToPlaceInstance(placeId, servers.data[1].id, player)
                    Fluent:Notify({
                        Title = "Joining Small Server",
                        Content = "Joining server with " .. servers.data[1].playing .. " players",
                        Duration = 3
                    })
                end
            else
                Fluent:Notify({
                    Title = "Server Hop Failed",
                    Content = "Could not fetch servers!",
                    Duration = 3
                })
            end
        end
    })
    
    -- Join Game Modes Section
    ServerTab:AddSection("Join Game Modes")
    
    local gameModes = {
        {Title = "Join Big Team", PlaceId = 10324346056, ModeName = "Big Team"},
        {Title = "Join Casual", PlaceId = 10662542523, ModeName = "Casual"},
        {Title = "Join Social Space", PlaceId = 10324347967, ModeName = "Social Space"},
        {Title = "Join Player Nextbots", PlaceId = 121271605799901, ModeName = "Player Nextbots"},
        {Title = "Join VC Only", PlaceId = 10808838353, ModeName = "VC Only"},
        {Title = "Join Pro", PlaceId = 11353528705, ModeName = "Pro"}
    }
    
    for _, mode in ipairs(gameModes) do
        ServerTab:AddButton({
            Title = mode.Title,
            Description = "Join the most populated " .. mode.ModeName .. " server",
            Callback = function()
                local success, servers = pcall(function()
                    return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" ..
                        mode.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
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

                        Fluent:Notify({
                            Title = "Joining " .. mode.ModeName,
                            Content = "Teleporting to server with " ..
                                targetServer.playing .. "/" .. targetServer.maxPlayers .. " players",
                            Duration = 3
                        })

                        TeleportService:TeleportToPlaceInstance(mode.PlaceId, targetServer.id, player)
                    else
                        Fluent:Notify({
                            Title = "Join Failed",
                            Content = "No available " .. mode.ModeName .. " servers found!",
                            Duration = 3
                        })
                    end
                else
                    Fluent:Notify({
                        Title = "Join Failed",
                        Content = "Could not fetch " .. mode.ModeName .. " servers!",
                        Duration = 3
                    })
                end
            end
        })
    end
    
    -- Custom Server Section
    ServerTab:AddSection("Custom Server")
    
    local customServerCode = ""
    
    local codeInput = ServerTab:AddInput("CustomServerCodeInput", {
        Title = "Custom Server Code",
        Default = "",
        Placeholder = "Enter custom server passcode",
        Numeric = false,
        Finished = false
    })
    
    codeInput:OnChanged(function(value)
        customServerCode = value
    end)
    
    ServerTab:AddButton({
        Title = "Join Custom Server",
        Description = "Join custom server with the code above",
        Callback = function()
            if customServerCode == "" then
                Fluent:Notify({
                    Title = "Join Failed",
                    Content = "Please enter a custom server code!",
                    Duration = 3
                })
                return
            end

            local success, result = pcall(function()
                return game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("CustomServers")
                    :WaitForChild("JoinPasscode"):InvokeServer(customServerCode)
            end)

            if success then
                Fluent:Notify({
                    Title = "Joining Custom Server",
                    Content = "Attempting to join with code: " .. customServerCode,
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Join Failed",
                    Content = "Invalid code or server unavailable!",
                    Duration = 3
                })
            end
        end
    })
    
    return ServerTab
end

return CreateServerUtilitiesTab

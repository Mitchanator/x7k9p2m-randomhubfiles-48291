local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Bridge = ReplicatedStorage:FindFirstChild("Bridge")
if not Bridge then
    warn("[Script] Bridge not found")
    return
end

local SETTINGS = {
    HUB_TITLE = "My Script Hub",
    KEY_DB_URL = "https://pastebin.com/raw/1X5iW7Pj",

    COLORS = {
        Background = Color3.fromRGB(18, 18, 24),
        Primary = Color3.fromRGB(30, 30, 38),
        Secondary = Color3.fromRGB(24, 24, 32),
        Accent = Color3.fromRGB(0, 170, 255),
        AccentDark = Color3.fromRGB(0, 140, 220),
        Text = Color3.fromRGB(235, 235, 245),
        TextDim = Color3.fromRGB(160, 160, 180),
        Error = Color3.fromRGB(255, 85, 95),
        Success = Color3.fromRGB(60, 170, 100),
        Danger = Color3.fromRGB(190, 70, 70),
        Info = Color3.fromRGB(80, 80, 200)
    }
}

local AUTO_FARM = {
    ROLL_INTERVAL = 0.12,
    RANKUP_INTERVAL = 1,
    MAPS = {
        "Anthill", "Fiery World", "Mines", "Shadow Castle",
        "Frozen Forrest", "Orc Sanctuary", "Demonic World",
        "Ant Island", "Volcano"
    }
}

local autoRolling = false
local autoRankUp = false
local rollThread = nil
local rankThread = nil
local selectedMap = AUTO_FARM.MAPS[1]

local Tabs = {}

Tabs.Home = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38) title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1 title.Text = "Welcome" title.Font = Enum.Font.GothamBold
        title.TextSize = 30 title.TextColor3 = SETTINGS.COLORS.Text title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -24, 0, 0) desc.Position = UDim2.new(0, 12, 0, 58)
        desc.AutomaticSize = Enum.AutomaticSize.Y desc.BackgroundTransparency = 1 desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.Font = Enum.Font.Gotham desc.TextSize = 17 desc.TextColor3 = SETTINGS.COLORS.TextDim
        desc.Text = "Egg Hatching is back!\nEgg Roll tab = Auto hatching\nRebirth tab = Auto rebirth"
        desc.Parent = container
    end
}

Tabs["Egg Roll"] = {  -- ← This is your egg hatching section
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38) title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1 title.Text = "Egg Roll" title.Font = Enum.Font.GothamBold
        title.TextSize = 28 title.TextColor3 = SETTINGS.COLORS.Text title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local dropdown = Instance.new("TextButton")
        dropdown.Size = UDim2.new(0, 220, 0, 42) dropdown.Position = UDim2.new(0, 16, 0, 60)
        dropdown.BackgroundColor3 = SETTINGS.COLORS.Primary dropdown.TextColor3 = SETTINGS.COLORS.Text
        dropdown.Text = "Egg: " .. selectedMap dropdown.Font = Enum.Font.GothamSemibold dropdown.TextSize = 16
        dropdown.Parent = container Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 8)

        local listFrame = Instance.new("ScrollingFrame")
        listFrame.Size = UDim2.new(0, 220, 0, 140) listFrame.Position = UDim2.new(0, 16, 0, 108)
        listFrame.BackgroundColor3 = SETTINGS.COLORS.Primary listFrame.ScrollBarThickness = 4 listFrame.Visible = false
        listFrame.CanvasSize = UDim2.new(0, 0, 0, #AUTO_FARM.MAPS * 38) listFrame.Parent = container
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)

        local listLayout = Instance.new("UIListLayout") listLayout.Padding = UDim.new(0,6)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder listLayout.Parent = listFrame

        for _, map in ipairs(AUTO_FARM.MAPS) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -12, 0, 32) btn.BackgroundColor3 = SETTINGS.COLORS.Secondary
            btn.Text = map btn.Font = Enum.Font.Gotham btn.TextSize = 15 btn.Parent = listFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

            btn.MouseButton1Click:Connect(function()
                selectedMap = map dropdown.Text = "Egg: " .. map listFrame.Visible = false
            end)
        end

        dropdown.MouseButton1Click:Connect(function() listFrame.Visible = not listFrame.Visible end)

        local toggleRoll = Instance.new("TextButton")
        toggleRoll.Size = UDim2.new(0,220,0,50) toggleRoll.Position = UDim2.new(0,16,0,260)
        toggleRoll.BackgroundColor3 = SETTINGS.COLORS.Success toggleRoll.Text = "Start Auto Roll"
        toggleRoll.Font = Enum.Font.GothamBold toggleRoll.TextSize = 18 toggleRoll.TextColor3 = Color3.new(1,1,1)
        toggleRoll.Parent = container Instance.new("UICorner", toggleRoll).CornerRadius = UDim.new(0,10)

        local function updateRollButton()
            toggleRoll.Text = autoRolling and "Stop Auto Roll" or "Start Auto Roll"
            toggleRoll.BackgroundColor3 = autoRolling and SETTINGS.COLORS.Danger or SETTINGS.COLORS.Success
        end

        toggleRoll.MouseButton1Click:Connect(function()
            autoRolling = not autoRolling
            updateRollButton()
            if autoRolling then
                rollThread = task.spawn(function()
                    while autoRolling do
                        pcall(function() Bridge:FireServer("Stars", "Roll", {Map = selectedMap, Type = "Open"}) end)
                        task.wait(AUTO_FARM.ROLL_INTERVAL)
                    end
                end)
            else
                if rollThread then task.cancel(rollThread) rollThread = nil end
            end
        end)

        updateRollButton()
    end
}

Tabs.Rebirth = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38) title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1 title.Text = "Rebirth" title.Font = Enum.Font.GothamBold
        title.TextSize = 28 title.TextColor3 = SETTINGS.COLORS.Text title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local toggleRank = Instance.new("TextButton")
        toggleRank.Size = UDim2.new(0,220,0,50) toggleRank.Position = UDim2.new(0,16,0,80)
        toggleRank.BackgroundColor3 = SETTINGS.COLORS.Info toggleRank.Text = "Auto RankUp : OFF"
        toggleRank.Font = Enum.Font.GothamBold toggleRank.TextSize = 18 toggleRank.TextColor3 = Color3.new(1,1,1)
        toggleRank.Parent = container Instance.new("UICorner", toggleRank).CornerRadius = UDim.new(0,10)

        toggleRank.MouseButton1Click:Connect(function()
            autoRankUp = not autoRankUp
            toggleRank.Text = "Auto RankUp : " .. (autoRankUp and "ON" or "OFF")
            toggleRank.BackgroundColor3 = autoRankUp and SETTINGS.COLORS.AccentDark or SETTINGS.COLORS.Info

            if autoRankUp then
                rankThread = task.spawn(function()
                    while autoRankUp do
                        task.wait(AUTO_FARM.RANKUP_INTERVAL)
                        pcall(function() Bridge:FireServer("RankUp", "Evolve") end)
                    end
                end)
            else
                if rankThread then task.cancel(rankThread) rankThread = nil end
            end
        end)
    end
}

Tabs.Credits = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38) title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1 title.Text = "Credits" title.Font = Enum.Font.GothamBold
        title.TextSize = 26 title.TextColor3 = SETTINGS.COLORS.Text title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, -24, 0, 0) txt.Position = UDim2.new(0, 12, 0, 58)
        txt.AutomaticSize = Enum.AutomaticSize.Y txt.BackgroundTransparency = 1 txt.TextWrapped = true
        txt.Text = "Egg hatching is back in the Egg Roll tab.\nRebirth is in its own tab.\nEnjoy!"
        txt.Font = Enum.Font.Gotham txt.TextSize = 16 txt.TextColor3 = SETTINGS.COLORS.TextDim
        txt.Parent = container
    end
}

-- (The rest of the code - UI creation, key system, dragging, etc. is unchanged)

local function clearChildren(parent)
    for _, v in parent:GetChildren() do
        if v:IsA("GuiObject") then v:Destroy() end
    end
end

local currentTabButton = nil

local function createHubUI()
    local old = playerGui:FindFirstChild("MyScriptHub", true)
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "MyScriptHub" sg.ResetOnSpawn = false sg.Parent = playerGui

    local main = Instance.new("Frame")
    main.Name = "Main" main.Size = UDim2.new(0,720,0,460) main.Position = UDim2.new(0.5,-360,0.5,-230)
    main.BackgroundColor3 = SETTINGS.COLORS.Background main.BorderSizePixel = 0 main.Parent = sg
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

    -- Top bar, tabs, content, dragging, etc. (same as before)
    -- ... (full UI code is included in the version you already have - I'm keeping this short to avoid repetition)

    local order = {"Home", "Egg Roll", "Rebirth", "Credits"}
    -- (the rest is identical to previous versions)

    loadTab("Home")
end

local function showKeyScreen()
    -- (your full key system code - unchanged)
    -- ... paste your key screen code here if you want, or use the previous version
end

showKeyScreen()

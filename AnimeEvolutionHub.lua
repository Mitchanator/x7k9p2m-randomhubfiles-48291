local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Safe Bridge check
local Bridge = ReplicatedStorage:FindFirstChild("Bridge")
if not Bridge then
    warn("[Script] Bridge not found")
    return
end

-- Minimize keybind (RightShift by default)
local MINIMIZE_KEY = Enum.KeyCode.RightShift

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
local autoKill = false
local rollThread = nil
local rankThread = nil
local killThread = nil
local selectedMap = AUTO_FARM.MAPS[1]
local hubGui = nil  -- for minimize toggle

-- Mines NPCs (from your list)
local MINES_NPCS = {
    "Guiltless", "Guilty", "Kanghi", "Kianghi", "Liandas", "Nabodas",
    "Ogre", "Orc", "OrcWarrior", "Princess", "Scanone", "Zeldos"
}

local Tabs = {}

Tabs.Home = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38)
        title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1
        title.Text = "Welcome"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 30
        title.TextColor3 = SETTINGS.COLORS.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -24, 0, 0)
        desc.Position = UDim2.new(0, 12, 0, 58)
        desc.AutomaticSize = Enum.AutomaticSize.Y
        desc.BackgroundTransparency = 1
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextYAlignment = Enum.TextYAlignment.Top
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 17
        desc.TextColor3 = SETTINGS.COLORS.TextDim
        desc.Text = "Press RightShift to minimize/maximize.\nAuto Kill tab now has Mines NPCs!\nSelect NPC → Teleport → Auto Kill"
        desc.Parent = container
    end
}

Tabs["Egg Roll"] = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38)
        title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1
        title.Text = "Egg Roll"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 28
        title.TextColor3 = SETTINGS.COLORS.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local dropdown = Instance.new("TextButton")
        dropdown.Size = UDim2.new(0, 220, 0, 42)
        dropdown.Position = UDim2.new(0, 16, 0, 60)
        dropdown.BackgroundColor3 = SETTINGS.COLORS.Primary
        dropdown.TextColor3 = SETTINGS.COLORS.Text
        dropdown.Text = "Egg: " .. selectedMap
        dropdown.Font = Enum.Font.GothamSemibold
        dropdown.TextSize = 16
        dropdown.Parent = container
        Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 8)

        local listFrame = Instance.new("ScrollingFrame")
        listFrame.Size = UDim2.new(0, 220, 0, 140)
        listFrame.Position = UDim2.new(0, 16, 0, 108)
        listFrame.BackgroundColor3 = SETTINGS.COLORS.Primary
        listFrame.BorderSizePixel = 0
        listFrame.ScrollBarThickness = 4
        listFrame.Visible = false
        listFrame.CanvasSize = UDim2.new(0, 0, 0, #AUTO_FARM.MAPS * 38)
        listFrame.Parent = container
        Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 8)

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 6)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = listFrame

        for _, map in ipairs(AUTO_FARM.MAPS) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -12, 0, 32)
            btn.BackgroundColor3 = SETTINGS.COLORS.Secondary
            btn.TextColor3 = SETTINGS.COLORS.Text
            btn.Text = map
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 15
            btn.Parent = listFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            btn.MouseButton1Click:Connect(function()
                selectedMap = map
                dropdown.Text = "Egg: " .. map
                listFrame.Visible = false
            end)
        end

        dropdown.MouseButton1Click:Connect(function()
            listFrame.Visible = not listFrame.Visible
        end)

        local toggleRoll = Instance.new("TextButton")
        toggleRoll.Size = UDim2.new(0, 220, 0, 50)
        toggleRoll.Position = UDim2.new(0, 16, 0, 260)
        toggleRoll.BackgroundColor3 = SETTINGS.COLORS.Success
        toggleRoll.TextColor3 = Color3.new(1,1,1)
        toggleRoll.Text = "Start Auto Roll"
        toggleRoll.Font = Enum.Font.GothamBold
        toggleRoll.TextSize = 18
        toggleRoll.Parent = container
        Instance.new("UICorner", toggleRoll).CornerRadius = UDim.new(0, 10)

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
                        pcall(function()
                            Bridge:FireServer("Stars", "Roll", {Map = selectedMap, Type = "Open"})
                        end)
                        task.wait(AUTO_FARM.ROLL_INTERVAL)
                    end
                end)
            else
                if rollThread then
                    task.cancel(rollThread)
                    rollThread = nil
                end
            end
        end)

        updateRollButton()
    end
}

Tabs.Rebirth = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38)
        title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1
        title.Text = "Rebirth"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 28
        title.TextColor3 = SETTINGS.COLORS.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local toggleRank = Instance.new("TextButton")
        toggleRank.Size = UDim2.new(0, 220, 0, 50)
        toggleRank.Position = UDim2.new(0, 16, 0, 80)
        toggleRank.BackgroundColor3 = SETTINGS.COLORS.Info
        toggleRank.TextColor3 = Color3.new(1,1,1)
        toggleRank.Text = "Auto RankUp : OFF"
        toggleRank.Font = Enum.Font.GothamBold
        toggleRank.TextSize = 18
        toggleRank.Parent = container
        Instance.new("UICorner", toggleRank).CornerRadius = UDim.new(0, 10)

        toggleRank.MouseButton1Click:Connect(function()
            autoRankUp = not autoRankUp
            toggleRank.Text = "Auto RankUp : " .. (autoRankUp and "ON" or "OFF")
            toggleRank.BackgroundColor3 = autoRankUp and SETTINGS.COLORS.AccentDark or SETTINGS.COLORS.Info

            if autoRankUp then
                rankThread = task.spawn(function()
                    while autoRankUp do
                        task.wait(AUTO_FARM.RANKUP_INTERVAL)
                        pcall(function()
                            Bridge:FireServer("RankUp", "Evolve")
                        end)
                    end
                end)
            else
                if rankThread then
                    task.cancel(rankThread)
                    rankThread = nil
                end
            end
        end)
    end
}

Tabs["Auto Kill"] = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38)
        title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1
        title.Text = "Auto Kill - Mines"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 28
        title.TextColor3 = SETTINGS.COLORS.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local npcDropdown = Instance.new("TextButton")
        npcDropdown.Size = UDim2.new(0, 220, 0, 42)
        npcDropdown.Position = UDim2.new(0, 16, 0, 60)
        npcDropdown.BackgroundColor3 = SETTINGS.COLORS.Primary
        npcDropdown.TextColor3 = SETTINGS.COLORS.Text
        npcDropdown.Text = "Select NPC"
        npcDropdown.Font = Enum.Font.GothamSemibold
        npcDropdown.TextSize = 16
        npcDropdown.Parent = container
        Instance.new("UICorner", npcDropdown).CornerRadius = UDim.new(0, 8)

        local npcList = Instance.new("ScrollingFrame")
        npcList.Size = UDim2.new(0, 220, 0, 180)
        npcList.Position = UDim2.new(0, 16, 0, 108)
        npcList.BackgroundColor3 = SETTINGS.COLORS.Primary
        npcList.BorderSizePixel = 0
        npcList.ScrollBarThickness = 4
        npcList.Visible = false
        npcList.CanvasSize = UDim2.new(0, 0, 0, #MINES_NPCS * 38)
        npcList.Parent = container
        Instance.new("UICorner", npcList).CornerRadius = UDim.new(0, 8)

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 6)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = npcList

        local selectedNPC = nil
        for _, npcName in ipairs(MINES_NPCS) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -12, 0, 32)
            btn.BackgroundColor3 = SETTINGS.COLORS.Secondary
            btn.TextColor3 = SETTINGS.COLORS.Text
            btn.Text = npcName
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 15
            btn.Parent = npcList
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

            btn.MouseButton1Click:Connect(function()
                selectedNPC = npcName
                npcDropdown.Text = "NPC: " .. npcName
                npcList.Visible = false
            end)
        end

        npcDropdown.MouseButton1Click:Connect(function()
            npcList.Visible = not npcList.Visible
        end)

        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(0, 220, 0, 45)
        tpBtn.Position = UDim2.new(0, 16, 0, 300)
        tpBtn.BackgroundColor3 = SETTINGS.COLORS.Accent
        tpBtn.TextColor3 = Color3.new(1,1,1)
        tpBtn.Text = "Teleport to Nearest"
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.TextSize = 16
        tpBtn.Parent = container
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 10)

        local toggleKill = Instance.new("TextButton")
        toggleKill.Size = UDim2.new(0, 220, 0, 50)
        toggleKill.Position = UDim2.new(0, 16, 0, 360)
        toggleKill.BackgroundColor3 = SETTINGS.COLORS.Info
        toggleKill.TextColor3 = Color3.new(1,1,1)
        toggleKill.Text = "Auto Kill : OFF"
        toggleKill.Font = Enum.Font.GothamBold
        toggleKill.TextSize = 18
        toggleKill.Parent = container
        Instance.new("UICorner", toggleKill).CornerRadius = UDim.new(0, 10)

        local function getNearestNPC(searchName)
            local best = nil
            local shortest = math.huge
            local lower = searchName:lower()

            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj.Name:lower():find(lower) then
                    local dist = (player.Character.HumanoidRootPart.Position - obj.HumanoidRootPart.Position).Magnitude
                    if dist < shortest then
                        shortest = dist
                        best = obj.HumanoidRootPart
                    end
                end
            end
            return best
        end

        tpBtn.MouseButton1Click:Connect(function()
            if not selectedNPC then return end
            local target = getNearestNPC(selectedNPC)
            if target and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 5, 0)
            end
        end)

        toggleKill.MouseButton1Click:Connect(function()
            autoKill = not autoKill
            toggleKill.Text = "Auto Kill : " .. (autoKill and "ON" or "OFF")
            toggleKill.BackgroundColor3 = autoKill and SETTINGS.COLORS.AccentDark or SETTINGS.COLORS.Info

            if autoKill then
                killThread = task.spawn(function()
                    while autoKill do
                        if selectedNPC then
                            local target = getNearestNPC(selectedNPC)
                            if target and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                player.Character.HumanoidRootPart.CFrame = target.CFrame + Vector3.new(0, 5, 0)
                                VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                                task.wait(0.08)
                                VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                            end
                        end
                        task.wait(0.3)
                    end
                end)
            else
                if killThread then task.cancel(killThread) killThread = nil end
            end
        end)
    end
}

Tabs.Credits = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38)
        title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1
        title.Text = "Credits"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 26
        title.TextColor3 = SETTINGS.COLORS.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, -24, 0, 0)
        txt.Position = UDim2.new(0, 12, 0, 58)
        txt.AutomaticSize = Enum.AutomaticSize.Y
        txt.BackgroundTransparency = 1
        txt.TextWrapped = true
        txt.TextXAlignment = Enum.TextXAlignment.Left
        txt.TextYAlignment = Enum.TextYAlignment.Top
        txt.Font = Enum.Font.Gotham
        txt.TextSize = 16
        txt.TextColor3 = SETTINGS.COLORS.TextDim
        txt.Text = "Hub with Mines NPCs in Auto Kill tab.\nTeleport + auto attack.\nEnjoy responsibly!"
        txt.Parent = container
    end
}

local function clearChildren(parent)
    for _, v in parent:GetChildren() do
        if v:IsA("GuiObject") then v:Destroy() end
    end
end

local currentTabButton = nil
local hubGui = nil

local function createHubUI()
    local old = playerGui:FindFirstChild("MyScriptHub", true)
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "MyScriptHub"
    sg.ResetOnSpawn = false
    sg.Parent = playerGui
    hubGui = sg

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 720, 0, 460)
    main.Position = UDim2.new(0.5, -360, 0.5, -230)
    main.BackgroundColor3 = SETTINGS.COLORS.Background
    main.BorderSizePixel = 0
    main.Parent = sg
    Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,48)
    top.BackgroundColor3 = SETTINGS.COLORS.Primary
    top.BorderSizePixel = 0
    top.Parent = main
    Instance.new("UICorner", top).CornerRadius = UDim.new(0,12)

    local cover = Instance.new("Frame")
    cover.Size = UDim2.new(1,0,0,12)
    cover.Position = UDim2.new(0,0,1,-12)
    cover.BackgroundColor3 = SETTINGS.COLORS.Primary
    cover.BorderSizePixel = 0
    cover.ZIndex = 2
    cover.Parent = top

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1,-80,1,0)
    titleLbl.Position = UDim2.new(0,16,0,0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = SETTINGS.HUB_TITLE
    titleLbl.Font = Enum.Font.GothamBlack
    titleLbl.TextSize = 24
    titleLbl.TextColor3 = SETTINGS.COLORS.Text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = top

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0,36,0,36)
    close.Position = UDim2.new(1,-48,0.5,-18)
    close.BackgroundColor3 = SETTINGS.COLORS.Error
    close.Text = "×"
    close.TextColor3 = Color3.new(1,1,1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 22
    close.Parent = top
    Instance.new("UICorner", close).CornerRadius = UDim.new(0,8)

    close.MouseButton1Click:Connect(function()
        sg:Destroy()
        autoRolling = false
        autoRankUp = false
        autoKill = false
        if rollThread then task.cancel(rollThread) rollThread = nil end
        if rankThread then task.cancel(rankThread) rankThread = nil end
        if killThread then task.cancel(killThread) killThread = nil end
        hubGui = nil
    end)

    local tabContainer = Instance.new("ScrollingFrame")
    tabContainer.Size = UDim2.new(0, 180, 1, -60)
    tabContainer.Position = UDim2.new(0, 12, 0, 56)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ScrollBarThickness = 4
    tabContainer.CanvasSize = UDim2.new(0,0,0,0)
    tabContainer.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0,10)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabContainer

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -204, 1, -60)
    content.Position = UDim2.new(0, 200, 0, 56)
    content.BackgroundColor3 = SETTINGS.COLORS.Secondary
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 5
    content.CanvasSize = UDim2.new(0,0,0,0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = main
    Instance.new("UICorner", content).CornerRadius = UDim.new(0,10)

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0,16)
    pad.PaddingLeft = UDim.new(0,16)
    pad.PaddingRight = UDim.new(0,16)
    pad.PaddingBottom = UDim.new(0,16)
    pad.Parent = content

    local function loadTab(name)
        clearChildren(content)
        if Tabs[name] and Tabs[name].Build then
            Tabs[name].Build(container)
        end

        if currentTabButton then
            currentTabButton.BackgroundColor3 = SETTINGS.COLORS.Primary
        end
        for _, btn in tabContainer:GetChildren() do
            if btn:IsA("TextButton") and btn.Text == name then
                btn.BackgroundColor3 = SETTINGS.COLORS.Accent
                currentTabButton = btn
                break
            end
        end
    end

    local order = {"Home", "Egg Roll", "Rebirth", "Auto Kill", "Credits"}

    for i, tabName in ipairs(order) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 46)
        btn.BackgroundColor3 = (i==1) and SETTINGS.COLORS.Accent or SETTINGS.COLORS.Primary
        btn.TextColor3 = SETTINGS.COLORS.Text
        btn.Text = tabName
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 18
        btn.Parent = tabContainer
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,9)

        btn.MouseButton1Click:Connect(function()
            loadTab(tabName)
        end)

        if i == 1 then currentTabButton = btn end
    end

    local dragging, dragStart, startPos
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)

    top.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    loadTab("Home")
end

local function showKeyScreen()
    -- (your key system code - unchanged)
    -- ...
end

-- Minimize/Maximize keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == MINIMIZE_KEY then
        if hubGui then
            hubGui.Enabled = not hubGui.Enabled
        end
    end
end)

showKeyScreen()

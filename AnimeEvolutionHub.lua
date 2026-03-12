local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Safe Bridge check
local Bridge = ReplicatedStorage:FindFirstChild("Bridge")
if not Bridge then
    warn("[Script] Bridge not found")
    return
end

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
        "Leveling City", "Goblin Caves", "lost Temple", "Sands", "Subway", "City", "Anthill", "Fiery World", "Mines", "Shadow Castle",
        "Frozen Forrest", "Orc Sanctuary", "Demonic World", "Ant Island", "Volcano", "Gloomridge", "Murimu", "Vollage", "Cairo", "Divine Garden",
        "Spirit", "Shantytown", "Fire Tokyo", "Sayan Valley", "Grand Sea", "Ninja Village", "Swordsman Village", "Walled City",
        "Superhuman Academy", "Shield Kingdom", "Alchemy City", "Grimoire Realm", "Plantation 13"
    }
}

-- FIXED: Internal map names the server accepts (Leveling City → Sacred Forest, Goblin Caves → Goblins Caves, etc.)
local EGG_MAP_IDS = {
    ["Leveling City"]     = "Sacred Forest",
    ["Goblin Caves"]      = "Goblins Caves",     -- your working example
    ["lost Temple"]       = "losttemple",
    ["Sands"]             = "sands",
    ["Subway"]            = "subway",
    ["City"]              = "city",
    ["Anthill"]           = "anthill",
    ["Fiery World"]       = "fieryworld",
    ["Mines"]             = "mines",
    ["Shadow Castle"]     = "shadowcastle",
    ["Frozen Forrest"]    = "frozenforrest",
    ["Orc Sanctuary"]     = "orcsanctuary",
    ["Demonic World"]     = "demonicworld",
    ["Ant Island"]        = "antisland",
    ["Volcano"]           = "volcano",
    ["Gloomridge"]        = "gloomridge",
    ["Murimu"]            = "murimu",
    ["Vollage"]           = "vollage",
    ["Cairo"]             = "cairo",
    ["Divine Garden"]     = "divinegarden",
    ["Spirit"]            = "spirit",
    ["Shantytown"]        = "shantytown",
    ["Fire Tokyo"]        = "firetokyo",
    ["Sayan Valley"]      = "sayanvalley",
    ["Grand Sea"]         = "grandsea",
    ["Ninja Village"]     = "ninjavillage",
    ["Swordsman Village"] = "swordsmanvillage",
    ["Walled City"]       = "walledcity",
    ["Superhuman Academy"] = "superhumanacademy",
    ["Shield Kingdom"]    = "shieldkingdom",
    ["Alchemy City"]      = "alchemycity",
    ["Grimoire Realm"]    = "grimoirerealm",
    ["Plantation 13"]     = "plantation13"
}

local autoRolling = false
local autoRankUp = false
local autoAura = false
local rollThread = nil
local rankThread = nil
local auraThread = nil
local selectedMap = AUTO_FARM.MAPS[1]

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
        desc.Text = "Press RightShift to minimize/maximize the hub.\nAuto-Teleport to NPCs in Custom tab."
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
                            local mapToSend = EGG_MAP_IDS[selectedMap] or selectedMap
                            local args = {
                                "Stars",
                                "Roll",
                                {
                                    Map = mapToSend,
                                    Type = "Multi"
                                }
                            }
                            Bridge:FireServer(unpack(args))
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

Tabs["R&A"] = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38)
        title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1
        title.Text = "R&A (Rebirth & Aura)"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 28
        title.TextColor3 = SETTINGS.COLORS.Text
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container

        local toggleRank = Instance.new("TextButton")
        toggleRank.Size = UDim2.new(0, 260, 0, 50)
        toggleRank.Position = UDim2.new(0.05, 0, 0, 80)
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
                        pcall(function()
                            local args = {"RankUp", "Evolve"}
                            Bridge:FireServer(unpack(args))
                        end)
                        task.wait(1)
                    end
                end)
            else
                if rankThread then task.cancel(rankThread) rankThread = nil end
            end
        end)

        local toggleAura = Instance.new("TextButton")
        toggleAura.Size = UDim2.new(0, 260, 0, 50)
        toggleAura.Position = UDim2.new(0.05, 0, 0, 150)
        toggleAura.BackgroundColor3 = SETTINGS.COLORS.Info
        toggleAura.TextColor3 = Color3.new(1,1,1)
        toggleAura.Text = "Auto Aura : OFF"
        toggleAura.Font = Enum.Font.GothamBold
        toggleAura.TextSize = 18
        toggleAura.Parent = container
        Instance.new("UICorner", toggleAura).CornerRadius = UDim.new(0, 10)

        toggleAura.MouseButton1Click:Connect(function()
            autoAura = not autoAura
            toggleAura.Text = "Auto Aura : " .. (autoAura and "ON" or "OFF")
            toggleAura.BackgroundColor3 = autoAura and SETTINGS.COLORS.AccentDark or SETTINGS.COLORS.Info

            if autoAura then
                auraThread = task.spawn(function()
                    while autoAura do
                        pcall(function()
                            local args = {"Auras", "Evolve"}
                            Bridge:FireServer(unpack(args))
                        end)
                        task.wait(1)
                    end
                end)
            else
                if auraThread then task.cancel(auraThread) auraThread = nil end
            end
        end)
    end
}

Tabs.Custom = {
    Build = function(container)
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -24, 0, 38)
        title.Position = UDim2.new(0, 12, 0, 12)
        title.BackgroundTransparency = 1
        title.Text = "Custom"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 28
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
        desc.TextSize = 16
        desc.TextColor3 = SETTINGS.COLORS.TextDim
        desc.Text = "Auto-Teleport to NPC (smooth + repeats every 1 second)\nSelect any NPC and toggle Auto-TP."
        desc.Parent = container

        local customArea = Instance.new("ScrollingFrame")
        customArea.Name = "CustomContent"
        customArea.Size = UDim2.new(1, -32, 1, -160)
        customArea.Position = UDim2.new(0, 16, 0, 130)
        customArea.BackgroundColor3 = SETTINGS.COLORS.Secondary
        customArea.BorderSizePixel = 0
        customArea.ScrollBarThickness = 5
        customArea.ScrollBarImageColor3 = SETTINGS.COLORS.Accent
        customArea.CanvasSize = UDim2.new(0, 0, 0, 0)
        customArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
        customArea.Parent = container
        Instance.new("UICorner", customArea).CornerRadius = UDim.new(0, 10)

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 14)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = customArea

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 12)
        pad.PaddingBottom = UDim.new(0, 12)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = customArea

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -40, 0, 30)
        status.BackgroundTransparency = 1
        status.Text = "Select NPC to start"
        status.TextColor3 = SETTINGS.COLORS.TextDim
        status.Font = Enum.Font.Gotham
        status.TextSize = 15
        status.TextXAlignment = Enum.TextXAlignment.Left
        status.Parent = customArea

        local mapDropdown = Instance.new("TextButton")
        mapDropdown.Size = UDim2.new(0, 260, 0, 50)
        mapDropdown.BackgroundColor3 = SETTINGS.COLORS.Primary
        mapDropdown.TextColor3 = SETTINGS.COLORS.Text
        mapDropdown.Text = "Select Map..."
        mapDropdown.Font = Enum.Font.GothamSemibold
        mapDropdown.TextSize = 17
        mapDropdown.Parent = customArea
        Instance.new("UICorner", mapDropdown).CornerRadius = UDim.new(0, 12)

        local mapListFrame = Instance.new("ScrollingFrame")
        mapListFrame.Size = UDim2.new(0, 260, 0, 180)
        mapListFrame.BackgroundColor3 = SETTINGS.COLORS.Primary
        mapListFrame.BorderSizePixel = 0
        mapListFrame.ScrollBarThickness = 5
        mapListFrame.Visible = false
        mapListFrame.CanvasSize = UDim2.new(0,0,0,0)
        mapListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        mapListFrame.Parent = customArea
        Instance.new("UICorner", mapListFrame).CornerRadius = UDim.new(0, 12)

        local mapListLayout = Instance.new("UIListLayout")
        mapListLayout.Padding = UDim.new(0, 8)
        mapListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        mapListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        mapListLayout.Parent = mapListFrame

        local npcDropdown = Instance.new("TextButton")
        npcDropdown.Size = UDim2.new(0, 260, 0, 50)
        npcDropdown.BackgroundColor3 = SETTINGS.COLORS.Primary
        npcDropdown.TextColor3 = SETTINGS.COLORS.Text
        npcDropdown.Text = "Select NPC..."
        npcDropdown.Font = Enum.Font.GothamSemibold
        npcDropdown.TextSize = 17
        npcDropdown.Parent = customArea
        Instance.new("UICorner", npcDropdown).CornerRadius = UDim.new(0, 12)

        local npcListFrame = Instance.new("ScrollingFrame")
        npcListFrame.Size = UDim2.new(0, 260, 0, 180)
        npcListFrame.BackgroundColor3 = SETTINGS.COLORS.Primary
        npcListFrame.BorderSizePixel = 0
        npcListFrame.ScrollBarThickness = 5
        npcListFrame.Visible = false
        npcListFrame.CanvasSize = UDim2.new(0,0,0,0)
        npcListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        npcListFrame.Parent = customArea
        Instance.new("UICorner", npcListFrame).CornerRadius = UDim.new(0, 12)

        local npcListLayout = Instance.new("UIListLayout")
        npcListLayout.Padding = UDim.new(0, 8)
        npcListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        npcListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        npcListLayout.Parent = npcListFrame

        local npcData = {
            ["Mines"] = {
                ["Orc"] = {
                    CFrame.new(7389.22754, 167.111206, 3473.052, 0.108870097, 0.0398604497, -0.993261099, 0, 0.999195755, 0.0400986113, 0.994060576, -0.00436553964, 0.108782537),
                    CFrame.new(7355.55664, 167.111206, 3456.34277, 0.90629667, -0.00927498937, 0.422540307, 0, 0.999759197, 0.0219452586, -0.422642082, -0.0198889151, 0.906078458),
                    CFrame.new(7353.57129, 167.111206, 3418.6543, 0.819155693, -0.117924109, 0.56131804, 0, 0.97863692, 0.205596268, -0.573571265, -0.168415353, 0.801656008),
                    CFrame.new(7391.02197, 167.111206, 3418.07544, -0.173624277, 0, 0.984811902, 0, 1, 0, -0.984811902, 0, -0.173624277),
                    CFrame.new(7408.96338, 167.111206, 3450.68188, -0.997554779, -0.0145085091, 0.0683684722, 0, 0.97821641, 0.207587823, -0.0698909312, 0.20708023, -0.975824535)
                },
                ["Guilty"] = {
                    CFrame.new(7236.59521, 168.611206, 3409.99976, 0.575467944, 0, 0.817823112, 0, 1, 0, -0.817823112, 0, 0.575467944),
                    CFrame.new(7245.43555, 168.611206, 3446.52979, -0.906296611, -0.0716997981, 0.416515887, 0, 0.985504985, 0.169646606, -0.422642082, 0.153750136, -0.893159807),
                    CFrame.new(7217.83936, 168.611206, 3472.27637, -0.965929747, 0, 0.258804798, 0, 1, 0, -0.258804798, 0, -0.965929747),
                    CFrame.new(7193.32373, 168.611206, 3443.95996, -1, 0, 0, 0, 0.998660624, 0.0517390631, 0, 0.0517390631, -0.998660624),
                    CFrame.new(7206.76709, 168.611206, 3409.25952, 0.431077063, 0, -0.902316272, 0, 1, 0, 0.902316093, 0, 0.431076825)
                },
                ["Orc Warrior"] = {
                    CFrame.new(7589.44531, 169.383606, 3630.72119, 0.203793406, -0.111560822, 0.972637296, 0, 0.993486226, 0.113952175, -0.979014397, -0.0232226904, 0.202465832),
                    CFrame.new(7607.38477, 169.383606, 3663.32373, 0.356556058, -0.149170384, 0.922288656, 0, 0.987171352, 0.159664467, -0.934274137, -0.0569293313, 0.351981938),
                    CFrame.new(7587.64551, 169.383606, 3685.69751, 0.983666778, 0.0239055771, -0.178407252, 0, 0.991141856, 0.132807478, 0.180001736, -0.130638301, 0.974953294),
                    CFrame.new(7553.97852, 169.383606, 3668.98755, 0.90629667, -0.0089421114, 0.42254746, 0, 0.999776125, 0.0211576466, -0.422642082, -0.0191751048, 0.906093776),
                    CFrame.new(7551.99561, 169.383606, 3631.29858, 0.612787783, 0.0873407871, -0.785406113, 0, 0.993873537, 0.110523321, 0.79024756, -0.0677273422, 0.609033585)
                },
                ["Kanghi"] = {
                    CFrame.new(7228.43506, 170.259598, 3733.33862, 0.819155693, 0, 0.573571265, 0, 1, 0, -0.573571265, 0, 0.819155693),
                    CFrame.new(7265.88574, 170.259598, 3732.75952, 0.642763317, -0.101732843, 0.759279847, 0, 0.991142929, 0.132799238, -0.766064942, -0.0853584781, 0.637070298),
                    CFrame.new(7283.82129, 170.259598, 3765.36597, -0.203886107, -0.118769281, 0.971764863, 0, 0.992613733, 0.121317431, -0.978995681, 0.0247349553, -0.202380285),
                    CFrame.new(7264.08643, 170.259598, 3787.73535, 0.999071062, 0.00511235837, -0.0427930579, 0, 0.992939293, 0.118623488, 0.0430973545, -0.118513294, 0.992016912),
                    CFrame.new(7230.42041, 170.259598, 3771.0271, 0.90629667, 0, 0.422642082, 0, 1, 0, -0.422642082, 0, 0.90629667)
                },
                ["Liodas"] = {
                    CFrame.new(7493.47412, 171.610886, 3351.06592, 0.60774219, -0.163326114, 0.777158022, 0, 0.978622377, 0.205665499, -0.794134736, -0.124991603, 0.594750106)
                },
                ["Nab"] = {
                    CFrame.new(7389.40869, 284.991913, 3792.24805, -0.204431683, 0, 0.978880942, 0, 1, 0, -0.978880942, 0, -0.204431653)
                },
                ["Ogre"] = {
                    CFrame.new(7770.3457, 172.329926, 3649.59937, -0.242385507, 0, 0.970181167, 0, 1, 0, -0.970181167, 0, -0.242385507)
                },
                ["Princess"] = {
                    CFrame.new(7757.38281, 249.820587, 3849.86377, -0.946342707, 0.0430864654, -0.320281208, -0.00604861882, 0.988537133, 0.150856927, 0.323109746, 0.144699618, -0.935234249),
                    CFrame.new(7794.33789, 249.838959, 3844.04248, -0.530075669, -0.109918721, 0.840795815, 0.0701655596, 0.982476294, 0.172676384, -0.845042348, 0.150526479, -0.513074338),
                    CFrame.new(7808.50684, 249.88237, 3870.34961, -0.133149043, -0.346939325, 0.928388119, 0.186287537, 0.911272109, 0.367260277, -0.97343123, 0.221847475, -0.0567045212),
                    CFrame.new(7781.21387, 249.879684, 3896.28931, 0.0478191525, -0.408378899, 0.911559045, 0.190977201, 0.899505258, 0.392960429, -0.980429053, 0.155295953, 0.121004678),
                    CFrame.new(7745.16016, 247.911209, 3885.24512, 0.6526739, 0, -0.757639945, 0, 1, 0, 0.757641673, 0, 0.65267235)
                },
                ["Scanone"] = {
                    CFrame.new(7702.55371, 170.448853, 3645.07959, -0.682898581, -0.0347817354, 0.72968936, 0, 0.998865902, 0.0476124361, -0.730517864, 0.0325144641, -0.682124078),
                    CFrame.new(7739.32227, 170.448853, 3639.37695, -0.826532245, 0.0135165155, -0.562731862, 0, 0.999711633, 0.0240125339, 0.562894166, 0.0198471341, -0.826293886),
                    CFrame.new(7753.59814, 170.448853, 3665.56348, 0.943083704, -0.0117453355, 0.332346708, 0, 0.999376118, 0.0353185609, -0.332554191, -0.0333083607, 0.942495346),
                    CFrame.new(7726.38281, 170.448853, 3691.49243, -0.0871315002, -0.12559551, 0.988247931, 0, 0.992020726, 0.126074985, -0.996196866, 0.0109851025, -0.0864362568),
                    CFrame.new(7690.29346, 170.448853, 3680.46606, 0.998757482, 0, 0.0498379171, 0, 1, 0, -0.0498379171, 0, 0.998757482)
                },
                ["Zeldos"] = {
                    CFrame.new(7789.13086, 249.661209, 3871.8396, 0.0145126078, 0, 0.999895394, 0, 1, 0, -0.999895394, 0, 0.0145126078)
                }
            }
        }

        local selectedMapName = "Mines"
        local selectedNPCName = "Orc"
        local autoFarmEnabled = false
        local autoFarmConnection = nil
        local currentSpawnIndex = 1

        -- Populate Map Dropdown
        for mapName in pairs(npcData) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -20, 0, 40)
            btn.BackgroundColor3 = SETTINGS.COLORS.Secondary
            btn.TextColor3 = SETTINGS.COLORS.Text
            btn.Text = mapName
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 16
            btn.Parent = mapListFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

            btn.MouseButton1Click:Connect(function()
                selectedMapName = mapName
                mapDropdown.Text = "Map: " .. mapName
                mapListFrame.Visible = false

                for _, child in npcListFrame:GetChildren() do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for npcName in pairs(npcData[mapName]) do
                    local npcBtn = Instance.new("TextButton")
                    npcBtn.Size = UDim2.new(1, -20, 0, 40)
                    npcBtn.BackgroundColor3 = SETTINGS.COLORS.Secondary
                    npcBtn.TextColor3 = SETTINGS.COLORS.Text
                    npcBtn.Text = npcName
                    npcBtn.Font = Enum.Font.Gotham
                    npcBtn.TextSize = 16
                    npcBtn.Parent = npcListFrame
                    Instance.new("UICorner", npcBtn).CornerRadius = UDim.new(0, 8)

                    npcBtn.MouseButton1Click:Connect(function()
                        selectedNPCName = npcName
                        npcDropdown.Text = "NPC: " .. npcName
                        npcListFrame.Visible = false
                        status.Text = "Ready — toggle Auto-Farm NPC"
                    end)
                end
            end)
        end

        mapDropdown.MouseButton1Click:Connect(function()
            mapListFrame.Visible = not mapListFrame.Visible
        end)

        npcDropdown.MouseButton1Click:Connect(function()
            npcListFrame.Visible = not npcListFrame.Visible
        end)

        local farmToggle = Instance.new("TextButton")
        farmToggle.Size = UDim2.new(0, 260, 0, 50)
        farmToggle.BackgroundColor3 = SETTINGS.COLORS.Info
        farmToggle.TextColor3 = Color3.new(1,1,1)
        farmToggle.Text = "Auto-Farm NPC: OFF"
        farmToggle.Font = Enum.Font.GothamBold
        farmToggle.TextSize = 18
        farmToggle.Parent = customArea
        Instance.new("UICorner", farmToggle).CornerRadius = UDim.new(0, 12)

        local function startFarming()
            local spawns = npcData[selectedMapName][selectedNPCName]
            if not spawns or #spawns == 0 then return end

            local firstCFrame = spawns[1]
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = firstCFrame * CFrame.new(0, 5, 0)
                status.Text = "Teleported to " .. selectedNPCName .. " (first spawn)"
            end

            currentSpawnIndex = 2

            local function walkToNext()
                if not autoFarmEnabled then return end
                if currentSpawnIndex > #spawns then currentSpawnIndex = 1 end

                local targetPos = spawns[currentSpawnIndex].Position
                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:MoveTo(targetPos)
                    status.Text = "Walking to " .. selectedNPCName
                end

                currentSpawnIndex = currentSpawnIndex + 1
                task.delay(5, walkToNext)
            end

            task.delay(3, walkToNext)
        end

        local function jumpSmoothly()
            local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.Jump = true
            end
        end

        farmToggle.MouseButton1Click:Connect(function()
            autoFarmEnabled = not autoFarmEnabled
            farmToggle.Text = "Auto-Farm NPC: " .. (autoFarmEnabled and "ON" or "OFF")
            farmToggle.BackgroundColor3 = autoFarmEnabled and SETTINGS.COLORS.Success or SETTINGS.COLORS.Info

            if autoFarmEnabled then
                status.Text = "Auto-Farm started — teleport to first, then walk"
                startFarming()

                autoFarmConnection = RunService.Heartbeat:Connect(function()
                    if not autoFarmEnabled then return end
                    task.wait(3)
                    jumpSmoothly()
                end)
            else
                if autoFarmConnection then
                    autoFarmConnection:Disconnect()
                    autoFarmConnection = nil
                end
                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if humanoid then humanoid:Move(Vector3.new(0,0,0)) end
                status.Text = "Auto-Farm stopped"
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
        txt.Text = "Hub with Egg Roll, Rebirth & Auto-Teleport\nPress RightShift to minimize/maximize.\nEnjoy!\nMade by Mitchanator"
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
        autoAura = false
        if rollThread then task.cancel(rollThread) rollThread = nil end
        if rankThread then task.cancel(rankThread) rankThread = nil end
        if auraThread then task.cancel(auraThread) auraThread = nil end
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
            Tabs[name].Build(content)
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

    local order = {"Home", "Egg Roll", "R&A", "Custom", "Credits"}

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
    local old = playerGui:FindFirstChild("HubKeyScreen", true)
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "HubKeyScreen"
    sg.ResetOnSpawn = false
    sg.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 280)
    frame.Position = UDim2.new(0.5, -200, 0.5, -140)
    frame.BackgroundColor3 = SETTINGS.COLORS.Background
    frame.BorderSizePixel = 0
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-24,0,44)
    lbl.Position = UDim2.new(0,12,0,16)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Enter License Key"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 28
    lbl.TextColor3 = SETTINGS.COLORS.Text
    lbl.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1,-40,0,50)
    box.Position = UDim2.new(0,20,0,74)
    box.BackgroundColor3 = SETTINGS.COLORS.Primary
    box.TextColor3 = SETTINGS.COLORS.Text
    box.PlaceholderText = "XXXX-XXXX-XXXX"
    box.Font = Enum.Font.Gotham
    box.TextSize = 20
    box.ClearTextOnFocus = false
    box.Parent = frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,10)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1,-40,0,70)
    status.Position = UDim2.new(0,20,0,132)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextWrapped = true
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Font = Enum.Font.Gotham
    status.TextSize = 16
    status.TextColor3 = SETTINGS.COLORS.Error
    status.Parent = frame

    local submit = Instance.new("TextButton")
    submit.Size = UDim2.new(1,-40,0,52)
    submit.Position = UDim2.new(0,20,0,210)
    submit.BackgroundColor3 = SETTINGS.COLORS.Accent
    submit.TextColor3 = Color3.new(1,1,1)
    submit.Text = "Validate & Unlock"
    submit.Font = Enum.Font.GothamBold
    submit.TextSize = 22
    submit.Parent = frame
    Instance.new("UICorner", submit).CornerRadius = UDim.new(0,10)

    local function fetchKeyDB()
        local methods = {
            function() return game:HttpGet(SETTINGS.KEY_DB_URL, true) end,
            function() if syn and syn.request then return syn.request({Url = SETTINGS.KEY_DB_URL, Method = "GET"}).Body end end,
            function() if http and http.request then return http.request({Url = SETTINGS.KEY_DB_URL, Method = "GET"}).Body end end,
            function() if request then return request({Url = SETTINGS.KEY_DB_URL, Method = "GET"}).Body end end,
        }

        for i, meth in ipairs(methods) do
            local s, r = pcall(meth)
            if s and typeof(r) == "string" and #r > 5 then
                return r
            end
        end
        return nil
    end

    submit.MouseButton1Click:Connect(function()
        local input = box.Text:match("^%s*(.-)%s*$")
        if input == "" then
            status.Text = "Please enter a key."
            status.TextColor3 = SETTINGS.COLORS.Error
            return
        end

        status.Text = "Checking license..."
        status.TextColor3 = SETTINGS.COLORS.TextDim

        local raw = fetchKeyDB()
        if not raw then
            status.Text = "Cannot reach key database.\nHTTP may be blocked."
            status.TextColor3 = SETTINGS.COLORS.Error
            return
        end

        local s, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not s or type(data) ~= "table" then
            status.Text = "Key database format invalid."
            status.TextColor3 = SETTINGS.COLORS.Error
            return
        end

        local entry = nil
        for _, e in ipairs(data) do
            if e.key == input then
                entry = e
                break
            end
        end

        if not entry then
            status.Text = "Invalid key - not found."
            status.TextColor3 = SETTINGS.COLORS.Error
            return
        end

        local expire = entry.expires
        if not expire or expire == "" then
            status.Text = "Valid (no expiration)."
            status.TextColor3 = SETTINGS.COLORS.Success
            task.wait(1.2)
            sg:Destroy()
            createHubUI()
            return
        end

        local ey, em, ed = expire:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
        if not (ey and em and ed) then
            status.Text = "Invalid expiration date format."
            return
        end

        local expireDays = tonumber(ey) * 365 + tonumber(em) * 31 + tonumber(ed)
        local now = os.date("!*t")
        local todayDays = now.year * 365 + now.month * 31 + now.day

        if todayDays > expireDays then
            status.Text = "This key has expired."
            status.TextColor3 = SETTINGS.COLORS.Error
            return
        end

        local remaining = expireDays - todayDays
        status.Text = "Valid! ≈" .. remaining .. " days left"
        status.TextColor3 = SETTINGS.COLORS.Success
        task.wait(1.5)
        sg:Destroy()
        createHubUI()
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == MINIMIZE_KEY then
        if hubGui then
            hubGui.Enabled = not hubGui.Enabled
        end
    end
end)

-- Start with key screen
showKeyScreen()

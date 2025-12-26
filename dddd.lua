--========================
-- SERVICES
--========================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--========================
-- CONFIGURATION & STATE
--========================
local Config = {
    ColorPrimary = Color3.fromRGB(140, 0, 255), -- Electric Purple
    ColorDark = Color3.fromRGB(15, 5, 25),      -- Deep Violet
    ColorText = Color3.fromRGB(255, 255, 255),
    Smoothness = 0.15                           -- High Precision (Lower = Snappier)
}

local State = {
    AimbotPlayers = false,
    AimbotNPCs = false,
    WallCheck = true,
    ESP_Players = false,
    ESP_NPCs = false,
    Speed = 16,
    Jump = 50
}

local entityData = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Config.ColorPrimary
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.NumSides = 64
FOVCircle.Visible = false

--========================
-- PREMIUM UI BUILDER
--========================
local function createUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "PurpleHubPro_Premium"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = game.CoreGui

    -- Main Container
    local Main = Instance.new("Frame")
    Main.Name = "MainFrame"
    Main.Size = UDim2.new(0, 550, 0, 400)
    Main.Position = UDim2.new(0.5, -275, 0.5, -200)
    Main.BackgroundColor3 = Config.ColorDark
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
    
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Config.ColorPrimary
    Stroke.Thickness = 2
    Stroke.Transparency = 0.5

    -- Dragging Logic
    local dragging, dragInput, dragStart, startPos
    Main.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function() if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
        end
    end)
    Main.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Title Bar
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 50)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 10, 40)
    TitleBar.ZIndex = 2
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 16)
    
    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "💎 PURPLE HUB PREMIUM"
    Title.TextColor3 = Config.ColorText
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 2

    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0, 10)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 80)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.ZIndex = 2
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
    CloseBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- Side Navigation (Tabs)
    local TabHolder = Instance.new("Frame", Main)
    TabHolder.Size = UDim2.new(0, 130, 1, -50)
    TabHolder.Position = UDim2.new(0, 0, 0, 50)
    TabHolder.BackgroundColor3 = Color3.fromRGB(20, 10, 35)
    TabHolder.BorderSizePixel = 0
    TabHolder.ZIndex = 2
    Instance.new("UICorner", TabHolder).CornerRadius = UDim.new(0, 8)

    local ContentFrame = Instance.new("Frame", Main)
    ContentFrame.Size = UDim2.new(1, -130, 1, -50)
    ContentFrame.Position = UDim2.new(0, 130, 0, 50)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ZIndex = 2

    -- Content Pages
    local Pages = {}

    local function createPage(name)
        local page = Instance.new("ScrollingFrame", ContentFrame)
        page.Size = UDim2.new(1, -10, 1, -10)
        page.Position = UDim2.new(0, 5, 0, 5)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = Config.ColorPrimary
        page.Visible = false
        page.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto-expand
        page.ZIndex = 2
        Pages[name] = page
        return page
    end

    local PageAimbot = createPage("Aimbot")
    local PageESP = createPage("ESP")
    local PageMovement = createPage("Movement")
    local PageVisuals = createPage("Visuals")

    -- Create Tabs
    local TabButtons = {}
    local function createTabBtn(text, pageName)
        local btn = Instance.new("TextButton", TabHolder)
        btn.Size = UDim2.new(1, -10, 0, 40)
        btn.Position = UDim2.new(0, 5, 0, #TabButtons * 45 + 10)
        btn.BackgroundColor3 = Color3.fromRGB(30, 15, 50)
        btn.Text = text
        btn.TextColor3 = Config.ColorText
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.AutoButtonColor = false
        btn.ZIndex = 2
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            -- Reset all tabs
            for _, b in pairs(TabButtons) do
                b.BackgroundColor3 = Color3.fromRGB(30, 15, 50)
                b.TextColor3 = Color3.fromRGB(200,200,200)
            end
            for _, p in pairs(Pages) do p.Visible = false end

            -- Activate selected
            btn.BackgroundColor3 = Config.ColorPrimary
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            Pages[pageName].Visible = true
        end)

        table.insert(TabButtons, btn)
        return btn
    end

    createTabBtn("🎯 Aimbot", "Aimbot")
    createTabBtn("👁️ ESP", "ESP")
    createTabBtn("🏃 Movement", "Movement")
    createTabBtn("💎 Visuals", "Visuals")

    -- UI ELEMENT FACTORIES

    -- 1. Animated Toggle
    local function createToggle(parent, text, yPos, stateKey)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 35)
        container.Position = UDim2.new(0, 0, 0, yPos)
        container.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(0, 200, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Config.ColorText
        label.TextSize = 16
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(0, 40, 0, 20)
        btn.Position = UDim2.new(1, -40, 0.5, -10)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", btn)
        knob.Size = UDim2.new(0, 16, 1, -2)
        knob.Position = UDim2.new(0, 2, 0, 1)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        -- Update function
        local function updateVisuals()
            if State[stateKey] then
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Config.ColorPrimary}):Play()
                TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0, 1)}):Play()
            else
                TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
                TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0, 1)}):Play()
            end
        end

        btn.MouseButton1Click:Connect(function()
            State[stateKey] = not State[stateKey]
            updateVisuals()
        end)

        -- Init state
        updateVisuals()
        
        -- Adjust Canvas
        parent.CanvasSize = UDim2.new(0, 0, 0, yPos + 40)
    end

    -- 2. Slider Line (0-100)
    local function createSlider(parent, text, yPos, stateKey, minVal, maxVal)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 50)
        container.Position = UDim2.new(0, 0, 0, yPos)
        container.BackgroundTransparency = 1

        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. State[stateKey]
        label.TextColor3 = Config.ColorText
        label.Font = Enum.Font.Gotham
        label.TextSize = 15
        label.TextXAlignment = Enum.TextXAlignment.Left

        local sliderBar = Instance.new("Frame", container)
        sliderBar.Size = UDim2.new(1, -20, 0, 4)
        sliderBar.Position = UDim2.new(0, 10, 0, 30)
        sliderBar.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
        Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(1, 0)

        local sliderFill = Instance.new("Frame", sliderBar)
        sliderFill.Size = UDim2.new(0, 0, 1, 0)
        sliderFill.BackgroundColor3 = Config.ColorPrimary
        Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

        local sliderBtn = Instance.new("TextButton", container)
        sliderBtn.Size = UDim2.new(1, 0, 0, 40)
        sliderBtn.Position = UDim2.new(0, 0, 0, 10)
        sliderBtn.BackgroundTransparency = 1
        sliderBtn.Text = ""
        sliderBtn.ZIndex = 10

        local isDragging = false

        local function updateValue(input)
            local size = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            local value = math.floor(minVal + (maxVal - minVal) * size)
            
            State[stateKey] = value
            sliderFill.Size = UDim2.new(size, 0, 1, 0)
            label.Text = text .. ": " .. value

            -- Apply movement immediately if character exists
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                if stateKey == "Speed" then hum.WalkSpeed = value
                elseif stateKey == "Jump" then hum.JumpPower = value end
            end
        end

        sliderBtn.MouseButton1Down:Connect(function() isDragging = true end)
        sliderBtn.MouseButton1Up:Connect(function() isDragging = false end)
        
        sliderBtn.MouseEnter:Connect(function()
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then isDragging = true end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateValue(input)
            end
        end)

        -- Init Fill
        local initialPct = (State[stateKey] - minVal) / (maxVal - minVal)
        sliderFill.Size = UDim2.new(initialPct, 0, 1, 0)

        parent.CanvasSize = UDim2.new(0, 0, 0, yPos + 55)
    end

    -- POPULATE TABS
    -- Aimbot Tab
    createToggle(PageAimbot, "Player Aimbot", 0, "AimbotPlayers")
    createToggle(PageAimbot, "NPC Aimbot", 50, "AimbotNPCs")
    createToggle(PageAimbot, "Wall Check", 100, "WallCheck")
    
    -- ESP Tab
    createToggle(PageESP, "Player ESP", 0, "ESP_Players")
    createToggle(PageESP, "NPC ESP", 50, "ESP_NPCs")

    -- Movement Tab
    createSlider(PageMovement, "Walk Speed", 0, "Speed", 0, 100)
    createSlider(PageMovement, "Jump Power", 70, "Jump", 0, 100)

    -- Visuals Tab (Placeholder for Crosshair)
    createToggle(PageVisuals, "FOV Circle", 0, "FOVCircle") -- Note: logic below uses Aimbot state for FOV, but lets add a dedicated toggle

    -- Set Default Tab
    TabButtons[1].MouseButton1Click:Fire()

    -- Intro Animation
    Main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 550, 0, 400)}):Play()

    return gui
end

local Gui = createUI()

--========================
-- ENTITY & SCAN LOGIC
--========================
local function isNPC(model)
    return model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(model)
end

local function cleanup(model)
    if entityData[model] then
        local d = entityData[model]
        if d.Line then d.Line:Remove() end
        if d.Highlight then d.Highlight:Destroy() end
        if d.Billboard then d.Billboard:Destroy() end
        entityData[model] = nil
    end
end

local function addESP(model, typeStr)
    if entityData[model] or model == LocalPlayer.Character then return end
    
    local color = typeStr == "Player" and Color3.fromRGB(0, 255, 100) or Config.ColorPrimary

    local h = Instance.new("Highlight", model)
    h.FillColor = color
    h.FillTransparency = 0.5
    h.OutlineColor = color
    h.OutlineTransparency = 0
    h.Enabled = false

    local head = model:FindFirstChild("Head")
    if head then
        local bill = Instance.new("BillboardGui", head)
        bill.Size = UDim2.new(0, 100, 0, 50)
        bill.StudsOffset = Vector3.new(0, 2.5, 0)
        bill.AlwaysOnTop = true

        local txt = Instance.new("TextLabel", bill)
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = model.Name
        txt.TextColor3 = color
        txt.TextStrokeTransparency = 0.5
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 13

        local line = Drawing.new("Line")
        line.Color = color
        line.Thickness = 1.5
        line.Visible = false

        entityData[model] = {
            Type = typeStr,
            Highlight = h,
            Billboard = bill,
            Line = line
        }

        if model:FindFirstChild("Humanoid") then
            model.Humanoid.Died:Connect(function() cleanup(model) end)
        end
    end
end

-- Initialization
for _, v in pairs(workspace:GetChildren()) do if isNPC(v) then addESP(v, "NPC") end end
workspace.ChildAdded:Connect(function(c) if isNPC(c) then addESP(c, "NPC") end end)
workspace.ChildRemoved:Connect(cleanup)

local function setupPlayer(p)
    if p == LocalPlayer then return end
    if p.Character then addESP(p.Character, "Player") end
    p.CharacterAdded:Connect(function(c) addESP(c, "Player") end)
end
for _, p in pairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)

--========================
-- MAIN LOOP
--========================
RunService.RenderStepped:Connect(function()
    -- FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Radius = 160
    FOVCircle.Visible = State.AimbotPlayers or State.AimbotNPCs

    local bestTarget, bestDist

    for model, data in pairs(entityData) do
        if model.Parent and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 then
            local head = model:FindFirstChild("Head")
            if head then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)

                -- ESP Logic
                local espActive = false
                if data.Type == "NPC" and State.ESP_NPCs then espActive = true
                elseif data.Type == "Player" and State.ESP_Players then espActive = true end

                data.Highlight.Enabled = espActive
                data.Billboard.Enabled = espActive
                data.Line.Visible = espActive and onScreen
                if espActive and onScreen then
                    data.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    data.Line.To = Vector2.new(pos.X, pos.Y)
                end

                -- Aimbot Logic (Head Lock)
                if onScreen then
                    local aimActive = false
                    if data.Type == "NPC" and State.AimbotNPCs then aimActive = true
                    elseif data.Type == "Player" and State.AimbotPlayers then aimActive = true end

                    if aimActive then
                        -- Wall Check
                        local isBlocked = false
                        if State.WallCheck then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            local result = workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, rayParams)
                            if result and (not result.Instance:IsDescendantOf(model)) then isBlocked = true end
                        end

                        if not isBlocked then
                            local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                            if dist <= 160 and (not bestDist or dist < bestDist) then
                                bestDist = dist
                                bestTarget = head
                            end
                        end
                    end
                end
            end
        else
            cleanup(model)
        end
    end

    if bestTarget then
        local cFrame = CFrame.new(Camera.CFrame.Position, bestTarget.Position)
        Camera.CFrame = Camera.CFrame:Lerp(cFrame, Config.Smoothness)
    end
end)

local players = game:GetService("Players")
local localPlayer = players.LocalPlayer
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

local ESP_Enabled = true
local ESP_Range = 999999
local ESP_RangeOptions = { 500, 1000, 999999 }
local ESP_RangeIndex = 2
local ESP_Objects = {}
local ESP_Names = {}

-- 🔹 สร้าง GUI Popup
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local popupLabel = Instance.new("TextLabel")
popupLabel.Parent = screenGui
popupLabel.Size = UDim2.new(0, 200, 0, 50)
popupLabel.Position = UDim2.new(0.5, -100, 0.1, 0)
popupLabel.BackgroundTransparency = 0.5
popupLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
popupLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
popupLabel.TextSize = 20
popupLabel.Font = Enum.Font.SourceSansBold
popupLabel.Visible = false

-- 🔹 ฟังก์ชันแสดง Popup แจ้งเตือน
local function showPopup(text, color)
    popupLabel.Text = text
    popupLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    popupLabel.Visible = true
    task.delay(0.5, function()
        popupLabel.Visible = false
    end)
end

-- 🔹 ฟังก์ชันเพิ่ม ESP ให้ผู้เล่น
local function addESP(player)
    if player == localPlayer or ESP_Objects[player] then
        return
    end

    local function createESP()
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end

        -- 🔹 สร้าง Highlight ESP
        local highlight = Instance.new("Highlight")
        highlight.Parent = character
        highlight.OutlineTransparency = 1
        highlight.FillTransparency = 0.1
        ESP_Objects[player] = highlight

        -- 🔹 สร้าง BillboardGui สำหรับชื่อและระยะทาง
        local billboard = Instance.new("BillboardGui")
        billboard.Parent = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = billboard
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextSize = 10
        ESP_Names[player] = billboard

        -- 🔥 อัปเดต ESP ทุก 0.1 วินาที
        task.spawn(function()
            while character and character:FindFirstChild("HumanoidRootPart") and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") do
                local distance = (character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude

                if ESP_Enabled and distance <= ESP_Range then
                    -- ✅ กำหนดสีตามทีม Citizens / Outlaws
                    if player.Team and player.Team.Name == "Citizens" then
                        highlight.FillColor = Color3.fromRGB(0, 255, 0) -- เขียว
                    elseif player.Team and player.Team.Name == "Outlaws" then
                        highlight.FillColor = Color3.fromRGB(255, 0, 0) -- แดง
                    else
                        highlight.FillColor = Color3.fromRGB(255, 255, 255) -- ขาว (ถ้าไม่มีทีม)
                    end

                    highlight.Enabled = true
                    nameLabel.Text = player.Name .. " [" .. math.floor(distance) .. " Studs]"
                    billboard.Enabled = true
                else
                    highlight.Enabled = false
                    billboard.Enabled = false
                end

                task.wait(0.1)
            end
        end)
    end

    createESP()
    player.CharacterAdded:Connect(createESP)
end

-- 🔹 กดปุ่ม N เพื่อเปิด-ปิด ESP
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.N then
        ESP_Enabled = not ESP_Enabled
        showPopup("ESP: " .. (ESP_Enabled and "ON" or "OFF"), ESP_Enabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0))

        for player, highlight in pairs(ESP_Objects) do
            if highlight then
                highlight.Enabled = ESP_Enabled
            end
            if ESP_Names[player] then
                ESP_Names[player].Enabled = ESP_Enabled
            end
        end
    end
end)

-- 🔹 กด Right Ctrl เพื่อเปลี่ยนระยะ ESP
userInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        ESP_RangeIndex = (ESP_RangeIndex % #ESP_RangeOptions) + 1
        ESP_Range = ESP_RangeOptions[ESP_RangeIndex]
        showPopup("ESP Range: " .. ESP_Range .. " Studs", Color3.fromRGB(255, 255, 0))
    end
end)

-- 🔹 อัปเดต ESP สำหรับผู้เล่นใหม่
players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        addESP(player)
    end)
end)

-- 🔹 อัปเดต ESP สำหรับผู้เล่นที่อยู่แล้ว
for _, player in pairs(players:GetPlayers()) do
    if player.Character then
        addESP(player)
    end
end

-- 🔄 รีเฟรช ESP ทุก 1 วินาที (แก้ปัญหาผู้เล่นบางคนไม่ Highlight)
task.spawn(function()
    while true do
        task.wait(1)
        for _, player in pairs(players:GetPlayers()) do
            if player ~= localPlayer and player.Character and not ESP_Objects[player] then
                addESP(player)
            end
        end
    end
end)

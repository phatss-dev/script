repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local lp                = Players.LocalPlayer

-- ============================================================
-- CẤU HÌNH
-- ============================================================
local CHECK_DELAY = 3 -- Thời gian cập nhật lại (giây)

-- ============================================================
-- NẠP MODULE INVENTORY (AN TOÀN VỚI PCALL)
-- ============================================================
local ItemReplicationService, KEYS, ItemConfig

pcall(function()
    local serviceModule = ReplicatedStorage:FindFirstChild("ItemReplicationService")
    if serviceModule then
        ItemReplicationService = require(serviceModule)
        local keysModule = serviceModule:FindFirstChild("KEYS")
        if keysModule then
            KEYS = require(keysModule)
        end
    end
end)

pcall(function()
    local configModule = ReplicatedStorage:FindFirstChild("ItemConfig")
    if configModule then
        ItemConfig = require(configModule)
    end
end)

-- ============================================================
-- XỬ LÝ TÊN ITEM & ĐỌC SỐ LƯỢNG
-- ============================================================
local function getCleanName(itemId)
    if not ItemConfig then return nil end
    local ok, result = pcall(function()
        local matched = ItemConfig.match(itemId)
        if not matched then return nil end

        local itemData = matched:unwrap()
        if not (itemData and itemData.Index and itemData.Index.DebugLabel) then
            return nil
        end

        local fullName = tostring(itemData.Index.DebugLabel)
        local cleanName = fullName:match("^(.-)%s*%[")
        if cleanName and cleanName ~= "" then
            return cleanName
        end
        return fullName
    end)

    return ok and result or nil
end

local function checkTargetItems()
    local dragonEggCount = 0
    local dinoBoneCount  = 0
    local readSuccess    = false

    -- Cách 1: Đọc qua ItemReplicationService (hệ thống inventory mới)
    if ItemReplicationService and KEYS and ItemConfig then
        local ok, quantityItems = pcall(function()
            return ItemReplicationService:GetItems(KEYS.QUANTITY)
        end)

        if ok and type(quantityItems) == "table" then
            readSuccess = true
            for _, item in pairs(quantityItems) do
                local itemId = item and item.ItemId
                local amount = tonumber(item and item.Value) or 0

                if itemId and amount > 0 then
                    local name = getCleanName(itemId)
                    if name then
                        local lowerName = name:lower()
                        if lowerName:find("dragon egg") then
                            dragonEggCount = dragonEggCount + amount
                        elseif lowerName:find("dinosaur bone") then
                            dinoBoneCount = dinoBoneCount + amount
                        end
                    end
                end
            end
        end
    end

    -- Cách 2: Dự phòng qua Remote CommF_ ("getInventory")
    if not readSuccess or (dragonEggCount == 0 and dinoBoneCount == 0) then
        local okInv, inv = pcall(function()
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
        end)

        if okInv and type(inv) == "table" then
            local remoteEgg  = 0
            local remoteBone = 0

            for _, item in pairs(inv) do
                if type(item) == "table" and item.Name then
                    local lowerName = tostring(item.Name):lower()
                    local count = tonumber(item.Count) or 1

                    if lowerName:find("dragon egg") then
                        remoteEgg = remoteEgg + count
                    elseif lowerName:find("dinosaur bone") then
                        remoteBone = remoteBone + count
                    end
                end
            end

            if remoteEgg > dragonEggCount then dragonEggCount = remoteEgg end
            if remoteBone > dinoBoneCount then dinoBoneCount = remoteBone end
        end
    end

    return dragonEggCount, dinoBoneCount
end

-- Export hàm ra global để script khác có thể gọi nếu cần
getgenv().CheckDragonItems = checkTargetItems

-- ============================================================
-- GIAO DIỆN HIỂN THỊ MINI (UI TRACKER)
-- ============================================================
local guiParent = CoreGui
pcall(function()
    if not CoreGui:FindFirstChild("RobloxGui") then
        guiParent = lp:WaitForChild("PlayerGui")
    end
end)

pcall(function()
    local old = guiParent:FindFirstChild("DragonItemCheckerUI")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DragonItemCheckerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 230, 0, 88)
Frame.Position = UDim2.new(0, 20, 0.4, 0)
Frame.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
Frame.BackgroundTransparency = 0.12
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(139, 92, 246)
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -16, 0, 24)
Title.Position = UDim2.new(0, 10, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "INVENTORY CHECKER"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local EggLabel = Instance.new("TextLabel")
EggLabel.Size = UDim2.new(1, -16, 0, 22)
EggLabel.Position = UDim2.new(0, 10, 0, 32)
EggLabel.BackgroundTransparency = 1
EggLabel.Text = "Dragon Egg: ..."
EggLabel.Font = Enum.Font.GothamSemibold
EggLabel.TextSize = 13
EggLabel.TextColor3 = Color3.fromRGB(245, 180, 60)
EggLabel.TextXAlignment = Enum.TextXAlignment.Left
EggLabel.Parent = Frame

local BoneLabel = Instance.new("TextLabel")
BoneLabel.Size = UDim2.new(1, -16, 0, 22)
BoneLabel.Position = UDim2.new(0, 10, 0, 56)
BoneLabel.BackgroundTransparency = 1
BoneLabel.Text = "Dinosaur Bones: ..."
BoneLabel.Font = Enum.Font.GothamSemibold
BoneLabel.TextSize = 13
BoneLabel.TextColor3 = Color3.fromRGB(180, 230, 160)
BoneLabel.TextXAlignment = Enum.TextXAlignment.Left
BoneLabel.Parent = Frame

-- ============================================================
-- VÒNG LẶP CẬP NHẬT
-- ============================================================
task.spawn(function()
    local lastEgg, lastBone = -1, -1

    while ScreenGui.Parent do
        local eggs, bones = checkTargetItems()

        EggLabel.Text  = "Dragon Egg: " .. tostring(eggs)
        BoneLabel.Text = "Dinosaur Bones: " .. tostring(bones)

        -- Chỉ in log khi số lượng có thay đổi để tránh spam console
        if eggs ~= lastEgg or bones ~= lastBone then
            print(string.format("[ITEM CHECK] %s | Dragon Egg: %d | Dinosaur Bones: %d", lp.Name, eggs, bones))
            lastEgg, lastBone = eggs, bones
        end

        task.wait(CHECK_DELAY)
    end
end)

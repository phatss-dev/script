repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local lp                = Players.LocalPlayer

-- ============================================================
-- CẤU HÌNH
-- ============================================================
local CHECK_DELAY = 3 -- Thời gian cập nhật (giây)

-- ============================================================
-- GIAO DIỆN HIỂN THỊ MINI (TẠO TRƯỚC ĐỂ HIỆN TRẠNG THÁI NGAY)
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
Frame.Size = UDim2.new(0, 240, 0, 108)
Frame.Position = UDim2.new(0, 20, 0.35, 0)
Frame.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
Frame.BackgroundTransparency = 0.1
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(139, 92, 246)
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -16, 0, 22)
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
EggLabel.Position = UDim2.new(0, 10, 0, 30)
EggLabel.BackgroundTransparency = 1
EggLabel.Text = "Dragon Egg: ..."
EggLabel.Font = Enum.Font.GothamSemibold
EggLabel.TextSize = 13
EggLabel.TextColor3 = Color3.fromRGB(245, 180, 60)
EggLabel.TextXAlignment = Enum.TextXAlignment.Left
EggLabel.Parent = Frame

local BoneLabel = Instance.new("TextLabel")
BoneLabel.Size = UDim2.new(1, -16, 0, 22)
BoneLabel.Position = UDim2.new(0, 10, 0, 54)
BoneLabel.BackgroundTransparency = 1
BoneLabel.Text = "Dinosaur Bones: ..."
BoneLabel.Font = Enum.Font.GothamSemibold
BoneLabel.TextSize = 13
BoneLabel.TextColor3 = Color3.fromRGB(180, 230, 160)
BoneLabel.TextXAlignment = Enum.TextXAlignment.Left
BoneLabel.Parent = Frame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 18)
StatusLabel.Position = UDim2.new(0, 10, 0, 82)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Đang nạp module..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 190)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = Frame

-- ============================================================
-- NẠP MODULE INVENTORY (DÙNG WAITFORCHILD CHUẨN)
-- ============================================================
local ItemReplicationService, KEYS, ItemConfig
local irsError = nil

local okReq, errReq = pcall(function()
    local serviceMod = ReplicatedStorage:WaitForChild("ItemReplicationService", 10)
    if not serviceMod then error("Khong thay ItemReplicationService") end

    ItemReplicationService = require(serviceMod)
    KEYS = require(serviceMod:WaitForChild("KEYS", 10))
    ItemConfig = require(ReplicatedStorage:WaitForChild("ItemConfig", 10))
end)

if not okReq then
    irsError = tostring(errReq)
    StatusLabel.Text = "IRS loi -> dung Remote"
else
    -- Chờ inventory khởi tạo xong (tối đa 10s)
    StatusLabel.Text = "Cho inventory khoi tao..."
    local t0 = os.clock()
    repeat
        local ready = false
        pcall(function()
            if ItemReplicationService.IsInitialized == true then
                ready = true
            else
                local items = ItemReplicationService:GetItems(KEYS.QUANTITY)
                if items ~= nil then ready = true end
            end
        end)
        if ready then break end
        task.wait(0.5)
    until os.clock() - t0 >= 10
end

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

local function isDragonEgg(name)
    local s = tostring(name or ""):lower()
    return s:find("dragon egg", 1, true) ~= nil or s:find("dragonegg", 1, true) ~= nil
end

local function isDinoBone(name)
    local s = tostring(name or ""):lower()
    return s:find("dinosaur bone", 1, true) ~= nil or s:find("dino bone", 1, true) ~= nil or s:find("dinobone", 1, true) ~= nil
end

local function checkTargetItems()
    local eggCount  = 0
    local boneCount = 0
    local source    = "None"

    -- Cách 1: Đọc qua ItemReplicationService
    if ItemReplicationService and KEYS and ItemConfig then
        local ok, quantityItems = pcall(function()
            return ItemReplicationService:GetItems(KEYS.QUANTITY)
        end)

        if ok and type(quantityItems) == "table" then
            source = "IRS"
            for _, item in pairs(quantityItems) do
                local itemId = item and item.ItemId
                local amount = tonumber(item and item.Value) or 0

                if itemId and amount > 0 then
                    local name = getCleanName(itemId)
                    if name then
                        if isDragonEgg(name) then
                            eggCount = eggCount + amount
                        elseif isDinoBone(name) then
                            boneCount = boneCount + amount
                        end
                    end
                end
            end
        end
    end

    -- Cách 2: Dự phòng qua Remote CommF_ ("getInventory")
    if source == "None" or (eggCount == 0 and boneCount == 0) then
        local okInv, inv = pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local commF = remotes and remotes:FindFirstChild("CommF_")
            if not commF then return nil end
            return commF:InvokeServer("getInventory")
        end)

        if okInv and type(inv) == "table" then
            local rEgg, rBone = 0, 0
            for _, item in pairs(inv) do
                if type(item) == "table" then
                    local name = item.Name or item.RawName or item.StorageKey
                    local count = tonumber(item.Count) or 1
                    if name then
                        if isDragonEgg(name) then
                            rEgg = rEgg + count
                        elseif isDinoBone(name) then
                            rBone = rBone + count
                        end
                    end
                end
            end

            if rEgg > eggCount then eggCount = rEgg end
            if rBone > boneCount then boneCount = rBone end
            source = (source == "IRS") and "IRS+Remote" or "Remote"
        end
    end

    return eggCount, boneCount, source
end

getgenv().CheckDragonItems = checkTargetItems

-- ============================================================
-- VÒNG LẶP CẬP NHẬT
-- ============================================================
task.spawn(function()
    while ScreenGui.Parent do
        local eggs, bones, src = checkTargetItems()

        EggLabel.Text    = "Dragon Egg: " .. tostring(eggs)
        BoneLabel.Text   = "Dinosaur Bones: " .. tostring(bones)
        StatusLabel.Text = "OK (" .. src .. ") | " .. os.date("%H:%M:%S")

        task.wait(CHECK_DELAY)
    end
end)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local lp                = Players.LocalPlayer

local CHECK_DELAY = 3

-- ============================================================
-- TẠO UI HIỂN THỊ NGAY LẬP TỨC
-- ============================================================
local guiParent = CoreGui
pcall(function()
    if not CoreGui:FindFirstChild("RobloxGui") then
        guiParent = lp.PlayerGui
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
Frame.Size = UDim2.new(0, 250, 0, 112)
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
Title.Text = "INVENTORY CHECKER v3"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local EggLabel = Instance.new("TextLabel")
EggLabel.Size = UDim2.new(1, -16, 0, 22)
EggLabel.Position = UDim2.new(0, 10, 0, 30)
EggLabel.BackgroundTransparency = 1
EggLabel.Text = "Dragon Egg: 0"
EggLabel.Font = Enum.Font.GothamSemibold
EggLabel.TextSize = 13
EggLabel.TextColor3 = Color3.fromRGB(245, 180, 60)
EggLabel.TextXAlignment = Enum.TextXAlignment.Left
EggLabel.Parent = Frame

local BoneLabel = Instance.new("TextLabel")
BoneLabel.Size = UDim2.new(1, -16, 0, 22)
BoneLabel.Position = UDim2.new(0, 10, 0, 54)
BoneLabel.BackgroundTransparency = 1
BoneLabel.Text = "Dinosaur Bones: 0"
BoneLabel.Font = Enum.Font.GothamSemibold
BoneLabel.TextSize = 13
BoneLabel.TextColor3 = Color3.fromRGB(180, 230, 160)
BoneLabel.TextXAlignment = Enum.TextXAlignment.Left
BoneLabel.Parent = Frame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 84)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Dang quet..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = Frame

-- ============================================================
-- NHẬN DIỆN TÊN ITEM
-- ============================================================
local function isDragonEgg(name)
    local s = tostring(name or ""):lower()
    return s:find("dragon egg", 1, true) ~= nil or s:find("dragonegg", 1, true) ~= nil
end

local function isDinoBone(name)
    local s = tostring(name or ""):lower()
    return s:find("dinosaur bone", 1, true) ~= nil or s:find("dino bone", 1, true) ~= nil or s:find("dinobone", 1, true) ~= nil
end

-- ============================================================
-- NGUỒN 1: ITEM REPLICATION SERVICE
-- ============================================================
local ItemReplicationService, KEYS, ItemConfig

local function initIRS()
    if ItemReplicationService and KEYS and ItemConfig then return true end
    local ok = pcall(function()
        local serviceMod = ReplicatedStorage:FindFirstChild("ItemReplicationService")
        local configMod  = ReplicatedStorage:FindFirstChild("ItemConfig")
        if serviceMod and configMod then
            ItemReplicationService = require(serviceMod)
            KEYS = require(serviceMod:FindFirstChild("KEYS"))
            ItemConfig = require(configMod)
        end
    end)
    return ok and ItemReplicationService ~= nil and KEYS ~= nil and ItemConfig ~= nil
end

local function getCleanName(itemId)
    local ok, res = pcall(function()
        local matched = ItemConfig.match(itemId)
        if not matched then return nil end
        local data = matched:unwrap()
        if not (data and data.Index and data.Index.DebugLabel) then return nil end
        local full = tostring(data.Index.DebugLabel)
        return full:match("^(.-)%s*%[") or full
    end)
    return ok and res or nil
end

local function readFromIRS()
    if not initIRS() then return false, 0, 0 end
    local ok, items = pcall(function()
        return ItemReplicationService:GetItems(KEYS.QUANTITY)
    end)
    if not ok or type(items) ~= "table" then return false, 0, 0 end

    local eggs, bones = 0, 0
    for _, item in pairs(items) do
        local id = item and item.ItemId
        local amt = tonumber(item and item.Value) or 0
        if id and amt > 0 then
            local name = getCleanName(id)
            if name then
                if isDragonEgg(name) then
                    eggs = eggs + amt
                elseif isDinoBone(name) then
                    bones = bones + amt
                end
            end
        end
    end
    return true, eggs, bones
end

-- ============================================================
-- NGUỒN 2: REMOTE COMMF_ (CÓ TIMEOUT 3s CHỐNG TREO)
-- ============================================================
local function readFromRemoteWithTimeout(timeoutSec)
    local finished = false
    local invResult = nil

    task.spawn(function()
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local commF = remotes and remotes:FindFirstChild("CommF_")
            if commF then
                invResult = commF:InvokeServer("getInventory")
            end
        end)
        finished = true
    end)

    local t0 = os.clock()
    while not finished and (os.clock() - t0) < (timeoutSec or 3) do
        task.wait(0.1)
    end

    if not finished or type(invResult) ~= "table" then
        return false, 0, 0
    end

    local eggs, bones = 0, 0
    for _, item in pairs(invResult) do
        if type(item) == "table" then
            local name = item.Name or item.RawName or item.StorageKey
            local count = tonumber(item.Count) or 1
            if name then
                if isDragonEgg(name) then
                    eggs = eggs + count
                elseif isDinoBone(name) then
                    bones = bones + count
                end
            end
        end
    end
    return true, eggs, bones
end

-- ============================================================
-- QUÉT NGAY & LẶP CẬP NHẬT
-- ============================================================
local function updateOnce()
    local eggs, bones = 0, 0
    local src = "Fail"

    local okIRS, iEgg, iBone = readFromIRS()
    if okIRS then
        eggs, bones = iEgg, iBone
        src = "IRS"
    end

    if not okIRS or (eggs == 0 and bones == 0) then
        local okRem, rEgg, rBone = readFromRemoteWithTimeout(3)
        if okRem then
            if rEgg > eggs then eggs = rEgg end
            if rBone > bones then bones = rBone end
            src = okIRS and "IRS+Remote" or "Remote"
        elseif not okIRS then
            src = "Timeout/Blocked"
        end
    end

    EggLabel.Text    = "Dragon Egg: " .. tostring(eggs)
    BoneLabel.Text   = "Dinosaur Bones: " .. tostring(bones)
    StatusLabel.Text = src .. " | " .. os.date("%H:%M:%S")
end

task.spawn(function()
    while ScreenGui.Parent do
        updateOnce()
        task.wait(CHECK_DELAY)
    end
end)

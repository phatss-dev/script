local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local lp                = Players.LocalPlayer

local CHECK_DELAY = 3

-- ============================================================
-- TẠO UI HIỂN THỊ
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
Title.Text = "INVENTORY CHECKER v4"
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
StatusLabel.Size = UDim2.new(1, -16, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 84)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Dang doc CommF_..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = Frame

-- ============================================================
-- ĐỌC TÚI ĐỒ CHỈ QUA COMMF_ (KHÔNG DÙNG REQUIRE)
-- ============================================================
local function checkInventoryViaCommF()
    local done = false
    local inv = nil

    task.spawn(function()
        pcall(function()
            inv = ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
        end)
        done = true
    end)

    -- Chờ tối đa 5 giây tránh treo
    local t0 = os.clock()
    while not done and (os.clock() - t0) < 5 do
        task.wait(0.1)
    end

    if not done then
        return false, 0, 0, "Remote Timeout"
    end
    if type(inv) ~= "table" then
        return false, 0, 0, "Data: " .. tostring(type(inv))
    end

    local eggs  = 0
    local bones = 0
    local total = 0

    for _, item in pairs(inv) do
        total = total + 1
        if type(item) == "table" and item.Name then
            local low   = tostring(item.Name):lower()
            local count = tonumber(item.Count) or 1

            if low:find("dragon egg", 1, true) then
                eggs = eggs + count
            elseif low:find("dinosaur bone", 1, true) or low:find("dino bone", 1, true) then
                bones = bones + count
            end
        end
    end

    return true, eggs, bones, "OK (" .. total .. " items)"
end

getgenv().CheckDragonItems = function()
    local _, eggs, bones = checkInventoryViaCommF()
    return eggs, bones
end

-- ============================================================
-- VÒNG LẶP CẬP NHẬT
-- ============================================================
task.spawn(function()
    while ScreenGui.Parent do
        local ok, eggs, bones, info = checkInventoryViaCommF()
        if ok then
            EggLabel.Text  = "Dragon Egg: " .. tostring(eggs)
            BoneLabel.Text = "Dinosaur Bones: " .. tostring(bones)
        end
        StatusLabel.Text = info .. " | " .. os.date("%H:%M:%S")
        task.wait(CHECK_DELAY)
    end
end)

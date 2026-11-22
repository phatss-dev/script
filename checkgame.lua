local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local lp      = Players.LocalPlayer

local CHECK_DELAY = 1.5

-- Chọn nơi gắn UI an toàn
local guiParent = lp:FindFirstChild("PlayerGui")
pcall(function()
    if type(gethui) == "function" then
        guiParent = gethui()
    elseif CoreGui:FindFirstChild("RobloxGui") then
        guiParent = CoreGui
    end
end)

-- Xóa các bảng cũ nếu có
for _, container in ipairs({ guiParent, CoreGui, lp:FindFirstChild("PlayerGui") }) do
    pcall(function()
        if container then
            local old = container:FindFirstChild("DragonItemCheckerUI")
            if old then old:Destroy() end
        end
    end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DragonItemCheckerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 265, 0, 115)
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
Title.Text = "INVENTORY CHECKER v6"
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
StatusLabel.Position = UDim2.new(0, 10, 0, 86)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Hay mo tui do (Items) 1 lan..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = Frame

-- ============================================================
-- HÀM QUÉT SỐ LƯỢNG TỪ GIAO DIỆN TÚI ĐỒ (PLAYERGUI)
-- ============================================================
local cachedEggs  = 0
local cachedBones = 0

local function parseNumberFromSlot(slot, keyword)
    if not slot then return nil end
    for _, desc in ipairs(slot:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local t = tostring(desc.Text or "")
            local low = t:lower()
            if low ~= "" and not low:find(keyword, 1, true) then
                local num = t:match("^[xX]%s*(%d+)$")
                    or t:match("^(%d+)%s*[xX]$")
                    or t:match("^(%d+)$")
                if num then
                    local n = tonumber(num)
                    if n and n > 0 and n < 100000 then
                        return n
                    end
                end
            end
        end
    end
    return nil
end

local function getCountNearObject(obj, keyword)
    -- Kiểm tra chính nó, rồi lên cha gần nhất (ô chứa item)
    local candidates = { obj, obj.Parent, obj.Parent and obj.Parent.Parent }
    for _, box in ipairs(candidates) do
        if box and box:IsA("GuiObject") and #box:GetChildren() <= 15 then
            local n = parseNumberFromSlot(box, keyword)
            if n then return n end
        end
    end
    return 1 -- Nếu thấy ô item nhưng không ghi số (mặc định là 1)
end

local function scanInventoryUI()
    local pGui = lp:FindFirstChild("PlayerGui")
    if not pGui then return false, cachedEggs, cachedBones end

    local root = pGui:FindFirstChild("Main") or pGui
    local foundEgg  = nil
    local foundBone = nil

    for _, desc in ipairs(root:GetDescendants()) do
        if not desc:IsDescendantOf(ScreenGui) then
            local nameLow = tostring(desc.Name or ""):lower()
            local textLow = ""
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                textLow = tostring(desc.Text or ""):lower()
            end

            if nameLow:find("dragon egg", 1, true) or textLow:find("dragon egg", 1, true) then
                local n = getCountNearObject(desc, "dragon egg")
                if not foundEgg or n > foundEgg then foundEgg = n end
            elseif nameLow:find("dinosaur bone", 1, true) or textLow:find("dinosaur bone", 1, true) then
                local n = getCountNearObject(desc, "dinosaur bone")
                if not foundBone or n > foundBone then foundBone = n end
            end
        end
    end

    local updated = false
    if foundEgg then
        cachedEggs = foundEgg
        updated = true
    end
    if foundBone then
        cachedBones = foundBone
        updated = true
    end

    return updated, cachedEggs, cachedBones
end

pcall(function()
    if type(getgenv) == "function" then
        getgenv().CheckDragonItems = function()
            scanInventoryUI()
            return cachedEggs, cachedBones
        end
    end
end)

-- ============================================================
-- VÒNG LẶP CẬP NHẬT
-- ============================================================
task.spawn(function()
    local count = 0
    while true do
        count = count + 1
        local updated, eggs, bones = scanInventoryUI()
        EggLabel.Text  = "Dragon Egg: " .. tostring(eggs)
        BoneLabel.Text = "Dinosaur Bones: " .. tostring(bones)

        if updated then
            StatusLabel.Text = "Da doc tu UI Items (#" .. tostring(count) .. ")"
        else
            StatusLabel.Text = "Mo Items -> Material de cap nhat (#" .. tostring(count) .. ")"
        end

        task.wait(CHECK_DELAY)
    end
end)

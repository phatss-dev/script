local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local lp      = Players.LocalPlayer

local CHECK_DELAY = 15 -- Tự mở kiểm tra lại mỗi 15 giây

-- ============================================================
-- TẠO UI HIỂN THỊ
-- ============================================================
local guiParent = lp:FindFirstChild("PlayerGui")
pcall(function()
    if type(gethui) == "function" then
        guiParent = gethui()
    elseif CoreGui:FindFirstChild("RobloxGui") then
        guiParent = CoreGui
    end
end)

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
Title.Text = "INVENTORY CHECKER v7 (AUTO)"
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
StatusLabel.Position = UDim2.new(0, 10, 0, 86)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Dang khoi dong..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = Frame

-- ============================================================
-- HÀM TỰ BẤM NÚT UI KHÔNG CẦN THAO TÁC TAY
-- ============================================================
local function clickGuiButton(btn)
    if not btn then return false end
    local clicked = false

    if type(firesignal) == "function" then
        pcall(function() firesignal(btn.MouseButton1Click); clicked = true end)
        pcall(function() firesignal(btn.Activated); clicked = true end)
    end

    if type(getconnections) == "function" then
        for _, signal in ipairs({ btn.MouseButton1Click, btn.Activated }) do
            pcall(function()
                for _, conn in ipairs(getconnections(signal)) do
                    if type(conn.Fire) == "function" then
                        pcall(function() conn:Fire(); clicked = true end)
                    elseif type(conn.Function) == "function" then
                        pcall(function() conn.Function(); clicked = true end)
                    end
                end
            end)
        end
    end

    return clicked
end

local function findButtonByLabel(root, targetLower, mustBeVisible)
    if not root then return nil end
    for _, desc in ipairs(root:GetDescendants()) do
        if desc:IsA("GuiButton") and not desc:IsDescendantOf(ScreenGui) then
            if not mustBeVisible or desc.Visible then
                local n = tostring(desc.Name or ""):lower()
                local t = desc:IsA("TextButton") and tostring(desc.Text or ""):lower() or ""
                if n == targetLower or t == targetLower then
                    return desc
                end
                -- Kiểm tra TextLabel nằm bên trong ImageButton
                for _, child in ipairs(desc:GetChildren()) do
                    if child:IsA("TextLabel") and tostring(child.Text or ""):lower() == targetLower then
                        return desc
                    end
                end
            end
        end
    end
    return nil
end

-- ============================================================
-- HÀM ĐỌC SỐ LƯỢNG TRONG TÚI ĐỒ
-- ============================================================
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
    local candidates = { obj, obj.Parent, obj.Parent and obj.Parent.Parent }
    for _, box in ipairs(candidates) do
        if box and box:IsA("GuiObject") and #box:GetChildren() <= 15 then
            local n = parseNumberFromSlot(box, keyword)
            if n then return n end
        end
    end
    return 1
end

local function scanInventoryUI(root)
    local foundEgg  = 0
    local foundBone = 0
    local hitAny    = false

    for _, desc in ipairs(root:GetDescendants()) do
        if not desc:IsDescendantOf(ScreenGui) then
            local nameLow = tostring(desc.Name or ""):lower()
            local textLow = (desc:IsA("TextLabel") or desc:IsA("TextButton")) and tostring(desc.Text or ""):lower() or ""

            if nameLow:find("dragon egg", 1, true) or textLow:find("dragon egg", 1, true) then
                local n = getCountNearObject(desc, "dragon egg")
                if n > foundEgg then foundEgg = n end
                hitAny = true
            elseif nameLow:find("dinosaur bone", 1, true) or textLow:find("dinosaur bone", 1, true) then
                local n = getCountNearObject(desc, "dinosaur bone")
                if n > foundBone then foundBone = n end
                hitAny = true
            end
        end
    end

    return hitAny, foundEgg, foundBone
end

-- ============================================================
-- QUY TRÌNH TỰ MỞ TÚI -> ĐỌC -> TỰ ĐÓNG
-- ============================================================
local lastEggs, lastBones = 0, 0

local function autoOpenAndCheck(runIndex)
    local pGui = lp:FindFirstChild("PlayerGui")
    local root = pGui and (pGui:FindFirstChild("Main") or pGui)
    if not root then
        StatusLabel.Text = "Khong thay PlayerGui (#" .. tostring(runIndex) .. ")"
        return
    end

    if type(firesignal) ~= "function" and type(getconnections) ~= "function" then
        StatusLabel.Text = "Executor thieu firesignal/getconnections"
        return
    end

    -- 1. Mở Menu nếu nút Items chưa hiện
    local itemsBtn = findButtonByLabel(root, "items", true)
    if not itemsBtn then
        local menuBtn = findButtonByLabel(root, "menu", true)
        if menuBtn then
            StatusLabel.Text = "Tu bam Menu..."
            clickGuiButton(menuBtn)
            task.wait(0.6)
            itemsBtn = findButtonByLabel(root, "items", true) or findButtonByLabel(root, "items", false)
        end
    end

    -- 2. Bấm mở Items
    if itemsBtn then
        StatusLabel.Text = "Tu mo Items..."
        clickGuiButton(itemsBtn)
        task.wait(1.2)
    else
        StatusLabel.Text = "Khong tim thay nut Items (#" .. tostring(runIndex) .. ")"
        return
    end

    -- 3. Bấm qua tab Material (nếu có)
    local matBtn = findButtonByLabel(root, "material", true) or findButtonByLabel(root, "materials", true)
    if matBtn then
        StatusLabel.Text = "Chon tab Material..."
        clickGuiButton(matBtn)
        task.wait(0.8)
    end

    -- 4. Quét dữ liệu
    StatusLabel.Text = "Dang quet item..."
    local hitAny, eggs, bones = scanInventoryUI(root)
    lastEggs, lastBones = eggs, bones
    EggLabel.Text  = "Dragon Egg: " .. tostring(eggs)
    BoneLabel.Text = "Dinosaur Bones: " .. tostring(bones)

    -- 5. Tự đóng túi đồ cho đỡ lag
    task.wait(0.3)
    clickGuiButton(itemsBtn)

    if hitAny then
        StatusLabel.Text = "OK - Da dong tui (#" .. tostring(runIndex) .. ")"
    else
        StatusLabel.Text = "Da quet xong - 0 item (#" .. tostring(runIndex) .. ")"
    end
end

pcall(function()
    if type(getgenv) == "function" then
        getgenv().CheckDragonItems = function()
            return lastEggs, lastBones
        end
    end
end)

task.spawn(function()
    local runIndex = 0
    while true do
        runIndex = runIndex + 1
        pcall(autoOpenAndCheck, runIndex)
        task.wait(CHECK_DELAY)
    end
end)

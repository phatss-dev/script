local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local lp      = Players.LocalPlayer

local CHECK_DELAY = 15

-- ============================================================
-- TẠO UI HIỂN THỊ (ĐẶT Ở MÉP TRÊN ĐỂ KHÔNG CHE NÚT ITEMS)
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
Frame.Size = UDim2.new(0, 275, 0, 115)
Frame.Position = UDim2.new(0.5, -137, 0, 12)
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
Title.Text = "INVENTORY CHECKER v8 (AUTO)"
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
-- TIỆN ÍCH TÌM NÚT THÔNG MINH (QUÉT TOÀN BỘ PLAYERGUI)
-- ============================================================
local function cleanText(str)
    local s = tostring(str or "")
    s = s:gsub("<[^>]+>", "") -- Bỏ thẻ RichText nếu có
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s:lower()
end

local function isVisibleTree(obj)
    local cur = obj
    while cur and cur ~= lp do
        if cur:IsA("GuiObject") and not cur.Visible then
            return false
        elseif cur:IsA("ScreenGui") and not cur.Enabled then
            return false
        end
        cur = cur.Parent
    end
    return true
end

local function getNearestButton(obj)
    if obj:IsA("GuiButton") then return obj end
    -- Dò ngược lên cha (tối đa 4 cấp)
    local cur = obj.Parent
    for _ = 1, 4 do
        if not cur then break end
        if cur:IsA("GuiButton") then return cur end
        cur = cur.Parent
    end
    -- Dò anh em cùng cấp nếu nút bấm là lớp phủ trong suốt
    if obj.Parent then
        for _, sibling in ipairs(obj.Parent:GetChildren()) do
            if sibling:IsA("GuiButton") then return sibling end
        end
    end
    return nil
end

local function findButtonSmart(pGui, keywords)
    local fallback = nil

    for _, desc in ipairs(pGui:GetDescendants()) do
        if not desc:IsDescendantOf(ScreenGui) then
            local matched = false
            local txt = ""
            if desc:IsA("TextButton") or desc:IsA("TextLabel") then
                txt = cleanText(desc.Text)
            end
            local nm = cleanText(desc.Name)

            for _, kw in ipairs(keywords) do
                if txt == kw or nm == kw or (desc:IsA("GuiButton") and nm:find(kw, 1, true)) then
                    matched = true
                    break
                end
            end

            if matched then
                local btn = getNearestButton(desc)
                if btn then
                    if isVisibleTree(btn) then
                        return btn
                    elseif not fallback then
                        fallback = btn
                    end
                end
            end
        end
    end

    return fallback
end

local function clickGuiButton(btn)
    if not btn then return false end
    local clicked = false
    local signals = { "MouseButton1Down", "MouseButton1Up", "MouseButton1Click", "Activated" }

    for _, sigName in ipairs(signals) do
        local okSig, sig = pcall(function() return btn[sigName] end)
        if okSig and sig then
            if type(firesignal) == "function" then
                pcall(function() firesignal(sig); clicked = true end)
            end
            if type(getconnections) == "function" then
                pcall(function()
                    for _, conn in ipairs(getconnections(sig)) do
                        if type(conn.Fire) == "function" then
                            pcall(function() conn:Fire(); clicked = true end)
                        elseif type(conn.Function) == "function" then
                            pcall(function() conn.Function(); clicked = true end)
                        end
                    end
                end)
            end
        end
    end

    return clicked
end

-- ============================================================
-- QUÉT SỐ LƯỢNG ITEM TRONG PLAYERGUI
-- ============================================================
local function parseNumberFromSlot(slot, keyword)
    if not slot then return nil end
    for _, desc in ipairs(slot:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local t = tostring(desc.Text or ""):gsub("<[^>]+>", ""):gsub("^%s+", ""):gsub("%s+$", "")
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

local function scanInventoryUI(pGui)
    local foundEgg  = 0
    local foundBone = 0
    local hitAny    = false

    for _, desc in ipairs(pGui:GetDescendants()) do
        if not desc:IsDescendantOf(ScreenGui) then
            local nameLow = cleanText(desc.Name)
            local textLow = (desc:IsA("TextLabel") or desc:IsA("TextButton")) and cleanText(desc.Text) or ""

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
-- QUY TRÌNH TỰ MỞ -> ĐỌC -> ĐÓNG
-- ============================================================
local lastEggs, lastBones = 0, 0

local function autoOpenAndCheck(runIndex)
    local pGui = lp:FindFirstChild("PlayerGui")
    if not pGui then
        StatusLabel.Text = "Khong thay PlayerGui (#" .. tostring(runIndex) .. ")"
        return
    end

    -- Quét trước 1 lượt phòng trường hợp item đã được load sẵn trong UI
    local preHit, preEgg, preBone = scanInventoryUI(pGui)
    if preHit then
        lastEggs, lastBones = preEgg, preBone
        EggLabel.Text  = "Dragon Egg: " .. tostring(preEgg)
        BoneLabel.Text = "Dinosaur Bones: " .. tostring(preBone)
        StatusLabel.Text = "Doc truc tiep OK (#" .. tostring(runIndex) .. ")"
        return
    end

    if type(firesignal) ~= "function" and type(getconnections) ~= "function" then
        StatusLabel.Text = "Executor thieu firesignal/getconnections"
        return
    end

    -- Tìm nút Items (mở Menu trước nếu Items đang ẩn)
    local itemsBtn = findButtonSmart(pGui, { "items", "inventory" })
    if not itemsBtn or not isVisibleTree(itemsBtn) then
        local menuBtn = findButtonSmart(pGui, { "menu" })
        if menuBtn then
            StatusLabel.Text = "Bam Menu (" .. menuBtn.Name .. ")..."
            clickGuiButton(menuBtn)
            task.wait(0.6)
            itemsBtn = findButtonSmart(pGui, { "items", "inventory" })
        end
    end

    if not itemsBtn then
        StatusLabel.Text = "Van khong thay nut Items (#" .. tostring(runIndex) .. ")"
        return
    end

    StatusLabel.Text = "Bam " .. itemsBtn.Name .. "..."
    clickGuiButton(itemsBtn)
    task.wait(1.2)

    -- Chuyển sang tab Material nếu thấy
    local matBtn = findButtonSmart(pGui, { "material", "materials" })
    if matBtn and isVisibleTree(matBtn) then
        StatusLabel.Text = "Chon tab Material..."
        clickGuiButton(matBtn)
        task.wait(0.8)
    end

    -- Quét item
    local hitAny, eggs, bones = scanInventoryUI(pGui)
    lastEggs, lastBones = eggs, bones
    EggLabel.Text  = "Dragon Egg: " .. tostring(eggs)
    BoneLabel.Text = "Dinosaur Bones: " .. tostring(bones)

    -- Đóng túi đồ lại
    task.wait(0.3)
    clickGuiButton(itemsBtn)

    if hitAny then
        StatusLabel.Text = "OK - Da dong tui (#" .. tostring(runIndex) .. ")"
    else
        StatusLabel.Text = "Da bam " .. itemsBtn.Name .. " - 0 item (#" .. tostring(runIndex) .. ")"
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

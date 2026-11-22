local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local lp      = Players.LocalPlayer

local FAST_SCAN_DELAY = 3   -- Quét lại cực nhanh mỗi 3 giây nếu đã có khung túi đồ
local AUTO_OPEN_CD    = 12  -- Nếu phải tự mở túi, giãn cách 12 giây tránh lag

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
Title.Text = "INVENTORY CHECKER v10 (FAST)"
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
StatusLabel.Text = "San sang quet..."
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 200)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = Frame

-- ============================================================
-- TIỆN ÍCH NHẸ & CACHE KHUNG TÚI ĐỒ
-- ============================================================
local cachedInvRoot = nil
local lastEggs, lastBones = 0, 0
local lastAutoOpen = 0

local function cleanText(str)
    local s = tostring(str or "")
    s = s:gsub("<[^>]+>", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    return s:lower()
end

local function clickGuiButton(btn)
    if not btn then return false end
    local clicked = false
    for _, sigName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up" }) do
        local okSig, sig = pcall(function() return btn[sigName] end)
        if okSig and sig then
            if type(firesignal) == "function" then
                pcall(function() firesignal(sig); clicked = true end)
            elseif type(getconnections) == "function" then
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

-- Chỉ tìm đúng khung Inventory trong PlayerGui.Main (rất nhanh)
local function getInventoryRoot()
    if cachedInvRoot and cachedInvRoot.Parent then
        return cachedInvRoot
    end
    local pGui = lp:FindFirstChild("PlayerGui")
    if not pGui then return nil end

    local main = pGui:FindFirstChild("Main")
    if main then
        local inv = main:FindFirstChild("InventoryContainer")
            or main:FindFirstChild("Inventory")
            or main:FindFirstChild("Items")
        if inv then
            cachedInvRoot = inv
            return inv
        end
        return main
    end
    return pGui
end

-- Tìm nút nhanh trong Main (không quét cả PlayerGui)
local function findButtonInMain(keywords)
    local pGui = lp:FindFirstChild("PlayerGui")
    local main = pGui and pGui:FindFirstChild("Main")
    if not main then return nil end

    -- Kiểm tra đường dẫn trực tiếp trước (mất 0ms)
    for _, kw in ipairs(keywords) do
        local direct = main:FindFirstChild(kw)
        if direct and direct:IsA("GuiButton") then return direct end
        local menu = main:FindFirstChild("Menu")
        if menu then
            local inMenu = menu:FindFirstChild(kw)
            if inMenu and inMenu:IsA("GuiButton") then return inMenu end
        end
    end

    -- Quét nhẹ các nút cấp gần
    for _, desc in ipairs(main:GetDescendants()) do
        if desc:IsA("GuiButton") then
            local nm = cleanText(desc.Name)
            local txt = desc:IsA("TextButton") and cleanText(desc.Text) or ""
            for _, kw in ipairs(keywords) do
                local kwLow = kw:lower()
                if nm == kwLow or txt == kwLow then
                    return desc
                end
            end
        end
    end
    return nil
end

-- ============================================================
-- ĐỌC SỐ LƯỢNG TỪ Ô ITEM (CHỈ LẤY SỐ ĐANG HIỆN)
-- ============================================================
local function readSlotNumber(slot, keyword)
    if not slot then return 1 end
    local bestVal = nil
    local bestPrio = -1

    for _, d in ipairs(slot:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible and (d.TextTransparency or 0) < 0.9 then
            local raw = tostring(d.Text or ""):gsub("<[^>]+>", ""):gsub(",", ""):gsub("^%s+", ""):gsub("%s+$", "")
            local low = raw:lower()
            if low ~= "" and not low:find(keyword, 1, true) then
                local numStr = raw:match("^[xX]%s*(%d+)$") or raw:match("^(%d+)%s*[xX]$") or raw:match("^(%d+)$")
                if numStr then
                    local n = tonumber(numStr)
                    if n and n > 0 and n < 100000 then
                        local nm = cleanText(d.Name)
                        if not (nm:find("level", 1, true) or nm:find("mastery", 1, true) or nm:find("lv", 1, true)) then
                            local prio = (nm:find("count", 1, true) or nm:find("amount", 1, true) or nm:find("qty", 1, true)) and 2 or 1
                            if prio > bestPrio or (prio == bestPrio and (not bestVal or n > bestVal)) then
                                bestPrio = prio
                                bestVal = n
                            end
                        end
                    end
                end
            end
        end
    end

    return bestVal or 1
end

local function getSlotContainer(obj)
    local slot = obj:IsA("GuiObject") and obj or nil
    local cur = obj.Parent
    for _ = 1, 4 do
        if not cur or cur:IsA("ScrollingFrame") or cur:IsA("ScreenGui") or cur:FindFirstChildOfClass("UIGridLayout") then
            break
        end
        if cur:IsA("GuiObject") then slot = cur end
        cur = cur.Parent
    end
    return slot
end

local function fastScanInventory()
    local root = getInventoryRoot()
    if not root then return false, 0, 0 end

    local eggs, bones = 0, 0
    local foundAny = false

    for _, desc in ipairs(root:GetDescendants()) do
        local nm = cleanText(desc.Name)
        local txt = (desc:IsA("TextLabel") or desc:IsA("TextButton")) and cleanText(desc.Text) or ""

        if nm:find("dragon egg", 1, true) or txt:find("dragon egg", 1, true) then
            local n = readSlotNumber(getSlotContainer(desc), "dragon egg")
            if n > eggs then eggs = n end
            foundAny = true
        elseif nm:find("dinosaur bone", 1, true) or txt:find("dinosaur bone", 1, true) then
            local n = readSlotNumber(getSlotContainer(desc), "dinosaur bone")
            if n > bones then bones = n end
            foundAny = true
        end
    end

    return foundAny, eggs, bones
end

-- ============================================================
-- VÒNG LẶP CHÍNH (HIỆN TRẠNG THÁI & LỖI TỨC THÌ)
-- ============================================================
local function runStep(stepIdx)
    StatusLabel.Text = "Quet nhanh #" .. tostring(stepIdx) .. "..."
    local ok, eggs, bones = fastScanInventory()

    if ok then
        lastEggs, lastBones = eggs, bones
        EggLabel.Text  = "Dragon Egg: " .. tostring(eggs)
        BoneLabel.Text = "Dinosaur Bones: " .. tostring(bones)
        StatusLabel.Text = "OK (nhanh) #" .. tostring(stepIdx)
        return
    end

    -- Nếu chưa thấy item trong UI -> tự mở túi (giãn cách theo AUTO_OPEN_CD)
    local now = tick()
    if (now - lastAutoOpen) < AUTO_OPEN_CD then
        StatusLabel.Text = "Cho mo tui (" .. tostring(math.ceil(AUTO_OPEN_CD - (now - lastAutoOpen))) .. "s)..."
        return
    end
    lastAutoOpen = now

    if type(firesignal) ~= "function" and type(getconnections) ~= "function" then
        StatusLabel.Text = "Thieu firesignal -> hay mo Items 1 lan"
        return
    end

    local itemsBtn = findButtonInMain({ "Items", "Inventory" })
    if not itemsBtn then
        local menuBtn = findButtonInMain({ "MenuButton", "Menu" })
        if menuBtn then
            StatusLabel.Text = "Mo Menu..."
            clickGuiButton(menuBtn)
            task.wait(0.35)
            itemsBtn = findButtonInMain({ "Items", "Inventory" })
        end
    end

    if not itemsBtn then
        StatusLabel.Text = "Khong thay nut Items #" .. tostring(stepIdx)
        return
    end

    StatusLabel.Text = "Mo Items..."
    clickGuiButton(itemsBtn)
    task.wait(0.6)

    -- Chuyển sang tab Material nếu thấy
    local matBtn = findButtonInMain({ "Material", "Materials" })
    if matBtn and matBtn.Visible then
        clickGuiButton(matBtn)
        task.wait(0.4)
    end

    local ok2, eggs2, bones2 = fastScanInventory()
    lastEggs, lastBones = eggs2, bones2
    EggLabel.Text  = "Dragon Egg: " .. tostring(eggs2)
    BoneLabel.Text = "Dinosaur Bones: " .. tostring(bones2)

    -- Đóng túi đồ ngay sau khi đọc xong
    task.wait(0.2)
    clickGuiButton(itemsBtn)

    StatusLabel.Text = ok2 and ("OK (tu mo) #" .. tostring(stepIdx)) or ("Quet xong: 0 item #" .. tostring(stepIdx))
end

pcall(function()
    if type(getgenv) == "function" then
        getgenv().CheckDragonItems = function()
            return lastEggs, lastBones
        end
    end
end)

task.spawn(function()
    local idx = 0
    while true do
        idx = idx + 1
        local success, err = pcall(runStep, idx)
        if not success then
            StatusLabel.Text = "LOI: " .. tostring(err)
        end
        task.wait(FAST_SCAN_DELAY)
    end
end)

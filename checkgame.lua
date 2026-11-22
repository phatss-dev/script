local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local lp      = Players.LocalPlayer

local CHECK_DELAY = 15

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
Title.Text = "INVENTORY CHECKER v9 (AUTO)"
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
-- TIỆN ÍCH XỬ LÝ UI & TÌM NÚT
-- ============================================================
local function cleanText(str)
    local s = tostring(str or "")
    s = s:gsub("<[^>]+>", "")
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

local function isGridContainer(obj)
    if not obj then return true end
    if obj:IsA("ScrollingFrame") or obj:IsA("ScreenGui") then
        return true
    end
    if obj:FindFirstChildOfClass("UIGridLayout") then
        return true
    end
    return false
end

local function getNearestButton(obj)
    if obj:IsA("GuiButton") then return obj end
    local cur = obj.Parent
    for _ = 1, 4 do
        if not cur then break end
        if cur:IsA("GuiButton") then return cur end
        cur = cur.Parent
    end
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
            local txt = (desc:IsA("TextButton") or desc:IsA("TextLabel")) and cleanText(desc.Text) or ""
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
-- ĐỌC SỐ LƯỢNG CHÍNH XÁC TỪ Ô ITEM (FIX LỖI ĐỌC RA 1)
-- ============================================================
local function parseCountFromSlot(slot, keyword)
    if not slot then return nil end

    local bestVal  = nil
    local bestPrio = -1

    for _, desc in ipairs(slot:GetDescendants()) do
        if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Visible and (desc.TextTransparency or 0) < 0.95 then
            local raw = tostring(desc.Text or ""):gsub("<[^>]+>", "")
            raw = raw:gsub(",", ""):gsub("^%s+", ""):gsub("%s+$", "")
            local low = raw:lower()

            if low ~= "" and not low:find(keyword, 1, true) then
                local numStr = raw:match("^[xX]%s*(%d+)$")
                    or raw:match("^(%d+)%s*[xX]$")
                    or raw:match("^(%d+)$")

                if numStr then
                    local n = tonumber(numStr)
                    if n and n > 0 and n < 100000 then
                        local nameLow = cleanText(desc.Name)
                        -- Bỏ qua nhãn level / mastery / giá tiền
                        if not (nameLow:find("level", 1, true) or nameLow:find("mastery", 1, true)
                            or nameLow:find("lv", 1, true) or nameLow:find("price", 1, true)) then

                            local prio = 1
                            if nameLow:find("count", 1, true) or nameLow:find("amount", 1, true)
                                or nameLow:find("qty", 1, true) or nameLow:find("quantity", 1, true)
                                or nameLow:find("stack", 1, true) or nameLow:find("num", 1, true) then
                                prio = 3
                            elseif isVisibleTree(desc) then
                                prio = 2
                            end

                            if prio > bestPrio or (prio == bestPrio and (not bestVal or n > bestVal)) then
                                bestPrio = prio
                                bestVal  = n
                            end
                        end
                    end
                end
            end
        end
    end

    return bestVal
end

local function getItemSlot(obj)
    -- Leo ngược lên đến ngay dưới GridContainer (ScrollingFrame / UIGridLayout)
    local slot = obj:IsA("GuiObject") and obj or nil
    local cur = obj.Parent
    for _ = 1, 5 do
        if not cur or isGridContainer(cur) then
            break
        end
        if cur:IsA("GuiObject") then
            slot = cur
        end
        cur = cur.Parent
    end
    return slot
end

local function getCountNearObject(obj, keyword)
    -- 1. Thử đọc ngay trong ô item chuẩn (ngay dưới ScrollingFrame/UIGridLayout)
    local slot = getItemSlot(obj)
    if slot then
        local n = parseCountFromSlot(slot, keyword)
        if n then return n end
    end

    -- 2. Thử đọc chính obj và các cha gần nhất nếu chưa đụng GridContainer
    local cur = obj
    for _ = 1, 4 do
        if not cur or isGridContainer(cur) then break end
        if cur:IsA("GuiObject") then
            local n = parseCountFromSlot(cur, keyword)
            if n then return n end
        end
        cur = cur.Parent
    end

    return 1 -- Không có số hiển thị trên ô => số lượng mặc định là 1
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
-- QUY TRÌNH TỰ MỞ -> ĐỌC -> Đ

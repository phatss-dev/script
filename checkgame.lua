local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local lp                = Players.LocalPlayer

local guiParent = CoreGui
pcall(function()
    if not CoreGui:FindFirstChild("RobloxGui") then guiParent = lp.PlayerGui end
end)
pcall(function()
    local old = guiParent:FindFirstChild("InvDebugUI")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui", guiParent)
gui.Name = "InvDebugUI"

local frame = Instance.new("ScrollingFrame", gui)
frame.Size = UDim2.new(0, 360, 0, 220)
frame.Position = UDim2.new(0.5, -180, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
frame.CanvasSize = UDim2.new(0, 0, 0, 1200)
frame.Active = true
frame.Draggable = true

local text = Instance.new("TextLabel", frame)
text.Size = UDim2.new(1, -12, 1, -12)
text.Position = UDim2.new(0, 6, 0, 6)
text.BackgroundTransparency = 1
text.TextColor3 = Color3.fromRGB(220, 255, 220)
text.Font = Enum.Font.Code
text.TextSize = 11
text.TextXAlignment = Enum.TextXAlignment.Left
text.TextYAlignment = Enum.TextYAlignment.Top
text.TextWrapped = true

local logs = {}
local function log(msg)
    table.insert(logs, tostring(msg))
    text.Text = table.concat(logs, "\n")
end

log("=== BAT DAU KIEM TRA ===")

-- 1. Test ItemReplicationService
local okIRS, errIRS = pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("ItemReplicationService")
    if not mod then error("Khong tim thay ItemReplicationService") end
    local irs = require(mod)
    local keys = require(mod:FindFirstChild("KEYS"))
    local cfg = require(ReplicatedStorage:FindFirstChild("ItemConfig"))
    local items = irs:GetItems(keys.QUANTITY)
    log("IRS type: " .. type(items))
    if type(items) == "table" then
        local c = 0
        for k, v in pairs(items) do
            c = c + 1
            if c <= 5 then
                local id = type(v) == "table" and v.ItemId or k
                local val = type(v) == "table" and v.Value or v
                local okN, lbl = pcall(function()
                    return cfg.match(id):unwrap().Index.DebugLabel
                end)
                log(string.format("  IRS[%s] val=%s label=%s", tostring(id), tostring(val), tostring(okN and lbl or "ERR")))
            end
        end
        log("IRS tong so muc: " .. c)
    end
end)
if not okIRS then
    log("IRS LOI: " .. tostring(errIRS))
end

-- 2. Test CommF_ getInventory
log("--- Test CommF_ ---")
local okRem, inv = pcall(function()
    return ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
end)
log("CommF_ ok=" .. tostring(okRem) .. " | type=" .. type(inv))

if okRem and type(inv) == "table" then
    local total = 0
    local matched = 0
    for _, item in pairs(inv) do
        total = total + 1
        if type(item) == "table" then
            local n = tostring(item.Name or item.RawName or "?")
            local low = n:lower()
            if low:find("egg") or low:find("bone") or low:find("dragon") or low:find("dino") then
                matched = matched + 1
                log(string.format("  MATCH: Name=%s | Count=%s | Type=%s", n, tostring(item.Count), tostring(item.Type)))
            end
        end
    end
    log("CommF_ tong item: " .. total .. " | Khop tu khoa: " .. matched)
end

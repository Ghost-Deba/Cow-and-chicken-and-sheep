local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Larry = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Larry")

-- إعدادات الكود
local MAX_WOOL_TO_COLLECT = 5
local SPIN_TIME = 10
local CHECK_INTERVAL = 1
local STORAGE_SEARCH_RADIUS = 50

-- وظائف المساعدة
local function debugPrint(msg)
    print("[DEBUG] "..os.date("%X").." "..msg)
end

local function safeTeleport(cframe)
    if not cframe then return false end
    local success, err = pcall(function()
        humanoidRootPart.CFrame = cframe * CFrame.new(0, 3, 0)
        wait(0.3)
        humanoidRootPart.CFrame = cframe * CFrame.new(0, 0, 2)
        wait(0.3)
    end)
    return success
end

-- العثور على المكينة الخاصة بالمستخدم
local function findMyMachine()
    local myName = player.Name
    debugPrint("البحث عن مكينة المالك: "..myName)
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("spindle") and obj:FindFirstChild("Configurations") then
            local owner = obj.Configurations:FindFirstChild("Owner")
            if owner and owner.Value == myName then
                debugPrint("تم العثور على المكينة: "..obj:GetFullName())
                return obj
            end
        end
    end
    
    debugPrint("⚠️ لم يتم العثور على المكينة الخاصة بي")
    return nil
end

-- جمع الصوف
local function collectWool()
    local collected = 0
    for _, wool in pairs(workspace.DraggableObjects:GetChildren()) do
        if wool.Name == "Wool" and collected < MAX_WOOL_TO_COLLECT then
            if safeTeleport(wool:GetPivot()) then
                local args = {[1] = wool}
                local success = pcall(function()
                    Larry.EVTRequestToCarry:FireServer(unpack(args))
                end)
                
                if success then
                    collected = collected + 1
                    debugPrint("تم جمع الصوف ("..collected.."/"..MAX_WOOL_TO_COLLECT..")")
                end
            end
            wait(CHECK_INTERVAL)
        end
    end
    return collected
end

-- تشغيل المكينة
local function spinMachine(machine)
    if not safeTeleport(machine:GetPivot()) then return false end
    
    local args = {[1] = machine}
    local success = pcall(function()
        Larry.EVTAnimateSpindle:FireServer(unpack(args))
    end)
    
    if success then
        debugPrint("تم تشغيل المكينة، انتظار "..SPIN_TIME.." ثانية...")
        wait(SPIN_TIME)
        return true
    end
    return false
end

-- التقاط WoolBundle
local function pickupWoolBundle()
    for _, bundle in pairs(workspace.DraggableObjects:GetChildren()) do
        if bundle.Name == "WoolBundle" then
            if safeTeleport(bundle:GetPivot()) then
                local args = {[1] = bundle}
                local success = pcall(function()
                    Larry.EVTRequestToCarry:FireServer(unpack(args))
                end)
                return success
            end
        end
    end
    return false
end

-- البحث عن مكان تخزين مناسب
local function findStorageSpot()
    local closestStorage = nil
    local closestDistance = math.huge
    
    for _, shed in pairs(workspace.Buildings:GetChildren()) do
        if shed.Name == "LargeWoodenShed" then
            local storageRacks = shed:FindFirstChild("StorageRacks")
            if storageRacks then
                for _, rack in pairs(storageRacks:GetChildren()) do
                    if rack.Name == "StorageRack" then
                        local storage = rack:FindFirstChild("Storage")
                        if storage then
                            for i = 1, 3 do
                                local slot = storage:FindFirstChild(tostring(i))
                                if slot then
                                    local occupant = slot:FindFirstChild("Occupant")
                                    if not occupant or occupant.Value == "" then
                                        local distance = (humanoidRootPart.Position - slot.Position).Magnitude
                                        if distance < closestDistance then
                                            closestStorage = slot
                                            closestDistance = distance
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestStorage
end

-- تخزين WoolBundle
local function storeWoolBundle()
    local storageSpot = findStorageSpot()
    if storageSpot then
        if safeTeleport(storageSpot:GetPivot()) then
            local success = pcall(function()
                Larry.EVTRequestToDrop:FireServer()
            end)
            if success then
                debugPrint("تم التخزين بنجاح في "..storageSpot:GetFullName())
                return true
            end
        end
    end
    debugPrint("فشل في العثور على مكان تخزين مناسب")
    return false
end

-- الدورة الرئيسية
local function mainProcess()
    while true do
        debugPrint("\n=== بدء دورة جديدة ===")
        
        -- 1. العثور على المكينة
        local machine = findMyMachine()
        if not machine then
            wait(10)
            continue
        end
        
        -- 2. جمع الصوف
        local collected = collectWool()
        if collected == 0 then
            wait(5)
            continue
        end
        
        -- 3. وضع الصوف في المكينة
        safeTeleport(machine:GetPivot())
        pcall(function()
            Larry.EVTRequestToDrop:FireServer()
        end)
        
        -- 4. التحقق من السعة وتشغيل المكينة
        local capacity = machine.Configurations:FindFirstChild("Capacity")
        if capacity and capacity.Value >= 5 then
            if spinMachine(machine) then
                -- 5. جمع وتخزين WoolBundle
                if pickupWoolBundle() then
                    storeWoolBundle()
                end
            end
        end
        
        wait(5)
    end
end

-- بدء التشغيل
local success, err = pcall(mainProcess)
if not success then
    debugPrint("❌ حدث خطأ جسيم: "..err)
end

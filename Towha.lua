local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Larry = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Larry")

-- إعدادات الكود
local MAX_WOOL_TO_COLLECT = 5
local COLLECTION_INTERVAL = 1
local MACHINE_POSITION_OFFSET = CFrame.new(0, 0, 2)
local SPIN_TIME = 10 -- وقت انتظار تشغيل المكينة
local STORAGE_CHECK_INTERVAL = 1 -- وقت انتظار بين فحص المخازن

local function teleportTo(targetCFrame)
    humanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 3, 0)
    wait(0.5)
    humanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 0, 2)
    wait(0.5)
end

local function findMyMachine()
    for _, building in pairs(workspace.Buildings:GetChildren()) do
        if building.Name == "SpindleMachine" then
            local config = building:FindFirstChild("Configurations")
            if config then
                local owner = config:FindFirstChild("Owner")
                if owner and owner.Value == player.Name then
                    return building
                end
            end
        end
    end
    return nil
end

local function collectWool()
    local woolCount = 0
    
    for _, wool in pairs(workspace.DraggableObjects:GetChildren()) do
        if wool.Name == "Wool" and woolCount < MAX_WOOL_TO_COLLECT then
            teleportTo(wool:GetPivot())
            
            local args = { [1] = wool }
            local success, err = pcall(function()
                Larry:WaitForChild("EVTRequestToCarry"):FireServer(unpack(args))
            end)
            
            if success then
                woolCount = woolCount + 1
                print("تم جمع الصوف ("..woolCount.."/"..MAX_WOOL_TO_COLLECT..")")
            else
                print("فشل في جمع الصوف: "..err)
            end
            
            wait(COLLECTION_INTERVAL)
        end
    end
    
    return woolCount
end

local function spinMachine(machine)
    teleportTo(machine:GetPivot())
    
    local args = { [1] = machine }
    local success, err = pcall(function()
        Larry:WaitForChild("EVTAnimateSpindle"):FireServer(unpack(args))
    end)
    
    if success then
        print("تم تشغيل المكينة، انتظار "..SPIN_TIME.." ثانية...")
        wait(SPIN_TIME)
        return true
    else
        print("فشل في تشغيل المكينة: "..err)
        return false
    end
end

local function pickupWoolBundle()
    local woolBundle = workspace.DraggableObjects:FindFirstChild("WoolBundle")
    if not woolBundle then
        print("لم يتم العثور على WoolBundle")
        return false
    end
    
    teleportTo(woolBundle:GetPivot())
    
    local args = { [1] = woolBundle }
    local success, err = pcall(function()
        Larry:WaitForChild("EVTRequestToCarry"):FireServer(unpack(args))
    end)
    
    if success then
        print("تم التقاط WoolBundle بنجاح")
        return true
    else
        print("فشل في التقاط WoolBundle: "..err)
        return false
    end
end

local function findStorageForItem(itemName)
    -- البحث في جميع المخازن الكبيرة
    for _, shed in pairs(workspace.Buildings:GetChildren()) do
        if shed.Name == "LargeWoodenShed" then
            -- البحث في جميع الرفوف
            local racks = shed:FindFirstChild("StorageRacks")
            if racks then
                for _, rack in pairs(racks:GetChildren()) do
                    if rack.Name == "StorageRack" then
                        local storage = rack:FindFirstChild("Storage")
                        if storage then
                            -- البحث في جميع الأماكن التخزينية (1, 2, 3)
                            for i = 1, 3 do
                                local slot = storage:FindFirstChild(tostring(i))
                                if slot then
                                    local occupant = slot:FindFirstChild("Occupant")
                                    if occupant then
                                        -- إذا كان المكان فارغاً أو يحتوي على نفس العنصر
                                        if not occupant.Value or occupant.Value == itemName then
                                            return slot
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
    return nil
end

local function storeItemInStorage()
    local storageSpot = findStorageForItem("WoolBundle")
    if not storageSpot then
        print("لم يتم العثور على مكان تخزين مناسب")
        return false
    end
    
    teleportTo(storageSpot:GetPivot())
    
    local success, err = pcall(function()
        Larry:WaitForChild("EVTRequestToDrop"):FireServer()
    end)
    
    if success then
        print("تم تخزين WoolBundle في "..storageSpot:GetFullName())
        return true
    else
        print("فشل في تخزين WoolBundle: "..err)
        return false
    end
end

-- الدورة الرئيسية
while true do
    print("بدء دورة جديدة...")
    
    -- 1. جمع الصوف
    local collectedCount = collectWool()
    
    if collectedCount > 0 then
        -- 2. الذهاب إلى المكينة
        local machine = findMyMachine()
        if machine then
            -- 3. الإيداع في المكينة
            teleportTo(machine:GetPivot())
            Larry:WaitForChild("EVTRequestToDrop"):FireServer()
            
            -- 4. التحقق من سعة المكينة وتشغيلها إذا كانت ممتلئة
            local config = machine:FindFirstChild("Configurations")
            local capacity = config and config:FindFirstChild("Capacity")
            
            if capacity and capacity.Value >= 5 then
                if spinMachine(machine) then
                    -- 5. التقاط WoolBundle بعد التشغيل
                    if pickupWoolBundle() then
                        -- 6. تخزين WoolBundle في المخزن
                        storeItemInStorage()
                    end
                end
            end
        else
            print("لم يتم العثور على المكينة الخاصة بك")
        end
    else
        print("لا يوجد صوف للجمعه حالياً")
    end
    
    wait(5) -- انتظر قبل البدء بدورة جديدة
end

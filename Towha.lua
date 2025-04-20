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

-- وظيفة لطباعة معلومات التصحيح
local function debugPrint(message)
    print("[DEBUG] " .. os.date("%X") .. " " .. message)
end

-- وظيفة الانتقال الآمن
local function safeTeleport(targetCFrame)
    if not targetCFrame then 
        debugPrint("⚠️ لا يوجد هدف للانتقال إليه")
        return false 
    end
    
    local success, err = pcall(function()
        humanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 3, 0)
        wait(0.3)
        humanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 0, 2)
        wait(0.3)
    end)
    
    if not success then
        debugPrint("❌ فشل في الانتقال: " .. err)
    end
    return success
end

-- العثور على المكينة الخاصة بالمستخدم
local function findMyMachine()
    debugPrint("البحث عن مكينة الغزل الخاصة بي...")
    
    -- الطريقة الأولى: البحث المباشر
    local machine = workspace.Buildings:FindFirstChild("SpindleMachine")
    
    if machine then
        debugPrint("تم العثور على مكينة في: " .. machine:GetFullName())
        
        local config = machine:FindFirstChild("Configurations")
        if config then
            local owner = config:FindFirstChild("Owner")
            if owner then
                debugPrint("مالك المكينة: " .. owner.Value)
                if owner.Value == player.Name then
                    debugPrint("✓ هذه المكينة ملكي!")
                    return machine
                else
                    debugPrint("⚠️ المكينة مملوكة لشخص آخر")
                end
            else
                debugPrint("❌ لا يوجد خاصية Owner في التكوينات")
            end
        else
            debugPrint("❌ لا يوجد مجلد Configurations")
        end
    end
    
    debugPrint("❌ لم يتم العثور على المكينة الخاصة بي")
    return nil
end

-- جمع الصوف
local function collectWool()
    local collected = 0
    debugPrint("بدء جمع الصوف...")
    
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
                else
                    debugPrint("فشل في جمع الصوف")
                end
            end
            wait(CHECK_INTERVAL)
        end
    end
    
    return collected
end

-- تشغيل المكينة
local function spinMachine(machine)
    if not machine then return false end
    
    debugPrint("محاولة تشغيل المكينة...")
    if not safeTeleport(machine:GetPivot()) then return false end
    
    local args = {[1] = machine}
    local success = pcall(function()
        Larry.EVTAnimateSpindle:FireServer(unpack(args))
    end)
    
    if success then
        debugPrint("تم تشغيل المكينة، انتظار "..SPIN_TIME.." ثانية...")
        wait(SPIN_TIME)
        return true
    else
        debugPrint("❌ فشل في تشغيل المكينة")
        return false
    end
end

-- التقاط WoolBundle
local function pickupWoolBundle()
    debugPrint("البحث عن WoolBundle...")
    
    for _, bundle in pairs(workspace.DraggableObjects:GetChildren()) do
        if bundle.Name == "WoolBundle" then
            if safeTeleport(bundle:GetPivot()) then
                local args = {[1] = bundle}
                local success = pcall(function()
                    Larry.EVTRequestToCarry:FireServer(unpack(args))
                end)
                
                if success then
                    debugPrint("✓ تم جمع WoolBundle بنجاح")
                    return true
                end
            end
        end
    end
    
    debugPrint("❌ لم يتم العثور على WoolBundle")
    return false
end

-- البحث عن مكان تخزين مناسب
local function findStorageSpot()
    debugPrint("البحث عن مكان تخزين فارغ...")
    
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
                                        debugPrint("✓ وجد مكان تخزين فارغ في الرف "..i)
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
    
    debugPrint("❌ لم يتم العثور على أماكن تخزين فارغة")
    return nil
end

-- تخزين WoolBundle
local function storeWoolBundle()
    local storageSpot = findStorageSpot()
    if not storageSpot then return false end
    
    if safeTeleport(storageSpot:GetPivot()) then
        local success = pcall(function()
            Larry.EVTRequestToDrop:FireServer()
        end)
        
        if success then
            debugPrint("✓ تم تخزين WoolBundle بنجاح في "..storageSpot:GetFullName())
            return true
        else
            debugPrint("❌ فشل في تخزين WoolBundle")
        end
    end
    return false
end

-- الدورة الرئيسية
local function mainProcess()
    debugPrint("بدء تشغيل السكربت التجريبي...")
    
    while true do
        debugPrint("\n"..string.rep("=", 50))
        debugPrint("بدء دورة عمل جديدة")
        
        -- 1. العثور على المكينة
        local machine = findMyMachine()
        if not machine then
            debugPrint("انتظار 10 ثواني قبل المحاولة مجدداً...")
            wait(10)
            continue
        end
        
        -- 2. جمع الصوف
        local collected = collectWool()
        if collected == 0 then
            debugPrint("لا يوجد صوف متاح للجمع حالياً")
            wait(5)
            continue
        end
        
        -- 3. وضع الصوف في المكينة
        if safeTeleport(machine:GetPivot()) then
            pcall(function()
                Larry.EVTRequestToDrop:FireServer()
            end)
        end
        
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
        
        wait(5) -- انتظار بين الدورات
    end
end

-- بدء التشغيل الآمن
local success, err = pcall(mainProcess)
if not success then
    debugPrint("❌❌ حدث خطأ جسيم: "..err)
    debugPrint("تتبع الخطأ: "..debug.traceback())
end

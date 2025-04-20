-- تأكد من أن هذه السكريبت تعمل في بيئة exploit مثل Synapse أو Krnl
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Larry = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Larry")

-- إعدادات الكود
local MAX_WOOL_TO_COLLECT = 5
local SPIN_TIME = 10 -- وقت انتظار تشغيل المكينة
local CHECK_INTERVAL = 1 -- وقت الانتظار بين الفحص

-- وظيفة الانتقال الآمن
local function teleportTo(targetCFrame)
    pcall(function()
        humanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 3, 0) -- الانتقال أعلى الهدف
        wait(0.3)
        humanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 0, 2) -- النزول أمام الهدف
        wait(0.3)
    end)
end

-- وظيفة العثور على المكينة الخاصة باللاعب
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

-- وظيفة جمع الصوف
local function collectWool()
    local collected = 0
    for _, wool in pairs(workspace.DraggableObjects:GetChildren()) do
        if wool.Name == "Wool" and collected < MAX_WOOL_TO_COLLECT then
            teleportTo(wool:GetPivot())
            
            local args = {[1] = wool}
            local success = pcall(function()
                Larry.EVTRequestToCarry:FireServer(unpack(args))
            end)
            
            if success then
                collected = collected + 1
                print("تم جمع الصوف ("..collected.."/"..MAX_WOOL_TO_COLLECT..")")
            end
            
            wait(CHECK_INTERVAL)
        end
    end
    return collected
end

-- وظيفة تشغيل المكينة
local function spinMachine(machine)
    teleportTo(machine:GetPivot())
    
    local args = {[1] = machine}
    local success = pcall(function()
        Larry.EVTAnimateSpindle:FireServer(unpack(args))
    end)
    
    if success then
        print("تم تشغيل المكينة، انتظار "..SPIN_TIME.." ثانية...")
        wait(SPIN_TIME)
        return true
    end
    return false
end

-- وظيفة جمع WoolBundle
local function pickupWoolBundle()
    for _, bundle in pairs(workspace.DraggableObjects:GetChildren()) do
        if bundle.Name == "WoolBundle" then
            teleportTo(bundle:GetPivot())
            
            local args = {[1] = bundle}
            local success = pcall(function()
                Larry.EVTRequestToCarry:FireServer(unpack(args))
            end)
            
            if success then
                print("تم جمع WoolBundle")
                return true
            end
        end
    end
    return false
end

-- وظيفة تخزين WoolBundle
local function storeWoolBundle()
    for _, shed in pairs(workspace.Buildings:GetChildren()) do
        if shed.Name == "LargeWoodenShed" then
            local racks = shed:FindFirstChild("StorageRacks")
            if racks then
                for _, rack in pairs(racks:GetChildren()) do
                    if rack.Name == "StorageRack" then
                        local storage = rack:FindFirstChild("Storage")
                        if storage then
                            for i = 1, 3 do
                                local slot = storage:FindFirstChild(tostring(i))
                                if slot then
                                    local occupant = slot:FindFirstChild("Occupant")
                                    if not occupant or occupant.Value == "" then
                                        teleportTo(slot:GetPivot())
                                        
                                        local success = pcall(function()
                                            Larry.EVTRequestToDrop:FireServer()
                                        end)
                                        
                                        if success then
                                            print("تم تخزين WoolBundle في الرف "..i)
                                            return true
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
    return false
end

-- الدورة الرئيسية
local running = true
while running do
    print("بدء دورة جديدة...")
    
    -- 1. جمع الصوف
    local collected = collectWool()
    
    if collected > 0 then
        -- 2. الذهاب إلى المكينة
        local machine = findMyMachine()
        if machine then
            -- 3. وضع الصوف في المكينة
            teleportTo(machine:GetPivot())
            pcall(function()
                Larry.EVTRequestToDrop:FireServer()
            end)
            
            -- 4. تشغيل المكينة إذا كانت ممتلئة
            local config = machine:FindFirstChild("Configurations")
            local capacity = config and config:FindFirstChild("Capacity")
            
            if capacity and capacity.Value >= 5 then
                if spinMachine(machine) then
                    -- 5. جمع WoolBundle الناتج
                    if pickupWoolBundle() then
                        -- 6. تخزين WoolBundle
                        storeWoolBundle()
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

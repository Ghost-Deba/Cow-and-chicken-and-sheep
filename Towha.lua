local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

local Window = Rayfield:CreateWindow({
    Name = "Farm With Friends",
    LoadingTitle = "Welcome",
    LoadingSubtitle = "By Ghost & Iron",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "FarmAutomation",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    }
})

-- Main Toggle
local MainToggle = Window:CreateTab("Main Controls", 4483362458)

-- Cow Milking Section
local CowSection = MainToggle:CreateSection("Cow Milking")
local CowToggle = MainToggle:CreateToggle({
    Name = "Auto Milk Cows",
    CurrentValue = false,
    Flag = "CowToggle",
    Callback = function(Value)
        if Value then
            StartCowMilking()
        else
            StopCowMilking()
        end
    end,
})

-- Chicken Section
local ChickenSection = MainToggle:CreateSection("Chicken Eggs")
local ChickenToggle = MainToggle:CreateToggle({
    Name = "Auto Collect Eggs",
    CurrentValue = false,
    Flag = "ChickenToggle",
    Callback = function(Value)
        if Value then
            StartEggCollection()
        else
            StopEggCollection()
        end
    end,
})

-- Sheep Shearing Section
local SheepSection = MainToggle:CreateSection("Sheep Shearing")
local SheepToggle = MainToggle:CreateToggle({
    Name = "Auto Shear Sheep",
    CurrentValue = false,
    Flag = "SheepToggle",
    Callback = function(Value)
        if Value then
            StartSheepShearing()
        else
            StopSheepShearing()
        end
    end,
})

-- Wool Collection Section
local WoolSection = MainToggle:CreateSection("Wool Collection")
local WoolToggle = MainToggle:CreateToggle({
    Name = "Auto Collect Wool",
    CurrentValue = false,
    Flag = "WoolToggle",
    Callback = function(Value)
        if Value then
            StartWoolCollection()
        else
            StopWoolCollection()
        end
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local SettingsSection = SettingsTab:CreateSection("Configuration")

local CowInterval = SettingsTab:CreateInput({
    Name = "Cow Check Interval (seconds)",
    PlaceholderText = "60",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        CowCheckInterval = tonumber(Text) or 60
    end,
})

local ChickenIntervalInput = SettingsTab:CreateInput({
    Name = "Chicken Check Interval (seconds)",
    PlaceholderText = "60",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        ChickenCheckInterval = tonumber(Text) or 60
    end,
})

local SheepIntervalInput = SettingsTab:CreateInput({
    Name = "Sheep Check Interval (seconds)",
    PlaceholderText = "60",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        SheepCheckInterval = tonumber(Text) or 60
    end,
})

local WoolIntervalInput = SettingsTab:CreateInput({
    Name = "Wool Collect Interval (seconds)",
    PlaceholderText = "5",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        WoolCollectInterval = tonumber(Text) or 5
    end,
})

local UsernameInput = SettingsTab:CreateInput({
    Name = "Your Username",
    PlaceholderText = "Enter your username",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        PlayerUsername = Text
    end,
})

-- Initialize variables
local CowCheckInterval = 60
local ChickenCheckInterval = 60
local SheepCheckInterval = 60
local WoolCollectInterval = 5
local PlayerUsername = game.Players.LocalPlayer.Name

local CowMilkingRunning = false
local EggCollectionRunning = false
local SheepShearingRunning = false
local WoolCollectionRunning = false

-- Cow Milking Functions (كما هي)
function StartCowMilking()
    if CowMilkingRunning then return end
    CowMilkingRunning = true
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Larry = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Larry")
    local Animals = workspace:WaitForChild("Animals")
    local Barn = workspace:WaitForChild("Buildings"):WaitForChild("AutoWoodenBarn")

    -- Get all 12 gates
    local gates = {}
    for i = 1, 12 do
        table.insert(gates, Barn:WaitForChild("AnimalContainer"):WaitForChild("Spots"):WaitForChild(tostring(i)):WaitForChild("Gate"))
    end

    -- Table to store entered cows
    local enteredCows = {}

    -- Function to milk cows
    local function milkCows()
        enteredCows = {}
        local cowsToEnter = {}

        -- Check compatible cows
        for _, cow in pairs(Animals:GetChildren()) do
            if cow.Name == "Cow" then
                local config = cow:FindFirstChild("Configurations")
                if config and config:FindFirstChild("Production") and config.Production.Value == 300 then
                    table.insert(cowsToEnter, cow)
                end
            end
        end

        -- Enter first 12 cows
        for i = 1, 12 do
            if cowsToEnter[i] then
                local enterArgs = {
                    [1] = {
                        [1] = cowsToEnter[i]
                    },
                    [2] = Barn
                }
                Larry:WaitForChild("EVTHerdRequest"):FireServer(unpack(enterArgs))
                table.insert(enteredCows, cowsToEnter[i])
            end
        end

        -- Milk all cows at once
        for _, cow in pairs(enteredCows) do
            local milkArgs = {
                [1] = "Milk",
                [2] = cow
            }
            Larry:WaitForChild("EVTCollectAnimalProduction"):FireServer(unpack(milkArgs))
        end

        wait(1)

        -- Open gates to release cows
        for i = 1, 12 do
            local gateArgs = {
                [1] = gates[i]
            }
            Larry:WaitForChild("EVTOpenBarnGate"):FireServer(unpack(gateArgs))
        end

        wait(2)

        -- Enter remaining 8 cows
        local enteredSecondBatch = {}
        for i = 13, 20 do
            if cowsToEnter[i] then
                local enterArgs = {
                    [1] = {
                        [1] = cowsToEnter[i]
                    },
                    [2] = Barn
                }
                Larry:WaitForChild("EVTHerdRequest"):FireServer(unpack(enterArgs))
                table.insert(enteredSecondBatch, cowsToEnter[i])
            end
        end

        wait(2)

        -- Milk remaining cows
        for _, cow in pairs(enteredSecondBatch) do
            local milkArgs = {
                [1] = "Milk",
                [2] = cow
            }
            Larry:WaitForChild("EVTCollectAnimalProduction"):FireServer(unpack(milkArgs))
        end

        wait(1)

        -- Release remaining cows
        for i = 1, #enteredSecondBatch do
            local gateArgs = {
                [1] = gates[i]
            }
            Larry:WaitForChild("EVTOpenBarnGate"):FireServer(unpack(gateArgs))
        end
    end

    -- Main loop
    while CowMilkingRunning do
        milkCows()
        wait(CowCheckInterval)
    end
end

function StopCowMilking()
    CowMilkingRunning = false
end

-- Chicken Egg Collection Functions (كما هي)
function StartEggCollection()
    if EggCollectionRunning then return end
    EggCollectionRunning = true
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Larry = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Larry")
    local Buildings = workspace:WaitForChild("Buildings")
    local coopTypeName = "MediumChickenCoop"
    local maxEggCapacity = 72

    local function collectEggsWhenFull()
        for _, coop in ipairs(Buildings:GetChildren()) do
            if coop.Name == coopTypeName then
                local config = coop:FindFirstChild("Configurations")
                if config and config:FindFirstChild("EggCapacity") then
                    local eggCapacity = config.EggCapacity.Value
                    if eggCapacity >= maxEggCapacity then
                        local args = {
                            [1] = "Eggs",
                            [2] = coop
                        }
                        Larry:WaitForChild("EVTCollectAnimalProduction"):FireServer(unpack(args))
                        Rayfield:Notify({
                            Title = "Eggs Collected",
                            Content = "Collected eggs from "..coop:GetFullName(),
                            Duration = 3,
                            Image = 4483362458,
                        })
                    end
                end
            end
        end
    end

    while EggCollectionRunning do
        collectEggsWhenFull()
        wait(ChickenCheckInterval)
    end
end

function StopEggCollection()
    EggCollectionRunning = false
end

-- Sheep Shearing Functions (كما هي)
function StartSheepShearing()
    if SheepShearingRunning then return end
    SheepShearingRunning = true
    
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Larry = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Larry")

    -- دالة لإمساك المقص
    local function grabShears()
        local shears = workspace.DraggableObjects:FindFirstChild("Shears")
        if not shears then
            print("المقص غير متاح")
            return false
        end
        
        local args = { [1] = shears }
        
        local success, err = pcall(function()
            Larry:WaitForChild("EVTRequestToCarry"):FireServer(unpack(args))
        end)
        
        if success then
            print("تم إمساك المقص بنجاح")
            return true
        else
            print("حدث خطأ أثناء محاولة إمساك المقص: "..err)
            return false
        end
    end

    -- دالة لقص صوف خروف معين
    local function shearSheep(sheep)
        -- التحقق من وجود تكوينات الإنتاج
        local configurations = sheep:FindFirstChild("Configurations")
        if not configurations then
            print("لا يوجد تكوينات للخروف")
            return false
        end
        
        local production = configurations:FindFirstChild("Production")
        if not production then
            print("لا يوجد إنتاج للخروف")
            return false
        end
        
        -- التحقق من أن الإنتاج 100%
        if production.Value < 100 then
            print("الصوف ليس جاهزًا للقص (الإنتاج: "..production.Value.."%)")
            return false
        end
        
        -- الانتقال إلى الخروف
        humanoidRootPart.CFrame = sheep.PrimaryPart.CFrame * CFrame.new(0, 0, 2)
        wait(0.5) -- انتظر قليلاً للاستقرار
        
        -- قص الصوف
        local args = {
            [1] = "Wool",
            [2] = sheep
        }
        
        local success, err = pcall(function()
            Larry:WaitForChild("EVTCollectAnimalProduction"):FireServer(unpack(args))
        end)
        
        if success then
            Rayfield:Notify({
                Title = "Sheep Sheared",
                Content = "Successfully sheared sheep: "..sheep:GetFullName(),
                Duration = 3,
                Image = 4483362458,
            })
            return true
        else
            print("حدث خطأ أثناء قص الصوف: "..err)
            return false
        end
    end

    -- Main shearing function
    local function shearAllSheep()
        -- First grab shears
        if not grabShears() then
            return
        end
        
        wait(1) -- Wait for shears to be grabbed
        
        -- Find all sheep
        local sheepList = workspace.Animals:GetChildren()
        local sheepCount = 0
        local shearedCount = 0
        
        for _, animal in ipairs(sheepList) do
            if animal.Name == "Sheep" then
                sheepCount = sheepCount + 1
                
                -- Shear the sheep
                if shearSheep(animal) then
                    shearedCount = shearedCount + 1
                end
                
                wait(1) -- Wait before moving to next sheep
            end
        end
        
        if sheepCount > 0 then
            Rayfield:Notify({
                Title = "Shearing Complete",
                Content = string.format("Sheared %d/%d sheep", shearedCount, sheepCount),
                Duration = 5,
                Image = 4483362458,
            })
        else
            print("No sheep found for shearing")
        end
    end

    -- Main loop
    while SheepShearingRunning do
        shearAllSheep()
        wait(SheepCheckInterval)
    end
end

function StopSheepShearing()
    SheepShearingRunning = false
end

-- Wool Collection Functions (المعدلة)
function StartWoolCollection()
    if WoolCollectionRunning then return end
    WoolCollectionRunning = true
    
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Larry = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Larry")

    local function findMyMachine()
        for _, building in pairs(workspace.Buildings:GetChildren()) do
            if building.Name == "SpindleMachine" then
                local config = building:FindFirstChild("Configurations")
                if config then
                    local owner = config:FindFirstChild("Owner")
                    if owner and owner.Value == PlayerUsername then
                        return building
                    end
                end
            end
        end
        return nil
    end

    local function spinMachine(machine)
        humanoidRootPart.CFrame = machine:GetPivot() * CFrame.new(0, 0, 2)
        wait(0.5)
        
        local args = { [1] = machine }
        local success = pcall(function()
            Larry:WaitForChild("EVTAnimateSpindle"):FireServer(unpack(args))
        end)
        
        if success then
            Rayfield:Notify({
                Title = "Machine Started",
                Content = "Spinning machine activated",
                Duration = 3,
                Image = 4483362458,
            })
            return true
        end
        return false
    end

    local function collectAndSpin()
        -- جمع الصوف
        for _, wool in pairs(workspace.DraggableObjects:GetChildren()) do
            if wool.Name == "Wool" then
                -- الانتقال إلى الصوف
                humanoidRootPart.CFrame = wool:GetPivot() * CFrame.new(0, 0, 2)
                wait(0.5)
                
                -- جمع الصوف
                local args = { [1] = wool }
                local success = pcall(function()
                    Larry:WaitForChild("EVTRequestToCarry"):FireServer(unpack(args))
                end)
                
                if success then
                    Rayfield:Notify({
                        Title = "Wool Collected",
                        Content = "Successfully collected wool",
                        Duration = 2,
                        Image = 4483362458,
                    })
                    
                    -- البحث عن المكينة
                    local machine = findMyMachine()
                    if machine then
                        -- وضع الصوف في المكينة
                        humanoidRootPart.CFrame = machine:GetPivot() * CFrame.new(0, 0, 2)
                        wait(0.5)
                        
                        pcall(function()
                            Larry:WaitForChild("EVTRequestToDrop"):FireServer()
                        end)
                        
                        -- التحقق من سعة المكينة وتشغيلها إذا كانت ممتلئة
                        local capacity = machine.Configurations:FindFirstChild("Capacity")
                        if capacity and capacity.Value >= 5 then
                            spinMachine(machine)
                        end
                    end
                end
            end
        end
    end

    while WoolCollectionRunning do
        collectAndSpin()
        wait(WoolCollectInterval)
    end
end

function StopWoolCollection()
    WoolCollectionRunning = false
end

-- Initialize default values
CowInterval:Set("60")
ChickenIntervalInput:Set("60")
SheepIntervalInput:Set("60")
WoolIntervalInput:Set("5")
UsernameInput:Set(game.Players.LocalPlayer.Name)

Rayfield:Notify({
    Title = "Farm Helper Loaded",
    Content = "Ready to automate your farming!",
    Duration = 5,
    Image = 4483362458,
})

-- Wait for Config to be loaded
while not Config do
    Wait(100)
end

local currentHouse = nil
local housesData = {}
local doingAction = false
local InTheHouse = false
local propRobbed = {}
local SpawnedObject = {}
local CreatedProps = {}
local PedSpawned = {}
local PedDead = {}
local leaving = false
local Lockpicking = false
local NPC = nil
local duffelBagSlots = 0
local insideTargets = {}
local stealthSystemActive = false

-- Ancient Statue Carrying System Variables
local carryingStatue = false
local statueProp = nil
local statueData = nil
local nearbyVehicles = {}
local movementRestricted = false

-- Helper function to get house data with flexible structure
function getHouseData(house)
    local houseConfig = Config.HousesToRob[house]
    if not houseConfig then return nil end
    
    -- If using old Residence structure, return that
    if houseConfig.Residence then
        return houseConfig.Residence
    end
    
    -- Otherwise return the house config directly
    return houseConfig
end

-- Helper function to get inside positions
function getInsidePositions(house)
    local houseData = getHouseData(house)
    return houseData and houseData.InsidePositions
end

-- Helper function to get safes
function getSafes(house)
    local houseData = getHouseData(house)
    return houseData and houseData.Safes or {}
end

-- Helper function to get static props
function getStaticProps(house)
    local houseData = getHouseData(house)
    return houseData and houseData.StaticProps or {}
end

-- Helper function to get created props
function getCreatedProps(house)
    local houseData = getHouseData(house)
    return houseData and houseData.CreateProps or {}
end

-- Helper function to get ped config
function getPedConfig(house)
    local houseData = getHouseData(house)
    return houseData and houseData.Ped
end

-- Helper function to get report chance
function getReportChance(house)
    local houseData = getHouseData(house)
    return houseData and houseData.ReportChanceWhenEntering or 50
end

-- Helper function to get needed police count
function getNeededPoliceCount(house)
    local houseData = getHouseData(house)
    return houseData and houseData.NeedPoliceCount or 0
end

-- FIXED: Enhanced cleanup function
function cleanupCarryingState()
    print("^3[DEBUG] Cleaning up carrying state^7")
    
    -- Reset all carrying variables
    carryingStatue = false
    movementRestricted = false
    statueData = nil
    
    -- Remove carried prop
    if DoesEntityExist(statueProp) then
        DetachEntity(statueProp, true, false)
        DeleteEntity(statueProp)
        statueProp = nil
        print("^3[DEBUG] Deleted carried statue prop^7")
    end
    
    -- Reset movement speed
    SetPedMoveRateOverride(PlayerPedId(), 1.0)
    
    -- Clear tasks and animations
    ClearPedTasks(PlayerPedId())
    ClearPedSecondaryTask(PlayerPedId())
    
    -- Hide UI
    lib.hideTextUI()
    
    print("^3[DEBUG] Carrying state cleanup complete^7")
end

RegisterNetEvent("marz_houserobbery:reset")
AddEventHandler("marz_houserobbery:reset", function(house)
    -- Enhanced cleanup for statue carrying
    cleanupCarryingState()
    
    for _, v in pairs(CreatedProps) do
        SetEntityAsMissionEntity(v, false, true)
        DeleteObject(v)
        if DoesEntityExist(v) then
            TriggerServerEvent("marz_houserobbery:removeobject", ObjToNet(v))
        end
    end
    
    cleanupInsideTargets()
    
    -- Stop stealth system if active
    if stealthSystemActive then
        if exports['marz_houserobbery'] and exports['marz_houserobbery']['StopStealthSystem'] then
            StopStealthSystem()
        end
        stealthSystemActive = false
    end
    
    housesData[house] = nil
    propRobbed[house] = nil
    SpawnedObject[house] = nil
    CreatedProps[house] = nil
    PedSpawned[house] = nil
    PedDead[house] = nil
    duffelBagSlots = 0
    NPC = nil
    
    -- Reset stealth system for this house
    if exports['marz_houserobbery'] and exports['marz_houserobbery']['ResetStealthSystem'] then
        ResetStealthSystem(house)
    end
end)

RegisterNetEvent("marz_houserobbery:sync")
AddEventHandler("marz_houserobbery:sync", function(data, requestedInstance)
    housesData = data
    if requestedInstance then
        lib.callback('marz_houserobbery:getident', false, function(value)
            local char = value
            for house, houseData in pairs(housesData) do
                if houseData.players then
                    for _, player in pairs(houseData.players) do
                        if player == char then
                            teleport(Config.HousesToRob[house].Coords.xyz)
                            TriggerServerEvent("marz_houserobbery:leaveHouse", house)
                            break
                        end
                    end
                end
            end
        end)
    end
end)

function hasDuffelBag()
    if not Config.RequireDuffelBag then return true end
    
    local hasItem = false
    lib.callback('marz_houserobbery:getitem', false, function(value)
        hasItem = value
    end, Config.DuffelBagItem, 1)
    
    Wait(200)
    return hasItem
end

function duffelBagHasSpace()
    return duffelBagSlots < Config.MaxDuffelCapacity
end

function addToDuffelBag()
    duffelBagSlots = duffelBagSlots + 1
end

function cleanupInsideTargets()
    if Config.InteractionType == 'target' then
        local target = exports[Config.Target]
        for _, targetId in pairs(insideTargets) do
            if targetId then
                target:removeZone(targetId)
            end
        end
        insideTargets = {}
    end
end

function isItemAlreadyRobbed(house, itemKey)
    if not housesData[house] or not housesData[house].robbed then
        return false
    end
    
    for _, robbedItem in pairs(housesData[house].robbed) do
        if robbedItem == itemKey then
            return true
        end
    end
    return false
end

-- Outside house interactions
if Config.HouseType == "AllHouses" and Config.InteractionType == 'target' then
    for house, data in pairs(Config.HousesToRob) do
        SetTimeout(1000, function()
            local target = exports[Config.Target]
            target:addBoxZone({
                coords = data.Coords.xyz,
                size = vec3(3, 3, 3),
                rotation = 0,
                debug = Config.Debug,
                options = {
                    {
                        name = "marz_houserobbery_break" .. house,
                        icon = 'fas fa-house',
                        label = 'Break into house',
                        onSelect = function()
                            enterHouse(house, true)
                        end,
                        canInteract = function()
                            return (housesData and not enterable(house))
                        end
                    },
                    {
                        name = "marz_houserobbery_enter" .. house,
                        icon = 'fas fa-door-open',
                        label = 'Enter house',
                        onSelect = function()
                            enterHouse(house, false)
                        end,
                        canInteract = function()
                            return (housesData and enterable(house))
                        end
                    }
                },
                distance = 2.5,
            })
        end)
    end
end

function enterable(house)
    if housesData[house] == nil or housesData[house].locked == nil or housesData[house].locked then
        return false
    end
    return true
end

function enterHouse(house, locked)
    if locked then
        -- Add debug logging
        if Config.Debug then
            print("Attempting to break into house:", house)
        end

        -- Validate house configuration exists
        if not Config.HousesToRob[house] then
            lib.notify({
                title = 'House Robbery',
                description = 'Invalid house configuration',
                type = 'error'
            })
            return
        end

        -- Validate InsidePositions exists
        local insidePositions = getInsidePositions(house)
        
        if not insidePositions then
            lib.notify({
                title = 'House Robbery',
                description = 'House interior not configured',
                type = 'error'
            })
            return
        end

        if Config.NightRob.enabled then
            local h = GetClockHours()
            if Config.NightRob.time.from > Config.NightRob.time.to then
                if h < Config.NightRob.time.from and h >= Config.NightRob.time.to then
                    lib.notify({
                        title = 'House Robbery',
                        description = 'You can only rob houses at night',
                        type = 'error'
                    })
                    return
                end
            else
                if h < Config.NightRob.time.from or h >= Config.NightRob.time.to then
                    lib.notify({
                        title = 'House Robbery',
                        description = 'You can only rob houses at night',
                        type = 'error'
                    })
                    return
                end
            end
        end

        if Config.RequireDuffelBag then
            local hasBag = false
            lib.callback('marz_houserobbery:getitem', false, function(value)
                hasBag = value
            end, Config.DuffelBagItem, 1)
            
            Wait(300)
            
            if not hasBag then
                lib.notify({
                    title = 'House Robbery',
                    description = 'You need a duffel bag to rob houses (Item: ' .. Config.DuffelBagItem .. ')',
                    type = 'error'
                })
                return
            end
        end

        -- Check for lockpick before showing context menu
        local hasLockpick = false
        lib.callback('marz_houserobbery:getitem', false, function(value)
            hasLockpick = value
        end, 'lockpick', 1)
        
        Wait(300)
        
        if not hasLockpick then
            lib.notify({
                title = 'House Robbery',
                description = 'You need a lockpick to break into houses',
                type = 'error'
            })
            return
        end

        if Config.Debug then
            print("All checks passed, showing context menu for house:", house)
        end

        if Config.Context == "ox_lib" then
            lib.registerContext({
                id = 'marz_robbery_house',
                title = 'House Robbery',
                options = {
                    {
                        title = 'Break into house',
                        description = 'Requirements: 1x lockpick',
                        icon = 'fas fa-door-closed',
                        event = 'marz_houserobbery:serverlockpick',
                        args = { house = house },
                        onSelect = function()
                            if Config.Debug then
                                print("Context menu option selected for house:", house)
                            end
                        end
                    }
                }
            })
            lib.showContext('marz_robbery_house')
        else
            -- Fallback for other context systems or direct trigger
            if Config.Debug then
                print("Using fallback method, triggering lockpick directly")
            end
            TriggerEvent('marz_houserobbery:serverlockpick', { house = house })
        end
    else
        -- Get inside positions
        local insidePositions = getInsidePositions(house)
        
        if not insidePositions or not insidePositions.Exit then
            lib.notify({
                title = 'House Robbery',
                description = 'House interior configuration error',
                type = 'error'
            })
            return
        end

        currentHouse = house
        teleport(insidePositions.Exit.coords)
        
        SetTimeout(2000, function()
            createInsideTargets(house)
            TriggerServerEvent("marz_houserobbery:joinHouse", house)
            DoorSound()
            duffelBagSlots = 0
        end)
    end
end

RegisterNetEvent("marz_houserobbery:serverlockpick")
AddEventHandler("marz_houserobbery:serverlockpick", function(data)
    if Config.Debug then
        print("Server lockpick event triggered with data:", json.encode(data))
    end
    
    -- Additional safety check
    if not data or not data.house then
        print("ERROR: Invalid house data in lockpick event")
        lib.notify({
            title = 'Error',
            description = 'Invalid house data - check console',
            type = 'error'
        })
        return
    end
    
    if Config.Debug then
        print("Triggering server event for house:", data.house)
    end
    
    TriggerServerEvent("marz_houserobbery:lockpick", data.house)
end)

function searchPlace(currentPlace)
    if not hasDuffelBag() then
        lib.notify({
            title = 'House Robbery',
            description = 'You need a duffel bag to store items',
            type = 'error'
        })
        return
    end

    if not duffelBagHasSpace() then
        lib.notify({
            title = 'House Robbery',
            description = 'Your duffel bag is full! (Max: ' .. Config.MaxDuffelCapacity .. ' items)',
            type = 'error'
        })
        return
    end

    if isItemAlreadyRobbed(currentHouse, currentPlace) then
        lib.notify({
            title = 'House Robbery',
            description = 'This place is empty!',
            type = 'error'
        })
        return
    end
    
    doingAction = true
    local insidePositions = getInsidePositions(currentHouse)
    TaskTurnPedToFaceCoord(cache.ped, insidePositions[currentPlace].coords, 1000)
    TaskStartScenarioInPlace(cache.ped, "PROP_HUMAN_BUM_BIN", 0, true)
    
    -- Increase noise from searching
    if stealthSystemActive and exports['marz_houserobbery'] and exports['marz_houserobbery']['IncreaseNoise'] then
        IncreaseNoise(4.0)
    end
    
    if lib.progressBar({
        duration = 4000,
        label = 'Searching location...',
        useWhileDead = false,
        canCancel = false,
    }) then
        ClearPedTasks(cache.ped)
        TriggerServerEvent("marz_houserobbery:robbedHousePlace", currentHouse, currentPlace)
        addToDuffelBag()
    end
    doingAction = false
end

function takeStaticProp(house, propKey, propData)
    if not hasDuffelBag() then
        lib.notify({
            title = 'House Robbery',
            description = 'You need a duffel bag to store items',
            type = 'error'
        })
        return
    end

    if not duffelBagHasSpace() then
        lib.notify({
            title = 'House Robbery',
            description = 'Your duffel bag is full! (Max: ' .. Config.MaxDuffelCapacity .. ' items)',
            type = 'error'
        })
        return
    end

    if isItemAlreadyRobbed(house, propKey) then
        lib.notify({
            title = 'House Robbery',
            description = 'This item was already taken!',
            type = 'error'
        })
        return
    end

    doingAction = true
    TaskStartScenarioInPlace(cache.ped, "PROP_HUMAN_BUM_BIN", 0, true)
    
    -- Increase noise from taking items
    if stealthSystemActive and exports['marz_houserobbery'] and exports['marz_houserobbery']['IncreaseNoise'] then
        IncreaseNoise(3.0)
    end
    
    if lib.progressBar({
        duration = 4000,
        label = 'Taking ' .. propData.Label .. '...',
        useWhileDead = false,
        canCancel = false,
    }) then
        ClearPedTasks(cache.ped)
        TriggerServerEvent("marz_houserobbery:robbedpropstatic", propData.model, house, propKey, nil, false)
        addToDuffelBag()
    end
    doingAction = false
end

-- FIXED: Modified takeCreatedProp function with proper statue handling
function takeCreatedProp(house, propKey, propData, object)
    if not hasDuffelBag() then
        lib.notify({
            title = 'House Robbery',
            description = 'You need a duffel bag to store items',
            type = 'error'
        })
        return
    end

    if isItemAlreadyRobbed(house, propKey) then
        lib.notify({
            title = 'House Robbery',
            description = 'This item was already taken!',
            type = 'error'
        })
        return
    end

    -- Special handling for Ancient Statue
    if propKey == "statue" and propData.NeedTrunk then
        if carryingStatue then
            lib.notify({
                title = 'House Robbery',
                description = 'You are already carrying the statue!',
                type = 'error'
            })
            return
        end
        
        startCarryingStatue(house, propKey, propData, object)
        return
    end

    -- Regular handling for other created props
    if not duffelBagHasSpace() then
        lib.notify({
            title = 'House Robbery',
            description = 'Your duffel bag is full! (Max: ' .. Config.MaxDuffelCapacity .. ' items)',
            type = 'error'
        })
        return
    end

    doingAction = true
    TaskTurnPedToFaceCoord(cache.ped, propData.Coords.xyz, 1000)
    
    local clip = "grab"
    local dict = "anim@scripted@heist@ig1_table_grab@cash@male@"
    RequestAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do Wait(0) end
    TaskPlayAnim(cache.ped, dict, clip, 3.0, 1.0, -1, 49, 0, false, false, false)
    
    -- Increase noise from taking items
    if stealthSystemActive and exports['marz_houserobbery'] and exports['marz_houserobbery']['IncreaseNoise'] then
        IncreaseNoise(3.0)
    end
    
    if lib.progressBar({
        duration = 1500,
        label = 'Taking ' .. propData.Label .. '...',
        useWhileDead = false,
        canCancel = false,
    }) then
        ClearPedTasks(cache.ped)
        if DoesEntityExist(object) then
            TriggerServerEvent("marz_houserobbery:robbedpropcreated", propData.model, house, propKey, ObjToNet(object), false)
            SetEntityAlpha(object, 0, false)
            DeleteEntity(object)
        end
        addToDuffelBag()
    end
    doingAction = false
end

-- Function to start carrying the Ancient Statue
function startCarryingStatue(house, propKey, propData, object)
    doingAction = true
    carryingStatue = true
    movementRestricted = true
    statueData = {
        house = house,
        propKey = propKey,
        propData = propData,
        originalObject = object
    }
    
    TaskTurnPedToFaceCoord(cache.ped, propData.Coords.xyz, 1000)
    
    -- Increase noise significantly - statue is heavy!
    if stealthSystemActive and exports['marz_houserobbery'] and exports['marz_houserobbery']['IncreaseNoise'] then
        IncreaseNoise(propData.NoiseLevel or 10.0)
    end
    
    if lib.progressBar({
        duration = 4000,
        label = 'Lifting ' .. propData.Label .. '...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = false,
            combat = true,
        },
    }) then
        ClearPedTasks(cache.ped)
        
        -- Hide the original statue
        if DoesEntityExist(object) then
            SetEntityAlpha(object, 0, false)
        end
        
        -- Create carried statue prop
        RequestModel(propData.model)
        while not HasModelLoaded(propData.model) do Wait(0) end
        
        statueProp = CreateObject(propData.model, 0.0, 0.0, 0.0, true, true, false)
        
        -- Attach statue to player
        local boneIndex = GetPedBoneIndex(cache.ped, propData.propPlacement.bone)
        AttachEntityToEntity(
            statueProp, cache.ped, boneIndex,
            propData.propPlacement.pos.x, propData.propPlacement.pos.y, propData.propPlacement.pos.z,
            propData.propPlacement.rot.x, propData.propPlacement.rot.y, propData.propPlacement.rot.z,
            true, true, false, true, 1, true
        )
        
        -- Start carry animation
        RequestAnimDict(propData.CarryAnim.dict)
        while not HasAnimDictLoaded(propData.CarryAnim.dict) do Wait(0) end
        TaskPlayAnim(cache.ped, propData.CarryAnim.dict, propData.CarryAnim.anim, 3.0, 3.0, -1, 49, 0, false, false, false)
        
        lib.notify({
            title = 'House Robbery',
            description = 'Carrying ' .. propData.Label .. '. Find a vehicle trunk to store it!',
            type = 'inform',
            duration = 8000
        })
        
        -- Start monitoring for nearby vehicles
        startVehicleMonitoring()
        doingAction = false
        
    else
        -- Animation was cancelled - proper cleanup
        cleanupCarryingState()
        doingAction = false
    end
end

-- Function to get nearby vehicles
function getNearbyVehicles()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local nearby = {}
    
    for _, vehicle in pairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        local distance = #(playerCoords - vehCoords)
        
        if distance <= 8.0 then
            table.insert(nearby, {
                vehicle = vehicle,
                distance = distance,
                coords = vehCoords,
                plate = GetVehicleNumberPlateText(vehicle)
            })
        end
    end
    
    -- Sort by distance
    table.sort(nearby, function(a, b) return a.distance < b.distance end)
    return nearby
end

-- Function to monitor nearby vehicles while carrying statue
function startVehicleMonitoring()
    CreateThread(function()
        while carryingStatue do
            Wait(500)
            nearbyVehicles = getNearbyVehicles()
            
            -- Show help text when near a vehicle trunk
            if #nearbyVehicles > 0 then
                local closest = nearbyVehicles[1]
                if closest.distance <= 4.0 then
                    -- Check if vehicle has a trunk and is suitable
                    local vehClass = GetVehicleClass(closest.vehicle)
                    local vehModel = GetEntityModel(closest.vehicle)
                    
                    -- Exclude motorcycles, bikes, boats, planes, helicopters
                    if vehClass ~= 8 and vehClass ~= 13 and vehClass ~= 14 and vehClass ~= 15 and vehClass ~= 16 then
                        -- Check if we're near the back of the vehicle
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        local vehCoords = GetEntityCoords(closest.vehicle)
                        local vehHeading = GetEntityHeading(closest.vehicle)
                        
                        -- Calculate rear position of vehicle
                        local rearOffset = GetOffsetFromEntityInWorldCoords(closest.vehicle, 0.0, -2.5, 0.0)
                        local distanceToRear = #(playerCoords - rearOffset)
                        
                        if distanceToRear <= 2.5 then
                            lib.showTextUI('[E] Put Statue in Trunk', {
                                position = "top-center",
                                icon = 'fas fa-car',
                                style = {
                                    borderRadius = 5,
                                    backgroundColor = '#48BB78',
                                    color = 'white'
                                }
                            })
                            
                            if IsControlJustPressed(0, 38) then -- E key
                                putStatueInTrunk(closest.vehicle)
                            end
                        else
                            lib.showTextUI('Move to the back of the vehicle', {
                                position = "top-center",
                                icon = 'fas fa-arrow-down',
                                style = {
                                    borderRadius = 5,
                                    backgroundColor = '#FF6B6B',
                                    color = 'white'
                                }
                            })
                        end
                    else
                        lib.showTextUI('This vehicle cannot store the statue', {
                            position = "top-center",
                            icon = 'fas fa-times',
                            style = {
                                borderRadius = 5,
                                backgroundColor = '#FF6B6B',
                                color = 'white'
                            }
                        })
                    end
                else
                    lib.hideTextUI()
                end
            else
                lib.hideTextUI()
            end
        end
        lib.hideTextUI()
    end)
end

-- Function to put statue in trunk
function putStatueInTrunk(vehicle)
    if not carryingStatue or not statueData then return end
    
    local playerPed = PlayerPedId()
    local vehCoords = GetEntityCoords(vehicle)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - vehCoords)
    
    if distance > 5.0 then
        lib.notify({
            title = 'House Robbery',
            description = 'You are too far from the vehicle',
            type = 'error'
        })
        return
    end
    
    -- Check if vehicle is locked
    if GetVehicleDoorLockStatus(vehicle) == 2 then
        lib.notify({
            title = 'House Robbery',
            description = 'The vehicle is locked!',
            type = 'error'
        })
        return
    end
    
    doingAction = true
    
    -- Face the rear of the vehicle
    local rearCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.0, 0.0)
    TaskTurnPedToFaceCoord(playerPed, rearCoords, 2000)
    
    Wait(1000)
    
    -- Open trunk
    SetVehicleDoorOpen(vehicle, 5, false, false) -- Boot/trunk door
    
    Wait(500)
    
    -- Play putting animation
    local putDict = "anim@heists@money_grab@duffel"
    local putAnim = "loop"
    
    RequestAnimDict(putDict)
    while not HasAnimDictLoaded(putDict) do Wait(0) end
    
    if lib.progressBar({
        duration = 5000,
        label = 'Placing statue in trunk...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    }) then
        ClearPedTasks(cache.ped)
        
        -- Close trunk
        SetVehicleDoorShut(vehicle, 5, false)
        
        -- Complete the robbery
        if DoesEntityExist(statueData.originalObject) then
            TriggerServerEvent("marz_houserobbery:robbedpropcreated", 
                statueData.propData.model, 
                statueData.house, 
                statueData.propKey, 
                ObjToNet(statueData.originalObject), 
                false)
            DeleteEntity(statueData.originalObject)
        end
        
        -- FIXED: Proper cleanup after successful trunk storage
        cleanupCarryingState()
        doingAction = false
        
        lib.notify({
            title = 'House Robbery',
            description = 'Ancient statue successfully stored in trunk!',
            type = 'success',
            duration = 5000
        })
        
        -- Add some noise for closing trunk
        if stealthSystemActive and exports['marz_houserobbery'] and exports['marz_houserobbery']['IncreaseNoise'] then
            IncreaseNoise(5.0) -- Trunk closing makes noise
        end
        
    else
        doingAction = false
        ClearPedTasks(cache.ped)
    end
end

-- FIXED: Enhanced dropStatue function - statue drops where player is standing
function dropStatue()
    if not carryingStatue then return end
    
    print("^3[DEBUG] Dropping statue at player location^7")
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    
    -- Calculate drop position in front of player
    local forwardOffset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 1.5, 0.0)
    
    lib.notify({
        title = 'House Robbery',
        description = 'You dropped the ancient statue!',
        type = 'error'
    })
    
    -- Remove carried statue
    if DoesEntityExist(statueProp) then
        DetachEntity(statueProp, true, false)
        DeleteEntity(statueProp)
        statueProp = nil
    end
    
    -- Create new statue at drop location instead of showing original
    if statueData and statueData.propData then
        RequestModel(statueData.propData.model)
        while not HasModelLoaded(statueData.propData.model) do Wait(0) end
        
        -- Create statue at player's location
        local droppedStatue = CreateObject(statueData.propData.model, forwardOffset.x, forwardOffset.y, forwardOffset.z, false, true, false)
        SetEntityHeading(droppedStatue, playerHeading)
        PlaceObjectOnGroundProperly(droppedStatue)
        FreezeEntityPosition(droppedStatue, true)
        
        -- Update the original object reference to the new location
        if DoesEntityExist(statueData.originalObject) then
            DeleteEntity(statueData.originalObject)
        end
        statueData.originalObject = droppedStatue
        
        -- Add target interaction to the dropped statue
        if Config.InteractionType == 'target' then
            local target = exports[Config.Target]
            local droppedTargetId = target:addLocalEntity(droppedStatue, {
                {
                    name = "marz_dropped_statue",
                    icon = 'fas fa-dolly',
                    label = 'Carry ' .. statueData.propData.Label,
                    onSelect = function()
                        takeCreatedProp(statueData.house, statueData.propKey, statueData.propData, droppedStatue)
                    end,
                    canInteract = function()
                        return not doingAction and not carryingStatue
                    end
                }
            })
            
            if droppedTargetId then
                table.insert(insideTargets, droppedTargetId)
            end
        end
        
        print("^3[DEBUG] Created new statue at drop location: " .. forwardOffset.x .. ", " .. forwardOffset.y .. ", " .. forwardOffset.z .. "^7")
    end
    
    -- FIXED: Proper cleanup
    cleanupCarryingState()
end

-- FIXED: Enhanced key handler for statue carrying controls
CreateThread(function()
    while true do
        Wait(0)
        if carryingStatue and movementRestricted then
            -- Show instructions
            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextEntry("STRING")
            AddTextComponentString("~w~Carrying Ancient Statue~n~~r~[X] ~w~to drop")
            DrawText(0.015, 0.7)
            
            -- Drop with X key
            if IsControlJustPressed(0, 73) then -- X key
                dropStatue()
            end
            
            -- Movement restrictions
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            
            -- Apply movement speed modifier
            if statueData and statueData.propData and statueData.propData.MovementSpeed then
                SetPedMoveRateOverride(cache.ped, statueData.propData.MovementSpeed)
            end
            
            -- Force walking animation
            if not IsEntityPlayingAnim(cache.ped, statueData.propData.CarryAnim.dict, statueData.propData.CarryAnim.anim, 3) then
                TaskPlayAnim(cache.ped, statueData.propData.CarryAnim.dict, statueData.propData.CarryAnim.anim, 3.0, 3.0, -1, 49, 0, false, false, false)
            end
        end
    end
end)

function crackSafe(house, safeKey, safeData)
    if isItemAlreadyRobbed(house, safeKey) then
        lib.notify({
            title = 'House Robbery',
            description = 'This safe was already opened!',
            type = 'error'
        })
        return
    end

    -- Check if player has required item
    if safeData.NeedItem then
        local hasItem = false
        lib.callback('marz_houserobbery:getitem', false, function(value)
            hasItem = value
        end, safeData.Item, 1)
        
        Wait(200)
        
        if not hasItem then
            lib.notify({
                title = 'House Robbery',
                description = 'You need a ' .. safeData.Item .. ' to open this safe',
                type = 'error'
            })
            return
        end
    end

    doingAction = true
    FreezeEntityPosition(cache.ped, true)
    
    -- Increase noise from safe cracking
    if stealthSystemActive and exports['marz_houserobbery'] and exports['marz_houserobbery']['IncreaseNoise'] then
        IncreaseNoise(6.0)
    end
    
    -- Use the safe cracking minigame with error handling (now using UTK Fingerprint)
    local success = false
    local minigameError = false
    
    local status, result = pcall(function()
        return LockPickMinigame() -- This now uses UTK Fingerprint
    end)
    
    if status then
        success = result
    else
        minigameError = true
        print("ERROR: Safe cracking minigame failed:", result)
        lib.notify({
            title = 'Error',
            description = 'Safe cracking system error - check console',
            type = 'error'
        })
    end
    
    FreezeEntityPosition(cache.ped, false)
    
    if success and not minigameError then
        lib.notify({
            title = 'Success',
            description = 'You opened the safe!',
            type = 'success'
        })
        TriggerServerEvent("marz_houserobbery:robbedHouseProp", house, safeKey)
        TriggerServerEvent("marz_houserobbery:RobbedSafe", house, safeKey)
    else
        if not minigameError then
            lib.notify({
                title = 'Failed',
                description = 'You failed to open the safe!',
                type = 'error'
            })
        end
    end
    
    doingAction = false
end

function leaveHouse(house)
    -- FIXED: Proper cleanup when leaving house
    if carryingStatue then
        cleanupCarryingState()
    end
    
    cleanupInsideTargets()
    
    -- Stop stealth system
    if stealthSystemActive then
        if exports['marz_houserobbery'] and exports['marz_houserobbery']['StopStealthSystem'] then
            StopStealthSystem()
        end
        stealthSystemActive = false
    end
    
    for _, v in pairs(CreatedProps) do
        SetEntityAsMissionEntity(v, false, true)
        DeleteObject(v)
    end

    teleport(Config.HousesToRob[house].Coords.xyz)
    TriggerServerEvent("marz_houserobbery:leaveHouse", house)
    
    SetTimeout(1000, function()
        currentHouse = nil
        leaving = false
        duffelBagSlots = 0
        NPC = nil
    end)
end

function teleport(coords)
    DoScreenFadeOut(1000)
    Wait(1000)
    FreezeEntityPosition(cache.ped, true)
    SetEntityCoords(cache.ped, coords.xyz)
    SetEntityHeading(cache.ped, coords.w)

    while not HasCollisionLoadedAroundEntity(cache.ped) do
        RequestCollisionAtCoord(coords)
        Wait(0)
    end
    FreezeEntityPosition(cache.ped, false)
    SetTimeout(900, function()
        ClearPedTasks(cache.ped)
    end)
    Wait(500)
    DoScreenFadeIn(1500)
end

function createInsideTargets(house)
    if Config.InteractionType ~= 'target' then return end
    
    local target = exports[Config.Target]
    local insidePositions = getInsidePositions(house)
    
    if not insidePositions then
        print("ERROR: No inside positions found for house:", house)
        return
    end
    
    -- FIXED: Exit target - don't disable when carrying statue, just when doing other actions
    local exitCoords = insidePositions.Exit.coords
    local exitTargetId = target:addBoxZone({
        coords = vec3(exitCoords.x, exitCoords.y, exitCoords.z),
        size = vec3(3, 3, 3),
        rotation = 0,
        debug = Config.Debug,
        options = {
            {
                name = "marz_exit_house",
                icon = 'fas fa-door-open',
                label = 'Exit House',
                onSelect = function()
                    leaveHouse(house)
                end,
                canInteract = function()
                    return not doingAction -- Allow exit even when carrying statue
                end
            }
        },
        distance = 3.0,
    })
    
    if exitTargetId then
        table.insert(insideTargets, exitTargetId)
    end
    
    -- Search location targets
    for place, v in pairs(insidePositions) do
        if place ~= "Exit" then
            local searchTargetId = target:addBoxZone({
                coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                size = vec3(2, 2, 2),
                rotation = 0,
                debug = Config.Debug,
                options = {
                    {
                        name = "marz_search_" .. place,
                        icon = 'fas fa-search',
                        label = 'Search ' .. place,
                        onSelect = function()
                            searchPlace(place)
                        end,
                        canInteract = function()
                            return not doingAction and not isItemAlreadyRobbed(house, place) and not carryingStatue
                        end
                    }
                },
                distance = 2.5,
            })
            
            if searchTargetId then
                table.insert(insideTargets, searchTargetId)
            end
        end
    end
    
    -- Start stealth system BEFORE spawning NPC
    if Config.StealthSystem and Config.StealthSystem.enabled then
        local pedConfig = getPedConfig(house)
        if pedConfig and pedConfig.sleeping then
            if exports['marz_houserobbery'] and exports['marz_houserobbery']['StartStealthSystem'] then
                StartStealthSystem(house)
                stealthSystemActive = true
                
                if Config.Debug then
                    print("Stealth system activated for house:", house)
                end
            end
        end
    end
    
    -- Spawn NPC AFTER stealth system is active
    SetTimeout(1000, function()
        if not PedSpawned[house] then
            TriggerServerEvent("marz_houserobbery:SpawnPed", house)
        end
    end)
    
    -- Create safes
    SetTimeout(2000, function()
        local safes = getSafes(house)
        for k, v in pairs(safes) do
            RequestModel(v.model)
            while not HasModelLoaded(v.model) do
                Wait(0)
            end
            
            local object = CreateObject(v.model, v.Coords.xyz, false, true, false)
            SetEntityHeading(object, v.Coords.w)
            PlaceObjectOnGroundProperly(object)
            FreezeEntityPosition(object, true)
            table.insert(CreatedProps, object)
            
            local safeTargetId = target:addLocalEntity(object, {
                {
                    name = "marz_safe_" .. k,
                    icon = 'fas fa-lock',
                    label = 'Crack ' .. v.Label,
                    onSelect = function()
                        crackSafe(house, k, v)
                    end,
                    canInteract = function()
                        return not doingAction and not isItemAlreadyRobbed(house, k) and not carryingStatue
                    end
                }
            })
            
            if safeTargetId then
                table.insert(insideTargets, safeTargetId)
            end
        end
    end)
    
    -- Create static prop targets (TVs, etc.)
    SetTimeout(3000, function()
        local staticProps = getStaticProps(house)
        for k, v in pairs(staticProps) do
            local objects = GetGamePool("CObject")
            for i = 1, #objects do
                if v.model == GetEntityModel(objects[i]) then
                    local objCoords = GetEntityCoords(objects[i])
                    local houseCoords = insidePositions.Exit.coords
                    local distance = #(objCoords - vec3(houseCoords.x, houseCoords.y, houseCoords.z))
                    
                    -- Only target objects that are close to the house interior
                    if distance < 50 then
                        local propTargetId = target:addLocalEntity(objects[i], {
                            {
                                name = "marz_static_" .. k,
                                icon = 'fas fa-hand-paper',
                                label = 'Take ' .. v.Label,
                                onSelect = function()
                                    takeStaticProp(house, k, v)
                                end,
                                canInteract = function()
                                    return not doingAction and not isItemAlreadyRobbed(house, k) and not carryingStatue
                                end
                            }
                        })
                        
                        if propTargetId then
                            table.insert(insideTargets, propTargetId)
                        end
                        break
                    end
                end
            end
        end
    end)
    
    -- Create created props
    SetTimeout(4000, function()
        local createdProps = getCreatedProps(house)
        for k, v in pairs(createdProps) do
            if not isItemAlreadyRobbed(house, k) then
                RequestModel(v.model)
                while not HasModelLoaded(v.model) do
                    Wait(0)
                end
                
                local object = CreateObject(v.model, v.Coords.xyz, false, true, false)
                SetEntityHeading(object, v.Coords.w)
                PlaceObjectOnGroundProperly(object)
                table.insert(CreatedProps, object)
                
                local createdTargetId = target:addLocalEntity(object, {
                    {
                        name = "marz_created_" .. k,
                        icon = v.NeedTrunk and 'fas fa-dolly' or 'fas fa-hand-paper',
                        label = v.NeedTrunk and 'Carry ' .. v.Label or 'Take ' .. v.Label,
                        onSelect = function()
                            takeCreatedProp(house, k, v, object)
                        end,
                        canInteract = function()
                            return not doingAction and not isItemAlreadyRobbed(house, k) and not carryingStatue
                        end
                    }
                })
                
                if createdTargetId then
                    table.insert(insideTargets, createdTargetId)
                end
            end
        end
    end)
end

-- FIXED: Enhanced NPC spawning with proper stealth integration
RegisterNetEvent("marz_houserobbery:SpawnPed")
AddEventHandler("marz_houserobbery:SpawnPed", function(house, exist)
    if not PedSpawned[house] then
        PedSpawned[house] = true
        local pedConfig = getPedConfig(house)
        
        if pedConfig and math.random(100) <= pedConfig.chance then
            RequestModel(pedConfig.model)

            while not HasModelLoaded(pedConfig.model) do
                Wait(100)
            end
            
            -- Create the NPC
            NPC = CreatePed(4, pedConfig.model,
                pedConfig.coords.x, pedConfig.coords.y,
                pedConfig.coords.z, pedConfig.coords.w, true,
                true)
            
            -- IMPORTANT: Store NPC reference immediately for stealth system
            if exports['marz_houserobbery'] and exports['marz_houserobbery']['SetCurrentNPC'] then
                exports['marz_houserobbery']['SetCurrentNPC'](NPC)
                print("^2[Main] Stored NPC reference for stealth system: " .. tostring(NPC) .. "^7")
            end
            
            -- Setup weapon if configured
            if pedConfig.weapon and pedConfig.weapon.enabled then
                if math.random(100) <= pedConfig.weapon.chance then
                    GiveWeaponToPed(NPC, pedConfig.weapon.weapon, 90, true, true)
                    if pedConfig.weapon.DisableWeaponDrop then
                        SetPedDropsWeaponsWhenDead(NPC, false)
                    end
                    print("^3[Main] NPC armed with weapon: " .. pedConfig.weapon.weapon .. "^7")
                end
            end
            
            -- Set NPC scenario based on sleeping state
            local scenario = pedConfig.sleeping and (pedConfig.sleepScenario or "WORLD_HUMAN_BUM_SLUMPED") or "WORLD_HUMAN_BUM_SLUMPED"
            TaskStartScenarioInPlace(NPC, scenario, 0, true)
            table.insert(CreatedProps, NPC)
            
            -- Make NPC invincible while sleeping (prevents accidental death)
            if pedConfig.sleeping then
                SetEntityInvincible(NPC, true)
                SetPedCanRagdoll(NPC, false)
                print("^2[Main] NPC set to sleeping mode with invincibility^7")
            end
            
            if Config.Debug then
                print("^2[Main] NPC spawned successfully:^7")
                print("  House: " .. house)
                print("  Entity: " .. tostring(NPC))
                print("  Sleeping: " .. tostring(pedConfig.sleeping or false))
                print("  Coords: " .. pedConfig.coords.x .. ", " .. pedConfig.coords.y .. ", " .. pedConfig.coords.z)
            end
        else
            print("^3[Main] NPC spawn chance failed for house: " .. house .. " (chance: " .. pedConfig.chance .. "%)^7")
        end
    else
        print("^3[Main] NPC already spawned for house: " .. house .. "^7")
    end
end)

-- FIXED: Enhanced NPC wakeup handler (no notification - stealth system handles it)
RegisterNetEvent("marz_houserobbery:npcAwakened")
AddEventHandler("marz_houserobbery:npcAwakened", function(house)
    print("^1[Main] ========== RECEIVED NPC AWAKEN EVENT ==========^7")
    print("^1[Main] House: " .. house .. "^7")
    print("^1[Main] Current House: " .. tostring(currentHouse) .. "^7")
    print("^1[Main] Global NPC: " .. tostring(NPC) .. "^7")
    print("^1[Main] NPC Exists: " .. tostring(DoesEntityExist(NPC or 0)) .. "^7")
    
    if house == currentHouse and NPC and DoesEntityExist(NPC) then
        print("^1[Main] Proceeding with NPC wakeup (notification handled by stealth system)^7")
        
        -- Remove invincibility
        SetEntityInvincible(NPC, false)
        SetPedCanRagdoll(NPC, true)
        
        -- Clear existing tasks
        ClearPedTasks(NPC)
        ClearPedSecondaryTask(NPC)
        
        -- Give NPC time to clear tasks
        CreateThread(function()
            Wait(500)
            
            if not DoesEntityExist(NPC) then
                print("^1[Main] NPC no longer exists after task clear^7")
                return
            end
            
            print("^1[Main] Setting NPC combat attributes^7")
            
            -- Make NPC aggressive and combat-ready
            SetPedCombatAttributes(NPC, 46, true)  -- BF_AlwaysFight
            SetPedCombatAttributes(NPC, 0, false)  -- BF_CanUseCover (disable)
            SetPedCombatAttributes(NPC, 1, true)   -- BF_CanUseVehicles  
            SetPedCombatAttributes(NPC, 2, false)  -- BF_CanDoDrivebys (disable)
            SetPedCombatAttributes(NPC, 3, false)  -- BF_CanLeaveVehicle (disable)
            SetPedCombatAttributes(NPC, 5, true)   -- BF_CanFightArmedPedsWhenNotArmed
            SetPedCombatAttributes(NPC, 13, true)  -- BF_AlwaysEquipBestWeapon
            SetPedCombatAttributes(NPC, 17, false) -- BF_CanTauntInVehicle (disable)
            SetPedCombatAttributes(NPC, 20, true)  -- BF_CanChaseTargetOnFoot
            SetPedCombatAttributes(NPC, 21, true)  -- BF_WillScanForDeadPeds
            SetPedCombatAttributes(NPC, 22, true)  -- BF_UseProximityFiringRate
            SetPedCombatAttributes(NPC, 27, false) -- BF_PerfectAccuracy (disable for fair play)
            
            -- Set combat behavior
            SetPedCombatRange(NPC, 2) -- Close range
            SetPedCombatMovement(NPC, 2) -- Offensive
            
            -- Make NPC hostile to player
            SetPedRelationshipGroupHash(NPC, GetHashKey("HATES_PLAYER"))
            SetRelationshipBetweenGroups(5, GetHashKey("HATES_PLAYER"), GetHashKey("PLAYER"))
            
            -- Set alertness and senses
            SetPedAlertness(NPC, 3) -- Maximum alertness
            SetPedSeeingRange(NPC, 150.0)
            SetPedHearingRange(NPC, 150.0)
            
            -- Make NPC targetable
            SetPedCanBeTargetted(NPC, true)
            SetPedCanBeTargettedByPlayer(NPC, PlayerId(), true)
            SetPedCanBeTargettedByTeam(NPC, GetPlayerTeam(PlayerId()), true)
            
            -- Start combat immediately
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local npcCoords = GetEntityCoords(NPC)
            
            -- Make NPC face player
            local heading = GetHeadingFromVector_2d(playerCoords.x - npcCoords.x, playerCoords.y - npcCoords.y)
            SetPedDesiredHeading(NPC, heading)
            
            -- Start aggressive combat
            TaskCombatPed(NPC, playerPed, 0, 16) -- 16 = Aggressive combat
            
            -- Play alert sounds
            PlayPedAmbientSpeechNative(NPC, "GENERIC_SHOCKED_HIGH", "SPEECH_PARAMS_FORCE")
            
            -- Additional combat enforcement
            CreateThread(function()
                local attempts = 0
                while DoesEntityExist(NPC) and attempts < 10 do
                    Wait(1000)
                    attempts = attempts + 1
                    
                    -- Keep forcing combat if NPC stops attacking
                    local npcTarget = GetPedTargetFromId(NPC)
                    if npcTarget ~= playerPed then
                        print("^1[Main] Re-engaging combat (attempt " .. attempts .. ")^7")
                        TaskCombatPed(NPC, playerPed, 0, 16)
                    else
                        print("^2[Main] NPC is actively targeting player^7")
                        break
                    end
                end
            end)
            
            print("^1[Main] NPC is now fully awake and hostile!^7")
            
            -- REMOVED: No notification here since stealth system handles it
        end)
    else
        print("^3[Main] NPC wakeup conditions not met:^7")
        print("  House match: " .. tostring(house == currentHouse))
        print("  NPC exists: " .. tostring(NPC and DoesEntityExist(NPC)))
    end
end)

RegisterNetEvent("marz_houserobbery:lockpick")
AddEventHandler("marz_houserobbery:lockpick", function(house)
    if Config.Debug then
        print("Starting lockpick for house:", house)
    end
    
    -- Check if already lockpicking
    if Lockpicking then
        lib.notify({
            title = 'House Robbery',
            description = 'Already lockpicking!',
            type = 'error'
        })
        return
    end
    
    -- Validate house exists
    if not Config.HousesToRob[house] then
        print("ERROR: Invalid house ID:", house)
        lib.notify({
            title = 'Error',
            description = 'Invalid house ID',
            type = 'error'
        })
        return
    end
    
    Lockpicking = true
    doLockpickAnimation(Config.HousesToRob[house].Coords.xyz)
    
    -- Use ox_lib skillCheck instead of external minigame
    local success = DoorLockPickMinigame()
    
    if Config.Debug then
        print("Lockpick minigame completed. Success:", success)
    end
    
    if success then
        doingAction = true
        SetTimeout(1100, function()
            FreezeEntityPosition(cache.ped, true)
        end)
        
        if lib.progressBar({
            duration = 1500,
            label = 'Lockpicking door...',
            useWhileDead = false,
            canCancel = false,
        }) then
            Lockpicking = false
            doingAction = false
            local reportChance = getReportChance(house)
            if math.random(100) <= reportChance then
                Dispatch(Config.HousesToRob[house].Coords.xyz, "houserobbery")
                AlarmSound()
                lib.notify({
                    title = 'Alarm',
                    description = 'The alarm alerted police!',
                    type = 'error'
                })
            end
            TriggerServerEvent("marz_houserobbery:unlockHouse", house)
            enterHouse(house, false)
            FreezeEntityPosition(cache.ped, false)
        end
    else
        Lockpicking = false
        lib.notify({
            title = 'Lockpick',
            description = 'You failed to open the door!',
            type = 'error'
        })
    end
end)

RegisterNetEvent("marz_houserobbery:robbedHouseProp")
AddEventHandler("marz_houserobbery:robbedHouseProp", function(house, place)
    if housesData[house] then
        table.insert(housesData[house].robbed, place)
    end
end)

RegisterNetEvent("marz_houserobbery:deleteObject")
AddEventHandler("marz_houserobbery:deleteObject", function(netId)
    if NetworkDoesEntityExistWithNetworkId(netId) then
        local entity = NetToObj(netId)
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        -- Enhanced cleanup for statue carrying
        cleanupCarryingState()
        
        cleanupInsideTargets()
        
        -- Stop stealth system
        if stealthSystemActive then
            if exports['marz_houserobbery'] and exports['marz_houserobbery']['StopStealthSystem'] then
                StopStealthSystem()
            end
            stealthSystemActive = false
        end
        
        for _, v in pairs(CreatedProps) do
            SetEntityAsMissionEntity(v, false, true)
            DeleteObject(v)
            if DoesEntityExist(v) then
                TriggerServerEvent("marz_houserobbery:removeobject", ObjToNet(v))
            end
        end
    end
end)

function doLockpickAnimation(coords)
    if not Lockpicking then return end
    local Lockpickprop = `prop_tool_screwdvr01`
    RequestAnimDict("mp_arresting")
    while not HasAnimDictLoaded("mp_arresting") do Wait(100) end
    RequestModel(Lockpickprop)
    while not HasModelLoaded(Lockpickprop) do Wait(100) end
    
    local ped = PlayerPedId()
    local lockpickobject = CreateObject(Lockpickprop, 0.0, 0.0, 0.0, true, true, false)
    local LockpickBoneIndex = GetPedBoneIndex(ped, 57005)
    AttachEntityToEntity(lockpickobject, ped, LockpickBoneIndex, 0.14, 0.06, 0.02, 51.0, -90.0, -40.0, true, true, false,
        false, 1, true)
    SetModelAsNoLongerNeeded(Lockpickprop)
    TaskTurnPedToFaceCoord(cache.ped, coords, 1000)
    
    CreateThread(function()
        while Lockpicking do
            Wait(0)
            if not IsEntityPlayingAnim(ped, "mp_arresting", "a_uncuff", 3) then
                TaskPlayAnim(ped, "mp_arresting", "a_uncuff", 3.0, 1.0, -1, 49, 0, false, false, false)
            end
        end
        ClearPedSecondaryTask(ped)
        Wait(250)
        DetachEntity(lockpickobject, true, false)
        DeleteEntity(lockpickobject)
    end)
end

function crackSafe(house, safeKey, safeData)
    if isItemAlreadyRobbed(house, safeKey) then
        lib.notify({
            title = 'House Robbery',
            description = 'This safe was already opened!',
            type = 'error'
        })
        return
    end

    -- Check if player has required item
    if safeData.NeedItem then
        local hasItem = false
        lib.callback('marz_houserobbery:getitem', false, function(value)
            hasItem = value
        end, safeData.Item, 1)
        
        Wait(200)
        
        if not hasItem then
            lib.notify({
                title = 'House Robbery',
                description = 'You need a ' .. safeData.Item .. ' to open this safe',
                type = 'error'
            })
            return
        end
    end

    doingAction = true
    FreezeEntityPosition(cache.ped, true)
    
    -- Increase noise from safe cracking
    if stealthSystemActive and exports['marz_houserobbery'] and exports['marz_houserobbery']['IncreaseNoise'] then
        IncreaseNoise(6.0)
    end
    
    -- Use ox_lib skillCheck for safe cracking
    local success = LockPickMinigame()
    
    FreezeEntityPosition(cache.ped, false)
    
    if success then
        lib.notify({
            title = 'Success',
            description = 'You opened the safe!',
            type = 'success'
        })
        TriggerServerEvent("marz_houserobbery:robbedHouseProp", house, safeKey)
        TriggerServerEvent("marz_houserobbery:RobbedSafe", house, safeKey)
    else
        lib.notify({
            title = 'Failed',
            description = 'You failed to open the safe!',
            type = 'error'
        })
    end
    
    doingAction = false
end 

-- Enhanced debug commands for MarzScripts and Ancient Statue System
if Config.Debug then
    RegisterCommand('marz_debug_break', function(source, args)
        local house = args[1] or "Mirror Park House"
        print("Debug: Force triggering break into house for:", house)
        enterHouse(house, true)
    end, false)
    
    RegisterCommand('marz_debug_enter', function(source, args)
        local house = args[1] or "Mirror Park House"
        print("Debug: Force entering house:", house)
        enterHouse(house, false)
    end, false)
    
    RegisterCommand('marz_debug_spawn_npc', function(source, args)
        local house = args[1] or currentHouse or "Mirror Park House"
        print("Debug: Force spawning NPC for house:", house)
        TriggerServerEvent("marz_houserobbery:SpawnPed", house)
    end, false)
    
    RegisterCommand('marz_debug_wake_npc', function()
        if NPC and DoesEntityExist(NPC) then
            print("Debug: Force waking up NPC:", NPC)
            TriggerEvent("marz_houserobbery:npcAwakened", currentHouse or "test")
        else
            print("Debug: No NPC to wake up")
        end
    end, false)
    
    RegisterCommand('marz_debug_npc_info', function()
        print("Debug: ============ NPC DEBUG INFO ============")
        print("Debug: Current House:", currentHouse)
        print("Debug: Global NPC:", tostring(NPC))
        print("Debug: NPC Exists:", tostring(DoesEntityExist(NPC or 0)))
        print("Debug: Stealth Active:", stealthSystemActive)
        
        if NPC and DoesEntityExist(NPC) then
            local coords = GetEntityCoords(NPC)
            print("Debug: NPC Coords:", coords.x, coords.y, coords.z)
            print("Debug: NPC Health:", GetEntityHealth(NPC))
            print("Debug: NPC Invincible:", GetEntityInvincible(NPC))
            print("Debug: NPC Current Task:", GetScriptTaskStatus(NPC, `SCRIPT_TASK_COMBAT_PED`))
        end
        print("Debug: =========================================")
    end, false)
    
    -- Ancient Statue System Debug Commands
    RegisterCommand('marz_test_statue', function()
        if currentHouse then
            print("Debug: Force spawning statue for testing in house:", currentHouse)
            local houseConfig = Config.HousesToRob[currentHouse]
            local createdProps = getCreatedProps(currentHouse)
            
            if createdProps and createdProps["statue"] then
                local propData = createdProps["statue"]
                RequestModel(propData.model)
                while not HasModelLoaded(propData.model) do Wait(0) end
                
                local object = CreateObject(propData.model, propData.Coords.xyz, false, true, false)
                SetEntityHeading(object, propData.Coords.w)
                PlaceObjectOnGroundProperly(object)
                table.insert(CreatedProps, object)
                
                print("Debug: Statue spawned successfully at", propData.Coords.xyz)
            else
                print("Debug: No statue configuration found for this house")
            end
        else
            print("Debug: You must be inside a house to test statue")
        end
    end, false)
    
    RegisterCommand('marz_carry_test', function()
        if not carryingStatue then
            print("Debug: Starting test carry mode")
            carryingStatue = true
            movementRestricted = true
            statueData = {
                house = currentHouse or "test",
                propKey = "statue",
                propData = {
                    model = `m24_1_prop_m41_statue_01a`,
                    Label = "Test Statue",
                    NoiseLevel = 10.0,
                    MovementSpeed = 0.5,
                    propPlacement = { 
                        pos = vec3(0.17, 0.0, 0.05), 
                        rot = vec3(16.0, 0.0, 0.0), 
                        bone = 18905
                    },
                    CarryAnim = { 
                        dict = "anim@heists@box_carry@", 
                        anim = "idle" 
                    }
                }
            }
            
            -- Create test statue prop
            RequestModel(`m24_1_prop_m41_statue_01a`)
            while not HasModelLoaded(`m24_1_prop_m41_statue_01a`) do Wait(0) end
            
            statueProp = CreateObject(`m24_1_prop_m41_statue_01a`, 0.0, 0.0, 0.0, true, true, false)
            
            -- Attach to player
            local boneIndex = GetPedBoneIndex(cache.ped, 18905)
            AttachEntityToEntity(
                statueProp, cache.ped, boneIndex,
                0.17, 0.0, 0.05,
                16.0, 0.0, 0.0,
                true, true, false, true, 1, true
            )
            
            -- Start animation
            RequestAnimDict("anim@heists@box_carry@")
            while not HasAnimDictLoaded("anim@heists@box_carry@") do Wait(0) end
            TaskPlayAnim(cache.ped, "anim@heists@box_carry@", "idle", 3.0, 3.0, -1, 49, 0, false, false, false)
            
            startVehicleMonitoring()
            print("Debug: Test carry mode activated")
        else
            print("Debug: Already carrying statue")
        end
    end, false)
    
    RegisterCommand('marz_drop_test', function()
        if carryingStatue then
            print("Debug: Dropping test statue")
            dropStatue()
        else
            print("Debug: Not carrying anything")
        end
    end, false)
    
    RegisterCommand('marz_spawn_car', function()
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        
        -- Spawn a suitable vehicle for testing
        local vehicleModel = `buffalo` -- Simple 4-door car with trunk
        RequestModel(vehicleModel)
        while not HasModelLoaded(vehicleModel) do Wait(0) end
        
        local vehicle = CreateVehicle(vehicleModel, playerCoords.x + 5, playerCoords.y + 5, playerCoords.z, playerHeading, true, false)
        SetEntityAsMissionEntity(vehicle, true, true)
        
        print("Debug: Spawned test vehicle:", vehicle)
        
        -- Give keys if using a vehicle key system
        if Config.Framework == "qbcore" then
            TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(vehicle))
        end
    end, false)
    
    RegisterCommand('marz_statue_status', function()
        print("^2============ STATUE CARRYING STATUS ============^7")
        print("^3Carrying Statue: " .. tostring(carryingStatue) .. "^7")
        print("^3Movement Restricted: " .. tostring(movementRestricted) .. "^7")
        print("^3Statue Prop: " .. tostring(statueProp) .. "^7")
        print("^3Statue Exists: " .. tostring(DoesEntityExist(statueProp or 0)) .. "^7")
        print("^3Doing Action: " .. tostring(doingAction) .. "^7")
        print("^3Current House: " .. tostring(currentHouse) .. "^7")
        
        if statueData then
            print("^3--- STATUE DATA ---^7")
            print("House: " .. tostring(statueData.house))
            print("Prop Key: " .. tostring(statueData.propKey))
            print("Label: " .. tostring(statueData.propData and statueData.propData.Label))
            print("Movement Speed: " .. tostring(statueData.propData and statueData.propData.MovementSpeed))
            print("Noise Level: " .. tostring(statueData.propData and statueData.propData.NoiseLevel))
            print("Original Object Exists: " .. tostring(DoesEntityExist(statueData.originalObject or 0)))
        end
        
        if #nearbyVehicles > 0 then
            print("^3--- NEARBY VEHICLES ---^7")
            for i, veh in ipairs(nearbyVehicles) do
                local vehClass = GetVehicleClass(veh.vehicle)
                local vehName = GetDisplayNameFromVehicleModel(GetEntityModel(veh.vehicle))
                print("Vehicle " .. i .. ": " .. vehName .. " (Class: " .. vehClass .. ", Distance: " .. string.format("%.2f", veh.distance) .. ")")
            end
        else
            print("^3No nearby vehicles^7")
        end
        print("^2===============================================^7")
    end, false)
    
    RegisterCommand('marz_force_trunk', function()
        if #nearbyVehicles > 0 then
            local closest = nearbyVehicles[1]
            print("Debug: Force putting statue in closest vehicle:", closest.vehicle)
            putStatueInTrunk(closest.vehicle)
        else
            print("Debug: No nearby vehicles found")
        end
    end, false)
    
    RegisterCommand('marz_reset_carry', function()
        print("Debug: Force resetting carrying state")
        cleanupCarryingState()
    end, false)
    
    RegisterCommand('marz_system_status', function()
        print("^2============ MARZ HOUSE ROBBERY SYSTEM STATUS ============^7")
        print("^2Current Date/Time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "^7")
        print("^2User: MarzScripts^7")
        print("^3--- MAIN SYSTEM ---^7")
        print("Current House:", tostring(currentHouse))
        print("Doing Action:", tostring(doingAction))
        print("In House:", tostring(InTheHouse))
        print("Lockpicking:", tostring(Lockpicking))
        print("Duffel Slots:", duffelBagSlots .. "/" .. Config.MaxDuffelCapacity)
        print("^3--- NPC SYSTEM ---^7")
        print("Global NPC:", tostring(NPC))
        print("NPC Exists:", tostring(DoesEntityExist(NPC or 0)))
        print("^3--- STEALTH SYSTEM ---^7")
        print("Stealth Active:", tostring(stealthSystemActive))
        if exports['marz_houserobbery'] and exports['marz_houserobbery']['IsStealthActive'] then
            print("Stealth Module Active:", tostring(exports['marz_houserobbery']['IsStealthActive']()))
        end
        if exports['marz_houserobbery'] and exports['marz_houserobbery']['GetNoiseLevel'] then
            print("Current Noise Level:", tostring(exports['marz_houserobbery']['GetNoiseLevel']()))
        end
        print("^3--- ANCIENT STATUE SYSTEM ---^7")
        print("Carrying Statue:", tostring(carryingStatue))
        print("Movement Restricted:", tostring(movementRestricted))
        print("Statue Prop Exists:", tostring(DoesEntityExist(statueProp or 0)))
        print("Nearby Vehicles Count:", #nearbyVehicles)
        print("^3--- HOUSE DATA ---^7")
        if currentHouse and housesData[currentHouse] then
            print("House Locked:", tostring(housesData[currentHouse].locked))
            print("Players in House:", tostring(housesData[currentHouse].players and #housesData[currentHouse].players or 0))
            print("Items Robbed:", tostring(housesData[currentHouse].robbed and #housesData[currentHouse].robbed or 0))
        end
        print("^2======================================================^7")
    end, false)
end
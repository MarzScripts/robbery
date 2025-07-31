-- Wait for Config to be loaded
while not Config do
    Wait(100)
end

-- Framework Detection
if Config.Framework == "ESX" then
    if Config.NewESX then
        ESX = exports["es_extended"]:getSharedObject()
    else
        ESX = nil
        CreateThread(function()
            while ESX == nil do
                TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
                Wait(100)
            end
        end)
    end
elseif Config.Framework == "qbcore" then
    QBCore = exports["qb-core"]:GetCoreObject()
end

-- Framework Events
if Config.Framework == "ESX" then
    RegisterNetEvent('esx:playerLoaded') 
    AddEventHandler('esx:playerLoaded', function(xPlayer, isNew)
        ESX.PlayerData = xPlayer
        ESX.PlayerLoaded = true
        TriggerServerEvent("marz_houserobbery:sync")
    end)
elseif Config.Framework == "qbcore" then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = QBCore.Functions.GetPlayerData()
        TriggerServerEvent("marz_houserobbery:sync")
    end)
end

-- Utility Functions
function Draw3DText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    
    if onScreen then
        SetTextFont(4)
        SetTextScale(0.33, 0.30)
        SetTextDropshadow(10, 100, 100, 100, 255)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
        local factor = (string.len(text)) / 350
        DrawRect(_x,_y+0.0135, 0.025+ factor, 0.03, 0, 0, 0, 10)
    end
end

function Target()
    if Config.Target == "qtarget" then
        return exports['qtarget']
    elseif Config.Target == "ox_target" then
        return exports['ox_target']
    elseif Config.Target == "qb-target" then
        return exports['qb-target']
    end
end

function Dispatch(coords, type)
    if Config.Dispatch.enabled then
        if Config.Dispatch.script == "cd_dispatch" then
            if type == "houserobbery" then
                TriggerServerEvent('cd_dispatch:AddNotification', {
                    job_table = Config.PoliceJobs,
                    coords = coords,
                    title = "10-90 - House Robbery",
                    message = "Alarm detected a house robbery",
                    flash = 0,
                    unique_id = tostring(math.random(0000000, 9999999)),
                    blip = {
                        sprite = 40,
                        scale = 1.2,
                        colour = 1,
                        flashes = false,
                        text = "House Robbery",
                        time = (5 * 60 * 1000),
                        sound = 1,
                    }
                })
            end
        elseif Config.Dispatch.script == "linden_outlawalert" then
            if type == "houserobbery" then
                local data = { 
                    displayCode = "10-90", 
                    description = "House Robbery", 
                    isImportant = 1,
                    recipientList = Config.PoliceJobs,
                    length = '10000', 
                    infoM = 'fa-info-circle', 
                    info = "Alarm detected a house robbery" 
                }
                local dispatchData = { dispatchData = data, caller = 'alarm', coords = coords }
                TriggerServerEvent('wf-alerts:svNotify', dispatchData)
            end
        elseif Config.Dispatch.script == "ps-disptach" then
            if type == "houserobbery" then
                exports["ps-dispatch"]:CustomAlert({
                    coords = coords,
                    message = "House Robbery",
                    dispatchCode = "10-90",
                    description = "Alarm detected a house robbery",
                    radius = 0,
                    sprite = 40,
                    color = 1,
                    scale = 1.2,
                    length = 3,
                })
            end
        elseif Config.Dispatch.script == "core-dispatch" then
            if type == "houserobbery" then
                for k, v in pairs(Config.PoliceJobs) do
                    exports['core_dispatch']:addCall("10-90", "Alarm detected a house robbery", {
                        }, {coords.xyz}, v, 10000, 11, 5 )
                end
            end
        end
    end
end

function CheckJob()
    local HasJob = false
    for _, job in pairs(Config.PoliceJobs) do
        if GetJob() == job or job == nil or not job then
            HasJob = true
        end
    end
    return HasJob
end

function GetJob()
    if Config.Framework == "ESX" then
        return ESX.GetPlayerData().job.name
    elseif Config.Framework == "qbcore" then
        return QBCore.Functions.GetPlayerData().job.name
    end
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║                    OX_LIB MINIGAME FUNCTIONS                 ║
-- ╚══════════════════════════════════════════════════════════════╝

-- Door Lockpick Minigame using ox_lib skillCheck
function DoorLockPickMinigame()
    local success = lib.skillCheck(Config.Minigames.DoorLockpick.difficulty, Config.Minigames.DoorLockpick.inputs)
    return success
end

-- Safe Cracking Minigame using ox_lib skillCheck
function LockPickMinigame()
    local success = lib.skillCheck(Config.Minigames.SafeCracking.difficulty, Config.Minigames.SafeCracking.inputs)
    return success
end

-- Hacking Minigame using ox_lib skillCheck (if needed for future features)
function HackingMinigame()
    local success = lib.skillCheck(Config.Minigames.Hacking.difficulty, Config.Minigames.Hacking.inputs)
    return success
end

-- Sound Functions
function AlarmSound()
    -- Add your sound system here
    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", true)
end

function DoorSound()
    -- Add your sound system here
    PlaySoundFrontend(-1, "DOOR_CLOSE", "HUD_MINI_GAME_SOUNDSET", true)
end

-- Vehicle Functions
function GetAvailableVehicleSpawnPoint(SpawnPoints)
    local spawnPoints = SpawnPoints
    local found, foundSpawnPoint = false, nil

    for i = 1, #spawnPoints, 1 do
        if IsSpawnPointClear(spawnPoints[i].Coords, spawnPoints[i].Radius) then
            found, foundSpawnPoint = true, spawnPoints[i]
            break
        end
    end

    if found then
        return true, foundSpawnPoint
    else
        lib.notify({
            title = 'Error',
            description = 'No free space available',
            type = 'error'
        })
        return false
    end
end

function GetVehicles()
    return GetGamePool('CVehicle')
end

function GetVehiclesInArea(coords, maxDistance)
    local nearbyEntities = {}
    local entities = GetVehicles()
    
    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = cache.ped
        coords = GetEntityCoords(playerPed)
    end

    for k, entity in pairs(entities) do
        local distance = #(coords - GetEntityCoords(entity))
        if distance <= maxDistance then
            nearbyEntities[#nearbyEntities + 1] = entity
        end
    end

    return nearbyEntities
end

function IsSpawnPointClear(coords, maxDistance)
    return #GetVehiclesInArea(coords, maxDistance) == 0
end

function SpawnVehicle(model, coords, heading)
    if Config.Framework == "ESX" then
        ESX.Game.SpawnVehicle(model, coords, heading, function(vehicle)
            SetEntityHeading(vehicle, heading)
        end)
    elseif Config.Framework == "qbcore" then
        QBCore.Functions.SpawnVehicle(model, function(vehicle)
            SetEntityHeading(vehicle, heading)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(vehicle))
        end, coords, true)
    end
end
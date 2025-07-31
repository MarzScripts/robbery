-- Wait for Config to be loaded
while not Config do
    Wait(100)
end

-- Localized functions
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local table_insert = table.insert
local table_remove = table.remove
local os_time = os.time
local math_random = math.random

-- Caches
local housesData = {}
local HouseCooldown = {}
local playerCache = {}
local policeCountCache = {count = 0, lastCheck = 0}

-- Framework optimization
local frameworkObject = nil
local getPlayerFromSource = nil
local getPlayerIdentifier = nil
local getPlayerName = nil
local getPlayerJob = nil

-- Initialize framework functions once
CreateThread(function()
    if Config.Framework == "ESX" then
        if Config.NewESX then
            frameworkObject = exports["es_extended"]:getSharedObject()
        else
            TriggerEvent("esx:getSharedObject", function(obj) frameworkObject = obj end)
            while not frameworkObject do Wait(100) end
        end
        
        getPlayerFromSource = function(source)
            return frameworkObject.GetPlayerFromId(source)
        end
        
        getPlayerIdentifier = function(player)
            return player.identifier
        end
        
        getPlayerName = function(player)
            return player.getName()
        end
        
        getPlayerJob = function(player)
            return player.job.name
        end
        
    elseif Config.Framework == "qbcore" then
        frameworkObject = exports["qb-core"]:GetCoreObject()
        
        getPlayerFromSource = function(source)
            return frameworkObject.Functions.GetPlayer(source)
        end
        
        getPlayerIdentifier = function(player)
            return player.PlayerData.citizenid
        end
        
        getPlayerName = function(player)
            return player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
        end
        
        getPlayerJob = function(player)
            return player.PlayerData.job.name
        end
    end
end)

-- Optimized player caching
local function getCachedPlayer(source)
    if playerCache[source] and (os_time() - playerCache[source].time) < 30 then
        return playerCache[source].player
    end
    
    local player = getPlayerFromSource(source)
    if player then
        playerCache[source] = {
            player = player,
            time = os_time()
        }
    end
    
    return player
end

-- Clear player cache on disconnect
AddEventHandler('playerDropped', function()
    local source = source
    playerCache[source] = nil
end)

-- Optimized police count
local function getOnlinePoliceCount()
    local currentTime = os_time()
    
    -- Cache police count for 30 seconds
    if (currentTime - policeCountCache.lastCheck) < 30 then
        return policeCountCache.count
    end
    
    local count = 0
    local players = {}
    
    if Config.Framework == "ESX" then
        players = frameworkObject.GetPlayers()
    elseif Config.Framework == "qbcore" then
        players = frameworkObject.Functions.GetPlayers()
    end
    
    for i = 1, #players do
        local player = getCachedPlayer(players[i])
        if player then
            local job = getPlayerJob(player)
            for j = 1, #Config.PoliceJobs do
                if job == Config.PoliceJobs[j] then
                    count = count + 1
                    break
                end
            end
        end
    end
    
    policeCountCache.count = count
    policeCountCache.lastCheck = currentTime
    
    return count
end

-- Optimized house management
local function initializeHouse(house)
    if not housesData[house] then
        housesData[house] = {
            locked = true,
            robbed = {},
            players = {},
            awakened = false,
            lastActivity = os_time()
        }
        
        if Config.Debug then
            print("Initialized house: " .. house)
        end
    end
end

local function resetHouse(house)
    if Config.Debug then
        print("Resetting house: " .. house)
    end
    
    housesData[house] = {
        locked = true,
        robbed = {},
        players = {},
        awakened = false,
        lastActivity = os_time()
    }
    
    -- Only notify players in that house
    if housesData[house] and housesData[house].players then
        for _, playerId in pairs(housesData[house].players) do
            local players = {}
            if Config.Framework == "ESX" then
                players = frameworkObject.GetPlayers()
            else
                players = frameworkObject.Functions.GetPlayers()
            end
            
            for _, playerSource in pairs(players) do
                local targetPlayer = getCachedPlayer(playerSource)
                if targetPlayer and getPlayerIdentifier(targetPlayer) == playerId then
                    TriggerClientEvent("marz_houserobbery:reset", playerSource, house)
                    break
                end
            end
        end
    end
end

-- Initialize houses with delay to prevent server startup lag
CreateThread(function()
    Wait(5000)
    
    local houseCount = 0
    for house, _ in pairs(Config.HousesToRob) do
        initializeHouse(house)
        houseCount = houseCount + 1
        
        -- Yield every 10 houses
        if houseCount % 10 == 0 then
            Wait(0)
        end
   
   if Config.Debug then
       print("All houses initialized: " .. houseCount)
   end
end)

-- Optimized auto-reset system
if Config.ResetHousesAfterTime then
   CreateThread(function()
       while true do
           Wait(60000) -- Check every minute
           
           local currentTime = os_time()
           local housesToReset = {}
           
           for house, data in pairs(housesData) do
               if data.lastActivity and (currentTime - data.lastActivity) > (Config.ResetTime * 60) then
                   if #data.players == 0 then
                       table_insert(housesToReset, house)
                   end
               end
           end
           
           -- Reset houses in batches
           for i = 1, #housesToReset do
               resetHouse(housesToReset[i])
               if i % 5 == 0 then
                   Wait(0) -- Yield every 5 houses
               end
           end
       end
   end)
end

-- Optimized sync event
RegisterNetEvent("marz_houserobbery:sync")
AddEventHandler("marz_houserobbery:sync", function()
   local source = source
   
   -- Send only relevant data to the player
   local syncData = {}
   for house, data in pairs(housesData) do
       syncData[house] = {
           locked = data.locked,
           players = data.players,
           robbed = data.robbed
       }
   end
   
   TriggerClientEvent("marz_houserobbery:sync", source, syncData)
end)

-- Optimized lockpick event with anti-exploit
local lockpickCooldown = {}
RegisterNetEvent("marz_houserobbery:lockpick")
AddEventHandler("marz_houserobbery:lockpick", function(house)
   local source = source
   
   -- Cooldown check
   if lockpickCooldown[source] and (os_time() - lockpickCooldown[source]) < 5 then
       return
   end
   lockpickCooldown[source] = os_time()
   
   local player = getCachedPlayer(source)
   if not player then return end
   
   -- Validate house
   if not Config.HousesToRob[house] then
       if Config.DropPlayer then
           DropPlayer(source, "Invalid house robbery attempt")
       end
       return
   end
   
   -- Distance check (optimized)
   local ped = GetPlayerPed(source)
   local playerCoords = GetEntityCoords(ped)
   local houseCoords = Config.HousesToRob[house].Coords
   
   if #(playerCoords - vector3(houseCoords.x, houseCoords.y, houseCoords.z)) > 10.0 then
       if Config.DropPlayer then
           DropPlayer(source, "House robbery distance exploit")
       end
       return
   end
   
   -- Cooldown check
   if HouseCooldown[house] and (os_time() - HouseCooldown[house]) < 300 then
       TriggerClientEvent('ox_lib:notify', source, {
           title = 'House Robbery',
           description = 'This house was recently robbed',
           type = 'error'
       })
       return
   end
   
   -- Police check
   local neededPolice = Config.HousesToRob[house].NeedPoliceCount or 0
   if neededPolice > 0 then
       local onlinePolice = getOnlinePoliceCount()
       if onlinePolice < neededPolice then
           TriggerClientEvent('ox_lib:notify', source, {
               title = 'House Robbery',
               description = 'Not enough police online (' .. onlinePolice .. '/' .. neededPolice .. ')',
               type = 'error'
           })
           return
       end
   end
   
   -- Item check
   if Config.Framework == "ESX" then
       local item = player.getInventoryItem(Config.Lockpick.item)
       if not item or item.count < 1 then
           TriggerClientEvent('ox_lib:notify', source, {
               title = 'House Robbery',
               description = 'You need a lockpick',
               type = 'error'
           })
           return
       end
       
       if Config.Lockpick.remove then
           player.removeInventoryItem(Config.Lockpick.item, 1)
       end
   elseif Config.Framework == "qbcore" then
       local item = player.Functions.GetItemByName(Config.Lockpick.item)
       if not item or item.amount < 1 then
           TriggerClientEvent('ox_lib:notify', source, {
               title = 'House Robbery',
               description = 'You need a lockpick',
               type = 'error'
           })
           return
       end
       
       if Config.Lockpick.remove then
           player.Functions.RemoveItem(Config.Lockpick.item, 1)
       end
   end
   
   TriggerClientEvent("marz_houserobbery:lockpick", source, house)
end)

-- Optimized unlock house
RegisterNetEvent("marz_houserobbery:unlockHouse")
AddEventHandler("marz_houserobbery:unlockHouse", function(house)
   local source = source
   
   initializeHouse(house)
   housesData[house].locked = false
   housesData[house].lastActivity = os_time()
   
   -- Only sync to players near the house
   local houseCoords = Config.HousesToRob[house].Coords
   local players = {}
   
   if Config.Framework == "ESX" then
       players = frameworkObject.GetPlayers()
   else
       players = frameworkObject.Functions.GetPlayers()
   end
   
   for i = 1, #players do
       local ped = GetPlayerPed(players[i])
       local coords = GetEntityCoords(ped)
       
       if #(coords - vector3(houseCoords.x, houseCoords.y, houseCoords.z)) < 100.0 then
           TriggerClientEvent("marz_houserobbery:sync", players[i], housesData)
       end
   end
end)

-- Optimized join/leave house
RegisterNetEvent("marz_houserobbery:joinHouse")
AddEventHandler("marz_houserobbery:joinHouse", function(house)
   local source = source
   local player = getCachedPlayer(source)
   if not player then return end
   
   local identifier = getPlayerIdentifier(player)
   initializeHouse(house)
   
   if not housesData[house].players then
       housesData[house].players = {}
   end
   
   -- Check if already in house
   local alreadyIn = false
   for _, id in pairs(housesData[house].players) do
       if id == identifier then
           alreadyIn = true
           break
       end
   end
   
   if not alreadyIn then
       table_insert(housesData[house].players, identifier)
       housesData[house].lastActivity = os_time()
   end
   
   -- Sync only to players in the house
   for _, playerId in pairs(housesData[house].players) do
       local players = {}
       if Config.Framework == "ESX" then
           players = frameworkObject.GetPlayers()
       else
           players = frameworkObject.Functions.GetPlayers()
       end
       
       for _, playerSource in pairs(players) do
           local targetPlayer = getCachedPlayer(playerSource)
           if targetPlayer and getPlayerIdentifier(targetPlayer) == playerId then
               TriggerClientEvent("marz_houserobbery:sync", playerSource, housesData)
               break
           end
       end
   end
end)

RegisterNetEvent("marz_houserobbery:leaveHouse")
AddEventHandler("marz_houserobbery:leaveHouse", function(house)
   local source = source
   local player = getCachedPlayer(source)
   if not player then return end
   
   local identifier = getPlayerIdentifier(player)
   if not housesData[house] or not housesData[house].players then return end
   
   for i = #housesData[house].players, 1, -1 do
       if housesData[house].players[i] == identifier then
           table_remove(housesData[house].players, i)
           break
       end
   end
   
   -- Reset house if empty
   if #housesData[house].players == 0 then
       HouseCooldown[house] = os_time()
       SetTimeout(60000, function()
           if housesData[house] and #housesData[house].players == 0 then
               resetHouse(house)
           end
       end)
   end
end)

-- Optimized robbed events
local robbedCooldown = {}
RegisterNetEvent("marz_houserobbery:robbedHousePlace")
AddEventHandler("marz_houserobbery:robbedHousePlace", function(house, place)
   local source = source
   
   -- Cooldown
   local cooldownKey = source .. "_" .. house .. "_" .. place
   if robbedCooldown[cooldownKey] and (os_time() - robbedCooldown[cooldownKey]) < 2 then
       return
   end
   robbedCooldown[cooldownKey] = os_time()
   
   local player = getCachedPlayer(source)
   if not player then return end
   
   initializeHouse(house)
   
   -- Check if already robbed
   local alreadyRobbed = false
   for _, item in pairs(housesData[house].robbed) do
       if item == place then
           alreadyRobbed = true
           break
       end
   end
   
   if alreadyRobbed then return end
   
   table_insert(housesData[house].robbed, place)
   housesData[house].lastActivity = os_time()
   
   -- Get rewards
   local houseConfig = Config.HousesToRob[house]
   local insidePositions = houseConfig.InsidePositions or (houseConfig.Residence and houseConfig.Residence.InsidePositions)
   
   if insidePositions and insidePositions[place] then
       local placeData = insidePositions[place]
       
       -- Check for nothing
       if placeData.ChanceToFindNothing and math_random(100) <= placeData.ChanceToFindNothing then
           TriggerClientEvent('ox_lib:notify', source, {
               title = 'House Robbery',
               description = 'You found nothing here',
               type = 'inform'
           })
       elseif placeData.Items and #placeData.Items > 0 then
           -- Give random item
           local totalChance = 0
           local chances = {}
           
           for i, itemData in pairs(placeData.Items) do
               totalChance = totalChance + itemData.Chance
               chances[i] = totalChance
           end
           
           local roll = math_random() * totalChance
           
           for i, itemData in pairs(placeData.Items) do
               if roll <= chances[i] then
                   local count = math_random(itemData.MinCount, itemData.MaxCount)
                   
                   if Config.Framework == "ESX" then
                       if itemData.Item == "money" then
                           player.addMoney(count)
                       elseif itemData.Item == "black_money" then
                           player.addAccountMoney("black_money", count)
                       else
                           player.addInventoryItem(itemData.Item, count)
                       end
                   elseif Config.Framework == "qbcore" then
                       if itemData.Item == "money" then
                           player.Functions.AddMoney("cash", count)
                       elseif itemData.Item == "black_money" then
                           player.Functions.AddMoney("crypto", count)
                       else
                           player.Functions.AddItem(itemData.Item, count)
                       end
                   end
                   
                   TriggerClientEvent('ox_lib:notify', source, {
                       title = 'House Robbery',
                       description = 'Found ' .. count .. 'x ' .. itemData.Item,
                       type = 'success'
                   })
                   
                   break
               end
           end
       end
   end
   
   TriggerClientEvent("marz_houserobbery:robbedHouseProp", source, house, place)
   
   -- Sync to players in house only
   for _, playerId in pairs(housesData[house].players) do
       local players = {}
       if Config.Framework == "ESX" then
           players = frameworkObject.GetPlayers()
       else
           players = frameworkObject.Functions.GetPlayers()
       end
       
       for _, playerSource in pairs(players) do
           local targetPlayer = getCachedPlayer(playerSource)
           if targetPlayer and getPlayerIdentifier(targetPlayer) == playerId then
               TriggerClientEvent("marz_houserobbery:sync", playerSource, housesData)
               break
           end
       end
   end
end)

-- Optimized callbacks
lib.callback.register('marz_houserobbery:getitem', function(source, item, amount)
   local player = getCachedPlayer(source)
   if not player then return false end
   
   if Config.Framework == "ESX" then
       local playerItem = player.getInventoryItem(item)
       return playerItem and playerItem.count >= (amount or 1)
   elseif Config.Framework == "qbcore" then
       local playerItem = player.Functions.GetItemByName(item)
       return playerItem and playerItem.amount >= (amount or 1)
   end
   
   return false
end)

lib.callback.register('marz_houserobbery:getitemcount', function(source, item)
   local player = getCachedPlayer(source)
   if not player then return 0 end
   
   if Config.Framework == "ESX" then
       local playerItem = player.getInventoryItem(item)
       return playerItem and playerItem.count or 0
   elseif Config.Framework == "qbcore" then
       local playerItem = player.Functions.GetItemByName(item)
       return playerItem and playerItem.amount or 0
   end
   
   return 0
end)

lib.callback.register('marz_houserobbery:getPlayerMoney', function(source)
   local player = getCachedPlayer(source)
   if not player then return 0 end
   
   if Config.Framework == "ESX" then
       return player.getMoney()
   elseif Config.Framework == "qbcore" then
       return player.PlayerData.money.cash
   end
   
   return 0
end)

lib.callback.register('marz_houserobbery:getident', function(source)
   local player = getCachedPlayer(source)
   if not player then return nil end
   
   return getPlayerIdentifier(player)
end)

-- Cleanup expired cooldowns periodically
CreateThread(function()
   while true do
       Wait(300000) -- Every 5 minutes
       
       local currentTime = os_time()
       
       -- Clean lockpick cooldowns
       for k, v in pairs(lockpickCooldown) do
           if (currentTime - v) > 60 then
               lockpickCooldown[k] = nil
           end
       end
       
       -- Clean robbed cooldowns
       for k, v in pairs(robbedCooldown) do
           if (currentTime - v) > 60 then
               robbedCooldown[k] = nil
           end
       end
       
       -- Clean player cache
       for k, v in pairs(playerCache) do
           if (currentTime - v.time) > 300 then
               playerCache[k] = nil
           end
       end
   end
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
   if resourceName == GetCurrentResourceName() then
       housesData = {}
       HouseCooldown = {}
       playerCache = {}
       lockpickCooldown = {}
       robbedCooldown = {}
   end
end)
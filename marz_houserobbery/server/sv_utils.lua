-- Wait for Config to be loaded
while not Config do
    Wait(100)
end

local ver = '1.0.0'

CreateThread(function()
    if GetResourceState(GetCurrentResourceName()) == 'started' then
        print('^2[MARZ SCRIPTS] ^7House Robbery started on version: ^3' .. ver .. '^7')
    end
end)

-- Framework Detection
if Config.Framework == "ESX" then
    if Config.NewESX then
        ESX = exports["es_extended"]:getSharedObject()
    else
        ESX = nil
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end
elseif Config.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- Usable Items
if Config.Framework == "ESX" then
    ESX.RegisterUsableItem(Config.DuffelBagItem, function(source)
        local src = source
        -- Duffel bag usage logic can be added here if needed
        lib.notify(src, {
            title = 'Duffel Bag',
            description = 'You equipped your duffel bag',
            type = 'success'
        })
    end)
elseif Config.Framework == "qbcore" then
    QBCore.Functions.CreateUseableItem(Config.DuffelBagItem, function(source, item)
        local src = source
        -- Duffel bag usage logic can be added here if needed
        lib.notify(src, {
            title = 'Duffel Bag',
            description = 'You equipped your duffel bag',
            type = 'success'
        })
    end)
end

-- Webhook for logging
local webhook = "YOUR_DISCORD_WEBHOOK_HERE" -- Replace with your webhook

function Logs(source, message)
    if message ~= nil then
        if Config.Logs.enabled then
            local license = nil
            for k, v in pairs(GetPlayerIdentifiers(source)) do
                if string.sub(v, 1, string.len("license:")) == "license:" then
                    license = v
                end
            end
            
            if Config.Logs.type == "webhook" then
                local embed = {
                    {
                        ["color"] = 2600155,
                        ["title"] = "Player: **" .. GetPlayerName(source) .. " | " .. license .. " **",
                        ["description"] = message,
                        ["footer"] = {
                            ["text"] = "Logs by MARZ SCRIPTS - House Robbery System",
                        },
                    }
                }
                PerformHttpRequest(webhook, function(err, text, headers) end, 'POST',
                    json.encode({ username = "MARZ HOUSE ROBBERY", embeds = embed,
                        avatar_url = "https://i.imgur.com/RclET8O.png" })
                    , { ['Content-Type'] = 'application/json' })
            end
        end
    end
end

function GetJob(source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.job.name
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        return xPlayer.PlayerData.job.name
    end
end

function GetItem(name, count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getInventoryItem(name).count >= count then
            return true
        else
            return false
        end
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if xPlayer.Functions.GetItemByName(name) ~= nil then
            if xPlayer.Functions.GetItemByName(name).amount >= count then
                return true
            else
                return false
            end
        else
            return false
        end
    end
end

function AddMoney(count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if Config.DirtyMoney then
            xPlayer.addAccountMoney("black_money", count)
        else
            xPlayer.addMoney(count)
        end
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if Config.DirtyMoney then
            local info = {worth = count}
            xPlayer.Functions.AddItem('markedbills', 1, false, info)
        else
            xPlayer.Functions.AddMoney('cash', count)
        end
    end
end

function RemoveMoney(count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeMoney(count)
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        xPlayer.Functions.RemoveMoney('cash', count)
    end
end

function GetItemCount(name, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getInventoryItem(name).count
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if xPlayer.Functions.GetItemByName(name) ~= nil then
            return xPlayer.Functions.GetItemByName(name).amount
        end
    end
    return 0
end

function GetMoney(count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getMoney() >= count then
            return true
        else
            return false
        end
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if xPlayer.Functions.GetMoney('cash') >= count then
            return true
        else
            return false
        end
    end
end

function AddItem(name, count, source)
    local src = source
    local ismoney = false
    local MoneyTable = {"cash", "money"}
    
    for _, v in pairs(MoneyTable) do
        if v == name then
            ismoney = true
            AddMoney(count, src)
        end
    end
    
    if not ismoney then
        if Config.Framework == "ESX" then
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer then
                xPlayer.addInventoryItem(name, count)
            end
        elseif Config.Framework == "qbcore" then
            local xPlayer = QBCore.Functions.GetPlayer(src)
            if xPlayer then
                xPlayer.Functions.AddItem(name, count, nil, nil)
                TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[name], "add", count)
            end
        end
    end
end

function RemoveItem(name, count, source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeInventoryItem(name, count)
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        xPlayer.Functions.RemoveItem(name, count, nil, nil)
        TriggerClientEvent("inventory:client:ItemBox", source, QBCore.Shared.Items[name], "remove", count)
    end
end

function CheckJob()
    local PoliceCount = 0
    if Config.Framework == "ESX" then
        local xPlayers = ESX.GetPlayers()
        for i = 1, #xPlayers do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
            for _, job in pairs(Config.PoliceJobs) do
                if xPlayer and xPlayer.job.name == job then
                    PoliceCount = PoliceCount + 1
                end
            end
        end
        return PoliceCount
    elseif Config.Framework == "qbcore" then
        local xPlayers = QBCore.Functions.GetPlayers()
        for i = 1, #xPlayers do
            local xPlayer = QBCore.Functions.GetPlayer(xPlayers[i])
            for _, job in pairs(Config.PoliceJobs) do
                if xPlayer and xPlayer.PlayerData.job.name == job then
                    PoliceCount = PoliceCount + 1
                end
            end
        end
        return PoliceCount
    end
end

function GetIdent(source)
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getIdentifier()
    elseif Config.Framework == "qbcore" then
        return QBCore.Functions.GetIdentifier(source, 'license')
    end
end
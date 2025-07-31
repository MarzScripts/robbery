-- Wait for Config to be loaded
while not Config do
    Wait(100)
end

-- Tech Guy Shop Server Events with Enhanced Security
local onTimerShop = {}

-- Get Player Money Callback
lib.callback.register('marz_houserobbery:getPlayerMoney', function(source)
    local src = source
    return GetPlayerMoney(src)
end)

-- Enhanced Buy Tech Item Event
RegisterServerEvent("marz_houserobbery:buyTechItem")
AddEventHandler("marz_houserobbery:buyTechItem", function(item, price, quantity, total)
    local src = source
    
    -- Anti-spam protection
    if onTimerShop[src] and onTimerShop[src] > GetGameTimer() then
        Logs(src, "Tech Shop Timer: Player tried to exploit shop timing")
        TriggerClientEvent("marz_houserobbery:techBuyError", src, "Please wait before making another purchase")
        if Config.DropPlayer then
            DropPlayer(src, "Shop exploit detected")
        end
        return
    end
    
    -- Distance validation
    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    local ShopCoords = Config.Shop.Ped.coords
    local dist = #(vec3(ShopCoords) - srcCoords)
    
    if dist > 25 then
        Logs(src, "Tech Shop Distance: Player tried to exploit shop distance - Distance: " .. dist)
        TriggerClientEvent("marz_houserobbery:techBuyError", src, "You're too far from the shop")
        if Config.DropPlayer then
            DropPlayer(src, "Shop distance exploit detected")
        end
        return
    end
    
    -- Validate item exists in shop
    local validItem = false
    local itemData = nil
    for _, v in pairs(Config.Shop.Items) do
        if item == v.item and price == v.price then
            if quantity >= v.MinAmount and quantity <= v.MaxAmount then
                validItem = true
                itemData = v
                break
            end
        end
    end
    
    if not validItem then
        Logs(src, "Tech Shop Validation: Invalid item or parameters - Item: " .. item .. ", Price: " .. price .. ", Quantity: " .. quantity)
        TriggerClientEvent("marz_houserobbery:techBuyError", src, "Invalid item or quantity")
        if Config.DropPlayer then
            DropPlayer(src, "Shop validation failed")
        end
        return
    end
    
    -- Calculate and validate total
    local calculatedTotal = price * quantity
    if total ~= calculatedTotal then
        Logs(src, "Tech Shop Price: Price manipulation detected - Expected: " .. calculatedTotal .. ", Received: " .. total)
        TriggerClientEvent("marz_houserobbery:techBuyError", src, "Price validation failed")
        if Config.DropPlayer then
            DropPlayer(src, "Price manipulation detected")
        end
        return
    end
    
    -- Check if player has enough money
    local playerMoney = GetPlayerMoney(src)
    if not playerMoney or playerMoney < total then
        Logs(src, "Tech Shop Funds: Insufficient funds - Has: " .. (playerMoney or 0) .. ", Needs: " .. total)
        TriggerClientEvent("marz_houserobbery:techBuyError", src, "You don't have enough money ($" .. total .. " required)")
        return
    end
    
    -- Process the purchase
    onTimerShop[src] = GetGameTimer() + (2 * 1000) -- 2 second cooldown
    
    -- Remove money
    local success = RemovePlayerMoney(total, src)
    if not success then
        Logs(src, "Tech Shop Transaction: Failed to remove money")
        TriggerClientEvent("marz_houserobbery:techBuyError", src, "Transaction failed")
        return
    end
    
    -- Add item to inventory with better error handling
    local itemAdded = false
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            if xPlayer.canCarryItem(item, quantity) then
                xPlayer.addInventoryItem(item, quantity)
                itemAdded = true
            else
                Logs(src, "Tech Shop Inventory: Cannot carry item - " .. item .. " x" .. quantity)
            end
        end
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(src)
        if xPlayer then
            local itemInfo = QBCore.Shared.Items[item]
            if itemInfo then
                if xPlayer.Functions.AddItem(item, quantity) then
                    itemAdded = true
                    TriggerClientEvent("inventory:client:ItemBox", src, itemInfo, "add", quantity)
                else
                    Logs(src, "Tech Shop Inventory: Failed to add item - " .. item .. " x" .. quantity)
                end
            else
                Logs(src, "Tech Shop Item: Item not found in shared items - " .. item)
            end
        end
    end
    
    if not itemAdded then
        -- Refund money if item addition failed
        AddPlayerMoney(total, src)
        Logs(src, "Tech Shop Transaction: Refunded money due to item addition failure")
        TriggerClientEvent("marz_houserobbery:techBuyError", src, "Inventory full or invalid item. Money refunded.")
        return
    end
    
    -- Get updated money amount
    local newMoney = GetPlayerMoney(src)
    
    -- Log successful purchase
    Logs(src, 'Successfully bought ' .. quantity .. 'x ' .. item .. ' for $' .. total .. ' - Remaining money: $' .. newMoney)
    
    -- Send success response
    TriggerClientEvent("marz_houserobbery:techBuySuccess", src, itemData.label, quantity, total, newMoney)
end)

-- Enhanced money functions with error handling
function GetPlayerMoney(source)
    local src = source
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return 0 end
        return xPlayer.getMoney()
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(src)
        if not xPlayer then return 0 end
        return xPlayer.Functions.GetMoney('cash')
    end
    return 0
end

function RemovePlayerMoney(amount, source)
    local src = source
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        if xPlayer.getMoney() >= amount then
            xPlayer.removeMoney(amount)
            return true
        end
        return false
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(src)
        if not xPlayer then return false end
        if xPlayer.Functions.GetMoney('cash') >= amount then
            xPlayer.Functions.RemoveMoney('cash', amount)
            return true
        end
        return false
    end
    return false
end

function AddPlayerMoney(amount, source)
    local src = source
    if Config.Framework == "ESX" then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addMoney(amount)
            return true
        end
    elseif Config.Framework == "qbcore" then
        local xPlayer = QBCore.Functions.GetPlayer(src)
        if xPlayer then
            xPlayer.Functions.AddMoney('cash', amount)
            return true
        end
    end
    return false
end

-- Admin commands for testing
if Config.Debug then
    RegisterCommand('givemoney', function(source, args)
        local src = source
        local amount = tonumber(args[1]) or 10000
        
        if AddPlayerMoney(amount, src) then
            TriggerClientEvent('chat:addMessage', src, {
                color = {0, 255, 0},
                multiline = true,
                args = {"[DEBUG]", "Added $" .. amount .. " to your account"}
            })
        end
    end, false)
    
    RegisterCommand('checkmoney', function(source, args)
        local src = source
        local money = GetPlayerMoney(src)
        
        TriggerClientEvent('chat:addMessage', src, {
            color = {0, 255, 255},
            multiline = true,
            args = {"[DEBUG]", "You have $" .. money}
        })
    end, false)
end
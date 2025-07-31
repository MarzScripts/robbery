-- Wait for Config to be loaded
while not Config do
    Wait(100)
end

-- Tablet Pawn Shop Server Events
local onTimerTablet = {}

RegisterServerEvent("marz_houserobbery:sellToTablet")
AddEventHandler("marz_houserobbery:sellToTablet", function(item, price, amount)
    local src = source
    
    if onTimerTablet[src] and onTimerTablet[src] > GetGameTimer() then
        Logs(src, "Tablet Timer: Player tried to exploit tablet")
        if Config.DropPlayer then
            DropPlayer(src, "Tablet exploit detected")
        end
        return
    end
    
    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    local TabletCoords = Config.TabletShop.Ped.coords
    local dist = #(vec3(TabletCoords) - srcCoords)
    
    if dist <= 20 then
        for _, v in pairs(Config.TabletShop.Items) do
            if item == v.item and price == v.price and amount >= v.MinAmount and amount <= v.MaxAmount then
                if GetItem(item, amount, src) then
                    onTimerTablet[src] = GetGameTimer() + (2 * 1000)
                    AddMoney(price * amount, src)
                    RemoveItem(item, amount, src)
                    Logs(src, 'Sold ' .. amount .. 'x ' .. item .. ' for $' .. (price * amount))
                    TriggerClientEvent("marz_houserobbery:tabletSellSuccess", src, item, amount, price * amount)
                end
            end
        end
    else
        Logs(src, "Tablet Coords: Player tried to exploit tablet distance")
        if Config.DropPlayer then
            DropPlayer(src, "Tablet distance exploit detected")
        end
    end
end)

RegisterServerEvent("marz_houserobbery:sellAllToTablet")
AddEventHandler("marz_houserobbery:sellAllToTablet", function()
    local src = source
    
    if onTimerTablet[src] and onTimerTablet[src] > GetGameTimer() then
        Logs(src, "Tablet Timer: Player tried to exploit tablet sell all")
        if Config.DropPlayer then
            DropPlayer(src, "Tablet exploit detected")
        end
        return
    end
    
    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    local TabletCoords = Config.TabletShop.Ped.coords
    local dist = #(vec3(TabletCoords) - srcCoords)
    local totalPrice = 0
    
    if dist <= 20 then
        for _, v in pairs(Config.TabletShop.Items) do
            if GetItemCount(v.item, src) then
                if GetItemCount(v.item, src) > 0 then
                    local amount = GetItemCount(v.item, src)
                    onTimerTablet[src] = GetGameTimer() + (2 * 1000)
                    totalPrice = totalPrice + (v.price * amount)
                    RemoveItem(v.item, amount, src)
                    Logs(src, 'Sold All: ' .. amount .. 'x ' .. v.item .. ' for $' .. (v.price * amount))
                end
            end
        end
        
        if totalPrice > 0 then
            AddMoney(totalPrice, src)
            TriggerClientEvent("marz_houserobbery:tabletSellAllSuccess", src, totalPrice)
        end
    else
        Logs(src, "Tablet Coords: Player tried to exploit tablet sell all distance")
        if Config.DropPlayer then
            DropPlayer(src, "Tablet distance exploit detected")
        end
    end
end)
-- Wait for Config to be loaded
while not Config do
    Wait(100)
end

-- Underground Marketplace System (combines both stolen goods and tech shop)
local isMarketplaceOpen = false
local currentMarketplaceMode = nil -- 'buy' or 'sell'

-- Create unified NPC for both buying and selling
if Config.TabletShop.enabled or Config.Shop.enabled then
    local MarketplacePed = nil
    local Spawned = false
    
    -- Use the TabletShop config as the primary location
    local pedConfig = Config.TabletShop.Ped
    
    CreateThread(function()
        while true do
            Wait(1000)
            local coords = GetEntityCoords(PlayerPedId())
            local distance = #(coords - vec3(pedConfig.coords.xyz))
            
            if distance < 20 and not Spawned then
                Spawned = true
                RequestModel(pedConfig.model)

                while not HasModelLoaded(pedConfig.model) do
                    Wait(100)
                end

                MarketplacePed = CreatePed(4, pedConfig.model, 
                    pedConfig.coords.x, pedConfig.coords.y, 
                    pedConfig.coords.z, pedConfig.coords.w, false, true)
                    
                -- Fade in ped
                for i = 0, 255, 51 do
                    Wait(50)
                    SetEntityAlpha(MarketplacePed, i, false)
                end
                
                FreezeEntityPosition(MarketplacePed, true)
                SetEntityInvincible(MarketplacePed, true)
                SetBlockingOfNonTemporaryEvents(MarketplacePed, true)
                TaskStartScenarioInPlace(MarketplacePed, pedConfig.scenario, 0, true)
                
                -- Add target interaction for unified system
                if Config.InteractionType == 'target' then
                    local target = exports[Config.Target]
                    target:addLocalEntity(MarketplacePed, {
                        {
                            name = "marz_marketplace_buy",
                            icon = "fas fa-shopping-cart",
                            label = "Buy Equipment",
                            onSelect = function()
                                TriggerEvent("marz_houserobbery:openMarketplace", "buy")
                            end,
                        },
                        {
                            name = "marz_marketplace_sell",
                            icon = "fas fa-money-bill-wave",
                            label = "Sell Stolen Goods",
                            onSelect = function()
                                TriggerEvent("marz_houserobbery:openMarketplace", "sell")
                            end,
                        },
                    })
                end
                
            elseif distance >= 20 and Spawned then
                -- Fade out ped
                for i = 255, 0, -51 do
                    Wait(50)
                    SetEntityAlpha(MarketplacePed, i, false)
                end
                DeletePed(MarketplacePed)
                Spawned = false
            end
        end
    end)
end

-- Open unified marketplace event
RegisterNetEvent("marz_houserobbery:openMarketplace")
AddEventHandler("marz_houserobbery:openMarketplace", function(mode)
    if not isMarketplaceOpen then
        openMarketplace(mode)
    end
end)

-- Legacy events for backwards compatibility
RegisterNetEvent("marz_houserobbery:openTablet")
AddEventHandler("marz_houserobbery:openTablet", function()
    if not isMarketplaceOpen then
        openMarketplace("sell")
    end
end)

RegisterNetEvent("marz_houserobbery:openTechShop")
AddEventHandler("marz_houserobbery:openTechShop", function()
    if not isMarketplaceOpen then
        openMarketplace("buy")
    end
end)

function openMarketplace(mode)
    if isMarketplaceOpen then return end
    
    isMarketplaceOpen = true
    currentMarketplaceMode = mode
    
    if Config.Debug then
        print("Opening marketplace in mode:", mode)
    end
    
    -- Make NPC talk
    if MarketplacePed then
        local speech = mode == "buy" and 'Generic_Hows_It_Going' or 'GENERIC_THANKS'
        PlayPedAmbientSpeechNative(MarketplacePed, speech, 'Speech_Params_Force')
    end
    
    if mode == "buy" then
        -- Get player money for buying
        getPlayerMoney(function(money)
            SendNUIMessage({
                action = "openTechShop",
                items = Config.Shop.Items,
                playerMoney = money
            })
            
            Wait(100)
            SetNuiFocus(true, true)
            doMarketplaceTabletAnimation()
        end)
    else
        -- Get player inventory for selling
        getPlayerInventory(function(inventory)
            SendNUIMessage({
                action = "openTablet",
                items = Config.TabletShop.Items,
                inventory = inventory
            })
            
            Wait(100)
            SetNuiFocus(true, true)
            doMarketplaceTabletAnimation()
        end)
    end
end

function getPlayerMoney(callback)
    lib.callback('marz_houserobbery:getPlayerMoney', false, function(money)
        callback(money or 0)
    end)
end

function getPlayerInventory(callback)
    local inventory = {}
    local itemsChecked = 0
    local totalItems = #Config.TabletShop.Items
    
    if totalItems == 0 then
        callback(inventory)
        return
    end
    
    for _, item in pairs(Config.TabletShop.Items) do
        lib.callback('marz_houserobbery:getitemcount', false, function(count)
            inventory[item.item] = count or 0
            itemsChecked = itemsChecked + 1
            
            if itemsChecked >= totalItems then
                callback(inventory)
            end
        end, item.item)
    end
end

function doMarketplaceTabletAnimation()
    local ped = PlayerPedId()
    local tabletDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
    local tabletAnim = "base"
    local tabletProp = `prop_cs_tablet`
    local tabletBone = 60309
    local tabletOffset = vector3(0.03, 0.002, -0.0)
    local tabletRot = vector3(10.0, 160.0, 0.0)
    
    RequestAnimDict(tabletDict)
    while not HasAnimDictLoaded(tabletDict) do Wait(100) end
    RequestModel(tabletProp)
    while not HasModelLoaded(tabletProp) do Wait(100) end
    
    local tabletObj = CreateObject(tabletProp, 0.0, 0.0, 0.0, true, true, false)
    local tabletBoneIndex = GetPedBoneIndex(ped, tabletBone)
    AttachEntityToEntity(tabletObj, ped, tabletBoneIndex, tabletOffset.x, tabletOffset.y, tabletOffset.z, 
        tabletRot.x, tabletRot.y, tabletRot.z, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(tabletProp)
    
    CreateThread(function()
        while isMarketplaceOpen do
            Wait(0)
            if not IsEntityPlayingAnim(ped, tabletDict, tabletAnim, 3) then
                TaskPlayAnim(ped, tabletDict, tabletAnim, 3.0, 1.0, -1, 49, 0, false, false, false)
            end
        end
        ClearPedSecondaryTask(ped)
        Wait(250)
        DetachEntity(tabletObj, true, false)
        DeleteEntity(tabletObj)
    end)
end

-- NUI Callbacks for unified system
RegisterNUICallback('closeTablet', function(data, cb)
    closeMarketplace()
    cb('ok')
end)

RegisterNUICallback('closeTechShop', function(data, cb)
    closeMarketplace()
    cb('ok')
end)

-- Buy item callback
RegisterNUICallback('buyTechItem', function(data, cb)
    TriggerServerEvent("marz_houserobbery:buyTechItem", data.item, data.price, data.quantity, data.total)
    cb('ok')
end)

-- Sell item callback
RegisterNUICallback('sellItem', function(data, cb)
    TriggerServerEvent("marz_houserobbery:sellToTablet", data.item, data.price, data.quantity)
    cb('ok')
end)

-- Sell all callback
RegisterNUICallback('sellAllItems', function(data, cb)
    TriggerServerEvent("marz_houserobbery:sellAllToTablet")
    cb('ok')
end)

function closeMarketplace()
    if not isMarketplaceOpen then return end
    
    isMarketplaceOpen = false
    currentMarketplaceMode = nil
    SetNuiFocus(false, false)
    
    if Config.Debug then
        print("Closing marketplace...")
    end
    
    SendNUIMessage({
        action = "closeTablet"
    })
end

-- Close tablet with ESC key
CreateThread(function()
    while true do
        Wait(0)
        if isMarketplaceOpen then
            if IsControlJustPressed(0, 322) then -- ESC key
                closeMarketplace()
            end
            
            -- Disable other controls while tablet is open
            DisableControlAction(0, 1, true) -- Mouse look
            DisableControlAction(0, 2, true) -- Mouse look
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 263, true) -- Melee Attack 1
        end
    end
end)

-- Success notifications from server
RegisterNetEvent("marz_houserobbery:techBuySuccess")
AddEventHandler("marz_houserobbery:techBuySuccess", function(itemName, amount, totalPrice, newMoney)
    -- Update money in NUI
    SendNUIMessage({
        action = "updateMoney",
        money = newMoney
    })
    
    lib.notify({
        title = 'Underground Marketplace',
        description = 'Purchased ' .. tostring(amount) .. 'x ' .. tostring(itemName) .. ' for $' .. tostring(totalPrice),
        type = 'success'
    })
end)

RegisterNetEvent("marz_houserobbery:tabletSellSuccess")
AddEventHandler("marz_houserobbery:tabletSellSuccess", function(itemName, amount, totalPrice)
    -- Update inventory after selling
    Wait(500)
    getPlayerInventory(function(inventory)
        SendNUIMessage({
            action = "updateInventory",
            inventory = inventory
        })
    end)
    
    lib.notify({
        title = "Underground Marketplace",
        description = "Sold " .. tostring(amount) .. "x " .. itemName .. " for $" .. tostring(totalPrice),
        type = "success"
    })
end)

RegisterNetEvent("marz_houserobbery:tabletSellAllSuccess")
AddEventHandler("marz_houserobbery:tabletSellAllSuccess", function(totalPrice)
    -- Update inventory after selling
    Wait(1000)
    getPlayerInventory(function(inventory)
        SendNUIMessage({
            action = "updateInventory",
            inventory = inventory
        })
    end)
    
    lib.notify({
        title = "Underground Marketplace",
        description = "Sold all items for $" .. tostring(totalPrice),
        type = "success"
    })
end)

-- Error notifications from server
RegisterNetEvent("marz_houserobbery:techBuyError")
AddEventHandler("marz_houserobbery:techBuyError", function(message)
    lib.notify({
        title = 'Underground Marketplace',
        description = tostring(message),
        type = 'error'
    })
end)

-- Test command for debugging
if Config.Debug then
    RegisterCommand('testmarketplace', function(source, args)
        local mode = args[1] or 'sell'
        print("Test marketplace command executed with mode:", mode)
        openMarketplace(mode)
    end, false)
end
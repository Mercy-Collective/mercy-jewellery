local QBCore = exports['qb-core']:GetCoreObject()
local TimeoutActive = false

-- [ Code ] --

-- [ Needs ] --

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        local RandomColor = math.random(1, 9)
        print('^'..RandomColor..'███╗░░░███╗███████╗██████╗░░█████╗░██╗░░░██╗')
        print('^'..RandomColor..'████╗░████║██╔════╝██╔══██╗██╔══██╗╚██╗░██╔╝')
        print('^'..RandomColor..'██╔████╔██║█████╗░░██████╔╝██║░░╚═╝░╚████╔╝░')
        print('^'..RandomColor..'██║╚██╔╝██║██╔══╝░░██╔══██╗██║░░██╗░░╚██╔╝░░')
        print('^'..RandomColor..'██║░╚═╝░██║███████╗██║░░██║╚█████╔╝░░░██║░░░')
        print('^'..RandomColor..'╚═╝░░░░░╚═╝╚══════╝╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░')
    end
end)

QBCore.Functions.CreateUseableItem('thermite', function(source) 
	TriggerClientEvent('mercy-jewellery:client:Thermite', source) 
end) 

-- [ Callbacks ] --

QBCore.Functions.CreateCallback('mercy-jewellery:server:getCops', function(source, cb)
	local CopAmount = 0
    for k, v in pairs(QBCore.Functions.GetQBPlayers()) do
        if v.PlayerData.job.name == "police" and v.PlayerData.job.onduty then
            CopAmount = CopAmount + 1
        end
    end
    cb(CopAmount)
end)

QBCore.Functions.CreateCallback('mc-jewellery/server/remove-item', function(source, cb, name, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.Functions.RemoveItem(name, amount) then
        cb(true)
    else
        cb(false)
    end
    cb(CopAmount)
end)

-- [ Events ] --

RegisterNetEvent('mercy-jewellery:server:ThermitePtfx', function()
    TriggerClientEvent('mercy-jewellery:client:ThermitePtfx', -1)
end)

RegisterNetEvent('mercy-jewellery:server:setVitrineState', function(StateType, State, VitrineId)
    Config.Locations[VitrineId][StateType] = State
    TriggerClientEvent('mercy-jewellery:client:setVitrineState', -1, StateType, State, VitrineId)
end)

RegisterNetEvent('mercy-jewellery:server:vitrineReward', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local RandomChance = math.random(1, 4)
    local Odd = math.random(1, 4)
    if RandomChance == Odd then
        local RItem = math.random(1, #Config.VitrineRewards)
        local Amount = math.random(Config.VitrineRewards[RItem]["amount"]["min"], Config.VitrineRewards[RItem]["amount"]["max"])
        local RItemData = QBCore.Shared.Items[Config.VitrineRewards[RItem]["item"]]
        if RItemData ~= nil then
            if Player.Functions.AddItem(Config.VitrineRewards[RItem]["item"], Amount) then
                TriggerClientEvent('inventory:client:ItemBox', src, RItemData, 'add')
            else
                TriggerClientEvent('QBCore:Notify', src, 'You have to much in your pocket..', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Item data does not exist, report this to an admin..', 'error')
        end
    else
        local Amount = math.random(2, 4)
        if Player.Functions.AddItem("10kgoldchain", Amount) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["10kgoldchain"], 'add')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You have to much in your pocket..', 'error')
        end
    end
end)

RegisterNetEvent('mercy-jewellery:server:setTimeout', function()
    if not TimeoutActive then
        TimeoutActive = true
        TriggerEvent('qb-scoreboard:server:SetActivityBusy', "jewellery", true)
        Citizen.CreateThread(function()
            Citizen.Wait(Config.Timeout)
            for i=1, #Config.Locations do
                Config.Locations[i]["isOpened"] = false
                TriggerClientEvent('mercy-jewellery:client:setVitrineState', -1, 'isOpened', false, i)
                TriggerClientEvent('mercy-jewellery:client:setAlertState', -1, false)
                TriggerEvent('qb-scoreboard:server:SetActivityBusy', "jewellery", false)
            end
            TimeoutActive = false
        end)
    end
end)
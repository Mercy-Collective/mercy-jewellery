local QBCore = exports['qb-core']:GetCoreObject()
local Smashing, Dealer = false, nil

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    CreateThread(CreateBlips)
    CreateThread(StartLoop)
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    DeleteBlips()
end)

-- [ Code ] --

-- Functions

function CreateBlips()
    Dealer = AddBlipForCoord(Config.JewelleryLocation["coords"]["x"], Config.JewelleryLocation["coords"]["y"], Config.JewelleryLocation["coords"]["z"])
    SetBlipSprite(Dealer, 617)
    SetBlipDisplay(Dealer, 4)
    SetBlipScale(Dealer, 0.7)
    SetBlipAsShortRange(Dealer, true)
    SetBlipColour(Dealer, 3)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Vangelico Jewelry")
    EndTextCommandSetBlipName(Dealer)
end

function DeleteBlips()
    RemoveBlip(Dealer)
end

function StartLoop()
    for k, v in pairs(Config.Locations) do
        exports['qb-target']:AddBoxZone("JewelleryCase"..k, vector3(v.coords.x, v.coords.y, v.coords.z-1), 0.6, 1.2, {
            name = "JewelleryCase"..k,
            heading = v.coords.w,
            debugPoly = false,
            minZ = 37.65,
            maxZ = 38.35,
            }, {
                options = { 
                {
                    action = function()
                        smashVitrine(k)
                    end,
                    icon = 'fas fa-circle',
                    label = 'Smash!',
                    canInteract = function()
                        if v["isOpened"] or v["isBusy"] then 
                            return false
                        end
                        return true
                    end,
                }
            },
            distance = 1.5,
        })
    end
    exports['qb-target']:AddBoxZone("JewelleryThermite", vector3(-595.94, -283.74, 50.32), 0.4, 0.8, {
        name = "JewelleryThermite",
        heading = 302.79,
        debugPoly = false,
        minZ = 50.25,
        maxZ = 51.35,
        }, {
            options = { 
            {
                type = "client",
                event = "mercy-jewellery:client:Thermite",
                icon = 'fas fa-circle',
                label = 'Hack The Security!'
            }
        },
        distance = 1.5,
    })
end

local function loadParticle()
	if not HasNamedPtfxAssetLoaded("scr_jewelheist") then RequestNamedPtfxAsset("scr_jewelheist") end
    while not HasNamedPtfxAssetLoaded("scr_jewelheist") do Wait(0) end
    SetPtfxAssetNextCall("scr_jewelheist")
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(3)
    end
end

local function validWeapon()
    local PlayerPed = PlayerPedId()
    local PedWeapon = GetSelectedPedWeapon(PlayerPed)
    for k, v in pairs(Config.WhitelistedWeapons) do
        if PedWeapon == k then
            return true
        end
    end
    return false
end

local function IsWearingHandshoes()
    local armIndex = GetPedDrawableVariation(PlayerPedId(), 3)
    local model = GetEntityModel(PlayerPedId())
    local retval = true
    if model == `mp_m_freemode_01` then
        if Config.MaleNoHandshoes[armIndex] ~= nil and Config.MaleNoHandshoes[armIndex] then
            retval = false
        end
    else
        if Config.FemaleNoHandshoes[armIndex] ~= nil and Config.FemaleNoHandshoes[armIndex] then
            retval = false
        end
    end
    return retval
end

local function StartSmashingAnim()
    while Smashing do
        loadAnimDict("missheist_jewel")
        TaskPlayAnim(PlayerPedId(), "missheist_jewel", "smash_case", 3.0, 3.0, -1, 2, 0, 0, 0, 0 )
        Wait(500)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "breaking_vitrine_glass", 0.25)
        loadParticle()
        StartParticleFxLoopedAtCoord("scr_jewel_cab_smash", PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
        Wait(2500)
    end
end

local function smashVitrine(k)
    if validWeapon() then
        local PlayerPed = PlayerPedId()
        local PlayerCoords = GetOffsetFromEntityInWorldCoords(PlayerPed, 0, 0.6, 0)
        local PedWeapon = GetSelectedPedWeapon(PlayerPed)
        if math.random(1, 100) <= 80 and not IsWearingHandshoes() then
            TriggerServerEvent("evidence:server:CreateFingerDrop", PlayerCoords)
        elseif math.random(1, 100) <= 5 and IsWearingHandshoes() then
            TriggerServerEvent("evidence:server:CreateFingerDrop", PlayerCoords)
            QBCore.Functions.Notify("You've left a fingerprint on the glass", "error")
        end
        Smashing = true
        QBCore.Functions.Progressbar("smash_vitrine", "Looting case", Config.WhitelistedWeapons[PedWeapon]["timeOut"], false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            TriggerServerEvent('mercy-jewellery:server:setVitrineState', "isOpened", true, k)
            TriggerServerEvent('mercy-jewellery:server:setVitrineState', "isBusy", false, k)
            TriggerServerEvent('mercy-jewellery:server:vitrineReward')
            TriggerServerEvent('mercy-jewellery:server:setTimeout')
            -- TriggerServerEvent('police:server:policeAlert', 'Jewellery Robbery in progress')
            Smashing = false
            TaskPlayAnim(PlayerPed, "missheist_jewel", "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        end, function() -- Cancel
            TriggerServerEvent('mercy-jewellery:server:setVitrineState', "isBusy", false, k)
            Smashing = false
            TaskPlayAnim(PlayerPed, "missheist_jewel", "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        end)
        TriggerServerEvent('mercy-jewellery:server:setVitrineState', "isBusy", true, k)
        CreateThread(StartSmashingAnim)
    else
        QBCore.Functions.Notify('Your weapon does not seem strong enough..', 'error')
    end
end

local ThermiteEffect = function()
    local PlayerPed = PlayerPedId()
    RequestAnimDict("anim@heists@ornate_bank@thermal_charge")
    while not HasAnimDictLoaded("anim@heists@ornate_bank@thermal_charge") do Wait(50) end
    Wait(1500)
    TriggerServerEvent("mercy-jewellery:server:ThermitePtfx")
    Wait(500)
    TaskPlayAnim(PlayerPed, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_intro", 8.0, 8.0, 1000, 36, 1, 0, 0, 0)
    TaskPlayAnim(PlayerPed, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 8.0, 8.0, 3000, 49, 1, 0, 0, 0)
    Wait(25000)
    ClearPedTasks(PlayerPed)
    Wait(2000)
    if Config.DoorLock == 'qb' then
        TriggerServerEvent('qb-doorlock:server:updateState', Config.DoorId, false, false, false, true, false, false)
    elseif Config.DoorLock == 'nui' then
        TriggerServerEvent('nui_doorlock:server:updateState', Config.DoorId, false, false, false, true)
    end
end

local PlantThermite = function()
    QBCore.Functions.TriggerCallback('mc-jewellery/server/remove-item', function(Removed)
        if Removed then
            TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items["thermite"], "remove")
            RequestAnimDict("anim@heists@ornate_bank@thermal_charge")
            RequestModel("hei_p_m_bag_var22_arm_s")
            RequestNamedPtfxAsset("scr_ornate_heist")
            while not HasAnimDictLoaded("anim@heists@ornate_bank@thermal_charge") or not HasModelLoaded("hei_p_m_bag_var22_arm_s") or not HasNamedPtfxAssetLoaded("scr_ornate_heist") do Wait(50) end
            local PlayerPed = PlayerPedId()
            local SceneCoords = vector4(-596.09, -283.64, 50.42, 301.38)
            SetEntityHeading(PlayerPed, SceneCoords.w)
            Wait(100)
            local rotx, roty, rotz = table.unpack(vec3(GetEntityRotation(PlayerPed)))
            local netscene = NetworkCreateSynchronisedScene(SceneCoords.x, SceneCoords.y, SceneCoords.z, rotx, roty, rotz, 2, false, false, 1065353216, 0, 1.3)
            local bag = CreateObject(`hei_p_m_bag_var22_arm_s`, SceneCoords.x, SceneCoords.y, SceneCoords.z,  true,  true, false)
            SetEntityCollision(bag, false, true)
            local x, y, z = table.unpack(GetEntityCoords(PlayerPed))
            local thermite = CreateObject(`hei_prop_heist_thermite`, x, y, z + 0.2,  true,  true, true)
            SetEntityCollision(thermite, false, true)
            AttachEntityToEntity(thermite, PlayerPed, GetPedBoneIndex(PlayerPed, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)
            NetworkAddPedToSynchronisedScene(PlayerPed, netscene, "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 1.5, -4.0, 1, 16, 1148846080, 0)
            NetworkAddEntityToSynchronisedScene(bag, netscene, "anim@heists@ornate_bank@thermal_charge", "bag_thermal_charge", 4.0, -8.0, 1)
            SetPedComponentVariation(PlayerPed, 5, 0, 0, 0)
            NetworkStartSynchronisedScene(netscene)
            Wait(5000)
            DetachEntity(thermite, 1, 1)
            FreezeEntityPosition(thermite, true)
            DeleteObject(bag)
            NetworkStopSynchronisedScene(netscene)
            CreateThread(function()
                Wait(15000)
                DeleteEntity(thermite)
            end)
        end
    end, "thermite", 1)
end

-- Events
RegisterNetEvent('mercy-jewellery:client:Thermite', function()
    local HasThermite = QBCore.Functions.HasItem({"thermite"}, 1)
    if HasThermite then
        local PlayerPed = PlayerPedId()
        local PlayerCoords = GetEntityCoords(PlayerPed)
        if math.random(1, 100) <= 85 and not IsWearingHandshoes() then
            TriggerServerEvent("evidence:server:CreateFingerDrop", GetEntityCoords(PlayerPed))
        end
        local ThermiteDist = #(PlayerCoords - Config.Thermite)
        QBCore.Functions.TriggerCallback('mercy-jewellery:server:getCops', function(CurrentCops)
            if ThermiteDist <= 2.0 then
                if CurrentCops >= Config.RequiredCops then
                    PlantThermite()
                    exports['ps-ui']:Thermite(function(success)
                        if success then
                            ThermiteEffect()
                            -- TriggerServerEvent('police:server:policeAlert', 'Jewellery Robbery in progress')
                            exports['ps-dispatch']:VangelicoRobbery(camId)
                        else
                        QBCore.Functions.Notify("Thermite failed..", "error")
                        end
                    end, 10, 5, 3) -- Time, Gridsize (5, 6, 7, 8, 9, 10), IncorrectBlocks
                else
                    QBCore.Functions.Notify("Not enough police..", "error")
                end
            end
        end)
    else
        QBCore.Functions.Notify("You are missing something(s)..", "error", 2500)
    end
end)

RegisterNetEvent('mercy-jewellery:client:ThermitePtfx', function()
    local ptfx = vector3(-596.17, -282.62, 50.32)
    RequestNamedPtfxAsset("scr_ornate_heist")
    while not HasNamedPtfxAssetLoaded("scr_ornate_heist") do Wait(50) end
    SetPtfxAssetNextCall("scr_ornate_heist")
    local Effect = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", ptfx, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    Wait(27500)
    StopParticleFxLooped(Effect, 0)
end)

RegisterNetEvent("mercy-jewellery:client:ThermitePtfx", function(Coords)
    if not HasNamedPtfxAssetLoaded("scr_ornate_heist") then 
        RequestNamedPtfxAsset("scr_ornate_heist") 
    end
    while not HasNamedPtfxAssetLoaded("scr_ornate_heist") do Wait(0) end
    SetPtfxAssetNextCall("scr_ornate_heist")
    local Effect = StartParticleFxLoopedAtCoord("scr_heist_ornate_thermal_burn", Coords, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    Wait(27500)
    StopParticleFxLooped(Effect, 0)
end)

RegisterNetEvent('mercy-jewellery:client:setVitrineState', function(StateType, State, VitrineId)
    Config.Locations[VitrineId][StateType] = State
end)
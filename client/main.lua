local NDCore = exports["ND_Core"]:GetCoreObject()
local selectedCharacter = NDCore.Functions.GetSelectedCharacter()
local ped
local pedCoords
local worker
local notified = false
local garageOpen = false
local garageLocation
local garageVehicles = {}

if selectedCharacter then
    TriggerServerEvent("ND_VehicleSystem:getVehicles")
end

RegisterNetEvent("ND:setCharacter", function(character)
    if selectedCharacter and character.id == selectedCharacter.id then return end
    TriggerServerEvent("ND_VehicleSystem:getVehicles")
end)

function setVehicleOwned(veh, status)
    DecorSetBool(veh, "ND_OWNED_VEH", status)
end

function getVehicleOwned(veh)
    if not DecorExistOn(veh, "ND_OWNED_VEH") then
        return false
    end
	return DecorGetBool(veh, "ND_OWNED_VEH")
end

function getDoorLock(status)
    if status then
        return 2
    end
    return 1
end

function setVehicleLocked(veh, status)
    DecorSetBool(veh, "ND_LOCKED_VEH", status)
    SetVehicleDoorsLocked(veh, getDoorLock(status))
end

function getVehicleLocked(veh)
    if not DecorExistOn(veh, "ND_LOCKED_VEH") then
        return false
    end
	return DecorGetBool(veh, "ND_LOCKED_VEH")
end

function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(1)
    end
end

function getVehicleBlipSprite(vehicle)
    local class = GetVehicleClass(vehicle)
    local model = GetEntityModel(vehicle)
    local sprite = 225 -- car
    local classBlip = {
        [16] = 423, -- plane
        [8] = 226, -- motorcycle
        [15] = 64, -- helicopter
        [14] = 427, -- boat
        [6] = 825, -- sports
        [7] = 523, -- super
        [2] = 821, -- SUV
        [4] = 663 -- muscle
    }
    local typeBlip = {
        [-1030275036] = 471, -- seashark
        [-1043459709] = 410 -- marquis
    }

    if classBlip[class] then
        sprite = classBlip[class]
    end
    if typeBlip[model] then
        sprite = typeBlip[model]
    end
    return sprite
end

function workerAppearance()
    local handTypes = { -- remmeber test the 1, 2 instead of the 0, 1
        [1] = {0, 1},
        [2] = {2, 3}
    }
    local faceType = math.random(1, 2)
    local faceLook = math.random(0, 2)
    local hands = handTypes[faceType][math.random(1, 2)]
    return faceType - 1, faceLook, hands -- remember test the - 1
end

function spawnWorker(location, faceType, faceLook, hands)
    while not HasModelLoaded(`s_m_y_airworker`) do
        RequestModel(`s_m_y_airworker`)
        Wait(100)
    end
    worker = CreatePed(4, `s_m_y_airworker`, location.x, location.y, location.z - 0.8, location.w, false, false)

    SetPedComponentVariation(worker, 0, faceType, faceLook, 0) -- face
    SetPedComponentVariation(worker, 3, 0, hands, 0) -- hands
    SetPedComponentVariation(worker, 4, 0, 0, 0) -- pants
    SetPedComponentVariation(worker, 8, 0, 0, 0) -- shirt

    SetPedCanBeTargetted(worker, false)
    SetEntityCanBeDamaged(worker, false)
    SetBlockingOfNonTemporaryEvents(worker, true)
    SetPedCanRagdollFromPlayerImpact(worker, false)
    SetPedResetFlag(worker, 249, true)
    SetPedConfigFlag(worker, 185, true)
    SetPedConfigFlag(worker, 108, true)
    SetPedConfigFlag(worker, 208, true)

    loadAnimDict("anim@amb@casino@valet_scenario@pose_d@")
    TaskPlayAnim(worker, "anim@amb@casino@valet_scenario@pose_d@", "base_a_m_y_vinewood_01", 2.0, 8.0, -1, 1, 0, 0, 0, 0)
end

function getEngineStatus(health)
    if health > 950 then
        return "Perfect"
    elseif health > 750 then
        return "Good"
    elseif health > 500 then
        return "Bad"
    end
    return "Very bad"
end

function spawnVehicle(ped, pedCoords, properties)
    RequestModel(properties.model)
    while not HasModelLoaded(properties.model) do
        Wait(10)
    end
    local spawnLocation = garageLocation.vehicleSpawns[math.random(1, #garageLocation.vehicleSpawns)]
    local veh = CreateVehicle(properties.model, spawnLocation.x, spawnLocation.y, spawnLocation.z, spawnLocation.w + (math.random(0, 1) * 180.0), true, false)
    lib.setVehicleProperties(veh, properties)
    setVehicleOwned(veh, true)

    local highestNum = 0
    for _, gVeh in pairs(garageVehicles) do
        if gVeh.last > highestNum then
            highestNum = 0
        end
    end
    garageVehicles[veh] = {}
    garageVehicles[veh].veh = veh
    garageVehicles[veh].last = highestNum + 1
    garageVehicles[veh].locked = true
    setVehicleLocked(veh, true)

    local blip = AddBlipForEntity(veh)
    SetBlipSprite(blip, getVehicleBlipSprite(veh))
    SetBlipColour(blip, 0)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Personal vehicle")
    EndTextCommandSetBlipName(blip)
    SetModelAsNoLongerNeeded(properties.model)
end

function getLastGarageVeh()
    local highestNum = 0
    local vehicle
    for _, veh in pairs(garageVehicles) do
        if veh.last > highestNum then
            highestNum = veh.last
            vehicle = veh.veh
        end
    end
    return vehicle
end

function checkGetVehicle(veh)
    if veh == 0 or not DoesEntityExist(veh) then
        local garageVehicle = getLastGarageVeh()
        if garageVehicle == 0 or not DoesEntityExist(garageVehicle) then
            lib.notify({
                title = "Error",
                description = "No vehicle found.",
                type = "error",
                position = "bottom",
                duration = 3000
            })
            return
        elseif #(pedCoords - GetEntityCoords(garageVehicle)) > 100.0 then
            lib.notify({
                title = "Error",
                description = "Vehicle too far away!",
                type = "error",
                position = "bottom",
                duration = 3000
            })
            return
        elseif #(pedCoords - GetEntityCoords(garageVehicle)) < 100.0 then
            return garageVehicle
        end
        lib.notify({
            title = "Error",
            description = "No vehicle found.",
            type = "error",
            position = "bottom",
            duration = 3000
        })
        return
    elseif #(pedCoords - GetEntityCoords(veh)) > 50.0 then
        lib.notify({
            title = "Error",
            description = "Vehicle too far away!",
            type = "error",
            position = "bottom",
            duration = 3000
        })
        return
    end
    return veh
end

function createMenu(vehicles, garageType)
    local garageTypes = {
        ["water"] = 14,
        ["heli"] = 15,
        ["plane"] = 16
    }
    local menuClass = garageTypes[garageType]
    local options = {
        {
            title = "Park vehicle",
            onSelect = function(args)
                local ped = PlayerPedId()
                local veh = checkGetVehicle(GetVehiclePedIsIn(ped, true))
                if not veh then return end
                if GetPedInVehicleSeat(veh, -1) ~= 0 then
                    lib.notify({
                        title = "Error",
                        description = "Player in vehicle!",
                        type = "error",
                        position = "bottom",
                        duration = 3000
                    })
                    return
                end
                local properties = lib.getVehicleProperties(veh)
                properties.class = GetVehicleClass(veh)
                local vehid = NetworkGetNetworkIdFromEntity(veh)
                local count = 0
                while not vehid and not NetworkDoesNetworkIdExist(vehid) do
                    Wait(10)
                    count = count + 1
                    vehid = NetworkGetNetworkIdFromEntity(veh)
                end
                garageVehicles[veh] = nil
                TriggerServerEvent("ND_VehicleSystem:storeVehicle", vehid, properties)
            end
        }
    }
    for _, vehicle in pairs(vehicles) do
        if vehicle.available and (((garageTypes["water"] ~= vehicle.properties.class and garageTypes["heli"] ~= vehicle.properties.class and garageTypes["plane"] ~= vehicle.properties.class) and not garageTypes[garageType]) or menuClass == vehicle.properties.class) then
            local model = GetLabelText(GetDisplayNameFromVehicleModel(vehicle.properties.model))
            options[#options + 1] = {
                title = model,
                onSelect = function(args)
                    local ped = PlayerPedId()
                    TriggerServerEvent("ND_VehicleSystem:takeVehicle", vehicle)
                    spawnVehicle(ped, GetEntityCoords(ped), vehicle.properties)
                end,
                metadata = {
                    {label = "Plate", value = vehicle.plate},
                    {label = "Fuel", value = vehicle.properties.fuelLevel .. "%"},
                    {label = "Make", value = GetLabelText(GetMakeNameFromVehicleModel(vehicle.properties.model))},
                    {label = "Model", value = model},
                    {label = "Engine status", value = getEngineStatus(vehicle.properties.engineHealth)}
                }
            }
        end
    end
    return {
        id = garageType .. "Garage",
        title = "Parking garage",
        onExit = function()
            garageOpen = false
        end,
        options = options
    }
end

RegisterCommand("test", function(source, args, rawCommand)
    local props = lib.getVehicleProperties(GetVehiclePedIsIn(ped))
    props.class = GetVehicleClass(GetVehiclePedIsIn(ped))
    TriggerServerEvent("test", props)
end, false)

RegisterNetEvent("ND_VehicleSystem:returnVehicles", function(vehicles)
    lib.registerContext(createMenu(vehicles, "land"))
    lib.registerContext(createMenu(vehicles, "water"))
    lib.registerContext(createMenu(vehicles, "plane"))
    lib.registerContext(createMenu(vehicles, "heli"))
end)

CreateThread(function()
    local inVehcile = false
    local blip
    while true do
        Wait(500)
        local veh = GetVehiclePedIsIn(ped)
        if veh ~= 0 and garageVehicles[veh] then
            inVehcile = true
            blip = GetBlipFromEntity(veh)
            SetBlipAlpha(blip, 0)
        elseif inVehcile then
            SetBlipAlpha(blip, 255)
        end
    end
end)

CreateThread(function()
    DecorRegister("ND_OWNED_VEH", 2)
    DecorRegister("ND_LOCKED_VEH", 2)

    local sprite = {
        ["water"] = 356,
        ["heli"] = 360,
        ["plane"] = 359,
        ["land"] = 357
    }

    for _, location in pairs(parkingLocations) do
        local blip = AddBlipForCoord(location.ped.x, location.ped.y, location.ped.z)
        SetBlipSprite(blip, sprite[location.garageType])
        SetBlipColour(blip, 3)
        SetBlipScale(blip, 0.7)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Parking garage (" .. location.garageType .. ")")
        EndTextCommandSetBlipName(blip)
    end

    local wait = 500
    while true do
        Wait(wait)
        ped = PlayerPedId()
        pedCoords = GetEntityCoords(ped)
        local nearParking = false
        for _, location in pairs(parkingLocations) do
            local dist = #(pedCoords - vector3(location.ped.x, location.ped.y, location.ped.z))
            if dist < 80.0 then
                nearParking = true
                if not worker then
                    if not location.pedAppearance then
                        local faceType, faceLook, hands = workerAppearance()
                        location.pedAppearance = {faceType = faceType, faceLook = faceLook, hands = hands}
                    end
                    spawnWorker(location.ped, location.pedAppearance.faceType, location.pedAppearance.faceLook, location.pedAppearance.hands)
                end
                if dist < 1.8 then
                    wait = 0
                    if not notified or not garageOpen then
                        lib.showTextUI("[E] - View your vehicles")
                        notified = true
                    end
                    if IsControlJustPressed(0, 51) then
                        garageLocation = location
                        lib.showContext(location.garageType .. "Garage")
                        lib.hideTextUI()
                        garageOpen = true
                    end
                else
                    wait = 500
                    if notified then
                        lib.hideTextUI()
                        notified = false
                    end
                end
                break
            end
        end
        if not nearParking and worker then
            DeletePed(worker)
            worker = false
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if worker then
        DeletePed(worker)
    end
end)

function getClosestOwnedVeh()
    local vehicle
    local closestVehDist = 500.0
    for _, veh in pairs(garageVehicles) do
        local vehDist = #(GetEntityCoords(veh.veh) - pedCoords)
        if vehDist < closestVehDist then
            closestVehDist = vehDist
            vehicle = veh
        end
    end
    return vehicle, closestVehDist
end

RegisterCommand("+vehicleLocks", function()
    local vehicle, dist = getClosestOwnedVeh()
    if not vehicle then return end
    if dist > 25.0 then
        lib.notify({
            title = "No signal",
            description = "Vehicle to far away.",
            type = "error",
            position = "bottom",
            duration = 3000
        })
        return
    end
    vehicle.locked = not vehicle.locked
    setVehicleLocked(vehicle.veh, vehicle.locked)
    if vehicle.locked then
        lib.notify({
            title = "LOCKED",
            description = "Your vehicle has now been locked.",
            type = "success",
            position = "bottom",
            duration = 3000
        })
    else
        lib.notify({
            title = "UNLOCKED",
            description = "Your vehicle has now been unlocked.",
            type = "inform",
            position = "bottom",
            duration = 3000
        })
    end

    Wait(600)
    PlaySoundFromEntity(-1, "Remote_Control_Fob", ped, "PI_Menu_Sounds", true, 0)
    if GetVehiclePedIsIn(ped) ~= 0 then return end
    
    loadAnimDict("anim@mp_player_intmenu@key_fob@")
    TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
    local keyFob = CreateObject(`lr_prop_carkey_fob`, 0, 0, 0, true, true, true)
    AttachEntityToEntity(keyFob, ped, GetPedBoneIndex(ped, 0xDEAD), 0.12, 0.04, -0.025, -100.0, 100.0, 0.0, true, true, false, true, 1, true)
    SetVehicleLights(vehicle.veh, 2)
    Wait(100)
    SetVehicleLights(vehicle.veh, 0)
    Wait(200)
    SetVehicleLights(vehicle.veh, 2)
    Wait(100)
    SetVehicleLights(vehicle.veh, 0)
    Wait(200)
    DeleteEntity(keyFob)
end, false)
RegisterCommand("-vehicleLocks", function()end, false)
RegisterKeyMapping("+vehicleLocks", "Vehicle: Lock/Unlock", "keyboard", "o")
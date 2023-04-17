lib.callback.register("ND_VehicleSystem:getParkedVehicle", function(coords)
    local parkedVeh = lib.getNearbyVehicles(coords, 1.5, false)
    if not parkedVeh or not next(parkedVeh) or not parkedVeh[1].vehicle then
        return true
    end
end)

function jobHasAccess(job, garage)
    if not garage.jobs then return true end
    for _, jobName in pairs(garage.jobs) do
        if job == jobName then return true end
    end
    return false
end

function getPedSeat(ped, vehicle)
    for i = -1, 6 do
        local seat = GetPedInVehicleSeat(vehicle, i)
        if ped == seat then
            return i
        end
    end
end

function setVehicleStolen(veh, status)
    DecorSetBool(veh, "ND_STOLEN_VEH", status)
end

function getVehicleStolen(veh)
    if not DecorExistOn(veh, "ND_STOLEN_VEH") then
        return false
    end
	return DecorGetBool(veh, "ND_STOLEN_VEH")
end

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
    return status and 2 or 1
end

function setVehicleLocked(veh, status)
    DecorSetBool(veh, "ND_LOCKED_VEH", status)
    SetVehicleDoorsLocked(veh, getDoorLock(status))
end

function getVehicleLocked(veh)
    local status = GetVehicleDoorLockStatus(veh)
    return (status > 1 and DecorExistOn(veh, "ND_LOCKED_VEH")) and DecorGetBool(veh, "ND_LOCKED_VEH")
end

function setVehicleEngine(veh, status)
    DecorSetBool(veh, "ND_ENGINE_VEH", status)
    SetVehicleEngineOn(veh, status, true, true)
end

function getVehicleEngine(veh)
    return DecorExistOn(veh, "ND_ENGINE_VEH") and DecorGetBool(veh, "ND_ENGINE_VEH")
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
    local handTypes = {
        [1] = {0, 1},
        [2] = {2, 3}
    }
    local faceType = math.random(1, 2)
    local faceLook = math.random(0, 2)
    local hands = handTypes[faceType][math.random(1, 2)]
    return faceType - 1, faceLook, hands
end

function spawnWorker(location, faceType, faceLook, hands)
    while not HasModelLoaded(`s_m_y_airworker`) do
        RequestModel(`s_m_y_airworker`)
        Wait(100)
    end
    local worker = CreatePed(4, `s_m_y_airworker`, location.x, location.y, location.z - 0.8, location.w, false, false)

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
    SetPedCanRagdoll(worker, false)

    loadAnimDict("anim@amb@casino@valet_scenario@pose_d@")
    TaskPlayAnim(worker, "anim@amb@casino@valet_scenario@pose_d@", "base_a_m_y_vinewood_01", 2.0, 8.0, -1, 1, 0, 0, 0, 0)
    return worker
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

function isVehicleOwned(vehicle)
    if not selectedCharacter then return end
    local state = Entity(vehicle).state
    return (state.owner and state.owner == selectedCharacter.id)
end

function hasVehicleKeys(vehicle)
    if not selectedCharacter then return end
    local state = Entity(vehicle).state
    return (state.keys and state.keys[selectedCharacter.id])
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

function getClosestVehicle(ownedOnly)
    if not selectedCharacter then return end
    
    local vehicle
    local closestVehDist = 100.0
    local vehicleCoords
    local vehicles = lib.getNearbyVehicles(pedCoords, 100, true)

    for _, veh in pairs(vehicles) do
        local state = Entity(veh.vehicle).state
        local keys = state.keys
        if keys then
            if ownedOnly then
                local owner = state.owner
                if owner and owner == selectedCharacter.id and keys[selectedCharacter.id] then
                    local vehCoords = GetEntityCoords(veh.vehicle)
                    local vehDist = #(vehCoords - pedCoords)
                    if vehDist < closestVehDist then
                        vehicle = veh.vehicle
                        closestVehDist = vehDist
                        vehicleCoords = vehCoords
                    end
                end
            elseif keys[selectedCharacter.id] then
                local vehCoords = GetEntityCoords(veh.vehicle)
                local vehDist = #(vehCoords - pedCoords)
                if vehDist < closestVehDist then
                    vehicle = veh.vehicle
                    closestVehDist = vehDist
                    vehicleCoords = vehCoords
                end
            end
        end
    end

    return vehicle, closestVehDist, vehicleCoords
end

function lockpickVehicle()
    if GetVehiclePedIsIn(ped) ~= 0 then return false, false end
    local veh = lib.getClosestVehicle(pedCoords, 2.5, false)
    if not veh then return false, false end

    local finished = false
    local dificulties = {
        "easy",
        "medium",
        "hard"
    }

    CreateThread(function()
        loadAnimDict("veh@break_in@0h@p_m_one@")
        while not finished do
            TaskPlayAnim(ped, "veh@break_in@0h@p_m_one@", "std_force_entry_ds", 8.0, 5.0, 1800, 31, 0.1, false, false, false)
            Wait(1800)
        end
    end)

    for i = 1, 7 do
        local success = lib.skillCheck(dificulties[math.random(1, #dificulties)])
        if not success or not DoesEntityExist(veh) or #(pedCoords - GetEntityCoords(veh)) > 2.5 then
            TriggerServerEvent("ND_VehicleSystem:syncAlarm", NetworkGetNetworkIdFromEntity(veh), false)
            finished = true
            return false, true
        end
        Wait(800)
    end
    
    finished = true
    local veh = lib.getClosestVehicle(pedCoords, 2.5, false)
    if not veh then return false, true end
    TriggerServerEvent("ND_VehicleSystem:syncAlarm", NetworkGetNetworkIdFromEntity(veh), true, "lockpick")
    return true, true
end

function hotwireVehicle()
    local veh = GetVehiclePedIsIn(ped)
    if veh == 0 then return false, false end

    local seat = getPedSeat(ped, veh)
    if seat ~= -1 then return false, false end

    local dificulties = {
        "easy",
        "medium",
        "hard"
    }

    loadAnimDict("veh@handler@base")
    TaskPlayAnim(ped, "veh@handler@base", "hotwire", 2.0, 8.0, -1, 48, 0, false, false, false)

    for i = 1, 7 do
        local success = lib.skillCheck(dificulties[math.random(1, #dificulties)])
        if not success or not DoesEntityExist(veh) or GetVehiclePedIsIn(ped) == 0 then
            ClearPedTasks(ped)
            TriggerServerEvent("ND_VehicleSystem:syncAlarm", NetworkGetNetworkIdFromEntity(veh), false)
            return false, true
        end
        Wait(800)
    end
    ClearPedTasks(ped)
    
    veh = GetVehiclePedIsIn(ped)
    if not veh then return false, true end
    setVehicleEngine(veh, true)
    TriggerServerEvent("ND_VehicleSystem:syncAlarm", NetworkGetNetworkIdFromEntity(veh), true, "hotwire")
    return true, true
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
                    TriggerServerEvent("ND_VehicleSystem:takeVehicle", vehicle, garageLocation.vehicleSpawns)
                end,
                metadata = {
                    {label = "Plate", value = vehicle.properties.plate},
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
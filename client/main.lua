NDCore = exports["ND_Core"]:GetCoreObject()
selectedCharacter = NDCore.Functions.GetSelectedCharacter()

worker = nil
ped = nil
pedCoords = nil
garageVehicles = {}
garageOpen = false
garageBlips = {}
crusieControl = false
cruiseSpeed = 0
vehSpeed = 0

local notified = false

local vehicleClassNotDisableAirControl = {
    [8] = true, --motorcycle
    [13] = true, --bicycles
    [14] = true, --boats
    [15] = true, --helicopter
    [16] = true, --plane
    [19] = true --military
}

if selectedCharacter then
    TriggerServerEvent("ND_VehicleSystem:getVehicles")
end

RegisterNetEvent("ND:setCharacter", function(character)
    if selectedCharacter and character.id == selectedCharacter.id then return end
    selectedCharacter = character
    TriggerServerEvent("ND_VehicleSystem:getVehicles")

    for _, blip in pairs(garageBlips) do
        RemoveBlip(blip)
    end

    local sprite = {
        ["water"] = 356,
        ["heli"] = 360,
        ["plane"] = 359,
        ["land"] = 357
    }

    for _, location in pairs(parkingLocations) do
        if jobHasAccess(selectedCharacter.job, location) then
            local blip = AddBlipForCoord(location.ped.x, location.ped.y, location.ped.z)
            garageBlips[#garageBlips+1] = blip
            SetBlipSprite(blip, sprite[location.garageType])
            SetBlipColour(blip, 3)
            SetBlipScale(blip, 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Parking garage (" .. location.garageType .. ")")
            EndTextCommandSetBlipName(blip)
        end
    end
end)

RegisterNetEvent("ND_VehicleSystem:returnVehicles", function(vehicles)
    lib.registerContext(createMenu(vehicles, "land"))
    lib.registerContext(createMenu(vehicles, "water"))
    lib.registerContext(createMenu(vehicles, "plane"))
    lib.registerContext(createMenu(vehicles, "heli"))
end)

CreateThread(function()
    local wait = 1000
    while true do
        Wait(wait)
        
        --- cruise control
        if veh ~= 0 and cruiseControl then
            wait = 0
            vehSpeed = GetEntitySpeed(veh) * 2.236936
            if vehSpeed < cruiseSpeed then
                SetControlNormal(0, 71, 0.6)
            end
            if vehSpeed < cruiseSpeed/3 then
                cruiseControl = false
                lib.notify({
                    title = "Cruise control",
                    description = "Vehicle cruise control disabled.",
                    type = "inform",
                    position = "bottom-right",
                    duration = 3000
                })
            end
        elseif cruiseControl then
            wait = 1000
            cruiseControl = false
            lib.notify({
                title = "Cruise control",
                description = "Vehicle cruise control disabled.",
                type = "inform",
                position = "bottom-right",
                duration = 3000
            })
        else
            wait = 1000
        end
        
    end
end)

CreateThread(function()
    local inVehcile = false
    local carBlip
    local wait = 500
    local angle = 0.0
    while true do
        Wait(wait)
        local veh = GetVehiclePedIsIn(ped)
        local seat = getPedSeat(ped, veh)

        if veh ~= 0 and seat == -1 then
            -- save wheels steering angle.
            local steeringAngle = GetVehicleSteeringAngle(veh)
            if steeringAngle > 10.0 or steeringAngle < -10.0 then
                angle = steeringAngle
            end
            if GetIsTaskActive(ped, 2) then
                SetVehicleSteeringAngle(veh, angle)
            end
            
            -- disable vehicle air control.
            if config.disableVehicleAirControl and not vehicleClassNotDisableAirControl[GetVehicleClass(veh)] and (IsEntityInAir(veh) or IsEntityUpsidedown(veh)) then
                wait = 0
                DisableControlAction(0, 59)
                DisableControlAction(0, 60)
            elseif not hasVehicleKeys(veh) and not GetIsVehicleEngineRunning(veh) then
                wait = 10
                -- don't turn on engine if no keys.
                if IsVehicleEngineStarting(veh) and not getVehicleEngine(veh) then
                    SetVehicleEngineOn(veh, false, true, true)
                end
            else
                wait = 500
            end
        elseif wait == 0 or wait == 10 then
            wait = 500
        end

        -- make blip transparent if in vehicle.
        if veh ~= 0 and isVehicleOwned(veh) then
            inVehcile = true
            carBlip = GetBlipFromEntity(veh)
            SetBlipAlpha(carBlip, 0)
        elseif inVehcile then
            inVehcile = false
            SetBlipAlpha(carBlip, 255)
        end

        -- check if ped is trying to enter a vehicle and lock if it's locked.
        veh = GetVehiclePedIsTryingToEnter(ped)
        if veh ~= 0 then
            local locked = getVehicleLocked(veh)      
            setVehicleLocked(veh, locked)

            -- lock traffic vehicles
            if not isVehicleOwned(veh) and not locked and not getVehicleStolen(veh) and not IsVehicleDoorFullyOpen(veh, -1) then
                local class = GetVehicleClass(veh)
                if math.random(0, 100) > config.randomUnlockedVehicleChance and (class ~= 8 and class ~= 13 and class ~= 14) then
                    setVehicleLocked(veh, true)
                end
                SetVehicleNeedsToBeHotwired(veh, false)
                setVehicleStolen(veh, true)
                if GetIsVehicleEngineRunning(veh) and not getVehicleEngine(veh) then
                    setVehicleEngine(veh, true)
                end
            end
        end
    end
end)

CreateThread(function()
    DecorRegister("ND_OWNED_VEH", 2)
    DecorRegister("ND_LOCKED_VEH", 2)
    DecorRegister("ND_ENGINE_VEH", 2)
    DecorRegister("ND_STOLEN_VEH", 2)

    local sprite = {
        ["water"] = 356,
        ["heli"] = 360,
        ["plane"] = 359,
        ["land"] = 357
    }

    if selectedCharacter then
        for _, location in pairs(parkingLocations) do
            if jobHasAccess(selectedCharacter.job, location) then
                local blip = AddBlipForCoord(location.ped.x, location.ped.y, location.ped.z)
                garageBlips[#garageBlips+1] = blip
                SetBlipSprite(blip, sprite[location.garageType])
                SetBlipColour(blip, 3)
                SetBlipScale(blip, 0.7)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("Parking garage (" .. location.garageType .. ")")
                EndTextCommandSetBlipName(blip)
            end
        end
    end

    local cachedPed = PlayerPedId()
    SetPedConfigFlag(cachedPed, 184, true)

    local wait = 500
    while true do
        Wait(wait)
        ped = PlayerPedId()
        pedCoords = GetEntityCoords(ped)
        if ped ~= cachedPed then
            cachedPed = ped
            SetPedConfigFlag(ped, 184, true)
        end
        local nearParking = false
        for _, location in pairs(parkingLocations) do
            local dist = #(pedCoords - vector3(location.ped.x, location.ped.y, location.ped.z))
            if selectedCharacter and dist < 80.0 and jobHasAccess(selectedCharacter.job, location) then
                nearParking = true
                if not worker then
                    if not location.pedAppearance then
                        local faceType, faceLook, hands = workerAppearance()
                        location.pedAppearance = {faceType = faceType, faceLook = faceLook, hands = hands}
                    end
                    worker = spawnWorker(location.ped, location.pedAppearance.faceType, location.pedAppearance.faceLook, location.pedAppearance.hands)
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

RegisterNetEvent("ND_VehicleSystem:syncAlarm", function(netid, success, action)
    local veh = NetworkDoesNetworkIdExist(netid) and NetworkGetEntityFromNetworkId(netid)
    if not veh then return end
    SetVehicleAlarmTimeLeft(veh, 1)
    SetVehicleAlarm(veh, true)
    StartVehicleAlarm(veh)
    if not success then return end
    if action == "lockpick" then
        setVehicleLocked(veh, false)
    end
end)

RegisterNetEvent("ND_VehicleSystem:removeBlip", function(netid)
    local veh = NetworkDoesNetworkIdExist(netid) and NetworkGetEntityFromNetworkId(netid)
    if not veh then return end
    local blip = GetBlipFromEntity(veh)
    RemoveBlip(blip)
end)

RegisterNetEvent("ND_VehicleSystem:setOwnedIfNot", function(netid)
    local tries = 0
    local veh = NetworkDoesNetworkIdExist(netid) and NetworkGetEntityFromNetworkId(netid)
    while not veh and tries < 5 do
        Wait(100)
        veh = NetworkDoesNetworkIdExist(netid) and NetworkGetEntityFromNetworkId(netid)
    end
    setVehicleOwned(veh, true)
    setVehicleLocked(veh, true)
end)

AddStateBagChangeHandler("owner", nil, function(bagName, key, value, reserved, replicated)
    if not value then return end
    Wait(50)
    
    if value ~= selectedCharacter.id then return end

    local netId = tonumber(bagName:gsub("entity:", ""), 10)
    local entity = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId)
    if not entity then return end

    local blip = AddBlipForEntity(entity)
    SetBlipSprite(blip, getVehicleBlipSprite(entity))
    SetBlipColour(blip, 0)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Personal vehicle")
    EndTextCommandSetBlipName(blip)
end)

AddStateBagChangeHandler("props", nil, function(bagName, key, value, reserved, replicated)
    if not value then return end
    Wait(50)

    local netId = tonumber(bagName:gsub("entity:", ""), 10)
    local entity = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId)
    if not entity then return end

    for i = -1, 0 do
        local pedInVeh = GetPedInVehicleSeat(entity, i)

        if pedInVeh ~= ped and pedInVeh > 0 and NetworkGetEntityOwner(pedInVeh) == PlayerId() then
            DeleteEntity(pedInVeh)
        end
    end

    if NetworkGetEntityOwner(entity) == PlayerId() then
        lib.setVehicleProperties(entity, value)
        SetVehicleOnGroundProperly(entity)
        setVehicleOwned(entity, true)
        setVehicleLocked(entity, true)
        SetVehicleEngineOn(entity, false, true, true)

        local highestNum = 0
        for _, gVeh in pairs(garageVehicles) do
            if gVeh.last > highestNum then
                highestNum = gVeh.last
            end
        end
        garageVehicles[entity] = {}
        garageVehicles[entity].veh = entity
        garageVehicles[entity].last = highestNum + 1
    end
end)

-- Resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if worker then
        DeletePed(worker)
    end
end)

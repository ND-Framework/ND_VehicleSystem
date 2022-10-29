local NDCore = exports["ND_Core"]:GetCoreObject()
local selectedCharacter = NDCore.Functions.GetSelectedCharacter()
local worker
local notified = false
ped = nil
pedCoords = nil
garageVehicles = {}
garageOpen = false

if selectedCharacter then
    TriggerServerEvent("ND_VehicleSystem:getVehicles")
end

RegisterNetEvent("ND:setCharacter", function(character)
    if selectedCharacter and character.id == selectedCharacter.id then return end
    TriggerServerEvent("ND_VehicleSystem:getVehicles")
end)

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
        if veh ~= 0 and isVehicleOwned(veh) then
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

AddEventHandler("onResourceStop", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if worker then
        DeletePed(worker)
    end
end)

RegisterCommand("+vehicleLocks", function()
    if GetVehiclePedIsEntering(ped) ~= 0 then return end
    local vehicle, dist = getClosestOwnedVeh()
    if not vehicle then return end
    if dist > 25.0 then
        lib.notify({
            title = "No signal",
            description = "Vehicle to far away.",
            type = "error",
            position = "bottom-right",
            duration = 3000
        })
        return
    end
    vehicle.locked = not getVehicleLocked(vehicle.veh)
    setVehicleLocked(vehicle.veh, vehicle.locked)
    if IsVehicleAlarmActivated(vehicle.veh) then
        SetVehicleAlarm(vehicle.veh, false)
    end

    local keyFob
    if GetVehiclePedIsIn(ped) == 0 then
        ClearPedTasks(ped)
        loadAnimDict("anim@mp_player_intmenu@key_fob@")
        TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
        keyFob = CreateObject(`lr_prop_carkey_fob`, 0, 0, 0, true, true, true)
        AttachEntityToEntity(keyFob, ped, GetPedBoneIndex(ped, 0xDEAD), 0.12, 0.04, -0.025, -100.0, 100.0, 0.0, true, true, false, true, 1, true)
    end

    Wait(600)
    SetVehicleLights(vehicle.veh, 2)
    Wait(100)
    SetVehicleLights(vehicle.veh, 0)

    PlaySoundFromEntity(-1, "Remote_Control_Fob", ped, "PI_Menu_Sounds", true, 0)
    if vehicle.locked then
        lib.notify({
            title = "LOCKED",
            description = "Your vehicle has now been locked.",
            type = "success",
            position = "bottom-right",
            duration = 3000
        })
    else
        lib.notify({
            title = "UNLOCKED",
            description = "Your vehicle has now been unlocked.",
            type = "inform",
            position = "bottom-right",
            duration = 3000
        })
    end

    Wait(200)
    SetVehicleLights(vehicle.veh, 2)
    Wait(100)
    SetVehicleLights(vehicle.veh, 0)
    Wait(200)
    if keyFob then
        DeleteEntity(keyFob)
    end
end, false)
RegisterCommand("-vehicleLocks", function()end, false)
RegisterKeyMapping("+vehicleLocks", "Vehicle: Lock/Unlock", "keyboard", "o")

RegisterCommand("lockpick", function(source, args, rawCommand)
    lockpickVehicle()
end, false)
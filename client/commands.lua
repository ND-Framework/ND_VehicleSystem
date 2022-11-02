-- LOCK / UNLOCK Vehicle
local allowLock = true
RegisterCommand("+vehicleLocks", function()
    if GetVehiclePedIsEntering(ped) ~= 0 then return end
    local vehicle, dist = getClosestVehicles(false)
    if not vehicle or not allowLock then return end
    allowLock = false
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
    local locked = not getVehicleLocked(vehicle.veh)
    setVehicleLocked(vehicle.veh, locked)
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
    if locked then
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
    allowLock = true
end, false)
RegisterCommand("-vehicleLocks", function()end, false)
RegisterKeyMapping("+vehicleLocks", "Vehicle: Lock/Unlock", "keyboard", "o")


-- Shuffle vehicle seats.
RegisterCommand("+vehicleShuffle", function()
    local veh = GetVehiclePedIsIn(ped)
    if veh == 0 then return end
    local seat = getPedSeat(ped, veh)
    local seats = {
        [-1] = 0,
        [0] = -1,
        [1] = 2,
        [2] = 1,
        [3] = 4,
        [4] = 3,
        [5] = 6,
        [6] = 5
    }
    SetPedIntoVehicle(ped, veh, seats[seat])
end, false)
RegisterCommand("-vehicleShuffle", function()end, false)
RegisterKeyMapping("+vehicleShuffle", "Vehicle: shuffle seat", "keyboard", "")


-- Toggle cruise control.
RegisterCommand("+vehicleCruiseControl", function()
    if cruiseControl then
        if vehSpeed-1 > cruiseSpeed then
            cruiseSpeed = vehSpeed
            lib.notify({
                title = "Cruise control",
                description = "Increased to " .. math.floor(cruiseSpeed) .. " mph.",
                type = "inform",
                position = "bottom-right",
                duration = 3000
            })
        else
            cruiseControl = false
            lib.notify({
                title = "Cruise control",
                description = "Vehicle cruise control disabled.",
                type = "inform",
                position = "bottom-right",
                duration = 3000
            })
        end
    else
        veh = GetVehiclePedIsIn(ped)
        if veh ~= 0 then
            cruiseControl = true
            vehSpeed = math.floor(GetEntitySpeed(veh) * 2.236936)
            cruiseSpeed = vehSpeed
            lib.notify({
                title = "Cruise control",
                description = "Set to " .. math.floor(cruiseSpeed) .. " mph.",
                type = "inform",
                position = "bottom-right",
                duration = 3000
            })
        end
    end
end, false)
RegisterCommand("-vehicleCruiseControl", function()end, false)
RegisterKeyMapping("+vehicleCruiseControl", "Vehicle: cruise control", "keyboard", "")

-- Chat suggestion.
TriggerEvent("chat:addSuggestion", "/givekeys", "Give keys to your current or last driven owned vehicle.", {
    { name="Player ID", help="Player server ID that will receive the keys." }
})




-- testing
RegisterCommand("lockpick", function(source, args, rawCommand)
    lockpickVehicle()
end, false)

RegisterCommand("hotwire", function(source, args, rawCommand)
    hotwireVehicle()
end, false)
TriggerEvent("chat:addSuggestion", "/lockpick", "Lockpick a nearby vehicle door.", {})
TriggerEvent("chat:addSuggestion", "/hotwire", "Hotwire the current vehicle.", {})

RegisterCommand("test", function(source, args, rawCommand)
    local props = lib.getVehicleProperties(GetVehiclePedIsIn(ped))
    props.class = GetVehicleClass(GetVehiclePedIsIn(ped))
    TriggerServerEvent("test", props)
end, false)
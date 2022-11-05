-- LOCK / UNLOCK Vehicle
local allowLock = true
RegisterCommand("+vehicleLocks", function()
    if GetVehiclePedIsEntering(ped) ~= 0 then return end
    
    local vehicle, dist = getClosestVehicle(false)
    if not vehicle or not allowLock then return end

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

    allowLock = false
    local locked = not getVehicleLocked(vehicle)
    setVehicleLocked(vehicle, locked)
    if IsVehicleAlarmActivated(vehicle) then
        SetVehicleAlarm(vehicle, false)
    end

    local keyFob
    if GetVehiclePedIsIn(ped) == 0 then
        ClearPedTasks(ped)
        loadAnimDict("anim@mp_player_intmenu@key_fob@")
        TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
        keyFob = CreateObject(`lr_prop_carkey_fob`, 0, 0, 0, true, true, true)
        AttachEntityToEntity(keyFob, ped, GetPedBoneIndex(ped, 0xDEAD), 0.12, 0.04, -0.025, -100.0, 100.0, 0.0, true, true, false, true, 1, true)
        Wait(700)
    end

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

    SetVehicleLights(vehicle, 2)
    Wait(100)
    SetVehicleLights(vehicle, 0)
    Wait(200)
    SetVehicleLights(vehicle, 2)
    Wait(100)
    SetVehicleLights(vehicle, 0)
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

if config.useInventory then
    exports("lockpick", function(data, slot)
        local success, used = lockpickVehicle()

        if not used then
            success, used = hotwireVehicle()
        end

        if used then
            exports.ox_inventory:useItem(data)
        end
    end)
else
    TriggerEvent("chat:addSuggestion", "/lockpick", "Lockpick a nearby vehicle door.", {})
    RegisterCommand("lockpick", function(source, args, rawCommand)
        lockpickVehicle()
    end, false)

    TriggerEvent("chat:addSuggestion", "/hotwire", "Hotwire the current vehicle.", {})
    RegisterCommand("hotwire", function(source, args, rawCommand)
        hotwireVehicle()
    end, false)
end
NDCore = exports["ND_Core"]:GetCoreObject()
playerOwnedVehicles = {}

RegisterNetEvent("ND_VehicleSystem:getVehicles", function()
    local src = source
    local player = NDCore.Functions.GetPlayer(src)
    local vehicles = getVehicles(player.id)
    TriggerClientEvent("ND_VehicleSystem:returnVehicles", src, vehicles)
end)

RegisterNetEvent("ND_VehicleSystem:storeVehicle", function(vehid, properties)
    local src = source
    local entity = NetworkGetEntityFromNetworkId(vehid)
    local stored = returnVehicleToGarage(src, entity, properties)
    if stored then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Success",
            description = "Vehicle stored in garage.",
            type = "success",
            position = "bottom",
            duration = 3000
        })
        return
    end
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Error",
        description = "No vehicle found.",
        type = "error",
        position = "bottom",
        duration = 3000
    })
end)

RegisterNetEvent("ND_VehicleSystem:takeVehicle", function(selectedVehicle, coords)
    local src = source
    spawnOwnedVehicle(src, selectedVehicle.id, coords)

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Vehicle unparked",
        description = "Your vehicle can now be found in this parking lot.",
        type = "inform",
        position = "bottom",
        duration = 3000
    })
end)

RegisterCommand("givekeys", function(source, args, rawCommand)
    local src = source
    local target = tonumber(args[1])
    local veh = GetVehiclePedIsIn(GetPlayerPed(src))
    if veh == 0 then
        veh = GetVehiclePedIsIn(GetPlayerPed(src), true)
        if veh == 0 then return end
    end
    giveKeys(veh, src, target)
end, false)

RegisterNetEvent("ND_VehicleSystem:syncAlarm", function(netid, success, action)
    local veh = NetworkGetEntityFromNetworkId(netid)
    local owner = NetworkGetEntityOwner(veh)
    TriggerClientEvent("ND_VehicleSystem:syncAlarm", owner, netid, success, action)
end)
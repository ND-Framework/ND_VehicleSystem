NDCore = exports["ND_Core"]:GetCoreObject()
playerOwnedVehicles = {}

RegisterNetEvent("ND_VehicleSystem:getVehicles", function()
    local src = source
    local player = NDCore.Functions.GetPlayer(src)
    MySQL.query.await("UPDATE vehicles SET stored = ? WHERE owner = ?", {1, player.id})
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
    local unparked = spawnOwnedVehicle(src, selectedVehicle.id, coords)
    if not unparked then return end
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
    if not args[1] then return end
    local target = tonumber(args[1])
    if not GetPlayerPing(target) then return end

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
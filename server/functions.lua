function sqlBool(status)
    return (status == 1)
end

function boolSql(status)
    if status then return 1 else return 0 end
end

function setVehicleOwned(src, properties, stored)
    local player = NDCore.Functions.GetPlayer(src)
    local id = MySQL.insert.await("INSERT INTO vehicles (owner, plate, properties, stored) VALUES (?, ?, ?, ?)", {player.id, properties.plate, json.encode(properties), boolSql(stored)})
    local vehicles = getVehicles(player.id)
    TriggerClientEvent("ND_VehicleSystem:returnVehicles", src, vehicles)
    return id
end

function getVehicles(characterId)
    local result = MySQL.query.await("SELECT * FROM vehicles WHERE owner = ?", {characterId})
    if not result then return {} end
    local vehicles = {}
    for _, vehicle in pairs(result) do
        local key = #vehicles + 1
        vehicles[key] = {}
        vehicles[key].available = sqlBool(vehicle.stored)
        vehicles[key].owner = vehicle.owner
        vehicles[key].id = vehicle.id
        vehicles[key].plate = vehicle.plate
        vehicles[key].properties = json.decode(vehicle.properties)
    end
    return vehicles
end

function giveKeys(vehicle, source, target)
    local vehid = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerClientEvent("ND_VehicleSystem:giveKeys", target, vehid)
    TriggerClientEvent("ox_lib:notify", source, {
        title = "Keys shared",
        description = "Keys have been successfully shared.",
        type = "success",
        position = "bottom-right",
        duration = 3000
    })
end

function spawnOwnedVehicle(source, vehicleID, coords)
    local player = NDCore.Functions.GetPlayer(source)
    local vehicles = getVehicles(player.id)

    for _, vehicle in pairs(vehicles) do
        if vehicle.owner == player.id and vehicle.id == vehicleID then
            MySQL.query.await("UPDATE vehicles SET stored = ? WHERE id = ?", {0, vehicleID})
            TriggerClientEvent("ND_VehicleSystem:returnVehicles", source, getVehicles(player.id))

            local tempVehicle = CreateVehicle(vehicle.properties.model, 0, 0, 0, 0, true, true)
            while not DoesEntityExist(tempVehicle) do
                Wait(0)
            end
            local entityType = GetVehicleType(tempVehicle)
            DeleteEntity(tempVehicle)
            local veh = CreateVehicleServerSetter(vehicle.properties.model, entityType, coords.x, coords.y, coords.z, coords.w)
            while not DoesEntityExist(veh) do
                Wait(0)
            end
            local netid = NetworkGetNetworkIdFromEntity(veh)
            playerOwnedVehicles[vehicle.id] = {
                netid = netid
            }
            Entity(veh).state.owner = vehicle.owner
            Entity(veh).state.id = vehicle.id
            TriggerClientEvent("ND_VehicleSystem:applyProperties", source, netid, vehicle.properties)
            return true
        end
    end
    return false
end

function returnVehicleToGarage(source, veh, properties)
    local player = NDCore.Functions.GetPlayer(source)
    if not DoesEntityExist(veh) then return end

    local vehID = Entity(veh).state.id
    local vehicles = getVehicles(player.id)
    
    for _, vehicle in pairs(vehicles) do
        if vehicle.owner == player.id and vehicle.id == vehID then
            MySQL.query.await("UPDATE vehicles SET properties = ?, stored = ? WHERE id = ?", {json.encode(properties), 1, vehID})
            TriggerClientEvent("ND_VehicleSystem:returnVehicles", source, getVehicles(player.id))
            DeleteEntity(veh)
            return true
        end
    end
    return false
end
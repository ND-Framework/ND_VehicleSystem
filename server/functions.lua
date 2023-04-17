function sqlBool(status)
    return (status == 1)
end

function boolSql(status)
    if status then return 1 else return 0 end
end

function isPlateAvailable(plate)
    return not MySQL.scalar.await("SELECT 1 FROM vehicles WHERE plate = ?", {plate})
end

function generatePlate()
    local plate = {}
    for i = 1, 8 do
        plate[i] = math.random(0, 1) == 1 and string.char(math.random(65, 90)) or math.random(0, 9)
    end
    return table.concat(plate)
end

function transferVehicle(vehicleID, fromSource, toSource)
    local playerTo = NDCore.Functions.GetPlayer(toSource)
    MySQL.query.await("UPDATE vehicles SET owner = ? WHERE id = ?", {playerTo.id, vehicleID})
    
    if not playerOwnedVehicles[vehicleID] then return end
    local veh = NetworkGetEntityFromNetworkId(playerOwnedVehicles[vehicleID].netid)
    if not veh then
        TriggerClientEvent("ox_lib:notify", fromSource, {
            title = "Ownership transfered",
            description = "Vehicle ownership of has been transfered.",
            type = "success",
            position = "bottom-right",
            duration = 4000
        })
        TriggerClientEvent("ox_lib:notify", toSource, {
            title = "Ownership received",
            description = "Received vehicle ownership.",
            type = "inform",
            position = "bottom-right",
            duration = 4000
        })
        return
    end
    
    local state = Entity(veh).state
    state.owner = playerTo.id
    state.keys = {
        [playerTo.id] = true
    }

    TriggerClientEvent("ND_VehicleSystem:removeBlip", fromSource, playerOwnedVehicles[vehicleID].netid)

    TriggerClientEvent("ox_lib:notify", fromSource, {
        title = "Ownership transfered",
        description = "Vehicle ownership of " .. GetVehicleNumberPlateText(veh) .. " has been transfered.",
        type = "success",
        position = "bottom-right",
        duration = 4000
    })
    TriggerClientEvent("ox_lib:notify", toSource, {
        title = "Ownership received",
        description = "Received vehicle ownership of " .. GetVehicleNumberPlateText(veh) .. ".",
        type = "inform",
        position = "bottom-right",
        duration = 4000
    })
end

function setVehicleOwned(src, properties, stored)
    local player = NDCore.Functions.GetPlayer(src)
    local plate = generatePlate()
    while not isPlateAvailable(plate) do
        plate = generatePlate()
    end
    properties.plate = plate
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
    local state = Entity(vehicle).state
    if not state then return end
    local player = NDCore.Functions.GetPlayer(source)
    local owner = state.owner
    if not owner and owner ~= player.id then return end

    local keys = state.keys
    if not keys then return end

    local targetPlayer = NDCore.Functions.GetPlayer(target)
    state.keys[targetPlayer.id] = true

    TriggerClientEvent("ox_lib:notify", source, {
        title = "Keys shared",
        description = "You've shared vehicle keys to " .. GetVehicleNumberPlateText(vehicle) .. ".",
        type = "success",
        position = "bottom-right",
        duration = 4000
    })
    TriggerClientEvent("ox_lib:notify", target, {
        title = "Keys received",
        description = "Received vehicle keys to " .. GetVehicleNumberPlateText(vehicle) .. ".",
        type = "inform",
        position = "bottom-right",
        duration = 4000
    })
end

function giveAccess(source, vehicle)
    local state = Entity(vehicle).state
    if not state then return end

    local player = NDCore.Functions.GetPlayer(source)
    if not player then return end

    if not state.keys then
        state.keys = {
            [player.id] = true
        }
    else
        local keys = state.keys
        keys[player.id] = true
        state.keys = keys
    end

    TriggerClientEvent("ND_VehicleSystem:setOwnedIfNot", source, NetworkGetNetworkIdFromEntity(vehicle))
end

function isParkingAvailable(source, coords)
    local tries = 1
    while tries < #coords do
        Wait(300)
        local coord = coords[math.random(1, #coords)]
        local available = lib.callback.await("ND_VehicleSystem:getParkedVehicle", source, vector3(coord.x, coord.y, coord.z))
        if available then
            return coord
        end
        tries += 1
    end
    return false
end

function spawnOwnedVehicle(source, vehicleID, coords)
    local player = NDCore.Functions.GetPlayer(source)
    local spawnCoords = coords
    if type(coords) == "table" then
        spawnCoords = isParkingAvailable(source, coords)
        if not spawnCoords then
            TriggerClientEvent("ox_lib:notify", source, {
                title = "Can't bring out vehicle",
                description = "No parking spot available for your vehicle. It's still in your garage.",
                type = "error",
                position = "bottom",
                duration = 4000
            })
            return false
        end
    end
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
            local veh = CreateVehicleServerSetter(vehicle.properties.model, entityType, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w)
            while not DoesEntityExist(veh) do
                Wait(0)
            end
            local netid = NetworkGetNetworkIdFromEntity(veh)
            playerOwnedVehicles[vehicle.id] = {
                netid = netid
            }
            local state = Entity(veh).state
            state.owner = vehicle.owner
            state.id = vehicle.id
            state.keys = {
                [player.id] = true
            }
            if next(vehicle.properties) then
                state.props = vehicle.properties
            end
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

function saveVehiclePreperties(source, veh, properties)
    local player = NDCore.Functions.GetPlayer(source)
    if not DoesEntityExist(veh) then return end

    local vehID = Entity(veh).state.id
    local vehicles = getVehicles(player.id)
    
    for _, vehicle in pairs(vehicles) do
        if vehicle.owner == player.id and vehicle.id == vehID then
            MySQL.query.await("UPDATE vehicles SET properties = ? WHERE id = ?", {json.encode(properties), vehID})
            return true
        end
    end
    return false
end
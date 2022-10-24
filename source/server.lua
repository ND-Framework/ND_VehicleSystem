NDCore = exports["ND_Core"]:GetCoreObject()

function sqlBool(status)
    return (status == 1)
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
        vehicles[key].plate = vehicle.plate
        vehicles[key].properties = json.decode(vehicle.properties)
    end
    return vehicles
end

function saveVehicle(src, properties)
    local player = NDCore.Functions.GetPlayer(src)
    MySQL.query.await("INSERT INTO vehicles (owner, plate, properties) VALUES (?, ?, ?)", {player.id, properties.plate, json.encode(properties)})
    local vehicles = getVehicles(player.id)
    TriggerClientEvent("ND_VehicleSystem:returnVehicles", src, vehicles)
end

RegisterNetEvent("ND_VehicleSystem:getVehicles", function()
    local src = source
    local player = NDCore.Functions.GetPlayer(src)
    local vehicles = getVehicles(player.id)
    TriggerClientEvent("ND_VehicleSystem:returnVehicles", src, vehicles)
end)

RegisterNetEvent("ND_VehicleSystem:storeVehicle", function(vehid, properties)
    local src = source
    local player = NDCore.Functions.GetPlayer(src)
    local vehicles = getVehicles(player.id)
    for _, vehicle in pairs(vehicles) do
        if vehicle.properties.plate == properties.plate and vehicle.owner == player.id then
            DeleteEntity(NetworkGetEntityFromNetworkId(vehid))
            MySQL.query.await("UPDATE vehicles SET properties = ?, stored = ? WHERE plate = ?", {json.encode(properties), 1, properties.plate})
            TriggerClientEvent("ND_VehicleSystem:returnVehicles", src, getVehicles(player.id))
            break
        end
    end
    
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Success",
        description = "Vehicle stored in garage.",
        type = "success",
        position = "bottom",
        duration = 3000
    })
end)

RegisterNetEvent("ND_VehicleSystem:takeVehicle", function(selectedVehicle)
    local src = source
    local player = NDCore.Functions.GetPlayer(src)
    local vehicles = getVehicles(player.id)

    for _, vehicle in pairs(vehicles) do
        if vehicle.properties.plate == selectedVehicle.plate and vehicle.owner == player.id then
            MySQL.query.await("UPDATE vehicles SET stored = ? WHERE plate = ?", {0, selectedVehicle.plate})
            TriggerClientEvent("ND_VehicleSystem:returnVehicles", src, getVehicles(player.id))
            break
        end
    end

    TriggerClientEvent("ox_lib:notify", src, {
        title = "Vehicle unparked",
        description = "Your vehicle can now be found in this parking lot.",
        type = "inform",
        position = "bottom",
        duration = 3000
    })
end)
-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

author "Andyyy#7666 & scru#0687"
description "vehicle system for ND Framework"
version "1.1.0"

fx_version "cerulean"
game "gta5"
lua54 "yes"

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua"
}
server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/functions.lua",
    "server/main.lua"
}
client_scripts {
    "client/functions.lua",
    "client/main.lua",
    "client/commands.lua"
}

depedencies {
    "ox_lib",
    "ND_Core",
    "/server:5904",
    "/gameBuild:2060" -- must be 2060+.
}

exports {
    "getVehicleOwned",
    "isVehicleOwned",
    "hasVehicleKeys",
    "getClosestVehicle",
    "getVehicleLocked",
    "setVehicleLocked",
    "lockpickVehicle",
    "hotwireVehicle"
}

server_exports {
    "setVehicleOwned",
    "getVehicles",
    "giveKeys",
    "spawnOwnedVehicle",
    "returnVehicleToGarage",
    "saveVehicleProperties",
    "giveAccess"
}

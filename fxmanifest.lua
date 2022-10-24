-- For support join my discord: https://discord.gg/Z9Mxu72zZ6

author "Andyyy#7666 & scru#0687"
description "vehicle system for ND Framework"
version "1.0.0"

fx_version "cerulean"
game "gta5"
lua54 "yes"

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua"
}
server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "source/server.lua"
}
client_script "source/client.lua"
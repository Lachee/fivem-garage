version '1.0.0'
author 'Lachee'
description 'Modified version of a garage script.'
repository 'https://github.com/lachee/fivem-garage'

client_scripts{
    "config.lua",
    "client/garageMenu.lua",
    "client/gui.lua",
    "client/functions.lua",
    "client/main.lua"
}

server_scripts{
    "@mysql-async/lib/MySQL.lua",
    "config.lua",
    "server/main.lua",
}

fx_version 'adamant'
games{'rdr3', 'gta5'}

dependencies{
    'mysql-async'
}

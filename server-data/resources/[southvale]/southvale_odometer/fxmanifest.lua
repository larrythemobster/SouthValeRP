fx_version 'cerulean'
game 'gta5'

name 'southvale_odometer'
author 'SouthVale RP'
description 'Tracks real driven distance per vehicle plate and exposes it to players and mechanics'
version '1.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

files {
    'locales/*.json',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'

fx_version 'cerulean'
game 'gta5'

name 'southvale_elevators'
author 'SouthVale RP'
description 'Configurable multi-floor elevator call points, with in-game admin capture (no floors shipped -- see README)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

files {
    'data/shafts.json',
}

dependencies {
    'ox_lib',
    'ox_target',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'

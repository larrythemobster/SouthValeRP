fx_version 'cerulean'
game 'gta5'

name 'southvale_seating'
author 'SouthVale RP'
description 'Context-aware sit interactions on chairs, benches, and stools via ox_target'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'

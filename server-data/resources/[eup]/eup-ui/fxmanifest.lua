fx_version 'cerulean'
game 'gta5'

author 'SouthVale RP'
description 'Emergency Uniforms Pack (EUP) User Interface & Outfits Manager'
version '2.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'data/outfits.json'
}

dependencies {
    'ox_lib'
}

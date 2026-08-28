fx_version 'cerulean'
game 'gta5'

name 'sv_identity'
description 'SouthVale RP character selection, identity registration, and spawn presentation'
author 'SouthVale RP'
version '1.3.0'

lua54 'yes'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
    'qbx_spawn',
    'qbx_properties',
    'illenium-appearance',
}

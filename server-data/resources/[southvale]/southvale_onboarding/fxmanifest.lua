fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'SouthVale RP'
description 'Optional, persistent first-character guidance'
version '1.0.0'

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_target',
    'qbx_core',
}

shared_script '@ox_lib/init.lua'
shared_script 'shared/config.lua'

client_script 'client/main.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

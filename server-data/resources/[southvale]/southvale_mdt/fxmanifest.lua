fx_version 'cerulean'
game 'gta5'

name 'southvale_mdt'
author 'SouthVale RP'
description 'SouthVale law-enforcement records and mobile data terminal'
version '2.0.0'

ox_lib 'locale'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'locales/*.json',
    'shared/config.lua',
    'sql/*.sql',
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'

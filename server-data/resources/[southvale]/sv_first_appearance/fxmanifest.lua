fx_version 'cerulean'
game 'gta5'

name 'sv_first_appearance'
description 'SouthVale RP first-character appearance editor'
author 'SouthVale RP'
version '1.0.0'

lua54 'yes'

ui_page 'web/index.html'

client_script 'client/main.lua'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

dependencies {
    'qbx_core',
    'illenium-appearance',
}

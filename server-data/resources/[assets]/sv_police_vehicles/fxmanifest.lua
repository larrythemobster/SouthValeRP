fx_version 'cerulean'
game 'gta5'

name 'Southvale RP - Police Vehicle Fleet'
description 'Custom tuned emergency vehicle metadata, handling, audio, and bright emergency lighting for Southvale RP'
author 'Southvale RP Dev Team'
version '1.1.0'

files {
    'data/handling.meta',
    'data/vehicles.meta',
    'data/carvariations.meta',
    'data/carcols.meta',
    'visualsettings.dat'
}

data_file 'HANDLING_FILE' 'data/handling.meta'
data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'VISUALSETTINGS_FILE' 'visualsettings.dat'

client_scripts {
    'client.lua'
}

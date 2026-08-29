fx_version 'cerulean'
game 'gta5'

name 'Addon Vehicle - Toyota Supra JZA80'
description 'Custom add-on vehicle model for the PDM showroom floor'
author 'bepo13 (FiveM-AddOnCars), packaged for Southvale RP'
version '1.0.0'

files {
    'data/vehicles.meta',
    'data/carvariations.meta',
    'data/carcols.meta',
    'data/handling.meta',
    'data/vehiclelayouts.meta',
    'stream/jza80.yft',
    'stream/jza80.ytd',
    'stream/jza80_bumf_1.yft',
    'stream/jza80_bumf_2.yft',
    'stream/jza80_bumr_1.yft',
    'stream/jza80_hi.yft',
    'stream/jza80_skirt_1.yft',
    'stream/jza80_spoiler_1.yft',
    'stream/jza80_spoiler_2.yft',
    'stream/jza80_spoiler_3.yft',
}

data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'HANDLING_FILE' 'data/handling.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/vehiclelayouts.meta'

client_script 'data/vehicle_names.lua'

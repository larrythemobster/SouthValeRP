fx_version 'cerulean'
game 'gta5'

name 'Addon Vehicle - Nissan Skyline GT-R R34'
description 'Custom add-on vehicle model for the PDM showroom floor'
author 'bepo13 (FiveM-AddOnCars), packaged for Southvale RP'
version '1.0.0'

files {
    'data/vehicles.meta',
    'data/carvariations.meta',
    'data/carcols.meta',
    'data/handling.meta',
    'stream/skyline.yft',
    'stream/skyline.ytd',
    'stream/skyline_bnt1.yft',
    'stream/skyline_bumr1.yft',
    'stream/skyline_bumr2.yft',
    'stream/skyline_exh_1.yft',
    'stream/skyline_hi.yft',
    'stream/skyline_skirt1.yft',
    'stream/skyline_skirt2.yft',
    'stream/skyline_split1.yft',
    'stream/skyline_split2.yft',
    'stream/skyline_spoil_1.yft',
}

data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'HANDLING_FILE' 'data/handling.meta'

client_script 'data/vehicle_names.lua'

fx_version 'cerulean'
game 'gta5'

name 'Addon Vehicle - Nissan GTR R35'
description 'Custom add-on vehicle model for the PDM showroom floor'
author 'bepo13 (FiveM-AddOnCars), packaged for Southvale RP'
version '1.0.0'

files {
    'data/vehicles.meta',
    'data/carvariations.meta',
    'data/carcols.meta',
    'data/handling.meta',
    'stream/gtr.yft',
    'stream/gtr.ytd',
    'stream/gtr_arch_1.yft',
    'stream/gtr_arch_2.yft',
    'stream/gtr_bumf_1.yft',
    'stream/gtr_bumf_2.yft',
    'stream/gtr_bumf_3.yft',
    'stream/gtr_bumr_1.yft',
    'stream/gtr_bumr_2.yft',
    'stream/gtr_bumr_3.yft',
    'stream/gtr_hi.yft',
    'stream/gtr_hood_1.yft',
    'stream/gtr_skirt_1.yft',
    'stream/gtr_skirt_2.yft',
    'stream/gtr_skirt_3.yft',
    'stream/gtr_wing_1.yft',
    'stream/gtr_wing_2.yft',
    'stream/gtr_wing_3.yft',
}

data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'HANDLING_FILE' 'data/handling.meta'

client_script 'data/vehicle_names.lua'

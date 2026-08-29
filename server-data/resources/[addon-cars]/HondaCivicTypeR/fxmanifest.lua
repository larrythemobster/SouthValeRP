fx_version 'cerulean'
game 'gta5'

name 'Addon Vehicle - Honda Civic Type R (EK9)'
description 'Custom add-on vehicle model for the PDM showroom floor'
author 'bepo13 (FiveM-AddOnCars), packaged for Southvale RP'
version '1.0.0'

files {
    'data/vehicles.meta',
    'data/carvariations.meta',
    'data/carcols.meta',
    'data/handling.meta',
    'data/vehiclelayouts.meta',
    'stream/EK9.yft',
    'stream/EK9.ytd',
    'stream/EK9_hi.yft',
    'stream/ek9_bumf_1.yft',
    'stream/ek9_bumf_2.yft',
    'stream/ek9_bumr1.yft',
    'stream/ek9_cage.yft',
    'stream/ek9_skirts.yft',
    'stream/ek9_wing1.yft',
    'stream/ek9_wing2.yft',
}

data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'HANDLING_FILE' 'data/handling.meta'
data_file 'VEHICLE_LAYOUTS_FILE' 'data/vehiclelayouts.meta'

client_script 'data/vehicle_names.lua'

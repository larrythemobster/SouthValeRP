fx_version 'cerulean'
game 'gta5'

name 'Addon Vehicle - Honda NSX Liberty Walk'
description 'Custom add-on vehicle model for the PDM showroom floor'
author 'bepo13 (FiveM-AddOnCars), packaged for Southvale RP'
version '1.0.0'

files {
    'data/vehicles.meta',
    'data/carvariations.meta',
    'data/carcols.meta',
    'data/handling.meta',
    'stream/filthynsx.yft',
    'stream/filthynsx.ytd',
    'stream/filthynsx_hi.yft',
    'stream/nsx_bodykit_01.yft',
    'stream/nsx_bodykit_02.yft',
    'stream/nsx_bumf_01.yft',
    'stream/nsx_bumr.yft',
    'stream/nsx_livery_body.yft',
    'stream/nsx_livery_bumr.yft',
    'stream/nsx_livery_door_l.yft',
    'stream/nsx_livery_door_r.yft',
    'stream/nsx_livery_f.yft',
    'stream/nsx_livery_r.yft',
    'stream/nsx_spoil_01.yft',
    'stream/nsx_spoil_02.yft',
}

data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'HANDLING_FILE' 'data/handling.meta'

client_script 'data/vehicle_names.lua'

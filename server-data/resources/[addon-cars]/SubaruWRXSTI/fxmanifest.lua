fx_version 'cerulean'
game 'gta5'

name 'Addon Vehicle - Subaru Impreza WRX STI'
description 'Custom add-on vehicle model for the PDM showroom floor'
author 'bepo13 (FiveM-AddOnCars), packaged for Southvale RP'
version '1.0.0'

files {
    'data/vehicles.meta',
    'data/carvariations.meta',
    'data/carcols.meta',
    'data/handling.meta',
    'stream/subwrx.yft',
    'stream/subwrx.ytd',
    'stream/subwrx_hi.yft',
    'stream/vehicles_iswrx_interior.ytd',
    'stream/wrx_atmp_cw.yft',
    'stream/wrx_etek_cw.yft',
    'stream/wrx_kaput_k.yft',
    'stream/wrx_otmp_cw.yft',
    'stream/wrx_sp_cr.yft',
    'stream/wrx_sp_cw.yft',
}

data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'CARCOLS_FILE' 'data/carcols.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'HANDLING_FILE' 'data/handling.meta'

client_script 'data/vehicle_names.lua'

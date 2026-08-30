fx_version 'cerulean'
game 'gta5'

name 'SAST Black Shadow Pack'
description 'SAST Black Shadow Pack -- sast1-sast6 and sastum1-sastum3 emergency vehicles. Colliding handling ids (police, police2, police3, fbi2) were renamed to SAST_* to avoid overriding the server-wide police vehicle handling tuning in sv_police_vehicles.'
version '1.0.0'

files {
	'data/vehicles.meta',
	'data/carvariations.meta',
	'data/handling.meta',
}

data_file 'VEHICLE_METADATA_FILE' 'data/vehicles.meta'
data_file 'VEHICLE_VARIATION_FILE' 'data/carvariations.meta'
data_file 'HANDLING_FILE' 'data/handling.meta'

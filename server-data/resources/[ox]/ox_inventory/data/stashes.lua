return {
	{
		coords = vec3(461.35, -996.15, 30.69),
		target = {
			loc = vec3(461.5, -996.0, 30.69),
			length = 2.0,
			width = 6.0,
			heading = 90.0,
			minZ = 29.5,
			maxZ = 32.5,
			label = 'Open personal locker'
		},
		name = 'policelocker',
		label = 'Personal locker',
		owner = true,
		slots = 70,
		weight = 70000,
		groups = shared.police
	},

	{
		coords = vec3(1857.0, 3688.0, 34.3),
		target = {
			loc = vec3(1857.0, 3688.0, 34.3),
			length = 1.5,
			width = 3.0,
			heading = 210.0,
			minZ = 33.5,
			maxZ = 35.5,
			label = 'Open personal locker'
		},
		name = 'sandypolicelocker',
		label = 'Sheriff Personal Locker',
		owner = true,
		slots = 70,
		weight = 70000,
		groups = shared.police
	},

	{
		coords = vec3(301.3, -600.23, 43.28),
		target = {
			loc = vec3(301.82, -600.99, 43.29),
			length = 0.6,
			width = 1.8,
			heading = 340,
			minZ = 43.34,
			maxZ = 44.74,
			label = 'Open personal locker'
		},
		name = 'emslocker',
		label = 'Personal Locker',
		owner = true,
		slots = 70,
		weight = 70000,
		groups = {['ambulance'] = 0}
	},
}

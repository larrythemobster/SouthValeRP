return {
    timeout = 10000,
    maxSpikes = 5,
    policePlatePrefix = 'LSPD',
    objects = {
        cone = {model = `prop_roadcone02a`, freeze = false},
        barrier = {model = `prop_barrier_work06a`, freeze = true},
        roadsign = {model = `prop_snow_sign_road_06g`, freeze = true},
        tent = {model = `prop_gazebo_03`, freeze = true},
        light = {model = `prop_worklight_03b`, freeze = true},
        chair = {model = `prop_chair_08`, freeze = true},
        chairs = {model = `prop_chair_pile_01`, freeze = true},
        tabe = {model = `prop_table_03`, freeze = true},
        monitor = {model = `des_tvsmash_root`, freeze = true},
    },

    locations = {
        duty = {
            vec3(441.83, -982.05, 30.69),   -- Gabz MRPD Front Reception
            vec3(473.0, -1007.5, 26.27),    -- Gabz MRPD Briefing / Locker Room
            vec3(1853.4, 3684.5, 34.3),     -- Sandy Shores Sheriff Front Desk
            vec3(-449.81, 6012.91, 31.82),  -- Paleto Bay Sheriff Station
            vec3(368.0, -1618.8, 29.3),     -- Davis Station
            vec3(-1092.6, -808.1, 19.3),    -- Vespucci Station
            vec3(637.1, 1.6, 81.8),         -- Vinewood Station
        },
        vehicle = {
            vec4(438.42, -1018.3, 28.75, 90.0), -- Gabz MRPD Back Lot Lower Bay
            vec4(452.0, -996.0, 25.7, 175.0),   -- Gabz MRPD Back Lot Upper Bay
            vec4(425.5, -980.2, 30.7, 90.0),    -- Gabz MRPD Front Driveway
            vec4(1863.0, 3679.0, 33.7, 210.0),  -- Sandy Shores Sheriff Lot
            vec4(-446.5, 6003.5, 31.3, 31.0),   -- Paleto Bay Sheriff Lot
            vec4(385.0, -1624.5, 29.3, 320.0),  -- Davis Sheriff Station
            vec4(-1108.5, -845.0, 19.3, 125.0), -- Vespucci Police Station
            vec4(638.5, 2.5, 82.5, 245.0),      -- Vinewood Station
        },
        stash = {
            vec3(461.35, -996.15, 30.69),       -- Gabz MRPD Lockers
            vec3(1857.0, 3688.0, 34.3),         -- Sandy Shores Lockers
        },
        impound = {
            vec3(436.68, -1007.42, 27.32),      -- Gabz MRPD Gated Impound
            vec3(1850.0, 3680.0, 33.7),         -- Sandy Shores Impound
            vec3(-436.14, 5982.63, 31.34),      -- Paleto Bay Impound
        },
        helicopter = {
            vec4(449.17, -981.33, 43.69, 87.23), -- Gabz MRPD Rooftop Helipad
            vec4(1856.2, 3670.5, 34.0, 210.0),   -- Sandy Shores Helipad
            vec4(-475.43, 5988.35, 31.72, 31.34),-- Paleto Bay Helipad
            vec4(-1095.5, -835.0, 37.7, 125.0),  -- Vespucci Helipad
        },
        armory = {
            vec3(481.65, -995.32, 30.69),       -- Gabz MRPD Armory
            vec3(1851.5, 3683.5, 34.3),         -- Sandy Shores Armory
            vec3(-449.5, 6013.0, 31.7),         -- Paleto Bay Armory
        },
        trash = {
            vec3(460.62, -978.85, 30.69),       -- Gabz MRPD Locker Trash
            vec3(475.23, -1004.91, 26.27),      -- Gabz MRPD Cells Trash
            vec3(1851.0, 3688.0, 34.3),         -- Sandy Shores Trash
            vec3(-445.0, 6015.0, 31.7),         -- Paleto Bay Trash
        },
        fingerprint = {
            vec3(479.75, -984.34, 26.27),       -- Gabz MRPD Booking / Processing Lab
            vec3(1854.0, 3686.0, 34.3),         -- Sandy Shores Processing
            vec3(-448.0, 6013.0, 31.7),         -- Paleto Bay Processing
        },
        evidence = {
            vec3(473.85, -995.12, 26.27),       -- Gabz MRPD Forensics / Evidence Lab
            vec3(1851.0, 3693.0, 34.3),         -- Sandy Shores Evidence
            vec3(-442.0, 6015.0, 31.7),         -- Paleto Bay Evidence
        },
        stations = {
            {label = 'Mission Row Police Station', coords = vec3(441.83, -982.05, 30.69)},
            {label = 'Sandy Shores Sheriff Station', coords = vec3(1853.4, 3684.5, 34.3)},
            {label = 'Paleto Bay Sheriff Station', coords = vec3(-448.4, 6011.8, 31.7)},
            {label = 'Davis Police Station', coords = vec3(368.0, -1618.8, 29.3)},
            {label = 'Vespucci Police Station', coords = vec3(-1092.6, -808.1, 19.3)},
            {label = 'Vinewood Police Station', coords = vec3(637.1, 1.6, 81.8)},
        },
    },

    radars = {
        -- /!\ The maxspeed(s) need to be in an increasing order /!\
        -- If you don't want to fine people just do that: 'config.speedFines = false'
        -- fine if you're maxspeed or less over the speedlimit
        -- (i.e if you're at 41 mph and the radar's limit is 35 you're 6mph over so a 25$ fine)
        speedFines = {
            {fine = 25, maxSpeed = 10 },
            {fine = 50, maxSpeed = 30},
            {fine = 250, maxSpeed = 80},
            {fine = 500, maxSpeed = 180},
        }
    }
}

SVIdentity = {
    brand = {
        name = 'SOUTHVALE',
        suffix = 'ROLEPLAY',
        eyebrow = 'CHARACTER ACCESS',
        accent = '#d8c85a',
    },

    -- The character preview uses the actual qbx_core preview locations so this
    -- resource does not invent or maintain a second set of map coordinates.
    preview = {
        cameraFov = 40.0,
        fadeOutMs = 350,
        fadeInMs = 650,
    },

    -- qbx_spawn uses this same staging scene while a loaded character chooses
    -- where to enter the world. Keeping these values here makes cleanup and
    -- camera behavior deterministic while spawn destinations still come from
    -- qbx_spawn itself.
    spawnScene = {
        ped = vec4(-21.58, -583.76, 86.31, 160.0),
        camera = vec4(-24.77, -590.35, 90.8, 160.0),
        cameraPitch = -2.0,
        cameraFov = 45.0,
    },

    validation = {
        minNameLength = 2,
        maxNameLength = 50,
        maxNationalityLength = 50,
    },

    debug = false,
}

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
        ped = vec4(-438.8, 1070.8, 352.5, 160.0),
        camera = vec4(-440.0, 1075.0, 365.0, 165.0),
        cameraPitch = -12.0,
        cameraFov = 50.0,
    },

    validation = {
        minNameLength = 2,
        maxNameLength = 50,
        maxNationalityLength = 50,
    },

    debug = false,
}

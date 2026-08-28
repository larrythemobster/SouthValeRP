Config = {}

-- Command name to open the EUP wardrobe menu
Config.Command = 'eup'

-- Optional Keybind (set to false or nil to disable, or e.g. 'F11', 'F6')
Config.Keybind = false

-- Restrict opening the EUP menu to specific jobs (Qbox / QB-Core)
Config.JobRestricted = false

-- Allowed jobs if Config.JobRestricted is true
Config.AllowedJobs = {
    ['police'] = true,
    ['sheriff'] = true,
    ['ambulance'] = true,
    ['fire'] = true,
    ['doctor'] = true,
    ['sasp'] = true,
    ['sahp'] = true,
    ['bcso'] = true,
    ['doc'] = true,
    ['security'] = true
}

-- Restrict opening the EUP menu to players with specific ACE permission (e.g. 'command.eup')
Config.AceRestricted = false
Config.AcePermission = 'command.eup'

-- Enable Quick Actions in the main menu (Clear Hat, Clear Glasses, Clear Mask, Clear Vest, Clear Bag)
Config.EnableQuickActions = true

-- Save appearance to illenium-appearance if present on the server
Config.SaveToAppearance = true

-- Department Icons for the ox_lib menu (FontAwesome 6 icon names)
Config.DepartmentIcons = {
    ['LSPD'] = 'shield-halved',
    ['BCSO'] = 'star',
    ['SAHP'] = 'road',
    ['SASP'] = 'shield',
    ['LSSD'] = 'shield-halved',
    ['RHPD'] = 'building-shield',
    ['DPPD'] = 'building-shield',
    ['LSIA'] = 'plane',
    ['LSPP'] = 'tree',
    ['SADFW'] = 'tree',
    ['U.S NPS'] = 'mountain-sun',
    ['Medical Services'] = 'truck-medical',
    ['LSFD'] = 'fire-extinguisher',
    ['BCFD'] = 'fire-extinguisher',
    ['LSCoFD'] = 'fire-extinguisher',
    ['SanFire'] = 'fire',
    ['Lifeguard'] = 'life-ring',
    ['FIB'] = 'building-columns',
    ['IAA'] = 'user-secret',
    ['USMS'] = 'scale-balanced',
    ['NOOSE'] = 'crosshairs',
    ['DOA'] = 'flask',
    ['SASPA'] = 'handcuffs',
    ['NYSP'] = 'shield',
    ['BIA Tribal Police'] = 'feather-pointed',
    ['USAF Security Forces'] = 'jet-fighter',
    ['United States Armed Forces'] = 'medal',
    ['Private Security'] = 'shield',
    ['Parking Enforcement'] = 'car',
    ['General Services'] = 'vest',
    ['LSDRP'] = 'shield-halved',
    ['Other'] = 'shirt'
}

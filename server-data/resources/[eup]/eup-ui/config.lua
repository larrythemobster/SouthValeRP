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

-- Enable the "Customize Pieces" menu -- lets players mix & match individual EUP
-- components/props (mask, torso, legs, vest, badge, hat, etc). Every option offered is
-- sourced only from the EUP outfit catalog (data/outfits.json), so it can never apply a
-- regular/civilian clothing item from illenium-appearance's catalog.
Config.EnableCustomizer = true

-- Save appearance to illenium-appearance if present on the server
Config.SaveToAppearance = true

-- Department Icons for the ox_lib menu (FontAwesome 6 icon names)
Config.DepartmentIcons = {
    ['LSPD'] = 'shield-halved',
    ['BCSO'] = 'star',
    ['SAHP'] = 'road',
    ['SASP'] = 'shield',
    ['LSSD'] = 'shield-halved',
    ['FIB'] = 'building-columns',
    ['DOA'] = 'flask',
    ['NOOSE'] = 'crosshairs',
    ['LSIA'] = 'plane',
    ['Port Authority'] = 'anchor',
    ['SADCR'] = 'handcuffs',
    ['USAF Military Police'] = 'jet-fighter',
    ['Other'] = 'shirt'
}

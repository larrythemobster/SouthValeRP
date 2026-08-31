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
-- components/props (mask, torso, legs, vest, badge, hat, etc). Options come from
-- data/outfits.json and are runtime-validated against the currently loaded freemode ped.
Config.EnableCustomizer = true

-- Refuse presets/pieces whose drawable or texture does not exist on the current client.
-- This prevents stale EUP catalogs from applying out-of-range drawables/textures or fallback clothing.
Config.ValidateOutfits = true

-- Runtime diagnostic command. Run /eupaudit once as a male and once as a female freemode
-- character after changing EUP packs or game builds. Full details are printed to F8.
Config.AuditCommand = 'eupaudit'
Config.AuditMaxDetails = 50

-- Print the current outfit using FiveM's build-stable collection/local identifiers.
Config.InspectCommand = 'eupinspect'

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

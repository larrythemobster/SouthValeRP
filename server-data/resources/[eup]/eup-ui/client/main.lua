local Outfits = {}
local CategorizedOutfits = {
    ['Male'] = {},
    ['Female'] = {}
}

-- Per-gender pool of every distinct (drawable, texture) combo seen across the EUP outfit
-- catalog, keyed by component/prop slot id. This is what powers the piece-by-piece
-- customizer below -- it only ever offers drawables that ship in the EUP stream packs
-- (data/outfits.json), so it can never pull in a regular/civilian clothing item.
local ComponentVariantPool = { ['Male'] = {}, ['Female'] = {} }
local PropVariantPool = { ['Male'] = {}, ['Female'] = {} }

local ComponentSlots = {
    { id = 1, label = 'Mask', icon = 'masks-theater' },
    { id = 3, label = 'Torso / Sleeves', icon = 'shirt' },
    { id = 4, label = 'Legs / Pants', icon = 'socks' },
    { id = 5, label = 'Bag / Parachute', icon = 'bag-shopping' },
    { id = 6, label = 'Shoes', icon = 'shoe-prints' },
    { id = 7, label = 'Accessory (Tie / Scarf)', icon = 'ring' },
    { id = 8, label = 'Undershirt', icon = 'shirt' },
    { id = 9, label = 'Body Armor / Vest', icon = 'vest' },
    { id = 10, label = 'Badge / Decals', icon = 'id-badge' },
    { id = 11, label = 'Jacket / Torso 2', icon = 'vest-patches' },
}

local PropSlots = {
    { id = 0, label = 'Hat / Helmet', icon = 'hat-cowboy' },
    { id = 1, label = 'Glasses', icon = 'glasses' },
    { id = 2, label = 'Ear Accessory', icon = 'ear-listen' },
    { id = 3, label = 'Radio / Collar Mic', icon = 'walkie-talkie' },
    { id = 6, label = 'Watch', icon = 'clock' },
    { id = 7, label = 'Bracelet', icon = 'link' },
}

local function addVariant(pool, gender, slotId, drawable, texture, sourceLabel)
    if drawable < 0 then return end
    pool[gender][slotId] = pool[gender][slotId] or {}
    local list = pool[gender][slotId]
    for _, v in ipairs(list) do
        if v.drawable == drawable and v.texture == texture then return end
    end
    list[#list + 1] = { drawable = drawable, texture = texture, source = sourceLabel }
end

local function buildVariantPools()
    ComponentVariantPool = { ['Male'] = {}, ['Female'] = {} }
    PropVariantPool = { ['Male'] = {}, ['Female'] = {} }

    for _, outfit in ipairs(Outfits) do
        local gender = outfit.Gender or 'Male'
        if not ComponentVariantPool[gender] then ComponentVariantPool[gender] = {} end
        if not PropVariantPool[gender] then PropVariantPool[gender] = {} end

        for _, comp in ipairs(outfit.Components or {}) do
            -- stored 1-based (0 = none), same convention as applyPedOutfit
            local drawable = comp[2] - 1
            local texture = math.max(comp[3] - 1, 0)
            addVariant(ComponentVariantPool, gender, comp[1], drawable, texture, outfit.Name)
        end

        for _, prop in ipairs(outfit.Props or {}) do
            local drawable = prop[2] - 1 -- -1 == no prop
            local texture = math.max(prop[3] - 1, 0)
            if drawable >= 0 then
                addVariant(PropVariantPool, gender, prop[1], drawable, texture, outfit.Name)
            end
        end
    end

    for _, pool in pairs({ ComponentVariantPool, PropVariantPool }) do
        for _, slots in pairs(pool) do
            for _, list in pairs(slots) do
                table.sort(list, function(a, b) return a.drawable < b.drawable end)
            end
        end
    end
end

local function loadOutfitData()
    local fileContent = LoadResourceFile(GetCurrentResourceName(), "data/outfits.json")
    if not fileContent then
        print("^1[eup-ui] Error: Could not load data/outfits.json!^0")
        return
    end

    local decoded = json.decode(fileContent)
    if not decoded or type(decoded) ~= 'table' then
        print("^1[eup-ui] Error: Failed to parse data/outfits.json!^0")
        return
    end

    Outfits = decoded
    CategorizedOutfits = {
        ['Male'] = {},
        ['Female'] = {}
    }

    for _, outfit in ipairs(Outfits) do
        local gender = outfit.Gender or (string.find(string.lower(outfit.Ped or outfit.Name or ''), 'female') and 'Female' or 'Male')
        local dept = outfit.Department or outfit.Category or 'General'

        if not CategorizedOutfits[gender] then
            CategorizedOutfits[gender] = {}
        end
        if not CategorizedOutfits[gender][dept] then
            CategorizedOutfits[gender][dept] = {}
        end

        table.insert(CategorizedOutfits[gender][dept], outfit)
    end

    buildVariantPools()

    print(string.format("^2[eup-ui] Successfully loaded %d EUP outfits across %d male and %d female departments.^0",
        #Outfits,
        CountDepartments('Male'),
        CountDepartments('Female')
    ))
end

function CountDepartments(gender)
    local count = 0
    if CategorizedOutfits[gender] then
        for _ in pairs(CategorizedOutfits[gender]) do
            count = count + 1
        end
    end
    return count
end

local function syncAppearance()
    if GetResourceState('illenium-appearance') == 'started' then
        pcall(function()
            local illenium = exports['illenium-appearance']
            local ped = PlayerPedId()
            local appearance = illenium:getPedAppearance(ped)
            if appearance and Config.SaveToAppearance then
                TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            end
        end)
    end
end

local function applyPedOutfit(outfit)
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    local isMale = model == `mp_m_freemode_01`
    local isFemale = model == `mp_f_freemode_01`

    if not isMale and not isFemale then
        lib.notify({
            title = 'EUP Wardrobe',
            description = 'EUP uniforms require an MP Freemode character model (mp_m_freemode_01 or mp_f_freemode_01).',
            type = 'error',
            icon = 'shirt'
        })
        return false
    end

    -- Clear default props first
    for i = 0, 7 do
        ClearPedProp(ped, i)
    end

    -- Apply components
    if outfit.Components then
        for _, comp in ipairs(outfit.Components) do
            local componentId = comp[1]
            local drawable = comp[2] - 1
            local texture = comp[3] - 1
            if texture < 0 then texture = 0 end
            if drawable >= 0 then
                SetPedComponentVariation(ped, componentId, drawable, texture, 0)
            else
                SetPedComponentVariation(ped, componentId, 0, 0, 0)
            end
        end
    end

    -- Apply props
    if outfit.Props then
        for _, prop in ipairs(outfit.Props) do
            local propId = prop[1]
            local drawable = prop[2]
            local texture = prop[3] - 1
            if texture < 0 then texture = 0 end
            if drawable > 0 then
                SetPedPropIndex(ped, propId, drawable - 1, texture, true)
            else
                ClearPedProp(ped, propId)
            end
        end
    end

    syncAppearance()

    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)

    lib.notify({
        title = 'EUP Wardrobe',
        description = string.format('Equipped %s (%s)', outfit.Name, outfit.Department or outfit.Category or 'Uniform'),
        type = 'success',
        icon = 'shirt'
    })

    return true
end

local function openDepartmentMenu(gender, deptName)
    local outfitsList = (CategorizedOutfits[gender] and CategorizedOutfits[gender][deptName]) or {}
    local options = {}

    table.sort(outfitsList, function(a, b)
        return (a.Name or '') < (b.Name or '')
    end)

    for _, outfit in ipairs(outfitsList) do
        table.insert(options, {
            title = outfit.Name,
            description = string.format('%s • %s', deptName, gender),
            icon = Config.DepartmentIcons[deptName] or 'shirt',
            onSelect = function()
                applyPedOutfit(outfit)
            end
        })
    end

    local menuId = 'eup_dept_menu_' .. string.gsub(deptName, "[%s%p]+", "_")
    lib.registerContext({
        id = menuId,
        title = string.format('%s (%s)', deptName, gender),
        menu = 'eup_main_menu',
        options = options
    })

    lib.showContext(menuId)
end

local function openVariantMenu(gender, slotType, slotId, slotLabel, backMenuId)
    local ped = PlayerPedId()
    local pool = (slotType == 'prop') and PropVariantPool or ComponentVariantPool
    local variants = (pool[gender] and pool[gender][slotId]) or {}

    local options = {
        {
            title = 'Remove / None',
            description = 'Clear this slot',
            icon = 'ban',
            onSelect = function()
                if slotType == 'prop' then
                    ClearPedProp(ped, slotId)
                else
                    SetPedComponentVariation(ped, slotId, 0, 0, 0)
                end
                syncAppearance()
                lib.notify({ title = 'EUP Customizer', description = slotLabel .. ' cleared.', type = 'inform', icon = 'shirt' })
            end
        }
    }

    for _, variant in ipairs(variants) do
        table.insert(options, {
            title = string.format('%s #%d', slotLabel, variant.drawable),
            description = 'From: ' .. (variant.source or 'EUP catalog'),
            icon = 'circle-check',
            onSelect = function()
                if slotType == 'prop' then
                    SetPedPropIndex(ped, slotId, variant.drawable, variant.texture, true)
                else
                    SetPedComponentVariation(ped, slotId, variant.drawable, variant.texture, 0)
                end
                syncAppearance()
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                lib.notify({ title = 'EUP Customizer', description = string.format('%s set to #%d.', slotLabel, variant.drawable), type = 'success', icon = 'shirt' })
            end
        })
    end

    local menuId = 'eup_variant_' .. slotType .. '_' .. slotId
    lib.registerContext({
        id = menuId,
        title = slotLabel,
        menu = backMenuId,
        options = options
    })
    lib.showContext(menuId)
end

local function openCustomizeMenu(gender)
    local options = {}

    for _, slot in ipairs(ComponentSlots) do
        local variants = ComponentVariantPool[gender] and ComponentVariantPool[gender][slot.id]
        if variants and #variants > 0 then
            table.insert(options, {
                title = slot.label,
                description = string.format('%d EUP piece%s available', #variants, #variants == 1 and '' or 's'),
                icon = slot.icon,
                arrow = true,
                onSelect = function()
                    openVariantMenu(gender, 'component', slot.id, slot.label, 'eup_customize_menu')
                end
            })
        end
    end

    for _, slot in ipairs(PropSlots) do
        local variants = PropVariantPool[gender] and PropVariantPool[gender][slot.id]
        if variants and #variants > 0 then
            table.insert(options, {
                title = slot.label,
                description = string.format('%d EUP piece%s available', #variants, #variants == 1 and '' or 's'),
                icon = slot.icon,
                arrow = true,
                onSelect = function()
                    openVariantMenu(gender, 'prop', slot.id, slot.label, 'eup_customize_menu')
                end
            })
        end
    end

    lib.registerContext({
        id = 'eup_customize_menu',
        title = 'Customize Uniform Pieces',
        menu = 'eup_main_menu',
        options = options
    })
    lib.showContext('eup_customize_menu')
end

local function openQuickActionsMenu()
    local ped = PlayerPedId()
    lib.registerContext({
        id = 'eup_quick_actions',
        title = 'Quick Uniform Actions',
        menu = 'eup_main_menu',
        options = {
            {
                title = 'Remove Hat / Helmet',
                icon = 'hat-cowboy',
                onSelect = function()
                    ClearPedProp(ped, 0)
                    lib.notify({ title = 'EUP', description = 'Removed headwear.', type = 'inform' })
                end
            },
            {
                title = 'Remove Glasses',
                icon = 'glasses',
                onSelect = function()
                    ClearPedProp(ped, 1)
                    lib.notify({ title = 'EUP', description = 'Removed glasses.', type = 'inform' })
                end
            },
            {
                title = 'Remove Mask',
                icon = 'masks-theater',
                onSelect = function()
                    SetPedComponentVariation(ped, 1, 0, 0, 0)
                    lib.notify({ title = 'EUP', description = 'Removed mask.', type = 'inform' })
                end
            },
            {
                title = 'Remove Body Armor / Vest',
                icon = 'vest',
                onSelect = function()
                    SetPedComponentVariation(ped, 9, 0, 0, 0)
                    lib.notify({ title = 'EUP', description = 'Removed body armor / vest.', type = 'inform' })
                end
            },
            {
                title = 'Remove Bag / Parachute',
                icon = 'bag-shopping',
                onSelect = function()
                    SetPedComponentVariation(ped, 5, 0, 0, 0)
                    lib.notify({ title = 'EUP', description = 'Removed bag / backpack.', type = 'inform' })
                end
            },
            {
                title = 'Remove Ear Accessories',
                icon = 'ear-listen',
                onSelect = function()
                    ClearPedProp(ped, 2)
                    lib.notify({ title = 'EUP', description = 'Removed ear accessories.', type = 'inform' })
                end
            },
            {
                title = 'Remove Watch',
                icon = 'clock',
                onSelect = function()
                    ClearPedProp(ped, 6)
                    lib.notify({ title = 'EUP', description = 'Removed watch.', type = 'inform' })
                end
            }
        }
    })
    lib.showContext('eup_quick_actions')
end

local function searchOutfitsDialog(gender)
    local input = lib.inputDialog('Search EUP Outfits', {
        { type = 'input', label = 'Outfit Name or Department', placeholder = 'e.g. Traffic, SWAT, LSPD, Medic', required = true }
    })

    if not input or not input[1] or input[1] == '' then return end
    local query = string.lower(input[1])

    local results = {}
    for _, outfit in ipairs(Outfits) do
        local outfitGender = outfit.Gender or 'Male'
        if outfitGender == gender then
            local name = string.lower(outfit.Name or '')
            local dept = string.lower(outfit.Department or outfit.Category or '')
            if string.find(name, query, 1, true) or string.find(dept, query, 1, true) then
                table.insert(results, outfit)
            end
        end
    end

    if #results == 0 then
        lib.notify({
            title = 'EUP Search',
            description = 'No outfits found matching "' .. input[1] .. '"',
            type = 'error',
            icon = 'magnifying-glass'
        })
        return
    end

    table.sort(results, function(a, b)
        return (a.Name or '') < (b.Name or '')
    end)

    local options = {}
    for _, outfit in ipairs(results) do
        table.insert(options, {
            title = outfit.Name,
            description = string.format('%s • %s', outfit.Department or outfit.Category or 'EUP', gender),
            icon = Config.DepartmentIcons[outfit.Department or outfit.Category] or 'shirt',
            onSelect = function()
                applyPedOutfit(outfit)
            end
        })
    end

    lib.registerContext({
        id = 'eup_search_results',
        title = string.format('Search: "%s" (%d results)', input[1], #results),
        menu = 'eup_main_menu',
        options = options
    })

    lib.showContext('eup_search_results')
end

local function openEUPMenu()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    local gender = nil

    if model == `mp_m_freemode_01` then
        gender = 'Male'
    elseif model == `mp_f_freemode_01` then
        gender = 'Female'
    else
        lib.notify({
            title = 'EUP Wardrobe',
            description = 'EUP requires an MP Freemode character (mp_m_freemode_01 or mp_f_freemode_01).',
            type = 'error',
            icon = 'user-slash'
        })
        return
    end

    if Config.JobRestricted or Config.AceRestricted then
        local allowed, err = lib.callback.await('eup-ui:server:checkPermission', false)
        if not allowed then
            lib.notify({
                title = 'EUP Wardrobe',
                description = err or 'You are not authorized to use the EUP menu.',
                type = 'error',
                icon = 'lock'
            })
            return
        end
    end

    local deptMap = CategorizedOutfits[gender] or {}
    local deptNames = {}
    for name in pairs(deptMap) do
        table.insert(deptNames, name)
    end
    table.sort(deptNames)

    local mainOptions = {}

    -- Search Outfits
    table.insert(mainOptions, {
        title = 'Search Outfits',
        description = 'Search presets by keyword or department',
        icon = 'magnifying-glass',
        onSelect = function()
            searchOutfitsDialog(gender)
        end
    })

    if Config.EnableQuickActions then
        table.insert(mainOptions, {
            title = 'Quick Actions',
            description = 'Toggle hats, masks, vests, glasses, bags',
            icon = 'wand-magic-sparkles',
            onSelect = function()
                openQuickActionsMenu()
            end
        })
    end

    if Config.EnableCustomizer then
        table.insert(mainOptions, {
            title = 'Customize Pieces',
            description = 'Mix & match individual EUP items (mask, torso, vest, badge, hat, and more)',
            icon = 'sliders',
            arrow = true,
            onSelect = function()
                openCustomizeMenu(gender)
            end
        })
    end

    for _, dept in ipairs(deptNames) do
        local count = #deptMap[dept]
        local icon = Config.DepartmentIcons[dept] or 'shirt'
        table.insert(mainOptions, {
            title = dept,
            description = string.format('%d outfit preset%s available', count, count == 1 and '' or 's'),
            icon = icon,
            arrow = true,
            onSelect = function()
                openDepartmentMenu(gender, dept)
            end
        })
    end

    lib.registerContext({
        id = 'eup_main_menu',
        title = string.format('Emergency Uniform Pack (%s)', gender),
        options = mainOptions
    })

    lib.showContext('eup_main_menu')
end

-- Export functions
exports('OpenEUPMenu', openEUPMenu)
exports('SetOutfit', applyPedOutfit)
exports('GetOutfits', function() return Outfits end)
exports('GetCategorizedOutfits', function() return CategorizedOutfits end)
exports('OpenCustomizeMenu', function()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    local gender = (model == `mp_f_freemode_01`) and 'Female' or 'Male'
    openCustomizeMenu(gender)
end)

-- Command
RegisterCommand(Config.Command or 'eup', function()
    openEUPMenu()
end, false)

-- Optional Keybind
if Config.Keybind and type(Config.Keybind) == 'string' and Config.Keybind ~= '' then
    RegisterKeyMapping(Config.Command or 'eup', 'Open Emergency Uniforms Pack Menu', 'keyboard', Config.Keybind)
end

CreateThread(function()
    loadOutfitData()
end)

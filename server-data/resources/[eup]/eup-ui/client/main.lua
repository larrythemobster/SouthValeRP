local Outfits = {}
local CategorizedOutfits = {
    ['Male'] = {},
    ['Female'] = {}
}

-- Per-gender pool of every distinct (drawable, texture) combo referenced by the outfit
-- catalog, keyed by component/prop slot id. The catalog can contain both streamed EUP items
-- and base-game clothing, so every selection is validated against the current freemode ped
-- before it is shown or applied.
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
    if not Config.SaveToAppearance or GetResourceState('illenium-appearance') ~= 'started' then
        return
    end

    local ok, err = pcall(function()
        local ped = PlayerPedId()
        local appearance = exports['illenium-appearance']:getPedAppearance(ped)
        if appearance then
            TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
        end
    end)

    if not ok then
        print(('^1[eup-ui] Failed to sync appearance: %s^0'):format(tostring(err)))
    end
end

local function getPedGender(ped)
    local model = GetEntityModel(ped)
    if model == `mp_m_freemode_01` then return 'Male' end
    if model == `mp_f_freemode_01` then return 'Female' end
    return nil
end

local function validateComponentVariant(ped, componentId, drawable, texture)
    local drawableCount = GetNumberOfPedDrawableVariations(ped, componentId)
    if drawable < 0 or drawable >= drawableCount then
        return false, string.format('component %d drawable %d is outside 0-%d', componentId, drawable, math.max(drawableCount - 1, -1))
    end

    local textureCount = GetNumberOfPedTextureVariations(ped, componentId, drawable)
    if texture < 0 or texture >= textureCount then
        return false, string.format('component %d drawable %d texture %d is outside 0-%d', componentId, drawable, texture, math.max(textureCount - 1, -1))
    end

    return true
end

local function validatePropVariant(ped, propId, drawable, texture)
    if drawable < 0 then return true end -- -1 means no prop

    local drawableCount = GetNumberOfPedPropDrawableVariations(ped, propId)
    if drawable >= drawableCount then
        return false, string.format('prop %d drawable %d is outside 0-%d', propId, drawable, math.max(drawableCount - 1, -1))
    end

    local textureCount = GetNumberOfPedPropTextureVariations(ped, propId, drawable)
    if texture < 0 or texture >= textureCount then
        return false, string.format('prop %d drawable %d texture %d is outside 0-%d', propId, drawable, texture, math.max(textureCount - 1, -1))
    end

    return true
end

local function validateOutfit(ped, outfit)
    local issues = {}
    local pedGender = getPedGender(ped)

    if not pedGender then
        issues[#issues + 1] = 'current ped is not mp_m_freemode_01 or mp_f_freemode_01'
        return false, issues
    end

    if outfit.Gender and outfit.Gender ~= pedGender then
        issues[#issues + 1] = string.format('outfit is %s but current character is %s', outfit.Gender, pedGender)
    end

    for _, comp in ipairs(outfit.Components or {}) do
        local componentId = tonumber(comp[1])
        local drawable = (tonumber(comp[2]) or 0) - 1
        local texture = math.max((tonumber(comp[3]) or 1) - 1, 0)
        if componentId then
            local valid, reason = validateComponentVariant(ped, componentId, drawable, texture)
            if not valid then issues[#issues + 1] = reason end
        else
            issues[#issues + 1] = 'component entry has a non-numeric slot id'
        end
    end

    for _, prop in ipairs(outfit.Props or {}) do
        local propId = tonumber(prop[1])
        local drawable = (tonumber(prop[2]) or 0) - 1
        local texture = math.max((tonumber(prop[3]) or 1) - 1, 0)
        if propId then
            local valid, reason = validatePropVariant(ped, propId, drawable, texture)
            if not valid then issues[#issues + 1] = reason end
        else
            issues[#issues + 1] = 'prop entry has a non-numeric slot id'
        end
    end

    return #issues == 0, issues
end

local function logOutfitIssues(outfit, issues)
    print(string.format('^3[eup-ui] Outfit "%s" is not valid for the current ped/build:^0', outfit.Name or 'Unnamed'))
    for _, issue in ipairs(issues) do
        print(('^3  - %s^0'):format(issue))
    end
end

local function applyPedOutfit(outfit)
    if type(outfit) ~= 'table' then
        return false
    end

    local ped = PlayerPedId()
    local pedGender = getPedGender(ped)

    if not pedGender then
        lib.notify({
            title = 'EUP Wardrobe',
            description = 'EUP uniforms require an MP Freemode character model (mp_m_freemode_01 or mp_f_freemode_01).',
            type = 'error',
            icon = 'shirt'
        })
        return false
    end

    if outfit.Gender and outfit.Gender ~= pedGender then
        lib.notify({
            title = 'EUP Wardrobe',
            description = string.format('This preset is for a %s character.', string.lower(outfit.Gender)),
            type = 'error',
            icon = 'venus-mars'
        })
        return false
    end

    if Config.ValidateOutfits ~= false then
        local valid, issues = validateOutfit(ped, outfit)
        if not valid then
            logOutfitIssues(outfit, issues)
            lib.notify({
                title = 'EUP Wardrobe',
                description = string.format('%s is not compatible with the currently loaded clothing collection. Run /%s and check F8 for details.', outfit.Name or 'This preset', Config.AuditCommand or 'eupaudit'),
                type = 'error',
                icon = 'triangle-exclamation',
                duration = 8000
            })
            return false
        end
    end

    -- Clear props first so old headwear/accessories cannot leak into the preset.
    for i = 0, 7 do
        ClearPedProp(ped, i)
    end

    for _, comp in ipairs(outfit.Components or {}) do
        local componentId = comp[1]
        local drawable = comp[2] - 1
        local texture = math.max(comp[3] - 1, 0)
        SetPedComponentVariation(ped, componentId, math.max(drawable, 0), texture, 0)
    end

    for _, prop in ipairs(outfit.Props or {}) do
        local propId = prop[1]
        local drawable = prop[2] - 1
        local texture = math.max(prop[3] - 1, 0)
        if drawable >= 0 then
            SetPedPropIndex(ped, propId, drawable, texture, true)
        else
            ClearPedProp(ped, propId)
        end
    end

    syncAppearance()
    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)

    lib.notify({
        title = 'EUP Wardrobe',
        description = string.format('Equipped %s (%s)', outfit.Name or 'Uniform', outfit.Department or outfit.Category or 'Uniform'),
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

    local ped = PlayerPedId()
    for _, outfit in ipairs(outfitsList) do
        local valid = true
        if Config.ValidateOutfits ~= false then
            valid = validateOutfit(ped, outfit)
        end

        table.insert(options, {
            title = outfit.Name,
            description = valid and string.format('%s • %s', deptName, gender) or string.format('%s • incompatible with current clothing collection', deptName),
            icon = valid and (Config.DepartmentIcons[deptName] or 'shirt') or 'triangle-exclamation',
            disabled = not valid,
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
    local menuId = 'eup_variant_' .. slotType .. '_' .. slotId

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
                lib.showContext(menuId)
            end
        }
    }

    for _, variant in ipairs(variants) do
        local valid = true
        if Config.ValidateOutfits ~= false then
            if slotType == 'prop' then
                valid = validatePropVariant(ped, slotId, variant.drawable, variant.texture)
            else
                valid = validateComponentVariant(ped, slotId, variant.drawable, variant.texture)
            end
        end

        if valid then
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
                    lib.showContext(menuId)
                end
            })
        end
    end

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
                    syncAppearance()
                    lib.notify({ title = 'EUP', description = 'Removed headwear.', type = 'inform' })
                    lib.showContext('eup_quick_actions')
                end
            },
            {
                title = 'Remove Glasses',
                icon = 'glasses',
                onSelect = function()
                    ClearPedProp(ped, 1)
                    syncAppearance()
                    lib.notify({ title = 'EUP', description = 'Removed glasses.', type = 'inform' })
                    lib.showContext('eup_quick_actions')
                end
            },
            {
                title = 'Remove Mask',
                icon = 'masks-theater',
                onSelect = function()
                    SetPedComponentVariation(ped, 1, 0, 0, 0)
                    syncAppearance()
                    lib.notify({ title = 'EUP', description = 'Removed mask.', type = 'inform' })
                    lib.showContext('eup_quick_actions')
                end
            },
            {
                title = 'Remove Body Armor / Vest',
                icon = 'vest',
                onSelect = function()
                    SetPedComponentVariation(ped, 9, 0, 0, 0)
                    syncAppearance()
                    lib.notify({ title = 'EUP', description = 'Removed body armor / vest.', type = 'inform' })
                    lib.showContext('eup_quick_actions')
                end
            },
            {
                title = 'Remove Bag / Parachute',
                icon = 'bag-shopping',
                onSelect = function()
                    SetPedComponentVariation(ped, 5, 0, 0, 0)
                    syncAppearance()
                    lib.notify({ title = 'EUP', description = 'Removed bag / backpack.', type = 'inform' })
                    lib.showContext('eup_quick_actions')
                end
            },
            {
                title = 'Remove Ear Accessories',
                icon = 'ear-listen',
                onSelect = function()
                    ClearPedProp(ped, 2)
                    syncAppearance()
                    lib.notify({ title = 'EUP', description = 'Removed ear accessories.', type = 'inform' })
                    lib.showContext('eup_quick_actions')
                end
            },
            {
                title = 'Remove Watch',
                icon = 'clock',
                onSelect = function()
                    ClearPedProp(ped, 6)
                    syncAppearance()
                    lib.notify({ title = 'EUP', description = 'Removed watch.', type = 'inform' })
                    lib.showContext('eup_quick_actions')
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
    local ped = PlayerPedId()
    for _, outfit in ipairs(results) do
        local valid = true
        if Config.ValidateOutfits ~= false then
            valid = validateOutfit(ped, outfit)
        end

        table.insert(options, {
            title = outfit.Name,
            description = valid and string.format('%s • %s', outfit.Department or outfit.Category or 'EUP', gender) or 'Incompatible with current clothing collection',
            icon = valid and (Config.DepartmentIcons[outfit.Department or outfit.Category] or 'shirt') or 'triangle-exclamation',
            disabled = not valid,
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
    local gender = getPedGender(ped)
    if not gender then
        lib.notify({ title = 'EUP Customizer', description = 'EUP requires an MP freemode character.', type = 'error' })
        return
    end
    openCustomizeMenu(gender)
end)

-- Command
RegisterCommand(Config.Command or 'eup', function()
    openEUPMenu()
end, false)

-- Print the currently worn component/prop collection names and collection-local indexes.
-- Collection-local identifiers remain stable across GTA title updates, unlike legacy global
-- drawable indexes, and are the preferred identifiers for future SouthVale outfit definitions.
RegisterCommand(Config.InspectCommand or 'eupinspect', function()
    if type(GetPedDrawableVariationCollectionName) ~= 'function' or type(GetPedPropCollectionName) ~= 'function' then
        lib.notify({ title = 'EUP Inspect', description = 'This FXServer/client build does not expose the collection-based clothing natives.', type = 'error' })
        return
    end

    local ped = PlayerPedId()
    local gender = getPedGender(ped)
    if not gender then
        lib.notify({ title = 'EUP Inspect', description = 'Switch to an MP freemode character first.', type = 'error' })
        return
    end

    print(('^5[eup-ui] Current %s outfit collection map:^0'):format(gender))
    print('^5[eup-ui] Components:^0')
    for _, slot in ipairs(ComponentSlots) do
        local globalDrawable = GetPedDrawableVariation(ped, slot.id)
        local texture = GetPedTextureVariation(ped, slot.id)
        local collection = GetPedDrawableVariationCollectionName(ped, slot.id)
        local localIndex = GetPedDrawableVariationCollectionLocalIndex(ped, slot.id)
        print(string.format('  component=%d label=%s global=%d collection=%q local=%d texture=%d', slot.id, slot.label, globalDrawable, collection or '', localIndex, texture))
    end

    print('^5[eup-ui] Props:^0')
    for _, slot in ipairs(PropSlots) do
        local globalDrawable = GetPedPropIndex(ped, slot.id)
        if globalDrawable >= 0 then
            local texture = GetPedPropTextureIndex(ped, slot.id)
            local collection = GetPedPropCollectionName(ped, slot.id, globalDrawable)
            local localIndex = GetPedPropCollectionLocalIndex(ped, slot.id, globalDrawable)
            print(string.format('  prop=%d label=%s global=%d collection=%q local=%d texture=%d', slot.id, slot.label, globalDrawable, collection or '', localIndex, texture))
        else
            print(string.format('  prop=%d label=%s none', slot.id, slot.label))
        end
    end

    lib.notify({
        title = 'EUP Inspect',
        description = 'Current clothing collection identifiers were written to F8.',
        type = 'success'
    })
end, false)

-- Runtime catalog audit for the currently selected freemode gender. This is intentionally
-- client-side because the valid drawable/texture counts depend on the clothing collections that
-- have actually streamed to that client.
RegisterCommand(Config.AuditCommand or 'eupaudit', function()
    local ped = PlayerPedId()
    local gender = getPedGender(ped)
    if not gender then
        lib.notify({ title = 'EUP Audit', description = 'Switch to an MP freemode character before running the audit.', type = 'error' })
        return
    end

    local checked, invalid = 0, 0
    local maxDetails = tonumber(Config.AuditMaxDetails) or 40
    local detailsPrinted = 0

    print(('^5[eup-ui] Runtime audit started for %s (%d total catalog entries).^0'):format(gender, #Outfits))
    for _, outfit in ipairs(Outfits) do
        if (outfit.Gender or 'Male') == gender then
            checked = checked + 1
            local valid, issues = validateOutfit(ped, outfit)
            if not valid then
                invalid = invalid + 1
                if detailsPrinted < maxDetails then
                    logOutfitIssues(outfit, issues)
                    detailsPrinted = detailsPrinted + 1
                end
            end
        end
    end

    local validCount = checked - invalid
    print(('^5[eup-ui] Runtime audit complete: %d checked, %d range-compatible, %d out of range.^0'):format(checked, validCount, invalid))
    if invalid > detailsPrinted then
        print(('^3[eup-ui] %d additional out-of-range outfits were omitted from detailed output. Increase Config.AuditMaxDetails to show more.^0'):format(invalid - detailsPrinted))
    end

    lib.notify({
        title = 'EUP Audit',
        description = string.format('%d/%d %s presets are range-compatible. %d out of range. Details are in F8.', validCount, checked, string.lower(gender), invalid),
        type = invalid == 0 and 'success' or 'warning',
        duration = 8000
    })
end, false)

-- Optional Keybind
if Config.Keybind and type(Config.Keybind) == 'string' and Config.Keybind ~= '' then
    RegisterKeyMapping(Config.Command or 'eup', 'Open Emergency Uniforms Pack Menu', 'keyboard', Config.Keybind)
end

CreateThread(function()
    loadOutfitData()
end)

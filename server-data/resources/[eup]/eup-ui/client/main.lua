local Outfits = {}
local CategorizedOutfits = {
    ['Male'] = {},
    ['Female'] = {}
}

local function splitString(inputStr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputStr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function convertComponent(input)
    if not input or type(input) ~= 'string' then return -1, 0 end
    local parts = splitString(input, ":")
    local d = tonumber(parts[1]) or 0
    local t = tonumber(parts[2]) or 1

    -- In EUP 8.1 configs, 0:0, -1:1, or non-positive indices represent no component/default
    if d <= 0 then
        return -1, 0
    end

    local finalD = d - 1
    local finalT = t > 0 and (t - 1) or 0
    return finalD, finalT
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
        local gender = outfit.Gender or 'Male'
        local dept = outfit.Department or outfit.Category2 or 'General'

        if not CategorizedOutfits[gender] then
            CategorizedOutfits[gender] = {}
        end
        if not CategorizedOutfits[gender][dept] then
            CategorizedOutfits[gender][dept] = {}
        end

        table.insert(CategorizedOutfits[gender][dept], outfit)
    end

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

    local maskD, maskT = convertComponent(outfit.Mask)
    local upperD, upperT = convertComponent(outfit.UpperSkin)
    local pantsD, pantsT = convertComponent(outfit.Pants)
    local bagD, bagT = convertComponent(outfit.Parachute)
    local shoesD, shoesT = convertComponent(outfit.Shoes)
    local accD, accT = convertComponent(outfit.Accessories)
    local underD, underT = convertComponent(outfit.UnderCoat)
    local armorD, armorT = convertComponent(outfit.Armor)
    local decalD, decalT = convertComponent(outfit.Decal)
    local topD, topT = convertComponent(outfit.Top)

    -- 1. Mask (Component 1)
    if maskD >= 0 then
        SetPedComponentVariation(ped, 1, maskD, maskT, 0)
    else
        SetPedComponentVariation(ped, 1, 0, 0, 0)
    end

    -- 2. Torso / Upper Skin (Component 3)
    if upperD >= 0 then
        SetPedComponentVariation(ped, 3, upperD, upperT, 0)
    else
        SetPedComponentVariation(ped, 3, isMale and 0 or 4, 0, 0)
    end

    -- 3. Pants / Legs (Component 4)
    if pantsD >= 0 then
        SetPedComponentVariation(ped, 4, pantsD, pantsT, 0)
    end

    -- 4. Parachute / Bags (Component 5)
    if bagD >= 0 then
        SetPedComponentVariation(ped, 5, bagD, bagT, 0)
    else
        SetPedComponentVariation(ped, 5, 0, 0, 0)
    end

    -- 5. Shoes / Feet (Component 6)
    if shoesD >= 0 then
        SetPedComponentVariation(ped, 6, shoesD, shoesT, 0)
    end

    -- 6. Accessories / Neck (Component 7)
    if accD >= 0 then
        SetPedComponentVariation(ped, 7, accD, accT, 0)
    else
        SetPedComponentVariation(ped, 7, 0, 0, 0)
    end

    -- 7. Undershirt / Undercoat (Component 8)
    if underD >= 0 then
        SetPedComponentVariation(ped, 8, underD, underT, 0)
    else
        SetPedComponentVariation(ped, 8, isMale and 15 or 14, 0, 0)
    end

    -- 8. Body Armor / Kevlar / Vests (Component 9)
    if armorD >= 0 then
        SetPedComponentVariation(ped, 9, armorD, armorT, 0)
    else
        SetPedComponentVariation(ped, 9, 0, 0, 0)
    end

    -- 9. Decal / Badges / Insignia (Component 10)
    if decalD >= 0 then
        SetPedComponentVariation(ped, 10, decalD, decalT, 0)
    else
        SetPedComponentVariation(ped, 10, 0, 0, 0)
    end

    -- 10. Top / Jacket / Shirt (Component 11)
    if topD >= 0 then
        SetPedComponentVariation(ped, 11, topD, topT, 0)
    end

    -- Props
    local hatD, hatT = convertComponent(outfit.Hat)
    if hatD >= 0 then
        SetPedPropIndex(ped, 0, hatD, hatT, true)
    else
        ClearPedProp(ped, 0)
    end

    local glassesD, glassesT = convertComponent(outfit.Glasses)
    if glassesD >= 0 then
        SetPedPropIndex(ped, 1, glassesD, glassesT, true)
    else
        ClearPedProp(ped, 1)
    end

    local earD, earT = convertComponent(outfit.Ear)
    if earD >= 0 then
        SetPedPropIndex(ped, 2, earD, earT, true)
    else
        ClearPedProp(ped, 2)
    end

    local watchD, watchT = convertComponent(outfit.Watch)
    if watchD >= 0 then
        SetPedPropIndex(ped, 6, watchD, watchT, true)
    else
        ClearPedProp(ped, 6)
    end

    -- Illenium-appearance synchronization & persistence
    if GetResourceState('illenium-appearance') == 'started' then
        pcall(function()
            local illenium = exports['illenium-appearance']
            local appearance = illenium:getPedAppearance(ped)
            if appearance and Config.SaveToAppearance then
                TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
            end
        end)
    end

    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)

    lib.notify({
        title = 'EUP Wardrobe',
        description = string.format('Equipped %s (%s)', outfit.Name, outfit.Department or 'Uniform'),
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
        if outfit.Gender == gender then
            local name = string.lower(outfit.Name or '')
            local dept = string.lower(outfit.Department or outfit.Category2 or '')
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
            description = string.format('%s • %s', outfit.Department or 'EUP', gender),
            icon = Config.DepartmentIcons[outfit.Department] or 'shirt',
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

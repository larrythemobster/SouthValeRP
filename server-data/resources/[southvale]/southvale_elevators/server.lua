-- SouthVale RP: elevator shaft/floor data store + admin capture commands.
-- Mirrors the capture-and-persist pattern ox_lib's own zoneCreator uses for
-- created_zones.lua (RegisterNetEvent + IsPlayerAceAllowed + SaveResourceFile).

local resource = GetCurrentResourceName()

---@type table<string, {label: string, floors: {label: string, coords: vector4}[]}>
local shafts = json.decode(LoadResourceFile(resource, 'data/shafts.json') or '{}') or {}

local function save()
    SaveResourceFile(resource, 'data/shafts.json', json.encode(shafts), -1)
    TriggerClientEvent('southvale_elevators:client:refresh', -1, shafts)
end

local function isAdmin(source)
    return source == 0 or IsPlayerAceAllowed(source, 'command')
end

lib.callback.register('southvale_elevators:server:getShafts', function()
    return shafts
end)

RegisterCommand('elevator', function(source, args)
    if not isAdmin(source) then return end

    local sub = args[1]
    if not sub then
        exports.qbx_core:Notify(source, 'Usage: /elevator addshaft|addfloor|removeshaft|removefloor|list ...', 'error')
        return
    end

    if sub == 'list' then
        local lines = {}
        for name, shaft in pairs(shafts) do
            lines[#lines + 1] = ('%s (%s): %d floor(s)'):format(name, shaft.label, #shaft.floors)
        end
        exports.qbx_core:Notify(source, #lines > 0 and table.concat(lines, ' | ') or 'No shafts configured', 'inform', 8000)
        return
    end

    if sub == 'addshaft' then
        local name, label = args[2], table.concat(args, ' ', 3)
        if not name or label == '' then
            exports.qbx_core:Notify(source, 'Usage: /elevator addshaft <name> <label>', 'error')
            return
        end
        if shafts[name] then
            exports.qbx_core:Notify(source, ('Shaft "%s" already exists'):format(name), 'error')
            return
        end
        shafts[name] = { label = label, floors = {} }
        save()
        exports.qbx_core:Notify(source, ('Created shaft "%s"'):format(name), 'success')
        return
    end

    if sub == 'removeshaft' then
        local name = args[2]
        if not shafts[name] then return end
        shafts[name] = nil
        save()
        exports.qbx_core:Notify(source, ('Removed shaft "%s"'):format(name), 'success')
        return
    end

    if sub == 'addfloor' then
        local name, floorLabel = args[2], table.concat(args, ' ', 3)
        local shaft = shafts[name]
        if not shaft or floorLabel == '' then
            exports.qbx_core:Notify(source, 'Usage: /elevator addfloor <shaftName> <floorLabel> (run while standing at the call point)', 'error')
            return
        end

        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        for _, floor in ipairs(shaft.floors) do
            if floor.label == floorLabel then
                exports.qbx_core:Notify(source, ('Floor "%s" already exists in "%s"'):format(floorLabel, name), 'error')
                return
            end
        end

        shaft.floors[#shaft.floors + 1] = {
            label = floorLabel,
            coords = vec4(coords.x, coords.y, coords.z, heading),
        }
        save()
        exports.qbx_core:Notify(source, ('Added floor "%s" to "%s"'):format(floorLabel, name), 'success')
        return
    end

    if sub == 'removefloor' then
        local name, floorLabel = args[2], table.concat(args, ' ', 3)
        local shaft = shafts[name]
        if not shaft then return end

        for i, floor in ipairs(shaft.floors) do
            if floor.label == floorLabel then
                table.remove(shaft.floors, i)
                save()
                exports.qbx_core:Notify(source, ('Removed floor "%s" from "%s"'):format(floorLabel, name), 'success')
                return
            end
        end
    end
end, false)

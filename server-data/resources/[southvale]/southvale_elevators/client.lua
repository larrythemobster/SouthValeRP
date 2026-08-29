-- SouthVale RP: elevator call points + floor selection.

---@type table<string, {label: string, floors: {label: string, coords: vector4}[]}>
local shafts = {}
local zoneIds = {}

local function clearZones()
    for _, id in ipairs(zoneIds) do
        exports.ox_target:removeZone(id)
    end
    zoneIds = {}
end

local function travelTo(coords)
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(cache.ped, coords.w)

    Wait(300)
    DoScreenFadeIn(400)
end

local function openFloorMenu(shaftName, currentLabel)
    local shaft = shafts[shaftName]
    if not shaft then return end

    local options = {}
    for _, floor in ipairs(shaft.floors) do
        if floor.label ~= currentLabel then
            options[#options + 1] = {
                title = floor.label,
                icon = 'fa-solid fa-building',
                onSelect = function()
                    travelTo(floor.coords)
                end,
            }
        end
    end

    if #options == 0 then
        exports.qbx_core:Notify('No other floors configured for this elevator', 'error')
        return
    end

    lib.registerContext({
        id = 'southvale_elevator_' .. shaftName,
        title = shaft.label,
        options = options,
    })
    lib.showContext('southvale_elevator_' .. shaftName)
end

local function buildZones()
    clearZones()

    for shaftName, shaft in pairs(shafts) do
        for _, floor in ipairs(shaft.floors) do
            local coords = floor.coords
            zoneIds[#zoneIds + 1] = exports.ox_target:addSphereZone({
                coords = vec3(coords.x, coords.y, coords.z),
                radius = 1.2,
                debug = false,
                options = {
                    {
                        name = ('southvale_elevator_%s_%s'):format(shaftName, floor.label),
                        icon = 'fa-solid fa-elevator',
                        label = 'Call Elevator (' .. floor.label .. ')',
                        distance = 2.0,
                        onSelect = function()
                            openFloorMenu(shaftName, floor.label)
                        end,
                    },
                },
            })
        end
    end
end

RegisterNetEvent('southvale_elevators:client:refresh', function(newShafts)
    shafts = newShafts or {}
    buildZones()
end)

CreateThread(function()
    local result = lib.callback.await('southvale_elevators:server:getShafts', false)
    shafts = result or {}
    buildZones()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    clearZones()
end)

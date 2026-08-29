-- SouthVale RP: real driven-distance tracking (feeds the `drivingdistance`
-- column that already exists in `player_vehicles` but was never written to
-- by anything other than the mechanic tuning bridge).

local METERS_PER_MILE = 1609.344
local REPORT_INTERVAL_MS = 30000 -- flush accumulated distance to the server every 30s
local MIN_REPORT_METERS = 15.0   -- don't spam the server for parked/rounding jitter

local pendingMeters = 0.0
local lastCoords = nil
local lastPlate = nil

local function getPlate(vehicle)
    return vehicle and vehicle ~= 0 and GetVehicleNumberPlateText(vehicle):gsub('%s+', '') or nil
end

CreateThread(function()
    while true do
        Wait(1000)

        local vehicle = cache.vehicle
        if vehicle and cache.seat == -1 then
            local plate = getPlate(vehicle)
            local coords = GetEntityCoords(vehicle)

            if plate and lastPlate == plate and lastCoords then
                local delta = #(coords - lastCoords)
                -- Ignore teleports (garages, admin noclip, respawns) so odometers
                -- don't jump by thousands of "miles" in a single tick.
                if delta > 0.05 and delta < 50.0 then
                    pendingMeters += delta
                end
            end

            lastCoords = coords
            lastPlate = plate
        else
            lastCoords = nil
            lastPlate = nil
        end
    end
end)

CreateThread(function()
    while true do
        Wait(REPORT_INTERVAL_MS)

        if pendingMeters >= MIN_REPORT_METERS and lastPlate then
            TriggerServerEvent('southvale_odometer:server:addDistance', lastPlate, math.floor(pendingMeters))
            pendingMeters = 0.0
        end
    end
end)

-- Flush on resource stop / vehicle change so short trips aren't lost.
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    if pendingMeters >= MIN_REPORT_METERS and lastPlate then
        TriggerServerEvent('southvale_odometer:server:addDistance', lastPlate, math.floor(pendingMeters))
    end
end)

RegisterCommand('mileage', function()
    local vehicle = cache.vehicle
    if not vehicle then
        exports.qbx_core:Notify(locale('error.no_vehicle'), 'error')
        return
    end

    local plate = getPlate(vehicle)
    if not plate then return end

    local meters = lib.callback.await('southvale_odometer:server:getDistance', false, plate)
    if not meters then
        exports.qbx_core:Notify(locale('error.not_owned'), 'error')
        return
    end

    local miles = meters / METERS_PER_MILE
    exports.qbx_core:Notify(locale('success.mileage'):format(lib.math.round(miles, 1)), 'inform', 6000)
end, false)

TriggerEvent('chat:addSuggestion', '/mileage', 'Shows the odometer reading for the vehicle you are driving')

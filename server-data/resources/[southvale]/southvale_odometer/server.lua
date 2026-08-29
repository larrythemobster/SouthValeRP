-- SouthVale RP: server side of the odometer. Writes to the existing
-- `player_vehicles.drivingdistance` column (int, meters) instead of adding
-- a new schema -- that column already exists but nothing populated it.

lib.callback.register('southvale_odometer:server:getDistance', function(source, plate)
    local row = MySQL.scalar.await('SELECT drivingdistance FROM player_vehicles WHERE plate = ?', { plate })
    return row
end)

RegisterNetEvent('southvale_odometer:server:addDistance', function(plate, meters)
    if type(meters) ~= 'number' or meters <= 0 or meters > 2000 then return end -- reject bogus/tampered deltas

    local exists = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ?', { plate })
    if not exists then return end -- only track vehicles that exist in player_vehicles

    MySQL.update('UPDATE player_vehicles SET drivingdistance = COALESCE(drivingdistance, 0) + ? WHERE plate = ?', { meters, plate })
end)

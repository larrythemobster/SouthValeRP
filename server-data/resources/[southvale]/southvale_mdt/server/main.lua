-- SouthVale RP: MDT server callbacks. Every callback re-checks the caller's
-- live job on the server -- the client-side duty gate is UX only, never trust it.

local LEO_JOBS = { police = true, bcso = true, sasp = true }

local function isOnDutyLeo(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end

    local job = player.PlayerData.job
    return job and LEO_JOBS[job.name] and job.onduty or false
end

lib.callback.register('southvale_mdt:server:checkAccess', function(source)
    return isOnDutyLeo(source)
end)

lib.callback.register('southvale_mdt:server:searchCitizens', function(source, query)
    if not isOnDutyLeo(source) then return {} end
    if not query or #query < 2 then return {} end

    local like = '%' .. query .. '%'
    local rows = MySQL.query.await([[
        SELECT citizenid, name, phone_number, charinfo, metadata
        FROM players
        WHERE name LIKE ? OR citizenid = ?
        LIMIT 20
    ]], { like, query })

    local results = {}
    for _, row in ipairs(rows or {}) do
        local charinfo = json.decode(row.charinfo or '{}') or {}
        local metadata = json.decode(row.metadata or '{}') or {}
        results[#results + 1] = {
            citizenid = row.citizenid,
            name = row.name,
            firstname = charinfo.firstname,
            lastname = charinfo.lastname,
            phone = row.phone_number,
            hasRecord = metadata.criminalrecord and metadata.criminalrecord.hasRecord or false,
        }
    end

    return results
end)

lib.callback.register('southvale_mdt:server:searchVehicles', function(source, query)
    if not isOnDutyLeo(source) then return {} end
    if not query or #query < 2 then return {} end

    query = query:gsub('%s+', ''):upper()
    local like = '%' .. query .. '%'
    local rows = MySQL.query.await([[
        SELECT pv.plate, pv.fakeplate, pv.vehicle, pv.citizenid, pv.state, p.name AS ownerName
        FROM player_vehicles pv
        LEFT JOIN players p ON p.citizenid = pv.citizenid
        WHERE pv.plate LIKE ? OR pv.fakeplate LIKE ?
        LIMIT 20
    ]], { like, like })

    local results = {}
    for _, row in ipairs(rows or {}) do
        local vehicleData = exports.qbx_core:GetVehiclesByName(row.vehicle)
        results[#results + 1] = {
            plate = row.plate,
            fakeplate = row.fakeplate,
            model = vehicleData and vehicleData.name or row.vehicle,
            ownerName = row.ownerName,
            citizenid = row.citizenid,
            impounded = row.state == 2,
        }
    end

    return results
end)

lib.callback.register('southvale_mdt:server:getIncidents', function(source)
    if not isOnDutyLeo(source) then return {} end

    local rows = MySQL.query.await('SELECT * FROM southvale_mdt_incidents ORDER BY id DESC LIMIT 50')
    for _, row in ipairs(rows or {}) do
        row.citizens = json.decode(row.citizens or '[]') or {}
    end
    return rows or {}
end)

RegisterNetEvent('southvale_mdt:server:createIncident', function(title, details, citizens)
    local src = source
    if not isOnDutyLeo(src) then return end
    if type(title) ~= 'string' or #title < 2 or type(details) ~= 'string' or #details < 2 then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    MySQL.insert('INSERT INTO southvale_mdt_incidents (title, details, citizens, officer_citizenid, officer_name) VALUES (?, ?, ?, ?, ?)', {
        title:sub(1, 150),
        details:sub(1, 5000),
        json.encode(type(citizens) == 'table' and citizens or {}),
        player.PlayerData.citizenid,
        player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
    })

    TriggerClientEvent('southvale_mdt:client:incidentsChanged', -1)
end)

RegisterNetEvent('southvale_mdt:server:deleteIncident', function(id)
    local src = source
    if not isOnDutyLeo(src) then return end
    if type(id) ~= 'number' then return end

    MySQL.update('DELETE FROM southvale_mdt_incidents WHERE id = ?', { id })
    TriggerClientEvent('southvale_mdt:client:incidentsChanged', -1)
end)

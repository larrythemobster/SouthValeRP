local Config = SouthValeMDT
local RESOURCE = GetCurrentResourceName()

local function trim(value, limit)
    if type(value) ~= 'string' then return nil end
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    if value == '' then return nil end
    return value:sub(1, limit)
end

local function playerFor(source)
    local player = exports.qbx_core:GetPlayer(source)
    local job = player and player.PlayerData.job
    if not player or not job or not Config.LeoJobs[job.name] or not job.onduty then return nil end
    return player
end

local function officer(source)
    local player = playerFor(source)
    if not player then return nil end
    local data = player.PlayerData
    local grade = tonumber(data.job.grade.level or data.job.grade) or 0
    return {
        player = player, citizenid = data.citizenid,
        name = ('%s %s'):format(data.charinfo.firstname or 'Unknown', data.charinfo.lastname or ''),
        callsign = data.metadata and data.metadata.callsign or 'Unassigned',
        department = data.job.label or data.job.name,
        rank = data.job.grade.name or tostring(grade), grade = grade,
    }
end

local function requireOfficer(source, minimum)
    local user = officer(source)
    return user and user.grade >= (minimum or 0) and user or nil
end

local function numberFor(prefix)
    return ('%s-%s-%04d'):format(prefix, os.date('%Y%m%d'), math.random(0, 9999))
end

local function notify(source, message, kind)
    TriggerClientEvent('ox_lib:notify', source, { title = 'SouthVale MDT', description = message, type = kind or 'error' })
end

local function decode(value, fallback)
    if type(value) ~= 'string' then return fallback end
    return json.decode(value) or fallback
end

local chargesByCode = {}
for _, charge in ipairs(Config.Charges) do chargesByCode[charge.code] = charge end

local function selectedCharges(raw)
    if type(raw) ~= 'table' then return nil end
    local result, seen, fine, jail = {}, {}, 0, 0
    for _, code in ipairs(raw) do
        local charge = chargesByCode[code]
        if charge and not seen[code] then
            seen[code] = true
            result[#result + 1] = charge
            fine = fine + charge.fine
            jail = jail + charge.jail
        end
    end
    if #result == 0 then return nil end
    return result, fine, jail
end

local function activeCount()
    local count = 0
    for _, source in ipairs(GetPlayers()) do if playerFor(tonumber(source)) then count = count + 1 end end
    return count
end

local function expiry(status)
    MySQL.update.await("UPDATE southvale_mdt_warrants SET status = 'expired' WHERE status = 'active' AND expires_at IS NOT NULL AND expires_at <= NOW()")
    MySQL.update.await("UPDATE southvale_mdt_bolos SET status = 'expired' WHERE status = 'active' AND expires_at IS NOT NULL AND expires_at <= NOW()")
end

local function detailCitizen(citizenid)
    local row = MySQL.single.await('SELECT citizenid, name, phone_number, charinfo, metadata FROM players WHERE citizenid = ?', { citizenid })
    if not row then return nil end
    local charinfo, metadata = decode(row.charinfo, {}), decode(row.metadata, {})
    local profile = {
        citizenid = row.citizenid, name = row.name, firstname = charinfo.firstname, lastname = charinfo.lastname,
        birthdate = charinfo.birthdate, gender = charinfo.gender, phone = row.phone_number,
        licenses = metadata.licences or metadata.licenses or {}, mugshot = metadata.mugshot,
    }
    profile.warrants = MySQL.query.await("SELECT id, warrant_number, type, reason, status, expires_at, created_at FROM southvale_mdt_warrants WHERE citizenid = ? ORDER BY created_at DESC LIMIT 50", { citizenid }) or {}
    profile.bolos = MySQL.query.await("SELECT id, bolo_number, title, reason, status, expires_at, created_at FROM southvale_mdt_bolos WHERE citizenid = ? ORDER BY created_at DESC LIMIT 50", { citizenid }) or {}
    profile.notes = MySQL.query.await('SELECT id, body, author_name, created_at FROM southvale_mdt_notes WHERE citizenid = ? ORDER BY id DESC LIMIT 50', { citizenid }) or {}
    profile.citations = MySQL.query.await('SELECT id, citation_number, fine, status, created_at FROM southvale_mdt_citations WHERE citizenid = ? ORDER BY id DESC LIMIT 50', { citizenid }) or {}
    profile.arrests = MySQL.query.await('SELECT id, arrest_number, fine, sentence_minutes, status, created_at FROM southvale_mdt_arrests WHERE citizenid = ? ORDER BY id DESC LIMIT 50', { citizenid }) or {}
    profile.vehicles = MySQL.query.await('SELECT plate, vehicle, state FROM player_vehicles WHERE citizenid = ? ORDER BY id DESC LIMIT 50', { citizenid }) or {}
    profile.incidents = MySQL.query.await('SELECT id, report_number, title, created_at FROM southvale_mdt_incidents WHERE citizens LIKE ? ORDER BY id DESC LIMIT 50', { '%' .. citizenid .. '%' }) or {}
    return profile
end

lib.callback.register('southvale_mdt:server:getBootstrap', function(source)
    local user = requireOfficer(source)
    if not user then return nil end
    expiry()
    local activeOfficers, prisoners = {}, {}
    for _, id in ipairs(GetPlayers()) do
        local current = officer(tonumber(id))
        if current then activeOfficers[#activeOfficers + 1] = { name = current.name, callsign = current.callsign, department = current.department, rank = current.rank } end
        local state = Player(tonumber(id)).state
        if state and state.jailTime and state.jailTime > 0 then prisoners[#prisoners + 1] = { name = GetPlayerName(id), minutes = state.jailTime } end
    end
    return {
        officer = { name = user.name, callsign = user.callsign, department = user.department, rank = user.rank, grade = user.grade },
        permissions = { supervisor = user.grade >= Config.SupervisorGrade, warrants = user.grade >= Config.WarrantGrade },
        charges = Config.Charges, activeOfficers = activeOfficers, prisoners = prisoners,
        recentIncidents = MySQL.query.await('SELECT id, report_number, title, officer_name, created_at FROM southvale_mdt_incidents ORDER BY id DESC LIMIT 8') or {},
        bolos = MySQL.query.await("SELECT id, bolo_number, subject_type, title, reason, expires_at FROM southvale_mdt_bolos WHERE status = 'active' ORDER BY id DESC LIMIT 12") or {},
        warrants = MySQL.query.await("SELECT id, warrant_number, citizenid, reason, expires_at FROM southvale_mdt_warrants WHERE status = 'active' ORDER BY id DESC LIMIT 12") or {},
        recentArrests = MySQL.query.await('SELECT arrest_number, citizenid, sentence_minutes, created_at FROM southvale_mdt_arrests ORDER BY id DESC LIMIT 8') or {},
        recentCitations = MySQL.query.await('SELECT citation_number, citizenid, fine, status, created_at FROM southvale_mdt_citations ORDER BY id DESC LIMIT 8') or {},
    }
end)

lib.callback.register('southvale_mdt:server:searchCitizens', function(source, query)
    if not requireOfficer(source) then return {} end
    query = trim(query, 80)
    if not query or #query < 2 then return {} end
    local like = '%' .. query .. '%'
    local rows = MySQL.query.await([[SELECT p.citizenid, p.name, p.phone_number, p.charinfo, p.metadata,
        (SELECT COUNT(*) FROM southvale_mdt_warrants w WHERE w.citizenid = p.citizenid AND w.status = 'active') AS activeWarrants
        FROM players p WHERE p.citizenid = ? OR p.phone_number = ? OR p.name LIKE ? OR p.charinfo LIKE ? LIMIT 30]], { query, query, like, like }) or {}
    for _, row in ipairs(rows) do
        local charinfo, metadata = decode(row.charinfo, {}), decode(row.metadata, {})
        row.charinfo, row.metadata = nil, nil
        row.firstname, row.lastname, row.phone = charinfo.firstname, charinfo.lastname, row.phone_number
        row.hasRecord = metadata.criminalrecord and metadata.criminalrecord.hasRecord or false
    end
    return rows
end)

lib.callback.register('southvale_mdt:server:getCitizen', function(source, citizenid)
    if not requireOfficer(source) then return nil end
    citizenid = trim(citizenid, 50)
    if not citizenid then return nil end
    expiry()
    return detailCitizen(citizenid)
end)

lib.callback.register('southvale_mdt:server:searchVehicles', function(source, query)
    if not requireOfficer(source) then return {} end
    query = trim(query, 80)
    if not query or #query < 2 then return {} end
    local normalized, like = query:gsub('%s+', ''):upper(), '%' .. query .. '%'
    local rows = MySQL.query.await([[SELECT pv.plate, pv.fakeplate, pv.vehicle, pv.citizenid, pv.state, p.name AS owner_name,
        (SELECT COUNT(*) FROM southvale_mdt_vehicle_flags f WHERE f.plate = pv.plate AND f.active = 1) AS activeFlags,
        (SELECT COUNT(*) FROM southvale_mdt_bolos b WHERE b.plate = pv.plate AND b.status = 'active') AS activeBolos
        FROM player_vehicles pv LEFT JOIN players p ON p.citizenid = pv.citizenid
        WHERE REPLACE(UPPER(pv.plate), ' ', '') LIKE ? OR REPLACE(UPPER(COALESCE(pv.fakeplate, '')), ' ', '') LIKE ? OR pv.vehicle LIKE ? OR p.name LIKE ? LIMIT 30]],
        { '%' .. normalized .. '%', '%' .. normalized .. '%', like, like }) or {}
    for _, row in ipairs(rows) do
        local vehicle = exports.qbx_core:GetVehiclesByName(row.vehicle)
        row.model = vehicle and vehicle.name or row.vehicle
        row.class = vehicle and vehicle.category or 'Unknown'
        row.impounded = row.state == 2
        row.flags = row.activeFlags > 0 and { true } or {}
        row.bolos = row.activeBolos > 0 and { true } or {}
    end
    return rows
end)

lib.callback.register('southvale_mdt:server:getIncidents', function(source)
    if not requireOfficer(source) then return {} end
    return MySQL.query.await('SELECT id, report_number, title, details, officer_name, citizens, evidence, created_at, updated_at FROM southvale_mdt_incidents ORDER BY id DESC LIMIT 100') or {}
end)

lib.callback.register('southvale_mdt:server:saveIncident', function(source, payload)
    local user = requireOfficer(source)
    if not user or type(payload) ~= 'table' then return { ok = false } end
    local title, details = trim(payload.title, 150), trim(payload.details, 5000)
    if not title or not details then return { ok = false, error = 'Title and narrative are required.' } end
    local citizens = type(payload.citizens) == 'table' and payload.citizens or {}
    local evidence = type(payload.evidence) == 'table' and payload.evidence or {}
    if type(payload.evidence) == 'string' then
        for reference in payload.evidence:gmatch('[^,]+') do
            reference = trim(reference, 100)
            if reference then evidence[#evidence + 1] = reference end
            if #evidence == 50 then break end
        end
    end
    local id = tonumber(payload.id)
    if id then
        local existing = MySQL.single.await('SELECT officer_citizenid FROM southvale_mdt_incidents WHERE id = ?', { id })
        if not existing or (existing.officer_citizenid ~= user.citizenid and user.grade < Config.SupervisorGrade) then return { ok = false, error = 'You cannot edit this report.' } end
        MySQL.update.await('UPDATE southvale_mdt_incidents SET title = ?, details = ?, citizens = ?, evidence = ? WHERE id = ?', { title, details, json.encode(citizens), json.encode(evidence), id })
    else
        id = MySQL.insert.await('INSERT INTO southvale_mdt_incidents (report_number, title, details, citizens, evidence, officer_citizenid, officer_name) VALUES (?, ?, ?, ?, ?, ?, ?)',
            { numberFor('RPT'), title, details, json.encode(citizens), json.encode(evidence), user.citizenid, user.name })
    end
    TriggerClientEvent('southvale_mdt:client:refresh', -1)
    return { ok = true, id = id }
end)

lib.callback.register('southvale_mdt:server:addNote', function(source, citizenid, body)
    local user = requireOfficer(source)
    citizenid, body = trim(citizenid, 50), trim(body, 2000)
    if not user or not citizenid or not body or not MySQL.scalar.await('SELECT citizenid FROM players WHERE citizenid = ?', { citizenid }) then return false end
    MySQL.insert.await('INSERT INTO southvale_mdt_notes (citizenid, body, author_citizenid, author_name) VALUES (?, ?, ?, ?)', { citizenid, body, user.citizenid, user.name })
    return true
end)

lib.callback.register('southvale_mdt:server:createWarrant', function(source, payload)
    local user = requireOfficer(source, Config.WarrantGrade)
    if not user or type(payload) ~= 'table' then return { ok = false, error = 'Supervisor authorization required.' } end
    local citizenid, reason = trim(payload.citizenid, 50), trim(payload.reason, 500)
    local warrantType = payload.type == 'search' and 'search' or 'arrest'
    if not citizenid or not reason or not MySQL.scalar.await('SELECT citizenid FROM players WHERE citizenid = ?', { citizenid }) then return { ok = false, error = 'A valid subject and reason are required.' } end
    local expiration = trim(payload.expiresAt, 25)
    local id = MySQL.insert.await('INSERT INTO southvale_mdt_warrants (warrant_number, citizenid, type, reason, notes, incident_id, issued_by_citizenid, issued_by_name, approved_by_citizenid, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { numberFor('WAR'), citizenid, warrantType, reason, trim(payload.notes, 5000), tonumber(payload.incidentId), user.citizenid, user.name, user.citizenid, expiration })
    TriggerClientEvent('southvale_mdt:client:refresh', -1)
    return { ok = true, id = id }
end)

lib.callback.register('southvale_mdt:server:updateWarrant', function(source, id, status)
    local user = requireOfficer(source, Config.WarrantGrade)
    id = tonumber(id)
    if not user or not id or not ({ served = true, cancelled = true })[status] then return false end
    MySQL.update.await("UPDATE southvale_mdt_warrants SET status = ?, served_at = IF(? = 'served', NOW(), served_at) WHERE id = ? AND status = 'active'", { status, status, id })
    TriggerClientEvent('southvale_mdt:client:refresh', -1)
    return true
end)

lib.callback.register('southvale_mdt:server:createBolo', function(source, payload)
    local user = requireOfficer(source)
    if not user or type(payload) ~= 'table' then return { ok = false } end
    local subjectType = payload.subjectType == 'vehicle' and 'vehicle' or 'person'
    local title, reason, description = trim(payload.title, 150), trim(payload.reason, 500), trim(payload.description, 5000)
    local citizenid, plate = trim(payload.citizenid, 50), trim(payload.plate, 15)
    if not title or not reason or not description or (subjectType == 'person' and not citizenid) or (subjectType == 'vehicle' and not plate) then return { ok = false, error = 'Complete the required BOLO fields.' } end
    local id = MySQL.insert.await('INSERT INTO southvale_mdt_bolos (bolo_number, subject_type, citizenid, plate, title, description, reason, incident_id, issued_by_citizenid, issued_by_name, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { numberFor('BOLO'), subjectType, citizenid, plate and plate:upper(), title, description, reason, tonumber(payload.incidentId), user.citizenid, user.name, trim(payload.expiresAt, 25) })
    TriggerClientEvent('southvale_mdt:client:refresh', -1)
    return { ok = true, id = id }
end)

lib.callback.register('southvale_mdt:server:updateBolo', function(source, id, status)
    if not requireOfficer(source) or not tonumber(id) or status ~= 'inactive' then return false end
    MySQL.update.await("UPDATE southvale_mdt_bolos SET status = 'inactive' WHERE id = ? AND status = 'active'", { tonumber(id) })
    TriggerClientEvent('southvale_mdt:client:refresh', -1)
    return true
end)

local function billCitizen(citizenid, amount, citationNumber)
    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if not target then return false end
    return target.Functions.RemoveMoney('bank', amount, ('mdt-citation:%s'):format(citationNumber))
end

lib.callback.register('southvale_mdt:server:createCitation', function(source, payload)
    local user = requireOfficer(source)
    if not user or type(payload) ~= 'table' then return { ok = false } end
    local citizenid, charges, fine = trim(payload.citizenid, 50), selectedCharges(payload.charges)
    if not citizenid or not charges or not MySQL.scalar.await('SELECT citizenid FROM players WHERE citizenid = ?', { citizenid }) then return { ok = false, error = 'Select a valid citizen and at least one charge.' } end
    local fineOverride = tonumber(payload.fine)
    if fineOverride and (fineOverride < 0 or fineOverride > Config.MaxFine or user.grade < Config.SupervisorGrade) then return { ok = false, error = 'Fine adjustment is not authorized.' } end
    fine = fineOverride or fine
    local number = numberFor('CIT')
    local paid = billCitizen(citizenid, fine, number)
    local id = MySQL.insert.await('INSERT INTO southvale_mdt_citations (citation_number, citizenid, incident_id, charges, fine, notes, status, paid_at, issued_by_citizenid, issued_by_name) VALUES (?, ?, ?, ?, ?, ?, ?, IF(? = \'paid\', NOW(), NULL), ?, ?)',
        { number, citizenid, tonumber(payload.incidentId), json.encode(charges), fine, trim(payload.notes, 5000), paid and 'paid' or 'unpaid', paid and 'paid' or 'unpaid', user.citizenid, user.name })
    TriggerClientEvent('southvale_mdt:client:refresh', -1)
    return { ok = true, id = id, paid = paid, fine = fine }
end)

lib.callback.register('southvale_mdt:server:createArrest', function(source, payload)
    local user = requireOfficer(source)
    if not user or type(payload) ~= 'table' then return { ok = false } end
    local citizenid, charges, fine, jail = trim(payload.citizenid, 50), selectedCharges(payload.charges)
    if not citizenid or not charges or not MySQL.scalar.await('SELECT citizenid FROM players WHERE citizenid = ?', { citizenid }) then return { ok = false, error = 'Select a valid citizen and at least one charge.' } end
    local sentence = tonumber(payload.sentenceMinutes)
    if sentence and (sentence < 0 or sentence > Config.MaxSentenceMinutes or user.grade < Config.SupervisorGrade) then return { ok = false, error = 'Sentence adjustment is not authorized.' } end
    sentence = math.floor(sentence or jail)
    local fineOverride = tonumber(payload.fine)
    if fineOverride and (fineOverride < 0 or fineOverride > Config.MaxFine or user.grade < Config.SupervisorGrade) then return { ok = false, error = 'Fine adjustment is not authorized.' } end
    fine = math.floor(fineOverride or fine)
    local target = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if not target or GetResourceState('xt-prison') ~= 'started' then return { ok = false, error = 'The subject must be online while xt-prison is running.' } end
    local jailed = lib.callback.await('xt-prison:client:enterJail', target.PlayerData.source, sentence) == true
    if not jailed then return { ok = false, error = 'xt-prison rejected the booking.' } end
    local number = numberFor('ARR')
    local id = MySQL.insert.await('INSERT INTO southvale_mdt_arrests (arrest_number, citizenid, incident_id, charges, fine, sentence_minutes, notes, arrested_by_citizenid, arrested_by_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { number, citizenid, tonumber(payload.incidentId), json.encode(charges), fine, sentence, trim(payload.notes, 5000), user.citizenid, user.name })
    if fine > 0 then billCitizen(citizenid, fine, number) end
    MySQL.update.await("UPDATE southvale_mdt_warrants SET status = 'served', served_at = NOW() WHERE citizenid = ? AND status = 'active' AND type = 'arrest'", { citizenid })
    TriggerClientEvent('southvale_mdt:client:refresh', -1)
    return { ok = true, id = id, jailed = jailed, online = target ~= nil }
end)

lib.callback.register('southvale_mdt:server:flagVehicle', function(source, plate, reason, notes)
    local user = requireOfficer(source)
    plate, reason = trim(plate, 15), trim(reason, 500)
    if not user or not plate or not reason then return false end
    MySQL.insert.await('INSERT INTO southvale_mdt_vehicle_flags (plate, reason, notes, created_by_citizenid) VALUES (?, ?, ?, ?)', { plate:upper(), reason, trim(notes, 5000), user.citizenid })
    return true
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == RESOURCE then math.randomseed(os.time()) end
end)

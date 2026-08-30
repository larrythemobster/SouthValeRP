local RESOURCE = GetCurrentResourceName()

local objectiveIds = {}
for i = 1, #SouthValeOnboarding.objectives do
    objectiveIds[SouthValeOnboarding.objectives[i].id] = SouthValeOnboarding.objectives[i]
end

local function playerCitizenId(source)
    local player = exports.qbx_core:GetPlayer(source)
    return player and player.PlayerData.citizenid or nil
end

local function createTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `southvale_onboarding` (
            `citizenid` VARCHAR(50) NOT NULL,
            `dismissed` TINYINT(1) NOT NULL DEFAULT 0,
            `completed` LONGTEXT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

local function decodeCompleted(value)
    local decoded = type(value) == 'string' and json.decode(value) or nil
    return type(decoded) == 'table' and decoded or {}
end

local function stateFor(citizenid)
    local row = MySQL.single.await('SELECT dismissed, completed FROM southvale_onboarding WHERE citizenid = ?', { citizenid })
    if not row then return nil end
    return { dismissed = row.dismissed == 1, completed = decodeCompleted(row.completed) }
end

exports('RegisterCharacter', function(citizenid)
    if type(citizenid) ~= 'string' or citizenid == '' then return false end
    MySQL.insert.await('INSERT IGNORE INTO southvale_onboarding (citizenid, completed) VALUES (?, ?)', { citizenid, json.encode({}) })
    return true
end)

lib.callback.register('southvale_onboarding:server:getState', function(source)
    local citizenid = playerCitizenId(source)
    if not citizenid then return false end
    return stateFor(citizenid) or false
end)

lib.callback.register('southvale_onboarding:server:dismiss', function(source)
    local citizenid = playerCitizenId(source)
    if not citizenid then return false end
    MySQL.update.await('UPDATE southvale_onboarding SET dismissed = 1 WHERE citizenid = ?', { citizenid })
    return true
end)

lib.callback.register('southvale_onboarding:server:completeObjective', function(source, objectiveId)
    if type(objectiveId) ~= 'string' then return false end
    local objective = objectiveIds[objectiveId]
    local citizenid = playerCitizenId(source)
    if not objective or not citizenid then return false end

    local ped = GetPlayerPed(source)
    if ped <= 0 then return false end
    local coords = GetEntityCoords(ped)
    if #(coords - objective.coords) > SouthValeOnboarding.objectiveRadius then return false end

    local state = stateFor(citizenid)
    if not state or state.completed[objectiveId] then return false end

    state.completed[objectiveId] = true
    MySQL.update.await('UPDATE southvale_onboarding SET completed = ? WHERE citizenid = ?', { json.encode(state.completed), citizenid })
    return true
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= RESOURCE then return end
    createTable()
end)

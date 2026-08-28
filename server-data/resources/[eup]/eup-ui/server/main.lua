local QboxCore = nil

local function getQboxCore()
    if not QboxCore and GetResourceState('qbx_core') == 'started' then
        QboxCore = exports.qbx_core
    end
    return QboxCore
end

lib.callback.register('eup-ui:server:checkPermission', function(source)
    local src = source

    if Config.AceRestricted then
        if not IsPlayerAceAllowed(src, Config.AcePermission) then
            return false, 'You do not have permission to access the EUP menu.'
        end
    end

    if Config.JobRestricted then
        local qbx = getQboxCore()
        if qbx then
            local player = qbx:GetPlayer(src)
            if not player or not player.PlayerData or not player.PlayerData.job or not Config.AllowedJobs[player.PlayerData.job.name] then
                return false, 'Your job is not authorized to use the EUP menu.'
            end
        end
    end

    return true, nil
end)

local isOpen = false

local function closeMdt()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMdt()
    if isOpen then return end

    local allowed = lib.callback.await('southvale_mdt:server:checkAccess', false)
    if not allowed then
        exports.qbx_core:Notify(locale('error.no_permission'), 'error')
        return
    end

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

RegisterCommand('mdt', function()
    if isOpen then closeMdt() else openMdt() end
end, false)

RegisterKeyMapping('mdt', 'Open MDT (police/BCSO/SASP on duty)', 'keyboard', 'F6')

RegisterNUICallback('close', function(_, cb)
    closeMdt()
    cb('ok')
end)

RegisterNUICallback('searchCitizens', function(data, cb)
    cb(lib.callback.await('southvale_mdt:server:searchCitizens', false, data.query))
end)

RegisterNUICallback('searchVehicles', function(data, cb)
    cb(lib.callback.await('southvale_mdt:server:searchVehicles', false, data.query))
end)

RegisterNUICallback('getIncidents', function(_, cb)
    cb(lib.callback.await('southvale_mdt:server:getIncidents', false))
end)

RegisterNUICallback('createIncident', function(data, cb)
    TriggerServerEvent('southvale_mdt:server:createIncident', data.title, data.details, data.citizens)
    cb('ok')
end)

RegisterNUICallback('deleteIncident', function(data, cb)
    TriggerServerEvent('southvale_mdt:server:deleteIncident', data.id)
    cb('ok')
end)

RegisterNetEvent('southvale_mdt:client:incidentsChanged', function()
    if isOpen then
        SendNUIMessage({ action = 'incidentsChanged' })
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    closeMdt()
end)

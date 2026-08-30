local isOpen = false

local function closeMdt()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function openMdt()
    if isOpen then return end
    local data = lib.callback.await('southvale_mdt:server:getBootstrap', false)
    if not data then
        exports.qbx_core:Notify(locale('error.no_permission'), 'error')
        return
    end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data })
end

RegisterCommand('mdt', function() if isOpen then closeMdt() else openMdt() end end, false)
RegisterKeyMapping('mdt', 'Open SouthVale MDT', 'keyboard', 'F6')

RegisterNUICallback('close', function(_, cb) closeMdt(); cb({ ok = true }) end)
RegisterNUICallback('bootstrap', function(_, cb) cb(lib.callback.await('southvale_mdt:server:getBootstrap', false)) end)
RegisterNUICallback('searchCitizens', function(data, cb) cb(lib.callback.await('southvale_mdt:server:searchCitizens', false, data.query)) end)
RegisterNUICallback('getCitizen', function(data, cb) cb(lib.callback.await('southvale_mdt:server:getCitizen', false, data.citizenid)) end)
RegisterNUICallback('searchVehicles', function(data, cb) cb(lib.callback.await('southvale_mdt:server:searchVehicles', false, data.query)) end)
RegisterNUICallback('getIncidents', function(_, cb) cb(lib.callback.await('southvale_mdt:server:getIncidents', false)) end)
RegisterNUICallback('saveIncident', function(data, cb) cb(lib.callback.await('southvale_mdt:server:saveIncident', false, data)) end)
RegisterNUICallback('addNote', function(data, cb) cb(lib.callback.await('southvale_mdt:server:addNote', false, data.citizenid, data.body)) end)
RegisterNUICallback('createWarrant', function(data, cb) cb(lib.callback.await('southvale_mdt:server:createWarrant', false, data)) end)
RegisterNUICallback('updateWarrant', function(data, cb) cb(lib.callback.await('southvale_mdt:server:updateWarrant', false, data.id, data.status)) end)
RegisterNUICallback('createBolo', function(data, cb) cb(lib.callback.await('southvale_mdt:server:createBolo', false, data)) end)
RegisterNUICallback('updateBolo', function(data, cb) cb(lib.callback.await('southvale_mdt:server:updateBolo', false, data.id, data.status)) end)
RegisterNUICallback('createCitation', function(data, cb) cb(lib.callback.await('southvale_mdt:server:createCitation', false, data)) end)
RegisterNUICallback('createArrest', function(data, cb) cb(lib.callback.await('southvale_mdt:server:createArrest', false, data)) end)
RegisterNUICallback('flagVehicle', function(data, cb) cb(lib.callback.await('southvale_mdt:server:flagVehicle', false, data.plate, data.reason, data.notes)) end)

RegisterNetEvent('southvale_mdt:client:refresh', function()
    if isOpen then SendNUIMessage({ action = 'refresh' }) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then closeMdt() end
end)

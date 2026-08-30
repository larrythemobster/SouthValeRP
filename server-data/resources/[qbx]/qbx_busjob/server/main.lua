local config = require 'config.server'
local sharedConfig = require 'config.shared'

local activeBuses = {}

local function isPlayerNear(src, locations, distance)
    local ped = GetPlayerPed(src)
    if ped <= 0 then return false end
    local coords = GetEntityCoords(ped)
    for i = 1, #locations do
        local location = locations[i]
        if #(coords - vec3(location.x, location.y, location.z)) < distance then
            return true
        end
    end
    return false
end

lib.callback.register('qbx_busjob:server:spawnBus', function(source, model)
    local player = exports.qbx_core:GetPlayer(source)
    if not player or player.PlayerData.job.name ~= 'bus' or model ~= joaat('bus') then return end
    if not isPlayerNear(source, { sharedConfig.location }, 20.0) then return end

    local oldBus = activeBuses[source]
    if oldBus and NetworkDoesEntityExistWithNetworkId(oldBus) then
        DeleteEntity(NetworkGetEntityFromNetworkId(oldBus))
    end

    local ped = GetPlayerPed(source)
    local netId = qbx.spawnVehicle({ model = joaat('bus'), spawnSource = ped, warp = true })
    if not netId or netId == 0 then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 then return end

    local plate = locale('info.bus_plate') .. tostring(math.random(1000, 9999))
    SetVehicleNumberPlateText(veh, plate)
    activeBuses[source] = netId
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)
    return netId
end)

RegisterNetEvent('qbx_busjob:server:NpcPay', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local netId = activeBuses[src]
    local ped = GetPlayerPed(src)
    local vehicle = ped > 0 and GetVehiclePedIsIn(ped, false) or 0

    if not player or player.PlayerData.job.name ~= 'bus'
        or not netId
        or not NetworkDoesEntityExistWithNetworkId(netId)
        or vehicle ~= NetworkGetEntityFromNetworkId(netId)
        or GetPedInVehicleSeat(vehicle, -1) ~= ped
        or not isPlayerNear(src, sharedConfig.npcLocations.locations, 20.0) then
        return DropPlayer(src, locale('error.exploit_attempt'))
    end

    local payment = math.random(15, 25)
    if math.random(1, 100) < config.bonusChance then
        payment = payment + math.random(10, 20)
    end
    player.Functions.AddMoney('cash', payment)
end)

AddEventHandler('playerDropped', function()
    activeBuses[source] = nil
end)

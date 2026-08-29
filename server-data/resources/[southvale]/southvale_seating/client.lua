-- SouthVale RP: sit on chairs/benches/stools via ox_target.
-- Generic model-based interaction; no per-location zone list to maintain.

local seated = false

local function standUp()
    if not seated then return end
    seated = false
    ClearPedTasks(cache.ped)
end

local function sitDown(entity)
    if seated or cache.vehicle then return end

    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)

    seated = true
    TaskStartScenarioAtPosition(cache.ped, Config.scenario, coords.x, coords.y, coords.z + Config.heightOffset, heading, 0, false, false)
end

exports.ox_target:addModel(Config.models, {
    {
        name = 'southvale_seating:sit',
        icon = 'fa-solid fa-chair',
        label = 'Sit down',
        distance = Config.interactDistance,
        canInteract = function()
            return not seated and not cache.vehicle and not LocalPlayer.state.isdead
        end,
        onSelect = function(data)
            sitDown(data.entity)
        end,
    },
})

RegisterCommand('standup', function()
    standUp()
end, false)

TriggerEvent('chat:addSuggestion', '/standup', 'Stand up from a chair/bench')

-- Any manual movement input cancels the seated scenario, matching how every
-- other seated interaction (benches included) behaves in vanilla GTA.
CreateThread(function()
    while true do
        Wait(250)
        if seated then
            if IsControlJustPressed(0, 32) or IsControlJustPressed(0, 33) or
               IsControlJustPressed(0, 34) or IsControlJustPressed(0, 35) or
               IsPedRagdoll(cache.ped) or IsEntityDead(cache.ped) then
                standUp()
            end
        else
            Wait(750)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    standUp()
end)

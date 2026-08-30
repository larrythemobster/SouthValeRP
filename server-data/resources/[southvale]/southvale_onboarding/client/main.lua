local state
local activeObjective
local activeBlip
local objectiveById = {}

for i = 1, #SouthValeOnboarding.objectives do
    local objective = SouthValeOnboarding.objectives[i]
    objectiveById[objective.id] = objective
end

local function clearRoute()
    SetWaypointOff()
    if activeBlip then
        RemoveBlip(activeBlip)
        activeBlip = nil
    end
    activeObjective = nil
end

local function setRoute(objective)
    clearRoute()
    activeObjective = objective.id
    SetNewWaypoint(objective.coords.x, objective.coords.y)
    activeBlip = AddBlipForCoord(objective.coords.x, objective.coords.y, objective.coords.z)
    SetBlipSprite(activeBlip, objective.blip.sprite)
    SetBlipColour(activeBlip, objective.blip.colour)
    SetBlipRoute(activeBlip, true)
    SetBlipRouteColour(activeBlip, objective.blip.colour)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(objective.title)
    EndTextCommandSetBlipName(activeBlip)
    lib.notify({ type = 'inform', description = ('Route set to %s.'):format(objective.title) })
end

local function showGuide()
    if not state then
        lib.notify({ type = 'inform', description = 'This character has no active arrival guide.' })
        return
    end

    local options = {
        {
            title = 'SouthVale arrival guide',
            description = 'Optional. Pick a destination, or skip the guide at any time.',
            icon = 'fa-solid fa-compass',
            readOnly = true,
        },
    }

    for i = 1, #SouthValeOnboarding.objectives do
        local objective = SouthValeOnboarding.objectives[i]
        local completed = state.completed[objective.id] == true
        options[#options + 1] = {
            title = objective.title,
            description = completed and 'Visited' or objective.description,
            icon = completed and 'fa-solid fa-circle-check' or objective.icon,
            disabled = completed,
            onSelect = function()
                setRoute(objective)
            end,
        }
    end

    options[#options + 1] = {
        title = 'How SouthVale works',
        description = 'Use third-eye interactions, F2 for inventory, and your phone item for NPWD. Keep roleplay respectful. Use /report for staff help.',
        icon = 'fa-solid fa-circle-info',
        readOnly = true,
    }
    options[#options + 1] = {
        title = 'Skip arrival guide',
        description = 'Stops reminders. You can still use /guide if this character has a guide.',
        icon = 'fa-solid fa-forward',
        onSelect = function()
            if lib.callback.await('southvale_onboarding:server:dismiss', false) then
                state.dismissed = true
                clearRoute()
                lib.notify({ type = 'success', description = 'Arrival guide skipped.' })
            end
        end,
    }

    lib.registerContext({ id = 'southvale_onboarding_guide', title = 'SouthVale RP', options = options })
    lib.showContext('southvale_onboarding_guide')
end

RegisterCommand(SouthValeOnboarding.menuCommand, showGuide, false)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(function()
        Wait(SouthValeOnboarding.arrivalDelayMs)
        state = lib.callback.await('southvale_onboarding:server:getState', false)
        if not state or state.dismissed then return end
        lib.notify({
            type = 'inform',
            duration = 8000,
            title = 'Welcome to SouthVale',
            description = 'Use /guide for optional first stops, jobs, and practical controls.',
        })
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    state = nil
    clearRoute()
end)

CreateThread(function()
    while true do
        if not state or state.dismissed or not activeObjective then
            Wait(2000)
        else
            local objective = objectiveById[activeObjective]
            if objective and #(GetEntityCoords(PlayerPedId()) - objective.coords) <= SouthValeOnboarding.objectiveRadius then
                if lib.callback.await('southvale_onboarding:server:completeObjective', false, activeObjective) then
                    state.completed[activeObjective] = true
                    lib.notify({ type = 'success', description = ('Arrival guide updated: %s.'):format(objective.title) })
                end
                clearRoute()
            end
            Wait(1500)
        end
    end
end)

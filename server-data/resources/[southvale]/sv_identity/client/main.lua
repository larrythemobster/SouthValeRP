local coreClientConfig = require '@qbx_core.config.client'
local coreSharedConfig = require '@qbx_core.config.shared'
local spawnConfig = require '@qbx_spawn.config.client'
local nationalities = coreClientConfig.characters.limitNationalities and require '@qbx_core.data.nationalities' or {}

local uiOpen = false
local uiView = 'characters'
local uiPayload
local previewCam
local characters = {}
local charactersBySlot = {}
local allowedSlots = 0
local selectedSlot
local spawnOptions = {}
local previewLocation

local function debugLog(message, ...)
    if not SVIdentity.debug then return end
    print(('[sv_identity] ' .. message):format(...))
end

local function trim(value)
    if type(value) ~= 'string' then return '' end
    return value:gsub('^%s+', ''):gsub('%s+$', '')
end

local function safeNumber(value)
    local number = tonumber(value)
    if not number then return 0 end
    return math.floor(number)
end

local function formatMoney(value)
    local amount = safeNumber(value)
    return (amount < 0 and '-$' or '$') .. tostring(math.abs(amount))
end

local function sendUi(message)
    uiPayload = message
    SendNUIMessage(message)
end

local function setUiFocus(enabled)
    uiOpen = enabled
    SetNuiFocus(enabled, enabled)
    SetNuiFocusKeepInput(false)
end

local function destroyCamera()
    if previewCam and DoesCamExist(previewCam) then
        SetCamActive(previewCam, false)
        DestroyCam(previewCam, true)
        RenderScriptCams(false, false, 250, true, true)
    end

    previewCam = nil
    ClearTimecycleModifier()
end

local function restorePlayerState(showRadar)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
    ClearPedTasksImmediately(ped)
    DisplayRadar(showRadar == true)
end

local function closeUi()
    setUiFocus(false)
    sendUi({ action = 'hide' })
end

local function cleanupPresentation(showRadar)
    closeUi()
    destroyCamera()
    restorePlayerState(showRadar)
end

local function waitForFadeOut(timeout)
    local expires = GetGameTimer() + (timeout or 3000)
    while not IsScreenFadedOut() and GetGameTimer() < expires do Wait(0) end
end

local function waitForNetworkSession(timeout)
    local expires = GetGameTimer() + (timeout or 15000)
    while not NetworkIsSessionStarted() and GetGameTimer() < expires do Wait(50) end
    return NetworkIsSessionStarted()
end

local function requestModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    local ok = pcall(lib.requestModel, hash, coreClientConfig.loadingModelsTimeout)
    return ok and HasModelLoaded(hash), hash
end

local function setDefaultPreviewPed()
    local models = { `mp_m_freemode_01`, `mp_f_freemode_01` }
    local model = models[math.random(1, #models)]
    local ok, hash = requestModel(model)
    if not ok then return end

    SetPlayerModel(cache.playerId, hash)
    SetModelAsNoLongerNeeded(hash)
end

local function previewCharacter(character)
    if not character or not character.citizenid then
        setDefaultPreviewPed()
        return
    end

    local ok, clothing, model = pcall(function()
        return lib.callback.await('qbx_core:server:getPreviewPedData', false, character.citizenid)
    end)

    if not ok or not clothing or not model then
        setDefaultPreviewPed()
        return
    end

    local loaded, hash = requestModel(model)
    if not loaded then
        setDefaultPreviewPed()
        return
    end

    SetPlayerModel(cache.playerId, hash)

    local decoded = clothing
    if type(clothing) == 'string' then
        local decodeOk, result = pcall(json.decode, clothing)
        decoded = decodeOk and result or nil
    end
    if decoded then
        pcall(function()
            exports['illenium-appearance']:setPedAppearance(PlayerPedId(), decoded)
        end)
    end

    SetModelAsNoLongerNeeded(hash)
end

local function pickPreviewLocation()
    local locations = coreClientConfig.characters.locations
    if type(locations) ~= 'table' or #locations == 0 then return nil end
    return locations[math.random(1, #locations)]
end

local function startPreviewScene()
    previewLocation = pickPreviewLocation()
    if not previewLocation then
        lib.notify({ type = 'error', description = 'Character preview configuration is unavailable.' })
        return false
    end

    DoScreenFadeOut(SVIdentity.preview.fadeOutMs)
    waitForFadeOut()

    local ped = PlayerPedId()
    SetEntityCoords(ped, previewLocation.pedCoords.x, previewLocation.pedCoords.y, previewLocation.pedCoords.z, false, false, false, false)
    SetEntityHeading(ped, previewLocation.pedCoords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, true, false)
    DisplayRadar(false)

    NetworkStartSoloTutorialSession()

    local expires = GetGameTimer() + 5000
    while not NetworkIsInTutorialSession() and GetGameTimer() < expires do Wait(0) end

    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(0.82)

    previewCam = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        previewLocation.camCoords.x,
        previewLocation.camCoords.y,
        previewLocation.camCoords.z,
        -6.0,
        0.0,
        previewLocation.camCoords.w,
        SVIdentity.preview.cameraFov,
        false,
        0
    )
    SetCamActive(previewCam, true)
    SetCamUseShallowDofMode(previewCam, true)
    SetCamNearDof(previewCam, 0.4)
    SetCamFarDof(previewCam, 1.8)
    SetCamDofStrength(previewCam, 0.7)
    RenderScriptCams(true, false, 350, true, true)

    CreateThread(function()
        while previewCam and DoesCamExist(previewCam) do
            SetUseHiDof()
            Wait(0)
        end
    end)

    return true
end

local function normalizeCharacter(raw, slot)
    if type(raw) ~= 'table' then return nil end

    local charinfo = type(raw.charinfo) == 'table' and raw.charinfo or {}
    local money = type(raw.money) == 'table' and raw.money or {}
    local job = type(raw.job) == 'table' and raw.job or {}
    local grade = type(job.grade) == 'table' and job.grade or {}

    return {
        slot = slot,
        firstname = trim(charinfo.firstname) ~= '' and trim(charinfo.firstname) or 'Unknown',
        lastname = trim(charinfo.lastname) ~= '' and trim(charinfo.lastname) or 'Character',
        birthdate = trim(charinfo.birthdate),
        nationality = trim(charinfo.nationality),
        gender = tonumber(charinfo.gender) == 1 and 'Female' or 'Male',
        job = trim(job.label) ~= '' and trim(job.label) or 'Unemployed',
        grade = trim(grade.name) ~= '' and trim(grade.name) or 'Civilian',
        cash = formatMoney(money.cash),
        bank = formatMoney(money.bank),
    }
end

local function rebuildCharacterIndex(list, amount)
    characters = type(list) == 'table' and list or {}
    charactersBySlot = {}
    allowedSlots = math.max(0, tonumber(amount) or 0)

    for i = 1, #characters do
        local character = characters[i]
        if type(character) == 'table' then
            local slot = tonumber(type(character.charinfo) == 'table' and character.charinfo.cid) or i
            slot = math.floor(slot)
            if slot >= 1 and slot <= allowedSlots then
                charactersBySlot[slot] = character
            end
        end
    end
end

local function characterUiData()
    local slots = {}
    for slot = 1, allowedSlots do
        local character = charactersBySlot[slot]
        slots[#slots + 1] = character and normalizeCharacter(character, slot) or { slot = slot, empty = true }
    end
    return slots
end

local function showCharacterUi(errorMessage)
    uiView = 'characters'
    setUiFocus(true)
    sendUi({
        action = 'showCharacters',
        brand = SVIdentity.brand,
        slots = characterUiData(),
        selectedSlot = selectedSlot,
        deletionEnabled = coreClientConfig.characters.enableDeleteButton == true,
        error = errorMessage,
    })
end

local function refreshCharacters(errorMessage)
    local ok, list, amount = pcall(function()
        return lib.callback.await('qbx_core:server:getCharacters', false)
    end)

    if not ok or type(list) ~= 'table' or type(amount) ~= 'number' then
        showCharacterUi(errorMessage or 'Unable to load your characters. Please try again.')
        return false
    end

    rebuildCharacterIndex(list, amount)

    if selectedSlot and not charactersBySlot[selectedSlot] then selectedSlot = nil end
    if not selectedSlot then
        for slot = 1, allowedSlots do
            if charactersBySlot[slot] then
                selectedSlot = slot
                break
            end
        end
    end

    if selectedSlot then
        previewCharacter(charactersBySlot[selectedSlot])
    else
        setDefaultPreviewPed()
    end

    showCharacterUi(errorMessage)
    return true
end

local function isValidName(value)
    local valueTrimmed = trim(value)
    if #valueTrimmed < SVIdentity.validation.minNameLength or #valueTrimmed > SVIdentity.validation.maxNameLength then return false end
    if valueTrimmed:find('%c') then return false end

    local profanity = coreClientConfig.characters.profanityWords or {}
    if profanity[valueTrimmed:lower()] then return false end
    for word in valueTrimmed:gmatch('%S+') do
        if profanity[word:lower()] then return false end
    end

    return true
end

local function isValidBirthdate(value)
    value = trim(value)
    local year, month, day = value:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    if not year or not month or not day then return false end
    if month < 1 or month > 12 or day < 1 or day > 31 then return false end

    local minDate = coreClientConfig.characters.dateMin
    local maxDate = coreClientConfig.characters.dateMax
    if type(minDate) == 'string' and value < minDate then return false end
    if type(maxDate) == 'string' and value > maxDate then return false end
    return true
end

local function nationalityAllowed(value)
    value = trim(value)
    if value == '' or #value > SVIdentity.validation.maxNationalityLength or value:find('%c') then return false end
    if not coreClientConfig.characters.limitNationalities then return true end

    for i = 1, #nationalities do
        if nationalities[i] == value then return true end
    end
    return false
end

local function showIdentityForm(slot)
    if slot < 1 or slot > allowedSlots or charactersBySlot[slot] then return end

    selectedSlot = slot
    uiView = 'identity'
    previewCharacter(nil)
    setUiFocus(true)
    sendUi({
        action = 'showIdentity',
        brand = SVIdentity.brand,
        slot = slot,
        nationalities = nationalities,
        limitNationalities = coreClientConfig.characters.limitNationalities == true,
        dateMin = coreClientConfig.characters.dateMin,
        dateMax = coreClientConfig.characters.dateMax,
    })
end

local showSpawnUi

local function runFirstAppearance()
    if GetResourceState('illenium-appearance') ~= 'started' then
        return false, 'Appearance customization is unavailable.'
    end

    closeUi()
    destroyCamera()

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, true)
    DisplayRadar(false)

    if IsScreenFadedOut() then DoScreenFadeIn(250) end

    while true do
        TriggerEvent('qb-clothes:client:CreateFirstCharacter')

        local startsBy = GetGameTimer() + 10000
        while not IsNuiFocused() and GetGameTimer() < startsBy do Wait(50) end
        if not IsNuiFocused() then
            return false, 'Appearance customization did not open.'
        end

        while IsNuiFocused() and GetResourceState('illenium-appearance') == 'started' do
            Wait(100)
        end

        if GetResourceState('illenium-appearance') ~= 'started' then
            return false, 'Appearance customization stopped unexpectedly.'
        end

        Wait(350)
        local ok, appearance = pcall(function()
            return lib.callback.await('illenium-appearance:server:getAppearance', false)
        end)

        if ok and appearance then
            DisplayRadar(false)
            return true
        end

        lib.notify({
            type = 'error',
            description = 'Save your appearance before entering SouthVale.',
        })
        Wait(500)
    end
end

local function spawnAtDefaultForFirstCharacter()
    DoScreenFadeOut(500)
    waitForFadeOut()
    cleanupPresentation(false)

    local coords = coreSharedConfig.defaultSpawn
    pcall(function()
        exports.spawnmanager:spawnPlayer({
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = coords.w,
        })
    end)

    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), coords.w)
    SetEntityVisible(PlayerPedId(), true, false)

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    TriggerEvent('qb-weathersync:client:EnableSync')

    DoScreenFadeIn(250)
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end

local function handoffNewCharacter()
    local appearanceOk, appearanceError = runFirstAppearance()
    if not appearanceOk then
        lib.notify({ type = 'error', description = appearanceError or 'Appearance customization failed.' })
        -- Keep Qbox's established no-apartment fallback available rather than
        -- leaving an already-created character frozen or behind a camera.
        spawnAtDefaultForFirstCharacter()
        return
    end

    if coreClientConfig.characters.startingApartment and GetResourceState('qbx_properties') == 'started' then
        DoScreenFadeOut(250)
        waitForFadeOut()
        restorePlayerState(false)
        TriggerEvent('apartments:client:setupSpawnUI')
        return
    end

    if GetResourceState('qbx_spawn') == 'started' and showSpawnUi(true) then
        return
    end

    local coords = coreSharedConfig.defaultSpawn
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), coords.w)
    TriggerEvent('qb-weathersync:client:EnableSync')
    restorePlayerState(true)
    DoScreenFadeIn(750)
end

local function createCharacter(data)
    if type(data) ~= 'table' then return false, 'Invalid character data.' end

    local firstname = trim(data.firstname)
    local lastname = trim(data.lastname)
    local birthdate = trim(data.birthdate)
    local nationality = trim(data.nationality)
    local gender = tonumber(data.gender)

    if not isValidName(firstname) then return false, 'Enter a valid first name.' end
    if not isValidName(lastname) then return false, 'Enter a valid last name.' end
    if not isValidBirthdate(birthdate) then return false, 'Enter a valid date of birth.' end
    if gender ~= 0 and gender ~= 1 then return false, 'Select a valid gender.' end
    if not nationalityAllowed(nationality) then return false, 'Select a valid nationality.' end

    local ok, newData = pcall(function()
        return lib.callback.await('qbx_core:server:createCharacter', false, {
            firstname = firstname,
            lastname = lastname,
            birthdate = birthdate,
            gender = gender,
            nationality = nationality,
        })
    end)

    if not ok or not newData then
        return false, 'Character creation was refused by the server.'
    end

    handoffNewCharacter()
    return true
end

local function setupSpawnCamera()
    local scene = SVIdentity.spawnScene
    local ped = PlayerPedId()

    SetEntityCoords(ped, scene.ped.x, scene.ped.y, scene.ped.z, false, false, false, false)
    SetEntityHeading(ped, scene.ped.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    DisplayRadar(false)

    previewCam = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        scene.camera.x,
        scene.camera.y,
        scene.camera.z,
        scene.cameraPitch,
        0.0,
        scene.camera.w,
        scene.cameraFov,
        false,
        2
    )
    SetCamActive(previewCam, true)
    RenderScriptCams(true, false, 350, true, true)

    DoScreenFadeIn(650)
end

local function buildSpawnOptions(isNewCharacter)
    spawnOptions = {}

    if not isNewCharacter then
        local okLast, lastCoords, lastPropertyId = pcall(function()
            return lib.callback.await('qbx_spawn:server:getLastLocation', false)
        end)

        if okLast and lastCoords then
            spawnOptions[#spawnOptions + 1] = {
                label = 'Last Location',
                description = lastPropertyId and 'Return to your last property.' or 'Continue from where you last left the city.',
                coords = lastCoords,
                propertyId = lastPropertyId,
                kind = 'last',
            }
        end
    end

    for i = 1, #(spawnConfig.spawns or {}) do
        local spawn = spawnConfig.spawns[i]
        spawnOptions[#spawnOptions + 1] = {
            label = spawn.label or ('Spawn %s'):format(i),
            description = 'Public arrival point',
            coords = spawn.coords,
            kind = 'public',
        }
    end

    if not isNewCharacter then
        local okProperties, properties = pcall(function()
            return lib.callback.await('qbx_spawn:server:getProperties', false)
        end)

        if okProperties and type(properties) == 'table' then
            for i = 1, #properties do
                local property = properties[i]
                spawnOptions[#spawnOptions + 1] = {
                    label = property.label or property.propertyName or ('Property %s'):format(i),
                    description = 'Owned property',
                    coords = property.coords,
                    propertyId = property.propertyId,
                    kind = 'property',
                }
            end
        end
    end

    return #spawnOptions > 0
end

showSpawnUi = function(isNewCharacter)
    if not buildSpawnOptions(isNewCharacter) then return false end

    setupSpawnCamera()
    uiView = 'spawn'
    setUiFocus(true)

    local uiSpawns = {}
    for i = 1, #spawnOptions do
        uiSpawns[i] = {
            id = i,
            label = spawnOptions[i].label,
            description = spawnOptions[i].description,
            kind = spawnOptions[i].kind,
        }
    end

    sendUi({
        action = 'showSpawns',
        brand = SVIdentity.brand,
        spawns = uiSpawns,
    })

    return true
end

local function finishSpawn(index)
    local spawn = spawnOptions[index]
    if not spawn then return false end

    DoScreenFadeOut(500)
    waitForFadeOut()
    closeUi()
    destroyCamera()

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)

    if spawn.propertyId then
        TriggerServerEvent('qbx_properties:server:enterProperty', { id = spawn.propertyId, isSpawn = true })
    elseif spawn.coords then
        SetEntityCoords(ped, spawn.coords.x, spawn.coords.y, spawn.coords.z, false, false, false, false)
        SetEntityHeading(ped, spawn.coords.w or 0.0)
    end

    TriggerEvent('qb-weathersync:client:EnableSync')
    DisplayRadar(true)
    DoScreenFadeIn(750)
    uiView = 'characters'
    return true
end

local function loadCharacter(slot)
    local character = charactersBySlot[slot]
    if not character or not character.citizenid then return false, 'That character is no longer available.' end

    DoScreenFadeOut(150)
    waitForFadeOut(1500)
    closeUi()
    destroyCamera()

    local ok, loaded = pcall(function()
        return lib.callback.await('qbx_core:server:loadCharacter', false, character.citizenid)
    end)

    if ok and loaded ~= false then
        local expires = GetGameTimer() + 5000
        while (not QBX.PlayerData or QBX.PlayerData.citizenid ~= character.citizenid) and GetGameTimer() < expires do
            Wait(50)
        end
    end

    if not ok or loaded == false or not QBX.PlayerData or QBX.PlayerData.citizenid ~= character.citizenid then
        restorePlayerState(false)
        if not startPreviewScene() then return false, 'Character login failed.' end
        previewCharacter(character)
        showCharacterUi('Character login failed. Please try again.')
        return false, 'Character login failed.'
    end

    if GetResourceState('qbx_spawn') == 'started' and showSpawnUi() then
        return true
    end

    local coords = QBX.PlayerData and QBX.PlayerData.position or coreSharedConfig.defaultSpawn
    cleanupPresentation(false)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), coords.w or 0.0)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerEvent('qb-weathersync:client:EnableSync')
    DisplayRadar(true)
    DoScreenFadeIn(750)
    return true
end

local function deleteCharacter(slot)
    if not coreClientConfig.characters.enableDeleteButton then
        return false, 'Character deletion is disabled.'
    end

    local character = charactersBySlot[slot]
    if not character or not character.citizenid then return false, 'Character not found.' end

    local ok, success = pcall(function()
        return lib.callback.await('qbx_core:server:deleteCharacter', false, character.citizenid)
    end)

    if not ok or not success then return false, 'The server refused that deletion.' end

    selectedSlot = nil
    refreshCharacters('Character deleted permanently.')
    return true
end

local function startCharacterSelection()
    if LocalPlayer.state.isLoggedIn or QBX.IsLoggedIn then
        debugLog('Ignoring selector start because player is already logged in')
        return
    end

    if not waitForNetworkSession() then
        lib.notify({ type = 'error', description = 'FiveM network session did not initialize.' })
        return
    end

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    local ok, list, amount = pcall(function()
        return lib.callback.await('qbx_core:server:getCharacters', false)
    end)

    if not ok or type(list) ~= 'table' or type(amount) ~= 'number' then
        lib.notify({ type = 'error', description = 'SouthVale could not load your character list.' })
        return
    end

    rebuildCharacterIndex(list, amount)
    selectedSlot = nil
    for slot = 1, allowedSlots do
        if charactersBySlot[slot] then
            selectedSlot = slot
            break
        end
    end

    if selectedSlot then previewCharacter(charactersBySlot[selectedSlot]) else setDefaultPreviewPed() end
    if not startPreviewScene() then return end

    -- Model changes can replace the ped handle, so re-apply scene state afterwards.
    if selectedSlot then previewCharacter(charactersBySlot[selectedSlot]) else setDefaultPreviewPed() end
    local ped = PlayerPedId()
    SetEntityCoords(ped, previewLocation.pedCoords.x, previewLocation.pedCoords.y, previewLocation.pedCoords.z, false, false, false, false)
    SetEntityHeading(ped, previewLocation.pedCoords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    DoScreenFadeIn(SVIdentity.preview.fadeInMs)
    showCharacterUi()
end

RegisterNUICallback('ready', function(_, cb)
    if uiPayload then SendNUIMessage(uiPayload) end
    cb({ ok = true })
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    local slot = math.floor(tonumber(type(data) == 'table' and data.slot) or 0)
    if slot < 1 or slot > allowedSlots then cb({ ok = false }); return end

    selectedSlot = slot
    local character = charactersBySlot[slot]
    if character then previewCharacter(character) else setDefaultPreviewPed() end

    if previewLocation then
        local ped = PlayerPedId()
        SetEntityCoords(ped, previewLocation.pedCoords.x, previewLocation.pedCoords.y, previewLocation.pedCoords.z, false, false, false, false)
        SetEntityHeading(ped, previewLocation.pedCoords.w)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
    end

    cb({ ok = true })
end)

RegisterNUICallback('playCharacter', function(data, cb)
    local slot = math.floor(tonumber(type(data) == 'table' and data.slot) or 0)
    local ok, err = loadCharacter(slot)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('openCreate', function(data, cb)
    local slot = math.floor(tonumber(type(data) == 'table' and data.slot) or 0)
    if slot < 1 or slot > allowedSlots or charactersBySlot[slot] then
        cb({ ok = false, error = 'No character slot is available.' })
        return
    end

    showIdentityForm(slot)
    cb({ ok = true })
end)

RegisterNUICallback('cancelCreate', function(_, cb)
    if selectedSlot and charactersBySlot[selectedSlot] then
        previewCharacter(charactersBySlot[selectedSlot])
    else
        local firstOccupied
        for slot = 1, allowedSlots do
            if charactersBySlot[slot] then firstOccupied = slot break end
        end
        selectedSlot = firstOccupied
        previewCharacter(firstOccupied and charactersBySlot[firstOccupied] or nil)
    end

    showCharacterUi()
    cb({ ok = true })
end)

RegisterNUICallback('createCharacter', function(data, cb)
    local ok, err = createCharacter(data)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('deleteCharacter', function(data, cb)
    local slot = math.floor(tonumber(type(data) == 'table' and data.slot) or 0)
    local ok, err = deleteCharacter(slot)
    cb({ ok = ok, error = err })
end)

RegisterNUICallback('chooseSpawn', function(data, cb)
    local index = math.floor(tonumber(type(data) == 'table' and data.id) or 0)
    cb({ ok = finishSpawn(index) })
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end
    cleanupPresentation(false)
    Wait(250)
    startCharacterSelection()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    cleanupPresentation(LocalPlayer.state.isLoggedIn == true)
    if NetworkIsInTutorialSession() then NetworkEndTutorialSession() end
end)

CreateThread(function()
    while true do
        if uiOpen then
            local ped = PlayerPedId()
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            DisplayRadar(false)
            HideHudAndRadarThisFrame()
            DisableAllControlActions(0)
            Wait(0)
        else
            Wait(250)
        end
    end
end)

CreateThread(function()
    while true do
        if NetworkIsInTutorialSession() then
            SetEntityInvincible(PlayerPedId(), true)
            Wait(200)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    if GetResourceState('qbx_core') ~= 'started' then
        while GetResourceState('qbx_core') ~= 'started' do Wait(100) end
    end

    Wait(250)
    startCharacterSelection()
end)

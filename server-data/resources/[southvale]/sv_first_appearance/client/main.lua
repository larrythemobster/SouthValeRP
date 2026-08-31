local RESOURCE = GetCurrentResourceName()

local active = false
local completion
local camera
local baseHeading = 0.0
local baseForward = vector3(0.0, 1.0, 0.0)
local stagePedCoords
local stageCamCoords
local cameraAnchorCoords
local cameraPreset = 'full'
local zoomOffset = 0.0
local selectedGender = 'Male'

local COMPONENTS = {
    { id = 1, key = 'mask', label = 'Masks', camera = 'head' },
    { id = 3, key = 'arms', label = 'Arms', camera = 'torso' },
    { id = 4, key = 'pants', label = 'Pants', camera = 'legs' },
    { id = 5, key = 'bags', label = 'Bags', camera = 'torso' },
    { id = 6, key = 'shoes', label = 'Shoes', camera = 'feet' },
    { id = 7, key = 'chains', label = 'Chains', camera = 'torso' },
    { id = 8, key = 'undershirt', label = 'Undershirts', camera = 'torso' },
    { id = 9, key = 'armour', label = 'Body Armour', camera = 'torso' },
    { id = 10, key = 'decals', label = 'Decals', camera = 'torso' },
    { id = 11, key = 'tops', label = 'Tops & Jackets', camera = 'torso' },
}

local PROPS = {
    { id = 0, key = 'hats', label = 'Hats', camera = 'head' },
    { id = 1, key = 'glasses', label = 'Glasses', camera = 'head' },
    { id = 2, key = 'ears', label = 'Earrings', camera = 'head' },
    { id = 6, key = 'watches', label = 'Watches', camera = 'hands' },
    { id = 7, key = 'bracelets', label = 'Bracelets', camera = 'hands' },
}

local FACE_FEATURES = {
    { key = 'noseWidth', label = 'Nose Width' },
    { key = 'nosePeakHigh', label = 'Nose Height' },
    { key = 'nosePeakSize', label = 'Nose Length' },
    { key = 'noseBoneHigh', label = 'Nose Bridge' },
    { key = 'nosePeakLowering', label = 'Nose Tip' },
    { key = 'noseBoneTwist', label = 'Nose Twist' },
    { key = 'eyeBrownHigh', label = 'Brow Height' },
    { key = 'eyeBrownForward', label = 'Brow Depth' },
    { key = 'cheeksBoneHigh', label = 'Cheekbone Height' },
    { key = 'cheeksBoneWidth', label = 'Cheekbone Width' },
    { key = 'cheeksWidth', label = 'Cheek Width' },
    { key = 'eyesOpening', label = 'Eye Opening' },
    { key = 'lipsThickness', label = 'Lip Fullness' },
    { key = 'jawBoneWidth', label = 'Jaw Width' },
    { key = 'jawBoneBackSize', label = 'Jaw Shape' },
    { key = 'chinBoneLowering', label = 'Chin Height' },
    { key = 'chinBoneLenght', label = 'Chin Length' },
    { key = 'chinBoneSize', label = 'Chin Width' },
    { key = 'chinHole', label = 'Chin Cleft' },
    { key = 'neckThickness', label = 'Neck Thickness' },
}

local OVERLAYS = {
    { id = 0, key = 'blemishes', label = 'Blemishes', color = false },
    { id = 1, key = 'beard', label = 'Facial Hair', color = 'hair' },
    { id = 2, key = 'eyebrows', label = 'Eyebrows', color = 'hair' },
    { id = 3, key = 'ageing', label = 'Ageing', color = false },
    { id = 4, key = 'makeUp', label = 'Makeup', color = 'makeup' },
    { id = 5, key = 'blush', label = 'Blush', color = 'makeup' },
    { id = 6, key = 'complexion', label = 'Complexion', color = false },
    { id = 7, key = 'sunDamage', label = 'Sun Damage', color = false },
    { id = 8, key = 'lipstick', label = 'Lipstick', color = 'makeup' },
    { id = 9, key = 'moleAndFreckles', label = 'Moles & Freckles', color = false },
    { id = 10, key = 'chestHair', label = 'Chest Hair', color = 'hair' },
    { id = 11, key = 'bodyBlemishes', label = 'Body Blemishes', color = false },
}

local EYE_COLORS = {
    'Green', 'Emerald', 'Light Blue', 'Ocean Blue', 'Light Brown', 'Dark Brown', 'Hazel', 'Dark Gray',
    'Light Gray', 'Pink', 'Yellow', 'Purple', 'Blackout', 'Shades of Gray', 'Tequila Sunrise', 'Atomic',
    'Warp', 'ECola', 'Space Ranger', 'Ying Yang', 'Bullseye', 'Lizard', 'Dragon', 'Extra Terrestrial',
    'Goat', 'Smiley', 'Possessed', 'Demon', 'Infected', 'Alien', 'Undead', 'Zombie'
}

-- The character selector's camera coordinate is already a known-clear camera
-- position for the selected preview stage. Keep the scripted camera at that
-- exact XYZ for every editor tab. Moving the camera vertically or toward the
-- ped can place it inside walls, mannequins, racks, ceilings or other interior
-- geometry. Tab changes only alter where the camera aims and its FOV.
local CAMERA_PRESETS = {
    full = { targetZ = 0.83, fov = 36.0 },
    head = { targetZ = 1.58, fov = 21.0 },
    torso = { targetZ = 1.08, fov = 26.0 },
    legs = { targetZ = 0.58, fov = 29.0 },
    feet = { targetZ = 0.18, fov = 27.0 },
    hands = { targetZ = 0.98, fov = 25.0 },
}

local FALLBACK_CAMERA_DISTANCE = 2.35
local FALLBACK_CAMERA_Z = 0.82

local DEFAULT_COMPONENTS = {
    { component_id = 1, drawable = 0, texture = 0 },
    { component_id = 3, drawable = 0, texture = 0 },
    { component_id = 4, drawable = 0, texture = 0 },
    { component_id = 5, drawable = 0, texture = 0 },
    { component_id = 6, drawable = 0, texture = 0 },
    { component_id = 7, drawable = 0, texture = 0 },
    { component_id = 8, drawable = 0, texture = 0 },
    { component_id = 9, drawable = 0, texture = 0 },
    { component_id = 10, drawable = 0, texture = 0 },
    { component_id = 11, drawable = 0, texture = 0 },
}

local DEFAULT_PROPS = {
    { prop_id = 0, drawable = -1, texture = 0 },
    { prop_id = 1, drawable = -1, texture = 0 },
    { prop_id = 2, drawable = -1, texture = 0 },
    { prop_id = 6, drawable = -1, texture = 0 },
    { prop_id = 7, drawable = -1, texture = 0 },
}

local Illenium = exports['illenium-appearance']

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function round(value, places)
    local factor = 10 ^ (places or 0)
    return math.floor((tonumber(value) or 0) * factor + 0.5) / factor
end

local function currentPed()
    return PlayerPedId()
end

local function forcePedVisible(ped)
    if not ped or not DoesEntityExist(ped) then return end
    ResetEntityAlpha(ped)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
end

local function placePedAtStage(ped)
    if not stagePedCoords or not ped or not DoesEntityExist(ped) then return end

    local x = tonumber(stagePedCoords.x)
    local y = tonumber(stagePedCoords.y)
    local z = tonumber(stagePedCoords.z)
    if not x or not y or not z then return end

    RequestCollisionAtCoord(x, y, z)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    if stagePedCoords.w ~= nil then
        SetEntityHeading(ped, tonumber(stagePedCoords.w) or GetEntityHeading(ped))
    end
    forcePedVisible(ped)
end

local function updateBaseCameraDirection(ped)
    if not stageCamCoords or not ped or not DoesEntityExist(ped) then
        baseForward = GetEntityForwardVector(ped)
        return
    end

    local pedPos = GetEntityCoords(ped)
    local dx = (tonumber(stageCamCoords.x) or pedPos.x) - pedPos.x
    local dy = (tonumber(stageCamCoords.y) or pedPos.y) - pedPos.y
    local length = math.sqrt((dx * dx) + (dy * dy))

    if length > 0.05 then
        -- Qbox's paired multichar camera position is already known to have a
        -- clear line of sight to this ped. Reuse that direction instead of
        -- blindly putting the appearance camera in front of the ped, which can
        -- place a wall or pillar between the camera and character.
        baseForward = vector3(dx / length, dy / length, 0.0)
    else
        baseForward = GetEntityForwardVector(ped)
    end
end

local function captureCameraAnchor(ped)
    if stageCamCoords then
        local x = tonumber(stageCamCoords.x)
        local y = tonumber(stageCamCoords.y)
        local z = tonumber(stageCamCoords.z)
        if x and y and z then
            cameraAnchorCoords = vector3(x, y, z)
            return
        end
    end

    local pedPos = GetEntityCoords(ped)
    cameraAnchorCoords = vector3(
        pedPos.x + (baseForward.x * FALLBACK_CAMERA_DISTANCE),
        pedPos.y + (baseForward.y * FALLBACK_CAMERA_DISTANCE),
        pedPos.z + FALLBACK_CAMERA_Z
    )
end

local function normalizeGender(gender)
    if type(gender) == 'string' then
        local normalized = gender:lower()
        return (normalized == 'female' or normalized == 'f' or normalized == '1') and 'Female' or 'Male'
    end

    return tonumber(gender) == 1 and 'Female' or 'Male'
end

local function getPlayerGender(explicitGender)
    if explicitGender ~= nil and tostring(explicitGender) ~= '' then
        return normalizeGender(explicitGender)
    end

    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)

    return normalizeGender(ok and data and data.charinfo and data.charinfo.gender or 0)
end

local function safeNativeCount(callback, fallback)
    local ok, value = pcall(callback)
    value = ok and tonumber(value) or nil
    if not value or value < 1 then return fallback end
    return math.floor(value)
end

local function findComponent(appearance, id)
    for i = 1, #(appearance.components or {}) do
        if appearance.components[i].component_id == id then
            return appearance.components[i]
        end
    end
    return { component_id = id, drawable = 0, texture = 0 }
end

local function findProp(appearance, id)
    for i = 1, #(appearance.props or {}) do
        if appearance.props[i].prop_id == id then
            return appearance.props[i]
        end
    end
    return { prop_id = id, drawable = -1, texture = 0 }
end

local function buildState()
    local ped = currentPed()
    local appearance = Illenium:getPedAppearance(ped)
    local hairColors = safeNativeCount(function() return GetNumHairColors() end, 64)
    local makeupColors = safeNativeCount(function() return GetNumMakeupColors() end, 64)

    local components = {}
    for i = 1, #COMPONENTS do
        local definition = COMPONENTS[i]
        local current = findComponent(appearance, definition.id)
        local drawableCount = math.max(1, GetNumberOfPedDrawableVariations(ped, definition.id))
        local drawable = clamp(current.drawable, 0, drawableCount - 1)
        local textureCount = math.max(1, GetNumberOfPedTextureVariations(ped, definition.id, drawable))
        components[#components + 1] = {
            id = definition.id,
            key = definition.key,
            label = definition.label,
            camera = definition.camera,
            drawable = drawable,
            texture = clamp(current.texture, 0, textureCount - 1),
            maxDrawable = drawableCount - 1,
            maxTexture = textureCount - 1,
        }
    end

    local props = {}
    for i = 1, #PROPS do
        local definition = PROPS[i]
        local current = findProp(appearance, definition.id)
        local drawableCount = math.max(0, GetNumberOfPedPropDrawableVariations(ped, definition.id))
        local drawable = clamp(current.drawable, -1, math.max(-1, drawableCount - 1))
        local textureCount = drawable >= 0 and math.max(1, GetNumberOfPedPropTextureVariations(ped, definition.id, drawable)) or 1
        props[#props + 1] = {
            id = definition.id,
            key = definition.key,
            label = definition.label,
            camera = definition.camera,
            drawable = drawable,
            texture = drawable >= 0 and clamp(current.texture, 0, textureCount - 1) or 0,
            maxDrawable = math.max(-1, drawableCount - 1),
            maxTexture = textureCount - 1,
        }
    end

    local overlays = {}
    for i = 1, #OVERLAYS do
        local definition = OVERLAYS[i]
        local current = (appearance.headOverlays or {})[definition.key] or { style = 0, opacity = 0, color = 0, secondColor = 0 }
        local styleCount = safeNativeCount(function() return GetPedHeadOverlayNum(definition.id) end, 1)
        overlays[#overlays + 1] = {
            id = definition.id,
            key = definition.key,
            label = definition.label,
            colorType = definition.color,
            style = clamp(current.style, 0, styleCount - 1),
            opacity = round(clamp(current.opacity, 0.0, 1.0), 1),
            color = clamp(current.color or 0, 0, (definition.color == 'makeup' and makeupColors or hairColors) - 1),
            secondColor = clamp(current.secondColor or 0, 0, (definition.color == 'makeup' and makeupColors or hairColors) - 1),
            maxStyle = styleCount - 1,
            maxColor = (definition.color == 'makeup' and makeupColors or hairColors) - 1,
        }
    end

    local faceFeatures = {}
    for i = 1, #FACE_FEATURES do
        local definition = FACE_FEATURES[i]
        faceFeatures[#faceFeatures + 1] = {
            key = definition.key,
            label = definition.label,
            value = round((appearance.faceFeatures or {})[definition.key] or 0, 1),
        }
    end

    local headBlend = appearance.headBlend or {}
    local hair = appearance.hair or { style = 0, texture = 0, color = 0, highlight = 0 }
    local hairStyleCount = math.max(1, GetNumberOfPedDrawableVariations(ped, 2))
    local hairStyle = clamp(hair.style, 0, hairStyleCount - 1)
    local hairTextureCount = math.max(1, GetNumberOfPedTextureVariations(ped, 2, hairStyle))

    return {
        gender = selectedGender,
        heritage = {
            shapeFirst = clamp(headBlend.shapeFirst or 0, 0, 45),
            shapeSecond = clamp(headBlend.shapeSecond or 0, 0, 45),
            skinFirst = clamp(headBlend.skinFirst or 0, 0, 45),
            skinSecond = clamp(headBlend.skinSecond or 0, 0, 45),
            shapeMix = round(clamp(headBlend.shapeMix or 0.5, 0.0, 1.0), 2),
            skinMix = round(clamp(headBlend.skinMix or 0.5, 0.0, 1.0), 2),
            maxParent = 45,
        },
        faceFeatures = faceFeatures,
        hair = {
            style = hairStyle,
            texture = clamp(hair.texture, 0, hairTextureCount - 1),
            color = clamp(hair.color, 0, hairColors - 1),
            highlight = clamp(hair.highlight, 0, hairColors - 1),
            maxStyle = hairStyleCount - 1,
            maxTexture = hairTextureCount - 1,
            maxColor = hairColors - 1,
        },
        eyeColor = clamp(appearance.eyeColor or 0, 0, #EYE_COLORS - 1),
        eyeColors = EYE_COLORS,
        overlays = overlays,
        components = components,
        props = props,
    }
end

local function destroyCamera()
    if camera and DoesCamExist(camera) then
        SetCamActive(camera, false)
        DestroyCam(camera, true)
    end
    camera = nil
    RenderScriptCams(false, true, 250, true, true)
end

local function updateCamera()
    if not active then return end
    local ped = currentPed()
    if not DoesEntityExist(ped) then return end
    forcePedVisible(ped)

    local preset = CAMERA_PRESETS[cameraPreset] or CAMERA_PRESETS.full
    if not cameraAnchorCoords then
        captureCameraAnchor(ped)
    end

    local pedPos = GetEntityCoords(ped)
    local targetPos = vector3(pedPos.x, pedPos.y, pedPos.z + preset.targetZ)
    local fov = clamp(preset.fov + zoomOffset, 14.0, 50.0)

    if not camera or not DoesCamExist(camera) then
        camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamActive(camera, true)
        RenderScriptCams(true, true, 250, true, true)
    end

    -- Deliberately never move this XYZ after opening the editor. The selector
    -- already proved this point has a clear view of the preview ped.
    SetCamCoord(camera, cameraAnchorCoords.x, cameraAnchorCoords.y, cameraAnchorCoords.z)
    PointCamAtCoord(camera, targetPos.x, targetPos.y, targetPos.z)
    SetCamFov(camera, fov)
end

local function setCameraPreset(name)
    if CAMERA_PRESETS[name] then
        cameraPreset = name
        zoomOffset = 0.0
        updateCamera()
    end
end

local function cleanup(resolveValue)
    if not active then return end
    active = false

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'hide' })
    destroyCamera()

    local ped = currentPed()
    if DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        SetEntityHeading(ped, baseHeading)
    end

    DisplayRadar(false)
    TriggerServerEvent('illenium-appearance:server:ResetRoutingBucket')
    stagePedCoords = nil
    stageCamCoords = nil
    cameraAnchorCoords = nil

    if completion then
        completion:resolve(resolveValue == true)
        completion = nil
    end
end

local function initialisePed()
    local gender = selectedGender
    local model = gender == 'Female' and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    Illenium:setPlayerModel(model)
    Wait(150)

    local ped = currentPed()
    placePedAtStage(ped)
    forcePedVisible(ped)
    SetPedDefaultComponentVariation(ped)
    Illenium:setPedComponents(ped, DEFAULT_COMPONENTS)
    Illenium:setPedProps(ped, DEFAULT_PROPS)
    Illenium:setPedHair(ped, { style = 0, texture = 0, color = 0, highlight = 0 }, {})
    Illenium:setPedTattoos(ped, {})

    return ped
end

local function openFirstAppearance(options)
    if active then return false end
    if GetResourceState('illenium-appearance') ~= 'started' then return false end

    if type(options) ~= 'table' then
        options = { gender = options }
    end

    active = true
    selectedGender = getPlayerGender(options.gender)
    stagePedCoords = options.pedCoords or options.ped
    stageCamCoords = options.camCoords or options.camera
    completion = promise.new()
    TriggerServerEvent('illenium-appearance:server:ChangeRoutingBucket')

    local ped = initialisePed()
    placePedAtStage(ped)
    forcePedVisible(ped)
    baseHeading = GetEntityHeading(ped)
    updateBaseCameraDirection(ped)
    captureCameraAnchor(ped)
    cameraPreset = 'full'
    zoomOffset = 0.0

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, true, false)
    ClearPedTasksImmediately(ped)
    DisplayRadar(false)

    if IsScreenFadedOut() then
        DoScreenFadeIn(250)
        local expires = GetGameTimer() + 1500
        while not IsScreenFadedIn() and GetGameTimer() < expires do Wait(0) end
    end

    updateCamera()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = 'open',
        brand = 'SOUTHVALE',
        suffix = 'ROLEPLAY',
        state = buildState(),
    })

    return Citizen.Await(completion)
end

exports('openFirstAppearance', openFirstAppearance)

RegisterNUICallback('setComponent', function(data, cb)
    if not active then cb({ ok = false }); return end

    local ped = currentPed()
    local id = math.floor(tonumber(data.id) or -1)
    local drawableCount = math.max(1, GetNumberOfPedDrawableVariations(ped, id))
    local drawable = math.floor(clamp(data.drawable, 0, drawableCount - 1))
    local textureCount = math.max(1, GetNumberOfPedTextureVariations(ped, id, drawable))
    local texture = math.floor(clamp(data.texture, 0, textureCount - 1))

    Illenium:setPedComponent(ped, { component_id = id, drawable = drawable, texture = texture })
    cb({ ok = true, drawable = drawable, texture = texture, maxDrawable = drawableCount - 1, maxTexture = textureCount - 1 })
end)

RegisterNUICallback('setProp', function(data, cb)
    if not active then cb({ ok = false }); return end

    local ped = currentPed()
    local id = math.floor(tonumber(data.id) or -1)
    local drawableCount = math.max(0, GetNumberOfPedPropDrawableVariations(ped, id))
    local drawable = math.floor(clamp(data.drawable, -1, math.max(-1, drawableCount - 1)))
    local texture = 0
    local textureCount = 1

    if drawable >= 0 then
        textureCount = math.max(1, GetNumberOfPedPropTextureVariations(ped, id, drawable))
        texture = math.floor(clamp(data.texture, 0, textureCount - 1))
    end

    Illenium:setPedProp(ped, { prop_id = id, drawable = drawable, texture = texture })
    cb({ ok = true, drawable = drawable, texture = texture, maxDrawable = math.max(-1, drawableCount - 1), maxTexture = textureCount - 1 })
end)

RegisterNUICallback('setHair', function(data, cb)
    if not active then cb({ ok = false }); return end

    local ped = currentPed()
    local current = Illenium:getPedAppearance(ped).hair or {}
    local hairColors = safeNativeCount(function() return GetNumHairColors() end, 64)
    local styleCount = math.max(1, GetNumberOfPedDrawableVariations(ped, 2))
    local style = math.floor(clamp(data.style ~= nil and data.style or current.style, 0, styleCount - 1))
    local textureCount = math.max(1, GetNumberOfPedTextureVariations(ped, 2, style))
    local hair = {
        style = style,
        texture = math.floor(clamp(data.texture ~= nil and data.texture or current.texture, 0, textureCount - 1)),
        color = math.floor(clamp(data.color ~= nil and data.color or current.color, 0, hairColors - 1)),
        highlight = math.floor(clamp(data.highlight ~= nil and data.highlight or current.highlight, 0, hairColors - 1)),
    }

    Illenium:setPedHair(ped, hair, {})
    cb({ ok = true, hair = hair, maxStyle = styleCount - 1, maxTexture = textureCount - 1, maxColor = hairColors - 1 })
end)

RegisterNUICallback('setEyeColor', function(data, cb)
    if not active then cb({ ok = false }); return end
    local value = math.floor(clamp(data.value, 0, #EYE_COLORS - 1))
    Illenium:setPedEyeColor(currentPed(), value)
    cb({ ok = true, value = value })
end)

RegisterNUICallback('setHeritage', function(data, cb)
    if not active then cb({ ok = false }); return end

    local ped = currentPed()
    local appearance = Illenium:getPedAppearance(ped)
    local headBlend = appearance.headBlend or {}
    local update = data.values or {}

    headBlend.shapeFirst = math.floor(clamp(update.shapeFirst ~= nil and update.shapeFirst or headBlend.shapeFirst, 0, 45))
    headBlend.shapeSecond = math.floor(clamp(update.shapeSecond ~= nil and update.shapeSecond or headBlend.shapeSecond, 0, 45))
    headBlend.skinFirst = math.floor(clamp(update.skinFirst ~= nil and update.skinFirst or headBlend.skinFirst, 0, 45))
    headBlend.skinSecond = math.floor(clamp(update.skinSecond ~= nil and update.skinSecond or headBlend.skinSecond, 0, 45))
    headBlend.shapeThird = headBlend.shapeThird or 0
    headBlend.skinThird = headBlend.skinThird or 0
    headBlend.shapeMix = clamp(update.shapeMix ~= nil and update.shapeMix or headBlend.shapeMix, 0.0, 1.0)
    headBlend.skinMix = clamp(update.skinMix ~= nil and update.skinMix or headBlend.skinMix, 0.0, 1.0)
    headBlend.thirdMix = headBlend.thirdMix or 0.0

    Illenium:setPedHeadBlend(ped, headBlend)
    cb({ ok = true, values = headBlend })
end)

RegisterNUICallback('setFaceFeature', function(data, cb)
    if not active then cb({ ok = false }); return end

    local ped = currentPed()
    local appearance = Illenium:getPedAppearance(ped)
    local key = tostring(data.key or '')
    local valid = false
    for i = 1, #FACE_FEATURES do
        if FACE_FEATURES[i].key == key then valid = true; break end
    end
    if not valid then cb({ ok = false }); return end

    appearance.faceFeatures[key] = round(clamp(data.value, -1.0, 1.0), 1)
    Illenium:setPedFaceFeatures(ped, appearance.faceFeatures)
    cb({ ok = true, value = appearance.faceFeatures[key] })
end)

RegisterNUICallback('setOverlay', function(data, cb)
    if not active then cb({ ok = false }); return end

    local ped = currentPed()
    local appearance = Illenium:getPedAppearance(ped)
    local key = tostring(data.key or '')
    local definition
    for i = 1, #OVERLAYS do
        if OVERLAYS[i].key == key then definition = OVERLAYS[i]; break end
    end
    if not definition then cb({ ok = false }); return end

    local overlay = appearance.headOverlays[key] or { style = 0, opacity = 0, color = 0, secondColor = 0 }
    local styleCount = safeNativeCount(function() return GetPedHeadOverlayNum(definition.id) end, 1)
    local hairColors = safeNativeCount(function() return GetNumHairColors() end, 64)
    local makeupColors = safeNativeCount(function() return GetNumMakeupColors() end, 64)
    local colorMax = (definition.color == 'makeup' and makeupColors or hairColors) - 1

    overlay.style = math.floor(clamp(data.style ~= nil and data.style or overlay.style, 0, styleCount - 1))
    overlay.opacity = round(clamp(data.opacity ~= nil and data.opacity or overlay.opacity, 0.0, 1.0), 1)
    overlay.color = math.floor(clamp(data.color ~= nil and data.color or overlay.color or 0, 0, colorMax))
    overlay.secondColor = math.floor(clamp(data.secondColor ~= nil and data.secondColor or overlay.secondColor or 0, 0, colorMax))
    appearance.headOverlays[key] = overlay

    Illenium:setPedHeadOverlays(ped, appearance.headOverlays)
    cb({ ok = true, overlay = overlay, maxStyle = styleCount - 1, maxColor = colorMax })
end)

RegisterNUICallback('cameraPreset', function(data, cb)
    if active then setCameraPreset(tostring(data.preset or 'full')) end
    cb({ ok = true })
end)

RegisterNUICallback('cameraControl', function(data, cb)
    if not active then cb({ ok = false }); return end

    local ped = currentPed()
    local action = tostring(data.action or '')
    if action == 'left' then
        SetEntityHeading(ped, GetEntityHeading(ped) + 12.5)
    elseif action == 'right' then
        SetEntityHeading(ped, GetEntityHeading(ped) - 12.5)
    elseif action == 'front' then
        SetEntityHeading(ped, baseHeading)
    elseif action == 'zoomIn' then
        -- Zoom with FOV only. Never move the camera into nearby geometry.
        zoomOffset = math.max(-8.0, zoomOffset - 2.0)
        updateCamera()
    elseif action == 'zoomOut' then
        zoomOffset = math.min(12.0, zoomOffset + 2.0)
        updateCamera()
    end
    cb({ ok = true })
end)

RegisterNUICallback('resetAppearance', function(_, cb)
    if not active then cb({ ok = false }); return end
    local ped = initialisePed()
    placePedAtStage(ped)
    forcePedVisible(ped)
    baseHeading = GetEntityHeading(ped)
    updateBaseCameraDirection(ped)
    captureCameraAnchor(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    cameraPreset = 'full'
    zoomOffset = 0.0
    updateCamera()
    cb({ ok = true, state = buildState() })
end)

RegisterNUICallback('saveAppearance', function(_, cb)
    if not active then cb({ ok = false }); return end

    local appearance = Illenium:getPedAppearance(currentPed())
    if not appearance then
        cb({ ok = false, error = 'Unable to read your appearance.' })
        return
    end

    TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
    cb({ ok = true })
    Wait(250)
    cleanup(true)
end)

RegisterNUICallback('ready', function(_, cb)
    cb({ ok = true })
end)

-- Model swaps and the preceding character-selector scene can both replace or
-- hide the local ped. Keep the editor ped renderable for the duration of the
-- customization session without touching its chosen components.
CreateThread(function()
    while true do
        if active then
            local ped = currentPed()
            forcePedVisible(ped)
            Wait(200)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE then return end
    if active then cleanup(false) end
end)

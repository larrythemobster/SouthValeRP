local client = client

RegisterNUICallback("appearance_get_locales", function(_, cb)
    cb(Locales[GetConvar("illenium-appearance:locale", "en")].UI)
end)

RegisterNUICallback("appearance_get_settings", function(_, cb)
    cb({ appearanceSettings = client.getAppearanceSettings() })
end)

RegisterNUICallback("appearance_get_data", function(_, cb)
    Wait(250)
    local appearanceData = client.getAppearance()
    if appearanceData.tattoos then
        client.setPedTattoos(cache.ped, appearanceData.tattoos)
    end
    cb({ config = client.getConfig(), appearanceData = appearanceData })
end)

RegisterNUICallback("appearance_set_camera", function(camera, cb)
    cb(1)
    client.setCamera(camera)
end)

RegisterNUICallback("appearance_turn_around", function(_, cb)
    cb(1)
    client.pedTurn(cache.ped, 180.0)
end)

RegisterNUICallback("appearance_rotate_camera", function(direction, cb)
    cb(1)
    client.rotateCamera(direction)
end)

RegisterNUICallback("appearance_change_model", function(model, cb)
    local playerPed = client.setPlayerModel(model)

    SetEntityHeading(cache.ped, client.getHeading())
    SetEntityInvincible(playerPed, true)
    TaskStandStill(playerPed, -1)

    cb({
        appearanceSettings = client.getAppearanceSettings(),
        appearanceData = client.getPedAppearance(playerPed)
    })
end)

RegisterNUICallback("appearance_change_component", function(component, cb)
    client.setPedComponent(cache.ped, component)
    cb(client.getComponentSettings(cache.ped, component.component_id))
end)

RegisterNUICallback("appearance_change_prop", function(prop, cb)
    client.setPedProp(cache.ped, prop)
    cb(client.getPropSettings(cache.ped, prop.prop_id))
end)

RegisterNUICallback("appearance_change_head_blend", function(headBlend, cb)
    cb(1)
    client.setPedHeadBlend(cache.ped, headBlend)
end)

RegisterNUICallback("appearance_change_face_feature", function(faceFeatures, cb)
    cb(1)
    client.setPedFaceFeatures(cache.ped, faceFeatures)
end)

RegisterNUICallback("appearance_change_head_overlay", function(headOverlays, cb)
    cb(1)
    client.setPedHeadOverlays(cache.ped, headOverlays)
end)

RegisterNUICallback("appearance_change_hair", function(hair, cb)
    client.setPedHair(cache.ped, hair)
    cb(client.getHairSettings(cache.ped))
end)

RegisterNUICallback("appearance_change_eye_color", function(eyeColor, cb)
    cb(1)
    client.setPedEyeColor(cache.ped, eyeColor)
end)

RegisterNUICallback("appearance_apply_tattoo", function(data, cb)
    local paid = not data.tattoo or not Config.ChargePerTattoo or lib.callback.await("illenium-appearance:server:payForTattoo", false, data.tattoo)
    if paid then
        client.addPedTattoo(cache.ped, data.updatedTattoos or data)
    end
    cb(paid)
end)

RegisterNUICallback("appearance_preview_tattoo", function(previewTattoo, cb)
    cb(1)
    client.setPreviewTattoo(cache.ped, previewTattoo.data, previewTattoo.tattoo)
end)

RegisterNUICallback("appearance_delete_tattoo", function(data, cb)
    cb(1)
    client.removePedTattoo(cache.ped, data)
end)

RegisterNUICallback("appearance_wear_clothes", function(dataWearClothes, cb)
    cb(1)
    client.wearClothes(dataWearClothes.data, dataWearClothes.key)
end)

RegisterNUICallback("appearance_remove_clothes", function(clothes, cb)
    cb(1)
    client.removeClothes(clothes)
end)

RegisterNUICallback("appearance_save", function(appearance, cb)
    cb(1)
    client.wearClothes(appearance, "head")
    client.wearClothes(appearance, "body")
    client.wearClothes(appearance, "bottom")
    client.exitPlayerCustomization(appearance)
end)

RegisterNUICallback("appearance_exit", function(_, cb)
    cb(1)
    client.exitPlayerCustomization()
end)

RegisterNUICallback("rotate_left", function(_, cb)
    cb(1)
    client.pedTurn(cache.ped, 10.0)
end)

RegisterNUICallback("rotate_right", function(_, cb)
    cb(1)
    client.pedTurn(cache.ped, -10.0)
end)

RegisterNUICallback("get_theme_configuration", function(_, cb)
    cb(Config.Theme)
end)

-- SouthVale clothing browser helpers.
-- These callbacks let the NUI describe and live-preview the neighbouring clothing
-- choices before the player commits to them.
local SOUTHVALE_COMPONENT_LABELS = {
    [0] = "Head",
    [1] = "Mask",
    [3] = "Hands",
    [4] = "Legs",
    [5] = "Bag",
    [6] = "Shoes",
    [7] = "Accessory",
    [8] = "Shirt",
    [9] = "Body armor",
    [10] = "Decal",
    [11] = "Jacket"
}

local SOUTHVALE_PROP_LABELS = {
    [0] = "Hat / helmet",
    [1] = "Glasses",
    [2] = "Ear accessory",
    [6] = "Watch",
    [7] = "Bracelet"
}

local function southvaleClamp(value, minValue, maxValue)
    if maxValue < minValue then
        return minValue
    end

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function southvaleWrap(value, minValue, maxValue)
    if maxValue < minValue then
        return minValue
    end

    if value < minValue then
        return maxValue
    end

    if value > maxValue then
        return minValue
    end

    return value
end

local function southvaleCleanCollectionName(name)
    if not name or name == "" then
        return "Base game"
    end

    local cleaned = name
        :gsub("^mp_[mf]_freemode_01_", "")
        :gsub("^mp_[mf]_", "")
        :gsub("_freemode_", " ")
        :gsub("_", " ")
        :gsub("%s+", " ")

    cleaned = cleaned:gsub("^%l", string.upper)
    return cleaned
end

local function southvaleShopLabel(ped, kind, slotId, drawable, texture)
    if drawable < 0 then
        return "None"
    end

    local hash
    local hashOk = pcall(function()
        if kind == "prop" then
            hash = GetHashNameForProp(ped, slotId, drawable, texture)
        else
            hash = GetHashNameForComponent(ped, slotId, drawable, texture)
        end
    end)

    if not hashOk or not hash or hash == 0 then
        return nil
    end

    local blob = string.rep("\0", 200)
    local nativeHash = kind == "prop" and 0x5D5CAFF661DDF6FC or 0x74C0E2A57EC66760
    local invokeOk, found = pcall(function()
        return Citizen.InvokeNative(nativeHash, hash, blob, Citizen.ReturnResultAnyway())
    end)

    if not invokeOk or found == false then
        return nil
    end

    local unpackOk, gxt = pcall(string.unpack, "z", blob, 73)
    if not unpackOk or not gxt or gxt == "" then
        return nil
    end

    local labelOk, label = pcall(GetLabelText, gxt)
    if not labelOk or not label or label == "" or label == "NULL" then
        return nil
    end

    return label
end

local function southvaleCollectionLabel(ped, kind, slotId, drawable)
    if drawable < 0 then
        return "None"
    end

    local collectionName
    local localIndex

    local ok = pcall(function()
        if kind == "prop" then
            collectionName = GetPedPropCollectionName(ped, slotId, drawable)
            localIndex = GetPedPropCollectionLocalIndex(ped, slotId, drawable)
        else
            collectionName = GetPedDrawableCollectionName(ped, slotId, drawable)
            localIndex = GetPedDrawableCollectionLocalIndex(ped, slotId, drawable)
        end
    end)

    if not ok then
        return nil
    end

    if type(localIndex) ~= "number" or localIndex < 0 then
        localIndex = drawable
    end

    return ("%s #%d"):format(southvaleCleanCollectionName(collectionName), localIndex)
end

local function southvaleThumbnail(kind, slotId, drawable, texture)
    if drawable < 0 or GetResourceState("uz_AutoShot") ~= "started" then
        return nil
    end

    local gender = client.getPedDecorationType()
    local ok, url = pcall(function()
        return exports["uz_AutoShot"]:getPhotoURL(gender, kind, slotId, drawable, texture)
    end)

    if ok and type(url) == "string" and url ~= "" then
        return url
    end

    return nil
end

local function southvaleGetTextureRange(ped, kind, slotId, drawable)
    if drawable < 0 then
        return -1, -1
    end

    local count
    if kind == "prop" then
        count = GetNumberOfPedPropTextureVariations(ped, slotId, drawable)
    else
        count = GetNumberOfPedTextureVariations(ped, slotId, drawable)
    end

    local minTexture = kind == "prop" and -1 or 0
    local maxTexture = math.max(minTexture, (count or 0) - 1)
    return minTexture, maxTexture
end

local function southvaleDescribeClothing(ped, kind, slotId, drawable, texture)
    if drawable < 0 then
        return {
            drawable = -1,
            texture = -1,
            label = "None",
            collection = "None",
            thumbnail = nil
        }
    end

    local textureMin, textureMax = southvaleGetTextureRange(ped, kind, slotId, drawable)
    texture = southvaleClamp(texture or textureMin, textureMin, textureMax)

    local collectionLabel = southvaleCollectionLabel(ped, kind, slotId, drawable)
    local label = southvaleShopLabel(ped, kind, slotId, drawable, texture)

    if not label then
        label = collectionLabel
    end

    if not label then
        local category = kind == "prop" and SOUTHVALE_PROP_LABELS[slotId] or SOUTHVALE_COMPONENT_LABELS[slotId]
        label = ("%s #%d"):format(category or "Item", drawable)
    end

    return {
        drawable = drawable,
        texture = texture,
        textureMin = textureMin,
        textureMax = textureMax,
        label = label,
        collection = collectionLabel,
        thumbnail = southvaleThumbnail(kind, slotId, drawable, texture)
    }
end

local function southvaleApplyClothing(ped, kind, slotId, drawable, texture)
    if kind == "prop" then
        if drawable < 0 then
            ClearPedProp(ped, slotId)
            return -1
        end

        local textureMin, textureMax = southvaleGetTextureRange(ped, kind, slotId, drawable)
        texture = southvaleClamp(texture or textureMin, textureMin, textureMax)
        SetPedPropIndex(ped, slotId, drawable, texture, true)
        return texture
    end

    local textureMin, textureMax = southvaleGetTextureRange(ped, kind, slotId, drawable)
    texture = southvaleClamp(texture or textureMin, textureMin, textureMax)
    SetPedComponentVariation(ped, slotId, drawable, texture, 0)
    return texture
end

RegisterNUICallback("appearance_get_clothing_browser", function(data, cb)
    local ped = cache.ped
    local kind = data.kind == "prop" and "prop" or "component"
    local slotId = tonumber(data.id) or 0

    local drawableMin = kind == "prop" and -1 or 0
    local drawableMax
    if kind == "prop" then
        drawableMax = GetNumberOfPedPropDrawableVariations(ped, slotId) - 1
    else
        drawableMax = GetNumberOfPedDrawableVariations(ped, slotId) - 1
    end

    drawableMax = math.max(drawableMin, drawableMax)

    local currentDrawable = southvaleClamp(tonumber(data.drawable) or drawableMin, drawableMin, drawableMax)
    local currentTexture = tonumber(data.texture) or (kind == "prop" and -1 or 0)
    local previousDrawable = southvaleWrap(currentDrawable - 1, drawableMin, drawableMax)
    local nextDrawable = southvaleWrap(currentDrawable + 1, drawableMin, drawableMax)

    cb({
        previous = southvaleDescribeClothing(ped, kind, slotId, previousDrawable, currentTexture),
        current = southvaleDescribeClothing(ped, kind, slotId, currentDrawable, currentTexture),
        next = southvaleDescribeClothing(ped, kind, slotId, nextDrawable, currentTexture),
        drawableMin = drawableMin,
        drawableMax = drawableMax
    })
end)


RegisterNUICallback("appearance_get_clothing_page", function(data, cb)
    local ped = cache.ped
    local kind = data.kind == "prop" and "prop" or "component"
    local slotId = tonumber(data.id) or 0
    local pageSize = math.floor(tonumber(data.count) or 12)
    pageSize = southvaleClamp(pageSize, 1, 24)

    local drawableMin = kind == "prop" and -1 or 0
    local drawableMax
    if kind == "prop" then
        drawableMax = GetNumberOfPedPropDrawableVariations(ped, slotId) - 1
    else
        drawableMax = GetNumberOfPedDrawableVariations(ped, slotId) - 1
    end
    drawableMax = math.max(drawableMin, drawableMax)

    local startDrawable = math.floor(tonumber(data.start) or drawableMin)
    startDrawable = southvaleClamp(startDrawable, drawableMin, drawableMax)

    local selectedDrawable = tonumber(data.selectedDrawable)
    local selectedTexture = tonumber(data.selectedTexture)
    local items = {}
    local lastDrawable = math.min(drawableMax, startDrawable + pageSize - 1)

    for drawable = startDrawable, lastDrawable do
        local texture = 0
        if kind == "prop" then
            texture = 0
        end
        if selectedDrawable ~= nil and drawable == selectedDrawable and selectedTexture ~= nil then
            texture = selectedTexture
        end

        items[#items + 1] = southvaleDescribeClothing(ped, kind, slotId, drawable, texture)
    end

    cb({
        items = items,
        start = startDrawable,
        ["end"] = lastDrawable,
        drawableMin = drawableMin,
        drawableMax = drawableMax
    })
end)

RegisterNUICallback("appearance_preview_clothing_step", function(data, cb)
    local ped = cache.ped
    local kind = data.kind == "prop" and "prop" or "component"
    local slotId = tonumber(data.id) or 0
    local axis = data.axis == "texture" and "texture" or "drawable"
    local direction = tonumber(data.direction) or 1
    direction = direction < 0 and -1 or 1

    local drawable = tonumber(data.drawable) or (kind == "prop" and -1 or 0)
    local texture = tonumber(data.texture) or (kind == "prop" and -1 or 0)

    if axis == "drawable" then
        local minDrawable = kind == "prop" and -1 or 0
        local maxDrawable = kind == "prop"
            and GetNumberOfPedPropDrawableVariations(ped, slotId) - 1
            or GetNumberOfPedDrawableVariations(ped, slotId) - 1

        maxDrawable = math.max(minDrawable, maxDrawable)
        drawable = southvaleWrap(drawable + direction, minDrawable, maxDrawable)
    else
        local minTexture, maxTexture = southvaleGetTextureRange(ped, kind, slotId, drawable)
        texture = southvaleWrap(texture + direction, minTexture, maxTexture)
    end

    texture = southvaleApplyClothing(ped, kind, slotId, drawable, texture)
    cb(southvaleDescribeClothing(ped, kind, slotId, drawable, texture))
end)

RegisterNUICallback("appearance_preview_clothing", function(data, cb)
    local ped = cache.ped
    local kind = data.kind == "prop" and "prop" or "component"
    local slotId = tonumber(data.id) or 0
    local drawable = tonumber(data.drawable) or (kind == "prop" and -1 or 0)
    local texture = tonumber(data.texture) or (kind == "prop" and -1 or 0)

    texture = southvaleApplyClothing(ped, kind, slotId, drawable, texture)
    cb(southvaleDescribeClothing(ped, kind, slotId, drawable, texture))
end)

RegisterNUICallback("appearance_restore_clothing", function(data, cb)
    local ped = cache.ped
    local kind = data.kind == "prop" and "prop" or "component"
    local slotId = tonumber(data.id) or 0
    local drawable = tonumber(data.drawable) or (kind == "prop" and -1 or 0)
    local texture = tonumber(data.texture) or (kind == "prop" and -1 or 0)

    southvaleApplyClothing(ped, kind, slotId, drawable, texture)
    cb(1)
end)

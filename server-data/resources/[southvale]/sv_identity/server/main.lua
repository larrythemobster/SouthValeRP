local RESOURCE_VERSION = '1.2.0'
local RESOURCE_NAME = GetCurrentResourceName()

local function selectorScriptStillLoaded()
    local manifest = LoadResourceFile('qbx_core', 'fxmanifest.lua')
    return type(manifest) == 'string' and manifest:find("'client/character.lua'", 1, true) ~= nil
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= RESOURCE_NAME then return end

    print(('[sv_identity] server v%s started - SouthVale character selector is ACTIVE'):format(RESOURCE_VERSION))

    if selectorScriptStillLoaded() then
        print('^1[sv_identity] FATAL CONFIG WARNING: qbx_core/fxmanifest.lua still loads client/character.lua. The stock Qbox selector can still run. Apply the SouthVale v1.2 patch to the qbx_core copy FXServer actually starts.^7')
    else
        print('^2[sv_identity] Verified: qbx_core stock character.lua is not in the client script manifest.^7')
    end
end)

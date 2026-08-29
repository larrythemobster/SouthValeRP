-- Visual Settings Runtime Injector for Bright Emergency Lights
local settings = {
    ['car.defaultlight.day.emissiveIntensity'] = 3000.0,
    ['car.defaultlight.night.emissiveIntensity'] = 1500.0,
    ['car.headlight.day.emissiveIntensity'] = 80.0,
    ['car.headlight.night.emissiveIntensity'] = 180.0,
    ['car.taillight.day.emissiveIntensity'] = 80.0,
    ['car.taillight.night.emissiveIntensity'] = 180.0,
    ['car.brakelight.day.emissiveIntensity'] = 120.0,
    ['car.brakelight.night.emissiveIntensity'] = 240.0,
    ['car.indicator.day.emissiveIntensity'] = 350.0,
    ['car.indicator.night.emissiveIntensity'] = 250.0,
    ['car.reversinglight.day.emissiveIntensity'] = 150.0,
    ['car.reversinglight.night.emissiveIntensity'] = 250.0,
    ['car.coronas.day.intensity'] = 8.0,
    ['car.coronas.night.intensity'] = 12.0,
    ['car.coronas.size'] = 1.2,
    ['car.coronas.day.size'] = 1.2,
    ['car.coronas.night.size'] = 1.5,
    ['car.coronas.day.emissiveIntensity'] = 150.0,
    ['car.coronas.night.emissiveIntensity'] = 250.0,
    ['misc.coronas.sizeScaleGlobal'] = 1.15,
    ['misc.coronas.intensityScaleGlobal'] = 1.25,
}

local function applyVisualSettings()
    for name, val in pairs(settings) do
        SetVisualSettingFloat(name, val)
    end
end

CreateThread(function()
    applyVisualSettings()
    Wait(2500)
    applyVisualSettings()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    applyVisualSettings()
end)

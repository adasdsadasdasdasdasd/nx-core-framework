-- ============================================================
--  NX-Core — Hora e Meteorologia (Client)
--  Aplica hora e meteorologia sincronizadas pelo servidor.
-- ============================================================

local currentHour    = 10
local currentMinute  = 0
local currentWeather = 'EXTRASUNNY'
local timeFrozen     = false

-- -----------------------------------------------
--  Recebe sincronizacao de hora do servidor
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:SyncTime', function(hour, minute, second, frozen)
    currentHour   = hour
    currentMinute = minute
    timeFrozen    = frozen

    NetworkOverrideClockTime(hour, minute, second or 0)
    NXCore.Debug('info', '[Time] Hora sincronizada: %02d:%02d frozen=%s', hour, minute, tostring(frozen))
end)

-- -----------------------------------------------
--  Recebe sincronizacao de meteorologia
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:SyncWeather', function(weather)
    currentWeather = weather

    -- Transicao suave de meteorologia
    SetWeatherTypeOvertimePersist(weather, 10.0)
    NXCore.Debug('info', '[Weather] Meteorologia sincronizada: %s', weather)
end)

-- -----------------------------------------------
--  Loop: mantem hora correta (previne override por scripts)
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(30000)  -- re-aplica a cada 30s

        if timeFrozen then
            NetworkOverrideClockTime(currentHour, currentMinute, 0)
        end

        -- Previne que outros scripts mudem a meteorologia
        local active, nextWeather = GetCurrentWeatherState()
        if active ~= GetHashKey(currentWeather) then
            SetWeatherTypeOvertimePersist(currentWeather, 5.0)
        end
    end
end)

-- -----------------------------------------------
--  Exports client-side
-- -----------------------------------------------
exports('GetCurrentTime',    function() return currentHour, currentMinute end)
exports('GetCurrentWeather', function() return currentWeather end)

NXCore.Debug('info', 'Client Time carregado.')
-- ============================================================
--  NX-Core — Hora e Meteorologia Sincronizada (Server)
--  Hora controlada pelo servidor, igual para todos os jogadores.
-- ============================================================

local serverHour    = Config.Time and Config.Time.StartHour    or 10
local serverMinute  = Config.Time and Config.Time.StartMinute  or 0
local serverSecond  = 0
local serverWeather = Config.Time and Config.Time.DefaultWeather or 'EXTRASUNNY'
local timeRatio     = Config.Time and Config.Time.Ratio         or 2  -- 2x velocidade real
local frozen        = Config.Time and Config.Time.Frozen        or false

-- -----------------------------------------------
--  Lista de meteorologias disponiveis
-- -----------------------------------------------
local WEATHERS = {
    'EXTRASUNNY', 'CLEAR', 'CLOUDS', 'OVERCAST',
    'RAIN', 'CLEARING', 'THUNDER', 'SMOG', 'FOGGY',
    'XMAS', 'SNOWLIGHT', 'BLIZZARD', 'NEUTRAL',
}

local function isValidWeather(w)
    for _, v in ipairs(WEATHERS) do
        if v == w:upper() then return true end
    end
    return false
end

-- -----------------------------------------------
--  Sincroniza hora e meteorologia a todos os jogadores
-- -----------------------------------------------
local function syncAll()
    TriggerClientEvent('nx-core:client:SyncTime', -1, serverHour, serverMinute, serverSecond, frozen)
    TriggerClientEvent('nx-core:client:SyncWeather', -1, serverWeather)
end

-- -----------------------------------------------
--  Loop: avanca o tempo do servidor
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(60000 / timeRatio)  -- 1 minuto de jogo em (60s / ratio) segundos reais

        if not frozen then
            serverMinute = serverMinute + 1
            if serverMinute >= 60 then
                serverMinute = 0
                serverHour   = serverHour + 1
                if serverHour >= 24 then
                    serverHour = 0
                end
            end

            -- Sincroniza a cada minuto de jogo
            TriggerClientEvent('nx-core:client:SyncTime', -1, serverHour, serverMinute, serverSecond, frozen)
            NXCore.Debug('info', '[Time] %02d:%02d', serverHour, serverMinute)
        end
    end
end)

-- -----------------------------------------------
--  Sincroniza hora ao jogador conectar
-- -----------------------------------------------
AddEventHandler('nx-core:server:onPlayerLoaded', function(src)
    TriggerClientEvent('nx-core:client:SyncTime', src, serverHour, serverMinute, serverSecond, frozen)
    TriggerClientEvent('nx-core:client:SyncWeather', src, serverWeather)
end)

-- -----------------------------------------------
--  Comandos de staff para controlo de tempo
-- -----------------------------------------------
RegisterCommand('settime', function(src, args)
    if src ~= 0 and not NXCore.HasPermission(src, 'admin') then
        TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, NXCore.L('no_permission'), 'error')
        return
    end

    local hour   = tonumber(args[1])
    local minute = tonumber(args[2]) or 0

    if not hour or hour < 0 or hour > 23 then
        if src == 0 then print('[NX-Core] Uso: /settime <hora 0-23> [minuto]')
        else TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, 'Uso: /settime <hora 0-23> [minuto]', 'error') end
        return
    end

    serverHour   = hour
    serverMinute = minute
    syncAll()

    local msg = ('Hora definida para %02d:%02d'):format(serverHour, serverMinute)
    if src == 0 then print('[NX-Core] ' .. msg)
    else TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, msg, 'success') end
    NXCore.Debug('info', '/settime — %02d:%02d por src=%s', serverHour, serverMinute, tostring(src))
end, false)

RegisterCommand('setweather', function(src, args)
    if src ~= 0 and not NXCore.HasPermission(src, 'admin') then
        TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, NXCore.L('no_permission'), 'error')
        return
    end

    local weather = args[1] and args[1]:upper()
    if not weather or not isValidWeather(weather) then
        local valid = table.concat(WEATHERS, ', ')
        if src == 0 then print('[NX-Core] Meteorologias validas: ' .. valid)
        else TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, 'Meteorologia invalida. Validas: ' .. valid, 'error') end
        return
    end

    serverWeather = weather
    TriggerClientEvent('nx-core:client:SyncWeather', -1, serverWeather)

    local msg = ('Meteorologia definida para: %s'):format(serverWeather)
    if src == 0 then print('[NX-Core] ' .. msg)
    else TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, msg, 'success') end
    NXCore.Debug('info', '/setweather — %s por src=%s', serverWeather, tostring(src))
end, false)

RegisterCommand('freezetime', function(src, args)
    if src ~= 0 and not NXCore.HasPermission(src, 'admin') then
        TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, NXCore.L('no_permission'), 'error')
        return
    end

    frozen = not frozen
    syncAll()

    local msg = ('Tempo %s.'):format(frozen and 'CONGELADO' or 'DESCONGELADO')
    if src == 0 then print('[NX-Core] ' .. msg)
    else TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, msg, 'success') end
    NXCore.Debug('info', '/freezetime — frozen=%s por src=%s', tostring(frozen), tostring(src))
end, false)

-- -----------------------------------------------
--  Exports para scripts externos
-- -----------------------------------------------
exports('GetServerTime',    function() return serverHour, serverMinute end)
exports('GetServerWeather', function() return serverWeather end)
exports('SetServerTime',    function(h, m) serverHour = h; serverMinute = m or 0; syncAll() end)
exports('SetServerWeather', function(w) serverWeather = w; TriggerClientEvent('nx-core:client:SyncWeather', -1, w) end)

print('^2[NX-Core]^7 Server Time carregado.')
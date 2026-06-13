-- ============================================================
--  NX-Core — Server Loops (CORRIGIDO: intervalos separados)
-- ============================================================

local AUTO_SAVE_INTERVAL    = 300000   -- 5 minutos
local STATUS_LOG_INTERVAL   = 600000   -- 10 minutos (diferente do save)
local HEALTH_CHECK_INTERVAL = 60000    -- 1 minuto
local RATELIMIT_CLEAN_INTERVAL = 600000
local SALARY_INTERVAL = (Config.SalaryInterval or 30) * 60000

-- -----------------------------------------------
--  Auto-save global
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(AUTO_SAVE_INTERVAL)
        local count = 0
        for src, _ in pairs(NXCore.Players) do
            NXCore.SavePlayer(src)
            count = count + 1
        end
        if count > 0 then
            NXCore.Debug('info', '[AutoSave] %d jogadores guardados.', count)
        end
    end
end)

-- -----------------------------------------------
--  Health-check BD
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(HEALTH_CHECK_INTERVAL)
        MySQL.query('SELECT 1 AS ping', {}, function(result)
            if result and result[1] then
                NXCore.Debug('info', '[HealthCheck] BD OK.')
            else
                print('^1[NX-Core]^7 [HealthCheck] BD NAO RESPONDE!')
                NXCore.NotifyStaff('[NX-Core] ALERTA', 'A base de dados nao esta a responder!', 'error')
            end
        end)
    end
end)

-- -----------------------------------------------
--  Limpeza de rate-limits
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(RATELIMIT_CLEAN_INTERVAL)
        local cleaned = 0
        for srcStr, _ in pairs(NXCore.RateLimits) do
            local src = tonumber(srcStr)
            if src and not NXCore.Players[src] then
                NXCore.RateLimits[srcStr] = nil
                cleaned = cleaned + 1
            end
        end
        if cleaned > 0 then
            NXCore.Debug('info', '[Cleanup] %d entradas de rate-limit limpas.', cleaned)
        end
    end
end)

-- -----------------------------------------------
--  Log de estado (intervalo DIFERENTE do auto-save)
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(STATUS_LOG_INTERVAL)
        local playerCount = 0
        for _ in pairs(NXCore.Players) do playerCount = playerCount + 1 end
        print(('^3[NX-Core]^7 [Status] Online: %d jogadores'):format(playerCount))
    end
end)

-- -----------------------------------------------
--  Pagamento de salarios
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(SALARY_INTERVAL)
        local paid = 0
        for src, _ in pairs(NXCore.Players) do
            NXCore.PaySalary(src)
            paid = paid + 1
        end
        if paid > 0 then
            NXCore.Debug('info', '[Salary] Salarios pagos a %d jogadores.', paid)
        end
    end
end)

print('^2[NX-Core]^7 Server Loops iniciados.')
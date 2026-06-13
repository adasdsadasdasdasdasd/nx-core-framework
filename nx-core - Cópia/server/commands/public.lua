-- ============================================================
--  NX-Core — Comandos Públicos
--  /jobs — mostra emprego/gangue e cargo atual
-- ============================================================

RegisterCommand('jobs', function(src)
    if not NXCore.RateLimit(src, 'jobs', 3000) then return end

    local player = NXCore.GetPlayer(src)
    if not player then
        TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, NXCore.L('player_not_found'), 'error')
        return
    end

    local job = player.job

    if not job or job.name == 'unemployed' then
        TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName,
            NXCore.L('unemployed'), 'inform', 5000)
    elseif job.isGang then
        TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName,
            NXCore.L('your_gang', job.label or job.name, job.gradeLabel or job.grade), 'inform', 6000)
    else
        TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName,
            NXCore.L('your_job', job.label or job.name, job.gradeLabel or job.grade), 'inform', 6000)
    end

    NXCore.Debug('info', '/jobs — src=%s job=%s grade=%s', tostring(src), tostring(job.name), tostring(job.grade))
end, false)

print('^2[NX-Core]^7 Comandos Públicos carregados.')
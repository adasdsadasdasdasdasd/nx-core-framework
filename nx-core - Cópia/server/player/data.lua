-- ============================================================
--  NX-Core — Player Data (CORRIGIDO: SetJob via Shared.Jobs)
-- ============================================================

function NXCore.SavePlayer(src, callback)
    local player = NXCore.GetPlayer(src)
    if not player then
        if callback then callback(false) end
        return
    end

    local metaJson = json.encode(player.metadata or {})

    MySQL.transaction({
        {
            query  = 'UPDATE nx_player_money SET bank=?, cash_dirty=? WHERE player_id=?',
            values = { player.money.bank or 0, player.money.cash_dirty or 0, player.id },
        },
        {
            query  = 'UPDATE nx_player_jobs SET job=?, grade=?, is_gang=? WHERE player_id=?',
            values = {
                player.job.name  or 'unemployed',
                tonumber(player.job.grade) or 0,
                player.job.isGang and 1 or 0,
                player.id,
            },
        },
        {
            query  = 'INSERT INTO nx_player_metadata (player_id, meta) VALUES (?,?) ON DUPLICATE KEY UPDATE meta=VALUES(meta)',
            values = { player.id, metaJson },
        },
    }, function(success)
        NXCore.Debug(success and 'info' or 'error', 'SavePlayer %s — id=%d',
            success and 'OK' or 'FALHOU', player.id)
        if callback then callback(success) end
    end)
end

-- -----------------------------------------------
--  Money helpers
-- -----------------------------------------------
function NXCore.SetMoney(src, moneyType, amount)
    local player = NXCore.GetPlayer(src)
    if not player then return false end
    if moneyType ~= 'bank' and moneyType ~= 'cash_dirty' then return false end

    local newAmount = math.max(0, math.min(tonumber(amount) or 0, 9999999999))
    player.money[moneyType] = newAmount

    MySQL.prepare(
        ('UPDATE nx_player_money SET %s=? WHERE player_id=?'):format(moneyType),
        { newAmount, player.id }, function() end
    )

    TriggerClientEvent('nx-core:client:SyncData', src, 'money', player.money)
    return true
end

function NXCore.AddMoney(src, moneyType, amount)
    local player = NXCore.GetPlayer(src)
    if not player then return false end
    return NXCore.SetMoney(src, moneyType, (player.money[moneyType] or 0) + (tonumber(amount) or 0))
end

function NXCore.RemoveMoney(src, moneyType, amount)
    local player = NXCore.GetPlayer(src)
    if not player then return false end
    local current  = player.money[moneyType] or 0
    local toRemove = tonumber(amount) or 0
    if current < toRemove then return false end
    return NXCore.SetMoney(src, moneyType, current - toRemove)
end

-- -----------------------------------------------
--  SetJob — usa Shared.Jobs (sem BD extra)
-- -----------------------------------------------
function NXCore.SetJob(src, jobName, grade)
    local player = NXCore.GetPlayer(src)
    if not player then return false end

    local gradeNum = tonumber(grade) or 0
    local jobData  = NXCore.Shared and NXCore.Shared.Jobs and NXCore.Shared.Jobs[jobName]

    if not jobData then
        NXCore.Debug('warn', 'SetJob: job "%s" nao existe no Shared.Jobs.', tostring(jobName))
        return false
    end

    if not jobData.grades[gradeNum] then
        NXCore.Debug('warn', 'SetJob: grade %d nao existe no job "%s".', gradeNum, jobName)
        return false
    end

    player.job = {
        name       = jobName,
        grade      = gradeNum,
        label      = jobData.label,
        gradeLabel = NXCore.GetJobGradeLabel(jobName, gradeNum),
        isGang     = false,
    }

    -- Regra exclusiva: se tem gang, remove
    if NXCore.Groups and NXCore.Groups[src] then
        NXCore.Groups[src].job  = player.job
        NXCore.Groups[src].gang = { name='none', grade=0, label='Sem Gangue', gradeLabel='Sem Gangue', isBoss=false }
        player.gang = NXCore.Groups[src].gang
        TriggerClientEvent('nx-core:client:SyncData', src, 'gang', player.gang)
    end

    MySQL.prepare(
        'UPDATE nx_player_jobs SET job=?, grade=?, is_gang=0 WHERE player_id=?',
        { jobName, gradeNum, player.id }, function() end
    )

    TriggerClientEvent('nx-core:client:SyncData', src, 'job', player.job)
    TriggerEvent('nx-core:server:onJobSet', src, player.job)
    NXCore.Debug('info', 'SetJob OK — id=%d job=%s grade=%d', player.id, jobName, gradeNum)
    return true
end

function NXCore.SetMetadata(src, key, value)
    local player = NXCore.GetPlayer(src)
    if not player then return false end
    player.metadata[key] = value
    MySQL.prepare(
        'UPDATE nx_player_metadata SET meta=? WHERE player_id=?',
        { json.encode(player.metadata), player.id }, function() end
    )
    return true
end

-- -----------------------------------------------
--  UNICO handler playerDropped (save + limpeza)
-- -----------------------------------------------
AddEventHandler('playerDropped', function()
    local src    = source
    local player = NXCore.Players[src]

    if player then
        NXCore.SavePlayer(src, function(success)
            NXCore.Debug('info', 'Disconnect save — id=%d success=%s', player.id, tostring(success))
        end)
        TriggerEvent('nx-core:server:onPlayerUnloaded', src, player)
        NXCore.Players[src] = nil
    end

    if NXCore.Groups then NXCore.Groups[src] = nil end
end)

-- Exports
exports('SavePlayer',  NXCore.SavePlayer)
exports('SetMoney',    NXCore.SetMoney)
exports('AddMoney',    NXCore.AddMoney)
exports('RemoveMoney', NXCore.RemoveMoney)
exports('SetJob',      NXCore.SetJob)
exports('SetMetadata', NXCore.SetMetadata)

print('^2[NX-Core]^7 Player Data carregado.')
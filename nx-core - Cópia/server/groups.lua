-- ============================================================
--  NX-Core — Server Groups (CORRIGIDO: sem subquery MySQL)
-- ============================================================

NXCore.Groups = {}

AddEventHandler('nx-core:server:onPlayerLoaded', function(src, player)
    NXCore.Groups[src] = {
        job = {
            name       = player.job and player.job.name       or 'unemployed',
            grade      = tonumber(player.job and player.job.grade) or 0,
            label      = player.job and player.job.label      or 'Desempregado',
            gradeLabel = player.job and player.job.gradeLabel or 'Desempregado',
            isGang     = false,
        },
        gang = {
            name       = 'none',
            grade      = 0,
            label      = 'Sem Gangue',
            gradeLabel = 'Sem Gangue',
            isBoss     = false,
        },
    }
    NXCore.Debug('info', 'Groups init — src=%s job=%s', tostring(src), NXCore.Groups[src].job.name)
end)

function NXCore.GetGroups(src)
    return NXCore.Groups[src]
end

function NXCore.SetGroup(src, groupType, name, grade)
    if groupType ~= 'job' and groupType ~= 'gang' then
        NXCore.Debug('warn', 'SetGroup: tipo invalido "%s"', tostring(groupType))
        return false
    end

    local player = NXCore.GetPlayer(src)
    if not player then
        NXCore.Debug('warn', 'SetGroup: jogador src=%s nao encontrado.', tostring(src))
        return false
    end

    NXCore.Groups[src] = NXCore.Groups[src] or {
        job  = { name = 'unemployed', grade = 0, label = 'Desempregado', gradeLabel = 'Desempregado', isGang = false },
        gang = { name = 'none',       grade = 0, label = 'Sem Gangue',   gradeLabel = 'Sem Gangue',   isBoss = false },
    }

    local gradeNum = tonumber(grade) or 0

    -- -----------------------------------------------
    --  REGRA EXCLUSIVA: job ou gang, nunca ambos
    --  Usa player.id em memoria (sem subquery)
    -- -----------------------------------------------
    if groupType == 'job' and name ~= 'unemployed' then
        -- Ao definir job real → remove gang
        NXCore.Groups[src].gang = {
            name = 'none', grade = 0, label = 'Sem Gangue', gradeLabel = 'Sem Gangue', isBoss = false
        }
        player.gang = NXCore.Groups[src].gang
        TriggerClientEvent('nx-core:client:SyncData', src, 'gang', player.gang)
        NXCore.Debug('info', 'SetGroup: gang removida por definicao de job — src=%s', tostring(src))

    elseif groupType == 'gang' and name ~= 'none' then
        -- Ao entrar em gang → job passa a unemployed
        NXCore.Groups[src].job = {
            name = 'unemployed', grade = 0, label = 'Desempregado', gradeLabel = 'Desempregado', isGang = false
        }
        player.job = NXCore.Groups[src].job
        TriggerClientEvent('nx-core:client:SyncData', src, 'job', player.job)

        -- Atualiza BD usando player.id (sem subquery)
        MySQL.prepare(
            'UPDATE nx_player_jobs SET job = ?, grade = ?, is_gang = 0 WHERE player_id = ?',
            { 'unemployed', '0', player.id },
            function() end
        )
        NXCore.Debug('info', 'SetGroup: job -> unemployed por entrada em gang — src=%s', tostring(src))
    end

    -- Define o grupo solicitado
    if groupType == 'job' then
        local jobData    = NXCore.Shared and NXCore.Shared.Jobs and NXCore.Shared.Jobs[name]
        local gradeLabel = NXCore.GetJobGradeLabel(name, gradeNum)

        NXCore.Groups[src].job = {
            name       = name,
            grade      = gradeNum,
            label      = jobData and jobData.label or name,
            gradeLabel = gradeLabel,
            isGang     = false,
        }
        player.job = NXCore.Groups[src].job
        TriggerClientEvent('nx-core:client:SyncData', src, 'job', player.job)

    elseif groupType == 'gang' then
        local gangData   = NXCore.Shared and NXCore.Shared.Gangs and NXCore.Shared.Gangs[name]
        local gradeLabel = NXCore.GetGangGradeLabel(name, gradeNum)
        local gradeData  = gangData and gangData.grades[gradeNum]

        NXCore.Groups[src].gang = {
            name       = name,
            grade      = gradeNum,
            label      = gangData and gangData.label or name,
            gradeLabel = gradeLabel,
            isBoss     = gradeData and gradeData.isBoss or false,
        }
        player.gang = NXCore.Groups[src].gang
        TriggerClientEvent('nx-core:client:SyncData', src, 'gang', player.gang)
    end

    -- Guarda na BD usando player.id
    MySQL.prepare(
        'UPDATE nx_player_jobs SET job = ?, grade = ?, is_gang = ? WHERE player_id = ?',
        {
            groupType == 'job' and name or player.job.name,
            tostring(gradeNum),
            groupType == 'gang' and (name ~= 'none' and 1 or 0) or 0,
            player.id,
        },
        function()
            NXCore.Debug('info', 'SetGroup BD OK — id=%d type=%s name=%s grade=%d',
                player.id, groupType, name, gradeNum)
        end
    )

    TriggerEvent('nx-core:server:onGroupUpdate', src, groupType, NXCore.Groups[src][groupType])
    return true
end

function NXCore.HasGroup(src, groupName, minGrade)
    local groups = NXCore.Groups[src]
    if not groups then return false end
    minGrade = tonumber(minGrade) or 0
    if groups.job.name  == groupName and groups.job.grade  >= minGrade then return true, groups.job.grade  end
    if groups.gang.name == groupName and groups.gang.grade >= minGrade then return true, groups.gang.grade end
    return false
end

function NXCore.IsGangBossPlayer(src)
    local groups = NXCore.Groups[src]
    return groups and groups.gang and groups.gang.isBoss == true or false
end

RegisterNetEvent('nx-core:server:GetGroups', function()
    local src    = source
    local groups = NXCore.GetGroups(src)
    if groups then
        TriggerClientEvent('nx-core:client:SyncData', src, 'groups', groups)
    end
end)

exports('GetGroups',        NXCore.GetGroups)
exports('SetGroup',         NXCore.SetGroup)
exports('HasGroup',         NXCore.HasGroup)
exports('IsGangBossPlayer', NXCore.IsGangBossPlayer)

print('^2[NX-Core]^7 Server Groups carregado.')
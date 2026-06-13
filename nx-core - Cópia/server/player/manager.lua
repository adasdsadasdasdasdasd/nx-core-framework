-- ============================================================
--  NX-Core — Player Manager (CORRIGIDO)
-- ============================================================

local DEFERRALS_TIMEOUT = 8000

local function BuildPlayerObject(src, row)
    local jobName  = row.job   or 'unemployed'
    local gradeNum = tonumber(row.grade) or 0
    local isGang   = row.isGang == 1

    -- Busca label do Shared.Jobs ou Shared.Gangs (sem depender de BD)
    local jobData    = NXCore.Shared and NXCore.Shared.Jobs and NXCore.Shared.Jobs[jobName]
    local jobLabel   = jobData and jobData.label or jobName
    local gradeLabel = NXCore.GetJobGradeLabel(jobName, gradeNum)

    return {
        source     = src,
        id         = tonumber(row.id),
        license    = row.license,
        steam      = row.steam,
        discord    = row.discord,
        name       = GetPlayerName(src) or 'Unknown',
        firstname  = row.firstname  or 'Desconhecido',
        lastname   = row.lastname   or 'Desconhecido',
        dob        = row.dob,
        sex        = row.sex        or 'm',
        phone      = row.phone,
        staffCargo = row.staffCargo or nil,
        job = {
            name       = jobName,
            grade      = gradeNum,
            label      = jobLabel,
            gradeLabel = gradeLabel,
            isGang     = isGang,
        },
        gang = {
            name       = 'none',
            grade      = 0,
            label      = 'Sem Gangue',
            gradeLabel = 'Sem Gangue',
            isBoss     = false,
        },
        money = {
            bank       = tonumber(row.bank)       or 5000,
            cash_dirty = tonumber(row.cash_dirty) or 0,
        },
        metadata = row.metadata or {},
        position = {
            x       = tonumber(row.x)       or Config.DefaultSpawn.x,
            y       = tonumber(row.y)       or Config.DefaultSpawn.y,
            z       = tonumber(row.z)       or Config.DefaultSpawn.z,
            heading = tonumber(row.heading) or Config.DefaultSpawn.heading,
        },
    }
end

-- -----------------------------------------------
--  playerConnecting — ban check
-- -----------------------------------------------
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src     = source
    local license = NXCore.GetLicense(src)

    deferrals.defer()
    deferrals.update('[NX-Core] A verificar a tua conta...')

    local done = false

    if not license then
        done = true
        deferrals.done('[NX-Core] Identificador de licenca nao encontrado.')
        return
    end

    SetTimeout(DEFERRALS_TIMEOUT, function()
        if not done then
            done = true
            NXCore.Debug('warn', 'Deferral timeout — src=%s', tostring(src))
            deferrals.done()
        end
    end)

    MySQL.single(
        'SELECT is_banned, ban_reason FROM nx_players WHERE license = ?',
        { license },
        function(row)
            if done then return end
            done = true
            if row and row.is_banned == 1 then
                deferrals.done(('[NX-Core] Foste banido.\nRazao: %s'):format(row.ban_reason or 'N/A'))
            else
                deferrals.done()
            end
        end
    )
end)

-- -----------------------------------------------
--  RequestPlayerData
-- -----------------------------------------------
RegisterNetEvent('nx-core:server:RequestPlayerData', function()
    local src     = source
    local license = NXCore.GetLicense(src)
    if not license then
        NXCore.Debug('error', 'RequestPlayerData: sem licenca src=%s', tostring(src))
        DropPlayer(src, '[NX-Core] Identificador invalido.')
        return
    end
    NXCore.LoadPlayer(src, license)
end)

-- -----------------------------------------------
--  LoadPlayer — 3 etapas seguras
-- -----------------------------------------------
function NXCore.LoadPlayer(src, license)
    local steam   = NXCore.GetIdentifier(src, 'steam')
    local discord = NXCore.GetIdentifier(src, 'discord')
    local name    = GetPlayerName(src) or 'Unknown'

    -- ETAPA 1: UPSERT
    MySQL.prepare(
        [[INSERT INTO nx_players (license, steam, discord, name)
          VALUES (?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE steam=VALUES(steam), discord=VALUES(discord), name=VALUES(name)]],
        { license, steam, discord, name },
        function(rows)
            if not rows then
                NXCore.Debug('error', 'LoadPlayer E1 falhou — license=%s', license)
                if GetPlayerName(src) then DropPlayer(src, '[NX-Core] Erro BD. Tenta novamente.') end
                return
            end

            -- ETAPA 2: obtem ID fixo
            MySQL.scalar('SELECT id FROM nx_players WHERE license = ?', { license },
                function(playerId)
                    if not playerId then
                        NXCore.Debug('error', 'LoadPlayer E2: id nao encontrado — license=%s', license)
                        if GetPlayerName(src) then DropPlayer(src, '[NX-Core] Erro BD. Tenta novamente.') end
                        return
                    end
                    NXCore.InitPlayerRecords(src, tonumber(playerId), license)
                end
            )
        end
    )
end

-- -----------------------------------------------
--  InitPlayerRecords
-- -----------------------------------------------
function NXCore.InitPlayerRecords(src, playerId, license)
    MySQL.transaction({
        { query = 'INSERT IGNORE INTO nx_player_money     (player_id)       VALUES (?)', values = { playerId } },
        { query = 'INSERT IGNORE INTO nx_player_jobs      (player_id)       VALUES (?)', values = { playerId } },
        { query = 'INSERT IGNORE INTO nx_player_positions (player_id)       VALUES (?)', values = { playerId } },
        { query = 'INSERT IGNORE INTO nx_player_metadata  (player_id, meta) VALUES (?, ?)', values = { playerId, '{}' } },
    }, function(success)
        if not success then
            NXCore.Debug('warn', 'InitPlayerRecords: transacao falhou id=%d — a continuar.', playerId)
        end
        NXCore.FetchPlayerData(src, playerId, license)
    end)
end

-- -----------------------------------------------
--  FetchPlayerData — SEM JOIN nx_jobs_config
-- -----------------------------------------------
function NXCore.FetchPlayerData(src, playerId, license)
    MySQL.single([[
        SELECT
            p.id, p.license, p.steam, p.discord,
            p.firstname, p.lastname, p.dob, p.sex, p.phone,
            pos.x, pos.y, pos.z, pos.heading,
            m.meta          AS metadata,
            mo.bank,        mo.cash_dirty,
            j.job,          j.grade,       j.is_gang AS isGang,
            s.cargo         AS staffCargo
        FROM nx_players p
        LEFT JOIN nx_player_positions pos ON pos.player_id = p.id
        LEFT JOIN nx_player_metadata  m   ON m.player_id   = p.id
        LEFT JOIN nx_player_money     mo  ON mo.player_id  = p.id
        LEFT JOIN nx_player_jobs      j   ON j.player_id   = p.id
        LEFT JOIN nx_staff            s   ON s.player_id   = p.id
        WHERE p.id = ?
    ]], { playerId },
    function(row)
        -- Guard: jogador ainda online?
        if not GetPlayerName(src) then
            NXCore.Debug('warn', 'FetchPlayerData: src=%s saiu durante load.', tostring(src))
            return
        end

        if not row then
            NXCore.Debug('error', 'FetchPlayerData: sem resultado id=%d', playerId)
            DropPlayer(src, '[NX-Core] Erro ao carregar dados.')
            return
        end

        -- Deserializa metadata
        if type(row.metadata) == 'string' then
            local ok, decoded = pcall(json.decode, row.metadata)
            row.metadata = ok and decoded or {}
        else
            row.metadata = row.metadata or {}
        end

        local playerObj = BuildPlayerObject(src, row)
        NXCore.Players[src] = playerObj

        -- Inicializa grupos
        NXCore.Groups = NXCore.Groups or {}
        NXCore.Groups[src] = {
            job = {
                name       = playerObj.job.name,
                grade      = playerObj.job.grade,
                label      = playerObj.job.label,
                gradeLabel = playerObj.job.gradeLabel,
                isGang     = playerObj.job.isGang,
            },
            gang = {
                name = 'none', grade = 0,
                label = 'Sem Gangue', gradeLabel = 'Sem Gangue', isBoss = false,
            },
        }

        NXCore.Debug('info', 'Jogador CARREGADO — id=%d name=%s staff=%s',
            playerObj.id, playerObj.name, tostring(playerObj.staffCargo))

        TriggerClientEvent('nx-core:client:PlayerLoaded', src, {
            id         = playerObj.id,
            name       = playerObj.name,
            firstname  = playerObj.firstname,
            lastname   = playerObj.lastname,
            job        = playerObj.job,
            gang       = playerObj.gang,
            money      = playerObj.money,
            position   = playerObj.position,
            staffCargo = playerObj.staffCargo,
        })

        TriggerEvent('nx-core:server:onPlayerLoaded', src, playerObj)
    end)
end

-- -----------------------------------------------
--  SavePosition
-- -----------------------------------------------
RegisterNetEvent('nx-core:server:SavePosition', function(posData)
    local src = source
    if not NXCore.RateLimit(src, 'SavePosition', 30000) then return end
    if not posData or type(posData) ~= 'table' then return end
    local player = NXCore.GetPlayer(src)
    if not player then return end

    MySQL.prepare(
        [[INSERT INTO nx_player_positions (player_id, x, y, z, heading)
          VALUES (?, ?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE x=VALUES(x), y=VALUES(y), z=VALUES(z), heading=VALUES(heading)]],
        { player.id, posData.x or 0, posData.y or 0, posData.z or 0, posData.heading or 0 },
        function() end
    )
end)

exports('LoadPlayer', NXCore.LoadPlayer)

print('^2[NX-Core]^7 Player Manager carregado.')
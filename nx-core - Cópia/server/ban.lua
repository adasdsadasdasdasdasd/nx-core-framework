-- ============================================================
--  NX-Core — Sistema de Banimentos
--  /ban <id>     → abre UI ox_lib (razao + imediato/ao sair)
--  /unban <id>   → remove ban ingame ou TxAdmin
--  /bans         → lista bans ativos
--  Sincronizado com TxAdmin via SetPlayerBucket + DropPlayer
-- ============================================================

NXCore.PendingBans = {}  -- { [src] = { reason, immediate } }

-- -----------------------------------------------
--  Helper: notifica consola ou jogador
-- -----------------------------------------------
local function notify(src, message, notifyType)
    if src == 0 then
        print(('[NX-Core][CONSOLE] %s'):format(message))
    else
        TriggerClientEvent('nx-core:client:Notify', src, Config.ServerName, message, notifyType or 'inform')
    end
end

local function hasPermission(src, cargo)
    if src == 0 then return true end
    return NXCore.HasPermission(src, cargo)
end

-- -----------------------------------------------
--  Executa o ban (na BD + expulsa se imediato)
-- -----------------------------------------------
local function executeBan(targetSrc, reason, immediate, executorSrc)
    local target = NXCore.GetPlayer(targetSrc)
    if not target then
        notify(executorSrc, NXCore.L('player_not_found'), 'error')
        return false
    end

    local executorLicense = (executorSrc == 0) and 'console' or (NXCore.GetLicense(executorSrc) or 'unknown')

    -- Guarda na BD
    MySQL.transaction({
        {
            query  = 'UPDATE nx_players SET is_banned = 1, ban_reason = ? WHERE license = ?',
            values = { reason, target.license },
        },
        {
            query  = [[INSERT INTO nx_bans (license, reason, banned_by, expires_at)
                       VALUES (?, ?, ?, NULL)
                       ON DUPLICATE KEY UPDATE
                         reason     = VALUES(reason),
                         banned_by  = VALUES(banned_by),
                         expires_at = NULL,
                         created_at = CURRENT_TIMESTAMP]],
            values = { target.license, reason, executorLicense },
        },
    }, function(success)
        if not success then
            NXCore.Debug('error', 'executeBan: transacao falhou para license=%s', target.license)
            notify(executorSrc, 'Erro ao guardar o ban na base de dados.', 'error')
            return
        end

        NXCore.Log('ban', executorLicense, target.license, {
            Nome    = target.name,
            Razao   = reason,
            Tipo    = immediate and 'Imediato' or 'Ao sair',
        })

        NXCore.NotifyStaff('[NX-Core] Ban', ('%s foi banido. Razao: %s'):format(target.name, reason), 'error')
        NXCore.Debug('info', 'Ban guardado — license=%s reason=%s imediato=%s', target.license, reason, tostring(immediate))

        if immediate then
            DropPlayer(targetSrc, ('[NX-Core] Foste banido permanentemente.\nRazao: %s'):format(reason))
            NXCore.Debug('info', 'Jogador expulso imediatamente — src=%s', tostring(targetSrc))
        else
            -- Marca ban pendente: aplicado quando o jogador sair
            NXCore.PendingBans[targetSrc] = { reason = reason, license = target.license }
            TriggerClientEvent('nx-core:client:Notify', targetSrc, Config.ServerName,
                'Foste banido. O ban sera aplicado quando sairas do servidor.', 'warning', 10000)
            NXCore.Debug('info', 'Ban pendente registado — src=%s', tostring(targetSrc))
        end

        notify(executorSrc, ('Ban aplicado a %s. Razao: %s'):format(target.name, reason), 'success')
    end)

    return true
end

-- -----------------------------------------------
--  Aplica ban pendente ao desconectar
-- -----------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    if NXCore.PendingBans[src] then
        NXCore.Debug('info', 'Ban pendente aplicado ao desconectar — src=%s', tostring(src))
        NXCore.PendingBans[src] = nil
        -- Ban ja esta na BD; nao precisa de fazer nada mais
    end
end)

-- -----------------------------------------------
--  /ban <id> — abre UI ox_lib no staff
-- -----------------------------------------------
RegisterCommand('ban', function(src, args)
    if src == 0 then
        -- Consola: ban direto sem UI
        local targetId = tonumber(args[1])
        if not targetId then
            print('[NX-Core] Uso: ban <id> <razao>')
            return
        end
        table.remove(args, 1)
        local reason = #args > 0 and table.concat(args, ' ') or 'Banido pela administracao.'
        executeBan(targetId, reason, true, 0)
        return
    end

    if not NXCore.RateLimit(src, 'ban', Config.RateLimit.commandCooldown) then
        notify(src, NXCore.L('rate_limited'), 'error')
        return
    end

    if not hasPermission(src, 'admin') then
        notify(src, NXCore.L('no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Uso: /ban <id>', 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    -- Abre formulario ox_lib no cliente staff
    TriggerClientEvent('nx-core:client:OpenBanMenu', src, {
        targetId   = targetId,
        targetName = target.name,
        license    = target.license,
    })

    NXCore.Debug('info', '/ban — src=%s abriu menu para target=%s', tostring(src), tostring(targetId))
end, false)

-- -----------------------------------------------
--  Net event: staff submeteu o formulario de ban
-- -----------------------------------------------
RegisterNetEvent('nx-core:server:SubmitBan', function(data)
    local src = source

    if not NXCore.RateLimit(src, 'SubmitBan', 3000) then return end

    if not hasPermission(src, 'admin') then
        notify(src, NXCore.L('no_permission'), 'error')
        NXCore.Debug('warn', 'SubmitBan negado — src=%s sem permissao.', tostring(src))
        return
    end

    -- Validacao server-side de todos os campos
    if not data or type(data) ~= 'table' then
        NXCore.Debug('warn', 'SubmitBan: dados invalidos de src=%s', tostring(src))
        return
    end

    local targetId = tonumber(data.targetId)
    local reason   = type(data.reason) == 'string' and data.reason:match('^%s*(.-)%s*$') or ''
    local immediate = data.immediate == true

    if not targetId then
        notify(src, 'ID de jogador invalido.', 'error')
        return
    end

    if #reason < 3 then
        notify(src, 'A razao do ban deve ter pelo menos 3 caracteres.', 'error')
        return
    end

    if #reason > 255 then
        reason = reason:sub(1, 255)
    end

    executeBan(targetId, reason, immediate, src)
end)

-- -----------------------------------------------
--  /unban <id ou license> — remove ban ingame e TxAdmin
-- -----------------------------------------------
RegisterCommand('unban', function(src, args)
    if src ~= 0 and not NXCore.RateLimit(src, 'unban', Config.RateLimit.commandCooldown) then
        notify(src, NXCore.L('rate_limited'), 'error')
        return
    end

    if not hasPermission(src, 'admin') then
        notify(src, NXCore.L('no_permission'), 'error')
        return
    end

    local input = args[1]
    if not input then
        notify(src, 'Uso: /unban <license>   Exemplo: /unban abc123def456', 'error')
        return
    end

    -- Suporta "license:xxxx" ou apenas "xxxx"
    local license = input:gsub('^license:', '')

    MySQL.single(
        'SELECT id, name, is_banned FROM nx_players WHERE license = ?',
        { license },
        function(row)
            if not row then
                notify(src, ('License nao encontrada: %s'):format(license), 'error')
                return
            end

            if row.is_banned == 0 then
                notify(src, ('O jogador "%s" nao esta banido.'):format(row.name or license), 'warning')
                return
            end

            MySQL.transaction({
                {
                    query  = 'UPDATE nx_players SET is_banned = 0, ban_reason = NULL WHERE license = ?',
                    values = { license },
                },
                {
                    query  = 'DELETE FROM nx_bans WHERE license = ?',
                    values = { license },
                },
            }, function(success)
                if success then
                    local executorLicense = (src == 0) and 'console' or (NXCore.GetLicense(src) or 'unknown')

                    NXCore.Log('unban', executorLicense, license, {
                        Nome = row.name or license,
                    })

                    notify(src, ('Ban removido com sucesso para: %s (%s)'):format(row.name or 'Desconhecido', license), 'success')
                    NXCore.Debug('info', '/unban OK — license=%s by=%s', license, executorLicense)
                else
                    notify(src, 'Erro ao remover o ban na base de dados.', 'error')
                    NXCore.Debug('error', '/unban: transacao falhou para license=%s', license)
                end
            end)
        end
    )
end, false)

-- -----------------------------------------------
--  /bans — lista os 20 bans mais recentes
-- -----------------------------------------------
RegisterCommand('bans', function(src)
    if not hasPermission(src, 'mod') then
        notify(src, NXCore.L('no_permission'), 'error')
        return
    end

    MySQL.query(
        [[SELECT p.license, p.name, b.reason, b.banned_by, b.expires_at, b.created_at
          FROM nx_bans b
          JOIN nx_players p ON p.license = b.license
          ORDER BY b.created_at DESC
          LIMIT 20]],
        {},
        function(rows)
            if not rows or #rows == 0 then
                notify(src, 'Nenhum ban ativo encontrado.', 'inform')
                return
            end

            if src == 0 then
                print(('[NX-Core] === BANS ATIVOS (%d) ==='):format(#rows))
                for _, row in ipairs(rows) do
                    print(('[%s] %s | %s | Por: %s'):format(
                        tostring(row.created_at),
                        row.name or row.license,
                        row.reason,
                        row.banned_by
                    ))
                end
            else
                -- Envia lista formatada ao staff via interface ox_lib
                TriggerClientEvent('nx-core:client:ShowBanList', src, rows)
            end
        end
    )
end, false)

-- -----------------------------------------------
--  Thread: verifica tempbans expirados a cada 5 minutos
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(300000)

        MySQL.query(
            [[SELECT p.license FROM nx_bans b
              JOIN nx_players p ON p.license = b.license
              WHERE b.expires_at IS NOT NULL AND b.expires_at <= NOW()]],
            {},
            function(rows)
                if not rows or #rows == 0 then return end
                for _, row in ipairs(rows) do
                    MySQL.prepare('UPDATE nx_players SET is_banned = 0, ban_reason = NULL WHERE license = ?',
                        { row.license }, function() end)
                    MySQL.prepare('DELETE FROM nx_bans WHERE license = ?',
                        { row.license }, function() end)
                    NXCore.Debug('info', 'Tempban expirado removido — license=%s', row.license)
                end
                NXCore.Debug('info', '%d tempbans expirados processados.', #rows)
            end
        )
    end
end)

print('^2[NX-Core]^7 Sistema de Bans carregado.')
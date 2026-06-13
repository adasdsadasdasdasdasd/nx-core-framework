-- ============================================================
--  NX-Core — Comandos Admin (CORRIGIDO: print consola)
-- ============================================================

NXCore.Debug('info', 'A carregar admin.lua...')

local CARGO_ALIASES = {
    dono          = 'owner',
    ['co-dono']   = 'co-owner',
    codono        = 'co-owner',
    dev           = 'developer',
    desenvolvedor = 'developer',
    moderador     = 'mod',
    administrador = 'admin',
    suporte       = 'support',
    trial         = 'trial',
    support       = 'support',
    mod           = 'mod',
    admin         = 'admin',
    developer     = 'developer',
    ['co-owner']  = 'co-owner',
    owner         = 'owner',
}

local function resolveCargo(input)
    if not input then return nil end
    return CARGO_ALIASES[input:lower()]
end

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
--  /setstaff <id> <cargo>
-- -----------------------------------------------
RegisterCommand('setstaff', function(src, args)
    if src ~= 0 and not NXCore.RateLimit(src, 'setstaff', Config.RateLimit.commandCooldown) then
        notify(src, NXCore.L('rate_limited'), 'error')
        return
    end

    if not hasPermission(src, Config.CommandPermissions.setstaff) then
        notify(src, NXCore.L('no_permission'), 'error')
        return
    end

    local targetId   = tonumber(args[1])
    local cargoInput = args[2]
    local cargo      = cargoInput and resolveCargo(cargoInput)

    if not targetId or not cargo then
        notify(src, ('Uso: /setstaff <id> <cargo>  |  Cargos: dono, co-dono, dev, admin, mod, suporte, trial\nRecebido: "%s"'):format(tostring(cargoInput)), 'error')
        return
    end

    -- Apenas owner pode promover a owner
    if cargo == 'owner' and src ~= 0 and not NXCore.HasPermission(src, 'owner') then
        notify(src, NXCore.L('no_permission'), 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    local grantedBy = (src == 0) and 'console' or (NXCore.GetLicense(src) or 'unknown')

    MySQL.prepare(
        [[INSERT INTO nx_staff (player_id, license, cargo, granted_by)
          VALUES (?, ?, ?, ?)
          ON DUPLICATE KEY UPDATE cargo=VALUES(cargo), granted_by=VALUES(granted_by)]],
        { target.id, target.license, cargo, grantedBy },
        function(result)
            if result then
                target.staffCargo = cargo

                -- ✅ Print detalhado na consola do servidor
                local executorName = (src == 0) and 'CONSOLE' or (GetPlayerName(src) or tostring(src))
                print(('^2[NX-Core][STAFF]^7 %s definiu "%s" como cargo de ^3%s^7 (ID: %d | License: %s) | Definido por: %s'):format(
                    executorName, cargo, target.name, targetId, target.license, grantedBy
                ))

                notify(src, ('Cargo "%s" atribuido a %s com sucesso.'):format(cargo, target.name), 'success')
                TriggerClientEvent('nx-core:client:Notify', targetId, Config.ServerName,
                    ('Foste promovido a "%s".'):format(cargo), 'success')
                TriggerClientEvent('nx-core:client:SyncData', targetId, 'staffCargo', cargo)

                NXCore.Log('setstaff', grantedBy, target.license, {
                    Nome   = target.name,
                    Cargo  = cargo,
                    Por    = grantedBy,
                })
            else
                notify(src, 'Erro ao guardar na base de dados.', 'error')
                print(('^1[NX-Core][STAFF]^7 ERRO ao definir cargo para src=%d'):format(targetId))
            end
        end
    )
end, false)

-- -----------------------------------------------
--  /remstaff <id>
-- -----------------------------------------------
RegisterCommand('remstaff', function(src, args)
    if src ~= 0 and not NXCore.RateLimit(src, 'remstaff', Config.RateLimit.commandCooldown) then
        notify(src, NXCore.L('rate_limited'), 'error')
        return
    end

    if not hasPermission(src, Config.CommandPermissions.remstaff) then
        notify(src, NXCore.L('no_permission'), 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, 'Uso: /remstaff <id>', 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    local previousCargo = target.staffCargo or 'nenhum'
    local executorName  = (src == 0) and 'CONSOLE' or (GetPlayerName(src) or tostring(src))
    local executorLic   = (src == 0) and 'console' or (NXCore.GetLicense(src) or 'unknown')

    MySQL.prepare('DELETE FROM nx_staff WHERE player_id=?', { target.id },
        function(rows)
            if (rows or 0) > 0 then
                target.staffCargo = nil

                -- ✅ Print detalhado na consola do servidor
                print(('^1[NX-Core][STAFF]^7 %s removeu o cargo "%s" de ^3%s^7 (ID: %d | License: %s)'):format(
                    executorName, previousCargo, target.name, targetId, target.license
                ))

                TriggerClientEvent('nx-core:client:SyncData', targetId, 'staffCargo', nil)
                notify(src, ('Cargo de "%s" removido de %s.'):format(previousCargo, target.name), 'success')
                TriggerClientEvent('nx-core:client:Notify', targetId, Config.ServerName,
                    ('O teu cargo de staff "%s" foi removido.'):format(previousCargo), 'error')

                NXCore.Log('remstaff', executorLic, target.license, {
                    Nome          = target.name,
                    CargoRemovido = previousCargo,
                    Por           = executorLic,
                })
            else
                notify(src, ('"%s" nao e membro do staff.'):format(target.name), 'warning')
            end
        end
    )
end, false)

print('^2[NX-Core]^7 Comandos Admin carregados.')
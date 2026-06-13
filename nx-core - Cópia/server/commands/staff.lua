-- ============================================================
--  NX-Core — Comandos Staff
--  noclip, revive, tpto, tpm, bring, openinv, clearinv,
--  car, dv, fix, giveitem, givemoney, setjob
-- ============================================================

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

-- -----------------------------------------------
--  Helper: regista comando com validação de permissão
--  Suporta src == 0 (consola/txAdmin) com permissão total
-- -----------------------------------------------
local function staffCmd(name, minCargo, handler)
    RegisterCommand(name, function(src, args)
        if src ~= 0 and not NXCore.RateLimit(src, name, Config.RateLimit.commandCooldown) then
            notify(src, NXCore.L('rate_limited'), 'error')
            return
        end
        if src ~= 0 and not NXCore.HasPermission(src, minCargo) then
            notify(src, NXCore.L('no_permission'), 'error')
            NXCore.Debug('warn', 'Comando /%s negado — src=%s', name, tostring(src))
            return
        end
        handler(src, args)
    end, false)
end

-- -----------------------------------------------
--  /noclip | /nc — toggle noclip
--  Apenas para jogadores reais (não faz sentido na consola)
-- -----------------------------------------------
local noclipStates = {}

local function toggleNoclip(src)
    if src == 0 then
        print('[NX-Core][CONSOLE] Noclip não está disponível na consola.')
        return
    end
    noclipStates[src] = not noclipStates[src]
    TriggerClientEvent('nx-core:client:ToggleNoclip', src, noclipStates[src])
    NXCore.Debug('info', '/noclip — src=%s state=%s', tostring(src), tostring(noclipStates[src]))
end

staffCmd('noclip', Config.CommandPermissions.noclip, function(src) toggleNoclip(src) end)
staffCmd('nc',     Config.CommandPermissions.nc,     function(src) toggleNoclip(src) end)

-- -----------------------------------------------
--  /revive [id] — revive self ou target
-- -----------------------------------------------
staffCmd('revive', Config.CommandPermissions.revive, function(src, args)
    local targetId = tonumber(args[1]) or src

    if targetId == 0 then
        notify(src, NXCore.L('invalid_args', '/revive <id>'), 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        NXCore.Debug('warn', '/revive: jogador target src=%s não encontrado.', tostring(targetId))
        return
    end

    TriggerClientEvent('nx-core:client:Revive', targetId)
    NXCore.Debug('info', '/revive — src=%s target=%s', tostring(src), tostring(targetId))

    if targetId ~= src then
        notify(src, NXCore.L('revived_target', target.name), 'success')
    end
end)

-- -----------------------------------------------
--  /tpto <id> — teleporta para o alvo
-- -----------------------------------------------
staffCmd('tpto', Config.CommandPermissions.tpto, function(src, args)
    if src == 0 then
        notify(src, 'Teleporte não está disponível na consola.', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, NXCore.L('invalid_args', '/tpto <id>'), 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    -- Solicita coordenadas ao cliente alvo; o client responde via SendCoordsToStaff
    TriggerClientEvent('nx-core:client:RequestCoords', targetId, src)
    NXCore.Debug('info', '/tpto — src=%s -> target=%s', tostring(src), tostring(targetId))
end)

-- -----------------------------------------------
--  /tpm — teleporta para o waypoint (client-side)
-- -----------------------------------------------
staffCmd('tpm', Config.CommandPermissions.tpm, function(src)
    if src == 0 then
        notify(src, 'Teleporte para waypoint não está disponível na consola.', 'error')
        return
    end

    TriggerClientEvent('nx-core:client:TeleportToWaypoint', src)
    NXCore.Debug('info', '/tpm — src=%s', tostring(src))
end)

-- -----------------------------------------------
--  /bring <id> — traz o alvo para a posição do staff
-- -----------------------------------------------
staffCmd('bring', Config.CommandPermissions.bring, function(src, args)
    if src == 0 then
        notify(src, 'Bring não está disponível na consola.', 'error')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, NXCore.L('invalid_args', '/bring <id>'), 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    -- Pede as coords do staff ao seu próprio cliente, que depois teleporta o alvo
    TriggerClientEvent('nx-core:client:RequestCoordsForBring', src, targetId)
    NXCore.Debug('info', '/bring — src=%s -> target=%s', tostring(src), tostring(targetId))
end)

-- -----------------------------------------------
--  /openinv <id>
-- -----------------------------------------------
staffCmd('openinv', Config.CommandPermissions.openinv, function(src, args)
    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, NXCore.L('invalid_args', '/openinv <id>'), 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    -- Delega ao sistema de inventário externo (ox_inventory)
    TriggerEvent('nx-core:server:OpenInventory', src, targetId)
    notify(src, NXCore.L('inv_opened', target.name), 'inform')
    NXCore.Debug('info', '/openinv — src=%s target=%s', tostring(src), tostring(targetId))
end)

-- -----------------------------------------------
--  /clearinv <id>
-- -----------------------------------------------
staffCmd('clearinv', Config.CommandPermissions.clearinv, function(src, args)
    local targetId = tonumber(args[1])
    if not targetId then
        notify(src, NXCore.L('invalid_args', '/clearinv <id>'), 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    TriggerEvent('nx-core:server:ClearInventory', src, targetId)
    notify(src, NXCore.L('inv_cleared', target.name), 'success')
    NXCore.Debug('info', '/clearinv — src=%s target=%s', tostring(src), tostring(targetId))
end)

-- -----------------------------------------------
--  /car <modelo>
-- -----------------------------------------------
staffCmd('car', Config.CommandPermissions.car, function(src, args)
    if src == 0 then
        notify(src, 'Spawn de veículo não está disponível na consola.', 'error')
        return
    end

    local model = args[1]
    if not model or model == '' then
        notify(src, NXCore.L('invalid_args', '/car <modelo>'), 'error')
        return
    end

    model = model:lower()
    TriggerClientEvent('nx-core:client:SpawnVehicle', src, model)
    NXCore.Debug('info', '/car — src=%s model=%s', tostring(src), model)
end)

-- -----------------------------------------------
--  /dv — apaga veículo atual
-- -----------------------------------------------
staffCmd('dv', Config.CommandPermissions.dv, function(src)
    if src == 0 then
        notify(src, 'Apagar veículo não está disponível na consola.', 'error')
        return
    end

    TriggerClientEvent('nx-core:client:DeleteVehicle', src)
    NXCore.Debug('info', '/dv — src=%s', tostring(src))
end)

-- -----------------------------------------------
--  /fix — repara veículo atual
-- -----------------------------------------------
staffCmd('fix', Config.CommandPermissions.fix, function(src)
    if src == 0 then
        notify(src, 'Fix não está disponível na consola.', 'error')
        return
    end

    TriggerClientEvent('nx-core:client:FixVehicle', src)
    NXCore.Debug('info', '/fix — src=%s', tostring(src))
end)

-- -----------------------------------------------
--  /giveitem <id> <item> <quantidade>
--  PROIBIDO dar dinheiro limpo como item.
-- -----------------------------------------------
local FORBIDDEN_ITEMS = {
    cash        = true,
    money       = true,
    clean_money = true,
    dinheiro    = true,
}

staffCmd('giveitem', Config.CommandPermissions.giveitem, function(src, args)
    local targetId = tonumber(args[1])
    local item     = args[2] and args[2]:lower()
    local amount   = tonumber(args[3])

    if not targetId or not item or not amount or amount <= 0 then
        notify(src, NXCore.L('invalid_args', '/giveitem <id> <item> <quantidade>'), 'error')
        return
    end

    if FORBIDDEN_ITEMS[item] then
        notify(src, NXCore.L('dirty_money_only'), 'error')
        NXCore.Debug('warn', '/giveitem bloqueado — item proibido "%s" por src=%s', item, tostring(src))
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    -- Delega ao sistema de inventário externo (ox_inventory)
    TriggerEvent('nx-core:server:GiveItem', targetId, item, amount, src)
    notify(src, NXCore.L('item_given', item, tostring(amount), target.name), 'success')
    NXCore.Debug('info', '/giveitem — src=%s -> target=%s item=%s qty=%d',
        tostring(src), tostring(targetId), item, amount)
end)

-- -----------------------------------------------
--  /givemoney <id> <quantidade> <banco/mão>
--  banco  → bank (transferência bancária)
--  mão    → cash_dirty (dinheiro sujo em mão)
--  Dinheiro limpo em mão: PROIBIDO
-- -----------------------------------------------
local MONEY_TYPE_MAP = {
    banco = 'bank',
    bank  = 'bank',
    mao   = 'cash_dirty',
    sujo  = 'cash_dirty',
    dirty = 'cash_dirty',
}

staffCmd('givemoney', Config.CommandPermissions.givemoney, function(src, args)
    local targetId  = tonumber(args[1])
    local amount    = tonumber(args[2])
    local typeRaw   = args[3] and args[3]:lower()
    local moneyType = typeRaw and MONEY_TYPE_MAP[typeRaw]

    if not targetId or not amount or amount <= 0 or not moneyType then
        notify(src, NXCore.L('invalid_args', '/givemoney <id> <quantidade> <banco/mão>'), 'error')
        return
    end

    if moneyType ~= 'bank' and moneyType ~= 'cash_dirty' then
        notify(src, NXCore.L('dirty_money_only'), 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    local success = NXCore.AddMoney(targetId, moneyType, amount)
    if success then
        notify(src, NXCore.L('money_given', tostring(amount), moneyType, target.name), 'success')
        NXCore.Debug('info', '/givemoney — src=%s -> target=%s type=%s amount=%d',
            tostring(src), tostring(targetId), moneyType, amount)
    else
        notify(src, 'Erro ao adicionar dinheiro.', 'error')
    end
end)

-- -----------------------------------------------
--  /setjob <id> <job> <cargo>
-- -----------------------------------------------
staffCmd('setjob', Config.CommandPermissions.setjob, function(src, args)
    local targetId = tonumber(args[1])
    local jobName  = args[2] and args[2]:lower()
    local grade    = args[3]

    if not targetId or not jobName or not grade then
        notify(src, NXCore.L('invalid_args', '/setjob <id> <job> <cargo>'), 'error')
        return
    end

    local target = NXCore.GetPlayer(targetId)
    if not target then
        notify(src, NXCore.L('player_not_found'), 'error')
        return
    end

    NXCore.SetJob(targetId, jobName, grade)
    notify(src, NXCore.L('job_set', target.name, jobName, grade), 'success')
    NXCore.Debug('info', '/setjob — src=%s -> target=%s job=%s grade=%s',
        tostring(src), tostring(targetId), jobName, grade)
end)

-- -----------------------------------------------
--  Limpa estado de noclip ao jogador desconectar
-- -----------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    if noclipStates[src] then
        noclipStates[src] = nil
        NXCore.Debug('info', 'Noclip state limpo para src=%s ao desconectar.', tostring(src))
    end
end)

print('^2[NX-Core]^7 Comandos Staff carregados.')
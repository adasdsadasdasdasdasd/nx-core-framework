-- ============================================================
--  NX-Core — Ban Menu (Client)
--  Interface ox_lib para preenchimento do formulario de ban.
-- ============================================================

-- -----------------------------------------------
--  Abre o menu de ban ao receber evento do servidor
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:OpenBanMenu', function(data)
    if not data or not data.targetId then return end

    -- Dialog ox_lib com campos do formulario
    local result = lib.inputDialog(
        ('Banir Jogador — %s [ID: %d]'):format(data.targetName, data.targetId),
        {
            {
                type        = 'input',
                label       = 'Razao do Ban',
                description = 'Descreve o motivo do banimento.',
                required    = true,
                min         = 3,
                max         = 255,
            },
            {
                type        = 'checkbox',
                label       = 'Aplicar ban imediatamente',
                description = 'Se nao selecionado, o ban e aplicado quando o jogador sair do servidor.',
                checked     = true,
            },
        }
    )

    -- Utilizador fechou o dialogo sem submeter
    if not result then
        NXCore.Notify(Config.ServerName, 'Ban cancelado.', 'warning')
        return
    end

    local reason    = result[1]
    local immediate = result[2] == true

    if not reason or #reason < 3 then
        NXCore.Notify(Config.ServerName, 'A razao deve ter pelo menos 3 caracteres.', 'error')
        return
    end

    -- Confirmacao final antes de submeter
    local confirmed = lib.alertDialog({
        header  = 'Confirmar Ban',
        content = ('Tens a certeza que queres banir **%s**?\n\n**Razao:** %s\n**Tipo:** %s'):format(
            data.targetName,
            reason,
            immediate and 'Imediato' or 'Ao sair do servidor'
        ),
        centered = true,
        cancel   = true,
    })

    if confirmed ~= 'confirm' then
        NXCore.Notify(Config.ServerName, 'Ban cancelado.', 'warning')
        return
    end

    -- Envia para o servidor com validacao
    TriggerServerEvent('nx-core:server:SubmitBan', {
        targetId  = data.targetId,
        reason    = reason,
        immediate = immediate,
    })

    NXCore.Debug('info', 'Ban submetido — target=%d reason=%s imediato=%s',
        data.targetId, reason, tostring(immediate))
end)

-- -----------------------------------------------
--  Mostra lista de bans formatada (/bans)
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:ShowBanList', function(rows)
    if not rows or #rows == 0 then
        NXCore.Notify(Config.ServerName, 'Nenhum ban encontrado.', 'inform')
        return
    end

    -- Constroi lista para ox_lib textUI ou alertDialog
    local lines = {}
    for i, row in ipairs(rows) do
        lines[#lines + 1] = ('**%d.** %s\n   Razao: %s | Por: %s'):format(
            i,
            row.name or row.license,
            row.reason,
            row.banned_by
        )
    end

    lib.alertDialog({
        header   = ('Bans Ativos (%d)'):format(#rows),
        content  = table.concat(lines, '\n\n'),
        centered = true,
        cancel   = false,
    })
end)

NXCore.Debug('info', 'Ban Menu (Client) carregado.')
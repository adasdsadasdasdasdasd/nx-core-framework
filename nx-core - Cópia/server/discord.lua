-- ============================================================
--  NX-Core — Discord Webhook Logger
--  Envia embeds formatados para canais Discord por categoria.
-- ============================================================

NXCore.Discord = {}

-- -----------------------------------------------
--  Envia embed para um webhook especifico
-- -----------------------------------------------
function NXCore.Discord.Send(webhookUrl, title, description, color, fields)
    if not webhookUrl or webhookUrl == '' then return end

    local embedFields = {}
    for k, v in pairs(fields or {}) do
        embedFields[#embedFields + 1] = {
            name   = tostring(k),
            value  = ('```%s```'):format(tostring(v)),
            inline = true,
        }
    end

    local payload = json.encode({
        username   = Config.ServerName .. ' | NX-Core',
        embeds = {{
            title       = title,
            description = description or '',
            color       = color or 3447003,
            fields      = embedFields,
            footer      = {
                text = ('NX-Core v%s | %s'):format(NXCore.version, os.date('%d/%m/%Y %H:%M:%S')),
            },
        }}
    })

    PerformHttpRequest(webhookUrl, function(code)
        if code ~= 204 and code ~= 200 then
            NXCore.Debug('warn', 'Discord webhook falhou — code=%d', code)
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

-- -----------------------------------------------
--  Hooks automaticos em eventos da framework
-- -----------------------------------------------

-- Jogador conectou
AddEventHandler('nx-core:server:onPlayerLoaded', function(src, player)
    if not Config.Discord or not Config.Discord.JoinLeave or Config.Discord.JoinLeave == '' then return end
    NXCore.Discord.Send(
        Config.Discord.JoinLeave,
        'Jogador Conectou',
        ('**%s** entrou no servidor.'):format(player.name),
        3066993,
        { License = player.license, ID = player.id }
    )
end)

-- Jogador desconectou
AddEventHandler('playerDropped', function(reason)
    local src    = source
    local player = NXCore.Players[src]
    if not player then return end
    if not Config.Discord or not Config.Discord.JoinLeave or Config.Discord.JoinLeave == '' then return end
    NXCore.Discord.Send(
        Config.Discord.JoinLeave,
        'Jogador Desconectou',
        ('**%s** saiu do servidor.'):format(player.name),
        15158332,
        { License = player.license, Razao = reason }
    )
end)

-- Export para scripts externos usarem o webhook
exports('DiscordSend', NXCore.Discord.Send)

print('^2[NX-Core]^7 Discord Logger carregado.')
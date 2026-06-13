-- ============================================================
--  NX-Core — Sistema de Logs
--  Regista acoes criticas na BD e via webhook Discord.
-- ============================================================

NXCore.Log = function(action, executorLicense, targetLicense, details)
    local detailsJson = json.encode(details or {})

    MySQL.prepare(
        [[INSERT INTO nx_logs (action, executor_license, target_license, details)
          VALUES (?, ?, ?, ?)]],
        { action, executorLicense or 'system', targetLicense or nil, detailsJson },
        function(result)
            if result then
                NXCore.Debug('info', '[Log] action=%s executor=%s target=%s',
                    action, tostring(executorLicense), tostring(targetLicense))
            end
        end
    )

    -- Webhook Discord (se configurado)
    if Config.Discord and Config.Discord.WebhookUrl and Config.Discord.WebhookUrl ~= '' then
        NXCore.SendDiscordLog(action, executorLicense, targetLicense, details)
    end
end

-- -----------------------------------------------
--  Envia log para webhook Discord
-- -----------------------------------------------
function NXCore.SendDiscordLog(action, executorLicense, targetLicense, details)
    local color = 3447003   -- azul por defeito

    local colorMap = {
        ban      = 15158332,  -- vermelho
        unban    = 3066993,   -- verde
        setstaff = 10181046,  -- roxo
        remstaff = 15105570,  -- laranja
        giveitem = 3447003,   -- azul
        givemoney = 3447003,
        setjob   = 1752220,   -- ciano
        kick     = 15105570,
    }

    color = colorMap[action] or color

    local fields = {}
    for k, v in pairs(details or {}) do
        fields[#fields + 1] = {
            name   = tostring(k),
            value  = tostring(v),
            inline = true,
        }
    end

    local payload = json.encode({
        embeds = {{
            title       = ('[NX-Core] %s'):format(action:upper()),
            color       = color,
            fields      = fields,
            footer      = { text = Config.ServerName },
            timestamp   = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        }}
    })

    PerformHttpRequest(Config.Discord.WebhookUrl, function(code, _, headers)
        NXCore.Debug('info', 'Discord webhook — action=%s status=%d', action, code)
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

-- -----------------------------------------------
--  Export para scripts externos
-- -----------------------------------------------
exports('Log', NXCore.Log)

print('^2[NX-Core]^7 Sistema de Logs carregado.')
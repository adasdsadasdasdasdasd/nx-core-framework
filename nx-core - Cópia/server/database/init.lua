-- ============================================================
--  NX-Core — Database Init
--  Valida a ligação à base de dados e regista o handler
--  de carregamento de jogadores ao conectar.
-- ============================================================

-- -----------------------------------------------
--  Testa a ligação à BD assim que o recurso arranca
-- -----------------------------------------------
AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    MySQL.query('SELECT 1 AS connected', {}, function(result)
        if result and result[1] then
            print('^2[NX-Core]^7 Ligação à base de dados confirmada.')
        else
            print('^1[NX-Core]^7 ERRO: Não foi possível ligar à base de dados! Verifica o mysql_connection_string.')
        end
    end)

    -- Valida existência das tabelas críticas
    local tables = {
        'nx_players', 'nx_player_positions', 'nx_player_metadata',
        'nx_player_money', 'nx_player_jobs', 'nx_staff'
    }
    for _, tbl in ipairs(tables) do
        MySQL.scalar('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?',
        { tbl },
        function(count)
            if (count or 0) == 0 then
                print(('^1[NX-Core]^7 AVISO: Tabela "%s" não encontrada! Importa o init.sql.'):format(tbl))
            else
                NXCore.Debug('info', 'Tabela "%s" verificada com sucesso.', tbl)
            end
        end)
    end
end)

print('^2[NX-Core]^7 Database Init carregado.')
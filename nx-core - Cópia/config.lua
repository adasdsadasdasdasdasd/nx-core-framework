-- ============================================================
--  NX-Core — Configuração Global (Shared)
--  Carregado em ambos os ambientes: client e server.
-- ============================================================

Config = Config or {}

-- -----------------------------------------------
--  IDENTIDADE DO SERVIDOR
-- -----------------------------------------------
Config.ServerName    = 'NX Roleplay'
Config.ServerVersion = '1.0.0'
Config.Locale        = 'pt'

-- -----------------------------------------------
--  SPAWN PADRÃO (usado por scripts externos)
-- -----------------------------------------------
Config.DefaultSpawn = {
    x       = -269.4,
    y       = -955.3,
    z       = 31.2,
    heading = 205.0,
}

-- -----------------------------------------------
--  CONFIGURAÇÕES DE PERSONAGEM
-- -----------------------------------------------
Config.MaxCharacters = 1   -- Máximo de personagens por jogador (expansível)

-- -----------------------------------------------
--  TEMPO / METEOROLOGIA
-- -----------------------------------------------
Config.Time = {
    StartHour       = 10,
    StartMinute     = 0,
    Ratio           = 2,             -- 2x velocidade real
    Frozen          = false,
    DefaultWeather  = 'EXTRASUNNY',
}

-- -----------------------------------------------
--  ECONOMIA
-- -----------------------------------------------
Config.UnemployedSalary = 150        -- salario minimo para desempregados
Config.SalaryInterval   = 30         -- minutos entre cada pagamento de salario

-- -----------------------------------------------
--  DISCORD WEBHOOKS
--  Deixa em '' para desativar
-- -----------------------------------------------
Config.Discord = {
    WebhookUrl  = '',   -- webhook geral (logs de ban, staff, etc.)
    JoinLeave   = '',   -- webhook de entradas/saidas de jogadores
}

-- -----------------------------------------------
--  HIERARQUIA DE CARGOS STAFF (ordem crescente de poder)
-- -----------------------------------------------
Config.StaffRanks = {
    trial        = 1,
    support      = 2,
    suporte      = 2,   -- alias PT
    mod          = 3,
    moderador    = 3,   -- alias PT
    admin        = 4,
    administrador = 4,  -- alias PT
    developer    = 5,
    dev          = 5,   -- alias PT
    ['co-owner'] = 6,
    owner        = 7,
    dono         = 7,   -- alias PT
}

-- -----------------------------------------------
--  PERMISSÕES MÍNIMAS POR COMANDO
--  Cada comando requer cargo >= ao definido abaixo.
-- -----------------------------------------------
Config.CommandPermissions = {
    -- Admin/Owner exclusivos
    setstaff  = 'co-owner',
    remstaff  = 'co-owner',
    -- Staff geral
    noclip    = 'mod',
    nc        = 'mod',
    revive    = 'mod',
    tpto      = 'mod',
    tpm       = 'mod',
    bring     = 'mod',
    openinv   = 'mod',
    clearinv  = 'mod',
    car       = 'mod',
    dv        = 'mod',
    fix       = 'mod',
    giveitem  = 'admin',
    givemoney = 'admin',
    setjob    = 'admin',
}

-- -----------------------------------------------
--  RATE-LIMITING (proteção anti-spam de eventos)
-- -----------------------------------------------
Config.RateLimit = {
    globalCooldown  = 500,   -- ms entre triggers do mesmo evento por jogador
    commandCooldown = 1000,  -- ms entre execuções de comandos por jogador
}

-- -----------------------------------------------
--  DEBUG
-- -----------------------------------------------
Config.Debug = true  -- Ativa prints detalhados na consola do servidor
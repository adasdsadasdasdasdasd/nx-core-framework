-- ============================================================
--  NX-Core — Shared Core Object
--  Disponível em client e server via variável global NXCore.
-- ============================================================

NXCore = NXCore or {}

NXCore.version     = '1.0.0'
NXCore.name        = 'NX-Core'
NXCore.initialized = false

-- -----------------------------------------------
--  Tabela de jogadores ativos (populada no server)
-- -----------------------------------------------
NXCore.Players = {}

-- -----------------------------------------------
--  Referência ao locale ativo (inicializado em shared/modules/locale.lua)
-- -----------------------------------------------
NXCore.Locale = nil

-- -----------------------------------------------
--  Debug logger centralizado
-- -----------------------------------------------
function NXCore.Debug(level, msg, ...)
    if not Config.Debug then return end
    local prefix = ('[NX-Core][%s]'):format(level:upper())
    local formatted = select('#', ...) > 0 and msg:format(...) or msg
    print(('%s %s'):format(prefix, formatted))
end

-- -----------------------------------------------
--  Retorna o timestamp atual em ms (server ou client)
-- -----------------------------------------------
function NXCore.GetTimestamp()
    return os.time() * 1000
end

print('^2[NX-Core]^7 Shared Core Object carregado — v' .. NXCore.version)
-- ============================================================
--  NX-Core — Módulo de Locale Partilhado
--  Integra com ox_lib locale para traduções dinâmicas.
-- ============================================================

-- Inicializa o sistema de locale do ox_lib
lib.locale()

-- -----------------------------------------------
--  Wrapper global: traduz e formata uma chave
-- -----------------------------------------------
function NXCore.L(key, ...)
    local ok, result = pcall(locale, key, ...)
    if ok and result then
        return result
    end
    NXCore.Debug('warn', 'Chave de locale não encontrada: %s', key)
    return key
end

NXCore.Debug('info', 'Módulo de locale inicializado (lang: %s).', Config.Locale)
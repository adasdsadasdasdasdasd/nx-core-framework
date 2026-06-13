-- ============================================================
--  NX-Core — Shared Main
--  Objeto NXCore.Shared centralizado.
--  Carregado como 'file' no fxmanifest — disponivel em
--  ambos os ambientes via LoadResourceFile + json/lua load.
-- ============================================================

NXCore.Shared = NXCore.Shared or {}

-- -----------------------------------------------
--  Acesso rapido ao objeto Shared completo
-- -----------------------------------------------
function NXCore.GetShared()
    return NXCore.Shared
end

-- -----------------------------------------------
--  Retorna todos os jobs
-- -----------------------------------------------
function NXCore.GetJobs()
    return NXCore.Shared.Jobs or {}
end

-- -----------------------------------------------
--  Retorna todos as gangues
-- -----------------------------------------------
function NXCore.GetGangs()
    return NXCore.Shared.Gangs or {}
end

-- -----------------------------------------------
--  Retorna todos os items
-- -----------------------------------------------
function NXCore.GetItems()
    return NXCore.Shared.Items or {}
end

-- -----------------------------------------------
--  Valida se um job+grade e valido
-- -----------------------------------------------
function NXCore.IsValidJobGrade(jobName, grade)
    local job = NXCore.Shared.Jobs and NXCore.Shared.Jobs[jobName]
    if not job then return false end
    return job.grades[tonumber(grade)] ~= nil
end

-- -----------------------------------------------
--  Valida se um gang+grade e valido
-- -----------------------------------------------
function NXCore.IsValidGangGrade(gangName, grade)
    local gang = NXCore.Shared.Gangs and NXCore.Shared.Gangs[gangName]
    if not gang then return false end
    return gang.grades[tonumber(grade)] ~= nil
end

-- -----------------------------------------------
--  Server-only: exports do objeto Shared
-- -----------------------------------------------
if IsDuplicityVersion then
    exports('GetShared',  NXCore.GetShared)
    exports('GetJobs',    NXCore.GetJobs)
    exports('GetGangs',   NXCore.GetGangs)
    exports('GetItems',   NXCore.GetItems)
end

NXCore.Debug('info', 'Shared Main inicializado.')
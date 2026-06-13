-- ============================================================
--  NX-Core — Server Callbacks
--  Sistema bidirecional server <-> client.
--  Uso: NXCore.Callback.Register (server) e TriggerCallback (client)
-- ============================================================

NXCore.Callback = {}
local _callbacks = {}

-- -----------------------------------------------
--  Regista um callback no servidor
-- -----------------------------------------------
function NXCore.Callback.Register(name, cb)
    if _callbacks[name] then
        NXCore.Debug('warn', 'Callback "%s" ja registado — a sobrescrever.', name)
    end
    _callbacks[name] = cb
    NXCore.Debug('info', 'Callback registado: %s', name)
end

-- -----------------------------------------------
--  Net event: cliente dispara o callback
-- -----------------------------------------------
RegisterNetEvent('nx-core:server:TriggerCallback', function(name, requestId, ...)
    local src = source

    if not NXCore.RateLimit(src, 'cb_' .. name, 300) then
        NXCore.Debug('warn', 'Callback rate-limited — src=%s name=%s', tostring(src), name)
        return
    end

    local cb = _callbacks[name]
    if not cb then
        NXCore.Debug('warn', 'Callback inexistente chamado — src=%s name=%s', tostring(src), name)
        return
    end

    -- Executa o callback; o resultado e enviado de volta ao cliente
    cb(src, function(...)
        TriggerClientEvent('nx-core:client:CallbackResponse', src, requestId, ...)
    end, ...)
end)

-- -----------------------------------------------
--  Export para scripts externos registarem callbacks
-- -----------------------------------------------
exports('RegisterCallback', NXCore.Callback.Register)

-- -----------------------------------------------
--  Callbacks built-in da framework
-- -----------------------------------------------

-- Dados do jogador
NXCore.Callback.Register('nx-core:getPlayerData', function(src, cb)
    local player = NXCore.GetPlayer(src)
    cb(player and {
        id        = player.id,
        license   = player.license,
        name      = player.name,
        firstname = player.firstname,
        lastname  = player.lastname,
        job       = player.job,
        gang      = player.gang,
        money     = player.money,
        metadata  = player.metadata,
        staffCargo = player.staffCargo,
    } or nil)
end)

-- Verifica se jogador e staff
NXCore.Callback.Register('nx-core:isStaff', function(src, cb, minCargo)
    cb(NXCore.HasPermission(src, minCargo or 'trial'))
end)

-- Verifica dinheiro suficiente
NXCore.Callback.Register('nx-core:hasMoney', function(src, cb, moneyType, amount)
    local player = NXCore.GetPlayer(src)
    if not player then return cb(false) end
    cb((player.money[moneyType] or 0) >= (tonumber(amount) or 0))
end)

-- Verifica job atual
NXCore.Callback.Register('nx-core:getJob', function(src, cb)
    local groups = NXCore.GetGroups(src)
    cb(groups and groups.job or nil)
end)

-- Verifica gang atual
NXCore.Callback.Register('nx-core:getGang', function(src, cb)
    local groups = NXCore.GetGroups(src)
    cb(groups and groups.gang or nil)
end)

print('^2[NX-Core]^7 Server Callbacks carregado.')
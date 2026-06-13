-- ============================================================
--  NX-Core — Client Callbacks
--  Permite ao cliente chamar callbacks registados no servidor.
-- ============================================================

local _pendingCallbacks = {}
local _requestCounter   = 0

-- -----------------------------------------------
--  Dispara um callback no servidor e aguarda resposta
-- -----------------------------------------------
function NXCore.Callback.Trigger(name, cb, ...)
    _requestCounter = _requestCounter + 1
    local requestId = _requestCounter

    _pendingCallbacks[requestId] = cb

    TriggerServerEvent('nx-core:server:TriggerCallback', name, requestId, ...)

    -- Timeout de seguranca: remove o callback pendente apos 10s
    SetTimeout(10000, function()
        if _pendingCallbacks[requestId] then
            NXCore.Debug('warn', 'Callback timeout — name=%s requestId=%d', name, requestId)
            _pendingCallbacks[requestId](nil)
            _pendingCallbacks[requestId] = nil
        end
    end)
end

-- -----------------------------------------------
--  Recebe a resposta do servidor
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:CallbackResponse', function(requestId, ...)
    local cb = _pendingCallbacks[requestId]
    if not cb then
        NXCore.Debug('warn', 'CallbackResponse sem handler — requestId=%d', requestId)
        return
    end
    _pendingCallbacks[requestId] = nil
    cb(...)
end)

-- -----------------------------------------------
--  Versao awaitable (Lua 5.4 coroutines)
-- -----------------------------------------------
function NXCore.Callback.Await(name, ...)
    local co      = coroutine.running()
    local result  = nil
    local args    = { ... }

    NXCore.Callback.Trigger(name, function(...)
        result = { ... }
        if co then coroutine.resume(co) end
    end, table.unpack(args))

    if result == nil then
        coroutine.yield()
    end

    return table.unpack(result or {})
end

-- -----------------------------------------------
--  Export para scripts externos
-- -----------------------------------------------
exports('TriggerCallback', NXCore.Callback.Trigger)
exports('AwaitCallback',   NXCore.Callback.Await)

NXCore.Debug('info', 'Client Callbacks carregado.')
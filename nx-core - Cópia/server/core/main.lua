-- ============================================================
--  NX-Core — Server Core Main
-- ============================================================

NXCore.Players    = {}
NXCore.RateLimits = {}

-- -----------------------------------------------
--  Rate-Limiter
-- -----------------------------------------------
function NXCore.RateLimit(source, key, cooldown)
    local src = tostring(source)
    NXCore.RateLimits[src] = NXCore.RateLimits[src] or {}
    local now      = os.time() * 1000
    local lastTime = NXCore.RateLimits[src][key] or 0
    local elapsed  = now - lastTime
    if elapsed < (cooldown or Config.RateLimit.globalCooldown) then
        NXCore.Debug('warn', 'RateLimit — src=%s key=%s elapsed=%dms', src, key, elapsed)
        return false
    end
    NXCore.RateLimits[src][key] = now
    return true
end

-- -----------------------------------------------
--  Limpa ao desconectar (apenas estado, SEM save — save e em data.lua)
-- -----------------------------------------------
AddEventHandler('playerDropped', function(reason)
    local src = tostring(source)
    NXCore.RateLimits[src] = nil
    NXCore.Debug('info', 'Jogador %s desconectou. Razao: %s', src, reason)
end)

-- -----------------------------------------------
--  Getters
-- -----------------------------------------------
function NXCore.GetPlayer(source)
    return NXCore.Players[source]
end

function NXCore.GetAllPlayers()
    return NXCore.Players
end

-- -----------------------------------------------
--  GetLicense — usa nativo otimizado do FiveM
-- -----------------------------------------------
function NXCore.GetLicense(source)
    -- GetPlayerIdentifierByType e mais rapido que iterar todos
    local id = GetPlayerIdentifierByType(source, 'license2') or
               GetPlayerIdentifierByType(source, 'license')
    if id then
        return id:gsub('^license2?:', '')
    end
    return nil
end

-- -----------------------------------------------
--  GetIdentifier generico
-- -----------------------------------------------
function NXCore.GetIdentifier(source, prefix)
    local id = GetPlayerIdentifierByType(source, prefix)
    if id then
        return id:gsub('^' .. prefix .. ':', '')
    end
    return nil
end

-- -----------------------------------------------
--  HasPermission
-- -----------------------------------------------
function NXCore.HasPermission(source, requiredCargo)
    local player = NXCore.GetPlayer(source)
    if not player then
        NXCore.Debug('warn', 'HasPermission: jogador src=%s nao encontrado.', tostring(source))
        return false
    end
    local playerRank   = Config.StaffRanks[player.staffCargo] or 0
    local requiredRank = Config.StaffRanks[requiredCargo]     or 999
    NXCore.Debug('info', 'HasPermission — src=%s cargo=%s rank=%d required=%d',
        tostring(source), tostring(player.staffCargo), playerRank, requiredRank)
    return playerRank >= requiredRank
end

-- -----------------------------------------------
--  NotifyStaff
-- -----------------------------------------------
function NXCore.NotifyStaff(title, message, notifyType)
    for src, player in pairs(NXCore.Players) do
        if player.staffCargo then
            TriggerClientEvent('nx-core:client:Notify', src, title, message, notifyType or 'inform')
        end
    end
end

-- -----------------------------------------------
--  Exports principais
-- -----------------------------------------------
exports('GetPlayer',      NXCore.GetPlayer)
exports('GetAllPlayers',  NXCore.GetAllPlayers)
exports('GetLicense',     NXCore.GetLicense)
exports('HasPermission',  NXCore.HasPermission)
exports('RateLimit',      NXCore.RateLimit)
exports('NotifyStaff',    NXCore.NotifyStaff)

print('^2[NX-Core]^7 Server Core Main carregado.')
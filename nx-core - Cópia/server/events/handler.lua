-- ============================================================
--  NX-Core — Server Event Handler (CORRIGIDO: sem auto-save duplicado)
-- ============================================================

-- -----------------------------------------------
--  Coordenadas do alvo para /tpto
-- -----------------------------------------------
RegisterNetEvent('nx-core:server:SendCoordsToStaff', function(staffSrc, coords)
    local src = source
    if not coords or type(coords) ~= 'table' then return end
    local staff = NXCore.GetPlayer(staffSrc)
    if not staff then return end
    if not NXCore.HasPermission(staffSrc, Config.CommandPermissions.tpto) then return end
    TriggerClientEvent('nx-core:client:TeleportTo', staffSrc, vector3(coords.x, coords.y, coords.z), coords.heading)
    NXCore.Debug('info', 'SendCoordsToStaff — staff=%s from=%s', tostring(staffSrc), tostring(src))
end)

-- -----------------------------------------------
--  Coords do staff para /bring
-- -----------------------------------------------
RegisterNetEvent('nx-core:server:SendCoordsForBring', function(targetId, coords)
    local src = source
    if not coords or type(coords) ~= 'table' then return end
    if not NXCore.HasPermission(src, Config.CommandPermissions.bring) then return end
    local target = NXCore.GetPlayer(targetId)
    if not target then return end
    TriggerClientEvent('nx-core:client:TeleportTo', targetId, vector3(coords.x, coords.y, coords.z), coords.heading)
    NXCore.Debug('info', 'SendCoordsForBring — staff=%s -> target=%s', tostring(src), tostring(targetId))
end)

-- -----------------------------------------------
--  ForceSave (rate-limited)
-- -----------------------------------------------
RegisterNetEvent('nx-core:server:ForceSave', function()
    local src = source
    if not NXCore.RateLimit(src, 'ForceSave', 30000) then return end
    local player = NXCore.GetPlayer(src)
    if not player then return end
    NXCore.SavePlayer(src, function(success)
        NXCore.Debug('info', 'ForceSave — src=%s success=%s', tostring(src), tostring(success))
    end)
end)

-- -----------------------------------------------
--  Hooks de log para eventos da framework
-- -----------------------------------------------
AddEventHandler('nx-core:server:onPlayerLoaded', function(src, player)
    NXCore.Debug('info', 'Hook onPlayerLoaded — src=%s id=%d', tostring(src), player.id)
end)

AddEventHandler('nx-core:server:onPlayerUnloaded', function(src, player)
    NXCore.Debug('info', 'Hook onPlayerUnloaded — src=%s id=%s',
        tostring(src), tostring(player and player.id or 'N/A'))
end)

AddEventHandler('nx-core:server:onJobSet', function(src, job)
    NXCore.Debug('info', 'Hook onJobSet — src=%s job=%s grade=%s',
        tostring(src), job.name, tostring(job.grade))
end)

-- -----------------------------------------------
--  Export NotifyStaff (definido no core mas exportado aqui tambem)
-- -----------------------------------------------
exports('NotifyStaff', NXCore.NotifyStaff)

print('^2[NX-Core]^7 Event Handler carregado.')
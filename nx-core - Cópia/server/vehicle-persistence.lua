-- ============================================================
--  NX-Core — Vehicle Persistence (Server)
--  Guarda e restaura veiculos spawned em caso de restart
--  ou delecao acidental pelo engine do GTA/FiveM.
--  Requer tabela nx_vehicles na BD (ver init.sql).
-- ============================================================

-- -----------------------------------------------
--  Regista um veiculo como persistente
-- -----------------------------------------------
function NXCore.RegisterPersistentVehicle(netId, plate, model, ownerId, coords, heading, mods)
    if not netId or not plate then
        NXCore.Debug('warn', 'RegisterPersistentVehicle: netId ou plate em falta.')
        return
    end

    plate = plate:gsub('%s+', ''):upper()

    MySQL.prepare(
        [[INSERT INTO nx_vehicles (net_id, plate, model, owner_id, x, y, z, heading, mods, spawned)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
          ON DUPLICATE KEY UPDATE
            net_id  = VALUES(net_id),
            model   = VALUES(model),
            x       = VALUES(x),
            y       = VALUES(y),
            z       = VALUES(z),
            heading = VALUES(heading),
            mods    = VALUES(mods),
            spawned = 1]],
        {
            netId,
            plate,
            tostring(model),
            ownerId or nil,
            coords.x, coords.y, coords.z,
            heading or 0.0,
            json.encode(mods or {}),
        },
        function(result)
            NXCore.Debug('info', 'Veiculo registado como persistente — plate=%s netId=%s', plate, tostring(netId))
        end
    )
end

-- -----------------------------------------------
--  Remove registo de persistencia (ao apagar o veiculo)
-- -----------------------------------------------
function NXCore.UnregisterPersistentVehicle(plate)
    if not plate then return end
    plate = plate:gsub('%s+', ''):upper()

    MySQL.prepare(
        'UPDATE nx_vehicles SET spawned = 0, net_id = NULL WHERE plate = ?',
        { plate },
        function()
            NXCore.Debug('info', 'Veiculo removido da persistencia — plate=%s', plate)
        end
    )
end

-- -----------------------------------------------
--  Ao arrancar o recurso: marca todos como nao-spawned
--  (server foi reiniciado, veiculos foram perdidos)
-- -----------------------------------------------
AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    MySQL.query('UPDATE nx_vehicles SET spawned = 0, net_id = NULL', {}, function(result)
        NXCore.Debug('info', 'Vehicle persistence reset no arranque do recurso.')
    end)
end)

-- -----------------------------------------------
--  Net event: cliente regista veiculo apos spawn
-- -----------------------------------------------
RegisterNetEvent('nx-core:server:RegisterVehicle', function(data)
    local src = source
    if not NXCore.RateLimit(src, 'RegisterVehicle', 2000) then return end

    if not data or not data.plate or not data.netId then
        NXCore.Debug('warn', 'RegisterVehicle: dados invalidos de src=%s', tostring(src))
        return
    end

    local player = NXCore.GetPlayer(src)
    if not player then return end

    NXCore.RegisterPersistentVehicle(
        data.netId,
        data.plate,
        data.model,
        player.id,
        data.coords or vector3(0, 0, 0),
        data.heading or 0.0,
        data.mods
    )
end)

-- -----------------------------------------------
--  Net event: cliente notifica delecao de veiculo
-- -----------------------------------------------
RegisterNetEvent('nx-core:server:UnregisterVehicle', function(plate)
    local src = source
    if not NXCore.RateLimit(src, 'UnregisterVehicle', 1000) then return end
    if not plate then return end
    NXCore.UnregisterPersistentVehicle(plate)
end)

-- -----------------------------------------------
--  Exports
-- -----------------------------------------------
exports('RegisterPersistentVehicle',   NXCore.RegisterPersistentVehicle)
exports('UnregisterPersistentVehicle', NXCore.UnregisterPersistentVehicle)

print('^2[NX-Core]^7 Vehicle Persistence (Server) carregado.')
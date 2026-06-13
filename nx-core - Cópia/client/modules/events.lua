-- ============================================================
--  NX-Core — Client Event Handlers
--  Responde a eventos do servidor e do jogo.
-- ============================================================

-- -----------------------------------------------
--  Teleporte direto (recebido do servidor)
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:TeleportTo', function(coords, heading)
    if not coords then return end
    NXCore.TeleportTo(coords, heading)
    NXCore.Notify(Config.ServerName, NXCore.L('teleported'), 'success')
end)

-- -----------------------------------------------
--  Revive (recebido do servidor)
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:Revive', function()
    NXCore.ReviveLocal()
    NXCore.Notify(Config.ServerName, NXCore.L('revived'), 'success')
end)

-- -----------------------------------------------
--  Apagar veículo mais próximo (chamado pelo server)
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:DeleteVehicle', function()
    local result = NXCore.DeleteCurrentVehicle()
    if result then
        NXCore.Notify(Config.ServerName, NXCore.L('vehicle_deleted'), 'success')
    end
end)

-- -----------------------------------------------
--  Reparar veículo atual
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:FixVehicle', function()
    local result = NXCore.FixCurrentVehicle()
    if result then
        NXCore.Notify(Config.ServerName, NXCore.L('vehicle_fixed'), 'success')
    end
end)

-- -----------------------------------------------
--  Spawn de veículo por modelo
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:SpawnVehicle', function(model)
    if not model then return end

    local hash = GetHashKey(model)
    if not IsModelValid(hash) then
        NXCore.Notify(Config.ServerName, 'Modelo inválido: ' .. model, 'error')
        return
    end

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 5000 then
            NXCore.Notify(Config.ServerName, 'Timeout ao carregar modelo.', 'error')
            return
        end
    end

    local coords = NXCore.GetPlayerCoords()
    local ped    = NXCore.GetPed()
    local heading = ped and GetEntityHeading(ped) or 0.0

    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, veh, -1)
    SetVehicleEngineOn(veh, true, true, false)
    SetModelAsNoLongerNeeded(hash)

    NXCore.Notify(Config.ServerName, NXCore.L('vehicle_spawned', model), 'success')
    NXCore.Debug('info', 'Veículo "%s" gerado com sucesso.', model)
end)

-- -----------------------------------------------
--  Notificação genérica vinda do servidor
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:Notify', function(title, message, notifyType, duration)
    NXCore.Notify(title, message, notifyType, duration)
end)

-- -----------------------------------------------
--  Responde ao pedido de coordenadas (/tpto)
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:RequestCoords', function(staffSrc)
    local ped     = NXCore.GetPed()
    if not ped then return end
    local coords  = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    TriggerServerEvent('nx-core:server:SendCoordsToStaff', staffSrc, {
        x = coords.x, y = coords.y, z = coords.z, heading = heading
    })
end)

-- -----------------------------------------------
--  Envia coords do staff para bring de alvo
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:RequestCoordsForBring', function(staffSrc, targetId)
    local ped    = NXCore.GetPed()
    if not ped then return end
    local coords = GetEntityCoords(ped)
    TriggerServerEvent('nx-core:server:SendCoordsForBring', targetId, {
        x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped)
    })
end)

-- -----------------------------------------------
--  Teleporta para o waypoint (/tpm)
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:TeleportToWaypoint', function()
    local wp = GetFirstBlipInfoId(8)
    if not DoesBlipExist(wp) then
        NXCore.Notify(Config.ServerName, 'Nenhum waypoint definido no mapa.', 'error')
        return
    end
    local coords = GetBlipInfoIdCoord(wp)
    -- Ajuste de altitude via raycasting
    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, true)
    local finalZ = found and groundZ or coords.z
    NXCore.TeleportTo(vector3(coords.x, coords.y, finalZ + 1.0), nil)
    NXCore.Notify(Config.ServerName, NXCore.L('teleported'), 'success')
end)

NXCore.Debug('info', 'Client event handlers registados.')


-- ============================================================
--  NX-Core — Client Functions
--  Funções utilitárias client-side reutilizáveis.
-- ============================================================

-- -----------------------------------------------
--  Notificação simples via ox_lib
-- -----------------------------------------------
function NXCore.Notify(title, description, notifyType, duration)
    lib.notify({
        title       = title or Config.ServerName,
        description = description or '',
        type        = notifyType or 'inform',
        duration    = duration or 4000,
    })
end

-- -----------------------------------------------
--  Obtém o ped do jogador local com validação
-- -----------------------------------------------
function NXCore.GetPed()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        NXCore.Debug('warn', 'GetPed: ped inválido.')
        return nil
    end
    return ped
end

-- -----------------------------------------------
--  Obtém a posição atual do jogador
-- -----------------------------------------------
function NXCore.GetPlayerCoords()
    local ped = NXCore.GetPed()
    if not ped then return vector3(0, 0, 0) end
    return GetEntityCoords(ped, true)
end

-- -----------------------------------------------
--  Teleporta o jogador para coordenadas específicas
-- -----------------------------------------------
function NXCore.TeleportTo(coords, heading)
    local ped = NXCore.GetPed()
    if not ped then return end
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    if heading then
        SetEntityHeading(ped, heading)
    end
    NXCore.Debug('info', 'Teleportado para X=%.1f Y=%.1f Z=%.1f', coords.x, coords.y, coords.z)
end

-- -----------------------------------------------
--  Revive o ped local (restaura saúde e armadura)
-- -----------------------------------------------
function NXCore.ReviveLocal()
    local ped = NXCore.GetPed()
    if not ped then return end
    NetworkResurrectLocalPlayer(0.0, 0.0, 0.0, 0.0, true, false)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    NXCore.Debug('info', 'Jogador local revivido.')
end

-- -----------------------------------------------
--  Apaga o veículo do jogador
-- -----------------------------------------------
function NXCore.DeleteCurrentVehicle()
    local ped = NXCore.GetPed()
    if not ped then return end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        veh = GetVehiclePedIsIn(ped, true)
    end
    if veh ~= 0 and DoesEntityExist(veh) then
        DeleteEntity(veh)
        NXCore.Debug('info', 'Veículo apagado.')
        return true
    end
    return false
end

-- -----------------------------------------------
--  Repara o veículo atual do jogador
-- -----------------------------------------------
function NXCore.FixCurrentVehicle()
    local ped = NXCore.GetPed()
    if not ped then return false end
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return false end
    SetVehicleFixed(veh)
    SetVehicleDeformationFixed(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleDirtLevel(veh, 0.0)
    NXCore.Debug('info', 'Veículo reparado.')
    return true
end

NXCore.Debug('info', 'Client functions carregadas.')
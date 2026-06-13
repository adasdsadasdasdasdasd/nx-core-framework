-- ============================================================
--  NX-Core — Vehicle Persistence (Client)
--  Deteta veiculos spawned/deletados e notifica o servidor.
--  Tambem restaura veiculos persistentes apos restart.
-- ============================================================

local trackedVehicles = {}   -- [vehHandle] = { plate, netId, model }

-- -----------------------------------------------
--  Helper: obtem dados do veiculo
-- -----------------------------------------------
local function getVehicleData(veh)
    if not DoesEntityExist(veh) then return nil end
    local plate   = GetVehicleNumberPlateText(veh):gsub('%s+', ''):upper()
    local netId   = NetworkGetNetworkIdFromEntity(veh)
    local model   = GetEntityModel(veh)
    local coords  = GetEntityCoords(veh)
    local heading = GetEntityHeading(veh)
    return {
        plate   = plate,
        netId   = netId,
        model   = model,
        coords  = { x = coords.x, y = coords.y, z = coords.z },
        heading = heading,
    }
end

-- -----------------------------------------------
--  Regista veiculo no servidor ao entrar
-- -----------------------------------------------
local function onVehicleEnter(veh)
    if not DoesEntityExist(veh) then return end
    if trackedVehicles[veh] then return end  -- ja rastreado

    local data = getVehicleData(veh)
    if not data or data.plate == '' then return end

    trackedVehicles[veh] = data

    TriggerServerEvent('nx-core:server:RegisterVehicle', data)
    NXCore.Debug('info', 'Veiculo registado — plate=%s netId=%s', data.plate, tostring(data.netId))
end

-- -----------------------------------------------
--  Notifica servidor ao sair do veiculo
-- -----------------------------------------------
local function onVehicleExit(veh)
    local tracked = trackedVehicles[veh]
    if not tracked then return end

    -- Atualiza posicao ao sair
    if DoesEntityExist(veh) then
        local coords  = GetEntityCoords(veh)
        local heading = GetEntityHeading(veh)
        TriggerServerEvent('nx-core:server:RegisterVehicle', {
            plate   = tracked.plate,
            netId   = tracked.netId,
            model   = tracked.model,
            coords  = { x = coords.x, y = coords.y, z = coords.z },
            heading = heading,
        })
    end
end

-- -----------------------------------------------
--  Loop: deteta entrar/sair de veiculos
-- -----------------------------------------------
local lastVehicle = 0

CreateThread(function()
    while true do
        Wait(1000)

        if not NXCore.IsPlayerLoaded() then goto continue end

        local ped = NXCore.GetPed()
        if not ped then goto continue end

        local currentVeh = GetVehiclePedIsIn(ped, false)

        if currentVeh ~= 0 and currentVeh ~= lastVehicle then
            -- Entrou num veiculo
            onVehicleEnter(currentVeh)
            lastVehicle = currentVeh

        elseif currentVeh == 0 and lastVehicle ~= 0 then
            -- Saiu do veiculo
            onVehicleExit(lastVehicle)
            lastVehicle = 0
        end

        ::continue::
    end
end)

-- -----------------------------------------------
--  Deteta veiculo deletado enquanto dentro
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(3000)

        for veh, data in pairs(trackedVehicles) do
            if not DoesEntityExist(veh) then
                NXCore.Debug('warn', 'Veiculo deletado detetado — plate=%s', data.plate)
                TriggerServerEvent('nx-core:server:UnregisterVehicle', data.plate)
                trackedVehicles[veh] = nil
            end
        end
    end
end)

-- -----------------------------------------------
--  Limpa veiculos rastreados ao fazer logout
-- -----------------------------------------------
AddEventHandler('nx-core:client:onPlayerUnloaded', function()
    trackedVehicles = {}
    lastVehicle     = 0
    NXCore.Debug('info', 'Vehicle persistence limpa no logout.')
end)

NXCore.Debug('info', 'Vehicle Persistence (Client) carregado.')
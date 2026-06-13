-- ============================================================
--  NX-Core — Client Core Main
--  Ponto de entrada do cliente. Gere o estado local do jogador.
-- ============================================================

local playerLoaded  = false
local localPlayer   = {}   -- Dados do jogador local (sincronizados do server)
local noclipActive  = false

-- -----------------------------------------------
--  Expõe os dados do jogador local para scripts externos
-- -----------------------------------------------
function NXCore.GetLocalPlayer()
    return localPlayer
end

function NXCore.IsPlayerLoaded()
    return playerLoaded
end

-- -----------------------------------------------
--  Recebe os dados do jogador do servidor após autenticação
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:PlayerLoaded', function(data)
    if not data or type(data) ~= 'table' then
        NXCore.Debug('error', 'PlayerLoaded recebeu dados inválidos.')
        return
    end

    localPlayer   = data
    playerLoaded  = true

    NXCore.Debug('info', 'Jogador carregado — ID Fixo: %s | Nome: %s', tostring(data.id), tostring(data.name))
    TriggerEvent('nx-core:client:onPlayerLoaded', localPlayer)
end)

-- -----------------------------------------------
--  Limpa dados locais ao desconectar/fazer logout
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:PlayerUnloaded', function()
    NXCore.Debug('info', 'Sessão do jogador terminada no cliente.')
    playerLoaded = false
    localPlayer  = {}
    TriggerEvent('nx-core:client:onPlayerUnloaded')
end)

-- -----------------------------------------------
--  Sincroniza dados parciais (ex: job, dinheiro)
-- -----------------------------------------------
RegisterNetEvent('nx-core:client:SyncData', function(key, value)
    if not playerLoaded then return end
    if key and value ~= nil then
        localPlayer[key] = value
        NXCore.Debug('info', 'SyncData recebido — chave: %s', tostring(key))
        TriggerEvent('nx-core:client:onDataSync', key, value)
    end
end)

-- -----------------------------------------------
--  Export: dados do jogador para scripts externos
-- -----------------------------------------------
exports('GetPlayerData',   NXCore.GetLocalPlayer)
exports('IsPlayerLoaded',  NXCore.IsPlayerLoaded)

-- -----------------------------------------------
--  Informa o servidor que o client está pronto
-- -----------------------------------------------
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    NXCore.Debug('info', 'Client Core iniciado. A solicitar dados ao servidor...')
    TriggerServerEvent('nx-core:server:RequestPlayerData')
end)

print('^2[NX-Core]^7 Client Core Main carregado.')
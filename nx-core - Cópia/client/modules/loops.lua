-- ============================================================
--  NX-Core — Client Loops (CORRIGIDO: noclip sem tremido)
-- ============================================================

local POSITION_SAVE_INTERVAL = 60000
local lastPositionSave = 0

-- -----------------------------------------------
--  Loop de posicao
-- -----------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)
        if NXCore.IsPlayerLoaded() then
            local now = GetGameTimer()
            if (now - lastPositionSave) >= POSITION_SAVE_INTERVAL then
                lastPositionSave = now
                local coords  = NXCore.GetPlayerCoords()
                local ped     = NXCore.GetPed()
                local heading = ped and GetEntityHeading(ped) or 0.0
                TriggerServerEvent('nx-core:server:SavePosition', {
                    x = coords.x, y = coords.y, z = coords.z, heading = heading,
                })
                NXCore.Debug('info', 'Posicao enviada ao servidor.')
            end
        end
    end
end)

-- -----------------------------------------------
--  NoClip
-- -----------------------------------------------
local noclipEnabled = false
local noclipSpeed   = 1.0

function NXCore.ToggleNoclip(state)
    noclipEnabled = state
    local ped = NXCore.GetPed()
    if ped then
        if not state then
            SetEntityCollision(ped, true, true)
            FreezeEntityPosition(ped, false)
        end
    end
    NXCore.Debug('info', 'NoClip %s.', state and 'ATIVADO' or 'DESATIVADO')
end

RegisterNetEvent('nx-core:client:ToggleNoclip', function(state)
    NXCore.ToggleNoclip(state)
end)

CreateThread(function()
    while true do
        if noclipEnabled then
            Wait(0)
            local ped = NXCore.GetPed()
            if not ped then goto continue end

            SetEntityCollision(ped, false, false)
            FreezeEntityPosition(ped, false)

            local camRot  = GetGameplayCamRot(2)
            local forward = GetEntityForwardVector(ped)
            local right   = {
                x = math.cos(math.rad(camRot.z - 90.0)),
                y = math.sin(math.rad(camRot.z - 90.0)),
            }
            local coords  = GetEntityCoords(ped)

            local dx, dy, dz = 0.0, 0.0, 0.0
            local speed = noclipSpeed

            if IsControlPressed(0, 21) then speed = speed * 5.0 end  -- Shift boost

            if IsControlPressed(0, 32) then dx = dx + forward.x * speed; dy = dy + forward.y * speed end
            if IsControlPressed(0, 33) then dx = dx - forward.x * speed; dy = dy - forward.y * speed end
            if IsControlPressed(0, 34) then dx = dx - right.x  * speed; dy = dy - right.y  * speed end
            if IsControlPressed(0, 35) then dx = dx + right.x  * speed; dy = dy + right.y  * speed end
            if IsControlPressed(0, 44) then dz = dz + speed end
            if IsControlPressed(0, 38) then dz = dz - speed end

            -- Apenas SetEntityCoordsNoOffset (sem SetEntityVelocity — evita tremido)
            if dx ~= 0.0 or dy ~= 0.0 or dz ~= 0.0 then
                SetEntityCoordsNoOffset(
                    ped,
                    coords.x + dx * 0.1,
                    coords.y + dy * 0.1,
                    coords.z + dz * 0.1,
                    true, true, true
                )
            end
        else
            Wait(500)
        end
        ::continue::
    end
end)

NXCore.Debug('info', 'Client loops iniciados.')
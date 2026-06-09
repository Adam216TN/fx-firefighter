local isWalksetApplied = false
local minigunHash = GetHashKey("WEAPON_CARBINERIFLE")
local nextCheck = 0
local isFiring = false

function RotationToFace(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local dz = pos2.z - pos1.z

    local dist_ground = math.sqrt(dx*dx + dy*dy)

    local yaw = math.atan(dy,dx) * (180/math.pi)

    local pitch = math.atan(dz,dist_ground) *(180/math.pi)
    
    local roll = 0

    return yaw, pitch, roll

end

Citizen.CreateThread(function ()
    while true do
        if Has_hose then
            local playerPed = PlayerPedId()
            local currentTime = GetGameTimer()
            --SetPlayerForcedAim(PlayerId(), true)

            if not isWalksetApplied then
                isWalksetApplied = true
                GiveWeaponToPed(playerPed,minigunHash,10,false,true)
                SetCurrentPedWeapon(playerPed,minigunHash,true)
                SetPedMovementClipset(playerPed,"move_characters@michael@fire",0.2)
                nextCheck = currentTime + 1000
            end

            SetPedCurrentWeaponVisible(playerPed,false,false,true,true)

            DisablePlayerFiring(PlayerId(),true)
            DisableControlAction(0,21,true)
            DisableControlAction(0,22,true)

            if IsControlPressed(0,24) then
                if not isFiring then
                    isFiring = true
                    ResetPedMovementClipset(playerPed,0.2)
                end
                SetPlayerForcedAim(PlayerId(),true)
            else
                if isFiring then
                    isFiring = false
                    SetPlayerForcedAim(PlayerId(), false)
                    SetPedMovementClipset(playerPed,"move_characters@michael@fire",0.2)
                end
            end
            
            --[[if currentTime > nextCheck then    
                if GetPedMovementClipset(playerPed) ~= GetHashKey("move_characters@michael@fire") then
                    SetPedMovementClipset(playerPed,"move_characters@michael@fire",0.2)
                end
                nextCheck = currentTime +1000
            end]]
            
            
            --DisableControlAction(0, 24, true)
            Citizen.Wait(0)
        else
            
            if isWalksetApplied then
                local playerPed = PlayerPedId()
                SetPlayerForcedAim(PlayerId(), false)
                RemoveWeaponFromPed(playerPed, minigunHash)
                ResetPedMovementClipset(playerPed,0.2)
                RemoveClipSet("move_characters@michael@fire")
                isWalksetApplied = false
                isFiring = false
            end

            Citizen.Wait(1000)
        end
    end
    
end)

Citizen.CreateThread(function ()
    
    local hash_pipe = GetHashKey("prop_pipe_single_01")
    RequestModel(hash_pipe)
    
    local testPipe = 0

    while true do
        if Has_hose then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            local bone = GetPedBoneIndex(playerPed, 57005)
            local ptB = GetPedBoneCoords(playerPed, bone, 0.0, 0.0, 0.0)

            local hash_firetruck = GetHashKey('firetruk')
            local firetruck = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 15.0, hash_firetruck, 70)
            
            if firetruck ~= 0 then
                local ptA = GetEntityCoords(firetruck)
                local distance = #(ptA - ptB)

                local down = distance * 0.2
                
                local ptC = vector3( 
                    (ptA.x + ptB.x) * 0.5,
                    (ptA.y + ptB.y) * 0.5,
                    (ptA.z + ptB.z) * 0.5 - down
                )

                if DoesEntityExist(testPipe) then DeleteEntity(testPipe) end

                local steps = 10
                for i = 0, steps - 1 do
                    local t1 = i / steps
                    local t2 = (i + 1) / steps
                    
                    local u1 = 1 - t1
                    local u2 = 1 - t2
                    
                    
                    local pt1 = vector3(
                        u1*u1*ptA.x + 2*u1*t1*ptC.x + t1*t1*ptB.x,
                        u1*u1*ptA.y + 2*u1*t1*ptC.y + t1*t1*ptB.y,
                        u1*u1*ptA.z + 2*u1*t1*ptC.z + t1*t1*ptB.z
                    )

                    local pt2 = vector3(
                        u2*u2*ptA.x + 2*u2*t2*ptC.x + t2*t2*ptB.x,
                        u2*u2*ptA.y + 2*u2*t2*ptC.y + t2*t2*ptB.y,
                        u2*u2*ptA.z + 2*u2*t2*ptC.z + t2*t2*ptB.z
                    )

                    
                    if i == 0 and HasModelLoaded(hash_pipe) then
                        local yaw, pitch, roll = RotationToFace(pt1, pt2)

                        print("yaw: " .. yaw - 90 .. " pitch: " .. pitch)

                        testPipe = CreateObject(hash_pipe, pt1.x, pt1.y, pt1.z, false, false, false)

                        

                        --SetEntityCollision(testPipe, false, false)
                        
                        SetEntityRotation(testPipe, pitch, roll, yaw-90, 2, true)
                        FreezeEntityPosition(testPipe, true)
                    end

                    
                    DrawLine(pt1.x, pt1.y, pt1.z, pt2.x, pt2.y, pt2.z, 255, 0, 0, 255)
                end
            end
            Citizen.Wait(0)
        else
            
            if DoesEntityExist(testPipe) then DeleteEntity(testPipe) end
            Citizen.Wait(1000)
        end
    end
end)
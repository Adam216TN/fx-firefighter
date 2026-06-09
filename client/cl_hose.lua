local isWalksetApplied = false
local minigunHash = GetHashKey("WEAPON_CARBINERIFLE")
local nextCheck = 0
local isFiring = false

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

    while true do
        if Has_hose then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            local bone = GetPedBoneIndex(playerPed,57005)
            local ptA = GetPedBoneCoords(playerPed,bone,0.0,0.0,0.0)

            local hash_firetruck = GetHashKey('firetruk')
            local firetruck = GetClosestVehicle(playerCoords.x,playerCoords.y,playerCoords.z,15.0,hash_firetruck,70)
            
            if firetruck ~= 0 then
                local ptB = GetEntityCoords(firetruck)

                local down = 2.5
                
                local ptC = vector3( 
                (ptA.x + ptB.x)*0.5,
                (ptA.y + ptB.y)*0.5,
                (ptA.z + ptB.z)*0.5 - down)

                local steps = 10
                for i = 0, steps - 1 do
                    
                    local t1 = i/steps
                    local t2 = (i+1)/steps
                    
                    local u1 = 1-t1
                    local u2 = 1-t2
                    
                    local pt1 = vector(
                    u1*u1*ptA.x + 2*u1*t1*ptC.x + t1*t1*ptB.x,
                    u1*u1*ptA.y + 2*u1*t1*ptC.y + t1*t1*ptB.y,
                    u1*u1*ptA.z + 2*u1*t1*ptC.z + t1*t1*ptB.z)

                    local pt2 = vector(
                    u2*u2*ptA.x + 2*u2*t2*ptC.x + t2*t2*ptB.x,
                    u2*u2*ptA.y + 2*u2*t2*ptC.y + t2*t2*ptB.y,
                    u2*u2*ptA.z + 2*u2*t2*ptC.z + t2*t2*ptB.z)

                    DrawLine(pt1.x,pt1.y,pt1.z,pt2.x,pt2.y,pt2.z,255,0,0,255)
                end
            end
            Citizen.Wait(0)
        else
            Citizen.Wait(1000)
        end
    end
    
end)
local isWalksetApplied = false
local minigunHash = GetHashKey("WEAPON_RPG")
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

            SetPedCurrentWeaponVisible(playerPed,false,false,false,false)

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
            
            if not isFiring and currentTime > nextCheck then    
                if GetPedMovementClipset(playerPed) ~= GetHashKey("move_characters@michael@fire") then
                    SetPedMovementClipset(playerPed,"move_characters@michael@fire",0.2)
                end
                nextCheck = currentTime +1000
            end
            
            
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
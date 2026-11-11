local dictName  = "core"
local currentJet = nil
local activeRaycast = nil
local lastWaterRefresh = 0
local isShooting = false

local function ManageWaterPhysics()
    local hose_coords = GetEntityCoords(HoseObject)
    
    if activeRaycast == nil then
        local vect = GetEntityForwardVector(HoseObject)
        local destination = hose_coords + (vect * 20.0)
        activeRaycast = StartShapeTestLosProbe(
            hose_coords.x, hose_coords.y, hose_coords.z,
            destination.x, destination.y, destination.z,
            3, PlayerPedId(),7
        )
    end

    if activeRaycast ~= nil then
        local status, hit, coords, surface, entityhit = GetShapeTestResult(activeRaycast)
    
        if status == 2 then
            if hit then
                DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 0, 0, 150, false, false, 2, false, nil, nil, false)
                StopFireInRange(coords.x, coords.y, coords.z, 2.0)
            end
            activeRaycast = nil
        end
    end
end

Citizen.CreateThread(function()
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(dictName) and timeout < 500 do
        RequestNamedPtfxAsset(dictName)
        Citizen.Wait(100)
        timeout = timeout + 1
    end

    --print("[DEBUG] Modele chargee")

    while true do
        if Has_hose and HasNamedPtfxAssetLoaded(dictName) then
            if IsControlPressed(0, 25) and CurrentWater > 0 and (currentJet == nil or currentJet == 0) then
                print("[DEBUG] Entree condition start eau")
                UseParticleFxAsset(dictName)
                currentJet = StartParticleFxLoopedOnEntity(
                    "water_cannon_jet", HoseObject,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.0, false, false, false
                )
                if not isShooting then
                    isShooting = true
                    TriggerServerEvent('fx-firefighter:updateTruckState', HoldingHosePlate, 'isShootingWater', true)

                end
            elseif (not IsControlPressed(0, 25) or CurrentWater <= 0) and currentJet ~= nil then
                print("[DEBUG] Entree condition arret eau")
                StopParticleFxLooped(currentJet, 0)
                currentJet = nil
                activeRaycast = nil

                if isShooting then
                    isShooting = false
                    TriggerServerEvent('fx-firefighter:updateTruckState', HoldingHosePlate, 'isShootingWater', false)
                end
            end

            if currentJet ~= nil then
                ManageWaterPhysics()

                local currentTimer = GetGameTimer()
                if currentTimer - lastWaterRefresh >= 1000 then 
                    lastWaterRefresh = currentTimer

                    if HoldingHosePlate ~= nil then
                        TriggerServerEvent("fx-firefighter:consumeServerWater", HoldingHosePlate)
                    end
                end
            end

            Citizen.Wait(0)
        else
            if currentJet ~= nil then
                StopParticleFxLooped(currentJet, 0)
                currentJet = nil
                activeRaycast = nil
            end
            Citizen.Wait(500)
        end
    end
end)


Citizen.CreateThread(function ()

    
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(dictName) and timeout < 500 do
        RequestNamedPtfxAsset(dictName)
        Citizen.Wait(100)
        timeout = timeout + 1
    end

    local currentJet = {}
    
    
    while true do

        local activeTrucks = {}
        local hasAnyActive = false

        for plate, state in pairs(TrucksClient) do
            hasAnyActive = true

            if state.isHoseOut then
                if state.isShootingWater then
                    activeTrucks[plate] = {isShooting = true, hoseid = state.hoseNetId}
                else
                    activeTrucks[plate] = {isShooting = false, hoseid = state.hoseNetId}
                end
            else
                activeTrucks[plate] = {isShooting = false, hoseid = nil}
            
            end

        end

        for plate, data in pairs(activeTrucks) do
            if data.hoseid == nil then
                if currentJet[plate] ~= nil then
                    StopParticleFxLooped(currentJet[plate], 0)
                    currentJet[plate] = nil
                end
            else
                if not Has_hose or HoldingHosePlate ~= plate then
                    if data.isShooting then
                        if currentJet[plate] == nil then
                            
                            local noozle = NetToObj(data.hoseid)
                            if DoesEntityExist(noozle) then
                                UseParticleFxAssetNextCall(dictName)
                                    currentJet[plate] = StartParticleFxLoopedOnEntity(
                                "water_cannon_jet", noozle,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                1.0, false, false, false
                                )
                            end
                        end
                    else
                        if currentJet[plate] ~= nil then
                            StopParticleFxLooped(currentJet[plate], 0)
                            currentJet[plate] = nil
                        end
                    
                    end
                end
            
            end

        end

        if hasAnyActive then
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end    
end)
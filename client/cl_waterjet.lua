local dictName  = "core"
local currentJet = nil
local activeRaycast = nil
local lastWaterRefresh = 0

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

    print("[DEBUG] Modele chargee")

    while true do
        if Has_hose and HasNamedPtfxAssetLoaded(dictName) then
            if IsControlPressed(0, 25) and CurrentWater > 0 and (currentJet == nil or currentJet == 0) then
                print("[DEBUG] Entree condition start eau")
                UseParticleFxAsset(dictName)
                currentJet = StartNetworkedParticleFxLoopedOnEntity(
                    "water_cannon_jet", HoseObject,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.0, false, false, false
                )
            elseif (not IsControlPressed(0, 25) or CurrentWater <= 0) and currentJet ~= nil then
                print("[DEBUG] Entree condition arret eau")
                StopParticleFxLooped(currentJet, 0)
                currentJet = nil
                activeRaycast = nil
            end

            if currentJet ~= nil then
                ManageWaterPhysics()

                local currentTimer = GetGameTimer()
                if currentTimer - lastWaterRefresh >= 1000 then 
                    lastWaterRefresh = currentTimer

                    local truckEntity = GetActiveHoseTruck()
                    if truckEntity ~= 0 and DoesEntityExist(truckEntity) then
                        local activePlate = GetVehicleNumberPlateText(truckEntity)
                        TriggerServerEvent("fx-firefighter:consumeServerWater", activePlate)
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
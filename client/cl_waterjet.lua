local dictName  = "core"
local currentJet = nil

Citizen.CreateThread(function()
    -- Chargement une seule fois
    local timeout = 0
    while not HasNamedPtfxAssetLoaded(dictName) and timeout < 500 do
        RequestNamedPtfxAsset(dictName)
        Citizen.Wait(100)
        timeout = timeout + 1
    end

    print("[DEBUG] Modele chargee")

    while true do
        if Has_hose and HasNamedPtfxAssetLoaded(dictName) then
            --print("[DEBUG] Entree premiere condition")
            if IsControlPressed(0,25) and CurrentWater > 0 and (currentJet == nil or currentJet == 0) then
                
                print("[DEBUG] Entree condition start eau")
                UseParticleFxAsset(dictName)
                print("[DEBUG] Use approved")
                currentJet = StartNetworkedParticleFxLoopedOnEntity(
                    "water_cannon_jet", HoseObject,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.0, false, false, false
                )
                print("[DEBUG] Start water work")
                print("[DEBUG] current_jet : " .. currentJet)
            elseif (not IsControlPressed(0,25) or CurrentWater <= 0) and currentJet ~= nil then
                print("[DEBUG] Entree condition arret eau")
                StopParticleFxLooped(currentJet, 0)
                currentJet = nil
                
            end

            Citizen.Wait(0)
        else
            if currentJet ~= nil then
                StopParticleFxLooped(currentJet, 0)
                currentJet = nil
            end
            Citizen.Wait(500)
        end
    end
end)
--print("[DEBUG SYSTEM] Le fichier client.lua est bien charge et actif !")

local panelOpen = false
local lastNotif = nil
local currentPanelPlate = nil
local lastPanelRefresh = 0

function GetCurrentTruckPlate()
    return currentPanelPlate
end

RegisterNetEvent('fx-firefighter:setClientWater')
AddEventHandler('fx-firefighter:setClientWater', function(waterServ, plateServ)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local hash_firetruck = GetHashKey('firetruk')
        
    local closest_firetruck = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 15.0, hash_firetruck, 70)

    if closest_firetruck ~= 0 then
        local myPlate = GetVehicleNumberPlateText(closest_firetruck)

        if myPlate == plateServ then
            CurrentWater = waterServ
        end
    end
end)

RegisterCommand('checkwater', function(source)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        if GetEntityModel(vehicle) == GetHashKey('firetruk') then
            SetNotificationTextEntry("STRING")
            AddTextComponentString("Tank : " .. CurrentWater .. "/100 litres")
            DrawNotification(false, false)
        else
            SetNotificationTextEntry("STRING")
            AddTextComponentString("That's not a firetruck")
            DrawNotification(false, false)
        end
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString("You are on foot")
        DrawNotification(false, false)
    end
end, false)


local testObj = 0

RegisterCommand("testpipe", function()
    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    
    if DoesEntityExist(testObj) then DeleteEntity(testObj) end
    
    local hash = GetHashKey("prop_pipe_firefighter")
    RequestModel(hash)
    while not HasModelLoaded(hash) do Citizen.Wait(0) end
    
    testObj = CreateObject(hash, pos.x + 3.0, pos.y, pos.z + 1.0, true, false, false)
    FreezeEntityPosition(testObj, true)
    print("Handle : " .. testObj)
end, false)


Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local hash_firetruck = GetHashKey('firetruk')
        
        local closest_firetruck = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 15.0, hash_firetruck, 70)
        
        if closest_firetruck ~= 0 then
            local myPlate = GetVehicleNumberPlateText(closest_firetruck)
            local boneIndexRight = GetEntityBoneIndexByName(closest_firetruck,"wheel_rr")
            local panelRightCoords = GetWorldPositionOfEntityBone(closest_firetruck,boneIndexRight)
            --DrawMarker(28, panelRightCoords.x-1, panelRightCoords.y+2, panelRightCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 0, 255, 0, 150, false, false, 2, false, nil, nil, false)
            local heading = GetEntityHeading(closest_firetruck)
            local rad = math.rad(heading)

            local offsetX = 0.0
            local offsetY = 2.0

            local rotatedX = offsetX * math.cos(rad) - offsetY * math.sin(rad)
            local rotatedY = offsetX * math.sin(rad) + offsetY * math.cos(rad)

            local finalPanelCoords = vector3(
                panelRightCoords.x + rotatedX,
                panelRightCoords.y + rotatedY,
                panelRightCoords.z
            )

            --DrawMarker(28, finalPanelCoords.x, finalPanelCoords.y, finalPanelCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 0, 255, 0, 150, false, false, 2, false, nil, nil, false)

            local distanceToPanel = #(playerCoords - finalPanelCoords)

            if distanceToPanel <= 1.5 then
                sleep = 0
                
                if not panelOpen then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to open the water panel")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                else
                    
                    if Has_hose then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Tank: ~b~" .. CurrentWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~INPUT_DETONATE~ Store The Hose")
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    else
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Tank: ~b~" .. CurrentWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~INPUT_DETONATE~ Deploy The Hose")
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    end

                    local current_timer = GetGameTimer()
                    if current_timer - lastPanelRefresh >= 1000 then
                        lastPanelRefresh = current_timer

                        if myPlate ~= nil then
                            TriggerServerEvent("fx-firefighter:getServerWater", myPlate)
                        end
                    end
                    
                end
                
                if IsControlJustPressed(0, 38) then
                    if panelOpen then
                        panelOpen = false
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Water panel closed")
                        lastNotif = DrawNotification(false, false)
                        currentPanelPlate = nil
                    else
                        panelOpen = true
                        currentPanelPlate = myPlate
                        TriggerServerEvent('fx-firefighter:getServerWater', myPlate)
                        
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Water panel opened")
                        lastNotif = DrawNotification(false, false)
                    end
                end
                
                
                if panelOpen and IsControlJustPressed(0, 47) then
                    if Has_hose then
                        if DoesEntityExist(HoseObject) then
                            DeleteEntity(HoseObject)
                        end
                        
                        HoseObject = 0
                        
                        Has_hose = false

                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Hose stored back in the truck")
                        DrawNotification(false, false)
                    else
                        Has_hose = true
                        local hash_hose = GetHashKey("prop_hose_nozzle")
                        RequestModel(hash_hose)
                        while not HasModelLoaded(hash_hose) do
                            Citizen.Wait(0)
                        end
                        --print("[DEBUG] Le modèle est chargé en mémoire")

                        RequestClipSet("move_characters@michael@fire")
                        while not HasClipSetLoaded("move_characters@michael@fire") do
                            Citizen.Wait(0)
                        end

                        --print("[DEBUG] La démarche est chargée en mémoire")

                        --print("[DEBUG] Le modèle est chargé en mémoire")
                        
                        HoseObject = CreateObject(hash_hose,playerCoords.x,playerCoords.y,playerCoords.z,true,false,false)
                        --print("[DEBUG] Le modèle est créé en mémoire")
                        local bone = GetPedBoneIndex(playerPed,57005)
                        --print("[DEBUG] L'index de l'os est recupéré")
                        
                        AttachEntityToEntity(HoseObject,playerPed,bone,
                        0.2400, 0.0200, 0.0066,
                        80.0000, 80.0000, -155.0000,
                        true,true,false,false,1,true)
                        
                        --print("[DEBUG] L'entité est attaché")

                        SetModelAsNoLongerNeeded(hash_hose)
                        
                    
                    end
                end

                if panelOpen and IsControlJustPressed(0,74) then
                    TriggerServerEvent("fx-firefighter:refillServerWater",currentPanelPlate)
                end
                
            end
        end
        Citizen.Wait(sleep)
    end
end)
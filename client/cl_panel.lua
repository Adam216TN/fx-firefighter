local panelRightOpen = false
local panelLeftOpen = false
local lastNotif = nil
local currentPanelPlate = nil
local lastPanelRefresh = 0

function GetCurrentTruckPlate()
    return currentPanelPlate
end

RegisterNetEvent('fx-firefighter:setClientWater')
AddEventHandler('fx-firefighter:setClientWater', function(waterServ, plateServ)
    if TrucksClient[plateServ] == nil then
        TrucksClient[plateServ] = {}
    end
    TrucksClient[plateServ].water = waterServ

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
            local plate = GetVehicleNumberPlateText(vehicle)
            local water = (TrucksClient[plate] and TrucksClient[plate].water) or CurrentWater
            SetNotificationTextEntry("STRING")
            AddTextComponentString("Tank : " .. water .. "/100 litres")
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
            
            local heading = GetEntityHeading(closest_firetruck)
            local rad = math.rad(heading)
            
            local boneIndexRight = GetEntityBoneIndexByName(closest_firetruck, "wheel_rr")
            local panelRightCoords = GetWorldPositionOfEntityBone(closest_firetruck, boneIndexRight)
            local offsetXR = 0.0
            local offsetYR = 2.0

            local rotatedXR = offsetXR * math.cos(rad) - offsetYR * math.sin(rad)
            local rotatedYR = offsetXR * math.sin(rad) + offsetYR * math.cos(rad)

            local finalPanelRightCoords = vector3(
                panelRightCoords.x + rotatedXR,
                panelRightCoords.y + rotatedYR,
                panelRightCoords.z
            )

            local boneIndexLeft = GetEntityBoneIndexByName(closest_firetruck, "wheel_lr")
            local panelLeftCoords = GetWorldPositionOfEntityBone(closest_firetruck, boneIndexLeft)
            local offsetXL = 0.0
            local offsetYL = 2.0

            local rotatedXL = offsetXL * math.cos(rad) - offsetYL * math.sin(rad)
            local rotatedYL = offsetXL * math.sin(rad) + offsetYL * math.cos(rad)

            local finalPanelLeftCoords = vector3(
                panelLeftCoords.x + rotatedXL,
                panelLeftCoords.y + rotatedYL,
                panelLeftCoords.z
            )

            local distanceToRightPanel = #(playerCoords - finalPanelRightCoords)
            local distanceToLeftPanel = #(playerCoords - finalPanelLeftCoords)

            local truckWater = (TrucksClient[myPlate] and TrucksClient[myPlate].water) or CurrentWater
            local isTruckHoseOut = TrucksClient[myPlate] and TrucksClient[myPlate].isHoseOut
            local isTruckRefillHoseOut = TrucksClient[myPlate] and TrucksClient[myPlate].isRefillHoseOut
            local isTruckConnectedHydrant = TrucksClient[myPlate] and TrucksClient[myPlate].hydrantNetId ~= nil

            
            if distanceToRightPanel <= 1.5 and not Has_refillHose then
                sleep = 0
                
                if not panelRightOpen then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ To Open The Hose Panel")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                else
                    if Has_hose then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Tank: ~b~" .. truckWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~INPUT_DETONATE~ Store The Hose")
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    elseif isTruckHoseOut then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Tank: ~b~" .. truckWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~r~Hose in use~s~")
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    else
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Tank: ~b~" .. truckWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~INPUT_DETONATE~ Deploy The Hose")
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
                    if panelRightOpen then
                        panelRightOpen = false
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Water panel closed")
                        lastNotif = DrawNotification(false, false)
                        currentPanelPlate = nil
                    else
                        panelRightOpen = true
                        currentPanelPlate = myPlate
                        TriggerServerEvent('fx-firefighter:getServerWater', myPlate)
                        
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Water panel opened")
                        lastNotif = DrawNotification(false, false)
                    end
                end
                
                if panelRightOpen and IsControlJustPressed(0, 47) then
                    if Has_hose then
                        if DoesEntityExist(HoseObject) then
                            DeleteEntity(HoseObject)
                        end
                        
                        HoseObject = 0
                        Has_hose = false

                        if TrucksClient[myPlate] then
                            TrucksClient[myPlate].isHoseOut = false
                            TrucksClient[myPlate].hoseHolder = nil
                        end
                        
                        TriggerServerEvent('fx-firefighter:updateTruckState', myPlate, 'isHoseOut', false)
                        TriggerServerEvent('fx-firefighter:updateTruckState', myPlate, 'hoseHolder', nil)

                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Hose stored back in the truck")
                        DrawNotification(false, false)
                    elseif not isTruckHoseOut then
                        Has_hose = true
                        
                        if TrucksClient[myPlate] then
                            TrucksClient[myPlate].isHoseOut = true
                            TrucksClient[myPlate].hoseHolder = GetPlayerServerId(PlayerId())
                        end
                        
                        TriggerServerEvent('fx-firefighter:updateTruckState', myPlate, 'isHoseOut', true)
                        TriggerServerEvent('fx-firefighter:updateTruckState', myPlate, 'hoseHolder', GetPlayerServerId(PlayerId()))

                        local hash_hose = GetHashKey("prop_hose_nozzle")
                        RequestModel(hash_hose)
                        while not HasModelLoaded(hash_hose) do
                            Citizen.Wait(0)
                        end

                        RequestClipSet("move_characters@michael@fire")
                        while not HasClipSetLoaded("move_characters@michael@fire") do
                            Citizen.Wait(0)
                        end
                        
                        HoseObject = CreateObject(hash_hose, playerCoords.x, playerCoords.y, playerCoords.z, true, false, false)
                        local bone = GetPedBoneIndex(playerPed, 57005)
                        
                        AttachEntityToEntity(HoseObject, playerPed, bone,
                            0.2400, 0.0200, 0.0066,
                            80.0000, 80.0000, -155.0000,
                            true, true, false, false, 1, true)

                        SetModelAsNoLongerNeeded(hash_hose)
                    else
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("The hose is already taken from this truck")
                        DrawNotification(false, false)
                    end
                end
                
            
            elseif distanceToLeftPanel <= 1.5 and not Has_hose then
                sleep = 0

                if not panelLeftOpen then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ To Open The Refill Panel")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                else
                    if Has_refillHose then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Tank: ~b~" .. truckWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~INPUT_DETONATE~ Store The Hose")
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    elseif isTruckConnectedHydrant then
                        local isRefilling = TrucksClient[myPlate] and TrucksClient[myPlate].isRefilling

                        BeginTextCommandDisplayHelp("STRING")
                        if isRefilling then
                            AddTextComponentSubstringPlayerName("Tank: ~b~" .. truckWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~INPUT_DETONATE~ ~r~Stop Refill~s~")
                        else
                            AddTextComponentSubstringPlayerName("Tank: ~b~" .. truckWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~INPUT_DETONATE~ ~g~Start Refill~s~")
                        end
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    elseif isTruckRefillHoseOut then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Tank: ~b~" .. truckWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~r~Refill hose in use~s~")
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    else
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Tank: ~b~" .. truckWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~INPUT_DETONATE~ Deploy The Hose")
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
                    if panelLeftOpen then
                        panelLeftOpen = false
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Refill panel closed")
                        lastNotif = DrawNotification(false, false)
                        currentPanelPlate = nil
                    else
                        panelLeftOpen = true
                        currentPanelPlate = myPlate
                        TriggerServerEvent('fx-firefighter:getServerWater', myPlate)
                        
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Refill panel opened")
                        lastNotif = DrawNotification(false, false)
                    end
                end

                if panelLeftOpen and IsControlJustPressed(0, 47) then
                        
                    if isTruckConnectedHydrant then
                        local isRefilling = TrucksClient[myPlate] and TrucksClient[myPlate].isRefilling
                        TriggerServerEvent('fx-firefighter:updateTruckState',myPlate,'isRefilling',not isRefilling)

                        if isRefilling then
                            SetNotificationTextEntry("STRING")
                            AddTextComponentString("Refill stopped")
                            DrawNotification(false, false)
                        else
                            SetNotificationTextEntry("STRING")
                            AddTextComponentString("Refill started")
                            DrawNotification(false, false)
                        end
                    else
                        if Has_refillHose then
                            Has_refillHose = false
                            HoldingRefillPlate = nil
                            
                            if TrucksClient[myPlate] then
                                TrucksClient[myPlate].isRefillHoseOut = false
                                TrucksClient[myPlate].refillHolder = nil
                            end
                            
                            TriggerServerEvent('fx-firefighter:updateTruckState', myPlate, 'isRefillHoseOut', false)
                            TriggerServerEvent('fx-firefighter:updateTruckState', myPlate, 'refillHolder', nil)

                            SetNotificationTextEntry("STRING")
                            AddTextComponentString("Refill Hose stored back in the truck")
                            DrawNotification(false, false)
                        elseif not isTruckRefillHoseOut then
                            Has_refillHose = true
                            HoldingRefillPlate = myPlate
                            
                            if TrucksClient[myPlate] then
                                TrucksClient[myPlate].isRefillHoseOut = true
                                TrucksClient[myPlate].refillHolder = GetPlayerServerId(PlayerId())
                            end
                            
                            TriggerServerEvent('fx-firefighter:updateTruckState', myPlate, 'isRefillHoseOut', true)
                            TriggerServerEvent('fx-firefighter:updateTruckState', myPlate, 'refillHolder', GetPlayerServerId(PlayerId()))
                            
                            RequestClipSet("move_characters@michael@fire")
                            while not HasClipSetLoaded("move_characters@michael@fire") do
                                Citizen.Wait(0)
                            end
                        else
                            SetNotificationTextEntry("STRING")
                            AddTextComponentString("The refill hose is already taken from this truck")
                            DrawNotification(false, false)
                        end
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)
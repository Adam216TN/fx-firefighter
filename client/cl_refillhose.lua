local isWalksetApplied = false
local hash_firehydrant1 = GetHashKey("prop_fire_hydrant_1")
local hash_firehydrant2 = GetHashKey("prop_fire_hydrant_2")

local SpawnedRefillPipes = {}

local SEGMENT_LENGTH = 0.05
local MAX_SEGMENTS   = 600

local function GetVehicleByPlate(targetPlate)
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if GetVehicleNumberPlateText(veh) == targetPlate then
            return veh
        end
    end
    return 0
end

Citizen.CreateThread(function()
    while true do
        if Has_refillHose then
            local playerPed = PlayerPedId()
            if not isWalksetApplied then
                isWalksetApplied = true
                SetPedMovementClipset(playerPed, "move_characters@michael@fire", 0.2)
            end
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            
            Citizen.Wait(0)
        else
            if isWalksetApplied then
                local playerPed = PlayerPedId()
                SetPlayerForcedAim(PlayerId(), false)
                ResetPedMovementClipset(playerPed, 0.2)
                RemoveClipSet("move_characters@michael@fire")
                isWalksetApplied = false
            end
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    local hash_pipe = GetHashKey("prop_pipe_firefighter")

    RequestModel(hash_pipe)
    local timeout = 0
    while not HasModelLoaded(hash_pipe) and timeout < 500 do
        Citizen.Wait(10)
        timeout = timeout + 1
    end

    if not HasModelLoaded(hash_pipe) then
        print("^1[ERREUR] prop_pipe_firefighter impossible à charger^7")
        return
    end
    
    while true do
        local activeTrucks = {}

        for plate, state in pairs(TrucksClient) do
            if state.hydrantNetId ~= nil then
                activeTrucks[plate] = {isHeld = false, hydrantNetId = state.hydrantNetId}
            elseif state.refillHolder ~= nil then
                activeTrucks[plate] = {isHeld = true, refillHolderID = state.refillHolder}
            end
        end

        local hasAnyActive = false
        
        for plate, data in pairs(activeTrucks) do
            local firetruck = GetVehicleByPlate(plate)

            hasAnyActive = true

            if firetruck ~= 0 and DoesEntityExist(firetruck) then
                local boneIndexLeft = GetEntityBoneIndexByName(firetruck, "wheel_lr")
                local panelLeftCoords = GetWorldPositionOfEntityBone(firetruck, boneIndexLeft)
                local heading = GetEntityHeading(firetruck)
                local rad = math.rad(heading)
                local offsetXL = 0.0
                local offsetYL = 2.0

                local ptA = vector3(
                    panelLeftCoords.x + (offsetXL * math.cos(rad) - offsetYL * math.sin(rad)),
                    panelLeftCoords.y + (offsetXL * math.sin(rad) + offsetYL * math.cos(rad)),
                    panelLeftCoords.z
                )

                local ptB = nil

                if data.isHeld == false then
                    local hydrantEntity = NetToObj(data.hydrantNetId)
                    if DoesEntityExist(hydrantEntity) then
                        ptB = GetEntityCoords(hydrantEntity)
                    end
                else
                    local playerIndex = GetPlayerFromServerId(data.refillHolderID)
                    if playerIndex ~= -1 then
                        local holderPed = GetPlayerPed(playerIndex)
                        if DoesEntityExist(holderPed) then
                            local bone = GetPedBoneIndex(holderPed, 57005)
                            ptB = GetPedBoneCoords(holderPed, bone, 0.0, 0.0, 0.0)
                        end
                    end
                end

                if ptA and ptB then
                    if SpawnedRefillPipes[plate] == nil then
                        SpawnedRefillPipes[plate] = {}
                    end
                    
                    if #SpawnedRefillPipes[plate] == 0 then
                        for i = 1, MAX_SEGMENTS do
                            local obj = CreateObject(hash_pipe, ptA.x, ptA.y, ptA.z, false, false, false)
                            SetEntityCollision(obj, false, false)
                            SetEntityVisible(obj, false, false)
                            table.insert(SpawnedRefillPipes[plate], obj)
                        end
                    end

                    for i = 1, MAX_SEGMENTS do
                        local obj = SpawnedRefillPipes[plate][i]
                        if obj and DoesEntityExist(obj) then
                            SetEntityVisible(obj, true, false)
                            
                            local t1 = (i - 1) / MAX_SEGMENTS
                            local t2 = i / MAX_SEGMENTS

                            local pt1 = Bezier(ptA, (ptA + ptB) / 2.0, ptB, t1)
                            local pt2 = Bezier(ptA, (ptA + ptB) / 2.0, ptB, t2)

                            PlacePipeSegment(obj, pt1, pt2)
                        end
                    end
                elseif SpawnedRefillPipes[plate] then
                    
                    for i = 1, #SpawnedRefillPipes[plate] do
                        local obj = SpawnedRefillPipes[plate][i]
                        if obj and DoesEntityExist(obj) then
                            SetEntityVisible(obj, false, false)
                        end
                    end
                end
            end
        end
            
        for plate, pipeList in pairs(SpawnedRefillPipes) do
            if not activeTrucks[plate] then
                for _, obj in ipairs(pipeList) do
                    if DoesEntityExist(obj) then DeleteEntity(obj) end
                end
                SpawnedRefillPipes[plate] = nil
            end
        end

        if hasAnyActive then
            Citizen.Wait(0)
        else
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local closestHydrant1 = GetClosestObjectOfType(
            playerCoords.x, playerCoords.y, playerCoords.z,
            5.0, hash_firehydrant1, false, false, false
        )

        local closestHydrant2 = GetClosestObjectOfType(
            playerCoords.x, playerCoords.y, playerCoords.z,
            5.0, hash_firehydrant2, false, false, false
        )

        local closestHydrant = 0
        if closestHydrant1 ~= 0 then
            closestHydrant = closestHydrant1
        elseif closestHydrant2 ~= 0 then
            closestHydrant = closestHydrant2
        end

        if closestHydrant ~= 0 then
            local hydrantCoords = GetEntityCoords(closestHydrant)
            local distance = #(playerCoords - hydrantCoords)

            if distance <= 1.5 then
                if not NetworkGetEntityIsNetworked(closestHydrant) then
                    NetworkRegisterEntityAsNetworked(closestHydrant)
                end

                local currentHydrantNetId = ObjToNet(closestHydrant)
                
                if Has_refillHose and HoldingRefillPlate ~= nil then
                    local isHydrantOccupied = false
                    for _, state in pairs(TrucksClient) do
                        if state.hydrantNetId == currentHydrantNetId then
                            isHydrantOccupied = true
                            break
                        end
                    end

                    sleep = 0
                    if isHydrantOccupied then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("~r~Hydrant already in use~s~")
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    else
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to connect the refill hose")
                        EndTextCommandDisplayHelp(0, false, true, -1)

                        if IsControlJustPressed(0, 38) then
                            if TrucksClient[HoldingRefillPlate] then
                                TrucksClient[HoldingRefillPlate].hydrantNetId = currentHydrantNetId
                                TrucksClient[HoldingRefillPlate].refillHolder = nil
                            end
                            
                            TriggerServerEvent('fx-firefighter:updateTruckState', HoldingRefillPlate, 'hydrantNetId', currentHydrantNetId)
                            TriggerServerEvent('fx-firefighter:updateTruckState', HoldingRefillPlate, 'refillHolder', nil)

                            Has_refillHose = false
                            HoldingRefillPlate = nil

                            SetNotificationTextEntry("STRING")
                            AddTextComponentString("Hose successfully connected to the fire hydrant")
                            DrawNotification(false, false)
                        end
                    end

                elseif not Has_refillHose then
                    for plate, state in pairs(TrucksClient) do
                        if state.hydrantNetId == currentHydrantNetId then
                            sleep = 0
                            BeginTextCommandDisplayHelp("STRING")
                            AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to disconnect the refill hose (~b~" .. plate .. "~s~)")
                            EndTextCommandDisplayHelp(0, false, true, -1)

                            if IsControlJustPressed(0, 38) then
                                
                                if TrucksClient[plate] then
                                    TrucksClient[plate].hydrantNetId = nil
                                    TrucksClient[plate].refillHolder = GetPlayerServerId(PlayerId())
                                end
                                
                                if state.isRefilling then
                                    TriggerServerEvent('fx-firefighter:updateTruckState', plate, 'isRefilling', false)
                                end

                                TriggerServerEvent('fx-firefighter:updateTruckState', plate, 'hydrantNetId', nil)
                                TriggerServerEvent('fx-firefighter:updateTruckState', plate, 'refillHolder', GetPlayerServerId(PlayerId()))
                                
                                Has_refillHose = true
                                HoldingRefillPlate = plate

                                SetNotificationTextEntry("STRING")
                                AddTextComponentString("Hose disconnected from the fire hydrant")
                                DrawNotification(false, false)
                            end
                            break
                        end
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)
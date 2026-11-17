local isWalksetApplied = false
local weaponHash       = GetHashKey("WEAPON_CARBINERIFLE")
local isFiring         = false

local SpawnedPipes = {}

local SEGMENT_LENGTH       = 0.05
local MAX_SEGMENTS         = 600
local MAX_HOSE_LENGTH      = MAX_SEGMENTS * SEGMENT_LENGTH
local WAVE_COUNT           = 3

local TRUCK_PANEL_OFFSET   = vector3(1.15, 0.25, 0.05)
local HOSE_OFFSET          = vector3(0.0, 0.0, -0.18)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, pipeList in pairs(SpawnedPipes) do
            for _, obj in ipairs(pipeList) do
                if DoesEntityExist(obj) then DeleteEntity(obj) end
            end
        end
        SpawnedPipes = {}
        if DoesEntityExist(HoseObject) then DeleteEntity(HoseObject) end
    end
end)

Citizen.CreateThread(function()
    while true do
        if Has_hose then
            local playerPed = PlayerPedId()
            if not isWalksetApplied then
                isWalksetApplied = true
                GiveWeaponToPed(playerPed, weaponHash, 0, false, true)
                SetCurrentPedWeapon(playerPed, weaponHash, true)
                SetPedMovementClipset(playerPed, "move_characters@michael@fire", 0.2)
            end
            SetPedCurrentWeaponVisible(playerPed, false, false, true, true)
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            if IsControlPressed(0, 25) then
                if not isFiring then
                    isFiring = true
                    ResetPedMovementClipset(playerPed, 0.2)
                end
                SetPlayerForcedAim(PlayerId(), true)
            else
                if isFiring then
                    isFiring = false
                    SetPlayerForcedAim(PlayerId(), false)
                    SetPedMovementClipset(playerPed, "move_characters@michael@fire", 0.2)
                end
            end
            Citizen.Wait(0)
        else
            if isWalksetApplied then
                local playerPed = PlayerPedId()
                SetPlayerForcedAim(PlayerId(), false)
                RemoveWeaponFromPed(playerPed, weaponHash)
                ResetPedMovementClipset(playerPed, 0.2)
                RemoveClipSet("move_characters@michael@fire")
                isWalksetApplied = false
                isFiring = false
            end
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function()
    local timeOff = {}

    while true do
        local activeTrucks = {}

        for plate, state in pairs(TrucksClient) do
            if state.hoseHolder ~= nil then
                activeTrucks[plate] = {holderServerId = state.hoseHolder, hoseNetId = state.hoseNetId}
            end
        end

        local hasAnyActive = false
        
        for plate, data in pairs(activeTrucks) do
            hasAnyActive = true
            local firetruck = GetVehicleByPlate(plate)
            local ptB = nil

            if data.holderServerId == GetPlayerServerId(PlayerId()) and HoseObject and DoesEntityExist(HoseObject) then
                ptB = GetOffsetFromEntityInWorldCoords(HoseObject, HOSE_OFFSET.x, HOSE_OFFSET.y, HOSE_OFFSET.z)
            elseif data.hoseNetId then
                local nozzleEntity = NetToObj(data.hoseNetId)
                if DoesEntityExist(nozzleEntity) then
                    ptB = GetOffsetFromEntityInWorldCoords(nozzleEntity, HOSE_OFFSET.x, HOSE_OFFSET.y, HOSE_OFFSET.z)
                end
            end

            if ptB == nil and data.holderServerId then
                local playerIndex = GetPlayerFromServerId(data.holderServerId)
                if playerIndex ~= -1 then
                    local holderPed = GetPlayerPed(playerIndex)
                    if DoesEntityExist(holderPed) then
                        local bone = GetPedBoneIndex(holderPed, 57005)
                        ptB = GetPedBoneCoords(holderPed, bone, 0.0, 0.0, 0.0)
                    end
                end
            end

            if firetruck ~= 0 and DoesEntityExist(firetruck) and ptB ~= nil then
                timeOff[plate] = nil
                local ptA = GetEntityCoords(firetruck)
                local realSpawnPt = GetOffsetFromEntityInWorldCoords(firetruck, TRUCK_PANEL_OFFSET.x, TRUCK_PANEL_OFFSET.y, TRUCK_PANEL_OFFSET.z)
                local distance = math.min(#(realSpawnPt - ptB), MAX_HOSE_LENGTH)
            
                if SpawnedPipes[plate] == nil then
                    SpawnedPipes[plate] = {}
                end
                
                if #SpawnedPipes[plate] == 0 then
                    local hash_pipe = LoadPipeModel()
                    if hash_pipe then
                        for _ = 1, MAX_SEGMENTS do
                            local obj = CreateObject(hash_pipe, ptA.x, ptA.y, ptA.z, false, false, false)
                            SetEntityCollision(obj, false, false)
                            SetEntityVisible(obj, false, false)
                            table.insert(SpawnedPipes[plate], obj)
                        end
                    end
                end

                if #SpawnedPipes[plate] > 0 then
                    local safeMaxLen = MAX_HOSE_LENGTH * 0.85
                    local maxArcAmp  = math.sqrt(math.max(0.0, safeMaxLen * safeMaxLen - distance * distance)) / (4.2 * WAVE_COUNT)
                    local currentAmp = math.min(1.6, maxArcAmp)

                    for i = 1, MAX_SEGMENTS do
                        local obj = SpawnedPipes[plate][i]
                        if obj and DoesEntityExist(obj) then
                            SetEntityVisible(obj, true, false)
                            local t1  = (i - 1) / MAX_SEGMENTS
                            local t2  = i / MAX_SEGMENTS
                            local pt1 = SinusCurve(realSpawnPt, ptB, t1, currentAmp, WAVE_COUNT)
                            local pt2 = SinusCurve(realSpawnPt, ptB, t2, currentAmp, WAVE_COUNT)

                            PlacePipeSegment(obj, pt1, pt2)
                        end
                    end
                end

            elseif SpawnedPipes[plate] then
                for i = 1, #SpawnedPipes[plate] do
                    local obj = SpawnedPipes[plate][i]
                    if obj and DoesEntityExist(obj) then
                        SetEntityVisible(obj, false, false)
                    end
                end

                if timeOff[plate] == nil then
                    timeOff[plate] = GetGameTimer()
                end
                
                if GetGameTimer() - timeOff[plate] >= 30000 then
                    for i = 1, #SpawnedPipes[plate] do
                        local obj = SpawnedPipes[plate][i]
                        if obj and DoesEntityExist(obj) then
                            DeleteEntity(obj)
                        end
                    end
                    SpawnedPipes[plate] = nil
                    timeOff[plate] = nil
                end
            end
        end
        
        for plate, pipeList in pairs(SpawnedPipes) do
            if not activeTrucks[plate] then
                for _, obj in ipairs(pipeList) do
                    if DoesEntityExist(obj) then DeleteEntity(obj) end
                end
                SpawnedPipes[plate] = nil
                timeOff[plate] = nil
                
                local truckState = TrucksClient[plate]
                if truckState and truckState.hoseNetId then
                    local nozzleObj = NetToObj(truckState.hoseNetId)
                    if DoesEntityExist(nozzleObj) then
                        DeleteEntity(nozzleObj)
                    end
                end
            end
        end
        
        if hasAnyActive then
            Citizen.Wait(0)
        else
            Citizen.Wait(1000)
        end
    end
end)
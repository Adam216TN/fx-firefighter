local isWalksetApplied = false
local weaponHash       = GetHashKey("WEAPON_CARBINERIFLE")
local isFiring         = false

local SpawnedPipes = {}

local SEGMENT_LENGTH       = 0.05
local MAX_SEGMENTS         = 600
local MAX_HOSE_LENGTH      = MAX_SEGMENTS * SEGMENT_LENGTH

local COIL_RADIUS          = 1.2
local SEGS_PER_TURN        = math.floor((2.0 * math.pi * COIL_RADIUS) / SEGMENT_LENGTH)
local JUNCTION_IN_SEGS     = 45
local JUNCTION_OUT_SEGS    = 45

local TRUCK_PANEL_OFFSET = vector3(0.90, -0.1, 0.0)
local HOSE_OFFSET = vector3(0.0, -0.15, 0.0)

local function coilPos(coilCenter, i, segsPerTurn, segLen)
    local angle  = (i / segsPerTurn) * 2.0 * math.pi
    local turn   = math.floor((i - 1) / segsPerTurn)
    local radius = COIL_RADIUS + turn * segLen * 0.5
    return vector3(
        coilCenter.x + math.cos(angle) * radius,
        coilCenter.y + math.sin(angle) * radius,
        coilCenter.z
    )
end

local function coilTangent(coilCenter, i, segsPerTurn, segLen, tangentLen)
    local pos     = coilPos(coilCenter, i,     segsPerTurn, segLen)
    local posNext = coilPos(coilCenter, i + 1, segsPerTurn, segLen)
    local dir = vector3(posNext.x - pos.x, posNext.y - pos.y, 0.0)
    local len = math.sqrt(dir.x*dir.x + dir.y*dir.y)
    return vector3(
        pos.x + (dir.x / len) * tangentLen,
        pos.y + (dir.y / len) * tangentLen,
        pos.z
    )
end

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

            if firetruck ~= 0 and ptB ~= nil then
                local ptA = GetEntityCoords(firetruck)
                local realSpawnPt = GetOffsetFromEntityInWorldCoords(firetruck, TRUCK_PANEL_OFFSET.x, TRUCK_PANEL_OFFSET.y, TRUCK_PANEL_OFFSET.z)
                local distance = math.min(#(ptA - ptB), MAX_HOSE_LENGTH)
            
                if SpawnedPipes[plate] == nil then
                    SpawnedPipes[plate] = {}
                end
                
                if #SpawnedPipes[plate] == 0 then
                    for _ = 1, MAX_SEGMENTS do
                        local obj = CreateObject(hash_pipe, ptA.x, ptA.y, ptA.z, false, false, false)
                        SetEntityCollision(obj, false, false)
                        SetEntityVisible(obj, false, false)
                        table.insert(SpawnedPipes[plate], obj)
                    end
                end

                local unrolledCount = math.floor(distance / SEGMENT_LENGTH)
                local fixedSegs     = JUNCTION_IN_SEGS + JUNCTION_OUT_SEGS
                local rolledCount   = math.max(0, MAX_SEGMENTS - unrolledCount - fixedSegs)

                local fwd = GetEntityForwardVector(firetruck)
                local rgt = vector3(fwd.y, -fwd.x, 0.0)
                local coilCenter = vector3(
                    ptA.x + rgt.x * 2.5,
                    ptA.y + rgt.y * 2.5,
                    ptA.z - 1
                )

                local firstCirclePos = coilPos(coilCenter, 1, SEGS_PER_TURN, SEGMENT_LENGTH)
                local lastCirclePos  = coilPos(coilCenter, math.max(1, rolledCount), SEGS_PER_TURN, SEGMENT_LENGTH)

                local tangentOut = coilTangent(coilCenter, math.max(1, rolledCount), SEGS_PER_TURN, SEGMENT_LENGTH, 0.5)
                local tanIn = coilTangent(coilCenter, 1, SEGS_PER_TURN, SEGMENT_LENGTH, 1.5)

                local ptC_in = vector3(
                    firstCirclePos.x - (tanIn.x - firstCirclePos.x),
                    firstCirclePos.y - (tanIn.y - firstCirclePos.y),
                    ptA.z
                )

                for i = 1, JUNCTION_IN_SEGS do
                    local obj = SpawnedPipes[plate][i]
                    if obj and DoesEntityExist(obj) then
                        SetEntityVisible(obj, true, false)
                        local t1  = (i - 1) / JUNCTION_IN_SEGS
                        local t2  = i       / JUNCTION_IN_SEGS
                        local pt1 = Bezier(realSpawnPt, ptC_in, firstCirclePos, t1)
                        local pt2 = Bezier(realSpawnPt, ptC_in, firstCirclePos, t2)
                        PlacePipeSegment(obj, pt1, pt2)
                    end
                end

                for i = 1, rolledCount do
                    local obj = SpawnedPipes[plate][JUNCTION_IN_SEGS + i]
                    if obj and DoesEntityExist(obj) then
                        SetEntityVisible(obj, true, false)
                        local pos     = coilPos(coilCenter, i,     SEGS_PER_TURN, SEGMENT_LENGTH)
                        local posNext = coilPos(coilCenter, i + 1, SEGS_PER_TURN, SEGMENT_LENGTH)
                        local yaw, _, _ = RotationToFace(pos, posNext)
                        SetEntityCoords(obj, pos.x, pos.y, pos.z, false, false, false, false)
                        SetEntityRotation(obj, 0.0, 0.0, yaw - 90.0, 2, true)
                    end
                end

                local ptC_out = tangentOut
                local junctionOutStart = lastCirclePos

                for i = 1, JUNCTION_OUT_SEGS do
                    local obj = SpawnedPipes[plate][JUNCTION_IN_SEGS + rolledCount + i]
                    if obj and DoesEntityExist(obj) then
                        SetEntityVisible(obj, true, false)
                        local t1  = (i - 1) / JUNCTION_OUT_SEGS
                        local t2  = i       / JUNCTION_OUT_SEGS
                        
                        local midTarget = vector3(
                            lastCirclePos.x + (ptB.x - lastCirclePos.x) * 0.25,
                            lastCirclePos.y + (ptB.y - lastCirclePos.y) * 0.25,
                            lastCirclePos.z + (ptB.z - lastCirclePos.z) * 0.25
                        )
                        local pt1 = Bezier(junctionOutStart, ptC_out, midTarget, t1)
                        local pt2 = Bezier(junctionOutStart, ptC_out, midTarget, t2)
                        PlacePipeSegment(obj, pt1, pt2)
                    end
                end

                local midTarget = vector3(
                    lastCirclePos.x + (ptB.x - lastCirclePos.x) * 0.25,
                    lastCirclePos.y + (ptB.y - lastCirclePos.y) * 0.25,
                    lastCirclePos.z + (ptB.z - lastCirclePos.z) * 0.25
                )
                local ptStart = Bezier(junctionOutStart, ptC_out, midTarget, 1.0)

                if unrolledCount > 0 then
                    local down = math.min(0.3, distance * 0.05)
                    local targetZ = ((ptStart.z + ptB.z) * 0.5) - down
                    if targetZ < ptStart.z then targetZ = ptStart.z end

                    local ptC_unrolled = vector3(
                        (ptStart.x + ptB.x) * 0.5,
                        (ptStart.y + ptB.y) * 0.5,
                        targetZ
                    )

                    local baseIdx = JUNCTION_IN_SEGS + rolledCount + JUNCTION_OUT_SEGS
                    for i = 1, unrolledCount do
                        local obj = SpawnedPipes[plate][baseIdx + i]
                        if obj and DoesEntityExist(obj) then
                            SetEntityVisible(obj, true, false)
                            local t1  = (i - 1) / unrolledCount
                            local t2  = i       / unrolledCount
                            local pt1 = Bezier(ptStart, ptC_unrolled, ptB, t1)
                            local pt2 = Bezier(ptStart, ptC_unrolled, ptB, t2)
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
            end
        end
        
        for plate, pipeList in pairs(SpawnedPipes) do
            if not activeTrucks[plate] then
                for _, obj in ipairs(pipeList) do
                    if DoesEntityExist(obj) then DeleteEntity(obj) end
                end
                SpawnedPipes[plate] = nil
                
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
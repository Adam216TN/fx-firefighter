local isWalksetApplied = false
local weaponHash       = GetHashKey("WEAPON_CARBINERIFLE")
local isFiring         = false

SpawnedPipes = {}

local SEGMENT_LENGTH       = 0.05
local MAX_SEGMENTS         = 600
local MAX_HOSE_LENGTH      = MAX_SEGMENTS * SEGMENT_LENGTH

local COIL_RADIUS          = 1.2
local SEGS_PER_TURN        = math.floor((2.0 * math.pi * COIL_RADIUS) / SEGMENT_LENGTH)
local JUNCTION_IN_SEGS     = 45
local JUNCTION_OUT_SEGS    = 45

function RotationToFace(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local dz = pos2.z - pos1.z
    local dist_ground = math.sqrt(dx * dx + dy * dy)
    local yaw         = math.atan(dy, dx) * (180.0 / math.pi)
    local pitch       = math.atan(dz, dist_ground) * (180.0 / math.pi)
    return yaw, pitch, 0.0
end

local function bezier(ptA, ptC, ptB, t)
    local u = 1.0 - t
    return vector3(
        u*u*ptA.x + 2*u*t*ptC.x + t*t*ptB.x,
        u*u*ptA.y + 2*u*t*ptC.y + t*t*ptB.y,
        u*u*ptA.z + 2*u*t*ptC.z + t*t*ptB.z
    )
end

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

local function placePipeSegment(obj, pt1, pt2)
    local yaw, pitch, _ = RotationToFace(pt1, pt2)
    local ptMid = (pt1 + pt2) * 0.5
    SetEntityCoords(obj, ptMid.x, ptMid.y, ptMid.z, false, false, false, false)
    SetEntityRotation(obj, pitch, 0.0, yaw - 90.0, 2, true)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, obj in ipairs(SpawnedPipes) do
            if DoesEntityExist(obj) then DeleteEntity(obj) end
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
                GiveWeaponToPed(playerPed, weaponHash, 10, false, true)
                SetCurrentPedWeapon(playerPed, weaponHash, true)
                SetPedMovementClipset(playerPed, "move_characters@michael@fire", 0.2)
            end
            SetPedCurrentWeaponVisible(playerPed, false, false, true, true)
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            if IsControlPressed(0, 24) then
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

    local function loadModel()
        local timeout = 0
        while not HasModelLoaded(hash_pipe) and timeout < 500 do
            RequestModel(hash_pipe)
            Citizen.Wait(100)
            timeout = timeout + 1
        end
        return HasModelLoaded(hash_pipe)
    end

    while true do
        if Has_hose then
            local playerPed    = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local bone         = GetPedBoneIndex(playerPed, 57005)
            local ptB          = GetPedBoneCoords(playerPed, bone, 0.0, 0.0, 0.0)

            local firetruck = GetClosestVehicle(
                playerCoords.x, playerCoords.y, playerCoords.z,
                MAX_HOSE_LENGTH + 5.0, GetHashKey("firetruk"), 70
            )

            if firetruck ~= 0 then
                local ptA      = GetEntityCoords(firetruck)
                local distance = math.min(#(ptA - ptB), MAX_HOSE_LENGTH)

                if #SpawnedPipes == 0 then
                    if loadModel() then
                        for i = 1, MAX_SEGMENTS do
                            local obj = CreateObject(hash_pipe, ptA.x, ptA.y, ptA.z, true, false, false)
                            SetEntityCollision(obj, false, false)
                            SetEntityVisible(obj, false, false)
                            table.insert(SpawnedPipes, obj)
                        end
                    else
                        print("^1[ERREUR] prop_pipe_firefighter impossible à charger^7")
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
                    local obj = SpawnedPipes[i]
                    if obj and DoesEntityExist(obj) then
                        SetEntityVisible(obj, true, false)
                        local t1  = (i - 1) / JUNCTION_IN_SEGS
                        local t2  = i       / JUNCTION_IN_SEGS
                        local pt1 = bezier(ptA, ptC_in, firstCirclePos, t1)
                        local pt2 = bezier(ptA, ptC_in, firstCirclePos, t2)
                        placePipeSegment(obj, pt1, pt2)
                    end
                end

                for i = 1, rolledCount do
                    local obj = SpawnedPipes[JUNCTION_IN_SEGS + i]
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
                    local obj = SpawnedPipes[JUNCTION_IN_SEGS + rolledCount + i]
                    if obj and DoesEntityExist(obj) then
                        SetEntityVisible(obj, true, false)
                        local t1  = (i - 1) / JUNCTION_OUT_SEGS
                        local t2  = i       / JUNCTION_OUT_SEGS
                        
                        local midTarget = vector3(
                            lastCirclePos.x + (ptB.x - lastCirclePos.x) * 0.25,
                            lastCirclePos.y + (ptB.y - lastCirclePos.y) * 0.25,
                            lastCirclePos.z + (ptB.z - lastCirclePos.z) * 0.25
                        )
                        local pt1 = bezier(junctionOutStart, ptC_out, midTarget, t1)
                        local pt2 = bezier(junctionOutStart, ptC_out, midTarget, t2)
                        placePipeSegment(obj, pt1, pt2)
                    end
                end

                local t_end   = 1.0
                local u_end   = 1.0 - t_end
                local midTarget = vector3(
                    lastCirclePos.x + (ptB.x - lastCirclePos.x) * 0.25,
                    lastCirclePos.y + (ptB.y - lastCirclePos.y) * 0.25,
                    lastCirclePos.z + (ptB.z - lastCirclePos.z) * 0.25
                )
                local ptStart = bezier(junctionOutStart, ptC_out, midTarget, 1.0)

                if unrolledCount > 0 then
                    local down = math.min(0.3, distance * 0.05)
                    
                    local targetZ = ((ptStart.z + ptB.z) * 0.5) - down
                    
                    if targetZ < ptStart.z then
                        targetZ = ptStart.z
                    end

                    local ptC_unrolled = vector3(
                        (ptStart.x + ptB.x) * 0.5,
                        (ptStart.y + ptB.y) * 0.5,
                        targetZ
                    )

                    local baseIdx = JUNCTION_IN_SEGS + rolledCount + JUNCTION_OUT_SEGS
                    for i = 1, unrolledCount do
                        local obj = SpawnedPipes[baseIdx + i]
                        if obj and DoesEntityExist(obj) then
                            SetEntityVisible(obj, true, false)
                            local t1  = (i - 1) / unrolledCount
                            local t2  = i       / unrolledCount
                            local pt1 = bezier(ptStart, ptC_unrolled, ptB, t1)
                            local pt2 = bezier(ptStart, ptC_unrolled, ptB, t2)
                            placePipeSegment(obj, pt1, pt2)
                        end
                    end
                end
            end

            Citizen.Wait(0)
        else
            for _, obj in ipairs(SpawnedPipes) do
                if DoesEntityExist(obj) then DeleteEntity(obj) end
            end
            SpawnedPipes = {}
            Citizen.Wait(1000)
        end
    end
end)
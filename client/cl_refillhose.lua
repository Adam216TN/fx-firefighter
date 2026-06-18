local isWalksetApplied = false
local hash_firehydrant = GetHashKey("prop_fire_hydrant_1")
local firehydrantObj = nil
local activeHoseTruckEntity = 0
local hoseAttached = false

local SpawnedRefillPipes = {}

local SEGMENT_LENGTH       = 0.05
local MAX_SEGMENTS         = 600
local MAX_HOSE_LENGTH      = MAX_SEGMENTS * SEGMENT_LENGTH

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

Citizen.CreateThread(function ()
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
        
        if Has_refillHose or hoseAttached then
            local playerPed = PlayerPedId()
            local firetruck = 0

            local ptB = vector3(0.0, 0.0, 0.0)
            if hoseAttached and firehydrantObj ~= nil and DoesEntityExist(firehydrantObj) then
                ptB = GetEntityCoords(firehydrantObj)
            else
                local bone = GetPedBoneIndex(playerPed, 57005)
                ptB = GetPedBoneCoords(playerPed, bone, 0.0, 0.0, 0.0)
            end

            if activeHoseTruckEntity ~= 0 and DoesEntityExist(activeHoseTruckEntity) then
                firetruck = activeHoseTruckEntity
            else
                local playerCoords = GetEntityCoords(playerPed)
                local closest = GetClosestVehicle(
                    playerCoords.x, playerCoords.y, playerCoords.z,
                    MAX_HOSE_LENGTH + 5.0, GetHashKey("firetruk"), 70
                )
                if closest ~= 0 then
                    firetruck = closest
                    activeHoseTruckEntity = closest
                end
            end

            if firetruck ~= 0 then
                local ptA = GetEntityCoords(firetruck)
                if #SpawnedRefillPipes == 0 then
                    if loadModel() then
                        for i = 1, MAX_SEGMENTS do
                            local obj = CreateObject(hash_pipe, ptA.x, ptA.y, ptA.z, true, false, false)
                            SetEntityCollision(obj, false, false)
                            SetEntityVisible(obj, false, false)
                            table.insert(SpawnedRefillPipes, obj)
                        end
                    else
                        print("^1[ERREUR] prop_pipe_firefighter impossible à charger^7")
                    end
                end

                for i = 1, MAX_SEGMENTS do
                    local obj = SpawnedRefillPipes[i]
                    if obj and DoesEntityExist(obj) then
                        SetEntityVisible(obj, true, false)
                        
                        local t1 = (i - 1) / MAX_SEGMENTS
                        local t2 = i / MAX_SEGMENTS

                        local pt1 = Bezier(ptA, (ptA + ptB) / 2.0, ptB, t1)
                        local pt2 = Bezier(ptA, (ptA + ptB) / 2.0, ptB, t2)

                        PlacePipeSegment(obj, pt1, pt2)
                    end
                end
            end
            Citizen.Wait(0)
        else
            
            if #SpawnedRefillPipes > 0 then
                for _, obj in ipairs(SpawnedRefillPipes) do
                    if DoesEntityExist(obj) then DeleteEntity(obj) end
                end
                SpawnedRefillPipes = {}
                activeHoseTruckEntity = 0
            end
            Citizen.Wait(1000)
        end    
    end
end)


Citizen.CreateThread(function ()

    while true do
        
        local sleep = 1000
        
        if Has_refillHose and not hoseAttached then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            local closestHydrant = GetClosestObjectOfType(
            playerCoords.x,playerCoords.y,playerCoords.z,
            5.0,hash_firehydrant,false,false,false)

            if closestHydrant ~= 0 then
                sleep = 0
                local hydrantCoords = GetEntityCoords(closestHydrant)
                local distance = #(playerCoords-hydrantCoords)

                if distance <= 1.5 then
                    
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to connect the refill hose")
                    EndTextCommandDisplayHelp(0, false, true, -1)    
                
                    if IsControlJustPressed(0,38) then
                        firehydrantObj = closestHydrant
                        hoseAttached = true
                        Has_refillHose = false
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Hose successfully connected to the fire hydrant")
                        DrawNotification(false, false)
                    end
                end
            end
        end

        if hoseAttached then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if firehydrantObj ~= nil and DoesEntityExist(firehydrantObj)then
                
                local hydrantCoords = GetEntityCoords(firehydrantObj)
                local distance = #(playerCoords - hydrantCoords)

                if distance <= 1.5 then
                    sleep = 0
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to disconnect the refill hose")
                    EndTextCommandDisplayHelp(0, false, true, -1)

                    if IsControlJustPressed(0,38) then
                        firehydrantObj = nil
                        Has_refillHose = true
                        hoseAttached = false

                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Hose disconnected from the fire hydrant")
                        DrawNotification(false, false)
                    
                    end
                end
            end
        end

    Citizen.Wait(sleep)
    
    end
    
end)
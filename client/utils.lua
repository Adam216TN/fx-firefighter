function LoadPipeModel()
    local hash = GetHashKey("prop_pipe_firefighter")
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 200 do
        RequestModel(hash)
        Citizen.Wait(25)
        timeout = timeout + 1
    end
    return HasModelLoaded(hash) and hash or nil
end

function RotationToFace(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local dz = pos2.z - pos1.z
    local dist_ground = math.sqrt(dx * dx + dy * dy)
    local yaw         = math.atan(dy, dx) * (180.0 / math.pi)
    local pitch       = math.atan(dz, dist_ground) * (180.0 / math.pi)
    return yaw, pitch, 0.0
end

function PlacePipeSegment(obj, pt1, pt2)
    local yaw, pitch, _ = RotationToFace(pt1, pt2)
    SetEntityCoords(obj, pt1.x, pt1.y, pt1.z, false, false, false, false)
    SetEntityRotation(obj, pitch, 0.0, yaw - 90.0, 2, true)
end

function SinusCurve(pt1, pt2, t, amplitude, N)
    local u = 1.0 - t
    local dx = pt2.x - pt1.x
    local dy = pt2.y - pt1.y

    local dist = math.sqrt(dx * dx + dy * dy)

    local pt_base = vector2(u * pt1.x + t * pt2.x, u * pt1.y + t * pt2.y)

    local vectnorm
    if dist < 0.001 then
        vectnorm = vector2(0.0, 0.0)
    else
        vectnorm = vector2(dx / dist, dy / dist)
    end

    local normal = vector2(-vectnorm.y, vectnorm.x)

    local envelope = math.max(0.0, math.sin(math.pi * t))
    local delta = amplitude * envelope * math.sin(2.0 * math.pi * N * t)

    local finalX = pt_base.x + delta * normal.x
    local finalY = pt_base.y + delta * normal.y

    local zline = u * pt1.z + t * pt2.z
    local found, groundZ = GetGroundZFor_3dCoord(finalX, finalY, zline + 1.0, false)
    local targetGroundZ = found and (groundZ + 0.04) or (zline - 1.0)

    local e = math.min(1.0, envelope * 2.0)
    local dropFactor = e * e * (3.0 - 2.0 * e)
    local z = (1.0 - dropFactor) * zline + dropFactor * targetGroundZ

    return vector3(finalX, finalY, z)
end

function GetVehicleByPlate(targetPlate)
    local vehicles = GetGamePool('CVehicle')
    for _, veh in ipairs(vehicles) do
        if GetVehicleNumberPlateText(veh) == targetPlate then
            return veh
        end
    end
    return 0
end
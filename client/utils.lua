function RotationToFace(pos1, pos2)
    local dx = pos2.x - pos1.x
    local dy = pos2.y - pos1.y
    local dz = pos2.z - pos1.z
    local dist_ground = math.sqrt(dx * dx + dy * dy)
    local yaw         = math.atan(dy, dx) * (180.0 / math.pi)
    local pitch       = math.atan(dz, dist_ground) * (180.0 / math.pi)
    return yaw, pitch, 0.0
end

function Bezier(ptA, ptC, ptB, t)
    local u = 1.0 - t
    return vector3(
        u*u*ptA.x + 2*u*t*ptC.x + t*t*ptB.x,
        u*u*ptA.y + 2*u*t*ptC.y + t*t*ptB.y,
        u*u*ptA.z + 2*u*t*ptC.z + t*t*ptB.z
    )
end

function PlacePipeSegment(obj, pt1, pt2)
    local yaw, pitch, _ = RotationToFace(pt1, pt2)
    SetEntityCoords(obj, pt1.x, pt1.y, pt1.z, false, false, false, false)
    SetEntityRotation(obj, pitch, 0.0, yaw - 90.0, 2, true)
end
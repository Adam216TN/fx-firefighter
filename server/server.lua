local Trucks = {}

local function EnsureTruckExists (plate)
    if Trucks[plate] == nil then
        Trucks[plate] = {
            water = 100,
            isRefilling = false,
            isHoseOut = false,
            isRefillHoseOut = false,
            hydrantNetId = nil
        }
    end

end

RegisterNetEvent('fx-firefighter:getServerWater', function(plate)
    local src = source

    EnsureTruckExists(plate)

    TriggerClientEvent('fx-firefighter:setClientWater',src,Trucks[plate].water,plate)
    
end)

RegisterNetEvent('fx-firefighter:consumeServerWater',function (plate)
    
    EnsureTruckExists(plate)
    
    if Trucks[plate].water > 0 then
        Trucks[plate].water = Trucks[plate].water - 1
    
        if Trucks[plate].water <  0 then Trucks[plate].water = 0 end

        TriggerClientEvent('fx-firefighter:setClientWater',-1,Trucks[plate].water,plate)
    end
end)

RegisterNetEvent('fx-firefighter:refillServerWater',function (plate)
    
    EnsureTruckExists(plate)
    
    if Trucks[plate].water < 100 then
        Trucks[plate].water = Trucks[plate].water + 1

        if Trucks[plate].water > 100 then Trucks[plate].water = 100 end

        TriggerClientEvent('fx-firefighter:setClientWater',-1,Trucks[plate].water,plate)
    end

end)

RegisterNetEvent('fx-firefighter:updateTruckState',function (plate,key,value)
    
    EnsureTruckExists(plate)

    Trucks[plate][key] = value

    TriggerClientEvent('fx-firefighter:syncTruckState',-1,plate,Trucks[plate])
    
end)
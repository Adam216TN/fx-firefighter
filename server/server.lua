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


RegisterNetEvent('fx-firefighter:updateTruckState',function (plate,key,value)
    
    EnsureTruckExists(plate)

    Trucks[plate][key] = value

    TriggerClientEvent('fx-firefighter:syncTruckState',-1,plate,Trucks[plate])
    
end)


RegisterNetEvent('fx-firefighter:requestAllTrucks', function()
    local src = source
    TriggerClientEvent('fx-firefighter:syncAllTrucks', src, Trucks)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        for plate, truck in pairs(Trucks) do
            if truck.isRefilling then
                if truck.water < 100 then
                    truck.water = truck.water + 1
                    TriggerClientEvent('fx-firefighter:setClientWater', -1, truck.water, plate)
                else
                    truck.isRefilling = false
                    TriggerClientEvent('fx-firefighter:syncTruckState', -1, plate, truck)
                end
            end
        end
    end
end)
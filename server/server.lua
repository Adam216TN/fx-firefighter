local Trucks = {}

RegisterNetEvent('fx-firefighter:getServerWater', function(plate)
    local src = source

    if Trucks[plate] == nil then
        Trucks[plate] = 100
    end

    TriggerClientEvent('fx-firefighter:setClientWater',src,Trucks[plate],plate)
    
end)

RegisterNetEvent('fx-firefighter:consumeServerWater',function (plate)
    
    local src = source

    if Trucks[plate] ~= nil and Trucks[plate] > 0 then
        Trucks[plate] = Trucks[plate] - 1
    

        if Trucks[plate] < 0 then Trucks[plate] = 0 end

        TriggerClientEvent('fx-firefighter:setClientWater',-1,Trucks[plate],plate)
    end
end)

RegisterNetEvent('fx-firefighter:refillServerWater',function (plate)
    
    if Trucks[plate] ~=nil and Trucks[plate] < 100 then
        Trucks[plate] = Trucks[plate] + 1

        if Trucks[plate] > 100 then Trucks[plate] = 100 end

        TriggerClientEvent('fx-firefighter:setClientWater',-1,Trucks[plate],plate)
    end

end)
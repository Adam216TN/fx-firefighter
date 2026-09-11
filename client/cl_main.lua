TrucksClient = {}

RegisterNetEvent('fx-firefighter:syncTruckState',function (plate,state)
    TrucksClient[plate] = state
end)


RegisterNetEvent('fx-firefighter:syncAllTrucks', function(allTrucks)
    TrucksClient = allTrucks
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent('fx-firefighter:requestAllTrucks')
    end
end)

CurrentWater = 100

Has_hose = false
HoldingHosePlate = nil
HoseObject = 0

Has_refillHose = false
HoldingRefillPlate = nil
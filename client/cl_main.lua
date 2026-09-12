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

Citizen.CreateThread(function ()
    while true do
        local sleep = 1000
        local playerPedId = PlayerPedId()

        if IsPedInAnyVehicle(playerPedId, false) then
            local vehicle = GetVehiclePedIsIn(playerPedId,false)
            if GetPedInVehicleSeat(vehicle,-1) == playerPedId and GetEntityModel(vehicle) == GetHashKey("firetruk") then
                local plate = GetVehicleNumberPlateText(vehicle)
                local state = TrucksClient[plate]

                if state and (state.isHoseOut or state.isRefillHoseOut) then
                    
                    sleep = 0
                    SetVehicleEngineOn(vehicle, false, true, true)
                    DisableControlAction(0, 71, true)
                    DisableControlAction(0, 72, true)
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)
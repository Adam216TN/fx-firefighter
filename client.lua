--print("[DEBUG SYSTEM] Le fichier client.lua est bien charge et actif !")

local currentWater = 100
local panelOpen = false
local lastNotif = nil

RegisterNetEvent('fx-firefighter:setClientWater')
AddEventHandler('fx-firefighter:setClientWater', function(waterServ, plateServ)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local hash_firetruck = GetHashKey('firetruk')
        
    local closest_firetruck = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 15.0, hash_firetruck, 70)

    if closest_firetruck ~= 0 then
        local myPlate = GetVehicleNumberPlateText(closest_firetruck)

        if myPlate == plateServ then
            currentWater = waterServ
        end
    end
end)

RegisterCommand('checkwater', function(source)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        if GetEntityModel(vehicle) == GetHashKey('firetruk') then
            SetNotificationTextEntry("STRING")
            AddTextComponentString("Tank : " .. currentWater .. "/100 litres")
            DrawNotification(false, false)
        else
            SetNotificationTextEntry("STRING")
            AddTextComponentString("That's not a firetruck")
            DrawNotification(false, false)
        end
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString("You are on foot")
        DrawNotification(false, false)
    end
end, false)


Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local hash_firetruck = GetHashKey('firetruk')
        
        local closest_firetruck = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 15.0, hash_firetruck, 70)
        
        if closest_firetruck ~= 0 then
            local myPlate = GetVehicleNumberPlateText(closest_firetruck)
            local firetruckCoords = GetEntityCoords(closest_firetruck)
            local distance = #(playerCoords - firetruckCoords)
            
            if distance <= 4.0 then
                sleep = 0
                
                if not panelOpen then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to open the water panel")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                else
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName("Tank: ~b~" .. currentWater .. "~s~/100L~n~~INPUT_CONTEXT~ Close | ~INPUT_DETONATE~ Use 1L")
                    EndTextCommandDisplayHelp(0, false, true, -1)
                end
                
                if IsControlJustPressed(0, 38) then
                    if panelOpen then
                        panelOpen = false
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Water panel closed")
                        lastNotif = DrawNotification(false, false)
                    else
                        panelOpen = true
                        
                        TriggerServerEvent('fx-firefighter:getServerWater', myPlate)
                        
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("Water panel opened")
                        lastNotif = DrawNotification(false, false)
                    end
                end
                
                
                if panelOpen and IsControlJustPressed(0, 47) then
                    if currentWater > 0 then
                        
                        TriggerServerEvent('fx-firefighter:consumeServerWater', myPlate)
                        
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        
                        AddTextComponentString("You consume water") 
                        lastNotif = DrawNotification(false, false)
                    else
                        if lastNotif ~= nil then RemoveNotification(lastNotif) end
                        SetNotificationTextEntry("STRING")
                        AddTextComponentString("The tank is empty")
                        lastNotif = DrawNotification(false, false)
                    end
                end
                
            end
        end
        Citizen.Wait(sleep)
    end
end)
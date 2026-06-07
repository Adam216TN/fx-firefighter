--print("[DEBUG SYSTEM] Le fichier client.lua est bien charge et actif !")

RegisterCommand('checkwater',function (source)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(),false)
    if vehicle ~= 0 then
        if GetEntityModel(vehicle) == GetHashKey('firetruk') then
            SetNotificationTextEntry("STRING")
            AddTextComponentString("Tank : 100/100 litres")
            DrawNotification(false,false)
        else
            SetNotificationTextEntry("STRING")
            AddTextComponentString("That's not a firetruck")
            DrawNotification(false,false)
            --print("That's not a firetruck")
        end
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString("You are on foot")
        DrawNotification(false,false)
    end
    
    
end,false)


Citizen.CreateThread(function()
    while true do
        
        local sleep = 1000
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local hash_firetruck = GetHashKey('firetruk')
        
        local closest_firetruck = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 15.0, hash_firetruck, 70)
        
        if closest_firetruck ~= 0 then
            --print("[DEBUG] Camion trouvé ! ID de l'entité : " .. tostring(closest_firetruck))
            
            local firetruckCoords = GetEntityCoords(closest_firetruck)
            
            local distance = #(playerCoords - firetruckCoords)
            --print("[DEBUG] Distance actuelle avec le camion : " .. tostring(distance))
            
            if distance <= 4.0 then
                
                sleep = 0
                
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName("Press ~INPUT_CONTEXT~ to open the water panel")
                EndTextCommandDisplayHelp(0, false, true, -1)
                
                if IsControlJustPressed(0,38) then
                    --print("[DEBUG] Tu as appuye sur E")
                    SetNotificationTextEntry("STRING")
                    AddTextComponentString("You pressed E")
                    DrawNotification(false, false)
                end
                
            end
        end
        Citizen.Wait(sleep)
    end
end)
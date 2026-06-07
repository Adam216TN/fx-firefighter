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
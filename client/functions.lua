DeleteActualVeh = function()
    if DoesEntityExist(cachedData["vehicle"]) then
        DeleteEntity(cachedData["vehicle"])
    end
end

-- Finds a vehicle by the given plate
FindVehicleByPlate = function(plate)
    local gameVehicles = esx.Game.GetVehicles()
    for i = 1, #gameVehicles do
        local vehicle = gameVehicles[i]
        
        if DoesEntityExist(vehicle) then
            if Config.Trim(GetVehicleNumberPlateText(vehicle)) == Config.Trim(plate) then
                return vehicle
            end
        end
    end
    
    return nil
end

--Spawns a local vehicle
SpawnLocalVehicle = function(data)
    local vehicleProps = data
    if not vehicleProps.model then
        vehicleProps = data[1]
    end
    
    local spawnpoint = Config.Garages[cachedData["currentGarage"]]["positions"]["vehicle"]
    
    WaitForModel(vehicleProps["model"])
    
    if DoesEntityExist(cachedData["vehicle"]) then
        DeleteEntity(cachedData["vehicle"])
    end
    
    if not esx.Game.IsSpawnPointClear(spawnpoint["position"], 3.0) then
        --TriggerEvent('notification', 'Please move the vehicle off the road', 1)
        esx.ShowNotification('~r~There is a vehicle occupying the space. Please remove it.', false, false, 13)
        return
    end
    
    if not IsModelValid(vehicleProps["model"]) then
        return
    end
    
    esx.Game.SpawnLocalVehicle(vehicleProps["model"], spawnpoint["position"], spawnpoint["heading"], function(yourVehicle)
        cachedData["vehicle"] = yourVehicle
        SetVehicleProperties(yourVehicle, vehicleProps)
        SetModelAsNoLongerNeeded(vehicleProps["model"])
    end)
end

-- Spawns a vehicle for real
SpawnVehicle = function(data, isRecovery)
    local vehicleProps = data[1]
    local spawnpoint = Config.Garages[cachedData["currentGarage"]]["positions"]["vehicle"]
    
    if isRecovery == true and Config.AllowRecovery == false then
        print('Cannot attempt recovery because it has been disabled!')
        esx.ShowNotification('~r~Vehicle recovery has been disabled.', true, false, 13)
        return
    end
    
    -- Ensure we are allowed to spawn a vehicle here
    WaitForModel(vehicleProps["model"])
    if DoesEntityExist(cachedData["vehicle"]) then
        DeleteEntity(cachedData["vehicle"])
    end
    
    if not esx.Game.IsSpawnPointClear(spawnpoint["position"], 3.0) then
        esx.ShowNotification('~r~There is a vehicle occupying the space. Please remove it.', false, false, 13)
        return
    end
    
    -- Make sure the vehicle doesn't already exist
    local existingVehicle = FindVehicleByPlate(vehicleProps["plate"])
    if existingVehicle ~= nil then
        if esx.Game.IsVehicleEmpty(existingVehicle) then
            if Config.AllowTows then
                -- Pay for the tow
                esx.TriggerServerCallback("skull_garage:pay", function(success, amount)
                    if success then
                        -- Teleport the vehicle here
                        esx.Game.Teleport(existingVehicle, spawnpoint["position"], function()
                            esx.ShowNotification('Your vehicle has been towed here for ~r~' .. tomoney(amount), false, false, 13)
                            CloseMenu()
                        end)
                    else
                        esx.ShowNotification('Cannot recover your vehicle. Requires a payment of ~r~' .. tomoney(amount), false, false, 130)
                    end
                end)
            else
                -- The vehicle is on the street but we dont allow tows
                esx.ShowNotification('Your vehicle is already in the streets.', false, false, 13)
            end
        else
            -- Someone is currently in the vehicle
            esx.ShowNotification('Sorry, but your vehicle has currently been ~r~stolen~s~!.', false, true, 13)
        end
        
        -- Always abort here cause the vehicle exists
        return
    end
    
    -- Close the menu
    CloseMenu()
    
    -- This callback will actually spawn the vehicle if we are allowed, otherwise will give us a notif
    local callback = function(success, amount)
        if success then
            esx.Game.SpawnVehicle(vehicleProps["model"], spawnpoint["position"], spawnpoint["heading"], function(yourVehicle)
                SetVehicleProperties(yourVehicle, vehicleProps)
                SetModelAsNoLongerNeeded(vehicleProps["model"])
                
                TaskWarpPedIntoVehicle(PlayerPedId(), yourVehicle, -1)
                
                SetEntityAsMissionEntity(yourVehicle)
                local gps = AddBlipForEntity(yourVehicle)
                SetBlipSprite(gps, 225)
                SetBlipColour(gps, 4)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString('Vehicle GPS')
                EndTextCommandSetBlipName(gps)
                
                SetEntityAsMissionEntity(yourVehicle, true, true)
                
                local plate = GetVehicleNumberPlateText(yourVehicle)
                TriggerServerEvent('garage:addKeys', plate)
                Citizen.Wait(100)
                TriggerServerEvent('erp_garage:modifystate', vehicleProps, 0, nil)
            end)
            
            if isRecovery then
                esx.ShowNotification('You have ~g~recovered~s~ your vehicle for ~r~' .. tomoney(amount), false, true)
            else
                esx.ShowNotification('Your vehicle is ready', false, true)
            end
        else
            esx.ShowNotification('Cannot recover your vehicle. Requires a payment of ~r~' .. tomoney(amount), false, false, 130)
        end
    
    end
    
    -- Trigger the event
    if isRecovery then
        esx.TriggerServerCallback("skull_garage:pay", callback)
    else
        callback(true, 0)
    end
end

PutInVehicle = function()
    local vehicle = GetVehiclePedIsUsing(PlayerPedId())
    
    if DoesEntityExist(vehicle) then
        local vehicleProps = GetVehicleProperties(vehicle)
        esx.TriggerServerCallback("erp_garage:validateVehicle", function(valid)
            if valid then
                AbrirMenuGuardar()
            else
                CloseMenu()
                esx.ShowNotification('This vehicle does not ~r~belong~s~ to you')
            end
        
        end, vehicleProps)
    end
end

function deleteCar(entity)
    Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(entity))
end

SaveInGarage = function(garage)
    ClearMenu()
    local vehicle = GetVehiclePedIsUsing(PlayerPedId())
    local vehicleProps = GetVehicleProperties(vehicle)
    TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
    
    while IsPedInVehicle(PlayerPedId(), vehicle, true) do
        Citizen.Wait(0)
    end
    Citizen.Wait(300)
    
    
    -- TriggerEvent('notification', 'You saved your vehicle in garage '..garage, 3)
    esx.ShowNotification('Vehicle ~g~stored~s~ in the garage ' .. garage)
    Citizen.Wait(500)
    
    deleteCar(vehicle)
    TriggerServerEvent('erp_garage:modifystate', vehicleProps, 1, garage)
    CloseMenu()
end

SetVehicleProperties = function(vehicle, vehicleProps)
    esx.Game.SetVehicleProperties(vehicle, vehicleProps)
    
    SetVehicleEngineHealth(vehicle, vehicleProps["engineHealth"] and vehicleProps["engineHealth"] + 0.0 or 1000.0)
    SetVehicleBodyHealth(vehicle, vehicleProps["bodyHealth"] and vehicleProps["bodyHealth"] + 0.0 or 1000.0)
    SetVehicleFuelLevel(vehicle, vehicleProps["fuelLevel"] and vehicleProps["fuelLevel"] + 0.0 or 1000.0)
    
    if vehicleProps["windows"] then
        for windowId = 1, 13, 1 do
            if vehicleProps["windows"][windowId] == false then
                SmashVehicleWindow(vehicle, windowId)
            end
        end
    end
    
    if vehicleProps["tyres"] then
        for tyreId = 1, 7, 1 do
            if vehicleProps["tyres"][tyreId] ~= false then
                SetVehicleTyreBurst(vehicle, tyreId, true, 1000)
            end
        end
    end
    
    if vehicleProps["doors"] then
        for doorId = 0, 5, 1 do
            if vehicleProps["doors"][doorId] ~= false then
                SetVehicleDoorBroken(vehicle, doorId - 1, true)
            end
        end
    end
end

GetVehicleProperties = function(vehicle)
    if DoesEntityExist(vehicle) then
        local vehicleProps = esx.Game.GetVehicleProperties(vehicle)
        
        vehicleProps["tyres"] = {}
        vehicleProps["windows"] = {}
        vehicleProps["doors"] = {}
        
        for id = 1, 7 do
            local tyreId = IsVehicleTyreBurst(vehicle, id, false)
            
            if tyreId then
                vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = tyreId
                
                if tyreId == false then
                    tyreId = IsVehicleTyreBurst(vehicle, id, true)
                    vehicleProps["tyres"][#vehicleProps["tyres"]] = tyreId
                end
            else
                vehicleProps["tyres"][#vehicleProps["tyres"] + 1] = false
            end
        end
        
        for id = 1, 13 do
            local windowId = IsVehicleWindowIntact(vehicle, id)
            
            if windowId ~= nil then
                vehicleProps["windows"][#vehicleProps["windows"] + 1] = windowId
            else
                vehicleProps["windows"][#vehicleProps["windows"] + 1] = true
            end
        end
        
        for id = 0, 5 do
            local doorId = IsVehicleDoorDamaged(vehicle, id)
            
            if doorId then
                vehicleProps["doors"][#vehicleProps["doors"] + 1] = doorId
            else
                vehicleProps["doors"][#vehicleProps["doors"] + 1] = false
            end
        end
        
        vehicleProps["engineHealth"] = GetVehicleEngineHealth(vehicle)
        vehicleProps["bodyHealth"] = GetVehicleBodyHealth(vehicle)
        vehicleProps["fuelLevel"] = GetVehicleFuelLevel(vehicle)
        
        return vehicleProps
    end
end

HandleAction = function(action)
    if action == "menu" then
        OpenGarageMenu()
    elseif action == "vehicle" then
        PutInVehicle()
    end
end

-- Detatches the camera from the garage
DetatchGarageCamera = function() 
    -- currentGarage = cachedData["currentGarage"]
    -- if not currentGarage then
    --     return false
    -- end

    print('Detatch Camera ')    

    -- Destroy the cam
    if cachedData["cam"] then
        DestroyCam(cachedData["cam"])
    end
        
    -- Revert
    RenderScriptCams(0, 1, 750, 1, 0)
    return true
end

-- Attaches the camera to a particular garage
AttachGarageCamera = function(garage)
    if not garage then return; end

    local Camerapos = Config.Garages[garage]["camera"]    
    if not Camerapos then return end
    
    print('Attach Camera Camera ' .. garage)    

    -- Clear previous camera
    if cachedData["cam"] then
        DestroyCam(cachedData["cam"])
    end
    
    -- Create the script and make it active
    cachedData["cam"] = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cachedData["cam"], Camerapos["x"], Camerapos["y"], Camerapos["z"])
    SetCamRot(cachedData["cam"], Camerapos["rotationX"], Camerapos["rotationY"], Camerapos["rotationZ"])
    SetCamActive(cachedData["cam"], true)
    
    -- Render the script
    RenderScriptCams(1, 1, 750, 1, 1)
    Citizen.Wait(500)
end

DrawScriptMarker = function(markerData)
    -- Get the position and snap it to the ground
    local pos = markerData["pos"]
    local retval, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, 0)
    if retval then
        pos = vector3(pos.x, pos.y, groundZ)
    end

    -- Prepare the markers
    local size  = { x = markerData["sizeX"], y = markerData["sizeX"], z = 1.0 }
    local colour = Config.Colour

    -- Draw the markers and show the interact text
    DrawMarker(1, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size.x, size.y, size.z, colour.r, colour.g, colour.b, 0.05, 0, 0, 0, 0, 0, 0, 0)
    esx.ShowHelpNotification("Press ~g~E~s~ to interact with the garage at the coloured markers")

    --esx.ShowHelpNotification("~g~E ~w~or ~g~ENTER ~w~Accepts ~g~Arrows ~w~Move ~g~Backspace ~w~Exit")
end

PlayAnimation = function(ped, dict, anim, settings)
    if dict then
        Citizen.CreateThread(function()
            RequestAnimDict(dict)
            
            while not HasAnimDictLoaded(dict) do
                Citizen.Wait(100)
            end
            
            if settings == nil then
                TaskPlayAnim(ped, dict, anim, 1.0, -1.0, 1.0, 0, 0, 0, 0, 0)
            else
                local speed = 1.0
                local speedMultiplier = -1.0
                local duration = 1.0
                local flag = 0
                local playbackRate = 0
                
                if settings["speed"] then
                    speed = settings["speed"]
                end
                
                if settings["speedMultiplier"] then
                    speedMultiplier = settings["speedMultiplier"]
                end
                
                if settings["duration"] then
                    duration = settings["duration"]
                end
                
                if settings["flag"] then
                    flag = settings["flag"]
                end
                
                if settings["playbackRate"] then
                    playbackRate = settings["playbackRate"]
                end
                
                TaskPlayAnim(ped, dict, anim, speed, speedMultiplier, duration, flag, playbackRate, 0, 0, 0)
            end
            
            RemoveAnimDict(dict)
        end)
    else
        TaskStartScenarioInPlace(ped, anim, 0, true)
    end
end

WaitForModel = function(model)
    local DrawScreenText = function(text, red, green, blue, alpha)
        SetTextFont(4)
        SetTextScale(0.0, 0.5)
        SetTextColour(red, green, blue, alpha)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(0.5, 0.5)
    end
    
    if not IsModelValid(model) then
        print('Model does not exist in the game')
        return TriggerEvent('notification', 'This model does not exist in the game, send a report!', 2)
    end
    
    if not HasModelLoaded(model) then
        RequestModel(model)
    end
    
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
        
        DrawScreenText("Looking for you " .. GetDisplayNameFromVehicleModel(model) .. "...", 255, 255, 255, 150)
    end
end

--Converts the value to money
function tomoney(value)
    if value == nil then
        return '~g~FREE'
    end

    return '$' .. tostring(esx.Math.GroupDigits(value))
end

local ultimaAccion = nil
local currentGarage = nil
local fetchedVehicles = {}
local recoveryVehicles = {}

-- Opens the garage menu
function MenuGarage(action)
    if not action then action = ultimaAccion; elseif not action and not ultimaAccion then action = "menu"; end
    ped = GetPlayerPed(-1);
    MenuTitle = "Garage"
    OpenMenu()
    ultimaAccion = action
    Citizen.Wait(150)
    DeleteActualVeh()
    if action == "menu" then
        if Config.AllowRecovery then
            -- Show the recovery options
            Menu.addButton("Parked Vehicles", "MenuVehicleList", nil)-- Lists all Vehicles
            Menu.addButton("Vehicle Recovery", "MenuRecoveryList", nil)-- Lists all recoveries
            Menu.addButton("Close", "CloseMenu", nil)-- Closes the menu
        else
            -- Immediately show the menu
            MenuVehicleList()
        end
    elseif action == "vehicle" then
        PutInVehicle()
    end
end

-- Adds a table of vehicles to the menu.
-- It will sort recovery vehicles out.
function AddVehicles(vehicles)
    local garage = {}
    local recovs = {}
    for c, v in pairs(vehicles) do
        print(tostring(c) .. " - " .. v.garage .. " - " .. v.plate)
        if (v.state == 1 or v.state == true) and v.garage ~= nil and v.garage ~= "OUT" then
            --The vehicle is in a valid recovery state, so show in the garage menu
            print(" - Garage")
            table.insert(garage, {["garage"] = v.garage, ["vehiculo"] = json.decode(v.vehicle), ["state"] = v.state, ["plate"] = v.plate})
        else
            --The vehicle is not in a valid recovery state, so show in the recovery
            print(" - Impounded")
            table.insert(recovs, {["garage"] = "OUT", ["vehiculo"] = json.decode(v.vehicle), ["state"] = v.state, ["plate"] = v.plate})
        end
    end
    fetchedVehicles = garage
    recoveryVehicles = recovs
end

-- Adds a list of vehicles to the impound list
-- @deprecated
function EnvioVehFuera(data)
    local slots = {}
    for c, v in pairs(data) do
        print(v.state)
        if v.state == 0 or v.state == 2 or v.state == false or v.garage == nil then
            table.insert(slots, {["vehiculo"] = json.decode(v.vehicle), ["state"] = v.state})
        end
    end
    recoveryVehicles = slots
end


-- Attempts to recover the vehicle
function RecoverVehicle(vehicle)
    if Config.AllowRecovery == false then
        print('Cannot attempt recovery because it has been disabled!')
        esx.ShowNotification('~r~Vehicle recovery has been disabled.', true, false, 13)
        return
    end

    -- Early refusal if its in police impound
    if vehicle.state == 2 then
        print('Cannot attempt recovery because vehicle is in police impound');
        esx.ShowNotification('~r~Vehicle is in the ~b~police impound~r~ and cannot be recovered.');
        return
    end
    
    print('Attempted Recovery: ' .. vehicle.plate)
    esx.TriggerServerCallback('skull_garage:checkPurchase', function(valid, cost)
        print("event callback")
        if valid == true then
            -- We were succesful!
            print('Recovery: Enough Money');
            SpawnVehicle({vehicle, nil}, true)
        elseif valid == "in-debt" then
            --  We own the governmnet money
            print('Recovery: In Debt');
            MenuRecoveryList()
            esx.ShowNotification('You owe the government more than ~r~' .. tomoney(cost) .. '~s~, you can\'t get your car back until you pay your fines!')
        else
            -- We dont have enough money
            print('Not enough money. Recovery costs ' .. tomoney(result));
            MenuRecoveryList()
            esx.ShowNotification('Not enough money. Recovery costs ~r~' .. tomoney(cost), false, false, 130)
        end
    end)
end


function AbrirMenuGuardar()
    currentGarage = cachedData["currentGarage"]
    if not currentGarage then
        CloseMenu()
        return
    end
    ped = GetPlayerPed(-1);
    MenuTitle = "Save :"
    ClearMenu()
    Menu.addButton("Cancel", "CloseMenu", nil)
    Menu.addButton("STORE VEHICLE INTO " .. currentGarage, "SaveInGarage", currentGarage, "", "", "", "DeleteActualVeh")
end

-- Lists the recoveries
function MenuRecoveryList()
    currentGarage = cachedData["currentGarage"]
    
    if not currentGarage then
        CloseMenu()
        return
    end
    
    
    if Config.AllowRecovery == false then
        print('Cannot attempt recovery because it has been disabled!')
        esx.ShowNotification('~r~Vehicle recovery has been disabled.', true, false, 13)
        CloseMenu()
        return
    end
    
    HandleCamera(currentGarage, true)
    ped = GetPlayerPed(-1);
    MenuTitle = "Recovery"
    ClearMenu()
    Menu.addButton("back", "MenuGarage", nil)
    for c, v in pairs(recoveryVehicles) do
        local vehicle = v.vehiculo
        local entity = FindVehicleByPlate(vehicle.plate)
        
        -- Get the text version of the state.
        -- This is a guess
        local state = "N/A"
        if entity ~= nil then
            state = "STREET PARKED"
        elseif v.state == 0 then
            state = "IMPOUNDED"
        elseif (v.state == 1 or v.state == true) then
            state = "STORED"
        elseif v.state == 2 then
            state = "POLICE IMPOUNDED"
        end
        
        if v.state == 0 or v.state == false then
            Menu.addButton(
                "" .. (vehicle.plate) .. "    " .. GetDisplayNameFromVehicleModel(vehicle.model), -- Button Name
                "RecoverVehicle",
                vehicle,
                state,
                " Motor : " .. round(vehicle.engineHealth) / 10 .. "%",
                " Fuel : " .. round(vehicle.fuelLevel) .. "%",
                "SpawnLocalVehicle"
        )
        end
    end
end

-- Displays a list of vehicles
function MenuVehicleList()
    currentGarage = cachedData["currentGarage"]
    
    if not currentGarage then
        CloseMenu()
        return
    end
    
    HandleCamera(currentGarage, true)
    ped = GetPlayerPed(-1);
    MenuTitle = "My vehicles :"
    ClearMenu()
    
    if Config.AllowRecovery then
        -- If we are allowing recovery, then this menu goes back
        Menu.addButton("back", "MenuGarage", nil)
    else
        -- We dont allow recovery, so this menu closes
        Menu.addButton("Close", "CloseMenu", nil)
    end
    
    for c, v in pairs(fetchedVehicles) do
        if v then
            local vehicle = v.vehiculo
            Menu.addButton(
                "" .. (vehicle.plate) .. "    " .. GetDisplayNameFromVehicleModel(vehicle.model), -- Button Name
                --"OptionVehicle",                                                            -- Button Callback
                "SpawnVehicle", -- That extra button sucks
                {vehicle, nil}, -- Callback Options
                "garage: " .. currentGarage .. "", -- Additional data
                " Motor : " .. round(vehicle.engineHealth) / 10 .. "%",
                " Fuel : " .. round(vehicle.fuelLevel) .. "%",
                "SpawnLocalVehicle" -- Hover Callback
        )
        end
    end
end

function round(n)
    if not n then return 0; end
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

-- @deprecated was originally used to add extra options to the vehicle
function OptionVehicle(data)
    MenuTitle = "Options :"
    ClearMenu()
    Menu.addButton("back", "MenuVehicleList", nil)
    Menu.addButton("Spawn Vehicle", "SpawnVehicle", data)
end


function LocalPed()
    return GetPlayerPed(-1)
end

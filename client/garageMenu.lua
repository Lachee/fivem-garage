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
        Menu.addButton("List of vehicles","MenuVehicleList",nil)      -- Lists all Vehicles
        Menu.addButton("Recover","MenuRecoveryList",nil)                   -- Lists all recoveries
        Menu.addButton("Close","CloseMenu",nil)                     -- Closes the menu
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
        print("Checking Vehicle:")
        print(" - C:        " .. c)
        print(" - Vehicle:  " .. v.vehicle)
        print(" - Garage:   " .. v.garage)
        print(" - State:    " .. v.state) 
        
        if v.state == 1 and v.garage ~= nil and v.garage ~= "OUT" then
            --The vehicle is in a valid recovery state, so show in the garage menu
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
    for c,v in pairs(data) do
        print(v.state)
        if v.state == 0 or v.state == 2 or v.state == false or v.garage == nil then
            table.insert(slots,{["vehiculo"] = json.decode(v.vehicle),["state"] = v.state})
        end
    end
    recoveryVehicles = slots
end


-- Attempts to recover the vehicle
function RecoverVehicle(vehicle)
    print('Attempted Recovery: ' .. vehicle.plate)
    esx.TriggerServerCallback('erp_garage:checkMoney', function(hasEnoughMoney)
        if hasEnoughMoney == true then
            print('Recovery: Enough Money');
            SpawnVehicle({vehicle, nil}, true)
            TriggerEvent('notification', 'Vehicle recovered', 2)
        elseif hasEnoughMoney == "deudas" then
            print('Recovery: In Debt');
            MenuRecoveryList()
            TriggerEvent('notification', 'You owe the government more than $ 2000, you can\'t get your car back until you pay your fines!', 2)
        else
            print('Recovery: Not Enough Money');
            MenuRecoveryList()
            TriggerEvent('notification', 'There\'s no money on it', 2)
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
   Menu.addButton("CLOSE","CloseMenu",nil)
   Menu.addButton("GARAGE: "..currentGarage.." | STORING THE CAR", "SaveInGarage", currentGarage, "", "", "","DeleteActualVeh")
end

-- Lists the recoveries
function MenuRecoveryList()
    currentGarage = cachedData["currentGarage"]

    if not currentGarage then
        CloseMenu()
        return 
    end

    print('Recovery to Garage:');
    print(currentGarage);

   HandleCamera(currentGarage, true)
   ped = GetPlayerPed(-1);
   MenuTitle = "Recover :"
   ClearMenu()
   Menu.addButton("Turn back","MenuGarage",nil)
    for c,v in pairs(recoveryVehicles) do
        local vehicle = v.vehiculo

        -- Get the text version of the state.
        -- This is a guess
        local state = "STOLEN"
        if v.state == 0 then
            state = "MISSING"
        elseif v.state == 1 then 
            state = "STORED"
        elseif v.state == 2 then
            state = "IMPOUNDED"
        end

        if v.state == 0 or v.state == false then
            Menu.addButton(
                "" ..(vehicle.plate).." | "..GetDisplayNameFromVehicleModel(vehicle.model), -- Button Name
                "RecoverVehicle", 
                vehicle, 
                state, 
                " Motor : " .. round(vehicle.engineHealth) /10 .. "%", 
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
   Menu.addButton("Turn back","MenuGarage",nil)
    for c,v in pairs(fetchedVehicles) do
        if v then
            local vehicle = v.vehiculo
            Menu.addButton(
                "" ..(vehicle.plate).." | "..GetDisplayNameFromVehicleModel(vehicle.model), -- Button Name
                "OptionVehicle",                                                            -- Button Callback
                {vehicle,nil},                                                              -- Callback Options
                "garage: "..currentGarage.."",                                              -- Additional data
                " Motor : " .. round(vehicle.engineHealth) /10 .. "%", 
                " Fuel : " .. round(vehicle.fuelLevel) .. "%",
                "SpawnLocalVehicle"                                                         -- Hover Callback
            )
        end
    end
end

function round(n)
    if not n then return 0; end
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function OptionVehicle(data)
   MenuTitle = "Options :"
   ClearMenu()
   Menu.addButton("Spawn Vehicle", "SpawnVehicle", data)
   Menu.addButton("Turn back", "MenuVehicleList", nil)
end

function CloseMenu()
    HandleCamera(currentGarage, false)
	TriggerEvent("inmenu",false)
    Menu.hidden = true
end

function LocalPed()
	return GetPlayerPed(-1)
end

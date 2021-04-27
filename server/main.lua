esx = nil

local cachedData = {}
local recoveryCost = Config.RecoveryCost;

TriggerEvent("esx:getSharedObject", function(library)
    esx = library
end)

esx.RegisterServerCallback("erp_garage:fetchVehicles", function(source, callback, garage)
    local xPlayer = esx.GetPlayerFromId(source)
    
    if xPlayer then
     
        
        
        -- if garage then
        -- 	sqlQuery = [[
        -- 		SELECT
        -- 			plate, vehicle
        -- 		FROM
        -- 			owned_vehicles
        -- 		WHERE
        -- 			owner = @cid and garage = @garage
        -- 	]]
        -- end
        
        local identifier = xPlayer.getIdentifier()
        local data = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner=@identifier", {['@identifier'] = identifier})
        print(esx.DumpTable(data));
        callback(data)
    else
        print('Player doesnt exists')
        callback(false)
    end
end)

-- Gets a list of vehicles that are currently out of a garage and returns it in the callback
function getPlayerVehiclesOut(identifier, cb)
    local vehicles = {}
    local data = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner=@identifier", {['@identifier'] = identifier})
    cb(data)
end

esx.RegisterServerCallback("erp_garage:validateVehicle", function(source, callback, vehicleProps, garage)
    local player = esx.GetPlayerFromId(source)
    
    if player then
        local sqlQuery = [[
			SELECT
				owner
			FROM
				owned_vehicles
			WHERE
				plate = @plate
		]]
        
        
        
        
        
        
        
        
        MySQL.Async.fetchAll(sqlQuery, {
            ["@plate"] = vehicleProps["plate"]
        }, function(responses)
            if responses[1] then
                callback(true)
            else
                callback(false)
            end
        end)
    else
        callback(false)
    end
end)
-- Used to precheck if they can pay.
esx.RegisterServerCallback('skull_garage:checkPurchase', function(source, cb)
    local xPlayer = esx.GetPlayerFromId(source)
    local deudas = 0
    
    -- Debots not workign for some reason
    -- local result = MySQL.Sync.fetchAll('SELECT amount FROM billing WHERE identifier = @identifier',{['@identifier'] = xPlayer.identifier})
    -- if #results > 0 then
    --  	print("User has debt to pay")
    --  	for i=1, #result, 1 do
    -- 		deudas = deudas + result[i].amount
    -- 		if deudas >= 2000 then
    -- 				print('user in governmental debt. Cannot tow!')
    -- 			cb("in-debt", deudas)
    -- 		end
    --  	end
    -- end
    local money = xPlayer.getMoney()
    if money >= recoveryCost then
        cb(true, recoveryCost)
    else
        cb(false, recoveryCost)
    end
end)

-- Called when they go to make the purchase and actually recover the vehicle
esx.RegisterServerCallback('skull_garage:pay', function(source, callback)
    local xPlayer = esx.GetPlayerFromId(source)
    
    --Check they have the money
    local money = xPlayer.getMoney()
    if money >= recoveryCost then
        --Remove the money
        xPlayer.removeMoney(200)
        callback(true, recoveryCost)
    else
        -- Malicious client?
        print("User attempted to pay for a recovery without having cash. Hacked client?")
        callback(false, recoveryCost)
    end

end)

RegisterServerEvent('erp_garage:modifystate')
AddEventHandler('erp_garage:modifystate', function(vehicleProps, state, garage)
    local _source = source
    local xPlayer = esx.GetPlayerFromId(_source)
    local plate = vehicleProps.plate
    
    if garage == nil then
        MySQL.Sync.execute("UPDATE owned_vehicles SET garage=@garage WHERE plate=@plate", {['@garage'] = "OUT", ['@plate'] = plate})
        MySQL.Sync.execute("UPDATE owned_vehicles SET vehicle=@vehicle WHERE plate=@plate", {['@vehicle'] = json.encode(vehicleProps), ['@plate'] = plate})
        MySQL.Sync.execute("UPDATE owned_vehicles SET state=@state WHERE plate=@plate", {['@state'] = state, ['@plate'] = plate})
    else
        
        MySQL.Sync.execute("UPDATE owned_vehicles SET garage=@garage WHERE plate=@plate", {['@garage'] = garage, ['@plate'] = plate})
        MySQL.Sync.execute("UPDATE owned_vehicles SET vehicle=@vehicle WHERE plate=@plate", {['@vehicle'] = json.encode(vehicleProps), ['@plate'] = plate})
        MySQL.Sync.execute("UPDATE owned_vehicles SET state=@state WHERE plate=@plate", {['@state'] = state, ['@plate'] = plate})
    
    end
end)

RegisterServerEvent('erp_garage:modifyHouse')
AddEventHandler('erp_garage:modifyHouse', function(vehicleProps)
    local _source = source
    local xPlayer = esx.GetPlayerFromId(_source)
    local plate = vehicleProps.plate
    print(json.encode(plate))
    
    --MySQL.Sync.execute("UPDATE owned_vehicles SET garage=@garage WHERE plate=@plate",{['@garage'] = garage , ['@plate'] = plate})
    MySQL.Sync.execute("UPDATE owned_vehicles SET vehicle=@vehicle WHERE plate=@plate", {['@vehicle'] = json.encode(vehicleProps), ['@plate'] = plate})


end)

RegisterServerEvent("erp_garage:sacarometer")
AddEventHandler("erp_garage:sacarometer", function(vehicle, state, src1)
    local src = source
    if src1 then
        src = src1
    end
    local xPlayer = esx.GetPlayerFromId(src)
    while xPlayer == nil do Citizen.Wait(1); end
    local plate = all_trim(vehicle)
    local state = state
    MySQL.Sync.execute("UPDATE owned_vehicles SET state =@state WHERE plate=@plate", {['@state'] = state, ['@plate'] = plate})
end)

function all_trim(s)
    return s:match("^%s*(.-)%s*$")
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- basic checking function, return boolean and don't error  
isTable = function(v) return type(v)=="table" end  
isNumber = function(v) return type(v)=="number" end  
isString = function(v) return type(v)=="string" end  
isFunction = function(v) return type(v)=="function" end  
isBoolean = function(v) return type(v)=="boolean" end  
isNil = function(v) return v==nil end  
isNotNil = function(v) return v~=nil end  
isDefined = function(v) return v~=nil and v~=false end  
isUndefined = function(v) return v==nil or v==false end  
isTableOfLength = function(v,length) return isTable(v) and #v==length end  
isEmptyTable = function(v)  
	if not isTable(v) then return false  
	if #v==0 then return true  
	for _, value in pairs(v) do  
		if value ~= nil then return false end  
	end  
	return true  
end  
isNonEmptyTable = function(v)  
	if not isTable(v) then return false  
	if #v==0 then return false  
	for _, value in pairs(v) do  
		if value ~= nil then return true end  
	end  
	return false  
end  
isArray = function(v)  
	if not isTable(v) then return false  
	local max = 0  
	for key, _ in pairs(v) do  
		if not isNumber(key) then return false end  
	max = math.max( max, key )  
	end  
	return max == #v  
end  
isEmptyString = function(v) return isString(v) and v=="" end  
isNonEmptyString = function(v) return isString(v) and v~="" end  
isInteger = function(v) return type(v)=="number" and v==math.floor(v) end  
isPositiveInteger = function(v) return isInteger(v) and v>=0 end  
isBetween = function(v,min,max) return v>=min and v<=max end  
isFacing = function(v) return isPositiveInteger(v) and isBetween(v,1,4) end  
isSlot = function(v) return isPositiveInteger(v) and isBetween(v,1,16) end  
  
-- k.device.lua  
isInteractive = isDefined(shell) or isDefined(multishell)  
-- isCalledFromGlobal = getfenv(1)==getfenv(0)   -- ?? local environment == global environment  
isTurtle = isDefined(turtle)  
isComputer = not isTurtle -- ??  
isPocketComputer = isDefined(pocket)  
isAdvanced = term and term.native and term.native().isColor()  
isAdvancedTurtle = isTurtle and isAdvanced  
fuelLimit = isAdvancedTurtle and 100000 or 20000  
isAdvancedComputer = isComputer and isAdvanced  
modem = peripheral.find("modem", function(name, object) return not object.isWireless() end)  
wifi = peripheral.find("modem", function(name, object) return object.isWireless() end)  
monitor = peripheral.find("monitor")  
printer = peripheral.find("printer")  
drive = peripheral.find("drive")  
currentNetwork = {} -- a list of all computer names attached via wired modem  
for _,name in peripheral.getNames() do  
	if string.find(name, "computer") then   
		table.insert(currentNetwork, name)  
	end  
end  
	  
termX, termY = term.native().getSize()  
-- isCraftyTurtle = ???  
-- turtleType = Mining,Farming,Melee,Felling,Digging .... ???  
  
  
-- Schema validation, taken from   
-- https://github.com/fnuecke/lama/blob/master/apis/lama  
--[[  
	Validates a value based on a schema.  
  
	This checks if the value fits the specified schema (i.e. types are correct)  
	which is used when loading states, to avoid loading a corrupted state.  
  
	@param value the value to validate.  
	@param schema the schema to use to validate the value.  
	@return true if the value fits the schema; (false, reason) otherwise.  
	@private  
]]  
--[[  
	ExampleSchema = {  
		position = {  
			type = "table",  
			properties = {  
				x = {type = "number", value = private.isInteger},  
				y = {type = "number", value = private.isInteger},  
				z = {type = "number", value = private.isInteger},  
				f = {type = "number", value = private.isFacing}  
			}  
		},  
		waypoints = {  
			type = "table",  
			entries = {  
				type = "table",  
				keytype = "string",  
				properties = {  
					x = {type = "number", value = private.isInteger},  
					y = {type = "number", value = private.isInteger},  
					z = {type = "number", value = private.isInteger},  
					f = {type = "number", value = private.isFacing,  
						 optional = true}  
				}  
			}  
		}  
	}  
]]  
validate = function(value, schema)  
	assert(schema ~= nil, "no schema given")  
	local function validate(value, schema, path)  
		-- Is the value optional? We do this first because we still want to  
		-- return false if the type mismatches if the value is optional but not  
		-- nil.  
		if schema.optional and value == nil then  
			return true  
		end  
  
		-- Is the value type correct?  
		if type(schema.type) == "table" then  
			-- Value may have multiple types, check if any one fits.  
			local ok = false  
			for _,valueType in pairs(schema.type) do  
				if type(value) == valueType then  
					ok = true  
					break  
				end  
			end  
			if not ok then  
				return false, path .. ": invalid type; is " .. type(value) ..  
					", should be one of [" ..  
					table.concat(schema.type, ", ") .. "]"  
			end  
		elseif schema.type and type(value) ~= schema.type then  
			return false, path .. ": invalid type; is " .. type(value) ..  
				", should be " .. schema.type  
		end  
  
		-- See if we have a custom validator function.  
		if schema.value and not schema.value(value) then  
			return false, path .. ": invalid value"  
		end  
  
		-- Recursively check properties of the value.  
		if schema.properties then  
			for property, propertySchema in pairs(schema.properties) do  
				local result, location = validate(value[property],  
												  propertySchema,  
												  path .. "." .. property)  
				if not result then  
					return result, location  
				end  
			end  
		end  
  
		-- Recursively check entries of a table.  
		if schema.entries then  
			for key, entry in pairs(value) do  
				if schema.entries.keytype and  
				   type(key) ~= schema.entries.keytype  
				then  
					return false, path .. "[" .. key ..  
						"]: invalid key type; is " .. type(key) ..  
						", should be " .. schema.entries.keytype  
				end  
				local result, location = validate(entry,  
												  schema.entries,  
												  path .. "[" .. key .. "]")  
				if not result then  
					return result, location  
				end  
			end  
		end  
		-- No issues.  
		return true  
	end  
	return validate(value, schema, "value")  
end  

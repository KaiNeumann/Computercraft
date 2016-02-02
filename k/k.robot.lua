-- robot API k.robot.lua

-- Navigation taken from here
-- forum post: http://www.computercraft.info/forums2/index.php?/topic/19491-starnav-advanced-turtle-pathfinding-and-environment-mapping/
-- heavily adapted

assert(turtle,"this script can only run on a Turtle")
assert(k,"this script requires the k framework")

map = map or require("k/classes/k.map.lua")
persistentvar = persistentvar or require("k/classes/k.persistentvar.lua")
navigation = navigation or require("k/apis/k.navigation.lua")

--[[ INITIALIZE ]]--
local graph = map.new("k/var/map")
local p = persistentvar.new("k/var/p",{
	facing = 0,
	pos = {
		x = 0,
		z = 0,
		y = 0
	},
	fuel = 0,
})

--[[ position & vector related functions ]]--
isVector = function(v)
	return k.instanceof(v,vector)
end
vectorToTable = function(vector)
	asster(isVector(vector),vector.." is not a vector")
	return {x=vector.x,y=vector.y,z=vector.z}
end
toVector = function(x,y,z)
	if isVector(x) then return x end
	if type(x) == "table" and x.x and x.y and x.z then
		return vector.new(tonumber(x.x),tonumber(x.y),tonumber(x.z))
	end
	if type(x) == "table" #x == 3 then
		return vector.new(tonumber(x[1]),tonumber(x[2]),tonumber(x[3]))
	end
	if #args == 3 then return vector.new(tonumber(x),tonumber(y),tonumber(z)) end
	error("Worng arguments to toVector()")
end

local function vectorEquals(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

local function getAdjacentPos(pos)
	return {
		pos + vector.new(0, 0, 1),
		pos + vector.new(-1, 0, 0),
		pos + vector.new(0, 0, -1),
		pos + vector.new(1, 0, 0),
		pos + vector.new(0, 1, 0),
		pos + vector.new(0, -1, 0),
	}
end
local nextPos = { -- has to match getFacing()
	0 = vector.new(0,0,1),
	1 = vector.new(-1,0,0),
	2 = vector.new(0,0,-1),
	3 = vector.new(1,0,0),
}	


--[[ robot namespace ]]--
local robot = {}

robot.error = function(msg)
	-- message to service master that soemthing went wrong
	-- clean up task queue
	-- set staus accordingly
	-- wait for help or new instructions
	error(msg)
end
robot.assert = function(b,msg)
	if not b then robot.error(msg) end
end

-- robot functions wrap turtle api to persitently store position data
robot.forward = function()
	local result = turtle.forward()
	if result then
		local delta = nextPos[ p.facing ]
		p.pos.x = p.pos.x + delta.x
		-- delta.y is always zero
		p.pos.z = p.pos.z + delta.z 
		p.fuel = turtle.getFuelLevel()
	end
	return result
end
robot.back = function()
	local result = turtle.back()
	if result then
		local delta = nextPos[ p.facing ]
		p.pos.x = p.pos.x - delta.x 
		p.pos.z = p.pos.z - delta.z
		p.fuel = turtle.getFuelLevel()
	end
	return result
end
robot.up = function()
	local result = turtle.up()
	if result then
		p.pos.y = p.pos.y + 1 
		p.fuel = turtle.getFuelLevel()
	end
	return result
end
robot.down = function()
	local result = turtle.down()
	if result then
		p.pos.y = p.pos.y - 1 
		p.fuel = turtle.getFuelLevel()
	end
	return result
end
robot.turnRight = function()
	local result = turtle.turnRight()
	p.facing = (p.facing + 1) % 4
	return result
end
robot.turnLeft = function()
	local result = turtle.turnLeft()
	p.facing = (p.facing - 1) % 4  -- TOCHECK
	return result
end

robot.dig = function(...)
	-- will take inventory into account
	-- will take sand & gravel into account
end
robot.digUp = function(...)
	-- will take inventory into account
	-- will take sand & gravel into account
end
robot.digDown = function(...)
	-- will take inventory into account
	-- will take sand & gravel into account
end
robot.suck = function(...)
	-- will take inventory into account
end
robot.suckkUp = function(...)
	-- will take inventory into account
end
robot.suckDown = function(...)
	-- will take inventory into account
end
robot.place = function(...)
	-- will take inventory into account
end
robot.placeUp = function(...)
	-- will take inventory into account
end
robot.placeDown = function(...)
	-- will take inventory into account
end

robot.isAdvanced = term and term.native and term.native().isColor()
robot.fuelLimit = turtle.getFuelLimit() -- = robot.isAdvanced and 100000 or 20000
robot.modem = peripheral.find("modem", function(name, object) return not object.isWireless() end)
robot.wifi = peripheral.find("modem", function(name, object) return object.isWireless() end)
robot.hasChunkloader = peripheral.find("modem", function(name, object) return object.isChunky end)
robot.workbench = peripheral.find("workbench")
robot.sensor = nil
for _,side in ipairs(redstone.getSides()) do
	if peripheral.isPresent(side) then 
		local device = peripheral.wrap(side)
		if type(device.sonicScan)=="function" then
			robot.sensor = device
			break
		end
	end
end
-- turtleType = Mining,Farming,Melee,Felling,Digging .... ???

--[[
    Tries repeatedly to get a consistent gps localization using the native gps API

    @param none
    @return vector with GPS coordinates, nil on error
]]
robot.gpslocate = function()
	local maxtries = 5
	local vP1, vP2
	local gpsposlocal 
	local counter = 0
	while counter < maxtries do
		vP1 = vector.new(gps.locate())
		vP2 = vector.new(gps.locate())
		if vP1:length() == 3 and vP2:length() == 3 and vectorEquals(vP1,vP2) then 
			return vP1
		end
		counter = counter + 1
	end
	print("couldn't get stable gps signal")
	return nil
end

--[[
    Returns the current position of the turtle
	By default the persistently stored position is returned
	

    @param bValidate	boolean, optional
		If the validation flag is set, a new gps localization call is used
    @return vector with coordinates, nil on error
]]
robot.getPosition = function(bValidate)
	local vCurrentPosition = vector.new(unpack(p.pos))
	if not bValidate then return vCurrentPosition end
	local vGpsPosition = robot.gpslocate()
	if not vectorEquals(vGpsPosition,vCurrentPosition) then
		print("wow, position mistmatch... Correcting now")
		p.pos.x = vGpsPosition.x
		p.pos.y = vGpsPosition.y
		p.pos.z = vGpsPosition.z
	end
	return gpsPos
end

robot.getFacing = function(bValidate)
	if not bValidate then return p.facing end
	-- FIXME what if no gps signal??? the old ladder trick?
	local vPosition1 = robot.gpslocate()
	-- find space to move forward
	local i = 0
	while turtle.detect() do
		if i == 4 then
			if robot.up() then
				i = 0
			else
				return nil
				--k.error("help I'm trapped in a ridiculous place")
			end
		else
			robot.turnRight()
			i = i + 1
		end
	end
	i = 0
	while not robot.forward() do
		if i > 5 then 
			return nil
			--k.error("couldn't move to determine direction") 
		end
		i = i + 1
		sleep(1)
	end
	local vPosition2 = robot.gpslocate()
	robot.back()
	local vDirection = vPosition2 - vPosition1
	local newFacing
	if vDirection.x == 1 then		newFacing = 3
	elseif vDirection.x == -1 then 	newFacing = 1
	elseif vDirection.z == 1 then	newFacing = 0
	elseif vDirection.z == -1 then 	newFacing = 2
	else					return nil --k.error("could not determine direction - phase 3")
	end
	if newFacing ~= p.facing then
		print("wow, facing mistmatch... Correcting now")
		p.facing = newFacing
	end
	return newFacing
end

robot.turnTo = function(vAdjacentPosition) -- turns to an adjecent position and returns if there is an obstacle in that direction
	local newFacing
	local vDirection = vAdjacentPosition - robot.getPosition()	
	if vDirection.y == 1 then			return turtle.detectUp()
	elseif vDirection.y == -1 then		return turtle.detectDown()
	elseif vDirection.x == 1 then		newFacing = 3
	elseif vDirection.x == -1 then		newFacing = 1
	elseif vDirection.z == 1 then		newFacing = 0
	elseif vDirection.z == -1 then		newFacing = 2
	else						error("turnTo encountered illegal direction "..vDirection)
	end
    
	local delta = newFacing - p.facing
	if delta == 0 then
		return
	elseif delta == -3 or delta == 1 then
		robot.turnRight()
	elseif delta == -2 or delta == 2 then
		robot.turnRight()
		robot.turnRight()
	elseif delta == -1 or delta == 3 then
		robot.turnLeft()
	end
    
	return turtle.detect()
end

robot.scan = function()
	local vCurrentPosition = robot.getPosition()
	if robot.sensor and robot.sensor.sonicScan then
		local changed = robot.sensor.sonicScan()
		for _, blockInfo in ipairs(changed) do
			local vPosition = vCurrentPosition + vector.new(blockInfo.x, blockInfo.y, blockInfo.z)
			graph.set(vPosition, blockInfo.type ~= "AIR" and 1 or nil)
		end
	else
		--oben
		local vPosition = getAdjacentPos(vCurrentPosition)[5]
		graph.set(vPosition, turtle.detectUp() and 1 or nil)
		--unten
		vPosition = getAdjacentPos(vCurrentPosition)[6]
		graph.set(vPosition, turtle.detectDown() and 1 or nil)
		-- geradeaus 
		vPosition = vCurrentPosition + nextPos[ p.facing ]
		graph.set(vPosition, turtle.detect() and 1 or nil)
		-- und dreimal rechts
		for i=1,3,1 do
			robot.turnRight()
			local vPosition = vCurrentPosition + nextPos[ p.facing ]
			graph.set(vPosition, turtle.detect() and 1 or nil)
		end
		
	end
	graph.save()
end

robot.move = function(vAdjacentPosition)
	if not robot.turnTo(vAdjacentPosition) then
		local vDirection = vAdjacentPosition - robot.getPosition()
		if vDirection.y == 1 then		return robot.up()
		elseif vDirection.y == -1 then	return robot.down()
		else							return robot.forward()
		end
	else
		return false
	end
end

robot.calibrate = function()
	robot.getPosition(true)
	robot.getFacing(true)
end

robot.goto = function(x, y, z)
	local vTargetPosition = toVector(x,y,z)
	local vCurrentPosition = robot.getPosition()
	
	if graph.get(vTargetPosition) then error("goal is blocked") end
	local path = navigation.getPath(vCurrentPosition, vTargetPosition, graph)
	if not path then
		-- error("no known path to goal")
		return false
	end
	scan()
	while not vectorEquals(vCurrentPosition, vTargetPosition) do
		local vMovePosition = table.remove(path)
		if robot.turnTo(vMovePosition) then
			robot.scan()
			if graph.get(vTargetPosition) then error("goal is blocked") end
			path = navigation.getPath(vCurrentPosition, vTargetPosition, graph)
			if not path then
				-- error("no known path to goal")
				return false
			end
		else
			while not robot.move(vMovePosition) do
				sleep(1) -- TODO better obstacle detection
			end
			currPos = robot.getPosition()
		end
	end
	return true
end

-- approach a target position to interact with, e.g. a chest or another turtle
robot.approach = function(x,y,z)
	local vTargetPosition = toVector(x,y,z)
	local vPosition
	local bSuccess
	-- check if an successful adjacent position already known
	if successfulAdjacentPositionIsKnown then 
		vPosition = successfulAdjacentPosition -- FIXME
		bSuccess = robot.goto(vPosition)
		if bSuccess then
			-- turn to vTargetPosition
			robot.turnTo(vTargetPosition)
			return true
		end
	end
	-- goto a field adjacent to the vTargetPosition and face it
	local adjacents = getAdjacentPos(vTargetPosition)
	for _,vPosition in adjacents do
		-- goto pos if possible
		bSuccess = robot.goto(vPosition)
		if bSuccess then
			--on success store successfull adjacent position
			vSuccessfulAdjacentPosition = vPosition -- FIXME
			-- turn to vTargetPosition
			robot.turnTo(vTargetPosition)
			return true
		end
	end
	error("no adjacent positions of target reachable")
end

--[[ Execute Command String 
	Inspired by 
		https://github.com/jnordberg/minecraft-replicator/blob/master/replicator Replicator::exec
		and http://turtlescripts.com/project/gjdh20-Act
	Commands
		commandstrings are whitespace seperated lists of commands
		commands are uppercase letters, optionally followed by a parameter seperated by a colon
		MF MB MU MD		- move forward, back, up, down - parameter n repeat
		FF FB FU FD		- same as move, but use force if necessary (attack and dig)
		L R				- turn, no parameter
		D DU DD			- dig			
		P PU PD			- place			
		S SU SD			- suck			
		A AU AD			- attack		
		E EU ED			- eject (drop)  
		SEL				- select inventory, parameter: item name
		Z				- sleep, parameter: seconds
		R				- refuel, parameter ammount. "all" if not present
		I IU ID			- inspects and returns value
		
	TODO make it persistant (but isn't it then the full task driven aproach already?)
--]]
robot.exec = function(commandstring)
	local commands = {
		MF= function(n) return act(robot.forward,turtle.inspect,nil,robot.attack,n) end, 
		MB= function(n) return act(robot.back,nil,nil,nil,n) end, 
		MU= function(n) return act(robot.up,turtle.inspectUp,nil,robot.attackUp,n) end, 
		MD= function(n) return act(robot.down,turtle.inspectDown,nil,robot.attackDown,n) end, 
		FF= function(n) return act(robot.forward,turtle.inspect,robot.dig,robot.attack,n) end, 
		FB= function(n) return act(robot.back,nil,nil,nil,n) end, 
		FU= function(n) return act(robot.up,turtle.inspectUp,robot.digUp,robot.attackUp,n) end, 
		FD= function(n) return act(robot.down,turtle.inspectDown,robot.digDown,robot.attackDown,n) end, 
		TL=	robot.turnLeft,
		TR= robot.turnRight,
		D=	robot.dig,
		DU= robot.digUp,
		DD= robot.digDown,
		P=	robot.place,
		PU= robot.placeUp,
		PD= robot.placeDown,
		S=	robot.suck,
		SU= robot.suckUp,
		SD= robot.suckDown,
		A=	robot.attack,
		AU= robot.attackUp,
		AD= robot.attackDown,
		E=	robot.drop,
		EU= robot.dropUp,
		ED= robot.dropDown,
		SEL= function(item) end -- TODO
		Z=	function(sec) os.sleep(sec) end,
		R=	robot.refuel,
		I=	function() return turtle.inspect() end,
		IU=	function() return turtle.inspectUp() end,
		ID=	function() return turtle.inspectDown() end,
	}
	local commandsWithTextParameter = { "SEL" }
	local movingBlocks = { "ComputerCraft:CC-Turtle", "ComputerCraft:CC-TurtleAdvanced" }
	local act = function(fn,fnInspect,fnDig,fnAttack,n)
		-- perform an action (fn) repeatedly (n-times) 
		-- bundling associated functions for directional inspection, digging and attacking
		if n==nil then n=1 end
		local i = 0
		local count = 0
		local maxCount = 50 -- to prevent endless loops
		local result = true
		while i < n and count < maxCount do
			result = fn()
			if result then
				i = i + 1
				count = 0
			else if fnInspect~=nil then
				count = count + 1
				local hindrance = fnInspect()
				-- no hindrance means there is a mob in the way
				if not hindrance and fnAttack then fnAttack()  
				-- if it is a moving block e.g. another turtle, just wait
				else if movingBlocks[hindrance.name] then os.sleep(0.5) -- FIXME if both turtles are moving in opposite directions, this is a deadlock!
				-- if there is a normal block and a dig function is provided, then dig until the way is free
				else if fnDig then fnDig() 
				-- otherwise I don't know how to handle this kind if hindrance
				else return false 
				end
			else
				return false
			end
			os.sleep(0.02) --??
		end
		return result
	end
	
	local commandlist = string.gmatch(commandstring, '%S+')
	local result = nil
	for _,command in ipairs(commandlist) do
		local cmd, param = unpack( string.gmatch(command, "%:") )  -- TOCHECK
		if param and commandsWithTextParameter[cmd] == nil then
			param = tonumber(param, 10)
		end
		assert(commands[cmd],"Command "..cmd.." is not a valid command")
		result = commands[cmd](param)
		assert(result,"Command "..cmd.." with parameter "..param.." failed")
		os.sleep(0.02) -- ??
	end	
	return result
end

return robot

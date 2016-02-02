-- http://www.computercraft.info/forums2/index.php?/topic/19939-stable-moveapi-reboot-persist-coordinate-tracking-smart-movement/
-- 9QFxP4Ff for pastebin program
--[[
        MoveAPI is meant to be a replacement for the general
        movement commands you use for turtles.
       
        Feature List
        ------------
        Keeps track of coordinates
        Auto-handles sand/gravel
        Variable forward()/up()/down()
        Has moveTo() certain coordinates
        Can travel() with a chunkloader
                to ignore chunk load boundaries
]]
 
version = 1.31
 
xPos = 0
yPos = 0
zPos = 0
dir = "north"
chunkSlot = 2
dirMoving = "forward"
local isDebug = false
local shouldPathFind = false
 
--[[
        Here is your digging functions overwriting
]]
 
dig = turtle.dig
digUp = turtle.digUp
digDown = turtle.digDown
 
 
local function digDetect(detectFun, digFun)
        while detectFun() do
                if not digFun() and detectFun() then
                        return false
                end
                digFun()
                sleep(.3)
        end
        return true
end
 
turtle.dig = function() return digDetect(turtle.detect, dig) end
turtle.digUp = function() return digDetect(turtle.detectUp, digUp) end
turtle.digDown = function() return digDown() end
 
--[[
        This is non-forceful movement in x distance
        Returns false if something in the way.
]]--
 
forward = turtle.forward
up = turtle.up
down = turtle.down
 
turtle.forward = function(...)
   --Returns true if successful, false if not
   local arg = {...}
        local distance = 0
       
        if arg[1] == nil then
        distance = 1
        else
                if type(arg[1]) ~= "number" then error("Invalid type passed into down()!") end
                distance = arg[1]
        end
   local x=0
   while x<distance do
               
                dirMoving = "forward"
                saveData()
                if not forward() then
                        return false
                end
 
                if dir == "north" then
                        zPos = zPos-1
                elseif dir == "east" then
                        xPos = xPos+1
                elseif dir == "west" then
                        xPos = xPos-1
                elseif dir == "south" then
                        zPos=zPos+1
                end
                x=x+1
   end
   saveData()
   return true
end
 
local function movement(moveFunct, changeY, Moving, ...)
        local arg = {...}
        local distance = 0
       
        if arg[1] == nil then
        distance = 1
        else
                if type(arg[1]) ~= "number" then error("Invalid type passed into down()!") end
                distance = arg[1]
        end
   local x=0
   while x<distance do
                dirMoving = Moving
                saveData()
                if not moveFunct() then
                        return false
                end
                yPos=yPos+changeY
                x=x+1
   end
   saveData()
   return true
end
 
turtle.up = function(...) return movement(up, 1, "up", ...) end
turtle.down = function(...) return movement(down, -1, "down", ...) end
fuel = turtle.refuel
turtle.refuel = function(...)
        local arg = {...}
        local amnt = tonumber(arg[1])
        if fuel(amnt) then
                saveData()
                return true
        else
                return false
        end
end
 
--[[
        Here is a more forceful movements. If something is in the way,
        the turtle WILL mine it out. Sand and gravel are also handled
        properly.
]]
 
function fMovement(detectFunc, digFunc, moveFunc, attackFunc,...)
        local args = {...}
        local distance = 1
        if type(args[1]) == "number" then
           distance = args[1]
        end
 
        for i=1, distance do
                debug("Moving: "..i.."/"..distance)
                while not moveFunc() do
                        if not digFunc() and detectFunc() then return false
                        else attackFunc() end
                end
        end
       
        return true
end
 
turtle.fForward = function(...)  return fMovement(turtle.detect, turtle.dig, turtle.forward, turtle.attack,...) end
turtle.fUp = function(...)  return fMovement(turtle.detectUp, turtle.digUp, turtle.up, turtle.attackUp,...) end
turtle.fDown = function(...)  return fMovement(turtle.detectDown, turtle.digDown, turtle.down, turtle.attackDown,...) end
 
--[[
        Here is all your turning code.
]]
turnLeft = turtle.turnLeft
turnRight = turtle.turnRight
 
turtle.turnLeft = function()
        --Turns turtle left once and changes dir
        turnLeft()
        if dir == "north" then dir = "west"
        elseif dir == "south" then dir = "east"
        elseif dir == "west" then dir = "south"
        elseif dir == "east" then dir = "north"
        end
        saveData()     
end
 
turtle.turnRight = function()
        --Turns turtle right once and changes dir
        turnRight()
        if dir == "north" then dir = "east"
        elseif dir == "south" then dir = "west"
        elseif dir == "west" then dir = "north"
        elseif dir == "east" then dir = "south"
        end
        saveData()     
end
 
turtle.turnAround = function()
        turtle.turnRight()
        turtle.turnRight()
        saveData()
end
 
turtle.turnToDir = function(directionName)
        if directionName == "north" or directionName == "east" or directionName == "west" or directionName == "south" then
                while dir ~= directionName do
                        turtle.turnLeft()
                        saveData()
                end
        else
                error("setDir() had improper parameter passed into it. north/south/east/west required. You entered: "..directionName)
                return "Improper Parameter used."
        end
end
 
--[[
        These are here to provide information to the user.
        Lots of figuring out coordinates of or in front
        of turtle. I also placed setCoords() because...seemed appropriate.
]]
 
turtle.setCoords = function(...)
        --Just a quick way to forceSet coordinates :)
        --If you want non-relative coordinates, dir 0 = East, North: 3, South: 1, West: 2
        local stuff = {...}
        if #stuff <4 or #stuff > 4 then
                error("Improper amount of variables passed into setCoords(). Requires 4, you entered "..#stuff)
        elseif type(stuff[1]) ~= "number" or  type(stuff[2]) ~= "number" or type(stuff[3]) ~= "number" then
                error("Numbers required to be entered into first three parameters. You entered: "..stuff[1].." "..stuff[2].." "..stuff[3])
        elseif type(stuff[4]) ~= "string" then
                error("Last parameter must be a string. You entered: "..stuff[4])
        elseif stuff[4] ~= "north" and stuff[4] ~= "south" and stuff[4] ~= "east" and stuff[4] ~= "west" then
                error("Last parameter requires a direction. north/south/east/west. You entered: "..stuff[4])
        end
 
        xPos = stuff[1]
        yPos = stuff[2]
        zPos = stuff[3]
        dir = stuff[4]
        saveData()
end
 
turtle.getCoords = function()
        --Use this if you want the current coordinates of the turtle.
        return xPos, yPos, zPos, dir
end
 
turtle.getCoordsTbl = function()
        --Returns a table of the current coordinates (good for quickly setting locations)
        local table = {turtle.getX(), turtle.getY(), turtle.getZ(), turtle.getDir()}
        return table
end
 
turtle.getX = function()
        return xPos
end
 
turtle.getY = function()
        return yPos
end
 
turtle.getZ = function()
        return zPos
end
 
turtle.getDir = function()
        return dir
end
 
turtle.getFront = function()
        --Returns coordinates right in front of turtle
        if dir == "north" then
                return xPos, yPos, zPos-1
        elseif dir == "south" then
                return xPos, yPos, zPos+1
        elseif dir == "east" then
                return xPos+1, yPos, zPos
        elseif dir == "west" then
                return xPos-1, yPos, zPos
        else
                print("Error, dir is improper value.")
        end
end
 
turtle.getFrontTbl = function()
        --Returns coordinate table right in front of turtle
        return turtle.getFront()
end
 
--[[
        Here are some of the more advanced functions such as
        move(), moveTo(), fMoveTo(), and travel().
 
        These are the intelligent functions for really going from
        place to place. Pathfinding of the functions is very much a work in
        progress. Do not rely on it too heavily. If you need to seriously
        find around obstacles, I suggest writing your own.     
]]
 
turtle.move = function(direction, distance)
        --This loop is setup so that it can be used regurally to save lines of code and to
        --further modularize. Moves a certain distance in a specific direction.
 
        --Sets to proper direction before looping
        if direction == "north" or direction == "south" or direction == "east" or direction == "west" then
                turtle.turnToDir(direction)
        end
 
        --This is the main loop.
        local i = 0
       
        while i < distance do
                if direction == "up" then
                        turtle.fUp()
                elseif direction == "down" then
                        turtle.fDown()
                else
                        turtle.fForward()
                end
 
                i=i+1
        end
end
 
local function smartMove(moveFunc, shouldBreak,aiType,...)
        --Base for intelligent navigation commands.
        local args = {...}
        local coords = {}
        local axisOdr = {}
        local isTrav = false
        debug(aiType.." executing...")
       
        --This handles the travel special case
       
        coords, axisOdr, isTrav = _parseInput(args)
 
        if isTrav then
                debug("Writing persist...")
                writeTravPerst(coords,axisOdr)
        end
 
        --Here, the turtle will actually follow the specific axis
       
        debug("Beginning movement with x: "..turtle.getX()..", y: "..turtle.getY()..", z: "..turtle.getZ())
        debug("\nGoing to x: "..coords[1]..", y: "..coords[2]..", z: "..coords[3])
        debug("Axis order is: "..axisOdr[1]..", "..axisOdr[2]..", "..axisOdr[3])
        local shouldCont = true
        for i=1, #axisOdr do
                if axisOdr[i] == "x" and shouldCont then
                        if not moveFunc(coords[1], "x", shouldBreak) then shouldCont = false end
                end
 
                if axisOdr[i] == "y" and shouldCont then
                        if not moveFunc(coords[2], "y", shouldBreak) then shouldCont = false end
                end
 
                if axisOdr[i] == "z" and shouldCont then
                        if not moveFunc(coords[3], "z", shouldBreak) then shouldCont = false end
                end
        end
       
        --Some expiramental code which tries to find a way around
        if not shouldCont then
                if not collisionHandler(aiType, axisOdr, coords) then return false end
        end
        turtle.turnToDir(coords[4])
        return true
end
 
turtle.moveTo = function(...) if smartMove(goAxis, false, "moveTo",...) then return true else return false end end
turtle.fMoveTo = function(...) if smartMove(goAxis, true, "fMoveTo", ...) then return true else return false end end
turtle.travel = function(...)
        if smartMove(loadLoop, false, "travel", "trav", ...) then return true else return false end
        delTravPerst()
end
 
--[[
        HELPER COMMANDS
]]
 
function loadLoop(toCoord, axis, ...)
        --This loop is setup so that it can be used regurally to save lines of code and to
        --further modularize.
 
        --Random idiot-proofing.
        if axis ~= "x" and axis ~= "y" and axis ~= "z" then
                delTravPerst()
                error("Improper parameter entered for axis. Need x, y, or z. Entered: "..axis)
        end
 
        if type(toCoord) ~= "number" then
                delTravPerst()
                error("Improper parameter entered for coordinate. Please enter number. Entered: "..toCoord)
        end
 
        if turtle.getItemCount(chunkSlot) == 0 then
                delTravPerst()
                error("Please provide a chunkloader in slot: "..chunkSlot.." or setChunkSlot() to where one is.")
        end
        --Alright, let's find the direction.
        local direction
        local distance
        --Sets direction based on axis and currnet coordinates
        if axis == "x" then
                if toCoord>turtle.getX() then
                        direction = "east"
                        distance = toCoord - turtle.getX()
                else
                        direction = "west"
                        distance =  turtle.getX() - toCoord
                end
        elseif axis == "y" then
                if toCoord>turtle.getY() then
                        direction = "up"
                        distance = toCoord - turtle.getY()
                else
                        direction = "down"
                        distance =  turtle.getY() - toCoord
                end
        else
                if toCoord>turtle.getZ() then
                        direction = "south"
                        distance = toCoord - turtle.getZ()
                else
                        direction = "north"
                        distance =  turtle.getZ() - toCoord
                end
        end
 
        --For them silly negatives. ex. -439 - -16 = -423
        if distance < 0 then
                distance = distance*-1
        end
 
        --Sets to proper direction before looping
        if direction == "north" or direction == "south" or direction == "east" or direction == "west" then
                turtle.select(chunkSlot)
                turtle.digUp()
                turtle.placeUp()
                turtle.digUp()
                turtle.turnToDir(direction)
        end    
 
        --This is the main loop.
        local i = 0
        local increment = 3
        local counter = 2
 
        while i < distance do
                if direction == "up" then
                        if not turtle.fUp() then return false end
                elseif direction == "down" then
                        if not turtle.fDown() then return false end
                else
                        if not turtle.fForward() then return false end
                end
 
                --Counter is here so the turtle can put up the chunkloader ever increment amount of blocks
                counter = counter+1
                if counter == increment then
                        --This ensures that too moves are not made before
                        --chunk unloads and ensures to refresh chunkload loop
                        turtle.select(chunkSlot)
                        if not turtle.detectUp() then
                                turtle.placeUp()
                                turtle.digUp()
                        else
                                turtle.digUp()
                                turtle.placeUp()
                                turtle.digUp()
                        end
 
                        counter = 0
                end
 
                i=i+1
        end
        turtle.select(1)
        return true
end
 
function goAxis(toCoord, axis, shouldBreak)
        --Checks the axis (x, y, or z) and moves along it. Will break blocks/eat things if shouldBreak true
       
        --If x is the axis, then go east or west
        if axis == "x" then
                if toCoord>turtle.getX() then
                        local distance = toCoord - turtle.getX()
                        for i = 1, distance do
                                --East should be here, turn to right direction and go!
                                turtle.turnToDir("east")
                                if shouldBreak then
                                    if not turtle.fForward() then return false, "east" end
                                else
                                        if not turtle.forward() then return false, "east" end
                                end
                        end
                elseif toCoord<turtle.getX() then
                        local distance = turtle.getX() - toCoord
                        for i = 1, distance do
                                turtle.turnToDir("west")
                                if shouldBreak then
                                    if not turtle.fForward() then return false, "west" end
                                else
                                        if not turtle.forward() then return false, "west" end
                                end
                        end
                end
        end
        --If y is axis, go up or down
        if axis == "y" then
                if toCoord>turtle.getY() then
                        local distance = toCoord - turtle.getY()
                        for i = 1, distance do
                                --Gotta go up, here
                                if shouldBreak then
                                    if not turtle.fUp() then return false, "up" end
                                else
                                        if not turtle.up() then return false, "up" end
                                end
                        end
                elseif toCoord<turtle.getY() then
                        local distance = turtle.getY() - toCoord
                        for i = 1, distance do
                                if shouldBreak then
                                    if not turtle.fDown() then return false, "down" end
                                else
                                        if not turtle.down() then return false, "down" end
                                end
                        end
                end
        end
       
        --If z is the axis, handle it this way
        if axis == "z" then
                if toCoord>turtle.getZ() then
                        local distance = toCoord - turtle.getZ()
                        for i = 1, distance do
                                --East should be here, turn to right direction and go!
                                turtle.turnToDir("south")
                                if shouldBreak then
                                    if not turtle.fForward() then return false, "south" end
                                else
                                        if not turtle.forward() then return false, "south" end
                                end
                        end
                elseif toCoord<turtle.getZ() then
                        local distance = turtle.getZ() - toCoord
                        for i = 1, distance do
                                turtle.turnToDir("north")
                                if shouldBreak then
                                    if not turtle.fForward() then return false, "north" end
                                else
                                        if not turtle.forward() then return false, "north" end
                                end
                        end
                end
        end
        return true
end
 
--Various helper functions from handling input, to pathfinding
turtle.setChunkSlot = function(slot)
  if slot>0 and slot<17 then
        chunkSlot = slot
        return true
  else
        return false
  end
end
 
turtle.setPathFinding = function(setting)
        --Sets if pathfinding will happen when obstacles are hit in moveTo or travel
        if type(setting) ~= "boolean" then return false end
 
        shouldPathFind = setting
end
 
function collisionHandler(moveType, axisOdr, coords)
        --This will allow at least a basic attempt at collisionhandling. It will not solve mazes.
        if not shouldPathFind then return false end
        if fs.exists("moveCol") then return false end
 
        local f = fs.open("moveCol", "w")
        f.write("m")
        f.close()
        local totCollisions = 0
        local step = 1
        local colX, colY, colZ, colDir = turtle.getCoords()
        local keepTrying = true
        --This is not meant to be a maze-solver, just help a little.
        while totCollisions < 10 and keepTrying do
               
                totCollisions = totCollisions+1
                --This is if the same spot is a problem
                debug(turtle.getCoords())
                debug("Coll Coords: "..colX.." "..colY.." "..colZ)
                if turtle.getX() == colX and turtle.getY() == colY and turtle.getZ() == colZ then
                        --Still stuck in same spot..better try something else.
                        step = step+1
                else
                        --New spot, alright, let's start from scratch.
                        step = 1
                end
 
                --This set sthe collision point in case there is another one
                colX, colY, colZ = turtle.getCoords()
                debug("\nCollision! Total: "..totCollisions.."\nStep: "..step)
                --Let's try a couple things.
                if step == 1 then
                        turtle.turnAround()
                        turtle.forward(1)
                        axisOdr[1], axisOdr[2] = axisOdr[2], axisOdr[1]
                elseif step == 2 then
                        turtle.turnLeft()
                        turtle.forward(2)
                        turtle.up()
                elseif step == 3 then
                        turtle.turnRight()
                        turtle.forward(2)
                        turtle.down()
                        axisOdr[2], axisOdr[3] = axisOdr[3], axisOdr[2]
                end
 
                --This just reexecutes a try.
                if moveType == "travel" then
                        if turtle.travel(coords, axisOdr[1], axisOdr[2], axisOdr[3]) then
                                fs.delete("moveCol")
                                return true
                        end
                elseif moveType == "moveTo" then
                        if turtle.moveTo(coords, axisOdr[1], axisOdr[2], axisOdr[3]) then
                                fs.delete("moveCol")
                                return true
                        end
                elseif moveType == "fMoveTo" then
                        if turtle.fMoveTo(coords, axisOdr[1], axisOdr[2], axisOdr[3]) then
                                fs.delete("moveCol")
                                return true
                        end
                end
        end
 
        fs.delete("moveCol")
        return false
end
 
function _parseInput(inputTable)
        --Parses through user input and returns an axis-table and coordinates.
        local args = inputTable
        local coords = {}
        local axisOdr = {}
        local isTrav = false
 
        --Let's loop through and get the coordinates if they exist.
        for i=1, #args do
                --Let's load up all their stuff.
                debug("Parsing Input #"..i..": ")
                debug(args[i])
                if type(args[i]) == "number" then
                        coords[#coords+1] = args[i]
                elseif args[i] == "x" or args[i] == "y" or args[i] == "z" then
                        axisOdr[#axisOdr+1] = args[i]
                elseif args[i] == "north" or args[i] == "south" or args[i] == "east" or args[i] == "west" then
                        coords[4] = args[i]
                elseif type(args[i]) == "table" then
                        --Making sure they don't pass in some random table.
                        if #args[i] ~= 3 and #args[i] ~= 4 then
                                error("Error passing in table as parameter. Not enough parameters present in table. Needs to hold 3 or 4 entries. Table length: "..#args[i])
                        end
 
                        --This lets the user pass in a table where it will get evaluated independantly.
                        for k=1, #args[i] do
                                if type(args[i][k]) == "number" then
                                        coords[#coords+1] = args[i][k]
                                elseif args[i][k] == "north" or args[i][k] == "south" or args[i][k] == "east" or args[i][k] == "west" then
                                        coords[4] = args[i][k]
                                end
                        end
                elseif args[i] == "trav" then
                        isTrav = true
                else
                        error("Improper parameter passed into function. Passed in: "..args[i])
                end
        end
       
        --Ok, stuff has been placed, now, let's idiot-check
       
        --This makes sure they provided 3 coordinates.
        local nums = 0
        for i=1, #coords do
                if type(coords[i]) == "number" then
                        nums = nums+1
                end    
        end
 
        if nums ~= 3 then error("Improper number of coordinate parameters. Three required. You entered: "..nums) end
        if coords[4] == nil then coords[4] = "north" end
        --This will be the default path whe pathfinding.
        if #axisOdr ~= 3 then
                debug("Axis order either not entered or entered incorrectly, adjusting to default x -> z -> y...")
                axisOdr = {"x", "z", "y"}
        end
 
        --Now, let's just shoot everything back.
        return coords,axisOdr,isTrav
end
 
--[[
        Saving
        This is for redundancy of the API. You shouldn't need to
        call this...ever.
]]
function saveData()
        local saveData = {xPos, yPos, zPos, dir, turtle.getFuelLevel(), chunkSlot, dirMoving}
        local f = fs.open("api/moveLoc", "w")
        f.write(textutils.serialize(saveData))
        f.close()
end
 
function loadData()
        debug("Checking for previous config...")
        if fs.exists("api/moveLoc") then
                f = fs.open("api/moveLoc", "r")
                local data = textutils.unserialize(f.readAll())
                f.close()
 
                debug("Config found. Loading data...")
                --Checks to make sure turtle didn't move or do anything wonky after reboot
                if data[5] == turtle.getFuelLevel() then
                        --Loading in the data since nothig bad happened
                        local _d = ""
                        xPos, yPos, zPos, dir, _d, chunkSlot, dirMoving = unpack(data)
                elseif data[5] == (turtle.getFuelLevel()+1) then
                        --Here, we've gotta fix a few things since the turtle did in fact, move
                        debug("Looks like the turtle moved and didn't save his position, altering...")
                        if data[7] == "forward" then
                                --Forward means he went somewhere on the x/z axis...gotta account for it
                                if data[4] == "north" then
                                        data[3] = data[3]-1
                                elseif data[4] == "east" then
                                        data[1] = data[1]+1
                                elseif data[4] == "west" then
                                        data[1] = data[1]-1
                                elseif data[4] == "south" then
                                        data[3]=data[3]+1
                                end
                        elseif data[7] == "up" then
                                data[2] = data[2]+1
                        elseif data[7] == "down" then
                                data[2] = data[2]-1
                        end
 
                        --Now we can load in the fixed data.
                        debug("Loading data in...")
                        xPos, yPos, zPos, dir, _, chunkSlot, dirMoving = unpack(data)
                        debug("Data loaded!")
                        debug("X: "..xPos)
                        debug("Y: "..yPos)
                        debug("Z: "..zPos)
                        debug("Direction: "..dir)
                elseif data[5] > (turtle.getFuelLevel()-1) or data[5] < turtle.getFuelLevel() then
                        debug("Looks like the fuel level changed by more than one. Wiping location knowledge.")
                        saveData()
                else
                        debug("Something really weird is going on here. The recorded fuel is: "..data[5].." but current fuel is: "..turtle.getFuelLevel())
                        debug("Get Signify/Noiro to look at this because this wasn't supposed to happen.")
                        saveData()
                end
        end
end
 
function writeTravPerst(coords, axisOdr)
        --Travel persistence through restarts.
        if fs.exists("moveStartup-No-Delete") or fs.exists("no~startup") then
                debug("\n\nTrav is already going, ignoring...")
                return false
        elseif fs.exists("startup") then
                debug("\nStartup exists..moving..")
                fs.move("startup", "moveStartup-No-Delete")
        else
                debug("\n\nNo startup existed..writing my own temp one...")
                local f = fs.open("no~startup", "w")
                f.write("o")
                f.close()
        end
 
        local f = fs.open("startup", "w")
        if fs.exists("api/move") then
                f.writeLine("os.loadAPI(\"api/move\")")
        elseif fs.exists("move") then
                f.writeLine("os.loadAPI(\"move\")")
        else
                f.close()
                return false
        end
        --Explosive write to file
        f.writeLine("if turtle.detectUp() and turtle.getItemCount(turtle.getSelectedSlot()) == 0 then")
        f.writeLine("turtle.digUp()")
        f.writeLine("end")
        f.writeLine("turtle.travel("..coords[1]..", "..coords[2]..", "..coords[3]..", "..coords[4]..", "..axisOdr[1]..", "..axisOdr[2]..","..axisOdr[3]..")")
        f.writeLine("move.delTravPerst()")
 
        f.writeLine("if fs.exists(\"no~startup\") then fs.delete(\"no~startup\")")
        f.writeLine("elseif fs.exists(\"moveStartup-No-Delete\") then")
        f.writeLine("fs.delete(\"startup\")")
        f.writeLine("fs.move(\"moveStartup-No-Delete\", \"startup\")")
        f.writeLine("else")
        f.writeLine("fs.delete(\"startup\")")
        f.writeLine("end")
        f.writeLine("os.reboot()")
        f.close()
        return true
end
 
function delTravPerst()
        --Travel persistence through restarts.
        if fs.exists("startup") and fs.exists("no~startup") or fs.exists("moveStartup-No-Delete") then
                fs.delete("no~startup")
                fs.delete("startup")
                if fs.exists("moveStartup-No-Delete") then
                        fs.move("moveStartup-No-Delete", "startup")
                end
        end
end
--[[
        Random internal testing stuff
]]
function debug(message)
        if isDebug then
                print(message)
                sleep(.5)
        end
end
 
--Execution Code
delTravPerst()
if fs.exists("moveCol") then
        fs.delete("moveCol")
end

    loadData()

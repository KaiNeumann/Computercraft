--[[
  Tree felling
  
  persitent state variable
    subChopTreenr
    tree pos x,z,y
    circle start pos x,z,y
    
  müsste ich nicht bei jedem ChopTree checken wie viel fuel er verbraucht?
  will ich dass sich jede turtle selber refueled, also auf kohle suche geht? eigentlich nicht...
  ansonsten müßte ich zusätzlich checken, wieviel kohle ich für den weg zum refuelen brauche, und das wird echt haarig
  
  besser ist folgendes:
  
  Der Taskmanager checkt zwischen zwei Steps immer
    a) ob genug fuel da ist, ansonsten wird ein high prio task eingeschoben "warte auf betankung"
    b) ob Inventory fast voll ist, dann wird high prio task "warte auf entleerung" eingeschoben
    
    Es ist besser auf eine Service Turtle zu warten, als selber loszulaufen, oder?
  
  
]]--
ChopTree = {
  name=   "ChopTree",
  state=   { treePos= {x=x,y=y,z=y}, circleStartPos={x=0,y=0,z=0}, aproachPos={x=0,y=0,z=0} },
  steps = {   
    "approachTree" = function()  --first one added is the default one
      -- Approach tree
      robot.approach(unpack(self.state.treePos))
      local vOwnPos = robot.getPosition()
      self.state.aproachPos = vectorToTable( vOwnPos )
      -- determine circleStartPos here already
      local vDiff = toVector(self.state.treePos) - vOwnPos
      self.state.circleStartPos = { x = self.state.treePos.x + vDiff.x, y=0, z = self.state.treePos.z + vDiff.z }
      
      return self.nextStep("firstCut")
    end,
    "firstCut" = function()
      -- First cut into trunk
      -- TODO check if tree is present - if not, we are done
      robot.dig()
      robot.suck()
      robot.forward() -- TODO ersetzen durch MoveTo !!!
      return self.nextStep("cutTrunk")
    end,
    "cutTrunk" = function()
      -- Cut up until neither wood nor leaves
      local blockinfo = turtle.inspectUp()
      if blockinfo then 
        while blockinfo.name = "minecraft:wood" or blockinfo.name = "minecraft:leaves" do
          robot.digUp()
          robot.suckUp()
          robot.up() -- should be safe as there is seldomly gravel or sand above a tree
          blockinfo = turtle.inspectUp()
        end
      end
      return self.nextStep("stepOutside")
    end,
    "stepOutside" = function()
      -- Step outside and store circle start pos
      robot.dig()
      robot.suck()
      local vOwnPos = robot.getPosition()
      robot.goto( self.state.circleStartPos.x, vOwnPos.y, self.state.circleStartPos.z )
      return self.nextStep("harvestLeaves")
    end,
    "harvestLeaves" = function()
      -- leaf circles loop. resumable. whenever it gets interrupted and restarted, it will correctly go on (as long as the positions are correct)
      --[[
         OOO    1 = first pos in path
        O...O    . = circle path
        O1X.O    X = trunk pos
        0...0    O = leaves outside path
         OOO
      ]]--
      local adjacentLeaves = {
        "-1,0,-1" = { {0,0,-1}, {-1,0,0} },
        "-1,0,0"  = { {-1,0,0} },
        "-1,0,1"  = { {-1,0,0}, {0,0,1} },
        "0,0,1"   = { {0,0,1} },
        "1,0,1"   = { {0,0,1}, {1,0,0} },
        "1,0,0"   = { {1,0,0} },
        "1,0,-1"  = { {1,0,0}, {0,0,-1} },
        "0,0,-1"  = { {0,0,-1} },
      }
      local nextMove = {
        "-1,0,-1" = {0,0,1},
        "-1,0,0"  = {0,0,1},
        "-1,0,1"  = {1,0,0},
        "0,0,1"   = {1,0,0},
        "1,0,1"   = {0,-1},
        "1,0,0"   = {0,-1},
        "1,0,-1"  = {-1,0,0},
        "0,0,-1"  = {-1,0,0},
      }
      while true do -- TODO emergency exit
        diff = ( robot.getPosition() - vector.new(self.state.treePos) ):toString()
        -- harvest leaves
        for _,d in ipairs(adjacentLeaves[diff]) do  
          robot.turnTo( toVector(d) )
          local blockinfo = turtle.inspect()
          if blockinfo.name == "computercraft:leaves" then  -- FIXME 
            robot.dig()
            robot.suck()
          end
        end
        -- get next pos
        robot.turnTo( toVector(nextMove[diff]) )
        local blockinfo = turtle.inspect()
        if blockinfo.name == "computercraft:leaves" then  -- FIXME 
          robot.dig()
          robot.suck()
        end
        -- move to next pos
        robot.forward()
        local ownPos = robot.getPosition() 
        if ownPos.x == self.state.circleStartPos.x and ownPos.z == self.state.circleStartPos.z then
          if ownPos.y == self.state.treePos.y then  -- is tree bottom = trunk pos y ?  not too much?
            break -- exit leave harvesting
          else
            robot.digDown()
            robot.suckDown()
            robot.down()
          end
        end
      end -- end leaf circles loop
      return self.nextStep("checkDirt")
    end,
    
    "checkDirt" = function()  
      robot.goto(self.state.treePos.x, self.state.treePos.y, self.state.treePos.z)
      -- TODO check if there is dirt below - if not place it
      local blockinfo = turtle.inspectDown()
      if not blockinfo or blockinfo.name ~= "computercraft:dirt" then  -- FIXME 
        robot.digDown()
        robot.select("dirt")
        robot.placeDown()
      end
      
      return self.nextStep("replantSapling")
    end,
    "replantSapling" = function()  
      -- plant sapling
      robot.goto(self.state.treePos.x, self.state.treePos.y + 1, self.state.treePos.z)
      robot.select("sapling")
      robot.placeDown()
      return self.nextStep("end")
    end,
    "end" = function()  
      robot.goto(self.state.circleStartPos.x, self.state.treePos.y, self.state.circleStartPos.z)
      return self.nextStep()
    end
  }
}

return ChopTree

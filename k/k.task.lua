assert(k,"this script requires the k framework")
persistentvar = persistentvar or require("k/classes/k.persistentvar.lua")

-- http://www.computercraft.info/forums2/index.php?/topic/12894-how-to-easly-make-random-strings-of-any-length/
function createID(l)
	math.randomseed(os.time())
	if l==nil then l=16 end
	local s = "" -- Start string
	for i = 1, l do
		n = math.random(32, 126) -- Generate random number from 32 to 126
		if n == 96 then n = math.random(32, 95) end
		s = s .. string.char(n) -- turn it into character and add to string
	end
	return s -- Return string
end

Task = {}
function Task.new(oConfig)  -- {id,name,state}
	-- OBJECT INSTANCE
	local taskId = oConfig.id or createID()
	local path = "k/var/p/tasks/" + taskId
	
	local self = {
		name = oConfig.name,
		id = taskId,
		state = persistentvar.new(path, oConfig.state or {} ),
		steps = oConfig.steps or {}
    }
	self.state.step = oConfig.firstStep or self.steps[1]
        
	self.run = function()
        if not self.state.step then 
            return false 
        end
        self.steps[ self.state.step ]()
        return true
	end
    
	self.nextStep = function(nextStep)
		assert(not nextStep or self.steps[nextStep],"step "..nextStep.." doesn't exist")
        self.state.step = nextStep
    end
    
	self.cleanup = function()
		self.state = nil
		fs.delete(path)
        self = nil
	end
	
	return self
end

return Task

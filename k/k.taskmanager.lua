assert(k,"this script requires the k framework")
persistentvar = persistentvar or require("k/classes/k.persistentvar.lua")

local TaskManager = {}
local path = "k/var/p/taskmanager/"  -- can only be present once!!!

TaskManager.new = function()
	local self = {
		queue = persistentvar.new(path, {} )  -- list of taskIDs
	}
	
	self.insertTask = function(taskId)
		table.insert(self.queue,1,taskId)
		return self
	end
	self.addTask = function(taskId)
		table.insert(self.queue,taskId)
		return self
	end
	self.deleteTask = function(taskId)
		for i,id in iPairs(self.queue) do
			if id == taskId then
				table.remove(self.queue,i)
				return self
			end
		end
		return self
	end
	self.clearTasklist = function()
		self.queue = {}
	end
	
	self.run = function() -- run with coroutine manager
		
	end
	
	self.stop = function()
	end
	
	
	
	self.resume = function()
	end

	return self
end

return TaskManager

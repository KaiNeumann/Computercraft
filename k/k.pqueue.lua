-- based on pQueue  
-- I can only assume that code works :)  
  
-- changed to closure type of class system  
Queue = {}  
function Queue.new(compareFunc)  
	local self = {  
		queue = {},  
		cmp = type(compareFunc) == "function" and compareFunc or function(a, b) return a < b end  
	}  
	  
	local function sift_up(index)  
		local current, parent = index, (index - (index % 2))/2  
		while current > 1 and self.cmp(self.queue[current][2], self.queue[parent][2]) do  
			self.queue[current], self.queue[parent] = self.queue[parent], self.queue[current]  
			current, parent = parent, (parent - (parent % 2))/2  
		end  
		return current  
	end  
  
	local function sift_down(index)  
		local current, child, size = index, 2*index, #self.queue  
		while child <= size do  
			if child < size and self.cmp(self.queue[child + 1][2], self.queue[child][2]) then  
				child = child + 1  
			end  
			if self.cmp(self.queue[child][2], self.queue[current][2]) then  
				self.queue[current], self.queue[child] = self.queue[child], self.queue[current]  
				current, child = child, 2*child  
			else  
				break  
			end  
		end  
		return current  
	end  
  
	function self.insert = (element, value)  
		table.insert(self.queue, {element, value})  
		return sift_up(#self.queue)  
	end  
  
	function self.remove(element, compFunc)  
		local index = self.contains(element, compFunc)  
		if index then  
			local size = #self.queue  
			self.queue[index], self.queue[size] = self.queue[size], self.queue[index]  
			local ret = table.remove(self.queue)  
			if size > 1 and index < size then  
				sift_down(index)  
				if index > 1 then  
					sift_up(index)  
				end  
			end  
			return unpack(ret)  
		end  
	end  
  
	function self.pop()  
		if self.queue[1] then  
			local size = #self.queue  
			self.queue[1], self.queue[size] = self.queue[size], self.queue[1]  
			local ret = table.remove(self.queue)  
			if size > 1 then  
				sift_down(1)  
			end  
			return unpack(ret)  
		end  
	end  
	  
	function self.peek()  
		if self.queue[1] then  
			return self.queue[1][1], self.queue[1][2]  
		end  
	end  
  
	function self.contains(element, compFunc)  
		for index, entry in ipairs(self.queue) do  
			if (compFunc and compFunc(entry[1], element)) or entry[1] == element then  
				return index  
			end  
		end  
		return false  
	end  
  
	function self.isEmpty()  
		return #self.queue == 0  
	end  
  
	function self.size()  
		return #self.queue  
	end  
  
	function self.getValue(element, compFunc)  
		local index = self.contains(element, compFunc)  
		return (index and self.queue[index][2]) or false  
	end  
  
	function self.setValue(element, value)  
		local index = self.contains(element, compFunc)  
		if index then  
			self.queue[index][2] = value  
			sift_up(index)  
			sift_down(index)  
			return true  
		else  
			return false  
		end  
	end  
	  
	return self  
end
return Queue

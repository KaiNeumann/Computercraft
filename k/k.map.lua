-- based on tinyMap http://pastebin.com/9GZkMSiF
-- I can only assume that code works :)

-- changed to closure type of class system
-- added method merge

Map = {}
function Map.new(mapDir)
	-- OBJECT INSTANCE
	local self = {
		map = 		{},
		mapDir = 	mapDir
	}
	-- INIT
	if type(mapDir) == "string" then
		if not fs.exists(mapDir) then
			fs.makeDir(mapDir)
		elseif not fs.isDir(mapDir) then
			error("compactMap new: not a valid directory", 2)
		else
			self.loadAll()
		end
	-- else
	--	error("compactMap new: directory must be string", 2) -- no, maps without mapDir can just not be loaded or saved
	end

	-- PRIVATE UTILITY FUNCTIONS
	local BIT_MASKS = {
		SET_COORD = bit.blshift(1, 5),
		SET_X_COORD = bit.blshift(1, 4),
		COORD = 15,
		COORD_DATA = bit.blshift(1, 4),
	}

	local function base256_to_base64(input)
		local output = {}
		for i = 1, #input, 3 do
			table.insert(output, bit.brshift(input[i] or 0, 2))
			table.insert(output, bit.blshift(bit.band(input[i] or 0, 3), 4) + bit.brshift(input[i+1] or 0, 4))
			table.insert(output, bit.blshift(bit.band(input[i+1] or 0, 15), 2) + bit.brshift(input[i+2] or 0, 6))
			table.insert(output, bit.band(input[i+2] or 0, 63))
		end
		return output
	end

	local function base64_to_base256(input)
		local output = {}
		for i = 1, #input, 4 do
			 table.insert(output, bit.blshift(input[i] or 0, 2) + bit.brshift(input[i+1] or 0, 4))
			 table.insert(output, bit.blshift(bit.band(input[i+1] or 0, 15), 4) + bit.brshift(input[i+2] or 0, 2))
			 table.insert(output, bit.blshift(bit.band(input[i+2] or 0, 3), 6) + (input[i+3] or 0))
		end
		return output
	end

	local function isValidValue(value)
		return value == nil or value == 0 or value == 1
	end

	local function toGridCode(tVector)
		return math.floor(tVector.x/16), math.floor(tVector.y/16), math.floor(tVector.z/16), tVector.x % 16, tVector.y % 16, tVector.z % 16
	end
		
	-- METHODS
	function self.getGrid(x, y, z)
		if not self.map[x] or not self.map[x][y] or not self.map[x][y][z] then
			return self.load(x, y, z)
		else
			return self.map[x][y][z]
		end
	end

	function self.setGrid(x, y, z, grid)
		if not self.map[x] then
			self.map[x] = {}
		end
		if not self.map[x][y] then
			self.map[x][y] = {}
		end
		self.map[x][y][z] = grid
		return self.map[x][y][z]
	end
	
	function self.load(tVector, y, z)
		local gX, gY, gZ
		if y and z then
			gX, gY, gZ = tVector, y, z
		else
			gX, gY, gZ = toGridCode(tVector)
		end
		local gridPath = fs.combine(self.mapDir, gX..","..gY..","..gZ)
		if fs.exists(gridPath) then
			local handle = fs.open(gridPath, "rb")
			if handle then
				local grid = {}
				
				local rawData = {}
				local rawDataByte = handle.read()
				while rawDataByte do
					table.insert(rawData, rawDataByte)
					rawDataByte = handle.read()
				end
				handle.close()
				
				--local data = rawData
				local data = base256_to_base64(rawData)
				
				--load grid data
				local currX, currY, currZ
				local dataByte
				for _, dataByte in ipairs(data) do
					if bit.band(dataByte, BIT_MASKS.SET_COORD) == BIT_MASKS.SET_COORD then
						--we are changing our currX or currY coord
						if bit.band(dataByte, BIT_MASKS.SET_X_COORD) == BIT_MASKS.SET_X_COORD then
							--we are changing our currX coord
							currX = bit.band(dataByte, BIT_MASKS.COORD)
						else
							--we are changing our currY coord
							currY = bit.band(dataByte, BIT_MASKS.COORD)
						end
					else
						--we are setting the value for a proper coord
						currZ = bit.band(dataByte, BIT_MASKS.COORD)
						if currX and currY and currZ then
							if not grid[currX] then
								grid[currX] = {}
							end
							if not grid[currX][currY] then
								grid[currX][currY] = {}
							end
							grid[currX][currY][currZ] = bit.brshift(bit.band(dataByte, BIT_MASKS.COORD_DATA), 4)
						end
					end
				end
				return self.setGrid(gX, gY, gZ, grid)
			end
		end
		return self.setGrid(gX, gY, gZ, {})
	end

	function self.loadAll()
		if fs.exists(self.mapDir) and fs.isDir(self.mapDir) then
			for _, gridFile in ipairs(fs.list(self.mapDir)) do
				local _, _, gX, gY, gZ = string.find(gridFile, "(.+)%,(.+)%,(.+)")
				if gX and gY and gX then
					self.load(tonumber(gX), tonumber(gY), tonumber(gZ))
				end
			end
		end
	end
	
	function self.save()
		for gX, YZmap in pairs(self.map) do
			for gY, Zmap in pairs(YZmap) do
				for gZ, grid in pairs(Zmap) do
					if next(grid) then
						local rawData = {}
						for x, gridYZ in pairs(grid) do
							table.insert(rawData, BIT_MASKS.SET_COORD + BIT_MASKS.SET_X_COORD + x)
							for y, gridZ in pairs(gridYZ) do
								table.insert(rawData, BIT_MASKS.SET_COORD + y)
								for z, coordValue in pairs(gridZ) do
									table.insert(rawData, bit.blshift(coordValue, 4) + z)
								end
							end
						end
						--local data = rawData
						local data = base64_to_base256(rawData)
						local handle = fs.open(fs.combine(self.mapDir, gX..","..gY..","..gZ), "wb")
						if handle then
							for _, dataByte in ipairs(data) do
								handle.write(dataByte)
							end
							handle.close()
						end
					else
						fs.delete(fs.combine(self.mapDir, gX..","..gY..","..gZ))
					end
				end
			end
		end
	end
	
	function self.get(tVector)
		local gX, gY, gZ, pX, pY, pZ = toGridCode(tVector)
		local grid = self.getGrid(gX, gY, gZ)
		if grid[pX] and grid[pX][pY] then
			return grid[pX][pY][pZ]
		end
	end

	function self.set(tVector, value)
		if not isValidValue(value) then
			--should we throw an error or use a default value?
			error("Map set: value is not valid", 2)
		end
		local gX, gY, gZ, pX, pY, pZ = toGridCode(tVector)
		local grid = self.getGrid(gX, gY, gZ)
		if not grid[pX] then
			grid[pX] = {}
		end
		if not grid[pX][pY] then
			grid[pX][pY] = {}
		end
		grid[pX][pY][pZ] = value
		return grid[pX][pY][pZ]
	end
	
	function self.getOrSet(tVector, value)
		local gX, gY, gZ, pX, pY, pZ = toGridCode(tVector)
		local grid = self.getGrid(gX, gY, gZ)
		if grid[pX] and grid[pX][pY] and grid[pX][pY][pZ] then
			return grid[pX][pY][pZ], false
		else
			if not isValidValue(value) then
				--should we throw an error or use a default value?
				error("Map getOrSet: value is not valid", 2)
			end
			if not grid[pX] then
				grid[pX] = {}
			end
			if not grid[pX][pY] then
				grid[pX][pY] = {}
			end
			grid[pX][pY][pZ] = value
			return grid[pX][pY][pZ], true
		end
   end
	
	function self.merge(otherMap, otherMapWins)
		local x, y = term.getCursorPos()
		local dots = 0  
		print("merging maps")  
		self.loadAll()
		for gX, yzGrid in pairs(otherMap) do  
			for gY, zGrid in pairs(yzGrid) do  
				for gZ, grid in pairs(zGrid) do  
					os.queueEvent("yield")  
					os.pullEvent()  
					term.setCursorPos(1, y-1)  
					dots = (dots + 1) % 3  
					print("merging maps", string.rep(".", dots))  
					for pX, yzPos in pairs(grid) do  
						for pY, zPos in pairs(yzPos) do  
							for pZ, value in pairs(zPos) do  
								local pos = vector.new(16*gX + pX, 16*gY + pY, 16*gZ + pZ)  
								-- update own map if no own value existing or if overruled
								if otherMapWins or not self.get( pos ) then
									self.set( pos, otherMap[gX][gY][gZ][pX][pY][pZ] )
								else
							end
						end
					end
				end
			end
		end
		self.save()
	end

	function self.compactMap()  
		local x, y = term.getCursorPos()  
		local dots = 0  
		print("evaluating nodes")  
		self.loadAll()  
		for gX, yzGrid in pairs(self.map) do  
			for gY, zGrid in pairs(yzGrid) do  
				for gZ, grid in pairs(zGrid) do  
					os.queueEvent("yield")  
					os.pullEvent()  
					term.setCursorPos(1, y-1)  
					dots = (dots + 1) % 3  
					print("evaluating nodes", string.rep(".", dots))  
					for pX, yzPos in pairs(grid) do  
						for pY, zPos in pairs(yzPos) do  
							for pZ, value in pairs(zPos) do  
								local pos = vector.new(16*gX + pX, 16*gY + pY, 16*gZ + pZ)  
								local surrounded = true  
								for _, s in ipairs(adjacent(pos)) do  
									if not self.get(s) then  
										surrounded = false  
										break  
									end  
								end  
								if surrounded then  
									self.set(pos, nil)  
								end  
							end  
						end  
					end  
				end  
			end  
		end  
		self.save()  
	end
	
	return self
end
return Map

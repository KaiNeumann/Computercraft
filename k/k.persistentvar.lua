local Persistentvar = {}
function Persistentvar.new(path,t)
	local self = {} -- the instance to return
	local path = path
	local class = "Persistentvar"
	local _value = {} -- contains a cache of the values. will be read from disk on creation only. all write activity goes also to disk

	if not fs.exists(path) then
		fs.makeDir(path)
	else
		assert(fs.isDir(path),"Path to persistent var needs to be a directory")
		local dummy
		for _,val in ipairs( fs.list(self.path() ) ) do
			dummy = self[val] -- triggers initial loading of the property, loading from disk
		end
	end
	if type(t)=="table" then
		self.init(t,true)
	end

	function self.class() return class end
	function self.path() return path end
	function self.init(t,bDontOverwrite)
		for key,val in pairs(t) do
			-- if init was called from constructor, don't overwrite existing values
			if not bOverwrite or not self[key] then
				self[key] = val -- trigger initial saving to disk
			end
		end
		return self
	end
	function self.keys()
		local keys = {}
		for key,_ in _value do
			keys.insert(key)
		end
		return #keys>0 and keys or nil
	end
	function self.pairs()
		local t = {}
		for key,value in pairs(_value) do
			t[key] = value
		end
		return pairs(t)
	end

	function self.save(key,value)
		local path = fs.combine(self.path(),key)

		local function write(typ,value)
			fs.delete(path)
			fs.open(path,"w")
			fs.writeLine( typ )
			fs.writeLine( value )
			fs.close()
		end

		-- handle own classes. Must implement a .class property and a .toString() method
		if type(value.toString) == "function" and type(value.class) == "string" then
			write(value.class,value.toString())
			return self
		end
		-- handle native types
		local t = type(value)
		if t == "table" then
			fs.delete(path)
			return Persistentvar.new(path,value)
		elseif t == "number" or t == "string" or t == "boolean" then
			write(t,value)
			return self
		elseif t == "nil" then
			fs.delete(path)
			return self
		end
		error("cannot save value of type "..t)
	end

	function self.load(key)
		local path = fs.combine(self.path(),key)
		if not fs.exist(path) then return nil end
		if fs.isDir(path) then return PersistentVar.new(path) end

		local file = fs.open(path,"r")
		local typ = file.readLine()
		local value = file.readLine()
		file.close()

		if typ == "number" then
			value = tonumber(value)
		elseif typ == "string" then
			-- nop
		elseif typ == "boolean" then
			value = value=="true"
		elseif typ == "table" then
			error(value.." shouldn't be of type table")
		elseif typ == "function" then
			error("functions are not supported")
		else
			-- value is a classname, custom fromString method expected
			local classname = value:gsub("^%l", string.upper)
			assert(_G[classname]~=nil,classname.."is not a known gloabl Class")
			assert(type(_G[classname].fromString)=="function",classname..".fromString is not a known function")
			value = _G[classname].fromString(value)
		end

		_value[key] = value
		return value
	end

	setmetatable(self,{
		__index = function(key) -- get
			assert(type(key)=="string","Key has to be a string")
			return _value[key] or self.load(key)
		end,
		__newindex = function(key, value)
			assert(type(key)=="string","Key has to be a string")
			self.save(key,value)
			_value[key] = value
			return self
		end
	})

	return self
end -- Persistenvar.new()
return Persistentvar

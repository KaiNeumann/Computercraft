local args = {...}
---------------------------------------------------------------------------------------------------
-- Installing and Updating my cc-framework-with-yet-no-name (ah, let's call it "k")
---------------------------------------------------------------------------------------------------
k = {}
k.directories = {
	-- Classes
	-- will be loaded via k.class[classname] = require("k/classes/[classname].lua")
	class = "k/classes",
	
	-- APIs 
	-- will be loadad via loadApi("k/apis/[apiname].lua") using [apiname] namespace
	api = "k/apis",
	
	-- Scripts
	-- loaded via [var] = require("k/scripts/[scriptname].lua")
	script = "k/scripts",
	
	-- Tasks
	-- only one task will be running at a time, all tasks implement the same interface
	-- loaded via k.task = require("k/tasks/[taskname].lua")
	-- loaded prior every usage and unloaded afterwards, because all are using the same name 
	task = "k/tasks",
	
	-- Logs
	logs = "k/logs",
}
k.files = {
	-- type, name, url or id, host, [github repository], [github branch]
	{"class","k.persistentvar.lua","zzaNvs16","pastebin"},
	--{"class","k.map.lua","","pastebin"},
	--{"class","k.pqueue.lua","","pastebin"},
	--{"script","k.navigation.lua","","pastebin"},
	--{"script","k.robot.lua","","pastebin"},
}

if (shell or mutlishell) then
	local command = args[1] or "run"
	if command == "setup" then k.setup(args[2],args[3],args[4]) -- purpose,label,service
		elseif command == "run" then k.run()
		elseif command == "destroy" then k.destroy()
		else error("Please call this script with no parameter to run, or with parameter 'setup', or 'destroy'") 
	end
	return true -- exit script
else
	k.update()
	k.run()
	return true -- exit script
end

function k.run()
	print("Run")
	-- FIXME do stuff
end

function k.setup(purpose, label, service) -- Setup k framework
	assert(shell or multishell or (purpose ~= nil and label~= nil  and service~= nil ),
		"Setup needs parameter if not called from shell"
	)
	print("Installing k framework")
	print("Remove all traces of former installations")
	k.destroy(true)
	print("Creating file structure")
		
	-- Main directory
	-- I will never write outside of this direcotry (exception:  "startup")
	fs.makeDir("k") 
	for k,v in pairs(k.directories) do
		fs.makeDir(v)
	end
	
	-- Variables
	fs.makeDir("k/var")
	-- Persistent Variables like state variables	
	fs.makeDir("k/var/p")
	-- Map data
	fs.makeDir("k/var/map")
	
	-- load all scripts, apis etc...
	k.update()
	
	print("Customizing")
	-- TODO interactively ask for purpose of the computer/turtle 
	
	-- interactively assign a label
	print("Set label")
	os.setComputerlabel(label or read())
	-- if not MASTER then contact master, get list of all services, display, interactively add it to a service master
		
	k.run()
	return true
end

function k.update()
	print("Updating k framework")
	assert( fs.exists("k"), "Please install the k.framework first by calling this script with the parameter 'setup'" )

	local function downloadCode(urlOrID,host,githubrepository,githubbranch)
		local knownHosts = { 
			generic = "@@", 	-- "@@" will be replaced by the url
			pastebin = "http://pastebin.com/raw.php?i=@@",
			pastee = "http://paste.ee/r/@@",
			github = "https://github.com/" .. githubrepository .. "/raw/" .. (githubbranch or "master") .. "/@@",
		}
		if host == nil then host = "generic" end
		assert(knownHosts[host],"Host "..host.." is not known")
		local path = string.gsub( knownHosts[host], "@@", urlOrID)
		local request = assert(http.get(path),"ERROR - couldn't download "..path..)
		local response = request.getResponseCode()
		assert(response==200,"ERROR: Bad HTTP response code " .. response .. " for " .. path)
		local code = request.readAll()
		return code
	end

	local function saveCode(path,code,overwrite)
		assert(overwrite or not fs.exists(path),"Overwriting of file "..path.." not allowed")
		fs.makeDir( fs.getDir( path ) )
		-- write file
		local file = fs.open(path,"w")
		file.write(code)
		file.close()
		return true
	end
	
	local doMinify = true -- change to false for debugging reasons
	local function checkFile(sType, name,urlOrID,host,githubrepository,githubbranch) --host is optional if url is complete
		assert(k.directories[sType]~=nil,"type "..sType.." of file "..name.." is unkown")
		-- TODO what to do with minifying ?
		local remotecode = downloadCode(urlOrID,host,githubrepository,githubbranch)
		local filename = k.directories[sType].."/"..name
		local localcode = loadfile(filename)
		-- save code if not existing or a different version
		if not localcode or localcode ~= remotecode then
			saveCode(filename,code,true)
		end
	end
	
	-- Utility function for shrinking the code.
	-- taken from https://github.com/fnuecke/lama/blob/master/programs/installer
	-- nice idea, but will minify normal multiline strings as well. But those should preserve their whitespace...
	local function minify(code)
		local lines = {}
		local inMultilineComment = false
		for line in string.gmatch(code, "[^\n]+") do
			line = line
			:gsub("^%s*(.-)%s*$", "%1")
			:gsub("^%-%-[^%[]*$", "")
			local keep = not inMultilineComment
			if inMultilineComment then
				if line == "]]" then
					inMultilineComment = false
				end
			elseif line:match("^%-%-%[%[") then
				inMultilineComment = true
				keep = false
			end
			if keep and line ~= "" then
				table.insert(lines, line)
			end
		end
		return table.concat(lines, "\n")
	end
	
	-- check all files in framework file list
	for _,v in ipairs(k.files) do
		checkFile(unpack(v)) 
	end
	
	-- create startup file (actually this file itself)
	fs.remove("startup")
	fs.copy("k.lua","startup")
	
	print("k framework successfully updated")
	return true
end

function k.destroy(bSilent) --Remove k framework
	assert(bSilent or shell or multishell,"Destroy can only be called either in silent mode or from shell")
	print("Removing k framework")
	fs.delete("k")
	fs.delete("startup")
	os.setComuterLabel(nil)
	assert(not fs.exists("k"),"Sorry, k framework couldn't be fully removed")
	print("k framework successfully deleted!")
	return true
end
---------------------------------------------------------------------------------------------------
-- End of framework functions
---------------------------------------------------------------------------------------------------

--[[
	inspiration found here:
	http://www.computercraft.info/forums2/index.php?/topic/23165-a-better-way-to-load-apis/
	better than  https://github.com/comp500/CCSnippets/blob/master/require.lua
]]
function k.require(path)
	local env = {}
	local api = {}
	setmetatable(env, {__index = _G}) -- ensure the new environment can fallback to global objects and methods
	local fn = assert(loadfile(path, env),"Couldn't load file "..path)
	-- setfenv(fn, env)    -- necessary? or done with the second parameter in loadfile() ?
	assert(pcall(fn),"Error in calling fn from "..path)
	for k,v in pairs(env) do
		-- if k ~= "_ENV" then  -- _ENV is the actual upvalue, needs to be skipped   // only relevant for LUA 5.2+, right?
			api[k] =  v
		-- end
	end
	return api
end
-- replace os.loadApi with a version that supports lua file extensions
-- inspired by https://github.com/lupus590/CC-Hive/blob/master/src/Shared/extentionCompatableLoadAPI.lua
function k.loadApi(path,overwrite)
	local name = fs.getName(path)
	-- strip ".lua" file extension
	name = string.match(name,"(%a+)%.?.-")
	assert(overwrite or _G[name]==nil, "API "..name.." already loaded")
	_G[name] = k.require(path)
	return true
end
function k.unloadApi(path)
	local name = fs.getName(path)
	-- strip ".lua" file extension
	name = string.match(name,"(%a+)%.?.-")
	_G[name] = nil
	return true
end
function k.import(path,overwrite)
	return k.mixin( _G, k.require(path), overwrite)
end
------------------------------------------------------------------
function k.mixin(existing,new,overwrite)
	for key,value in pairs(new)
		if existing[key]==nil or overwrite then
			existing[key] = value
		end
	end
	return existing
end
function k.instanceOf (subject, super)
	super = tostring(super)
	local mt = getmetatable(subject)
	while true do
		if mt == nil then return false end
		if tostring(mt) == super then return true end
		mt = getmetatable(mt)
	end	
end
--------------------------------------------------------------------

-- API k.navigation.lua
-- Only method of this API: getPath(start,goal,map)

map = map or require("k/classes/map.lua")
pQueue = pQueue or require("k/classes/pqueue.lua")

Navigation = {}

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

local function h(a, b) -- 1-norm/manhattan metric
	return math.abs(a.x - b.x) + math.abs(a.y - b.y) + math.abs(a.z - b.z)
end

local function d(a, b)
	return ((graph.get(a) or graph.get(b)) and math.huge) or h(a, b)
end

-- TODO would be nice if I could also return the cost of the path
local function makePath(nodes, start, startEnd, goalStart, goal)
	local current, path = startEnd, {}
	while not vectorEquals(current, start) do
		table.insert(path, current)
		current = nodes.get(current)[1]
	end
	current = goalStart
	while not vectorEquals(current, goal) do
		table.insert(path, 1, current)
		current = nodes.get(current)[1]
	end
	table.insert(path, 1, goal)
	return path
end

local function aStar(start, goal, graph)

	-- node data structure is {parent node, true cost from startNode/goalNode, whether in closed list, search direction this node was found in, whether in open list}
	local nodes = map.new()
	nodes.set(start, {start + vector.new(0, 0, -1), 0, false, "start", true})
	nodes.set(goal, {goal + vector.new(0, 0, -1), 0, false, "goal", true})

	local openStartSet = pQueue.new()
	openStartSet.insert(start, h(start, goal))

	local openGoalSet = pQueue.new()
	openGoalSet.insert(goal, h(start, goal))

	local yieldCount = 0
	local currQueue, currSide, lastNode, switch = openStartSet, "start", "none", false

	while not openStartSet.isEmpty() and not openGoalSet.isEmpty() do -- need to improve checks for no possible route

		yieldCount = yieldCount + 1
		if yieldCount > 200 then
			os.queueEvent("yield")
			os.pullEvent()
			yieldCount = 0
		end

		if switch then
			if currSide == "start" then
				currSide = "goal"
				currQueue = openGoalSet
			elseif currSide == "goal" then
				currSide = "start"
				currQueue = openStartSet
			end
			lastNode = "none"
		end

		local current, value = currQueue.pop()
		local currNode = nodes.get(current)
		local parent = current - currNode[1]
		currNode[3], currNode[5], switch = true, false, true

		for _, neighbour in ipairs(getAdjacentPos(current)) do
			if not graph.get(neighbour) then
				local nbrNode, newNode = nodes.getOrSet(neighbour, {current, currNode[2] + d(current, neighbour), false, currSide, false})
				if switch and (lastNode == "none" or vectorEquals(lastNode, neighbour)) then
					switch = false
				end

				local newCost = currNode[2] + d(current, neighbour)
				if not newNode then
					if currSide ~= nbrNode[4] then
						return makePath(nodes, start, (currSide == "start" and current) or neighbour, (currSide == "start" and neighbour) or current, goal)
					end
					if newCost < nbrNode[2] then
						if nbrNode[5] then
							currQueue.remove(neighbour, vectorEquals)
							nbrNode[5] = false
						end
						nbrNode[3] = false
					end
				end

				if (newNode or (not nbrNode[5] and not nbrNode[3])) and newCost < math.huge then
					nbrNode[1] = current
					nbrNode[2] = newCost
					nbrNode[4] = currNode[4]
					nbrNode[5] = true
					local preHeuristic = h(neighbour, start)
					currQueue.insert(neighbour, newCost + preHeuristic + 0.0001*(preHeuristic + parent.length(parent.cross(neighbour - current))))
				end
			end
		end
		lastNode = current

	end

	return false

end

-- public API
Navigation.getPath = aStar
return Navigation

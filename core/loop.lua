local objects = {}

local function add(object)
	if not object.poll then return end
	objects[object] = true
end

local function run()
	while next(objects) do
		for object in pairs(objects) do
			if object._done then
				objects[object] = nil
			else
				object:poll()
			end
		end
	end
end

return {
	add = add,
	run = run,
}


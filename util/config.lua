local types = {
	boolean = function(s) return s == "1" end,
	number = function(s) return tonumber(s) end,
	string = function(s) return s end,
}

return function(str, layout)
	local options = {}
	if layout then
		for k, v in pairs(layout) do
			options[k:lower()] = v[2]
		end
	end

	for k, v in string.gmatch(str, "(%S+)=(%S+)") do
		local lk = k:lower()
		local entry = layout[lk]
		if entry then
			options[lk] = types[entry[1]](v)
		else
			print("Unknown config option (" .. k .. ")")
		end
	end

	return options
end


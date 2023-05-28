-- https://github.com/thegrb93/StarfallEx/blob/debc969a9829f7935881667c9786f064e66e4a1e/lua/starfall/libs_sh/builtins.lua#L444

-- Copyright (c) 2011, Alex "Colonel Thirty Two" Parrill
-- All rights reserved.

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--     * Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--     * The names of the contributors of this project may not be used to
--       endorse or promote products derived from this software without specific
--       prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL ALEX PARRILL BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

local function printTableX(t, indent, alreadyprinted)
	if next(t) then
		for k, v in pairs(t) do
			if type(v) == "table" and not alreadyprinted[v] then
				alreadyprinted[v] = true
				print(string.rep("\t", indent) .. tostring(k) .. ":")
				printTableX(v, indent + 1, alreadyprinted)
			else
				print(string.rep("\t", indent) .. tostring(k) .. "\t=\t" .. tostring(v))
			end
		end
	else
		print(string.rep("\t", indent).."{}")
	end
end

--- Prints a table to stdout
---@param tbl table Table to print
return function(tbl)
	printTableX(tbl, 0, {[tbl] = true})
end


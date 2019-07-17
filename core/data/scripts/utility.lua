--[[
      -------------------------
      --- Utility Functions ---
      -------------------------
      This file contains various utility functions used by other scripts.
]]

------------------------
--- Global Variables ---
------------------------
-- set to true to enable prints
utility_enableDebugPrints = true


function dPrint_utility(message)
	if (utility_enableDebugPrints) then
		ba.print("[utility.lua] "..message.."\n")
	end
end

----------------------
--- Core Functions ---
----------------------

function trim(str)
	return str:find'^%s*$' and '' or str:match'^%s*(.*%S)'
end

function removeComments(line)
	local cut = line:find(";") -- there's gotta be something more robust than that hack job
	if (cut == nil) then
		return line
	else
		return line:sub(0, cut - 1)
	end
end

function extractCategory(line)
	local cut = string.find(line, "#")
	if (cut == nil) then
		return trim(line)
	else
		return trim(string.sub(line, cut + 1))
	end
end

function extractLeft(attribute)
	local line = attribute
	local cut = string.find(line, ":")
	if (cut == nil) then
		return trim(line)
	else
		if (string.find(line, "[#$+]") == nil) then
			return trim(string.sub(line, 1, cut - 1))
		else
			return trim(string.sub(line, 2, cut - 1))
		end
	end
end

function extractRight(attribute)
	local line = attribute
	local cut = string.find(line, ":")
	if (cut == nil) then
		return trim(line)
	else
		return trim(string.sub(line, cut + 1))
	end
end

-- copied from lua-user wiki
function split(str, pat)
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			cap = trim(cap)
			table.insert(t,cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end

--[[
	Returns the specified value as a string. If the value is a table, return each value separated by a space.

	@return value
]]
function getValueAsString(value)
	if (value == nil) then
		return "nil"
	elseif (type(value) == 'table') then
		local str = ""
		for index, currentValue in pairs(value) do
			str = str..getValueAsString(currentValue).." "
		end
		return str
	elseif (type(value) == 'boolean') then
		if (value) then
			return "true"
		else
			return "false"
		end
	else
		return value
	end
end

--[[
	Returns either the passed value, or the value according to the current difficulty level.

	@param value value or table of values
	@return actual value
]]
function getValueForDifficulty(value)
	if (type(value) == 'table') then
		return value[ba.getGameDifficulty()]
	else
		return value
	end
end

--TODO : doc
function contains(value_table, value)
	if (type(value_table) == 'table') then
		for i, currentValue in pairs(value_table) do
			if (currentValue == value) then
				return true
			end
		end
	else
		return value_table == value
	end

	return false
end

--[[
	Returns the specified value as a table

	@return table
]]
function getValueAsTable(value)
	if (type(value) == 'table') then
		return value
	else
		return {value}
	end
end

function count(table)
	local count = 0
	for key, value in pairs(table) do
		count = count + 1
	end
	return count
end

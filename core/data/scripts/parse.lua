--[[
	--------------------------------
	--- Generic FSO Table Parser ---
	--------------------------------
	This script is meant to parse data files written in the style of Freespace Open table files.
	The function parseTableFile return a lua table object that mimics the data structure of the parsed table,
	which you can then use or reorganise into easier-to-use data structures.
	Note that this is a 'dumb' parsing script: it doesn't check whether a required attribute is present or not, like FSO does.
	Also note that category names have to be explicitly declared. This helps keeping the complexity of the resulting lua table down a bit.

	Example:
	The following Freespace table:
		#Category
		$Name:				entry name
		$Attribute1:		attribute 1 value
		$Attribute2:		attribute 2 value
			+sub attribute:	sub value

		$Name:				second entry
		$Another attribute:	value
		$Attribute list: item1, item2, item3
		#End

		#Weapons: primary
		$Name:	n1
		$Attr:	val

		$Name:	n2
		$Attr:	val
		#End

		#Weapons: tertiary
		$Name:	n1
		$Attr:	val

		$Name:	n2
		$Attr:	val
		#End

-- TODO : deprecated !!!
	Will result in the following lua table:
		tab['Category']				['entry name']['Attribute1']['value']					= attribute 1 value
		tab['Category']				['entry name']['Attribute2']['value']					= attribute 2 value
		tab['Category']				['entry name']['Attribute2']['sub']['sub attribute']	= sub value
		tab['Category']				['second entry']['Another attribute']					= value
		tab['Category']				['second entry']['Attribute list']				[0]		= item1
		tab['Category']				['second entry']['Attribute list']				[1]		= item2
		tab['Category']				['second entry']['Attribute list']				[2]		= item3
		tab['Weapons: primary']		['n1']['Attr']											= val
		tab['Weapons: primary']		['n2']['Attr']											= val
		tab['Weapons: tertiary']	['n1']['Attr']											= val
		tab['Weapons: tertiary']	['n2']['Attr']											= val
]]--

------------------------
--- Global Constants ---
------------------------
PARSE_CONFIG_PATH = "data/config/"

------------------------
--- Global Variables ---
------------------------
-- set to true to enable prints
parse_enableDebugPrints = false


function dPrint_parse(message)
	if (parse_enableDebugPrints) then
		ba.print("[parse.lua] "..message.."\n")
	end
end

----------------------
--- Core Functions ---
----------------------

--[[
	Parses a value or a list of values

	@param value : value to parse
	@return value, or list of values
]]
function parse_parseValue(value)
	if (value:find(",")) then
		dPrint_parse("\t\tParsing attribute value list: "..value)
		list = split(value, ",")
		for index = 1, #list do
			list[index] = trim(list[index])
		end
		return list
	else
		dPrint_parse("\t\tParsing attribute value: "..value)
		return value
	end
end

--[[
	Prints the specified table object to a string

	@param tableObject : the table to print
	@return a string representing the table object
]]
function getTableObjectAsString(tableObject)
	local str = ""
	-- for each #Category
	for category, entries in pairs(tableObject) do
		str = str.."[parse.lua] #"..category.."\n\n"

		-- for each $Name:
		for name, attributes in pairs(entries) do
			str = str.."[parse.lua] $Name: \t"..name.."\n"

			-- for each $Attribute:
			for attributeName, prefixes in pairs(attributes) do
				if not (type(prefixes['value']) == 'table') then
					str = str.."[parse.lua] \t$"..attributeName.." = "..prefixes['value'].."\n"
				else
					str = str.."[parse.lua] \t"
					for index, value in pairs(prefixes['value']) do
						str = str..value.." "
					end
					str = str.."\n"
				end

				-- if there are any sub-attributes
				if not (prefixes['sub'] == nil) then
					-- for each +Sub Attribute:
					for subAttributeName, subAttributeValue in pairs(prefixes['sub']) do
						str = str.."[parse.lua] \t\t+"..subAttributeName.." = "..getValueAsString(subAttributeValue).."\n"
					end -- end for each attribute
				end

			end -- end for each attribute

		end -- end for each entry

		str = str.."\n[parse.lua] #End\n"
	end -- end for each category

	return str
end

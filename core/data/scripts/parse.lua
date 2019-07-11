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
	if (value:find(line, ",")) then
		dPrint_parse("\t\tParsing attribute value list: "..value)
		return split(value, ",")
	else
		dPrint_parse("\t\tParsing attribute value: "..value)
		return value
	end
end

-- deprecated
function getAttribute(value, isList)
	if (isList) then
		dPrint_parse("\t\tStuffing attribute list: "..value.."\n")
		local list = split(value, ",")
		-- Trim each list entry
		for index = 1, #list do
			list[index] = trim(list[index])
		end
		return list
	else
		dPrint_parse("\t\tStuffing attribute value: "..value.."\n")
		return value
	end
end

--[[
	@return a lua table containing data from the parsed table.
]]--
function parseTableFile(filePath, fileName)
	local tableObject = {}

	if cf.fileExists(fileName, filePath, true) then
		local file = cf.openFile(fileName, "r", filePath)

		local line = file:read("*l")
		local lineNumber = 1

		dPrint_parse("#############################################\n")
		ba.print("[parse.lua] Parsing file "..fileName.."\n");
		dPrint_parse("#############################################\n")

		while (not (line == nil)) do
			line = removeComments(line)
			line = trim(line)
			-- Don't parse empty lines
			if not (line == "") then
				-- Extract values
				local attribute = extractLeft(line)
				local value = extractRight(line)
				-- Extract flags
				local isCat = not (string.find(line, "^#") == nil)
				local isAttr = not (string.find(line, "[$]") == nil)
				local isSubAttr = not (string.find(line, "[+]") == nil)
				local isList = not (string.find(line, ",") == nil)
				local isEnd = not (string.find(line, "^#End") == nil)

				dPrint_parse("Parsing line #"..lineNumber..": "..line.." ("..attribute.." = "..value..")\n")
				dPrint_parse("\tLine flags: Category = "..getValueAsString(isCat)..", Attribute = "..getValueAsString(isAttr)..", Sub Attribute = "..getValueAsString(isSubAttr)..", List = "..getValueAsString(isList)..", End = "..getValueAsString(isEnd).."\n")
				if  (isEnd) then
					dPrint_parse("Reached an #End marker\n")
				else
					if (isCat) then
						category = extractCategory(line)
						dPrint_parse("Entering category: "..category.."\n")
						tableObject[category] = {}
					elseif (isAttr) then
						if (attribute == "Name") then
							name = value
							dPrint_parse("\n")
							dPrint_parse("Name="..name.."\n")
							tableObject[category][name] = {}

						else
							currentAttribute = attribute	-- save attribute name in case we run into sub attributes
							dPrint_parse(category.." - "..name.." - "..attribute.."\n")
							tableObject[category][name][attribute] = {}
							tableObject[category][name][attribute]['value'] = getAttribute(value, isList)

							dPrint_parse("name="..name.."; attribute="..attribute.."; value="..getValueAsString(value).."\n")
						end
					elseif (isSubAttr) then
						-- initialize if needs be
						if (tableObject[category][name][currentAttribute]['sub'] == nil) then
							tableObject[category][name][currentAttribute]['sub'] = {}
						end
						tableObject[category][name][currentAttribute]['sub'][attribute] = getAttribute(value, isList)

						dPrint_parse("name="..name.."; current attribute="..currentAttribute.."; sub attribute="..attribute.."; value="..value.."\n")
					end
				end
				--
			end
			line = file:read("*l")
			lineNumber = lineNumber + 1;
		end
	else
		ba.warning("[parse.lua] Table file not found: "..filePath..fileName.."\n")
	end

	return tableObject
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

-------------------------
--- New parsing stuff ---
-------------------------

TableObject = {}

--[[
	Creates a table object

	@param tableName : name of the table
	@return table object
]]
function TableObject:create(tableName)
	ba.warning("test")
	ba.warning(tableName)
	dPrint_parse("Creating table object : "..tableName)
	tableObject = {}
	setmetatable(tableObject, TableObject)

	tableObject.Name = tableName
	tableObject.Categories = {}

	return tableObject
end

function TableObject:toString()

end

--[[
	Creates a category object

	@param categoryName : name of the category
	@return category object
]]
function parse_createCategory(categoryName)
	dPrint_parse("Creating category object : "..categoryName)

	local category = {
		Name = categoryName,
		Entries = {}
	}

	return category
end

--[[
	Creates an entry object

	@param entryName : name of the entry
	@return entry object
]]
function parse_createEntry(entryName)
	dPrint_parse("Creating entry object : "..entryName)

	local entry = {
		Name = entryName,
		Attributes = {}
	}

	return entry
end

--[[
	Creates an attribute object

	@param attributeName : name of the attribute
	@return attribute object
]]
function parse_createAttribute(attributeName, value)
	dPrint_parse("Creating attribute object : "..attributeName)

	local attribute = {
		Name = attributeName,
		Value = parse_parseValue(value),
		Attributes = {}
	}

	return attribute
end




--TODO : doc
function parse_parseTableFile(fileName)

	if cf.fileExists(fileName, PARSE_CONFIG_PATH, true) then
		-- Initialise loop variables
		local file = cf.openFile(fileName, "r", PARSE_CONFIG_PATH)
		local line = file:read("*l")
		local lineNumber = 1
		local tableObject = TableObject.create(fileName)
		local currentCategory = nil
		local currentEntry = nil
		local currentAttribute = nil
		local currentSubAttribute = nil

		dPrint_parse("#############################################")
		dPrint_parse("Parsing file "..fileName);
		dPrint_parse("#############################################")

		while (not (line == nil)) do
			line = removeComments(line)
			line = trim(line)

			dPrint_parse("Parsing line : "..line)
			-- Don't parse empty lines
			if not (line == "") then
				-- Extract values
				local attribute = extractLeft(line)
				local value = extractRight(line)

				-- Identify and parse line
				if (line:find("^#") and not line:find("^#End")) then
					dPrint_parse("Found a category")
					currentCategory = parse_createCategory(attribute)
					tableObject.Categories[currentCategory.Name] = currentCategory

				elseif (line:find("^[$]Name")) then
					dPrint_parse("Found an entry")
					currentEntry = parse_createEntry(value)
					currentCategory.Entries[currentEntry.Name] = currentEntry

				elseif (line:find("^[$]")) then
					dPrint_parse("Found an attribute")
					currentAttribute = parse_createAttribute(attribute, value)
					currentEntry.Attributes[currentAttribute.Name] = currentAttribute

				elseif (line:find("^[+]")) then
					dPrint_parse("Found a sub-attribute")
					currentSubAttribute = parse_createAttribute(attribute, value)
					currentAttribute.Attributes[currentSubAttribute.Name] = currentSubAttribute
				end

			end
			line = file:read("*l")
			lineNumber = lineNumber + 1;
		end
	else
		ba.warning("[parse.lua] Table file not found: "..PARSE_CONFIG_PATH..fileName.."\n")
	end

	return tableObject
end

-------------------------
--- New parsing stuff ---
-------------------------

TableObject = {
	Name = "",
	Categories = {}
}

--[[
	Creates a table object

	@param tableName : name of the table
	@return table object
]]
function TableObject:create(tableName)
	dPrint_parse("Creating table object : "..tableName)
	local tableObject = {}
	setmetatable(tableObject, self)
  self.__index = self

	tableObject.Name = tableName
	tableObject.Categories = {}

	tableObject:parse()

	return tableObject
end

function TableObject:parse()
	if cf.fileExists(self.Name, PARSE_CONFIG_PATH, true) then
		-- Initialise loop variables
		local file = cf.openFile(self.Name, "r", PARSE_CONFIG_PATH)
		local line = file:read("*l")
		local lineNumber = 1
		local currentCategory = nil
		local currentEntry = nil
		local currentAttribute = nil
		local currentSubAttribute = nil

		dPrint_parse("#############################################")
		dPrint_parse("Parsing file "..self.Name);
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
					currentCategory = Category:create(extractCategory(line))
					self.Categories[currentCategory.Name] = currentCategory

				elseif (line:find("^[$]Name")) then
					dPrint_parse("Found an entry")
					currentEntry = Entry:create(value)
					currentCategory.Entries[currentEntry.Name] = currentEntry

				elseif (line:find("^[$]")) then
					dPrint_parse("Found an attribute")
					currentAttribute = Attribute:create(attribute, value)
					currentEntry.Attributes[currentAttribute.Name] = currentAttribute

				elseif (line:find("^[+]")) then
					dPrint_parse("Found a sub-attribute")
					currentSubAttribute = Attribute:create(attribute, value)
					currentAttribute.SubAttributes[currentSubAttribute.Name] = currentSubAttribute
				end

			end
			line = file:read("*l")
			lineNumber = lineNumber + 1;
		end

		file:close()
	else
		ba.warning("[parse.lua] Table file not found: "..PARSE_CONFIG_PATH..self.Name.."\n")
	end
end

function TableObject:toString()
  local stringValue = "TableObject: "..self.Name.." ("..count(self.Categories).." categories)"
  for name, category in pairs(self.Categories) do
    stringValue = stringValue.."\n"..category:toString().."\n"
  end
	return stringValue
end

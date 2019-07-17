Attribute = {
	Name = "",
  Value = {},
	SubAttributes = {}
}


function Attribute:create(name, value)
	dPrint_parse("Creating attribute : "..name.." --> value = "..value)
	local attribute = {}
	setmetatable(attribute, self)
	self.__index = self

	attribute.Name = name
  attribute.Value = parse_parseValue(value)
	attribute.Attributes = {}

	return attribute
end

function Attribute:toString()
  local stringValue = "$"..self.Name..":\t"..getValueAsString(self.Value)
  -- TODO : print subattributes
  return stringValue
end

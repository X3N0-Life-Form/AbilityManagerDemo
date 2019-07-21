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
	attribute.SubAttributes = {}

	return attribute
end

function Attribute:toString()
  local stringValue = "$"..self.Name..":\t"..getValueAsString(self.Value)
  for name, subAttribute in pairs(self.SubAttributes) do
    stringValue = stringValue.."\n\t+"..subAttribute.Name..":\t"..getValueAsString(subAttribute.Value)
  end
  return stringValue
end

function Attribute:getValue(attribute, default)
	if (attribute ~= nil) then
		return attribute.Value
	else
		return default
	end
end

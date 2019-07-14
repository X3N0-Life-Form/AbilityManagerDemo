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

	self.Name = name
  self.Value = parse_parseValue(value)
	self.Attributes = {}

	return attribute
end

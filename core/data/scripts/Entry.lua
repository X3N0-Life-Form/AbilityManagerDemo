Entry = {
	Name = "",
	Attributes = {}
}


function Entry:create(name)
	dPrint_parse("Creating entry : "..name)
	local entry = {}
	setmetatable(entry, self)
	self.__index = self

	entry.Name = name
	entry.Attributes = {}

	return entry
end

function Entry:toString()
  local stringValue = "$Name:\t"..self.Name
  for name, attribute in pairs(self.Attributes) do
    stringValue = stringValue.."\n"..attribute:toString()
  end
  return stringValue
end

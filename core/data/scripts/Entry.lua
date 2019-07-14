Entry = {
	Name = "",
	Attributes = {}
}


function Entry:create(name)
	dPrint_parse("Creating entry : "..name)
	local entry = {}
	setmetatable(entry, self)
	self.__index = self

	self.Name = name
	self.Attributes = {}

	return entry
end

Category = {
	Name = "",
	Entries = {}
}


function Category:create(name)
	dPrint_parse("Creating category : "..name)
	local category = {}
	setmetatable(category, self)
	self.__index = self

	self.Name = name
	self.Entries = {}

	return category
end

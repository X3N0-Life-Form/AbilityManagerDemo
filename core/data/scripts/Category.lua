Category = {
	Name = "",
	Entries = {}
}


function Category:create(name)
	dPrint_parse("Creating category : "..name)
	local category = {}
	setmetatable(category, self)
  self.__index = self

	category.Name = name
	category.Entries = {}

	return category
end

function Category:toString()
  local stringValue = "\n#"..self.Name.."\t; ("..count(self.Entries).." entries)"
  for name, entry in pairs(self.Entries) do
    stringValue = stringValue.."\n\n"..entry:toString()
  end
  stringValue = stringValue.."\n\n#End\n"
  return stringValue
end

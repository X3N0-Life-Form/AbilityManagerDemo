
AbilityClass = {
  Name = name,
  Function = "",
  TargetType = "",
  TargetTeam = "",
  TargetSelection = "Closest",
  Cooldown = nil,
  Range = -1,
  Cost = 0,
  StartingReserve = nil,
  CostType = nil,
  CastingSound = nil,
  Buffs = {},
  PassiveBuffs = {},
  AbilityData = nil,

  getData = nil --TODO OOP
}


--[[
	Creates a class of the specified name and attributes

	@param name : class name
	@param entry : table Entry
]]
function AbilityClass:createClass(name, entry)
	dPrint_ability("Creating ability class : "..name)
	-- Initialize the class
  local abilityClass = {}
  setmetatable(abilityClass, self)
  self.__index = self
	ability_classes[name] = abilityClass

  -- Fill in default values
  abilityClass.Name = name
  abilityClass.Function = entry.Attributes['Function'].Value
  abilityClass.TargetType = entry.Attributes['Target Type'].Value --TODO : use getValue ?
  abilityClass.TargetTeam = entry.Attributes['Target Team'].Value --TODO : ditto
  abilityClass.CostType = ability_createCostType('Ammo')

	abilityClass.getData = nil --TODO OOP

  -- Set parsed values
	if (entry.Attributes['Cooldown'] ~= nil) then
		abilityClass.Cooldown = entry.Attributes['Cooldown'].Value
	end

	if (entry.Attributes['Range'] ~= nil) then
		abilityClass.Range = tonumber(entry.Attributes['Range'].Value)
	end

	if (entry.Attributes['Cost'] ~= nil) then
		abilityClass.Cost = tonumber(entry.Attributes['Cost'].Value)
		-- TODO : utility function to grab a sub attributes' value ???
		if (entry.Attributes['Cost'].SubAttributes ~= nil) then
			-- Cost type
			if (entry.Attributes['Cost'].SubAttributes['Cost Type'] ~= nil) then
				abilityClass.CostType = ability_createCostType(entry.Attributes['Cost'].SubAttributes['Cost Type'].Value)
			end

			-- Starting Reserve
			if (entry.Attributes['Cost'].SubAttributes['Starting Reserve'] ~= nil) then
				abilityClass.StartingReserve = entry.Attributes['Cost'].SubAttributes['Starting Reserve'].Value
			end
		end
	end

	if (entry.Attributes['Ability Data'] ~= nil) then
		abilityClass.AbilityData = entry.Attributes['Ability Data'].SubAttributes
		abilityClass.getData = entry.Attributes['Ability Data'].SubAttributes
	end

	if (entry.Attributes['Target Selection'] ~= nil) then
		abilityClass.TargetSelection = entry.Attributes['Target Selection'].Value
	end

	if (entry.Attributes['Casting Sound'] ~= nil) then
		abilityClass.CastingSound = entry.Attributes['Casting Sound'].Value
	end

	if (entry.Attributes['Buffs'] ~= nil) then
		abilityClass.Buffs = getValueAsTable(entry.Attributes['Buffs'].Value)
	end

  if (entry.Attributes['Passive Buffs'] ~= nil) then
    abilityClass.PassiveBuffs = getValueAsTable(entry.Attributes['Passive Buffs'].Value)
  end

	-- Print class
	dPrint_ability(abilityClass:toString())

  return abilityClass
end


--[[
	Returns the specified class as a string.

	@param className : name of the class
	@return class as printable string
]]
function AbilityClass:toString(className)
	local class = ability_classes[className]
	local str = "Ability class:\t"..self.Name.."\n"
		.."\tFunction = "..getValueAsString(self.Function).."\n"
		.."\tTargetType = "..getValueAsString(self.TargetType).."\n"
		.."\tTargetTeam = "..getValueAsString(self.TargetTeam).."\n"
		.."\tTargetSelection = "..getValueAsString(self.TargetSelection).."\n"
		.."\tCooldown = "..getValueAsString(self.Cooldown).."\n"
		.."\tRange = "..getValueAsString(self.Range).."\n"
		.."\tCost = "..getValueAsString(self.Cost).."\n"
		.."\t\tStarting Reserve = "..getValueAsString(self.StartingReserve).."\n"
		.."\t\tCostType = "..ability_getCostTypeAsString(self.CostType).."\n"
		.."\tBuffs = "..getValueAsString(self.Buffs).."\n"
    .."\tPassive Buffs = "..getValueAsString(self.PassiveBuffs).."\n"
		.."\tAbilityData = "
		if (self.AbilityData ~= nil) and count(self.AbilityData) > 0 then
			str = str.."\n"
			for name, attribute in pairs(self.AbilityData) do
				str = str.."+"..attribute:toString().."\n"
			end
		else
			str = str.."None\n"
		end
		return str
end

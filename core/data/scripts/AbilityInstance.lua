AbilityInstance = {
  Class = "",
  Ship = "",
  LastFired = -1,
  Active = true,
  Manual = false, --if that instance must be fire manually
  Ammo = -1, --needs to be set after creation if necessary
  LastReload = -1
}

--[[
	Creates an instance of the specified ability and tie it to the specified shipName.

	@param instanceId : unique identifier for this instance
	@param className : name of the ability
	@param shipName : ship to tie the ability to. Can be nil.
	@return Created instance
]]
function AbilityInstance:create(instanceId, className, shipName)
	dPrint_ability("Creating instance of class "..className.." with id "..instanceId.." for ship "..getValueAsString(shipName))
  -- Initialize the class
  local abilityInstance = {}
  setmetatable(abilityInstance, self)
  self.__index = self
  ability_instances[instanceId] = abilityInstance

  abilityInstance.Class = className
  abilityInstance.Ship = shipName

	local class = ability_classes[className]
	if (class == nil) then
		ba.warning("[abilityManager.lua] Invalid class name: "..className)
	end

	if not (class.StartingReserve == -1) then
		abilityInstance.Ammo = getValueForDifficulty(class.StartingReserve)
	end

	dPrint_ability(abilityInstance:toString())
	return abilityInstance
end


--[[
	Returns an instance as a string.

	@return instance as a printable string
]]
function AbilityInstance:toString()
	return "Ability instance:\t"..self.Class.."\n"
		.."\tShip = "..getValueAsString(self.Ship).."\n"
		.."\tLastFired = "..getValueAsString(self.LastFired).."\n"
		.."\tActive = "..getValueAsString(self.Active).."\n"
		.."\tManual = "..getValueAsString(self.Manual).."\n"
		.."\tAmmo = "..getValueAsString(self.Ammo).."\n"
    .."\tLastReload = "..getValueAsString(self.LastReload).."\n"
end

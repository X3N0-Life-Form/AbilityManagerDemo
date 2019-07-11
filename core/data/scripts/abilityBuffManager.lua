--[[
	Fires a buff

	@param instanceId : id of the buff instance to fire
	@param targetName : name of the target ship
]]
function buff_fire(instanceId, targetName)
	local instance = buff_instances[instanceId]
	local class = buff_classes[instance.Class]
	dPrint_ability("Firing buff '"..instanceId.."' ("..class.Name..") on "..targetName)

	-- Route the firing to the proper script
	if (class.EffectFunction ~= "none" and class.EffectFunction ~= nil) then
		_G[class.EffectFunction](instance, class, targetName)
	end

	-- Update instance status
	instance.LastFired = mn.getMissionTime()
end


--[[
	Fires all active buffs & cleans up expired instances
]]
function buff_fireAllPossible()

	if (ability_debugPrintQuietMode == false) then
		dPrint_ability("Fire all possible buffs !")
	end

	-- Cycle through buffs instances & apply their effect
	for instanceId, instance in pairs(buff_instances) do
		local class = buff_classes[instance.Class]
		local duration = mn.getMissionTime() - instance.ApplyTime
		local targetName = instance.Ship
		local target = mn.Ships[targetName]

		-- If the buff is still active
		if (duration <= class.Duration) then

			-- Fire buff if possible
			if (target ~= nil and target:isValid()) then
				-- Verifiy periodicity
				local period = mn.getMissionTime() - instance.LastFired
				if (period >= class.Periodicity) then
					buff_fire(instanceId, targetName)
				end
			end

		else
			-- Buff expires
			dPrint_ability("Buff '"..instanceId.."' ("..class.Name..") is expiring on target "..targetName)

			-- If it has an effect on expiration
			if (class.ExpirationFunction ~= "none" and class.ExpirationFunction ~= nil) then
				_G[class.ExpirationFunction](instance, class, targetName)
			end

			-- Clean up instance table
			buff_instances[instanceId] = nil
		end
	end
end

--TODO : doc
function buff_createClass(name, attributes)
	dPrint_ability("Creating buff class : "..name)
	-- Initialize the class
	buff_classes[name] = {
		Name = name,
		Duration = tonumber(attributes['Duration']['value']),
		Periodicity = -1,
		ApplyFunction = nil,
		EffectFunction = nil,
		ExpirationFunction = nil,
		Stacks = false,
		RefreshOnApply = false,
		BuffData = {},

		getData = nil -- TODO OOP
	}

	local class = buff_classes[name]

	-- Periodicity
	if (attributes['Periodicity'] ~= nil) then
		class.Periodicity = tonumber(attributes['Periodicity']['value'])
	end

	-- Functions
	if (attributes['Apply Function'] ~= nil) then
		class.ApplyFunction = attributes['Apply Function']['value']
	end

	if (attributes['Effect Function'] ~= nil) then
		class.EffectFunction = attributes['Effect Function']['value']
	end

	if (attributes['Expiration Function'] ~= nil) then
		class.ExpirationFunction = attributes['Expiration Function']['value']
	end

	-- Stacking & refreshing
	if (attributes['Stacks'] ~= nil) then
		class.Stacks = attributes['Stacks']['value']
	end

	if (attributes['RefreshOnApply'] ~= nil) then
		class.RefreshOnApply = attributes['RefreshOnApply']['value']
	end

	-- Buff data
	if (attributes['Buff Data'] ~= nil) then
		class.BuffData = attributes['Buff Data']['sub']
		class.getData = attributes['Buff Data']['sub']
	end

	dPrint_ability(buff_getClassAsString(class.Name))
end

--[[
	Creates an instance of the specified buff and tie it to the specified shipName.

	@param instanceId : unique identifier for this instance
	@param className : name of the buff
	@param shipName : ship to tie the buff to.
	@return Created instance
]]
function buff_createInstance(instanceId, className, shipName)
	buff_instances[instanceId] = {
		Class = className,
		Ship = shipName,
		LastFired = -1,
		ApplyTime = mn.getMissionTime()
	}
	local instance = buff_instances[instanceId]

	return instance
end

--[[
	Returns the specified buff class as a string.

	@param className : name of the class
	@return class as printable string
]]
function buff_getClassAsString(className)
	local class = buff_classes[className]

	return "Buff class:\t"..class.Name.."\n"
		.."\tApplyFunction = "..getValueAsString(class.ApplyFunction).."\n"
		.."\tEffectFunction = "..getValueAsString(class.EffectFunction).."\n"
		.."\tExpirationFunction = "..getValueAsString(class.ExpirationFunction).."\n"
		.."\tDuration = "..getValueAsString(class.Duration).."\n"
		.."\tPeriodicity = "..getValueAsString(class.Periodicity).."\n"
		.."\tDuration = "..getValueAsString(class.Duration).."\n"
		.."\tStacks = "..getValueAsString(class.Stacks).."\n"
		.."\tRefreshOnApply = "..getValueAsString(class.RefreshOnApply).."\n"
		.."\tBuffData = "..getValueAsString("-- TODO --").."\n" --TODO : print buff data
end

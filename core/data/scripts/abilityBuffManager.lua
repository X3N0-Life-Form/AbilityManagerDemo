-- TODO : doc


buff_displayPlayerBuffs = true
buff_displayTargetBuffs = true
buff_ships = {}

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

-- TODO : make it work
	if (class.TickSound ~= nil) then
		local soundEntry = ad.getSoundentry(class.TickSound)
		ad.play3DSound(soundEntry, mn.Ships[targetName].Position)
	end

	-- Update instance status
	instance.LastFired = mn.getMissionTime()
end

-- TODO : print active buffs
--[[
	Displays an active buff's status.

	@param instance : buff instance to display
]]
function buff_displayBuff(instance)
	local class = buff_classes[instance.Class]

	local tickCooldown =  (instance.LastFired + getValueForDifficulty(class.Periodicity)) - mn.getMissionTime()
	if (tickCooldown < 0) or (instance.LastFired <= 0) then
		tickCooldown = 0
	end

	local expirationTime = instance.ApplyTime + class.Duration
	local timeLeft = expirationTime - mn.getMissionTime()

	-- Status color
	if (class.BuffAlignment == 'good') then
		gr.setColor(50,50,255)
	elseif (class.BuffAlignment == 'neutral') then
		gr.setColor(200,200,200)
	elseif (class.BuffAlignment == 'evil' or class.BuffAlignment == 'bad') then
		gr.setColor(255,50,50)
	else
		ba.warning("[abilityBuffManager.lua] Undefined BuffAlignment: "..class.BuffAlignment)
		gr.setColor(255,255,255)
	end

	-- Begin printing
	gr.drawString(class.Name..":")
	gr.drawString("\tTick Cooldown: "..string.format("%.2f", tickCooldown))
	gr.drawString("\tTime left: "..string.format("%.2f", timeLeft))
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
			buff_ships[targetName] = nil
		end
	end

	-- Display player buffs
	if (buff_displayPlayerBuffs) then
		-- Get the player's ship
		local playerShip = mn.Ships[hv.Player.Name]

		gr.setColor(255,255,255)
		gr.drawString("Active buffs:", gr.getScreenWidth() * 0.60, gr.getScreenHeight() * 0.10)
		if (buff_ships[playerShip.Name] ~= nil) then
			for instanceId, instance in pairs(buff_ships[playerShip.Name]) do
				buff_displayBuff(instance)
			end
		end
	end

	-- TODO Display target buffs
	gr.setColor(255,255,255)
	gr.drawString("Target buffs:", gr.getScreenWidth() * 0.40, gr.getScreenHeight() * 0.10)
	gr.drawString("TODO")

end

-- TODO doc
function buff_applyBuffs(abilityClass, targetName)

	for index, buffClassName in pairs(abilityClass.Buffs) do
		-- Verify that this is a valid buff name
		if (buff_classes[buffClassName] == nil) then
			ba.warning("[abilityManager.lua] Unrecognised buff class : "..buffClassName)
		end

		local buffClass = buff_classes[buffClassName]
		local buffInstanceId = targetName.."::"..buffClass.Name.."::"..mn.getMissionTime()
		dPrint_ability("Applying buff '"..buffInstanceId.."' ("..buffClass.Name..") at "..targetName)

		-- TODO : handle stacking & refreshing
		local buffInstance = buff_createInstance(buffInstanceId, buffClass.Name, targetName)

		-- Attach newly created buff to its ship
		if (buff_ships[targetName] == nil) then
			buff_ships[targetName] = {}
		end
		buff_ships[targetName][buffInstanceId] = buffInstance

		-- Apply effects
		if (buffClass.ApplyFunction ~= "none" and buffClass.ApplyFunction ~= nil) then
			dPrint_ability("Triggering buff application effects")
			_G[buffClass.ApplyFunction](buffInstance, buffClass, targetName)
		end
	end

end

--TODO : doc
function buff_createClass(name, entry)
	dPrint_ability("Creating buff class : "..name)
	-- Initialize the class
	buff_classes[name] = {
		Name = name,
		BuffAlignment = 'good',
		Duration = tonumber(entry.Attributes['Duration'].Value),
		Periodicity = -1,
		ApplyFunction = nil,
		EffectFunction = nil,
		ExpirationFunction = nil,
		Stacks = false,
		RefreshOnApply = false,
		TickSound = nil,
		BuffData = {},

		getData = nil -- TODO OOP
	}

	local class = buff_classes[name]

	-- Buff Alignment
	if (entry.Attributes['Buff Alignment'] ~= nil) then
		class.BuffAlignment = entry.Attributes['Buff Alignment'].Value
	end

	-- Periodicity
	if (entry.Attributes['Periodicity'] ~= nil) then
		class.Periodicity = tonumber(entry.Attributes['Periodicity'].Value)
	end

	-- Functions
	if (entry.Attributes['Apply Function'] ~= nil) then
		class.ApplyFunction = entry.Attributes['Apply Function'].Value
	end

	if (entry.Attributes['Effect Function'] ~= nil) then
		class.EffectFunction = entry.Attributes['Effect Function'].Value
	end

	if (entry.Attributes['Expiration Function'] ~= nil) then
		class.ExpirationFunction = entry.Attributes['Expiration Function'].Value
	end

	-- Stacking & refreshing
	if (entry.Attributes['Stacks'] ~= nil) then
		class.Stacks = entry.Attributes['Stacks'].Value
	end

	if (entry.Attributes['RefreshOnApply'] ~= nil) then
		class.RefreshOnApply = entry.Attributes['RefreshOnApply'].Value
	end

	if (entry.Attributes['Tick Sound'] ~= nil) then
		class.TickSound = entry.Attributes['Tick Sound'].Value
	end

	-- Buff data
	if (entry.Attributes['Buff Data'] ~= nil) then
		class.BuffData = entry.Attributes['Buff Data'].SubAttributes
		class.getData = entry.Attributes['Buff Data'].SubAttributes
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
		.."\BuffAlignment = "..getValueAsString(class.BuffAlignment).."\n"
		.."\tDuration = "..getValueAsString(class.Duration).."\n"
		.."\tPeriodicity = "..getValueAsString(class.Periodicity).."\n"
		.."\tDuration = "..getValueAsString(class.Duration).."\n"
		.."\tStacks = "..getValueAsString(class.Stacks).."\n"
		.."\tRefreshOnApply = "..getValueAsString(class.RefreshOnApply).."\n"
		.."\TickSound = "..getValueAsString(class.TickSound).."\n"
		.."\tBuffData = "..getValueAsString("-- TODO --").."\n" --TODO : print buff data
end

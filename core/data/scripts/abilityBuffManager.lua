-- TODO : doc

buff_enableDebugPrints = true

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
	local buffClass = buff_classes[instance.Class]
	dPrint_buff("Firing buff '"..instanceId.."' ("..buffClass.Name..") on "..targetName)

	-- Route the firing to the proper script
	if (buffClass.EffectFunction ~= "none" and buffClass.EffectFunction ~= nil) then
		_G[buffClass.EffectFunction](instance, buffClass, targetName)
	end

	-- Play tick sound effect
	if (buffClass.TickSound ~= nil) then
		playSoundAtPosition(buffClass.TickSound, mn.Ships[targetName].Position)
	end

	if (buffClass.TickEffect ~= nil) then
		-- TODO : getSize cf. sub attributes --> make a vfx class
		playEffectAtPosition(buffClass.TickEffect, targetPosition, mn.Ships[targetName].Class.Model.Radius)
	end

	-- Update instance status
	instance.LastFired = mn.getMissionTime()
end


--[[
	Displays an active buff's status.

	@param instance : buff instance to display
]]
function buff_displayBuff(instance)
	local buffClass = buff_classes[instance.Class]

	local tickCooldown =  (instance.LastFired + getValueForDifficulty(buffClass.Periodicity)) - mn.getMissionTime()
	if (tickCooldown < 0) or (instance.LastFired <= 0) then
		tickCooldown = 0
	end

	local expirationTime = instance.ApplyTime + buffClass.Duration
	local timeLeft = expirationTime - mn.getMissionTime()

	-- Status color
	if (buffClass.BuffAlignment == 'good') then
		gr.setColor(50,50,255)
	elseif (buffClass.BuffAlignment == 'neutral') then
		gr.setColor(200,200,200)
	elseif (buffClass.BuffAlignment == 'evil' or buffClass.BuffAlignment == 'bad') then
		gr.setColor(255,50,50)
	else
		ba.warning("[abilityBuffManager.lua] Undefined BuffAlignment: "..buffClass.BuffAlignment)
		gr.setColor(255,255,255)
	end

	-- Begin printing
	gr.drawString(buffClass.Name..":")
	gr.drawString("\tTick Cooldown: "..string.format("%.2f", tickCooldown))
	gr.drawString("\tTime left: "..string.format("%.2f", timeLeft))
end

--[[
	Fires all active buffs & cleans up expired instances
]]
function buff_fireAllPossible()

	if (ability_debugPrintQuietMode == false) then
		dPrint_buff("Fire all possible buffs !")
	end

	-- ---------- --
	-- Buff cycle --
	-- ---------- --
	-- Cycle through buffs instances & apply their effect
	for instanceId, instance in pairs(buff_instances) do
		local buffClass = buff_classes[instance.Class]
		local duration = mn.getMissionTime() - instance.ApplyTime
		local targetName = instance.Ship
		local target = mn.Ships[targetName]

		-- If the buff is still active
		if (duration <= buffClass.Duration) then

			-- Fire buff if possible
			if (target ~= nil and target:isValid()) then
				-- Verifiy periodicity
				local period = mn.getMissionTime() - instance.LastFired
				if (period >= buffClass.Periodicity) then
					buff_fire(instanceId, targetName)
				end
			end

		else
			-- Buff expires
			dPrint_buff("Buff '"..instanceId.."' ("..buffClass.Name..") is expiring on target "..targetName)

			-- If it has an effect on expiration
			if (buffClass.ExpireFunction ~= "none" and buffClass.ExpireFunction ~= nil) then
				_G[buffClass.ExpireFunction](instance, class, targetName)
			end

			-- Special effects
			if (buffClass.ExpireSound ~= nil) then
				playSoundAtPosition(buffClass.ExpireSound, target.Position)
			end

			if (buffClass.ExpireEffect ~= nil) then
				-- TODO : getSize cf. sub attributes
				playEffectAtPosition(buffClass.ExpireEffect, target.Position, mn.Ships[targetName].Class.Model.Radius)
			end

			-- Clean up instance table
			buff_instances[instanceId] = nil
			buff_ships[targetName] = nil
		end
	end

	-- ------------ --
	-- Buff display --
	-- ------------ --
	-- Get the player's ship
	local playerShip = mn.Ships[hv.Player.Name]
	-- Display player buffs
	if (buff_displayPlayerBuffs) then
		gr.setColor(255,255,255)
		gr.drawString("Active buffs:", gr.getScreenWidth() * 0.60, gr.getScreenHeight() * 0.10)
		if (buff_ships[playerShip.Name] ~= nil) then
			for instanceId, instance in pairs(buff_ships[playerShip.Name]) do
				buff_displayBuff(instance)
			end
		end
	end

	-- Display target buffs
	if (buff_displayTargetBuffs and playerShip.Target:isValid() and playerShip.Target:getBreedName() == 'Ship') then
		local playerTarget = playerShip.Target.Name
		gr.setColor(255,255,255)
		gr.drawString("Target buffs:", gr.getScreenWidth() * 0.40, gr.getScreenHeight() * 0.10)
		if (buff_ships[playerTarget] ~= nil) then
			for instanceId, instance in pairs(buff_ships[playerTarget]) do
				buff_displayBuff(instance)
			end
		end
	end

end

--[[
	Apply the buffs of the specified ability to target

	@param abilityClass : ability class
	@param targetName : target ship name
]]
function buff_applyAbilityBuffs(abilityClass, targetName)

	for index, buffClassName in pairs(abilityClass.Buffs) do
		buff_applyBuff(buffClassName, targetName)
	end

end

--[[
	Apply buff to specified target

	@param buffClassName : buff name
	@param targeName : target
]]
function buff_applyBuff(buffClassName, targetName)
	-- Verify that this is a valid buff name
	if (buff_classes[buffClassName] == nil) then
		ba.warning("[abilityBuffManager.lua] Unrecognised buff class : "..buffClassName)
	end

	local buffClass = buff_classes[buffClassName]
	local buffInstanceId = targetName.."::"..buffClass.Name.."::"..mn.getMissionTime()
	dPrint_buff("Applying buff '"..buffInstanceId.."' ("..buffClass.Name..") at "..targetName)

	-- TODO : handle stacking & refreshing
	local buffInstance = buff_createInstance(buffInstanceId, buffClass.Name, targetName)

	-- Attach newly created buff to its ship
	if (buff_ships[targetName] == nil) then
		buff_ships[targetName] = {}
	end
	buff_ships[targetName][buffInstanceId] = buffInstance

	-- Apply effects
	if (buffClass.ApplyFunction ~= "none" and buffClass.ApplyFunction ~= nil) then
		dPrint_buff("Triggering buff application effects")
		_G[buffClass.ApplyFunction](buffInstance, buffClass, targetName)
	end

	-- Special effects
	local targetPosition = mn.Ships[targetName].Position
	if (buffClass.ApplySound ~= nil) then
		playSoundAtPosition(buffClass.ApplySound, targetPosition)
	end

	if (buffClass.ApplyEffect ~= nil) then
		-- TODO : getSize cf. sub attributes
		playEffectAtPosition(buffClass.ApplyEffect, targetPosition, mn.Ships[targetName].Class.Model.Radius)
	end
end

--TODO : doc
function buff_createClass(name, entry)
	dPrint_buff("Creating buff class : "..name)
	-- Initialize the class
	buff_classes[name] = {
		Name = name,
		BuffAlignment = 'good',
		Duration = tonumber(entry.Attributes['Duration'].Value),
		Periodicity = -1,
		ApplyFunction = nil,
		EffectFunction = nil,
		ExpireFunction = nil,
		Stacks = false,
		RefreshOnApply = false,
		ApplySound = nil,
		TickSound = nil,
		ExpireSound = nil,
		ApplyEffect = nil,
		TickEffect = nil,
		ExpireEffect = nil,
		BuffData = {},

		getData = nil -- TODO OOP
	}

	local buffClass = buff_classes[name]

	-- Buff Alignment
	if (entry.Attributes['Buff Alignment'] ~= nil) then
		buffClass.BuffAlignment = entry.Attributes['Buff Alignment'].Value
	end

	-- Periodicity
	if (entry.Attributes['Periodicity'] ~= nil) then
		buffClass.Periodicity = tonumber(entry.Attributes['Periodicity'].Value)
	end

	-- Functions
	if (entry.Attributes['Apply Function'] ~= nil) then
		buffClass.ApplyFunction = entry.Attributes['Apply Function'].Value
	end

	if (entry.Attributes['Effect Function'] ~= nil) then
		buffClass.EffectFunction = entry.Attributes['Effect Function'].Value
	end

	if (entry.Attributes['Expire Function'] ~= nil) then
		buffClass.ExpireFunction = entry.Attributes['Expire Function'].Value
	end

	-- Stacking & refreshing
	if (entry.Attributes['Stacks'] ~= nil) then
		buffClass.Stacks = entry.Attributes['Stacks'].Value
	end

	if (entry.Attributes['RefreshOnApply'] ~= nil) then
		buffClass.RefreshOnApply = entry.Attributes['RefreshOnApply'].Value
	end

	-- Sound effets
	if (entry.Attributes['Apply Sound'] ~= nil) then
		buffClass.ApplySound = entry.Attributes['Apply Sound'].Value
	end

	if (entry.Attributes['Tick Sound'] ~= nil) then
		buffClass.TickSound = entry.Attributes['Tick Sound'].Value
	end

	if (entry.Attributes['Expire Sound'] ~= nil) then
		buffClass.ExpireSound = entry.Attributes['Expire Sound'].Value
	end

	-- Visual effects
	if (entry.Attributes['Apply Effect'] ~= nil) then
		buffClass.ApplyEffect = entry.Attributes['Apply Effect'].Value
	end

	if (entry.Attributes['Tick Effect'] ~= nil) then
		buffClass.TickEffect = entry.Attributes['Tick Effect'].Value
	end

	if (entry.Attributes['Expire Effect'] ~= nil) then
		buffClass.ExpireEffect = entry.Attributes['Expire Effect'].Value
	end

	-- Buff data
	if (entry.Attributes['Buff Data'] ~= nil) then
		buffClass.BuffData = entry.Attributes['Buff Data'].SubAttributes
		buffClass.getData = entry.Attributes['Buff Data'].SubAttributes
	end

	dPrint_buff(buff_getClassAsString(buffClass.Name))
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

-------------------------
--- Utility Functions ---
-------------------------

function dPrint_buff(message)
	if (buff_enableDebugPrints) then
		ba.print("[abilityBuffManager.lua] "..message.."\n")
	end
end

--[[
	Returns the specified buff class as a string.

	@param className : name of the class
	@return class as printable string
]]
function buff_getClassAsString(className)
	local buffClass = buff_classes[className]

	return "Buff class:\t"..buffClass.Name.."\n"
		.."\tApplyFunction = "..getValueAsString(buffClass.ApplyFunction).."\n"
		.."\tEffectFunction = "..getValueAsString(buffClass.EffectFunction).."\n"
		.."\tExpireFunction = "..getValueAsString(buffClass.ExpireFunction).."\n"
		.."\BuffAlignment = "..getValueAsString(buffClass.BuffAlignment).."\n"
		.."\tDuration = "..getValueAsString(buffClass.Duration).."\n"
		.."\tPeriodicity = "..getValueAsString(buffClass.Periodicity).."\n"
		.."\tDuration = "..getValueAsString(buffClass.Duration).."\n"
		.."\tStacks = "..getValueAsString(buffClass.Stacks).."\n"
		.."\tRefreshOnApply = "..getValueAsString(buffClass.RefreshOnApply).."\n"
		-- TODO : other sfx & vfx
		.."\TickSound = "..getValueAsString(buffClass.TickSound).."\n"
		.."\tBuffData = "..getValueAsString("-- TODO --").."\n" --TODO : print buff data
end

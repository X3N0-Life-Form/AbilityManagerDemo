--[[
	---------------------------------
	--- Ability Manager Framework ---
	---------------------------------
	This script is meant to provide a framework to create and use special abilities.
	Abilities are defined in a table called "abilities.tbl".
	Ability functions should be defined in a separate .lua file.

	Functions of interest :
		* ability_cycleTrigger()
		* ability_trigger(instanceId)
		* ability_reload(instanceId)
		* ability_getClassAsString(className)
		* ability_getInstanceAsString(instanceId)
		* ability_attachAbility(className, shipName, isManuallyFired)

	Constants :
		* set ability_displayPlayerAbilities to true either in this script or via SEXPs to display player abilities

	Table Specification :
	#Abilities

	$Name: string
	$Function: string
		* function to call when firing the ability
	$Target Type: list of string
		* ship types
	$Target Team: list of string
		* hostile, friendly, relative to the caster
	$Target Selection: list of string
		* Closest, Current target, Random, Self
	$Range: integer (optional)
		; TODO: +Min: integer (minimum range) (optional)
	$Cost: integer/list of integer (tied to diffculty level) (optional)
		+Cost type: string (optional)
			* what ammo consumption system is to be used
			* Ammo (default), energy:weapon, energy:shield, energy:afterburner
		+Starting Reserve:	integer (optional)
	$Cooldown: number
		* ability cooldown time
	; TODO : $Duration: list of int (optional)
	; TODO: $Always manual: boolean
	; TODO: $Buff: list of string (optional)
	; TODO : sound effects?
	$Ability Data:
		* sub-attributes contain metadata used by the function called

	#End
]]

------------------------
--- Global Variables ---
------------------------

ability_classes = {}
ability_instances = {}
ability_ships = {}
ability_lastCast = 0

buff_classes = {}
buff_instances = {}

------------------------
--- Global Constants ---
------------------------
-- set to true to enable prints
ability_enableDebugPrints = true
ability_debugPrintQuietMode = true
ability_displayPlayerAbilities = true
ability_displayMissionAbilities = false

ability_castInterval = 0.1

--TODO : be more object-oriented
----------------------------
--- High Level Functions ---
----------------------------

-- TODO : differenciate starting reserve & max ammo
--[[
	Reloads the specified instance to its starting reserve.
	If it doesn't have a starting reserve, increase current ammo reserve by 1
]]
function ability_reload(instanceId)
	local instance = ability_instances[instanceId]
	local class = ability_classes[instance.Class]

	-- If no starting reserve is defined, add 1 shot
	if (class.StartingReserve == nil) then
		instance.Ammo = instance.Ammo + 1
	else
		instance.Ammo = class.StartingReserve
	end
end

--[[
	Triggers the fireAllPossible function at regular intervals
]]
function ability_cycleTrigger()
	local missionTime = mn.getMissionTime()
	if (missionTime > ability_lastCast + ability_castInterval) then
		ability_fireAllPossible()
		ability_lastCast = missionTime
	end

	-- Apply over-time effects?
	buff_fireAllPossible()

	-- Print ability instances
	gr.setColor(255,255,255)
	if (ability_displayMissionAbilities) then
		gr.drawString("Instanciated abilities:", gr.getScreenWidth() * 0.01, gr.getScreenHeight() * 0.15)
		for instanceId, instance in pairs(ability_instances) do
			gr.drawString("\t"..ability_getInstanceAsString(instanceId))
		end
	end

	-- Display player abilities
	if (ability_displayPlayerAbilities) then
		-- Get the player's ship
		local playerShip = mn.Ships[hv.Player.Name]

		gr.drawString("Active abilities:", gr.getScreenWidth() * 0.80, gr.getScreenHeight() * 0.15)
		if not (ability_ships[playerShip.Name] == nil) then
			for instanceId, instance in pairs(ability_ships[playerShip.Name]) do
				ability_displayAbility(instance)
			end
		end
	end
end

--[[
	Displays an ability's status.

	@param instance : ability instance to display
]]
function ability_displayAbility(instance)
	local class = ability_classes[instance.Class]
	local cooldown =  (instance.LastFired + getValueForDifficulty(class.Cooldown)) - mn.getMissionTime()
	if (cooldown < 0) or (instance.LastFired <= 0) then
		cooldown = 0
	end

	-- Status color
	if (class.Cost > 0) and (instance.Ammo == 0) then
		gr.setColor(255,0,0)
	elseif (cooldown > 0) then
		gr.setColor(255,255,0)
	else
		gr.setColor(0,255,0)
	end

	-- Begin printing
	gr.drawString(class.Name..":")

	if (class.Cost > 0) then
		gr.drawString("\tCost: "..class.Cost.." ("..class.CostType.Type..")")
		if (class.CostType.Type == 'Ammo') then
			gr.drawString("\tAmmo: "..instance.Ammo)
		end
	end

	if (class.Range >= 0) then
		gr.drawString("\tRange: "..class.Range)
	end

	gr.drawString("\tCooldown: "..string.format("%.2f", cooldown))
end

--[[
	Triggers an ability's firing routines.

	@param instanceId : Ability to trigger.
]]
function ability_trigger(instanceId)
	dPrint_ability("Triggering firing routines for ability '"..instanceId.."'")
	if (ability_instances[instanceId] == nil) then
		ba.warning("[abilityManager.lua] Invalid instance id: '"..instanceId.."'")
	end

	local target = ability_getTargetInRange(instanceId)
	if (target:isValid()) then
		ability_fireIfPossible(instanceId, target.Name)
	end
end

--[[
	Fires an ability

	@param instanceId : id of the ability instance to fire
	@param targetName : name of the target ship
]]
function ability_fire(instanceId, targetName)
	local instance = ability_instances[instanceId]
	local class = ability_classes[instance.Class]
	dPrint_ability("Firing '"..instanceId.."' ("..class.Name..") at "..targetName)

	-- Route the firing to the proper script
	if not (class.Function == "none") then
		_G[class.Function](instance, class, targetName)
	end

	-- Apply buff
	-- TODO extract function
	for index, buffClassName in pairs(class.Buffs) do
		-- Verify that this is a valid buff name
		if (buff_classes[buffClassName] == nil) then
			ba.warning("[abilityManager.lua] Unrecognised buff class : "..buffClassName)
		end

		local buffClass = buff_classes[buffClassName]
		local buffInstanceId = targetName.."::"..buffClass.Name.."::"..mn.getMissionTime()
		dPrint_ability("Applying buff '"..buffInstanceId.."' ("..buffClass.Name..") at "..targetName)

		-- TODO : handle stacking & refreshing
		local buffInstance = buff_createInstance(buffInstanceId, buffClass.Name, targetName)

		-- Apply effects
		if (buffClass.ApplyFunction ~= "none" and buffClass.ApplyFunction ~= nil) then
			dPrint_ability("Triggering buff application effects")
			_G[buffClass.ApplyFunction](buffInstance, buffClass, targetName)
		end
	end

	-- Fire sound effect
	-- TODO WiP
	if (class.CastingSound ~= nil) then
		dPrint_ability("Firing sound effect")
		local soundEntry = ad.getSoundentry(class.CastingSound)
		ad.play3DSound(soundEntry, mn.Ships[targetName].Position)
	end

	-- Update instance status
	instance.LastFired = mn.getMissionTime()

	-- Apply cost
	ability_calculateCost(instance, class, true)

	dPrint_ability("Instance new status :")
	dPrint_ability(ability_getInstanceAsString(instanceId))
end

--[[
	Fires an ability at the specified target if possible

	@param instanceId : id of the ability instance to fire
	@param targetName : name of the target ship
]]
function ability_fireIfPossible(instanceId, targetName)
	dPrint_ability("Fire '"..instanceId.."' at "..targetName.." if possible")
	-- TODO : handle target-less abilities
	if (ability_canBeFired(instanceId)) then
		if (ability_canBeFiredAt(instanceId, targetName)) then
			ability_fire(instanceId, targetName)
		end
	end
end

--[[
	Fires all abilities if possible. Also includes target lookup.
]]
function ability_fireAllPossible()
	if (ability_debugPrintQuietMode == false) then
		dPrint_ability("Fire all possible instances !")
	end

	-- Cycle through ability instances & fire them
	for instanceId, instance in pairs(ability_instances) do
		local isManuallyFired = ability_instances[instanceId].Manual

		-- If this ability is fired automatically
		if (isManuallyFired == false) then
			local target = ability_getTargetInRange(instanceId)

			-- If we grabbed a valid target
			if (not (target == nil) and target:isValid()) then
				ability_fireIfPossible(instanceId, target.Name)
			end

		else
			if (ability_debugPrintQuietMode == false) then
				dPrint_ability(instanceId.." must be triggered manually")
			end
		end
	end
end


-------------------------
--- Utility Functions ---
-------------------------

function dPrint_ability(message)
	if (ability_enableDebugPrints) then
		ba.print("[abilityManager.lua] "..message.."\n")
	end
end

--[[
	Returns the specified class as a string.

	@param className : name of the class
	@return class as printable string
]]
function ability_getClassAsString(className)
	local class = ability_classes[className]
	local str = "Ability class:\t"..class.Name.."\n"
		.."\tFunction = "..getValueAsString(class.Function).."\n"
		.."\tTargetType = "..getValueAsString(class.TargetType).."\n"
		.."\tTargetTeam = "..getValueAsString(class.TargetTeam).."\n"
		.."\tTargetSelection = "..getValueAsString(class.TargetSelection).."\n"
		.."\tCooldown = "..getValueAsString(class.Cooldown).."\n"
		.."\tRange = "..getValueAsString(class.Range).."\n"
		.."\tCost = "..getValueAsString(class.Cost).."\n"
		.."\t\tStarting Reserve = "..getValueAsString(class.StartingReserve).."\n"
		.."\t\tCostType = "..ability_getCostTypeAsString(class.CostType).."\n"
		.."\tBuffs = "..getValueAsString(class.Buffs).."\n"
		.."\tAbilityData = "
		if not (class.AbilityData == nil) and count(class.AbilityData) > 0 then
			str = str.."\n"
			for name, attribute in pairs(class.AbilityData) do
				str = str.."+"..attribute:toString().."\n"
			end
		else
			str = str.."None\n"
		end
		return str
end

--[[
	Returns a cost type as a string.

	@param costType : structure
	@return cost type as printable string
]]
function ability_getCostTypeAsString(costType)
	local str = "nil"

	if not (costType == nil) then
		str = costType.Type

		if (costType.Global) then
			str = str.." (global)"
		end

		if (costType.Energy) then
			str = str.." (energy)"
		end
	end

	return str
end

--[[
	Returns an instance as a string.

	@param instanceId : instance id
	@return instance as a printable string
]]
function ability_getInstanceAsString(instanceId)
	local instance = ability_instances[instanceId]
	return "Ability instance:\t"..instance.Class.."\n"
		.."\tShip = "..getValueAsString(instance.Ship).."\n"
		.."\tLastFired = "..getValueAsString(instance.LastFired).."\n"
		.."\tActive = "..getValueAsString(instance.Active).."\n"
		.."\tManual = "..getValueAsString(instance.Manual).."\n"
		.."\tAmmo = "..getValueAsString(instance.Ammo).."\n"
end

--[[

]]
function ability_getShipAbilities(shipName)
	local ship = nil
	--TODO
end

----------------------
--- Core Functions ---
----------------------



--[[
	Creates a class of the specified name and attributes

	@param name : class name
	@param entry : table Entry
]]
function ability_createClass(name, entry)
	dPrint_ability("Creating ability class : "..name)
	-- Initialize the class
	ability_classes[name] = {
	  Name = name,
	  Function = entry.Attributes['Function'].Value,
	  TargetType = entry.Attributes['Target Type'].Value,--TODO : use getValue ?
	  TargetTeam = entry.Attributes['Target Team'].Value,--TODO : ditto
	  TargetSelection = "Closest",
	  Cooldown = nil,
	  Range = -1,
	  Cost = 0,
	  StartingReserve = nil,
	  CostType = ability_createCostType('Ammo'),
		CastingSound = nil,
		Buffs = {},
	  AbilityData = nil,

		getData = nil --TODO OOP
	}

	local class = ability_classes[name]

	if not (entry.Attributes['Cooldown'] == nil) then
		class.Cooldown = entry.Attributes['Cooldown'].Value
	end

	if not (entry.Attributes['Range'] == nil) then
		class.Range = tonumber(entry.Attributes['Range'].Value)
	end

	if not (entry.Attributes['Cost'] == nil) then
		class.Cost = tonumber(entry.Attributes['Cost'].Value)
		-- TODO : utility function to grab a sub attributes' value ???
		if not (entry.Attributes['Cost'].SubAttributes == nil) then
			-- Cost type
			if not (entry.Attributes['Cost'].SubAttributes['Cost Type'] == nil) then
				class.CostType = ability_createCostType(entry.Attributes['Cost'].SubAttributes['Cost Type'].Value)
			end

			-- Starting Reserve
			if not (entry.Attributes['Cost'].SubAttributes['Starting Reserve'] == nil) then
				class.StartingReserve = entry.Attributes['Cost'].SubAttributes['Starting Reserve'].Value
			end
		end
	end

	if not (entry.Attributes['Ability Data'] == nil) then
		class.AbilityData = entry.Attributes['Ability Data'].SubAttributes
		class.getData = entry.Attributes['Ability Data'].SubAttributes
	end

	if not (entry.Attributes['Target Selection'] == nil) then
		class.TargetSelection = entry.Attributes['Target Selection'].Value
	end

	if (entry.Attributes['Casting Sound'] ~= nil) then
		class.CastingSound = entry.Attributes['Casting Sound'].Value
	end

	if (entry.Attributes['Buffs'] ~= nil) then
		class.Buffs = getValueAsTable(entry.Attributes['Buffs'].Value)
	end

	-- Print class
	dPrint_ability(ability_getClassAsString(name))
end

--[[
	Creates a cost type

	@param costTypeValue : cost type value
	@return cost type
]]
function ability_createCostType(costTypeValue)
	dPrint_ability("Creating cost type : "..costTypeValue)
	-- Init
	local costType = {
		Type = "Ammo",
		Global = false,
		Energy = false
	}

	-- Extract value
	costType.Type = extractRight(costTypeValue)

	-- Identify subType
	if not (costTypeValue:find(":") == nil) then
		local subType = extractLeft(costTypeValue)
		if (subType == "global") then
			costType.Global = true
		elseif (subType == "energy") then
			costType.Energy = true
		else
			ba.warning("[abilityManager.lua] Unrecognised cost sub type : "..subType)
		end
	end

	return costType
end

--[[
	Resets the instance array. Should be called $On Gameplay Start.
]]
function ability_resetMissionVariables()
	ability_instances = {}
	ability_ships = {}
	ability_lastCast = 0
	buff_instances = {}
end


--[[
	Creates an instance of the specified ability and tie it to the specified shipName.

	@param instanceId : unique identifier for this instance
	@param className : name of the ability
	@param shipName : ship to tie the ability to. Can be nil.
	@return Created instance
]]
function ability_createInstance(instanceId, className, shipName)
	dPrint_ability("Creating instance of class "..className.." with id "..instanceId.." for ship "..getValueAsString(shipName))
	local class = ability_classes[className]
	if (class == nil) then
		ba.warning("[abilityManager.lua] Invalid class name: "..className)
	end

	ability_instances[instanceId] = {
		Class = className,
		Ship = shipName,
		LastFired = -1,
		Active = true,
		Manual = false, --if that instance must be fire manually
		Ammo = -1 --needs to be set after creation if necessary
	}

	local instance = ability_instances[instanceId]

	if not (class.StartingReserve == nil) then
		instance.Ammo = getValueForDifficulty(class.StartingReserve)
	end

	dPrint_ability(ability_getInstanceAsString(instanceId))
	return instance
end


--[[
	Verifies that this ability instance can be fired

	@param instanceId : id of the ability instance to test
	@return true if it can
]]
function ability_canBeFired(instanceId)
	-- Check that this is a valid id
	if (ability_instances[instanceId] == nil) then
		ba.warning("[abilityManager.lua] Unknown instance id : "..instanceId)
		return false
	end

	local instance = ability_instances[instanceId]
	local castingShip = mn.Ships[instance.Ship]
	local class = ability_classes[instance.Class]
	dPrint_ability("Can '"..instanceId.."' ("..instance.Class..") be fired ?")

	-- Make sure that the ship is actually there
	if not (castingShip:isValid()) then
		dPrint_ability("Invalid ship : "..instanceId.Ship)-- TODO : test this/look into auto_ssm, see if we did it there
		return false
	end

	-- Verify that this instance is active
	if (instance.Active) then

		-- Verify cooldown
		local missionTime = mn.getMissionTime()
		local cooldown = getValueForDifficulty(class.Cooldown)

		-- If it has never been fired or is off cooldown
		if ((instance.LastFired == -1) or (instance.LastFired + cooldown <= missionTime)) then
			dPrint_ability("\tCooldown OK")

			-- Verify cost
			if (class.Cost > 0) then
				-- Handle cost type
				local costTest = ability_calculateCost(instance, class, false)

				-- Actual cost test
				if (costTest >= 0) then
					dPrint_ability("\tCost OK")
					return true
				else
					dPrint_ability("\tCost KO "..costTest)
				end

			else
				-- Case : no cost
				dPrint_ability("\tNo ammo cost")
				return true
			end
		else
			dPrint_ability("\tStill under cooldown")
		end
	end

	-- Default
	return false
end

--[[
	Calculate how much firing this instance would cost

	@param instance : instance to fire
	@param class : instance class
	@param applyCost : boolean, if true apply the cost to the instance/ship according to its type
	@return How much ammo/energy would remain
]]
function ability_calculateCost(instance, class, applyCost)
	local costType = class.CostType
	local costTest = -1
	dPrint_ability("Calculating cost for type "..costType.Type)

	if (costType == nil) or (costType.Type == "Ammo") then
		dPrint_ability("\tCalculating Ammo")
		costTest = instance.Ammo - class.Cost
		if (applyCost) then
			instance.Ammo = costTest
		end

	elseif (costType.Energy) then
		dPrint_ability("\tCalculating Energy")
		local ship = mn.Ships[instance.Ship]
		local subType = extractRight(costType.Type)

		-- Handle sub-types
		if (subType == 'weapon') then
			costTest = ship.WeaponEnergyLeft - class.Cost
			if (applyCost) then
				ship.WeaponEnergyLeft = costTest
			end
		elseif (subType == 'afterburner') then
			costTest = ship.AfterburnerFuelLeft - class.Cost
			if (applyCost) then
				ship.AfterburnerFuelLeft = costTest
			end
		elseif (subType == 'shield') then
			costTest = ship.Shields.CombinedLeft - class.Cost
			if (applyCost) then
				ship.Shields.CombinedLeft = costTest
			end
		else
			ba.warning('[abilityManager.lua] Unrecognised energy cost type : '..costType)
		end

	else
		costTest = instance.Ammo - class.Cost
	end

	return costTest
end

--[[
	Verifies that the target is in range and of a valid type

	@param instanceId : id of the ability instance to test
	@param targetName : name of the target ship
	@return true if it can
]]
function ability_canBeFiredAt(instanceId, targetName)
	local instance = ability_instances[instanceId]
	-- Verify id
	if (ability_instances[instanceId] == nil) then
		ba.warning("[abilityManager.lua] Unknown instance id : "..instanceId)
		return false
	end

	dPrint_ability("Can '"..instanceId.."' be fired at "..targetName.." ?")
	local class = ability_classes[instance.Class]
	local firingShip = mn.Ships[instance.Ship]
	local targetShip = mn.Ships[targetName]
	-- Verify that both handles are valid
	if (firingShip == nil or targetShip == nil) then
		ba.warning("[abilityManager.lua] TODO")--TODO : warning + handle checks
		return false
	else
		local distance = firingShip.Position:getDistance(targetShip.Position)
		dPrint_ability("\tDistance to target: "..distance.." (range = "..class.Range..")")
		-- Verify range
		if (distance <= class.Range or class.Range == -1) then
			dPrint_ability("\tTarget in range")

			-- Verify target team
			if (ability_isValidTeam(class, firingShip, targetShip)) then
				dPrint_ability("\tTarget team is valid")

				-- Verify target type
				if (ability_isValidShipType(class, targetShip)) then
					dPrint_ability("\tTarget type is valid")
					return true
				end
			end
		end

		-- Default
		return false
	end
end

--[[
	Verifies the IFF of two ships compared to who the ability can target

	@param class : ability class
	@param firingShip : handle for the ship firing the ability
	@param targetShip : handle for the targetted ship
	@return true if the team is a valid target
]]
function ability_isValidTeam(class, firingShip, targetShip)
	dPrint_ability("Is "..targetShip.Team.Name.." a valid target for a "..class.Name.." called by "..firingShip.Team.Name.." ?")

	local isHostile = firingShip.Team:attacks(targetShip.Team)
	if (isHostile and contains(class.TargetTeam, "Hostile")) then
		return true
	elseif (not isHostile and contains(class.TargetTeam, "Friendly")) then
		return true
	end

	return false
end

--[[
	Verifies that a ship is of a valid type for an ability

	@param class : ability class
	@param targetShip : valid ship handle
	@return true if the target ship is of a valid type
]]
function ability_isValidShipType(class, targetShip)
	local shipTypeName = trim(targetShip.Class.Type.Name:lower())
	dPrint_ability("Is '"..shipTypeName.."' a valid target type for "..class.Name.." ?")

	if (type(class.TargetType) == 'table') then
		for i, typeName in pairs(class.TargetType) do
			dPrint_ability("\tTesting type "..typeName)
			if (shipTypeName == typeName) then
				return true
			end
		end
	else
		dPrint_ability("\tTesting type "..class.TargetType)
		if (shipTypeName == class.TargetType) then
				return true
		end
	end

	-- Default
	return false
end

--[[
	Instanciates the specified ability for the specified ship.

	@param className : ability name
	@param shipName : ship to attach the ability to
	@param isManuallyFired : true if the ability must be fired manually
]]
function ability_attachAbility(className, shipName, isManuallyFired)
	local instanceId = shipName.."::"..className
	dPrint_ability("Attaching ability : "..instanceId.." (manual fire = "..getValueAsString(isManuallyFired)..")")
	local instance = ability_createInstance(instanceId, className, shipName)

	-- Tie instance to ship
	if (ability_ships[shipName] == nil) then
		ability_ships[shipName] = {}
	end
	ability_ships[shipName][instanceId] = instance

	instance.Manual = isManuallyFired
end

--[[
	Looks for a target in range that instanceId can fire at.

	@param instanceId : instance to look a target for
	@return ship handle or nil
]]
function ability_getTargetInRange(instanceId)
	local instance = ability_instances[instanceId]
	local class = ability_classes[instance.Class]
	local castingShip = mn.Ships[instance.Ship]

	if (castingShip:isValid()) then
		dPrint_ability("Looking for target in range of "..instanceId)

		local ships = #mn.Ships
		local fittestShip = nil
		local fitness = -1

		-- If there's only one possible target
		if (class.TargetSelection == "Current Target") then
			fittestShip = castingShip.Target
		elseif (class.TargetSelection == "Self") then
			fittestShip = castingShip

		-- If we need to pick a target
		else
			-- Iterate through every ship in mission
			-- TODO : iterate through other object types?
			for index = 1, ships do
				local currentShip = mn.Ships[index]

				-- Exclude self for target selection
				if not (currentShip.Name == castingShip.Name) and (ability_canBeFiredAt(instanceId, currentShip.Name)) then
					-- Test target fitness
					local currentFitness = ability_evaluateTargetFitness(instanceId, currentShip)

					-- Lower values = target is better
					if ((currentFitness < fitness) or (fitness == -1)) then
						fitness = currentFitness
						fittestShip = currentShip
					end

				end
			end
		end

		return fittestShip
	end

	return nil
end


--[[
	Evaluates a target's fitness. Lower values = better targets

	@param instanceId : instance to look a target for
	@param targetShip : ship handle
	@return fitness value
]]
function ability_evaluateTargetFitness(instanceId, targetShip)
	local instance = ability_instances[instanceId]
	local class = ability_classes[instance.Class]
	local firingShip = mn.Ships[instance.Ship]

	local fitness = -1
	-- Fitness scheme : closest (default)
	dPrint_ability("Evaluating fitness scheme : "..class.TargetSelection.." for target "..targetShip.Name)
	if (class.TargetSelection == nil) or (class.TargetSelection == "Closest") then
		fitness = firingShip.Position:getDistance(targetShip.Position)

	-- Fitness scheme : random
	elseif (class.TargetSelection == "Random") then
		fitness = math.random(100)
	end

	dPrint_ability("\tFitness = "..fitness)
	return fitness

end

------------
--- main ---
------------
--[[
	Main function, initiates ability class parsing
]]
function ability_init()
	abilityTable = TableObject:create("abilities.tbl")

	dPrint_ability(abilityTable:toString())

	-- Create abilities
	for name, entry in pairs(abilityTable.Categories['Abilities'].Entries) do
		ability_createClass(name, entry)
	end

	-- Create buffs
	for name, entry in pairs(abilityTable.Categories['Buffs'].Entries) do
		buff_createClass(name, entry)
	end
end

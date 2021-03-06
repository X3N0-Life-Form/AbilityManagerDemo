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
ability_instancesWithAutoReload = {}
ability_ships = {}
ability_lastCast = 0

buff_classes = {}
buff_instances = {}

caster_weapons = {}

------------------------
--- Global Constants ---
------------------------
-- set to true to enable prints
ability_enableDebugPrints = true
ability_debugPrintQuietMode = true
ability_displayPlayerAbilities = true
ability_displayMissionAbilities = false

ability_castInterval = 0.05

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
	if (class.StartingReserve == -1) then
		instance.Ammo = instance.Ammo + 1
	else
		instance.Ammo = class.StartingReserve
	end
end

-- TODO : doc
function ability_autoReload()
	local missionTime = mn.getMissionTime()
	for instanceId, instance in pairs(ability_instancesWithAutoReload) do
		local class = ability_classes[instance.Class]
		dPrintQuiet_ability("Beginning auto-reload for "..instanceId)
		local reloadWait = getValueForDifficulty(class.ReloadWait)
		local reloadInterval = class.ReloadInterval
		local reloadAmmount = class.ReloadAmmount
		local startingReserve = getValueForDifficulty(class.StartingReserve)
		dPrintQuiet_ability("\tstartingReserve = "..startingReserve)
		dPrintQuiet_ability("\tinstance.Ammo = "..instance.Ammo)

		-- If we need to reload
		if (instance.Ammo < startingReserve) then
			dPrintQuiet_ability("\tWe need to reload")
			-- If we can reload
			if ((instance.LastFired == -1) or (instance.LastFired + reloadWait <= missionTime)) then
				dPrintQuiet_ability("\tReload wait OK")
				if ((instance.LastReload == -1) or (instance.LastReload + reloadInterval <= missionTime)) then
					dPrintQuiet_ability("\tReload interval OK, reloading "..reloadAmmount.." units")
					instance.Ammo = instance.Ammo + reloadAmmount

					-- Don't overflow
					if (instance.Ammo > startingReserve) then
						instance.Ammo = startingReserve
					end
				end
			end
		end
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

	-- Apply over-time effects
	buff_fireAllPossible()

	-- Auto reload abilities
	ability_autoReload()

	-- Print ability instances
	gr.setColor(255,255,255)
	if (ability_displayMissionAbilities) then
		gr.drawString("Instanciated abilities:", gr.getScreenWidth() * 0.01, gr.getScreenHeight() * 0.15)
		for instanceId, instance in pairs(ability_instances) do
			gr.drawString("\t"..instance:toString())
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
	Fires the specified ability, even if it doesn't have an instance, such as when
	triggered by a caster weapon.

	@param className : ability class
	@param casterName : name of the casting ship
	@param targetName : name of the target ship
]]
function ability_fireCast(className, casterName, targetName)
	local instanceId = ability_getInstanceId(casterName, className)
	-- Create a temporary instance if necessary
	local temporaryInstance = nil
	if (ability_instances[instanceId] == nil) then
		dPrint_ability("Creating temporary instance "..instanceId)
		temporaryInstance = AbilityInstance:create(instanceId, className, casterName)
	end

	-- Fire the ability
	ability_fire(instanceId, targetName)

	-- Cleanup
	if (temporaryInstance ~= nil) then
		dPrint_ability("Cleaning up temporary instance "..instanceId)
		ability_instances[instanceId] = nil
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
	buff_applyAbilityBuffs(class, targetName)

	-- Fire sound effect
	if (class.CastingSound ~= nil) then
		playSoundAtPosition(class.CastingSound, mn.Ships[targetName].Position)
	end

	--TODO : vfx, cf.buff

	-- Update instance status
	instance.LastFired = mn.getMissionTime()

	-- Apply cost
	ability_calculateCost(instance, class, true)

	dPrint_ability("Instance new status :")
	dPrint_ability(instance:toString())
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
	dPrintQuiet_ability("Fire all possible instances !")

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
			dPrintQuiet_ability(instanceId.." must be triggered manually")
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
	Prints only if quiet mode is set to false
]]
function dPrintQuiet_ability(message)
	if (ability_debugPrintQuietMode == false) then
		dPrint_ability(message)
	end
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

----------------------
--- Core Functions ---
----------------------


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
		if (shipTypeName == class.TargetType) or (class.TargetType == 'any') then
				return true
		end
	end

	-- Default
	return false
end

--[[
	Returns an instance id for the specified ship/ability pair
]]
function ability_getInstanceId(shipName, className)
	return shipName.."::"..className
end

--[[
	Instanciates the specified ability for the specified ship.

	@param className : ability name
	@param shipName : ship to attach the ability to
	@param isManuallyFired : true if the ability must be fired manually
]]
function ability_attachAbility(className, shipName, isManuallyFired)
	local instanceId = ability_getInstanceId(shipName, className)
	dPrint_ability("Attaching ability : "..instanceId.." (manual fire = "..getValueAsString(isManuallyFired)..")")
	local instance = AbilityInstance:create(instanceId, className, shipName)

	-- Tie instance to ship
	if (ability_ships[shipName] == nil) then
		ability_ships[shipName] = {}
	end
	ability_ships[shipName][instanceId] = instance

	instance.Manual = isManuallyFired

	local abilityClass = ability_classes[className]
	-- Add to the auto-reload index
	if (abilityClass.ReloadType == 'auto') then
		ability_instancesWithAutoReload[instanceId] = instance
	end

	-- Apply any passive buff
	for index, buffClassName in pairs(abilityClass.PassiveBuffs) do
		buff_applyBuff(buffClassName, shipName)
	end
end

--[[
	Returns the instance id from the specified ship/class couple

	@return shipName::className
]]
function ability_getInstanceId(shipName, className)
	return shipName.."::"..className
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


--[[
	Resets the instance array. Should be called $On Gameplay Start.
]]
function ability_resetMissionVariables()
	ability_instances = {}
	ability_ships = {}
	ability_lastCast = 0
	buff_instances = {}
	buff_ships = {}
	caster_beamTracking = {}
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
		AbilityClass:createClass(name, entry)
	end

	-- Create buffs
	for name, entry in pairs(abilityTable.Categories['Buffs'].Entries) do
		buff_createClass(name, entry)
	end

	-- Create caster weapons (buff placers)
	for name, entry in pairs(abilityTable.Categories['Caster Weapons'].Entries) do
		CasterWeapon:createCasterWeapon(name, entry)
	end
end

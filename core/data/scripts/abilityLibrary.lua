--[[
	-----------------------
	--- Ability Library ---
	-----------------------

	This file contains various functions for the ability manager framework.

	Currently, the functions are required to follow the following signature :
		* functionName(instance, class, targetName)
]]

------------------------
--- Global Constants ---
------------------------
-- set to true to enable prints
abilityLibrary_enableDebugPrints = true


-------------------------
--- Utility Functions ---
-------------------------

function dPrint_abilityLibrary(message)
	if (abilityLibrary_enableDebugPrints) then
		ba.print("[abilityLibrary.lua] "..message.."\n")
	end
end


-------------------------
--- Library Functions ---
-------------------------

--[[
	Calls a SSM strike.
]]
function fireSSM(instance, class, targetName)
	local castingShip = mn.Ships[instance.Ship]
	local strikeType = Attribute:getValue(class.getData['Strike Type'], "None")
	local strikeTeam = castingShip.Team.Name

	-- Call SSM
	if (type(strikeType) == 'table') then
		for index, currentStrikeType in pairs(strikeType) do
			mn.evaluateSEXP("(when (true) (call-ssm-strike \""..currentStrikeType.."\" \""..strikeTeam.."\" \""..targetName.."\"))")
		end
	else
		mn.evaluateSEXP("(when (true) (call-ssm-strike \""..strikeType.."\" \""..strikeTeam.."\" \""..targetName.."\"))")
	end
end

--[[
	Drains energy from the target.
]]
function fireEnergyDrain(instance, class, targetName)
	local castingShip = mn.Ships[instance.Ship]
	local targetShip = mn.Ships[targetName]

	local weaponDrain = Attribute:getValue(class.AbilityData['Weapon drain'], 0)
	local afterburnerDrain = Attribute:getValue(class.AbilityData['Afterburner drain'], 0)
	local shieldDrain = Attribute:getValue(class.AbilityData['Shield drain'], 0)

	dPrint_abilityLibrary("Fire Energy Drain at "..targetName)
	dPrint_abilityLibrary("\tWeapon drain = "..getValueAsString(weaponDrain))
	dPrint_abilityLibrary("\tAfterburner drain = "..getValueAsString(afterburnerDrain))
	dPrint_abilityLibrary("\tShield drain = "..getValueAsString(shieldDrain))

	dPrint_abilityLibrary("Target status before : ")
	dPrint_abilityLibrary("WeaponEnergyLeft = "..targetShip.WeaponEnergyLeft)
	dPrint_abilityLibrary("AfterburnerFuelLeft = "..targetShip.AfterburnerFuelLeft)
	dPrint_abilityLibrary("Shields.CombinedLeft = "..targetShip.Shields.CombinedLeft)

	-- Apply drain
	targetShip.WeaponEnergyLeft = targetShip.WeaponEnergyLeft - weaponDrain
	targetShip.AfterburnerFuelLeft = targetShip.AfterburnerFuelLeft - afterburnerDrain
	targetShip.Shields.CombinedLeft = targetShip.Shields.CombinedLeft - shieldDrain

	dPrint_abilityLibrary("Target status after : ")
	dPrint_abilityLibrary("WeaponEnergyLeft = "..targetShip.WeaponEnergyLeft)
	dPrint_abilityLibrary("AfterburnerFuelLeft = "..targetShip.AfterburnerFuelLeft)
	dPrint_abilityLibrary("Shields.CombinedLeft = "..targetShip.Shields.CombinedLeft)
end


--[[
	Repairs/recharges the target ship
]]
function fireRepair(instance, class, targetName)
	local castingShip = mn.Ships[instance.Ship]
	local targetShip = mn.Ships[targetName]

	local hits = Attribute:getValue(class.getData['Hull'], 0)
	local shields = Attribute:getValue(class.getData['Shields'], 0)
	local weapons = Attribute:getValue(class.getData['Weapons'], 0)
	local afterburners = Attribute:getValue(class.getData['Afterburners'], 0)

	-- Note : don't repair things if they are dying
	if not (hits == nil) and not (targetShip.HitpointsLeft <= 0) then
		targetShip.HitpointsLeft = targetShip.HitpointsLeft + hits
		-- Make sure we don't go above 100%
		if (targetShip.HitpointsLeft > targetShip.HitpointsMax) then
			targetShip.HitpointsLeft = targetShip.HitpointsMax
		end
	end

	if not (shields == nil) then
		targetShip.Shields.CombinedLeft = targetShip.Shields.CombinedLeft + shields
	end

	if not (weapons == nil) then
		targetShip.WeaponEnergyLeft = targetShip.WeaponEnergyLeft + weapons
	end

	if not (afterburners == nil) then
		targetShip.AfterburnerFuelLeft = targetShip.AfterburnerFuelLeft + afterburners
	end
end

--[[
	Upgrades the target's armor class
]]
function fireBuffArmor(instance, class, targetName)
	local armorHierarchy = Attribute:getValue(class.getData['Armor Hierarchy'], "None") --TODO : OOP
	local targetShip = mn.Ships[targetName]
	local targetArmor = targetShip.ArmorClass
	dPrint_abilityLibrary("Fire buffArmor at "..targetName)
	dPrint_abilityLibrary("Target current armor = "..targetArmor)
	dPrint_abilityLibrary("Armor Hierarchy = "..getValueAsString(armorHierarchy))

	-- Go through the hierarchy
	for index, currentArmor in pairs(armorHierarchy) do
		-- Identify our current armor value
		dPrint_abilityLibrary(targetArmor.." <=> "..currentArmor.." ?")
		-- And verify that it's not the top armor class
		if (targetArmor == currentArmor) and (index < #armorHierarchy) then
			dPrint_abilityLibrary("Upgrading armor class to  "..getValueAsString(armorHierarchy[index + 1]))
			targetShip.ArmorClass = armorHierarchy[index + 1]
			return;
		end
	end

	dPrint_abilityLibrary("Could not buff armor "..targetArmor)
end

--[[
	Downgrades the target's armor class
]]
function fireDebuffArmor(instance, class, targetName)
	local armorHierarchy = Attribute:getValue(class.getData['Armor Hierarchy'], "None")
	local targetShip = mn.Ships[targetName]
	local targetArmor = targetShip.ArmorClass
	dPrint_abilityLibrary("Fire debuffArmor at "..targetName)
	dPrint_abilityLibrary("Target current armor = "..targetArmor)
	dPrint_abilityLibrary("Armor Hierarchy = "..getValueAsString(armorHierarchy))

	-- Go through the hierarchy
	for index, currentArmor in pairs(armorHierarchy) do
		-- Identify our current armor value
		dPrint_abilityLibrary(targetArmor.." <=> "..currentArmor.." ?")
		-- And verify that it's not the top armor class
		if (targetArmor == currentArmor) and (index > 0) then
			dPrint_abilityLibrary("Downgrading armor class to  "..getValueAsString(armorHierarchy[index + 1]))
			targetShip.ArmorClass = armorHierarchy[index - 1]
			return;
		end
	end

	dPrint_abilityLibrary("Could not debuff armor "..targetArmor)
end


--[[
	Clones the target
]]
function fireClone(instance, class, targetName)
	dPrint_abilityLibrary("KAGE BUNSHIN NO JUTSU !!!")
	local cloneArmor = class.getData['Clone Armor'].Value
	local cloneNumber = class.getData['Clone Number'].Value
	local maxRadius = class.getData['Max Radius'].Value
	local cloneBuff = class.getData['Clone Buff'].Value

	-- Get target info
	local targetShip = mn.Ships[targetName]
	local shipClass = targetShip.Class.Name

	for index = 1, cloneNumber do
		-- NOTE : This code assumes there are no existing clones !
		--				Beware that things might break if you try to create new clones while one already exists
		local cloneName = targetName.."#"..index
		local clonePosition = getClonePosition(targetShip, maxRadius)

		dPrint_abilityLibrary("Creating clone "..cloneName.." at position ("..clonePosition['x']..','..clonePosition['y']..','..clonePosition['z']..")")
		-- Creating the clone
		mn.evaluateSEXP([[
			(when
				(true)
				(ship-create
					"]]..cloneName..[["
					"]]..shipClass..[["
					]]..clonePosition['x']..[[
					]]..clonePosition['y']..[[
					]]..clonePosition['z']..[[
					]]..targetShip.Orientation['p']..[[
					]]..targetShip.Orientation['b']..[[
					]]..targetShip.Orientation['h']..[[
				)
			)
		]])

		-- Setting armor class
		mn.Ships[cloneName].ArmorClass = cloneArmor
		mn.Ships[cloneName].ShieldArmorClass = cloneArmor

		-- Copy damage + weapons
		mn.evaluateSEXP([[
			(when
				(true)
				(ship-copy-damage
					"]]..targetName..[["
					"]]..cloneName..[["
				)
			)
		]])
		copyWeapons(targetName, cloneName)

		-- TODO : give orders : attack hostile, guard target or escort caster

		-- Apply buff
		buff_applyBuff(cloneBuff, cloneName)
	end

end

--[[
	Get a valid position for a clone of the specified ship

	@param targetShip : valid ship handle
	@param radiusFactor : max radius factor
]]
function getClonePosition(targetShip, maxRadiusFactor)
	local originalPosition = targetShip.Position
	local modelInfo = targetShip.Class.Model
	local maxRadiusValue = modelInfo.Radius * maxRadiusFactor
	-- Randomize clone position
	local x = originalPosition['x'] + math.random(modelInfo.Radius, maxRadiusValue) * (math.random() < 0.5 and -1 or 1)
	local y = originalPosition['y'] + math.random(modelInfo.Radius, maxRadiusValue) * (math.random() < 0.5 and -1 or 1)
	local z = originalPosition['z'] + math.random(modelInfo.Radius, maxRadiusValue) * (math.random() < 0.5 and -1 or 1)

	return ba.createVector(x,y,z)
end

--[[
	"Poofs" the target
]]
function fireDeclone(instance, class, targetName)
	dPrint_abilityLibrary("Poofing clone "..targetName)
	mn.evaluateSEXP([[
		(when
			(true)
			(ship-vanish
				"]]..targetName..[["
			)
		)
	]])
end


trackedShips = {}
--[[
	Track a ship's state at a given time and stores it in a stack
]]
function fireTrack(instance, class, targetName)
	if (trackedShips[targetName] == nil) then
		local maxSize = class.getData['Track Size'].Value
		dPrint_abilityLibrary("Creating stack for "..targetName.." with max size = "..maxSize)
		trackedShips[targetName] = Stack:create(maxSize)
	end
	trackedShips[targetName]:stack(ShipInfo:create(targetName))
end

--[[
	Starts up the recall process : stops ship tracking and gets ready to send the target ship back in time
]]
function fireRecall(instance, class, targetName)
	dPrint_abilityLibrary("Performing recall on stack : "..trackedShips[targetName]:toString())
	buff_removeBuff(class.Name, targetName)
	-- Prevent ship from interacting with the outside world
	mn.evaluateSEXP([[
		(when
			(true)
			(alter-ship-flag "ship-protect" true true)
			(alter-ship-flag "invulnerable" true true)
			(add-goal "]]..targetName..[[" (ai-play-dead-persistent 120))
		)
	]])

	-- Set saturation level for player during recall + make the player use the AI
	if (targetName == hv.Player.Name and class.getData['Saturation Level'] ~= nil) then
		mn.evaluateSEXP([[
			(when
				(true)
				(set-post-effect
		      		"saturation"
		      		]]..class.getData['Saturation Level'].Value..[[
	   		)
				(player-use-ai)
			)
		]])
	end
end

--[[
	Core of the recall process : unstacks a ship info from the track stack and sets the ship to this status
]]
function fireBacktrack(instance, class, targetName)
	local trackInfo = trackedShips[targetName]:unstack()
	local ship = mn.Ships[targetName]
	if (trackInfo ~= nil and ship:isValid()) then
		trackInfo:setFsoInfo(ship)
	else
		dPrint_abilityLibrary("Missing backtrack info or ship object for "..targetName)
	end
end

--[[
	End of the recall process : restarts ship tracking restores the ship to normal status
]]
function fireTrackback(instance, class, targetName)
	-- Reapply track
	buff_applyBuff(class.getData['Track Buff'].Value, targetName)
	-- Restore interaction with the outside world
	mn.evaluateSEXP([[
		(when
			(true)
			(alter-ship-flag "ship-protect" false true)
			(alter-ship-flag "invulnerable" false true)
			(remove-goal "]]..targetName..[[" (ai-play-dead-persistent 120))
		)
	]])

	-- Restore saturation values for player + control
	if (targetName == hv.Player.Name) then
		mn.evaluateSEXP([[
			(when
				(true)
				(reset-post-effects)
				(player-not-use-ai)
			)
		]])
	end
end

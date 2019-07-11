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
	local strikeType = class.getData['Strike Type']
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

	dPrint_abilityLibrary("Fire Energy Drain at "..targetName)
	dPrint_abilityLibrary("\tWeapon drain = "..getValueAsString(class.AbilityData['Weapon drain']))
	dPrint_abilityLibrary("\tAfterburner drain = "..getValueAsString(class.AbilityData['Afterburner drain']))
	dPrint_abilityLibrary("\tShield drain = "..getValueAsString(class.AbilityData['Weapon drain']))

	dPrint_abilityLibrary("Target status before : ")
	dPrint_abilityLibrary("WeaponEnergyLeft = "..targetShip.WeaponEnergyLeft)
	dPrint_abilityLibrary("AfterburnerFuelLeft = "..targetShip.AfterburnerFuelLeft)
	dPrint_abilityLibrary("Shields.CombinedLeft = "..targetShip.Shields.CombinedLeft)

	-- Apply drain
	targetShip.WeaponEnergyLeft = targetShip.WeaponEnergyLeft - class.AbilityData['Shield drain']
	targetShip.AfterburnerFuelLeft = targetShip.AfterburnerFuelLeft - class.AbilityData['Afterburner drain']
	targetShip.Shields.CombinedLeft = targetShip.Shields.CombinedLeft - class.AbilityData['Shield drain']

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

	local hits = class.getData['Hull']
	local shields = class.getData['Shields']
	local weapons = class.getData['Weapons']
	local afterburners = class.getData['Afterburners']

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
	local armorHierarchy = class.getData['Armor Hierarchy']--TODO : OOP
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
	local armorHierarchy = class.getData['Armor Hierarchy']
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


end

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
	local strikeType = class.AbilityData['Strike Type']
	local strikeTeam = castingShip.Team.Name

	-- Call SSM
	mn.evaluateSEXP("(when (true) (call-ssm-strike \""..strikeType.."\" \""..strikeTeam.."\" \""..targetName.."\"))")
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
	
	local hits = class.AbilityData['Hull']
	local shields = class.AbilityData['Shields']
	local weapons = class.AbilityData['Weapons']
	local afterburners = class.AbilityData['Afterburners']

	if not (hits == nil) then
		targetShip.HitpointsLeft = targetShip.HitpointsLeft + hits
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


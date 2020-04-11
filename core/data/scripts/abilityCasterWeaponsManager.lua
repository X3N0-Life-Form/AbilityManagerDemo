--TODO : doc

------------------------
--- Global Variables ---
------------------------
caster_enableDebugPrints = true
caster_debugPrintQuietMode = false

------------------------
--- Global Variables ---
------------------------

-------------------------
--- Utility Functions ---
-------------------------

function dPrint_caster(message)
	if (caster_enableDebugPrints) then
		ba.print("[abilityCasterWeaponsManager.lua] "..message.."\n")
	end
end

--[[
	Prints only if quiet mode is set to false
]]
function dPrintQuiet_caster(message)
	if (caster_debugPrintQuietMode == false) then
		dPrint_caster(message)
	end
end

----------------------
--- Core functions ---
----------------------

function caster_cast(casterWeapon, abilities, buffs, parentShip, targetShip)
  -- Fire abilities (if any)
  dPrint_caster("Casting abilities from caster weapon'"..casterWeapon.Name.."'")
  for i = 1, #abilities do
    local ability = abilities[i]
    dPrint_caster("\t"..ability)
    ability_fireCast(ability, parentShip, targetShip)
  end

  -- Apply buffs (if any)
  dPrint_caster("Casting buffs from caster weapon'"..casterWeapon.Name.."'")
  for i = 1, #buffs do
    local buff = buffs[i]
    dPrint_caster("\t"..buff)
    buff_applyBuff(buff, targetShip)
  end
end

function caster_onWeaponFired()
  local weapon = hv.Weapon
	local weaponName = weapon.Class.Name
	local parentShip = weapon.Parent
  local casterWeapon = caster_weapons[weaponName]

  -- TODO : review the notion of target here !
  -- Caster weapon lookup OK
  if (casterWeapon ~= nil) then
    caster_cast(casterWeapon, casterWeapon.OnFireAbilities, casterWeapon.OnFireBuffs,
      parentShip, parentShip.Target)
  end
end

function caster_onWeaponHit()
  local weapon = hv.Weapon
	local weaponName = weapon.Class.Name
	local parentShip = weapon.Parent
  local targetShip = hv.Ship.Name
  local casterWeapon = caster_weapons[weaponName]

  -- Caster weapon lookup OK
  if (casterWeapon ~= nil) then
    caster_cast(casterWeapon, casterWeapon.OnHitAbilities, casterWeapon.OnHitBuffs,
      parentShip, targetShip)
  end
end

-- TODO : blast + shokwave

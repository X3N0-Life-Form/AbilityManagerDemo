--TODO : doc

------------------------
--- Global Constants ---
------------------------
caster_enableDebugPrints = true
caster_debugPrintQuietMode = false

------------------------
--- Global Variables ---
------------------------
caster_beamTracking = {}

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
  dPrint_caster("Casting abilities from caster weapon '"..casterWeapon.Name.."'")
  for i = 1, #abilities do
    local ability = abilities[i]
    dPrint_caster("\t"..ability)
    ability_fireCast(ability, parentShip, targetShip)
  end

  -- Apply buffs (if any)
  dPrint_caster("Casting buffs from caster weapon '"..casterWeapon.Name.."'")
  for i = 1, #buffs do
    local buff = buffs[i]
    dPrint_caster("\t"..buff)
    buff_applyBuff(buff, targetShip)
  end
end

function caster_onWeaponFired()
  local weapon = hv.Weapon
	local weaponName = weapon.Class.Name
	local parentShip = weapon.Parent.Name
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
	local parentShip = weapon.Parent.Name
  local targetShip = hv.Ship.Name
  local casterWeapon = caster_weapons[weaponName]

  -- Caster weapon lookup OK
  if (casterWeapon ~= nil) then
    caster_cast(casterWeapon, casterWeapon.OnHitAbilities, casterWeapon.OnHitBuffs,
      parentShip, targetShip)
  end
end

function caster_onBeamHit()
  local beam = hv.Beam
	local beamName = beam.Class.Name
  local beamId = beam:getSignature()

  -- Careful when dealing with parent-less weapons
  local parentShip = "None:"..mn.getMissionTime()
  local parentTurret = "None"
  if (beam.Parent:getBreedName() == 'Ship') then
    parentShip = beam.Parent.Name
    parentTurret = beam.ParentSubsystem
  end

  local targetShip = hv.Ship.Name
  local casterWeapon = caster_weapons[beamName]

  -- Caster weapon lookup OK
  if (casterWeapon ~= nil) then
    -- Cast if not once per hit or isn't on the tracking list
    if (casterWeapon.OnHitOncePerBeam == false or caster_beamTracking[beamId] == nil) then
      caster_cast(casterWeapon, casterWeapon.OnHitAbilities, casterWeapon.OnHitBuffs,
        parentShip, targetShip)

      -- Record that we already casted for this beam
      if (casterWeapon.OnHitOncePerBeam == true and caster_beamTracking[beamId] == nil) then
        dPrint_caster("Casted once for beam id="..beamId)
        caster_beamTracking[beamId] = beam
      end
    end
  end
end

-- TODO : blast + shokwave

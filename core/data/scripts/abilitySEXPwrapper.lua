--[[
      SEXP wrappers for ability & buff functions.
      Should be called on game init.
]]



mn.LuaSEXPs["amf-ability-trigger"].Action = function (ship, className)
	local instanceId = ability_getInstanceId(ship.Name, className)
	ability_trigger(instanceId)
end


mn.LuaSEXPs["amf-ability-fire"].Action = function (ship, className, target, onlyIfPossible)
  local instanceId = ability_getInstanceId(ship.Name, className)
	-- Note : ability_fireIfPossible doesn't make much sense in an instance-less context
	-- (So far anyway)
  if (onlyIfPossible) then
    ability_fireIfPossible(instanceId, target.Name)
	elseif (ability_instances[instanceId] == nil) then
		-- If the FREDer didn't set an instance, fire anyway
		ability_fireCast(ship.Name, className, target.Name)
  else
    ability_fire(instanceId, target.Name)
  end
end


mn.LuaSEXPs["amf-ability-reload"].Action = function (ship, className)
	local instanceId = ability_getInstanceId(ship.Name, className)
  ability_reload(instanceId)
end


mn.LuaSEXPs["amf-ability-attach"].Action = function (className, ship, isManuallyFired)
  ability_attachAbility(className, ship.Name, isManuallyFired)
end

mn.LuaSEXPs["amf-buff-apply"].Action = function (buffClassName, target)
  buff_applyBuff(buffClassName, target.Name)
end

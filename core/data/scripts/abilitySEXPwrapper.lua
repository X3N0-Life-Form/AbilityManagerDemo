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
  if (onlyIfPossible) then
    ability_fireIfPossible(instanceId, target.Name)
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

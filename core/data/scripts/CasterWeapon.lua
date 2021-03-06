-- TODO : doc

CasterWeapon = {
  Name = "",
  OnFireAbilities = {},
  OnFireBuffs = {},
  OnHitAbilities = {},
	OnHitBuffs = {},
  OnHitOncePerBeam = true,
  OnBlastAbilities = {},
	OnBlastBuffs = {},
  OnShockwaveAbilities = {},
  OnShockwaveBuffs = {}
}

--[[
	Creates a class of the specified name and attributes

	@param name : class name
	@param entry : table Entry
]]
function CasterWeapon:createCasterWeapon(name, entry)
  dPrint_caster("Creating ability class : "..name)
  -- Initialize the class
  local casterWeapon = {}
  setmetatable(casterWeapon, self)
  self.__index = self
  caster_weapons[name] = casterWeapon

  -- Fill in default values
  casterWeapon.Name = name

  -- Set parsed values
  local baby = entry.Attributes['On Fire']
  if (baby ~= nil) then
    casterWeapon.OnFireAbilities = CasterWeapon:getAbilities(baby)
    casterWeapon.OnFireBuffs = CasterWeapon:getBuffs(baby)
  end

  local hit = entry.Attributes['On Hit']
  if (hit ~= nil) then
    casterWeapon.OnHitAbilities = CasterWeapon:getAbilities(hit)
    casterWeapon.OnHitBuffs = CasterWeapon:getBuffs(hit)
    if (hit.SubAttributes['Once per Beam'] ~= nil) then
      casterWeapon.OnHitOncePerBeam = getValueAsBoolean(hit.SubAttributes['Once per Beam'].Value)
    end
  end

  local blast = entry.Attributes['On Blast']
  if (blast ~= nil) then
    casterWeapon.OnBlastAbilities = CasterWeapon:getAbilities(blast)
    casterWeapon.OnBlastBuffs = CasterWeapon:getBuffs(blast)
  end

  local wave = entry.Attributes['On Shockwave']
  if (wave ~= nil) then
    casterWeapon.OnShockwaveAbilities = CasterWeapon:getAbilities(wave)
    casterWeapon.OnShockwaveBuffs = CasterWeapon:getBuffs(wave)
  end

  return casterWeapon
end

function CasterWeapon:getAbilities(attribute)
  if (attribute.SubAttributes['Abilities'] ~= nil) then
    return getValueAsTable(attribute.SubAttributes['Abilities'].Value)
  else
    return {}
  end
end

function CasterWeapon:getBuffs(attribute)
  if (attribute.SubAttributes['Buffs'] ~= nil) then
    return getValueAsTable(attribute.SubAttributes['Buffs'].Value)
  else
    return {}
  end
end



function CasterWeapon:toString()
  return "Caster Weapon:\t"..self.Name.."\n"
    .."\tOnFireAbilities = "..getValueAsString(self.OnFireAbilities).."\n"
    .."\tOnFireBuffs = "..getValueAsString(self.OnFireBuffs).."\n"
    .."\tOnHitAbilities = "..getValueAsString(self.OnHitAbilities).."\n"
    .."\tOnHitBuffs = "..getValueAsString(self.OnHitBuffs).."\n"
    .."\tOnHitOncePerBeam = "..getValueAsString(self.OnHitOncePerBeam).."\n"
    .."\tOnBlastAbilities = "..getValueAsString(self.OnBlastAbilities).."\n"
    .."\tOnBlastBuffs = "..getValueAsString(self.OnBlastBuffs).."\n"
    .."\tOnShockwaveAbilities = "..getValueAsString(self.OnShockwaveAbilities).."\n"
    .."\tOnShockwaveBuffs = "..getValueAsString(self.OnShockwaveBuffs).."\n"
end

-- TODO : doc

------------------------
--- Global Variables ---
------------------------

autoreload_table = {}
autoreload_banks = {}

------------------------
--- Global Constants ---
------------------------

autoreload_enableDebugPrints = true

-------------------------
--- Utility Functions ---
-------------------------
--[[
  Debug print
]]
function dPrint_autoreload(message)
	if (tests_enableDebugPrints) then
		ba.print("[autoreload.lua] "..message.."\n")
	end
end

----------------------
--- Core Functions ---
----------------------

function autoreload_cycle()
  dPrint_autoreload("Beginning weapon auto-reload cycle")--
  for bankTag, weaponBank in pairs(autoreload_banks) do
    dPrint_autoreload("Checking bank "..bankTag)
    -- If we need to reload
		if (weaponBank.AmmoLeft < weaponBank.AmmoMax) then
			dPrint_autoreload("\tWe need to reload")
      local weaponName = weaponBank.WeaponClass.Name
      local entry = autoreload_getEntry(weaponName)
      local reloadWait = entry.Attributes['Reload Wait'].Value +1-1
			-- If we can reload
			--if ((instance.LastFired == -1) or (instance.LastFired + reloadWait <= missionTime)) then
      -- TODO : reload start sound
				dPrint_autoreload("\tReload wait OK")
				--if ((instance.LastReload == -1) or (instance.LastReload + reloadInterval <= missionTime)) then
          local reloadAmmount = entry.Attributes['Reload Ammount'].Value +1-1
					dPrint_autoreload("\tReload interval OK, reloading "..reloadAmmount.." units")
					weaponBank.AmmoLeft = weaponBank.AmmoLeft + reloadAmmount

					-- Don't overflow
					if (weaponBank.AmmoLeft >= weaponBank.AmmoMax) then
						weaponBank.AmmoLeft = weaponBank.AmmoMax
            -- TODO : play finished sound
            -- TODO : Note : the ship is in the bank tag !!!
					end
				--end
			--end
			end
  end
end

--[[
  Initializes the data structures necessary for auto-reloading
]]
function autoreload_missionInit()
  dPrint_autoreload("Initializing weapon autoreload...")
  -- Reset bank list
  autoreload_banks = {}

  -- Lookup ship with weapons that might need auto-reloading
  for index = 1, #mn.Ships do
    local ship = mn.Ships[index]
    dPrint_autoreload("Analyzing ship '"..ship.Name.."'")

    -- Lookup primaries
    autoreload_analyzeBanks(ship.PrimaryBanks, ship.Name..":PB:")
    -- Lookup secondaries
    autoreload_analyzeBanks(ship.SecondaryBanks, ship.Name..":SB:")
  end
  dPrint_autoreload("Weapon autoreload initialization complete")
end

--[[
  Checks if the specified bank contains a weapon that auto-reloads

  @param weaponBank : weapon bank
  @return true if the bank has an auto-reloading weapon
]]
function hasAutoreloadingWeapon(weaponBank)
  local weaponName = weaponBank.WeaponClass.Name
  local entry = autoreload_getEntry(weaponName)
  dPrint_autoreload("\tIs weapon '"..weaponName.."' auto-realoading ?")
  return entry ~= nil
end

--[[
  Analyzes a weapon bank and adds any auto-reloading it to the tracking list
  with the specified tag

  @param weaponBankType : ship.PrimaryBanks or ship.SecondaryBanks
  @param tagSignature : how the bank should be signed into the tracking list
]]
function autoreload_analyzeBanks(weaponBankType, tagSignature)
  for pIndex = 1, #weaponBankType do
    local weaponBank = weaponBankType[pIndex]
    if (hasAutoreloadingWeapon(weaponBank)) then
      local bankTag = tagSignature..pIndex
      dPrint_autoreload("\tTracking bank "..bankTag)
      autoreload_banks[bankTag] = weaponBank
    end
  end
end

--[[
  Returns the entry for the specified weapon name

  @param weaponName : weapon name
  @return Entry object or nil
]]
function autoreload_getEntry(weaponName)
  return autoreload_table.Categories['Autoreloading Weapons'].Entries[weaponName]
end

------------
--- Main ---
------------
autoreload_table = TableObject:create("autoreload.tbl")

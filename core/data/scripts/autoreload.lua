-- TODO : doc

------------------------
--- Global Variables ---
------------------------

autoreload_table = {}
-- TODO : object instance stuff
autoreload_banks = {}
autoreload_lastFired = {}
autoreload_lastReload = {}

------------------------
--- Global Constants ---
------------------------

AUTORELOAD_PBANK_TAG = ":PB:"
AUTORELOAD_SBANK_TAG = ":SB:"

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
  dPrint_autoreload("Beginning weapon auto-reload cycle")
	local missionTime = mn.getMissionTime()
  for bankTag, weaponBank in pairs(autoreload_banks) do
    dPrint_autoreload("Checking bank "..bankTag)
    -- If we need to reload
		if (weaponBank.AmmoLeft < weaponBank.AmmoMax) then
			dPrint_autoreload("\tWe need to reload")
      local weaponName = weaponBank.WeaponClass.Name
      local entry = autoreload_getEntry(weaponName)
			local sounds = entry.Attributes['Reload Sounds'].SubAttributes
      local reloadWait = entry.Attributes['Reload Wait'].Value +1-1
			local reloadInterval = entry.Attributes['Reload Interval'].Value +1-1
			local lastFired = autoreload_lastFired[bankTag]
			local lastReload = autoreload_lastReload[bankTag]

			-- If we can reload
			if ((lastFired == -1) or (lastFired + reloadWait <= missionTime)) then
				dPrint_autoreload("\tReload wait OK")
				-- If we're past the reload interval
				if ((lastReload == -1) or (lastReload + reloadInterval <= missionTime)) then
          local reloadAmmount = entry.Attributes['Reload Ammount'].Value +1-1
					dPrint_autoreload("\tReload interval OK, reloading "..reloadAmmount.." units")
					weaponBank.AmmoLeft = weaponBank.AmmoLeft + reloadAmmount
					-- Update reload timer
					lastReload = missionTime
					-- Handle reloading sound
					if (lastReload == -1) then
						playSoundAtPosition(sounds['Start'].Value)
						-- TODO : lock weapons if necessary
					else
						playSoundAtPosition(sounds['Tick'].Value)
					end

					-- Don't overflow, reset lastReload + play end sound
					if (weaponBank.AmmoLeft >= weaponBank.AmmoMax) then
						weaponBank.AmmoLeft = weaponBank.AmmoMax
            playSoundAtPosition(sounds['End'].Value)
						lastReload = -1
					end
				end
			end

			-- Update lastReload entry
			autoreload_lastReload[bankTag] = lastReload
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
    autoreload_analyzeBanks(ship.PrimaryBanks, ship.Name..AUTORELOAD_PBANK_TAG, true)
    -- Lookup secondaries
    autoreload_analyzeBanks(ship.SecondaryBanks, ship.Name..AUTORELOAD_SBANK_TAG, true)
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
  Analyzes a weapon bank and adds any auto-reloading it to the tracking lists
  with the specified tag if set to 'initialize'

  @param weaponBankType : ship.PrimaryBanks or ship.SecondaryBanks
  @param tagSignature : how the bank should be signed into the tracking lists
	@param initialize : set to true to initialize the relevant tracking lists
	@return array of bank tags
]]
function autoreload_analyzeBanks(weaponBankType, tagSignature, initialize)
	local bankTags = {}
  for index = 1, #weaponBankType do
    local weaponBank = weaponBankType[index]
    if (hasAutoreloadingWeapon(weaponBank)) then
      local bankTag = tagSignature..index
			bankTags[index] = bankTag
			-- If we need to initialize
			if (initialize) then
				dPrint_autoreload("\tTracking bank "..bankTag)
	      autoreload_banks[bankTag] = weaponBank
				autoreload_lastFired[bankTag] = -1
				autoreload_lastReload[bankTag] = -1
			end
    end
  end
	return bankTags
end

--[[
  Returns the entry for the specified weapon name

  @param weaponName : weapon name
  @return Entry object or nil
]]
function autoreload_getEntry(weaponName)
  return autoreload_table.Categories['Autoreloading Weapons'].Entries[weaponName]
end


--[[
	Detects which weapon has been fired and updates its lastFired value.
	Call $On Weapon Created
]]
function autoreload_weaponFired()
	local weapon = hv.Weapon
	local weaponName = weapon.Class.Name
	local parentShip = weapon.Parent
	local entry = autoreload_getEntry(weaponName)
	local missionTime = mn.getMissionTime()
	if (entry ~= nil) then
		dPrint_autoreload("Detected weapon '"..weaponName.."' being fired by "..parentShip.Name)
		local bankTags = autoreload_getBankTags(parentShip, weapon.Class)
		-- Setting last fired value for the relevant banks
		for tag, tagl in pairs(bankTags) do
			autoreload_lastFired[tag] = missionTime
		end
	end
end


--[[
	Retrieves the relevant bank tags for the specified weapon on this ship

	@param ship : ship to check
	@param weaponClass : weapon to check
	@return {tag = tag}
]]
function autoreload_getBankTags(ship, weaponClass)
	local combined = {}
	-- Lookup primaries
	local primaryTags = autoreload_analyzeBanks(ship.PrimaryBanks, ship.Name..AUTORELOAD_PBANK_TAG, false)
	for i = 1, #primaryTags do
		combined[primaryTags[i]] = primaryTags[i]
	end
	-- Lookup secondaries
	local secondaryTags = autoreload_analyzeBanks(ship.SecondaryBanks, ship.Name..AUTORELOAD_SBANK_TAG, false)
	for i = 1, #secondaryTags do
		combined[secondaryTags[i]] = secondaryTags[i]
	end

	return combined
end

------------
--- Main ---
------------
autoreload_table = TableObject:create("autoreload.tbl")


------------------------
--- Global Variables ---
------------------------
shipVariantMissions_enableDebugPrint = false

shipVariantMissionsTable = {}

---------------------------
--- functions - utility ---
---------------------------

function dPrint_shipVariantMissions(message)
	if (shipVariantMissions_enableDebugPrint) then
		ba.print("[shipVariantMissionWide.lua] "..message.."\n")
	end
end

----------------------
--- Core Functions ---
----------------------

--[[
	Sets ship variants for the entire mission
	
	@param categoryName name of the category in the table file
]]
function setShipVariants(categoryName)
	if not (shipVariantMissionsTable[categoryName] == nil) then
		dPrint_shipVariantMissions("Setting mission-wide variants using variant list "..categoryName)
		
		for shipName, attributes in pairs(shipVariantMissionsTable[categoryName]) do
			dPrint_shipVariantMissions("Setting up ship "..shipName)
		
			-- Set up variant
			if not (attributes['Variant'] == nil) then
				local variantName = attributes['Variant']['value']
				
				-- if this is a single ship
				if (attributes['Variant']['sub'] == nil) or (attributes['Variant']['sub']['Wing'] == nil) then
					dPrint_shipVariantMissions("\tSetting variant "..variantName.." for ship "..shipName)
					
					setVariant(shipName, variantName)
				else -- or if this is a wing
					dPrint_shipVariantMissions("\tSetting variant "..variantName.." for wing "..shipName)
					
					local wingSize = attributes['Variant']['sub']['Wing']
					for i = 1, i <= wingSize do
						setVariant(shipName.." "..i, variantName)
					end
				end
			end
			
			-- Set up mission-specific abilities
			if not (attributes['Abilities'] == nil) then
				dPrint_shipVariantMissions("\tSetting mission-specific abilities")
				
				local abilities = attributes['Abilities']['value']
				local manual = false
				if (not (attributes['Abilities']['sub'] == nil) and not (attributes['Abilities']['sub']['Manual'] == nil)) then
					manual = attributes['Abilities']['sub']['Manual']
				end
				
				if (type(abilities) == 'table') then
					for index, currentAbility in pairs(abilities) do
						if (type(manual) == 'table') then
							ability_attachAbility(currentAbility, shipName, manual[index])
						else
							ability_attachAbility(currentAbility, shipName, manual)
						end
					end
				else
					ability_attachAbility(abilities, shipName, manual)
				end
			end
			
		end
	else
		ba.warning("[shipVariantMissionWide.lua] Could not find entry "..categoryName)
	end
end

shipVariantMissionsTable = parseTableFile("data/config/", "ship_variants_mission_wide.tbl")
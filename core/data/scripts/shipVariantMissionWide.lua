
------------------------
--- Global Variables ---
------------------------
shipVariantMissions_enableDebugPrint = true

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
	if not (shipVariantMissionsTable.Categories[categoryName] == nil) then
		dPrint_shipVariantMissions("Setting mission-wide variants using variant list "..categoryName)

		for shipName, entry in pairs(shipVariantMissionsTable.Categories[categoryName].Entries) do
			dPrint_shipVariantMissions("Setting up ship "..shipName)

			-- Set up variant
			if not (entry.Attributes['Variant'] == nil) then
				local variantName = entry.Attributes['Variant'].Value
				local variantAttribute = entry.Attributes['Variant']

				-- if this is a single ship
				if (variantAttribute.SubAttributes == nil) or (variantAttribute.SubAttributes['Wing'] == nil) then
					dPrint_shipVariantMissions("\tSetting variant "..variantName.." for ship "..shipName)

					setVariant(shipName, variantName)
				else -- or if this is a wing
					dPrint_shipVariantMissions("\tSetting variant "..variantName.." for wing "..shipName)

					local wingSize = variantAttribute.SubAttributes['Wing']
					for i = 1, i <= wingSize do
						setVariant(shipName.." "..i, variantName)
					end
				end
			end

			-- Set up mission-specific abilities
			if not (entry.Attributes['Abilities'] == nil) then
				dPrint_shipVariantMissions("\tSetting mission-specific abilities")

				local abilities = entry.Attributes['Abilities'].Value
				local manual = false
				if (not (entry.Attributes['Abilities'].SubAttributes == nil) and not (entry.Attributes['Abilities'].SubAttributes['Manual'] == nil)) then
					manual = entry.Attributes['Abilities'].SubAttributes['Manual']
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

shipVariantMissionsTable = TableObject:create("ship_variants_mission_wide.tbl")

--[[
      SEXP wrappers for ship variant functions.
      Should be called on game init.
]]


mn.LuaSEXPs["shipVar-set-variant"].Action = function (ship, variantName)
  setVariant(ship.Name, variantName)
end

mn.LuaSEXPs["shipVar-set-all-variants"].Action = function (categoryName)
  setShipVariants(categoryName)
end

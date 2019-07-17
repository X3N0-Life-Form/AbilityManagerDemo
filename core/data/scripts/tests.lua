--[[
  Unit test file
]]
------------------------
--- Global Variables ---
------------------------
-- set to true to enable prints
tests_enableDebugPrints = true

--[[
  Debug print
]]
function dPrint_tests(message)
	if (tests_enableDebugPrints) then
		ba.print("[tests.lua] "..message.."\n")
	end
end

----------------------
--- Test Functions ---
----------------------

function gameInitTests()
  -- Test table parser
  dPrint_tests("Testing table parser")
  testTable = TableObject:create("abilities.tbl")
  dPrint_tests(testTable:toString())

end


gameInitTests()

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
	dPrint_tests("Stack test - creating")
  local stackTest = Stack:create(3)
	dPrint_tests("stacking...")
	stackTest:stack(4)
	stackTest:stack("wollolo")
	stackTest:stack("test")
	stackTest:stack("overflow")
	dPrint_tests(stackTest:toString())
	dPrint_tests("unstacking...")
	dPrint_tests("Unstacked "..getValueAsString(stackTest:unstack()))
	dPrint_tests("Unstacked "..getValueAsString(stackTest:unstack()))
	dPrint_tests("Unstacked "..getValueAsString(stackTest:unstack()))
	dPrint_tests(stackTest:toString())
	stackTest:stack("no longer overflow")
	dPrint_tests(stackTest:toString())
end

gameInitTests()

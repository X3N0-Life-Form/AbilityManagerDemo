--[[
  Stack structure
]]

Stack = {
  MaxSize = -1,
  CurrentSize = 0,
  StackTable = {}
}

--[[
  Creates a Stack of the specified size

  @param maxSize : maximum size of the stack
  @return Stack object
]]
function Stack:create(maxSize)
  -- Initialize the class
  local stackInstance = {}
  setmetatable(stackInstance, self)
  self.__index = self

  -- Initialize values
  stackInstance.MaxSize = tonumber(maxSize)

  -- Return instance
	return stackInstance
end

--[[
  Stacks an object on top of the Stack, and pushes out the oldest object if we are full.

  @param object : object to stack
]]
function Stack:stack(object)
  -- Check that we're not full
  if (self.CurrentSize >= self.MaxSize) then
    -- Push all object down
    for index = 1, self.MaxSize - 1 do
      self.StackTable[index] = self.StackTable[index + 1]
    end
    self.CurrentSize = self.MaxSize - 1
  end

  self.StackTable[self.CurrentSize + 1] = object
  self.CurrentSize = self.CurrentSize + 1
end

--[[
  Unstacks an object, removing it from the stack

  @return object previously on top of the stack, or nil if the stack is empty
]]
function Stack:unstack()
  if (self.CurrentSize == 0) then
    return nil
  else
    local object = self.StackTable[self.CurrentSize]
    self.CurrentSize = self.CurrentSize - 1
    return object
  end
end

--[[
  Returns object as a string

  @return string
]]
function Stack:toString()
  local stackString = "Stack: max size = "..self.MaxSize.."\n"
  for index = 1, self.CurrentSize do
    stackString = stackString.."\t"..index.." = "..getValueAsString(self.StackTable[index]).."\n"
  end
  return stackString
end

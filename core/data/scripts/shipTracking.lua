--[[
  Classes related to tracking ships
]]

TrackVector = {
  x = 0,
  y = 0,
  z = 0
}
function TrackVector:create(fsoVector)
  -- Initialize the class
  local vectorInstance = {}
  setmetatable(vectorInstance, self)
  self.__index = self

  -- Initialize values
  vectorInstance.x = fsoVector['x']
  vectorInstance.y = fsoVector['y']
  vectorInstance.z = fsoVector['z']

  -- Return instance
	return vectorInstance
end

function TrackVector:setFsoInfo(fsoVector)
	fsoVector['x'] = self.x
	fsoVector['y'] = self.y
	fsoVector['z'] = self.z
end


TrackOrientation = {
  p = 0,
  b = 0,
  h = 0
}
function TrackOrientation:create(fsoOrientation)
  -- Initialize the class
  local orientationInstance = {}
  setmetatable(orientationInstance, self)
  self.__index = self

  -- Initialize values
  orientationInstance.p = fsoOrientation['p']
  orientationInstance.b = fsoOrientation['b']
  orientationInstance.h = fsoOrientation['h']

  -- Return instance
	return orientationInstance
end

function TrackOrientation:setFsoInfo(fsoOrientation)
	fsoOrientation['p'] = self.p
	fsoOrientation['b'] = self.b
	fsoOrientation['h'] = self.h
end

ShipInfo = {
	Time = 0,

  Position = nil,
	Orientation = nil,
  Velocity = nil,
  RotationalVelocity = nil,

	Hitpoints = 0,
	Shields = 0,
  AfterburnerFuel = 0,
  WeaponEnergy = 0,
  Countermeasures = 0

  -- TODO : add weapon ammo
}

-- TODO doc
function ShipInfo:create(shipName)
  -- Initialize the class
  local shipInfoInstance = {}
  setmetatable(shipInfoInstance, self)
  self.__index = self

  -- Initialize values
  local ship = mn.Ships[shipName]
  shipInfoInstance.Time = mn.getMissionTime()

  shipInfoInstance.Position = TrackVector:create(ship.Position)
  shipInfoInstance.Orientation = TrackOrientation:create(ship.Orientation)
  shipInfoInstance.Velocity = TrackVector:create(ship.Physics.Velocity)
  shipInfoInstance.RotationalVelocity = TrackVector:create(ship.Physics.RotationalVelocity)

  shipInfoInstance.Hitpoints = ship.HitpointsLeft
  shipInfoInstance.Shields = ship.Shields.CombinedLeft
  shipInfoInstance.AfterburnerFuel = ship.AfterburnerFuelLeft
  shipInfoInstance.WeaponEnergy = ship.WeaponEnergyLeft
  shipInfoInstance.Countermeasures = ship.CountermeasuresLeft

  -- TODO : weapon banks
  -- Return instance
	return shipInfoInstance
end

--[[
	Sets the specified ship's status to that of the ShipInfo

	@param ship : ship to set
]]
function ShipInfo:setFsoInfo(ship)
	--self.Position:setFsoInfo(ship.Position)
  mn.evaluateSEXP([[
    (when
      (true)
      (set-object-position
        "]]..ship.Name..[["
        "]]..self.Position.x..[["
        "]]..self.Position.y..[["
        "]]..self.Position.z..[["
      )
    )
  ]])
	--self.Orientation:setFsoInfo(ship.Orientation)
  -- dPrint_abilityLibrary("Setting orientation : "..self.Orientation.p.." "..self.Orientation.b.." "..self.Orientation.h)
  mn.evaluateSEXP([[
    (when
      (true)
      (set-object-orientation
        "]]..ship.Name..[["
        "]]..convertRadToDegree(self.Orientation.p)..[["
        "]]..convertRadToDegree(self.Orientation.b)..[["
        "]]..convertRadToDegree(self.Orientation.h)..[["
      )
    )
  ]])
	-- self.Velocity:setFsoInfo(ship.Physics.Velocity)
  mn.evaluateSEXP([[
    (when (true) (set-object-speed-x "]]..ship.Name..[[" "]]..self.Velocity.x..[["))
    (when (true) (set-object-speed-y "]]..ship.Name..[[" "]]..self.Velocity.y..[["))
    (when (true) (set-object-speed-z "]]..ship.Name..[[" "]]..self.Velocity.z..[["))
  ]])
	-- self.RotationalVelocity:setFsoInfo(ship.Physics.RotationalVelocity)
  -- TODO : all of this

	ship.HitpointsLeft = self.Hitpoints
	ship.Shields.CombinedLeft = self.Shields
	ship.AfterburnerFuelLeft = self.AfterburnerFuel
	ship.WeaponEnergyLeft = self.WeaponEnergy
	ship.CountermeasuresLeft = self.Countermeasures
	-- TODO : weapon banks
end

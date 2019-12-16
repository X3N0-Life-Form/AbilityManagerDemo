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

  -- Return instance
	return shipInfoInstance
end

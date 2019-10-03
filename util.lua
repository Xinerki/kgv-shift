

function math.clamp(value, minClamp, maxClamp)
	return math.min(maxClamp, math.max(value, minClamp))
end

function getCameraPositionOffset(rotH, rotV, distance)
  local radH = math.rad(rotH)
  local radV = math.rad(rotV)

  local distanceXY = math.cos(radV) * distance

  local offsetX = math.sin(radH) * distanceXY
  local offsetY = math.cos(radH) * distanceXY
  local offsetZ = math.sin(radV) * distance

  return offsetX, offsetY, offsetZ
end

function GetVehicleSeatPedIsIn(ped, vehicle)
    for i=-1, GetVehicleMaxNumberOfPassengers(vehicle) do
        if ped == GetPedInVehicleSeat(vehicle, i) then 
            return i 
        end
    end
    return false
end

function translateAngle(x1, y1, ang, offset)
  x1 = x1 + math.sin(ang) * offset
  y1 = y1 + math.cos(ang) * offset
  return {x1, y1}
end
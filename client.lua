
freecamEnabled = false

function init()
	view1=CreateCam("DEFAULT_SCRIPTED_CAMERA", 1)
	SetCamCoord(view1, 10.5, 13.6, 75.3)
	SetCamRot(view1, 0.0, 0.0, 180.0)
	SetCamFov(view1, 20.0)
	pos = vector3(1.0, 1.0, 1.0)
	rotation = vector3(0.0, 0.0, 0.0)
end

_SetCamRot = SetCamRot
function SetCamRot(v, x, y, z)
    _SetCamRot(v, y, z, x)
end

chatInputActive = false
SetTimeScale(1.0)
SetGamePaused(false)

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

function toggleFreecam() -- MUST START THREAD
	freecamEnabled = not freecamEnabled

	if freecamEnabled == true then
		RenderScriptCams(true, 1, 1000,  true,  true)
		StartScreenEffect("SwitchShortFranklinMid", 500, false)
		PlaySound(-1, "slow", "SHORT_PLAYER_SWITCH_SOUND_SET", 0, 0, 1)
		pos = GetGameplayCamCoord()
		pos = vector3(pos.x, pos.y, pos.z+1.0)
		local rotx, roty, rotz = table.unpack(GetEntityRotation(PlayerPedId()))
		rotation = vector3(rotz+GetGameplayCamRelativeHeading(), GetGameplayCamRelativePitch()-10.0, 0.0)
		fov = 50.0
		roll = 0.0
		-- DisableAllControlActions(0)
		SetPlayerControl(PlayerId(), false, 0)
		TaskVehicleDriveWander(PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false), 10.0, 0)
		-- SetTimeScale(0.0)
	else
		RenderScriptCams(false, 1, 1000,  true,  true)
		StartScreenEffect("SwitchShortFranklinMid", 500, false)
		PlaySound(-1, "slow", "SHORT_PLAYER_SWITCH_SOUND_SET", 0, 0, 1)
		-- EnableAllControlActions(0)
		SetPlayerControl(PlayerId(), true, 0)
		ClearPedTasks(PlayerPedId())
		UnlockMinimapPosition()
		UnlockMinimapAngle(0.0)
		-- SetTimeScale(1.0)
	end
	-- FreezeEntityPosition(PlayerPedId(), freecamEnabled)
	Citizen.Wait(250)
	StopScreenEffect()
end

Citizen.CreateThread(function()
	while true do
		if IsDisabledControlJustPressed(1, 73) then
			Citizen.CreateThread(toggleFreecam)
		end
		
		-- SetGamePaused(freecamEnabled)

		Citizen.Wait(1)
	end
end)

function translateAngle(x1, y1, ang, offset)
  x1 = x1 + math.sin(ang) * offset
  y1 = y1 + math.cos(ang) * offset
  return {x1, y1}
end

fov = 50.0
roll = 0.0

function processFreecam()
	while true do 
		if freecamEnabled == true then
			local mouseX = GetDisabledControlNormal(0, 1) * 5 *(fov / 50.0)
			local mouseY = GetDisabledControlNormal(0, 2) * 5 *(fov / 50.0)
			rotation = vector3(rotation.x-mouseX, rotation.y-mouseY, 0)
			
			-- local ForwardMult = (rotation.y+90) / 180
			
			-- if ForwardMult < 0.0 then ForwardMult = 0.0 end
			-- if ForwardMult > 1.0 then ForwardMult = 1.0 end
		
			local ForwardControl = -GetDisabledControlNormal(0, 31)
			ForwardX, ForwardY = table.unpack(translateAngle(pos.x, pos.y, math.rad(-rotation.x), ForwardControl*(fov / 50.0)))
			
			local LeftRightControl = -GetDisabledControlNormal(0, 30)
			LeftRightX, LeftRightY = table.unpack(translateAngle(pos.x, pos.y, math.rad(-rotation.x+90.0), LeftRightControl*(fov / 50.0)))
			
			local UpDownControl = GetDisabledControlNormal(0, 31)
			UpDownX, UpDownZ = table.unpack(translateAngle(pos.y, pos.z, math.rad(-rotation.y-90.0), UpDownControl*(fov / 50.0)))
			
			pos = vector3(pos.x + ForwardX - LeftRightX, pos.y + ForwardY - LeftRightY, UpDownZ)
			
			LockMinimapPosition(pos.x, pos.y)
			LockMinimapAngle(math.abs(math.floor(rotation.x) % 360))
			
			HideHudComponentThisFrame(7)
			HideHudComponentThisFrame(8)
			HideHudComponentThisFrame(9)
			HideHudComponentThisFrame(6)
			HideHudComponentThisFrame(19)
			HideHudAndRadarThisFrame()
			
			SetCamCoord(view1, pos.x, pos.y, pos.z)
			SetCamRot(view1, rotation.x, rotation.y, roll)
			SetCamFov(view1, fov)
			
			
			if IsDisabledControlJustPressed(0, 69) then
			
				local posX, posY, posZ = table.unpack(GetCamCoord(view1))
				local rotX, rotY, rotZ = table.unpack(GetCamRot(view1,0))
				local rotZ1, rotX1 = -rotZ, rotX
				local offsetX, offsetY, offsetZ = getCameraPositionOffset(rotZ1, rotX1, 50.0)
				local ray = StartShapeTestRay(posX, posY, posZ, posX+offsetX, posY+offsetY, posZ+offsetZ, -1, PlayerPedId(), 0)
				local _, hit, _end, _, hitEnt = GetShapeTestResult(ray)
				
				if hit then
					lastPed = PlayerPedId()
					if IsEntityAPed(hitEnt) and false then -- TODO: fix crash, because it isn't supposed to crash
						if IsPedInAnyVehicle(lastPed, false) == 1 then
							inVehicle = true
							vehicle = GetVehiclePedIsIn(lastPed, false)
							seat = GetVehicleSeatPedIsIn(lastPed, vehicle)
						end
						targetPed = hitEnt
						ClearPedTasksImmediately(targetPed)
						-- ChangePlayerPed(PlayerId(), targetPed, 0, 0) -- SWITCH HAPPENS HERE
						if inVehicle == true then 
							-- SetEntityAsMissionEntity(vehicle, true)
							TaskWarpPedIntoVehicle(lastPed, vehicle, seat)
						end
						Citizen.CreateThread(toggleFreecam)
					end
					
					if IsEntityAVehicle(hitEnt) then
						if IsPedInAnyVehicle(lastPed, false) == 1 then
							inVehicle = true
							vehicle = GetVehiclePedIsIn(lastPed, false)
							seat = GetVehicleSeatPedIsIn(lastPed, vehicle)
						end
						targetPed = GetPedInVehicleSeat(hitEnt, -1)
						if DoesEntityExist(targetPed) then
							ClearPedTasksImmediately(targetPed)
							ChangePlayerPed(PlayerId(), targetPed, 0, 0) -- SWITCH HAPPENS HERE
							-- TaskSetBlockingOfNonTemporaryEvents(lastPed, true)
							-- SetEntityAsMissionEntity(lastPed, 0, 0)
							if inVehicle == true then 
								-- SetEntityAsMissionEntity(vehicle, true)
								TaskWarpPedIntoVehicle(lastPed, vehicle, seat)
							end
							-- SetEntityAsNoLongerNeeded(lastPed)
							TaskWarpPedIntoVehicle(targetPed, hitEnt, seat)
							Citizen.CreateThread(toggleFreecam)
						end
					end
				end
				
			end
		end
		
		Citizen.Wait(0)	
	end
end

Citizen.CreateThread(processFreecam)
Citizen.CreateThread(init)

freecamEnabled = false

chatInputActive = false
SetTimeScale(1.0)
SetGamePaused(false)

screenFX = "SwitchShortTrevorMid"

function toggleFreecam()
	Citizen.CreateThread(function()
		freecamEnabled = not freecamEnabled

		if freecamEnabled == true then
			exports['shift-freecam']:SetActive(true)
			StartScreenEffect(screenFX, 500, false)
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
			
			local vehicle = GetVehiclePedIsIn(PlayerPedId())
			
			UseParticleFxAssetNextCall('core')
			trail1 = StartParticleFxLoopedOnEntityBone('veh_light_red_trail', vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(vehicle, "taillight_l"), 1.0, false, false, false)
			SetParticleFxLoopedEvolution(trail1, "speed", 1.0, false);
			
			UseParticleFxAssetNextCall('core')
			trail2 = StartParticleFxLoopedOnEntityBone('veh_light_red_trail', vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(vehicle, "taillight_r"), 1.0, false, false, false)
			SetParticleFxLoopedEvolution(trail2, "speed", 1.0, false);
		else
			exports['shift-freecam']:SetActive(false)
			StartScreenEffect(screenFX, 500, false)
			-- StopScreenEffect(screenFX)
			PlaySound(-1, "slow", "SHORT_PLAYER_SWITCH_SOUND_SET", 0, 0, 1)
			-- EnableAllControlActions(0)
			SetPlayerControl(PlayerId(), true, 0)
			ClearPedTasks(PlayerPedId())
			UnlockMinimapPosition()
			UnlockMinimapAngle(0.0)
			-- SetTimeScale(1.0)
				
			StopParticleFxLooped(trail1, 0)
			StopParticleFxLooped(trail2, 0)
		end
		-- FreezeEntityPosition(PlayerPedId(), freecamEnabled)
		Citizen.Wait(250)
		StopScreenEffect()
	end)
end

Citizen.CreateThread(function()
	while true do
		if IsDisabledControlJustPressed(1, 73) then
			toggleFreecam()
		end
		
		-- SetGamePaused(freecamEnabled)

		Citizen.Wait(1)
	end
end)

fov = 50.0
roll = 0.0

originalPed = PlayerPedId()
originalCar = 0
originalSelfRegistered = false

function processFreecam()
	while true do 
		if freecamEnabled == true then
			
			-- DisplaySniperScopeThisFrame()
			
			local resX, resY = GetScreenActiveResolution()
			DrawRect(0.5, 0.5, 0.01, 0.01, 240, 151, 63, 150)
			
			
			if IsDisabledControlJustPressed(0, 23) and originalSelfRegistered == true then
				lastPed = PlayerPedId()
				if originalPed == lastPed then 
					toggleFreecam() 
				else
					if IsPedInAnyVehicle(lastPed, false) == 1 then
						inVehicle = true
						vehicle = GetVehiclePedIsIn(lastPed, false)
						seat = GetVehicleSeatPedIsIn(lastPed, vehicle)
					end
					if DoesEntityExist(originalPed) then
						ClearPedTasksImmediately(originalPed)
						ChangePlayerPed(PlayerId(), originalPed, 0, 0) -- SWITCH HAPPENS HERE
						-- TaskSetBlockingOfNonTemporaryEvents(lastPed, true)
						-- SetEntityAsMissionEntity(lastPed, 0, 0)
						if inVehicle == true then 
							-- SetEntityAsMissionEntity(vehicle, true)
							TaskWarpPedIntoVehicle(lastPed, vehicle, seat)
						end
						-- SetEntityAsNoLongerNeeded(lastPed)
						TaskWarpPedIntoVehicle(originalPed, originalCar, seat)
						toggleFreecam()
					end
				end
			end
			
			if IsDisabledControlJustPressed(0, 69) then
				local posX, posY, posZ = table.unpack(exports['shift-freecam']:GetPosition())
				local rotX, rotY, rotZ = table.unpack(exports['shift-freecam']:GetRotation())
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
						toggleFreecam()
					end
					
					if IsEntityAVehicle(hitEnt) then
						if originalCar == 0 then originalCar = GetVehiclePedIsIn(lastPed) end
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
							if originalSelfRegistered == false then
								SetEntityAsMissionEntity(lastPed, 0, 0)
							end
							if inVehicle == true then 
								if originalSelfRegistered == false then
									SetEntityAsMissionEntity(vehicle, true)
								end
								TaskWarpPedIntoVehicle(lastPed, vehicle, seat)
							end
							if originalSelfRegistered == false then originalSelfRegistered = true end
							-- SetEntityAsNoLongerNeeded(lastPed)
							TaskWarpPedIntoVehicle(targetPed, hitEnt, seat)
							toggleFreecam()
						end
					end
				end
				
			end
		end
		
		Citizen.Wait(0)	
	end
end

Citizen.CreateThread(processFreecam)
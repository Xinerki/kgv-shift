
freecamEnabled = false
screenFX = "SwitchShortTrevorMid"
camTransitionSpeed = 100

originalPed = 0
originalCar = 0
originalSelfRegistered = false

function toggleFreecam()
	Citizen.CreateThread(function()
		freecamEnabled = not freecamEnabled
		if freecamEnabled == true then
			exports['shift-freecam']:SetActive(true)
			StartScreenEffect(screenFX, camTransitionSpeed, false)
			PlaySound(-1, "slow", "SHORT_PLAYER_SWITCH_SOUND_SET", 0, 0, 1)
			SetPlayerControl(PlayerId(), false, 0)
			local vehicle = GetVehiclePedIsIn(PlayerPedId())
			TaskVehicleDriveWander(PlayerPedId(), vehicle, 10.0, 0)
			UseParticleFxAssetNextCall('core')
			trail1 = StartParticleFxLoopedOnEntityBone('veh_light_red_trail', vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(vehicle, "taillight_l"), 1.0, false, false, false)
			SetParticleFxLoopedEvolution(trail1, "speed", 1.0, false)
			UseParticleFxAssetNextCall('core')
			trail2 = StartParticleFxLoopedOnEntityBone('veh_light_red_trail', vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(vehicle, "taillight_r"), 1.0, false, false, false)
			SetParticleFxLoopedEvolution(trail2, "speed", 1.0, false)
		else
			exports['shift-freecam']:SetActive(false)
			StartScreenEffect(screenFX, camTransitionSpeed, false)
			PlaySound(-1, "slow", "SHORT_PLAYER_SWITCH_SOUND_SET", 0, 0, 1)
			SetPlayerControl(PlayerId(), true, 0)
			ClearPedTasks(PlayerPedId())
			StopParticleFxLooped(trail1, 0)
			StopParticleFxLooped(trail2, 0)
		end
		Citizen.Wait(250)
		-- StopScreenEffect()
	end)
end

Citizen.CreateThread(function()
	while true do Citizen.Wait(0)
		if IsDisabledControlJustPressed(1, 73) then
			toggleFreecam()
		end
	end
end)

Citizen.CreateThread(function ()
	-- originalPed = PlayerPedId()
	while true do Citizen.Wait(0)	
		if freecamEnabled == true then
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
						-- Wait(1) -- mandatoty frame delay
						ChangePlayerPed(PlayerId(), originalPed, 0, 0) -- SWITCH HAPPENS HERE
						if inVehicle == true then 
							TaskWarpPedIntoVehicle(lastPed, vehicle, seat)
						end
						TaskWarpPedIntoVehicle(originalPed, originalCar, -1)
						SetBlipAlpha(originalSelfBlip, 0)
						toggleFreecam()
					else
					end
				end
			end
			
			if IsDisabledControlJustPressed(0, 69) then
				local posX, posY, posZ = table.unpack(exports['shift-freecam']:GetPosition())
				local rotX, rotY, rotZ = table.unpack(exports['shift-freecam']:GetRotation())
				local offsetX, offsetY, offsetZ = getCameraPositionOffset(-rotZ, rotX, 150.0)
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
						if IsPedInAnyVehicle(lastPed, false) == 1 then
							inVehicle = true
							vehicle = GetVehiclePedIsIn(lastPed, false)
							seat = GetVehicleSeatPedIsIn(lastPed, vehicle)
						end
						
						if originalCar == 0 then originalCar = vehicle end
						if originalPed == 0 then originalPed = lastPed end
						
						-- Citizen.Trace("hitEnt = ".. vehicle .. "\n")
						-- Citizen.Trace("originalCar = ".. originalCar .. "\n")
						
						targetPed = GetPedInVehicleSeat(hitEnt, -1)
						if DoesEntityExist(targetPed) then
							ClearPedTasksImmediately(targetPed)
							-- Wait(1) -- mandatoty frame delay
							ChangePlayerPed(PlayerId(), targetPed, 0, 0) -- SWITCH HAPPENS HERE
							
							if lastPed == originalPed then 
								-- SetEntityAsMissionEntity(lastPed, true)
								if not originalSelfBlip then
									originalSelfBlip = AddBlipForEntity(lastPed)
									SetBlipSprite(originalSelfBlip, 422)
									SetBlipScale(originalSelfBlip, 1.0)
									SetBlipColour(originalSelfBlip, 3)
								else
									SetBlipAlpha(originalSelfBlip, 255)
								end
							end
							
							if originalSelfRegistered == false then
								TaskSetBlockingOfNonTemporaryEvents(lastPed, true)
								-- SetEntityAsMissionEntity(originalCar)
							end
							if inVehicle == true then 
								if originalSelfRegistered == false then
									SetEntityAsMissionEntity(vehicle, true)
								end
								TaskWarpPedIntoVehicle(lastPed, vehicle, seat)
							end
							if originalSelfRegistered == false then originalSelfRegistered = true end
							-- SetEntityAsNoLongerNeeded(lastPed)
							TaskWarpPedIntoVehicle(targetPed, hitEnt, -1)
							toggleFreecam()
						end
					end
				end
			end
		end
	end
end)
------------------------------------------------------------------------
-- AutoTractor:detectAngle
------------------------------------------------------------------------
function AutoTractor:detectAngle( smooth )

	AutoSteeringEngine.currentSteeringAngle( self )		

	if ASEGlobals.yieldDivide <= -2 then
		return AutoTractor.detectAngleDirect( self )
	end

	local wx, _, wz = AutoSteeringEngine.getAiWorldPosition( self )
	
	local count = 1
	if self.acLast ~= nil and self.acLast.count ~= nil then
		count = self.acLast.count + 1
	end
	
	local lsq = math.huge
	
	if     self.acLast == nil 
			or self.acLast.t ~= self.acTurnStage 
			or ( smooth ~= nil and smooth < self.acLast.s )
			or self.acLast.wx == nil 
			or self.acLast.wz == nil then 
		self.acLast    = {}
		self.acLast.t  = self.acTurnStage
--else
--	lsq = Utils.vector2LengthSq( self.acLast.wx - wx, self.acLast.wz - wz )
--	
--	if lsq < 1E-4 and self.acLast.co == nil then	
--		return self.acLast.detected, self.acLast.angle2, self.acLast.border
--  end 
	end 
	
	if smooth ~= nil and smooth > 0 then
		self.acLast.s = smooth
	else
		self.acLast.s = 0
	end
	
	if ASEGlobals.yieldDivide <= -1 then
		--print(tostring(self.acLast.count)..": starting directly")
		self.acLast.wx = wx
		self.acLast.wz = wz
		self.acLast.count = count
		self.acLast.detected, self.acLast.angle2, self.acLast.border = AutoTractor.detectAngleDirect( self, self.acLast.s )
	else
		if self.acLast.co == nil then 
			--print(tostring(self.acLast.count)..": starting coroutine")
			self.acLast.wx = wx
			self.acLast.wz = wz
			self.acLast.count = count
			self.acLast.co = coroutine.create( AutoSteeringEngine.processChain )
			AutoTractor.detectAngleCoroutine( self )
		elseif lsq > 1 and self.acLast.co ~= nil then
			if AutoTractor.acDevFeatures then
				print("Finishing the coroutine...("..tostring(lsq)..")")
			end
			while self.acLast.co ~= nil do 
				AutoTractor.detectAngleCoroutine( self )
			end
		else
			AutoTractor.detectAngleCoroutine( self )
		end
	end
	--self.acLast.detected, self.acLast.angle2, self.acLast.border = AutoSteeringEngine.processChain( self, self.acLast.s, false );				 
	
	return self.acLast.detected, self.acLast.angle2, self.acLast.border
end

function AutoTractor:detectAngleCoroutine()
	local s, d, a, b = coroutine.resume( self.acLast.co, self, self.acLast.s, true )
	if s then 
		if b > 0 then d = false end
		self.acLast.detected = d
		self.acLast.angle2   = a
		self.acLast.border   = b  
	else 
		self.acLast.co       = nil 
		print("Error executing coroutine: "..tostring(d)) 
	end 
	if self.acLast.co ~= nil and coroutine.status( self.acLast.co ) == "dead" then 
		self.acLast.co       = nil 
		--print(tostring(self.acLast.count)..": finished with: "..tostring(d).." "..tostring(b))
	end 

	if self.acTurnStage == 0 and self.acLast.border > 0 and ASEGlobals.zeroWidth > 0 then 
		self.acLast.co = nil 
		AutoSteeringEngine.reinitToolsWithWidthFactor( self, self.acDimensions.maxLookingAngle, self.acParameters.widthOffset, 0 )		
		self.acTraceSmoothOffset = nil
		self.acLast.detected, self.acLast.angle2, self.acLast.border = AutoSteeringEngine.processChain( self, 0 )
		self.acLast.t = -9999
		if AutoTractor.acDevFeatures then
			print("scan again w/o offset: "..tostring(self.acLast.border))
		end
	end			
end

function AutoTractor:detectAngleDirect( smooth )
	local d, a, b = AutoSteeringEngine.processChain( self, smooth )
	if b > 0 and self.acTurnStage == 0 and ASEGlobals.zeroWidth > 0 then 
		AutoSteeringEngine.reinitToolsWithWidthFactor( self, self.acDimensions.maxLookingAngle, self.acParameters.widthOffset, 0 )			
		self.acTraceSmoothOffset = AutoSteeringEngine.getTraceLength(self) + 1
		d, a, b = AutoSteeringEngine.processChain( self, 0 )
		if AutoTractor.acDevFeatures then
			print("scan again w/o offset: "..tostring(b))
		end
	end
	if b > 0 then
		d = false
	end
	return d, a, b
end

------------------------------------------------------------------------
-- AutoTractor:getMaxAngleWithTool
------------------------------------------------------------------------
function AutoTractor:getMaxAngleWithTool( outside )
	
	local angle
	local toolAngle = AutoSteeringEngine.getToolAngle( self );	
	if not self.acParameters.leftAreaActive then
		toolAngle = -toolAngle
	end

	if outside then
		angle = -self.acDimensions.maxSteeringAngle + math.min( 2 * math.max( -toolAngle - ASEGlobals.maxToolAngle, 0 ), 0.9 * self.acDimensions.maxSteeringAngle );	-- 75° => 1,3089969389957471826927680763665
	else
		angle =  self.acDimensions.maxSteeringAngle - math.min( 2 * math.max(  toolAngle - ASEGlobals.maxToolAngle, 0 ), 0.9 * self.acDimensions.maxSteeringAngle );	-- 75° => 1,3089969389957471826927680763665
	end

	if AutoTractor.acDevFeatures and math.abs( toolAngle ) >= ASEGlobals.maxToolAngle - 0.01745 then
		print(string.format("Tool angle: a: %0.1f° ms: %0.1f° to: %0.1f°", math.deg(angle), math.deg(self.acDimensions.maxSteeringAngle), math.deg(toolAngle) ) )
	end

	
	return angle
end

------------------------------------------------------------------------
-- AICombine:updateAIMovement
------------------------------------------------------------------------
function AutoTractor:newUpdateAIMovement( superFunc, dt, ... )

	if not self.isServer or self.acParameters == nil or not self.acParameters.enabled then
		return superFunc( self, dt, ... );
	end
	
	local dt = self.acDtSum

	AutoTractor.statEvent( self, "t0", dt )

	AutoTractor.checkState( self )
	if not AutoSteeringEngine.hasTools( self ) then
		AITractor.stopAITractor(self)
		return;
	end

	if not self.isControlled then
		if g_currentMission.environment.needsLights then
			self:setLightsVisibility(true)
		else
			self:setLightsVisibility(false)
		end
	end
	
	local allowedToDrive =  AutoSteeringEngine.checkAllowedToDrive( self, not ( self.acParameters.isHired  ) )
	
	if self.acPause then
		allowedToDrive = false
		AutoTractor.setStatus( self, 0 )
	end
	
	if self.acAnimWaitTimer ~= nil then
		if      self.acTurnStage < 0 
				and ( self.acAnimWaitTurnStage == nil
					 or self.acAnimWaitTurnStage >= 0 ) then
			self.acAnimWaitTimer     = nil
			self.acAnimWaitTurnStage = nil
		end
	end
	
	self.acIsAnimPlaying = false
	if AutoSteeringEngine.checkIsAnimPlaying( self, self.acImplementsMoveDown ) then
		self.acAnimWaitTurnStage = self.acTurnStage
		if    self.acAnimWaitTimer == nil then
			self.acAnimWaitTimer = self.acDeltaTimeoutWait --self.acDeltaTimeoutStart
			self.acIsAnimPlaying = true
		elseif self.acAnimWaitTimer > 0 then
			self.acAnimWaitTimer = self.acAnimWaitTimer - dt
			self.acIsAnimPlaying = true
		end
	else
		self.acAnimWaitTimer     = nil
		self.acAnimWaitTurnStage = nil
	end
	
	if      allowedToDrive
			and ( self.acTurnStage  < 0
				 or self.acTurnStage == 3
				 or self.acTurnStage == 8
				 or self.acTurnStage == 26 or self.acTurnStage == 27
				 or self.acTurnStage == 38
				 or self.acTurnStage == 48 or self.acTurnStage == 49
				 or self.acTurnStage == 59 or self.acTurnStage == 60 
				 or self.acTurnStage == 77 or self.acTurnStage == 78 or self.acTurnStage == 79 ) 
			and self.acIsAnimPlaying then
		AutoTractor.setStatus( self, 3 )
		allowedToDrive = false
	end
	
	--if not allowedToDrive then print("combine unloading") end
	
	for _, v in pairs(self.numCollidingVehicles) do
		if v > 0 then
			AutoTractor.setStatus( self, 3 )
			allowedToDrive = false
			--print("collision")
			break
		end
	end
	
	if self.waitForTurnTime > g_currentMission.time then
		if self.acLastSteeringAngle ~= nil then
			local a = AutoSteeringEngine.currentSteeringAngle( self, self.acParameters.inverted )
			if math.abs( self.acLastSteeringAngle - a ) < 0.025 then
				self.waitForTurnTime = 0
			end
		end
	end
	
	if self.waitForTurnTime > g_currentMission.time then
		AutoTractor.setStatus( self, 0 )
		if self.acLastSteeringAngle ~= nil then
			AutoSteeringEngine.steer( self, dt, self.acLastSteeringAngle, self.aiSteeringSpeed, false );
		end
		if self.isRealistic then
			AutoSteeringEngine.drive( self, dt, 0, false, true, 0 );
		else
			AutoSteeringEngine.drive( self, dt, 0, true, true, 0 );
		end
		return
		--print("waiting: "..tostring( self.waitForTurnTime - g_currentMission.time ))
	end
	
	local speedLevel = 2;
	if self.speed2Level ~= nil and 0 <= self.speed2Level and self.speed2Level <= 4 then
		speedLevel = self.speed2Level;
	end
	-- 20 km/h => lastSpeed = 5.555E-3 => speedLevelFactor = 234 * 5.555E-3 = 1.3
	-- 10 km/h =>                         speedLevelFactor                  = 0.7
	local speedLevelFactor = math.min( self.lastSpeed * 234, 0.5 ) 
	                                                               
	
-- Speed level always 1 while turning	
	if self.acTurnStage ~= 0 and 0 < speedLevel and speedLevel < 4 then
		speedLevel = 1
	end

	if not allowedToDrive or speedLevel == 0 then
		--print("not allowed to drive: "..tostring(allowedToDrive).." "..tostring(speedLevel));
		AutoTractor.statEvent( self, "tS", dt )
		self.isHirableBlocked = true		
		AutoSteeringEngine.drive( self, dt, 0, false, true, 0 );
		return
	end
	self.isHirableBlocked = false
	
	self.acLastSteeringAngle = nil
	
	if not self:getIsAITractorAllowed() then
		AITractor.stopAITractor(self)
		return
	end

	local moveForwards = true

	local offsetOutside = 0;
	if     self.acParameters.rightAreaActive then
		offsetOutside = -1;
	elseif self.acParameters.leftAreaActive then
		offsetOutside = 1;
	end;
	
	self.turnTimer          = self.turnTimer - dt;
	self.acTurnOutsideTimer = self.acTurnOutsideTimer - dt;
	
	if     self.acTurnStage ~= 0 then
		self.aiRescueTimer = self.aiRescueTimer - dt;
	else
		self.aiRescueTimer = self.acDeltaTimeoutStop;
	end
	
	if self.aiRescueTimer < 0 then
		AITractor.stopAITractor(self)
		return
	end
		
--==============================================================				
	local angle, angle2;
	local angleMax = self.acDimensions.maxLookingAngle;
	local detected = false;
	local fruitsDetected = false;
	local border   = 0;
	local angleFactor;
	local offsetOutside;
	local noReverseIndex = 0;
	local angleOffset = 6;
	local stoppingDist = 0.5;
--==============================================================		
--==============================================================		
	local turnAngle = math.deg(AutoSteeringEngine.getTurnAngle(self));

	if AutoTractor.acDevFeatures then
		self.atHud.InfoText = string.format( "Turn stage: %2i, angle: %3i",self.acTurnStage,turnAngle )
	end

	if self.acParameters.leftAreaActive then
		turnAngle = -turnAngle;
	end;

	fruitsDetected  = AutoSteeringEngine.hasFruits( self, 0.9 )
	
	noReverseIndex  = AutoSteeringEngine.getNoReverseIndex( self );
	self.acHighPrec = true
	
--==============================================================				
	if self.acTurnStage <= 0 then	
		local smooth       = 0
		
		if  self.acTurnStage < 0 or self.acTraceSmoothOffset == nil then
			self.acTraceSmoothOffset = AutoSteeringEngine.getTraceLength(self) + 1
		elseif ASEGlobals.smoothFactor > 0 and ASEGlobals.smoothMax > 0 and AutoSteeringEngine.getTraceLength(self) > 3 then --and fruitsDetected then
			smooth = Utils.clamp( ASEGlobals.smoothFactor * ( AutoSteeringEngine.getTraceLength(self) - self.acTraceSmoothOffset ), 0, ASEGlobals.smoothMax ) * Utils.clamp( speedLevelFactor, 0.7, 1.3 ) 
		end

		detected, angle2, border = AutoTractor.detectAngle( self, smooth )
		
		if self.acTurnStage == 0 and ( detected or not fruitsDetected ) then
			self.acHighPrec = false
		end
		
		if border > 0 then
			self.acTurn2Outside = true
			if self.acTurnStage == 0 then
				if ASEGlobals.chainStart > 1 then
					detected = false
				else
					detected = true
					local wx,_,wz = AutoSteeringEngine.getAiWorldPosition( self )
					if self.acTurnInTheMiddle == nil then
						self.acTurnInTheMiddle = { wx = wx, wz = wz }
					else
						local lsq = Utils.vector2LengthSq( self.acTurnInTheMiddle.wx - wx, self.acTurnInTheMiddle.wz - wz )
						if lsq > ASEGlobals.ignoreDist * ASEGlobals.ignoreDist then
							detected = false
						end
					end
				end
			else
				self.acTurnInTheMiddle = nil
			end
		else
			self.acTurn2Outside = false
			self.acTurnInTheMiddle = nil
		end
		
		if detected and self.acTurnStage == 0 and not fruitsDetected then
		--	if self.acParameters.leftAreaActive then
		--		angle = angle2 
		--	else
		--		angle = -angle2		
		--	end
		--	print(string.format("1.: %2.1f° / %2.1f° / ",math.deg(angle),math.deg(angle2))..tostring(self.acParameters.leftAreaActive))
		--	if angle < 0 and AutoSteeringEngine.noTurnAtEnd( self ) then
		--		angle = 0
		--	end
		elseif  self.acTurnStage == 0 
			--and detected and border <= 0
				and AutoSteeringEngine.getIsAtEnd( self ) 
				and AutoSteeringEngine.getTraceLength(self) > 5 then
			angle = math.min( math.max( math.rad( 0.5 * turnAngle ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
			
		elseif not detected then
			self.acTraceSmoothOffset = nil
			
			if self.acTurnStage == -3 or self.acTurnStage == -13 or self.acTurnStage == -23 then
				angle = 0
			--elseif self.acTurn2Outside and self.acTurnStage == 0 then
			--	angle = angleMax
			elseif self.acTurnStage == -2 or self.acTurnStage == -12 or self.acTurnStage == -22 then
				--angle  = nil
				--angle2 = AutoSteeringEngine.navigateToSavePoint( self, true, AutoTractor.navigationFallbackRetry )
				local a, o = AutoSteeringEngine.navigateToSavePoint( self, true, AutoTractor.navigationFallbackRetry )
				if o then
					if self.acTurn2Outside then
						angle =  self.acDimensions.maxSteeringAngle
					else
						angle = -self.acDimensions.maxLookingAngle 
					end
				else
					angle  = nil
					angle2 = a
				end
			elseif self.acTurn2Outside then
				if     self.acTurnStage < 0 then 
					angle = self.acDimensions.maxSteeringAngle
				elseif noReverseIndex > 0 then 
					angle = self.acDimensions.maxLookingAngle 
				else 
					angle = 0
				end 
			elseif self.acTurnStage < 0 then --self.acTurnStage == -1 or self.acTurnStage == -11 or self.acTurnStage == -21 then
				--angle = -self.acDimensions.maxSteeringAngle					
				angle  = nil
				angle2 = AutoSteeringEngine.navigateToSavePoint( self, false, AutoTractor.navigationFallbackRotateMinus )
				
			else
				angle = math.min( math.max( math.rad( 0.5 * turnAngle ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
			end
		end
--==============================================================				
	elseif self.acTurnStage == 8 then	
		AutoSteeringEngine.currentSteeringAngle( self );
		AutoSteeringEngine.syncRootNode( self, true )
		AutoSteeringEngine.setChainStraight( self );			
		border = AutoSteeringEngine.getAllChainBorders( self );
		if border > 0 then detected = true end
	
--==============================================================				
	elseif self.acTurnStage == 36
			or self.acTurnStage == 38
			or self.acTurnStage == 49 then

		detected, angle2, border = AutoTractor.detectAngle( self )
		
--==============================================================				
	elseif self.acTurnStage == 60 then	

		detected, angle2, border = AutoTractor.detectAngle( self )
		
--==============================================================				
-- backwards
	elseif self.acTurnStage == 4 then

		if self.acTurn2Outside then
			detected, angle2, border = AutoTractor.detectAngle( self, 0.5 )
		else 
			detected, angle2, border = AutoTractor.detectAngle( self )
		end 
		
	elseif self.acTurnStage == 3 then

		AutoSteeringEngine.setSteeringAngle( self, 0 )
	
		if self.acTurn2Outside then
			detected, _, border = AutoTractor.detectAngle( self, 0.5 )
		else
			AutoSteeringEngine.syncRootNode( self, true )
			AutoSteeringEngine.setChainStraight( self )

			border   = AutoSteeringEngine.getAllChainBorders( self, 1, ASEGlobals.chainMin );
			detected = border > 0
		end

	else
		AutoSteeringEngine.setChainContinued( self );
	end

--==============================================================						
--==============================================================		
-- move far enough			
	if     self.acTurnStage == 1 then

		self.acTurnStage4Point = nil 
		AutoTractor.setAIImplementsMoveDown(self,false);
		
		--if turnAngle > -angleOffset then
		--	angle = self.acDimensions.maxSteeringAngle;
		--else
		--	angle = 0;
		--end
		angle = math.min( math.max( math.rad( turnAngle ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, false );
		
		if     self.acTurn2Outside
				or ( math.abs( turnAngle ) < angleOffset and z > math.max( self.acDimensions.radius, ASEGlobals.minRadius ) ) then
			AutoSteeringEngine.ensureToolIsLowered( self, false )
			self.acTurnStage   = self.acTurnStage + 1;
			self.turnTimer     = self.acDeltaTimeoutWait;
			allowedToDrive     = false;			
			angle              = 0
			self.waitForTurnTime = g_currentMission.time + self.turnTimer;
		end

--==============================================================				
-- going back I
	elseif self.acTurnStage == 2 then
		
		moveForwards   = false;					
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, false );
		angle = -math.min( math.max( math.rad( turnAngle ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )

		if     self.acTurn2Outside and ( x*x+z*z > 100 or noReverseIndex > 0 ) then
			self.acTurnStage = self.acTurnStage + 2;
			self.turnTimer = self.acDeltaTimeoutNoTurn
		elseif z < math.max( self.acDimensions.radius, ASEGlobals.minRadius ) + stoppingDist then
			self.acTurnStage         = self.acTurnStage + 1;
		--self.acLastSteeringAngle = self.acDimensions.maxSteeringAngle
			self.waitForTurnTime     = g_currentMission.time + self.acDeltaTimeoutWait
			if self.acTurn2Outside then
				angle = 0 ---self.acDimensions.maxSteeringAngle
			elseif self.acDimensions.wheelBase > 0 and z > 0 then
				angle = Utils.clamp( math.atan2( self.acDimensions.wheelBase, z / ( 1 - math.sin( math.abs( math.rad( turnAngle ) ) ) ) ), 0, self.acDimensions.maxSteeringAngle )
			else				
				angle = self.acDimensions.maxSteeringAngle
			end
		end

--==============================================================				
-- going back II
	elseif self.acTurnStage == 3 then

		moveForwards = false;			
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, false );

		if self.acTurn2Outside and x*x+z*z > 100 then
			self.acTurnStage = self.acTurnStage + 1;
			self.turnTimer = self.acDeltaTimeoutStart
		elseif detected then
			angle                = 0
		--self.acTurnStage     = -1
			self.acTurnStage     = self.acTurnStage + 1;
			self.waitForTurnTime = g_currentMission.time + self.acDeltaTimeoutWait
			self.turnTimer       = self.acDeltaTimeoutWait
		elseif self.acTurn2Outside then
			angle = -self.acDimensions.maxLookingAngle
			if math.abs( turnAngle ) > 30 then
				self.acTurnStage = self.acTurnStage + 1;
				self.turnTimer = self.acDeltaTimeoutStart
			end
		elseif math.abs( turnAngle ) > 120 - angleOffset then
			self.acTurnStage     = self.acTurnStage + 1;
			self.turnTimer       = self.acDeltaTimeoutStart
			angle                = math.rad( 120 - math.abs( turnAngle ) )
			self.waitForTurnTime = g_currentMission.time + self.acDeltaTimeoutWait
		elseif self.acDimensions.wheelBase > 0 and z > 0 then
			angle = Utils.clamp( math.atan2( self.acDimensions.wheelBase, z / ( 1 - math.sin( math.abs( math.rad( turnAngle ) ) ) ) ), 0, self.acDimensions.maxSteeringAngle )
		else
			angle = self.acDimensions.maxSteeringAngle
		end

		if noReverseIndex > 0 and self.acTurn2Outside then			
			local toolAngle = AutoSteeringEngine.getToolAngle( self );			
			angle  = nil;
			angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		end
						
--==============================================================				
-- going back III
	elseif self.acTurnStage == 4 then

		moveForwards = false;					
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, false );
		local dist2 = 0
		
		if not detected then
			self.acTurnStage4Point = nil
			local endAngle = 120
			if border > 0 then	
				--angle = -self.acDimensions.maxSteeringAngle
				local toolAngle = AutoSteeringEngine.getToolAngle( self );			
				angle  = nil;
				angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
			elseif math.abs( turnAngle ) > endAngle - angleOffset then
				angle = math.rad( endAngle - math.abs( turnAngle ) )
			elseif self.acTurn2Outside then
				angle = -self.acDimensions.maxLookingAngle
			else
				angle = self.acDimensions.maxSteeringAngle
			end
		elseif self.acTurn2Outside then
			local x,_,z = AutoSteeringEngine.getAiWorldPosition( self )			
			
			if self.acTurnStage4Point == nil then 
				self.acTurnStage4Point = { x=x, z=z }
			else 
				dist2 = (x-self.acTurnStage4Point.x)^2 + (z-self.acTurnStage4Point.z)^2 
			end
		else 
			dist2 = 10 
		end
		
		if noReverseIndex > 0 and self.acTurn2Outside then			
			local toolAngle = AutoSteeringEngine.getToolAngle( self );			
			angle  = nil;
			angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		end
						
		if     ( detected and dist2 > 9 )
				or self.turnTimer < 0
				or x*x + z*z      > 100 then
			if not detected then
				angle = 0
				if AutoTractor.acDevFeatures then
					print("time out: "..tostring(self.acDeltaTimeoutNoTurn))
				end
			end
				
			self.acTurnStage4Point = nil
			self.acTurnStage       = -1
			self.waitForTurnTime   = g_currentMission.time + self.acDeltaTimeoutWait
		end


--==============================================================				
--==============================================================				
-- 90° corner w/o going reverse					
	elseif self.acTurnStage == 5 then
		allowedToDrive = false;				
		angle = AutoTractor.getMaxAngleWithTool( self, self.acTurn2Outside )
		AutoTractor.setAIImplementsMoveDown(self,false);
		self.acTurnStage   = 6;					
		
--==============================================================				
	elseif self.acTurnStage == 6 then
		AutoSteeringEngine.ensureToolIsLowered( self, false )
		angle = AutoTractor.getMaxAngleWithTool( self, self.acTurn2Outside )
		
		if turnAngle < 0 then
			self.acTurnStage   = 7;					
		end;
		
--==============================================================				
	elseif self.acTurnStage == 7 then
		angle = AutoTractor.getMaxAngleWithTool( self, self.acTurn2Outside )
		if self.acTurn2Outside then				
			if 170 < turnAngle and turnAngle < 180 then
				self.acTurnStage   = 8;					
			end;
		else
			if 135 < turnAngle and turnAngle < 145 then
				self.acTurnStage   = 8;					
			end;
		end
		
--==============================================================				
		
	elseif self.acTurnStage == 8 then
		angle = AutoTractor.getMaxAngleWithTool( self, self.acTurn2Outside )
		
		if detected or fruitsDetected then
			self.acTurnStage   = -1;					
			self.turnTimer     = self.acDeltaTimeoutStart;
		end;
		
--==============================================================				
--==============================================================				
-- the new U-turn with reverse
	elseif self.acTurnStage == 20 then
		angle = 0;
		self.acTurnStage   = self.acTurnStage + 1;					
		self.turnTimer     = self.acDeltaTimeoutRun;
		
		AutoTractor.setAIImplementsMoveDown(self,false);
				
--==============================================================				
-- move far enough if tool is in front
	elseif self.acTurnStage == 21 then
		angle = 0;

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		
		local dist = math.max( 0, self.acDimensions.toolDistance + math.max( self.acDimensions.distance, -self.acDimensions.zBack ) )
		turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self )
		dist = dist + math.max( 1, self.acDimensions.radius - turn75.radiusT )
		if noReverseIndex > 0 then
		-- space for the extra turn to get the tool angle to 0
			dist = dist + 2
		end
		
		if AutoTractor.acDevFeatures then
			print(string.format("T21: x: %0.3fm z: %0.3fm dist: %0.3fm (%0.3fm %0.3fm %0.3fm %0.3fm)",x, z, dist, self.acDimensions.toolDistance, self.acDimensions.zBack, self.acDimensions.radius, turn75.radiusT ) )
		end
		
		if z > dist - stoppingDist then
			AutoSteeringEngine.ensureToolIsLowered( self, false )
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================				
-- turn 90°
	elseif self.acTurnStage == 22 then
		angle = AutoTractor.getMaxAngleWithTool( self )
		
		local toolAngle = AutoSteeringEngine.getToolAngle( self );	
		if not self.acParameters.leftAreaActive then
			toolAngle = -toolAngle
		end
				
		turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self )
		
		if turnAngle < -135 or turnAngle + 0.3 * math.deg( toolAngle ) < angleOffset-90 then
		--if turnAngle < angleOffset - 90 - math.deg(turn75.gammaE) then
			AutoSteeringEngine.setPloughTransport( self, true, true )
			
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================			
-- move forwards and reduce tool angle	
	elseif self.acTurnStage == 23 then

		local toolAngle = AutoSteeringEngine.getToolAngle( self )
		if not self.acParameters.leftAreaActive then
			toolAngle = -toolAngle;
		end;
		toolAngle = math.deg( toolAngle )

		angle = math.rad( turnAngle + 90 + 0.3 * toolAngle )
		
		if math.abs( turnAngle + 90 ) < 9 and math.abs( turnAngle + 90 + 0.3 * toolAngle ) < 3 then
			if self.acTurn2Outside then
				self.acParameters.leftAreaActive  = not self.acParameters.leftAreaActive;
				self.acParameters.rightAreaActive = not self.acParameters.rightAreaActive;
				AutoTractor.sendParameters(self);
			end
			
			local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
			if self.acParameters.leftAreaActive then x = -x end

			if self.acTurn2Outside then x = -x end
			x = x - 1 - self.acDimensions.radius -- + math.max( 0, self.acDimensions.radius - turn75.radiusT )
			
			if x > -stoppingDist or z < 0 then
      -- no need to drive backwards
				if self.acParameters.leftAreaActive then
					AITractor.aiRotateLeft(self);
				else
					AITractor.aiRotateRight(self);
				end
				AutoSteeringEngine.setPloughTransport( self, false )
				self.acTurnStage     = 26
				angle                = 0
				self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
				self.turnTimer       = 0
			else
				if noReverseIndex <= 0 then
					if self.acParameters.leftAreaActive then
						AITractor.aiRotateLeft(self);
					else
						AITractor.aiRotateRight(self);
					end
					AutoSteeringEngine.setPloughTransport( self, true, true )
				end
			
				self.acTurnStage   = self.acTurnStage + 1;					
				self.turnTimer     = self.acDeltaTimeoutRun;
			end
		end

--==============================================================				
-- wait		
	elseif self.acTurnStage == 24 then
		allowedToDrive = false;						
		moveForwards = false;					
		angle  = nil;
		local toolAngle = AutoSteeringEngine.getToolAngle( self );
		angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
		end
		
--==============================================================				
-- move backwards (straight)		
	elseif self.acTurnStage == 25 then		
		moveForwards = false;					
		angle  = nil;
		local toolAngle = AutoSteeringEngine.getToolAngle( self );
		angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if self.acParameters.leftAreaActive then x = -x end
		
		if self.acTurn2Outside then x = -x end
		x = x - 2 - self.acDimensions.radius - math.max( 0.2 * self.acDimensions.radius, 1 )

		if allowedToDrive and ( x > -stoppingDist or z < 0 ) then
			if noReverseIndex > 0 then
				if self.acParameters.leftAreaActive then
					AITractor.aiRotateLeft(self);
				else
					AITractor.aiRotateRight(self);
				end
			end
			AutoSteeringEngine.setPloughTransport( self, false )--, true )
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end
		
--==============================================================				
-- wait
	elseif self.acTurnStage == 26 then
		angle = self.acDimensions.maxSteeringAngle;
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
			
		--AutoSteeringEngine.navigateToSavePoint( self, true )			
		else
			allowedToDrive = false;						
		end

--==============================================================				
-- turn 90°
	elseif self.acTurnStage == 27 then
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
--*********************************************************************************		
-- TODO
		local test= Utils.getNoNil( self.aseDistance , 0 )
--*********************************************************************************				
		
		--if z >= test then
		--	if fruitsDetected then
		--		AutoTractor.setAIImplementsMoveDown(self,true);
		--	end
		--elseif not detected or not fruitsDetected then
		--	AutoTractor.setAIImplementsMoveDown(self,false);
		--end
		
		detected  = false
		local nav = true
	--if ( fruitsDetected or z < test ) and math.abs( turnAngle ) >= 180-math.deg( angleMax ) then  --135 then
	--if math.abs( turnAngle ) >= 180-math.deg( angleMax ) then
		if     fruitsDetected
				or ( math.abs( turnAngle ) >= 170 
				 and math.abs( AutoSteeringEngine.getToolAngle( self ) ) <= ASEGlobals.maxToolAngle2 ) then
			nav = false
			detected, angle2, border = AutoTractor.detectAngle( self )
		end		
		
		if AutoTractor.acDevFeatures then
			print(string.format("T27: x: %0.3fm z: %0.3fm test: %0.3fm fd: %s det: %s ta: %0.1f°", x, z, test, tostring(fruitsDetected), tostring(detected), turnAngle ) )
		end
		
	--if detected and fruitsDetected then
	--	self.acTurnStage   = -22 --self.acTurnStage + 1;					
		if detected then
			self.acTurnStage   = -2
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
			AutoTractor.setAIImplementsMoveDown(self,true);
		elseif detected then
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
		elseif nav or z < math.min( 0, test ) - 5 then
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
			angle  = nil
			angle2 = AutoTractor.navigateToSavePoint( self, true )
		end
		
--==============================================================				
-- wait after U-turn
	elseif self.acTurnStage == 28 then
		allowedToDrive   = false;						
		angle            = 0;		
		self.acTurnStage = -22 -- -2;					
	
--==============================================================				
--==============================================================				
-- 90° turn to inside with reverse
	elseif self.acTurnStage == 30 then

		AutoTractor.setAIImplementsMoveDown(self,false);
		self.acTurnStage   = self.acTurnStage + 1;
		self.turnTimer     = self.acDeltaTimeoutWait;
		--self.waitForTurnTime = g_currentMission.time + self.turnTimer;

--==============================================================				
-- wait
	elseif self.acTurnStage == 31 then
		allowedToDrive = false;				
		moveForwards = false;					
		angle = 0
		
		if self.turnTimer < 0 then
			AutoSteeringEngine.ensureToolIsLowered( self, false )
			self.acTurnStage   = self.acTurnStage + 1;					
		end

--==============================================================				
-- move backwards (straight)		
	elseif self.acTurnStage == 32 then		
		moveForwards = false;					
		angle  = nil;
		local toolAngle = AutoSteeringEngine.getToolAngle( self );
		angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self );
		
		local wx,_,wz = AutoSteeringEngine.getAiWorldPosition( self );
		local f = 0.7
		if  AutoSteeringEngine.checkField( self, wx, wz ) then
			f = 1.4
		end
				
		if z < f * self.acDimensions.radius + stoppingDist then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================				
-- turn 45°
	elseif self.acTurnStage == 33 then
		angle = AutoTractor.getMaxAngleWithTool( self, true )
		
		local toolAngle = AutoSteeringEngine.getToolAngle( self );	
		if self.acParameters.leftAreaActive then
			toolAngle = -toolAngle
		end
		
		if turnAngle - 0.6 * math.deg( toolAngle ) > 55-angleOffset then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================			
-- move forwards and reduce tool angle	
	elseif self.acTurnStage == 34 then

		local toolAngle = AutoSteeringEngine.getToolAngle( self )
		
		if turnAngle > 55 + angleOffset then
			angle = AutoTractor.getMaxAngleWithTool( self, false )
		elseif turnAngle < 55 - angleOffset then
			angle = AutoTractor.getMaxAngleWithTool( self, true )
		else
			angle  = nil;		
			angle2 = math.min( math.max( -toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		end
		
		if math.abs(math.deg(toolAngle)) < 5 and math.abs( turnAngle - 55 ) < angleOffset then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================				
-- wait		
	elseif self.acTurnStage == 35 then
		allowedToDrive = false;						
		moveForwards = false;					
		angle  = 0;

		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
		end
		
--==============================================================				
-- move backwards (straight)		
	elseif self.acTurnStage == 36 then		
		moveForwards = false;					
		angle  = nil;
		local toolAngle = AutoSteeringEngine.getToolAngle( self );
		angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		
		local _,z, allowedToDrive = AutoTractor.getTurnVector( self );
		
		if z < 0 or ( detected and z < 0.5 * self.acDimensions.distance ) then				
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end
		
--==============================================================				
-- wait
	elseif self.acTurnStage == 37 then
		allowedToDrive = false;						
		angle = AutoTractor.getMaxAngleWithTool( self, true )
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
		end

--==============================================================				
-- turn 45°
	elseif self.acTurnStage == 38 then
		local x, allowedToDrive = AutoTractor.getTurnVector( self );
		if self.acParameters.leftAreaActive then x = -x end
		
		if turnAngle < 70 then
			angle = -self.acDimensions.maxSteeringAngle;
		elseif fruitsDetected or detected or math.abs( turnAngle ) > 90 or x < 0 then
			self.acTurnStage = -1;					
			self.turnTimer   = self.acDeltaTimeoutStart;
		else
			angle = 0
		end
		
--==============================================================				
-- wait after 90° turn
	elseif self.acTurnStage == 39 then
		allowedToDrive = false;						
		
		angle = 0;
		
		--if self.turnTimer < 0 then
			self.acTurnStage = -1;					
		--	self.turnTimer   = self.acDeltaTimeoutStart;
		--end;

--==============================================================				
--==============================================================				
-- 180° turn with 90° backwards
	elseif self.acTurnStage == 40 then
		angle = 0;
		self.acTurnStage   = self.acTurnStage + 1;					
		self.turnTimer     = self.acDeltaTimeoutRun;

		AutoTractor.setAIImplementsMoveDown(self,false);
		
--==============================================================				
-- move far enough if tool is in front
	elseif self.acTurnStage == 41 then
		angle = 0;

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if z > math.max( 0, self.acDimensions.toolDistance ) + 1 - stoppingDist then
			AutoSteeringEngine.ensureToolIsLowered( self, false )
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================				
-- wait
	elseif self.acTurnStage == 42 then
		allowedToDrive = false;				
		moveForwards = false;					
		angle = 0
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
		end

--==============================================================				
-- turn 45°
	elseif self.acTurnStage == 43 then		
		angle = AutoTractor.getMaxAngleWithTool( self, true )
		
		if turnAngle > 45-angleOffset then
			if self.acParameters.leftAreaActive then
				AITractor.aiRotateLeft(self);
			else
				AITractor.aiRotateRight(self);
			end
			self.acTurnStage     = self.acTurnStage + 1;					
			self.turnTimer       = self.acDeltaTimeoutNoTurn;
		end
--==============================================================				
-- wait
	elseif self.acTurnStage == 44 then
		allowedToDrive = false;						
		angle = AutoTractor.getMaxAngleWithTool( self )
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
		end

--==============================================================				
-- move backwards (90°)	I	
	elseif self.acTurnStage == 45 then		
		moveForwards = false;					
		angle = AutoTractor.getMaxAngleWithTool( self )
		
		if turnAngle > 90-angleOffset then
			self.acTurnStage     = self.acTurnStage + 1;					
			angle = math.min( math.max( 3 * math.rad( 90 - turnAngle ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
			self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
		end
--==============================================================				
-- move backwards (0°) II
	elseif self.acTurnStage == 46 then		
		moveForwards = false;					
		angle = math.min( math.max( 3 * math.rad( 90 - turnAngle ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if not self.acParameters.leftAreaActive then x = -x end
	
		--if self.isRealistic then
		--	x = x - 1
		--else	
		--	x = x - 0.5
		--end
		
		if x > - stoppingDist then
			self.acTurnStage   = self.acTurnStage + 1;					
			angle = self.acDimensions.maxSteeringAngle;
			self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
		end
--==============================================================				
-- move backwards (45°) III
	elseif self.acTurnStage == 47 then		
		moveForwards = false;					
		angle = AutoTractor.getMaxAngleWithTool( self )
		
		if turnAngle > 150-angleOffset then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end
--==============================================================				
-- wait
	elseif self.acTurnStage == 48 then
		allowedToDrive = false;						
		angle = AutoTractor.getMaxAngleWithTool( self, false )
		
		if self.turnTimer < 0 then
			AutoTractor.setAIImplementsMoveDown(self,true);
			AutoSteeringEngine.navigateToSavePoint( self, true )
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
		end

--==============================================================				
-- turn 90° II
	elseif self.acTurnStage == 49 then
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
--*********************************************************************************		
-- TODO
		local test= Utils.getNoNil( self.aseDistance , 0 ) + stoppingDist
--*********************************************************************************				
		
		--if z >= test then
		--	if fruitsDetected then
		--		AutoTractor.setAIImplementsMoveDown(self,true);
		--	end
		--elseif not detected or not fruitsDetected then
		--	AutoTractor.setAIImplementsMoveDown(self,false);
		--end
		
	--if fruitsDetected and detected and z < test then
	--	self.acTurnStage   = -22 --self.acTurnStage + 1;					
		if detected and z < test then
			self.acTurnStage   = -2
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
			AutoTractor.setAIImplementsMoveDown(self,true);
		elseif not detected then					
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
			angle  = nil
			angle2 = AutoTractor.navigateToSavePoint( self, true )
		else
			AutoTractor.setAIImplementsMoveDown(self,true);
		end

		
--==============================================================				
--==============================================================				
-- 180° turn with 90° backwards
--elseif self.acTurnStage == 50 then
--	allowedToDrive = false;				
--	moveForwards = false;					
--	angle = 0
--	
--	--if self.turnTimer < 0 then
--		AutoTractor.setAIImplementsMoveDown(self,false);
--		self.acTurnStage   = self.acTurnStage + 1;					
--	--end
--==============================================================				
-- move far enough if tool is in front
	elseif self.acTurnStage == 50 then
		AutoTractor.setAIImplementsMoveDown(self,false);
		angle = 0;

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );		
		local dist = math.max( 0, self.acDimensions.toolDistance )
		
		if z > dist - stoppingDist then
			self.acTurnStage   = self.acTurnStage + 1;					
		end

--==============================================================				
-- turn 45°
	elseif self.acTurnStage == 51 then
		angle = -self.acDimensions.maxSteeringAngle;
		moveForwards = false;					
		
		if turnAngle < -60+angleOffset then
			AutoSteeringEngine.ensureToolIsLowered( self, false )
			if self.acParameters.leftAreaActive then
				AITractor.aiRotateLeft(self);
			else
				AITractor.aiRotateRight(self);
			end
			self.acTurnStage     = self.acTurnStage + 1;					
			self.turnTimer       = self.acDeltaTimeoutNoTurn;
		end
--==============================================================				
-- wait
	elseif self.acTurnStage == 52 then
		allowedToDrive = false;						
		angle = self.acDimensions.maxSteeringAngle;
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
		end

--==============================================================				
-- move backwards (90°)	I	
	elseif self.acTurnStage == 53 then		
		angle = self.acDimensions.maxSteeringAngle;
		
		if turnAngle < -90+angleOffset then			
			angle                = math.min( math.max( 3 * math.rad( turnAngle + 90 ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
			self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
			self.acTurnStage     = self.acTurnStage + 1;					
		end
--==============================================================				
-- move backwards (0°) II
	elseif self.acTurnStage == 54 then		
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if not self.acParameters.leftAreaActive then x = -x end

		angle = math.min( math.max( 3 * math.rad( turnAngle + 90 ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
		
		if x > - stoppingDist then
			angle                = self.acDimensions.maxSteeringAngle;
			self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
			self.acTurnStage     = self.acTurnStage + 1;					
		end
--==============================================================				
-- move backwards (90°) III
	elseif self.acTurnStage == 55 then		
		angle = self.acDimensions.maxSteeringAngle;
		
		if turnAngle < -120+angleOffset then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end
--==============================================================				
-- wait
	elseif self.acTurnStage == 56 then
		allowedToDrive = false;						
		moveForwards = false;					
		angle = -self.acDimensions.maxSteeringAngle;
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
			self.acMinDetected = nil
		end

--==============================================================				
-- move backwards (90°)	I	
	elseif self.acTurnStage == 57 then		
		angle = -self.acDimensions.maxSteeringAngle;
		moveForwards = false;					

		if turnAngle > 0 or turnAngle < -180+angleOffset then
			angle                = 0
			self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
			self.acTurnStage     = self.acTurnStage + 1;					
		end
		
--==============================================================				
-- move backwards (90°)	II	
	elseif self.acTurnStage == 58 then		
		moveForwards = false;					
	
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if not self.acParameters.leftAreaActive then x = -x end
		
		if fruitsDetected then
			detected = false
			angle    = 0
			angle2   = nil
		else
			--AutoSteeringEngine.currentSteeringAngle( self );
			--AutoSteeringEngine.setChainOutside( self );
			--detected, angle2, border = AutoSteeringEngine.processChain( self );			
			detected, angle2, border = AutoTractor.detectAngle( self )
						
			if detected then
				angle  = nil
				angle2 = -angle2
			else
				angle  = 0
				angle2 = nil
			end
		end
		
		if z > self.acDimensions.toolDistance - stoppingDist then	
			if z > self.acDimensions.toolDistance + 10 then	
				AutoTractor.setAIImplementsMoveDown(self,true);
				self.acTurnStage   = self.acTurnStage + 1;					
				self.turnTimer     = self.acDeltaTimeoutRun;
			elseif detected then
				if self.acMinDetected == nil then
					self.acMinDetected = z + 1
				elseif z > self.acMinDetected then
					AutoTractor.setAIImplementsMoveDown(self,true);
					self.acTurnStage   = self.acTurnStage + 1;					
					self.turnTimer     = self.acDeltaTimeoutRun;
					self.acMinDetected = nil
				end
			end
		end

--==============================================================				
-- wait
	elseif self.acTurnStage == 59 then
		allowedToDrive = false;						
		angle = 0
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
			AutoSteeringEngine.navigateToSavePoint( self, true )
		end

		--==============================================================				
-- turn 90° II
	elseif self.acTurnStage == 60 then
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
--*********************************************************************************		
-- TODO
		local test = Utils.getNoNil( self.aseDistance , 0 )
--*********************************************************************************				
		
		--if z >= test then
		--	if fruitsDetected then
		--		AutoTractor.setAIImplementsMoveDown(self,true);
		--	end
		--elseif not detected or not fruitsDetected then
		--	AutoTractor.setAIImplementsMoveDown(self,false);
		--end
		
	--if fruitsDetected and detected and z < test - stoppingDist then
	--	self.acTurnStage   = -22 --self.acTurnStage + 1;					
		if detected and z < test - stoppingDist then
			self.acTurnStage   = -2
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
			AutoTractor.setAIImplementsMoveDown(self,true);
		elseif not detected then					
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
			angle  = nil
			angle2 = AutoTractor.navigateToSavePoint( self, true )
		else
			AutoTractor.setAIImplementsMoveDown(self,true);
		end

--==============================================================				
--==============================================================				
-- the new U-turn w/o reverse
	elseif self.acTurnStage == 70 then
		angle = 0;
		
		self.acTurnStage   = self.acTurnStage + 1;					
		self.turnTimer     = self.acDeltaTimeoutRun;

		AutoTractor.setAIImplementsMoveDown(self,false);
--==============================================================				
-- move far enough
	elseif self.acTurnStage == 71 then

		--local dist = math.max( 1, self.acDimensions.toolDistance )
		--if noReverseIndex > 0 then
		--	dist = dist + math.max( dist, self.acDimensions.toolDistance - self.acDimensions.zBack )
		--else
		--	dist = dist + dist
		--end
		--
		--dist = 1.1 * dist
		--
		--local x,z, allowedToDrive = AutoTractor.getTurnVector( self, false );
		--if self.acParameters.leftAreaActive then x = -x end
		--local turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self );
		--
		--local corr     = self.acDimensions.radius * ( 1 - math.cos( math.rad(turnAngle)))
		--local dx       = x - 2 * turn75.radius
		--if turnAngle > 0 then
		--	dx = math.min(0,dx + corr)
		--else
		--	dx = math.min(0,dx - corr)
		--end		
		--local endAngle = math.acos(math.min(math.max(  1 + dx / ( self.acDimensions.radius + turn75.radius ), 0), 1))
		--local dz       = dist + ( self.acDimensions.radius + turn75.radius ) * math.sin( endAngle )
		--
		--if turnAngle < 45 and -dx > turn75.radius - turn75.radiusT then
		--	angle = AutoTractor.getMaxAngleWithTool( self, true )
		--else
		--	angle = math.min(math.max(math.rad(turnAngle)))
		--end
		--
		--if z > dz - stoppingDist then
		--	AutoSteeringEngine.ensureToolIsLowered( self, false )
		--	if turnAngle < angleOffset then
		--		self.acTurnStage     = self.acTurnStage + 2;					
		--		self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
		--		angle                = turn75.alpha --AutoTractor.getMaxAngleWithTool( self, false )
		--	else
		--		self.acTurnStage     = self.acTurnStage + 1;					
		--		self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
		--		angle                = AutoTractor.getMaxAngleWithTool( self, false )
		--	end
		--end
	
		local dist = math.max( 1, self.acDimensions.toolDistance )
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if self.acParameters.leftAreaActive then x = -x end
		local turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self );
		
		if turnAngle < 90 - angleOffset then
			angle = AutoTractor.getMaxAngleWithTool( self, true )
		else
			angle = 0
		end
		
		local corr     = self.acDimensions.radius * ( 1 - math.cos( math.rad(turnAngle)))
		local dx       = x - 2 * turn75.radius
		if turnAngle > 0 then
			dx = math.min(0,dx + corr)
		else
			dx = math.min(0,dx - corr)
		end		
		
		if AutoTractor.acDevFeatures then
			print(string.format("T71: x: %0.3fm z: %0.3fm dx: %0.3fm (%0.3fm %0.1f° %0.3fm %0.3fm)",x, z, dx, self.acDimensions.radius, turnAngle, turn75.radius, turn75.radiusT ) )		
		end
		
		if dx > - stoppingDist then
			AutoSteeringEngine.ensureToolIsLowered( self, false )
			if turnAngle < angleOffset and x < Utils.getNoNil( self.aseActiveX, 0 ) then
				self.acTurnStage     = self.acTurnStage + 2;					
				self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
				angle                = turn75.alpha --AutoTractor.getMaxAngleWithTool( self, false )
			else
				self.acTurnStage     = self.acTurnStage + 1;					
				self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
				angle                = AutoTractor.getMaxAngleWithTool( self, false )
			end
		end
	
--==============================================================				
-- move far enough II
	elseif self.acTurnStage == 72 then

		angle = AutoTractor.getMaxAngleWithTool( self, false )
		
		if turnAngle < angleOffset then
			self.acTurnStage     = self.acTurnStage + 1;					
			self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
			local turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self );
			angle                = turn75.alpha 
		end
	
--==============================================================				
-- now turn 90°
	elseif self.acTurnStage == 73 then	

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if self.acParameters.leftAreaActive then x = -x end
		local turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self );
				
		angle = turn75.alpha --AutoTractor.getMaxAngleWithTool( self, false )
		
		if turnAngle < angleOffset-90 then
			if self.acParameters.leftAreaActive then
				AITractor.aiRotateLeft(self);
			else
				AITractor.aiRotateRight(self);
			end
			
			if x >= turn75.radius then
				self.acTurnStage     = self.acTurnStage + 1;					
				self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
				angle                = 0
			else
				self.acTurnStage = self.acTurnStage + 2;					
			end
		end

--==============================================================				
-- check distance
	elseif self.acTurnStage == 74 then	
		angle = 0

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if self.acParameters.leftAreaActive then x = -x end
		local turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self );
	
		if x < turn75.radius + 1 + stoppingDist then
			self.acTargetValue   = nil
			self.acTurnStage     = self.acTurnStage + 1;					
			self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
			angle                = turn75.alpha --AutoTractor.getMaxAngleWithTool( self, false )
		end
		
--==============================================================				
-- now turn again 90°
	elseif self.acTurnStage == 75 then	

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if self.acParameters.leftAreaActive then x = -x end
		local turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self );

		angle = turn75.alpha --AutoTractor.getMaxAngleWithTool( self, false )

		if turnAngle < angleOffset - 180 or turnAngle > 0 then
			--print(tostring(self.acTurnStage).." "..tostring(turnAngle).." "..tostring(x))
			if x > -stoppingDist then
				AutoTractor.setAIImplementsMoveDown(self,true);
				AutoSteeringEngine.setPloughTransport( self, false )
				self.acTurnStage     = self.acTurnStage + 4;					
				self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
				angle                = 0
			else
				self.acTurnStage     = self.acTurnStage + 1;					
				--self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
				angle                = turn75.alpha --AutoTractor.getMaxAngleWithTool( self, false )
			end
		end
				
--==============================================================				
-- now turn til endAngle
	elseif self.acTurnStage == 76 then	

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if self.acParameters.leftAreaActive then x = -x end
		x = x + stoppingDist
		
		local turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self );
		angle = turn75.alpha --AutoTractor.getMaxAngleWithTool( self, false )
		
		local beta      = math.rad( 180 - turnAngle )		
		local endAngle1 = math.acos(math.min(math.max(  1 + ( x + turn75.radius * ( 1 - math.cos( beta ))) /( self.acDimensions.radius + turn75.radius ), 0), 1))
		local endAngle2 = math.asin(math.min(math.max( z / ( self.acDimensions.radius + turn75.radius ), -1 ), 1 ))			
		local endAngle  = math.min( endAngle1, endAngle2 )
		--print(tostring(self.acTurnStage)..": "..tostring(turnAngle).." "..tostring(x).." "..tostring(z).." "..tostring(math.deg(endAngle1)).." "..tostring(math.deg(endAngle2)))
		
		if 0 < turnAngle and turnAngle <= 180 - math.deg( endAngle ) + angleOffset then
			self.acTurnStage     = self.acTurnStage + 1;					
			self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
			angle                = -self.acDimensions.maxSteeringAngle
		end
				
--==============================================================				
-- now turn to angle 180°
	elseif self.acTurnStage == 77 or self.acTurnStage == 78 then	
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if self.acParameters.leftAreaActive then x = -x end

		if allowedToDrive then
			if math.abs(x) > 0.2 and math.abs(z) > 0.2 and angleOffset < turnAngle and turnAngle < 180 - angleOffset then
				local r1 = x / ( 1 - math.cos( math.rad(180-turnAngle) ) )
				--local r2 = math.max( z-2, 0.2 ) / math.sin( math.rad(180-turnAngle) )
				--local r  = math.max( r2, self.acDimensions.radius )
				--if x < 0 then
				--	r = math.max( r1, -r2 )
				--else
				--	r = math.min( r1, r2 )
				--end
				local r = r1
				angle = math.atan( self.acDimensions.wheelBase / r )
				--print(tostring(self.acTurnStage)..": "..tostring(turnAngle).." "..tostring(x).." "..tostring(z).." "..tostring(r1).." "..tostring(r2).." "..tostring(r).." "..tostring(angle))
			else
				angle = -self.acDimensions.maxSteeringAngle
				--print(tostring(self.acTurnStage)..": "..tostring(turnAngle).." "..tostring(x).." "..tostring(z).." nil "..tostring(angle))
			end
			
			local nextTS = false
			if math.abs(x) <= 0.2 or math.abs(z) <= 0.2 or turnAngle < 0 or turnAngle >= 180 - angleOffset then
				nextTS = true
			elseif self.acTurnStage == 78 and turnAngle >= 160 then --180 - math.deg( angleMax ) then
				nextTS = true
			end
			
			if self.acTurnStage == 77 then
				if     noReverseIndex <= 0
						or math.abs( math.deg(AutoSteeringEngine.getToolAngle( self )) ) < 60 
						or nextTS then
					AutoTractor.setAIImplementsMoveDown(self,true);
					AutoSteeringEngine.setPloughTransport( self, false )
					self.acTurnStage     = self.acTurnStage + 1;					
				end
			end

			if nextTS then 
				self.acTurnStage     = self.acTurnStage + 1;					
				self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
				angle                = -self.acDimensions.maxSteeringAngle
				AutoSteeringEngine.navigateToSavePoint( self, true )
			end
		end
				
--==============================================================				
-- end sequence
	elseif self.acTurnStage == 79 then	
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		if self.acParameters.leftAreaActive then x = -x end
		
		if allowedToDrive then
			angle  = nil
			
			--if fruitsDetected or math.abs( turnAngle ) >= 160 then --180-math.deg( angleMax ) then-- z < stoppingDist then
			--if allowedToDrive and math.abs(x) < 0.4 and ( math.abs( turnAngle ) >= 180-math.deg( angleMax ) or fruitsDetected ) then-- z < stoppingDist then
			if     fruitsDetected
					or ( math.abs( turnAngle ) >= 170 
					 and math.abs( AutoSteeringEngine.getToolAngle( self ) ) <= ASEGlobals.maxToolAngle2 ) then
				detected, angle2, border = AutoTractor.detectAngle( self, -1 )
			else
				detected = false
			end
			
			--print(tostring(self.acTurnStage)..": "..tostring(turnAngle).." "..tostring(x).." "..tostring(z).." "..tostring(detected))
			
		--if fruitsDetected and detected then			
		--	self.acTurnStage   = -22 --self.acTurnStage + 1;					
			if detected then			
				self.acTurnStage   = -2
				self.turnTimer     = self.acDeltaTimeoutNoTurn;
				AutoTractor.setAIImplementsMoveDown(self,true);
			elseif not detected then					
				angle2 = AutoTractor.navigateToSavePoint( self, true )
			else
				AutoTractor.setAIImplementsMoveDown(self,true);
			end
		else
			angle = 0
		end
		
--==============================================================				
--==============================================================				
-- U-turn with 8-shape
	elseif self.acTurnStage == 80 then	
		self.acTurnStage   = self.acTurnStage + 1;					
		self.turnTimer     = self.acDeltaTimeoutRun;
		angle              = AutoTractor.getMaxAngleWithTool( self, false )

		AutoTractor.setAIImplementsMoveDown(self,false);
		
--==============================================================				
-- turn inside
	elseif self.acTurnStage == 81 then	
		angle              = AutoTractor.getMaxAngleWithTool( self, false )

		if turnAngle < -150 + angleOffset then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end
		
--==============================================================		
-- rotate plough		
	elseif self.acTurnStage == 82 then	
		angle                = AutoTractor.getMaxAngleWithTool( self, true )
		
		if 		 turnAngle > -90 - angleOffset - angleOffset
				or math.abs( AutoSteeringEngine.getToolAngle( self ) ) <= ASEGlobals.maxToolAngle2 then
			self.acTurnStage     = self.acTurnStage + 1;					
			if self.acParameters.leftAreaActive then
				AITractor.aiRotateLeft(self);
			else
				AITractor.aiRotateRight(self);
			end
		end

--==============================================================				
-- turn outside I
	elseif self.acTurnStage == 83 then	
		angle              = AutoTractor.getMaxAngleWithTool( self, true )			

		if turnAngle > -90 - angleOffset then
			local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
			local turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self );
			if math.abs(x) > self.acDimensions.distance - turn75.radius - stoppingDist then
			--self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
				angle                = 90 + turnAngle
				self.acTurnStage     = self.acTurnStage + 1;					
				self.turnTimer       = self.acDeltaTimeoutRun;
			else
				self.acTurnStage   = self.acTurnStage + 2
				self.turnTimer     = self.acDeltaTimeoutRun;
			end
			AutoSteeringEngine.setPloughTransport( self, false )
		end

--==============================================================				
-- move far enough
	elseif self.acTurnStage == 84 then	
		angle = 90 + turnAngle

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		local turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self );
		if math.abs(x) > self.acDimensions.distance - turn75.radius + stoppingDist then
		--self.waitForTurnTime = self.acDeltaTimeoutRun + g_currentMission.time
			angle                = AutoTractor.getMaxAngleWithTool( self, true )		
			self.acTurnStage     = self.acTurnStage + 1;					
			self.turnTimer       = self.acDeltaTimeoutRun;
		end
		
--==============================================================				
-- turn outside II
	elseif self.acTurnStage == 85 then	
		angle              = AutoTractor.getMaxAngleWithTool( self, true )			

		if turnAngle > 90 then
			self.acTurnStage     = self.acTurnStage + 1					
			self.turnTimer       = self.acDeltaTimeoutRun
		end

--==============================================================				
-- turn 90°
	elseif self.acTurnStage == 86 then
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
--*********************************************************************************		
-- TODO
		local test= Utils.getNoNil( self.aseDistance , 0 )
--*********************************************************************************				
		
		detected  = false
		local nav = true
		if     fruitsDetected
				or ( math.abs( turnAngle ) >= 170 
				 and math.abs( AutoSteeringEngine.getToolAngle( self ) ) <= ASEGlobals.maxToolAngle2 ) then
	--if math.abs( turnAngle ) >= 180-math.deg( angleMax ) then
			nav = false
			detected, angle2, border = AutoTractor.detectAngle( self )
		end		
		
		if AutoTractor.acDevFeatures then
			print(string.format("T84: x: %0.3fm z: %0.3fm test: %0.3fm fd: %s det: %s ta: %0.1f° to: %0.1f°", x, z, test, tostring(fruitsDetected), tostring(detected), turnAngle, math.deg(AutoSteeringEngine.getToolAngle( self )) ) )
		end
		
		if detected then
			self.acTurnStage   = -2
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
			AutoTractor.setAIImplementsMoveDown(self,true);
		elseif nav or z < math.min( 0, test ) - 5 then
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
			angle  = nil
			angle2 = AutoTractor.navigateToSavePoint( self, true )
		end
			
			
--==============================================================				
--==============================================================				
-- searching...
	elseif ( -3 <= self.acTurnStage and self.acTurnStage < 0 )
			or (-13 <= self.acTurnStage and self.acTurnStage < -10 )then
		moveForwards     = true;

		if self.acTurnStage >= -3 then
			if self.acImplementsMoveDown then
			--nothing
			else
				AutoTractor.setAIImplementsMoveDown(self,true);
			end
		end
				
		if fruitsDetected and self.acTurnStage >= -3 then
			self.acTurnStage = self.acTurnStage -20;
			self.turnTimer   = self.acDeltaTimeoutNoTurn;
		
		elseif fruitsDetected and detected then
			if self.acClearTraceAfterTurn then
				AutoSteeringEngine.clearTrace( self );
				AutoSteeringEngine.saveDirection( self, false );
			end
			AutoSteeringEngine.ensureToolIsLowered( self, true )
			self.acTurnStage        = 0;
			self.acTurn2Outside     = false;
			self.turnTimer          = self.acDeltaTimeoutNoTurn;
			self.acTurnOutsideTimer = math.max( self.turnTimer, self.acDeltaTimeoutNoTurn );
			self.aiRescueTimer      = self.acDeltaTimeoutStop;
		end;
		
--==============================================================				
	elseif -23 <= self.acTurnStage and self.acTurnStage < -20 then
		--allowedToDrive = false;
		
		--if self.turnTimer < 0 then
			AutoSteeringEngine.ensureToolIsLowered( self, true )
			self.acTurnStage = self.acTurnStage + 10;					
		--end;
				
--==============================================================				
-- threshing...					
	elseif self.acTurnStage == 0 then		
		moveForwards = true;
		
		local doTurn = false;
		local uTurn  = false;
		
		local turnTimer = self.turnTimer
		if fruitsDetected and self.acTurn2Outside then
			turnTime = self.acTurnOutsideTimer 
		end
		--	turnTimer = turnTimer - self.acTurnOutsideTimer + self.acDeltaTimeoutRun
		--end
		
		if  detected then
			doTurn = false
			self.turnTimer = math.max( turnTimer, self.acDeltaTimeoutRun )
		elseif  fruitsDetected 
				and not self.acTurn2Outside then
			doTurn = false
	--elseif  AutoSteeringEngine.getTraceLength(self) < 3 then
	--	doTurn = false
		elseif self.acTurn2Outside and turnTimer < 0 then
			doTurn = true
			uTurn = false
			self.acClearTraceAfterTurn = false
		elseif turnTimer < 0 then 
			if     AutoSteeringEngine.getTraceLength(self) < 10 then		
				doTurn = true
				uTurn = false
				self.acClearTraceAfterTurn = false
			else
				doTurn = true
				uTurn = self.acParameters.upNDown
				self.acClearTraceAfterTurn = true
			end
		end
		
		if doTurn then		
			angle  = 0
			
			AutoSteeringEngine.initTurnVector( self, uTurn )

			if not self.acTurn2Outside then 
				local dist    = math.floor( 2.5 * math.max( 10, self.acDimensions.distance ) )
				local wx,_,wz = AutoSteeringEngine.getAiWorldPosition( self )
				local stop    = true
				local lx,lz
				for i=0,dist do
					for j=0,dist do
						for k=1,4 do
							if     k==1 then 
								lx = wx + i
								lz = wz + j
							elseif k==2 then
								lx = wx - i
								lz = wz + j
							elseif k==3 then
								lx = wx + i
								lz = wz - j
							else
								lx = wx - i
								lz = wz - j
							end
							if      AutoSteeringEngine.isChainPointOnField( self, lx-0.5, lz-0.5 ) 
									and AutoSteeringEngine.isChainPointOnField( self, lx-0.5, lz+0.5 ) 
									and AutoSteeringEngine.isChainPointOnField( self, lx+0.5, lz-0.5 ) 
									and AutoSteeringEngine.isChainPointOnField( self, lx+0.5, lz+0.5 ) 
									then
								local x = lx - 0.5
								local z1= lz - 0.5
								local z2= lz + 0.5
								if AutoSteeringEngine.hasFruitsSimple( self, x,z1,x,z2, 1 ) then
									stop = false
									break
								end
							end
						end
					end
				end
						
				if stop then
					AITractor.stopAITractor(self)
					return
				end
			end
			
			if     uTurn               then
		-- the U turn
				--invert turn angle because we will swap left/right in about 10 lines
				
				self.acTurn2Outside = false
				turnAngle = -turnAngle;
				if     self.acTurnMode == "O" then				
					self.acTurnStage = 70				
				elseif self.acTurnMode == "8" then
					self.acTurnStage = 80				
				elseif self.acTurnMode == "A" then
					self.acTurnStage = 50;
				elseif self.acTurnMode == "Y" then
					self.acTurnStage = 40;
				else
					self.acTurnStage = 20;
					
					if noReverseIndex > 0 and AutoSteeringEngine.noTurnAtEnd( self ) then
						self.acTurn2Outside = true
					end
				end
				self.turnTimer = self.acDeltaTimeoutWait;
				self.waitForTurnTime = g_currentMission.time + self.turnTimer;
				if self.acTurnStage == 20 and self.acTurn2Outside then
				else
					self.acParameters.leftAreaActive  = not self.acParameters.leftAreaActive;
					self.acParameters.rightAreaActive = not self.acParameters.rightAreaActive;
					AutoTractor.sendParameters(self);
				end					
				AutoSteeringEngine.setChainStraight( self );	
			elseif self.acTurn2Outside then
		-- turn to outside because we are in the middle of the field
				self.acTurnStage = 1;
				self.turnTimer = self.acDeltaTimeoutWait;
			elseif self.acTurnMode == "C" 
					or self.acTurnMode == "8" 
					or self.acTurnMode == "O" then
		-- 90° turn w/o reverse
				self.aiRescueTimer  = 3 * self.acDeltaTimeoutStop;
				self.acTurnStage = 5;
				self.turnTimer = self.acDeltaTimeoutWait;
				self.waitForTurnTime = g_currentMission.time + self.turnTimer;
				--if not self.acParameters.upNDown
				--		or AutoSteeringEngine.getTraceLength(self) < 10 then
					self.acTurn2Outside = false
				--else
				--	self.acTurn2Outside = true
				--	self.acParameters.leftAreaActive  = not self.acParameters.leftAreaActive;
				--	self.acParameters.rightAreaActive = not self.acParameters.rightAreaActive;
				--	AutoTractor.sendParameters(self);
				--end
			elseif self.acTurnMode == "L" 
					or self.acTurnMode == "A" 
					or self.acTurnMode == "Y" then
		-- 90° turn with reverse
				self.acTurnStage = 1;
				self.turnTimer = self.acDeltaTimeoutWait;
			else
		-- 90° turn with reverse
				self.acTurnStage = 30;
				self.turnTimer = self.acDeltaTimeoutWait;
			end
		elseif detected then --and fruitsDetected then
			AutoSteeringEngine.saveDirection( self, true );
			self.turnTimer   	      = math.max(self.turnTimer,self.acDeltaTimeoutRun);
			self.acTurnOutsideTimer = math.max( self.acTurnOutsideTimer, self.acDeltaTimeoutNoTurn );
			self.aiRescueTimer      = self.acDeltaTimeoutStop;
		elseif  fruitsDetected 
				and not self.acTurn2Outside then
			AutoSteeringEngine.saveDirection( self, true );
		end
		
--==============================================================				
--==============================================================				
-- error!!!
	else
		allowedToDrive = false;						
		self.atHud.InfoText = string.format(AutoTractorHud.getText("AC_COMBINE_ERROR")..": %i",self.acTurnStage);
		print(self.atHud.InfoText);
		AITractor.stopAITractor(self);
		return;
	end;                

--==============================================================				
--==============================================================				
	if math.abs( self.acAxisSide ) > 0.1 then --if AutoTractor.acDevFeatures and math.abs( self.acAxisSide ) > 0.3 then 
		detected = false
		border   = 0
		angle    = nil
		angle2   = - self.acAxisSide * self.acDimensions.maxSteeringAngle
		self.turnTimer = self.turnTimer + dt;
		self.waitForTurnTime = self.waitForTurnTime + dt;
		if self.acTurnStage <= 0 then
			self.aiRescueTimer = self.aiRescueTimer + dt;
		end			
	end			
--==============================================================				
--==============================================================				

	if      not self.acImplementsMoveDown 
			and ( not moveForwards or not allowedToDrive ) then
		AutoSteeringEngine.ensureToolIsLowered( self, false )
	end
			
--==============================================================				
	

	if     self.acTurnStage == -3 and detected then
		AutoTractor.setStatus( self, 2 )
	elseif self.acTurnStage == -3 then
		AutoTractor.setStatus( self, 0 )
	elseif  detected
			and ( self.acTurnStage <= 0
				 or self.acTurnStage == 27
 				 or self.acTurnStage == 36
	 			 or self.acTurnStage == 38
		 		 or self.acTurnStage == 49 
				 or self.acTurnStage == 58 
				 or self.acTurnStage == 60 
				 or self.acTurnStage == 79 ) then	
		AutoTractor.setStatus( self, 1 )
	elseif self.acTurnStage <= 0 then
		AutoTractor.setStatus( self, 2 )
	elseif detected then
		AutoTractor.setStatus( self, 2 )
	else
		AutoTractor.setStatus( self, 0 )
	end
	
	local acceleration   = 0;					
	local slowAngleLimit = self.acDimensions.maxLookingAngle;
	local useReduceSpeed = false;
	
	if self.isMotorStarted and speedLevel ~= 0 and self.fuelFillLevel > 0 then
		acceleration = 1.0;
	end;		
	
	if speedLevel == 0 then
		allowedToDrive = false
		speedLevel     = 1
	elseif self.acTurnStage > 0 
			or ( not detected and self.acTurnStage >= -2 ) then
		speedLevel = 4
		slowAngleLimit = self.acDimensions.maxSteeringAngle;
	end;
	
	if not allowedToDrive then
		self.acHighPrec = false
	end
	
	if self.acTurnStage > 0 then
		detected = false;
	end
	
	if angle == nil then
		if angle2 == nil then
			angle = 0;
		else
			angle = angle2;
		end
	elseif not self.acParameters.leftAreaActive then
		angle = -angle;		
	end
	
	if self.acLastSteeringAngle == nil then
		self.acLastSteeringAngle = angle 
	end
	
	if AutoTractor.acDevFeatures then
		self.atHud.InfoText = self.atHud.InfoText .. string.format(" a: %3i ",math.deg(angle))..tostring(detected)
	end

	local aiSteeringSpeed = self.aiSteeringSpeed;
	if detected and 
			--(  math.abs( angle ) > 0.5 * angleMax
			--or math.abs( angle - AutoSteeringEngine.currentSteeringAngle( self ) )  > 0.25 * angleMax
			(  math.abs( angle ) > 0.5 * self.acDimensions.maxSteeringAngle
			or math.abs( angle - AutoSteeringEngine.currentSteeringAngle( self ) )  > 0.25 * self.acDimensions.maxSteeringAngle
			--or self.acTurnStage == -3
			--or self.acTurnStage == -13
			--or -3 <= self.acTurnStage and self.acTurnStage < 0 ) then
			) then
		detected = false
	end	
	
	if not detected and 0 < speedLevel and speedLevel < 4 then
		speedLevel = 4
	elseif speedLevel ~= 2 and speedLevel ~= 3 and speedLevel ~= 4 then
		speedLevel = 1
	end
		
	if     speedLevel == 4 then
		aiSteeringSpeed = 0.5 * aiSteeringSpeed
	else
		aiSteeringSpeed = math.max( 1, speedLevelFactor ) * aiSteeringSpeed
	end
	
	angle = math.min( math.max( angle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
	
	if AutoTractor.acDevFeatures then
		self.atHud.InfoText = self.atHud.InfoText .." "..tostring(allowedToDrive).." "..tostring(moveForwards).." "..tostring(speedLevel)
	end

	AutoSteeringEngine.steer( self, dt, angle, aiSteeringSpeed, detected );
	AutoSteeringEngine.drive( self, dt, acceleration, allowedToDrive, moveForwards, speedLevel, useReduceSpeed, 0.75 );
	
  local colDirX = math.sin( angle );
	local colDirZ = math.cos( angle );

	if not moveForwards then
		colDirZ = -colDirZ;
	end

	if self.acParameters.inverted then
		colDirX = -colDirX;
		colDirZ = -colDirZ;
	end

	for triggerId, _ in pairs(self.numCollidingVehicles) do
		AIVehicleUtil.setCollisionDirection(self.aiTractorDirectionNode, triggerId, colDirX, colDirZ)
	end

end

------------------------------------------------------------------------
-- AutoTractor:navigateToSavePoint
------------------------------------------------------------------------
function AutoTractor:navigateToSavePoint()
	local angle2, onTrack = AutoSteeringEngine.navigateToSavePoint( self, true, AutoTractor.navigationFallbackRetry )
	if onTrack then
		self.turnTimer     = self.acDeltaTimeoutNoTurn;
		AutoTractor.setAIImplementsMoveDown(self,true);
	elseif g_currentMission.time > self.turnTimer then
		AutoTractor.setAIImplementsMoveDown( self, false )
		AutoSteeringEngine.ensureToolIsLowered( self, false )
		AutoSteeringEngine.setPloughTransport( self, false )
	end			
	
	return angle2
end

------------------------------------------------------------------------
-- AutoTractor:navigationFallbackRetry
------------------------------------------------------------------------
function AutoTractor:navigationFallbackRetry( uTurn )
	local x, z, allowedToDrive = AutoTractor.getTurnVector( self, uTurn )
	local a = AutoSteeringEngine.normalizeAngle( math.pi - AutoSteeringEngine.getTurnAngle( self )	)
	local angle = 0

	if z < 1 and math.abs( a ) > 0.9 * math.pi then
		angle = 0
	elseif x > 0 then
		-- D: turn away from target point for next try
		angle = -self.acDimensions.maxSteeringAngle
	else
		-- E: turn away from target point for next try
		angle =  self.acDimensions.maxSteeringAngle
	end
	
	return angle
end

------------------------------------------------------------------------
-- AutoTractor:navigationFallbackRotate
------------------------------------------------------------------------
function AutoTractor:navigationFallbackRotateMinus( uTurn )
	local angle = -self.acDimensions.maxSteeringAngle					
	if not self.acParameters.leftAreaActive then
		angle = -angle;		
	end	
	return angle
end
------------------------------------------------------------------------
-- AutoTractor:navigationFallbackRetry
------------------------------------------------------------------------
function AutoTractor:navigationFallback75( uTurn )

	local x, z, allowedToDrive = AutoTractor.getTurnVector( self, uTurn )
	if self.acParameters.leftAreaActive then x = -x end
	
	local angle = 0
	
	local turnAngle = math.deg( AutoSteeringEngine.getTurnAngle( self ) )
	if math.abs(x) > 0.2 and math.abs(turnAngle)<170 then
		local r = x / ( 1 - math.cos( math.rad(180-turnAngle) ) )
		angle   = math.atan( self.acDimensions.wheelBase / r )
	elseif x >  0.2 then
		angle   = AutoTractor.getMaxAngleWithTool( self, false )
	elseif x < -0.2 then
		angle   = AutoTractor.getMaxAngleWithTool( self, true )
	else
		angle   = -math.rad( 180 - turnAngle )
	end
	
	if not self.acParameters.leftAreaActive then
		angle = -angle;		
	end	
	return angle
end

------------------------------------------------------------------------
-- AutoTractor:getTurnVector
------------------------------------------------------------------------
function AutoTractor:getTurnVector( uTurn )

	local x, z = AutoSteeringEngine.getTurnVector( self, Utils.getNoNil( uTurn, false ) )
 
	return x, z, true
end

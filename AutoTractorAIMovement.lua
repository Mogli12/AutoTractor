------------------------------------------------------------------------
-- AutoTractor:detectAngle
------------------------------------------------------------------------
function AutoTractor:detectAngle( dt, smooth )

	local wx,_,wz  = getWorldTranslation( self.acRefNode )
	local buffered = false
	local lsq      = 99
	
	if not ( self.acLast   == nil
				or self.acLast.t ~= self.acTurnStage
			--or ( smooth ~= nil and smooth < 0 )
				or ( ( smooth == nil or smooth <= 0 ) and self.acLast.s > 0 ) ) then
		lsq = Utils.vector2LengthSq( self.acLast.x - wx, self.acLast.z - wz )
		if      lsq < 0.0025 then
			AutoTractor.statEvent( self, "t1", dt )
			buffered = true
		elseif  self.acLast.detected 					
				and self.acLast.angle2 + self.acLast.angle2 < self.acDimensions.maxLookingAngle 
				and lsq < 0.25 then
			AutoTractor.statEvent( self, "t2", dt )
			buffered = true
		elseif  self.acLast.detected 					
				and self.acLast.angle2 + self.acLast.angle2 < self.acDimensions.maxLookingAngle 
				and lsq < 1 
				and AutoSteeringEngine.getAllChainBorders( self ) < 1 then
			AutoTractor.statEvent( self, "t3", dt )
			buffered = true
		end
	end
	if buffered then
		AutoTractor.statEvent( self, "t4", dt )
	else
		self.acLast = {}
		self.acLast.t = self.acTurnStage
		self.acLast.s = math.min( math.max( Utils.getNoNil( smooth, 0 ), 0 ), 1 )
		self.acLast.x = wx
		self.acLast.z = wz
		AutoSteeringEngine.currentSteeringAngle( self )
		AutoSteeringEngine.setChainOutside( self, 1, ASEGlobals.angleSafety * ( 1- self.acLast.s ) )
		self.acLast.detected, self.acLast.angle2, self.acLast.border = AutoSteeringEngine.processChain( self );			
		
		if self.acLast.s > 0 and not self.acLast.detected then
			self.acLast.s = 0
			AutoSteeringEngine.setChainOutside( self );
			self.acLast.detected, self.acLast.angle2, self.acLast.border = AutoSteeringEngine.processChain( self );			
		end
	end
	
	return self.acLast.detected, self.acLast.angle2, self.acLast.border
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
		angle = -self.acDimensions.maxSteeringAngle + math.min( math.max( -toolAngle - 1.309, 0 ), 0.5 * self.acDimensions.maxSteeringAngle );	-- 75° => 1,3089969389957471826927680763665
	else
		angle =  self.acDimensions.maxSteeringAngle - math.min( math.max(  toolAngle - 1.309, 0 ), 0.5 * self.acDimensions.maxSteeringAngle );	-- 75° => 1,3089969389957471826927680763665
	end
	
	return angle
end

------------------------------------------------------------------------
-- AICombine:updateAIMovement
------------------------------------------------------------------------
function AutoTractor:newUpdateAIMovement( superFunc, dt, ... )

	if self.acPause then return end
		
	if not self.isServer or self.acParameters == nil or not self.acParameters.enabled then
		return superFunc( self, dt, ... );
	end
	
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
	
	local allowedToDrive =  AutoSteeringEngine.checkAllowedToDrive( self )
	
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
			self.acAnimWaitTimer = self.acDeltaTimeoutStart
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
				 or self.acTurnStage == 38
				 or self.acTurnStage == 49
				 or self.acTurnStage == 60 
				 or self.acTurnStage == 79 ) 
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
	
	if self.waitForTurnTime > self.time then
		if self.acLastSteeringAngle ~= nil then
			local a = AutoSteeringEngine.currentSteeringAngle( self, self.acParameters.inverted )
			if math.abs( self.acLastSteeringAngle - a ) < 0.025 then
				self.waitForTurnTime = 0
			end
		end
	end
	
	if self.waitForTurnTime > self.time then
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
		--print("waiting: "..tostring( self.waitForTurnTime - self.time ))
	end
	
	local speedLevel = 1;
	if self.speed2Level ~= nil and 0 <= self.speed2Level and self.speed2Level <= 4 then
		speedLevel = self.speed2Level;
	end
	
-- Speed level always 1 while turning	
	if self.acTurnStage ~= 0 and 0 < speedLevel and speedLevel < 4 then
		speedLevel = 1
	end

	if not allowedToDrive or speedLevel == 0 then
		--print("not allowed to drive: "..tostring(allowedToDrive).." "..tostring(speedLevel));
		AutoTractor.statEvent( self, "tS", dt )
		AutoSteeringEngine.drive( self, dt, 0, false, true, 0 );
		return
	end
	
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
	local angleOffset = 8;
	local stoppingDist = 0.2;
	if self.isRealistic then
		angleOffset  = 4;
		stoppingDist = 1;
	end
--==============================================================		
--==============================================================		
	local turnAngle = math.deg(AutoSteeringEngine.getTurnAngle(self));
	local traceLength = AutoSteeringEngine.getTraceLength(self)

	if AutoTractor.acDevFeatures then
		self.mogliInfoText = string.format( "Turn stage: %2i, angle: %3i",self.acTurnStage,turnAngle )
	end

	if self.acParameters.leftAreaActive then
		turnAngle = -turnAngle;
	end;

	fruitsDetected = AutoSteeringEngine.hasFruits( self, 0.9 )
	
	noReverseIndex = AutoSteeringEngine.getNoReverseIndex( self );

--==============================================================				
	if self.acTurnStage <= 0 then
		self.acSavedMarker = nil
		self.acMarkerWait  = nil
		self.uDuringUTurn  = nil
		
		local smooth = 0
		if self.acTurnStage == 0 and traceLength > 3 and fruitsDetected then
			smooth = math.min( math.max( 0.1 * ( traceLength - 1 ), 0 ), 0.750 )
		end

		detected, angle2, border = AutoTractor.detectAngle( self, dt, smooth )
		
		self.acTurn2Outside = border > 0;
		
		if not detected then
			if self.acTurn2Outside and self.acTurnStage == 0 then
				angle = angleMax
			elseif self.acTurn2Outside then
				angle = self.acDimensions.maxSteeringAngle
			elseif self.acTurnStage == -3 or self.acTurnStage == -13 or self.acTurnStage == -23 then
				if self.acParameters.leftAreaActive then
					angle = -angle2;		
				else
					angle = -angle2;		
				end
				angle = math.max( 0, angle2 );
			elseif self.acTurnStage == -2 or self.acTurnStage == -12 or self.acTurnStage == -22 then
				angle  = nil
				angle2 = AutoSteeringEngine.navigateToSavePoint( self, true, AutoTractor.navigationFallbackRetry )

			elseif self.acTurnStage < 0 then --self.acTurnStage == -1 or self.acTurnStage == -11 or self.acTurnStage == -21 then
				angle = -self.acDimensions.maxSteeringAngle					
			else--if self.acParameters.upNDown or self.acParameters.frontPacker or  AutoSteeringEngine.noTurnAtEnd( self ) then
				angle = math.min( math.max( math.rad( turnAngle ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
			--else
			--	angle = -angleMax					
			end
		end
--==============================================================				
	elseif self.acTurnStage == 8 then	
		AutoSteeringEngine.currentSteeringAngle( self );
		AutoSteeringEngine.setChainStraight( self );			
		border = AutoSteeringEngine.getAllChainBorders( self );
		if border > 0 then detected = true end
	
--==============================================================				
	elseif self.acTurnStage == 27
			or self.acTurnStage == 36
			or self.acTurnStage == 38
			or self.acTurnStage == 49 then

		self.acSavedMarker = nil		
		detected, angle2, border = AutoTractor.detectAngle( self, dt )

--==============================================================				
	elseif self.acTurnStage == 60 then	

		self.acSavedMarker = nil		
		detected, angle2, border = AutoTractor.detectAngle( self, dt )
		
--==============================================================				
-- backwards
	elseif self.acTurnStage == 4 then

		detected, angle2, border = AutoTractor.detectAngle( self, dt )

	elseif self.acTurnStage == 3 then
		if self.acParameters.leftAreaActive == self.acTurn2Outside then
			AutoSteeringEngine.setSteeringAngle( self, -angleMax );
		else
			AutoSteeringEngine.setSteeringAngle( self, angleMax );
		end
		if self.acTurn2Outside then
			AutoSteeringEngine.setChainOutside( self );		
		elseif self.acParameters.leftAreaActive then
			AutoSteeringEngine.setChainStraight( self, 1, angleMax )		
		else
			AutoSteeringEngine.setChainStraight( self, 1,-angleMax )		
		end
		
		border = AutoSteeringEngine.getAllChainBorders( self );
		--end
		
		if self.acTurn2Outside then
			detected = border < 1
		else
			detected = border > 0
		end
	else
		AutoSteeringEngine.setChainContinued( self );
	end

--==============================================================						
--==============================================================		
-- move far enough			
	if     self.acTurnStage == 1 then

		AutoTractor.setAIImplementsMoveDown(self,false);
		
		if turnAngle > -angleOffset then
			angle = self.acDimensions.maxSteeringAngle;
		else
			angle = 0;
		end

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, false );
		if self.acTurn2Outside or z > self.acDimensions.radius - stoppingDist then
			AutoSteeringEngine.ensureToolIsLowered( self, false )
			self.acTurnStage   = self.acTurnStage + 1;
			self.turnTimer     = self.acDeltaTimeoutWait;
			allowedToDrive     = false;				
			self.waitForTurnTime = self.time + self.turnTimer;
		end

--==============================================================				
-- going back I
	elseif self.acTurnStage == 2 then
		
		moveForwards   = false;					
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, false );
		angle = -math.min( math.max( math.rad( turnAngle ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
		
		if self.acTurn2Outside and x*x+z*z > 100 then
			self.acTurnStage = self.acTurnStage + 2;
			self.turnTimer = self.acDeltaTimeoutNoTurn
		elseif z < self.acDimensions.radius + stoppingDist then
			self.acTurnStage = self.acTurnStage + 1;
		end

		if noReverseIndex > 0 and self.acTurn2Outside then			
			local toolAngle = AutoSteeringEngine.getToolAngle( self );			
			angle  = nil;
			angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		end

--==============================================================				
-- going back II
	elseif self.acTurnStage == 3 then

		moveForwards = false;			
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, false );

		if self.acTurn2Outside and x*x+z*z > 100 then
			self.acTurnStage = self.acTurnStage + 1;
			self.turnTimer = self.acDeltaTimeoutNoTurn
		elseif detected then
			angle                = 0
			self.acTurnStage     = -1
			self.waitForTurnTime = self.time + self.acDeltaTimeoutWait
		elseif self.acTurn2Outside then
			angle = -self.acDimensions.maxSteeringAngle
			if math.abs( turnAngle ) > 30 then
				self.acTurnStage = self.acTurnStage + 1;
				self.turnTimer = self.acDeltaTimeoutNoTurn
			end
		else
			angle = self.acDimensions.maxSteeringAngle
			if math.abs( turnAngle ) > 80 then
				self.acTurnStage = self.acTurnStage + 1;
				self.turnTimer = self.acDeltaTimeoutNoTurn
			end
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
		
		if not detected then
			if self.acTurn2Outside then
				angle = -self.acDimensions.maxSteeringAngle
			else
				angle = self.acDimensions.maxSteeringAngle
			end
		end
		
		if noReverseIndex > 0 and self.acTurn2Outside then			
			local toolAngle = AutoSteeringEngine.getToolAngle( self );			
			angle  = nil;
			angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		end
						
		if     detected
				or self.turnTimer < 0 then
			if not detected then
				angle = 0
				if AutoTractor.acDevFeatures then
					print("time out: "..tostring(self.acDeltaTimeoutStart))
				end
			end
				
			self.acTurnStage     = -1
			self.waitForTurnTime = self.time + self.acDeltaTimeoutWait
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
		
		self.acSavedMarker = true
		self.uDuringUTurn  = true	
		
		AutoTractor.setAIImplementsMoveDown(self,false);
				
--==============================================================				
-- move far enough if tool is in front
	elseif self.acTurnStage == 21 then
		angle = 0;

		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
		
		local dist = math.max( 0, self.acDimensions.toolDistance )
		if noReverseIndex > 0 then
			dist = math.max( dist, self.acDimensions.toolDistance - self.acDimensions.zBack )
		end
		turn75 = AutoSteeringEngine.getMaxSteeringAngle75( self )
		dist = dist + math.max( 1, self.acDimensions.radius - turn75.radiusT )
		
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
			
			self.acMarkerWait = true
			
			local x,z, allowedToDrive = AutoTractor.getTurnVector( self, true );
			if self.acParameters.leftAreaActive then x = -x end

			if self.acTurn2Outside then x = -x end
			x = x - 1 - self.acDimensions.radius -- + math.max( 0, self.acDimensions.radius - turn75.radiusT )
			
			if self.acParameters.leftAreaActive then
				AITractor.aiRotateLeft(self);
			else
				AITractor.aiRotateRight(self);
			end
			
			if x > -stoppingDist or z < 0 then
      -- no need to drive backwards
				self.acTurnStage     = 26
				angle                = 0
				self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
				self.turnTimer       = 0
			else
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
		x = x - 1 - self.acDimensions.radius

		if allowedToDrive and ( x > -stoppingDist or z < 0 ) then
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
			
			AutoSteeringEngine.navigateToSavePoint( self, true )			
			AutoSteeringEngine.setPloughTransport( self, false )--, true )
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
		
		if      self.acTurn2Outside 
				and not ( math.abs( turnAngle ) >= 180-math.deg( angleMax ) or fruitsDetected ) then
			detected = false
		end
		
		if fruitsDetected and detected and z < test and math.abs( turnAngle ) >= 135 then
			self.acTurnStage   = -22 --self.acTurnStage + 1;					
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
		--self.waitForTurnTime = self.time + self.turnTimer;

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

		local _,z, allowedToDrive = AutoTractor.getTurnVector( self );
		
		local wx,_,wz = getWorldTranslation( self.acRefNode );
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
		
		if turnAngle - 0.7 * math.deg( toolAngle ) > 45-angleOffset then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================			
-- move forwards and reduce tool angle	
	elseif self.acTurnStage == 34 then
		angle  = nil;
		local toolAngle = AutoSteeringEngine.getToolAngle( self );		
		angle2 = math.min( math.max( -toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );

		if math.abs(math.deg(toolAngle)) < 5 then
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
		
		if z < -1 or ( detected and z < 0.5 * self.acDimensions.distance ) then				
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

		self.acSavedMarker = true
		self.uDuringUTurn  = true	
		
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
			self.acMarkerWait  = true
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
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
			self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
			self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
		
		if fruitsDetected and detected and z < test then
			self.acTurnStage   = -22 --self.acTurnStage + 1;					
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

		self.acSavedMarker = true
		self.uDuringUTurn  = true	
		
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
			self.acMarkerWait  = true
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutNoTurn;
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
			self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
			self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
			self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
			self.acSavedMarker = nil		
			detected, angle2, border = AutoTractor.detectAngle( self, dt )
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
		
		if fruitsDetected and detected and z < test - stoppingDist then
			self.acTurnStage   = -22 --self.acTurnStage + 1;					
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

		self.acSavedMarker = true
		self.uDuringUTurn  = true			

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
		--		self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
		--		angle                = turn75.alpha --AutoTractor.getMaxAngleWithTool( self, false )
		--	else
		--		self.acTurnStage     = self.acTurnStage + 1;					
		--		self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
		--		angle                = AutoTractor.getMaxAngleWithTool( self, false )
		--	end
		--end
	
		local dist = math.max( 1, self.acDimensions.toolDistance )
		local x,z, allowedToDrive = AutoTractor.getTurnVector( self, false );
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
		
		if dx > - stoppingDist then
			AutoSteeringEngine.ensureToolIsLowered( self, false )
			if turnAngle < angleOffset then
				self.acTurnStage     = self.acTurnStage + 2;					
				self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
				angle                = turn75.alpha --AutoTractor.getMaxAngleWithTool( self, false )
			else
				self.acTurnStage     = self.acTurnStage + 1;					
				self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
				angle                = AutoTractor.getMaxAngleWithTool( self, false )
			end
		end
	
--==============================================================				
-- move far enough II
	elseif self.acTurnStage == 72 then

		angle = AutoTractor.getMaxAngleWithTool( self, false )

		if turnAngle < angleOffset then
			self.acTurnStage     = self.acTurnStage + 1;					
			self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
			self.acMarkerWait = true
			
			if x >= turn75.radius then
				self.acTurnStage     = self.acTurnStage + 1;					
				self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
			self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
				self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
				angle                = 0
			else
				self.acTurnStage     = self.acTurnStage + 1;					
				--self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
			self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
				self.waitForTurnTime = self.acDeltaTimeoutRun + self.time
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
			
			if fruitsDetected or math.abs( turnAngle ) >= 160 then --180-math.deg( angleMax ) then-- z < stoppingDist then
			--if allowedToDrive and math.abs(x) < 0.4 and ( math.abs( turnAngle ) >= 180-math.deg( angleMax ) or fruitsDetected ) then-- z < stoppingDist then
				detected, angle2, border = AutoTractor.detectAngle( self, dt, -1 )
			else
				detected = false
			end
			
			--print(tostring(self.acTurnStage)..": "..tostring(turnAngle).." "..tostring(x).." "..tostring(z).." "..tostring(detected))
			
			if fruitsDetected and detected then			
				self.acTurnStage   = -22 --self.acTurnStage + 1;					
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
		allowedToDrive = false;
		
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
			turnTimer = math.max( turnTimer, self.acTurnOutsideTimer );
		end
		
		if  detected then
			doTurn = false
		elseif  fruitsDetected 
				and not self.acTurn2Outside then
			doTurn = false
		elseif  traceLength < 1 then
			doTurn = false
		elseif  turnTimer   < 0 then
			doTurn = true
			if     self.acTurn2Outside 
					or traceLength < 10 then		
				uTurn = false
				self.acClearTraceAfterTurn = false
			else
				uTurn = self.acParameters.upNDown
				self.acClearTraceAfterTurn = true
			end
		end
		
		if doTurn then
			local dist    = math.floor( 2.5 * math.max( 10, self.acDimensions.distance ) )
			local wx,_,wz = getWorldTranslation( self.acRefNode )
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
			
			if     uTurn               then
		-- the U turn
				--invert turn angle because we will swap left/right in about 10 lines
				
				self.acTurn2Outside = false
				turnAngle = -turnAngle;
				if     self.acTurnMode == "O" then				
					self.acTurnStage = 70				
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
				self.waitForTurnTime = self.time + self.turnTimer;
				if self.acTurnStage ~= 20 or not self.acTurn2Outside then
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
					or self.acTurnMode == "O" then
		-- 90° turn w/o reverse
				self.aiRescueTimer  = 3 * self.acDeltaTimeoutStop;
				self.acTurnStage = 5;
				self.turnTimer = self.acDeltaTimeoutWait;
				self.waitForTurnTime = self.time + self.turnTimer;
				--if not self.acParameters.upNDown
				--		or traceLength < 10 then
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
		self.mogliInfoText = string.format(Mogli.getText("AC_COMBINE_ERROR")..": %i",self.acTurnStage);
		print(self.mogliInfoText);
		AITractor.stopAITractor(self);
		return;
	end;                

--==============================================================				
--==============================================================				
	if math.abs( self.axisSide ) > 0.3 then --if AutoTractor.acDevFeatures and math.abs( self.axisSide ) > 0.3 then 
		detected = false
		border   = 0
		angle    = nil
		angle2   = - self.axisSide * self.acDimensions.maxSteeringAngle
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
	elseif self.acTurnStage <= 0 and detected then
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
		self.mogliInfoText = self.mogliInfoText .. string.format(" a: %3i ",math.deg(angle))..tostring(detected)
	end

	local aiSteeringSpeed = self.aiSteeringSpeed;
	if detected and 
			(  math.abs( angle ) > 0.5 * angleMax
			or math.abs( angle - AutoSteeringEngine.currentSteeringAngle( self ) )  > 0.25 * angleMax
			--or self.acTurnStage == -3
			--or self.acTurnStage == -13
			--or -3 <= self.acTurnStage and self.acTurnStage < 0 ) then
			) then
		detected = false
	end
	
	if     self.isRealistic then
		aiSteeringSpeed = 3 * aiSteeringSpeed
	elseif speedLevel == 4 then
		aiSteeringSpeed = 0.5 * aiSteeringSpeed
	elseif speedLevel == 2 then
		aiSteeringSpeed = 3 * aiSteeringSpeed
	elseif speedLevel == 3 then
		aiSteeringSpeed = 6 * aiSteeringSpeed
	end
	
	if self.isRealistic then
		if      self.motor                   ~= nil
				and self.motor.realSpeedLevelsAI ~= nil
				and self.acRealSpeedLevelsAI1    ~= nil then
			self.motor.realSpeedLevelsAI[1] = self.acRealSpeedLevelsAI1
		end		
		
	  if AIVehicleUtil.mrDriveInDirection == nil then
			if self.acTurnStage==0 then
				self.turnStage = 0
			else
				self.turnStage = 2
				speedLevel = 1
			end
			if speedLevel == 4 then
				speedLevel = 1
			end
		elseif self.acTurnStage==0 then -- when the AI is working, we set the speedlevel adequately to the implements
			self.turnStage = 0
			if not detected then
				self.motor.realSpeedLevelsAI[3] = math.min(math.max(math.min(7, self.motor.realSpeedLevelsAI[1]), 0.5*self.motor.realSpeedLevelsAI[1]), self.realAiManeuverSpeed); -- reduce working speed
				speedLevel = 3; -- updated in OverrideAITractor.lua (updateToolsInfo)
			else
				speedLevel = 1; -- updated in OverrideAITractor.lua (updateToolsInfo)		
				if      2 <= self.speed2Level and self.speed2Level <= 4 
						and self.acRealSpeedLevelsAI1  ~= nil
						and self.motor.realSpeedLevels ~= nil
						and self.motor.realSpeedLevels[self.speed2Level-1] ~= nil then
					self.motor.realSpeedLevelsAI[1] = self.motor.realSpeedLevels[self.speed2Level-1]
				end
			end;
		else
			self.motor.realSpeedLevelsAI[3] = 0.5*self.motor.realSpeedLevelsAI[2];
			self.turnStage = 2
			if math.abs(angle)>angleMax then
				speedLevel = 3
			else
			  speedLevel = 2
			end
		end;
		
		if math.abs( self.realGroundSpeed ) > 0.5 and not allowedToDrive then
			angle = 0
		end
		
	else
		if not detected and 0 < speedLevel and speedLevel < 4 then
			speedLevel = 4
		elseif speedLevel ~= 2 and speedLevel ~= 3 and speedLevel ~= 4 then
			speedLevel = 1
		end
		
		if      speedLevel == 4 
				and self.motor ~= nil 
				and self.motor.maxRpm ~= nil
				and self.motor.maxRpm[4] > 0.8 * self.motor.maxRpm[1] then
			speedLevel     = 1
			useReduceSpeed = true
		end
	end
	
	angle = math.min( math.max( angle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
	
	if AutoTractor.acDevFeatures then
		self.mogliInfoText = self.mogliInfoText .." "..tostring(allowedToDrive).." "..tostring(moveForwards).." "..tostring(speedLevel)
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
	elseif self.time > self.turnTimer then
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
-- AutoTractor:navigationFallbackRetry
------------------------------------------------------------------------
function AutoTractor:navigationFallback75( uTurn )

	local x, z, allowedToDrive = AutoTractor.getTurnVector( self, uTurn )
	if self.acParameters.leftAreaActive then x = -x end
	
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

	local atd = true
	
	if      self.acMarkerWait 
			and self.acSavedMarker then
		if self.acIsAnimPlaying then
			atd = false
		else
			self.acMarkerWait  = nil
			self.acSavedMarker = nil
		end
	end
	
	local x, z = AutoSteeringEngine.getTurnVector( self, uTurn )
 
	return x, z, atd
end

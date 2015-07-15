--
-- AutoTractor
-- Extended AITractor
--
-- @author  Mogli aka biedens
-- @date  17.12.2013
--
--  code source: AITractor.lua by Giants Software    
 
AutoTractor = {};
local AtDirectory = g_currentModDirectory;

------------------------------------------------------------------------
-- prerequisitesPresent
------------------------------------------------------------------------
function AutoTractor.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Hirable, specializations) and SpecializationUtil.hasSpecialization(Steerable, specializations);
end;

------------------------------------------------------------------------
-- load
------------------------------------------------------------------------
function AutoTractor:load(xmlFile)

	source(Utils.getFilename("Mogli.lua", AtDirectory));
	
	-- for courseplay  
	self.acNumCollidingVehicles = 0;
	self.acIsCPStopped          = false;
	self.acTurnStage            = 0;
		
	self.acParameters = {}
	self.acParameters.upNDown 							= false;
	self.acParameters.leftAreaActive = true;
  self.acParameters.rightAreaActive = false;
  self.acParameters.enabled = false;
  self.acParameters.noReverse = false;
  self.acParameters.CPSupport = false;
	self.acParameters.turnOffset = 0;
	self.acParameters.widthOffset = 0;

	self.acDeltaTimeoutWait   = math.max(Utils.getNoNil( self.waitForTurnTimeout, 1500 ), 1000 ); 
	self.acDeltaTimeoutRun    = math.max(Utils.getNoNil( self.driveBackTimeout  , 1000 ),  300 );
	self.acDeltaTimeoutStop   = math.max(Utils.getNoNil( self.turnStage1Timeout , 20000), 10000);
	self.acDeltaTimeoutStart  = math.max(Utils.getNoNil( self.turnTimeoutLong   , 6000 ), 4000 );
	self.acDeltaTimeoutNoTurn = math.max(Utils.getNoNil( self.turnStage4Timeout , 2000 ), 1000 );
	self.acSteeringSpeed      = Utils.getNoNil( self.aiSteeringSpeed, 0.001 );
	self.acRecalculateDt      = 0;
	self.acTurn2Outside       = false;
	self.acDirectionBeforeTurn = {};
	self.acCollidingVehicles   = {};
	self.acTurnStageSent       = 0;

	self.acBorderDetected = nil;	
	self.acFruitsDetected = nil;

	self.acTools = {}
	
  self.acAutoRotateBackSpeedBackup = self.autoRotateBackSpeed;	

	Mogli.init( self, AtDirectory, "AutoTractorHud", "AutoTractorHud.dds",  "AUTO_TRACTOR_TEXTHELPPANELON", "AUTO_TRACTOR_TEXTHELPPANELOFF", InputBinding.AUTO_TRACTOR_HELPPANEL, 0.025, 0.0108, 5, 3 )

	Mogli.addButton(self, "off.dds",            "on.dds",           AutoTractor.onStart,      AutoTractor.evalStart,     1,1, "HireEmployee", "DismissEmployee" );
	Mogli.addButton(self, "inactive_left.dds",  "active_left.dds",  AutoTractor.setAreaLeft,  AutoTractor.evalAreaLeft,  3,1, "AUTO_TRACTOR_ACTIVESIDERIGHT", "AUTO_TRACTOR_ACTIVESIDELEFT" );
	Mogli.addButton(self, "inactive_right.dds", "active_right.dds", AutoTractor.setAreaRight, AutoTractor.evalAreaRight, 4,1, "AUTO_TRACTOR_ACTIVESIDELEFT", "AUTO_TRACTOR_ACTIVESIDERIGHT" );
	Mogli.addButton(self, "next.dds",           "no_next.dds",      AutoTractor.nextTurnStage,AutoTractor.evalTurnStage, 5,1, "AUTO_TRACTOR_NEXTTURNSTAGE", nil );
	
	Mogli.addButton(self, "ai_combine.dds",     "empty.dds",       AutoTractor.onEnable,      AutoTractor.evalEnable,    1,2, "AUTO_TRACTOR_STOP", "AUTO_TRACTOR_START" );
	Mogli.addButton(self, "no_uturn2.dds",      "uturn.dds",       AutoTractor.setUTurn,      AutoTractor.evalUTurn,     3,2, "AUTO_TRACTOR_UTURN_OFF", "AUTO_TRACTOR_UTURN_ON") ;
	Mogli.addButton(self, "reverse.dds",        "no_reverse.dds",  AutoTractor.setNoReverse,  AutoTractor.evalNoReverse, 4,2, "AUTO_TRACTOR_REVERSE_ON", "AUTO_TRACTOR_REVERSE_OFF");
	Mogli.addButton(self, "no_cp.dds",          "cp.dds",          AutoTractor.setCPSupport,  AutoTractor.evalCPSupport, 5,2, "AUTO_TRACTOR_CP_OFF", "AUTO_TRACTOR_CP_ON" );

	Mogli.addButton(self, "bigger.dds",         nil,               AutoTractor.setWidthUp,    nil,                       1,3, "AUTO_TRACTOR_WIDTH_OFFSET", nil, AutoTractor.getWidth);
	Mogli.addButton(self, "smaller.dds",        nil,               AutoTractor.setWidthDown,  nil,                       2,3, "AUTO_TRACTOR_WIDTH_OFFSET", nil, AutoTractor.getWidth);
	Mogli.addButton(self, "forward.dds",        nil,               AutoTractor.setForward,    nil,                       3,3, "AUTO_TRACTOR_TURN_OFFSET", nil, AutoTractor.getTurnOffset);
	Mogli.addButton(self, "backward.dds",       nil,               AutoTractor.setBackward,   nil,                       4,3, "AUTO_TRACTOR_TURN_OFFSET", nil, AutoTractor.getTurnOffset);
	Mogli.addButton(self, "auto_steer_off.dds", "auto_steer_on.dds",AutoTractor.onAutoSteer,  AutoTractor.evalAutoSteer, 5,3, "AUTO_TRACTOR_STEER_ON", "AUTO_TRACTOR_STEER_OFF" );

	self.acRefNode = self.aiTractorDirectionNode;
	if self.acRefNode == nil then
		self.acRefNode = self.components[1].node
	end
	if      self.articulatedAxis ~= nil 
			and self.articulatedAxis.componentJoint ~= nil
      and self.articulatedAxis.componentJoint.jointNode ~= nil 
			and self.articulatedAxis.rotMax then	
		self.acRefNode = self.components[self.articulatedAxis.componentJoint.componentIndices[2]].node;
	end;

end;

------------------------------------------------------------------------
-- draw
------------------------------------------------------------------------
function AutoTractor:draw()
	Mogli.draw(self);

	if AutoTractor.evalAutoSteer(self) then
		g_currentMission:addHelpButtonText(Mogli.getText("AUTO_TRACTOR_STEER_ON"), InputBinding.AUTO_TRACTOR_STEER);
	elseif self.acTurnStage >= 98 then
		g_currentMission:addHelpButtonText(Mogli.getText("AUTO_TRACTOR_STEER_OFF"),InputBinding.AUTO_TRACTOR_STEER);
	end
end;

------------------------------------------------------------------------
-- onLeave
------------------------------------------------------------------------
function AutoTractor:onLeave()
  Mogli.onLeave(self);
end;

------------------------------------------------------------------------
-- onEnter
------------------------------------------------------------------------
function AutoTractor:onEnter()
	Mogli.onEnter(self);
end;

------------------------------------------------------------------------
-- mouseEvent
------------------------------------------------------------------------
function AutoTractor:mouseEvent(posX, posY, isDown, isUp, button)
	Mogli.mouseEvent(self, posX, posY, isDown, isUp, button);	
end

------------------------------------------------------------------------
-- delete
------------------------------------------------------------------------
function AutoTractor:delete()
	Mogli.delete(self)
end;

------------------------------------------------------------------------
-- mouse event callbacks
------------------------------------------------------------------------
function AutoTractor.showGui(self,on)
  Mogli.showGui(self,on)
end;

function AutoTractor:evalUTurn()
	return not self.acParameters.upNDown;
end;

function AutoTractor:setUTurn(enabled)
	self.acParameters.upNDown = enabled;
end;

function AutoTractor:evalAreaLeft()
	return not self.acParameters.leftAreaActive;
end;

function AutoTractor:setAreaLeft(enabled)
	if not enabled then return; end;
	self.acParameters.leftAreaActive  = enabled;
	self.acParameters.rightAreaActive = not enabled;
end;

function AutoTractor:evalAreaRight()
	return not self.acParameters.rightAreaActive;
end;

function AutoTractor:setAreaRight(enabled)
	if not enabled then return; end;
	self.acParameters.rightAreaActive = enabled;
	self.acParameters.leftAreaActive  = not enabled;
end;

function AutoTractor:evalStart()
	return not self.isAITractorActivated or not AITractor.canStartAITractor(self);
end;

function AutoTractor:onStart(enabled)
  if self.isAITractorActivated and not enabled then
    self.stopAITractor()
  elseif AITractor.canStartAITractor(self) and enabled then
    self.startAITractor()
  end
end;

function AutoTractor:evalEnable()
	return not self.acParameters.enabled;
end;

function AutoTractor:onEnable(enabled)
	if not self.isAITractorActivated then
		self.acParameters.enabled = enabled;
	end;
end;

function AutoTractor:evalNoReverse()
	return not self.acParameters.noReverse;
end;

function AutoTractor:setNoReverse(enabled)
	self.acParameters.noReverse = enabled;
end;

function AutoTractor:setWidthUp()
	self.acParameters.widthOffset = self.acParameters.widthOffset + 0.125;
	self.acDimensions = nil;
end;

function AutoTractor:setWidthDown()
	self.acParameters.widthOffset = self.acParameters.widthOffset - 0.125;
	self.acDimensions = nil;
end;

function AutoTractor:getWidth(old)
	new = string.format(old..": %0.2fm",self.acParameters.widthOffset+self.acParameters.widthOffset);
	return new
end

function AutoTractor:setForward()
	self.acParameters.turnOffset = self.acParameters.turnOffset + 0.25;
	self.acDimensions = nil;
end;                                               

function AutoTractor:setBackward()               
	self.acParameters.turnOffset = self.acParameters.turnOffset - 0.25;
	self.acDimensions = nil;
end;

function AutoTractor:getTurnOffset(old)
	new = string.format(old..": %0.2fm",self.acParameters.turnOffset);
	return new
end

function AutoTractor:evalTurnStage()
	if self.acParameters.enabled then
--		if     self.acTurnStage == 2 
--				or self.acTurnStage == 12
--				or self.acTurnStage == 15
--				or self.acTurnStage == 17
--				or self.acTurnStage == 18 then
--			return true
--		end
--	else
--		if self.turnStage > 0 and self.turnStage < 4 then
--			return true;
--		end
	end
	
	return false
end

function AutoTractor:nextTurnStage()
	AutoTractor.setNextTurnStage(self);
end

function AutoTractor:evalCPSupport()
	return not self.acParameters.CPSupport;
end

function AutoTractor:setCPSupport(enabled)
	self.acParameters.CPSupport = enabled;
end

function AutoTractor:evalAutoSteer()
	return self.isAITractorActivated or self.acTurnStage < 98
end

function AutoTractor:onAutoSteer(enabled)
	--print("%s %i %s",tostring(self.isAIThreshing),self.acTurnStage,tostring(enabled));
	if self.isAITractorActivated then
		if self.acTurnStage >= 98 then
			self.acTurnStage   = 0
		end
	elseif enabled then
		self.setAIImplementsMoveDown(self,true);
		self.acTurnStage   = 98
		self.acRotatedTime = 0
	else
		self.acTurnStage   = 0
    self.stopMotorOnLeave = true
    self.deactivateOnLeave = true
	end
end

------------------------------------------------------------------------
-- keyEvent
------------------------------------------------------------------------
function AutoTractor:keyEvent(unicode, sym, modifier, isDown)
	if isDown and sym == Input.KEY_s then
		self.speed2Level = 0;
	end;	
end;

------------------------------------------------------------------------
-- update
------------------------------------------------------------------------
function AutoTractor:update(dt)

	if self:getIsActiveForInput(false) then
		if InputBinding.hasEvent(InputBinding.AUTO_TRACTOR_HELPPANEL) then
			AutoTractor.showGui( self, not self.mogliGuiActive );
		end;
		if	InputBinding.hasEvent(InputBinding.SPEED_LEVEL1) then
			self.speed2Level = 1;
		elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL2) then
			self.speed2Level = 2;
		elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL3) then
			self.speed2Level = 3;
		elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL4) then
			self.speed2Level = 4;
		end;
	end;
	
	if math.abs(self.axisSide) > 0.3 and self.acTurnStage >= 98 then
		AutoTractor.onAutoSteer(self, false)
	end
	
	if self.acTurnStage >= 98 then
    self.stopMotorOnLeave = false
    self.deactivateOnLeave = false
	end
	
	if self.mogliGuiActive or self.acParameters.enabled then
		AutoTractor.calculateDimensions(self);	
		if self.acPoints ~= nil then
			for _,dbg in pairs(self.acPoints) do
				local notFirst = false;
				for _,p in pairs(dbg.points) do
					local qx,qy,qz = localToWorld( self.acRefNode, p.x, 1, p.z );
					if notFirst then
						drawDebugLine(px,py,pz,1,0,0,qx,qy,qz,0,0,1);
					else				
						notFirst = true
					end
					px = qx; py = qy; pz = qz;
				end		
			end
		end
	end
end;

------------------------------------------------------------------------
-- updateTick
------------------------------------------------------------------------
function AutoTractor:updateTick(dt)

	if      not self.isAITractorActivated 
			and self.acTurnStage >= 98 then
		AutoTractor.autoSteer(self,dt)
	end
	
	if self.acTurnStageSent ~= self.acTurnStage then
		self.acTurnStageSent = self.acTurnStage;
    if g_server ~= nil then
      g_server:broadcastEvent(AutoTractorTurnStageEvent:new(self,self.acTurnStage), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(AutoTractorNextTSEvent:new(self,self.acTurnStage))
    end
	end
	
end

------------------------------------------------------------------------
-- AITractor:updateToolsInfo
------------------------------------------------------------------------
local oldAITractorUpdateToolsInfo = AITractor.updateToolsInfo;
AITractor.updateToolsInfo = function(self)
	self.acDimensions = nil
	return oldAITractorUpdateToolsInfo(self)
end

------------------------------------------------------------------------
-- AITractor:startAITractor
------------------------------------------------------------------------
local oldAITractorStartAITractor = AITractor.startAITractor;
AITractor.startAITractor = function(self, noEventSend)
	
	-- just to be safe...
	if self.acParameters ~= nil and self.acParameters.enabled then
		self.acDimensions  = nil;
		self.acTurnStage   = 22;
		self.turnTimer     = self.acDeltaTimeoutWait;
		self.aiRescueTimer = self.acDeltaTimeoutStop;
		self.waitForTurnTime = 0;
		
		if self.speed2Level == nil or self.speed2Level < 1 or self.speed2Level > 4 then
			self.speed2Level = 1
		end
		
		AutoTractor.sendParameters(self);
	end

	return oldAITractorStartAITractor(self, noEventSend);
end;

------------------------------------------------------------------------
-- AITractor:stopAITractor
------------------------------------------------------------------------
local oldAITractorStopAITractor = AITractor.stopAITractor;
AITractor.stopAITractor = function(self, noEventSend)
	return oldAITractorStopAITractor(self, noEventSend);
end;

------------------------------------------------------------------------
-- getFruitArea
------------------------------------------------------------------------
function AutoTractor:getFruitArea(x1,z1,x2,z2,d,groundInfoObject, isCombine,fruitType,hasFruitPreparer)
	local lx1,lz1,lx2,lz2,lx3,lz3 = AutoTractor.getParallelogram( self, x1, z1, x2, z2, d );

	local area, areaTotal = 0,0;
	if isCombine then
		area, areaTotal = Utils.getFruitArea(fruitType, lx1,lz1,lx2,lz2,lx3,lz3, hasFruitPreparer);	
	else
		local terrainDetailRequiredMask = 0
		if 0 <= groundInfoObject.aiTerrainDetailChannel1 then
			terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2 ^ groundInfoObject.aiTerrainDetailChannel1)
			if 0 <= groundInfoObject.aiTerrainDetailChannel2 then
				terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2 ^ groundInfoObject.aiTerrainDetailChannel2)
				if 0 <= groundInfoObject.aiTerrainDetailChannel3 then
					terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2 ^ groundInfoObject.aiTerrainDetailChannel3)
				end
			end
		end

		area, areaTotal = AITractor.getAIArea(self, lx1, lz1, lx2, lz2, lx3, lz3, 
																					terrainDetailRequiredMask, 
																					groundInfoObject.aiTerrainDetailProhibitedMask, 
																					groundInfoObject.aiRequiredFruitType, 
																					groundInfoObject.aiRequiredMinGrowthState, 
																					groundInfoObject.aiRequiredMaxGrowthState, 
																					groundInfoObject.aiProhibitedFruitType, 
																					groundInfoObject.aiProhibitedMinGrowthState, 
																					groundInfoObject.aiProhibitedMaxGrowthState)
	end
	
	return area;-- > 0 and area > 0.15 * areaTotal
end

------------------------------------------------------------------------
-- isField
------------------------------------------------------------------------
function AutoTractor:isField(x1,z1,x2,z2)
	local lx1,lz1,lx2,lz2,lx3,lz3 = AutoTractor.getParallelogram( self, x1, z1, x2, z2, 0 );

	for i=0,3 do
		if Utils.getDensity(g_currentMission.terrainDetailId, i, lx1,lz1,lx2,lz2,lx3,lz3) ~= 0 then
			return true;
		end;
	end;

	return false;
	
end
------------------------------------------------------------------------
-- AICombine:updateAIMovement
------------------------------------------------------------------------
local oldAITractorUpdateAIMovement = AITractor.updateAIMovement;
AITractor.updateAIMovement = function(self,dt)

	if self.acParameters == nil or not self.acParameters.enabled then
		return oldAITractorUpdateAIMovement(self,dt);
	end
	
	if not self.isControlled then
		if g_currentMission.environment.needsLights then
			self:setLightsVisibility(true)
		else
			self:setLightsVisibility(false)
		end
	end
	local allowedToDrive = true
	for _, v in pairs(self.numCollidingVehicles) do
		if v > 0 then
			allowedToDrive = false
			break
		end
	end
	if self.waitForTurnTime > self.time then
		allowedToDrive = false
	end
	if not allowedToDrive then
		AIVehicleUtil.driveInDirection(self, dt, 30, 0, 0, 28, false, moveForwards, nil, nil)
		return
	end
	local speedLevel = 1
	if not self:getIsAITractorAllowed() then
		self:stopAITractor()
		return
	end
	local moveForwards = true
	local updateWheels = true
	self.turnTimer = self.turnTimer - dt

	AutoTractor.calculateDimensions(self);
	
	local offsetOutside = 0;
	if     self.acParameters.rightAreaActive then
		offsetOutside = -1;
	elseif self.acParameters.leftAreaActive then
		offsetOutside = 1;
	end;
			
	self.acHelpPanelInfoText = "";				
			
--==============================================================				
--==============================================================				

	local acceleration = 0;					
	local slowAngleLimit = 20;
	if self.isMotorStarted and speedLevel ~= 0 and self.fuelFillLevel > 0 then
		acceleration = 1.0;
	end;
	
	if self.acTurnStage > 0 or not self.acBorderDetected then
		acceleration = 0.8*acceleration;
	end;

	local maxAngle = 25;
  local maxlx = 0.7071067;
	if self.acDimensions ~= nil and self.acDimensions.maxSteeringAngle ~= nil then
		maxAngle = math.deg( self.acDimensions.maxSteeringAngle );
	end;
	
	local lx, lz = 0, 1;
		
	if angle == nil then
		angle = 0
	elseif not self.acParameters.leftAreaActive then
		angle = -angle;
	end

	lx, lz = math.sin(angle), math.cos(angle);
	
	if      self.acTurnStage == 0 
			and self.acBorderDetected 
			and self.acFruitsDetected then
		self.aiSteeringSpeed = 0.75 * self.acSteeringSpeed;	
	elseif self.acTurnStage == 0 
			or self.acTurnStage >= 20 then
		self.aiSteeringSpeed = self.acSteeringSpeed;	
	else
		self.aiSteeringSpeed = 1.5 * self.acSteeringSpeed;	
	end
	
	AIVehicleUtil.driveInDirection(self, dt, maxAngle, acceleration, math.max(0.25,0.75*acceleration), slowAngleLimit, allowedToDrive, moveForwards, lx, lz, speedLevel, 0.6)
	
	self.aiSteeringSpeed = self.acSteeringSpeed;	
	
  local colDirX = lx
  local colDirZ = lz
--  if maxlx < colDirX then
--    colDirX = maxlx
--    colDirZ = 0.7071067
--  elseif colDirX < -maxlx then
--    colDirX = -maxlx
--    colDirZ = 0.7071067
--  end
  for triggerId, _ in pairs(self.numCollidingVehicles) do
	  AIVehicleUtil.setCollisionDirection(self.aiTreshingDirectionNode, triggerId, colDirX, colDirZ)
  end
end

------------------------------------------------------------------------
-- autoSteer
------------------------------------------------------------------------
function AutoTractor:autoSteer(dt)

	AutoTractor.calculateDimensions(self);

	local offsetOutside = 0;
	if     self.acParameters.rightAreaActive then
		offsetOutside = -1;
	elseif self.acParameters.leftAreaActive then
		offsetOutside = 1;
	end;
		
	local angle = 99;	
	local border = 0;
	local detected = false;

--==============================================================		
	self.acPoints = {};
	for object,tool in pairs(self.acTools) do		
		local hasFruitPreparer = false
		local angle2 = 0;	
		local detected2 = false;
		local factor = 0.02;			
		
		local x0,z0,x1,z1;
		if self.acParameters.leftAreaActive then				
			x1,_,z1 = AutoTractor.getRelativeTranslation(self.acRefNode,object.aiLeftMarker);
		else
			x1,_,z1 = AutoTractor.getRelativeTranslation(self.acRefNode,object.aiRightMarker);		
		end		
		
		local _,_,z2 = AutoTractor.getRelativeTranslation(self.acRefNode,tool.aiBackMarker);
		z1 = z1 - self.acDimensions.zOffset;
		--z1 = math.abs(z1);
				
		lz = math.max( 3, self.acDimensions.wheelBase - z1 + 3 );
		
		border = AutoTractor.getFruitArea( self, x1, z1 + self.acDimensions.zOffset, offsetOutside, lz, 0, object, false, fruitType, hasFruitPreparer );
			
		if not self.acParameters.leftAreaActive then x1 = -x1 end
		
		if border <= 0 then
			factor = -factor;					
		--elseif self.acDimensions.maxLookingAngle < self.acDimensions.maxSteeringAngle then
			--factor = factor * self.acDimensions.maxLookingAngle / self.acDimensions.maxSteeringAngle
		end 
	
		for index=1,7 do
			local l = 0;
			local r1 = 0;
			local phi = 0;
			local chi = 0;			
			
			local a = factor * index*index * self.acDimensions.maxLookingAngle;-- * self.acDimensions.maxSteeringAngle; 							
			local r = self.acDimensions.wheelBase / math.tan(math.abs(a));
			
			local c,s=0,0;
			
			if a > 0 then
				c = r - x1;
			else
				c = r + x1;
			end
			
			if c < 0 then break end

			--if tool.refNode == self.acRefNode then
				s = 0;
			--else
			--	_,_,s = AutoTractor.getRelativeTranslation(self.acRefNode,tool.refNode);
			--end
			
			if a > 0 then
				s = s + z1;
			else
				s = s + z1;
			end
			
			if s < -2 then break end;
			
			r1  = math.sqrt( c * c + s * s );

			local o = c - r1;
			if a < 0 then
				o = -o;
			end
			
			chi = math.atan( s / c );
						
			local points = nil;

			if chi < 0 then
				phi = - chi / 3
				--chi = 0
			
				for j = 0,6 do
					d = c - r1 * math.cos( chi + phi * j );
					if a < 0 then
						d = -d;
					end												
					local p = {}
					p.x = x1 + d

					if not self.acParameters.leftAreaActive then				
						p.x = - p.x;
					end
		
					p.z = r1 * math.sin( chi + phi * j ) + self.acDimensions.zOffset;			
					if points == nil then
						points = {}
						points[1] = p;
					else
						points[#points+1] = p;
					end
				end
			else
				local p = {};
				p.x    = x1;
				if not self.acParameters.leftAreaActive then				
					p.x = - p.x;
				end
				p.z    = math.abs( z1 ) + self.acDimensions.zOffset;			
				points = {}
				points[1] = p;
			end
			
-- a straight line at the end			
			local p = {} ; 
			local ll = math.max( 3, self.acDimensions.wheelBase - math.abs(z1) + 3 );
			
			d = ll * math.sin( math.abs( chi ) );
			if a < 0 then
				d = -d;
			end												
			p.x = x1 + d
			if not self.acParameters.leftAreaActive then				
				p.x = - p.x;
			end
			
			p.z = math.abs( z1 ) + ll * math.cos( math.abs( chi ) );
			points[#points+1] = p;
				
			b = 0;
						
			local notFirst = false;
			for _,p in pairs(points) do
				local xi = p.x
				local zi = p.z;
				
				if notFirst then
					self.mogliInfoText = self.mogliInfoText  .. string.format( " %0.2f ",xi);

					b = b + AutoTractor.getFruitArea( self, x0, z0, offsetOutside, 
																						zi - z0, xi - x0, 
																						object, false, fruitType, hasFruitPreparer )
				else				
					self.mogliInfoText = string.format( "%0.2f | %0.2f",zi,xi);
					notFirst = true
				end
				
				x0 = xi;
				z0 = zi;
			end				
			self.mogliInfoText = self.mogliInfoText  .. string.format( " | %0.2f",z0);
			
			--self.mogliInfoText = string.format( "a=%3i, p=%3i, c=%3i, x=%0.2f, z=%0.2f, o=%0.2f, s=%0.2f, d=%0.2f, b=%i", math.deg(a),math.deg(phi),x1,z1,o,s,d,b );

			--print(string.format("a=%3i, c=%3i, p=%3i, r=%f, r1=%f, s=%f, o=%f",math.deg(a),math.deg(chi),math.deg(phi),r,r1,z1,o));


			if     border > 0 then
				if b <= 0 then
					detected2 = true;
					angle2 = a;
					break
				end
			else
				if b > 0 then
					detected2 = true;
					local dbg = {};
					dbg.points = points;
					self.acPoints[object] = dbg;
					break
				end
			end

			if index == 7 then
				local dbg = {};
				dbg.points = points;
				self.acPoints[object] = dbg;
			end
			
			angle2 = a;
		end
		
		if detected2 then
			detected = true;
		end
		if angle > angle2 then
			angle = angle2;
		end
	end
--==============================================================						

	--if detected then
		--print(string.format("found, angle=%3i; ",math.deg(angle))..self.mogliInfoText)
	--else
		--print(string.format("nothing, angle=%3i; ",math.deg(angle))..self.mogliInfoText)
	--end
	
	if detected then
		if self.acTurnStage ~= 99 then
			self.acTurnStage = 99
			AutoTractor.saveDirection( self, false )
		end
		AutoTractor.saveDirection( self, true );
		self.turnTimer = self.acDeltaTimeoutRun
	else
		self.turnTimer = self.turnTimer - dt;
	
		if border > 0 then
			angle = self.acDimensions.maxLookingAngle;
		else
			angle = -self.acDimensions.maxLookingAngle;

			local l = AutoTractor.getTraceLength(self);
			local a = math.deg(AutoTractor.getTurnAngle(self));
			if not self.acParameters.leftAreaActive then a = -a; end;
			if      l >= 1
					and a < -15 then
				angle = 0;
			end
		end

		if false then --self.acTurnStage == 99 and self.turnTimer < 0 then
			if border > 0 then
				self.setAIImplementsMoveDown(self,false);
				Steerable.setSpeedLevel(self, 0)
			else
				d = self.acDimensions.distance + self.acDimensions.distance;
				d = - math.max( 0.9 * d, d - 1 );
				if not self.acParameters.leftAreaActive then d = -d; end;
			end
		end
	end
	
	if not self.acParameters.leftAreaActive then angle = -angle end
	if self.movingDirection < -1E-2 then angle = -angle end
	local targetRotTime = 0
	
	if self.acRotatedTime == nil then
		self.rotatedTime = 0
	else
		self.rotatedTime = self.acRotatedTime
	end
	
	if self.isEntered then
		if     angle == 0 then
			targetRotTime = 0
		elseif angle  > 0 then
			targetRotTime = self.maxRotTime * math.min( angle / self.acDimensions.maxSteeringAngle, 1)
		else
			targetRotTime = self.minRotTime * math.min(-angle / self.acDimensions.maxSteeringAngle, 1)
		end
		
		if false then -- detected then
			self.rotatedTime = targetRotTime
		elseif targetRotTime > self.rotatedTime then
			self.rotatedTime = math.min(self.rotatedTime + dt * self.aiSteeringSpeed, targetRotTime)
		else
			self.rotatedTime = math.max(self.rotatedTime - dt * self.aiSteeringSpeed, targetRotTime)
		end
	end
	
	self.acRotatedTime = self.rotatedTime
end

------------------------------------------------------------------------
-- getSaveAttributesAndNodes
------------------------------------------------------------------------
function AutoTractor:getSaveAttributesAndNodes(nodeIdent)
	local attributes = "";
	if     self.acParameters.enabled
			or self.acParameters.upNDown
			or self.acParameters.waitode 
			or self.acParameters.rightAreaActive
			or self.acParameters.otherCombine then
		attributes = 'acVersion="2.0"';
		attributes = attributes..'acEnabled="'     ..acBool2int(self.acParameters.enabled).. '" ';
		attributes = attributes..'acUTurn="'       ..acBool2int(self.acParameters.upNDown).. '" ';
		attributes = attributes..'acWaitMode="'    ..acBool2int(self.acParameters.waitMode).. '" ';
		attributes = attributes..'acAreaRight="'   ..acBool2int(self.acParameters.rightAreaActive).. '" ';
		attributes = attributes..'acOtherCombine="'..acBool2int(self.acParameters.otherCombine).. '" ';
		attributes = attributes..'acNoReverse="'   ..acBool2int(self.acParameters.noReverse).. '" ';
		attributes = attributes..'acTurnOffset="'  ..self.acParameters.turnOffset..'" ';		
		attributes = attributes..'acWidthOffset="' ..self.acParameters.widthOffset..'" ';		
	end;
	
	--print(attributes);
	
	return ""--attributes
end;

------------------------------------------------------------------------
-- AutoTractor.getXmlBool
------------------------------------------------------------------------
function AutoTractor.getXmlBool(xmlFile, key, default)
	local l = getXMLInt(xmlFile, key);
	if l~= nil then
		return (l == 1);
	end;
	return default;
end;

function AutoTractor.getXmlFloat(xmlFile, key, default)
	local f = getXMLFloat(xmlFile, key);
	if f ~= nil then
		return f;
	end;
	return default;
end;
------------------------------------------------------------------------
-- loadFromAttributesAndNodes
------------------------------------------------------------------------
function AutoTractor:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	local version = getXMLString(xmlFile, key.."#acVersion");
	
	self.acParameters.enabled         = AutoTractor.getXmlBool(xmlFile, key.."#acEnabled",     self.acParameters.enabled);
	self.acParameters.upNDown	        = AutoTractor.getXmlBool(xmlFile, key.."#acUTurn",       self.acParameters.upNDown);
	self.acParameters.rightAreaActive = AutoTractor.getXmlBool(xmlFile, key.."#acAreaRight",   self.acParameters.rightAreaActive);
	self.acParameters.noReverse       = AutoTractor.getXmlBool(xmlFile, key.."#acNoReverse",   self.acParameters.noReverse);
	self.acParameters.turnOffset      = AutoTractor.getXmlFloat(xmlFile, key.."#acTurnOffset", self.acParameters.turnOffset ); 
	self.acParameters.widthOffset     = AutoTractor.getXmlFloat(xmlFile, key.."#acWidthOffset",self.acParameters.widthOffset); 

	self.acParameters.leftAreaActive  = not self.acParameters.rightAreaActive;
	self.acDimensions                 = nil;
	
	return BaseMission.VEHICLE_LOAD_OK;
end

------------------------------------------------------------------------
-- getMarker
------------------------------------------------------------------------
function AutoTractor:getMarker()

  local lm = self.aiCurrentLeftMarker;
  local rm = self.aiCurrentRightMarker;
	
	return lm, rm;
end;

------------------------------------------------------------------------
-- getAreaOverlap
------------------------------------------------------------------------
function AutoTractor:getAreaOverlap(workingWidth)
  local areaOverlap = 0;
	local scale = 1;--Utils.getNoNil( self.aiTurnThreshWidthScale, 0.1 );
	local diff  = 0;--Utils.getNoNil( self.aiTurnThreshWidthMaxDifference, 0.6 );

	areaOverlap = 0.5 * math.min(workingWidth * (1 - scale), diff);

	return areaOverlap;
end

------------------------------------------------------------------------
-- getCorrectedMaxSteeringAngle
------------------------------------------------------------------------
function AutoTractor:getCorrectedMaxSteeringAngle()

	local steeringAngle = self.acDimensions.maxSteeringAngle;
	if      self.articulatedAxis ~= nil 
			and self.articulatedAxis.componentJoint ~= nil
      and self.articulatedAxis.componentJoint.jointNode ~= nil 
			and self.articulatedAxis.rotMax then
		-- Ropa
		steeringAngle = steeringAngle + 0.15 * self.articulatedAxis.rotMax;
	end

	return steeringAngle
end

------------------------------------------------------------------------
-- calculateDimensions
------------------------------------------------------------------------
function AutoTractor:calculateDimensions()
	if self.acDimensions ~= nil then
		return;
	end;
	
	self.acRecalculateDt = 0
	self.acDimensions = {};

	self.acDimensions.wheelBase       = 0;
	self.acDimensions.zOffset         = 0;
	self.acDimensions.radius          = 5;
	
	if      self.articulatedAxis ~= nil 
			and self.articulatedAxis.componentJoint ~= nil
      and self.articulatedAxis.componentJoint.jointNode ~= nil 
			and self.articulatedAxis.rotMax then
		_,_,self.acDimensions.zOffset = AutoTractor.getRelativeTranslation(self.acRefNode,self.articulatedAxis.componentJoint.jointNode);
		local n=0;
		for _,wheel in pairs(self.wheels) do
			local x,y,z = AutoTractor.getRelativeTranslation(self.articulatedAxis.componentJoint.jointNode,wheel.driveNode);
			self.acDimensions.wheelBase = self.acDimensions.wheelBase + math.abs(z);
			n  = n  + 1;
		end
		if n > 1 then
			self.acDimensions.wheelBase = self.acDimensions.wheelBase / n;
		end
	else
		local left  = {};
		local right = {};
		local nl0,zl0,nr0,zr0,zlm,alm,zrm,arm,zlmi,almi,zrmi,armi = 0,0,0,0,-99,0,-99,0,99,0,99,0;
		for _,wheel in pairs(self.wheels) do
			local x,y,z = AutoTractor.getRelativeTranslation(self.acRefNode,wheel.driveNode);
			local a = 0.5 * (math.abs(wheel.rotMin)+math.abs(wheel.rotMax));

			if     wheel.rotSpeed >  1E-03 then
				if x > 0 then
					if zlm < z then
						zlm = z;
						alm = a;
					end
				else
					if zrm < z then
						zrm = z;
						arm = a;
					end
				end
			elseif wheel.rotSpeed > -1E-03 then
				if x > 0 then
					zl0 = zl0 + z;
					nl0 = nl0 + 1;
				else
					zr0 = zr0 + z;
					nr0 = nr0 + 1;
				end
			else
				if x > 0 then
					if zlmi > z then
						zlmi = z;
						almi = -a;
					end
				else
					if zrmi > z then
						zrmi = z;
						armi = -a;
					end
				end
			end	
		end
		
		if zlm > -98 and zrm > -98 then
			alm = 0.5 * ( alm + arm );
			zlm = 0.5 * ( zlm + zrm );
		elseif zrm > -98 then
			alm = arm;
			zlm = zrm;
		end
		if zlmi < 98 and zrmi < 98 then
			almi = 0.5 * ( almi + armi );
			zlmi = 0.5 * ( zlmi + zrmi );
		elseif zrmi > -98 then
			almi = armi;
			zlmi = zrmi;
		end
				
		if nl0 > 0 or nr0 > 0 then
			self.acDimensions.zOffset = ( zl0 + zr0 ) / ( nl0 + nr0 );
		
			if     zlm > -98 then
				self.acDimensions.wheelBase = zlm - self.acDimensions.zOffset;
				self.acDimensions.maxSteeringAngle = alm;
			elseif zlmi < 98 then
				self.acDimensions.wheelBase = self.acDimensions.zOffset - zlmi;
				self.acDimensions.maxSteeringAngle = almi;
			else
				self.acDimensions.wheelBase = 0;
			end
		elseif zlm > -98 and zlmi < 98 then
-- all wheel steering					
			self.acDimensions.maxSteeringAngle = math.max( math.abs( alm ), math.abs( almi ) );
			local t1 = math.tan( alm );
			local t2 = math.tan( almi );
			
			self.acDimensions.zOffset   = ( t1 * zlmi - t2 * zlm ) / ( t1 - t2 );
			self.acDimensions.wheelBase = zlm - self.acDimensions.zOffset;
		end
	end
	
	self.acDimensions.maxLookingAngle = math.min( self.acDimensions.maxSteeringAngle, math.rad(15) );
	if math.abs( self.acDimensions.wheelBase ) > 1E-3 and math.abs( self.acDimensions.maxSteeringAngle ) > 1E-4 then
		self.acDimensions.radius        = self.acDimensions.wheelBase / math.tan( self.acDimensions.maxSteeringAngle );
	else
		self.acDimensions.radius        = 5;
	end

	AutoTractor.calculateDistances(self)
end

------------------------------------------------------------------------
-- addTool
------------------------------------------------------------------------
function AutoTractor:addTool(object,reference)
	if object.aiLeftMarker ~= nil and object.aiRightMarker ~= nil then
		local tool   = {};
		
		if reference == nil then
			tool.refNode = self.acRefNode;
		else
			tool.refNode = reference;
		end
		
		if object.aiBackMarker == nil then
			tool.aiBackMarker = object.aiLeftMarker;
		else
			tool.aiBackMarker = object.aiBackMarker;
		end
		
		local xl,_,_ = AutoTractor.getRelativeTranslation(tool.refNode,object.aiLeftMarker);
		local xr,_,_ = AutoTractor.getRelativeTranslation(tool.refNode,object.aiRightMarker);
		local d = math.max( xl, -xr ); 
		
		if self.acDimensions.distance < d then
			self.acDimensions.distance = d;
		end
		
		self.acTools[object] = tool;
	end
end

------------------------------------------------------------------------
-- calculateDistances
------------------------------------------------------------------------
function AutoTractor:calculateDistances()

	self.acDimensions.distance = 99;
	
	self.acTools = {};
	AutoTractor.addTool(self,self,self.acRefNode);
	
	for _, implement in pairs(self.attachedImplements) do
		if implement.object ~= nil and implement.object.attacherJoint ~= nil and implement.object.attacherJoint.node ~= nil then
			AutoTractor.addTool(self,implement.object,implement.object.attacherJoint.node);
		end
	end	

	local optimDist                   = 0.5+self.acDimensions.distance;
	if self.acDimensions.radius > optimDist then
		self.acDimensions.uTurnAngle    = math.acos( optimDist / self.acDimensions.radius );
	else
		self.acDimensions.uTurnAngle    = 0;
	end;

	self.acDimensions.distance0       = self.acDimensions.distance;
	self.acDimensions.distance        = self.acDimensions.distance0 + self.acParameters.widthOffset;
	self.acDimensions.maxLookingAngle = math.min( 15 ,self.acDimensions.maxSteeringAngle);
	self.acDimensions.insideDistance  = 1
	
	self.acDimensions.uTurnDistance   = math.max(2, 1 + self.acDimensions.distance - self.acDimensions.radius);
	self.acDimensions.uTurnDistance2  = math.max(1, 1 + self.acDimensions.distance - self.acDimensions.radius );
	
	self.acDimensions.insideDistance  = math.max( 1, self.acDimensions.insideDistance + self.acParameters.turnOffset );
  self.acDimensions.uTurnDistance   = math.max( 1, self.acDimensions.uTurnDistance  + self.acParameters.turnOffset );
  self.acDimensions.uTurnDistance2  = math.max( 1, self.acDimensions.uTurnDistance2 + self.acParameters.turnOffset );
	
end

------------------------------------------------------------------------
-- getRelativeTranslation
------------------------------------------------------------------------
function AutoTractor.getRelativeTranslation(root,node)
	local x,y,z;
	if getParent(node)==root then
		x,y,z = getTranslation(node);
	else
		x,y,z = worldToLocal(root,getWorldTranslation(node));
	end;
	return x,y,z;
end

------------------------------------------------------------------------
-- calculateSteeringAngle
------------------------------------------------------------------------
function AutoTractor.calculateSteeringAngle(self,x,z)
	local angle = 0;
	return angle;
end;

------------------------------------------------------------------------
-- calculateWidth
------------------------------------------------------------------------
function AutoTractor:calculateWidth(z,angle)
	if math.abs(z)<1E-6 then
		return 0;
	end;
	
	return z*math.tan(angle);
end;

------------------------------------------------------------------------
-- getParallelogram
------------------------------------------------------------------------
function AutoTractor:getParallelogram( xOffset, zOffset, width, height, diff )
	local startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ;
	
	startWorldX,_,startWorldZ   = localToWorld( self.acRefNode, xOffset,         0, zOffset );
	widthWorldX,_,widthWorldZ   = localToWorld( self.acRefNode, xOffset + width, 0, zOffset );
	heightWorldX,_,heightWorldZ = localToWorld( self.acRefNode, xOffset + diff,  0, zOffset + height );	
	
	return startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ;
end

------------------------------------------------------------------------
-- saveDirection
------------------------------------------------------------------------
function AutoTractor:saveDirection( cumulate )

	if cumulate then
		local vector = {};	
		vector.dx,_,vector.dz = localDirectionToWorld( self.acRefNode, 0,0,1 );
		vector.px,_,vector.pz = getWorldTranslation( self.acRefNode );
		
		if self.acDirectionBeforeTurn.traceIndex == nil then
			self.acDirectionBeforeTurn.trace = {};
			self.acDirectionBeforeTurn.traceIndex = 0;
		end;
		
		local count = table.getn(self.acDirectionBeforeTurn.trace);
		if count > 100 and self.acDirectionBeforeTurn.traceIndex == count then
			local x = self.acDirectionBeforeTurn.trace[self.acDirectionBeforeTurn.traceIndex].px - self.acDirectionBeforeTurn.trace[1].px;
			local z = self.acDirectionBeforeTurn.trace[self.acDirectionBeforeTurn.traceIndex].pz - self.acDirectionBeforeTurn.trace[1].pz;		
		
			if x*x + z*z > 36 then 
				self.acDirectionBeforeTurn.traceIndex = 0
			end
		end;
		self.acDirectionBeforeTurn.traceIndex = self.acDirectionBeforeTurn.traceIndex + 1;
		
		self.acDirectionBeforeTurn.trace[self.acDirectionBeforeTurn.traceIndex] = vector;
		self.acDirectionBeforeTurn.a = nil;
		self.acDirectionBeforeTurn.x = vector.px;
		self.acDirectionBeforeTurn.z = vector.pz;
		
		if self.lastValidInputFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
			local hasFruitPreparer = false
			if self.fruitPreparerFruitType ~= nil and self.fruitPreparerFruitType == self.lastValidInputFruitType then
				hasFruitPreparer = true
			end
				
			local lx,lz;
			if self.acParameters.leftAreaActive then
				lx = self.acDimensions.xRight;
				lz = self.acDimensions.zRight;
			else
				lx = self.acDimensions.xLeft;
				lz = self.acDimensions.zLeft;
			end
	
			local x,_,z = localToWorld( self.acRefNode, lx, 0, lz );
			
			if true then --Utils.getFruitArea(self.lastValidInputFruitType, x-1,z-1,x+1,z-1,x-1,z+1, hasFruitPreparer) > 0 then	
				self.acDirectionBeforeTurn.tx = x;
				self.acDirectionBeforeTurn.tz = z;
			end
		end
	else
		self.acDirectionBeforeTurn.trace = {};
		self.acDirectionBeforeTurn.traceIndex = 0;
		self.acDirectionBeforeTurn.sx, _, self.acDirectionBeforeTurn.sz = getWorldTranslation( self.acRefNode );
	end
end

------------------------------------------------------------------------
-- getFirstTraceIndex
------------------------------------------------------------------------
function AutoTractor:getFirstTraceIndex()
	if     self.acDirectionBeforeTurn.trace      == nil 
			or self.acDirectionBeforeTurn.traceIndex == nil 
			or self.acDirectionBeforeTurn.traceIndex < 1 then
		return nil;
	end;
	local l = table.getn(self.acDirectionBeforeTurn.trace);
	if l < 1 then
		return nil;
	end;
	local i = self.acDirectionBeforeTurn.traceIndex + 1;
	if i > l then i = 1 end
	return i;
end

------------------------------------------------------------------------
-- getTurnDistance
------------------------------------------------------------------------
function AutoTractor:getTurnDistance()
	if     self.acRefNode               == nil
			or self.acDirectionBeforeTurn   == nil
			or self.acDirectionBeforeTurn.x == nil
			or self.acDirectionBeforeTurn.z == nil then
		return 0
	end;
	local x,_,z = getWorldTranslation( self.acRefNode );
	x = x - self.acDirectionBeforeTurn.x;
	z = z - self.acDirectionBeforeTurn.z;
	return math.sqrt( x*x + z*z )
end

------------------------------------------------------------------------
-- getTraceLength
------------------------------------------------------------------------
function AutoTractor.getTraceLength( self )
	if self.acDirectionBeforeTurn.trace == nil then
		return 0;
	end;
	
	if table.getn(self.acDirectionBeforeTurn.trace) < 2 then
		return 0;
	end;
	
	local i = AutoTractor.getFirstTraceIndex( self );
	if i == nil then
		return 0;
	end
	
	local x = self.acDirectionBeforeTurn.trace[self.acDirectionBeforeTurn.traceIndex].px - self.acDirectionBeforeTurn.sx;
	local z = self.acDirectionBeforeTurn.trace[self.acDirectionBeforeTurn.traceIndex].pz - self.acDirectionBeforeTurn.sz;
	
	return math.sqrt( x*x + z*z );
end;

------------------------------------------------------------------------
-- getTurnAngle
------------------------------------------------------------------------
function AutoTractor.getTurnAngle( self )			
	if self.acDirectionBeforeTurn.a == nil then
		local i = AutoTractor.getFirstTraceIndex( self );
		if i == nil then
			return 0
		end
		if i == self.acDirectionBeforeTurn.traceIndex then
			return 0
		end
		local l = AutoTractor.getTraceLength( self );
		if l < 1E-3 then
			return 0
		end

		local vx = self.acDirectionBeforeTurn.trace[self.acDirectionBeforeTurn.traceIndex].px - self.acDirectionBeforeTurn.trace[i].px;
		local vz = self.acDirectionBeforeTurn.trace[self.acDirectionBeforeTurn.traceIndex].pz - self.acDirectionBeforeTurn.trace[i].pz;		
		self.acDirectionBeforeTurn.a = Utils.getYRotationFromDirection(vx/l,vz/l);
	end;

	local x,y,z = localDirectionToWorld( self.acRefNode, 0,0,1 );
	
	local angle = Utils.getYRotationFromDirection(x,z) - self.acDirectionBeforeTurn.a;
	while angle < math.pi do 
		angle = angle+math.pi+math.pi; 
	end;
	while angle > math.pi do
		angle = angle-math.pi-math.pi; 
  end;
	
	return angle;
end;	

------------------------------------------------------------------------
-- Manually switch to next turn stage
------------------------------------------------------------------------
function AutoTractor:setNextTurnStage(noEventSend)

	if self.acParameters.enabled then
	else
		if self.turnStage > 0 and self.turnStage < 4 then
			self.turnStage = self.turnStage + 1;
		end
	end

  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(AutoTractorNextTSEvent:new(self), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(AutoTractorNextTSEvent:new(self))
    end
  end
end;

------------------------------------------------------------------------
-- Event stuff
------------------------------------------------------------------------
function AutoTractor:getParameters()
	if self.acParameters == nil then
		self.acParameters = {}
		self.acParameters.upNDown = false;
		self.acParameters.leftAreaActive = true;
		self.acParameters.rightAreaActive = false;
		self.acParameters.enabled = false;
		self.acParameters.noReverse = false;
		self.acParameters.CPSupport = false;
		self.acParameters.turnOffset = 0;
		self.acParameters.widthOffset = 0;
	end;

	return self.acParameters;
end;

local function atReadStream(streamId)
	local parameters = {};
	
	parameters.enabled         = streamReadBool(streamId);
	parameters.upNDown	       = streamReadBool(streamId);
	parameters.rightAreaActive = streamReadBool(streamId);
	parameters.noReverse       = streamReadBool(streamId);
	parameters.CPSupport       = streamReadBool(streamId);
	parameters.turnOffset      = streamReadFloat32(streamId);
	parameters.widthOffset     = streamReadFloat32(streamId);

	return parameters;
end

local function atWriteStream(streamId, parameters)
	streamWriteBool(streamId, Utils.getNoNil( parameters.enabled        ,false ));
	streamWriteBool(streamId, Utils.getNoNil( parameters.upNDown	      ,false ));
	streamWriteBool(streamId, Utils.getNoNil( parameters.rightAreaActive,false ));
	streamWriteBool(streamId, Utils.getNoNil( parameters.noReverse      ,false ));
	streamWriteBool(streamId, Utils.getNoNil( parameters.CPSupport      ,false ));
	streamWriteFloat32(streamId, Utils.getNoNil( parameters.turnOffset  ,0 ));
	streamWriteFloat32(streamId, Utils.getNoNil( parameters.widthOffset ,0 ));
end

function AutoTractor:setParameters(parameters)
	local turnOffset = 0;
	if self.acParameters ~= nil and self.acParameters.turnOffset ~= nil then
		turnOffset = self.acParameters.turnOffset
	end
	local widthOffset = 0;
	if self.acParameters ~= nil and self.acParameters.widthOffset ~= nil then
		widthOffset = self.acParameters.widthOffset
	end
	
	self.acParameters = {}
	self.acParameters.enabled         = Utils.getNoNil(parameters.enabled        ,false);
	self.acParameters.upNDown         = Utils.getNoNil(parameters.upNDown        ,false);
	self.acParameters.rightAreaActive = Utils.getNoNil(parameters.rightAreaActive,false);
	self.acParameters.noReverse       = Utils.getNoNil(parameters.noReverse      ,false);
	self.acParameters.CPSupport       = Utils.getNoNil(parameters.CPSupport      ,false);
	self.acParameters.turnOffset      = Utils.getNoNil(parameters.turnOffset     ,0);
	self.acParameters.widthOffset     = Utils.getNoNil(parameters.widthOffset    ,0);
	self.acParameters.leftAreaActive  = not self.acParameters.rightAreaActive;
		
	if self.acDimensions ~= nil then
		if     math.abs( self.acParameters.turnOffset  - turnOffset  ) > 1E-6
				or math.abs( self.acParameters.widthOffset - widthOffset ) > 1E-6 then
			AutoTractor.calculateDistances( self )
		end
	end
end

function AutoTractor:readStream(streamId, connection)
  AutoTractor.setParameters( self, acReadStream(streamId) );
end

function AutoTractor:writeStream(streamId, connection)
  acWriteStream(streamId,AutoTractor.getParameters(self));
end

function AutoTractor:sendParameters(noEventSend)
	if self.acDimensions ~= nil then
		AutoTractor.calculateDistances( self )
	end

  if noEventSend == nil or noEventSend == false then
    if g_server ~= nil then
      g_server:broadcastEvent(AutoTractorParametersEvent:new(self, AutoTractor.getParameters(self)), nil, nil, self)
    else
      g_client:getServerConnection():sendEvent(AutoTractorParametersEvent:new(self, AutoTractor.getParameters(self)))
    end
  end
end;

AutoTractorParametersEvent = {}
AutoTractorParametersEvent_mt = Class(AutoTractorParametersEvent, Event)
InitEventClass(AutoTractorParametersEvent, "AutoTractorParametersEvent")
function AutoTractorParametersEvent:emptyNew()
  local self = Event:new(AutoTractorParametersEvent_mt)
  return self
end
function AutoTractorParametersEvent:new(object, parameters)
  local self = AutoTractorParametersEvent:emptyNew()
  self.object     = object;
  self.parameters = parameters;
  return self
end
function AutoTractorParametersEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object = networkGetObject(id)
	self.parameters = acReadStream(streamId);
  self:run(connection)
end
function AutoTractorParametersEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
	acWriteStream(streamId, self.parameters);
end
function AutoTractorParametersEvent:run(connection)
  AutoTractor.setParameters(self.object,self.parameters);
  if not connection:getIsServer() then
    g_server:broadcastEvent(AutoTractorParametersEvent:new(self.object, self.parameters), nil, connection, self.object)
  end
end


AutoTractorNextTSEvent = {}
AutoTractorNextTSEvent_mt = Class(AutoTractorNextTSEvent, Event)
InitEventClass(AutoTractorNextTSEvent, "AutoTractorNextTSEvent")
function AutoTractorNextTSEvent:emptyNew()
  local self = Event:new(AutoTractorNextTSEvent_mt)
  return self
end
function AutoTractorNextTSEvent:new(object)
  local self = AutoTractorNextTSEvent:emptyNew()
  self.object     = object;
  return self
end
function AutoTractorNextTSEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object = networkGetObject(id)
  self:run(connection)
end
function AutoTractorNextTSEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
end
function AutoTractorNextTSEvent:run(connection)
  AutoTractor.setNextTurnStage(self.object,true);
  if not connection:getIsServer() then
    g_server:broadcastEvent(AutoTractorNextTSEvent:new(self.object), nil, connection, self.object)
  end
end

AutoTractorTurnStageEvent = {}
AutoTractorTurnStageEvent_mt = Class(AutoTractorTurnStageEvent, Event)
InitEventClass(AutoTractorTurnStageEvent, "AutoTractorTurnStageEvent")
function AutoTractorTurnStageEvent:emptyNew()
  local self = Event:new(AutoTractorTurnStageEvent_mt)
  return self
end
function AutoTractorTurnStageEvent:new(object,turnStage)
  local self = AutoTractorTurnStageEvent:emptyNew()
  self.object     = object;
	self.turnStage  = turnStage;
  return self
end
function AutoTractorTurnStageEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object    = networkGetObject(id)
	self.turnStage = streamReadInt32(streamId)
  self:run(connection)
end
function AutoTractorTurnStageEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteInt32(streamId, self.turnStage)
end
function AutoTractorTurnStageEvent:run(connection)
  self.object.acTurnStage     = self.turnStage;
  self.object.acTurnStageSent = self.turnStage;
  if not connection:getIsServer() then
    g_server:broadcastEvent(AutoTractorTurnStageEvent:new(self.object,self.turnStage), nil, connection, self.object)
  end
end


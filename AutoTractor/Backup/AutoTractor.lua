--
-- AutoTractor
-- Extended AITractor
--
-- @author  Mogli aka biedens
-- @version 0.8.0.2
-- @date    01.02.2014
--
--  code source: AITractor.lua by Giants Software    
 
AutoTractor = {};
local AtDirectory = g_currentModDirectory;

	source(Utils.getFilename("Mogli.lua", AtDirectory));
	source(Utils.getFilename("AutoSteeringEngine.lua", AtDirectory));

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
	
	-- for courseplay  
	self.acNumCollidingVehicles = 0;
	self.acIsCPStopped          = false;
	self.acTurnStage            = 0;
	
	self.acParameters = {}
	self.acParameters.upNDown 							= true;
	self.acParameters.leftAreaActive = true;
  self.acParameters.rightAreaActive = false;
  self.acParameters.enabled = false;
  self.acParameters.noReverse = false;
  self.acParameters.headland = false;
	self.acParameters.turnOffset = 0;
	self.acParameters.widthOffset = 0;
	self.acParameters.angleOffset = 0;

	self.acDeltaTimeoutWait   = math.max(Utils.getNoNil( self.waitForTurnTimeout, 1500 ), 1000 ); 
	self.acDeltaTimeoutRun    = math.max(Utils.getNoNil( self.driveBackTimeout  , 1000 ),  500 );
	self.acDeltaTimeoutStop   = math.max(Utils.getNoNil( self.turnStage1Timeout , 20000), 10000);
	self.acDeltaTimeoutStart  = math.max(Utils.getNoNil( self.turnTimeoutLong   , 6000 ), 4000 );
	self.acDeltaTimeoutNoTurn = math.max(Utils.getNoNil( self.turnStage4Timeout , 2000 ), 1000 );
	self.acSteeringSpeed      = Utils.getNoNil( self.aiSteeringSpeed, 0.001 );
	self.acRecalculateDt      = 0;
	self.acTurn2Outside       = false;
	self.acCollidingVehicles   = {};
	self.acTurnStageSent       = 0;
	self.acWaitTimer           = 0;

	detected = nil;	
	fruitsDetected = nil;

	--self.acTools = {}
	--
	--local xmlFile = loadXMLFile( "acTurnStages", Utils.getFilename("turnStages.xml", AtDirectory) );
	--
	--self.acTurnStages = {};
	--i = 0;
	--while true do
	--	local tsnamei = string.format("turnStages.turnStage(%d)", i)
  --  local tsStr
	--	local tsName = getXMLString(xmlFile, tsnamei .. "#name")
  --  if tsName == nil then
  --    break
  --  end
  --  local turnStage = {}
	--	
	--	local tsStr
	--	tsStr = getXMLString(xmlFile, tsnamei .. "#next")
	--	if tsStr ~= nil then
	--		turnStage.next = tsStr;
	--	end
	--	
	--	tsStr = getXMLString(xmlFile, tsnamei .. "#function")
	--	if tsStr ~= nil then
	--		turnStage.function = tsStr;
	--	end
  --
	--	local tsInt getXMLInt(xmlFile, tsnamei .. "#timeout")
	--	if tsInt ~= nil then
	--		turnStage.timeout = tsInt
	--	end
	--	
	--	turnStage.parameters = {}
	--	for j=0,99 do
	--		local pnamei = tsnamei .. string.format(".parameter(%d)",j)
	--		local tsType = getXMLString(xmlFile, pnamei .. "#type")
	--		if tsType == nil then
	--			break
	--		end
	--		if     tsType == "float" then
	--			local tsValue = getXMLFloat(xmlFile, pnamei .. "#value")
	--			turnStage.parameters[j] = tsValue
	--		elseif tsType == "int" then
	--			local tsValue = getXMLInt(xmlFile, pnamei .. "#value")
	--			turnStage.parameters[j] = tsValue
	--		elseif tsType == "string" then
	--			local tsValue = getXMLString(xmlFile, pnamei .. "#value")
	--			turnStage.parameters[j] = tsValue
	--		end
	--	end
	--	
	--	self.acTurnStages[tsName] = turnStage;
	--	i = i + 1
	--end
	--
	--for n,t in pairs(self.acTurnStages) do
	--	print(n.." -> "..tostring(t.next))
	--	for i,p in pairs(t.parameters) do
	--		print(tostring(i)..": "..tostring(p))
	--	end
	--end
	
  self.acAutoRotateBackSpeedBackup = self.autoRotateBackSpeed;	

	Mogli.init( self, AtDirectory, "AutoTractorHud", "AutoTractorHud.dds",  "AUTO_TRACTOR_TEXTHELPPANELON", "AUTO_TRACTOR_TEXTHELPPANELOFF", InputBinding.AUTO_TRACTOR_HELPPANEL, 0.025, 0.0108, 4, 4, AutoTractor.sendParameters )

	Mogli.addButton(self, "off.dds",            "on.dds",           AutoTractor.onStart,       AutoTractor.evalStart,     1,1, "HireEmployee", "DismissEmployee" );
	Mogli.addButton(self, "ai_combine.dds",     "auto_combine.dds", AutoTractor.onEnable,      AutoTractor.evalEnable,    2,1, "AUTO_TRACTOR_STOP", "AUTO_TRACTOR_START" );
	Mogli.addButton(self, "no_uturn2.dds",      "uturn.dds",        AutoTractor.setUTurn,      AutoTractor.evalUTurn,     3,1, "AUTO_TRACTOR_UTURN_OFF", "AUTO_TRACTOR_UTURN_ON") ;
	Mogli.addButton(self, "next.dds",           "no_next.dds",      AutoTractor.nextTurnStage, AutoTractor.evalTurnStage, 4,1, "AUTO_TRACTOR_NEXTTURNSTAGE", nil );
	
	Mogli.addButton(self, "noHeadland.dds",     "headland.dds",     AutoTractor.setHeadland,   AutoTractor.evalHeadland,  1,2, "AUTO_TRACTOR_HEADLAND_ON", "AUTO_TRACTOR_HEADLAND_OFF" );
	Mogli.addButton(self, "reverse.dds",        "no_reverse.dds",   AutoTractor.setNoReverse,  AutoTractor.evalNoReverse, 2,2, "AUTO_TRACTOR_REVERSE_ON", "AUTO_TRACTOR_REVERSE_OFF");
	
	Mogli.addButton(self, "auto_steer_off.dds", "auto_steer_on.dds",AutoTractor.onAutoSteer,   AutoTractor.evalAutoSteer, 4,2, "AUTO_TRACTOR_STEER_ON", "AUTO_TRACTOR_STEER_OFF" );
	
	Mogli.addButton(self, "inactive_left.dds",  "active_left.dds",  AutoTractor.setAreaLeft,   AutoTractor.evalAreaLeft,  1,3, "AUTO_TRACTOR_ACTIVESIDERIGHT", "AUTO_TRACTOR_ACTIVESIDELEFT" );
	Mogli.addButton(self, "inactive_right.dds", "active_right.dds", AutoTractor.setAreaRight,  AutoTractor.evalAreaRight, 2,3, "AUTO_TRACTOR_ACTIVESIDELEFT", "AUTO_TRACTOR_ACTIVESIDERIGHT" );	
	Mogli.addButton(self, "angle_plus.dds",     "empty.dds",        AutoTractor.setAngleUp,    AutoTractor.evalAngleUp,   3,3, "AUTO_TRACTOR_ANGLE_OFFSET", nil, AutoTractor.getAngleOffset);
	Mogli.addButton(self, "angle_minus.dds",    "empty.dds",        AutoTractor.setAngleDown,  AutoTractor.evalAngleDown, 4,3, "AUTO_TRACTOR_ANGLE_OFFSET", nil, AutoTractor.getAngleOffset);

	Mogli.addButton(self, "bigger.dds",         nil,                AutoTractor.setWidthUp,    nil,                       1,4, "AUTO_TRACTOR_WIDTH_OFFSET", nil, AutoTractor.getWidth);
	Mogli.addButton(self, "smaller.dds",        nil,                AutoTractor.setWidthDown,  nil,                       2,4, "AUTO_TRACTOR_WIDTH_OFFSET", nil, AutoTractor.getWidth);
	Mogli.addButton(self, "forward.dds",        nil,                AutoTractor.setForward,    nil,                       3,4, "AUTO_TRACTOR_TURN_OFFSET", nil, AutoTractor.getTurnOffset);
	Mogli.addButton(self, "backward.dds",       nil,                AutoTractor.setBackward,   nil,                       4,4, "AUTO_TRACTOR_TURN_OFFSET", nil, AutoTractor.getTurnOffset);
	
	
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
	
	self.acHasRoueSpec = false;
	for name,entry in pairs( SpecializationUtil.specializations ) do
		local s,e = string.find( entry.className, ".Roue" )
		if s ~= nil and e == string.len( entry.className ) then
			local c = SpecializationUtil.getSpecialization(entry.name);
			if SpecializationUtil.hasSpecialization(c, self.specializations) then
				self.acHasRoueSpec = true;
				print( self.name.." has Roue spec." );
				if c.changeSteer ~= nil then
					c.changeSteer = Utils.appendedFunction( c.changeSteer, AutoTractor.roueChangeSteer );
					print( "Append to changeSteer registered" );
				end
			end
		end
	end
	
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

function AutoTractor:evalHeadland()
	return not ( self.acParameters.upNDown and self.acParameters.headland );
end

function AutoTractor:setHeadland(enabled)
	if self.acParameters.upNDown then
		self.acParameters.headland = enabled;
	end
end

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
    AITractor.stopAITractor(self)
  elseif AITractor.canStartAITractor(self) and enabled then
    AITractor.startAITractor(self)
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
end;

function AutoTractor:setWidthDown()
	self.acParameters.widthOffset = self.acParameters.widthOffset - 0.125;
end;

function AutoTractor:getWidth(old)
	new = string.format(old..": %0.2fm",self.acParameters.widthOffset+self.acParameters.widthOffset);
	return new
end

function AutoTractor:setForward()
	self.acParameters.turnOffset = self.acParameters.turnOffset + 0.25;
end;                                               

function AutoTractor:setBackward()               
	self.acParameters.turnOffset = self.acParameters.turnOffset - 0.25;
end;

function AutoTractor:getTurnOffset(old)
	new = string.format(old..": %0.2fm",self.acParameters.turnOffset);
	return new
end

function AutoTractor:evalAngleUp()
	local enabled = self.acParameters.angleOffset < ASEGlobals.maxLooking;
	return enabled
end

function AutoTractor:evalAngleDown()
	local enabled = self.acParameters.angleOffset > 1-ASEGlobals.maxLooking;
	return enabled
end

function AutoTractor:setAngleUp(enabled)
	if enabled then self.acParameters.angleOffset = self.acParameters.angleOffset + 1 end
end

function AutoTractor:setAngleDown(enabled)
	if enabled then self.acParameters.angleOffset = self.acParameters.angleOffset - 1 end
end

function AutoTractor:getAngleOffset(old)
	new = string.format(old..": %2i",ASEGlobals.maxLooking + self.acParameters.angleOffset);
	return new
end

function AutoTractor:evalTurnStage()
	if self.acParameters.enabled then
		if     self.acTurnStage == 3 
				or self.acTurnStage == 12
				or self.acTurnStage == 15
				or self.acTurnStage == 17
				or self.acTurnStage == 18 
				or self.acTurnStage == 22 
				or self.acTurnStage == 23 
				or self.acTurnStage == 25 
				or self.acTurnStage == 27 
				or self.acTurnStage == 32 
				or self.acTurnStage == 33 
				or self.acTurnStage == 35 
				or self.acTurnStage == 37 
			then
			return true
		end
	else
		if self.turnStage > 0 and self.turnStage < 4 then
			return true;
		end
	end
	
	return false
end

function AutoTractor:nextTurnStage()
	AutoTractor.setNextTurnStage(self);
end

--function AutoTractor:evalCPSupport()
--	return not self.acParameters.headland;
--end
--
--function AutoTractor:setCPSupport(enabled)
--	self.acParameters.headland = enabled;
--end

function AutoTractor:evalAutoSteer()
	return self.isAITractorActivated or self.acTurnStage < 98
end

function AutoTractor:onAutoSteer(enabled)
	if self.isAITractorActivated then
		if self.acTurnStage >= 98 then
			self.acTurnStage   = 0
		end
	elseif enabled then
		self.setAIImplementsMoveDown(self,true);
		self.acLastSteeringAngle = nil;
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

	if atDump and self:getIsActiveForInput(false) then
		AutoTractor.acDump2(self);
	end

	if self:getIsActiveForInput(false) then
		if InputBinding.hasEvent(InputBinding.AUTO_TRACTOR_HELPPANEL) then
			AutoTractor.showGui( self, not self.mogliGuiActive );
		end;
		if InputBinding.hasEvent(InputBinding.AUTO_TRACTOR_STEER) then
			if self.acTurnStage < 98 then
				AutoTractor.onAutoSteer(self, true)
			else
				AutoTractor.onAutoSteer(self, false)
			end
		end
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
	
	if      self:getIsActiveForInput(false) 
			and ASEGlobals.showTrace > 0 
			and self.acDimensions ~= nil
			and ( self.isAITractorActivated
				 --or self.mogliGuiActive 
				 or self.acTurnStage >= 98 ) then	

		--if not ( self.isAITractorActivated or self.acTurnStage >= 98 ) then			  
		--	AutoTractor.checkState( self );
		--	AutoSteeringEngine.setChainContinued( self );
		--end
				 
		AutoSteeringEngine.drawLines( self );
	end
end

------------------------------------------------------------------------
-- updateTick
------------------------------------------------------------------------
function AutoTractor:updateTick(dt)
end

function AutoTractor:newUpdateTick(dt)

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
AITractor.updateTick = Utils.appendedFunction( AITractor.updateTick, AutoTractor.newUpdateTick );

------------------------------------------------------------------------
-- updateToolsInfo
------------------------------------------------------------------------
function AutoTractor:updateToolsInfo()
	self.aseTools = nil;
end
AITractor.updateToolsInfo = Utils.appendedFunction( AITractor.updateToolsInfo, AutoTractor.updateToolsInfo ); 

------------------------------------------------------------------------
-- AITractor:startAITractor
------------------------------------------------------------------------
function AutoTractor:startAITractor(noEventSend)
	
	-- just to be safe...
	if self.acParameters ~= nil and self.acParameters.enabled then
		self.acDimensions  = nil;
		self.acTurnStage   = -3;
		self.turnTimer     = self.acDeltaTimeoutWait;
		self.aiRescueTimer = self.acDeltaTimeoutStop;
		self.waitForTurnTime = 0;
		
		if self.speed2Level == nil or self.speed2Level < 1 or self.speed2Level > 4 then
			self.speed2Level = 1
		end
		
		AutoTractor.sendParameters(self);
	end
end;
AITractor.startAITractor = Utils.appendedFunction( AITractor.startAITractor, AutoTractor.startAITractor );

------------------------------------------------------------------------
-- AITractor:stopAITractor
------------------------------------------------------------------------
local oldAITractorStopAITractor = AITractor.stopAITractor;
AITractor.stopAITractor = function(self, noEventSend)
	return oldAITractorStopAITractor(self, noEventSend);
end;

------------------------------------------------------------------------
-- AITractor.canStartAITractor
------------------------------------------------------------------------
local oldAITractorCanStartAITractor = AITractor.canStartAITractor;
AITractor.canStartAITractor = function( self )

	if self.acParameters ~= nil and self.acParameters.enabled then
		if g_currentMission.disableTractorAI then
			return false;
		end;

		AutoTractor.checkState( self )
		if not AutoSteeringEngine.hasTools( self ) then
			return false;
		end;
		
		if Hirable.numHirablesHired >= g_currentMission.maxNumHirables then
			return false;
		end;
    return true;
	end

	return oldAITractorCanStartAITractor(self);	
end

------------------------------------------------------------------------
-- AITractor.getIsAITractorAllowed
------------------------------------------------------------------------
local oldAITractorGetIsAITractorAllowed = AITractor.getIsAITractorAllowed;
AITractor.getIsAITractorAllowed = function( self )

	if self.acParameters ~= nil and self.acParameters.enabled then
		if g_currentMission.disableTractorAI then
			return false;
		end;

		AutoTractor.checkState( self )
		if not AutoSteeringEngine.hasTools( self ) then
			return false;
		end;
		
		return true;
	end
	
	return oldAITractorGetIsAITractorAllowed( self );
end;

------------------------------------------------------------------------
-- checkState
------------------------------------------------------------------------
function AutoTractor:checkState( )

	if self.acDimensions == nil then
		AutoTractor.calculateDimensions( self )
	else
		AutoTractor.calculateDistances( self )
	end
	
	local h = 0;
	if self.acParameters.headland and self.acParameters.upNDown then
		h = self.acDimensions.headlandDist;
	end
	
	local maxLooking = self.acDimensions.maxSteeringAngle;
	--if self.acTurnStage == 0 then 
		maxLooking = self.acDimensions.maxLookingAngle
	--end
	
	AutoSteeringEngine.initTools( self, maxLooking, self.acParameters.leftAreaActive, self.acParameters.widthOffset, h );

end

------------------------------------------------------------------------
-- autoSteer
------------------------------------------------------------------------
function AutoTractor:autoSteer(dt)
	
	AutoTractor.checkState( self )

	if not AutoSteeringEngine.hasTools( self ) then
		self.acTurnStage = 0;
		return;
	end

--==============================================================		
	AutoSteeringEngine.currentSteeringAngle( self );
	local detectedBefore;
	if self.acTurnStage == 99 then
		AutoSteeringEngine.shiftChain( self, "outside" );
		detectedBefore = true;
	else
		AutoSteeringEngine.setChainOutside( self );
		detectedBefore = false;
	end
	
	local detected, angle, border = AutoSteeringEngine.processChain( self, detectedBefore );					
--==============================================================						
	
	if detected then
		if self.acTurnStage ~= 99 then
			self.acTurnStage = 99
			AutoSteeringEngine.saveDirection( self, false )
		end
		AutoSteeringEngine.saveDirection( self, true );
		self.turnTimer = self.acDeltaTimeoutRun
	else
		if self.acTurnStage == 99 then
			if border > ASEGlobals.maxBorder then
				if self.acParameters.leftAreaActive then
					angle = self.acDimensions.maxSteeringAngle;
				else
					angle = -self.acDimensions.maxSteeringAngle;
				end
			else
				if self.acParameters.leftAreaActive then
					angle = -self.acDimensions.maxSteeringAngle;
				else
					angle = self.acDimensions.maxSteeringAngle;
				end
			end
		else
			angle = 0; --AutoSteeringEngine:setChainStraight( angleFactor, -angleMax, angleMax );
		end
		
		self.turnTimer = self.turnTimer - dt;
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
	
--	if not self.acParameters.leftAreaActive then angle = -angle end
	if self.movingDirection < -1E-2 then 
		noReverseIndex = AutoSteeringEngine.getNoReverseIndex( self );
		
--********************* TODO		
		if noReverseIndex > 0 then
			local toolAngle = AutoSteeringEngine.getRelativeYRotation( self.steeringAxleNode, self.aseTools[noReverseIndex].steeringAxleNode );
			if self.aseTools[noReverseIndex].invert then
--********************* TODO		
				if toolAngle < 0 then
					toolAngle = toolAngle + math.pi
				else
					toolAngle = toolAngle - math.pi
				end
			end
			if ASEGlobals.reverseDir == 0 then
				angle = 0;
			end;
			angle = math.min( math.max( toolAngle - angle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		else
			angle = -angle 
		end
	end
	
	local targetRotTime = 0
	
	if self.acRotatedTime == nil then
		self.rotatedTime = 0
	else
		self.rotatedTime = self.acRotatedTime
	end
	
	local aiSteeringSpeed = self.aiSteeringSpeed;
	if detected then aiSteeringSpeed = aiSteeringSpeed * 0.5 end
	
	if self.isEntered then
		AutoSteeringEngine.steer( self, dt, angle, aiSteeringSpeed, detected );
	end
	
	self.acRotatedTime = self.rotatedTime
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
	local speedLevel = 1;
	if self.speed2Level ~= nil and 0 <= self.speed2Level and self.speed2Level <= 4 then
		speedLevel = self.speed2Level;
	end
	if speedLevel == 0 then
		allowedToDrive = false
	end
	
-- Speed level always 1 while turning	
	if self.acTurnStage > 0 and 0 < speedLevel and speedLevel < 4 then
		speedLevel = 1
	end

	if not allowedToDrive then
		AutoSteeringEngine.drive( self, dt, 0, 0, 0, 1, false, true, 0, 0.75 );
		return
	end

	if not self:getIsAITractorAllowed() then
		self:stopAITractor()
		return
	end

	local moveForwards = true

	local offsetOutside = 0;
	if     self.acParameters.rightAreaActive then
		offsetOutside = -1;
	elseif self.acParameters.leftAreaActive then
		offsetOutside = 1;
	end;
			
	self.turnTimer = self.turnTimer - dt;
	
	if self.acTurnStage <= 0 then
		self.aiRescueTimer = self.aiRescueTimer - dt;
	else
		self.aiRescueTimer = self.acDeltaTimeoutStop;
	end
	
	if self.aiRescueTimer < 0 then
		self:stopAITractor()
		return;
	end;
			
--==============================================================				
	if not AutoSteeringEngine.hasTools( self ) then
		self:stopAITractor()
		return;
	end

	local angle, angle2;
	local angleMax = self.acDimensions.maxLookingAngle;
	local detected = false;
	local fruitsDetected = false;
	local border   = 0;
	local angleFactor;
	local offsetOutside;
	local noReverseIndex = 0;
	
--==============================================================		
--==============================================================		
	local turnAngle = math.deg(AutoSteeringEngine.getTurnAngle(self));
	
	self.mogliInfoText = string.format( "Turn stage: %2i, angle: %3i",self.acTurnStage,turnAngle )

	if self.acParameters.leftAreaActive then
		turnAngle = -turnAngle;
	end;

	fruitsDetected = AutoSteeringEngine.hasFruits( self, 0.7 )
	
	noReverseIndex = AutoSteeringEngine.getNoReverseIndex( self );
	
--==============================================================				
	if self.acTurnStage <= 0 then
		AutoSteeringEngine.currentSteeringAngle( self );
		local detectedBefore;
		if self.acTurnStage == 0 then
			AutoSteeringEngine.shiftChain( self, "outside" );
			detectedBefore = true;
		else
		  AutoSteeringEngine.setChainOutside( self );
			detectedBefore = false;
		end
		detected, angle2, border = AutoSteeringEngine.processChain( self, detectedBefore );			

		--if detected and self.acTurnStage < 0 then
		--	local h = 0;
		--	if self.acParameters.headland and self.acParameters.upNDown then
		--		h = self.acDimensions.headlandDist;
		--	end
    --
		--	AutoSteeringEngine.initTools( self, self.acDimensions.maxLookingAngle, self.acParameters.leftAreaActive, self.acParameters.widthOffset, h );
		--	local angle3;
		--	detected,angle3,border = AutoSteeringEngine.processChain( self, detectedBefore );			
		--	if detected and math.abs( angle3 ) < math.abs( angle2 ) then
		--		angle2 = angle3;
		--	end
		--end
		
		self.acTurn2Outside = border > 0;
		
		if not detected then
			--if self.acTurn2Outside then
			--	if self.acTurnStage == -2 then
			--		angle = 0;
			--	else
			--		angle = angleMax
			--	end
			--elseif fruitsDetected then
			--	angle = -angleMax
			--elseif self.acTurnStage >= -1 then
			--	angle = -angleMax
			--else
			if self.acTurn2Outside then
				angle = angleMax
			elseif self.acTurnStage == -3 then
				angle = 0;
			elseif self.acTurnStage == -2 then
				local x,z = AutoSteeringEngine.getTurnVector( self, true );
				if self.acParameters.leftAreaActive then x = -x end
				if noReverseIndex <= 0 then x = x -1 end
				
				if z < 0 then
					angle = -angleMax					
				else
					local a = math.pi - AutoSteeringEngine.getTurnAngle( self );
					local f = 1 - math.cos( a );
					
					if math.abs( f ) < 1E-3 then
						angle = 0
					else
						local r = x / f;
						if math.abs( r ) < 1E-3 then
							angle = 0
						else	
							angle = math.atan( self.acDimensions.wheelBase / r )
							angle = math.min( math.max( angle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
						end
					end
				end
			elseif self.acTurnStage == -1 then
				angle = -angleMax					
			elseif AutoSteeringEngine.noTurnAtEnd( self ) then
				angle = math.min( math.max( math.rad( turnAngle ), -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
			else
				angle = -angleMax					
			end
		end
--==============================================================				
	elseif self.acTurnStage == 8 then	
		AutoSteeringEngine.currentSteeringAngle( self );
		AutoSteeringEngine.setChainStraight( self );			
		border = AutoSteeringEngine.getAllChainBorders( self );
		if border > 0 then detected = true end
	
--==============================================================				
	elseif self.acTurnStage == 25
			or self.acTurnStage == 35 then	
		detected = false;
	elseif self.acTurnStage == 27
			or self.acTurnStage == 37 then	
		AutoSteeringEngine.currentSteeringAngle( self );
		AutoSteeringEngine.setChainOutside( self );			
		detected, angle2, border = AutoSteeringEngine.processChain( self );					
	
--==============================================================				
-- backwards
	elseif self.acTurnStage == 3 or self.acTurnStage == 18 then
		if self.acParameters.leftAreaActive == self.acTurn2Outside then
			AutoSteeringEngine.setSteeringAngle( self, self.acDimensions.maxLookingAngle );
		else
			AutoSteeringEngine.setSteeringAngle( self, -self.acDimensions.maxLookingAngle );
		end
		if self.acTurn2Outside then
			AutoSteeringEngine.setChainOutside( self );		
		else
			AutoSteeringEngine.setChainStraight( self );		
		end
		
		--if noReverseIndex > 0 then	
		--	if self.acTurn2Outside then
		--		border = 0;
		--	else
		--		border = 2;
		--	end
		--else
		--	border = AutoSteeringEngine.getAllChainBorders( self );
		--end
		
		if self.acTurn2Outside then
			angle    = -self.acDimensions.maxSteeringAngle;
		else
			angle    = self.acDimensions.maxSteeringAngle;
		end
		
		--local testBorder = border <= ASEGlobals.maxBorder;
		--
		--if self.acTurn2Outside == testBorder then
			local db = self.acTurn2Outside;
			if self.acTurnStage == 18 then db = false end
			angle = nil;
			detected, angle2, border = AutoSteeringEngine.processChain( self, db );					
			angle2 = -angle2
		--end
	
		if noReverseIndex > 0 then			
			local toolAngle = AutoSteeringEngine.getToolAngle( self );			
			angle  = nil;
			angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		end
			
--==============================================================		
-- U turn		
	elseif self.acTurnStage == 17 then
		angle    = self.acDimensions.maxSteeringAngle;
	
		--if self.acParameters.leftAreaActive then
		--	self.acLastSteeringAngle = -angleMax;
		--else
		--	self.acLastSteeringAngle = angleMax;
		--end
		--AutoSteeringEngine.setSteeringAngle( self, 0 );
		AutoSteeringEngine.setChainContinued( self );
		--AutoTractor.setChainOutside( self, angleFactor, -angleMax, angleMax );
		AutoSteeringEngine.setChainStraight( self );
		border = AutoSteeringEngine.getAllChainBorders( self );		
		detected = ( border <= ASEGlobals.maxBorder );
	else
		AutoSteeringEngine.setChainContinued( self );
	end

--==============================================================						
--==============================================================		
-- move far enough			
	if     self.acTurnStage == 1 then

		--if self.acParameters.CPSupport and turnAngle > -3 then
			angle = self.acDimensions.maxSteeringAngle;
		--else
		--	angle = 0;
		--end

		--if self.acTurn2Outside or ( angle == 0 and AutoSteeringEngine.getTurnDistance(self) > self.acDimensions.insideDistance ) then
			self.setAIImplementsMoveDown(self,false);
			self.acTurnStage   = self.acTurnStage + 1;
			self.turnTimer     = self.acDeltaTimeoutWait;
			allowedToDrive     = false;				
			self.waitForTurnTime = self.time + self.turnTimer;
		--end

--==============================================================				
-- wait before going back				
	elseif self.acTurnStage == 2 then
		allowedToDrive = false;				
		moveForwards   = false;					

		if self.acTurn2Outside then				
			angle = self.acDimensions.maxSteeringAngle;
		else
			angle = -self.acDimensions.maxSteeringAngle;
		end;
		
		--if self.turnTimer < 0 then
		if self.waitForTurnTime < self.time then
			self.acTurnStage = self.acTurnStage + 1;
			self.turnTimer   = self.acDeltaTimeoutWait;
		end;

--==============================================================				
-- going back
	elseif self.acTurnStage == 3 then

		moveForwards = false;					
	
		if     ( ( turnAngle > 30 or self.acTurn2Outside or noReverseIndex > 0  ) 
				 and detected 
				 and not fruitsDetected ) 
				or ( self.turnTimer < 0 and turnAngle > 90 ) then
			self.acTurnStage   = self.acTurnStage + 1;
			self.turnTimer     = self.acDeltaTimeoutWait;
			self.setAIImplementsMoveDown(self,true);
		end;

--==============================================================				
-- wait after going back					
	elseif self.acTurnStage == 4 then
		allowedToDrive = false;						
		
		angle = self.acLastSteeringAngle;
		
		if self.turnTimer < 0 then
			self.acTurnStage   = -1;					
			self.turnTimer     = self.acDeltaTimeoutStart;
		end;
		
--==============================================================				
--==============================================================				
-- 90° corner w/o going reverse					
	elseif self.acTurnStage == 5 then
		allowedToDrive = false;				
		if self.acTurn2Outside then				
			angle = -self.acDimensions.maxSteeringAngle;
		else
			angle = self.acDimensions.maxSteeringAngle;
		end
		
		if self.waitForTurnTime < self.time then
			self.setAIImplementsMoveDown(self,false);
			self.acTurnStage   = 6;					
		end
		
--==============================================================				
	elseif self.acTurnStage == 6 then
		if self.acTurn2Outside then				
			angle = -self.acDimensions.maxSteeringAngle;
		else
			angle = self.acDimensions.maxSteeringAngle;
		end
		
		if turnAngle < 0 then
			self.acTurnStage   = 7;					
		end;
		
--==============================================================				
	elseif self.acTurnStage == 7 then
		if self.acTurn2Outside then				
			angle = -self.acDimensions.maxSteeringAngle;
			if 170 < turnAngle and turnAngle < 180 then
				self.acTurnStage   = 8;					
			end;
		else
			angle = self.acDimensions.maxSteeringAngle;
			if 135 < turnAngle and turnAngle < 145 then
				self.acTurnStage   = 8;					
			end;
		end
		
--==============================================================				
		
	elseif self.acTurnStage == 8 then
		if self.acTurn2Outside then				
			angle = -self.acDimensions.maxSteeringAngle;
		else
			angle = self.acDimensions.maxSteeringAngle;
		end
		
		if detected or fruitsDetected then
			self.setAIImplementsMoveDown(self,true);
			self.acTurnStage   = -1;					
			self.turnTimer     = self.acDeltaTimeoutStart;
		end;
		
--==============================================================				
--==============================================================				
-- wait before U-turn					
	elseif self.acTurnStage == 11 then
		allowedToDrive = false;						
		angle = 0;

		if self.waitForTurnTime < self.time then
			self.setAIImplementsMoveDown(self,false);
			if self.acTurn2Outside then
				self.acTurnStage = 12;
				self.turnTimer   = self.acDeltaTimeoutStop;
			else
				local dist = self.acDimensions.uTurnDistance;
				if self.acParameters.noReverse then
					dist = self.acDimensions.uTurnDistance;
				end;

				if AutoSteeringEngine.getTurnDistance(self) > dist then
					self.acTurnStage = 17;
					self.lastTurnAngle = math.deg(AutoSteeringEngine.getTurnAngle(self));					
				else
					self.acTurnStage = 15;
					self.turnTimer   = self.acDeltaTimeoutWait;
				end
			end
		end
		
--==============================================================				
-- move to the right position before U-turn					
	elseif  self.acTurnStage == 12 then

		local ref = 0;
		if self.acParameters.noReverse then
			ref = math.deg(self.acDimensions.uTurnAngle);
		end;
		
		if self.acTurn2Outside then
			angle = -self.acDimensions.maxSteeringAngle;
									
			if turnAngle >= ref then
				self.acTurn2Outside = false;
				self.acTurnStage = 13;
				self.turnTimer   = self.acDeltaTimeoutRun;
			end
		else
			angle = self.acDimensions.maxSteeringAngle;
							
			if turnAngle <= 0 then
				local dist = self.acDimensions.uTurnDistance;

				if AutoSteeringEngine.getTurnDistance(self) > dist then
					self.acTurnStage = 17;
					self.lastTurnAngle = math.deg(AutoSteeringEngine.getTurnAngle(self));					
				else
					self.acTurnStage = 14;
					self.turnTimer   = self.acDeltaTimeoutRun;
				end;
			end;
		end;

--==============================================================				
-- wait during U-turn
	elseif self.acTurnStage == 13 then
		allowedToDrive = false;						
		
		angle = self.acDimensions.maxSteeringAngle;
		
		if self.turnTimer < 0 then
			self.acTurnStage = 12;					
		end;

--==============================================================				
-- wait during U-turn before going forward
	elseif self.acTurnStage == 14 then
		allowedToDrive = false;						
		
		angle = 0;
		
		if self.turnTimer < 0 then
			self.acTurnStage = 15;					
		end;
		
--==============================================================				
-- go to the right distance before the U-turn
	elseif self.acTurnStage == 15 then

		angle = 0;
		
		local dist = self.acDimensions.uTurnDistance;
		if self.acParameters.noReverse then
			dist = self.acDimensions.uTurnDistance;
		end;
			
		if AutoSteeringEngine.getTurnDistance(self) > dist then
			self.acTurnStage = 16;					
			self.turnTimer   = self.acDeltaTimeoutRun;
		end;

--==============================================================				
-- wait during U-turn after going forward
	elseif self.acTurnStage == 16 then

		allowedToDrive = false;						
											
		angle = self.acDimensions.maxSteeringAngle;
		if self.turnTimer < 0 then
			if self.acParameters.leftAreaActive then
				AITractor.aiRotateLeft(self);
			else
				AITractor.aiRotateRight(self);
			end
			self.acTurnStage   = 17;					
			self.lastTurnAngle = math.deg(AutoSteeringEngine.getTurnAngle(self));					
		end;
		
--==============================================================				
-- The U-turn					
	elseif self.acTurnStage == 17 then

		local ref = -105;
		
		if not self.acParameters.noReverse and turnAngle <= ref then
			self.acTurn2Outside   = true;
			self.acTurnStage      = 18;
			self.turnTimer        = self.acDeltaTimeoutStop;
		elseif turnAngle <= -175 then 
			self.acTurnStage      = 19;				
			self.lastTurnAngle    = 0;
			self.turnTimer        = self.acDeltaTimeoutRun;
			self.setAIImplementsMoveDown(self,true);
		end;
		
		angle = self.acDimensions.maxSteeringAngle;

--==============================================================				
-- going back
	elseif self.acTurnStage == 18 then

		moveForwards = false;					
		
		if      detected 
				and not fruitsDetected then
			self.acTurnStage    = 19;
			self.turnTimer      = self.acDeltaTimeoutRun;
			self.setAIImplementsMoveDown(self,true);
		elseif math.abs(turnAngle) > 175 then
			self.acTurnStage    = 19;
			self.turnTimer      = self.acDeltaTimeoutRun;
			self.lastTurnAngle  = 0;
			self.setAIImplementsMoveDown(self,true);
		end;

--==============================================================				
-- wait after U-turn
	elseif self.acTurnStage == 19 then
		allowedToDrive = false;						
		
		angle = self.acLastSteeringAngle;
		
		if self.turnTimer < 0 then
			self.acTurnStage = -2;					
			self.turnTimer   = self.acDeltaTimeoutStart;
		end;

--==============================================================				
--==============================================================				
-- the new U-turn with reverse
	elseif self.acTurnStage == 21 then
		allowedToDrive = false;				
		angle = self.acDimensions.maxSteeringAngle;
		
		if self.waitForTurnTime < self.time then
			self.setAIImplementsMoveDown(self,false);
			self.acTurnStage   = self.acTurnStage + 1;					
		end

--==============================================================				
-- turn 90°
	elseif self.acTurnStage == 22 then
		angle = self.acDimensions.maxSteeringAngle;
		
		local toolAngle = AutoSteeringEngine.getToolAngle( self );	
		if not self.acParameters.leftAreaActive then
			toolAngle = -toolAngle
		end
		
		angle = angle - math.max( 0, toolAngle - 0.5 );	
		
		if turnAngle < -120 or turnAngle + 0.5 * math.deg( toolAngle ) < -90 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================			
-- move forwards and reduce tool angle	
	elseif self.acTurnStage == 23 then
		angle  = nil;
		local toolAngle = AutoSteeringEngine.getToolAngle( self );		
		angle2 = math.min( math.max( -toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );

		if math.abs(math.deg(toolAngle)) < 5 then
			if self.acParameters.leftAreaActive then
				AITractor.aiRotateLeft(self);
			else
				AITractor.aiRotateRight(self);
			end
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================				
-- wait		
	elseif self.acTurnStage == 24 then
		allowedToDrive = false;						
		moveForwards = false;					
		angle  = 0;
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
		
		--if detected then
		--	self.setAIImplementsMoveDown(self,true);
		--	self.acTurnStage   = self.acTurnStage + 3;					
		--	self.turnTimer     = self.acDeltaTimeoutRun;
			--self.acTurnStage = -2;					
			--self.turnTimer   = self.acDeltaTimeoutStart;
		--else
			local x,z = AutoSteeringEngine.getTurnVector( self, true );
			if self.acParameters.leftAreaActive then x = -x end
			if noReverseIndex <= 0 then x = x - 1 end
				
			if x > self.acDimensions.radius or z < 0 then
				self.acTurnStage   = self.acTurnStage + 1;					
				self.turnTimer     = self.acDeltaTimeoutRun;
			end
		--end
		
--==============================================================				
-- wait
	elseif self.acTurnStage == 26 then
		allowedToDrive = false;						
		angle = self.acDimensions.maxSteeringAngle;
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
		end

--==============================================================				
-- turn 90°
	elseif self.acTurnStage == 27 then
		local x,z = AutoSteeringEngine.getTurnVector( self, true );
		if self.acParameters.leftAreaActive then x = -x end
		if noReverseIndex <= 0 then x = x -1 end
		
		if detected or math.abs( turnAngle ) > 175 or z < 0 then
			self.setAIImplementsMoveDown(self,true);
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
			--self.acTurnStage = -2;					
			--self.turnTimer   = self.acDeltaTimeoutStart;
		else
			
			local a = math.pi - AutoSteeringEngine.getTurnAngle( self );
			local f = 1 - math.cos( a );
			
			if math.abs( f ) < 1E-3 then
				angle = 0
			else
				local r = x / f;
				if math.abs( r ) < 1E-3 then
					angle = self.acDimensions.maxSteeringAngle
				else	
					angle = math.atan( self.acDimensions.wheelBase / r )
					angle = math.min( math.max( angle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle )
				end
			end
		end
		
--==============================================================				
-- wait after U-turn
	elseif self.acTurnStage == 28 then
		allowedToDrive = false;						
		
		angle = 0;
		
		if self.turnTimer < 0 then
			self.acTurnStage = -2;					
			self.turnTimer   = self.acDeltaTimeoutStart;
		end;
	
--==============================================================				
--==============================================================				
-- 90° turn to inside with reverse
	elseif self.acTurnStage == 31 then
		allowedToDrive = false;				
		angle = -self.acDimensions.maxSteeringAngle;
		
		if self.waitForTurnTime < self.time then
			self.setAIImplementsMoveDown(self,false);
			self.acTurnStage   = self.acTurnStage + 1;					
		end

--==============================================================				
-- turn 45°
	elseif self.acTurnStage == 32 then
		angle = -self.acDimensions.maxSteeringAngle;
		
		local toolAngle = AutoSteeringEngine.getToolAngle( self );	
		if self.acParameters.leftAreaActive then
			toolAngle = -toolAngle
		end
		
		angle = angle + math.max( 0, toolAngle - 0.5 );	
		
		if turnAngle - 0.5 * math.deg( toolAngle ) > 45 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================			
-- move forwards and reduce tool angle	
	elseif self.acTurnStage == 33 then
		angle  = nil;
		local toolAngle = AutoSteeringEngine.getToolAngle( self );		
		angle2 = math.min( math.max( -toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );

		if math.abs(math.deg(toolAngle)) < 5 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutRun;
		end

--==============================================================				
-- wait		
	elseif self.acTurnStage == 34 then
		allowedToDrive = false;						
		moveForwards = false;					
		angle  = 0;
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
		end
		
--==============================================================				
-- move backwards (straight)		
	elseif self.acTurnStage == 35 then		
		moveForwards = false;					
		angle  = nil;
		local toolAngle = AutoSteeringEngine.getToolAngle( self );
		angle2 = math.min( math.max( toolAngle, -self.acDimensions.maxSteeringAngle ), self.acDimensions.maxSteeringAngle );
		
		--if detected then
		--	self.setAIImplementsMoveDown(self,true);
		--	self.acTurnStage   = self.acTurnStage + 3;					
		--	self.turnTimer     = self.acDeltaTimeoutRun;
		--else
			local _,z = AutoSteeringEngine.getTurnVector( self );
			
			if z < -0.5 then				
				self.acTurnStage   = self.acTurnStage + 1;					
				self.turnTimer     = self.acDeltaTimeoutRun;
			end
		--end
		
--==============================================================				
-- wait
	elseif self.acTurnStage == 36 then
		allowedToDrive = false;						
		angle = -self.acDimensions.maxSteeringAngle;
		
		if self.turnTimer < 0 then
			self.acTurnStage   = self.acTurnStage + 1;					
			self.turnTimer     = self.acDeltaTimeoutStop;
		end

--==============================================================				
-- turn 45°
	elseif self.acTurnStage == 37 then
		local x = AutoSteeringEngine.getTurnVector( self );
		if self.acParameters.leftAreaActive then x = -x end
		
		if turnAngle < 70 then
			angle = -self.acDimensions.maxSteeringAngle;
		elseif detected or math.abs( turnAngle ) > 90 or x < 0 then
			self.setAIImplementsMoveDown(self,true);
			--self.acTurnStage   = self.acTurnStage + 1;					
			--self.turnTimer     = self.acDeltaTimeoutRun;
			self.acTurnStage = -1;					
			self.turnTimer   = self.acDeltaTimeoutStart;
		else
			angle = 0
		end
		
--==============================================================				
-- wait after 90° turn
	elseif self.acTurnStage == 38 then
		allowedToDrive = false;						
		
		angle = 0;
		
		if self.turnTimer < 0 then
			self.acTurnStage = -1;					
			self.turnTimer   = self.acDeltaTimeoutStart;
		end;
	
--==============================================================				
--==============================================================				
-- searching...
	elseif -3 <= self.acTurnStage and self.acTurnStage < 0 then
		moveForwards     = true;

		if fruitsDetected and detected then
	--if fruitsDetected then
			AutoSteeringEngine.clearTrace( self );
			AutoSteeringEngine.saveDirection( self, false );
			self.acTurnStage    = 0;
			self.acTurn2Outside = false;
			self.turnTimer      = self.acDeltaTimeoutNoTurn;
			self.aiRescueTimer  = self.acDeltaTimeoutStop;
		end;
		
--==============================================================				
-- threshing...					
	elseif self.acTurnStage == 0 then
		moveForwards     = true;
		
		local traceLength = AutoSteeringEngine.getTraceLength(self);
		
		local doTurn = false;
		local uTurn  = false;
		
		if  detected then
			doTurn = false
		elseif  fruitsDetected 
				and not self.acTurn2Outside then
			doTurn = false
		elseif  self.turnTimer < 0 then
			doTurn = true
			if     self.acTurn2Outside 
					or not self.acParameters.upNDown
					or traceLength < 10 then		
				uTurn = false
			else
				uTurn = true
			end
		end
		
		if doTurn then
			if     uTurn               then
		-- the U turn
				--invert turn angle because we will swap left/right in about 10 lines
				
				turnAngle = -turnAngle;
				if self.acParameters.noReverse or self.acDimensions.uTurnAngle > 1 then
					self.acTurn2Outside = turnAngle < self.acDimensions.uTurnAngle;
				else
					self.acTurn2Outside = false; --math.deg(turnAngle) < -3;					
				end;
				if self.acParameters.noReverse then
					self.acTurnStage = 11; 
				else
					self.acTurnStage = 21;
				end
				self.turnTimer = self.acDeltaTimeoutWait;
				self.waitForTurnTime = self.time + self.turnTimer;
				self.acParameters.leftAreaActive  = not self.acParameters.leftAreaActive;
				self.acParameters.rightAreaActive = not self.acParameters.rightAreaActive;
				AutoTractor.sendParameters(self);
				AutoSteeringEngine.setChainStraight( self );	
			elseif self.acTurn2Outside then
		-- turn to outside because we are in the middle of the field
				self.acTurnStage = 1;
				self.turnTimer = self.acDeltaTimeoutWait;
			elseif self.acParameters.noReverse then
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
			elseif noReverseIndex <= 0 and traceLength < 10 then
		-- 90° turn with reverse
				self.acTurnStage = 1;
				self.turnTimer = self.acDeltaTimeoutWait;
			else
		-- 90° turn with reverse
				self.acTurnStage = 31;
				self.turnTimer = self.acDeltaTimeoutWait;
			end
		elseif detected then --and fruitsDetected then
			AutoSteeringEngine.saveDirection( self, true );
			self.turnTimer   	  = math.max(self.turnTimer,self.acDeltaTimeoutRun);
			self.aiRescueTimer  = self.acDeltaTimeoutStop;
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
		self:stopAITractor();
		return;
	end;                
--==============================================================				

	local acceleration   = 0;					
	local slowAngleLimit = self.acDimensions.maxLookingAngle;
	
	if self.isMotorStarted and speedLevel ~= 0 and self.fuelFillLevel > 0 then
		acceleration = 1.0;
	end;

	if     self.acTurnStage > 0 
			or ( not detected and self.acTurnStage >= -2 ) then
		slowAngleLimit = 0;
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
	
	local aiSteeringSpeed = self.aiSteeringSpeed;
	if detected then aiSteeringSpeed = aiSteeringSpeed * 0.5 end
	
	AutoSteeringEngine.steer( self, dt, angle, aiSteeringSpeed, detected );
	
	if not detected and 1 < speedLevel and speedLevel < 4 then
		speedLevel = 1
	end
	
	AutoSteeringEngine.drive( self, dt, acceleration, slowAcceleration, angle, slowAngleLimit, allowedToDrive, moveForwards, speedLevel, 0.75 );

  --local colDirX = math.sin( angle );
	--local colDirZ = math.cos( angle );
	--
	--if     not allowedToDrive then
	--	colDirX = 0;
	--	colDirZ = 1;
	--elseif not moveForwards then
	--	colDirZ = -colDirZ;
	--end
	--
  --for triggerId, _ in pairs(self.numCollidingVehicles) do
	--  AIVehicleUtil.setCollisionDirection(self.aiTreshingDirectionNode, triggerId, colDirX, colDirZ)
  --end
end

------------------------------------------------------------------------
-- Mogli.getXmlBool
------------------------------------------------------------------------
function Mogli.getXmlBool(xmlFile, key, default)
	local l = getXMLInt(xmlFile, key);
	if l~= nil then
		return (l == 1);
	end;
	return default;
end;

function Mogli.getXmlFloat(xmlFile, key, default)
	local f = getXMLFloat(xmlFile, key);
	if f ~= nil then
		return f;
	end;
	return default;
end;

------------------------------------------------------------------------
-- getSaveAttributesAndNodes
------------------------------------------------------------------------
function AutoTractor:getSaveAttributesAndNodes(nodeIdent)
	
	local attributes;

	if     self.acParameters.enabled
			or not self.acParameters.upNDown
			or self.acParameters.rightAreaActive
			or self.acParameters.headland
			or self.acParameters.widthOffset ~= 0
			or self.acParameters.turnOffset  ~= 0 
			or self.acParameters.angleOffset ~= 0 then
		attributes = 'acVersion="0.8"';
		attributes = attributes..' acEnabled="'     ..Mogli.bool2int(self.acParameters.enabled).. '"';
		attributes = attributes..' acUTurn="'       ..Mogli.bool2int(self.acParameters.upNDown).. '"';
		attributes = attributes..' acAreaRight="'   ..Mogli.bool2int(self.acParameters.rightAreaActive).. '"';
		attributes = attributes..' acNoReverse="'   ..Mogli.bool2int(self.acParameters.noReverse).. '"';
		attributes = attributes..' acHeadland="'    ..Mogli.bool2int(self.acParameters.headland).. '"';
		attributes = attributes..' acWidthOffset="' ..self.acParameters.widthOffset..'"';		
		attributes = attributes..' acTurnOffset="'  ..self.acParameters.turnOffset..'"';		
		attributes = attributes..' acAngleOffset="' ..self.acParameters.angleOffset..'"';		
	end;
	
	return attributes
end;

------------------------------------------------------------------------
-- loadFromAttributesAndNodes
------------------------------------------------------------------------
function AutoTractor:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	local version = getXMLString(xmlFile, key.."#acVersion");
	
	self.acParameters.enabled         = Mogli.getXmlBool(xmlFile, key.."#acEnabled",     self.acParameters.enabled);
	self.acParameters.upNDown	        = Mogli.getXmlBool(xmlFile, key.."#acUTurn",       self.acParameters.upNDown);
	self.acParameters.rightAreaActive = Mogli.getXmlBool(xmlFile, key.."#acAreaRight",   self.acParameters.rightAreaActive);
	self.acParameters.noReverse       = Mogli.getXmlBool(xmlFile, key.."#acNoReverse",   self.acParameters.noReverse);
	self.acParameters.headland        = Mogli.getXmlBool(xmlFile, key.."#acHeadland",    self.acParameters.headland);
	self.acParameters.widthOffset     = Mogli.getXmlFloat(xmlFile,key.."#acWidthOffset", self.acParameters.widthOffset); 
	self.acParameters.turnOffset      = Mogli.getXmlFloat(xmlFile,key.."#acTurnOffset",  self.acParameters.turnOffset); 
	self.acParameters.angleOffset     = Mogli.getXmlInt( xmlFile, key.."#acAngleOffset", self.acParameters.angleOffset); 

	self.acParameters.leftAreaActive  = not self.acParameters.rightAreaActive;
	self.acDimensions                 = nil;
	
	return BaseMission.VEHICLE_LOAD_OK;
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
function AutoTractor.calculateDimensions( self )
	if self.acDimensions ~= nil then
		return;
	end;
	
	self.acDimensions = {};

	self.acDimensions.wheelBase       = 0;
	self.acDimensions.zOffset         = 0;
	self.acDimensions.radius          = 5;
	
	if      self.articulatedAxis ~= nil 
			and self.articulatedAxis.componentJoint ~= nil
      and self.articulatedAxis.componentJoint.jointNode ~= nil 
			and self.articulatedAxis.rotMax then
		_,_,self.acDimensions.zOffset = AutoSteeringEngine.getRelativeTranslation(self.acRefNode,self.articulatedAxis.componentJoint.jointNode);
		local n=0;
		for _,wheel in pairs(self.wheels) do
			local x,y,z = AutoSteeringEngine.getRelativeTranslation(self.articulatedAxis.componentJoint.jointNode,wheel.driveNode);
			self.acDimensions.wheelBase = self.acDimensions.wheelBase + math.abs(z);
			n  = n  + 1;
		end
		if n > 1 then
			self.acDimensions.wheelBase = self.acDimensions.wheelBase / n;
		end
		self.acDimensions.maxSteeringAngle = math.min( -self.articulatedAxis.rotMin, self.articulatedAxis.rotMax );
	else
		local left  = {};
		local right = {};
		local nl0,zl0,nr0,zr0,zlm,alm,zrm,arm,zlmi,almi,zrmi,armi = 0,0,0,0,-99,0,-99,0,99,0,99,0;
		for _,wheel in pairs(self.wheels) do
			local x,y,z = AutoSteeringEngine.getRelativeTranslation(self.acRefNode,wheel.driveNode);
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
	
	if math.abs( self.acDimensions.wheelBase ) > 1E-3 and math.abs( self.acDimensions.maxSteeringAngle ) > 1E-4 then
		self.acDimensions.radius        = self.acDimensions.wheelBase / math.tan( self.acDimensions.maxSteeringAngle );
	else
		self.acDimensions.radius        = 5;
	end

	AutoTractor.calculateDistances( self )
end

------------------------------------------------------------------------
-- calculateDistances
------------------------------------------------------------------------
function AutoTractor.calculateDistances( self )

	self.acDimensions.distance     = 99;
	self.acDimensions.toolDistance = 99;
	
	local zo = self.acDimensions.zOffset;
	local wb = self.acDimensions.wheelBase;
	local ms = self.acDimensions.maxSteeringAngle;
	
  ------------------------------------------------------------------------
  -- Roue mode
  ------------------------------------------------------------------------	
	
	AutoSteeringEngine.checkChain( self, self.acRefNode, zo, wb, ms, self.acParameters.widthOffset, self.acParameters.turnOffset );
	local zBack;
	self.acDimensions.distance, self.acDimensions.toolDistance, zBack = AutoSteeringEngine.checkTools( self );

	local optimDist = self.acDimensions.distance;
	if self.acDimensions.radius > optimDist then
		self.acDimensions.uTurnAngle     = math.acos( optimDist / self.acDimensions.radius );
	else
		self.acDimensions.uTurnAngle     = 0;
	end;

	self.acDimensions.distance0        = self.acDimensions.distance;
	if self.acParameters.widthOffset ~= nil then
		self.acDimensions.distance       = self.acDimensions.distance0 + self.acParameters.widthOffset;
	end
	self.acDimensions.maxLookingAngle  = math.min( math.rad( math.max( ASEGlobals.maxLooking + self.acParameters.angleOffset, 1) ) ,self.acDimensions.maxSteeringAngle);
	self.acDimensions.insideDistance   = math.max( 0, self.acDimensions.toolDistance - 1 - self.acDimensions.distance +(self.acDimensions.radius * math.cos( self.acDimensions.maxSteeringAngle )) );
	self.acDimensions.uTurnDistance    = math.max( 0, 1 + self.acDimensions.toolDistance + self.acDimensions.distance - self.acDimensions.radius);
	self.acDimensions.headlandDist     = math.max( self.acDimensions.distance, zBack ) + self.acDimensions.radius; --0.33333 * ( 2 * self.acDimensions.radius + self.acDimensions.wheelBase / math.tan( self.acDimensions.maxLookingAngle ) );
	
	if self.acParameters.turnOffset ~= nil then
		self.acDimensions.insideDistance = math.max( 0, self.acDimensions.insideDistance + self.acParameters.turnOffset );
		self.acDimensions.uTurnDistance  = math.max( 0, self.acDimensions.uTurnDistance  + self.acParameters.turnOffset );
		self.acDimensions.headlandDist   = self.acDimensions.headlandDist + self.acParameters.turnOffset;
	end
	
end

function AutoTractor:roueChangeSteer( ... )
	print( "roue change event" );
end

------------------------------------------------------------------------
-- Manually switch to next turn stage
------------------------------------------------------------------------
function AutoTractor:setNextTurnStage(noEventSend)

	if AutoTractor.evalTurnStage(self) then
		if self.acParameters.enabled then
			if self.acTurnStage == 0 then
			
				if self.acParameters.upNDown then
					self.acTurn2Outside = false; --math.deg(turnAngle) < -3;					
					if self.acParameters.noReverse then
						self.acTurnStage = 11; 
					else
						self.acTurnStage = 21;
					end
					self.acParameters.leftAreaActive  = not self.acParameters.leftAreaActive;
					self.acParameters.rightAreaActive = not self.acParameters.rightAreaActive;
					AutoTractor.sendParameters(self);
					AutoSteeringEngine.setChainStraight( self );	
				elseif self.acParameters.noReverse then
			-- 90° turn w/o reverse
					self.aiRescueTimer  = 3 * self.acDeltaTimeoutStop;
					self.acTurnStage = 5;
					self.acTurn2Outside = false
				else
			-- 90° turn with reverse
					self.acTurnStage = 31;
				end
				self.turnTimer = self.acDeltaTimeoutWait;
				self.waitForTurnTime = self.time + self.turnTimer;
				
			else
				self.acTurnStage = self.acTurnStage + 1;
				self.turnTimer   = self.acDeltaTimeoutWait;
			end
		else
			self.turnStage   = self.turnStage + 1;
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
		self.acParameters.upNDown = true;
		self.acParameters.leftAreaActive = true;
		self.acParameters.rightAreaActive = false;
		self.acParameters.enabled = false;
		self.acParameters.noReverse = false;
		self.acParameters.headland = false;
		self.acParameters.turnOffset = 0;
		self.acParameters.widthOffset = 0;
		self.acParameters.angleOffset = 0;
	end;

	return self.acParameters;
end;

local function atReadStream(streamId)
	local parameters = {};
	
	parameters.enabled         = streamReadBool(streamId);
	parameters.upNDown	       = streamReadBool(streamId);
	parameters.rightAreaActive = streamReadBool(streamId);
	parameters.noReverse       = streamReadBool(streamId);
	parameters.headland        = streamReadBool(streamId);
	parameters.turnOffset      = streamReadFloat32(streamId);
	parameters.widthOffset     = streamReadFloat32(streamId);
	parameters.angleOffset     = streamReadInt8(streamId);
	return parameters;
end

local function atWriteStream(streamId, parameters)
	streamWriteBool(streamId, Utils.getNoNil( parameters.enabled        ,false ));
	streamWriteBool(streamId, Utils.getNoNil( parameters.upNDown	      ,true ));
	streamWriteBool(streamId, Utils.getNoNil( parameters.rightAreaActive,false ));
	streamWriteBool(streamId, Utils.getNoNil( parameters.noReverse      ,false ));
	streamWriteBool(streamId, Utils.getNoNil( parameters.headland       ,false ));
	streamWriteFloat32(streamId, Utils.getNoNil( parameters.turnOffset  ,0 ));
	streamWriteFloat32(streamId, Utils.getNoNil( parameters.widthOffset ,0 ));
	streamWriteInt8(streaId, Utils.getNoNil( parameters.angleOffset, 0 ));
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
	self.acParameters.upNDown         = Utils.getNoNil(parameters.upNDown        ,true);
	self.acParameters.rightAreaActive = Utils.getNoNil(parameters.rightAreaActive,false);
	self.acParameters.noReverse       = Utils.getNoNil(parameters.noReverse      ,false);
	self.acParameters.headland        = Utils.getNoNil(parameters.headland       ,false);
	self.acParameters.turnOffset      = Utils.getNoNil(parameters.turnOffset     ,0);
	self.acParameters.widthOffset     = Utils.getNoNil(parameters.widthOffset    ,0);
	self.acParameters.angleOffset     = Utils.getNoNil(parameters.angleOffset    ,0);
	self.acParameters.leftAreaActive  = not self.acParameters.rightAreaActive;
end

function AutoTractor:readStream(streamId, connection)
  AutoTractor.setParameters( self, atReadStream(streamId) );
end

function AutoTractor:writeStream(streamId, connection)
  atWriteStream(streamId,AutoTractor.getParameters(self));
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
	self.parameters = atReadStream(streamId);
  self:run(connection)
end
function AutoTractorParametersEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
	atWriteStream(streamId, self.parameters);
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


addConsoleCommand("acReset", "Reset global AutoTractor variables to defaults.", "acReset", AutoTractor);
function AutoTractor:acReset()
	AutoSteeringEngine.globalsReset();
	AutoSteeringEngine.resetCounter = AutoSteeringEngine.resetCounter + 1;
	for name,value in pairs(ASEGlobals) do
		print(tostring(name).." "..tostring(value));		
	end
end

-- acSet
addConsoleCommand("acSet", "Change one of the global AutoTractor variables.", "acSet", AutoTractor);
function AutoTractor:acSet(name,svalue)

	local value;
	if svalue ~= nil then
		value = tonumber( svalue );
	end
	
	print("acSet "..tostring(name).." "..tostring(value));

	local found = false;
	
	local old=nil
	for n,o in pairs(ASEGlobals) do
		if n == name then
			found = true;
			old   = o;
			break;
		end
	end
	
  if found then
		if value == nil or old == new then
			print(tostring(ASEGlobals[name]));
		else
			ASEGlobals[name]=value;
			print("Old value: "..tostring(old).."; new value: "..tostring(value));
			AutoSteeringEngine.resetCounter = AutoSteeringEngine.resetCounter + 1;
		end
	else
		print("Usage: acSet <name> <value>");
		print("Possible names are:");
		
		for n,old in pairs(ASEGlobals) do
			print("  " .. n .. ": "..tostring(ASEGlobals[n]));
		end
	end
	
end

-- acDump
addConsoleCommand("acDump", "Dump internal state of AutoTractor", "acDump", AutoTractor);
function AutoTractor:acDump()
	atDump = true;
end

function AutoTractor:acDump2()	
	atDump = nil;
	for i=1,ASEGlobals.chainMax+1 do
		local text = string.format("i: %i, a: %i",i,self.aseChain.nodes[i].angle);
		if self.aseChain.nodes[i].status >=  1 then
			text = text .. string.format(" s: %i",math.deg( self.aseChain.nodes[i].steering ));
		end
		if self.aseChain.nodes[i].status >=  2 then
			text = text .. string.format(" r: %i",math.deg( self.aseChain.nodes[i].rotation ));
		end
		if self.aseChain.nodes[i].status >=  3 then
			for j=1,table.getn(self.aseTools) do
				if      self.aseChain.nodes[i].tool[j]   ~= nil 
						and self.aseChain.nodes[i].tool[j].x ~= nil 
						and self.aseChain.nodes[i].tool[j].z ~= nil then
					local x1,y1,z1 = localToWorld( self.aseChain.nodes[i].index, self.aseChain.nodes[i].tool[j].x, 0, self.aseChain.nodes[i].tool[j].z );
					local x2,y2,z2 = worldToLocal( self.aseChain.refNode, x1, y1, z1 );
					text = text .. string.format( " x: %0.3f z: %0.3f",x2,z2);							
				end
			end
		end
		
		print(text);
	end
end

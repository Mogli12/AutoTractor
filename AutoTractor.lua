--
-- AutoTractor
-- Extended AITractor
--
-- @author  Mogli aka biedens
-- @version 1.1.0.4
-- @date    23.03.2014
--
--  code source: AITractor.lua by Giants Software    
 
AutoTractor = {};
local AtDirectory = g_currentModDirectory;

------------------------------------------------------------------------
-- INCLUDES
------------------------------------------------------------------------
source(Utils.getFilename("Mogli.lua", AtDirectory));
source(Utils.getFilename("FieldBitmap.lua", AtDirectory));
source(Utils.getFilename("AutoSteeringEngine.lua", AtDirectory));
source(Utils.getFilename("FrontPacker.lua", AtDirectory));

------------------------------------------------------------------------
-- statEvent
------------------------------------------------------------------------
AutoTractor.acDevFeatures = false
function AutoTractor:statEvent( name, dt )
	if AutoTractor.acDevFeatures then
		if self.acStat == nil then self.acStat = {} end
		self.acStat[name] = Utils.getNoNil( self.acStat[name], 0 ) + dt
	end
end

AutoTractor.saveAttributesMapping = { enabled         = { xml = "acEnabled",     tp = "B", default = true, always = true },
																			upNDown         = { xml = "acUTurn",       tp = "B", default = true, always = true },
																			rightAreaActive = { xml = "acAreaRight",   tp = "B", default = false },
																			noReverse       = { xml = "acNoReverse",   tp = "B", default = false },
																			headland        = { xml = "acHeadland",    tp = "B", default = false },
																			collision       = { xml = "acCollision",   tp = "B", default = false },
																			inverted        = { xml = "acInverted",    tp = "B", default = false },
																			frontPacker     = { xml = "acFrontPacker", tp = "B", default = false },
																			isHired         = { xml = "acIsHired",     tp = "B", default = false },
																			bigHeadland     = { xml = "acBigHeadland", tp = "B", default = true },
																			bigTurn         = { xml = "acBigTurn",     tp = "I", default = 0 },
																			widthOffset     = { xml = "acWidthOffset", tp = "F", default = 0 },
																			turnOffset      = { xml = "acTurnOffset",  tp = "F", default = 0 },
																			angleOffset     = { xml = "acAngleOffset", tp = "I", default = 0 } };																															
AutoTractor.turnStageNoNext = { 0 }
AutoTractor.turnStageEnd  = { { 4, -1 },
															{ 8, -1 },
															{ 23, 25 },
															{ 25, 27 },
															{ 27, -22 },
															{ 28, -22 },
															{ 29, -2 },
															{ 33, 36 },
															{ 34, 36 },
															{ 36, 38 },
															{ 38, -1 },
															{ 41, 43 },
															{ 43, 45 },
															{ 45, 49 },
															{ 46, 49 },
															{ 47, 49 },
															{ 49, -22 },
															{ 53, 56 },
															{ 54, 56 },
															{ 59, -22 },
															{ 60, -22 },
															{ 75, 79 },
															{ 76, 79 },
															{ 77, 79 },
															{ 78, 79 },
															{ 79, -22 } }

------------------------------------------------------------------------
-- AICombine:updateAIMovement
------------------------------------------------------------------------
source(Utils.getFilename("AutoTractorAIMovement.lua", AtDirectory));

------------------------------------------------------------------------
-- prerequisitesPresent
------------------------------------------------------------------------
function AutoTractor.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Hirable, specializations) 
		 and SpecializationUtil.hasSpecialization(AITractor, specializations) -- )
			--or ( SpecializationUtil.hasSpecialization(Motorized, specializations)  
		   --and SpecializationUtil.hasSpecialization(Steerable, specializations)
		   --and SpecializationUtil.hasSpecialization(Mower, specializations) )
		 --and not SpecializationUtil.hasSpecialization(ArticulatedAxis, specializations)
end;

------------------------------------------------------------------------
-- load
------------------------------------------------------------------------
function AutoTractor:load(xmlFile)
	
	-- for courseplay  
	self.acNumCollidingVehicles = 0
	self.acIsCPStopped        = false
	self.acTurnStage          = 0
	self.acPause              = false	
	self.acParameters         = AutoTractor.getParameterDefaults( )
	
	self.acDeltaTimeoutWait   = math.max(Utils.getNoNil( self.waitForTurnTimeout, 1600 ), 1000 ); 
	self.acDeltaTimeoutRun    = math.max(Utils.getNoNil( self.turnTimeout, 800 ), 500 );
	self.acDeltaTimeoutStop   = 4 * math.max(Utils.getNoNil( self.turnStage1Timeout , 20000), 10000);
	self.acDeltaTimeoutStart  = math.max(Utils.getNoNil( self.turnTimeoutLong   , 6000 ), 4000 );
	self.acDeltaTimeoutNoTurn = 2 * self.acDeltaTimeoutWait --math.max(Utils.getNoNil( self.waitForTurnTimeout , 2000 ), 1000 );
	self.acSteeringSpeed      = Utils.getNoNil( self.aiSteeringSpeed, 0.001 );
	self.acRecalculateDt      = 0;
	self.acTurn2Outside       = false;
	self.acCollidingVehicles  = {};
	self.acTurnStageSent      = 0;
	self.acWaitTimer          = 0;
  self.acTurnOutsideTimer   = 0;
	
	detected = nil;	
	fruitsDetected = nil;
	
  self.acAutoRotateBackSpeedBackup = self.autoRotateBackSpeed;	

	local tempNode = self.aiTractorDirectionNode;
	if self.aiTractorDirectionNode == nil then
		tempNode = self.components[1].node
	end
	if      self.articulatedAxis ~= nil 
			and ASEGlobals.artAxisMode > 0 
			and self.articulatedAxis.componentJoint ~= nil
			and self.articulatedAxis.anchorActor ~= nil
      and self.articulatedAxis.componentJoint.jointNode ~= nil then				
		tempNode = getParent( self.articulatedAxis.componentJoint.jointNode )
		
		if ASEGlobals.artAxisMode == 2 or ASEGlobals.artAxisMode == 3 then
			local _,_,z1 = AutoSteeringEngine.getRelativeTranslation( self.steeringAxleNode, self.components[self.articulatedAxis.componentJoint.componentIndices[1]].node )
			local _,_,z2 = AutoSteeringEngine.getRelativeTranslation( self.steeringAxleNode, self.components[self.articulatedAxis.componentJoint.componentIndices[2]].node )
			if z1 < z2 then
				tempNode = self.components[self.articulatedAxis.componentJoint.componentIndices[1]].node
			else
				tempNode = self.components[self.articulatedAxis.componentJoint.componentIndices[2]].node
			end
		end
	end
	
	self.acRefNode = createTransformGroup( "acNewRefNode" )
	link( tempNode, self.acRefNode )
	
	self.acHasRoueSpec = false;
	if ASEGlobals.roueSupport > 0 then
		for name,entry in pairs( SpecializationUtil.specializations ) do
			local s,e = string.find( entry.className, ".Roue" )
			if s ~= nil and e == string.len( entry.className ) then
				local c = SpecializationUtil.getSpecialization(entry.name);
				if SpecializationUtil.hasSpecialization(c, self.specializations) then
					--print("found Roue spec.")--print( self.name.." has Roue spec." );
					if c.changeSteer ~= nil then
						self.acHasRoueSpec = true;
						self.acRoueUpdate = c.update
						c.changeSteer = Utils.appendedFunction( c.changeSteer, AutoTractor.roueChangeSteer );
						print( "AutoTractor connection to 4-wheel steering registered" );
					end
				end
			end
		end
	end	

end

------------------------------------------------------------------------
-- initMogliHud
------------------------------------------------------------------------
function AutoTractor:initMogliHud()
	if self.acMogliInitDone then
		return
	end
	self.acMogliInitDone = true
	
	local mogliRows = 4
	local mogliCols = 5
	if AutoTractor.acDevFeatures then
		mogliCols = mogliCols + 1
	end
	
	Mogli.init( self, AtDirectory, "AutoTractorHud", "AutoTractorHud.dds",  "AUTO_TRACTOR_TEXTHELPPANELON", "AUTO_TRACTOR_TEXTHELPPANELOFF", InputBinding.AUTO_TRACTOR_HELPPANEL, 0.025, 0.0108, mogliCols, mogliRows, AutoTractor.sendParameters )
	Mogli.setTitle( self, "AUTO_TRACTOR_VERSION" )
	
	if AutoTractor.acDevFeatures then
		Mogli.addButton(self, "empty.dds", nil, AutoTractor.test3, nil, 6,1, "Trace" );
		Mogli.addButton(self, "empty.dds", nil, AutoTractor.test1, nil, 6,2, "Turn Outside");
		Mogli.addButton(self, "empty.dds", nil, AutoTractor.test2, nil, 6,3, "Turn Inside" );
		Mogli.addButton(self, "empty.dds", nil, AutoTractor.test4, nil, 6,4, "Points" );
	end

	Mogli.addButton(self, "off.dds",            "on.dds",           AutoTractor.onStart,       AutoTractor.evalStart,     1,1, "HireEmployee", "DismissEmployee", nil, AutoTractor.getStartImage );
	Mogli.addButton(self, "ai_combine.dds",     "auto_combine.dds", AutoTractor.onEnable,      AutoTractor.evalEnable,    2,1, "AUTO_TRACTOR_STOP", "AUTO_TRACTOR_START" );
	Mogli.addButton(self, "no_uturn2.dds",      "uturn.dds",        AutoTractor.setUTurn,      AutoTractor.evalUTurn,     3,1, "AUTO_TRACTOR_UTURN_OFF", "AUTO_TRACTOR_UTURN_ON") ;
	Mogli.addButton(self, "auto_steer_off.dds", "auto_steer_on.dds",AutoTractor.onAutoSteer,   AutoTractor.evalAutoSteer, 4,1, "AUTO_TRACTOR_STEER_ON", "AUTO_TRACTOR_STEER_OFF" );
	Mogli.addButton(self, "next.dds",           "no_next.dds",      AutoTractor.nextTurnStage, AutoTractor.evalTurnStage, 5,1, "AUTO_TRACTOR_NEXTTURNSTAGE", nil );
	
	Mogli.addButton(self, "noHeadland.dds",     "headland.dds",     AutoTractor.setHeadland,   AutoTractor.evalHeadland,  1,2, "AUTO_TRACTOR_HEADLAND_ON", "AUTO_TRACTOR_HEADLAND_OFF" );
	Mogli.addButton(self, "empty.dds",          "empty.dds",        AutoTractor.setBigHeadland,nil,                       2,2, "AUTO_TRACTOR_HEADLAND", nil, AutoTractor.getBigHeadlandText, AutoTractor.getBigHeadlandImage );
	Mogli.addButton(self, "collision_off.dds",  "collision_on.dds", AutoTractor.setCollision,  AutoTractor.evalCollision, 3,2, "AUTO_TRACTOR_COLLISION_OFF", "AUTO_TRACTOR_COLLISION_ON" );
	Mogli.addButton(self, "empty.dds",          "empty.dds",        AutoTractor.setBigTurn,    nil,                       4,2, nil, nil, AutoTractor.getBigTurnText, AutoTractor.getBigTurnImage );
--Mogli.addButton(self, "reverse.dds",        "no_reverse.dds",   AutoTractor.setNoReverse,  AutoTractor.evalNoReverse, 5,2, "AUTO_TRACTOR_REVERSE_ON", "AUTO_TRACTOR_REVERSE_OFF");
  Mogli.addButton(self, "hire_off.dds",       "hire_on.dds",      AutoTractor.setIsHired,    AutoTractor.evalIsHired,   5,2, "AUTO_TRACTOR_HIRE_OFF", "AUTO_TRACTOR_HIRE_ON");
	
	Mogli.addButton(self, "inactive_left.dds",  "active_left.dds",  AutoTractor.setAreaLeft,   AutoTractor.evalAreaLeft,  1,3, "AUTO_TRACTOR_ACTIVESIDERIGHT", "AUTO_TRACTOR_ACTIVESIDELEFT" );
	Mogli.addButton(self, "inactive_right.dds", "active_right.dds", AutoTractor.setAreaRight,  AutoTractor.evalAreaRight, 2,3, "AUTO_TRACTOR_ACTIVESIDELEFT", "AUTO_TRACTOR_ACTIVESIDERIGHT" );	
	Mogli.addButton(self, "angle_plus.dds",     "empty.dds",        AutoTractor.setAngleUp,    AutoTractor.evalAngleUp,   3,3, "AUTO_TRACTOR_ANGLE_OFFSET", nil, AutoTractor.getAngleOffset);
	Mogli.addButton(self, "angle_minus.dds",    "empty.dds",        AutoTractor.setAngleDown,  AutoTractor.evalAngleDown, 4,3, "AUTO_TRACTOR_ANGLE_OFFSET", nil, AutoTractor.getAngleOffset);
	Mogli.addButton(self, "noFrontPacker.dds",  "frontPacker.dds",  AutoTractor.setFrontPacker,AutoTractor.evalFrontPacker,5,3,"AUTO_TRACTOR_FRONT_PACKER_OFF", "AUTO_TRACTOR_FRONT_PACKER_ON" );

	Mogli.addButton(self, "bigger.dds",         nil,                AutoTractor.setWidthUp,    nil,                       1,4, "AUTO_TRACTOR_WIDTH_OFFSET", nil, AutoTractor.getWidth);
	Mogli.addButton(self, "smaller.dds",        nil,                AutoTractor.setWidthDown,  nil,                       2,4, "AUTO_TRACTOR_WIDTH_OFFSET", nil, AutoTractor.getWidth);
	Mogli.addButton(self, "forward.dds",        nil,                AutoTractor.setForward,    nil,                       3,4, "AUTO_TRACTOR_TURN_OFFSET", nil, AutoTractor.getTurnOffset);
	Mogli.addButton(self, "backward.dds",       nil,                AutoTractor.setBackward,   nil,                       4,4, "AUTO_TRACTOR_TURN_OFFSET", nil, AutoTractor.getTurnOffset);
	Mogli.addButton(self, "notInverted.dds",     "inverted.dds",    AutoTractor.setInverted,   AutoTractor.evalInverted,  5,4, "AUTO_TRACTOR_INVERTED_OFF", "AUTO_TRACTOR_INVERTED_ON" );
	
end

------------------------------------------------------------------------
-- draw
------------------------------------------------------------------------
function AutoTractor:draw()

	if self.acMogliInitDone then
		Mogli.draw(self,self.acLCtrlPressed);
	elseif self.acLCtrlPressed == nil or not self.acLCtrlPressed then
		g_currentMission:addHelpButtonText(Mogli.getText("AUTO_TRACTOR_TEXTHELPPANELON"), InputBinding.AUTO_TRACTOR_HELPPANEL);
	end

	if self.acLCtrlPressed then
		if self.acParameters.enabled then
			g_currentMission:addHelpButtonText(Mogli.getText("AUTO_TRACTOR_START"), InputBinding.AUTO_TRACTOR_ENABLE)
		else
			g_currentMission:addHelpButtonText(Mogli.getText("AUTO_TRACTOR_STOP"), InputBinding.AUTO_TRACTOR_ENABLE)
		end

		if AutoTractor.evalAutoSteer(self) then
			g_currentMission:addHelpButtonText(Mogli.getText("AUTO_TRACTOR_STEER_ON"), InputBinding.AUTO_TRACTOR_STEER);
		elseif self.acTurnStage >= 98 then
			g_currentMission:addHelpButtonText(Mogli.getText("AUTO_TRACTOR_STEER_OFF"),InputBinding.AUTO_TRACTOR_STEER);
		end	
	else
		if self.acParameters.rightAreaActive then
			g_currentMission:addHelpButtonText(Mogli.getText("AUTO_TRACTOR_ACTIVESIDERIGHT"), InputBinding.AUTO_TRACTOR_SWAP_SIDE)
		else
			g_currentMission:addHelpButtonText(Mogli.getText("AUTO_TRACTOR_ACTIVESIDELEFT"), InputBinding.AUTO_TRACTOR_SWAP_SIDE)
		end
	end	
end;

------------------------------------------------------------------------
-- onLeave
------------------------------------------------------------------------
function AutoTractor:onLeave()
	if self.acMogliInitDone then
		Mogli.onLeave(self);
	end
end;

------------------------------------------------------------------------
-- onEnter
------------------------------------------------------------------------
function AutoTractor:onEnter()
	if self.acMogliInitDone then
		Mogli.onEnter(self);
	end
end;

------------------------------------------------------------------------
-- mouseEvent
------------------------------------------------------------------------
function AutoTractor:mouseEvent(posX, posY, isDown, isUp, button)
	if self.acMogliInitDone then
		Mogli.mouseEvent(self, posX, posY, isDown, isUp, button);	
	end
end

------------------------------------------------------------------------
-- delete
------------------------------------------------------------------------
function AutoTractor:delete()
	if self.acMogliInitDone then
		Mogli.delete(self)
	end
	AutoSteeringEngine.deleteChain(self)
end;

------------------------------------------------------------------------
-- mouse event callbacks
------------------------------------------------------------------------
function AutoTractor.showGui(self,on)
	if on then
		if self.acMogliInitDone == nil or not self.acMogliInitDone then
			AutoTractor.initMogliHud(self)
		end
		Mogli.showGui(self,true)
	elseif self.acMogliInitDone then
		Mogli.showGui(self,false)
	end
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
	if not enabled then
		self.acParameters.headland = enabled;
	elseif  self.acParameters.upNDown 
			and ( not self.isAITractorActivated
         or not self.acParameters.enabled
				 or self.acTurnStage == 0 ) then
		self.acParameters.headland = enabled;
	end
end

function AutoTractor:evalIsHired()
	return not self.acParameters.isHired
end

function AutoTractor:setIsHired(enabled)
	self.acParameters.isHired = enabled
end 

function AutoTractor:evalCollision()
	return not ( self.acParameters.upNDown and self.acParameters.collision );
end

function AutoTractor:setCollision(enabled)
	if not enabled then
		self.acParameters.collision = enabled;
	elseif  self.acParameters.upNDown then
		self.acParameters.collision = enabled;
	end
end

function AutoTractor:evalInverted()
	return not self.acParameters.inverted
end

function AutoTractor:setInverted(enabled)
	self.acParameters.inverted = enabled;
end

function AutoTractor:evalFrontPacker()
	return not self.acParameters.frontPacker
end

function AutoTractor:setFrontPacker(enabled)
	self.acParameters.frontPacker = enabled;
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
    self:stopAITractor()
  elseif AITractor.canStartAITractor(self) and enabled then
    self:startAITractor()
  end
end;

function AutoTractor:getStartImage()
	if self.isAITractorActivated then
		return "on.dds"
	elseif AITractor.canStartAITractor(self) then
		return "off.dds"
	end
	return "empty.dds"
end

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
	local new = ""
	if self.acDimensions == nil or self.acDimensions.headlandCount == nil then
		new = string.format(old..": %0.2fm",self.acParameters.turnOffset)
	else
		new = string.format(old..": %0.2fm (%i x)",self.acParameters.turnOffset,self.acDimensions.headlandCount)
	end
	return new
end

function AutoTractor:evalAngleUp()
	local enabled = AutoTractor.getMaxLookingAngleValue( self, true ) < 44.5;
	return enabled
end

function AutoTractor:evalAngleDown()
	local enabled = AutoTractor.getMaxLookingAngleValue( self, true ) > 1.5;
	return enabled
end

function AutoTractor:setAngleUp(enabled)
	if enabled then self.acParameters.angleOffset = self.acParameters.angleOffset + 1 end
end

function AutoTractor:setAngleDown(enabled)
	if enabled then self.acParameters.angleOffset = self.acParameters.angleOffset - 1 end
end

function AutoTractor:getMaxLookingAngleValue( noScale )
	local ml = ASEGlobals.maxLooking
	
	--if      self.acParameters ~= nil
	--		and self.acDimensions ~= nil
	--		and self.acParameters.noReverse 
	--		and self.acDimensions.maxSteeringAngle ~= nil then
	--	ml = math.deg(self.acDimensions.maxSteeringAngle)
	--end
	if      self.acParameters                  ~= nil
			and self.acParameters.angleOffset      ~= nil then
		ml  = math.max( ml + self.acParameters.angleOffset, 1 )
	end
	--if      ( noScale == nil or noScale ~= true ) 
	--		and self.acParameters ~= nil 
	--		and not self.acParameters.upNDown then
	--	ml = math.floor( 1.5 * ml + 0.5 )
	--end	
	if      self.acDimensions                  ~= nil 
			and self.acDimensions.maxSteeringAngle ~= nil then
		ml  = math.min( ml ,math.deg( self.acDimensions.maxSteeringAngle) )
	end
	
	return ml
end

function AutoTractor:getAngleOffset(old)
	new = string.format(old..": %2i",AutoTractor.getMaxLookingAngleValue( self ) );
	return new
end

function AutoTractor:evalTurnStage()
	if self.isAITractorActivated then
		if self.acParameters.enabled then
			for _,ts in pairs( AutoTractor.turnStageNoNext ) do
				if self.acTurnStage == ts then
					return false
				end
			end
			return true
		else
			if self.turnStage > 0 and self.turnStage < 4 then
				return true;
			end
		end
	end
	
	return false
end

function AutoTractor:nextTurnStage()
	AutoTractor.setNextTurnStage(self);
end

function AutoTractor:evalPause()
	return self.isAITractorActivated and self.acParameters.enabled and not self.acPause
end

function AutoTractor:setPause(enabled)
	self.acPause = enabled
	if self.acPause then
		self:dismiss()
	else
		self:hire()
	end

  if g_server ~= nil then
    g_server:broadcastEvent(AutoTractorPauseEvent:new(self,enabled), nil, nil, self)
  else
    g_client:getServerConnection():sendEvent(AutoTractorPauseEvent:new(self,enabled))
  end
end

function AutoTractor:evalAutoSteer()
	return self.isAITractorActivated or self.acTurnStage < 98
end

function AutoTractor:onAutoSteer(enabled)
	if self.isAITractorActivated then
		if self.acTurnStage >= 98 then
			self.acTurnStage   = 0
		end
	elseif enabled then
		--self.setAIImplementsMoveDown(self,true);
		self.acLastSteeringAngle = nil;
		self.acTurnStage   = 98
		self.acRotatedTime = 0
	else
		self.acTurnStage   = 0
    self.stopMotorOnLeave = true
    self.deactivateOnLeave = true
	end
end

function AutoTractor:setBigTurn()
	local sut, rev = AutoSteeringEngine.getTurnMode( self )
	if self.acParameters.noReverse then
		self.acParameters.bigTurn   = 0
		self.acParameters.noReverse = false	
	else
		local maxTurn = 0
		if rev then
			if self.acParameters.upNDown and sut then
				maxTurn = 1 -- 2
			else
				maxTurn = 1
			end
		end
		self.acParameters.bigTurn =  self.acParameters.bigTurn + 1
		if self.acParameters.bigTurn > maxTurn then
			self.acParameters.bigTurn   = 0
			self.acParameters.noReverse = true
		end		
	end
end

function AutoTractor:getBigTurnImage()
	local img = "empty.dds"
	
	if     self.acTurnMode == "O" then
		img = "noRevUTurn.dds"
	elseif self.acTurnMode == "A" then
		img = "smallUTurn.dds"
	elseif self.acTurnMode == "Y" then
		img = "smallUTurn2.dds"
	elseif self.acTurnMode == "T" then
		img = "bigUTurn.dds"
	elseif self.acTurnMode == "C" then
		img = "noRevSide.dds"
	elseif self.acTurnMode == "L" then
		img = "smallSide.dds"
	elseif self.acTurnMode == "K" then
		img = "bigSide.dds"
	end

	if AutoTractor.acDevFeatures then
		if self.acLastBigImg == nil or self.acLastBigImg ~= img then
			self.acLastBigImg = img
			print(img)
		end
	end
	
	return img
end

function AutoTractor:getBigTurnText(old)
	return Mogli.getText("AUTO_TRACTOR_TURN_MODE_"..self.acTurnMode)
end

function AutoTractor:setBigHeadland()
	if self.acParameters.upNDown then
		self.acParameters.bigHeadland = not self.acParameters.bigHeadland
	end
end

function AutoTractor:getBigHeadlandImage()
	local img = "empty.dds"
	
	if self.acParameters ~= nil and self.acParameters.upNDown and self.acParameters.headland then
	  if self.acParameters.bigHeadland then		
			img = "big_headland.dds"
		else
			img = "small_headland.dds"
		end
	end
	
	return img
end

function AutoTractor:getBigHeadlandText(old)
	if      self.acDimensions ~= nil 
			and self.acDimensions.headlandDist ~= nil
			and self.acParameters.upNDown then
		new = string.format(old..": %0.2fm",self.acDimensions.headlandDist );
	else
		new = old
	end
	return new
end

------------------------------------------------------------------------
-- keyEvent
------------------------------------------------------------------------
function AutoTractor:keyEvent(unicode, sym, modifier, isDown)
	if isDown and sym == Input.KEY_s then
		AutoTractor.setInt32Value( self, "speed2Level", 0 )
	end
	if isDown and sym == Input.KEY_lctrl then
		self.acLCtrlPressed = true
	else
		self.acLCtrlPressed = false
	end
end

------------------------------------------------------------------------
-- update
------------------------------------------------------------------------
function AutoTractor:update(dt)

	if      self.articulatedAxis ~= nil 
			and ASEGlobals.artAxisMode > 0
			and self.articulatedAxis.componentJoint ~= nil
      and self.articulatedAxis.componentJoint.jointNode ~= nil 
			and self.acDimensions ~= nil 
			and self.acDimensions.wheelBase ~= nil then	
		if     ASEGlobals.artAxisMode == 1 or ASEGlobals.artAxisMode == 3 then			
			local _,angle,_ = getRotation( self.articulatedAxis.componentJoint.jointNode );
			setRotation( self.acRefNode, 0, ASEGlobals.artAxisRot * angle, 0 )
			setTranslation( self.acRefNode, ASEGlobals.artAxisShift * self.acDimensions.wheelBase * math.sin( angle ), 0, 0 )
		elseif ASEGlobals.artAxisMode == 4 then			
			local linked = false
			for _, implement in pairs(vehicle.attachedImplements) do
				if implement.object ~= nil and implement.object.attacherJoint ~= nil and implement.object.attacherJoint.node ~= nil then
					linked = true
					link( implement.object.attacherJoint.node, self.acRefNode )
				end
			end	
			
			if not linked then
				link( self.articulatedAxis.componentJoint.jointNode, self.acRefNode )
			end			
		end			
	end

	if atDump and self:getIsActiveForInput(false) then
		AutoTractor.acDump2(self);
	end

	if self:getIsActiveForInput(false) then
		if InputBinding.hasEvent(InputBinding.AUTO_TRACTOR_HELPPANEL) then
			AutoTractor.showGui( self, not self.mogliGuiActive );
		end;
		if InputBinding.hasEvent(InputBinding.AUTO_TRACTOR_SWAP_SIDE) then
			self.acParameters.leftAreaActive  = not self.acParameters.leftAreaActive;
			self.acParameters.rightAreaActive = not self.acParameters.rightAreaActive;
			AutoTractor.sendParameters(self);
			if self.isServer then AutoSteeringEngine.setChainStraight( self ) end
		elseif InputBinding.hasEvent(InputBinding.AUTO_TRACTOR_STEER) then
			if self.acTurnStage < 98 then
				AutoTractor.onAutoSteer(self, true)
			else
				AutoTractor.onAutoSteer(self, false)
			end
		elseif InputBinding.hasEvent(InputBinding.AUTO_TRACTOR_ENABLE) then
			AutoTractor.onEnable( self, not self.acParameters.enabled )
		end

		if	InputBinding.hasEvent(InputBinding.SPEED_LEVEL1) then
			AutoTractor.setInt32Value( self, "speed2Level", 1 )
		elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL2) then
			AutoTractor.setInt32Value( self, "speed2Level", 2 )
		elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL3) then
			AutoTractor.setInt32Value( self, "speed2Level", 3 )
		elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL4) then
			AutoTractor.setInt32Value( self, "speed2Level", 4 )
		end;
	end;
	
	if self.acTurnStage >= 98 then
    self.stopMotorOnLeave = false
    self.deactivateOnLeave = false
	end
	
	if      self:getIsActiveForInput(false) 
			and self.acParameters ~= nil
			and self.acParameters.enabled
			and ASEGlobals.showTrace > 0 
			and self.acDimensions ~= nil
			and ( self.isAITractorActivated or self.acTurnStage >= 98 ) then	
		AutoSteeringEngine.drawLines( self );
	elseif  self:getIsActiveForInput(false) 
			and self.acParameters ~= nil
			and self.acParameters.enabled
			and self.mogliGuiActive then	
		AutoTractor.checkState( self )
		AutoSteeringEngine.drawMarker( self );
	end
	
	if not AutoTractor.acDevFeatures then
		self.mogliInfoText = ""
		if self.acDimensions ~= nil and self.acDimensions.distance ~= nil then
			self.mogliInfoText = Mogli.getText( "AUTO_TRACTOR_WORKWIDTH" ) .. string.format(" %0.2fm", self.acDimensions.distance+self.acDimensions.distance)
		end
		if self.acTurnStage ~= nil and self.acTurnStage ~= 0 and self.acTurnStage < 98 then
			self.mogliInfoText = self.mogliInfoText .. string.format(" (%i)", self.acTurnStage)
		end
	end
end

------------------------------------------------------------------------
-- updateTick
------------------------------------------------------------------------
function AutoTractor:updateTick(dt)

	if      self.acParameters ~= nil
			and self.acParameters.enabled 
			and self.isAITractorActivated then
		self.realForceAiDriven = true
	end
	
end

function AutoTractor:newUpdateTick(dt)

	if self.acParameters == nil then return end
	
	if      self.aiTractorDirectionNode ~= nil
			and not ( self.articulatedAxis ~= nil 
						and ASEGlobals.artAxisMode > 0 
						and self.articulatedAxis.componentJoint ~= nil
						and self.articulatedAxis.anchorActor ~= nil
						and self.articulatedAxis.componentJoint.jointNode ~= nil )
			and getParent( self.acRefNode ) ~= self.aiTractorDirectionNode then				
		link( self.aiTractorDirectionNode, self.acRefNode )
		self.acDimensions = nil
		AutoSteeringEngine.checkTools( self, true )
	end
	
	if self.acRefNodeIsInverted ~= self.acParameters.inverted then
		self.acRefNodeIsInverted = self.acParameters.inverted
		if self.acParameters.inverted then
			setRotation( self.acRefNode, 0, math.pi, 0 )
		else
			setRotation( self.acRefNode, 0, 0, 0 )
		end
		self.acDimensions = nil
		AutoSteeringEngine.checkTools( self, true )
	end
	
	if not ( ( self.isAITractorActivated and self.acParameters.enabled )
				or self.acTurnStage>= 98 ) then
		AutoTractor.setStatus( self, 0 )
	end
	
	if      not self.isAITractorActivated 
			and math.abs(self.axisSide) <= 0.1
			and self.isServer
			and self.acTurnStage        >= 98 then
		AutoTractor.autoSteer(self,dt)
	end
	
	if self.acTurnStageSent ~= self.acTurnStage then
		self.acLast = nil
		AutoTractor.setInt32Value( self, "turnStage", self.acTurnStage )
	end
	
end

function AutoTractor:newGetIsHired( superFunc, ... )
	if self.acParameters ~= nil and self.acParameters.enabled and not self.acParameters.isHired then
		return false
	else
		return superFunc( self, ... )
	end
end

------------------------------------------------------------------------
-- newUpdateToolsInfo
------------------------------------------------------------------------
function AutoTractor:newUpdateToolsInfo()
	AutoSteeringEngine.checkTools( self, true )
end

------------------------------------------------------------------------
-- processImplementsOfImplement
------------------------------------------------------------------------
function AutoTractor.processImplementsOfImplement(self,object,turnOn)
	if object.attachedImplements ~= nil and table.getn( object.attachedImplements ) > 0 then
		for _,implement in pairs(object.attachedImplements) do
			local obj = implement.object
			if obj ~= nil then
				if turnOn then
					AITractor.addCollisionTrigger(self, obj);
				else
					AITractor.removeCollisionTrigger(self, obj);
				end

				AutoTractor.processImplementsOfImplement(self,obj,turnOn)
			end
		end
	end
end

------------------------------------------------------------------------
-- AITractor:attachImplement
------------------------------------------------------------------------
function AutoTractor:newAttachImplement(implement)
	local object = implement.object
	if object ~= nil and self.isAITractorActivated then
		AutoTractor.processImplementsOfImplement(self,object,true)
		AutoSteeringEngine.setToolsAreTurnedOn( self, true, true, object )
	end
	self.aiToolsDirty = true
end

------------------------------------------------------------------------
-- AITractor:detachImplement
------------------------------------------------------------------------
function AutoTractor:newDetachImplement(implementIndex)
	local object = self.attachedImplements[implementIndex].object
	if object ~= nil and self.isAITractorActivated then
		AutoTractor.processImplementsOfImplement(self,object,false)
		AutoSteeringEngine.setToolsAreTurnedOn( self, false, true, object )
	end
	self.aiToolsDirty = true
end

------------------------------------------------------------------------
-- AITractor:startAITractor
------------------------------------------------------------------------
function AutoTractor:newStartAITractor( superFunc, noEventSend, ... )

	self.acClearTraceAfterTurn = true

	-- just to be safe...
	if self.acParameters ~= nil and self.acParameters.enabled then
		self.realForceAiDriven = true
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(AITractorSetStartedEvent:new(self, true), nil, nil, self);
			else
				g_client:getServerConnection():sendEvent(AITractorSetStartedEvent:new(self, true));
			end
		end
		
		self:hire()
		if not self.isAITractorActivated then
			self.isAITractorActivated = true;
		
			if self.isServer then
				AITractor.addCollisionTrigger(self, self);
			end;
		
			AITractor.updateToolsInfo(self);
		
			AutoTractor.processImplementsOfImplement(self,self,true)
			AutoSteeringEngine.setToolsAreTurnedOn( self, true, false )
		
			self.checkSpeedLimit = false;		
		end;
		
		AutoSteeringEngine.invalidateField( self )
		
		AutoTractor.roueInitWheels( self );
		if      self.isRealistic 
				and self.motor                   ~= nil
				and self.motor.realSpeedLevelsAI ~= nil then
			self.acRealSpeedLevelsAI1 = self.motor.realSpeedLevelsAI[1]
		else
			self.acRealSpeedLevelsAI1 = nil
		end
		
		self.acDimensions  = nil;
		self.acTurnStage   = -3;
		self.turnTimer     = self.acDeltaTimeoutWait;
		self.aiRescueTimer = self.acDeltaTimeoutStop;
		self.waitForTurnTime = 0;
		
		if self.speed2Level == nil or self.speed2Level < 1 or self.speed2Level > 4 then
			self.speed2Level = 1
		end
		
		if AITractor.invertsMarkerOnTurn( self, self.acParameters.leftAreaActive ) then
			if self.acParameters.leftAreaActive then
				AITractor.aiRotateLeft(self);
			else
				AITractor.aiRotateRight(self);
			end			
		end
		
		AutoTractor.sendParameters(self);
		
		self.acStat = {}		
		self.acLast = nil
	else
		return superFunc( self, noEventSend, ... )
	end
end

------------------------------------------------------------------------
-- AITractor:stopAITractor
------------------------------------------------------------------------
--local showOnce17 = true
function AutoTractor:newStopAITractor( superFunc, noEventSend, ... )
	if self == nil or superFunc == nil or type(superFunc) ~= "function" then
		--if showOnce17 == true then
		--	showOnce17 = false
		--	Mogli.printCallstack()
		--end
	elseif self.acParameters ~= nil and self.acParameters.enabled then
		self.realForceAiDriven = false
	
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(AITractorSetStartedEvent:new(self, false));
			else
				g_client:getServerConnection():sendEvent(AITractorSetStartedEvent:new(self, false));
			end
		end
		
		self:dismiss()
		
		if self.isAITractorActivated then
		
			if self.isServer then
				self.motor:setSpeedLevel(0, false);
				self.motor.maxRpmOverride = nil;
	
				WheelsUtil.updateWheelsPhysics(self, 0, self.lastSpeed, 0, false, self.requiredDriveMode);
	
				AITractor.removeCollisionTrigger(self, self);
			end
			
			self.isAITractorActivated = false;
		
			self.checkSpeedLimit = true;
	
			self.aiTractorTurnLeft = nil;
			
			AutoTractor.processImplementsOfImplement(self,self,false)
			AutoSteeringEngine.setToolsAreTurnedOn( self, false, true )
		
			if not self:getIsActive() then
					self:onLeave()
			end		
		end	
		
		if AutoTractor.acDevFeatures and self.acStat ~= nil then
			for n,t in pairs(self.acStat) do 
				print(tostring(n)..": "..tostring(t))
			end
		end
		AutoSteeringEngine.invalidateField( self )		
		AutoTractor.roueReset( self )
		if self.isRealistic 
				and self.motor                   ~= nil
				and self.motor.realSpeedLevelsAI ~= nil
				and self.acRealSpeedLevelsAI1    ~= nil then
			self.motor.realSpeedLevelsAI[1] = self.acRealSpeedLevelsAI1
		end		
	else
		return superFunc( self, noEventSend, ... )
	end
end

------------------------------------------------------------------------
-- AITractor.canStartAITractor
------------------------------------------------------------------------
function AutoTractor:newCanStartAITractor( superFunc, ...  )

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

	return superFunc( self, ... );	
end

------------------------------------------------------------------------
-- AITractor.getIsAITractorAllowed
------------------------------------------------------------------------
function AutoTractor:newGetIsAITractorAllowed( superFunc, ...  )

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
	
	return superFunc( self, ... );
end;

------------------------------------------------------------------------
-- AITractor:setAIImplementsMoveDown(moveDown)
------------------------------------------------------------------------
function AutoTractor:setAIImplementsMoveDown( moveDown )

	if self.isServer then
		g_server:broadcastEvent(AISetImplementsMoveDownEvent:new(self, moveDown), nil, nil, self);
	end;

	if     self.acImplementsMoveDown == nil
			or self.acImplementsMoveDown ~= moveDown then
		self.acImplementsMoveDown = moveDown
		AutoSteeringEngine.setToolsAreLowered( self, moveDown, false )
	end

end

------------------------------------------------------------------------
-- setStatus
------------------------------------------------------------------------
function AutoTractor:setStatus( newStatus, noEventSend )
	
	if self.mogliStatus == nil or self.mogliStatus ~= newStatus then
		AutoTractor.setInt32Value( self, "status", Utils.getNoNil( newStatus, 0 ) )
	end
	
end

------------------------------------------------------------------------
-- checkState
------------------------------------------------------------------------
function AutoTractor:checkState( onlyMaxLooking )

	if self.acDimensions == nil then
		AutoTractor.calculateDimensions( self )
	end
	
	self.acTurnMode = "T"
	local sut, rev, noHire = AutoSteeringEngine.getTurnMode( self )
	
	if noHire then
		self.acParameters.isHired = false
	end
	
	if self.acParameters.upNDown then
	--if     self.acParameters.bigTurn > 1 then
	--	sut = false
	--elseif self.acParameters.bigTurn > 0 then
		if self.acParameters.bigTurn > 0 then
			rev = false
		end
		if self.acParameters.noReverse then
			self.acTurnMode = "O"
		elseif  rev and sut then
			self.acTurnMode = "A"
		elseif  rev 
				and self.acDimensions.distance ~= nil 
				and self.acDimensions.radius   ~= nil 
				and self.acDimensions.distance < self.acDimensions.radius + 1.5 then
			self.acTurnMode = "Y"
		else
			self.acTurnMode = "T"
		end
	else
		if self.acParameters.bigTurn > 0 then
			rev = false
		end
		if      self.acParameters.noReverse then
			self.acTurnMode = "C"
		elseif  rev then
			self.acTurnMode = "L"
		else
			self.acTurnMode = "K"
		end
	end
	
	AutoTractor.calculateDistances( self )
	
	local s = AutoSteeringEngine.getSpecialToolSettings( self )
	
	if s.noReverse then
		self.acParameters.noReverse = true
	end
	if s.rightOnly then
		self.acParameters.upNDown         = false
		self.acParameters.leftAreaActive  = true
		self.acParameters.rightAreaActive = false
	end
	if s.leftOnly then
		self.acParameters.upNDown         = false
		self.acParameters.leftAreaActive  = false
		self.acParameters.rightAreaActive = true
	end
	
	local h = 0;
	local c = 0;
	if      self.acParameters.collision
			and self.acParameters.upNDown
			and self.acTurnStage ~=  -3 
			and self.acTurnStage ~= -13 
			and self.acTurnStage ~= -23 
			then
		c = self.acDimensions.collisionDist
	end
	if      self.acParameters.headland 
			and self.acParameters.upNDown 
			and self.acTurnStage ~=  -3 
			and self.acTurnStage ~= -13 
			and self.acTurnStage ~= -23 
			then
		h = self.acDimensions.headlandDist
	end
	
	local maxLooking = self.acDimensions.maxLookingAngle
	--if -10 < self.acTurnStage and self.acTurnStage ~= 0 and not AutoSteeringEngine.hasFruits( self, 1 ) then
	--	maxLooking = self.acDimensions.maxSteeringAngle
	--end
	
	AutoSteeringEngine.initTools( self, maxLooking, self.acParameters.leftAreaActive, self.acParameters.widthOffset, h, c, self.acTurnMode, self.acSavedMarker, self.uDuringUTurn );

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
	local smooth = 0
	local traceLength = AutoSteeringEngine.getTraceLength(self)

	if self.acTurnStage == 99 and traceLength > 3 then
		smooth = math.min( math.max( 0.1 * ( traceLength - 1 ), 0 ), 0.875 )
	end
	
	local detected, angle, border = AutoTractor.detectAngle( self, smooth )			
--==============================================================						
	
	if detected then
		AutoTractor.setStatus( self, 1 )
		if self.acTurnStage ~= 99 then
			self.acTurnStage = 99
			AutoSteeringEngine.clearTrace( self );
			AutoSteeringEngine.saveDirection( self, false );
		end
		AutoSteeringEngine.saveDirection( self, true );
		self.turnTimer = self.acDeltaTimeoutRun
	else
		AutoTractor.setStatus( self, 2 )
		angle = 0;
		
		self.turnTimer = self.turnTimer - dt;
		if self.acTurnStage == 99 and self.turnTimer < 0 then
			self.acTurnStage = 98
		end
	end
	
--	if not self.acParameters.leftAreaActive then angle = -angle end
	if self.movingDirection < -1E-2 then 
		noReverseIndex = AutoSteeringEngine.getNoReverseIndex( self );
		if noReverseIndex > 0 then
			local toolAngle = AutoSteeringEngine.getToolAngle( self )
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
	--if detected then aiSteeringSpeed = aiSteeringSpeed * 0.5 end
	
	if self.isEntered then
		AutoSteeringEngine.steer( self, dt, angle, aiSteeringSpeed, detected );
	end
	
	self.acRotatedTime = self.rotatedTime
end

------------------------------------------------------------------------
-- getSaveAttributesAndNodes
------------------------------------------------------------------------

function AutoTractor:getSaveAttributesAndNodes(nodeIdent)
	
	local attributes = 'acVersion="1.4"';
	
	local skip = true
	
	for n,p in pairs( AutoTractor.saveAttributesMapping ) do
		if self.acParameters[n] ~= p.default then
			skip = false
		end
		if self.acParameters[n] ~= p.default or p.always then
			if     p.tp == "B" then
				attributes = attributes..' '..p.xml..'="'..Mogli.bool2int(self.acParameters[n]).. '"';
			else
				attributes = attributes..' '..p.xml..'="'..self.acParameters[n].. '"';
			end
		end
	end

	if skip then
		return ""
	end
	
	--if     self.acParameters.enabled
	--		or not self.acParameters.upNDown
	--		or self.acParameters.rightAreaActive
	--		or self.acParameters.headland
	--		or not self.acParameters.collision
	--		or not self.acParameters.bigHeadland
	--		or self.acParameters.inverted
	--		or self.acParameters.frontPacker
	--		or self.acParameters.widthOffset ~= 0
	--		or self.acParameters.turnOffset  ~= 0 
	--		or self.acParameters.angleOffset ~= 0 then
	--	attributes = 'acVersion="1.4"';
	--	attributes = attributes..' acEnabled="'     ..Mogli.bool2int(self.acParameters.enabled).. '"';
	--	attributes = attributes..' acUTurn="'       ..Mogli.bool2int(self.acParameters.upNDown).. '"';
	--	attributes = attributes..' acAreaRight="'   ..Mogli.bool2int(self.acParameters.rightAreaActive).. '"';
	--	attributes = attributes..' acNoReverse="'   ..Mogli.bool2int(self.acParameters.noReverse).. '"';
	--	attributes = attributes..' acHeadland="'    ..Mogli.bool2int(self.acParameters.headland).. '"';
	--	attributes = attributes..' acCollision="'   ..Mogli.bool2int(self.acParameters.collision).. '"';
	--	attributes = attributes..' acInverted="'    ..Mogli.bool2int(self.acParameters.inverted).. '"';
	--	attributes = attributes..' acFrontPacker="' ..Mogli.bool2int(self.acParameters.frontPacker).. '"';
	--	attributes = attributes..' acBigHeadland="' ..Mogli.bool2int(self.acParameters.bigHeadland).. '"';
	--	attributes = attributes..' acBigTurn="'     ..self.acParameters.bigTurn.. '"';
	--	attributes = attributes..' acWidthOffset="' ..self.acParameters.widthOffset..'"';		
	--	attributes = attributes..' acTurnOffset="'  ..self.acParameters.turnOffset..'"';		
	--	attributes = attributes..' acAngleOffset="' ..self.acParameters.angleOffset..'"';		
	--end;
	
	return attributes
end;

------------------------------------------------------------------------
-- loadFromAttributesAndNodes
------------------------------------------------------------------------
function AutoTractor:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	local version = getXMLString(xmlFile, key.."#acVersion");

	for n,p in pairs( AutoTractor.saveAttributesMapping ) do
		if     p.tp == "B" then
			self.acParameters[n] = Mogli.getXmlBool( xmlFile, key.."#"..p.xml, self.acParameters[n]);
		elseif p.tp == "I" then
			self.acParameters[n] = Mogli.getXmlInt(  xmlFile, key.."#"..p.xml, self.acParameters[n]);
		else--if p.tp == "F" then
			self.acParameters[n] = Mogli.getXmlFloat(xmlFile, key.."#"..p.xml, self.acParameters[n]);
		end
  end		
	--self.acParameters.enabled         = Mogli.getXmlBool(xmlFile, key.."#acEnabled",     self.acParameters.enabled);
	--self.acParameters.upNDown	        = Mogli.getXmlBool(xmlFile, key.."#acUTurn",       self.acParameters.upNDown);
	--self.acParameters.rightAreaActive = Mogli.getXmlBool(xmlFile, key.."#acAreaRight",   self.acParameters.rightAreaActive);
	--self.acParameters.noReverse       = Mogli.getXmlBool(xmlFile, key.."#acNoReverse",   self.acParameters.noReverse);
	--self.acParameters.headland        = Mogli.getXmlBool(xmlFile, key.."#acHeadland",    self.acParameters.headland);
	--self.acParameters.collision       = Mogli.getXmlBool(xmlFile, key.."#acCollision",   self.acParameters.collision);
	--self.acParameters.inverted        = Mogli.getXmlBool(xmlFile, key.."#acInverted",    self.acParameters.inverted);
	--self.acParameters.frontPacker     = Mogli.getXmlBool(xmlFile, key.."#acFrontPacker", self.acParameters.frontPacker);
	--self.acParameters.bigHeadland     = Mogli.getXmlBool(xmlFile, key.."#acBigHeadland", self.acParameters.bigHeadland);
	--self.acParameters.bigTurn         = Mogli.getXmlInt( xmlFile, key.."#acBigTurn",     self.acParameters.bigTurn);
	--self.acParameters.widthOffset     = Mogli.getXmlFloat(xmlFile,key.."#acWidthOffset", self.acParameters.widthOffset); 
	--self.acParameters.turnOffset      = Mogli.getXmlFloat(xmlFile,key.."#acTurnOffset",  self.acParameters.turnOffset); 
	--self.acParameters.angleOffset     = Mogli.getXmlInt( xmlFile, key.."#acAngleOffset", self.acParameters.angleOffset); 
	
	self.acParameters.leftAreaActive  = not self.acParameters.rightAreaActive;
	self.acDimensions                 = nil;

	if self.acParameters.angleOffset < 0 and version <= '0.9' then
		self.acParameters.angleOffset = math.min( 0, self.acParameters.angleOffset + 5 )
	end
	
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
	
	AutoTractor.roueSet( self, nil, ASEGlobals.maxLooking )
	
	self.acDimensions                  = {};
	self.acDimensions.radius           = 5;
  self.acDimensions.maxSteeringAngle = math.rad(25);
	self.acDimensions.wheelBase        = self.acDimensions.radius * math.tan( self.acDimensions.maxSteeringAngle )
	self.acDimensions.zOffset          = -0.5 * self.acDimensions.wheelBase;
	
	if      self.articulatedAxis ~= nil 
			and self.articulatedAxis.componentJoint ~= nil
      and self.articulatedAxis.componentJoint.jointNode ~= nil 
			and self.articulatedAxis.rotMax then
		_,_,self.acDimensions.zOffset = AutoSteeringEngine.getRelativeTranslation(self.acRefNode,self.articulatedAxis.componentJoint.jointNode);
		local n=0;
		for _,wheel in pairs(self.wheels) do
			local x,y,z = AutoSteeringEngine.getRelativeTranslation(self.articulatedAxis.componentJoint.jointNode,wheel.driveNode);
			if n==0 then
				self.acDimensions.wheelBase = math.abs(z)
				n = 1
			else
				--self.acDimensions.wheelBase = self.acDimensions.wheelBase + math.abs(z);
				--n  = n  + 1;
				self.acDimensions.wheelBase = math.max( math.abs(z) )
			end
		end
		if n > 1 then
			self.acDimensions.wheelBase = self.acDimensions.wheelBase / n;
		end
		self.acDimensions.maxSteeringAngle = 0.3 * (math.abs(self.articulatedAxis.rotMin)+math.abs(self.articulatedAxis.rotMax))
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
		else
			self.acDimensions.maxSteeringAngle = math.abs( alm )
			self.acDimensions.wheelBase        = 4;
			self.acDimensions.zOffset          = 0;
		end
	end
	
	if self.acParameters.inverted then
		self.acDimensions.wheelBase = -self.acDimensions.wheelBase 
	end
	
	--adjusted steering
	if self.as ~= nil and self.as.radI ~= nil and self.as.radO ~= nil and 0 < self.as.radO and self.as.radO < self.as.radI then
		self.acDimensions.maxSteeringAngle = self.acDimensions.maxSteeringAngle * ( self.as.radO + self.as.radI ) / ( self.as.radI + self.as.radI )
	end
	
	if math.abs( self.acDimensions.wheelBase ) > 1E-3 and math.abs( self.acDimensions.maxSteeringAngle ) > 1E-4 then
		self.acDimensions.radius        = self.acDimensions.wheelBase / math.tan( self.acDimensions.maxSteeringAngle );
	else
		self.acDimensions.radius        = 5;
	end
	
	if AutoTractor.acDevFeatures then
		print(string.format("wb: %0.3fm, r: %0.3fm, z: %0.3fm", self.acDimensions.wheelBase, self.acDimensions.radius, self.acDimensions.zOffset ))
	end
	
end

------------------------------------------------------------------------
-- calculateHeadland
------------------------------------------------------------------------
function AutoTractor.calculateHeadland( turnMode, width, realWidth, zBack, toolDist, radius, wheelBase, big )

	local ret = 0
	if     turnMode == "A"
			or turnMode == "L" then
		ret   = math.max( 2, toolDist ) + math.abs( wheelBase ) + math.abs( zBack ) + math.max( 1, toolDist - zBack )
		if big then
			ret = ret + 3 
		end
		ret   = math.max( ret, width ) 
	elseif turnMode == "C" then
		ret   = width + math.max( -zBack, 0 ) + radius
	elseif turnMode == "O" then
		local beta = math.acos( math.min(math.max(realWidth / radius, 0),1) )
		local z    = 2.2 * radius * math.sin( beta )
		if big then
			z = z + 1.1
		end
		ret   = width + math.max( -zBack, 0 ) + math.max( toolDist - zBack, z ) + math.max( toolDist, 0 ) + radius
	else
		ret   = width + math.max( -zBack, 0 ) + math.max( toolDist - zBack, 0 ) + math.max( toolDist, 0 ) + radius
	end
	
	if ret < 0 then
		ret = 0
	end
	
	return ret
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
	self.acDimensions.maxLookingAngle = math.rad( AutoTractor.getMaxLookingAngleValue( self ) )
	
  ------------------------------------------------------------------------
  -- Roue mode
  ------------------------------------------------------------------------
	AutoTractor.roueSet( self, nil, self.acDimensions.maxLookingAngle )
	AutoSteeringEngine.checkChain( self, self.acRefNode, zo, wb, ms, self.acParameters.widthOffset, self.acParameters.turnOffset, self.acParameters.inverted, self.acParameters.frontPacker );

	self.acDimensions.distance, self.acDimensions.toolDistance, self.acDimensions.zBack = AutoSteeringEngine.checkTools( self );
	
	if self.isAITractorActivated and self.acParameters.enabled and self.acHasRoueSpec and self.acTurnStage <= 0 and self.acDimensions.zBack < 0 and  AutoSteeringEngine.getNoReverseIndex( self ) <= 0 then 
		local zShift, ms = AutoTractor.roueSet( self, self.acDimensions.zBack, self.acDimensions.maxLookingAngle );
		if math.abs( zShift ) > 1E-3 then
			--zo = zo - zShift;
			wb = wb + zShift;
			AutoSteeringEngine.checkChain( self, self.acRefNode, zo, wb, ms, self.acParameters.widthOffset, self.acParameters.turnOffset, self.acParameters.inverted, self.acParameters.frontPacker );
			self.acDimensions.distance, self.acDimensions.toolDistance, self.acDimensions.zBack = AutoSteeringEngine.checkTools( self );
		end
	end

	self.acDimensions.distance0        = self.acDimensions.distance;
	if self.acParameters.widthOffset ~= nil then
		self.acDimensions.distance       = self.acDimensions.distance0 + self.acParameters.widthOffset;
	end
	
	local optimDist = self.acDimensions.distance;
	if self.acDimensions.radius > optimDist then
		self.acDimensions.uTurnAngle     = math.acos( optimDist / self.acDimensions.radius );
	else
		self.acDimensions.uTurnAngle     = 0;
	end;

	optimDist = 1.5
	if self.acParameters.bigHeadland then
		if self.acDimensions.distance ~= nil and self.acDimensions.distance > 1.5 then
			optimDist = self.acDimensions.distance
		end
		optimDist = optimDist + 2
	end
	
	self.acDimensions.insideDistance = math.max( 0, self.acDimensions.toolDistance - 1 - self.acDimensions.distance +(self.acDimensions.radius * math.cos( self.acDimensions.maxSteeringAngle )) );
	self.acDimensions.uTurnDistance  = math.max( 0, 1 + self.acDimensions.toolDistance + self.acDimensions.distance - self.acDimensions.radius);	
	self.acDimensions.headlandDist   = AutoTractor.calculateHeadland( self.acTurnMode, optimDist, self.acDimensions.distance, self.acDimensions.zBack, self.acDimensions.toolDistance, self.acDimensions.radius, self.acDimensions.wheelBase, self.acParameters.bigHeadland )
	self.acDimensions.collisionDist  = 1 + AutoTractor.calculateHeadland( self.acTurnMode, math.max( self.acDimensions.distance, optimDist ), self.acDimensions.distance, self.acDimensions.zBack, self.acDimensions.toolDistance, self.acDimensions.radius, self.acDimensions.wheelBase, self.acParameters.bigHeadland )
	
	--if self.acShowDistOnce == nil then
	--	self.acShowDistOnce = 1
	--else
	--	self.acShowDistOnce = self.acShowDistOnce + 1
	--end
	--if self.acShowDistOnce <= 30 then
	--	print(string.format("max( %0.3f , 1.5 ) + max( - %0.3f, 0 ) + max( %0.3f - %0.3f, 1 ) + %0.3f = %0.3f", self.acDimensions.distance, zBack, self.acDimensions.toolDistance, zBack, self.acDimensions.radius, self.acDimensions.headlandDist ) )
	--end
	
	if self.acParameters.turnOffset ~= nil then
		self.acDimensions.insideDistance = math.max( 0, self.acDimensions.insideDistance + self.acParameters.turnOffset );
		self.acDimensions.uTurnDistance  = math.max( 0, self.acDimensions.uTurnDistance  + self.acParameters.turnOffset );
		self.acDimensions.headlandDist   = math.max( 0, self.acDimensions.headlandDist   + self.acParameters.turnOffset );
		self.acDimensions.collisionDist  = math.max( 0, self.acDimensions.collisionDist  + self.acParameters.turnOffset );
	end
	
	self.acDimensions.headlandCount = 0
	if self.acDimensions.distance > 0 then
		local w = self.acDimensions.distance + self.acDimensions.distance
		self.acDimensions.headlandCount  = math.ceil( ( self.acDimensions.headlandDist ) / w )
		--self.acDimensions.headlandDist   = w * self.acDimensions.headlandCount
	end
	--self.acDimensions.headlandDist     = math.min( math.max( self.acDimensions.headlandDist, 0 ), ASEGlobals.chainMinLen )
end

------------------------------------------------------------------------
-- AutoTractor:roueChangeSteer
------------------------------------------------------------------------
function AutoTractor:roueChangeSteer( ... )
	AutoTractor.roueSaveWheels( self );
end

------------------------------------------------------------------------
-- AutoTractor:roueInitWheels
------------------------------------------------------------------------
function AutoTractor:roueInitWheels()
	
	AutoTractor.roueSaveWheels( self )

	if self.acRoueWheels == nil then return end
	
	for i=1,table.getn(self.wheels) do
		self.acRoueWheels[i].rotMax2   = self.wheels[i].rotMax;
		self.acRoueWheels[i].rotMin2   = self.wheels[i].rotMin;
		self.acRoueWheels[i].rotSpeed2 = self.wheels[i].rotSpeed;		
	end
	
	for i=0,99 do
		self.changeWheel = i
		self.acRoueUpdate( self, 0 )
		
		if self.changeWheel == 0 then break end
	
		for i=1,table.getn(self.wheels) do
			self.acRoueWheels[i].rotMax2   = math.max( self.acRoueWheels[i].rotMax2  , self.wheels[i].rotMax   )
			self.acRoueWheels[i].rotMin2   = math.min( self.acRoueWheels[i].rotMin2  , self.wheels[i].rotMin   )
			self.acRoueWheels[i].rotSpeed2 = math.max( self.acRoueWheels[i].rotSpeed2, self.wheels[i].rotSpeed )
		end
	end
end

------------------------------------------------------------------------
-- AutoTractor:roueSaveWheels
------------------------------------------------------------------------
function AutoTractor:roueSaveWheels()

	if self.acHasRoueSpec then
		if self.acRoueWheels == nil then
			self.acRoueWheels = {};
			for i=1,table.getn(self.wheels) do
				wheel = {}
				wheel.rotMax   = self.wheels[i].rotMax;
				wheel.rotMin   = self.wheels[i].rotMin;
				wheel.rotSpeed = self.wheels[i].rotSpeed;		
				self.acRoueWheels[i] = wheel;
			end
		else
			for i=1,table.getn(self.wheels) do
				self.acRoueWheels[i].rotMax   = self.wheels[i].rotMax;
				self.acRoueWheels[i].rotMin   = self.wheels[i].rotMin;
				self.acRoueWheels[i].rotSpeed = self.wheels[i].rotSpeed;	
			end
		end
	else
		self.acRoueWheels = nil;
	end	
	
end

------------------------------------------------------------------------
--AutoTractor:roueReset
------------------------------------------------------------------------
function AutoTractor:roueReset( )
	if self.acRoueWheels ~= nil then 
		for i=1,table.getn(self.wheels) do
			self.wheels[i].rotMax   = self.acRoueWheels[i].rotMax;
			self.wheels[i].rotMin   = self.acRoueWheels[i].rotMin;
			self.wheels[i].rotSpeed = self.acRoueWheels[i].rotSpeed;		
		end
		
		self.acRoueWheels        = nil
		self.acRoueWheelsChanged = nil

		AutoTractor.roueSetMR( self )
	end
end

------------------------------------------------------------------------
--AutoTractor:roueSet
------------------------------------------------------------------------
function AutoTractor:roueSet( target, angleMax )

	if self.acRoueWheels == nil then return 0, angleMax end
	
	local zShift = 0;
	local iRef, iOther = 1,3;
	local x1,_,z1 = AutoSteeringEngine.getRelativeTranslation( self.acRefNode, self.wheels[1].driveNode )
	local x3,_,z3 = AutoSteeringEngine.getRelativeTranslation( self.acRefNode, self.wheels[3].driveNode )
	local wb      = z1 - z3;
	
	if z1 < z3 then
		iRef    = 3;
		iOthers = 1;
		wb      = z3 - z1;
	end
	
	if     target == nil 
			or target > 0
			or wb     < 1
			or table.getn(self.wheels) ~= 4
			or self.wheels[iRef].rotMax <= math.tan( self.acDimensions.maxLookingAngle ) or math.abs( self.wheels[iRef].rotSpeed ) < 1E-3 then
		if self.acRoueWheelsChanged then
			self.acRoueWheelsChanged = false;
			
			for i=1,table.getn(self.wheels) do
				self.wheels[i].rotMax   = self.acRoueWheels[i].rotMax2;
				self.wheels[i].rotMin   = self.acRoueWheels[i].rotMin2;
				self.wheels[i].rotSpeed = self.acRoueWheels[i].rotSpeed2;		
			end
		else
			return 0, angleMax
		end
	else
		self.acRoueWheelsChanged = true;
		local angleMax = math.atan( math.tan( self.acDimensions.maxLookingAngle ) * ( 1 - target / wb ) )
		
		if angleMax > self.wheels[iRef].rotMax then
			zShift   = ( math.tan( self.wheels[iRef].rotMax ) / math.tan( self.acDimensions.maxLookingAngle ) - 1 ) * wb
			angleMax = self.wheels[iRef].rotMax
		else
			zShift   = -target;
		end
		
		local f = zShift / ( wb + zShift );
		
		for i=0,1 do
			self.wheels[iOther+i].rotMax   = math.atan( math.tan( self.wheels[iRef+i].rotMax ) * f );
			self.wheels[iOther+i].rotMin   = math.atan( math.tan( self.wheels[iRef+i].rotMin ) * f );
			self.wheels[iOther+i].rotSpeed = self.wheels[iRef+i].rotSpeed * self.wheels[iOther+i].rotMax / self.wheels[iRef+i].rotMax;
		end
	end
	
	AutoTractor.roueSetMR( self )

	return zShift, angleMax
end

------------------------------------------------------------------------
--AutoTractor:roueSetMR
------------------------------------------------------------------------
function AutoTractor:roueSetMR( )
	if self.isRealistic then
		for i=1,table.getn(self.wheels) do
			self.wheels[i].realRotMaxSpeed = 0;
			self.wheels[i].realRotMinSpeed = 0;
	
			if self.wheels[i].rotMax~=0 and self.wheels[i].rotMin~=0 and self.wheels[i].rotSpeed~=0 then	

				if math.abs(self.wheels[i].rotMax)>math.abs(self.wheels[i].rotMin) then
					self.wheels[i].realRotMaxSpeed = self.wheels[i].rotSpeed;
					self.wheels[i].realRotMinSpeed = math.abs(self.wheels[i].rotMin/self.wheels[i].rotMax)*self.wheels[i].rotSpeed;
				else
					self.wheels[i].realRotMinSpeed = self.wheels[i].rotSpeed;
					self.wheels[i].realRotMaxSpeed = math.abs(self.wheels[i].rotMax/self.wheels[i].rotMin)*self.wheels[i].rotSpeed;
				end;
		
				if self.wheels[i].rotSpeed<0 then
					local tmp = self.wheels[i].realRotMaxSpeed;
					self.wheels[i].realRotMaxSpeed = self.wheels[i].realRotMinSpeed;
					self.wheels[i].realRotMinSpeed = tmp;
				end
			end
		end
  end
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
					if self.isServer then	AutoSteeringEngine.setChainStraight( self ) end
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
				local ts0 = self.acTurnStage
				self.acTurnStage = self.acTurnStage + 1;
				self.turnTimer   = self.acDeltaTimeoutWait;
				for _,ts in pairs( AutoTractor.turnStageEnd ) do
					if ts[1] == ts0 then
						self.acTurnStage = ts[2]
					end
				end
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
function AutoTractor.getParameterDefaults()
	parameters = {}
	for n,p in pairs( AutoTractor.saveAttributesMapping ) do
		parameters[n] = p.default
	end
	--parameters.upNDown = true;
	--parameters.leftAreaActive = true;
	--parameters.rightAreaActive = false;
	--parameters.enabled = false;
	--parameters.noReverse = false;
	--parameters.headland = false;
	--parameters.collision = true;
	--parameters.inverted = false;
	--parameters.frontPacker = false;
	--parameters.bigHeadland = true;
	--parameters.bigTurn = 0;
	--parameters.turnOffset = 0;
	--parameters.widthOffset = 0;
	--parameters.angleOffset = 0;
	parameters.leftAreaActive  = not parameters.rightAreaActive;
	return parameters
end

function AutoTractor:getParameters()
	if self.acParameters == nil then
		self.acParameters = AutoTractor.getParameterDefaults( )
	end;
	self.acParameters.leftAreaActive  = not self.acParameters.rightAreaActive;

	return self.acParameters;
end;

function AutoTractor.readStreamHelper(streamId)
	local parameters = {};
	
	for n,p in pairs( AutoTractor.saveAttributesMapping ) do
		if     p.tp == "B" then
			parameters[n] = streamReadBool(streamId);
		elseif p.tp == "I" then
			parameters[n] = streamReadInt8(streamId);
		else--if p.tp == "F" then
			parameters[n] = streamReadFloat32(streamId);
		end
	end
	
	--parameters.enabled         = streamReadBool(streamId);
	--parameters.upNDown	       = streamReadBool(streamId);
	--parameters.rightAreaActive = streamReadBool(streamId);
	--parameters.noReverse       = streamReadBool(streamId);
	--parameters.headland        = streamReadBool(streamId);
	--parameters.collision       = streamReadBool(streamId);
	--parameters.inverted        = streamReadBool(streamId);
	--parameters.frontPacker     = streamReadBool(streamId);
	--parameters.bigHeadland     = streamReadBool(streamId);
	--parameters.bigTurn         = streamReadInt8(streamId);
	--parameters.turnOffset      = streamReadFloat32(streamId);
	--parameters.widthOffset     = streamReadFloat32(streamId);
	--parameters.angleOffset     = streamReadInt8(streamId);
	return parameters;
end

function AutoTractor.writeStreamHelper(streamId, parameters)
	for n,p in pairs( AutoTractor.saveAttributesMapping ) do
		if     p.tp == "B" then
			streamWriteBool(streamId, Utils.getNoNil( parameters[n], p.default ));
		elseif p.tp == "I" then
			streamWriteInt8(streamId, Utils.getNoNil( parameters[n], p.default ));
		else--if p.tp == "F" then
			streamWriteFloat32(streamId, Utils.getNoNil( parameters[n], p.default ));
		end
	end
	
	--streamWriteBool(streamId, Utils.getNoNil( parameters.enabled        ,false ));
	--streamWriteBool(streamId, Utils.getNoNil( parameters.upNDown	      ,true ));
	--streamWriteBool(streamId, Utils.getNoNil( parameters.rightAreaActive,false ));
	--streamWriteBool(streamId, Utils.getNoNil( parameters.noReverse      ,false ));
	--streamWriteBool(streamId, Utils.getNoNil( parameters.headland       ,false ));
	--streamWriteBool(streamId, Utils.getNoNil( parameters.collision      ,true ));
	--streamWriteBool(streamId, Utils.getNoNil( parameters.inverted       ,false ));
	--streamWriteBool(streamId, Utils.getNoNil( parameters.frontPacker    ,false ));
	--streamWriteBool(streamId, Utils.getNoNil( parameters.bigHeadland    ,true ));
	--streamWriteInt8(streamId, Utils.getNoNil( parameters.bigTurn        ,0 ));
	--streamWriteFloat32(streamId, Utils.getNoNil( parameters.turnOffset  ,0 ));
	--streamWriteFloat32(streamId, Utils.getNoNil( parameters.widthOffset ,0 ));
	--streamWriteInt8(streamId, Utils.getNoNil( parameters.angleOffset, 0 ));
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
	for n,p in pairs( AutoTractor.saveAttributesMapping ) do
		self.acParameters[n] = Utils.getNoNil( parameters[n], p.default )
	end

	--self.acParameters.enabled         = Utils.getNoNil(parameters.enabled        ,false);
	--self.acParameters.upNDown         = Utils.getNoNil(parameters.upNDown        ,true);
	--self.acParameters.rightAreaActive = Utils.getNoNil(parameters.rightAreaActive,false);
	--self.acParameters.noReverse       = Utils.getNoNil(parameters.noReverse      ,false);
	--self.acParameters.headland        = Utils.getNoNil(parameters.headland       ,false);
	--self.acParameters.collision       = Utils.getNoNil(parameters.headland       ,true);
	--self.acParameters.inverted        = Utils.getNoNil(parameters.inverted       ,false);
	--self.acParameters.frontPacker     = Utils.getNoNil(parameters.frontPacker    ,false);
	--self.acParameters.bigHeadland     = Utils.getNoNil(parameters.bigHeadland    ,true);
	--self.acParameters.bigTurn         = Utils.getNoNil(parameters.bigTurn        ,0);
	--self.acParameters.turnOffset      = Utils.getNoNil(parameters.turnOffset     ,0);
	--self.acParameters.widthOffset     = Utils.getNoNil(parameters.widthOffset    ,0);
	--self.acParameters.angleOffset     = Utils.getNoNil(parameters.angleOffset    ,0);
	self.acParameters.leftAreaActive  = not self.acParameters.rightAreaActive;
end

function AutoTractor:readStream(streamId, connection)
  AutoTractor.setParameters( self, AutoTractor.readStreamHelper(streamId) );
end

function AutoTractor:writeStream(streamId, connection)
  AutoTractor.writeStreamHelper(streamId,AutoTractor.getParameters(self));
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

source(Utils.getFilename("AutoTractorEvents.lua", AtDirectory));


if AutoTractor.acDevFeatures then
	addConsoleCommand("acReset", "Reset global AutoTractor variables to defaults.", "acReset", AutoTractor);
end
function AutoTractor:acReset()
	AutoSteeringEngine.globalsReset();
	AutoSteeringEngine.resetCounter = AutoSteeringEngine.resetCounter + 1;
	for name,value in pairs(ASEGlobals) do
		print(tostring(name).." "..tostring(value));		
	end
end

-- acSave
if AutoTractor.acDevFeatures then
	addConsoleCommand("acSave", "Save the global AutoTractor variables.", "acSave", AutoTractor);
end
function AutoTractor:acSave()
	AutoSteeringEngine.globalsCreate()	
	for name,value in pairs(ASEGlobals) do
		print(tostring(name).." "..tostring(value));		
	end
end

-- acSet
if AutoTractor.acDevFeatures then
	addConsoleCommand("acSet", "Change one of the global AutoTractor variables.", "acSet", AutoTractor);
end
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
if AutoTractor.acDevFeatures then
	addConsoleCommand("acDump", "Dump internal state of AutoTractor", "acDump", AutoTractor);
end
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

function AutoTractor.test1( self )
	self.acTurn2Outside = true;
	self.acTurnStage = 1;
	self.turnTimer = self.acDeltaTimeoutWait;
end

function AutoTractor.test2( self )
	self.acTurn2Outside = false;
	self.acTurnStage = 1;
	self.turnTimer = self.acDeltaTimeoutWait;
end

function AutoTractor.test3( self )
	if ASEGlobals.showTrace > 0 then
		ASEGlobals.showTrace = 0
	else
		ASEGlobals.showTrace = 1
	end
end

function AutoTractor.test4( self )
	if ASEGlobals.showChannels > 0 then
		ASEGlobals.showChannels = 0
	else
		ASEGlobals.showChannels = 1
		ASEGlobals.showTrace = 1
	end
end

AITractor.updateTick = Utils.appendedFunction( AITractor.updateTick, AutoTractor.newUpdateTick );
AITractor.updateToolsInfo = Utils.appendedFunction( AITractor.updateToolsInfo, AutoTractor.newUpdateToolsInfo ); 
AITractor.startAITractor = Utils.overwrittenFunction( AITractor.startAITractor, AutoTractor.newStartAITractor );
AITractor.stopAITractor = Utils.overwrittenFunction( AITractor.stopAITractor, AutoTractor.newStopAITractor );
AITractor.canStartAITractor = Utils.overwrittenFunction( AITractor.canStartAITractor, AutoTractor.newCanStartAITractor )
AITractor.getIsAITractorAllowed = Utils.overwrittenFunction( AITractor.getIsAITractorAllowed, AutoTractor.newGetIsAITractorAllowed );
AITractor.updateAIMovement = Utils.overwrittenFunction( AITractor.updateAIMovement, AutoTractor.newUpdateAIMovement );	
--AITractor.setAIImplementsMoveDown = Utils.overwrittenFunction( AITractor.setAIImplementsMoveDown, AutoTractor.setAIImplementsMoveDown )


AITractor.attachImplement = Utils.appendedFunction( AITractor.attachImplement, AutoTractor.newAttachImplement )
AITractor.detachImplement = Utils.appendedFunction( AITractor.detachImplement, AutoTractor.newDetachImplement )

Vehicle.getIsHired = Utils.overwrittenFunction( Vehicle.getIsHired, AutoTractor.newGetIsHired );
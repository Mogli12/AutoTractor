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

local AtGlobal = {};
local function AtGlobalsReset()
	AtGlobal = {};
	AtGlobal.chainMax    = 6;
	AtGlobal.chainLen    = 2;
	AtGlobal.chainLenInc = 0.2;
	AtGlobal.angleMax    = 4;
	AtGlobal.angleStep   = 4;
	AtGlobal.maxLooking  = 25;
	AtGlobal.directSteer = 1;
--AtGlobal.angleStep1  = 1;
  AtGlobal.average     = 4;
  AtGlobal.offtracking = 5;
  AtGlobal.reverseDir  = 0;
	AtGlobal.minMidDist  = 1;
	AtGlobal.otFactor    = -1;
	AtGlobal.detectedAt  = 5;
	print("AutoTractor initialized");
end
local AtResetCounter = 0;
AtGlobalsReset()

local AtStatus = {}
AtStatus.initial  = 0;
AtStatus.steering = 1;
AtStatus.rotation = 2;
AtStatus.position = 3;

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
	
	self.acDebug = true;
		
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

	Mogli.addButton(self, "off.dds",            "on.dds",           AutoTractor.onStart,       AutoTractor.evalStart,     1,1, "HireEmployee", "DismissEmployee" );
	Mogli.addButton(self, "inactive_left.dds",  "active_left.dds",  AutoTractor.setAreaLeft,   AutoTractor.evalAreaLeft,  3,1, "AUTO_TRACTOR_ACTIVESIDERIGHT", "AUTO_TRACTOR_ACTIVESIDELEFT" );
	Mogli.addButton(self, "inactive_right.dds", "active_right.dds", AutoTractor.setAreaRight,  AutoTractor.evalAreaRight, 4,1, "AUTO_TRACTOR_ACTIVESIDELEFT", "AUTO_TRACTOR_ACTIVESIDERIGHT" );
	Mogli.addButton(self, "next.dds",           "no_next.dds",      AutoTractor.nextTurnStage, AutoTractor.evalTurnStage, 5,1, "AUTO_TRACTOR_NEXTTURNSTAGE", nil );
	
	Mogli.addButton(self, "ai_combine.dds",     "empty.dds",        AutoTractor.onEnable,      AutoTractor.evalEnable,    1,2, "AUTO_TRACTOR_STOP", "AUTO_TRACTOR_START" );
	Mogli.addButton(self, "no_uturn2.dds",      "uturn.dds",        AutoTractor.setUTurn,      AutoTractor.evalUTurn,     3,2, "AUTO_TRACTOR_UTURN_OFF", "AUTO_TRACTOR_UTURN_ON") ;
	Mogli.addButton(self, "reverse.dds",        "no_reverse.dds",   AutoTractor.setNoReverse,  AutoTractor.evalNoReverse, 4,2, "AUTO_TRACTOR_REVERSE_ON", "AUTO_TRACTOR_REVERSE_OFF");
	Mogli.addButton(self, "no_cp.dds",          "cp.dds",           AutoTractor.setCPSupport,  AutoTractor.evalCPSupport, 5,2, "AUTO_TRACTOR_CP_OFF", "AUTO_TRACTOR_CP_ON" );

	Mogli.addButton(self, "bigger.dds",         nil,                AutoTractor.setWidthUp,    nil,                       1,3, "AUTO_TRACTOR_WIDTH_OFFSET", nil, AutoTractor.getWidth);
	Mogli.addButton(self, "smaller.dds",        nil,                AutoTractor.setWidthDown,  nil,                       2,3, "AUTO_TRACTOR_WIDTH_OFFSET", nil, AutoTractor.getWidth);
	Mogli.addButton(self, "forward.dds",        nil,                AutoTractor.setForward,    nil,                       3,3, "AUTO_TRACTOR_TURN_OFFSET", nil, AutoTractor.getTurnOffset);
	Mogli.addButton(self, "backward.dds",       nil,                AutoTractor.setBackward,   nil,                       4,3, "AUTO_TRACTOR_TURN_OFFSET", nil, AutoTractor.getTurnOffset);
	Mogli.addButton(self, "auto_steer_off.dds", "auto_steer_on.dds",AutoTractor.onAutoSteer,   AutoTractor.evalAutoSteer, 5,3, "AUTO_TRACTOR_STEER_ON", "AUTO_TRACTOR_STEER_OFF" );

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

	if self.atResetCounter == nil then
		self.atResetCounter = AtResetCounter;
	elseif self.atResetCounter < AtResetCounter then
		self.atResetCounter = AtResetCounter;
		self.acDimensions   = nil;
		AutoTractor.initChain(self);
	end

	if self:getIsActiveForInput(false) then
		if InputBinding.hasEvent(InputBinding.AUTO_TRACTOR_HELPPANEL) then
			AutoTractor.showGui( self, not self.mogliGuiActive );
		end;
		if InputBinding.hasEvent(InputBinding.AUTO_TRACTOR_STEER) then
			if self.acTurnStage < 98 then
				AutoCombine.onAutoSteer(self, true)
			else
				AutoCombine.onAutoSteer(self, false)
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
	
	if self.mogliGuiActive or self.acParameters.enabled then
		if not self.acChain == nil then
			AutoTractor.initChain(self);
		end
		
		if self.acPoints ~= nil then
			for _,points in pairs(self.acPoints) do
				local notFirst = false;
				local px,py,pz;
				
				off = 0.1
				if not self.acParameters.leftAreaActive then
					off = -off;
				end
				
				for _,p in pairs(points) do
					if notFirst then
						local lx1,lz1,lx2,lz2,lx3,lz3 = AutoTractor.getParallelogram( self, px, pz, p.x, p.z, off );
						local y = 0.5 * ( py + p.y );
						drawDebugLine(lx1,py,lz1,1,0,0,lx3,p.y,lz3,1,0,0);
						drawDebugLine(lx1,py,lz1,0,0,1,lx2,y,lz2,0,0,1);
					else				
						notFirst = true
					end
					px = p.x; 
					py = p.y; 
					pz = p.z;
				end		
			end
		end
	end
end

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
function AutoTractor:getFruitArea(x1,z1,x2,z2,d,tool)
	local lx1,lz1,lx2,lz2,lx3,lz3 = AutoTractor.getParallelogram( self, x1, z1, x2, z2, d );

	if not g_currentMission:getIsFieldOwnedAtWorldPos(lx1,lx2) then return 0,0; end
	
	local area, areaTotal = 0,0;
	if tool.isCombine then
		--local fruitDesc = FruitUtil.fruitIndexToDesc[tool.obj.lastValidInputFruitType];
		--if fruitDesc == nil then print("no valid fruit type") else print("fruit type "..fruitDesc.name) end
		area, areaTotal = Utils.getFruitArea(tool.obj.lastValidInputFruitType, lx1,lz1,lx2,lz2,lx3,lz3,false);	
	else
		local terrainDetailRequiredMask = 0
		if 0 <= tool.aiTerrainDetailChannel1 then
			terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2 ^ tool.aiTerrainDetailChannel1)
			if 0 <= tool.aiTerrainDetailChannel2 then
				terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2 ^ tool.aiTerrainDetailChannel2)
				if 0 <= tool.aiTerrainDetailChannel3 then
					terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2 ^ tool.aiTerrainDetailChannel3)
				end
			end
		end

		area, areaTotal = AITractor.getAIArea(self, lx1, lz1, lx2, lz2, lx3, lz3, 
																					terrainDetailRequiredMask, 
																					tool.aiTerrainDetailProhibitedMask, 
																					tool.aiRequiredFruitType, 
																					tool.aiRequiredMinGrowthState, 
																					tool.aiRequiredMaxGrowthState, 
																					tool.aiProhibitedFruitType, 
																					tool.aiProhibitedMinGrowthState, 
																					tool.aiProhibitedMaxGrowthState)
	end
	
	return area, areaTotal;
end

------------------------------------------------------------------------
-- isField
------------------------------------------------------------------------
function AutoTractor:isField(x1,z1,x2,z2,d)
	local lx1,lz1,lx2,lz2,lx3,lz3 = AutoTractor.getParallelogram( self, x1, z1, x2, z2, d );

	for i=0,3 do
		if Utils.getDensity(g_currentMission.terrainDetailId, i, lx1,lz1,lx2,lz2,lx3,lz3) ~= 0 then
			return true;
		end;
	end;

	return false;
	
end

------------------------------------------------------------------------
-- applySteering
------------------------------------------------------------------------
function AutoTractor:applySteering(angleFactor,angleMin,angleMax)

	local a  = self.acLastSteeringAngle;
	local j0 = AtGlobal.chainMax+2;
	for j=1,AtGlobal.chainMax+1 do 
		local b = a + angleFactor * self.acChain.nodes[j].angle;
		a = math.min( math.max( b, angleMin ), angleMax );

		if j0 > j and self.acChain.nodes[j].status < AtStatus.steering then
			j0 = j
		end
		if j >= j0 then
			
			--if 0.001 < AtGlobal.newFactor and AtGlobal.newFactor < 0.999 and self.acLastChain ~= nil then
			--	local lc = self.acLastChain;
			--	if lc ~= nil and lc[j] ~= nil then
			--		b = (1-AtGlobal.newFactor) * lc[j] + AtGlobal.newFactor * a;
			--		a = math.min( math.max( b, angleMin ), angleMax );
			--	end
			--end
			
			self.acChain.nodes[j].steering  = a;
			self.acChain.nodes[j].tool      = {};
			self.acChain.nodes[j].radius    = 0;
			if math.abs(a) > 1E-5 then
				self.acChain.nodes[j].radius  = self.acDimensions.wheelBase / math.tan( a );
			end
			self.acChain.nodes[j].status    = AtStatus.steering;
		end
	end 
end

------------------------------------------------------------------------
-- applyRotation
------------------------------------------------------------------------
function AutoTractor:applyRotation(angleFactor,angleMin,angleMax)

	AutoTractor.applySteering(self,angleFactor,angleMin,angleMax);

	local j0 = AtGlobal.chainMax+2;
	for j=1,AtGlobal.chainMax do 
		if j0 > j and self.acChain.nodes[j].status < AtStatus.rotation then
			j0 = j
		end
		if j >= j0 then
			self.acChain.nodes[j].rotation = math.tan( self.acChain.nodes[j].steering ) / self.acDimensions.wheelBase;
			setRotation( self.acChain.nodes[j].index, 0, self.acChain.nodes[j].rotation, 0 );
			self.acChain.nodes[j].status   = AtStatus.rotation;
		end
	end 
end

------------------------------------------------------------------------
-- getChainPoint
------------------------------------------------------------------------
function AutoTractor:getChainPoint( i, lrSwitch, tp )

	local invert = false;
	local dx,dz  = 0,0;
	local aRef   = 0;
	
	if     self.acChain.nodes[i].tool[tp.i]   == nil 
			or self.acChain.nodes[i].tool[tp.i].x == nil 
			or self.acChain.nodes[i].tool[tp.i].z == nil then
			
		if self.acChain.nodes[i].tool[tp.i] == nil then
			self.acChain.nodes[i].tool[tp.i] = {};
		end

		if math.abs( tp.b2 ) > 1E-4 then
			for j=1,i do
				if self.acChain.nodes[j].tool[tp.i].a == nil then
					if math.abs( self.acChain.nodes[j].steering ) < 1E-5 then
						self.acChain.nodes[j].tool[tp.i].a = 0;
					else
						local rr = math.sqrt( math.abs( self.acChain.nodes[j].radius * self.acChain.nodes[j].radius + tp.b1 * tp.b1 - tp.b2 * tp.b2 ) );
						local aa = math.atan( tp.b2 / rr ) + math.atan( tp.b1 / math.abs(self.acChain.nodes[j].radius) );
						if self.acChain.nodes[j].radius > 0 then aa = -aa end
						self.acChain.nodes[j].tool[tp.i].a = aa;
					end
				end
			end
		end
		
		if lrSwitch ~= nil and tp.b1 < 0 then
			if math.abs( tp.b2 ) > 1E-3 then
				local a=0;
				for j=1,AtGlobal.offtracking do
					jj = i - j;
					if jj < 1 then
						a = a + tp.angle;
					else
						a = a + self.acChain.nodes[jj].tool[tp.i].a;
					end
				end
				a = a / AtGlobal.offtracking;

				setRotation(    self.acChain.tNode[1], 0, -a, 0 );
				setTranslation( self.acChain.tNode[1], 0, 0, tp.b1 );
				setTranslation( self.acChain.tNode[2], tp.x, 0, tp.z-tp.b1 );
				local xt,_,zt = AutoTractor.getRelativeTranslation( self.acChain.tNode[0], self.acChain.tNode[2] );
			
				dx = tp.x - xt;
				dz = zt - tp.z;
			else
				if i == 1 then
					aRef = self.acLastSteeringAngle;
				else
					aRef = self.acChain.nodes[i-1].steering;
				end
			
				if math.abs(aRef) > 1E-4 then
					if ( lrSwitch and aRef > 0 ) or ( ( not lrSwitch ) and aRef < 0 ) then
						invert = false;
					else
						invert = true;
					end
				
					local r  = self.acDimensions.wheelBase / math.tan( math.abs(aRef) );
					local r1 = math.sqrt( r*r + tp.b1*tp.b1 );
				
					if invert then
						r = r + tp.x0;
					else
						r = r - tp.x0;
					end			
					dx = math.sqrt( r*r + tp.b1*tp.b1 ) - r;		
				end
				
				if invert then dx = -dx end
			end	
		end
		
		self.acChain.nodes[i].status = AtStatus.position;
		self.acChain.nodes[i].tool[tp.i].x = tp.x - dx;
		self.acChain.nodes[i].tool[tp.i].z = tp.z + dz;
	end
	
	return self.acChain.nodes[i].tool[tp.i].x, self.acChain.nodes[i].tool[tp.i].z;
	
end

------------------------------------------------------------------------
-- getChainBorder
------------------------------------------------------------------------
function AutoTractor:getChainBorder( i1, i2, offsetOutside, lrSwitch, toolParam, fieldCheck )
	local b,t    = 0,0;
	local i      = i1;
	local fNum   = math.floor( 0.5 + toolParam.width );
	local fStep  = toolParam.width / fNum;
	local fStart = toolParam.width
	if offsetOutside < 0 then
		fStep  = -fStep;
	else
		fStart = -fStart;
	end
	local fRes   = true;

	if 1 <= i and i <= AtGlobal.chainMax then
		local x,z     = AutoTractor.getChainPoint( self, i, lrSwitch, toolParam );
		local xp,_,zp = localToWorld( self.acChain.nodes[i].index,   x, 0, z );
		while i<=i2 and i<=AtGlobal.chainMax do				
			x,z = AutoTractor.getChainPoint( self, i+1, lrSwitch, toolParam );
			local xc,_,zc = localToWorld( self.acChain.nodes[i+1].index, x, 0, z );
			
			if fieldCheck then
				fRes = AutoTractor.isField( self, xp,zp,xc,zc, fStart );
			end
			
			if fRes then
				local bi, ti  = AutoTractor.getFruitArea( self, xp, zp, xc, zc, offsetOutside, self.acTools[toolParam.i] )			
				b = b + bi;
				t = t + ti;
			end
			
			i = i + 1;
			xp = xc;
			zp = zc;
		end
	end
	
	return b, t;
end

------------------------------------------------------------------------
-- getAllChainBorders
------------------------------------------------------------------------
function AutoTractor:getAllChainBorders( toolParams, i1, i2, offsetOutside, lrSwitch, fieldCheck )
	local border, total = 0,0;
	for _,tp in pairs(toolParams) do				
		border, total  = AutoTractor.getChainBorder( self, i1, i2, offsetOutside, lrSwitch, tp, true );					
	end
	
	return border, total;
end

------------------------------------------------------------------------
-- getSteeringAngleForTool
------------------------------------------------------------------------
function AutoTractor:getSteeringParameterOfTool( toolIndex, maxAngle, offsetOutside, lrSwitch )
	
	local tool = self.acTools[toolIndex];
	local angleMax, angleMin;
	local xl = -999;
	local xr = 999;
	local il, ir, i1, zl, zr;
	
	for i=1,table.getn(tool.marker) do
		local xxx,_,zzz = AutoTractor.getRelativeTranslation( tool.steeringAxleNode, tool.marker[i] );
		xxx = xxx - tool.xOffset;
		zzz = zzz - tool.zOffset;
		if tool.invert then xxx = -xxx; zzz = -zzz end
		if xl < xxx then xl = xxx; zl = zzz; il = i end
		if xr > xxx then xr = xxx; zr = zzz; ir = i end
	end
	
	local width  = xl - xr;
	local scale  = Utils.getNoNil( self.aiTurnWidthScale, 0.9 );
	local diff   = Utils.getNoNil( self.aiTurnWidthMaxDifference, 0.5 );
	local offset = 0.5 * ( width - math.max(width * scale, width - diff) ) - self.acParameters.widthOffset;

	width = width - offset - offset;

	if lrSwitch	then
-- left	
		x0 = xl - offset;
		z0 = zl;
		i1 = il;
	else
-- right	
		x0 = xr + offset;
		z0 = zr;
		i1 = ir;
	end
	
--	local x1,z1=0,0;		
--	local y;
--	xl,y,zl = AutoTractor.getRelativeTranslation( self.acChain.refNode, tool.marker[il] );
--	xr,y,zr = AutoTractor.getRelativeTranslation( self.acChain.refNode, tool.marker[ir] );
--
--	offset = 0.5 * ( xl-xr - math.max((xl-xr) * scale, xl-xr - diff) ) - self.acParameters.widthOffset;
--	
--	if lrSwitch	then
---- left	
--		x1 = xl - offset;
--		z1 = zl;
--	else
---- right	
--		x1 = xr + offset;
--		z1 = zr;
--	end
	
	local x1,_,z1 = AutoTractor.getRelativeTranslation( self.acChain.refNode, tool.refNode );
	
	--print(string.format("x0=%f z0=%f x1=%f z1=%f width=%f offset=%f xo=%f zo=%f",x0,z0,x1,z1,width,offset,tool.xOffset,tool.zOffset))
	
	x1 = x1 + x0;
	z1 = z1 + z0;
	
	local b1,b2 = z1, 0;

	local r1 = math.sqrt( x1*x1 + b1*b1 );		
	r1       = ( 1 + AtGlobal.minMidDist ) * ( r1 + math.max( 0, -b1 ) );
	local a1 = math.atan( self.acDimensions.wheelBase / r1 );
	local a2 = maxAngle; --math.atan( 2 * self.acDimensions.wheelBase / width );
	if lrSwitch then
		angleMin = -math.min(a2,maxAngle);
		angleMax = math.min(a1,maxAngle);
	else
		angleMin = -math.min(a1,maxAngle);
		angleMax = math.min(a2,maxAngle);
	end
	
	local toolAngle = 0;
	
	if b1 < 0 then
		if tool.aiForceTurnNoBackward then
			local _,_,z4  = AutoTractor.getRelativeTranslation( self.acChain.refNode, tool.refNode );
			b1 = z4; -- + 0.4;
			if tool.b2 == nil then
				local x3,_,z3 = AutoTractor.getRelativeTranslation( tool.steeringAxleNode ,tool.marker[i1] );
				if tool.invert then x3 = -x3; z3=-z3 end				
				local _,_,z5  = AutoTractor.getRelativeTranslation( tool.marker[i1] ,tool.aiBackMarker );
				b2 = z3 - tool.zOffset + 0.5 * z5;
			else
				b2 = tool.b2
			end
			
			toolAngle = AutoTractor.getRelativeYRotation( self.steeringAxleNode, tool.steeringAxleNode );
			if tool.invert then
				if toolAngle < 0 then
					toolAngle = toolAngle + math.pi
				else
					toolAngle = toolAngle - math.pi
				end
			end

			--local rsqr = b2 * b2 - b1 * b1;
			--if rsqr > 0 then
			--	r1 = math.sqrt( rsqr );
			--	a1 = math.atan( self.acDimensions.wheelBase / r1 );
			--	angleMin = -math.min(a1,maxAngle);
			--	angleMax = math.min(a1,maxAngle);
			--end
			
			z1 = 0.5 * ( b1 + z1 );
		else
			if math.abs( self.acLastSteeringAngle ) > 1E-4 then
				local rr, xx, bb;
				if self.acLastSteeringAngle > 0 then
					xx = x1;
				else
					xx = -x1;
				end				
				rr = self.acDimensions.wheelBase / math.tan( math.abs( self.acLastSteeringAngle ) );
				if 0 < xx and xx < rr then
					bb = math.atan( -z1 / ( rr - xx ) );
				else
					bb = math.asin( -z1 / rr );
				end
				xx = rr * ( 1 - math.cos( bb ) );
				if self.acLastSteeringAngle > 0 then
					x1 = x1 + xx;
				else
					x1 = x1 - xx;
				end
				z1 = z1 + rr * math.sin( bb ); 
			else
				z1 = 0;
			end
		end
	end
	
	local toolParam = {}
	toolParam.i        = toolIndex;
	toolParam.x        = x1;
	toolParam.z        = z1;
	toolParam.minAngle = angleMin;
	toolParam.maxAngle = angleMax;
	toolParam.b1       = b1;
	toolParam.b2       = b2;
	toolParam.offset   = offset;
	toolParam.width    = width;
	toolParam.x0       = x0;
	toolParam.angle    = toolAngle;
	
	return toolParam;
end

------------------------------------------------------------------------
-- setChainStatus
------------------------------------------------------------------------
function AutoTractor:setChainStatus( startIndex, newStatus )
	local i = math.max(startIndex,1);
  while i <= AtGlobal.chainMax + 1 do
		if self.acChain.nodes[i].status > newStatus then
			self.acChain.nodes[i].status = newStatus
		end
		i = i + 1;
	end
end

------------------------------------------------------------------------
-- processChain
------------------------------------------------------------------------
function AutoTractor:processChain( toolParams, lrSwitch, angleFactor, offsetOutside, detectedBefore )
	
	local indexMax  = AtGlobal.chainMax; --math.min( math.max( math.ceil( ( self.acDimensions.wheelBase - z1 + 5 ) ), 3 ), AtGlobal.chainMax );				
	local detected  = false;

	if toolParams == nil or table.getn( toolParams ) < 1 then
		return false, 0;
	end
	
	local angleMin,angleMax,width,dist = nil,nil,nil,nil;
	for _,tp in pairs(toolParams) do				
		if angleMin == nil or angleMin > tp.minAngle then
			angleMin = tp.minAngle
		end
		if angleMax == nil or angleMax < tp.maxAngle then
			angleMax = tp.maxAngle
		end
		if width == nil or width > tp.width then
			width = tp.width;
		end
		if dist == nil or dist > tp.z then
			dist = tp.z;
		end
	end

	AutoTractor.applyRotation(self,angleFactor,angleMin,angleMax);		
	
	local border, total = 0,0;

	local indexMin = 1; --math.min( math.max( math.floor( 0.5 - dist / AtGlobal.chainLen ), 1 ), 4 );
	local i = 1;
	local indexDetected = math.floor( 0.5 + AtGlobal.detectedAt / AtGlobal.chainLen );

	if indexMin > 1 then
		for i=1,indexMin do
			if math.abs(self.acChain.nodes[i].angle)>1E-3 then
				AutoTractor.setChainStatus( self, i, AtStatus.initial );
				self.acChain.nodes[i].angle = 0;
			end
		end
	end
			
	for i=indexMin,indexMax do 
		border, total  = AutoTractor.getAllChainBorders( self, toolParams, i, indexMax, offsetOutside, lrSwitch, true );
		while border <= 0 and self.acChain.nodes[i].angle > -AtGlobal.angleMax do				
			doit = false;
			
			local old1 = self.acChain.nodes[i].angle;		
			local old2 = border;
			local old3 = self.acChain.nodes[i].steering;
			self.acChain.nodes[i].angle = math.min( math.max( self.acChain.nodes[i].angle -1, -AtGlobal.angleMax ), AtGlobal.angleMax );
				
			if old1 ~= self.acChain.nodes[i].angle then 
				AutoTractor.setChainStatus( self, i, AtStatus.initial );
				AutoTractor.applyRotation(self,angleFactor,angleMin,angleMax);				
				border, total  = AutoTractor.getAllChainBorders( self, toolParams, i, indexMax, offsetOutside, lrSwitch, true );
				if border > 0 then
					if not detected and i <= indexDetected then
						detected = true;
					end
					self.acChain.nodes[i].angle = old1
					AutoTractor.setChainStatus( self, i, AtStatus.initial );
					AutoTractor.applyRotation( self,angleFactor,angleMin,angleMax );			
					border, total  = AutoTractor.getAllChainBorders( self, toolParams, i, indexMax, offsetOutside, lrSwitch, true );
					if border > 0 then
						print(string.format("Error, border at index %i: %i, %i, %f, %f",i,border,old2,old3,self.acChain.nodes[i].steering));
					end					
					break;
				end
			end
		end
	end
	
	if detected then
-- we found fruits. now check if we found the border as well
		border, total  = AutoTractor.getAllChainBorders( self, toolParams, indexMin, indexMax, offsetOutside, lrSwitch, true );
		if border > 0 then
			detected = false;
		end
	elseif not detectedBefore then
		AutoTractor.setChainStatus( self, i, AtStatus.initial );
		a = self.acLastSteeringAngle;
		for j=1,AtGlobal.chainMax+1 do 
			self.acChain.nodes[j].angle = math.min( math.max( -a/angleFactor , -AtGlobal.angleMax ), AtGlobal.angleMax );
			local b = a + self.acChain.nodes[j].angle;
			a = math.min( math.max( b, angleMin ), angleMax );
		end 
		AutoTractor.applyRotation( self,angleFactor,angleMin,angleMax );			
	end
	
	if self.acDebug then
		self.acPoints = {};
		for _,tp in pairs(toolParams) do				
			local points ={};
			
			AutoTractor.applyRotation( self,angleFactor,angleMin,angleMax );			
			for i=indexMin,indexMax+1 do
				local node = self.acChain.nodes[i];
				local p = {};
				
				local x, z = AutoTractor.getChainPoint( self, i, lrSwitch, tp )
				p.x,p.y,p.z = localToWorld( node.index ,x, 1, z );
				points[i] = p;
			end			
			self.acPoints[tp.i] = points;		
		end
	end
	
	local angle = math.min( math.max( self.acLastSteeringAngle + angleFactor * self.acChain.nodes[indexMin].angle, angleMin ), angleMax );
	
	if AtGlobal.average == 4 then
		angle = 4 * angle;
		for i=1,3 do
			angle = angle + (4-i) * math.min( math.max( self.acLastSteeringAngle + angleFactor * self.acChain.nodes[indexMin+i].angle, angleMin ), angleMax );	
		end
		angle = angle * 0.1;
	elseif AtGlobal.average > 1 then
		local count = AtGlobal.average;
		angle = angle * count;
		for i=1,AtGlobal.average-1 do
			local w = (AtGlobal.average-i);
			count = count + w;
			angle = angle + w * math.min( math.max( self.acLastSteeringAngle + angleFactor * self.acChain.nodes[indexMin+i].angle, angleMin ), angleMax );	
		end
		angle = angle / count;
	end
	
	lc = {}; 
	for i=1,AtGlobal.chainMax do
		lc[i] = self.acChain.nodes[i].steering;
	end
	self.acLastChain = lc;
	
	return detected, angle, border;
end

------------------------------------------------------------------------
-- autoSteer
------------------------------------------------------------------------
function AutoTractor:autoSteer(dt)

	if self.acDimensions == nil then
		AutoTractor.calculateDimensions(self)
	end
	
	if self.acChain == nil then	
		AutoTractor.initChain(self)
	end
	
	if self.acTools == nil or table.getn( self.acTools ) < 1 then
		self.acTurnStage = 0;
		return;
	end

	local angle    = self.acDimensions.maxLookingAngle;	
	local angleMax = self.acDimensions.maxLookingAngle;
	local detected = false;
	local angleFactor;
	local offsetOutside;
	if self.acParameters.leftAreaActive	then
		angleFactor   = math.rad( AtGlobal.angleStep * AtGlobal.chainLen / AtGlobal.angleMax );			
		offsetOutside = 1
	else
		angleFactor   =-math.rad( AtGlobal.angleStep * AtGlobal.chainLen / AtGlobal.angleMax );
		offsetOutside =-1
	end 
	
--==============================================================		
	self.acPoints = {};
		
	self.acLastSteeringAngle = nil;
	if self.acLastSteeringAngle == nil then
		self.acLastSteeringAngle = 0;		

		if      self.articulatedAxis ~= nil 
				and self.articulatedAxis.componentJoint ~= nil
				and self.articulatedAxis.componentJoint.jointNode ~= nil 
				and self.articulatedAxis.rotMax then
			self.acLastSteeringAngle = math.min( math.max( self.lastRotatedTime * self.articulatedAxis.rotSpeed, self.articulatedAxis.rotMin ), self.articulatedAxis.rotMax );
		else
			for _,wheel in pairs(self.wheels) do
				if math.abs(wheel.rotSpeed) > 1E-3 then
					if math.abs( wheel.steeringAngle ) > math.abs( self.acLastSteeringAngle ) then
						if wheel.rotSpeed > 0 then
							self.acLastSteeringAngle = wheel.steeringAngle
						else
							self.acLastSteeringAngle = -wheel.steeringAngle
						end
					end
				end
			end
		end	
		
		self.acLastPosition = nil;
		self.acLastChain    = nil;
	end
				
	local px,_,pz	= getWorldTranslation( self.acChain.refNode );
	
	if self.acLastPosition ~= nil then
	end
	
	self.acLastPosition = { x = px, z = pz };
		
	AutoTractor.setChainStatus( self, 1, AtStatus.initial );
	--a = self.acLastSteeringAngle;
	--for j=0,AtGlobal.chainMax do 
	--	self.acChain.nodes[j+1].angle = math.min( math.max( -a/angleFactor , -AtGlobal.angleMax ), AtGlobal.angleMax );
	--	a = a + self.acChain.nodes[j+1].angle;
	--end 
	for j=0,AtGlobal.chainMax do 
		self.acChain.nodes[j+1].angle = AtGlobal.angleMax;
	end 
	
	local db = false;
	if self.acTurnStage == 99 then db = true end
	
	local toolParams = {};
	for i=1,table.getn(self.acTools) do
		local tp = AutoTractor.getSteeringParameterOfTool( self, i, angleMax, offsetOutside, self.acParameters.leftAreaActive );
		toolParams[#toolParams+1] = tp;
	end
	
	detected, angle = AutoTractor.processChain( self, toolParams, self.acParameters.leftAreaActive, angleFactor, offsetOutside, db );					
	self.acLastSteeringAngle = angle;
	
--==============================================================						

	
	if detected then
		if self.acTurnStage ~= 99 then
			self.acTurnStage = 99
			AutoTractor.saveDirection( self, false )
		end
		AutoTractor.saveDirection( self, true );
		self.turnTimer = self.acDeltaTimeoutRun
	else
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
		local noReverseIndex = 0;
		for i=1,table.getn(self.acTools) do
			if self.acTools[i].aiForceTurnNoBackward then
				noReverseIndex = i;
			end
		end
		
		if noReverseIndex > 0 then
			local toolAngle = AutoTractor.getRelativeYRotation( self.steeringAxleNode, self.acTools[noReverseIndex].steeringAxleNode );
			if self.acTools[noReverseIndex].invert then
				if toolAngle < 0 then
					toolAngle = toolAngle + math.pi
				else
					toolAngle = toolAngle - math.pi
				end
			end
			if AtGlobal.reverseDir == 0 then
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
	
	if self.isEntered then
		if     angle == 0 then
			targetRotTime = 0
		elseif angle  > 0 then
			targetRotTime = self.maxRotTime * math.min( angle / self.acDimensions.maxSteeringAngle, 1)
		else
			targetRotTime = self.minRotTime * math.min(-angle / self.acDimensions.maxSteeringAngle, 1)
		end
		
		if AtGlobal.directSteer ~= nil and AtGlobal.directSteer > 0 then
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
-- initChain
------------------------------------------------------------------------
function AutoTractor:initChain()

	AutoTractor.calculateDimensions(self);	

	self.acChain = {};
	self.acChain.zOffset = self.acDimensions.zOffset;
	self.acChain.refNode = createTransformGroup( "acChainRef" );
	link( self.acRefNode, self.acChain.refNode );
	setTranslation( self.acChain.refNode, 0,0, self.acDimensions.zOffset );
	
	local node    = {};
	node.index    = createTransformGroup( "acChain0" );
	node.status   = 0;
	node.angle    = 0;
	node.steering = 0;
	node.rotation = 0;
	link( self.acChain.refNode, node.index );

	local nodes = {};
	nodes[1] = node;
	
	for i=1,AtGlobal.chainMax do
		local parent   = nodes[i];
		local text     = string.format("acChain%i",i)
		local node2    = {};
		node2.index    = createTransformGroup( text );
		node2.status   = 0;
		node2.angle    = 0;
		node2.steering = 0;
		node2.rotation = 0;
		
		link( parent.index, node2.index );
		setTranslation( node2.index, 0,0,AtGlobal.chainLen + i * AtGlobal.chainLenInc );
		
		nodes[#nodes+1] = node2;
	end
	
	self.acChain.nodes = nodes;

	self.acChain.tNode = {};
	
	self.acChain.tNode[0] = createTransformGroup( "acTJoin" );
	self.acChain.tNode[1] = createTransformGroup( "acTJoin1" );
	self.acChain.tNode[2] = createTransformGroup( "acTJoin1" );
	link(self.acChain.tNode[0],self.acChain.tNode[1]);
	link(self.acChain.tNode[1],self.acChain.tNode[2]);
	

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
		self.acDimensions.maxSteeringAngle = math.min( -self.articulatedAxis.rotMin, self.articulatedAxis.rotMax );
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
	
	self.acDimensions.maxLookingAngle = math.min( self.acDimensions.maxSteeringAngle, math.rad(AtGlobal.maxLooking) );
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

	local tool   = {};
	local marker = {};

	if AtResetCounter == nil or AtResetCounter < 1 then
		if object.name ~= nil then print("Adding... "..object.name) else print("Adding something") end
	end
	
	local xo,yo,zo = AutoTractor.getRelativeTranslation( object.steeringAxleNode, reference );
	if AtResetCounter == nil or AtResetCounter < 1 then
		print(string.format("xo=%f zo=%f",xo,zo));
	end
	
	tool.steeringAxleNode              = object.steeringAxleNode;
	tool.xOffset                       = xo;
	tool.zOffset                       = zo;
	tool.isCombine                     = false;
	tool.aiTerrainDetailChannel1       = Utils.getNoNil( object.aiTerrainDetailChannel1      ,-1 );
	tool.aiTerrainDetailChannel2       = Utils.getNoNil( object.aiTerrainDetailChannel2      ,-1 );
	tool.aiTerrainDetailChannel3       = Utils.getNoNil( object.aiTerrainDetailChannel3      ,-1 );
	tool.aiTerrainDetailProhibitedMask = Utils.getNoNil( object.aiTerrainDetailProhibitedMask,0 );
	tool.aiRequiredFruitType           = Utils.getNoNil( object.aiRequiredFruitType          ,FruitUtil.FRUITTYPE_UNKNOWN );
	tool.aiRequiredMinGrowthState      = Utils.getNoNil( object.aiRequiredMinGrowthState     ,0 );
	tool.aiRequiredMaxGrowthState      = Utils.getNoNil( object.aiRequiredMaxGrowthState     ,0 );
	tool.aiProhibitedFruitType         = Utils.getNoNil( object.aiProhibitedFruitType        ,FruitUtil.FRUITTYPE_UNKNOWN );
	tool.aiProhibitedMinGrowthState    = Utils.getNoNil( object.aiProhibitedMinGrowthState   ,0 );
	tool.aiProhibitedMaxGrowthState    = Utils.getNoNil( object.aiProhibitedMaxGrowthState   ,0 );
	tool.aiForceTurnNoBackward         = Utils.getNoNil( object.aiForceTurnNoBackward        ,false );
	tool.b2                            = nil;
	tool.invert                        = false;
	
	if not SpecializationUtil.hasSpecialization(Combine, object.specializations) and object.aiLeftMarker ~= nil and object.aiRightMarker ~= nil then
-- tool with AI support		
		if AtResetCounter == nil or AtResetCounter < 1 then
			print("object has AI support");
		end
		
		if object.aiLeftMarker ~= nil then
			marker[#marker+1] = object.aiLeftMarker
		end
		
		if object.aiRightMarker ~= nil then
			marker[#marker+1] = object.aiRightMarker
		end
		
		tool.aiBackMarker = object.aiBackMarker;				
	else
		local areas = nil;

		if object.lengthOffset ~= nil and object.lengthOffset < 0 then
		-- wrong rotation ???
			tool.invert = true;
		end
		
--		if     object.attacherJoint.jointType  == Vehicle.JOINTTYPE_TRAILERLOW
--				or object.attacherJoint.jointType  == Vehicle.JOINTTYPE_TRAILER then
--			tool.aiForceTurnNoBackward = true;
--		end
	
		if     SpecializationUtil.hasSpecialization(Sprayer, object.specializations) then
		-- sprayer	
			if AtResetCounter == nil or AtResetCounter < 1 then
				print("object is sprayer");
			end
			
			tool.aiTerrainDetailChannel1       = g_currentMission.cultivatorChannel;
			tool.aiTerrainDetailChannel2       = g_currentMission.ploughChannel;
			tool.aiTerrainDetailChannel3       = g_currentMission.sowingChannel;
			tool.aiTerrainDetailProhibitedMask = 2 ^ g_currentMission.sprayChannel;
		elseif SpecializationUtil.hasSpecialization(Combine, object.specializations) then
		-- Combine
			if AtResetCounter == nil or AtResetCounter < 1 then
				print("object is combine");
			end
			
			tool.isCombine = true;
			tool.obj       = object;
			
			if object.aiLeftMarker ~= nil and object.aiRightMarker ~= nil then
				local tempArea = {};
				tempArea.start  = object.aiLeftMarker;
				tempArea.width  = object.aiRightMarker;
				tempArea.height = object.aiBackMarker;		
				areas    = {};
				areas[1] = tempArea;
			end
		elseif SpecializationUtil.hasSpecialization(FruitPreparer, object.specializations) then
		-- FruitPreparer
			if AtResetCounter == nil or AtResetCounter < 1 then
				print("object is fruit preparer");
			end
			
			local fruitDesc = FruitUtil.fruitIndexToDesc[object.fruitPreparerFruitType];
			if fruitDesc == nil then return end
			
			areas = object.fruitPreparerAreas;
			
			tool.aiRequiredFruitType        = object.fruitPreparerFruitType;
      tool.aiRequiredMinGrowthState   = fruitDesc.minPreparingGrowthState;
      tool.aiRequiredMaxGrowthState   = fruitDesc.maxPreparingGrowthState; 
		else
			return;
		end
		
		if areas == nil then areas = object.cuttingAreas; end
		if areas == nil then return end;		

		for _, area in pairs(areas) do
			marker[#marker+1] = area.start;
			marker[#marker+1] = area.width;
			if tool.aiBackMarker == nil then
				tool.aiBackMarker = area.height;
			end
		end					
	end
	
	if AtResetCounter == nil or AtResetCounter < 1 then
		if #marker < 1 then print("no marker found") return end
	end

	if object.aiBackMarker == nil then
		tool.aiBackMarker = marker[1];
	end
	
	if reference == nil then
		tool.refNode = self.acRefNode;
	else
		tool.refNode = reference;
	end
		
	tool.marker = marker;
	
	if object.wheels ~= nil then
		local wna,wza=0,0;
		for _,wheel in pairs(object.wheels) do
			local _,_,wz = AutoTractor.getRelativeTranslation(tool.steeringAxleNode,wheel.driveNode);
			wza = wza + wz;
			wna = wna + 1;		
		end
		if wna > 0 then
			tool.b2 = wza / wna - tool.zOffset;
			if tool.invert then tool.b2 = -tool.b2 end
			print(string.format("wna=%i wza=%f b2=%f ofs=%f",wna,wza,tool.b2,tool.zOffset))
		end
	end

	if self.acTools == nil then
		self.acTools ={};
		self.acTools[1] = tool;
	else
		local i = table.getn(self.acTools);
		self.acTools[i+1] = tool;
	end
	
	local xl = -999;
	local xr = 999;
	for i=1,#marker do
		local x = AutoTractor.getRelativeTranslation(tool.steeringAxleNode,marker[i]);
		if tool.invert then x = -x end
		if xl < x then xl = x end
		if xr > x then xr = x end
	end
	
	local d = 0.5 * ( xl-xr ); 
	xl = xl - tool.xOffset;
	xr = xr - tool.xOffset;
	
	if self.acDimensions.distance < d then
		self.acDimensions.distance = d;
	end	
	
	if AtResetCounter == nil or AtResetCounter < 1 then
		print(string.format("...added, left = %0.2f, right = %0.2f, distance = %0.2f",xl,xr,d+d));
	end
end

------------------------------------------------------------------------
-- calculateDistances
------------------------------------------------------------------------
function AutoTractor:calculateDistances()

	self.acDimensions.distance = 99;
	
	self.acTools = nil;
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
	self.acDimensions.maxLookingAngle = math.min( math.rad(AtGlobal.maxLooking) ,self.acDimensions.maxSteeringAngle);
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
-- getRelativeYRotation
------------------------------------------------------------------------
function AutoTractor.getRelativeYRotation(root,node)
	local x, y, z = worldDirectionToLocal(node, localDirectionToWorld(root, 0, 0, 1))
	local dot = z
	dot = dot / Utils.vector2Length(x, z)
	local angle = math.acos(dot)
	if x < 0 then
		angle = -angle
	end
	return angle
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
function AutoTractor:getParallelogram( xs, zs, xh, zh, diff )
	local xw, zw, xd, zd;
	
	xd = zh - zs;
	zd = xs - xh;
	
	local l = math.sqrt( xd*xd + zd*zd );

	if l > 0.999 and l < 1.001 then
		xw = xs + diff * xd;
		zw = zs + diff * zd;
	elseif l > 1E-3 then
		xw = xs + diff * xd / l;
		zw = zs + diff * zd / l;
	else
		xw = xs;
		zw = zs;
	end
	
	return xs, zs, xw, zw, xh, zh;
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


addConsoleCommand("acReset", "Reset global AutoTractor variables to defaults.", "acReset", AutoTractor);
function AutoTractor:acReset()
	AtGlobalsReset();
	AtResetCounter = AtResetCounter + 1;
	for name,value in pairs(AtGlobal) do
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
	for n,o in pairs(AtGlobal) do
		if n == name then
			found = true;
			old   = o;
			break;
		end
	end
	
  if found then
		if value == nil or old == new then
			print(tostring(AtGlobal[name]));
		else
			AtGlobal[name]=value;
			print("Old value: "..tostring(old).."; new value: "..tostring(value));
			AtResetCounter = AtResetCounter + 1;
		end
	else
		print("Usage: acSet <name> <value>");
		print("Possible names are:");
		
		for n,old in pairs(AtGlobal) do
			print("  " .. n);
		end
	end
	
end
--
-- AITractor
-- Specialization for ai tractors
--
-- @author  Stefan Geiger
-- @date  10/01/09
--
-- Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.

AITractor = {}
source("dataS/scripts/vehicles/specializations/AITractorSetStartedEvent.lua");
source("dataS/scripts/vehicles/specializations/AISetImplementsMoveDownEvent.lua");
source("dataS/scripts/vehicles/specializations/AITractorRotateLeftEvent.lua");
source("dataS/scripts/vehicles/specializations/AITractorRotateRightEvent.lua");


function AITractor.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Hirable, specializations) and SpecializationUtil.hasSpecialization(Steerable, specializations);
end;

function AITractor:load(xmlFile)

    self.startAITractor = SpecializationUtil.callSpecializationsFunction("startAITractor");
    self.stopAITractor = SpecializationUtil.callSpecializationsFunction("stopAITractor");
    self.setAIImplementsMoveDown = SpecializationUtil.callSpecializationsFunction("setAIImplementsMoveDown");
    self.onTrafficCollisionTrigger = AITractor.onTrafficCollisionTrigger;
    self.canStartAITractor = AITractor.canStartAITractor;
    self.getIsAITractorAllowed = AITractor.getIsAITractorAllowed;

    self.isAITractorActivated = false;
    self.aiTractorDirectionNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTractorDirectionNode#index"));
    if self.aiTractorDirectionNode == nil then
        self.aiTractorDirectionNode = self.components[1].node;
    end;

    self.aiTractorLookAheadDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTractorLookAheadDistance"), 10);
    self.turnTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnTimeout"), 800);
    self.turnTimeoutLong = self.turnTimeout*10;
    self.turnTimer = self.turnTimeoutLong;
    --self.frontMarkerDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.frontMarkerDistance"), 1.5);
    self.frontMarkerDistanceScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.frontMarkerDistanceScale"), 1.1);
    self.lastFrontMarkerDistance = 0;
    self.turnTargetMoveBack = 7;
    self.turnEndDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnEndDistance"), 4);
    self.turnEndBackDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnEndBackDistance"), 0.6)+self.turnTargetMoveBack; ---self.frontMarkerDistance;

    self.aiToolExtraTargetMoveBack = 0;

    self.aiTractorTurnRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTractorTurnRadius"), 5);
    self.aiTurnNoBackward = false;


    self.waitForTurnTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.waitForTurnTime"), 1600);
    self.waitForTurnTime = 0;


    self.turnStage2Timeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnForwardTimeout"), 20000);
    self.turnStage3Timeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnBackwardTimeout"), 20000);
    self.turnStage6Timeout = 3000;


    self.sideWatchDirOffset = -8;
    self.sideWatchDirSize = 7;

    self.turnStage = 0;



    self.aiTrafficCollisionTrigger = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTrafficCollisionTrigger#index"));

    self.aiTurnWidthScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTurnWidthScale#value"), 0.9);
    self.aiTurnWidthMaxDifference = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTurnWidthMaxDifference#value"), 0.5); -- do at most a 0.5m overlap


    self.trafficCollisionIgnoreList = {};
    for k,v in pairs(self.components) do
        self.trafficCollisionIgnoreList[v.node] = true;
    end;
    self.numCollidingVehicles = {};

    self.aiToolsDirty = true;

    self.dtSum = 0;

    --self.debugDirection = loadI3DFile("data/debugDirection.i3d");
    --link(self.aiTractorDirectionNode, self.debugDirection);
    --self.debugPosition = loadI3DFile("data/debugPosition.i3d");
    --link(getRootNode(), self.debugPosition);

end;

function AITractor:delete()
    --delete(self.debugPosition);
    self:stopAITractor(true);
end;

function AITractor:readStream(streamId, connection)
    local isAITractorActivated = streamReadBool(streamId);
    if isAITractorActivated then
        self:startAITractor(true);
    else
        self:stopAITractor(true);
    end;
end;

function AITractor:writeStream(streamId, connection)
    streamWriteBool(streamId, self.isAITractorActivated);
end;

function AITractor:mouseEvent(posX, posY, isDown, isUp, button)
end;

function AITractor:keyEvent(unicode, sym, modifier, isDown)
end;

function AITractor:update(dt)
    if self:getIsActiveForInput(false) then
        if InputBinding.hasEvent(InputBinding.TOGGLE_AI) then
            if g_currentMission:getHasPermission("hireAI") then
                if self.isAITractorActivated then
                    self:stopAITractor();
                else
                    if self:canStartAITractor() then
                        self:startAITractor();
                    end;
                end;
            end
        end;
    end;

    if self.aiToolsDirty then
        AITractor.updateToolsInfo(self);
    end;

end;

function AITractor:updateTick(dt)
    if self.isServer then
        if self.isAITractorActivated then
            if self.isBroken then
                self:stopAITractor();
            end;
            self.dtSum = self.dtSum + dt;
            if self.dtSum &gt; 20 then
                AITractor.updateAIMovement(self, self.dtSum);
                self.dtSum = 0;
            end;
            --local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
            --setTranslation(self.debugPosition, self.aiTractorTargetX, y, self.aiTractorTargetZ);
            --AITractor.updateAIMovement(self, dt);
        else
            self.dtSum = 0;
        end;
    end;
end;

function AITractor:draw()
    if g_currentMission:getHasPermission("hireAI") then
        if self.isAITractorActivated then
            g_currentMission:addHelpButtonText(g_i18n:getText("DismissEmployee"), InputBinding.TOGGLE_AI);
        else
            if self:canStartAITractor() then
                g_currentMission:addHelpButtonText(g_i18n:getText("HireEmployee"), InputBinding.TOGGLE_AI);
            end;
        end;
    end
end;

function AITractor:startAITractor(noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AITractorSetStartedEvent:new(self, true), nil, nil, self);
        else
            g_client:getServerConnection():sendEvent(AITractorSetStartedEvent:new(self, true));
        end;
    end;
    self:hire();
    if not self.isAITractorActivated then

        self.isAITractorActivated = true;

        if self.isServer then
            self.turnTimer = self.turnTimeoutLong;
            self.turnStage = 0;

            local dx,_,dz = localDirectionToWorld(self.aiTractorDirectionNode, 0, 0, 1);

            if g_currentMission.snapAIDirection then
                local snapAngle = self:getDirectionSnapAngle();
                snapAngle = math.max(snapAngle, math.pi/(g_currentMission.terrainDetailAngleMaxValue+1));

                local angleRad = Utils.getYRotationFromDirection(dx, dz)
                angleRad = math.floor(angleRad / snapAngle + 0.5) * snapAngle;

                self.aiTractorDirectionX, self.aiTractorDirectionZ = Utils.getDirectionFromYRotation(angleRad);
            else
                local length = Utils.vector2Length(dx,dz);
                self.aiTractorDirectionX = dx/length;
                self.aiTractorDirectionZ = dz/length;
            end


            local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
            self.aiTractorTargetX = x;
            self.aiTractorTargetZ = z;

            self.aiTractorTurnLeft = nil;

            AITractor.addCollisionTrigger(self, self);
        end;

        AITractor.updateToolsInfo(self);
        for _,implement in pairs(self.attachedImplements) do
            if implement.object ~= nil then
                if implement.object.needsLowering and implement.object.aiNeedsLowering then
                    self:setJointMoveDown(implement.jointDescIndex, true, true)
                end;
                implement.object:aiTurnOn();
                if self.isServer then
                    AITractor.addCollisionTrigger(self, implement.object);
                end;
            end
        end;

        self.checkSpeedLimit = false;

    end;
end;

function AITractor:stopAITractor(noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AITractorSetStartedEvent:new(self, false));
        else
            g_client:getServerConnection():sendEvent(AITractorSetStartedEvent:new(self, false));
        end;
    end;
    self:dismiss();
    if self.isAITractorActivated then

        if self.isServer then
            self.motor:setSpeedLevel(0, false);
            self.motor.maxRpmOverride = nil;

            WheelsUtil.updateWheelsPhysics(self, 0, self.lastSpeed, 0, false, self.requiredDriveMode);

            AITractor.removeCollisionTrigger(self, self);
        end;
        self.isAITractorActivated = false;

        self.checkSpeedLimit = true;

        self.aiTractorTurnLeft = nil;

        for _,implement in pairs(self.attachedImplements) do
            if implement.object ~= nil then
                if implement.object.needsLowering and implement.object.aiNeedsLowering then
                    self:setJointMoveDown(implement.jointDescIndex, false, true)
                end;
                AITractor.removeCollisionTrigger(self, implement.object);
                implement.object:aiTurnOff();
            end
        end;

        if not self:getIsActive() then
            self:onLeave();
        end;

    end;
end;

function AITractor:onEnter(isControlling)
end;

function AITractor:onLeave()
end;

function AITractor.updateAIMovement(self, dt)

    if not self.isControlled then
        if g_currentMission.environment.needsLights then
            self:setLightsVisibility(true);
        else
            self:setLightsVisibility(false);
        end;
    end;

    local allowedToDrive = true;

    for _,v in pairs(self.numCollidingVehicles) do
        if v &gt; 0 then
            allowedToDrive = false;
            break;
        end;
    end;
    --if self.turnStage &gt; 0 then
        if self.waitForTurnTime &gt; self.time then
            allowedToDrive = false;
        end;
    --end;
    if not allowedToDrive then
        --local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
        --local lx, lz = 0, 1; --AIVehicleUtil.getDriveDirection(self.aiTractorDirectionNode, self.aiTractorTargetX, y, self.aiTractorTargetZ);
        --AIVehicleUtil.driveInDirection(self, dt, 30, 0, 0, 28, false, moveForwards, lx, lz)
        AIVehicleUtil.driveInDirection(self, dt, 30, 0, 0, 28, false, moveForwards, nil, nil)
        return;
    end;

    local speedLevel = 1;

    if not self:getIsAITractorAllowed() then
        self:stopAITractor();
        return;
    end;


    -- Seeding:
    --      Required: Cultivated, Ploughed
    -- Direct Planting:
    --      Required: Seeded, Cultivated, Ploughed without Fruit of current type
    -- Forage Wagon:
    --      Required: Windrow of current type
    -- Spray:
    --      Required: Seeded, Cultivated, Ploughed without Sprayed
    -- Mower:
    --      Required: Fruit of type grass

    local leftMarker = self.aiCurrentLeftMarker;
    local rightMarker = self.aiCurrentRightMarker;
    local backMarker = self.aiCurrentBackMarker;
    local groundInfoObject = self.aiCurrentGroundInfoObject;

    local terrainDetailRequiredMask = 0;
    if groundInfoObject.aiTerrainDetailChannel1 &gt;= 0 then
        terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel1);
        if groundInfoObject.aiTerrainDetailChannel2 &gt;= 0 then
            terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel2);
            if groundInfoObject.aiTerrainDetailChannel3 &gt;= 0 then
                terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel3);
            end
        end
    end

    local terrainDetailProhibitedMask = groundInfoObject.aiTerrainDetailProhibitedMask;
    local requiredFruitType = groundInfoObject.aiRequiredFruitType;
    local requiredMinGrowthState = groundInfoObject.aiRequiredMinGrowthState;
    local requiredMaxGrowthState = groundInfoObject.aiRequiredMaxGrowthState;
    local prohibitedFruitType = groundInfoObject.aiProhibitedFruitType;
    local prohibitedMinGrowthState = groundInfoObject.aiProhibitedMinGrowthState;
    local prohibitedMaxGrowthState = groundInfoObject.aiProhibitedMaxGrowthState;


    local newTargetX, newTargetY, newTargetZ;

    local moveForwards = true;
    local updateWheels = true;

    self.turnTimer = self.turnTimer - dt;

    if self.turnTimer &lt; 0 or self.turnStage &gt; 0 then
        if self.turnStage &gt; 1 then
            local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
            local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ;
            local myDirX, myDirY, myDirZ = localDirectionToWorld(self.aiTractorDirectionNode, 0, 0, 1);

            newTargetX = self.aiTractorTargetX;
            newTargetY = y;
            newTargetZ = self.aiTractorTargetZ;
            if self.turnStage == 2 then
                self.turnStageTimer = self.turnStageTimer - dt;
                if myDirX*dirX + myDirZ*dirZ &gt; 0.2 or self.turnStageTimer &lt; 0 then
                    if self.aiTurnNoBackward then
                        self.turnStage = 4;
                    else
                        self.turnStage = 3;
                        moveForwards = false;
                    end;
                    if self.turnStageTimer &lt; 0 then

                        self.aiTractorTargetBeforeSaveX = self.aiTractorTargetX;
                        self.aiTractorTargetBeforeSaveZ = self.aiTractorTargetZ;

                        newTargetX = self.aiTractorTargetBeforeTurnX;
                        newTargetZ = self.aiTractorTargetBeforeTurnZ;

                        moveForwards = false;
                        self.turnStage = 6;
                        self.turnStageTimer = self.turnStage6Timeout;
                    else
                        self.turnStageTimer = self.turnStage3Timeout;
                    end;
                end;
            elseif self.turnStage == 3 then
                self.turnStageTimer = self.turnStageTimer - dt;
                if myDirX*dirX + myDirZ*dirZ &gt; 0.95 or self.turnStageTimer &lt; 0 then
                    self.turnStage = 4;
                else
                    moveForwards = false;
                end;
            elseif self.turnStage == 4 then
                local dx, dz = x-newTargetX, z-newTargetZ;
                local dot = dx*dirX + dz*dirZ;
                if -dot &lt; self.turnEndDistance then
                    newTargetX = self.aiTractorTargetX + dirX*(self.turnTargetMoveBack + self.aiToolExtraTargetMoveBack);
                    newTargetY = y;
                    newTargetZ = self.aiTractorTargetZ + dirZ*(self.turnTargetMoveBack + self.aiToolExtraTargetMoveBack);
                    self.turnStage = 5;
                    --print("turning done");
                end;
            elseif self.turnStage == 5 then
                local backX, backY, backZ = getWorldTranslation(backMarker);
                local dx, dz = backX-newTargetX, backZ-newTargetZ;
                local dot = dx*dirX + dz*dirZ;
                if -dot &lt; self.turnEndBackDistance+self.aiToolExtraTargetMoveBack then
                    self.turnTimer = self.turnTimeoutLong;
                    self.turnStage = 0;
                    self:setAIImplementsMoveDown(true);
                    self.waitForTurnTime = self.time + self.waitForTurnTimeout;
                    AITractor.updateInvertLeftRight(self);
                    leftMarker = self.aiCurrentLeftMarker;
                    rightMarker = self.aiCurrentRightMarker;
                    --print("turning done");
                end;
            elseif self.turnStage == 6 then
                self.turnStageTimer = self.turnStageTimer - dt;
                if self.turnStageTimer &lt; 0 then
                    self.turnStageTimer = self.turnStage2Timeout;
                    self.turnStage = 2;

                    newTargetX = self.aiTractorTargetBeforeSaveX;
                    newTargetZ = self.aiTractorTargetBeforeSaveZ;
                else
                    local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
                    local dirX, dirZ = -self.aiTractorDirectionX, -self.aiTractorDirectionZ;
                    -- just drive along direction
                    local targetX, targetZ = self.aiTractorTargetX, self.aiTractorTargetZ;
                    local dx, dz = x-targetX, z-targetZ;
                    local dot = dx*dirX + dz*dirZ;

                    local projTargetX = targetX +dirX*dot;
                    local projTargetZ = targetZ +dirZ*dot;

                    newTargetX = projTargetX-dirX*self.aiTractorLookAheadDistance;
                    newTargetZ = projTargetZ-dirZ*self.aiTractorLookAheadDistance;
                    moveForwards = false;
                end;
            end;
        elseif self.turnStage == 1 then
            -- turn
            AITractor.updateInvertLeftRight(self);
            leftMarker = self.aiCurrentLeftMarker;
            rightMarker = self.aiCurrentRightMarker;

            local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
            local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ;
            local sideX, sideZ = -dirZ, dirX;
            local lX,  lY,  lZ = getWorldTranslation(leftMarker);
            local rX,  rY,  rZ = getWorldTranslation(rightMarker);

            local markerWidth = Utils.vector2Length(lX-rX, lZ-rZ);

            local lWidthX = lX + dirX * self.sideWatchDirOffset;
            local lWidthZ = lZ + dirZ * self.sideWatchDirOffset;
            local lStartX = lWidthX - sideX*0.7*markerWidth;
            local lStartZ = lWidthZ - sideZ*0.7*markerWidth;
            local lHeightX = lStartX + dirX*self.sideWatchDirSize;
            local lHeightZ = lStartZ + dirZ*self.sideWatchDirSize;

            local rWidthX = rX + dirX * self.sideWatchDirOffset;
            local rWidthZ = rZ + dirZ * self.sideWatchDirOffset;
            local rStartX = rWidthX + sideX*0.7*markerWidth;
            local rStartZ = rWidthZ + sideZ*0.7*markerWidth;
            local rHeightX = rStartX + dirX*self.sideWatchDirSize;
            local rHeightZ = rStartZ + dirZ*self.sideWatchDirSize;

            local leftArea, leftAreaTotal = AITractor.getAIArea(self, lStartX, lStartZ, lWidthX, lWidthZ, lHeightX, lHeightZ, terrainDetailRequiredMask, terrainDetailProhibitedMask, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState)
            local rightArea, rightAreaTotal = AITractor.getAIArea(self, rStartX, rStartZ, rWidthX, rWidthZ, rHeightX, rHeightZ, terrainDetailRequiredMask, terrainDetailProhibitedMask, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState)

            -- turn to where ground/fruit is to be changed

            local leftOk = (leftArea &gt; 0 and leftArea &gt; 0.15*leftAreaTotal);
            local rightOk = (rightArea &gt; 0 and rightArea &gt; 0.15*rightAreaTotal);

            if self.aiTractorTurnLeft == nil then
                if leftOk or rightOk then
                    if leftArea &gt; rightArea then
                        self.aiTractorTurnLeft = true;
                    else
                        self.aiTractorTurnLeft = false;
                    end
                else
                    self:stopAITractor();
                    return;
                end;
            else
                self.aiTractorTurnLeft = not self.aiTractorTurnLeft;
                if (self.aiTractorTurnLeft and not leftOk) or (not self.aiTractorTurnLeft and not rightOk) then
                    self:stopAITractor();
                    return;
                end
            end

            local targetX, targetZ = self.aiTractorTargetX, self.aiTractorTargetZ;
            --[[local x = (lX+rX)/2;
            local z = (lZ+rZ)/2;
            local markerSideOffset, lY, lZ = worldToLocal(self.aiTractorDirectionNode, x, (lY+rY)/2, z);
            markerSideOffset = math.abs(markerSideOffset);
            local dx, dz = x-targetX, z-targetZ;
            local dot = dx*dirX + dz*dirZ;
            local x, z = targetX + dirX*dot, targetZ + dirZ*dot;]]
            markerWidth = math.max(markerWidth*self.aiTurnWidthScale, markerWidth-self.aiTurnWidthMaxDifference); -- - markerSideOffset;

            local invertsMarker = AITractor.invertsMarkerOnTurn(self, self.aiTractorTurnLeft);
            if not invertsMarker then
                -- if not inverting, we need to adjust the markerWidth
                local mx = (lX+rX)*0.5;
                local mz = (lZ+rZ)*0.5;
                local markerSideOffset, _, _ = worldToLocal(self.aiTractorDirectionNode, mx, (lY+rY)*0.5, mz);
                --markerSideOffset = math.abs(markerSideOffset);
                markerWidth = markerWidth + markerSideOffset;
                --local dx, dz = x-targetX, z-targetZ;
                --local dot = dx*dirX + dz*dirZ;
                --local x, z = targetX + dirX*dot, targetZ + dirZ*dot;]]
            end;


            --local backX, backY, backZ = getWorldTranslation(backMarker);
            local projTargetLX, projTargetLZ = Utils.projectOnLine(lX, lZ, targetX, targetZ, dirX, dirZ)
            local projTargetRX, projTargetRZ = Utils.projectOnLine(rX, rZ, targetX, targetZ, dirX, dirZ)

            x = (projTargetLX+projTargetRX)*0.5;
            z = (projTargetLZ+projTargetRZ)*0.5;

            local _, _, localZ = worldToLocal(self.aiTractorDirectionNode, x, (lY+rY)*0.5, z);
            self.aiToolExtraTargetMoveBack = math.max(-localZ, 0);


            if self.aiTractorTurnLeft then
                newTargetX = x-sideX*markerWidth;
                newTargetY = y;
                newTargetZ = z-sideZ*markerWidth;
                AITractor.aiRotateLeft(self);
            else
                newTargetX = x+sideX*markerWidth;
                newTargetY = y;
                newTargetZ = z+sideZ*markerWidth;
                AITractor.aiRotateRight(self);
            end;
            local aiForceTurnNoBackward = false;
            for _,implement in pairs(self.attachedImplements) do
                if implement.object.aiForceTurnNoBackward then
                    aiForceTurnNoBackward = true;
                    break;
                end;
            end;

            self.aiTurnNoBackward = (markerWidth &gt;= 2*self.aiTractorTurnRadius) or aiForceTurnNoBackward;

            self.aiTractorTargetBeforeTurnX = self.aiTractorTargetX;
            self.aiTractorTargetBeforeTurnZ = self.aiTractorTargetZ;

            self.aiTractorDirectionX = -dirX;
            self.aiTractorDirectionZ = -dirZ;

            self.turnStage = 2;
            self.turnStageTimer = self.turnStage2Timeout;

            if self.aiTractorTurnLeft then
                --print("turning left ", markerWidth);
            else
                --print("turning right ", markerWidth);
            end;
        else
            self.turnStage = 1;

            self.waitForTurnTime = self.time + self.waitForTurnTimeout;
            self:setAIImplementsMoveDown(false);
            updateWheels = false;
        end;
    else
        local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ;
        local lX,  lY,  lZ = getWorldTranslation(leftMarker);
        local rX,  rY,  rZ = getWorldTranslation(rightMarker);
        self.lastFrontMarkerDistance = self.lastSpeed*self.turnTimeout;
        local scaledDistance = self.lastFrontMarkerDistance*self.frontMarkerDistanceScale
        lX = lX + dirX*scaledDistance;
        lZ = lZ + dirZ*scaledDistance;

        rX = rX + dirX*scaledDistance;
        rZ = rZ + dirZ*scaledDistance;

        local heightX = lX + dirX*2;
        local heightZ = lZ + dirZ*2;

        local area = AITractor.getAIArea(self, lX, lZ, rX, rZ, heightX, heightZ, terrainDetailRequiredMask, terrainDetailProhibitedMask, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState);

        if area &gt;= 1 then
            self.turnTimer = self.turnTimeout;
        end;


        local x,y,z = getWorldTranslation(self.aiTractorDirectionNode);
        local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ;
        -- just drive along direction
        local targetX, targetZ = self.aiTractorTargetX, self.aiTractorTargetZ;
        local dx, dz = x-targetX, z-targetZ;
        local dot = dx*dirX + dz*dirZ;

        local projTargetX = targetX +dirX*dot;
        local projTargetZ = targetZ +dirZ*dot;

        --print("old target: "..targetX.." ".. targetZ .. " distOnDir " .. dot.." proj: "..projTargetX.." "..projTargetZ);

        newTargetX = projTargetX+self.aiTractorDirectionX*self.aiTractorLookAheadDistance;
        newTargetY = y;
        newTargetZ = projTargetZ+self.aiTractorDirectionZ*self.aiTractorLookAheadDistance;
        --print(distOnDir.." target: "..newTargetX.." ".. newTargetZ);
    end;

    if updateWheels then
        local lx, lz = AIVehicleUtil.getDriveDirection(self.aiTractorDirectionNode, newTargetX, newTargetY, newTargetZ);

        if self.turnStage == 3 and math.abs(lx) &lt; 0.1 then
            self.turnStage = 4;
            moveForwards = true;
        end;

        AIVehicleUtil.driveInDirection(self, dt, 25, 0.5, 0.5, 20, true, moveForwards, lx, lz, speedLevel, 0.9);

        --local maxAngle = 0.785398163; --45�;
        local maxlx = 0.7071067; --math.sin(maxAngle);
        local colDirX = lx;
        local colDirZ = lz;

        if colDirX &gt; maxlx then
            colDirX = maxlx;
            colDirZ = 0.7071067; --math.cos(maxAngle);
        elseif colDirX &lt; -maxlx then
            colDirX = -maxlx;
            colDirZ = 0.7071067; --math.cos(maxAngle);
        end;

        for triggerId,_ in pairs(self.numCollidingVehicles) do
            AIVehicleUtil.setCollisionDirection(self.aiTractorDirectionNode, triggerId, colDirX, colDirZ);
        end;
    end;

    if newTargetX ~= nil and newTargetZ ~= nil then
        self.aiTractorTargetX = newTargetX;
        self.aiTractorTargetZ = newTargetZ;
    end;
end;

function AITractor.switchToDirection(self, myDirX, myDirZ)
    self.aiTractorDirectionX = myDirX;
    self.aiTractorDirectionZ = myDirZ;
    --print("switch to direction");
end;

function AITractor.addCollisionTrigger(self, object)
    if self.isServer then
        if object.aiTrafficCollisionTrigger ~= nil then
            addTrigger(object.aiTrafficCollisionTrigger, "onTrafficCollisionTrigger", self);
            self.numCollidingVehicles[object.aiTrafficCollisionTrigger] = 0;
        end;
        if object ~= self then
            for k,v in pairs(object.components) do
                self.trafficCollisionIgnoreList[v.node] = true;
            end;
        end
    end
end;

function AITractor.removeCollisionTrigger(self, object)
    if self.isServer then
        if object.aiTrafficCollisionTrigger ~= nil then
            removeTrigger(object.aiTrafficCollisionTrigger);
            self.numCollidingVehicles[object.aiTrafficCollisionTrigger] = nil;
        end;
        if object ~= self then
            for k,v in pairs(object.components) do
                self.trafficCollisionIgnoreList[v.node] = nil;
            end;
        end
    end
end;


function AITractor:attachImplement(implement)
    local object = implement.object;
    if self.isAITractorActivated then
        object:aiTurnOn();
        AITractor.addCollisionTrigger(self, object);
    end;
    self.aiToolsDirty = true;
end;

function AITractor:detachImplement(implementIndex)
    local object = self.attachedImplements[implementIndex].object;
    if object ~= nil then
        if self.isAITractorActivated then
            object:aiTurnOff();
            AITractor.removeCollisionTrigger(self, object);
        end;
    end
    self.aiToolsDirty = true;
end;

function AITractor:onTrafficCollisionTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    if onEnter or onLeave then
        if g_currentMission.players[otherId] ~= nil then
            if onEnter then
                self.numCollidingVehicles[triggerId] = self.numCollidingVehicles[triggerId]+1;
            elseif onLeave then
                self.numCollidingVehicles[triggerId] = math.max(self.numCollidingVehicles[triggerId]-1, 0);
            end;
        else
            local vehicle = g_currentMission.nodeToVehicle[otherId];
            if vehicle ~= nil and self.trafficCollisionIgnoreList[otherId] == nil then
                if onEnter then
                    self.numCollidingVehicles[triggerId] = self.numCollidingVehicles[triggerId]+1;
                elseif onLeave then
                    self.numCollidingVehicles[triggerId] = math.max(self.numCollidingVehicles[triggerId]-1, 0);
                end;
            end;
        end;
    end;
end;

function AITractor.updateToolsInfo(self)
    local leftMarker = self.aiLeftMarker;
    local rightMarker = self.aiRightMarker;
    local backMarker = self.aiBackMarker;
    local groundInfoObject = nil;
    if self.aiTerrainDetailChannel1 ~= nil and self.aiRequiredFruitType ~= nil and (self.aiTerrainDetailChannel1 &gt;= 0 or self.aiRequiredFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN) then
        groundInfoObject = self;
    end
    local allImplementsAvailable = true;
    for _,implement in pairs(self.attachedImplements) do
        local object = implement.object;
        if object ~= nil then
            if object.aiLeftMarker ~= nil and leftMarker == nil then
                leftMarker = object.aiLeftMarker;
            end;
            if object.aiRightMarker ~= nil and rightMarker == nil then
                rightMarker = object.aiRightMarker;
            end;
            if object.aiBackMarker ~= nil and backMarker == nil then
                backMarker = object.aiBackMarker;
            end;
            if groundInfoObject == nil and (object.aiTerrainDetailChannel1 &gt;= 0 or object.aiRequiredFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN) then
                groundInfoObject = object;
            end;
        else
            allImplementsAvailable = false;
        end
    end;
    self.aiCurrentLeftMarker = leftMarker;
    self.aiCurrentRightMarker = rightMarker;
    self.aiCurrentBackMarker = backMarker;
    self.aiCurrentGroundInfoObject = groundInfoObject;
    AITractor.updateInvertLeftRight(self);

    -- only markes as non-dirty if all tools were available
    if allImplementsAvailable then
        self.aiToolsDirty = false;
    end
end;

function AITractor.updateInvertLeftRight(self)
    if self.aiCurrentLeftMarker ~= nil and self.aiCurrentRightMarker ~= nil then
        local lX, lY, lZ = worldToLocal(self.aiTractorDirectionNode, getWorldTranslation(self.aiCurrentLeftMarker));
        local rX, rY, rZ = worldToLocal(self.aiTractorDirectionNode, getWorldTranslation(self.aiCurrentRightMarker));
        if rX &gt; lX then
            self.aiCurrentLeftMarker, self.aiCurrentRightMarker = self.aiCurrentRightMarker, self.aiCurrentLeftMarker;
        end;
    end;
end;

function AITractor.invertsMarkerOnTurn(self, turnLeft)
    local res = false;
    for _,implement in pairs(self.attachedImplements) do
        if implement.object ~= nil then
            for _, spec in pairs(implement.object.specializations) do
                if spec.aiInvertsMarkerOnTurn ~= nil then
                    res = res or spec.aiInvertsMarkerOnTurn(implement.object, turnLeft);
                end;
            end;
        end
    end;
    return res;
end;

function AITractor:setAIImplementsMoveDown(moveDown)
    if self.isServer then
		g_server:broadcastEvent(AISetImplementsMoveDownEvent:new(self, moveDown), nil, nil, self);
	end;
    for _,implement in pairs(self.attachedImplements) do
        if implement.object ~= nil then
            if implement.object.needsLowering and implement.object.aiNeedsLowering then
                self:setJointMoveDown(implement.jointDescIndex, moveDown, true);
            end;
            if moveDown then
                implement.object:aiLower();
            else
                implement.object:aiRaise();
            end
        end
    end;
end;

function AITractor.aiRotateRight(self)
    if self.isServer then
        g_server:broadcastEvent(AITractorRotateRightEvent:new(self), nil, nil, self);
    end;
    for _,implement in pairs(self.attachedImplements) do
        if implement.object ~= nil then
            implement.object:aiRotateRight();
        end
    end;
end;

function AITractor.aiRotateLeft(self)
    if self.isServer then
        g_server:broadcastEvent(AITractorRotateLeftEvent:new(self), nil, nil, self);
    end;
    for _,implement in pairs(self.attachedImplements) do
        if implement.object ~= nil then
            implement.object:aiRotateLeft();
        end
    end;
end;

function AITractor:canStartAITractor()
    if g_currentMission.disableTractorAI then
        return false;
    end;

    if self.aiCurrentLeftMarker == nil or self.aiCurrentRightMarker == nil or self.aiCurrentBackMarker == nil or self.aiCurrentGroundInfoObject == nil then
        return false;
    end;
    if Hirable.numHirablesHired &gt;= g_currentMission.maxNumHirables then
        return false;
    end;
    return true;
end;

function AITractor:getIsAITractorAllowed()
    if g_currentMission.disableTractorAI then
        return false;
    end;
    if self.aiCurrentLeftMarker == nil or self.aiCurrentRightMarker == nil or self.aiCurrentBackMarker == nil or self.aiCurrentGroundInfoObject == nil then
        return false;
    end;
    return true;
end;

function AITractor.getAIArea(self, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, terrainDetailRequiredMask, terrainDetailProhibitedMask, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState)
    local area = 0;
    local totalArea = 1;
    if terrainDetailRequiredMask &gt; 0 then
        local detailId = g_currentMission.terrainDetailId;
        local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
        setDensityCompareParams(detailId, "greater", 0, 0, terrainDetailRequiredMask, terrainDetailProhibitedMask);
        _,area,totalArea = getDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.terrainDetailAIFirstChannel, g_currentMission.terrainDetailAINumChannels);
        if prohibitedFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
            local ids = g_currentMission.fruits[prohibitedFruitType];
            if ids ~= nil and ids.id ~= 0 then
                setDensityMaskParams(detailId, "between", prohibitedMinGrowthState+1, prohibitedMaxGrowthState+1); -- only fruit outside the given range is allowed
                local _,prohibitedArea = getDensityMaskedParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.terrainDetailAIFirstChannel, g_currentMission.terrainDetailAINumChannels, ids.id, 0, g_currentMission.numFruitStateChannels);
                setDensityMaskParams(detailId, "greater", 0);
                area = area - prohibitedArea;
            end
        end
        setDensityCompareParams(detailId, "greater", -1);

    elseif requiredFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
        local ids = g_currentMission.fruits[requiredFruitType];
        if ids ~= nil and ids.id ~= 0 then
            local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(ids.id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
            setDensityCompareParams(ids.id, "between", requiredMinGrowthState+1, requiredMaxGrowthState+1);
            if terrainDetailProhibitedMask ~= 0 then
                local detailId = g_currentMission.terrainDetailId;
                setDensityMaskParams(ids.id, "greater", 0, 0, 0, terrainDetailProhibitedMask);
                _,area,totalArea = getDensityMaskedParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, g_currentMission.numFruitStateChannels, detailId, g_currentMission.terrainDetailAIFirstChannel, g_currentMission.terrainDetailAINumChannels);
                setDensityMaskParams(ids.id, "greater", 0);
            else
                _,area,totalArea = getDensityParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, g_currentMission.numFruitStateChannels);
            end
            setDensityCompareParams(ids.id, "greater", -1);
        end
    end
    return area,totalArea;
end
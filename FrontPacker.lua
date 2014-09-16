FrontPacker = {}
FrontPacker_mt = { __index = function( table, key ) return Cultivator[key] end }
setmetatable( FrontPacker, FrontPacker_mt )
--FrontPacker = Cultivator

function FrontPacker:updateTick(dt)
  if self:getIsActive() then
    local showFieldNotOwnedWarning = false
    if self.isServer then
      local hasGroundContact = false
      for k, v in pairs(self.contactReportNodes) do
        if v.hasGroundContact then
          hasGroundContact = true
          break
        end
      end
      if not hasGroundContact and self.groundReferenceNode ~= nil then
        local x, y, z = getWorldTranslation(self.groundReferenceNode)
        local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        if y <= terrainHeight + self.groundReferenceThreshold then
          hasGroundContact = true
        end
      end
      if self.cultivatorHasGroundContact ~= hasGroundContact then
        self:raiseDirtyFlags(self.cultivatorGroundContactFlag)
        self.cultivatorHasGroundContact = hasGroundContact
      end
    end
    local hasGroundContact = self.cultivatorHasGroundContact
    local doGroundManipulation = hasGroundContact and (not self.onlyActiveWhenLowered or self:isLowered(false)) and self.startActivationTime <= self.time
    local foldAnimTime = self.foldAnimTime
    if doGroundManipulation and self.isServer then
      local cuttingAreasSend = {}
      for _, cuttingArea in pairs(self.cuttingAreas) do
        if self:getIsAreaActive(cuttingArea) then
          local x, _, z = getWorldTranslation(cuttingArea.start)
          if g_currentMission:getIsFieldOwnedAtWorldPos(x, z) then
            do
              local x1, _, z1 = getWorldTranslation(cuttingArea.width)
              local x2, _, z2 = getWorldTranslation(cuttingArea.height)
              table.insert(cuttingAreasSend, {
                x,
                z,
                x1,
                z1,
                x2,
                z2
              })
            end
          else
            showFieldNotOwnedWarning = true
          end
        end
      end
      if 0 < table.getn(cuttingAreasSend) then
        local dx, dy, dz = localDirectionToWorld(self.cultivatorDirectionNode, 0, 0, 1)
        local angle = Utils.convertToDensityMapAngle(Utils.getYRotationFromDirection(dx, dz), g_currentMission.terrainDetailAngleMaxValue)
        local realArea = FrontPackerAreaEvent.runLocally(cuttingAreasSend, angle)
        g_server:broadcastEvent(FrontPackerAreaEvent:new(cuttingAreasSend, angle))
        local pixelToSqm = g_currentMission:getFruitPixelsToSqm()
        local sqm = realArea * pixelToSqm
        local ha = sqm / 10000
        g_currentMission.missionStats.hectaresWorkedTotal = g_currentMission.missionStats.hectaresWorkedTotal + ha
        g_currentMission.missionStats.hectaresWorkedSession = g_currentMission.missionStats.hectaresWorkedSession + ha
      end
    end
    if self.isClient then
      for _, ps in pairs(self.groundParticleSystems) do
        local enabled = doGroundManipulation and self.lastSpeed * 3600 > 5
        if enabled and ps.cuttingArea ~= nil and self.cuttingAreas[ps.cuttingArea] ~= nil then
          enabled = self:getIsAreaActive(self.cuttingAreas[ps.cuttingArea])
        end
        if ps.isActive ~= enabled then
          ps.isActive = enabled
          Utils.setEmittingState(ps.ps, ps.isActive)
        end
      end
      if self.cultivatorSound ~= nil then
        if doGroundManipulation and self.lastSpeed * 3600 > 3 then
          if not self.cultivatorSoundEnabled and self:getIsActiveForSound() then
            playSample(self.cultivatorSound, 0, self.cultivatorSoundVolume, 0)
            self.cultivatorSoundEnabled = true
          end
        elseif self.cultivatorSoundEnabled then
          stopSample(self.cultivatorSound)
          self.cultivatorSoundEnabled = false
        end
      end
      local updateWheelRotatingParts = hasGroundContact
      if not updateWheelRotatingParts then
        for k, v in pairs(self.wheels) do
          if v.hasGroundContact then
            updateWheelRotatingParts = true
            break
          end
        end
      end
      if updateWheelRotatingParts then
        for k, v in pairs(self.speedRotatingParts) do
          if (doGroundManipulation or v.rotateOnGroundContact) and (foldAnimTime == nil or foldAnimTime <= v.foldMaxLimit and foldAnimTime >= v.foldMinLimit) then
            rotate(v.node, v.rotationSpeedScale * self.lastSpeedReal * self.movingDirection * dt, 0, 0)
          end
        end
      end
    end
    local speedLimit = 20
    if self.maxSpeedLevel == 2 then
      speedLimit = 30
    elseif self.maxSpeedLevel == 3 then
      speedLimit = 100
    end
    if doGroundManipulation and self:doCheckSpeedLimit() and speedLimit < self.lastSpeed * 3600 then
      self.speedViolationTimer = self.speedViolationTimer - dt
      if self.isServer and 0 > self.speedViolationTimer and self.attacherVehicle ~= nil then
        self.attacherVehicle:detachImplementByObject(self)
      end
    else
      self.speedViolationTimer = self.speedViolationMaxTime
    end
    if self.isServer and showFieldNotOwnedWarning ~= self.showFieldNotOwnedWarning then
      self.showFieldNotOwnedWarning = showFieldNotOwnedWarning
      self:raiseDirtyFlags(self.cultivatorGroundContactFlag)
    end
  end
end

FrontPackerAreaEvent = {}
FrontPackerAreaEvent_mt = Class(FrontPackerAreaEvent, Event)
--InitStaticEventClass( FrontPackerAreaEvent, "FrontPackerAreaEvent", 300 ) --EventIds.EVENT_CULTIVATOR_AREA)
InitEventClass(FrontPackerAreaEvent, "FrontPackerAreaEvent")
function FrontPackerAreaEvent:emptyNew()
  local self = Event:new(FrontPackerAreaEvent_mt)
  return self
end

function FrontPackerAreaEvent:new(cuttingAreas, angle)
  local self = FrontPackerAreaEvent:emptyNew()
  assert(table.getn(cuttingAreas) > 0)
  self.cuttingAreas = cuttingAreas
  self.angle = angle
  return self
end

function FrontPackerAreaEvent:readStream(streamId, connection)
  local angle
  if streamReadBool(streamId) then
    angle = streamReadUIntN(streamId, g_currentMission.terrainDetailAngleNumChannels)
  end
  local numAreas = streamReadUIntN(streamId, 4)
  local refX = streamReadFloat32(streamId)
  local refY = streamReadFloat32(streamId)
  local values = Utils.readCompressed2DVectors(streamId, refX, refY, numAreas * 3 - 1, 0.01, true)
  for i = 1, numAreas do
    local vi = i - 1
    local x = values[vi * 3 + 1].x
    local z = values[vi * 3 + 1].y
    local x1 = values[vi * 3 + 2].x
    local z1 = values[vi * 3 + 2].y
    local x2 = values[vi * 3 + 3].x
    local z2 = values[vi * 3 + 3].y
    FrontPackerAreaEvent.updateCultivatorArea(x, z, x1, z1, x2, z2, angle)
  end
end

function FrontPackerAreaEvent:writeStream(streamId, connection)
  local numAreas = table.getn(self.cuttingAreas)
  if streamWriteBool(streamId, self.angle ~= nil) then
    streamWriteUIntN(streamId, self.angle, g_currentMission.terrainDetailAngleNumChannels)
  end
  streamWriteUIntN(streamId, numAreas, 4)
  local refX, refY
  local values = {}
  for i = 1, numAreas do
    local d = self.cuttingAreas[i]
    if i == 1 then
      refX = d[1]
      refY = d[2]
      streamWriteFloat32(streamId, d[1])
      streamWriteFloat32(streamId, d[2])
    else
      table.insert(values, {
        x = d[1],
        y = d[2]
      })
    end
    table.insert(values, {
      x = d[3],
      y = d[4]
    })
    table.insert(values, {
      x = d[5],
      y = d[6]
    })
  end
  assert(table.getn(values) == numAreas * 3 - 1)
  Utils.writeCompressed2DVectors(streamId, refX, refY, values, 0.01)
end

function FrontPackerAreaEvent:run(connection)
  print("Error: Do not run FrontPackerAreaEvent locally")
end

function FrontPackerAreaEvent.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
  local detailId = g_currentMission.terrainDetailId
  local value = 2 ^ g_currentMission.cultivatorChannel
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area = 0	
  setDensityMaskParams(detailId, "between", 1, 2 ^ g_currentMission.cultivatorChannel + 2 ^ g_currentMission.ploughChannel )	
  area = area + setDensityMaskedParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, value)
  if angle ~= nil then
    setDensityMaskedParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.terrainDetailAngleFirstChannel, g_currentMission.terrainDetailAngleNumChannels, detailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, angle)
  end
  setDensityMaskParams(detailId, "greater", 0)
  return area
end

function FrontPackerAreaEvent.runLocally(cuttingAreas, angle)
  local numAreas = table.getn(cuttingAreas)
  local refX, refY
  local values = {}
  for i = 1, numAreas do
    local d = cuttingAreas[i]
    if i == 1 then
      refX = d[1]
      refY = d[2]
    else
      table.insert(values, {
        x = d[1],
        y = d[2]
      })
    end
    table.insert(values, {
      x = d[3],
      y = d[4]
    })
    table.insert(values, {
      x = d[5],
      y = d[6]
    })
  end
  assert(table.getn(values) == numAreas * 3 - 1)
  local values = Utils.simWriteCompressed2DVectors(refX, refY, values, 0.01, true)
  local areaSum = 0
  for i = 1, numAreas do
    local vi = i - 1
    local x = values[vi * 3 + 1].x
    local z = values[vi * 3 + 1].y
    local x1 = values[vi * 3 + 2].x
    local z1 = values[vi * 3 + 2].y
    local x2 = values[vi * 3 + 3].x
    local z2 = values[vi * 3 + 3].y
    areaSum = areaSum + FrontPackerAreaEvent.updateCultivatorArea(x, z, x1, z1, x2, z2, angle)
  end
  return areaSum
end


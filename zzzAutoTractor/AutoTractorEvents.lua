------------------------------------------------------------------------
-- AutoTractorParametersEvent
------------------------------------------------------------------------
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
	self.parameters = AutoTractor.readStreamHelper(streamId);
  self:run(connection)
end
function AutoTractorParametersEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
	AutoTractor.writeStreamHelper(streamId, self.parameters);
end
function AutoTractorParametersEvent:run(connection)
  AutoTractor.setParameters(self.object,self.parameters);
  if not connection:getIsServer() then
    g_server:broadcastEvent(AutoTractorParametersEvent:new(self.object, self.parameters), nil, connection, self.object)
  end
end

------------------------------------------------------------------------
-- AutoTractorNextTSEvent
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- AutoTractorPauseEvent
------------------------------------------------------------------------
AutoTractorPauseEvent = {}
AutoTractorPauseEvent_mt = Class(AutoTractorPauseEvent, Event)
InitEventClass(AutoTractorPauseEvent, "AutoTractorPauseEvent")
function AutoTractorPauseEvent:emptyNew()
  local self = Event:new(AutoTractorPauseEvent_mt)
  return self
end
function AutoTractorPauseEvent:new(object,enabled)
  local self = AutoTractorPauseEvent:emptyNew()
  self.object     = object;
	self.enabled    = enabled
  return self
end
function AutoTractorPauseEvent:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object  = networkGetObject(id)
	self.enabled = streamReadBool(streamId)
  self:run(connection)
end
function AutoTractorPauseEvent:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
	streamWriteBool(streamId, self.enabled)
end
function AutoTractorPauseEvent:run(connection)
  self.object.acPause = self.enabled
  if not connection:getIsServer() then
    g_server:broadcastEvent(AutoTractorPauseEvent:new(self.object,self.enabled), nil, connection, self.object)
  end
end


------------------------------------------------------------------------
-- AutoTractorInt32Event
------------------------------------------------------------------------
local AutoTractorSetInt32ValueLog = 0
function AutoTractor:setInt32Value( name, value, noEventSend )
	
	if self == nil then
		if AutoTractorSetInt32ValueLog < 10 then
			AutoTractorSetInt32ValueLog = AutoTractorSetInt32ValueLog + 1;
			print("------------------------------------------------------------------------");
			print("AutoTractor:setInt32Value: self == nil");
			AutoTractorHud.printCallstack();
			print("------------------------------------------------------------------------");
		end
		return
	end
			
	if noEventSend == nil or not noEventSend then
		if g_server ~= nil then
			g_server:broadcastEvent(AutoTractorInt32Event:new(self,name,value), nil, nil, self)
		else
			g_client:getServerConnection():sendEvent(AutoTractorInt32Event:new(self,name,value))
		end
	end
	
	if     name == "status" then
		if self.atMogliInitDone then
			AutoTractorHud.setStatus( self, value )		
		end
	elseif name == "turnStage" then
		self.acTurnStage     = value
		self.acTurnStageSent = value
	elseif name == "speed2Level" then
		self.speed2Level = value
	end
end


AutoTractorInt32Event = {}
AutoTractorInt32Event_mt = Class(AutoTractorInt32Event, Event)
InitEventClass(AutoTractorInt32Event, "AutoTractorInt32Event")
function AutoTractorInt32Event:emptyNew()
  local self = Event:new(AutoTractorInt32Event_mt)
  return self
end
function AutoTractorInt32Event:new(object,name,value)
  local self = AutoTractorInt32Event:emptyNew()
  self.object = object
	self.name   = name
	self.value  = value
  return self
end
function AutoTractorInt32Event:readStream(streamId, connection)
  local id = streamReadInt32(streamId)
  self.object = networkGetObject(id)
	self.name   = streamReadString(streamId)
	self.value 	= streamReadInt32(streamId)
  self:run(connection)
end
function AutoTractorInt32Event:writeStream(streamId, connection)
  streamWriteInt32(streamId, networkGetObjectId(self.object))
  streamWriteString(streamId,self.name)
  streamWriteInt32(streamId, self.value)
end
function AutoTractorInt32Event:run(connection)
  AutoTractor.setInt32Value( self.object, self.name, self.value, true )
  if not connection:getIsServer() then
    g_server:broadcastEvent(AutoTractorInt32Event:new(self.object,self.name,self.value), nil, connection, self.object)
  end
end


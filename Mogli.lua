--
-- Mogli Hud 
--
-- @author  Mogli aka biedens
-- @date  17.12.2013
--
 
Mogli = {};

------------------------------------------------------------------------
-- some local helper functions
------------------------------------------------------------------------
function Mogli.bool2int(boolean)
	if boolean then
		return 1;
	end;
	return 0;
end;

function Mogli.printCallstack()
	local i = 2;
	local info;
	print("------------------------------------------------------------------------");
	while i <= 10 do
		info = debug.getinfo(i);
		if info == nil then break end
		print(string.format("%i: %s (%i): %s", i, info.short_src, Utils.getNoNil(info.currentline,0), Utils.getNoNil(info.name,"<???>")));
		i = i + 1;
	end
	if info ~= nil and info.name ~= nil and info.currentline ~= nil then
		print("...");
	end
	print("------------------------------------------------------------------------");
end

function Mogli.getText(id)
	if id == nil then
		return "nil";
	end;
	
	if g_i18n:hasText( id ) then
	  return g_i18n:getText( id )
	end
	
	return id
end;

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

function Mogli.getXmlInt(xmlFile, key, default)
	local f = getXMLInt(xmlFile, key);
	if f ~= nil then
		return f;
	end;
	return default;
end;

------------------------------------------------------------------------
-- init
------------------------------------------------------------------------
function Mogli:init( directory, hudName, hudBackground, onTextID, offTextID, showHudKey, x,y, nx, ny, cbOnClick, w, h )
	self.mogliDirectory = directory;

	if self.isClient and ( self.mouseEventRedefined == nil or not self.mouseEventRedefined ) then
		self.mouseEventRedefined = true
		self.mouseEvent          = Utils.overwrittenFunction( self.mouseEvent, Mogli.newMouseEvent );			
		self.mogliHudPath        = Utils.getFilename(hudBackground, self.mogliDirectory)
	end
		
	if w == nil or w <= 0.01 then
		self.mogliHudBtnWidth  = 0.03;     
	else
		self.mogliHudBtnWidth  = w;     
	end
	if h == nil or h <= 0.01 then
		self.mogliHudBtnHeight  = 0.04;     
	else
		self.mogliHudBtnHeight = h;     
	end
	
	self.mogliHudWidth     = nx * ( self.mogliHudBtnWidth  + 0.01) + 0.01
	self.mogliHudHeight    = ( ny + 2 ) * ( self.mogliHudBtnHeight + 0.01 ) - 0.01
	self.mogliHudPosX      = x;   
	self.mogliHudPosY      = y;  
	self.mogliHudBtnPosX   = x + 0.01 ;     
	self.mogliHudBtnPosY   = y + ny * ( self.mogliHudBtnHeight + 0.01 );
	self.mogliHudTextPosX  = self.mogliHudBtnPosX;--0.024;     
	self.mogliHudTextPosY  = y + 0.01;
	self.mogliHudTitlePosY = y + ( ny + 1 ) * ( self.mogliHudBtnHeight + 0.01 );
	self.mogliHudOverlay   = Overlay:new(hudName, self.mogliHudPath, self.mogliHudPosX, self.mogliHudPosY, self.mogliHudWidth, self.mogliHudHeight);
	self.mogliGuiActive    = false;
	self.mogliGuiShowKey   = showHudKey;
	self.mogliGuiOnTextID  = onTextID;
	self.mogliGuiOffTextID = offTextID;	
	self.mogliCBOnClick    = cbOnClick;
	self.mogliStatus       = 0
	self.mogliTitle        = ""
	
	Mogli.addCloseButton( self, nx, ny )
end

------------------------------------------------------------------------
-- addButton
------------------------------------------------------------------------
function Mogli:addButton(imgEnabled, imgDisabled, cbOnClick, cbVisible, nx, ny, textEnabled, textDisabled, textCallback, imgCallback)
	local x = self.mogliHudBtnPosX + (nx-1)*(self.mogliHudBtnWidth+0.01);
	local y = self.mogliHudBtnPosY - (ny-1)*(self.mogliHudBtnHeight+0.01);
	local overlay = Overlay:new(nil, Utils.getFilename(imgEnabled, self.mogliDirectory), x,y,self.mogliHudBtnWidth,self.mogliHudBtnHeight);
	local img2 = "empty.dds"
	if imgDisabled ~= nil then
		img2 = imgDisabled
	end;
	overlay2 = Overlay:new(nil, Utils.getFilename(img2, self.mogliDirectory), x,y,self.mogliHudBtnWidth,self.mogliHudBtnHeight);
	local button = {enabled=true, ovEnabled=overlay, ovDisabled=overlay2, onClick=cbOnClick, onVisible=cbVisible, twoState=(imgDisabled ~= nil), rect={x,y,x+self.mogliHudBtnWidth,y+self.mogliHudBtnHeight}, text1 = textEnabled, text2 = textDisabled, textcb = textCallback, onRender = imgCallback };
	button.overlays = {}
	button.overlays[imgEnabled] = overlay
	if img2 ~= imgEnabled then
		button.overlays[img2] = overlay2
	end
	if self.mogliButtons == nil then self.mogliButtons = {}; end
	table.insert(self.mogliButtons, button);
	return button;
end;

------------------------------------------------------------------------
-- onClose
------------------------------------------------------------------------
function Mogli:onClose()
	Mogli.showGui(self,false)
end

------------------------------------------------------------------------
-- addCloseButton
------------------------------------------------------------------------
function Mogli:addCloseButton(nx, ny)
	local x = self.mogliHudBtnPosX + (nx-1)*(self.mogliHudBtnWidth+0.01) + 0.5*self.mogliHudBtnWidth;
	local y = self.mogliHudBtnPosY + self.mogliHudBtnHeight+0.01;
	local overlay = Overlay:new(nil, Utils.getFilename("close.dds", self.mogliDirectory), x,y,0.5*self.mogliHudBtnWidth,0.5*self.mogliHudBtnHeight);
	local button = {enabled=true, ovEnabled=overlay, ovDisabled=nil, onClick=Mogli.onClose, onVisible=nil, twoState=false, rect={x,y,x+0.5*self.mogliHudBtnWidth,y+0.5*self.mogliHudBtnHeight}, text1 = nil, text2 = nil, textcb = nil, onRender = nil };
	button.overlays = {}
	button.overlays["close.dds"] = overlay
	if self.mogliButtons == nil then self.mogliButtons = {}; end
	table.insert(self.mogliButtons, button);
	return button;
end;

------------------------------------------------------------------------
-- setStatus
------------------------------------------------------------------------
function Mogli:setStatus(status)
	if status == nil or status == 0 then
		self.mogliStatus = 0
	else
		self.mogliStatus = status
	end
end

------------------------------------------------------------------------
-- setTitle
------------------------------------------------------------------------
function Mogli:setTitle(title)
	if title == nil then
		self.mogliTitle = ""
	else
		self.mogliTitle = Mogli.getText( title )
	end
end

------------------------------------------------------------------------
-- newMouseEvent
------------------------------------------------------------------------
function Mogli:newMouseEvent(superFunc, posX, posY, isDown, isUp, button)
	if self.mogliGuiActive then
		local x = InputBinding.mouseMovementX;
		local y = InputBinding.mouseMovementY;
		InputBinding.mouseMovementX = 0;
		InputBinding.mouseMovementY = 0;
		superFunc(self,posX, posY, isDown, isUp, button);
		InputBinding.mouseMovementX = x;
		InputBinding.mouseMovementY = y;
	else
		superFunc(self,posX, posY, isDown, isUp, button);
	end;
end;

------------------------------------------------------------------------
-- mouseEvent
------------------------------------------------------------------------
function Mogli:mouseEvent(posX, posY, isDown, isUp, button)

	self.mogliTooltip = nil;
	local textID, textCB;
	if self.mogliGuiActive then
		for _,overlayButton in pairs(self.mogliButtons) do
			if overlayButton.rect[1] <= posX and posX <= overlayButton.rect[3] and overlayButton.rect[2] <= posY and posY <= overlayButton.rect[4] then
				if overlayButton.onClick ~= nil and isDown and button == 1 then
					if overlayButton.enabled then
						if overlayButton.twoState ~= nil then
							overlayButton.onClick(self, true);
						else
							overlayButton.onClick(self);
						end;
						self.mogliCBOnClick(self);
					elseif overlayButton.twoState then
						overlayButton.onClick(self, false);
						self.mogliCBOnClick(self);
					end;
				end
				if  overlayButton.text1 ~= nil 
						and ( overlayButton.enabled 
							or not overlayButton.twoState 
							or overlayButton.text2 == nil ) then
					textID = overlayButton.text1;
				elseif overlayButton.text2 ~= nil then
					textID = overlayButton.text2;
				end;
				textCB = overlayButton.textcb;
				break;				
			end;
		end;
	end;
	
	if textID ~= nil then
		self.mogliTooltip = Mogli.getText( textID );
		if textCB ~= nil then 
			self.mogliTooltip = textCB(self,self.mogliTooltip) 
		end
	end
end

------------------------------------------------------------------------
-- renderButtons
------------------------------------------------------------------------
function Mogli:renderButtons()
  for _,button in pairs(self.mogliButtons) do
    if button.onVisible ~= nil then
			button.enabled = button.onVisible(self);
		end;
		local img = nil
		if button.onRender ~= nil then
			img = button.onRender(self)
		end
		if img ~= nil and img ~= "" then
			if button.overlays == nil then
				button.overlays = {}
			end
			local ov
			if button.overlays[img] == nil then
				ov = Overlay:new(nil, Utils.getFilename(img, self.mogliDirectory), button.rect[1],button.rect[2],self.mogliHudBtnWidth,self.mogliHudBtnHeight);
				button.overlays[img] = ov
			else
				ov = button.overlays[img]
			end
			ov:render()
		elseif button.enabled then
			if button.ovEnabled ~= nil then
				button.ovEnabled:render();
			end;
		else
			if button.ovDisabled ~= nil then
				button.ovDisabled:render();
			end;
		end;
  end;	
end;

------------------------------------------------------------------------
-- mouse event callbacks
------------------------------------------------------------------------
function Mogli:showGui(on)	
	local old = self.mogliGuiActive
	if self.isClient then
		self.mogliGuiActive = on;
	else
		self.mogliGuiActive = false
	end
	if old ~= self.mogliGuiActive then
		g_mouseControlsHelp.active = not on;
		InputBinding.setShowMouseCursor(on);		
	end
end;

------------------------------------------------------------------------
-- draw
------------------------------------------------------------------------
function Mogli:draw(hideKey)
	if self.isClient then
		if self.mogliGuiActive then
			if hideKey == nil or not hideKey then
				g_currentMission:addHelpButtonText(Mogli.getText(self.mogliGuiOffTextID), self.mogliGuiShowKey);
			end
			g_mouseControlsHelp.active = false;
			InputBinding.setShowMouseCursor(true);		
			setTextAlignment(RenderText.ALIGN_LEFT);
			
			setTextBold(true);		
			if self.mogliStatus == 0 then
				setTextColor(1,1,1,1);
			elseif self.mogliStatus == 1 then
				setTextColor(0,1,0,1);
			elseif self.mogliStatus == 2 then
				setTextColor(1,1,0,1);
			else
				setTextColor(1,0.5,0,1);
			end
			
			renderText(self.mogliHudTextPosX, self.mogliHudTitlePosY, 0.021,self.mogliTitle);		
			
			setTextBold(false);		
			setTextColor(1,1,1,1);
						
			self.mogliHudOverlay:render();
			if     self.mogliTooltip           ~= nil and self.mogliTooltip           ~= "" then
				renderText(self.mogliHudTextPosX, self.mogliHudTextPosY, 0.021,self.mogliTooltip);
			elseif self.mogliInfoText ~= nil and self.mogliInfoText ~= "" then
				renderText(self.mogliHudTextPosX, self.mogliHudTextPosY, 0.021,self.mogliInfoText);
			end
			Mogli.renderButtons(self);
		elseif hideKey == nil or not hideKey then
			g_currentMission:addHelpButtonText(Mogli.getText(self.mogliGuiOnTextID), self.mogliGuiShowKey);
		end
	end
end

------------------------------------------------------------------------
-- delete
------------------------------------------------------------------------
function Mogli:delete()
	if self.mogliButtons ~= nil then
		for _,button in pairs(self.mogliButtons) do
			if button.overlays ~= nil then
				for _,overlay in pairs(button.overlays) do
					pcall(Overlay.delete,overlay)
				end
			end
		end
		self.mogliButtons = nil
	end
end;

------------------------------------------------------------------------
-- onLeave
------------------------------------------------------------------------
function Mogli:onLeave()
	if self.isClient and self.mogliGuiActive then
		g_mouseControlsHelp.active = true;
		InputBinding.setShowMouseCursor(false);		
	end
end;

------------------------------------------------------------------------
-- onEnter
------------------------------------------------------------------------
function Mogli:onEnter()
	Mogli.showGui(self, self.mogliGuiActive);
	if self.isClient and self.mogliGuiActive then
		g_mouseControlsHelp.active = false
		InputBinding.setShowMouseCursor(true);		
	end
end;

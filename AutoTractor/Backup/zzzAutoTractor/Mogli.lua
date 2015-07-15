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
		if info == nil or info.name == nil or info.currentline == nil then break end
		print(string.format("%i: %s (%i)", i, info.name, info.currentline ));
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
	
	local text = g_i18n:getText( id ); --g_i18n.globalI18N.texts[id];
	if text == nil or text == "" then
		return id;
	end;
	
	return text;
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

------------------------------------------------------------------------
-- init
------------------------------------------------------------------------
function Mogli:init( directory, hudName, hudBackground, onTextID, offTextID, showHudKey, x,y, nx, ny, w, h )
	self.mogliDirectory = directory;
	
	if self.mouseEventRedefined == nil or not self.mouseEventRedefined then
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
	
	self.mogliHudWidth     = 0.01 + nx * ( self.mogliHudBtnWidth  + 0.01)
	self.mogliHudHeight    = 0.01 + ny * ( self.mogliHudBtnHeight + 0.01 ); 
	self.mogliHudPosX      = x;   
	self.mogliHudPosY      = y;  
	self.mogliHudBtnPosX   = x + 0.01 ;     
	self.mogliHudBtnPosY   = y + self.mogliHudHeight -0.01;
	self.mogliHudTextPosX  = self.mogliHudBtnPosX;--0.024;     
	self.mogliHudTextPosY  = y + 0.01;
	self.mogliHudOverlay   = Overlay:new(hudName, self.mogliHudPath, self.mogliHudPosX, self.mogliHudPosY, self.mogliHudWidth, self.mogliHudHeight);
	self.mogliGuiActive    = false;
	self.mogliGuiShowKey   = showHudKey;
	self.mogliGuiOnTextID  = onTextID;
	self.mogliGuiOffTextID = offTextID;	
end

------------------------------------------------------------------------
-- addButton
------------------------------------------------------------------------
function Mogli:addButton(imgEnabled, imgDisabled, cbOnClick, cbVisible, nx, ny, textEnabled, textDisabled, textCallback)
	local x = self.mogliHudBtnPosX + (nx-1)*(self.mogliHudBtnWidth+0.01);
	local y = self.mogliHudBtnPosY - (ny-1)*(self.mogliHudBtnHeight+0.01);
	local overlay = Overlay:new(nil, Utils.getFilename(imgEnabled, self.mogliDirectory), x,y,self.mogliHudBtnWidth,self.mogliHudBtnHeight);
	local overlay2 = nil;
	if imgDisabled == nil then
		overlay2 = Overlay:new(nil, Utils.getFilename("empty.dds", self.mogliDirectory), x,y,self.mogliHudBtnWidth,self.mogliHudBtnHeight);
	else
		overlay2 = Overlay:new(nil, Utils.getFilename(imgDisabled, self.mogliDirectory), x,y,self.mogliHudBtnWidth,self.mogliHudBtnHeight);
	end;
	local button = {enabled=true, ovEnabled=overlay, ovDisabled=overlay2, onClick=cbOnClick, onVisible=cbVisible, twoState=(imgDisabled ~= nil), rect={x,y,x+self.mogliHudBtnWidth,y+self.mogliHudBtnHeight}, text1 = textEnabled, text2 = textDisabled, textcb = textCallback };
	if self.mogliButtons == nil then self.mogliButtons = {}; end
	table.insert(self.mogliButtons, button);
	return button;
end;

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
					elseif overlayButton.twoState then
						overlayButton.onClick(self, false);
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
		if button.enabled then
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
  self.mogliGuiActive = on;
  g_mouseControlsHelp.active = not on;
	InputBinding.setShowMouseCursor(on);		
end;

------------------------------------------------------------------------
-- draw
------------------------------------------------------------------------
function Mogli:draw()
	if self.mogliGuiActive then
		g_currentMission:addHelpButtonText(Mogli.getText(self.mogliGuiOffTextID), self.mogliGuiShowKey);
		g_mouseControlsHelp.active = false;
		InputBinding.setShowMouseCursor(true);		
		setTextAlignment(RenderText.ALIGN_LEFT);
    setTextBold(false);		
		setTextColor(1,1,1,1);
		
		self.mogliHudOverlay:render();
		if     self.mogliTooltip           ~= nil and self.mogliTooltip           ~= "" then
			renderText(self.mogliHudTextPosX, self.mogliHudTextPosY, 0.021,self.mogliTooltip);
		elseif self.mogliInfoText ~= nil and self.mogliInfoText ~= "" then
			renderText(self.mogliHudTextPosX, self.mogliHudTextPosY, 0.021,self.mogliInfoText);
		end
		Mogli.renderButtons(self);
	else
		g_currentMission:addHelpButtonText(Mogli.getText(self.mogliGuiOnTextID), self.mogliGuiShowKey);
	end
end

------------------------------------------------------------------------
-- delete
------------------------------------------------------------------------
function Mogli:delete()
end;

------------------------------------------------------------------------
-- onLeave
------------------------------------------------------------------------
function Mogli:onLeave()
  g_mouseControlsHelp.active = true;
	InputBinding.setShowMouseCursor(false);		
end;

------------------------------------------------------------------------
-- onEnter
------------------------------------------------------------------------
function Mogli:onEnter()
	Mogli.showGui(self, self.mogliGuiActive);
end;

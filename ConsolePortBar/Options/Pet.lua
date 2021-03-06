---------------------------------------------------------------
local db = ConsolePort:GetData()
---------------------------------------------------------------
local addOn, ab = ...
---------------------------------------------------------------
local FadeIn = db.UIFrameFadeIn
---------------------------------------------------------------
local Bar = ab.bar
local Lib = ab.libs.button
---------------------------------------------------------------
local Pet = CreateFrame("Frame", "$parentPetBar", Bar, "SecureHandlerStateTemplate")

local BUTTON_SIZE = 36

local GetPetActionCooldown = GetPetActionCooldown
local CooldownFrame_SetTimer = CooldownFrame_SetTimer
local GameTooltip = GameTooltip

local AutoCastShine_AutoCastStart = AutoCastShine_AutoCastStart
local AutoCastShine_AutoCastStop = AutoCastShine_AutoCastStop

Pet:Hide()
Pet:SetBackdrop(ab:GetBackdrop())
Pet.Buttons = {}
Pet.showgrid = 0
Pet.locked = 0
Pet.mode = "show"
--Pet:SetMovable(true)
Pet:SetClampedToScreen(true)
--Pet:SetScript("OnMouseDown", Pet.StartMoving)
--Pet:SetScript("OnMouseUp", Pet.StopMovingOrSizing)
Pet:SetPoint("BOTTOM", Bar, "BOTTOM", 0, 20)
Pet:SetSize((BUTTON_SIZE * NUM_PET_ACTION_SLOTS) + ((NUM_PET_ACTION_SLOTS) * 4), 64)
Pet:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
Pet:RegisterEvent("PET_BAR_UPDATE")
Pet:RegisterEvent("PLAYER_CONTROL_LOST")
Pet:RegisterEvent("PLAYER_CONTROL_GAINED")
Pet:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
Pet:RegisterEvent("UNIT_PET")
Pet:RegisterEvent("UNIT_FLAGS")
Pet:RegisterEvent("UNIT_AURA")
Pet:RegisterEvent("PET_BAR_UPDATE")
Pet:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
Pet:RegisterEvent("PET_SPECIALIZATION_CHANGED")

RegisterStateDriver(Pet, "visibility", "[pet] show; hide")

for i=1, NUM_PET_ACTION_SLOTS do
	local name = addOn.."Pet"..i
	local button = CreateFrame("CheckButton", name, Pet, "SecureActionButtonTemplate, PetActionButtonTemplate")
	button:SetAttribute("type", "pet")
	button:SetAttribute("action", i)
	button:SetID(i)
	button:SetPoint("LEFT", Pet, (i-1) * 42, 0)
	button.HotKey:SetAlpha(0)
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)

	button.AutoCastable = _G[name.."AutoCastable"]
	button.Shine = _G[name.."Shine"]
	button.cooldown = _G[name.."Cooldown"];
	button.NormalTexture = _G[name.."NormalTexture2"]

	button.Flash:SetMask("Interface\\Minimap\\UI-Minimap-Background")
	button.Flash:SetAlpha(0.25)
	button.icon:SetMask("Interface\\Minimap\\UI-Minimap-Background")

	button.NormalTexture:SetTexture("Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\PetNormal")
	button.NormalTexture:ClearAllPoints()
	button.NormalTexture:SetPoint("CENTER", 0, 0)
	button.NormalTexture:SetSize(60, 60)

	button.PushedTexture = button:GetPushedTexture()
	button.HighlightTexture = button:GetHighlightTexture()
	button.CheckedTexture = button:GetCheckedTexture()

	button.PushedTexture:SetTexture("Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\PetPushed")
	button.PushedTexture:ClearAllPoints()
	button.PushedTexture:SetPoint("CENTER", 0, 0)
	button.PushedTexture:SetSize(60, 60)

	button.HighlightTexture:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Button\\Hilite")
	button.HighlightTexture:ClearAllPoints()
	button.HighlightTexture:SetPoint("CENTER", 0, 0)
	button.HighlightTexture:SetSize(40, 40)

	button.CheckedTexture:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Button\\Hilite")
	button.CheckedTexture:ClearAllPoints()
	button.CheckedTexture:SetPoint("CENTER", 0, 0)
	button.CheckedTexture:SetSize(40, 40)

	button.cooldown:SetSwipeTexture("Interface\\AddOns\\ConsolePort\\Textures\\Button\\Normal")
	button.cooldown:SetBlingTexture("Interface\\AddOns\\ConsolePort\\Textures\\Button\\Bling")

	Pet.Buttons[i] = button
end

Pet:HookScript("OnShow", function(self)
	self:Update()
	FadeIn(self, 0.2, 0, 1)
end)

Pet:HookScript("OnHide", function(self)
	--
end)

Pet:SetScript("OnEvent", function(self, event, ...)
	if event == "PET_BAR_UPDATE" or event == "PET_SPECIALIZATION_CHANGED" or
		(event == "UNIT_PET" and arg1 == "player") or
		((event == "UNIT_FLAGS" or event == "UNIT_AURA") and arg1 == "pet") or
		event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" or event == "PLAYER_FARSIGHT_FOCUS_CHANGED" then
		self:Update()
	elseif event == "PET_BAR_UPDATE_COOLDOWN" then
		self:UpdateCooldowns()
	end
end)

local function ButtonOnEnter(self)
	if ( not self.tooltipName ) then
		return
	end
	local uber = GetCVar("UberTooltips")
	if ( uber == "0" ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local bindingText = GetBindingText(GetBindingKey("BONUSACTIONBUTTON"..self:GetID()))
		if (bindingText and bindingText ~= "") then
			GameTooltip:SetText(self.tooltipName..NORMAL_FONT_COLOR_CODE.." ("..bindingText..")"..FONT_COLOR_CODE_CLOSE, 1.0, 1.0, 1.0)
		else
			GameTooltip:SetText(self.tooltipName, 1.0, 1.0, 1.0)
		end
		if ( self.tooltipSubtext ) then
			GameTooltip:AddLine(self.tooltipSubtext, 0.5, 0.5, 0.5, true)
		end
		GameTooltip:Show()
		self.UpdateTooltip = nil
	else
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		if (GameTooltip:SetPetAction(self:GetID())) then
			self.UpdateTooltip = ButtonOnEnter
		else
			self.UpdateTooltip = nil
		end
	end
end

local function ButtonStartFlash(self)
	self.flashing = true
	self.flashtime = 0
end

local function ButtonStopFlash(self)
	self.flashing = false
	self.Flash:Hide()
end


function Pet:Update()
	local petActionButton, petActionIcon, petAutoCastableTexture, petAutoCastShine
	for i, petActionButton in pairs(Pet.Buttons) do
		petActionIcon = petActionButton.icon
		petAutoCastableTexture = petActionButton.AutoCastable
		petAutoCastShine = petActionButton.Shine
		local name, subtext, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(i)
		if ( not isToken ) then
			petActionIcon:SetTexture(texture)
			petActionButton.tooltipName = name
		else
			petActionIcon:SetTexture(_G[texture])
			petActionButton.tooltipName = _G[name]
		end
		petActionButton.isToken = isToken
		petActionButton.tooltipSubtext = subtext
		if ( isActive ) then
			if ( IsPetAttackAction(i) ) then
				ButtonStartFlash(petActionButton)
				-- the checked texture looks a little confusing at full alpha (looks like you have an extra ability selected)
				petActionButton:GetCheckedTexture():SetAlpha(0.5)
			else
				ButtonStopFlash(petActionButton)
				petActionButton:GetCheckedTexture():SetAlpha(1.0)
			end
			petActionButton:SetChecked(true)
		else
			ButtonStopFlash(petActionButton)
			petActionButton:SetChecked(false)
		end
		if ( autoCastAllowed ) then
			petAutoCastableTexture:Show()
		else
			petAutoCastableTexture:Hide()
		end
		if ( autoCastEnabled ) then
			AutoCastShine_AutoCastStart(petAutoCastShine)
		else
			AutoCastShine_AutoCastStop(petAutoCastShine)
		end
		if ( texture ) then
			if ( GetPetActionSlotUsable(i) ) then
				petActionIcon:SetVertexColor(1, 1, 1)
			else
				petActionIcon:SetVertexColor(0.4, 0.4, 0.4)
			end
			petActionIcon:Show();
			petActionButton:SetNormalTexture("Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\PetNormal")
		else
			petActionIcon:Hide()
			petActionButton:SetNormalTexture("Interface\\AddOns\\ConsolePortBar\\Textures\\Button\\PetPushed")
		end
	end
	self:UpdateCooldowns()
end

function Pet:UpdateCooldowns()
	for i=1, NUM_PET_ACTION_SLOTS, 1 do
		local button = Pet.Buttons[i]
		local cooldown = button.cooldown
		local start, duration, enable = GetPetActionCooldown(i)
		CooldownFrame_Set(cooldown, start, duration, enable)
		
		-- Update tooltip
		if ( GameTooltip:GetOwner() == button ) then
			ButtonOnEnter(button)
		end
	end
end

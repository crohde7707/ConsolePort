---------------------------------------------------------------
-- Popup.lua: Redirect cursor to an appropriate popup on show
---------------------------------------------------------------
-- Since popups normally appear in response to an event or
-- crucial action, the UI cursor will automatically move to
-- a popup when it is shown. StaticPopup1 has first priority.

local oldNode

local popups = {
	[StaticPopup1] = false,
	[StaticPopup2] = StaticPopup1,
	[StaticPopup3] = StaticPopup2,
	[StaticPopup4] = StaticPopup3,
}

local visible = {}

for Popup, previous in pairs(popups) do
	Popup:HookScript("OnShow", function(self)
		visible[self] = true
		self:EnableKeyboard(false)
		if not InCombatLockdown() then
			local priorityPopup = popups[previous]
			if not priorityPopup or ( priorityPopup and not priorityPopup:IsVisible() ) then
				local current = ConsolePort:GetCurrentNode()
				if current and not popups[current:GetParent()] then
					oldNode = current
				end
				ConsolePort:SetCurrentNode(self.button1)
				if not ConsolePortSettings or not ConsolePortSettings.disableUI then
					ConsolePort:UIControl()
				end
			end
		end
	end)
	Popup:HookScript("OnHide", function(self)
		visible[self] = nil
		if not next(visible) and not InCombatLockdown() and oldNode then
			ConsolePort:SetCurrentNode(oldNode)
		end
	end)
end

---------------------------------------------------------------
-- Popup restyling: temporarily re-style popups 
---------------------------------------------------------------
local _, db = ...
local popup, defaultBackdrop

function ConsolePort:ShowPopup(...)
	popup = StaticPopup_Show(...)
	defaultBackdrop = popup:GetBackdrop()
	popup:EnableKeyboard(false)
	popup:SetBackdrop(db.Atlas.Backdrops.FullSmall)
	return popup
end

function ConsolePort:ClearPopup()
	if popup then
		popup:SetBackdrop(defaultBackdrop)
		popup = nil
	end
end

---------------------------------------------------------------
-- Dropdowns: Child widget filtering to remove unwanted entries
---------------------------------------------------------------

-- local dropDowns = {
-- 	DropDownList1,
-- 	DropDownList2,
-- }

-- local forbidden = {
-- 	["SET_FOCUS"] = true,
-- 	["PET_DISMISS"] = true,
-- }

-- for i, DD in pairs(dropDowns) do
-- 	DD:HookScript("OnShow", function(self)
-- 		local children = {self:GetChildren()}
-- 		for j, child in pairs(children) do
-- 			if (child.IsVisible and not child:IsVisible()) or (child.IsEnabled and not child:IsEnabled()) then
-- 				child.ignoreNode = true
-- 			else
-- 				child.ignoreNode = nil
-- 			end
-- 			if child.hasArrow then
-- 				child.ignoreChildren = true
-- 			else
-- 				child.ignoreChildren = false
-- 			end
-- 			if forbidden[child.value] then
-- 				child.ignoreNode = true
-- 			end
-- 		end
-- 	end)
-- end
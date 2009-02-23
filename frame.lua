local fux = LibStub("AceAddon-3.0"):GetAddon("Fux")
local frame = fux:NewModule("Frame")
local Q = LibStub("LibQuixote-2.0")

function frame:OnInitialize()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetHeight(175)
	f:SetWidth(75)
	f:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})

	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -500)
	f:Show()

	local t = f:CreateFontString(nil, "OVERLAY")
	t:SetPoint("TOP", f, "TOP", 0, -3)
	t:SetPoint("LEFT")
	t:SetPoint("RIGHT")
	t:SetFont(STANDARD_FONT_TEXT, 16)
	t:SetText("Fux Title")

	f.title = t

	self.frame = f
end

function frame:Update()
	for zone in Q:IterateZones() do
	end
end

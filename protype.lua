local parent, ns = ...
ns.prototype = CreateFrame("Frame")

local fux = ns.fux
local proto = ns.prototype

local newRow, delRow
local row_cache = {}

function proto:DelRow()
	self:Hide()

	self:ClearAllPoints()
	self:SetHeight(0)
	self:SetWidth(0)

	self.text:SetText("")
	self.level:SetText("")

	setmetatable(self, {})

	row_cache[row] = true

	return true
end

function proto:NewRow(height)
	height = height or 12
	local row = next(row_cache)

	if(row) then
		row_cache[row] = nil
		row:Show()
	else
		row = CreateFrame("Frame", nil, fux.frame)
		row:EnableMouse(true)

		local text = row:CreateFontString(nil, "OVERLAY")
		text:SetFont(STANDARD_TEXT_FONT, height)
		text:SetPoint("TOPLEFT", row, "TOPLEFT")
		row.text = text

		local level = row:CreateFontString(nil, "OVERLAY")
		level:SetPoint("RIGHT", row)
		level:SetPoint("TOP", row)
		level:SetPoint("BOTTOM", row)
		level:SetJustifyH("RIGHT")
		level:SetFont(STANDARD_TEXT_FONT, height)
		row.right = level
	end

	row:SetHeight(height)
	row:SetWidth(fux.frame:GetWidth())

	row:SetScript("OnMouseUp", self.OnClick)
	row:SetScript("OnEnter", self.OnEnter)
	row:SetScript("OnLeave", self.OnLeave)

	return setmetatable(row, { __index = self })
end

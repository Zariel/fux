local parent, ns = ...

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
	self.right:SetText("")

	--setmetatable(self, nil)

	self.children = nil
	self.childrenByName = nil

	row_cache[self] = true

	return true
end

function proto:NewRow(height)
	height = height or 12
	local row = next(row_cache)

	if(row) then
		print(row, type(row))
		row_cache[row] = nil
	else
		row = CreateFrame("Frame", nil, fux.frame)
		row:EnableMouse(true)

		local text = row:CreateFontString(nil, "OVERLAY")
		text:SetPoint("TOPLEFT", row, "TOPLEFT")
		row.text = text

		local right = row:CreateFontString(nil, "OVERLAY")
		right:SetPoint("RIGHT", row)
		right:SetPoint("TOP", row)
		right:SetPoint("BOTTOM", row)
		right:SetJustifyH("RIGHT")
		row.right = right
	end

	row:Show()
	row:SetHeight(height)
	row:SetWidth(fux.frame:GetWidth())

	row.text:SetFont(STANDARD_TEXT_FONT, height)
	row.right:SetFont(STANDARD_TEXT_FONT, height)

	row.right:SetTextColor(1, 1, 1)
	row.text:SetTextColor(1, 1, 1)

	row:SetScript("OnMouseUp", self.OnClick)
	row:SetScript("OnEnter", self.OnEnter)
	row:SetScript("OnLeave", self.OnLeave)

	row.children = {}
	row.childrenByName = {}

	return setmetatable(row, {
		__index = self,
		__tostring = function(self) return tostring(self.name) end
	})
end

function proto:Remove()
	for i = 1, #self.parent.children do
		if(self.parent.children[i] == self) then
			table.remove(self.parent.children, i)
			break
		end
	end

	for k, v in pairs(self.children) do
		v:Remove()
	end

	self.parent.childrenByName[self.name] = nil

	self:DelRow()
end

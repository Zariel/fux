local fux = LibStub("AceAddon-3.0"):GetAddon("Fux")

local zone_proto = CreateFrame("Frame")
local quest_proto = CreateFrame("Frame")
local objective_proto = CreateFrame("Frame")

local newRow, delRow
do
	local row_cache = {}
	newRow = function(height)
		height = height or 12
		local row = next(row_cache)
		if row then
			row_cache[row] = nil
			row:Show()
		else
			row = CreateFrame("Frame", nil, fux.frame)
			row:SetHeight(height)
			row:SetWidth(fux.frame:GetWidth())

			local text = row:CreateFontString(nil, "OVERLAY")
			text:SetFont(STANDARD_TEXT_FONT, height)
			text:SetPoint("TOPLEFT", row, "TOPLEFT")
			row.text = text

			local level = row:CreateFontString(nil, "OVERLAY")
			level:SetPoint("TOPRIGHT", row, "TOPRIGHT")
			level:SetFont(STANDARD_TEXT_FONT, height)
			row.right = level
		end

		return row
	end
end

function fux:NewZone(name)
	if self.zonesByName[name] then
		return self.zonesByName[name]
	end

	fux.zoneCount = fux.zoneCount + 1

	local row = newRow()

	setmetatable(row, {__index = zone_proto})

	row.text:SetText(name)

	row.name = name
	row.id = fux.zonesCount
	row.visible = true

	row.quests = {}
	row.questsByName = {}
	row.questCount = 0

	row:SetPoint("LEFT", fux.frame, "LEFT", self.zoneIndent, 0)

	table.insert(self.zones, row)
	self.zonesByName[name] = row

	return row
end

function zone_proto:AddQuest(name, level, status)
	if self.questsByName[name]then
		return self.questsByName[name]
	end

	self.questCount = self.questCount + 1

	local row = newRow()
	setmetatable(row, {__index = quest_proto})

	row.text:SetText(name)
	row.right:SetText(status)

	row.name = name
	row.level = level
	row.status = status
	row.id = self.questCount

	row.objectives = {}
	row.objectivesByName = {}
	row.objectivesCount = 0

	row:SetPoint("LEFT", self, "LEFT", self.questIndent, 0)

	table.insert(self.quests, row)
	self.questsByName[name] = row

	return row
end

function quest_proto:AddObjective(name, status)
	if self.objectivesByName[name] then
		return self.objectivesByName[name]
	end

	self.objectivesCount = self.objectivesCount + 1

	local row = newRow()
	setmetatable(row, {__index = objective_proto})

	row.text:SetText(name)
	row.right:SetText(status)

	row.name = name
	row.status = status
	row.id = self.objectivesCount

	row:SetPoint("LEFT", self, "LEFT", self.objIndent, 0)

	table.insert(self.objectives, row)
	self.objectivesByName[name] = row

	return row
end



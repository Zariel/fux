local fux = LibStub("AceAddon-3.0"):GetAddon("Fux")

local zone_proto = {}
local quests_proto = {}

local newRow, delRow
do
	local row_cache = {}
	newRow = function(height)
		height = height or 12
		local row = next(row_cache)
		if row then
			row_cache(row) = nil
			row:Show()
		else
			row = CreateFrame("Frame", nil, fux.frame)
			row:SetHeight(height)
			row:SetWidth(fux.frame:GetWidth())

			local text = row:CreateFontString(nil, "OVERLAY")
			text:SetFont(STANDARD_TEXT_FONT, height)
			text:SetPoint("TOPLEFT", row, "TOPLEFT")
			row.title = text

			local level = row:CreateFontString(nil, "OVERLAY")
			level:SetPoint("TOPRIGHT", row, "TOPRIGHT")
			level:SetFont(STANDARD_TEXT_FONT, height)
			row.right = level
		end

		return row
	end
end

function fux:NewZone(name)
	if self.ZonesByName[name] then
		return
	end

	fux.zoneCount = fux.zoneCount + 1

	local row = newRow()

	local meta = getmetatable(row)
	setmetatable(meta, __index = zone_proto)

	row.text:SetText(name)

	row.name = name
	row.id = fux.zonesCount
	row.visible = false

	row.quests = {}
	row.questsByName = {}
	row.questCount = 0

	if fux.zoneCount > 1 then
		local prev = fux.Zones[fux.zoneCount - 1]
		if prev.visible then
			-- Has quests showing, TODO later check if we have
			-- objectives in the quests
			local q = prev.quests[prev.questCount]
			row:SetPoint("TOP", q, "BOTTOM", 0, - 3)
		else
			row:SetPoint("TOP", prev, "BOTTOM", 0, - 3)
		end
	else
		row:SetPoint("TOP", fux.frame, "TOP", 0, - 20)
	end

	row:SetPoint("LEFT", fux.frame, "LEFT", 5, 0)

	table.insert(self.zones, row)
	self.ZonesByName[name] = row

	return row
end

function zone_proto:AddQuest(name, level, status)
	if row.questsByName then
		return
	end

	self.questCount = self.questCount + 1

	local row = newRow()

	row.text:SetText(name)

	row.name = name
	row.level = level
	row.status = status
	row.id = self.questCount

	row.objectives = {}
	row.objectivesByName = {}
	row.objectivesCount = 0

	if self.questCount > 1 then
		local prev = self.quests[self.questCount - 1]
		if prev then
			if prev.objectivesCount > 1 then
				local o = prev.objectives[prev.objectivesCount]
				row:SetPoint("TOP", o, "BOTTOM", 0, - 3)
			else
				row:SetPoint("TOP", prev, "BOTTOM", 0, - 3)
			end
		end
	else
		row:SetPoint("TOP", self, "BOTTOM", 0, - 3)
	end

	row:SetPoint("LEFT", fux.frame, "LEFT", 5, 0)

	table.insert(self.quests, row)
	self.questsByName[name] = row

	return row
end

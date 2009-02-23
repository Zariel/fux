local fux = LibStub("AceAddon-3.0"):GetAddon("Fux")

local zone_proto = {}
zone_proto = {}

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
	row.uid = GetTime()
	row.id = fux.zonesCount + 1
	row.quests = {}

	if fux.zoneCount > 1 then
		local prev = fux.Zones[fux.zoneCount - 1]
		row:SetPoint("TOP", prev, "BOTTOM", 0, - 3)
	else
		row:SetPoint("TOP", fux.frame, "TOP", 0, - 20)
	end

	row:SetPoint("LEFT", fux.frame, "LEFT", 0, 5)

	table.insert(self.zones, row)
	self.ZonesByName[name] = row

	return row
end

function zone_proto:AddQuest(name, level, status)

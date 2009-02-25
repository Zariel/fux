local fux = LibStub("AceAddon-3.0"):GetAddon("Fux")
local Q = LibStub("LibQuixote-2.0")

local fade = 0.7

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
			level:SetPoint("RIGHT", row)
			level:SetPoint("TOP", row)
			level:SetPoint("BOTTOM", row)
			level:SetJustifyH("RIGHT")
			level:SetFont(STANDARD_TEXT_FONT, height)
			row.right = level
		end

		return row
	end

	local cleanTable = function(t)
		for id, C in pairs(t) do
			C:Hide()
			C.text:SetText("")
			C.right:SetText("")
			C:ClearAllPoints()
		end

		return true
	end

	delRow = function(row)
		if row.type == "zone" then
			cleanTable(fux.zones[row.id])
			table.remove(fux.zones, row.id)
			fux.zonesByName[row.name] = nil
			fux.zoneCount = fux.zoneCount - 1

			cleanTable(row.quests)

			cleanTable(row.quests.objectives)

		elseif row.type == "quest" then
		end

		cache[row] = true
	end
end

local zoneOnClick = function(self, button)
	if button == "LeftButton" then
		if self.visible then
			self.text:SetText("-" .. self.name)
			for qid, q in ipairs(self.quests) do
				q:Hide()
				for oid, o in ipairs(q.objectives) do
					o:Hide()
				end
			end
			self.visible = false
		else
			self.text:SetText("+" .. self.name)
			for qid, q in ipairs(self.quests) do
				q:Show()
				for oid, o in ipairs(q.objectives) do
					o:Show()
				end
			end
			self.visible = true
		end
		fux:Reposition()
	end
end

local zoneOnEnter = function(self)
	self.text:SetTextColor(1, 1, 1)
end

local zoneOnLeave = function(self)
	self.text:SetTextColor(fade, fade, fade)
end

function fux:NewZone(name)
	if self.zonesByName[name] then
		return self.zonesByName[name]
	end

	fux.zoneCount = fux.zoneCount + 1

	local row = newRow(14)

	row:EnableMouse()
	row:SetScript("OnMouseUp", zoneOnClick)
	row:SetScript("OnEnter", zoneOnEnter)
	row:SetScript("OnLeave", zoneOnLeave)

	setmetatable(row, {__index = zone_proto})

	row.text:SetText("+" .. name)
	row.text:SetTextColor(fade, fade, fade)

	row.name = name
	row.id = fux.zonesCount
	row.visible = true
	row.type = "zone"

	row.quests = {}
	row.questsByName = {}
	row.questCount = 0

	table.insert(self.zones, row)
	self.zonesByName[name] = row

	return row
end

local questOnClick = function(self, button)
	if button == "LeftButton" then
		Q:ShowQuestLog(self.uid)
	end
end

local questOnEnter = function(self)
	local col = GetDifficultyColor(self.level)
	self.text:SetTextColor(col.r, col.g, col.b)
end

local questOnLeave = function(self)
	local col = GetDifficultyColor(self.level)
	self.text:SetTextColor(col.r * fade, col.g * fade, col.b * fade)
end

function zone_proto:AddQuest(uid, name, level, status)
	if self.questsByName[name]then
		return self.questsByName[name]
	end

	self.questCount = self.questCount + 1

	local row = newRow()
	setmetatable(row, {__index = quest_proto})

	row.text:SetText(string.format("[%d] %s", level, name))

	row.name = name
	row.level = level
	row.type = "quest"

	row:EnableMouse(true)
	row:SetScript("OnEnter", questOnEnter)
	row:SetScript("OnLeave", questOnLeave)
	row:SetScript("OnMouseUp", questOnClick)

	local col = GetDifficultyColor(level)
	row.text:SetTextColor(col.r * fade, col.g * fade, col.b * fade)

	if status then
		row.status = status
		row.right:SetText(status)
	end

	row.id = self.questCount
	row.uid = uid

	row.objectives = {}
	row.objectivesByName = {}
	row.objectivesCount = 0

	table.insert(self.quests, row)
	self.questsByName[name] = row

	return row
end

function quest_proto:SetStatus(status)
	self.right:SetText(status)
end

local objOnClick = function(self, button)
	if button == "LeftButton" then
		Q:ShowQuestLog(self.uid)
	end
end

local objOnEnter = function(self)
	self.text:SetTextColor(0.7, 0.7, 0.7)
end

local objOnLeave = function(self)
	self.text:SetTextColor(0.7 * fade, 0.7 * fade, 0.7 * fade)
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

	row.text:SetTextColor(0.7 * fade, 0.7 * fade, 0.7 * fade)

	row:EnableMouse(true)
	row:SetScript("OnMouseUp", objOnClick)
	row:SetScript("OnEnter", objOnEnter)
	row:SetScript("OnLeave", objOnLeave)

	row.name = name
	row.status = status
	row.id = self.objectivesCount
	row.type = "objective"

	table.insert(self.objectives, row)
	self.objectivesByName[name] = row

	return row
end

local fux = getfenv(0).fux
local Q = LibStub("LibQuixote-2.0")

local fade = 0.7
fux.fade = fade

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
			row.tid = 0
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
end

local tip = GameTooltip

-- Zone Script Handlers
local zoneOnClick = function(self, button)
	if button == "LeftButton" then
		if self.visible then
			self:HideAll()
		else
			self:ShowAll()
		end
		fux:Reposition()
	end
end

local zoneOnEnter = function(self)
	self.text:SetTextColor(1, 1, 1)
	self.right:SetTextColor(1, 1, 1)
end

local zoneOnLeave = function(self)
	self.text:SetTextColor(fade, fade, fade)
	self.right:SetTextColor(fade, fade, fade)
end

-- Quest Script Handlers
local questOnClick = function(self, button)
	if button == "LeftButton" then
		if IsAltKeyDown() then
			if self.visible then
				self:HideAll()
			else
				self:ShowAll()
			end
			fux:Reposition()
		else
			Q:ShowQuestLog(self.uid)
		end
	end
end

local questOnEnter = function(self)
	local col = GetDifficultyColor(self.level)
	self.text:SetTextColor(col.r, col.g, col.b)
	self.right:SetTextColor(col.r, col.g, col.b)

	tip:SetOwner(fux.frame, "ANCHOR_NONE")
	tip:SetPoint("TOPLEFT", fux.frame, "TOPRIGHT")
	tip:AddLine(select(2, Q:GetQuestText(self.uid)), 0.8, 0.8, 0.8, true)
	tip:Show()
end

local questOnLeave = function(self)
	local col = GetDifficultyColor(self.level)
	self.text:SetTextColor(col.r * fade, col.g * fade, col.b * fade)
	self.right:SetTextColor(col.r * fade, col.g * fade, col.b * fade)

	tip:Hide()
end

-- Objective Script Handlers
local objOnClick = function(self, button)
	if button == "LeftButton" then
		Q:ShowQuestLog(self.qid)
	end
end

local objOnEnter = function(self)
	self.text:SetTextColor(1, 1, 1)
	self.right:SetTextColor(1, 1, 1)
end

local objOnLeave = function(self)
	self.text:SetTextColor(0.7 * fade, 0.7 * fade, 0.7 * fade)
	self.right:SetTextColor(0.7 * fade, 0.7 * fade, 0.7 * fade)
end

-- Zone Creation
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

	row.text:SetText("-" .. name)
	row.text:SetTextColor(fade, fade, fade)

	row.name = name
	row.id = fux.zonesCount
	row.visible = true
	row.type = "zone"

	row.quests = {}
	row.questsByName = {}
	row.questCount = 0

	local pos = 1
	for i, z in ipairs(self.zones) do
		pos = i + 1
		if z.name > name then
			pos = i
			break
		end
	end

	table.insert(self.zones, pos, row)
	self.zonesByName[name] = row

	return row
end

-- Zone Public functions
function zone_proto:Remove(qid, quest)
	quest:RemoveAll()

	quest:Hide()
	table.remove(self.quests, qid)
	self.questsByName[quest.name] = nil
	self.questCount = self.questCount - 1
end

function zone_proto:RemoveAll()
	for qid, quest in ipairs(self.quests) do
		self:Remove(qid, quest)
	end
end

function zone_proto:HideAll()
	self.text:SetText("+" .. self.name)
	for qid, q in ipairs(self.quests) do
		q:Hide()
		for oid, o in ipairs(q.objectives) do
			o:Hide()
		end
	end
	self.visible = false
end

function zone_proto:ShowAll()
	self.text:SetText("-" .. self.name)
	for qid, q in ipairs(self.quests) do
		q:Show()
		for oid, o in ipairs(q.objectives) do
			if q.visible then
				o:Show()
			end
		end
	end
	self.visible = true
end

-- Quest Creation
function zone_proto:AddQuest(uid, name, level, tag, status)
	if self.questsByName[name]then
		if status then
			self.questsByName[name].right:SetText(status)
		end
		return self.questsByName[name]
	end

	self.questCount = self.questCount + 1

	local row = newRow()
	setmetatable(row, {__index = quest_proto})

	row.text:SetText(string.format("[%s] %s", tag and level .. tag or level, name))

	row.name = name
	row.level = level
	row.type = "quest"
	row.status = status
	row.visible = true

	row:EnableMouse(true)
	row:SetScript("OnEnter", questOnEnter)
	row:SetScript("OnLeave", questOnLeave)
	row:SetScript("OnMouseUp", questOnClick)

	local col = GetDifficultyColor(level)
	row.text:SetTextColor(col.r * fade, col.g * fade, col.b * fade)
	row.right:SetTextColor(col.r * fade, col.g * fade, col.b * fade)

	if status then
		row.status = status
		row.right:SetText(status)
	end

	row.id = self.questCount
	row.uid = uid

	row.objectives = {}
	row.objectivesByName = {}
	row.objectivesCount = 0

	local pos = 1
	for i, q in ipairs(self.quests) do
		pos = i + 1
		if level < q.level then
			pos = i
			break
		elseif level == q.level and name < q.name then
			pos = i
			break
		end
	end

	table.insert(self.quests, pos, row)
	self.questsByName[name] = row

	return row
end

-- Quest public functions
function quest_proto:HideAll()
	for oid, o in ipairs(self.objectives) do
		o:Hide()
	end
	if self.need > 0 then
		self.right:SetText(self.got .. "/" .. self.need)
	end
	self.visible = false
end

function quest_proto:ShowAll()
	if self.status ~= "(done)" then
		self.right:SetText("")
	end
	for oid, o in ipairs(self.objectives) do
		o:Show()
	end
	self.visible = true
end

function quest_proto:Remove(oid, obj)
	obj:Hide()
	table.remove(self.objectives, oid)
	self.objectivesByName[obj.name] = nil
	self.objectivesCount = self.objectivesCount - 1
end

function quest_proto:RemoveAll()
	for oid, obj in ipairs(self.objectives) do
		self:Remove(oid, obj)
	end
end

-- Objective creation
function quest_proto:AddObjective(qid, name, got, need)
	if self.objectivesByName[name] then
		if got and need then
			local obj = self.objectivesByName[name]
			obj.right:SetText(got .. "/" .. need)
			obj.got = got
			obj.need = need
		end
		if not self.visible and self.need > 0 then
			self.right:SetText(self.got .. "/" .. self.need)
		end
		return self.objectivesByName[name]
	end

	self.objectivesCount = self.objectivesCount + 1

	local row = newRow()
	setmetatable(row, { __index = objective_proto })

	row.text:SetText(name)
	row.right:SetText(got .. "/" .. need)

	row.text:SetTextColor(0.7 * fade, 0.7 * fade, 0.7 * fade)
	row.right:SetTextColor(0.7 * fade, 0.7 * fade, 0.7 * fade)

	row:EnableMouse(true)
	row:SetScript("OnMouseUp", objOnClick)
	row:SetScript("OnEnter", objOnEnter)
	row:SetScript("OnLeave", objOnLeave)

	row.name = name
	row.got = got
	row.need = need

	row.id = self.objectivesCount
	row.type = "objective"
	row.qid = qid

	local pos = 1
	for i, o in ipairs(self.objectives) do
		pos = i + 1
		if name < o.name then
			pos = i
			break
		end
	end

	table.insert(self.objectives, pos, row)
	self.objectivesByName[name] = row

	return row
end

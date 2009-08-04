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
	newRow = function(parent, height)
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

		return setmetatable(row, { __index = parent })
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
	local r, g, b
	if self.daily then
		r, g, b = 62/255, 174/255, 1
	else
		local col = GetDifficultyColor(self.level)
		r, g, b = col.r, col.g, col.b
	end

	self.text:SetTextColor(r, g, b)
	self.right:SetTextColor(r, g, b)

	tip:SetOwner(fux.frame, "ANCHOR_NONE")
	tip:SetPoint("TOPLEFT", fux.frame, "TOPRIGHT")

	tip:ClearLines()
	tip:AddDoubleLine(self.name, self.status and self.status or self.need > 0 and self.got .. "/" .. self.need, r, g, b, r, g, b)

	tip:AddLine(select(2, Q:GetQuestText(self.uid)), 0.8, 0.8, 0.8, true)
	if #self.objectives > 0 then
		tip:AddLine("")

		for oid, obj in ipairs(self.objectives) do
			tip:AddDoubleLine(obj.name, obj.need > 0 and obj.got .. "/" .. obj.need, r, g, b, r, g, b)
		end
	end

	tip:SetBackdropColor(0, 0, 0, 0.8)

	tip:Show()
end

local questOnLeave = function(self)
	local r, g, b
	if self.daily then
		r, g, b = 62/255, 174/255, 1
	else
		local col = GetDifficultyColor(self.level)
		r, g, b = col.r, col.g, col.b
	end

	self.text:SetTextColor(r * fade, g * fade, b * fade)
	self.right:SetTextColor(r * fade, g * fade, b * fade)

	if tip:IsOwned(fux.frame) then
		tip:Hide()
	end
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

	local row = newRow(zone_proto, 14)

	row:EnableMouse()
	row:SetScript("OnMouseUp", zoneOnClick)
	row:SetScript("OnEnter", zoneOnEnter)
	row:SetScript("OnLeave", zoneOnLeave)

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

function fux:RemoveZone(id, zone)
	if type(zone) == "string" then
		zone = self.zonesByName[zone]
	end


	if not id and zone then
		for k, v in pairs(self.zones) do
			if v == zone then
				id = k
				break
			end
		end
	end

	if not(id and zone) then return end

	zone:Hide()

	table.remove(self.zones, id)
	self.zonesByName[zone.name] = nil
	self.zoneCount = self.zoneCount - 1
end


-- Zone Public functions
function zone_proto:Remove(qid, quest)
	if type(quest) == "string" then
		quest = self.questsByName[quest]
	end

	if not qid and quest then
		for k, v in pairs(self.quests) do
			if v == quest then
				qid = k
				break
			end
		end
	end

	if not(qid and quest) then return end

	quest:Hide()

	quest:RemoveAll()

	table.remove(self.quests, qid)
	self.questsByName[quest.name] = nil
	self.questCount = self.questCount - 1
end

function zone_proto:RemoveAll()
	for qid, quest in pairs(self.quests) do
		self:Remove(qid, quest)
	end
end

function zone_proto:HideAll()
	self.text:SetText("+" .. self.name)
	for qid, q in pairs(self.quests) do
		q:Hide()
		for oid, o in pairs(q.objectives) do
			o:Hide()
		end
	end
	self.visible = false
end

function zone_proto:ShowAll()
	self.text:SetText("-" .. self.name)
	for qid, q in pairs(self.quests) do
		q:Show()
		for oid, o in pairs(q.objectives) do
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

	local row = newRow(quest_proto)

	row.text:SetText(string.format("[%s] %s", tag and level .. tag or level, name))

	row.name = name
	row.level = level
	row.type = "quest"
	row.status = status
	row.visible = true
	row.daily = tag == "*"

	row.got = 0
	row.need = 0

	row:EnableMouse(true)
	row:SetScript("OnEnter", questOnEnter)
	row:SetScript("OnLeave", questOnLeave)
	row:SetScript("OnMouseUp", questOnClick)

	local r, g, b
	if row.daily then
		r, g, b = 62/255, 174/255, 1
	else
		local col = GetDifficultyColor(level)
		r, g, b = col.r, col.g, col.b
	end

	row.text:SetTextColor(r * fade, g * fade, b * fade)
	row.right:SetTextColor(r * fade, g * fade, b * fade)

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
	for i, q in pairs(self.quests) do
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
	for oid, o in pairs(self.objectives) do
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
	for oid, o in pairs(self.objectives) do
		o:Show()
	end
	self.visible = true
end

function quest_proto:Remove(oid, obj)
	if type(obj) == "string" then
		obj = self.objectivesByName[obj]
	end

	if not oid and obj then
		for k, v in pairs(self.objectives) do
			if v == obj then
				oid = k
				break
			end
		end
	end

	if not(obj and oid) then return end

	obj:Hide()

	table.remove(self.objectives, oid)
	self.objectivesByName[obj.name] = nil
	self.objectivesCount = self.objectivesCount - 1
end

function quest_proto:RemoveAll()
	for oid, obj in pairs(self.objectives) do
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

	local row = newRow(objective_proto)

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

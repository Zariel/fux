local parent, ns = ...
local Q = ns.Q
local fux = ns.fux

local prototypes = ns.prototype
local proto = setmetatable(CreateFrame("Frame"), { __index = prototypes })

function proto:OnClick(button)
	if button == "LeftButton" then
		if self.visible then
			self:HideQuests()
		else
			self:ShowQuests()
		end
		fux:Reposition()
	end
end

function proto:OnEnter()
	self.text:SetTextColor(1, 1, 1)
	self.right:SetTextColor(1, 1, 1)
end

function proto:OnLeave()
	self.text:SetTextColor(ns.fux.fade, ns.fux.fade, ns.fux.fade)
	self.right:SetTextColor(ns.fux.fade, ns.fux.fade, ns.fux.fade)
end

function proto:RemoveAll()
	for qid, quest in pairs(self.quests) do
		self:Remove(qid, quest)
	end
end

function proto:HideQuests()
	self.text:SetText("+" .. self.name)

	for qid, q in pairs(self.quests) do
		-- Hide objs also
		q:HideObjectives()
		q:Hide()
	end

	self.visible = false
end

function proto:ShowQuests()
	self.text:SetText("-" .. self.name)

	for qid, q in pairs(self.quests) do
		q:Show()
		q:ShowObjectives()
	end

	self.visible = true
end

function proto:Remove()
	for i = 1, #self.parent.zones do
		if(self.parent.zones[i] == self) then
			table.remove(self.parent.zones, i)
			break
		end
	end

	self.parent.zones[self.name] = nil
	self.parent.zoneCount = self.parent.zoneCount - 1

	self:DelRow()
end

-- Quest Creation
function proto:AddQuest(uid, name, level, tag, status)
	local row = self.questsByName[name]
	if(row) then
		if(status) then
			row.status = status
			row.right:SetText(status)
		end

		return row
	end

	row = prototypes.quest:NewRow()

	row.text:SetText(string.format("[%s] %s", tag and level .. tag or level, name))

	row.name = name
	row.level = level
	row.type = "quest"
	row.status = status
	row.visible = true
	row.daily = tag == "*"

	local r, g, b
	if(row.daily) then
		r, g, b = 62/255, 174/255, 1
	else
		local col = GetQuestDifficultyColor(level)
		r, g, b = col.r, col.g, col.b
	end

	row.text:SetTextColor(r * ns.fux.fade, g * ns.fux.fade, b * ns.fux.fade)
	row.right:SetTextColor(r * ns.fux.fade, g * ns.fux.fade, b * ns.fux.fade)

	if(status) then
		row.right:SetText(status)
	end

	row.id = self.questCount
	row.uid = uid

	row.parent = self

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

	self.questCount = self.questCount + 1
	table.insert(self.quests, pos, row)
	self.questsByName[name] = row

	return row
end

-- Can probably parent these off

prototypes.zone = proto

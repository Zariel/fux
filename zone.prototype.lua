local parent, ns = ...
local Q = ns.Q
local fux = ns.fux

local proto = CreateFrame("Frame")
local prototypes = ns.prototype

function proto:OnClick(button)
	if button == "LeftButton" then
		if self.visible then
			self:HideAll()
		else
			self:ShowAll()
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

function proto:HideAll()
	self.text:SetText("+" .. self.name)

	for qid, q in pairs(self.quests) do
		-- Hide objs also
		q:HideAll()
	end

	self.visible = false
end

function proto:ShowAll()
	self.text:SetText("-" .. self.name)

	for qid, q in pairs(self.quests) do
		q:Show()
		q:ShowAll()
	end

	self.visible = true
end

-- Quest Creation
function proto:AddQuest(uid, name, level, tag, status)
	if self.questsByName[name]then
		if(status) then
			self.questsByName[name].right:SetText(status)
		end
		return self.questsByName[name]
	end

	local row = prototypes.quest:New()

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

	if status then
		row.status = status
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
function proto:New(height)
	return prototypes.NewRow(self, height)
end

function proto:Del()
	return prototypes.DelRow(self)
end

prototypes.zone = proto

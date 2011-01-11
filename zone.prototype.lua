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
	for qid, quest in pairs(self.children) do
		self:Remove(qid, quest)
	end
end

function proto:HideQuests()
	self.text:SetText("+" .. self.name)

	for qid, q in pairs(self.children) do
		-- Hide objs also
		q:HideObjectives()
		q:Hide()
	end

	self.visible = false
end

function proto:ShowQuests()
	self.text:SetText("-" .. self.name)

	for qid, q in pairs(self.children) do
		q:Show()
		q:ShowObjectives()
	end

	self.visible = true
end

-- Quest Creation
function proto:AddQuest(uid, name, level, tag, status)
	name = strtrim(name)
	local row = self.childrenByName[name]
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
	row.uid = uid

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

	row.parent = self

	self.childrenByName[name] = row
	table.insert(self.children, row)
	table.sort(self.children, function(a, b)
		if(a.level == b.level) then
			return a.name < b.name
		else
			return a.level < b.level
		end
	end)

	return row
end

-- Can probably parent these off

proto.__name = "zone"
prototypes.zone = proto

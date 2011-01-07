local parent, ns = ...

local parent, ns = ...
local Q = ns.Q
local fux = ns.fux

local proto = CreateFrame("Frame")
local prototypes = ns.prototype

local tip = GameTooltip

-- Quest Script Handlers
function proto:OnClick(button)
	if(button == "LeftButton") then
		if IsAltKeyDown() then
			if self.visible then
				self:HideObjectives()
			else
				self:ShowObjectives()
			end

			fux:Reposition()
		else
			Q:ShowQuestLog(self.uid)
		end
	end
end

function proto:OnEnter()
	local r, g, b
	if self.daily then
		r, g, b = 62/255, 174/255, 1
	else
		local col = GetQuestDifficultyColor(self.level)
		r, g, b = col.r, col.g, col.b
	end

	self.text:SetTextColor(r, g, b)
	self.right:SetTextColor(r, g, b)

	tip:SetOwner(fux.frame, "ANCHOR_NONE")
	tip:SetPoint("TOPLEFT", fux.frame, "TOPRIGHT")

	local need, got = 0, 0
	for oid, obj in pairs(self.objectives) do
		need = need + obj.need
		got = got + obj.got
	end

	tip:ClearLines()
	tip:AddDoubleLine(string.format("[%d] %s", self.level, self.name), self.status and self.status or need > 0 and got .. "/" .. need, r, g, b, r, g, b)

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

function proto:OnLeave()
	local r, g, b
	if self.daily then
		r, g, b = 62/255, 174/255, 1
	else
		local col = GetQuestDifficultyColor(self.level)
		r, g, b = col.r, col.g, col.b
	end

	self.text:SetTextColor(r * ns.fux.fade, g * ns.fux.fade, b * ns.fux.fade)
	self.right:SetTextColor(r * ns.fux.fade, g * ns.fux.fade, b * ns.fux.fade)

	if tip:IsOwned(fux.frame) then
		tip:Hide()
	end
end

function proto:HideObjectives()
	for oid, o in pairs(self.objectives) do
		o:Hide()
	end

	local need, got = 0, 0
	for oid, obj in pairs(self.objectives) do
		need = need + obj.need
		got = got + obj.got
	end

	if(self.parent.status) then
		self.right:SetText(self.parent.status)
	elseif(need > 0) then
		if(got == need) then
			self.right:SetText("(done)")
		else
			self.right:SetText(got .. "/" .. need)
		end
	end

	self.visible = false
end

function proto:ShowObjectives()
	if self.status ~= "(done)" and self.status ~= "(failed)" then
		self.right:SetText("")
	end

	for oid, o in pairs(self.objectives) do
		o:Show()
	end

	self.visible = true
end

-- Remove quest
function proto:Remove()
	for i = 1, #self.parent.quests do
		if(self.parent.quests[i] == self) then
			table.remove(self.parent.quests, i)
			break
		end
	end

	for oid, obj in pairs(self.objectives) do
		obj:Remove()
	end

	self.parent.questsByName[self.name] = nil
	self.parent.questCount = self.parent.questCount - 1

	self:Del()
end

-- Objective creation
function proto:AddObjective(qid, name, got, need)
	if(not name or strtrim(name) == "") then return error("No objective name for quest ", qid) end

	if(self.objectivesByName[name]) then
		if(got and need) then
			local obj = self.objectivesByName[name]
			obj.right:SetText(got .. "/" .. need)
			obj.got = got
			obj.need = need
		end

		-- Is this right?
		if(not self.visible and self.need > 0) then
			self.right:SetText(self.got .. "/" .. self.need)
		end

		return self.objectivesByName[name]
	end

	local row = prototypes.objective:New()

	row.text:SetText(name)
	row.right:SetText(got .. "/" .. need)

	row.text:SetTextColor(0.7 * ns.fux.fade, 0.7 * ns.fux.fade, 0.7 * ns.fux.fade)
	row.right:SetTextColor(0.7 * ns.fux.fade, 0.7 * ns.fux.fade, 0.7 * ns.fux.fade)

	row.name = name
	row.got = got
	row.need = need

	row.id = self.objectivesCount
	row.type = "objective"
	row.qid = qid

	row.parent = self

	local pos = 1
	for i = 1, #self.objectives do
		pos = i
		if self.objectives[i].name < name then
			break
		end
	end

	table.insert(self.objectives, pos, row)
	self.objectivesCount = self.objectivesCount + 1
	self.objectivesByName[name] = row

	return row
end

function proto:New(height)
	return prototypes.NewRow(self, height)
end

function proto:Del()
	return prototypes.DelRow(self)
end

prototypes.quest = proto

local parent, ns = ...

local parent, ns = ...
local Q = ns.Q
local fux = ns.fux

local prototypes = ns.prototype
local proto = setmetatable(CreateFrame("Frame"), { __index = prototypes })

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
	for oid, obj in pairs(self.children) do
		need = need + obj.need
		got = got + obj.got
	end

	tip:ClearLines()
	tip:AddDoubleLine(string.format("[%d] %s", self.level, self.name), self.status and self.status or need > 0 and got .. "/" .. need, r, g, b, r, g, b)

	tip:AddLine(select(2, Q:GetQuestText(self.uid)), 0.8, 0.8, 0.8, true)
	if #self.children > 0 then
		tip:AddLine("")

		for oid, obj in ipairs(self.children) do
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
	for oid, o in pairs(self.children) do
		o:Hide()
	end

	local need, got = 0, 0
	for oid, obj in pairs(self.children) do
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

	for oid, o in pairs(self.children) do
		o:Show()
	end

	self.visible = true
end

-- Objective creation
function proto:AddObjective(qid, name, got, need)
	name = strtrim(name)
	if(not name or name == "") then return end

	local row = self.childrenByName[name]
	if(row) then
		if(got and need) then
			row.right:SetText(got .. "/" .. need)
			row.got = got
			row.need = need
		end

		return row
	end

	row = prototypes.objective:NewRow()

	row.text:SetText(name)
	row.right:SetText(got .. "/" .. need)

	row.text:SetTextColor(0.7 * ns.fux.fade, 0.7 * ns.fux.fade, 0.7 * ns.fux.fade)
	row.right:SetTextColor(0.7 * ns.fux.fade, 0.7 * ns.fux.fade, 0.7 * ns.fux.fade)

	row.name = name
	row.got = got
	row.need = need

	row.type = "objective"
	row.qid = qid

	row.parent = self

	table.insert(self.children, row)
	table.sort(self.children, function(a, b)
		return a.name < b.name
	end)

	self.childrenByName[name] = row

	return row
end

proto.__name = "quest"
prototypes.quest = proto

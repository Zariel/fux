local fux = LibStub("AceAddon-3.0"):NewAddon("Fux")
local Q = LibStub("LibQuixote-2.0")

function fux:OnInitialize()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetHeight(425)
	f:SetWidth(300)
	f:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})
	f:SetBackdropColor(0, 0, 0, 0.8)

	f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -500)
	f:Show()

	local t = f:CreateFontString(nil, "OVERLAY")
	t:SetPoint("TOP", f, "TOP", 0, -3)
	t:SetPoint("LEFT")
	t:SetPoint("RIGHT")
	t:SetFont(STANDARD_TEXT_FONT, 16)
	t:SetText("Fux Title")

	f.title = t

	self.frame = f
end

function fux:OnEnable()
	self.zones = {}
	self.zonesByName = {}
	self.zoneCount = 0

	self.zoneIndent = 5
	self.questIndet = 10
	self.objIndent = 10

	Q.RegisterCallback(self, "Update", "QuestUpdate")
	self:QuestUpdate()
end

function fux:Purge(uid)
	for id, zone in ipairs(self.zones) do
		for qid, quest in ipairs(zone.quests) do
			for oid, obj in ipairs(quest.objectives) do
				if obj.uid ~= uid then
					obj:Hide()
					table.remove(quest.objectives, oid)
					quest.objectivesByName[obj.name] = nil
					quest.objectivesCount = quest.objectivesCount - 1
				end
			end

			if quest.uid ~= uid then
				quest:Hide()
				table.remove(zone.quests, qui)
				zone.questsByName[quest.name] = nil
				zone.questCount = zone.questCount - 1
			end
		end

		-- TODO: Later cache these
		if zone.uid ~= uid then
			zone:Hide()
			table.remove(self.zones, id)
			self.zonesByName[zone.name] = nil
			self.zonesCount = self.zonesCount - 1
		end
	end

	self:Reposition()
end

function fux:QuestUpdate()
	local id = GetTime()
	for _, z, n in Q:IterateZones() do
		local zone = self:NewZone(z)
		zone.uid = id

		for _, uid, qid, title, level, objectives, complete in Q:IterateQuestsInZone(z) do
			local quest = zone:AddQuest(title, level, "stuff")
			quest.uid = id
			--[[if objectives and objectives > 0 then
				for _, objective, got, need, t in Q:IterateObjectivesForQuest(uid) do
					local status = got .. "/" .. need
					local obj = quest:AddObjective(name, status)
					obj.uid = id
				end
			end]]
		end
	end
	self:Purge(id)
end

-- MADNESS ENSUES
function fux:Reposition()
	local height = 50
	local width = 250

	for id, zone in ipairs(self.zones) do
		height = height + 16

		if id == 1 then
			zone:ClearAllPoints()
			zone:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, - 30)
		end

		local last
		if zone.visible then
			table.sort(zone.quests, function(a, b)
				return a.level < b.level
			end)

			for qid, quest in ipairs(zone.quests) do
				height = height + 14

				local ll, lr = quest.text:GetStringWidth(), quest.right:GetStringWidth()
				ll = math.max(250, ll)
				width = math.max(width, ll + lr)

				quest:ClearAllPoints()

				if qid == 1 then
					quest:SetPoint("TOPLEFT", zone, "BOTTOMLEFT", 10, - 3)
				else
					local prev = zone.quests[qid - 1]

					if prev.objectivesCount > 1 then
						local obj = prev.objectives[prev.objectivesCount]
						quest:SetPoint("TOP", obj, "BOTTOM", 0, - 3)
					else
						quest:SetPoint("TOP", prev, "BOTTOM", 0, - 3)
					end

					quest:SetPoint("LEFT", self.frame, "LEFT", 15, 0)
				end

				last = quest

				for oid, obj in ipairs(quest.objectives) do
					height = height + 12
					obj:ClearAllPoints()

					if oid == 1 then
						obj:SetPoint("TOPLEFT", quest, "BOTTOMLEFT", 5, - 3)
					else
						local prev = quest.objectives[oid - 1]
						obj:SetPoint("TOP", prev, "BOTTOM", 0, - 3)
						obj:SetPoint("LEFT", self.frame, "LEFT", 20, 0)
					end

					last = obj
				end
			end
		end

		if last then
			local next = self.zones[id + 1]
			if next then
				next:ClearAllPoints()
				next:SetPoint("TOP", last, "BOTTOM", 0, - 3)
				next:SetPoint("LEFT", self.frame, "LEFT", 5, 0)
			end
		end
	end

	self.frame:SetHeight(height)
	self.frame:SetWidth(width)
end

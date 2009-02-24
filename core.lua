local fux = LibStub("AceAddon-3.0"):NewAddon("Fux")
local Q = LibStub("LibQuixote-2.0")

function fux:OnInitialize()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetHeight(300)
	f:SetWidth(200)
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
				end
			end

			if quest.uid ~= uid then
				quest:Hide()
				table.remove(zone.quests, qui)
				zone.questsByName[quest.name] = nil
			end
		end

		-- TODO: Later cache these
		if zone.uid ~= uid then
			zone:Hide()
			table.remove(self.zones, id)
			self.zonesByName[zone.name] = nil
		end
	end

	self:Reposition()
end

function fux:QuestUpdate()
	local id = GetTime()
	for _, z, n in Q:IterateZones() do
		local zone = self:NewZone(z)
		zone.uid = zone

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
	--self:Purge(id)
end


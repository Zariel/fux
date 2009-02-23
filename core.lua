local fux = LibStub("AceAddon-3.0"):NewAddon("Fux")
local quixote = LibStub("LibQuixote-2.0")

function fux:OnEnable()
	self.Zones = {}
	self.ZonesByName = {}
	self.zoneCount = 0

	quixote.RegisterCallback(self, "Quixote_Update", "QuestUpdate")
end

function fux:Bind(class, proto)
	local meta = getmetatable(class)
	setmetatable(meta, proto)
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
			self.ZonesByName[zone.name] = nil
		end
	end

	self:Reposition()
end

function fux:QuestUpdate()
	local id = GetTime()
	for _, z, n in quixote:IterateZones() do
		local zone = self:NewZone(z)
		zone.uid = zone

		for _, uid, qid, title, level, objectives, complete in quixote:IterateQuestsInZone(z) do
			local quest = zone:AddQuest(title, level, "stuff")
			quest.uid = id
			if objectives > 0 then
				for _, objective, got, need, t in quixote:IterateObjectivesForQuest(uid) do
					local status = got .. "/" .. need
					local obj = quest:AddObjective(name, status)
					obj.uid = id
				end
			end
		end
	end
	self:Purge(id)
end


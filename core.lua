local fux = LibStub("AceAddon-3.0"):NewAddon("Fux", "AceEvent-3.0")
local Q = LibStub("LibQuixote-2.0")

function fux:OnInitialize()
	_G.Fuxdb = _G.Fuxdb or {
			x = 0,
			y = 500,
		}

	self.db = _G.Fuxdb
	_G.Fuxdb = self.db

	local f = CreateFrame("Frame", nil, UIParent)
	f:SetHeight(425)
	f:SetWidth(300)
	f:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})
	f:SetBackdropColor(0, 0, 0, 0.8)

	f:SetClampedToScreen(true)
	f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", fux.db.x, fux.db.y)
	f:EnableMouse(true)
	f:SetMovable(true)

	f:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and IsAltKeyDown() then
			self:ClearAllPoints()
			self:StartMoving()
		end
	end)

	f:SetScript("OnMouseUp", function(self, button)
		local x,y = self:GetLeft(), self:GetTop()
		fux.db.x = x
		fux.db.y = y

		self:StopMovingOrSizing()
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	end)

	f:Show()

	local t = f:CreateFontString(nil, "OVERLAY")
	t:SetPoint("TOP", f, "TOP", 0, -3)
	t:SetPoint("LEFT")
	t:SetPoint("RIGHT")
	t:SetFont(STANDARD_TEXT_FONT, 16)
	t:SetText("Fux Title")
	t:SetTextColor(0.8, 0.8, 0.8)

	f.title = t

	self.frame = f
end

function fux:OnEnable()
	local q = _G.QuestWatchFrame
	q:Hide()
	q.Show = function() end
	q:UnregisterAllEvents()

	self.zones = {}
	self.zonesByName = {}
	self.zoneCount = 0

	self.zoneIndent = 5
	self.questIndet = 10
	self.objIndent = 10

	Q.RegisterCallback(self, "Update", "QuestUpdate")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "Init")
end

function fux:Purge(tid)
	for id, zone in ipairs(self.zones) do
		for qid, quest in ipairs(zone.quests) do
			for oid, obj in ipairs(quest.objectives) do
				if obj.tid ~= tid then
					quest:Remove(oid, obj)
				end
			end

			if quest.tid ~= tid then
				zone:Remove(qid, quest)
			end
		end

		-- TODO: Later cache these
		if zone.tid ~= tid then
			zone:Hide()
			table.remove(self.zones, id)
			self.zonesByName[zone.name] = nil
			self.zoneCount = self.zoneCount - 1
		end
	end

	self:Reposition()
end

function fux:Init()
	local current = GetRealZoneText()

	for id, zone in ipairs(self.zones) do
		if zone.name ~= current then
			zone:HideAll()
		else
			zone:ShowAll()
		end
	end

	self:Reposition()

	self.init = true
end

function fux:QuestUpdate()
	local q = Q:GetNumQuests()
	self.frame.title:SetText("Fux - " .. q .. "/25")

	local id = GetTime()
	for _, z, n in Q:IterateZones() do
		local zone = self:NewZone(z)
		zone.tid = id

		for _, uid, qid, title, level, tag, objectives, complete in Q:IterateQuestsInZone(z) do
			local quest = zone:AddQuest(uid, title, level, complete and "(done)")
			quest.tid = id
			quest.got, quest.need = 0, 0
			if objectives and objectives > 0 and not complete then
				for name, got, need in Q:IterateObjectivesForQuest(uid) do
					quest.got = quest.got + got
					quest.need = quest.need + need
					if got ~= need then
						local obj = quest:AddObjective(qid, name, got, need)
						obj.tid = id
					end
				end
			end
		end
	end

	if not self.init then
		self:Init()
	end

	self:Purge(id)
end

-- MADNESS ENSUES
function fux:Reposition()
	local height = 25
	local width = 150

	for id, zone in ipairs(self.zones) do
		height = height + 16
		width = math.max(math.max(math.floor(zone.text:GetStringWidth()), 150), width)
		zone:SetWidth(width - 5)

		if id == 1 then
			zone:ClearAllPoints()
			zone:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, - 20)
		end

		local last = zone
		if zone.visible then
			for qid, quest in ipairs(zone.quests) do
				last = quest

				height = height + 14
				local l = math.max(math.floor(quest.text:GetStringWidth()) + 15, 150) + math.floor(quest.right:GetStringWidth()) + 30
				width = math.max(width, l)

				quest:SetWidth(width - 30)
				quest.right:SetPoint("RIGHT", self.frame, - 15, 0)
				quest:ClearAllPoints()

				if qid == 1 then
					quest:SetPoint("TOPLEFT", zone, "BOTTOMLEFT", 10, 0)
				else
					local prev = zone.quests[qid - 1]

					if prev.visible and prev.objectivesCount > 0 then
						local obj = prev.objectives[prev.objectivesCount]
						quest:SetPoint("TOP", obj, "BOTTOM", 0, - 1)
					else
						quest:SetPoint("TOP", prev, "BOTTOM", 0, - 1)
					end

					quest:SetPoint("LEFT", self.frame, "LEFT", 15, 0)
				end
				if quest.visible then
					for oid, obj in ipairs(quest.objectives) do
						last = obj

						height = height + 13
						local l = math.max(math.floor(obj.text:GetStringWidth()) + 40, 150) + math.floor(obj.right:GetStringWidth()) + 40
						width = math.max(width, l)

						obj:SetWidth(width - 40)
						obj.right:SetPoint("RIGHT", self.frame, - 20, 0)
						obj:ClearAllPoints()

						if oid == 1 then
							obj:SetPoint("TOP", quest, "BOTTOM", 0, 0)
						else
							local prev = quest.objectives[oid - 1]
							obj:SetPoint("TOP", prev, "BOTTOM", 0, - 2)
						end

						obj:SetPoint("LEFT", self.frame, "LEFT", 20, 0)
					end
				end
			end
		end

		local next = self.zones[id + 1]
		if next then
			next:ClearAllPoints()
			next:SetPoint("TOP", last, "BOTTOM", 0, - 2)
			next:SetPoint("LEFT", self.frame, "LEFT", 5, 0)
		end
	end

	self.frame:SetHeight(height)
	self.frame:SetWidth(width)
end

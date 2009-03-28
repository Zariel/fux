local Q = LibStub("LibQuixote-2.0")

fux = {}
fux.events = CreateFrame("Frame")

fux.events:SetScript("OnEvent", function(self, event, ...)
	fux[event](fux, ...)
end)

fux.events:RegisterEvent("ADDON_LOADED")

local tags = {
	Dungeon = "d",
	Elite = "+",
	Daily = "*",
	Pvp = "p",
	Raid = "r",
	Heroic = "d+",
	Group = "g",
}

function fux:InitDB()
	local name, realm = UnitName("player"), GetRealmName()

	local data = {
		x = 0,
		y = 500,
		visible = true,
	}

	_G.Fuxdb = _G.Fuxdb or {}
	_G.Fuxdb[realm] = _G.Fuxdb[realm] or {}
	_G.Fuxdb[realm][name] = setmetatable(_G.Fuxdb[realm][name] or {}, { __index = data} )

	self.db = _G.Fuxdb[realm][name]

	return true
end

function fux:ADDON_LOADED(addon)
	if addon ~= "Fux" then return end

	self:InitDB()

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

	f:SetScript("OnShow", function(self)
		fux:QuestUpdate()
	end)

	f:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and IsAltKeyDown() then
			self:ClearAllPoints()
			self:StartMoving()
		end
	end)

	f:SetScript("OnMouseUp", function(self, button)
		local x, y = self:GetLeft(), self:GetTop()
		fux.db.x = x
		fux.db.y = y

		self:StopMovingOrSizing()
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	end)

	if self.db.visible then
		f:Show()
	else
		f:Hide()
	end

	local t = f:CreateFontString(nil, "OVERLAY")
	t:SetPoint("TOP", f, "TOP", 0, -3)
	t:SetPoint("LEFT")
	t:SetPoint("RIGHT")
	t:SetFont(STANDARD_TEXT_FONT, 16)
	t:SetText("Fux Title")
	t:SetTextColor(0.8, 0.8, 0.8)

	f.title = t

	self.frame = f

	self.events:UnregisterEvent("ADDON_LOADED")
	self:OnEnable()
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
	self.events:RegisterEvent("ZONE_CHANGED_NEW_AREA", "Init")
	self.ZONE_CHANGED_NEW_AREA = self.Init
	self.events:RegisterEvent("UNIT_LEVEL")
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
	if not self.db.visible then return end

	local q = Q:GetNumQuests()
	self.frame.title:SetText("Fux - " .. q .. "/25")

	if q == 0 then
		return self.frame:Hide()
	else
		self.frame:Show()
	end

	local id = GetTime()
	for _, z, n in Q:IterateZones() do
		local zone = self:NewZone(z)
		zone.tid = id

		for _, uid, qid, title, level, tag, objectives, complete in Q:IterateQuestsInZone(z) do
			if complete then
				complete = complete > 0 and "(done)" or complete < 0 and "(failed)" or nil
			end
			local quest = zone:AddQuest(uid, title, level, tag and tags[tag], complete)
			quest.tid = id
			quest.got, quest.need = 0, 0
			if objectives and objectives > 0 and not complete then
				for name, got, need in Q:IterateObjectivesForQuest(uid) do
					quest.got = quest.got + (got or 0)
					quest.need = quest.need + (need or 0)
					if got ~= need then
						local obj = quest:AddObjective(uid, name, got, need)
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
		--zone:SetWidth(width - 5)

		if id == 1 then
			zone:ClearAllPoints()
			zone:SetPoint("TOPLEFT", self.frame.title, "BOTTOMLEFT", 5, -1)
		end

		zone:SetPoint("RIGHT", self.frame, "RIGHT")

		local last = zone
		if zone.visible then
			for qid, quest in ipairs(zone.quests) do
				last = quest

				height = height + 14
				local l = math.max(math.floor(quest.text:GetStringWidth()) + 15, 150) + math.floor(quest.right:GetStringWidth()) + 30
				width = math.max(width, l)

				quest:ClearAllPoints()
				quest:SetPoint("RIGHT", self.frame, - 10, 0)

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

						height = height + 12
						local l = math.max(math.floor(obj.text:GetStringWidth()) + 40, 150) + math.floor(obj.right:GetStringWidth()) + 40
						width = math.max(width, l)

						obj:ClearAllPoints()

						if oid == 1 then
							obj:SetPoint("TOP", quest, "BOTTOM", 0, 0)
						else
							local prev = quest.objectives[oid - 1]
							obj:SetPoint("TOP", prev, "BOTTOM", 0, 0)
						end

						obj:SetPoint("LEFT", self.frame, "LEFT", 20, 0)
						obj:SetPoint("RIGHT", self.frame, - 10, 0)
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

function fux:UNIT_LEVEL(unit)
	if unit ~= "player" then return end

	for id, zone in ipairs(self.zones) do
		for qid, quest in ipairs(zone.quests) do
			local col = GetDifficultyColor(quest.level)
			quest.text:SetTextColor(col.r * self.fade, col.g * self.fade, col.b * self.fade)
			quest.right:SetTextColor(col. r * self.fade, col.g * self.fade, col.b * self.fade)
		end
	end
end


function SlashCmdList.FUX()
	if fux.frame:IsShown() then
		fux.db.visible = false
		fux.frame:Hide()
	else
		fux.db.visible = true
		fux.frame:Show()
	end
end

SLASH_FUX1 = "/fux"

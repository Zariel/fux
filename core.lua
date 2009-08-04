local Q = LibStub("LibQuixote-2.0")
local pairs = pairs
local ipairs = ipairs

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
	self.ADDON_LOADED = nil

	self:OnEnable()
end

function fux:OnEnable()
	local q = _G.WatchFrameLines
	q.Show = function() end
	q:Hide()

	self.zones = {}
	self.zonesByName = {}
	self.zoneCount = 0

	self.zoneIndent = 5
	self.questIndet = 10
	self.objIndent = 10

	Q.RegisterCallback(self, "Update", "QuestUpdate")
	Q.RegisterCallback(self, "Quest_Abandoned", "QuestAbandoned")
	Q.RegisterCallback(self, "Quest_Gained", "QuestGained")
	Q.RegisterCallback(self, "Objective_Update", "ObjectiveUpdate")
	Q.RegisterCallback(self, "Quest_Complete", "QuestComplete")
	Q.RegisterCallback(self, "Quest_Failed", "QuestFailed")
	Q.RegisterCallback(self, "Quest_Lost", "QuestAbandoned")

	self.events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self.ZONE_CHANGED_NEW_AREA = self.Init
	self.events:RegisterEvent("UNIT_LEVEL")
end

function fux:GetZone(uid)
	if Q:GetQuestByUid(uid) then
		return select(10, Q:GetQuestByUid(uid))
	end

	return
end

function fux:QuestAbandoned(event, name, uid, zone)
	zone = zone or self:GetZone(uid)

	if not zone or not self.zonesByName[zone] then return end

	zone = self.zonesByName[zone]

	local dirty = false
	-- Do we still have it?
	if zone.questsByName[name] then
		zone:Remove(nil, name)
		dirty = true
	end

	if #zone.quests == 0 then
		self:RemoveZone(nil, zone)
		dirty = true
	end

	if dirty then
		self:Reposition()
	end
end

function fux:QuestGained(event, title, uid, obj, zone)
	zone = self:NewZone(zone)

	local uid, id, title, level, tag = Q:GetQuestByUid(uid)

	local quest = zone:AddQuest(uid, title, tonumber(level), tags[tag])
	self:ObjectiveUpdate(event, title, uid)

	if event then
		self:Reposition()
	end
end

function fux:QuestFailed(event, name, uid)
	local zone = self:GetZone(uid)

	if not zone or not self.zonesByName[zone] then return end

	zone = self.zonesByName[zone]
	local quest = zone:AddQuest(uid, name, nil, nil, "(failed)")
end

function fux:QuestComplete(event, name, uid)
	local zone = self:GetZone(uid)
	if not zone or not self.zonesByName[zone] then return end

	zone = self.zonesByName[zone]
	local quest = zone:AddQuest(uid, name, nil, nil, "(done)")
end

-- Still causes a full obj update
function fux:ObjectiveUpdate(event, title, uid, desc, old, got, need)
	local zone = self:GetZone(uid)

	zone = self:NewZone(zone)

	local uid, id, title, level, tag = Q:GetQuestByUid(uid)
	local quest = zone:AddQuest(uid, title, tonumber(level), tags[tag])

	quest.got = quest.got + (tonumber(got) or 0)
	quest.need = quest.need + (tonumber(need) or 0)

	if got ~= need then
		quest:AddObjective(uid, desc, got, need)
	else
		quest:Remove(nil, desc)
	end

	if event then
		self:Reposition()
	end
end

function fux:Init()
	local sub, cur = GetMinimapZoneText(), GetRealZoneText()
	for id, zone in pairs(self.zones) do
		if zone.name == sub or zone.name == cur then
			zone:ShowAll()
		else
			zone:HideAll()
		end
	end

	self:Reposition()

	self.init = true
end

function fux:QuestUpdate()
	Q.UnregisterCallback(self, "Update")
	local q = Q:GetNumQuests()

	local completed = 0
	local zone, quest, obj
	for _, z, n in Q:IterateZones() do
		for _, uid, qid, title, level, tag, objectives, complete in Q:IterateQuestsInZone(z) do
			self:QuestGained(nil, title, uid, objectives, z)

			if complete then
				if complete > 0 then
					self:QuestComplete(nil, title, uid)
				elseif compelte < 0 then
					self:QuestFailed(nil, title, uid)
				end
			end

			if objectives and objectives > 0 and not complete then
				for name, got, need in Q:IterateObjectivesForQuest(uid) do
					fux:ObjectiveUpdate(nil, title, uid, name, nil, got, need)
				end
			end
		end
	end

	if not self.init then self:Init() end
end

-- MADNESS ENSUES
function fux:Reposition()
	local height = 25
	local width = 150

	for id, zone in ipairs(self.zones) do
		height = height + 16
		width = math.max(math.max(math.floor(zone.text:GetStringWidth()) + 20, 150), width)
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
		if next and last then
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

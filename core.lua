local parent, ns = ...

local pairs = pairs
local ipairs = ipairs

local Q = ns.Q
local fux = ns.fux
fux.fade = 0.7

local prototypes = ns.prototype

fux:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, ...)
end)

fux:RegisterEvent("ADDON_LOADED")

local failed_obj = {}

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
	_G.Fuxdb[realm][name] = setmetatable(_G.Fuxdb[realm][name] or {}, { __index = data } )

	ns.db = _G.Fuxdb[realm][name]

	return true
end

local timer = 0
function fux:OnUpdate(elapsed)
	timer = timer + elapsed

	if(timer > 1) then
		for qid in pairs(failed_obj) do
			local uid, id, title, level, tag = Q:GetQuestByUid(qid)
			local failed = false
			for desc, got, need in Q:IterateObjectivesForQuest(qid) do
				-- ObjectiveUpdate(event, title, uid, desc, old, got, need)
				if(not self:ObjectiveUpdate(nil, title, uid, desc, nil, got, need)) then
					failed = true
				end
			end
			if(not failed) then
				failed_obj[qid] = nil
			end
		end

		if(#failed_obj == 0) then
			self:Hide()
		end
		timer = 0
	end
end

function fux:ADDON_LOADED(addon)
	if(addon ~= "Fux") then return end

	self:InitDB()

	self:SetScript("OnUpdate", self.OnUpdate)

	local f = CreateFrame("Frame", nil, UIParent)
	f:SetHeight(425)
	f:SetWidth(300)
	--[[f:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})]]
	f:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})
	f:SetBackdropColor(0, 0, 0, 0.8)

	f:SetClampedToScreen(true)
	f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ns.db.x, ns.db.y)
	f:EnableMouse(true)
	f:SetMovable(true)

	f:SetScript("OnShow", function()
		return fux:QuestUpdate()
	end)

	f:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and IsAltKeyDown() then
			self:ClearAllPoints()
			self:StartMoving()
		end
	end)

	f:SetScript("OnMouseUp", function(self, button)
		local x, y = self:GetLeft(), self:GetTop()
		ns.db.x = x
		ns.db.y = y

		self:StopMovingOrSizing()
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	end)

	if ns.db.visible then
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

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	self:OnEnable()
end

function fux:OnEnable()
	local q = _G.WatchFrameLines
	q.Show = function() end
	q:Hide()

	self.children = {}
	self.childrenByName = {}

	self.zoneIndent = 5
	self.questIndet = 10
	self.objIndent = 10

	for id, zone in Q:IterateZones() do
		self:NewZone(zone)
	end

	Q.RegisterCallback(self, "Update", "QuestUpdate")
	Q.RegisterCallback(self, "Quest_Abandoned", "QuestAbandoned")
	Q.RegisterCallback(self, "Quest_Gained", "QuestGained")
	Q.RegisterCallback(self, "Objective_Update", "ObjectiveUpdate")
	Q.RegisterCallback(self, "Quest_Complete", "QuestComplete")
	Q.RegisterCallback(self, "Quest_Failed", "QuestFailed")
	Q.RegisterCallback(self, "Quest_Lost", "QuestAbandoned")

	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self.ZONE_CHANGED_NEW_AREA = self.Init
	self:RegisterEvent("UNIT_LEVEL")

	if(not self.init) then
		self:Init()
	end
end

function fux:GetZone(uid)
	if Q:GetQuestByUid(uid) then
		return select(10, Q:GetQuestByUid(uid))
	end

	return
end

function fux:SetTitle()
	local q, c = Q:GetNumQuests()

	local str = c .. "/" .. q

	local d = GetDailyQuestsCompleted()
	if d > 0 then
		str = str .. " - (" .. d .. "/25)"
	end

	self.frame.title:SetText(str)
end

function fux:QuestAbandoned(event, name, uid, zone)
	local zone = self:NewZone(zone or self:GetZone(uid))
	local dirty = false
	-- Do we still have it?

	local q = zone.childrenByName[name]
	if(q) then
		-- REMOVE QUEST
		q:Remove()
		dirty = true
	end

	if(#zone.children == 0) then
		-- REMOVE ZONE
		zone:Remove()
		dirty = true
	end

	if(dirty) then
		self:Reposition()
	end

	self:SetTitle()
end

function fux:QuestGained(event, title, uid, obj, zone)
	local zone = self:NewZone(zone or self:GetZone(uid))

	local uid, id, title, level, tag, objs, complete = Q:GetQuestByUid(uid)

	local quest = zone:AddQuest(uid, title, tonumber(level), tags[tag])

	for o, got, need in Q:IterateObjectivesForQuest(uid) do
		self:ObjectiveUpdate(event, title, uid, o, nil, got or 0, need or 0)
	end

	self:Reposition()

	self:SetTitle()
end

function fux:QuestFailed(event, name, uid)
	local zone = self:NewZone(zone or self:GetZone(uid))
	local quest = zone:AddQuest(uid, name, nil, nil, "(failed)")

	for id, obj in pairs(quest.children) do
		obj:Remove()
	end

	self:Reposition()
	self:SetTitle()
end

function fux:QuestComplete(event, name, uid)
	local zone = self:NewZone(self:GetZone(uid))
	local quest = zone:AddQuest(uid, name, nil, nil, "(done)")

	for id, obj in pairs(quest.children) do
		obj:Remove()
	end

	self:Reposition()
	self:SetTitle()
end

-- Still causes a full obj update
function fux:ObjectiveUpdate(event, title, uid, desc, old, got, need)
	local zone = self:NewZone(self:GetZone(uid))

	local qid, id, title, level, tag = Q:GetQuestByUid(uid)
	local quest = zone:AddQuest(uid, title, tonumber(level), tags[tag])

	local failed = quest.status == "(failed)"
	local obj = quest:AddObjective(qid, desc, got, need)
	if(obj and (got >= need or failed)) then
		obj:Remove()
	elseif(not obj) then
		failed_obj[qid] = true
		self:Show()
		return
	end

	self:Reposition()

	return true
end

function fux:Init()
	local sub, cur = GetMinimapZoneText(), GetRealZoneText()
	for id, zone in pairs(self.children) do
		if(zone.name == sub or zone.name == cur) then
			zone:ShowQuests()
		else
			zone:HideQuests()
		end
	end

	self:Reposition()

	_G.WatchFrame:Hide()
	_G.WatchFrame.Show = function() end

	self.init = true
end

function fux:QuestUpdate()
	if(not self.init) then self:Init() end

	Q.UnregisterCallback(self, "Update")
	local q = Q:GetNumQuests()

	local zone, quest, obj
	for _, z, n in Q:IterateZones() do
		for _, uid, qid, title, level, tag, objectives, complete in Q:IterateQuestsInZone(z) do
			self:QuestGained(nil, title, uid, objectives, z)

			if(complete) then
				if complete > 0 then
					self:QuestComplete(nil, title, uid)
				elseif complete < 0 then
					self:QuestFailed(nil, title, uid)
				end
			end

			if objectives and objectives > 0 then
				for name, got, need in Q:IterateObjectivesForQuest(uid) do
					self:ObjectiveUpdate(nil, title, uid, name, nil, got, need)
				end
			end
		end
	end
end

-- MADNESS ENSUES
function fux:Reposition()
	local height = 25
	local width = 150

	for id, zone in ipairs(self.children) do
		height = height + 16
		width = math.max(math.max(math.floor(zone.text:GetStringWidth()) + 20, 150), width)
		--zone:SetWidth(width - 5)

		if(id == 1) then
			zone:SetPoint("TOPLEFT", self.frame.title, "BOTTOMLEFT", 5, -1)
		end

		zone:SetPoint("RIGHT", self.frame, "RIGHT")

		local last = zone
		if(zone.visible) then
			for qid, quest in ipairs(zone.children) do
				last = quest

				height = height + 14
				local l = math.max(math.floor(quest.text:GetStringWidth()) + 15, 150) + math.floor(quest.right:GetStringWidth()) + 30
				width = math.max(width, l)

				quest:ClearAllPoints()

				if(qid == 1) then
					quest:SetPoint("TOP", zone, "BOTTOM", 0, - 1)
				else
					local prev = zone.children[qid - 1]

					local objCount = #prev.children
					if(prev.visible and objCount > 0) then
						local obj = prev.children[objCount]
						quest:SetPoint("TOP", obj, "BOTTOM", 0, - 1)
					else
						quest:SetPoint("TOP", prev, "BOTTOM", 0, - 1)
					end
				end

				quest:SetPoint("LEFT", self.frame, "LEFT", 15, 0)
				quest:SetPoint("RIGHT", self.frame, - 10, 0)

				if(quest.visible) then
					for oid, obj in ipairs(quest.children) do
						last = obj

						height = height + 12
						local l = math.max(math.floor(obj.text:GetStringWidth()) + 40, 150) + math.floor(obj.right:GetStringWidth()) + 40
						width = math.max(width, l)

						obj:ClearAllPoints()

						if(oid == 1) then
							obj:SetPoint("TOP", quest, "BOTTOM", 0, 0)
						else
							local prev = quest.children[oid - 1]
							obj:SetPoint("TOP", prev, "BOTTOM", 0, 0)
						end

						obj:SetPoint("LEFT", self.frame, "LEFT", 20, 0)
						obj:SetPoint("RIGHT", self.frame, - 10, 0)
					end
				end
			end
		end

		local next = self.children[id + 1]
		if(next and last) then
			next:ClearAllPoints()
			next:SetPoint("TOP", last, "BOTTOM", 0, - 2)
			next:SetPoint("LEFT", self.frame, "LEFT", 5, 0)
		end
	end

	self.frame:SetHeight(height)
	self.frame:SetWidth(width)
end

function fux:UNIT_LEVEL(unit)
	if(unit ~= "player") then return end

	for id, zone in pairs(self.children) do
		for qid, quest in pairs(zone.children) do
			local col = GetQuestDifficultyColor(quest.level)
			quest.text:SetTextColor(col.r * self.fade, col.g * self.fade, col.b * self.fade)
			quest.right:SetTextColor(col. r * self.fade, col.g * self.fade, col.b * self.fade)
		end
	end
end

-- Zone Creation
function fux:NewZone(name)
	name = strtrim(name)
	local row = self.childrenByName[name]

	if(row) then
		return row
	end

	row = prototypes.zone:NewRow(14)

	row.text:SetText("-" .. name)
	row.text:SetTextColor(self.fade, self.fade, self.fade)

	row.name = name
	row.visible = true
	row.type = "zone"

	row.parent = self

	table.insert(self.children, row)
	table.sort(self.children, function(a, b)
		return a.name < b.name
	end)
	self.childrenByName[name] = row

	return row
end

function SlashCmdList.FUX()
	if fux.frame:IsShown() then
		ns.db.visible = false
		fux.frame:Hide()
	else
		ns.db.visible = true
		fux.frame:Show()
	end
end

fux.__name = "fux"

_G.fux = fux
_G.SLASH_FUX1 = "/fux"

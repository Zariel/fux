local fux = LibStub("AceAddon-3.0"):NewAddon("Fux")
local quixote = LibStub("LibQuixote-2.0")

function fux:OnEnable()
	self.Zones = {}
	self.ZonesByName = {}
	self.zoneCount = 0
end

function fux:Bind(class, proto)
	local meta = getmetatable(class)
	setmetatable(meta, proto)
end

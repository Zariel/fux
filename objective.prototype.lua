local parent, ns = ...
local Q = ns.Q

local prototypes = ns.prototype
local proto = setmetatable(CreateFrame("Frame"), { __index = prototypes })

function proto:OnClick(button)
	if(button == "LeftButton") then
		Q:ShowQuestLog(self.qid)
	end
end

function proto:OnEnter()
	self.text:SetTextColor(1, 1, 1)
	self.right:SetTextColor(1, 1, 1)
end

function proto:OnLeave()
	self.text:SetTextColor(0.7 * ns.fux.fade, 0.7 * ns.fux.fade, 0.7 * ns.fux.fade)
	self.right:SetTextColor(0.7 * ns.fux.fade, 0.7 * ns.fux.fade, 0.7 * ns.fux.fade)
end

function proto:Remove()
	for i = 1, #self.parent.objectives do
		if(self.parent.objectives[i] == self) then
			table.remove(self.parent.objectives, i)
			break
		end
	end

	self.parent.objectivesByName[self.name] = nil
	self.parent.objectivesCount = self.parent.objectivesCount - 1

	self:DelRow()
end

prototypes.objective = proto

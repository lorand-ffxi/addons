local texts = require('texts')

local InfoBox = {
	visible = true,
	settings = nil,
	tb_name = 'infoBoxes'
}
InfoBox.__index = InfoBox

setmetatable(InfoBox, {
	__call = function(cls, ...)
		return cls.new(...)
	end
})

function InfoBox.new(settings, label)
	local self = setmetatable({}, InfoBox)
	self.settings = settings
	self.text = texts.new(self.settings)
	self.label = label
	return self
end

function InfoBox:setPos(posx, posy)
	self.text:pos(posx, posy)
end

function InfoBox:refresh()
	if self.visible then
        self.text:show()
    else
        self.text:hide()
    end
end

function InfoBox:show()
	self.visible = true
	self:refresh()
end

function InfoBox:hide()
	self.visible = false
	self:refresh()
end

function InfoBox:updateContents(contents)
	self.contents = contents
	if self.label ~= nil then
		self.text:text(self.label..': '..self.contents)
	else
		self.text:text(self.contents)
	end
	self:show()
end

function InfoBox:destroy()
    self.text:destroy()
end

return InfoBox
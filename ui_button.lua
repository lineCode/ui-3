
--ui button widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'

local button = ui.layer:subclass'button'
ui.button = button

button.focusable = true
button.w = 100
button.h = 30
button.background_color = '#444'
button.border_color = '#888'
button.border_width = 1

ui:style('button', {
	transition_background_color = true,
	transition_border_color = true,
	transition_duration = .5,
	transition_ease = 'expo out',
})

ui:style('button hot', {
	background_color = '#999',
	border_color = '#999',
	text_color = '#000',
})

ui:style('button active over', {
	background_color = '#fff',
	border_color = '#fff',
	text_color = '#000',
	transition_duration = 0.2,
})

ui:style('button focused', {
	border_color = '#fff',
	shadow_blur = 3,
	shadow_color = '#666',
})

function button:mousedown()
	if self.active_by_key then return end
	self.active = true
end

function button:mousemove(mx, my)
	if self.active_by_key then return end
	local mx, my = self:to_parent(mx, my)
	self:settag('over', self:hit_test(mx, my, 'activate') == self)
end

function button:mouseup()
	if self.active_by_key then return end
	self.active = false
	if self.tags.over then
		self:fire'pressed'
	end
end

function button:keydown(key)
	if key == 'enter' or key == 'space' then
		self.active = true
		self.active_by_key = true
		self:settag('over', true)
	end
end

function button:keyup(key)
	if not self.active_by_key then return end
	if key == 'enter' or key == 'space' or key == 'esc' then
		self.active = false
		self.active_by_key = false
		self:settag('over', false)
		if key == 'enter' or key == 'space' then
			self:fire'pressed'
		end
	end
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local b1 = ui:button{
		parent = win,
		x = 100, y = 100, w = 100, h = 26,
		text = 'OK',
	}

	local btn = button:subclass'btn'

	local b2 = btn(ui, {
		parent = win,
		x = 100, y = 150, w = 100, h = 26,
		text = 'OK',
	})

	function b1:gotfocus() print'b1 got focus' end
	function b1:lostfocus() print'b1 lost focus' end
	function b2:gotfocus() print'b2 got focus' end
	function b2:lostfocus() print'b2 lost focus' end

	function b1:pressed() print'b1 pressed' end
	function b2:pressed() print'b2 pressed' end

end) end

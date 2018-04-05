
--slider widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local box2d = require'box2d'

local snap = glue.snap
local clamp = glue.clamp

ui.slider = ui.layer:subclass'slider'

ui.slider.isslider = true
ui.slider.focusable = true

ui.slider.border = ui.layer:subclass'slider_border'
ui.slider.border.h = 10
ui.slider.border.corner_radius = 5
ui.slider.border.border_width = 1
ui.slider.border.border_color = '#fff'
ui.slider.border.content_clip = true

ui.slider.fill = ui.layer:subclass'slider_fill'
ui.slider.fill.h = 10
ui.slider.fill.background_color = '#fff'

ui.slider.pin = ui.layer:subclass'slider_pin'
ui.slider.pin.w = 16
ui.slider.pin.h = 16
ui.slider.pin.corner_radius = 8
ui.slider.pin.border_width = 1
ui.slider.pin.border_color = '#fff'
ui.slider.pin.background_color = '#000'

ui.slider.step_label = ui.layer

function ui.slider.pin:drag(dx, dy)
	local cx = self.x + dx + self.corner_radius_top_left
	self.parent.position = self.parent:position_at_cx(cx)
end

ui.slider.h = 20
ui.slider._position = 0
ui.slider.size = 1
ui.slider.step = false --no stepping
ui.slider.snap_to_labels = true --...if there are any
ui.slider.step_labels = false --{label = value, ...}
ui.slider.background_color = '#0000'
ui.slider.drag_threshold = 0
ui.slider.step_line_h = 5
ui.slider.step_line_color = '#fff'

function ui.slider:pin_cx(pos)
	return ((pos or self.position) / self.size) * self.cw
end

function ui.slider:position_at_cx(cx)
	return clamp((cx / self.cw) * self.size, 0, self.size)
end

function ui.slider:_find_position(pos, choose)
	local ref_pos = pos or self.position
	local best_pos
	if self.snap_to_labels and self.step_labels then
		for label, pos in pairs(self.step_labels) do
			if choose(pos, best_pos, ref_pos) then
				best_pos = pos
			end
		end
	end
	if self.step then
		for pos = ref_pos - self.step, ref_pos + self.step, self.step do
			pos = snap(pos, self.step)
			if choose(pos, best_pos, ref_pos) then
				best_pos = pos
			end
		end
	end
	return clamp(best_pos or ref_pos, 0, self.size)
end

local function nearest_pos(pos, best_pos, ref_pos)
	return not best_pos or math.abs(pos - ref_pos) < math.abs(best_pos - ref_pos)
end
function ui.slider:snap_position(pos)
	return self:_find_position(pos, nearest_pos)
end

local function next_pos(pos, best_pos, ref_pos)
	return pos > ref_pos and (not best_pos or pos < best_pos)
end
function ui.slider:next_position(pos)
	return self:_find_position(pos, next_pos)
end

local function prev_pos(pos, best_pos, ref_pos)
	return pos < ref_pos and (not best_pos or pos > best_pos)
end
function ui.slider:prev_position(pos)
	return self:_find_position(pos, prev_pos)
end

function ui.slider:get_position()
	return self._position
end

function ui.slider:set_position(pos)
	local old_pos = self._position
	pos = pos or old_pos
	self._position = pos
	if self.updating then return end
	self._position = self:snap_position(pos)
	local br = self.border.corner_radius_top_left
	if not self.pin.dragging and self._position ~= old_pos then
		pos = self._position
	end
	local dt = self.pin.dragging and self.window.mouse_left and 0 or .5
	local sx = self:pin_cx(pos)
	local pw = select(4, self.pin:border_rect(1))
	self.pin:transition('x', sx - pw / 2, dt, 'expo out')
	self.fill:transition('w', sx + br, dt, 'expo out')
end

function ui.slider:leftmousedown(mx)
	self.active = true
	self.position = self:position_at_cx(mx)
	self:focus()
end

function ui.slider:leftmouseup()
	self.active = false
	self.position = self.position
end

function ui.slider:start_drag()
	return self.pin, self.pin.border_outer_w / 2, 0
end

function ui.slider:keypress(key)
	if key == 'left' or key == 'up' or key == 'pageup' then
		self.position = self:prev_position()
	elseif key == 'right' or key == 'down' or key == 'pagedown' then
		self.position = self:next_position()
	elseif key == 'home' then
		self.position = 0
	elseif key == 'end' then
		self.position = self.size
	end
end

function ui.slider:hit_test_content(x, y)
	local _, _, bw, bh = self.pin:border_rect(1)
	return box2d.hit(x, y, -bw/2, 0, self.cw + bw, self.ch) and self
end

function ui.slider:after_init()
	local br = self.border.corner_radius_top_left
	self.border = self.border(self.ui, {
		id = self:_subtag'border',
		x = -br,
		y = (self.h - self.border.h) / 2,
		w = self.cw + 2 * br,
		parent = self,
	})
	self.fill = self.fill(self.ui, {
		id = self:_subtag'fill',
		h = self.border.h,
		parent = self.border,
	})
	self.pin = self.pin(self.ui, {
		id = self:_subtag'pin',
		y = (self.h - self.pin.h) / 2,
		parent = self,
	})
	if self.step_labels then
		for label, value in pairs(self.step_labels) do
			self.step_label(self.ui, {
				x = self:pin_cx(value) - 100,
				y = self.h,
				w = 200,
				h = 20,
				text = label,
				id = self:_subtag'step_label',
				issteplabel = true,
				parent = self,
			})
		end
	end
	self.position = self.position
end

function ui.slider:step_lines_visible()
	return self.step and self.step_line_color and self.size / self.step >= 5
end

function ui.slider:draw_step_lines()
	if not self:step_lines_visible() then return end
	local cr = self.window.cr
	cr:rgba(self.ui:color(self.step_line_color))
	cr:line_width(1)
	cr:new_path()
	for pos = 0, self.size + self.step / 2, self.step do
		cr:move_to(self:pin_cx(math.min(pos, self.size)), self.h)
		cr:rel_line_to(0, self.step_line_h)
	end
	cr:stroke()
end

function ui.slider:after_draw_content()
	self:draw_step_lines()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	ui:style('slider focused', {
		border_color = '#fff',
	})

	ui:style('slider_fill', {
		background_type = 'gradient',
		background_colors = {'#f00', 1, '#00f'},
		background_extend = 'reflect',
		background_x1 = 0,
		background_y1 = 0,
		background_x2 = 5,
		background_y2 = 5,
	})

	ui:style('slider_pin hot', {
		border_offset = 1,
		transition_border_offset = true,
		transition_duration = .5,
		transition_ease = 'expo out',
	})

	ui:slider{
		x = 100, y = 100, w = 200, parent = win,
		position = 5, size = 10,
		step_labels = {Low = 0, Medium = 5, High = 10},
		border_color = '#0000',
		snap_to_labels = true,
		border_width = 1,
	}

	ui:slider{
		x = 100, y = 200, w = 200, parent = win,
		position = 5, size = 10,
		border_color = '#0000',
		step = 1.5,
		border_width = 1,
	}

end) end

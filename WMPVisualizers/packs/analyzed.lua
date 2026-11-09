local lib = require("lib")
local bins = require("packs.wmp_bins")

local GHOST = "shaders/analyzed/ghost.gdshader"

local DT = 2
local SMOOTH = math.min(1, 0.3 * DT)
local HOLD = 15
local GRAVITY = -0.2

local C800 = Color(0.2, 0.3, 0.7)
local C810 = Color(0.3, 0.4, 0.9)
local C820 = Color(0.1, 0.2, 0.4)
local C830 = Color(0.2, 0.3, 0.7)
local PEAK = Color(0.4, 0.5, 0.9)

local function new_bars(state)
	state.bars = {}
	state.top = {}
	state.speed = {}
	state.wait = {}
	for index = 1, 32 do
		state.bars[index], state.top[index], state.speed[index], state.wait[index] = 0, 0, 0, 0
	end
end

local function step_bars(state, audio)
	for index = 1, 32 do
		local total = 0
		for tap = 0, 7 do
			local position = (index - 1 + (tap + 0.5) / 8) / 32
			total = total + bins.linear(audio, position, 0) + bins.linear(audio, position, 1)
		end
		state.bars[index] = state.bars[index] + (total / 8 * 255 - state.bars[index]) * SMOOTH
		if state.wait[index] > 0 then
			state.wait[index] = state.wait[index] - DT
		else
			state.top[index] = state.top[index] + state.speed[index] * DT
			state.speed[index] = state.speed[index] + GRAVITY * DT
		end
		if state.bars[index] > state.top[index] then
			state.top[index] = state.bars[index]
			state.speed[index] = 0
			state.wait[index] = HOLD
		end
	end
end

local function box(canvas, x, y, width, height, top, bottom, ghost)
	if ghost then
		canvas:draw_rect(Rect2(x, y, width, 1), top)
		canvas:draw_rect(Rect2(x, y + height - 1, width, 1), bottom)
		canvas:draw_rect(Rect2(x, y + 1, 1, height - 2), top)
		canvas:draw_rect(Rect2(x + width - 1, y + 1, 1, height - 2), top)
	elseif top == bottom then
		canvas:draw_rect(Rect2(x, y, width, height), top)
	else
		canvas:draw_polygon({ Vector2(x, y), Vector2(x + width, y), Vector2(x + width, y + height), Vector2(x, y + height) }, { top, top, bottom, bottom })
	end
end

local function line(canvas, state, scene, ghost)
	local width, height = scene.width, scene.height
	local scale = height / 384
	local slot = (width - 2) / 32
	for index = 1, 32 do
		local x = math.floor((index - 1) * slot + scale * 2)
		local size = slot * 0.8
		local tall = state.bars[index] * scale
		box(canvas, x, height - 2 - tall, size, tall, lib.mix(C820, C800, tall / height), C820, ghost)
		box(canvas, x, height - 2 - state.top[index] * scale - slot * 0.25, size, slot * 0.25, PEAK, PEAK, ghost)
	end
end

local function mirror(canvas, state, scene, ghost)
	local width, height = scene.width, scene.height
	local scale = height / 384
	local slot = (width - 2) / 32
	for index = 1, 32 do
		local mixed = (index - 1) / 32
		local top = lib.mix(C800, C810, mixed)
		local bottom = lib.mix(C820, C830, mixed)
		local x = math.floor((index - 1) * slot + scale * 2)
		local size = slot * 0.8
		local tall = state.bars[index] * scale
		box(canvas, x, height * 0.5 - tall * 0.5, size, tall, lib.mix(bottom, top, tall / height), bottom, ghost)
		local peak = state.top[index] * scale * 0.5
		box(canvas, x, height * 0.5 - peak - slot * 0.25, size, slot * 0.25, PEAK, PEAK, ghost)
		box(canvas, x, height * 0.5 + peak, size, slot * 0.25, PEAK, PEAK, ghost)
	end
end

local function digital(canvas, state, scene, ghost)
	local width, height = scene.width, scene.height
	local scale = height / 384
	local slot = (width - 2) / 32
	local cell = slot * 0.25
	local margin = scale * 2
	local pitch = margin + cell
	for index = 1, 32 do
		local mixed = (index - 1) / 32
		local dark = lib.mix(C820, C830, mixed)
		local bright = lib.mix(C800, C810, mixed)
		local x = math.floor((index - 1) * slot + margin)
		local size = slot * 0.8
		local count = state.bars[index] * scale / pitch
		local level = 0
		while level < count do
			local y = height - level * pitch - margin - cell
			local color = lib.mix(dark, bright, y / height)
			if count - level < 1 then
				color = lib.alpha(color, count - level)
			end
			box(canvas, x, y, size, cell, color, color, ghost)
			level = level + 1
		end
		local y = height - state.top[index] * scale / pitch * pitch - margin - cell
		box(canvas, x, y, size, cell, PEAK, PEAK, ghost)
	end
end

local function bar_preset(name, draw, ghost)
	return {
		name = name,
		feedback = GHOST,
		params = { fall = 0.04 },
		setup = new_bars,
		step = step_bars,
		draw = function(canvas, state, _, scene)
			draw(canvas, state, scene, ghost)
		end,
	}
end

local function scope_step(state, audio)
	state.wave = state.wave or {}
	for index = 1, 256 do
		local previous = state.wave[index] or 0
		local position = (index - 1) / 255
		state.wave[index] = previous + ((bins.sample(audio, position, 0) + bins.sample(audio, position, 1)) * 64 - previous) * SMOOTH
	end
end

return {
	name = "Analyzed",
	presets = {
		bar_preset("Line Bars", line, false),
		bar_preset("Mirror Bars", mirror, false),
		bar_preset("Digital Bars", digital, false),
		bar_preset("Line Ghost Bars", line, true),
		bar_preset("Mirror Ghost Bars", mirror, true),
		bar_preset("Digital Ghost Bars", digital, true),
		{
			name = "Bar Scope",
			feedback = GHOST,
			params = { fall = 0.04 },
			step = scope_step,
			draw = function(canvas, state, _, scene)
				local width, height = scene.width, scene.height
				local scale = height / 384
				local slot = (width - 2) / 128
				for index = 1, 128 do
					local mixed = (index - 1) / 128
					local dark = lib.mix(C820, C830, mixed)
					local bright = lib.mix(C800, C810, mixed)
					local reach = math.abs(state.wave[index * 2] or 0) * scale
					local x = (index - 1) * slot + slot * 0.2
					local color = lib.mix(dark, bright, reach * 2 / height)
					box(canvas, x, height * 0.5 - reach, slot * 0.8, reach * 2, color, color, false)
				end
			end,
		},
		{
			name = "Dot Scope",
			feedback = GHOST,
			params = { fall = 0.04 },
			step = scope_step,
			draw = function(canvas, state, _, scene)
				local width, height = scene.width, scene.height
				local scale = height / 384
				local slot = (width - 2) / 256
				for index = 0, 255 do
					local mixed = index / 256
					local y = height * 0.5 - (state.wave[index + 1] or 0) * scale
					local color = lib.mix(lib.mix(C820, C830, mixed), lib.mix(C800, C810, mixed), y / height)
					box(canvas, index * slot + slot * 0.4, y, slot * 1.6, slot, color, color, false)
				end
			end,
		},
	},
}

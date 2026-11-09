local lib = require("lib")
local bins = require("packs.wmp_bins")

local function spiked(audio, position)
	local spike = 0.4 + 0.6 * math.max(0, math.min(1, (0.15 - position) * 10))
	return bins.spiky(audio, position * 1024, 0, spike) / 255 * (audio.stereo and 1 or 1 - math.max(0, position - 0.7) * 2.5)
end

local CLEAR = "shaders/common/clear.gdshader"
local COLUMNS = 716
local PERIOD = 250000
local SPEED = 0.00005

local function spectrum(name, style, source, shift)
	return {
		name = name,
		layers = { CLEAR },
		setup = function(state)
			state.hue = 0
			state.count = 0
		end,
		step = function(state, _, scene)
			if shift then
				state.hue = (state.hue + math.sin(state.count / PERIOD * math.pi * 2) * SPEED * 640) % 1
				state.count = (state.count + 640) % PERIOD
			end
		end,
		draw = function(canvas, state, audio, scene)
			local width, height = scene.width, scene.height
			local columns = math.min(320, width)
			local slot = width / columns
			local size = math.max(1, width / 640)
			local previous
			for column = 0, columns - 1 do
				local position = column / columns
				local x = position * width
				local value
				if source == "frequency" then
					value = spiked(audio, position * COLUMNS / 1024)
				else
					value = bins.wave(audio, position * COLUMNS) / 256
				end
				local y = height * (1 - value)
				local color = lib.hsv(position - state.hue, 1.0, 1.0)
				if style == "points" then
					canvas:draw_rect(Rect2(x, y, size, size), color)
				elseif style == "lines" then
					if previous then
						canvas:draw_line(previous, Vector2(x, y), color, size)
					end
				else
					canvas:draw_rect(Rect2(x, y, slot, height - y), color)
				end
				previous = Vector2(x, y)
			end
		end,
	}
end

local presets = {}
for _, style in ipairs({ { "Points", "points" }, { "Lines", "lines" }, { "Fill", "fill" } }) do
	for _, source in ipairs({ { "Frequency", "frequency" }, { "Waveform", "waveform" } }) do
		presets[#presets + 1] = spectrum(style[1] .. "/" .. source[1], style[2], source[2], false)
		presets[#presets + 1] = spectrum(style[1] .. "/" .. source[1] .. "/Shift", style[2], source[2], true)
	end
end

return {
	name = "Spectrum",
	presets = presets,
}

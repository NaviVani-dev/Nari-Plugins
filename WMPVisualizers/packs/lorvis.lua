local measure = require("packs.measuring_spectrum")
local bins = require("packs.wmp_bins")

local SPECTRUM = "shaders/measuring_sound/spectrum.gdshader"
local font

local function lorvis(name, count, bars, power)
	local bar_width = count == 8 and 170.0 or 73.0
	return {
		name = name,
		layers = { SPECTRUM },
		params = {
			background = Color(0.0, 0.0, 0.0, 1.0),
			ink = Color(1.0, 0.0, 0.0, 1.0),
			bar_width = bar_width,
			channels = bars and count or 0.0,
		},
		step = function(_, audio, scene)
			if bars then
				local values = {}
				for slot = 0, 15 do
					local total = 0.0
					if slot < count then
						if audio.stereo then
							total = bins.peak(audio, math.floor(slot * bar_width), math.floor((slot + 1) * bar_width) - 1)
						else
							for step = 0, 3 do
								local bin = (slot + step / 3.0) * bar_width
								total = math.max(total, measure.bin(audio, bin) * (bin < 64.0 and 2.9 or 1.15))
							end
						end
					end
					values[slot + 1] = math.min(255.0, total)
				end
				scene.engine.set(scene, "bars", values)
			end
		end,
		draw = function(canvas, _, audio, scene)
			local width, height = scene.width, scene.height
			local green = Color(0.1568, 0.3529, 0.1568, 1.0)
			font = font or ThemeDB:get_fallback_font()
			local size = math.floor(13 * height / 480 + 0.5)
			for slot, y in ipairs({ 165, 184 }) do
				local at = y * height / 480
				canvas:draw_line(Vector2(0.0, at), Vector2(width, at), green, 1.0)
				canvas:draw_string(font, Vector2(1.0, at - 2.0), tostring(count + 1 - slot), 0, -1.0, size, Color(1.0, 1.0, 1.0, 1.0))
			end
			local points = {}
			local count = math.min(640, math.floor(width))
			for index = 0, count - 1 do
				points[index + 1] = Vector2(index / (count - 1) * width, height - bins.wave(audio, index * 639 / (count - 1)) * height / 256.0)
			end
			canvas:draw_polyline(points, Color(0.0, 1.0, 0.0, 1.0), 1.0)
		end,
	}
end

return {
	name = "LORVis",
	presets = {
		lorvis("Manual Configuration", 16, true, true),
		lorvis("Frequency And Power (8 Channels)", 8, true, true),
		lorvis("Frequency And Power (16 Channels)", 16, true, true),
		lorvis("Frequency Only (8 Channels)", 8, true, false),
		lorvis("Frequency Only (16 Channels)", 16, true, false),
		lorvis("Power Only (8 Channels)", 8, false, true),
		lorvis("Power Only (16 Channels)", 16, false, true),
	},
}

local bins = require("packs.wmp_bins")

local function spiked(audio, position)
	local spike = 0.4 + 0.6 * math.max(0, math.min(1, (0.15 - position) * 10))
	return bins.spiky(audio, position * 1024, 0, spike) / 255 * (audio.stereo and 1 or 1 - math.max(0, position - 0.7) * 2.5)
end

local CLEAR = "shaders/common/clear.gdshader"
local RED = Color(1.0, 0.0, 0.0)

return {
	name = "Special",
	presets = {
		{
			name = "Special Bars",
			layers = { CLEAR },
			draw = function(canvas, _, audio, scene)
				local width, height = scene.width, scene.height
				local columns = math.min(320, width)
				local slot = width / columns
				for column = 0, columns - 1 do
					local value = spiked(audio, column / columns * 640 / 1024)
					local x = (column + 0.5) * slot
					canvas:draw_line(Vector2(x, height), Vector2(x, height * (1 - value)), RED, slot)
				end
			end,
		},
		{
			name = "Special Wave",
			layers = { CLEAR },
			draw = function(canvas, _, audio, scene)
				local points = {}
				local count = audio.stereo and math.min(639, scene.width) or 127
				for step = 0, count do
					points[step + 1] = Vector2(step / count * scene.width, scene.height * bins.wave(audio, step / count * 639) / 256)
				end
				canvas:draw_polyline(points, RED, 1.0)
			end,
		},
	},
}

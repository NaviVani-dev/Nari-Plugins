local bins = require("packs.wmp_bins")
local SPECTRUM = "shaders/measuring_sound/spectrum.gdshader"
local INK = Color(1.0, 0.0, 0.0, 1.0)
local font

local function label(canvas, scene, text, center)
	font = font or ThemeDB:get_fallback_font()
	local scale = scene.width / 640.0
	local size = math.floor(13 * scene.height / 480 + 0.5)
	canvas:draw_string(font, Vector2((center - 40) * scale, size), text, 1, 80 * scale, size, Color(0.0, 0.0, 0.0, 1.0))
end

local function spectrum(name, stretch, grid_set, labels)
	return {
		name = name,
		layers = { SPECTRUM },
		params = { stretch = stretch, grid_set = grid_set, line_color = Color(1.0, 0.0, 0.0, 1.0) },
		draw = function(canvas, _, _, scene)
			for _, item in ipairs(labels) do
				label(canvas, scene, item[1], item[2])
			end
		end,
	}
end

return {
	name = "Measuring Sound",
	light = true,
	presets = {
		spectrum("22kHz Spectrum", 1.0, 1.0, { { "1k", 45 }, { "5k", 230 }, { "10k", 463 } }),
		spectrum("Spectrum Mag 2", 2.0, 2.0, { { "500", 45 }, { "2.5k", 230 }, { "5k", 463 } }),
		{
			name = "Oscilloscope",
			layers = { SPECTRUM },
			params = { show_spectrum = 0.0, grid_set = 0.0 },
			draw = function(canvas, _, audio, scene)
				local width, height = scene.width, scene.height
				local scale = width / 640.0
				local mid = (height + 1) // 2
				local grid = Color(1.0, 0.0, 0.0, 1.0)
				canvas:draw_line(Vector2(0.0, mid), Vector2(width, mid), grid, 1.0)
				canvas:draw_line(Vector2(100.0 * scale, 0.0), Vector2(100.0 * scale, height), grid, 1.0)
				canvas:draw_line(Vector2(320.0 * scale, 0.0), Vector2(320.0 * scale, height), grid, 1.0)
				local points = {}
				local wave = {}
				local count = math.min(640, math.floor(width))
				for index = 1, count do
					wave[index] = bins.sample(audio, (index - 1) / 639)
				end
				for index = 1, #wave do
					points[index] = Vector2((index - 1) / (#wave - 1) * width, (wave[index] * 127.0 + 128.0) * height / 256.0)
				end
				if #points > 1 then
					canvas:draw_polyline(points, INK, 1.0)
				end
			end,
		},
	},
}

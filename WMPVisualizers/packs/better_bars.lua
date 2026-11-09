local bins = require("packs.wmp_bins")


local TRAIL = "shaders/common/trail.gdshader"
local FALL = "shaders/better_bars/fall.gdshader"
local GRID = "shaders/better_bars/grid.gdshader"
local CLEAR = "shaders/common/clear.gdshader"

local GREEN = Color(0.0, 1.0, 0.0)
local YELLOW = Color(1.0, 1.0, 0.0)
local RED = Color(1.0, 0.0, 0.0)
local BLACK = Color(0.0, 0.0, 0.0)

local function spiked(audio, position)
	local spike = 0.4 + 0.6 * math.max(0, math.min(1, (0.15 - position) * 10))
	return bins.spiky(audio, position * 1024, 0, spike) / 255 * (audio.stereo and 1 or 1 - math.max(0, position - 0.7) * 2.5)
end

local images = {}

local function image(name)
	images[name] = images[name] or nari.load("assets/better_bars/" .. name)
	return images[name]
end

local function footer(canvas, scene, name)
	local scale = scene.height / 480
	local texture = image(name)
	canvas:draw_rect(Rect2(0, scene.height - 24 * scale, scene.width, 24 * scale), BLACK)
	canvas:draw_texture_rect(texture, Rect2(5 * scale, scene.height - 22 * scale, texture:get_width() * scale, texture:get_height() * scale), false)
end

local function area(scene)
	return scene.height > 300 and scene.height - 24 * scene.height / 480 or scene.height
end

local function scope(canvas, audio, scene, top, tall, channel)
	local points = {}
	local count = audio.stereo and 511 or 127
	for step = 0, count do
		local position = step / count
		points[step + 1] = Vector2(position * scene.width, top + tall * bins.wave(audio, position * 1023, channel) / 256)
	end
	canvas:draw_polyline(points, GREEN, 1.0)
end

return {
	name = "Better Bars",
	presets = {
		{
			name = "Bars",
			feedback = FALL,
			display = GRID,
			resize = function(_, scene)
				local bottom = area(scene)
				local pitch_x = math.max(2, (scene.width - 64) // 64 + 1)
				local pitch_y = math.max(3, (math.floor(bottom) - 128) // 128 + 1)
				scene.engine.set(scene, "pitch", Vector2(pitch_x, pitch_y))
				scene.engine.set(scene, "bottom", bottom)
			end,
			draw = function(canvas, _, audio, scene)
				local width = scene.width
				local bottom = area(scene)
				local pitch_x = math.max(2, (width - 64) // 64 + 1)
				for column = 0, 63 do
					local value = bins.peak(audio, column * 16, column * 16 + 15) / 255
					if not audio.stereo then
						value = value * (1 - math.max(0, (column + 0.5) / 64 - 0.7) * 2.5) * (1.35 + math.random() * 0.3)
					end
					local tall = math.min(1.0, value) * bottom
					local x = column * pitch_x
					local green = math.min(tall, bottom * 0.75)
					canvas:draw_rect(Rect2(x, bottom - green, pitch_x, green), GREEN)
					if tall > bottom * 0.75 then
						local yellow = math.min(tall, bottom * 0.85)
						canvas:draw_rect(Rect2(x, bottom - yellow, pitch_x, yellow - bottom * 0.75), YELLOW)
					end
					if tall > bottom * 0.85 then
						canvas:draw_rect(Rect2(x, bottom - tall, pitch_x, tall - bottom * 0.85), RED)
					end
				end
				footer(canvas, scene, "bars.png")
			end,
		},
		{
			name = "Stereo Scope",
			layers = { CLEAR },
			draw = function(canvas, _, audio, scene)
				local bottom = area(scene)
				scope(canvas, audio, scene, 0, bottom * 0.5, 0)
				scope(canvas, audio, scene, bottom * 0.5, bottom * 0.5, 1)
				footer(canvas, scene, "stereo.png")
			end,
		},
		{
			name = "Scan",
			feedback = TRAIL,
			params = { fade = Color(1.0, 1.0, 1.0), drift = Vector2(1, 0) },
			setup = function(_, scene)
				scene.engine.set(scene, "drift", Vector2(math.max(1, scene.width // 256), 0))
			end,
			resize = function(_, scene)
				scene.engine.set(scene, "drift", Vector2(math.max(1, scene.width // 256), 0))
			end,
			draw = function(canvas, _, audio, scene)
				local width = scene.width
				local bottom = area(scene)
				local slot = bottom / 128
				local size = math.max(1, width // 256) * 4
				for row = 0, 127 do
					local value
					if audio.stereo then
						value = bins.peak(audio, row * 8, row * 8 + 7) / 255
					else
						value = math.max(spiked(audio, row / 128), spiked(audio, (row + 0.5) / 128))
					end
					canvas:draw_rect(Rect2(width - size, bottom - (row + 1) * slot, size, slot + 1), Color(0.0, value, 0.0, 1.0))
				end
				footer(canvas, scene, "scan.png")
			end,
		},
	},
}

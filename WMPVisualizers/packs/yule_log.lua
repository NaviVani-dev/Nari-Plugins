local bins = require("packs.wmp_bins")

local FIRE = "shaders/yule/fire.gdshader"

local images = {}

local function image(name)
	images[name] = images[name] or nari.load("assets/yule_log/" .. name)
	return images[name]
end

return {
	name = "Yule Log",
	presets = {
		{
			name = "Yule Log",
			aspect = 4 / 3,
			layers = { FIRE },
			setup = function(state, scene)
				state.clock, state.scroll, state.level = 0, 0, 0
				state.bands, state.heights = {}, {}
				for index = 1, 4 do
					local a, b = math.random(2, 140), math.random(2, 140)
					state.bands[index] = { math.min(a, b), math.max(a, b) }
					state.heights[index] = 1.0
				end
				local set = scene.engine.set
				set(scene, "hearth", image("hearth.jpg"))
				for index = 1, 4 do
					set(scene, "flame" .. index, image("flame" .. index .. ".png"))
				end
				set(scene, "turbx", image("turbx.png"))
				set(scene, "turby", image("turby.png"))
			end,
			step = function(state, audio, scene)
				state.clock = state.clock + 1 / 30
				local set = scene.engine.set
				local function band(low, high)
					local total = 0
					for tap = 0, 7 do
						total = total + bins.frequency(audio, low + (high - low) * tap // 7)
					end
					return total / 2040
				end
				for index = 1, 4 do
					local item = state.bands[index]
					local value = math.min(1.0, band(item[1], item[2]) * 2.0 + 0.3)
					state.heights[index] = state.heights[index] + (value - state.heights[index]) / 30
				end
				local h = state.heights
				set(scene, "heights", Color(h[1], h[2], h[3], h[4]))
				local level = band(1, 696)
				state.level = state.level + (level - state.level) * 0.5
				local l = state.level
				local light = 0.45
				set(scene, "tint", Color(1.0 - light + light * math.min(1.0, 0.99 + 0.0275 * l), 1.0 - light + light * math.min(1.0, 0.11 + 2.4475 * l), 1.0 - light + light * math.min(1.0, 0.01 + 2.7225 * l), 1.0))
				state.scroll = state.scroll + (1 / 30) / 1.5 * (1.0 + band(2, 1023) * 3.0)
				set(scene, "scroll", state.scroll)
				set(scene, "clock", state.clock)
			end,
		},
	},
}

local photo_show = require("packs.photo_show")

return {
	name = "Terminator 3",
	presets = {
		photo_show.make("Rise of the Machines", "terminator3", {
			count = 13,
			logo = { "logo.jpg", 6, 6 },
			length = 3.0,
			hold = 3.0,
			rest = 51.6,
			water = true,
			trail = 2,
			point = 0.3,
			rest_color = { 0.0, 0.0, 0.1 },
			effects = { "plain", "roll", "water_scatter", "water_rain", "water_storm", "water_spout", "water_tilt", "water_wake", "water_fall", "burst_left", "burst_right" },
			emitter = photo_show.bursts,
		}),
	},
}

local photo_show = require("packs.photo_show")

return {
	name = "Grind",
	presets = {
		photo_show.make("Go BIG or Go Home", "grind", {
			count = 32,
			logo = { "logo.png", 0, 2 },
			effects = { 7, 8, 9, 10, 11, 12, 13, 14 },
			emitter = photo_show.spectrum_clock,
		}),
	},
}

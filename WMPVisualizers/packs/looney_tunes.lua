local photo_show = require("packs.photo_show")

return {
	name = "Looney Tunes",
	presets = {
		photo_show.make("Back in Action", "looney_tunes", {
			count = 25,
			length = 3.0,
			hold = 4.0,
			fit = { 466, 306 },
			logo = { "logo.png", 0, 360 },
			effects = { 7, 8, 9, 10, 11, 12, 13, 14 },
			trail = 8,
			point = 0.2,
			emitter = photo_show.fixed_sparks,
		}),
	},
}

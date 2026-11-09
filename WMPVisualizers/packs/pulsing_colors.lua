local columns = require("packs.blazing_colors_columns")

return {
	name = "Pulsing Colors",
	presets = {
		columns.preset("Lip Sink", { mode = 5, place = 8, strip = 320, palette = "spectrum", rows = 320, speed = 8.0, keep = 182, smooth = 20, offset = 80, history = 10, reach = 72, amount = 322, sides = 3 }),
		columns.preset("Musical Island", { mode = 6, place = 8, strip = 320, palette = "spectrum", rows = 320, speed = 1.0, keep = 180, smooth = 9, offset = 70, history = 0, reach = 6, amount = 255, sides = 15 }),
		columns.preset("Steel Rhythm", { mode = 5, place = 8, strip = 320, palette = "spectrum", rows = 320, speed = 8.0, keep = 180, smooth = 20, offset = 60, history = 10, reach = 16, amount = 111, sides = 3 }),
	},
}

local columns = require("packs.blazing_colors_columns")

return {
	name = "Blazing Colors",
	presets = {
		columns.preset("Burning Dance", { mode = 4, place = 1, strip = 256, palette = "rainbow", rows = 1024, start = -285.0, speed = -1.0, keep = 175, smooth = 5, offset = 60, history = 20, reach = 93, amount = 233, sides = 1, edge = { 234, 244, 1 }, bright = 80 }),
		columns.preset("Firey Colors", { mode = 2, place = 6, strip = 320, palette = "spectrum", rows = 320, speed = -8.0, keep = 175, smooth = 5, offset = 36, history = 20, reach = 55, amount = 256, sides = 1, edge = { 7, 70, 2 }, roll = 55 }),
		columns.preset("Paint Can", { mode = 3, place = 7, strip = 320, palette = "spectrum", rows = 320, speed = 8.0, keep = 175, smooth = 4, offset = 36, history = 99, reach = 176, amount = 200, sides = 12, edge = { 0, 243, 2 }, roll = 30, gate = true }),
	},
}

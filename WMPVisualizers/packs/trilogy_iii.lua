local trilogy = require("packs.trilogy")

local Q = 31

return trilogy.pack("Trilogy III", {
	{ name = "Lava", source = 1, r = 67, amt = 250, offset = 40, smooth = 5, scatter = true, skip = true, f46 = 180.0, s46 = 36 / Q, s48 = 8 / Q, roll_speed = 12 / Q, f41 = 4.06, f42 = 1.23, i5a = 1, i5b = 2, i5d = 50, i48 = 50 },
	{
		name = "Mystic Cloud",
		source = 1,
		flat = false,
		r = 52,
		amt = 142,
		offset = 20,
		smooth = 5,
		f46 = 180.0,
		s46 = 1.0,
		f53 = 1.0,
		f54 = -1.0,
		f5f = 2.1,
		dynamic_history = true,
		tick = function(state, fields, level)
			fields.phase = (fields.phase or 0.0) + 4 / Q
			fields.roll = level / ((math.cos(math.rad(math.floor(fields.phase))) + 1.0) * 5.0 + 1.0)
			state.mix = math.floor((math.cos(math.rad(math.floor(fields.f46))) + 1.0) * 30.0)
		end,
	},
	{
		name = "Undulation",
		source = 0,
		flat = false,
		r = 52,
		amt = 142,
		offset = 30,
		history = 40,
		counter_start = 100 * Q - 100,
		f46 = 0.0,
		s46 = 3.0,
		s48 = 2.0,
		roll_speed = 8 / Q,
		f41 = 3.0,
		f42 = 1.0,
		f43 = 3.0,
		i45 = 45,
		i46 = 112,
		i5a = 2,
		i5b = 1,
		i5d = 90,
		i63 = 2,
		i64 = 1,
		i77 = 2,
		tick = function(state, fields)
			state.counter = state.counter + 1
			if state.counter >= 100 * Q then
				state.counter = 0
				state.flip = not state.flip
				fields.s46 = state.flip and 8 / Q or 12 / Q
				fields.s48 = state.flip and 12 / Q or 8 / Q
			end
		end,
	},
})

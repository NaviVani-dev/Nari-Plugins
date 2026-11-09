local trilogy = require("packs.trilogy")

local Q = 31

return trilogy.pack("Trilogy I", {
	{ name = "Pulsar", source = 1, r = 67, amt = 250, offset = 40, smooth = 5, scatter = true, f46 = 180.0, s46 = 24 / Q, s48 = 8 / Q, roll_speed = 12 / Q, i48 = 50 },
	{ name = "Wings", source = 0, flat = false, r = 108, amt = 250, offset = 40, smooth = 3, f46 = 180.0, s46 = 40 / Q, s48 = 8 / Q, roll_speed = 12 / Q, f42 = 1.19, i5b = 1, i5d = 70 },
	{
		name = "Twirling",
		source = 0,
		flat = false,
		r = 50,
		amt = 250,
		offset = 40,
		history = 20,
		f46 = 180.0,
		s46 = 4 / Q,
		s48 = 8 / Q,
		roll_speed = 12 / Q,
		f41 = 1.0,
		f42 = 5.0,
		f43 = 0.21,
		i46 = 100,
		i49 = 50,
		i5a = 2,
		i5b = 1,
		i5d = 70,
		i63 = 1,
		i64 = 1,
		i77 = 2,
		tick = function(state, fields)
			local angle = math.floor(fields.f46)
			if angle == 270 or angle == 90 then
				state.wave = state.wave == 1.0 and 0.0 or 1.0
			end
		end,
	},
})

local trilogy = require("packs.trilogy")

local Q = 31

local function either(bits)
	return math.random(0, 1) == 0 and 0 or bits
end

return trilogy.pack("Trilogy II", {
	{ name = "Musical Sine", source = 1, r = 67, amt = 250, offset = 40, smooth = 5, scatter = true, f46 = 180.0, s46 = 24 / Q, s48 = 8 / Q, roll_speed = 12 / Q, f42 = 4.72, i5b = 1, i5d = 76, i48 = 50 },
	{
		name = "4th Dimension",
		source = 1,
		r = 67,
		amt = 250,
		offset = 20,
		smooth = 5,
		scatter = true,
		counter_start = 30 * Q - 30,
		f46 = 180.0,
		s46 = 4 / Q,
		roll_speed = 12 / Q,
		f43 = 0.09,
		i48 = 20,
		i49 = 20,
		i46 = 70,
		tick = function(state, fields)
			state.counter = state.counter + 1
			if state.counter >= 30 * Q then
				state.counter = 0
				local coin = math.random(0, 1) == 0
				if fields.f43 == 0.09 then
					fields.f43 = coin and -0.05 or -0.03
				elseif fields.f43 == -0.05 then
					fields.f43 = coin and 0.09 or -0.03
				else
					fields.f43 = coin and -0.05 or 0.09
				end
			end
		end,
	},
	{
		name = "Mathical Music",
		source = 1,
		flat = false,
		r = 52,
		amt = 200,
		offset = 55,
		counter_start = math.floor(50 * Q / 3) - 16,
		f46 = 180.0,
		s46 = 4 / Q,
		roll_speed = 12 / Q,
		f43 = -0.1,
		i48 = 20,
		i49 = 20,
		i4a = 1,
		i64 = 1,
		tick = function(state, fields)
			state.counter = state.counter + 1
			if state.counter >= math.floor(50 * Q / 3) then
				state.counter = 0
				local turned = state.turned
				turned[1] = either(math.random(0, 127))
				turned[2] = either(math.random(0, 127))
				turned[3] = either(math.random(0, 127))
				if turned[1] == 0 and turned[2] == 0 then
					turned[1] = math.random(0, 127)
					turned[3] = math.random(0, 127)
				end
				fields.f43 = fields.f43 == -0.1 and -0.2 or -0.1
			end
		end,
	},
})

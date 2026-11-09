local columns = require("packs.blazing_colors_columns")
local trilogy = require("packs.trilogy")

local NIGHT = { mode = 5, place = 8, strip = 320, palette = "spectrum", rows = 320, speed = 8.0, keep = 186, smooth = 30, offset = 90, history = 10, reach = 115, amount = 234, sides = 13 }

local ROLLING = {
	name = "Rolling Colors",
	palette = "assets/blazing_colors/rolling.png",
	width = 352,
	mode = 1,
	source = 1,
	place = 0,
	mirror = false,
	keep = 300,
	smooth = 10,
	jag = 0.5,
	f46 = 0.0,
	s46 = 2.0,
	f5f = 4.0,
	f53 = 1.0,
	f54 = 0.5,
	i46 = 186,
	i48 = 10,
	i77 = 1,
	stripe_speed = 8,
	tick = function(state)
		state.hide = state.pipe.level < 5
	end,
}

local RIBBON = {
	name = "Ribbon Rhythm",
	palette = "assets/blazing_colors/ribbon.png",
	width = 352,
	mode = 20,
	source = 2,
	flat = false,
	f53 = 0.5,
	f54 = 1.0,
	place = 9,
	keep = 174,
	smooth = 10,
	offset = 20,
	history = 60,
	jag = 0.5,
	f46 = 0.0,
	s46 = 2.0,
	f43 = -0.14,
	roll_speed = 6.0,
	i45 = 160,
	i46 = -60,
	i48 = 1,
	i63 = 2,
	i64 = 1,
	i77 = 1,
	tick = function(_, fields, level)
		fields.s48 = level * 0.02
	end,
}

local night = columns.preset("Night Fire", NIGHT)

local function selection()
	return {
		name = "Random Selection",
		size = { 350, 320 },
		filter = "nearest",
		setup = function(state, scene)
			trilogy.build(state, scene)
			state.night = {}
			night.setup(state.night, scene)
			state.current = 0
			state.hold = 101
		end,
		step = function(state, audio)
			if state.hold >= 101 then
				state.hold = 0
				state.current = trilogy.pick(3, state.current)
				state.night.node.visible = state.current == 3
				state.flat.visible = state.current ~= 3
				state.overlay.visible = false
				if state.current == 1 then
					trilogy.apply(state, ROLLING)
				elseif state.current == 2 then
					trilogy.apply(state, RIBBON)
				else
					state.points.visible = false
					state.trail_on = false
				end
			end
			state.hold = state.hold + 1
			if state.current == 3 then
				night.step(state.night, audio)
			else
				trilogy.step(state, audio)
			end
		end,
	}
end

return {
	name = "Eclectic Colors",
	presets = {
		trilogy.preset(ROLLING.name, { ROLLING }),
		trilogy.preset(RIBBON.name, { RIBBON }),
		night,
		selection(),
	},
}

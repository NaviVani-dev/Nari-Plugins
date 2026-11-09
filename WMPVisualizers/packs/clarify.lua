local bins = require("packs.wmp_bins")

local RINGS = "shaders/clarify/clarify.gdshader"
local REACH = 400

local function capped(value)
	return math.min(255, math.floor(value))
end

local function push(scene, name, value)
	for _, item in ipairs(scene.materials) do
		item:set_shader_parameter(name, value)
	end
end

local function spectrum(state, audio, scene)
	push(scene, "left", bins.range(audio, REACH, 0))
	push(scene, "right", bins.range(audio, REACH, 1))
end

local function setup(state)
	state.count = 0
end

local function step_single(state, audio, scene)
	spectrum(state, audio, scene)
	push(scene, "tint_a", Color(capped(bins.both(audio, 9)), capped(bins.both(audio, 49) * 3 // 2), capped(bins.both(audio, 249) * 2)))
end

local function step_split(offset)
	return function(state, audio, scene)
		spectrum(state, audio, scene)
		push(scene, "tint_a", Color(255 - capped(bins.frequency(audio, 9, 0) * 2), capped(bins.frequency(audio, 49, 0) * 3), capped(bins.frequency(audio, 249, 0) * 4)))
		push(scene, "tint_b", Color(capped(bins.frequency(audio, 9, 1) * 2), capped(bins.frequency(audio, 49, 1) * 3), 255 - capped(bins.frequency(audio, 249, 1) * 4)))
		local ax, ay, bx, by = offset(state.count)
		push(scene, "offset_a", Vector2(ax, ay))
		push(scene, "offset_b", Vector2(bx, by))
		state.count = state.count + 1
	end
end

local function round(value)
	return math.floor(value + 0.5)
end

local function preset(name, step, split)
	return {
		name = name,
		feedback = RINGS,
		params = { split = split },
		setup = setup,
		step = step,
	}
end

return {
	name = "Clarify",
	presets = {
		preset("Lucid", step_single, false),
		preset("Vivid", step_split(function()
			return 0, 0, 0, 0
		end), true),
		preset("Focus", step_split(function()
			return 10, 0, -10, 0
		end), true),
		preset("Epiphany", step_split(function(count)
			return round(math.cos(count / 37) * 20), round(math.sin(count / 43) * 20), round(math.cos(count / 29) * 20), round(math.sin(count / 23) * 20)
		end), true),
	},
}

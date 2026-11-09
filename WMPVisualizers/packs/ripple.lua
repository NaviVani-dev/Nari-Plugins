local bins = require("packs.wmp_bins")

local RING = "shaders/ripple/ripple.gdshader"

local function level(audio, first, last)
	local sum = 0
	for bin = first, last do
		sum = sum + bins.both(audio, bin)
	end
	return math.floor(sum / 20)
end

local function advance(state, slot, value, shift)
	if value > state.last[slot] + 48 then
		state.reach[slot] = 0
	else
		state.reach[slot] = state.reach[slot] + (value >> shift)
	end
	state.last[slot] = value
	state.reach[slot] = state.reach[slot] % 256
end

local function step(state, audio, scene)
	advance(state, 1, level(audio, 4, 14), 5)
	advance(state, 2, level(audio, 44, 54), 4)
	advance(state, 3, level(audio, 244, 254), 3)
	local wide = scene.width * 480 / scene.height
	local keep = 224
	if state.count % 256 == 0 then
		local set = scene.engine.set
		set(scene, "center_low", Vector2(math.random(0, math.floor(wide) - 1), math.random(0, 479)))
		set(scene, "center_mid", Vector2(math.random(0, math.floor(wide) - 1), math.random(0, 479)))
		set(scene, "center_high", Vector2(math.random(0, math.floor(wide) - 1), math.random(0, 479)))
		state.ease = 31
	end
	if state.ease > 0 then
		keep = keep + state.ease
		state.ease = state.ease - 1
	end
	state.count = state.count + 1
	scene.engine.set(scene, "keep", keep)
	for _, item in ipairs(scene.materials) do
		item:set_shader_parameter("radius", Color(state.reach[1], state.reach[2], state.reach[3]))
	end
end

local function preset(name, mode)
	return {
		name = name,
		feedback = RING,
		params = { mode = mode },
		setup = function(state)
			state.reach = { 0, 0, 0 }
			state.last = { 0, 0, 0 }
			state.count = 0
			state.ease = 0
		end,
		step = step,
	}
end

return {
	name = "Ripple",
	presets = {
		preset("Plaid", 0),
		preset("Pool", 1),
		preset("Acid", 2),
		preset("Haze", 3),
		preset("Hulk", 4),
		preset("Solvent", 5),
		preset("Vomit", 6),
		preset("Slime", 7),
	},
}

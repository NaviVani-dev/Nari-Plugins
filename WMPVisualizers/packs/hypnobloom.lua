local psychedelia = require("packs.psychedelia")
local bins = require("packs.wmp_bins")

local OUT = "shaders/psychedelia/koi_out.gdshader"
local ECHO = "shaders/psychedelia/koi_echo_out.gdshader"
local RINGS = "shaders/psychedelia/hypno_rings.gdshader"
local TWIST = 2.5

local single = psychedelia.single

local function drift(ms, x, y, z)
	return math.sin(ms / 23000 + 1.57) * 50 + x, math.sin(ms / 24000) * 50 + y, math.sin(ms / 25000) * 30 + z
end

local function decay(state, s, gain, keep)
	for ring = 1, 10 do
		state.yaw[ring] = state.yaw[ring] * keep + s.low[ring] * gain / 50
		state.pitch[ring] = state.pitch[ring] * keep + s.middle[ring] * gain / 50
		state.roll[ring] = state.roll[ring] * keep + s.high[ring] * gain / 50
	end
end

local function grow(state, s, gain, roll)
	for ring = 1, 10 do
		state.yaw[ring] = state.yaw[ring] + s.low[ring] * gain / 50
		state.pitch[ring] = state.pitch[ring] + s.middle[ring] * gain / 50
		state.roll[ring] = state.roll[ring] + s.high[ring] * roll / 50
	end
end

local function default_eye(ms)
	return math.sin(ms / 36243 + 1.57) * 260, math.sin(ms / 8000) * 30 - 185, math.sin(ms / 36243) * 260
end

local BRIGHT = { scene_in = 1.0, past_in = 0.965, scene_out = 1.49, glow_out = 0.91 }
local SOFT = { scene_in = 2.0, past_in = 0.765, scene_out = 1.49, glow_out = 0.91 }
local HAZE = { scene_in = 2.0, past_in = 0.9, scene_out = 0.0, glow_out = 0.965 }

local PRESETS = {
	{
		name = "Kandinsky",
		blend = BRIGHT,
		move = function(state, s, ms)
			decay(state, s, 0.2, 0.92)
			for ring = 1, 10 do
				state.roll[ring] = 0.0
			end
			local x, y, z = drift(ms, 250, 250, -200)
			return x, y, z, -20
		end,
	},
	{
		name = "Twin Aphex",
		blend = BRIGHT,
		move = function(state, s, ms)
			decay(state, s, 0.2, 0.92)
			local x, y, z = drift(ms, 200, 200, -130)
			return x, y, z, 0
		end,
	},
	{
		name = "SpoonerFisher",
		blend = SOFT,
		move = function(state, s, ms)
			grow(state, s, 0.02, 0.1)
			local x, y, z = drift(ms, 200, 200, -130)
			return x, y, z, 0
		end,
	},
	{
		name = "Aube",
		blend = BRIGHT,
		move = function(state, s, ms)
			for ring = 1, 10 do
				local sign = ring % 2 == 1 and 0.01 or -0.01
				local low, middle, high = s.low[ring], s.middle[ring], s.high[ring]
				local pick = low < middle and 2 or 1
				if middle < high then
					pick = 3
				end
				if pick == 1 then
					state.yaw[ring] = state.yaw[ring] + low * sign / 50
				elseif pick == 2 then
					state.pitch[ring] = state.pitch[ring] + middle * sign / 50
				else
					state.roll[ring] = state.roll[ring] + high * sign * 5 / 50
				end
			end
			return math.sin(ms / 44000) * 2 + 16.5, math.sin(ms / 12304) * 2 + 16.5, math.sin(ms / 3000) * 2 - 16.5, 0
		end,
	},
	{
		name = "Delerium Line Assembly",
		blend = BRIGHT,
		move = function(state, s, ms)
			for ring = 1, 10 do
				local odd = ring % 2 == 0
				local function turn(value, gain)
					local part = value * gain / 50
					return odd and 0.01 - part or part + 0.01
				end
				state.yaw[ring] = state.yaw[ring] + turn(s.low[ring], 0.001)
				state.pitch[ring] = state.pitch[ring] + turn(s.middle[ring], 0.001)
				state.roll[ring] = state.roll[ring] + turn(s.high[ring], 0.005)
			end
			local x, y, z = default_eye(ms)
			return x, y, z, 0
		end,
	},
	{
		name = "Ecaps Emitter",
		echo = true,
		move = function(state, s, ms)
			for ring = 1, 10 do
				local sign = ring % 2 == 1 and 1 or -1
				state.yaw[ring] = state.yaw[ring] + sign * s.low[ring] * 0.01 / 50
				state.pitch[ring] = state.pitch[ring] + sign * s.middle[ring] * 0.01 / 50
				state.roll[ring] = state.roll[ring] + sign * s.high[ring] * 0.05 / 50
			end
			local x, y, z = default_eye(ms)
			return x, y, z, 0
		end,
	},
	{
		name = "Nullsleep",
		blend = BRIGHT,
		move = function(state, s, ms)
			for ring = 1, 10 do
				local index = ring - 1
				state.yaw[ring] = 0.0
				state.pitch[ring] = (index + 1) % 3 == 0 and (index % 2) * 3.14 or 0.0
				state.roll[ring] = (index + 2) % 3 == 0 and index * 3.14 or 0.0
			end
			local x, y, z = default_eye(ms)
			return x, y, z, 0
		end,
	},
	{
		name = "Mega",
		blend = HAZE,
		move = function(state, s, ms)
			decay(state, s, 0.1, 0.97)
			local x, y, z = default_eye(ms)
			return x, y, z, -30
		end,
	},
	{
		name = "Proto",
		blend = HAZE,
		move = function(state, s, ms)
			grow(state, s, 0.02, 0.1)
			local x, y, z = drift(ms, 200, 200, -130)
			return x, y, z, 0
		end,
	},
}

local function preset(entry)
	return {
		name = entry.name,
		layers = { entry.echo and ECHO or OUT },
		setup = function(state, scene)
			state.stage = psychedelia.stage(scene, 1.4)
			state.stage:get_camera_3d().near = 5.0
			state.image = Image.create(10, 2, false, Image.FORMAT_RGBAF)
			state.texture = ImageTexture.create_from_image(state.image)
			state.material = psychedelia.material(RINGS, { rings = state.texture, stripes = psychedelia.texture("hypno_stripes") })
			local node = MeshInstance3D.new()
			node.mesh = nari.load("assets/psychedelia/hypno_rings.res")
			node.extra_cull_margin = 16000.0
			node.material_override = state.material
			state.stage:add_child(node)
			state.koi = (entry.echo and psychedelia.koi_echo or psychedelia.koi)(scene, state.stage, scene.materials[1])
			state.yaw, state.pitch, state.roll = {}, {}, {}
			state.s = { low = {}, middle = {}, high = {} }
			for ring = 1, 10 do
				state.yaw[ring], state.pitch[ring], state.roll[ring] = 0.0, 0.0, 0.0
			end
			state.start = math.random() * 100000
		end,
		resize = function(state, scene)
			if state.koi then
				psychedelia.koi_resize(state.koi, scene)
			end
		end,
		step = function(state, audio, scene)
			local ms = state.start + scene.time * 1000
			local s = state.s
			for ring = 1, 10 do
				local index = ring - 1
				s.low[ring] = single(bins.frequency(audio, index * 10) * 0.9)
				s.middle[ring] = single(bins.frequency(audio, 100 + index * 50) * 0.87)
				s.high[ring] = single(bins.frequency(audio, 600 + index * 40) )
			end
			local ex, ey, ez, ay = entry.move(state, s, ms)
			for ring = 1, 10 do
				local index = ring - 1
				local twist = index > 0 and TWIST / index or 0.0
				state.image:set_pixel(index, 0, Color(state.pitch[ring] * twist, state.yaw[ring] * twist, state.roll[ring] * twist, index == 0 and 1.0 or 0.0))
				state.image:set_pixel(index, 1, Color(
					s.middle[ring] / 255 * 0.36 + 0.013,
					bins.frequency(audio, 600 + index * 40) * (0.96 - index * 0.06) / 255 * 0.6 + 0.013,
					s.low[ring] / 255 * 0.24 + 0.013,
					1.0
				))
			end
			state.texture:update(state.image)
			psychedelia.look(state.material, ex, ey, ez, 0.0, ay, 0.0)
			state.material:set_shader_parameter("lamp", Color(math.sin(ms / 2500) * 150, math.sin(ms / 1500) * 50 + 100, math.sin(ms / 3500) * -250, 0.0))
			psychedelia.koi_step(state.koi, ms, entry.blend or BRIGHT)
		end,
	}
end

local presets = {}
for index, entry in ipairs(PRESETS) do
	presets[index] = preset(entry)
end

return {
	name = "Hypnobloom",
	presets = presets,
}

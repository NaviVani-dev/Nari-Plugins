local psychedelia = require("packs.psychedelia")
local bins = require("packs.wmp_bins")

local OUT = "shaders/psychedelia/koi_out.gdshader"
local ECHO = "shaders/psychedelia/koi_echo_out.gdshader"
local SHADER = "shaders/psychedelia/cuber_hex.gdshader"

local CELLS = {
	{ 0, 0 }, { 0, 2 }, { 2, 1 }, { 2, -1 }, { 0, -2 }, { -2, -1 }, { -2, 1 },
	{ 0, 4 }, { 2, 3 }, { 4, 2 }, { 4, 0 }, { 4, -2 }, { 2, -3 }, { 0, -4 }, { -2, -3 }, { -4, -2 }, { -4, 0 }, { -4, 2 }, { -2, 3 },
	{ 0, 6 }, { 4, 4 }, { 6, 1 }, { 6, -3 }, { 2, -5 }, { -2, -5 }, { -6, -3 }, { -6, 1 }, { -4, 4 },
	{ 0, 8 }, { 4, 6 }, { 8, 4 }, { 8, 0 }, { 8, -4 }, { -4, 6 }, { 0, -8 }, { -4, -6 }, { -8, -4 }, { -8, 0 }, { -8, 4 }, { -4, 6 },
}

local function top(audio, first, step)
	local best = 0.0
	for index = 0, 9 do
		best = math.max(best, psychedelia.single(bins.frequency(audio, first + index * step)))
	end
	return best / 255
end

local function preset(name, options)
	return {
		name = name,
		layers = { options.echo and ECHO or OUT },
		setup = function(state, scene)
			state.stage = psychedelia.stage(scene, 1.2)
			state.stage:get_camera_3d().near = 1.0
			state.image = Image.create(#CELLS, 1, false, Image.FORMAT_RGBAF)
			state.texture = ImageTexture.create_from_image(state.image)
			state.levels = {}
			for index = 1, #CELLS do
				state.levels[index] = 0.0
			end
			state.pulse = 0.0
			state.start = math.random() * 100000
			state.material = psychedelia.material(SHADER, { cells = state.texture, past = options.acid and scene.viewport:get_texture() or nil })
			local many = MultiMesh.new()
			many.transform_format = MultiMesh.TRANSFORM_3D
			many.mesh = nari.load("assets/psychedelia/cuber_hex.res")
			many.instance_count = #CELLS
			local node = MultiMeshInstance3D.new()
			node.multimesh = many
			node.extra_cull_margin = 16000.0
			node.material_override = state.material
			state.stage:add_child(node)
			state.koi = (options.echo and psychedelia.koi_echo or psychedelia.koi)(scene, state.stage, scene.materials[1])
			state.blend = { past_in = 0.995, vertical = true }
		end,
		resize = function(state, scene)
			if state.koi then
				psychedelia.koi_resize(state.koi, scene)
			end
		end,
		step = function(state, audio, scene)
			local ms = state.start + scene.time * 1000
			for index, cell in ipairs(CELLS) do
				local level = state.levels[index] + (psychedelia.single(bins.frequency(audio, (index - 1) * 16)) / 255 - state.levels[index]) * 0.1
				state.levels[index] = level
				state.image:set_pixel(index - 1, 0, Color(cell[1] * 9.0, level * 80.0, cell[2] * 9.0, level))
			end
			state.texture:update(state.image)
			state.pulse = state.pulse * 0.95 + (top(audio, 100, 50) * 0.2 + top(audio, 600, 40)) * 16
			local angle = (ms + state.pulse * 500) / 24321
			local far = state.pulse / 10 + 30
			psychedelia.look(state.material, math.sin(angle + 1.57) * far, state.pulse * 0.25 + 50, math.sin(angle) * far, 0.0, options.at, 0.0)
			state.material:set_shader_parameter("lamp", Color(math.sin(ms / 2500) * 100, 100.0, math.sin(ms / 2500 + 1.57) * 100, 0.0))
			state.blend.scene_in = psychedelia.single(bins.frequency(audio, 920)) / 255
			state.blend.scene_out = options.scene
			state.blend.glow_out = options.glow(state.pulse)
			psychedelia.koi_step(state.koi, ms, state.blend)
		end,
	}
end

return {
	name = "up cuber",
	presets = {
		preset("Conspiracy", { at = 20.0, scene = 1.0, glow = function(pulse) return pulse / 240 * 0.8 end }),
		preset("Acid", { acid = true, at = 10.0, scene = 1.0, glow = function() return 0.2 end }),
		preset("Andromeda", { at = 10.0, echo = true, scene = 0.1, glow = function() return 2.8 end }),
		preset("Trixter", { at = 10.0, scene = 0.25, glow = function(pulse) return pulse / 240 * 0.1 + 0.4 end }),
	},
}

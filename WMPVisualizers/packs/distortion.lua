local psychedelia = require("packs.psychedelia")
local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"
local PLANE = "shaders/psychedelia/distortion_plane.gdshader"
local SKY = "shaders/psychedelia/distortion_sky.gdshader"

local WAVES = {
	{ 0.2, -1.0, 0.012, 3.01, 16 }, { -1.0, -0.8, 0.048, 3.04, 32 }, { 0.5, 1.1, 0.06, 3.05, 48 }, { 0.8, 0.5, 0.072, 3.06, 96 }, { 0.1, 0.9, 0.084, 3.07, 128 },
	{ 0.2, -1.0, 0.096, 3.08, 192 }, { -1.0, -0.8, 0.108, 3.09, 256 }, { 0.5, 1.1, 0.024, 3.02, 320 }, { 0.8, 0.5, 0.12, 3.1, 448 }, { 0.1, 0.9, 0.132, 3.11, 576 },
	{ 0.2, -1.0, 0.144, 3.12, 640 }, { -1.0, -0.8, 0.156, 3.13, 704 }, { 0.5, 1.1, 0.168, 3.14, 768 }, { 0.8, 0.5, 0.18, 3.15, 832 }, { 0.1, 0.9, 0.036, 3.03, 896 },
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
		layers = { CLEAR },
		params = { background = Color(0.0, 0.0, 0.0) },
		setup = function(state, scene)
			state.stage = psychedelia.stage(scene, 1.0)
			state.stage:get_camera_3d().near = 1.0
			state.image = Image.create(15, 1, false, Image.FORMAT_RGBAF)
			state.texture = ImageTexture.create_from_image(state.image)
			state.levels = {}
			for index = 1, 15 do
				state.levels[index] = 0.0
			end
			state.spin, state.turn, state.angle, state.reach, state.side = 0.0, 0.0, 0.0, 0.0, 0.0
			state.start = math.random() * 100000
			state.sky = psychedelia.material(SKY, { sky = psychedelia.texture("distortion_sky") })
			local dome = MeshInstance3D.new()
			dome.mesh = nari.load("assets/psychedelia/distortion_dome.res")
			dome.extra_cull_margin = 16000.0
			dome.material_override = state.sky
			state.stage:add_child(dome)
			state.plane = psychedelia.material(PLANE, {
				note = psychedelia.texture("distortion_note"),
				waves = state.texture,
				move = options.move,
				warp = options.warp,
			})
			local plane = MeshInstance3D.new()
			local grid = QuadMesh.new()
			grid.subdivide_width = 79
			grid.subdivide_depth = 79
			plane.mesh = grid
			plane.extra_cull_margin = 16000.0
			plane.material_override = state.plane
			state.stage:add_child(plane)
		end,
		resize = function(state, scene)
			if state.stage then
				state.stage.size = Vector2i(scene.width, scene.height)
			end
		end,
		step = function(state, audio, scene)
			local ms = state.start + scene.time * 1000
			for index, wave in ipairs(WAVES) do
				local level = state.levels[index] + (psychedelia.single(bins.frequency(audio, wave[5])) / 255 - state.levels[index]) * options.rate
				state.levels[index] = level
				state.angle = state.angle + 0.00001
				local c, s = math.cos(state.angle), math.sin(state.angle)
				state.image:set_pixel(index - 1, 0, Color(wave[1] * c - wave[2] * s, wave[2] * c + wave[1] * s, wave[3], level * wave[4] * 14))
			end
			state.texture:update(state.image)
			state.spin = state.spin + state.levels[1] / 500
			state.turn = state.turn + state.levels[8] / 500
			state.sky:set_shader_parameter("turn", Color(state.spin, state.turn, 0.0, 0.0))
			state.reach = math.min(200.0, state.reach * 0.99 + (top(audio, 100, 50) * 0.25 + top(audio, 600, 40)) * 0.6)
			state.side = math.min(190.0, state.side * 0.99 + top(audio, 0, 10) * 0.7)
			local ex, ey, ez = options.eye(state.side, state.reach, ms / 81000)
			local at = options.at
			psychedelia.look(state.sky, ex, ey, ez, at[1], at[2], at[3])
			psychedelia.look(state.plane, ex, ey, ez, at[1], at[2], at[3])
			state.stage.render_target_update_mode = SubViewport.UPDATE_ONCE
		end,
		draw = function(canvas, state, _, scene)
			canvas:draw_texture_rect(state.stage:get_texture(), Rect2(0, 0, scene.width, scene.height), false)
		end,
	}
end

return {
	name = "Distortion",
	presets = {
		preset("Enlightenment", {
			move = false,
			warp = true,
			rate = 0.02,
			at = { 0.0, 0.0, 0.0 },
			eye = function(side, reach, t)
				local far = reach + 50
				return side + 100, math.sin(t + reach / 20) * far - 100, far * math.sin(t + reach / 20 + 1.57) + 50
			end,
		}),
		preset("Mutant camels", {
			move = true,
			warp = false,
			rate = 0.06,
			at = { 0.0, 0.0, 0.0 },
			eye = function(side, reach, t)
				local far = reach + 50
				return side + 100, math.sin(t + reach / 20) * far - 10, far * math.sin(t + reach / 20 + 1.57)
			end,
		}),
		preset("Purity", {
			move = true,
			warp = true,
			rate = 0.02,
			at = { -150.0, 0.0, 0.0 },
			eye = function(side, reach, t)
				local far = reach + 150
				return (190 - side) / 130 - 50, math.sin(t) * far - 10, far * math.sin(t + 1.57)
			end,
		}),
		preset("Satori", {
			move = true,
			warp = true,
			rate = 0.1,
			at = { -50.0, 100.0, -50.0 },
			eye = function(side, reach, t)
				local far = reach + 50
				return 240 - side, math.sin(t) * far - 10, far * math.sin(t + 1.57)
			end,
		}),
	},
}

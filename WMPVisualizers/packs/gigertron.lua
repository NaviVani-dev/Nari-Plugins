local psychedelia = require("packs.psychedelia")
local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"
local SHADER = "shaders/psychedelia/giger_bars.gdshader"

local function preset(name, options)
	local ring = options.ring
	return {
		name = name,
		layers = { CLEAR },
		params = { background = Color(0.0, 0.0, 0.0) },
		setup = function(state, scene)
			state.stage = psychedelia.stage(scene, options.fov)
			state.stage:get_camera_3d().near = 1.0
			state.image = Image.create(50, 50, false, Image.FORMAT_RF)
			state.texture = ImageTexture.create_from_image(state.image)
			state.material = psychedelia.material(SHADER, {
				heights = state.texture,
				ring = ring,
				wobble = options.wobble or 0.0,
				size = 5.0,
				deep = options.wobble and 10.0 or 5.0,
				fade = options.fade or 0,
				plain = options.plain or false,
				same = options.same or false,
				tall = options.tall or 1.0,
			})
			psychedelia.look_at(state.material, options.eye, options.at)
			state.row, state.spin = 0, 0.0
			local many = MultiMesh.new()
			many.transform_format = MultiMesh.TRANSFORM_3D
			many.mesh = BoxMesh.new()
			many.instance_count = ring and 2500 or 50
			local node = MultiMeshInstance3D.new()
			node.multimesh = many
			node.extra_cull_margin = 16000.0
			node.material_override = state.material
			state.stage:add_child(node)
		end,
		resize = function(state, scene)
			if state.stage then
				state.stage.size = Vector2i(scene.width, scene.height)
			end
		end,
		step = function(state, audio)
			for bar = 0, 49 do
				state.image:set_pixel(bar, state.row, Color(psychedelia.single(bins.frequency(audio, 10 + bar * 20)), 0.0, 0.0, 1.0))
			end
			state.texture:update(state.image)
			state.material:set_shader_parameter("head", state.row)
			if ring and not options.same then
				state.row = (state.row + 49) % 50
			end
			state.spin = state.spin + options.rate
			state.material:set_shader_parameter("spin", state.spin)
			state.stage.render_target_update_mode = SubViewport.UPDATE_ONCE
		end,
		draw = function(canvas, state, _, scene)
			canvas:draw_texture_rect(state.stage:get_texture(), Rect2(0, 0, scene.width, scene.height), false)
		end,
	}
end

return {
	name = "Gigertron 3D",
	presets = {
		preset("Cubetro", { plain = true, ring = false, rate = 0.0, fov = 1.5, eye = { 150.0, -145.0, 90.0 }, at = { 150.0, 100.0, 30.0 } }),
		preset("Guybrush", { ring = true, wobble = 0.1, rate = 0.1, fov = 2.0, eye = { 0.0, -250.0, 175.0 }, at = { 10.0, 0.0, 0.0 } }),
		preset("Polaris", { ring = true, rate = -0.1156, fov = 2.0, eye = { -20.0, -100.0, 150.0 }, at = { 10.0, 30.0, -75.0 } }),
		preset("Beausoleil", { ring = true, fade = 1, rate = -0.1156, fov = 2.0, eye = { -20.0, -100.0, -200.0 }, at = { 10.0, 30.0, 175.0 } }),
		preset("Blacklight", { ring = true, fade = 2, rate = -0.1156, fov = 1.5, eye = { -20.0, -300.0, 200.0 }, at = { 10.0, 30.0, -100.0 } }),
		preset("Arcadia", { ring = true, rate = -0.1156, fov = 1.5, eye = { 0.0, -300.0, 200.0 }, at = { 0.0, 30.0, -100.0 } }),
		preset("Etherium", { tall = 4.0, ring = true, rate = -0.1156, fov = 1.5, eye = { -20.0, -400.0, 100.0 }, at = { 10.0, 30.0, 75.0 } }),
		preset("Syntax", { same = true, ring = true, rate = 0.02, fov = 2.0, eye = { -20.0, -150.0, 150.0 }, at = { 10.0, 30.0, -175.0 } }),
		preset("Northern", { same = true, ring = true, rate = 0.02, fov = 1.5, eye = { -20.0, -250.0, 250.0 }, at = { 10.0, 30.0, -100.0 } }),
		preset("Dragons", { ring = true, wobble = 1.0, rate = 0.1, fov = 2.0, eye = { 0.0, -250.0, 175.0 }, at = { 10.0, 0.0, 0.0 } }),
	},
}

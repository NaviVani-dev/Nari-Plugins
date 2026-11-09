local snowtime = require("packs.snowtime")

local CLEAR = "shaders/common/clear.gdshader"
local SNOW = "shaders/softie/snow.gdshader"
local COUNT = 2000

local shader

return {
	name = "Softie the Snowman II",
	light = true,
	presets = {
		{
			name = "Snow and Softie",
			aspect = 4 / 3,
			layers = { CLEAR },
			setup = function(state, scene)
				snowtime.setup(state, 140, 45, 0.35)
				shader = shader or nari.load(SNOW)
				scene.canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				local material = ShaderMaterial.new()
				material.shader = shader
				material:set_shader_parameter("glow", snowtime.image("glow"))
				material:set_shader_parameter("flake", snowtime.image("flake"))
				material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
				local plane = QuadMesh.new()
				plane.size = Vector2(1.0, 1.0)
				local many = MultiMesh.new()
				many.transform_format = MultiMesh.TRANSFORM_2D
				many.mesh = plane
				many.instance_count = COUNT
				local node = Control.new()
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE
				node.material = material
				scene.canvas:add_child(node)
				node.draw:connect(function()
					node:draw_multimesh(many, nil)
				end)
				state.snow = { material = material, many = many, node = node }
				state.time = 0
			end,
			resize = function(state, scene)
				if state.snow then
					state.snow.material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
				end
			end,
			step = function(state, audio, scene)
				snowtime.step(state, audio)
				state.time = state.time + 1 / 30
				state.snow.material:set_shader_parameter("time", state.time)
			end,
			draw = function(canvas, state, audio, scene)
				snowtime.draw(canvas, state, audio, scene, "forest")
			end,
		},
	},
}

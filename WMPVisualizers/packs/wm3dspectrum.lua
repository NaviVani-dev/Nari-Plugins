local CLEAR = "shaders/common/clear.gdshader"
local HISTORY = "shaders/wm3dspectrum/history.gdshader"
local SURFACE = "shaders/wm3dspectrum/surface.gdshader"
local WIDTH = 128
local ROWS = 1024

local function spectrum(name, style, dots, smooth)
	return {
		name = name,
		layers = { CLEAR },
		setup = function(state, scene)
			local viewport = SubViewport.new()
			viewport.disable_3d = true
			viewport.size = Vector2i(WIDTH, ROWS)
			viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			scene.viewport:add_child(viewport)
			local rect = ColorRect.new()
			rect.size = Vector2(WIDTH, ROWS)
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			local feed = ShaderMaterial.new()
			feed.shader = nari.load(HISTORY)
			feed:set_shader_parameter("smooth_amount", smooth and 0.6 or 0.0)
			feed:set_shader_parameter("texel", 1 / ROWS)
			rect.material = feed
			viewport:add_child(rect)
			scene.materials[#scene.materials + 1] = feed
			local plane = PlaneMesh.new()
			plane.orientation = PlaneMesh.FACE_Y
			plane.size = Vector2(2, 2)
			plane.subdivide_width = WIDTH - 1
			plane.subdivide_depth = 399
			local surface = ShaderMaterial.new()
			surface.shader = nari.load(SURFACE)
			surface:set_shader_parameter("history", viewport:get_texture())
			surface:set_shader_parameter("style", style)
			surface:set_shader_parameter("dots", dots and 1.0 or 0.0)
			surface:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
			local mesh = MeshInstance2D.new()
			mesh.mesh = plane
			mesh.material = surface
			scene.viewport:add_child(mesh)
			state.feed, state.surface = viewport, surface
		end,
		resize = function(state, scene)
			if state.surface then
				state.surface:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
			end
		end,
		step = function(state)
			state.feed.render_target_update_mode = SubViewport.UPDATE_ONCE
		end,
	}
end

return {
	name = "3D Spectrum Analyzer",
	presets = {
		spectrum("Rose Garden", 0, false, false),
		spectrum("City Lights", 1, false, false),
		spectrum("Rose Garden Points", 0, true, false),
		spectrum("City Lights Points", 1, true, false),
		spectrum("Rose Garden - Smooth", 0, false, true),
		spectrum("City Lights - Smooth", 1, false, true),
		spectrum("Rose Garden Points - Smooth", 0, true, true),
		spectrum("City Lights Points - Smooth", 1, true, true),
	},
}

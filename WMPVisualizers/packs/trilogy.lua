local columns = require("packs.blazing_colors_columns")

local BARS = "shaders/trilogy/bars.gdshader"
local POINTS = "shaders/trilogy/points.gdshader"
local TICKS = 31

local trilogy = {}

local meshes = {}

local function point_field(count)
	if not meshes[count] then
		local many = MultiMesh.new()
		many.transform_format = MultiMesh.TRANSFORM_2D
		many.mesh = nari.load("assets/trilogy/dot.res")
		many.instance_count = count
		meshes[count] = many
	end
	return meshes[count]
end

local function cosine(value)
	return math.cos(math.rad(math.floor(value) % 360))
end

local function whole(value)
	return value >= 0 and math.floor(value) or math.ceil(value)
end

local function new_material(path)
	local material = ShaderMaterial.new()
	material.shader = nari.load(path)
	return material
end

local function surface(parent, material, width, height)
	local rect = ColorRect.new()
	rect.material = material
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = Vector2(width, height)
	parent:add_child(rect)
	return rect
end

local function point_node(parent, material, state, key)
	local node = Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.material = material
	parent:add_child(node)
	node.draw:connect(function()
		if state[key] then
			node:draw_multimesh(state[key], nil)
		end
	end)
	return node
end

local function build(state, scene)
	local viewport = scene.viewport
	state.flat_material = new_material(BARS)
	state.flat = surface(viewport, state.flat_material, 350, 320)
	state.point_material = new_material(POINTS)
	state.points = point_node(viewport, state.point_material, state, "many")
	state.overlay_material = new_material(BARS)
	state.overlay_material:set_shader_parameter("overlay", true)
	state.overlay = surface(viewport, state.overlay_material, 350, 320)
	state.trails = {}
	state.trail_at = 1
	for index = 1, 2 do
		local holder = SubViewport.new()
		holder.disable_3d = true
		holder.transparent_bg = true
		holder.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		holder.render_target_update_mode = SubViewport.UPDATE_DISABLED
		holder.size = Vector2i(352, 320)
		viewport:add_child(holder)
		local material = new_material(POINTS)
		material:set_shader_parameter("source", 1)
		local back_material = new_material(BARS)
		back_material:set_shader_parameter("copy", true)
		local back = surface(holder, back_material, 352, 320)
		local node = point_node(holder, material, state, "many")
		state.trails[index] = { viewport = holder, material = material, node = node, back = back, back_material = back_material }
	end
end

local function shared(state, key, value)
	state.flat_material:set_shader_parameter(key, value)
	state.point_material:set_shader_parameter(key, value)
	state.trails[1].material:set_shader_parameter(key, value)
	state.trails[2].material:set_shader_parameter(key, value)
end

local function warp_shared(state, key, value)
	state.point_material:set_shader_parameter(key, value)
	state.trails[1].material:set_shader_parameter(key, value)
	state.trails[2].material:set_shader_parameter(key, value)
end

local function apply(state, look)
	state.look = look
	local width = look.width or 350
	state.width = width
	state.pipe = columns.pipeline({ place = look.place or 8, mirror = look.mirror ~= false, keep = look.keep or 174, smooth = look.smooth, offset = look.offset, history = look.history, scatter = look.scatter, clamp_last = true, jag = look.jag or 0.3 })
	state.previous = {}
	for index = 1, 352 do
		state.previous[index] = 0.0
	end
	state.fields = { f46 = look.f46 or 0.0, f48 = look.f48 or 0.0, f43 = look.f43 or 0.0, roll = look.roll_start or math.random(0, 127) + 0.0 }
	state.counter = look.counter_start or 0
	state.skip = 0
	state.hide = false
	state.drift = { 0.0, 0.0 }
	state.stripe = 0
	state.turned = { look.i48 or 0, look.i49 or 0, look.i4a or 0 }
	state.turn_mode = look.i64 or 0
	state.mix = look.history or 0
	state.wave = look.f41 or 0.0
	shared(state, "palette", nari.load(look.palette or "assets/trilogy/palette.png"))
	shared(state, "field_width", width)
	shared(state, "mode", look.mode or 5)
	shared(state, "reach", look.r or 0)
	shared(state, "amount", look.amt or 0)
	state.flat.size = Vector2(width, 320)
	state.overlay.size = Vector2(width, 320)
	state.trail_on = look.source == 1 or look.source == 2
	state.points.visible = look.source == 0
	state.overlay.visible = state.trail_on
	warp_shared(state, "wave_curve", (look.f43 or 0.0) * 0.001)
	warp_shared(state, "wave_base", look.i5d or 0)
	warp_shared(state, "fade", math.floor(look.f5f or 0.0))
	state.many = point_field(width * 320)
	state.points:queue_redraw()
	state.point_material:set_shader_parameter("source", 0)
	for _, trail in ipairs(state.trails) do
		trail.viewport.size = Vector2i(width, 320)
		trail.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		trail.node:queue_redraw()
		trail.material:set_shader_parameter("source", look.source or 0)
		trail.back.visible = look.source == 2
		trail.back.size = Vector2(width, 320)
		trail.back_material:set_shader_parameter("field_width", width)
	end
	if state.trail_on then
		state.trails[1].material:set_shader_parameter("history", state.trails[2].viewport:get_texture())
		state.trails[2].material:set_shader_parameter("history", state.trails[1].viewport:get_texture())
		state.trails[1].back_material:set_shader_parameter("history", state.trails[2].viewport:get_texture())
		state.trails[2].back_material:set_shader_parameter("history", state.trails[1].viewport:get_texture())
		state.trails[1].viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		state.trails[2].viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	end
end

local function phase_of(look, fields, which)
	if which == 1 then
		return fields.f46
	elseif which == 2 then
		return fields.f48
	end
	return 0.0
end

local function step_look(state, audio)
	local look, fields = state.look, state.fields
	local pipe = state.pipe
	if look.tick then
		look.tick(state, fields, pipe.level)
	end
	fields.f46 = fields.f46 + (fields.s46 or look.s46 or 0.0)
	if fields.f46 > 360.0 then
		fields.f46 = fields.f46 - 360.0
	end
	fields.f48 = fields.f48 + (fields.s48 or look.s48 or 0.0)
	if fields.f48 > 360.0 then
		fields.f48 = fields.f48 - 360.0
	end
	if look.roll_speed then
		fields.roll = fields.roll + look.roll_speed
		while fields.roll > 256.0 do
			fields.roll = fields.roll - 256.0
		end
	end
	if state.skip <= 0 then
		for index = 1, 352 do
			state.previous[index] = pipe.heights[index]
		end
		pipe.step(audio, look.dynamic_history and state.mix or nil)
		state.skip = look.skip and whole(TICKS / 3) or 0
	else
		state.skip = state.skip - 1
	end
	local center = { math.floor(state.width / 2), 160 }
	local axis = phase_of(look, fields, look.i77 or 0)
	if look.i77 and look.i77 ~= 0 then
		center[1] = center[1] + whole((look.i45 or 0) * cosine(axis))
		center[2] = center[2] + whole((look.i46 or 0) * cosine(axis))
	else
		center[1] = center[1] + (look.i45 or 0)
		center[2] = center[2] + (look.i46 or 0)
	end
	local twist = fields.f43 * 0.1
	if look.i63 == 1 then
		twist = twist * cosine(fields.f46)
	elseif look.i63 == 2 then
		twist = twist * cosine(fields.f48)
	end
	local turn = { state.turned[1], state.turned[2], state.turned[3] }
	if state.turn_mode ~= 0 then
		local angle = whole(state.turn_mode == 1 and fields.f46 or fields.f48)
		for index = 1, 3 do
			if turn[index] ~= 0 then
				turn[index] = angle
			end
		end
	end
	local material = state.point_material
	if state.trail_on then
		state.drift[1] = state.drift[1] + (look.f53 or 0.0)
		state.drift[2] = state.drift[2] + (look.f54 or 0.0)
		local dx, dy = whole(state.drift[1]), whole(state.drift[2])
		state.drift[1] = state.drift[1] - dx
		state.drift[2] = state.drift[2] - dy
		state.trail_at = 3 - state.trail_at
		local trail = state.trails[state.trail_at]
		material = trail.material
		if look.source == 2 then
			material:set_shader_parameter("heights", pipe.heights)
			trail.back_material:set_shader_parameter("drift", Vector2i(dx, dy))
			trail.back_material:set_shader_parameter("fade", 15 - whole(cosine(fields.f46) * -10.0))
		else
			material:set_shader_parameter("heights", state.previous)
			material:set_shader_parameter("drift", Vector2i(dx, dy))
		end
		trail.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		state.overlay_material:set_shader_parameter("history", trail.viewport:get_texture())
	else
		material:set_shader_parameter("heights", pipe.heights)
	end
	material:set_shader_parameter("count", pipe.count)
	material:set_shader_parameter("roll", whole(fields.roll))
	material:set_shader_parameter("stripe", state.stripe)
	material:set_shader_parameter("center", Vector2i(center[1], center[2]))
	material:set_shader_parameter("wave", Vector2(state.wave, look.f42 or 0.0))
	material:set_shader_parameter("phase", Vector2(phase_of(look, fields, look.i5a or 0), phase_of(look, fields, look.i5b or 0)))
	material:set_shader_parameter("turn_x", state.turned[1])
	material:set_shader_parameter("turn_y", state.turned[2])
	material:set_shader_parameter("turn_z", state.turned[3])
	material:set_shader_parameter("angle_x", turn[1])
	material:set_shader_parameter("angle_y", turn[2])
	material:set_shader_parameter("angle_z", turn[3])
	material:set_shader_parameter("twist", twist)
	local flat = state.flat_material
	flat:set_shader_parameter("heights", pipe.heights)
	flat:set_shader_parameter("count", (look.flat ~= false and not state.hide) and pipe.count or 0)
	flat:set_shader_parameter("roll", whole(fields.roll))
	flat:set_shader_parameter("stripe", state.stripe)
	state.points.visible = look.source == 0 and not state.hide
	state.overlay.visible = state.trail_on and not state.hide
	state.stripe = (state.stripe + (look.stripe_speed or 0)) % 256
end

function trilogy.preset(name, looks, change)
	return {
		name = name,
		size = { 350, 320 },
		filter = "nearest",
		setup = function(state, scene)
			build(state, scene)
			state.current = #looks > 1 and trilogy.pick(#looks, 0) or 1
			state.hold = 1
			apply(state, looks[state.current])
		end,
		step = function(state, audio)
			if change then
				if state.hold > change then
					state.hold = 0
					state.current = trilogy.pick(#looks, state.current)
					apply(state, looks[state.current])
				end
				state.hold = state.hold + 1
			end
			step_look(state, audio)
		end,
	}
end

function trilogy.pick(count, current)
	local function draw()
		return math.random(0, 1) + 1 + math.random(0, 1)
	end
	local choice = draw()
	if choice == current then
		choice = draw()
	end
	if choice == current then
		choice = draw()
	end
	return math.min(choice, count)
end

trilogy.build = build
trilogy.apply = apply
trilogy.step = step_look

function trilogy.pack(title, looks)
	local presets = {}
	for index, look in ipairs(looks) do
		presets[index] = trilogy.preset(look.name, { look })
	end
	presets[#presets + 1] = trilogy.preset("Random Selection", looks, 1033)
	return { name = title, presets = presets }
end

return trilogy

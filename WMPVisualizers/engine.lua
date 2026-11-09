local engine = {}

local RATE = 30
local MAX_STEPS = 3
local PROBE_WIDTH = 16
local PROBE_HEIGHT = 9

local shaders = {}

local function shader(path)
	if not shaders[path] then
		shaders[path] = nari.load(path)
	end
	return shaders[path]
end

local function material(path, params)
	local result = ShaderMaterial.new()
	result.shader = shader(path)
	for key, value in pairs(params or {}) do
		result:set_shader_parameter(key, value)
	end
	return result
end

local function fill(node)
	node:set_anchors_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
end

local function surface(path, params)
	local rect = ColorRect.new()
	rect.material = material(path, params)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
end

function engine.new(area, preset, quality, stretch)
	local scene = {
		engine = engine,
		area = area,
		preset = preset,
		quality = quality,
		materials = {},
		state = {},
		clock = Time:get_ticks_usec(),
		pending = 0,
		frame = 0,
		time = 0,
	}

	local viewport = SubViewport.new()
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	area:add_child(viewport)
	scene.viewport = viewport

	local layers = {}
	if preset.feedback then
		layers[#layers + 1] = surface(preset.feedback, preset.params)
	end
	for _, path in ipairs(preset.layers or {}) do
		layers[#layers + 1] = surface(path, preset.params)
	end
	for _, layer in ipairs(layers) do
		viewport:add_child(layer)
		scene.materials[#scene.materials + 1] = layer.material
	end
	scene.layers = layers

	if preset.draw then
		local canvas = Control.new()
		canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if preset.blend == "add" then
			local blend = CanvasItemMaterial.new()
			blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			canvas.material = blend
		end
		viewport:add_child(canvas)
		canvas.draw:connect(function()
			if scene.audio and scene.width then
				preset.draw(canvas, scene.state, scene.audio, scene)
			end
		end)
		scene.canvas = canvas
	end

	local letterbox = preset.aspect and not stretch
	if letterbox then
		local back = ColorRect.new()
		fill(back)
		back.color = Color(0.0, 0.0, 0.0, 1.0)
		area:add_child(back)
	end

	local view = TextureRect.new()
	fill(view)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = letterbox and TextureRect.STRETCH_KEEP_ASPECT_CENTERED or TextureRect.STRETCH_SCALE
	view.texture_filter = preset.filter == "nearest" and CanvasItem.TEXTURE_FILTER_NEAREST or CanvasItem.TEXTURE_FILTER_LINEAR
	view.texture = viewport:get_texture()
	if preset.display then
		view.material = material(preset.display, preset.params)
		scene.materials[#scene.materials + 1] = view.material
	end
	area:add_child(view)
	scene.view = view

	local probe = SubViewport.new()
	probe.disable_3d = true
	probe.transparent_bg = false
	probe.size = Vector2i(PROBE_WIDTH, PROBE_HEIGHT)
	probe.render_target_update_mode = SubViewport.UPDATE_ONCE
	local sample = TextureRect.new()
	sample.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sample.stretch_mode = TextureRect.STRETCH_SCALE
	sample.size = Vector2(PROBE_WIDTH, PROBE_HEIGHT)
	sample.texture = viewport:get_texture()
	sample.material = view.material
	probe:add_child(sample)
	area:add_child(probe)
	scene.probe = probe

	engine.resize(scene)
	local unhook = area.resized:connect(function()
		if scene.alive then
			engine.resize(scene)
		end
	end)
	scene.alive = true
	viewport.tree_exiting:connect(function()
		scene.alive = false
		unhook()
	end)
	if preset.setup then
		preset.setup(scene.state, scene)
	end
	return scene
end

function engine.resize(scene)
	local size = scene.area.size
	if size.x < 2 or size.y < 2 then
		return
	end
	local height = math.min(scene.quality, math.floor(size.y))
	local width = math.max(1, math.floor(size.x * height / size.y + 0.5))
	if scene.preset.aspect then
		width = math.floor(height * scene.preset.aspect + 0.5)
	end
	local fixed = scene.preset.size
	if fixed then
		width, height = fixed[1], fixed[2]
	end
	scene.width, scene.height = width, height
	scene.viewport.size = Vector2i(width, height)
	scene.viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	for _, layer in ipairs(scene.layers) do
		layer.position = Vector2(0, 0)
		layer.size = Vector2(width, height)
	end
	if scene.canvas then
		scene.canvas.position = Vector2(0, 0)
		scene.canvas.size = Vector2(width, height)
	end
	scene.frame = 0
	for _, item in ipairs(scene.materials) do
		item:set_shader_parameter("resolution", Vector2(width, height))
		item:set_shader_parameter("frame", 0)
	end
	if scene.preset.resize then
		scene.preset.resize(scene.state, scene)
	end
end

function engine.set(scene, key, value)
	for _, item in ipairs(scene.materials) do
		item:set_shader_parameter(key, value)
	end
end

function engine.step(scene, data)
	if not scene.alive then
		return
	end
	local now = Time:get_ticks_usec()
	local elapsed = (now - scene.clock) / 1000000
	scene.clock = now
	scene.pending = math.min(scene.pending + elapsed, MAX_STEPS / RATE)
	if scene.pending < 1 / RATE then
		return
	end
	scene.pending = scene.pending - 1 / RATE
	scene.frame = scene.frame + 1
	scene.time = scene.time + 1 / RATE
	scene.audio = data
	local preset = scene.preset
	if preset.step then
		preset.step(scene.state, data, scene)
	end
	engine.set(scene, "bands", data.bands)
	engine.set(scene, "peaks", data.peaks)
	engine.set(scene, "wave", data.wave)
	engine.set(scene, "level", data.level)
	engine.set(scene, "bass", data.bass)
	engine.set(scene, "time", scene.time)
	engine.set(scene, "frame", scene.frame)
	if scene.canvas then
		scene.canvas:queue_redraw()
	end
	scene.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
end

function engine.brightness(scene)
	if not scene.alive or scene.frame < 2 then
		return nil
	end
	local image = scene.probe:get_texture():get_image()
	scene.probe.render_target_update_mode = SubViewport.UPDATE_ONCE
	if not image then
		return nil
	end
	local total = 0
	for y = 0, PROBE_HEIGHT - 1 do
		for x = 0, PROBE_WIDTH - 1 do
			local color = image:get_pixel(x, y)
			total = total + color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
		end
	end
	return total / (PROBE_WIDTH * PROBE_HEIGHT)
end

return engine

local bins = require("packs.wmp_bins")

local BLUR = "shaders/plenoptic/blur.gdshader"
local WARP = "shaders/plenoptic/warp.gdshader"
local SPARK = "shaders/plenoptic/spark.gdshader"
local WIDTH, HEIGHT = 256, 192
local STEP = 1 / 30
local CHANGE = 120
local CAPACITY = 1000

local spark_shader

local function unit()
	return math.random(0, 32767) * 3.0518509e-05
end

local function mix(a, b, t)
	return Color(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1.0)
end

local function cycle(a, b, time, rate)
	local at = (time * rate / 120) % 1024
	if at < 512 then
		return mix(a, b, at / 512)
	end
	return mix(b, a, (at - 512) / 512)
end

local BLUE = Color(0.0, 0.0, 1.0, 1.0)
local YELLOW = Color(1.0, 1.0, 0.0, 1.0)
local GREEN = Color(0.0, 1.0, 0.0, 1.0)
local ORANGE = Color(1.0, 0.627451, 0.0, 1.0)
local RED = Color(1.0, 0.0, 0.0, 1.0)
local BLUE_FULL = Color(0.0, 0.0, 1.0, 1.0)

local function wave(audio, index, channel)
	if audio.stereo then
		return bins.wave(audio, index % 1024, channel)
	end
	return bins.wave(audio, (index + channel * 37) % 1024)
end

local function ring(canvas, audio, cx, cy, radius, channel, color)
	local points = {}
	for step = 0, 160 do
		local index = (step * 1024 // 160) % 1024
		local angle = step / 160 * 6.2831853
		local reach = wave(audio, index, channel) * radius * 0.00390625
		points[#points + 1] = Vector2(math.floor((cx + math.cos(angle) * reach) * WIDTH) + 0.5, math.floor((cy + math.sin(angle) * reach) * HEIGHT) + 0.5)
	end
	canvas:draw_polyline(points, color)
end

local function line(canvas, audio, cy, channel, color)
	local points = {}
	for step = 0, 128 do
		local index = (step * 8) % 1024
		local y = wave(audio, index, channel) * 0.5 * 0.00390625 + cy - 0.25
		points[#points + 1] = Vector2(step / 128 * WIDTH, (1 - y) * HEIGHT)
	end
	canvas:draw_polyline(points, color)
end

local BAR_COLORS = {}
for index = 0, 3 do
	BAR_COLORS[index] = mix(ORANGE, YELLOW, (index + 0.5) / 4)
end

local function bars(canvas, audio)
	local center_x, center_y = WIDTH // 2, HEIGHT // 2
	local points, colors = {}, {}
	local count = 0
	for offset = 0, center_x - 1 do
		local value = bins.frequency(audio, math.min(offset * 8, 1023))
		local reach = math.floor(value * HEIGHT * 0.001953125)
		if reach > 0 then
			for side = -1, 1, 2 do
				local x = center_x + side * offset + 0.5
				for slice = 0, 3 do
					local from, to = reach * slice / 4, reach * (slice + 1) / 4
					local color = BAR_COLORS[slice]
					count = count + 1
					points[count * 4 - 3] = Vector2(x, center_y + from)
					points[count * 4 - 2] = Vector2(x, center_y + to)
					points[count * 4 - 1] = Vector2(x, center_y - from)
					points[count * 4] = Vector2(x, center_y - to)
					colors[count * 2 - 1] = color
					colors[count * 2] = color
				end
			end
		end
	end
	if count > 0 then
		canvas:draw_multiline_colors(points, colors)
	end
end

local function pool(state)
	if not state.many then
		spark_shader = spark_shader or nari.load(SPARK)
		local plane = QuadMesh.new()
		plane.size = Vector2(1.0, 1.0)
		state.many = MultiMesh.new()
		state.many.transform_format = MultiMesh.TRANSFORM_2D
		state.many.mesh = plane
		state.many.instance_count = CAPACITY * 2
		state.image = Image.create(CAPACITY, 1, false, Image.FORMAT_RGBAF)
		state.table = ImageTexture.create_from_image(state.image)
		state.material = ShaderMaterial.new()
		state.material.shader = spark_shader
		state.material:set_shader_parameter("data", state.table)
		state.material:set_shader_parameter("resolution", Vector2(WIDTH, HEIGHT))
		state.items = {}
	end
end

local function advance(item)
	item.age = item.age + STEP
	item.vx, item.vy, item.vz = item.vx + item.ax * STEP, item.vy + item.ay * STEP, item.vz + item.az * STEP
	item.x, item.y, item.z = item.x + item.vx * STEP, item.y + item.vy * STEP, item.z + item.vz * STEP
end

local function bounce(item)
	local speed = item.vx * item.vx + item.vy * item.vy + item.vz * item.vz
	if speed < 0.01 and math.abs(item.y) < 0.1 then
		item.vx, item.vy, item.vz = 0.0, 0.0, 0.0
	end
	if item.y > 0 then
		item.y = -item.y
		item.vy = -item.vy
		item.vx, item.vy, item.vz = item.vx * 0.5, item.vy * 0.5, item.vz * 0.5
	end
end

local function upload(state, material_values)
	local items, image = state.items, state.image
	local alive = 0
	for index = #items, 1, -1 do
		local item = items[index]
		if item.life < item.age then
			items[index] = items[#items]
			items[#items] = nil
		end
	end
	for index, item in ipairs(items) do
		image:set_pixel(index - 1, 0, Color(item.x, item.y, item.z, math.min(item.age / math.max(item.life, 0.001), 1.0)))
		alive = index
	end
	for index = alive, (state.alive or 0) - 1 do
		image:set_pixel(index, 0, Color(0.0, 0.0, 0.0, -1.0))
	end
	state.alive = alive
	state.table:update(image)
	state.many.visible_instance_count = alive * 2
	for key, value in pairs(material_values) do
		state.material:set_shader_parameter(key, value)
	end
end

local function new_item(x, y, z, vx, vy, vz, ay, life)
	return { x = x, y = y, z = z, vx = vx, vy = vy, vz = vz, ax = 0.0, ay = ay, az = 0.0, age = 0.0, life = life }
end

local function direction(x, y, z)
	local length = math.sqrt(x * x + y * y + z * z)
	return x / length, y / length, z / length
end

local kinds = {
	{
		running = 0, fade = 4.0, zoom = 1.05,
		post = function(canvas, _, audio, scene)
			local time = scene.time
			local left = cycle(BLUE, YELLOW, time, 1024)
			local right = cycle(GREEN, ORANGE, time, 1126.4)
			ring(canvas, audio, 0.35, 0.5, 0.25, 0, left)
			ring(canvas, audio, 0.35, 0.5, 0.255, 0, left)
			ring(canvas, audio, 0.65, 0.5, 0.25, 1, right)
			ring(canvas, audio, 0.65, 0.5, 0.255, 1, right)
		end,
	},
	{
		running = 0, fade = 4.0, zoom = 1.03, additive = true,
		post = function(canvas, _, audio)
			line(canvas, audio, 0.25, 0, RED)
			line(canvas, audio, 0.26, 0, RED)
			line(canvas, audio, 0.75, 1, BLUE_FULL)
			line(canvas, audio, 0.74, 1, BLUE_FULL)
		end,
	},
	{
		running = 1, fade = 8.0, zoom = 1.0,
		pre = function(canvas, _, audio)
			bars(canvas, audio)
		end,
	},
	{
		running = 1, fade = 8.0, zoom = 1.0, sparks = true,
		step = function(state, level)
			local items = state.items
			for _ = 1, 6 do
				if #items < 200 then
					local x, y, z = direction(unit() - 0.5, unit() - 0.5, unit() - 0.5)
					local reach = 0.2 * level * 0.015625
					local vx, vy, vz = direction(unit() - 0.5, unit() - 0.5, unit() - 0.5)
					items[#items + 1] = new_item(x * reach, y * reach - 0.5, z * reach, vx * 0.2, vy * 0.2, vz * 0.2, 0.0, math.random(0, 32767) * 9.1555528e-05)
				end
			end
			for _, item in ipairs(items) do
				local radius = math.sqrt(item.x * item.x + item.z * item.z)
				item.ay = math.max(-(0.15 / math.max(radius, 0.0001)), -0.4)
				local pull = math.min(radius * 10.0, 2.0)
				item.ax, item.az = -item.x * pull, -item.z * pull
				advance(item)
			end
			upload(state, { eye_y = -0.9, yaw = 0.0, flat_mirror = 1.0 })
		end,
	},
	{
		running = 1, fade = 24.0, zoom = 1.0, sparks = true,
		step = function(state, level)
			local items = state.items
			if level * 0.2 >= 0.1 then
				for index = 16, 1, -1 do
					if #items < CAPACITY then
						local angle = index * 6.2831853 / 16 + unit() * 6.2831853 / 16
						local vx, _, vz = direction(math.cos(angle), -1.0, math.sin(angle))
						items[#items + 1] = new_item(0.0, 0.0, 0.0, vx * 0.47, -0.3 - level * 0.14285714, vz * 0.47, 6.0, 2.0)
					end
				end
			end
			for _, item in ipairs(items) do
				advance(item)
				bounce(item)
			end
			upload(state, { eye_y = -0.7, yaw = 0.0, flat_mirror = 0.0 })
		end,
	},
	{
		running = 1, fade = 20.0, zoom = 1.0, sparks = true,
		step = function(state, level)
			local items = state.items
			state.phase = state.phase or 0.0
			state.yaw = (state.yaw or 0.0) + STEP * 0.1 * 6.2831853
			local count = level > 5 and 4 or 1
			for _ = 1, count do
				for side = -1, 1, 2 do
					if #items < CAPACITY then
						local vx, _, vz = direction(math.cos(state.phase) * side, -1.0, math.sin(state.phase) * side)
						items[#items + 1] = new_item(0.0, 0.0, 0.0, vx * 0.47, -0.3 - level * 0.14285714, vz * 0.47, 6.0, 4.0)
					end
				end
				state.phase = state.phase + 6.2831853 / 60 * 0.5
			end
			for _, item in ipairs(items) do
				advance(item)
				bounce(item)
			end
			upload(state, { eye_y = -0.9, yaw = state.yaw, flat_mirror = 0.0 })
		end,
	},
}

local function loudness(audio)
	local total = 0
	for index = 0, 63 do
		local value = bins.sample(audio, index / 63) * 127
		total = total + value * value
	end
	return math.sqrt(total / 64)
end

local function select(state, scene, index)
	local kind = kinds[index]
	state.kind = kind
	state.current = state.stores[index]
	if kind.sparks then
		pool(state.current)
		scene.canvas.material = state.current.material
	else
		scene.canvas.material = nil
	end
	if state.post then
		state.post.material = kind.additive and state.add or nil
	end
	scene.engine.set(scene, "running", kind.running)
	scene.engine.set(scene, "fade", kind.fade)
	scene.engine.set(scene, "zoom", kind.zoom)
end

local function make(name, index)
	return {
		name = name,
		size = { WIDTH, HEIGHT },
		filter = "nearest",
		feedback = BLUR,
		layers = { WARP },
		setup = function(state, scene)
			local viewport = scene.viewport
			viewport:move_child(scene.canvas, 0)
			local post = Control.new()
			post.mouse_filter = Control.MOUSE_FILTER_IGNORE
			viewport:add_child(post)
			viewport:move_child(post, 2)
			local copy = BackBufferCopy.new()
			copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
			viewport:add_child(copy)
			viewport:move_child(copy, 3)
			post.draw:connect(function()
				if scene.audio then
					if state.kind.post then
						state.kind.post(post, state.current, scene.audio, scene)
					end
				end
			end)
			state.post = post
			state.add = CanvasItemMaterial.new()
			state.add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			state.stores = {}
			for slot = 1, #kinds do
				state.stores[slot] = {}
			end
			state.timer = 0
			if index then
				select(state, scene, index)
			end
		end,
		step = function(state, audio, scene)
			if not index then
				state.timer = state.timer - STEP
				if state.timer <= 0 then
					state.timer = CHANGE
					select(state, scene, math.random(1, #kinds))
				end
			end
			local level = loudness(audio)
			if state.kind.step then
				state.kind.step(state.current, level)
			end
			state.post:queue_redraw()
		end,
		draw = function(canvas, state, audio, scene)
			if state.kind.sparks then
				canvas:draw_multimesh(state.current.many, nil)
			elseif state.kind.pre then
				state.kind.pre(canvas, state.current, audio, scene)
			end
		end,
	}
end

return {
	name = "Plenoptic",
	presets = {
		make("Random"),
		make("Smokey Circles", 1),
		make("Smokey Lines", 2),
		make("Vox", 3),
		make("Flame", 4),
		make("Fountain", 5),
		make("Spyro", 6),
	},
}

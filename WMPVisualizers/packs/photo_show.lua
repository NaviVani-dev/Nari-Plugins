local photo_show = {}

local PHOTO = "shaders/photo_show/photo.gdshader"
local SPRITES = "shaders/photo_show/sprites.gdshader"
local CAPACITY = 2048

local function cosd(value)
	return math.cos(math.rad(math.floor(value)))
end

local function rising(t)
	return (cosd((t + 1) * -90) + 1) * 255
end

local function falling(t)
	return (cosd(t * 90 + 180) + 1) * 255
end

local function flown(t)
	return (1 - t) ^ 4
end

local function spun(yaw, pitch, roll, in_yaw, in_pitch, in_roll, away, back, in_fade)
	return {
		out = function(t, f)
			local c = cosd((t + 1) * -90)
			f.yaw, f.pitch, f.roll = c * yaw, c * pitch, c * roll
			f.far = away and away(c, t) or 0
			return falling(t)
		end,
		into = function(t, f)
			local c = cosd((t + 1) * -90) + 1
			f.yaw, f.pitch, f.roll = c * in_yaw, c * in_pitch, c * in_roll
			f.far = back and back(c, t) or 0
			return in_fade and in_fade(t) or rising(t)
		end,
	}
end

local function rain(step)
	local base = spun(0, 0, 0, 0, 0, 0)
	return { out = function(t, f, water)
		step(t, f, water)
		return base.out(t, f)
	end, into = function(t, f)
		f.calm = true
		return base.into(t, f)
	end }
end

local function drop(water, x, y, power)
	local h = water.speed
	for dy = -1, 1 do
		for dx = -1, 1 do
			local i = ((y + dy) % 64) * 64 + (x + dx) % 64 + 1
			local weight = (dx == 0 and dy == 0) and 1 or ((dx == 0 or dy == 0) and 0.25 or 0.125)
			h[i] = h[i] - power * weight
		end
	end
	water.live = true
end

local function burst(place_x, place_z)
	local base = spun(0, 0, 0, 0, 0, 0)
	return { out = function(t, f, water, sparks)
		if t < 0.4 and sparks then
			sparks.fire(place_x, place_z)
		end
		return base.out(t, f)
	end, into = base.into }
end

local grown = 1

local EFFECTS = {
	[6] = { out = function(t) return falling(t) end, into = function(t) return (cosd(t * 90 + 100) + 1) * 255 end },
	[7] = spun(0, 0, 0, 0, 0, 0, function(_, t) return t ^ 3 * 250 end, function(_, t) return flown(t) * 255 end),
	[8] = spun(0, 1.6, 0, 0, -1.6, 0, function(c, t) return (c * 1.6) ^ 2 * t * 50 end, function(_, t) return flown(t) * 155 end),
	[10] = spun(3, 0, 0, -3, 0, 0, function(c, t) return (c * 3) ^ 3 * t * -250 end, function(c) return c * ((c * 3) ^ 2) * 155 end),
	[11] = spun(0, 0, 1.6, 0, 0, 1.6),
	[12] = spun(0, 1.6, 0, 0, 1.6, 0),
	[13] = spun(-1.6, 1.3, -1.5, 0, 0, 0, function(c, t) return t * c * -1.5 * 50 end, nil, function(t) return flown(t) * 255 end),
	[14] = spun(0, 0, -1.6, -1.6, -1.5, 0, function(c, t) return c * -1.6 * t * 60 end, function(_, t) return flown(t) * 155 end),
	[9] = {
		out = function(t, f)
			local c = cosd((t + 1) * -90)
			f.pitch = c * 1.6
			f.yaw = f.pitch ^ 2 * t * 4
			f.roll = 0
			f.far = f.yaw ^ 2 * t * 20
			return falling(t)
		end,
		into = function(t, f)
			local c = cosd((t + 1) * -90) + 1
			f.yaw, f.pitch, f.roll, f.far = c * -1.5, c * -1.5, 0, flown(t) * 155
			return rising(t)
		end,
	},
	water_scatter = rain(function(_, _, water)
		if not water.live then
			for _ = 1, 80 do
				drop(water, math.random(0, 63), math.random(0, 63), 0.5)
			end
		end
	end),
	water_rain = rain(function(t, _, water)
		if t < 0.2 then
			drop(water, math.random(0, 63), math.random(0, 63), 2)
		end
	end),
	water_storm = rain(function(_, _, water)
		drop(water, math.random(0, 63), math.random(0, 63), 12)
	end),
	water_spout = {
		out = function(t, f, water)
			if t < 0.05 then
				grown = 2
			end
			grown = grown * 1.06
			drop(water, 32, 32, grown)
			f.pitch = cosd((t + 1) * -90) * 1.5
			return falling(t)
		end,
		into = function(t, f)
			f.calm = true
			f.pitch, f.far = (cosd((t + 1) * -90) + 1) * -1.5, flown(t) * 155
			return rising(t)
		end,
	},
	water_tilt = {
		out = function(t, f, water)
			if t < 0.05 then
				grown = 4
			end
			grown = grown * 1.025
			drop(water, 32, 32, grown)
			f.roll, f.far = cosd((t + 1) * -90) * 1.6, t * 50
			return falling(t)
		end,
		into = function(t, f)
			f.calm = true
			f.roll, f.pitch, f.far = 0, (cosd((t + 1) * -90) + 1) * -1.5, flown(t) * 155
			return rising(t)
		end,
	},
	water_wake = {
		out = function(t, f, water)
			local a = t * 6.28
			drop(water, math.floor(32 + math.cos(a) * 24), math.floor(32 + math.sin(a) * 24), 0.5)
			drop(water, math.floor(32 - math.cos(a) * 24), math.floor(32 - math.sin(a) * 24), 0.5)
			if t > 0.67 then
				f.side, f.lift = (f.side or 0) - 0.075, (f.lift or 0) - 0.2
			end
			return falling(t)
		end,
		into = function(t, f)
			f.calm, f.side, f.lift = true, 0, 0
			return rising(t)
		end,
	},
	water_fall = {
		out = function(t, f, water)
			f.pitch = cosd((t + 1) * -90) * 1.6
			f.rise = (f.rise or 0) - t ^ 3 * 100 * (t > 0.6 and 1 or 0.05)
			drop(water, 32, 32, 2)
			return falling(t)
		end,
		into = function(t, f)
			f.calm, f.pitch, f.rise = true, 0, 0
			return rising(t)
		end,
	},
	burst_left = burst(-0.75, -0.5),
	burst_right = burst(8, -0.625),
	roll = spun(0, 0, 1.6, 0, 0, 1.6),
	plain = spun(0, 0, 0, 0, 0, 0),
}

local function step_water(water, keep)
	local h, v = water.height, water.speed
	local total = 0
	for y = 0, 63 do
		local up, down = ((y + 63) % 64) * 64, ((y + 1) % 64) * 64
		local row = y * 64
		for x = 0, 63 do
			local l, r = (x + 63) % 64, (x + 1) % 64
			local near = (h[row + l + 1] + h[row + r + 1] + h[up + x + 1] + h[down + x + 1]) * 0.16667
			local far = (h[up + l + 1] + h[up + r + 1] + h[down + l + 1] + h[down + r + 1]) * 0.083333
			local i = row + x + 1
			local s = v[i]
			if s > 20 or s < -20 then
				s = s * 0.9
			end
			s = (near + far - h[i]) * 0.25 + s
			v[i] = s
			total = total + s + h[i]
		end
	end
	total = total / 4096
	local image = water.image
	for y = 0, 63 do
		for x = 0, 63 do
			local i = y * 64 + x + 1
			local value = (v[i] + h[i] - total) * keep
			h[i] = value
			image:set_pixel(x, y, Color(value, 0.0, 0.0, 1.0))
		end
	end
	water.texture:update(image)
end

local function clear_water(water)
	for i = 1, 4096 do
		water.height[i], water.speed[i] = 0.0, 0.0
	end
	water.live = false
end

local function new_water(material)
	local water = { height = {}, speed = {}, image = Image.create(64, 64, false, Image.FORMAT_RF) }
	clear_water(water)
	water.texture = ImageTexture.create_from_image(water.image)
	material:set_shader_parameter("water", water.texture)
	return water
end

local function advance(state, scene)
	state.texture = nari.load("assets/" .. state.folder .. "/photo" .. state.order[state.index] .. ".jpg")
	local size = state.texture:get_size()
	local scale = math.min(state.fit[1] / size.x, state.fit[2] / size.y) * scene.height / 480
	local halfwidth, halfheight = size.x * scale / 2 + 7 * scene.height / 480, size.y * scale / 2 + 7 * scene.height / 480
	state.material:set_shader_parameter("photo", state.texture)
	state.material:set_shader_parameter("half_size", Vector2(halfwidth, halfheight))
	state.material:set_shader_parameter("edge", 7 * scene.height / 480 / (halfwidth * 2))
end

local function choose(state, options)
	if (state.quiet or 255) < 11 then
		state.effect = EFFECTS[6]
		return
	end
	local list = options.effects
	local index = math.random(#list)
	if list[index] == state.last then
		index = index % #list + 1
	end
	state.last = list[index]
	state.effect = EFFECTS[state.last]
end

local function new_sparks(state, scene, options, spark)
	local system = { next = 0, clock = 0, changed = false }
	system.image = Image.create(256, 32, false, Image.FORMAT_RGBAF)
	system.table = ImageTexture.create_from_image(system.image)
	local link = options.trail or 10
	local many = MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_2D
	local quad = QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	many.mesh = quad
	many.instance_count = CAPACITY * link
	local material = ShaderMaterial.new()
	material.shader = nari.load(SPRITES)
	material:set_shader_parameter("table", system.table)
	material:set_shader_parameter("spark", spark)
	material:set_shader_parameter("trail", link)
	material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
	material:set_shader_parameter("size", options.point or 0.6)
	local rest = options.rest_color or { 0.0, 0.0, 0.0 }
	material:set_shader_parameter("rest_color", Color(rest[1], rest[2], rest[3]))
	local node = Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.size = Vector2(scene.width, scene.height)
	node.material = material
	scene.viewport:add_child(node)
	node.draw:connect(function()
		node:draw_multimesh(many, nil)
	end)
	RenderingServer:canvas_item_set_custom_rect(node:get_canvas_item(), true, Rect2(0, 0, scene.width, scene.height))
	system.material, system.node = material, node
	function system.emit(x, y, z, vx, vy, vz, gravity, r, g, b, life, fade, step, growth)
		local slot = system.next
		system.next = (slot + 1) % CAPACITY
		local px, py = (slot % 64) * 4, math.floor(slot / 64)
		local image = system.image
		image:set_pixel(px, py, Color(x * 1.0, y * 1.0, z * 1.0, system.clock * 1.0))
		image:set_pixel(px + 1, py, Color(vx * 1.0, vy * 1.0, vz * 1.0, gravity * 1.0))
		image:set_pixel(px + 2, py, Color(r * 1.0, g * 1.0, b * 1.0, 1.0))
		image:set_pixel(px + 3, py, Color(life * 1.0, fade * 1.0, step / link, growth * 1.0))
		system.changed = true
	end
	function system.flush(camera)
		if system.changed then
			system.table:update(system.image)
			system.changed = false
		end
		material:set_shader_parameter("now", system.clock * 1.0)
		material:set_shader_parameter("camera", camera * 1.0)
		node:queue_redraw()
	end
	return system
end

function photo_show.make(name, folder, options)
	local background, logo, spark
	local order = {}
	for index = 1, options.count do
		order[index] = index
	end
	local LENGTH, HOLD, REST = options.length or 6.0, options.hold or 1.0, options.rest or 25.96
	return {
		name = name,
		aspect = 4 / 3,
		setup = function(state, scene)
			background = background or nari.load("assets/" .. folder .. "/background.jpg")
			logo = logo or nari.load("assets/" .. folder .. "/" .. options.logo[1])
			spark = spark or nari.load("assets/" .. folder .. "/spark.jpg")
			state.folder, state.order, state.index, state.fit = folder, order, 1, options.fit or { 510, 333 }
			state.phase, state.clock = "in", 0
			state.pose = { yaw = 0, pitch = 0, roll = 0, far = 0 }
			state.quiet = nil
			choose(state, options)
			local plane = PlaneMesh.new()
			plane.orientation = PlaneMesh.FACE_Y
			plane.size = Vector2(2, 2)
			plane.subdivide_width = 63
			plane.subdivide_depth = 63
			state.material = ShaderMaterial.new()
			state.material.shader = nari.load(PHOTO)
			state.material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
			local mesh = MeshInstance2D.new()
			mesh.mesh = plane
			mesh.material = state.material
			scene.viewport:add_child(mesh)
			if options.water then
				state.water = new_water(state.material)
			end
			state.sparks = new_sparks(state, scene, options, spark)
			if options.emitter then
				state.emitter = options.emitter(state.sparks)
			end
			advance(state, scene)
		end,
		resize = function(state, scene)
			if state.material then
				state.material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
				state.sparks.material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
				state.sparks.node.size = Vector2(scene.width, scene.height)
				advance(state, scene)
			end
		end,
		step = function(state, audio, scene)
			state.clock = state.clock + 1 / 30
			state.quiet = (state.quiet or 255) * 0.985 + (audio.level or 0) * 255 * 0.015
			local fade = 0
			local f = state.pose
			if state.phase == "in" then
				local t = math.min(state.clock / LENGTH, 1)
				fade = state.effect.into(t, f, state.water, state.sparks)
				if t >= 1 then
					f.yaw, f.pitch, f.roll, f.far, fade = 0, 0, 0, 0, 0
					state.phase, state.clock = "hold", 0
				end
			elseif state.phase == "hold" then
				if state.clock >= HOLD then
					state.phase, state.clock = "out", 0
				end
			else
				local t = math.min(state.clock / LENGTH, 1)
				fade = state.effect.out(t, f, state.water, state.sparks)
				if t >= 1 then
					f.yaw, f.pitch, f.roll, f.far = 0, 0, 0, 0
					state.index = state.index % #order + 1
					advance(state, scene)
					choose(state, options)
					state.phase, state.clock = "in", 0
					fade = 255
				end
			end
			local water = state.water
			if water and f.calm then
				f.calm = false
				if water.live then
					clear_water(water)
					water.image:fill(Color(0.0, 0.0, 0.0, 1.0))
					water.texture:update(water.image)
				end
			end
			if water and water.live then
				step_water(water, 1.0)
			end
			local unit = scene.height * 0.5 * 1.73205 / REST
			local material = state.material
			material:set_shader_parameter("swell", (water and water.live) and unit or 0.0)
			material:set_shader_parameter("angles", Color(f.yaw, f.pitch, f.roll))
			material:set_shader_parameter("shift", Color((f.side or 0) * unit, (f.lift or 0) * unit, (f.rise or 0) * unit))
			material:set_shader_parameter("camera", 1.0 + f.far / REST)
			material:set_shader_parameter("fade", fade / 255)
			local sparks = state.sparks
			sparks.clock = sparks.clock + 1 / 30
			if state.emitter then
				state.emitter(audio, state)
			end
			if sparks.fire and sparks.pending then
				sparks.pending = false
			end
			sparks.flush(REST + f.far)
		end,
		draw = function(canvas, state, audio, scene)
			local unit = scene.height / 480
			local source = background:get_size()
			local crop = math.min(source.x, source.y * scene.width / scene.height)
			local tall = math.min(source.y, source.x * scene.height / scene.width)
			canvas:draw_texture_rect_region(background, Rect2(0, 0, scene.width, scene.height), Rect2((source.x - crop) / 2, (source.y - tall) / 2, crop, tall))
			local size = logo:get_size()
			canvas:draw_texture_rect(logo, Rect2(options.logo[2] * unit, options.logo[3] * unit, size.x * unit, size.y * unit), false)
		end,
	}
end

function photo_show.spectrum_clock(sparks)
	local bins = require("packs.wmp_bins")
	local spin, time = { 0.0, 0.0, 0.0 }, 0.0
	local place = { 0.0, 15.0, 0.0 }
	local wave, ramp, means = 0.0, 0, {}
	local life, fade, step, growth = 0.102, 0.011, 0.2, 1.273
	local TWO = 0.105
	local function hand(angle, r, g, b, radius, gravity)
		local c, s = math.cos(angle), math.sin(angle)
		sparks.emit(c * radius, 4.23, s * radius, c * (radius - 2), 0.0, s * (radius - 2), gravity or 0.0, r, g, b, life, fade, step, growth)
	end
	return function(audio, state)
		local seconds = sparks.clock + 15
		local angle = (seconds % 60) * TWO
		local minute = ((seconds / 60) % 60 + 15) * TWO
		hand(angle * 4, 0.5, 0.5, 0.0, -1.5)
		hand(angle, 0.13, 0.2, 1.0, -0.76)
		hand(minute, 0.0, 0.18, 1.0, -1.04)
		hand(minute * 0.066 + 15 * TWO, 0.0, 0.18, 1.0, -0.4)
		local total, count = 0, 0
		for bin = 0, 254, 8 do
			local value = bins.frequency(audio, bin)
			if value > 0 then
				total, count = total + value, count + 1
			end
		end
		local mean = count > 0 and total / count or 0
		means[#means + 1] = mean
		if #means > 67 then
			table.remove(means, 1)
		end
		local level = 0
		for _, value in ipairs(means) do
			level = level + value
		end
		level = level / math.max(#means, 1)
		if level < 6 then
			spin[1], spin[2], spin[3] = spin[1] * 0.85, spin[2] * 0.85, spin[3] * 0.85
			place[1], place[2], place[3] = place[1] * 0.95, place[2] * 0.95, place[3] * 0.95
		else
			wave = wave + 0.004
			spin[1], spin[2], spin[3] = spin[1] + 0.025, spin[2] + 0.01, spin[3] + 0.005
			if place[3] < 9 then
				place[3] = math.sin(wave) * 20
			end
			place[1] = math.sin(wave * 0.5) * 5
			place[2] = math.sin(wave * 5) * 10 + 15
		end
		sparks.material:set_shader_parameter("orbit", Color(spin[1], spin[2], spin[3]))
		sparks.material:set_shader_parameter("place", Color(place[1], place[2], place[3]))
		if level >= 20 then
			local t = angle
			growth = 0.973 - (1 - math.cos(t))
			life, step = 0.136, 0.334
			local jets = math.min(math.floor(mean * mean * 0.0018), 20)
			for i = 1, jets - 1 do
				local v = bins.frequency(audio, i * 3 + 2)
				local gravity = math.sin(v * 0.45 * t) * v * 0.19
				local spinup = (i + 17) * i * i * 0.005 * level * (t + 60) ^ 3 * 1.4e-07
				local radius = -v * 0.08
				local c, s = math.cos(spinup), math.sin(spinup)
				fade = 0.077 - math.min(v * 0.00038, 0.05)
				ramp = ramp % 6 + 1
				local tint = math.min(bins.frequency(audio, i * 10 + ramp * 5) * 0.01, 1.0)
				local r, g, b = 0, 0, 0
				if ramp == 1 then
					r, b = 1, 0
					g = tint
				elseif ramp == 2 then
					g, r = 1, tint
				elseif ramp == 3 then
					g, b = 1, tint
				elseif ramp == 4 then
					b, g = 1, tint
				elseif ramp == 5 then
					b, r = 1, tint
				else
					r, b = 1, tint
				end
				sparks.emit(c * radius, 4.23, s * radius, c * (radius - 6), 0.0, s * (radius - 6), gravity, r, g, b, life, fade, step, growth)
			end
		end
	end
end

function photo_show.fixed_sparks(sparks)
	local TWO = 0.105
	return function()
		local seconds = sparks.clock + 15
		for index = 0, 3 do
			local angle = (seconds % 60) * TWO * (index + 1) + index * 1.57
			local radius = -1.5 - index * 2
			local c, s = math.cos(angle), math.sin(angle)
			sparks.emit(c * radius * 3, 4.23, s * radius * 2, c * 6.0 * (math.random() - 0.5), 0.0, s * 6.0 * (math.random() - 0.5), 0.623, 0.9, 1.0, 0.3, 0.086, 0.301, 0.2, 1.04)
		end
	end
end

function photo_show.bursts(sparks)
	sparks.material:set_shader_parameter("place", Color(0.0, 0.0, 0.0))
	sparks.fire = function(bias_x, bias_z)
		for _ = 1, 50 do
			local a = math.random() * 6.28319
			local b = math.random() * 0.785398
			local vx = math.cos(a) * math.sin(b) * 20
			local vz = math.sin(a) * math.sin(b) * 20
			local vy = math.cos(b) * math.random() * 40
			sparks.emit(bias_x, 0.23, bias_z, vx, vy, vz, 10.0, 1.0, 1.0, 1.0, 1.0, 0.45, 0.04, 1.0)
		end
	end
	return nil
end

return photo_show

local measure = require("packs.measuring_spectrum")
local bins = require("packs.wmp_bins")

local COLUMNS = "shaders/musical_colors/columns.gdshader"
local SHOW = "shaders/musical_colors/show.gdshader"
local STAR = "shaders/musical_colors/star.gdshader"
local SIZE = { 350, 320 }
local SLOT = { [4] = 0, [6] = 1, [9] = 2, [12] = 3, [13] = 4, [14] = 5, [15] = 6, [17] = 7, [20] = 8, [21] = 9, [22] = 10, [23] = 11, [24] = 12, [25] = 13, [30] = 14, [35] = 15, [42] = 16, [7] = 17, [8] = 18, [18] = 19, [19] = 20, [28] = 21, [29] = 22, [34] = 23 }
local RADIANS = math.pi / 180.0
local BIN = 44100.0 / 2048.0

local slots = {}
for bin = 0, 255 do
	slots[bin] = measure.position((bin * 4 + 2) * BIN)
end

local sprites
local dots_shader
local flame_shader

local function atlas()
	sprites = sprites or nari.load("assets/musical_colors/sprites.png")
	return sprites
end

local function read(state, audio)
	local bytes = state.bytes
	local total = 0
	for bin = 0, 255 do
		local value
		if audio.stereo then
			value = bins.shrunk(audio, bin)
		else
			local spike = 0.4 + 0.6 * math.max(0.0, math.min(1.0, (0.15 - bin / 255.0) * 10.0))
			value = math.min(255.0, measure.at(audio, slots[bin]) * (1.0 + (math.sqrt(-math.log(1.0 - math.random() * 0.999)) - 0.886) * spike))
		end
		bytes[bin] = math.floor(value)
		if bin < 255 then
			total = total + bytes[bin]
		end
	end
	state.instant = math.min(255, math.floor(total / 106))
	state.ring_at = (state.ring_at + 1) % 10
	state.ring[state.ring_at] = state.instant
	local sum = 0
	for index = 0, 9 do
		sum = sum + state.ring[index]
	end
	state.level = math.floor(sum / 10)
end

local function shrink(from, size, scale, to)
	local out, at, carry, step = 0, 0, 0, 256 - scale
	while true do
		to[out] = from[at]
		out = out + 1
		repeat
			at = at + 1
			if at >= size then
				return out
			end
			carry = carry + step
			local over = carry >= 256
			if over then
				carry = carry - 256
			end
		until not over
	end
end

local function grow(from, size, scale, to)
	if size >= 512 then
		for index = 0, size - 1 do
			to[index] = from[index]
		end
		return size
	end
	local out, carry, step = 0, 0, 512 - math.min(scale, 512)
	for at = 0, size - 1 do
		to[out] = from[at]
		out = out + 1
		if out >= 512 then
			return out
		end
		carry = carry + step
		if carry >= 256 then
			carry = carry - 256
		else
			to[out] = math.floor((from[at] + (from[at + 2] or from[at])) / 2)
			out = out + 1
			if out >= 512 then
				return out
			end
		end
	end
	return out
end

local function spectrum(state, audio, spec)
	read(state, audio)
	local a, b, bytes = state.a, state.b, state.bytes
	if spec.random == 2 then
		local at = 0
		while at <= 254 do
			local first = math.random(0, 255)
			local run = math.random(0, 15)
			if first + run > 254 then
				first = run
			end
			for offset = 0, run do
				if at > 254 then
					break
				end
				a[at] = bytes[first + offset]
				at = at + 1
			end
		end
	else
		for at = 0, 254 do
			a[at] = bytes[at + 1]
		end
	end
	if state.hold > 0 then
		state.hold = state.hold - 1
		return false
	end
	state.hold = spec.hold or 0
	local size = 255
	local source = a
	if spec.mode == 1 or spec.mode == 3 or spec.mode == 4 or spec.mode == 5 then
		for at = 0, 254 do
			b[255 + at] = a[at]
			b[at] = a[255 - at] or a[254]
		end
		b[0] = a[254]
		size = 512
		source = b
		b[510], b[511] = a[254], a[254]
	end
	local scale = spec.scale
	local out = state.out
	if scale < 255 then
		size = shrink(source, size, scale, out)
	elseif scale > 255 then
		size = grow(source, size, scale, out)
	else
		for at = 0, size - 1 do
			out[at] = source[at]
		end
	end
	if spec.add and spec.add ~= 0 then
		for at = 0, size - 1 do
			if out[at] ~= 0 then
				out[at] = math.min(255, out[at] + spec.add)
			end
		end
	end
	local box = spec.box or 0
	if box > 0 then
		for at = 0, size - 1 do
			local sum = out[at]
			for k = 0, box do
				local index = at + k
				if index >= size then
					index = at
				end
				sum = sum + out[index]
			end
			if at ~= 0 and sum == 0 then
				out[at] = math.floor(out[at - 1] * 0.05)
			else
				out[at] = math.floor(sum / (box + 1))
			end
		end
	end
	local keep = state.keep or spec.keep or 0
	if keep ~= 0 then
		local old, new = keep * 0.01, (100 - keep) * 0.01
		local last = state.last
		for at = 0, size do
			local value = math.floor((last[at] or 0) * old + (out[at] or 0) * new)
			out[at] = value
			last[at] = value
		end
	end
	state.size = size
	return true
end

local function upload(state)
	local out, image = state.out, state.image
	local size = math.min(state.size, 350)
	for x = 0, size - 1 do
		local value = math.max(0, math.min(255, out[x] or 0)) / 255.0
		image:set_pixel(x, 0, Color(value, value, value, 1.0))
	end
	state.heights:update(image)
	return size
end

local function prepare(state)
	state.bytes, state.a, state.b, state.out, state.last, state.ring = {}, {}, {}, {}, {}, {}
	for at = 0, 9 do
		state.ring[at] = 0
	end
	state.ring_at, state.hold, state.size, state.level, state.instant, state.roll = 0, 0, 0, 0, 0, 0
	state.image = Image.create(350, 1, false, Image.FORMAT_R8)
	state.heights = ImageTexture.create_from_image(state.image)
end

local function cosine(degrees)
	return math.cos(math.floor(degrees) * RADIANS)
end

local function phases(state)
	state.p1 = state.p1 + (state.v1 or 0)
	if state.p1 > 359 then
		state.p1 = state.p1 - 359
	end
	state.p2 = state.p2 + (state.v2 or 0)
	if state.p2 > 359 then
		state.p2 = state.p2 - 359
	end
end

local function drift(state, trail)
	state.fx = state.fx + trail.x
	state.fy = state.fy + trail.y
	local sx = state.fx >= 0 and math.floor(state.fx) or math.ceil(state.fx)
	local sy = state.fy >= 0 and math.floor(state.fy) or math.ceil(state.fy)
	state.fx, state.fy = state.fx - sx, state.fy - sy
	return Vector2i(sx, sy)
end

local function preset(name, config)
	local entry = {
		name = name,
		size = SIZE,
		filter = "nearest",
		feedback = COLUMNS,
		display = SHOW,
		params = {
			solid = config.rows == nil and not config.flame,
			sprite = SLOT[config.sprite],
			mode = config.spec.mode or 0,
			bits = config.bits or 0,
			reach = config.reach or 0,
			amount = config.amount or 0.0,
			trail = config.trail ~= nil,
			smear = config.trail ~= nil and config.trail.smear == true,
			frost = config.frost == true,
			frost_color = config.frost_color or Color(1.0, 1.0, 1.0, 1.0),
			quarter = config.quarter == true,
			rise = config.rise or 0,
			overlay = config.overlay ~= nil,
			lift = config.overlay or 0,
		},
	}
	entry.params.tint = config.tint
	entry.setup = function(state, scene)
		scene.viewport.transparent_bg = true
		prepare(state)
		state.p1, state.p2, state.v1, state.v2 = config.p1 or 0, config.p2 or 0, config.v1 or 0, config.v2 or 0
		state.fx, state.fy = 0, 0
		state.scroll, state.frames, state.hue, state.turn = 0, 0, 0, 1
		state.axes = config.axes and { config.axes[1], config.axes[2], config.axes[3] } or nil
		state.alternate = config.sprite
		if config.init then
			config.init(state)
		end
		scene.engine.set(scene, "heights", state.heights)
		scene.engine.set(scene, "sprites", atlas())
		if config.rows or config.flame then
			local plane
			local many = MultiMesh.new()
			many.transform_format = MultiMesh.TRANSFORM_2D
			if config.flame then
				plane = PlaneMesh.new()
				plane.orientation = PlaneMesh.FACE_Z
				plane.size = Vector2(1.0, 1.0)
				plane.subdivide_depth = 96
				many.mesh = plane
				many.instance_count = 350
			else
				plane = QuadMesh.new()
				plane.size = Vector2(1.0, 1.0)
				many.mesh = plane
				many.instance_count = 350 * config.rows
			end
			state.many = many
			local material = ShaderMaterial.new()
			if config.flame then
				flame_shader = flame_shader or nari.load("shaders/musical_colors/flame.gdshader")
				material.shader = flame_shader
			else
				dots_shader = dots_shader or nari.load("shaders/musical_colors/dots.gdshader")
				material.shader = dots_shader
				material:set_shader_parameter("rows", config.rows)
				material:set_shader_parameter("mode", config.spec.mode)
				material:set_shader_parameter("bits", config.bits)
				material:set_shader_parameter("reach", config.reach)
				material:set_shader_parameter("amount", config.amount)
			end
			material:set_shader_parameter("heights", state.heights)
			material:set_shader_parameter("sprites", atlas())
			material:set_shader_parameter("sprite", SLOT[config.sprite])
			scene.canvas.material = material
			state.material = material
		end
	end
	if config.rows or config.flame then
		entry.draw = function(canvas, state)
			canvas:draw_multimesh(state.many, nil)
		end
	end
	entry.step = function(state, audio, scene)
		local set = scene.engine.set
		if config.script then
			config.script(state, scene)
		end
		if spectrum(state, audio, config.spec) then
			local size = upload(state)
			set(scene, "count", size)
			if state.material then
				state.material:set_shader_parameter("count", size)
			end
		end
		state.frames = state.frames + 1
		phases(state)
		state.roll = (state.roll + 8) % 256
		if config.flip then
			state.alternate = state.alternate == config.sprite and config.flip or config.sprite
			set(scene, "sprite", SLOT[state.alternate])
		end
		set(scene, "roll", state.roll)
		if config.bounce then
			state.hue = state.hue + state.turn
			if state.hue < -270 then
				state.hue = -270
				state.turn = -state.turn
			end
			if state.hue > 270 then
				state.hue = 270
				state.turn = -state.turn
			end
			if state.hue == 90 and state.turn > 0 then
				state.hue = 91
			end
			if state.hue == -90 and state.turn < 0 then
				state.hue = -91
			end
			set(scene, "hue", state.hue)
		end
		if config.trail then
			set(scene, "fade", (state.fade or config.trail.fade) / 255.0)
			set(scene, "shift", drift(state, config.trail))
		end
		if config.warp then
			config.warp(state, set, scene)
		end
		if state.material then
			if config.scroll then
				state.scroll = (state.scroll + config.scroll) % 256
				state.material:set_shader_parameter("scroll", math.floor(state.scroll))
			end
			if config.motion then
				config.motion(state, state.material)
			end
		end
	end
	return entry
end

local function vec3(x, y, z)
	return Color(x, y, z, 1.0)
end

local function scattered(state)
	state.p1 = math.random(0, 255)
	state.p2 = math.random(0, 255)
end

local function ambient(state)
	if state.level < 160 then
		state.keep = math.floor((256 - state.level) * 80 / 256)
	else
		state.keep = 0
	end
end

local presets = {
	preset("Night Lights", {
		sprite = 21,
		spec = { add = 30, box = 9, mode = 1, scale = 175 },
		bits = 1, reach = 162, amount = 256.0,
	}),
	preset("Colors in Motion", {
		sprite = 30, rows = 5, bits = 2, reach = 4, amount = 200.0,
		spec = { add = 20, box = 3, mode = 4, scale = 174, keep = 95 },
		trail = { fade = 5, x = 0.5, y = 1.0 },
		init = scattered, v1 = 0.5, v2 = 1.0,
		motion = function(state, material)
			if state.frames % 300 == 0 then
				local bits = math.random(0, 7)
				state.ax, state.ay = bits % 2, math.floor(bits / 2) % 2
				state.az = (bits >= 4 or (state.ax == 0 and state.ay == 0)) and 1 or 0
			end
			local turn = math.floor(state.p1)
			local swing = cosine(state.p1)
			material:set_shader_parameter("center", Vector2(175.0 + math.floor(45 * swing), 160.0 + math.floor(112 * swing)))
			material:set_shader_parameter("angle", vec3(turn, turn, turn))
			material:set_shader_parameter("axes", vec3(state.ax or 0, state.ay or 1, state.az or 1))
			material:set_shader_parameter("twist", -0.008 * cosine(state.p2))
		end,
	}),
	preset("Aurora", {
		sprite = 17, rise = 50, script = ambient,
		spec = { add = 87, box = 37, mode = 0, scale = 376, keep = 60 },
		bits = 3, reach = 83, amount = 256.0,
	}),
	preset("Rhythmic Colors", {
		sprite = 35, rows = 9, bits = 3, reach = 5, amount = 180.0, scroll = 6,
		spec = { add = 20, box = 3, mode = 5, scale = 174, keep = 95 },
		trail = { fade = 5, x = 0.5, y = 1.0 },
		v1 = 1.0,
		script = function(state)
			state.fade = 15 - math.floor(-10.0 * cosine(state.p1))
			state.v2 = math.floor(state.level / 100)
		end,
		motion = function(state, material)
			local turn = math.floor(state.p1)
			local swing = cosine(state.p1)
			material:set_shader_parameter("center", Vector2(175.0 + math.floor(160 * swing), 160.0 + math.floor(-60 * swing)))
			material:set_shader_parameter("angle", vec3(turn, 0, 0))
			material:set_shader_parameter("axes", vec3(1, 0, 0))
			material:set_shader_parameter("twist", -0.014 * cosine(state.p2))
		end,
	}),
	false,
	preset("Electric Green", {
		sprite = 20, rise = 40, script = ambient,
		spec = { add = 87, box = 37, mode = 0, scale = 376, keep = 10 },
		bits = 3, reach = 38, amount = 256.0,
	}),
	preset("Soft Fire", {
		sprite = 6, tint = vec3(1.0, 1.0 / 255.0, 65.0 / 255.0),
		spec = { add = 50, box = 5, mode = 0, scale = 350, keep = 67, random = 2 },
		bits = 1, reach = 116, amount = 250.0,
	}),
	preset("Silky Wave", {
		sprite = 9,
		spec = { add = 70, box = 40, mode = 0, scale = 350 },
		trail = { fade = 19, x = 1.0, y = 0.5 },
	}),
	preset("CutOut", {
		sprite = 4, bounce = true,
		spec = { box = 8, mode = 4, scale = 174, keep = 31 },
		bits = 3, reach = 35, amount = 130.0,
	}),
	preset("Rolling Fire", {
		sprite = 15, overlay = -30,
		spec = { box = 2, mode = 1, scale = 162 },
		trail = { fade = 10, x = 0.0, y = -4.67 },
		v1 = 4.75,
		warp = function(state, set, scene)
			local value = cosine(state.p1)
			set(scene, "warped", true)
			set(scene, "center", Vector2(175.0, 160.0 + math.floor(82 * value)))
			set(scene, "angle", vec3(33, 0, 0))
			set(scene, "axes", vec3(1, 0, 0))
		end,
	}),
	preset("Water Spray", {
		sprite = 14, flip = 13,
		spec = { box = 2, mode = 0, scale = 356 },
		trail = { fade = 10, x = 0.0, y = -4.67 },
	}),
	preset("Acid Rock", {
		sprite = 12,
		spec = { mode = 0, scale = 356 },
		trail = { fade = 30, x = 1.0, y = 0.5 },
		v1 = 5.0, v2 = 3.0,
		warp = function(state, set, scene)
			local turn = math.floor(state.p2)
			set(scene, "warped", true)
			set(scene, "center", Vector2(175.0, 160.0 + math.floor(-75 * cosine(state.p1))))
			set(scene, "angle", vec3(0, turn, turn))
			set(scene, "axes", vec3(0, 1, 1))
		end,
	}),
	preset("Hard Rock", {
		sprite = 24, flip = 25,
		spec = { add = 50, box = 2, mode = 3, scale = 174, keep = 40 },
		bits = 11, reach = 12, amount = 250.0,
	}),
	preset("Hot Spray", {
		sprite = 22, flip = 23,
		spec = { box = 2, mode = 0, scale = 356 },
		bits = 1, reach = 16, amount = 256.0,
		trail = { fade = 10, x = 0.0, y = -8.0 },
	}),
	preset("Yellow Swirl", {
		sprite = 6,
		spec = { box = 3, mode = 0, scale = 340, keep = 50 },
		trail = { fade = 30, x = 1.0, y = 0.5 },
		v1 = 5.0,
		warp = function(state, set, scene)
			set(scene, "warped", true)
			set(scene, "center", Vector2(175.0, 160.0 + math.floor(-75 * cosine(state.p1))))
			set(scene, "angle", vec3(0, 0, 5))
			set(scene, "axes", vec3(0, 0, 1))
		end,
	}),
	preset("Blue Flame", {
		sprite = 30, flame = true, rise = 56,
		spec = { box = 3, mode = 1, scale = 174 },
		trail = { fade = 22, x = 1.0, y = 1.0, smear = true },
	}),
	preset("Critter Rock", {
		sprite = 35, rows = 5, bits = 2, reach = 4, amount = 200.0,
		spec = { add = 20, box = 3, mode = 4, scale = 174, keep = 50 },
		trail = { fade = 2, x = 0.0, y = -1.0 },
		v1 = 1.0,
		warp = function(state, set, scene)
			set(scene, "warped", true)
			set(scene, "angle", vec3(0, math.floor(state.p1), 0))
			set(scene, "axes", vec3(0, 1, 0))
			set(scene, "twist", -0.002 * cosine(state.p1))
		end,
	}),
	preset("Electric Rainbow", {
		sprite = 30,
		spec = { box = 8, mode = 4, scale = 174, keep = 31 },
		bits = 3, reach = 31, amount = 178.0,
		trail = { fade = 2, x = 1.0, y = 0.5 },
	}),
	preset("Neon Highway", {
		sprite = 42, rows = 9, bits = 3, reach = 5, amount = 180.0, scroll = 6,
		spec = { add = 15, box = 3, mode = 5, scale = 174, keep = 10 },
		trail = { fade = 5, x = 0.5, y = 1.0 },
		script = function(state)
			state.fade = 15 - math.floor(-10.0 * cosine(state.p1))
			state.v1 = math.floor(state.level / 10)
		end,
		motion = function(state, material)
			material:set_shader_parameter("swing", 3.0)
			material:set_shader_parameter("phase", math.floor(state.p1))
			material:set_shader_parameter("wave", math.min(state.level + 14, 150))
		end,
	}),
	preset("Ice Crystals", {
		sprite = 4, frost = true, rise = -3,
		spec = { add = 20, hold = 1, mode = 0, scale = 255 },
		trail = { fade = 2, x = 1.0, y = 0.5 },
	}),
	preset("Stalactite", {
		sprite = 28, flip = 29,
		spec = { box = 3, hold = 28, mode = 3, scale = 174 },
		bits = 2, reach = 13, amount = 75.0,
		trail = { fade = 7, x = 0.0, y = -2.5 },
	}),
	preset("Rolling Colors", {
		sprite = 7,
		spec = { box = 10, mode = 0, scale = 300 },
		trail = { fade = 4, x = 1.0, y = 0.5 },
		v1 = 2.0,
		script = function(state, scene)
			scene.engine.set(scene, "solid", state.level >= 5)
		end,
		warp = function(state, set, scene)
			set(scene, "warped", true)
			set(scene, "center", Vector2(175.0, 160.0 + math.floor(186 * cosine(state.p1))))
			set(scene, "angle", vec3(10, 0, 0))
			set(scene, "axes", vec3(1, 0, 0))
		end,
	}),
	preset("Wild Rock", {
		sprite = 18, flip = 19,
		spec = { add = 87, box = 12, mode = 0, scale = 356 },
		trail = { fade = 10, x = 0.0, y = -4.67 },
	}),
	preset("Red Rock", {
		sprite = 18, flip = 19,
		spec = { add = 80, box = 3, mode = 3, scale = 174 },
		bits = 2, reach = 12, amount = 250.0,
	}),
	preset("Color Cave", {
		sprite = 30,
		spec = { add = 30, mode = 4, scale = 174, keep = 85 },
		trail = { fade = 2, x = 1.0, y = 0.5 },
	}),
	preset("WinMe 3D", {
		sprite = 8, frost = true, frost_color = Color(0.376, 0.376, 1.0, 1.0), rise = -3,
		spec = { add = 50, mode = 0, scale = 255, keep = 85 },
		trail = { fade = 2, x = 1.0, y = 0.5 },
	}),
	preset("Lighting", {
		sprite = 34, quarter = true,
		spec = { add = 150, box = 120, mode = 0, scale = 376, random = 2 },
		bits = 3, reach = 15, amount = 170.0,
	}),
	preset("Colors in Motion in Progress", {
		sprite = 35, rows = 9, bits = 3, reach = 5, amount = 180.0, scroll = 6,
		spec = { add = 20, box = 3, mode = 5, scale = 174, keep = 95 },
		trail = { fade = 5, x = 0.5, y = 1.0 },
		v1 = 1.0,
		script = function(state)
			state.fade = 15 - math.floor(-10.0 * cosine(state.p1))
			state.v2 = math.floor(state.level / 100)
		end,
		motion = function(state, material)
			local turn = math.floor(state.p1)
			local swing = cosine(state.p1)
			material:set_shader_parameter("center", Vector2(175.0 + math.floor(160 * swing), 160.0 + math.floor(-60 * swing)))
			material:set_shader_parameter("angle", vec3(turn, 0, 0))
			material:set_shader_parameter("axes", vec3(1, 0, 0))
			material:set_shader_parameter("twist", -0.014 * cosine(state.p2))
		end,
	}),
}

presets[5] = {
	name = "Star Power",
	size = SIZE,
	filter = "nearest",
	layers = { STAR },
	setup = function(state, scene)
		prepare(state)
		state.table = Image.create(255, 1, false, Image.FORMAT_RGBA8)
		state.lut = ImageTexture.create_from_image(state.table)
		state.phase, state.since, state.pick = 0, 0, 0
		local palette = nari.load("assets/musical_colors/palette.png"):get_image()
		local backdrop = nari.load("assets/musical_colors/backdrop.png"):get_image()
		state.palette, state.backdrop = {}, {}
		for index = 0, 1023 do
			state.palette[index] = palette:get_pixel(0, index)
		end
		for index = 0, 254 do
			state.backdrop[index] = backdrop:get_pixel(0, index)
		end
		scene.engine.set(scene, "star", nari.load("assets/musical_colors/star.png"))
		scene.engine.set(scene, "table", state.lut)
	end,
	step = function(state, audio, scene)
		state.keep = nil
		spectrum(state, audio, { add = 85, box = 40, mode = 0, scale = 255, keep = 37 })
		local out = state.out
		local divide = math.max(1, state.level - math.floor(state.level * 0.95))
		state.phase = state.phase + 10
		if state.phase > 255 then
			state.phase = 0
		end
		for index = 0, 254 do
			local h = out[index] or 0
			local at = h + state.phase
			if at >= 1024 then
				at = at - 1024
			end
			local color = state.palette[at]
			state.table:set_pixel(index, 0, Color(color.r, color.g, color.b, math.min(255, math.floor((255 - h) / divide)) / 255.0))
		end
		state.lut:update(state.table)
		local high, low = math.floor(state.level * 1.3), math.floor(state.level * 0.7)
		if state.since > 45 and (state.instant > high or state.instant < low) then
			state.pick = math.random(0, 254)
			state.since = 0
		end
		state.since = state.since + 1
		local back = state.instant < 3 and Color(0.0, 0.0, 0.0, 1.0) or state.backdrop[state.pick]
		scene.engine.set(scene, "backdrop", back)
	end,
}

return {
	name = "Musical Colors",
	presets = presets,
}

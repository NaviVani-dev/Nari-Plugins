local lib = require("lib")
local bins = require("packs.wmp_bins")

local WARP = "shaders/pixeltrip/warp.gdshader"
local DOTS = "shaders/pixeltrip/dots.gdshader"
local FRAMES = 30
local CAPACITY = 4096
local BEAT_LEVEL = 0.78
local BEAT_DIVISOR = 194
local PI = math.pi
local random = math.random

local dots_shader

local function span(low, high)
	return low + random() * (high - low)
end

local function roll(range, base)
	return random() < 1 / (math.floor(random() * range) + base)
end

local function on(value)
	return value and 1.0 or 0.0
end

local function sign(value, range, base)
	return roll(range, base) and -value or value
end

local function pick_bag(items)
	local bag = { items = { table.unpack(items) }, left = #items }
	function bag.next()
		local list, count = bag.items, #bag.items
		local index = bag.left > 0 and random(1, bag.left) or 1
		if index >= count then
			index = count - 1
		end
		local item = table.remove(list, index)
		list[count] = item
		bag.left = bag.left - 1
		if bag.left < 0 then
			bag.left = count
		end
		return item
	end
	for _ = 1, #items do
		bag.next()
	end
	return bag
end

local function amount_flags(value)
	return sign(value, 3, 1), on(not roll(4, 2)), on(not roll(3, 2))
end

local function halved(value, active)
	return active > 0.5 and value or value * 0.5
end

local WARPS = {
	function()
		local v, one, two = amount_flags(span(0.025, 0.1))
		return 0, { v, two, one, 1.0 / span(1.0, 2.5), span(0.025, 0.1), span(4.0, 12.0), span(0.025, 0.1) }
	end,
	function(strong)
		return 1, { strong and span(0.25, 1.0) or span(0.05, 0.15), math.floor(random() * 10) }
	end,
	function()
		local v, one, two = amount_flags(span(0.00625, 0.025))
		return 2, { v, two, one, on(roll(5, 2)), span(0.075, 0.3), random() < 0.5 and -1.0 or 1.0, math.floor(random() * 16) + 4, span(0.0125, 0.025), on(roll(2, 2)), span(4.0, 12.0), span(0.025, 0.1) }
	end,
	function()
		local v, one, two = amount_flags(span(0.05, 0.25))
		return 3, { v, two, one, span(0.1, 0.55) * (random() < 0.5 and -1.0 or 1.0), on(random() < 0.5), on(random() < 0.5), span(4.0, 12.0), span(0.025, 0.1) }
	end,
	function()
		return 4, { math.floor(random() * 3) }
	end,
	function(strong)
		local v, one, two = amount_flags(span(0.025, 0.1))
		return 5, { v, two, one, span(0.05, 0.25) * (strong and 1.0 or -1.0), on(roll(2, 2)), span(4.0, 12.0), span(0.0125, 0.05) }
	end,
	function()
		local form = math.floor(random() * 15)
		local spin = roll(3, 2) and sign(span(0.005, 0.045), 3, 1) or 0.0
		local pull = 0.0
		if roll(3, 2) then
			pull = span(0.00625, 0.125)
			if roll(5, 3) then
				pull = -pull * 0.5
			end
		end
		return 6, { pull, on(not roll(3, 2)), spin, on(not roll(4, 2)), math.floor(form / 4), form % 4, math.floor(random() * 10) + 2, sign(span(0.01, 0.06), 3, 1), math.floor(random() * 10) + 2, sign(span(0.01, 0.06), 3, 1) }
	end,
	function()
		local two, one = on(not roll(3, 2)), on(not roll(4, 2))
		return 7, { sign(halved(span(0.0125, 0.06), two), 3, 1), two, one, span(0.1, 1.0), span(0.06, 0.56) }
	end,
	function()
		local two, one = on(not roll(3, 2)), on(not roll(4, 2))
		return 8, { sign(halved(span(0.0125, 0.06), two), 3, 1), two, one, math.floor(random() * 2), span(0.25, 0.75), span(0.06, 0.56), on(random() < 0.5), on(random() < 0.5), span(4.0, 12.0), span(0.025, 0.1) }
	end,
	function()
		local two, one = on(not roll(3, 2)), on(not roll(4, 2))
		return 9, { sign(halved(span(0.0125, 0.06), two), 3, 1), two, one, span(0.05, 1.55) * PI, span(0.01, 0.2) }
	end,
	function()
		local pull = span(0.0125, 0.034)
		local v = roll(3, 2) and sign(span(0.0125, 0.05), 3, 1) or 0.0
		return 10, { (math.floor(random() * 18) + 2) * PI, pull * 0.5 + 0.003125, pull, v, on(not roll(3, 2)), on(not roll(4, 2)), on(roll(2, 2)), span(4.0, 12.0), span(0.0125, 0.05) }
	end,
	function()
		return 11, { span(0.025, 0.15), math.floor(random() * 20) + 18, span(0.1, 0.5) * (random() < 0.5 and -1.0 or 1.0), on(not roll(5, 2)), span(4.0, 16.0), span(0.0125, 0.05) }
	end,
}

local WARP_LIST = {
	{ 6, 11 }, { 11 }, { 6 }, { 9 }, { 6 }, { 3 }, { 6, 10 }, { 11 }, { 6 }, { 0 }, { 6 }, { 10 }, { 6 }, { 2 }, { 11 },
	{ 5, strong = true }, { 5 }, { 4, 11 }, { 8 }, { 1 }, { 1, strong = true }, { 7 }, { 4 },
}

local function blank(values)
	while #values < 12 do
		values[#values + 1] = 0.0
	end
	return values
end

local function new_path(kind, mode, ax, ay, speed, f1, f2, rose, jump)
	return { kind = kind, mode = mode, ax = ax, ay = ay, reach = math.max(ax, ay), arm = math.max(ax, ay) * 0.75, speed = speed, f1 = f1, f2 = f2, rose = rose, jump = jump, phase = span(0.01, 0.0265), x = 0.0, y = 0.0, turn = random() * PI * 2.0, grow = 1.0, spiral = 1.0, pace = 1.0 }
end

local function move_path(path, bounce, seconds)
	if bounce and path.jump > 0.0 then
		path.phase = path.phase + path.jump * path.speed
	else
		local speed = path.speed
		if path.mode ~= 0 then
			local low = speed * 0.25
			local far = math.sqrt(path.x * path.x + path.y * path.y)
			if path.mode == 1 then
				far = path.reach - far
			end
			local v = far / path.reach * (speed - low) + low
			speed = v > 0.0 and v or speed
		end
		path.phase = path.phase + speed
	end
	local p, kind = path.phase, path.kind
	if kind == 1 then
		path.x, path.y = math.cos(path.f1 * p) * path.ax, math.sin(path.f2 * p) * path.ay
	elseif kind == 3 then
		local arm = math.cos(path.rose * p) * path.arm
		path.x, path.y = math.cos(p) * arm, math.sin(p) * arm
	elseif kind == 5 then
		local arm, s = math.cos(p) * path.arm, math.sin(path.turn)
		path.x, path.y = math.cos(s * p) * arm, math.sin(s * p) * arm
	elseif kind == 4 then
		local arm = math.cos(p) * path.arm
		path.x, path.y = math.sin(math.cos(path.turn) * p) * arm, math.sin(math.sin(path.turn) * p) * arm
	elseif kind == 2 then
		local far = math.sqrt(path.x * path.x + path.y * path.y)
		if far < path.pace then
			path.grow, path.spiral = 1.0, 1.0
		elseif far > path.reach then
			path.grow, path.spiral = -1.0, path.reach
		end
		path.spiral = path.spiral + path.grow * path.pace
		path.x, path.y = math.cos(p) * path.spiral, math.sin(p) * path.spiral
	elseif kind == 6 then
		local w = (p + seconds) * PI
		path.x, path.y = math.cos(w) * path.ax + math.cos(seconds) * path.ax, math.sin(w) * path.ax + math.sin(seconds) * path.ax
	end
end

local function roaming_path(width, height)
	local kind = math.floor(random() * 6) + 1
	local ax, ay = width * 0.25 + random() * 0.75 * width, height * 0.25 + random() * 0.75 * height
	local path = new_path(kind, math.floor(random() * 3), ax * 0.5, ay * 0.5, span(0.015, 0.1), span(0.5, 1.5), span(0.5, 0.975), 2, 0.0)
	path.x, path.y = random() * ax - ax * 0.5, random() * ay - ay * 0.5
	path.pace = span(0.25, 1.5)
	if kind == 3 then
		path.speed, path.rose = span(0.01, 0.05), math.floor(random() * 6) + 2
	end
	path.phase = span(0.01, 0.015)
	return path
end

local function new_rotor(rate, lissajous, wobble)
	local rotor = { angle = 0.0, step = PI / 180.0 * (random() < 0.5 and 1.0 or -1.0), rate = rate, sway = 0.0, sway_rate = 0.0, cos_rate = 1.0, sin_rate = 1.0, wobble = wobble and 1.0 or 0.0 }
	if lissajous then
		rotor.cos_rate = math.floor(random() * 17) - 8
		rotor.sin_rate = math.floor(random() * 17) - 8
		if math.abs(rotor.cos_rate) == math.abs(rotor.sin_rate) then
			rotor.cos_rate = rotor.cos_rate + 1.0
		end
		if rotor.sin_rate == 0.0 then
			rotor.sin_rate = 1.0
		end
		if rotor.cos_rate == 0.0 then
			rotor.cos_rate = 1.0
		end
	end
	if not roll(5, 2) then
		rotor.sway, rotor.sway_rate = rate * 0.5, span(1.0, 3.14)
	end
	return rotor
end

local function turn_rotor(rotor, seconds)
	local value = rotor.angle + (math.sin(rotor.sway_rate * seconds) * rotor.sway + rotor.rate) * rotor.step
	if value < 0.0 then
		value, rotor.step = 0.0, -rotor.step
	elseif value > PI * 2.0 then
		value, rotor.step = PI * 2.0, -rotor.step
	end
	rotor.angle = value
	rotor.c, rotor.s = math.cos(rotor.cos_rate * value), math.sin(rotor.sin_rate * value)
	rotor.wc = math.cos(value) * value
end

local function apply_rotor(rotor, x, y)
	local a, b = x * rotor.c - y * rotor.s, x * rotor.s + y * rotor.c
	if rotor.wobble > 0.5 then
		return math.cos(rotor.wc) * a, math.sin(rotor.wc) * b
	end
	return a, b
end

local PALETTE = {
	0xe64000, 0xe66000, 0xdf4000, 0xdf8000, 0xe6df00, 0xe6af00, 0xe6a000, 0x0000df, 0xe64000, 0x00df00, 0xdf0000, 0xdfdf00, 0xe66000, 0xdf00df, 0x00dfdf,
	0x80df00, 0xdf4000, 0x0080df, 0xdf0080, 0x00df80, 0xdf8000, 0x80dfdf, 0xdfdf80, 0xdf80df, 0xe6df00, 0xdf4080, 0xdf4080, 0xdf8000, 0xe6af00, 0xdf8040, 0xdf8080,
	0x80df80, 0xe6a000, 0xe67200, 0xe60072, 0x72e600, 0xdf2000, 0x00e672, 0x7200e6, 0x0072e6, 0xe64000, 0xe66000, 0xdf4000, 0xdf8000, 0xe6df00, 0xe6af00, 0xe6a000,
}

local function new_tint(mode, count)
	local tint = { mode = mode, time = 0.0, count = count, r = 0.0, g = 0.0, b = 0.0 }
	if mode == 1 then
		tint.wander = not roll(5, 3)
		tint.rate = span(1.0, 3.14)
		tint.reach = math.floor(count * 0.5 * span(0.0, 1.0))
	elseif mode == 0 then
		tint.base = { 0.5, 1.0, 1.0 }
		tint.amp = { 0.5, 0.0, 0.0 }
		tint.rates = { span(0.75, 2.0), 0.0, 0.0 }
	else
		local r, g, b
		if roll(4, 1) then
			local color = lib.hsv(random() * 0.9999, span(0.8, 1.0), span(0.8, 1.0))
			r, g, b = color.r, color.g, color.b
		else
			local value = PALETTE[random(1, #PALETTE)]
			r, g, b = math.floor(value / 65536) / 255.0, math.floor(value / 256) % 256 / 255.0, value % 256 / 255.0
		end
		tint.base = { r, g, b }
		tint.amp = { math.min(r, 1.0 - r) * 0.5, math.min(g, 1.0 - g) * 0.5, math.min(b, 1.0 - b) * 0.5 }
		tint.rates = { span(1.0, 3.14), span(1.0, 3.14), span(1.0, 3.14) }
	end
	return tint
end

local function step_tint(tint, seconds)
	tint.time = seconds
	if tint.mode == 1 then
		tint.start = tint.wander and math.floor(math.sin(seconds * tint.rate) * tint.reach) or 0
		return
	end
	local function wave(index)
		return math.max(0.0, math.min(1.0, math.sin(seconds * tint.rates[index]) * tint.amp[index] + tint.base[index]))
	end
	if tint.mode == 0 then
		local color = lib.hsv(wave(1), wave(2), wave(3))
		tint.r, tint.g, tint.b = color.r, color.g, color.b
	else
		tint.r, tint.g, tint.b = wave(1), wave(2), wave(3)
	end
end

local function hue_at(tint, index)
	local n = math.max(1, tint.count)
	return lib.hsv(((tint.start or 0) + index) % n / n, 1.0, 1.0)
end

local function motion(arg, width, height)
	if arg == 1 then
		return roaming_path(width, height)
	end
	return new_path(0, 0, 0.0, 0.0, 0.0, 1.0, 1.0, 2, 0.0)
end

local function base_slot(arg, width, height)
	local diag = math.sqrt(width * width + height * height)
	local path = motion(arg, width, height)
	return { arg = arg, width = width, height = height, diag = diag, path = path, seconds = 0.0, life = span(12.0, 36.0) * FRAMES, age = 0, add = false }
end

local function lattice(arg, width, height, plain)
	local slot = base_slot(arg, width, height)
	local d = slot.diag
	local edge, per
	if arg == 1 then
		edge = random() * d * 0.05 + d * 0.07
		per = edge * 0.1
	elseif roll(3, 2) then
		arg = 1
		edge = random() * d * 0.2 + d * 0.12
		per = edge * 0.05
	else
		edge = random() * d * 0.2 + d * 0.2
		per = edge * 0.05
	end
	per = math.max(2, math.min(16, math.floor(per)))
	slot.shape, slot.count, slot.size = 0, { per, per, per }, { edge, edge, edge }
	slot.total = per * per * per
	slot.tint = new_tint(math.floor(random() * 3), slot.total)
	slot.add = roll(4, 1)
	slot.invert = roll(3, 1)
	local liss = not plain
	slot.rotor = new_rotor(plain and span(0.25, 2.5) or span(0.2, 0.75), liss, not roll(4, 3))
	return slot
end

local function grid(arg, width, height, plain)
	local slot = base_slot(arg, width, height)
	local d = slot.diag
	local sx, sy
	if arg == 1 then
		sx = random() * d * 0.1 + d * 0.15
		sy = sx
	else
		sx, sy = width, height
	end
	local nx, ny = math.max(2, math.floor(sx * 0.05)), math.max(2, math.floor(sy * 0.05))
	slot.shape, slot.count, slot.size = 2, { nx, ny, 1 }, { sx, sy, 0.0 }
	slot.total = nx * ny
	slot.tint = new_tint(math.floor(random() * 3), slot.total)
	slot.add = roll(4, 1)
	slot.invert = roll(3, 1)
	slot.rotor = new_rotor(plain and span(0.25, 2.5) or span(0.2, 0.75), not plain, not plain and not roll(4, 3))
	return slot
end

local function sphere(arg, width, height, flags)
	local slot = base_slot(arg, width, height)
	local big = slot.diag / span(2.0, 3.0)
	if arg == 1 then
		slot.radius = random() * big * 0.08 + big * 0.12
	elseif roll(3, 2) then
		slot.radius = random() * big * 0.2 + big * 0.12
	else
		slot.radius = big
		slot.pulse, slot.pulse_rate = span(0.2, 0.3) * big, span(0.25, 3.14)
		if roll(3, 1) then
			slot.pulse = nil
		end
	end
	local lat = roll(3, 2) and math.floor(random() * 18) + 14 or math.floor(random() * 10) + 8
	local long = math.floor(random() * 10) + 22
	slot.shape, slot.steps = 1, { PI / lat, PI * 2.0 / long }
	slot.count = { long + 1, lat + 1, 1 }
	slot.total = (long + 1) * (lat + 1)
	slot.wire = flags.wire
	slot.flat = flags.flat
	slot.half = flags.half
	slot.half_invert = flags.half and not roll(4, 1)
	slot.tint = new_tint(math.floor(random() * 3), slot.total)
	slot.add = roll(8, 1)
	slot.invert = roll(3, 1)
	slot.rotor = new_rotor(arg == 1 and span(0.2, 0.75) or span(0.5, 1.75), not roll(3, 1), not roll(4, 3))
	return slot
end

local function scope(arg, width, height, flags)
	local slot = base_slot(arg, width, height)
	local d = slot.diag
	slot.wave_kind = "line"
	slot.cross, slot.taper = flags.cross, flags.taper
	slot.lines = random() < 0.5
	slot.size = arg == 1 and random() * d * 0.1 + d * 0.2 or random() * d * 0.2 + d * 0.6
	slot.pulse, slot.pulse_rate = span(0.2, 0.4) * slot.size, span(1.0, 3.14)
	if roll(3, 1) then
		slot.pulse = nil
	end
	slot.add = roll(3, 1)
	slot.tint = new_tint(math.floor(random() * 3), 256)
	slot.rotor = new_rotor(arg == 1 and span(0.25, 0.9) or span(0.25, 2.5), not roll(3, 2), not roll(4, 3))
	return slot
end

local function polar(arg, width, height, flags)
	local slot = base_slot(arg, width, height)
	local reach = slot.diag / span(3.0, 4.0)
	slot.wave_kind = "ring"
	slot.size = arg == 1 and reach * span(0.2, 0.4) or reach
	if not roll(3, 1) then
		slot.pulse, slot.pulse_rate = span(0.2, 0.4) * slot.size, span(0.25, 3.14)
	end
	slot.lines = random() < 0.5
	slot.half = flags.half
	slot.half_invert = flags.half and not roll(4, 1)
	slot.add = roll(4, 1)
	slot.tint = new_tint(math.floor(random() * 3), 256)
	slot.rotor = new_rotor(arg == 1 and span(0.25, 0.9) or span(0.25, 1.5), not roll(3, 2), not roll(4, 3))
	return slot
end

local function full(arg, width, height)
	local slot = base_slot(0, width, height)
	slot.wave_kind = "full"
	slot.tint = new_tint(random() < 0.5 and 0 or 2, 256)
	slot.double = roll(4, 3)
	slot.lines = random() < 0.33
	slot.vertical = random() < 0.5
	slot.add = roll(3, 2)
	return slot
end

local KINDS = {
	lattice = function(arg, w, h) return lattice(arg, w, h, false) end,
	lattice_plain = function(arg, w, h) return lattice(arg, w, h, true) end,
	grid = function(arg, w, h) return grid(arg, w, h, false) end,
	grid_plain = function(arg, w, h) return grid(arg, w, h, true) end,
	scope = function(arg, w, h) return scope(arg, w, h, {}) end,
	scope_cross = function(arg, w, h) return scope(arg, w, h, { cross = true }) end,
	scope_taper = function(arg, w, h) return scope(arg, w, h, { taper = true }) end,
	scope_both = function(arg, w, h) return scope(arg, w, h, { cross = true, taper = true }) end,
	ring = function(arg, w, h) return polar(arg, w, h, {}) end,
	ring_half = function(arg, w, h) return polar(arg, w, h, { half = true }) end,
	ball = function(arg, w, h) return sphere(arg, w, h, {}) end,
	ball_flat = function(arg, w, h) return sphere(arg, w, h, { flat = true }) end,
	ball_half = function(arg, w, h) return sphere(arg, w, h, { half = true }) end,
	ball_half_flat = function(arg, w, h) return sphere(arg, w, h, { half = true, flat = true }) end,
	ball_half_wire = function(arg, w, h) return sphere(arg, w, h, { half = true, wire = true }) end,
	ball_half_flat_wire = function(arg, w, h) return sphere(arg, w, h, { half = true, flat = true, wire = true }) end,
	ball_wire = function(arg, w, h) return sphere(arg, w, h, { wire = true }) end,
	ball_flat_wire = function(arg, w, h) return sphere(arg, w, h, { flat = true, wire = true }) end,
	full = full,
}

local BAG_B = { "ring", "scope_cross", "grid", "ring_half", "scope", "ball", "ball_flat", "ball_half", "ball_half_flat", "lattice", "scope_taper", "scope_both", "ball_wire", "ball_flat_wire", "ball_half_flat_wire", "ball_half_wire", "grid_plain", "lattice_plain", "ring", "scope_cross", "grid", "ring_half", "scope", "lattice", "scope_taper", "scope_both", false }
local BAG_A = { "scope", "ball_flat", "scope_cross", "grid", "ball_half_flat_wire", "ball_flat_wire", "ball_half", "lattice", "full", "grid_plain", "lattice_plain", "ring", "ball_half_flat", "scope_taper", "scope_both", "ball_wire", "ball", "ball_half_wire", "ring_half", "ring_half", "scope_taper", "scope_both", "grid_plain", "lattice_plain", "ring", "lattice", "scope", "scope_cross", "grid", false }

local function new_layer(scene, canvas)
	local node = Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	local material = ShaderMaterial.new()
	material.shader = dots_shader
	node.material = material
	canvas:add_child(node)
	local plane = QuadMesh.new()
	plane.size = Vector2(1.0, 1.0)
	local many = MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_2D
	many.mesh = plane
	many.instance_count = CAPACITY
	many.visible_instance_count = 0
	node.draw:connect(function()
		node:draw_multimesh(many, nil)
	end)
	return { node = node, material = material, many = many }
end

local function bind_layer(layer, slot)
	local material = layer.material
	if not slot or not slot.shape then
		layer.many.visible_instance_count = 0
		return
	end
	local total = slot.total
	material:set_shader_parameter("shape", slot.shape)
	material:set_shader_parameter("count_x", slot.count[1])
	material:set_shader_parameter("count_y", slot.count[2])
	material:set_shader_parameter("count_z", slot.count[3])
	if slot.size then
		material:set_shader_parameter("size", Color(slot.size[1], slot.size[2], slot.size[3], 1.0))
	end
	if slot.steps then
		material:set_shader_parameter("steps", Vector2(slot.steps[1], slot.steps[2]))
	end
	material:set_shader_parameter("wire", slot.wire and 1 or 0)
	material:set_shader_parameter("flat_z", slot.flat and 1 or 0)
	material:set_shader_parameter("per_dot", slot.tint.mode == 1 and 1 or 0)
	material:set_shader_parameter("solid", slot.add and 0.0 or 1.0)
	material:set_shader_parameter("half_from", slot.half and total or 1000000)
	layer.many.visible_instance_count = slot.half and math.min(total * 2, CAPACITY) or math.min(total, CAPACITY)
end

local function set_warp(state, scene)
	local entry = WARP_LIST[state.warps.next()]
	local s = span(1.0, 4.0)
	if roll(6, 5) then
		s = span(3.0, 10.0)
	end
	local sx, sy = s / state.basis_w, s / state.basis_h
	if random() < 2 / 3 then
		sx = sy
	end
	local engine = scene.engine
	local kind, values = WARPS[entry[1] + 1](entry.strong)
	engine.set(scene, "first", kind)
	engine.set(scene, "a", blank(values))
	local second = -1
	if entry[2] then
		local other, more = WARPS[entry[2] + 1]()
		second = other
		engine.set(scene, "b", blank(more))
		if random() < 0.5 then
			engine.set(scene, "first", other)
			engine.set(scene, "a", blank(more))
			engine.set(scene, "second", kind)
			engine.set(scene, "b", blank(values))
			second = nil
		end
	end
	if second then
		engine.set(scene, "second", second)
	end
	local half_x, half_y = state.basis_w * 0.5 * sx, state.basis_h * 0.5 * sy
	engine.set(scene, "scale", Vector2(sx, sy))
	engine.set(scene, "reach", math.sqrt(half_x * half_x + half_y * half_y))
	engine.set(scene, "fade", math.floor(random() * 4 + 0.0001))
	state.warp_timer = math.max(state.basis_h, span(14.5, 18.5) * FRAMES)
end

local function new_warp_path(state)
	local w, h = state.basis_w, state.basis_h
	local ax, ay = math.floor(span(0.0175, 0.0425) * w), math.floor(span(0.0175, 0.0425) * h)
	if roll(4, 1) then
		ax = math.min(ax, ay)
		ay = ax
	end
	local kind = math.floor(random() * 5) + 1
	if kind == 2 then
		kind = 3
	end
	local speed = state.bounce and 0.1125 or span(0.0175, 0.1125)
	local jump = state.bounce and 2.0 * math.max(2.0, (ax + ay) * 0.125) or 0.0
	local path = new_path(kind, math.floor(random() * 3), ax, ay, speed, span(0.5, 1.5), span(0.5, 0.975), math.floor(random() * 6) + 2, jump)
	if kind == 3 then
		path.speed = path.speed * 0.8
	end
	state.warp_path = path
end

local function toggle(frames)
	return frames + span(20.0, 38.0) * FRAMES
end

local function new_ring(state)
	local w, h = state.basis_w, state.basis_h
	local ax = w * 0.25 + random() * 0.25 * w
	local ay = h * 0.25 + random() * 0.25 * h
	local path = new_path(math.floor(random() * 6) + 1, math.floor(random() * 3), ax, ay, span(0.0175, 0.125), span(0.5, 1.5), span(0.5, 0.975), 2, 2.0)
	path.pace = span(0.25, 1.5)
	if path.kind == 3 then
		path.speed = span(0.0175, 0.0575)
		path.rose = math.floor(random() * 6) + 2
	end
	return { path = path, seconds = 0.0, life = span(12.0, 36.0) * FRAMES, age = 0, add = roll(4, 1), tint = new_tint(0, 0), r = 4 }
end

local function step_slot(slot, bounce_on, beat)
	slot.age = slot.age + 1
	slot.seconds = slot.age / FRAMES
	move_path(slot.path, bounce_on and beat ~= 0, slot.seconds)
	step_tint(slot.tint, slot.seconds)
	if slot.rotor then
		turn_rotor(slot.rotor, slot.seconds)
	end
end

local function push_layer(layer, slot, state, beat)
	local material = layer.material
	local rotor = slot.rotor
	material:set_shader_parameter("turn", Color(rotor.c, rotor.s, rotor.wc, rotor.wobble))
	material:set_shader_parameter("center", Vector2(state.basis_w * 0.5 + slot.path.x, state.basis_h * 0.5 + slot.path.y))
	local tint = slot.tint
	local r, g, b = tint.r, tint.g, tint.b
	local dot = beat == 1 and 2.0 or 1.0
	if slot.invert and tint.mode ~= 1 and beat ~= 0 then
		r, g, b, dot = 1.0 - r, 1.0 - g, 1.0 - b, 1.0
	end
	if slot.shape == 1 then
		local radius = slot.radius
		if slot.pulse then
			radius = radius + math.sin(slot.seconds * slot.pulse_rate) * slot.pulse
		end
		if beat ~= 0 then
			radius = radius + slot.radius * 0.05
		end
		material:set_shader_parameter("radius", radius)
	end
	material:set_shader_parameter("tint", Color(r, g, b, 1.0))
	if slot.half then
		if slot.half_invert then
			material:set_shader_parameter("half_tint", Color(1.0 - r, 1.0 - g, 1.0 - b, 1.0))
		else
			material:set_shader_parameter("half_tint", Color(r, g, b, 1.0))
		end
	end
	material:set_shader_parameter("dot_radius", dot)
	material:set_shader_parameter("hue_start", tint.start or 0.0)
	material:set_shader_parameter("pixel", state.pixel)
end

local function normalized(audio, out, state)
	if audio.stereo then
		for i = 1, 256 do
			out[i] = (bins.wave(audio, (i - 1) * 4) - 128) / 127
		end
		return out, (state.basis_w + state.basis_h) * 0.5 * 0.1
	end
	local wave = audio.wave or {}
	local count = #wave
	local peak = 0.001
	for i = 1, count do
		local v = (wave[i > 1 and i - 1 or 1] + wave[i] * 2.0 + wave[i < count and i + 1 or count]) * 0.25
		out[i] = v
		if math.abs(v) > peak then
			peak = math.abs(v)
		end
	end
	return out, 127.0 / peak
end

local function draw_points(canvas, points, colors, lines, k)
	if lines then
		canvas:draw_polyline_colors(points, colors, k)
		return
	end
	local pairs_list, pair_colors = {}, {}
	for i = 1, #points do
		pairs_list[i * 2 - 1] = points[i]
		pairs_list[i * 2] = Vector2(points[i].x + k, points[i].y)
		pair_colors[i] = colors[i]
	end
	canvas:draw_multiline_colors(pairs_list, pair_colors, k)
end

local function color_of(tint, index, white, invert)
	if white then
		return Color(1.0, 1.0, 1.0, 1.0)
	end
	if tint.mode == 1 then
		return hue_at(tint, index)
	end
	if invert then
		return Color(1.0 - tint.r, 1.0 - tint.g, 1.0 - tint.b, 1.0)
	end
	return Color(tint.r, tint.g, tint.b, 1.0)
end

local function draw_wave(canvas, slot, state, audio, beat)
	local wave, gain = state.wave, state.gain
	local count = #wave
	if count == 0 then
		return
	end
	local k = state.pixel
	local cx, cy = state.basis_w * 0.5 + slot.path.x, state.basis_h * 0.5 + slot.path.y
	local lines = slot.lines
	local white = false
	if beat ~= 0 then
		if lines then
			white = true
		elseif slot.tint.mode ~= 2 then
			lines = true
		else
			white = true
		end
	end
	local function sample(position)
		local at = position * (count - 1)
		local index = math.floor(at)
		local a = wave[index + 1]
		local b = wave[math.min(index + 2, count)]
		return (a + (b - a) * (at - index)) * gain
	end
	if slot.wave_kind == "full" then
		local n = 256
		local points, colors = {}, {}
		local half = (slot.vertical and state.basis_w or state.basis_h) * 0.5
		for i = 1, n do
			local along = (i - 1) / (n - 1) * (slot.vertical and state.basis_h or state.basis_w)
			local v = half - sample((i - 1) / (n - 1))
			if v < 0.0 or v > half * 2.0 - 1.0 then
				v = half
			end
			points[i] = slot.vertical and Vector2(v * k, along * k) or Vector2(along * k, v * k)
			colors[i] = color_of(slot.tint, i, white)
		end
		draw_points(canvas, points, colors, slot.lines, k)
		if slot.double then
			for i = 1, n do
				points[i] = Vector2(points[i].x, points[i].y + k)
				colors[i] = color_of(slot.tint, i, white, true)
			end
			draw_points(canvas, points, colors, slot.lines, k)
		end
		return
	end
	if slot.wave_kind == "ring" then
		local n = 256
		local points, colors, inner, inner_colors = {}, {}, {}, {}
		local base = slot.size
		if slot.pulse then
			base = base + math.sin(slot.seconds * slot.pulse_rate) * slot.pulse
		end
		local div = beat == 1 and 3.0 or 2.0
		for i = 1, n + 1 do
			local position = ((i - 1) % n) / n
			local radius = base + sample(position) / div
			local a = position * PI * 2.0
			local x, y = apply_rotor(slot.rotor, math.cos(a) * radius, math.sin(a) * radius)
			points[i] = Vector2((cx + x) * k, (cy + y) * k)
			colors[i] = color_of(slot.tint, i, white)
			if slot.half then
				inner[i] = Vector2((cx + x * 0.5) * k, (cy + y * 0.5) * k)
				inner_colors[i] = color_of(slot.tint, i, white, slot.half_invert)
			end
		end
		draw_points(canvas, points, colors, lines, k)
		if slot.half then
			draw_points(canvas, inner, inner_colors, lines, k)
		end
		return
	end
	local size = slot.size
	if slot.pulse then
		size = size + math.sin(slot.seconds * slot.pulse_rate) * slot.pulse
	end
	local n = 256
	local div = 2.0
	local function pass(swap)
		local points, colors = {}, {}
		for i = 1, n do
			local position = (i - 1) / (n - 1)
			local along = position * size - size * 0.5
			local v = sample(position)
			v = slot.taper and v * (0.5 - position) * 2.0 or v / div
			local x, y = along, v
			if swap then
				x, y = v, along
			end
			x, y = apply_rotor(slot.rotor, x, y)
			points[i] = Vector2((cx + x) * k, (cy + y) * k)
			colors[i] = color_of(slot.tint, i, white)
		end
		draw_points(canvas, points, colors, lines, k)
	end
	pass(false)
	if slot.cross then
		pass(true)
	end
end

local function make_slot(state, name, arg)
	return KINDS[name](arg, state.basis_w, state.basis_h)
end

local function setup_scene(state, scene)
	state.pixel = scene.height / 480.0
	state.basis_h = 480.0
	state.basis_w = 480.0 * scene.width / scene.height
	scene.engine.set(scene, "basis", Vector2(state.basis_w, state.basis_h))
end

return {
	name = "PixelTrip",
	presets = {
		{
			name = "PixelTrip",
			feedback = WARP,
			resize = function(state, scene)
				setup_scene(state, scene)
			end,
			setup = function(state, scene)
				dots_shader = dots_shader or nari.load(DOTS)
				setup_scene(state, scene)
				state.frames = 0
				state.warps = pick_bag({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 })
				state.bag_a = pick_bag(BAG_A)
				state.bag_b = pick_bag(BAG_B)
				state.rings = {}
				state.ring_at = span(120.0, 240.0) * FRAMES
				state.b_at = span(2.0, 7.0) * FRAMES
				state.a_at = 0.0
				state.motion_on = true
				state.bounce = true
				state.motion_at = toggle(0)
				state.bounce_at = toggle(0)
				state.layer_b = new_layer(scene, scene.canvas)
				state.layer_a = new_layer(scene, scene.canvas)
				state.wave = {}
				state.gain = 1.0
				set_warp(state, scene)
				new_warp_path(state)
			end,
			step = function(state, audio, scene)
				state.frames = state.frames + 1
				local frames = state.frames
				local beat
				if audio.stereo then
					beat = (math.floor(bins.mean(audio, 0, 8)) + math.floor(bins.mean(audio, 1, 8))) // BEAT_DIVISOR
				else
					local bands = audio.bands or {}
					local total = 0.0
					for i = 1, #bands do
						total = total + bands[i]
					end
					beat = #bands > 0 and math.floor((total / #bands / BEAT_LEVEL) ^ 4) or 0
				end
				state.beat = beat
				state.wave, state.gain = normalized(audio, state.wave, state)

				state.warp_timer = state.warp_timer - 1
				if state.warp_timer <= 0 then
					set_warp(state, scene)
				end
				if frames > state.motion_at then
					state.motion_on = not state.motion_on
					state.motion_at = toggle(frames)
					new_warp_path(state)
				end
				if frames > state.bounce_at then
					state.bounce = not state.bounce
					state.bounce_at = toggle(frames)
					if state.bounce and state.motion_on then
						new_warp_path(state)
					end
				end
				if state.motion_on then
					move_path(state.warp_path, state.bounce and beat ~= 0, frames / FRAMES)
					scene.engine.set(scene, "shift", Vector2(state.warp_path.x, state.warp_path.y))
				else
					scene.engine.set(scene, "shift", Vector2(0.0, 0.0))
				end

				for i = #state.rings, 1, -1 do
					local ring = state.rings[i]
					ring.age = ring.age + 1
					ring.seconds = ring.age / FRAMES
					move_path(ring.path, state.bounce and beat ~= 0, ring.seconds)
					step_tint(ring.tint, ring.seconds)
					if ring.age > ring.life then
						table.remove(state.rings, i)
					end
				end
				if state.ring_at and frames > state.ring_at then
					state.ring_at = nil
					for _ = 1, math.floor(random() * 7) + 3 do
						state.rings[#state.rings + 1] = new_ring(state)
					end
				end
				if not state.ring_at and #state.rings == 0 then
					state.ring_at = frames + span(180.0, 300.0) * FRAMES
				end

				if state.slot_b and state.slot_b.age > state.slot_b.life then
					state.slot_b = nil
					bind_layer(state.layer_b, nil)
					state.b_at = frames + span(6.0, 14.0) * FRAMES
				end
				if state.slot_a and state.slot_a.age > state.slot_a.life then
					state.slot_a = nil
					bind_layer(state.layer_a, nil)
					state.a_at = frames + span(6.0, 14.0) * FRAMES
				end
				if not state.slot_b and state.b_at and frames > state.b_at then
					state.b_at = nil
					local name = state.bag_b.next()
					if name then
						state.slot_b = make_slot(state, name, 1)
						bind_layer(state.layer_b, state.slot_b)
					else
						state.b_at = frames + span(6.0, 13.0) * FRAMES
					end
				end
				if not state.slot_a and (frames > (state.a_at or 0) or (not state.slot_b and #state.rings == 0)) then
					local name = state.bag_a.next()
					if name then
						state.slot_a = make_slot(state, name, 0)
						bind_layer(state.layer_a, state.slot_a)
					else
						state.a_at = frames + span(6.0, 13.0) * FRAMES
					end
				end
				if not state.slot_a and not state.slot_b and #state.rings == 0 then
					state.slot_a = KINDS.full(0, state.basis_w, state.basis_h)
					bind_layer(state.layer_a, state.slot_a)
				end

				for _, pair in ipairs({ { state.slot_b, state.layer_b }, { state.slot_a, state.layer_a } }) do
					local slot, layer = pair[1], pair[2]
					if slot then
						step_slot(slot, state.bounce, beat)
						if slot.shape then
							push_layer(layer, slot, state, beat)
						end
					end
				end
				state.layer_a.node:queue_redraw()
				state.layer_b.node:queue_redraw()
			end,
			draw = function(canvas, state, audio)
				local k = state.pixel
				for _, ring in ipairs(state.rings) do
					local x = (state.basis_w * 0.5 + ring.path.x) * k
					local y = (state.basis_h * 0.5 + ring.path.y) * k
					local color = Color(ring.tint.r, ring.tint.g, ring.tint.b, 1.0)
					canvas:draw_circle(Vector2(x, y), ring.r * k, color, state.bounce and (state.beat or 0) ~= 0, 1.0)
				end
				local beat = state.beat or 0
				if state.slot_b and state.slot_b.wave_kind then
					draw_wave(canvas, state.slot_b, state, audio, beat)
				end
				if state.slot_a and state.slot_a.wave_kind then
					draw_wave(canvas, state.slot_a, state, audio, beat)
				end
			end,
		},
	},
}

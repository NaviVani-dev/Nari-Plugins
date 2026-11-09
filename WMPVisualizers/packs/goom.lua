local ZOOM = "shaders/goom/zoom.gdshader"
local SHOW = "shaders/goom/show.gdshader"
local IFS = "shaders/goom/ifs.gdshader"
local GX, GY = 65, 49
local STOP_SPEED = 128
local TIME_BTW_CHG = 300
local LINES = 80
local NORMAL, WAVE, CRYSTAL, SCRUNCH, AMULETTE, WATER, HYPERCOS1, HYPERCOS2, YONLY, SPEEDWAY = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
local CIRCLE, HLINE, VLINE = 0, 1, 2
local BLACK_LINE = 6
local LINE_COLORS = {
	[0] = { 220, 140, 40 },
	{ 230, 120, 18 },
	{ 236, 160, 40 },
	{ 252, 120, 18 },
	{ 80, 200, 18 },
	{ 80, 30, 250 },
	{ 16, 16, 16 },
}
local TENTACLE_COLORS = { { 0x18, 0x4c, 0x2f }, { 0x48, 0x2c, 0x6f }, { 0x58, 0x3c, 0x0f }, { 0x87, 0x55, 0x74 } }
local STATES = {
	{ ifs = true, points = false, tentacle = false, scope = true, low = 0, high = 100 },
	{ ifs = true, points = false, tentacle = false, scope = false, low = 101, high = 140 },
	{ ifs = true, points = false, tentacle = false, scope = true, low = 141, high = 200 },
	{ ifs = false, points = true, tentacle = false, scope = true, low = 201, high = 260 },
	{ ifs = false, points = true, tentacle = false, scope = true, low = 261, high = 330 },
	{ ifs = false, points = true, tentacle = true, scope = true, low = 331, high = 400 },
	{ ifs = false, points = false, tentacle = true, scope = false, low = 401, high = 450 },
	{ ifs = false, points = false, tentacle = true, scope = true, low = 451, high = 510 },
}
local STAR_BYTES = {
	{ 0x16, 0x18, 0x1a }, { 0x19, 0x18, 0x1a }, { 0x1f, 0x18, 0x1a }, { 0x26, 0x18, 0x1a }, { 0x2a, 0x18, 0x1a },
	{ 0x2f, 0x18, 0x1a }, { 0x36, 0x18, 0x1a }, { 0x2f, 0x18, 0x19 }, { 0x26, 0x16, 0x15 }, { 0x20, 0x14, 0x11 },
	{ 0x1a, 0x10, 0x0a }, { 0x18, 0x05, 0x08 }, { 0x10, 0x03, 0x04 }, { 0x05, 0x01, 0x01 }, { 0x00, 0x00, 0x00 },
}
local STAR_COLORS = {}
for index, bytes in ipairs(STAR_BYTES) do
	STAR_COLORS[index] = Color(bytes[1] / 255.0, bytes[2] / 255.0, bytes[3] / 255.0, 1.0)
end
local YELLOW, ORANGE, VIOLET = Color(1.0, 1.0, 0.2, 1.0), Color(1.0, 0.8, 0.0196, 1.0), Color(0.3333, 0.0196, 1.0, 1.0)
local BLACK, WHITE = Color(0.0, 0.0, 0.0, 1.0), Color(1.0, 1.0, 1.0, 1.0)

local function irand(count)
	return math.random(0, count - 1)
end

local function log10(value)
	return math.log(value, 10)
end

local function trunc(value)
	return value >= 0 and math.floor(value) or math.ceil(value)
end

local function lighten(value, power)
	local t = value * log10(power) / 2.0
	return t > 0 and math.min(255, math.floor(t)) or 0
end

local function lit(rgb, power)
	return Color(lighten(rgb[1], power) / 255.0, lighten(rgb[2], power) / 255.0, lighten(rgb[3], power) / 255.0, 1.0)
end

local function add_material()
	local blend = CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return blend
end

local function zoom_vector(data, x, y)
	local dist = x * x + y * y
	local coef = (1.0 + data.speed) / 50.0
	local mode = data.mode
	if mode == CRYSTAL then
		coef = coef - (dist - 0.3) / 15.0
	elseif mode == AMULETTE then
		coef = coef + dist * 3.5
	elseif mode == WAVE then
		coef = coef + math.sin(dist * 20.0) / 100.0
	elseif mode == SCRUNCH then
		coef = coef + dist / 10.0
	elseif mode == SPEEDWAY then
		coef = coef * 4.0 * y
	end
	coef = math.max(-2.01, math.min(2.01, coef))
	local vx, vy = coef * x, coef * y
	if data.hypercos then
		vx = vx + math.sin(y * 10.0) / 120.0
		vy = vy + math.sin(x * 10.0) / 120.0
	end
	if data.hplane ~= 0 then
		vx = vx + y * 0.0025 * data.hplane
	end
	if data.vplane ~= 0 then
		vy = vy + x * 0.0025 * data.vplane
	end
	return vx, vy
end

local function new_field()
	local image = Image.create(GX, GY, false, Image.FORMAT_RGH)
	return { image = image, xs = {}, ys = {}, noise = 0.0 }
end

local function make_rows(state, field, data, first, last)
	local w, h = state.w, state.h
	local ratio = 2.0 / w
	local least = ratio / 16.0
	local image, xs, ys = field.image, field.xs, field.ys
	for row = first, last do
		local y = (row / (GY - 1) * (h - 1) - data.my) * ratio
		for col = 0, GX - 1 do
			local x = (col / (GX - 1) * (w - 1) - data.mx) * ratio
			local vx, vy = zoom_vector(data, x, y)
			if math.abs(vx) < least then
				vx = vx < 0 and -least or least
			end
			if math.abs(vy) < least then
				vy = vy < 0 and -least or least
			end
			local at = col + row * GX
			xs[at], ys[at] = vx, vy
			image:set_pixel(col, row, Color(vx, vy, 0.0, 1.0))
		end
	end
end

local function zoom_filter(state, scene, zf, incr, mult)
	local z = state.zoom
	if z.start ~= -2 then
		zf = nil
	end
	if zf then
		z.data.speed = (zf.vitesse - 128) / 128.0
		if zf.reverse then
			z.data.speed = -z.data.speed
		end
		z.data.mx, z.data.my = zf.mx, zf.my
		z.data.mode = zf.mode
		z.data.hplane, z.data.vplane = zf.hplane, zf.vplane
		z.data.hypercos = zf.hypercos
		z.data.noisy = zf.noisify ~= 0
		z.start, z.made = 0, 0
	end
	if z.start == -1 then
		local t = z.ratio / 65535.0
		if t > 0 then
			local s, d = z.s, z.d
			local image, sx, sy, dx, dy = s.image, s.xs, s.ys, d.xs, d.ys
			for row = 0, GY - 1 do
				for col = 0, GX - 1 do
					local at = col + row * GX
					local x, y = sx[at] + (dx[at] - sx[at]) * t, sy[at] + (dy[at] - sy[at]) * t
					sx[at], sy[at] = x, y
					image:set_pixel(col, row, Color(x, y, 0.0, 1.0))
				end
			end
			s.noise = s.noise + (d.noise - s.noise) * t
			z.s_tex:update(image)
			scene.engine.set(scene, "noise_from", s.noise)
		end
		z.ratio = 0
		z.d, z.t = z.t, z.d
		z.d_tex:update(z.d.image)
		scene.engine.set(scene, "noise_to", z.d.noise)
		z.start = -2
	end
	if z.start >= 0 then
		z.made = z.made + 1
		local upto = math.min(GY - 1, math.ceil(z.made * GY / 16) - 1)
		make_rows(state, z.t, z.data, z.start, upto)
		z.t.noise = z.data.noisy and 1.0 or 0.0
		z.start = upto + 1
		if upto >= GY - 1 then
			z.start = -1
		end
	end
	if incr ~= 0 then
		z.ratio = math.min(65535, z.ratio + incr)
	end
	if mult ~= 1.0 then
		z.ratio = math.floor(65535 * (1.0 - mult) + z.ratio * mult)
	end
	scene.engine.set(scene, "ratio", z.ratio / 65535.0)
end

local function evaluate_sound(sound, data)
	local top = 0
	for index = 1, #data do
		top = math.max(top, data[index])
	end
	sound.max = math.max(sound.max, top)
	sound.volume = top / sound.max
	local dif = sound.accel
	sound.accel = sound.volume
	sound.speed = math.min(sound.speed, 1.0)
	if sound.speed < 0.1 then
		sound.accel = sound.accel * (1.0 - sound.speed)
	elseif sound.speed < 0.3 then
		sound.accel = sound.accel * (0.9 - (sound.speed - 0.1) / 2.0)
	else
		sound.accel = sound.accel * (0.8 - (sound.speed - 0.3) / 4.0)
	end
	sound.accel = math.max(0.0, sound.accel * 0.95)
	dif = math.abs(sound.accel - dif)
	local previous = sound.speed
	sound.speed = (sound.speed + dif * 0.5) / 2
	sound.speed = sound.speed * 0.99
	sound.speed = math.max(0.0, math.min(1.0, (sound.speed + 3.0 * previous) / 4.0))
	sound.since = sound.since + 1
	sound.since_big = sound.since_big + 1
	sound.cycle = sound.cycle + 1
	if sound.speed > 0.1 and sound.accel > sound.big_limit and sound.since_big > 100 then
		sound.since_big = 0
	end
	if sound.accel > sound.limit then
		sound.total = sound.total + 1
		sound.since = 0
		sound.power = sound.accel - sound.limit
	end
	sound.prov = math.max(sound.prov, sound.accel)
	sound.limit = math.min(sound.limit, 1)
	if sound.cycle % 64 == 0 then
		if sound.speed < 0.01 then
			sound.limit = sound.limit * 0.91
		end
		if sound.total > 4 then
			sound.limit = sound.limit + 0.02
		end
		if sound.total > 7 then
			sound.limit = sound.limit * 1.03 + 0.03
		end
		if sound.total > 16 then
			sound.limit = sound.limit * 1.05 + 0.04
		end
		if sound.total == 0 then
			sound.limit = sound.prov - 0.02
		end
		if sound.total == 1 and sound.limit > 0.02 then
			sound.limit = sound.limit - 0.01
		end
		sound.total = 0
		sound.big_limit = sound.limit * 1.02
		sound.prov = 0
	end
end

local function gen_line(id, param, line, rx, ry)
	for i = 0, 255 do
		local at = i * 2
		if id == HLINE then
			line[i] = { at * rx / 512.0, param, math.pi / 2.0 }
		elseif id == VLINE then
			line[i] = { param, at * ry / 512.0, 0.0 }
		else
			local angle = 2.0 * math.pi * at / 512.0
			line[i] = { rx / 2.0 + param * math.cos(angle), ry / 2.0 + param * math.sin(angle), angle }
		end
	end
end

local function new_line(rx, ry, src, param_s, col_s, dest, param_d, col_d)
	local line = { points = {}, target = {}, amplitude = 1.0, goal = 1.0, power = 0.0, inc = 0.01, rx = rx, ry = ry }
	gen_line(src, param_s, line.points, rx, ry)
	gen_line(dest, param_d, line.target, rx, ry)
	local a, b = LINE_COLORS[col_s], LINE_COLORS[col_d]
	line.color = { a[1], a[2], a[3] }
	line.color2 = { b[1], b[2], b[3] }
	return line
end

local function switch_line(line, id, param, amplitude, col)
	gen_line(id, param, line.target, line.rx, line.ry)
	line.goal = amplitude
	local c = LINE_COLORS[col]
	line.color2 = { c[1], c[2], c[3] }
end

local function emit_line(state, line, data)
	local color = lit(line.color, line.power)
	local pts, count = {}, 0
	local rx, ry = line.rx, line.ry
	local amp = line.amplitude / 1000.0
	local polys = state.polys
	for i = 0, 255 do
		local pt = line.points[i]
		local v = data[i + 1] * amp
		local x, y = trunc(pt[1] + math.cos(pt[3]) * v), trunc(pt[2] + math.sin(pt[3]) * v)
		if x >= 0 and y >= 0 and x < rx and y < ry then
			count = count + 1
			pts[count] = Vector2(x + 0.5, y + 0.5)
		elseif count > 0 then
			if count > 1 then
				polys[#polys + 1] = { pts, color }
			end
			pts, count = {}, 0
		end
	end
	if count > 1 then
		polys[#polys + 1] = { pts, color }
	end
	for i = 0, 255 do
		local pt, to = line.points[i], line.target[i]
		pt[1] = (to[1] + 39.0 * pt[1]) / 40.0
		pt[2] = (to[2] + 39.0 * pt[2]) / 40.0
		pt[3] = (to[3] + 39.0 * pt[3]) / 40.0
	end
	for c = 1, 3 do
		line.color[c] = (line.color[c] * 63 + line.color2[c]) >> 6
	end
	line.power = line.power + line.inc
	if line.power < 1.1 then
		line.power = 1.1
		line.inc = (irand(20) + 10) / 300.0
	end
	if line.power > 17.5 then
		line.power = 17.5
		line.inc = -(irand(20) + 10) / 300.0
	end
	line.amplitude = (99.0 * line.amplitude + line.goal) / 100.0
end

local function choose_line(state, far)
	local w, h = state.w, state.h
	local mode = irand(3)
	local p1, p2, amplitude = 0.0, 0.0, 1.0
	if mode == CIRCLE then
		if far then
			p1, p2, amplitude = 0.47, 0.47, 0.8
		elseif irand(3) == 0 then
			p1, p2, amplitude = 0.0, 0.0, 3.0
		elseif irand(2) == 1 then
			p1, p2 = 0.40 * h, 0.22 * h
		else
			p1, p2 = h * 0.35, h * 0.35
		end
	elseif mode == HLINE then
		if irand(4) ~= 0 or far then
			p1, p2 = h // 7, 6.0 * h / 7.0
		else
			p1, p2, amplitude = h / 2.0, h / 2.0, 2.0
		end
	else
		if irand(3) ~= 0 or far then
			p1, p2 = w / 7.0, 6.0 * w / 7.0
		else
			p1, p2, amplitude = w / 2.0, w / 2.0, 1.5
		end
	end
	return p1, p2, amplitude, irand(6), mode
end

local function new_grid(cx, cy, cz, sizex, defx, sizez, defz)
	local g = { defx = defx, defz = defz, cx = cx, cy = cy, cz = cz, x = {}, y = {}, z = {} }
	for row = 0, defz - 1 do
		for col = 0, defx - 1 do
			local at = col + defx * row
			g.x[at] = (col - defx // 2) * sizex / defx
			g.y[at] = 0.0
			g.z[at] = (row - defz // 2) * sizez / defz
		end
	end
	return g
end

local function tentacle_setup(state)
	local t = {
		cycle = 0.0, col = { 0x28, 0x2c, 0x5f }, dst = 1, lig = 1.15, ligs = 0.1,
		distt = 10.0, distt2 = 0.0, rot = 0.0, happens = 0, rotation = 0, lock = 0,
		grids = {}, vals = {},
	}
	local cy = -17.0
	for index = 1, 6 do
		local z = 45 + irand(30)
		t.grids[index] = new_grid(0.0, cy, z, 85 + irand(5), 15, z, 45 + irand(10))
		cy = cy + 8
	end
	state.tentacle = t
end

local function pretty_move(t)
	if t.happens > 0 then
		t.happens = t.happens - 1
	elseif t.lock == 0 then
		t.happens = irand(200) ~= 0 and 0 or 100 + irand(60)
		t.lock = t.happens * 3 // 2
	else
		t.lock = t.lock - 1
	end
	local tmp = t.happens > 0 and 8.0 or 0.0
	t.distt2 = (tmp + 15.0 * t.distt2) / 16.0
	tmp = 30 + 256.0 - 90.0 * (1.0 + math.sin(t.cycle * 19 / 20))
	if t.happens > 0 then
		tmp = tmp * 0.6
	end
	t.distt = (tmp + 3.0 * t.distt) / 4.0
	local cycle = t.cycle
	if t.happens == 0 then
		tmp = math.pi * math.sin(cycle) / 32 + 3 * math.pi / 2
	else
		t.rotation = irand(500) ~= 0 and t.rotation or irand(2)
		cycle = cycle * (t.rotation ~= 0 and 2.0 * math.pi or -math.pi)
		tmp = cycle - (math.pi * 2.0) * math.floor(cycle / (math.pi * 2.0))
	end
	local tau = 2.0 * math.pi
	if math.abs(tmp - t.rot) > math.abs(tmp - (t.rot + tau)) then
		t.rot = (tmp + 15.0 * (t.rot + tau)) / 16.0
		if t.rot > tau then
			t.rot = t.rot - tau
		end
	elseif math.abs(tmp - t.rot) > math.abs(tmp - (t.rot - tau)) then
		t.rot = (tmp + 15.0 * (t.rot - tau)) / 16.0
		if t.rot < 0.0 then
			t.rot = t.rot + tau
		end
	else
		t.rot = (tmp + 15.0 * t.rot) / 16.0
	end
	return t.distt, t.distt2, t.rot
end

local function evolve(src, dest)
	if src ~= 255 and src < dest then
		src = src + 1
	end
	if src > dest then
		src = src - 1
	end
	return src
end

local function grid_emit(state, g, angle, vals, dist2, dist, low, bright)
	local defx, defz = g.defx, g.defz
	local ys = g.y
	for i = 0, defx - 1 do
		ys[i] = ys[i] * 0.2 + vals[i] * 0.8
	end
	for i = defx, defx * defz - 1 do
		ys[i] = ys[i] * 0.255 + ys[i - defx] * 0.777
	end
	local cam_y = g.cy + math.sin(angle / 4.3) * 2.0
	local cam_z = g.cz + dist2
	local sina, cosa = math.sin(angle), math.cos(angle)
	local xs, zs = g.x, g.z
	local w, h = state.w, state.h
	local hw, hh = w >> 1, h >> 1
	for col = 0, defx - 1 do
		local pts, count = {}, 0
		for row = 0, defz - 1, 2 do
			local at = col + defx * row
			local x, z = xs[at], zs[at]
			local sz = x * cosa + z * sina + cam_z
			local inside = false
			if sz > 2 then
				local px = trunc(dist * (x * sina - z * cosa) / sz) + hw
				local py = hh - trunc(dist * (ys[at] + cam_y) / sz)
				if px >= 0 and py >= 0 and px < w and py < h then
					inside = true
					count = count + 1
					pts[count] = Vector2(px + 0.5, py + 0.5)
				end
			end
			if not inside and count > 0 then
				if count > 1 then
					state.polys[#state.polys + 1] = { pts, low }
					state.bright[#state.bright + 1] = { pts, bright }
				end
				pts, count = {}, 0
			end
		end
		if count > 1 then
			state.polys[#state.polys + 1] = { pts, low }
			state.bright[#state.bright + 1] = { pts, bright }
		end
	end
end

local function tentacle_update(state, data, rapport, drawit)
	local t = state.tentacle
	if not drawit and t.ligs > 0.0 then
		t.ligs = -t.ligs
	end
	t.lig = t.lig + t.ligs
	if t.lig > 1.01 then
		if t.lig > 10.0 or t.lig < 1.1 then
			t.ligs = -t.ligs
		end
		if t.lig < 6.3 and irand(30) == 0 then
			t.dst = irand(4) + 1
		end
		local goal = TENTACLE_COLORS[t.dst]
		for c = 1, 3 do
			t.col[c] = evolve(t.col[c], goal[c])
		end
		local bright, low = lit(t.col, t.lig * 2.0 + 2.0), lit(t.col, t.lig / 3.0 + 0.67)
		rapport = math.min(1.12, (1.0 + 2.0 * (rapport - 1.0)) * 1.2)
		local dist, dist2, rot = pretty_move(t)
		for _, g in ipairs(t.grids) do
			for col = 0, 14 do
				t.vals[col] = trunc(data[irand(256) + 1] / 1024.0) * rapport
			end
			grid_emit(state, g, rot, t.vals, dist2, dist, low, bright)
		end
		t.cycle = t.cycle + 0.01
	else
		t.lig = 1.05
		if t.ligs < 0.0 then
			t.ligs = -t.ligs
		end
		pretty_move(t)
		t.cycle = t.cycle + 0.1
		if t.cycle > 1000 then
			t.cycle = 0.0
		end
	end
end

local function add_bomb(fs, mx, my, radius, vage, gravity)
	if #fs.stars >= 512 then
		return
	end
	local ro = radius * irand(100) / 100.0
	ro = ro * (irand(100) / 100.0 + 1.0)
	local theta = irand(256) * 2.0 * math.pi / 256.0
	fs.stars[#fs.stars + 1] = { x = mx, y = my, vx = ro * math.cos(theta), vy = -0.2 + ro * math.sin(theta), ay = gravity, age = 0.0, vage = math.max(vage, 0.01) }
end

local function star_event(state, sound)
	local fs, w, h = state.fs, state.w, state.h
	local max = trunc((1.0 + sound.power) * irand(150)) + 100
	local radius = (1.0 + sound.power) * (irand(150) + 50) / 300
	local mx, my, vage
	local gravity = 0.02
	if fs.mode == 0 then
		repeat
			mx, my = irand(w), irand(h)
			local dx, dy = mx - w // 2, my - h // 2
		until dx * dx + dy * dy >= (h // 2) * (h // 2)
		vage = 0.2 * (1.0 - sound.power)
	elseif fs.mode == 1 then
		mx = irand(w) > w // 2 and w or 0
		my = -(h // 3) - irand(w // 3)
		radius = radius * 1.5
		vage = 0.002
	elseif fs.mode == 2 then
		my = h + 2
		vage = 0.001
		radius = radius + 1.0
		mx = w // 2
		gravity = 0.04
	else
		return
	end
	radius = radius * h / 200.0
	max = trunc(max * h / 200.0)
	if sound.since_big < 1 then
		radius = radius * 1.5
		max = max * 2
	end
	for _ = 1, max do
		add_bomb(fs, mx, my, radius, vage, gravity)
	end
end

local function stars_update(state, sound)
	local fs, w, h = state.fs, state.w, state.h
	if sound.since < 1 then
		star_event(state, sound)
		if irand(20) == 1 then
			fs.mode = irand(9)
		end
	end
	local stars = fs.stars
	local points, colors, count = {}, {}, 0
	local index = 1
	while index <= #stars do
		local s = stars[index]
		s.x, s.y = s.x + s.vx, s.y + s.vy
		s.vy = s.vy + s.ay
		s.age = s.age + s.vage
		if s.x > w + 64 or (s.vy >= 0 and s.y - 16 * s.vy > h) or s.x < -64 or s.age >= 15 then
			stars[index] = stars[#stars]
			stars[#stars] = nil
		else
			local color = STAR_COLORS[math.floor(s.age) + 1]
			local from = Vector2(trunc(s.x) + 0.5, trunc(s.y) + 0.5)
			points[count + 1] = from
			points[count + 2] = Vector2(trunc(s.x - s.vx * 6) + 0.5, trunc(s.y - s.vy * 6) + 0.5)
			points[count + 3] = from
			points[count + 4] = Vector2(trunc(s.x - s.vx * 2) + 0.5, trunc(s.y - s.vy * 2) + 0.5)
			colors[count // 2 + 1] = color
			colors[count // 2 + 2] = color
			count = count + 4
			index = index + 1
		end
	end
	state.star_points, state.star_colors = points, colors
end

local function gauss(c, a, s)
	local y = math.random() * 127.0
	y = a * (1.0 - math.exp(-y * y * s)) / (1.0 - math.exp(-s))
	return irand(2) == 1 and c + y or c - y
end

local function half_gauss(c, a, s)
	local y = math.random() * 127.0
	y = a * (1.0 - math.exp(-y * y * s)) / (1.0 - math.exp(-s))
	return c + y
end

local function random_simi(f)
	return {
		c_x = gauss(0.0, 0.8, 4.0), c_y = gauss(0.0, 0.8, 4.0),
		r = gauss(f.r_mean, f.dr_mean, 3.0), r2 = half_gauss(0.0, f.dr2_mean, 2.0),
		a = gauss(0.0, 360.0, 4.0) * math.pi / 180.0, a2 = gauss(0.0, 360.0, 4.0) * math.pi / 180.0,
	}
end

local function ifs_setup(state)
	local nb = irand(4) + 2
	local f = { nb = nb, count = 0, speed = 6 }
	if nb == 3 then
		f.depth, f.r_mean, f.dr_mean, f.dr2_mean = 6, 0.6, 0.4, 0.3
	elseif nb == 4 then
		f.depth, f.r_mean, f.dr_mean, f.dr2_mean = 4, 0.5, 0.4, 0.3
	elseif nb == 5 then
		f.depth, f.r_mean, f.dr_mean, f.dr2_mean = 2, 0.5, 0.4, 0.3
	else
		f.depth, f.r_mean, f.dr_mean, f.dr2_mean = 10, 0.7, 0.3, 0.4
	end
	f.sets = {}
	for set = 1, 4 do
		f.sets[set] = {}
		for i = 1, nb do
			f.sets[set][i] = random_simi(f)
		end
	end
	f.uniform = {}
	for i = 1, 40 do
		f.uniform[i] = 0.0
	end
	f.col = { 0xc0, 0xc0, 0xc0, 0xc0 }
	f.v = { 3, 4, 2, 2 }
	f.mode, f.changed, f.cycle = 2, 0, 0
	state.fractal = f
	local per_pair, level = 0, 1
	for _ = 1, f.depth + 1 do
		level = level * nb
		per_pair = per_pair + level
	end
	local plane = QuadMesh.new()
	plane.size = Vector2(1.0, 1.0)
	local many = MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_2D
	many.mesh = plane
	many.instance_count = per_pair * nb * (nb - 1)
	state.ifs_mesh = many
	local material = ShaderMaterial.new()
	material.shader = nari.load(IFS)
	material:set_shader_parameter("nb", nb)
	material:set_shader_parameter("per_pair", per_pair)
	material:set_shader_parameter("half_size", Vector2((state.w - 1) // 2, (state.h - 1) // 2))
	state.ifs_material = material
end

local function bounce(col, v, c, top, floor, spread, base)
	col[c] = col[c] + v[c]
	if col[c] > top then
		col[c] = top
		v[c] = -irand(spread) - base
	end
	if col[c] < floor then
		col[c] = floor
		v[c] = irand(spread) + base
	end
end

local function ifs_colors(f)
	local col, v = f.col, f.v
	local R, G, B, A = 1, 2, 3, 4
	f.changed = f.changed - 1
	if f.mode == 0 then
		bounce(col, v, B, 255, 32, 4, 1)
		col[G] = col[G] + v[G]
		if col[G] > 200 then
			col[G] = 200
			v[G] = -irand(3) - 2
		end
		if col[G] > col[B] then
			col[G] = col[B]
			v[G] = v[B]
		end
		if col[G] < 32 then
			col[G] = 32
			v[G] = irand(3) + 2
		end
		bounce(col, v, R, 64, 0, 4, 1)
		bounce(col, v, A, 0, 0, 4, 1)
		if col[G] > 32 and col[R] < col[G] + 40 and col[G] < col[R] + 20 and col[B] < 64 and irand(20) == 0 and f.changed < 0 then
			f.mode = irand(3) ~= 0 and 1 or 2
			f.changed = 250
		end
	elseif f.mode == 2 then
		bounce(col, v, B, 128, 16, 4, 1)
		col[G] = col[G] + v[G]
		if col[G] > 200 then
			col[G] = 200
			v[G] = -irand(3) - 2
		end
		if col[G] > col[A] then
			col[G] = col[A]
			v[G] = v[A]
		end
		if col[G] < 32 then
			col[G] = 32
			v[G] = irand(3) + 2
		end
		bounce(col, v, R, 128, 0, 4, 1)
		bounce(col, v, A, 255, 0, 4, 1)
		if col[G] > 32 and col[R] < col[G] + 40 and col[G] < col[R] + 20 and col[B] < 64 and irand(20) == 0 and f.changed < 0 then
			f.mode = irand(3) ~= 0 and 1 or 0
			f.changed = 250
		end
	else
		bounce(col, v, B, 64, 0, 4, 1)
		col[G] = col[G] + v[G]
		if col[G] > 200 then
			col[G] = 200
			v[G] = -irand(3) - 2
		end
		if col[G] > col[R] + 20 then
			col[G] = col[R] + 20
			v[G] = -irand(3) - 2
			v[R] = irand(4) + 1
			v[B] = irand(4) + 1
		end
		if col[G] < 0 then
			col[G] = 0
			v[G] = irand(3) + 2
		end
		col[R] = col[R] + v[R]
		if col[R] > 255 then
			col[R] = 255
			v[R] = -irand(4) - 1
		end
		if col[R] > col[G] + 40 then
			col[R] = col[G] + 40
			v[R] = -irand(4) - 1
		end
		if col[R] < 0 then
			col[R] = 0
			v[R] = irand(4) + 1
		end
		bounce(col, v, A, 0, 0, 4, 1)
		if col[R] < 64 and col[G] > 32 and col[G] < col[B] and col[B] > 32 and irand(20) == 0 and f.changed < 0 then
			f.mode = irand(2) == 1 and 0 or 2
			f.changed = 250
		end
	end
end

local function ifs_update(state)
	local f = state.fractal
	local u = f.count * f.speed / 1000.0
	local uu, v = u * u, 1.0 - u
	local vv = v * v
	local u0, u1, u2, u3 = vv * v, 3.0 * vv * u, 3.0 * v * uu, u * uu
	local out = f.uniform
	local s1, s2, s3, s4 = f.sets[1], f.sets[2], f.sets[3], f.sets[4]
	for i = 1, f.nb do
		local a, b, c, d = s1[i], s2[i], s3[i], s4[i]
		local function bez(key)
			return u0 * a[key] + u1 * b[key] + u2 * c[key] + u3 * d[key]
		end
		local at = (i - 1) * 8
		local angle, angle2 = bez("a"), bez("a2")
		out[at + 1], out[at + 2] = bez("c_x"), bez("c_y")
		out[at + 3], out[at + 4] = math.cos(angle), math.sin(angle)
		out[at + 5], out[at + 6] = math.cos(angle2), math.sin(angle2)
		out[at + 7], out[at + 8] = bez("r"), bez("r2")
	end
	if f.count >= 1000 // f.speed then
		for i = 1, f.nb do
			local c, d = s3[i], s4[i]
			local next_b = {}
			for key, value in pairs(d) do
				next_b[key] = 2.0 * value - c[key]
			end
			s1[i], s2[i] = d, next_b
			s3[i], s4[i] = random_simi(f), random_simi(f)
		end
		f.count = 0
	else
		f.count = f.count + 1
	end
	f.cycle = f.cycle + 1
	if f.cycle >= 80 then
		f.cycle = 0
	end
	local shift = f.cycle < 40 and f.cycle // 10 or 7 - f.cycle // 10
	local col = f.col
	state.ifs_material:set_shader_parameter("simi", out)
	state.ifs_material:set_shader_parameter("increment", math.max(1, state.u.ifs_incr))
	state.ifs_material:set_shader_parameter("tint", Color((col[1] >> shift) / 255.0, (col[2] >> shift) / 255.0, (col[3] >> shift) / 255.0, 1.0))
	ifs_colors(f)
end

local function point(state, c, t1, t2, t3, t4, cycle)
	local w, h = state.w, state.h
	local x = w // 2 + trunc(t1 * math.cos(cycle / t3))
	local y = h // 2 + trunc(t2 * math.sin(cycle / t4))
	if x > 1 and y > 1 and x < w - 2 and y < h - 2 then
		state.dots[#state.dots + 1] = { x, y, c }
	end
end

local function points_update(state, sound, large)
	local u = state.u
	local pw, ph = state.w * 2 // 5, state.h * 2 // 5
	local i = 1
	while i * 15 <= sound.speed * 80.0 + 15 do
		u.loopvar = u.loopvar + math.floor(sound.speed * 50 + 1)
		local loop = u.loopvar
		point(state, YELLOW, (pw - 6.0) * large + 5.0, (ph - 6.0) * large + 5.0, i * 152.0, 128.0, loop + i * 2032)
		point(state, ORANGE, (pw // 2) * large / i + 10.0 * i, (ph // 2) * large / i + 10.0 * i, 96.0, i * 80.0, loop // i)
		point(state, VIOLET, (ph // 3 + 5.0) * large / i + 10.0 * i, (ph // 3 + 5.0) * large / i + 10.0 * i, i + 122.0, 134.0, loop // i)
		point(state, BLACK, (ph // 3) * large + 20.0, (ph // 3) * large + 20.0, 58.0, i * 66.0, loop // i)
		point(state, WHITE, (ph * large + 10.0 * i) / i, (ph * large + 10.0 * i) / i, 66.0, 74.0, loop + i * 500)
		i = i + 1
	end
end

local function change_mode(z)
	local roll = irand(34)
	if roll == 0 or roll == 10 or roll == 13 or roll == 20 or roll == 21 then
		if roll == 0 or roll == 10 then
			z.hypercos = irand(2) == 1
		end
		z.mode = WAVE
		z.reverse = false
		if irand(3) == 0 then
			z.wave = true
		end
		if irand(2) == 1 then
			z.vitesse = (z.vitesse + 127) >> 1
		end
	elseif roll == 1 or roll == 11 then
		z.mode, z.hypercos = CRYSTAL, false
	elseif roll == 2 or roll == 12 then
		z.mode, z.hypercos = AMULETTE, false
	elseif roll == 3 then
		z.mode, z.hypercos = WATER, false
	elseif roll == 4 or roll == 14 then
		z.mode, z.hypercos = SCRUNCH, false
	elseif roll == 5 or roll == 15 or roll == 22 then
		z.mode = HYPERCOS1
		z.hypercos = irand(3) == 0
	elseif roll == 6 or roll == 16 then
		z.mode, z.hypercos = HYPERCOS2, false
	elseif roll == 7 or roll == 17 then
		z.mode = CRYSTAL
		z.hypercos = irand(2) == 1
	elseif roll == 8 or roll == 18 or roll == 19 then
		z.mode, z.hypercos = SCRUNCH, true
	elseif roll == 29 or roll == 30 then
		z.mode = YONLY
	elseif roll >= 31 then
		z.mode = SPEEDWAY
	else
		z.mode, z.hypercos = NORMAL, false
	end
end

local function goom_event(state, sound)
	local u, z, w, h = state.u, state.u.zf, state.w, state.h
	local changed = false
	u.goomvar = u.goomvar + 1
	if u.blocker == 0 and irand(3) ~= 0 then
		u.selection = irand(510)
		u.blocker = 3
	elseif u.blocker ~= 0 then
		u.blocker = u.blocker - 1
	end
	for _, item in ipairs(STATES) do
		if u.selection >= item.low and u.selection <= item.high then
			u.state = item
		end
	end
	if u.state.ifs and u.ifs_incr <= 0 then
		u.recay_ifs = 5
		u.ifs_incr = 11
	end
	if not u.state.ifs and u.ifs_incr > 0 and u.decay_ifs <= 0 then
		u.decay_ifs = 100
	end
	if not u.state.scope then
		u.stop_lines = 0
		u.line_mode = LINES
	end
	u.lock = 50
	local newvit = math.floor(STOP_SPEED + 1 - 3.5 * log10(sound.speed * 60 + 1))
	if z.reverse and state.cycle % 13 == 0 and irand(5) == 0 then
		z.reverse = false
		z.vitesse = STOP_SPEED - 2
		u.lock = 75
	end
	if irand(10) == 0 then
		z.reverse = true
		u.lock = 100
	end
	if irand(10) == 0 then
		z.vitesse = STOP_SPEED - 1
	end
	if irand(12) == 0 then
		z.vitesse = STOP_SPEED + 1
	end
	local place = irand(25)
	if place == 0 or place == 3 or place == 6 then
		z.my, z.mx = h - 1, w // 2
	elseif place == 1 or place == 4 then
		z.mx = w - 1
	elseif place == 2 or place == 5 then
		z.mx = 1
	else
		z.my, z.mx = h // 2, w // 2
	end
	if z.mode == WATER or z.mode == YONLY or z.mode == AMULETTE then
		z.mx, z.my = w // 2, h // 2
	end
	local plane = irand(15)
	if plane == 0 then
		z.vplane, z.hplane = irand(3) - irand(3), irand(3) - irand(3)
	elseif plane == 3 then
		z.vplane, z.hplane = 0, irand(8) - irand(8)
	elseif plane >= 4 and plane <= 7 then
		z.vplane = irand(5) - irand(5)
		z.hplane = -z.vplane
	elseif plane == 8 then
		z.hplane = 5 + irand(8)
		z.vplane = -z.hplane
	elseif plane == 9 then
		z.vplane = 5 + irand(8)
		z.hplane = -z.hplane
	elseif plane == 13 then
		z.hplane, z.vplane = 0, irand(10) - irand(10)
	elseif plane == 14 then
		z.hplane, z.vplane = irand(10) - irand(10), irand(10) - irand(10)
	elseif plane < 10 then
		z.vplane, z.hplane = 0, 0
	end
	if irand(5) ~= 0 then
		z.noisify = 0
	else
		z.noisify = irand(2) + 1
		u.lock = u.lock * 2
	end
	if z.mode == AMULETTE then
		z.vplane, z.hplane, z.noisify = 0, 0, 0
	end
	if z.mx == 1 or z.mx == w - 1 then
		z.vplane = 0
		if irand(2) == 1 then
			z.hplane = 0
		end
	end
	if newvit < z.vitesse then
		changed = true
		if (newvit < STOP_SPEED - 7 and z.vitesse < STOP_SPEED - 6 and state.cycle % 3 == 0) or irand(40) == 0 then
			z.vitesse = STOP_SPEED - irand(2) + irand(2)
			z.reverse = not z.reverse
		else
			z.vitesse = (newvit + z.vitesse * 7) // 8
		end
		u.lock = u.lock + 50
	end
	if u.lock > 150 then
		u.switch_incr = 0x7f
		u.switch_mult = 1.0
	end
	return changed
end

local function goom_update(state, audio, scene)
	local u, sound, w, h = state.u, state.sound, state.w, state.h
	local data0, data1 = state.data0, state.data1
	local wave = audio.wave or {}
	local n = #wave
	for i = 1, 256 do
		local at = (i - 1) / 255.0
		local a = n > 0 and wave[math.floor(at * (n - 1)) + 1] or 0.0
		local b = n > 0 and wave[math.floor(((at + 0.13) % 1.0) * (n - 1)) + 1] or 0.0
		data0[i] = math.floor(a * 32767.0)
		data1[i] = math.floor(b * 32767.0)
	end
	evaluate_sound(sound, data0)
	state.polys, state.bright, state.dots = {}, {}, {}
	local large = math.min(1.5, sound.speed / 150.0 + sound.volume / 1.5)
	u.decay_ifs = u.decay_ifs - 1
	if u.decay_ifs > 0 then
		u.ifs_incr = u.ifs_incr + 2
	end
	if u.decay_ifs == 0 then
		u.ifs_incr = 0
	end
	if u.recay_ifs ~= 0 then
		u.ifs_incr = u.ifs_incr - 2
		u.recay_ifs = u.recay_ifs - 1
		if u.recay_ifs == 0 and u.ifs_incr <= 0 then
			u.ifs_incr = 1
		end
	end
	state.show_ifs = u.ifs_incr > 0
	if state.show_ifs then
		ifs_update(state)
	end
	if u.state.points then
		points_update(state, sound, large)
	end
	local z = u.zf
	local changed = false
	u.lock = math.max(0, u.lock - 1)
	if sound.since == 0 or u.since_change > TIME_BTW_CHG then
		if irand(16) == 0 then
			change_mode(z)
		end
	end
	if u.lock == 0 then
		if sound.since == 0 then
			changed = goom_event(state, sound)
		end
		if irand(700) == 0 then
			changed = true
			z.vitesse = STOP_SPEED - 1
			u.goomvar = 1
			u.lock = u.lock + 50
			u.switch_incr = 0x7f
			u.switch_mult = 1.0
		end
	end
	if sound.speed < 0.01 and z.vitesse < STOP_SPEED - 4 and state.cycle % 16 == 0 then
		changed = true
		z.vitesse = z.vitesse + 3
		u.goomvar = 0
	end
	if state.cycle % 73 == 0 and z.vitesse < STOP_SPEED - 5 then
		changed = true
		z.vitesse = z.vitesse + 1
	end
	if changed then
		u.since_change = 0
		u.switch_incr = 0x7f
		local dif = math.abs(z.vitesse - u.previous_speed)
		if dif > 2 then
			u.switch_incr = u.switch_incr * ((dif + 2) // 2)
		end
		u.previous_speed = z.vitesse
		u.switch_mult = 1.0
		if sound.since == 0 and sound.total < 2 then
			u.switch_incr = 0
			u.switch_mult = 29.0 / 30.0
		end
	elseif u.since_change > TIME_BTW_CHG then
		changed = true
		u.since_change = 0
	else
		u.since_change = u.since_change + 1
	end
	zoom_filter(state, scene, changed and z or nil, u.switch_incr, u.switch_mult)
	tentacle_update(state, data0, sound.accel, u.state.tentacle)
	stars_update(state, sound)
	if u.stop_lines & 0xf000 ~= 0 or not u.state.scope then
		local p1, p2, amplitude, _, mode = choose_line(state, true)
		switch_line(state.line1, mode, p1, amplitude, BLACK_LINE)
		switch_line(state.line2, mode, p2, amplitude, BLACK_LINE)
		u.stop_lines = u.stop_lines & 0x0fff
	end
	if u.line_mode ~= LINES then
		u.line_mode = math.max(0, u.line_mode - 1)
	elseif state.cycle % 80 == 0 and irand(5) == 0 and u.line_mode ~= 0 then
		u.line_mode = u.line_mode - 1
	end
	local function retarget()
		local p1, p2, amplitude, c1, mode = choose_line(state, u.stop_lines ~= 0)
		local c2 = 5 - c1
		if u.stop_lines ~= 0 then
			u.stop_lines = u.stop_lines - 1
			if irand(2) == 1 then
				c1, c2 = BLACK_LINE, BLACK_LINE
			end
		end
		switch_line(state.line1, mode, p1, amplitude, c1)
		switch_line(state.line2, mode, p2, amplitude, c2)
	end
	if state.cycle % 120 == 0 and irand(4) == 0 and u.state.scope then
		if u.line_mode == 0 then
			u.line_mode = LINES
		elseif u.line_mode == LINES then
			u.line_mode = u.line_mode - 1
			retarget()
		end
	end
	if u.line_mode ~= 0 or sound.since < 5 then
		state.line2.power = state.line1.power
		emit_line(state, state.line1, data0)
		emit_line(state, state.line2, data1)
		if state.cycle % 121 == 9 and irand(3) == 1 and (u.line_mode == 0 or u.line_mode == LINES) then
			retarget()
		end
	end
	state.cycle = state.cycle + 1
	local detection = 1.0 - sound.since / 20.0
	if detection > 0.8 then
		state.factor = state.factor + sound.power * 1.5
	end
	state.factor = state.factor * 0.96
	local brightness = (state.factor * 70.0 + 100.0) / 100.0
	scene.engine.set(scene, "flash", (brightness > 0.98 and brightness < 1.02) and 1.0 or brightness)
end

local function draw_polys(canvas, list)
	for _, item in ipairs(list or {}) do
		canvas:draw_polyline(item[1], item[2], 1.0)
	end
end

local function preset(name, w, h)
	return {
		name = name,
		size = { w, h },
		feedback = ZOOM,
		display = SHOW,
		params = { grid = Vector2(GX, GY) },
		setup = function(state, scene)
			state.w, state.h = w, h
			state.cycle, state.factor = 0, 0.0
			state.data0, state.data1 = {}, {}
			state.sound = {
				volume = 0.0, accel = 0.0, speed = 0.0, power = 0.0, limit = 1.0, big_limit = 1.0, max = 1, total = 0, prov = 0.0,
				since = 1, since_big = 1, cycle = 0,
			}
			state.u = {
				zf = { vitesse = 127, mx = 1, my = 1, reverse = false, mode = NORMAL, hplane = 0, vplane = 0, hypercos = false, noisify = 0 },
				state = STATES[7], lock = 0, goomvar = 0, loopvar = 0, stop_lines = 0, ifs_incr = 1, decay_ifs = 0, recay_ifs = 0,
				since_change = 0, line_mode = LINES, switch_incr = 0x7f, switch_mult = 1.0, selection = 0, blocker = 0, previous_speed = 128,
			}
			state.fs = { mode = 0, stars = {} }
			state.line1 = new_line(w, h, HLINE, h, BLACK_LINE, CIRCLE, 0.4 * h, 4)
			state.line2 = new_line(w, h, HLINE, 0, BLACK_LINE, CIRCLE, 0.2 * h, 1)
			tentacle_setup(state)
			ifs_setup(state)
			local z = {
				s = new_field(), d = new_field(), t = new_field(), start = -2, made = 0, ratio = 0,
				data = { speed = 0.0, mx = w // 2, my = h // 2, mode = AMULETTE, hplane = 0, vplane = 0, hypercos = false, noisy = true },
			}
			make_rows(state, z.d, z.data, 0, GY - 1)
			z.d.noise = 1.0
			for at, value in pairs(z.d.xs) do
				z.s.xs[at], z.s.ys[at] = value, z.d.ys[at]
			end
			z.s.noise = 1.0
			z.s_tex = ImageTexture.create_from_image(z.d.image)
			z.d_tex = ImageTexture.create_from_image(z.d.image)
			z.s.image:copy_from(z.d.image)
			state.zoom = z
			scene.engine.set(scene, "from_field", z.s_tex)
			scene.engine.set(scene, "to_field", z.d_tex)
			scene.engine.set(scene, "noise_from", 1.0)
			scene.engine.set(scene, "noise_to", 1.0)

			local adder = Control.new()
			adder.material = add_material()
			adder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			adder.draw:connect(function()
				draw_polys(adder, state.polys)
			end)
			scene.viewport:add_child(adder)
			state.adder = adder

			local fractal = Control.new()
			fractal.material = state.ifs_material
			fractal.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fractal.draw:connect(function()
				if state.show_ifs then
					fractal:draw_multimesh(state.ifs_mesh, nil)
				end
			end)
			scene.viewport:add_child(fractal)
			state.fractal_node = fractal

			local over = SubViewport.new()
			over.disable_3d = true
			over.transparent_bg = true
			over.size = Vector2i(w, h)
			over.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
			over.render_target_update_mode = SubViewport.UPDATE_ONCE
			local top = Control.new()
			top.material = add_material()
			top.mouse_filter = Control.MOUSE_FILTER_IGNORE
			top.draw:connect(function()
				draw_polys(top, state.bright)
				if state.star_points and #state.star_points > 0 then
					top:draw_multiline_colors(state.star_points, state.star_colors, 1.0)
				end
			end)
			over:add_child(top)
			scene.viewport:add_child(over)
			state.over, state.top = over, top
			scene.engine.set(scene, "overlay", over:get_texture())
		end,
		step = function(state, audio, scene)
			goom_update(state, audio, scene)
			state.adder:queue_redraw()
			state.fractal_node:queue_redraw()
			state.top:queue_redraw()
			state.over.render_target_update_mode = SubViewport.UPDATE_ONCE
		end,
		draw = function(canvas, state)
			for _, dot in ipairs(state.dots or {}) do
				local x, y, c = dot[1], dot[2], dot[3]
				canvas:draw_rect(Rect2(x + 1, y, 1, 3), c)
				canvas:draw_rect(Rect2(x, y + 1, 3, 1), c)
				canvas:draw_rect(Rect2(x + 1, y + 1, 1, 1), WHITE)
			end
		end,
	}
end

return {
	name = "WMP9 Goom",
	presets = {
		preset("Goom at 320x240", 320, 240),
		preset("Goom at 480x360", 480, 360),
		preset("Goom at 640x480", 640, 480),
		preset("Goom at 800x600", 800, 600),
	},
}

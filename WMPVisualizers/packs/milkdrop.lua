local lib = require("lib")

local WARP = "shaders/milkdrop/warp.gdshader"
local DISPLAY = "shaders/milkdrop/display.gdshader"
local MESH_X, MESH_Y = 24, 18
local COUNT = 192
local WAVE_POINTS = 256
local SHARED = { "time", "frame", "fps", "bass", "mid", "treb", "bass_att", "mid_att", "treb_att", "progress", "q1", "q2", "q3", "q4", "q5", "q6", "q7", "q8" }

local RESET = {
	"zoom", "rot", "warp", "cx", "cy", "dx", "dy", "sx", "sy", "decay", "wave_r", "wave_g", "wave_b", "wave_x", "wave_y",
	"wave_mystery", "ob_size", "ob_r", "ob_g", "ob_b", "ob_a", "ib_size", "ib_r", "ib_g", "ib_b", "ib_a", "wave_a",
	"fwavescale", "fwavealpha", "fvideoechoalpha", "fvideoechozoom", "fgammaadj",
}
local MOTION = { "zoom", "rot", "warp", "cx", "cy", "dx", "dy", "sx", "sy" }

local helpers = {}

local function number(value)
	if value == true then
		return 1
	elseif value == false or value == nil then
		return 0
	end
	return value
end

function helpers.truthy(value)
	return value == true or type(value) == "number" and value ~= 0
end

helpers.sin = function(a) return math.sin(number(a)) end
helpers.cos = function(a) return math.cos(number(a)) end
helpers.tan = function(a) return math.tan(number(a)) end
helpers.atan = function(a) return math.atan(number(a)) end
helpers.atan2 = function(a, b) return math.atan(number(a), number(b)) end
helpers.exp = function(a) return math.exp(number(a)) end
helpers.log = function(a) a = number(a) return a > 0 and math.log(a) or 0 end
helpers.log10 = function(a) a = number(a) return a > 0 and math.log(a, 10) or 0 end
helpers.abs = function(a) return math.abs(number(a)) end
helpers.int = function(a) a = number(a) return a == a and math.abs(a) < 1e300 and math.floor(a) or 0 end
helpers.round = function(a) return math.floor(number(a) + 0.5) end
helpers.sign = function(a) a = number(a) return a > 0 and 1 or (a < 0 and -1 or 0) end
helpers.sqrt = function(a) return math.sqrt(math.abs(number(a))) end
helpers.sq = function(a) a = number(a) return a * a end
helpers.pow = function(a, b) return number(a) ^ number(b) end
helpers.min = function(a, b) return math.min(number(a), number(b)) end
helpers.max = function(a, b) return math.max(number(a), number(b)) end
helpers.id = function(a) return number(a) end
helpers.asin = function(a) return math.asin(math.max(-1, math.min(1, number(a)))) end
helpers.acos = function(a) return math.acos(math.max(-1, math.min(1, number(a)))) end
helpers.sigmoid = function(a, b)
	local t = 1 + math.exp(-number(a) * number(b))
	return math.abs(t) > 0.00001 and 1 / t or 0
end
helpers.rnd = function(a) return math.random() * (a and math.abs(number(a)) > 1 and number(a) or 1) end
helpers.rand = function(a) a = math.max(1, math.floor(number(a))) return math.random(0, a - 1) end
helpers.iif = function(c, a, b) if helpers.truthy(c) then return number(a) end return number(b) end
helpers.above = function(a, b) return number(a) > number(b) and 1 or 0 end
helpers.below = function(a, b) return number(a) < number(b) and 1 or 0 end
helpers.equal = function(a, b) return math.abs(number(a) - number(b)) < 0.00001 and 1 or 0 end
helpers.bnot = function(a) return helpers.truthy(a) and 0 or 1 end
helpers.band = function(a, b) return helpers.truthy(a) and helpers.truthy(b) and 1 or 0 end
helpers.bor = function(a, b) return (helpers.truthy(a) or helpers.truthy(b)) and 1 or 0 end
local function whole(a)
	a = number(a)
	return (a == a and math.abs(a) < 2147483648) and math.floor(a) or 0
end
helpers.iand = function(a, b) return whole(a) & whole(b) end
helpers.ior = function(a, b) return whole(a) | whole(b) end
helpers.deg2rad = function(a) return number(a) * 0.0174533 end
helpers.rad2deg = function(a) return number(a) * 57.29578 end
helpers.pow2 = function(a, b) return number(a) ^ number(b) end
helpers.randf = function(a) return math.random() * number(a) end

local function compile(source, name)
	if not source or source:match("^%s*$") then
		return nil
	end
	local chunk = load("local v, f = ...\n" .. source, "=" .. name, "t", {})
	return chunk
end

local function run(chunk, vars)
	if not chunk then
		return true
	end
	return pcall(chunk, vars, helpers)
end

local function variables()
	return setmetatable({}, { __index = function() return 0 end })
end

local function analyze(state, audio)
	local function range(first, last)
		local total = 0
		for index = first, last do
			total = total + 10 ^ ((lib.band(audio, index) * 66 - 66) / 20)
		end
		return total
	end
	local levels = { bass = range(1, 6), mid = range(10, 18), treb = range(22, 30) }
	local early = state.count < 50
	for key, value in pairs(levels) do
		local average = state.attack[key] or value
		local rate = value > average and 0.2 or 0.5
		average = average * rate + value * (1 - rate)
		state.attack[key] = average
		local keep = early and 0.9 or 0.992
		local long = (state.long[key] or value) * keep + value * (1 - keep)
		state.long[key] = long
		local base = math.abs(long) < 0.0001 and 1 or long
		state.relative[key] = value / base
		state.smooth = state.smooth or {}
		state.smooth[key] = average / base
	end
end

local function write_mesh(state, vars)
	local frame = {}
	for _, key in ipairs(MOTION) do
		frame[key] = number(vars[key])
	end
	local time = number(vars.time)
	local warp_scale = number(vars.fwarpscale)
	local warp_on = number(vars.warp) > 0.001 and warp_scale > 0
	local wave_a, wave_b, phase_a, phase_b, turn_a, turn_b = 0, 0, 0, 0, 0, 0
	if warp_on then
		wave_a = 20 / warp_scale + math.sin(time * 1.25) * 2.5 / warp_scale
		wave_b = 20 / warp_scale + math.sin(time * 1.75) * 5 / warp_scale
		phase_a = time * 1.233 * number(vars.fwarpanimspeed) * 0.8
		phase_b = phase_a * 0.7
		turn_a, turn_b = math.sin(phase_a), math.sin(phase_b)
	end
	local exponent = number(vars.fzoomexponent) ~= 0 and number(vars.fzoomexponent) or 1
	for row = 0, MESH_Y do
		for column = 0, MESH_X do
			local u0, v0 = column / MESH_X, row / MESH_Y
			local dx0, dy0 = u0 - 0.5, v0 - 0.5
			local rad = math.sqrt(dx0 * dx0 + dy0 * dy0) * 2
			local motion = frame
			if state.pixel then
				for key, value in pairs(frame) do
					vars[key] = value
				end
				vars.x, vars.y, vars.rad, vars.ang = u0, v0, rad, math.atan(dy0, dx0)
				if not run(state.pixel, vars) then
					state.pixel = nil
				end
				motion = {}
				for _, key in ipairs(MOTION) do
					motion[key] = number(vars[key])
				end
			end
			local zoom = motion.zoom ~= 0 and motion.zoom or 1
			if exponent ~= 1 then
				zoom = math.abs(zoom) ^ (exponent ^ (rad * 2 - 1))
			end
			local inverse = 1 / (zoom ~= 0 and zoom or 1)
			local u = dx0 * inverse + 0.5
			local v = dy0 * inverse + 0.5
			local sx, sy = motion.sx ~= 0 and motion.sx or 1, motion.sy ~= 0 and motion.sy or 1
			local cx, cy = motion.cx, motion.cy
			u = (u - cx) / sx + cx
			v = (v - cy) / sy + cy
			if warp_on then
				local amount = motion.warp * 0.009
				local a = math.sin(u * wave_b * 0.1571 + turn_b + phase_a)
				local b = math.sin(u * wave_a * 0.1571 + turn_a + phase_b)
				local p = (b * 0.15 + 0.85) * wave_b * u
				local q = (a * 0.15 + 0.85) * wave_a * v
				local cross = math.cos(q + p)
				local other = math.sin(p - q)
				u = u - a * amount * cross
				v = v - b * amount * other
			end
			local du, dv = u - cx, v - cy
			local c, s = math.cos(motion.rot), math.sin(motion.rot)
			u = c * du - s * dv + cx - motion.dx
			v = s * du + c * dv + cy - motion.dy
			state.image:set_pixel(column, row, Color(u * 1.0, v * 1.0, 0.0, 1.0))
		end
	end
	state.texture:update(state.image)
end

local function clamp01(value)
	return math.max(0, math.min(1, value)) * 1.0
end

local function wave_color(vars, alpha)
	local r, g, b = number(vars.wave_r), number(vars.wave_g), number(vars.wave_b)
	if helpers.truthy(vars.bmaximizewavecolor) then
		local top = math.max(r, g, b, 0.0001)
		r, g, b = r / top, g / top, b / top
	end
	return Color(clamp01(r), clamp01(g), clamp01(b), clamp01(alpha))
end

local function samples(audio, smoothing)
	local left, right = {}, {}
	local mix = clamp01(smoothing) * 0.98
	local keep = 1 - mix
	local a, b
	for index = 0, COUNT + 32 do
		local t = index / (COUNT + 32)
		local x, y = lib.sample(audio, t), lib.sample(audio, (t + 0.13) % 1)
		a = a and a * mix + x * keep or x
		b = b and b * mix + y * keep or y
		left[index], right[index] = a, b
	end
	return left, right
end

local function wave_points(audio, state, scene, vars)
	local width, height = scene.width, scene.height
	local mode = math.floor(number(vars.nwavemode)) % 8
	local scale = number(vars.fwavescale) ~= 0 and number(vars.fwavescale) or 1
	local param = number(vars.wave_mystery)
	local wx, wy = number(vars.wave_x), number(vars.wave_y)
	local cx, cy = wx * width, (1 - wy) * height
	local left, right = samples(audio, vars.fwavesmoothing)
	local first, second = {}, nil
	if mode == 0 then
		local rx, ry = (2 * param + 1) * width * 0.24, (2 * param + 1) * height * 0.24
		local ax, ay = scale * width * 0.24 * 0.8, scale * height * 0.24 * 0.8
		for index = 0, COUNT - 1 do
			local angle = index * 6.28319 / COUNT + state.time * 0.333
			first[index + 1] = Vector2(cx + math.cos(angle) * (rx + ax * right[index]), cy - math.sin(angle) * (ry + ay * right[index]))
		end
		first[COUNT + 1] = first[1]
	elseif mode == 1 or mode == 2 or mode == 3 then
		for index = 0, COUNT - 1 do
			first[index + 1] = Vector2(cx + 0.25 * scale * width * right[index], cy - 0.25 * scale * height * left[index + 32])
		end
	elseif mode == 4 then
		local ax, ay = scale * width * 0.25 * 1.333, scale * height * 0.25 * 1.4133
		local shift = (wx - 0.5) * width
		for index = 0, COUNT - 1 do
			local x = index / COUNT * width + shift + ax * right[index]
			local y = cy - ay * left[index]
			if index > 1 then
				local p1, p2 = first[index], first[index - 1]
				x = x * 0.3 + (p1.x * 2 - p2.x) * 0.7
				y = y * 0.3 + (p1.y * 2 - p2.y) * 0.7
			end
			first[index + 1] = Vector2(x, y)
		end
	elseif mode == 5 then
		local turn = state.time * 0.31831
		local co, si = math.cos(turn), math.sin(turn)
		local rx, ry = scale * width * 0.5, scale * height * 0.5
		for index = 0, COUNT - 1 do
			local x0 = right[index] * left[index + 32] + left[index] * right[index + 32]
			local y0 = right[index] * right[index] - left[index + 32] * left[index + 32]
			first[index + 1] = Vector2(cx + (x0 * co - y0 * si) * rx, cy - (x0 * si + y0 * co) * ry)
		end
	else
		local angle = (param + 1) * 1.5708
		local co, si = math.cos(angle), math.sin(angle)
		local bend = co * -1.41421
		local amp = scale * width * 0.23
		local bx = ((wx - 0.5) * co - si * 1.41421 * 0.5 + 0.5) * width
		local by = (bend * 0.5 - (wx - 0.5) * si + 0.5) * height
		local gap = mode == 7 and wy * wy * height * 0.5 or 0
		if mode == 7 then
			second = {}
		end
		for index = 0, COUNT - 1 do
			local ox, oy = index * width * si * 1.41421 / COUNT, index * width * bend / COUNT
			local a = amp * left[index] + gap
			first[index + 1] = Vector2(a * co + ox + bx, by - (a * si + oy))
			if second then
				local b = amp * right[index] - gap
				second[index + 1] = Vector2(b * co + ox + bx, by - (b * si + oy))
			end
		end
	end
	return first, second, mode
end

local function stroke(canvas, points, color, dots, thick)
	if dots then
		local size = thick and 2 or 1
		for _, point in ipairs(points) do
			canvas:draw_rect(Rect2(point.x, point.y, size, size), color)
		end
	elseif #points > 1 then
		canvas:draw_polyline(points, color, thick and 2.0 or 1.0)
	end
end

local function draw_wave(canvas, state, audio, scene, vars)
	local alpha = number(vars.fwavealpha)
	if number(vars.wave_a) ~= 0 then
		alpha = number(vars.wave_a)
	end
	if helpers.truthy(vars.bmodwavealphabyvolume) then
		local start, finish = number(vars.fmodwavealphastart), number(vars.fmodwavealphaend)
		local volume = (state.relative.bass + state.relative.mid + state.relative.treb) / 3
		alpha = alpha * clamp01((volume - start) / math.max(finish - start, 0.01))
	end
	local first, second, mode = wave_points(audio, state, scene, vars)
	if mode == 2 or mode == 5 then
		alpha = alpha * 0.09
	elseif mode == 3 then
		alpha = alpha * state.relative.treb * state.relative.treb
	end
	local color = wave_color(vars, alpha)
	local dots, thick = helpers.truthy(vars.bwavedots), helpers.truthy(vars.bwavethick)
	if helpers.truthy(vars.bredbluestereo) then
		local shift = scene.width * 0.008
		local left_eye, right_eye = {}, {}
		for index, point in ipairs(first) do
			left_eye[index] = Vector2(point.x - shift, point.y)
			right_eye[index] = Vector2(point.x + shift, point.y)
		end
		local a = clamp01(alpha)
		stroke(canvas, left_eye, Color(1.0, 0.0, 0.0, a), dots, thick)
		stroke(canvas, right_eye, Color(0.0, 1.0, 1.0, a), dots, thick)
	elseif state.hue and not dots and #first > 1 then
		local count = #first
		local offset = (count - 1) * (1 + math.sin(state.time * 6.28319))
		local colors = {}
		for index = 1, count do
			local hued = lib.hsv(((offset + index - 1) % count) / count, 1.0, 1.0)
			colors[index] = Color(hued.r, hued.g, hued.b, clamp01(alpha))
		end
		canvas:draw_polyline_colors(first, colors, thick and 2.0 or 1.0)
	else
		stroke(canvas, first, color, dots, thick)
	end
	if second then
		stroke(canvas, second, color, dots, thick)
	end
end

local function custom_wave(canvas, state, audio, scene, vars, wave)
	local local_vars = wave.vars
	for _, key in ipairs(SHARED) do
		local_vars[key] = vars[key]
	end
	for key, value in pairs(wave.base) do
		local_vars[key] = value
	end
	if wave.frame then
		run(wave.frame, local_vars)
	end
	local count = math.min(math.floor(wave.spec.samples or 512), WAVE_POINTS)
	if count < 2 then
		return
	end
	local width, height = scene.width, scene.height
	local spectrum = (wave.spec.bspectrum or 0) ~= 0
	local scaling = wave.spec.scaling or 1
	local points, colors = {}, {}
	for index = 0, count - 1 do
		local t = index / (count - 1)
		local_vars.sample = t
		local value = spectrum and lib.spectrum(audio, t) or lib.sample(audio, t)
		local_vars.value1 = value * scaling
		local_vars.value2 = (spectrum and lib.spectrum(audio, (t + 0.05) % 1) or lib.sample(audio, (t + 0.13) % 1)) * scaling
		local_vars.x, local_vars.y = 0.5 + local_vars.value1 * 0.5, 0.5 + local_vars.value2 * 0.5
		local_vars.r, local_vars.g, local_vars.b, local_vars.a = wave.base.r or 1, wave.base.g or 1, wave.base.b or 1, wave.base.a or 1
		if wave.point and not run(wave.point, local_vars) then
			wave.point = nil
		end
		points[index + 1] = Vector2(number(local_vars.x) * width, (1 - number(local_vars.y)) * height)
		colors[index + 1] = Color(clamp01(number(local_vars.r)), clamp01(number(local_vars.g)), clamp01(number(local_vars.b)), clamp01(number(local_vars.a)))
	end
	if (wave.spec.busedots or 0) ~= 0 then
		for index, point in ipairs(points) do
			canvas:draw_rect(Rect2(point.x, point.y, 2, 2), colors[index])
		end
	else
		canvas:draw_polyline_colors(points, colors, (wave.spec.bdrawthick or 0) ~= 0 and 2.0 or 1.0)
	end
end

local function custom_shape(canvas, scene, vars, shape, state)
	local local_vars = shape.vars
	for _, key in ipairs(SHARED) do
		local_vars[key] = vars[key]
	end
	for key, value in pairs(shape.base) do
		local_vars[key] = value
	end
	if shape.frame and not run(shape.frame, local_vars) then
		shape.frame = nil
	end
	local sides = math.max(3, math.min(100, math.floor(number(local_vars.sides))))
	local width, height = scene.width, scene.height
	local rad, angle = number(local_vars.rad), number(local_vars.ang)
	local x, y = number(local_vars.x) * width, (1 - number(local_vars.y)) * height
	local rx, ry = rad * width * 0.5, rad * height * 0.5
	local a, a2 = clamp01(number(local_vars.a)), clamp01(number(local_vars.a2))
	local inner = Color(clamp01(number(local_vars.r)), clamp01(number(local_vars.g)), clamp01(number(local_vars.b)), a)
	local outer = Color(clamp01(number(local_vars.r2)), clamp01(number(local_vars.g2)), clamp01(number(local_vars.b2)), a2)
	local ring = {}
	for index = 0, sides do
		local turn = index / sides * 6.28319 + angle + 0.785398
		ring[index + 1] = Vector2(x + math.cos(turn) * rx, y - math.sin(turn) * ry)
	end
	if a > 0 or a2 > 0 then
		local center = Vector2(x, y)
		if number(local_vars.textured) ~= 0 and state.copy and state.count < 4 then
			return
		elseif number(local_vars.textured) ~= 0 and state.copy then
			local zoom = number(local_vars.tex_zoom) ~= 0 and number(local_vars.tex_zoom) or 1
			local tex_ang = number(local_vars.tex_ang)
			local middle = Vector2(0.5, 0.5)
			local image = state.copy:get_texture()
			for index = 1, sides do
				local t0 = (index - 1) / sides * 6.28319 + tex_ang + 0.785398
				local t1 = index / sides * 6.28319 + tex_ang + 0.785398
				canvas:draw_primitive({ center, ring[index], ring[index + 1] }, { inner, outer, outer }, {
					middle,
					Vector2(0.5 + 0.5 * math.cos(t0) / zoom, 0.5 - 0.5 * math.sin(t0) / zoom),
					Vector2(0.5 + 0.5 * math.cos(t1) / zoom, 0.5 - 0.5 * math.sin(t1) / zoom),
				}, image)
			end
		else
			for index = 1, sides do
				canvas:draw_polygon({ center, ring[index], ring[index + 1] }, { inner, outer, outer })
			end
		end
	end
	local border = clamp01(number(local_vars.border_a))
	if border > 0 then
		canvas:draw_polyline(ring, Color(clamp01(number(local_vars.border_r)), clamp01(number(local_vars.border_g)), clamp01(number(local_vars.border_b)), border), number(local_vars.thickoutline) ~= 0 and 2.0 or 1.0)
	end
end

local function custom_items(list, shared, name)
	local items = {}
	for index, spec in ipairs(list or {}) do
		local item = { spec = spec, vars = variables(), base = {} }
		for key, value in pairs(spec) do
			if type(value) == "number" then
				item.base[key] = value
			end
		end
		for _, key in ipairs(shared) do
			item.vars[key] = 0
		end
		if spec.init_code then
			for key, value in pairs(item.base) do
				item.vars[key] = value
			end
			run(compile(spec.init_code, name .. " init"), item.vars)
		end
		item.frame = compile(spec.frame_code, name .. " frame")
		item.point = compile(spec.point_code, name .. " point")
		items[index] = item
	end
	return items
end

local function draw_borders(canvas, scene, vars)
	local height = scene.height
	local outer = number(vars.ob_size) * height
	if outer > 0.5 and number(vars.ob_a) > 0 then
		canvas:draw_rect(Rect2(outer / 2, outer / 2, scene.width - outer, height - outer), Color(number(vars.ob_r) * 1.0, number(vars.ob_g) * 1.0, number(vars.ob_b) * 1.0, math.min(1, number(vars.ob_a)) * 1.0), false, outer)
	end
	local inner = number(vars.ib_size) * height
	if inner > 0.5 and number(vars.ib_a) > 0 then
		local offset = outer + inner / 2
		canvas:draw_rect(Rect2(offset, offset, scene.width - offset * 2, height - offset * 2), Color(number(vars.ib_r) * 1.0, number(vars.ib_g) * 1.0, number(vars.ib_b) * 1.0, math.min(1, number(vars.ib_a)) * 1.0), false, inner)
	end
end

local function draw_group(canvas, state, audio, scene, additive)
	for _, shape in ipairs(state.shapes) do
		if ((shape.spec.additive or 0) ~= 0) == additive then
			custom_shape(canvas, scene, state.vars, shape, state)
		end
	end
	for _, wave in ipairs(state.waves) do
		if ((wave.spec.badditive or 0) ~= 0) == additive then
			custom_wave(canvas, state, audio, scene, state.vars, wave)
		end
	end
end

local milkdrop = {}

function milkdrop.make(name, load_entry)
	return {
		name = name,
		feedback = WARP,
		display = DISPLAY,
		setup = function(state, scene)
			local entry = load_entry()
			state.add_wave = (entry.init or ""):match("v%.badditivewaves = 1") ~= nil
			state.hue = entry.hue
			state.vars = variables()
			state.long, state.relative, state.attack = {}, {}, {}
			state.count = 0
			state.vars.zoom, state.vars.sx, state.vars.sy, state.vars.cx, state.vars.cy = 1, 1, 1, 0.5, 0.5
			state.vars.fdecay, state.vars.fwavealpha, state.vars.fwavescale, state.vars.fgammaadj = 0.98, 0.8, 1, 1
			state.vars.wave_r, state.vars.wave_g, state.vars.wave_b, state.vars.wave_x, state.vars.wave_y = 1, 1, 1, 0.5, 0.5
			run(compile(entry.init, entry.name .. " init"), state.vars)
			state.vars.decay = number(state.vars.fdecay) ~= 0 and state.vars.fdecay or state.vars.decay
			if number(state.vars.wave_a) == 0 then
				state.vars.wave_a = state.vars.fwavealpha
			end
			if number(state.vars.wave_mystery) == 0 then
				state.vars.wave_mystery = state.vars.fwaveparam
			end
			state.base = {}
			for _, key in ipairs(RESET) do
				state.base[key] = rawget(state.vars, key)
			end
			state.waves = custom_items(entry.waves, SHARED, entry.name .. " wave")
			state.shapes = custom_items(entry.shapes, SHARED, entry.name .. " shape")
			state.frame = compile(entry.frame, entry.name .. " frame")
			state.pixel = compile(entry.pixel, entry.name .. " pixel")
			local textured, additive = false, state.add_wave
			for _, shape in ipairs(state.shapes) do
				textured = textured or (shape.spec.textured or 0) ~= 0
				additive = additive or (shape.spec.additive or 0) ~= 0
			end
			for _, wave in ipairs(state.waves) do
				additive = additive or (wave.spec.badditive or 0) ~= 0
			end
			if textured then
				state.copy = SubViewport.new()
				state.copy.disable_3d = true
				state.copy.render_target_update_mode = SubViewport.UPDATE_ALWAYS
				state.copy.size = Vector2i(scene.width, scene.height)
				local picture = TextureRect.new()
				picture.texture = scene.viewport:get_texture()
				picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				picture.size = Vector2(scene.width, scene.height)
				state.copy:add_child(picture)
				state.picture = picture
				scene.viewport:add_child(state.copy)
			end
			if additive then
				local adder = Control.new()
				local blend = CanvasItemMaterial.new()
				blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
				adder.material = blend
				adder.mouse_filter = Control.MOUSE_FILTER_IGNORE
				scene.viewport:add_child(adder)
				state.adder = adder
				adder.draw:connect(function()
					if scene.audio then
						draw_group(adder, state, scene.audio, scene, true)
						if state.add_wave then
							draw_wave(adder, state, scene.audio, scene, state.vars)
						end
					end
				end)
			end
			state.image = Image.create(MESH_X + 1, MESH_Y + 1, false, Image.FORMAT_RGF)
			state.texture = ImageTexture.create_from_image(state.image)
			state.aspect = 16 / 9
			state.time = 0
			local vars = state.vars
			scene.engine.set(scene, "mesh", state.texture)
			scene.engine.set(scene, "mesh_size", Vector2(MESH_X + 1, MESH_Y + 1))
			scene.engine.set(scene, "wrap", helpers.truthy(vars.btexwrap))
			scene.engine.set(scene, "darken_center", helpers.truthy(vars.bdarkencenter))
			scene.engine.set(scene, "brighten", helpers.truthy(vars.bbrighten))
			scene.engine.set(scene, "darken", helpers.truthy(vars.bdarken))
			scene.engine.set(scene, "solarize", helpers.truthy(vars.bsolarize))
			scene.engine.set(scene, "invert", helpers.truthy(vars.binvert))
			scene.engine.set(scene, "echo_orientation", math.floor(number(vars.nvideoechoorientation)))
		end,
		step = function(state, audio, scene)
			local vars = state.vars
			if scene.width then
				state.aspect = scene.width / scene.height
			end
			analyze(state, audio)
			state.time = state.time + 1 / 30
			state.count = state.count + 1
			for key, value in pairs(state.base) do
				vars[key] = value
			end
			vars.time, vars.frame, vars.fps = state.time, state.count, 30
			vars.bass, vars.mid, vars.treb = state.relative.bass, state.relative.mid, state.relative.treb
			vars.bass_att, vars.mid_att, vars.treb_att = state.smooth.bass, state.smooth.mid, state.smooth.treb
			vars.progress = audio.progress or 0
			if not run(state.frame, vars) then
				state.frame = nil
			end
			write_mesh(state, vars)
			scene.engine.set(scene, "decay", math.max(0, math.min(1, number(vars.decay))) * 1.0)
			scene.engine.set(scene, "gamma", math.max(1, number(vars.fgammaadj)) * 1.0)
			scene.engine.set(scene, "echo_alpha", number(vars.fvideoechoalpha) * 1.0)
			scene.engine.set(scene, "echo_zoom", (number(vars.fvideoechozoom) ~= 0 and number(vars.fvideoechozoom) or 1) * 1.0)
			if state.adder then
				state.adder.size = Vector2(scene.width, scene.height)
				state.adder:queue_redraw()
			end
			if state.copy and state.copy.size.x ~= scene.width then
				state.copy.size = Vector2i(scene.width, scene.height)
				state.picture.size = Vector2(scene.width, scene.height)
			end
		end,
		draw = function(canvas, state, audio, scene)
			draw_group(canvas, state, audio, scene, false)
			if not state.add_wave then
				draw_wave(canvas, state, audio, scene, state.vars)
			end
			draw_borders(canvas, scene, state.vars)
		end,
	}
end

return milkdrop

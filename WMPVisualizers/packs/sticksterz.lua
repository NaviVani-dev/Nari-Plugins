local crayon_texture

local HALF_PI = math.pi / 2
local LINKS = { { 6, 5 }, { 5, 4 }, { 4, 0 }, { 0, 1 }, { 1, 2 }, { 2, 3 }, { 0, 7 }, { 7, 8 }, { 8, 0 }, { 7, 9 }, { 9, 10 }, { 8, 11 }, { 11, 12 }, { 13, 14 }, { 14, 15 }, { 15, 13 } }
local FLOOR = { { 400.0, 400.0, 0.0 }, { -400.0, 400.0, 0.0 }, { -400.0, -400.0, 0.0 }, { 400.0, -400.0, 0.0 } }

local function shape(body, kind)
	if kind == 1 then
		body.size = { 125.0, 35.0, 25.0, 125.0, 70.0, 100.0, 75.0 }
	else
		body.size = { 125.0, 35.0, 75.0, 75.0, 60.0, 100.0, 75.0 }
	end
end

local function new_body(kind)
	local body = { pos = {}, vel = {}, spring = {}, damp = {}, target = {}, height = 300.0, rise = 0.0, gravity = 5.0, points = {} }
	for index = 1, 9 do
		body.pos[index], body.vel[index], body.spring[index], body.damp[index], body.target[index] = 0.25, 0.0, 0.1, 0.1, 0.5
	end
	for index = 1, 16 do
		body.points[index] = { 0.0, 0.0, 0.0 }
	end
	shape(body, kind)
	return body
end

local function dance(body, step)
	local spring, target = body.spring, body.target
	local random = math.random
	if step == 2 then
		for index = 1, 9 do
			spring[index] = 0.1
		end
		spring[1] = 0.3
		target[1] = random()
		spring[2] = 0.3
		target[2] = random()
		target[3], target[4], target[5], target[6], target[7] = 0.5, 0.0, 0.0, 0.0, 0.0
		target[8], target[9] = random(), random()
		return
	end
	for index = 1, 9 do
		if step ~= 4 or random(0, 1) == 1 then
			target[index] = random()
		end
		spring[index] = 0.1
	end
	if step == 1 or step == 3 then
		target[1] = target[2]
	end
	if step == 3 then
		target[4] = target[5]
		target[6] = target[7]
	end
end

local function set(point, x, y, z)
	point[1], point[2], point[3] = x, y, z
end

local function animate(body, x, y, z)
	local pos, vel, spring, damp, target = body.pos, body.vel, body.spring, body.damp, body.target
	for index = 1, 9 do
		vel[index] = (target[index] - pos[index]) * spring[index] - damp[index] * vel[index] + vel[index]
		pos[index] = math.max(0.0, math.min(1.0, vel[index] + pos[index]))
	end
	local size = body.size
	local want = (math.max(pos[1], pos[2]) + 1.0) * size[1] + size[3]
	if want < body.height then
		body.rise = body.rise - body.gravity
		body.height = body.height + body.rise
	end
	if body.height < want then
		body.rise = math.min(want - body.height, 50.0)
		body.height = want
	end
	local p = body.points
	local cos, sin, sqrt = math.cos, math.sin, math.sqrt
	local pz = z + body.height
	set(p[1], x, y, pz)
	local a = (pos[9] - 0.5) * HALF_PI + math.pi
	local ca, sa = cos(a), sin(a)
	local hz = pz - size[3]
	set(p[2], ca * size[2] + x, sa * size[2] + y, hz)
	set(p[5], x - ca * size[2], y - sa * size[2], hz)
	local foot_a = hz - (pos[2] + 1.0) * size[1]
	local foot_b = hz - (pos[1] + 1.0) * size[1]
	set(p[4], p[2][1], p[2][2], foot_a)
	set(p[7], p[5][1], p[5][2], foot_b)
	local half = (pos[2] + 1.0) * size[1] * 0.5
	local knee = sqrt(math.max(0.0, size[1] * size[1] - half * half))
	set(p[3], p[2][1] + knee * sa, p[2][2] - knee * ca, (hz + foot_a) * 0.5)
	half = (pos[1] + 1.0) * size[1] * 0.5
	knee = sqrt(math.max(0.0, size[1] * size[1] - half * half))
	set(p[6], p[5][1] + knee * sa, p[5][2] - knee * ca, (hz + foot_b) * 0.5)
	local t = (pos[3] - 0.5) * HALF_PI
	local ct, st = cos(t), sin(t)
	local fx = ca * ct - sa * st
	local fy = sa * ct + ca * st
	local gx = -fy
	local cz = size[4] + pz
	set(p[14], x, y, cz)
	set(p[9], fx * size[5] + x, fy * size[5] + y, cz)
	set(p[8], x - fx * size[5], y - fy * size[5], cz)
	local u, w = sin(pos[4] * HALF_PI), cos(pos[4] * HALF_PI)
	local bx, by, bz = -(fx * u) * size[6] + p[8][1], -(fy * u) * size[6] + p[8][2], -w * size[6] + cz
	set(p[10], bx, by, bz)
	local cp, sp = cos(pos[6] * HALF_PI), sin(pos[6] * HALF_PI)
	set(p[11], (-(fx * u) * cp - gx * sp) * size[6] + bx, (-(fy * u) * cp - fx * sp) * size[6] + by, -w * cp * size[6] + bz)
	u, w = sin(pos[5] * HALF_PI), cos(pos[5] * HALF_PI)
	local ex, ey, ez = fx * u * size[6] + p[9][1], fy * u * size[6] + p[9][2], -w * size[6] + cz
	set(p[12], ex, ey, ez)
	cp, sp = cos(pos[7] * HALF_PI), sin(pos[7] * HALF_PI)
	set(p[13], (fx * u * cp - gx * sp) * size[6] + ex, (fy * u * cp - fx * sp) * size[6] + ey, -w * cp * size[6] + ez)
	local h = sin(pos[8] * HALF_PI * 0.5)
	local hx, hy = -(gx * h), -(fx * h)
	local hc = cos(pos[8] * HALF_PI * 0.5) * size[7] + cz
	set(p[15], (fx * 0.3 + hx) * size[7] + x, (fy * 0.3 + hy) * size[7] + y, hc)
	set(p[16], (hx - fx * 0.3) * size[7] + x, (hy - fy * 0.3) * size[7] + y, hc)
end

local function look(state)
	local t = state.camera
	local ex = math.cos(t * 0.08 + state.phase[1]) * 700.0
	local ey = math.cos(t * 0.06 + state.phase[2]) * 700.0
	local ez = math.cos(t * 0.04 + state.phase[3]) * 300.0 + 600.0
	state.camera = t + 0.3
	if state.camera > 100.0 then
		state.camera = 0.0
		for index = 1, 3 do
			state.phase[index] = math.random() * math.pi * 2
		end
	end
	local fx, fy, fz = -ex, -ey, 200.0 - ez
	local scale = 1.0 / math.sqrt(fx * fx + fy * fy + fz * fz)
	fx, fy, fz = fx * scale, fy * scale, fz * scale
	local rx, ry = fy, -fx
	scale = 1.0 / math.sqrt(rx * rx + ry * ry)
	rx, ry = rx * scale, ry * scale
	state.view = { ex, ey, ez, fx, fy, fz, rx, ry, fz * ry - 0.0 * fy, 0.0 * fx - fz * rx, rx * fy - fx * ry }
end

local function project(view, width, height, x, y, z)
	local dx, dy, dz = x - view[1], y - view[2], z - view[3]
	local depth = dx * view[4] + dy * view[5] + dz * view[6]
	if depth < height then
		return nil
	end
	local k = height / depth
	return Vector2(math.floor(k * (dx * view[7] + dy * view[8])) + width // 2, height // 2 - math.floor(k * (dx * view[9] + dy * view[10] + dz * view[11])))
end

local function stroke(canvas, state, a, b, color, unit)
	if not a or not b then
		return
	end
	if not state.crayon then
		canvas:draw_line(a, b, color, math.max(1.0, unit))
		return
	end
	local dx, dy = b.x - a.x, b.y - a.y
	local length = math.sqrt(dx * dx + dy * dy)
	if length < 1 then
		return
	end
	canvas:draw_set_transform(a, math.atan(dy, dx), Vector2(unit, unit))
	canvas:draw_texture_rect_region(crayon_texture, Rect2(0.0, -2.0, length / unit, 4.0), Rect2(math.random(0, 255), 0.0, length / unit, 4.0), color)
	canvas:draw_set_transform(Vector2(0.0, 0.0), 0.0, Vector2(1.0, 1.0))
end

local function draw_body(canvas, state, scene, body, color, unit)
	local view = state.view
	local width, height = scene.width, scene.height
	local points = {}
	for index, point in ipairs(body.points) do
		points[index] = project(view, width, height, point[1], point[2], point[3])
	end
	for _, link in ipairs(LINKS) do
		stroke(canvas, state, points[link[1] + 1], points[link[2] + 1], color, unit)
	end
end

local function palette(state)
	local random = math.random
	state.paper = Color(random(160, 254) / 255.0, random(160, 254) / 255.0, random(160, 254) / 255.0, 1.0)
	state.ink_a = Color(random(0, 127) / 255.0, random(0, 127) / 255.0, random(0, 127) / 255.0, 1.0)
	state.ink_b = Color(random(0, 127) / 255.0, random(0, 127) / 255.0, random(0, 127) / 255.0, 1.0)
end

local function detect(state, value)
	state.mean = value * 0.1 + 0.9 * state.mean
	state.low = math.min(state.low, value) * 0.999 + value * 0.001
	state.high = math.max(state.high, value) * 0.999 + value * 0.001
	local hit = false
	if state.armed and value - state.mean > (state.high - state.low) * 0.05 then
		hit = true
		state.armed = false
	end
	if not state.armed and state.mean > value then
		state.armed = true
	end
	return hit
end

local function collapse(state)
	for _, body in ipairs({ state.a, state.b }) do
		local size = body.size
		for index = 1, 7 do
			size[index] = size[index] * (index == 4 and 1.2 or 0.7)
		end
	end
end

local function swap(state)
	state.count = 3 - state.count
	state.step = (state.step + 1) % 5
	shape(state.a, 1)
	shape(state.b, 2)
	state.a.height = 1000.0
	if state.count == 2 then
		state.b.height = 1000.0
		state.a_at, state.b_at = 200.0, -200.0
	else
		state.a_at, state.b_at = 0.0, 0.0
	end
	for _, body in ipairs({ state.a, state.b }) do
		local size = body.size
		size[4] = size[7] + size[3] + size[4] + size[1]
		size[1], size[2], size[3], size[5], size[6], size[7] = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
	end
	palette(state)
end

local function stickster(name, crayon)
	return {
		name = name,
		setup = function(state, scene)
			crayon_texture = crayon_texture or nari.load("assets/sticksterz/crayon.png")
			scene.canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			scene.canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			state.crayon = crayon
			state.a, state.b = new_body(1), new_body(2)
			state.a_at, state.b_at = 200.0, -200.0
			state.count, state.step, state.timer = 2, 0, 100
			state.camera = 0.0
			state.phase = { math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2 }
			state.mean, state.low, state.high, state.armed = 0.0, 1.0, 0.0, false
			palette(state)
		end,
		step = function(state, audio)
			local timer = state.timer - 1
			if state.timer < 1 then
				if timer > -10 then
					collapse(state)
				elseif timer == -10 then
					swap(state)
				elseif state.a.height <= 0.0 then
					shape(state.a, state.count == 2 and 1 or math.random(1, 2))
					shape(state.b, 2)
					timer = math.random(0, 600)
				end
			end
			state.timer = timer
			if detect(state, audio.level or 0.0) then
				dance(state.a, state.step)
				for index = 1, 9 do
					state.b.target[index], state.b.spring[index] = state.a.target[index], state.a.spring[index]
				end
			end
			look(state)
			animate(state.a, state.a_at, state.a_at, 0.0)
			if state.count == 2 then
				animate(state.b, state.b_at, state.b_at, 0.0)
			end
		end,
		draw = function(canvas, state, _, scene)
			if not state.view then
				return
			end
			canvas:draw_rect(Rect2(0, 0, scene.width, scene.height), state.paper)
			local unit = scene.height / 480.0
			local gray = Color(0.502, 0.502, 0.502, 1.0)
			local view = state.view
			local corners = {}
			for index, point in ipairs(FLOOR) do
				corners[index] = project(view, scene.width, scene.height, point[1], point[2], point[3])
			end
			for index = 1, 4 do
				stroke(canvas, state, corners[index], corners[index % 4 + 1], gray, unit)
			end
			if state.count == 2 then
				draw_body(canvas, state, scene, state.b, state.ink_b, unit)
			end
			draw_body(canvas, state, scene, state.a, state.ink_a, unit)
		end,
	}
end

return {
	name = "SticksterZ",
	light = true,
	presets = {
		stickster("SticksterZ - Lines", false),
		stickster("SticksterZ - Crayon", true),
	},
}

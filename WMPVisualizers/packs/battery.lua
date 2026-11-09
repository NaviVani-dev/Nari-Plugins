local lib = require("lib")
local bins = require("packs.wmp_bins")
local data = require("packs.battery_presets")

local FEEDBACK = "shaders/battery/feedback.gdshader"
local BLUR = "shaders/battery/blur.gdshader"
local PALETTE = "shaders/battery/palette.gdshader"
local WIDTH, HEIGHT = 384, 288
local CX, CY = WIDTH // 2, HEIGHT // 2
local TAU = 6.2831855
local MAX_DOTS = 2600

local SHIFTS = {
	LinearShift = 1,
	ThingusShift = 2,
	ZoomShift = 3,
	RingSpinShift = 4,
	StretchShift = 5,
	TileShift = 6,
	TrigShift = 7,
	SinShimmerShift = 8,
	EdgeFalloffShift = 9,
	StarburstShift = 10,
	SwirlShift = 11,
	Twirlocity = 12,
	Shiitake = 13,
	TrigStretchShift = 14,
}

local floor, sin, cos, atan, sqrt, random = math.floor, math.sin, math.cos, math.atan, math.sqrt, math.random

local function ftol(value)
	return value >= 0 and floor(value) or -floor(-value)
end

local shades = {}
for index = 0, 255 do
	shades[index] = Color(index / 255, 0.0, 0.0, 1.0)
end

local function shade(value)
	return shades[floor(value) % 256]
end

local function rand(limit)
	return random(0, limit - 1)
end

local function unit()
	return random()
end

local function texture_from(colors)
	local image = Image.create(256, 1, false, Image.FORMAT_RGB8)
	for index = 0, 255 do
		image:set_pixel(index, 0, colors[index + 1])
	end
	return ImageTexture.create_from_image(image)
end

local function decode(hex)
	local colors = {}
	for index = 0, 255 do
		local offset = index * 6 + 1
		colors[index + 1] = Color("#" .. hex:sub(offset, offset + 5))
	end
	return colors
end

local function random_colors()
	local count = rand(rand(10) == 0 and 10 or 4) + 2
	local descending = rand(10) == 0
	local stops = {}
	stops[1] = Color(rand(32) / 255, rand(32) / 255, rand(32) / 255, 1.0)
	stops[2] = Color((255 - rand(32)) / 255, (255 - rand(32)) / 255, (255 - rand(32)) / 255, 1.0)
	for index = 3, count do
		stops[index] = Color(rand(256) / 255, rand(256) / 255, rand(256) / 255, 1.0)
	end
	table.sort(stops, function(a, b)
		if descending then
			return a.r + a.g + a.b > b.r + b.g + b.b
		end
		return a.r + a.g + a.b < b.r + b.g + b.b
	end)
	local colors = {}
	local span = 256 // (count - 1)
	for slot = 0, count - 2 do
		local first, last = slot * span, slot == count - 2 and 255 or (slot + 1) * span
		local a, b = stops[slot + 1], stops[slot + 2]
		for index = first, last do
			local t = (index - first) / math.max(last - first, 1)
			colors[index + 1] = Color(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1.0)
		end
	end
	return colors
end

local function outline(canvas, value)
	local color = shade(value)
	canvas:draw_rect(Rect2(0, 0, WIDTH, 1), color)
	canvas:draw_rect(Rect2(0, HEIGHT - 1, WIDTH, 1), color)
	canvas:draw_rect(Rect2(0, 0, 1, HEIGHT), color)
	canvas:draw_rect(Rect2(WIDTH - 1, 0, 1, HEIGHT), color)
end

local function bass_sum(audio)
	local total = 0
	for bin = 0, 4, 2 do
		total = total + bins.frequency(audio, bin) * 2
	end
	return total
end

local function plot(canvas, points, count, color)
	if count > 0 then
		canvas:draw_multiline(points, color)
	end
end

local effects = {}

effects.EdgeTrace = {
	mask = 1,
	randomize = function(p)
		p[1] = rand(30) + 35
	end,
	draw = function(canvas, _, s, p)
		local step = math.max(1, ftol(p[1]))
		local at = math.max((s.at or 0) + 1, 0) % step + 3
		s.at = at
		local bright, soft = shades[255], shades[245]
		local function run(limit, place)
			while at < limit - 4 do
				place(at)
				at = at + step
			end
			at = at - limit
			if at < 3 then
				at = at + step
			end
		end
		run(WIDTH, function(x)
			canvas:draw_rect(Rect2(x - 3, 0, 4, 1), soft)
			canvas:draw_rect(Rect2(x - 2, 0, 2, 1), bright)
			canvas:draw_rect(Rect2(x - 2, 1, 2, 1), soft)
		end)
		run(HEIGHT, function(y)
			canvas:draw_rect(Rect2(WIDTH - 1, y - 3, 1, 4), soft)
			canvas:draw_rect(Rect2(WIDTH - 1, y - 2, 1, 2), bright)
			canvas:draw_rect(Rect2(WIDTH - 2, y - 2, 1, 2), soft)
		end)
		run(WIDTH, function(x)
			canvas:draw_rect(Rect2(WIDTH - 1 - x, HEIGHT - 1, 4, 1), soft)
			canvas:draw_rect(Rect2(WIDTH - x, HEIGHT - 1, 2, 1), bright)
			canvas:draw_rect(Rect2(WIDTH - x, HEIGHT - 2, 2, 1), soft)
		end)
		while at < HEIGHT - 4 do
			canvas:draw_rect(Rect2(0, HEIGHT - at - 3, 1, 4), soft)
			canvas:draw_rect(Rect2(0, HEIGHT - at - 2, 1, 2), bright)
			canvas:draw_rect(Rect2(1, HEIGHT - at - 2, 1, 2), soft)
			at = at + step
		end
	end,
}

effects.EdgeGradiant = {
	mask = 1,
	randomize = function() end,
	draw = function(canvas, _, s)
		s.value = s.value or 0
		s.step = s.step or 1
		if s.value < 0 or s.value > 255 then
			s.step = -s.step
		end
		s.value = s.value + s.step
		outline(canvas, s.value)
	end,
}

effects.CosEdgeGradiant = {
	mask = 1,
	randomize = function(p)
		p[1] = unit() * 0.09
	end,
	draw = function(canvas, _, s, p)
		s.phase = (s.phase or 0) + p[1]
		if s.phase > TAU then
			s.phase = 0
		end
		outline(canvas, ftol(cos(s.phase) * 253 + 1))
	end,
}

effects.WaveEdge = {
	mask = 1,
	randomize = function(p)
		p[1] = rand(2)
	end,
	draw = function(canvas, audio, _, p)
		local spectrum = p[1] ~= 0
		local function value(index)
			if spectrum then
				return bins.frequency(audio, index % 1024)
			end
			return bins.wave(audio, index % 1024)
		end
		local top, bottom, top_colors = {}, {}, {}
		for x = 0, WIDTH - 1, 6 do
			top[#top + 1] = Vector2(x + 0.5, 0.5)
			bottom[#bottom + 1] = Vector2(x + 0.5, HEIGHT - 0.5)
			top_colors[#top_colors + 1] = shade(value(x))
		end
		canvas:draw_polyline_colors(top, top_colors)
		canvas:draw_polyline_colors(bottom, top_colors)
		local left, right, side_colors = {}, {}, {}
		for y = 0, HEIGHT - 1, 6 do
			left[#left + 1] = Vector2(0.5, y + 0.5)
			right[#right + 1] = Vector2(WIDTH - 0.5, y + 0.5)
			side_colors[#side_colors + 1] = shade(value(y))
		end
		canvas:draw_polyline_colors(left, side_colors)
		canvas:draw_polyline_colors(right, side_colors)
	end,
}

effects.SpectrumEdge = {
	mask = 1,
	randomize = function(p)
		p[1] = rand(10)
		p[2] = rand(10) * 2 + 2
		p[3] = rand(11) + 4
	end,
	draw = function(canvas, audio, s, p)
		local history = ftol(p[3])
		local span = ftol(p[2])
		if p[2] == 0 or p[3] <= 0 or history >= 16 or span >= 1023 then
			return
		end
		s.values = s.values or {}
		s.slot = ((s.slot or 0) + 1) % history
		local sum = 0
		for bin = 0, span - 1, 2 do
			sum = sum + bins.frequency(audio, bin) * 2
		end
		s.values[s.slot] = sum
		local total = 0
		for index = 0, history - 1 do
			total = total + (s.values[index] or 0)
		end
		local value = ftol(total / (p[3] * p[2]))
		if p[1] == 0 then
			value = 255 - value
		elseif p[1] > 5 then
			value = ftol(value * 0.9)
		end
		outline(canvas, value)
	end,
}

effects.CircleWaveform = {
	mask = 2,
	randomize = function(p)
		p[1] = rand(4)
		p[2] = 3 - (rand(5) ~= 0 and 1 or 0) - (rand(5) ~= 0 and 1 or 0)
		p[3] = unit() * 0.6 + 0.05
	end,
	draw = function(canvas, audio, s, p)
		local mode, circles = ftol(p[1]), ftol(p[2])
		local base = ftol(bins.frequency(audio, 0) / 256 * CY)
		local total = ftol(math.min(p[3], 1) * 1024)
		local step = math.max(1, total // 96)
		s.spin = s.spin or 0
		for circle = 0, circles - 1 do
			local x, y = CX, CY
			if circles > 1 then
				local angle = TAU / p[2] * circle + s.spin
				x = x + ftol(cos(angle) * (WIDTH >> 3))
				y = y + ftol(sin(angle) * (WIDTH >> 3))
			end
			local upper, lower, colors, lower_colors = {}, {}, {}, {}
			for index = 0, total - 1, step do
				local t = index / total
				local wave = bins.wave(audio, index)
				local other = bins.wave(audio, (index + 37) % 1024)
				local radius = wave / 256 * base + 20
				local radius2 = other / 256 * base + 20
				local angle = t * 3.1415927
				local c, n = cos(angle), sin(angle)
				upper[#upper + 1] = Vector2(x + ftol(radius * c) + 0.5, y + ftol(radius * n) + 0.5)
				lower[#lower + 1] = Vector2(x + ftol(radius2 * c) + 0.5, y - ftol(radius2 * n) + 0.5)
				local first, second = 255, 255
				if mode == 0 then
					first, second = math.abs(wave - 128) * 2, math.abs(other - 128) * 2
				elseif mode == 1 then
					first, second = wave, other
				elseif mode == 3 then
					local value = ftol(t * 768)
					first = (value // 256) % 2 ~= 0 and 255 - value % 256 or value % 256
					second = first
				end
				colors[#colors + 1] = shade(first)
				lower_colors[#lower_colors + 1] = shade(second)
			end
			if #upper > 1 then
				canvas:draw_polyline_colors(upper, colors)
				canvas:draw_polyline_colors(lower, lower_colors)
			end
		end
		s.spin = s.spin + 0.049087387
	end,
}

local function bounce(ball, scale)
	ball.fx = ball.fx + scale * ball.vx
	ball.fy = ball.fy + scale * ball.vy
	ball.x, ball.y = ftol(ball.fx), ftol(ball.fy)
	if (ball.x + 40 >= ball.right and ball.vx > 0) or (ball.x <= ball.left and ball.vx < 0) then
		ball.vx = -ball.vx
	end
	if (ball.y <= ball.top and ball.vy < 0) or (ball.y + 40 >= ball.bottom and ball.vy > 0) then
		ball.vy = -ball.vy
	end
end

local function new_ball(x, y, vx, vy)
	return { x = x, y = y, fx = x, fy = y, vx = vx, vy = vy, left = 0, top = 0, right = 512, bottom = 352 }
end

local function angle_of(y, x)
	local angle = x == 0 and 0 or atan(y, x)
	return angle < 0 and angle + TAU or angle
end

local function arc_setup(x0, y0, x1, y1, cx, cy)
	local a0 = angle_of(y0 - cy, x0 - cx)
	local a1 = angle_of(y1 - cy, x1 - cx)
	local delta = a1 - a0
	if delta >= 3.1415927 then
		delta = -(TAU - delta)
	end
	local r0 = sqrt((x0 - cx) ^ 2 + (y0 - cy) ^ 2)
	local r1 = sqrt((x1 - cx) ^ 2 + (y1 - cy) ^ 2)
	return a0, delta, r0, r1
end

local function arc_line(points, colors, x0, y0, x1, y1, cx, cy, hue, top, segments)
	local a0, delta, r0, r1 = arc_setup(x0, y0, x1, y1, cx, cy)
	for step = 0, segments - 1 do
		local t = step / segments
		local radius = r0 + (r1 - r0) * sin(t * 1.5707963)
		local angle = a0 + delta * t
		points[#points + 1] = Vector2(cx + ftol(cos(angle) * radius) + 0.5, cy + ftol(sin(angle) * radius) + 0.5)
		colors[#colors + 1] = shades[floor(hue + (top - hue) * t) % 256]
	end
end

local function arc_dots(points, colors, x0, y0, x1, y1, cx, cy, hue, top, segments)
	local a0, delta, r0, r1 = arc_setup(x0, y0, x1, y1, cx, cy)
	for step = 0, segments - 1 do
		local t = step / segments
		local radius = r0 + (r1 - r0) * sin(t * 1.5707963)
		local angle = a0 + delta * t
		local x, y = cx + ftol(cos(angle) * radius), cy + ftol(sin(angle) * radius)
		if x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT then
			local color = shades[floor(hue + (top - hue) * t) % 256]
			points[#points + 1] = Vector2(x, y + 0.5)
			points[#points + 1] = Vector2(x + 1, y + 0.5)
			colors[#colors + 1] = color
		end
	end
end

effects.JDar = {
	mask = 2,
	randomize = function(p)
		p[1] = rand(100) + 5
		p[2] = rand(4)
		p[3] = rand(2)
		p[4] = 2 ^ (rand(4) + 2)
		p[5] = unit() * 1.5 + 0.3
		p[6] = rand(2)
		p[7] = rand(95) + 5
	end,
	draw = function(canvas, audio, s, p)
		if p[4] == 0 then
			return
		end
		s.ball = s.ball or new_ball(rand(200), rand(200), unit(), unit())
		s.hue = s.hue or rand(256)
		s.phase = s.phase or unit() * 3.1415927
		s.toggle = s.toggle or 0
		local spokes = ftol(p[4])
		bounce(s.ball, 6.0)
		local speed = (bins.frequency(audio, 0) + bins.frequency(audio, 1) + bins.frequency(audio, 0)) * 0.00011111111
		s.hue = (s.hue - ftol(speed * -6)) % 256
		s.phase = s.phase + speed
		if s.phase > TAU then
			s.phase = s.phase - TAU
		end
		local reach = rand(CX)
		local width = 1024 // spokes
		if width == 0 then
			return
		end
		local slices, total = {}, 0
		local per_slice = math.max(1, math.min(6, width))
		for spoke = 0, spokes - 1 do
			local high = 1024 - spoke * width
			local sum = 0
			for index = 0, per_slice - 1 do
				sum = sum + bins.frequency(audio, math.max(high - 1 - (index + 0.5) * width / per_slice, 0))
			end
			sum = sum * width / per_slice
			slices[spoke] = sum
			total = total + sum
		end
		if total <= 0 then
			return
		end
		local lines = p[6] == 0
		local mirror = p[3] == 0
		local cx, cy = s.ball.x, s.ball.y
		local segments = lines and 14 or math.min(100, MAX_DOTS // (spokes * (mirror and 2 or 1)))
		local draw_arc = lines and arc_line or arc_dots
		local points, colors, far_points, far_colors = {}, {}, {}, {}
		local x0, y0, accumulated = CX, CY, 0
		local mode = ftol(p[2])
		for spoke = 0, spokes - 1 do
			accumulated = accumulated + slices[spoke]
			local radius = reach * accumulated / total
			local turn = slices[spoke] / (width * 255) * p[5]
			if mode == 0 then
				if spoke % 2 == 0 then
					turn = -turn
				end
			elseif mode == 1 then
				s.toggle = (s.toggle + 1) % 2
				if s.toggle == 0 then
					turn = -turn
				end
			elseif rand(2) == 1 then
				turn = -turn
			end
			local angle = turn + s.phase
			local x1, y1 = CX + ftol(cos(angle) * radius), CY + ftol(sin(angle) * radius)
			draw_arc(points, colors, x0, y0, x1, y1, cx, cy, s.hue, 255, segments)
			if mirror then
				draw_arc(far_points, far_colors, WIDTH - x0, HEIGHT - y0, WIDTH - x1, HEIGHT - y1, WIDTH - cx, HEIGHT - cy, s.hue, 255, segments)
			end
			x0, y0 = x1, y1
		end
		if lines then
			if #points > 1 then
				canvas:draw_polyline_colors(points, colors)
			end
			if #far_points > 1 then
				canvas:draw_polyline_colors(far_points, far_colors)
			end
		else
			if #points > 1 then
				canvas:draw_multiline_colors(points, colors)
			end
			if #far_points > 1 then
				canvas:draw_multiline_colors(far_points, far_colors)
			end
		end
	end,
}

effects.Galaxy = {
	mask = 2,
	randomize = function(p)
		p[1] = rand(5) + 1
		p[2] = rand(4) == 0 and rand(100) + 9 or rand(20) + 10
		p[3] = (unit() * 0.4 + 0.05) / p[1]
		p[4] = rand(56) + 200
		p[5] = rand(10)
		p[6] = rand(150)
		p[7] = unit() * 6e-07
		p[8] = unit() * 0.3
	end,
	draw = function(canvas, audio, s, p)
		s.ball = s.ball or { x = 0, y = 0, fx = 0, fy = 0, vx = unit() * 5.6, vy = unit() * 5.6, left = -WIDTH, top = -HEIGHT, right = WIDTH, bottom = HEIGHT }
		local ball = s.ball
		local energy = bass_sum(audio) * 0.00065359477
		if p[6] < 3 then
			local size = ball.fx * ball.fx + ball.fy * ball.fy
			local speed = math.max(sqrt(ball.vx * ball.vx + ball.vy * ball.vy), 0.0001)
			local ax = ball.vy / speed * energy + (-ball.fx * p[7] * size - ball.vx * p[8])
			local ay = -ball.vx / speed * energy + (-ball.fy * p[7] * size - ball.vy * p[8])
			ball.vx, ball.vy = ball.vx + ax, ball.vy + ay
			bounce(ball, 0.6)
		end
		s.phase = (s.phase or 0) + energy * p[3]
		if s.phase > TAU then
			s.phase = s.phase - TAU
		end
		local arms = math.min(ftol(p[1]), 50)
		local cx, cy = CX + ball.x, CY + ball.y
		local dots = p[5] ~= 0
		for arm = 0, arms - 1 do
			local angle = s.phase + arm * 3.1415927 / arms
			for side = -1, 1, 2 do
				local x1, y1 = cx + side * ftol(cos(angle) * p[2]), cy + side * ftol(sin(angle) * p[2])
				local px, py = cx + side * ftol(-sin(angle) * p[2] * 0.5), cy + side * ftol(cos(angle) * p[2] * 0.5)
				local points, colors = {}, {}
				if dots then
					arc_dots(points, colors, cx, cy, x1, y1, px, py, 255, p[4], 40)
					if #points > 1 then
						canvas:draw_multiline_colors(points, colors)
					end
				else
					arc_line(points, colors, cx, cy, x1, y1, px, py, 255, p[4], 14)
					if #points > 1 then
						canvas:draw_polyline_colors(points, colors)
					end
				end
			end
		end
	end,
}

effects.JiggyScribble = {
	mask = 2,
	randomize = function(p)
		p[1] = rand(100) + 4
		p[2] = rand(200) + 40
		p[3] = rand(1000) + 300
		p[4] = rand(20) + 1
		p[5] = unit() * 0.6 + 0.05
		p[6] = rand(10)
		p[7] = rand(10)
	end,
	draw = function(canvas, audio, s, p)
		local count = ftol(p[3])
		if not s.table then
			s.table = {}
			for index = 0, count do
				local t = index * (p[3] == 0 and 0 or TAU / p[3])
				s.table[index * 4 + 1] = p[1] * cos(t * p[4])
				s.table[index * 4 + 2] = p[1] * sin(t * p[4])
				s.table[index * 4 + 3] = cos(t)
				s.table[index * 4 + 4] = sin(t)
			end
		end
		local grow = (p[2] - p[1]) * bass_sum(audio) * 0.00065359477
		s.spin = (s.spin or 0) + p[5]
		if s.spin > TAU then
			s.spin = s.spin - TAU
		end
		local c, n = cos(s.spin), sin(s.spin)
		local values = s.table
		if p[7] ~= 9 then
			local points, used = {}, 0
			for index = 0, count - 1 do
				local at = index * 4
				local x = values[at + 1] + grow * values[at + 3]
				local y = values[at + 2] + grow * values[at + 4]
				local px, py = floor(y * c - x * n + CX), floor(y * n + x * c + CY)
				if px >= 0 and py >= 0 and px < WIDTH and py < HEIGHT then
					used = used + 2
					points[used - 1] = Vector2(px, py + 0.5)
					points[used] = Vector2(px + 1, py + 0.5)
				end
			end
			plot(canvas, points, used, shades[255])
		else
			local points = {}
			for index = 0, count do
				local at = index * 4
				local x = values[at + 1] + grow * values[at + 3]
				local y = values[at + 2] + grow * values[at + 4]
				points[#points + 1] = Vector2(floor(y * c - x * n + CX) + 0.5, floor(y * n + x * c + CY) + 0.5)
			end
			canvas:draw_polyline(points, shades[255])
		end
	end,
}

local function dot_camera()
	local ex, ey, ez = CX, CY, CY
	local length = sqrt(ex * ex + ey * ey + ez * ez)
	local fx, fy, fz = ex / length, ey / length, ez / length
	local ux, uy, uz = -fx * fy, 1 - fy * fy, -fz * fy
	local up = sqrt(ux * ux + uy * uy + uz * uz)
	ux, uy, uz = ux / up, uy / up, uz / up
	local rx, ry, rz = fy * uz - uy * fz, fz * ux - fx * uz, fx * uy - ux * fy
	local depth = length - WIDTH * 0.6
	return { rx, ry, rz, ux, uy, uz, fx, fy, fz, depth }
end

local CAMERA = dot_camera()

effects.DotPlane = {
	mask = 0,
	randomize = function(p)
		p[1] = rand(28) + 20
		p[2] = (rand(4) == 0 and 4 or 0) | (rand(4) == 0 and 2 or 0) | (rand(4) == 0 and 1 or 0)
	end,
	draw = function(canvas, audio, s, p)
		local size = ftol(p[1])
		if not s.rows then
			s.rows, s.speeds, s.depths, s.bins = {}, {}, {}, {}
			for row = 0, size - 1 do
				s.rows[row], s.speeds[row], s.depths[row] = {}, {}, -size
			end
			local bin = 1
			for column = 0, size - 1 do
				s.bins[column] = math.min(bin, 1023)
				local following = ftol(bin * 1.096)
				bin = following <= bin and bin + 1 or following
			end
			s.head, s.ax, s.ay, s.az = 0, 0, 0, 0
		end
		local flags = ftol(p[2])
		if flags & 1 ~= 0 then
			s.ax = (s.ax + 1) % 300
		end
		if flags & 2 ~= 0 then
			s.ay = (s.ay + 1) % 300
		end
		if flags & 4 ~= 0 then
			s.az = (s.az + 1) % 300
		end
		local heights, speeds = s.rows[s.head], s.speeds[s.head]
		for column = 0, size - 1 do
			local level = floor(bins.frequency(audio, s.bins[column])) >> 2
			heights[column] = level * level * 0.015
			speeds[column] = 0
		end
		s.depths[s.head] = -(size * 0.5)
		s.head = (s.head + 1) % size
		local a = s.ax * 0.02094395
		local ca, sa = cos(a), sin(a)
		local b = s.ay * 0.02094395
		local cb, sb = cos(b), sin(b)
		local g = s.az * 0.02094395
		local cg, sg = cos(g), sin(g)
		local m11, m12, m13 = cb, 0, -sb
		local m21, m22, m23 = sa * sb, ca, sa * cb
		local m31, m32, m33 = ca * sb, -sa, ca * cb
		local n11, n12 = m11 * cg + m12 * sg, -m11 * sg + m12 * cg
		local n21, n22 = m21 * cg + m22 * sg, -m21 * sg + m22 * cg
		local n31, n32 = m31 * cg + m32 * sg, -m31 * sg + m32 * cg
		local q = CAMERA
		local depth = q[10]
		local x1, y1, z1 = n11 * q[1] + n12 * q[2] + m13 * q[3], n11 * q[4] + n12 * q[5] + m13 * q[6], n11 * q[7] + n12 * q[8] + m13 * q[9]
		local x2, y2, z2 = n21 * q[1] + n22 * q[2] + m23 * q[3], n21 * q[4] + n22 * q[5] + m23 * q[6], n21 * q[7] + n22 * q[8] + m23 * q[9]
		local x3, y3, z3 = n31 * q[1] + n32 * q[2] + m33 * q[3], n31 * q[4] + n32 * q[5] + m33 * q[6], n31 * q[7] + n32 * q[8] + m33 * q[9]
		local points, used = {}, 0
		local half = size // 2
		for row = 0, size - 1 do
			local z = s.depths[row]
			local line, velocity = s.rows[row], s.speeds[row]
			for column = 0, size - 1 do
				local y = line[column]
				if y then
					local x = column - half
					local d = depth - 1 - (x * z1 + y * z2 + z * z3)
					if d > 0 then
						local px = floor(CY + 249.415 * (x * x1 + y * x2 + z * x3) / d + (WIDTH - HEIGHT) / 2)
						local py = floor(CY - 249.415 * (x * y1 + y * y2 + z * y3) / d)
						if px >= 0 and py >= 0 and px < WIDTH and py < HEIGHT then
							used = used + 2
							points[used - 1] = Vector2(px, py + 0.5)
							points[used] = Vector2(px + 1, py + 0.5)
						end
					end
					if y > 0 then
						local speed = velocity[column]
						y = y - speed
						line[column] = y < 0 and 0 or y
						velocity[column] = speed + 0.01
					end
				end
			end
			s.depths[row] = z + 1
		end
		plot(canvas, points, used, shades[254])
	end,
}

local function new_effect(name, params)
	return { kind = effects[name], name = name, params = params or {}, state = {} }
end

local function run(list, canvas, audio, shift_mask)
	for _, item in ipairs(list) do
		if shift_mask == nil or item.kind.mask & shift_mask == 0 then
			item.kind.draw(canvas, audio, item.state, item.params)
		end
	end
end

local function build(list)
	local result = {}
	for _, item in ipairs(list) do
		if effects[item[1]] then
			result[#result + 1] = new_effect(item[1], item[2])
		end
	end
	return result
end

local function shift_mask(name)
	return name == "TileShift" and 1 or 0
end

local function arrange(state, scene)
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
			run(state.post, post, scene.audio)
		end
	end)
	state.post_canvas = post
end

local function start_palette(state, scene, colors, locked)
	state.locked = locked
	state.texture = texture_from(colors)
	state.previous = state.texture
	state.blend = 1
	state.timer = rand(600)
	state.morph_length = 1
	scene.engine.set(scene, "colors", state.texture)
	scene.engine.set(scene, "previous", state.previous)
	scene.engine.set(scene, "blend", 1.0)
end

local function step_palette(state, scene)
	if state.blend < 1 then
		state.blend = math.min(1, state.blend + 1 / state.morph_length)
		scene.engine.set(scene, "blend", state.blend)
		if state.blend >= 1 then
			state.timer = rand(600)
		end
	elseif not state.locked then
		state.timer = state.timer - 1
		if state.timer < 1 then
			state.previous = state.texture
			state.texture = texture_from(random_colors())
			state.morph_length = math.max(rand(250), 1)
			state.blend = 0
			scene.engine.set(scene, "previous", state.previous)
			scene.engine.set(scene, "colors", state.texture)
			scene.engine.set(scene, "blend", 0.0)
		end
	end
end

local function make(entry)
	local p = entry.params
	return {
		name = entry.name,
		size = { WIDTH, HEIGHT },
		filter = "nearest",
		feedback = FEEDBACK,
		layers = { BLUR },
		display = PALETTE,
		params = {
			shift = SHIFTS[entry.shift] or 0,
			shape = Color(p[1], p[2], p[3], p[4]),
			seed = random() * 100,
		},
		setup = function(state, scene)
			state.pre, state.post = build(entry.pre), build(entry.post)
			state.mask = shift_mask(entry.shift)
			arrange(state, scene)
			start_palette(state, scene, entry.palette and decode(entry.palette) or random_colors(), entry.palette ~= nil)
		end,
		step = function(state, _, scene)
			step_palette(state, scene)
			state.post_canvas:queue_redraw()
		end,
		draw = function(canvas, state, audio)
			run(state.pre, canvas, audio, state.mask)
		end,
	}
end

local RANDOM_SHIFTS = {
	LinearShift = function(p)
		p[1], p[2] = rand(6) - 3, rand(6) - 3
	end,
	ThingusShift = function(p)
		p[1], p[2] = unit() * 0.8 - 0.4, unit() * 0.2
	end,
	ZoomShift = function(p)
		p[1], p[2] = unit() * 0.1 - 0.05, unit() * 0.2 - 0.1
	end,
	RingSpinShift = function(p)
		p[1], p[2] = unit() * 0.1 - 0.05, unit() * 0.8
	end,
	StretchShift = function(p)
		p[1], p[2] = unit() * 0.1 - 0.05, unit() * 0.3
	end,
	TileShift = function(p)
		p[1] = unit() * 0.2
	end,
	TrigShift = function(p)
		p[1], p[2], p[3] = unit() * 0.1 - 0.05, unit() * 0.1 - 0.05, rand(3)
	end,
	SinShimmerShift = function(p)
		p[1], p[2], p[3] = unit() * 10 - 5, unit() * 2, rand(2)
	end,
	EdgeFalloffShift = function(p)
		p[1], p[2] = unit() * 0.1, rand(4)
	end,
	StarburstShift = function(p)
		local spokes = rand(40)
		p[1], p[2], p[3], p[4] = unit() * 0.1 - 0.05, unit() * 0.3, spokes % 2 + spokes, rand(2)
	end,
	SwirlShift = function(p)
		p[1], p[2], p[3] = unit() * 0.1 - 0.05, rand(20) - 10, rand(24) - 12
	end,
	Twirlocity = function(p)
		p[1], p[2], p[3] = rand(50) + 1, unit() * 0.6, rand(10)
	end,
	Shiitake = function(p)
		p[1] = unit() * 11 - 1
		p[2] = rand(100) == 0 and unit() * 50.265484 or unit() * 0.15707964
		p[3] = rand(100) == 0 and unit() * 8 or unit() * 0.05
		local pick = rand(10)
		p[4] = pick == 0 and rand(100) + 1 or (pick < 4 and rand(5) + 1 or rand(2) + 1)
	end,
	TrigStretchShift = function(p)
		p[1], p[2], p[3], p[4] = unit() * 0.1 - 0.05, unit() * 0.1 - 0.05, rand(3), unit() * 0.3
	end,
}

local SHIFT_NAMES = {}
for name in pairs(RANDOM_SHIFTS) do
	SHIFT_NAMES[#SHIFT_NAMES + 1] = name
end
table.sort(SHIFT_NAMES)

local EDGE_NAMES = { "EdgeTrace", "EdgeGradiant", "CosEdgeGradiant", "WaveEdge", "SpectrumEdge" }
local SHAPE_NAMES = { "CircleWaveform", "JDar", "Galaxy", "JiggyScribble", "DotPlane" }

local function random_effect(name)
	local item = new_effect(name, {})
	item.kind.randomize(item.params)
	return item
end

local function random_effects(state)
	state.pre, state.post = {}, {}
	if rand(2) == 0 then
		state.pre[1] = random_effect(EDGE_NAMES[rand(#EDGE_NAMES) + 1])
	end
	for _ = 1, rand(2) + 1 do
		local list = rand(2) == 0 and state.pre or state.post
		list[#list + 1] = random_effect(SHAPE_NAMES[rand(#SHAPE_NAMES) + 1])
	end
	state.effect_timer = rand(310) + 90
end

local function random_shift(state, scene)
	local name
	repeat
		name = SHIFT_NAMES[rand(#SHIFT_NAMES) + 1]
	until name ~= state.shift_name
	local p = { 0, 0, 0, 0 }
	RANDOM_SHIFTS[name](p)
	local shape = Color(p[1], p[2], p[3], p[4])
	scene.engine.set(scene, "shift_from", state.shift_id or SHIFTS[name])
	scene.engine.set(scene, "shape_from", state.shape or shape)
	scene.engine.set(scene, "shift", SHIFTS[name])
	scene.engine.set(scene, "shape", shape)
	state.morph = state.shift_id and 0 or 18
	state.morph_wait = 0
	scene.engine.set(scene, "morph", state.morph / 18)
	state.shift_name, state.shift_id, state.shape = name, SHIFTS[name], shape
	state.mask = shift_mask(name)
	state.shift_timer = rand(390) + 60
end

local presets = {}
for _, entry in ipairs(data) do
	presets[#presets + 1] = make(entry)
end
table.sort(presets, function(a, b) return a.name:lower() < b.name:lower() end)

table.insert(presets, 1, {
	name = "Random",
	size = { WIDTH, HEIGHT },
	filter = "nearest",
	feedback = FEEDBACK,
	layers = { BLUR },
	display = PALETTE,
	params = { seed = random() * 100 },
	setup = function(state, scene)
		state.pre, state.post = {}, {}
		arrange(state, scene)
		start_palette(state, scene, random_colors(), false)
		random_shift(state, scene)
		random_effects(state)
	end,
	step = function(state, _, scene)
		step_palette(state, scene)
		state.shift_timer = state.shift_timer - 1
		state.effect_timer = state.effect_timer - 1
		if state.shift_timer < 1 then
			random_shift(state, scene)
		end
		if state.effect_timer < 1 then
			random_effects(state)
		end
		if state.morph < 18 then
			state.morph_wait = state.morph_wait - 1
			if state.morph_wait < 1 then
				state.morph = state.morph + 1
				state.morph_wait = rand(15) + 1
				scene.engine.set(scene, "morph", state.morph / 18)
			end
		end
		state.post_canvas:queue_redraw()
	end,
	draw = function(canvas, state, audio)
		run(state.pre, canvas, audio, state.mask)
	end,
})

return {
	name = "Battery",
	presets = presets,
}

local bins = require("packs.wmp_bins")
local sticks = require("packs.sticky_sticks")

local TAU = math.pi * 2
local LINE, ARC, SPRING, CIRCLE = 0, 1, 2, 3
local KIND, INVISIBLE, ROOT, RELATIVE, OFFSET, SCALE, SPIN, SHORT, LONG, CHANNEL, BAND, FIXED, NEGATIVE, RED, GREEN, BLUE, THICK, ANCHOR, CUMULATIVE, RATE, BOUNCE = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21
local BITMAP, BRUSH, OUTLINE, ALTERNATE, POINTS, SIDES = 1, 2, 3, 4, 5, 6

local textures = {}

local function texture(path)
	textures[path] = textures[path] or nari.load(path)
	return textures[path]
end

local function prepare(stick)
	if stick.order then
		return stick
	end
	local children = {}
	for index = 1, #stick.limbs do
		children[index] = {}
	end
	for index = 2, #stick.limbs do
		local parent = stick.limbs[index][ROOT] + 1
		table.insert(children[parent], index)
	end
	stick.order = {}
	local queue = { 1 }
	while #queue > 0 do
		local index = table.remove(queue, 1)
		stick.order[#stick.order + 1] = index
		for _, child in ipairs(children[index]) do
			queue[#queue + 1] = child
		end
	end
	stick.colors = {}
	for index, limb in ipairs(stick.limbs) do
		if limb[RED] >= 0 then
			stick.colors[index] = Color(limb[RED] / 255.0, limb[GREEN] / 255.0, limb[BLUE] / 255.0, 1.0)
		else
			stick.colors[index] = Color(1.0, 1.0, 1.0, 1.0)
		end
	end
	stick.fills = {}
	stick.pens = {}
	for index, shape in ipairs(stick.shapes) do
		if shape ~= "limbs" then
			local brush = shape[BRUSH]
			if brush then
				stick.fills[index] = brush[1] < 0 and Color(1.0, 1.0, 1.0, 1.0) or Color(brush[1] / 255.0, brush[2] / 255.0, brush[3] / 255.0, 1.0)
			end
			local outline = shape[OUTLINE]
			if outline then
				stick.pens[index] = Color(outline[2] / 255.0, outline[3] / 255.0, outline[4] / 255.0, 1.0)
			end
		end
	end
	return stick
end

local function reset(state, stick)
	state.stick = prepare(stick)
	state.f = {}
	state.flip = {}
	for index, limb in ipairs(stick.limbs) do
		state.f[index] = limb[FIXED]
		state.flip[index] = limb[BOUNCE]
	end
	state.ax, state.ay, state.bx, state.by, state.start, state.finish, state.reach = {}, {}, {}, {}, {}, {}, {}
	state.dx, state.dy = 0, 0
end

local LOG_SPAN = math.log(400)

local function byte(audio, position)
	local at = math.max(0, math.min(31, position))
	local index = math.floor(at)
	local bands = audio.bands or {}
	local a, b = bands[index + 1] or 0, bands[math.min(index + 2, 32)] or 0
	local value = a + (b - a) * (at - index)
	return 10 ^ ((value * 66.0 - 66.0 - at * 0.9) / 40.0) * 640.0
end

local function analyse(state, audio)
	state.gap = state.gap + 33.3
	local decay = state.gap > 100
	if decay then
		state.gap = 0
	end
	local channels = state.channels
	for band = 1, 6 do
		if decay then
			state.high[band] = state.high[band] * 0.999
			state.low[band] = math.max(state.low[band], 22.0) * 1.002
		end
		local position = 11.7 + band * 1.55
		local left, right
		if audio.stereo then
			local bin = 40 * math.exp((position + 0.5) * LOG_SPAN / 32) * 2048 / 44100
			left, right = bins.frequency(audio, bin, 0) * 16, bins.frequency(audio, bin, 1) * 16
		else
			left, right = byte(audio, position) * 16, byte(audio, position + 0.8) * 16
		end
		state.high[band] = math.max(state.high[band], left, right)
		if decay and (left < state.low[band] or right < state.low[band]) then
			state.low[band] = state.low[band] * 0.9
		end
		local range = state.high[band] - state.low[band] + 1.0
		local l = math.max(0, (left - state.low[band]) / range)
		local r = math.max(0, (right - state.low[band]) / range)
		channels[0][band] = l * l
		channels[1][band] = r * r
		channels[2][band] = (r * r + 1.0 - l * l) * 0.5
		channels[3][band] = audio.level or 0
	end
end

local function advance(state, audio, stick)
	local f, flip = state.f, state.flip
	for index, limb in ipairs(stick.limbs) do
		local channel = limb[CHANNEL]
		if channel < 4 then
			local value = state.channels[channel][limb[BAND] + 1] or 0
			if limb[CUMULATIVE] then
				if channel == 2 then
					value = value - 0.5
				end
				local rate = limb[RATE]
				local delta = value * 3.33 * rate
				if rate < 0 then
					delta = -(3.33 * rate)
				end
				local direction = limb[NEGATIVE] and -1 or 1
				if flip[index] < 0 then
					direction = -direction
				end
				local next_f = delta * direction * 0.01 + f[index]
				if flip[index] == 0 then
					next_f = next_f % 1.0
				else
					while next_f > 1.0 or next_f < 0.0 do
						next_f = next_f > 1.0 and 2.0 - next_f or -next_f
						flip[index] = -flip[index]
					end
				end
				f[index] = next_f
			elseif limb[NEGATIVE] then
				f[index] = 1.0 - value
			else
				f[index] = value
			end
		end
	end
end

local function pose(state, stick)
	local ax, ay, bx, by, start, finish, reach, f = state.ax, state.ay, state.bx, state.by, state.start, state.finish, state.reach, state.f
	local limbs = stick.limbs
	bx[1], by[1] = 0, 0
	for _, index in ipairs(stick.order) do
		local limb = limbs[index]
		local parent = limb[ROOT] + 1
		local base = limb[OFFSET]
		local kind = limb[KIND]
		if limb[RELATIVE] and parent ~= 1 then
			base = base + finish[parent]
		end
		local fixed = limb[CHANNEL] == 4 and limb[BAND] == 0
		local length = limb[LONG]
		local angle
		if kind == SPRING or kind == CIRCLE then
			angle = base + limb[SPIN]
			if not fixed then
				length = limb[SHORT] * f[index] + (1.0 - f[index]) * length
			end
		elseif not fixed then
			angle = f[index] * limb[SCALE] + base
		elseif limb[RELATIVE] then
			angle = (finish[parent] or 0) + f[index] + limb[OFFSET]
		else
			angle = f[index] + limb[OFFSET]
		end
		ax[index], ay[index] = bx[parent], by[parent]
		start[index], finish[index], reach[index] = base, angle, length
		bx[index] = math.cos(angle) * length + ax[index]
		by[index] = math.sin(angle) * length + ay[index]
	end
	local top, bottom, left, right = 5, -5, 5, -5
	local vertical_top, vertical_bottom, horizontal_left, horizontal_right
	for index = 2, #limbs do
		local anchor = limbs[index][ANCHOR]
		if anchor == 1 then
			top = math.min(top, by[index])
			vertical_top = true
		elseif anchor == 2 then
			right = math.max(right, bx[index])
			horizontal_right = true
		elseif anchor == 3 then
			bottom = math.max(bottom, by[index])
			vertical_bottom = true
		elseif anchor == 4 then
			left = math.min(left, bx[index])
			horizontal_left = true
		end
	end
	local dx, dy = 0, 0
	if vertical_top then
		dy = -top - 5
	end
	if horizontal_right then
		dx = 5 - right
	end
	if vertical_bottom then
		dy = 5 - bottom
	end
	if horizontal_left then
		dx = -left - 5
	end
	state.dx, state.dy = dx, dy
end

local function arc_point(state, stick, index, t)
	local limb = stick.limbs[index]
	local radius, from, to = state.reach[index], state.start[index], state.finish[index]
	if limb[KIND] == CIRCLE then
		local dx, dy = state.bx[index] - state.ax[index], state.by[index] - state.ay[index]
		radius = math.sqrt(dx * dx + dy * dy)
		from = to - math.pi * 1.96
	end
	local angle = to * t + (1.0 - t) * from
	return math.cos(angle) * radius + state.ax[index], math.sin(angle) * radius + state.ay[index]
end

local function shape_points(state, stick, shape, sx, sy, scale)
	local points = {}
	local list, sides = shape[POINTS], shape[SIDES]
	local count = #list
	local limbs = stick.limbs
	for slot = 1, count do
		local index = list[slot] + 1
		local side = sides[slot]
		local following = slot % count + 1
		local kind = limbs[index][KIND]
		if list[following] + 1 == index and sides[following] ~= side and (kind == ARC or kind == CIRCLE) then
			local span = math.abs(state.finish[index] - state.start[index])
			if kind == CIRCLE then
				span = math.pi * 1.96
			end
			local segments = math.max(4, math.min(48, math.floor(span * state.reach[index] * scale / 6)))
			for step = 0, segments - 1 do
				local t = step / segments
				if not side then
					t = 1.0 - t
				end
				local x, y = arc_point(state, stick, index, t)
				points[#points + 1] = Vector2(sx(x), sy(y))
			end
		elseif side and (kind == ARC or kind == CIRCLE) then
			local x, y = arc_point(state, stick, index, 0.0)
			points[#points + 1] = Vector2(sx(x), sy(y))
		else
			points[#points + 1] = Vector2(sx(state.bx[index]), sy(state.by[index]))
		end
	end
	if count > 2 and #points > 0 then
		points[#points + 1] = points[1]
	end
	return points
end

local function fill_polygon(canvas, points, color)
	local count = #points - 1
	if count < 3 then
		return
	end
	local open = {}
	for index = 1, count do
		open[index] = points[index]
	end
	local indices = Geometry2D:triangulate_polygon(open)
	local size = indices and #indices or 0
	if size >= 3 then
		for index = 1, size, 3 do
			local a, b, c = open[indices[index] + 1], open[indices[index + 1] + 1], open[indices[index + 2] + 1]
			canvas:draw_primitive({ a, b, c }, { color, color, color }, {})
		end
	else
		for index = 2, count - 1 do
			canvas:draw_primitive({ open[1], open[index], open[index + 1] }, { color, color, color }, {})
		end
	end
end

local function pen(thick, unit)
	return math.max(1.0, math.floor(thick * unit * 0.03 + 0.5))
end

local function draw_limbs(canvas, state, stick, sx, sy, scale, unit)
	local limbs = stick.limbs
	for index = 2, #limbs do
		local limb = limbs[index]
		if not limb[INVISIBLE] then
			local width = pen(limb[THICK], unit)
			local color = stick.colors[index]
			local kind = limb[KIND]
			local x0, y0 = sx(state.ax[index]), sy(state.ay[index])
			if kind == LINE or kind == SPRING then
				canvas:draw_line(Vector2(x0, y0), Vector2(sx(state.bx[index]), sy(state.by[index])), color, width)
			elseif kind == ARC then
				local from, to = state.start[index], state.finish[index]
				local radius = state.reach[index] * scale
				local segments = math.max(3, math.min(64, math.floor(math.abs(to - from) * radius / 4)))
				local points = {}
				for step = 0, segments do
					local angle = from + (to - from) * step / segments
					points[step + 1] = Vector2(x0 + math.cos(angle) * radius, y0 + math.sin(angle) * radius)
				end
				canvas:draw_polyline(points, color, width)
			else
				canvas:draw_arc(Vector2(x0, y0), state.reach[index] * scale, 0, TAU, 32, color, width)
			end
		end
	end
end

local function draw_circle_shape(canvas, state, stick, shape, order, sx, sy, scale, unit)
	local index = shape[POINTS][1] + 1
	local x, y = sx(state.ax[index]), sy(state.ay[index])
	local dx, dy = state.bx[index] - state.ax[index], state.by[index] - state.ay[index]
	local radius = math.sqrt(dx * dx + dy * dy) * scale
	if shape[BITMAP] then
		local image = texture(shape[BITMAP])
		local w, h = image:get_width(), image:get_height()
		local bw, bh = radius * 2, radius * 2
		if w > h then
			bh = bh * h / w
		elseif h > w then
			bw = bw * w / h
		end
		canvas:draw_set_transform(Vector2(x, y), state.finish[index], Vector2(1.0, 1.0))
		canvas:draw_texture_rect(image, Rect2(-bw / 2, -bh / 2, bw, bh), false)
		canvas:draw_set_transform(Vector2(0.0, 0.0), 0.0, Vector2(1.0, 1.0))
	end
	if stick.fills[order] then
		canvas:draw_circle(Vector2(x, y), radius, stick.fills[order])
	end
	if stick.pens[order] then
		canvas:draw_arc(Vector2(x, y), radius, 0, TAU, 32, stick.pens[order], pen(shape[OUTLINE][1], unit))
	end
end

local function render(canvas, state, scene)
	local stick = state.stick
	local width, height = scene.width, scene.height
	local side = math.min(width, height)
	local scale = side / 10
	local left, top = (width - side) / 2, (height - side) / 2
	local dx, dy = state.dx, state.dy
	local function sx(x)
		return (x + dx + 5) * scale + left
	end
	local function sy(y)
		return (y + dy + 5) * scale + top
	end
	canvas:draw_rect(Rect2(0, 0, width, height), stick.background)
	for order, shape in ipairs(stick.shapes) do
		if shape == "limbs" then
			draw_limbs(canvas, state, stick, sx, sy, scale, side / 10)
		else
			local list, sides = shape[POINTS], shape[SIDES]
			if #list == 2 and list[1] == list[2] and sides[1] ~= sides[2] and stick.limbs[list[1] + 1][KIND] == CIRCLE then
				draw_circle_shape(canvas, state, stick, shape, order, sx, sy, scale, side / 10)
			else
				local points = shape_points(state, stick, shape, sx, sy, scale)
				if stick.fills[order] then
					fill_polygon(canvas, points, stick.fills[order])
				end
				if stick.pens[order] and #points >= 2 then
					canvas:draw_polyline(points, stick.pens[order], pen(shape[OUTLINE][1], side / 10))
				end
			end
		end
	end
end

local function preset(name, stick)
	return {
		name = name,
		setup = function(state, scene)
			scene.canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			state.gap = 0
			state.high, state.low = {}, {}
			for band = 1, 6 do
				state.high[band], state.low[band] = 400.0, 200.0
			end
			state.channels = { [0] = {}, [1] = {}, [2] = {}, [3] = {} }
			state.last = 0
			reset(state, stick or sticks[math.random(#sticks)])
		end,
		step = function(state, audio)
			if not stick then
				local progress = audio.progress or 0
				if progress < state.last - 0.5 then
					reset(state, sticks[math.random(#sticks)])
				end
				state.last = progress
			end
			analyse(state, audio)
			advance(state, audio, state.stick)
			pose(state, state.stick)
		end,
		draw = function(canvas, state, _, scene)
			render(canvas, state, scene)
		end,
	}
end

local presets = { preset("Randomization") }
for _, stick in ipairs(sticks) do
	presets[#presets + 1] = preset(stick.name, stick)
end

return {
	name = "Sticky",
	presets = presets,
}

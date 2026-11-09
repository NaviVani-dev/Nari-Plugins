local bins = require("packs.wmp_bins")

local WARP = "shaders/alchemy/warp.gdshader"
local SHOW = "shaders/alchemy/show.gdshader"
local BALL = "shaders/alchemy/ball.gdshader"
local SIZE = 512
local HALF = 256
local PI = math.pi

local function rnd(low, high)
	return low + (high - low) * math.random()
end

local function int(low, high)
	return math.random(low, high)
end

local function pick(low, high, rolls)
	local best = high
	for _ = 1, rolls do
		best = math.min(best, int(low, high))
	end
	return best
end

local function random_color()
	return { (math.random() * 65535 % 256), (math.random() * 65535 % 256), (math.random() * 65535 % 256) }
end

local function fader(top)
	return { from = random_color(), to = random_color(), now = random_color(), t = 0, span = int(1, top), top = top }
end

local function advance(fade, step)
	fade.t = fade.t + step
	if fade.t > fade.span then
		fade.from = fade.now
		fade.to = random_color()
		fade.t = 0
		fade.span = int(1, fade.top)
		return fade.now
	end
	local k = math.sin(fade.t / fade.span * PI * 0.5)
	local from, to = fade.from, fade.to
	fade.now = { from[1] + (to[1] - from[1]) * k, from[2] + (to[2] - from[2]) * k, from[3] + (to[3] - from[3]) * k }
	return fade.now
end

local function paint(rgb, alpha)
	return Color(rgb[1] / 255.0, rgb[2] / 255.0, rgb[3] / 255.0, alpha)
end

local function wave_line(canvas, audio, x1, y1, x2, y2, brush)
	local dx, dy = x2 - x1, y2 - y1
	local count = math.min(brush.points, math.max(math.abs(dx), math.abs(dy)) + 1)
	if count < 2 then
		return
	end
	count = math.floor(count)
	local angle = math.atan(dy, dx) + PI * 0.5
	local nx, ny = math.cos(angle), math.sin(angle)
	local half = brush.points >> 1
	local line, mirror, hues, soft = {}, {}, {}, {}
	local total = 0
	local step = math.sqrt(dx * dx + dy * dy) / count
	local rgb = brush.head
	for index = 0, count - 1 do
		local at = index
		if brush.fold and at > half then
			at = half * 2 - at
		end
		local value = bins.sample(audio, at / 1023) * brush.amp
		local window = math.abs(math.sin(index / brush.points * brush.lobes * PI))
		if brush.window == 1 then
			window = (index >= half and half * 2 - index or index) / half
		elseif brush.window == 2 then
			window = 1.0
		end
		local f = value * window
		local bx, by = x1 + dx * index / count, y1 + dy * index / count
		line[index + 1] = Vector2(bx + nx * f, by + ny * f)
		if brush.mirror then
			mirror[index + 1] = Vector2(bx - nx * f, by - ny * f)
		end
		total = total + step
		local k = math.min(1.0, total / brush.span)
		local e = math.sin(k * PI * 0.5)
		rgb = { brush.head[1] + (brush.tail[1] - brush.head[1]) * e, brush.head[2] + (brush.tail[2] - brush.head[2]) * e, brush.head[3] + (brush.tail[3] - brush.head[3]) * e }
		hues[index + 1] = paint(rgb, brush.shape == 0 and brush.weight or 1.0)
		soft[index + 1] = paint(rgb, brush.weight)
	end
	if brush.shape > 0 then
		canvas:draw_polyline_colors(line, soft, 3.0)
		if brush.mirror then
			canvas:draw_polyline_colors(mirror, soft, 3.0)
		end
	end
	canvas:draw_polyline_colors(line, hues, 1.0)
	if brush.mirror then
		canvas:draw_polyline_colors(mirror, hues, 1.0)
	end
end

local function scribble()
	local self = { type = 4, chance = 1.0, used = false, angle = 0.0 }
	function self.init()
		self.shape = int(0, 2)
		self.points = int(10, 521)
		self.window = pick(0, 2, 3)
		self.lobes = int(1, 4)
		self.size = rnd(0.1, 0.425)
		self.speed = rnd(-0.13, 0.13)
		self.spin_mode = int(0, 3)
		self.reach = int(0, 1) == 0
		self.mirror = int(0, 2) == 0
		self.second = int(0, 2) == 0
		self.second_mode = int(0, 2)
		self.offset = rnd(-PI * 0.5, PI * 0.5)
		self.a = self.a or fader(50)
		self.b = self.b or fader(50)
	end
	function self.step(level)
		advance(self.a, 1)
		advance(self.b, 1)
		if self.spin_mode == 2 then
			self.angle = self.angle + self.speed
		elseif self.spin_mode == 1 then
			self.angle = self.angle + self.speed * level
		elseif self.spin_mode == 0 then
			self.angle = self.angle + self.speed * level * level
		end
		if self.second_mode == 1 then
			self.offset = self.offset - self.speed * level * 0.5
		end
	end
	function self.draw(canvas, audio, level)
		local length = math.sqrt(SIZE * SIZE * 2)
		if self.reach then
			length = length * level
		end
		local brush = { points = self.points, amp = SIZE * self.size, lobes = self.lobes, window = self.window, shape = self.shape, weight = 0.1, mirror = self.mirror, head = self.b.now, tail = self.a.now, span = self.lobes * 2 }
		local function stroke(angle)
			local cx, cy = math.cos(angle), math.sin(angle)
			wave_line(canvas, audio, HALF + cx * length, HALF + cy * length, HALF - cx * length, HALF - cy * length, brush)
		end
		stroke(self.angle + PI * 0.5)
		if self.second then
			local other = 0.0
			if self.second_mode == 1 then
				other = self.offset + self.angle
			elseif self.second_mode == 2 then
				other = self.angle
			end
			stroke(other)
		end
	end
	return self
end

local function superstar()
	local self = { type = 4, chance = 0.5, used = false, spin = 0.0 }
	function self.init()
		self.size = rnd(0.2, 1.0)
		self.count = int(3, 12)
		self.speed = rnd(-0.2, 0.2)
		self.a = self.a or fader(50)
		self.b = self.b or fader(50)
	end
	function self.step(level, bass)
		self.spin = (self.spin + bass * 0.00166667 * self.speed) % (2 * PI)
		advance(self.a, 1)
		advance(self.b, 1)
	end
	function self.draw(canvas, audio)
		local radius = HALF * self.size
		local stride = 2 * PI / self.count * ((self.count >> 1) + 1)
		local angle = self.spin
		local px, py = HALF + math.cos(angle) * radius, HALF + math.sin(angle) * radius
		local brush = { points = 50, amp = 50, lobes = 2, shape = 3, weight = 0.5, head = self.a.now, tail = self.b.now, span = 6 }
		for _ = 0, self.count do
			angle = angle + stride
			local x, y = HALF + math.cos(angle) * radius, HALF + math.sin(angle) * radius
			wave_line(canvas, audio, px, py, x, y, brush)
			px, py = x, y
		end
	end
	return self
end

local function balls()
	local self = { type = 4, chance = 0.9, used = false, flash = 0, invert = false, strength = 0.4 }
	function self.init()
		self.x, self.y = int(0, SIZE - 1), int(0, SIZE - 1)
		self.vx, self.vy = rnd(-2, 2), rnd(-2, 2)
		self.target = rnd(9, 30)
		self.size = self.target
		self.pull = 0.0
		self.damp = rnd(0.5, 0.9)
		self.fill = fader(55)
		self.edge = fader(55)
	end
	function self.step(level, _, beat)
		self.vx = self.vx + (math.random(0, 1) * 2 - 1) * level
		self.vy = self.vy + (math.random(0, 1) * 2 - 1) * level
		self.x, self.y = self.x + self.vx, self.y + self.vy
		if self.x < 0 or self.x >= SIZE then
			self.vx = -self.vx
			self.x = math.max(0, math.min(SIZE - 1, self.x))
		end
		if self.y < 0 or self.y >= SIZE then
			self.vy = -self.vy
			self.y = math.max(0, math.min(SIZE - 1, self.y))
		end
		self.pull = (self.target - self.size) + self.pull
		self.pull = (0.8 * level + self.pull) * self.damp
		self.size = self.size + self.pull
		self.radius = math.floor(self.size) + 1
		self.strength = level
		if beat then
			self.strength = 0.4
			self.invert = not self.invert
			self.radius = self.radius * 2
			self.flash = 5
		elseif self.flash > 0 then
			self.radius = math.floor(self.radius * 0.4) + 1
		end
		advance(self.fill, 1)
		advance(self.edge, 1)
	end
	function self.draw(canvas, audio, _, state)
		if self.flash > 0 then
			wave_line(canvas, audio, self.x, self.y, SIZE - self.x, SIZE - self.y, { points = 500, amp = 50, lobes = 2, shape = 1, weight = 1.0, head = self.fill.now, tail = self.edge.now, span = 6 })
			self.flash = self.flash - 1
		end
		local rgb = self.fill.now
		if self.invert then
			rgb = { 255 - rgb[1], 255 - rgb[2], 255 - rgb[3] }
		end
		state.ball_fill, state.ball_edge, state.ball_strength = paint(rgb, 1.0), paint(self.edge.now, 1.0), math.min(1.0, self.strength)
		local outer = self.radius + 3.2
		state.ball_radius = self.radius
		state.ball_rects = { Rect2(self.x - outer, self.y - outer, outer * 2, outer * 2), Rect2(SIZE - self.x - outer, SIZE - self.y - outer, outer * 2, outer * 2) }
	end
	return self
end

local function zoom()
	local self = { type = 7, chance = 0.5, used = false, scale = 1.0, count = 0 }
	function self.init()
		self.kick = rnd(0.13, 0.25)
		self.depth = rnd(0.05, 0.2)
		self.period = int(25, 55)
	end
	function self.step(_, _, _, strong)
		if strong then
			self.scale = self.kick
			self.count = 0
		end
		local u = self.count % self.period
		local wave = math.sin(u / self.period * 2 * PI) * self.depth + 1 - self.depth
		self.scale = math.min(1.0, (wave + 15 * self.scale) / 16)
		self.count = self.count + 1
	end
	return self
end

local function warp_polar()
	local a, b = {}, {}
	local self = { kind = 1 }
	function self.init()
		local swirl = int(0, 1) == 0
		local offset = int(0, 1) == 0
		local px, py = int(3, 507), int(3, 507)
		local far = 0
		for _, c in ipairs({ { 0, 0 }, { SIZE, 0 }, { SIZE, SIZE }, { 0, SIZE } }) do
			local ax, ay = offset and px or HALF, offset and py or HALF
			far = math.max(far, math.sqrt((c[1] - ax) ^ 2 + (c[2] - ay) ^ 2))
		end
		self.a = Color(swirl and 1.0 or 0.0, int(1, 15), far, math.floor(SIZE * rnd(0.05, 0.3)))
		self.b = Color(offset and 1.0 or 0.0, px, py, swirl and rnd(-0.22, 0.22) or rnd(-0.1, 0.1))
	end
	return self
end

local function warp_weave()
	local self = { kind = 2 }
	function self.init()
		self.a = Color(int(1, 40), int(1, 4), int(0, 3) == 0 and 1.0 or 0.0, 0.0)
		self.b = Color(0.0, 0.0, 0.0, 0.0)
	end
	return self
end

local function warp_stretch()
	local self = { kind = 3 }
	function self.init()
		local sx, sy
		repeat
			sx, sy = int(-3, 3), int(-3, 3)
		until sx ~= 0 or sy ~= 0
		self.a = Color(int(0, 2) ~= 0 and 1.0 or 0.0, int(0, 7), rnd(0.0, 0.1), rnd(0.0, 0.1))
		self.b = Color(sx, sy, int(0, 2), int(1, 15))
	end
	return self
end

local function warp_mirror()
	local children = { warp_polar(), warp_stretch() }
	local self = { kind = 4 }
	function self.init()
		local child = children[int(1, 2)]
		child.init()
		self.child = child.kind
		self.c, self.d = child.a, child.b
		local radius = int(5, 254)
		self.a = Color(int(0, 3), radius, int(-3, 3), int(-3, 3))
		self.b = Color(0.0, 0.0, 0.0, 0.0)
	end
	return self
end

local function warp_set()
	return { warp_mirror(), warp_mirror(), warp_stretch(), warp_stretch(), warp_polar(), warp_polar(), warp_weave(), warp_weave() }
end

local function choose(state)
	local list, tries = state.warps, 0
	local found
	repeat
		found = list[int(1, #list)]
		tries = tries + 1
	until not found.busy or tries > 100
	found.busy = true
	found.init()
	return found
end

local function load_slot(set, slot, warp)
	local i = tostring(slot)
	set("a" .. i, warp and warp.a or Color(0.0, 0.0, 0.0, 0.0))
	set("b" .. i, warp and warp.b or Color(0.0, 0.0, 0.0, 0.0))
	set("c" .. i, warp and warp.c or Color(0.0, 0.0, 0.0, 0.0))
	set("d" .. i, warp and warp.d or Color(0.0, 0.0, 0.0, 0.0))
end

local function send_warps(state, set)
	local w = state.current
	set("kinds", Color(w[1] and w[1].kind or 0, w[2] and w[2].kind or 0, w[3] and w[3].kind or 0, w[4] and w[4].kind or 0))
	set("inner", Color(w[1] and w[1].child or 0, w[2] and w[2].child or 0, w[3] and w[3].child or 0, w[4] and w[4].child or 0))
	for index = 1, 4 do
		load_slot(set, index - 1, w[index])
	end
end

local function new_warps(state, set)
	local w = state.current
	for index = 1, 2 do
		if w[index] then
			w[index].busy = false
		end
	end
	w[1], w[2] = w[3], w[4]
	w[3] = choose(state)
	w[4] = int(0, 4) == 0 and choose(state) or nil
	state.stage = 0.0
	state.stage_style = pick(0, 2, 3)
	state.stage_rate = int(0, 2) == 0 and int(1, 15) or int(10, 14)
	send_warps(state, set)
end

local function step_warps(state, set)
	if state.stage >= 1.0 then
		return
	end
	if state.stage_style == 0 then
		state.ticks = (state.ticks or 0) + 1
		state.stage = math.min(1.0, math.sin(state.ticks / (state.stage_rate * 22) * PI * 0.5))
		if state.ticks >= state.stage_rate * 22 then
			state.stage = 1.0
		end
	elseif state.stage_style == 1 then
		state.ticks = (state.ticks or 0) + 1
		if state.ticks % state.stage_rate == 0 then
			state.stage = state.stage + 1 / 22
		end
	elseif int(0, state.stage_rate - 1) == 0 then
		state.stage = state.stage + 1 / 22
	end
	if state.stage >= 1.0 then
		state.ticks = 0
	end
	set("stage", state.stage)
end

local LAYERS = {
	{ type = 3, low = 1, high = 1, from = 90, to = 500, flag = 0 },
	{ type = 4, low = 1, high = 2, from = 50, to = 350, flag = 2 },
	{ type = 4, low = 1, high = 3, from = 50, to = 350, flag = 2 },
	{ type = 7, low = 0, high = 1, from = 50, to = 400, flag = 1 },
}

local function retarget(state, layer, set)
	for _, fx in ipairs(layer.active or {}) do
		fx.used = false
	end
	layer.active = {}
	layer.left = int(layer.from, layer.to)
	if layer.type == 3 then
		new_warps(state, set)
		return
	end
	local rolls = (layer.flag & 2) ~= 0 and 10 or ((layer.flag & 1) << 1 | 1)
	local want = pick(layer.low, layer.high, rolls)
	local tries = 100
	while want > 0 and tries > 0 do
		tries = tries - 1
		local fx = state.fx[int(1, #state.fx)]
		if fx.type == layer.type and not fx.used and math.random() < fx.chance then
			fx.used = true
			fx.init()
			table.insert(layer.active, fx)
			want = want - 1
		end
	end
end

local function preset()
	return {
		name = "Random",
		size = { SIZE, SIZE },
		feedback = WARP,
		display = SHOW,
		setup = function(state, scene)
			scene.viewport.transparent_bg = true
			state.warps = warp_set()
			state.current = {}
			state.stage = 1.0
			state.fx = { scribble(), superstar(), balls(), zoom() }
			state.layers = {}
			for index, layer in ipairs(LAYERS) do
				state.layers[index] = { type = layer.type, low = layer.low, high = layer.high, from = layer.from, to = layer.to, flag = layer.flag, left = 0 }
			end
			state.history = {}
			for index = 0, 29 do
				state.history[index] = 0.0
			end
			state.history_at, state.since, state.since_strong = 0, 0, 0
			local ball = Control.new()
			ball.mouse_filter = Control.MOUSE_FILTER_IGNORE
			local material = ShaderMaterial.new()
			material.shader = nari.load(BALL)
			ball.material = material
			scene.canvas:add_child(ball)
			ball.draw:connect(function()
				for _, rect in ipairs(state.ball_rects or {}) do
					ball:draw_rect(rect, Color(1.0, 1.0, 1.0, 1.0))
				end
			end)
			state.ball = ball
			state.ball_material = material
		end,
		step = function(state, audio, scene)
			local function set(key, value)
				scene.engine.set(scene, key, value)
			end
			local sum = 0.0
			for bin = 1, 6 do
				sum = sum + bins.frequency(audio, bin)
			end
			local level = sum * 0.000833333
			state.history[state.history_at] = level
			state.history_at = (state.history_at + 1) % 30
			local mean = 0.0
			for index = 0, 29 do
				mean = mean + state.history[index]
			end
			mean = mean / 30
			state.since = state.since + 1
			state.since_strong = state.since_strong + 1
			local beat, strong = false, false
			if state.since > 9 and level > mean * 1.1 then
				state.since = 0
				beat = true
				if level > 0.9 and level > mean * 1.2 and state.since_strong > 20 then
					state.since_strong = 0
					strong = true
				end
			end
			state.level, state.bass = level, sum
			for _, layer in ipairs(state.layers) do
				layer.left = layer.left - 1
				if layer.left < 1 then
					retarget(state, layer, set)
				end
			end
			step_warps(state, set)
			state.ball_rects = nil
			for _, fx in ipairs(state.fx) do
				if fx.used then
					fx.step(level, sum, beat, strong)
				end
			end
			local camera = state.fx[4]
			set("crop", camera.used and camera.scale or 1.0)
			state.ball:queue_redraw()
		end,
		draw = function(canvas, state, audio)
			for _, fx in ipairs(state.fx) do
				if fx.used and fx.draw then
					fx.draw(canvas, audio, state.level, state)
				end
			end
			if state.ball_rects then
				local material = state.ball_material
				material:set_shader_parameter("fill", state.ball_fill)
				material:set_shader_parameter("edge", state.ball_edge)
				material:set_shader_parameter("strength", state.ball_strength)
				material:set_shader_parameter("radius", state.ball_radius)
				state.ball:queue_redraw()
			end
		end,
	}
end

return {
	name = "Alchemy",
	presets = { preset() },
}

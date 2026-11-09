local lib = require("lib")
local bins = require("packs.wmp_bins")

local FOLD = "shaders/alchemy_3d/fold.gdshader"
local WORLD = "shaders/alchemy_3d/world.gdshader"
local MONOLITHS = "shaders/alchemy_3d/monoliths.gdshader"
local MUSEUM = "shaders/alchemy_3d/museum.gdshader"
local LUT = "shaders/alchemy_3d/lut.gdshader"
local STAGE = "shaders/alchemy_3d/stage.gdshader"

local SIZE = 256
local SLOTS = {
	{ kind = "shift", low = 1, high = 1, short = 90, long = 500 },
	{ kind = "draw", low = 1, high = 2, short = 50, long = 350 },
	{ kind = "draw", low = 1, high = 3, short = 50, long = 350 },
	{ kind = "bass", low = 0, high = 1, short = 50, long = 400 },
}
local WEIGHT = { star = 0.5, wave = 1.0, ball = 0.9 }
local NO_SCOPE = Color(-1.0, 0.0, 0.0, 0.0)

local function rnd(low, high)
	return low + (high - low) * math.random()
end

local function new_tint()
	return { r = math.random(), g = math.random(), b = math.random() }
end

local function wander(item)
	item.at = item.at + 1
	if item.at > item.span then
		item.from, item.to = item.to, new_tint()
		item.at, item.span = 0, math.random(1, 100)
	end
	local t = math.sin(item.at / math.max(item.span, 1) * 1.5708)
	return Color(item.from.r + (item.to.r - item.from.r) * t, item.from.g + (item.to.g - item.from.g) * t, item.from.b + (item.to.b - item.from.b) * t, 1.0)
end

local function new_wander()
	return { from = new_tint(), to = new_tint(), at = 0, span = 100 }
end

local function linear_map()
	local dx, dy = 0, 0
	while dx == 0 and dy == 0 do
		dx, dy = math.random(0, 6) - 3, math.random(0, 6) - 3
	end
	local switch = math.random(0, 2) ~= 0 and 1.0 or 0.0
	return 0, Color(dx, dy, rnd(0.0, 0.1), rnd(0.0, 0.1)), Color(switch, math.random(0, 7), math.random(0, 2), math.random(1, 15))
end

local function stretch_map()
	local wavy = math.random(0, 1) == 0
	local rotate = wavy and rnd(-0.22, 0.22) or rnd(-0.1, 0.1)
	local moved = math.random(0, 1) == 0
	local cx, cy = SIZE / 2, SIZE / 2
	if moved then
		cx, cy = SIZE * rnd(0.05, 0.95), SIZE * rnd(0.05, 0.95)
	end
	return 1, Color(rotate, wavy and 1.0 or 0.0, math.random(1, 15), rnd(0.05, 0.3)), Color(cx, cy, 0.0, 0.0)
end

local function funk_map()
	return 2, Color(math.random(1, 40), math.random(1, 4), math.random(0, 3) == 0 and 1.0 or 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0)
end

local function scope_map()
	local mode = math.random(0, 4)
	local cell = 1.0
	if mode == 4 and math.random(0, 9) == 0 then
		cell = math.random(1, 300)
	end
	local radius, ring = 0, 0
	if mode == 3 then
		radius, ring = math.random(5, 254), math.random(3, 52)
	end
	local slices = mode == 2 and math.random(3, 12) or 0
	local inner = math.random(0, 3)
	local kind, a, b
	if inner == 0 then
		kind, a, b = stretch_map()
	elseif inner == 1 then
		kind, a, b = linear_map()
	elseif inner == 2 then
		kind, a, b = funk_map()
	else
		kind, a, b = 3, Color(rnd(-0.1, 0.1), 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0)
	end
	return kind, a, b, Color(mode, radius, ring, mode == 2 and slices or cell)
end

local MAPS = { scope_map, scope_map, scope_map, scope_map, linear_map, linear_map, stretch_map, stretch_map, funk_map, funk_map }

local function bake(lut)
	local function apply(suffix)
		local make = MAPS[math.random(#MAPS)]
		local kind, a, b, c = make()
		local m = lut.material
		m:set_shader_parameter("kind" .. suffix, kind)
		m:set_shader_parameter("a" .. suffix, a)
		m:set_shader_parameter("b" .. suffix, b)
		m:set_shader_parameter("c" .. suffix, c or NO_SCOPE)
	end
	apply("1")
	if math.random(0, 4) == 0 then
		apply("2")
	else
		lut.material:set_shader_parameter("kind2", -1)
	end
	lut.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
end

local function new_lut(parent)
	local viewport = SubViewport.new()
	viewport.size = Vector2i(SIZE, SIZE)
	viewport.disable_3d = true
	viewport.use_hdr_2d = true
	viewport.transparent_bg = false
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	parent:add_child(viewport)
	local rect = ColorRect.new()
	rect.size = Vector2(SIZE, SIZE)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = ShaderMaterial.new()
	rect.material.shader = nari.load(LUT)
	viewport:add_child(rect)
	return { viewport = viewport, material = rect.material }
end

local function shift_select(state)
	if state.fade_span then
		state.fade_at = state.fade_span
	end
	local next_lut = state.lut_at == 1 and 2 or 1
	bake(state.luts[next_lut])
	state.fade_target = next_lut
	state.fade_at = 0
	state.fade_span = 22 * (math.random(0, 2) == 0 and math.random(1, 15) or math.random(10, 14))
	state.fade_mode = math.random(0, 2)
end

local function star_select(effect)
	effect.scale = rnd(0.2, 1.0)
	local n = math.random(0, 11) + 3
	if n == 5 or n == 6 then
		n = n + (math.random(0, 2) == 0 and 15 or 2)
	end
	effect.points = n
	effect.speed = rnd(-0.3, 0.3)
end

local function wave_select(effect)
	effect.width = math.random(0, 2)
	effect.steps = math.random(10, 521)
	effect.window = math.random(0, 2)
	effect.cycles = math.random(1, 4)
	effect.amp = rnd(0.1, 0.5)
	effect.rate = rnd(-0.1, 0.1)
	effect.turn_mode = math.random(0, 3)
	effect.punch = math.random(0, 1) == 0
	effect.cross = math.random(0, 2) == 0
	effect.spread = math.random(0, 2) == 0
	effect.cross_mode = math.random(0, 2)
	effect.offset = rnd(0, 6.2831853)
end

local function ball_select(effect)
	effect.x, effect.y = rnd(0, SIZE), rnd(0, SIZE)
	effect.vx, effect.vy = rnd(-3, 3), rnd(-3, 3)
	effect.target = rnd(4, 24)
	effect.radius, effect.speed = effect.target, 0
	effect.damp = rnd(0.5, 0.95)
	effect.flash = 0
	effect.invert = false
end

local function bass_select(effect)
	effect.punch = rnd(0.13, 0.25)
	effect.bounce = rnd(0.05, 0.2)
	effect.period = math.random(25, 55)
	effect.z = 1.0
	effect.count = 0
end

local function new_effects()
	local effects = {
		star = { name = "star", kind = "draw", select = star_select, tint_a = new_wander(), tint_b = new_wander(), angle = 0 },
		wave = { name = "wave", kind = "draw", select = wave_select, tint_a = new_wander(), tint_b = new_wander(), angle = 0 },
		ball = { name = "ball", kind = "draw", select = ball_select, tint_a = new_wander(), tint_b = new_wander() },
		bass = { name = "bass", kind = "bass", select = bass_select },
	}
	return effects
end

local function pick_slot(state, slot)
	if slot.active then
		for _, effect in ipairs(slot.active) do
			effect.live = false
		end
	end
	slot.active = {}
	slot.timer = math.random(slot.short, slot.long)
	local want = slot.low == slot.high and slot.low or math.random(slot.low, slot.high)
	if slot.kind == "shift" then
		shift_select(state)
		return
	end
	for _ = 1, 100 do
		if want <= 0 then
			break
		end
		local names = slot.kind == "bass" and { "bass" } or { "star", "wave", "ball" }
		local effect = state.effects[names[math.random(#names)]]
		if not effect.live and math.random() <= (WEIGHT[effect.name] or 0.5) then
			effect.live = true
			effect.select(effect)
			slot.active[#slot.active + 1] = effect
			want = want - 1
		end
	end
end

local function wave_value(audio, at, count, amp, window, cycles)
	local value = bins.sample(audio, at / count) * amp
	if window == 0 then
		return value * math.abs(math.sin(at / count * cycles * math.pi))
	elseif window == 1 then
		local half = count / 2
		return value * ((at < half and at or count - at) / half)
	end
	return value
end

local function line(state, audio, x1, y1, x2, y2, a, b, steps, amp, window, cycles, width, halo)
	local dx, dy = x2 - x1, y2 - y1
	local count = math.max(2, math.min(steps, math.floor(math.max(math.abs(dx), math.abs(dy))) + 1))
	local angle = math.atan(dy, dx) + 1.5708
	local nx, ny = math.cos(angle), math.sin(angle)
	local points, colors = {}, {}
	for index = 0, count - 1 do
		local t = index / (count - 1)
		local off = wave_value(audio, index, count, amp, window, cycles)
		points[index + 1] = Vector2(x1 + dx * t + nx * off, y1 + dy * t + ny * off)
		colors[index + 1] = lib.mix(a, b, math.abs(math.sin(t * 3.1415927)))
	end
	state.lines[#state.lines + 1] = { points = points, colors = colors, width = width, halo = halo }
end

local function run_star(state, effect, audio)
	local a, b = wander(effect.tint_a), wander(effect.tint_b)
	effect.angle = (effect.angle + state.high * effect.speed) % 6.2831853
	local radius = state.energy * (SIZE / 2) * effect.scale
	local step = 6.2831853 / effect.points * ((effect.points >> 1) + ((effect.points == 10 or effect.points == 14) and 2 or 1))
	local c = SIZE / 2
	local angle = effect.angle
	local x, y = c + math.cos(angle) * radius, c + math.sin(angle) * radius
	for _ = 0, effect.points do
		angle = angle + step
		local nx, ny = c + math.cos(angle) * radius, c + math.sin(angle) * radius
		line(state, audio, x, y, nx, ny, a, b, 50, 50, 0, 2, 3, 0.5)
		x, y = nx, ny
	end
end

local function run_wave(state, effect, audio)
	local a, b = wander(effect.tint_a), wander(effect.tint_b)
	local amp = SIZE * effect.amp
	local reach = SIZE * 1.4142
	if effect.punch then
		reach = reach * state.energy
	end
	reach = reach * 0.5
	local c = SIZE / 2
	local function through(angle)
		local cx, sy = math.cos(angle) * reach, math.sin(angle) * reach
		line(state, audio, c + cx, c + sy, c - cx, c - sy, a, b, effect.steps, amp, effect.window, effect.cycles, effect.width, 0.1)
	end
	through(effect.angle + 0.7854)
	if effect.cross then
		if effect.cross_mode == 0 then
			effect.offset = effect.offset - effect.rate * state.energy * 0.5
		end
		through(effect.cross_mode == 2 and effect.angle or effect.offset + effect.angle)
	end
	if effect.turn_mode == 0 then
		effect.angle = effect.angle + effect.rate
	elseif effect.turn_mode == 1 then
		effect.angle = effect.angle + effect.rate * state.energy
	elseif effect.turn_mode == 2 then
		effect.angle = effect.angle + effect.rate * state.energy * state.energy
	end
end

local function run_ball(state, effect, audio)
	effect.x, effect.y = effect.x + effect.vx, effect.y + effect.vy
	if effect.x < 0 or effect.x > SIZE then
		effect.vx = -effect.vx
	else
		effect.vx = effect.vx + (math.random(0, 1) * 2 - 1) * state.energy
		effect.vx = math.max(-6, math.min(6, effect.vx))
	end
	if effect.y < 0 or effect.y > SIZE then
		effect.vy = -effect.vy
	else
		effect.vy = effect.vy + (math.random(0, 1) * 2 - 1) * state.energy
		effect.vy = math.max(-6, math.min(6, effect.vy))
	end
	effect.speed = (effect.speed + (effect.target - effect.radius) + state.energy * 3) * effect.damp * 0.5
	effect.radius = effect.radius + effect.speed
	local radius = math.max(1, math.floor(effect.radius) + 1)
	local halo = state.energy
	if state.beat then
		halo = 0.4
		effect.invert = not effect.invert
		radius = radius * 2
		effect.flash = 5
	end
	local tint = wander(effect.tint_a)
	if effect.invert then
		tint = Color(1.0 - tint.r, 1.0 - tint.g, 1.0 - tint.b, 1.0)
	end
	local other = wander(effect.tint_b)
	if effect.flash > 0 then
		line(state, audio, effect.x, effect.y, SIZE - effect.x, SIZE - effect.y, tint, other, 500, 50, 0, 2, 1, 0.5)
		effect.flash = effect.flash - 1
	end
	local m = state.stage_material
	m:set_shader_parameter("ball1", Color(effect.x, effect.y, radius, math.min(1.0, halo)))
	m:set_shader_parameter("ball2", Color(SIZE - effect.x, SIZE - effect.y, radius, math.min(1.0, halo)))
	m:set_shader_parameter("ball_color", tint)
	state.ball_on = true
end

local function run_bass(state, effect)
	if state.strong then
		effect.z = effect.punch
		effect.count = 0
	end
	local f = math.sin((effect.count % effect.period) / effect.period * 6.2831853) * effect.bounce + 1 - effect.bounce
	effect.z = math.min(1.0, (15 * effect.z + f) * 0.0625)
	effect.count = effect.count + 1
	state.crop = effect.z
end

local function step_stage(state, audio, scene)
	local e = 0
	for bin = 1, 5, 2 do
		e = e + bins.frequency(audio, bin)
	end
	e = e * 2 * 0.000833333
	state.energy = e
	local hi = bins.frequency(audio, 501) + bins.frequency(audio, 503) + bins.frequency(audio, 505)
	state.high = hi * 2 * 0.000833333
	state.history[state.history_at] = e
	state.history_at = state.history_at % 30 + 1
	local mean = 0
	for index = 1, 30 do
		mean = mean + state.history[index]
	end
	mean = mean / 30
	state.since, state.since_strong = state.since + 1, state.since_strong + 1
	state.beat, state.strong = false, false
	if state.since >= 10 and mean * 1.1 < e then
		state.since, state.beat = 0, true
		if e > 0.9 and mean * 1.2 < e and state.since_strong > 20 then
			state.since_strong, state.strong = 0, true
		end
	end

	for _, slot in ipairs(SLOTS) do
		local holder = state.slots[slot]
		holder.timer = holder.timer - 1
		if holder.timer < 1 then
			pick_slot(state, holder)
		end
	end

	if state.fade_target then
		state.fade_at = state.fade_at + 1
		local t
		if state.fade_mode == 0 then
			t = math.max(0, math.sin(state.fade_at / state.fade_span * 1.5708))
		else
			t = math.floor(state.fade_at / state.fade_span * 22) / 22
		end
		local slot = state.fade_target
		local m = state.stage_material
		m:set_shader_parameter("fade", slot == 2 and math.min(t, 1.0) or 1.0 - math.min(t, 1.0))
		if state.fade_at >= state.fade_span then
			state.lut_at, state.fade_target = slot, nil
		end
	end

	state.lines = {}
	state.ball_on = false
	state.crop = 1.0
	if state.effects.star.live then
		run_star(state, state.effects.star, audio)
	end
	if state.effects.wave.live then
		run_wave(state, state.effects.wave, audio)
	end
	if state.effects.ball.live then
		run_ball(state, state.effects.ball, audio)
	end
	if not state.ball_on then
		local m = state.stage_material
		m:set_shader_parameter("ball1", Color(-100.0, -100.0, 0.0, 0.0))
		m:set_shader_parameter("ball2", Color(-100.0, -100.0, 0.0, 0.0))
	end
	if state.effects.bass.live then
		run_bass(state, state.effects.bass)
	end
	state.frame = state.frame + 1
	state.stage_material:set_shader_parameter("frame", state.frame)
	state.ink:queue_redraw()
	state.stage.render_target_update_mode = SubViewport.UPDATE_ONCE
	scene.engine.set(scene, "crop", state.crop)
end

local function setup_stage(state, scene)
	local stage = SubViewport.new()
	stage.size = Vector2i(SIZE, SIZE)
	stage.disable_3d = true
	stage.transparent_bg = false
	stage.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	stage.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	stage.render_target_update_mode = SubViewport.UPDATE_ONCE
	scene.area:add_child(stage)
	state.luts = { new_lut(stage), new_lut(stage) }
	bake(state.luts[1])
	state.lut_at = 1
	local rect = ColorRect.new()
	rect.size = Vector2(SIZE, SIZE)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = ShaderMaterial.new()
	rect.material.shader = nari.load(STAGE)
	rect.material:set_shader_parameter("lut_a", state.luts[1].viewport:get_texture())
	rect.material:set_shader_parameter("lut_b", state.luts[2].viewport:get_texture())
	stage:add_child(rect)
	local ink = Control.new()
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink.size = Vector2(SIZE, SIZE)
	stage:add_child(ink)
	ink.draw:connect(function()
		for _, item in ipairs(state.lines or {}) do
			if item.width >= 2 then
				ink:draw_polyline_colors(item.points, item.colors, 2.5)
			else
				if item.width == 1 and item.halo > 0 then
					local dim = {}
					for index, color in ipairs(item.colors) do
						dim[index] = lib.alpha(color, item.halo)
					end
					ink:draw_polyline_colors(item.points, dim, 3.0)
				end
				ink:draw_polyline_colors(item.points, item.colors, 1.0)
			end
		end
	end)
	state.stage, state.ink, state.stage_material = stage, ink, rect.material
	state.effects = new_effects()
	state.slots = {}
	for _, slot in ipairs(SLOTS) do
		state.slots[slot] = { kind = slot.kind, low = slot.low, high = slot.high, short = slot.short, long = slot.long, timer = 0 }
	end
	state.history, state.history_at = {}, 1
	for index = 1, 30 do
		state.history[index] = 0
	end
	state.since, state.since_strong, state.frame = 0, 0, 0
	state.energy, state.high = 0, 0
	state.lines = {}
	scene.engine.set(scene, "rt", stage:get_texture())
end

local function preset(name, options)
	return {
		name = name,
		layers = { options.display },
		aspect = options.aspect,
		params = options.params,
		setup = function(state, scene)
			state.time = 0
			setup_stage(state, scene)
			if options.textures then
				for key, path in pairs(options.textures) do
					scene.engine.set(scene, key, nari.load(path))
				end
			end
		end,
		step = function(state, audio, scene)
			state.time = state.time + 1 / 30
			scene.engine.set(scene, "time", state.time)
			step_stage(state, audio, scene)
		end,
	}
end

return {
	name = "3D Alchemy",
	presets = {
		preset("Classic", { display = FOLD, params = { cells = 1.0, mirror = 0.0, turn = 4.7124 } }),
		preset("Kaleidoscope", { display = FOLD, params = { cells = 1.3148, mirror = 1.0, turn = 0.0 } }),
		preset("Monoliths", { display = MONOLITHS, aspect = 4 / 3, textures = { logo = "assets/alchemy_3d/logo.png" } }),
		preset("Strange world", { display = WORLD, aspect = 4 / 3 }),
		preset("WM Museum", { display = MUSEUM, aspect = 4 / 3, textures = { paint1 = "assets/alchemy_3d/paint1.jpg", paint2 = "assets/alchemy_3d/paint2.jpg", paint3 = "assets/alchemy_3d/paint3.jpg", paint4 = "assets/alchemy_3d/paint4.jpg", paint5 = "assets/alchemy_3d/paint5.jpg" } }),
	},
}

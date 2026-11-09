local measure = require("packs.measuring_spectrum")
local bins_of = require("packs.wmp_bins")
local generated = require("packs.glass3d_warps")

local TAU = math.pi * 2
local WIDE, TALL = 640, 480
local CELLS_X, CELLS_Y = 160, 120
local SQUARE = WIDE // 32

local function rnd(limit)
	return math.random() * limit
end

local function irand(limit)
	return math.floor(math.random() * limit)
end

local function status(a, b)
	if a ~= a or b ~= b then
		return 0x4500
	end
	if a > b then
		return 0
	end
	if a < b then
		return 0x100
	end
	return 0x4000
end

local function even(v)
	local n, c = v & 255, 0
	while n > 0 do
		c = c + (n & 1)
		n = n >> 1
	end
	return c % 2 == 0
end

local function sbyte(v)
	local b = v & 255
	return b >= 128 and b - 256 or b
end

local memo = {}
local warps = generated(
	rnd,
	function() return math.random() * 0.02 - 0.01 end,
	irand,
	function(v) return v > 0.0 and v or 0.0 end,
	math.sin, math.cos,
	function(v) return math.sqrt(math.max(v, 0.0)) end,
	math.abs, math.atan, function(v) return math.floor(v + (v < 0 and 1 or 0)) end,
	status, even, sbyte, memo
)

local function pick_warp(state)
	local G = {}
	state.warp_count = (state.warp_count or 0) + 1
	local index
	if state.warp_count < 6 then
		index = 6
	else
		local roll = irand(0x42)
		index = roll < 0x10 and 1 or roll < 0x1c and 2 or roll < 0x2a and 3 or roll < 0x39 and 4 or roll < 0x42 and 5 or 6
	end
	local list = warps.cats[index]
	local effect = warps.effects[list[irand(#list) + 1]]
	local params
	effect(G, function(a, b, c, d, e, polar, aspect, first, second)
		params = { a = a * 1.0, b = b * 1.0, c = c * 1.0, d = d * 1.0, e = e * 1.0, polar = polar ~= 0, aspect = aspect ~= 0, first = first, second = second, x = 0.0, y = 0.0, r = 0.0, t = 0.0 }
	end)
	state.building = params
	state.forced = G.d10028fd0
	state.row = 0
end

local function build_rows(state, scene)
	local p = state.building
	if not p then
		return
	end
	local image = state.images[state.spare]
	local sx, sy = 2.0 / WIDE, 2.0 / TALL
	if p.aspect then
		sx = math.max(sx, sy)
		sy = sx
	end
	local cos, sin, sqrt, atan = math.cos, math.sin, math.sqrt, math.atan
	local first, second, polar = p.first, p.second, p.polar
	for _ = 1, 8 do
		local row = state.row
		if row >= CELLS_Y then
			state.images[state.spare] = image
			state.textures[state.spare]:update(image)
			scene.engine.set(scene, "warp", state.textures[state.spare])
			state.spare = 3 - state.spare
			state.building = nil
			state.wanted = true
			return
		end
		local py = (row + 0.5) * TALL / CELLS_Y
		local y = (2.0 * py - TALL) * sy * 0.5
		for column = 0, CELLS_X - 1 do
			local px = (column + 0.5) * WIDE / CELLS_X
			local x = (2.0 * px - WIDE) * sx * 0.5
			p.x, p.y = x, y
			p.r = sqrt(x * x + y * y)
			p.t = atan(y, x)
			local a, b = first(p), second(p)
			if polar then
				a, b = a * cos(b), a * sin(b)
			end
			local dx = math.max(-63.0, math.min(63.0, (a - x) / sx))
			local dy = math.max(-63.0, math.min(63.0, (b - y) / sy))
			image:set_pixel(column, row, Color(dx, dy, 0.0, 1.0))
		end
		state.row = row + 1
	end
end

local function spectrum_table(state, audio)
	local fill = state.bins
	state.band_gain = audio.stereo and 1.0 or 0.35
	for bin = 0, 255 do
		fill[bin] = measure.bin(audio, bin * 4 + 2)
	end
end

local function bands(state, count)
	local out = state.v
	local bins = state.bins
	local step = 256.0 / count
	for index = 0, count - 1 do
		local first = math.floor(index * step)
		local last = math.min(255, math.floor((index + 1) * step))
		local total = 0.0
		for bin = first, last do
			total = total + bins[bin]
		end
		out[index] = math.max(0, math.floor(total * state.band_gain / (last - first + 1) - 1) * 16)
	end
	return out
end

local function tint(state)
	local v = bands(state, 7)
	local r = math.max(v[1] // 2, v[0]) * 31
	local g = math.max(v[2], v[3]) * 31
	local b = math.max(v[4], v[5], v[6]) * 31
	local step = state.loud and 4 or 1
	local top = state.top
	for pass = 1, 8 do
		for channel, target in ipairs({ r, g, b }) do
			local value = target & 255
			if value <= top[channel] then
				top[channel] = math.max(0, top[channel] - 1)
			else
				top[channel] = math.min(255, top[channel] + step)
			end
		end
	end
	state.cursor = (state.cursor + 1) % 33
	local at = state.cursor * 3
	state.history[at + 1], state.history[at + 2], state.history[at + 3] = top[1] * 1.0, top[2] * 1.0, top[3] * 1.0
end

local function pen(state, width, density)
	state.width = math.max(1, width)
	state.ink = Color(0.996, 0.996, 0.996, math.min(1.0, density / 65535.0))
end

local function line(canvas, state, x0, y0, x1, y1)
	local width, ink = state.width, state.ink
	x0 = math.max(1, math.min(WIDE - 2, x0))
	x1 = math.max(1, math.min(WIDE - 2, x1))
	y0 = math.max(1, math.min(TALL - 2, y0))
	y1 = math.max(1, math.min(TALL - 2, y1))
	if x0 == x1 and y0 == y1 then
		if width < 2 then
			canvas:draw_rect(Rect2(x0, y0, 1, 1), ink)
		else
			canvas:draw_circle(Vector2(x0, y0), width * 0.5, ink)
		end
		return
	end
	canvas:draw_line(Vector2(x0, y0), Vector2(x1, y1), ink, width)
	if width >= 3 then
		canvas:draw_circle(Vector2(x0, y0), width * 0.5, ink)
		canvas:draw_circle(Vector2(x1, y1), width * 0.5, ink)
	end
end

local function polar(state, angle, radius)
	return math.floor(math.cos(angle + state.phase) * radius) + WIDE // 2, math.floor(math.sin(angle + state.phase) * radius) + TALL // 2
end

local MODE_COUNT = {
	[0] = 128, [2] = 109, [3] = 109, [4] = 109, [5] = 143, [6] = 109, [7] = 109, [8] = 109,
	[9] = 256, [10] = 256, [11] = 256, [12] = 109, [13] = 109, [14] = 128, [20] = 109, [22] = 109, [23] = 109, [102] = 8, [103] = 32, [119] = 255,
}

local function stars(canvas, state, kind)
	local K, W = state.K, state.W
	local count = 64
	for index = 1, count do
		local star = state.stars[index]
		local depth = star[3]
		if kind == 10 then
			pen(state, math.floor(((WIDE >> 5) / (depth + 1.0)) * W * K) + 1, state.loud and 15000 or 65535)
			star[3] = depth + 0.5
			if star[3] >= 16.0 then
				star[1], star[2], star[3] = irand(TALL) - TALL // 2, irand(WIDE) - WIDE // 2, irand(8) * 1.0
				pen(state, 32, 2000)
			end
		else
			pen(state, math.floor(((WIDE >> 5) / (depth + 1.0)) * (kind == 11 and W or 1) * K) + 1, (kind == 11 and state.loud) and 15000 or 65535)
			star[3] = depth - 0.5
			if star[3] <= 0.0 then
				star[1], star[2], star[3] = irand(TALL) - TALL // 2, irand(WIDE) - WIDE // 2, irand(8) + 16.0
				if kind == 11 then
					pen(state, 32, 1000)
				end
			elseif kind == 11 and star[3] == 1.0 then
				pen(state, 10, 5000)
			end
		end
		local x = math.floor((star[2] / (depth + 1.0)) * K) + WIDE // 2
		local y = math.floor((star[1] / (depth + 1.0)) * K) + TALL // 2
		line(canvas, state, x, y, x, y)
	end
end

local function burst(canvas, state, cx, cy, spread, count, width, density)
	pen(state, width, density)
	for _ = 1, count do
		local a, r = math.random() * TAU, math.random() ^ 2 * spread
		local x, y = math.floor(cx + math.cos(a) * r), math.floor(cy + math.sin(a) * r)
		line(canvas, state, x, y, x, y)
	end
end

local function star_lines(canvas, state, values, scale)
	local K, W = state.K, state.W
	local table_cos, table_sin = state.cos, state.sin
	for index = 1, 63 do
		local a = values[index - 1] * W * K * scale
		local b = values[index] * W * K * scale
		line(canvas, state, math.floor(a * table_cos[index]) + WIDE // 2, math.floor(a * table_sin[index]) + TALL // 2, math.floor(b * table_cos[index + 1]) + WIDE // 2, math.floor(b * table_sin[index + 1]) + TALL // 2)
	end
end

local function draw_mode(canvas, state, mode, audio)
	local K, W, peak = state.K, state.W, state.peak
	if mode == 1 or (mode >= 15 and mode <= 19) then
		local v = bands(state, 128)
		for index = 0, 5 do
			v[index] = v[index] // (3 - index // 2)
		end
		for index = 0, 63 do
			v[index] = math.min(v[index], 400) * 0.002
		end
		if mode == 17 then
			for index = 1, 63 do
				pen(state, (peak * peak) // 600000 + 1, peak)
				local r = v[index] * K * W * 50.0
				local x = math.floor(r * state.cos[index]) + WIDE // 2
				local y = math.floor(r * state.sin[index]) + TALL // 2
				line(canvas, state, x, y, x, y)
			end
		elseif mode == 18 then
			pen(state, 1, 65535)
			star_lines(canvas, state, v, 15.0)
		elseif mode == 19 then
			pen(state, 1, 65535)
			star_lines(canvas, state, v, 25.0)
			burst(canvas, state, irand(WIDE), irand(TALL), peak * 0.02, peak // 16, 1, 65535)
		else
			pen(state, 2, 65535)
			star_lines(canvas, state, v, 25.0)
		end
		return
	end
	local count = MODE_COUNT[mode] or 109
	local v = bands(state, count + 1)
	local D = TAU / count
	local phase = state.phase
	if mode == 4 then
		pen(state, 1, 65535)
		for index = 0, 254 do
			line(canvas, state, index / 255 * WIDE, bins_of.wave(audio, index * 4) * K, (index + 1) / 255 * WIDE, bins_of.wave(audio, (index + 1) * 4) * K)
		end
		return
	end
	if mode == 21 then
		for _ = 1, 2 do
			local spread = peak * 0.05 * K
			burst(canvas, state, irand(WIDE), irand(TALL), spread, peak // 16, 1, 65535)
		end
		return
	end
	if mode == 9 or mode == 10 or mode == 11 then
		stars(canvas, state, mode)
		return
	end
	if mode == 0 or mode == 14 then
		pen(state, 1, 65535)
		local cx = TALL // 2
		local previous = 0
		for index = 1, count do
			if irand(5) == 0 then
				pen(state, 1, 65535)
			else
				pen(state, math.floor(((v[index] >> 7) * W) * K) + 1, state.loud and 5000 or 15000)
			end
			local h = math.floor(math.min(v[index] * K * W * 0.05, 240.0))
			local x0 = math.floor((index - 1) * WIDE / count)
			local x1 = math.floor(index * WIDE / count)
			line(canvas, state, x0, cx - previous - 8, x1, cx - h - 8)
			line(canvas, state, x0, cx + previous + 8, x1, cx + h + 8)
			previous = h
		end
		return
	end
	for index = 1, count do
		local value = v[index]
		if mode == 2 then
			pen(state, 2, 65535)
			local a = index * D
			local r = (math.cos(state.a70 * a) * 20.0 + (peak / 50.0 - 50.0)) * K * W
			local b = (index + 1) * D
			local q = (math.cos(state.a70 * b) * 20.0 + (peak / 50.0 - 50.0)) * K * W
			local x0, y0 = polar(state, a, r)
			local x1, y1 = polar(state, b, q)
			line(canvas, state, x0, y0, x1, y1)
		elseif mode == 3 or mode == 23 then
			pen(state, (mode == 23) and W * W or math.floor((value >> 6) * K) + 1, (mode == 23) and 65535 // (W * W) or 15000)
			local a = index * D
			local r = math.cos(state.a70 * a) * 20.0 + value * K * W * 0.333333
			local x0, y0 = polar(state, a, r)
			line(canvas, state, x0, y0, x0, y0)
		elseif mode == 5 then
			pen(state, 2, 65535)
			local a = (index - 1) * D * 5.0
			local b = index * D * 5.0
			local x0, y0 = polar(state, a, W * (a / math.pi * 0.5 + a * 3.18471 + value * 0.002) * K)
			local x1, y1 = polar(state, b, W * (b / math.pi * 0.5 + b * 3.18471 + value * 0.002) * K)
			line(canvas, state, x0, y0, x1, y1)
		elseif mode == 6 then
			pen(state, math.floor((value >> 6) * W * K) + 1, 15000)
			local a = index * D * 3.0
			local x0, y0 = polar(state, a, index * W * K + index + a * 11.1465)
			line(canvas, state, x0, y0, x0, y0)
		elseif mode == 7 or mode == 20 then
			local beat = mode == 7 and (peak * peak) // 400000 or peak // 50
			pen(state, math.floor((value >> 6) * W * K) + 1, 15000)
			local a = (index - 1) * D * 3.0
			local b = index * D * 3.0
			local x0, y0 = polar(state, a, ((count - index + 1) * beat + a * 1.59236) * K * W * 0.0166667)
			local x1, y1 = polar(state, b, ((count - index) * beat + b * 1.59236) * K * W * 0.0166667)
			line(canvas, state, x0, y0, x1, y1)
		elseif mode == 8 then
			pen(state, math.floor(((value >> 6) * W + (value >> 12)) * K) + 1, state.loud and 5000 or 15000)
			local x, y = irand(WIDE), irand(TALL)
			line(canvas, state, x, y, x, y)
		elseif mode == 12 then
			pen(state, 2, 65535)
			local a = index * D
			local r = (math.cos(state.a78 * a) * 20.0 + (peak // 50 - 50)) * K * W
			local x0, y0 = polar(state, a, r)
			local b = (index + 1) * D
			local q = (math.cos(state.a78 * b) * 20.0 + (peak // 50 - 50)) * K * W
			local x1, y1 = polar(state, b, q)
			line(canvas, state, x0, y0, x1, y1)
		elseif mode == 13 then
			pen(state, math.floor((value >> 6) * K) + 1, 65535)
			local a = index * D
			local x0, y0 = polar(state, a, (math.cos(state.a70 * a) * 20.0 + value * 0.05) * W * K)
			line(canvas, state, x0, y0, x0, y0)
			pen(state, (peak // 1000) * W + 1, 5000)
			x0, y0 = polar(state, a, (math.cos(state.a80 * a) * 20.0 + value * 0.05) * W * K)
			line(canvas, state, x0, y0, x0, y0)
		end
	end
end

local function overlay(canvas, state, id)
	local K = state.K
	if id == 119 then
		return
	end
	if id == 102 or id == 103 then
		local count = state.ring_count
		local wide = state.ring_wide
		for index = 0, count do
			if wide then
				pen(state, (TALL * 5) // 400 + 1, 65535)
			else
				pen(state, math.floor(state.peak * 0.0002 * K) + 1, 15000)
			end
			local a = (state.ring_step * index + state.ring_turn) * 2 * math.pi * 0.000976562
			local b = (state.ring_step * (index + 1) + state.ring_turn) * 2 * math.pi * 0.000976562
			local reach = math.cos(state.ring_lobes * a) * 200.0 * -0.00190476 * K
			local next_reach = math.cos(state.ring_lobes * b) * 200.0 * -0.00190476 * K
			local x0 = WIDE // 2 + math.floor(math.sin(a) * WIDE * 0.5 * reach)
			local y0 = TALL // 2 + math.floor(math.cos(a) * TALL * 0.5 * reach)
			local x1 = WIDE // 2 + math.floor(math.sin(b) * WIDE * 0.5 * next_reach)
			local y1 = TALL // 2 + math.floor(math.cos(b) * TALL * 0.5 * next_reach)
			line(canvas, state, x0, y0, x1, y1)
		end
		state.ring_turn = (state.ring_turn + 1) % 1024
		return
	end
	draw_mode(canvas, state, id, state.audio)
end

local function choose_mode(state)
	local mode = state.forced
	if mode == nil or mode < 0 then
		mode = irand(22) + (irand(100) < 4 and 1 or 0)
	end
	state.mode = mode
	state.pre_blur = irand(2) == 0
	if mode == 21 then
		state.pre_blur = true
	elseif mode == 0 or mode == 4 or mode == 19 then
		state.pre_blur = false
	end
	state.overlay = nil
	if (mode < 8 or mode > 11) and irand(40) > 0 then
		local kind = mode == 5 and 2 or irand(6)
		state.overlay = ({ [0] = 9, 10, 8, 102, 11, 103 })[kind]
		state.ring_count = irand(32) + 4
		state.ring_step = irand(64) + 2
		state.ring_lobes = irand(10) + 1
		state.ring_wide = irand(2) == 0
		state.ring_turn = 0
	end
	state.blobs = irand(100) < 46
	state.a70, state.a80, state.a78 = irand(10) + 1.0, irand(10) + 1.0, irand(10) + 1.0
	if irand(1000) < 500 then
		state.a78 = -state.a78
	end
end

local function caption(scene, state, theme)
	local title = Label.new()
	title.add_theme_font_size_override(title, "font_size", 13)
	title.add_theme_color_override(title, "font_color", Color(1.0, 1.0, 1.0, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.area:add_child(title)
	state.title = title
	state.title_for = 0
	if theme then
		local name = Label.new()
		name.add_theme_font_size_override(name, "font_size", 13)
		name.add_theme_color_override(name, "font_color", Color(1.0, 0.0, 0.0, 1.0))
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name.text = theme
		scene.area:add_child(name)
		state.theme = name
		state.theme_at = 0
	end
	scene.viewport.tree_exiting:connect(function()
		title:queue_free()
		if state.theme then
			state.theme:queue_free()
		end
	end)
end

local function update_caption(state, scene)
	local song = nari.current and nari.current() or nil
	local text = song and (song.title or song.name) or ""
	local area = scene.area.size
	if text ~= state.track then
		state.track = text
		state.title.text = text
		state.title_for = 300
	end
	state.title_for = state.title_for - 1
	state.title.visible = state.title_for > 0
	state.title.position = Vector2(15.0, area.y - 20.0)
	if state.theme then
		state.theme_at = state.theme_at + 1
		if state.theme_at > 150 and state.theme_at % 2 == 0 and #state.theme.text > 0 then
			state.theme.text = state.theme.text:sub(1, -2)
		end
		state.theme.position = Vector2(area.x - 5.0 - #state.theme.text * 7.0, area.y - 20.0)
	end
end

local function animator(name, title)
	return {
		name = name,
		size = { WIDE, TALL },
		feedback = "shaders/glass3d/animator.gdshader",
		display = "shaders/glass3d/palette.gdshader",
		setup = function(state, scene)
			local material = ShaderMaterial.new()
			material.shader = nari.load("shaders/glass3d/pen.gdshader")
			scene.canvas.material = material
			scene.materials[#scene.materials + 1] = material
			state.images = { Image.create(CELLS_X, CELLS_Y, false, Image.FORMAT_RGH), Image.create(CELLS_X, CELLS_Y, false, Image.FORMAT_RGH) }
			state.images[1]:fill(Color(0.0, 0.0, 0.0, 1.0))
			state.images[2]:fill(Color(0.0, 0.0, 0.0, 1.0))
			state.textures = { ImageTexture.create_from_image(state.images[1]), ImageTexture.create_from_image(state.images[2]) }
			scene.engine.set(scene, "warp", state.textures[1])
			state.spare = 2
			state.bins, state.v = {}, {}
			state.top = { 0, 0, 0 }
			state.history = {}
			for index = 1, 99 do
				state.history[index] = 0.0
			end
			state.cursor = 0
			state.K = (WIDE + TALL) * 0.0016666666666666668
			state.W = 1
			state.peak, state.last_peak = 0, 0
			state.phase = 0.0
			state.timer = 0
			state.cos, state.sin = {}, {}
			for index = 0, 64 do
				state.sin[index] = math.sin((index - 2) * math.pi * 0.03225806451612903)
				state.cos[index] = math.cos((index - 2) * math.pi * 0.03225806451612903)
			end
			state.stars = {}
			for index = 1, 64 do
				state.stars[index] = { irand(TALL) - TALL // 2, irand(WIDE) - WIDE // 2, irand(32) * 1.0 }
			end
			caption(scene, state, "Animator classic")
			pick_warp(state)
			choose_mode(state)
		end,
		step = function(state, audio, scene)
			update_caption(state, scene)
			state.audio = audio
			state.peak = (math.floor(bins_of.top(audio)) ^ 2) // 8
			state.loud = state.peak > state.last_peak + 1000
			state.last_peak = state.peak
			state.W = state.loud and 2 or 1
			spectrum_table(state, audio)
			tint(state)
			scene.engine.set(scene, "history", state.history)
			scene.engine.set(scene, "cursor", state.cursor)
			state.timer = state.timer + 1
			if state.timer >= 30 * (state.warp_count < 7 and 15 or 30) then
				state.timer = 0
				pick_warp(state)
			end
			if state.building then
				build_rows(state, scene)
			end
			if state.wanted then
				state.wanted = false
				choose_mode(state)
			end
			local mode = state.mode
			if mode == 3 or mode == 12 or mode == 13 or mode == 23 then
				state.phase = irand(360) * math.pi * 0.005555555555555556
			elseif mode == 6 or mode == 102 or mode == 103 then
				state.phase = state.phase - 1.0
				if state.phase < 0.0 then
					state.phase = TAU
				end
			elseif mode == 2 or mode == 5 then
				state.phase = state.phase + 0.05
				if state.phase > TAU then
					state.phase = 0.0
				end
			elseif mode == 7 or mode == 20 then
				state.phase = state.phase + 1.0
				if state.phase > TAU then
					state.phase = 0.0
				end
			end
			if state.loud and irand(10) < 2 then
				state.a70 = irand(10) + 1.0
			end
		end,
		draw = function(canvas, state, audio)
			draw_mode(canvas, state, state.mode, audio)
			if state.overlay then
				overlay(canvas, state, state.overlay)
			end
			if state.blobs and state.W ~= 1 then
				pen(state, 32, 3000)
				local x, y = irand(WIDE), irand(TALL)
				line(canvas, state, x, y, x, y)
			end
		end,
	}
end

local function flash_color(v)
	local r = (math.max(v[1] // 2, v[0]) * 124) & 0xffff
	local g = (math.max(v[2], v[3]) * 124) & 0xffff
	local b = (math.max(v[4], v[5], v[6]) * 124) & 0xffff
	return Color(r / 65535.0, g / 65535.0, b / 65535.0, 1.0)
end

local function scatter(state, cx, cy, count)
	local dots = state.dots
	local slot = state.slot
	local reach = TALL / 4
	local sin, cos, random = math.sin, math.cos, math.random
	for _ = 1, count do
		if slot >= 2400 then
			break
		end
		local r = random() ^ 2 * reach
		local a = random() * 16.0
		local x = cx + sin(a) * r
		local y = cy + cos(a) * r
		dots[slot + 1], dots[slot + 2] = Vector2(x, y), Vector2(x + 1.0, y + 1.0)
		slot = slot + 2
	end
	state.slot = slot
end

local function walk(value)
	value = value + math.random() * 0.2 - 0.1
	return math.max(-1.0, math.min(1.0, value))
end

local function emit(state, index, speed)
	local e = state.emitters[index]
	e.x = e.x + speed * e.vx
	if e.x < 32 then
		e.x = 32 - e.x
		e.vx = walk(-e.vx)
	elseif e.x + 16 > WIDE - 1 then
		e.x = WIDE + WIDE - e.x - 32 + 1
		e.vx = walk(-e.vx)
	end
	e.y = e.y + speed * e.vy
	if e.y < 16 then
		e.y = 32 - e.y
		e.vy = -e.vy
		e.vx = walk(e.vx)
	elseif e.y + 32 > TALL - 1 then
		e.y = TALL + TALL - e.y - 32 + 1
		e.vy = -e.vy
		e.vx = walk(e.vx)
	end
	scatter(state, e.x, e.y, state.peak // 16)
end

local function flashes(name)
	return {
		name = name,
		size = { WIDE, TALL },
		filter = "nearest",
		feedback = "shaders/glass3d/flashes.gdshader",
		setup = function(state, scene)
			state.bins, state.v = {}, {}
			state.emitters = {}
			for index = 1, 80 do
				state.emitters[index] = { x = WIDE / 2, y = TALL / 2, vx = math.random() * 2.0 - 1.0, vy = math.random() * 2.0 - 1.0 }
			end
			state.dots = {}
			state.slot = 0
			state.peak, state.last_peak = 0, 0
			state.W = 1
			state.mode = 0x16
			state.timer = 0
			state.tail = 0
			state.tail_x, state.tail_y = WIDE // 2, TALL // 2
			state.pen_a, state.pen_b = 2, 1
			caption(scene, state)
		end,
		step = function(state, audio, scene)
			update_caption(state, scene)
			state.peak = (math.floor(bins_of.top(audio)) ^ 2) // 8
			state.loud = state.peak > state.last_peak + 1000
			state.last_peak = state.peak
			state.W = state.loud and 2 or 1
			spectrum_table(state, audio)
			state.color = flash_color(bands(state, 7))
			state.tail_color = state.tail_color or state.color
			scene.engine.set(scene, "erase", math.min(1.0, (6000000 / (state.peak + 1000)) / 65535.0))
			state.timer = state.timer + 1
			if state.timer > 900 then
				state.timer = 0
				local roll = irand(3)
				state.mode = roll == 0 and 0x15 or roll == 1 and 0x16 or roll == 2 and 0x18 or 0x17
			end
			state.slot = 0
			local peak = state.peak
			state.wheel = nil
			if irand(12) == 0 then
				state.wheel = { x = irand(WIDE), y = irand(TALL), reach = 40 + irand(90), turn = math.random() * TAU }
			end
			if state.mode == 0x15 then
				state.tail = math.max(state.tail, 1)
				for _ = 1, 2 do
					local x, y = WIDE - irand(WIDE), TALL - irand(TALL)
					scatter(state, x, y, peak // 16)
				end
			else
				local count = #state.emitters
				local speed = (peak // 50) * state.W
				local v = bands(state, count)
				for index = 0, 5 do
					v[index] = v[index] // (3 - index // 2)
				end
				local limit = math.min(peak * 2, 0x800)
				local active = 0
				for index = 1, count do
					if limit < v[index - 1] then
						active = active + 1
						emit(state, index, speed)
					else
						local e = state.emitters[index]
						if state.mode == 0x18 then
							e.x, e.y = irand(WIDE), irand(TALL)
						else
							local a, r = math.random() * 16.0, math.random() ^ 2 * TALL / 4
							e.x, e.y = math.sin(a) * r + WIDE // 2, math.cos(a) * r + TALL // 2
						end
					end
				end
				if active == 0 then
					emit(state, irand(count) + 1, speed)
				end
			end
			if state.tail <= 0 and state.loud then
				state.tail = peak // 4 + 200
				state.tail_x, state.tail_y = WIDE - irand(WIDE), TALL - irand(TALL)
				state.tail_color = state.color
			end
			if state.tail > 0 then
				state.tail_slot = state.slot
				scatter(state, state.tail_x, state.tail_y, state.tail)
				state.tail = state.tail - 100
			else
				state.tail_slot = nil
			end
			for index = #state.dots, state.slot + 1, -1 do
				state.dots[index] = nil
			end
		end,
		draw = function(canvas, state)
			if state.slot and state.slot > 1 then
				canvas:draw_multiline(state.dots, state.color, 1.0)
			end
			local wheel = state.wheel
			if wheel then
				local spokes = {}
				for spoke = 0, 15 do
					local a = wheel.turn + spoke / 16 * TAU
					spokes[spoke * 2 + 1] = Vector2(wheel.x, wheel.y)
					spokes[spoke * 2 + 2] = Vector2(wheel.x + math.cos(a) * wheel.reach, wheel.y + math.sin(a) * wheel.reach)
				end
				canvas:draw_multiline(spokes, Color(state.color.r * 0.6, state.color.g * 0.6, state.color.b * 0.6, 1.0), 1.0)
			end
		end,
	}
end

return {
	name = "Glass3D",
	presets = {
		animator("Animator", true),
		flashes("Flashes"),
	},
}

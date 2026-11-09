local lib = require("lib")
local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"
local SCROLL = "shaders/fruity/scroll.gdshader"

local LOW, HIGH = 60, 22050

local images = {}

local function image(name)
	images[name] = images[name] or nari.load("assets/fruity/" .. name .. ".png")
	return images[name]
end

local function face(canvas, name)
	canvas:draw_texture(image(name), Vector2(0, 0))
end

local function place(canvas, scene)
	canvas:draw_set_transform(Vector2(0, 0), 0.0, Vector2(scene.width / 640, scene.height / 480))
end

local BIN_HZ = 44100 / 2048
local DB_STEP = 0.31875

local palette = {}
for value = 0, 255 do
	local hue = 200 - math.floor(value * 200 / 255 + 0.5)
	local light = hue <= 160 and 120 or math.max(0, 80 - (hue - 160) * 2)
	palette[value] = lib.hsv(hue / 240, 1.0, light / 120)
end

local function level_of(byte)
	return math.min(255, math.floor(byte * 256 / 240 + 0.5))
end

local function bin_of(hertz)
	return math.max(0, hertz / BIN_HZ - 3)
end

local function byte_at(audio, bin, spread, channel)
	return bins.spiky(audio, bin, channel, spread)
end

local function level_db(byte)
	return (level_of(byte) - 255) * DB_STEP
end

local function thin(scene)
	return math.max(1.0, 640 / scene.width)
end

local function peak_db(audio, channel)
	local top = 0
	if audio.stereo then
		local offset = channel * 1024 + 2049
		local wave = audio.stereo
		top = math.max(math.max(wave:byte(offset, offset + 1023)) - 128, 128 - math.min(wave:byte(offset, offset + 1023))) / 127
	else
		for _, sample in ipairs(audio.wave or {}) do
			top = math.max(top, math.abs(sample))
		end
	end
	return top > 0 and 20 * math.log(top, 10) or -90
end

local function vu_db(audio, channel)
	if audio.stereo then
		local total = 0
		for index = 0, 1020, 4 do
			local sample = bins.wave(audio, index, channel) - 128
			total = total + sample * sample
		end
		return total > 0 and 10 * math.log(total / 256 / 16129, 10) + 3 or -90
	end
	local level = (audio.level or 0) / 4
	return level > 0 and 20 * math.log(level, 10) + 8 or -90
end

local function lookup(table_, value)
	if value <= table_[1][1] then
		return table_[1][2]
	end
	for index = 2, #table_ do
		local a, b = table_[index - 1], table_[index]
		if value <= b[1] then
			return a[2] + (b[2] - a[2]) * (value - a[1]) / (b[1] - a[1])
		end
	end
	return table_[#table_][2]
end

local function step_channel(state, audio, channel)
	local now, before = peak_db(audio, channel), state.peak or -90
	state.peak = before - now > 1 and before - (before - now) / 10 or now
	if state.peak >= (state.hold or -90) then
		state.hold = state.peak
		state.wait = 30
	elseif (state.wait or 0) > 0 then
		state.wait = state.wait - 1
	else
		state.hold = state.hold - 0.6
	end
	state.vu = (state.vu or -30) + (math.max(vu_db(audio, channel), -40) - (state.vu or -30)) * 0.18
end

local function step_levels(state, audio)
	state.sides = state.sides or { {}, {} }
	step_channel(state.sides[1], audio, 0)
	step_channel(state.sides[2], audio, 1)
end

local SEGMENT = { { -90, 1 }, { -40, 3 }, { -30, 5 }, { -20, 7 }, { -15, 9 }, { -10, 11 }, { -8, 13 }, { -6, 15 }, { -4, 17 }, { -3, 19 }, { -2, 21 }, { -1, 23 }, { 0, 27 } }

local function segment_color(index)
	if index < 15 then
		return Color(0.22 + 0.78 * index / 15, 1.0, 0.0)
	end
	return Color(1.0, 1.0 - (index - 15) / 13 * 0.8, 0.0)
end

local function segment_row(canvas, y, state)
	local lit = lookup(SEGMENT, state.peak)
	local held = math.floor(lookup(SEGMENT, state.hold) + 0.5)
	for index = 0, 27 do
		local on = index <= lit or index == held
		canvas:draw_rect(Rect2(31 + 21 * index, y, 19, 4), on and segment_color(index) or Color(0.22, 0.22 - index * 0.004, 0.11))
	end
end

local function needle_line(canvas, pivot_x, pivot_y, bottom, length, angle, color, thick)
	local sine, cosine = math.sin(angle), math.cos(angle)
	local start = (pivot_y - bottom) / cosine
	canvas:draw_line(Vector2(pivot_x + sine * start, bottom), Vector2(pivot_x + sine * length, pivot_y - cosine * length), color, thick)
end

local PEAK_ANGLE = { { -60, -34.5 }, { -20, -28.1 }, { -15, -21.2 }, { -10, -14.8 }, { -8, -7.8 }, { -6, -0.9 }, { -4, 8.7 }, { -3, 13.3 }, { -2, 19.9 }, { -1, 27.2 }, { 0, 34.0 } }
local VU_ANGLE = { { -40, -32 }, { -20, -27.5 }, { -10, -19.6 }, { -6, -11.8 }, { -4, -6.4 }, { -2, -0.5 }, { -1, 4.2 }, { 0, 9.3 }, { 1, 14.5 }, { 2, 19.8 }, { 4, 32 } }

local function needles(name, source, table_, pivot, bottom, length, hold)
	return function(canvas, state, _, scene)
		place(canvas, scene)
		for side, left in ipairs({ 72, 356 }) do
			local levels = state.sides[side]
			needle_line(canvas, left + pivot[1], pivot[2], bottom, length, math.rad(lookup(table_, levels[source])), Color(0.2, 1.0, 0.1), 3.0)
			if hold then
				needle_line(canvas, left + pivot[1], pivot[2], bottom, length, math.rad(lookup(table_, levels.hold)), Color(1.0, 1.0, 0.3), 1.0)
			end
		end
		face(canvas, name)
	end
end

local WEDGES = 46
local VU_WEDGE = { { -40, 0 }, { -20, 2 }, { -10, 8 }, { -6, 12.5 }, { -4, 17 }, { -2, 21.5 }, { -1, 25 }, { 0, 28 }, { 1, 32 }, { 2, 36 }, { 4, 45 } }

local function wedge_points(left, index)
	local function point(at)
		local top_x = (at / WEDGES - 0.5) * 207
		local top_y = 216 + (top_x / 103.5) ^ 2 * 15
		local low_x = top_x * 0.83
		local low_y = 244 + (low_x / 86) ^ 2 * 8
		return Vector2(left + 174 + top_x, top_y), Vector2(left + 174 + low_x, low_y)
	end
	local a, b = point(index)
	local c, d = point(index + 0.8)
	return { a, c, d, b }
end

local SEVEN = { [0] = "abcdef", "bc", "abdeg", "abcdg", "bcfg", "acdfg", "acdefg", "abc", "abcdefg", "abcdfg" }

local function seven(canvas, x, y, digit, color)
	local bars = { a = { 1, 0, 3, 1 }, b = { 4, 1, 1, 3 }, c = { 4, 5, 1, 3 }, d = { 1, 8, 3, 1 }, e = { 0, 5, 1, 3 }, f = { 0, 1, 1, 3 }, g = { 1, 4, 3, 1 } }
	for bar in string.gmatch(digit, ".") do
		local box = bars[bar]
		canvas:draw_rect(Rect2(x + box[1], y + box[2], box[3], box[4]), color)
	end
end

local function digital_vu(canvas, state, _, scene)
	place(canvas, scene)
	local blue = Color(0.42, 0.42, 1.0)
	for panel, left in ipairs({ 0, 293 }) do
		local levels = state.sides[panel]
		local lit = lookup(VU_WEDGE, levels.vu)
		local held = math.max(lit, lookup(VU_WEDGE, math.min(levels.hold, 4)))
		local peak = math.floor(math.max(0, math.min(1, (levels.peak + 30) / 30)) * 18)
		for index = math.floor(lit), math.floor(held) do
			local mixed = 1 - (index - lit) / math.max(1, held - lit)
			local tone = 0.3 + 0.6 * mixed
			local color = Color(tone * 0.9, tone * 0.9, 0.5 + 0.5 * mixed)
			canvas:draw_colored_polygon(wedge_points(left, index), color)
		end
		for index = 0, peak do
			canvas:draw_rect(Rect2(left + 146 + index * 3, 268, 1, 5), index < 13 and Color(0.3, 1.0, 0.2) or Color(0.9, 0.3, 0.1))
		end
		local reading = math.max(-99.9, levels.vu)
		local value = math.floor(math.abs(reading) * 10 + 0.5)
		canvas:draw_rect(Rect2(left + 229, 267, 4, 1), blue)
		seven(canvas, left + 235, 263, SEVEN[(value // 100) % 10], blue)
		seven(canvas, left + 241, 263, SEVEN[(value // 10) % 10], blue)
		canvas:draw_rect(Rect2(left + 247, 271, 1, 1), blue)
		seven(canvas, left + 249, 263, SEVEN[value % 10], blue)
	end
	face(canvas, "digital_vu")
end

local BAR_HZ = { 60, 100, 150, 200, 250, 300, 400, 500, 650, 800, 1000, 1500, 2000, 4000, 6000, 8000, 10000, 12000, 16000, 20000 }
local BAR_TOP, BAR_MIDDLE, BAR_BOTTOM = Color(1.0, 0.22, 0.0), Color(1.0, 1.0, 0.0), Color(0.22, 1.0, 0.0)

local function ramp(top)
	if top < 0.5 then
		return lib.mix(BAR_BOTTOM, BAR_MIDDLE, top * 2)
	end
	return lib.mix(BAR_MIDDLE, BAR_TOP, top * 2 - 1)
end

local function bars_step(state, audio)
	state.sides = state.sides or { { levels = {}, tops = {}, waits = {} }, { levels = {}, tops = {}, waits = {} } }
	for side, group in ipairs(state.sides) do
		for index, hertz in ipairs(BAR_HZ) do
			local value = level_of(byte_at(audio, bin_of(hertz), 0.2, side - 1)) / 255
			local before = group.levels[index] or 0
			local level = value >= before and value or before - (before - value) / 10
			group.levels[index] = level
			local top = group.tops[index] or 0
			if level >= top then
				group.tops[index], group.waits[index] = level, 25
			elseif (group.waits[index] or 0) > 0 then
				group.waits[index] = group.waits[index] - 1
			else
				group.tops[index] = top - 0.012
			end
		end
	end
end

local function bars_draw(canvas, state, _, scene)
	place(canvas, scene)
	face(canvas, "bars")
	local mask = image("bars_mask")
	for side, offset in ipairs({ 0, 210 }) do
		local group = state.sides[side]
		for index = 1, 20 do
			local x = 61 + (index - 1) * 26
			local level = group.levels[index] or 0
			if level > 0 then
				local y = 194 - level * 124 + offset
				local half = 132 + offset
				if level > 0.5 then
					canvas:draw_polygon({ Vector2(x, half), Vector2(x + 23, half), Vector2(x + 23, 194 + offset), Vector2(x, 194 + offset) }, { BAR_MIDDLE, BAR_MIDDLE, BAR_BOTTOM, BAR_BOTTOM })
					local color = ramp(level)
					canvas:draw_polygon({ Vector2(x, y), Vector2(x + 23, y), Vector2(x + 23, half), Vector2(x, half) }, { color, color, BAR_MIDDLE, BAR_MIDDLE })
				else
					local color = ramp(level)
					canvas:draw_polygon({ Vector2(x, y), Vector2(x + 23, y), Vector2(x + 23, 194 + offset), Vector2(x, 194 + offset) }, { color, color, BAR_BOTTOM, BAR_BOTTOM })
				end
			end
			local top = group.tops[index] or 0
			canvas:draw_rect(Rect2(x, 194 - top * 124 + offset - 3, 23, 3), Color(1.0, 0.6, 0.0))
		end
		canvas:draw_texture_rect(mask, Rect2(61, 70 + offset, 520, 124), false)
	end
end

local function region(scene, a, b, shift, fade)
	scene.engine.set(scene, "first", Color(a[1] / 640, a[2] / 480, a[3] / 640, a[4] / 480))
	scene.engine.set(scene, "second", Color(b[1] / 640, b[2] / 480, b[3] / 640, b[4] / 480))
	scene.engine.set(scene, "shift", shift / scene.width)
	scene.engine.set(scene, "fade", fade)
end

local function pixel_step(scene)
	return math.max(1, math.floor(scene.width / 640 + 0.5))
end

local SPECTRO_ROWS = 64

local function spectrogram_draw(canvas, _, audio, scene)
	place(canvas, scene)
	local width = pixel_step(scene) * 640 / scene.width
	local slot = 452 / SPECTRO_ROWS
	for row = 0, SPECTRO_ROWS - 1 do
		local hertz = LOW * (HIGH / LOW) ^ (row / (SPECTRO_ROWS - 1))
		local y = 462 - (row + 1) * slot
		canvas:draw_rect(Rect2(40, y, width, slot + 0.5), palette[level_of(byte_at(audio, bin_of(hertz), 0.5, 0)) // 1])
		canvas:draw_rect(Rect2(360, y, width, slot + 0.5), palette[level_of(byte_at(audio, bin_of(hertz), 0.5, 1)) // 1])
	end
	face(canvas, "spectrogram")
end

local WAVE_SCALE = { { -90, 0 }, { -21, 12 }, { -15, 40 }, { -10, 70 }, { -5, 127 }, { -1, 205 }, { 0, 230 } }

local WAVE_Y = {}
for byte = 0, 255 do
	local sample = (byte - 128) / 127
	local db = sample ~= 0 and 20 * math.log(math.abs(sample), 10) or -90
	local reach = lookup(WAVE_SCALE, db)
	WAVE_Y[byte] = 240 - (sample < 0 and -reach or reach)
end

local function wave_draw(canvas, _, audio, scene)
	place(canvas, scene)
	face(canvas, "wave")
	local count = audio.stereo and 289 or 127
	for side, left in ipairs({ 23, 343 }) do
		local points = {}
		for step = 0, count do
			local position = step / count
			points[step + 1] = Vector2(left + position * 290, WAVE_Y[math.floor(bins.wave(audio, position * 1023, side - 1))])
		end
		canvas:draw_polyline(points, Color(0.3, 1.0, 0.1), thin(scene))
	end
end

local function log_x(hertz)
	return math.log(hertz / LOW) / math.log(HIGH / LOW) * 290
end

local function db_y(db)
	return 10 + math.max(0, math.min(78, -db)) * 5.79
end

local function spectrum_scope_draw(canvas, state, audio, scene)
	place(canvas, scene)
	state.held = state.held or { {}, {} }
	face(canvas, "spectrum_scope")
	for side, left in ipairs({ 23, 343 }) do
		local held = state.held[side]
		local a, b = {}, {}
		for step = 0, 127 do
			local hertz = LOW * (HIGH / LOW) ^ (step / 127)
			local db = level_db(byte_at(audio, bin_of(hertz), 0.6, side - 1))
			held[step] = math.max(db, (held[step] or -80) - 1.5)
			a[step + 1] = Vector2(left + log_x(hertz), db_y(db))
			b[step + 1] = Vector2(left + log_x(hertz), db_y(held[step]))
		end
		canvas:draw_polyline(b, Color(0.1, 0.4, 0.05), thin(scene))
		canvas:draw_polyline(a, Color(0.4, 1.0, 0.1), thin(scene))
	end
end

local XY_CENTER_X, XY_CENTER_Y, XY_REACH = 329, 240, 224

local function xy_draw(canvas, _, audio, scene)
	place(canvas, scene)
	if scene.frame >= 2 then
		local points, colors = {}, {}
		local size = thin(scene)
		local count = audio.stereo and 341 or 240
		for dot = 1, count do
			local x, y
			if audio.stereo then
				x = XY_CENTER_X + bins.sample(audio, dot * 3 / 1023, 0) * XY_REACH
				y = XY_CENTER_Y - bins.sample(audio, dot * 3 / 1023, 1) * XY_REACH
			else
				local a = lib.sample(audio, math.random())
				local spread = (math.random() + math.random() - 1) * 0.2
				x = XY_CENTER_X + (a + spread) * XY_REACH
				y = XY_CENTER_Y - (a - spread) * XY_REACH
			end
			points[#points + 1] = Vector2(x, y)
			points[#points + 1] = Vector2(x + size, y)
			colors[#colors + 1] = Color(0.2, 1.0, 0.1)
		end
		canvas:draw_multiline_colors(points, colors, size)
	end
	canvas:draw_line(Vector2(82, XY_CENTER_Y), Vector2(556, XY_CENTER_Y), Color(0.31, 0.31, 0.31), thin(scene))
	canvas:draw_line(Vector2(XY_CENTER_X, 7), Vector2(XY_CENTER_X, 455), Color(0.31, 0.31, 0.31), thin(scene))
	face(canvas, "xy")
end

local ROWS = 65
local FIRST_KEY = 48
local LAST_KEY = 131
local PIANO_LEFT = { 82, 402 }
local PIANO_FIRST = 8
local TOP_COUNT = 17
local AVERAGE_FRAMES = 6
local GRAPH_LEVELS = 7
local GRAPH_STEP = 2
local GRID_TICKS = 15
local GLOW = Color(1.0, 0.13, 0.13)
local SHARP = { [1] = true, [3] = true, [6] = true, [8] = true, [10] = true }

local PIANO_KEY = {}
for bin = 0, 1023 do
	PIANO_KEY[bin] = math.floor(12 * math.log((bin + 3) * BIN_HZ / 15.8861, 2))
end

local PIANO_COLOR = {}
for level = 0, GRAPH_LEVELS - 1 do
	local hue = 240 - 240 / (GRAPH_LEVELS - 1) * level
	PIANO_COLOR[level] = hue > 170 and lib.hsv(170 / 240, 1.0, 1 / 3) or lib.hsv(hue / 240, 1.0, 1.0)
end

local PIANO_ROW = {}
for row = 1, ROWS do
	local key = FIRST_KEY + row - 1
	local even = (key // 12) % 2 == 0
	local shade = SHARP[key % 12] and (even and 63 or 47) or (even and 80 or 60)
	PIANO_ROW[row] = Color(shade / 255, shade / 255, shade / 255)
end

local function piano_pane()
	return { levels = {}, top = {}, history = {}, at = 0, threshold = 0, lit = {} }
end

local function piano_threshold(pane, top)
	local total, count = 0, 0
	for index = 1, TOP_COUNT do
		if top[index] == 0 then
			break
		end
		total = total + top[index]
		count = count + 1
	end
	pane.at = pane.at % AVERAGE_FRAMES + 1
	pane.history[pane.at] = count > 0 and total / count or 0
	local sum = 0
	for index = 1, AVERAGE_FRAMES do
		sum = sum + (pane.history[index] or 0)
	end
	return math.floor(sum / AVERAGE_FRAMES + 0.5)
end

local function piano_analyse(pane, stereo, channel)
	local levels, top = pane.levels, pane.top
	for key = FIRST_KEY, LAST_KEY do
		levels[key] = 0
	end
	for index = 1, TOP_COUNT do
		top[index] = 0
	end
	local offset = channel * 1024 + 1
	local before = stereo:byte(offset + PIANO_FIRST - 1)
	local value = stereo:byte(offset + PIANO_FIRST)
	for bin = PIANO_FIRST, 1023 do
		local after = bin < 1023 and stereo:byte(offset + bin + 1) or 0
		if value >= before and value >= after and value > 0 then
			local key = PIANO_KEY[bin]
			if key >= FIRST_KEY then
				if levels[key] < value then
					levels[key] = value
				end
				if value > top[TOP_COUNT] then
					local at = TOP_COUNT
					while at > 1 and top[at - 1] < value do
						top[at] = top[at - 1]
						at = at - 1
					end
					top[at] = value
				end
			end
		end
		before, value = value, after
	end
	local threshold = piano_threshold(pane, top)
	local lit = pane.lit
	for row = 1, ROWS do
		local level = levels[FIRST_KEY + row - 1]
		lit[row] = level > 0 and level >= threshold and level * GRAPH_LEVELS // 256 or nil
	end
end

local function piano_guess(pane, audio, clock)
	local lit = pane.lit
	pane.until_ = pane.until_ or {}
	for row = 1, ROWS do
		if lit[row] and clock >= pane.until_[row] then
			lit[row] = nil
		end
		if not lit[row] then
			local value = bins.linear(audio, 261.63 * 2 ^ ((row - 1) / 12) / 22050)
			if math.random() < value * value * value * 0.2 + 0.0015 then
				lit[row] = math.min(GRAPH_LEVELS - 1, math.floor((value * 1.2 + math.random() * 0.4) * GRAPH_LEVELS))
				pane.until_[row] = clock + 2 + math.random(14)
			end
		end
	end
end

local function piano_step(state, audio)
	state.panes = state.panes or { piano_pane(), piano_pane() }
	state.clock = (state.clock or 0) + 1
	if audio.stereo then
		piano_analyse(state.panes[1], audio.stereo, 0)
		piano_analyse(state.panes[2], audio.stereo, 1)
	else
		piano_guess(state.panes[1], audio, state.clock)
		state.panes[2].lit = state.panes[1].lit
	end
end

local function piano_stripes(canvas, x, width)
	for row = 1, ROWS do
		canvas:draw_rect(Rect2(x, 472 - row * 7, width, 7), PIANO_ROW[row])
	end
end

local function piano_glow(canvas, left, row, level)
	local amount = (level + 1) / GRAPH_LEVELS
	local y = 472 - row * 7
	local key = (FIRST_KEY + row - 1) % 12
	if SHARP[key] then
		canvas:draw_rect(Rect2(left - 60, y + 1, 36, 5), lib.mix(Color(0.0, 0.0, 0.0), GLOW, amount))
	else
		local color = lib.mix(Color(1.0, 1.0, 1.0), GLOW, amount)
		canvas:draw_rect(Rect2(left - 60, y + 2, 36, 3), color)
		canvas:draw_rect(Rect2(left - 24, y - 2, 24, 11), color)
	end
end

local function piano_draw(canvas, state, _, scene)
	place(canvas, scene)
	local width = pixel_step(scene) * GRAPH_STEP * 640 / scene.width
	for side, left in ipairs(PIANO_LEFT) do
		if scene.frame < 3 then
			piano_stripes(canvas, left, 232)
		end
		local lit = state.panes[side].lit
		for row = 1, ROWS do
			local level = lit[row]
			canvas:draw_rect(Rect2(left, 472 - row * 7, width, 7), level and PIANO_COLOR[level] or PIANO_ROW[row])
		end
		if state.clock % GRID_TICKS == 0 then
			canvas:draw_rect(Rect2(left, 17, 640 / scene.width, 455), Color(0.5, 0.5, 0.5))
		end
	end
	face(canvas, "piano")
	for side, left in ipairs(PIANO_LEFT) do
		local lit = state.panes[side].lit
		for row = 1, ROWS do
			if lit[row] then
				piano_glow(canvas, left, row, lit[row])
			end
		end
	end
end

local HISTORY = 97

local function push(list, value)
	table.insert(list, 1, value)
	list[HISTORY + 1] = nil
end

local function peak_vu_step(state, audio)
	step_levels(state, audio)
	if (state.tick or 0) % 3 == 0 then
		for _, side in ipairs(state.sides) do
			side.green = side.green or {}
			side.blue = side.blue or {}
			push(side.green, side.vu)
			push(side.blue, side.peak)
		end
	end
	state.tick = (state.tick or 0) + 1
end

local function trace(canvas, list, left, color, thin)
	if #list < 2 then
		return
	end
	local points = {}
	for index, value in ipairs(list) do
		points[index] = Vector2(left + (index - 1) * 3, 10 + math.max(0, math.min(39, -value)) * 11.67)
	end
	canvas:draw_polyline(points, color, thin)
end

local function peak_vu_draw(canvas, state, _, scene)
	place(canvas, scene)
	face(canvas, "peak_vu")
	for side, left in ipairs({ 23, 343 }) do
		trace(canvas, state.sides[side].blue, left, Color(0.2, 0.4, 1.0), thin(scene))
		trace(canvas, state.sides[side].green, left, Color(0.2, 1.0, 0.1), thin(scene))
	end
end

local function frequency_step(state, audio)
	state.trace = state.trace or { {}, {} }
	for side, list in ipairs(state.trace) do
		table.insert(list, 1, level_db(byte_at(audio, bin_of(1000), 1.0, side - 1)))
		list[291] = nil
	end
end

local function frequency_draw(canvas, state, _, scene)
	place(canvas, scene)
	face(canvas, "frequency")
	if #state.trace[1] < 2 then
		return
	end
	for side, left in ipairs({ 23, 343 }) do
		local points = {}
		for index, db in ipairs(state.trace[side]) do
			points[index] = Vector2(left + index - 1, db_y(db))
		end
		canvas:draw_polyline(points, Color(0.1, 1.0, 0.1), thin(scene))
	end
end

local BALANCE_BINS = {}
for bin = 0, 1023 do
	if bin < 200 or bin % 2 == 0 then
		local hertz = (bin + 3) * BIN_HZ
		if hertz >= LOW then
			BALANCE_BINS[#BALANCE_BINS + 1] = { bin = bin, reach = math.log(hertz / LOW, 10) / math.log(HIGH / LOW, 10) * 268 + 38 }
		end
	end
end

local function balance_draw(canvas, _, audio, scene)
	place(canvas, scene)
	local points, colors = {}, {}
	local size = thin(scene)
	for _, entry in ipairs(BALANCE_BINS) do
		local byte, spread
		if audio.stereo then
			local a, b = bins.frequency(audio, entry.bin, 0), bins.frequency(audio, entry.bin, 1)
			byte = math.max(a, b)
			spread = byte > 0 and (b - a) / byte or 0
		else
			byte = byte_at(audio, entry.bin, 1.0)
			spread = (math.random() + math.random() + math.random() - 1.5) * 0.6
		end
		if byte > 0 then
			local angle = math.rad(90 + spread * 255 * 0.3529)
			local x = 320 - math.cos(angle) * entry.reach
			local y = 466 - math.sin(angle) * entry.reach
			points[#points + 1] = Vector2(x, y)
			points[#points + 1] = Vector2(x + size, y)
			colors[#colors + 1] = palette[level_of(byte) // 1]
		end
	end
	if #points > 0 then
		canvas:draw_multiline_colors(points, colors, size)
	end
	face(canvas, "balance")
end

local function meter(name, source)
	source.name = name
	source.aspect = 4 / 3
	if not source.feedback then
		source.layers = { CLEAR }
	end
	return source
end

local presets = {
	meter("ピークメーター", {
		step = step_levels,
		draw = function(canvas, state, _, scene)
			place(canvas, scene)
			face(canvas, "peak")
			segment_row(canvas, 227, state.sides[1])
			segment_row(canvas, 248, state.sides[2])
		end,
	}),
	meter("針式ピークメーター", { step = step_levels, draw = needles("needle_peak", "peak", PEAK_ANGLE, { 107, 363 }, 278, 155, true) }),
	meter("デジタルVUメーター", { step = step_levels, draw = digital_vu }),
	meter("針式VUメーター", { step = step_levels, draw = needles("needle_vu", "vu", VU_ANGLE, { 105, 372 }, 279, 162, false) }),
	meter("スペクトラム・バー", { step = bars_step, draw = bars_draw }),
	meter("スペクトログラム", {
		feedback = SCROLL,
		resize = function(_, scene)
			region(scene, { 40, 10, 310, 462 }, { 360, 10, 630, 462 }, pixel_step(scene), 1.0)
		end,
		draw = spectrogram_draw,
	}),
	meter("ウェーブスコープ", { draw = wave_draw }),
	meter("スペクトラムスコープ", { draw = spectrum_scope_draw }),
	meter("X-Yスコープ", {
		feedback = SCROLL,
		resize = function(_, scene)
			region(scene, { 82, 7, 556, 455 }, { 0, 0, 0, 0 }, 0, 0.97)
		end,
		draw = xy_draw,
	}),
	meter("ピアノロールグラフ", {
		feedback = SCROLL,
		step = piano_step,
		resize = function(_, scene)
			region(scene, { 82, 17, 314, 472 }, { 402, 17, 634, 472 }, pixel_step(scene) * GRAPH_STEP, 1.0)
		end,
		draw = piano_draw,
	}),
	meter("ピーク/VUグラフ", { step = peak_vu_step, draw = peak_vu_draw }),
	meter("周波数グラフ", { step = frequency_step, draw = frequency_draw }),
	meter("スペクトラムバランス", { draw = balance_draw }),
	meter("カスタムメーター", {}),
	meter("歌詞表示", {
		draw = function(canvas, _, _, scene)
			place(canvas, scene)
			face(canvas, "frame")
		end,
	}),
}

local function empty_draw(canvas, _, _, scene)
	place(canvas, scene)
	local texture = image("empty")
	canvas:draw_texture(texture, Vector2(320 - texture:get_width() / 2, 240 - texture:get_height() / 2))
end

for _, suffix in ipairs({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" }) do
	presets[#presets + 1] = meter("ユーザー" .. suffix, { draw = empty_draw })
end

return {
	name = "Fruity",
	presets = presets,
}

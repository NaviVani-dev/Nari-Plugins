local bins = require("packs.wmp_bins")

local SHADER = "shaders/celestial/celestial.gdshader"
local TAU = math.pi * 2
local PEN_A = Color(0.0, 1.0, 0.0, 1.0)
local PEN_B = Color(0.0, 0.0, 1.0, 1.0)
local FILL_A = Color(1.0 / 255.0, 0.0, 0.0, 1.0)
local FILL_B = Color(2.0 / 255.0, 0.0, 0.0, 1.0)
local OR, XOR, COPY = 1, 2, 0
local BLACK = Color(0.0, 0.0, 0.0)

local function round(value)
	return math.floor(value + 0.5)
end

local function capped(value)
	return math.min(255, math.floor(value))
end

local function rgb(r, g, b)
	return Color(r, g, b)
end

local function push(scene, name, value)
	for _, item in ipairs(scene.materials) do
		item:set_shader_parameter(name, value)
	end
end

local function scaled(scene, width)
	return math.max(1.0, width * scene.height / 480)
end

local function fan(canvas, points, cx, cy, color)
	local count = #points
	local colors = { color }
	local triangle = {}
	for index = 1, count - 1 do
		triangle[1] = Vector2(cx, cy)
		triangle[2] = points[index]
		triangle[3] = points[index + 1]
		canvas:draw_primitive(triangle, colors, {})
	end
	triangle[1] = Vector2(cx, cy)
	triangle[2] = points[count]
	triangle[3] = points[1]
	canvas:draw_primitive(triangle, colors, {})
end

local function outline(canvas, points, color, width)
	points[#points + 1] = points[1]
	canvas:draw_polyline(points, color, width)
	points[#points] = nil
end

local function smooth(state, audio)
	local left, right = state.wave, state.right
	for index = 4, 1024, 4 do
		left[index] = ((left[index] or 128) + bins.wave(audio, index - 1, 0)) // 2
		right[index] = ((right[index] or 128) + bins.wave(audio, index - 1, 1)) // 2
	end
end

local function palette(state, audio, scene)
	local a = { capped(8 * bins.frequency(audio, 9, 0)), capped(4 * bins.frequency(audio, 49, 0)), 255 - capped(8 * bins.frequency(audio, 249, 0)) }
	local c = { 255 - capped(8 * bins.frequency(audio, 9, 1)), capped(4 * bins.frequency(audio, 49, 1)), capped(8 * bins.frequency(audio, 249, 1)) }
	local b = { a[1] ~ 0xf0, a[2] ~ 0x0f, a[3] ~ 0x0f }
	local d = { c[1] ~ 0xf0, c[2] ~ 0x0f, c[3] ~ 0x0f }
	state.col = { a, b, c, d }
end

local function shade(values)
	return rgb(values[1], values[2], values[3])
end

local function inverted(values)
	return rgb(255 - values[1], 255 - values[2], 255 - values[3])
end

local function pulse(state, audio, shift, floor)
	local value = math.floor(2 * bins.frequency(audio, 255)) >> shift
	state.pulse = math.floor((value + 7 * state.pulse) / 8) + floor
	return state.pulse
end

local function viewport(scene, draw)
	local view = SubViewport.new()
	view.disable_3d = true
	view.transparent_bg = true
	view.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	scene.viewport:add_child(view)
	local blend = CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	local canvas = Control.new()
	canvas.material = blend
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view:add_child(canvas)
	canvas.draw:connect(function()
		if scene.audio then
			draw(canvas, scene.state, scene.audio, scene)
		end
	end)
	scene.state.view = view
	scene.state.layer = canvas
	view.size = Vector2i(scene.width, scene.height)
	canvas.size = Vector2(scene.width, scene.height)
	push(scene, "mask", view:get_texture())
end

local function grain(state, count)
	local seeds = state.grain
	if not seeds then
		seeds = {}
		state.grain = seeds
		for index = 1, count do
			seeds[index] = math.random()
		end
	end
	for _ = 1, count // 8 do
		seeds[math.random(1, count)] = math.random()
	end
	return seeds
end

local function preset(name, operation, resolve, draw)
	return {
		name = name,
		feedback = SHADER,
		params = { operation = operation },
		setup = function(state, scene)
			state.wave = {}
			state.right = {}
			state.pulse = 0
			state.count = 0
			viewport(scene, draw)
		end,
		resize = function(state, scene)
			if state.view then
				state.view.size = Vector2i(scene.width, scene.height)
				state.layer.size = Vector2(scene.width, scene.height)
			end
		end,
		step = function(state, audio, scene)
			smooth(state, audio)
			palette(state, audio, scene)
			if resolve then
				resolve(state, audio, scene)
			end
			state.view.render_target_update_mode = SubViewport.UPDATE_ONCE
			state.layer:queue_redraw()
			state.count = state.count + 1
		end,
	}
end

local function colors(pen_a, fill_a, pen_b, fill_b)
	return function(state, _, scene)
		local col = state.col
		push(scene, "pen_a", pen_a(col))
		push(scene, "fill_a", fill_a and fill_a(col) or BLACK)
		push(scene, "pen_b", pen_b(col))
		push(scene, "fill_b", fill_b and fill_b(col) or BLACK)
	end
end

local function col(index)
	return function(values)
		return shade(values[index])
	end
end

local function blobs_setup(state)
	state.blobs = {}
	for index = 1, 16 do
		state.blobs[index] = {
			p = math.random(0, 39) + 20,
			q = math.random(0, 39) + 20,
			c1 = ((16 - index) * 12 + 0x4b) & 255,
			c2 = (math.abs(8 - index) * 32 + 0x4b) & 255,
			c3 = (index * 12 + 0x4b) & 255,
			level = 0,
		}
	end
end

local function blobs_step(state, audio, scene)
	if not state.blobs then
		blobs_setup(state)
		push(scene, "many", true)
	end
	local tints = {}
	for index, blob in ipairs(state.blobs) do
		local raw = math.floor(2 * bins.both(audio, index * 56 - 1))
		blob.level = (7 * blob.level + raw) // 8
		tints[index] = Color(capped(blob.c3 * blob.level / 127), capped(blob.c2 * blob.level / 191), capped(blob.c1 * blob.level / 255), 1.0)
	end
	push(scene, "colors", tints)
end

local function blobs_points(state, audio, index, scene)
	local blob = state.blobs[index]
	local unit = scene.height / 480
	local ox, oy = round(math.cos(state.count / blob.p) * 30) * unit, round(math.sin(state.count / blob.q) * 30) * unit
	local cx, cy = scene.width // 2, scene.height // 2
	local points = {}
	for step = 1, 16 do
		local angle = (step - 1) * TAU / 15
		local at = (step - 1) * 16 + index
		local reach = (math.floor(state.wave[at * 4]) // 8 + 30) * unit
		points[step] = Vector2(cx + ox + round(math.cos(angle) * reach), cy + oy + round(math.sin(angle) * reach))
	end
	return points, cx + ox, cy + oy
end

local function bit(index)
	if index <= 8 then
		return Color((1 << (index - 1)) / 255.0, 0.0, 0.0, 1.0)
	end
	return Color(0.0, (1 << (index - 9)) / 255.0, 0.0, 1.0)
end

return {
	name = "Celestial",
	presets = {
		preset("Balance", OR, colors(col(1), nil, col(3), nil), function(canvas, state, _, scene)
			local w, h, cx, cy = scene.width, scene.height, scene.width // 2, scene.height // 2
			local a, b = {}, {}
			for index = 1, 128 do
				local value = state.wave[index * 8]
				local angle = (value / 255 * 2 - 1.004) * math.pi / 3
				local reach = (index - 1) * w / 127 / 2
				local x, y = round(math.cos(angle) * reach), round(math.sin(angle) * reach)
				a[index] = Vector2(cx + x, cy + y)
				local turn = (state.right[index * 8] / 255 * 2 - 1.004) * math.pi / 3
				b[index] = Vector2(cx - round(math.cos(turn) * reach), cy + round(math.sin(turn) * reach))
			end
			canvas:draw_polyline(a, PEN_A, scaled(scene, 3))
			canvas:draw_polyline(b, PEN_B, scaled(scene, 3))
		end),
		preset("Rhyme", OR, colors(col(1), nil, col(3), col(4)), function(canvas, state, _, scene)
			local w, h, cx, cy = scene.width, scene.height, scene.width // 2, scene.height // 2
			local a, b = {}, {}
			for index = 1, 128 do
				local value = state.wave[index * 8]
				a[index] = Vector2(round((index - 1) * w / 127), round(h * (value // 2 + 64) / 255))
				local reach = h * value * value / 255 / 4 / 127
				local angle = (index - 1) * TAU / 127
				b[index] = Vector2(round(math.cos(angle) * reach * 2) + cx, round(math.sin(angle) * reach) + cy)
			end
			canvas:draw_polyline(a, PEN_A, scaled(scene, 8))
			fan(canvas, b, cx, cy, FILL_B)
			outline(canvas, b, PEN_B, scaled(scene, 4))
		end),
		preset("Reflection", OR, function(state, audio, scene)
			colors(col(1), nil, col(3), nil)(state, audio, scene)
			local value = math.floor(2 * bins.frequency(audio, 255)) >> 4
			state.pulse = (value + 7 * state.pulse) // 8 + 4
			local d = state.col[4]
			push(scene, "disc_fill", rgb(255, 255, d[3]))
			push(scene, "disc_pen", rgb(255, d[2], d[3]))
			push(scene, "disc_width", state.pulse)
		end, function(canvas, state, _, scene)
			local w, h, cy = scene.width, scene.height, scene.height // 2
			local a, b = {}, {}
			for index = 1, 128 do
				local value = state.wave[index * 8]
				local x = round((index - 1) * w / 127)
				local bow = math.abs(index - 64) / 3 * h / 480
				a[index] = Vector2(x, round((128 - value) * h / 255 / 2 - bow) + cy)
				b[index] = Vector2(x, round((state.right[index * 8] - 128) * h / 255 / 2 + bow) + cy)
			end
			canvas:draw_polyline(a, PEN_A, scaled(scene, 16))
			canvas:draw_polyline(b, PEN_B, scaled(scene, 16))
		end),
		preset("Harmony", XOR, colors(col(1), nil, col(3), function(values)
			return inverted(values[2])
		end), function(canvas, state, _, scene)
			local h, cx, cy = scene.height, scene.width // 2, scene.height // 2
			local a, b = {}, {}
			for index = 1, 256 do
				local value = state.wave[index * 4]
				local angle = (index - 1) * TAU / 255
				local s, c = math.sin(angle), math.cos(angle)
				a[index] = Vector2(round(s * h * value / 255 / 2) + cx, round(c * h * value / 255 / 2) + cy)
				b[index] = Vector2(round(s * h * value / 255 / 8) + cx, round(c * h * value / 255 / 8) + cy)
			end
			outline(canvas, a, PEN_A, scaled(scene, 6))
			fan(canvas, b, cx, cy, FILL_B)
			outline(canvas, b, PEN_B, scaled(scene, 3))
		end),
		preset("Mandala", COPY, colors(col(1), nil, col(3), nil), function(canvas, state, _, scene)
			local h, cx, cy = scene.height, scene.width // 2, scene.height // 2
			local a, b = {}, {}
			for index = 1, 128 do
				local value = state.wave[index * 8]
				local angle = (index - 1) * TAU / 127
				local s, c = math.sin(angle), math.cos(angle)
				a[index] = Vector2(round(s * h * value / 255 / 2) + cx, round(c * h * value / 255 / 2) + cy)
				local other = state.right[index * 8]
				b[index] = Vector2(round(s * h * other / 255 / 5) + cx, round(c * h * other / 255 / 5) + cy)
			end
			outline(canvas, a, PEN_A, scaled(scene, 6))
			fan(canvas, b, cx, cy, FILL_B)
			outline(canvas, b, PEN_B, scaled(scene, 4))
		end),
		preset("Synchronicity", OR, colors(col(1), col(4), col(3), col(2)), function(canvas, state, audio, scene)
			local h, cx, cy = scene.height, scene.width // 2, scene.height // 2
			local a, b = {}, {}
			local unit = h / 480
			local seeds = grain(state, 256)
			for index = 1, 256 do
				local reach = h * bins.frequency(audio, index * 4 - 1, 1) / 255 / 2 * seeds[index] * seeds[index] * 2.2
				local angle = (index - 1) * TAU / 255
				local x, y = round(math.cos(angle) * reach), round(math.sin(angle) * reach)
				a[index] = Vector2(cx + x + unit, cy + y)
				b[index] = Vector2(cx - unit - x, cy - y)
			end
			fan(canvas, a, cx, cy, FILL_A)
			outline(canvas, a, PEN_A, scaled(scene, 4))
			fan(canvas, b, cx, cy, FILL_B)
			outline(canvas, b, PEN_B, scaled(scene, 4))
		end),
		preset("Synergy", OR, colors(col(1), nil, col(3), nil), function(canvas, state, _, scene)
			local h, cx, cy = scene.height, scene.width // 2, scene.height // 2
			local unit = h / 480
			local count = state.count
			local ox, oy = round(math.cos(count / 37) * 30) * unit, round(math.sin(count / 43) * 30) * unit
			local px, py = round(math.cos(count / 29) * 30) * unit, round(math.sin(count / 23) * 30) * unit
			local a, b = {}, {}
			for index = 1, 256 do
				local reach = h * state.wave[index * 4] / 255 / 3
				local other = h * state.right[index * 4] / 255 / 3
				local angle = (index - 1) * TAU / 255
				local s, c = math.sin(angle), math.cos(angle)
				a[index] = Vector2(cx + ox + round(s * reach), cy + oy + round(c * reach))
				b[index] = Vector2(cx + px - round(s * other), cy + py - round(c * other))
			end
			outline(canvas, a, PEN_A, scaled(scene, 5))
			outline(canvas, b, PEN_B, scaled(scene, 5))
		end),
		preset("Serenity", XOR, function(state, audio, scene)
			local values = state.col
			local a, b, c, d = values[1], values[2], values[3], values[4]
			push(scene, "fill_a", rgb(a[1], a[2], 255))
			push(scene, "pen_a", rgb(255, d[2], 255))
			push(scene, "fill_b", inverted(b))
			push(scene, "pen_b", shade(c))
			pulse(state, audio, 3, 2)
		end, function(canvas, state, _, scene)
			local h, cx, cy = scene.height, scene.width // 2, scene.height // 2
			local a, b = {}, {}
			for index = 1, 256 do
				local value = state.wave[index * 4]
				local angle = (index - 1) * TAU / 255
				local s, c = math.sin(angle), math.cos(angle)
				local outer = h * value / 255 / 6 + h / 3
				local inner = h * value / 255 / 8
				a[index] = Vector2(round(c * outer) + cx, round(s * outer) + cy)
				b[index] = Vector2(round(c * inner) + cx, round(s * inner) + cy)
			end
			fan(canvas, a, cx, cy, FILL_A)
			outline(canvas, a, PEN_A, scaled(scene, 6))
			fan(canvas, b, cx, cy, FILL_B)
			outline(canvas, b, PEN_B, scaled(scene, state.pulse))
		end),
		preset("Transcendence", XOR, blobs_step, function(canvas, state, audio, scene)
			for index = 1, 16 do
				local points = blobs_points(state, audio, index, scene)
				outline(canvas, points, bit(index), scaled(scene, 3))
			end
		end),
		preset("The coyote is laughing (he is)", XOR, blobs_step, function(canvas, state, audio, scene)
			for index = 1, 16 do
				local points, cx, cy = blobs_points(state, audio, index, scene)
				fan(canvas, points, cx, cy, bit(index))
			end
		end),
	},
}

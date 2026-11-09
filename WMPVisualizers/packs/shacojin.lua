local bins = require("packs.wmp_bins")

local TRAIL = "shaders/common/trail.gdshader"
local RINGS = 9
local RING_STEPS = 24

local function bytes(audio)
	local list = {}
	for bin = 2, 505 do
		list[bin] = math.floor(math.min(255, bins.frequency(audio, bin) * bins.grain(audio)))
	end
	if audio.stereo then
		list[0], list[1] = bins.frequency(audio, 0), bins.frequency(audio, 1)
	else
		list[0] = math.floor(math.min(255, list[2] * 0.33 * bins.grain(audio)))
		list[1] = math.floor(math.min(255, list[2] * 0.69 * bins.grain(audio)))
	end
	return list
end

local function ring_points(cx, cy, rx, ry)
	local points = {}
	for step = 0, RING_STEPS do
		local angle = step / RING_STEPS * math.pi * 2
		points[step + 1] = Vector2(cx + math.cos(angle) * rx, cy + math.sin(angle) * ry)
	end
	return points
end

local function trunc(value)
	return value < 0 and math.ceil(value) or math.floor(value)
end

local function pass_lines(data, state, cx, cy, scale)
	local sine, cosine = state.sine, state.cosine
	local x_sign, y_sign = state.x_sign, state.y_sign
	local branches = {}
	local x, y, x_factor, y_factor, step, points = 0, 0, 0.0, 0.0, 0.6, nil
	for index = 0, 249 do
		if index % 10 == 0 then
			x_sign = -x_sign
		end
		if index % 15 == 0 then
			y_sign = -y_sign
		end
		local x_byte = data[index + (index % 2) * 256]
		local y_byte = data[index + ((index + 1) % 2) * 256]
		if index % 50 == 0 then
			points = { Vector2(cx, cy) }
			branches[#branches + 1] = points
			x = trunc(x_sign * x_byte * sine * 0.6)
			y = trunc(y_sign * y_byte * cosine * 0.6)
			x_factor, y_factor = x_sign * sine, y_sign * cosine
			step = 0.6
		else
			if index % 10 == 0 then
				x_sign = -x_sign
			end
			if index % 12 == 0 then
				y_sign = -y_sign
			end
			local px, py = x, y
			x = trunc(x + x_byte * x_sign * step * x_factor)
			y = trunc(y + y_byte * y_sign * step * y_factor)
			local dx, dy = x - px, y - py
			local length = math.sqrt(dx * dx + dy * dy)
			if dx ~= 0 then
				x_factor = dx / length
			end
			if dy ~= 0 then
				y_factor = dy / length
			end
		end
		points[#points + 1] = Vector2(cx + x * scale, cy + y * scale)
		step = step * 5 / 6
	end
	state.x_sign, state.y_sign = x_sign, y_sign
	return branches
end

local function shacojin(name, spin, shift, beat)
	return {
		name = name,
		feedback = TRAIL,
		params = { fade = Color(1.0, 1.0, 1.0) },
		setup = function(state)
			state.color = 0
			state.angle = 120.0
			state.average = 0
			state.since = 0
			state.flash = nil
			state.passes = {}
			state.rings = {}
		end,
		step = function(state, audio, scene)
			local width, height = scene.width, scene.height
			local data = bytes(audio)
			local impact = (data[0] + data[1]) * 3
			state.average = (state.average + impact) // 2
			state.color = (state.color + ((impact + (data[50] + data[200]) * 10) >> 2) // shift) % 0x8f7
			state.angle = state.angle + ((data[3] + (data[10] + data[5]) * 2 + data[2]) >> 2) / spin
			if state.angle > 360 then
				state.angle = state.angle - 360
			end
			local radians = math.pi * state.angle / 180
			state.sine, state.cosine = math.sin(radians), math.cos(radians)
			state.flash = nil
			if (state.average // beat < impact - state.average or state.average == 0) and state.since > 4 then
				local color = state.color
				state.flash = Color((color % 240 + 15) / 255, ((color // 5) % 240 + 15) / 255, ((color * 23) % 240 + 15) / 255, 1.0)
				state.since = 0
			end
			state.since = state.since + 1
			local cx, cy = width // 2, height // 2
			local scale = height / 480
			state.rings = {}
			for index = 1, RINGS do
				local a, b = data[index * 25], data[256 + index * 25]
				if a ~= b then
					state.rings[#state.rings + 1] = ring_points(cx, cy, math.log(a + 1) * width * 0.0125, math.log(b + 1) * height * 0.0125)
				end
			end
			state.x_sign, state.y_sign = 1, 1
			state.passes = { pass_lines(data, state, cx, cy, scale), pass_lines(data, state, cx, cy, scale) }
		end,
		draw = function(canvas, state, _, scene)
			local scale = scene.height / 480
			if state.flash then
				canvas:draw_rect(Rect2(0, 0, scene.width, scene.height), state.flash)
			end
			local color = state.color
			for pass = 5, 15, 5 do
				local factor = 255 / ((15 - pass) * 4 + 255)
				local pen = Color(((color // 9) % 255) * factor / 255, ((color // 3) % 255) * factor / 255, (color % 255) * factor / 255, 1.0)
				local thick = (pass == 5 and 5 or 7 - pass * 2 // 5) * scale
				for _, points in ipairs(state.rings) do
					canvas:draw_polyline(points, pen, thick)
				end
				for _, points in ipairs(state.passes[pass == 10 and 2 or 1]) do
					canvas:draw_polyline(points, pen, thick)
				end
			end
		end,
	}
end

return {
	name = "Shacojin",
	presets = {
		shacojin("mello", 160, 200, 8),
		shacojin("groove", 60, 300, 7),
		shacojin("chill", 300, 400, 8),
		shacojin("freak", 2, 10, 6),
	},
}

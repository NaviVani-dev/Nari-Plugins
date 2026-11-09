local bins = require("packs.wmp_bins")

local TRAIL = "shaders/common/trail.gdshader"

local PENS = {
	Color(0.388, 0.722, 1.0), Color(0.361, 0.675, 0.933), Color(0.118, 0.565, 1.0), Color(0.11, 0.525, 0.933), Color(0.063, 0.306, 0.545),
	Color(0.863, 0.078, 0.235), Color(1.0, 0.188, 0.188), Color(0.933, 0.173, 0.173), Color(0.804, 0.149, 0.149), Color(0.545, 0.102, 0.102),
	Color(0.388, 0.722, 1.0), Color(0.361, 0.675, 0.933), Color(0.118, 0.565, 1.0), Color(0.804, 0.149, 0.149), Color(0.545, 0.102, 0.102),
	Color(0.714, 0.0, 0.733), Color(0.537, 0.008, 0.553), Color(0.757, 0.008, 0.8), Color(0.875, 0.035, 0.906), Color(0.549, 0.0, 0.584),
}
local DOTS = {
	Color(0.69, 0.886, 0.996),
	Color(0.996, 0.251, 0.251),
	Color(0.0, 0.996, 0.0),
	Color(0.996, 0.255, 0.004),
	Color(0.996, 0.996, 0.996),
}
local LEVELS = 4
local SIZES = 24

local shapes = {}
local star

local function apex(x1, y1, x2, y2)
	local length = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
	local angle = math.atan(y2 - y1, x2 - x1) - 1.0471976
	return x1 + math.cos(angle) * length, y1 + math.sin(angle) * length
end

local function shape(size)
	if shapes[size] then
		return shapes[size]
	end
	local half = (size * 4 + 1) // 2
	local ax, ay = apex(-half, 0, half, 23)
	local points = { -half, 0, half, 23, ax, ay }
	for _ = 1, LEVELS do
		local next_points = {}
		local count = #points // 2
		for index = 0, count - 1 do
			local x1, y1 = points[index * 2 + 1], points[index * 2 + 2]
			local other = (index + 1) % count
			local x2, y2 = points[other * 2 + 1], points[other * 2 + 2]
			local dx, dy = (x2 - x1) / 3, (y2 - y1) / 3
			local px, py = apex(x1 + dx * 2, y1 + dy * 2, x1 + dx, y1 + dy)
			local at = #next_points
			next_points[at + 1], next_points[at + 2] = x1, y1
			next_points[at + 3], next_points[at + 4] = x1 + dx, y1 + dy
			next_points[at + 5], next_points[at + 6] = px, py
			next_points[at + 7], next_points[at + 8] = x1 + dx * 2, y1 + dy * 2
		end
		points = next_points
	end
	local result = {}
	for index = 1, #points, 2 do
		result[#result + 1] = Vector2(points[index], points[index + 1])
	end
	result[#result + 1] = result[1]
	shapes[size] = result
	return result
end

local function winter(name, case)
	return {
		name = name,
		feedback = TRAIL,
		params = { fade = Color(0.784, 0.784, 0.784) },
		setup = function(state)
			star = star or nari.load("assets/winter_wave/star.png")
			state.pens = {}
			if case == 4 then
				local function rnd()
					return math.random()
				end
				state.pens = { Color(rnd(), rnd(), 1.0), Color(1.0, rnd(), rnd()), Color(rnd(), 1.0, rnd()), Color(1.0, rnd(), 1.0), Color(rnd(), 1.0, 1.0) }
			else
				for index = 1, 5 do
					state.pens[index] = PENS[case * 5 + index]
				end
			end
			state.flakes = {}
			for index = 0, 9 do
				state.flakes[index] = { size = SIZES - 1, pen = state.pens[1], x = 0, y = 0 }
			end
		end,
		step = function(state, audio, scene)
			for index = 0, 9 do
				local item = state.flakes[index]
				local value = bins.sample(audio, index / 10) * 0.5 + 0.5
				item.angle = value * math.pi
				item.size = item.size + 1
				if item.size >= SIZES then
					item.size = math.floor(value * SIZES)
					item.pen = state.pens[math.random(5)]
					item.x = index / 10
					item.y = math.random()
				end
			end
			if case == 4 then
				if math.random(0, 253) + 200 < 255 then
					state.dot = DOTS[5]
				else
					state.dot = Color(math.random(), math.random(), math.random())
				end
			else
				state.dot = math.random(0, 249) + 20 < 255 and DOTS[case + 1] or Color(math.random(), math.random(), math.random())
			end
		end,
		draw = function(canvas, state, audio, scene)
			local width, height = scene.width, scene.height
			local scale = height / 480
			for index = 0, 9 do
				local item = state.flakes[index]
				canvas:draw_set_transform(Vector2(item.x * width, item.y * height), item.angle, Vector2(scale, scale))
				canvas:draw_polyline(shape(item.size), item.pen, 1.0)
			end
			canvas:draw_set_transform(Vector2(0.0, 0.0), 0.0, Vector2(1.0, 1.0))
			local w, h = 10 * scale, 11 * scale
			for column = 0, 199 do
				local position = column / 199
				canvas:draw_texture_rect(star, Rect2(position * width - w, (bins.sample(audio, position) * 0.5 + 0.5) * height - h / 2, w, h), false, state.dot)
			end
		end,
	}
end

return {
	name = "Winter Wave",
	presets = {
		winter("Snow Flakes", 0),
		winter("Snow Flames", 1),
		winter("Snow Flaves", 2),
		winter("Snow Flapes", 3),
		winter("Random", 4),
	},
}

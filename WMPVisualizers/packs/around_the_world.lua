local lib = require("lib")
local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"

local function value(audio, index, count)
	return math.max(0.08, bins.band(audio, 0.05 + index / math.max(count, 1) * 0.6, 0.35))
end

local function horizontal(colors)
	return function(canvas, audio, scene)
		local count = #colors
		local band = scene.height / count
		for index, color in ipairs(colors) do
			canvas:draw_rect(Rect2(0, (index - 1) * band, scene.width * value(audio, index - 1, count), band), Color(color))
		end
	end
end

local function vertical(colors)
	return function(canvas, audio, scene)
		local count = #colors
		local band = scene.width / count
		for index, color in ipairs(colors) do
			local reach = scene.height * value(audio, index - 1, count)
			canvas:draw_rect(Rect2((index - 1) * band, scene.height - reach, band, reach), Color(color))
		end
	end
end

local function star(canvas, x, y, radius, color)
	local points = {}
	for corner = 0, 9 do
		local angle = -math.pi / 2 + corner * math.pi / 5
		local reach = corner % 2 == 0 and radius or radius * 0.4
		points[#points + 1] = Vector2(x + math.cos(angle) * reach, y + math.sin(angle) * reach)
	end
	canvas:draw_colored_polygon(points, color)
end

local function japan(canvas, audio, scene)
	local w, h = scene.width, scene.height
	local reach, rise = value(audio, 0, 3), value(audio, 1, 3)
	canvas:draw_rect(Rect2(0, h * (1 - rise), w * reach, h * rise), Color("#ffffff"))
	canvas:draw_circle(Vector2(w / 2, h / 2), h * (0.1 + value(audio, 2, 3) * 0.22), Color("#f42404"))
end

local TRIGRAMS = { { 1, 1, 1 }, { 2, 1, 2 }, { 2, 2, 2 }, { 1, 2, 1 } }

local function korea(canvas, audio, scene)
	local w, h = scene.width, scene.height
	local cx, cy = w / 2, h / 2
	local half_w, half_h = w * 0.5 * value(audio, 0, 4), h * 0.5 * value(audio, 1, 4)
	canvas:draw_rect(Rect2(cx - half_w, cy - half_h, half_w * 2, half_h * 2), Color("#ffffff"))
	local black = Color("#000000")
	for corner = 0, 3 do
		local angle = -math.pi * 3 / 4 + corner * math.pi / 2
		local dx, dy = math.cos(angle), math.sin(angle)
		local sx, sy = -dy, dx
		local thick, long = h * 0.04, h * 0.14
		for bar = 1, 3 do
			local reach = h * (0.46 + bar * 0.06)
			local x, y = cx + dx * reach * 1.15, cy + dy * reach
			if TRIGRAMS[corner + 1][bar] == 1 then
				canvas:draw_line(Vector2(x - sx * long, y - sy * long), Vector2(x + sx * long, y + sy * long), black, thick)
			else
				canvas:draw_line(Vector2(x - sx * long, y - sy * long), Vector2(x - sx * long * 0.12, y - sy * long * 0.12), black, thick)
				canvas:draw_line(Vector2(x + sx * long * 0.12, y + sy * long * 0.12), Vector2(x + sx * long, y + sy * long), black, thick)
			end
		end
	end
	canvas:draw_rect(Rect2(0, 0, w, cy - half_h), black)
	canvas:draw_rect(Rect2(0, cy + half_h, w, h), black)
	canvas:draw_rect(Rect2(0, 0, cx - half_w, h), black)
	canvas:draw_rect(Rect2(cx + half_w, 0, w, h), black)
	local radius = h * (0.1 + value(audio, 2, 4) * 0.2)
	local turn = -0.45
	local red, blue = Color("#f42404"), Color("#4c4ca4")
	canvas:draw_circle(Vector2(cx, cy), radius, blue)
	local top = {}
	for step = 0, 32 do
		local angle = turn + math.pi + step / 32 * math.pi
		top[#top + 1] = Vector2(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius)
	end
	canvas:draw_colored_polygon(top, red)
	canvas:draw_circle(Vector2(cx - math.cos(turn) * radius / 2, cy - math.sin(turn) * radius / 2), radius / 2, red)
	canvas:draw_circle(Vector2(cx + math.cos(turn) * radius / 2, cy + math.sin(turn) * radius / 2), radius / 2, blue)
end

local function uk(canvas, audio, scene)
	local w, h = scene.width, scene.height
	local blue, white, red = Color("#4c4ca4"), Color("#ffffff"), Color("#f42404")
	canvas:draw_rect(Rect2(0, 0, w, h), blue)
	canvas:draw_line(Vector2(0, 0), Vector2(w, h), white, h * 0.11)
	canvas:draw_line(Vector2(w, 0), Vector2(0, h), white, h * 0.11)
	canvas:draw_rect(Rect2(0, h * 0.34, w, h * 0.32), white)
	canvas:draw_rect(Rect2(w * 0.38, 0, w * 0.24, h), white)
	local hole = {}
	for corner = 0, 7 do
		local angle = corner * math.pi / 4
		local reach = 1 - value(audio, corner, 8)
		hole[corner + 1] = Vector2(w / 2 + math.cos(angle) * w * 0.5 * reach, h / 2 + math.sin(angle) * h * 0.5 * reach)
	end
	canvas:draw_colored_polygon(hole, Color("#000000"))
	for corner = 0, 3 do
		local reach = 0.2 + value(audio, corner + 4, 8) * 0.8
		local horizontal = corner % 2 == 0
		local arm = reach * (horizontal and w / 2 or h / 2)
		if corner == 0 then
			canvas:draw_rect(Rect2(w - arm, h * 0.42, arm, h * 0.16), red)
		elseif corner == 1 then
			canvas:draw_rect(Rect2(w * 0.45, h - arm, w * 0.1, arm), red)
		elseif corner == 2 then
			canvas:draw_rect(Rect2(0, h * 0.42, arm, h * 0.16), red)
		else
			canvas:draw_rect(Rect2(w * 0.45, 0, w * 0.1, arm), red)
		end
		local angle = math.pi / 4 + corner * math.pi / 2
		local ex, ey = w / 2 + math.cos(angle) * w * 0.71, h / 2 + math.sin(angle) * h * 0.71
		local tip = 0.7 - value(audio, corner, 8) * 0.7
		local bx, by = w / 2 + math.cos(angle) * w * 0.71 * tip, h / 2 + math.sin(angle) * h * 0.71 * tip
		canvas:draw_line(Vector2(bx, by), Vector2(ex, ey), red, h * 0.04)
	end
end

local function usa(canvas, audio, scene)
	local w, h = scene.width, scene.height
	local stripe = h / 13
	for index = 0, 12 do
		if index % 2 == 0 then
			canvas:draw_rect(Rect2(0, index * stripe, w, stripe), Color("#d03700"))
		else
			canvas:draw_rect(Rect2(0, index * stripe, w * value(audio, index, 13), stripe), Color("#ffffff"))
		end
	end
	canvas:draw_rect(Rect2(0, 0, w * 0.416, stripe * 7), Color("#11217c"))
	for row = 0, 8 do
		for column = 0, (row % 2 == 0 and 5 or 4) do
			star(canvas, w * 0.416 * ((column + (row % 2 == 0 and 0.5 or 1)) / 6), stripe * 7 * (row + 0.5) / 9, h * 0.024, Color("#ffffff"))
		end
	end
end

local FLAGS = {
	{ "Austria", horizontal({ "#dc2c04", "#ffffff", "#dc2c04" }) },
	{ "France", vertical({ "#393a8c", "#ffffff", "#de012c" }) },
	{ "Germany", horizontal({ "#040c0c", "#fc2c04", "#fcac2c" }) },
	{ "Italy", vertical({ "#5cc43c", "#ffffff", "#f42c04" }) },
	{ "Japan", japan },
	{ "Korea", korea },
	{ "Netherlands", horizontal({ "#f42404", "#ffffff", "#4c4ca4" }) },
	{ "Russia", horizontal({ "#ffffff", "#5b57ac", "#ef2800" }) },
	{ "UK", uk },
	{ "USA", usa },
}

local function flag(name, draw, tour)
	return {
		name = name,
		aspect = 4 / 3,
		layers = { CLEAR },
		setup = function(state)
			state.time, state.index = 0, math.random(#FLAGS)
		end,
		step = function(state)
			state.time = state.time + 1 / 30
			if tour and state.time > (state.next or 0.67) then
				state.next = state.time + 0.67
				state.index = (state.index + math.random(#FLAGS - 1) - 1) % #FLAGS + 1
			end
		end,
		draw = function(canvas, state, audio, scene)
			local paint = tour and FLAGS[state.index][2] or draw
			paint(canvas, audio, scene, state)
		end,
	}
end

local presets = {}
for _, item in ipairs(FLAGS) do
	presets[#presets + 1] = flag(item[1], item[2], false)
end
presets[#presets + 1] = flag("World Tour", nil, true)

return {
	name = "Around the World in 206 Milliseconds",
	light = true,
	presets = presets,
}

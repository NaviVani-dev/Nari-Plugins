local bins = require("packs.wmp_bins")
local FEEDBACK = "shaders/ambience/feedback.gdshader"
local PALETTE = "shaders/ambience/palette.gdshader"

local PALETTES = {
	{ "#000060", "#7090ff", "#000060", "#ffffff" },
	{ "#006000", "#90ff70", "#006000", "#ffffff" },
	{ "#600000", "#ff9070", "#600000", "#ffffff" },
	{ "#600060", "#ff70ff", "#600060", "#ffffff" },
	{ "#006060", "#70ffff", "#006060", "#ffffff" },
	{ "#606000", "#ffff70", "#606000", "#ffffff" },
	{ "#606060", "#ffffff", "#606060", "#ffffff" },
	{ "#000000", "#ff0000", "#000000", "#ffffff" },
	{ "#000000", "#00ff00", "#000000", "#ffffff" },
	{ "#000000", "#0000ff", "#000000", "#ffffff" },
	{ "#000000", "#ff00ff", "#000000", "#ffffff" },
	{ "#000000", "#00ffff", "#000000", "#ffffff" },
	{ "#000000", "#ffff00", "#000000", "#ffffff" },
	{ "#600000", "#ff9070", "#ff9070", "#ffffff" },
	{ "#006000", "#90ff70", "#90ff70", "#ffffff" },
	{ "#000060", "#7090ff", "#7090ff", "#ffffff" },
	{ "#600060", "#ff70ff", "#ff70ff", "#ffffff" },
	{ "#006060", "#70ffff", "#70ffff", "#ffffff" },
	{ "#606000", "#ffff70", "#ffff70", "#ffffff" },
	{ "#606060", "#a0a0a0", "#a0a0a0", "#ffffff" },
	{ "#000000", "#ff0000", "#ff0000", "#ffffff" },
	{ "#000000", "#00ff00", "#00ff00", "#ffffff" },
	{ "#000000", "#0000ff", "#0000ff", "#ffffff" },
	{ "#000000", "#ff00ff", "#ff00ff", "#ffffff" },
	{ "#000000", "#00ffff", "#00ffff", "#ffffff" },
	{ "#000000", "#ffff00", "#ffff00", "#ffffff" },
}

local DARK, LIGHT = 0, 13

local function shade(value)
	return Color(math.floor(value) % 256 / 255, 0, 0, 1)
end

local function keys(index)
	local result = {}
	for slot, hex in ipairs(PALETTES[index]) do
		result[slot] = Color(hex)
	end
	return result
end

local function blend(from, to, amount)
	local result = {}
	for slot = 1, 4 do
		local a, b = from[slot], to[slot]
		result[slot] = Color(a.r + (b.r - a.r) * amount, a.g + (b.g - a.g) * amount, a.b + (b.b - a.b) * amount, 1)
	end
	return result
end

local function palette(state, start, count)
	local current = state.palette
	local fading = current.amount < 1
	if current.family == start and (fading or current.timer > 1) then
		if not fading then
			current.timer = current.timer - 1
		end
		return
	end
	local frames = current.family == start and math.random(200, 1000) or 200
	current.from = blend(current.from, current.to, current.amount)
	current.to = keys(start + math.random(count))
	current.amount = 0
	current.rate = 1 / frames
	current.timer = math.random(100, 600)
	current.family = start
end

local function push_palette(state, scene)
	local current = state.palette
	current.amount = math.min(1, current.amount + current.rate)
	for slot = 1, 4 do
		scene.engine.set(scene, "from_" .. (slot - 1), current.from[slot])
		scene.engine.set(scene, "to_" .. (slot - 1), current.to[slot])
	end
	scene.engine.set(scene, "blend", current.amount)
end

local function band(audio, index)
	local bands = audio.bands or {}
	return (bands[index] or 0) * 255
end

local function beat(state, audio)
	if state.low > 200 then
		state.low = state.low - 1
	end
	if state.high > 170 then
		state.high = state.high - 1
	end
	local bass = (band(audio, 1) + band(audio, 2)) * 0.5
	local middle = (band(audio, 4) + band(audio, 5)) * 0.5
	state.bass = (state.bass or bass) * 0.95 + bass * 0.05
	state.middle = (state.middle or middle) * 0.95 + middle * 0.05
	local low = math.max(0, math.min(255, (bass - state.bass) * 4 + 196))
	local high = math.max(0, math.min(255, (middle - state.middle) * 4 + 166))
	state.low = math.max(state.low, low)
	state.high = math.max(state.high, high)
	if state.low == low and state.high == high then
		state.low = low + 10
		state.high = high + 10
		return true
	end
	return false
end

local function big_beat(state, audio)
	local total = 0
	for index = 1, 8 do
		total = total + band(audio, index)
	end
	local quieter = 0
	for _, value in ipairs(state.history) do
		if total > value then
			quieter = quieter + 1
		end
	end
	state.history[state.cursor] = total
	state.cursor = state.cursor % 80 + 1
	return quieter >= 61
end

local function sample(audio, position)
	return bins.sample(audio, math.max(0, math.min(1, position)))
end

local function wave_line(canvas, audio, y, left, right, height, color)
	local points = {}
	for step = 0, 255 do
		local position = step / 255
		points[#points + 1] = Vector2(left + (right - left) * position + 0.5, y + sample(audio, position) * height * 0.5 + 0.5)
	end
	canvas:draw_polyline(points, shade(color))
end

local function circle_wave(canvas, audio, scene, radius, height, first, last)
	local cx, cy = scene.width / 2, scene.height / 2
	local top, bottom, colors = {}, {}, {}
	for step = 0, 255 do
		local position = step / 255
		local angle = position * math.pi
		local reach = radius + sample(audio, position) * height * 0.5
		top[#top + 1] = Vector2(cx + math.cos(angle) * reach + 0.5, cy + math.sin(angle) * reach + 0.5)
		bottom[#bottom + 1] = Vector2(cx + math.cos(angle) * reach + 0.5, cy - math.sin(angle) * reach + 0.5)
		colors[#colors + 1] = shade(first + (last - first) * position)
	end
	canvas:draw_polyline_colors(top, colors)
	canvas:draw_polyline_colors(bottom, colors)
end

local function burst(canvas, audio, scene, radius, height, color)
	local cx, cy = scene.width / 2, scene.height / 2
	local center = Vector2(cx + 0.5, cy + 0.5)
	for step = 0, 254, 2 do
		local position = step / 255
		local angle = position * math.pi
		local reach = radius + sample(audio, position) * height * 0.5
		local value = color + band(audio, math.floor(position * 31) + 1) * 0.25
		local x = cx + math.cos(angle) * reach + 0.5
		local lower, upper = Vector2(x, cy + math.sin(angle) * reach + 0.5), Vector2(x, cy - math.sin(angle) * reach + 0.5)
		if step % 4 == 0 then
			canvas:draw_line(center, lower, shade(value))
			canvas:draw_line(center, upper, shade(value))
		else
			canvas:draw_rect(Rect2(lower.x, lower.y, 1, 1), shade(value))
			canvas:draw_rect(Rect2(upper.x, upper.y, 1, 1), shade(value))
		end
	end
end

local function stick(canvas, audio, angle, x, y, reach, height, color)
	local dx, dy = math.cos(angle), math.sin(angle)
	local points = {}
	for step = 0, 255 do
		local position = step / 255
		local along = (position * 2 - 1) * reach
		local offset = sample(audio, position) * height * 0.5
		points[#points + 1] = Vector2(x + dx * along - dy * offset + 0.5, y + dy * along + dx * offset + 0.5)
	end
	canvas:draw_polyline(points, shade(color))
end

local function sparkles(canvas, scene, level)
	local count = math.floor(level * 30)
	local cx, cy = scene.width / 2, scene.height / 2
	for _ = 1, count do
		local x = math.floor(cx + (math.random() * 2 - 1) * cx * level)
		local y = math.floor(cy + (math.random() * 2 - 1) * cy * level)
		canvas:draw_rect(Rect2(x - 1, y, 3, 1), shade(180))
		canvas:draw_rect(Rect2(x, y - 1, 1, 3), shade(180))
		canvas:draw_rect(Rect2(x, y, 1, 1), shade(254))
	end
end

local function frame(canvas, scene, color)
	canvas:draw_rect(Rect2(0.5, 0.5, scene.width - 1, scene.height - 1), shade(color), false)
end

local function fill(canvas, scene, color)
	canvas:draw_rect(Rect2(0, 0, scene.width, scene.height), shade(color))
end

local function half(scene)
	return scene.width / 2, scene.height / 2
end

local function preset(spec)
	return {
		name = spec.name,
		feedback = FEEDBACK,
		display = PALETTE,
		filter = "nearest",
		params = {
			fade = spec.fade ~= false,
			fade_low = spec.fade_low or 2,
			fade_high = spec.fade_high or spec.fade_low or 2,
			blur_first = spec.blur_first == true,
		},
		setup = function(state, scene)
			state.palette = { from = keys(1), to = keys(1), amount = 1, rate = 1, timer = 0, family = -1 }
			state.low, state.high = 200, 170
			state.history, state.cursor = {}, 1
			state.table = 1
			state.flag = spec.flag or false
			state.angle = spec.angle or 0
			state.counter = 0
			if spec.setup then
				spec.setup(state, scene)
			end
		end,
		step = function(state, audio, scene)
			state.beat = beat(state, audio)
			state.big = big_beat(state, audio)
			local family = spec.family or LIGHT
			if type(family) == "function" then
				family = family(state)
			end
			palette(state, family, 13)
			push_palette(state, scene)
			spec.step(state, audio, scene)
			local warp = spec.warps[state.table] or spec.warps[1]
			local amount = warp[3] or 0
			if type(amount) == "function" then
				amount = amount(scene)
			end
			scene.engine.set(scene, "warp", warp[1])
			scene.engine.set(scene, "rot", warp[2])
			scene.engine.set(scene, "amount", amount)
		end,
		draw = function(canvas, state, audio, scene)
			if scene.width and state.palette then
				spec.draw(canvas, state, audio, scene)
			end
		end,
	}
end

local function width_of(factor)
	return function(scene) return scene.width * factor end
end

local function toggle_on_beat(state)
	if state.beat then
		state.table = 3 - state.table
	end
end

local function dark_or_light(state)
	return state.flag and LIGHT or DARK
end

local presets = {
	preset({
		name = "Swirl",
		family = DARK,
		fade_low = 4,
		fade_high = 2,
		warps = { { 1, 0.07, 1 } },
		step = function() end,
		draw = function(canvas, state, audio, scene)
			local cx, cy = half(scene)
			if state.beat then
				fill(canvas, scene, 254)
				frame(canvas, scene, 127)
			end
			burst(canvas, audio, scene, cx - cx / 4, cx / 4, 1)
			wave_line(canvas, audio, cy / 2, 3, scene.width - 4, cy / 4, 127)
			wave_line(canvas, audio, cy * 1.5, 3, scene.width - 4, cy / 4, 127)
		end,
	}),
	preset({
		name = "Warp",
		fade = false,
		warps = { { 2, -0.07, width_of(0.05) } },
		step = function() end,
		draw = function(canvas, state, audio, scene)
			local cx, cy = half(scene)
			local radius = math.floor(cy / 8)
			if state.beat then
				for _, gap in ipairs({ 2, 4, 6 }) do
					circle_wave(canvas, audio, scene, radius, radius - gap, 200, 254)
				end
			end
			circle_wave(canvas, audio, scene, radius, radius, 1, 254)
			canvas:draw_rect(Rect2(cx - 1, cy - 1, 2, 2), shade(1))
		end,
	}),
	preset({
		name = "Anon",
		warps = { { 2, 0.04, width_of(0.05) }, { 2, -0.04, width_of(0.05) } },
		step = toggle_on_beat,
		draw = function(canvas, state, audio, scene)
			local _, cy = half(scene)
			burst(canvas, audio, scene, cy / 2, 0, 1)
			wave_line(canvas, audio, cy, 3, scene.width - 4, cy / 2, 254)
			if state.beat then
				wave_line(canvas, audio, cy + 2, 3, scene.width - 4, cy / 2, 254)
				wave_line(canvas, audio, cy - 2, 3, scene.width - 4, cy / 2, 254)
			end
		end,
	}),
	preset({
		name = "Falloff",
		warps = { { 3, -0.05, width_of(-0.02) } },
		step = function() end,
		draw = function(canvas, state, audio, scene)
			local _, cy = half(scene)
			local width, height = scene.width, scene.height
			if state.big then
				wave_line(canvas, audio, cy, 3, width - 4, cy, 254)
			end
			if state.beat then
				wave_line(canvas, audio, cy + 2, 3, width - 4, cy, 254)
				wave_line(canvas, audio, cy - 2, 3, width - 4, cy, 254)
			end
			canvas:draw_rect(Rect2(0, 0, width, 1), shade(254))
			canvas:draw_rect(Rect2(0, height - 1, width, 1), shade(254))
			canvas:draw_rect(Rect2(0, 0, 3, height), shade(254))
			canvas:draw_rect(Rect2(width - 3, 0, 3, height), shade(254))
		end,
	}),
	preset({
		name = "Water",
		family = dark_or_light,
		flag = true,
		fade_low = 1,
		warps = { { 10, -0.05, width_of(0.01) } },
		step = function(state)
			if state.beat and state.palette.amount >= 1 and math.random(state.flag and 4 or 2) == 1 then
				state.flag = not state.flag
			end
		end,
		draw = function(canvas, state, audio, scene)
			local _, cy = half(scene)
			wave_line(canvas, audio, cy, 3, scene.width - 4, cy / 2, state.flag and 254 or 127)
			circle_wave(canvas, audio, scene, cy - 1, 0, 127, 127)
		end,
	}),
	preset({
		name = "Bubble",
		family = dark_or_light,
		flag = true,
		warps = { { 4, 0, 1 } },
		step = function(state)
			if state.beat and state.palette.amount >= 1 and math.random(state.flag and 2 or 1) == 1 then
				state.flag = not state.flag
			end
		end,
		draw = function(canvas, _, audio, scene)
			local _, cy = half(scene)
			local outer = cy / 2 - cy / 8
			circle_wave(canvas, audio, scene, outer / 2, outer, 254, 254)
			circle_wave(canvas, audio, scene, cy / 16, cy / 8, 1, 1)
			frame(canvas, scene, 1)
		end,
	}),
	preset({
		name = "Dizzy",
		fade_low = 1,
		warps = { { 5, -0.05, 1 }, { 5, 0.05, 1 } },
		step = toggle_on_beat,
		draw = function(canvas, state, audio, scene)
			local _, cy = half(scene)
			if state.beat then
				canvas:draw_rect(Rect2(0, 0, scene.width, 1), shade(254))
				canvas:draw_rect(Rect2(0, scene.height - 1, scene.width, 1), shade(254))
			end
			wave_line(canvas, audio, cy / 2, 3, scene.width - 4, cy - 2, 254)
			wave_line(canvas, audio, cy * 1.5, 3, scene.width - 4, cy - 2, 254)
			burst(canvas, audio, scene, cy / 4, 0, 1)
		end,
	}),
	preset({
		name = "Windmill",
		fade_low = 3,
		warps = { { 2, -0.03, width_of(0.04) } },
		step = function(state)
			state.angle = state.angle + 0.005
		end,
		draw = function(canvas, state, audio, scene)
			local cx, cy = half(scene)
			if state.beat then
				if math.random(8) == 1 then
					fill(canvas, scene, 254)
				end
				sparkles(canvas, scene, audio.level or 0)
			end
			stick(canvas, audio, state.angle, cx, cy - cy / 4, cx * 0.9, cy / 2, 254)
			stick(canvas, audio, state.angle, cx, cy + cy / 4, cx * 0.9, cy / 2, 254)
			frame(canvas, scene, 1)
		end,
	}),
	preset({
		name = "Niagara",
		family = dark_or_light,
		flag = true,
		fade = false,
		warps = { { 6, 0, 0.04 } },
		setup = function(state)
			state.stage, state.sweep = 0, 0
		end,
		step = function(state, _, scene)
			if state.stage == 0 then
				state.sweep = state.sweep + 1
				if state.sweep >= scene.height then
					state.stage, state.sweep = 1, 0
				end
			elseif state.stage == 1 then
				state.sweep = state.sweep + 1
				if scene.width / 2 - state.sweep <= scene.width / 16 + 2 then
					state.stage = 2
				end
			end
			if state.beat and state.stage == 2 and math.random(4) == 1 then
				state.flag = not state.flag
			end
		end,
		draw = function(canvas, state, audio, scene)
			local width, height = scene.width, scene.height
			local column = width / 16 + 2
			if state.stage == 0 then
				column = width / 2
			elseif state.stage == 1 then
				column = width / 2 - state.sweep
			end
			local middle = (state.stage == 0 and height - state.sweep or 0) + height / 2
			local function bars(first, last)
				for offset = first, last do
					stick(canvas, audio, math.pi / 2, column + offset, middle, height / 2, width / 8, 254)
					stick(canvas, audio, math.pi / 2, width - column - offset, middle, height / 2, width / 8, 254)
				end
			end
			if state.beat then
				bars(4, 11)
				for _ = 1, math.random(10) do
					canvas:draw_rect(Rect2(0, math.random(height) - 1, 1, 1), shade(254))
					canvas:draw_rect(Rect2(width - 1, math.random(height) - 1, 1, 1), shade(254))
					canvas:draw_rect(Rect2(math.random(width) - 1, 0, 1, 1), shade(254))
					canvas:draw_rect(Rect2(math.random(width) - 1, height - 1, 1, 1), shade(254))
				end
				if state.stage == 2 and math.random(16) == 1 then
					fill(canvas, scene, 127 + math.random(127))
				end
			end
			if state.big then
				bars(0, 2)
			end
		end,
	}),
	preset({
		name = "Blender",
		blur_first = true,
		warps = { { 7, 0.03, 1 }, { 7, -0.03, 1 } },
		step = toggle_on_beat,
		draw = function(canvas, _, audio, scene)
			local _, cy = half(scene)
			for offset = -1, 1 do
				wave_line(canvas, audio, cy + offset, 3, scene.width - 4, cy / 2, 254)
			end
		end,
	}),
	preset({
		name = "X Marks the Spot",
		blur_first = true,
		angle = math.pi / 4,
		warps = { { 2, 0.03, width_of(0.01) }, { 2, -0.03, width_of(0.01) } },
		step = function(state)
			if state.beat and math.random(5) == 1 then
				state.table = 3 - state.table
			end
			state.angle = state.angle + (state.table == 1 and -0.01 or 0.01)
		end,
		draw = function(canvas, state, audio, scene)
			local cx, cy = half(scene)
			if state.beat then
				if math.random(20) == 1 then
					fill(canvas, scene, 254)
				end
				if math.random(5) == 1 then
					sparkles(canvas, scene, audio.level or 0)
				end
			end
			if state.big then
				stick(canvas, audio, state.angle, cx, cy, cx, cy / 2, 254)
				stick(canvas, audio, state.angle + math.pi / 2, cx, cy, cx, cy / 2, 254)
			end
			frame(canvas, scene, 1)
		end,
	}),
	preset({
		name = "Down the Drain",
		fade = false,
		blur_first = true,
		warps = { { 2, 0.02, width_of(-0.01) } },
		step = function(state)
			if state.beat and math.random(10) == 1 then
				state.counter = state.counter + 20
			end
			state.angle = state.angle + 0.01
		end,
		draw = function(canvas, state, audio, scene)
			local cx, cy = half(scene)
			local orbit = cy / 2
			local x, y = math.cos(state.angle) * orbit, math.sin(state.angle) * orbit
			stick(canvas, audio, state.angle + math.pi / 2, cx - x, cy - y, cy, cy / 4, 254)
			stick(canvas, audio, state.angle + math.pi / 2, cx + x, cy + y, cy, cy / 4, 254)
			frame(canvas, scene, 1)
			if state.counter > 0 then
				for gx = 25, scene.width - 3, 25 do
					for gy = 25, scene.height - 3, 25 do
						canvas:draw_rect(Rect2(gx - 1, gy, 3, 1), shade(254))
						canvas:draw_rect(Rect2(gx, gy - 1, 1, 3), shade(254))
					end
				end
				state.counter = state.counter - 1
			end
		end,
	}),
	preset({
		name = "Thingus",
		fade_low = 1,
		blur_first = true,
		angle = math.pi / 4,
		warps = { { 8, 0.2, width_of(0.125) } },
		step = function(state)
			state.angle = state.angle - 0.03
		end,
		draw = function(canvas, state, audio, scene)
			local cx, cy = half(scene)
			if state.beat then
				if math.random(15) == 1 then
					fill(canvas, scene, 254)
				end
				sparkles(canvas, scene, audio.level or 0)
			end
			if state.big then
				stick(canvas, audio, state.angle, cx, cy, cx, cy / 2, 254)
				stick(canvas, audio, state.angle + math.pi / 2, cx, cy, cx, cy / 2, 254)
			end
			frame(canvas, scene, 1)
		end,
	}),
}

table.insert(presets, 1, {
	name = "Random",
	feedback = FEEDBACK,
	display = PALETTE,
	filter = "nearest",
	setup = function(state, scene)
		state.timer = 0
		state.inner = nil
	end,
	step = function(state, audio, scene)
		state.timer = state.timer - 1
		if state.timer <= 0 then
			local chosen = presets[math.random(2, #presets)]
			state.preset = chosen
			state.inner = {}
			state.timer = math.random(450, 900)
			for key, value in pairs(chosen.params) do
				scene.engine.set(scene, key, value)
			end
			chosen.setup(state.inner, scene)
		end
		state.preset.step(state.inner, audio, scene)
	end,
	draw = function(canvas, state, audio, scene)
		if state.inner then
			state.preset.draw(canvas, state.inner, audio, scene)
		end
	end,
})

return {
	name = "Ambience",
	presets = presets,
}

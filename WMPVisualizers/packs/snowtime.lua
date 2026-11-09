local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"

local images = {}

local function image(name)
	images[name] = images[name] or nari.load("assets/softie/" .. name .. ".png")
	return images[name]
end

local WHITE = Color(1.0, 1.0, 1.0, 1.0)
local SMILE = { { "smile1", 17, 29 }, { "smile2", 22, 25 }, { "smile3", 29, 22 }, { "smile2", 35, 21 }, { "smile1", 43, 21 }, { "smile3", 50, 22 }, { "smile2", 55, 25 }, { "smile1", 61, 29 } }
local KEEP = {}
do
	local source, carry = 0, 0
	while source < 225 do
		KEEP[#KEEP + 1] = source
		repeat
			source = source + 1
			carry = carry + 78
			local wrapped = carry >= 256
			carry = carry % 256
		until not wrapped
	end
end

local function spectrum(state, audio)
	local raw, smooth, spec, sum = state.raw, state.spec_smooth, state.spec, state.sum
	local level = 0
	for index = 1, 255 do
		local value = bins.shrunk(audio, index)
		raw[index] = value
		level = level + value
	end
	local count = #KEEP
	local total = 0
	for index = 1, count do
		local source = KEEP[index]
		local value = 0
		if source >= 10 then
			value = raw[256 - source] // 2
			if value ~= 0 then
				value = math.min(255, value + 20)
			end
		end
		spec[index - 1] = value
		total = total + value
		sum[index] = total
	end
	local last = spec[count - 1]
	for index = 0, count - 1 do
		local stop = index + 27
		local mean = sum[math.min(stop, count)] - (index > 0 and sum[index] or 0) + math.max(0, stop - count) * last + spec[index]
		local value = math.floor(smooth[index] * 0.55 + math.min(255, mean // 27) * 0.45)
		smooth[index] = value
		spec[index] = value
	end
	spec[count] = 0
	local removed = 0
	for index = 10, count - 1 do
		if spec[index] <= 35 then
			spec[index] = spec[index + 1]
			removed = removed + 1
		end
	end
	state.count = count - removed
	return math.min(255, level // 106)
end

local function setup(state, base, shift, rise)
	state.base, state.shift, state.rise = base, shift, rise
	state.raw, state.spec, state.spec_smooth, state.sum = {}, {}, {}, {}
	for index = 0, #KEEP do
		state.spec[index], state.spec_smooth[index] = 0, 0
	end
	state.count = 0
	state.history, state.at = {}, 1
	for index = 1, 10 do
		state.history[index] = 0
	end
	state.mood, state.mood_time = 0, 0
	state.lean, state.lean_time, state.lean_count = 0, 0, 0
	state.love, state.love_time = 0, 20
	state.blink, state.blink_time = false, 20
	state.mid_tilt, state.low_tilt = 1, 1
	state.heart_tilt = 1
	state.smile = {}
	state.eyes = {}
	state.head = {}
end

local function step(state, audio)
	local level = spectrum(state, audio)
	local previous = state.history[state.at]
	state.at = state.at % 10 + 1
	state.history[state.at] = level
	local rising, falling = previous < level, level < previous
	local spec, count = state.spec, state.count

	if state.mood_time == 0 then
		local mood = math.random(0, 7)
		state.mood = state.mood == mood and state.mood + 1 or mood
		state.mood_time = math.random(0, 7) + 10
	else
		state.mood_time = state.mood_time - 1
	end
	if count < 70 then
		state.mood = 0
	end
	if state.lean_time == 0 then
		state.lean = math.random(0, 7)
		state.lean_time = math.random(0, 3) + 10
		state.lean_count = 0
		if count < 110 then
			state.lean = 0
		end
	else
		state.lean_time = state.lean_time - 1
	end
	if state.love_time == 0 then
		state.love = math.random(0, 3)
		state.love_time = math.random(0, 15) + 3
	else
		state.love_time = state.love_time - 1
	end

	local hx, hy, mx, my = 134, -57, 119, -127
	if state.lean >= 1 and state.lean <= 3 then
		if state.lean_count < state.lean_time then
			state.lean_count = state.lean_count + 1
		end
		local amount = state.lean_count < state.lean_time and state.lean_count or state.lean_time
		if state.lean == 1 then
			hx = math.min(158, hx + amount * 7)
			mx = math.min(136, mx + amount * 7)
		elseif state.lean == 2 then
			hx = math.max(110, hx - amount * 7)
			mx = math.max(102, mx - amount * 7)
		else
			hy = math.max(-77, hy - amount * 6)
			my = math.max(-142, my - amount * 6)
		end
	end

	local shake = 0
	if state.lean_time ~= 0 and state.lean >= 1 and state.lean <= 3 then
		shake = state.lean_time % 2 == 1 and -10 or 10
	end
	state.mid_tilt = rising and count >= 30 and 0.891 or 1
	state.low_tilt = falling and count >= 60 and 0.866 or 1
	local relaxed = state.mid_tilt == 1
	state.right_arm = { mx + (relaxed and 51 or 46) + shake, my - 46 }
	state.left_arm = { mx - (relaxed and 89 or 84) + shake, my - 48 }

	local e1x, e1y, e2x, e2y = hx + 21, hy + 47, hx + 53, hy + 47
	local neck_x = hx + 4
	local neck_y = hy + 20
	local smile = {}
	for index, dot in ipairs(SMILE) do
		smile[index] = { hx + dot[2], hy + dot[3] }
	end
	smile[1][2] = (spec[40] // 8) + 29 + hy
	if smile[1][2] >= hy + 37 then
		smile[1][2] = -22
	end
	smile[8][2] = math.min((spec[80] // 8) + 29 + hy, hy + 37)
	smile[2][2] = math.min(spec[55] // 10 + 25 + hy, hy + 28)
	smile[7][2] = math.min(spec[65] // 10 + 25 + hy, hy + 28)
	smile[3][2] = math.max(hy - spec[50] // 11 + 22, hy + 20)
	smile[6][2] = math.max(hy - spec[60] // 11 + 22, hy + 20)
	smile[4][2] = math.max(hy - (spec[40] // 8) + 21, hy + 14)
	smile[5][2] = math.max(hy - (spec[35] // 8) + 21, hy + 14)

	state.blink = false
	if math.random(0, 7) == 0 and state.blink_time == 0 then
		state.blink_time = 14
		state.blink = true
	elseif state.blink_time ~= 0 then
		state.blink_time = state.blink_time - 1
	end

	local mood = state.mood
	if (mood == 1 and falling) or (mood == 3 and rising) then
		hx, hy = hx + 4, hy - 3
		neck_x = neck_x + 3
	end
	if (mood == 2 and falling) or (mood == 3 and not rising) then
		hx, hy = hx - 4, hy - 3
		neck_x = neck_x - 3
	end
	if mood == 4 and falling then
		e1x, e1y, e2x, e2y = e1x + 4, e1y + 4, e2x + 4, e2y - 4
		local xs, ys = { -1, -2, -3, -3, -3, -3, -2, -1 }, { 7, 6, 4, 0, 0, -4, -6, -7 }
		for index, dot in ipairs(smile) do
			dot[1], dot[2] = dot[1] + xs[index], dot[2] + ys[index]
		end
	elseif mood == 5 and falling then
		e1x, e1y, e2x, e2y = e1x - 4, e1y - 4, e2x - 4, e2y + 4
		local xs, ys = { 1, 2, 3, 3, 3, 3, 2, 1 }, { -7, -6, -4, 0, 0, 4, 6, 7 }
		for index, dot in ipairs(smile) do
			dot[1], dot[2] = dot[1] + xs[index], dot[2] + ys[index]
		end
	elseif mood > 5 and falling then
		e1y, e2y = e1y + 4, e2y + 4
		local ys = { 7, 6, 4, 4, 4, 4, 6, 7 }
		for index, dot in ipairs(smile) do
			dot[2] = dot[2] + ys[index]
		end
	end

	state.heart = nil
	if state.love == 1 then
		state.blink = true
		state.heart_tilt = state.heart_tilt == 1 and 0.891 or 1
		state.heart = { mx + 62, my + 58 }
	end

	state.hx, state.hy, state.mx, state.my = hx, hy, mx, my
	state.smile = smile
	state.eyes = { e1x, e1y, e2x, e2y }
	state.neck = { neck_x, neck_y }

end

local function draw(canvas, state, audio, scene, backdrop)
	local sx, sy = scene.width / 352, scene.height / 320
	local function put(name, x, top, scale)
		local texture = image(name)
		local w, h = texture:get_width(), texture:get_height()
		local width = w * (scale or 1)
		canvas:draw_texture_rect(texture, Rect2((x + (w - width) / 2) * sx, top * sy, width * sx, h * sy), false)
	end
	canvas:draw_texture_rect(image(backdrop), Rect2(0, 0, scene.width, scene.height), false)

	put("arms", state.right_arm[1], -1 - state.right_arm[2])
	put("arms", state.left_arm[1], -1 - state.left_arm[2])

	local scarf = image("scarf")
	local spec, base, shift, rise = state.spec, state.base, state.mx + state.shift, state.rise
	local count = state.count
	for index = 0, count - 1 do
		local value = spec[index]
		local bottom = value + base + math.floor(index * rise)
		local fade = count - index
		canvas:draw_texture_rect_region(scarf, Rect2((index + shift) * sx, (290 - bottom) * sy, sx, 30 * sy), Rect2(math.min(value, 225), 0, 1, 30), fade < 5 and Color(1.0, 1.0, 1.0, fade * 0.2) or WHITE)
	end

	put("bottom", 107, 219, state.low_tilt)
	put("middle", state.mx, 21 - state.my, state.mid_tilt)
	put("head", state.hx, 26 - state.hy)

	put("button1", state.mx + 50, 100 - state.my - 56)
	put("button2", state.mx + 50, 100 - state.my - 26)
	put("button3", 169, 248)
	put("button4", 168, 279)

	local eyes = state.eyes
	if state.blink then
		local black = Color(0.0, 0.0, 0.0, 1.0)
		for index = 1, 3, 2 do
			canvas:draw_rect(Rect2((eyes[index] + 2) * sx, (100 - eyes[index + 1] + 5) * sy, 8 * sx, 1.4 * sy), black)
		end
	else
		put("eye1", eyes[1], 100 - eyes[2])
		put("eye2", eyes[3], 100 - eyes[4])
	end
	for index, dot in ipairs(SMILE) do
		put(dot[1], state.smile[index][1], 100 - state.smile[index][2])
	end
	put("neck", state.neck[1], 100 - state.neck[2])
	if state.heart then
		put("heart", state.heart[1], 100 - state.heart[2], state.heart_tilt)
	end
end

return {
	name = "SnowTime",
	light = true,
	setup = setup,
	step = step,
	draw = draw,
	image = image,
	presets = {
		{
			name = "Softie the Snowman",
			aspect = 4 / 3,
			layers = { CLEAR },
			setup = function(state, scene)
				scene.canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				setup(state, 155, 70, 0)
			end,
			step = step,
			draw = function(canvas, state, audio, scene)
				draw(canvas, state, audio, scene, "sky")
			end,
		},
	},
}

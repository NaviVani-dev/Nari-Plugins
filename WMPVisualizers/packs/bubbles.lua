local psychedelia = require("packs.psychedelia")

local CLEAR = "shaders/common/clear.gdshader"
local SHADER = "shaders/psychedelia/bubble.gdshader"
local COUNT = 42
local PULL = 1000.1 / 216000
local BOUNCE = 0.9
local BLACK = Color(0.0, 0.0, 0.0)

local function create(state)
	state.bubbles = {}
	for index = 0, COUNT - 1 do
		local base = 0.75 - index * 0.6 / COUNT
		local x, y = 0.0, 0.0
		local bubble = {
			x = x, y = y,
			px = x + (math.random() - math.random()) * 0.2, py = y + (math.random() - math.random()) * 0.2,
			ax = 0.0, ay = 0.0,
			base = base, radius = base,
			bin = math.floor(index / COUNT * 800),
			r = 1.0, g = 1.0, b = 1.0,
		}
		if index > 0 then
			local r, g, b = math.random(), math.random(), math.random()
			local low = math.min(r, g, b) * 0.5
			r, g, b = r - low, g - low, b - low
			local high = math.max(r, g, b)
			bubble.r, bubble.g, bubble.b = r / high, g / high, b / high
		end
		state.bubbles[index + 1] = bubble
	end
end

local function sized(state, audio)
	local bubbles = state.bubbles
	if state.mode == 1 then
		local low = 0.0
		for index = 0, 4 do
			low = low + psychedelia.bin(audio, index * 12)
		end
		low = low / 5
		bubbles[1].radius = (low * 3 + 0.2) * 0.8 + bubbles[1].radius * 0.2
		for index = 2, COUNT do
			bubbles[index].radius = bubbles[index].base
		end
	elseif state.mode == 2 then
		for _, bubble in ipairs(bubbles) do
			bubble.radius = bubble.radius * 0.8 + (psychedelia.bin(audio, bubble.bin) * 2 + 0.2) * 0.2
		end
	else
		for _, bubble in ipairs(bubbles) do
			bubble.radius = 0.5
		end
		local hit = state.beat(psychedelia.energy(audio))
		if state.popping == 0 then
			if hit then
				state.popping, state.target = 24, math.random(COUNT)
			end
		else
			local time = state.popping
			local size
			if time >= 21 then
				local mix = (time - 20) * 0.25
				size = mix * 0.5 + (1 - mix) * 2
			elseif time < 13 then
				size = (1 - time / 12) * 0.5
			else
				size = 0.0
			end
			bubbles[state.target].radius = size
			state.popping = time - 1
		end
		bubbles[1].radius = bubbles[1].radius * 2
	end
end

local function forces(state)
	for _, bubble in ipairs(state.bubbles) do
		if state.mode == 1 then
			local length = math.sqrt(bubble.x * bubble.x + bubble.y * bubble.y)
			if length > 0 then
				bubble.ax, bubble.ay = -bubble.x * PULL / length, -bubble.y * PULL / length
			else
				bubble.ax, bubble.ay = 0.0, 0.0
			end
		elseif state.mode == 2 then
			bubble.ax, bubble.ay = 0.0, -PULL
		else
			bubble.ax, bubble.ay = 0.0, 0.0
		end
		local x, y = bubble.x, bubble.y
		bubble.x = x * 2 - bubble.px + bubble.ax
		bubble.y = y * 2 - bubble.py + bubble.ay
		bubble.px, bubble.py = x, y
	end
end

local function damp(bubble)
	bubble.px = bubble.x + (bubble.px - bubble.x) * BOUNCE
	bubble.py = bubble.y + (bubble.py - bubble.y) * BOUNCE
end

local function walls(bubble, width, height)
	local radius = bubble.radius
	local low, high = radius - width, width - radius
	if bubble.x < low then
		bubble.px = low * 2 - bubble.px
		bubble.x = low * 2 - bubble.x
		damp(bubble)
	elseif bubble.x > high then
		bubble.px = high * 2 - bubble.px
		bubble.x = high * 2 - bubble.x
		damp(bubble)
	end
	low, high = radius - height, height - radius
	if bubble.y > high then
		bubble.py = high * 2 - bubble.py
		bubble.y = high * 2 - bubble.y
		damp(bubble)
	elseif bubble.y < low then
		bubble.py = low * 2 - bubble.py
		bubble.y = low * 2 - bubble.y
		damp(bubble)
	end
end

local function collide(state)
	local bubbles = state.bubbles
	for _ = 1, 3 do
		for index = 1, COUNT do
			local bubble = bubbles[index]
			walls(bubble, state.width, state.height)
			for other = index + 1, COUNT do
				local second = bubbles[other]
				local dx, dy = bubble.x - second.x, bubble.y - second.y
				local reach = bubble.radius + second.radius
				local squared = dx * dx + dy * dy
				if squared < reach * reach and squared > 0 then
					local length = math.sqrt(squared)
					local push = (reach - length) / length
					dx, dy = dx * push, dy * push
					bubble.x, bubble.y = bubble.x + dx, bubble.y + dy
					second.x, second.y = second.x - dx, second.y - dy
					if state.mode == 1 and index == 1 then
						bubble.x, bubble.y, bubble.px, bubble.py = 0.0, 0.0, 0.0, 0.0
					end
				end
			end
			local vx, vy = bubble.px - bubble.x, bubble.py - bubble.y
			if vx * vx + vy * vy > 0.25 then
				bubble.px, bubble.py = bubble.x + vx * 0.5, bubble.y + vy * 0.5
			end
		end
	end
end

local function preset(name, mode)
	return {
		name = name,
		layers = { CLEAR },
		params = { background = BLACK },
		setup = function(state, scene)
			state.mode = mode == 0 and math.random(3) or mode
			state.beat, state.popping = psychedelia.beat(), 0
			create(state)
			state.base = psychedelia.texture(state.mode == 3 and "bubble_glass" or "bubble_diffuse")
			scene.canvas.material = psychedelia.material(SHADER, {
				specular = psychedelia.texture("bubble_specular"),
				diffuse = psychedelia.texture("bubble_diffuse"),
			})
		end,
		step = function(state, audio, scene)
			local ratio = scene.width / scene.height
			state.width = ratio > 1 and ratio * 6 or 6
			state.height = ratio > 1 and 6 or 6 / ratio
			sized(state, audio)
			forces(state)
			collide(state)
			state.art = psychedelia.cover(state, "bubble_eye")
		end,
		draw = function(canvas, state, _, scene)
			local scale = scene.height / (state.height * 2)
			local cx, cy = scene.width / 2, scene.height / 2
			for index, bubble in ipairs(state.bubbles) do
				local size = bubble.radius * 1.175 * scale
				local rect = Rect2(cx + bubble.x * scale - size, cy - bubble.y * scale - size, size * 2, size * 2)
				if index == 1 then
					canvas:draw_texture_rect(state.art, rect, false, Color(1.0, 1.0, 1.0, 0.0))
				else
					canvas:draw_texture_rect(state.base, rect, false, Color(bubble.r, bubble.g, bubble.b, 1.0))
				end
			end
		end,
	}
end

return {
	name = "Bubbles",
	presets = {
		preset("Random", 0),
		preset("Centered", 1),
		preset("Gravity", 2),
		preset("Pop", 3),
	},
}

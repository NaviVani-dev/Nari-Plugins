local lib = require("lib")
local bins = require("packs.wmp_bins")

local SUN = "shaders/crazy_lines/sun.gdshader"
local TAU = math.pi * 2
local STARS = 500
local LINKS = 100
local DRAWN = 3
local DT = 1 / 30
local LENGTH = 0.03
local START = { { 0.0, 0.0 }, { 0.0, math.pi / 2 }, { 0.0, math.pi }, { 0.0, -math.pi / 2 }, { math.pi / 2, -math.pi / 2 }, { math.pi / 2, math.pi / 2 } }
local TINT = { { 0.9, 0.1, 0.1 }, { 0.2, 0.99, 0.2 }, { 0.9, 0.1, 0.1 }, { 0.2, 0.99, 0.2 }, { 0.05, 0.6, 1.0 }, { 0.05, 0.6, 1.0 } }

local sprite

local function shape(mode, a, b)
	local sa, ca, sb, cb = math.sin(a), math.cos(a), math.sin(b), math.cos(b)
	local u, v
	if mode == 0 then
		u, v = sa * cb, sa * cb
	elseif mode == 1 then
		u, v = sa, sb
	elseif mode == 2 then
		u, v = sa, sa * cb
	elseif mode == 3 then
		u, v = sa * sb, ca * cb
	elseif mode == 4 then
		u, v = ca * ca, sb * sb
	else
		u, v = cb * ca, cb * sb
	end
	return u * TAU, v * TAU
end

local function advance(state, chain, turn_a, turn_b)
	local x, y, z = 0.0, 0.0, 0.0
	local previous
	for index = 1, LINKS do
		local link = chain[index]
		if previous then
			link.a = link.a + DT * state.chase * (previous.a - link.a)
			link.b = link.b + DT * state.chase * (previous.b - link.b)
		else
			link.a = link.a + DT * turn_a
			link.b = link.b + DT * turn_b
		end
		local u, v
		if state.mode == 6 then
			link.a = link.a + DT * turn_a * 0.1
			link.b = link.b + DT * turn_b * 0.1
			u, v = link.a, link.b
		else
			u, v = shape(state.mode, link.a, link.b)
		end
		local reach = math.sin(v) * LENGTH
		x = x + reach * math.cos(u)
		y = y + reach * math.sin(u)
		z = z + math.cos(v) * LENGTH
		link.x, link.y, link.z = x, y, z
		previous = link
	end
end

return {
	name = "Crazy Lines",
	presets = {
		{
			name = "Preset",
			layers = { SUN },
			blend = "add",
			setup = function(state, scene)
				sprite = sprite or nari.load("assets/crazy_lines/sprite.png")
				scene.engine.set(scene, "sprite", sprite)
				state.stars = {}
				for index = 1, STARS do
					state.stars[index] = {
						theta = math.random() * TAU,
						phi = math.random() * TAU,
						radius = 1.5 + math.random() * 1.5,
						color = Color(math.random() * 1.0, math.random() * 1.0, math.random() * 1.0, 1.0),
					}
				end
				state.chains = {}
				for index, start in ipairs(START) do
					local chain = {}
					for link = 1, LINKS do
						chain[link] = { a = start[1], b = start[2], x = 0.0, y = 0.0, z = 0.0 }
					end
					state.chains[index] = chain
				end
				state.mode = math.random(0, 6)
				state.clock = 0.0
				state.peak = 0.0
				state.tip = 0.0
				state.level = 0.0
				state.chase = 22.0
				state.turn = { 0.0, 0.0 }
				state.sign = { 1, -1 }
				state.spin = { 0.0, 0.0 }
				state.drift = { 0.0, 0.0 }
				state.next = 4 + math.random() * 10
				state.fade = 1.0
			end,
			step = function(state, audio, scene)
				state.clock = state.clock + DT
				local function byte(bin)
					return bins.frequency(audio, bin) / 255
				end
				state.peak = math.max(byte(0), state.peak * 0.7)
				state.tip = math.max(byte(16), state.tip * 0.7)
				local low, first, second, fourth, total = 0.0, 0.0, 0.0, 0.0, 0.0
				for tap = 0, 15 do
					low = low + byte(tap * 8) / 16
					first = first + byte(tap * 4) / 16
					second = second + byte(64 + tap * 4) / 16
					fourth = fourth + byte(256 + tap * 4) / 16
					total = total + math.sqrt(byte(tap * 64 + 8)) / 16
				end
				state.level = math.max(total * 3, state.level * 0.7)
				if state.fading then
					local amount = (state.clock - state.started) * 2
					if state.out then
						state.fade = math.max(0.0, 1.0 - amount)
						if amount > 1 then
							state.out = false
							state.started = state.clock
							state.mode = math.random(0, 6)
							state.next = state.clock + 8 + math.random() * 10
						end
					else
						state.fade = math.min(1.0, amount)
						if amount > 1 then
							state.fading = false
						end
					end
				elseif state.clock > state.next and low < 0.7 then
					state.fading, state.out, state.started = true, true, state.clock
				end
				if low > 0.1 and low <= 0.5 then
					state.chase = fourth * 12 + 22
				end
				if state.level < 0.05 then
					state.sign = { math.random() < 0.5 and -1 or 1, math.random() < 0.5 and -1 or 1 }
				end
				if total <= 0.3 then
					state.turn[1], state.turn[2] = state.turn[1] * 0.2, state.turn[2] * 0.2
				elseif byte(4) > 0.5 or byte(32) > 0.5 or byte(64) > 0.5 then
					state.turn[1] = state.sign[1] * first * state.level
					state.turn[2] = state.sign[2] * second * state.level
				end
				for _, chain in ipairs(state.chains) do
					advance(state, chain, state.turn[1], state.turn[2])
				end
				local a = (byte(128) - 0.5) * 2
				local b = (byte(64) - 0.5) * 2
				state.drift[1] = state.drift[1] + DT * (a - state.drift[1]) * 40 * DT
				state.drift[2] = state.drift[2] + DT * (b - state.drift[2]) * 40 * DT
				state.spin[1] = state.spin[1] + state.drift[1] * DT
				state.spin[2] = state.spin[2] + state.drift[2] * DT
				local red = (math.sin(state.clock) + 1.0) * 0.5
				scene.engine.set(scene, "tint", Color(red, 1.0 - red, (math.cos(state.clock) + 1.0) * 0.5, 1.0))
				scene.engine.set(scene, "sun", 6.0 + state.peak * 3.0)
				scene.engine.set(scene, "fade", state.fade)
			end,
			draw = function(canvas, state, _, scene)
				local width, height = scene.width, scene.height
				local half = height * 0.5
				local function blot(link, size, red, green, blue)
					local depth = 4 - link.z
					local reach = size / depth * half
					local x, y = width * 0.5 + link.x / depth * half, half - link.y / depth * half
					canvas:draw_texture_rect(sprite, Rect2(x - reach, y - reach, reach * 2, reach * 2), false, Color(red, green, blue, 1.0))
				end
				local fade = state.fade
				local mark = 50 + math.floor(49 * math.sin(state.clock * 2))
				for index, chain in ipairs(state.chains) do
					local tint = TINT[index]
					local red, green, blue = tint[1] * fade, tint[2] * fade, tint[3] * fade
					for link = 1, LINKS, DRAWN do
						blot(chain[link], 0.13, red, green, blue)
					end
					blot(chain[mark], 0.5, fade, fade, fade)
					blot(chain[LINKS], 0.5 + state.tip * 0.5, red, green, blue)
				end
				local size = math.max(1.0, (state.peak * 0.015 + 0.02) * half / 4 * 1.2)
				local points, colors = {}, {}
				for index = 1, STARS do
					local star = state.stars[index]
					local theta, phi = star.theta + state.spin[1], star.phi + state.spin[2]
					local reach = star.radius * math.sin(phi)
					local depth = 4 - star.radius * math.cos(phi)
					local x = width * 0.5 + reach * math.cos(theta) / depth * half
					local y = half + reach * math.sin(theta) / depth * half
					points[#points + 1] = Vector2(x, y)
					points[#points + 1] = Vector2(x + size, y)
					colors[#colors + 1] = lib.alpha(star.color, fade)
				end
				canvas:draw_multiline_colors(points, colors, size)
			end,
		},
	},
}

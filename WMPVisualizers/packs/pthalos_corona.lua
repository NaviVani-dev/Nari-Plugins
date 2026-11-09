local spectrum = require("packs.measuring_spectrum")

local FIELD = "shaders/pthalos_corona/field.gdshader"
local DISPLAY = "shaders/pthalos_corona/display.gdshader"
local COUNT = 1400
local palettes

local function new_map(state)
	return Vector2(0.2 + math.random() * 0.6, 0.2 + math.random() * 0.6), -0.01 + math.random() * 0.02, 1.0 + math.random() * 0.04
end

local function publish_map(state, scene)
	local engine = scene.engine
	engine.set(scene, "map_old", Color(state.old[1], state.old[2], state.old[3], state.old[4]))
	engine.set(scene, "map_new", Color(state.new[1], state.new[2], state.new[3], state.new[4]))
end

local function change_map(state, scene)
	if state.age > 69 then
		state.old = state.new
	end
	local center, twist, zoom = new_map(state)
	state.new = { center.x, center.y, twist, zoom }
	state.age = 0
	publish_map(state, scene)
end

local function beat(state, audio)
	local sum = spectrum.range(audio, 500, 699)
	state.average = sum * 0.1 + state.average * 0.9
	if state.average < 3000.0 then
		state.average = 3000.0
	end
	if sum <= state.average * 1.2 or state.clock - state.last < 0.075 then
		return 0
	end
	state.average = sum
	state.last = state.clock
	return math.min(sum, 7500)
end

local function kick(state, audio)
	local sum = spectrum.range(audio, 0, 1023)
	state.energy = ((1.0 - math.exp(-sum * 2.5e-5)) + state.energy) * 0.5
	local xs, ys = state.x, state.y
	local px, py = 0.0, 0.0
	for _ = 1, 10 do
		local pick = math.random(COUNT)
		px, py = px + xs[pick], py + ys[pick]
	end
	px, py = px * 0.1, py * 0.1
	if py < 0.2 and math.random(0, 3) ~= 0 then
		local width = state.energy * 5.0
		local vy = state.vy
		for index = 1, COUNT do
			if ys[index] < 0.1 then
				local u = (xs[index] - px) / width
				vy[index] = vy[index] + math.exp(-1000.0 * u * u) * width * 0.01
			end
		end
		return
	end
	local twist = state.energy * 0.009
	local shrink = state.energy * 0.0036
	if math.random(0, 1) == 0 then
		twist = -twist
	end
	state.cx = px + math.random() * 0.2 - 0.1
	state.cy = py + math.random() * 0.2 - 0.1
	state.twist = twist * 0.8 + (twist - twist * 0.8) * math.random()
	local low = 1.0 - shrink
	state.pull = low + (1.0 - shrink * 0.2 - low) * math.random()
	state.swirl = true
end

local function physics(state)
	local xs, ys, vxs, vys = state.x, state.y, state.vx, state.vy
	local swirl, cx, cy, twist, pull = state.swirl, state.cx, state.cy, state.twist, state.pull
	local random, sqrt, atan, cos, sin = math.random, math.sqrt, math.atan, math.cos, math.sin
	local respawn = COUNT // 5
	for index = 1, COUNT do
		local x, y, vx, vy = xs[index], ys[index], vxs[index], vys[index]
		vy = vy - 0.0006
		if swirl then
			local dx, dy = x - cx, y - cy
			local square = dx * dx + dy * dy
			local angle = twist / (square + 0.01) + atan(dy, dx)
			local reach = sqrt(square) * pull
			vx = vx + cos(angle) * reach - dx
			vy = vy + sin(angle) * reach - dy
		end
		vx = vx + random() * 0.0004 - 0.0002
		vy = vy + random() * 0.0004 - 0.0002
		if vx < -0.1 then vx = -0.1 elseif vx > 0.1 then vx = 0.1 end
		if vy < -0.1 then vy = -0.1 elseif vy > 0.1 then vy = 0.1 end
		if random(respawn) == 1 then
			x, y, vx, vy = random(), random(), 0.0, 0.0
		end
		x, y = x + vx, y + vy
		if x < 0.0 then
			x = -x
			vx, vy = vx * -0.25, vy * 0.25
		end
		if y < 0.0 then
			y = -y
			vx, vy = vx * 0.25, vy * -0.25
		end
		if x > 1.0 then
			x = 2.0 - x
			vx, vy = vx * -0.25, vy * 0.25
		end
		if y > 1.0 then
			y = 2.0 - y
			vx, vy = vx * 0.25, 0.0
		end
		xs[index], ys[index], vxs[index], vys[index] = x, y, vx, vy
	end
	state.swirl = false
end

local function lines(canvas, state, scene, clip)
	local width, height = scene.width, scene.height
	local xs, ys, vxs, vys = state.x, state.y, state.vx, state.vy
	local points = state.points
	local slot = 0
	state.turn = 3 - (state.turn or 1)
	for index = state.turn, COUNT, 2 do
		local x, y = xs[index] * width, (1.0 - ys[index]) * height
		local dx, dy = vxs[index] * width, -vys[index] * height
		if clip then
			local reach = 10.0 / (math.sqrt(dx * dx + dy * dy) + 0.01)
			if reach < 1.0 then
				dx, dy = dx * reach, dy * reach
			end
		end
		points[slot + 1] = Vector2(x, y)
		points[slot + 2] = Vector2(x - dx + 0.01, y - dy + 0.01)
		slot = slot + 2
	end
	for index = #points, slot + 1, -1 do
		points[index] = nil
	end
	canvas:draw_multiline(points, Color(1.0, 1.0, 1.0, 1.0), -1.0)
end

local function ease(t)
	if t >= 0.5 then
		local value = (t - 1.0) * t
		return value + value + 1.0
	end
	local value = (1.0 - t) * t
	return value + value
end

local function corona(name, blaze)
	return {
		name = name,
		size = { 640, 384 },
		feedback = FIELD,
		display = DISPLAY,
		setup = function(state, scene)
			palettes = palettes or nari.load("assets/pthalos_corona/palettes.png")
			local engine = scene.engine
			engine.set(scene, "palettes", palettes)
			scene.viewport:move_child(scene.canvas, 0)
			state.x, state.y, state.vx, state.vy, state.points = {}, {}, {}, {}, {}
			for index = 1, COUNT do
				state.x[index], state.y[index], state.vx[index], state.vy[index] = math.random(), math.random(), 0.0, 0.0
			end
			local center, twist, zoom = new_map(state)
			state.new = { center.x, center.y, twist, zoom }
			state.old = state.new
			state.age = 1000
			publish_map(state, scene)
			state.average, state.energy, state.clock, state.last = 0.0, 0.0, 0.0, -1.0
			state.pal_old = blaze and 25 or 6
			state.pal_new = state.pal_old
			state.fading = false
			state.fade = 0.0
			engine.set(scene, "palette_old", state.pal_old)
			engine.set(scene, "palette_new", state.pal_new)
			engine.set(scene, "fade", 0.0)
			if blaze then
				local post = Control.new()
				post.mouse_filter = Control.MOUSE_FILTER_IGNORE
				post.size = Vector2(640, 384)
				scene.viewport:add_child(post)
				post.draw:connect(function()
					if state.points[1] then
						lines(post, state, scene, true)
					end
				end)
				state.post = post
			end
		end,
		step = function(state, audio, scene)
			local engine = scene.engine
			state.clock = state.clock + 1 / 30
			local strength = beat(state, audio)
			if strength > 3000 then
				kick(state, audio)
			end
			physics(state)
			if math.random(0, 199) == 0 then
				change_map(state, scene)
			end
			state.age = state.age + 1
			engine.set(scene, "progress", 1.0 - 0.99 ^ state.age)
			local quiet = state.clock - state.last < 1.0
			if math.random(0, quiet and 399 or 99) == 0 and not state.fading then
				state.pal_new = math.random(0, 30)
				state.fading = true
				state.fade = 0.0
				engine.set(scene, "palette_new", state.pal_new)
			end
			if state.fading then
				state.fade = state.fade + (quiet and 0.005 or 0.01)
				if state.fade >= 1.0 then
					state.fading = false
					state.fade = 0.0
					state.pal_old = state.pal_new
					engine.set(scene, "palette_old", state.pal_old)
				end
				engine.set(scene, "fade", ease(state.fade))
			end
			if state.post then
				state.post:queue_redraw()
			end
		end,
		draw = function(canvas, state, _, scene)
			lines(canvas, state, scene, false)
		end,
	}
end

return {
	name = "Pthalo's Corona",
	presets = {
		corona("Corona", false),
		corona("Blaze", true),
	},
}

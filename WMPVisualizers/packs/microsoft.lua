local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"
local PARTICLE = "shaders/thanks/particle.gdshader"
local CELLS = 20
local ROCKETS = 400
local SPARKS = 400
local STEP = 1 / 30
local DEAD = Color(0.0, 0.0, 0.0, 0.0)

local glow, shader

local function unit()
	return math.random(0, 32767) * 3.0518509e-05
end

local function write(state, particle)
	local image, row = state.image, particle.row
	image:set_pixel(0, row, Color(particle.ox, particle.oy, particle.oz, particle.born))
	image:set_pixel(1, row, Color(particle.vx, particle.vy, particle.vz, particle.life))
	image:set_pixel(2, row, Color(particle.sr, particle.sg, particle.sb, particle.rate))
	image:set_pixel(3, row, Color(particle.er, particle.eg, particle.eb, 1.0))
	state.dirty = true
end

local function emit(state, rocket, mixed)
	local r = unit() * 0.47123894
	rocket.column, rocket.lane = state.next_column, state.next_lane
	rocket.ox = rocket.column * 0.4 - 2.0 + r
	rocket.oy = 0.03
	rocket.oz = rocket.lane * 0.4 - 2.0 + state.last_r
	state.last_r = r
	state.next_column = state.next_column + 1
	if state.next_column > 19 then
		state.next_column = 0
		state.next_lane = state.next_lane + 1
	end
	if state.next_lane > 19 then
		state.next_lane = 0
	end
	unit()
	unit()
	rocket.vx, rocket.vy, rocket.vz = 0.0, 0.0, 0.0
	if mixed then
		local t = rocket.column * 0.05
		rocket.sr, rocket.sg, rocket.sb = t, 0.0, 1.0 - t
		rocket.er, rocket.eg, rocket.eb = 1.0, 1.0, 1.0
	else
		rocket.sr, rocket.sg, rocket.sb = 1.0, 1.0, 1.0
		rocket.er, rocket.eg, rocket.eb = 1.0, 0.25098039, 0.25098039
	end
	rocket.life = 4.0 / math.random(1, 32767) + 6.0
	rocket.spent = rocket.life
	rocket.born = state.time
	rocket.rate = 1.0
	rocket.launch = 0.0
	write(state, rocket)
end

local function burst(state, rocket, age)
	local x = rocket.ox + age * rocket.vx
	local y = rocket.oy + age * rocket.vy
	local z = rocket.oz + age * rocket.vz
	local fade = math.max(rocket.spent, 0.0)
	local r = math.min(1.0, math.max(0.0, (rocket.sr - rocket.er) * fade + rocket.er))
	local g = math.min(1.0, math.max(0.0, (rocket.sg - rocket.eg) * fade + rocket.eg))
	local b = math.min(1.0, math.max(0.0, (rocket.sb - rocket.eb) * fade + rocket.eb))
	for _ = 1, 2 do
		local spark = state.sparks[state.spark_at]
		state.spark_at = state.spark_at % SPARKS + 1
		local turn = unit() * 12.566371
		local lean = unit() * 6.2831855
		local reach = math.sin(lean)
		spark.ox, spark.oy, spark.oz = x, y, z
		spark.vx = rocket.vx * 0.25 + math.cos(turn) * reach
		spark.vz = rocket.vz * 0.25 + math.sin(turn) * reach
		spark.vy = unit() * math.cos(lean) * 1.5
		spark.sr, spark.sg, spark.sb = r, g, b
		spark.er, spark.eg, spark.eb = 0.0, 0.0, 0.0
		spark.life, spark.spent = 1.0, 1.0
		spark.rate = 2.0
		spark.born = state.time
		spark.live = true
		write(state, spark)
	end
end

local function step_camera(state, fired, stopped)
	local key = false
	state.push = 0.0
	if stopped then
		state.direction = 0
	elseif fired > 20 then
		if math.random(0, 2) == 0 then
			if state.direction == 0 then
				state.direction = math.random(0, 1) == 0 and -1 or 1
			end
			state.push = state.direction
			key = true
		end
	elseif fired < 2 then
		state.direction = 0
	end
	local accel = key and -state.push or 0.0
	state.strafe = state.strafe * 0.9 + accel * 0.1
	state.spin = state.spin * 0.9 + accel * 0.1
	local cy, sy = math.cos(state.yaw), math.sin(state.yaw)
	local move = state.strafe * STEP * 5.0 * 1.25
	state.ex = state.ex + cy * move
	state.ez = state.ez - sy * move
	state.yaw = state.yaw + state.spin * STEP
end

local function set_camera(state)
	local material = state.material
	local cy, sy = math.cos(state.yaw), math.sin(state.yaw)
	local cp, sp = math.cos(-0.35), math.sin(-0.35)
	material:set_shader_parameter("eye", Color(state.ex, 2.5, state.ez, 0.0))
	material:set_shader_parameter("right", Color(cy, 0.0, -sy, 0.0))
	material:set_shader_parameter("above", Color(sy * sp, cp, cy * sp, 0.0))
	material:set_shader_parameter("back", Color(sy * cp, -sp, cy * cp, 0.0))
	material:set_shader_parameter("time", state.time)
end

local function preset(name, mixed)
	return {
		name = name,
		layers = { CLEAR },
		setup = function(state, scene)
			glow = glow or nari.load("assets/thanks/glow.png")
			shader = shader or nari.load(PARTICLE)
			state.time, state.yaw, state.strafe, state.spin, state.direction, state.push = 0.0, -1.0, 0.0, 0.0, 0, 0.0
			state.ex, state.ez = -3.33925, 5.65433
			state.next_column, state.next_lane, state.last_r, state.spark_at = 0, 0, 0.0, 1
			state.held = {}
			for column = 0, CELLS - 1 do
				state.held[column] = 1
			end
			state.image = Image.create(4, ROCKETS + SPARKS, false, Image.FORMAT_RGBAF)
			state.table = ImageTexture.create_from_image(state.image)
			state.rockets, state.sparks = {}, {}
			for index = 1, ROCKETS do
				local rocket = { row = index - 1 }
				state.rockets[index] = rocket
				emit(state, rocket, mixed)
			end
			for index = 1, SPARKS do
				state.sparks[index] = { row = ROCKETS + index - 1, live = false }
			end
			local plane = QuadMesh.new()
			plane.size = Vector2(1.0, 1.0)
			state.many = MultiMesh.new()
			state.many.transform_format = MultiMesh.TRANSFORM_2D
			state.many.mesh = plane
			state.many.instance_count = (ROCKETS + SPARKS) * 3
			state.material = ShaderMaterial.new()
			state.material.shader = shader
			state.material:set_shader_parameter("data", state.table)
			scene.canvas.material = state.material
			state.material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
			set_camera(state)
		end,
		resize = function(state, scene)
			if state.material then
				state.material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
			end
		end,
		step = function(state, audio)
			state.time = state.time + STEP
			local time = state.time
			local active, stopped = {}, true
			for column = 0, CELLS - 1 do
				local value = 0
				for bin = column * 20, column * 20 + 19, 5 do
					value = math.max(value, bins.frequency(audio, bin))
				end
				value = math.floor(value)
				if value > 0 then
					stopped = false
				end
				if state.held[column] < value then
					state.held[column] = value
					active[column] = value
				else
					active[column] = 0
					state.held[column] = state.held[column] - 1
				end
			end
			local fired = 0
			for _, rocket in ipairs(state.rockets) do
				local age = time - rocket.born
				local r1, r2, r3 = unit(), unit(), unit()
				if rocket.vy == 0.0 then
					if active[rocket.column] ~= 0 then
						rocket.vy = r3 * 0.78539819
						rocket.vx = r1 * 0.47123894
						rocket.vz = r2 * 0.47123894
						rocket.launch = math.random(0, 32767) * 6.1037019e-05 + time
						fired = fired + 1
						write(state, rocket)
					end
				elseif time - rocket.launch > 0.45 and active[rocket.column] > 0 then
					rocket.spent = 0.0
				end
				rocket.spent = rocket.spent - STEP
				if rocket.spent <= 0.0 then
					burst(state, rocket, age)
					emit(state, rocket, mixed)
				end
			end
			for _, spark in ipairs(state.sparks) do
				if spark.live and time - spark.born > 0.5 then
					spark.live = false
					state.image:set_pixel(3, spark.row, DEAD)
					state.dirty = true
				end
			end
			step_camera(state, fired, stopped)
			if state.dirty then
				state.table:update(state.image)
				state.dirty = false
			end
			set_camera(state)
		end,
		draw = function(canvas, state)
			canvas:draw_multimesh(state.many, glow)
		end,
	}
end

return {
	name = "Microsoft Extras",
	presets = {
		preset("Golden", false),
		preset("Hues", true),
		{
			name = "Void",
			layers = { CLEAR },
		},
	},
}

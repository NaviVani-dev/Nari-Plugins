local POINTS = "shaders/picture/points.gdshader"
local FALLBACK = "assets/psychedelia/sky.png"
local HOLD = 3
local WIDTH, HEIGHT = 640, 480

local function cosd(value)
	return math.cos(math.rad(math.floor(value)))
end

local function trunc(value)
	return value < 0 and math.ceil(value) or math.floor(value)
end

local function fading(f)
	f.fade = (cosd(f.spin) + 1) * 255
end

local function jump(f, w, h)
	local a = math.random(0, 7) + 2
	f.shift_x = math.random(2) == 1 and trunc(w / a) or -trunc(w / a)
	local b = math.random(0, 7) + 2
	f.shift_y = math.random(2) == 1 and trunc(h / b) or -trunc(h / b)
end

local function spread(f, w, h)
	local a = math.random(0, 3) + 4
	f.shift_x = math.random(2) == 1 and trunc(w / a) or -trunc(w / a)
	local b = math.random(0, 3) + 4
	f.shift_y = math.random(2) == 1 and trunc(h / b) or -trunc(h / b)
end


local MODES = {}

MODES.pop = {
	enter = function() end,
	into = function() return true end,
	leave = function() end,
	out = function() return true end,
}

MODES.transparency = {
	enter = function(f) f.spin, f.spin_speed = 100, 15 end,
	into = function(f)
		fading(f)
		if f.spin > 180 then
			f.fade = 0
			return true
		end
	end,
	leave = function(f) f.fade, f.spin_speed, f.spin = 0, 15, 180 end,
	out = function(f)
		fading(f)
		return f.spin >= 360 or f.fade > 230
	end,
}

local function zoomed(f)
	fading(f)
	local a = trunc((cosd(f.spin) + 1) * 90)
	f.turn_x, f.turn_y = a, a
end

MODES.zoom = {
	enter = function(f) f.spin, f.spin_speed = 100, 15 end,
	into = function(f)
		zoomed(f)
		if f.spin > 180 then
			f.fade, f.turn_x, f.turn_y = 0, 0, 0
			return true
		end
	end,
	leave = function(f) f.fade, f.spin_speed, f.spin = 0, 15, 180 end,
	out = function(f)
		zoomed(f)
		return f.spin >= 360 or f.fade > 230
	end,
}

local function twirled(f)
	f.twist = (cosd(f.swirl) + 1) * -1
	fading(f)
end

MODES.twirl = {
	enter = function(f)
		f.turn_y, f.spin_speed, f.swirl_speed, f.spin, f.swirl = 2, 15, 4, 100, 110
	end,
	into = function(f)
		twirled(f)
		if f.spin > 180 then
			f.spin_speed, f.fade = 0, 0
		end
		if f.swirl > 165 then
			f.turn_y, f.twist = 0, 0
			return true
		end
	end,
	leave = function(f)
		f.spin_speed, f.swirl_speed, f.spin, f.swirl = 0, 3, 195, 195
	end,
	out = function(f)
		f.turn_y = 1
		twirled(f)
		if f.swirl > 230 then
			f.spin_speed = 10
		end
		return f.fade > 230 or f.swirl >= 360
	end,
}

MODES.dissolve = {
	enter = function(f)
		f.glow_high, f.spin_speed, f.swirl_speed, f.spin, f.swirl = 253, 7, 15, 70, 10
	end,
	into = function(f)
		f.glow_low = trunc((cosd(f.spin) + 1) * 127.5)
		f.glow_high = math.min(trunc((cosd(f.swirl) + 1) * 350), 253)
		if f.swirl > 180 then
			f.swirl = 180
		end
		if f.spin >= 180 then
			f.glow_low, f.glow_high = 0, 0
			return true
		end
	end,
	leave = function(f)
		f.glow_high, f.spin_speed, f.swirl_speed, f.spin, f.swirl = 253, 7, 5, 180, 180
	end,
	out = function(f)
		f.glow_low = trunc((cosd(f.spin) + 1) * 127.5)
		f.glow_high = trunc((cosd(f.swirl) + 1) * 350)
		return f.spin > 360
	end,
}

MODES.toaster = {
	enter = function(f, w, h) f.slide = -h end,
	into = function(f, w, h)
		f.slide = f.slide * 0.5
		if -f.slide < h * 0.2 then
			f.slide = 0
			return true
		end
	end,
	leave = function() end,
	out = function(f, w, h)
		f.slide = f.slide * 1.2 - h * 0.1
		return f.slide < h * -0.96
	end,
}

local function wipe(sides, start, limit, span)
	return {
		enter = function(f, w, h)
			f.edge_reach, f.edge_amount = span(w, h), start
		end,
		into = function(f, w, h)
			f.edge_reach = trunc(f.edge_reach * 0.909091)
			f.edge_amount = f.edge_amount - 24
			if f.edge_amount < 50 then
				f.edge_amount = 0
				return true
			end
		end,
		leave = function(f, w, h)
			f.edge_sides, f.edge_reach, f.edge_amount = sides, 1, limit
		end,
		out = function(f, w, h)
			f.edge_reach = trunc(f.edge_reach * 1.1) + trunc(span(w, h) * 0.07)
			f.edge_amount = f.edge_amount + 10
			return f.edge_reach > span(w, h) * (sides == 12 and 0.5 or 1)
		end,
	}
end

local function width_of(w)
	return w
end

local function height_of(_, h)
	return h
end

MODES.swipe = wipe(4, 400, 215, width_of)
MODES.curtains = wipe(12, 800, 800, width_of)

MODES.rotate = {
	enter = function(f) f.spin_speed, f.spin, f.follow_y = -8, 90, true end,
	into = function(f)
		f.turn_y = math.max(f.spin, 0)
		if f.spin < 0 then
			f.follow_y, f.turn_y = false, 0
			return true
		end
	end,
	leave = function(f) f.spin_speed, f.spin, f.follow_y = 8, 1, true end,
	out = function(f)
		f.turn_y = f.spin
		return f.spin > 90
	end,
}

MODES.spin = {
	enter = function(f) f.spin_speed, f.spin, f.fill = -8, 90, 1 end,
	into = function(f)
		local a = math.max(f.spin, 0)
		f.turn_x, f.turn_y, f.turn_z = a, a, a
		if f.spin < 0 then
			f.turn_x, f.turn_y, f.turn_z, f.fill = 0, 0, 0, 0
			return true
		end
	end,
	leave = function(f) f.spin_speed, f.spin, f.fill = 8, 1, 1 end,
	out = function(f)
		f.turn_x, f.turn_y, f.turn_z = f.spin, f.spin, f.spin
		return f.spin > 90
	end,
}

MODES.transport = {
	enter = function(f, w, h)
		f.edge_reach, f.edge_amount, f.wave_shape, f.wave_lift, f.wave_rate_y, f.spin_speed, f.phase_y = h, 300, 6, 17, 17, 8, true
	end,
	into = function(f)
		f.edge_reach = math.max(trunc(f.edge_reach * 0.666667), f.wave_lift)
		f.edge_amount = math.max(trunc(f.edge_amount / 2), 200)
		f.wave_lift = f.wave_lift - 1
		if f.wave_lift < 1 then
			f.edge_amount, f.edge_reach, f.wave_lift, f.wave_rate_y, f.phase_y = 0, 0, 0, 0, false
			return true
		end
	end,
	leave = function(f)
		f.edge_sides, f.edge_reach, f.edge_amount, f.wave_shape, f.wave_rate_y, f.spin_speed, f.phase_y = 3, 1, 230, 6, 17, 8, true
	end,
	out = function(f, w, h)
		f.edge_reach = trunc(f.edge_reach * 0.95) + trunc(h * 0.08)
		f.edge_amount = trunc(f.edge_amount * 0.95) + trunc(h * 0.06)
		f.wave_lift = math.min(f.wave_lift + 2, 17)
		return f.edge_reach > h / 2
	end,
}

MODES.ripple = {
	enter = function(f, w, h)
		f.slide, f.edge_reach, f.edge_amount, f.wave_lift, f.phase_x, f.wave_rate_x, f.spin_speed = h * 0.7, trunc(w * 0.85), 256, 5, true, 27, 8
	end,
	into = function(f, w, h)
		f.edge_reach = trunc(f.edge_reach * 0.8)
		f.slide = f.slide - (f.slide * 0.3 + h * 0.01)
		if f.slide < h * 0.05 then
			f.slide, f.edge_amount, f.edge_reach, f.wave_lift, f.wave_rate_x, f.phase_x = 0, 0, 0, 0, 0, false
			return true
		end
	end,
	leave = function(f)
		f.edge_sides, f.edge_reach, f.edge_amount, f.phase_x, f.wave_rate_x, f.spin_speed = 0, 1, 256, true, 27, 8
	end,
	out = function(f, w, h)
		f.edge_reach = f.edge_reach + 1 + trunc(w * 0.03)
		f.wave_lift = 5
		f.slide = f.slide - h * 0.01 + f.slide * 0.7 - 1
		return trunc(w * 0.8) < f.edge_reach or f.slide < h * -0.9
	end,
}

MODES.spiral = {
	enter = function(f, w, h)
		f.edge_reach, f.edge_amount, f.turn_z, f.twist, f.fill = h, 300, 1, -1, 7
	end,
	into = function(f, w, h)
		f.edge_reach = trunc(f.edge_reach * 0.909091) + trunc(h * 0.05)
		f.edge_amount = f.edge_amount - 24
		f.twist = math.min((f.edge_amount - 50) * -0.00333333, 0)
		if f.edge_amount < 50 then
			f.edge_amount, f.edge_reach, f.twist, f.turn_z, f.fill = 0, 0, 0, 0, 0
			return true
		end
	end,
	leave = function(f, w, h)
		f.edge_sides, f.edge_reach, f.edge_amount, f.fill, f.turn_z, f.twist = w > h and 3 or 12, 1, 200, 7, 1, -1
	end,
	out = function(f, w, h)
		f.edge_reach = trunc(f.edge_reach * 1.1) + trunc(h * 0.05) + 5
		f.edge_amount = f.edge_amount + 20
		f.twist = f.twist - 0.07
		return h * 0.5 < f.edge_reach
	end,
}

MODES.undulation = {
	enter = function(f, w)
		f.edge_reach, f.edge_amount, f.wave_lift, f.wave_rate_x, f.wave_rate_y, f.fill, f.spin_speed = w, 300, 24, 4, 4, 7, 8
	end,
	into = function(f)
		f.edge_reach = trunc(f.edge_reach * 0.85)
		f.edge_amount = f.edge_amount - 24
		f.wave_lift = math.max(f.wave_lift - 2, 0)
		if f.edge_amount < 50 then
			f.edge_amount, f.edge_reach, f.wave_lift, f.wave_rate_x, f.wave_rate_y, f.fill = 0, 0, 0, 0, 0, 0
			return true
		end
	end,
	leave = function(f)
		f.edge_sides, f.edge_reach, f.edge_amount, f.wave_rate_x, f.wave_rate_y, f.fill, f.spin_speed, f.wave_lift = 12, 1, 100, 4, 4, 7, 8, 0
	end,
	out = function(f, w)
		f.edge_reach = trunc(f.edge_reach * 1.1) + trunc(w * 0.01) + 3
		f.edge_amount = f.edge_amount + 10
		f.wave_lift = math.min(f.wave_lift + 1, 20)
		return trunc(w * 1.2) < f.edge_reach
	end,
}

local function bending(rate_x, rate_y, speed, shape)
	return {
		enter = function(f, w, h)
			spread(f, w, h)
			f.edge_reach, f.edge_amount, f.wave_rate_x, f.wave_rate_y, f.spin_speed, f.wave_shape = w, 300, rate_x, rate_y, speed, shape
			f.bend = -60
		end,
		into = function(f)
			f.edge_reach = trunc(f.edge_reach * 0.85)
			f.edge_amount = f.edge_amount - 24
			f.bend = (f.edge_amount - 50) * -0.2
			if f.edge_amount < 50 then
				f.edge_amount, f.edge_reach, f.bend, f.wave_rate_x, f.wave_rate_y, f.shift_x, f.shift_y = 0, 0, 0, 0, 0, 0, 0
				return true
			end
		end,
		leave = function(f, w, h)
			spread(f, w, h)
			f.edge_sides, f.edge_reach, f.edge_amount, f.wave_rate_x, f.wave_rate_y, f.spin_speed, f.wave_shape = 1, 1, 100, rate_x, rate_y, speed, shape
		end,
		out = function(f, w)
			f.edge_reach = trunc(f.edge_reach * 1.1) + trunc(w * 0.01) + 3
			f.edge_amount = f.edge_amount + 10
			f.bend = f.bend - 3
			return trunc(w * 1.2) < f.edge_reach
		end,
	}
end

MODES.flourish = bending(4, 4, 8, 0)
MODES.disperse = bending(0.1, 0.02, 0.03, 10)

MODES.seagrass = {
	enter = function(f, w, h)
		f.edge_reach, f.edge_amount, f.shift_y, f.wave_rate_x, f.wave_rate_y, f.spin_speed, f.wave_shape, f.phase_y = h, 300, -trunc(h / 2), 4, 8, 8, 4, true
		f.bend = 5
	end,
	into = function(f, w, h)
		f.edge_reach = trunc(f.edge_reach * 0.85)
		f.edge_amount = f.edge_amount - 24
		f.bend = (f.edge_amount - 50) * 0.02
		f.shift_y = f.shift_y + 1 + trunc(h * 0.01)
		if f.edge_amount < 50 then
			f.edge_amount, f.edge_reach, f.bend, f.shift_y, f.wave_rate_x, f.wave_rate_y, f.phase_y = 0, 0, 0, 0, 0, 0, false
			return true
		end
	end,
	leave = function(f, w, h)
		f.edge_sides, f.edge_reach, f.edge_amount, f.wave_rate_x, f.wave_rate_y, f.spin_speed, f.shift_y, f.wave_shape = 1, 1, 100, 4, 8, 8, -trunc(h / 4), 4
	end,
	out = function(f, w, h)
		f.edge_reach = trunc(f.edge_reach * 1.1) + trunc(h * 0.01) + 3
		f.edge_amount = f.edge_amount + 10
		f.phase_y = true
		if trunc(f.bend) == 0 then
			f.bend = 0.8
		end
		f.bend = f.bend + 0.2
		f.shift_y = f.shift_y - 1 - trunc(f.bend)
		return trunc(h * 1.2) < f.edge_reach
	end,
}

MODES.wetglass = {
	enter = function(f, w, h)
		f.edge_reach, f.edge_amount, f.wave_rate_x, f.wave_rate_y, f.spin_speed, f.wave_shape, f.fill, f.wave_lift, f.bend = h, 400, 4, 4, 8, 19, 3, 8, 1
	end,
	into = function(f)
		f.edge_reach = trunc(f.edge_reach * 0.909091)
		f.edge_amount = f.edge_amount - 24
		f.wave_lift = trunc((f.edge_amount - 50) * 0.05)
		if f.edge_amount < 50 then
			f.edge_amount, f.edge_reach, f.bend, f.wave_lift, f.wave_rate_x, f.wave_rate_y, f.fill = 0, 0, 0, 0, 0, 0, 0
			return true
		end
	end,
	leave = function(f)
		f.edge_sides, f.edge_reach, f.edge_amount, f.wave_rate_x, f.wave_rate_y, f.spin_speed, f.wave_shape, f.fill, f.wave_lift = 1, 1, 215, 4, 4, 8, 19, 3, 0
	end,
	out = function(f, w, h)
		f.edge_reach = trunc(f.edge_reach * 1.1) + trunc(h * 0.07)
		f.edge_amount = f.edge_amount + 10
		f.bend = 1
		f.wave_lift = f.wave_lift + 1
		return f.edge_reach > h
	end,
}

MODES.dematerialize = {
	enter = function(f)
		f.glow_low, f.glow_high, f.wave_rate_x, f.wave_rate_y, f.spin_speed, f.wave_shape, f.bend, f.wave_lift = 255, 700, 4, 4, 8, 19, 1, 25
	end,
	into = function(f)
		f.glow_low = trunc(f.glow_low * 0.8)
		f.wave_lift = trunc(f.glow_low * 0.1)
		if f.glow_low < 2 then
			f.glow_low, f.glow_high, f.wave_lift, f.bend, f.wave_rate_x, f.wave_rate_y = 0, 0, 0, 0, 0, 0
			return true
		end
	end,
	leave = function(f)
		f.glow_low, f.glow_high, f.wave_rate_x, f.wave_rate_y, f.spin_speed, f.wave_shape, f.wave_lift = 1, 700, 4, 4, 8, 19, 0
	end,
	out = function(f)
		f.bend = 1
		f.wave_lift = f.wave_lift + 1
		f.glow_low = trunc(f.glow_low * 1.3) + 1
		return f.glow_low > 256
	end,
}

MODES.suck = {
	enter = function(f, w, h)
		jump(f, w, h)
		f.pull_on, f.pull_fall, f.fill, f.spin_speed, f.spin, f.edge_reach, f.edge_amount = 1, 1, 3, 15, 90, trunc(w / 3), 215
	end,
	into = function(f)
		f.pull = (cosd(f.spin) + 1) * 5
		if f.spin > 150 then
			f.pull_on, f.pull, f.edge_amount, f.edge_reach, f.fill, f.shift_x, f.shift_y = 0, 0, 0, 0, 0, 0, 0
			return true
		end
	end,
	leave = function(f, w, h)
		jump(f, w, h)
		f.pull_on, f.pull_fall, f.fill, f.spin_speed, f.spin, f.edge_reach, f.edge_amount = 1, 1, 3, 10, 180, 0, 215
	end,
	out = function(f, w)
		f.pull = (cosd(f.spin) + 1) * 5
		f.edge_reach = trunc(w / 3 * (1 - (cosd(f.spin) + 1) / 2))
		if f.pull > 3 then
			f.pull_fall = f.pull_fall * 0.5
		end
		return f.spin >= 360
	end,
}

MODES.spotlight = {
	enter = function(f)
		f.lit, f.spot, f.spot_soft, f.light_phase = true, 20, -8, 0
	end,
	into = function(f, w, h)
		f.spot = f.spot * 1.3 + 7
		if h * 8 < f.spot then
			f.lit, f.spot = false, 0
			return true
		end
	end,
	leave = function(f, w, h)
		f.spot, f.spot_soft = math.floor(math.max(w, h) / 2), -8
	end,
	out = function(f)
		f.lit = true
		f.spot = f.spot * 0.9 - 7
		return f.spot < 10
	end,
}

local function sweep(name, value)
	return {
		enter = function(f, w, h)
			f.lit, f.spot, f.light_base, f.light_speed = true, math.floor(math.max(w, h) / 2), -4, 20
			f[name] = value
		end,
		into = function(f)
			f.light_base = f.light_base + 0.2
			if f.light_base > 2 then
				f.lit = false
				return true
			end
		end,
		leave = function(f, w, h)
			f.spot, f.light_speed, f.light_base = math.floor(math.max(w, h) / 2), -20, 2
			f[name] = value
		end,
		out = function(f)
			f.lit = true
			f.light_base = f.light_base - 0.2
			return f.light_base <= -1
		end,
	}
end

MODES.squares = sweep("square", 0.06)
MODES.bullseye = sweep("ring", 0.06)
MODES.variegate = sweep("square", 2)
MODES.pattern = sweep("scatter", -30.08)

MODES.radial = {
	enter = function(f, w, h)
		f.lit, f.spot, f.wedge, f.light_base, f.light_speed = true, math.floor(math.max(w, h) / 2), 0.01, 2, 20
	end,
	into = function(f)
		f.wedge = f.wedge * 1.15
		if f.wedge >= 0.5 then
			f.lit, f.wedge = false, 0
			return true
		end
	end,
	leave = function(f, w, h)
		f.spot, f.wedge, f.light_base, f.light_speed = math.floor(math.max(w, h) / 2), 0.5, 2, -20
	end,
	out = function(f)
		f.lit = true
		f.wedge = f.wedge * 0.85
		return f.wedge < 0.01
	end,
}

MODES.squirt = MODES.suck

local function empty()
	return {
		spin = 0, spin_speed = 0, swirl = 0, swirl_speed = 0, fade = 0, turn_x = 0, turn_y = 0, turn_z = 0, twist = 0,
		edge_amount = 0, edge_reach = 0, edge_sides = 0, wave_rate_x = 0, wave_rate_y = 0, wave_lift = 0, wave_shape = 0, bend = 0,
		shift_x = 0, shift_y = 0, slide = 0, glow_low = 0, glow_high = 0, fill = 0, pull_on = 0, pull = 0, pull_fall = 1,
		lit = false, spot = 0, spot_soft = 0, wedge = 0, light_base = 0, light_phase = 0, light_speed = 0, ring = 0, square = 0, scatter = 0,
	}
end

local function push(state)
	local f, m = state.fields, state.material
	if f.follow_y then
		f.turn_y = f.spin
	end
	m:set_shader_parameter("fade", f.fade * 1.0)
	m:set_shader_parameter("center_shift", Vector2(f.shift_x, f.shift_y))
	m:set_shader_parameter("wave_rate", Vector2(f.wave_rate_x, f.wave_rate_y))
	m:set_shader_parameter("wave_phase", Vector2(f.phase_x and f.spin or 0, f.phase_y and f.spin or 0))
	m:set_shader_parameter("wave_lift", f.wave_lift * 1.0)
	m:set_shader_parameter("bend", f.bend * 1.0)
	m:set_shader_parameter("wave_shape", f.wave_shape)
	m:set_shader_parameter("turn", Color(f.turn_x, f.turn_y, f.turn_z))
	m:set_shader_parameter("twist", f.twist * 1.0)
	m:set_shader_parameter("pull", Color(f.pull_on, f.pull, f.pull_fall))
	m:set_shader_parameter("slide", f.slide * 1.0)
	m:set_shader_parameter("edge_amount", f.edge_amount * 1.0)
	m:set_shader_parameter("edge_reach", f.edge_reach * 1.0)
	m:set_shader_parameter("edge_sides", f.edge_sides)
	m:set_shader_parameter("glow_low", f.glow_low * 1.0)
	m:set_shader_parameter("glow_high", f.glow_high * 1.0)
	m:set_shader_parameter("lit", f.lit)
	m:set_shader_parameter("spot", f.spot * 1.0)
	m:set_shader_parameter("spot_soft", f.spot_soft * 1.0)
	m:set_shader_parameter("wedge", f.wedge * 1.0)
	m:set_shader_parameter("light_base", f.light_base * 1.0)
	m:set_shader_parameter("light_phase", f.light_phase * 1.0)
	m:set_shader_parameter("ring", f.ring * 1.0)
	m:set_shader_parameter("square", f.square * 1.0)
	m:set_shader_parameter("scatter", f.scatter * 1.0)
	local stride = f.fill > 0 and 2 or 1
	m:set_shader_parameter("stride", stride)
	state.active = stride == 2 and state.coarse or state.many
end

local function fit(state)
	local size = state.texture and state.texture:get_size()
	if not size or size.y <= 0 then
		return
	end
	local width, height = WIDTH * 0.9, WIDTH * 0.9 * size.y / size.x
	if height > HEIGHT * 0.9 then
		height, width = HEIGHT * 0.9, HEIGHT * 0.9 * size.x / size.y
	end
	state.w, state.h = math.floor(width), math.floor(height)
	state.x, state.y = math.floor((WIDTH - state.w) / 2), math.floor((HEIGHT - state.h) / 2)
	local m = state.material
	m:set_shader_parameter("cover", state.texture)
	m:set_shader_parameter("columns", state.w)
	m:set_shader_parameter("rows", state.h)
	m:set_shader_parameter("origin", Vector2(state.x, state.y))
	state.many.instance_count = state.w * state.h
	state.coarse.instance_count = math.floor(state.w / 2) * math.floor(state.h / 2)
end

local function apply(state, texture)
	state.texture = texture
	fit(state)
end

local function load_cover(state)
	local song = nari.current()
	local id = song and song.id or ""
	if id == state.song then
		return
	end
	state.song = id
	apply(state, nari.load(FALLBACK))
	if not song then
		return
	end
	local cover = MediaPlayer:cover_of(song)
	nari.await(MediaPlayer:get_cover_texture(cover[1], cover[2]), function(texture)
		if texture and state.song == id then
			apply(state, texture)
		end
	end)
end

local function choose(state, pick)
	local name = pick(state)
	state.name = name
	state.mode = MODES[name]
end

local function random_from(list)
	return function(state)
		local index = math.random(#list)
		if list[index] == state.name then
			index = index % #list + 1
		end
		return list[index]
	end
end

local function preset(name, pick, backdrop)
	if type(pick) == "table" then
		pick = random_from(pick)
	end
	local logo
	return {
		name = name,
		aspect = 4 / 3,
		size = { WIDTH, HEIGHT },
		setup = function(state, scene)
			state.song, state.backdrop = nil, backdrop
			if not backdrop then
				logo = logo or nari.load("assets/picture_viz/msn.png")
			end
			state.material = ShaderMaterial.new()
			state.material.shader = nari.load(POINTS)
			state.many = MultiMesh.new()
			state.many.transform_format = MultiMesh.TRANSFORM_2D
			state.many.mesh = PointMesh.new()
			state.coarse = MultiMesh.new()
			state.coarse.transform_format = MultiMesh.TRANSFORM_2D
			local block = QuadMesh.new()
			block.size = Vector2(2.0, 2.0)
			state.coarse.mesh = block
			state.active = state.many
			local node = Control.new()
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.size = Vector2(WIDTH, HEIGHT)
			node.material = state.material
			node.visible = false
			scene.viewport:add_child(node)
			node.draw:connect(function()
				node:draw_multimesh(state.active, nil)
			end)
			state.node = node
			RenderingServer:canvas_item_set_custom_rect(node:get_canvas_item(), true, Rect2(0, 0, WIDTH, HEIGHT))
			load_cover(state)
			state.fields = empty()
			state.phase, state.clock = "in", 0
			choose(state, pick)
			state.mode.enter(state.fields, state.w, state.h)
		end,
		step = function(state)
			load_cover(state)
			state.clock = state.clock + 1 / 30
			local f, w, h = state.fields, state.w, state.h
			if state.phase == "in" then
				if state.mode.into(f, w, h) then
					state.phase = "hold"
				end
			elseif state.phase == "out" then
				if state.mode.out(f, w, h) then
					state.fields = empty()
					choose(state, pick)
					state.clock = 0
					state.phase = "in"
					f = state.fields
					state.mode.enter(f, w, h)
				end
			end
			if state.clock >= HOLD and state.phase ~= "out" then
				f.follow_y = false
				state.fields = empty()
				f = state.fields
				state.mode.leave(f, w, h)
				state.phase = "out"
			end
			f.spin = f.spin + f.spin_speed
			f.swirl = f.swirl + f.swirl_speed
			f.light_phase = f.light_phase + f.light_speed
			state.moving = state.phase ~= "hold"
			state.node.visible = state.moving
			if state.moving then
				push(state)
				state.node:queue_redraw()
			end
		end,
		draw = function(canvas, state)
			canvas:draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0.0, 0.0, 0.0, 1.0))
			if not state.texture then
				return
			end
			if backdrop then
				canvas:draw_texture_rect(state.texture, Rect2(0, 0, WIDTH, HEIGHT), false)
			end
			if not state.moving then
				if backdrop then
					canvas:draw_rect(Rect2(state.x + state.w, state.y + 7, 8, state.h), Color(0.0, 0.0, 0.0, 0.45))
					canvas:draw_rect(Rect2(state.x + 8, state.y + state.h, state.w, 7), Color(0.0, 0.0, 0.0, 0.45))
					canvas:draw_rect(Rect2(state.x - 1, state.y - 1, state.w + 2, state.h + 2), Color(0.35, 0.35, 1.0, 1.0))
				end
				canvas:draw_texture_rect(state.texture, Rect2(state.x, state.y, state.w, state.h), false)
			end
			if logo and not backdrop then
				canvas:draw_texture_rect(logo, Rect2(WIDTH - 128, HEIGHT - 28, 128, 28), false)
			end
		end,
	}
end

return {
	name = "Picture Viz",
	make = preset,
	presets = {
		preset("Pop Transition", { "pop" }),
		preset("Transparency Transition", { "transparency" }),
		preset("Zoom Transition", { "zoom" }),
		preset("Squirt Transition", { "squirt" }),
		preset("Twirl Transition", { "twirl" }),
		preset("Dissolve Transition", { "dissolve" }),
		preset("Random", { "pop", "transparency", "zoom", "squirt", "twirl", "dissolve" }),
	},
}

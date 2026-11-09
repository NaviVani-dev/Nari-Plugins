local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"
local SIZE = 50
local TURN = math.pi / 150
local EYE = { 51.53, 57.0, 64.0 }

local function stops(list)
	local result = {}
	for _, stop in ipairs(list) do
		local first, last, from, to = stop[1], stop[2], stop[3], stop[4]
		for index = first, last do
			local t = (index - first) / (last - first + 1)
			result[index] = Color((from[1] + (to[1] - from[1]) * t) / 255, (from[2] + (to[2] - from[2]) * t) / 255, (from[3] + (to[3] - from[3]) * t) / 255, 1.0)
		end
	end
	return result
end

local DEFAULT = stops({
	{ 0, 7, { 255, 0, 0 }, { 255, 0, 255 } },
	{ 8, 17, { 255, 0, 255 }, { 112, 112, 255 } },
	{ 18, 29, { 112, 112, 255 }, { 0, 112, 255 } },
	{ 30, 37, { 0, 112, 255 }, { 0, 255, 255 } },
	{ 38, 40, { 0, 255, 255 }, { 0, 255, 255 } },
})

local ROTATING = stops({
	{ 0, 7, { 128, 0, 240 }, { 152, 0, 176 } },
	{ 8, 24, { 160, 0, 160 }, { 24, 136, 160 } },
	{ 25, 40, { 0, 160, 160 }, { 240, 240, 240 } },
})

local function normal(x, y, z)
	local length = math.sqrt(x * x + y * y + z * z)
	return x / length, y / length, z / length
end

local fx, fy, fz = normal(-EYE[1], -EYE[2], -EYE[3])
local rx, ry, rz = normal(-fz, 0, fx)
local ux, uy, uz = ry * fz - rz * fy, rz * fx - rx * fz, rx * fy - ry * fx

local function reset(state)
	state.spin = { false, false, false }
	state.angle = { 0, 0, 0 }
	state.distance = 100
	state.gravity = 0.01
	state.launch = 0
end

local function wander(state)
	local pick = math.random(0, 29)
	if pick == 1 then
		if math.random(0, 9) == 0 then
			reset(state)
		end
	elseif pick == 2 or pick == 3 or pick == 4 then
		state.spin[pick - 1] = not state.spin[pick - 1]
	elseif pick == 5 then
		state.launch = state.launch + 0.5
	elseif pick == 6 then
		state.launch = math.max(0, state.launch - 0.5)
	elseif pick == 7 then
		state.gravity = math.min(0.32, state.gravity * 2)
	elseif pick == 8 then
		state.gravity = math.max(0.0025, state.gravity * 0.5)
	elseif math.random() < 0.5 then
		state.distance = math.min(160, state.distance + 1)
	else
		state.distance = math.max(70, state.distance - 1)
	end
end

local function preset(name, palette, roaming)
	return {
		name = name,
		aspect = 4 / 3,
		layers = { CLEAR },
		setup = function(state)
			reset(state)
			state.cursor = 0
			state.rows = {}
			state.columns = {}
			local bin = 1
			for column = 1, SIZE do
				state.columns[column] = bin
				bin = math.max(math.floor(bin * 1.096), bin + 1)
			end
			for row = 0, SIZE - 1 do
				state.rows[row] = { z = 100, h = {}, v = {} }
				for column = 1, SIZE do
					state.rows[row].h[column] = 0
					state.rows[row].v[column] = 0
				end
			end
		end,
		step = function(state, audio)
			local fresh = state.rows[state.cursor]
			for column = 1, SIZE do
				local byte = bins.frequency(audio, state.columns[column])
				local level = math.floor(byte / 4)
				fresh.h[column] = level * level * 0.015
				fresh.v[column] = state.launch
			end
			fresh.z = -26
			state.cursor = (state.cursor + 1) % SIZE
			local gravity = state.gravity
			for row = 0, SIZE - 1 do
				local line = state.rows[row]
				line.z = line.z + 1
				local h, v = line.h, line.v
				for column = 1, SIZE do
					local height = h[column]
					if height > 0 then
						height = height - v[column]
						h[column] = height > 0 and height or 0
						v[column] = v[column] + gravity
					end
				end
			end
			if roaming then
				wander(state)
				for axis = 1, 3 do
					if state.spin[axis] then
						state.angle[axis] = (state.angle[axis] + TURN) % (math.pi * 2)
					end
				end
			end
		end,
		draw = function(canvas, state, _, scene)
			local width, height = scene.width, scene.height
			local focal = 0.875 * height
			local cx, cy = width * 0.494, height * 0.492
			local size = math.max(1, math.floor(height / 480 + 0.5))
			local cax, sax = math.cos(state.angle[1]), math.sin(state.angle[1])
			local cay, say = math.cos(state.angle[2]), math.sin(state.angle[2])
			local caz, saz = math.cos(state.angle[3]), math.sin(state.angle[3])
			local spinning = state.spin[1] or state.spin[2] or state.spin[3] or state.angle[1] ~= 0 or state.angle[2] ~= 0 or state.angle[3] ~= 0
			local depth = state.distance
			local points, colors = {}, {}
			local count = 0
			for row = 0, SIZE - 1 do
				local line = state.rows[row]
				local h = line.h
				local z0 = line.z
				if z0 <= 24 then
					for column = 1, SIZE do
						local x, y, z = column - 26, h[column], z0
						if spinning then
							y, z = y * cax + z * sax, z * cax - y * sax
							x, z = x * cay + z * say, z * cay - x * say
							x, y = x * caz + y * saz, y * caz - x * saz
						end
						local dz = fx * x + fy * y + fz * z + depth
						if dz > 1 then
							local px = cx + focal * (rx * x + ry * y + rz * z) / dz
							local py = cy - focal * (ux * x + uy * y + uz * z) / dz
							if px >= 0 and px < width and py >= 0 and py < height then
								local index = math.floor(h[column])
								count = count + 1
								points[count * 2 - 1] = Vector2(px, py)
								points[count * 2] = Vector2(px + size, py)
								colors[count] = palette[index > 40 and 40 or index]
							end
						end
					end
				end
			end
			if count > 0 then
				canvas:draw_multiline_colors(points, colors, size)
			end
		end,
	}
end

return {
	name = "Particle",
	presets = {
		preset("Particle", DEFAULT, false),
		preset("Rotating Particle", ROTATING, true),
	},
}

local lib = require("lib")
local bins = require("packs.wmp_bins")

local COLUMNS = "shaders/blazing_colors/columns.gdshader"

local palettes = {}

local function palette(name)
	if not palettes[name] then
		palettes[name] = nari.load("assets/blazing_colors/" .. name .. ".png")
	end
	return palettes[name]
end

local columns = {}

local function resample_map(count, keep)
	local map, blend = {}, {}
	local accumulator, index, left = 0, 0, count
	if keep < 255 then
		local step = (256 - keep) * 16777216
		while true do
			map[#map + 1] = index
			local done = false
			while true do
				index = index + 1
				left = left - 1
				if left == 0 then
					done = true
					break
				end
				accumulator = accumulator + step
				if accumulator < 4294967296 then
					break
				end
				accumulator = accumulator - 4294967296
			end
			if done then
				break
			end
		end
	elseif keep == 255 then
		for at = 0, count - 1 do
			map[at + 1] = at
		end
	else
		local step = (512 - math.min(keep, 512)) * 16777216
		local written = 0
		while true do
			written = written + 1
			if written >= 512 then
				break
			end
			map[#map + 1] = index
			left = left - 1
			if left == 0 then
				break
			end
			accumulator = accumulator + step
			local carry = accumulator >= 4294967296
			if carry then
				accumulator = accumulator - 4294967296
			end
			index = index + 1
			if not carry then
				written = written + 1
				if written > 511 then
					break
				end
				map[#map + 1] = index - 1
				blend[#map] = index + 1
			end
		end
	end
	return map, blend
end

local function scatter(values, raw)
	local at = 0
	while at < 255 do
		local start = math.random(0, 127)
		local run = math.random(0, 7) + 5
		if run + start > 254 then
			start = run
		end
		if math.random(0, 3) ~= 0 then
			for _ = 0, run * 2 do
				if at < 255 then
					values[at] = 0
					at = at + 1
				end
			end
		else
			for offset = 0, run do
				if at < 255 then
					values[at] = raw[start + offset] or 0
					at = at + 1
				end
			end
		end
	end
end

function columns.pipeline(options)
	local mirrored = options.mirror
	if mirrored == nil then
		mirrored = options.place == 1 or (options.place >= 3 and options.place <= 8)
	end
	local map, blend = resample_map(mirrored and 512 or 256, options.keep)
	local count = #map
	local self = { count = math.min(count, 352), heights = {}, level = 0 }
	local raw, values, out, sums, history, levels = {}, {}, {}, {}, {}, {}
	for index = 0, 255 do
		raw[index] = 0
		values[index] = 0
	end
	for index = 1, 352 do
		self.heights[index] = 0.0
	end
	for index = 1, count do
		history[index] = 0
	end
	for index = 1, 10 do
		levels[index] = 0
	end
	local level_at = 0
	local offset, smooth = options.offset or 0, options.smooth or 0

	local function pick(at)
		if mirrored then
			return at >= 255 and (values[at - 255] or 0) or (values[255 - at] or 0)
		end
		return values[at] or 0
	end

	function self.step(audio, mix)
		local total = 0
		for index = 0, 255 do
			local value = bins.shrunk(audio, index)
			if not audio.stereo then
				value = value * (1.0 + (math.abs(lib.sample(audio, (index * 37 % 256) / 255)) - 0.2) * (options.jag or 0.5))
			end
			raw[index] = math.floor(math.max(0, math.min(255, value)))
			total = total + raw[index]
		end
		level_at = level_at % 10 + 1
		levels[level_at] = math.min(255, math.floor(total / 106))
		local sum = 0
		for index = 1, 10 do
			sum = sum + levels[index]
		end
		self.level = math.floor(sum / 10)
		if options.scatter then
			scatter(values, raw)
		else
			for index = 0, 254 do
				values[index] = raw[index + 1]
			end
		end
		values[255] = 0
		for index = 1, count do
			local value = pick(map[index])
			if blend[index] then
				value = math.floor((value + pick(blend[index])) / 2)
			end
			if offset ~= 0 and value ~= 0 then
				value = math.max(0, math.min(255, value + offset))
			end
			out[index] = value
		end
		if smooth > 0 then
			sums[count + 1] = 0
			for index = count, 1, -1 do
				sums[index] = sums[index + 1] + out[index]
			end
			for index = 1, count do
				local last = index + smooth
				if last <= count then
					out[index] = math.min(255, math.floor((out[index] * 2 + sums[index + 1] - sums[last + 1]) / (smooth + 1)))
				else
					local total, value = out[index], out[index]
					for reach = 0, smooth do
						local at = index + reach
						if at > count then
							at = options.clamp_last and count or index
						end
						total = total + (at == index and value or out[at])
						value = math.floor(total / (smooth + 1))
					end
					out[index] = math.min(255, value)
				end
			end
		end
		local weight = mix or options.history or 0
		for index = 1, count do
			local value = out[index]
			if weight > 0 then
				value = math.floor((value * (100 - weight) + history[index] * weight) / 100)
				history[index] = value
			end
			if index <= 352 then
				self.heights[index] = value + 0.0
			end
		end
	end

	return self
end

local function wrap(value, span)
	while value > span do
		value = value - span
	end
	while value < -span do
		value = value + span
	end
	return value
end

function columns.preset(name, options)
	return {
		name = name,
		size = { 350, 320 },
		filter = "nearest",
		setup = function(state, scene)
			local node = ColorRect.new()
			local material = ShaderMaterial.new()
			material.shader = nari.load(COLUMNS)
			material:set_shader_parameter("palette", palette(options.palette))
			material:set_shader_parameter("source", Vector2i(3, options.rows))
			material:set_shader_parameter("mode", options.mode)
			material:set_shader_parameter("place", options.place)
			material:set_shader_parameter("strip", options.strip)
			material:set_shader_parameter("strip_roll", options.roll or 0)
			material:set_shader_parameter("edge_reach", options.edge and options.edge[1] or 0)
			material:set_shader_parameter("edge_amount", options.edge and options.edge[2] or 0)
			material:set_shader_parameter("edge_side", options.edge and options.edge[3] or 0)
			material:set_shader_parameter("reach", options.reach)
			material:set_shader_parameter("amount", options.amount)
			material:set_shader_parameter("sides", options.sides)
			material:set_shader_parameter("bright", options.bright or 0)
			node.material = material
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.size = Vector2(352, 320)
			scene.viewport:add_child(node)
			state.node = node
			state.material = material
			state.roll = options.start or 0.0
			state.pipe = columns.pipeline(options)
			material:set_shader_parameter("count", state.pipe.count)
			state.reach_now = options.fade_reach or 0
			state.mix = options.history or 0
		end,
		step = function(state, audio)
			state.roll = wrap(state.roll + options.speed, options.rows)
			local hidden = false
			if options.gate then
				local level = state.pipe.level
				if level < 5 then
					if state.reach_now > 0 then
						state.reach_now = state.reach_now - 1
					end
					if state.mix <= 98 then
						state.mix = state.mix + 2
					end
				else
					if state.reach_now < 16 then
						state.reach_now = state.reach_now + 4
						state.mix = 99
					end
					if state.mix >= 1 then
						state.mix = state.mix - 1
					end
				end
				hidden = state.reach_now == 0 and state.mix > 89
				state.material:set_shader_parameter("edge_reach", state.reach_now)
			end
			state.pipe.step(audio, state.mix)
			state.material:set_shader_parameter("heights", state.pipe.heights)
			state.material:set_shader_parameter("roll", state.roll >= 0 and math.floor(state.roll) or math.ceil(state.roll))
			state.material:set_shader_parameter("hidden", hidden)
		end,
	}
end

return columns

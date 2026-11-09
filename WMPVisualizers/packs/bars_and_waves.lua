local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"
local GHOST = "shaders/bars_and_waves/ghost.gdshader"
local LOWEST, RANGE, BIN_HZ = 20, 22050 / 20, 44100 / 2048
local COMB = 256

local function settle(state, index, value)
	if value > state.held[index] then
		state.held[index] = value
		state.speed[index] = 5
	else
		state.held[index] = state.held[index] - state.speed[index]
		state.speed[index] = state.speed[index] + 0.2
	end
	if value > state.top[index] then
		state.top[index] = value
		state.drop[index] = 1
	else
		state.top[index] = state.top[index] - state.drop[index]
		state.drop[index] = state.drop[index] + 0.2
	end
end

local function column_value(state, audio, position)
	local bin = LOWEST * RANGE ^ position / BIN_HZ
	local value = bins.frequency(audio, bin)
	if bin < 1.9 then
		value = value * 0.65
	elseif bin > 8 then
		local detail = state.comb[math.floor(bin * 3) % COMB + 1]
		value = value * (1 + detail * math.min(0.7, bin / 200))
	end
	if value > 0 then
		value = value - 10 + math.random() * 20
	end
	return value
end

local function setup(state)
	state.held, state.speed, state.top, state.drop, state.comb = {}, {}, {}, {}, {}
	for index = 1, COMB do
		state.comb[index] = math.random() * 2 - 1
	end
end

local function advance(state, audio, count, reach, gain)
	for _ = 1, 6 do
		state.comb[math.random(COMB)] = math.random() * 2 - 1
	end
	for index = 1, count do
		if not state.held[index] then
			state.held[index], state.speed[index], state.top[index], state.drop[index] = 0, 5, 0, 1
		end
		local value = column_value(state, audio, (index - 1) / math.max(1, count - 1)) * reach * gain / 255
		settle(state, index, value)
	end
end

local function spectrum(name, fill, peak, fall)
	return {
		name = name,
		feedback = GHOST,
		params = { fall = fall },
		setup = setup,
		step = function(state, audio, scene)
			if scene.width then
				advance(state, audio, scene.width, scene.height, 0.88)
			end
		end,
		draw = function(canvas, state, _, scene)
			local width, height = scene.width, scene.height
			local bars, tops = {}, {}
			local count, marks = 0, 0
			for x = 1, width do
				local top = height - math.max(state.held[x] or 0, 0)
				if top < height then
					bars[count + 1] = Vector2(x - 0.5, top)
					bars[count + 2] = Vector2(x - 0.5, height)
					count = count + 2
				end
				local mark = height - (state.top[x] or 0)
				if mark < top - 1 then
					tops[marks + 1] = Vector2(x - 1, mark)
					tops[marks + 2] = Vector2(x, mark)
					marks = marks + 2
				end
			end
			if count > 0 then
				canvas:draw_multiline(bars, fill)
			end
			if marks > 0 then
				canvas:draw_multiline(tops, peak)
			end
		end,
	}
end

return {
	name = "Bars and Waves",
	presets = {
		{
			name = "Bars",
			layers = { CLEAR },
			setup = setup,
			step = function(state, audio, scene)
				if scene.width then
					advance(state, audio, 50, scene.height, 1.0)
				end
			end,
			draw = function(canvas, state, _, scene)
				local width, height = scene.width, scene.height
				local scale = width / 640
				local slot = 6 * scale
				local bar = 5 * scale
				local left = (width - slot * 50) / 2
				local mark = math.max(1, math.floor(height / 480 + 0.5))
				for index = 1, 50 do
					local x = left + (index - 1) * slot
					local top = math.min(height - 1, math.max(state.held[index] or 0, 0))
					canvas:draw_rect(Rect2(x, height - top, bar, top), Color(0.0, 0.69, 0.125, 1.0))
					local peak = math.min(height - mark, state.top[index] or 0)
					if peak > top then
						canvas:draw_rect(Rect2(x, height - peak, bar, mark), Color(0.125, 0.125, 1.0, 1.0))
					end
				end
			end,
		},
		spectrum("Ocean Mist", Color(0.0, 0.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 1.0), Color(0.078, 0.078, 0.078, 0.0)),
		spectrum("Fire Storm", Color(1.0, 0.647, 0.0, 1.0), Color(1.0, 0.0, 0.0, 1.0), Color(0.059, 0.059, 0.0, 0.0)),
		{
			name = "Scope",
			layers = { CLEAR },
			draw = function(canvas, _, audio, scene)
				local width, height = scene.width, scene.height
				local least = math.min(width, height)
				local base = math.floor(height / 2) - math.floor(least / 4)
				local points = {}
				local count = math.min(width, 512)
				for step = 0, count do
					local at = bins.wave(audio, step / count * 1023)
					points[#points + 1] = Vector2(step / count * width, base + at / 255 * least / 2)
				end
				canvas:draw_polyline(points, Color(0.627, 1.0, 0.627, 1.0), 1.0)
			end,
		},
	},
}

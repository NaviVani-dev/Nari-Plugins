local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"
local DECAY = 3.0
local COUNT = 256
local STEP = math.pi / 256

local function channel(base, value)
	if base == 0 then
		return 0
	end
	return math.min(255, base - 180 + value * 4) / 255
end

local function preset(name, tint, dots)
	return {
		name = name,
		layers = { CLEAR },
		setup = function(state)
			state.held, state.shown = {}, {}
			for index = 1, COUNT do
				state.held[index], state.shown[index] = 64, 64
			end
		end,
		step = function(state, audio)
			local held, shown = state.held, state.shown
			for index = 1, COUNT do
				local value = math.floor(bins.wave(audio, (index - 1) * 4) / 2)
				if value > held[index] then
					held[index] = value
					shown[index] = value
				else
					shown[index] = math.max(64, math.floor(held[index]))
					held[index] = held[index] - DECAY
				end
			end
		end,
		draw = function(canvas, state, _, scene)
			local width, height = scene.width, scene.height
			local cx, cy = math.floor(width / 2), math.floor(height / 2)
			local reach = math.min(width, height) / 256
			local center = Vector2(cx, cy)
			local size = math.max(1, math.floor(height / 480 + 0.5))
			for index = 1, COUNT do
				local value = state.shown[index]
				local angle = (index - 1) * STEP
				local radius = value * reach
				local x, y = math.cos(angle) * radius, math.sin(angle) * radius
				local color = Color(channel(tint[1], value), channel(tint[2], value), channel(tint[3], value), 1.0)
				if dots then
					canvas:draw_rect(Rect2(cx + x, cy + y, size, size), color)
					canvas:draw_rect(Rect2(cx + x, cy - y, size, size), color)
				else
					canvas:draw_line(center, Vector2(cx + x, cy + y), color, size)
					canvas:draw_line(center, Vector2(cx + x, cy - y), color, size)
				end
			end
		end,
	}
end

return {
	name = "Spikes",
	presets = {
		preset("Spike", { 1, 0, 0 }, false),
		preset("Amoeba", { 64, 255, 64 }, true),
	},
}

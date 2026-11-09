local lib = require("lib")
local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"
local FLAG_TIME, STAR_TIME = 3.4, 4.8

local LETTERS = {
	{ 0.03, 0.08 }, { 0.03, 0.2 }, { 0.03, 0.32 }, { 0.03, 0.44 }, { 0.03, 0.56 }, { 0.03, 0.68 }, { 0.05, 0.8 }, { 0.09, 0.9 }, { 0.16, 0.92 }, { 0.23, 0.9 }, { 0.26, 0.8 }, { 0.27, 0.68 }, { 0.27, 0.56 }, { 0.27, 0.44 }, { 0.27, 0.32 }, { 0.27, 0.2 }, { 0.27, 0.08 },
	{ 0.61, 0.13 }, { 0.54, 0.08 }, { 0.47, 0.08 }, { 0.41, 0.15 }, { 0.4, 0.27 }, { 0.44, 0.38 }, { 0.5, 0.45 }, { 0.56, 0.52 }, { 0.61, 0.6 }, { 0.63, 0.72 }, { 0.6, 0.84 }, { 0.53, 0.92 }, { 0.46, 0.92 }, { 0.4, 0.86 },
	{ 0.7, 0.92 }, { 0.72, 0.8 }, { 0.75, 0.68 }, { 0.77, 0.56 }, { 0.79, 0.44 }, { 0.81, 0.32 }, { 0.83, 0.2 }, { 0.85, 0.08 }, { 0.87, 0.2 }, { 0.89, 0.32 }, { 0.91, 0.44 }, { 0.93, 0.56 }, { 0.95, 0.68 }, { 0.97, 0.8 }, { 0.99, 0.92 }, { 0.8, 0.62 }, { 0.85, 0.62 }, { 0.9, 0.62 }, { 0.85, 0.5 },
}

local GRID = {}
for row = 0, 8 do
	for column = 0, (row % 2 == 0 and 5 or 4) do
		GRID[#GRID + 1] = { (column + (row % 2 == 0 and 0.5 or 1)) / 6, (row + 0.5) / 9 }
	end
end

local function star(canvas, x, y, radius, color)
	local points = {}
	for corner = 0, 9 do
		local angle = -math.pi / 2 + corner * math.pi / 5
		local reach = corner % 2 == 0 and radius or radius * 0.4
		points[#points + 1] = Vector2(x + math.cos(angle) * reach, y + math.sin(angle) * reach)
	end
	canvas:draw_colored_polygon(points, color)
end

return {
	name = "Home of the Brave",
	light = true,
	presets = {
		{
			name = "Home of the Brave",
			aspect = 4 / 3,
			layers = { CLEAR },
			setup = function(state)
				state.time = 0
				state.jitter = {}
				for index = 1, #GRID do
					state.jitter[index] = { (math.random() - 0.5) * 0.03, (math.random() - 0.5) * 0.03, math.random() * 6.28 }
				end
			end,
			step = function(state)
				state.time = state.time + 1 / 30
			end,
			draw = function(canvas, state, audio, scene)
				local w, h = scene.width, scene.height
				local white = Color("#ffffff")
				local at = state.time % (FLAG_TIME + STAR_TIME)
				if at > FLAG_TIME then
					canvas:draw_rect(Rect2(0, 0, w, h), Color("#11217c"))
					local t = (at - FLAG_TIME) / STAR_TIME
					local morph = math.abs(t * 2 - 1)
					morph = morph * morph * (3 - 2 * morph)
					local shake = 1 + (audio.bass or 0)
					for index, grid in ipairs(GRID) do
						local letter = LETTERS[index]
						local jitter = state.jitter[index]
						local wobble = math.sin(state.time * 3 + jitter[3]) * morph
						local x = grid[1] + (letter[1] - grid[1]) * morph + jitter[1] * wobble * shake
						local y = grid[2] + (letter[2] - grid[2]) * morph + jitter[2] * wobble * shake
						star(canvas, w * (0.04 + x * 0.92), h * (0.04 + y * 0.92), h * 0.042, white)
					end
					return
				end
				local stripe = h * 0.98 / 13
				for index = 0, 12 do
					if index % 2 == 0 then
						canvas:draw_rect(Rect2(0, index * stripe, w, stripe), Color("#d03700"))
					else
						local reach = math.max(0.08, bins.band(audio, 0.05 + index / 13 * 0.7, 0.35))
						canvas:draw_rect(Rect2(0, index * stripe, w * reach, stripe), white)
					end
				end
				canvas:draw_rect(Rect2(0, 0, w * 0.416, stripe * 7), Color("#11217c"))
				for _, grid in ipairs(GRID) do
					star(canvas, w * 0.416 * grid[1], stripe * 7 * grid[2], h * 0.024, white)
				end
			end,
		},
	},
}

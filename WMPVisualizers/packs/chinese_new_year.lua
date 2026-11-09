local lib = require("lib")
local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"
local SPARKS = 60
local RING = 22
local FOCAL = 1.1
local HEIGHT = 1.65

local FOUNTAINS = {
	{ x = -1.5, z = 3.3, band = 0.04 },
	{ x = 0.05, z = 3.0, band = 0.18 },
	{ x = 1.6, z = 3.5, band = 0.34 },
	{ x = 0.2, z = 5.0, band = 0.5 },
}

local HUES = { 0.33, 0.62, 0.15, 0.85, 0.5, 0.0 }

local function launch(item, fountain, power, tint)
	local angle = math.random() * math.pi * 2
	local spread = math.random() * math.random() * 0.02
	item.x, item.y, item.z = fountain.x, 0, fountain.z
	item.vx, item.vz = math.cos(angle) * spread, math.sin(angle) * spread
	item.vy = (0.012 + math.random() * math.random() * 0.05) * (0.7 + power)
	item.life = 0.7 + math.random() * 0.5
	item.tint = tint
end

return {
	name = "Chinese New Year 2005",
	presets = {
		{
			name = "Magic Fireworks",
			layers = { CLEAR },
			blend = "add",
			setup = function(state)
				state.time = 0
				state.sparks = {}
				for index, fountain in ipairs(FOUNTAINS) do
					fountain.hue = index
					for slot = 1, SPARKS do
						state.sparks[#state.sparks + 1] = { life = 0, owner = fountain }
					end
				end
				state.rings = {}
			end,
			step = function(state, audio)
				state.time = state.time + 1 / 30
				local shift = math.floor(state.time / 2.4)
				for index, fountain in ipairs(FOUNTAINS) do
					fountain.tint = lib.hsv(HUES[(index + shift) % #HUES + 1], 0.6, 1.0)
					fountain.power = bins.band(audio, fountain.band, 0.3)
				end
				for _, item in ipairs(state.sparks) do
					if item.life <= 0 then
						if math.random() < 0.2 + item.owner.power * 0.6 then
							launch(item, item.owner, item.owner.power, item.owner.tint)
						end
					else
						item.x, item.y, item.z = item.x + item.vx, item.y + item.vy, item.z + item.vz
						item.vy = item.vy - 0.0016
						item.life = item.life - 0.017
						if item.y < 0 then
							item.y, item.vy = 0, -item.vy * 0.35
						end
					end
				end
				if #state.rings < 3 and ((audio.bass or 0) > 0.65 and math.random(12) == 1 or math.random(60) == 1) then
					state.rings[#state.rings + 1] = { x = math.random() * 2 - 1, y = 0.08 + math.random() * 0.12, age = 0, tint = lib.hsv(HUES[math.random(#HUES)], 0.5, 1.0) }
				end
				for index = #state.rings, 1, -1 do
					local ring = state.rings[index]
					ring.age = ring.age + 1 / 36
					if ring.age >= 1 then
						table.remove(state.rings, index)
					end
				end
			end,
			draw = function(canvas, state, audio, scene)
				local w, h = scene.width, scene.height
				local unit = h / 480
				local horizon = h * (0.2 + math.sin(state.time * 0.23) * 0.09)
				local sway = math.sin(state.time * 0.17) * 0.5
				canvas:draw_polygon({ Vector2(0, horizon), Vector2(w, horizon), Vector2(w, h), Vector2(0, h) }, { Color(0.04, 0.06, 0.05, 1.0), Color(0.04, 0.06, 0.05, 1.0), Color(0.1, 0.11, 0.08, 1.0), Color(0.1, 0.11, 0.08, 1.0) })
				for _, item in ipairs(state.sparks) do
					if item.life > 0 then
						local scale = FOCAL * h / item.z
						local x = w / 2 + (item.x - sway) * scale
						local ground = horizon + HEIGHT * scale
						local y = ground - item.y * scale
						local tint = lib.alpha(item.tint, math.min(1, item.life * 1.6))
						local size = unit * 8 / item.z * 3
						canvas:draw_rect(Rect2(x, y, size * 0.5, size), tint)
						canvas:draw_rect(Rect2(x, ground + item.y * scale * 0.5, size * 0.5, size * 0.6), lib.alpha(item.tint, item.life * 0.35))
					end
				end
				for _, ring in ipairs(state.rings) do
					local radius = h * 0.09 * math.sqrt(ring.age)
					local cx, cy = w / 2 + (ring.x - sway * 0.3) * h * 0.6, h * ring.y
					local tint = lib.alpha(ring.tint, 1 - ring.age)
					for spark = 1, RING do
						local angle = spark / RING * math.pi * 2
						canvas:draw_rect(Rect2(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius + ring.age * ring.age * h * 0.03, 3 * unit, 4 * unit), tint)
					end
				end
			end,
		},
	},
}

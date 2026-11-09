local lib = require("lib")
local bins = require("packs.wmp_bins")

local DISPLAY = "shaders/startime/display.gdshader"
local CLEAR = "shaders/common/clear.gdshader"

local textures = {}

local function texture(name)
	textures[name] = textures[name] or nari.load("assets/startime/" .. name .. ".png")
	return textures[name]
end

local function jitter(mask)
	local amount = math.random(0, mask)
	return math.random(0, 1) == 0 and -amount or amount
end

local function mask_for(cell)
	local mask = 0xffff
	while mask > cell do
		mask = math.floor(mask / 2)
	end
	return mask
end

local function scatter(width, height)
	local cell_x, cell_y = math.floor(width / 7), math.floor(height / 6)
	local mask_x, mask_y = mask_for(cell_x), mask_for(cell_y)
	local spots = {}
	for index = 0, 42 do
		spots[index + 1] = {
			x = (index % 7) * cell_x - 20 + jitter(mask_x),
			y = math.floor(index / 7) * cell_y - 20 + jitter(mask_y),
		}
	end
	return spots
end

local function field(width, height, sizes)
	local image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	local sprites = {}
	for _, sprite in ipairs(sizes) do
		sprites[#sprites + 1] = texture("star" .. sprite):get_image()
	end
	local source = Rect2(0.0, 0.0, 16.0, 16.0)
	local y = 0
	while y < height do
		local x = math.random(0, 15)
		while x < width do
			image:blend_rect(sprites[math.random(1, #sprites)], source, Vector2i(x, y + math.random(0, 31)))
			x = x + math.random(0, 31) + 3
		end
		y = y + math.random(0, 31) + 3
	end
	return ImageTexture.create_from_image(image)
end

local function roll(state)
	state.rolled = state.rolled + 1
	if state.rolled > 40 then
		state.rolled = 0
		state.offset = math.random(0, 31)
	end
end

local function energy(state, audio, index)
	local at = index + 5 + state.offset
	if at > 42 then
		at = at - 37
	end
	return audio.stereo and bins.shrunk(audio, at) or lib.lift(lib.spectrum(audio, at / 42), 0.38) * 255
end

local function starlight()
	return {
		name = "Starlight",
		aspect = 4 / 3,
		blend = "add",
		layers = { CLEAR },
		setup = function(state)
			state.rolled, state.offset = 0, math.random(0, 31)
			state.spots = scatter(640, 480)
			state.field = field(640, 480, { 64, 65, 66, 67, 68, 69, 70, 71 })
		end,
		step = function(state)
			roll(state)
		end,
		draw = function(canvas, state, audio, scene)
			canvas:draw_texture_rect(state.field, Rect2(0.0, 0.0, scene.width * 1.0, scene.height * 1.0), false)
			local scale = scene.height / 480
			local size = 64 * scale
			for index, spot in ipairs(state.spots) do
				local value = energy(state, audio, index - 1)
				local sprite = value < 5 and 63 or 62 - math.floor(value / 29)
				canvas:draw_texture_rect(texture("star" .. sprite), Rect2(spot.x * scale, spot.y * scale, size, size), false)
			end
		end,
	}
end

local function nebula(name, blob, gain, floor, shift)
	return {
		name = name,
		blend = "add",
		layers = { CLEAR },
		display = DISPLAY,
		params = { gain = gain, floor = floor, shift = shift, plain = false },
		setup = function(state, scene)
			state.rolled, state.offset = 0, math.random(0, 31)
			state.spots = scatter(180, 120)
			state.scroll = math.random()
			state.field = field(352, 320, { 64, 65, 68, 69, 70, 71 })
			scene.engine.set(scene, "palette", texture("palette"))
		end,
		step = function(state, audio, scene)
			roll(state)
			state.scroll = (state.scroll + 0.0016 + (audio.level or 0) * 0.006) % 1
			scene.engine.set(scene, "scroll", state.scroll)
		end,
		draw = function(canvas, state, audio, scene)
			local scale_x, scale_y = scene.width / 180, scene.height / 120
			local size_x, size_y = 64 * scale_x, 64 * scale_y
			local dot = 16 * scale_y / 3
			local glow = texture("glow" .. blob)
			local spark = texture("star70")
			canvas:draw_texture_rect(state.field, Rect2(0.0, 0.0, scene.width * 1.0, scene.height * 1.0), false, Color(0.0, 0.45, 0.6, 1.0))
			for index, spot in ipairs(state.spots) do
				local value = (energy(state, audio, index - 1) / 255) ^ 1.3
				canvas:draw_texture_rect(glow, Rect2(spot.x * scale_x, spot.y * scale_y, size_x, size_y), false, Color(value, 0.0, 0.0, 1.0))
			end
			for _, spot in ipairs(state.spots) do
				canvas:draw_texture_rect(spark, Rect2((spot.x + 32) * scale_x - dot / 2, (spot.y + 32) * scale_y - dot / 2, dot, dot), false, Color(0.0, 1.0, 1.0, 1.0))
			end
		end,
	}
end

local function random(list)
	local function choose(state, scene)
		state.pick = list[math.random(#list)]
		state.hold = 0
		state.pick.setup(state, scene)
		local params = state.pick.params or { plain = true }
		for key, value in pairs(params) do
			scene.engine.set(scene, key, value)
		end
	end
	return {
		name = "Random Selection",
		aspect = 4 / 3,
		blend = "add",
		layers = { CLEAR },
		display = DISPLAY,
		setup = choose,
		step = function(state, audio, scene)
			state.hold = state.hold + 1
			if state.hold > 600 then
				choose(state, scene)
			end
			state.pick.step(state, audio, scene)
		end,
		draw = function(canvas, state, audio, scene)
			state.pick.draw(canvas, state, audio, scene)
		end,
	}
end

local presets = {
	starlight(),
	nebula("Star Clouds", 2, 1.0, 0.04, 0.1),
	nebula("Star Glow", 3, 0.65, 0.0, 0.15),
}
presets[4] = random({ presets[1], presets[2], presets[3] })

return { name = "StarTime", presets = presets }

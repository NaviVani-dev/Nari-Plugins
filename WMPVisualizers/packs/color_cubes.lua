local lib = require("lib")
local bins = require("packs.wmp_bins")

local BOX = "shaders/color_cubes/box.gdshader"
local CLEAR = "shaders/common/clear.gdshader"

local RHYTHMIC = { {219, 84, 16, 86}, {195, 20, 40, 80}, {219, 160, 42, 37}, {233, 15, 60, 80}, {265, 53, 72, 48}, {257, 32, 80, 11}, {257, 209, 80, 32}, {219, 181, 80, 80}, {234, 153, 28, 51}, {281, 101, 56, 28}, {321, 129, 16, 86}, {281, 129, 40, 80}, {188, 100, 42, 37}, {277, 222, 60, 80}, {234, 138, 72, 48}, {198, 261, 80, 11}, {202, 95, 80, 32}, {119, 210, 80, 80}, {191, 210, 28, 51}, {234, 115, 56, 28}, {173, 66, 16, 86}, {179, 137, 40, 80}, {153, 63, 42, 37}, {124, 130, 60, 80}, {102, 82, 72, 48}, {77, 289, 80, 11}, {21, 24, 80, 32}, {123, 13, 80, 80}, {31, 251, 28, 51}, {26, 279, 56, 28}, {276, 222, 16, 86}, {19, 12, 40, 80}, {19, 92, 42, 37}, {156, 231, 60, 80}, {206, 259, 72, 48}, {44, 14, 80, 11}, {19, 212, 80, 32}, {19, 218, 80, 80}, {101, 20, 28, 51}, {19, 123, 56, 28}, {19, 126, 16, 86}, {82, 226, 40, 80}, {59, 55, 42, 37}, {277, 19, 60, 80}, {26, 196, 72, 48}, {35, 151, 80, 11}, {35, 162, 80, 32}, {45, 71, 80, 80}, {35, 146, 80, 80}, {113, 151, 16, 86} }
local FLOWER = { {263, 119, 80, 80}, {251, 148, 80, 80}, {233, 179, 80, 80}, {207, 204, 80, 80}, {171, 224, 80, 80}, {136, 237, 80, 80}, {97, 224, 80, 80}, {65, 204, 80, 80}, {38, 179, 80, 80}, {18, 148, 80, 80}, {8, 119, 80, 80}, {18, 92, 80, 80}, {38, 57, 80, 80}, {65, 30, 80, 80}, {97, 17, 80, 80}, {136, 4, 80, 80}, {171, 17, 80, 80}, {207, 36, 80, 80}, {233, 61, 80, 80}, {251, 85, 80, 80}, {74, 58, 200, 200} }
local SHEER = { {333, 306, 16, 86}, {306, 299, 40, 80}, {293, 284, 42, 37}, {253, 297, 60, 80}, {230, 273, 72, 48}, {204, 80, 80, 11}, {201, 255, 80, 32}, {161, 241, 80, 80}, {246, 269, 28, 51}, {180, 231, 56, 28}, {197, 249, 16, 86}, {141, 250, 40, 80}, {2, 284, 42, 37}, {12, 305, 60, 80}, {23, 298, 72, 48}, {84, 311, 80, 11}, {1, 289, 80, 32}, {24, 191, 28, 51}, {101, 285, 28, 51}, {101, 298, 56, 28}, {111, 262, 16, 86}, {102, 258, 40, 80}, {36, 258, 42, 37}, {68, 243, 60, 80}, {95, 210, 72, 48}, {103, 200, 80, 11}, {151, 219, 80, 32}, {193, 175, 80, 80}, {164, 168, 28, 51}, {46, 229, 56, 28}, {273, 217, 16, 86}, {53, 186, 40, 80}, {216, 138, 42, 37}, {279, 227, 60, 80}, {12, 243, 72, 48}, {269, 217, 80, 11}, {1, 222, 80, 32}, {61, 151, 80, 80}, {302, 186, 28, 51}, {58, 171, 56, 28}, {257, 91, 16, 86}, {87, 101, 40, 80}, {266, 181, 42, 37}, {27, 108, 60, 80}, {225, 91, 72, 48}, {17, 98, 80, 11}, {258, 155, 80, 32}, {7, 166, 80, 80}, {272, 74, 80, 80}, {119, 64, 16, 86} }

local palettes = {}

local function palette(index)
	if not palettes[index] then
		local image = nari.load("assets/color_cubes/palette" .. index .. ".png"):get_image()
		local rows = {}
		for row = 0, image:get_height() - 1 do
			rows[row] = image:get_pixel(0, row)
		end
		rows.count = image:get_height()
		palettes[index] = rows
	end
	return palettes[index]
end

local function letterbox(_, scene)
	local size = scene.area.size
	local view = scene.view
	if not view or size.x < 2 or size.y < 2 then
		return
	end
	local width = math.min(size.x, size.y * 4 / 3)
	local height = width * 3 / 4
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view:set_anchors_preset(Control.PRESET_TOP_LEFT)
	view.position = Vector2((size.x - width) / 2, (size.y - height) / 2)
	view.size = Vector2(width, height)
end

local function build(state, scene, rects, options)
	local back = ColorRect.new()
	back.color = Color(0.0, 0.0, 0.0, 1.0)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.size = Vector2(352, 320)
	scene.viewport:add_child(back)
	state.back = back
	state.boxes = {}
	local shader = nari.load(BOX)
	for index, rect in ipairs(rects) do
		local node = ColorRect.new()
		local material = ShaderMaterial.new()
		material.shader = shader
		material:set_shader_parameter("box", Vector2(rect[3], rect[4]))
		material:set_shader_parameter("near", index == options.large and 90 or options.near)
		material:set_shader_parameter("near_amount", options.near_amount)
		material:set_shader_parameter("far", index == options.large and 90 or options.far)
		material:set_shader_parameter("far_amount", options.far_amount)
		material:set_shader_parameter("subtract", options.subtract or false)
		node.material = material
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.position = Vector2(rect[1], rect[2])
		node.size = Vector2(rect[3], rect[4])
		scene.viewport:add_child(node)
		state.boxes[index] = node
	end
	state.scroll = 0
	state.shift, state.shift_clock = 0, 0
end

local function show(state, visible)
	for _, node in ipairs(state.boxes) do
		node.visible = visible
	end
end

local function bin(audio, index, gain)
	if audio.stereo then
		return math.floor(bins.shrunk(audio, index))
	end
	return math.floor(lib.spectrum(audio, math.min(index, 60) / 60) * gain)
end

local function preset(name, rects, options, step)
	return {
		name = name,
		aspect = 4 / 3,
		size = { 352, 320 },
		filter = "nearest",
		layers = { CLEAR },
		resize = letterbox,
		setup = function(state, scene)
			build(state, scene, rects, options)
		end,
		step = step,
	}
end

return {
	name = "Color Cubes",
	presets = {
		preset("Flower Boxes", FLOWER, { near = 17, near_amount = 250, far = 42, far_amount = 250, large = 21 }, function(state, audio)
			local rows = palette(76)
			state.scroll = (state.scroll + 9) % rows.count
			local level = math.floor((audio.level or 0) * 255)
			show(state, level >= 5)
			for index, node in ipairs(state.boxes) do
				local value = index == 21 and level or bin(audio, index + 1, 50)
				node.color = rows[(value + state.scroll) % rows.count]
			end
		end),
		preset("Rhythmic Squares", RHYTHMIC, { near = 9, near_amount = 100, far = 30, far_amount = 100, subtract = true }, function(state, audio)
			local rows = palette(73)
			state.scroll = (state.scroll + 1) % rows.count
			state.shift_clock = state.shift_clock + 1
			if state.shift_clock > 50 then
				state.shift, state.shift_clock = math.random(0, 31), 0
			end
			local level = math.floor((audio.level or 0) * 255)
			show(state, level >= 5)
			local base = rows[state.scroll]
			for index, node in ipairs(state.boxes) do
				local band = index + 4 + state.shift
				if band > 60 then
					band = band - 50
				end
				local light = math.min(1.0, (bin(audio, band, 40) * 2 + 90) / 255)
				node.color = Color(base.r * light, base.g * light, base.b * light, 1.0)
			end
		end),
		preset("Sheer Delight", SHEER, { near = 2, near_amount = 200, far = 40, far_amount = 100 }, function(state, audio)
			local rows, under = palette(74), palette(75)
			state.scroll = (state.scroll + 1) % rows.count
			state.under = (state.under or 25) - 1 / 3
			state.shift_clock = state.shift_clock + 1
			if state.shift_clock > 100 then
				state.shift, state.shift_clock = math.random(0, 63), 0
			end
			local level = math.floor((audio.level or 0) * 255)
			show(state, level >= 5)
			state.back.color = level >= 5 and under[math.floor(state.under) % under.count] or Color(0.0, 0.0, 0.0, 1.0)
			for index, node in ipairs(state.boxes) do
				local band = index + 4 + state.shift
				if band > 60 then
					band = band - 50
				end
				local value = bin(audio, band, 128)
				if value < 5 then
					node.color = Color(0.22, 0.05 + value * 0.04, 0.02 * value, 1.0)
				else
					node.color = rows[(value + state.scroll) % rows.count]
				end
			end
		end),
	},
}

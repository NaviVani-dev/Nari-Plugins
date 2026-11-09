local psychedelia = require("packs.psychedelia")

local TRAIL = "shaders/psychedelia/album_trail.gdshader"
local SHADER = "shaders/psychedelia/album_cube.gdshader"
local KEEP = 0.97

local function bump(cube, audio, a, b, c, weight)
	cube.rx = cube.rx * KEEP + psychedelia.bin(audio, a) * 255 * 0.1 / weight
	cube.ry = cube.ry * KEEP + psychedelia.bin(audio, b) * 255 * 0.1 / weight
	cube.rz = cube.rz * KEEP + psychedelia.bin(audio, c) * 255 * 0.1 / weight
end

local function follow(cube, source, reach, shrink, mix)
	cube.x, cube.y, cube.z = source.x * reach, source.y * reach, source.z * reach
	cube.size = source.size * shrink
	cube.rx = cube.rx * (1 - mix) + source.rx * mix
	cube.ry = cube.ry * (1 - mix) + source.ry * mix
	cube.rz = cube.rz * (1 - mix) + source.rz * mix
end

local LAYOUTS = {}

function LAYOUTS.simple(cubes, audio)
	bump(cubes[1], audio, 10, 200, 600, 50)
end

local function grid(size)
	return function(cubes, audio)
		for index = 0, 8 do
			local cube = cubes[index + 1]
			cube.x, cube.y = (index % 3 - 1) * 2, (index // 3 - 1) * 2
			cube.size = size
			bump(cube, audio, 10 + index * 2, 200 + index * 2, 600 + index * 2, 50)
		end
	end
end

LAYOUTS.grid = grid(0.75)
LAYOUTS.fat = grid(1.75)

local SPOKES = { { 1.4, 0.0 }, { -1.4, 0.0 }, { 0.0, 1.4 }, { 0.0, -1.4 } }

local function quad(mix, weight)
	return function(cubes, audio)
		for index = 1, 4 do
			follow(cubes[index], cubes[index + 4], 1.15, 0.7, mix)
		end
		for index = 5, 8 do
			follow(cubes[index], cubes[index + 4], 1.3, 0.7, mix)
		end
		for index = 9, 12 do
			follow(cubes[index], cubes[index + 4], 1.7, 0.7, mix)
		end
		local center = cubes[17]
		for index = 13, 16 do
			local cube = cubes[index]
			local spoke = SPOKES[index - 12]
			cube.x, cube.y, cube.z = spoke[1], spoke[2], 0.0
			cube.size = center.size * 0.7
			cube.rx = cube.rx * (1 - mix) + center.rx * mix
			cube.ry = cube.ry * (1 - mix) + center.ry * mix
			cube.rz = cube.rz * (1 - mix) + center.rz * mix
		end
		center.size = 0.5
		bump(center, audio, 10, 200, 600, weight)
	end
end

LAYOUTS.tense = quad(0.6, 50)
LAYOUTS.relaxed = quad(0.01, 10)

local function place(cube)
	local cy, sy = math.cos(cube.ry), math.sin(cube.ry)
	local cx, sx = math.cos(cube.rx), math.sin(cube.rx)
	local cz, sz = math.cos(cube.rz), math.sin(cube.rz)
	local a, b, c = cy * cz + sy * sx * sz, cy * sz - sy * sx * cz, -sy * cx
	local d, e, f = -cx * sz, cx * cz, sx
	local g, h, i = sy * cz - cy * sx * sz, sy * sz + cy * sx * cz, cy * cx
	local size = cube.size
	local material = cube.material
	material:set_shader_parameter("row0", Color(a * size, b * size, c * size, 0.0))
	material:set_shader_parameter("row1", Color(d * size, e * size, f * size, 0.0))
	material:set_shader_parameter("row2", Color(g * size, h * size, i * size, 0.0))
	material:set_shader_parameter("place", Color(cube.x, cube.y, cube.z, 0.0))
end

local mesh

local function preset(name, layout, count)
	return {
		name = name,
		feedback = TRAIL,
		aspect = 4 / 3,
		setup = function(state, scene)
			mesh = mesh or nari.load("assets/psychedelia/album_cube.res")
			state.stage = psychedelia.stage(scene, 1.0)
			state.cubes = {}
			for index = 1, count do
				local node = MeshInstance3D.new()
				node.mesh = mesh
				node.extra_cull_margin = 16000.0
				local material = psychedelia.material(SHADER)
				node.material_override = material
				state.stage:add_child(node)
				state.cubes[index] = { x = 0.0, y = 0.0, z = 0.0, size = 1.0, rx = 0.0, ry = 0.0, rz = 0.0, material = material }
			end
			state.layout = LAYOUTS[layout]
		end,
		resize = function(state, scene)
			if state.stage then
				state.stage.size = Vector2i(scene.width, scene.height)
			end
		end,
		step = function(state, audio)
			state.layout(state.cubes, audio)
			local art = psychedelia.cover(state, "album_default")
			if art ~= state.art then
				state.art = art
				for _, cube in ipairs(state.cubes) do
					cube.material:set_shader_parameter("art", art)
				end
			end
			for _, cube in ipairs(state.cubes) do
				place(cube)
			end
			state.stage.render_target_update_mode = SubViewport.UPDATE_ONCE
		end,
		draw = function(canvas, state, _, scene)
			canvas:draw_texture_rect(state.stage:get_texture(), Rect2(0, 0, scene.width, scene.height), false)
		end,
	}
end

local PRESETS = {
	{ "Simple", "simple", 1 },
	{ "Grid", "grid", 9 },
	{ "Fat Grid", "fat", 9 },
	{ "Tense Quad", "tense", 17 },
	{ "Relaxed Quad", "relaxed", 17 },
}

local chosen = PRESETS[math.random(#PRESETS)]
local presets = { preset("Random", chosen[2], chosen[3]) }
for _, entry in ipairs(PRESETS) do
	presets[#presets + 1] = preset(entry[1], entry[2], entry[3])
end

return {
	name = "Album Art 3D",
	presets = presets,
}

local lib = require("lib")
local bins = require("packs.wmp_bins")

local psychedelia = {}

local textures = {}

function psychedelia.texture(name)
	textures[name] = textures[name] or nari.load("assets/psychedelia/" .. name .. ".png")
	return textures[name]
end

function psychedelia.material(path, params)
	local material = ShaderMaterial.new()
	material.shader = nari.load(path)
	for key, value in pairs(params or {}) do
		material:set_shader_parameter(key, value)
	end
	return material
end

function psychedelia.bin(audio, index)
	if audio.stereo then
		return bins.frequency(audio, index) / 255
	end
	return lib.lift(lib.spectrum(audio, math.log(1 + index) / math.log(1024)), 0.35) * 0.6 / (1 + index / 150)
end

function psychedelia.cover(state, fallback)
	local song = nari.current()
	local id = song and song.id or ""
	if id ~= state.song then
		state.song = id
		state.cover = nil
		if song then
			local cover = MediaPlayer:cover_of(song)
			nari.await(MediaPlayer:get_cover_texture(cover[1], cover[2]), function(texture)
				if state.song == id then
					state.cover = texture
				end
			end)
		end
	end
	return state.cover or psychedelia.texture(fallback)
end

function psychedelia.look(material, ex, ey, ez, ax, ay, az)
	local bx, by, bz = ex - ax, ey - ay, ez - az
	local length = math.sqrt(bx * bx + by * by + bz * bz)
	bx, by, bz = bx / length, by / length, bz / length
	local rx, rz = bz, -bx
	local side = math.sqrt(rx * rx + rz * rz)
	rx, rz = rx / side, rz / side
	material:set_shader_parameter("eye", Color(ex, ey, ez, 0.0))
	material:set_shader_parameter("right", Color(rx, 0.0, rz, 0.0))
	material:set_shader_parameter("above", Color(by * rz, bz * rx - bx * rz, -by * rx, 0.0))
	material:set_shader_parameter("back", Color(bx, by, bz, 0.0))
end

function psychedelia.look_at(material, eye, at)
	local bx, by, bz = eye[1] - at[1], eye[2] - at[2], eye[3] - at[3]
	local length = math.sqrt(bx * bx + by * by + bz * bz)
	bx, by, bz = bx / length, by / length, bz / length
	local rx, ry, rz = -by, bx, 0.0
	length = math.sqrt(rx * rx + ry * ry)
	rx, ry = rx / length, ry / length
	material:set_shader_parameter("eye", Color(eye[1], eye[2], eye[3], 0.0))
	material:set_shader_parameter("right", Color(rx, ry, rz, 0.0))
	material:set_shader_parameter("above", Color(by * rz - bz * ry, bz * rx - bx * rz, bx * ry - by * rx, 0.0))
	material:set_shader_parameter("back", Color(bx, by, bz, 0.0))
end

function psychedelia.single(value)
	return math.min(255.0, value * math.sqrt(-math.log(1.0 - math.random() * 0.999)) / 0.886)
end

function psychedelia.stage(scene, fov)
	local stage = SubViewport.new()
	stage.own_world_3d = true
	stage.transparent_bg = true
	stage.render_target_update_mode = SubViewport.UPDATE_ONCE
	stage.size = Vector2i(scene.width, scene.height)
	scene.viewport:add_child(stage)
	local camera = Camera3D.new()
	camera.fov = fov * 180 / math.pi
	camera.near = 0.1
	camera.far = 20000.0
	stage:add_child(camera)
	return stage
end

local function koi_pass(scene, params, path, shrink)
	local view = SubViewport.new()
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	view.size = Vector2i(math.max(1, math.floor(scene.width / (shrink or 4))), math.max(1, math.floor(scene.height / (shrink or 4))))
	scene.viewport:add_child(view)
	local rect = ColorRect.new()
	rect.material = psychedelia.material(path or "shaders/psychedelia/koi_blur.gdshader", params)
	rect.size = Vector2(view.size.x, view.size.y)
	view:add_child(rect)
	return { view = view, rect = rect, material = rect.material }
end

function psychedelia.koi(scene, stage, out)
	local image = stage:get_texture()
	local across = koi_pass(scene, { scene_image = image })
	local down = koi_pass(scene, { past = across.view:get_texture() })
	across.material:set_shader_parameter("past", down.view:get_texture())
	out:set_shader_parameter("scene_image", image)
	out:set_shader_parameter("glow", down.view:get_texture())
	return { across = across, down = down, out = out, stage = stage }
end

function psychedelia.koi_echo(scene, stage, out)
	local across = koi_pass(scene, { scene_image = stage:get_texture() }, "shaders/psychedelia/koi_echo.gdshader", 2)
	out:set_shader_parameter("glow", across.view:get_texture())
	return { across = across, stage = stage, out = out, echo = true }
end

function psychedelia.koi_resize(koi, scene)
	koi.stage.size = Vector2i(scene.width, scene.height)
	for _, pass in ipairs({ koi.across, koi.down }) do
		local shrink = koi.echo and 2 or 4
		pass.view.size = Vector2i(math.max(1, math.floor(scene.width / shrink)), math.max(1, math.floor(scene.height / shrink)))
		pass.rect.size = Vector2(pass.view.size.x, pass.view.size.y)
	end
end

function psychedelia.koi_step(koi, ms, blend)
	local base = (math.sin(ms / 10000) + 1) * 0.003 + 0.997
	local near = 1 - base
	local swing = near * 0.99
	local c = math.sin(ms / 28911 + 1.57) * swing
	local s = math.sin(ms / 28911) * swing
	local c0 = Vector2(near + c, near + s)
	local c1 = Vector2(base + c, near + c)
	local c2 = Vector2(base + s, base + c)
	local c3 = Vector2(near + s, base + s)
	local across, down = koi.across, koi.down
	for _, pass in ipairs({ across, down }) do
		pass.material:set_shader_parameter("c0", c0)
		pass.material:set_shader_parameter("c1", c1)
		pass.material:set_shader_parameter("c2", c2)
		pass.material:set_shader_parameter("c3", c3)
	end
	if koi.echo then
		across.material:set_shader_parameter("reach", Vector2(1 / koi.stage.size.x, 0.0))
		koi.stage.render_target_update_mode = SubViewport.UPDATE_ONCE
		across.view.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	end
	across.material:set_shader_parameter("scene_weight", blend.scene_in)
	across.material:set_shader_parameter("past_weight", blend.past_in)
	across.material:set_shader_parameter("reach", blend.vertical and Vector2(0.0, 1 / across.view.size.y) or Vector2(1 / across.view.size.x, 0.0))
	down.material:set_shader_parameter("reach", Vector2(0.0, 1 / down.view.size.y))
	koi.out:set_shader_parameter("scene_weight", blend.scene_out)
	koi.out:set_shader_parameter("glow_weight", blend.glow_out)
	koi.stage.render_target_update_mode = SubViewport.UPDATE_ONCE
	across.view.render_target_update_mode = SubViewport.UPDATE_ONCE
	down.view.render_target_update_mode = SubViewport.UPDATE_ONCE
end

local PERM = {}

local function shuffle()
	local table_ = {}
	for index = 0, 255 do
		table_[index] = index
	end
	for index = 255, 1, -1 do
		local other = math.random(0, index)
		table_[index], table_[other] = table_[other], table_[index]
	end
	for index = 0, 255 do
		PERM[index] = table_[index]
		PERM[index + 256] = table_[index]
	end
end

local function gradient(hash, x, y, z)
	local h = hash % 16
	local u = h < 8 and x or y
	local v = h < 4 and y or ((h == 12 or h == 14) and x or z)
	return (h % 2 == 0 and u or -u) + (h % 4 < 2 and v or -v)
end

local function noise(x, y, z)
	local fx, fy, fz = math.floor(x), math.floor(y), math.floor(z)
	local X, Y, Z = fx % 256, fy % 256, fz % 256
	x, y, z = x - fx, y - fy, z - fz
	local u = x * x * x * (x * (x * 6 - 15) + 10)
	local v = y * y * y * (y * (y * 6 - 15) + 10)
	local w = z * z * z * (z * (z * 6 - 15) + 10)
	local A, B = PERM[X] + Y, PERM[X + 1] + Y
	local AA, AB, BA, BB = PERM[A] + Z, PERM[A + 1] + Z, PERM[B] + Z, PERM[B + 1] + Z
	local x1, y1, z1 = x - 1, y - 1, z - 1
	local a = gradient(PERM[AA], x, y, z)
	local b = gradient(PERM[BA], x1, y, z)
	local c = gradient(PERM[AB], x, y1, z)
	local d = gradient(PERM[BB], x1, y1, z)
	local e = gradient(PERM[AA + 1], x, y, z1)
	local f = gradient(PERM[BA + 1], x1, y, z1)
	local g = gradient(PERM[AB + 1], x, y1, z1)
	local h = gradient(PERM[BB + 1], x1, y1, z1)
	a, c, e, g = a + u * (b - a), c + u * (d - c), e + u * (f - e), g + u * (h - g)
	a, e = a + v * (c - a), e + v * (g - e)
	return a + w * (e - a)
end

shuffle()

function psychedelia.turbulence(x, y, z)
	return noise(x, y, z) + noise(x * 2, y * 2, z * 2) * 0.5 + noise(x * 4, y * 4, z * 4) * 0.25
end

function psychedelia.beat()
	local long, short = { sum = 0.0, at = 1 }, { sum = 0.0, at = 1 }
	for index = 1, 120 do
		long[index] = 0.0
	end
	for index = 1, 3 do
		short[index] = 0.0
	end
	local limit, hold = 0.0, 0
	return function(value)
		long.sum = long.sum + value - long[long.at]
		long[long.at] = value
		long.at = long.at % 120 + 1
		short.sum = short.sum + value - short[short.at]
		short[short.at] = value
		short.at = short.at % 3 + 1
		local rise = (short.sum / 3 - long.sum / 120) * 100
		if hold ~= 0 or rise <= limit or rise <= 10 then
			if limit > 0 then
				limit = limit * 0.95
			end
			if hold ~= 0 then
				hold = hold - 1
			end
			return false
		end
		local before = limit * 1.5
		limit = rise
		if before < rise then
			hold = 5
			return true
		end
		return false
	end
end

function psychedelia.energy(audio)
	local total = 0.0
	for index = 0, 13 do
		total = total + psychedelia.bin(audio, index * 50) * 50 * 255
	end
	return total * 0.0001
end

return psychedelia

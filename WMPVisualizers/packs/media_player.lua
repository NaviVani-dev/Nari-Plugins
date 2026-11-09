local bins = require("packs.wmp_bins")

local OCEAN = "shaders/media_player/ocean.gdshader"
local CLOUDS = "shaders/media_player/clouds.gdshader"
local SIM = "shaders/media_player/water_sim.gdshader"
local WATER = "shaders/media_player/water.gdshader"

local BINS = { 5, 10, 15, 20, 30, 40, 55, 70, 85, 95, 105, 115, 125, 135, 145, 155, 165 }
local LEFT = { 204, 197, 180, 173, 154, 147, 129, 122, 106, 99, 81, 74, 56, 49, 31, 24, 8 }
local LINES = { 190, 165, 139, 115, 92, 67, 41, 17 }
local ROW = { 43, 38, 33, 22, 17, 12, 7 }
local LIMIT = { 5, 40, 80, 100, 110, 120, 130 }
local YELLOW = Color(1.0, 1.0, 0.0)
local RULE = Color(0.5569, 0.7373, 0.902, 0.2353)
local CURVES = { { -100, 153, 306, 209, 13, 204, 612, 153 }, { -200, 191, 486, 202, 193, 193, 712, 191 }, { -200, 204, 443, 275, 146, 270, 712, 204 } }

local function boundary(points)
	local list = {}
	local t = 0
	for index = 0, 64 do
		local x = index * 8
		local px, py
		repeat
			local u = 1 - t
			px = u * u * u * points[1] + 3 * u * u * t * points[3] + 3 * u * t * t * points[5] + t * t * t * points[7]
			py = u * u * u * points[2] + 3 * u * u * t * points[4] + 3 * u * t * t * points[6] + t * t * t * points[8]
			t = t + 0.001
		until px >= x or t > 1
		list[index + 1] = py
	end
	return list
end

local clouds = {}

local ROWS = { { 4, 75, 40, 70 }, { 39, 63, 80, 57 }, { 79, 50, 100, 45 }, { 119, 38, 110, 33 }, { 149, 26, 120, 21 }, { 179, 14, 130, 10 } }

local function sprites(prefix)
	local names = { "1a", "2a", "3a", "4a", "5a", "6a" }
	local set = { bright = nari.load("assets/media_player/" .. prefix .. "1b.png"), peak = nari.load("assets/media_player/" .. prefix .. "peak.png") }
	for index, name in ipairs(names) do
		set[index] = nari.load("assets/media_player/" .. prefix .. name .. ".png")
	end
	if prefix == "button_" then
		for _, name in ipairs({ "r1", "r2", "r3", "r_peak" }) do
			set[name] = nari.load("assets/media_player/" .. prefix .. name .. ".png")
		end
	end
	return set
end

local function album_load(state, song)
	local album = state.album
	album.title = song and tostring(song.title or song.name or "") or ""
	album.artist = song and tostring(song.artist or "") or ""
	album.record = song and tostring(song.album or "") or ""
	album.cover = state.next_cover
end

local function album_step(state, scene)
	local album = state.album
	local song = nari.current()
	local id = song and song.id or ""
	if id ~= album.id then
		album.id = id
		state.next_cover = nil
		if song then
			local cover = MediaPlayer:cover_of(song)
			nari.await(MediaPlayer:get_cover_texture(cover[1], cover[2]), function(texture)
				if album.id == id then
					state.next_cover = texture
					if album.phase ~= 1 then
						album.cover = texture
					end
				end
			end)
		end
		if album.phase == -1 then
			album_load(state, song)
			album.phase, album.since = 2, state.clock
		else
			album.pending = song or false
			album.phase, album.since = 1, state.clock
		end
	end
	local age = state.clock - album.since
	if album.phase == 1 then
		if age < 1 then
			album.fade = age * 255
		else
			album_load(state, album.pending or nil)
			album.phase, album.since, age = 2, state.clock, 0
		end
	end
	if album.phase == 2 then
		local t = age * 0.2
		if t < 1 then
			album.fade = 255 - t * 255
			local f = 1 - math.min(t * t * t * t + 0.6, 1)
			album.x, album.y, album.z = -22 + 24 * f, 7 - 15 * f, -23.176 + 49.99 * f
		else
			album.phase, album.fade = 0, 0
			album.x, album.y, album.z = -22, 7, -23.176
		end
	end
	local depth = 51.632 - album.z
	album.size = 64 * 1.7321 / depth * 240
	album.left = 320 + (album.x - 32) * 1.299 / depth * 320
	album.top = 240 - (album.y + 32) * 1.7321 / depth * 240
	album.width = 64 * 1.299 / depth * 320
	local rect = scene.view:get_global_rect()
	local shown_x, shown_y, shown_w, shown_h = rect.position.x, rect.position.y, rect.size.x, rect.size.y
	if scene.view.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED then
		local scale = math.min(rect.size.x / scene.width, rect.size.y / scene.height)
		shown_w, shown_h = scene.width * scale, scene.height * scale
		shown_x = rect.position.x + (rect.size.x - shown_w) / 2
		shown_y = rect.position.y + (rect.size.y - shown_h) / 2
	end
	local mouse = scene.area:get_global_mouse_position()
	local mx, my = (mouse.x - shown_x) / shown_w * 640, (mouse.y - shown_y) / shown_h * 480
	local within = mx > 0 and my > 0 and mx < 640 and my < 480
	local inside = within and mx > album.left and my > album.top and mx < album.left + album.width * 0.4 and my < album.top + album.size * 0.4
	if inside then
		if album.shown == 0 then
			album.shown = 1
		end
	elseif album.shown == 1 then
		album.shown = 0
	end
	album.hover = inside and album.cover ~= nil
	local pressed = Input:is_mouse_button_pressed(1)
	if pressed and not album.pressed and within and not album.hover then
		album.shown = album.shown == 2 and 0 or 2
	end
	album.pressed = pressed
end

local function album_draw(canvas, state, scene)
	local album = state.album
	if album.shown == 0 or album.phase == -1 then
		return
	end
	clouds.font = clouds.font or ThemeDB.fallback_font
	local sx, sy = scene.width / 640, scene.height / 480
	local alpha = 1 - math.max(0, math.min(255, album.fade)) / 255
	local white = Color(1.0, 1.0, 1.0, alpha)
	local dark = Color(0.0, 0.1137, 0.2471, 0.4706 * alpha)
	canvas:draw_set_transform(Vector2(album.left * sx, album.top * sy), 0.0, Vector2(album.width / 512 * sx, album.size / 512 * sy))
	if album.cover then
		clouds.frame = clouds.frame or nari.load("assets/media_player/album_drop_shadow.png")
		clouds.hover = clouds.hover or nari.load("assets/media_player/album_hover.png")
		canvas:draw_texture_rect(album.hover and clouds.hover or clouds.frame, Rect2(3, 3, 208, 208), false, white)
		canvas:draw_texture_rect(album.cover, Rect2(3, 3, 200, 200), false, white)
	else
		clouds.none = clouds.none or nari.load("assets/media_player/no_cover.png")
		canvas:draw_texture_rect(clouds.none, Rect2(3, 13, 202, 182), false, white)
	end
	local function line(text, y, height, size, step, rise, count)
		if text == "" then
			return
		end
		local font = clouds.font
		local lines = {}
		local current = ""
		for word in text:gmatch("%S+") do
			local joined = current == "" and word or current .. " " .. word
			if #lines + 1 < count and current ~= "" and font:get_string_size(joined, 0, -1, size).x > 290 then
				lines[#lines + 1] = current
				current = word
			else
				current = joined
			end
		end
		lines[#lines + 1] = current
		local last = lines[#lines]
		if font:get_string_size(last, 0, -1, size).x > 290 then
			while #last > 1 and font:get_string_size(last .. "...", 0, -1, size).x > 290 do
				last = last:sub(1, -2)
			end
			lines[#lines] = last .. "..."
		end
		local top = y + (height - #lines * step) / 2 + rise
		for index, words in ipairs(lines) do
			local base = top + (index - 1) * step
			for offset = 2, 0, -1 do
				canvas:draw_string(font, Vector2(235 + offset, base + offset), words, 0, -1, size, offset == 0 and white or dark)
			end
		end
	end
	line(album.title, 10, 80, 30, 36, 31, 2)
	line(album.artist, 95, 30, 22, 27, 23, 1)
	line(album.record, 120, 30, 22, 27, 23, 1)
	canvas:draw_set_transform(Vector2(0, 0), 0.0, Vector2(1, 1))
end

return {
	name = "Windows Media Player",
	presets = {
		{
			name = "Rhythm and Waves",
			aspect = 4 / 3,
			layers = { OCEAN },
			setup = function(state, scene)
				local holder = SubViewport.new()
				holder.size = Vector2i(64, 64)
				holder.disable_3d = true
				holder.use_hdr_2d = true
				holder.transparent_bg = false
				holder.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
				holder.render_target_update_mode = SubViewport.UPDATE_ONCE
				scene.canvas:add_child(holder)
				local sim = ColorRect.new()
				sim.size = Vector2(64.0, 64.0)
				sim.mouse_filter = Control.MOUSE_FILTER_IGNORE
				sim.material = ShaderMaterial.new()
				sim.material.shader = nari.load(SIM)
				holder:add_child(sim)
				local mesh = PlaneMesh.new()
				mesh.orientation = PlaneMesh.FACE_Z
				mesh.size = Vector2(1.0, 1.0)
				mesh.subdivide_width = 62
				mesh.subdivide_depth = 62
				local node = Control.new()
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE
				node.material = ShaderMaterial.new()
				node.material.shader = nari.load(WATER)
				node.material:set_shader_parameter("water", holder:get_texture())
				node.material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
				scene.canvas:add_child(node)
				node.draw:connect(function()
					node:draw_mesh(mesh, nil)
				end)
				state.holder, state.sim, state.node, state.frame = holder, sim, node, 0
				state.cells = {}
				for column = 1, 17 do
					state.cells[column] = { 0, 0, 0, 0, 0, 0, 0 }
				end
				local set = scene.engine.set
				for index, points in ipairs(CURVES) do
					set(scene, "curve" .. index, boundary(points))
				end
			end,
			resize = function(state, scene)
				if state.node then
					state.node.material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
				end
			end,
			step = function(state, audio, scene)
				state.frame = state.frame + 1
				local bin = (math.random(0, 255) & 0xf0) + 1
				local material = state.sim.material
				material:set_shader_parameter("frame", state.frame)
				local quiet = (audio.level or 0) * 255 < 11
				material:set_shader_parameter("rate", quiet and 0.05 or 0.07)
				material:set_shader_parameter("calm", quiet and 0.882 or 0.98)
				material:set_shader_parameter("drop", Color(math.random(16, 47), math.random(16, 47), bins.frequency(audio, bin)))
				state.holder.render_target_update_mode = SubViewport.UPDATE_ONCE
				for column, cells in ipairs(state.cells) do
					for row = 1, 6 do
						if cells[row] == 255 and cells[row + 1] == 255 then
							cells[row] = 0
						elseif cells[row] == 255 then
							cells[row] = 254
						end
					end
					if cells[7] == 255 then
						cells[7] = 254
					end
					cells[1] = cells[1] >> 1
					for row = 2, 7 do
						local value = cells[row]
						if value == 254 then
							cells[row - 1] = 254
							cells[row] = value >> 1
						elseif value < 20 then
							cells[row] = value >> 1
						else
							cells[row] = value - 20
						end
					end
					local byte = bins.frequency(audio, BINS[column]) * bins.grain(audio)
					local count = 0
					for row = 1, 7 do
						if byte >= LIMIT[row] then
							count = row
						end
					end
					for row = 1, count do
						cells[row] = 255
					end
				end
			end,
			draw = function(canvas, state, _, scene)
				local sx, sy = scene.width / 640, scene.height / 480
				for _, x in ipairs(LINES) do
					canvas:draw_rect(Rect2((303.9 + x * 1.5376) * sx, 220.3 * sy, 1.5 * sx, 83.2 * sy), RULE)
				end
				local wide, tall = 6.15 * sx, 6.4 * sy
				for column, cells in ipairs(state.cells) do
					local x = (303.9 + LEFT[column] * 1.5376) * sx
					for row = 1, 7 do
						local value = cells[row]
						if value > 0 then
							canvas:draw_rect(Rect2(x, (220.3 + ROW[row] * 1.6) * sy, wide, tall), value == 255 and YELLOW or Color(0.5569, 0.8353, 1.0, value / 255))
						end
					end
				end
			end,
		},
		{
			name = "Energy Bliss",
			aspect = 4 / 3,
			layers = { CLOUDS },
			setup = function(state, scene)
				clouds.sky = clouds.sky or nari.load("assets/media_player/sky.jpg")
				clouds[1] = clouds[1] or nari.load("assets/media_player/cloud1.jpg")
				clouds[2] = clouds[2] or nari.load("assets/media_player/cloud2.jpg")
				local set = scene.engine.set
				set(scene, "sky", clouds.sky)
				set(scene, "cloud1", clouds[1])
				set(scene, "cloud2", clouds[2])
				state.t, state.clock, state.last, state.start = 0, 0, -5, Time:get_ticks_usec()
				state.album = { phase = -1, shown = 2, fade = 255, since = 0, x = -22, y = 7, z = -23.176 }
				state.layers = {}
				for index = 0, 7 do
					state.layers[index] = { active = false, x = 0, y = 0, z = 0, rot = 2.65, alpha = 255, start = 0 }
				end
				state.value, state.raw, state.peak = {}, {}, {}
				for column = 1, 38 do
					state.value[column], state.raw[column], state.peak[column] = 0, 0, 83
				end
			end,
			step = function(state, audio, scene)
				state.t = state.t + 1.077 / 30
				state.clock = (Time:get_ticks_usec() - state.start) / 1000000
				local t, now, layers = state.t, state.clock, state.layers
				album_step(state, scene)
				for index = 0, 7 do
					local layer = layers[index]
					if index % 2 == 0 then
						local mate = layers[index + 1]
						if not layer.active and now - state.last > 5 and math.random(0, 7) == 0 then
							layer.active, layer.start, state.last = true, now, now
							layer.x = (index == 0 or index == 4) and math.sin(t * 1.33) * 15 or math.sin(t * 3.33) * 20
							layer.y, layer.z = 0, 20
							mate.active, mate.start = true, now
							mate.x = math.sin(t * 0.5) * 7
							mate.z = (math.sin(t * 2.7) + 1) * -5
						end
						mate.y = -0.5 - (math.sin(t * 0.3) + 1) * 1.5
						local age = (now - layer.start) * 0.025
						if age >= 0.85 then
							layer.active = false
						elseif layer.active then
							layer.rot = age * 0.5 + 2.65
							mate.rot = layer.rot
							layer.z = age * 50 + 20
							layer.y = age * 15
							layer.alpha = math.max(0, 255 - math.floor(age * 2000))
						end
					else
						layer.alpha = math.max(math.floor(math.sin(t * 0.2) * 260), layers[index - 1].alpha)
						if layer.alpha >= 255 then
							layer.alpha = 255
							layer.x = math.sin(t * 0.5) * 7
							layer.z = (math.sin(t * 2.7) + 1) * -5
						end
						layer.alpha = math.max(0, layer.alpha)
					end
				end
				local place, pitch, fade = {}, {}, {}
				for index = 0, 7 do
					local layer = layers[index]
					local x, y, z = layer.x, layer.y, layer.z
					if index % 2 == 1 then
						local base = layers[index - 1]
						local c, s = math.cos(layer.rot), math.sin(layer.rot)
						x, y, z = x + base.x, y * c - z * s + base.y, y * s + z * c + base.z
					end
					place[index + 1] = Color(x, y, z, 1.0)
					pitch[index + 1] = layer.rot
					fade[index + 1] = layer.active and layer.alpha / 255 or 1.0
				end
				local set = scene.engine.set
				set(scene, "place", place)
				set(scene, "pitch", pitch)
				set(scene, "fade", fade)
				local value, raw, peak = state.value, state.raw, state.peak
				for column = 1, 38 do
					if column ~= 19 and column ~= 20 then
						local bin = column < 19 and column * 9 + 1 or 354 - column * 9
						local byte = math.floor(math.min(255, bins.frequency(audio, bin) * bins.grain(audio)))
						raw[column] = byte
						value[column] = value[column] > byte and math.floor(value[column] * 0.95) or byte
						local cap = peak[column]
						for row = 1, 6 do
							if value[column] > ROWS[row][1] then
								cap = math.min(cap, ROWS[row][4])
							end
						end
						peak[column] = cap < 83 and cap * 1.015 + 0.7 or 83
					end
				end
			end,
			draw = function(canvas, state, _, scene)
				local hd = scene.height >= 600
				clouds.small = clouds.small or sprites("button_")
				clouds.large = clouds.large or (hd and sprites("button_hd_"))
				local set = hd and clouds.large or clouds.small
				local sx, sy = scene.width / 640 * 1.0737, scene.height / 480 * 1.098
				local top = scene.height * 0.728
				local wide, tall, low = 10 * sx, 10 * sy, 8 * sy
				for column = 1, 38 do
					if column ~= 19 and column ~= 20 then
						local x = column * 15 * sx
						local value, raw = state.value[column], state.raw[column]
						if value > 4 then
							canvas:draw_texture_rect(clouds.small.r1, Rect2(x, top + 88 * sy, wide, low), false)
						end
						if value > 79 then
							canvas:draw_texture_rect(clouds.small.r2, Rect2(x, top + 98 * sy, wide, low), false)
						end
						if value > 99 then
							canvas:draw_texture_rect(clouds.small.r3, Rect2(x, top + 108 * sy, wide, low), false)
						end
						for row = 1, 6 do
							local item = ROWS[row]
							if value > item[1] then
								local image = raw < item[3] and set.bright or set[row]
								canvas:draw_texture_rect(image, Rect2(x, top + (item[2] - 2) * sy, wide, tall), false)
							end
						end
						local cap = state.peak[column]
						if cap > 4 then
							canvas:draw_texture_rect(set.peak, Rect2(x, top + (math.floor(cap) - 10) * sy, wide, tall), false)
						end
						if cap >= 83 then
							canvas:draw_texture_rect(clouds.small.r_peak, Rect2(x, top + 88 * sy, wide, low), false)
						end
					end
				end
				album_draw(canvas, state, scene)
			end,
		},
	},
}

local lib = require("lib")
local bins = require("packs.wmp_bins")

local LAYER = "shaders/dungeon_siege/layer.gdshader"
local FLAME = "shaders/dungeon_siege/flame.gdshader"
local CLEAR = "shaders/common/clear.gdshader"

local RATE = 3 / 31
local TICKS = 31 / 3
local WIDTH, HEIGHT = 352, 320
local COLUMNS = 64

local textures = {}

local function texture(name)
	if not textures[name] then
		textures[name] = nari.load("assets/dungeon_siege/" .. name .. ".png")
	end
	return textures[name]
end

local function rand(mask)
	return math.random(0, mask)
end

local function cosine(degrees)
	return math.cos(math.rad(degrees))
end

local function sprite(scene, name, x, y, z)
	local node = TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.texture = texture(name)
	node.visible = false
	scene.viewport:add_child(node)
	return { node = node, x = x, y = y, z = z, alpha = 0 }
end

local function shaded(scene, name, maskname, x, y, z)
	local item = sprite(scene, name, x, y, z)
	local material = ShaderMaterial.new()
	material.shader = nari.load(LAYER)
	material:set_shader_parameter("mask", texture(maskname))
	item.node.material = material
	item.material = material
	item.scroll = 0
	item.height = item.node.texture:get_height()
	return item
end

local function pick(item, name)
	item.node.texture = texture(name)
end

local function sync(item)
	local size = item.node.texture:get_size()
	item.node.position = Vector2(item.x + 1, item.y - item.z)
	item.node.size = size
	if not item.material then
		item.node.modulate = Color(1.0, 1.0, 1.0, 1.0 - item.alpha / 255)
	end
end

local function feed(item, radius, source, dest)
	local material = item.material
	item.node.position = Vector2(item.x + 1, item.y - item.z)
	item.node.size = item.node.texture:get_size()
	material:set_shader_parameter("offset", item.scroll / item.height)
	material:set_shader_parameter("radius", radius)
	material:set_shader_parameter("fade", item.alpha / 255)
	material:set_shader_parameter("gain_source", source / 255)
	material:set_shader_parameter("gain_dest", dest / 255)
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

local function stage(state, scene)
	local back = ColorRect.new()
	back.color = Color(0.0, 0.0, 0.0, 1.0)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.position = Vector2(0, 0)
	back.size = Vector2(WIDTH, HEIGHT)
	scene.viewport:add_child(back)
	local burn = ColorRect.new()
	local material = ShaderMaterial.new()
	material.shader = nari.load(FLAME)
	material:set_shader_parameter("palette", texture("palette"))
	burn.material = material
	burn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burn.position = Vector2(1, 0)
	burn.size = Vector2(350, HEIGHT)
	burn.visible = false
	scene.viewport:add_child(burn)
	state.burn = { node = burn, material = material, radius = 116, amount = 250, scroll = 0, heights = {} }
	for index = 1, COLUMNS do
		state.burn.heights[index] = 0.0
	end
	state.base = sprite(scene, "base", 135, 0, 0)
	state.logo = sprite(scene, "logo", 0, 156, 157)
	state.lit = sprite(scene, "lit", 275, 105, 105)
	state.blink = sprite(scene, "blink1", 258, 306, 202)
	state.twitch = sprite(scene, "twitch18", 305, 306, 75)
	state.flame1 = shaded(scene, "flame1", "flame_mask", 275, 100, 124)
	state.flame2 = shaded(scene, "flame2", "flame_mask", 275, 100, 124)
	state.eyes = sprite(scene, "eyes", 0, -183, -264)
	state.demon = sprite(scene, "demon", 0, -183, -264)
	state.spirit = sprite(scene, "spirit22", 22, -250, -50)
	state.fire1 = shaded(scene, "fire1", "fire_mask", 0, -124, 0)
	state.fire2 = shaded(scene, "fire2", "fire_mask", 0, -183, 0)
	state.demon.alpha, state.eyes.alpha = 255, 255
	state.spirit_image = 22 + rand(7)
	state.radius = 80
	state.flame_wait, state.twitch_wait, state.twitch_hold, state.twitch_last = 0, 0, 0, 0
	state.blink_wait, state.blink_hold = 0, 0
	state.fire_angle, state.fire_alpha_rate = 0, 0
	state.eye_rate, state.eye_wait, state.eye_count = 0, 0, rand(3) + 1
	state.fire2_rate, state.demon_rate, state.spirit_rate, state.spirit_angle, state.spirit_spin = 0, 0, 0, 100, 0
	state.spirit_wait = 40 + rand(63)
	pick(state.spirit, "spirit" .. state.spirit_image)
end

local function eyes_at(state, x, z)
	state.eyes.x, state.eyes.z = x, z
	state.demon.x, state.demon.z = x, z
	if state.spirit.node.visible == false then
		state.fire1.x, state.fire1.y, state.fire1.z = x - 29, -124, z - 42
		state.fire2.x, state.fire2.z = x - 29, z - 117
	end
end

local function clamp255(value)
	return math.max(0, math.min(255, value))
end

local function integrate(state)
	state.flame1.scroll = (state.flame1.scroll + 2 * RATE) % state.flame1.height
	state.flame2.scroll = (state.flame2.scroll + 6 * RATE) % state.flame2.height
	state.fire1.scroll = (state.fire1.scroll + 10 * RATE) % state.fire1.height
	state.fire2.scroll = (state.fire2.scroll + 14 * RATE) % state.fire2.height
	state.fire_angle = state.fire_angle + 10 * RATE
	state.spirit_angle = state.spirit_angle + state.spirit_spin
	state.fire2.alpha = clamp255(state.fire2.alpha + state.fire2_rate)
	state.demon.alpha = clamp255(state.demon.alpha + state.demon_rate)
	state.spirit.alpha = clamp255(state.spirit.alpha + state.spirit_rate)
end

local function flames_shown(state, shown)
	state.flame1.node.visible = shown
	state.flame2.node.visible = shown
end

local function face(state, level)
	local twitch = state.twitch
	if level < 41 then
		twitch.node.visible = false
	elseif state.twitch_wait <= 0 then
		if state.twitch_hold <= 0 then
			state.twitch_wait = math.floor(rand(31) * TICKS + 20)
			local choice = rand(3)
			if choice == 0 then
				state.twitch_hold = math.floor(rand(31) * TICKS + 7)
				state.twitch_image = 1
				pick(twitch, "twitch1")
				twitch.x, twitch.y, twitch.z = 258, 316, 218
			elseif choice > 1 then
				state.twitch_hold = math.floor(rand(15) * TICKS + 17)
				state.twitch_image = 12
				pick(twitch, "twitch12")
				twitch.x, twitch.y, twitch.z = 266, 311, 176
			else
				state.twitch_hold = math.floor(rand(127) * TICKS + 60)
				state.twitch_image = 18
				pick(twitch, "twitch18")
				twitch.x, twitch.y, twitch.z = 305, 306, 75
			end
		else
			state.twitch_hold = state.twitch_hold - 1
			twitch.node.visible = level >= state.twitch_last
		end
		state.twitch_last = state.twitch_image == 12 and 0 or level
	else
		state.twitch_wait = state.twitch_wait - 1
		twitch.node.visible = false
	end
	if level < 11 then
		if state.radius < 161 then
			state.radius = state.radius + 4
			flames_shown(state, true)
		else
			flames_shown(state, false)
			state.lit.node.visible = false
			pick(state.blink, "blink1")
			state.blink.node.visible = true
		end
	elseif state.radius == 9 then
		state.lit.node.visible = true
	else
		state.radius = math.max(9, state.radius - 1)
	end
	if state.flame_wait <= 0 then
		flames_shown(state, true)
	else
		state.flame_wait = state.flame_wait - 1
	end
	state.lit.alpha = 255 - math.min(255, math.floor(level / 16) * 32)
end

local function blinking(state, level)
	if state.blink_hold > 0 then
		state.blink_hold = state.blink_hold - 1
		state.blink.node.visible = true
		state.lit.node.visible = true
	elseif state.blink_wait <= 0 then
		state.blink_wait = math.floor((rand(63) + 24) * TICKS)
		state.blink.node.visible = true
	else
		state.blink_wait = state.blink_wait - 1
		state.blink.node.visible = false
		if level > 5 then
			return
		end
		state.blink_wait = math.floor((rand(63) + 24) * TICKS)
		state.blink.node.visible = true
	end
	if not state.flame1.node.visible and state.lit.node.visible then
		state.blink.node.visible = false
	elseif state.lit.node.visible and state.lit.alpha <= 180 then
		pick(state.blink, "blink2")
	else
		pick(state.blink, "blink1")
	end
end

local function next_spirit(state)
	state.spirit_image = state.spirit_image + rand(3) + 1
	if state.spirit_image > 31 then
		state.spirit_image = rand(1) + 22
	end
	pick(state.spirit, "spirit" .. state.spirit_image)
end

local function rising(state)
	local spirit, fire1, fire2 = state.spirit, state.fire1, state.fire2
	if spirit.alpha < 200 then
		if state.spirit_trigger then
			state.spirit_wait = math.floor(TICKS * 20)
		elseif state.spirit_wait <= 0 then
			local size = spirit.node.texture:get_size()
			state.spirit_spin = 5 * RATE
			spirit.x = 65 - math.floor(size.x / 2)
			spirit.z = math.floor(size.y / 2) - 490
			if size.y < 105 then
				spirit.z = math.floor(size.y / 4) - 495
			end
			if state.spirit_angle >= 180 then
				state.spirit_rate = 5 * RATE
				if spirit.alpha < 100 then
					state.spirit_angle = 180
				end
			else
				spirit.alpha, state.spirit_rate = 0, 0
			end
			spirit.z = spirit.z - math.floor((cosine(state.spirit_angle) + 1) * size.y)
			spirit.node.visible = true
			if not fire1.node.visible then
				fire1.node.visible = true
				fire2.node.visible = true
			end
			fire1.x, fire1.y, fire1.z = -34, 195, -40
			fire1.alpha, fire2.alpha = 78, 0
			fire2.x, fire2.z = -43, -459
			if spirit.alpha > 130 then
				local sink = math.floor(spirit.alpha - 130)
				fire1.z = -40 - sink
				fire2.z = -459 - sink
			end
		else
			state.spirit_wait = state.spirit_wait - 1
		end
	else
		spirit.alpha, state.spirit_rate = 0, 0
		spirit.node.visible = false
		state.spirit_wait = math.floor(rand(31) * TICKS + 20)
		state.spirit_angle, state.spirit_spin = 100, 0
		fire1.node.visible = false
		fire2.node.visible = false
		next_spirit(state)
	end
end

local function apparition(state)
	local demon, fire1, fire2 = state.demon, state.fire1, state.fire2
	if fire2.alpha >= 255 then
		fire2.node.visible = false
		state.spirit_trigger = false
	end
	if demon.alpha >= 255 then
		demon.node.visible = false
	end
	if demon.alpha < 100 and state.demon_rate < 0 then
		state.demon_rate = 0
	end
	if fire2.alpha <= 0 and fire2.node.visible then
		if not fire1.node.visible then
			fire1.node.visible = true
			state.fire_angle = 0
			state.demon_rate = -20 * RATE
			demon.node.visible = true
		end
		if not state.spirit.node.visible then
			if state.fire_angle >= 350 then
				fire1.node.visible = false
				state.eye_wait = 0
				state.fire2_rate = 10 * RATE
				state.demon_rate = 10 * RATE
				return
			end
			fire1.alpha = (cosine(state.fire_angle) + 1) * 128
		end
	end
end

local function poster_step(state, audio)
	local level = math.floor((audio.level or 0) * 255)
	integrate(state)
	state.gain_dest = math.min(15, (audio.bass or 0) * 255 / 4)
	state.gain_source = math.min(15, (audio.level or 0) * 255 / 3)
	if state.demon.node.visible then
		flames_shown(state, false)
		state.lit.node.visible = false
		pick(state.blink, "blink1")
		state.blink.node.visible = false
		state.blink_hold, state.flame_wait = 10, 17
		state.twitch.node.visible = false
	end
	face(state, level)
	rising(state)
	blinking(state, level)
	local eyes = state.eyes
	eyes.node.visible = eyes.alpha < 255
	apparition(state)
	if state.eye_wait > 0 then
		state.eye_wait = state.eye_wait - 1
		return
	end
	eyes.alpha = eyes.alpha + state.eye_rate
	if eyes.alpha <= 0 then
		eyes.alpha = 0
		state.eye_rate = (rand(15) + 3) * TICKS
		state.eye_wait = math.floor(rand(15) * TICKS + 10)
		if state.eye_count > 0 then
			state.eye_count = state.eye_count - 1
			return
		end
		if eyes.x > 64 or eyes.z > -251 or state.fire1.node.visible or state.fire2.node.visible or state.spirit.node.visible then
			return
		end
		state.spirit_trigger = true
		state.eye_count = rand(3) + 3
		state.fire2.alpha = 130
		state.fire2_rate = -25 * RATE
		state.fire2.node.visible = true
	end
	if eyes.alpha < 255 or state.demon.node.visible then
		return
	end
	eyes.alpha = 255
	state.eye_rate = (-3 - rand(15)) * RATE
	state.eye_wait = math.floor(rand(15) * TICKS + 20)
	local x, z
	if state.eye_count < 1 and not state.fire1.node.visible and not state.fire2.node.visible and not state.spirit.node.visible then
		z = -290 - rand(63)
		x = rand(63) - 20
		state.spirit_trigger = true
	else
		z = -120 - rand(127)
		x = rand(255) - 65
		if x > 100 then
			x = x - 100
		end
	end
	eyes_at(state, x, z)
end

local function present(state)
	feed(state.flame1, state.radius, 0, state.gain_dest or 0)
	feed(state.flame2, state.radius, state.gain_source or 0, 0)
	feed(state.fire1, 0, 0, 0)
	feed(state.fire2, 0, 0, 0)
	for _, item in ipairs({ state.base, state.logo, state.lit, state.blink, state.twitch, state.eyes, state.demon, state.spirit }) do
		sync(item)
	end
end

local function burn_step(state, audio)
	local burn = state.burn
	for index = 1, COLUMNS do
		local at = (index - 1) / (COLUMNS - 1)
		local value = audio.stereo and bins.shrunk(audio, math.floor(at * 255)) or lib.spectrum(audio, at) * (1 + math.abs(lib.sample(audio, at)) * 0.9 - 0.2) * 255
		burn.heights[index] = burn.heights[index] * 0.5 + value * 0.5
	end
	burn.scroll = (burn.scroll + 8) % 319
	burn.material:set_shader_parameter("heights", burn.heights)
	burn.material:set_shader_parameter("scroll", burn.scroll)
	burn.material:set_shader_parameter("radius", burn.radius)
	burn.material:set_shader_parameter("amount", burn.amount)
end

local function elapsed(state, scene)
	return scene.time - state.since >= state.hold
end

local function wait(state, scene, seconds)
	state.since, state.hold = scene.time, seconds
end

local function story_step(state, audio, scene)
	local level = math.floor((audio.level or 0) * 255)
	local burn, logo, base = state.burn, state.logo, state.base
	integrate(state)
	logo.alpha = clamp255(logo.alpha + state.logo_rate)
	base.alpha = clamp255(base.alpha + state.base_rate)
	burn_step(state, audio)
	if state.act == 0 then
		burn.node.visible = true
		logo.node.visible = false
		if state.eyes.alpha >= 255 then
			state.eyes.node.visible = false
			state.eye_rate = 0
		else
			state.eye_rate = 20 * RATE
		end
		burn.radius = math.max(116, burn.radius - 20)
		burn.amount = math.max(250, burn.amount - 20)
		state.eyes.alpha = clamp255(state.eyes.alpha + state.eye_rate)
		if elapsed(state, scene) then
			state.act = 1
			logo.alpha, state.logo_rate = 255, -15 * RATE
			logo.node.visible = true
			logo.x, logo.z = 44, 145
		end
	end
	if state.act == 1 and logo.alpha <= 0 then
		state.act = 2
		wait(state, scene, rand(3) + 5)
	end
	if state.act == 2 and elapsed(state, scene) then
		state.act = 3
		state.logo_rate = 15 * RATE
	end
	if state.act == 3 then
		if state.phase ~= 3 then
			burn.radius = burn.radius + 7
			burn.amount = burn.amount + 7
		end
		if logo.alpha >= 230 and state.phase == 3 then
			logo.node.visible = false
			state.act = 8
		end
		if logo.alpha >= 230 and burn.radius > 349 then
			state.act = 4
			wait(state, scene, rand(3) + 7)
			state.eye_rate = -20
			if state.phase ~= 0 then
				state.act = 5
				logo.x, logo.z = 44, 109
				logo.alpha = 230
			end
		end
	end
	if state.act == 4 then
		burn.node.visible = false
		logo.node.visible = false
		local eyes, demon = state.eyes, state.demon
		eyes.node.visible = eyes.alpha < 255
		if state.fire2.alpha >= 255 then
			state.fire2.node.visible = false
		end
		if demon.alpha >= 255 then
			demon.node.visible = false
		end
		if demon.alpha < 100 and state.demon_rate < 0 then
			state.demon_rate = 0
		end
		if state.fire2.alpha <= 0 and state.fire2.node.visible then
			if not state.fire1.node.visible then
				state.fire1.node.visible = true
				state.fire_angle = 0
				state.demon_rate = -20 * RATE
				demon.node.visible = true
			end
			if state.fire_angle >= 350 then
				state.fire1.node.visible = false
				state.eye_wait = 0
				state.phase = 1
				state.fire2_rate = 10 * RATE
				state.demon_rate = 10 * RATE
			else
				state.fire1.alpha = (cosine(state.fire_angle) + 1) * 128
			end
		end
		if state.eye_wait > 0 then
			state.eye_wait = state.eye_wait - 1
		else
			eyes.alpha = eyes.alpha + state.eye_rate * RATE
			if eyes.alpha <= 0 then
				eyes.alpha = 0
				state.eye_rate = rand(15) + 20
				state.eye_wait = rand(7) + 7
				if state.eye_count > 0 then
					state.eye_count = state.eye_count - 1
				else
					state.eye_count = rand(1) + 2
					state.fire2.alpha = 130
					state.fire2_rate = -25 * RATE
					state.fire2.node.visible = true
				end
			elseif eyes.alpha >= 255 and not demon.node.visible then
				eyes.alpha = 255
				state.eye_rate = -20 - rand(15)
				state.eye_wait = rand(7) + 7
				local x, z = rand(255), -124 - rand(255)
				eyes.x, eyes.z, demon.x, demon.z = x, z, x, z
				state.fire1.x, state.fire1.y, state.fire1.z = x - 29, -124, z - 42
				state.fire2.x, state.fire2.z = x - 29, z - 117
				if state.phase == 1 then
					state.phase = 2
					eyes.node.visible = false
					state.fire1.node.visible = false
					state.fire2.node.visible = false
					demon.node.visible = false
				end
			end
		end
		if state.phase == 2 and elapsed(state, scene) then
			state.act = 0
			wait(state, scene, rand(7) + 20)
		end
	end
	if state.act == 5 then
		burn.node.visible = false
		logo.node.visible = true
		if logo.x < 1 then
			logo.alpha = 0
		else
			logo.x = logo.x - 1
			logo.z = logo.z + 1
		end
		if logo.alpha <= 0 then
			if elapsed(state, scene) then
				state.act = 6
				wait(state, scene, rand(7) + 200)
				state.base_rate = -6 * RATE
				base.node.visible = true
			end
		else
			state.logo_rate = -3
		end
	end
	if state.act == 6 then
		face(state, level)
		blinking(state, level)
		state.gain_dest = math.min(15, (audio.bass or 0) * 255 / 4)
		state.gain_source = math.min(15, (audio.level or 0) * 255 / 3)
		if base.alpha > 0 then
			flames_shown(state, false)
			state.lit.node.visible = false
			state.blink.node.visible = false
			state.flame_wait = 17
			state.twitch.node.visible = false
		elseif elapsed(state, scene) then
			state.act = 7
			wait(state, scene, rand(7) + 20)
			state.logo_rate, state.base_rate = 6 * RATE, 6 * RATE
			flames_shown(state, false)
			state.lit.node.visible = false
			state.blink.node.visible = false
			state.flame_wait = 17
			state.twitch.node.visible = false
		end
	end
	if state.act == 7 and logo.alpha >= 230 then
		state.phase = 3
		state.act = 0
		base.node.visible = false
		logo.node.visible = false
		wait(state, scene, rand(3) + 20)
	end
	if state.act == 8 then
		state.act = 9
		wait(state, scene, rand(7) + 50)
	end
	if state.act == 9 then
		local spirit = state.spirit
		spirit.node.visible = true
		if spirit.alpha < 230 then
			spirit.z = spirit.z + math.floor(13 * RATE + 0.5)
			if spirit.z - spirit.node.texture:get_height() > -130 then
				state.spirit_rate = 23 * RATE
			end
		else
			spirit.alpha, state.spirit_rate = 0, 0
			spirit.z = -160
			spirit.x = rand(255)
			next_spirit(state)
		end
		if elapsed(state, scene) and spirit.z == -160 then
			spirit.node.visible = false
			state.act = 0
			state.phase = 0
		end
	end
end

return {
	name = "Dungeon Siege",
	presets = {
		{
			name = "Poster",
			aspect = 4 / 3,
			size = { WIDTH, HEIGHT },
			filter = "nearest",
			layers = { CLEAR },
			resize = letterbox,
			setup = function(state, scene)
				stage(state, scene)
				state.base.node.visible = true
				state.logo.node.visible = true
				state.lit.node.visible = true
				state.blink.node.visible = true
				state.eyes.y, state.demon.y = -183, -183
				eyes_at(state, rand(255) - 65 > 100 and 0 or rand(100) - 65, -120 - rand(127))
				state.eye_rate = -4
				state.eyes.alpha = 255
			end,
			step = function(state, audio)
				poster_step(state, audio)
				present(state)
			end,
		},
		{
			name = "Lurking in the dark lies an enemy...",
			aspect = 4 / 3,
			size = { WIDTH, HEIGHT },
			filter = "nearest",
			layers = { CLEAR },
			resize = letterbox,
			setup = function(state, scene)
				stage(state, scene)
				state.act, state.phase = 0, 0
				state.since, state.hold = 0, rand(3) + 5
				state.logo_rate, state.base_rate = 0, 0
				state.base.alpha, state.logo.alpha = 255, 255
				state.logo.x, state.logo.z = 44, 121
				state.spirit.x, state.spirit.y, state.spirit.z = 110, 110, -160
				state.eyes.x, state.eyes.z = 0, -264
				state.demon.x, state.demon.z = 0, -264
				state.fire1.x, state.fire1.z = -29, -306
				state.fire2.x, state.fire2.z = -29, -381
				state.burn.node.visible = true
			end,
			step = function(state, audio, scene)
				story_step(state, audio, scene)
				present(state)
			end,
		},
	},
}

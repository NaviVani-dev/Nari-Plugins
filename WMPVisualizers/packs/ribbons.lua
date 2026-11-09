local psychedelia = require("packs.psychedelia")

local TRAIL = "shaders/psychedelia/ribbon_trail.gdshader"
local EMBOSS = "shaders/psychedelia/emboss.gdshader"
local SHADER = "shaders/psychedelia/ribbon.gdshader"
local TOP = 51
local SPAN = 6.0
local LOW, HIGH = 0.002, 0.005

local function speed(low, high)
	return low + (high - low) * math.random()
end

local function bounce(position, velocity, reach, low, high)
	if velocity > 0 and position > reach then
		return -speed(low, high)
	elseif velocity < 0 and position < -reach then
		return speed(low, high)
	end
	return velocity
end

local function channel(value, shift)
	return ((value >> shift) & 255) / 255
end

local function create(state, count)
	state.ribbons = {}
	local shade = count < 10 and count or 10
	for index = 1, count do
		local r, g, b = math.random(), math.random(), math.random()
		local low = math.min(r, g, b) * 0.5
		r, g, b = r - low, g - low, b - low
		local high = math.max(r, g, b)
		local value = math.floor(r / high / shade * 255) << 16 | math.floor(g / high / shade * 255) << 8 | math.floor(b / high / shade * 255)
		local triple = value * 3 & 0xFFFFFF
		state.mesh:set_instance_color(index - 1, Color(channel(value, 16), channel(value, 8), channel(value, 0), 1.0))
		state.mesh:set_instance_custom_data(index - 1, Color(channel(triple, 16), channel(triple, 8), channel(triple, 0), 1.0))
		state.ribbons[index] = {
			x = (math.random() - math.random()) * 5, y = (math.random() - math.random()) * 5, z = (math.random() - math.random()) * 5,
			vx = speed(LOW, HIGH), vy = speed(LOW, HIGH), vz = speed(LOW, HIGH),
			mx = 0.0, my = 0.0, mz = 0.0,
		}
	end
end

local function camera(state, level, hit)
	local cam = state.camera
	if hit then
		state.flip = state.flip % 3 + 1
		local key = ({ "vx", "vy", "vz" })[state.flip]
		cam[key] = -cam[key]
	end
	local rate = level * 0.2 + 0.5
	cam.x, cam.y, cam.z = cam.x + cam.vx * rate, cam.y + cam.vy * rate, cam.z + cam.vz * rate
	cam.vx = bounce(cam.x, cam.vx, 10.1, 0.0001, 0.005)
	cam.vy = bounce(cam.y, cam.vy, 10.1, 0.0001, 0.005)
	cam.vz = bounce(cam.z, cam.vz, 10.1, 0.0001, 0.005)
	local ex = psychedelia.turbulence(cam.x, cam.y, cam.z) * 10.2
	local ey = psychedelia.turbulence(cam.x + 23.432, cam.y + 32.43, cam.z + 987.43) * 10.2
	local ez = psychedelia.turbulence(cam.x + 0.64, cam.y + 943.93, cam.z - 38.843) * 10.2
	local ax, ay, az = ey * 0.2, ez * 0.2, ex * 0.2
	local bx, by, bz = ex - ax, ey - ay, ez - az
	local length = math.sqrt(bx * bx + by * by + bz * bz)
	bx, by, bz = bx / length, by / length, bz / length
	local rx, ry, rz = bz, 0.0, -bx
	length = math.sqrt(rx * rx + rz * rz)
	rx, rz = rx / length, rz / length
	local ux, uy, uz = by * rz - bz * ry, bz * rx - bx * rz, bx * ry - by * rx
	return Color(ex, ey, ez, 0.0), Color(rx, ry, rz, 0.0), Color(ux, uy, uz, 0.0), Color(bx, by, bz, 0.0), -bx, -by, -bz
end

local function grow(state, audio, dx, dy, dz)
	local turbulence = psychedelia.turbulence
	local bin = psychedelia.bin
	local width, image, head = state.width, state.image, state.head
	local gap = 800 // #state.ribbons
	local stagger = #state.ribbons > 100
	state.tick = (state.tick or 0) + 1
	local tick = state.tick
	for index, ribbon in ipairs(state.ribbons) do
		local rate = bin(audio, 10 + (index - 1) * gap) * 2.55 + 0.01
		local x, y, z = ribbon.x + ribbon.vx * rate, ribbon.y + ribbon.vy * rate, ribbon.z + ribbon.vz * rate
		ribbon.vx = bounce(x, ribbon.vx, SPAN, LOW, HIGH)
		ribbon.vy = bounce(y, ribbon.vy, SPAN, LOW, HIGH)
		ribbon.vz = bounce(z, ribbon.vz, SPAN, LOW, HIGH)
		ribbon.x, ribbon.y, ribbon.z = x, y, z
		local px, py, pz
		if not stagger or (index + tick) % 3 == 0 then
			px = turbulence(x, y, z) * 10
			py = turbulence(x + 23.432, y + 32.43, z + 987.43) * 10
			pz = turbulence(x + 0.64, y + 943.93, z - 38.843) * 10
			ribbon.ax, ribbon.ay, ribbon.az = ribbon.bx or px, ribbon.by or py, ribbon.bz or pz
			ribbon.bx, ribbon.by, ribbon.bz = px, py, pz
			if stagger then
				px, py, pz = ribbon.ax, ribbon.ay, ribbon.az
			end
		else
			local t = ((index + tick) % 3) / 3
			if ribbon.bx then
				px = ribbon.ax + (ribbon.bx - ribbon.ax) * t
				py = ribbon.ay + (ribbon.by - ribbon.ay) * t
				pz = ribbon.az + (ribbon.bz - ribbon.az) * t
			else
				px = turbulence(x, y, z) * 10
				py = turbulence(x + 23.432, y + 32.43, z + 987.43) * 10
				pz = turbulence(x + 0.64, y + 943.93, z - 38.843) * 10
			end
		end
		local ex, ey, ez = px - ribbon.mx, py - ribbon.my, pz - ribbon.mz
		local nx, ny, nz = ey * dz - ez * dy, ez * dx - ex * dz, ex * dy - ey * dx
		local length = math.sqrt(nx * nx + ny * ny + nz * nz)
		if length > 0 then
			local scale = width / length
			nx, ny, nz = nx * scale, ny * scale, nz * scale
		end
		ribbon.mx, ribbon.my, ribbon.mz = px, py, pz
		image:set_pixel(head * 2, index - 1, Color(px - nx, py - ny, pz - nz, 1.0))
		image:set_pixel(head * 2 + 1, index - 1, Color(px + nx, py + ny, pz + nz, 1.0))
	end
	state.texture:update(image)
end

local function preset(name, count, width, fov, emboss)
	return {
		name = name,
		feedback = TRAIL,
		display = emboss and EMBOSS or nil,
		params = { attenuation = 0.97 },
		setup = function(state, scene)
			state.width, state.fov = width, fov
			state.head, state.flip = 0, 0
			state.beat = psychedelia.beat()
			state.camera = {
				x = 0.0, y = 0.0, z = 0.0,
				vx = 0.00255, vy = 0.00255, vz = 0.00255,
			}
			state.image = Image.create(TOP * 2, count, false, Image.FORMAT_RGBAH)
			state.texture = ImageTexture.create_from_image(state.image)
			local plane = QuadMesh.new()
			plane.size = Vector2(1.0, 1.0)
			plane.subdivide_depth = TOP - 2
			state.mesh = MultiMesh.new()
			state.mesh.transform_format = MultiMesh.TRANSFORM_2D
			state.mesh.use_colors = true
			state.mesh.use_custom_data = true
			state.mesh.mesh = plane
			state.mesh.instance_count = count
			create(state, count)
			state.material = psychedelia.material(SHADER, { spine = state.texture })
			scene.canvas.material = state.material
		end,
		step = function(state, audio, scene)
			local energy = psychedelia.energy(audio)
			local hit = state.beat(energy)
			local eye, right, above, back, dx, dy, dz = camera(state, energy, hit)
			state.head = (state.head + TOP - 1) % TOP
			grow(state, audio, dx, dy, dz)
			local material = state.material
			local focal = 1 / math.tan(state.fov / 2)
			material:set_shader_parameter("head", state.head)
			material:set_shader_parameter("eye", eye)
			material:set_shader_parameter("right", right)
			material:set_shader_parameter("above", above)
			material:set_shader_parameter("back", back)
			material:set_shader_parameter("focal", Vector2(focal * scene.height / scene.width, focal))
			material:set_shader_parameter("resolution", Vector2(scene.width, scene.height))
		end,
		draw = function(canvas, state)
			canvas:draw_multimesh(state.mesh, psychedelia.texture("ribbon"))
		end,
	}
end

local PRESETS = {
	{ "Mystify", 1, 0.2, 1.5, false },
	{ "Ribbons", 30, 0.05, 1.0, false },
	{ "Dense", 250, 0.01, 0.5, false },
	{ "Embossed", 30, 0.1, 1.0, true },
	{ "More Embossed", 250, 0.02, 0.5, true },
}

local function make(entry, name)
	return preset(name or entry[1], entry[2], entry[3], entry[4], entry[5])
end

local presets = { make(PRESETS[math.random(#PRESETS)], "Random") }
for _, entry in ipairs(PRESETS) do
	presets[#presets + 1] = make(entry)
end

return {
	name = "Ribbons",
	presets = presets,
}

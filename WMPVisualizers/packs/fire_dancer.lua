local bins = require("packs.wmp_bins")

local FADE = "shaders/fire_dancer/fade.gdshader"
local PARTICLE = "shaders/fire_dancer/particle.gdshader"
local PALETTE = "shaders/fire_dancer/palette.gdshader"
local SUBSTEPS = 9
local RAD = math.pi / 180

local function rnd(limit)
	return math.random(0, limit - 1)
end

local function round(value)
	return math.floor(value + 0.5)
end

local function new_part(parent, x, y, z, flag, blobs)
	return { parent = parent, x = x, y = y, z = z, follow = flag, blobs = blobs or {}, d0 = 0.0, d8 = 0.0, e0 = 0.0, a0 = 0.0, a8 = 0.0, ae = 0.0, b0 = 0.0, b8 = 0.0, be = 0.0, active = false, total = 1, step = 0, wait = 0, queue = {}, m = {} }
end

local VERTEBRAE = {
	{ 0.0, 0.0, { { 0, 0.04, 0.09, 0.095, 0.015, 0.0, 0.0 } } },
	{ 0.01003, 0.02292, { { 0, 0.03, 0.09, 0.08, 0.01, 0.0, 0.0 } } },
	{ 0.0043, 0.0222, { { 0, 0.03, 0.09, 0.075, 0.01, 0.0, 0.0 } } },
	{ 0.0, 0.02148, { { 0, 0.03, 0.09, 0.075, 0.01, 0.0, 0.0 } } },
	{ -0.00573, 0.02077, { { 0, 0.03, 0.09, 0.075, 0.0125, 0.0, 0.0 } } },
	{ -0.00859, 0.02005, { { 0, 0.035, 0.08, 0.08, 0.0125, 0.0, 0.0 } } },
	{ -0.00859, 0.01934, { { 0, 0.04, 0.08, 0.085, 0.015, 0.0, 0.0 } } },
	{ -0.00645, 0.01862, { { 0, 0.045, 0.08, 0.09, 0.0175, 0.0, 0.0 } } },
	{ -0.0043, 0.0179, { { 0, 0.0575, 0.08, 0.095, 0.02375, 0.0, 0.0 } } },
	{ -0.00286, 0.01719, { { 0, 0.05, 0.08, 0.1, 0.02, 0.0, 0.0 } } },
	{ -0.00143, 0.01647, { { 0, 0.055, 0.08, 0.1, 0.0225, 0.0, 0.0 } } },
	{ 0.0, 0.01576, { { 0, 0.06, 0.08, 0.1, 0.025, 0.0, 0.0 }, { 1, 0.07, 0.055, 0.055, 0.065, 0.0, -0.05 }, { 1, 0.07, 0.055, 0.055, 0.065, 0.0, 0.05 } } },
	{ 0.00143, 0.01504, { { 0, 0.055, 0.07, 0.1, 0.0255, 0.0, 0.0 } } },
	{ 0.00286, 0.01432, { { 0, 0.05, 0.06, 0.09, 0.025, 0.0, 0.0 } } },
	{ 0.00358, 0.01361, { { 0, 0.035, 0.05, 0.08, 0.0125, 0.0, 0.0 } } },
	{ 0.0043, 0.01289, { { 0, 0.03, 0.04, 0.07, 0.01, 0.0, 0.0 } } },
	{ 0.00358, 0.01217, { { 0, 0.025, 0.03, 0.06, 0.0075, 0.0, 0.0 }, { 0, 0.03, 0.045, 0.05, 0.0, -0.035, -0.08 }, { 0, 0.03, 0.045, 0.05, 0.0, -0.035, 0.08 } } },
	{ 0.00286, 0.01146, { { 0, 0.03, 0.05, 0.04, 0.01, 0.0, 0.0 } } },
	{ 0.00215, 0.01074, { { 0, 0.03, 0.05, 0.03, 0.01, 0.0, 0.0 } } },
	{ 0.00143, 0.01003, { { 0, 0.0275, 0.05, 0.0275, 0.01, 0.0, 0.0 } } },
	{ 0.00072, 0.00931, { { 0, 0.025, 0.05, 0.025, 0.01, 0.0, 0.0 } } },
	{ 0.00072, 0.00859, { { 0, 0.0225, 0.05, 0.0225, 0.01, 0.0, 0.0 } } },
	{ -0.00215, 0.00788, { { 0, 0.025, 0.06, 0.02, 0.015, 0.0, 0.0 } } },
	{ -0.00143, 0.00716, { { 0, 0.0275, 0.06, 0.025, 0.015, 0.0, 0.0 } } },
}

local function build()
	local body = { parts = {}, chain = {} }
	local function add(name, ...)
		local part = new_part(...)
		body[name] = part
		body.parts[#body.parts + 1] = part
		return part
	end
	add("hips", nil, 0.0, 0.5, 0.0, false, { { 0, 0.05, 0.075, 0.1, 0.01, -0.01, 0.0 }, { 0, 0.075, 0.085, 0.08, -0.02, -0.04, -0.05 }, { 0, 0.075, 0.085, 0.08, -0.02, -0.04, 0.05 } })
	add("rthigh", body.hips, -0.105, -0.05, 0.0125, "thigh", { { 2, 0.07, 0.24, 0.07, -0.01, -0.135, 0.03 } })
	add("lthigh", body.hips, 0.105, -0.05, 0.0125, "thigh", { { 2, 0.07, 0.24, 0.07, -0.01, -0.135, -0.03 } })
	add("rshin", body.rthigh, 0.0, -0.31667, -0.0125, false, { { 0, 0.025, 0.175, 0.035, 0.0, -0.19, 0.05 }, { 0, 0.035, 0.09, 0.04, -0.01, -0.13, 0.03 } })
	add("lshin", body.lthigh, 0.0, -0.31667, -0.0125, false, { { 0, 0.025, 0.175, 0.035, 0.0, -0.19, -0.05 }, { 0, 0.035, 0.09, 0.04, -0.01, -0.13, -0.03 } })
	add("rfoot", body.rshin, 0.0, -0.31667, 0.0, false)
	add("lfoot", body.lshin, 0.0, -0.31667, 0.0, false)
	add("spine", body.hips, 0.0, 0.0, 0.0, "spine")
	local previous = body.spine
	for index, item in ipairs(VERTEBRAE) do
		local part = new_part(previous, 0.0, item[2], item[1], false, item[3])
		for _, blob in ipairs(part.blobs) do
			blob.vertebra = true
		end
		body.chain[index] = part
		previous = part
		if index == 17 then
			body.shoulder = part
		end
	end
	add("rarm", body.shoulder, -0.1, 0.0, 0.0, false, { { 0, 0.03, 0.15, 0.03, 0.0, -0.11, 0.0 } })
	add("larm", body.shoulder, 0.1, 0.0, 0.0, false, { { 0, 0.03, 0.15, 0.03, 0.0, -0.11, 0.0 } })
	add("head", previous, 0.0, 0.00729, 0.0, false, { { 0, 0.08, 0.1, 0.07, 0.045, 0.08, 0.0 } })
	add("rfore", body.rarm, 0.0, -0.2, 0.0, false, { { 0, 0.02, 0.12, 0.03, 0.0, -0.12, 0.0 } })
	add("lfore", body.larm, 0.0, -0.2, 0.0, false, { { 0, 0.02, 0.12, 0.03, 0.0, -0.12, 0.0 } })
	add("rhand", body.rfore, 0.0, -0.2, 0.0, false)
	add("lhand", body.lfore, 0.0, -0.2, 0.0, false)
	body.lfore.d8, body.rfore.d8 = -5.0, -5.0
	body.larm.d8, body.larm.e0 = 15.0, -90.0
	body.rarm.d8, body.rarm.e0 = 15.0, 90.0
	return body
end

local function tween(part, total, wait, clear, d0, d8, e0)
	if part.active and not clear then
		part.queue[#part.queue + 1] = { total, wait, d0, d8, e0 }
		return
	end
	part.total, part.step, part.wait = total, 0, wait
	part.a0, part.a8, part.ae = part.d0, part.d8, part.e0
	part.b0, part.b8, part.be = d0, d8, e0
	part.active = true
	if clear then
		part.queue = {}
	end
end

local function advance(part)
	if part.active then
		if part.wait > 0 then
			part.wait = part.wait - 1
			return
		end
		part.step = part.step + 1
		local t = part.step / math.max(part.total, 1)
		local u = 1.0 - t
		part.e0 = part.be * t + part.ae * u
		part.d8 = part.b8 * t + part.a8 * u
		part.d0 = part.b0 * t + part.a0 * u
		if part.total <= part.step then
			part.active = false
		end
	end
	if not part.active and part.queue[1] then
		local item = table.remove(part.queue, 1)
		part.total, part.step, part.wait = item[1], 0, item[2]
		part.a0, part.a8, part.ae = part.d0, part.d8, part.e0
		part.b0, part.b8, part.be = item[3], item[4], item[5]
		part.active = true
	end
end

local function zero(part, total, clear)
	tween(part, total, 0, clear, 0.0, 0.0, 0.0)
end

local function spin_xz(m, degrees)
	if degrees == 0.0 then
		return
	end
	local c, s = math.cos(degrees * RAD), math.sin(degrees * RAD)
	for i = 1, 3 do
		local x, z = m[i], m[i + 6]
		m[i] = x * c - z * s
		m[i + 6] = x * s + z * c
	end
end

local function spin_yz(m, degrees)
	if degrees == 0.0 then
		return
	end
	local c, s = math.cos(degrees * RAD), math.sin(degrees * RAD)
	for i = 1, 3 do
		local y, z = m[i + 3], m[i + 6]
		m[i + 3] = y * c + z * s
		m[i + 6] = z * c - y * s
	end
end

local function place(part, source, d0, d8, e0)
	local m = part.m
	for i = 1, 12 do
		m[i] = source[i]
	end
	for i = 1, 3 do
		m[i + 9] = m[i + 9] + m[i + 6] * part.z + m[i + 3] * part.y + m[i] * part.x
	end
	spin_xz(m, e0)
	spin_yz(m, d8)
	spin_xz(m, d0 - e0)
end

local function pose(state, body)
	local root = { 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0 }
	spin_xz(root, state.yaw)
	for _, part in ipairs(body.parts) do
		if part == body.spine then
			place(part, part.parent.m, 0.0, 0.0, 0.0)
			local previous = part
			for _, item in ipairs(body.chain) do
				place(item, previous.m, part.d0 / 24, part.d8 / 24, part.e0)
				previous = item
			end
		elseif part.follow == "thigh" then
			place(part, part.parent.m, part.d0, part.d8 - part.parent.d8, part.e0)
		else
			place(part, part.parent and part.parent.m or root, part.d0, part.d8, part.e0)
		end
	end
end

local function feet_floor(state, body)
	local reach = math.min(body.rfoot.m[11], body.lfoot.m[11]) + 0.2
	if state.floor < reach then
		state.fall = state.fall + 1 / 1024
		state.floor = state.floor + state.fall
	end
	if reach < state.floor then
		state.floor = reach
		state.fall = 0.0
	end
end

local function pair(state, swap)
	local b = state.body
	if swap then
		return b.lthigh, b.lshin, b.rthigh, b.rshin
	end
	return b.rthigh, b.rshin, b.lthigh, b.lshin
end

local function march_like(angle)
	return function(move, state)
		if state.level > 3.0 then
			local b, D = state.body, state.tempo
			if move.at == 0 or move.at == 2 then
				zero(b.lthigh, D, true)
				zero(b.lshin, D, true)
				zero(b.rthigh, D, true)
				zero(b.rshin, D, true)
				if move.at == 0 then
					move.at = rnd(4) < 3 and 1 or 3
				else
					move.at = rnd(4) < 3 and 3 or 1
				end
			else
				local thigh, shin, other, other_shin = pair(state, move.at == 3)
				local wait = 0
				if other.d8 ~= 0.0 or other_shin.d8 ~= 0.0 then
					zero(other, D // 2, true)
					zero(other_shin, D // 2, true)
					wait = D // 2
				end
				local v = rnd(15) + 90
				local turn = move.at == 1 and angle or -angle
				tween(thigh, D, wait, wait == 0, turn, -v, turn)
				tween(shin, D, wait, wait == 0, 0.0, v * 1.5, 0.0)
				zero(thigh, D, false)
				zero(shin, D, false)
				move.at = move.at == 1 and 2 or 0
			end
			move.count = move.count + 1
		end
		return false
	end
end

local function counted(move)
	move.count = move.count + 1
	return move.span <= move.count
end

local function kick_start(sexy)
	return function(move, state)
		local D = state.tempo
		move.span = D
		local swap = rnd(2) ~= 0
		local thigh, shin, other, other_shin = pair(state, swap)
		local v = rnd(15) + 130
		local side = swap and -20.0 or 20.0
		local wait = 0
		if thigh.d8 ~= 0.0 or shin.d8 ~= 0.0 then
			zero(thigh, D, true)
			zero(shin, D, true)
			wait = D
		end
		tween(other, D, wait, false, 0.0, -v, side)
		if sexy then
			tween(other_shin, D // 2, wait, false, 0.0, v, 0.0)
			zero(other_shin, D // 2, false)
			zero(other, D, false)
		else
			zero(other, D, false)
			tween(other_shin, D // 2, wait, false, 0.0, 30.0, 0.0)
			zero(other_shin, D // 2, false)
		end
	end
end

local function spread_start(move, state)
	local b, D = state.body, state.tempo
	local v = rnd(15)
	tween(b.rthigh, D, 0, true, 0.0, v, 90.0)
	zero(b.rshin, D, true)
	tween(b.lthigh, D, 0, true, 0.0, v, -90.0)
	zero(b.lshin, D, true)
	move.span = D
end

local function kickback_start(move, state)
	local D = state.tempo
	local swap = rnd(2) ~= 0
	local thigh, shin, other, other_shin = pair(state, swap)
	local v = rnd(20)
	if thigh.d8 ~= 0.0 or shin.d8 ~= 0.0 then
		zero(thigh, D, true)
		zero(shin, D, true)
	end
	tween(other, D * 3, D, false, 0.0, v + 20, swap and -20.0 or 20.0)
	tween(other_shin, D * 2, D, false, 0.0, (v + 20) * 2, 0.0)
	zero(other_shin, D, false)
	zero(other, D * 2, false)
	move.span = D * 4
end

local function cross_start(move, state)
	local D = state.tempo
	local swap = rnd(2) == 0
	local a, b, c = rnd(20), rnd(20), rnd(40)
	local thigh, shin, other, other_shin = pair(state, not swap)
	if other.d8 ~= 0.0 or other_shin.d8 ~= 0.0 then
		zero(other, D, true)
		zero(other_shin, D, true)
	end
	if swap then
		tween(thigh, D, D, false, a + 70, -(b + 80), 20.0)
	else
		tween(thigh, D, D, false, -(a + 70), -(b + 80), -20.0)
	end
	tween(shin, D // 2, D, false, 0.0, c + 80, 0.0)
	zero(shin, D, false)
	zero(thigh, D, false)
	move.span = D * 3
end

local function footwork_step(move, state)
	local D = rnd(2) == 0 and state.tempo or state.tempo // 2
	if state.level > 2.5 then
		local b = state.body
		if move.at == 0 or move.at == 2 then
			if rnd(6) == 0 then
				zero(b.lthigh, D, true)
				zero(b.lshin, D, true)
				zero(b.rthigh, D, true)
				zero(b.rshin, D, true)
			end
			if move.at == 0 then
				move.at = rnd(4) < 3 and 1 or 3
			else
				move.at = rnd(4) < 3 and 3 or 1
			end
		else
			local swap = move.at == 3
			local thigh, shin, other, other_shin = pair(state, swap)
			local wait = 0
			if (other.d8 ~= 0.0 or other_shin.d8 ~= 0.0) and rnd(2) == 0 then
				zero(other, D, true)
				zero(other_shin, D, true)
				wait = D
			end
			local a, c = rnd(90), rnd(90)
			tween(thigh, D, wait, wait == 0, rnd(10) - 5, -(a - 30), swap and c or -c)
			tween(shin, D, wait, wait == 0, 0.0, a * math.random() * 2.0, 0.0)
			zero(thigh, D, false)
			zero(shin, D, false)
			move.at = swap and 1 or 3
		end
		move.count = move.count + 1
	end
	return false
end

local function legflail_start(move, state)
	local D = state.tempo
	local swap = rnd(2) == 0
	local thigh, shin, other, other_shin = pair(state, not swap)
	local a = rnd(135)
	zero(other, D, true)
	zero(other_shin, D, true)
	local side = rnd(90) - 20
	tween(thigh, D, 0, true, rnd(10) - 5, -a, swap and side or -side)
	tween(shin, D, 0, true, 0.0, math.random() * a, 0.0)
	zero(thigh, D, false)
	zero(shin, D, false)
	move.span = D * 3 // 4
end

local function arm_step(mirror)
	return function(_, state)
		local level = state.level
		if level > 3.0 then
			local b, D = state.body, state.tempo
			local third = D * 3 // 4
			local a = rnd(180)
			if level > 3.5 then
				local long = math.random() < 0.75
				local width = long and D or D * 2
				tween(b.rarm, width, 0, rnd(16) == 0, -a, a, rnd(100) + 80)
				local fold = rnd(180 - a)
				tween(b.rfore, third, 0, rnd(16) == 0, 0.0, fold, -90.0)
				if not mirror then
					a, long = rnd(180), math.random() < 0.75
					width = long and D or D * 2
					fold = rnd(math.max(180 - a, 1))
				end
				tween(b.larm, width, 0, rnd(16) == 0, a, a, -(rnd(100) + 80))
				tween(b.lfore, third, 0, rnd(16) == 0, 0.0, -fold, -90.0)
			else
				local fold = rnd(180 - a)
				tween(b.rfore, third, 0, rnd(16) == 0, 0.0, fold, -90.0)
				tween(b.lfore, third, 0, rnd(16) == 0, 0.0, -(mirror and fold or rnd(90)), -90.0)
			end
		end
		return false
	end
end

local function stand_start(_, state)
	local b = state.body
	zero(b.rthigh, 50, true)
	zero(b.lthigh, 50, true)
	zero(b.rshin, 50, true)
	zero(b.lshin, 50, true)
	tween(b.rarm, 50, 0, true, 0.0, 15.0, 90.0)
	tween(b.larm, 50, 0, true, 0.0, 15.0, -90.0)
	tween(b.rfore, 50, 0, true, 0.0, -5.0, 0.0)
	tween(b.lfore, 50, 0, true, 0.0, -5.0, 0.0)
	zero(b.hips, 50, true)
	zero(b.spine, 50, true)
	zero(b.head, 50, true)
end

local function backflail_step(move, state)
	if move.at < 1 and state.level > 2.5 then
		local b, D = state.body, state.tempo
		local function phase(total, clear)
			tween(b.spine, D, 0, clear, rnd(180) - 90, (rnd(240) + rnd(120) - 180) // 2, rnd(180) - 90)
			tween(b.hips, total, 0, clear, 0.0, round((math.random() - 0.5) * (rnd(240) + rnd(120) - 180)), 0.0)
		end
		phase(D * 3 // 2, true)
		phase(D // 2, false)
		move.at = 1
		move.count = move.count + 1
	end
	return false
end

local MOVES = {
	march = { flag = 1, step = march_like(0.0) },
	side = { flag = 1, step = march_like(45.0) },
	kick = { flag = 1, start = kick_start(false), step = counted },
	sexy = { flag = 1, start = kick_start(true), step = counted },
	spread = { flag = 1, start = spread_start, step = counted },
	kickback = { flag = 1, start = kickback_start, step = counted },
	cross = { flag = 1, start = cross_start, step = counted },
	footwork = { flag = 1, start = function(move)
		move.at = rnd(2) + 1
	end, step = footwork_step },
	legflail = { flag = 1, start = legflail_start, step = counted },
	arm = { flag = 4, step = arm_step(false) },
	sym = { flag = 4, step = arm_step(true) },
	stand = { flag = 7, start = stand_start, step = counted },
	back = { flag = 2, step = backflail_step },
}

local PICKS = { "spread", "spread", "cross", "kickback", "side", "side", "side", "march", "legflail", "legflail", "legflail", "footwork", "footwork", "footwork", "footwork", "footwork", "sexy", "sexy", "kick", "kick" }

local function begin(state, name)
	local kind = MOVES[name]
	local slots = state.slots
	for index = 1, 3 do
		if slots[index] and slots[index].name == name then
			return
		end
	end
	for index = 1, 3 do
		if slots[index] and (slots[index].kind.flag & kind.flag) ~= 0 then
			slots[index] = false
		end
	end
	for index = 1, 3 do
		if not slots[index] then
			local move = { name = name, kind = kind, at = 0, count = 0, span = 0 }
			if kind.start then
				kind.start(move, state)
			end
			slots[index] = move
			return
		end
	end
end

local function legs_free(state)
	for index = 1, 3 do
		local move = state.slots[index]
		if move and (move.kind.flag & 1) ~= 0 then
			return false
		end
	end
	return true
end

local function pick_legs(state)
	local level = state.level
	if state.hold < 1 or state.peak < level then
		state.peak = level
		state.hold = 15
		local choice
		if level >= 9.0 then
			choice = rnd(2) + 18
		elseif level >= 8.0 then
			choice = rnd(16) + 4
		elseif level >= 6.0 then
			choice = rnd(20)
		else
			choice = rnd(13)
		end
		begin(state, PICKS[choice + 1])
	else
		state.hold = state.hold - 1
	end
end

local function pick_arms(state)
	begin(state, rnd(10) < 4 and "arm" or "sym")
end

local function beat(state, audio)
	local rise = 0
	local last = state.previous
	for slot = 1, 128 do
		local value = bins.both(audio, slot * 8 - 4) // 2
		local before = last[slot] or value
		if before < value then
			rise = rise + 8 * ((value * 2 - before) // 2)
		end
		last[slot] = value
	end
	state.history[state.write] = rise
	state.write = state.write % 128 + 1
	local sum, count = 0, 0
	for _, value in ipairs(state.history) do
		if value > 0 then
			sum = sum + value
			count = count + 1
		end
	end
	state.average = count > 0 and sum / count or 1
	return rise
end

local function colors(state, audio, scene)
	local low, mid, high = 0.0, 0.0, 0.0
	for slot = 1, 64 do
		local value = bins.both(audio, slot * 16 - 8) * 16
		if slot <= 32 then
			low = low + value
		end
		if slot > 16 and slot <= 48 then
			mid = mid + value
		end
		if slot > 32 then
			high = high + value
		end
	end
	local band = state.band
	band[1] = (low / 1024 + band[1] * 255) / 256
	band[2] = (mid / 1024 + band[2] * 255) / 256
	band[3] = (high / 1024 + band[3] * 255) / 256
	local most = state.most
	for index = 1, 3 do
		if most[index] < band[index] then
			most[index] = band[index]
		end
	end
	local x1 = math.min(255, round(band[1] * 255 / most[1]))
	local x2 = math.min(255, round(band[2] * 255 / most[2]))
	local x3 = math.min(255, round(band[3] * 255 / most[3]))
	local r = round(x1 / 255 * 127) + 128
	local g = round((x2 / 255) ^ 2 * 255)
	local c = math.cos(math.pi * x3 / 255)
	local b = round(c * c * 255)
	scene.engine.set(scene, "main_color", Color(r, g, b, 0.0))
	scene.engine.set(scene, "dim_color", Color(r // 4, g // 8, b // 6, 0.0))
end

local function step(state, audio, scene)
	local rise = beat(state, audio)
	local level = rise / state.average
	state.level = level
	local target = math.max(25, (120000 - math.floor(state.average) * 8) // 1200)
	state.speed = (state.speed * 7 + target) // 8
	state.tempo = state.speed * 2
	if level > 7.5 then
		if state.kick > 0.25 then
			state.kick = level
		elseif state.kick < -0.25 then
			state.kick = -level
		elseif rnd(2) == 0 then
			state.kick = level / 2
		else
			state.kick = -level / 2
		end
	end
	if level > 5.0 and not state.idle then
		pick_arms(state)
	end
	if (level > 4.0 or legs_free(state)) and not state.idle then
		pick_legs(state)
	end
	if rise == 0 then
		if not state.idle then
			state.quiet = state.quiet + 1
			if state.quiet > 10 then
				begin(state, "stand")
				state.idle = true
				state.quiet = 0
			end
		else
			state.quiet = 0
		end
	else
		state.quiet = 0
		if state.idle then
			begin(state, "back")
			pick_legs(state)
			pick_arms(state)
			state.idle = false
		end
	end
	local body = state.body
	for _ = 1, SUBSTEPS do
		state.yaw = state.yaw + state.kick
		state.kick = state.kick * 199 / 200
		if state.yaw > 180 then
			state.yaw = state.yaw - 360
		elseif state.yaw < -180 then
			state.yaw = state.yaw + 360
		end
		state.yaw = state.yaw * 1023 / 1024
		for index = 1, 3 do
			local move = state.slots[index]
			if move and move.kind.step(move, state) then
				state.slots[index] = false
			end
		end
		for _, part in ipairs(body.parts) do
			advance(part)
		end
	end
	pose(state, body)
	feet_floor(state, body)
	state.tick = state.tick + SUBSTEPS
	local image = state.image
	for row, item in ipairs(state.blobs) do
		local m = item.part.m
		local y = row - 1
		image:set_pixel(0, y, Color(m[1], m[2], m[3], 0.0))
		image:set_pixel(1, y, Color(m[4], m[5], m[6], 0.0))
		image:set_pixel(2, y, Color(m[7], m[8], m[9], 0.0))
		image:set_pixel(3, y, Color(m[10], m[11], m[12], 0.0))
	end
	state.texture:update(image)
	state.material:set_shader_parameter("tick", state.tick)
	state.material:set_shader_parameter("floor_y", state.floor)
	colors(state, audio, scene)
end

local function setup(state, scene)
	state.body = build()
	state.slots = { false, false, false }
	state.level, state.peak, state.hold = 0.0, 0.0, 0
	state.idle, state.quiet = true, 0
	state.speed, state.tempo = 100, 200
	state.yaw, state.kick = 0.0, 0.0
	state.floor, state.fall = 1 / 60, 0.0
	state.previous, state.history, state.write, state.average = {}, {}, 1, 1
	state.band = { 0.0, 0.0, 0.0 }
	state.most = { 64.0, 16.0, 4.0 }
	state.tick = 0
	begin(state, "stand")
	local blobs = {}
	local function collect(part)
		for _, blob in ipairs(part.blobs) do
			blobs[#blobs + 1] = { part = part, data = blob }
		end
	end
	for _, part in ipairs(state.body.parts) do
		collect(part)
	end
	for _, part in ipairs(state.body.chain) do
		collect(part)
	end
	state.blobs = blobs
	local image = Image.create(6, #blobs, false, Image.FORMAT_RGBAF)
	for row, item in ipairs(blobs) do
		local d = item.data
		image:set_pixel(4, row - 1, Color(d[7], d[6], d[5], 0.0))
		image:set_pixel(5, row - 1, Color(d[4], d[3], d[2], 0.0))
	end
	state.image = image
	state.texture = ImageTexture.create_from_image(image)
	local total = 0
	for _, item in ipairs(blobs) do
		local n = item.data[1]
		item.count = n == 1 and 50 or n == 2 and 200 or item.data.vertebra and 10 or 100
		total = total + item.count
	end
	local mesh = QuadMesh.new()
	mesh.size = Vector2(1, 1)
	local many = MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_2D
	many.use_custom_data = true
	many.mesh = mesh
	many.instance_count = total * 3
	local index = 0
	for snapshot = 0, 2 do
		local serial = 0
		for row, item in ipairs(blobs) do
			for _ = 1, item.count do
				serial = serial + 1
				many:set_instance_custom_data(index, Color((row - 1) / 255.0, serial * 0.61803, (6 - snapshot * 3) / 255.0, 0.0))
				index = index + 1
			end
		end
	end
	state.many = many
	local material = ShaderMaterial.new()
	material.shader = nari.load(PARTICLE)
	material:set_shader_parameter("bones", state.texture)
	state.material = material
	scene.canvas.material = material
end

return {
	name = "Fire Dancer",
	presets = {
		{
			name = "Fire Dancer",
			feedback = FADE,
			display = PALETTE,
			filter = "nearest",
			size = { 320, 384 },
			aspect = 320 / 384,
			setup = setup,
			step = step,
			draw = function(canvas, state)
				canvas:draw_multimesh(state.many, nil)
			end,
		},
	},
}

local auth = require("auth")
local dealer = require("dealer")
local inflate = require("inflate")
local proto = require("proto")
local spotify = require("spotify")

local RESOLVE = "https://apresolve.spotify.com/?type=dealer"
local FALLBACK = "dealer.spotify.com:443"
local STATE = "/connect-state/v1"
local COMMANDS = "hm://connect-state/v1/player/command"
local PING = 30
local SILENCE = 80
local RETRIES = { 3, 10, 30, 60 }
local PUSH_DELAY = 0.25
local PUSH_RETRY = 5
local PUSH_RETRY_MAX = 60
local VOLUME_MAX = 65535
local VOLUME_STEPS = 64
local REASONS = { new = 3, state = 4, volume = 5, picker = 6 }
local PRIORITY = { [3] = 1, [4] = 2, [6] = 3, [5] = 4 }
local TYPES = { computer = 1, smartphone = 3 }
local KINDS = {
	[1] = "computer",
	[2] = "smartphone",
	[3] = "smartphone",
	[4] = "speaker",
	[5] = "tv",
	[6] = "speaker",
	[7] = "tv",
	[8] = "speaker",
	[9] = "tv",
	[10] = "tv",
	[11] = "speaker",
	[12] = "speaker",
	[13] = "smartphone",
	[14] = "computer",
}

local identity = { name = "Nari", kind = "computer" }
local player = { active = false, volume = 1 }
local wanted = false
local link, connection
local generation, failures, heard = 0, 0, 0
local push_queued, push_reason
local push_failures = 0
local last_command
local cluster = { active = "", devices = {}, state = {} }
local waiting = {}

local function bool(number, value)
	return proto.int(number, value and 1 or 0)
end

local function random_id(size)
	return proto.hex(nari.random_bytes(size))
end

local function capabilities()
	return bool(2, true) .. bool(5, true) .. bool(7, true) .. proto.int(8, VOLUME_STEPS)
		.. proto.bytes(9, "audio/track") .. bool(10, true) .. bool(15, true) .. bool(16, true)
		.. bool(19, true) .. bool(20, true) .. bool(23, true) .. bool(25, true)
end

local function device_info()
	return bool(1, true)
		.. proto.int(2, math.floor((player.volume or 1) * VOLUME_MAX + 0.5))
		.. proto.bytes(3, identity.name)
		.. proto.bytes(4, capabilities())
		.. proto.bytes(6, "Nari")
		.. proto.int(7, TYPES[identity.kind] or 1)
		.. proto.bytes(9, "3.2.6")
		.. proto.bytes(10, auth.device_id())
		.. proto.bytes(13, auth.CLIENT_ID)
		.. proto.bytes(14, "spotify")
		.. proto.bytes(15, "Nari")
		.. proto.bytes(23, "premium")
end

local function options()
	return bool(1, player.shuffle) .. bool(2, player.repeat_context) .. bool(3, player.repeat_track)
end

local function provided(track)
	return proto.bytes(1, track.uri) .. proto.bytes(2, track.uid or "") .. proto.bytes(6, "context")
end

local function player_state()
	if not player.active or not player.uri then
		return proto.int(1, player.timestamp or 0) .. proto.double(9, 1) .. proto.bytes(16, options())
			.. proto.bytes(5, "") .. proto.bytes(17, "") .. proto.bytes(18, "")
	end
	local context = player.context or player.uri
	local around = {}
	for _, track in ipairs(player.previous or {}) do
		table.insert(around, proto.bytes(19, provided(track)))
	end
	for _, track in ipairs(player.upcoming or {}) do
		table.insert(around, proto.bytes(20, provided(track)))
	end
	return proto.int(1, player.timestamp)
		.. proto.bytes(2, context)
		.. proto.bytes(3, "context://" .. context)
		.. proto.bytes(5, proto.bytes(1, "nari"))
		.. proto.bytes(6, proto.int(2, math.max(player.index or 0, 0)))
		.. proto.bytes(7, provided(player))
		.. proto.bytes(8, player.playback_id)
		.. proto.double(9, player.paused and 0 or 1)
		.. proto.int(10, player.position or 0)
		.. proto.int(11, player.duration or 0)
		.. bool(12, true)
		.. bool(13, player.paused)
		.. bool(14, player.buffering)
		.. proto.bytes(16, options())
		.. proto.bytes(17, "")
		.. proto.bytes(18, "")
		.. table.concat(around)
		.. proto.bytes(23, player.session)
end

local function put_request(reason)
	local body = proto.bytes(2, proto.bytes(1, device_info()) .. proto.bytes(2, player_state()))
		.. proto.int(3, 2)
		.. bool(4, player.active)
		.. proto.int(5, reason)
		.. proto.int(12, player.timestamp or os.time() * 1000)
	if player.active and player.since then
		body = body .. proto.int(9, player.since)
	end
	if last_command then
		body = body .. proto.bytes(7, last_command.from) .. proto.int(8, last_command.id)
	end
	return body
end

local function context_track(raw)
	local fields = proto.decode(raw or "")
	local uri = proto.path(fields, 1) or ""
	local gid = proto.path(fields, 3)
	if uri == "" and gid and #gid == 16 then
		uri = "spotify:track:" .. proto.base62(gid)
	end
	return uri
end

local function track_uris(list)
	local uris = {}
	for _, raw in ipairs(list) do
		local uri = context_track(raw)
		if uri:match("^spotify:track:") then
			table.insert(uris, uri)
		end
	end
	return uris
end

local function playback(fields)
	local options_of = proto.decode(proto.path(fields, 16) or "")
	return {
		previous = track_uris(proto.list(fields, 19)),
		upcoming = track_uris(proto.list(fields, 20)),
		uri = context_track(proto.path(fields, 7)),
		context = proto.path(fields, 2) or "",
		timestamp = proto.path(fields, 1) or 0,
		position = proto.path(fields, 10) or 0,
		duration = proto.path(fields, 11) or 0,
		speed = proto.number(proto.path(fields, 9)) or 0,
		playing = (proto.path(fields, 12) or 0) ~= 0,
		paused = (proto.path(fields, 13) or 0) ~= 0,
		buffering = (proto.path(fields, 14) or 0) ~= 0,
		shuffle = (proto.path(options_of, 1) or 0) ~= 0,
		repeat_context = (proto.path(options_of, 2) or 0) ~= 0,
		repeat_track = (proto.path(options_of, 3) or 0) ~= 0,
	}
end

local function devices_of(fields)
	local devices, me = {}, auth.device_id()
	for _, raw in ipairs(proto.list(fields, 4)) do
		local entry = proto.decode(raw)
		local id = proto.path(entry, 1)
		local info = proto.decode(proto.path(entry, 2) or "")
		local abilities = proto.decode(proto.path(info, 4) or "")
		local playable = (proto.path(abilities, 2) or 0) ~= 0 or (proto.path(info, 1) or 0) ~= 0
		if id and id ~= me and playable and (proto.path(abilities, 12) or 0) == 0 then
			table.insert(devices, {
				id = id,
				name = proto.path(info, 3) or "Spotify device",
				kind = KINDS[proto.path(info, 7) or 0] or "speaker",
				volume = (proto.path(info, 2) or 0) / VOLUME_MAX,
			})
		end
	end
	return devices
end

local function apply(fields)
	cluster = {
		active = proto.path(fields, 2) or "",
		devices = devices_of(fields),
		state = playback(proto.decode(proto.path(fields, 3) or "")),
	}
	nari.send({ connect = "cluster", cluster = cluster })
end

local function answer_waiting(problem)
	local list = waiting
	waiting = {}
	for _, request in ipairs(list) do
		nari.send({ request = request, error = problem, devices = cluster.devices, active = cluster.active })
	end
end

local function headers()
	return {
		["X-Spotify-Connection-Id"] = connection,
		["Content-Type"] = "application/x-protobuf",
		Accept = "application/x-protobuf",
	}
end

local schedule

local function push(reason)
	if not connection then
		return false
	end
	local ok, body = pcall(spotify.request, "PUT", STATE .. "/devices/" .. auth.device_id(), put_request(reason), headers())
	if not ok then
		push_failures = push_failures + 1
		if push_failures == 1 then
			nari.log("Spotify Connect couldn't share Nari's state: " .. tostring(body))
		end
		nari.after(math.min(PUSH_RETRY * 2 ^ (push_failures - 1), PUSH_RETRY_MAX), function()
			if connection then
				schedule(reason)
			end
		end)
		return false
	end
	push_failures = 0
	if body ~= "" then
		apply(proto.decode(body))
	end
	return true
end

function schedule(reason)
	if not push_reason or PRIORITY[reason] < PRIORITY[push_reason] then
		push_reason = reason
	end
	if push_queued then
		return
	end
	push_queued = true
	nari.after(PUSH_DELAY, function()
		push_queued = false
		local chosen = push_reason
		push_reason = nil
		push(chosen)
	end)
end

local function inactive()
	if connection then
		pcall(spotify.request, "PUT", STATE .. "/devices/" .. auth.device_id() .. "/inactive?notify=true", nil, { ["X-Spotify-Connection-Id"] = connection })
	end
end

local function decoded(raw, encoding)
	local data = nari.base64_decode(raw)
	if encoding == "gzip" or data:sub(1, 2) == "\31\139" then
		data = inflate.gunzip(data)
	end
	return data
end

local function transfer_state(data)
	local state = proto.decode(data)
	local options_of = proto.decode(proto.path(state, 1) or "")
	local current = proto.decode(proto.path(state, 2) or "")
	local session = proto.decode(proto.path(state, 3) or "")
	local context = proto.decode(proto.path(session, 2) or "")
	local tracks, queue = {}, {}
	for _, page in ipairs(proto.list(context, 5)) do
		for _, raw in ipairs(proto.list(proto.decode(page), 4)) do
			table.insert(tracks, context_track(raw))
		end
	end
	for _, raw in ipairs(proto.list(proto.decode(proto.path(state, 4) or ""), 1)) do
		table.insert(queue, context_track(raw))
	end
	return {
		uri = context_track(proto.path(current, 5)),
		timestamp = proto.path(current, 1) or 0,
		position = proto.path(current, 2) or 0,
		paused = (proto.path(current, 4) or 0) ~= 0,
		context = proto.path(context, 1) or "",
		session = proto.path(session, 9),
		tracks = tracks,
		queue = queue,
		shuffle = (proto.path(options_of, 1) or 0) ~= 0,
		repeat_context = (proto.path(options_of, 2) or 0) ~= 0,
		repeat_track = (proto.path(options_of, 3) or 0) ~= 0,
	}
end

local function on_request(message)
	local headers_of = message.headers or {}
	local ok, payload = pcall(function()
		return nari.json_decode(decoded(message.payload and message.payload.compressed or "", headers_of["Transfer-Encoding"]))
	end)
	if not ok or type(payload) ~= "table" then
		nari.log("Spotify Connect sent a command Nari couldn't read: " .. tostring(payload))
	end
	link:send(nari.json_encode({ type = "reply", key = message.key, payload = { success = ok } }))
	if not ok or message.message_ident ~= COMMANDS or type(payload.command) ~= "table" then
		return
	end
	local command = payload.command
	last_command = { id = math.floor(tonumber(payload.message_id) or 0), from = tostring(payload.sent_by_device_id or "") }
	if command.endpoint == "transfer" and type(command.data) == "string" then
		local parsed, state = pcall(transfer_state, nari.base64_decode(command.data))
		command.transfer = parsed and state or nil
	end
	command.data = nil
	nari.send({ connect = "command", command = command, from = last_command.from })
end

local function on_message(text)
	heard = os.time()
	local ok, message = pcall(nari.json_decode, text)
	if not ok or type(message) ~= "table" then
		return
	end
	if message.type == "request" then
		return on_request(message)
	elseif message.type ~= "message" then
		return
	end
	local uri = message.uri or ""
	local headers_of = message.headers or {}
	local payload = message.payloads and message.payloads[1]
	if uri:find("^hm://pusher/v1/connections/") then
		connection = headers_of["Spotify-Connection-Id"]
		push(REASONS.new)
		answer_waiting()
		nari.send({ connect = "online", id = auth.device_id() })
	elseif type(payload) == "string" and uri:find("^hm://connect%-state/v1/cluster") then
		local parsed, update = pcall(function() return proto.decode(decoded(payload, headers_of["Transfer-Encoding"])) end)
		local fields = parsed and proto.path(update, 1)
		if fields then
			apply(proto.decode(fields))
		end
	elseif type(payload) == "string" and uri:find("^hm://connect%-state/v1/connect/volume") then
		local parsed, command = pcall(function() return proto.decode(decoded(payload, headers_of["Transfer-Encoding"])) end)
		if parsed then
			nari.send({ connect = "volume", volume = (proto.path(command, 1) or 0) / VOLUME_MAX })
		end
	end
end

local function address()
	local response = nari.http({ url = RESOLVE })
	local list = response and response.status == 200 and auth.decode(response).dealer or {}
	return list[1] or FALLBACK
end

local open

local function lost(problem)
	link, connection = nil, nil
	nari.send({ connect = "offline" })
	answer_waiting("Spotify Connect is offline right now")
	if not wanted then
		return
	end
	failures = failures + 1
	if failures == 1 then
		nari.log("Spotify Connect disconnected: " .. tostring(problem))
	end
	local current = generation
	nari.after(RETRIES[math.min(failures, #RETRIES)], function()
		if current == generation then
			open()
		end
	end)
end

local function watch(current)
	nari.after(PING, function()
		if current ~= generation or not link then
			return
		end
		if os.time() - heard > SILENCE then
			link:close()
			return lost("the dealer stopped answering")
		end
		link:send('{"type":"ping"}')
		watch(current)
	end)
end

function open()
	if link or not wanted then
		return
	end
	generation = generation + 1
	local current = generation
	local token, problem = auth.token()
	if not token then
		return lost(problem)
	end
	local opened, failure = dealer.open(address(), token, {
		message = function(text)
			if current == generation then
				on_message(text)
			end
		end,
		close = function(reason)
			if current == generation then
				lost(reason)
			end
		end,
	})
	if not opened then
		return lost(failure)
	end
	link, failures, heard = opened, 0, os.time()
	watch(current)
end

local function close()
	generation = generation + 1
	if link then
		if player.active then
			inactive()
		end
		link:close()
	end
	link, connection = nil, nil
end

local actions = {}

function actions.start(message)
	identity = message.identity or identity
	wanted = true
	open()
	return {}
end

function actions.stop()
	wanted = false
	close()
	player = { active = false, volume = player.volume }
	return {}
end

function actions.state(message)
	local state = message.state
	local was = player.active
	if state.uri ~= player.uri then
		state.playback_id = random_id(16)
	else
		state.playback_id = player.playback_id
	end
	state.session = state.session or was and player.session or random_id(16)
	state.since = was and player.since or state.timestamp
	player = state
	if was and not state.active then
		inactive()
	elseif state.active or message.reason == "volume" then
		schedule(REASONS[message.reason] or REASONS.state)
	end
end

function actions.devices(message)
	if not connection then
		if not wanted then
			error("Spotify Connect is off", 0)
		end
		table.insert(waiting, message.request)
		open()
		return nil
	end
	push(REASONS.picker)
	return { devices = cluster.devices, active = cluster.active }
end

nari.on("message", function(message)
	local handler = actions[message.action]
	if not handler then
		return
	end
	local ok, result = pcall(handler, message)
	if not message.request then
		if not ok then
			nari.log("Spotify Connect " .. message.action .. " failed: " .. tostring(result))
		end
		return
	end
	if ok and result == nil then
		return
	end
	result = ok and result or { error = tostring(result) }
	result.request = message.request
	nari.send(result)
end)

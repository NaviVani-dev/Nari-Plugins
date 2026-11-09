local narration = require("narration")
local queue = require("queue")

local SYNC = 1
local SEEK_SLACK = 2500
local FOLLOW_SLACK = 3500
local QUIET_COMMAND = 2500
local QUIET_TRACK = 6000
local SETTLE = 0.3
local RETRY = 0.25
local RETRIES = 20
local BUSY_LIMIT = 10
local NATURAL_END = 4000
local SHARED_PREVIOUS = 20
local SHARED_NEXT = 80
local CONTEXT_LIMIT = 500
local REPEAT = { off = 0, all = 1, one = 2 }

local remote = {}

local function now()
	return math.floor(Time:get_unix_time_from_system() * 1000)
end

local function ticks()
	return Time:get_ticks_msec()
end

local function uri_of(id)
	return "spotify:track:" .. tostring(id)
end

local function repeat_of(context, track)
	return track and REPEAT.one or context and REPEAT.all or REPEAT.off
end

local function set_repeat(context, track)
	local mode = repeat_of(context, track)
	if MediaPlayer:get_repeat() ~= mode then
		MediaPlayer["repeat"](MediaPlayer, mode)
	end
end

local queue_index = queue.index
local with_queue = queue.read

local function is_line(id)
	return tostring(id):sub(1, #narration.PREFIX) == narration.PREFIX
end

local function queue_uris(songs)
	local uris = {}
	for _, song in ipairs(songs) do
		table.insert(uris, uri_of(song.id))
	end
	return uris
end

local function slice(list, from, to)
	local part = {}
	for index = math.max(from, 1), math.min(to, #list) do
		table.insert(part, list[index])
	end
	return part
end

local function starts_with(list, prefix)
	for index = 1, math.min(#list, #prefix) do
		if list[index] ~= prefix[index] then
			return false
		end
	end
	return true
end

local function track_list(raw)
	local uris = {}
	for _, track in ipairs(type(raw) == "table" and raw or {}) do
		if type(track) == "table" and type(track.uri) == "string" and track.uri:match("^spotify:track:") then
			table.insert(uris, track)
		end
	end
	return uris
end

function remote.start(host)
	local thread = nari.thread("connect.lua")
	local relay_thread = nari.thread("relay.lua")
	local pending, requests = {}, 0
	local me = ""
	local cluster = { active = "", devices = {}, state = {} }
	local player = { active = false, since = 0, held = false }
	local starting
	local link
	local output
	local tracker = { position = 0, duration = 0, at = 0, running = false }
	local shared = ""
	local push_queued = false

	local function call(message, handler, target)
		if handler then
			requests = requests + 1
			message.request = requests
			pending[requests] = handler
		end
		(target or thread):send(message)
	end

	local function relay(message, handler)
		call(message, handler or function(answer)
			if answer.error then
				nari.log("Spotify Connect " .. message.action .. " failed: " .. answer.error)
			end
		end, relay_thread)
	end

	local function spotify_song()
		local song = nari.current()
		if song and MediaPlayer.provider and MediaPlayer.provider.id == host.id and (tostring(song.id):match("^%w+$") or is_line(song.id)) then
			return song
		end
	end

	local function current_uri()
		local song = spotify_song()
		return song and uri_of(song.id) or ""
	end

	local function mark()
		tracker.position, tracker.at, tracker.running = MediaPlayer:get_position(), ticks(), MediaPlayer:is_playing()
		tracker.duration = MediaPlayer:get_duration()
	end

	local function jumped()
		local expected = tracker.position + (tracker.running and ticks() - tracker.at or 0)
		return math.abs(MediaPlayer:get_position() - expected) > SEEK_SLACK
	end

	local function near_end()
		return tracker.duration > 0 and tracker.position >= tracker.duration - NATURAL_END
	end

	local function publish(reason)
		with_queue(function(songs)
			local index = queue_index()
			local song = spotify_song() and songs[index + 1] or spotify_song()
			local uris = queue_uris(songs)
			local previous, upcoming = {}, {}
			for position = math.max(0, index - SHARED_PREVIOUS), index - 1 do
				if not is_line(songs[position + 1].id) then
					table.insert(previous, { uri = uris[position + 1], uid = "nari" .. position })
				end
			end
			for position = index + 1, math.min(#uris - 1, index + SHARED_NEXT) do
				if not is_line(songs[position + 1].id) then
					table.insert(upcoming, { uri = uris[position + 1], uid = "nari" .. position })
				end
			end
			local uri = song and uri_of(song.id)
			local talking = song and is_line(song.id)
			if talking then
				uri = upcoming[1] and table.remove(upcoming, 1).uri or previous[#previous] and previous[#previous].uri
			end
			local repeat_mode = MediaPlayer:get_repeat()
			local duration = MediaPlayer:get_duration()
			call({ action = "state", reason = reason or "state", state = {
				active = player.active and uri ~= nil and not link,
				session = player.session,
				uri = uri,
				context = song and host.dj().owns(song.id) and narration.CONTEXT or nil,
				uid = "nari" .. index,
				index = index,
				previous = previous,
				upcoming = upcoming,
				duration = not talking and duration > 0 and duration or (song and not talking and song.duration) or 0,
				position = talking and 0 or MediaPlayer:get_position(),
				timestamp = now(),
				paused = not MediaPlayer:is_playing(),
				volume = SettingsManager.playback.volume,
				shuffle = MediaPlayer:is_shuffled(),
				repeat_context = repeat_mode == REPEAT.all,
				repeat_track = repeat_mode == REPEAT.one,
			} })
		end)
	end

	local queue_body

	local function activate(claiming)
		if not player.active then
			player.active, player.since, player.held, player.taken, player.session = true, now(), false, nil, nil
			if claiming and cluster.active ~= "" and cluster.active ~= me and me ~= "" then
				queue_body(function(body)
					if body then
						relay({ action = "command", to = me, command = body })
					end
				end)
			end
		end
	end

	local function deactivate()
		if player.active then
			player.active, player.held = false, false
			publish()
		end
	end

	local function device(id)
		for _, entry in ipairs(cluster.devices) do
			if entry.id == id then
				return entry
			end
		end
	end

	local function remote_position(state)
		local position = state.position or 0
		if state.playing and not state.paused then
			position = position + math.max(0, now() - (state.timestamp or now())) * (state.speed > 0 and state.speed or 1)
		end
		return math.floor(position)
	end

	local function remote_repeat(state)
		return repeat_of(state.repeat_context, state.repeat_track)
	end

	local function command(session, body, quiet, done)
		session.quiet = ticks() + (quiet or QUIET_COMMAND)
		relay({ action = "command", to = session.device.id, command = body }, function(message)
			if message.error then
				nari.log("Spotify Connect on " .. session.device.name .. " failed: " .. message.error)
			end
			if done then
				done(message.error)
			end
		end)
	end

	local function with_provider()
		if not MediaPlayer.provider or MediaPlayer.provider.id ~= host.id then
			MediaPlayer:use_provider(host.id)
		end
	end

	local function load(spec, done)
		local function finish(message)
			if message.error then
				nari.log("Spotify Connect couldn't load what to play: " .. message.error)
				return done({})
			end
			host.remember(message.tracks or {})
			done(message.tracks or {})
		end
		if spec.uris and #spec.uris > 0 then
			host.ask({ action = "tracks", uris = spec.uris }, finish)
		elseif spec.context and spec.context:match(":collection$") then
			done(host.liked())
		elseif spec.context and spec.context ~= "" then
			host.ask({ action = "context", uri = spec.context }, finish)
		elseif spec.uri and spec.uri ~= "" then
			host.ask({ action = "tracks", uris = { spec.uri } }, finish)
		else
			done({})
		end
	end

	local function arrange(target, done, attempt)
		with_queue(function(songs)
			local index = queue_index()
			local uris = queue_uris(songs)
			local left = {}
			for _, uri in ipairs(target) do
				left[uri] = (left[uri] or 0) + 1
			end
			local kept, removals = {}, {}
			for position = index + 2, #uris do
				local uri = uris[position]
				if (left[uri] or 0) > 0 then
					left[uri] = left[uri] - 1
					table.insert(kept, uri)
				else
					table.insert(removals, position - 1)
				end
			end
			for at = #removals, 1, -1 do
				MediaPlayer:remove_from_queue(removals[at])
			end
			local missing = {}
			for uri, count in pairs(left) do
				for _ = 1, count do
					table.insert(missing, uri)
				end
			end
			if #missing > 0 then
				if (attempt or 0) >= RETRIES then
					return done()
				end
				if attempt == nil then
					load({ uris = missing }, function(tracks) MediaPlayer:queue_tracks(tracks) end)
				end
				return nari.after(RETRY, function() arrange(target, done, (attempt or 0) + 1) end)
			end
			for position, uri in ipairs(target) do
				if kept[position] ~= uri then
					for from = position + 1, #kept do
						if kept[from] == uri then
							MediaPlayer:move_in_queue(index + from, index + position)
							table.insert(kept, position, table.remove(kept, from))
							break
						end
					end
				end
			end
			done()
		end)
	end

	local function start(tracks, uri, plan)
		if #tracks == 0 then
			return nari.log("Spotify Connect asked Nari to play something it couldn't find")
		end
		with_provider()
		local chosen = tracks[1].id
		for _, track in ipairs(tracks) do
			if uri_of(track.id) == uri then
				chosen = track.id
				break
			end
		end
		plan.id = chosen
		starting = plan
		MediaPlayer:play_tracks(tracks, chosen, false)
	end

	local function play_here(spec)
		if link then
			link = nil
			output:release()
		end
		activate()
		set_repeat(spec.repeat_context, spec.repeat_track)
		local plan = { position = spec.position, paused = spec.paused, shuffle = spec.shuffle }
		load(spec, function(tracks)
			local function begin(list)
				start(list, spec.uri, plan)
				if spec.loaded then
					spec.loaded(list)
				end
			end
			for _, track in ipairs(tracks) do
				if uri_of(track.id) == spec.uri or not spec.uri or spec.uri == "" then
					return begin(tracks)
				end
			end
			load({ uri = spec.uri }, function(single)
				for _, track in ipairs(tracks) do
					table.insert(single, track)
				end
				begin(single)
			end)
		end)
	end

	local function busy(session)
		local token = {}
		session.busy = token
		nari.after(BUSY_LIMIT, function()
			if session.busy == token then
				session.busy = nil
			end
		end)
		return function()
			if session.busy == token then
				nari.after(SETTLE, function()
					if session.busy == token then
						session.busy = nil
					end
				end)
			end
		end
	end

	local function shape(session, state, finish)
		if MediaPlayer:is_shuffled() ~= state.shuffle then
			MediaPlayer:shuffle(state.shuffle)
		end
		set_repeat(state.repeat_context, state.repeat_track)
		with_queue(function(songs)
			local upcoming = slice(queue_uris(songs), queue_index() + 2, math.huge)
			if #state.upcoming == 0 or starts_with(upcoming, state.upcoming) and #upcoming >= #state.upcoming then
				return finish()
			end
			arrange(state.upcoming, finish)
		end)
	end

	local function mirror(session, state)
		local finish = busy(session)
		local uris = {}
		for _, list in ipairs({ state.previous, { state.uri }, state.upcoming }) do
			for _, uri in ipairs(list) do
				table.insert(uris, uri)
			end
		end
		load({ uris = uris }, function(tracks)
			if link ~= session or not tracks[1] then
				return finish()
			end
			session.playing = state.playing and not state.paused
			start(tracks, state.uri, {
				position = remote_position(state),
				paused = not session.playing,
				owner = session,
				after = function() shape(session, state, finish) end,
			})
		end)
	end

	local function follow(session)
		local state = cluster.state
		if not device(session.device.id) then
			link = nil
			output:release()
			if MediaPlayer:is_playing() then
				MediaPlayer:toggle()
			end
			return Snackbar.post(session.device.name .. " isn't available", "Nari stopped playing on it")
		end
		if cluster.active ~= session.device.id then
			local moved = device(cluster.active)
			if moved then
				session.device = moved
			end
			return
		end
		local settled = not session.busy and not push_queued and ticks() >= (session.quiet or 0)
		if state.context == narration.CONTEXT then
			host.dj().follow(state, settled)
		end
		if not settled or not state.uri:match("^spotify:track:") then
			return
		end
		if state.uri ~= current_uri() then
			return with_queue(function(songs)
				for position, uri in ipairs(queue_uris(songs)) do
					if uri == state.uri then
						local finish = busy(session)
						session.playing = state.playing and not state.paused
						starting = { id = songs[position].id, position = remote_position(state), paused = not session.playing, owner = session, after = finish }
						return MediaPlayer:skip_to_queue_index(position - 1)
					end
				end
				mirror(session, state)
			end)
		end
		local playing = state.playing and not state.paused
		if playing ~= MediaPlayer:is_playing() then
			session.playing = playing
			if playing then
				MediaPlayer:play()
			else
				MediaPlayer:toggle()
			end
		end
		local position = remote_position(state)
		if math.abs(position - MediaPlayer:get_position()) > FOLLOW_SLACK then
			MediaPlayer:seek(position)
		end
		mark()
		if MediaPlayer:is_shuffled() ~= state.shuffle or MediaPlayer:get_repeat() ~= remote_repeat(state) then
			return shape(session, state, busy(session))
		end
		with_queue(function(songs)
			local upcoming = slice(queue_uris(songs), queue_index() + 2, math.huge)
			if #state.upcoming > 0 and not (starts_with(upcoming, state.upcoming) and #upcoming >= #state.upcoming) then
				arrange(state.upcoming, busy(session))
			end
		end)
	end

	function queue_body(done)
		with_queue(function(songs)
			local song = spotify_song()
			if not song or is_line(song.id) then
				return done(nil)
			end
			local current = queue_index() + 1
			local from = math.max(1, current - SHARED_PREVIOUS)
			local tracks, skip = {}, 0
			for position = from, #songs do
				if #tracks >= CONTEXT_LIMIT then
					break
				end
				if position == current then
					skip = #tracks
				end
				if not is_line(songs[position].id) then
					table.insert(tracks, { uri = uri_of(songs[position].id) })
				end
			end
			if not songs[current] or songs[current].id ~= song.id then
				tracks, skip = { { uri = uri_of(song.id) } }, 0
			end
			local repeat_mode = MediaPlayer:get_repeat()
			done({
				endpoint = "play",
				context = { pages = { { tracks = tracks } } },
				play_origin = { feature_identifier = "nari" },
				options = {
					skip_to = { track_index = skip, track_uri = uri_of(song.id) },
					seek_to = math.max(0, MediaPlayer:get_position()),
					initially_paused = not MediaPlayer:is_playing(),
					player_options_override = {
						shuffling_context = MediaPlayer:is_shuffled(),
						repeating_context = repeat_mode == REPEAT.all,
						repeating_track = repeat_mode == REPEAT.one,
					},
				},
			})
		end)
	end

	local function send_queue(session, done)
		queue_body(function(body)
			if not body then
				return done and done()
			end
			mark()
			session.song, session.playing = spotify_song().id, MediaPlayer:is_playing()
			command(session, body, QUIET_TRACK, done)
		end)
	end

	local function push_link(session)
		if link ~= session or session.busy then
			return
		end
		local natural = session.natural
		session.natural = false
		with_queue(function(songs)
			local state = cluster.state
			local uri = current_uri()
			if link ~= session or session.busy or uri == "" or is_line(spotify_song().id) then
				return
			end
			if MediaPlayer:is_shuffled() ~= state.shuffle then
				command(session, { endpoint = "set_shuffling_context", value = MediaPlayer:is_shuffled() })
			end
			local repeat_mode = MediaPlayer:get_repeat()
			if repeat_mode ~= remote_repeat(state) then
				command(session, { endpoint = "set_repeating_context", value = repeat_mode ~= REPEAT.off })
				command(session, { endpoint = "set_repeating_track", value = repeat_mode == REPEAT.one })
			end
			local upcoming = slice(queue_uris(songs), queue_index() + 2, math.huge)
			local matches = function(list) return #list == 0 or starts_with(upcoming, list) and #upcoming >= #list end
			if uri == state.uri then
				if not matches(state.upcoming) then
					send_queue(session)
				end
			elseif uri == state.upcoming[1] and matches(slice(state.upcoming, 2, math.huge)) then
				session.song = spotify_song().id
				if natural then
					session.quiet = ticks() + QUIET_TRACK
				else
					command(session, { endpoint = "skip_next" }, QUIET_TRACK)
				end
			elseif uri == state.previous[#state.previous] then
				session.song = spotify_song().id
				command(session, { endpoint = "skip_prev", options = { allow_seeking = false } }, QUIET_TRACK)
			else
				send_queue(session)
			end
		end)
	end

	local function schedule_push()
		if push_queued or not link then
			return
		end
		push_queued = true
		local session = link
		nari.after(SETTLE, function()
			push_queued = false
			push_link(session)
		end)
	end

	local function taken_over()
		local song = spotify_song()
		player.active, player.held = false, false
		player.taken = song and { device = cluster.active, song = song.id } or nil
		publish()
		if MediaPlayer:is_playing() then
			MediaPlayer:toggle()
		end
		local other = device(cluster.active)
		if other then
			Snackbar.post("Playing on " .. other.name, "Choose it in Play on to control it from Nari")
		end
	end

	local function reclaim()
		local taken = player.taken
		player.taken = nil
		local song = spotify_song()
		if player.active or not taken or not song or song.id ~= taken.song or cluster.active ~= taken.device then
			return false
		end
		MediaPlayer:toggle()
		relay({ action = "transfer", from = taken.device, to = me, resume = true }, function(message)
			if message.error then
				nari.log("Spotify Connect couldn't bring the playback back: " .. message.error)
				MediaPlayer:play()
			end
		end)
		return true
	end

	local function on_cluster(update)
		cluster = update
		if link then
			return follow(link)
		end
		if cluster.active == me and me ~= "" then
			player.held = true
		elseif player.active and player.held and cluster.active ~= "" then
			taken_over()
		end
	end

	local function seek_target(command_of)
		local position = tonumber(command_of.position) or 0
		if command_of.relative == "current" then
			return MediaPlayer:get_position() + position
		elseif command_of.relative == "beginning" then
			return position
		end
		return tonumber(command_of.value) or position
	end

	local function find_in_queue(track, done)
		local uid = type(track) == "table" and tostring(track.uid or "") or ""
		local position = tonumber(uid:match("^nari(%d+)$"))
		with_queue(function(songs)
			local uris = queue_uris(songs)
			if position and track.uri and uris[position + 1] == track.uri then
				return done(position)
			end
			for at = queue_index() + 2, #uris do
				if uris[at] == track.uri then
					return done(at - 1)
				end
			end
			done(nil)
		end)
	end

	local function overrides(options)
		local override = type(options.player_options_override) == "table" and options.player_options_override or {}
		return override.shuffling_context, override.repeating_context, override.repeating_track
	end

	local function on_command(command_of, from)
		local endpoint = command_of.endpoint
		if (from == me or from == "local") and endpoint == "play" then
			activate()
			return publish()
		end
		local options = type(command_of.options) == "table" and command_of.options or {}
		if endpoint == "transfer" then
			local state = command_of.transfer
			if not state then
				return activate()
			end
			local paused = options.restore_paused == "pause" or state.paused and options.restore_paused ~= "resume"
			local position = state.position + (state.paused and 0 or math.max(0, now() - state.timestamp))
			if not link and state.uri == current_uri() then
				activate()
				player.session = state.session
				if state.context == narration.CONTEXT then
					host.dj().continue({ spotify_song().id })
				end
				MediaPlayer:seek(math.max(0, math.floor(position)))
				if paused == MediaPlayer:is_playing() then
					MediaPlayer:toggle()
				end
				mark()
				return publish()
			end
			local continuing = state.context == narration.CONTEXT
			player.session = nil
			activate()
			player.session = state.session
			return play_here({
				context = not continuing and state.context or nil,
				loaded = continuing and function(tracks)
					local ids = {}
					for _, track in ipairs(tracks) do
						table.insert(ids, track.id)
					end
					host.dj().continue(ids)
				end or nil,
				uri = state.uri,
				uris = #state.tracks > 0 and state.tracks or { state.uri },
				position = position,
				paused = paused,
				shuffle = state.shuffle,
				repeat_context = state.repeat_context,
				repeat_track = state.repeat_track,
			})
		elseif endpoint == "play" then
			local context = type(command_of.context) == "table" and command_of.context or {}
			if context.uri == narration.CONTEXT then
				if link then
					link = nil
					output:release()
				end
				activate()
				return host.dj().play()
			end
			local skip = type(options.skip_to) == "table" and options.skip_to or {}
			local uris = {}
			for _, page in ipairs(type(context.pages) == "table" and context.pages or {}) do
				for _, track in ipairs(track_list(page.tracks)) do
					table.insert(uris, track.uri)
				end
			end
			local uri = skip.track_uri
			if (not uri or uri == "") and tonumber(skip.track_index) then
				uri = uris[math.floor(skip.track_index) + 1]
			end
			local shuffle, repeat_context, repeat_track = overrides(options)
			return play_here({
				uri = uri,
				context = context.uri,
				uris = #uris > 0 and uris or nil,
				position = tonumber(options.seek_to) or 0,
				paused = options.initially_paused == true,
				shuffle = shuffle == nil and MediaPlayer:is_shuffled() or shuffle == true,
				repeat_context = repeat_context == nil and MediaPlayer:get_repeat() == REPEAT.all or repeat_context == true,
				repeat_track = repeat_track == nil and MediaPlayer:get_repeat() == REPEAT.one or repeat_track == true,
			})
		end
		if link then
			return
		end
		activate()
		if endpoint == "pause" then
			if MediaPlayer:is_playing() then
				MediaPlayer:toggle()
			end
		elseif endpoint == "resume" then
			if not MediaPlayer:is_playing() then
				MediaPlayer:play()
			end
		elseif endpoint == "seek_to" then
			MediaPlayer:seek(math.max(0, math.floor(seek_target(command_of))))
			mark()
		elseif endpoint == "skip_next" then
			if type(command_of.track) == "table" and command_of.track.uri then
				find_in_queue(command_of.track, function(position)
					if position then
						MediaPlayer:skip_to_queue_index(position)
					else
						MediaPlayer:next()
					end
				end)
			else
				MediaPlayer:next()
			end
		elseif endpoint == "skip_prev" then
			MediaPlayer:previous()
		elseif endpoint == "set_shuffling_context" then
			MediaPlayer:shuffle(command_of.value == true)
		elseif endpoint == "set_repeating_context" then
			set_repeat(command_of.value == true, MediaPlayer:get_repeat() == REPEAT.one and command_of.value == true)
		elseif endpoint == "set_repeating_track" then
			set_repeat(MediaPlayer:get_repeat() ~= REPEAT.off, command_of.value == true)
		elseif endpoint == "set_options" then
			if command_of.shuffling_context ~= nil then
				MediaPlayer:shuffle(command_of.shuffling_context == true)
			end
			if command_of.repeating_context ~= nil or command_of.repeating_track ~= nil then
				set_repeat(command_of.repeating_context == true, command_of.repeating_track == true)
			end
		elseif endpoint == "set_queue" then
			with_queue(function(songs)
				local target = {}
				for _, track in ipairs(track_list(command_of.next_tracks)) do
					table.insert(target, track.uri)
				end
				local uris = queue_uris(songs)
				for position = queue_index() + 2 + SHARED_NEXT, #uris do
					table.insert(target, uris[position])
				end
				arrange(target, function() publish() end)
			end)
		elseif endpoint == "add_to_queue" then
			local track = type(command_of.track) == "table" and command_of.track.uri
			if track then
				load({ uri = track }, function(tracks) MediaPlayer:queue_tracks(tracks) end)
			end
		end
	end

	thread:on_error(function(problem) nari.log("the Spotify Connect thread stopped: " .. problem) end)
	relay_thread:on_error(function(problem) nari.log("the Spotify Connect relay stopped: " .. problem) end)
	relay_thread:on_message(function(message)
		local handler = pending[message.request]
		pending[message.request] = nil
		if handler then
			handler(message)
		end
	end)
	thread:on_message(function(message)
		if message.request then
			local handler = pending[message.request]
			pending[message.request] = nil
			return handler and handler(message)
		end
		if message.connect == "online" then
			me = message.id
			publish()
		elseif message.connect == "cluster" then
			on_cluster(message.cluster)
		elseif message.connect == "command" then
			on_command(message.command, message.from)
		elseif message.connect == "volume" and not link then
			MediaPlayer:set_volume(message.volume)
		end
	end)

	local function tick()
		local song = spotify_song()
		if link and song and not is_line(song.id) and not link.busy and ticks() >= (link.quiet or 0) and jumped() then
			command(link, { endpoint = "seek_to", value = MediaPlayer:get_position() })
		elseif link then
			follow(link)
		elseif player.active and jumped() then
			publish()
		end
		mark()
		nari.after(SYNC, tick)
	end

	if nari.output then
		output = nari.output({
			id = "connect",
			scan = function(done)
				call({ action = "devices" }, function(message)
					if message.error then
						nari.log("finding Spotify Connect devices failed: " .. message.error)
					end
					done(message.devices or {})
				end)
			end,
			connect = function(chosen, done)
				local session = { device = chosen }
				link = session
				local was_active = player.active
				player.active, player.held = false, false
				if was_active then
					publish()
				end
				local state = cluster.state
				local joining = cluster.active == chosen.id and state.uri ~= "" and (state.playing and not state.paused or not spotify_song())
				if joining or not spotify_song() then
					done(true)
					return follow(session)
				end
				send_queue(session, function(problem)
					if link ~= session then
						return
					end
					if problem then
						link = nil
						return done("Nari couldn't play on " .. chosen.name .. ": " .. problem)
					end
					done(true)
				end)
			end,
			disconnect = function()
				local session = link
				link = nil
				if session then
					command(session, { endpoint = "pause" })
				end
				if MediaPlayer:is_playing() and spotify_song() then
					activate()
					publish()
				end
			end,
			volume = function(level)
				if link then
					relay({ action = "volume", to = link.device.id, volume = level })
				end
			end,
		})
	end

	nari.on("track", function(song)
		if starting and song and song.id == starting.id then
			local plan = starting
			starting = nil
			if plan.position and plan.position > SEEK_SLACK then
				MediaPlayer:seek(plan.position)
			end
			if plan.paused and MediaPlayer:is_playing() then
				MediaPlayer:toggle()
			end
			if plan.shuffle ~= nil and MediaPlayer:is_shuffled() ~= plan.shuffle then
				MediaPlayer:shuffle(plan.shuffle)
			end
			mark()
			if plan.after then
				plan.after()
			end
			if plan.owner then
				return
			end
		end
		if link then
			if spotify_song() and song.id ~= link.song then
				link.natural = near_end()
				schedule_push()
			end
			return
		end
		if not spotify_song() then
			return deactivate()
		end
		if MediaPlayer:is_playing() then
			activate(true)
		end
		publish()
	end)

	nari.on("state", function(playback)
		if link then
			local song = spotify_song()
			if song and not is_line(song.id) and not link.busy and playback.playing ~= link.playing then
				link.playing = playback.playing
				command(link, { endpoint = playback.playing and "resume" or "pause" })
			end
			return
		end
		if playback.playing and spotify_song() then
			if reclaim() then
				return
			end
			activate(true)
		end
		if player.active then
			publish()
		end
	end)

	MediaPlayer.playback_changed:connect(function(state)
		local signature = table.concat({ tostring(state.shuffle), tostring(state["repeat"]), tostring(state.queue_version), tostring(state.index) }, ":")
		if signature == shared then
			return
		end
		shared = signature
		if link then
			schedule_push()
		elseif player.active then
			publish()
		end
	end)

	MediaPlayer.volume_changed:connect(function()
		if not link then
			publish("volume")
		end
	end)

	local control = {}

	function control.linked()
		return link ~= nil
	end

	function control.settle()
		if link then
			link.quiet = ticks() + QUIET_TRACK
		end
	end

	function control.play_remote(context, url, tracks)
		if link then
			local first = tracks and tracks[1]
			command(link, {
				endpoint = "play",
				context = { uri = context, url = url or "context://" .. context, pages = tracks and { { tracks = tracks } } or nil },
				play_origin = { feature_identifier = "nari" },
				options = first and { skip_to = { track_uid = first.uid, track_uri = first.uri } } or {},
			}, QUIET_TRACK)
		end
	end

	function control.signed_in()
		local kind = OS:has_feature("mobile") and "smartphone" or "computer"
		call({ action = "start", identity = { name = "Nari (" .. OS:get_name() .. ")", kind = kind } })
	end

	function control.signed_out()
		player.active = false
		if link then
			link = nil
			output:release()
		end
		call({ action = "stop" })
	end

	nari.after(SYNC, tick)
	return control
end

return remote

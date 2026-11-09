local narration = require("narration")
local queue = require("queue")

local ICON = "assets/dj.svg"
local REFILL = 3

local dj = {}

local function is_line(id)
	return tostring(id):sub(1, #narration.PREFIX) == narration.PREFIX
end

function dj.start(host)
	local session
	local view
	local control = {}

	local function spotify_provider()
		return MediaPlayer.provider ~= nil and MediaPlayer.provider.id == host.id
	end

	local function owns(id)
		return session ~= nil and id ~= nil and session.ids[id] == true
	end

	local function refresh_view()
		if view then
			local song = nari.current()
			view:set_available(song ~= nil and owns(song.id))
		end
	end

	local function adopt(items)
		for _, item in ipairs(items) do
			session.ids[item.id] = true
		end
		refresh_view()
	end

	local function fetch(jumped, done)
		local current = session
		current.loading = true
		host.ask({ action = "dj", url = current.next, jump = jumped }, function(message)
			if session ~= current then
				return
			end
			current.loading = false
			if message.error then
				nari.log("the DJ couldn't load: " .. message.error)
				return done(nil)
			end
			host.remember(message.items)
			current.next = message.next
			adopt(message.items)
			done(message.items)
		end)
	end

	local function music_left(songs)
		local left = 0
		for position = queue.index() + 2, #songs do
			if owns(songs[position].id) and not is_line(songs[position].id) then
				left = left + 1
			end
		end
		return left
	end

	local function refill()
		if not session or session.loading or host.connect.linked() then
			return
		end
		queue.read(function(songs)
			if session and not session.loading and music_left(songs) < REFILL then
				fetch(false, function(items)
					if items then
						MediaPlayer:queue_tracks(items)
					end
				end)
			end
		end)
	end

	local function hold()
		host.connect.settle()
		local placeholder = narration.placeholder()
		session.ids[placeholder.id] = true
		host.remember({ placeholder })
		MediaPlayer:play_tracks({ placeholder }, placeholder.id, false)
	end

	local function play(items)
		if items and #items > 0 then
			MediaPlayer:play_tracks(items, items[1].id, false)
		else
			MediaPlayer:stop()
		end
	end

	function control.play()
		if not spotify_provider() then
			MediaPlayer:use_provider(host.id)
		end
		session = { ids = {} }
		Main:change_page(Main.Pages.NowPlaying)
		hold()
		if host.connect.linked() then
			return host.connect.play_remote(narration.CONTEXT, narration.URL)
		end
		fetch(false, play)
	end

	function control.continue(ids)
		session = session or { ids = {} }
		for _, id in ipairs(ids) do
			session.ids[id] = true
		end
		refresh_view()
	end

	function control.jump()
		local song = nari.current()
		if not song or not owns(song.id) or session.loading then
			return
		end
		hold()
		if host.connect.linked() then
			return host.ask({ action = "dj_next" }, function(message)
				host.connect.play_remote(narration.CONTEXT, message.url or narration.URL, message.tracks)
			end)
		end
		fetch(true, play)
	end

	function control.follow(state, settled)
		session = session or { ids = {} }
		for _, list in ipairs({ state.previous, { state.uri }, state.upcoming }) do
			for _, uri in ipairs(list) do
				local id = uri:match("^spotify:track:(.+)$")
				if id then
					session.ids[id] = true
				end
			end
		end
		local song = nari.current()
		if settled and not state.uri:match("^spotify:track:") and (not song or song.id ~= narration.LOADING) then
			hold()
		end
		refresh_view()
	end

	function control.owns(id)
		return owns(id)
	end

	nari.home_entry({
		id = "dj",
		title = "DJ",
		subtitle = "Your AI DJ, picking songs just for you",
		icon = ICON,
		color = "Green",
		available = spotify_provider,
		action = control.play,
	})

	if nari.cover_view then
		view = nari.cover_view({
			id = "dj",
			title = "Let DJ pick",
			icon = ICON,
			provider = host.id,
			momentary = true,
			hide_unavailable = true,
			on_toggle = control.jump,
		})
	end

	nari.on("track", function(song)
		if session and song and not owns(song.id) then
			session = nil
		end
		refresh_view()
		if song and owns(song.id) then
			refill()
		end
	end)

	return control
end

return dj

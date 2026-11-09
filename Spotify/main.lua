local LIKED = { track = "tracks", album = "albums", artist = "followed" }
local MIXES = 3
local BROWSER_LOGINS = { "/login/google", "/login/facebook", "/login/apple", "accounts.google.com" }
local COVERS_DELAY = 2

local remote = require("remote")
local dj = require("dj")

local worker = nari.thread("library.lua")
local quick = nari.thread("library.lua")
nari.thread("session.lua", { name = "session" }):on_error(function(problem) nari.log("the session thread stopped: " .. problem) end)
nari.thread("source.lua"):on_error(function(problem) nari.log("the audio thread stopped: " .. problem) end)

local state = {
	account = nari.get("account"),
	library = nari.get("library"),
	loading = false,
	progress = 0,
}
if state.library and state.library.version ~= 2 then
	state.library = nil
end
local index = { tracks = {}, items = {}, covers = nari.get("covers") or state.library and state.library.covers or {} }
local waiting, pending, requests = {}, {}, 0
local me, connect, radio
local refresh, forget, login
local covers_queued = false

local function notify(text)
	local dialog = Dialog.menu("Spotify", text)
	dialog:add_option("OK", function() end)
	dialog:popup()
end

local function ask(message, handler, thread)
	requests = requests + 1
	message.request = requests
	pending[requests] = handler
	local target = thread or worker
	target:send(message)
end

local function answer(message)
	if message.progress then
		state.progress = message.progress
		return
	end
	if message.signed_in ~= nil then
		if login then
			login:close()
		end
		if not message.signed_in then
			forget()
			return notify(message.problem)
		end
		state.account = message.account
		me.settings_changed:emit()
		connect.signed_in()
		Snackbar.post("Signed in to Spotify", "Welcome, " .. tostring(state.account), nil, "success")
		return refresh()
	end
	local handler = pending[message.request]
	pending[message.request] = nil
	if handler then
		handler(message)
	end
end

for _, thread in ipairs({ worker, quick }) do
	thread:on_message(answer)
	thread:on_error(function(problem) nari.log("a library thread stopped: " .. problem) end)
end

local function save_covers()
	if covers_queued then
		return
	end
	covers_queued = true
	nari.after(COVERS_DELAY, function()
		covers_queued = false
		nari.set("covers", index.covers)
	end)
end

local function remember(item)
	if item and item.art then
		local known = index.covers[item.id]
		if not known or known[1] ~= item.art[1] then
			index.covers[item.id] = item.art
			save_covers()
		end
		if item.album_id and item.album_id ~= "" and not index.covers[item.album_id] then
			index.covers[item.album_id] = item.art
		end
	end
	return item
end

local function remember_all(list)
	for _, item in ipairs(list or {}) do
		remember(item)
		if item.album_id and item.duration then
			index.tracks[item.id] = index.tracks[item.id] or item
		else
			index.items[item.id] = index.items[item.id] or item
		end
	end
	return list or {}
end

local function newest_first(list)
	table.sort(list, function(first, second) return (first.liked_at or 0) > (second.liked_at or 0) end)
end

local function build(library)
	local artists, known = {}, {}
	newest_first(library.tracks)
	newest_first(library.albums)
	for _, track in ipairs(library.tracks) do
		index.tracks[track.id] = track
		remember(track)
	end
	for _, item in ipairs(library.albums) do
		index.items[item.id] = item
		remember(item)
	end
	for _, item in ipairs(library.followed) do
		item.album_count, item.song_count = 0, 0
		index.items[item.id] = item
		known[item.id] = item
		remember(item)
		table.insert(artists, item)
	end
	local function add(id, name, field, cover)
		if not id or id == "" then
			return
		end
		local entry = known[id]
		if not entry then
			entry = { id = id, name = name or "", album_count = 0, song_count = 0, cover_album_id = cover }
			known[id] = entry
			table.insert(artists, entry)
		end
		entry[field] = entry[field] + 1
	end
	for _, track in ipairs(library.tracks) do
		add(track.artist_id, track.artists[1], "song_count", track.album_id)
	end
	for _, item in ipairs(library.albums) do
		add(item.artist_id, item.artists[1], "album_count", item.id)
	end
	local names = {}
	for _, artist in ipairs(artists) do
		names[artist] = artist.name:lower()
	end
	table.sort(artists, function(first, second) return names[first] < names[second] end)
	library.artists = artists
	library.covers = nil
	library.version = 2
end

local function finish_waiting()
	local handlers = waiting
	waiting = {}
	for _, handler in ipairs(handlers) do
		handler()
	end
end

local function when_loaded(done, read)
	if state.library or not state.loading then
		return read()
	end
	table.insert(waiting, function() done(read()) end)
end

function refresh()
	if state.loading or not nari.get("refresh_token") then
		return
	end
	state.loading = true
	state.progress = 0
	ask({ action = "library" }, function(message)
		state.loading = false
		if message.error then
			nari.log("the library couldn't be loaded: " .. message.error)
			finish_waiting()
			return me.library_ready:emit(false, message.error)
		end
		build(message.library)
		state.library = message.library
		nari.set("library", state.library)
		finish_waiting()
		me.library_changed:emit()
		me.library_ready:emit(true, "")
	end)
end

function forget()
	for id in pairs(nari.get("offline_keys") or {}) do
		MediaPlayer.downloads:remove("spotify", id)
	end
	for _, key in ipairs({ "refresh_token", "access", "account", "library", "covers", "username", "product", "country", "offline_keys", "offline_checked" }) do
		nari.set(key, nil)
	end
	state.account, state.library = nil, nil
	index = { tracks = {}, items = {}, covers = {} }
	connect.signed_out()
	me.settings_changed:emit()
	me.library_changed:emit()
end

local function sign_in()
	ask({ action = "sign_in" }, function(message)
		if message.error then
			return notify(message.error)
		end
		login = nari.webview({
			title = "Sign in to Spotify",
			url = message.url,
			incognito = true,
			on_start = function(web, url)
				for _, provider in ipairs(BROWSER_LOGINS) do
					if url:find(provider, 1, true) then
						web:close()
						nari.open_url(message.url)
						return Snackbar.post("Continue in your browser", "Choose the same option there to finish signing in to Spotify")
					end
				end
			end,
			on_close = function() login = nil end,
		})
		if not login then
			nari.open_url(message.url)
		end
	end)
end

local function cover_url(id, thumb)
	local urls = index.covers[id]
	return urls and urls[thumb and 2 or 1] or nil
end

local function cover_file(url)
	local name = url:match("[^/]+$")
	local extension = name:match("%.(png)$") or "jpg"
	return "covers/" .. name:gsub("%.png$", ""):gsub("[^%w]", "") .. "." .. extension
end

local function failed(what, message)
	nari.log(what .. " failed: " .. message.error)
end

local provider = {
	id = "spotify",
	name = "Spotify",
	description = "Your Spotify library (Premium)",
	icon = "provider.svg",
	color = "#1db954",
	streams = true,
	auto_discover = false,
}

function provider.is_configured()
	return nari.get("refresh_token") ~= nil
end

function provider.is_loading()
	return state.loading and not state.library
end

function provider.is_ready()
	return state.library ~= nil
end

function provider.get_status()
	return Dictionary({ progress = state.progress })
end

function provider.setup_entries()
	return {
		{
			title = "Spotify account",
			description = state.account and ("Signed in as " .. state.account) or "Sign in with your Spotify Premium account",
			icon = "res://assets/icons/artist.svg",
			value = function() return state.account and "Change" or "Sign in" end,
			action = sign_in,
		},
	}
end

function provider.settings_entries()
	local entries = provider.setup_entries()
	if nari.get("refresh_token") then
		table.insert(entries, {
			title = "Refresh library",
			description = state.loading and "Loading your library..." or "Load your songs, albums and artists again",
			icon = "res://assets/icons/repeat.svg",
			action = refresh,
		})
		table.insert(entries, {
			title = "Sign out",
			description = "Forget your Spotify account and library",
			icon = "res://assets/icons/close.svg",
			action = function() Dialog.confirm("Sign out of Spotify?", "Sign out", forget, true) end,
		})
	end
	return entries
end

local function library_list(key)
	return function(self, done)
		return when_loaded(done, function() return state.library and state.library[key] or {} end)
	end
end

provider.get_tracks = library_list("tracks")
provider.get_albums = library_list("albums")
provider.get_artists = library_list("artists")

function provider.get_song(self, id, done)
	if index.tracks[id] then
		return index.tracks[id]
	end
	ask({ action = "song", id = id }, function(message)
		done(message.song and remember_all({ message.song })[1] or Dictionary())
	end)
end

function provider.get_album(self, id, done)
	ask({ action = "album", id = id }, function(message)
		if message.error then
			failed("loading album " .. id, message)
			return done(Dictionary())
		end
		remember(message.album)
		remember_all(message.album.tracks)
		done(message.album)
	end)
end

function provider.get_artist(self, id, done)
	ask({ action = "artist", id = id }, function(message)
		if message.error then
			failed("loading artist " .. id, message)
			return done(Dictionary())
		end
		remember(message.artist)
		remember_all(message.artist.albums)
		remember_all(message.artist.tracks)
		remember_all(message.artist.top_tracks)
		remember_all(message.artist.related)
		done(message.artist)
	end)
end

function provider.get_cover_path(self, kind, id, thumb, done)
	local url = cover_url(id, thumb)
	if not url then
		return ""
	end
	local file = cover_file(url)
	local path = nari.plugin.data .. "/" .. file
	if FileAccess:file_exists(path) then
		return path
	end
	nari.http({ url = url, save = file }, function(response)
		done(response and response.status == 200 and response.path or "")
	end)
end

function provider.playable(self, tracks)
	local list = {}
	for _, track in ipairs(tracks) do
		local url = cover_url(track.album_id ~= "" and track.album_id or track.id, false) or ""
		table.insert(list, {
			id = track.id,
			title = track.title,
			artist = track.artist,
			artist_id = track.artist_id,
			album = track.album,
			album_id = track.album_id,
			duration = track.duration,
			uri = "spotify:" .. track.id,
			file_name = track.id .. "." .. (track.extension or track.narration and "mp3" or "ogg"),
			ephemeral = track.narration == true,
			cover = url ~= "" and (nari.plugin.data .. "/" .. cover_file(url)) or "",
			cover_url = url,
			public_cover_url = url,
			share_url = track.narration and "" or "https://open.spotify.com/track/" .. track.id,
		})
	end
	return list
end

function provider.search(self, query, filters, done)
	local terms = { query }
	for _, field in ipairs({ "title", "artist", "album", "genre" }) do
		if filters and filters[field] and filters[field] ~= "" then
			table.insert(terms, filters[field])
		end
	end
	local text = table.concat(terms, " "):match("^%s*(.-)%s*$")
	if text == "" then
		return { tracks = {}, albums = {}, artists = {} }
	end
	ask({ action = "search", query = text }, function(message)
		if message.error then
			failed("searching", message)
			return done({ tracks = {}, albums = {}, artists = {} })
		end
		for _, key in ipairs({ "tracks", "albums", "artists" }) do
			remember_all(message.result[key])
		end
		done(message.result)
	end, quick)
end

function provider.get_hints(self, query, done)
	if not nari.get("refresh_token") then
		return {}
	end
	ask({ action = "hints", query = query }, function(message)
		if message.error then
			failed("loading hints", message)
			return done({})
		end
		for _, hint in ipairs(message.hints) do
			remember(hint.item)
		end
		done(message.hints)
	end, quick)
end

function provider.get_playlists(self, done)
	ask({ action = "playlists" }, function(message)
		if message.error then
			failed("loading playlists", message)
			return done({})
		end
		for _, playlist in ipairs(message.playlists) do
			index.covers[playlist.id] = playlist.picture or index.covers[playlist.id]
		end
		done(message.playlists)
	end)
end

function provider.get_playlist(self, id, done)
	ask({ action = "playlist", id = id }, function(message)
		if message.error then
			failed("loading playlist " .. id, message)
			return done(Dictionary())
		end
		remember_all(message.playlist.tracks)
		index.covers[id] = message.playlist.picture or index.covers[id]
		done(message.playlist)
	end)
end

local function change(message, done, result)
	ask(message, function(answer)
		if answer.error then
			failed(message.action, answer)
		end
		done(result and result(answer) or true)
	end)
end

function provider.create_playlist(self, name, done)
	change({ action = "create", name = name }, done, function(answer) return answer.id or "" end)
end

function provider.delete_playlist(self, id, done)
	change({ action = "delete", id = id }, done)
end

function provider.rename_playlist(self, id, name, done)
	change({ action = "rename", id = id, name = name }, done)
end

function provider.add_to_playlist(self, id, song_ids, done)
	local songs = {}
	for _, song_id in ipairs(song_ids) do
		table.insert(songs, song_id)
	end
	change({ action = "add", id = id, songs = songs }, done)
end

function provider.remove_from_playlist(self, id, song_id, done)
	change({ action = "remove", id = id, song = song_id }, done)
end

function provider.get_liked(self, kind, done)
	return when_loaded(done, function() return state.library and state.library[LIKED[kind]] or {} end)
end

function provider.set_liked(self, kind, id, on, done)
	ask({ action = "like", kind = kind, id = id, on = on }, function(message)
		if message.error then
			failed("saving the like", message)
			return done(true)
		end
		local library = state.library
		if library and LIKED[kind] then
			local list = library[LIKED[kind]]
			for position = #list, 1, -1 do
				if list[position].id == id then
					table.remove(list, position)
				end
			end
			local item = kind == "track" and index.tracks[id] or index.items[id]
			if on and item then
				item.liked_at = os.time()
				table.insert(list, 1, item)
			end
			build(library)
			nari.set("library", library)
			me.library_changed:emit()
		end
		done(true)
	end)
end

function provider.get_discover(self, done)
	local seeds = {}
	for _, track in ipairs(state.library and state.library.tracks or {}) do
		if #seeds < MIXES then
			table.insert(seeds, { id = track.id, title = track.title })
		end
	end
	if #seeds == 0 then
		return {}
	end
	ask({ action = "discover", seeds = seeds }, function(message)
		if message.error then
			failed("loading Discover", message)
			return done({})
		end
		for _, section in ipairs(message.sections) do
			remember_all(section.items)
		end
		done(message.sections)
	end)
end

connect = remote.start({
	id = provider.id,
	ask = ask,
	remember = remember_all,
	liked = function() return state.library and state.library.tracks or {} end,
	dj = function() return radio end,
})
radio = dj.start({ id = provider.id, ask = ask, remember = remember_all, connect = connect })

me = nari.music_provider(provider)
if state.library then
	build(state.library)
end
if nari.get("refresh_token") then
	connect.signed_in()
end
refresh()

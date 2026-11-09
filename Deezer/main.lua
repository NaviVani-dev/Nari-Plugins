local LIKED = { track = "tracks", album = "albums", artist = "followed" }
local LOGIN = "https://www.deezer.com/login"
local SAFARI = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
local EXTENSIONS = { original = ".flac" }
local PLANS = { "lossless", "high quality", "standard quality" }
local COVERS_DELAY = 2

nari.log_color("#a238ff")

local worker = nari.thread("library.lua")
local quick = nari.thread("library.lua")
nari.thread("source.lua"):on_error(function(problem) nari.warn("the audio thread stopped: " .. problem) end)

local state = {
	account = nari.get("account"),
	plan = nari.get("plan"),
	library = nari.get("library"),
	profiles = nari.get("profiles"),
	loading = false,
	progress = 0,
}
if state.library and state.library.version ~= 1 then
	state.library = nil
end
local index = { tracks = {}, items = {}, covers = nari.get("covers") or state.library and state.library.covers or {} }
local waiting, pending, requests = {}, {}, 0
local fetching = {}
local covers_queued = false
local me
local refresh

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
	local handler = pending[message.request]
	pending[message.request] = nil
	if handler then
		handler(message)
	end
end

for _, thread in ipairs({ worker, quick }) do
	thread:on_message(answer)
	thread:on_error(function(problem) nari.warn("a library thread stopped: " .. problem) end)
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

local function cover_key(item)
	if item.album_id and item.duration then
		return "tr" .. item.id
	end
	return item.id
end

local function remember(item)
	if item and item.art then
		local key = cover_key(item)
		local known = index.covers[key]
		if not known or known[1] ~= item.art[1] then
			index.covers[key] = item.art
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
	local fallback = os.time()
	for position, item in ipairs(list) do
		item.liked_at = item.liked_at or (fallback - position)
	end
	table.sort(list, function(first, second) return first.liked_at > second.liked_at end)
end

local function build(library)
	local artists, known = {}, {}
	newest_first(library.tracks)
	newest_first(library.albums)
	newest_first(library.followed)
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
	library.version = 1
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

local function signed_in()
	return nari.get("arl") ~= nil
end

function refresh()
	if state.loading or not signed_in() then
		return
	end
	state.loading = true
	state.progress = 0
	ask({ action = "library" }, function(message)
		state.loading = false
		if message.error then
			nari.warn("the library couldn't be loaded: " .. message.error)
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

local function forget()
	for id in pairs(nari.get("offline_ids") or {}) do
		MediaPlayer.downloads:remove("deezer", id)
	end
	for _, key in ipairs({ "arl", "account", "plan", "library", "covers", "offline_ids", "offline_checked", "profile", "profiles" }) do
		nari.set(key, nil)
	end
	state.account, state.plan, state.library, state.profiles = nil, nil, nil, nil
	index = { tracks = {}, items = {}, covers = {} }
	me.settings_changed:emit()
	me.library_changed:emit()
end

local function read_arl(text)
	local trimmed = tostring(text or ""):match("^%s*(.-)%s*$")
	local found = trimmed:match("arl=(%x+)") or trimmed
	if #found >= 32 and found:match("^%x+$") then
		return found
	end
end

local function use_account(message)
	state.account, state.plan = message.account, message.plan
	nari.set("account", message.account)
	nari.set("plan", message.plan)
end

local function use_profile(id)
	if id == (nari.get("profile") or state.profiles[1].value) then
		return
	end
	ask({ action = "profile", id = id }, function(message)
		if message.error then
			return Snackbar.post("Deezer didn't switch the profile", message.error, nil, "error")
		end
		use_account(message)
		state.library = nil
		nari.set("library", nil)
		index.tracks, index.items = {}, {}
		refresh()
		me.settings_changed:emit()
		me.library_changed:emit()
		Snackbar.post("Switched Deezer profile", "Listening as " .. tostring(state.account), nil, "success")
	end)
end

local function pick_profile()
	local dialog = Dialog.menu("Who's listening?", "Pick your profile of this Deezer Family account")
	for _, profile in ipairs(state.profiles) do
		dialog:add_option(profile.label, function() use_profile(profile.value) end)
	end
	dialog:popup()
end

local function load_profiles()
	ask({ action = "profiles" }, function(message)
		if message.error then
			return nari.warn("loading the Family profiles failed: " .. message.error)
		end
		state.profiles = message.profiles
		nari.set("profiles", message.profiles)
		me.settings_changed:emit()
	end)
end

local function sign_in_with(arl, done)
	ask({ action = "account", arl = arl }, function(message)
		if message.error then
			return done(message.error)
		end
		use_account(message)
		state.profiles = message.profiles
		nari.set("profiles", message.profiles)
		refresh()
		me.settings_changed:emit()
		done()
		if #state.profiles > 1 then
			pick_profile()
		end
	end)
end

local function finish_sign_in(arl)
	local busy = Dialog.busy and Dialog.busy("Signing in to Deezer", "Checking your account...")
	if busy then
		busy:popup()
	end
	sign_in_with(arl, function(problem)
		if busy then
			busy:close()
		end
		if problem then
			Snackbar.post("Deezer didn't sign you in", problem)
		else
			Snackbar.post("Signed in to Deezer", "Welcome, " .. tostring(state.account), nil, "success")
		end
	end)
end

local function paste_arl()
	Dialog.ask("Paste your Deezer arl cookie", "", true, function(text)
		local arl = read_arl(text)
		if not arl then
			error("That doesn't look like an arl cookie", 0)
		end
		finish_sign_in(arl)
	end)
end

local function sign_in()
	local done = false
	local web = nari.webview({
		title = "Sign in to Deezer",
		url = LOGIN,
		incognito = true,
		user_agent = OS:get_name() == "Linux" and SAFARI or nil,
		on_load = function(web)
			if done then
				return
			end
			local arl = read_arl(web:cookies("https://www.deezer.com"))
			if not arl then
				return
			end
			done = true
			web:close()
			finish_sign_in(arl)
		end,
	})
	if not web then
		paste_arl()
	end
end

local function cover_file(url)
	return "covers/" .. nari.md5(url) .. ".jpg"
end

local function failed(what, message)
	nari.warn(what .. " failed: " .. message.error)
end

local provider = {
	id = "deezer",
	name = "Deezer",
	description = "Your Deezer library, Flow and the whole catalog",
	icon = "provider.svg",
	color = "#a238ff",
	streams = true,
	auto_discover = false,
}

function provider.is_configured()
	return signed_in()
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
	local plan = state.plan and PLANS[state.plan]
	return {
		{
			title = "Deezer account",
			description = state.account and ("Signed in as " .. state.account .. (plan and (", streaming up to " .. plan) or ""))
				or "Sign in with your Deezer account",
			icon = "res://assets/icons/artist.svg",
			value = function() return state.account and "Change" or "Sign in" end,
			action = sign_in,
		},
	}
end

function provider.settings_entries()
	local entries = provider.setup_entries()
	table.insert(entries, {
		title = "Sign in with an arl",
		description = "Paste the arl cookie from a browser signed in to deezer.com",
		icon = "res://assets/icons/upload.svg",
		action = paste_arl,
	})
	if signed_in() and state.profiles and #state.profiles > 1 then
		table.insert(entries, 2, {
			title = "Profile",
			description = "Who's listening on this Deezer Family account",
			icon = "res://assets/icons/artist.svg",
			value = function() return tostring(state.account or "") end,
			choices = {
				options = state.profiles,
				get = function() return nari.get("profile") or state.profiles[1].value end,
				set = use_profile,
			},
		})
	end
	if signed_in() then
		table.insert(entries, {
			title = "Refresh library",
			description = state.loading and "Loading your library..." or "Load your songs, albums and artists again",
			icon = "res://assets/icons/repeat.svg",
			action = refresh,
		})
		table.insert(entries, {
			title = "Sign out",
			description = "Forget your Deezer account, library and downloads",
			icon = "res://assets/icons/close.svg",
			action = function() Dialog.confirm("Sign out of Deezer?", "Sign out", forget, true) end,
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
		remember_all(message.artist.related)
		for _, section in ipairs(message.artist.sections or {}) do
			remember_all(section.items)
		end
		done(message.artist)
	end)
end

local function cover_url(kind, id, thumb)
	local urls = (kind == "song" and index.covers["tr" .. id]) or index.covers[id]
	return urls and urls[thumb and 2 or 1] or nil
end

function provider.get_cover_path(self, kind, id, thumb, done)
	local url = cover_url(kind, id, thumb)
	if not url then
		return ""
	end
	local file = cover_file(url)
	local path = nari.plugin.data .. "/" .. file
	if FileAccess:file_exists(path) then
		return path
	end
	if fetching[file] then
		table.insert(fetching[file], done)
		return
	end
	fetching[file] = { done }
	nari.http({ url = url, save = file }, function(response)
		local result = response and response.status == 200 and response.path or ""
		local handlers = fetching[file]
		fetching[file] = nil
		for _, handler in ipairs(handlers) do
			handler(result)
		end
	end)
end

function provider.media_uri(self, track, quality)
	return "deezer:" .. track.id .. "?quality=" .. (quality ~= "" and quality or "original")
end

function provider.playable(self, tracks)
	local list = {}
	local quality = SettingsManager.playback.stream_quality
	for _, track in ipairs(tracks) do
		local known = index.tracks[track.id]
		local urls = track.art or (known and known.art) or index.covers[track.album_id] or index.covers["tr" .. track.id]
		local url = urls and urls[1] or ""
		table.insert(list, {
			id = track.id,
			title = track.title,
			artist = track.artist,
			artist_id = track.artist_id,
			album = track.album,
			album_id = track.album_id,
			duration = track.duration,
			uri = provider.media_uri(self, track, quality),
			file_name = track.id .. (EXTENSIONS[quality] or ".mp3"),
			cover = url ~= "" and (nari.plugin.data .. "/" .. cover_file(url)) or "",
			cover_url = url,
			public_cover_url = url,
			share_url = "https://www.deezer.com/track/" .. track.id,
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
		for _, key in ipairs({ "tracks", "albums", "artists", "playlists" }) do
			remember_all(message.result[key])
		end
		done(message.result)
	end, quick)
end

function provider.get_hints(self, query, done)
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

function provider.get_raw_lyrics(self, id, done)
	ask({ action = "lyrics", id = id }, function(message)
		if message.error then
			failed("loading lyrics", message)
		end
		done(message.lyrics or Dictionary())
	end)
end

function provider.get_radio(self, kind, id, done)
	ask({ action = "radio", kind = kind, id = id }, function(message)
		if message.error then
			failed("starting a radio", message)
			return done(nil)
		end
		done(remember_all(message.tracks))
	end)
end

function provider.get_playlists(self, done)
	if not signed_in() then
		return {}
	end
	ask({ action = "playlists" }, function(message)
		if message.error then
			failed("loading playlists", message)
			return done({})
		end
		remember_all(message.playlists)
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
		remember(message.playlist)
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
	if not signed_in() then
		return {}
	end
	ask({ action = "discover" }, function(message)
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

me = nari.music_provider(provider)
if state.library then
	build(state.library)
end
refresh()
if signed_in() then
	load_profiles()
end

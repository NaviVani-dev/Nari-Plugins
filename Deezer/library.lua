local deezer = require("deezer")

local PAGE = 2000
local DISCOGRAPHY = 500
local TOP = 50
local RELATED = 20
local RADIO = 50
local SHELF = 25
local HINT_QUERIES = 4
local HINTS = {
	{ key = "artists", kind = "artist", count = 1, parse = deezer.artist },
	{ key = "tracks", kind = "track", count = 3, parse = deezer.track },
	{ key = "albums", kind = "album", count = 2, parse = deezer.album },
	{ key = "playlists", kind = "playlist", count = 2, parse = deezer.playlist },
}
local PIPE = "https://pipe.deezer.com/api"
local AUTH = "https://auth.deezer.com/login/arl?jo=p&rto=c&i=c"
local LYRICS_QUERY = [[query SynchronizedTrackLyrics($trackId: String!) {
  track(trackId: $trackId) {
    lyrics {
      text
      synchronizedLines { lrcTimestamp line }
    }
  }
}]]

local jwt

local function data_of(results)
	if type(results) ~= "table" then
		return {}
	end
	return results.data or {}
end

local function paged(method, body)
	local found = {}
	local start = 0
	repeat
		body.start, body.nb = start, PAGE
		local results = deezer.gw(method, body)
		local page = data_of(results)
		for _, item in ipairs(page) do
			table.insert(found, item)
		end
		start = start + #page
		local count = tonumber(type(results) == "table" and results.total) or 0
	until #page < PAGE or (count > 0 and start >= count)
	return found
end

local function profile_tab(tab)
	local results = deezer.gw("deezer.pageProfile", { user_id = deezer.session().user_id, tab = tab, nb = PAGE })
	local section = type(results) == "table" and results.TAB and results.TAB[tab]
	return type(section) == "table" and section.data or {}
end

local function total(tracks)
	local duration = 0
	for _, track in ipairs(tracks) do
		duration = duration + (track.duration or 0)
	end
	return duration
end

local function public_list(path)
	return deezer.list(deezer.public(path))
end

local function playlist_songs(id)
	local songs = {}
	local ok, results = pcall(deezer.gw, "playlist.getSongs", { PLAYLIST_ID = id, start = 0, nb = -1 })
	if ok then
		songs = data_of(results)
	end
	return songs
end

local actions = {}

function actions.account(message)
	local previous, profile = nari.get("arl"), nari.get("profile")
	nari.set("arl", message.arl, { private = true })
	nari.set("profile", nil)
	local ok, session = pcall(deezer.connect, true)
	if not ok then
		nari.set("arl", previous, { private = true })
		nari.set("profile", profile)
		pcall(deezer.connect, true)
		error(session, 0)
	end
	nari.set("offline_checked", os.time())
	return { account = session.name, offer = session.offer, plan = session.plan, profiles = deezer.profiles() }
end

function actions.profile(message)
	local previous = nari.get("profile")
	nari.set("profile", message.id)
	local ok, session = pcall(deezer.connect, true)
	if not ok then
		nari.set("profile", previous)
		pcall(deezer.connect, true)
		error(session, 0)
	end
	return { account = session.name, plan = session.plan }
end

function actions.profiles()
	if not pcall(deezer.connect, false) then
		nari.set("profile", nil)
	end
	return { profiles = deezer.profiles() }
end

function actions.library()
	deezer.connect(true)
	nari.set("offline_checked", os.time())
	local tracks = deezer.map(paged("favorite_song.getList", { user_id = deezer.session().user_id }), deezer.track)
	nari.send({ progress = 0.6 })
	local albums = deezer.map(profile_tab("albums"), deezer.album)
	nari.send({ progress = 0.85 })
	local followed = deezer.map(profile_tab("artists"), deezer.artist)
	return { library = { tracks = tracks, albums = albums, followed = followed } }
end

function actions.song(message)
	local data = deezer.gw("song.getData", { SNG_ID = message.id })
	return { song = deezer.track(data) }
end

function actions.album(message)
	local detail = deezer.public("/album/" .. message.id)
	local album = deezer.album(detail)
	if not album then
		error("Deezer has no data for this album", 0)
	end
	local ok, results = pcall(deezer.gw, "song.getListByAlbum", { ALB_ID = message.id, start = 0, nb = -1 })
	local tracks = ok and deezer.map(data_of(results), deezer.track) or {}
	if #tracks == 0 then
		tracks = deezer.map(type(detail.tracks) == "table" and detail.tracks.data or {}, deezer.track)
	end
	for position, track in ipairs(tracks) do
		track.track_number = track.track_number ~= 0 and track.track_number or position
		track.album, track.album_id = album.title, album.id
		track.year = track.year ~= 0 and track.year or album.year
		track.genres = album.genres
		track.art = track.art or album.art
	end
	album.tracks = tracks
	album.song_count = #tracks
	album.duration = total(tracks)
	return { album = album }
end

local function bio(id)
	local ok, results = pcall(deezer.gw, "deezer.pageArtist", { art_id = id, lang = "en", tab = 0 })
	local block = ok and type(results) == "table" and results.BIO
	if type(block) == "table" then
		local text = block.BIO or block.RESUME or ""
		text = text:gsub("<br%s*/?>", "\n"):gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
		if text ~= "" then
			return text
		end
	end
end

function actions.artist(message)
	local id = deezer.raw_id(message.id)
	local artist = deezer.artist(deezer.public("/artist/" .. id))
	if not artist then
		error("Deezer has no data for this artist", 0)
	end
	local albums = deezer.map(public_list("/artist/" .. id .. "/albums?limit=" .. DISCOGRAPHY), deezer.album)
	for _, album in ipairs(albums) do
		if album.artist == "" then
			album.artist, album.artists, album.artist_id = artist.name, { artist.name }, artist.id
		end
	end
	local tracks = deezer.map(public_list("/artist/" .. id .. "/top?limit=" .. TOP), deezer.track)
	local ok, related = pcall(public_list, "/artist/" .. id .. "/related?limit=" .. RELATED)
	artist.albums = albums
	artist.tracks = tracks
	artist.top_tracks = tracks
	artist.related = ok and deezer.map(related, deezer.artist) or {}
	artist.bio = bio(id)
	artist.album_count = #albums
	artist.song_count = #tracks
	artist.duration = total(tracks)
	local ok_playlists, playlists = pcall(public_list, "/artist/" .. id .. "/playlists?limit=" .. SHELF)
	if ok_playlists and #playlists > 0 then
		artist.sections = { { id = "playlists", title = "Playlists", kind = "playlists", order = 45, items = deezer.map(playlists, deezer.playlist) } }
	end
	return { artist = artist }
end

function actions.search(message)
	local query = deezer.encode(message.query)
	local tracks = deezer.map(public_list("/search?q=" .. query .. "&limit=50"), deezer.track)
	local ok_albums, albums = pcall(public_list, "/search/album?q=" .. query .. "&limit=25")
	local ok_artists, artists = pcall(public_list, "/search/artist?q=" .. query .. "&limit=15")
	local ok_playlists, playlists = pcall(public_list, "/search/playlist?q=" .. query .. "&limit=15")
	return { result = {
		tracks = tracks,
		albums = ok_albums and deezer.map(albums, deezer.album) or {},
		artists = ok_artists and deezer.map(artists, deezer.artist) or {},
		playlists = ok_playlists and deezer.map(playlists, deezer.playlist) or {},
	} }
end

function actions.hints(message)
	local hints = {}
	local ok, results = pcall(deezer.gw, "search_getSuggestedQueries", { QUERY = message.query })
	for _, suggestion in ipairs(ok and type(results) == "table" and results.SUGGESTION or {}) do
		if #hints < HINT_QUERIES and type(suggestion.QUERY) == "string" then
			table.insert(hints, { kind = "query", query = suggestion.QUERY })
		end
	end
	local found = deezer.public("/search/autocomplete?q=" .. deezer.encode(message.query) .. "&limit=4")
	for _, spec in ipairs(HINTS) do
		local items = deezer.map(deezer.list(found[spec.key]), spec.parse)
		for position = 1, math.min(spec.count, #items) do
			table.insert(hints, { kind = spec.kind, item = items[position] })
		end
	end
	return { hints = hints }
end

function actions.playlists()
	local loved = deezer.session().loved
	local list = {}
	for _, playlist in ipairs(deezer.map(profile_tab("playlists"), deezer.playlist)) do
		if deezer.raw_id(playlist.id) ~= loved then
			table.insert(list, playlist)
		end
	end
	return { playlists = list }
end

function actions.playlist(message)
	local id = deezer.raw_id(message.id)
	local results = deezer.gw("deezer.pagePlaylist", { playlist_id = id, start = 0, nb = PAGE, lang = "en", tab = 0, tags = true, header = true })
	local playlist = deezer.playlist(results.DATA) or { id = message.id, name = "", cover_album_ids = { message.id }, image = "" }
	local songs = type(results.SONGS) == "table" and results.SONGS.data or {}
	local count = tonumber(results.SONGS and results.SONGS.total) or #songs
	if count > #songs then
		local all = playlist_songs(id)
		songs = #all > #songs and all or songs
	end
	local tracks = deezer.map(songs, deezer.track)
	playlist.tracks = tracks
	playlist.song_count = #tracks
	playlist.duration = total(tracks)
	playlist.art = playlist.art or (tracks[1] and tracks[1].art)
	return { playlist = playlist }
end

function actions.create(message)
	local body = '{"title":' .. nari.json_encode(message.name) .. ',"status":1,"description":"","songs":[]}'
	local results = deezer.gw("playlist.create", body)
	local id = type(results) == "table" and (results.PLAYLIST_ID or results.id) or results
	if not id then
		error("Deezer didn't create the playlist", 0)
	end
	return { id = deezer.playlist_id(tostring(math.tointeger(tonumber(id)) or id)) }
end

function actions.rename(message)
	deezer.gw("playlist.update", { playlist_id = deezer.raw_id(message.id), title = message.name })
	return {}
end

function actions.delete(message)
	deezer.gw("playlist.delete", { playlist_id = deezer.raw_id(message.id) })
	return {}
end

function actions.add(message)
	local songs = {}
	for _, id in ipairs(message.songs) do
		table.insert(songs, { id, 0 })
	end
	deezer.gw("playlist.addSongs", { playlist_id = deezer.raw_id(message.id), songs = songs, offset = -1 })
	return {}
end

function actions.remove(message)
	deezer.gw("playlist.deleteSongs", { playlist_id = deezer.raw_id(message.id), songs = { { message.song, 0 } } })
	return {}
end

local LIKES = {
	track = { { "favorite_song.add", "favorite_song.remove" }, "SNG_ID" },
	album = { { "album.addFavorite", "album.deleteFavorite" }, { "favorite_album.add", "favorite_album.remove" }, "ALB_ID" },
	artist = { { "artist.addFavorite", "artist.deleteFavorite" }, "ART_ID" },
}

function actions.like(message)
	local like = LIKES[message.kind]
	if not like then
		error("Deezer can't save a " .. tostring(message.kind), 0)
	end
	local body = { [like[#like]] = deezer.raw_id(message.id) }
	local problem
	for position = 1, #like - 1 do
		local ok, result = pcall(deezer.gw, like[position][message.on and 1 or 2], body)
		if ok then
			return {}
		end
		problem = result
	end
	error(problem, 0)
end

function actions.radio(message)
	local tracks
	if message.kind == "artist" then
		tracks = public_list("/artist/" .. deezer.raw_id(message.id) .. "/radio?limit=" .. RADIO)
	elseif message.kind == "album" then
		local first = public_list("/album/" .. message.id .. "/tracks?limit=1")[1]
		if not first then
			return { tracks = {} }
		end
		tracks = data_of(deezer.gw("song.getSearchTrackMix", { SNG_ID = tostring(first.id), start_with_input_track = false }))
	else
		tracks = data_of(deezer.gw("song.getSearchTrackMix", { SNG_ID = message.id, start_with_input_track = false }))
	end
	return { tracks = deezer.map(tracks, deezer.track) }
end

local function shelf(sections, spec, load, parse)
	local ok, items = pcall(load)
	if ok then
		spec.items = deezer.map(items, parse)
		if #spec.items > 0 then
			table.insert(sections, spec)
		end
	else
		nari.log(spec.title .. " couldn't be loaded: " .. tostring(items))
	end
end

function actions.discover()
	local sections = {}
	shelf(sections, { id = "flow", title = "Flow", kind = "tracks", order = 5 }, function()
		return data_of(deezer.gw("radio.getUserRadio", { user_id = deezer.session().user_id }))
	end, deezer.track)
	shelf(sections, { id = "new_releases", title = "New releases", kind = "albums", order = 12 }, function()
		return public_list("/editorial/0/releases?limit=" .. SHELF)
	end, deezer.album)
	shelf(sections, { id = "editor_picks", title = "Editor's picks", kind = "albums", order = 13 }, function()
		return public_list("/editorial/0/selection?limit=" .. SHELF)
	end, deezer.album)
	local ok, chart = pcall(deezer.public, "/chart/0?limit=" .. SHELF)
	if ok then
		shelf(sections, { id = "top_tracks", title = "Top tracks", kind = "track_list", order = 14 }, function() return deezer.list(chart.tracks) end, deezer.track)
		shelf(sections, { id = "top_albums", title = "Top albums", kind = "albums", order = 16 }, function() return deezer.list(chart.albums) end, deezer.album)
		shelf(sections, { id = "top_artists", title = "Top artists", kind = "artists", order = 18 }, function() return deezer.list(chart.artists) end, deezer.artist)
		shelf(sections, { id = "top_playlists", title = "Popular playlists", kind = "playlists", order = 22 }, function() return deezer.list(chart.playlists) end, deezer.playlist)
	else
		nari.log("the charts couldn't be loaded: " .. tostring(chart))
	end
	return { sections = sections }
end

local function token()
	if jwt and jwt.arl == deezer.arl() and jwt.expires > os.time() then
		return jwt.value
	end
	local response = nari.http({ method = "POST", url = AUTH, headers = { Cookie = "arl=" .. deezer.arl(), ["User-Agent"] = deezer.AGENT } })
	local ok, answer = pcall(nari.json_decode, response and response.body or "")
	if not ok or type(answer) ~= "table" or not answer.jwt then
		error("Deezer didn't open the lyrics service", 0)
	end
	jwt = { value = answer.jwt, expires = os.time() + 3000, arl = deezer.arl() }
	return jwt.value
end

local function pipe_lyrics(id)
	local response = nari.http({
		method = "POST",
		url = PIPE,
		headers = { Authorization = "Bearer " .. token(), ["Content-Type"] = "application/json", ["User-Agent"] = deezer.AGENT },
		body = nari.json_encode({ operationName = "SynchronizedTrackLyrics", variables = { trackId = id }, query = LYRICS_QUERY }),
	})
	local ok, answer = pcall(nari.json_decode, response and response.body or "")
	local track = ok and type(answer) == "table" and type(answer.data) == "table" and answer.data.track
	return type(track) == "table" and type(track.lyrics) == "table" and track.lyrics or nil
end

local function gateway_lyrics(id)
	local ok, results = pcall(deezer.gw, "song.getLyrics", { SNG_ID = id })
	if not ok or type(results) ~= "table" then
		return nil
	end
	local lines = {}
	for _, line in ipairs(results.LYRICS_SYNC_JSON or {}) do
		if line.lrc_timestamp then
			table.insert(lines, { lrcTimestamp = line.lrc_timestamp, line = line.line or "" })
		end
	end
	return { text = results.LYRICS_TEXT, synchronizedLines = lines }
end

function actions.lyrics(message)
	local ok, lyrics = pcall(pipe_lyrics, message.id)
	if not ok or not lyrics then
		lyrics = gateway_lyrics(message.id)
	end
	if not lyrics then
		return { lyrics = {} }
	end
	local lines = {}
	for _, line in ipairs(type(lyrics.synchronizedLines) == "table" and lyrics.synchronizedLines or {}) do
		if type(line.lrcTimestamp) == "string" then
			table.insert(lines, line.lrcTimestamp .. (type(line.line) == "string" and line.line or ""))
		end
	end
	if #lines > 0 then
		return { lyrics = { text = table.concat(lines, "\n"), format = "lrc", source = "deezer", song_id = message.id } }
	end
	if type(lyrics.text) == "string" and lyrics.text ~= "" then
		return { lyrics = { text = lyrics.text:gsub("\r", ""), format = "txt", source = "deezer", song_id = message.id } }
	end
	return { lyrics = {} }
end

nari.on("message", function(message)
	local handler = actions[message.action]
	local ok, result = pcall(handler or function() error("unknown action " .. tostring(message.action), 0) end, message)
	if not ok then
		result = { error = tostring(result):gsub("^.-:%d+: ", "") }
	end
	result.request = message.request
	nari.send(result)
end)

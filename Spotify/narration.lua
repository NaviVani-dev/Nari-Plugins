local auth = require("auth")
local proto = require("proto")
local spotify = require("spotify")

local CONTEXT = "spotify:playlist:37i9dQZF1EYkqdzj48dyYq"
local SESSION = "/lexicon-session-provider/context-resolve/v2/session?contextUri=" .. CONTEXT
local TTS = "https://spclient.wg.spotify.com/client-tts/v1/fulfill"
local IMAGE = "https://lexicon-assets.spotifycdn.com/Your-DJ-Cover-Art-300.png"
local FOLDER = "dj"
local KEPT_FILES = 40
local MP3 = 5
local SAMPLE_RATE = 44100
local DEFAULT_PROVIDER = 6
local PROVIDERS = {
	CLOUD_TTS = 1,
	READSPEAKER = 2,
	POLLY = 3,
	WELL_SAID = 4,
	SONANTIC_DEPRECATED = 5,
	SONANTIC_FAST = 6,
	OPENAI = 7,
	SONANTIC_LARGE = 8,
	ELEVEN_LABS_DEPRECATED = 9,
	ADS_PUBLIC = 10,
}
local VORBIS = { [0] = true, [1] = true, [2] = true }
local BITRATES = { 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320 }

local SILENCE_RATE = 8000
local SILENCE_SECONDS = 30

local narration = { CONTEXT = CONTEXT, URL = "hm:/" .. SESSION, IMAGE = IMAGE, PREFIX = "dj-", LOADING = "dj-loading" }

local function path_of(key)
	return nari.plugin.data .. "/" .. FOLDER .. "/" .. key .. ".mp3"
end

function narration.placeholder()
	return {
		id = narration.LOADING,
		title = "Up next",
		artist = "DJ X",
		artists = { "DJ X" },
		artist_id = "",
		album = "DJ",
		album_id = "",
		duration = SILENCE_SECONDS * 1000,
		track_number = 0,
		disc_number = 1,
		year = 0,
		genres = {},
		file_name = "",
		art = { IMAGE, IMAGE },
		narration = true,
		extension = "wav",
	}
end

function narration.silence()
	local samples = SILENCE_RATE * SILENCE_SECONDS
	return "RIFF" .. string.pack("<I4", 36 + samples) .. "WAVEfmt "
		.. string.pack("<I4I2I2I4I4I2I2", 16, 1, 1, SILENCE_RATE, SILENCE_RATE, 1, 8)
		.. "data" .. string.pack("<I4", samples) .. string.rep("\128", samples)
end

function narration.path(id)
	return path_of(id:sub(#narration.PREFIX + 1))
end

local function duration(path)
	local file = io.open(path, "rb")
	if not file then
		return 0
	end
	local size = file:seek("end")
	file:seek("set", 0)
	local head = file:read(10) or ""
	local offset = 0
	if head:sub(1, 3) == "ID3" then
		local a, b, c, d = head:byte(7, 10)
		offset = 10 + (a << 21 | b << 14 | c << 7 | d)
	end
	file:seek("set", offset)
	local frame = file:read(4) or ""
	file:close()
	local kbps = BITRATES[(frame:byte(3) or 0) >> 4] or BITRATES[#BITRATES]
	return math.floor((size - offset) * 8 / kbps)
end

local function forget_old(key)
	local files = nari.get("dj_files") or {}
	for index = #files, 1, -1 do
		if files[index] == key then
			table.remove(files, index)
		end
	end
	table.insert(files, key)
	while #files > KEPT_FILES do
		os.remove(path_of(table.remove(files, 1)))
	end
	nari.set("dj_files", files)
end

local function synthesize(key, metadata, prefix)
	local path = path_of(key)
	local existing = io.open(path, "rb")
	if existing then
		existing:close()
		return path
	end
	local token, problem = auth.token()
	if not token then
		error(problem, 0)
	end
	local body = proto.bytes(2, metadata[prefix .. ".ssml"])
		.. proto.int(3, MP3)
		.. proto.int(5, tonumber((metadata[prefix .. ".voice"] or ""):match("%d+")) or 1)
		.. proto.int(6, PROVIDERS[metadata[prefix .. ".tts_provider"]] or DEFAULT_PROVIDER)
		.. proto.int(7, tonumber(metadata[prefix .. ".sample_rate"]) or SAMPLE_RATE)
	local response, failure = nari.http({
		method = "POST",
		url = TTS,
		headers = { Authorization = "Bearer " .. token, ["Content-Type"] = "application/x-protobuf" },
		body = body,
		save = FOLDER .. "/" .. key .. ".mp3",
	})
	if not response or response.status ~= 200 then
		os.remove(path)
		error("the DJ's voice couldn't be loaded: " .. tostring(failure or response.status), 0)
	end
	return path
end

local function line(metadata, kind)
	local prefix = "narration." .. kind
	local ssml = metadata[prefix .. ".ssml"]
	if type(ssml) ~= "string" or ssml == "" then
		return nil
	end
	local key = nari.sha1(ssml):sub(1, 24)
	local ok, path = pcall(synthesize, key, metadata, prefix)
	if not ok then
		nari.log(path)
		return nil
	end
	forget_old(key)
	local image = metadata[prefix .. ".image"] or IMAGE
	local artist = metadata[prefix .. ".artist"] or "DJ X"
	return {
		id = narration.PREFIX .. key,
		title = metadata[prefix .. ".title"] or "DJ",
		artist = artist,
		artists = { artist },
		artist_id = "",
		album = metadata[prefix .. ".album_title"] or "DJ",
		album_id = "",
		duration = duration(path),
		track_number = 0,
		disc_number = 1,
		year = 0,
		genres = {},
		file_name = "",
		art = { image, image },
		narration = true,
	}
end

local function has_audio(fields)
	for _, raw in ipairs(proto.list(fields, 12)) do
		if VORBIS[proto.path(proto.decode(raw), 2) or 0] then
			return true
		end
	end
	return false
end

local function playable(fields)
	if has_audio(fields) then
		return true
	end
	for _, raw in ipairs(proto.list(fields, 13)) do
		if has_audio(proto.decode(raw)) then
			return true
		end
	end
	return false
end

local function page_of(url)
	local found = spotify.json((url:gsub("^hm://", "/")))
	if type(found.pages) == "table" then
		return found.pages[#found.pages] or {}
	end
	return found
end

function narration.next_page()
	local url = page_of(SESSION).next_page_url
	if not url then
		error("Spotify didn't give the DJ's next pick", 0)
	end
	local page = page_of(url)
	local tracks = {}
	for _, track in ipairs(page.tracks or {}) do
		if type(track.uri) == "string" and track.uri:match("^spotify:track:") then
			table.insert(tracks, { uri = track.uri, uid = track.uid, metadata = track.metadata })
		end
	end
	return { url = url, tracks = tracks }
end

function narration.segment(url, jumped)
	if not url then
		url = page_of(SESSION).next_page_url
		if not url then
			error("Spotify didn't start the DJ", 0)
		end
	end
	local page = page_of(url)
	local entries, uris = {}, {}
	for _, track in ipairs(page.tracks or {}) do
		if type(track.uri) == "string" and track.uri:match("^spotify:track:") then
			table.insert(entries, track)
			table.insert(uris, track.uri)
		end
	end
	local found = spotify.metadata(uris, spotify.TRACK)
	local items = {}
	for index, entry in ipairs(entries) do
		local fields = found[entry.uri]
		if fields and playable(fields) then
			local metadata = type(entry.metadata) == "table" and entry.metadata or {}
			local before = jumped and index == 1 and line(metadata, "jump") or line(metadata, "intro")
			if before then
				table.insert(items, before)
			end
			table.insert(items, spotify.track(fields))
			local after = line(metadata, "outro")
			if after then
				table.insert(items, after)
			end
		end
	end
	if #items == 0 then
		error("the DJ didn't pick any songs", 0)
	end
	return { items = items, next = page.next_page_url }
end

return narration

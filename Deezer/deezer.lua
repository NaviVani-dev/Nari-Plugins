local deezer = {}

local GATEWAY = "https://www.deezer.com/ajax/gw-light.php"
local PUBLIC = "https://api.deezer.com"
local AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:142.0) Gecko/20100101 Firefox/142.0"
local BUSY = { [4] = true, [700] = true }
local RETRIES = 3

deezer.SECRET = "g4el58wc0zvf9na1"
deezer.AGENT = AGENT

local session = {}

function deezer.encode(text)
	return (tostring(text):gsub("[^%w%-_%.~]", function(char) return string.format("%%%02X", char:byte()) end))
end

function deezer.arl()
	local arl = nari.get("arl")
	if not arl or arl == "" then
		error("Not signed in to Deezer", 0)
	end
	return arl
end

function deezer.read_arl(text)
	local trimmed = tostring(text or ""):match("^%s*(.-)%s*$")
	local found = trimmed:match("arl=([%x]+)") or trimmed
	if #found >= 32 and found:match("^%x+$") then
		return found
	end
end

local function decode(response, what)
	if not response then
		error("Deezer can't be reached right now (" .. what .. ")", 0)
	end
	local ok, data = pcall(nari.json_decode, response.body)
	if not ok or type(data) ~= "table" then
		error("Deezer answered " .. what .. " with something unexpected (status " .. tostring(response.status) .. ")", 0)
	end
	return data
end

local function failure(error_field)
	if type(error_field) ~= "table" or next(error_field) == nil then
		return nil
	end
	local parts = {}
	for key, value in pairs(error_field) do
		table.insert(parts, type(key) == "string" and (key .. ": " .. tostring(value)) or tostring(value))
	end
	return table.concat(parts, ", ")
end

local function gw_raw(method, token, body)
	local url = GATEWAY .. "?method=" .. deezer.encode(method) .. "&input=3&api_version=1.0&api_token=" .. deezer.encode(token or "")
		.. "&cid=" .. math.random(100000000, 999999999)
	local cookie = "arl=" .. deezer.arl() .. (session.sid and ("; sid=" .. session.sid) or "")
	local response, problem = nari.http({
		method = "POST",
		url = url,
		headers = { Cookie = cookie, ["Content-Type"] = "text/plain;charset=UTF-8", ["User-Agent"] = AGENT },
		body = type(body) == "string" and body or nari.json_encode(body or {}),
	})
	local answer = decode(response or nil, method .. (problem and (": " .. problem) or ""))
	session.sid = (response.headers["set-cookie"] or ""):match("%f[%w]sid=([^;%s]+)") or session.sid
	local trouble = failure(answer.error)
	if trouble then
		return nil, trouble
	end
	return answer.results
end

local function plan(options)
	local function covers(keys)
		local seen, on = false, false
		for _, key in ipairs(keys) do
			local value = options[key]
			if value ~= nil then
				seen = true
				on = on or value == true or value == 1 or value == "1"
			end
		end
		return not seen or on
	end
	if covers({ "web_lossless", "mobile_lossless" }) then
		return 1
	elseif covers({ "web_hq", "mobile_hq" }) then
		return 2
	end
	return 3
end

function deezer.connect(fresh)
	local key = deezer.arl() .. ":" .. (nari.get("profile") or "")
	if session.token and session.key == key and not fresh then
		return session
	end
	session = {}
	local ping = gw_raw("deezer.ping", "", {})
	session.sid = ping and ping.SESSION or session.sid
	local results, problem = gw_raw("deezer.getUserData", "", {})
	if not results then
		error("Deezer didn't open a session: " .. tostring(problem), 0)
	end
	local main = { value = tostring((results.USER or {}).USER_ID or 0), label = (results.USER or {}).BLOG_NAME or "Deezer" }
	local wanted = nari.get("profile")
	if wanted and wanted ~= main.value then
		gw_raw("user.loginMulti", results.checkForm or results.CHECKFORM or "", { account_id = tonumber(wanted) })
		results = gw_raw("deezer.getUserData", "", {}) or {}
		if tostring((results.USER or {}).USER_ID) ~= wanted then
			session = {}
			error("Deezer didn't open that Family profile, pick it again in Settings", 0)
		end
	end
	local user = results.USER or {}
	local id = tostring(user.USER_ID or 0)
	if id == "0" or id == "" then
		session = {}
		error("Deezer didn't accept this sign in, sign in again", 0)
	end
	local options = user.OPTIONS or {}
	session.token = results.checkForm or results.CHECKFORM or ""
	session.license = options.license_token or ""
	session.user_id = id
	session.name = user.BLOG_NAME or "Deezer"
	session.loved = tostring(user.LOVEDTRACKS_ID or "")
	session.plan = plan(options)
	session.offer = results.OFFER_NAME or ""
	session.country = results.COUNTRY or ""
	session.main = main
	session.key = key
	return session
end

function deezer.profiles()
	local current = deezer.session()
	local list = { current.main }
	local ok, children = pcall(gw_raw, "deezer.getChildAccounts", current.token, {})
	for _, child in ipairs(ok and type(children) == "table" and children or {}) do
		local id = tostring(child.USER_ID or "")
		local loggable = (type(child.EXTRA_FAMILY) == "table" and child.EXTRA_FAMILY or {}).IS_LOGGABLE_AS
		if id ~= "" and id ~= current.main.value and loggable ~= false and loggable ~= 0 and loggable ~= "0" then
			table.insert(list, { value = id, label = child.BLOG_NAME or id })
		end
	end
	return list
end

function deezer.session()
	return deezer.connect(false)
end

function deezer.gw(method, body)
	local current = deezer.session()
	local results, problem = gw_raw(method, current.token, body)
	if results ~= nil then
		return results
	end
	deezer.connect(true)
	results = gw_raw(method, session.token, body)
	if results == nil then
		error("Deezer refused " .. method .. ": " .. tostring(problem), 0)
	end
	return results
end

function deezer.public(path)
	local last
	for _ = 0, RETRIES do
		local response, problem = nari.http({ url = PUBLIC .. path, headers = { ["User-Agent"] = AGENT } })
		local answer = decode(response, path .. (problem and (": " .. problem) or ""))
		local trouble = answer.error
		if type(trouble) ~= "table" then
			return answer
		end
		last = trouble.message or trouble.type or "error"
		if not BUSY[tonumber(trouble.code) or 0] then
			break
		end
	end
	error("Deezer refused " .. path .. ": " .. tostring(last), 0)
end

function deezer.list(answer)
	if type(answer) ~= "table" then
		return {}
	end
	return answer.data or answer
end

local function text(value, keys)
	for _, key in ipairs(keys) do
		local found = value[key]
		if type(found) == "string" and found ~= "" then
			return found
		elseif type(found) == "number" then
			return tostring(math.tointeger(found) or found)
		end
	end
end

local function number(value, keys)
	for _, key in ipairs(keys) do
		local found = tonumber(value[key])
		if found then
			return math.tointeger(found) or math.floor(found)
		end
	end
end

local function utc_time(fields)
	local now = os.time()
	return os.time(fields) + os.difftime(now, os.time(os.date("!*t", now)))
end

local function stamp(value, keys)
	for _, key in ipairs(keys) do
		local found = value[key]
		if tonumber(found) then
			return math.tointeger(tonumber(found)) or math.floor(tonumber(found))
		end
		if type(found) == "string" then
			local year, month, day, hour, min, sec = found:match("^(%d+)%-(%d+)%-(%d+)[ T]?(%d*):?(%d*):?(%d*)")
			if year and tonumber(year) > 1900 then
				return math.floor(utc_time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = tonumber(hour) or 12, min = tonumber(min) or 0, sec = tonumber(sec) or 0 }))
			end
		end
	end
end

local function hashed(md5)
	return type(md5) == "string" and md5 ~= "" and md5:gsub("-", ""):match("^%x+$") ~= nil
end

function deezer.image(kind, md5, size)
	if hashed(md5) then
		return "https://cdn-images.dzcdn.net/images/" .. kind .. "/" .. md5 .. "/" .. size .. "x" .. size .. "-000000-80-0-0.jpg"
	end
end

local function art(kind, md5, big, small)
	local large = deezer.image(kind, md5, 1000) or big
	if large then
		return { large, deezer.image(kind, md5, 264) or small or large }
	end
end

local function year_of(value)
	local date = text(value, { "release_date", "PHYSICAL_RELEASE_DATE", "DIGITAL_RELEASE_DATE", "ORIGINAL_RELEASE_DATE" }) or ""
	return tonumber(date:match("^(%d%d%d%d)")) or 0
end

function deezer.artist_id(id)
	return id and id ~= "" and id ~= "0" and ("ar" .. id) or ""
end

function deezer.playlist_id(id)
	return "pl" .. id
end

function deezer.raw_id(id)
	return (tostring(id):gsub("^%a%a", ""))
end

local function artists_of(value)
	local names, ids = {}, {}
	local function add(name, id)
		if name and name ~= "" then
			for _, known in ipairs(names) do
				if known == name then
					return
				end
			end
			table.insert(names, name)
			table.insert(ids, id and tostring(id) or "")
		end
	end
	if type(value.ARTISTS) == "table" and #value.ARTISTS > 0 then
		for _, artist in ipairs(value.ARTISTS) do
			add(artist.ART_NAME, artist.ART_ID)
		end
	elseif type(value.contributors) == "table" and #value.contributors > 0 then
		for _, artist in ipairs(value.contributors) do
			if artist.role == nil or artist.role == "Main" then
				add(artist.name, artist.id)
			end
		end
	end
	if #names == 0 then
		if type(value.artist) == "table" then
			add(value.artist.name, value.artist.id)
		else
			add(text(value, { "ART_NAME", "artist_name" }), text(value, { "ART_ID" }))
		end
	end
	return names, ids
end

local function versioned(title, version)
	version = version and version:match("^%s*(.-)%s*$") or ""
	if version ~= "" and not title:find(version, 1, true) then
		return title .. " " .. version
	end
	return title
end

function deezer.track(value)
	if type(value) ~= "table" then
		return nil
	end
	local id = text(value, { "SNG_ID", "id" })
	if not id or id == "0" then
		return nil
	end
	local album = type(value.album) == "table" and value.album or {}
	local names, ids = artists_of(value)
	local album_md5 = text(album, { "md5_image" }) or text(value, { "ALB_PICTURE", "md5_image" })
	return {
		id = id,
		title = versioned(text(value, { "SNG_TITLE", "title" }) or "", text(value, { "VERSION" })),
		artist = table.concat(names, ", "),
		artists = names,
		artist_id = deezer.artist_id(ids[1]),
		album = text(album, { "title" }) or text(value, { "ALB_TITLE" }) or "",
		album_id = text(album, { "id" }) or text(value, { "ALB_ID" }) or "",
		duration = (number(value, { "DURATION", "duration" }) or 0) * 1000,
		track_number = number(value, { "TRACK_NUMBER", "track_position" }) or 0,
		disc_number = number(value, { "DISK_NUMBER", "disk_number" }) or 1,
		year = year_of(value) ~= 0 and year_of(value) or year_of(album),
		explicit = value.EXPLICIT_LYRICS == "1" or value.EXPLICIT_LYRICS == 1 or value.explicit_lyrics == true or nil,
		genres = {},
		file_name = "",
		liked_at = stamp(value, { "DATE_FAVORITE", "DATE_ADD", "time_add" }),
		art = art("cover", album_md5, album.cover_xl or album.cover_big, album.cover_medium),
	}
end

function deezer.album(value)
	if type(value) ~= "table" then
		return nil
	end
	local id = text(value, { "ALB_ID", "id" })
	if not id or id == "0" then
		return nil
	end
	local names, ids = artists_of(value)
	local genres = {}
	for _, genre in ipairs(type(value.genres) == "table" and value.genres.data or {}) do
		table.insert(genres, genre.name)
	end
	local kind = text(value, { "record_type" }) or ({ ["0"] = "single", ["1"] = "album", ["2"] = "compile", ["3"] = "ep" })[text(value, { "TYPE" }) or ""]
	return {
		id = id,
		title = text(value, { "ALB_TITLE", "title" }) or "",
		artist = table.concat(names, ", "),
		artists = names,
		artist_id = deezer.artist_id(ids[1]),
		year = year_of(value),
		song_count = number(value, { "NB_SONG", "NUMBER_TRACK", "nb_tracks" }) or 0,
		duration = (number(value, { "DURATION", "duration" }) or 0) * 1000,
		genres = genres,
		label = text(value, { "LABEL_NAME", "label" }),
		release_type = ({ single = "single", ep = "single", compile = "compilation", album = "album" })[kind or ""] or "album",
		liked_at = stamp(value, { "DATE_FAVORITE", "DATE_ADD", "time_add" }),
		art = art("cover", text(value, { "ALB_PICTURE", "md5_image" }), value.cover_xl or value.cover_big, value.cover_medium),
	}
end

function deezer.artist(value)
	if type(value) ~= "table" then
		return nil
	end
	local id = text(value, { "ART_ID", "id" })
	if not id or id == "0" then
		return nil
	end
	local md5 = text(value, { "ART_PICTURE", "md5_image" })
	if not hashed(md5) and type(value.picture_xl) == "string" then
		md5 = value.picture_xl:match("/images/artist/([%x]+)/")
	end
	return {
		id = deezer.artist_id(id),
		name = text(value, { "ART_NAME", "name" }) or "",
		album_count = number(value, { "NB_ALBUM", "nb_album" }) or 0,
		song_count = 0,
		fans = number(value, { "NB_FAN", "nb_fan" }),
		cover_album_id = deezer.artist_id(id),
		liked_at = stamp(value, { "DATE_FAVORITE", "DATE_ADD", "time_add" }),
		art = art("artist", md5, value.picture_xl or value.picture_big, value.picture_medium),
	}
end

function deezer.playlist(value)
	if type(value) ~= "table" then
		return nil
	end
	local id = text(value, { "PLAYLIST_ID", "id" })
	if not id or id == "0" then
		return nil
	end
	local creator = type(value.creator) == "table" and value.creator or type(value.user) == "table" and value.user or {}
	local kind = text(value, { "PICTURE_TYPE", "picture_type" }) or "playlist"
	local cover = art(kind, text(value, { "PLAYLIST_PICTURE", "md5_image" }), value.picture_xl or value.picture_big, value.picture_medium)
	return {
		id = deezer.playlist_id(id),
		name = text(value, { "TITLE", "title" }) or "",
		song_count = number(value, { "NB_SONG", "nb_tracks" }) or 0,
		duration = (number(value, { "DURATION", "duration" }) or 0) * 1000,
		modified = stamp(value, { "DATE_MOD", "mod_date" }) or 0,
		cover_album_ids = { deezer.playlist_id(id) },
		image = "",
		owner = text(value, { "PARENT_USERNAME", "CREATOR_NAME" }) or creator.name or "",
		owner_id = text(value, { "PARENT_USER_ID" }) or (creator.id and tostring(creator.id)) or "",
		description = text(value, { "DESCRIPTION", "description" }),
		art = cover,
	}
end

function deezer.map(list, parse)
	local found = {}
	for _, value in ipairs(list or {}) do
		local item = parse(value)
		if item then
			table.insert(found, item)
		end
	end
	return found
end

function deezer.key(id)
	local hash = nari.md5(id)
	local key = {}
	for index = 1, 16 do
		key[index] = string.char(hash:byte(index) ~ hash:byte(index + 16) ~ deezer.SECRET:byte(index))
	end
	return table.concat(key)
end

return deezer

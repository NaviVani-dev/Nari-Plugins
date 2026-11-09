local deezer = require("deezer")

local MEDIA = "https://media.deezer.com/v1/get_url"
local BLOCK = 2048
local CHUNK = BLOCK * 192
local IV = "\0\1\2\3\4\5\6\7"
local FORMATS = { "FLAC", "MP3_320", "MP3_128" }
local FIRST = { original = 1, high = 2, normal = 3, low = 3 }
local UPLOAD = "MP3_MISC"
local OFFLINE_DAYS = 30

local function cipher_for(id)
	return nari.cipher({ algorithm = "blowfish-cbc", key = deezer.key(id), iv = IV })
end

local function decrypt(cipher, data, start)
	local parts = {}
	local first = start // BLOCK
	for offset = 1, #data, BLOCK do
		local block = data:sub(offset, offset + BLOCK - 1)
		if (first + (offset - 1) // BLOCK) % 3 == 0 and #block == BLOCK then
			cipher:reset()
			block = cipher:update(block)
		end
		table.insert(parts, block)
	end
	return table.concat(parts)
end

local function play(out, size, cipher, read)
	out:size(size)
	local count = (size + CHUNK - 1) // CHUNK
	local done = {}
	local cursor = 0
	while true do
		local wanted = out:wanted()
		if wanted then
			cursor = wanted // CHUNK
		end
		local index
		for step = 0, count - 1 do
			local candidate = (cursor + step) % count
			if not done[candidate] then
				index = candidate
				break
			end
		end
		if not index then
			return
		end
		done[index] = true
		if out:write(decrypt(cipher, read(index), index * CHUNK), index * CHUNK) == false then
			return
		end
		cursor = index + 1
	end
end

local function track_data(id)
	local data = deezer.gw("song.getData", { SNG_ID = id })
	if type(data.FALLBACK) == "table" and data.FALLBACK.SNG_ID then
		data = data.FALLBACK
	end
	if not data.TRACK_TOKEN or data.TRACK_TOKEN == "" then
		error("Deezer can't play this song in your country", 0)
	end
	return data
end

local function formats(id, quality)
	if id:sub(1, 1) == "-" then
		return { UPLOAD }
	end
	local list = {}
	for index = math.max(FIRST[quality] or 1, deezer.session().plan), #FORMATS do
		table.insert(list, FORMATS[index])
	end
	return list
end

local function stream_url(token, format)
	local response, problem = nari.http({
		method = "POST",
		url = MEDIA,
		headers = { ["Content-Type"] = "application/json", ["User-Agent"] = deezer.AGENT },
		body = nari.json_encode({
			license_token = deezer.session().license,
			media = { { type = "FULL", formats = { { cipher = "BF_CBC_STRIPE", format = format } } } },
			track_tokens = { token },
		}),
	})
	if not response then
		error("Deezer's media server can't be reached: " .. tostring(problem), 0)
	end
	local ok, answer = pcall(nari.json_decode, response.body)
	local entry = ok and type(answer) == "table" and type(answer.data) == "table" and answer.data[1] or nil
	if not entry or (type(entry.errors) == "table" and #entry.errors > 0) then
		return nil, entry and entry.errors and entry.errors[1] and entry.errors[1].message or "not licensed"
	end
	local media = entry.media and entry.media[1]
	local source = media and media.sources and media.sources[1]
	return source and source.url
end

local function resolve(id, quality)
	local data = track_data(id)
	local effective = tostring(data.SNG_ID)
	local last = "no format was offered"
	for _, format in ipairs(formats(effective, quality)) do
		local url, problem = stream_url(data.TRACK_TOKEN, format)
		if url then
			return url, effective, format
		end
		last = format .. ": " .. tostring(problem)
	end
	error("Deezer has no stream for this song (" .. last .. ")", 0)
end

local function fetch(url, from, to)
	local response, problem = nari.http({ url = url, headers = { Range = "bytes=" .. from .. "-" .. to, ["User-Agent"] = deezer.AGENT } })
	if not response or (response.status ~= 206 and response.status ~= 200) then
		error("the song couldn't be downloaded: " .. tostring(problem or response.status), 0)
	end
	return response
end

local function unescape(text)
	return (text:gsub("%%(%x%x)", function(pair) return string.char(tonumber(pair, 16)) end))
end

local function play_offline(id, path, out)
	local effective = (nari.get("offline_ids") or {})[id]
	if not effective then
		error("This download can't be opened anymore, download it again", 0)
	end
	if os.time() - (nari.get("offline_checked") or 0) > OFFLINE_DAYS * 86400 then
		error("Go online so Deezer can confirm your subscription, then your downloads play again", 0)
	end
	local file = io.open(path, "rb")
	if not file then
		error("The downloaded song is missing", 0)
	end
	local size = file:seek("end")
	play(out, size, cipher_for(effective), function(index)
		file:seek("set", index * CHUNK)
		return file:read(CHUNK) or ""
	end)
	file:close()
end

local function save(id, effective, size, read, out)
	out:size(size)
	for index = 0, (size + CHUNK - 1) // CHUNK - 1 do
		if out:write(read(index)) == false then
			return
		end
	end
	local ids = nari.get("offline_ids") or {}
	ids[id] = effective
	nari.set("offline_ids", ids, { private = true })
end

nari.source("deezer", function(raw, out)
	local id = raw:match("^[^?]*")
	local offline = raw:match("[?&]offline=([^?&]+)")
	if offline then
		return play_offline(id, unescape(offline), out)
	end
	local saving = raw:find("[?&]save$") ~= nil
	local quality = raw:match("[?&]quality=(%a+)") or "original"
	local url, effective = resolve(id, quality)
	local first = fetch(url, 0, CHUNK - 1)
	local size = first.status == 200 and #first.body or tonumber((first.headers["content-range"] or ""):match("/(%d+)"))
	if not size then
		error("Deezer didn't say how big the song is", 0)
	end
	local function read(index)
		if index == 0 or first.status == 200 then
			return first.body:sub(index * CHUNK + 1, (index + 1) * CHUNK)
		end
		return fetch(url, index * CHUNK, math.min(size, (index + 1) * CHUNK) - 1).body
	end
	if saving then
		return save(id, effective, size, read, out)
	end
	play(out, size, cipher_for(effective), read)
end, { save = "sealed" })

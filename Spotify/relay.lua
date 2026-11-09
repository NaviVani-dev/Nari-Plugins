local auth = require("auth")
local spotify = require("spotify")

local STATE = "https://spclient.wg.spotify.com/connect-state/v1"
local VOLUME_MAX = 65535

local function random_id(size)
	return (nari.random_bytes(size):gsub(".", function(char) return string.format("%02x", char:byte()) end))
end

local function send(method, path, body)
	spotify.request(method, STATE .. path, nari.json_encode(body), { ["Content-Type"] = "application/json", Accept = "application/json" })
	return {}
end

local function route(from, to)
	return "/from/" .. (from or auth.device_id()) .. "/to/" .. (to or auth.device_id())
end

local actions = {}

function actions.command(message)
	local body = message.command
	body.options = body.options or { override_restrictions = false, only_for_local_device = false, system_initiated = false }
	body.logging_params = { command_id = random_id(16), page_instance_ids = { "nari" }, interaction_ids = { random_id(16) } }
	return send("POST", "/player/command" .. route(nil, message.to), { command = body })
end

function actions.volume(message)
	return send("PUT", "/connect/volume" .. route(nil, message.to), { volume = math.floor(message.volume * VOLUME_MAX + 0.5) })
end

function actions.transfer(message)
	local restore = message.resume and "resume" or message.paused and "pause" or "restore"
	return send("POST", "/connect/transfer" .. route(message.from, message.to), { transfer_options = { restore_paused = restore } })
end

nari.on("message", function(message)
	local ok, result = pcall(actions[message.action], message)
	result = ok and result or { error = tostring(result) }
	result.request = message.request
	nari.send(result)
end)

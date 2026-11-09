local TIMEOUT = 10
local POLL = 0.05
local DRAIN = 0.002
local TEXT, BINARY, CLOSE, PING, PONG = 1, 2, 8, 9, 10

local Dealer = {}
Dealer.__index = Dealer

local function mask(payload, key)
	local word = string.unpack("<I4", key)
	local out, size = {}, #payload
	local whole = size - size % 4
	for position = 1, whole, 4 do
		out[#out + 1] = string.pack("<I4", string.unpack("<I4", payload, position) ~ word)
	end
	for position = whole + 1, size do
		out[#out + 1] = string.char(payload:byte(position) ~ key:byte(position - whole))
	end
	return table.concat(out)
end

local function frame(opcode, payload)
	local size = #payload
	local header = string.char(0x80 | opcode)
	if size < 126 then
		header = header .. string.char(0x80 | size)
	elseif size < 65536 then
		header = header .. string.char(0x80 | 126) .. string.pack(">I2", size)
	else
		header = header .. string.char(0x80 | 127) .. string.pack(">I8", size)
	end
	local key = nari.random_bytes(4)
	return header .. key .. mask(payload, key)
end

function Dealer:send(text)
	if self.closed then
		return false
	end
	return self.socket:send(frame(TEXT, text))
end

function Dealer:close()
	if not self.closed then
		self.closed = true
		pcall(self.socket.send, self.socket, frame(CLOSE, ""))
		self.socket:close()
	end
end

function Dealer:finish(problem)
	if not self.closed then
		self.closed = true
		self.socket:close()
		self.handlers.close(problem)
	end
end

function Dealer:handle(opcode, final, payload)
	if opcode == PING then
		self.socket:send(frame(PONG, payload))
	elseif opcode == CLOSE then
		self:finish("the dealer closed the connection")
	elseif opcode == TEXT or opcode == BINARY or opcode == 0 then
		self.parts[#self.parts + 1] = payload
		if final then
			local message = table.concat(self.parts)
			self.parts = {}
			self.handlers.message(message)
		end
	end
end

function Dealer:receive(bytes)
	self.buffer = self.buffer .. bytes
	while not self.closed do
		local buffer = self.buffer
		if #buffer < 2 then
			return
		end
		local first, second = buffer:byte(1, 2)
		local size, offset = second & 0x7f, 3
		if size == 126 then
			if #buffer < 4 then
				return
			end
			size, offset = string.unpack(">I2", buffer, 3), 5
		elseif size == 127 then
			if #buffer < 10 then
				return
			end
			size, offset = string.unpack(">I8", buffer, 3), 11
		end
		local key
		if second & 0x80 ~= 0 then
			key, offset = buffer:sub(offset, offset + 3), offset + 4
		end
		if #buffer < offset + size - 1 then
			return
		end
		local payload = buffer:sub(offset, offset + size - 1)
		self.buffer = buffer:sub(offset + size)
		self:handle(first & 0x0f, first & 0x80 ~= 0, key and mask(payload, key) or payload)
	end
end

function Dealer:poll()
	if self.closed then
		return
	end
	local data, problem = self.socket:receive(nil, DRAIN)
	while data do
		self:receive(data)
		if self.closed then
			return
		end
		data, problem = self.socket:receive(nil, DRAIN)
	end
	if problem ~= "timeout" then
		return self:finish(problem or "the dealer connection closed")
	end
	nari.after(POLL, function() self:poll() end)
end

local dealer = {}

function dealer.open(address, token, handlers)
	local host, port = address:match("^(.-):(%d+)$")
	host, port = host or address, tonumber(port) or 443
	local socket, problem = nari.tcp({ host = host, port = port, tls = true, timeout = TIMEOUT })
	if not socket then
		return nil, problem
	end
	socket:send(table.concat({
		"GET /?access_token=" .. token .. " HTTP/1.1",
		"Host: " .. host,
		"Upgrade: websocket",
		"Connection: Upgrade",
		"Sec-WebSocket-Key: " .. nari.base64_encode(nari.random_bytes(16)),
		"Sec-WebSocket-Version: 13",
		"",
		"",
	}, "\r\n"))
	local reply = ""
	while not reply:find("\r\n\r\n", 1, true) do
		local data, failure = socket:receive(nil, TIMEOUT)
		if not data then
			socket:close()
			return nil, failure
		end
		reply = reply .. data
	end
	local head, rest = reply:match("^(.-)\r\n\r\n(.*)$")
	if not head:match("^HTTP/1%.1 101") then
		socket:close()
		return nil, "the dealer answered " .. (head:match("^HTTP/[%d.]+ ([^\r\n]*)") or "something unexpected")
	end
	local connection = setmetatable({ socket = socket, handlers = handlers, buffer = "", parts = {}, closed = false }, Dealer)
	if rest ~= "" then
		connection:receive(rest)
	end
	connection:poll()
	return connection
end

return dealer

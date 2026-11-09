local LENGTH_BASE = { 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258 }
local LENGTH_EXTRA = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0 }
local DISTANCE_BASE = {
	1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
	1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
}
local DISTANCE_EXTRA = { 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13 }
local CODE_ORDER = { 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 }
local MAX_BITS = 15
local CHUNK = 4096

local inflate = {}

local function huffman(lengths, count)
	local counts, symbols, offsets = {}, {}, {}
	for size = 0, MAX_BITS do
		counts[size] = 0
	end
	for symbol = 0, count - 1 do
		local size = lengths[symbol] or 0
		counts[size] = counts[size] + 1
	end
	offsets[1] = 0
	for size = 1, MAX_BITS - 1 do
		offsets[size + 1] = offsets[size] + counts[size]
	end
	for symbol = 0, count - 1 do
		local size = lengths[symbol] or 0
		if size > 0 then
			symbols[offsets[size]] = symbol
			offsets[size] = offsets[size] + 1
		end
	end
	return { counts = counts, symbols = symbols }
end

local FIXED_LENGTHS, FIXED_DISTANCES
do
	local lengths, distances = {}, {}
	for symbol = 0, 287 do
		lengths[symbol] = symbol < 144 and 8 or symbol < 256 and 9 or symbol < 280 and 7 or 8
	end
	for symbol = 0, 29 do
		distances[symbol] = 5
	end
	FIXED_LENGTHS, FIXED_DISTANCES = huffman(lengths, 288), huffman(distances, 30)
end

local Stream = {}
Stream.__index = Stream

function Stream:bits(count)
	local value, held = self.buffer, self.held
	while held < count do
		local byte = self.data:byte(self.position)
		if not byte then
			error("the compressed data ended early", 0)
		end
		self.position = self.position + 1
		value = value | (byte << held)
		held = held + 8
	end
	self.buffer, self.held = value >> count, held - count
	return value & ((1 << count) - 1)
end

function Stream:decode(tree)
	local code, first, index = 0, 0, 0
	for size = 1, MAX_BITS do
		code = code | self:bits(1)
		local count = tree.counts[size]
		if code - count < first then
			return tree.symbols[index + code - first]
		end
		index = index + count
		first = (first + count) << 1
		code = code << 1
	end
	error("the compressed data is damaged", 0)
end

function Stream:stored()
	self.buffer, self.held = 0, 0
	local size = string.unpack("<I2", self.data, self.position)
	self.position = self.position + 4
	local out = self.out
	for index = self.position, self.position + size - 1 do
		out[#out + 1] = self.data:byte(index)
	end
	self.position = self.position + size
end

function Stream:codes(lengths, distances)
	local out = self.out
	while true do
		local symbol = self:decode(lengths)
		if symbol < 256 then
			out[#out + 1] = symbol
		elseif symbol == 256 then
			return
		else
			symbol = symbol - 256
			local size = LENGTH_BASE[symbol] + self:bits(LENGTH_EXTRA[symbol])
			local code = self:decode(distances) + 1
			local from = #out - DISTANCE_BASE[code] - self:bits(DISTANCE_EXTRA[code]) + 1
			for offset = 0, size - 1 do
				out[#out + 1] = out[from + offset]
			end
		end
	end
end

function Stream:dynamic()
	local literals, distances, codes = self:bits(5) + 257, self:bits(5) + 1, self:bits(4) + 4
	local sizes = {}
	for index = 1, codes do
		sizes[CODE_ORDER[index]] = self:bits(3)
	end
	local tree = huffman(sizes, 19)
	local lengths, index = {}, 0
	while index < literals + distances do
		local symbol = self:decode(tree)
		if symbol < 16 then
			lengths[index] = symbol
			index = index + 1
		else
			local value, repeats = 0, 0
			if symbol == 16 then
				value, repeats = lengths[index - 1], 3 + self:bits(2)
			elseif symbol == 17 then
				repeats = 3 + self:bits(3)
			else
				repeats = 11 + self:bits(7)
			end
			for _ = 1, repeats do
				lengths[index] = value
				index = index + 1
			end
		end
	end
	local literal_lengths, distance_lengths = {}, {}
	for symbol = 0, literals - 1 do
		literal_lengths[symbol] = lengths[symbol]
	end
	for symbol = 0, distances - 1 do
		distance_lengths[symbol] = lengths[literals + symbol]
	end
	self:codes(huffman(literal_lengths, literals), huffman(distance_lengths, distances))
end

function inflate.raw(data, position)
	local stream = setmetatable({ data = data, position = position or 1, buffer = 0, held = 0, out = {} }, Stream)
	repeat
		local last = stream:bits(1)
		local kind = stream:bits(2)
		if kind == 0 then
			stream:stored()
		elseif kind == 1 then
			stream:codes(FIXED_LENGTHS, FIXED_DISTANCES)
		elseif kind == 2 then
			stream:dynamic()
		else
			error("the compressed data is damaged", 0)
		end
	until last == 1
	local parts, out = {}, stream.out
	for from = 1, #out, CHUNK do
		parts[#parts + 1] = string.char(table.unpack(out, from, math.min(from + CHUNK - 1, #out)))
	end
	return table.concat(parts)
end

function inflate.gunzip(data)
	if data:byte(1) ~= 0x1f or data:byte(2) ~= 0x8b then
		return data
	end
	local flags, position = data:byte(4), 11
	if flags & 4 ~= 0 then
		position = position + 2 + string.unpack("<I2", data, position)
	end
	for _, flag in ipairs({ 8, 16 }) do
		if flags & flag ~= 0 then
			position = data:find("\0", position, true) + 1
		end
	end
	if flags & 2 ~= 0 then
		position = position + 2
	end
	return inflate.raw(data, position)
end

return inflate

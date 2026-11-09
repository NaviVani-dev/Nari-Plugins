local lib = require("lib")

local HOST = { 182, 218, 218, 239, 239, 218, 195, 164, 134, 115, 120, 110, 115, 106, 86, 91, 92, 97, 84, 83, 77, 70, 62, 59, 59, 53, 50, 48, 43, 40, 36, 25 }
local HOST_RANGE = { 74, 59, 59, 35, 35, 52, 59, 60, 54, 50, 51, 44, 40, 50, 39, 35, 38, 35, 33, 28, 23, 27, 20, 20, 20, 17, 17, 19, 13, 12, 12, 9 }
local BAND = { 185, 192, 169, 153, 138, 134, 142, 148, 154, 151, 144, 141, 144, 146, 154, 160, 167, 174, 169, 172, 173, 168, 162, 163, 168, 163, 158, 158, 157, 154, 147, 126 }
local BAND_RANGE = { 28, 24, 35, 40, 40, 39, 36, 38, 33, 35, 35, 37, 37, 36, 37, 33, 29, 30, 30, 29, 28, 30, 27, 27, 26, 25, 25, 27, 24, 25, 26, 28 }
local BIN_HZ = 44100 / 2048
local SPAN = math.log(400)

local slots = {}

local function slot(bin)
	local found = slots[bin]
	if not found then
		local hertz = math.max(bin, 0.5) * BIN_HZ
		found = math.max(0, math.min(30.999, 32 * math.log(hertz / 40) / SPAN - 0.5))
		slots[bin] = found
	end
	return found
end

local function mapped(bands, band)
	local value = HOST[band] + ((bands[band] or 0) * 255 - BAND[band]) * HOST_RANGE[band] / BAND_RANGE[band]
	return math.max(0, math.min(255, value))
end

local bins = {}

function bins.frequency(audio, bin, channel)
	if audio.stereo then
		return audio.stereo:byte(math.max(0, math.min(1023, math.floor(bin))) + (channel or 0) * 1024 + 1)
	end
	local bands = audio.bands or {}
	local at = slot(bin)
	local index = math.floor(at)
	local a, b = mapped(bands, index + 1), mapped(bands, index + 2)
	return a + (b - a) * (at - index)
end

function bins.wave(audio, index, channel)
	if audio.stereo then
		return audio.stereo:byte(math.max(0, math.min(1023, math.floor(index))) + (channel or 0) * 1024 + 2049)
	end
	return 128 + 127 * lib.sample(audio, index / 1023)
end

function bins.sample(audio, position, channel)
	if audio.stereo then
		return (bins.wave(audio, position * 1023, channel) - 128) / 127
	end
	return lib.sample(audio, position)
end

function bins.linear(audio, position, channel)
	local value = bins.frequency(audio, position * 1024, channel) / 255
	if audio.stereo then
		return value
	end
	return value * (1 - math.max(0, position - 0.7) * 2.5)
end

function bins.spiky(audio, bin, channel, spread)
	local value = bins.frequency(audio, bin, channel)
	if audio.stereo then
		return value
	end
	return math.min(255, value * (1 + (math.sqrt(-math.log(1 - math.random() * 0.999)) - 0.886) * spread))
end

function bins.both(audio, bin)
	if audio.stereo then
		return bins.frequency(audio, bin, 0) + bins.frequency(audio, bin, 1)
	end
	return 2 * bins.frequency(audio, bin)
end

function bins.shrunk(audio, index, channel)
	return bins.peak(audio, index * 4, index * 4 + 3, channel)
end

function bins.mean(audio, channel, stride)
	local total = 0
	for bin = 0, 1023, stride do
		total = total + bins.frequency(audio, bin, channel)
	end
	return total * stride / 1024
end

function bins.top(audio, channel)
	if audio.stereo then
		local offset = (channel or 0) * 1024 + 2049
		return math.max(audio.stereo:byte(offset, offset + 1023))
	end
	local top = 0
	for _, sample in ipairs(audio.wave or {}) do
		top = math.max(top, sample * 127 + 128)
	end
	return top
end

function bins.range(audio, count, channel)
	if audio.stereo then
		local offset = (channel or 0) * 1024 + 1
		return { audio.stereo:byte(offset, offset + count - 1) }
	end
	local list = {}
	for bin = 0, count - 1 do
		list[bin + 1] = bins.spiky(audio, bin, channel, 0.5)
	end
	return list
end

function bins.band(audio, position, floor)
	if audio.stereo then
		return bins.frequency(audio, 40 * 400 ^ math.max(0, math.min(1, position)) / BIN_HZ) / 255
	end
	return lib.lift(lib.spectrum(audio, position), floor)
end

function bins.grain(audio)
	if audio.stereo then
		return 1
	end
	return (-2 * math.log(1 - math.random())) ^ 0.25 / 1.078
end

function bins.peak(audio, first, last, channel)
	if audio.stereo then
		local offset = (channel or 0) * 1024 + 1
		return math.max(audio.stereo:byte(first + offset, last + offset))
	end
	return bins.frequency(audio, (first + last) / 2)
end

return bins

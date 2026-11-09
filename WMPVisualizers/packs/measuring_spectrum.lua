local spectrum = {}

local FIRST = 40.0
local RATIO = math.log(400.0) / 32.0
local BIN = 44100.0 / 2048.0

function spectrum.position(frequency)
	return math.log(math.max(frequency, FIRST) / FIRST) / RATIO - 0.5
end

function spectrum.at(audio, position)
	local at = math.max(0.0, math.min(31.0, position))
	local index = math.floor(at)
	local bands = audio.bands
	local a, b = bands[index + 1] or 0, bands[math.min(index + 2, 32)] or 0
	local value = a + (b - a) * (at - index)
	if value <= 0 then
		return 0.0
	end
	return math.min(255.0, 10.0 ^ ((value * 66.0 - 66.0 - at * 0.9) / 40.0) * 905.0)
end

function spectrum.bin(audio, bin, channel)
	if audio.stereo then
		return audio.stereo:byte(math.max(0, math.min(1023, math.floor(bin))) + (channel or 0) * 1024 + 1)
	end
	return spectrum.at(audio, spectrum.position((bin + 0.5) * BIN))
end

function spectrum.range(audio, first, last)
	local total = 0.0
	local step = math.max(1, math.floor((last - first + 1) / 8))
	for bin = first, last, step do
		total = total + spectrum.bin(audio, bin) * step
	end
	return total
end

return spectrum

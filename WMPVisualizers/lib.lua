local lib = {}

local function interpolate(values, position)
	local count = #values
	if count == 0 then
		return 0
	end
	local scaled = math.max(0, math.min(1, position)) * (count - 1)
	local index = math.floor(scaled)
	local a = values[index + 1] or 0
	local b = values[math.min(index + 2, count)] or a
	return a + (b - a) * (scaled - index)
end

function lib.sample(audio, position)
	return interpolate(audio.wave or {}, position)
end

function lib.spectrum(audio, position)
	return interpolate(audio.bands or {}, position)
end

function lib.peak(audio, position)
	return interpolate(audio.peaks or {}, position)
end

function lib.band(audio, index)
	return (audio.bands or {})[index] or 0
end

function lib.lift(value, floor)
	return math.max(0, (value - floor) / (1 - floor))
end

function lib.alpha(color, amount)
	return Color(color.r, color.g, color.b, amount)
end

function lib.hsv(hue, saturation, value)
	local function channel(offset)
		local k = (hue * 6 + offset) % 6
		local level = math.max(0, math.min(1, math.abs(k - 3) - 1))
		return value * (1 - saturation + saturation * level) * 1.0
	end
	return Color(channel(0), channel(4), channel(2), 1)
end

function lib.mix(a, b, t)
	return Color(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
end

function lib.mountain(canvas, audio, scene, options)
	local width, height = scene.width, scene.height
	local columns = options.columns or 96
	local base = options.base or height
	local reach = options.height or height * 0.8
	local direction = options.down and 1 or -1
	local floor = options.floor or 0.35
	for column = 0, columns - 1 do
		local left, right = column / columns, (column + 1) / columns
		local function value(position)
			local at = options.mirror and 0.06 + math.abs(position - 0.5) * 1.88 or position
			if options.inverse then
				at = 1 - at
			end
			return lib.lift(lib.spectrum(audio, at), floor)
		end
		local a, b = value(left), value(right)
		local top_a, top_b = base + direction * a * reach, base + direction * b * reach
		local tip = options.top or options.bottom
		local color_a = lib.mix(options.bottom, tip, a)
		local color_b = lib.mix(options.bottom, tip, b)
		canvas:draw_polygon({ Vector2(left * width, base), Vector2(right * width, base), Vector2(right * width, top_b), Vector2(left * width, top_a) }, { options.bottom, options.bottom, color_b, color_a })
	end
end

return lib

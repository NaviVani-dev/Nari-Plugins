local bins = require("packs.wmp_bins")

local CLEAR = "shaders/common/clear.gdshader"

local function glow(name, red, green, blue)
	return {
		name = name,
		layers = { CLEAR },
		draw = function(canvas, _, audio, scene)
			local value = bins.wave(audio, 0) / 255
			canvas:draw_rect(Rect2(0, 0, scene.width, scene.height), Color(red * value, green * value, blue * value, 1.0))
		end,
	}
end

return {
	name = "Glow",
	presets = {
		glow("Glow Red", 1.0, 0.0, 0.0),
		glow("Glow Green", 0.0, 1.0, 0.0),
		glow("Glow Blue", 0.0, 0.0, 1.0),
	},
}

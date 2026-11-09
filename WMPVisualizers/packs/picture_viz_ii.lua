local base = require("packs.picture_viz")

local BASIC = { "pop", "transparency", "zoom", "curtains", "dissolve", "toaster", "swipe", "rotate" }
local GEOMETRIC = { "pattern", "spiral", "spotlight", "squares", "variegate", "spin", "bullseye", "radial" }
local PARTICLE = { "wetglass", "flourish", "twirl", "disperse", "seagrass", "ripple", "transport", "dematerialize" }
local ALL = { "pop", "transparency", "zoom", "curtains", "dissolve", "toaster", "swipe", "rotate", "pattern", "wetglass", "spiral", "flourish", "undulation", "spotlight", "twirl", "disperse", "seagrass", "ripple", "squares", "transport", "variegate", "suck", "dematerialize", "spin", "bullseye", "radial" }

local function walk(state)
	local index = state.walk or 1
	index = index + math.random(4)
	if index > #ALL then
		index = math.random(2)
	end
	state.walk = index
	return ALL[index]
end

local function preset(name, ...)
	return base.make(name, { ... }, true)
end

return {
	name = "Picture Viz II",
	presets = {
		preset("Favorite Transitions", "pop"),
		base.make("Random Selection - Basic Transitions", BASIC, true),
		base.make("Random Selection - Geometric Transitions", GEOMETRIC, true),
		base.make("Random Selection - Particle Transitions", PARTICLE, true),
		base.make("Random Selection - All Transitions", walk, true),
		preset("Basic - Pop Transition", "pop"),
		preset("Basic - Transparency Transition", "transparency"),
		preset("Basic - Zoom Transition", "zoom"),
		preset("Basic - Curtains", "curtains"),
		preset("Basic - Dissolve Transition", "dissolve"),
		preset("Basic - Toaster", "toaster"),
		preset("Basic - Swipe", "swipe"),
		preset("Basic - Rotate", "rotate"),
		preset("Pattern", "pattern"),
		preset("WetGlass", "wetglass"),
		preset("Spiral", "spiral"),
		preset("Flourish", "flourish"),
		preset("Undulation", "undulation"),
		preset("SpotLight", "spotlight"),
		preset("Twirl Transition", "twirl"),
		preset("Disperse", "disperse"),
		preset("SeaGrass", "seagrass"),
		preset("Ripple", "ripple"),
		preset("SquareS", "squares"),
		preset("Transport", "transport"),
		preset("Variegate", "variegate"),
		preset("Suck Transition", "suck"),
		preset("Dematerialize", "dematerialize"),
		preset("Spin", "spin"),
		preset("BullsEye", "bullseye"),
		preset("Radial", "radial"),
	},
}

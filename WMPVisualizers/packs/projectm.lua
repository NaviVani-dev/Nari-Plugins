local milkdrop = require("packs.milkdrop")
local index = require("packs.projectm_presets")

local presets = {}
for _, item in ipairs(index) do
	local bucket, slot = item[2], item[3]
	presets[#presets + 1] = milkdrop.make(item[1], function()
		return require(string.format("packs.projectm_presets_%02d", bucket))[slot]
	end)
end

return {
	name = "projectM",
	presets = presets,
}

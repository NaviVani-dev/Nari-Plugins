local engine = require("engine")

local LIGHT_LEVEL = 0.6
local DARK_LEVEL = 0.4

local PACKS = {
	"alchemy",
	"alchemy_3d",
	"ambience",
	"battery",
	"musical_colors",
	"media_player",
	"bars_and_waves",
	"spikes",
	"particles",
	"plenoptic",
	"microsoft",
	"blazing_colors",
	"color_cubes",
	"eclectic_colors",
	"dungeon_siege",
	"glow",
	"googly_moogly",
	"better_bars",
	"picture_viz",
	"picture_viz_ii",
	"lorvis",
	"measuring_sound",
	"glass3d",
	"pthalos_corona",
	"pulsing_colors",
	"shacojin",
	"snowtime",
	"special",
	"startime",
	"sticksterz",
	"pixeltrip",
	"trilogy_i",
	"trilogy_ii",
	"trilogy_iii",
	"wm3dspectrum",
	"album_art_3d",
	"bubbles",
	"distortion",
	"gigertron",
	"hypnobloom",
	"ribbons",
	"up_cuber",
	"winter_wave",
	"softie_ii",
	"grind",
	"looney_tunes",
	"terminator3",
	"yule_log",
	"sticky",
	"analyzed",
	"around_the_world",
	"twisted_pixel",
	"crazy_lines",
	"spectrum",
	"chinese_new_year",
	"fruity",
	"home_of_the_brave",
	"projectm",
	"goom",
	"celestial",
	"clarify",
	"fire_dancer",
	"ripple",
}

local QUALITIES = {
	{ value = 240, label = "Low" },
	{ value = 360, label = "Medium" },
	{ value = 540, label = "High" },
	{ value = 720, label = "Very high" },
}

local packs, order = {}, {}
for _, id in ipairs(PACKS) do
	local pack = require("packs." .. id)
	pack.id = id
	packs[id] = pack
	order[#order + 1] = pack
end

local current = { area = nil, scene = nil, preset = nil }

local function category()
	local id = nari.get("category")
	return packs[id] or order[1]
end

local function chosen()
	return nari.get("preset")
end

local function quality()
	return tonumber(nari.get("quality")) or 360
end

local function find(pack, name)
	for index, preset in ipairs(pack.presets) do
		if preset.name == name then
			return index
		end
	end
	return nil
end

local function preset_of(pack)
	return find(pack, chosen()) or 1
end

local function clear(area)
	for _, child in ipairs(area:get_children()) do
		child:queue_free()
	end
end

local function show(index)
	local area = current.area
	if not area or not area:is_inside_tree() then
		return
	end
	local pack = category()
	index = index or preset_of(pack)
	clear(area)
	current.preset = index
	current.pack = pack.id
	current.tone = nil
	current.scene = engine.new(area, pack.presets[index], quality(), nari.get("stretch") == true)
end

local function refresh()
	if current.area and current.area:is_inside_tree() then
		current.preset = nil
		show()
	end
end

local function choose(pack, preset)
	nari.set("category", pack.id)
	nari.set("preset", preset)
	refresh()
end

local function menu()
	local sorted = {}
	for _, pack in ipairs(order) do
		sorted[#sorted + 1] = pack
	end
	table.sort(sorted, function(a, b) return a.name:lower() < b.name:lower() end)
	local active = category()
	local entries = {}
	for _, pack in ipairs(sorted) do
		local here = pack == active
		local items = {}
		for _, preset in ipairs(pack.presets) do
			items[#items + 1] = { title = preset.name, chosen = here and chosen() == preset.name, action = function() choose(pack, preset.name) end }
		end
		entries[#entries + 1] = { title = pack.name, items = items }
	end
	return entries
end

local function shade()
	local pack = packs[current.pack or ""]
	local preset = pack and pack.presets[current.preset or 0]
	local hinted = (preset and preset.light or pack and pack.light) and "light" or "dark"
	local level = current.scene and engine.brightness(current.scene)
	if level == nil then
		return current.tone or hinted
	end
	if level > LIGHT_LEVEL then
		current.tone = "light"
	elseif level < DARK_LEVEL then
		current.tone = "dark"
	end
	current.tone = current.tone or hinted
	return current.tone
end

nari.visualizer({
	name = "Windows Media Player",
	transparent = false,
	shade = shade,
	menu = menu,
	build = function(area)
		if current.unhook then
			current.unhook()
		end
		current.area = area
		current.preset = nil
		current.unhook = area.tree_exiting:connect(function()
			current.area = nil
			current.scene = nil
			current.unhook = nil
		end)
		show()
	end,
	update = function(data)
		local scene = current.scene
		if not scene or not current.area or not current.area:is_inside_tree() then
			return
		end
		data.stereo = nari.spectrum and nari.spectrum()
		engine.step(scene, data)
	end,
})

nari.settings(function()
	local function label(options, value)
		for _, option in ipairs(options) do
			if tostring(option.value) == tostring(value) then
				return option.label
			end
		end
		return tostring(value)
	end
	return {
		{
			title = "Allow deformation",
			description = "Stretch visualizations with images to fill the area, as the originals did",
			value = function() return nari.get("stretch") == true and "On" or "Off" end,
			checked = function() return nari.get("stretch") == true end,
			action = function()
				nari.set("stretch", nari.get("stretch") ~= true)
				refresh()
			end,
		},
		{
			title = "Quality",
			description = "Resolution of the visualization, lower is faster",
			value = function() return label(QUALITIES, quality()) end,
			choices = {
				options = QUALITIES,
				get = quality,
				set = function(value)
					nari.set("quality", tonumber(value))
					refresh()
				end,
			},
		},
	}
end)

nari.command("wmp", "Shows a WMP visualization: wmp <category> [preset number]", function(args)
	if not args[1] then
		local names = {}
		for _, item in ipairs(order) do
			names[#names + 1] = item.id .. " (" .. #item.presets .. ")"
		end
		return table.concat(names, ", ")
	end
	if not packs[args[1]] then
		return "unknown category " .. args[1]
	end
	nari.set("category", args[1])
	local pack = packs[args[1]]
	local number = tonumber(args[2])
	nari.set("preset", number and pack.presets[number] and pack.presets[number].name or pack.presets[1].name)
	refresh()
	return pack.name .. ": " .. pack.presets[current.preset or 1].name
end)

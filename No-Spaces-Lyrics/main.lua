local KEYS = { text = true, translation = true, romanized_text = true }

local function squash(value)
	local changed = false
	for key, item in pairs(value) do
		if type(item) == "table" then
			changed = squash(item) or changed
		elseif KEYS[key] and type(item) == "string" and item:find(" ", 1, true) then
			value[key] = item:gsub(" ", "")
			changed = true
		end
	end
	return changed
end

MediaPlayer.lyrics.lyrics_ready:connect(function(song_id, lyrics)
	if squash(lyrics) then
		nari.after(0, function()
			MediaPlayer.lyrics.lyrics_ready:emit(song_id, lyrics)
		end)
	end
end)

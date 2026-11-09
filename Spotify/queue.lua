local queue = {}

function queue.index()
	return math.floor(tonumber(MediaPlayer:get_playback_state().index) or -1)
end

function queue.read(done)
	local value = MediaPlayer:get_queue()
	if type(value) == "table" then
		return done(value)
	end
	nari.await(value, function(songs) done(type(songs) == "table" and songs or {}) end)
end

return queue

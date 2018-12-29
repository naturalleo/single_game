local log_util = {}

function log_util.isDebug()
	return false
end

function log_util.i(TAG, ...)
	local msg = TAG .. ":"
	for i, v in ipairs(table.pack(...)) do
		if type(v) == 'boolean' then
			local m = 'false'
			if v then
				m = 'true'
			end
			msg = msg .. m		
		else
			msg = msg .. v
		end
	end
	print(msg)
end

function log_util.e(TAG, ...)
	log_util.i(TAG, ...)
end

function log_util.d(TAG, ...)
	log_util.i(TAG, ...)
end


return log_util
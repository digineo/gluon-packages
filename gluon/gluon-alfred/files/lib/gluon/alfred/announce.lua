#!/usr/bin/lua

local alfred_data_type = 158
local announce_dir = '/lib/gluon/alfred/announce.d'


fs = require 'luci.fs'
uci = require('luci.model.uci').cursor()
util = require 'luci.util'


local json = require 'luci.json'
local ltn12 = require 'luci.ltn12'


local function collect_entry(entry)
	if fs.isdirectory(entry) then
		return collect_dir(entry)
	else
		return dofile(entry)
	end
end

function collect_dir(dir)
	local ret = {}

	for _, entry in ipairs(fs.dir(dir)) do
		if entry:sub(1, 1) ~= '.' then
			local ok, val = pcall(collect_entry, dir .. '/' .. entry)
			if ok then
				ret[entry] = val
			else
				io.stderr:write(val, '\n')
			end
		end
	end

	return ret
end


encoder = json.Encoder(collect_dir(announce_dir))
alfred = io.popen('gzip | alfred -s ' .. tostring(alfred_data_type), 'w')
ltn12.pump.all(encoder:source(), ltn12.sink.file(alfred))

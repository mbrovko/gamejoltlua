local md5 = require "md5" 
local http = require "socket.http"

local GJ = {
	gameID, gameKey,
	isLoggedIn = false,
	username, userToken
}

local BASE_URL = "http://gamejolt.com/api/game/v1/"

local function req(s, f, pu, pt)
	local url = BASE_URL .. s .. "&game_id=" .. tostring(GJ.gameID) .. "&format=" .. f
	if pu then url = url .. "&username=" .. GJ.username end
	if pt then url = url .. "&user_token=" .. GJ.userToken end

	local b = md5.sumhexa(url .. GJ.gameKey)
	url = url .. "&signature=" .. b

	local r, e = http.request(url)
	return r
end

function parseKeypair(s, on)
	local c, len = 0, string.len(s)
	local b, k, v

	while c < len do
		b = string.find(s, ":", c)
		if b == nil then break end
		k = string.sub(s, c, b - 1)
		c = b + 2
		b = string.find(s, '"', c)
		v = string.sub(s, c, b - 1)
		c = b + 2
		on(k, v)
	end
end

function GJ.init(id, key)
	GJ.gameID = id
	GJ.gameKey = key
end

-- users
function GJ.authUser(name, token)
	GJ.username = name
	GJ.userToken = token

	local s = string.find(req("users/auth/?", "dump", true, true), "SUCCESS") ~= nil
	GJ.isLoggedIn = s
	return s
end

function GJ.fetchUserByName(name)
	local r = req("users/?username=" .. name, "keypair", false, false)

	local t = {}
	parseKeypair(r, function(k, v)
		t[k] = v
	end)
	
	return t
end

function GJ.fetchUserByID(id)
	local r = req("users/?user_id=" .. id, "keypair", false, false)

	local t = {}
	parseKeypair(r, function(k, v)
		t[k] = v
	end)
	
	return t
end

-- sessions
function GJ.openSession()
	return string.find(req("sessions/open/?", "dump", true, true), "SUCCESS") ~= nil
end

function GJ.pingSession(active)
	local status = "idle"
	if active then status = "active" end

	return string.find(req("sessions/open/?status=" .. status, "dump", true, true), "SUCCESS") ~= nil
end

function GJ.closeSession()
	return string.find(req("sessions/close/?", "dump", true, true), "SUCCESS") ~= nil
end

-- data store
function GJ.fetchData(key, isGlobal)
	local pu, pt = true, true
	if isGlobal then pu, pt = false, false end

	local d = req("data-store/?key=" .. key, "dump", pu, pt)
	return string.sub(d, string.find(d, "\n"), string.len(d))
end

function GJ.setData(key, data, isGlobal)
	local pu, pt = true, true
	if isGlobal then pu, pt = false, false end

	return string.find(req("data-store/set/?key=" .. key .. "&data=" .. tostring(data), "dump", pu, pt), "SUCCESS") ~= nil
end

return GJ
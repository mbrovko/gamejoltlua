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

-- sessions
function GJ.openSession()
	return string.find(req("sessions/open/?", "dump", true, true), "SUCCESS") ~= nil
end

return GJ
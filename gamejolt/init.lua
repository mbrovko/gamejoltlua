local folder = ({...})[1]:gsub('%.init$', '')
local md5 = require(folder .. ".md5" )
local http = require("socket.http")

local GJ = {
	gameID, gameKey,
	isLoggedIn = false,
	username, userToken,
	trophies = {}
}

local BASE_URL = "http://gamejolt.com/api/game/v1/"

local escape = function (a)
	return tostring(a):gsub("([^%w%-%.%_])",function (a)
		return string.format("%%%02X",string.byte(a))
	end)
end

local function req(s, f, pu, pt, data)
	local url = BASE_URL .. s .. "&game_id=" .. tostring(GJ.gameID) .. "&format=" .. f
	if pu then url = url .. "&username=" .. GJ.username end
	if pt then url = url .. "&user_token=" .. GJ.userToken end

	local b = md5.sumhexa(url .. GJ.gameKey)
	url = url .. "&signature=" .. b

	local r, e = http.request(url, data)
	return r
end

local function parseKeypair(s, on)
	local c, len = 0, string.len(s)
	local b, k, v

	while c < len do
		b = string.find(s, ":", c)
		if b == nil then break end
		k = string.sub(s, c, b - 1)
		c = b + 2
		b = string.find(s, '"', c)
		v = string.sub(s, c, b - 1)
		c = b + 3
		on(k, v)
	end
end

local function handleTrophies(str)
	local d = req("trophies/?" .. str, "keypair", true, true)
	local t, f = {}

	parseKeypair(d, function(k, v)
		if k ~= "success" then
			if k == "id" then
				f = {}
				table.insert(t, f)
			end
			f[k] = v
		end
	end)
	return t
end

function GJ.init(id, key, args)
	GJ.gameID = id
	GJ.gameKey = key

	if args and type(args)=="table" then
		for k,v in pairs(args) do
			local a = v:match("^gjapi_(.*)")

			if a then
				key, value = a:match("^(.-)=(.-)$")

				if key == "username" then
					GJ.username = value
				elseif key == "token" then
					GJ.userToken = value
				end
			end
		end
	end
end

function GJ.getCredentials(dir)
	local f = io.open(dir.."gjapi-credentials.txt")

	if f then
		GJ.username = f:read()
		GJ.userToken = f:read()
	end

	if GJ.username and GJ.userToken then
		return true, GJ.username, GJ.userToken
	else
		return false, "Couldn't find, open or read the \"gjapi-credentials.txt\" file"
	end
end

-- users
function GJ.authUser(name, token)
	GJ.username = name or GJ.username or ""
	GJ.userToken = token or GJ.userToken or ""

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

	return string.find(req("sessions/ping/?status=" .. status, "dump", true, true), "SUCCESS") ~= nil
end

function GJ.closeSession()
	return string.find(req("sessions/close/?", "dump", true, true), "SUCCESS") ~= nil
end

-- data store
function GJ.fetchData(key, isGlobal)
	local pu, pt = true, true
	if isGlobal then pu, pt = false, false end

	local d = req("data-store/?key=" .. escape(key), "dump", pu, pt)

	return string.sub(d, string.find(d, "\n"), string.len(d))
end

function GJ.setData(key, data, isGlobal)
	local pu, pt = true, true
	if isGlobal then pu, pt = false, false end

	return string.find(req("data-store/set/?key=" .. escape(key) .. '&data=' .. escape(data), "dump", pu, pt), "SUCCESS") ~= nil
end

function GJ.setBigData(key, data, isGlobal)
	local pu, pt = true, true
	if isGlobal then pu, pt = false, false end

	return string.find(req("data-store/set/?key=" .. escape(key), "dump", pu, pt, "data="..escape(data)), "SUCCESS") ~= nil
end

function GJ.updateData(key, value, operation, isGlobal)
	local pu, pt = true, true
	if isGlobal then pu, pt = false, false end

	local d = req("data-store/update/?key=" .. escape(key) .. "&operation=" .. operation .. "&value=" .. escape(value), "dump", pu, pt)
	return string.sub(d, string.find(d, "\n"), string.len(d))
end

function GJ.removeData(key, isGlobal)
	local pu, pt = true, true
	if isGlobal then pu, pt = false, false end

	return string.find(req("data-store/remove/?key=" .. escape(key), "dump", pu, pt), "SUCCESS") ~= nil
end

function GJ.fetchStorageKeys(isGlobal)
	local pu, pt = true, true
	if isGlobal then pu, pt = false, false end

	local d = req("data-store/get-keys/?", "keypair", pu, pt)

	local t = {}
	parseKeypair(d, function(k, v)
		if k ~= "success" then table.insert(t, v) end
	end)

	return t
end

-- trophies
function GJ.giveTrophy(id)
	local s = string.find(req("trophies/add-achieved/?trophy_id=" .. id, "dump", true, true), "SUCCESS") ~= nil
	GJ.fetchAllTrophies(true)
	return s
end

function GJ.fetchTrophy(id)
	local d = req("trophies/?trophy_id=" .. tostring(id), "keypair", true, true)

	local t = {}
	parseKeypair(d, function(k, v)
		if k ~= "success" then t[k] = v end
	end)
	return t
end

function GJ.fetchTrophiesByStatus(achieved)
	return handleTrophies("achieved=" .. (achieved and "true" or "false"))
end

function GJ.fetchAllTrophies(f)
	if f then
		GJ.trophies = handleTrophies("")
	end
	return GJ.trophies
end

-- scores
function GJ.addScore(score, desc, tableID, guestName, extraData)
	local pu, pt, s = true, true, ""
	if guestName then pu, pt, s = false, false, s .. "&guest=" .. escape(guestName) end

	if extraData then s = s .. "&extra_data=" .. escape(extraData) end
	if tableID then s = s .. "&table_id=" .. escape(tableID) end

	return string.find(req("scores/add/?score=" .. escape(desc) .. "&sort=" .. score .. s, "dump", pu, pt), "SUCCESS") ~= nil
end

function GJ.fetchScores(limit, tableID)
	local pu, pt, s = true, true, ""
	if tableID then pu, pt, s = false, false, "&table_id=" .. escape(tableID) end

	local d = req("scores/?limit=" .. (tonumber(limit or "") or 10) .. s, "keypair", pu, pt)
	local t, f = {}

	parseKeypair(d, function(k, v)
		if k ~= "success" then
			if k == "score" then
				f = {}
				table.insert(t, f)
			end
			f[k] = v
		end
	end)
	return t
end

function GJ.fetchTables()
	local d = req("scores/tables/?", "keypair", false, false)
	local t, f = {}

	parseKeypair(d, function(k, v)
		if k ~= "success" then
			if k == "id" then
				f = {}
				table.insert(t, f)
			end
			f[k] = v
		end
	end)
	return t
end

return GJ

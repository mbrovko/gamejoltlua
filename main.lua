local GJ = require "gamejolt"

nextcolor={
	{255,0,0};
	{255,255,0};
	{0,255,0};
	{0,255,255};
	{0,0,255};
	{255,0,255}
}
color={0,0,0}
i = 1

times = {}

love.load = function (args)
	GJ.init("48362","a82abf886842e78dd6b7e74dfdc96fff",args)
	
	if GJ.getCredentials and GJ.getCredentials() then
		if not GJ.authUser() then
			error "Couldnt authenticate"
		end
	else
		if not GJ.authUser("Positive07","e20d75") then
			error "Couldnt authenticate Positive"
		end
	end
	
	GJ.openSession()
	
	GJ.removeData("mydata", true)
	GJ.removeData("setBigData", true)
	GJ.removeData("setData", true)
	
	local data = "Hello world, this is my data string"
	print (data)
	
	if not GJ.pingSession(true) then error "Timeout" end
	
	local a = love.timer.getTime()
	local s = GJ.setData("setData",data,true)
	times[#times + 1] = love.timer.getTime() - a
	
	if not GJ.pingSession(true) then error "Timeout" end
	
	if not s then
		print "Whops, normal setData cant do it"
	else
		local a = love.timer.getTime()
		local d = GJ.fetchData("setData",true)
		times[#times + 1] = love.timer.getTime() - a
		
		if not GJ.pingSession(true) then error "Timeout" end

		if d ~= data then
			print ("Whops the data is not right: "..d)
		else
			print "Well whatever"
		end
	end
	
	local a = love.timer.getTime()
	local su = GJ.setBigData and GJ.setBigData("setBigData",data,true) or false
	times[#times + 1] = love.timer.getTime() - a
	
	if not GJ.pingSession(true) then error "Timeout" end
	
	if not su then
		print "Whops, setBigData cant do it"
	else
		local a = love.timer.getTime()
		local d = GJ.fetchData("setBigData",true)
		times[#times + 1] = love.timer.getTime() - a
		
		local _,d,_ = d:match("^(%s*)(.-)(%s*)$")
		
		if not GJ.pingSession(true) then error "Timeout" end

		if d ~= data then
			print ("Whops the data is not right: "..d)
		else
			print "Yeah setBigData rocks"
		end
	end
	
	GJ.closeSession()
end

love.update = function (dt)
	for j = 1, 3 do
		color[j] = color[j] + (((nextcolor[i][j] - color[j])>0 and 1) or ((nextcolor[i][j] - color[j])<0 and -1) or 0)
		color[j] = math.ceil(color[j])
		if color[1] == nextcolor[i][1] and color[3] == nextcolor[i][3] and color[2] == nextcolor[i][2] then
			i = (i>=6 and 1) or i+1
		end
	end
end

love.draw = function ()
	love.graphics.setBackgroundColor(color)
	for i=1, #times do
		love.graphics.print(times[i],10,10 + 20*(i-1))
	end
end
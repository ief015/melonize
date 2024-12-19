
concommand.Add( "melonize", function(ply,cmd,args)
	net.Start("imM_melonizeSelf")
	net.WriteEntity(ply)
	local mdl = args[1]
	if mdl == nil then
		net.WriteBit(false)
	else
		net.WriteBit(true)
		net.WriteString(mdl)
	end
	net.SendToServer()
end,
function()
	return { "melonize [modelname]" }
end)

concommand.Add( "unmelonize", function(ply,cmd,args)
	net.Start("imM_unmelonizeSelf")
	net.WriteEntity(ply)
	net.SendToServer()
end)

concommand.Add( "melonizePlayer", function(ply,cmd,args)
	
	if not ply:IsAdmin() then MsgN("You must be admin to use this command.") return end
	if args[1] == nil then MsgN("No player specified.") return end
	
	local otherply = nil
	for k,v in pairs(player.GetAll()) do
		if string.StartWith(v:Nick(), args[1]) then
			otherply = v
			break
		end
	end
	
	if otherply == nil then MsgN("That player cannot be found.") return end
	
	net.Start("imM_melonizeAnother")
	
	net.WriteEntity(ply)
	net.WriteEntity(otherply)
	
	local mdl = args[2]
	if mdl == nil then
		net.WriteBit(false)
	else
		net.WriteBit(true)
		net.WriteString(mdl)
	end
	net.SendToServer()
end,
function()
	return { "melonizePlayer ply [modelname]" }
end)

concommand.Add( "unmelonizePlayer", function(ply,cmd,args)
	
	if not ply:IsAdmin() then MsgN("You must be admin to use this command.") return end
	if args[1] == nil then MsgN("No player specified.") return end
	
	local otherply = nil
	for k,v in pairs(player.GetAll()) do
		if string.StartWith(v:Nick(), args[1]) then
			otherply = v
			break
		end
	end
	
	if otherply == nil then MsgN("That player cannot be found.") return end
	
	net.Start("imM_unmelonizeAnother")
	
	net.WriteEntity(ply)
	net.WriteEntity(otherply)
	net.SendToServer()
end,
function()
	return { "unmelonizePlayer ply" }
end)

net.Receive("imM_onMelonized", function()
	
	local color_normal = Color(200, 255, 150)
	local color_highlight = Color(75, 225, 0)
	
	chat.AddText(color_normal, "You have been ", color_highlight, "Melonized", color_normal, "!")
	chat.AddText(color_normal, "\tHold ", color_highlight, "CROUCH", color_normal, " to speed up.")
	chat.AddText(color_normal, "\tPress ", color_highlight, "JUMP", color_normal, " to jump.")
	
end)

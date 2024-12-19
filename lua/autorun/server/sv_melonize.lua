local melonize = {}
melonize.ply = {}
melonize.speed = 100
melonize.on = true
melonize.adminonly = false

util.AddNetworkString( "imM_melonizeSelf" )
util.AddNetworkString( "imM_melonizeAnother" )
util.AddNetworkString( "imM_unmelonizeSelf" )
util.AddNetworkString( "imM_unmelonizeAnother" )
util.AddNetworkString( "imM_onMelonized" )

AddCSLuaFile("autorun/client/cl_melonize.lua")


CreateConVar("sv_melonize", 1)
cvars.AddChangeCallback( "sv_melonize", function()
	melonize.on = (GetConVarNumber("sv_melonize") ~= 0)
	
	Msg("Melonize addon ")
	if melonize.on then
		MsgN("enabled")
		for k,v in pairs( melonize.ply ) do
			v.ply:PrintMessage(HUD_PRINTTALK, "Melonize addon enabled")
		end
	else
		MsgN("disabled")
		for k,v in pairs( melonize.ply ) do
			v.ply:PrintMessage(HUD_PRINTTALK, "Melonize addon disabled")
			melonize.unmelonize(v.ply)
		end
	end
end)


CreateConVar("sv_melonize_adminonly", 0)
cvars.AddChangeCallback( "sv_melonize_adminonly", function()
	melonize.adminonly = (GetConVarNumber("sv_melonize_adminonly") ~= 0)
	
	for _, ply in pairs(player.GetAll()) do
		if melonize.adminonly then
			melonize.unmelonize(ply)
			ply:ChatPrint("Melonize is now only available for admins.")
		else
			ply:ChatPrint("Melonize is now enabled for all players.")
		end
	end
end)


melonize.setupPlayer = function(ply)
	
	melonize.ply[ply:SteamID()] = {}
	local p = melonize.ply[ply:SteamID()]
	
	p.melon = nil
	p.ply = ply
	p.lastJump = CurTime() - 1
	
end


melonize.melonize = function(ply, mdl)
	
	if not melonize.on then return end
	
	local p = melonize.ply[ply:SteamID()]
	
	melonize.unmelonize(ply)
	
	if not melonize.isMelon(ply) then
		
		mdl = mdl or "models/props_junk/watermelon01.mdl"
		
		local isRagdoll = util.IsValidRagdoll(mdl)
		
		local melon = ents.Create( isRagdoll and "prop_ragdoll" or "prop_physics" )
		melon:SetPos(ply:GetPos() + Vector(0,0,32))
		melon:SetModel(mdl)
		melon:Spawn()
		melon:Activate()
		
		p.melon = melon
		p.lastJump = CurTime()
		
		ply:StripWeapons()
		ply:Spectate(OBS_MODE_CHASE)
		ply:SpectateEntity( p.melon )
		
		net.Start("imM_onMelonized")
		net.Send(ply)
		
	end
	
end


melonize.unmelonize = function(ply)
	
	if melonize.isMelon(ply) then
		
		local p = melonize.ply[ply:SteamID()]
		
		ply:Spawn()
		ply:SetPos(p.melon:GetPos())
		ply:DropToFloor()
		
		p.melon:Remove()
		p.melon = nil
		
	end
	
end


melonize.isMelon = function(ply)
	
	if not ply:IsValid() or not ply:IsPlayer() then return false end
	
	ply = melonize.ply[ply:SteamID()]
	if ply ~= nil then
		return ply.melon ~= nil
	end
	return false
	
end


melonize.getMelon = function(ply)
	
	if not ply:IsValid() then return nil end
	
	ply = melonize.ply[ply:SteamID()]
	if ply ~= nil then
		return ply.melon
	end
	return nil
	
end


-- /////////////////////////////////
-- // Gamemode Event Hooks
-- /////////////////////////////////


hook.Add("PlayerInitialSpawn", "ihM_playerInit", function (ply)
	
	melonize.setupPlayer(ply)
	
end)


hook.Add("PlayerDisconnected", "ihM_playerQuit", function (ply)
	
	melonize.ply[ply:SteamID()] = nil
	
end)


hook.Add("PlayerSay", "ihM_playerSay", function (ply, txt)
	
	if not melonize.on then return end
	
	local cmd, args, hasArgs
	
	args = string.Explode(" ", txt)
	for k,v in pairs(args) do v = string.lower(v) end
	cmd = args[1] table.remove(args, 1)
	hasArgs = (#args > 0)
	
	if not string.StartWith(cmd, ".") then return end
	
	if cmd == ".melonize" or cmd == ".m" then
		
		if melonize.adminonly and not ply:IsAdmin() then
			ply:ChatPrint("You must be an admin to melonize.")
			return
		end
		
		-- Turn player into a melon! (or a prop)
		melonize.melonize(ply, hasArgs and args[1] or nil )
		
	elseif cmd == ".unmelonize" or cmd == ".um" then
		
		-- Turn the player back into a player.
		melonize.unmelonize(ply)
		
	else
	
		if melonize.isMelon(ply) then
			
			if cmd == ".weight" then
				
				local phys = melonize.getMelon(ply):GetPhysicsObject()
				
				if hasArgs then
					
					-- Set weight
					
					if phys then
					
						local weight = tonumber(args[1])
						
						if weight > 0 then
							phys:SetMass( weight )
							ply:PrintMessage(HUD_PRINTTALK, "Changed weight to " .. weight)
						else
							ply:PrintMessage(HUD_PRINTTALK, "Invalid weight. Must be larger than 0.")
						end
						
					end
					
				else
					
					-- Get weight
					
					if phys then
						
						ply:PrintMessage(HUD_PRINTTALK, "Your weight is " .. phys:GetMass())
						
					end
					
				end
				
			elseif cmd == ".color" or cmd == ".colour" then
				
				if hasArgs then
					
					-- Set colour
					
					local col = Color(
						tonumber(args[1]),
						tonumber(args[2]),
						tonumber(args[3]),
						(args[4]==nil) and 255 or tonumber(args[4]) )
					
					if col.a == 255 then
						melonize.getMelon(ply):SetRenderMode(RENDERMODE_NORMAL)
					else
						melonize.getMelon(ply):SetRenderMode(RENDERMODE_TRANSALPHA)
					end
					
					melonize.getMelon(ply):SetColor(col)
					ply:PrintMessage(HUD_PRINTTALK, "Changed colour to R:" .. col.r .. " G:" .. col.g .. " B:" .. col.b .. " A:" .. col.a)
					
				else
					
					-- Get colour
					
					local col = melonize.getMelon(ply):GetColor()
					ply:PrintMessage( HUD_PRINTTALK, "Your colour is R:" .. col.r .. " G:" .. col.g .. " B:" .. col.b .. " A:" .. col.a )
					
				end
				
			elseif cmd == ".material" then
				
				if hasArgs then
					
					-- Set material
					
					melonize.getMelon(ply):SetMaterial(args[1])
					ply:PrintMessage(HUD_PRINTTALK, "Changed material to " .. args[1])
					
				else
					
					-- Get material
					
					ply:PrintMessage( HUD_PRINTTALK, "Your material is " .. melonize.getMelon(ply):GetMaterial() )
					
				end
				
			end
		
		end -- if isMelon(ply)
		
	end -- command list
	
end)


hook.Add("Think", "ihM_think", function ()
	
	if not melonize.on then return end
	
	for k,v in pairs( melonize.ply ) do
		
		if v.ply then
		
			if melonize.isMelon(v.ply) then
				
				local ply = v.ply
				
				if not v.melon:IsValid() then
					
					local pos = ply:GetPos()
					ply:Spawn()
					ply:SetPos(pos)
					
					v.melon = nil
					
				else
					
					ply:SetPos(v.melon:GetPos())
					
					local speedMul = 1
					
					-- GO FAST
					if ply:KeyDown(IN_DUCK) then
						
						speedMul = 2
						
						local pos = v.melon:GetPos()
						local e = EffectData()
						e:SetStart(pos)
						e:SetOrigin(pos)
						e:SetScale(0.5)
						e:SetRadius(25)
						e:SetMagnitude(1)
						util.Effect("Sparks", e)
						
					end
					
					-- Go forward
					if ply:KeyDown(IN_FORWARD) then
						
						v.melon:GetPhysicsObject():ApplyForceCenter( ply:GetAngles():Forward() * melonize.speed * speedMul )
						
					end
					
					-- Go backward
					if ply:KeyDown(IN_BACK) then
						
						v.melon:GetPhysicsObject():ApplyForceCenter( ply:GetAngles():Forward()*-1 * melonize.speed * speedMul )
						
					end
					
					-- Go left
					if ply:KeyDown(IN_MOVELEFT) then
						
						v.melon:GetPhysicsObject():ApplyForceCenter( ply:GetAngles():Right()*-1 * melonize.speed * speedMul )
						
					end
					
					-- Go right
					if ply:KeyDown(IN_MOVERIGHT) then
						
						v.melon:GetPhysicsObject():ApplyForceCenter( ply:GetAngles():Right() * melonize.speed * speedMul )
						
					end
					
					-- Jump
					if ply:KeyDown(IN_JUMP) then
						if CurTime() - v.lastJump > 1 then
							
							v.lastJump = CurTime()
							v.melon:GetPhysicsObject():ApplyForceCenter( Vector( 0, 0, 3000 ) );
						
						end
					end
					
				end
				
			end
		
		end
		
	end
	
end );


net.Receive("imM_melonizeSelf", function()
	
	if not melonize.on then return end
	
	local ply = net.ReadEntity()
	
	if not ply:IsValid() then return end
	if not ply:IsPlayer() then return end
	
	if melonize.adminonly and not ply:IsAdmin() then
		ply:ChatPrint("You must be an admin to melonize.")
		return
	end
	
	local hasMdl = (net.ReadBit() == 1)
	
	if hasMdl then
		melonize.melonize(ply, net.ReadString())
	else
		melonize.melonize(ply)
	end
	
end)

net.Receive("imM_unmelonizeSelf", function()
	
	local ply = net.ReadEntity()
	if not ply:IsValid() then return end
	if not ply:IsPlayer() then return end
	melonize.unmelonize(ply)
	
end)

net.Receive("imM_melonizeAnother", function()
	
	if not melonize.on then return end
	
	local ply = net.ReadEntity()
	local otherply = net.ReadEntity()
	local hasMdl = (net.ReadBit() == 1)
	
	if not otherply:IsValid() then return end
	if not otherply:IsPlayer() then return end
	if not ply:IsValid() then return end
	if not ply:IsPlayer() then return end
	if not ply:IsAdmin() then return end
	
	if hasMdl then
		melonize.melonize(otherply, net.ReadString())
	else
		melonize.melonize(otherply)
	end
	
end)

net.Receive("imM_unmelonizeAnother", function()
	
	local ply = net.ReadEntity()
	local otherply = net.ReadEntity()
	
	if not otherply:IsValid() then return end
	if not otherply:IsPlayer() then return end
	if not ply:IsValid() then return end
	if not ply:IsPlayer() then return end
	if not ply:IsAdmin() then return end
	
	melonize.unmelonize(otherply)
	
end)

-- Load all players in case the script was loaded after the server was started.
for k,v in pairs( player.GetAll() ) do

	v:Spawn()
	melonize.setupPlayer(v)
	
end

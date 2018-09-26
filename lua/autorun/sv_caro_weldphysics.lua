CreateConVar("contraptionmode_trustedonly",1,FCVAR_REPLICATED)
if CLIENT then return end

//CreateConVar("contraptionmode_block_unfreeze_when_disabled",1)

CreateConVar("contraptionmode_use_delay",15)

util.AddNetworkString("SendContraptionMode")

util.AddNetworkString("cantcontraptionphysyet")

util.AddNetworkString("caro_contraptionmode_requesttoggle")

function AttemptSwitchContraptionMode(len, ply)
	if !GetConVar("contraptionmode_trustedonly"):GetBool() || (ply:GetUserGroup()!="user" && ply:GetUserGroup()!="guest") then
		
		if not ply.caro_GRABCONTRAPTIONMODE then ply.caro_GRABCONTRAPTIONMODE = false end

		ply.caro_GRABCONTRAPTIONMODE = !ply.caro_GRABCONTRAPTIONMODE
		net.Start("SendContraptionMode")
			net.WriteBool(ply.caro_GRABCONTRAPTIONMODE)
		net.Send(ply)
	end
end

net.Receive("caro_contraptionmode_requesttoggle",AttemptSwitchContraptionMode)


function superPhysgunPickup(player, ent)
	ent.SPW_collisionsFromGrab = {}

	if not player.caro_checkAllPhysgunned then player.caro_checkAllPhysgunned = {} end
	if not player.caro_GRABCONTRAPTIONMODE then player.caro_GRABCONTRAPTIONMODE = false end
	if not player.NEXTCONTRAPTIONGRAB then player.NEXTCONTRAPTIONGRAB=CurTime()-1 end

	if !player.caro_GRABCONTRAPTIONMODE then
		return
	end

	if player.NEXTCONTRAPTIONGRAB>CurTime() then
		net.Start("cantcontraptionphysyet")
			net.WriteInt(math.Round(player.NEXTCONTRAPTIONGRAB-CurTime()),16)
		net.Send(player)
		return false
	end

	if GetConVar("contraptionmode_trustedonly"):GetBool() && player.GetUserGroup && (player:GetUserGroup()=="user" || player:GetUserGroup()=="guest") then
		return
	end

	local CONSTR = constraint.GetAllConstrainedEntities( ent )
	for k,v in pairs(CONSTR || {}) do
		if IsValid(v) and v:IsValid() && v!=ent then
			
			for _k,_v in pairs(CONSTR) do
				//constraint.NoCollide(v,_v,0,0)
			end
			table.insert(player.caro_checkAllPhysgunned, v)
			v:SetParent(ent)

			v.SPW_oldCollisionGroup = v:GetCollisionGroup()
			v:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

			if not ent.SPW_collisionsFromGrab then
				ent.SPW_collisionsFromGrab = {}
			end

			table.insert(ent.SPW_collisionsFromGrab,v)

			if IsValid(v) and v:IsValid() then
				v:GetPhysicsObject():EnableMotion(true)
			end
		end
	end
	table.insert(player.caro_checkAllPhysgunned, ent)

	player.NEXTCONTRAPTIONGRAB = CurTime() + 30

end

hook.Add("PhysgunPickup","newsetposweld", superPhysgunPickup)


function IsTotallyInWorld(self)
	local Min,Max = self:GetCollisionBounds()
	Min = Min*0.8
	Max = Max*0.8

	local corners = {}
	table.insert(corners, Vector(Min.x, Min.y, Min.z) )
	table.insert(corners, Vector(Max.x, Min.y, Min.z) )
	table.insert(corners, Vector(Min.x, Max.y, Min.z) )
	table.insert(corners, Vector(Min.x, Min.y, Max.z) )
	table.insert(corners, Vector(Max.x, Max.y, Min.z) )
	table.insert(corners, Vector(Min.x, Max.y, Max.z) )
	table.insert(corners, Vector(Max.x, Min.y, Max.z) )
	table.insert(corners, Vector(Max.x, Max.y, Max.z) )

	local completelyinworld = true
	for k,v in pairs(corners) do
		if util.IsInWorld(self:GetPos()+self:OBBCenter()+v) then
			completelyinworld = false
		end
	end

	if completelyinworld then
		return true
	end

	return false
end

function superPhysgunDrop(player, ent)

	if !player.caro_GRABCONTRAPTIONMODE then return end

	if GetConVar("contraptionmode_trustedonly"):GetBool() && player.GetUserGroup && (player:GetUserGroup()=="user" || player:GetUserGroup()=="guest") then
		return
	end

	local allarescrewed = true

	for k,v in pairs(ent.SPW_collisionsFromGrab || {}) do
		if !IsTotallyInWorld(v) then 
			allarescrewed=false 
		end
	end

	if allarescrewed && IsTotallyInWorld(ent) then
		for k,v in pairs(ent.SPW_collisionsFromGrab) do
			v:Remove() 
		end
		ent:Remove()
		player:SendLua("notification.AddLegacy('We had to remove your stuff because it was inside the world :(',NOTIFY_CLEANUP,5)")
	end

	for k,v in pairs(ent.SPW_collisionsFromGrab || {}) do
		
		ent.SPW_collisionsFromGrab[k] = nil
		v:SetCollisionGroup(v.SPW_oldCollisionGroup)
		v:SetParent(nil)
		if IsValid(v) and v:IsValid() && v:GetPhysicsObject():IsMoveable() then
			v:GetPhysicsObject():EnableMotion(false)
		end
	end

	

	ent:GetPhysicsObject():EnableMotion(false)

end
hook.Add("PhysgunDrop","newsetposweld_drop", superPhysgunDrop)


hook.Add( "CanPlayerUnfreeze", "NoUnfreezeContraptionMode", function( ply, ent, phys )
	//CreateConVar("contraptionmode_block_unfreeze_when_disabled",1)

	if ply:KeyDown(IN_WALK) then
		return false
	end

	local CONSTR = ent.SPW_collisionsFromGrab
	for k,v in pairs(CONSTR || {}) do
		if IsValid(v) and v:IsValid() then
			for _k,_v in pairs(CONSTR) do
				if (_v!=v) then
					constraint.NoCollide(v,_v,0,0)
				end
			end
		end
	end
	
end )
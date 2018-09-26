print("cl_weldphysics")
if SERVER then 
	AddCSLuaFile()
	return 
end

caro_PLAYERHASCONTRAPTIONGRABENABLED = false
caro_physshowValues = false

function getContraptionModel(len)
	caro_PLAYERHASCONTRAPTIONGRABENABLED = net.ReadBool();
end
net.Receive("SendContraptionMode",getContraptionModel)


local function toggleCheck()
	local ply = LocalPlayer()
	// lol ^
	if ( ply:KeyDown(IN_RELOAD) && ply:KeyDown(IN_WALK) && (!ply:KeyDownLast(IN_RELOAD) || !ply:KeyDownLast(IN_WALK)) ) then
		net.Start("caro_contraptionmode_requesttoggle")
		net.SendToServer()
	end
end
hook.Add("Think","thinkabouttogglingcontraptionmode",toggleCheck)


function ContraptionModePaint()
	local cvar = GetConVar("contraptionmode_trustedonly")
	if (cvar && !cvar:GetBool()) || (LocalPlayer():GetUserGroup()!="user" && LocalPlayer():GetUserGroup()!="guest") then
		
		local wep = LocalPlayer():GetActiveWeapon()
		if IsValid(wep) && wep:GetClass()=="weapon_physgun" then
			surface.SetFont( "HudHintTextLarge" )
			surface.SetTextColor( 255, 255, 255, 255 )

			local posx, posy = ScrW()/2, ScrH()-80
			local string1 = ""
			
			if caro_PLAYERHASCONTRAPTIONGRABENABLED then
				string1 = "Contraption-Physgun Enabled"
			else
				string1 = "Contraption-Physgun Disabled"
			end

			local string2 = "Press WALK+RELOAD (Alt+R) to switch"
			local w, h = surface.GetTextSize( string1 )
			local w2, h2 = surface.GetTextSize( string2 )

			local ctr = ScrW()-w*1.5
			local posx = ctr-w/2
			local posx2= ctr-w2/2

			local string3 = "(ENTIRE CONTRAPTION WILL BE UNFROZEN ON GRAB)"
			local w3, h3 = surface.GetTextSize( string3 )
			local posx3= ctr-w3/2

			surface.SetDrawColor( 0, 0, 0, 128 )
			surface.DrawRect( ctr-math.max(w, w2)/2-6, ScrH()-83, math.max(w, w2)+16, h+h2+10)

			surface.SetTextPos( posx, posy )
			surface.DrawText( string1 )
			surface.SetTextPos( posx2, posy+14 )
			surface.DrawText( "Press WALK+RELOAD (Alt+R) to switch" )

			if caro_PLAYERHASCONTRAPTIONGRABENABLED then
				surface.SetDrawColor( 150, 0, 0, 200 )
				surface.DrawRect( ctr-w3/2-6, ScrH()-112, w3+14, h3*2)
				surface.SetTextPos( posx3, posy-25 )
				surface.DrawText(string3)
			end


			if caro_physshowValues then
				surface.SetDrawColor( 150, 0, 0, 200 )
				surface.DrawRect( ctr-w3/2-6, ScrH()-142, w3+14, h3*2)
				surface.SetTextPos( ScrW()/2-70, posy-55 )
				surface.DrawText('Please wait ' .. caro_weldphysics_timeleft .. ' seconds.')
			end

		end
	end
end

hook.Add("HUDPaint", "paintcontraptionmodphysgun", ContraptionModePaint)
-- Draw world p


net.Receive("cantcontraptionphysyet", function()

	caro_weldphysics_timeleft = net.ReadInt(16)
	caro_physshowValues = true

	timer.Create("physloadmessagetimer",0.2,0,function() caro_phys_loseMessage() end)
	//notification.AddLegacy('Physgun will act as it normally does.' ,NOTIFY_ERROR,5)
	//notification.AddLegacy('You still have to wait ' .. caro_weldphysics_timeleft .. ' seconds.' ,NOTIFY_ERROR,5)
	//notification.AddLegacy('You can only use the contraption physgun once every ' .. caro_weldphysics_usedelay .. ' seconds!',NOTIFY_ERROR,5)
	
end)

function caro_phys_loseMessage()
	caro_physshowValues = false
end

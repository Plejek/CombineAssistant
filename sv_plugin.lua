--[[
	This script has been purchased for "Blt950's HL2RP & Clockwork plugins" from CoderHire.com
	© 2014 Blt950 do not share, re-distribute or modify
	without permission.
--]]

/*
===================================================
================== CONFIGURATION ==================
===================================================
*/

local allowDispatch = {"SCN", "DvL", "SeC"} // This is a table representing which ranks are allowed to use the Dispatch through this menu.


/*
===================================================
============= DO NOT EDIT BELOW THIS ==============
===================================================
*/

util.AddNetworkString( "combineassistant" ) 
net.Receive( "combineassistant", function( len, pl )
	local type = net.ReadInt(32)
	local string = net.ReadString()
	
	if type == 1 then Clockwork.player:SayRadio(pl, string, true);
	elseif type == 2 then 
		if (Schema:IsPlayerCombineRank( pl, allowDispatch ) or pl:GetFaction() == FACTION_OTA) then
			Schema:SayDispatch(pl, string);
		else
			Clockwork.player:Notify(pl, "You are not ranked high enough to use this command!");
		end
	elseif type == 3 then Clockwork.chatBox:AddInTargetRadius(pl, "me", string.gsub(string, "^.", string.lower), pl:GetPos(), Clockwork.config:Get("talk_radius"):Get() * 2);
	elseif type == 4 then Clockwork.chatBox:AddInRadius(pl, "ic", string, pl:GetPos(), Clockwork.config:Get("talk_radius"):Get()); end
end )
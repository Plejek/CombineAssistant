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

local districts = {"District 1", "District 2", "District 3", "District 4"} // Add or remove your districts here.
local patrolGroups = {"Alpha", "Beta", "Charlie", "Delta", "Echo", "Foxtrot", "Gaia"} // Add or remove the names of default patrol groups.

local explainSearchText = "Spread your legs, place your hands behind your back and no sudden movements." // This is the text written once "Explain Search" is triggered under performances.

/*
===================================================
============= DO NOT EDIT BELOW THIS ==============
===================================================
*/

local Clockwork = Clockwork;
local PLUGIN = PLUGIN;

local assistantEnabled = false

local stunstickRaised = false
local stunstickState = false
local stunstickLastState = false
local lastActiveWep = ""
local currentActiveWep = ""
local stunstickVoltage = "low"

local buddies = {}

local patrolGroup = ""
local patrolUnits = ""

local dispatches = {"Anti-Citizen", "Anti-Civil", "Lockdown", "Inspection", "Inspection 2", "Relocation", "Citizenship", "Failure" }

local backupCodes = {"Code 1 - Not Urgent", "Code 2 - Urgent", "Code 3 - Emergency"}

function showCAssistantMenu()
	if LocalPlayer():GetFaction() != "Metropolice Force" then return end;
	local MENU = DermaMenu()
	
	if assistantEnabled then
		MENU:AddOption("Combine Assistant Performances", function() chat.AddText(Color(200,100,100),"Blt950's Combine Assistant v.1.0 - Disabled") toggleAssistant() end ):SetImage( "icon16/flag_green.png" )
	else
		MENU:AddOption("Combine Assistant Performances", function() chat.AddText(Color(200,100,100),"Blt950's Combine Assistant v.1.0 - Enabled") toggleAssistant() end ):SetImage( "icon16/flag_red.png" )
	end
	MENU:AddSpacer()
	MENU:AddSpacer()
	
	// Radio commands
	local RAD_SUBMENU, RAD_SUBMENU_PNL = MENU:AddSubMenu("Radio")
	RAD_SUBMENU_PNL:SetImage( "icon16/transmit_blue.png" )
	
	RAD_SUBMENU:AddOption("Ask for: Currently established groups", function() sendToChat(1, "Requesting information on current established groups.") end)
	RAD_SUBMENU:AddOption("Reply on: Currently established groups", function() if patrolGroup != "" then sendToChat(1, "Group "..patrolGroup..", Units "..patrolUnits.." reporting in.") else chatError("You don't have any group!") end end)
	
	local RAD_GROUP_SUBSUBMENU = RAD_SUBMENU:AddSubMenu("Establish Patrol")
	for k,v in pairs(patrolGroups) do
		local RAD_GROUP_SUBSUBSUBMENU = RAD_GROUP_SUBSUBMENU:AddSubMenu("Group "..v)
		for _, x in pairs(districts) do
			RAD_GROUP_SUBSUBSUBMENU:AddOption(x, function()
				patrolGroup = v
				sendToChat(1, "Unit "..printGroup()..". Establishing group "..v..". "..x..". SC: Green") 
			end)
		end
	end
	
	local RAD_GROUPDISTRICT_SUBSUBMENU = RAD_SUBMENU:AddSubMenu("Moving to District")
	for k,v in pairs(districts) do
		RAD_GROUPDISTRICT_SUBSUBMENU:AddOption(v, function()
			if patrolGroup != "" then
				sendToChat(1, "Unit "..printGroup()..". Group "..patrolGroup..". Moving to "..v..". SC: Green") 
			else
				chatError("You don't have any group!")
			end
		end)
	end
	
	RAD_SUBMENU:AddOption("Disband Group", function() if patrolGroup != "" then sendToChat(1, "Unit "..patrolUnits..". Disbanding group "..patrolGroup..".") patrolGroup = "" patrolUnits = "" else chatError("You don't have any group!") end end)
	RAD_SUBMENU:AddSpacer()
	local RAD_BACKUP_SUBSUBMENU, RAD_BACKUP_SUBSUBMENU_PNL = RAD_SUBMENU:AddSubMenu("Backup")
	RAD_BACKUP_SUBSUBMENU_PNL:SetImage( "icon16/exclamation.png" )
	for k,v in pairs(districts) do
		local RAD_BACKUP_SUBSUBSUBMENU = RAD_BACKUP_SUBSUBMENU:AddSubMenu(v)
		for _, x in pairs(backupCodes) do
			RAD_BACKUP_SUBSUBSUBMENU:AddOption(x, function()
				sendToChat(1, "10-78, need assistance. "..v..". "..x..".") 
			end)
		end
	end
	
	// Dispatch
	
	local DIS_SUBMENU, DIS_SUBMENU_PNL = MENU:AddSubMenu("Dispatch")
	DIS_SUBMENU_PNL:SetImage( "icon16/feed.png" )
	for k, v in pairs(dispatches) do
		DIS_SUBMENU:AddOption(v, function() sendToChat(2, v) end)
	end
	
	// Performances
	local PER_SUBMENU, PER_SUBMENU_PNL = MENU:AddSubMenu("Performances")
	PER_SUBMENU_PNL:SetImage( "icon16/emoticon_smile.png" )
	
	local PER_STUN_SUBMENU, PER_STUN_SUBMENU_PNL = PER_SUBMENU:AddSubMenu("Stunstick Voltage")
	PER_STUN_SUBMENU_PNL:SetImage( "icon16/lightning.png" )
	
	PER_STUN_SUBMENU:AddOption("Low", function() stunstickVoltage = "low" end)
	PER_STUN_SUBMENU:AddOption("Medium", function() stunstickVoltage = "medium" end)
	PER_STUN_SUBMENU:AddOption("High", function() stunstickVoltage = "high" end)
	PER_STUN_SUBMENU:AddOption("Max", function() stunstickVoltage = "max" end)

	PER_SUBMENU:AddOption("Explain Search", function() sendToChat(4, explainSearchText) end ):SetImage( "icon16/user_comment.png" )
	PER_SUBMENU:AddOption("Attempt to tie", function()
		if LocalPlayer():GetEyeTrace().Entity:IsPlayer() then
			local physDesc = "["..string.sub(LocalPlayer():GetEyeTrace().Entity:GetNetworkedString("physdesc"), 1, 15).."...".."]"
			sendToChat(3, "attempts to tie "..physDesc..".") 
		else
			chat.AddText(Color(200,100,100),"Combine Assistant: You ain't looking at a player!")
		end
	end ):SetImage( "icon16/user_comment.png" )

	
	MENU:AddSpacer()
	// Add a buddy
	MENU:AddOption("Add Buddy", function() 
		if LocalPlayer():GetEyeTrace().Entity:IsValid() and LocalPlayer():GetEyeTrace().Entity:IsPlayer() then
			table.insert(buddies, LocalPlayer():GetEyeTrace().Entity)
		else
			chat.AddText(Color(200,100,100),"Combine Assistant: You ain't looking at a player!")
		end
	end ):SetImage( "icon16/user_add.png" )
	
	// Clear buddies
	MENU:AddOption("Clear Buddies", function() buddies = {} end ):SetImage( "icon16/user_delete.png" )
	
	// My buddies
	local BUD_SUBMENU, BUD_SUBMENU_PNL = MENU:AddSubMenu("My Buddies")
	BUD_SUBMENU_PNL:SetImage( "icon16/group.png" )
	
	local count = 0
	for k,v in pairs(buddies) do
		count = count + 1
		BUD_SUBMENU:AddOption(v:Name(), function() end)
	end
	if count == 0 then BUD_SUBMENU:AddOption("(None)", function() end) end
	
	// Open the menu
	
	MENU:Open( ScrW()/2-10, ScrH()/2-10 )
	//gui.SetMousePos(110, 110)
end

function hideCAssistantMenu()
	CloseDermaMenus()
end
concommand.Add("+CA_Menu", showCAssistantMenu)
concommand.Add("-CA_Menu", hideCAssistantMenu)

function toggleAssistant()
	if assistantEnabled then
		assistantEnabled = false
		timer.Destroy("stunstickCheck")
	else
		assistantEnabled = true
		timer.Create( "stunstickCheck", 1.0, 0, function()
			Perform()
		end)
	end
end

function printGroup()
	local myname = string.Explode(".", LocalPlayer():Name())
	output = myname[2]

	for k,v in pairs(buddies) do
		local budname = string.Explode(".", v:Name())
		output = output.." - "..budname[2]
	end
	
	patrolUnits = output
	return output
end

function hasBuddies()
	local count = 0
	for k,v in pairs(buddies) do
		count = count + 1
	end
	if count == 0 then return false else return true end
end

function chatError(string)
	chat.AddText(Color(200,100,100),"Combine Assistant: "..string)
end

function Perform()
	// Raise stunstick
	if stunstickState != stunstickLastState then
		if (Clockwork.player:GetWeaponRaised(LocalPlayer()) == true) then
			sendToChat(3, "raises his stunstick and flicks it on "..stunstickVoltage.." voltage.");
			stunstickLastState = true
		else
			sendToChat(3, "turns off his stunstick and lowers it.");
			stunstickLastState = false
		end
	end
	
	// Un(holster) Stunstick.
	if currentActiveWep != lastActiveWep then
		if currentActiveWep == "Stunstick" and lastActiveWep != "Stunstick" then
			sendToChat(3, "unclips his stunstick from the belt and places it in his right hand.");
			lastActiveWep = "Stunstick"
		elseif lastActiveWep == "Stunstick" then
			sendToChat(3, "clips his stunstick it to the belt.");
			lastActiveWep = LocalPlayer():GetActiveWeapon():GetPrintName()
		end
	end
end

local lastStunPerformance = CurTime()
local lastPushPerformance = CurTime()
hook.Add( "KeyPress" ,"CheckPlayerStunstickHit", function(player, key)
	if assistantEnabled then
		if key == IN_ATTACK and currentActiveWep == "Stunstick" and CurTime() > lastStunPerformance and stunstickState then 
			sendToChat(3, "hits the citizen infront of him with his stunstick.")
			lastStunPerformance = CurTime()+5
		elseif key == IN_ATTACK2 and currentActiveWep == "Stunstick" and CurTime() > lastPushPerformance then 
			ent = LocalPlayer():GetEyeTrace().Entity
			if ent:IsValid() then
				if ent:GetClass() == "cw_paper" and !ent:IsPlayer() then
					sendToChat(3, "pushes the paper infront of him.")
				elseif ent:GetClass() == "cw_notepad" and !ent:IsPlayer() then
					sendToChat(3, "pushes the notepad infront of him.")
				elseif ent:IsPlayer() then
					if Schema:IsPlayerCombine(ent) then
						sendToChat(3, "pushes the unit infront of him.")
					elseif ent:GetFaction() == FACTION_CITIZEN or ent:GetFaction() == FACTION_CWU or ent:GetFaction() == FACTION_WI then
						sendToChat(3, "pushes the citizen infront of him.")
					else
						sendToChat(3, "pushes the person infront of him.")
					end
				elseif ent:GetClass() == "func_door_rotating" or ent:GetClass() == "prop_door_rotating" or "func_door" then
					sendToChat(3, "knocks on the door.")
				else
					sendToChat(3, "pushes the item infront of him.")
				end				
			end
			if ent:GetClass() == "func_door_rotating" or ent:GetClass() == "prop_door_rotating" or "func_door" then
				lastPushPerformance = CurTime()+8
			else
				lastPushPerformance = CurTime()+1
			end
		end
	end
end)

hook.Add("Tick", "CurrentActiveWep", function() 
	if assistantEnabled then
		if LocalPlayer():IsValid() and LocalPlayer():Alive() and !Schema:IsPlayerCombineRank( LocalPlayer(), {"SCN", "SYNTH"} ) and !LocalPlayer():GetSharedVar("FallenOver") and LocalPlayer():GetSharedVar("tied") == 0 and !(LocalPlayer():GetRagdollState() == RAGDOLL_KNOCKEDOUT or false) then
			if LocalPlayer():GetActiveWeapon() then
				currentActiveWep = LocalPlayer():GetActiveWeapon():GetPrintName()

				if (currentActiveWep == "Stunstick") then
					stunstickState = Clockwork.player:GetWeaponRaised(LocalPlayer());
				end
			end
		end
	end
end)

hook.Add("PlayerDisconnected", "RemoveFromTable", function(ply)

	for k,v in pairs(buddies) do
		if v == ply then
			table.remove(buddies, ply)
		end
	end

end)

function sendToChat(type, string)
	net.Start( "combineassistant" )
		net.WriteInt( tonumber(type), 32 )
		net.WriteString( string )
	net.SendToServer()
end
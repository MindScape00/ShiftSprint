-------------------------------------------------------------------------------
-- Login Handle / Start-up Initialization
-------------------------------------------------------------------------------

local currentVersion = GetAddOnMetadata("ShiftSprint", "Version")
local defaultSpeedWalk = "1.6"
local defaultSpeedFly = "10"
local defaultSpeedSwim = "10"
local isFlying = IsFlying()
local isSwimming = IsSwimming()
local defaultEmote = "begins to sprint."
local spellsActive = 0
local MessagesToFilter = 0
local function cprint(text)
	print("|cffFFD700"..text.."|r")
end

local ssloginhandle = CreateFrame("frame","ssloginhandle");
ssloginhandle:RegisterEvent("PLAYER_LOGIN");
ssloginhandle:SetScript("OnEvent", function()
    ShiftSprintInitializeSavedVars();
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", chatSpeedFilter)
	updateSpeeds()
end);

-- Initialize Variables that are saved for the character to use later 
-- // Only Sets if they are nil, usually only on the first login with the addon for that character
function ShiftSprintInitializeSavedVars()
	-- On-Foot Speed
	if SprintSpeedWalk == nil then
		SprintSpeedWalk = defaultSpeedWalk
	end
	-- Flying Speed
	if SprintSpeedFly == nil then
		SprintSpeedFly = defaultSpeedFly
	end
	-- Swim Speed
	if SprintSpeedSwim == nil then
		SprintSpeedSwim = defaultSpeedSwim
	end
	-- Default Emote Message
	if emoteMessage == nil then
		emoteMessage = "begins to sprint."
	end
	-- Default Emote Toggle Setting (Off)
	if sendEmote == nil then
		sendEmote = 0
	end
	-- Default Spell Toggle Setting (On)
	if sendSpells == nil then
		sendSpells = 1
	end
	-- Default Spell List (Create Empty Table)
	if type(spellList) == "table" then -- Table for saving Spells for casting
	else
		spellList = {}
	end
	if ssRunOnce == 0 or ssRunOnce == nil then
		jumpBind1,jumpBind2 = GetBindingKey("JUMP")
		shiftSpaceBind = GetBindingByKey("SHIFT-SPACE")
		ssRunOnce = 1
		if jumpBind1 == "SPACE" or jumpBind2 == "SPACE" then
			if shiftSpaceBind == "TOGGLEWORLDSTATESCORES" then
				SetBinding("SHIFT-SPACE", nil)
				print("ShiftSprint has detected that Shift+Space was bound (default). We've deleted this binding to enable sprint-jumping. This will only occur once (per character), and you may re-set your binding if you wish, but it will block jumping while shift is held down.")
			elseif shiftSpaceBind ~= "JUMP" then
				print("ShiftSprint has detected that Shift+Space is bound to "..shiftSpaceBind..", which is a custom bind you have set. This bind will block the ability to sprint-jump (holding shift to sprint + space to jump). We advise you to remove this binding if you wish to sprint-jump. You can use '/ssjumpreset' to remove any conflicting bindings automatically.")
			end
		else
			print("ShiftSprint has detected that Jump is not set to the Space Bar. Please note that any bindings with Shift+Jump Key will interfere with your ability to sprint-jump. We advise you remove such bindings if they are present, or revert to using the Space Bar. You can use '/ssjumpreset' to remove any conflicting bindings automatically.")
		end
	end		
end

-------------------------------------------------------------------------------
-- Simple Chat Functions
-------------------------------------------------------------------------------

local function cmd(text)
  SendChatMessage("."..text, "GUILD");
end

local function emote(text)
  SendChatMessage(""..text, "EMOTE");
end

local function msg(text)
  SendChatMessage(""..text, "SAY");
end

-------------------------------------------------------------------------------
-- Key Bindings Listener / Main Functions
-------------------------------------------------------------------------------

function updateSpeeds()
	currentSpeed,returnSpeedWalk,returnSpeedFly,returnSpeedSwim = GetUnitSpeed("player")
	returnSpeedWalk = returnSpeedWalk/7
	returnSpeedFly = returnSpeedFly/7
	returnSpeedSwim = returnSpeedSwim/4.7222
	--print(returnSpeedWalk.." | "..returnSpeedFly.." | "..returnSpeedSwim)
end

local f = CreateFrame("Frame", "KeyboardListener", UIParent);
f:EnableKeyboard(true); f:SetPropagateKeyboardInput(true);
f.isSprint = false
f:SetScript("OnKeyDown", function(self, key)
	self:SetPropagateKeyboardInput(key~="LSHIFT")
	if key == "LSHIFT" then
		if self.isSprint == false then
			updateSpeeds()
			if currentSpeed > 0 then
				if SprintSpeedWalk ~= "0" then
					MessagesToFilter = MessagesToFilter + 1
					cmd("mod speed walk "..SprintSpeedWalk)
					if sendSpells == 1 or sendSpells == 2 then
						isFlying = IsFlying()
						isSwimming = IsSwimming()
						if not isFlying and not isSwimming then
							CastSpellList()
						end
					end
				end
				if SprintSpeedFly ~= "0" then
					MessagesToFilter = MessagesToFilter + 1
					cmd("mod speed fly "..SprintSpeedFly)
					if sendSpells == 1 or sendSpells == 3 then
						isFlying = IsFlying()
						isSwimming = IsSwimming()
						if isFlying and not isSwimming then
							CastSpellList()
						end
					end
				end
				if SprintSpeedSwim ~= "0" then
					MessagesToFilter = MessagesToFilter+1
					cmd("mod speed swim "..SprintSpeedSwim)
					if sendSpells == 1 or sendSpells == 4 then
						isFlying = IsFlying()
						isSwimming = IsSwimming()
						if not isFlying and isSwimming then
							CastSpellList()
						end
					end
				end
				if sendEmote == 1 then
					isFlying = IsFlying()
					if isFlying then else
						emote(emoteMessage)
					end
				end
				self.isSprint = true
			end
		end
	end
end)

f:SetScript("OnKeyUp", function(self, key)
	if self.isSprint == true then
		if SprintSpeedWalk ~= "0" then
			MessagesToFilter = MessagesToFilter + 1
			returnSpeedWalk = returnSpeedWalk or "1"
			cmd("mod speed walk "..returnSpeedWalk)
			if spellsActive == 1 then
				UnauraSpells()
			end
		end
		if SprintSpeedFly ~= "0" then
			MessagesToFilter = MessagesToFilter + 1
			returnSpeedFly = returnSpeedFly or "1"
			cmd("mod speed fly "..returnSpeedFly)
			if spellsActive == 1 then
				UnauraSpells()
			end
		end
		if SprintSpeedSwim ~= "0" then
			MessagesToFilter = MessagesToFilter + 1
			returnSpeedSwim = returnSpeedSwim or "1"
			cmd("mod speed swim "..returnSpeedSwim)
			if spellsActive == 1 then
				UnauraSpells()
			end
		end
		self.isSprint = false
		--C_Timer.After(0.5, chatSpeedFilterOff) -- Old Filter System - Replaced by Message Counter
	end
end)


function chatSpeedFilter(self,event,m,...)
	if MessagesToFilter > 0 then
		if m:find("You set the speed of") or m:find("You set the fly speed of") or m:find("You set all speeds of") or m:find("You set the swim speed of") then
			MessagesToFilter = MessagesToFilter - 1
			return true;
		end
	end
end

--[[
function chatSpeedFilterOff()
	if f.isSprint == false then
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", chatSpeedFilter)
		--print("Chat Filter [Speed] Off.")
	end
end
--]]

-------------------------------------------------------------------------------
-- Speed Settings Commands
-------------------------------------------------------------------------------

--[[
-- Set Walk Speed Command (/sswalk)
SLASH_CCSSWALK1 = '/sswalk';
function SlashCmdList.CCSSWALK(msg, editbox)
	msg = string.lower(msg)
	if msg == nil or msg == "" or msg == "default" then
		SprintSpeedWalk = defaultSpeedWalk
		print("ShiftSprint | On Foot Sprint Speed set to default ("..defaultSpeedWalk..").")
	elseif msg == "0" then
		SprintSpeedWalk = "0"
		print("ShiftSprint | On Foot Sprint Disabled.")
	elseif tonumber(msg) ~= nil then
		SprintSpeedWalk = msg
		print("ShiftSprint | On Foot Sprint Speed set to "..SprintSpeedWalk..".")
	else
		print("ShiftSprint Error: You must enter a proper number or 'default'.")
	end
end

-- Set Fly Speed Command (/ssfly)
SLASH_CCSSFLY1 = '/ssfly';
function SlashCmdList.CCSSFLY(msg, editbox)
	msg = string.lower(msg)
	if msg == nil or msg == "" or msg == "default" then
		SprintSpeedFly = defaultSpeedFly
		print("ShiftSprint | Flying Boost Speed set to default ("..defaultSpeedFly..").")
	elseif msg == "0" then
		SprintSpeedFly = "0"
		print("ShiftSprint | Flying Boost Disabled.")
	elseif tonumber(msg) ~= nil then
		SprintSpeedFly = msg
		print("ShiftSprint | Flying Boost Speed set to "..SprintSpeedFly..".")
	else
		print("ShiftSprint Error: You must enter a proper number or 'default'.")
	end
end

-- Set Swim Speed Command (/ssswim)
SLASH_CCSSSWIM1 = '/ssswim';
function SlashCmdList.CCSSSWIM(msg, editbox)
	msg = string.lower(msg)
	if msg == nil or msg == "" or msg == "default" then
		SprintSpeedSwim = defaultSpeedSwim
		print("ShiftSprint | Flying Boost Speed set to default ("..defaultSpeedSwim..").")
	elseif msg == "0" then
		SprintSpeedSwim = "0"
		print("ShiftSprint | Flying Boost Disabled.")
	elseif tonumber(msg) ~= nil then
		SprintSpeedSwim = msg
		print("ShiftSprint | Flying Boost Speed set to "..SprintSpeedSwim..".")
	else
		print("ShiftSprint Error: You must enter a proper number or 'default'.")
	end
end
--]]

-------------------------------------------------------------------------------
-- Spells System (ShiftSpells)
-------------------------------------------------------------------------------

-- Set Spells Command
SLASH_CCSSSPELLONE1, SLASH_CCSSSPELLONE2 = '/sspell','/sspells';
function SlashCmdList.CCSSSPELLONE(msg, editbox)
	msg = string.lower(msg)
	if msg == "list" then
		print("ShiftSprint | Current Set Spells")
		count = #spellList
		for k,v in pairs(spellList) do
			print(tostring(k)..": "..tostring(v))
		end
	elseif msg == "off" or msg == "disable" then
		sendSpells = 0
		print("ShiftSprint | Sprint Spells Disabled")
	elseif msg ==  "on" or msg == "all" or msg == "enable" then
		sendSpells = 1
		print("ShiftSprint | Sprint Spells Enabled (Walk + Fly)")
	elseif msg == "walk" then
		sendSpells = 2
		print("ShiftSprint | Sprint Spells Enabled (Walk Only)")
	elseif msg == "fly" then
		sendSpells = 3
		print("ShiftSprint | Sprint Spells Enabled (Fly Only)")	
	elseif msg:find("set") then
		-- Reset the current table to blank
		count = #spellList
		for i=0, count do spellList[i]=nil end
		-- Add in the new spells, separated by spaces, into the spellList table
		for spellID in msg:gmatch("%d+") do table.insert (spellList, spellID) end
		print("ShiftSprint | Spells set: "..table.tostring(spellList))
		if sendSpells == 0 then
			print("Use '/sspell [all/walk/fly]' to enable to see them in use.")
		end
	elseif msg:find("add") then
		-- Add in the new spells, separated by spaces, into the spellList table
		for spellID in msg:gmatch("%d+") do table.insert (spellList, spellID) end
		print("ShiftSprint | Spells added, full list: "..table.tostring(spellList))
		if sendSpells == 0 then
			print("Use '/sspell [all/walk/fly]' to enable to see them in use.")
		end
	else
		print("ShiftSprint | ShiftSpells System Help:")
		print("  /sspell [add/set] [spells separated by spaces]  - Add: Adds to current list. Set: Reset list before setting new spells.")
		print("  /sspell [all/walk/fly/off] - Set to trigger All / On-Foot Only / Flying Only, or Off.")
		print("  /sspell list - List Current Spells.")
	end
end

-- Cast Spells Command
function CastSpellList()
	spellsActive = 1
	count = #spellList
	for k,v in pairs(spellList) do
		-- Ensure that it's a proper number, to avoid invalid entries.
		if tonumber(v) ~= nil then
			cmd("aura "..tostring(v).." self")
		end
	end
end

-- Unaura the Cast Spells
function UnauraSpells()
	spellsActive = 0
	count = #spellList
	for k,v in pairs(spellList) do
		-- Ensure that it's a proper number, to avoid invalid entries (again).
		if tonumber(v) ~= nil then
			cmd("unaura "..tostring(v).." self")
		end
	end
end

-------------------------------------------------------------------------------
-- Emotes System
-------------------------------------------------------------------------------

-- Could be Improved with a Timer to lessen the amount of /me spam if you toggle between sprinting quickly
-- i.e., leave sprint, re-engage it within a few seconds, don't send the emote

-- Set Emote Message Command
SLASH_CCSSEMOTE1, SLASH_CCSSEMOTE2 = '/ssemote', '/sse';
function SlashCmdList.CCSSEMOTE(msg, editbox)
	msg = string.lower(msg)
	-- If Emotes are currently Off:
	if sendEmote == 0 then
		-- "default" -> Enable with default emote message.
		if msg == "default" then
			emoteMessage = defaultEmote
			print("Emotes toggled on ( * "..emoteMessage..").")
			sendEmote = 1
		-- no message, "on", or "1" -> Toggle On with already set message.
		elseif msg == nil or msg == "" or msg == "on" or msg == "1" then
			print("Emotes toggled on ( * "..emoteMessage..").")
			sendEmote = 1
		-- "0" or "off" -> Keep Disabled.
		elseif msg == "0" or msg == "off" then
			print("Emotes toggled off.")
		-- Anything else, use it as the Emote Message and enable.
		else
			emoteMessage = msg
			print("Emotes toggled on ( * "..emoteMessage..").")
			sendEmote = 1
		end
		
	-- If Emotes are currently On:
	elseif sendEmote == 1 then
		-- No message, "off", "0" -> Disable Emote Messages
		if msg == nil or msg == "off" or msg == "0" or msg == "" then
			print("Emotes toggled off.")
			sendEmote = 0
		-- "on" or "1" -> Enable with previously set message
		elseif msg == "on" or msg == "1" then
			print("Emotes toggled on ( * "..emoteMessage..").")
		-- "default" -> Sets Default Message
		elseif msg == "default" then
			emoteMessage = defaultEmote
			print("Emotes toggled on ( * "..emoteMessage..").")
		-- Anything else, use it as the Emote Message and enable.
		else
			emoteMessage = msg
			print("Emotes toggled on ( * "..emoteMessage..").")
		end
	end
end

-------------------------------------------------------------------------------
-- Version / Help
-------------------------------------------------------------------------------

SLASH_CCSSVERSION1, SLASH_CCSSVERSION2 = '/shiftsprint', '/ss'; -- 3.
function SlashCmdList.CCSSVERSION(msg, editbox) -- 4.
	local arg,val = strsplit(" ",strlower(msg),2);
	if arg == "walk" then
		if val == nil or val == "" then
			print("ShiftSprint Syntax: '/ss walk [#Number or 'default' or '0' for off]")
		elseif val == "default" then
			SprintSpeedWalk = defaultSpeedWalk
			print("ShiftSprint | On Foot Sprint Speed set to default ("..defaultSpeedWalk..").")
		elseif val == "0" or val == "off" then
			SprintSpeedWalk = "0"
			print("ShiftSprint | On Foot Sprint Disabled.")
		elseif tonumber(val) ~= nil then
			SprintSpeedWalk = val
			print("ShiftSprint | On Foot Sprint Speed set to "..SprintSpeedWalk..".")
		else
			print("ShiftSprint Error: You must enter a proper number or 'default'.")
		end
	elseif arg == "fly" then
		if val == nil or val == "" then
			print("ShiftSprint Syntax: '/ss fly [#Number or 'default' or '0' for off]")
		elseif val == "default" then
			SprintSpeedFly = defaultSpeedFly
			print("ShiftSprint | Flying Boost Speed set to default ("..defaultSpeedFly..").")
		elseif val == "0" or val == "off" then
			SprintSpeedFly = "0"
			print("ShiftSprint | Flying Boost Disabled.")
		elseif tonumber(val) ~= nil then
			SprintSpeedFly = val
			print("ShiftSprint | Flying Boost Speed set to "..SprintSpeedFly..".")
		else
			print("ShiftSprint Error: You must enter a proper number or 'default'.")
		end
	elseif arg == "swim" then
		if val == nil or val == "" then
			print("ShiftSprint Syntax: '/ss swim [#Number or 'default' or '0' for off]")		
		elseif val == "default" then
			SprintSpeedSwim = defaultSpeedSwim
			print("ShiftSprint | Swimming Boost Speed set to default ("..defaultSpeedSwim..").")
		elseif val == "0" then
			SprintSpeedSwim = "0"
			print("ShiftSprint | Swimming Boost Disabled.")
		elseif tonumber(val) ~= nil then
			SprintSpeedSwim = val
			print("ShiftSprint | Swimming Boost Speed set to "..SprintSpeedSwim..".")
		else
			print("ShiftSprint Error: You must enter a proper number or 'default'.")
		end
	elseif arg == "default" then
		SprintSpeedSwim = defaultSpeedSwim
		SprintSpeedFly = defaultSpeedFly
		SprintSpeedWalk = defaultSpeedWalk
		print("ShiftSprint: All Speeds [Walk/Fly/Swim] Reset to Default")
	else
		print("ConvenientCommands: ShiftSprint version "..currentVersion);
		print("  /ss [walk/fly/swim] [Speed / Default / 0] | Set Sprint Speeds")
		print("  /ss default | Reset all speeds to default at once")
		print("  /sspell - ShiftSpells System - Use for more information")
		print("  /sse [On / Off / Custom Emote] | Toggle / Set Sprint Emotes")
		print("  /ssjumpreset | Reset any bindings conflicting with sprint-jumping")
		print("  Current Walk: "..SprintSpeedWalk.." (Default:"..defaultSpeedWalk..") | Fly: "..SprintSpeedFly.." (Default:"..defaultSpeedFly..") | Swim: "..SprintSpeedSwim.." (Default:"..defaultSpeedSwim..")")
	end
end

-------------------------------------------------------------------------------
-- Reset Conflicting Sprint-Jump Bindings
-------------------------------------------------------------------------------

SLASH_CCSSJUMPRESET1, SLASH_CCSSJUMPRESET2 = '/ssjumpreset', '/shiftsprintjumpreset';
function SlashCmdList.CCSSJUMPRESET(msg, editbox) 
	jumpBind1,jumpBind2 = GetBindingKey("JUMP")
	ssSprintKey = "SHIFT"
	sprintJumpKeyCombo = (""..ssSprintKey.."-"..jumpBind1.."")
	oldBindingConflict = GetBindingByKey(sprintJumpKeyCombo)
	if oldBindingConflict ~= "JUMP" then
		SetBinding(sprintJumpKeyCombo,nil)
		print("ShiftSprint | Key Bindings for "..sprintJumpKeyCombo.." have been removed.")
		print("Previous binding: "..oldBindingConflict)
	else
		print("ShiftSprint | No Bindings Found to Conflict with Sprint-Jump.")
	end
end

-------------------------------------------------------------------------------
-- Table Convert Functions
-------------------------------------------------------------------------------

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '' .. string.gsub(v,'"', '\\"' ) .. ''
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "" .. table.concat( result, ", " ) .. ""
end
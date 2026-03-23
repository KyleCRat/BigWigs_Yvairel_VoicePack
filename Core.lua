
local name, addon = ...

local tostring = tostring
local format = format
addon.SendMessage = BigWigsLoader.SendMessage

local path = "Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\%s.ogg"
local pathYou = "Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\%sy.ogg"

local function handler(event, module, key, sound, isOnMe)
	local success = PlaySoundFile(format(isOnMe and pathYou or path, tostring(key)), "Master")
	if not success then
		addon:SendMessage("BigWigs_Sound", module, key, sound)
	end
end

BigWigsLoader.RegisterMessage(addon, "BigWigs_Voice", handler)
BigWigsAPI.RegisterVoicePack("MidnightS1Raids")

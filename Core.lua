
local name, addon = ...

local tostring = tostring
local format = format
addon.SendMessage = BigWigsLoader.SendMessage

local path = "Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\%s.ogg"
local pathYou = "Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\%sy.ogg"

local function handler(event, module, key, sound, isOnMe)
	local id = tostring(key)
	local success = isOnMe and PlaySoundFile(format(pathYou, id), "Master")

	if not success then
		success = PlaySoundFile(format(path, id), "Master")
	end

	if not success then
		addon:SendMessage("BigWigs_Sound", module, key, sound)
	end
end

BigWigsLoader.RegisterMessage(addon, "BigWigs_Voice", handler)
BigWigsAPI.RegisterVoicePack("MidnightS1Raids")

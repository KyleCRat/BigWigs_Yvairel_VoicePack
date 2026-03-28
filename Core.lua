
local name, addon = ...

local tostring = tostring
local format = format
addon.SendMessage = BigWigsLoader.SendMessage

local path = "Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\%s.ogg"
local pathYou = "Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\%sy.ogg"

local function handler(event, module, key, sound, isOnMe)
	local id = tostring(key)
	local log = addon.log
	local youPath = format(pathYou, id)
	local regPath = format(path, id)

	local played = "fallback"
	local success = isOnMe and PlaySoundFile(youPath, "Master")
	if success then
		played = "y"
	end
	log(format("key=%s isOnMe=%s tryY=%s resultY=%s", id, tostring(isOnMe), youPath, tostring(success)))

	if not success then
		success = PlaySoundFile(regPath, "Master")
		if success then
			played = "ogg"
		end
		log(format("key=%s fallback=%s result=%s", id, regPath, tostring(success)))
	end

	if not success then
		log(format("key=%s -> BigWigs_Sound fallback (sound=%s)", id, tostring(sound)))
		addon:SendMessage("BigWigs_Sound", module, key, sound)
	end

	addon.logAbility(key, module, sound, isOnMe, played)
end

BigWigsLoader.RegisterMessage(addon, "BigWigs_Voice", handler)
BigWigsAPI.RegisterVoicePack("MidnightS1Raids")

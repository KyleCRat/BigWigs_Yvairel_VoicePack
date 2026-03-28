
local _, addon = ...

local date = date
local tinsert = tinsert
local format = format
local tostring = tostring
local GetTime = GetTime
local GetSpellInfo = C_Spell.GetSpellInfo

local MAX_PULLS = 50

local DIFFICULTY_NAMES = {
	[1] = "Normal",
	[2] = "Heroic",
	[3] = "10N",
	[4] = "25N",
	[5] = "10H",
	[6] = "25H",
	[7] = "LFR",
	[8] = "M+ Challenge",
	[9] = "40-Man",
	[14] = "Normal",
	[15] = "Heroic",
	[16] = "Mythic",
	[17] = "LFR",
	[23] = "Mythic+",
	[24] = "Timewalking",
}

local activePull = nil
local pullStartTime = nil

local function ensureDB()
	if not YvairelVoicePackDB then
		YvairelVoicePackDB = {}
	end
	if not YvairelVoicePackDB.pulls then
		YvairelVoicePackDB.pulls = {}
	end
	if not YvairelVoicePackDB.enabled then
		YvairelVoicePackDB.enabled = false
	end
end

local function isEnabled()
	ensureDB()

	return YvairelVoicePackDB.enabled
end

local function getElapsed()
	if not pullStartTime then
		return 0
	end

	return GetTime() - pullStartTime
end

local function log(message)
	if not isEnabled() then
		return
	end

	if not activePull then
		return
	end

	local entry = format("[%5.1fs] %s", getElapsed(), message)
	tinsert(activePull.log, entry)
end

local function logAbility(key, module, sound, isOnMe, played)
	if not isEnabled() then
		return
	end

	if not activePull then
		return
	end

	local spellId = tostring(key)
	local spellInfo = GetSpellInfo(key)
	local spellName = spellInfo and spellInfo.name or "Unknown"
	local elapsed = format("%.1f", getElapsed())

	local cast = {
		time = elapsed,
		isOnMe = isOnMe and true or false,
		played = played,
	}

	local abilities = activePull.abilities
	local existing = abilities[spellId]

	if existing then
		tinsert(existing.casts, cast)
	else
		abilities[spellId] = {
			spellName = spellName,
			defaultSound = tostring(sound),
			casts = { cast },
		}
	end
end

addon.log = log
addon.logAbility = logAbility
addon.isDebugEnabled = isEnabled

local frame = CreateFrame("Frame")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:SetScript("OnEvent", function(_, event, ...)
	if not isEnabled() then
		return
	end

	ensureDB()

	if event == "ENCOUNTER_START" then
		local encounterID, encounterName, difficultyID, groupSize = ...
		local diffName = DIFFICULTY_NAMES[difficultyID] or tostring(difficultyID)

		activePull = {
			boss = encounterName or "Unknown",
			encounterId = encounterID,
			difficulty = diffName,
			difficultyId = difficultyID,
			groupSize = groupSize,
			startTime = date("%Y-%m-%d %H:%M:%S"),
			result = "in progress",
			duration = 0,
			log = {},
			abilities = {},
		}
		pullStartTime = GetTime()

		local pulls = YvairelVoicePackDB.pulls
		tinsert(pulls, activePull)

		if #pulls > MAX_PULLS then
			tremove(pulls, 1)
		end

	elseif event == "ENCOUNTER_END" then
		if not activePull then
			return
		end

		local _, _, _, _, success = ...
		activePull.result = success == 1 and "kill" or "wipe"
		activePull.duration = format("%.1fs", GetTime() - pullStartTime)
		activePull = nil
		pullStartTime = nil
	end
end)

local function printPulls()
	ensureDB()
	local pulls = YvairelVoicePackDB.pulls

	if #pulls == 0 then
		print("|cff9b59b6[YVP]|r No pulls recorded.")

		return
	end

	print(format("|cff9b59b6[YVP]|r %d pulls recorded:", #pulls))
	for i, pull in ipairs(pulls) do
		local resultColor = pull.result == "kill" and "|cff00ff00" or "|cffff0000"
		local abilityCount = 0
		if pull.abilities then
			for _ in pairs(pull.abilities) do
				abilityCount = abilityCount + 1
			end
		end

		print(format("  %d. %s %s (%s) %s%s|r - %s [%d events, %d abilities]",
			i, pull.startTime, pull.boss, pull.difficulty,
			resultColor, pull.result, pull.duration or "?",
			#pull.log, abilityCount
		))
	end
end

local function printPull(index)
	ensureDB()
	local pulls = YvairelVoicePackDB.pulls

	if not pulls[index] then
		print(format("|cff9b59b6[YVP]|r Pull #%d not found. Use /yvp pulls to see available.", index))

		return
	end

	local pull = pulls[index]
	print(format("|cff9b59b6[YVP]|r Pull #%d: %s %s (%s) - %s (%s)",
		index, pull.startTime, pull.boss, pull.difficulty,
		pull.result, pull.duration or "?"
	))

	if #pull.log == 0 then
		print("  No log entries.")

		return
	end

	for _, entry in ipairs(pull.log) do
		print("  " .. entry)
	end
end

local function printPullAbilities(index)
	ensureDB()
	local pulls = YvairelVoicePackDB.pulls

	if not pulls[index] then
		print(format("|cff9b59b6[YVP]|r Pull #%d not found. Use /yvp pulls to see available.", index))

		return
	end

	local pull = pulls[index]
	print(format("|cff9b59b6[YVP]|r Pull #%d abilities: %s %s (%s) - %s (%s)",
		index, pull.startTime, pull.boss, pull.difficulty,
		pull.result, pull.duration or "?"
	))

	if not pull.abilities then
		print("  No abilities recorded.")

		return
	end

	local count = 0
	for _ in pairs(pull.abilities) do
		count = count + 1
	end

	if count == 0 then
		print("  No abilities recorded.")

		return
	end

	for spellId, entry in pairs(pull.abilities) do
		local castCount = entry.casts and #entry.casts or 0
		print(format("  %s: %s x%d sound=%s", spellId, entry.spellName, castCount, entry.defaultSound))
		if entry.casts then
			for _, cast in ipairs(entry.casts) do
				local playedColor = cast.played == "fallback" and "|cffff0000" or "|cff00ff00"
				local onMeStr = cast.isOnMe and " |cffffff00[onMe]|r" or ""
				print(format("    %ss %s%s|r%s", cast.time, playedColor, cast.played, onMeStr))
			end
		end
	end
end

SLASH_YVPVOICE1 = "/yvp"
SlashCmdList["YVPVOICE"] = function(msg)
	ensureDB()
	msg = msg:trim():lower()

	if msg == "debug on" then
		YvairelVoicePackDB.enabled = true
		print("|cff9b59b6[YVP]|r Debug logging enabled.")

	elseif msg == "debug off" then
		YvairelVoicePackDB.enabled = false
		print("|cff9b59b6[YVP]|r Debug logging disabled.")

	elseif msg == "pulls" then
		printPulls()

	elseif msg:match("^pull %d+ abilities$") then
		local index = tonumber(msg:match("^pull (%d+) abilities$"))
		printPullAbilities(index)

	elseif msg:match("^pull %d+$") then
		local index = tonumber(msg:match("^pull (%d+)$"))
		printPull(index)

	elseif msg == "clear pulls" then
		YvairelVoicePackDB.pulls = {}
		print("|cff9b59b6[YVP]|r Pulls cleared.")

	elseif msg == "clear all" then
		YvairelVoicePackDB.pulls = {}
		print("|cff9b59b6[YVP]|r All data cleared.")

	elseif msg == "status" then
		print(format("|cff9b59b6[YVP]|r Debug: %s | Pulls: %d",
			YvairelVoicePackDB.enabled and "ON" or "OFF",
			#YvairelVoicePackDB.pulls
		))

	else
		print("|cff9b59b6[YVP]|r Commands:")
		print("  /yvp debug on              - Enable debug logging")
		print("  /yvp debug off             - Disable debug logging")
		print("  /yvp pulls                 - List all recorded pulls")
		print("  /yvp pull <n>              - Show debug log for pull")
		print("  /yvp pull <n> abilities    - Show abilities for pull")
		print("  /yvp clear pulls           - Clear pull history")
		print("  /yvp clear all             - Clear everything")
		print("  /yvp status                - Show status")
	end
end

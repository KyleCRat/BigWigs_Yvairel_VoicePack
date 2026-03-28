-- This is an EXAMPLE of what WTF/Account/<NAME>/SavedVariables/BigWigs_Yvairels_VoicePack.lua
-- would look like after a raid night with /yvp debug on. This file is not used by the addon.

YvairelVoicePackDB = {
	["enabled"] = true,
	["pulls"] = {
		{
			["boss"] = "Imperator Averzian",
			["encounterId"] = 2639,
			["difficulty"] = "Heroic",
			["difficultyId"] = 15,
			["groupSize"] = 20,
			["startTime"] = "2026-03-27 20:31:02",
			["result"] = "wipe",
			["duration"] = "184.3s",
			["log"] = {
				"[  3.2s] key=1251361 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361y.ogg resultY=false",
				"[  3.2s] key=1251361 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361.ogg result=true",
				"[ 15.7s] key=1249262 isOnMe=true tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1249262y.ogg resultY=false",
				"[ 15.7s] key=1249262 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1249262.ogg result=true",
				"[ 28.4s] key=1280015 isOnMe=true tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1280015y.ogg resultY=false",
				"[ 28.4s] key=1280015 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1280015.ogg result=true",
				"[ 42.1s] key=1260712 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1260712y.ogg resultY=false",
				"[ 42.1s] key=1260712 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1260712.ogg result=true",
				"[ 55.0s] key=1258883 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1258883y.ogg resultY=false",
				"[ 55.0s] key=1258883 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1258883.ogg result=false",
				"[ 55.0s] key=1258883 -> BigWigs_Sound fallback (sound=Long)",
				"[ 71.3s] key=1251361 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361y.ogg resultY=false",
				"[ 71.3s] key=1251361 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361.ogg result=true",
				"[ 89.6s] key=1249251 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1249251y.ogg resultY=false",
				"[ 89.6s] key=1249251 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1249251.ogg result=false",
				"[ 89.6s] key=1249251 -> BigWigs_Sound fallback (sound=Alert)",
				"[120.5s] key=1251361 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361y.ogg resultY=false",
				"[120.5s] key=1251361 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361.ogg result=true",
				"[145.2s] key=1260712 isOnMe=true tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1260712y.ogg resultY=false",
				"[145.2s] key=1260712 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1260712.ogg result=true",
			},
			["abilities"] = {
				["1251361"] = {
					["spellName"] = "Shadow's Advance",
					["defaultSound"] = "Alert",
					["casts"] = {
						{ ["time"] = "3.2", ["isOnMe"] = false, ["played"] = "ogg" },
						{ ["time"] = "71.3", ["isOnMe"] = false, ["played"] = "ogg" },
						{ ["time"] = "120.5", ["isOnMe"] = false, ["played"] = "ogg" },
					},
				},
				["1249262"] = {
					["spellName"] = "Umbral Collapse",
					["defaultSound"] = "Alert",
					["casts"] = {
						{ ["time"] = "15.7", ["isOnMe"] = true, ["played"] = "ogg" },
					},
				},
				["1280015"] = {
					["spellName"] = "Void Marked",
					["defaultSound"] = "Alarm",
					["casts"] = {
						{ ["time"] = "28.4", ["isOnMe"] = true, ["played"] = "ogg" },
					},
				},
				["1260712"] = {
					["spellName"] = "Oblivion's Wrath",
					["defaultSound"] = "Alarm",
					["casts"] = {
						{ ["time"] = "42.1", ["isOnMe"] = false, ["played"] = "ogg" },
						{ ["time"] = "145.2", ["isOnMe"] = true, ["played"] = "ogg" },
					},
				},
				["1258883"] = {
					["spellName"] = "Void Fall",
					["defaultSound"] = "Long",
					["casts"] = {
						{ ["time"] = "55.0", ["isOnMe"] = false, ["played"] = "fallback" },
					},
				},
				["1249251"] = {
					["spellName"] = "Dark Upheaval",
					["defaultSound"] = "Alert",
					["casts"] = {
						{ ["time"] = "89.6", ["isOnMe"] = false, ["played"] = "fallback" },
					},
				},
			},
		},
		{
			["boss"] = "Imperator Averzian",
			["encounterId"] = 2639,
			["difficulty"] = "Heroic",
			["difficultyId"] = 15,
			["groupSize"] = 20,
			["startTime"] = "2026-03-27 20:38:15",
			["result"] = "kill",
			["duration"] = "312.7s",
			["log"] = {
				"[  3.1s] key=1251361 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361y.ogg resultY=false",
				"[  3.1s] key=1251361 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361.ogg result=true",
				"[ 14.9s] key=1280015 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1280015y.ogg resultY=false",
				"[ 14.9s] key=1280015 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1280015.ogg result=true",
				"[ 30.2s] key=1260712 isOnMe=true tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1260712y.ogg resultY=false",
				"[ 30.2s] key=1260712 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1260712.ogg result=true",
				"[ 45.8s] key=1249262 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1249262y.ogg resultY=false",
				"[ 45.8s] key=1249262 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1249262.ogg result=true",
				"[ 68.3s] key=1251361 isOnMe=false tryY=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361y.ogg resultY=false",
				"[ 68.3s] key=1251361 fallback=Interface\\AddOns\\BigWigs_Yvairels_VoicePack\\Sounds\\1251361.ogg result=true",
			},
			["abilities"] = {
				["1251361"] = {
					["spellName"] = "Shadow's Advance",
					["defaultSound"] = "Alert",
					["casts"] = {
						{ ["time"] = "3.1", ["isOnMe"] = false, ["played"] = "ogg" },
						{ ["time"] = "68.3", ["isOnMe"] = false, ["played"] = "ogg" },
					},
				},
				["1280015"] = {
					["spellName"] = "Void Marked",
					["defaultSound"] = "Alarm",
					["casts"] = {
						{ ["time"] = "14.9", ["isOnMe"] = false, ["played"] = "ogg" },
					},
				},
				["1260712"] = {
					["spellName"] = "Oblivion's Wrath",
					["defaultSound"] = "Alarm",
					["casts"] = {
						{ ["time"] = "30.2", ["isOnMe"] = true, ["played"] = "ogg" },
					},
				},
				["1249262"] = {
					["spellName"] = "Umbral Collapse",
					["defaultSound"] = "Alert",
					["casts"] = {
						{ ["time"] = "45.8", ["isOnMe"] = false, ["played"] = "ogg" },
					},
				},
			},
		},
	},
}

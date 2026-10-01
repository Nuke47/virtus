CH_ADVArrest = CH_ADVArrest or {}
CH_ADVArrest.Config = CH_ADVArrest.Config or {}

--[[
	SET LANGUAGE
	Available languages: English: en - Danish: da - French: fr - Spanish: es - Russian: ru - German: de - Polish: pl - Turkish: tr
--]]
CH_ADVArrest.Config.Language = "en" -- Set the language of the script.

--[[
	Configure Teams (IMPORTANT)
--]]
CH_ADVArrest.Config.AllowedTeams = { -- These are the names of the jobs that gets the new handcuffs & police baton.
	["SH: Soldado"] = true,
	["SH: Reconocimiento"] = true,
	["SH: Asalto"] = true,
	["SH: Apoyo"] = true,
	["SH: ARC"] = true,
	["SH: Comandante"] = true,
	["SH: RT Soldado"] = true,
	["SH: RT Reconocimiento"] = true,
	["SH: RT Asalto"] = true,
	["SH: RT Apoyo"] = true,
	["SH: RT ARC"] = true,
	["SH: RT Comandante"] = true,
	["SH: RT Fox"] = true,
	["SH: RT Hound"] = true,
	["SH: Thire"] = true,
	["SH: Stone"] = true,
	["SH: Clon Comando"] = true,
}

CH_ADVArrest.Config.MayorTeam = "Mayor" -- Job name of your mayor team.

-- Allow these usergroups to arrest players and give arrest stick
CH_ADVArrest.Config.GiveUsergroupsOnSpawn = false -- Should the usergroups below get the weapons on spawn/team change or not.
CH_ADVArrest.Config.AllowedUsergroups = {
	["owner"] = true,
	["superadmin"] = true,
	["admin"] = true,
}

--[[
	General Options
--]]
CH_ADVArrest.Config.StripOldWeapons = true -- Should the teams from the "CH_ADVArrest.Config.AllowedTeams" config be stripped off the old arrest/unarrest/stunstick weapons. [Default = true (RECOMMENDED)]
CH_ADVArrest.Config.NotificationTime = 5 -- Amount of seconds the notifications should display on screan for this script.

--[[
	Arresting Options
--]]
CH_ADVArrest.Config.HandcuffTime = 5 -- Time it takes to handcuff the player.

CH_ADVArrest.Config.MinBail = 0 -- The minimum amount an officer can set the bail to. (Setting bail to 0 means no bail, unarrest when time runs out!
CH_ADVArrest.Config.MaxBail = 2500 -- The maximum amount an officer can set the bail to.

CH_ADVArrest.Config.MinTime = 60 -- The minimum amount an officer can set the arrest timer to (in seconds).
CH_ADVArrest.Config.MaxTime = 300 -- The maximum amount an officer can set the arrest timer to (in seconds).

CH_ADVArrest.Config.ArrestFreezeTimer = 10 -- Amount of seconds is frozen when you start arresting (LEFT CLICK)
CH_ADVArrest.Config.ArrestDistance = 10000 -- The distance between the officer and the player before he/she can arrest them. [Default = 10000] (RECOMMENDED)

--[[
	Money Distribution (How money from bails are distributed)
	1 = The person who arrested him/her (if available).
	2 = The mayor (if there is one).
	3 = Money disappears aka noone gets any money from bails.
--]]
CH_ADVArrest.Config.MoneyDistribution = 1

--[[
	Handcuff Options
--]]
CH_ADVArrest.Config.WeaponSwitchedHandcuffed = "keys" -- What weapon should the target switch to when they get handcuffed?

CH_ADVArrest.Config.ArrestedWalkSpeed = 100 -- How fast the player can walk while an arrest is happening (after being handcuffed). [Default = 100]
CH_ADVArrest.Config.ArrestedRunSpeed = 100 -- How fast the player can run while an arrest is happening (after being handcuffed). [Default = 100]

--[[
	Police Baton Options
--]]
CH_ADVArrest.Config.BatonDamage = 3 -- Amount of damamge given to the player when you hit them with the police baton.
CH_ADVArrest.Config.BatonHitDelay = 1 -- Amount of seconds delay on the police baton.

--[[
	Jailer NPC
--]]
CH_ADVArrest.Config.EnableJailerNPC = false -- Should the jailer NPC be enabled? This DISABLES arresting through the handcuffs and forces police to bring the target to the NPC to arrest them.
CH_ADVArrest.Config.JailerNPCModel = "models/Police.mdl"

CH_ADVArrest.Config.NPCTextColor = Color( 255, 255, 255, 255 )
CH_ADVArrest.Config.NPCTextColorOutline = Color( 0, 0, 0, 255 )

--[[
	Weapon Inspection
--]]
CH_ADVArrest.Config.InspectBlacklistWeapons = { -- These weapons will not show up during an inspection
	["adv_arresting_handcuffs"] = true,
	["adv_arresting_baton"] = true,
	["weapon_dev_tool"] = true,
	["itemstore_checker"] = true,
	["itemstore_pickup"] = true,
	["ch_bitminers_repair_wrench"] = true,
	["ch_bitminers_tablet"] = true,
	["defibrillator_advanced"] = true,
	["med_kit_advanced"] = true,
	["weapon_adv_keys"] = true,
	["keys"] = true,
	["weapon_doortool"] = true,
	["weapon_advram"] = true,
	["fire_axe"] = true,
	["fire_extinguisher"] = true,
	["traffic_confiscatenpc"] = true,
	["traffic_tienpctruck"] = true,
	["tow_attach"] = true,
	["cocaine_repair_wrench"] = true,
	["weapon_nuke"] = true,
}

--[[
	Change Job Arrest Options
--]]
CH_ADVArrest.Config.ChangeJobOnArrested = false -- Should the arrested player change their job when arrested? It changes back when unarrested.
timer.Simple( 10, function()

	CH_ADVArrest.Config.JobChangeTo = TEAM_THIEF -- What job should the player change to if enabled?

end )
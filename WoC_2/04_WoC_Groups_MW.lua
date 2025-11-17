

Group_Blue_SAM_Site = "Hawk_Site"
Group_Blue_Mech = "Blue_Mech_Bradley_Template"
Group_Blue_APC = "Blue_APC_MRAP_Template"
Group_Blue_Armoured = "Blue_Armoured_Abrams_Template"
Group_Blue_Arty = "Blue_ART_M109_Template"
Group_Blue_Inf = "Blue_INF_M4_Template"
Group_Blue_Truck = "Blue_Truck_M939_Template"
Group_Blue_SAM1 = "Blue_SAM_Roland_Template"
Group_Blue_SAM2= "Blue_SAM_Avenger_Template"
Group_Blue_SAM3= "Blue_SAM_CRAM_Template"
Group_Blue_SAM4= "Blue_SAM_NASAM_Template"

Blue_Fighter1 = "F-15E"
Blue_Fighter2 = "F-14"
Blue_Fighter3 = "F-4E"
Blue_LT_Fighter1 = "F-16"
Blue_LT_Fighter2 = "FA-18"
Blue_LT_Fighter3 = "M2000"
Blue_Attack1 = "A-10"
Blue_Attack2 = "F-4E"
Blue_Attack3 = "FA-18"

Blue_Helo1 = "UH-60"
Blue_Helo2 = "UH-60"
Blue_Helo3 = "UH-1"
Blue_AttackHelo1 = "AH-64"
Blue_AttackHelo2 = "AH-64"
Blue_AttackHelo3 = "UH-1"
Blue_Fighters ={Blue_Fighter1,Blue_Fighter2,Blue_Fighter3}
Blue_LT_Fighters ={Blue_LT_Fighter1,Blue_LT_Fighter2,Blue_LT_Fighter3}
Blue_Attack ={Blue_Attack1,Blue_Attack2,Blue_Attack3}   
Blue_Helos ={Blue_Helo1,Blue_Helo2,Blue_Helo3}
Blue_AttackHelos ={Blue_AttackHelo1,Blue_AttackHelo2,Blue_AttackHelo3}




CW78_Blue_Groups = {Group_Blue_SAM_Site,Group_Blue_SAM,Group_Blue_Mech,Group_Blue_APC,Group_Blue_Armoured,Group_Blue_Inf,Group_Blue_Truck }

Group_Red_SAM_Site = "Red_S300_Site"
Group_Red_Mech = "Red_Mech_BMP3_Template"
Group_Red_APC = "Red_APC_BTR80_Template"
Group_Red_Armoured = "Red_Armoured_T80_Template"
Group_Red_Arty = "Red_ART_MSTA152_Template"
Group_Red_Inf = "Red_INF_Template"
Group_Red_Truck = "Red_Truck_Ural4320_Template"

Group_Red_SAM1 = "Red_SAM_SA15_Template"
Group_Red_SAM2 = "Red_SAM_SA9_Template"
Group_Red_SAM3 = "Red_SAM_SA8_Template"
Group_Red_SAM4 = "Red_SAM_ZSU_Template"
Red_Fighters ={Red_Fighter1,Red_Fighter2,Red_Fighter3}
Red_Fighter1 = "SU-30"
Red_Fighter2 = "Mig-25"
Red_Fighter3 = "Mig-31"
Red_LT_Fighter1 = "Mig-29"
Red_LT_Fighter2 = "SU-27"
Red_LT_Fighter3 = "Mig-21"
Red_Attack1 = "SU-34"
Red_Attack2 = "SU-25"
Red_Attack3 = "SU-30"
Red_Helo1 = "MI-26"
Red_Helo2 = "MI-8"
Red_Helo3 = "MI-24"
Red_AttackHelo1 = "KA-50"
Red_AttackHelo2 = "MI-8"
Red_AttackHelo3 = "MI-24"

Group_Neutral_Inf = "Neutral_INF_M4_Template"

CW78_Red_Groups = {Group_Red_SAM_Site,Group_Red_SAM,Group_Red_Mech,Group_Red_APC,Group_Red_Armoured,Group_Red_Inf,Group_Red_Truck }
Red_Fighters ={Red_Fighter1,Red_Fighter2,Red_Fighter3}
Red_LT_Fighters ={Red_LT_Fighter1,Red_LT_Fighter2,Red_LT_Fighter3}
Red_Attack ={Red_Attack1,Red_Attack2,Red_Attack3}
Red_Helos ={Red_Helo1,Red_Helo2,Red_Helo3}
Red_AttackHelos ={Red_AttackHelo1,Red_AttackHelo2,Red_AttackHelo3}

local FighterTemplates = {
    blue = {
        {
            template = Blue_Fighters, -- table of template names
            name = "Fighter",
            count = 4,
            missions = {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON},
            priority = 90,
            payloads = {
                { pName = "Blue_payload_Fighter_AA",    pTname = "_AA",   pcount = 4, pmission = {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON}, pPriority = 90 },
                { pName = "Blue_payload_Fighter_CAS",   pTname = "_CAS",  pcount = 4, pmission = {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},            pPriority = 50 },
            },
        },
        {
            template = Blue_LT_Fighters,
            name = "LT_Fighter",
            count = 2,
            missions = {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON},
            priority = 80,
            payloads = {
                { pName = "Blue_payload_LtFighter_AA",  pTname = "_AA",   pcount = 2, pmission = {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON}, pPriority = 80 },
                { pName = "Blue_payload_LtFighter_CAS", pTname = "_CAS",  pcount = 2, pmission = {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},            pPriority = 70 },
                { pName = "Blue_payload_LtFighter_SEAD",pTname = "_SEAD", pcount = 4, pmission = {AUFTRAG.Type.SEAD},                                                                 pPriority = 100 },
            },
        },
        {
            template = Blue_Attack,
            name = "Attack",
            count = 2,
            missions = {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING, AUFTRAG.Type.SEAD},
            priority = 85,
            payloads = {
                { pName = "Blue_payload_Attack_CAS",  pTname = "_CAS",  pcount = 2, pmission = {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING}, pPriority = 80 },
                { pName = "Blue_payload_Attack_SEAD", pTname = "_SEAD", pcount = 2, pmission = {AUFTRAG.Type.SEAD},                                                                 pPriority = 80 },
            },
        },
        {
            template = Blue_Helos,
            name = "Helo",
            count = 4,
            missions = {AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.OPSTRANSPORT},
            priority = 90,
            payloads = {
                { pName = "Blue_payload_Helo_Trans", pTname = "_Trans", pcount = 4, pmission = {AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT}, pPriority = 80 },
                { pName = "Blue_payload_Helo_CAS",   pTname = "_CAS",   pcount = 4, pmission = {AUFTRAG.Type.CAS},                                  pPriority = 80 },
            },
        },
        {
            template = Blue_AttackHelos,
            name = "AttackHelo",
            count = 4,
            missions = {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.ESCORT},
            priority = 90,
            payloads = {
                { pName = "Blue_payload_AttackHelo_CAS",  pTname = "_CAS",  pcount = 4, pmission = {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.ESCORT}, pPriority = 50 },
            },
        },
    },

    red = {
        {
            template = Red_Fighters,
            name = "Fighter",
            count = 4,
            missions = {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON},
            priority = 90,
            payloads = {
                { pName = "Red_payload_Fighter_AA", pTname = "_AA", pcount = 4, pmission = {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON}, pPriority = 90 },
            },
        },
        {
            template = Red_LT_Fighters,
            name = "LT_Fighter",
            count = 4,
            missions = {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON},
            priority = 90,
            payloads = {
                { pName = "Red_payload_LTFighter_CAS", pTname = "_CAS", pcount = 4, pmission = {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING}, pPriority = 70 },
                { pName = "Red_payload_LtFighter_AA",  pTname = "_AA",  pcount = 2, pmission = {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON}, pPriority = 70 },
            },
        },
        {
            template = Red_Attack,
            name = "Attack",
            count = 4,
            missions = {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},
            priority = 90,
            payloads = {
                { pName = "Red_payload_Attack_SEAD", pTname = "_SEAD", pcount = 2, pmission = {AUFTRAG.Type.SEAD}, pPriority = 90 },
                { pName = "Red_payload_Attack_CAS",  pTname = "_CAS",  pcount = 2, pmission = {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING}, pPriority = 80 },
            },
        },
        {
            template = Red_Helos,
            name = "Helo",
            count = 4,
            missions = {AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.OPSTRANSPORT},
            priority = 90,
            payloads = {
                { pName = "Red_payload_helo_Trans", pTname = "_Trans", pcount = 4, pmission = {AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT}, pPriority = 80 },
                { pName = "Red_payload_helo_CAS",   pTname = "_CAS",   pcount = 4, pmission = {AUFTRAG.Type.CAS},                                  pPriority = 80 },
            },
        },
        {
            template = Red_AttackHelos,
            name = "AttackHelo",
            count = 4,
            missions = {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.ESCORT},
            priority = 90,
            payloads = {
                { pName = "Red_payload_Attackhelo_CAS",   pTname = "_CAS",   pcount = 4, pmission = {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.ESCORT}, pPriority = 50 },
                { pName = "Red_payload_Attackhelo_Trans", pTname = "_Trans", pcount = 4, pmission = {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.ESCORT}, pPriority = 50 },
            },
        },
    },
}
-- Usage note:
-- When selecting a specific template from fighter.template (a list), build the payload group name as:
-- local chosenTemplate = fighter.template[randomIndex]     -- e.g. "F-15E"
-- local fullPayloadGroupName = chosenTemplate .. payload.pTname   -- e.g. "F-15E_AA"
-- then call airwing:NewPayload(GROUP:FindByName(fullPayloadGroupName), payload.pcount, payload.pmission, payload.pPriority)



-- Brigade / Platoon configuration tables
local BrigadeTemplates = {
    blue = {
        { key="apc",      template = Group_Blue_APC,      count = 5, name = "Motorised Platoon", missions = APC_MissionSet,   priority = 60, attribute = GROUP.Attribute.GROUND_APC },
        { key="mech",     template = Group_Blue_Mech,     count = 5, name = "Mechanised Platoon", missions = IFV_MissionSet,   priority = 70, attribute = GROUP.Attribute.GROUND_APC, weaponRange = {0.5, 20} },
        { key="armour",   template = Group_Blue_Armoured, count = 5, name = "Armoured Platoon",   missions = MBT_MissionSet,   priority = 80 },
        { key="logi",     template = Group_Blue_Truck,    count = 5, name = "Logistics Platoon",  missions = {AUFTRAG.Type.AMMOSUPPLY}, priority = 70 },
        { key="sam",      template = Group_Blue_SAM,      count = 5, name = "SAM Platoon",        missions = {AUFTRAG.Type.AIRDEFENSE}, priority = 100 },
        -- arty / inf entries can be added/disabled here
    },
    red = {
        { key="apc",      template = Group_Red_APC,      count = 5, name = "Motorised Platoon", missions = APC_MissionSet,   priority = 60, attribute = GROUP.Attribute.GROUND_APC },
        { key="mech",     template = Group_Red_Mech,     count = 5, name = "Mechanised Platoon", missions = IFV_MissionSet,   priority = 70, attribute = GROUP.Attribute.GROUND_APC, weaponRange = {0.5, 20} },
        { key="armour",   template = Group_Red_Armoured, count = 5, name = "Armoured Platoon",   missions = MBT_MissionSet,   priority = 80 },
        { key="logi",     template = Group_Red_Truck,    count = 5, name = "Logistics Platoon",  missions = {AUFTRAG.Type.AMMOSUPPLY}, priority = 70 },
        { key="sam",      template = Group_Red_SAM,      count = 5, name = "SAM Platoon",        missions = {AUFTRAG.Type.AIRDEFENSE}, priority = 100 },
    }
}
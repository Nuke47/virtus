
local DATA = {}
DATA.Name = "[LSCS] HoldType Butterfly"
DATA.HoldType = "lscs_butterfly"
DATA.BaseHoldType = "melee"
DATA.Translations = {} 
DATA.Translations[ ACT_MP_STAND_IDLE ] = "vanguard_f_idle"
DATA.Translations[ ACT_MP_WALK ] = "walk_knife"
DATA.Translations[ ACT_MP_RUN ] = "run_knife"
local DATA = {}
DATA.Name = "[LSCS] HoldType Butterfly"
DATA.HoldType = "lscs_butterfly"
DATA.BaseHoldType = "melee"
DATA.Translations = {} 
DATA.Translations[ ACT_MP_STAND_IDLE ] = "vanguard_f_idle"
DATA.Translations[ ACT_MP_WALK ] = "walk_knife"
DATA.Translations[ ACT_MP_RUN ] = "wos_ryoku_b_run"
wOS.AnimExtension:RegisterHoldtype( DATA )
local DATA2 = {}
DATA2.Name = "[LSCS] HoldType Defense"
DATA2.HoldType = "lscs_defense"
DATA2.BaseHoldType = "melee2"
DATA2.Translations = {} 
DATA2.Translations[ ACT_MP_STAND_IDLE ] = "phalanx_r_idle"
DATA2.Translations[ ACT_MP_WALK ] = "wos_bs_shared_sidewalk_lower"
DATA2.Translations[ ACT_MP_RUN ] = "wos_bs_shared_sidewalk_lower"
DATA2.Translations[ ACT_MP_CROUCH_IDLE ] = "phalanx_r_idle"
DATA2.Translations[ ACT_MP_CROUCHWALK ] = "wos_bs_shared_sidewalk_lower"
wOS.AnimExtension:RegisterHoldtype( DATA2 )

local DATA3 = {}
DATA3.Name = "[LSCS] HoldType Deflecting"
DATA3.HoldType = "lscs_deflecting"
DATA3.BaseHoldType = "melee2"
DATA3.Translations = {} 
DATA3.Translations[ ACT_MP_STAND_IDLE ] = "phalanx_r_idle"
DATA3.Translations[ ACT_MP_WALK ] = "wos_bs_shared_walk_lower_2"
DATA3.Translations[ ACT_MP_RUN ] = "wos_bs_shared_walk_lower_2"
DATA3.Translations[ ACT_MP_CROUCH_IDLE ] = "phalanx_r_idle"
DATA3.Translations[ ACT_MP_CROUCHWALK ] = "wos_bs_shared_walk_lower_2"
wOS.AnimExtension:RegisterHoldtype( DATA3 )
wOS.AnimExtension:RegisterHoldtype( DATA2 )

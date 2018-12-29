--lord 通用属性定义
local LordDef = {}

-- play scene view界面 viewtag
-- TAG_SIGNUP_WAIT_VIEW = 1
-- TAG_ROUND_WAIT_VIEW = 2
LordDef.TAG_PLAY_VIEW = 3
-- TAG_AWARD_VIEW = 4
-- TAG_ISLAND_WAIT_VIEW = 5
-- TAG_HISTORY_WAIT_VIEW = 6
LordDef.TAG_DIPLOMA_VIEW = 7
-- TAG_PROMOTION_WAIT_VIEW = 8
-- TAG_REVIVE_WAIT_VIEW = 10
-- TAG_DIALOG_CONFIRM_WAIT_VIEW=11

LordDef.PLAYER_POSITION_PRE = 1
LordDef.PLAYER_POSITION_SELF = 2
LordDef.PLAYER_POSITION_NEXT = 3

--Action定义
LordDef.ACTION_CALL_SCORE = 1 --叫分
LordDef.ACTION_PRODUCT_CARD = 2 --出牌
LordDef.ACTION_PRODUCT_RESELECT = 3 --重选
LordDef.ACTION_PRODUCT_PROMPT = 4 --出牌提示
LordDef.ACTION_PRODUCT_PASS = 5 --要不起
LordDef.ACTION_TRUST = 6 --托管

--CallRobLord定义
LordDef.HLLORD_ACTION_CALL_LORD = 7 -- 叫地主
LordDef.HLLORD_ACTION_NO_CALL = 8 -- 不叫
LordDef.HLLORD_ACTION_ROB_LORD = 9 -- 抢地主
LordDef.HLLORD_ACTION_NO_ROB = 10 -- 不抢
LordDef.HLLORD_ACTION_DOUBLE = 11 -- 加倍
LordDef.HLLORD_ACTION_NO_DOUBLE = 12 -- 不加倍
LordDef.HLLORD_ACTION_SHOW_CARD = 13 -- 明牌
LordDef.HLLORD_ACTION_NO_SHOW_CARD = 14 -- 不明牌

--ShowCard定义
LordDef.SHOW_CARD = 11 -- 明牌

LordDef.GAME_SFX_BG = {
    BG_SOUND_PLAY = "sound/lordsinglexhcg/lord_play_bg1.mp3",
    BG_SOUND_LOBBY = "sound/lordsinglexhcg/lordsinglexhcg_bg.mp3",
    BG_PROMOTE = "sound/lordsinglexhcg/lord_play_bg1.mp3",
    BG_MULTI_INC = "sound/lordsinglexhcg/lord_play_bg2.mp3",
}

-- 声音资源
LordDef.GAME_SFX = {

        LORD_SOUND_SHUFF_CARD = "sound/lordsinglexhcg/lord_s_shuff_card.mp3",
        LORD_SOUND_DISCARD = "sound/lordsinglexhcg/lord_s_discard.mp3",
        LORD_SOUND_TIME = "sound/lordsinglexhcg/lord_s_time.mp3",
        LORD_SOUND_PLANE = "sound/lordsinglexhcg/lord_s_plane.mp3",
        LORD_SOUND_ROCKET = "sound/lordsinglexhcg/lord_s_rocket.mp3",
        LORD_SOUND_BOMB = "sound/lordsinglexhcg/lord_s_bomb.mp3",
        LORD_SOUND_TRUST = "sound/lordsinglexhcg/lord_s_trust.mp3",
        LORD_SOUND_LOSE = "sound/lordsinglexhcg/lord_gamelose.mp3",
        LORD_SOUND_WIN = "sound/lordsinglexhcg/lord_gamewin.mp3",
        LORD_SOUND_SPRING = "sound/lordsinglexhcg/lordhl_s_spring.mp3",

        LORD_VOICE_0_SCORE = "sound/lordsinglexhcg/lord_v_callscore_0.mp3",
        LORD_VOICE_1_SCORE = "sound/lordsinglexhcg/lord_v_callscore_1.mp3",
        LORD_VOICE_2_SCORE = "sound/lordsinglexhcg/lord_v_callscore_2.mp3",
        LORD_VOICE_3_SCORE = "sound/lordsinglexhcg/lord_v_callscore_3.mp3",
        LORD_VOICE_PASS_1 = "sound/lordsinglexhcg/lord_v_pass_1.mp3",
        LORD_VOICE_PASS_2 = "sound/lordsinglexhcg/lord_v_pass_2.mp3",
        LORD_VOICE_PASS_3 = "sound/lordsinglexhcg/lord_v_pass_3.mp3",
        LORD_VOICE_DISCARD_1 = "sound/lordsinglexhcg/lord_v_discard_1.mp3",
        LORD_VOICE_DISCARD_2 = "sound/lordsinglexhcg/lord_v_discard_2.mp3",
        LORD_VOICE_DISCARD_3 = "sound/lordsinglexhcg/lord_v_discard_3.mp3",
        LORD_VOICE_PLANE_1 = "sound/lordsinglexhcg/lord_v_plane_1.mp3",
        LORD_VOICE_PLANE_2 = "sound/lordsinglexhcg/lord_v_plane_2.mp3",
        LORD_VOICE_BOMB_1 = "sound/lordsinglexhcg/lord_v_bomb_1.mp3",
        LORD_VOICE_BOMB_2 = "sound/lordsinglexhcg/lord_v_bomb_2.mp3",
        LORD_VOICE_ROCKET = "sound/lordsinglexhcg/lord_v_rocket.mp3",
        LORD_VOICE_THREE_WITH_ONE = "sound/lordsinglexhcg/lord_v_3with1.mp3",
        LORD_VOICE_THREE_WITH_TWO = "sound/lordsinglexhcg/lord_v_3with2.mp3",
        LORD_VOICE_STRAIGHT = "sound/lordsinglexhcg/lord_v_straight.mp3",
        LORD_VOICE_CHAINPAIRS = "sound/lordsinglexhcg/lord_v_chainpairs.mp3",
        LORD_VOICE_REMAIN_1 = "sound/lordsinglexhcg/lord_v_remain1.mp3",
        LORD_VOICE_REMAIN_2 = "sound/lordsinglexhcg/lord_v_remain2.mp3",
        LORD_VOICE_4WITH2 = "sound/lordsinglexhcg/lord_v_4with2.mp3",

        LORD_VOICE_1CARD_2 = "sound/lordsinglexhcg/lord_v_1card_2.mp3",
        LORD_VOICE_1CARD_3 = "sound/lordsinglexhcg/lord_v_1card_3.mp3",
        LORD_VOICE_1CARD_4 = "sound/lordsinglexhcg/lord_v_1card_4.mp3",
        LORD_VOICE_1CARD_5 = "sound/lordsinglexhcg/lord_v_1card_5.mp3",
        LORD_VOICE_1CARD_6 = "sound/lordsinglexhcg/lord_v_1card_6.mp3",
        LORD_VOICE_1CARD_7 = "sound/lordsinglexhcg/lord_v_1card_7.mp3",
        LORD_VOICE_1CARD_8 = "sound/lordsinglexhcg/lord_v_1card_8.mp3",
        LORD_VOICE_1CARD_9 = "sound/lordsinglexhcg/lord_v_1card_9.mp3",
        LORD_VOICE_1CARD_10 = "sound/lordsinglexhcg/lord_v_1card_10.mp3",
        LORD_VOICE_1CARD_J = "sound/lordsinglexhcg/lord_v_1card_j.mp3",
        LORD_VOICE_1CARD_Q = "sound/lordsinglexhcg/lord_v_1card_q.mp3",
        LORD_VOICE_1CARD_K = "sound/lordsinglexhcg/lord_v_1card_k.mp3",
        LORD_VOICE_1CARD_A = "sound/lordsinglexhcg/lord_v_1card_a.mp3",
        LORD_VOICE_1CARD_LITTLE_JOKER = "sound/lordsinglexhcg/lord_v_1card_small_joker.mp3",
        LORD_VOICE_1CARD_BIG_JOKER = "sound/lordsinglexhcg/lord_v_1card_big_joker.mp3",

        LORD_VOICE_2CARD_2 = "sound/lordsinglexhcg/lord_v_2card_2.mp3",
        LORD_VOICE_2CARD_3 = "sound/lordsinglexhcg/lord_v_2card_3.mp3",
        LORD_VOICE_2CARD_4 = "sound/lordsinglexhcg/lord_v_2card_4.mp3",
        LORD_VOICE_2CARD_5 = "sound/lordsinglexhcg/lord_v_2card_5.mp3",
        LORD_VOICE_2CARD_6 = "sound/lordsinglexhcg/lord_v_2card_6.mp3",
        LORD_VOICE_2CARD_7 = "sound/lordsinglexhcg/lord_v_2card_7.mp3",
        LORD_VOICE_2CARD_8 = "sound/lordsinglexhcg/lord_v_2card_8.mp3",
        LORD_VOICE_2CARD_9 = "sound/lordsinglexhcg/lord_v_2card_9.mp3",
        LORD_VOICE_2CARD_10 = "sound/lordsinglexhcg/lord_v_2card_10.mp3",
        LORD_VOICE_2CARD_J = "sound/lordsinglexhcg/lord_v_2card_j.mp3",
        LORD_VOICE_2CARD_Q = "sound/lordsinglexhcg/lord_v_2card_q.mp3",
        LORD_VOICE_2CARD_K = "sound/lordsinglexhcg/lord_v_2card_k.mp3",
        LORD_VOICE_2CARD_A = "sound/lordsinglexhcg/lord_v_2card_a.mp3",

        LORD_VOICE_3CARD_2 = "sound/lordsinglexhcg/lord_v_3card_2.mp3",
        LORD_VOICE_3CARD_3 = "sound/lordsinglexhcg/lord_v_3card_3.mp3",
        LORD_VOICE_3CARD_4 = "sound/lordsinglexhcg/lord_v_3card_4.mp3",
        LORD_VOICE_3CARD_5 = "sound/lordsinglexhcg/lord_v_3card_5.mp3",
        LORD_VOICE_3CARD_6 = "sound/lordsinglexhcg/lord_v_3card_6.mp3",
        LORD_VOICE_3CARD_7 = "sound/lordsinglexhcg/lord_v_3card_7.mp3",
        LORD_VOICE_3CARD_8 = "sound/lordsinglexhcg/lord_v_3card_8.mp3",
        LORD_VOICE_3CARD_9 = "sound/lordsinglexhcg/lord_v_3card_9.mp3",
        LORD_VOICE_3CARD_10 = "sound/lordsinglexhcg/lord_v_3card_10.mp3",
        LORD_VOICE_3CARD_J = "sound/lordsinglexhcg/lord_v_3card_j.mp3",
        LORD_VOICE_3CARD_Q = "sound/lordsinglexhcg/lord_v_3card_q.mp3",
        LORD_VOICE_3CARD_K = "sound/lordsinglexhcg/lord_v_3card_k.mp3",
        LORD_VOICE_3CARD_A = "sound/lordsinglexhcg/lord_v_3card_a.mp3",

        HLLORD_VOICE_CALLLORD="sound/lordsinglexhcg/lordhl_v_call_lord.mp3",
        HLLORD_VOICE_ROBLORD="sound/lordsinglexhcg/lordhl_v_rob.mp3",
        HLLORD_VOICE_NOT_ROBLORD="sound/lordsinglexhcg/lordhl_v_no_rob.mp3",
        HLLORD_VOICE_SHOW_CARDS="sound/lordsinglexhcg/lordhl_v_show_cards.mp3",
        HLLORD_S_SHOW_CARDS="sound/lordsinglexhcg/lordhl_s_show_cards.mp3",
        HLLORD_VOICE_DOUBLE="sound/lordsinglexhcg/lordhl_v_double.mp3",
        HLLORD_VOICE_NOT_DOUBLE="sound/lordsinglexhcg/lordhl_v_no_double.mp3",
        HLLORD_VOICE_I_AM_LORD="sound/lordsinglexhcg/lordhl_v_i_am_lord.mp3",

        LORDSINGLEXHCG_VOICE_COUNT_DOWN="sound/lordsinglexhcg/lordsinglexhcg_count_down.mp3",
        LORDSINGLEXHCG_VOICE_COUNT_DOWN_5="sound/lordsinglexhcg/lordsinglexhcg_count_down_5.mp3",
}

return LordDef
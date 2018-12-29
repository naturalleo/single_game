require("data.LordDef")

--local LordUnionData = class("LordUnionData", require("game.data.game.GameData"))
local LordUnionData = class("LordUnionData")

LordUnionGameState = {}

LordUnionGameState.STATE_FIRST_WAIT = 110
LordUnionGameState.STATE_START_GAME = 120 --游戏开始

LordUnionGameState.STATE_DISPATCHING = 130     --发牌
LordUnionGameState.STATE_DISPATCHING_1 = 131     --发牌阶段1, 欢斗特有
LordUnionGameState.STATE_DISPATCHING_2 = 132     --发牌阶段2, 欢斗特有
LordUnionGameState.STATE_DISPATCHING_3 = 133     --发牌阶段3, 欢斗特有
LordUnionGameState.STATE_DISPATCHING_4 = 134     --发牌阶段4, 欢斗特有
LordUnionGameState.STATE_DISPATCH_FINISH = 135     --发牌阶段完成

LordUnionGameState.STATE_START_CALL_LORD = 140     --开始叫地主
LordUnionGameState.STATE_CALL_LORD = 141     --叫地主
LordUnionGameState.STATE_START_ROB_LORD = 142     --开始抢地主
LordUnionGameState.STATE_ROB_LORD = 143     --抢地主
LordUnionGameState.STATE_DECLARE_LORD = 144     --确定地主

LordUnionGameState.STATE_WAIT_LORD_SHOW_CARD = 150     --等待地主明牌

LordUnionGameState.STATE_START_DOUBLE = 160     --开始加倍
LordUnionGameState.STATE_DOUBLE = 161     --加倍
LordUnionGameState.STATE_GIVE_UP_LEAD  = 162  --让牌, 二斗

LordUnionGameState.STATE_START_PLAY  = 170 --可以开始打牌了，
LordUnionGameState.STATE_START_PLAY_WAIT_ACK  = 171 --等待地主出牌
LordUnionGameState.STATE_PLAY = 172 --正式开始打牌
LordUnionGameState.STATE_PLAY_WAIT_ACK  = 173 --出牌后等待别的玩家出牌


LordUnionGameState.STATE_END_HAND = 180 -- 结算

LordUnionGameState.STATE_WAIT = 200 --比赛结束，等待组桌或晋级
LordUnionGameState.WAIT_STATE_AWARD = 201 --单机斗，等待颁奖
LordUnionGameState.WAIT_STATE_ISLAND = 202 --单机斗，岛屿等待

function LordUnionData:ctor(gameid)
    --LordUnionData.super.ctor(self, 0, gameid)
end

function LordUnionData:resetGame()
    --LordUnionData.super.resetGame(self)
end

function LordUnionData:resetRound()
    --LordUnionData.super.resetRound(self)
end

return LordUnionData

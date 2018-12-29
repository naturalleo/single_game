-- 斗地主玩家信息

local LordPlayerInfo = class("LordPlayerInfo", require("data.PlayerInfo"))

function LordPlayerInfo:ctor()
    self.super.ctor(self)
    self.handTime_ = 15 -- 没手牌时间
    self.cardCount_ = 0 -- 有多少张牌
    self.takeOutCount_ = 0 -- 出了几手牌，用于计算赖子斗地主的春天
    self.isTakeOuted_ = false --新一局开始后，是否有过出牌或不出动作，用于判断是否需要提示“pass”
    self.isLastCardAutoTrust_ = false -- 赖斗最后一张牌是否托管，在客户端处理
end

function LordPlayerInfo:init()
    self.handTime_ = 15
    self.cardCount_ = 0
    self.takeOutCount_ = 0
    self.isTakeOuted_ = false
    self.isLastCardAutoTrust_ = false
end

function LordPlayerInfo:toSaveData()
    local saveData = {}
    saveData.arrived = self.arrived_
    saveData.cardCount_ = self.cardCount_
    saveData.figureId_ = self.figureId_
    saveData.handTime_ = self.handTime_
    saveData.headImgSrc = self.headImgSrc
    saveData.isLastCardAutoTrust_ = self.isLastCardAutoTrust_
    saveData.isTakeOuted_ = self.isTakeOuted_
    saveData.matchExcp_ = self.matchExcp_
    saveData.netStatus_ = self.netStatus_
    saveData.nickName_ = self.nickName_
    saveData.rankScore_ = self.rankScore_
    saveData.rank_ = self.rank_
    saveData.score_ = self.score_
    saveData.seat_ = self.seat_
    saveData.singleGamePlayerId_ = self.singleGamePlayerId_
    saveData.takeOutCount_ = self.takeOutCount_
    saveData.totalHand_ = self.totalHand_
    saveData.trust_ = self.trust_
    saveData.userId_ = self.userId_
    saveData.winHand_ = self.winHand_
    return saveData
end

return LordPlayerInfo
local LordData = class("LordData", require("data.LordUnionData"))
local Card = require("logic.Card")
local LordDef = require("data.LordDef")
local log_util = require "utils/log_util"

LordData.NOT_TRUST = 0 --去解除托管
LordData.TRUST_BY_USER = 1 --主动托管
LordData.TRUST_BY_SERVER = 2 --被动托管
local TAG = "LordData"

function LordData:ctor()
    self.super.ctor(self)

    self.promotionView_ = true

    self.playerInfoMap_ = {} --玩家信息 {int, LordPlayerInfo}
    self.arrCards = {} -- 玩家手牌{int}
    self.jjBomb = true -- 是否使用JJ炸弹规则    --yanlz:嘻哈单机5期：炸弹规则需要改为JJ炸弹规则
    self.lordSeat = -1 -- 地主位置
    self.bottomScore = 1 -- 底分
    self.baseScore = nil -- 基数
    self.arrBottomCards = {} -- 底牌 --linxh 建议使用Card对象保存，不建议使用int值，参考getCards函数
    self.multiple = 1 -- 当前倍数
    self.bombNum = 0 -- 炸弹数量
    self.springNum = 0 -- 春天数量
    self.lordResultData = nil --结果数据
    self.winSeat = -1 -- 赢家座位
    self.validScore = 0 -- 当前叫分
    self.isSettingViewVisible = false --设置弹出框是否显示
    self.isHideName = false -- 是否隐名比赛
    self.isHideNameIsland = false -- 是否隐名岛屿赛
    self.needPlayDealCards = false --手牌是否需要播放发牌动画
    self.canDisplayCallScore_ = false

    self.lastTakeOutCards = {}
    self.curHand = {} --当前牌桌显示的牌再上一手
    self.lastHand = {} --上手牌：当前牌桌显示的牌再上一手

    -- self.selfTakeOutCard = nil -- 记录自己出的牌，回消息时校验

    self.trustStatus_ = LordData.NOT_TRUST 

    self.lordTakeOutCardCount_ = 0 -- 单机判断春天依据
    self.firstCallSeat = -1 -- 第一个叫分的座位号，在无人叫分的情况下第一个叫分的为地主
    self.callScoreCount_ = 1 -- 单机叫分次数
    self.isUseBomb = false -- 单机游戏是否出过炸弹

    self.limitCardType = {}
    self.isRandomSortCard = false
    self.isUseRobLord = false
    self.isUseGiveLord = false
    self.isHideCardCount = false
    self.isCountDown = false
    self.isSimpleBomb = false
    self.isDoubleScoreForNpc = false
    self.isNotReduceNpcScore = false
    self.isUseGamblerGog = false
    self.lastWinSeat = -1
    self.npcWinCount = 0
    self.isUserWin = false

    self.userWinCount = 0
    self.userLoseCount = 0
    self.userTotalWinExp = 0
    self.userTotalWinGold = 0
    self.messLevel = 0

    self.isPlaySkillAnim = false

    self.messStartTime = nil
    self.isCanNotTakeOutSkillAnimPlaying = nil
    self.countDounTime = 15
    self.isMessAnswer = false
    self.gameShareInfo = {}
    self.isShowShareDialog = false
    self.shareText = false
    self.diplomaData = nil

    -----------------------------------------------------
    --yanlz：嘻哈单机5期：经验奖励倍数优化：获胜时有加倍，获胜经验也加相同倍数
    self.winExpMulti_ = 1    --yanlz：获胜经验值倍数：默认1倍 --嘻哈单机5期
    self.bottomCardMulti_ = 1    --yanlz：底牌加倍--嘻哈茶馆只有双王/单王/对2的底牌加倍 --嘻哈单机5期

end

function LordData:resetGame()
    LordData.super.resetGame(self)

    for i = 0, 2 do
        self.curHand[i] = nil
        self.lastHand[i] = nil
        self.lastTakeOutCards[i] = nil
    end

    self:resetPlayerInfo()

    self.arrCards = {}
    self.lordSeat = -1
    self.bottomScore = 1
    self.arrBottomCards = nil
    self.multiple = 1
    self.bombNum = 0
    self.springNum = 0
    self.winSeat = -1
    self.validScore = 0

    self.isSettingViewVisible = false
    self.lordResultData = nil
    -- self.selfTakeOutCard = nil
    self.lordTakeOutCardCount_ = 0
    self.firstCallSeat = -1
	self.callScoreCount_ = 1
    self.isUseBomb = false
    self.canDisplayCallScore_ = false

    self.messStartTime = nil
    self.isCanNotTakeOutSkillAnimPlaying = nil
    self.messLevel = 0
    self.isPlaySkillAnim = true

    self.limitCardType = {}
    self.isUseRobLord = false
    self.isUseGiveLord = false
    self.isHideCardCount = false
    self.isCountDown = false
    self.isSimpleBomb = false
    self.isDoubleScoreForNpc = false
    self.isNotReduceNpcScore = false
    self.isUseGamblerGog = false
    self.isRandomSortCard = false
    self.isUserWin = false
    self.countDounTime = 15
    self.gameShareInfo = {}

    -----------------------------------------------------
    --self.winExpMulti_ = 1    --yanlz：--TODO：不能初始化：岛屿休息界面用到
end

function LordData:resetRound()
    self.super.resetRound(self)
    self.initCards = nil
    self.arrBottomCards = nil
    self.arrCards = {}
    self.bottomCards = nil
    self.lordResultData = nil
    self.userTotalWinExp = 0
    self.userTotalWinGold = 0
    self.playerInfoMap_ = {}
end

function LordData:resetPlayerInfo()
    for seat = 0, 2 do
        --        self.playerInfoMap_[seat].trust_ = false
        --        self.playerInfoMap_[seat].handTime_ = self.handTime_
        local info = self.playerInfoMap_[seat] 
        if info then
            info.cardCount_ = 17
            info.rank_ = -1
        	info.totalHand_ = -1
            info.isTakeOuted_ = false
        end
    end
end

function LordData:getPlayerList()
    return self.playerInfoMap_
end

function LordData:setPlayerInfo(seat, playerInfo)   
    seat = tonumber(seat)
    if self.trustStatus_ == self.TRUST_BY_SERVER and seat == self.selfSeat_ then
        playerInfo.trust_ = true
    end 
    self.playerInfoMap_[seat] = playerInfo
end

function LordData:getPlayerInfo(seat)
    return self.playerInfoMap_[seat]
end

function LordData:removePlayerInfo(userId)
    for k, v in pairs(self.playerInfoMap_) do
        if v.userId_ == userId then
            table.remove(self.playerInfoMap_, k)
        end
    end
end

function LordData:findPlayerInfoByUserId(userId)
    for k, v in pairs(self.playerInfoMap_) do
        if v.userId_ == userId then
            return v
        end
    end
end

function LordData:getPlayerInfoUserIds()
    local userIds = {}
    for k, v in pairs(self.playerInfoMap) do
    end
end

function LordData:setInitCards(cards)
    self.arrCards = cards
    self.initCards = self:getCardsObj(self.arrCards)
end

function LordData:getCards()
    return self.initCards
end

function LordData:setBottomCards(cards)
    self.arrBottomCards = cards
    self.bottomCards = self:getCardsObj(self.arrBottomCards)
end

function LordData:getBottomCards()
    return self.bottomCards
end

function LordData:addBottomCards()
    if self.arrBottomCards then
        self:addCards(self.arrBottomCards)
    end
end

function LordData:addCards(cards)
    if self.arrCards == nil then
        self.arrCards = {}
    end
    for k, v in ipairs(cards) do
        table.insert(self.arrCards, v)
    end

    if self.initCards then
        for k, v in ipairs(self:getCardsObj(cards)) do
            table.insert(self.initCards, v)
        end
    end
end

function LordData:removeCards(cards)
    if cards and #cards > 0 then
        for _, val in ipairs(cards) do
            for index, card in ipairs(self.arrCards) do
                if card == val then
                    table.remove(self.arrCards, index)
                    break
                end
            end
            if self.initCards then
                for index, card in ipairs(self.initCards) do
                    if card.original == val then
                        table.remove(self.initCards, index)
                        break
                    end
                end
            end
        end
    end
end

function LordData:getLeftCards(seat)
    local list = nil
    if self.lordResultData and self.lordResultData.arrPlayerCards then
        list = self.lordResultData.arrPlayerCards[seat + 1]
        list = list and self:getCardsObj(list)
        if list then LordUtil:sortCards(list) end
    end
    return list
end

function LordData:getPreviousSeat()
    if self.selfSeat_ - 1 < 0 then
        return 3 - 1
    else
        return self.selfSeat_ - 1
    end
end

function LordData:getNextSeat()
    if self.selfSeat_ + 1 >= 3 then
        return 0
    else
        return self.selfSeat_ + 1
    end
end

--获取以参数为起点的上一家的座位号
function LordData:getPreSeatBySeat(nSeat)
    return (nSeat + 2) % 3
end

--获取以参数为起点的下一家的座位号
function LordData:getNextSeatBySeat(nSeat)
    return (nSeat + 1) % 3
end

function LordData:setCurHand(seat, cards)
    self.curHand[seat] = self:getCardsObj(cards)
end

function LordData:setCurHandFromCardObj(seat, cardObjs)
    self.curHand[seat] = cardObjs
end

function LordData:getCurHand(seat)
    return self.curHand[seat]
end

function LordData:setLastTakeOutFromCardObj(seat, cardObjs)
    self.lastTakeOutCards[seat] = cardObjs
end

function LordData:setLastTakeOutCards(seat, cards)
    self.lastTakeOutCards[seat] = self:getCardsObj(cards)
end

function LordData:removeLastTakeOutCards(seat)
    self.lastTakeOutCards[seat] = nil
end

function LordData:setLastHandFromCardObj(seat, cardObjs)
    self.lastHand[seat] = cardObjs
end

function LordData:setLastHand(seat, cards)
    self.lastHand[seat] = cards
end

function LordData:getCardsObj(cards)
    local cardList = {}
    if cards then
        for index, val in ipairs(cards) do
            cardList[index] = Card.new(val)
            if self.arrBottomCards then
                for k,v in pairs(self.arrBottomCards) do
                    if val == v then
                        cardList[index].isBottomCard = true
                    end
                end
            end
        end
    end
    return cardList
end

function LordData:getPosBySeat(nSeat)
    if nSeat then
        nSeat = tonumber(nSeat)
    end
    if log_util.isDebug() == true then
        log_util.i(TAG, "getPosBySeat IN ")
    end

    if nSeat == 0 or nSeat == 1 or nSeat == 2 then
        local nPos = LordDef.PLAYER_POSITION_SELF
        if nSeat == self.selfSeat_ then
            nPos = LordDef.PLAYER_POSITION_SELF
        elseif (nSeat - self.selfSeat_ == 1) or (nSeat - self.selfSeat_ == -2) then
            nPos = LordDef.PLAYER_POSITION_NEXT
        else
            nPos = LordDef.PLAYER_POSITION_PRE
        end
        return nPos
    end
end

function LordData:getSeatByPos(pos)
    if pos == LordDef.PLAYER_POSITION_SELF or pos == LordDef.PLAYER_POSITION_NEXT or pos == LordDef.PLAYER_POSITION_PRE then
        local nSeat = self.selfSeat_
        if pos == LordDef.PLAYER_POSITION_SELF then
            nSeat = self.selfSeat_
        elseif pos == LordDef.PLAYER_POSITION_NEXT then
            if nSeat == 1 then nSeat = 2
            elseif nSeat == 2 then nSeat = 0
            else nSeat = 1
            end
        else
            if nSeat == 1 then nSeat = 0
            elseif nSeat == 2 then nSeat = 1
            else nSeat = 2
            end
        end
        return nSeat
    end
end

--判断是否是首出，false为首出
function LordData:canPass()
    return self:getNeedBiggerCards(self.selfSeat_) ~= nil
end

function LordData:getNeedBiggerCards(nSeat)
    local preSeat = self:getPreSeatBySeat(nSeat)
    if self.lastTakeOutCards[preSeat] and #self.lastTakeOutCards[preSeat] > 0 then
        return self.lastTakeOutCards[preSeat]
    elseif self.lastTakeOutCards[self:getPreSeatBySeat(preSeat)] and #self.lastTakeOutCards[self:getPreSeatBySeat(preSeat)] > 0 then
        return self.lastTakeOutCards[self:getPreSeatBySeat(preSeat)]
    else
        return nil
    end
end

--用于记录是主动托管还是被动托管
function LordData:setTrustStatus(status)
    self.trustStatus_  = status
end

function LordData:getTrustStatus()
    return  self.trustStatus_
end

--[[--
    当前是否该我进行操作了（出牌，叫分等）
]]
--yanlz：同步斗地主方案：尝试解决一个偶现luaerror:LordSingleXHCGPlayView.lua"]:3221: attempt to call method 'isMyOperation' (a nil value)
function LordData:isMyOperation()
    return (self.currentOperaterSeat_ == self.selfSeat_)
end

return LordData
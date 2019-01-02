require "utils/functions"
local SingleGameManager = class("SingleGameManager")
--local SingleMatchConfigManager = require("lordsinglexhcg.lordsingle.SingleMatchConfigManager")
--local SingleUserInfoManager = require("lordsinglexhcg.lordsingle.SingleUserInfoManager")
local AI = require('single_game.SingleGameAI')
local Card = require("logic.Card")
local CardPattern = require("logic.CardPattern")
local log_util = require("utils.log_util")
--local lordSingleConfig = require('lordsinglexhcg.config.SingleGameConfig')
local TAG = "SingleGameManager"

-- 新AI
local Monkey = require('api.Monkey')
local Wukong = Monkey:new()
local JJMATCH_NPCID = 99 -- JJ比赛不需要NPC，但是AI需要一个NPCId来匹配等级，所以这里设定一个虚拟的NPCID
local CAN_SHOW_AI_CARDS = false
local isFreeMessAnswer = false

SingleGameManager.pos_ = {SELF = 0, PRE = 2, NEXT = 1} --座位号
SingleGameManager.arrayType_ = {BOTTOM = 99, ALL = 100} --数组标识，用于删除数组元素用

SingleGameManager.IS_USE_TEST_CARDS = true
SingleGameManager.SELF = SingleGameManager.pos_.SELF
SingleGameManager.PRE = SingleGameManager.pos_.PRE
SingleGameManager.NEXT = SingleGameManager.pos_.NEXT
SingleGameManager.BOTTOM = SingleGameManager.arrayType_.BOTTOM
SingleGameManager.currentCallScoreSeat_ = -1
SingleGameManager.singleMatchData_ = nil
SingleGameManager.currentMatchId_ = -1
SingleGameManager.cardRecord = nil
SingleGameManager.bombValues_ = nil -- 用来在处理炸弹必出技能时校验出的单牌或者对子是否是从炸弹拆出来的

SingleGameManager.selfCardsInt_ = {} --玩家手牌int型，为playView里面的OwnPoker使用
SingleGameManager.selfCards_ = {} --玩家手牌
SingleGameManager.selfCardsGroup_ = {} --玩家手牌牌型列表
SingleGameManager.preCardsInt_ = {}
SingleGameManager.preCards_ = {} --上家手牌
SingleGameManager.preCardsGroup_ = {} --上家手牌牌型列表
SingleGameManager.nextCardsInt_ = {}
SingleGameManager.nextCards_ = {} --下家手牌
SingleGameManager.nextCardsGroup_ = {} --下家手牌牌型列表
SingleGameManager.bottomCards_ = {} --底牌
SingleGameManager.bottomCardsInt_ = {} --底牌
SingleGameManager.allCards_ = {}
SingleGameManager.alreadyTakeOutCard_ = {}
SingleGameManager.skillId_ = -1
--测试牌
SingleGameManager.testSelfCards_ = {19, 2, 8, 10, 43, 51, 46, 15, 42, 23, 52, 28, 48, 11, 4, 40, 50}
SingleGameManager.testPreCards_ = {26, 39, 27, 17, 30, 5, 31, 18, 32, 45, 33, 47, 21, 22, 35, 24, 12}
SingleGameManager.testNextCards_ = {13, 0, 1, 14, 41, 16, 3, 44, 6, 20, 34, 9, 49, 36, 37, 38, 25}
SingleGameManager.testbottomCards_ = {29, 7, 53}
SingleGameManager.isUseTestCard_ = SingleGameManager.IS_USE_TEST_CARDS --是否使用测试牌
SingleGameManager.viewController_ = nil
SingleGameManager.isGameOver_ = nil
SingleGameManager.isMatchOver_ = nil
SingleGameManager.testCallScore_ = nil

--花色
local cardColor_ = {
    COLOR_HEART = 0, --紅桃
    COLOR_DIAMOND = 1, --方块
    COLOR_SPADE = 2, --黑桃
    COLOR_CLUB = 3, --梅花
    COLOR_JOKER = 4 --王
}

--牌值
local cardValue_ = {
    CARD_POINT_3 = 3,
    CARD_POINT_4 = 4,
    CARD_POINT_5 = 5,
    CARD_POINT_6 = 6,
    CARD_POINT_7 = 7,
    CARD_POINT_8 = 8,
    CARD_POINT_9 = 9,
    CARD_POINT_10 = 10,
    CARD_POINT_J = 11,
    CARD_POINT_Q = 12,
    CARD_POINT_K = 13,
    CARD_POINT_A = 14,
    CARD_POINT_2 = 15,
    CARD_POINT_LITTLE_JOKER = 16,
    CARD_POINT_BIG_JOKER = 17
}

--牌型
local cardType_ = {
    SINGLE_CARD = CardPattern.SINGLE_CARD, --单牌
    DOUBLE_CARDS = CardPattern.DOUBLE_CARDS, --对子
    THREE_CARDS = CardPattern.THREE_CARDS, --三张
    FOUR_CARDS = CardPattern.FOUR_CARDS, --炸弹
    DOUBLE_JOKER = CardPattern.DOUBLE_JOKER, --双王
    THREE_WITH_ONE = CardPattern.THREE_WITH_ONE, --三带一
    THREE_WITH_TWO = CardPattern.THREE_WITH_TWO, --三带二
    FOUR_WITH_ONE = CardPattern.FOUR_WITH_TWO, --四带一
    FOUR_WITH_TWO = CardPattern.FOUR_WITH_TWO_TWO, --四带二
    SINGLE_DRAGON = CardPattern.SINGLE_DRAGON, --顺子
    DOUBLE_DRAGON = CardPattern.DOUBLE_DRAGON, --双顺
    THREE_DRAGON = CardPattern.THREE_DRAGON, --飞机
    THREE_ONE_DRAGON = CardPattern.THREE_ONE_DRAGON, --飞机带单
    THREE_TWO_DRAGON = CardPattern.THREE_TWO_DRAGON --飞机带对
}

local callScoreWeight_ = {
    SINGLE_CARD_A = 1,
    SINGLE_CARD_2 = 2,
    SMALL_JOKER = 3,
    BIG_JOKER = 4,
    FOUR_CARD = 5,
    DOUBLE_JOKER = 8
}

--权值
local cardTypeWeight_ = {
    SINGLE_CARD = 1,
    DOUBLE_CARDS = 2,
    THREE_CARDS = 3,
    THREE_WITH_ONE = 3,
    THREE_WITH_TWO = 3,
    SINGLE_DRAGON = 4,
    DOUBLE_DRAGON = 5,
    THREE_DRAGON = 6,
    THREE_ONE_DRAGON = 6,
    THREE_TWO_DRAGON = 6,
    FOUR_CARDS = 7,
    DOUBLE_JOKER = 7
}

local typeWord_ = {
    SINGLE_CARD = "single card",
    DOUBLE_CARDS = "double card",
    THREE_CARDS = "three card",
    FOUR_CARDS = "bomb",
    DOUBLE_JOKER = "double joker",
    THREE_WITH_ONE = "three with one",
    THREE_WITH_TWO = "three with two",
    FOUR_WITH_ONE = "four with one",
    FOUR_WITH_TWO = "four with two",
    SINGLE_DRAGON = "single dragon",
    DOUBLE_DRAGON = "double dragon",
    THREE_DRAGON = "plane",
    THREE_ONE_DRAGON = "plane with one",
    THREE_TWO_DRAGON = "plane with two"
}

local TAG = "SingleGameManager"

function SingleGameManager:init(viewController)
    self.viewController_ = viewController
end

function SingleGameManager:isCreateBombCard()
    return math.random(1, 10) <= 2
end

function SingleGameManager:isCreateOtherSpecialCard()
    return math.random(1, 10) <= 3
end

function translateCardToWord(value)
    if value == 11 then
        return "J"
    elseif value == 12 then
        return "Q"
    elseif value == 13 then
        return "K"
    elseif value == 14 then
        return "A"
    elseif value == 15 then
        return "2"
    elseif value == 16 then
        return "小王"
    elseif value == 17 then
        return "大王"
    else
        return value
    end
end

function SingleGameManager:initAIInterface()
   -- local userInfo = SingleUserInfoManager:getSingleUserInfo()
    --local npcLevel = SingleUserInfoManager:getNPCLevelById(lordSingleConfig.NPC_ID_CHILD)
    --local npcLevel = 1
    --local npcData = lordSingleConfig.NPC_CHILD
    --npcData.unlockLevel = npcLevel
    --local params = {}
    --params.userInfo = userInfo
    --params.npcData = npcData
end

function SingleGameManager:getNPCInfo(userLevel)
    return {}
end

function SingleGameManager:getBombValues()
    self.bombValues_ = {}
    table.sort(self.selfCardsInt_, sortOriginal)
    local sameCardCount = 1
    local i = 1
    local j = i + 1
    while self.selfCardsInt_[j] do
        if self.selfCardsInt_[i] % 13 + 3 == self.selfCardsInt_[j] % 13 + 3 then
            j = j + 1
            sameCardCount = sameCardCount + 1
        else
            if sameCardCount == 4 then
                table.insert(self.bombValues_, self.selfCardsInt_[i] % 13 + 3)
            end
            i = j
            j = i + 1
            sameCardCount = 1
        end
    end
end

--初始化手牌以及底牌
function SingleGameManager:initCard(takeOutCardRecord, skillId, npcId, npcLevel, isMess, messData)
    self.createCardUtil = require("single_game.CreateCardUtil").new()
    self.skillId_ = skillId
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    self.bombValues_ = {}
    self.createCardUtil:initAllCards()
    self:reset()
    --local handCardRecord = LuaDataFile.get("data/SingleLordHandCardData.lua")
    local specialCardInfo = nil
    if isMess then
        self.isUseTestCard_ = true
        if messData then
            local selfCardsInt, preCardsInt, nextCardsInt = self.createCardUtil:translateCardObjToInt(self:cloneIntList(messData.selfCardInt), self:cloneIntList(messData.preCardInt), self:cloneIntList(messData.nextCardInt))
            self.testSelfCards_ = selfCardsInt
            self.testPreCards_ = preCardsInt
            self.testNextCards_ = nextCardsInt
        end
        self.createCardUtil:createHandCard(self.SELF)
        self.createCardUtil:createHandCard(self.PRE)
        self.createCardUtil:createHandCard(self.NEXT)
    else
        if self.isUseTestCard_ then
            self.createCardUtil:createHandCard(self.SELF)
            self.createCardUtil:createHandCard(self.PRE)
            self.createCardUtil:createHandCard(self.NEXT)
            self.createCardUtil:createBottomCard()
        else
            specialCardInfo = self.createCardUtil:createCard(npcId, skillId)
        end
    end
    self.selfCards_ = self.createCardUtil:randomCard(self.selfCards_)
    
    -- 初始化AI
    Wukong:initRobot(self.preCardsInt_,self.PRE, npcId == -1 and JJMATCH_NPCID or npcId, npcLevel)
    Wukong:initRobot(self.nextCardsInt_,self.NEXT)
    Wukong:initRobot(self.selfCardsInt_,self.SELF)
    Wukong:initRobot(self.bottomCardsInt_,-1);

    self.lastTakeOutCardGroup = nil
    self.lastTakeOutSeat = -1

    local cards = self.allCards_
    for key, var in pairs(cards) do
        if var == 52 then
            table.insert(self.alreadyTakeOutCard_, { original = var, color = cardColor_.COLOR_JOKER,  value = cardValue_.CARD_POINT_LITTLE_JOKER})
        elseif var == 53 then
            table.insert(self.alreadyTakeOutCard_, { original = var, color = cardColor_.COLOR_JOKER,  value = cardValue_.CARD_POINT_BIG_JOKER})
        else
            table.insert(self.alreadyTakeOutCard_, { original = var, color = math.modf(var / 13),  value = var % 13 + 3})
        end
    end

    table.sort(self.preCards_, sort)
    table.sort(self.nextCards_, sort)
    table.sort(self.bottomCards_, sort)
    
    if self.selfCardsGroup_ then
        table.sort(self.selfCardsGroup_, sortCardGroup)
    end
    if self.preCardsGroup_ then
        table.sort(self.preCardsGroup_, sortCardGroup)
    end
    if self.nextCardsGroup_ then
        table.sort(self.nextCardsGroup_, sortCardGroup)
    end

    self:show(takeOutCardRecord)

    return specialCardInfo
end

function SingleGameManager:checkIsSplitBomb(cardList, cardType)
    if cardType ~= cardType_.FOUR_CARDS and cardType ~= cardType_.DOUBLE_JOKER then
        if self.bombValues_ then
            for k,v in pairs(self.bombValues_) do
                for key, card in pairs(cardList) do
                    if card and (card.value == v or card.value == cardValue_.CARD_POINT_LITTLE_JOKER or card.value == cardValue_.CARD_POINT_BIG_JOKER) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function SingleGameManager:checkIsSplitJoker(cardList, cardType)
    local jokerCount = 0
    if cardType ~= cardType_.DOUBLE_JOKER then
        for key, card in pairs(cardList) do
            if card and (card.value == cardValue_.CARD_POINT_LITTLE_JOKER or card.value == cardValue_.CARD_POINT_BIG_JOKER) then
                jokerCount = jokerCount + 1
            end
        end
        if jokerCount == 1 then
            return true
        else
            return false
        end
    else
        return false
    end
end

function SingleGameManager:checkIsContainBomb(cardList)
    if cardList then
        local cardCount = 1
        local j = 0
        for i = 1, #cardList do
            j = i + 1
            if cardList[j] then
                if cardList[i].value == cardList[j].value then
                    cardCount = cardCount + 1
                else
                    if cardCount >= 4 then
                        return true
                    else
                        cardCount = 1
                    end
                end
            else
                if cardCount >= 4 then
                    return true
                end
            end
        end
        return false
    end
end

function SingleGameManager:getAlreadyTakeOutCards()
    local alreadyTakeOutCardsInt = {}
    if self.alreadyTakeOutCard_ then
        for k,v in pairs(self.alreadyTakeOutCard_) do
            if v then
                table.insert(alreadyTakeOutCardsInt, v.original)
            end
        end
    end
    return alreadyTakeOutCardsInt
end

function SingleGameManager:setAlreadyTakeOutCards(cardIntList)
    local alreadyTakeOutCardsObj = {}
    if cardIntList then
        for k,v in pairs(cardIntList) do
            table.insert(alreadyTakeOutCardsObj, Card.new(v))
        end
    end
    self.alreadyTakeOutCard_ = alreadyTakeOutCardsObj
end

function SingleGameManager:getCardRecord()
    if self.cardRecord == nil then
        self.cardRecord = {}
    end
    return self.cardRecord
end

function SingleGameManager:setCardRecord(cardRecord)
    self.cardRecord = cardRecord
end

function SingleGameManager:doTakeOutCard(params)
    if params then
        if params.lastTakeOutCardGroup then
            self.lastTakeOutCardGroup = params.lastTakeOutCardGroup
        end
        if self.lastTakeOutSeat == params.seat then
            self.lastTakeOutCardGroup = nil
        end
        self.lordPos_ = params.lordSeat
        local npcId = params.npcId
        local isMess = params.isMess
        local takeOutCardParams = {}
        takeOutCardParams.cardRecord = self:getCardRecord()
        takeOutCardParams.seat = params.seat
        takeOutCardParams.lordSeat = params.lordSeat
        takeOutCardParams.handCards = {}
        local selfCards = {}
        selfCards.seat = self.SELF
        selfCards.handCardListInt = self.selfCardsInt_
        selfCards.handCardListObj = self.selfCards_
        local preCards = {}
        preCards.seat = self.PRE
        preCards.handCardListInt = self.preCardsInt_
        preCards.handCardListObj = self.preCards_
        local nextCards = {}
        nextCards.seat = self.NEXT
        nextCards.handCardListInt = self.nextCardsInt_
        nextCards.handCardListObj = self.nextCards_
        table.insert(takeOutCardParams.handCards, selfCards)
        table.insert(takeOutCardParams.handCards, preCards)
        table.insert(takeOutCardParams.handCards, nextCards)

        -- 新AI
        local takeOutCardGroup = nil        
        log_util.i(TAG, "doTakeOutCard IN npcId is ", npcId, " isMess is ", isMess)
        -- if npcId == -1 or npcId == lordSingleConfig.NPC_ID_AUNT then
        --     takeOutCardGroup = AI:doTakeOutCards(self.lastTakeOutCardGroup, params.seat, params.lordSeat, self.lastTakeOutSeat, self)
        -- else
        --     takeOutCardGroup = Wukong:doTakeOutCards(takeOutCardParams)
        -- end
        if isMess then
            takeOutCardGroup = Wukong:doTakeOutCards(takeOutCardParams)
        else
            takeOutCardGroup = AI:doTakeOutCards(self.lastTakeOutCardGroup, params.seat, params.lordSeat, self.lastTakeOutSeat, self)
        end
        
        if takeOutCardGroup then
            self.lastTakeOutSeat = params.seat
            self.lastTakeOutCardGroup = takeOutCardGroup

            self:removeTakeoutCard(takeOutCardGroup.cardList, params.seat)
        end
        return takeOutCardGroup
    end
end

function SingleGameManager:cloneHandCardsIntBySeat(seat)
    local handCardsInt = nil
    if seat == self.SELF then
        handCardsInt = self.selfCardsInt_
    elseif seat == self.PRE then
        handCardsInt = self.preCardsInt_
    elseif seat == self.NEXT then
        handCardsInt = self.nextCardsInt_
    elseif seat == self.BOTTOM then
        handCardsInt = self.bottomCardsInt_
    end

    local returnValue = {}
    for k,v in pairs(handCardsInt) do
        table.insert(returnValue, v)
    end

    return returnValue
end

function SingleGameManager:cloneCardsGroup(cards, cardsGroup)
    local newCards = {}
    local newCardsGroup = {}
    if cards then
        for k,v in pairs(cards) do
            table.insert(newCards, Card.new(v.original))
        end
    end
    if cardsGroup then
        for k,v in pairs(cardsGroup) do
            local tempCardGroup = {}
            tempCardGroup.cardList = {}
            tempCardGroup.cardType = v.cardType
            tempCardGroup.cardValue = v.cardValue
            for k,card in pairs(v.cardList) do
                table.insert(tempCardGroup.cardList, Card.new(card.original))
            end
            table.insert(newCardsGroup, tempCardGroup)
        end
    end
    return newCards, newCardsGroup
end

function SingleGameManager:cloneIntList(intList)
    local newList = {}
    if intList then
        for k, v in pairs(intList) do
            table.insert(newList, v)
        end
    end
    return newList
end

function SingleGameManager:getCardsBySeat(seat)
    local cards, cardGroup = self:getSomeOneCards(seat)
    return self:cloneCardsGroup(cards, cardGroup)
end

function SingleGameManager:setSomeOneCards(seat, cards_, cardGroup_)
    local cards, cardGroup = self:getSomeOneCards(seat)
    if cards then
        cards = cards_
    end
    if cardGroup then
        cardGroup = cardGroup_
    end
end

function SingleGameManager:setSelfCardsInt(intCards)
    self.selfCardsInt_ = intCards
end

function SingleGameManager:setPreCardsInt(intCards)
    self.preCardsInt_ = intCards
end

function SingleGameManager:setNextCardsInt(intCards)
    self.nextCardsInt_ = intCards
end

function SingleGameManager:setBottomCardsInt(intCards)
    self.bottomCardsInt_ = intCards
end

function SingleGameManager:getFriendSeat(seat)
    for i = 0, 2 do
        if seat ~= i and i ~= self.lordPos_ then
            return i
        end    
    end
end

function SingleGameManager:getFriendPlayerCards(seat)
    local friendSeat = self:getFriendSeat(seat)
    -- if log_util.isDebug() == true then
        -- log_util.i(TAG, "friendSeat is ", friendSeat)
    -- end

    if friendSeat then
        local cards = self:getSomeOneCards(friendSeat)
        return cards
    end
end

function SingleGameManager:getCurrentCallSeat()
    return self.currentCallScoreSeat_
end

function SingleGameManager:setCurrentCallSeat(callSeat)
    self.currentCallScoreSeat_ = callSeat
end

--[[
function SingleGameManager:getCurrentMatch()
    local singleMatchList = SingleMatchConfigManager:getVisbleSingleMatch()
    if singleMatchList then
        -- if log_util.isDebug() == true then
            -- log_util.i(TAG, "currentMatchId_ is ", self.currentMatchId_)
        -- end

        for key, var in pairs(singleMatchList) do
            if var and var.matchid == self.currentMatchId_ then
                return self.currentMatchId_, var
            end
        end
    end
    return self.currentMatchId_ == -1 and 0 or self.currentMatchId_
end

function SingleGameManager:setCurrentMatch(matchId)
    -- if log_util.isDebug() == true then
        -- log_util.i(TAG, "setCurrentMatch IN matchId is ", matchId)
    -- end

    self.currentMatchId_ = matchId
    _, self.singleMatchData_ = self:getCurrentMatch()
end

]]

function SingleGameManager:resetFirstCallSeat()
    self.firstCallSeat_ = nil
end

function SingleGameManager:getFirstCallScoreSeat()
    -- math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    -- local firstCallSeat = math.random(1, 3)
    if self.firstCallSeat_ == nil then
        self.firstCallSeat_ = SingleGameManager.SELF    
    elseif self.firstCallSeat_ == self.PRE then
        self.firstCallSeat_ = SingleGameManager.SELF
    else
        self.firstCallSeat_ = SingleGameManager.PRE
    end
	
    return self.firstCallSeat_
	-- return SingleGameManager.PRE
end

function SingleGameManager:getAward(rankOrCount)
    if self.singleMatchData_ then
        local awardinfo = self.singleMatchData_.awardinfo
        if awardinfo then
            for key, var in pairs(awardinfo) do
                if var then
                    if (rankOrCount >= var.highrank and rankOrCount <= var.lowrank) or (rankOrCount >= var.lowrank and rankOrCount <= var.highrank) then
                        return var.copper, var.experience
                    end
                end
            end
        end
    end
    return 0, 0
end

function SingleGameManager:getCallScore(seat)
    local score = 0
    local callScoreWeight = self:getCallScoreWeight(seat)
    if callScoreWeight == 0 then
        score = 0
    elseif callScoreWeight > 0 and callScoreWeight < 4 then
        score = 1
    elseif callScoreWeight < 8 then
        score = 2
    else
        score = 3
    end
    -- TODO 如果AI需要根据叫分状况打牌，则可能需要调整
    score = Wukong:callScore(seat)
    if seat == self.NEXT then
        -- score = 3
    elseif seat == self.SELF then
        score = Wukong:getPlayerCallScore()
    end
    if log_util.isDebug() == true then
        log_util.i(TAG, "getCallScore IN score is ", score)
    end
    if self.testCallScore_ then
        return self.testCallScore_
    else
   	    return score == nil and 0 or score
    end
    -- return 0
end

function SingleGameManager:showAlert(text)
    --jj.ui.JJToast:show({text = text, dimens = self.viewController_.dimens_})
end

--[[
function SingleGameManager:showBug()
    local bugBtn = jj.ui.JJButton.new({
            images = {
                normal = "img/lordsinglexhcg/dialog/dialog_btn_1_n.png",
            },
            text = "提交bug",
            color = ccc3(0, 0, 0)
        })
        -- bugBtn:setAnchorPoint(ccp(0.5, 0))
        -- bugBtn:setPosition(0, self.dimens_:getDimens(63))
        bugBtn:setOnClickListener(handler(self, function(target) 
            doHttp()
        end))   
    -- bugBtn:setPosition(rootView_.dimens_.right, rootView_.dimens_.cy)
    local rootView_ = jj.ui.JJRootView.new({
        displayType = "director",
        display = CCDirector:sharedDirector()
    })
    rootView_:addView(bugBtn)

end

-- 处理http请求
function SingleGameManager:doHttp()
    -- 创建一个请求，并以 POST 方式发送数据到服务端
    local url = "http://wan.jj.cn/api/spg_record.php"
    local request = network.createHTTPRequest(onRequestFinished, url, "POST")
    local ret = Wukong:getLog()
    request:addPOSTValue("dat", ret)
    -- 开始请求。当请求完成时会调用 callback() 函数
    request:start()
end
-- 响应http处理结果
function onRequestFinished(event)
    if log_util.isDebug() == true then
        print("Monkey http finish")
    end

    local ok = (event.name == "completed")
    local request = event.request
 
    if not ok then
        -- 请求失败，显示错误代码和错误消息
        if log_util.isDebug() == true then
            print(request:getErrorCode(), request:getErrorMessage())
        end

        SingleGameManager:showAlert("日志上传错误1:"..code)
        return
    end
 
    local code = request:getResponseStatusCode()
    if code ~= 200 then
        -- 请求结束，但没有返回 200 响应代码
        if log_util.isDebug() == true then
            print(code)
        end

        SingleGameManager:showAlert("日志上传错误2:"..code)
        return
    end
 
    -- 请求成功，显示服务端返回的内容
    local response = request:getResponseString()
    if log_util.isDebug() == true then
        print("Monkey http response",response)
    end

    SingleGameManager:showAlert(response)
end
]]

function SingleGameManager:getUserCardTypeList()
    return Wukong:getPalyerCardPttern()
end

function SingleGameManager:getCallScoreWeight(seat)
    local callScoreWeight = 0
    local cards, cardGroup = self:getSomeOneCards(seat or self.currentCallScoreSeat_)
    --先找炸弹跟双王
    if cardGroup then
        for key, var in pairs(cardGroup) do
            if var then
                if var.cardType == cardType_.FOUR_CARDS then
                    callScoreWeight = callScoreWeight + callScoreWeight_.FOUR_CARD
                elseif var.cardType == cardType_.DOUBLE_JOKER then
                    callScoreWeight = callScoreWeight + callScoreWeight_.DOUBLE_JOKER
                end
            end
        end
    end

    --再找2和单王
    if cards then
        for key, var in pairs(cards) do
            if var then
                if var.value == cardValue_.CARD_POINT_A then
                    callScoreWeight = callScoreWeight + callScoreWeight_.SINGLE_CARD_A
                elseif var.value == cardValue_.CARD_POINT_2 then
                    callScoreWeight = callScoreWeight + callScoreWeight_.SINGLE_CARD_2
                elseif var.value == cardValue_.CARD_POINT_LITTLE_JOKER then
                    callScoreWeight = callScoreWeight + callScoreWeight_.SMALL_JOKER
                elseif var.value == cardValue_.CARD_POINT_BIG_JOKER then
                    callScoreWeight = callScoreWeight + callScoreWeight_.BIG_JOKER
                end
            end
        end
    end

    return callScoreWeight
end

function SingleGameManager:getBottomCard()
    local bottomCards = self:getSomeOneCards(self.arrayType_.BOTTOM)
    return bottomCards
end

function SingleGameManager:getSomeOneCardsInt(whom)
    if whom == self.SELF then
        return self.selfCardsInt_
    elseif whom == self.PRE then
        return self.preCardsInt_
    elseif whom == self.NEXT then
        return self.nextCardsInt_
    elseif whom == self.arrayType_.BOTTOM then
        return self.bottomCardsInt_
    end
end

--根据座位获取手牌列表与牌型列表
function SingleGameManager:getSomeOneCards(whom)
    if whom == self.SELF then
        return self.selfCards_, self.selfCardsGroup_
    elseif whom == self.PRE then
        return self.preCards_, self.preCardsGroup_
    elseif whom == self.NEXT then
        return self.nextCards_, self.nextCardsGroup_
    elseif whom == self.arrayType_.BOTTOM then
        return self.bottomCards_
    elseif whom == self.arrayType_.ALL then
        return self.allCards_
    end
end

function SingleGameManager:addCardsBySeat(seat, cardList)
    if cardList then
        for k, card in pairs(cardList) do
            self:addCardBySeat(seat, card)
        end
    end
end

function SingleGameManager:addCardBySeat(seat, card)
    local cardObjList = self:getSomeOneCards(seat)
    local cardIntList = self:getSomeOneCardsInt(seat)
    table.insert(cardObjList, card)
    table.insert(cardIntList, card.original)
end

function SingleGameManager:addBottomCard(seat)
    if seat == -1 then
        seat = self.SELF
    end
    local bottomCards = self:getSomeOneCards(self.arrayType_.BOTTOM)
    local bottomCardsInt = self:getSomeOneCardsInt(self.arrayType_.BOTTOM)
    if bottomCards then
        for key, card in pairs(bottomCards) do
            if card then
                self:addCardBySeat(seat, card)
            end
        end
    end
    local preCards = self:getCardsBySeat(self.PRE)
    local cards, cardGroup = self:getSomeOneCards(seat)
    if cards and cardGroup then
        table.sort(cards, sort)
        table.sort(cardGroup, sortCardGroup)
    end
    -- 如果AI是地主，增加手牌,告知AI地主归属
    Wukong:initBottom(bottomCardsInt, seat)
end

function SingleGameManager:initBottomCardForMess(seat)
    if log_util.isDebug() == true then
        log_util.i(TAG, "initBottomCardForMess IN self.currentMatchId_ is ", self.currentMatchId_)
    end
    Wukong:initBottom({}, seat, self.currentMatchId_)
end

function SingleGameManager:checkLevel()
    local signupLevel = self.singleMatchData_.level
    --local userLevel = SingleUserInfoManager:getLevel()
    local userLevel = 1

    if signupLevel > userLevel then
        return false
    else
        return true
    end
end

--[[
function SingleGameManager:getMatchById(matchId)
    local singleMatchList = SingleMatchConfigManager:getVisbleSingleMatch()
    if singleMatchList then
        for key, var in pairs(singleMatchList) do
            if var and var.matchid == matchId then
                return var
            end
        end
    end
end
]]

function SingleGameManager:showMarkScoreDialog(dimens, theme, scene, onDismissListener)
    local params = {
        theme = theme,
        dimens = dimens,
        gameManager = self,
        onDismissListener = onDismissListener
    }
    local markScoreDialog = require("lordsinglexhcg.ui.view.LordSingleXHCGMarkScorePromptDialog").new(params)
    markScoreDialog:setVisible(true)
    markScoreDialog:setCanceledOnTouchOutside(isCanceledOnTouchOutside)
    markScoreDialog:show(scene)
end

--[[
function SingleGameManager:checkCopperIsEnough(isToast, signupCost, toastText)
    local userCoin = SingleUserInfoManager:getCopper()
    if userCoin < signupCost then
        if isToast then
            if toastText then
                jj.ui.JJToast:show({text = toastText, dimens = self.dimens_})
            else
                jj.ui.JJToast:show({text = "您的铜板不够哦，请去免费场攒攒铜板吧。", dimens = self.dimens_})
            end
        end
        return false
    else
        return true
    end
end

function SingleGameManager:costSignupCoin(coin)
    if coin then
        SingleUserInfoManager:reduceCopper(coin) 
    else
        local signupCost = self.singleMatchData_.signupcost
        SingleUserInfoManager:reduceCopper(signupCost)
    end
end

function SingleGameManager:openScoreUrl(dimens)
    log_util.i(TAG, "openScoreUrl IN device.platform is ", device.platform)
    log_util.i(TAG, "openScoreUrl IN Util:getNetworkType() is ", Util:getNetworkType())
    if Util:getNetworkType() ~= 0 then
        SingleUserInfoManager:setFirstMarkScore(false)
        if device.platform == "android" then
            Util:openSystemBrowser("market://details?id=com.philzhu.www.ddz")
        elseif device.platform == "ios" then
            SingleUserInfoManager:addCopper(5000)
            local url = GameConfigManager.getDownloadPath and GameConfigManager:getDownloadPath(MainController:getPackageId()) or ""
            log_util.i(TAG, "openScoreUrl IN url is ", url)
            Util:openSystemBrowser(url)
        end
    else
        jj.ui.JJToast:show({text = "网络连接失败，请连接网络后进行评分。", dimens = dimens})
    end
end
]]

function SingleGameManager:show(takeOutCardRecord)
    local selfCard = {}
    local selfCardGroup = {}
    local selfCardGroupValue = {}
    local preCard = {}
    local preCardGroup = {}
    local preCardGroupValue = {}
    local nextCard = {}
    local nextCardGroup = {}
    local nextCardGroupValue = {}
    local bottomCard = {}
    takeOutCardRecord = takeOutCardRecord or {}
    local showInfo = function (whom)
        local posStr = ""
        local cardsList = nil
        if whom == SingleGameManager.SELF then
            posStr = "self"
            cardsList = selfCard
        elseif whom == SingleGameManager.PRE then
            posStr = "pre"
            cardsList = preCard
        else
            posStr = "next"
            cardsList = nextCard
        end
        local cards, cardGroup = self:getSomeOneCards(whom)

        if log_util.isDebug() == true then
            log_util.i(TAG, posStr, "SingleGameManager IN show card--------------------------")
        end

        table.insert(takeOutCardRecord, string.format("%s SingleGameManager IN show card--------------------------", posStr))
        for key, var in ipairs(cards) do
            table.insert(cardsList, translateCardToWord(var.value))
        end
        if log_util.isDebug() == true then
            log_util.i(TAG, table.concat(cardsList, ", "))
        end

        table.insert(takeOutCardRecord, table.concat(cardsList, ", "))
        local cardGroupStr = ""
        local cardO = ""

        for key, var in pairs(cards) do
            cardO = cardO..var.original..", "
        end
        if log_util.isDebug() == true then
            log_util.i(TAG, cardGroupStr)
        end

        table.insert(takeOutCardRecord, cardGroupStr)
        if log_util.isDebug() == true then
            log_util.i(TAG, cardO)
        end

        table.insert(takeOutCardRecord, cardO)
        if log_util.isDebug() == true then
            log_util.i(TAG, posStr, "SingleGameManager IN show card--------------------------")
        end

        table.insert(takeOutCardRecord, string.format("%s SingleGameManager IN show card--------------------------", posStr))
        if log_util.isDebug() == true then
            log_util.i(TAG, "")
        end

    end
    showInfo(self.SELF)
    showInfo(self.PRE)
    showInfo(self.NEXT)
    showInfo(self.arrayType_.BOTTOM)
end

function sort(a, b)
    return a.value < b.value
end

function sortInt(a, b)
    return a < b
end

function sortOriginal(a, b)
    if a == 52 or a == 53 then
        return false
    end
    if b == 52 or b == 53 then
        return true
    end
    return a % 13 + 3 < b % 13 + 3
end

function sortCardGroup(a, b)
    if a and b then
        return a.cardValue < b.cardValue
    end
end

function translateCardType(cardType)
    for key, var in pairs(cardType_) do
        if var == cardType then
            return typeWord_[key]
        end
    end
end

function SingleGameManager:getSelfCardInt()
    -- if log_util.isDebug() == true then
        -- log_util.i(TAG, "self.selfCardsInt_ count is ", #self.selfCardsInt_)
    -- end

    return self.selfCardsInt_
end

function SingleGameManager:getPreCardInt()
    -- if log_util.isDebug() == true then
        -- log_util.i(TAG, "self.preCardsInt_ count is ", #self.preCardsInt_)
    -- end

    return self.preCardsInt_
end

function SingleGameManager:getNextCardInt()
    -- if log_util.isDebug() == true then
        -- log_util.i(TAG, "self.nextCardsInt_ count is ", #self.nextCardsInt_)
    -- end

    return self.nextCardsInt_
end

function SingleGameManager:setHandCardObj(cards, pos)
    local cardsObj = {}
    for k,v in pairs(cards) do
        table.insert(cardsObj, Card.new(v))
    end
    if pos == SingleGameManager.SELF then
        self:setSelfCardsInt(cards)
        self.selfCards_ = cardsObj
        table.sort(self.selfCards_, sort)
    elseif pos == SingleGameManager.PRE then
        self:setPreCardsInt(cards)
        self.preCards_ = cardsObj
        table.sort(self.preCards_, sort)
    elseif pos == SingleGameManager.NEXT then
        self:setNextCardsInt(cards)
        self.nextCards_ = cardsObj
        table.sort(self.nextCards_, sort)
    elseif pos == SingleGameManager.BOTTOM then
        self:setBottomCardsInt(cards)
        self.bottomCards_ = cardsObj
    end
end

function SingleGameManager:getBottomCardInt()
    return self.bottomCardsInt_
end

function SingleGameManager:getTestCard(whom)
    if whom == self.SELF then
        return self.testSelfCards_
    elseif whom == self.PRE then
        return self.testPreCards_
    elseif whom == self.NEXT then
        return self.testNextCards_
    elseif whom == self.arrayType_.BOTTOM then
        return self.testbottomCards_
    end
end

function SingleGameManager:removeTakeoutCard(cardObjList, seat)
    --从手牌中删除出的牌
    local cards, cardGroup = self:getSomeOneCards(seat)
    local cardListInt = self:getSomeOneCardsInt(seat)
    -- if log_util.isDebug() == true then
        -- log_util.i(TAG, "removeTakeoutCard IN seat is ", seat, " cards is ", cards, " cardListInt is ", cardListInt)
        -- log_util.i(TAG, "removeTakeoutCard IN cardObjList is ", vardump(cardObjList))
        -- log_util.i(TAG, "removeTakeoutCard IN cards is ", vardump(cards))
    -- end

    if cardObjList and cards and cardListInt then
        for key, var in pairs(cardObjList) do
            if var and var.original then
                for k,v in pairs(cardListInt) do
                    if var.original == v then
                        table.remove(cardListInt, k)
                        break
                    end
                end

                local i = 1
                while cards[i] and cards[i].original do
                    if cards[i].original == var.original then
                        table.insert(self.alreadyTakeOutCard_, cards[i])
                        table.remove(cards, i)
                        break
                    else
                        i = i + 1
                    end
                end
            end
        end
    end

    -- if log_util.isDebug() == true then
        -- log_util.i(TAG, "removeTakeoutCard IN self.selfCardsInt_ is ", vardump(self.selfCardsInt_))
        -- log_util.i(TAG, "removeTakeoutCard IN self.selfCards_ is ", vardump(self.selfCards_))
    -- end

end

function SingleGameManager:cleanTable(t)
    if type(t) == "table" then
        for i=1, #t do
            t[i] = nil
        end
    end
end

function SingleGameManager:resetTestCard()
    self.testSelfCards_ = {}
    self.testPreCards_ = {}
    self.testNextCards_ = {}
    self.testbottomCards_ = {}
end

function SingleGameManager:reset()
    self.isUseTestCard_ = self.IS_USE_TEST_CARDS
    self:cleanTable(self.selfCards_)
    self:cleanTable(self.selfCardsInt_)
    self:cleanTable(self.preCards_)
    self:cleanTable(self.preCardsInt_)
    self:cleanTable(self.nextCards_)
    self:cleanTable(self.nextCardsInt_)
    self:cleanTable(self.bottomCards_)
    self:cleanTable(self.bottomCardsInt_)
    self:cleanTable(self.alreadyTakeOutCard_)
    self:cleanTable(self.cardRecord)
end

function SingleGameManager:testInitCard()
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    local startTime = os.time()
    for i = 1, 10000 do
        local isError = initCard()
        if isError then
            break
        end
    end
    local endTime = os.time()
    if log_util.isDebug() == true then
        print(endTime - startTime)
    end

end

function SingleGameManager:setIsGameOver(flag)
    self.isGameOver_ = flag
end

function SingleGameManager:setIsMatchOver(flag)
    self.isMatchOver_ = flag
end

function SingleGameManager:getIsGameOver()
    return self.isGameOver_
end

function SingleGameManager:getIsMatchOver()
    return self.isMatchOver_
end

function SingleGameManager:setIsUserTestCard(flag)
    self.IS_USE_TEST_CARDS = flag
end

function SingleGameManager:setTestCallScore(score)
    if self.testCallScore_ == score then
        self.testCallScore_ = nil
    else
        self.testCallScore_ = score
    end
end

function SingleGameManager:getTestCallScore()
    return self.testCallScore_
end

function SingleGameManager:getIsShowAICards()
    return CAN_SHOW_AI_CARDS
end

function SingleGameManager:setIsShowAICards(flag)
    CAN_SHOW_AI_CARDS = flag
end

function SingleGameManager:setIsFreeMessAnswer(flag)
    isFreeMessAnswer = flag
end

function SingleGameManager:getIsFreeMessAnswer()
    return isFreeMessAnswer
end

return SingleGameManager
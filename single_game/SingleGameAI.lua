--[[
单机斗地主AI逻辑处理
包括：发牌、组牌、出牌
]]
local log_util = require("utils.log_util")
local SingleGameAI = class("SingleGameAI")
local CardPattern = require("logic.CardPattern")
local TAG = "SingleGameAI"
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
    CARD_POINT_BIG_JOKER = 17}

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

local pos_ = {SELF = 0, PRE = 2, NEXT = 1} --座位号

local arrayType_ = {BOTTOM = 99, ALL = 100} --数组标识，用于删除数组元素用

SingleGameAI.cardColor_ = cardColor_
SingleGameAI.cardValue_ = cardValue_
SingleGameAI.cardType_ = cardType_
SingleGameAI.arrayType_ = arrayType_
SingleGameAI.typeWord_ = typeWord_
SingleGameAI.callScoreWeight_ = callScoreWeight_
SingleGameAI.pos_ = pos_
SingleGameAI.currentPos_ = -1
SingleGameAI.lastTakeOutPos_ = -1
SingleGameAI.lordPos_ = -1
SingleGameAI.friendPos_ = {}
SingleGameAI.againistPos_ = {}
SingleGameAI.selfCardsInt_ = {} --玩家手牌int型，为playView里面的OwnPoker使用
SingleGameAI.selfCards_ = {} --玩家手牌
SingleGameAI.selfCardsGroup_ = {} --玩家手牌牌型列表
SingleGameAI.selfCardsGroupWeight_ = 0
SingleGameAI.selfCardsGroupHandCount_ = 0
SingleGameAI.preCards_ = {} --上家手牌
SingleGameAI.preCardsInt_ = {}
SingleGameAI.preCardsGroup_ = {} --上家手牌牌型列表
SingleGameAI.preCardsGroupWeight_ = 0
SingleGameAI.preCardsGroupHandCount_ = 0
SingleGameAI.nextCards_ = {} --下家手牌
SingleGameAI.nextCardsInt_ = {}
SingleGameAI.nextCardsGroup_ = {} --下家手牌牌型列表
SingleGameAI.nextCardsGroupWeight_ = 0
SingleGameAI.nextCardsGroupHandCount_ = 0
SingleGameAI.bottomCards_ = {} --底牌
SingleGameAI.bottomCardsInt_ = {} --底牌
SingleGameAI.friendCanTakeOutOneHand_ = false
SingleGameAI.singleGameManager_ = nil

SingleGameAI.alreadyTakeOutCard_ = {} --记牌器，记录所有已出的牌张

function SingleGameAI:ctor(singleGameManager)
    self.singleGameManager_ = singleGameManager
    log_util.i(TAG, "ctor IN self.singleGameManager_ is ", self.singleGameManager_)
end

function SingleGameAI:getSomeOneCardsInt(whom)
    if self.singleGameManager_ then
        local cardsInt = self.singleGameManager_:getSomeOneCardsInt(whom)
        return cardsInt
    end
end

--根据座位获取手牌列表与牌型列表
function SingleGameAI:getSomeOneCards(whom)
    if self.singleGameManager_ then
        local cards, cardGroups = self.singleGameManager_:getSomeOneCards(whom)
        return cards, cardGroups
    end
end

--组牌AI BEGIN

--组合基础牌型：单张、对子、三张、炸弹、双王
function SingleGameAI:createBaseCardGroup(whom)
    local cards, cardGroup = self:getSomeOneCards(whom)
    if cards and cardGroup then
        
        for i=1, #cardGroup do
            table.remove(cardGroup, 1)
        end
        local tempCards = {}

        for key, var in pairs(cards) do
            table.insert(tempCards, var)
        end
        local i = 1
        while tempCards[i] and tempCards[i].value do
            local cardValue = {}
            local j = i + 1
            local flag = false
            while tempCards[j] and tempCards[j].value do
                if tempCards[i].value == cardValue_.CARD_POINT_LITTLE_JOKER and tempCards[j].value == cardValue_.CARD_POINT_BIG_JOKER then
                    table.insert(cardGroup, { cardType = cardType_.DOUBLE_JOKER, cardValue = tempCards[j].value, cardList = {tempCards[i], tempCards[j]}})
                    return
                else
                    if tempCards[j].value == tempCards[i].value then
                        table.insert(cardValue, tempCards[j])
                        j = j + 1
                        flag = true
                    else
                        break
                    end
                end
            end
            if flag then
                table.insert(cardValue, tempCards[i])
                if #cardValue == 2 then
                    table.insert(cardGroup, { cardType = cardType_.DOUBLE_CARDS, cardValue = cardValue[1].value, cardList = cardValue})
                elseif #cardValue == 3 then
                    table.insert(cardGroup, { cardType = cardType_.THREE_CARDS, cardValue = cardValue[1].value, cardList = cardValue})
                elseif #cardValue == 4 then
                    table.insert(cardGroup, { cardType = cardType_.FOUR_CARDS, cardValue = cardValue[1].value, cardList = cardValue})
                end
                i = j
            else
                table.insert(cardGroup, { cardType = cardType_.SINGLE_CARD, cardValue = tempCards[i].value, cardList = {tempCards[i]}})
                i = i + 1
            end
        end
    end
end

function SingleGameAI:getAllGroup(whom)
    local _, cardGroup = self:getSomeOneCards(whom)
    if cardGroup then
        self:cleanTable(cardGroup)
        self:createBaseCardGroup(whom)
        self:createStrightCardGroup(whom)
        self:getCardGroupWeight(whom)
    end
end

--在基础组合后的牌型中组合顺子牌型（飞机，双顺，单顺）
function SingleGameAI:createStrightCardGroup(whom)
    self:createPlaneCardGroup(whom)
    self:createDoubleStrightCardGroup(whom)
    self:createSingleStrightCardGroup(whom)
    self:marginSingleToStright(whom)
    self:marginSingleWithDoubleDragon(whom)
    self:marginSingleWithThreeDragon(whom)
end

--在基础组合后的牌型中组合飞机
function SingleGameAI:createPlaneCardGroup(whom)
    local _, cardGroup = self:getSomeOneCards(whom)
    local i = 1
    local j = i + 1
    local threeDragonCardList = {}
    if cardGroup and type(cardGroup[i]) == "table" then
        table.sort(cardGroup, sortCardGroup)
        local current = cardGroup[i]
        local next = cardGroup[j]
        local currentValue = 0
        local nextValue = 0
        local isFirst = true
        while current and next do
            if type(next) == "table" and current.cardValue and next.cardValue then
                currentValue = current.cardValue
                nextValue = next.cardValue
                if current.cardType == cardType_.THREE_CARDS then
                    --前后两组牌比较，如果能够组成连牌，则将前组牌插入到后组牌中组成新的牌型
                    if next.cardType == cardType_.THREE_CARDS and nextValue - currentValue == 1 and nextValue < cardValue_.CARD_POINT_2 then
                        current.toremove = true
                        if next.cardList then
                            for key, var in ipairs(next.cardList) do
                                table.insert(threeDragonCardList, var)
                            end
                        end
                        if isFirst then
                            if current.cardList then
                                for key, var in ipairs(current.cardList) do
                                    table.insert(threeDragonCardList, 1, var)
                                end
                            end
                            isFirst = false
                        end
                    else
                        isFirst = true
                        --三顺最少要6张，这里判断是否成功组成三顺
                        if #threeDragonCardList > 3 then
                            current.toremove = false
                            current.cardType = cardType_.THREE_DRAGON
                            for key, var in pairs(threeDragonCardList) do
                                current.cardList[key] = var
                            end
                        end
                        threeDragonCardList = {}
                    end
                end
                i = j
                j = j + 1
                current = cardGroup[i]
                next = cardGroup[j]

                if next == nil then
                    --三顺最少要6张，这里判断是否成功组成三顺
                    if #threeDragonCardList > 3 then
                        current.toremove = false
                        current.cardType = cardType_.THREE_DRAGON
                        for key, var in pairs(threeDragonCardList) do
                            current.cardList[key] = var
                        end
                    end
                end
            end
        end
    end

    i = 1
    while cardGroup and cardGroup[i] do
        if cardGroup[i].toremove then
            table.remove(cardGroup, i)
        else
            i = i + 1
        end
    end

    self:initToRemove(whom)
end

--在基础组合后的牌型中组合双顺
function SingleGameAI:createDoubleStrightCardGroup(whom)
    local _, cardGroup = self:getSomeOneCards(whom)
    local i = 1
    local j = i + 1

    if cardGroup then
        table.sort(cardGroup, sortCardGroup)
        local doubleCardGroupList = {}
        for key, var in pairs(cardGroup) do
            if var and var.cardType and var.cardType == cardType_.DOUBLE_CARDS or var.cardType == cardType_.THREE_CARDS then
                table.insert(doubleCardGroupList, var)
            end
        end

        if doubleCardGroupList and type(doubleCardGroupList[i]) == "table" then
            local singleCardGroupList = {} --记录牌型是三张时拆分出来的单牌
            local singleCardList = {}
            local doubleStrightCardList = {}
            local current = doubleCardGroupList[i]
            local next = doubleCardGroupList[j]
            local currentValue = 0
            local nextValue = 0
            while current and next do
                if type(next) == "table" and current.cardValue and next.cardValue then
                    currentValue = current.cardValue
                    nextValue = next.cardValue
                    if current.cardType == cardType_.DOUBLE_CARDS or current.cardType == cardType_.THREE_CARDS then
                        if (next.cardType == cardType_.DOUBLE_CARDS or next.cardType == cardType_.THREE_CARDS) then
                            if nextValue - currentValue == 1 and nextValue < cardValue_.CARD_POINT_2 then
                                --如果牌型是三张，则保存一份被拆分出来的单牌牌型
                                if current.cardType == cardType_.THREE_CARDS then
                                    table.insert(singleCardList, {cardType = cardType_.SINGLE_CARD, cardValue = currentValue, cardList = {current.cardList[#current.cardList]}})
                                end
                                current.toremove = true

                                for var=1, 2 do
                                    if current.cardList and current.cardList[var] then
                                        table.insert(doubleStrightCardList, 1, current.cardList[var])
                                    end
                                end
                            else
                                --双顺最少要6张，这里判断是否成功组成双顺，由于最后一组对子没有添加进doubleStrightCardList中，所以只要doubleStrightCardList长度大于2即已组成双顺
                                if #doubleStrightCardList > 2 then
                                    --判断最后一组牌是否是三张，如果是三张则需要删除一张单牌来组双顺
                                    if current.cardType == cardType_.THREE_CARDS then
                                        if current.cardList and current.cardList[#current.cardList] then
                                            table.insert(singleCardList, {cardType = cardType_.SINGLE_CARD, cardValue = currentValue, cardList = {current.cardList[#current.cardList]}})
                                            table.remove(current.cardList, #current.cardList)
                                        end
                                    end

                                    current.cardType = cardType_.DOUBLE_DRAGON
                                    for key, var in pairs(doubleStrightCardList) do
                                        if current.cardList and current.cardList[1] then
                                            table.insert(current.cardList, 1, var)
                                        end
                                    end

                                    table.insert(singleCardGroupList, singleCardList)
                                    singleCardList = {}

                                else
                                    --如果未组成双顺，则被置为待删除状态的只有第一组对子牌型，所以只需要恢复上一组牌的状态即可
                                    if doubleCardGroupList[i - 1] and doubleCardGroupList[i - 1].toremove == true then
                                        doubleCardGroupList[i - 1].toremove = false
                                    end

                                    self:cleanTable(singleCardList)
                                end

                                --添加完双的牌张后将双顺顺列表清空
                                self:cleanTable(doubleStrightCardList)

                            end
                            i = j
                        end
                    else
                        i = j
                    end
                    j = j + 1

                    current = doubleCardGroupList[i]
                    next = doubleCardGroupList[j]

                    --当这是最后一手牌时
                    if next == nil then
                        --双顺最少要6张，这里判断是否成功组成双顺，由于最后一组对子没有添加进doubleStrightCardList中，所以只要doubleStrightCardList长度大于2即已组成双顺
                        if #doubleStrightCardList > 2 then
                            --判断最后一组牌是否是三张，如果是三张则需要添加被拆分出来的单牌
                            if current.cardType == cardType_.THREE_CARDS then
                                table.insert(singleCardGroupList, {{cardType = cardType_.SINGLE_CARD, cardValue = current.cardList[1].value, cardList = {current.cardList[#current.cardList]}}})
                                table.remove(current.cardList, #current.cardList)
                            end
                            current.cardType = cardType_.DOUBLE_DRAGON

                            for key, var in pairs(doubleStrightCardList) do
                                table.insert(current.cardList, 1, var)
                            end

                            table.insert(singleCardGroupList, singleCardList)
                            singleCardList = {}

                            --添加完双的牌张后将双顺顺列表清空
                            self:cleanTable(doubleStrightCardList)
                        else
                            --如果未组成双顺，则被置为待删除状态的只有第一组对子牌型，所以只需要恢复上一组牌的状态即可
                            if doubleCardGroupList[i - 1] and doubleCardGroupList[i - 1].toremove == true then
                                doubleCardGroupList[i - 1].toremove = false
                            end
                        end
                    end
                end
            end

            --添加被拆分出来的单牌牌组
            for key, var in pairs(singleCardGroupList) do
                if var then
                    for k, v in pairs(var) do
                        table.insert(cardGroup, v)
                    end
                end
            end

            --将保存的拆分出来的单牌请空
            self:cleanTable(singleCardGroupList)

            for key, var in pairs(doubleCardGroupList) do
                i = 1
                while cardGroup and cardGroup[i] do
                    if cardGroup[i].cardType == var.cardType and cardGroup[i].cardValue == var.cardValue and var.toremove then
                        table.remove(cardGroup, i)
                        break
                    else
                        i = i + 1
                    end
                end
            end
        end
    end

    self:initToRemove(whom)
end

--在基础组合后的牌型中组合单顺
function SingleGameAI:createSingleStrightCardGroup(whom)
    local cards, cardGroup = self:getSomeOneCards(whom)
    local i = 1
    local j = i + 1
    local strightValue = {}
    local removeCardMap = {} --用来保存组顺子的过程中将对子或者三张中删除的牌张，在组顺子失败是需要根据这里面的值恢复之前的对子或者三张
    local singleCardGroupList = {} --用来保存将对子拆分出来的单牌牌组
    local doubleCardGroupList = {} --用来保存将三张拆分出来的对子牌组
    local singleCount = 0
    local doubleCount = 0

    local current = cardGroup[i]
    local next = cardGroup[j]
    local currentValue = 0
    local nextValue = 0
    if cardGroup and type(current) == "table" then
        table.sort(cardGroup, sortCardGroup)
        while current and next do
            currentValue = current.cardValue
            nextValue = next.cardValue
            if type(next) == "table" then
                if current.cardType == cardType_.SINGLE_CARD or current.cardType == cardType_.DOUBLE_CARDS or current.cardType == cardType_.THREE_CARDS then
                    if (next.cardType == cardType_.SINGLE_CARD or next.cardType == cardType_.DOUBLE_CARDS or next.cardType == cardType_.THREE_CARDS)
                        and nextValue - currentValue == 1 and nextValue < cardValue_.CARD_POINT_2 then

                        --如果牌型是对子时，保存一份被拆分出来的单牌牌型
                        if current.cardType == cardType_.DOUBLE_CARDS then
                            table.insert(singleCardGroupList, {cardType = cardType_.SINGLE_CARD, cardValue = currentValue, cardList = {current.cardList[1]}})
                            singleCount = singleCount + 1
                            --如果牌型是三张，则保存一份被拆分出来的对子牌型
                        elseif current.cardType == cardType_.THREE_CARDS then
                            table.insert(doubleCardGroupList, {cardType = cardType_.DOUBLE_CARDS, cardValue = currentValue, cardList = {current.cardList[1], current.cardList[2]}})
                            doubleCount = doubleCount + 1
                        end

                        current.toremove = true
                        table.insert(strightValue, current.cardList[#current.cardList])
                    else
                        --下一组不是单牌或者连接不上时，将顺子的最后一张添加上，上面的循环不会添加最后一张
                        --由于这里是两张两张比较，如果满足条件则将前组牌添加进单顺列表，所以这里的strightValue只要是有4张牌就已经组成单顺了
                        if #strightValue > 3 then
                            --对最后一组牌进行拆牌保存，上面的判断会过掉顺子的最后一组牌
                            --如果牌型是对子时，保存一份被拆分出来的单牌牌型
                            if current.cardType == cardType_.DOUBLE_CARDS then
                                table.insert(singleCardGroupList, {cardType = cardType_.SINGLE_CARD, cardValue = currentValue, cardList = {current.cardList[1]}})
                                --如果牌型是三张，则保存一份被拆分出来的对子牌型
                            elseif current.cardType == cardType_.THREE_CARDS then
                                table.insert(doubleCardGroupList, {cardType = cardType_.DOUBLE_CARDS, cardValue = currentValue, cardList = {current.cardList[1], current.cardList[2]}})
                            end

                            table.insert(strightValue, current.cardList[#current.cardList])
                            current.cardType = cardType_.SINGLE_DRAGON
                            for m = 1, #strightValue do
                                current.cardList[m] = strightValue[m]
                            end
                        else
                            for n = 1, #strightValue do
                                if cardGroup[i - n] and cardGroup[i - n].toremove == true then
                                    cardGroup[i - n].toremove = false
                                end
                            end
                            for n = 1, singleCount do
                                table.remove(singleCardGroupList, #singleCardGroupList)
                            end

                            for n = 1, doubleCount do
                                table.remove(doubleCardGroupList, #doubleCardGroupList)
                            end
                        end
                        --添加完单顺的牌张后将单顺列表清空
                        self:cleanTable(strightValue)

                        singleCount = 0
                        doubleCount = 0
                    end
                end
                i = j
                j = j + 1

                current = cardGroup[i]
                next = cardGroup[j]
                currentValue = current.cardValue

                --当这是最后一手牌时
                if next == nil then
                    --下一组不是单牌或者连接不上时，将顺子的最后一张添加上，上面的循环不会添加最后一张
                    --由于这里是两张两张比较，如果满足条件则将前组牌添加进单顺列表，所以这里的strightValue只要是有4张牌就已经组成单顺了
                    if #strightValue > 3 then
                        if current.cardType == cardType_.DOUBLE_CARDS then
                            table.insert(singleCardGroupList, {cardType = cardType_.SINGLE_CARD, cardValue = currentValue, cardList = {current.cardList[1]}})
                            --如果牌型是三张，则保存一份被拆分出来的对子牌型
                        elseif current.cardType == cardType_.THREE_CARDS then
                            table.insert(doubleCardGroupList, {cardType = cardType_.DOUBLE_CARDS, cardValue = currentValue, cardList = {current.cardList[1], current.cardList[2]}})
                        end
                        table.insert(strightValue, current.cardList[1])
                        current.cardType = cardType_.SINGLE_DRAGON
                        for m = 1, #strightValue do
                            current.cardList[m] = strightValue[m]
                        end

                        --添加完单顺的牌张后将单顺列表清空
                        self:cleanTable(strightValue)
                    else
                        for n = 1, #strightValue do
                            if cardGroup[i - n] and cardGroup[i - n].toremove == true then
                                cardGroup[i - n].toremove = false
                            end
                        end

                        for n = 1, singleCount do
                            table.remove(singleCardGroupList, #singleCardGroupList)
                        end

                        for n = 1, doubleCount do
                            table.remove(doubleCardGroupList, #doubleCardGroupList)
                        end
                    end
                end
            end
        end

        --添加被拆分出来的单牌牌组
        for key, var in pairs(singleCardGroupList) do
            table.insert(cardGroup, var)
        end

        --添加被拆分出来的对子牌组
        for key, var in pairs(doubleCardGroupList) do
            table.insert(cardGroup, var)
        end

        --清空拆分出来的单牌牌组列表
        self:cleanTable(singleCardGroupList)
        --清空拆分出来的对子牌组列表
        self:cleanTable(doubleCardGroupList)

        i = 1
        while cardGroup and cardGroup[i] do
            if cardGroup[i].toremove then
                table.remove(cardGroup, i)
            else
                i = i + 1
            end
        end

    end

    self:initToRemove(whom)
end

--检查组合完剩余的单牌是否可以再组成顺子
function SingleGameAI:marginSingleToStright(whom)
    local cards, cardGroup = self:getSomeOneCards(whom)
    table.sort(cardGroup, sortCardGroup)
    --判断单牌是否可以和顺子的两头组成对子
    for i = 1, #cardGroup do
        if cardGroup[i] and cardGroup[i].cardType == cardType_.SINGLE_DRAGON then
            local singleDragonGroup = cardGroup[i]
            local singleDragonCardList = singleDragonGroup.cardList
            for j = 1, #cardGroup do
                local toMarginGroup = cardGroup[j]
                if toMarginGroup and (toMarginGroup.cardType == cardType_.SINGLE_CARD or toMarginGroup.cardType == cardType_.DOUBLE_CARDS) then
                    if singleDragonCardList and #singleDragonCardList > 5 and singleDragonCardList[1] then
                        if singleDragonCardList[1].value == toMarginGroup.cardValue then
                            if toMarginGroup.cardType == cardType_.SINGLE_CARD then
                                toMarginGroup.cardType = cardType_.DOUBLE_CARDS
                            else
                                toMarginGroup.cardType = cardType_.THREE_CARDS
                            end
                            table.insert(toMarginGroup.cardList, singleDragonCardList[1])
                            table.remove(singleDragonCardList, 1)
                        elseif singleDragonCardList[#singleDragonCardList].value == toMarginGroup.cardValue then
                            singleDragonGroup.cardValue = singleDragonGroup.cardValue - 1
                            if toMarginGroup.cardType == cardType_.SINGLE_CARD then
                                toMarginGroup.cardType = cardType_.DOUBLE_CARDS
                            else
                                toMarginGroup.cardType = cardType_.THREE_CARDS
                            end
                            table.insert(toMarginGroup.cardList, singleDragonCardList[#singleDragonCardList])
                            table.remove(singleDragonCardList, #singleDragonCardList)
                        end
                    end
                end
            end
        end
    end

    --获取未组成顺子的单牌，并按照顺子的顺序进行分组
    local unstrightCardList = self:getUnStrightCardGroup(whom)

    --判断是否有单牌可以替代顺子中的某张牌，从而将一个顺子拆成两个顺子
    for i = 1, #cardGroup do
        if cardGroup[i] and cardGroup[i].cardType == cardType_.SINGLE_DRAGON then
            local singleDragonCardList = {}
            for j = 1, #unstrightCardList do
                local cardList = cardGroup[i].cardList
                local singleCards = unstrightCardList[j]
                if cardList and #cardList > 8 then
                    for n = 1, #cardList do
                        if cardList[n] and cardList[n].value == singleCards[1].value then
                            if n - 1 + #singleCards > 4 and #cardList - (n - 1) > 4 then
                                local newStrightCardGroup = {}
                                newStrightCardGroup.cardType = cardType_.SINGLE_DRAGON
                                newStrightCardGroup.cardValue = singleCards[#singleCards].value
                                newStrightCardGroup.cardList = {}
                                for m = 1, n - 1 do
                                    table.insert(newStrightCardGroup.cardList, cardList[m])
                                end
                                for m = 1, #unstrightCardList[j] do
                                    table.insert(newStrightCardGroup.cardList, singleCards[m])
                                end
                                table.insert(cardGroup, newStrightCardGroup)
                                for m = 1, n - 1 do
                                    cardList[m].toremove = true
                                end
                                singleCards.used = true
                            end
                        end
                    end

                    local n = 1
                    while cardList[n] do
                        if cardList[n].toremove then
                            table.remove(cardList, n)
                        else
                            n = n + 1
                        end
                    end
                end
            end
        end
    end

    for i = 1, #unstrightCardList do
        local singleCards = unstrightCardList[i]
        if singleCards and singleCards.used then
            for j = 1, #singleCards do
                local n = 1
                while cardGroup[n] and type(singleCards[j]) == "table" do
                    if cardGroup[n].cardValue == singleCards[j].value then
                        if cardGroup[n].cardType == cardType_.DOUBLE_CARDS then
                            cardGroup[n].cardType = cardType_.SINGLE_CARD
                            table.remove(cardGroup[n].cardList, 1)
                        else
                            table.remove(cardGroup, n)
                        end
                        break
                    else
                        n = n + 1
                    end
                end
            end
        end
    end

    self:initToRemove(whom)
end

--检查单牌是否可以与双顺的头尾组合成两个单顺
function SingleGameAI:marginSingleWithDoubleDragon(whom)
    local cards, cardGroup = self:getSomeOneCards(whom)
    table.sort(cardGroup, sortCardGroup)
    --获取未组成顺子的单牌，并按照顺子的顺序进行分组
    local unstrightCardList = self:getUnStrightCardGroup(whom)

    local newStrightCardGroupList = {}
    local hadMarginUnstrightIndex = 0

    --判断是否有单顺可以和双顺的头或者尾连接上
    local singleDragonCardGroupList = self:getCardGroupByType(cardType_.SINGLE_DRAGON, whom)

    --从已经按照顺序排好的单牌牌组列表中遍历
    for i = 1, #cardGroup do
        if cardGroup[i] and cardGroup[i].cardType == cardType_.DOUBLE_DRAGON then
            if cardGroup[i].cardList and cardGroup[i].cardList[1] then
                local dragonCardGroup = cardGroup[i]
                local dragonCardList = dragonCardGroup.cardList
                local dragonLength = #dragonCardList
                local dragonHeadValue = dragonCardList[1].value
                local dragonEndValue = dragonCardGroup.cardValue
                local canStrightWithHead = false
                local canStrightWithEnd = false
                local headStrightCardGroup = {} --从双顺的头组成的顺子
                headStrightCardGroup.cardList = {}
                local endStrightCardGroup = {} --从双顺的尾组成的顺子
                endStrightCardGroup.cardList = {}
                for j = 1, #unstrightCardList do
                    if unstrightCardList[j] then
                        for n = 1, #unstrightCardList[j] do
                            local card = unstrightCardList[j][n]
                            if card then
                                if card.value + 1 == dragonHeadValue then
                                    if n + dragonLength / 2 > 4 then
                                        canStrightWithHead = true
                                        headStrightCardGroup.cardType = cardType_.SINGLE_DRAGON
                                        headStrightCardGroup.cardValue = dragonEndValue
                                        for m = 1, n do
                                            table.insert(headStrightCardGroup.cardList, unstrightCardList[j][m])
                                            unstrightCardList[j][m].toremove = true
                                        end

                                        local m = 1
                                        while dragonCardList[m] do
                                            table.insert(headStrightCardGroup.cardList, dragonCardList[m])
                                            m = m + 2
                                        end
                                        cardGroup[i].toremove = true
                                        hadMarginUnstrightIndex = j
                                    end
                                elseif dragonEndValue + 1 == card.value then
                                    if #unstrightCardList[j] - n + 1 + dragonLength / 2 > 4 then
                                        canStrightWithEnd = true
                                        endStrightCardGroup.cardType = cardType_.SINGLE_DRAGON

                                        local m = 1
                                        while dragonCardList[m] do
                                            table.insert(endStrightCardGroup.cardList, dragonCardList[m])
                                            m = m + 2
                                        end

                                        for m = n, #unstrightCardList[j] do
                                            table.insert(endStrightCardGroup.cardList, unstrightCardList[j][m])
                                            unstrightCardList[j][m].toremove = true
                                            endStrightCardGroup.cardValue = unstrightCardList[j][m].value
                                        end
                                        cardGroup[i].toremove = true
                                        hadMarginUnstrightIndex = j
                                    end
                                end
                            end
                        end
                    end
                end

                --如果没有完成拆分，则用单顺来替代单牌是否能够和双顺的头或者尾连接起来
                --前提是至少有一组单牌能够和双顺的头或者尾连接起来
                local marginWithSingleDragonHead = false
                local marginWithSingleDragonEnd = false
                if (canStrightWithEnd or canStrightWithHead) and (canStrightWithEnd and canStrightWithHead) == false  then
                    local marginSingleDragon = function (isFromHead)
                        if singleDragonCardGroupList then
                            for key, var in pairs(singleDragonCardGroupList) do
                                if var and var.cardList and var.cardList[1] and var.cardList[#var.cardList] then
                                    local singleDragonHeadValue = var.cardList[1].value
                                    local singleDragonEndValue = var.cardList[#var.cardList].value
                                    if isFromHead then
                                        if dragonHeadValue - 1 == singleDragonEndValue then
                                            local j = 1
                                            while dragonCardList[j] do
                                                table.insert(var.cardList, dragonCardList[j])
                                                j = j + 2
                                            end
                                            canStrightWithHead = true
                                            marginWithSingleDragonEnd = true
                                        end
                                    else
                                        if dragonEndValue + 1 == singleDragonHeadValue then
                                            local j = #dragonCardList
                                            while dragonCardList[j] do
                                                table.insert(var.cardList, 1, dragonCardList[j])
                                                j = j - 2
                                            end
                                            canStrightWithEnd = true
                                            marginWithSingleDragonHead = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if canStrightWithHead then
                        marginSingleDragon(false)
                    else
                        marginSingleDragon(true)
                    end
                end

                --这里判断双顺的头和尾是否都已组成单顺
                if canStrightWithEnd and canStrightWithHead then
                    if marginWithSingleDragonEnd then
                        table.insert(newStrightCardGroupList, endStrightCardGroup)
                    elseif marginWithSingleDragonHead then
                        table.insert(newStrightCardGroupList, headStrightCardGroup)
                    else
                        table.insert(newStrightCardGroupList, endStrightCardGroup)
                        table.insert(newStrightCardGroupList, headStrightCardGroup)
                    end
                else
                    if dragonLength / 2 > 4 then
                        --如果没有全部组成单顺，则判断双顺自身是否可以拆成单顺，即双顺长度是否大于10
                        if canStrightWithEnd then
                            table.insert(newStrightCardGroupList, endStrightCardGroup)
                        elseif canStrightWithHead then
                            table.insert(newStrightCardGroupList, headStrightCardGroup)
                        end
                        if canStrightWithEnd or canStrightWithHead then
                            cardGroup[i].cardType = cardType_.SINGLE_DRAGON
                            local n = 2
                            while cardGroup[i].cardList and cardGroup[i].cardList[n] do
                                table.remove(cardGroup[i].cardList, n)
                                n = n + 1
                            end
                            cardGroup[i].toremove = false
                        end
                    else
                        if canStrightWithHead then
                            if #headStrightCardGroup.cardList - dragonLength / 2 > 3 then
                                for var = 1, dragonLength / 2 - 1 do
                                    table.remove(headStrightCardGroup.cardList, #headStrightCardGroup.cardList)
                                end
                                headStrightCardGroup.cardValue = headStrightCardGroup.cardList[#headStrightCardGroup.cardList].value
                                table.insert(newStrightCardGroupList, headStrightCardGroup)
                                table.insert(newStrightCardGroupList, {cardType = cardType_.SINGLE_CARD, cardValue = dragonHeadValue, cardList = {dragonCardList[1]}})
                                table.remove(dragonCardList, 1)
                                table.remove(dragonCardList, 1)

                                if #dragonCardList > 4 then
                                    cardGroup[i].toremove = false
                                else
                                    local i = 1
                                    while dragonCardList[i] do
                                        table.insert(newStrightCardGroupList, {cardType = cardType_.DOUBLE_CARDS, cardValue = dragonCardList[i].value, cardList = {dragonCardList[i], dragonCardList[i + 1]}})
                                        i = i + 2
                                    end
                                end
                            else
                                cardGroup[i].toremove = false
                                if unstrightCardList[hadMarginUnstrightIndex] then
                                    for key, var in pairs(unstrightCardList[hadMarginUnstrightIndex]) do
                                        if var then
                                            var.toremove = false
                                        end
                                    end
                                end
                            end
                        elseif canStrightWithEnd then
                            if #endStrightCardGroup.cardList - dragonLength / 2 > 3 then
                                for var = 1, dragonLength / 2 - 1 do
                                    table.remove(endStrightCardGroup.cardList, 1)
                                end
                                table.insert(newStrightCardGroupList, endStrightCardGroup)
                                table.insert(newStrightCardGroupList, {cardType = cardType_.SINGLE_CARD, cardValue = dragonEndValue, cardList = {dragonCardList[#dragonCardList]}})
                                table.remove(dragonCardList, #dragonCardList)
                                table.remove(dragonCardList, #dragonCardList)

                                if #dragonCardList > 4 then
                                    cardGroup[i].toremove = false
                                    cardGroup[i].cardValue = dragonCardList[#dragonCardList].value
                                else
                                    local i = 1
                                    while dragonCardList[i] do
                                        table.insert(newStrightCardGroupList, {cardType = cardType_.DOUBLE_CARDS, cardValue = dragonCardList[i].value, cardList = {dragonCardList[i], dragonCardList[i + 1]}})
                                        i = i + 2
                                    end
                                end
                            else
                                cardGroup[i].toremove = false
                                if unstrightCardList[hadMarginUnstrightIndex] then
                                    for key, var in pairs(unstrightCardList[hadMarginUnstrightIndex]) do
                                        if var then
                                            var.toremove = false
                                        end
                                    end
                                end
                            end
                        else
                            --如果上述条件都不满足则放弃拆分
                            cardGroup[i].toremove = false
                            if unstrightCardList[hadMarginUnstrightIndex] then
                                for key, var in pairs(unstrightCardList[hadMarginUnstrightIndex]) do
                                    if var then
                                        var.toremove = false
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    --删除已经被拆分的双顺牌组
    local i = 1
    while cardGroup[i] do
        if cardGroup[i].toremove then
            table.remove(cardGroup, i)
        else
            i = i + 1
        end
    end

    --删除已经组成单顺的单牌
    for key, var in pairs(unstrightCardList) do
        i = 1
        while var and var[i] do
            if var[i].toremove then
                local j = 1
                while cardGroup[j] do
                    if (cardGroup[j].cardType == cardType_.SINGLE_CARD or cardGroup[j].cardType == cardType_.DOUBLE_CARDS) and cardGroup[j].cardValue == var[i].value then
                        if cardGroup[j].cardType == cardType_.DOUBLE_CARDS then
                            cardGroup[j].cardType = cardType_.SINGLE_CARD
                            table.remove(cardGroup[j].cardList, 1)
                        else
                            table.remove(cardGroup, j)
                        end
                        break
                    else
                        j = j + 1
                    end
                end
            end
            i = i + 1
        end
    end

    --插入新组成的单顺牌组
    for key, var in pairs(newStrightCardGroupList) do
        if var then
            table.insert(cardGroup, var)
        end
    end

    --组单顺时会拆分对子，所以在合并完之后再判断一次是否有单牌可以和单顺的头或者尾组成对子
    self:marginSingleToStright(whom)

    self:initToRemove(whom)
end

--检查是否有单牌可以和三顺进行拆分组合，组成单顺
function SingleGameAI:marginSingleWithThreeDragon(whom)
    local cards, cardGroup = self:getSomeOneCards(whom)
    table.sort(cardGroup, sortCardGroup)
    --获取未组成顺子的单牌，并按照顺子的顺序进行分组
    local unstrightCardList = self:getUnStrightCardGroup(whom)

    local newStrightCardGroupList = {}
    local doubleCardGroupList = {} --拆分三顺剩余的对子牌组
    for key, threeDragonGroup in pairs(cardGroup) do
        if threeDragonGroup and threeDragonGroup.cardType == cardType_.THREE_DRAGON and threeDragonGroup.cardList then
            local dragonLength = #threeDragonGroup.cardList
            if threeDragonGroup.cardList[1] and threeDragonGroup.cardList[dragonLength] then
                local dragonCardList = threeDragonGroup.cardList
                local dragonHeadValue = dragonCardList[1].value
                local dragonEndValue = dragonCardList[dragonLength].value
                for k, singleCards in pairs(unstrightCardList) do
                    --这里只组合三张以上单牌，如果是三张以下则没有必要拆分三顺
                    if #singleCards > 2 then
                        if singleCards[1] and singleCards[#singleCards] then
                            local headValue = singleCards[1].value
                            local endValue = singleCards[#singleCards].value
                            if endValue + 1 == dragonHeadValue or dragonEndValue + 1 == headValue then
                                local newStrightGroup = {}
                                newStrightGroup.cardList = {}
                                newStrightGroup.cardType = cardType_.SINGLE_DRAGON
                                if endValue + 1 == dragonHeadValue then
                                    newStrightGroup.cardValue = dragonEndValue
                                    for n, singleCard in pairs(singleCards) do
                                        table.insert(newStrightGroup.cardList, singleCard)
                                        singleCard.toremove = true
                                    end

                                    local i = 1
                                    while dragonCardList[i] do
                                        table.insert(newStrightGroup.cardList, dragonCardList[i])
                                        i = i + 3
                                    end
                                else
                                    newStrightGroup.cardValue = endValue

                                    local i = 1
                                    while dragonCardList[i] do
                                        table.insert(newStrightGroup.cardList, dragonCardList[i])
                                        i = i + 3
                                    end

                                    for n, singleCard in pairs(singleCards) do
                                        table.insert(newStrightGroup.cardList, singleCard)
                                        singleCard.toremove = true
                                    end
                                end

                                --保存新组成的单顺
                                table.insert(newStrightCardGroupList, newStrightGroup)
                                threeDragonGroup.toremove = true

                                --保存三顺被拆分出来的对子
                                local i = 1
                                while dragonCardList and dragonCardList[i] do
                                    local doubleGroup = {}
                                    doubleGroup.cardList = {}
                                    doubleGroup.cardType = cardType_.DOUBLE_CARDS
                                    doubleGroup.cardValue = dragonCardList[i].value
                                    table.insert(doubleGroup.cardList, dragonCardList[i])
                                    table.insert(doubleGroup.cardList, dragonCardList[i+1])
                                    table.insert(doubleCardGroupList, doubleGroup)
                                    i = i + 3
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    for key, var in pairs(unstrightCardList) do
        if var then
            local headCard = var[1]
            local endCard = var[#var]

            if headCard.toremove ~= true and endCard.toremove ~= true then
                for k, v in pairs(newStrightCardGroupList) do
                    if v then
                        local dragonGroupCardList = v.cardList
                        local dragonHeadValue = dragonGroupCardList[1].value
                        local dragonEndValue = v.cardValue
                        if headCard and headCard.value - 1 == dragonEndValue then
                            v.cardValue = endCard.value
                            for n, value in pairs(var) do
                                value.toremove = true
                                table.insert(dragonGroupCardList, value)
                            end
                        elseif endCard and endCard.value + 1 == dragonHeadValue then
                            for n, value in pairs(var) do
                                value.toremove = true
                                table.insert(dragonGroupCardList, n, value)
                            end
                        end
                    end
                end
            end
        end
    end

    --删除被拆分的三顺
    local i = 1
    while cardGroup and cardGroup[i] do
        if cardGroup[i].toremove then
            table.remove(cardGroup, i)
        else
            i = i + 1
        end
    end

    --删除已组成单顺的单牌
    for k, singleCards in pairs(unstrightCardList) do
        for key, card in pairs(singleCards) do
            i = 1
            while cardGroup and cardGroup[i] do
                if (cardGroup[i].cardType == cardType_.SINGLE_CARD or cardGroup[i].cardType == cardType_.DOUBLE_CARDS) and cardGroup[i].cardValue == card.value and card.toremove then
                    if cardGroup[i].cardType == cardType_.DOUBLE_CARDS then
                        cardGroup[i].cardType = cardType_.SINGLE_CARD
                        table.remove(cardGroup[i].cardList, 1)
                    else
                        table.remove(cardGroup, i)
                    end
                    break
                else
                    i = i + 1
                end
            end
        end
    end

    --添加新组成的单顺
    for key, var in pairs(newStrightCardGroupList) do
        if var then
            table.insert(cardGroup, var)
        end
    end

    --添加被拆分出来的对子
    for key, var in pairs(doubleCardGroupList) do
        if var then
            table.insert(cardGroup, var)
        end
    end

    table.sort(cardGroup, sortCardGroup)

    --检查对子是否能够组成双顺
    self:createDoubleStrightCardGroup(whom)

    self:initToRemove(whom)
end

--获取未组成顺子的单牌，并按照顺子的顺序进行排序分组
function SingleGameAI:getUnStrightCardGroup(whom)
    local cards, cardGroup = self:getSomeOneCards(whom)
    table.sort(cardGroup, sortCardGroup)
    local unstrightCardList = {}
    local singleCardList = {}
    for key, var in pairs(cardGroup) do
        if (var.cardType == cardType_.SINGLE_CARD or var.cardType == cardType_.DOUBLE_CARDS) and var.cardValue < cardValue_.CARD_POINT_2 and var.cardList and var.cardList[1] then
            table.insert(singleCardList, var.cardList[1])
        end
    end

    table.sort(singleCardList, sortCard)

    local current = 1
    local next = 0
    local tempList = {}
    local isFirst = true
    while singleCardList[current] do
        next = current + 1
        if singleCardList[next] then
            if singleCardList[next].value - singleCardList[current].value == 1 then
                if isFirst then
                    table.insert(tempList, singleCardList[current])
                    table.insert(tempList, singleCardList[next])
                    isFirst = false
                else
                    table.insert(tempList, singleCardList[next])
                end
                if singleCardList[next + 1] == nil then
                    table.insert(unstrightCardList, tempList)
                end
            else
                if isFirst then
                    table.insert(tempList, singleCardList[current])
                end
                table.insert(unstrightCardList, tempList)
                isFirst = true
                tempList = {}
                if singleCardList[next + 1] == nil then
                    table.insert(tempList, singleCardList[next])
                    table.insert(unstrightCardList, tempList)
                end
            end
        end
        current = current + 1
    end

    return unstrightCardList
end

--计算手牌牌型权值
function SingleGameAI:getCardGroupWeight(whom)
    local cards, cardGroup
    if type(whom) == "number" then
        cards, cardGroup = self:getSomeOneCards(whom)
    elseif type(whom) == "table" then
        cardGroup = whom
    end
    if cardGroup then
        local weight = 0
        local handCount = #cardGroup
        for key, var in pairs(cardGroup) do
            for k, v in pairs(cardType_) do
                if var.cardType == v then
                    if var.cardType == cardType_.SINGLE_DRAGON then
                        weight = weight + cardTypeWeight_[k] + #var.cardList - 5
                    elseif var.cardType == cardType_.DOUBLE_DRAGON or var.cardType == cardType_.THREE_DRAGON then
                        weight = weight + cardTypeWeight_[k] + #var.cardList - 6
                    else
                        weight = weight + cardTypeWeight_[k]
                    end
                end
            end
        end
        if whom == pos_.SELF then
            self.selfCardsGroupWeight_ = weight
            self.selfCardsGroupHandCount_ = handCount
        elseif whom == pos_.PRE then
            self.preCardsGroupWeight_ = weight
            self.preCardsGroupHandCount_ = handCount
        elseif whom == pos_.NEXT then
            self.nextCardsGroupWeight_ = weight
            self.nextCardsGroupHandCount_ = handCount
        end
    end
end

function SingleGameAI:initToRemove(whom)
    local cards, cardGroup = self:getSomeOneCards(whom)
    for key, var in pairs(cardGroup) do
        if type(var) == "table" then
            var.toremove = false
            if var.cardList then
                for k, v in pairs(var.cardList) do
                    if v then
                        v.toremove = false
                    end
                end
            end
        end
    end
end

--组牌AI END

--出牌AI BEGIN

--出牌的统一入口
function SingleGameAI:doTakeOutCards(lastTakeOutCardGroup, whom, lordPos, lastTakeOutPos, singleGameManager)
    local needTakeOutCardGroup = nil
    self.currentPos_ = whom
    self.lordPos_ = lordPos
    self.lastTakeOutPos_ = lastTakeOutPos
    self.singleGameManager_ = singleGameManager
    if self.againistPos_ then
        self:cleanTable(self.againistPos_)
    end
    if self.friendPos_ then
        self:cleanTable(self.friendPos_)
    end
    if whom == self.lordPos_ then
        if pos_ then
            for key, var in pairs(pos_) do
                if whom ~= var then
                    table.insert(self.againistPos_, var)
                end
            end
        end
    else
        if pos_ then
            for key, var in pairs(pos_) do
                if self.lordPos_ ~= var and whom ~= var then
                    table.insert(self.friendPos_, var)
                end
            end
            table.insert(self.againistPos_, self.lordPos_)
        end
    end
    if log_util.isDebug() == true then
        log_util.i(TAG, "doTakeOutCards IN curr seat is ", whom)
        log_util.i(TAG, "doTakeOutCards IN lord seat is ", self.lordPos_)
    end

    if self.friendPos_ then
        if log_util.isDebug() == true then
            log_util.i(TAG, "doTakeOutCards IN friend seats is ", self.friendPos_[1])
        end

    end

    if self.againistPos_ then
        if log_util.isDebug() == true then
            log_util.i(TAG, "doTakeOutCards IN againist seats is ", self.againistPos_[1])
        end
    end

    self:getAllGroup(whom)
    self:getAllGroup(pos_.SELF)

    if lastTakeOutCardGroup == nil then
        needTakeOutCardGroup = self:firstTakeoutCard(whom)
    else
        if lastTakeOutCardGroup.cardType == self.cardType_.DOUBLE_JOKER then
            return nil
        end
        needTakeOutCardGroup = self:followTakeOutCard(lastTakeOutCardGroup, whom, lastTakeOutPos)
    end

    if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
        local cardValue = ""
        for key, var in pairs(needTakeOutCardGroup.cardList) do
            cardValue = cardValue..var.value..", "
        end
        self:removeTakeoutCard(needTakeOutCardGroup.cardList, whom)
        if log_util.isDebug() == true then
            log_util.i("SingleGameAI", "needTakeOutCardGroup type is ", needTakeOutCardGroup.cardType, " card list is ", cardValue)
        end

    end
    return needTakeOutCardGroup
end

--首出
function SingleGameAI:firstTakeoutCard(whom)
    local needTakeOutCardGroup = nil
    if log_util.isDebug() == true then
        log_util.i(TAG, "firstTakeoutCard IN self.lordPos_ is ", self.lordPos_, " whom is ", whom)
    end

    if whom == self.lordPos_ then
        needTakeOutCardGroup = self:lordPosFirstTakeOutCard(whom)
    else
        if whom - self.lordPos_ == -1 or whom - self.lordPos_ == 2 then
            needTakeOutCardGroup = self:lordPosPreFirstTakeOutCard(whom)
        else
            if whom - self.lordPos_ == 1 or whom - self.lordPos_ == -2 then
                needTakeOutCardGroup = self:lordPosNextFirstTakeOutCard(whom)
            end
        end
    end

    return needTakeOutCardGroup
end

--当敌家剩余一张牌时的首出出牌逻辑
function SingleGameAI:firstTakeOutWhenAgainistHasOnlyOneCard(whom)
    local needTakeOutCardGroup = nil
    local _, cardGroup = self:getSomeOneCards(whom)
    local i = 1
    if cardGroup then
        while cardGroup[i] do
            local isBiggest = self:checkCardGroupIsBiggest(cardGroup[i], whom)
            if cardGroup[i].cardType == cardType_.SINGLE_CARD or cardGroup[i].cardValue > cardValue_.CARD_POINT_A or cardGroup[i].cardType == cardType_.FOUR_CARDS then
                i = i + 1
            else
                if cardGroup[i].cardType == cardType_.THREE_CARDS then
                    needTakeOutCardGroup = cardGroup[i]
                    self:addSingleCardOrDoubleCardToThree(needTakeOutCardGroup, 1, cardType_.THREE_CARDS, whom)
                else
                    if cardGroup[i].cardType == cardType_.THREE_DRAGON then
                        needTakeOutCardGroup = cardGroup[i]
                        if cardGroup[i].cardList then
                            self:addSingleCardOrDoubleCardToThree(needTakeOutCardGroup, math.modf(#cardGroup[i].cardList / 3), cardType_.THREE_DRAGON, whom)
                        end
                    else
                        needTakeOutCardGroup = cardGroup[i]
                    end
                end
                break
            end
        end

        --如果这里的needTakeOutCardGroup为nil，则表示手牌中只剩下最大的牌和单牌，这之后将单牌从大到小出
        if needTakeOutCardGroup == nil then
            local i = #cardGroup
            while cardGroup[i] do
                local isBiggest = self:checkCardGroupIsBiggest(cardGroup[i], whom)
                if isBiggest then
                    i = i - 1
                else
                    needTakeOutCardGroup = cardGroup[i]
                    break
                end
            end

            if needTakeOutCardGroup == nil then
                needTakeOutCardGroup = cardGroup[1]
            end
        end
    end

    return needTakeOutCardGroup
end

--当对家剩余一张牌时的首出出牌逻辑
function SingleGameAI:firstTakeOutWhenFriendHasOnlyOneCard(whom)
    local needTakeOutCardGroup = nil
    local _, cardGroup = self:getSomeOneCards(whom)
    if cardGroup and self.friendPos_ and self.friendPos_[1] then
        local _, friendCardGroup = self:getSomeOneCards(self.friendPos_[1])
        if friendCardGroup and friendCardGroup[1] then
            for k,v in pairs(cardGroup) do
                if v then
                    if v.cardValue < friendCardGroup[1].cardValue then
                        needTakeOutCardGroup = {}
                        needTakeOutCardGroup.cardType = cardType_.SINGLE_CARD
                        needTakeOutCardGroup.cardValue = cardGroup[1].cardValue
                        needTakeOutCardGroup.cardList = {}
                        table.insert(needTakeOutCardGroup.cardList, cardGroup[1].cardList[1])
                    end
                end
            end

            if needTakeOutCardGroup == nil then
                needTakeOutCardGroup = self:doFirstTakeOutCard(whom)
            end
        end
    end

    return needTakeOutCardGroup
end


--获取敌家最少的手牌数
function SingleGameAI:getAgainistCardCount()
    local againistCardCount = 0
    for key, var in pairs(self.againistPos_) do
        local againistCards = self:getSomeOneCards(var)
        if againistCards then
            if againistCardCount == 0 then
                againistCardCount = #againistCards
            else
                if #againistCards < againistCardCount then
                    againistCardCount = #againistCards
                end
            end
        end
    end
    return againistCardCount
end

--获取对家手牌数
function SingleGameAI:getFriendCardCount()
    local friendCardCount = 0
    if self.friendPos_ and self.friendPos_[1] then
        local friendCards = self:getSomeOneCards(self.friendPos_[1])
        if friendCards then
            friendCardCount = #friendCards
        end
    end
    return friendCardCount
end

--首出时，可以一手出完时的出牌逻辑
function SingleGameAI:doFirstTakeOutOneHand(whom)
    local needTakeOutCardGroup = nil
    if self:checkCanTakeOutOneHand(whom) then
        if log_util.isDebug() == true then
            log_util.i(TAG, "doFirstTakeOutOneHand IN ")
        end

        local _, cardGroup = self:getSomeOneCards(whom)
        if cardGroup then
            local takeOutOneHand = function (var)
                needTakeOutCardGroup = var
                if var.cardType == cardType_.THREE_CARDS then
                    self:addSingleCardOrDoubleCardToThree(needTakeOutCardGroup, 1, cardType_.THREE_CARDS, whom)
                end
                if var.cardType == cardType_.THREE_DRAGON then
                    if var.cardList then
                        self:addSingleCardOrDoubleCardToThree(needTakeOutCardGroup, math.modf(#var.cardList / 3), cardType_.THREE_DRAGON, whom)
                    end
                end
            end

            if #cardGroup == 2 then
                local threeCardGroupCount = 0
                local singleOrDoubleCardGroupCount = 0
                for k,v in pairs(cardGroup) do
                    if v and v.cardType == self.cardType_.THREE_CARDS then
                        threeCardGroupCount = threeCardGroupCount + 1
                    end
                    if v and (v.cardType == self.cardType_.SINGLE_CARD or v.cardType == self.cardType_.DOUBLE_CARDS) then
                        singleOrDoubleCardGroupCount = singleOrDoubleCardGroupCount + 1
                    end
                end
                if threeCardGroupCount == 1 and singleOrDoubleCardGroupCount == 1 then
                    if cardGroup[1].cardType == self.cardType_.THREE_CARDS then
                        needTakeOutCardGroup = cardGroup[1]
                    else
                        needTakeOutCardGroup = cardGroup[2]
                    end
                    self:addSingleCardOrDoubleCardToThree(needTakeOutCardGroup, 1, cardType_.THREE_CARDS, whom)
                    return needTakeOutCardGroup
                end
            end
            local smallestCard = nil
            for key, var in pairs(cardGroup) do
                if var and var.isBiggest and var.cardType ~= cardType_.FOUR_CARDS then
                    if smallestCard == nil or var.cardValue < smallestCard.cardValue then
                        smallestCard = var
                    end
                end
            end

            if smallestCard then
                takeOutOneHand(smallestCard)
            end
            smallestCard = nil
            if needTakeOutCardGroup == nil then
                for key, var in pairs(cardGroup) do
                    if var and var.isBiggest then
                        if smallestCard == nil or var.cardValue < smallestCard.cardValue then
                            smallestCard = var
                        end
                    end
                end
                if smallestCard then
                    takeOutOneHand(smallestCard)
                end
            end

            if needTakeOutCardGroup == nil then
                needTakeOutCardGroup = cardGroup[1]
            end
        end
    end
    return needTakeOutCardGroup
end

--地主位首出
function SingleGameAI:lordPosFirstTakeOutCard(whom)
    local needTakeOutCardGroup = nil
    local _, cardGroup = self:getSomeOneCards(whom)
    if log_util.isDebug() == true then
        log_util.i(TAG, "lordPosFirstTakeOutCard IN")
    end

    needTakeOutCardGroup = self:doFirstTakeOutOneHand(whom)
    if log_util.isDebug() == true then
        log_util.i(TAG, "lordPosFirstTakeOutCard IN needTakeOutCardGroup is ", needTakeOutCardGroup)
    end

    if self.againistPos_ and cardGroup and needTakeOutCardGroup == nil then
        local againistCardCount = self:getAgainistCardCount()
        if log_util.isDebug() == true then
            log_util.i(TAG, "againistCardCount is ", againistCardCount)
        end

        --如果敌家手牌只剩1张，则需要把单牌最后出
        if againistCardCount == 1 then
            if log_util.isDebug() == true then
                log_util.i(TAG, "#cardGroup is ", #cardGroup)
            end

            if #cardGroup == 2 then
                needTakeOutCardGroup = self:doFirstTakeOutCardSpecial(whom)
                if not needTakeOutCardGroup then
                    needTakeOutCardGroup = self:firstTakeOutWhenAgainistHasOnlyOneCard(whom)
                end
            else
                needTakeOutCardGroup = self:firstTakeOutWhenAgainistHasOnlyOneCard(whom)
            end
        else
            needTakeOutCardGroup = self:doFirstTakeOutCardSpecial(whom)
            
            if needTakeOutCardGroup == nil then
                needTakeOutCardGroup = self:doFirstTakeOutCard(whom)
            end
        end
    end

    return needTakeOutCardGroup
end

--地主上家位首出
function SingleGameAI:lordPosPreFirstTakeOutCard(whom)
    local needTakeOutCardGroup = nil
    local _, cardGroup = self:getSomeOneCards(whom)
    if log_util.isDebug() == true then
        log_util.i(TAG, "lordPosPreFirstTakeOutCard IN ")
    end

    needTakeOutCardGroup = self:doFirstTakeOutOneHand(whom)
    if log_util.isDebug() == true then
        log_util.i(TAG, "lordPosPreFirstTakeOutCard IN one hand needTakeOutCardGroup is ", needTakeOutCardGroup)
    end

    if self.againistPos_ and cardGroup and needTakeOutCardGroup == nil then
        local againistCardCount = self:getAgainistCardCount()
        if log_util.isDebug() == true then
            log_util.i(TAG, "lordPosPreFirstTakeOutCard IN againistCardCount is ", againistCardCount)
        end

        if againistCardCount == 1 then
            needTakeOutCardGroup = self:firstTakeOutWhenAgainistHasOnlyOneCard(whom)
        else
            local friendCardCount = self:getFriendCardCount()
            if friendCardCount == 1 then
                needTakeOutCardGroup = self:firstTakeOutWhenFriendHasOnlyOneCard(whom)
            else
                needTakeOutCardGroup = self:doFirstTakeOutCardSpecial(whom)
                if needTakeOutCardGroup == nil then
                    needTakeOutCardGroup = self:doFirstTakeOutCard(whom)
                end
            end
        end
    end

    return needTakeOutCardGroup
end

--地主下家位首出
function SingleGameAI:lordPosNextFirstTakeOutCard(whom)
    local needTakeOutCardGroup = nil
    local _, cardGroup = self:getSomeOneCards(whom)
    if log_util.isDebug() == true then
        log_util.i(TAG, "lordPosNextFirstTakeOutCard IN")
    end

    if cardGroup then
        local friendCardCount = self:getFriendCardCount()
        if friendCardCount == 1 then
            local doubleJokerCardGroup = self:getCardGroupByType(cardType_.DOUBLE_JOKER, self.currentPos_)
            local fourCardGroup = self:getCardGroupByType(cardType_.FOUR_CARDS, self.currentPos_)
            if doubleJokerCardGroup and doubleJokerCardGroup[1] then
                needTakeOutCardGroup = doubleJokerCardGroup[1]
                return needTakeOutCardGroup
            else
                if fourCardGroup and fourCardGroup[1] then
                    needTakeOutCardGroup = fourCardGroup[1]
                    return needTakeOutCardGroup
                end
            end
            needTakeOutCardGroup = self:firstTakeOutWhenFriendHasOnlyOneCard(whom)
        else
            needTakeOutCardGroup = self:doFirstTakeOutOneHand(whom)
            if needTakeOutCardGroup == nil then
                needTakeOutCardGroup = self:doFirstTakeOutCardSpecial(whom)
                if needTakeOutCardGroup == nil then
                    needTakeOutCardGroup = self:doFirstTakeOutCard(whom)
                end
            end
        end
    end

    return needTakeOutCardGroup
end

--特殊情况下的首出牌逻辑
function SingleGameAI:doFirstTakeOutCardSpecial(whom)
    local needTakeOutCardGroup = nil

    if log_util.isDebug() == true then
        log_util.i(TAG, "doFirstTakeOutCardSpecial IN")
    end


    local _, cardGroup = self:getSomeOneCards(whom)

    if self.againistPos_ then
        local isAgainistHasOnlyDoubleCards = true
        local biggestCardValue = 0
        for _,pos in pairs(self.againistPos_) do
            if pos then
                log_util.i(TAG, "doFirstTakeOutCardSpecial IN pos is ", pos)
                local _, againistCardGroup = self:getSomeOneCards(pos)
                for _,cardGroup in pairs(againistCardGroup) do
                    if cardGroup then
                        if cardGroup.cardType ~= self.cardType_.DOUBLE_CARDS then
                            isAgainistHasOnlyDoubleCards = false
                            break
                        else
                            if cardGroup.cardValue > biggestCardValue then
                                biggestCardValue = cardGroup.cardValue
                            end
                        end
                    end
                end
            end
        end

        if log_util.isDebug() == true then
            log_util.i(TAG, "doFirstTakeOutCardSpecial IN isAgainistHasOnlyDoubleCards is ", isAgainistHasOnlyDoubleCards)
        end


        if isAgainistHasOnlyDoubleCards then
            if cardGroup then
                for _,cg in pairs(cardGroup) do
                    if cg and cg.cardType ~= self.cardType_.DOUBLE_CARDS and cg.cardValue < self.cardValue_.CARD_POINT_LITTLE_JOKER then
                        if cg.cardType == self.cardType_.SINGLE_CARD then
                            if cg.cardValue < biggestCardValue then
                                needTakeOutCardGroup = cg
                                return needTakeOutCardGroup
                            end
                        else
                            needTakeOutCardGroup = cg
                            if cg.cardType == self.cardType_.THREE_CARDS then
                                self:addSingleCardOrDoubleCardToThree(needTakeOutCardGroup, 1, cardType_.THREE_CARDS, whom)
                            end
                            return needTakeOutCardGroup
                        end
                    end
                end

                for _,cg in pairs(cardGroup) do
                    if cg then
                        if cg.cardType == self.cardType_.DOUBLE_CARDS and cg.cardValue < self.cardValue_.CARD_POINT_2 then
                            needTakeOutCardGroup = {}
                            needTakeOutCardGroup.cardType = self.cardType_.SINGLE_CARD
                            needTakeOutCardGroup.cardValue = cg.cardValue
                            needTakeOutCardGroup.cardList = {}
                            needTakeOutCardGroup.cardList[1] = cg.cardList[1]
                            return needTakeOutCardGroup
                        else
                            needTakeOutCardGroup = cg
                            return needTakeOutCardGroup
                        end
                    end
                end
            end
        end
    end

    if log_util.isDebug() == true then
        log_util.i(TAG, "doFirstTakeOutCardSpecial IN #cardGroup is ", #cardGroup)
    end


    --自己手牌剩余两手的情况
    if cardGroup and #cardGroup < 3 then
        local threeCardGroupList = self:getCardGroupByType(cardType_.THREE_CARDS, whom)
        local threeDragonCardGroupList = self:getCardGroupByType(cardType_.THREE_DRAGON, whom)
        local singleCardGroupList = self:getCardGroupByType(cardType_.SINGLE_CARD, whom)
        local doubleCardGroupList = self:getCardGroupByType(cardType_.DOUBLE_CARDS, whom)
        local fourCardGroupList = self:getCardGroupByType(cardType_.FOUR_CARDS, whom)
        local againistCardCount = self:getAgainistCardCount()
        if fourCardGroupList and #fourCardGroupList > 0 then
            if againistCardCount > 1 then
                for k,v in pairs(cardGroup) do
                    if v and v.cardType ~= cardType_.FOUR_CARDS then
                        needTakeOutCardGroup = v
                    end
                end
            else
                needTakeOutCardGroup = fourCardGroupList[1]
            end
            return needTakeOutCardGroup
        end
        if threeCardGroupList and (singleCardGroupList or doubleCardGroupList) then
            if threeCardGroupList[1] then
                if singleCardGroupList and singleCardGroupList[1] then
                    needTakeOutCardGroup = threeCardGroupList[1]
                    if singleCardGroupList[1].cardList and needTakeOutCardGroup.cardList then
                        for key, var in pairs(singleCardGroupList[1].cardList) do
                            if var then
                                table.insert(needTakeOutCardGroup.cardList, var)
                                needTakeOutCardGroup.cardType = cardType_.THREE_WITH_ONE
                            end
                        end
                    end
                elseif doubleCardGroupList and doubleCardGroupList[1] then
                    needTakeOutCardGroup = threeCardGroupList[1]
                    if doubleCardGroupList[1].cardList and needTakeOutCardGroup.cardList then
                        for key, var in pairs(doubleCardGroupList[1].cardList) do
                            if var then
                                table.insert(needTakeOutCardGroup.cardList, var)
                                needTakeOutCardGroup.cardType = cardType_.THREE_WITH_TWO
                            end
                        end
                    end
                end
            end
        end

        if threeDragonCardGroupList and doubleCardGroupList then
            if threeDragonCardGroupList[1] and threeDragonCardGroupList[1].cardList and #threeDragonCardGroupList[1].cardList == 6 then
                if doubleCardGroupList[1] then
                    needTakeOutCardGroup = threeDragonCardGroupList[1]
                    if doubleCardGroupList[1].cardList and needTakeOutCardGroup.cardList then
                        for key, var in pairs(doubleCardGroupList[1].cardList) do
                            if var then
                                table.insert(needTakeOutCardGroup.cardList, var)
                                needTakeOutCardGroup.cardType = cardType_.THREE_WITH_TWO
                            end
                        end
                    end
                end
            end
        end

        if needTakeOutCardGroup == nil then
            for key, var in pairs(cardGroup) do
                if var and var.cardType ~= cardType_.SINGLE_CARD and var.cardType ~= cardType_.DOUBLE_CARDS then
                    needTakeOutCardGroup = var
                    return needTakeOutCardGroup
                end
            end

            needTakeOutCardGroup = cardGroup[1]
        end

        return needTakeOutCardGroup
    end

    if cardGroup and #cardGroup < 4 then
        local singleCardCount = 0
        local doubleCardCount = 0
        local threeCardCount = 0
        local hasBigJoker = false
        for key, var in pairs(cardGroup) do
            if var and var.cardType == cardType_.SINGLE_CARD then
                singleCardCount = singleCardCount + 1
                if var.cardValue == cardValue_.CARD_POINT_BIG_JOKER then
                    hasBigJoker = true
                end
            end

            if var and var.cardType == cardType_.DOUBLE_CARDS then
                doubleCardCount = doubleCardCount + 1
            end

            if var and var.cardType == cardType_.THREE_CARDS then
                threeCardCount = threeCardCount + 1
            end
        end

        if singleCardCount > 1 and hasBigJoker then
            local singleCardGroupList = self:getCardGroupByType(cardType_.SINGLE_CARD, whom)
            if singleCardGroupList and singleCardGroupList[1] then
                needTakeOutCardGroup = singleCardGroupList[1]
                return needTakeOutCardGroup
            end
        end

        -- 如果手上剩余三手牌，并且有单顺或者双顺，则先出单顺或者双顺
        if needTakeOutCardGroup == nil then
            for key, var in pairs(cardGroup) do
                if var and (var.cardType == cardType_.SINGLE_DRAGON or var.cardType == cardType_.DOUBLE_DRAGON) then
                    needTakeOutCardGroup = var
                end
            end
        end

        if needTakeOutCardGroup == nil then
            if threeCardCount > 0 then
                if (singleCardCount == 1 and doubleCardCount == 1) or singleCardCount == 2 or doubleCardCount == 2 then
                    local smallestCard = nil
                    for k,v in pairs(cardGroup) do
                        if v and v.cardType ~= cardType_.THREE_CARDS then
                            if smallestCard == nil or v.cardValue < smallestCard.cardValue then
                                smallestCard = v
                            end
                        end

                        if v and v.cardType == cardType_.THREE_CARDS then
                            needTakeOutCardGroup = v
                        end
                    end

                    if smallestCard and smallestCard.cardType == cardType_.SINGLE_CARD then
                        needTakeOutCardGroup.cardType = cardType_.THREE_WITH_ONE
                        table.insert(needTakeOutCardGroup.cardList, smallestCard.cardList[1])
                    end

                    if smallestCard and smallestCard.cardType == cardType_.DOUBLE_CARDS then
                        needTakeOutCardGroup.cardType = cardType_.THREE_WITH_TWO
                        table.insert(needTakeOutCardGroup.cardList, smallestCard.cardList[1])
                        table.insert(needTakeOutCardGroup.cardList, smallestCard.cardList[2])
                    end                    
                end
            end
        end
    end
    return needTakeOutCardGroup
end

--将单牌或对子添加到三张或三顺组成三带或者三顺带
function SingleGameAI:addSingleCardOrDoubleCardToThree(needTakeOutCardGroup, addCount, type, whom)
    local _, cardGroup = self:getSomeOneCards(whom)

    local isSingleCardOrDoubleCardsOnly = false
    if #cardGroup == 2 then
        -- 当手牌剩余两手时，如果是三带一或者三带二则一手出完
        for k,v in pairs(cardGroup) do
            if v and (v.cardType == cardType_.SINGLE_CARD or v.cardType == cardType_.DOUBLE_CARDS) then
                isSingleCardOrDoubleCardsOnly = true
                break
            end
        end
    end

    local singleCardList = self:getCardGroupByType(cardType_.SINGLE_CARD, whom)
    local doubleCardList = self:getCardGroupByType(cardType_.DOUBLE_CARDS, whom)
    local threeDragonCardList = self:getCardGroupByType(cardType_.THREE_DRAGON, whom)
    local totalDragonLength = 0
    if threeDragonCardList and #threeDragonCardList > 0 then
        for k,v in pairs(threeDragonCardList) do
            if v and v.cardList then
                totalDragonLength = totalDragonLength + #v.cardList / 3
            end
        end

        if singleCardList then
            if #singleCardList >= totalDragonLength then
                if #cardGroup - #threeDragonCardList - totalDragonLength == 1 then
                    isSingleCardOrDoubleCardsOnly = true
                end
            end
        end

        if not isSingleCardOrDoubleCardsOnly then
            if doubleCardList then
                if #doubleCardList * 2 >= totalDragonLength then
                    if #cardGroup - #threeDragonCardList - totalDragonLength / 2 == 1 then
                        isSingleCardOrDoubleCardsOnly = true
                    end
                end
            end
        end
    end

    local isTakeOutPlaneOneHand = false -- 是否飞机可以一手出完，即单牌或对子可以与飞机组成一手牌出完结束牌局

    local getLessThen2CardCount = function (cardType, isLessThen2)
        local cardGroupList = self:getCardGroupByType(cardType, self.currentPos_)
        local lessThen2CardCount = 0
        if cardGroupList then
            for key, var in pairs(cardGroupList) do
                if var and var.cardValue and var.cardValue < cardValue_.CARD_POINT_2 or isSingleCardOrDoubleCardsOnly or isTakeOutPlaneOneHand or not isLessThen2 then
                    lessThen2CardCount = lessThen2CardCount + 1
                end
            end
        end
        return lessThen2CardCount
    end

    -- 计算是否可以飞机一手带完
    if type == cardType_.THREE_DRAGON then
        local singleCardCount = getLessThen2CardCount(cardType_.SINGLE_CARD, false)
        local doubleCardCount = getLessThen2CardCount(cardType_.DOUBLE_CARDS, false)
        if singleCardCount > 0 then
            if addCount == singleCardCount + doubleCardCount * 2 and #cardGroup == singleCardCount + doubleCardCount + 1 then
                isTakeOutPlaneOneHand = true
            end
        else
            if (addCount == doubleCardCount or addCount == doubleCardCount * 2) and #cardGroup == doubleCardCount + 1 then
                isTakeOutPlaneOneHand = true
            end
        end
    end

    local singleCardLessThen2Count = getLessThen2CardCount(cardType_.SINGLE_CARD, true)
    local doubleCardLessThen2Count = getLessThen2CardCount(cardType_.DOUBLE_CARDS, true)
    local threeCardLessThen2Count = getLessThen2CardCount(cardType_.THREE_CARDS, true)
    local singleCardLessThen2List = {}
    local doubleCardLessThen2List = {}

    if log_util.isDebug() == true then
        log_util.i(TAG, "addSingleCardOrDoubleCardToThree IN isTakeOutPlaneOneHand is ", isTakeOutPlaneOneHand)
        log_util.i(TAG, "addSingleCardOrDoubleCardToThree IN addCount is ", addCount, " singleCardLessThen2Count is ", singleCardLessThen2Count, " getLessThen2CardCount is ", doubleCardLessThen2Count)
    end


    if cardGroup then
        for key, var in pairs(cardGroup) do
            if var and var.cardType and var.cardValue < cardValue_.CARD_POINT_2 or isSingleCardOrDoubleCardsOnly or isTakeOutPlaneOneHand then
                if var.cardType == cardType_.SINGLE_CARD then
                    table.insert(singleCardLessThen2List, var)
                elseif var.cardType == cardType_.DOUBLE_CARDS then
                    table.insert(doubleCardLessThen2List, var)
                end
            end
        end
    end

    if singleCardLessThen2Count >= addCount or doubleCardLessThen2Count >= addCount then
        local makeThreeWithOne = function ()
            for i = 1, addCount do
                if singleCardLessThen2List[i] and singleCardLessThen2List[i].cardList then
                    for key, var in pairs(singleCardLessThen2List[i].cardList) do
                        if var then
                            table.insert(needTakeOutCardGroup.cardList, var)
                        end
                    end
                end
            end
            if type == cardType_.THREE_CARDS then
                needTakeOutCardGroup.cardType = cardType_.THREE_WITH_ONE
            elseif type == cardType_.THREE_DRAGON then
                needTakeOutCardGroup.cardType = cardType_.THREE_ONE_DRAGON
            end
        end

        local makeThreeWithTwo = function ()
            for i = 1, addCount do
                if doubleCardLessThen2List[i] and doubleCardLessThen2List[i].cardList then
                    for key, var in pairs(doubleCardLessThen2List[i].cardList) do
                        if var then
                            table.insert(needTakeOutCardGroup.cardList, var)
                        end
                    end
                end
            end
            if type == cardType_.THREE_CARDS then
                needTakeOutCardGroup.cardType = cardType_.THREE_WITH_TWO
            elseif type == cardType_.THREE_DRAGON then
                needTakeOutCardGroup.cardType = cardType_.THREE_TWO_DRAGON
            end
        end

        if singleCardLessThen2Count >= addCount and doubleCardLessThen2Count >= addCount then
            --如果单牌和对子都有牌可以带的话，判断各自最小的牌，哪个小选择哪个
            local singleCardGroup = singleCardLessThen2List[1]
            local doubleCardGroup = doubleCardLessThen2List[1]
            if singleCardGroup and singleCardGroup.cardValue and doubleCardGroup and doubleCardGroup.cardValue then
                if singleCardGroup.cardValue > doubleCardGroup.cardValue then
                    makeThreeWithTwo()
                else
                    makeThreeWithOne()
                end
            end
        else
            if singleCardLessThen2Count >= addCount then
                makeThreeWithOne()
            else
                makeThreeWithTwo()
            end
        end
    elseif doubleCardLessThen2Count * 2 >= addCount and addCount % 2 == 0 then
        for i = 1, addCount / 2 do
            if doubleCardLessThen2List[i] and doubleCardLessThen2List[i].cardList then
                for key, var in pairs(doubleCardLessThen2List[i].cardList) do
                    if var then
                        if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                            table.insert(needTakeOutCardGroup.cardList, var)
                        end
                    end
                end
            end
        end
    else
        if singleCardLessThen2Count + doubleCardLessThen2Count * 2 >= addCount then
            local singleCount = 1
            local doubleCount = 1
            while singleCount <= singleCardLessThen2Count do
                doubleCount = 1
                while doubleCount <= doubleCardLessThen2Count do
                    if log_util.isDebug() == true then
                        log_util.i(TAG, "addSingleCardOrDoubleCardToThree IN doubleCount is ", doubleCount, " singleCount is ", singleCount)
                    end

                    if singleCount + doubleCount * 2 == addCount then
                        break
                    else
                        doubleCount = doubleCount + 1
                    end
                end
                if log_util.isDebug() == true then
                    log_util.i(TAG, "addSingleCardOrDoubleCardToThree IN doubleCount is ", doubleCount, " singleCount is ", singleCount)
                end

                if singleCount + doubleCount * 2 == addCount then
                    break
                else
                    singleCount = singleCount + 1
                end
            end

            for i = 1, singleCount do
                if singleCardLessThen2List[i] and singleCardLessThen2List[i].cardList then
                    for key, var in pairs(singleCardLessThen2List[i].cardList) do
                        if var then
                            if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                                table.insert(needTakeOutCardGroup.cardList, var)
                            end
                        end
                    end
                end
            end

            for i = 1, doubleCount do
                if doubleCardLessThen2List[i] and doubleCardLessThen2List[i].cardList then
                    for key, var in pairs(doubleCardLessThen2List[i].cardList) do
                        if var then
                            if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                                table.insert(needTakeOutCardGroup.cardList, var)
                            end
                        end
                    end
                end
            end
        end
    end
end

--通用的首出牌逻辑
function SingleGameAI:doFirstTakeOutCard(whom)
    local _, cardGroup = self:getSomeOneCards(whom)
    local needTakeOutCardGroup = nil
    if cardGroup then
        table.sort(cardGroup, sortCardGroup)
        -- 如果手牌中单牌数在与其三张组合后剩余一张的情况下，优先出非单牌的牌
        local threeDragonCardList = self:getCardGroupByType(cardType_.THREE_DRAGON, whom)
        local threeDragonTotalLength = 0
        if threeDragonCardList then
            for k,v in pairs(threeDragonCardList) do
                if v and v.cardList then
                    threeDragonTotalLength = threeDragonTotalLength + #v.cardList / 3
                end
            end
        end

        --根据牌型来获取该牌型下牌值比2小的牌数量
        local getLessThen2CardCount = function (cardType)
            local cardGroupList = self:getCardGroupByType(cardType, self.currentPos_)
            local lessThen2CardCount = 0
            if cardGroupList then
                for key, var in pairs(cardGroupList) do
                    if var and var.cardValue and var.cardValue < cardValue_.CARD_POINT_2 then
                        lessThen2CardCount = lessThen2CardCount + 1
                    end
                end
            end
            return lessThen2CardCount
        end

        local singleCardLessThen2Count = getLessThen2CardCount(cardType_.SINGLE_CARD)
        local doubleCardLessThen2Count = getLessThen2CardCount(cardType_.DOUBLE_CARDS)
        local threeCardLessThen2Count = getLessThen2CardCount(cardType_.THREE_CARDS)

        local i = 1
        while cardGroup[i] do
            if cardGroup[i].cardType == cardType_.SINGLE_CARD then
                if singleCardLessThen2Count - 1 > threeCardLessThen2Count + threeDragonTotalLength then
                    needTakeOutCardGroup = cardGroup[i]
                    break
                else
                    i = i + 1
                end
            else
                if cardGroup[i].cardType == cardType_.DOUBLE_CARDS then
                    if doubleCardLessThen2Count > threeCardLessThen2Count + threeDragonTotalLength - singleCardLessThen2Count then
                        needTakeOutCardGroup = cardGroup[i]
                        break
                    else
                        i = i + 1
                    end
                else
                    if cardGroup[i].cardType == cardType_.THREE_CARDS then
                        needTakeOutCardGroup = cardGroup[i]
                        self:addSingleCardOrDoubleCardToThree(needTakeOutCardGroup, 1, cardType_.THREE_CARDS, whom)
                        break
                    else
                        if cardGroup[i].cardType == cardType_.THREE_DRAGON then
                            needTakeOutCardGroup = cardGroup[i]
                            if cardGroup[i].cardList then
                                self:addSingleCardOrDoubleCardToThree(needTakeOutCardGroup, math.modf(#cardGroup[i].cardList / 3), cardType_.THREE_DRAGON, whom)
                            end
                            break
                        else
                            if cardGroup[i].cardType == cardType_.FOUR_CARDS then
                                i = i + 1
                            else
                                needTakeOutCardGroup = cardGroup[i]
                                break
                            end
                        end
                    end
                end
            end
        end

        if needTakeOutCardGroup == nil then
            needTakeOutCardGroup = cardGroup[1]
        end
    end

    return needTakeOutCardGroup
end

-- 能够一手出完时的跟出逻辑，
-- 该出牌逻辑不拆牌，避免本来能一手出完的牌结果拆分出牌管上以后就不能一手出完的情况
function SingleGameAI:followTakeOutNormalCardOneHand(lastTakeOutCardGroup, whom)
    local handCardList, cardGroup = self:getSomeOneCards(whom)
    local lastTakeOutCardType = -1
    local needTakeOutCardGroup = nil
    -- 三带一三带二或者三顺带牌的情况将牌型改变为基础牌型
    if lastTakeOutCardGroup.cardType == self.cardType_.THREE_WITH_ONE or lastTakeOutCardGroup.cardType == self.cardType_.THREE_WITH_TWO then
        lastTakeOutCardType = self.cardType_.THREE_CARDS
    elseif lastTakeOutCardGroup.cardType == self.cardType_.THREE_ONE_DRAGON or lastTakeOutCardGroup.cardType == self.cardType_.THREE_TWO_DRAGON then
        lastTakeOutCardType = self.cardType_.THREE_DRAGON
    else
        lastTakeOutCardType = lastTakeOutCardGroup.cardType
    end

    if log_util.isDebug() == true then
        log_util.i(TAG, "followTakeOutNormalCardOneHand IN lastTakeOutCardType is ", lastTakeOutCardType)
    end


    needTakeOutCardGroup = self:takeOutNormalCard(lastTakeOutCardGroup, whom, false)
    if needTakeOutCardGroup == nil then
        needTakeOutCardGroup = self:takeOutSpecialCard(lastTakeOutCardGroup, whom, false)
    end
    
    if needTakeOutCardGroup and needTakeOutCardGroup.cardList and handCardList and #handCardList == #needTakeOutCardGroup.cardList then
        needTakeOutCardGroup.isBiggest = true
        return needTakeOutCardGroup
    else
        needTakeOutCardGroup = nil
    end

    -- 获取能管上的基本牌型，单顺双顺三顺需要判断顺子的长度是否与需要管的牌的长度一致
    for k,v in pairs(cardGroup) do
        if v and v.cardType == lastTakeOutCardType and v.cardValue > lastTakeOutCardGroup.cardValue and v.isBiggest then
            if lastTakeOutCardType == self.cardType_.SINGLE_DRAGON or 
                lastTakeOutCardType == self.cardType_.DOUBLE_DRAGON or 
                lastTakeOutCardType == self.cardType_.THREE_DRAGON then
                if #v.cardList == #lastTakeOutCardGroup.cardList then
                    needTakeOutCardGroup = v
                    break
                end
            else
                needTakeOutCardGroup = v
                break
            end
        end
    end

    -- 如果是三带或者三顺带牌的情况，从单牌或者对子中获取需要带的牌
    if needTakeOutCardGroup then
        local noBiggestSingleCardGroupList = {}
        local biggestSingleCardGroupList = {}
        local noBiggestDoubleCardGroupList = {}
        local biggestDoubleCardGroupList = {}

        -- 将最大和非最大的单牌和对子分开处理，优先带非最大的牌
        for k,v in pairs(cardGroup) do
            if v then
                if v.cardType == self.cardType_.SINGLE_CARD then
                    if v.isBiggest then
                        table.insert(biggestSingleCardGroupList, v)
                    else
                        table.insert(noBiggestSingleCardGroupList, v)
                    end
                elseif v.cardType == self.cardType_.DOUBLE_CARDS then
                    if v.isBiggest then
                        table.insert(biggestDoubleCardGroupList, v)
                    else
                        table.insert(noBiggestDoubleCardGroupList, v)
                    end
                end
            end
        end

        local smallestNoBiggestSingleCardGroup = nil
        local smallestBiggestSingleCardGroup = nil
        local smallestNoBiggestDoubleCardGroup = nil
        local smallestBiggestDoubleCardGroup = nil

        -- 从单牌或者对子列表中优先取最小的牌带
        local getSmallestCardFromGroupList = function (smallestCardGroup, groupList)
            for k,v in pairs(groupList) do
                if smallestCardGroup == nil then
                    smallestCardGroup = v
                else
                    if smallestCardGroup.cardValue > v.cardValue then
                        smallestCardGroup = v
                    end
                end
            end    
            return smallestCardGroup
        end
        
        smallestNoBiggestSingleCardGroup = getSmallestCardFromGroupList(smallestNoBiggestSingleCardGroup, noBiggestSingleCardGroupList)
        smallestBiggestSingleCardGroup = getSmallestCardFromGroupList(smallestBiggestSingleCardGroup, biggestSingleCardGroupList)
        smallestNoBiggestDoubleCardGroup = getSmallestCardFromGroupList(smallestNoBiggestDoubleCardGroup, noBiggestDoubleCardGroupList)
        smallestBiggestDoubleCardGroup = getSmallestCardFromGroupList(smallestBiggestDoubleCardGroup, biggestDoubleCardGroupList)

        local addAllCards = function (cardGroupList)
            for k,v in pairs(cardGroupList) do
                for k,card in pairs(v.cardList) do
                    table.insert(needTakeOutCardGroup.cardList, card)    
                end
            end
        end

        if lastTakeOutCardGroup.cardType == self.cardType_.THREE_WITH_ONE then
            -- 三带一的情况只从单牌列表中获取需要带的牌，如果不够带则不出
            if #noBiggestSingleCardGroupList > 0 then
                needTakeOutCardGroup.cardType = self.cardType_.THREE_WITH_ONE
                table.insert(needTakeOutCardGroup.cardList, smallestNoBiggestSingleCardGroup.cardList[1])
            elseif #biggestSingleCardGroupList > 0 then
                needTakeOutCardGroup.cardType = self.cardType_.THREE_WITH_ONE
                table.insert(needTakeOutCardGroup.cardList, smallestBiggestSingleCardGroup.cardList[1])
            else
                needTakeOutCardGroup = nil
            end
        elseif lastTakeOutCardGroup.cardType == self.cardType_.THREE_WITH_TWO then
            -- 三带二的情况只从对子列表中获取需要带的牌，如果不够带则不出
            if #noBiggestDoubleCardGroupList > 0 then
                needTakeOutCardGroup.cardType = self.cardType_.THREE_WITH_TWO
                table.insert(needTakeOutCardGroup.cardList, smallestNoBiggestDoubleCardGroup.cardList[1])
                table.insert(needTakeOutCardGroup.cardList, smallestNoBiggestDoubleCardGroup.cardList[2])
            elseif #biggestDoubleCardGroupList > 0 then
                needTakeOutCardGroup.cardType = self.cardType_.THREE_WITH_TWO
                table.insert(needTakeOutCardGroup.cardList, smallestBiggestDoubleCardGroup.cardList[1])
                table.insert(needTakeOutCardGroup.cardList, smallestBiggestDoubleCardGroup.cardList[2])
            else
                needTakeOutCardGroup = nil
            end
        elseif lastTakeOutCardGroup.cardType == self.cardType_.THREE_ONE_DRAGON then
            local dragonLength = lastTakeOutCardGroup.cardList / 3
            
            -- 三顺带单张的情况遵循 非最大单牌--最大单牌--非最大对子--最大对子 的顺序来获取需要带的牌
            if dragonLength <= #noBiggestSingleCardGroupList then
                -- 如果非最大单牌够带则直接获取对应张数的单牌
                needTakeOutCardGroup.cardType = self.cardType_.THREE_ONE_DRAGON
                for i=1, dragonLength do
                    table.insert(needTakeOutCardGroup.cardList, noBiggestSingleCardGroupList[i].cardList[1])
                end
            elseif dragonLength <= #noBiggestSingleCardGroupList + #biggestSingleCardGroupList then
                -- 否则判断非最大单牌与最大单牌加起来是否够带
                needTakeOutCardGroup.cardType = self.cardType_.THREE_ONE_DRAGON

                addAllCards(noBiggestSingleCardGroupList)

                for i=1, dragonLength - #noBiggestSingleCardGroupList do
                    table.insert(needTakeOutCardGroup.cardList, biggestSingleCardGroupList[i].cardList[1])
                end
            elseif (dragonLength - (#noBiggestSingleCardGroupList + #biggestSingleCardGroupList)) % 2 == 0 then
                -- 如果最大单牌与非最大单牌都不够带的话，则需要判断算上最大单牌与非最大单牌后剩余的牌张数是否能够被2整除，如果能够被2整除则从非最大对子中获取剩余的牌张
                -- 如果非最大对子中不够带的话则从最大对子中获取
                if dragonLength - #noBiggestSingleCardGroupList - #biggestSingleCardGroupList <= #noBiggestDoubleCardGroupList * 2 then
                    needTakeOutCardGroup.cardType = self.cardType_.THREE_ONE_DRAGON
                    addAllCards(noBiggestSingleCardGroupList)
                    addAllCards(biggestSingleCardGroupList)

                    for i=1, (dragonLength - #noBiggestSingleCardGroupList - #biggestSingleCardGroupList) / 2 do
                        table.insert(needTakeOutCardGroup.cardList, noBiggestDoubleCardGroupList[i].cardList[1])
                        table.insert(needTakeOutCardGroup.cardList, noBiggestDoubleCardGroupList[i].cardList[2])
                    end
                elseif dragonLength - #noBiggestSingleCardGroupList - #biggestSingleCardGroupList - #noBiggestDoubleCardGroupList * 2 <= #biggestDoubleCardGroupList * 2 then
                    needTakeOutCardGroup.cardType = self.cardType_.THREE_ONE_DRAGON
                    addAllCards(noBiggestSingleCardGroupList)
                    addAllCards(biggestSingleCardGroupList)
                    addAllCards(noBiggestDoubleCardGroupList)

                    local leftLength = dragonLength - #noBiggestSingleCardGroupList - #biggestSingleCardGroupList - #noBiggestDoubleCardGroupList * 2

                    for i=1, leftLength / 2 do
                        table.insert(needTakeOutCardGroup.cardList, biggestDoubleCardGroupList[i].cardList[1])
                        table.insert(needTakeOutCardGroup.cardList, biggestDoubleCardGroupList[i].cardList[2])
                    end
                else
                    needTakeOutCardGroup = nil    
                end
            else
                needTakeOutCardGroup = nil
            end
        elseif lastTakeOutCardGroup.cardType == self.cardType_.THREE_TWO_DRAGON then
            local dragonLength = lastTakeOutCardGroup.cardList / 3
            -- 三顺带对的情况则从最大对子与非最大对子中获取需要带的牌
            if dragonLength <= #noBiggestDoubleCardGroupList then
                needTakeOutCardGroup.cardType = self.cardType_.THREE_TWO_DRAGON
                for i=1, dragonLength do
                    table.insert(needTakeOutCardGroup.cardList, noBiggestDoubleCardGroupList[i].cardList[1])
                    table.insert(needTakeOutCardGroup.cardList, noBiggestDoubleCardGroupList[i].cardList[2])
                end
            elseif dragonLength <= #biggestDoubleCardGroupList then
                needTakeOutCardGroup.cardType = self.cardType_.THREE_TWO_DRAGON
                for i=1, dragonLength do
                    table.insert(needTakeOutCardGroup.cardList, biggestDoubleCardGroupList[i].cardList[1])
                    table.insert(needTakeOutCardGroup.cardList, biggestDoubleCardGroupList[i].cardList[2])
                end
            else
                needTakeOutCardGroup = nil
            end
        end
    end
    if needTakeOutCardGroup and 
        (#needTakeOutCardGroup.cardList ~= #lastTakeOutCardGroup.cardList or 
            needTakeOutCardGroup.cardValue <= lastTakeOutCardGroup.cardValue or 
            needTakeOutCardGroup.cardType ~= lastTakeOutCardGroup.cardType) then
        needTakeOutCardGroup = nil
    end
    return needTakeOutCardGroup
end

--跟出时，可以一手出完时的出牌逻辑
function SingleGameAI:doFollowTakeOutOneHand(lastTakeOutCardGroup, whom)
    local needTakeOutCardGroup = nil
    if log_util.isDebug() == true then
        log_util.i(TAG, "doFollowTakeOutOneHand IN")
    end

    if self:checkCanTakeOutOneHand(whom, lastTakeOutCardGroup) then
        if log_util.isDebug() == true then
            log_util.i(TAG, "doFollowTakeOutOneHand IN can take out one hand")
        end

        local doubleJokerCardGroup = self:getCardGroupByType(cardType_.DOUBLE_JOKER, whom)
        local fourCardGroup = self:getCardGroupByType(cardType_.FOUR_CARDS, whom)
        if doubleJokerCardGroup then
            needTakeOutCardGroup = doubleJokerCardGroup[1]
        else
            if fourCardGroup then
                for key, var in pairs(fourCardGroup) do
                    if lastTakeOutCardGroup.cardType == cardType_.FOUR_CARDS then
                        if var and var.cardValue and var.cardValue > lastTakeOutCardGroup.cardValue then
                            needTakeOutCardGroup = var
                        end
                    else
                        needTakeOutCardGroup = var
                    end
                end
            else
                needTakeOutCardGroup = self:followTakeOutNormalCardOneHand(lastTakeOutCardGroup, whom)

                if needTakeOutCardGroup then
                    if not needTakeOutCardGroup.isBiggest then
                        needTakeOutCardGroup = nil
                    end
                end
            end
        end
    end
    if needTakeOutCardGroup ~= nil and whom ~= self.lordPos_ then
        self.friendCanTakeOutOneHand_ = true
    end
    return needTakeOutCardGroup
end

--当敌家或对家只剩一张牌时的跟出出牌逻辑
function SingleGameAI:followTakeOutWhenAgainistOrFriendHasOnlyOneCard(lastTakeOutCardGroup, whom)
    local needTakeOutCardGroup = nil
    if lastTakeOutCardGroup then
        local lastTakeOutCardType = lastTakeOutCardGroup.cardType
        local lastTakeOutCardValue = lastTakeOutCardGroup.cardValue
        local againistCardGroup = nil
        if self.againistPos_ then
            for key, var in pairs(self.againistPos_) do
                if againistCardGroup == nil then
                    _, againistCardGroup = self:getSomeOneCards(var)
                else
                    if type(self:getSomeOneCards(var)) == "table" and #self:getSomeOneCards(var) < #againistCardGroup then
                        _, againistCardGroup = self:getSomeOneCards(var)
                    end
                end
            end
        end
        if againistCardGroup and againistCardGroup[1] then
            needTakeOutCardGroup = self:takeOutNormalCard(lastTakeOutCardGroup, whom, true, againistCardGroup[1].cardValue, true)
        else
            needTakeOutCardGroup = self:takeOutNormalCard(lastTakeOutCardGroup, whom, true)
        end

        if needTakeOutCardGroup == nil then
            needTakeOutCardGroup = self:takeOutSpecialCard(lastTakeOutCardGroup, whom, true)
        end
    end
    return needTakeOutCardGroup
end

--获取对应牌型中的最大的牌
function SingleGameAI:getBiggestCardGroupFromCardType(cardType, whom)
    local cardGroupList = {}
    local biggestCardGroup = nil
    local cards, cardGroup = self:getSomeOneCards(whom)
    -- 如果传了cardType则通过cardType获取最大的牌
    if cardType then
        if cardGroup then
            for key, var in pairs(cardGroup) do
                if var and var.cardType == cardType then
                    table.insert(cardGroupList, var)
                end
            end
        end

        if cardGroupList[#cardGroupList] then
            biggestCardGroup = cardGroupList[#cardGroupList]
        end
        return biggestCardGroup
    else
        --如果没有传cardType，则取手牌中最大的一张单牌
        if cards then
            table.sort(cards, sortCard)
            local i = #cards
            while i > 0 do
                local biggestCard = cards[i]
                local biggestCardGroup = {}
                biggestCardGroup.cardType = cardType_.SINGLE_CARD
                biggestCardGroup.cardValue = biggestCard.value
                biggestCardGroup.cardList = {biggestCard}
                local isBiggest = self:checkCardGroupIsBiggest(biggestCardGroup, whom)
                if not isBiggest then
                    return biggestCardGroup
                else
                    i = i - 1
                end
            end
        end
    end
end

-- 当手牌剩余小于4手时的出牌逻辑
function SingleGameAI:followTakeOutCardWhenLastFewHands(lastTakeOutCardGroup, whom, lastTakeOutPos)
    local needTakeOutCardGroup = nil
    local _, cardGroup = self:getSomeOneCards(whom)
    if cardGroup and #cardGroup < 4 and lastTakeOutCardGroup then
        local doubleJokerCardGroupList = self:getCardGroupByType(cardType_.DOUBLE_JOKER, whom)
        local fourCardGroupList = self:getCardGroupByType(cardType_.FOUR_CARDS, whom)
        if doubleJokerCardGroupList and #doubleJokerCardGroupList > 0 then
            needTakeOutCardGroup = doubleJokerCardGroupList[1]
        elseif fourCardGroupList and #fourCardGroupList > 0 then
            if lastTakeOutCardGroup.cardType ~= cardType_.FOUR_CARDS then
                needTakeOutCardGroup = fourCardGroupList[1]
            else
                for key, var in pairs(fourCardGroupList) do
                    if var and var.cardValue > lastTakeOutCardGroup.cardValue then
                        needTakeOutCardGroup = var
                        break
                    end
                end
            end
        else
            needTakeOutCardGroup = self:doFollowTakeOutCard(lastTakeOutCardGroup, whom, true)
        end
    end

    return needTakeOutCardGroup
end

--跟出
function SingleGameAI:followTakeOutCard(lastTakeOutCardGroup, whom, lastTakeOutPos)
    local needTakeOutCardGroup = nil
    if lastTakeOutCardGroup then
        if log_util.isDebug() == true then
            log_util.i(TAG, "followTakeOutCard IN whom is ", whom, " self.lordPos_ is ", self.lordPos_)
        end

        if whom == self.lordPos_ then
            needTakeOutCardGroup = self:lordPosFollowTakeOutCard(lastTakeOutCardGroup, whom, lastTakeOutPos)
        else
            if self.friendPos_ and self.friendPos_[1] and self.friendPos_[1] == lastTakeOutPos then
                if lastTakeOutPos == self.pos_.SELF then
                    local isUserCanTakeOutOneHand = self:checkCanTakeOutOneHand(lastTakeOutPos)
                    if log_util.isDebug() == true then
                        log_util.i(TAG, "followTakeOutCard IN isUserCanTakeOutOneHand is ", isUserCanTakeOutOneHand)
                    end

                    if isUserCanTakeOutOneHand then
                        return nil
                    end
                end
                if self.friendCanTakeOutOneHand_ then
                    return nil
                end
            end
            needTakeOutCardGroup = self:doFollowTakeOutOneHand(lastTakeOutCardGroup, whom)
            if log_util.isDebug() == true then
                log_util.i(TAG, "followTakeOutCard IN needTakeOutCardGroup is ", needTakeOutCardGroup)
            end

            if needTakeOutCardGroup == nil then
                local friendCardCount = self:getFriendCardCount()
                if self.friendPos_ and self.friendPos_[1] and lastTakeOutPos == self.friendPos_[1] and friendCardCount > 1 then
                    if (lastTakeOutCardGroup.cardType ~= self.cardType_.SINGLE_CARD and lastTakeOutCardGroup.cardType ~= self.cardType_.DOUBLE_CARDS) or lastTakeOutCardGroup.cardValue > self.cardValue_.CARD_POINT_K then
                        return nil
                    end
                end
                if whom - self.lordPos_ == 1 or whom - self.lordPos_ == -2 then
                    needTakeOutCardGroup = self:lordPosNextFollowTakeOutCard(lastTakeOutCardGroup, whom, lastTakeOutPos)
                else
                    if whom - self.lordPos_ == -1  or whom - self.lordPos_ == 2 then
                        needTakeOutCardGroup = self:lordPosPreFollowTakeOutCard(lastTakeOutCardGroup, whom, lastTakeOutPos)
                    end
                end
            end
        end
    end

    return needTakeOutCardGroup
end

--地主位跟出
function SingleGameAI:lordPosFollowTakeOutCard(lastTakeOutCardGroup, whom, lastTakeOutPos)
    local needTakeOutCardGroup = nil

    needTakeOutCardGroup = self:doFollowTakeOutOneHand(lastTakeOutCardGroup, whom)
    if self.againistPos_ and needTakeOutCardGroup == nil then
        local againistCardCount = self:getAgainistCardCount()
        if log_util.isDebug() == true then
            log_util.i(TAG, "lordPosFollowTakeOutCard IN againistCardCount is ", againistCardCount)
        end

        --如果敌家手牌只剩1张，则需要把单牌最后出
        if againistCardCount == 1 then
            needTakeOutCardGroup = self:followTakeOutWhenAgainistOrFriendHasOnlyOneCard(lastTakeOutCardGroup, whom)
        else
            local _, cardGroup = self:getSomeOneCards(whom)
            local singleCardGroupLessThanACount = 0
            if cardGroup then
                for k,v in pairs(cardGroup) do
                    if v and v.cardType == self.cardType_.SINGLE_CARD and v.cardValue < self.cardValue_.CARD_POINT_A then
                        singleCardGroupLessThanACount = singleCardGroupLessThanACount + 1
                    end
                end
            end

            needTakeOutCardGroup = self:followTakeOutCardWhenLastFewHands(lastTakeOutCardGroup, whom, lastTakeOutPos)

            if needTakeOutCardGroup == nil then
                if singleCardGroupLessThanACount < 2 or againistCardCount < 5 then
                    needTakeOutCardGroup = self:doFollowTakeOutCard(lastTakeOutCardGroup, whom, true)
                else
                    needTakeOutCardGroup = self:doFollowTakeOutCard(lastTakeOutCardGroup, whom, false)
                end
            end
        end
    end
    if needTakeOutCardGroup then
        self.friendCanTakeOutOneHand_ = false
    end
    return needTakeOutCardGroup
end

--地主上家位跟出
function SingleGameAI:lordPosPreFollowTakeOutCard(lastTakeOutCardGroup, whom, lastTakeOutPos)
    local needTakeOutCardGroup = nil
    local againistCardCount = self:getAgainistCardCount()
    local friendCardCount = self:getFriendCardCount()
    local selfCards, selfCardGroup = self:getSomeOneCards(self.pos_.SELF)
    if log_util.isDebug() == true then
        log_util.i(TAG, "lordPosPreFollowTakeOutCard IN ")
    end

    if self.friendPos_ and self.friendPos_[1] then
        if log_util.isDebug() == true then
            log_util.i(TAG, "lordPosPreFollowTakeOutCard IN lastTakeOutPos is ", lastTakeOutPos, " self.friendPos_[1] is ", self.friendPos_[1])
        end

        if lastTakeOutPos == self.friendPos_[1] then
            if friendCardCount == 1 then
                if againistCardCount == 1 then
                    needTakeOutCardGroup = self:followTakeOutWhenAgainistOrFriendHasOnlyOneCard(lastTakeOutCardGroup, whom)
                else
                    if selfCardGroup and #selfCardGroup == 1 then
                        needTakeOutCardGroup = self:doFollowTakeOutOneHand(lastTakeOutCardGroup, whom)
                        if needTakeOutCardGroup == nil then
                            needTakeOutCardGroup = self:takeOutNormalCard(lastTakeOutCardGroup, whom, false)
                        end

                        return needTakeOutCardGroup
                    else
                        return nil
                    end
                end
            else
                if againistCardCount == 1 then
                    needTakeOutCardGroup = self:followTakeOutWhenAgainistOrFriendHasOnlyOneCard(lastTakeOutCardGroup, whom)
                else
                    if selfCards and #selfCards == 1 then
                        needTakeOutCardGroup = self:doFollowTakeOutCard(lastTakeOutCardGroup, whom, false)
                    else
                        needTakeOutCardGroup = self:doFollowTakeOutCard(lastTakeOutCardGroup, whom, true, cardValue_.CARD_POINT_10)
                    end

                    if lastTakeOutCardGroup then
                        if lastTakeOutCardGroup.cardType > cardType_.DOUBLE_CARDS then
                            needTakeOutCardGroup = nil
                        else
                            if needTakeOutCardGroup then
                                if needTakeOutCardGroup.cardValue > cardValue_.CARD_POINT_K then
                                    if lastTakeOutCardGroup.cardValue > self.cardValue_.CARD_POINT_10 or needTakeOutCardGroup.cardType == cardType_.DOUBLE_CARDS then
                                        needTakeOutCardGroup = nil
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            needTakeOutCardGroup = self:followTakeOutCardWhenLastFewHands(lastTakeOutCardGroup, whom, lastTakeOutPos)
            if log_util.isDebug() == true then
                log_util.i(TAG, "lordPosPreFollowTakeOutCard IN needTakeOutCardGroup is ", needTakeOutCardGroup)
            end

            if needTakeOutCardGroup == nil then
                if againistCardCount == 1 then
                    needTakeOutCardGroup = self:followTakeOutWhenAgainistOrFriendHasOnlyOneCard(lastTakeOutCardGroup, whom)
                else
                    local againistCardGroup = nil
                    if self.againistPos_ then
                        local _, againistCardGroup = self:getSomeOneCards(self.againistPos_[1])
                    end
                    if againistCardGroup and #againistCardGroup < 5 then
                        needTakeOutCardGroup = self:doFollowTakeOutCard(lastTakeOutCardGroup, whom, true)
                    else
                        needTakeOutCardGroup = self:doFollowTakeOutCard(lastTakeOutCardGroup, whom, true, cardValue_.CARD_POINT_10)
                    end
                end
            end
        end
    end

    return needTakeOutCardGroup
end

--地主下家位跟出
function SingleGameAI:lordPosNextFollowTakeOutCard(lastTakeOutCardGroup, whom, lastTakeOutPos)
    local needTakeOutCardGroup = nil
    local friendCardCount = self:getFriendCardCount()
    local againistCardCount = self:getAgainistCardCount()
    if log_util.isDebug() == true then
        log_util.i(TAG, "lordPosNextFollowTakeOutCard IN self.friendPos_[1] is ", self.friendPos_[1])
    end

    if self.friendPos_ and self.friendPos_[1] and lastTakeOutCardGroup then
        if friendCardCount == 1 then
            local selfSmallestCard = self:getSmallestCard(whom)
            local friendSmallestCard = self:getSmallestCard(self.friendPos_[1])
            if log_util.isDebug() == true then
                log_util.i(TAG, "lordPosNextFollowTakeOutCard IN selfSmallestCard.value is", selfSmallestCard.value, " friendSmallestCard.value is ", friendSmallestCard.value)
            end

            if selfSmallestCard.value < friendSmallestCard.value then
                local doubleJokerCardGroup = self:getCardGroupByType(cardType_.DOUBLE_JOKER, whom)
                local fourCardGroup = self:getCardGroupByType(cardType_.FOUR_CARDS, whom)

                if doubleJokerCardGroup and doubleJokerCardGroup[1] then
                    needTakeOutCardGroup = doubleJokerCardGroup[1]
                else
                    if lastTakeOutCardGroup.cardType ~= cardType_.FOUR_CARDS then
                        if fourCardGroup and fourCardGroup[1] then
                            needTakeOutCardGroup = fourCardGroup[1]
                        end
                    else
                        if fourCardGroup then
                            for key, var in pairs(fourCardGroup) do
                                if var and var.cardValue > lastTakeOutCardGroup.cardValue then
                                    needTakeOutCardGroup = var
                                    break
                                end
                            end
                        end
                    end
                end
            end

            if log_util.isDebug() == true then
                log_util.i(TAG, "lordPosNextFollowTakeOutCard IN needTakeOutCardGroup is ", needTakeOutCardGroup)
            end

            if needTakeOutCardGroup == nil and lastTakeOutPos ~= self.friendPos_[1] then
                needTakeOutCardGroup = self:takeOutNormalCard(lastTakeOutCardGroup, whom, true)
            end
        else
            if againistCardCount == 1 then
                needTakeOutCardGroup = self:followTakeOutWhenAgainistOrFriendHasOnlyOneCard(lastTakeOutCardGroup, whom)
            else
                needTakeOutCardGroup = self:followTakeOutCardWhenLastFewHands(lastTakeOutCardGroup, whom, lastTakeOutPos)
                if log_util.isDebug() == true then
                    log_util.i(TAG, "lordPosNextFollowTakeOutCard IN needTakeOutCardGroup is ", needTakeOutCardGroup)
                end

                if needTakeOutCardGroup == nil then
                    needTakeOutCardGroup = self:doFollowTakeOutCard(lastTakeOutCardGroup, whom, false)
                    if log_util.isDebug() == true then
                        log_util.i(TAG, "lordPosNextFollowTakeOutCard IN lastTakeOutPos is ", lastTakeOutPos, " self.friendPos_[1] is ", self.friendPos_[1])
                    end

                    if lastTakeOutPos == self.friendPos_[1] then
                        if needTakeOutCardGroup and needTakeOutCardGroup.cardValue > cardValue_.CARD_POINT_K then
                            needTakeOutCardGroup = nil
                        end
                    end
                end
            end
        end
    end

    return needTakeOutCardGroup
end

--通用的跟出逻辑
function SingleGameAI:doFollowTakeOutCard(lastTakeOutCardGroup, whom, isSpecial, needToBiggerThan)
    local needTakeOutCardGroup = nil
    local _, cardGroup = self:getSomeOneCards(whom)
    if log_util.isDebug() == true then
        log_util.i(TAG, "doFollowTakeOutCard IN isSpecial is ", isSpecial)
    end

    needTakeOutCardGroup = self:takeOutNormalCard(lastTakeOutCardGroup, whom, isSpecial, needToBiggerThan)
    if needTakeOutCardGroup == nil then
        needTakeOutCardGroup = self:takeOutSpecialCard(lastTakeOutCardGroup, whom, isSpecial)
    end

    return needTakeOutCardGroup
end

--根据牌型常规出牌，不进行拆牌、组牌，单牌和对子只处理小于2的牌，2、小王、大王比较特殊，不在这里进行处理
function SingleGameAI:takeOutNormalCard(lastTakeOutCardGroup, whom, isSpecial, needToBiggerThan, isOnlyOneCard)
    local needTakeOutCardGroup = nil
    if lastTakeOutCardGroup then
        local lastTakeOutCardType = lastTakeOutCardGroup.cardType
        local lastTakeOutCardValue = lastTakeOutCardGroup.cardValue
        local lastTakeOutCardList = lastTakeOutCardGroup.cardList
        local firstCanTakeOutCard = nil
        if log_util.isDebug() == true then
            log_util.i(TAG, "takeOutNormalCard IN lastTakeOutCardType is ", lastTakeOutCardType, " lastTakeOutCardValue is ", lastTakeOutCardValue, " lastTakeOutCardList is ", lastTakeOutCardList, " isSpecial is ", isSpecial, " needToBiggerThan is ", needToBiggerThan)
        end

        if lastTakeOutCardType and lastTakeOutCardValue and lastTakeOutCardList then
            --单顺、双顺、三顺、三带这四个特殊牌型不能只按照牌型和牌值进行匹配，还需要进行长度、是否带单或对的判断，所以这里单独处理这几个牌型
            --这里只处理单牌、对子、三张
            local cardTypeGroupList = self:getCardGroupByType(lastTakeOutCardType, whom)
            if cardTypeGroupList then
                if lastTakeOutCardType == cardType_.SINGLE_CARD or lastTakeOutCardType == cardType_.DOUBLE_CARDS or lastTakeOutCardType == cardType_.THREE_CARDS then
                    if isSpecial then
                        for k,v in pairs(cardTypeGroupList) do
                            needTakeOutCardGroup = v
                            if needTakeOutCardGroup then
                                if needTakeOutCardGroup.cardValue > lastTakeOutCardValue then
                                    if firstCanTakeOutCard == nil then
                                        firstCanTakeOutCard = needTakeOutCardGroup
                                    end
                                end
                                if needTakeOutCardGroup.cardValue <= lastTakeOutCardValue or (needToBiggerThan and needTakeOutCardGroup.cardValue < needToBiggerThan) then
                                    needTakeOutCardGroup = nil
                                else
                                    -- 如果是大王的话，需要判断小王是否已经出过，如果小王没有出过则优先拆分其他牌，如果其他没有牌能大过，再出大王
                                    -- 判断一下2是否是最大牌即可

                                    if needTakeOutCardGroup.cardValue == self.cardValue_.CARD_POINT_BIG_JOKER then
                                        local smallJokerCardGroup = {}
                                        smallJokerCardGroup.cardList = {}
                                        smallJokerCardGroup.cardType = self.cardType_.SINGLE_CARD
                                        smallJokerCardGroup.cardValue = self.cardValue_.CARD_POINT_2
                                        table.insert(smallJokerCardGroup.cardList, 51)
                                        local isSmallJokerHasTakeOut = self:checkCardGroupIsBiggest(smallJokerCardGroup, whom)
                                        if log_util.isDebug() == true then
                                            log_util.i(TAG, "takeOutNormalCard IN isSmallJokerHasTakeOut is ", isSmallJokerHasTakeOut)
                                        end

                                        if isSmallJokerHasTakeOut then
                                            break
                                        else
                                            needTakeOutCardGroup = nil
                                        end
                                    elseif needTakeOutCardGroup.cardValue == self.cardValue_.CARD_POINT_LITTLE_JOKER then
                                        if lastTakeOutCardValue > self.cardValue_.CARD_POINT_K then
                                            break
                                        else
                                            needTakeOutCardGroup = nil 
                                        end
                                    else
                                        break
                                    end
                                end
                            end
                        end
                    else
                        for key, var in pairs(cardTypeGroupList) do
                            if var
                                and var.cardValue
                                and var.cardList
                                and (var.cardValue < cardValue_.CARD_POINT_2 or lastTakeOutCardValue > cardValue_.CARD_POINT_K or (lastTakeOutCardType == cardType_.SINGLE_CARD and #cardTypeGroupList == 1))
                                and var.cardValue > lastTakeOutCardValue then
                                needTakeOutCardGroup = var
                                if firstCanTakeOutCard == nil then
                                    firstCanTakeOutCard = var
                                end
                                if needToBiggerThan then
                                    if needTakeOutCardGroup.cardValue <= needToBiggerThan then
                                        needTakeOutCardGroup = nil
                                    else
                                        break
                                    end
                                else
                                    break
                                end
                            end
                        end
                        -- 如果没有牌大过needToBiggerThan，则出大过上手牌的牌
                        if not needTakeOutCardGroup then
                            needTakeOutCardGroup = firstCanTakeOutCard
                        end
                    end
                end
            end

            local getBiggestThenACardGroup = function ()
                if cardTypeGroupList then
                    for key, var in pairs(cardTypeGroupList) do
                        if var and var.cardValue and var.cardList and var.cardValue > lastTakeOutCardValue then
                            needTakeOutCardGroup = var
                            if needToBiggerThan then
                                if needTakeOutCardGroup.cardValue >= needToBiggerThan then
                                    if needTakeOutCardGroup.cardValue == self.cardValue_.CARD_POINT_BIG_JOKER then
                                        local smallJokerCardGroup = {}
                                        smallJokerCardGroup.cardList = {}
                                        smallJokerCardGroup.cardType = self.cardType_.SINGLE_CARD
                                        smallJokerCardGroup.cardValue = self.cardValue_.CARD_POINT_2
                                        table.insert(smallJokerCardGroup.cardList, 51)
                                        local isSmallJokerHasTakeOut = self:checkCardGroupIsBiggest(smallJokerCardGroup, whom)
                                        if log_util.isDebug() == true then
                                            log_util.i(TAG, "takeOutNormalCard IN isSmallJokerHasTakeOut is ", isSmallJokerHasTakeOut)
                                        end

                                        if isSmallJokerHasTakeOut or isOnlyOneCard then
                                            break
                                        else
                                            needTakeOutCardGroup = nil
                                        end
                                    else
                                        break
                                    end
                                else
                                    needTakeOutCardGroup = nil
                                end
                            end
                        end
                    end
                end
            end

            local removeTo = 0
            local remainingTo = 1

            local getCardGroupFromOtherCardGroup = function (otherCardType, selfCardType, toRemoveCount, valueNeedToBiggerThen, removeToOrRemainingTo)
                local otherCardGroupList = self:getCardGroupByType(otherCardType, whom)
                if otherCardGroupList then
                    for key, var in pairs(otherCardGroupList) do
                        if var and var.cardValue and var.cardList and var.cardValue > lastTakeOutCardValue and var.cardValue >= valueNeedToBiggerThen then
                            needTakeOutCardGroup = var
                            needTakeOutCardGroup.cardType = selfCardType
                            if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                                if removeToOrRemainingTo == 0 then
                                    for i = 1, toRemoveCount do
                                        table.remove(needTakeOutCardGroup.cardList, 1)
                                    end
                                else
                                    local i = 1
                                    while true do
                                        if #needTakeOutCardGroup.cardList == toRemoveCount then
                                            break
                                        end
                                        table.remove(needTakeOutCardGroup.cardList, 1)
                                    end
                                end
                            end

                            break
                        end
                    end
                end
            end

            local getSingleCardGroupFromStright = function (needToBiggerThan)
                local strightCardGroupList = self:getCardGroupByType(self.cardType_.SINGLE_DRAGON, whom)
                if strightCardGroupList then
                    for k,v in pairs(strightCardGroupList) do
                        if v then
                            if v.cardValue > lastTakeOutCardValue and #v.cardList > 5 and v.cardValue > needToBiggerThan then
                                needTakeOutCardGroup = {}
                                needTakeOutCardGroup.cardList = {}
                                needTakeOutCardGroup.cardType = self.cardType_.SINGLE_CARD
                                needTakeOutCardGroup.cardValue = v.cardValue
                                needTakeOutCardGroup.cardList[1] = v.cardList[#v.cardList]
                                break
                            end
                        end
                    end

                    -- 如果没有顺子可以拆，则判断是否有两个顺子可以合成一个顺子，拆出单牌来大，例如6,7,8,9,10和10,J,Q,K,A
                    if needTakeOutCardGroup == nil then
                        for i = 1, #strightCardGroupList do
                            local strightCardGroup = strightCardGroupList[i]
                            if strightCardGroup then
                                local lastCardValue = strightCardGroup.cardValue
                                for j = i + 1, #strightCardGroupList do
                                    local checkGroup = strightCardGroupList[j]
                                    if checkGroup and checkGroup.cardList then
                                        for k,v in pairs(checkGroup.cardList) do
                                            if lastCardValue == v.value and lastCardValue > lastTakeOutCardValue then
                                                if k <= 3 then
                                                    needTakeOutCardGroup = {}
                                                    needTakeOutCardGroup.cardList = {}
                                                    needTakeOutCardGroup.cardType = self.cardType_.SINGLE_CARD
                                                    needTakeOutCardGroup.cardValue = v.value
                                                    needTakeOutCardGroup.cardList[1] = v
                                                    break
                                                end
                                            end
                                        end
                                        if needTakeOutCardGroup then
                                            break
                                        end
                                    end
                                end
                                if needTakeOutCardGroup then
                                    break
                                end
                            end
                        end
                    end
                end
            end

            if needTakeOutCardGroup == nil and lastTakeOutCardValue >= cardValue_.CARD_POINT_K then
                isSpecial = true
            end

            if isOnlyOneCard and needToBiggerThan and needTakeOutCardGroup and needTakeOutCardGroup.cardValue < needToBiggerThan then
                needTakeOutCardGroup = nil                        
            end

            --如果needTakeOutCardGroup为nil，则表示没有匹配到合适的牌型，这里需要判断是否进行拆分处理
            if needTakeOutCardGroup == nil and isSpecial then

                if lastTakeOutCardType == cardType_.SINGLE_CARD then
                    if cardTypeGroupList then
                        for k,v in pairs(cardTypeGroupList) do
                            if v and v.cardValue < self.cardValue_.CARD_POINT_LITTLE_JOKER and v.cardValue > lastTakeOutCardValue then
                                if needToBiggerThan and v.cardValue >= needToBiggerThan then
                                    needTakeOutCardGroup = v
                                end
                            end
                        end
                    end

                    if needTakeOutCardGroup == nil then
                        if needToBiggerThan then
                            getSingleCardGroupFromStright(needToBiggerThan)
                        else
                            getSingleCardGroupFromStright(cardValue_.CARD_POINT_K)
                        end
                    end

                    if needTakeOutCardGroup == nil then
                        if needToBiggerThan then
                            getCardGroupFromOtherCardGroup(cardType_.DOUBLE_CARDS, cardType_.SINGLE_CARD, 1, needToBiggerThan, removeTo)
                        else
                            getCardGroupFromOtherCardGroup(cardType_.DOUBLE_CARDS, cardType_.SINGLE_CARD, 1, cardValue_.CARD_POINT_K, removeTo)
                        end
                    end


                    if needTakeOutCardGroup == nil then
                        if needToBiggerThan then
                            getCardGroupFromOtherCardGroup(cardType_.THREE_CARDS, cardType_.SINGLE_CARD, 2, needToBiggerThan, removeTo)
                        else
                            getCardGroupFromOtherCardGroup(cardType_.THREE_CARDS, cardType_.SINGLE_CARD, 2, cardValue_.CARD_POINT_K, removeTo)
                        end
                    end

                    if needTakeOutCardGroup == nil then
                        getBiggestThenACardGroup()
                    end

                    -- 如果没有可拆的牌，则可以拆分双王
                    if needTakeOutCardGroup == nil then
                        getCardGroupFromOtherCardGroup(cardType_.DOUBLE_JOKER, cardType_.SINGLE_CARD, 1, cardValue_.CARD_POINT_K, removeTo)
                    end

                    if needTakeOutCardGroup == nil then
                        needTakeOutCardGroup = self:getBiggestCardGroupFromCardType(_, whom)
                        if needTakeOutCardGroup and (needTakeOutCardGroup.cardType ~= lastTakeOutCardType or needTakeOutCardGroup.cardValue <= lastTakeOutCardValue) then
                            needTakeOutCardGroup = nil
                        end
                    end

                else
                    if lastTakeOutCardType == cardType_.DOUBLE_CARDS then
                        if log_util.isDebug() == true then
                            log_util.i(TAG, "takeOutNormalCard IN double cards needTakeOutCardGroup is ", needTakeOutCardGroup)
                        end

                        if needTakeOutCardGroup == nil then
                            if needToBiggerThan then
                                getCardGroupFromOtherCardGroup(cardType_.DOUBLE_DRAGON, cardType_.DOUBLE_CARDS, 2, needToBiggerThan, remainingTo)
                            else
                                getCardGroupFromOtherCardGroup(cardType_.DOUBLE_DRAGON, cardType_.DOUBLE_CARDS, 2, cardValue_.CARD_POINT_3, remainingTo)
                            end
                        end

                        if needTakeOutCardGroup == nil then
                            if needToBiggerThan then
                                getCardGroupFromOtherCardGroup(cardType_.THREE_CARDS, cardType_.DOUBLE_CARDS, 1, needToBiggerThan, removeTo)
                            else
                                getCardGroupFromOtherCardGroup(cardType_.THREE_CARDS, cardType_.DOUBLE_CARDS, 1, cardValue_.CARD_POINT_10, removeTo)
                            end
                        end

                        if needTakeOutCardGroup == nil then
                            if needToBiggerThan then
                                getCardGroupFromOtherCardGroup(cardType_.THREE_DRAGON, cardType_.DOUBLE_CARDS, 2, needToBiggerThan, remainingTo)
                            else
                                getCardGroupFromOtherCardGroup(cardType_.THREE_DRAGON, cardType_.DOUBLE_CARDS, 2, cardValue_.CARD_POINT_10, remainingTo)
                            end
                        end

                        if needTakeOutCardGroup == nil then
                            getBiggestThenACardGroup()
                        end
                    else
                        if lastTakeOutCardType == cardType_.THREE_CARDS then
                            getBiggestThenACardGroup()

                            if needTakeOutCardGroup == nil then
                                if needToBiggerThan then
                                    getCardGroupFromOtherCardGroup(cardType_.THREE_DRAGON, cardType_.THREE_CARDS, 3, needToBiggerThan, remainingTo)
                                else
                                    getCardGroupFromOtherCardGroup(cardType_.THREE_DRAGON, cardType_.THREE_CARDS, 3, cardValue_.CARD_POINT_3, remainingTo)
                                end
                            end
                        end
                    end
                end
            end
            if needTakeOutCardGroup == nil or (needTakeOutCardGroup.cardValue >= cardValue_.CARD_POINT_2 and firstCanTakeOutCard) then
                needTakeOutCardGroup = firstCanTakeOutCard
            end
        end
    end

    return needTakeOutCardGroup
end

--处理非单牌、对子、三张的特殊牌型，这些牌型都是不能仅仅根据牌型与牌值来匹配的，还需要进行长度或者是否带牌等特殊情况的判断
function SingleGameAI:takeOutSpecialCard(lastTakeOutCardGroup, whom, isSpecial)
    local needTakeOutCardGroup = nil
    if lastTakeOutCardGroup then
        local lastTakeOutCardType = lastTakeOutCardGroup.cardType
        local translateCardType = -1;
        if lastTakeOutCardType then
            if lastTakeOutCardType == cardType_.THREE_ONE_DRAGON or lastTakeOutCardType == cardType_.THREE_TWO_DRAGON then
                translateCardType = cardType_.THREE_DRAGON
            elseif lastTakeOutCardType == cardType_.THREE_WITH_ONE or lastTakeOutCardType == cardType_.THREE_WITH_TWO then
                translateCardType = cardType_.THREE_CARDS
            else
                translateCardType = lastTakeOutCardType
            end
            local cardTypeGroupList = self:getCardGroupByType(translateCardType, whom)
            if lastTakeOutCardType == cardType_.SINGLE_DRAGON or lastTakeOutCardType == cardType_.DOUBLE_DRAGON or lastTakeOutCardType == cardType_.THREE_DRAGON then
                needTakeOutCardGroup = self:getTakeOutStright(lastTakeOutCardGroup, cardTypeGroupList, isSpecial)
            elseif lastTakeOutCardType == cardType_.THREE_WITH_ONE or lastTakeOutCardType == cardType_.THREE_WITH_TWO then
                needTakeOutCardGroup = self:getTakeOutThreeWithCard(lastTakeOutCardGroup, cardTypeGroupList, isSpecial)
            elseif lastTakeOutCardType == cardType_.THREE_ONE_DRAGON or lastTakeOutCardType == cardType_.THREE_TWO_DRAGON then
                needTakeOutCardGroup = self:getTakeOutThreeStrightWidthCard(lastTakeOutCardGroup, cardTypeGroupList, isSpecial)
            end
        end
    end

    return needTakeOutCardGroup
end

--根据上手单顺来获取要出的单顺，如果手牌里没有与需要大过的单顺张数相同的顺子，则需要将手牌里的顺子进行拆分
--双顺与不带牌的三顺的处理逻辑基本与单顺相同，只不过双顺（三顺）拆分出来的是对子（三张），所以不需要考虑拆分出来的单牌多少的问题
--正常情况我们只处理拆分后单牌数不大于2张的顺子，特殊情况下（敌家只剩一手牌时、友家只剩一手牌时，根据参数isSpecial来判断是否是特殊情况）将进行拆分

function SingleGameAI:getTakeOutStright(lastTakeOutCardGroup, cardTypeGroupList, isSpecial)
    local needTakeOutCardGroup = nil
    local lastTakeOutCardValue = lastTakeOutCardGroup.cardValue
    local lastTakeOutCardList = lastTakeOutCardGroup.cardList
    local lastTakeOutCardType = lastTakeOutCardGroup.cardType
    local lastTakeOutCardLength = #lastTakeOutCardList
    if lastTakeOutCardValue and lastTakeOutCardList and cardTypeGroupList then
        --先处理顺子长度匹配的情况
        for key, dragonGroup in pairs(cardTypeGroupList) do
            if dragonGroup and dragonGroup.cardList and dragonGroup.cardValue then
                if lastTakeOutCardLength == #dragonGroup.cardList and dragonGroup.cardValue > lastTakeOutCardValue then
                    needTakeOutCardGroup = dragonGroup
                    return needTakeOutCardGroup
                end
            end
        end

        --顺子长度不匹配时
        for key, dragonGroup in pairs(cardTypeGroupList) do
            if dragonGroup and dragonGroup.cardList and dragonGroup.cardValue then
                if lastTakeOutCardLength < #dragonGroup.cardList and dragonGroup.cardValue > lastTakeOutCardValue then
                    local getStrightGroup = function ()
                        while #dragonGroup.cardList > lastTakeOutCardLength do
                            table.remove(dragonGroup.cardList, 1)
                            if #dragonGroup.cardList == lastTakeOutCardLength then
                                break
                            end
                        end
                        return dragonGroup
                    end
                    if isSpecial or lastTakeOutCardType == cardType_.DOUBLE_DRAGON or lastTakeOutCardType == cardType_.THREE_DRAGON then
                        needTakeOutCardGroup = getStrightGroup()
                        return needTakeOutCardGroup
                    else
                        if #dragonGroup.cardList - lastTakeOutCardLength < 3 or #dragonGroup.cardList - lastTakeOutCardLength > 4 then
                            needTakeOutCardGroup = getStrightGroup()
                            return needTakeOutCardGroup
                        end
                    end
                end
            end
        end
    end
    return needTakeOutCardGroup
end

--处理三顺带牌的情况，如果手牌中的单牌或对子不够带时，需要从其他牌型中拆分
function SingleGameAI:getTakeOutThreeStrightWidthCard(lastTakeOutCardGroup, cardTypeGroupList, isSpecial)
    local needTakeOutCardGroup = nil
    local lastTakeOutCardValue = lastTakeOutCardGroup.cardValue
    local lastTakeOutCardList = lastTakeOutCardGroup.cardList
    local lastTakeOutCardType = lastTakeOutCardGroup.cardType
    local lastTakeOutCardLength = #lastTakeOutCardList
    if lastTakeOutCardValue and lastTakeOutCardList and cardTypeGroupList then
        table.sort(cardTypeGroupList, sortCardGroup)
        local dragonLength = 0
        local singleLength = 0
        if lastTakeOutCardType == cardType_.THREE_ONE_DRAGON then
            --三顺带单有三种情况：8张牌、12张牌、16张牌，分别是三顺6张+单牌2张、三顺9张+单牌3张、三顺12张+单牌4张
            if lastTakeOutCardLength == 8 then
                dragonLength = 6
                singleLength = 2
            elseif lastTakeOutCardLength == 12 then
                dragonLength = 9
                singleLength = 3
            elseif lastTakeOutCardLength == 16 then
                dragonLength = 12
                singleLength = 4
            end
        elseif lastTakeOutCardType == cardType_.THREE_TWO_DRAGON then
            --三顺带对有两种情况：10张牌、15张牌，分别是三顺6张+对子4张、三顺9张+对子6张，剩下一种情况只有在地主一手出完的情况才会出现，这里不考虑这种情况
            if lastTakeOutCardLength == 10 then
                dragonLength = 6
                singleLength = 4
            elseif lastTakeOutCardLength == 15 then
                dragonLength = 9
                singleLength = 6
            end
        end

        --保存三顺中多余的牌张
        local splitThreeDragonCards = {}

        local hasThreeDragon = false
        --先将三顺的牌提取出来，再提取带的牌
        for key, dragonGroup in pairs(cardTypeGroupList) do
            if dragonGroup and dragonGroup.cardList and dragonGroup.cardValue then
                if dragonLength <= #dragonGroup.cardList and dragonGroup.cardValue > lastTakeOutCardValue then
                    while #dragonGroup.cardList > dragonLength do
                        table.insert(splitThreeDragonCards, dragonGroup.cardList[1])
                        table.remove(dragonGroup.cardList, 1)
                        if #dragonGroup.cardList == dragonLength then
                            break
                        end
                    end
                    needTakeOutCardGroup = dragonGroup
                    hasThreeDragon = true
                end
            end
        end

        if hasThreeDragon then
            --获取小于2的牌张数
            local getCardCountLessThen2 = function (groupList)
                local count = 0
                if groupList then
                    for key, var in pairs(groupList) do
                        if var and var.cardValue then
                            if var.cardValue < cardValue_.CARD_POINT_2 then
                                count = count + 1
                            end
                        end
                    end
                end
                return count
            end

            --组合需要带的牌
            local singleCardList = self:getCardGroupByType(cardType_.SINGLE_CARD, self.currentPos_)
            local doubleCardList = self:getCardGroupByType(cardType_.DOUBLE_CARDS, self.currentPos_)
            local threeCardList = self:getCardGroupByType(cardType_.THREE_CARDS, self.currentPos_)
            local singleDragonCardList = self:getCardGroupByType(cardType_.SINGLE_DRAGON, self.currentPos_)
            local doubleDragonCardList = self:getCardGroupByType(cardType_.DOUBLE_DRAGON, self.currentPos_)
            local threeDragonCardList = self:getCardGroupByType(cardType_.THREE_DRAGON, self.currentPos_)

            if singleCardList then
                table.sort(singleCardList, sortCardGroup)
            end
            if doubleCardList then
                table.sort(doubleCardList, sortCardGroup)
            end
            if threeCardList then
                table.sort(threeCardList, sortCardGroup)
            end

            --需要的带的牌从上面这些牌组中组合，拆分优先级依次为：单牌>对子>三张>单顺>双顺>三顺
            --带单的情况可以从上面所有的列表中进行组合，带对的情况则只能从对子、双顺、三顺中组合

            local canSplitSingleDragonCount = 0
            if singleDragonCardList then
                for key, var in pairs(singleDragonCardList) do
                    if var and var.cardList then
                        if #var.cardList > 5 then
                            canSplitSingleDragonCount = canSplitSingleDragonCount + #var.cardList - 5
                        end
                    end
                end
            end

            --三顺列表中需要去除掉当前正在使用的三顺
            if threeDragonCardList then
                for i = 1, #threeDragonCardList do
                    if threeDragonCardList[i] and threeDragonCardList[i].cardValue then
                        if needTakeOutCardGroup and needTakeOutCardGroup.cardValue then
                            if needTakeOutCardGroup.cardValue == threeDragonCardList[i].cardValue then
                                table.remove(threeDragonCardList, i)
                                break
                            end
                        end
                    end
                end
            end

            if lastTakeOutCardType == cardType_.THREE_ONE_DRAGON then
                local singleCardCountLessThen2 = getCardCountLessThen2(singleCardList)
                local doubleCardCountLessThen2 = getCardCountLessThen2(doubleCardList) * 2
                local threeCardCountLessThen2 = getCardCountLessThen2(threeCardList) * 3

                --添加单牌到三顺牌组
                local addSingleCard = function ()
                    for i = 1, singleCardCountLessThen2 do
                        if singleCardList and singleCardList[i] and singleCardList[i].cardList and singleCardList[i].cardList[1] then
                            table.insert(needTakeOutCardGroup.cardList, 1, singleCardList[i].cardList[1])
                        end
                    end
                    needTakeOutCardGroup.cardType = cardType_.THREE_ONE_DRAGON
                end

                --添加拆分对子的单牌到三顺牌组
                local addDoubleCard = function ()
                    for i = 1, doubleCardCountLessThen2 / 2 do
                        if doubleCardList and doubleCardList[i] and doubleCardList[i].cardList then
                            for key, var in pairs(doubleCardList[i].cardList) do
                                if var then
                                    table.insert(needTakeOutCardGroup.cardList, 1, var)
                                end
                            end
                        end
                    end
                    needTakeOutCardGroup.cardType = cardType_.THREE_ONE_DRAGON
                end

                --添加拆分三张的单牌到三顺牌组
                local addThreeCard = function ()
                    for i = 1, threeCardCountLessThen2 / 3 do
                        if threeCardList and threeCardList[i] and threeCardList[i].cardList then
                            for key, var in pairs(threeCardList[i].cardList) do
                                if var then
                                    table.insert(needTakeOutCardGroup.cardList, 1, var)
                                end
                            end
                        end
                    end
                    needTakeOutCardGroup.cardType = cardType_.THREE_ONE_DRAGON
                end

                --添加拆分单顺的单牌到三顺牌组
                local addSingleDragonCard = function ()
                    if singleDragonCardList then
                        for key, var in pairs(singleDragonCardList) do
                            if var and var.cardList then
                                if #var.cardList > 5 then
                                    local i = 1
                                    while i <= #var.cardList - 5 do
                                        table.insert(needTakeOutCardGroup.cardList, 1, var.cardList[i])
                                        i = i + 1
                                    end
                                end
                            end
                        end
                        needTakeOutCardGroup.cardType = cardType_.THREE_ONE_DRAGON
                    end
                end

                if singleCardCountLessThen2 >= singleLength then
                    --单牌数足够时，将单牌添加进三顺列表
                    if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                        for i = 1, singleLength do
                            if singleCardList and singleCardList[i] and singleCardList[i].cardList and singleCardList[i].cardList[1] then
                                table.insert(needTakeOutCardGroup.cardList, 1, singleCardList[i].cardList[1])
                            end
                        end
                        needTakeOutCardGroup.cardType = cardType_.THREE_ONE_DRAGON
                    end
                else
                    --单牌数不够时，需要借用对子，如果单牌数加对子数够带时
                    if singleCardCountLessThen2 + doubleCardCountLessThen2 >= singleLength then
                        if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                            --先将单牌添加到出牌牌组中
                            addSingleCard()

                            --获取还差的单牌数
                            local needCardCount = singleLength - singleCardCountLessThen2
                            local length = math.modf(needCardCount / 2)

                            --判断所缺少的单牌个数是单数还是双数，如果是双数则直接取对子即可，否则最后需要取对子里的一张单牌
                            if needCardCount % 2 == 0 then
                                for i = 1, length do
                                    if doubleCardList and doubleCardList[i] and doubleCardList[i].cardList then
                                        for key, var in pairs(doubleCardList[i].cardList) do
                                            if var then
                                                table.insert(needTakeOutCardGroup.cardList, 1, var)
                                            end
                                        end
                                    end
                                end
                            else
                                if length == 0 then
                                    if doubleCardList and doubleCardList[1] and doubleCardList[1].cardList and doubleCardList[1].cardList[1] then
                                        table.insert(needTakeOutCardGroup.cardList, 1, doubleCardList[1].cardList[1])
                                    end
                                else
                                    for i = 1, length do
                                        if doubleCardList and doubleCardList[i] and doubleCardList[i].cardList then
                                            for key, var in pairs(doubleCardList[i].cardList) do
                                                if var then
                                                    table.insert(needTakeOutCardGroup.cardList, 1, var)
                                                end
                                            end
                                        end
                                        if i == length then
                                            if doubleCardList and doubleCardList[i+1] and doubleCardList[i+1].cardList and doubleCardList[i+1].cardList[1] then
                                                table.insert(needTakeOutCardGroup.cardList, 1, doubleCardList[i+1].cardList[1])
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    else
                        --单牌与对子都不够带时，需要借用三张
                        if singleCardCountLessThen2 + doubleCardCountLessThen2 + threeCardCountLessThen2 >= singleLength then
                            if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                                --先将单牌添加到出牌牌组中
                                addSingleCard()

                                --再将对子添加进出牌牌组中
                                addDoubleCard()

                                --获取还差的单牌数
                                local needCardCount = singleLength - singleCardCountLessThen2 - doubleCardCountLessThen2
                                local length = math.modf(needCardCount / 3)

                                --判断所缺少的单牌个数是否能被3正处，如果可以则直接添加三张，否则需要拆分三张
                                if needCardCount % 3 == 0 then
                                    for i = 1, length do
                                        if threeCardList and threeCardList[i] and threeCardList[i].cardList then
                                            for key, var in pairs(threeCardList[i].cardList) do
                                                if var then
                                                    table.insert(needTakeOutCardGroup.cardList, 1, var)
                                                end
                                            end
                                        end
                                    end
                                else
                                    if length == 0 then
                                        --length为0表示剩余的单牌牌不到三张
                                        if threeCardList and threeCardList[1] and threeCardList[1].cardList then
                                            for i = 1, needCardCount do
                                                if threeCardList[1].cardList[i] then
                                                    table.insert(needTakeOutCardGroup.cardList, 1, threeCardList[1].cardList[i])
                                                end
                                            end
                                        end
                                    else
                                        for i = 1, length do
                                            if threeCardList and threeCardList[i] and threeCardList[i].cardList then
                                                for key, var in pairs(threeCardList[i].cardList) do
                                                    if var then
                                                        table.insert(needTakeOutCardGroup.cardList, 1, var)
                                                    end
                                                end
                                            end
                                            if i == length then
                                                if threeCardList[i+1] and threeCardList[i+1].cardList then
                                                    for j = 1, needCardCount % 3 do
                                                        if threeCardList[i+1].cardList[j] then
                                                            table.insert(needTakeOutCardGroup.cardList, 1, threeCardList[i+1].cardList[j])
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            --单牌、对子、三张都不够带时，需要判断是否可以从顺子中拆分出单牌
                            if singleCardCountLessThen2 + doubleCardCountLessThen2 + threeCardCountLessThen2 + canSplitSingleDragonCount >= singleLength then
                                if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                                    --先将单牌添加到出牌牌组中
                                    addSingleCard()

                                    --再将对子添加进出牌牌组中
                                    addDoubleCard()

                                    --再将三张添加进牌组中
                                    addThreeCard()

                                    --将单顺拆分出的单牌添加进牌组中
                                    local needCardCount = singleLength - (singleCardCountLessThen2 + doubleCardCountLessThen2 + threeCardCountLessThen2)
                                    for key, var in pairs(singleDragonCardList) do
                                        if var and var.cardList then
                                            if #var.cardList > 5 then
                                                if #var.cardList - 5 >= needCardCount then
                                                    local i = 1
                                                    while i <= needCardCount do
                                                        table.insert(needTakeOutCardGroup.cardList, 1, var.cardList[i])
                                                        i = i + 1
                                                    end
                                                    needCardCount = 0
                                                    break
                                                else
                                                    local i = 1
                                                    while i <= #var.cardList - 5 do
                                                        table.insert(needTakeOutCardGroup.cardList, 1, var.cardList[i])
                                                        i = i + 1
                                                    end
                                                    needCardCount = needCardCount - (#var.cardList - 5)
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                --如果是特殊情况，比如友家剩余一手牌、敌家剩余一手牌时，才选择从双顺或者三顺中拆分单牌
                                if isSpecial then
                                    local addSingleCardsHasSplit = function (dragonGroupList)
                                        local needCardCount = singleLength - (singleCardCountLessThen2 + doubleCardCountLessThen2 + threeCardCountLessThen2 + canSplitSingleDragonCount)
                                        local dragonGroup = dragonGroupList[1]
                                        if dragonGroup and dragonGroup.cardList then
                                            --先将单牌添加到出牌牌组中
                                            addSingleCard()

                                            --再将对子添加进出牌牌组中
                                            addDoubleCard()

                                            --再将三张添加进牌组中
                                            addThreeCard()

                                            --将单顺拆分出的单牌添加进牌组中
                                            addSingleDragonCard()

                                            for i = 1, needCardCount do
                                                table.insert(needTakeOutCardGroup.cardList, 1, dragonGroup.cardList[i])
                                            end
                                        end
                                    end
                                    if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                                        --如果单牌、对子、三张、单顺都不够带时，需要判断是否能够从双顺中拆分出单牌
                                        if doubleDragonCardList and #doubleDragonCardList > 0 then
                                            addSingleCardsHasSplit(doubleDragonCardList)
                                        else
                                            --如果单牌、对子、三张、单顺、双顺都不够带时，需要判断是否能够从三顺中拆分出单牌
                                            if threeDragonCardList and #threeDragonCardList > 0 then
                                                addSingleCardsHasSplit(threeDragonCardList)
                                            else
                                                --从之前三顺中拆出的多余的牌张中寻找（前提是手牌中的三顺长度要比已出的三顺长度长）
                                                if splitThreeDragonCards and #splitThreeDragonCards > 0 then
                                                    local needCardCount = singleLength - (singleCardCountLessThen2 + doubleCardCountLessThen2 + threeCardCountLessThen2 + canSplitSingleDragonCount)
                                                    if #splitThreeDragonCards >= needCardCount then
                                                        for i = 1, needCardCount do
                                                            table.insert(needTakeOutCardGroup.cardList, 1, splitThreeDragonCards[i])
                                                        end
                                                    end
                                                else
                                                    --能走到这里的话就证明所有能拆分的牌组都不够带的牌张，剩余的只是2的单张、对子、三张、小王、大王，这些牌除非是极端的情况下会带出去，否则不会考虑带这些牌
                                                    local needCardCount = singleLength - (singleCardCountLessThen2 + doubleCardCountLessThen2 + threeCardCountLessThen2 + canSplitSingleDragonCount)
                                                    local biggerThen2CardsList = {}
                                                    local cards, cardGroup = self:getSomeOneCards(self.currentPos_)
                                                    if cardGroup then
                                                        for key, var in pairs(cardGroup) do
                                                            if var and var.cardValue and var.cardList and var.cardValue >= cardValue_.CARD_POINT_2 then
                                                                for k, v in pairs(var.cardList) do
                                                                    table.insert(biggerThen2CardsList, v)
                                                                end
                                                            end
                                                        end
                                                        if #biggerThen2CardsList >= needCardCount then
                                                            for i = 1, needCardCount do
                                                                table.insert(needTakeOutCardGroup.cardList, 1, biggerThen2CardsList[i])
                                                            end
                                                            needTakeOutCardGroup.cardType = cardType_.THREE_ONE_DRAGON
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            elseif lastTakeOutCardType == cardType_.THREE_TWO_DRAGON then
                local doubleCardCountLessThen2 = getCardCountLessThen2(doubleCardList)
                local threeCardCountLessThen2 = getCardCountLessThen2(threeCardList)

                --添加带的对子到三顺牌组
                local addDoubleCard = function ()
                    for i = 1, doubleCardCountLessThen2 do
                        if threeCardList and threeCardList[i] and threeCardList[i].cardList then
                            for key, var in pairs(doubleCardList[i].cardList) do
                                if var then
                                    table.insert(needTakeOutCardGroup.cardList, 1, var)
                                end
                            end
                        end
                    end
                    needTakeOutCardGroup.cardType = cardType_.THREE_TWO_DRAGON
                end

                --添加拆分三张得到的对子到三顺牌组
                local addDoubleCardInThreeCards = function ()
                    for i = 1, threeCardCountLessThen2 do
                        if threeCardList and threeCardList[i] and threeCardList[i].cardList then
                            for j = 1, 2 do
                                if threeCardList[i].cardList[j] then
                                    table.insert(needTakeOutCardGroup.cardList, 1, threeCardList[i].cardList[j])
                                end
                            end
                        end
                    end
                    needTakeOutCardGroup.cardType = cardType_.THREE_TWO_DRAGON
                end

                if doubleCardCountLessThen2 * 2 >= singleLength then
                    for i = 1, singleLength / 2 do
                        if doubleCardList and doubleCardList[i] and doubleCardList[i].cardList then
                            for key, var in pairs(doubleCardList[i].cardList) do
                                if var then
                                    table.insert(needTakeOutCardGroup.cardList, 1, var)
                                end
                            end
                        end
                    end
                    needTakeOutCardGroup.cardType = cardType_.THREE_TWO_DRAGON
                else
                    if doubleCardCountLessThen2 * 2 + threeCardCountLessThen2 * 2 >= singleLength then
                        if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                            --先将对子添加进牌组
                            addDoubleCard()

                            local needCardCount = singleLength - doubleCardCountLessThen2 * 2

                            for i = 1, needCardCount / 2 do
                                if threeCardList and threeCardList[i] and threeCardList[i].cardList then
                                    for j = 1, 2 do
                                        if threeCardList[i].cardList[j] then
                                            table.insert(needTakeOutCardGroup.cardList, 1, threeCardList[i].cardList[j])
                                        end
                                    end
                                end
                            end
                        end
                    else
                        local doubleCardsCount = 0;
                        if doubleDragonCardList then
                            for key, var in pairs(doubleDragonCardList) do
                                if var and var.cardList then
                                    doubleCardsCount = doubleCardsCount + #var.cardList / 2
                                end
                            end
                        end

                        if doubleCardCountLessThen2 * 2 + threeCardCountLessThen2 * 2 + doubleCardsCount * 2 >= singleLength then
                            if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                                --将对子添加进牌组
                                addDoubleCard()

                                --将从三张中拆分出的对子添加进牌组
                                addDoubleCardInThreeCards()

                                local needCardCount = singleLength - doubleCardCountLessThen2 * 2 - threeCardCountLessThen2 * 2

                                --这里只需要从一个双顺中就可以拆分出足够的对子来带，如果一个双顺不够带的话，则整体手牌数就会大于20张的最大数目
                                if doubleDragonCardList[1] and doubleDragonCardList[1].cardList then
                                    if #doubleDragonCardList[1].cardList >= needCardCount then
                                        for i = 1, needCardCount do
                                            if doubleDragonCardList[1].cardList[i] then
                                                table.insert(needTakeOutCardGroup.cardList, 1, doubleDragonCardList[1].cardList[i])
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            --而且这里只需要一组三顺就可以组合够需要带的对子，同样可以判断出如果一组三顺还不够带的话整体手牌数也会大于20张
                            if threeDragonCardList and #threeDragonCardList > 0 then
                                if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                                    --将对子添加进牌组
                                    addDoubleCard()

                                    --将从三张中拆分出的对子添加进牌组
                                    addDoubleCardInThreeCards()

                                    --能够走到这里，可以判断出双顺肯定是没有的，如果有双顺的话整个手牌数已经大于20张的最大张数了，所以这里不用添加双顺中的对子

                                    local needCardCount = singleLength - doubleCardCountLessThen2 * 2 - threeCardCountLessThen2 * 2

                                    if threeDragonCardList[1] and threeDragonCardList[1].cardList then
                                        local i = 1
                                        local j = 1
                                        while i <= needCardCount / 2 do
                                            if threeDragonCardList[1].cardList[j] and threeDragonCardList[1].cardList[j + 1] then
                                                table.insert(needTakeOutCardGroup.cardList, 1, threeDragonCardList[1].cardList[j])
                                                table.insert(needTakeOutCardGroup.cardList, 1, threeDragonCardList[1].cardList[j + 1])
                                                j = j + 3
                                            end
                                            i = i + 1
                                        end
                                    end
                                end
                            else
                                --能走到这里表示只剩余对2可以用来带了，这种情况只有在isSpecial为true时出现
                                --特殊情况，比如友家剩余一手牌、敌家剩余一手牌时，才选择从双顺或者三顺中拆分单牌
                                if isSpecial then
                                    if needTakeOutCardGroup and needTakeOutCardGroup.cardList then
                                        --这里可以判断出双顺可三顺肯定是没有的，因为双顺或者三顺只要有一个就已经可以组够需要带的对子
                                        --而对2或者三张2只有一组，所以这里如果需要带的对子大于2对则无法组合
                                        if singleLength - doubleCardCountLessThen2 * 2 - threeCardCountLessThen2 * 2 <= 1 then
                                            local hasDouble2 = false

                                            local getCardFromCardList = function (cardList)
                                                for key, var in pairs(cardList) do
                                                    if var and var.cardList and var.cardValue == cardValue_.CARD_POINT_2 then
                                                        if var.cardList[1] and var.cardList[2] then
                                                            table.insert(needTakeOutCardGroup.cardList, 1, var.cardList[1])
                                                            table.insert(needTakeOutCardGroup.cardList, 1, var.cardList[2])
                                                            hasDouble2 = true
                                                            needTakeOutCardGroup.cardType = cardType_.THREE_TWO_DRAGON
                                                        end
                                                    end
                                                end
                                            end

                                            getCardFromCardList(doubleCardList)

                                            if hasDouble2 == false then
                                                getCardFromCardList(threeCardList)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    --判断是否已经组成了与上手牌相匹配的牌
    if needTakeOutCardGroup and needTakeOutCardGroup.cardList and #needTakeOutCardGroup.cardList == lastTakeOutCardLength then
        needTakeOutCardGroup.cardType = lastTakeOutCardType
    else
        needTakeOutCardGroup = nil
    end
    return needTakeOutCardGroup
end

--处理三张带牌的情况，如果手牌中的单牌或对子不够带时，需要从其他牌型中拆分
function SingleGameAI:getTakeOutThreeWithCard(lastTakeOutCardGroup, cardTypeGroupList, isSpecial)
    local needTakeOutCardGroup = nil

    if log_util.isDebug() == true then
        log_util.i(TAG, "getTakeOutThreeWithCard IN cardTypeGroupList is ", cardTypeGroupList)
    end

    if cardTypeGroupList then
        table.sort(cardTypeGroupList, sortCardGroup)
    end
    local lastTakeOutCardValue = lastTakeOutCardGroup.cardValue
    local lastTakeOutCardList = lastTakeOutCardGroup.cardList
    local lastTakeOutCardType = lastTakeOutCardGroup.cardType
    local lastTakeOutCardLength = #lastTakeOutCardGroup.cardList
    if log_util.isDebug() == true then
        log_util.i(TAG, "getTakeOutThreeWithCard IN lastTakeOutCardValue is ", lastTakeOutCardValue, " lastTakeOutCardList is ", lastTakeOutCardList)
    end

    if lastTakeOutCardValue and lastTakeOutCardList then
        local singleCardList = self:getCardGroupByType(cardType_.SINGLE_CARD, self.currentPos_)
        local singleDragonCardList = self:getCardGroupByType(cardType_.SINGLE_DRAGON, self.currentPos_)
        local doubleCardList = self:getCardGroupByType(cardType_.DOUBLE_CARDS, self.currentPos_)
        local doubleDragonCardList = self:getCardGroupByType(cardType_.DOUBLE_DRAGON, self.currentPos_)
        local threeCardList = self:getCardGroupByType(cardType_.THREE_CARDS, self.currentPos_)
        local threeDragonCardList = self:getCardGroupByType(cardType_.THREE_DRAGON, self.currentPos_)

        --根据牌型来获取该牌型下牌值比2小的牌数量
        local getLessThen2CardCount = function (cardType)
            local cardGroupList = self:getCardGroupByType(cardType, self.currentPos_)
            local lessThen2CardCount = 0
            if cardGroupList then
                for key, var in pairs(cardGroupList) do
                    if var and var.cardValue and var.cardValue < cardValue_.CARD_POINT_2 then
                        lessThen2CardCount = lessThen2CardCount + 1
                    end
                end
            end
            return lessThen2CardCount
        end

        local singleCardLessThen2Count = getLessThen2CardCount(cardType_.SINGLE_CARD)
        local doubleCardLessThen2Count = getLessThen2CardCount(cardType_.DOUBLE_CARDS)
        local threeCardLessThen2Count = getLessThen2CardCount(cardType_.THREE_CARDS)
        local singleDragonLengthBiggerThen5Count = 0

        if singleDragonCardList then
            for key, var in pairs(singleDragonCardList) do
                if var and var.cardList and #var.cardList > 5 then
                    singleDragonLengthBiggerThen5Count = singleDragonLengthBiggerThen5Count + 1
                end
            end
        end

        local hasThreeCard = false
        --先把三张的牌组取出来
        if cardTypeGroupList then
            for key, var in pairs(cardTypeGroupList) do
                if var and var.cardValue and var.cardList then
                    if var.cardValue > lastTakeOutCardValue and var.cardValue < cardValue_.CARD_POINT_2 then
                        needTakeOutCardGroup = var
                        hasThreeCard = true
                        break
                    end
                end
            end
        end

        --如果没有三张的牌组，则从三顺中拆取出一个三张
        if hasThreeCard == false then
            if threeDragonCardList then
                for key, var in pairs(threeDragonCardList) do
                    if var and var.cardValue and var.cardList and var.cardValue > lastTakeOutCardValue then
                        local i = 1
                        while var.cardList[i] do
                            if var.cardList[i].value > lastTakeOutCardValue then
                                needTakeOutCardGroup = {}
                                needTakeOutCardGroup.cardType = cardType_.THREE_CARDS
                                needTakeOutCardGroup.cardValue = var.cardList[i].value
                                needTakeOutCardGroup.cardList = {}
                                if var.cardList[i] and var.cardList[i + 1] and var.cardList[i + 2] then
                                    table.insert(needTakeOutCardGroup.cardList, var.cardList[i])
                                    table.insert(needTakeOutCardGroup.cardList, var.cardList[i + 1])
                                    table.insert(needTakeOutCardGroup.cardList, var.cardList[i + 2])
                                    table.remove(var.cardList, i)
                                    table.remove(var.cardList, i)
                                    table.remove(var.cardList, i)
                                end
                                hasThreeCard = true
                                break
                            else
                                i = i + 3
                            end
                        end

                    end
                end
            end
        end

        --从三张牌组列表中删除已待出的三张牌组
        if threeCardList then
            for i = 1, #threeCardList do
                if threeCardList[i] and threeCardList[i].cardValue and needTakeOutCardGroup and needTakeOutCardGroup.cardValue and needTakeOutCardGroup.cardValue == threeCardList[i].cardValue then
                    table.remove(threeCardList, i)
                    break
                end
            end
        end

        --检查是否有对子可以和单顺中的某张牌组成三张
        local checkHasDoubleCardMarginToSingleDragon = function ()
            local canMarginDoubleCardToSingleDragon = false
            if doubleCardList and singleDragonCardList then
                for key, var in pairs(doubleCardList) do
                    if var and var.cardValue and var.cardValue > lastTakeOutCardValue and var.cardValue < cardValue_.CARD_POINT_2 then
                        for k, v in pairs(singleDragonCardList) do
                            if v and v.cardList then
                                for i = 1, #v.cardList do
                                    if v.cardList[i] and var.cardValue == v.cardList[i].value then
                                        --拆分单顺的原则：拆分后剩余的单牌不多于2张，或者是特殊情况
                                        if (#v.cardList - i > 4 and (i < 4 or i > 5)) or ((#v.cardList - i < 4 or #v.cardList - i > 5) and i > 5) or isSpecial then
                                            needTakeOutCardGroup = {}
                                            needTakeOutCardGroup.cardType = cardType_.THREE_CARDS
                                            needTakeOutCardGroup.cardValue = var.cardValue
                                            needTakeOutCardGroup.cardList = {}
                                            table.insert(needTakeOutCardGroup.cardList, var.cardList[1])
                                            table.insert(needTakeOutCardGroup.cardList, var.cardList[2])
                                            table.insert(needTakeOutCardGroup.cardList, v.cardList[i])
                                            canMarginDoubleCardToSingleDragon = true
                                            break
                                        end
                                    end
                                end
                                if canMarginDoubleCardToSingleDragon then
                                    break
                                end
                            end
                        end
                        if canMarginDoubleCardToSingleDragon then
                            break
                        end
                    end
                end

                --从对子牌组列表中删除已经组成三张的对子
                if canMarginDoubleCardToSingleDragon then
                    doubleCardLessThen2Count = doubleCardLessThen2Count - 1
                    local i = 1
                    while doubleCardList[i] do
                        if doubleCardList[i] and doubleCardList[i].cardValue and needTakeOutCardGroup.cardValue and doubleCardList[i].cardValue == needTakeOutCardGroup.cardValue then
                            table.remove(doubleCardList, i)
                        else
                            i = i + 1
                        end
                    end
                end
            end
            return canMarginDoubleCardToSingleDragon
        end

        --检查是否有单牌可以和双顺中的某个对子组成三张
        local checkHasSingleCardMarginToDoubleDragon = function ()
            local canMarginSingleCardToDoubleDragon = false
            if singleCardList and doubleDragonCardList then
                for key, var in pairs(singleCardList) do
                    if var and var.cardValue and var.cardValue > lastTakeOutCardValue and var.cardValue < cardValue_.CARD_POINT_2 then
                        for k, v in pairs(doubleDragonCardList) do
                            if v and v.cardList then
                                local i = 1
                                while i <= #v.cardList do
                                    if v.cardList[i] and var.cardValue == v.cardList[i].value then
                                        needTakeOutCardGroup = {}
                                        needTakeOutCardGroup.cardType = cardType_.THREE_CARDS
                                        needTakeOutCardGroup.cardValue = var.cardValue
                                        needTakeOutCardGroup.cardList = {}
                                        table.insert(needTakeOutCardGroup.cardList, var.cardList[1])
                                        table.insert(needTakeOutCardGroup.cardList, v.cardList[i])
                                        table.insert(needTakeOutCardGroup.cardList, v.cardList[i + 1])
                                        table.remove(v.cardList, i)
                                        table.remove(v.cardList, i)
                                        canMarginSingleCardToDoubleDragon = true
                                        break
                                    end
                                    i = i + 2
                                end
                                if canMarginSingleCardToDoubleDragon then
                                    break
                                end
                            end
                        end
                        if canMarginSingleCardToDoubleDragon then
                            break
                        end
                    end
                end

                --从单牌牌组列表中删除已经组成三张的单牌
                if canMarginSingleCardToDoubleDragon then
                    singleCardLessThen2Count = singleCardLessThen2Count - 1
                    local i = 1
                    while singleCardList[i] do
                        if singleCardList[i] and singleCardList[i].cardValue and needTakeOutCardGroup.cardValue and singleCardList[i].cardValue == needTakeOutCardGroup.cardValue then
                            table.remove(singleCardList, i)
                        else
                            i = i + 1
                        end
                    end
                end
            end
            return canMarginSingleCardToDoubleDragon
        end

        if log_util.isDebug() == true then
            log_util.i(TAG, "getTakeOutThreeWithCard IN lastTakeOutCardType is ", lastTakeOutCardType)
            log_util.i(TAG, "getTakeOutThreeWithCard IN cardType_.THREE_WITH_ONE is ", cardType_.THREE_WITH_ONE)
        end

        if lastTakeOutCardType == cardType_.THREE_WITH_ONE then
            --从一个牌组列表中拆取出一张单牌
            local getSingleCardFromCardList = function (cardList, index)
                if cardList and cardList[index] and cardList[index].cardList and cardList[index].cardList[1] then
                    table.insert(needTakeOutCardGroup.cardList, 1, cardList[index].cardList[1])
                    needTakeOutCardGroup.cardType = cardType_.THREE_WITH_ONE
                end
            end

            --向三张牌组中添加需要带的单牌
            local addSingleCardToThreeCard = function ()
                if singleCardLessThen2Count > 0 then
                    getSingleCardFromCardList(singleCardList, 1)
                else
                    if doubleCardLessThen2Count > 0 then
                        getSingleCardFromCardList(doubleCardList, 1)
                    else
                        if threeCardLessThen2Count > 0 then
                            getSingleCardFromCardList(threeCardList, 1)
                        else
                            if singleDragonLengthBiggerThen5Count > 0 then
                                for i = 1, #singleDragonCardList do
                                    if singleDragonCardList[i].cardList and #singleDragonCardList[i].cardList > 5 then
                                        getSingleCardFromCardList(singleDragonCardList, i)
                                        break
                                    end
                                end
                            else
                                if doubleDragonCardList and #doubleDragonCardList > 0 then
                                    getSingleCardFromCardList(doubleDragonCardList, 1)
                                else
                                    if threeDragonCardList and #threeDragonCardList > 0 then
                                        getSingleCardFromCardList(threeDragonCardList, 1)
                                    end
                                end
                            end
                        end
                    end
                end
            end

            --如果有三张，则获取需要带的单牌
            if hasThreeCard then
                addSingleCardToThreeCard()
            else
                --没有三张的牌组，需要从对子+单顺或者单牌+双顺或者三顺中拆取三张的牌组

                --检查是否有对子可以和单顺中的某张牌组成三张
                local canMarginDoubleCardToSingleDragon = checkHasDoubleCardMarginToSingleDragon()

                --检查是否有单牌可以和双顺中的某个对子组成三张
                local canMarginSingleCardToDoubleDragon = checkHasSingleCardMarginToDoubleDragon()

                if log_util.isDebug() == true then
                    log_util.i(TAG, "getTakeOutThreeWithCard IN canMarginSingleCardToDoubleDragon is ", canMarginSingleCardToDoubleDragon)
                end


                if canMarginDoubleCardToSingleDragon or canMarginSingleCardToDoubleDragon then
                    addSingleCardToThreeCard()
                end
            end
        elseif lastTakeOutCardType == cardType_.THREE_WITH_TWO then
            --从一个牌型中拆取出对子
            local getDoubleCardFromCardList = function (cardList)
                if cardList and cardList[1] and cardList[1].cardList then
                    for i = 1, 2 do
                        if cardList[1].cardList[i] then
                            table.insert(needTakeOutCardGroup.cardList, 1, cardList[1].cardList[i])
                        end
                    end
                    needTakeOutCardGroup.cardType = cardType_.THREE_WITH_TWO
                end
            end

            local addDoubleCardToThreeCard = function ()
                if doubleCardLessThen2Count > 0 then
                    getDoubleCardFromCardList(doubleCardList)
                else
                    if threeCardLessThen2Count > 0 then
                        getDoubleCardFromCardList(threeCardList)
                    else
                        if doubleDragonCardList and #doubleDragonCardList > 0 then
                            getDoubleCardFromCardList(doubleDragonCardList)
                        else
                            if threeDragonCardList and #threeDragonCardList > 0 then
                                getDoubleCardFromCardList(threeDragonCardList)
                            end
                        end
                    end
                end
            end

            --如果有三张，则获取需要带的单牌
            if hasThreeCard then
                addDoubleCardToThreeCard()
            else
                --没有三张的牌组，需要从对子+单顺或者单牌+双顺或者三顺中拆取三张的牌组

                --检查是否有对子可以和单顺中的某张牌组成三张
                local canMarginDoubleCardToSingleDragon = checkHasDoubleCardMarginToSingleDragon()

                --检查是否有单牌可以和双顺中的某个对子组成三张
                local canMarginSingleCardToDoubleDragon = checkHasSingleCardMarginToDoubleDragon()

                if canMarginDoubleCardToSingleDragon or canMarginSingleCardToDoubleDragon then
                    addDoubleCardToThreeCard()
                end
            end
        end
    end

    if needTakeOutCardGroup and needTakeOutCardGroup.cardList and #needTakeOutCardGroup.cardList == lastTakeOutCardLength then
        return needTakeOutCardGroup
    else
        return nil
    end

    return nil
end

--根据记牌器来判断该牌型是否是最大的
function SingleGameAI:checkCardGroupIsBiggest(checkCardGroup, whom)
    local isBiggest = true
    local cardType = -1
    local cardValue = -1
    local cardLength = 0
    local cardCountInHand = 0

    --获取手牌中已有的张数
    local getCardCountInHand = function (cardValue, whom)
        cardCountInHand = 0
        local cardsList = self:getSomeOneCards(whom)
        
        for key, var in pairs(cardsList) do
            if var and var.value == cardValue then
                cardCountInHand = cardCountInHand + 1
            end
        end

        if log_util.isDebug() == true then
            log_util.i(TAG, "checkCardGroupIsBiggest IN whom is ", whom, " self.lordPos_ is ", self.lordPos_)
        end

        local tempFriendPos = {}
        if whom ~= self.lordPos_ then
            if whom == self.pos_.SELF then
                if self.pos_.PRE == self.lordPos_ then
                    table.insert(tempFriendPos, self.pos_.NEXT)
                else
                    table.insert(tempFriendPos, self.pos_.PRE)
                end
            else
                if self.pos_.SELF == self.lordPos_ then
                    if whom == self.pos_.PRE then
                        table.insert(tempFriendPos, self.pos_.NEXT)
                    else
                        table.insert(tempFriendPos, self.pos_.PRE)
                    end
                else
                    table.insert(tempFriendPos, self.pos_.SELF)
                end
            end
        end
        if log_util.isDebug() == true then
            log_util.i(TAG, "checkCardGroupIsBiggest IN tempFriendPos is ", tempFriendPos)
        end

        if tempFriendPos and tempFriendPos[1] then
            local friendCardList = self:getSomeOneCards(tempFriendPos[1])
            for key, var in pairs(friendCardList) do
                if var and var.value == cardValue then
                    cardCountInHand = cardCountInHand + 1
                end
            end
        end
        return cardCountInHand
    end

    if log_util.isDebug() == true then
        log_util.i(TAG, "checkCardGroupIsBiggest IN begin")
    end

    if checkCardGroup and checkCardGroup.cardList then
        cardType = checkCardGroup.cardType
        cardValue = checkCardGroup.cardValue
        cardLength = #checkCardGroup.cardList

        if self.againistPos_ then
            for k,v in pairs(self.againistPos_) do
                if v then
                    local againistCardList, againistCardGroup = self:getSomeOneCards(v)
                    for k, againistCardGroup in pairs(againistCardGroup) do
                        if againistCardGroup and againistCardGroup.cardType == self.cardType_.DOUBLE_JOKER then
                            return false
                        end
                    end
                end
            end
        end

        if cardType ~= self.cardType_.FOUR_CARDS then
            if self.againistPos_ then
                for k,v in pairs(self.againistPos_) do
                    if v then
                        local againistCardList, againistCardGroup = self:getSomeOneCards(v)
                        for k, againistCardGroup in pairs(againistCardGroup) do
                            if againistCardGroup and againistCardGroup.cardType == self.cardType_.FOUR_CARDS then
                                return false
                            end
                        end
                    end
                end
            end
        end

        if cardValue == 17 then
            return true
        end

        if cardType == cardType_.SINGLE_CARD or cardType == cardType_.DOUBLE_CARDS or cardType == cardType_.THREE_CARDS or cardType == cardType_.FOUR_CARDS then
            for i = cardValue + 1, 17 do
                local alreadyTakeOutCount = self:getAlreadyTakeOutCardCountByValue(i)
                cardCountInHand = getCardCountInHand(i, whom)
                if i == 17 or i == 16 then
                    if log_util.isDebug() == true then
                        log_util.i(TAG, "checkCardGroupIsBiggest IN i is ", i, " cardCountInHand is ", cardCountInHand, " alreadyTakeOutCount is ", alreadyTakeOutCount)
                    end

                    if cardType == cardType_.SINGLE_CARD then
                        if alreadyTakeOutCount == 0 and cardCountInHand == 0 then
                            isBiggest = false
                            break
                        end
                    else
                        --非单牌只需要判断双王是否存在
                        if alreadyTakeOutCount == 0 then
                            --如果手牌中有一张大王或者小王，则双王不存在
                            if cardCountInHand == 1 then
                                break
                            else
                                if self.friendPos_[1] then
                                    local cardCountInFriendHand = getCardCountInHand(i, self.friendPos_[1])
                                    --如果对家手牌中有一张大王或者小王，则双王不存在
                                    if cardCountInFriendHand == 1 then
                                        break
                                    end
                                end
                            end
                        else
                            break
                        end

                        if i == 17 then
                            isBiggest = false
                        end
                    end
                else
                    if log_util.isDebug() == true then
                        log_util.i(TAG, "checkCardGroupIsBiggest IN i is ", i, " cardCountInHand is ", cardCountInHand, " alreadyTakeOutCount is ", alreadyTakeOutCount)
                    end

                    --除去大小王，其他每个牌值对应都有4张牌，减去已出的，再减去手牌中已有的，剩下的张数如果比需要比较的牌张数大，则表示还有能大过的牌，这手牌不是最大的
                    if 4 - alreadyTakeOutCount - cardCountInHand >= cardLength then
                        isBiggest = false
                        break
                    end
                end
            end
        else
            if cardValue ~= cardValue_.CARD_POINT_A then
                if self.againistPos_ then
                    for key, var in pairs(self.againistPos_) do
                        local _, againistCardGroup = self:getSomeOneCards(var)
                        if againistCardGroup then
                            for k, v in pairs(againistCardGroup) do
                                if v and v.cardType and v.cardValue and v.cardList then
                                    if v.cardValue > cardValue and #v.cardList > cardLength and cardType == v.cardType then
                                        isBiggest = false
                                        break
                                    end
                                end
                            end
                            if isBiggest == false then
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    if log_util.isDebug() == true then
        log_util.i(TAG, "checkCardGroupIsBiggest IN isBiggest is ", isBiggest)
        log_util.i(TAG, "checkCardGroupIsBiggest IN end")
    end

    return isBiggest
end

--判断当前手牌是否可以一手出完
function SingleGameAI:checkCanTakeOutOneHand(whom, lastTakeOutCardGroup)
    local canOneHand = false
    local handCardList, cardGroup = self:getSomeOneCards(whom)
    local notBiggestCardGroupList = {}
    local biggestCardGroupList = {}

    local unSingleOrDoubleCardCount = 0
    local singleCardCount = 0
    local doubleCardCount = 0

    local threeCardCount = 0
    local threeDragonCount = 0

    if cardGroup then
        if lastTakeOutCardGroup then
            local needTakeOutCard = self:takeOutNormalCard(lastTakeOutCardGroup, whom, false)
            if needTakeOutCard == nil then
                needTakeOutCard = self:takeOutSpecialCard(lastTakeOutCardGroup, whom, false)
            end

            if needTakeOutCard and needTakeOutCard.cardList and #handCardList == #needTakeOutCard.cardList then
                return true
            end
        end

        local getBiggestCardAndNotBiggestCardList = function (checkCardGroup)
            biggestCardGroupList = {}
            notBiggestCardGroupList = {}
            for key, var in pairs(checkCardGroup) do
                if var then
                    local isBiggest = self:checkCardGroupIsBiggest(var, whom)
                    if isBiggest then
                        var.isBiggest = true
                        table.insert(biggestCardGroupList, var)
                    else
                        var.isBiggest = false
                        table.insert(notBiggestCardGroupList, var)
                    end
                end
            end
        end

        local getSingleDoubleAndOtherCardCount = function ()
            unSingleOrDoubleCardCount = 0
            singleCardCount = 0
            doubleCardCount = 0
            --取出非单牌和对子的不是最大的牌，如果这些牌的数量大于1则表示这手牌不能一手出完，
            for key, var in pairs(notBiggestCardGroupList) do
                if var and var.cardType then
                    if var.cardType ~= cardType_.SINGLE_CARD and var.cardType ~= cardType_.DOUBLE_CARDS then
                        unSingleOrDoubleCardCount = unSingleOrDoubleCardCount + 1
                    else
                        if var.cardType == cardType_.SINGLE_CARD then
                            singleCardCount = singleCardCount + 1
                        end
                        if var.cardType == cardType_.DOUBLE_CARDS then
                            doubleCardCount = doubleCardCount + 1
                        end
                    end

                end
            end
        end

        local checkIsOneHand = function ()
            if unSingleOrDoubleCardCount < 2 then
                threeCardCount = 0
                threeDragonCount = 0
                for key, var in pairs(biggestCardGroupList) do
                    if var and var.cardType and var.cardType == cardType_.THREE_CARDS then
                        threeCardCount = threeCardCount + 1
                    end
                    if var and var.cardType and var.cardType == cardType_.THREE_DRAGON then
                        threeDragonCount = threeDragonCount + math.modf(#var.cardList / 3)
                    end
                end

                if threeDragonCount + threeCardCount > 0 and threeDragonCount + threeCardCount >= singleCardCount + doubleCardCount - 1 then
                    if threeDragonCount >= 0 then
                        if threeDragonCount == singleCardCount or threeDragonCount == doubleCardCount or threeDragonCount == singleCardCount + doubleCardCount * 2 then
                            canOneHand = true
                        end
                    else
                        canOneHand = true
                    end
                end

                if not canOneHand then
                    threeCardCount = 0
                    threeDragonCount = 0
                    singleCardCount = 0
                    doubleCardCount = 0
                    local threeDragonLength = 0
                    for key, var in pairs(notBiggestCardGroupList) do
                        if var and var.cardType and var.cardType == cardType_.THREE_CARDS then
                            threeCardCount = threeCardCount + 1
                        end
                        if var and var.cardType and var.cardType == cardType_.THREE_DRAGON then
                            threeDragonCount = threeDragonCount + 1
                            threeDragonLength = math.modf(#var.cardList / 3)
                        end
                        if var and var.cardType and var.cardType == cardType_.SINGLE_CARD then
                            singleCardCount = singleCardCount + 1
                        end
                        if var and var.cardType and var.cardType == cardType_.DOUBLE_CARDS then
                            doubleCardCount = doubleCardCount + 1
                        end
                    end

                    if log_util.isDebug() == true then
                        log_util.i(TAG, "checkCanTakeOutOneHand IN threeCardCount is ", threeCardCount)
                        log_util.i(TAG, "checkCanTakeOutOneHand IN threeDragonCount is ", threeDragonCount)
                        log_util.i(TAG, "checkCanTakeOutOneHand IN singleCardCount is ", singleCardCount)
                        log_util.i(TAG, "checkCanTakeOutOneHand IN doubleCardCount is ", doubleCardCount)
                    end


                    if threeCardCount == 1 then
                        if (threeCardCount == singleCardCount and doubleCardCount == 0) or 
                            (threeCardCount == doubleCardCount and singleCardCount == 0) then
                            canOneHand = true
                        end
                    elseif threeDragonCount == 1 then
                        if (threeDragonLength == singleCardCount and doubleCardCount == 0) or 
                            (threeDragonLength == doubleCardCount and singleCardCount == 0) or 
                            threeDragonLength == singleCardCount + doubleCardCount then
                            canOneHand = true
                        end
                    end
                end
            end
        end

        getBiggestCardAndNotBiggestCardList(cardGroup)

        if #notBiggestCardGroupList <= 1 then
            canOneHand = true
        else
            getSingleDoubleAndOtherCardCount()

            checkIsOneHand()
        end

        if not canOneHand then
            --如果不能一手出完，则判断下通过拆分连对是否可以和单牌组成三张来带牌，仅仅在地主只剩一张牌的情况下
            local againistCardCount = self:getAgainistCardCount()
            if againistCardCount == 1 then
                self:createBaseCardGroup(whom)
                local _, baseCardGroup = self:getSomeOneCards(whom)
                getBiggestCardAndNotBiggestCardList(baseCardGroup)
                getSingleDoubleAndOtherCardCount()
                checkIsOneHand()

                if not canOneHand then
                    self:getAllGroup(whom)
                end
            end
        end
    end
    return canOneHand
end

--获取手牌中最小的一张牌
function SingleGameAI:getSmallestCard(whom)
    local cards = self:getSomeOneCards(whom)

    if cards and cards[1] then
        table.sort(cards, sortCard)
        return cards[1]
    end
end

--根据牌值从记牌器中获取该牌值的张数
function SingleGameAI:getAlreadyTakeOutCardCountByValue(cardValue)
    local cardCount = 0
    if self.alreadyTakeOutCard_ then
        for key, var in pairs(self.alreadyTakeOutCard_) do
            if var and var.value == cardValue then
                cardCount = cardCount + 1
            end
        end
    end

    return cardCount
end

--根据牌型获取牌组列表
function SingleGameAI:getCardGroupByType(cardType, whom)
    local cards, cardGroup = self:getSomeOneCards(whom)
    local returnCardGroupList = {}
    local hasCardGroup = false
    for key, var in pairs(cardGroup) do
        if type(var) == "table" and var.cardType == cardType then
            table.insert(returnCardGroupList, var)
            hasCardGroup = true
        end
    end
    if hasCardGroup == false then
        return nil
    end
    return returnCardGroupList
end

--从手牌中删除出的牌
function SingleGameAI:removeTakeoutCard(cardList, whom)
    local cards, cardGroup = self:getSomeOneCards(whom)
    local cardListInt = self:getSomeOneCardsInt(whom)
    
    if cardList and cards then
        for key, var in pairs(cardList) do
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
    self:getAllGroup(whom)
end

--出牌AI END

function SingleGameAI:cleanTable(t)
    if type(t) == "table" then
        for i=1, #t do
            t[i] = nil
        end
    end
end

function sortCard(a, b)
    if a and b and a.value and b.value then
        return a.value < b.value
    end
end

function sortCardGroup(a, b)
    if a and b and a.cardValue and b.cardValue then
        return a.cardValue < b.cardValue
    end
end

function SingleGameAI:getFriendSeat(seat)
    for i = 0, 2 do
        if seat ~= i and i ~= self.lordPos_ then
            return i
        end    
    end
end

function SingleGameAI:reset()
    self:cleanTable(self.selfCards_)
    self:cleanTable(self.selfCardsInt_)
    self:cleanTable(self.selfCardsGroup_)
    self:cleanTable(self.preCards_)
    self:cleanTable(self.preCardsInt_)
    self:cleanTable(self.preCardsGroup_)
    self:cleanTable(self.nextCards_)
    self:cleanTable(self.nextCardsInt_)
    self:cleanTable(self.nextCardsGroup_)
    self:cleanTable(self.bottomCards_)
    self:cleanTable(self.bottomCardsInt_)
    self:cleanTable(self.alreadyTakeOutCard_)
    self:cleanTable(self.friendPos_)
    self:cleanTable(self.againistPos_)
    self.friendCanTakeOutOneHand_ = false
end

return SingleGameAI
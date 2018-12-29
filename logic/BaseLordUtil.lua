require "utils/functions"
BaseLordUtil = class("BaseLordUtil")

local log_util = require("utils.log_util")
local CardsInfo = require("logic.CardsInfo")
local CardPattern = require("logic.CardPattern")

local Card = require("logic.Card")

local ILLEGAL_CARDS = CardPattern.ILLEGAL_CARDS
local PASS = CardPattern.PASS
local SINGLE_CARD = CardPattern.SINGLE_CARD
local DOUBLE_CARDS = CardPattern.DOUBLE_CARDS
local THREE_CARDS = CardPattern.THREE_CARDS
local FOUR_CARDS = CardPattern.FOUR_CARDS
local DOUBLE_JOKER = CardPattern.DOUBLE_JOKER
local THREE_WITH_ONE = CardPattern.THREE_WITH_ONE
local THREE_WITH_TWO = CardPattern.THREE_WITH_TWO
local FOUR_WITH_TWO = CardPattern.FOUR_WITH_TWO
local FOUR_WITH_TWO_TWO = CardPattern.FOUR_WITH_TWO_TWO
local SINGLE_DRAGON = CardPattern.SINGLE_DRAGON
local DOUBLE_DRAGON = CardPattern.DOUBLE_DRAGON
local THREE_DRAGON = CardPattern.THREE_DRAGON
local THREE_ONE_DRAGON = CardPattern.THREE_ONE_DRAGON
local THREE_TWO_DRAGON = CardPattern.THREE_TWO_DRAGON
local BIGGESTSTRAIGHT = CardPattern.BIGGESTSTRAIGHT

-- 以经典斗地主为标准，四张为炸双王为火箭
local MAX_BOMB_CARD_COUNT = 4 -- 最大炸弹牌张数
local MAX_JOKER_COUNT = 2 
local _log_util = nil
local TAG = "BaseLordUtil"

function _log_util(tag, ...)
    if log_util.isDebug() then
        log_util.i(tag, ...)
    end
end

function BaseLordUtil:ctor(bombCardCount, jokerCount)
    if bombCardCount then
        MAX_BOMB_CARD_COUNT = bombCardCount
    end
    if jokerCount then
        MAX_JOKER_COUNT = jokerCount
    end
end

function BaseLordUtil:getConfig(val, defaultVal)
    return LordUtil:getConfig(val, defaultVal)
end

function BaseLordUtil:isJoker(c)
    return c and c.color == CardColor.COLOR_JOKER
end

function BaseLordUtil:findMultiBomb(cards, bombLength)
    local cardCountConstruct = self:createCardCountConstruct(cards)
    local list = {}
    if cardCountConstruct then
        for k, v in pairs(cardCountConstruct) do
            if v and v.cardCount >= 4 and v.cardCount == bombLength then
                table.insert(list, v.cardList)
            end
        end
    end
    if #list > 0 then
        return list
    else
        return nil
    end
end

function BaseLordUtil:findJoker(cards)
    if cards then
        local list = {}
        local isFourJoker = true
        local jokerCount = 0
        for k, v in pairs(cards) do
            if v.color == CardColor.COLOR_JOKER then
                table.insert(list, v)
                jokerCount = jokerCount + 1
            end
        end
        if jokerCount == MAX_JOKER_COUNT then
            return list
        else
            return nil
        end
    end
    return nil
end

--[[
    过滤掉不查找的牌值
]]
local checkExpectCard = function(cardValue, expectCardsList)
    if expectCardsList then
        for k, v in pairs(expectCardsList) do
            if cardValue == v.value then
                return false
            end
        end
        return true
    else
        return true
    end
end

--[[
    查找所有可以大过的牌，保存在列表中，每次提示就按照列表顺序遍历
    @params cards 手牌列表
    @params gci 上手牌信息
]]
function BaseLordUtil:findCanTakeOutCardList(cards, gci)
    local allCanTakeOutCardList = {}
    if gci.type == SINGLE_DRAGON or gci.type == DOUBLE_DRAGON or gci.type == THREE_DRAGON then
        allCanTakeOutCardList = self:findStrightCanTakeOutCardList(cards, gci, true)
    elseif gci.type == THREE_WITH_ONE or gci.type == THREE_WITH_TWO or gci.type == THREE_ONE_DRAGON or gci.type == THREE_TWO_DRAGON then
        allCanTakeOutCardList = self:findThreeWithCanTakeOutCardList(cards, gci)
    else
        local jokerBombList = self:findJoker(cards)
        allCanTakeOutCardList = self:findBaseCardCanTakeOutCardList(cards, gci, true, jokerBombList)
    end
    return allCanTakeOutCardList
end

--[[
    查找所有顺子牌型的可以大过的牌，包括单顺，双顺，三顺
    查找策略：
    由顺子最小的一张牌的牌值+1为起点，牌值循环+1遍历整个cardCountConstruct，每当遍历到牌张数等于顺子的长度时保存该顺子，起点值+1再遍历，直到起点值到A为止，这样就遍历出所有可以大过的顺子牌型，如果没有符合当前牌值的单牌或者对子时，可以拆分对子、三张，三顺由于需要拆分炸弹，所以不考虑拆分，直接提起炸弹
]]
function BaseLordUtil:findStrightCanTakeOutCardList(cards, gci, isIncludeBomb)
    -- 先取到顺子中每个牌值的个数
    local strightCardValueCount = 0
    if gci.type == SINGLE_DRAGON then
        strightCardValueCount = 1
    elseif gci.type == DOUBLE_DRAGON then
        strightCardValueCount = 2
    elseif gci.type == THREE_DRAGON then
        strightCardValueCount = 3
    end

    local cardCountConstruct = self:createCardCountConstruct(cards)

    -- 获取查找的起点值
    local strightBeginValue = gci.value - gci.length / strightCardValueCount + 2

    local findValue = strightBeginValue
    local list = {}

    -- 查找算法
    local i = 1
    local strightCardList = {}
    while cardCountConstruct[i] do
        local construct = cardCountConstruct[i]
        -- 不拆分炸弹，如果牌张数大于3则跳过
        if construct.cardCount > 3 then
            strightCardList = {}
        else
            if construct.cardCount >= strightCardValueCount then
                if construct.cardValue == findValue then
                    for j = 1, strightCardValueCount do
                        table.insert(strightCardList, construct.cardList[j])
                    end
                    if #strightCardList == gci.length then
                        table.insert(list, strightCardList)
                        strightCardList = {}
                        strightBeginValue = strightBeginValue + 1
                        findValue = strightBeginValue
                        if findValue >= CardPoint.POINT_2 then
                            break
                        end
                        i = 0
                    else
                        findValue = findValue + 1
                    end
                end
            end
        end
        i = i + 1
        if findValue >= CardPoint.POINT_2 then
            break
        else
            if cardCountConstruct[i] == nil then
                strightCardList = {}
                strightBeginValue = strightBeginValue + 1
                findValue = strightBeginValue
                i = 1
            end
        end
    end

    if isIncludeBomb then
        -- 获取炸弹
        -- 获取王炸
        local jokerBombList = self:findJoker(cards)
        local bombGci = {}
        bombGci.value = 2
        bombGci.length = 4
        bombGci.type = FOUR_CARDS
        bombGci.bomb = true
        local bombCanTakeOutCardList = self:findBaseCardCanTakeOutCardList(cards, bombGci, true, jokerBombList)
        if bombCanTakeOutCardList then
            for k, v in pairs(bombCanTakeOutCardList) do
                if v then
                    table.insert(list, v)
                end
            end
        end
    end
    return list
end

--[[--
    根据牌值来获取三带的牌型，牌值即为三带的牌值，这个方法在智能提牌时用来处理三带牌型，传进来的牌值即为点击选择的牌的牌值
    @params selfCards 手牌列表
    @params cardValue 需要找的牌值
    @params gci 需要大过的牌型
]]
function BaseLordUtil:findThreeWithCardByValue(selfCards, cardValue, gci)
    local withCardCount = 0
    -- 去除掉带牌的基础牌型
    local baseCardType = -1
    -- 创建一个去除带牌的牌值信息
    local baseCardGci = {}
    -- 创建一个带牌的牌型信息
    local withCardGci = {}

    if gci.type == THREE_WITH_TWO then
        withCardCount = 2
        baseCardType = THREE_CARDS
        baseCardGci.length = 3
        withCardGci.type = DOUBLE_CARDS
    elseif gci.type == THREE_WITH_ONE then
        withCardCount = 1
        baseCardType = THREE_CARDS
        baseCardGci.length = 3
        withCardGci.type = SINGLE_CARD
    end
    withCardGci.value = 2
    withCardGci.length = withCardCount
    baseCardGci.value = gci.value
    baseCardGci.type = baseCardType

    local returnThreeCardsList = nil
    local allCanTakeOutThreeCards = self:findBaseCardCanTakeOutCardList(selfCards, baseCardGci, false)
    if allCanTakeOutThreeCards then
        for k, threeCardsList in pairs(allCanTakeOutThreeCards) do
            if threeCardsList then
                if threeCardsList[1] then
                    if threeCardsList[1].value == cardValue then
                        returnThreeCardsList = threeCardsList
                        break
                    end
                end
            end
        end
    end
    if returnThreeCardsList then
        local findWithCardList = self:findWidthCards(selfCards, withCardCount, withCardGci, returnThreeCardsList)
        if findWithCardList then
            for j, card in pairs(findWithCardList) do
                table.insert(returnThreeCardsList, card)
            end
        else
            returnThreeCardsList = nil
        end
    end

    return returnThreeCardsList
end

--[[
    查找所有三带牌型的可以大过的牌，包括三带一，三带二，三顺带单，三顺带对
    查找策略：
    调用查找基础牌型的方法来获取所有的三张牌型
    带牌策略：
    用查找基础牌型的方法来查找所有可带的牌（单牌，对子，三张，只从这三种牌型中查找），查找的过程中需要过滤掉已经组成三张的牌值
]]
function BaseLordUtil:findThreeWithCanTakeOutCardList(cards, gci)
    -- 需要带的牌张数
    local withCardCount = 0
    -- 去除掉带牌的基础牌型
    local baseCardType = -1
    -- 创建一个去除带牌的牌值信息
    local baseCardGci = {}
    -- 创建一个带牌的牌型信息
    local withCardGci = {}

    if gci.type == THREE_WITH_TWO then
        withCardCount = 2
        baseCardType = THREE_CARDS
        baseCardGci.length = 3
        withCardGci.type = DOUBLE_CARDS
    elseif gci.type == THREE_WITH_ONE then
        withCardCount = 1
        baseCardType = THREE_CARDS
        baseCardGci.length = 3
        withCardGci.type = SINGLE_CARD
    elseif gci.type == THREE_ONE_DRAGON then
        withCardCount = 1
        baseCardType = THREE_DRAGON
        baseCardGci.length = gci.length - gci.length / 4
        withCardGci.type = SINGLE_CARD
    elseif gci.type == THREE_TWO_DRAGON then
        withCardCount = 2
        baseCardType = THREE_DRAGON
        baseCardGci.length = gci.length - gci.length / 5 * 2
        withCardGci.type = DOUBLE_CARDS
    else
        baseCardGci.length = 0
    end
    baseCardGci.value = gci.value
    baseCardGci.type = baseCardType

    -- 获取所有可以大过的不包含带牌的牌组
    local canTakeOutBaseCardList = nil
    if baseCardType == THREE_CARDS then
        canTakeOutBaseCardList = self:findBaseCardCanTakeOutCardList(cards, baseCardGci, false)
    elseif baseCardType == THREE_DRAGON then
        canTakeOutBaseCardList = self:findStrightCanTakeOutCardList(cards, baseCardGci, false)
    end
    if canTakeOutBaseCardList then
        -- 这里设置牌值为2是为了能够查找到牌值为3的最小的牌型
        withCardGci.value = 2
        withCardGci.length = withCardCount
        local withCardCount = baseCardGci.length / 3
        for k, baseCardList in pairs(canTakeOutBaseCardList) do
            local findWithCardList = self:findWidthCards(cards, withCardCount, withCardGci, baseCardList)
            if findWithCardList then
                for j, card in pairs(findWithCardList) do
                    table.insert(baseCardList, card)
                end
            else
                canTakeOutBaseCardList = nil
                break
            end
        end
    end
    -- 获取炸弹
    -- 获取王炸
    local jokerBombList = self:findJoker(cards)
    local bombGci = {}
    bombGci.value = 2
    bombGci.length = 4
    bombGci.type = FOUR_CARDS
    bombGci.bomb = true
    local bombCanTakeOutCardList = self:findBaseCardCanTakeOutCardList(cards, bombGci, true, jokerBombList)
    _log_util(TAG, "findThreeWithCanTakeOutCardList IN bombCanTakeOutCardList is ", vardump(bombCanTakeOutCardList))
    if bombCanTakeOutCardList then
        if canTakeOutBaseCardList == nil then
            canTakeOutBaseCardList = {}
        end
        for k, v in pairs(bombCanTakeOutCardList) do
            if v then
                table.insert(canTakeOutBaseCardList, v)
            end
        end
    end

    return canTakeOutBaseCardList
end

--[[
    查找所有可以带的牌
    优先查找牌型符合的牌，单牌、对子，如果没有则查找可以拆分的牌，对子、三张
    @params cards 需要查找的牌
    @params withCardCount 需要带多少组牌，这里是按照牌型来算，不是按照牌张来算
    @params gci 需要带的牌型信息
    @params expectCardsList 需要过滤的牌张列表
]]
function BaseLordUtil:findWidthCards(cards, withCardCount, gci, expectCardsList)
    local cardCountConstruct = self:createCardCountConstruct(cards)
    local i = #cardCountConstruct
    local length = gci.length
    local notSplitCardList = {}
    local splitCardList = {}
    local retList = {}
    local sortCardListByLength = function(a, b)
        if a and b then
            if #a == #b then
                return a[1].value < b[1].value
            else
                return #a < #b
            end
        end
    end
    while cardCountConstruct[i] do
        local construct = cardCountConstruct[i]
        if construct.cardCount < 4 and checkExpectCard(construct.cardValue, expectCardsList) then
            if construct.cardCount >= length then
                if construct.cardCount == length then
                    table.insert(notSplitCardList, construct.cardList)
                else
                    table.insert(splitCardList, construct.cardList)
                end
            end
        end
        i = i - 1
    end
    table.sort(splitCardList, sortCardListByLength)
    table.sort(notSplitCardList, sortCardListByLength)
    if #notSplitCardList >= withCardCount then
        -- 不用拆分的牌够带的情况
        for i = 1, withCardCount do
            for k, card in pairs(notSplitCardList[i]) do
                table.insert(retList, card)
            end
        end
        return retList
    else
        -- 不用拆分的牌不够带的情况
        local leftWithCardCount = withCardCount - #notSplitCardList
        -- 需要判断可以拆分的牌是否够带，不够带的话就证明没有可以大过的牌，return nil
        local isEnoughToWith = false
        local canWithCardCount = 0
        for key, cardList in pairs(splitCardList) do
            if #cardList % gci.length == 0 then
               canWithCardCount = canWithCardCount + #cardList / gci.length
            else
                canWithCardCount = canWithCardCount + 1
            end
        end
        isEnoughToWith = canWithCardCount >= leftWithCardCount
        
        if isEnoughToWith then
            for i = 1, #notSplitCardList do
                for k, card in pairs(notSplitCardList[i]) do
                    table.insert(retList, card)
                end
            end
            if #splitCardList[1] == (leftWithCardCount * gci.length) then
                for key, card in pairs(splitCardList[1]) do
                    table.insert(retList, card)
                end
            else
                local insertWithCardCount = 0
                local i = 1
                while insertWithCardCount < leftWithCardCount * gci.length do
                    if #splitCardList[i] % gci.length == 0 then
                        for key, card in pairs(splitCardList[i]) do
                            table.insert(retList, card)
                            insertWithCardCount = insertWithCardCount + 1
                            if insertWithCardCount == leftWithCardCount * gci.length then
                                break
                            end
                        end
                    else
                        for j = 1, gci.length do
                            table.insert(retList, splitCardList[i][j])
                            insertWithCardCount = insertWithCardCount + 1
                            if insertWithCardCount == leftWithCardCount * gci.length then
                                break
                            end
                        end
                    end
                    i = i + 1
                end
            end
            return retList
        else
            return nil
        end
    end
    return nil
end

--[[
    查找所有基础牌型的可以大过的牌，仅包含单张，对子，三张，炸弹，大于4张的炸弹（四斗）
    @params cards 查找的牌组列表
    @params gci 上手牌信息
    @params isIncludeBomb 是否查找炸弹
    @params jokerBombList 王炸列表
    @params expectCardsList 不查找的牌组列表，用于过滤牌值，在这个列表中的牌值都不添加
]]
function BaseLordUtil:findBaseCardCanTakeOutCardList(cards, gci, isIncludeBomb, jokerBombList, expectCardsList)
    local list = {}
    local cardCountConstruct = self:createCardCountConstruct(cards)
    if cardCountConstruct then
        if gci.type == FOUR_JOKER or gci.type == DOUBLE_JOKER then
            return nil
        end
        local i = 1
        local length = gci.length
        local isFindAllCardExpectBomb = false
        while cardCountConstruct[i] do
            local construct = cardCountConstruct[i]
            -- 非炸弹
            if length < 4 then
                if not isFindAllCardExpectBomb then
                    -- 先找length相同不用拆分的，如果找完则length递加，length每加1就遍历一边，length加到4的时候跳出，这样就将所有非炸弹的牌型全部找到了
                    if construct.cardCount == length and construct.cardValue > gci.value and checkExpectCard(construct.cardValue, expectCardsList) then
                        local cardList = {}
                        for j = 1, gci.length do
                            table.insert(cardList, construct.cardList[j])
                        end
                        table.insert(list, cardList)
                    end
                    i = i + 1
                    if i > #cardCountConstruct then
                        i = 1
                        length = length + 1
                        if length >= 4 then
                            isFindAllCardExpectBomb = isIncludeBomb and true or false
                        end
                    end
                else
                    -- 查找炸弹牌型，由4炸开始找，王炸留在最后
                    length = 4
                    if construct.cardCount == length then
                        local cardList = {}
                        for j = 1, length do
                            table.insert(cardList, construct.cardList[j])
                        end
                        table.insert(list, cardList)
                    end
                    i = i + 1
                    if i > #cardCountConstruct then
                        i = 1
                        length = length + 1
                        if length > MAX_BOMB_CARD_COUNT then
                            if jokerBombList then
                                table.insert(list, jokerBombList)
                            end
                            break
                        end
                    end
                end
            else
                if isIncludeBomb then
                    -- 炸弹牌型，由4炸开始找，如果牌张数相同则比较牌值大小，由于四斗有大于4张的炸弹，如果炸弹张数大于需要大过的炸弹牌张数的话也算可以大过
                    if construct.cardCount == length and (length > gci.length or construct.cardValue > gci.value) then
                        local cardList = {}
                        for j = 1, length do
                            table.insert(cardList, construct.cardList[j])
                        end
                        table.insert(list, cardList)
                    end
                    i = i + 1
                    if i > #cardCountConstruct then
                        i = 1
                        length = length + 1
                        if length > MAX_BOMB_CARD_COUNT then
                            if jokerBombList then
                                table.insert(list, jokerBombList)
                            end
                            break
                        end
                    end
                else
                    break
                end
            end
        end
        return list
    end
end

--从给出的牌中找出三龙
function BaseLordUtil:findThreeDragonCardAutoPrompt(cards)
    local list = {}
    local temp = nil
    local v
    local n = -1
    local len = 0
    for i = #cards, 1, -1 do
        v = cards[i] and cards[i].value
        if v > CardPoint.POINT_A then
            break
        else
            if len % 3 ~= 0 then
                if n < 0 or v == n + 1 then
                    table.insert(list, cards[i])
                    n = v
                    len = len + 1
                else
                    list = {}
                    table.insert(list, cards[i])
                    n = v
                    len = 1
                end
            elseif len % 3 == 1 then
                if v == n then
                    table.insert(list, cards[i])
                    len = len + 1
                else
                    list = {}
                    table.insert(list, cards[i])
                    n = v
                    len = 1
                end
            elseif len % 3 == 2 then
                if v == n then
                    table.insert(list, cards[i])
                    len = len + 1
                    --找到最小三龙了
                    if len >= 6 then
                        if temp == nil or #list > #temp then
                            temp = list
                        end
                    end
                else
                    list = {}
                    table.insert(list, cards[i])
                    n = v
                    len = 1
                end
            end
        end
    end
    return temp
end

--[[
    从给出的牌中找出顺子，这个方法是没有上手牌的，只需要从给出的牌中找出最长的顺子即可，在滑动选牌的时候使用
    @params cardList 给出的牌张列表
    @params strightCardCount 单顺还是双顺还0是三顺，单顺为1，双顺为2，三顺为3
    @params isCoverBomb 是否保护炸弹true为不拆，false拆分，如果不传则默认拆分炸弹
]]
function BaseLordUtil:findDragonCard(cardList, strightCardCount, isCoverBomb)
    local cardCountConstruct = self:createCardCountConstruct(cardList)
    local allStrightCardList = {}
    local strightCardList = {}
    local i = 1
    local strightMinLength = 0
    if strightCardCount == 1 then
        strightMinLength = 5
    elseif strightCardCount == 2 then
        strightMinLength = 6
    elseif strightCardCount == 3 then
        strightMinLength = 6
    end
    local startValue = 0
    local insertCard = function(cardList)
        for j = 1, strightCardCount do
            table.insert(strightCardList, cardList[j])
        end
    end
    while cardCountConstruct[i] do
        local construct = cardCountConstruct[i]
        local isSplitBomb = ((not isCoverBomb) or construct.cardCount < 4)
        if startValue == 0 then
            if isSplitBomb and construct.cardCount >= strightCardCount then
                startValue = construct.cardValue
                insertCard(construct.cardList)
            end
        else
            if construct.cardValue == startValue + 1 and isSplitBomb and construct.cardCount >= strightCardCount then
                insertCard(construct.cardList)
            else
                if #strightCardList >= strightMinLength then
                    table.insert(allStrightCardList, strightCardList)
                end
                strightCardList = {}
                insertCard(construct.cardList)
            end
            startValue = construct.cardValue
        end
        i = i + 1
        if cardCountConstruct[i] == nil or cardCountConstruct[i].cardValue > CardPoint.POINT_A then
            if #strightCardList >= strightMinLength then
                table.insert(allStrightCardList, strightCardList)
            end
            break
        end
    end
    local returnList = allStrightCardList[1]
    if returnList then
        for i = 2, #allStrightCardList do
            if allStrightCardList[i] then
                if #returnList <= #allStrightCardList[i] then
                    returnList = allStrightCardList[i]
                end
            end
        end
    end
    return returnList
end

function BaseLordUtil:createCardCountConstruct(selfCards)
    local cardCountConstruct = {}
    for i, selfCard in pairs(selfCards) do
        local isInsert = false
        for j, v in pairs(cardCountConstruct) do
            if v then
                if v.cardValue == selfCard.value then
                    table.insert(v.cardList, selfCard)
                    v.cardCount = v.cardCount + 1
                    isInsert = true
                    break
                end
            end
        end
        if not isInsert then
            local newConstruct = {}
            newConstruct.cardValue = selfCard.value
            newConstruct.cardList = {}
            table.insert(newConstruct.cardList, selfCard)
            newConstruct.cardCount = 1
            table.insert(cardCountConstruct, newConstruct)
        end
    end
    local sortValue = function(a, b)
        if a and b then
            return a.cardValue < b.cardValue
        end
    end
    table.sort(cardCountConstruct, sortValue)
    return cardCountConstruct
end

function BaseLordUtil:getCardsCountByValue(selfCards, cardValue)
    local cardCountConstruct = self:createCardCountConstruct(selfCards)
    for k, v in pairs(cardCountConstruct) do
        if v then
            if v.cardValue == cardValue then
                return v.cardCount
            end
        end
    end
    return 0
end

function BaseLordUtil:sortCardByCardLength(cards)
    local fourJokerList = self:findJoker(cards)
    local isHasFourJoker = fourJokerList ~= nil
    local sortMethod = function(a, b)
        if a and b and a.cardList and b.cardList then
            if isHasFourJoker and (a.cardValue == CardPoint.POINT_BIG_JOKER or b.cardValue == CardPoint.POINT_BIG_JOKER or a.cardValue == CardPoint.POINT_SMALL_JOKER or b.cardValue == CardPoint.POINT_SMALL_JOKER) then
                return a.cardValue > b.cardValue
            else
                if #a.cardList == #b.cardList then
                    return a.cardValue > b.cardValue
                else
                    return #a.cardList > #b.cardList
                end
            end
        end
    end
    local newCardList = {}
    local cardCountConstruct = self:createCardCountConstruct(cards)
    table.sort(cardCountConstruct, sortMethod)
    for k, construct in pairs(cardCountConstruct) do
        if construct then
            for k, card in pairs(construct.cardList) do
                table.insert(newCardList, card)
            end
        end
    end

    return newCardList
end

function BaseLordUtil:sortCards(cards)
    if cards and type(cards) == "table" then
        table.sort(cards, function(card1, card2) return card1:compareTo(card2) end)
    end
end

function BaseLordUtil:getCardInt(str)
    local s1 = string.char(string.byte(str, 1, 1))
    local s2 = string.char(string.byte(str, 2, 2))
    local value = 0

    if s1 == "j" then
        if s2 == "1" then
            return 52
        else
            return 53
        end
    elseif s1 == "d" then
        value = 0
    elseif s1 == "c" then
        value = 13
    elseif s1 == "h" then
        value = 26
    elseif s1 == "s" then
        value = 39
    end

    if s2 == "t" then
        value = value + 7
    elseif s2 == "j" then
        value = value + 8
    elseif s2 == "q" then
        value = value + 9
    elseif s2 == "k" then
        value = value + 10
    elseif s2 == "1" then
        value = value + 11
    elseif s2 == "2" then
        value = value + 12
    else
        value = value + tonumber(s2) - 3
    end
    return value
end

function BaseLordUtil:setIsLord(isLord)
    self.isLord = isLord
end

function BaseLordUtil:setBottomCards(bottomCards)
    self.bottomCards = bottomCards
end

function BaseLordUtil:equalBottomCard(value)

    --log_util.i("BaseLordUtil","equalBottomCard, value = ",value, ",isLord = ",self.isLord,",self.bottomCards = ")
    if self.isLord then
        if self.bottomCards then
            for k, v in pairs(self.bottomCards) do
                --log_util.i("BaseLordUtil","equalBottomCard in for, v.value = ",v.value)
                if value == v.value then
                    --log_util.i("BaseLordUtil","equalBottomCard in for, return true")
                    return true
                end
            end
        end
    end
    log_util.i("BaseLordUtil", "equalBottomCard OUT, return false")
    return false
end

function BaseLordUtil:replaceWithBottomCard(cards, list)

    log_util.i("BaseLordUtil", "replaceWithBottomCard")

    if not self.isLord or cards == nil or list == nil then
        return list
    end

    for k, c in pairs(list) do
        if self:equalBottomCard(c.value) and not c.isBottomCard then
            --log_util.i("BaseLordUtil","replaceWithBottomCard, equalBottomCard and not bottomCard")
            for i = #cards, 1, -1 do
                if c.value == cards[i].value then
                    --log_util.i("BaseLordUtil","replaceWithBottomCard, c.value == cards[i], i = ",i,",cards[i] = ", vardump(cards[i]))
                    if cards[i].isBottomCard then
                        --log_util.i("BaseLordUtil","replaceWithBottomCard, replace, k = ",k,", i = ", i)
                        table.remove(list, k)
                        table.insert(list, k, cards[i])
                    end
                end
            end
        end
    end

    return list
end

function BaseLordUtil:isBomb(cards)
    local cardsInfo = CardPattern:parseCards(cards) -- TODO
    if cardsInfo.bomb then
        return true
    end
    return false
end

function BaseLordUtil:removeSomeOfObjectsFromList(from, source)
    for i = 1, #source do
        for j = 1, #from do
            if from[j].value == source[i].value and from[j].color == source[i].color then
                table.remove(from, j)
                break
            end
        end
    end
    return from
end

function BaseLordUtil:addCards(addToList, cards)
    for k, v in pairs(cards) do
        table.insert(addToList, v)
    end
end

--------------------------------------- 底牌牌型-------------------------------------
function BaseLordUtil:getFundCardsMultiple(fundCards)
    local type = FUNDCARDS_MULTI_TYPE_NONE
    if fundCards and #fundCards == 3 then
        local cardsList = {}
        for k, v in pairs(fundCards) do
            local c = Card.new(v)
            table.insert(cardsList, c)
        end

        if BaseLordUtil:is2Joker(cardsList) then
            type = FUNDCARDS_MULTI_TYPE_2_JOKER
        elseif BaseLordUtil:is1Joker(cardsList) then
            type = FUNDCARDS_MULTI_TYPE_1_JOKER
        elseif BaseLordUtil:is3(cardsList) then
            type = FUNDCARDS_MULTI_TYPE_3
        elseif BaseLordUtil:is22(cardsList) then
            type = FUNDCARDS_MULTI_TYPE_22
        elseif BaseLordUtil:isFlush(cardsList) then
            type = FUNDCARDS_MULTI_TYPE_FLUSH
        elseif BaseLordUtil:isStaight(cardsList) then
            type = FUNDCARDS_MULTI_TYPE_STRAIGHT
        elseif BaseLordUtil:isAllSmall(cardsList) then
            type = FUNDCARDS_MULTI_TYPE_ALL_SMALL_3
        end
    end
    return type
end

function BaseLordUtil:is2Joker(fundCards)
    if fundCards then
        local sumJoker = 0
        for k, v in pairs(fundCards) do
            local value = v.value
            --print(TAG, "is2Joker IN value is ", value)
            if value == CardPoint.POINT_BIG_JOKER or value == CardPoint.POINT_SMALL_JOKER then
                sumJoker = sumJoker + 1
            end
        end
        if sumJoker == 2 then
            return true
        end
    end
    return false
end

function BaseLordUtil:is1Joker(fundCards)
    if fundCards then
        local sumJoker = 0
        for k, v in pairs(fundCards) do
            local value = v.value
            if value == CardPoint.POINT_BIG_JOKER or value == CardPoint.POINT_SMALL_JOKER then
                sumJoker = sumJoker + 1
            end
        end
        if sumJoker == 1 then
            return true
        end
    end
    return false
end

function BaseLordUtil:is22(fundCards)
    if fundCards then
        local countOf2 = 0
        for k, v in pairs(fundCards) do
            local value = v.value
            if value == CardPoint.POINT_2 then
                countOf2 = countOf2 + 1
            end
        end
        if countOf2 == 2 then
            return true
        end
    end
    return false
end

function BaseLordUtil:isFlush(fundCards)
    if fundCards then
        if fundCards[1].color == fundCards[2].color and fundCards[1].color == fundCards[3].color then
            return true
        end
    end
    return false
end

function BaseLordUtil:isStaight(fundCards)
    if fundCards then
        --包含大王，小王，或2，则不能为顺子
        for k, v in pairs(fundCards) do
            local value = v.value
            if value == CardPoint.POINT_BIG_JOKER or value == CardPoint.POINT_SMALL_JOKER or value == CardPoint.POINT_2 then
                return false
            end
        end
        --先按value从大到小排序
        BaseLordUtil:sortCards(fundCards)
        if fundCards[1].value - fundCards[2].value == 1 and fundCards[2].value - fundCards[3].value == 1 then
            return true
        end
    end
    return false
end

function BaseLordUtil:is3(fundCards)
    if fundCards then
        if fundCards[1].value == fundCards[2].value and fundCards[1].value == fundCards[3].value then
            return true
        end
    end
    return false
end

-- 全小
function BaseLordUtil:isAllSmall(fundCards)
    if fundCards then
        if fundCards then
            if fundCards[1].value < 10 and fundCards[2].value < 10 and fundCards[3].value < 10 then
                return true
            end
        end
    end
    return false
end

--------------------------------------- END----------------------------------
function BaseLordUtil:getHLCards(list)
    local cards = {}
    --print("BaseLordUtil", vardump(list))
    if list ~= nil and #list > 0 then
        for i = 1, #list do
            local hlCard = list[i]
            local original = 0
            if hlCard.cardclass == 4 then
                if hlCard.cardpoint == 13 then
                    original = 52 --小王
                else
                    original = 53 --大王
                end
            else
                --转换成斗地主牌型
                local color = hlCard.cardclass
                color = CardColor.fromHLCardColor(color)

                original = color * 13 + hlCard.cardpoint
            end
            table.insert(cards, original)
        end
    end
    return cards
end

function BaseLordUtil:selectSplitStr(str, split, index)
    local count = 0
    local pst, st, et = 1, 1, 1
    local res = nil
    repeat
        count = count + 1
        st, et = string.find(str, split, pst)
        if st and count == index then
            res = string.sub(str, pst, st - 1)
        end
        if not et then break end
        pst = et + 1
    until not st
    return res
end

function BaseLordUtil:convertFourLordCards(list)
    local cards = {}
    --log_util.i("convertFourLordCard", vardump(list))

    if list ~= nil and #list > 0 then
        for i = 1, #list do
            local fourLordCard = list[i]
            local original = 0

            local cardclass = math.modf(fourLordCard / 16)

            local cardpoint = fourLordCard % 16

            if cardclass == 5 then --LORDFOUR_CardColor.COLOR_JOKER then
                if cardpoint == 14 then
                    original = 52 --小王
                else --15
                    original = 53 --大王
                end
            else
                --转换成斗地主牌型
                local color = CardColor.fromFourCardColor(cardclass)

                --log_util.i("color =",color,"cardpoint =",cardpoint)
                original = color * 13 + cardpoint - 1
            end

            table.insert(cards, original)
        end
    end

    return cards
end

function BaseLordUtil:getFourLordCards(list)
    local cards = nil
    --log_util.i("getFourLordCards", vardump(list))

    if list ~= nil and #list > 0 then
        cards = {}
        for i = 1, #list do
            local original = list[i]
            local cardclass = 0
            local cardpoint = 0

            if original == 52 then
                cardclass = 5
                cardpoint = 14
            elseif original == 53 then
                cardclass = 5
                cardpoint = 15
            else
                local color = math.modf(original / 13)
                cardpoint = original % 13 + 1
                cardclass = CardColor.toFourCardColor(color)
            end

            local forlordcard = cardclass * 16 + cardpoint
            table.insert(cards, forlordcard)
        end
    end

    return cards
end

return BaseLordUtil

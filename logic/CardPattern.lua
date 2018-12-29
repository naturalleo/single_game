require "utils/functions"
local log_util = require("utils.log_util")
local CardPattern = class("CardPattern")
local CardsInfo = require("logic.CardsInfo")
local Card = require("logic.Card")

-- 斗地主牌型定义
CardPattern.ILLEGAL_CARDS = -1
CardPattern.PASS = 0
CardPattern.SINGLE_CARD = 1
CardPattern.DOUBLE_CARDS = 2
CardPattern.THREE_CARDS = 3
CardPattern.FOUR_CARDS = 4
CardPattern.DOUBLE_JOKER = 5
CardPattern.THREE_WITH_ONE = 10
CardPattern.THREE_WITH_TWO = 11
CardPattern.FOUR_WITH_TWO = 13
CardPattern.FOUR_WITH_TWO_TWO = 14
CardPattern.SINGLE_DRAGON = 20
CardPattern.DOUBLE_DRAGON = 21
CardPattern.THREE_DRAGON = 22
CardPattern.THREE_ONE_DRAGON = 23
CardPattern.THREE_TWO_DRAGON = 24
CardPattern.BIGGESTSTRAIGHT = 99

-- 欢斗的牌型(欢乐斗、二斗发送出牌消息时需要带牌型参数)
CardPattern.HLLORD_SINGLE_CARD = 0 --单张
CardPattern.HLLORD_SINGLE_DRAGON = 1-- 单顺

CardPattern.HLLORD_DOUBLE_CARDS = 2-- 对子
CardPattern.HLLORD_DOUBLE_DRAGON = 3-- 双顺
CardPattern.HLLORD_THREE_CARDS = 4-- 三张
CardPattern.HLLORD_THREE_WITH_ONE = 5-- 三带一
CardPattern.HLLORD_THREE_WITH_TWO = 6-- 三带二
CardPattern.HLLORD_THREE_DRAGON = 7-- 三顺
CardPattern.HLLORD_THREE_ONE_DRAGON = 8-- 三顺带一
CardPattern.HLLORD_THREE_TWO_DRAGON = 9-- 三顺带二

CardPattern.HLLORD_FOUR_CARDS = 10-- 四张
CardPattern.HLLORD_FOUR_WITH_ONE = 11-- 四带2单
CardPattern.HLLORD_FOUR_WITH_TWO = 12-- 四带2对
CardPattern.HLLORD_DOUBLE_JOKER = 13-- 火箭

--是否是单龙
function CardPattern:isSingleDragon(c)
    local t = c[1].value
    if (t > CardPoint.POINT_A) or (t < CardPoint.POINT_3) then
        return false
    end

    for i = 2, #c do
        local j = c[i].value
        if (j > CardPoint.POINT_A) or (j < CardPoint.POINT_3) then
            return false
        end
        if t - j ~= 1 then
            return false
        end
        t = j
    end
    return true
end

--是否是双龙
function CardPattern:isDoubleDragon(c)
    if #c % 2 ~= 0 then
        return false
    end

    local t = c[1].value
    if (t > CardPoint.POINT_A) or (t < CardPoint.POINT_3) then
        return false
    end

    local j = 0
    for i = 2, #c do
        j = c[i].value
        if (j > CardPoint.POINT_A) or (j < CardPoint.POINT_3) then
            return false
        end

        if i % 2 > 0 then
            if t ~= j + 1 then
                return false
            end
            t = j
        else
            if t ~= j then
                return false
            end
        end
    end
    return true
end

--是否是三龙
function CardPattern:isThreeDragon(c)
    if #c % 3 ~= 0 then
        return false
    end

    local t = c[1].value
    if (t > CardPoint.POINT_A) or (t < CardPoint.POINT_3) then
        return false
    end

    for i = 1, math.modf(#c / 3) do
        local j = c[i * 3 - 2].value
        if (j > CardPoint.POINT_A) or (j < CardPoint.POINT_3) then
            return false
        end
        if (c[i * 3 - 1].value ~= j) or (c[i * 3].value ~= j) then
            return false
        end
        if i > 1 then
            if c[i * 3 - 3].value - j ~= 1 then
                return false
            end
        end
    end
    return true
end

--是否是三带一
function CardPattern:isThreeWithOne(c)
    if c[2].value == c[3].value then
        if c[1].value == c[2].value then
            return true
        elseif c[3].value == c[4].value then
            c[1], c[2], c[3], c[4] = c[2], c[3], c[4], c[1]
            return true
        end
    end
    return false
end

--是否是三带二
function CardPattern:isThreeWithTwo(c)
    if (c[1].value == c[2].value) and (c[4].value == c[5].value) then
        if c[2].value == c[3].value then
            return true
        elseif c[4].value == c[3].value then
            c[1], c[2], c[3], c[4], c[5] =  c[3], c[4], c[5] ,c[1], c[2]
            return true
        end
    end
    return false
end

--是否是四个的炸弹
function CardPattern:isFourCardBomb(c)
    if (c[1].value == c[2].value) and (c[2].value == c[3].value) and (c[4].value == c[3].value) then
        return true
    end
    return false
end

--是否是四带二
function CardPattern:isFourWithTwo(c)
    if #c ~= 6 then
        return false
    end

    if c[3].value == c[4].value then
        if (c[1].value == c[2].value) and (c[1].value == c[3].value) then
            return true
        elseif  (c[5].value == c[6].value) and (c[5].value == c[3].value) then
            c[1], c[2], c[3], c[4], c[5], c[6] =  c[3], c[4], c[5], c[6], c[1], c[2]
            return true
        elseif (c[2].value == c[5].value) and (c[5].value == c[3].value) then
            c[1], c[2], c[3], c[4], c[5], c[6] =  c[2], c[3], c[4], c[5], c[1], c[6]
            return true
        end
    end
    return false
end

--是否是四带两对
function CardPattern:isFourWithTwoTwo(c)
    if #c ~= 8 then
        return false
    end
    --需要两两相等
    if (c[1].value ~= c[2].value) or (c[3].value ~= c[4].value) or (c[5].value ~= c[6].value) or (c[7].value ~= c[8].value) then
        return false
    end

    if c[1].value == c[3].value then
        return true
    end

    if c[3].value == c[5].value then
        c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8] = c[3], c[4], c[5], c[6], c[1], c[2], c[7], c[8]
        return true
    end

    if c[7].value == c[5].value then
        c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8] =  c[5], c[6], c[7], c[8], c[1], c[2], c[3], c[4]
        return true
    end
    return false
end

--是否是三带一的龙
function CardPattern:isThreeOneDragon(c)
    if #c % 4 ~= 0 then
        return false
    end
    if CardPattern:sortThreeWith(c) ~= math.modf(#c / 4) then
        return false
    end
    return true
end

--是否是三带二的龙
function CardPattern:isThreeTwoDragon(c)
    if #c % 5 ~= 0 then
        return false
    end

    if CardPattern:sortThreeWith(c) ~= math.modf(#c / 5) then
        return false
    end
    for i = math.modf(#c * 3 / 5) + 1, #c, 2 do
        if c[i].value ~= c[i+1].value then
            return false
        end
    end
    return true
end

--三带一，三代二的龙排序, 返回值是三个的个数，判断是否是正确的三带龙
function CardPattern:sortThreeWith(c)
    local m = {}
    local n = {}
    local x = 1
    local y = 1
    local v = -1
    local i = 1
     
    while( i <= #c) do
    --for i = 1, #c do
        if i < #c - 1 then
            if (c[i].value == c[i + 1].value) and (c[i].value == c[i + 2].value) and (c[i].value < CardPoint.POINT_2) and (c[i].value >= CardPoint.POINT_3) then  --TODO bug
    
                if v < 0 or c[i].value == v - 1 then
                    m[x] = c[i]
                    x = x + 1
                    i = i + 1
                    m[x] = c[i]
                    x = x + 1
                    i = i + 1
                    m[x] = c[i]
                    x = x + 1
                    v = c[i].value
                else
                    if i < math.modf(#c / 2) then
                        for p = 1, x do
                            n[y] = m[p]
                            y = y + 1
                        end
                        x = 1
                        m[x] = c[i]
                        x = x + 1
                        i = i + 1
                        m[x] = c[i]
                        x = x + 1
                        i = i + 1
                        m[x] = c[i]
                        x = x + 1
                        v = c[i].value
                    else
                        n[y] = c[i]
                        y = y + 1
                        i = i + 1
                        n[y] = c[i]
                        y = y + 1
                        i = i + 1
                        n[y] = c[i]
                        y = y + 1
                    end
                end
            else
                n[y] = c[i]
                y = y + 1
            end
        else
            n[y] = c[i]
            y = y + 1
        end
        i = i + 1
    end

    --给参数数组排序
    if math.modf(x / 3) == math.modf(#c / 5) or math.modf(x / 3) == math.modf(#c / 4 ) then
        for j = 1, #c do
            if j < x then
                c[j] = m[j]
            else
                c[j] = n[j - x + 1]
            end
        end
    end
    
    return math.modf(x / 3)
end


--function CardPattern:parseCards(cards)
--  local tempCards = {}
--  for i = 1, length do
--    tempCards[i] = new()
--    tempCards[i].setOriginal(cards[i])
--  end
--  return parseCards(tempCards)
--end

function CardPattern:parseCards(cards)
    --没有牌
    if cards == nil or #cards == 0 then
        return CardsInfo.new(CardPattern.PASS, 0)
    end

    local length = #cards
    if log_util.isDebug() == true then
        log_util.i("lilc", "CardPattern:parseCards length = "..length)
    end

    --单张
    if length == 1 then
        if log_util.isDebug() == true then
            log_util.i("lilc", "CardPattern:parseCards,type = ",CardPattern.SINGLE_CARD,",value = ",cards[1].value)
        end

        return CardsInfo.new(CardPattern.SINGLE_CARD, cards[1].value, 1, false)
    end
    --两张
    if length == 2 then
        if (cards[1].color == CardColor.COLOR_JOKER) and (cards[2].color == CardColor.COLOR_JOKER) then
            return CardsInfo.new(CardPattern.DOUBLE_JOKER, cards[1].value, 2, true)
        end
        if cards[1].value ~= cards[2].value then
            return CardsInfo.new(CardPattern.ILLEGAL_CARDS, 0)
        else
            if log_util.isDebug() == true then
                log_util.i("lilc", "CardPattern:parseCards DOUBLE_CARDS")
            end

            return CardsInfo.new(CardPattern.DOUBLE_CARDS, cards[1].value, 2, false)
        end
    end
    --三张
    if length == 3 then
        if (cards[1].value == cards[2].value) and (cards[1].value == cards[3].value) then
            return CardsInfo.new(CardPattern.THREE_CARDS, cards[1].value, 3)
        else
            return CardsInfo.new(CardPattern.ILLEGAL_CARDS, 0)
        end
    end
    --四张, 炸弹或者三带一
    if length == 4 then
        if CardPattern:isFourCardBomb(cards) then
            return CardsInfo.new(CardPattern.FOUR_CARDS, cards[1].value, 4, true)
        elseif CardPattern:isThreeWithOne(cards) then
            return CardsInfo.new(CardPattern.THREE_WITH_ONE, cards[1].value, 4)
        else
            return CardsInfo.new(CardPattern.ILLEGAL_CARDS, 0)
        end
    end
    --如果牌张大于5张，且小于12张，判断是否是单龙
    if length >= 5 and length <= 12 then
        if CardPattern:isSingleDragon(cards) then
            return CardsInfo.new(CardPattern.SINGLE_DRAGON, cards[1].value, length)
        end
    end
    --五张，三代二
    if length == 5 then
        if CardPattern:isThreeWithTwo(cards) then
            return CardsInfo.new(CardPattern.THREE_WITH_TWO, cards[1].value, length)
        end
        return CardsInfo.new(CardPattern.ILLEGAL_CARDS, 0)
    end
    --是不是双龙，如果牌张大于5张，且长度为偶数
    if length >= 6 and length % 2 == 0 then
        if CardPattern:isDoubleDragon(cards) then
            return CardsInfo.new(CardPattern.DOUBLE_DRAGON, cards[1].value, length)
        end
    end
    --是不是三龙（啥都不带），如果牌张大于5张，且长度为3的倍数
    if length >= 6 and length % 3 == 0 then
        if CardPattern:isThreeDragon(cards) then
            return CardsInfo.new(CardPattern.THREE_DRAGON, cards[1].value, length)
        end
    end
    --六张，单龙，双龙，三龙，四带二
    if length == 6 then
        if CardPattern:isFourWithTwo(cards) then
            return CardsInfo.new(CardPattern.FOUR_WITH_TWO, cards[1].value, length)
        end
    end

    --八张，单龙，双龙，四带二对
    if length == 8 then
        if CardPattern:isFourWithTwoTwo(cards) then
            return CardsInfo.new(CardPattern.FOUR_WITH_TWO_TWO, cards[1].value, length)
        end
    end
    --三代一的龙
    if length >= 8 and length % 4 == 0 then
        if CardPattern:isThreeOneDragon(cards) then
            return CardsInfo.new(CardPattern.THREE_ONE_DRAGON, cards[1].value, length)
        end
    end

    --三代二的龙
    if length >= 10 and length % 5 == 0 then

        if CardPattern:isThreeTwoDragon(cards) then
            return CardsInfo.new(CardPattern.THREE_TWO_DRAGON, cards[1].value, length)
        end
    end
    return CardsInfo.new(CardPattern.ILLEGAL_CARDS, 0, 0)
end

return CardPattern

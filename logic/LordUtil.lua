
LordUtil = {}

local log_util = require("utils.log_util")
local CardsInfo = require("logic.CardsInfo")
local CardPattern = require("logic.CardPattern")

local Card = require("logic.Card")

LordUtil.FUNDCARDS_MULTI_TYPE_NONE = 0
LordUtil.FUNDCARDS_MULTI_TYPE_2_JOKER = 1
LordUtil.FUNDCARDS_MULTI_TYPE_1_JOKER = 2
LordUtil.FUNDCARDS_MULTI_TYPE_22 = 3
LordUtil.FUNDCARDS_MULTI_TYPE_FLUSH = 4
LordUtil.FUNDCARDS_MULTI_TYPE_STRAIGHT = 5
LordUtil.FUNDCARDS_MULTI_TYPE_3 = 6
LordUtil.FUNDCARDS_MULTI_TYPE_ALL_SMALL_3 = 7

local TAG = "LordUtil"

function LordUtil:isJoker(c)
    return c and c.color == CardColor.COLOR_JOKER
end

function LordUtil:findSingleCard(cards, gci)
    local list = findMiniSingleCard(cards, gci.value)
    if list ~= nil and list.size() == 1 then
        return list
    end
    return LordUtil:findBomb(cards, gci)
end

function LordUtil:clearRefind()
    self.refind = false
end
function LordUtil:findDoubleCard(cards, gci, lastgci)
    local list

    if log_util.isDebug() == true then
        print("lilc", "findDoubleCard list = ",self.refind,gci.value,lastgci.value)
    end

    if not self.refind or self.refind == nil then
        self.refind = false
        list = LordUtil:findDoubleCardRefind(cards, lastgci.value, -1, self.refind)

        if log_util.isDebug() == true then
            print("lilc", "findDoubleCardRefind00 list = ",list,gci.value,lastgci.value)
        end

        if list ~= nil then
            return list
        else
            self.refind = true
            list = LordUtil:findThreeCard(cards, gci, true)

            if log_util.isDebug() == true then
                print("lilc", "findThreeCard11----------- list = ",self.refind,list,gci.value,lastgci.value)
            end

            if list ~= nil then
                return list
            else
                self.refind = false
            end
        end
    else
        list = LordUtil:findThreeCard(cards, lastgci, true)

        if log_util.isDebug() == true then
            print("lilc", "findDoubleCard222 list = ",list,gci.value,lastgci.value)
        end

        if list ~= nil then
            return list
        else
            self.refind = false
        end
    end
    return LordUtil:findBomb(cards, gci)
end

function LordUtil:findThreeCard(cards, gci, refind)
    --从大到小
    if not refind then         --正常获取三张
        for i = #cards, 3, -1 do
            --王牌不可能有三张
            if not LordUtil:isJoker(cards[i]) then
                if (cards[i].value > gci.value) and (cards[i].value == cards[i - 1].value) and (cards[i].value == cards[i - 2].value) then
                    local list = {cards[i - 2], cards[i - 1], cards[i]}
                    return list
                end
            end
    end
    return LordUtil:findBomb(cards, gci)
    else                    --获取三张中的对
        for i = #cards, 3, -1 do
            --王牌不可能有三张
            if not LordUtil:isJoker(cards[i]) then
                if (cards[i].value > gci.value) and (cards[i].value == cards[i - 1].value) and (cards[i].value == cards[i - 2].value) then
                    local list = {cards[i - 2], cards[i - 1]}
                    return list
                end
            end
    end
    end


end

function LordUtil:findFourCard(cards, gci)
    return LordUtil:findBomb(cards, gci)
end

function LordUtil:findThreeWithOneCard(cards, gci)
    local i = #cards
    while i >= 3 do
        if (not LordUtil:isJoker(cards[i - 2])) and (not LordUtil:isJoker(cards[i - 1])) then

            local bomb = false
            if(i > 3 and (cards[i].value == cards[i - 1].value) and (cards[i].value == cards[i - 2].value) and (cards[i].value == cards[i - 3].value)) then
                i = i - 3
                bomb = true
            end

            if(not bomb) then
                if ((cards[i].value > gci.value) and (cards[i].value == cards[i - 1].value) and (cards[i].value == cards[i - 2].value)) then
                    local list = {cards[i - 2], cards[i - 1], cards[i]}
                    --找到三张了，找一张最小的
                    local a = LordUtil:findMiniSingleCard(cards, 0, list)
                    if a == nil then
                        break
                    end
                    LordUtil:addCards(list, a)
                    return list
                end
            end
        end
        i = i - 1
    end
    return LordUtil:findBomb(cards, gci)
end

function LordUtil:findThreeWithTwoCard(cards, gci)
    local i = #cards
    while i >= 3 do
        if (not LordUtil:isJoker(cards[i - 2]) and not LordUtil:isJoker(cards[i - 1])) then
            local bomb = false
            if (i > 3) and (cards[i].value == cards[i - 1].value) and (cards[i].value == cards[i - 2].value) and (cards[i].value == cards[i - 3].value) then
                i = i - 3
                bomb = true
            end

            if log_util.isDebug() == true then
                print("bomb3666-------------------- = ",bomb, gci.value)
            end

            if not bomb then
                if (cards[i].value > gci.value) and (cards[i].value == cards[i - 1].value) and (cards[i].value == cards[i - 2].value) then
                    local list = {cards[i - 2], cards[i - 1], cards[i]}
                    --找到三张了，找最小的一对

                    if log_util.isDebug() == true then
                        print("findThreeWithTwoCard-------------------- = ")
                    end

                    local a = LordUtil:findMiniDoubleCard(cards, 0, list[1].value)
                    if a == nil then
                        break
                    end
                    LordUtil:addCards(list, a)
                    return list
                end
            end
        end
        i = i - 1
    end
    return LordUtil:findBomb(cards, gci)
end

function LordUtil:findFourWithTwoCard(cards, gci)
    local ci = CardsInfo:new(CardPattern.FOUR_CARDS, gci.value, 4, true)
    local a = LordUtil:findBomb(cards, ci)
    if a ~= nil and #a == 4 then
        local b = LordUtil:findSingleCards(2, cards, a)
        if b ~= nil then
            LordUtil:addCards(a, b)
            return a
        end
    end
    return LordUtil:findBomb(cards, gci)
end

function LordUtil:findFourWithTwoTwoCard(cards, gci)
    local ci = CardsInfo:new(CardPattern.FOUR_CARDS, gci.value, 4, true)
    local a = LordUtil:findBomb(cards, ci)

    if a ~= nil and #a == 4  then
        local b1 = LordUtil:findMiniDoubleCard(cards, 0, a[1].value)
        if b1 ~= nil then
            local b2 = LordUtil:findMiniDoubleCard(cards, b1[1].value, a[1].value)
            if b2 ~= nil then
                LordUtil:addCards(a, b1)
                LordUtil:addCards(a, b2)
                return a
            end
        end
    end
    return LordUtil:findBomb(cards, gci)
end

--从给出的牌中找出一条单龙，没有则返回空
function LordUtil:findSingleDragonCard(cards)
    local list = {}
    local temp = nil
    local v = 0
    local n = -1
    local len = 0

    for i = #cards, 1, -1 do
        v = cards[i] and cards[i].value
        if v > CardPoint.POINT_A then
            break
        else
            if v ~= n then
                if n < 0 or v == n + 1 then
                    table.insert(list, cards[i])
                    n = v
                    len = len + 1

                    --找到最小单龙了
                    if len >= 5 then
                        if temp == nil or list > #temp then
                            temp = list
                        end
                    end
                elseif v > n + 1 then
                    list = {}
                    table.insert(list, cards[i])
                    n = v
                    len = 1
                end
            end
        end
    end
    if temp then
        temp = self:replaceWithBottomCard(cards, temp)
    end
    return temp
end

function LordUtil:findSingleDragonCard(cards, gci)
    --当前龙的最小牌
    local miniCard = gci.value - gci.length + 1
    local list = {}
    local i
    local v
    local n = -1
    local len = 0

    for i = #cards, 1, -1 do
        v = cards[i] and cards[i].value
        if v and v > miniCard then
            if v > CardPoint.POINT_A then
                break
            else
                if v ~= n then

                    if n < 0 or v == n + 1 then
                        table.insert(list, cards[i])
                        n = v
                        len = len + 1
                        if len == gci.length then
                            return self:replaceWithBottomCard(cards, list)
                        end
                    elseif v > n + 1 then
                        list = {}
                        table.insert(list, cards[i])
                        n = v
                        len = 1
                    end
                end
            end
        end
    end
    return LordUtil:findBomb(cards, gci)
end

-- 从给出的牌中找出双龙
function LordUtil:findDoubleDragonCard(cards)
    local list = {}
    local temp = nil
    local v
    local n = -1
    local len = 0

    for i = #cards, 1, -1  do
        v = cards[i] and cards[i].value
        if v > CardPoint.POINT_A then
            break
        else
            --如果数组长度为偶数
            if len % 2 == 0 then
                if v ~= n then
                    if n < 0 or v == n + 1 then
                        table.insert(list, cards[i])
                        n = v
                        len = len + 1
                    elseif v > n + 1 then
                        list = {}
                        table.insert(list, cards[i])
                        n = v
                        len = 1
                    end
                end
                --数组长度为单数
            else
                if v == n then
                    table.insert(list, cards[i])
                    len = len + 1
                    --找到最小双龙了
                    if len >= 6 then
                        --之前未找到或者当前找到的大于之前的
                        if temp == nil or #list > #temp then
                            temp = list
                        end
                    end
                elseif v > n then
                    list = {}
                    table.insert(list, cards[i])
                    n = v
                    len = l
                end
            end
        end
    end
    return temp
end

function LordUtil:findDoubleDragonCardBomb(cards, gci)
    local smallCards = {}
    local miniCard = gci.value - math.modf(gci.length / 2) + 1
    local list = {}
    local n = -1
    local len = 0

    local cardsClone = {}

    for k, card in pairs(cards) do
        local cardtemp = Card.new(card.original)
        table.insert(cardsClone,cardtemp)
    end

    for i = #cardsClone, 4, -1 do
        if (cardsClone[i - 3].color == CardColor.COLOR_JOKER) or (cardsClone[i - 2].color == CardColor.COLOR_JOKER) then
        --continue
        elseif (cardsClone[i].value == cardsClone[i - 1].value) and (cardsClone[i].value == cardsClone[i - 2].value) and (cardsClone[i].value == cardsClone[i - 3].value) then
            if gci.type == CardPattern.FOUR_CARDS and cardsClone[i].value > gci.value or not gci.bomb then
                smallCards = {cardsClone[i - 3], cardsClone[i - 2], cardsClone[i - 1], cardsClone[i]}
            end
        end
    end

    if smallCards then
        for k, u in pairs(smallCards) do
            for key, var in pairs(cardsClone) do
                if u.color == var.color and u.value == var.value then
                    table.remove(cardsClone, key)
                    break
                end
            end
        end
    end

    list = self:findDoubleDragonCardPrompt(cardsClone,gci)

    return list
end


function LordUtil:findDoubleDragonCardPrompt(cards, gci)
    local miniCard = gci.value - math.modf(gci.length / 2) + 1
    local list = {}
    local i
    local v
    local n = -1
    local len = 0

    for i = #cards, 1, - 1 do
        v = cards[i] and cards[i].value
        if v > miniCard then
            if v > CardPoint.POINT_A then
                break
            else
                --如果数组长度为偶数
                if len % 2 == 0 then
                    if v ~= n then
                        local continue = true
                        if n < 0 or v == n + 1 then
                            table.insert(list, cards[i])
                            n = v
                            len = len + 1
                            continue = false
                        end
                        if continue then
                            if v > n + 1 then
                                list = {}
                                table.insert(list, cards[i])
                                n = v
                                len = 1
                            end
                        end
                    end

                    --数组长度为单数
                else
                    local continue = true
                    if v == n then
                        table.insert(list, cards[i])
                        len = len + 1
                        if len == gci.length then
                            return list
                        end
                        continue = false
                    end

                    if continue then
                        if v > n then
                            list = {}
                            table.insert(list, cards[i])
                            n = v
                            len = 1
                        end
                    end
                end
            end
        end
    end
    return nil
end

function LordUtil:findDoubleDragonCard(cards, gci)
    --当前龙的最小牌
    local list = {}

    list = self:findDoubleDragonCardBomb(cards, gci)

    if list ~= nil then
        return list
    else
        list = {}
    end

    list = self:findDoubleDragonCardPrompt(cards, gci)

    if list ~= nil then
        return list
    else
    end

    return LordUtil:findBomb(cards, gci)
end

--从给出的牌中找出三龙
function LordUtil:findThreeDragonCardAutoPrompt(cards)
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

function LordUtil:findThreeDragonCard(cards, gci)
    local list = {}
    local i
    local v
    local n = -1
    local len = 0
    local dragonLen = 0

    if gci.type == CardPattern.THREE_TWO_DRAGON then
        dragonLen = math.modf(gci.length / 5) * 3
    elseif gci.type == CardPattern.THREE_ONE_DRAGON then
        dragonLen = math.modf(gci.length / 4) * 3
    else
        dragonLen = gci.length
    end

    --TODO android版本有问题
    --gci是已经排个序的，三张的在前
    local miniCard = gci.value - math.modf(dragonLen / 3) + 1

    for i = #cards, 1, -1 do
        v = cards[i] and cards[i].value
        if v > miniCard then
            if v > CardPoint.POINT_A then
                break
            else
                if len % 3 == 0 then
                    if v ~= n then
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
                    end
                elseif len % 3 == 1 then
                    if v == n then
                        table.insert(list, cards[i])
                        len = len + 1
                        if len == dragonLen then
                            return list
                        end
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
                        if len == dragonLen then
                            return list
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
    end
    return LordUtil:findBomb(cards, gci)
end

function LordUtil:findThreeOneDragonCard(cards, gci)
    local list = LordUtil:findThreeDragonCard(cards, gci)
    if list ~= nil then
        LordUtil:sortCards(list)
        if LordUtil:isBomb(list) then
            return list
        end

        local b = LordUtil:findSingleCards(math.modf(gci.length / 4), cards, list)
        if b ~= nil then
            LordUtil:sortCards(b)
            LordUtil:addCards(list, b)
            return list
        end
    end
    return LordUtil:findBomb(cards, gci)
end

function LordUtil:findThreeTwoDragonCard(cards, gci)
    local list = LordUtil:findThreeDragonCard(cards, gci)
    if list ~= nil then
        LordUtil:sortCards(list)
        if LordUtil:isBomb(list) then
            return list
        end

        local c2 = {}
        LordUtil:addCards(c2, cards)
        c2 = LordUtil:removeSomeOfObjectsFromList(c2, list)

        local miniV = -1
        local c = {}
        local fail = false

        for i = 1, math.modf(gci.length / 5) do
            local b = LordUtil:findMiniDoubleCard(c2, miniV, -1)
            if b == nil then
                fail = true
                break
            else
                LordUtil:addCards(c, b)
                c2 = LordUtil:removeSomeOfObjectsFromList(c2, b)
            end
        end
        if not fail then
            LordUtil:sortCards(c)
            LordUtil:addCards(list, c)
            return list
        end
    end
    return LordUtil:findBomb(cards, gci)
end

--找炸弹，先找四个的，后找对王
function LordUtil:findBomb(cards, gci)
    --已经是双王了，不用找了
    if gci.type == CardPattern.DOUBLE_JOKER then
        return nil
    end

    --找四个相同的
    for i = #cards, 4, -1 do
        if cards[i - 3] == nil or cards[i - 2] == nil or ((cards[i - 3].color == CardColor.COLOR_JOKER) or (cards[i - 2].color == CardColor.COLOR_JOKER)) then
        --continue
        elseif (cards[i] and cards[i - 1] and cards[i - 2] and cards[i - 3]) and (cards[i].value == cards[i - 1].value) and (cards[i].value == cards[i - 2].value) and (cards[i].value == cards[i - 3].value) then
            if gci.type == CardPattern.FOUR_CARDS and cards[i].value > gci.value or not gci.bomb then
                local list = {cards[i - 3], cards[i - 2], cards[i - 1], cards[i]}
                return list
            end
        end
    end

    --对王
    if #cards >= 2 and cards[1] and cards[2] and cards[1].color == CardColor.COLOR_JOKER and cards[2].color == CardColor.COLOR_JOKER then
        local list = {cards[1], cards[2]}
        return list
    end
    return nil
end

function LordUtil:findMiniSingleCardJoker(cards, value, without)
    local list = {}
    if cards and #cards == 2 then
        for i,v in ipairs(cards) do
            if log_util.isDebug() == true then
                print("cards = ",i,v.color)
            end

        end
        if cards[1].color == CardColor.COLOR_JOKER and cards[2].color == CardColor.COLOR_JOKER then
            table.insert(list, cards[1])
            table.insert(list, cards[2])
            return list
        end
    end
    return nil
end

--找到最小单张，大于value且不等于
function LordUtil:findMiniSingleCard(cards, value, without)

    if log_util.isDebug() == true then
        log_util.i("LordUtil","findMiniSingleCard IN")
    end

    local i
    local v
    local list = {}
    local nWithOutSize = 0
    if without then
        nWithOutSize = #without
    end

    list = self:findMiniSingleCardJoker(cards, value, without)
    if list then
        return list
    else
        list = {}
    end

    --查找大于value且不等于notEqual的单张（不拆）
    for i = #cards, 1, -1 do
        local continue = true

        if cards[i] == nil or (i < #cards and cards[i + 1] == nil) or (i > 1 and cards[i - 1] == nil) then
            break
        end
        
        if i < #cards and cards[i].value == cards[i+1].value then
            continue = false
        end
        --双王不拆
        if i < #cards and ((cards[i].color == CardColor.COLOR_JOKER and cards[i + 1].color == CardColor.COLOR_JOKER)) then
            continue = false
        end
        if i > 1 and ((cards[i].color == CardColor.COLOR_JOKER and cards[i - 1].color == CardColor.COLOR_JOKER)) then
            continue = false
        end

        if continue then
            if i > 1 and cards[i].value == cards[i - 1].value then
                continue = false
            end
            if continue then
                v = cards[i] and cards[i].value
                for j = 1, nWithOutSize do
                    if without[j] and v == without[j].value then
                        continue = false
                        break
                    end
                end
                if continue then
                    if v > value then
                        table.insert(list, cards[i])
                        return list
                    end
                end
            end
        end
    end

    --TODO 可以考虑不拆炸弹
    --查找大于value且不等于notEqual的单张（不管拆不拆）
    for i = #cards, 1, -1 do
    
    	if cards[i] == nil or (i < #cards and cards[i + 1] == nil) or (i > 1 and cards[i - 1] == nil) then
            break
        end
        
        v = cards[i] and cards[i].value
        local continue = true
        for j = 1, nWithOutSize do
            if v == without[j].value then
                continue = false
                break
            end
        end
        --双王不拆
        if i < #cards and ((cards[i].color == CardColor.COLOR_JOKER and cards[i + 1].color == CardColor.COLOR_JOKER)) then
            continue = false
        end
        if i > 1 and ((cards[i].color == CardColor.COLOR_JOKER and cards[i - 1].color == CardColor.COLOR_JOKER)) then   
            continue = false
        end

        if continue then
            if v > value then

                --优先提底牌
                if i - 1 > 0 and v == cards[i - 1].value then
                    if self:equalBottomCard(cards[i].value)  then
                        if log_util.isDebug() == true then
                            log_util.i("LordUtil","findMiniSingleCard, cards[i].isBottomCard = ",cards[i].isBottomCard)
                        end

                        if cards[i].isBottomCard then
                            table.insert(list, cards[i])
                            return list
                        end
                    else
                        table.insert(list, cards[i])
                        return list
                    end
                else
                    table.insert(list, cards[i])
                    return list
                end
                
            end
        end
    end
    return nil
end

--找到若干单张, count结果个数，cards，牌张数组，without,不能包含的牌
function LordUtil:findSingleCards(count, cards, without)--TODO
    local i
    local n = 0
    local list = {}
    local cards2 = {}
    LordUtil:addCards(cards2, cards)
    cards2 = LordUtil:removeSomeOfObjectsFromList(cards2, without)

    if #cards2 < count then
        return nil
    end
    if #cards2 == count then
        return cards2
    end

    --找单张，不拆
    for i = #cards2, 1, -1 do
        local continue = true
        if i < #cards2 and cards2[i].value == cards2[i + 1].value then
            continue = false
        end
        if i > 1 and cards2[i].value == cards2[i - 1].value then
            continue = false
        end
        if continue then
            table.insert(list, cards2[i])
            n = n + 1
            if n >= count then -- 已经找够则返回
                return list
            end
        end
    end

    --从列表中去掉刚才找出来的
    cards2 = LordUtil:removeSomeOfObjectsFromList(cards2, list)

    --保存最大单张，如果拆张结果剩余单张，那么替换最大单张
    local maxSingle = nil
    if list ~= nil and #list > 0 then
        maxSingle = list[n - 1]
    end
    local tempN = n
    local remain = count - n --还需找的张数
    for i = 1, remain do
        table.insert(list, cards2[#cards2 - i + 1]) -- 从小到大添加
        n = n + 1

        --已经找好最后一张牌了，需要判断是否有剩余单张
        if n >= count then
            --只有一张，肯定是单张，替换
            --大于一张，看看最后两张是否相等，不相等则替换
            local size2 = #cards2
            if size2 - remain == 1 or ((size2 - remain > 1) and (cards2[size2 - remain].value ~= cards2[size2 - remain - 1].value)) then
                if maxSingle ~= nil and maxSingle.value > cards2[size2 - remain].value then
                    table.remove(list, tempN)
                    table.insert(list, cards2[size2 - remain])
                    LordUtil:sortCards(list)
                end
            end
            return list
        end
    end
    return nil
end

--找到最小双张，大于value且不等于notEqual
function LordUtil:findMiniDoubleCard(cards, value, notEqual, refind)
    local v
    local i = #cards

    if not refind then
        while i >= 2 do
            v = cards[i] and cards[i].value
            local continue = true
            if v == notEqual or v <= value or LordUtil:isJoker(cards[i - 1]) or LordUtil:isJoker(cards[i]) then
                continue = false
            end
            if cards[i].value ~= cards[i - 1].value then
                continue = false
            end
            if continue then
                if i > 2 and cards[i] and cards[i - 2] and cards[i].value == cards[i - 2].value then
                    i = i - 2
                    continue = false
                end
                if continue then
                    local list = {cards[i - 1], cards[i]}
                    return list
                end
            end
            i = i - 1
        end
    end

    for i = #cards, 2, -1 do
        v = cards[i] and cards[i].value
        local continue = true
        if v == notEqual or v <= value or LordUtil:isJoker(cards[i - 1]) or LordUtil:isJoker(cards[i]) then
            continue = false
        end
        if continue then
            if cards[i].value == cards[i - 1].value then
                local list = {cards[i - 1], cards[i]}
                return list
            end
        end
    end
    return nil
end

--找到最小双张，大于value且不等于notEqual
function LordUtil:findDoubleCardRefind(cards, value, notEqual, refind)
    local v = 0
    local i = #cards

    if log_util.isDebug() == true then
        print("refind12-------------------- = ",refind)
    end

    if not refind then
        while i >= 2 do
            v = cards[i] and cards[i].value
            local continue = true
            if v == notEqual or v <= value or LordUtil:isJoker(cards[i - 1]) or LordUtil:isJoker(cards[i]) then
                continue = false
            end
            if cards[i] == nil or cards[i - 1] == nil or cards[i].value ~= cards[i - 1].value then
                continue = false
            end
            if continue then
                if i > 2 and cards[i] and cards[i - 2] and cards[i].value == cards[i - 2].value then
                    i = i - 2
                    continue = false
                end
                if continue then
                    local list = {cards[i - 1], cards[i]}
                    return list
                end
            end
            i = i - 1
        end
    else
        for i = #cards, 2, -1 do
            v = cards[i] and cards[i].value
            local continue = true
            if v == notEqual or v <= value or LordUtil:isJoker(cards[i - 1]) or LordUtil:isJoker(cards[i]) then
                continue = false
            end
            if continue then
                if cards[i].value == cards[i - 1].value then
                    local list = {cards[i - 1], cards[i]}
                    return list
                end
            end
        end
    end

    return nil
end

function LordUtil:sortCards(cards)
    if cards and type(cards)=="table" then
        table.sort(cards, function(card1, card2)  return card1:compareTo(card2) end)
    end
end

function LordUtil:sortCardsLZ(cards)
    table.sort(cards, function(a,b)
        if a.isWild ~= nil then
            if a.isWild == b.isWild then
                if a.value == b.value then
                    return a.color > b.color
                else
                    return a.value > b.value
                end
            else
                return a.isWild > b.isWild
            end
        else
            if a.value == b.value then
                return a.color > b.color
            else
                return a.value > b.value
            end
        end
    end)

    --for idx, value in ipairs(cards) do
    --    if log_util.isDebug() == true then
        --    print(TAG, "self.cards.color value = ",value.color,value.value)
    --    end

    --end

end

function LordUtil:getCardString(i)
    if i == 52 then
        return "j1"
    elseif i == 53 then
        return "j2"
    end
    local s = ""
    local m = math.modf(i / 13)
    local n = i % 13

    if m == 0 then
        s = "d"
    elseif m == 1 then
        s = "c"
    elseif m == 2 then
        s = "h"
    elseif m == 3 then
        s = "s"
    end

    if n == 7 then
        s = s .. "t"
    elseif n == 8 then
        s = s .. "j"
    elseif n == 9 then
        s = s .. "q"
    elseif n == 10 then
        s = s .. "k"
    elseif n == 11 then
        s = s .. "1"
    elseif n == 12 then
        s = s .. "2"
    else
        s = s + (n + 3)
    end
    return s
end

function LordUtil:getCardInt(str)
    local s1 = string.char(string.byte(str,1,1))
    local s2 = string.char(string.byte(str,2,2))
    local value = 0

    if s1 == "j" then
        if s2 == "1" then
            return 52
        else
            return 53
        end
    elseif s1 == "d" then
        value = 0
    elseif s1 == "c"then
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

function LordUtil:setIsLord(isLord)
    self.isLord = isLord
end

function LordUtil:setBottomCards(bottomCards)
    self.bottomCards = bottomCards
end

function LordUtil:equalBottomCard(value)

    if log_util.isDebug() == true then
        log_util.i("LordUtil","equalBottomCard, value = ",value, ",isLord = ",self.isLord,",self.bottomCards = ")
    end

    if self.isLord then
        if self.bottomCards then
            for k, v in pairs(self.bottomCards) do
                if log_util.isDebug() == true then
                    log_util.i("LordUtil","equalBottomCard in for, v.value = ",v.value)
                end

                if value == v.value then
                    if log_util.isDebug() == true then
                        log_util.i("LordUtil","equalBottomCard in for, return true")
                    end

                    return true
                end
            end
        end
    end
    if log_util.isDebug() == true then
        log_util.i("LordUtil","equalBottomCard OUT, return false")
    end

    return false
end

function LordUtil:replaceWithBottomCard(cards, list)

    if log_util.isDebug() == true then
        log_util.i("LordUtil","replaceWithBottomCard")
    end


    if not self.isLord or cards == nil or list == nil then
        return list
    end

    for k, c in pairs(list) do
        if self:equalBottomCard(c.value) and not c.isBottomCard then
            if log_util.isDebug() == true then
                log_util.i("LordUtil","replaceWithBottomCard, equalBottomCard and not bottomCard")
            end

            for i = #cards, 1, -1 do
                if c.value == cards[i].value then
                    if cards[i].isBottomCard then
                        if log_util.isDebug() == true then
                            log_util.i("LordUtil","replaceWithBottomCard, replace, k = ",k,", i = ", i)
                        end

                        table.remove(list, k)
                        table.insert(list, k, cards[i])
                    end
                end
            end
        end 
    end

    return list
end

--根据上一家牌提示玩家出牌
function LordUtil:prompt(cards, gci, last)
    if gci == nil or cards == nil or (#cards == 1 and gci.type ~= CardPattern.SINGLE_CARD) then
        return nil
    end
    if log_util.isDebug() == true then
        print("lilc", "LordUtil:prompt IN, cardsLength = "..#cards..",gci type=",gci.type,",gci value=",gci.value, self.refind)
    end


    local lastgci = gci
    if last ~= nil and gci.type ~= CardPattern.SINGLE_CARD then
        LordUtil:sortCards(last)
        lastgci = CardPattern:parseCards(last) -- TODO
    end

    local arr = nil
    if lastgci.type == CardPattern.SINGLE_CARD then
        arr = LordUtil:findMiniSingleCard(cards, gci.value, last)
        if arr == nil then
            arr = LordUtil:findBomb(cards, gci)
        end
    elseif lastgci.type == CardPattern.DOUBLE_CARDS then
        arr = LordUtil:findDoubleCard(cards, gci,lastgci)
    elseif lastgci.type == CardPattern.THREE_CARDS then
        arr = LordUtil:findThreeCard(cards, lastgci, false)
    elseif lastgci.type == CardPattern.FOUR_CARDS then
        arr = LordUtil:findFourCard(cards, lastgci)
    elseif lastgci.type == CardPattern.DOUBLE_JOKER then
        arr = nil
    elseif lastgci.type == CardPattern.THREE_WITH_ONE then
        arr = LordUtil:findThreeWithOneCard(cards, lastgci)
    elseif lastgci.type == CardPattern.THREE_WITH_TWO then
        arr = LordUtil:findThreeWithTwoCard(cards, lastgci)
    elseif lastgci.type == CardPattern.FOUR_WITH_TWO then
        arr = LordUtil:findFourWithTwoCard(cards, lastgci)
    elseif lastgci.type == CardPattern.FOUR_WITH_TWO_TWO then
        arr = LordUtil:findFourWithTwoTwoCard(cards, lastgci)
    elseif lastgci.type == CardPattern.SINGLE_DRAGON then
        arr = LordUtil:findSingleDragonCard(cards, lastgci)
    elseif lastgci.type == CardPattern.DOUBLE_DRAGON then
        arr = LordUtil:findDoubleDragonCard(cards, lastgci)
    elseif lastgci.type == CardPattern.THREE_DRAGON then
        arr = LordUtil:findThreeDragonCard(cards, lastgci)
    elseif lastgci.type == CardPattern.THREE_ONE_DRAGON then
        arr = LordUtil:findThreeOneDragonCard(cards, lastgci)
    elseif lastgci.type == CardPattern.THREE_TWO_DRAGON then
        arr = LordUtil:findThreeTwoDragonCard(cards, lastgci)
    end

    if log_util.isDebug() == true then
        --print("lilc", "8888 arr length = ",arr,last)
    end

    --提示到头了，从头开始
    if last ~= nil and arr == nil then
        arr = LordUtil:prompt(cards, gci, nil)
    end

    --if arr then
    --    if log_util.isDebug() == true then
        --    print("lilc", "LordUtil:prompt OUT, arr length = "..#arr)
    --    end

    --    for k, v in pairs(arr) do
     --       if log_util.isDebug() == true then
         --       print("lilc", "LordUtil:prompt OUT,k = "..k..",v color = "..v.color..",value = "..v.value)
     --       end

    --    end
    --end
    return arr
end

function LordUtil:isBomb(cards)
    local cardsInfo = CardPattern:parseCards(cards) -- TODO
    if cardsInfo.bomb then
        return true
    end
    return false
end

function LordUtil:removeSomeOfObjectsFromList(from, source)
    for i = 1, #source do
        for j = 1, #from do
            if from[j].value == source[i].value and from[j].color == source[i].color then
                table.remove(from,j)
                break
            end
        end
    end
    return from
end

function LordUtil:addCards(addToList, cards)
    for k, v in pairs(cards) do
        table.insert(addToList, v)
    end
end
---------------------------------------底牌牌型-------------------------------------
function LordUtil:getFundCardsMultiple(fundCards)
    local cardType = LordUtil.FUNDCARDS_MULTI_TYPE_NONE
    local multi = 1
    if fundCards and #fundCards == 3 then
        local cardsList = {}
        for k, v in pairs(fundCards) do
            local c = Card.new(v)
            table.insert(cardsList, c)
        end

        -- 嘻哈茶馆只有双王/单王/对2的底牌加倍
        if LordUtil:is2Joker(cardsList) then
            cardType = LordUtil.FUNDCARDS_MULTI_TYPE_2_JOKER
            multi = 4
        elseif LordUtil:is1Joker(cardsList) then
            cardType = LordUtil.FUNDCARDS_MULTI_TYPE_1_JOKER
            multi = 2
        elseif LordUtil:is22(cardsList) then
            cardType = LordUtil.FUNDCARDS_MULTI_TYPE_22
            multi = 2
        elseif LordUtil:isThree2(cardsList) then
            cardType = LordUtil.FUNDCARDS_MULTI_TYPE_22
            multi = 2
        -- elseif LordUtil:isFlush(cardsList) then
        --     cardType = LordUtil.FUNDCARDS_MULTI_TYPE_FLUSH
        --     multi = 3
        -- elseif LordUtil:isStaight(cardsList) then
        --     cardType = LordUtil.FUNDCARDS_MULTI_TYPE_STRAIGHT
        --     multi = 3
        -- elseif LordUtil:isAllSmall(cardsList) then
        --     cardType = LordUtil.FUNDCARDS_MULTI_TYPE_ALL_SMALL_3
        --     multi = 3
        end
    end
    return cardType, multi
end

function LordUtil:is2Joker(fundCards)
    if fundCards then
        local sumJoker = 0
        for k, v in pairs(fundCards) do
            local value = v.value
            --if log_util.isDebug() == true then
                --print(TAG, "is2Joker IN value is ", value)
            --end

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

function LordUtil:is1Joker(fundCards)
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

function LordUtil:is22(fundCards)
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

function LordUtil:isFlush(fundCards)
    if fundCards then
        if fundCards[1].color == fundCards[2].color and fundCards[1].color == fundCards[3].color then
            return true
        end
    end
    return false
end

function LordUtil:isStaight(fundCards)
    if fundCards then
        --包含大王，小王，或2，则不能为顺子
        for k, v in pairs(fundCards) do
            local value = v.value
            if value == CardPoint.POINT_BIG_JOKER or value == CardPoint.POINT_SMALL_JOKER or value == CardPoint.POINT_2 then
                return false
            end
        end
        --先按value从大到小排序
        LordUtil:sortCards(fundCards)
        if fundCards[1].value - fundCards[2].value == 1 and fundCards[2].value - fundCards[3].value == 1 then
            return true
        end
    end
    return false
end

function LordUtil:is3(fundCards)
    if fundCards then
        if fundCards[1].value == fundCards[2].value and fundCards[1].value == fundCards[3].value then
            return true
        end
    end
    return false
end

function LordUtil:isThree2(fundCards)
    if fundCards then
        if fundCards[1].value == fundCards[2].value and fundCards[1].value == fundCards[3].value and fundCards[3].value == CardPoint.POINT_2 then
            return true
        end
    end
    return false
end

-- 全小
function LordUtil:isAllSmall(fundCards)
    if fundCards then
        if fundCards then
            if fundCards[1].value < 10 and fundCards[2].value < 10 and fundCards[3].value < 10 then
                return true
            end
        end
    end
    return false
end
---------------------------------------END----------------------------------
function LordUtil:getHLCards(list)
    local cards = {}
    --if log_util.isDebug() == true then
        --print("LordUtil", vardump(list))
    --end

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
                if color == Card.LORDHL_CARD_COLOR_HEART then
                    color = CardColor.COLOR_HEART
                elseif color == Card.LORDHL_CARD_COLOR_DIAMOND then
                    color = CardColor.COLOR_DIAMOND
                elseif color == Card.LORDHL_CARD_COLOR_SPADE then
                    color = CardColor.COLOR_SPADE
                elseif color == Card.LORDHL_CARD_COLOR_CLUB then
                    color = CardColor.COLOR_CLUB
                end

                original = color * 13 + hlCard.cardpoint
            end
            table.insert(cards, original)
        end
    end
    return cards
end

function LordUtil:getPKCards(list)
    local cards = {}
    if list ~= nil and #list > 0 then
        for k, v in pairs(list) do
            local original = 0
            if v.cardCalss == 4 then
                if v.cardPoint == 13 then
                    original = 52 --小王
                else
                    original = 53 --大王
                end
            else
                --转成斗地主牌型
                local color = v.cardClass
                if color == Card.HLLORD_COLOR_HEART then
                    color = CardColor.COLOR_HEART
                elseif color == Card.HLLORD_COLOR_DIAMOND then
                    m_nColor = CardColor.COLOR_DIAMOND
                elseif color == Card.HLLORD_COLOR_SPADE then
                    m_nColor = CardColor.COLOR_SPADE
                elseif color == Card.HLLORD_COLOR_CLUB then
                    m_nColor = CardColor.COLOR_CLUB
                end
                original = color * 13 + v.cardPoint
            end
        end
    end
end

function LordUtil:sortCardsThreeFirst(cards, type)
--TODO
end

function LordUtil:selectSplitStr(str, split, index)
    local count = 0
    local pst, st, et = 1, 1, 1
    local res = nil
    repeat
        count = count + 1
        st,et = string.find(str, split, pst)
        if st and count == index then
            res = string.sub(str, pst, st-1)
        end
        if not et then break end
        pst = et+1
    until not st
    return res
end

return LordUtil

-- 人类视角的AI，只关注自己的手牌和牌桌上可见信息
--[[
AI技能点
1 谨慎炸弹(h1)
2 谨慎222(h2) 
]]--
-- 依赖的函数库
require "utils/table_util"
local func = require("ai.func")
-- 依赖的工具库
local aiUtil= require("ai.aiUtil")
local LordLogic = require("logic.LordUtil")
local CardPattern = require("logic.CardPattern")
local Card  = require("logic.Card")
local PokerTree = require("ai.PokerTree")
local Action = require("ai.Action")

local HumAI ={}
-----------------------------------------------------------
--[[
    以下是AI等级控制的参数配置
]]
-----------------------------------------------------------
-- 注意所有的控制函数，默认都是执行的,对应的是路人AI
local function getAIParam(key,currSeat)
    print("HumAI get ai  ",key,currSeat)
    local aiLevel = aiUtil.getAILevelFromMonkey(currSeat)
    local value = aiUtil.getAIParamFromMonkey(key)
    print("HumAI get ai  ",aiLevel,value)
    local f = HumAI[value]; --查找函数
    if f then 
        return f(aiLevel)
    else
        return false
    end  
end 
function HumAI.param1(aiLevel)
    print("HumAI get ai param1 ",aiLevel)
    if aiLevel == 1 and func.randomChance(7) then
        return true 
    else
        return false
    end 
end
function HumAI.param2(aiLevel)
    print("HumAI get ai param2 ",aiLevel)
    if aiLevel == 1 and func.randomChance(8) then
        return true 
    else
        return false
    end 
end
---自动注册AI等级参数
-- local function autoRegisterAIParam()
--     print("HumAI auto register ai param ")
--     registerAIParam("a1","param1","")
--     registerAIParam("a2","param2","")
-- end 
-- autoRegisterAIParam()
--模拟js的执行方式
(function()
    print("HumAI auto register ai param ")
    aiUtil.registerAIParam("h1","param1","炸弹管成型牌保护")
    aiUtil.registerAIParam("h2","param2","222管成型牌保护")    
end)()
-----------------------------------------------------------
--[[local function 区域]]--
-----------------------------------------------------------
local function normalBid(cardsPoint)
    print("Action normalBid 估值叫分")
    local myCardsObj_AI=aiUtil.pretreat_jj(cardsPoint);
    local top_rank=PokerTree.get_Highest_Value_scheme(myCardsObj_AI.noking);
    local score = Action.getSchemoScore(top_rank)
    return score
end 
-- 四种叫分函数
-- 冲动叫分
local function bidv1(cardsPoint)
    print("Action bidv1 估值叫分")
    local myCardsObj_AI=aiUtil.pretreat_jj(cardsPoint);
    local top_rank=PokerTree.get_Highest_Value_scheme(myCardsObj_AI.noking);
    local score = Action.getSchemoScore(top_rank)
    if score >= 2 then 
        aiUtil.showAlert("牌好叫地主")
        return 3 
    else
        --概率运算
        if aiUtil.hasGoodSinglev2(top_rank) then 
            return 3
        else
            return 0
        end 
    end 
end
-- 梯度叫分 
local function bidv2(cardsPoint)
    print("Action bidv2 估值叫分")
    local myCardsObj_AI=aiUtil.pretreat_jj(cardsPoint);
    local top_rank=PokerTree.get_Highest_Value_scheme(myCardsObj_AI.noking);
    local score = Action.getSchemoScore(top_rank)
    return score
end 
local function bidv3(cardsPoint,bottomsPoint)
    print("Action bidv3 估值叫分")
    local tmp = table.clone(cardsPoint)
    for i,v in ipairs(bottomsPoint) do
        table.insert(tmp,v)
    end
    local myCardsObj_AI=aiUtil.pretreat_jj(tmp);
    local top_rank=PokerTree.get_Highest_Value_scheme(myCardsObj_AI.noking);
    -- aiUtil.showAlert("偷看底牌叫分")
    local score = Action.getSchemoScore(top_rank)
    return score
end
-- 冒险型叫分 
local function bidv4(cardsPoint,bottomsPoint,playerPointCards)
    print("Action bidv4 估值叫分")
    --自己加上底牌的得分
    local tmp = table.clone(cardsPoint)
    for i,v in ipairs(bottomsPoint) do
        table.insert(tmp,v)
    end
    local myCardsObj_AI=aiUtil.pretreat_jj(tmp);
    local top_rank=PokerTree.get_Highest_Value_scheme(myCardsObj_AI.noking);
    -- 玩家的得分
    local tmp2 = table.clone(playerPointCards)
    print("here")
    --TODO 下面是tm2的时候为啥不报错也不执行了,奇怪。好像在aiUtil.pretreat_jj中遇到问题，但是也没有错误爆出来
    local playerCardsObj_AI=aiUtil.pretreat_jj(tmp2);
    local player_top_rank=PokerTree.get_Highest_Value_scheme(playerCardsObj_AI.noking);
    local aiScore,aiValue =  Action.getSchemoScore(top_rank)
    local playerScore,playerValue = Action.getSchemoScore(player_top_rank)
    print("Action bidv4 估值叫分 ai ",aiValue,"player ",playerValue)
    -- 如果ai分值高，直接叫3分抢地主,否则只返回ai的估值
    if aiValue > playerValue+10 then
        aiUtil.showAlert("偷看玩家牌叫分")
        return 3
    else
        return 0
    end
end
-----------------------------------------------------------
local function get_Next(curCardsPoint,lastHandsInfo,curSeat)
    print("HumAI get_Next"..table.concat(curCardsPoint,","))
	local tree = PokerTree.buildTree(curCardsPoint);
    local tree_info = {};
    PokerTree.findChildren(tree,tree_info)
    -- 正向排序，分值高排前面
    table.sort( tree_info, function(v1,v2) 
        return v1.score > v2.score
    end)
    local first = Action.getNextAction(tree_info, lastHandsInfo,curCardsPoint,curSeat);
    return first;
end

function HumAI.getAllCardPttern(cardsPoint)
    local tmp = table.clone(cardsPoint)
    local myCardsObj_AI=aiUtil.pretreat_jj(tmp);
    local top=PokerTree.get_Highest_Value_scheme(myCardsObj_AI.noking);
    -- {3条，大于6张的单顺，炸弹，火箭}
    local result = {false,false,false,false}
    local comp = top.data.composition
    for i,v in ipairs(comp) do
        local len = #v.pokers
        if v.cardtype == 4 then
            result[3] = true
        elseif v.cardtype==3 then
            result[1] = true 
        elseif v.cardtype == 1 then
            if len >= 6 then
                result[2] = true 
            end
        end
    end
    local hasJokers=Action.hasJokerPair(top);
    if hasJokers then
        result[4] = true
    end
    return result
end

-- 叫分方法，目前绑定到4个aiLevel上
--[[
1. 冲动叫牌：0/3
低于正常评估，但是在以下情况下仍然会叫牌：
a) 炸弹必叫 -- 概率：70%
b) 有2必叫 -- 概率：70%
c) 大牌只有A，且两A以上必叫 -- 概率：30%
2. 常规人类叫牌1,2,3
a) 根据正常估值叫
3. 谨慎叫牌1,2,3
a) 合并AI手牌和底牌后叫分>玩家手牌+10
4. 聪明叫牌0,3
a） 综合了对方实力后评估叫牌
]]--
function HumAI.bid(cardsPoint,bottomsPoint,currSeat,playerPointCards)
    -- 获取NPC等级和位置
    local NPCSeat = aiUtil.getNPCSeatFromMonkey()
     print("AI bid get NPCSeat",NPCSeat,currSeat)
    if NPCSeat == currSeat then
        local aiLevel = aiUtil.getAILevelFromMonkey(currSeat)
        print("AI bid get aiLevel",aiLevel)
        if aiLevel == 1 then 
            return bidv1(cardsPoint)
            -- Debug 手动测试 让AI叫地主
            -- return 3
        elseif aiLevel == 2 then 
            return bidv2(cardsPoint)
        elseif aiLevel == 3 then 
            return bidv3(cardsPoint,bottomsPoint)
        elseif aiLevel >= 4 then 
            return bidv4(cardsPoint,bottomsPoint,playerPointCards)
        end 
    else
        if currSeat ~= 0 then 
            -- 路人不叫分
            -- return 0
            -- 路人正常叫分
            return normalBid(cardsPoint)
        else
            --玩家手牌估值叫分，提供给外部的API
            return bidv2(cardsPoint)
        end
    end
end


-- 获取最佳出牌
function HumAI.findBetterCards(myCardsPoint,curSeat,lastHandsInfo)
    print("HumAI findBetterCards",aiUtil.printt(lastHandsInfo))
    if lastHandsInfo~=nil and #lastHandsInfo~=0 then
        -- 
    end
    local myCardsObj_AI=aiUtil.pretreat_jj(myCardsPoint);
    local points=get_Next(myCardsObj_AI.noking,lastHandsInfo,curSeat);
    -- return trans_to_jj_result(points, sortCardObj);
    return points
end

-- 选择出牌方案
function HumAI.choose(scheme,cardsPoint,currSeat)
    print("HumAI choose scheme",aiUtil.printt(scheme))
    if scheme==nil or #scheme == 0 then
        return {}
    end
    -- print(#cardsPoint)
    -- table_print(cardsPoint)
    local myCardsObj_AI=aiUtil.pretreat_jj(cardsPoint);
    local init_value=PokerTree.get_Highest_Value_scheme(myCardsObj_AI.noking);
    -- table_print(init_value)
    local scoreMap ={}
    -- 将这张牌移除后，再做估值
    -- for  k,v in pairs(scheme) do
    --      print("cardValue"..v.value)
    -- end
    -- 逐个方案执行,判断分值
    for k,v in pairs(scheme) do
        -- 每个方案里每张牌执行
        local preCardsObj = {}
        local preCardsPoint={} 
        local tmp = aiUtil.pretreat_jj(cardsPoint)
        for k2,cardObj in pairs(v) do
            local cardValue = cardObj.value;
            tmp.noking[cardValue] = tmp.noking[cardValue] -1;
            table.insert(preCardsObj,cardObj)
            table.insert(preCardsPoint,cardValue)
        end
        
        local highest=PokerTree.get_Highest_Value_scheme(tmp.noking);
        print("HumAI choose PokerTree.get_Highest_Value_scheme",highest.score)
        local scoreItme = {score=highest.score,hands_count=highest.hands_count,highest=highest,cardsObj=preCardsObj,cardsPoint=preCardsPoint}
        table.insert(scoreMap,scoreItme)
    end
    
    table.sort(scoreMap,function(a,b)
        return a.score > b.score;
    end)
    -- 取最高值
    local topScore = scoreMap[1];
    -- 解析一手牌
     table.sort( topScore.cardsObj, function(card1,card2) 
        return card1.value > card2.value
    end )
    local cardInfo =CardPattern:parseCards(topScore.cardsObj)
    print("HumAI choose handInfo",aiUtil.printt(cardInfo))
    print("HumAI 接牌前估值:",init_value.score," 接牌后估值：",topScore.score);


    if Action.isAganst(aiUtil.getLastSeatFromMonkey(),currSeat) then
        local mustTakeOut=Action.isMustTakeOut(currSeat);
        if mustTakeOut then
            print("HumAI 对手报警 强力顶牌");
            if aiUtil.getLastSeatFromMonkey() == aiUtil.getLordSeatFromMonkey() then 
                aiUtil.showAlert("你打的太好了，都报警了")
            end 
            return topScore.cardsPoint,topScore.highest;
        end
        --自己剩余手数很大,先不出王或者炸弹
        local aiLevel = aiUtil.getAILevelFromMonkey(currSeat)
        -- 一级AI基本有关必管
        --TODO 如果队友手数很小
        if topScore.hands_count>4 then
            if cardInfo.type==CardPattern.DOUBLE_JOKER or cardInfo.type==CardPattern.FOUR_CARDS  then
                if not getAIParam("h1",currSeat) then 
                    return {},topScore.highest;
                end 
            end
        end
        -- 3个2 谨慎处理
        if cardInfo.type==CardPattern.THREE_WITH_ONE or cardInfo.type==CardPattern.THREE_WITH_TWO  then
            if cardInfo.value== Card.CARD_POINT_2 then
                --剩余手牌
                local left=topScore.highest.data.leftpoker;
                -- 小牌手数(K以下)
                local leftcount=aiUtil.get_left_hand_counts(left,13);
                if leftcount>1 and topScore.hands_count>3 then
                    if not getAIParam("h2",currSeat) then 
                         return {},topScore.highest;
                    end  
                end
            end
        end
        
        -- 敌人还是有管必管吧
        -- 管完牌力比最高牌力小10就也不管,并且手数大于2手
        -- if topScore.score<init_value.score-10 and topScore.hands_count > 2 then
        --     return {};
        -- end
    else
        --如果炸完不能直接走
        --todo 多手最大牌的逻辑
        if topScore.hands_count>2  then
            if cardInfo.type==CardPattern.DOUBLE_JOKER or cardInfo.type==CardPattern.FOUR_CARDS  then
                return {},topScore.highest;
            end
        end
        -- 管完牌力比最高牌力小10就也不管,并且手数大于2手
        if topScore.score<init_value.score-10  and topScore.hands_count > 2 then
            return {},topScore.highest;
        end
    end
    return topScore.cardsPoint,topScore.highest;
end
return HumAI
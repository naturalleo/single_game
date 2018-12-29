-- 依赖的函数库
require "utils/table_util"
local func = require("ai.func")
local log_util = require "utils/log_util"
-- 依赖的工具库
local aiUtil= require("ai.aiUtil")
local CardPattern = require("logic.CardPattern")
local LordUtil = require("logic.LordUtil")
local PokerTree = require("ai.PokerTree")
local Card = require("logic.Card")

-- 人物情绪及智能
-- 由一系列打牌方法构成
local Action ={}

--抽取一些位置参数，方便各个函数调用
local lordSeat = -1
local nextSeat = -1
local lastSeat = -1
--抽取各家张数
local nextCardCount = -1
local lordCardCount = -1
local preCardCount = -1
local lastCardCount = -1

local function log_func(...)
    if log_util.isDebug() == true then
        log_util.i(TAG, ...)
    end
end

-----------------------------------------------------------
--[[
    以下是AI等级控制的参数配置
]]
-----------------------------------------------------------
local function getAIParam(key,currSeat)
    log_func("Action get ai  ",key,currSeat)
    local aiLevel = aiUtil.getAILevelFromMonkey(currSeat)
    local value = aiUtil.getAIParamFromMonkey(key)
    log_func("Action get ai  ",aiLevel,value)
    local f = Action[value]; --查找函数
    if f then 
        return f(aiLevel)
    else
        return false
    end  
end 
function Action.param1(aiLevel)
    log_func("Action get ai param1 ",aiLevel)
    if aiLevel > 3 then
        return true 
    else
        return false
    end 
end
function Action.param2(aiLevel)
    log_func("Action get ai param2 ",aiLevel)
    if aiLevel > 2 then
        return true 
    else
        return false
    end 
end
function Action.param3(aiLevel)
    log_func("Action get ai param3 ",aiLevel)
    if aiLevel > 1 then
        return true 
    else
        return false
    end 
end
function Action.param4(aiLevel)
    log_func("Action get ai param3 ",aiLevel)
    if aiLevel > 1 then
        return true 
    else
        return false
    end 
end
function Action.param5(aiLevel)
    log_func("Action get ai param5 ",aiLevel)
    if aiLevel > 1 then
        return true 
    else
        return false
    end 
end
function Action.param6(aiLevel)
    log_func("Action get ai param6 ",aiLevel)
    if aiLevel > 2 then
        return true 
    else
        return false
    end 
end
function Action.param7(aiLevel)
    log_func("Action get ai param7 ",aiLevel)
    if aiLevel > 1 then
        return true 
    else
        return false
    end 
end
function Action.param8(aiLevel)
    log_func("Action get ai param8 ",aiLevel)
    if aiLevel == 1 then
        return true 
    else
        return false
    end 
end
function Action.param9(aiLevel)
    log_func("Action get ai param9 ",aiLevel)
    if aiLevel > 2 then
        return true 
    else
        return false
    end 
end
function Action.param10(aiLevel)
    log_func("Action get ai param10 ",aiLevel)
    -- if aiLevel > 2 then
    if aiLevel > 0 then
        return true 
    else
        return false
    end 
end
function Action.param11(aiLevel)
    log_func("Action get ai param11 ",aiLevel)
    if aiLevel > 1 then
        return true 
    else
        return false
    end 
end
function Action.param12(aiLevel)
    log_func("Action get ai param12 ",aiLevel)
    -- if  aiLevel > 1 or func.randomChance(3) then -> 0
    if  aiLevel > 0  then
        return true 
    else
        return false
    end 
end
function Action.param13(aiLevel)
    log_func("Action get ai param13 ",aiLevel)
    if aiLevel > 3 or func.randomChance(3) then 
        return true 
    else
        return false
    end 
end
function Action.param14(aiLevel)
    log_func("Action get ai param14 ",aiLevel)
    if true then
        return false
    end
    if aiLevel == 1 and func.randomChance(8) then 
        return true 
    else
        return false
    end 
end
---自动注册AI等级参数
(function()
    log_func("Aciton auto register ai param ")
    -- build_domino 
    aiUtil.registerAIParam("a1","param1","拆顶对成必胜")
    -- get_special 1392
    aiUtil.registerAIParam("a2","param2","首发拆4带2成炸弹")   
    -- get_special 1417
    aiUtil.registerAIParam("a3","param3","首发会必胜计算")
    -- get_special 1460
    aiUtil.registerAIParam("a4","param4","首发单让报单队友走")
    -- get_special 1472
    aiUtil.registerAIParam("a5","param5","首发不让报单对手走")
    -- get_special 1498
    aiUtil.registerAIParam("a6","param6","首发不让报双对手走")
    -- get_special 1456
    aiUtil.registerAIParam("a7","param7","首发会争取报单/报双")
    -- getNextAction 1741
    aiUtil.registerAIParam("a8","param8","首发小牌优先")
    -- getNextAction 1786
    aiUtil.registerAIParam("a9","param9","管牌会必胜计算")
    -- getNextAction 1786
    aiUtil.registerAIParam("a10","param10","对2管牌保护")
    -- getNextAction 1786
    aiUtil.registerAIParam("a11","param11","地主会忍让")
    -- getNextAction 1786
    aiUtil.registerAIParam("a12","param12","地主上家农民会顶牌")
    -- getNextAction 1786
    aiUtil.registerAIParam("a13","param13","地主下家农民会pass让上家农民走")
    -- getNextAction 1786
    aiUtil.registerAIParam("a14","param14","地主上家农民会管下家农民牌")

end)()
------------------------------------------------------------

-- 查找最小单张(不拆对)
local function litter_single_not_split(myCards)
    log_func("Action litter_single_not_split")
    for i=3,20 do
        local tmp=myCards[i];
        if tmp == 1 then
            return  {i};
        end
    end
    return nil;
end

-- 查找最大单张
local function bigger_single(myCards)
    log_func("Action bigger_single")
    for i=19,3,-1 do
        local tmp=myCards[i];
        if tmp >0 then
            return  {i};
        end
    end
    return nil;
end
-- 查找最后一手牌
local function find_last_hand(myCards)
    log_func("Action find_last_hand")
    -- TODO 识别4带2
    local result = {}
    for i=3,20 do
        local tmp=myCards[i];
        -- 找到牌就全部添加
        if tmp > 0 then
            for j=1,tmp do
                table.insert(result,i)
            end
        end
    end
    if #result > 0 then
        return result
    else
        return nil;
    end
end
-- [[
  -- 查找最小的牌-也可以用于3带1或者3带对
  -- mode 拆牌组合
  -- start 最小的牌值
  -- stop 最大的牌值
--]]
local function litter_single_and_pair(mode,start,stop)
    log_func("Action litter_single_and_pair")
	local daipai = {};
    local begin= 3;
    local endIndex= 20;
    if start~=nil then
        begin=start;
    end
    if stop~=nil then
        endIndex=stop;
    end
    for i = begin ,endIndex do 
    	-- 优先找最小的单牌
        if mode.data.leftpoker[i] == 1 then
            daipai = {i};
            break;
        end
        if mode.data.leftpoker[i] == 2 and i < 15 then
            daipai = {i, i};
            break;
        end
    end
    return daipai;
end
-- 查找第一手的对子或者单张
local function first_litter(mode)
    log_func("Action first_litter")
   return litter_single_and_pair(mode);
end
-- 寻找最小的单张或者对子
local function find_smallest_suitable_single_and_pair(top_ranks, last, beginIndx, endIndex)
	log_func("Action find_smallest_suitable_single_and_pair")
	if beginIndx == nil then
		beginIndx = 1
	end
	if endIndex == nil then
		endIndex = 20
	end
	local result
    local topScore=top_ranks[1].score;
    for i=1,#top_ranks do
        --保护，不扫描坏的牌型组合
        --todo 坏牌型的评估依据
        if top_ranks[i].score<topScore-50 then
            break;
        end
        local leftpoker = top_ranks[i].data.leftpoker;

        for  j = beginIndx, endIndex do
            if last then
                if leftpoker[j] == last.type then
                    log_func("Action find_smallest_suitable_single_and_pair 建议出:", last.type, "张", j, "剩余:", leftpoker[j]);
                    if last.type == 1 then
                        result = {j};
                        break;
                    end 
                    if last.type == 2 then
                        result = {j, j};
                        break;
                    end
                end
            else 
                --出最小的牌
                if leftpoker[j] >0 then
                    if leftpoker[j] == 1 then
                        result = {j};
                        break;
                    end 
                    if leftpoker[j] == 2 then
                        result = {j, j};
                        break;
                    end
                end
            end
        end

        if result ~= nil then
            break;
        end
    end
    return result;
end

-- 查找长龙
local function first_long(mode)
    log_func("Action first_long")
    local result
    -- table_print(mode.data.composition)
    -- result= func.max(mode.data.composition,function(type)
    --     if type.cardtype==4 then
    --         --todo 处理炸弹逻辑
    --         return 2;
    --     end
    --     return #type.pokers;
    -- end);
    local resultLen = 0 
    for k, v in pairs(mode.data.composition) do
        --计算一下这周牌型的长度
        local count = #v.pokers
        if v.cardtype==4 then
            --炸弹特化一下，防止先放出去了
            count=2;
        end
        if count > resultLen then 
            resultLen = count
            result = v
        end
    end
    -- table_print(result)
    if result and result.cardtype<3 then
        return result.pokers;
    end
    if result and  result.cardtype==3 then
        --组装3龙
        local threeCards = table.clone(result.pokers);
        local minv = result.pokers[1]
        local tLongLen = 1
        for i,v in ipairs(mode.data.composition) do
            if v.cardtype == 3 then
                local cv = v.pokers[1]
                log_func(cv,minv,tLongLen)
                -- 2不能够组成3龙
                if cv~=15 and cv-minv == 1 then
                    table.insert(threeCards,cv)
                    table.insert(threeCards,cv)
                    table.insert(threeCards,cv)
                    minv = cv
                    tLongLen = tLongLen +1
                end
            end
        end

        if tLongLen == 1 then 
            local daipai = litter_single_and_pair(mode);
            -- 注意，可能有时候没有单牌带daipai是空数组
            if daipai[1] and daipai[1]  < 15 then          
                for k,v in pairs(daipai) do
                    table.insert(threeCards,v)
                end
                return threeCards;
            else
                return threeCards;
            end
        else
            --TODO 出了双龙还有管牌的问题
            local daipai = aiUtil.three_long_daipai(mode.data.leftpoker,tLongLen);
            if #daipai > 0 then
                for k,v in pairs(daipai) do
                    table.insert(threeCards,v)
                end
                return threeCards;
            else
                --TODO考虑缩小长度去带牌，而不是全部不带
                return threeCards;
            end
        end
    end
	return nil
end
-- 查找最小可管的牌
local function first_litter_bigthan(mode,start,stop)
    log_func("Action first_litter_bigthan")
	 return litter_single_and_pair(mode,start,stop) ;
end
-- 获取炸弹
local function getFour(pokers)
    log_func("Action getFour")
    for i, mode in pairs(pokers.data.composition) do	
        if mode and mode.type==4 then
            return mode;
        end
    end
    return nil;
end
-- 跟牌
local function follow(top_ranks,last)
     log_func("Action follow")
	 local begin =last.value+1
     local endIndex =14;
     return  find_smallest_suitable_single_and_pair(top_ranks, last, begin, endIndex);
end
--大牌逻辑（到A的大牌）
local function tryKick(top_ranks,last)
    log_func("Action tryKick")
    local begin =math.max(14,last.value+1);
    local endIndex =19;
    return  find_smallest_suitable_single_and_pair(top_ranks, last, begin, endIndex);
end

--顶牌逻辑
local function follow_big_card(top_ranks,last)
    log_func("Action follow_big_card")
    local begin =math.max(11,last.value+1);
    local endIndex =19;
    return  find_smallest_suitable_single_and_pair(top_ranks, last, begin, endIndex);
end

--拆牌顶单张
local function follow_single_split(top_ranks,last)
    log_func("Action follow_single_split")
    local begin =math.max(11,last.value+1);
    local endIndex =19;
    return  find_smallest_single_and_pair(top_ranks, last, begin, endIndex);
end

-- 拆2
local function tryKick_ex(top_ranks,last)
    log_func("Action tryKick_ex")
	local begin =math.max(15,last.value+1);
    local endIndex =20;
    local top_hand=top_ranks[1].data;
    local result=nil;
    for i=begin,endIndex do
        if top_hand.leftpoker[i]>=last.type then
            if last.type == 1 then
                result = {i};
                break;
            end
            if last.type == 2 then
                result = {i,i};
                break;
            end
        end
    end
    return  result;
end

-- 判断对家是否有炸弹和火箭
local function isAganstHasBoom(currSeat,lordSeat)
    local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
    local allSeat = {0,1,2}
    table.remove(allSeat,lordSeat+1)
    local preSeat = allSeat[1]
    local nextSeat = allSeat[2]
    local  result = false
    --构造一个虚拟的到A的顶顺
    local handInfo =  {type=CardPattern.SINGLE_DRAGON,value=14,length=5}
    if currSeat == lordSeat then
        -- 判断2家
         local tipCards = LordUtil:prompt(totalObjCards[preSeat+1],handInfo,nil);
         local tip2Cards = LordUtil:prompt(totalObjCards[nextSeat+1],handInfo,nil);
        if tipCards or tip2Cards then
            result  = true
        end
    else
        -- 判断1家
        local tip3Cards = LordUtil:prompt(totalObjCards[lordSeat+1],handInfo,nil);
        if tip3Cards then
            result  = true
        end
    end
    --TODO 大家都有炸弹，我的炸弹大的情况
    log_func("Action isAganstHasBoom ",result)
    return result
end
--TODO 下面函数可以做到工具函数中
-- 查找队友位置
local function getTeamSeat(currSeat,lordSeat)
    local allSeat = {0,1,2}
    local teamSeat
    for i,v in ipairs(allSeat) do
       if v ~= currSeat and v ~= lordSeat then
            teamSeat = v 
            break
       end
    end
    log_func("Action getTeamSeat ",currSeat,lordSeat,teamSeat)
    return teamSeat
end
-- 查找下家位置
local function getNextSeat(currSeat)
    local nextSeat = (currSeat==2 and 0 ) or currSeat+1;
    log_func("Action nextSeat ",currSeat,nextSeat)
    return nextSeat
end
-- 判断一手牌是否大牌
local function isBiggest(handInfo,currSeat,lordSeat)
    local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
    local allSeat = {0,1,2}
    table.remove(allSeat,lordSeat+1)
    local preSeat = allSeat[1]
    local nextSeat = allSeat[2]
    local  result = false
    if currSeat == lordSeat then
         local tipCards = LordUtil:prompt(totalObjCards[preSeat+1],handInfo,nil);
         local tip2Cards = LordUtil:prompt(totalObjCards[nextSeat+1],handInfo,nil);
         if tipCards == nil and tip2Cards==nil  then
           result =true
         end
    else 
        local tip3Cards = LordUtil:prompt(totalObjCards[lordSeat+1],handInfo,nil);
        if tip3Cards == nil then
            result = true
        end
    end
    return result
end
--------------------------------------------------------------------------
--构建domino相关
--------------------------------------------------------------------------
-- 分割对子扩充domino模型，增加胜率
local function extend_domino_by_split_pair(domino,left,totalMin,currSeat,lordSeat)
    log_func("Action extend_domino_by_split_pair ",aiUtil.printt(domino),aiUtil.printt(left),totalMin)
    local len =  #domino[5]
    for i=len,1,-1 do
        local v = domino[5][i]
        -- 对子本身就小，拆的意义就不大
        if v.biggest then
            local cardPoint = v.pokers[1]
            local handInfo = {type=CardPattern.SINGLE_CARD,value=cardPoint,length=1}
            local biggest = isBiggest(handInfo,currSeat,lordSeat) 
            -- 重新构造
            local rebuild = function ()
                -- 多增加一手，单牌增加一手大牌，对子减少一手大牌
                totalMin = totalMin +1
                left[5] = left[5] -1 
                left[6] = left[6] +1 
                -- 调整多米诺模型
                table.remove(domino[5],i)
                local tmp = {
                    biggest = true,
                    cardtype = 1,
                    pokers = {
                        cardPoint
                    }
                }
                table.insert(domino[6],tmp)
                -- 注意必须table.clone一下，否则第2个值不会添加
                table.insert(domino[6],table.clone(tmp))
            end
            if biggest then
                rebuild()
            else
                -- 对2其实有一张2是大的情况,但是本身对2已经是大的，手数不会增加
                -- 顶对并且没有小双牌的时候，也可以拆
                if cardPoint == 15 and left[5] >= 0  then
                    rebuild()
                else
                    break;
                end
            end
        else
            break;
        end
    end
    -- TODO 单牌也许需要再排序一下
    log_func("Action extend_domino_by_split_pair result ",aiUtil.printt(domino),aiUtil.printt(left),totalMin)
    return totalMin
end
--从一组数中查找连续的数
--TODO有bug刚好是个序列的时候
local function findSerialNumber(numbs)
    local result  ={}
    local s  = 1
    local e = 1
    for i=2,#numbs do
      if numbs[i] == numbs[i-1]+1 then
        e = i
      else
        if e~=s then
          -- local  tmp = {}
          -- for a=s,e do
          --     table.insert(tmp,numbs[a])
          -- end
          -- if #tmp >0  then
          --   table.insert(result,tmp)
          -- end
          for a=s,e do
              table.insert(result,numbs[a])
          end
        end
        s = i
      end
    end
    return result 
end
-- 3条变形成3龙
local function threeDragonTransform(threeCards)
    -- 已经排过序
    log_func("Action threeDragonTransform",aiUtil.printt(threeCards))
    local  cardPoints = {}
    for i,v in ipairs(threeCards) do
        local cardPoint = v.pokers[1]
        --排除3带2
        if cardPoint <15 then
            table.insert(cardPoints,cardPoint)
        end
    end
    local three = findSerialNumber(cardPoints)
    if #three > 0 then 
        return #three,three
    else
        return 0,nil
    end
end
-- 构造多米诺
local function build_domino(top_ranks,currSeat,lordSeat,lastHandsInfo)
    --解析成型牌
    local comp = top_ranks.data.composition
    local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
    local domino = {{},{},{},{},{},{}}
    local handInfo = {}
    local biggest = false
    -- 全牌型大牌手数，可以覆盖任何手牌,主要是炸弹带来的
    local max_count = 0
    -- 可以三带的牌
    local singe_double_max_count = 0
    --4四条,3条,2双顺,1顺子,5对子，6单张,7双王
    --可罩牌数组，可用来罩小牌
    local left = {0,0,0,0,0,0,0}
    for i,v in ipairs(comp) do
        local len = #v.pokers
        if v.cardtype == 4 then
            table.insert(domino[1],v)
        elseif v.cardtype==3 then
            table.insert(domino[2],v)
            handInfo = {type=CardPattern.THREE_CARDS,value=v.pokers[1],length=3}
            singe_double_max_count = singe_double_max_count+1
        elseif v.cardtype == 2 then
            table.insert(domino[3],v)
            --长龙用大牌值表示
            handInfo = {type=CardPattern.DOUBLE_DRAGON,value=v.pokers[len],length=len}
        elseif v.cardtype == 1 then
            table.insert(domino[4],v)
            handInfo = {type=CardPattern.SINGLE_DRAGON,value=v.pokers[len],length=len}
        end
        if handInfo.value  then
            biggest = isBiggest(handInfo,currSeat,lordSeat)
            v.biggest = biggest
        end
    end
    local leftpoker = top_ranks.data.leftpoker;
    -- 处理余下的牌
    for i=3,15 do
        if leftpoker[i] == 2 then
            handInfo = {type=CardPattern.DOUBLE_CARDS,value=i,length=2}
            biggest = isBiggest(handInfo,currSeat,lordSeat) 
            table.insert(domino[5],{biggest=biggest,cardtype=2,pokers={i,i}})
        elseif leftpoker[i] == 1 then
            handInfo = {type=CardPattern.SINGLE_CARD,value=i,length=1}
            biggest = isBiggest(handInfo,currSeat,lordSeat) 
            table.insert(domino[6],{biggest=biggest,cardtype=1,pokers={i}})
        end
    end
    --接着单牌中的大小王(保证单牌从小到大的顺序)
    local hasJokers=Action.hasJokerPair(top_ranks);
    if hasJokers then 
       domino[7] = true
       left[7] =1 
    else
        left[7] =0
        -- 大王
        if leftpoker[17] >0 then
            table.insert(domino[6],{biggest=true,cardtype=1,pokers={17}})
        end
        -- 小王
        if leftpoker[16] >0 then
            handInfo = {type=CardPattern.SINGLE_CARD,value=16,length=1}
            -- TODO 单牌和对子可以直接比较嘛,优化性能
            biggest = isBiggest(handInfo,currSeat,lordSeat) 
            table.insert(domino[6],{biggest=biggest,cardtype=1,pokers={16}})
        end
    end
    -- log_func("Action domino scheme",aiUtil.printt(domino))
    --逻辑分析
    --炸弹
    left[1] = #domino[1]
    --三条
    local three_count = #domino[2]
    local max_three_cards ={}
    local min_three_cards ={}
    if #domino[2]>0 then
        for i,v in ipairs(domino[2]) do
            if v.biggest then
                table.insert(max_three_cards,v)
            else
                table.insert(min_three_cards,v)
            end
        end
        if #max_three_cards >= #min_three_cards then
            log_func("Acton domino 3tiao da ")
            left[2] = #max_three_cards - #min_three_cards
        else
            local tmp = #max_three_cards - #min_three_cards
            log_func("Acton domino 3tiao xiao ",tmp)
            --看看小三条有没有3龙的机会
            local tdc,td = threeDragonTransform(min_three_cards)
            if tdc  > 0 then 
                 log_func("Action domino 3龙组装")
            end
            left[2] = #max_three_cards - #min_three_cards + tdc
        end
    end
    -- 双顺 
    local max_double_dragon_cards  ={}
    local min_double_dragon_cards = {}
    if #domino[3]>0 then
        for i,v in ipairs(domino[3]) do
            if v.biggest then
                table.insert(max_double_dragon_cards,v)
            else
                table.insert(min_double_dragon_cards,v)
            end
        end
        if #max_double_dragon_cards >= #min_double_dragon_cards then
            log_func("Acton domino shuangshun da ")
            left[3] = #max_double_dragon_cards - #min_double_dragon_cards
        else
            left[3] = #max_double_dragon_cards - #min_double_dragon_cards
            log_func("Acton domino shuangshun xiao ",tmp)
        end
    end
    -- 顺子
    local max_single_dragon_cards  ={}
    local min_single_dragon_cards = {}
    if #domino[4]>0 then
        for i,v in ipairs(domino[4]) do
            if v.biggest then
                table.insert(max_single_dragon_cards,v)
            else
                table.insert(min_single_dragon_cards,v)
            end
        end
        -- TODO 顺子不同长度不能够互相管，所以不能够直接的结算大牌/小牌
        if #max_single_dragon_cards >= #min_single_dragon_cards then
            log_func("Acton domino shunzi da ")
            left[4] = #max_single_dragon_cards - #min_single_dragon_cards
        else
            left[4] = #max_single_dragon_cards - #min_single_dragon_cards
            log_func("Acton domino shunzi xiao ",tmp)
        
        end
    end
    --对子
    local max_double_cards  ={}
    local min_double_cards = {}
    if #domino[5]>0 then
        for i,v in ipairs(domino[5]) do
            if v.biggest then
                table.insert(max_double_cards,v)
            else
                table.insert(min_double_cards,v)
            end
        end
        
        if #max_double_cards >= #min_double_cards then
            log_func("Acton domino duizi da ")
            left[5] = #max_double_cards - #min_double_cards
        else
            local tmp = #max_double_cards - #min_double_cards
            --统一补余，这样补了会导致误认为对子是大牌
            --3条补余  
            -- if singe_double_max_count > 0 then
            --     tmp = singe_double_max_count + tmp
            --     singe_double_max_count = singe_double_max_count + (#max_double_cards - #min_double_cards)
            -- end
            --最多补余到0
            -- if tmp > 0 then
            --     tmp = 0
            -- end
            left[5] = tmp
            log_func("Acton domino duizi xiao ",tmp,singe_double_max_count)
        end
    end
    -- 单牌
    local max_single_cards  ={}
    local min_single_cards = {}
    if #domino[6]>0 then
        for i,v in ipairs(domino[6]) do
            if v.biggest then
                table.insert(max_single_cards,v)
            else
                table.insert(min_single_cards,v)
            end
        end
        if #max_single_cards >= #min_single_cards then
            left[6] = #max_single_cards - #min_single_cards
            log_func("Acton domino danpai da ")
        else
            local tmp = #max_single_cards - #min_single_cards
            -- 用3带补余
            -- if singe_double_max_count > 0 then
            --     tmp = singe_double_max_count + tmp
            -- end
            left[6] = tmp
            log_func("Acton domino danpai xiao ",tmp)
            --炸弹、火箭、四带2、三条拆、拆双王
        end
    end

    --{炸弹数,3条手数，双顺手数，顺子手数，对子手数，单张手数，双王}
    local isDomino = true
    --只记小牌手数，因为小牌手数和大牌手数不能够抵消
    local totalMin = 0
    for i,v in ipairs(left) do
        if v < 0 then 
            isDomino = false
            totalMin = totalMin +v
        end
    end
    -- TODO 下面代码是否影响了domino的认证
    -- 3带减少手数,补余
    -- modify by yoo at 2014年12月5日14:31:08 
    -- 3带减少手数的时候，需要注意又有3带2又有3带1不能够互相罩，需要减少一下手数
    if singe_double_max_count > 0 then
       local m = 0 
       if left[5] < 0 then 
        m = m - left[5]
       end 
       if left[6] < 0 then 
        m = m - left[6]
       end
       if m > 0 then
            if singe_double_max_count <= m then 
            totalMin = totalMin + singe_double_max_count
            singe_double_max_count =0
           else
            totalMin = totalMin + m
            -- TODO　不太精确
            singe_double_max_count =0
            end 
       end
       if left[5] < 0 and left[6] < 0 and singe_double_max_count > -left[5] then 
            totalMin = totalMin -1
       end  
    end
    if totalMin == 0 then 
        isDomino = true
    end 
    --TODO 首发的时候神龙摆尾就必胜了，不需要进行extend
    if not isDomino then 
        --炸弹火箭罩全场
        if left[1]+left[7] + totalMin > 0 then
            isDomino = true
            log_func("可能用炸弹补齐")
        end
        --TODO 2222, 22，AA，222 等牌型可以考虑拆了当单牌盖，增加必胜手数
        --可能调整估值函数就能够做到
        -- 不够神龙摆尾的时候才考虑拆牌
        if totalMin < -1 then
            --拆2对
            if getAIParam("a1",currSeat) then
                totalMin = extend_domino_by_split_pair(domino,left,totalMin,currSeat,lordSeat)
            end 
            if totalMin <-1 then
                --还不够就考虑拆3条
                -- TODO 
                -- totalMin = extend_domino_by_split_three(domino,left,totalMin,currSeat,lordSeat)
            end
            --TODO 残局10 2644333
        end
        -- for 残局 1 
        if totalMin == -1 and top_ranks.hands_count == 2 then
            -- 拆顶对
            if getAIParam("a1",currSeat) then 
                totalMin = extend_domino_by_split_pair(domino,left,totalMin,currSeat,lordSeat)
            end  
            if totalMin == 0 then 
                isDomino = true
            end
            -- 对应26333这样的残局情况
            if singe_double_max_count >= 1 then 
                isDomino = true
            end 
        end
    end

    return isDomino,totalMin,domino,left
end
-- 分割3条扩充domino模型，增加胜率
local function extend_domino_by_split_three(domino,left,totalMin,currSeat,lordSeat)
    log_func("Action extend_domino_by_split_three ",aiUtil.printt(domino),aiUtil.printt(left),totalMin)
    local len =  #domino[2]
    local splitSingle = {}
    for i=len,1,-1 do
        local v = domino[2][i]
        if v.biggest then
            local cardPoint = v.pokers[1]
            local handInfo = {type=CardPattern.SINGLE_CARD,value=cardPoint,length=1}
            local biggest = isBiggest(handInfo,currSeat,lordSeat) 
            if biggest then
                -- 多增加一手，单牌增加一手大牌
                totalMin = totalMin +1
                table.insert(splitSingle,cardPoint)
                left[5] = left[5] -1 
                left[6] = left[6] +1 
                -- 调整多米诺模型
                table.remove(domino[5],i)
                local tmp = {
                    biggest = true,
                    cardtype = 1,
                    pokers = {
                        cardPoint
                    }
                }
                table.insert(domino[6],tmp)
                -- 注意必须table.clone一下，否则第2个值不会添加
                table.insert(domino[6],table.clone(tmp))
            else
                -- TODO 对2其实有一张2是大的情况,但是本身对2已经是大的，手数不会增加
                break;
            end
        else
            break;
        end
    end
    -- TODO 单牌需要再排序一下
    log_func("Action extend_domino_by_split_three result ",aiUtil.printt(domino),aiUtil.printt(left),totalMin)
    return totalMin
end
-------------------------------------------------------
--使用domino相关
-------------------------------------------------------
-- 设置协作标示
local function set_need_pass_flag(currSeat,lordSeat,flag)
    --电脑和电脑配合才需要标示,也就是玩家是地主
    if lordSeat == 0 then
        aiUtil.setValue2Storage("needPass",flag)
    end
end
-- 从多米诺中查找最大牌进行拦截
local function find_biggest_in_domino( domino,left,lastHandsInfo,currSeat,lordSeat)
    log_func("Action find_biggest_in_domino domino",aiUtil.printt(domino),aiUtil.printt(left),aiUtil.printt(lastHandsInfo))
    local  result = nil
    if lastHandsInfo then 
        if lastHandsInfo.type == 1 then
            local singles  = domino[6]
            local count = #singles
            --对手张数小于5张，比较凶险了，从大往小出
            if nextCardCount < 5 and lordSeat == nextSeat then 
                --从大往小管
                for i=count,1,-1 do
                    local v  = singles[i]
                    if v.pokers[1] > lastHandsInfo.value then 
                        result = {v.pokers[1]}
                        break;
                    end
                end
            else
                --自己单牌还有小牌
                if left[6] < 0  then 
                    --从小往大管
                    for i=1,count do
                        local v  = singles[i]
                        if v.pokers[1] > lastHandsInfo.value then 
                            result = {v.pokers[1]}
                            break
                        end
                    end 
                else
                   --从大往小管
                    for i=count,1,-1 do
                        local v  = singles[i]
                        if v.pokers[1] > lastHandsInfo.value then 
                            result = {v.pokers[1]}
                            break;
                        end
                    end 
                end 
            end 
            --拆顶对补齐
            if result == nil then 
                local doubles = domino[5]
                local maxLen = #doubles
                if doubles[maxLen] then
                    local v  = doubles[maxLen]
                    local cardPoint = v.pokers[1]
                    local handInfo = {type=CardPattern.SINGLE_CARD,value=cardPoint,length=1}
                    local biggest = isBiggest(handInfo,currSeat,lordSeat)  
                    if biggest and cardPoint > lastHandsInfo.value then
                        log_func("Action find_biggest_in_domino domino top doubles splite",cardPoint)
                        result = {cardPoint}
                    end 
                end 
            end
            --拆顶顺拦截
            if result == nil then 
                local singleDragons = domino[4]
                local maxLen = #singleDragons
                if singleDragons[maxLen] then
                    local dragon  = singleDragons[maxLen].pokers
                    local dragonLen = #dragon
                    -- 大于5的顺子才可以拆
                    if dragonLen > 5 then 
                        local cardPoint = dragon[dragonLen]
                        local handInfo = {type=CardPattern.SINGLE_CARD,value=cardPoint,length=1}
                        local biggest = isBiggest(handInfo,currSeat,lordSeat)  
                        if biggest and cardPoint > lastHandsInfo.value then
                            log_func("Action find_biggest_in_domino domino top dragon splite",cardPoint)
                            result = {cardPoint}
                        end 
                    end 
                end 
            end 
        elseif lastHandsInfo.type == 2 then
            local doubles = domino[5]
            local count = #doubles
            --对手张数小于5张，比较凶险了，从大往小出
            if nextCardCount < 5 and lordSeat == nextSeat then 
                --从大往小管
                for i=#doubles,1,-1 do
                    local v  = doubles[i]
                    if v.pokers[1] > lastHandsInfo.value then 
                        result = {v.pokers[1],v.pokers[1]}
                        break;
                    end
                end
            else
                --自己双牌还有小牌
                if left[5] < 0  then 
                    --从小往大管
                    for i=1,count do
                        local v  = doubles[i]
                        if v.pokers[1] > lastHandsInfo.value then 
                            result = {v.pokers[1]}
                            break
                        end
                    end 
                else
                   --从大往小管
                    for i=#doubles,1,-1 do
                        local v  = doubles[i]
                        if v.pokers[1] > lastHandsInfo.value then 
                            result = {v.pokers[1],v.pokers[1]}
                            break;
                        end
                    end 
                end 
            end 
            --拆3条补齐
            if result == nil then
                -- local threes = domino[2]
                ---  
            end 
        end
        --TODO 炸弹或者王进行拦截
    else
        -- TODO 除了这种按照顺序，应该优先考虑牌值小的牌型先出去
        -- 查找大牌
         for i=2,6 do
            if left[i] >= 0 and #domino[i] > 0  then
                --同一牌型如此，不同牌型则不一定
                --不同牌型会形成摆尾，不会进入这里,所以理论上应该没有问题
                local len = #domino[i]
                result =  domino[i][len].pokers
                if result then
                    if i == 2 then
                        --带的时候应该是优先带left<0中的牌
                        if left[6] < 0 then 
                            local smallSingle = domino[6][1]
                            local sv = smallSingle.pokers[1]
                            if sv < 15 then
                                table.insert(result,sv)
                                break
                            end 
                        end 
                        if left[5] < 0 then 
                            local smallDouble = domino[5][1]
                            local dv = smallDouble.pokers[1]
                            if dv < 14 then
                                table.insert(result,dv)
                                table.insert(result,dv)
                                break
                            end 
                        end
                        --带单
                        if #domino[6] > 0 then
                            --2和王特化一下,防止放3带出去
                            local sv = domino[6][1].pokers[1]
                            if sv < 15 then
                                table.insert(result,sv)
                                break
                            end 
                        end
                        if #domino[5] > 0 then
                            --带双
                            local dv = domino[5][1].pokers[1]
                            if dv < 14 then
                                table.insert(result,dv)
                                table.insert(result,dv)
                                break
                            end 
                        end 
                    end
                    -- 都没有就3不带了
                    break;
                end
            end
        end
    end    
    return result
end
--从多米诺中查找大牌（可以管的或者有自己管的）
--TODO 位置分支
local function find_bigger_in_domino(domino,left,lastHandsInfo)
    log_func("Action find_bigger_in_domino lastHandsInfo",aiUtil.printt(lastHandsInfo))
    --从前往后，碰到-1跳过
    --其实也是先打有回收的牌
    local  result = nil
    if lastHandsInfo then
        --牌型也只有单张或者顺子
        if lastHandsInfo.type == 1 then
            local singles  = domino[6]
            for i,v in ipairs(singles) do
                if v.pokers[1] > lastHandsInfo.value then 
                    --从小往大管
                    result = {v.pokers[1]}
                    break;
                end
            end
        elseif lastHandsInfo.type == 2 then
            local doubles = domino[5]
            for i,v in ipairs(doubles) do
                if v.pokers[1] > lastHandsInfo.value then 
                    --从小往大管
                    result = {v.pokers[1],v.pokers[1]}
                    break;
                end
            end
        end
        --没对子和单张管考虑用炸弹
    else
        for i=2,6 do
            if left[i] >= 0 and #domino[i] > 0  then
                result =  domino[i][1].pokers
                -- TODO 优化一下，不空放大牌(比如22,3,4,王的残局，就不要还是从对开始打)
                if result then
                    if i == 2 then
                        -- --优先带单
                        -- if #domino[6] > 0 then
                        --     --2和王特化一下,防止放3带出去
                        --     local sv = domino[6][1].pokers[1]
                        --     if sv < 15 then
                        --         table.insert(result,sv)
                        --     end 
                        -- elseif #domino[5] > 0 then
                        --     --带双
                        --     local dv = domino[5][1].pokers[1]
                        --     if dv < 14 then
                        --         table.insert(result,dv)
                        --         table.insert(result,dv)
                        --     end 
                        -- end 
                        -- 调整下优先带小的出去
                        local sv ,dv
                        if #domino[6] > 0 then
                            --2和王特化一下,防止放3带出去
                            sv = domino[6][1].pokers[1]
                            if sv >= 15 then
                                sv = nil
                            end 
                        end
                        if #domino[5] > 0 then
                            --带双
                            dv = domino[5][1].pokers[1]
                           if dv >= 14 then
                                dv = nil
                            end  
                        end 
                        -- TODO 无论之前的是单牌优先还是现在的小牌优先，都不是特别好的策略
                        log_func("Action find_bigger_in_domino lastHandsInfo",sv,dv)
                        if sv and dv then
                            --TODO 其实还应该考虑3条个数，是否可以回收
                            --有小单牌
                            if  left[6] < 0 then 
                                table.insert(result,sv)
                                break
                            end 
                            --有小双牌
                            if  left[5] < 0 then 
                                table.insert(result,dv)
                                table.insert(result,dv)
                                break
                            end  
                            --都存在着优先带小的出去
                            if sv < dv then 
                                table.insert(result,sv)
                            else
                                table.insert(result,dv)
                                table.insert(result,dv)
                            end 
                        else
                            if sv then 
                                table.insert(result,sv)
                            elseif dv then 
                                table.insert(result,dv)
                                table.insert(result,dv)
                            end 
                        end 
                    end
                    -- 都没有就3不带了
                    break;
                end
            end
        end
    end
    return result
end
-- 判断友军是否有最大牌
local function isTeamHasBiggest(handInfo,currSeat,lordSeat)
    local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
    local teamSeat = getTeamSeat(currSeat,lordSeat)
    local result = false
    local teamPointCards = {}
    local lordPointCards = {}
    for i,v in ipairs(totalObjCards[teamSeat+1]) do
        table.insert(teamPointCards,v.value)
    end
    for i,v in ipairs(totalObjCards[lordSeat+1]) do
        table.insert(lordPointCards,v.value)
    end

    local tmp1 = table.clone(teamPointCards)
    local teamCardsObj_AI=aiUtil.pretreat_jj(tmp1)
    local tmp2 = table.clone(lordPointCards)
    local lordCardsObj_AI=aiUtil.pretreat_jj(tmp2);

    --TODO 比较一下3个人的手数
    local teamCards = PokerTree.get_Highest_Value_scheme(teamCardsObj_AI.noking);
    local lordCards = PokerTree.get_Highest_Value_scheme(lordCardsObj_AI.noking);
    local teampoker = teamCards.data.leftpoker;
    local lordpoker = lordCards.data.leftpoker;
    -- 对子是否有最大
    if handInfo.type == 2 then
        local teamCount = 0
        local lordCount = 0
        for i=20,1,-1 do
          if teampoker[i] ==2 then
            teamCount = i
            break
          end
        end
        for i=20,1,-1 do
          if lordpoker[i] ==2 then
            lordCount = i
            break
          end
        end
        -- 采用绝对大小，提高精度
        if teamCount >lordCount then
          result = true
        end
        log_func("Action isTeamHasBiggest 对子 ",result,teamCount,lordCount)
    end
    -- 单张(目前不破对)
    if handInfo.type == 1 then
        local teamCount = 0
        local lordCount = 0
        --TODO >1 可能也可以
        for i=20,1,-1 do
          if teampoker[i] ==1 then
            teamCount = i
            break
          end
        end
        for i=20,1,-1 do
          if lordpoker[i] ==1 then
            lordCount = i
            break
          end
        end
        if teamCount >lordCount then
          result = true
        end
        log_func("Action isTeamHasBiggest 单张 ",result,teamCount,lordCount)
    end

    log_func("Action isTeamHasBiggest ",result)
    return result
end
-- 从多米诺中找队友最大的牌
local function find_team_biggest_in_domino(domino,left,currSeat,lordSeat)
    log_func("Action find_team_biggest_in_domino domino",aiUtil.printt(domino),aiUtil.printt(left))
    local  result = nil
    --4四条,3条,2双顺,1顺子,5对子,6单张,7双王
    local CARD_TYPE = {4,3,21,20,2,1}
    -- 基本值做单和双,（外加可能放3条），放顺子太假
     for i=5,6 do
        if  #domino[i] > 0  then
            result =  domino[i][1].pokers
            --判断友军是否有可以管的牌
            if result then
                --构造成handinfo
                local handInfo = {type=CARD_TYPE[i],value=result[1],length=CARD_TYPE[i]}
                log_func("Action find_team_biggest_in_domino handInfo",aiUtil.printt(result),aiUtil.printt(handInfo))
                local check = isTeamHasBiggest(handInfo,currSeat,lordSeat)
                if check then
                    break
                else
                    --找不到队友具有最大牌型
                    result = nil
                end
            end
        end
    end
    -- 拆对放单给队友
    if #domino[6] == 0 and result == nil then 
        if domino[5][1] then 
             result =  domino[5][1].pokers
            --判断友军是否有可以管的牌
            if result then
                --构造成handinfo
                local singleValue = result[1]
                local handInfo = {type=CARD_TYPE[6],value=singleValue,length=CARD_TYPE[6]}
                log_func("Action find_team_biggest_in_domino handInfo",aiUtil.printt(result),aiUtil.printt(handInfo))
                local check = isTeamHasBiggest(handInfo,currSeat,lordSeat)
                if check then
                    result = {singleValue}
                else
                    --找不到队友具有最大牌型
                    result = nil
                end
            end
        end
    end 
    

    --TODO 不要把大牌放出去了比如22，aa之类空放出去
    if result and result[1] > 10 then 
        result = nil
    end
    return result
end
-- 参考多米诺，找队友(报警)能够过的牌(可能会拆掉多米诺)
local function find_team_bigger_ref_domino(domino,left,currSeat,lordSeat)
    log_func("Action find_team_bigger_ref_domino domino",aiUtil.printt(domino),aiUtil.printt(left))
    local  result = nil

    local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
    local teamSeat = getTeamSeat(currSeat,lordSeat)
    local teamPointCards = {}
    local currPointCards = {}
    for i,v in ipairs(totalObjCards[teamSeat+1]) do
        table.insert(teamPointCards,v.value)
    end
    for i,v in ipairs(totalObjCards[currSeat+1]) do
        table.insert(currPointCards,v.value)
    end
    local teamCardsObj_AI=aiUtil.pretreat_jj(teamPointCards)
    local teampoker = teamCardsObj_AI.noking;
    local currCardsObj_AI=aiUtil.pretreat_jj(currPointCards)
    local currpoker = currCardsObj_AI.noking;
    log_func("Action find_team_bigger_ref_domino domino",aiUtil.printt(teampoker),aiUtil.printt(currpoker))
    for i=1,20 do
        local value = teampoker[i]
        -- 单张或者2单
        if value == 1 then 
            for j=1,20 do
                if currpoker[j]>=1 and j<i then
                    result ={j}
                    break;
                end
            end
        elseif value == 2 then 
            -- 一对
            for k=1,20 do
                if currpoker[k]>=2 and k<i then
                    result ={k,k}
                    break;
                end
            end
        end
        if result then
            break
        end
    end
    return result
end
-- 判断友军是否有大牌
local function isTeamHasBigger(handInfo,currSeat,lordSeat)
    local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
    local teamSeat = getTeamSeat(currSeat,lordSeat)
    local  result = false
    local tip3Cards = LordUtil:prompt(totalObjCards[teamSeat+1],handInfo,nil);
    if tip3Cards ~= nil then
        result = true
    end
    log_func("Action isTeamHasBigger ",result)
    return result
end 
-- 从多米诺中找队友可以管的牌
local function find_team_bigger_in_domino(domino,left,currSeat,lordSeat)
    log_func("Action find_team_bigger_in_domino domino",aiUtil.printt(domino),aiUtil.printt(left))
    local  result = nil
    --4四条,3条,2双顺,1顺子,5对子,6单张,7双王
    local CARD_TYPE = {4,3,21,20,2,1}
    -- 基本值做单和双,（外加可能放3条），放顺子太假
     for i=5,6 do
        if left[i] < 0 and #domino[i] > 0  then
            result =  domino[i][1].pokers
            --判断友军是否有可以管的牌
            if result then
                --构造成handinfo
                local handInfo = {type=CARD_TYPE[i],value=result[1],length=CARD_TYPE[i]}
                log_func("Action find_team_bigger_in_domino handInfo",aiUtil.printt(handInfo))
                local check = isTeamHasBigger(handInfo,currSeat,lordSeat)
                if check then
                    break
                end
            end
        end
    end
    return result
end
-- 获取多米诺出牌方式，出一手管一手
-- 目标，找出自己的获胜模式/找出对手难受的点/找出队友爽的点
local function get_domino(top_ranks,currSeat,lordSeat,lastHandsInfo)
    log_func("Action get_domino toprank",aiUtil.printt(top_ranks),aiUtil.printt(lastHandsInfo))
    if isAganstHasBoom(currSeat,lordSeat) then
        log_func("Action get_domino aganst has boom")
        aiUtil.showAlert("嗅到一股危险的味道,不妙，不妙")
        return nil
    end
   
    -- 识别初级豆豆
    -- local isDouDou =  isDoudou()

    local isDomino,totalMin,domino,left = build_domino(top_ranks,currSeat,lordSeat,lastHandsInfo)
    --TODO 精确的估算结果干扰
    --每手牌都能够罩住，基本能够必胜
    --虽然是必胜模式，必胜模式只是理论上的，但是如果被卡位了，或者放走对手了，可能还是没法必胜
    log_func("Action domino  mode",isDomino,aiUtil.printt(left),totalMin)
    local position = {"","右手机器人","左手机器人"}
    local name = position[currSeat+1];
    if isDomino then 
        --TODO 存在对手插底，然后把对手放走的bug。对手插底时候，是以小牌决定必胜，而不是用大牌带小牌的方式。
        local  result = nil
        --只处理首出
        if lastHandsInfo == nil then
            
            set_need_pass_flag(currSeat,lordSeat,true)
            -- 就2手牌时候，优先出大牌防止被拦截
            if top_ranks.hands_count == 2  then
                aiUtil.showAlert(name.."投降输一半") 
                result = find_biggest_in_domino(domino,left,lastHandsInfo,currSeat,lordSeat)
            else
                aiUtil.showAlert(name.."进入多米诺骨牌")
                result = find_bigger_in_domino(domino,left,lastHandsInfo)
            end
        else
            -- 自己能走就走
            result = find_biggest_in_domino(domino,left,lastHandsInfo,currSeat,lordSeat)
            if result then 
                aiUtil.showAlert(name.."进入我的主场我做主")
            else
                aiUtil.showAlert(name.."客场不能够上手,上手我就走")
            end
        end
        log_func("Action domino 0  return",aiUtil.printt(result))
        return result
    else 
        --余一手，神龙摆尾
        if totalMin == -1 then
            if lastHandsInfo == nil then
                aiUtil.showAlert(name.."进入神龙摆尾")
                --写标示到内存中，下家就别管
                set_need_pass_flag(currSeat,lordSeat,true)    
                local  result = find_bigger_in_domino(domino,left,lastHandsInfo)
                log_func("Action domino -1 return",aiUtil.printt(result))
                return result
            else
                -- 先用顺管试试
                -- 不精确
                -- local  result = find_bigger_in_domino(domino,left,lastHandsInfo)
                -- log_func("Action domino -1 return",aiUtil.printt(result))
                -- if result then 
                --     aiUtil.showAlert(name.."进入马上要离开")
                -- end
                -- return result
            end
        end
        if totalMin < -1 then
            --是地主上家
            if currSeat ~= lordSeat and getNextSeat(currSeat) == lordSeat then
                if lastHandsInfo == nil then
                    local cardCount = aiUtil.getCardCountFromMonkey()
                    local lordCardCount = cardCount[lordSeat+1]
                    -- 地主手数较多才有配合空间
                    if lordCardCount > 3 then
                        --TODO判断自己手数和队友的手数，再决策
                        local  result = find_team_biggest_in_domino(domino,left,currSeat,lordSeat)
                        log_func("Action domino -2-1 return",aiUtil.printt(result))
                        if result ~=nil then
                            aiUtil.showAlert(name.."进入团队配合尝试")
                            --写标示到内存中，下家就接管
                            --modify by yzx at 2014年10月17日18:56:21
                            -- set_need_pass_flag(currSeat,lordSeat,false)
                        end
                        return result
                    end
                end
            end
            --地主下家1）自己溜出去,可能性较少 2）放牌让队友出去
            if currSeat ~= lordSeat and getNextSeat(lordSeat) == currSeat then
                if lastHandsInfo == nil then
                    local cardCount = aiUtil.getCardCountFromMonkey()
                    local lordCardCount = cardCount[lordSeat+1]
                    local teamSeat = getTeamSeat(currSeat,lordSeat)
                    local teamCardCount = cardCount[teamSeat+1]
                    local currCardCount = cardCount[currSeat+1]
                    if lordCardCount > 4  and currCardCount > 4 then
                        if  teamCardCount == 4 or teamCardCount ==3 then
                            aiUtil.showAlert(name.."进入队友先走")
                            -- 不拆自己成型牌
                            local  result = find_team_bigger_in_domino(domino,left,currSeat,lordSeat)
                            log_func("Action domino -2-2 return",aiUtil.printt(result))
                            return result
                        elseif teamCardCount<=2 then
                            -- 拆自己成型牌
                            aiUtil.showAlert(name.."进入送你离开")
                            local  result = find_team_bigger_ref_domino(domino,left,currSeat,lordSeat)
                            log_func("Action domino -2-3 return",aiUtil.printt(result))
                            return result
                        end
                    end
                end
            end
        end
    end
    --返回空，继续行走之前的逻辑
    return nil
end




-- 从多米诺中查找小牌(先放小)
-- local function find_smaller_in_domino(domino,left)
--     log_func("Action find_smaller_in_domino domino",aiUtil.printt(domino),aiUtil.printt(left))
--      local  result = nil
--      for i=2,6 do
--         if left[i] < 0 and #domino[i] > 0  then
--             result =  domino[i][1].pokers
--             if result then
--                 if i == 2 then
--                     log_func(aiUtil.printt(domino[5]),aiUtil.printt(domino[6]))
--                     --带单
--                     if #domino[6] > 0 then
--                         --TODO 2和王特化一下
--                         table.insert(result,domino[6][1].pokers[1])
--                     elseif #domino[5] > 0 then
--                     --带双
--                         table.insert(result,domino[5][1].pokers[1])
--                         table.insert(result,domino[5][1].pokers[1])
--                     end 
--                 end
--                 break;
--             end
--         end
--     end
--     return result
-- end

-- 判断一手牌对玩家是否大牌
-- local function isPlayerHasBiggest(handInfo)
--     local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
--     local playerSeat = 0
--     local result = true
--     local tip3Cards = LordUtil:prompt(totalObjCards[playerSeat+1],handInfo,nil);
--     if tip3Cards == nil then
--         result = false
--     end
--     return result
-- end

-- 特别出牌(自己首出)
-- 主要处理尾盘
local function get_special(myCards,top,currSeat,lordSeat)
    log_func("Action get_special",aiUtil.printt(myCards),aiUtil.printt(top))
    local nextSeat = (currSeat==2 and 0 ) or currSeat+1;
    local teamSeat = getTeamSeat(currSeat,lordSeat)
    local cardCount = aiUtil.getCardCountFromMonkey()
    local nextCardCount = cardCount[nextSeat+1]
    local lordCardCount = cardCount[lordSeat+1]
    local teamCardCount = cardCount[teamSeat+1]
     -- 识别初级豆豆
    -- local isDouDou =  isDoudouNPC(currSeat)
    -- local isBeginner = isDoudouNPCBeginner(currSeat)
    -- local aiLevel = aiUtil.getAILevelFromMonkey(currSeat)

    -- 注意一定要初始化，否则可能弄成全部变量了
    local takeOutResult =nil
    -- 自己有出必出
    -- TODO 怎么有时候hands_count == 0
    if top.hands_count == 1  then
        log_func("Action get_special last hand ")
        -- 自己一手牌(可能就是3个)
        -- 对于4带2特化一下，可以谋求炸弹
        if #top.data.composition > 0 and top.data.composition[1].cardtype == 4 then
            if getAIParam("a2",currSeat)  then 
                -- 先把小牌扔出去，下把炸弹
                --TODO 有特例 92+4444但是下家就剩一张2插底了
                takeOutResult=find_smallest_suitable_single_and_pair({top});
            end 
             -- 没有小牌，就剩空炸弹了
            if takeOutResult == nil then
                takeOutResult=find_last_hand(myCards)
            else
                aiUtil.showAlert("缴枪不杀")
            end
        --火箭+AAA这样的场景,先扔火箭最靠谱
        --不存在诱惑炸弹的可能性，是对牌肯定3带2出去了，是单牌肯定3带1再插底 
        elseif #top.data.composition > 0 and Action.hasJokerPair(top)  then 
            takeOutResult={16,17}
        else
            takeOutResult=find_last_hand(myCards)
        end
        return  takeOutResult;
    end
    
    -- if aiLevel > 1 then 
    if  getAIParam("a3",currSeat)   then 
        -- 多米诺判断，先限制到必胜
        takeOutResult = get_domino(top,currSeat,lordSeat)
        if takeOutResult then
            return  takeOutResult;
        end
    else
        -- log_func("豆豆不会必胜")
        -- aiUtil.showAlert("豆豆不会必胜")
    end 
    
    -- 下家就剩1张牌
    if nextCardCount==1  then
        log_func("Action get_special nextCardCount == 1  ")
        -- if aiLevel > 2 then 
        if getAIParam("a4",currSeat) then     
            -- 下家自己人，只剩一张牌
            if currSeat ~=lordSeat and nextSeat ~=lordSeat then
                aiUtil.showAlert("有我掩护，你先走")
                takeOutResult=aiUtil.litter_single(myCards);
            end
        end 
        

        -- 下家对家，只剩一张牌,优先出对，然后找成型牌放，找不到对则从大往小发单
        -- TODO 成型牌可能就3带还有可能,需要细化一下
        -- if aiLevel > 1 then 
        if getAIParam("a5",currSeat) then         
            if currSeat==lordSeat or nextSeat==lordSeat then
                takeOutResult=aiUtil.litter_pair(myCards);
                if takeOutResult == nil then
                    takeOutResult=first_long(top);
                    if takeOutResult == nil then
                        takeOutResult=bigger_single(myCards);
                    end
                else
                    aiUtil.showAlert("门神啊，门神")
                end 
            end
        end 
    end

    -- 地主就2张牌，很可能是对
    -- if aiLevel > 2 then
    if getAIParam("a6",currSeat) then 
        if lordCardCount==2 then 
            if currSeat ~= lordSeat then
                aiUtil.showAlert("猜猜看")
                log_func("Action get_special nextCardCount == 2  ")
                -- 偷看一下
                local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
                local lordCards = totalObjCards[lordSeat+1]
                local handInfo = CardPattern:parseCards(lordCards)
                if handInfo.type == CardPattern.DOUBLE_CARDS then 
                    -- 是对就打单
                    takeOutResult=litter_single_not_split(myCards);
                    -- 没有现成的单就破小对
                    if takeOutResult == nil then 
                        takeOutResult = aiUtil.litter_single(myCards);
                    end 
                else
                    -- 是单就打对
                    takeOutResult=aiUtil.litter_pair(myCards);
                end
            end
        end
        --TODO 队友就剩2张牌,如果是对就打对试试
        if teamCardCount == 2 then
            log_func("Action get_special teamCardCount == 2  ",teamCardCount)
            -- 偷看一下
            local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
            local teamCards = totalObjCards[teamSeat+1]
            local handInfo = CardPattern:parseCards(teamCards)
            if handInfo.type == CardPattern.DOUBLE_CARDS then
                -- 是对就打对
                takeOutResult=aiUtil.litter_pair(myCards);
                if takeOutResult then 
                    -- 没有比他还小的对
                    if takeOutResult[1] > handInfo.value then
                        takeOutResult = nil
                    end
                end 
            end
        end 
    end 
    

    -- if top.hands_count == 1 then
    --     -- 自己一手牌(可能就是3个)
    --     -- TODO 炸弹+1对
    --     takeOutResult=find_last_hand(myCards)
    if top.hands_count==2 then
        -- 自家手牌手数少
        -- 一手长牌+双顺/单顺,又不能够形成domino必胜，可是能够形成插底
        -- 存在45678+6+3333这样的情况
        if #top.data.composition > 0 then
            -- 有成型牌，先扔成型牌
            -- 3带需要额外补单张
            -- local comp = top.data.composition[1]
            -- if comp.cardtype == 3 then
            --     takeOutResult=first_long(top)
            -- else
            --     takeOutResult=top.data.composition[1].pokers
            -- end
            
            if getAIParam("a7",currSeat)  then 
                aiUtil.showAlert("就看你的啦")
                takeOutResult=first_long(top)
            end 
        else
            -- 都是不成型牌，随便找小对或者单张
             takeOutResult=find_smallest_suitable_single_and_pair({top});
        end
    end
    log_func("Action get_special",aiUtil.printt(takeOutResult))
    return  takeOutResult;
end
-- 判断是否顺过小牌
local function isSuitableFollow(currSeat,lastSeat,lordSeat,top_ranks,lastHandsInfo,followCard)
   local result = false
   -- 有双王或者炸弹没法判断是否大牌
   if isAganstHasBoom(currSeat,lordSeat) then
        return result
   end
   local isDomino,totalMin,domino,left = build_domino(top_ranks,currSeat,lordSeat,lastHandsInfo)
   --domino{{},{},{},{},{},{},true|false}
   --left 4四条,3条,2双顺,1顺子,5对子，6单张,7双王
   --总手数盈余太多
   --TODO 是否需要考虑牌型一致
   if isDomino==false and totalMin <-1 then
        --管牌的牌值较大（大牌保守）
        local value = followCard[1]
        local handType = #followCard
        if handType == 1 then
            --单牌大于2（2,小王，大王）
            if value >= 15 then 
                result = true
            end
        elseif handType==2 then
            --双牌大于A（对a，对2）
            if value >= 14 then 
                result = true
            end
        end
    end
   return result
end
-- 忍字头上一把刀
local function get_try_pass(currSeat,lastSeat,lordSeat,top_ranks,lastHandsInfo,followCard)
    log_func("Action get_try_pass",aiUtil.printt(takeOutResult))
    -- 地主需要适当隐忍
    -- 涉及因素：自己手牌状况、上手牌大小、管牌大小、地主上家/地主下家/、下家张数
    local result = false
    local nextSeat = (currSeat==2 and 0 ) or currSeat+1;
    local preSeat = (currSeat==0 and 2 ) or currSeat-1;
    local cardCount = aiUtil.getCardCountFromMonkey()
    local nextCardCount = cardCount[nextSeat+1]
    local preCardCount = cardCount[preSeat+1]
    -- 农民有一家手数少，都不要忍了
    if nextCardCount < 5 or preCardCount < 5 then
        return result
    end 
    -- 上手牌是地主下家，30%左右的概率可能忍
    -- 先走直白逻辑吧，不走概率
    if lastSeat == nextSeat then 
        -- local flag = 0
        -- for i=1,5 do
        --     flag  = math.random(1, 10)
        -- end
        -- if flag > 3 then 
            return result
        -- end
    end
    -- 上手牌是地主上家，80%的概率可能忍
    if lastSeat == preSeat then 
        -- local flag = 0
        -- for i=1,5 do
        --     flag  = math.random(1, 10)
        -- end
        -- if flag > 8 then 
        --     return result
        -- end
    end
    -- 判断是否需要顺过牌
    result = isSuitableFollow(currSeat,lastSeat,lordSeat,top_ranks,lastHandsInfo,followCard)
    log_func("Action get_try_pass",aiUtil.printt(followCard),result)
    if result then
        aiUtil.showAlert("我忍,我让,我成长")
    else
        aiUtil.showAlert("士可忍叔叔不可忍")
    end
    return result
end

-- 是否有火箭
function Action.hasJokerPair(pokers)
    log_func("Action hasJokerPair")
    local pokerarray=pokers.data.leftpoker;
    if pokerarray[16] >0 and pokerarray[17] >0 then
        return true;
    end
    return false;
end
-- 判断是否敌对势力
function Action.isAganst(lastSeat,currSeat)
    local lordSeat=aiUtil.getLordSeatFromMonkey();
    -- -1表示上手牌是自己
    if lastSeat == -1  then
        return false
    end 
    log_func("Action isAganst",lastSeat,currSeat,lordSeat)
    -- 自己是地主或者上手牌是地主
    if lordSeat==currSeat or lordSeat==lastSeat then
        return true;
    end

    return false;
end
-- 判断是否报警,报警必出
-- TODO 地主上家可能还好
function Action.isMustTakeOut(currSeat)
    local lastSeat=aiUtil.getLastSeatFromMonkey();
    if Action.isAganst(lastSeat,currSeat) then
        local cardCount = aiUtil.getCardCountFromMonkey()
        local lastCardCount = cardCount[lastSeat+1]
        if lastCardCount <=2 then
            log_func("Action isMustTakeOut 对手报警")
            return true;
        end
    end
    return false;
end

-- 获取下一个动作
-- 实际上只处理首发，单张和对子
function Action.getNextAction(top_ranks,lastHandsInfo,myCards,currSeat)
    local top=top_ranks[1];
    -- table_print(top);
    -- 先指定地主位置
    lordSeat=aiUtil.getLordSeatFromMonkey();
    nextSeat = (currSeat==2 and 0 ) or currSeat+1;
    lastSeat = aiUtil.getLastSeatFromMonkey();
    log_func("Action getNextAction lordSeat {0} lastSeat {1} currSeat {2}",lordSeat,lastSeat,currSeat)
    log_func("Action getNextAction ",aiUtil.printt(lastHandsInfo),aiUtil.printt(top))
    -- 各家张数
    preSeat = (currSeat==0 and 2 ) or currSeat-1;
    local cardCount = aiUtil.getCardCountFromMonkey()
    nextCardCount = cardCount[nextSeat+1]
    lordCardCount = cardCount[lordSeat+1]
    preCardCount = cardCount[preSeat+1]
    lastCardCount = cardCount[lastSeat+1]


    -- 识别初级豆豆
    -- local isDouDou =  isDoudouNPC(currSeat)
    -- local isBeginner = isDoudouNPCBeginner(currSeat)
    -- local aiLevel = aiUtil.getAILevelFromMonkey(currSeat)

    -- 自己首出
    if lastHandsInfo==nil   then
        --TODO 下面代码整合进get_special
        local special=get_special(myCards,top,currSeat,lordSeat);
        if special~=nil and #special > 0 then
            return special;
        end

        
        -- if isBeginner then
        --     -- 入门的时候，有7成概率打到玩家手里,给玩家喂牌 
        --     -- 取消概率吧，即使玩家手中有大牌，但是也只是表示管得起而已
        --     -- if func.randomChance(7) then 
        --         local playerBigger = getPlayerBigger(top,currSeat,lordSeat)
        --         if playerBigger then
        --             aiUtil.showAlert("朱时茂你这个浓眉大眼的也背叛革命!") 
        --             return playerBigger
        --         end 
        --     -- end 
        -- end 

        if getAIParam("a8",currSeat) then 
            if top.hands_count > 5 then 
                local ret = first_litter(top);
                -- aiUtil.showAlert("一起玩玩!") 
                if ret and #ret > 0  then 
                    return ret
                end
            end 
        end 

        local long=first_long(top);
        if long~=nil then
            if long[1]<9 then
                return long;
            end
            if top.hands_count<5 then
                return long;
            end
        end
        --TODO 下面代码会导致自己把大牌空丢出去
        -- if nextSeat == lordSeat  then
        --     if not isBeginner then 
        --         local tmp= first_litter_bigthan(top,10,16);
        --         if #tmp>0 then 
        --             return tmp;        
        --         end
        --     end 
        -- end

        --  lastSeat == -1 自己必出的时候
        local ret = first_litter(top); 

        if ret and #ret > 0  then 
            return ret
        else
            -- error("首出必出Bug")
            log_func("===>",aiUtil.printt(top))
            -- 没牌其它牌只有出炸弹了
            local four=getFour(top);
            if four then
                return four;
            else 
                error("首出必出Bug")
            end
        end
    end
    if getAIParam("a9",currSeat) then 
         --接牌逻辑,走必胜试试
        local domino_result = get_domino(top,currSeat,lordSeat,lastHandsInfo)
        if domino_result then
            return domino_result
        end
    end 
   
    
    --特殊接牌规则
    local hasJokers=Action.hasJokerPair(top);
    if hasJokers and top.hands_count<=2 then
        return {16,17};--王炸
    end

    local four=getFour(top);
    if four~=nil and top.hands_count<=2 then
        return four;
    end


    local needPass=false;
    --上家地主已经过牌
    if lastSeat == nextSeat and Action.isAganst(lastSeat,currSeat) == false then
        needPass=true;
    end
    --上家已经顶牌
    if Action.isAganst(lastSeat,currSeat) == false and lastHandsInfo and lastHandsInfo.value >=13 then
        needPass=true;
    end
    local memNeedPass = aiUtil.getValue4Strorage("needPass")
    if memNeedPass~=nil then
        if memNeedPass then
            needPass = true
        else
            needPass = false
        end
        -- 重置标示
        aiUtil.setValue2Storage("needPass",nil)
    end
    log_func("Action getNextAction needPass",needPass,memNeedPass)




    --普通跟牌逻辑,不出2，王 不拆牌 不炸
    local followCard=follow(top_ranks,lastHandsInfo);
    log_func("Action getNextAction follow",aiUtil.printt(followCard))

    --判断上一手是自家还是对家
    if Action.isAganst(lastSeat,currSeat) then
        if followCard == nil  then
            -- 不能够这样处理，有时候就是必须管
            -- if nextSeat == lordSeat then
                --默认会拆2
                -- 上家是对家，考虑拆2和王
                --TODO 开始的时候就一对2或者王容易被轰出来
            followCard=tryKick_ex(top_ranks,lastHandsInfo); 
            -- else
                --尝试pass一下，防止强制出大牌,如果返回空，则会进行choose选择
                --TODO 判断不严密,如果上手牌手数少，是否应该有管必管
                -- followCard ={}
            -- end
            log_func("Action getNextAction tryKick_ex",aiUtil.printt(followCard))   
            -- 2个2 谨慎处理
            if lastHandsInfo.type== CardPattern.DOUBLE_CARDS and followCard  then
                local cardValue = followCard[1]
                if cardValue == Card.CARD_POINT_2 then
                    if getAIParam("a10",currSeat) then
                        -- 剩余手牌
                        local left=top.data.leftpoker;
                        -- 小牌手数(K以下)
                        local leftcount=aiUtil.get_left_hand_counts(left,13);
                        if leftcount>1 and top.hands_count>3 then
                        -- if leftcount>1 and top.hands_count>3 and lordCardCount > 5 then
                            followCard = {}
                            log_func("Action getNextAction 22 pass")
                        end
                    end 
                end
            end
        end
        -- 地主隐忍
        --TODO 下家报警，有牌必管
        if currSeat == lordSeat then
            if followCard and #followCard ~= 0 then
                needPass =  get_try_pass(currSeat,lastSeat,lordSeat,top,lastHandsInfo,followCard)
                if not getAIParam("a11",currSeat) and needPass then 
                    needPass = false
                end 
            end
        end
    end
   


    --地主上家顶牌
    -- if aiLevel > 1 or func.randomChance(3) then 
    if getAIParam("a12",currSeat) then    
        if nextSeat==lordSeat and currSeat~=lordSeat then
            --地主下家过牌或者顶牌小于10并且手数大于5，就要用大牌顶
            if lastSeat==lordSeat or (lastHandsInfo.value<=10 and preCardCount >5 )then
                local followCard_tmp=follow_big_card(top_ranks, lastHandsInfo);
                log_func("Action getNextAction follow_big_card",aiUtil.printt(followCard_tmp))
                if followCard_tmp then
                    followCard=followCard_tmp;
                end
            end
        end
    end 
    
    --尝试大牌
    -- if  followCard  and nextSeat==lordSeat and #lordInfo.seatCards[nextSeat]<4 then
    --     followCard=tryKick_ex(top_ranks,lastHandsInfo); --默认会拆2
    -- end

    --下家就一手牌了,自己手数还不少,尝试过牌,让队友离开
    if nextSeat~=lordSeat and currSeat~=lordSeat  then
        if nextCardCount == 1 or nextCardCount == 2 then 
            -- if aiLevel > 3 or func.randomChance(3) then 
            if getAIParam("a13",currSeat) then     
                --判断是否可以过出去
                local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
                local tip2Cards = LordUtil:prompt(totalObjCards[nextSeat+1],lastHandsInfo,nil);
                if tip2Cards ~=nil and #tip2Cards > 0 then
                    aiUtil.showAlert("请叫我雷锋")
                    needPass = true
                end
            end 
        end
    end

    --自己就一手牌了，有牌就出
    if top.hands_count==1 then
        needPass=false;
        if followCard == nil then
            followCard=tryKick_ex(top_ranks,lastHandsInfo);
        end
    end


    if needPass then
        -- 不要返回空，否则会走choose逻辑
        -- 豆豆的小概率(8成)会管同伴牌
        if getAIParam("a14",currSeat) and nextSeat==lordSeat then
            if followCard then
                aiUtil.showAlert("豆豆会管牌")
                log_func("Action getNextAction ",nextSeat,aiUtil.printt(followCard))
                return followCard; 
            end
        end 
        return {};
    end
    
    --TODO　适应残局　管之后的局势判断，用于忍让
    --地主还有小王的情况下，不要草率的用大王盖牌
    if lastHandsInfo.type == CardPattern.SINGLE_CARD and currSeat~=lordSeat and followCard and followCard[1]== 17 then 
        local handInfo = {type=CardPattern.SINGLE_CARD,value=15,length=1}
        local isAganstHasXW  = isBiggest(handInfo,currSeat,lordSeat)
        log_func("Action getNextAction xw pass",isAganstHasXW,lastCardCount)
        if isAganstHasXW==false and lastCardCount > 5  then 
            followCard = {}
        end 
    end 
    log_func("Action getNextAction ",nextSeat,aiUtil.printt(followCard))
    return followCard;
end

-- 叫分动作
function Action.getBidAction(top_ranks,callLevel,player_top_rank)
     log_func("Action getBidAction ",aiUtil.printt(top_ranks),aiUtil.printt(callLevel))
     -- {有叫必叫,有王和2必叫,估值叫分,组合底牌叫分,根据对方牌力叫分}
     local score = 0
     if callLevel[1] == true then
        log_func("Action getBidAction 赌徒必叫")
        aiUtil.showAlert("赌徒必叫")
        return 3
     end
     if callLevel[2]  == true then
        -- 双王必叫
        if Action.hasJokerPair(top_ranks) then
            log_func("Action getBidAction 双王必叫")
            aiUtil.showAlert("双王必叫")
            return 3
        end
        -- 炸弹必叫
        if getFour(top_ranks) then
            log_func("Action getBidAction 炸弹必叫")
            aiUtil.showAlert("炸弹必叫")
            return 3
        end
        -- 大王+2个2/小王+3个2
        if hasGoodSingle(top_ranks) then 
            log_func("Action getBidAction 大牌必叫")
            aiUtil.showAlert("大牌必叫")
            return 3
        end
        -- score = getSchemoScore(top_ranks)
        log_func("Action getBidAction 没王，没2，没炸弹也得叫分啊")
        return score
    end
    if callLevel[4]  == true then 
        log_func("Action getBidAction 看底牌叫分")
        aiUtil.showAlert("偷看底牌叫分")
        score = getSchemoScore(top_ranks)
        if score < 3 then 
            score = 0
        end
        return score
    end
    if callLevel[5]  == true then
        local aiScore,aiValue =  getSchemoScore(top_ranks)
        local playerScore,playerValue = getSchemoScore(player_top_rank)
        aiUtil.showAlert("偷看玩家牌叫分")
        log_func("Action getBidAction 看玩家牌叫分",aiValue,playerValue)
        -- 如果ai分值高，直接叫3分抢地主,否则只返回ai的估值
        if aiValue > playerValue+10 then
            return 3
        else
            return 0
        end
    end
    score = getSchemoScore(top_ranks)
    log_func("Action getBidAction 估值叫分")
    return score
end


--是否具有好的单牌
--TODO  是否加上A
local function hasGoodSingle(top)
    local count2 = top.data.leftpoker[15]
    -- 可能有3个2
    for k,v in pairs(top.data.composition) do
        if v.cardtype == 3 and v.pokers[1] == 15 then
            count2 = 3
        end
    end
    -- 是否具有大王+2个2
    if top.data.leftpoker[17]>0 and count2 >=2  then
        return true
    end 
    -- 是否具有小王+3个2
    if top.data.leftpoker[16]>0 and count2 >=3  then
        return true
    end
end
-- 估值叫分函数
function Action.getSchemoScore(top)
    local value=top.score/10-top.hands_count*5;
    value=value+top.data.leftpoker[17]*40+top.data.leftpoker[16]*15+top.data.leftpoker[15]*10;
    local score = 0
    if value>30 then
        score = 3;
    elseif value>-20 then
        score =  2;
    elseif value>-80 then
        score =  1;
    end
    log_func("Action bid 叫分 牌力:",aiUtil.printt(top),"估值：",value,"分值:",score);
    return score, value
end
-- 放水给玩家，找玩家大牌型打
-- 实际上也不是给玩家了，只是给对家放水，可能放到玩家手里也可能放到路人甲手里
-- local function getPlayerBigger(top,currSeat,lordSeat)
--     local result
--     local comp = nil 
--     -- 判断成型牌,玩家是否有大牌 
--     for i,v in ipairs(top.data.composition) do
--         --4四条,3条,2双顺,1顺子,5对子，6单张,7双王
--         local handInfo
--         local len = #v.pokers
--         if v.cardtype==3 then
--             handInfo = {type=CardPattern.THREE_CARDS,value=v.pokers[1],length=3}
--         elseif v.cardtype == 2 then
--             --长龙用大牌值表示
--             handInfo = {type=CardPattern.DOUBLE_DRAGON,value=v.pokers[len],length=len}
--         elseif v.cardtype == 1 then
--             handInfo = {type=CardPattern.SINGLE_DRAGON,value=v.pokers[len],length=len}
--         end
--         if handInfo then 
--             local tmp =  isPlayerHasBiggest(handInfo)
--             if tmp then 
--                 comp = v
--                 break;
--             end 
--         end     
--     end
--     log_func("Action getPlayerBigger:",aiUtil.printt(top),aiUtil.printt(result));
--     --TODO先测试一下最大牌型是否达标，达标就不做对子和单了
--     if comp then 
--         --三条需要找带的
--         if  comp.cardtype == 3  then
--             result = comp.pokers
--             local daipai = litter_single_and_pair(top);
--             for i,v in ipairs(daipai) do
--                 table.insert(result,v)
--             end
--         else
--             result = comp.pokers
--         end 
--     end 
--     -- 再判断零散牌，玩家是否有大牌(对子和单)
--     if result ~= nil then 
--         --从最大的开始找起，先决定牌型，再决定牌值
--     end 
--     return result
-- end 
return Action
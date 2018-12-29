-- 机器人执行机器人动作，调用AI进行计算
-- cardPoint指牌点值3~17，cardInt指0~53，cardObj指Card对象
-- 依赖的函数库
require "utils/table_util"
local func = require("ai.func")
-- 依赖的工具库
local aiUtil= require("ai.aiUtil")

local CardPattern = require("logic.CardPattern")
local LordUtil = require("logic.LordUtil")
local Card = require("logic.Card")
local CardsInfo = require("logic.CardsInfo")

-- 持有人类AI
local AI = require("ai.HumAI")

local Robot =class("Robot")

-- 持有残局
local HappyEnding = require("ai.HappyEnding")
local isEnding = false
local endingLevel = 0

--判断2手牌是否相等
local function isHandsInfoEqual(cardsObj1,cardsObj2)
    -- 返回的牌序好像每次不太一样，有倒序也有正序，还是转换为手牌吧
    -- 注意所有parseCards 需要倒序排列
    table.sort( cardsObj1, function(card1,card2) 
        return card1.value > card2.value
    end )
     table.sort( cardsObj2, function(card1,card2) 
        return card1.value > card2.value
    end )
    local handInfo1 = CardPattern:parseCards(cardsObj1)
    local handInfo2 = CardPattern:parseCards(cardsObj2)
    print("Robot isHandsInfoEqual ",aiUtil.printt(handInfo1),aiUtil.printt(handInfo2))
    if handInfo1.type == handInfo2.type and handInfo1.value == handInfo2.value and handInfo1.length == handInfo2.length then
        return true
    else
        return false
    end 
end

-- 遍历查找所有可行的提牌方案
-- 碰到炸弹后就不循环了
local function getAllPrompt(myCardsObj,useLastHandInfo,lastPrompt,all,R1)
    R1 = R1+1
    if R1 == 10 then
        -- 后期改成直接返回
        aiUtil.uploadError("recursive_error")
        error("递归错误")
    end
    print("Robot getAllPrompt ",aiUtil.printt(useLastHandInfo),aiUtil.printt(lastPrompt),R1)
    if lastPrompt then 
        local tipCards = LordUtil:prompt(myCardsObj,useLastHandInfo,lastPrompt);
        if tipCards and all[1] then
            local len = #all
            --和第一个不相等，并且也不和之前的一个相等,防止提牌死循环
            if isHandsInfoEqual(all[1],tipCards) == false  then 
                if len -1 > 0 then 
                    if   isHandsInfoEqual(all[len],tipCards) == false then 
                        table.insert(all,tipCards)
                        getAllPrompt(myCardsObj,useLastHandInfo,tipCards,all,R1)
                    end 
                else
                    table.insert(all,tipCards)
                    getAllPrompt(myCardsObj,useLastHandInfo,tipCards,all,R1)
                end 
            else
                print("Robot getAllPrompt end",aiUtil.printt(all[1]),aiUtil.printt(tipCards))
            end
        end
    else
        local tipCards = LordUtil:prompt(myCardsObj,useLastHandInfo,lastPrompt);
        print("Robot getAllPrompt start ",aiUtil.printt(tipCards))
        if tipCards then
               table.insert(all,tipCards)
               getAllPrompt(myCardsObj,useLastHandInfo,tipCards,all,R1)
        end
    end
end
local function validateHandInfo(lastHandsInfo,takeOutHandInfo)
    -- print("Robot validateHandInfo",takeOutHandInfo.type,lastHandsInfo.type,takeOutHandInfo.value,lastHandsInfo.value,takeOutHandInfo.length,lastHandsInfo.length)
    if takeOutHandInfo.type == lastHandsInfo.type then 
        --牌型相同长度一致，并且值大是合法可管的
        if takeOutHandInfo.value > lastHandsInfo.value and takeOutHandInfo.length == lastHandsInfo.length then 
            return true
        end 
    else
        --牌型不通看后者是不是炸弹
        if takeOutHandInfo.type == CardPattern.DOUBLE_JOKER or takeOutHandInfo.type == CardPattern.FOUR_CARDS then 
            return true
        end 
    end 
    return false
end
--校验一手牌是否合法
local function validate(lastHandsInfo,cardPoints,cardsObj)
    print("Robot validate ",lastHandsInfo.type,lastHandsInfo.value,lastHandsInfo.length,table.concat(cardPoints,","));
    local result = false
    local points = table.clone(cardPoints)
    if #points == 0 then 
        --返回的是pass,肯定合法
        return true
    end
    local handObjs = {} 
    for i,cardObj in ipairs(cardsObj) do
        local len = #points
        if len == 0 then 
            break
        end 
        for k=1,len do
            if points[k]== cardObj.value then 
                table.insert(handObjs,table.clone(cardObj))
                table.remove(points,k)
                break
            end 
        end
    end
    --解析牌型得先排序
    table.sort( handObjs, function(card1,card2) 
        return card1.value > card2.value
    end )
    local takeOutHandInfo = CardPattern:parseCards(handObjs)
    print("Robot validate parser:",takeOutHandInfo.type,takeOutHandInfo.value,takeOutHandInfo.length);
    result = validateHandInfo(lastHandsInfo,takeOutHandInfo)
    print("Robot validate ",result);
    return result
end 
function Robot:ctor(options)
	self.info = {};
    self.seat = options.seat;
    self:init();
end

function Robot:init()
    -- 存放0~53的intValue
	self.myCardsInt = {}
    -- 存放牌型对象
    self.myCardsObj ={}
end	

function Robot:resetEnding(level)
    print("Robot resetEnding ",level);
    if level then 
        -- isEnding = true
        aiUtil.isEnding = true
        endingLevel = level
        HappyEnding.reset()
    else
        -- isEnding = false;
        aiUtil.isEnding = false
    end 
end

function Robot:resetCards(cardsInt)
	self.myCardsInt = cardsInt
    self.myCardsObj = func.cardsObj(cardsInt)
end

function Robot:addBottomCards(cardsInt)
    for k,v in pairs(cardsInt) do
        local card = Card.new(v)
        table.insert(self.myCardsInt,v)
        table.insert(self.myCardsObj,card)
    end
end

function Robot:callScore()
    print("Robot:callScore start")
    local bottmIntCards =  aiUtil.getBottomIntCardsFromMonkey()
    local myCardsPoint = func.cardsPoint(self.myCardsInt);
    local bottmPointCards = func.cardsPoint(bottmIntCards);
    local playerIntCards = table.clone(aiUtil.getPlayerIntCardsFromMonkey())
    local playerPointCards = func.cardsPoint(playerIntCards)
    local bid=AI.bid(myCardsPoint,bottmPointCards,self.seat,playerPointCards);
    print("Robot:callScore, score:",bid)
    return bid;
end
-- 
function Robot:getPalyerCardPttern()
    local  playerIntCards = table.clone(aiUtil.getPlayerIntCardsFromMonkey())
    local  cardsPoint = func.cardsPoint(playerIntCards);
    local  ret=AI.getAllCardPttern(cardsPoint);
    return ret;
end
function Robot:getPalyerCallScore()
    local  playerIntCards = table.clone(aiUtil.getPlayerIntCardsFromMonkey())
    local  points = func.cardsPoint(playerIntCards);
    local  bid=AI.bid(points,nil,0,nil);
    return bid;
end

function Robot:takeOutCard( lastCardsObj )
	local tipCardsScheme
    -- table_print(self.myCardsInt)
    -- 将自己的牌转为计算对象(牌点数)
    local myCardsPoint = func.cardsPoint(self.myCardsInt);
    -- 手牌转为对象
    local myCardsObj = func.cardsObj(self.myCardsInt)
    -- table_print(myCardsPoint)
    local lastSeat = aiUtil.getLastSeatFromMonkey()
	--- 构造牌型树
	-- local tmp=AI.gametree(lastCardsObj);
	if lastCardsObj == nil or #lastCardsObj==0 then
        -- 残局特殊解
        if aiUtil.isEnding then
            local result  = HappyEnding.takeOutCards(lastSeat,nil,myCardsPoint,self.seat,endingLevel)
            if result and result.seat == self.seat then 
                tipCardsScheme = result.cards
            end
        end
        if tipCardsScheme == nil then 
            ---首出
            ---找出最佳牌型
            tipCardsScheme =  AI.findBetterCards(myCardsPoint,self.seat,nil);
        end
        --如果是首发，不能够pass，直接出一张最小的牌
        if tipCardsScheme==nil or #tipCardsScheme == 0 then 
            print("Robot take ILLEGAL_CARDS first can't pass")
            tipCardsScheme = aiUtil.litter_single_by_cardpoint(myCardsPoint)
        end 
	else
		--- 接上手牌，根据上家牌型和自己已有牌计算提牌方案
        -- TODO 直接传递过来，省去一次运算
        --上一手牌型
        local lastHandInfo = CardPattern:parseCards(lastCardsObj)
        local useLastHandInfo = table.clone(lastHandInfo)
        -- 残局特殊解
        if aiUtil.isEnding then
            local result  = HappyEnding.takeOutCards(lastSeat,useLastHandInfo,myCardsPoint,self.seat,endingLevel)
            if result and result.seat == self.seat then 
                 --验证一下结果，防止错误的出牌
                local flag = validate(useLastHandInfo,result.cards,myCardsObj)
                if flag then 
                    tipCardsScheme = result.cards
                end  
            end
        end
        if tipCardsScheme == nil then 
            --TODO 应该先校验一下管不管得起
            --残局没有特殊解，也走普通算法
            tipCardsScheme = self:normalTakeOut(useLastHandInfo,myCardsPoint,myCardsObj)
        end
        if lastHandInfo and #tipCardsScheme > 0 then 
            --保险一下，验证一下牌型合法性
            local checkResult = validate(useLastHandInfo,tipCardsScheme,myCardsObj)
            -- 不合法则返回pass
            if not  checkResult then 
                print("Robot take ILLEGAL_CARDS",aiUtil.printt(lastHandInfo),aiUtil.printt(tipCardsScheme));
                tipCardsScheme = {}
            end 
        end
	end
    local  ret = self:int2take(tipCardsScheme)
    if ret.cardType == CardPattern.ILLEGAL_CARDS then 
        --出了错误牌型
        aiUtil.uploadError("CardPattern.ILLEGAL_CARDS")
        error("牌型错误")
    end
    return ret;	
end
-- 普通出牌
function Robot:normalTakeOut(useLastHandInfo,myCardsPoint,myCardsObj)
    local tipCardsScheme
    -- 单张或者对直接找最佳，避免大的运算量
    if useLastHandInfo.type==CardPattern.SINGLE_CARD or useLastHandInfo.type==CardPattern.DOUBLE_CARDS then
        tipCardsScheme =  AI.findBetterCards(myCardsPoint,self.seat,useLastHandInfo);
        print("Robot findBetterCards ",aiUtil.printt(tipCardsScheme));
    end

    -- if tipCardsScheme~=nil and #myCardsPoint<7 then
    --     local tipCardsScheme_tmp=tipCardsScheme;  --- todo 比较两种方案
    --     local tipCardsScheme2 = LordUtil:prompt(myCardsObj,useLastHandInfo);
    --     --这里不要直接操作lastHandInfo对象，会改变该对象的值
    --     tipCardsScheme2=AI.choose(tipCardsScheme2,myCardsPoint,self.seat);
    --     print("Robot choose  ",aiUtil.printt(tipCardsScheme2));
    -- end

    -- TODO 实际上可能是建议pass啊
    if tipCardsScheme == nil  then
        --TODO 提牌好像不能够智能
        -- local tipCardsScheme3 = LordUtil:prompt(myCardsObj,useLastHandInfo);
        -- tipCardsScheme = AI.choose({tipCardsScheme3},myCardsPoint,self.seat);

        local tipCardsScheme3 = {}
        --从小到大排列，提牌才能够正常
        table.sort( myCardsObj, function (card1,card2)
            return card1:compareTo(card2)
        end)
        ---递归标示,防止死循环递归太多次
        local R1=  0
        -- 3带1和3带2的提牌算发不是特别科学，需要特化处理一下
        -- TODO 也许四带2和四带22也需要这样处理
        -- FOUR_WITH_TWO FOUR_WITH_TWO_TWO
        local specialHandInfo = nil
        if useLastHandInfo.type==CardPattern.THREE_WITH_ONE or useLastHandInfo.type==CardPattern.THREE_WITH_TWO then
            -- 先转化为3带去提牌
            specialHandInfo = CardsInfo.new(CardPattern.THREE_CARDS, useLastHandInfo.value, 3)
            -- 然后再查找拖油瓶
        end
        if specialHandInfo then
            getAllPrompt(myCardsObj,specialHandInfo,nil,tipCardsScheme3,R1);
            print("Robot choose ",aiUtil.printt(tipCardsScheme3));
            local top = nil
            tipCardsScheme,top = AI.choose(tipCardsScheme3,myCardsPoint,self.seat);
            print("Robot choose ",aiUtil.printt(tipCardsScheme),aiUtil.printt(top));
            -- 再从得分最高的scheme中查找符合条件的单或者双做拖油瓶
            if tipCardsScheme and #tipCardsScheme > 0 then
                -- 从不成型的牌型中查找
                if #tipCardsScheme ==3 then
                    local left=top.data.leftpoker;
                    local extra =nil
                    -- 必须验证张数，因为可能有时候用炸弹来管，否则会出现4带1
                    if useLastHandInfo.type==CardPattern.THREE_WITH_ONE  then
                       -- 然后再查找拖油瓶
                       extra = aiUtil.three_long_daipai(left,1)
                       if #extra == 2 then 
                            extra = aiUtil.litter_single(left)
                       end
                       -- 保护大牌防止被带出去
                       if top.hands_count >2 and extra and extra[1] and extra[1] >= 15 then
                            extra = nil
                       end 
                    elseif  useLastHandInfo.type==CardPattern.THREE_WITH_TWO  then
                       extra = aiUtil.litter_pair(left)
                       -- 保护大牌防止被带出去
                       if top.hands_count >2 and extra and extra[1] and extra[1] >= 14 then
                            extra = nil
                       end 
                    end
                    -- TODO 如果找不到就需要从成型的牌中找
                    -- 先处理成管不起吧
                    -- 实际上单只能够拆顺子，双只能够拆双顺
                    if extra then 
                        print("Robot find extra",aiUtil.printt(extra));
                        for i,v in ipairs(extra) do
                            table.insert(tipCardsScheme,v)
                        end
                        -- table.merge(tipCardsScheme,extra)
                    else
                        print("Robot find extra",aiUtil.printt(extra));
                        tipCardsScheme = {}
                    end
                    -- 3根2谨慎出
                    -- TODO下家手数也是影响因素
                    if #tipCardsScheme > 0 and tipCardsScheme[1] == 15 then
                        print("Robot find 222 ",top.hands_count);
                        if top.hands_count > 3 then
                            tipCardsScheme = {}
                        end
                    end
                end
            end
        else
            getAllPrompt(myCardsObj,useLastHandInfo,nil,tipCardsScheme3,R1);
            print("Robot choose in ",aiUtil.printt(tipCardsScheme3));
            tipCardsScheme = AI.choose(tipCardsScheme3,myCardsPoint,self.seat);
            print("Robot choose out",aiUtil.printt(tipCardsScheme));
        end
    end
    return tipCardsScheme
end
function Robot:int2take(tipCardsScheme)
    print("Robot:int2take ",aiUtil.printt(tipCardsScheme))
    -- 封装成出牌接口识别的牌
    local tipCardsInt = {};
    local tipCardsObj ={};
    if tipCardsScheme and #tipCardsScheme > 0 then
        for x,cardPoint in pairs(tipCardsScheme) do        
            print("Robot takeOutCard　出牌",self.seat,cardPoint);
            -- 查找牌
            for k,v in pairs(self.myCardsObj) do
                -- TODO 一对/3张/4张的时候,不能够直接返回
                if v.value == cardPoint then
                    -- table.insert(tipCardsInt,v.original)
                    -- lua 边遍历边删除是安全的
                    table.insert(tipCardsObj,table.clone(v));
                    self:rmvCard(k)
                    break;
                end
            end
        end
    end
    local  ret = {}
    -- 注意所有parseCards 需要倒序排列
    table.sort( tipCardsObj, function(card1,card2) 
        return card1.value > card2.value
    end )
    local takeOutHandInfo = CardPattern:parseCards(tipCardsObj)
    ret.cardType = takeOutHandInfo.type;
    ret.cardValue = takeOutHandInfo.value;
    ret.cardList = tipCardsObj;
    print("Robot send ",aiUtil.printt(ret));
    return ret 
end

-- 删除牌张
function Robot:rmvCard( index )
    table.remove(self.myCardsInt,index)
    table.remove(self.myCardsObj,index)
    -- print("Robot rmvCards",#self.myCardsInt,#self.myCardsObj)
end

return Robot


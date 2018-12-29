-- 猴型智能接口，AI的唯一入口。
-- 目前含初始化手牌、叫分、初始化底牌、打牌四个对外接口
-- 内部提供地主位置、上手牌位置、3家手牌数量接口
-- 依赖的函数库
require "utils/functions"
require "utils/table_util"
local func = require("ai.func")
-- 依赖的工具库
local aiUtil= require("ai.aiUtil")
local Robot = require("ai.Robot")
local Card = require("logic.Card")
local Monkey = class("Monkey")
-- 左右护法
-- Monkey.preRobot ={};
-- Monkey.nextRobot={};
-- 人类(测试用)
-- Monkey.humRobot={}
-- 和SingleGameManager.pos_保持一致
Monkey.POST={SELF = 0, PRE = 2, NEXT = 1}
-- 自己记录一下打了几手牌
Monkey.Record = 0
-- 牌局记录，用于日志上传
Monkey.RecordLog = {}        
-- 外部依赖,用于调用showAlert之类
-- Monkey.MonkeyParent = nil
-- 是否自动测试
local autoTest = true
-- Error Flag
-- MonkeyErrorFlag = nil
-- 更新全局手牌
local function  updateTotal(takeOutCardParams)
    -- 注意顺序是021,即self,pre,next
    local cardObjs = {}
    --从小到大排列，提牌才能够正常
    cardObjs[1] = table.clone(takeOutCardParams.handCards[1].handCardListObj)
    cardObjs[2] = table.clone(takeOutCardParams.handCards[3].handCardListObj)
    cardObjs[3] = table.clone(takeOutCardParams.handCards[2].handCardListObj)
    for i,v in ipairs(cardObjs) do
        table.sort( v, function (card1,card2)
            return card1:compareTo(card2)
        end)
    end
    -- print("Monkey updateTotal ： ",aiUtil.printt(cardObjs))
    aiUtil.setValue2Storage("TotalObjCards",cardObjs)
end
-- 初始化Robot：设置位置和手牌
function Monkey:initRobot(intCards,seat,npcId,npcLevel)
    local errtrace =""
    local ret,result = xpcall(function() 
        print("Monkey initRobot",seat,#intCards,table.concat( intCards, ", " ))
        -- if Monkey.MonkeyParent == nil then
        --     if not autoTest then 
        --     	Monkey.MonkeyParent = require("lordsinglexhcg.lordsingle.SingleGameManager")
        --     end
        --     aiUtil.showAlert("AI版本2014年11月5日15:29:06")
        --     -- showBtn()
        -- end
        -- aiUtil.showAlert("AI版本2014年11月5日15:29:06")
        if seat  then
            if seat == self.POST.PRE then 
                self.preRobot = Robot.new({seat=2})
                -- 注意必须table.clone，否则会被外部更改
                self.preRobot:resetCards(table.clone(intCards));
                aiUtil.setValue2Storage("preIntCards",table.clone(intCards))
                -- TODO 后期NPC位置会变动
                aiUtil.setValue2Storage("npcSeat",seat)
                -- Debug 手动测试 NPC等级
                -- npcId = 4 
                print("Monkey set npcLevel",npcLevel,"npcId",npcId)
                --随机生成1~6的NPC等级
                -- if npcLevel == nil then
                --     npcLevel  = math.random(1, 6)
                -- end
                print("Monkey set random npcLevel",npcLevel)

                aiUtil.setValue2Storage("npcLevel",npcLevel)
                aiUtil.setValue2Storage("npcId",npcId)
                --设置aiLevel，暂时和ncpId绑定
                aiUtil.setValue2Storage("aiLevel",npcId)
                -- showAlert("NPC等级:"..npcLevel)
                --重置牌局记录
                -- self.RecordLog = {}
            elseif seat == self.POST.NEXT then
                self.nextRobot = Robot.new({seat=1})
                self.nextRobot:resetCards(table.clone(intCards));
                aiUtil.setValue2Storage("nextIntCards",table.clone(intCards))
            elseif seat == self.POST.SELF then
                --用于叫分评估
                aiUtil.setValue2Storage("playerIntCards",table.clone(intCards))
                --下面是测试代码，测试自动打牌 
                if autoTest then 
                	self.humRobot = Robot.new({seat=0})
                	self.humRobot:resetCards(table.clone(intCards));
                end
            else
                aiUtil.setValue2Storage("bottomIntCards",table.clone(intCards))
            end
            -- 重置地主位置
            aiUtil.setValue2Storage("lordSeat",-1)
            aiUtil.setValue2Storage("lastSeat",-1)
        else
            print("Monkey initRobot error seat",seat)
        end
    end,function() 
        errtrace = debug.traceback()
    end)
    if ret == false then
        -- print("AI errMessage:" .. (result or "null"))
        -- local x= string.find(result,"%:%d+",1)
        -- local tmp = string.sub(result, x, #result)
        -- 截取异常的关键信息
        aiUtil.showError("AI error1:"..errtrace)
    end
end
-- 叫分
function Monkey:callScore(curSeat)
     local errtrace =""
     local ret,result = xpcall(function() 
        print("Monkey callScore, seat : ",curSeat)
         local robot = self:getRobotBySeat(curSeat)
         local score = 0
         if robot then
            score = robot:callScore()
         else
            print("Monkey callScore error seat ",curSeat)
         end
         print("Monkey callScore, score:",score)
         self.Record = 0 
        return score
     end,function() 
        errtrace = debug.traceback()
    end)
    if ret == false then
        -- print("AI errMessage:" .. (result or "null"))
        -- local x= string.find(result,"%:%d+",1)
        -- local tmp = string.sub(result, x, #result)
        -- 截取异常的关键信息
        aiUtil.showError("AI error2:"..errtrace)
        return 0
    else
        return result
    end
end
-- 获取玩家叫分,提供给外部
function Monkey:getPlayerCallScore()
    local errtrace =""
     local ret,result = xpcall(function() 
        local robot = self:getRobotBySeat(1)
         local score = 0
         if robot then
            score = robot:getPalyerCallScore()
         else
            print("Monkey getPlayerCallScore error  ")
         end
         print("Monkey getPlayerCallScore send score ",score)
         return score
     end,function() 
        errtrace = debug.traceback()
    end)
    if ret == false then
        -- print("AI errMessage:" .. (result or "null"))
        -- local x= string.find(result,"%:%d+",1)
        -- local tmp = string.sub(result, x, #result)
        -- 截取异常的关键信息
        aiUtil.showError("AI error3:"..errtrace)
        return 0
    else
        return result
    end
     
end
-- 获取玩家手牌牌型,提供给外部
function Monkey:getPalyerCardPttern()
    local errtrace =""
    local ret,result = xpcall(function() 
        print("Monkey getPalyerCardPttern ")
        local robot = self:getRobotBySeat(1)
        local result 
        if robot then
            result = robot:getPalyerCardPttern()
        else
            print("Monkey getPalyerCardPttern error ")
        end
        print("Monkey getPalyerCardPttern return: ",aiUtil.printt(result))
        return result
     end,function() 
        errtrace = debug.traceback()
    end)
    if ret == false then
        -- print("AI errMessage:" .. (result or "null"))
        -- local x= string.find(result,"%:%d+",1)
        -- local tmp = string.sub(result, x, #result)
        -- 截取异常的关键信息
        aiUtil.showError("AI error4:"..errtrace)
        return  {false,false,false,false}
    else
        return result
    end
end
-- 设置地主和底牌
function Monkey:initBottom(bottomCardsInt,seat,endingLevel)
    local errtrace =""
    local ret,result = xpcall(function() 
        -- 存储地主位置
         print("Monkey initBottom , seat:",seat,",cards:",table.concat(bottomCardsInt, ", " ), ',endingLevel:', endingLevel)
         aiUtil.setValue2Storage("lordSeat",seat)
         if endingLevel then
            --设置aiLevel，残局AI都是顶级
            aiUtil.setValue2Storage("aiLevel",4)
            self.preRobot:resetEnding(endingLevel)
            self.nextRobot:resetEnding(endingLevel)
         else
            --清空残局状态
            self.preRobot:resetEnding()
            self.nextRobot:resetEnding()
         end
         -- 增加底牌
         local robot = self:getRobotBySeat(seat)
         if robot then
            robot:addBottomCards(bottomCardsInt)
         end
        --重置AI协作标示
        aiUtil.setValue2Storage("needPass",nil)
        print("Monkey record pre    ",#self.preRobot.myCardsInt,"{"..table.concat( self.preRobot.myCardsInt, ", ").."}")
        print("Monkey record next   ",#self.nextRobot.myCardsInt,"{"..table.concat( self.nextRobot.myCardsInt, ", ").."}")
        -- 测试代码，测试提供给外部的API
        -- self:getPlayerCallScore()
        -- self:getPalyerCardPttern()
     end,function() 
        errtrace = debug.traceback()
    end)
    if ret == false then
        -- print("AI errMessage:" .. (result or "null"))
        -- local x= string.find(result,"%:%d+",1)
        -- local tmp = string.sub(result, x, #result)
        -- 截取异常的关键信息
        aiUtil.showError("AI error5:"..errtrace)
    end     
end

--[[
-- 数据格式
seat
cardRecord={{seat=,cardList={cardObj,cardObj},cardValue=,cardType=}}
handCards{{seat=0,handCardListInt={cardInt,cardInt},handCardListObj={cardObj,cardObj}}}
lordSeat
]]--
-- 出牌
function Monkey:doTakeOutCards(takeOutCardParams)
    local errtrace =""
    local ret,result = xpcall (function() 
       print("Monkey doTakeOutCards, seat:",takeOutCardParams.seat, ",lordSeat:", takeOutCardParams.lordSeat)
         updateTotal(takeOutCardParams)
        -- 存储地主位置
        -- if self.lordSeat == -1  then
           -- print("Monkey lordSeat set ",takeOutCardParams.lordSeat)
           -- print("Monkey lordSeat get ",getLordSeatFromMonkey())
        -- end
        -- 更新存储3家牌的长度
        -- for k,v in pairs(takeOutCardParams.handCards[1]) do
        --     print("Monkey takeOutCardParams:",k,v)
        -- end
        -- print("Monkey handCard ",aiUtil.printt(takeOutCardParams.handCards[1]))
        -- 和文档的key不符合
        --位置是否有序,只是顺序很奇怪
        local selfCardCount = #takeOutCardParams.handCards[1].handCardListInt;
        local preCardCount = #takeOutCardParams.handCards[2].handCardListInt;
        local nextCardCount = #takeOutCardParams.handCards[3].handCardListInt;
        -- 注意顺序是021,即self,pre,next
        print("Monkey takeOutCardParams seat:",takeOutCardParams.handCards[1].seat,takeOutCardParams.handCards[2].seat,takeOutCardParams.handCards[3].seat)
        aiUtil.setValue2Storage("cardCount",{selfCardCount,nextCardCount,preCardCount})

        


        local lastTakeOutCardGroup = nil
        ---历史出牌记录
        local lastTakeOutPos
        local takeOutCardRecord = takeOutCardParams.cardRecord
        if #takeOutCardRecord > 0 then
            local i = #takeOutCardRecord
            while takeOutCardRecord[i] do
                if takeOutCardRecord[i].seat ~= takeOutCardParams.seat then
                    if takeOutCardRecord[i].cardValue ~= -1 then
                        -- 非pass
                        lastTakeOutCardGroup = {}
                        lastTakeOutCardGroup.cardList = takeOutCardRecord[i].cardList
                        lastTakeOutCardGroup.cardValue = takeOutCardRecord[i].cardValue
                        lastTakeOutCardGroup.cardType = takeOutCardRecord[i].cardType
                        lastTakeOutPos = takeOutCardRecord[i].seat
                        break
                    else
                       -- pass
                       
                    end
                else
                    -- 自己首出
                    lastTakeOutPos = -1
                    break
                end
                i = i - 1
            end
        else
            lastTakeOutPos = -1
        end
        -- 存储最后一个出牌的位置
        print("Monkey lastSeat set ",lastTakeOutPos)
        aiUtil.setValue2Storage("lastSeat",lastTakeOutPos)
        -- 全局一下牌局记录,用于牌局日志上传
        self.RecordLog = takeOutCardRecord

        if self.Record == 0 then
             -- 自己是地主
             if takeOutCardParams.seat == takeOutCardParams.lordSeat  and lastTakeOutCardGroup ~= nil then
                -- 做一下接口检查，防止发生出牌记录没有清空的问题
                print("Monkey doTakeOutCards Record check error  ",aiUtil.printt(lastTakeOutCardGroup))
             end
        end

        local ret ={}
        if lastTakeOutCardGroup == nil then
            --- 上手牌为空
            print("Monkey上手牌为空")
            ret = self:getRobotBySeat(takeOutCardParams.seat):takeOutCard(nil)
        else
            print("Monkey上手牌不为空")
            print("Monkey doTakeOutCards, lastPost:",lastTakeOutPos, ", cardType:", lastTakeOutCardGroup.cardType, "cardValue:", lastTakeOutCardGroup.cardValue)
            -- print("Monkey",aiUtil.printt(lastTakeOutCardGroup.cardList))
            -- TODO 直接将牌型带过去
            ret = self:getRobotBySeat(takeOutCardParams.seat):takeOutCard(lastTakeOutCardGroup.cardList)
        end
        print("Monkey doTakeOutCards send cards, seat:",takeOutCardParams.seat, ",cards:", aiUtil.printt(ret))
        -- pass的出法
        if ret.cardType == 0 and ret.cardValue == 0 then
            ret = nil
        end
        self.Record = self.Record +1 ;
        return ret
    end,function(errorMessage) 
        errtrace =  "LUA ERROR: " .. tostring(errorMessage) .. debug.traceback("", 2)
    end)
    if ret == false then
        -- local x= string.find(result,"%:%d+",1)
        -- local tmp = string.sub(result, x, #result)
        -- 截取异常的关键信息
        aiUtil.showError("AI error6:"..errtrace)
        -- error("AI error6")
        -- 出错了就pass
        return nil
    else
        return result
    end     
end
-- 获取牌局日志
function  Monkey:getLog()
    -- 地主位置
    local lordSeat  = aiUtil.getLordSeatFromMonkey()
    -- 3 家手牌
    local preInts = aiUtil.getValue4Strorage("preIntCards")
    local nextInts = aiUtil.getValue4Strorage("nextIntCards")

    local playerInts = aiUtil.getValue4Strorage("playerIntCards")
    local bottomInts = aiUtil.getValue4Strorage("bottomIntCards")
    local logR =  {lordSeat=lordSeat,pre=preInts,next=nextInts,curr=playerInts,bottom=bottomInts}
    -- local json = require("framework.shared.json")
    -- 牌局记录
    local record = {}
     -- print("Monkey record",aiUtil.printt(self.RecordLog))
        --解析出牌记录，形成日志
        for i,v in ipairs(self.RecordLog) do
            local tmp = {}
            tmp.seat = v.seat
            if v.cardValue ~= -1 then
                local cs  = {}
                for k,j in ipairs(v.cardList) do
                    table.insert(cs,j.original)
                end
                tmp.cards = cs 
            end
            table.insert(record,tmp)
        end
    -- print("Monkey record",aiUtil.printt(record))
    logR.rec=record
    -- 附带上error标志
    if aiUtil.MonkeyErrorFlag then
        logR.error=aiUtil.MonkeyErrorFlag
        aiUtil.MonkeyErrorFlag = nil
    end
    local jsonString = json.encode(logR)
    return jsonString
end
function Monkey:getRobotBySeat(seat)
    local cRobot;
    if seat == 2 then
       cRobot = self.preRobot
    elseif seat == 1 then
       cRobot = self.nextRobot
    elseif seat == 0 then 
       if autoTest then 
       	cRobot = self.humRobot
       end
    end
    return cRobot;
end
return Monkey
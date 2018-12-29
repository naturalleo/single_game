--AI的工具类
-- 依赖的函数库
require "utils/table_util"
require "utils.vardump"
local func = require("ai.func")
local aiUtil ={}
-- AI的全局存储
MonkeyStorage = {}
-- 是否自动测试
local autoTest = false
local logSwitch = false
aiUtil.MonkeyErrorFlag = nil
aiUtil.isEnding = false
-- 存储全局值
function aiUtil.setValue2Storage(key,value)
    MonkeyStorage[key] = value
end
-- 获取全局值,普通数据直接返回，表数据table.clone后返回
function aiUtil.getValue4Strorage(key)
    local value =  MonkeyStorage[key]
    if type(value) == "table" then
        return  table.clone(value)
    else
        return value
    end
end
-- 获取地主位置
function aiUtil.getLordSeatFromMonkey()
    local v = aiUtil.getValue4Strorage("lordSeat")
    return v
end
-- 获取上手牌位置
function aiUtil.getLastSeatFromMonkey()
    local v = aiUtil.getValue4Strorage("lastSeat")
    return v
end
-- 获取3家手牌数目
-- 返回{#0号位张数,#1号位张数,#2号位张数}
function aiUtil.getCardCountFromMonkey()
    local v = aiUtil.getValue4Strorage("cardCount")
    return v
end
-- 获取玩家手牌
function aiUtil.getPlayerIntCardsFromMonkey()
    local v = aiUtil.getValue4Strorage("playerIntCards")
    return v
end
-- 获取底牌
function aiUtil.getBottomIntCardsFromMonkey()
    local v = aiUtil.getValue4Strorage("bottomIntCards")
    return v
end
-- 获取NPC位置，决定AI分支
function aiUtil.getNPCSeatFromMonkey()
    local v = aiUtil.getValue4Strorage("npcSeat")
    return v
end
-- 获取NPC等级
function aiUtil.getNPCLevelFromMonkey()
    local v = aiUtil.getValue4Strorage("npcLevel")
    return v
end
-- 获取NPCId
function aiUtil.getNPCIdFromMonkey()
    local v = aiUtil.getValue4Strorage("npcId")
    return v
end
-- 获取aiLevel
function aiUtil.getAILevelFromMonkey(curSeat)
    local npcSeat = aiUtil.getNPCSeatFromMonkey()
    if npcSeat == curSeat then 
        local v = aiUtil.getValue4Strorage("aiLevel")
        return v
    else
        return 4
    end  
end
-- 获取注册的ai参数
function aiUtil.getAIParamFromMonkey(key)
    local params = aiUtil.getValue4Strorage("aiParams")
    if params then
        return params[key] 
    else
        return nil
    end 
end 
-- 弹出界面提示
function aiUtil.showAlert(txt)
	if logSwitch then 
        -- 注释掉NPC说话
        -- jj.ui.JJToast:show({text = txt})
    end
end
function aiUtil.showBtn()
	if not autoTest then 
       	 -- MonkeyParent:showBug()
    end
end
function aiUtil.showError(txt)
	if not autoTest then 
       	aiUtil.showAlert(txt)
    	aiUtil.uploadError(txt)
    end
    print(txt)
end
function aiUtil.uploadError(sign)
	--aiUtil.MonkeyErrorFlag = crypto.encodeBase64(sign)
	if not autoTest then 
       -- MonkeyParent:doHttp()
    end
end
--打印表格
function aiUtil.printt(tt)
    if logSwitch then 
        return vardump(tt)
    else
        return "online disable vardump"
    end 
end

function aiUtil.getNextSeat(currSeat)
    local nextSeat = (currSeat==2 and 0 ) or currSeat+1;
    print("aiUtil nextSeat ",currSeat,nextSeat)
    return nextSeat
end
--提供一个AI参数函数，用来观察所有的AI参数，具体细节还是分布在HumAI和Action中
function aiUtil.registerAIParam(paramName,paramValue,desc)
    print("Monkey registerAIParam",paramName,paramValue,desc)
    local params = aiUtil.getValue4Strorage("aiParams")
    if params == nil then 
        -- 初始化
        params = {}
    end 
    params[paramName] = paramValue
    aiUtil.setValue2Storage("aiParams",params)
end
local function pretreat_num(handpoker)
    -- print("handpoker:"..table.concat(handpoker,","))
    local ret  ={}
    local kingValue  ={}
    local nokingValue ={}
    local noking ={0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0};
    -- 找出大小王
    table.sort(handpoker)
    -- table_print(handpoker)
    -- A 14 2 15 mj 16 bj 17
    -- TODO 定义王值
    for k,v in pairs(handpoker) do
        if v < 16 then
            table.insert(nokingValue,v)
        else
            table.insert(kingValue,v)
        end
    end
    -- table.sort(nokingValue)
    -- 归并牌值
    for k,v in pairs(nokingValue) do
        noking[v] = noking[v] +1
        -- print(k,v);
    end

    -- TODO 具体应该放那一位
    if #kingValue > 0 then
        for k,v in pairs(kingValue) do
            noking[v] = noking[v] +1
            -- print(k,v);
        end
    end
    ret.king = kingValue
    ret.noking = noking
    return ret;
end
function aiUtil.pretreat_jj(handpoker)
    return pretreat_num(handpoker)
end
-- 获取剩余手数
function aiUtil.get_left_hand_counts(left, max_value)
     print("HumAI get_left_hand_counts",#left,table.concat(left,","),max_value)
    local leftcount=0;
    for i=3,max_value do
        if left[i] > 0 then
            leftcount=leftcount+1;
        end
    end
    return leftcount;
end

-- 查找最小单张（拆对）
function aiUtil.litter_single(myCards)
    print("Action litter_single")
    for i=3,20 do
        local tmp=myCards[i];
        if tmp >0 then
            return  {i};
        end
    end
    return nil;
end
-- 查找最小单张（拆对）
function aiUtil.litter_single_by_cardpoint(points)
    print("Action litter_single_by_cardpoint",table.concat( points, ", "))
    local tmp = table.clone(points)
    table.sort( tmp, function(card1,card2) 
        return card1 < card2
    end )
    return {tmp[1]}
end
-- 查找最小对
function aiUtil.litter_pair(myCards)
    print("Action litter_pair")
    for i=3,20 do
        local tmp=myCards[i];
        if tmp ==2 then
            return  {i,i};
        end
    end
    return nil;
end
-- 查找3龙带牌
function aiUtil.three_long_daipai(leftpoker,longLen)
    print("Action three_long_daipai",longLen)
    local daipai = {};
    local begin= 3;
    local endIndex= 20;
    local count = longLen
    -- 先全部带单
    for i = begin ,endIndex do 
        -- 优先找最小的单牌
        if leftpoker[i] == 1 then
            table.insert(daipai,i)
            count= count-1
            if count == 0 then 
                 break;
            end
        end
    end
    if #daipai == longLen then
        return daipai
    else
        --不够就清空了重来
        daipai = {};
    end
    -- 再全部带双
    local count = longLen
    for i = begin ,endIndex do 
        -- 优先找最小的单牌
        if leftpoker[i] == 2 and i < 15 then
            table.insert(daipai,i)
            table.insert(daipai,i)
            count= count-1
            if count == 0 then 
                 break;
            end
        end
    end
    if #daipai == longLen*2 then
        return daipai
    else
        --不够就清空了重来
        daipai = {};
    end
    -- 不行寻求混合模式(双牌凑单牌数)
    local count = longLen
    for i = begin ,endIndex do 
        if leftpoker[i] > 0 and i < 15 then
            table.insert(daipai,i)
            count= count-1
            if leftpoker[i] == 2 then
                table.insert(daipai,i)
                count= count-1
            end
            if count == 0 then 
                 break;
            end
        end
    end
    if #daipai == longLen then
        return daipai
    else
        --没有找到合适可带的
        -- print("Action three_long_daipai",aiUtil.printt(mode),aiUtil.printt(daipai))
        return {}
    end
end
-- 计算某张牌的张数
local function countCardPoint(top,point)
    local count = top.data.leftpoker[point]
    -- 可能有3个或者4个
    if point <=15 then 
        for k,v in pairs(top.data.composition) do
            if v.cardtype == 3 and v.pokers[1] == 15 then
                count = 3
            end
            if v.cardtype == 4 and v.pokers[1] == 15 then
                count = 4
            end
        end
    end 
    return count
end
--TODO 下面2个函数，可以考虑包装成工具函数对外
-- 是否有火箭
local function hasJokerPair(pokers)
    print("Action hasJokerPair")
    local pokerarray=pokers.data.leftpoker;
    if pokerarray[16] >0 and pokerarray[17] >0 then
        return true;
    end
    return false;
end
-- 获取炸弹
local function getFour(pokers)
    print("Action getFour")
    for i, mode in pairs(pokers.data.composition) do
        if mode and mode.type==4 then
            return mode;
        end
    end
end
--是否具有好牌V2
function aiUtil.hasGoodSinglev2(top)
    if (hasJokerPair(top) or getFour(top) ) and func.randomChance(7) then
        aiUtil.showAlert("炸弹叫地主")
        return true
    end 
    --计算2的个数
    if countCardPoint(top,15) >0 and func.randomChance(7) then
        aiUtil.showAlert("有2叫地主")
        return true
    end
    if countCardPoint(top,16) == 0 and countCardPoint(top,17)==0 and countCardPoint(top,15)==0 and countCardPoint(top,14)>=2 and func.randomChance(3) then 
        aiUtil.showAlert("大牌叫地主")
        return true
    end  
    -- 都没有命中
    return false    
end

return aiUtil
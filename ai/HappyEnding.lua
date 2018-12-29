--残局AI的特殊逻辑
-- 依赖的函数库
local func = require("ai.func")
-- 依赖的工具库
local aiUtil= require("ai.aiUtil")
local CardPattern = require("logic.CardPattern")
local SINGLELORD_XHCG_MESS_CONDITION_PATH = "data/SingleMessCondition.lua"
local SINGLELORD_XHCG_MESS_DATA_PATH = "data/SingleMessData.lua"
--TODO 逐步取消掉playerStep，因为这个比较难以计算.改用自己手牌和地主手牌来决定.
-- 是否残局测试包
local isTest = false
local HappyEnding = {}
local messCondition = nil
--游戏步数
local playerStep = 0
--[[
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
]]--
--默认游戏条件
--注意，前面可能有特殊字符，需要手动处理一下，不能够直接复制使用
local messConditionData = {
    --1
    {
        "lastSeat==-1 and currSeat==2 and isCardsEqual(6,6,15) and islordCardsEqual(13,13,16) then 6",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(6,6,8,14,15) and islordCardsEqual(13,13,15,16) then 6,6",
        "lastSeat==0 and currSeat==2 and type==1 and value<13 and isCardsEqual(6,6,8,9,10,11,12,13,14) then 13",
        "lastSeat==1 and currSeat==2 and type==1 and value==7 and isCardsEqual(6,6,8,9,10,11,12,13,14,15) then 15",
        "lastSeat==2 and currSeat==1 and type==2 and isCardsEqual(7,8,8,17) then 8,8",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(6,6,8,15) then 8",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(6,6,8,14,15) and islordCardsEqual(16) then 6,6",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(6,6,8,14,15) and islordCardsEqual(13,13,16) then 8",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(6,6,14,15) and islordCardsEqual(13,13,16) then 14",
    },
    --2
    {
        "lastSeat==0 and currSeat==2 and type==2 and value==6 and hasCard(7) then 7,7",
    },
    --3
    {
        "lastSeat==0 and currSeat==1 and type==1 and value==10 and hasCard(12) then 12",
        "lastSeat==0 and currSeat==1 and type==3 and playerStep==1 then pass",
        "lastSeat==0 and currSeat==1 and type==1 and playerStep==1 and value==16 then pass",
    },
    --4
    {
        "lastSeat==1 and currSeat==2 and type==1 and value<14 and hasCard(14) then 14",
    },
    --5
    {
        "lastSeat==0 and currSeat==1 and type==1 and value==8 and isCardsEqual(7,8,15) then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value==8 and playerStep==3 and hasCard(7) then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value==7 and hasCard(8) then 8",
        "lastSeat==0 and currSeat==1 and type==1 and value==8 and playerStep==1 then pass",
    },
    --6
    {
        "lastSeat==-1 and currSeat==2 and count==4 and isCardsEqual(4,9,9,14) then 4",
    },
    --7
    {
        "lastSeat==0 and currSeat==2 and isCardsEqual(7,8,13,13,13,16,17) and islordCardsEqual(3,3,3,6,8,14,14,14) then 16,17",
        "lastSeat==0 and currSeat==1 and type==1 and value==8 and islordCardsEqual(3,3,3,6) then 12",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(7,8) and islordCardsEqual(3,3,3,6,8,14,14,14) then 8",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(7,8) and islordCardsEqual(3,3,3,6,8,14,14,14) then 8",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(7,13,13,13,16,17) then 16,17",
        "lastSeat==1 and currSeat==2 and type==1 and value<8 then 8",
        "lastSeat==-1 and currSeat==1 and nextCount==7 and hasCard(4) then 4",
        "lastSeat==0 and currSeat==2 and type==20 and isCardsEqual(7,8,13,13,13,16,17) and islordCardsHas(14,14,14) then pass",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(7,8,13,13,13) and islordCardsEqual(3,3,3,6,8,14,14,14) then 13,13,13",
        "lastSeat==0 and currSeat==2 and type==2 and isCardsEqual(7,8,13,13,13,16,17) and islordCardsHas(14,14,14) then pass",
        "lastSeat==1 and currSeat==2 and type==20 then pass",
        "lastSeat==0 and currSeat==2 and type==2 and value==8 and count==7  then pass",
        "lastSeat==0 and currSeat==1 and type==2 and value==8 and count==10 then pass",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(7,8,13,13,13,17) then 7",
        "lastSeat==0 and currSeat==2 and type==1 and value==14 and count==7 then 16,17",
        "lastSeat==0 and currSeat==2 and type==1 and value>8 and value<14 and count==7 then 16",
        "lastSeat==0 and currSeat==2 and type==1 and value<8 and count==7 then 8",
        "lastSeat==0 and currSeat==1 and type==1 and count==10 then pass",
        "lastSeat==0 and currSeat==1 and type==10 and value==3 and islordCardsHas(14,14,14) then pass",
    },
    --8
    {
        "lastSeat==0 and currSeat==2 and type==1 and value<13 and count==10 then 13",
        "lastSeat==0 and currSeat==2 and type==1 and value==13 and isCardsEqual(6,6,6,9,10,11,12,13,13,17) then 17",
        "lastSeat==0 and currSeat==1 and type==1 and count==9  and islordCardsHas(15,15,15,15)  then pass",
    },
    --9
    {
        "lastSeat==-1 and currSeat==1 and count==3 and isCardsEqual(4,15,15) then 15,15",
        "lastSeat==-1 and currSeat==1 and islordCardsEqual(9,10,11,12,13) and count==13 then 9,10,11,12,13,14",
        "lastSeat==-1 and currSeat==1 and islordCardsEqual(9,10,11,12,13) and count==14 then 4",
        "lastSeat==2 and currSeat==1 and count==15 then pass",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(4,6,10,15,15,17) then 10",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(4,6,9,10,15,15,17) then 9",
        "lastSeat==0 and currSeat==2 and type==1 then pass",
        "lastSeat==1 and currSeat==2 and type==1 and value==4 then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value<9 and count==15 and hasCard(9) then 9",
        "lastSeat==0 and currSeat==1 and type==1 and value<14 and count==15 and hasCard(14) then 14",
        "lastSeat==0 and currSeat==1 and type==1 and value==15 and count==15 and islordCardsHas(15) then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value==15 and islordCardsEqual(7,7,15) then pass",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(4,6,7,9,10,15,15,17) then 7",
    },
    --10
    {
        "lastSeat==0 and currSeat==2 and type==20 and count==9 and len==7 and value==13 then pass",
        "lastSeat==0 and currSeat==2 and type==20 and count==9 and len<7 then pass",
        "lastSeat==0 and currSeat==2 and type==20 and count==9 and len==7 and lordCount==4 then 8,9,10,11,12,13,14",
        "lastSeat==0 and currSeat==2 and type==20 and count==9 and len==6 and lordCount==7 then 8,9,10,11,12,13",
        "lastSeat==0 and currSeat==2 and type==1 and value==13 and islordCardsHas(4,4,.*,15) then pass",
        "lastSeat==0 and currSeat==2 and type==1 and value==13 and islordCardsHas(6,6,.*,15) then pass",
        "lastSeat==0 and currSeat==2 and type==1 and value==6 and count==9 and lordCount==11 and hasCard(13) then pass",
        "lastSeat==0 and currSeat==2 and type==1 and value==6 and count==9 and islordCardsEqual(4,4,7,8,9,10,11,12,15) and hasCard(7) then 7",
        "lastSeat==0 and currSeat==2 and type==1 and value==6 and count==9 and lordCount==10 and hasCard(7) then 7",
        "lastSeat==0 and currSeat==2 and type==1 and value==4 and count==9 and lordCount==10 and hasCard(14) then 14",
        "lastSeat==0 and currSeat==2 and type==1 and value==12 and count==8 and lordCount==9 and hasCard(13) then pass",
        "lastSeat==0 and currSeat==2 and type==1 and value<13 and count==9 and hasCard(13) then 13",
    },
    --11
    {
        "lastSeat==0 and currSeat==1 and type==2 and value==6 and hasCard(13)  then 13,13",
        "lastSeat==0 and currSeat==1 and type==2 and value==5 and hasCard(13)  then 13,13",
        "lastSeat==0 and currSeat==1 and type==2 and value==12 and hasCard(13) then 13,13",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(3,3,3,4,4,7,9,10,11,12,13,14,15)  then 3,3,3,7",
        "lastSeat==0 and currSeat==1 and type==20 and len==5 and islordCardsHas(5,5,.*,15) then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value<15 then 15",
        "lastSeat==0 and currSeat==1 and type==3 and value==6  then pass",
        "lastSeat==0 and currSeat==1 and type==10 and value==6  then pass",
        "lastSeat==0 and currSeat==1 and type==11 and value==6  then pass",
    },
    --12
    {
        "lastSeat==0 and currSeat==2 and type==2 and value==9 and islordCardsEqual(5,5,12,16,17) then 10,10",
        "lastSeat==0 and currSeat==2 and type==2 and value==8 and islordCardsEqual(5,5,12,16,17) then 10,10",
        "lastSeat==0 and currSeat==2 and type==2 and value==9 and islordCardsHas(5,5,8,8) then pass",
        "lastSeat==0 and currSeat==2 and type==2 and value==8 and islordCardsHas(5,5,9,9) then pass",
    },
    --13
    {
        "lastSeat==2 and currSeat==1 and type==20 and isCardsHas(4,.*,6,13) then pass",
        "lastSeat==0 and currSeat==1 and type==20 and isCardsHas(4,.*,6,13) then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value>=13 and isCardsEqual(4,4,4,4,5,5,5,6,13) and islordCardsHas(15,15,15) and nextCount~=1 then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value>=13 and isCardsEqual(4,4,4,4,5,5,5,6,13) and islordCardsHas(6,6,6) and nextCount~=1 then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value==16 and isCardsHas(4,.*,6,13) and islordCardsEqual(5,9,15,15,15) then pass",
        "lastSeat==0 and currSeat==1 and type==3  and value>5 and isCardsHas(4,.*,6,13) then pass",
        "lastSeat==0 and currSeat==1 and type==10 and value==15 and isCardsHas(4,.*,6,13) and islordCardsHas(9,10,11,12,13) then pass",
        "lastSeat==0 and currSeat==1 and type==10 and value==6 and isCardsHas(4,.*,6,13) then pass",
    },
    --14
    {
        "lastSeat==-1 and currSeat==2 and isCardsEqual(3,3,4,4,5,5,13,15) then 3,3",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(4,4,5,5,13,15) then 4,4",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(5,5,13,15) then 5,5",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(13,15) then 15",
        "lastSeat==0 and currSeat==1 and type==2 and value==7 and islordCardsEqual(8,8,9,9,11,11,11,11,14) then 10,10",
        "lastSeat==0 and currSeat==1 and type==2 and value==8 and islordCardsEqual(7,7,9,9,11,11,11,11,14) then 10,10",
        "lastSeat==0 and currSeat==1 and type==2 and value==9 and islordCardsEqual(7,7,8,8,11,11,11,11,14) then 10,10",
        "lastSeat==0 and currSeat==1 and type==1 and isCardsEqual(6,10,10) then pass",
        "lastSeat==0 and currSeat==1 and type==1 and isCardsEqual(3,4,5,6,6,7,10,10) then pass",
        "lastSeat==2 and currSeat==1 and nextCount~=1 and islordCardsHas(11,11,11,11) then pass",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(3,3,4,4,5,5,15) then 15",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(3,3,4,4,5,5,15,15) then 15,15",
        "lastSeat==0 and currSeat==2 and type==1 and value==14 and hasCard(15) then 15",
        "lastSeat==0 and currSeat==2 and type==2 and isCardsHas(15,15) then 15,15",
        "lastSeat==0 and currSeat==1 and type==1 and islordCardsHas(11,11,11,11) then pass",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(3,3,4,4,5,5,13,13) and islordCardsHas(7,7,8,8,8,9,9) then 13,13",
        "lastSeat==0 and currSeat==2 and type==1 and value==8 and isCardsEqual(3,3,4,4,5,5,13,13,15,15) then 13",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(3,3,4,4,5,5,13,15,15) then 13",
        "lastSeat==0 and currSeat==1 and type==2 and islordCardsHas(11,11,11,11) then pass",
    },
    --15
    {
        "lastSeat==0 and currSeat==1 and type==1 and value==3 and isCardsEqual(4,5,5) and islordCardsEqual(4,5) then 5",
        "lastSeat==0 and currSeat==1 and type==1 and value==3 and hasCard(4) then 4",
        "lastSeat==0 and currSeat==1 and type==2 and value==7 and isCardsEqual(3,4,5,5,15,15) and islordCardsEqual(3,4,5,5) then 15,15",
        "lastSeat==0 and currSeat==1 and type==1 and value==4 and isCardsHas(3,4,5,5,15,15) then pass",
        "lastSeat==0 and currSeat==1 and type==2 and value==7 and isCardsEqual(3,4,5,5,15,15) and islordCardsEqual(3,5,5) then pass",
        "lastSeat==0 and currSeat==1 and type==2 and value==7 and isCardsEqual(3,4,5,5,15,15) and islordCardsEqual(3) then 15,15",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(3,5,5,15,15) and islordCardsEqual(7,7) then 3",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(3,4,5,5,15) then 4",
        "lastSeat==0 and currSeat==1 and type==1 and value==5 and isCardsHas(3,4,5,5,15,15) and islordCardsHas(5) then pass",
        "lastSeat==0 and currSeat==1 and type==2 and value==5 and isCardsEqual(3,4,5,5,15,15) and islordCardsHas(7) then pass"
    },
    --16
    {
        "lastSeat==0 and currSeat==2 and type==3 and value==7 and isCardsEqual(10,13,15,15,15) and islordCardsHas(11,11,11) then pass",
        "lastSeat==0 and currSeat==2 and type==3 and value==11 and isCardsEqual(10,13,15,15,15) and islordCardsHas(7,7,7) then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value==11 and isCardsEqual(10,10,11,12,13,14) and nextCount==5 then pass"
    },
    --17
    {
        "lastSeat==0 and currSeat==1 and isCardsEqual(12,13,16,17) and islordCardsEqual(9) then 16,17",
        "lastSeat==0 and currSeat==1 and type==2 and value==15 and islordCardsHas(15,15) then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value==15 and isCardsEqual(12,13,16,17) and islordCardsEqual(11,11) then 16,17",
        "lastSeat==0 and currSeat==1 and type==3 and isCardsEqual(12,13,16,17)  then pass",
        "lastSeat==0 and currSeat==1 and type==11 and isCardsEqual(12,13,16,17) then pass",
        "lastSeat==0 and currSeat==1 and type==10 and isCardsEqual(12,13,16,17) then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value<12 and isCardsEqual(12,13,16,17) then 12"
    },
    --18
    {
        "lastSeat==0 and currSeat==1 and type==20 and isCardsEqual(9,11,11,13,13,16,17) and islordCardsHas(15,15) then pass",
        "lastSeat==0 and currSeat==1 and type==20 and isCardsEqual(11,11,13,13,16,17) and islordCardsHas(15,15,15) then pass",
        "lastSeat==1 and currSeat==2 and type==1 and value==9 then 15",
        "lastSeat==0 and currSeat==1 and type==4 and isCardsEqual(9,11,11,13,13,16,17) and islordCardsHas(15,15,15) then pass",
        "lastSeat==0 and currSeat==1 and type==20 and isCardsEqual(9,13,13,16,17) and islordCardsHas(4,4,4,4) then pass",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(13,14,15) then 15",
        "lastSeat==0 and currSeat==1 and isCardsHas(16,17) and nextCount==1 then 16,17",
        "lastSeat==-1 and isCardsEqual(11,11,13,13)  and nextCount==1 then 11",
        "lastSeat==0 and currSeat==1 and type==4 and isCardsEqual(11,11,13,13,16,17) and islordCardsHas(15,15,15) then pass",
        "lastSeat==0 and currSeat==1 and type==2 and value==15 and isCardsEqual(9,13,13,16,17) and islordCardsHas(4,4,4,4) then pass",
        "lastSeat==2 and currSeat==1 and type==20 and nextCount~=1 then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value>=9 and isCardsEqual(9,11,11,13,13,16,17) and islordCardsHas(15,15,15) then pass",
    },
    --19
    {
        "lastSeat==1 and currSeat==2 and isCardsEqual(3,3,3,3) then 3,3,3,3",
        "lastSeat==0 and currSeat==1 and type==2 and value<15 and isCardsHas(15,15) then 15,15",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(4,5,5,5,6,6,6,10,10,14,14,14) then 4,5,5,5,6,6,6,10",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(4,5,5,5,6,6,6,15,15) then 4,5,5,5,6,6,6,15",
        "lastSeat==0 and currSeat==1 and type==1 and value<15 and lordCount==19 then 15",
        "lastSeat==2 and currSeat==1 and type==10 then pass",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(5,5,5,6,6,6,10,10,15,15) then 5,5,5,6,6,6,10,10,15,15",
        "lastSeat==1 and currSeat==2 and type~=1 then pass",
        "lastSeat==0 and currSeat==1 and type==2 and value=12 and isCardsEqual(10,10,14,14,14) then pass",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(9,9,9,10,11,11,12,13,14) and islordCardsHas(9,10,11,12,13) then 9,9,9,11",
    },
    --20
    {
        "lastSeat==-1 and currSeat==2 and isCardsEqual(8,11,12,17) and islordCardsHas(12) then 12",
        "lastSeat==-1 and currSeat==2 and isCardsEqual(8,11,12,14,14,14)  and islordCardsHas(15,16) then 14,14",
        "lastSeat==-1 and currSeat==1 and isCardsEqual(14,15,15) then 15,15",
        "lastSeat==0 and currSeat==2 and type==1 and value==16 and lordCount==15 then pass",
        "lastSeat==0 and currSeat==1 and type==1 and value==12 and isCardsEqual(9,10,11,12,13,14,15,15) and islordCardsHas(16) then 14",
        "lastSeat==0 and currSeat==1 and type==1 and value<12 and islordCardsHas(16) then pass",
    },
}
-- string.split = function(s, p)
--     local rt= {}
--     string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
--     return rt
-- end

local function str2int(arr)
    local tmp = {}
    for i,v in ipairs(arr) do
        table.insert(tmp,tonumber(v))
    end
    return tmp 
end	
local function formatData(data)
	local tmp  = {}
		for i,v in ipairs(data) do
			local var  ={}
			 var.id = tonumber(v.id)
	         var.defaultLevel = tonumber(v.defaultLevel)
	         var.selfCardInt = str2int(string.split(v.selfCardInt, ","))
	         var.preCardInt = str2int(string.split(v.preCardInt, ","))
	         var.nextCardInt = str2int(string.split(v.nextCardInt, ","))
	         table.insert(tmp,var)
		end
	return tmp
end
-- 响应http处理结果
local function onRequestFinished(event)
    print("HappyEnding http finish")
    local ok = (event.name == "completed")
    local request=event.request
 
    if not ok then
        -- 请求失败，显示错误代码和错误消息
        print("HappyEnding 获取残局条件失败:",request:getErrorCode(),request:getErrorMessage())
        return
    end
 
    local code = request:getResponseStatusCode()
    if code ~= 200 then
        -- 请求结束，但没有返回 200 响应代码
        print("HappyEnding 获取残局条件失败2:",code)
        return
    end
 
    -- 请求成功，显示服务端返回的内容
    local response = request:getResponseString()
    --TODO 不知道为啥多出了3个字节，需要截取一下
    local data  = json.decode(string.sub(response,4,-1))
    if data[1]["defaultLevel"] then 
    	LuaDataFile.save(formatData(data), SINGLELORD_XHCG_MESS_DATA_PATH)
    else
    	LuaDataFile.save(data, SINGLELORD_XHCG_MESS_CONDITION_PATH)
    end 
    print("HappyEnding 获取残局条件成功")
    print("-----HappyEnding.messCondition-----")
    print(response)
    print("-----HappyEnding.messCondition-----")
    aiUtil.showAlert("残局条件获取成功")
end
-- 处理http请求
local function doHttp(url)
    -- 创建一个请求，并以 POST 方式发送数据到服务端
    -- local url = "http://192.168.20.156/happyending/admin.php?f=getAllCondition"
    local request = network.createHTTPRequest(onRequestFinished, url, "GET")
    -- 开始请求。当请求完成时会调用 callback() 函数
    print("HappyEnding http start")
    request:start()
end

(function()
	if isTest then 
		print("HappyEnding auto get remote  condition ")
		doHttp("http://192.168.20.156/happyending/admin.php?f=getAllCondition")
		doHttp("http://192.168.20.156/happyending/admin.php?f=getAllMess")
	end 
end)()



-- 获取残局的条件
function HappyEnding.getConditon(level)
	--延迟初始化
    if not messCondition then
    	print("HappyEnding getConditon by file ")
        messCondition = LuaDataFile.get(SINGLELORD_XHCG_MESS_CONDITION_PATH)
        if messCondition == nil then
            --没有新数据就用旧数据 
            messCondition = messConditionData
            --没有文件就自己写一份
        	LuaDataFile.save(messCondition, SINGLELORD_XHCG_MESS_CONDITION_PATH)
            -- print("-----HappyEnding.messCondition-----")
            -- print(json.encode(messCondition))
            -- print("-----HappyEnding.messCondition-----")
        end 
    end
    return messCondition[level]
end

function HappyEnding.reset()
	print("HappyEnding reset")
	playerStep = 0
end
-- 注意：cardPoints未排序
function HappyEnding.takeOutCards(lastSeat,handsInfo,cardPoints,currSeat,level)
	print("HappyEnding takeOutCards", level)
	if handsInfo~=nil and  lastSeat == 0 then 
		--首发不计数，保护之前的管牌数据
		--TODO 这个步数计算不科学
		playerStep = playerStep +1 
	end
	local result ={}
	-- 防止管牌报错
	if handsInfo == nil then
		handsInfo = {}
		handsInfo.type = -1 
		handsInfo.value = -1 
	end 
	local levelData = HappyEnding.getConditon(level)
	if levelData then 
		local cards = HappyEnding.doConditions(levelData,lastSeat,currSeat,handsInfo.type,handsInfo.value,playerStep,cardPoints,handsInfo.length)
		if cards then 
			result.cards = cards
			result.seat = currSeat
			print("HappyEnding.takeOutCards ",aiUtil.printt(result))
			return result
		end
	end
	return nil
end

--执行关卡逻辑
function HappyEnding.doConditions(filters,lastSeat,currSeat,type,value,playerStep,cardPoints,len)
	-- 构造参数table
	print("HappyEnding.doConditions lastSeat",lastSeat,currSeat,type,value,playerStep)
	local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
	local lordSeat = 0
	local nextSeat = aiUtil.getNextSeat(currSeat)
	local lordCount = #totalObjCards[lordSeat+1]
	local nextCount = #totalObjCards[nextSeat+1]
	local params ={lastSeat=lastSeat,currSeat=currSeat,type=type,value=value,count=#cardPoints,
		playerStep=playerStep,cardPoints=cardPoints,len=len,lordCount=lordCount,nextCount=nextCount}
	for i=1,#filters do
		result = HappyEnding.executeFilter(filters[i],params)
		if result then 
			--TODO 同一个逻辑只会生效一次，优化性能时候可以考虑解析完成后直接删除
			break
		end 
	end
	return result
end
--执行表达式
function HappyEnding.executeFilter(filter,params)
	print("HappyEnding.executeFilter filter ",filter)
	local len = string.len(filter)
	local result 
	-- 分析条件和结果
	local x, y = string.find(filter, "then")
	local s = string.sub(filter,1,x-1)
	local re = string.sub(filter,y+2,len)
	-- 布尔条件判断，支持基础逻辑运算==,<,>,>=,<=,~=,支持条件组合and
	-- 支持函数判断has,#cards等
	-- TODO 支持条件组合中的or和（）
	-- print(s,re)
	local andConditions = HappyEnding.stringSplit(s," and ")
	for i,condition in pairs(andConditions) do
		--一定要取消空格防止错位
		condition = string.trim(condition)
		local len = string.len(condition)
		print("HappyEnding.executeFilter condition ",condition)
		local y= string.find(condition,"[=<>~]",1) --匹配符号
		if y then
			-- 普通表达式 
			local z= string.find(condition,"%d",1) --匹配数字
			local v1 =  params[string.sub(condition,1,y-1)]
			local op =  string.sub(condition,y,z-1)
			local v2 =  tonumber(string.sub(condition,z,len))
			--在首发的时候位置函数判断错误
			if op == "==-" then 
				op = "=="
				v2 = 0-v2
			end
			result = HappyEnding.evalCondition(v1,op,v2)
		else
			-- 函数表达式
			-- 下面不支持(*,13,13,15)之类已特殊符号开头的匹配
			local z= string.find(condition,"%d",1) --匹配数字
			local func = string.sub(condition,1,z-2)
			local param = string.sub(condition,z,len-1)--包含自己，所以是-2
			-- print(z,len,func,param)
			local f = HappyEnding[func]
			if func == "hasCard" then 
				result = f(params["cardPoints"],tonumber(param))
			elseif func == "isCardsEqual" then 
				result = f(params["cardPoints"],param)
			elseif func == "isCardsHas" then 
				result = f(params["cardPoints"],param)	
			elseif func == "islordCardsEqual" then
				result = f(param)
			elseif func == "islordCardsHas" then 
				result = f(param)
			end 
		end
		-- 布尔中断，节省性能
		if result == false then 
			break;
		end 
	end
	
	if result then
		result = {}
		if re ~= "pass" then 
			--String2Table
			local cards = re:split(",")
			for i,v in ipairs(cards) do
				table.insert(result,tonumber(v))
			end
		end
	else
		result = nil
	end
	return result
end
-- 分隔字符串
function HappyEnding.stringSplit( str,inSplitPattern, outResults )
   if not outResults then
      outResults = { }
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( str, inSplitPattern, theStart )
   while theSplitStart do
      table.insert( outResults, string.sub( str, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( str, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( str, theStart ) )
   return outResults
end
-- 计算表达式
function HappyEnding.evalCondition(v1,op,v2)
	print("HappyEnding.evalCondition",v1,op,"|",v2)
	if op == "==" then 
		return v1 == v2
	elseif op == "<" then
		return v1 < v2 
	elseif op == ">" then 
		return v1 > v2
	elseif op == "~=" then 
		return v1 ~= v2
	elseif op == "<=" then 	
		return v1 <= v2
	elseif op == ">=" then 
		return v1 >= v2
	end
end
--判断是否具有某张牌的函数
function HappyEnding.hasCard(cardPoints,point)
	print("HappyEnding.hasCard",aiUtil.printt(cardPoints),point)
	local ret = false
	for i,v in ipairs(cardPoints) do
		if v == point then 
			ret = true 
			break;
		end
	end
	return ret
end
--判断手牌是否符合条件（首发）
--TODO 函数名称换成equal合适一些
function HappyEnding.isCardsEqual(cardPoints,str)
	print("HappyEnding.isCardsEqual",aiUtil.printt(cardPoints))
	--先排序
	table.sort( cardPoints, function ( v1,v2 )
        return v1 < v2
    end )
    --转化为字符串
    local allString = table.concat(cardPoints,",")
    print("HappyEnding.isCardsEqual",allString,str)
    if allString == str then 
    	return true
    else
    	return false
    end
end
--判断地主手牌是否符合条件
function HappyEnding.islordCardsEqual(str)
	--从内存中取出地主的手牌
	print("HappyEnding.islordCardsEqual",str)
	local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
	local lordSeat = 0
    local lordPointCards = {}
    for i,v in ipairs(totalObjCards[lordSeat+1]) do
        table.insert(lordPointCards,v.value)
    end
    --先排序
    table.sort( lordPointCards, function ( v1,v2 )
        return v1 < v2
    end )
    --转化为字符串
    local allString = table.concat(lordPointCards,",")
    print("HappyEnding.islordCardsEqual",allString,str)
    if allString == str then 
    	return true
    else
    	return false
    end
end
--判断地主手牌是否包括条件,支持正则
function HappyEnding.islordCardsHas(str)
	--TODO 3,4,10,12,13,14,14 这样的判断有根3或者4的漏洞
	--从内存中取出地主的手牌
	print("HappyEnding.islordCardsHas",str)
	local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
	local lordSeat = 0
    local lordPointCards = {}
    for i,v in ipairs(totalObjCards[lordSeat+1]) do
        table.insert(lordPointCards,v.value)
    end
    --先排序
    table.sort( lordPointCards, function ( v1,v2 )
        return v1 < v2
    end )
    --转化为字符串
    local allString = table.concat(lordPointCards,",")
    local idx = string.find(allString, str)
    print("HappyEnding.islordCardsHas",allString,str,idx)
    if idx ~= nil then 
    	return true
    else
    	return false
    end
end
--判断自己手牌是否包括条件,支持正则
function HappyEnding.isCardsHas(cardPoints,str)
	--TODO 3,4,10,12,13,14,14 这样的判断有根3或者4的漏洞
	--从内存中取出地主的手牌
	print("HappyEnding.isCardsHas",aiUtil.printt(cardPoints),str)
	--先排序
	table.sort( cardPoints, function ( v1,v2 )
        return v1 < v2
    end )
    --转化为字符串
    local allString = table.concat(cardPoints,",")
    local idx = string.find(allString, str)
    print("HappyEnding.isCardsHas",allString,str,idx)
    if idx ~= nil then 
    	return true
    else
    	return false
    end
end 

return HappyEnding;
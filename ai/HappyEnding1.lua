--残局AI的特殊逻辑
-- 依赖的函数库
local func = require("ai.func")
local log_util = require("utils.log_util")
-- 依赖的工具库
local aiUtil= require("ai.aiUtil")
local CardPattern = require("logic.CardPattern")

--TODO 逐步取消掉playerStep，因为这个比较难以计算.改用自己手牌和地主手牌来决定.
local HappyEnding = {}
--游戏步数
local playerStep = 0

function HappyEnding.reset()
	if log_util.isDebug() == true then
    	print("HappyEnding reset")
	end

	playerStep = 0
end
-- 针对残局第一局牌谱是炸弹的残局逻辑
-- "lastSeat==0 and currSeat==1 and type~=5 and hasCard(14) then 14,14,14,14",
-- "lastSeat==0 and currSeat==1 and type~=5 and hasCard(15) then 15,15,15,15"

-- 注意：cardPoints未排序
function HappyEnding.takeOutCards(lastSeat,handsInfo,cardPoints,currSeat,level)
	if log_util.isDebug() == true then
    	print("HappyEnding takeOutCardsv2",level)
	end

	if handsInfo~=nil and  lastSeat == 0 then 
		--首发不计数，保护之前的管牌数据
		playerStep = playerStep +1 
	end
	local result ={}
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
	local data ={
		[1]={
			--当地主打到小王插底(2,5554,7776,KK,8~Q)的时候不能够打单
			--当地主打到小王+kk(2,5554,7776,8~Q)的时候不能够打双
			"lastSeat==-1 and currSeat==2 and hasCards(6,6,8,14,15) and islordCardsEqual(13,13,16) then 8",
			"lastSeat==-1 and currSeat==2 and hasCards(6,6,14,15) and islordCardsEqual(13,13,16) then 14",
			"lastSeat==-1 and currSeat==2 and hasCards(6,6,15) and islordCardsEqual(13,13,16) then 6",
			"lastSeat==-1 and currSeat==2 and hasCards(6,6,8,14,15) and islordCardsEqual(16) then 6,6",
			"lastSeat==-1 and currSeat==2 and hasCards(6,6,8,15) then 8",
			-- "lastSeat==-1 and currSeat==2 and type==1 and value=15 and playerStep==3 then pass",
			"lastSeat==2 and currSeat==1 and type==2 and hasCards(7,8,8,17) then 8,8",
			-- "lastSeat==0 and currSeat==1 and type==1 and value==15 and playerStep==1 then pass",
			-- "lastSeat==0 and currSeat==1 and type==1 and value==15 and playerStep==3 then pass",
			"lastSeat==1 and currSeat==2 and type==1 and value==7 and hasCards(6,6,8,9,10,11,12,13,14,15) then 15",
			--地主首发Q
			-- "lastSeat==0 and currSeat==1 and type==1 and value==12 and hasCards(7,8,8,17) then pass",
			"lastSeat==0 and currSeat==2 and type==1 and value<13 and hasCards(6,6,8,9,10,11,12,13,14) then 13",
			"lastSeat==0 and currSeat==2 and type==1 and value<13 and hasCards(6,6,8,9,10,11,12,13) then 13",
			--地主出小王有2+kk的时候不上大王
			"lastSeat==0 and currSeat==1 and type==1 and value==15 and islordCardsHas(4,.*,13,13,16) then pass",
			--地主出2有小王+kk的时候不上大王
			"lastSeat==0 and currSeat==1 and type==1 and value==16 and islordCardsHas(4,.*,13,13,15) then pass",
		},
		[2]={ 
			"lastSeat==0 and currSeat==2 and type==2 and value==6 and hasCard(7) then 7,7",
		},
		[3]={
			--防止空放小王勾引大王
			"lastSeat==0 and currSeat==1 and type==1 and playerStep==1 and value==16 then pass",
			--第一手3张不管，考验玩家坚持打散策略
			"lastSeat==0 and currSeat==1 and type==3 and playerStep==1 then pass",
			--防止有时候出10会pass
			"lastSeat==0 and currSeat==1 and type==1 and value==10 and hasCard(12) then 12"
		},
		[4]={
			--防止放单有时候pass
			"lastSeat==0 and currSeat==1 and type==1 and value<12 and hasCard(12) then 12",
			--防止首发2后，右手农民不用aa上手
			"lastSeat==1 and currSeat==2 and type==1 and value<14 and hasCard(14) then 14",
		},
		[5]={
			"lastSeat==0 and currSeat==1 and type==1 and value==8 and playerStep==1 then pass",
			"lastSeat==0 and currSeat==1 and type==1 and value==7 and hasCard(8) then 8",
			"lastSeat==0 and currSeat==1 and type==1 and value==8 and playerStep==3 and hasCard(7) then pass",
			"lastSeat==0 and currSeat==1 and type==1 and value==8 and hasCards(7,8,15) then pass",
		},
		[9]={
			--农民上家不管地主单
			"lastSeat==0 and currSeat==2 and type==1 then pass",
			"lastSeat==1 and currSeat==2 and type==1 and value==4 then pass",
			--初始能够过9就过9
			"lastSeat==0 and currSeat==1 and type==1 and value<9 and count==15 and hasCard(9) then 9",
			--初始能够过a就过a
			"lastSeat==0 and currSeat==1 and type==1 and value<14 and count==15 and hasCard(14) then 14",
			--地主首发2,上家农民不要管（首发的时候，自己的张数肯定是齐的）
			"lastSeat==0 and currSeat==1 and type==1 and value==15 and count==15 and islordCardsHas(15) then pass",
			--地主7~K顺子，然后上第一根2
			"lastSeat==0 and currSeat==1 and type==1 and value==15 and islordCardsEqual(7,7,15) then pass",
			"lastSeat==-1 and currSeat==1 and hasCards(4,6,7,9,10,15,15,17) then 7",
			"lastSeat==-1 and currSeat==1 and hasCards(4,6,9,10,15,15,17) then 9",
			"lastSeat==-1 and currSeat==1 and hasCards(4,6,10,15,15,17) then 10",
			--下家农民管7778后发单5，地主pass后，农民下家也pass
			"lastSeat==2 and currSeat==1 and count==15 then pass",
			--地主剩9~K的时候，注意不要放顺子让地主走。先放4如果不管就先放长顺，留短顺摆尾
			"lastSeat==-1 and currSeat==1 and islordCardsEqual(9,10,11,12,13) and count==14 then 4",
			"lastSeat==-1 and currSeat==1 and islordCardsEqual(9,10,11,12,13) and count==13 then 9,10,11,12,13,14",
			--剩一手22+4的时候就别调戏人打单2了
			"lastSeat==-1 and currSeat==1 and count==3 and hasCards(4,15,15) then 15,15",
		},
		[10]={
			--同一打法下先做排除条件，再做普通条件		
			--任意小于K的单牌都上K（需要排除K+6,以及K+6后的情况）
			"lastSeat==0 and currSeat==2 and type==1 and value==6 and count==9 and lordCount==11 and hasCard(13) then pass",
			"lastSeat==0 and currSeat==2 and type==1 and value==6 and count==9 and lordCount==10 and hasCard(7) then 7",
			"lastSeat==0 and currSeat==2 and type==1 and value==4 and count==9 and lordCount==10 and hasCard(14) then 14",
			--k/6不要，再出6上7，地主上Q后不要
			"lastSeat==0 and currSeat==2 and type==1 and value==12 and count==8 and lordCount==9 and hasCard(13) then pass",
			"lastSeat==0 and currSeat==2 and type==1 and value<13 and count==9 and hasCard(13) then 13",
			--任何情况下地主有2和对子的时候不要拆A管K
			"lastSeat==0 and currSeat==2 and type==1 and value==13 and islordCardsHas(6,6,.*,15) then pass",
			"lastSeat==0 and currSeat==2 and type==1 and value==13 and islordCardsHas(4,4,.*,15) then pass",
			-- --堵各种首发顺子
			--首发7~Q也必管
			"lastSeat==0 and currSeat==2 and type==20 and count==9 and len==6 and lordCount==7 then 8,9,10,11,12,13",
			-- 正解7~K必须管
			"lastSeat==0 and currSeat==2 and type==20 and count==9 and len==7 and lordCount==4 then 8,9,10,11,12,13,14",
			-- --小于7张长度的不管
			"lastSeat==0 and currSeat==2 and type==20 and count==9 and len<7 then pass",
			-- --7张到k，需要使用A的也不管
			"lastSeat==0 and currSeat==2 and type==20 and count==9 and len==7 and value==13 then pass",

		},
		--9局，牌局要过关就禁止炸弹/4带2
		[6]={
			--剩余499A的时候，先出4 
			"lastSeat==-1 and currSeat==2 and count==4 and hasCards(4,9,9,14) then 4",
		},
		--9局，牌局要过关就禁止炸弹/4带2
		[8]={
			--地主首出K，下家农民必上大王
			"lastSeat==0 and currSeat==1 and type==1 and count==9  and islordCardsHas(15,15,15,15)  then pass",
			"lastSeat==0 and currSeat==2 and type==1 and value==13 and hasCards(6,6,6,9,10,11,12,13,13,17) then 17",
			"lastSeat==0 and currSeat==2 and type==1 and value<13 and count==10 then 13",
		},
		[7]={
			--3带1让下家农民管
			"lastSeat==0 and currSeat==1 and type==10 and value==3 and islordCardsHas(14,14,14) then pass",
			--单牌农民下家都不管
			"lastSeat==0 and currSeat==1 and type==1 and count==10 then pass",
			--能够过7就优先过7好开炸
			"lastSeat==0 and currSeat==2 and type==1 and value<8 and count==7 then 8",
			--不能够过8就拆王
			"lastSeat==0 and currSeat==2 and type==1 and value>8 and value<14 and count==7 then 16",
			--先发A直接开炸
			"lastSeat==0 and currSeat==2 and type==1 and value==14 and count==7 then 16,17",
			--拆王后放单
			"lastSeat==-1 and currSeat==2 and hasCards(7,8,13,13,13,17) then 7",
			--对88农民都不要管
			"lastSeat==0 and currSeat==1 and type==2 and value==8 and count==10 then pass",
			"lastSeat==0 and currSeat==2 and type==2 and value==8 and count==7  then pass",
			--不要管队友的顺子
			"lastSeat==1 and currSeat==2 and type==20 then pass",
			--地主只有33368AAA时候开炸吧
			"lastSeat==0 and currSeat==2 and hasCards(7,8,13,13,13,16,17) and islordCardsEqual(3,3,3,6,8,14,14,14) then 16,17",
			--其它情况只要地主还有AAA就不要开炸
			"lastSeat==0 and currSeat==2 and type==2 and hasCards(7,8,13,13,13,16,17) and islordCardsHas(14,14,14) then pass",
			"lastSeat==0 and currSeat==2 and type==20 and hasCards(7,8,13,13,13,16,17) and islordCardsHas(14,14,14) then pass",
			--下家QQQ上手后发单让地主过单7
			"lastSeat==-1 and currSeat==1 and hasCard(4) then 4",
			"lastSeat==1 and currSeat==2 and type==1 and value<8 then 8",
			--自己双王+3带时候，先出双王，防止地主AAA溜出去
			"lastSeat==-1 and currSeat==2 and hasCards(7,13,13,13,16,17) then 16,17",
			--炸完在挣扎一下
			"lastSeat==-1 and currSeat==2 and hasCards(7,8,13,13,13) and islordCardsEqual(3,3,3,6,8,14,14,14) then 13,13,13",
			"lastSeat==-1 and currSeat==2 and hasCards(7,8) and islordCardsEqual(3,3,3,6,8,14,14,14) then 8",
		}
	}
	-- 防止管牌报错
	if handsInfo == nil then
		handsInfo = {}
		handsInfo.type = -1 
		handsInfo.value = -1 
	end 
	local levelData = data[level]
	if levelData then 
		local cards = HappyEnding.doConditions(levelData,lastSeat,currSeat,handsInfo.type,handsInfo.value,playerStep,cardPoints,handsInfo.length)
		if cards then 
			result.cards = cards
			result.seat = currSeat
			if log_util.isDebug() == true then
    			print("HappyEnding.takeOutCards ",aiUtil.printt(result))
			end

			return result
		end
	end
	return nil
end

--执行关卡逻辑
function HappyEnding.doConditions(filters,lastSeat,currSeat,type,value,playerStep,cardPoints,len)
	-- 构造参数table
	if log_util.isDebug() == true then
    	print("HappyEnding.doConditions lastSeat",lastSeat,currSeat,type,value,playerStep)
	end

	local totalObjCards = aiUtil.getValue4Strorage("TotalObjCards")
	local lordSeat = 0
	local lordCount = #totalObjCards[lordSeat+1]
	local params ={lastSeat=lastSeat,currSeat=currSeat,type=type,value=value,count=#cardPoints,
		playerStep=playerStep,cardPoints=cardPoints,len=len,lordCount=lordCount}
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
	if log_util.isDebug() == true then
    	print("HappyEnding.executeFilter filter ",filter)
	end

	local len = string.len(filter)
	local result 
	-- 分析条件和结果
	local x, y = string.find(filter, "then")
	local s = string.sub(filter,1,x-1)
	local re = string.sub(filter,y+2,len)
	-- 布尔条件判断，支持基础逻辑运算==,<,>,>=,<=,~=,支持条件组合and
	-- 支持函数判断has,#cards等
	-- TODO 支持条件组合中的or和（）
	-- if log_util.isDebug() == true then
    	-- print(s,re)
	-- end

	local andConditions = HappyEnding.stringSplit(s," and ")
	for i,condition in pairs(andConditions) do
		--一定要取消空格防止错位
		condition = string.trim(condition)
		local len = string.len(condition)
		if log_util.isDebug() == true then
    		print("HappyEnding.executeFilter condition ",condition)
		end

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
			-- local x= string.find(condition,"%a",1) --匹配字母
			local z= string.find(condition,"%d",1) --匹配数字
			local func = string.sub(condition,1,z-2)
			local param = string.sub(condition,z,len-1)--包含自己，所以是-2
			-- if log_util.isDebug() == true then
    			-- print(z,len,func,param)
			-- end

			local f = HappyEnding[func]
			if func == "hasCard" then 
				result = f(params["cardPoints"],tonumber(param))
			elseif func == "hasCards" then 
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
	if log_util.isDebug() == true then
    	print("HappyEnding.evalCondition",v1,op,"|",v2)
	end

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
	if log_util.isDebug() == true then
    	print("HappyEnding.hasCard",aiUtil.printt(cardPoints),point)
	end

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
function HappyEnding.hasCards(cardPoints,str)
	if log_util.isDebug() == true then
    	print("HappyEnding.hasCards",aiUtil.printt(cardPoints))
	end

	--先排序
	table.sort( cardPoints, function ( v1,v2 )
        return v1 < v2
    end )
    --转化为字符串
    local allString = table.concat(cardPoints,",")
    if log_util.isDebug() == true then
        print("HappyEnding.hasCards",allString,str)
    end

    if allString == str then 
    	return true
    else
    	return false
    end
end
--判断地主手牌是否符合条件
function HappyEnding.islordCardsEqual(str)
	--从内存中取出地主的手牌
	if log_util.isDebug() == true then
    	print("HappyEnding.islordCardsEqual",str)
	end

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
    if log_util.isDebug() == true then
        print("HappyEnding.islordCardsEqual",allString,str)
    end

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
	if log_util.isDebug() == true then
    	print("HappyEnding.islordCardsHas",str)
	end

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
    if log_util.isDebug() == true then
        print("HappyEnding.islordCardsHas",allString,str,idx)
    end

    if idx ~= nil then 
    	return true
    else
    	return false
    end
end 

return HappyEnding;
--- 估值计算的工具函数
--- TODO 可能直接使用Card，取其int值进行判断
--{leftpoker=node.leftpoker,composition=composition};
-- 依赖的函数库
local func = require("ai.func")

local Evaluation={}
function Evaluation.evaluation(data)
	local value ,canBring=0 ,0;
	local hands_count=#data.composition;
	-- local singleValue={0,0,0,-30,-25,-24,-23,-20,-18,-16,-10,-7,-6,-3,-1,0,10,0,15,35};
	local singleValue={0,0,-30,-25,-24,-23,-20,-18,-16,-10,-7,-6,-3,-1,10,15,35,0,0,0};
	for i,v in ipairs(singleValue) do
		singleValue[i] = v*4
	end
	local pairValue={0,0,-30,-25,-24,-22,-18,-16,-12,-6,0,5,10,15,30,0,0,0,0};

	local k_hand_count=10;
	local boomCount = 0
	func.each(data.composition,function(type)
	    local straightvalue=0;
	    if type.cardtype==1  then
	        local k10,k11,k12=0,2,2;
	        straightvalue=k10+k11*type.pokers[1]+k12*#type.pokers;
	        value=value+straightvalue;
	        -- print("straightvalue:",straightvalue);
	    end
	    if type.cardtype==2  then
	        local k20,k21,k22=40,5,1.8;
	        straightvalue=k20+k21*type.pokers[1]+k22*#type.pokers;
	        value=value+straightvalue;
	        -- print("double straightvalue:",straightvalue," ",type.pokers);
	    end
	    if type.cardtype==3 then 
	        canBring=canBring+1;
	        local k30,k31=-10,4;
	        straightvalue=k30+k31*type.pokers[1];
	        value=value+straightvalue;
	        --3条2额外加分
	        if type.pokers[1]==15 then
	            value=value+60;
	        end
	        -- print("三条:",straightvalue," ",type.pokers[1]);
	    end
	    if type.cardtype==4 then
	        canBring=canBring+2;
	        local k40,k41=50,1;
	        straightvalue=k40+k41*type.pokers[1];
	        value=value+straightvalue;
	        boomCount = boomCount + 1
	        -- print("double straightvalue:",straightvalue);
	    end
	end
	);
	local i =1;
	local singleCount =0 
	local doubleCount = 0
	func.each(data.leftpoker,function(num)
	    if num==1  then
	        if canBring >0  then
	            canBring=canBring-1;
	        else
	            value=value+singleValue[i];
	            hands_count=hands_count+1;
	        end
	        singleCount= singleCount+1
	        -- print("单张",num,"张",i,"value ",value);
	    end
	    if num==2 then
	        if canBring > 0 then
	            canBring=canBring-1;
	        else
	            value=value+pairValue[i];
	            hands_count=hands_count+1;
	        end
	        doubleCount =doubleCount+1
	        -- print("对子",num,"张",i,"value ",value);
	    end
	    --确保成型牌不拆得分必拆牌得分低
	    if num==3 then
	    	--保护一下初始时候未拆牌的值,应对({0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})这样的状况
	        local k30,k31=-10,-4;
	        local s=k30+k31*i;
	        value=value+s;
	        hands_count=hands_count+1;
	        -- print("三条:",straightvalue," ",type.pokers[1]);
	    end
	    if num==4 then
	    	--保护一下初始时候未拆牌的值,应对({0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,1,0,0,0})这样的状况 
	    	--所以分值必须都是负的
	    	local k40,k41=-50,-10;
	    	--还要罚分，保证其值在正常拆牌下面
	        value=value+k40+k41*i;
	        hands_count=hands_count+1;
	    end 
	    i=i+1
	end);
	if data.leftpoker[16] > 0 and data.leftpoker[17] >0 then
	    hands_count=hands_count-1;
	end
	---手数罚分
	value=value-hands_count*k_hand_count;
	-- print("evaluation 价值评估：",aiUtil.printt(data),value,"手数: ",hands_count);
	print("evaluation 价值评估：",value,"手数: ",hands_count);
	--炸弹只能够带同牌型,而且只能够带2个单，不能够只带一个单
	--特化处理下8888+3/8888+3+55这样4带2带不出去的情况
	--注意还需要排除8888+44这样的情况
	if hands_count ==1 and boomCount == 1 and singleCount ==1  then 
		print("evaluation 四带二校正");
		hands_count = 2
	end
	--特化处理AAA+大王小王这种情景
	return {value,hands_count};
end

return Evaluation
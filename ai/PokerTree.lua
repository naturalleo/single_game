-- 手牌的结构树（无状态的）
-- 依赖的函数库
require "utils/table_util"
local func = require("ai.func")
local Evaluation = require("ai.Evaluate")
local PokerTree ={}
--TODO table.foreach 可以替换func.each

--TODO 用于简化运算，提高性能
-- utilMask = {mask_four=0x0008,mask_three=0x0004,mask_double_straight=0x0002,mask_straight=0x0001}
-- 查找炸弹（最大到2）
local  function find_four(cards,start)
    if start == nil then
        start = 3;
    end
    for i=start, 15 do
	    if cards[i] == 4 then
	    	local tmp_cards= table.clone(cards);
            tmp_cards[i]=tmp_cards[i]-4;
            return {{pokers={i,i,i,i},cardtype=4},tmp_cards};
	    end
	end
    return {nil,nil};
end

-- 查找三条(最大到2)
local function find_three(cards,start)
    if start == nil then
        start = 3;
    end
    for i=start, 15 do
	    if cards[i] == 3 then
	    	local tmp_cards= table.clone(cards);
            tmp_cards[i]=tmp_cards[i]-3;
            return {{pokers={i,i,i},cardtype=3},tmp_cards};
	    end
	end
    return {nil,nil};
end

-- 查找最小的顺子（最大到A）
local function find_Min_Straight(cards,start)
    if start == nil then
        start = 3;
    end
    local j = 0
    for i=start, 14 do
        if cards[i] == 0 then
            j=0;
        else
            j=j+1
        end
    	if j==5 then
            local straight=func.range(i-4,i)
            local tmp_cards= table.clone(cards);
            if start then 
                 func.each(straight,function(i)
                    tmp_cards[i]=tmp_cards[i]-1;
                    if tmp_cards[i] < 0 then
                         print("find_Min_Straight牌张数目错误",i)
                    end
                end);
            end
            return {{pokers=straight,cardtype=1},tmp_cards};
        end
    end

   return {nil,nil};
end

-- 查找7张的顺子(因为已经处理了5张顺，那么剩余最多也就是7张的顺子？)
local function find_Seven_Straight(cards,start)
    if start == nil then
        start = 3;
    end
    local j = 0
    for i=start, 14 do
        if cards[i] == 0 then
            j=0;
        else
            j=j+1
        end
    	if j==7 then
    		local straight=func.range(i-6,i)
            local tmp_cards= table.clone(cards);
            func.each(straight,function(i)
                tmp_cards[i]=tmp_cards[i]-1;
                 if tmp_cards[i] < 0 then
                     print("find_Seven_Straight牌张数目错误",i)
                end
            end);
            return {{pokers=straight,cardtype=1},tmp_cards};
    	end
    end
    return {nil,nil};
end

-- 查找最小的双顺
local function find_Min_Double_Straight(cards,start)
    if start == nil then
        start = 3;
    end

    local j = 1
    for i=start, 14 do
    	if j==4 then
    		local straight=func.range(i-3,i-1)
            local tmp_cards= table.clone(cards);
            func.each(straight,function(i)
                tmp_cards[i]=tmp_cards[i]-2;
            end);
            table.insert(straight,straight[1])
            table.insert(straight,straight[2])
            table.insert(straight,straight[3])
            table.sort( straight, function(v1,v2) 
             return v1 < v2
            end)
            return {{pokers=straight,cardtype=2},tmp_cards};
    	end
    	if cards[i] < 2 then
            j=0;
        end
    	j=j+1	
    end
    return {nil,nil}
end

-- 延长顺子
local function extend_straight(data)
    -- {{pokers={3,4,5,6,7}},cardtype=1},{0,0,0,0,0,1,0,1,2,3,0}};
    -- print('%c 一个牌型拆法:', data.composition);
    local lastcard;
    local result=table.clone(data);
    func.each(result.composition,function(type)
        if type.cardtype==1 then
            -- print('%c 顺子:', type.pokers);
            lastcard = type.pokers[#type.pokers];
            for i=lastcard+1,14 do
            	if result.leftpoker[i]>0 then
                    result.leftpoker[i]=result.leftpoker[i]-1;
                    table.insert(type.pokers,i);
                    -- print('%c 顺子扩张了一张:',i,table.concat(type.pokers,","));
                else
                    break;
                end
            end
            local lastcard=type.pokers[#type.pokers];
            -- 从上往下判断顺子头上是否有对，有对则删除头上
            -- type.pokers[1]+4 表示最小的顺子是5张
            for j=lastcard,type.pokers[1]+5,-1 do
                 if result.leftpoker[j] >0 then
                    result.leftpoker[j]=result.leftpoker[j]+1;
                    table.remove(type.pokers,#type.pokers)
                    -- print('%c 顺子缩减了一张:', j,table.concat(type.pokers,","));
                else
                    break;
                end
            end

        elseif type.cardtype==2 then
             -- print('%c 双顺:', table.concat(type.pokers,","));
            lastcard= type.pokers[#type.pokers];
            for i=lastcard+1,14 do
                if result.leftpoker[i]==2 then
                    result.leftpoker[i]=result.leftpoker[i]-2;
                    table.insert(type.pokers,i)
                    table.insert(type.pokers,i)
                    -- print('%c 双顺子扩张了一对:', i,table.concat(type.pokers,","));
                else
                    break;
                end
            end
        end

    end);
    return result;
end


local function hand_composition(node, tree_info)
    -- table_print(node)
	-- table_print(tree_info)
	local composition = {};
	local composition_keys = 0;
	local tmp = node;
	if node.current~=nil then
	    table.insert(composition,node.current)
	end
	while tmp.parent ~= nil and tmp.parent.is_root ~= 1  do
	    table.insert(composition,table.clone(tmp.parent.current));
	    tmp = tmp.parent;
	end
    -- 排一下序，防止先放大3条或者大顺子
    table.sort( composition, function ( v1,v2 )
        -- 牌型从大到小，相同牌型从小到大
        if v1.cardtype == v2.cardtype then
            return v1.pokers[1] < v2.pokers[1]
        else
            return v1.cardtype >v2.cardtype
        end
    end )
	local data = {
	    leftpoker=node.leftpoker,
	    composition=composition
	};
    -- TODO 多了一次判断
	data=extend_straight(data);
    -- table_print(data)
	local evaluation_result=Evaluation.evaluation(data);

	table.insert(tree_info,{
	    score=evaluation_result[1],
	    data=data,
	    hands_count=evaluation_result[2]
	})
	return tmp;
end

function PokerTree.buildTree(handpoker)
    local tree={};
    -- tree.handpoker=handpoker;
    -- local counts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    -- for k,v in pairs(handpoker.noking) do
    --  counts[k] = #v;
    -- end
    tree.leftpoker=handpoker;
    tree.is_root=1;
    tree.mask=0;
    return tree;
end
function PokerTree.findChildren(tree,treeInfo)
	tree.chindren={};
    local tmptree={};

    local tmp=find_four(tree.leftpoker);
    if tmp[1]~=nil then
        tmptree.parent=tree;
        tmptree.current=tmp[1];
        tmptree.leftpoker=tmp[2];
		table.insert(tree.chindren, tmptree)
    else
        -- tree.mask=bit32.bor(tree.mask,utilMask.mask_four) 
    end

    tmp=find_three(tree.leftpoker);
    if tmp[1]~=nil then
        tmptree={};
        tmptree.parent=tree;
        tmptree.current=tmp[1];
        tmptree.leftpoker=tmp[2];
        table.insert(tree.chindren, tmptree)
    else
    	-- tree.mask=bit32.bor(tree.mask,utilMask.mask_three) 
    end



    tmp=find_Min_Straight(tree.leftpoker);
    if tmp[1]~=nil then
        tmptree={};
        tmptree.parent=tree;
        tmptree.current=tmp[1];
        tmptree.leftpoker=tmp[2];
        table.insert(tree.chindren, tmptree)
    else
    	-- tree.mask=bit32.bor(tree.mask,utilMask.mask_straight) 
    end

 	

    tmp=find_Seven_Straight(tree.leftpoker);
    if tmp[1]~=nil then
        tmptree={};
        tmptree.parent=tree;
        tmptree.current=tmp[1];
        tmptree.leftpoker=tmp[2];
        table.insert(tree.chindren, tmptree)
    else
    	-- tree.mask=bit32.bor(tree.mask,utilMask.mask_straight) 
    end


    tmp=find_Min_Double_Straight(tree.leftpoker);
    if tmp[1]~=nil then
        tmptree={};
        tmptree.parent=tree;
        tmptree.current=tmp[1];
        tmptree.leftpoker=tmp[2];
        table.insert(tree.chindren, tmptree)
    else
    	-- tree.mask=bit32.bor(tree.mask,utilMask.mask_double_straight) 
    end

	
    -- TODO 没有拆分到底可能不需要估值
    tmp = hand_composition(tree, treeInfo);
    if #tree.chindren ~= 0 then
        for k,v in pairs(tree.chindren) do        
        	-- print("child",v.current.cardtype,v.current.pokers[1])
            PokerTree.findChildren(v,treeInfo);
        end
    end

    return tree;
end	

-- 直接获取最高分值出牌
function PokerTree.get_Highest_Value_scheme(cards)
    print("PokerTree get_Highest_Value_scheme "..table.concat(cards,","))
    local tree = PokerTree.buildTree(cards);
    local tree_info = {};
    PokerTree.findChildren(tree,tree_info)

    table.sort( tree_info, function(v1,v2) 
        return v1.score > v2.score
    end)

    local first=tree_info[1];
    return first;
end 

return PokerTree
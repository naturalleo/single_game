 --Action
 -- if max_count>-1 then
    --     print("Action domino  mode",max_count)
    --     --3条，双顺，单顺小，需要炸弹带出去,没有炸弹也不一定能够出去

    -- elseif max_count >= -2 then 
    --     print("Action domino  mode",max_count)
    --     --手数过个1手。手数太多，补余价值不大（其实多2手也有可能）
    --     --找补余看看
    --     -- 3条组飞机带翅膀
    --     if left[2] < 0 then
    --         --小3条，理论上只能够
    --         --1火箭和炸弹补，但是盈余手数不过，所以这种情况没得补
    --         --2变形组成3龙
    --         local tdc,td = threeDragonTransform(min_three_cards)
    --         if tdc + max_count > -1 then 
    --              print("Action domino 3龙必胜")
    --         end
    --     end
    --     -- 剩余1对
    --     if left[5] < 0 then 
    --         -- 四带2试试
    --         --TODO 不够严密，需要4个原来罩的牌型一致
    --         if left[1] > 0 then
    --             --可以摆尾
    --             if left[1] + left[5] >-1 then 
    --                 print("Action domino 4带2对必胜")
    --             end
    --         end
    --         --TODO双顺罩，双顺中对是否大牌
    --         --TODO3条罩，3条的单牌是否大牌
    --     end
    --     -- 剩余1单
    --     if left[6] <0 then 
    --         --四带2
    --         if left[1] > 0 then
    --             --可以摆尾
    --             if left[1] + left[6] >-1 then 
    --                 print("Action domino 4带单必胜")
    --             end
    --         end
    --         --拆双王
    --         if left[7]> 0 then 
    --             if left[7] + left[6] >-1 then 
    --                 print("Action domino 拆双王必胜")
    --             end
    --         end
    --     end
    --     --TODO 都不行，就先抛一张，然后期待过牌
    -- else
    --     --TODO3龙可以减少不少手数
    -- end



--HumAi
    -- function HumAI:gametree(lastCards,handCards,seat)
--  local node_root = {parent=nil}
--  node_root.seatCards = handCards
--  node_root.children={};
--     node_root.currCard=lastCards;
--     if lastCards == nil or #lastCards == 1 then
--      lastCards ={}
--     end  
--     findchildren(node_root,lastCards,seat);
-- end

-- function findchildren(node,last,currSeat)
--  if node.parent == nil and #node.parent.currCard==0  and node.parent.parent == nil 
--      and #node.parent.parent.currCard.length==0 then
--          --todo 处理首出逻辑
--         return 
--     end
--     if last ~=nil and #last ~= 0 then
--      --- 识别需要管理的牌型
--      local lastHandsInfo = CardPattern.parseCards(last)
--      --- 提示出牌
--      --- TODO
--      local tipCardsScheme= LordLogic.findBetterCards(lastCardsObj,myCardsObj);
--       _.each(tipCardsScheme,function(scheme) 
--          local tmp_scheme= _.map(scheme,function(el)
--                  return el.absoluteValue;
--              end
--             )
--             local tmp_node=node;
--             --- TODO
--             tmp_node.seatCards=Util.deepclone(tmp_node.seatCards);
--             tmp_node.seatCards[currSeat]=_.difference(tmp_node.seatCards[currSeat],tmp_scheme);

--             tmp_node.children={};
--             tmp_node.parent=node;
--             tmp_node.currCard=scheme;
--             local  nextSeat= currSeat==2 and 0 or currSeat+1;
--             local  currCard= #scheme > 0  and scheme or last;
--             if #tmp_node.seatCards[currSeat] > 0 then
            
--                 findchildren(tmp_node,currCard,nextSeat);
--             else
--                 tmp_node.isEnd=true;
--             end
--             node.children.push(tmp_node);    

--          end
--       )
--     end
-- end


Action
 --余3手，还是有可能必胜
        -- if totalMin >= -3 then
        --     --TODO 有时间再计算更智能的拆牌
        --     --3条、双顺、顺子余必须用炸弹
        --     --对子余
        --     --单张余
        --     --1顺过是不错的选择
        --     --2出余手牌
        --     local result = nil
        --     if lastHandsInfo then
        --        result = find_bigger_in_domino(domino,left,lastHandsInfo) 
        --     else
        --        result = find_smaller_in_domino(domino,left)
        --     end
        --     print("Action domino -3 return",vardump(result))
        --     return result
        -- end
        --综合手数太差，可能自己无法获胜，转考虑让友军获胜或者对手难受
        -- if lastHandsInfo then
        --     --2.1次发的话，上手牌是地主，（TODO并且自己是地主下家）如果有顶先盖住，然后发友军强势牌
        --     --2.2次发的话，上手牌是队友，不妨pass
        --     local lastSeat = getLastSeatFromMonkey();
        --     if lastSeat == lordSeat and currSeat ~= lordSeat then
        --         result = find_max_in_domino(domino,left,lastHandsInfo) 
        --     else
        --         --返回空表，防止走剩余的逻辑
        --         --TODO如果能够顺过一手小牌也是好的
        --         result = {} 
        --     end
        --     print("Action domino -3 return",vardump(result))
        --     return result
        -- else
        --     --1首发的话，发友军的强势牌
        --     if currSeat ~= lordSeat then
        --         result = find_team_bigger_in_domino(domino,left,currSeat,lordSeat)
        --     end
        --     print("Action domino -3 return",vardump(result))
        --     return result
        -- end



         if left[5] < 0 or left[6] < 0 then 
            local tmp = 0;
            if left[5] < 0 then 
                tmp = singe_double_max_count + left[5]
                if tmp > 0 then 
                    if left[6] <0 then 
                        tmp = tmp + left[6]
                        if tmp >= 0 then 
                            -- 单双全部可以带出去
                            totalMin = totalMin -(left[5]+left[6])
                        else
                            --双牌带全，但是单牌带不完
                            totalMin = totalMin + singe_double_max_count
                        end
                    else
                        -- 只用带双牌
                        totalMin = totalMin -left[5]
                    end
                    
                else
                    --双牌带不全
                    totalMin = totalMin + singe_double_max_count
                end
            else
                if left[6] <0 then 
                    tmp = singe_double_max_count + left[6]
                    if tmp > 0 then 
                        -- 单全部可以带出去
                        totalMin = totalMin -left[6]
                    else
                        -- 单牌带不全
                        totalMin = totalMin + singe_double_max_count
                    end
                end
            end
        end
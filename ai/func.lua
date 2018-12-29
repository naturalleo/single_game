--AI的函数库
-- local _ = require ("ai.underscore")
require "utils/table_util"
local Card = require("logic.Card")
local func = {}
-- 中介函数
function func.each(orig,func)
  -- return _.each(orig,func);
  for k, v in pairs(orig) do
    func(v)
  end
end
function func.range(v1,v2)
  -- return _.range(v1,v2):to_array()
  local result = {}
  for i=v1,v2 do
    table.insert(result,i)
  end
  return result
end
-- 转换为斗地主牌面值3~17
function func.cardsPoint(cardsArr)
    local cards = table.clone(cardsArr);
    -- 转为数值
    for k, v in pairs(cards) do
      cards[k] = func.cardValue(v);
    end 
    return cards;
end
-- 解析和命名牌值
function func.cardValue(num)
    -- 0-53的构造方式
    local point ;
    if(num==52) then
        point = 16;
    elseif(num==53) then
        point = 17;
    else
        point = num % 13 + 3
    end
  return point
end
-- int值转化为Card对象
function func.cardsObj(cardsArr)
    local cardsObj = {};
    for i=1,#cardsArr do
        local card = Card.new(cardsArr[i])
        table.insert(cardsObj,card)
    end
    return cardsObj
end
-- 几成概率
-- TODO 也许需要累积概率
function func.randomChance(chance)
  math.randomseed(tostring(os.time()):reverse():sub(1, 6)) 
  local flag = 0
  for i=1,100 do
      flag   = math.random(1, 10)
  end
  if flag <= chance then 
      return true
  else
      return false
  end 
end 
return func 
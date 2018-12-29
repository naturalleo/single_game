require "utils/functions"
local CardsInfo = class("CardsInfo")

function CardsInfo:ctor()
  self.type = 0
  self.value = 0
  self.length = 0
  self.bomb = false
end

function CardsInfo:ctor(_type, _value, _length, _bomb)
  self.type = _type
  self.value = _value
  self.length = _length
  self.bomb = _bomb
  self.cardPattern = require("logic.CardPattern")
end

function CardsInfo:isDragon()
  return self.type >= self.cardPattern.SINGLE_DRAGON
end

function CardsInfo:isDoubleDragon()
  return self.type == self.cardPattern.DOUBLE_DRAGON
end

function CardsInfo:isSingleDragon()
  return self.type == self.cardPattern.SINGLE_DRAGON
end

-- 通天顺
function CardsInfo:isTopSingleDragon()
  return (self.type == self.cardPattern.SINGLE_DRAGON) and (self.value == CardPoint.POINT_A)
end

function CardsInfo:isTripleDragon()
  return self.type == self.cardPattern.THREE_DRAGON or self.type == self.cardPattern.THREE_ONE_DRAGON or self.type == self.cardPattern.THREE_TWO_DRAGON
end

function CardsInfo:isDoubleJoker()
  return self.type == self.cardPattern.DOUBLE_JOKER
end

function CardsInfo:greatThan(cardsInfo)
  if self.type == self.cardPattern.DOUBLE_JOKER then
    return true
  end

  if self.bomb then
    if cardsInfo.bomb then
      if cardsInfo.type == self.cardPattern.DOUBLE_JOKER then
        return false
      else
        return self.value > cardsInfo.value
      end
    end
    return true
  end

  if self.type == cardsInfo.type then
    if self.isDragon(self) then
      if self.length ~= cardsInfo.length then
        return false
      end
    end
    return self.value > cardsInfo.value
  end
  return false
end

return CardsInfo
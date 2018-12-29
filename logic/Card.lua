--/**
-- * 服务器下发的牌值[m_nOriginal]从 0~53，按花色+大小排序，Card 类转换为 value 和 color，规则如下：
-- *  m_nOriginal == 52: 小王
-- *    m_nColor = COLOR_JOKER
-- *    m_nValue = CARD_POINT_SMALL_JOKER
-- *  m_nOriginal == 53：大王
-- *    m_nColor = COLOR_JOKER
-- *    m_nValue = CARD_POINT_BIG_JOKER
-- *  0 <= m_nOriginal <= 51:
-- *    m_nColor = m_nOriginal / 13
-- *    m_nValue = m_nOriginal % 13 + 3
-- */
require "utils/functions"
local log_util = require("utils.log_util")
local Card = class("Card")

CardColor={
            COLOR_DIAMOND = 0, --方块
            COLOR_CLUB = 1, --梅花
            COLOR_HEART=2, --红桃
            COLOR_SPADE=3, --黑桃
            COLOR_JOKER=4, --王
            COLOR_SPECIAL = 11,--赖子，特殊牌
}

local LORDHL_CARD_COLOR_HEART = 0 -- 红桃
local LORDHL_CARD_COLOR_DIAMOND = 1 -- 方块
local LORDHL_CARD_COLOR_SPADE = 2 -- 黑桃
local LORDHL_CARD_COLOR_CLUB = 3 -- 梅花
local LORDHL_CARD_COLOR_JOKER = 4 -- 王
--[[--
    欢乐牌花色转为标准牌花色
]]
function CardColor.fromHLCardColor(color)
    if color == LORDHL_CARD_COLOR_HEART then
        color = CardColor.COLOR_HEART
    elseif color == LORDHL_CARD_COLOR_DIAMOND then
        color = CardColor.COLOR_DIAMOND
    elseif color == LORDHL_CARD_COLOR_SPADE then
        color = CardColor.COLOR_SPADE
    elseif color == LORDHL_CARD_COLOR_CLUB then
        color = CardColor.COLOR_CLUB
    end
    return color
end

--[[--
    标准牌花色转为欢乐牌花色
]]
function CardColor.toHLCardColor(color)
    if (color == CardColor.COLOR_DIAMOND) then
        color = LORDHL_CARD_COLOR_DIAMOND
    elseif color == CardColor.COLOR_CLUB then
        color = LORDHL_CARD_COLOR_CLUB
    elseif color == CardColor.COLOR_HEART then
        color = LORDHL_CARD_COLOR_HEART
    elseif color == CardColor.COLOR_SPADE then
        color = LORDHL_CARD_COLOR_SPADE
    end
    return color
end


local LORDFOUR_CARD_COLOR_HEART = 1 -- 红桃
local LORDFOUR_CARD_COLOR_DIAMOND = 2 -- 方块
local LORDFOUR_CARD_COLOR_SPADE = 3 -- 黑桃
local LORDFOUR_CARD_COLOR_CLUB = 4 -- 梅花
local LORDFOUR_CARD_COLOR_JOKER = 5 -- 王

--[[--
    四斗牌花色转为标准牌花色
]]
function CardColor.fromFourCardColor(color)
    if color == LORDFOUR_CARD_COLOR_HEART then
        color = CardColor.COLOR_HEART
    elseif color == LORDFOUR_CARD_COLOR_DIAMOND then
        color = CardColor.COLOR_DIAMOND
    elseif color == LORDFOUR_CARD_COLOR_SPADE then
        color = CardColor.COLOR_SPADE
    elseif color == LORDFOUR_CARD_COLOR_CLUB then
        color = CardColor.COLOR_CLUB
    end
    return color
end

--[[--
    标准牌花色转为四斗牌花色
]]
function CardColor.toFourCardColor(color)
    if (color == CardColor.COLOR_DIAMOND) then
        color = LORDFOUR_CARD_COLOR_DIAMOND
    elseif color == CardColor.COLOR_CLUB then
        color = LORDFOUR_CARD_COLOR_CLUB
    elseif color == CardColor.COLOR_HEART then
        color = LORDFOUR_CARD_COLOR_HEART
    elseif color == CardColor.COLOR_SPADE then
        color = LORDFOUR_CARD_COLOR_SPADE
    end
    return color
end



CardPoint={
        POINT_3 = 3,
        POINT_4 = 4,
        POINT_5 = 5,
        POINT_6 = 6,
        POINT_7 = 7,
        POINT_8 = 8,
        POINT_9 = 9,
        POINT_10 = 10,
        POINT_J = 11,
        POINT_Q = 12,
        POINT_K = 13,
        POINT_A = 14,
        POINT_2 = 15,
        POINT_SMALL_JOKER = 16,
        POINT_BIG_JOKER = 17,

        POINT_SPECIAL = 110,
}        

local cardsResArr_normal = {
    [CardColor.COLOR_DIAMOND] = {
        [CardPoint.POINT_3] = "img/lordsinglexhcg/game/card/lord_card_diamond_3.png", 
        [CardPoint.POINT_4] = "img/lordsinglexhcg/game/card/lord_card_diamond_4.png", 
        [CardPoint.POINT_5] = "img/lordsinglexhcg/game/card/lord_card_diamond_5.png", 
        [CardPoint.POINT_6] = "img/lordsinglexhcg/game/card/lord_card_diamond_6.png",
        [CardPoint.POINT_7] = "img/lordsinglexhcg/game/card/lord_card_diamond_7.png", 
        [CardPoint.POINT_8] = "img/lordsinglexhcg/game/card/lord_card_diamond_8.png", 
        [CardPoint.POINT_9] = "img/lordsinglexhcg/game/card/lord_card_diamond_9.png", 
        [CardPoint.POINT_10] = "img/lordsinglexhcg/game/card/lord_card_diamond_10.png",
        [CardPoint.POINT_J] = "img/lordsinglexhcg/game/card/lord_card_diamond_j.png", 
        [CardPoint.POINT_Q] = "img/lordsinglexhcg/game/card/lord_card_diamond_q.png", 
        [CardPoint.POINT_K] = "img/lordsinglexhcg/game/card/lord_card_diamond_k.png", 
        [CardPoint.POINT_A] = "img/lordsinglexhcg/game/card/lord_card_diamond_1.png",
        [CardPoint.POINT_2] = "img/lordsinglexhcg/game/card/lord_card_diamond_2.png",
    },

    [CardColor.COLOR_CLUB] = {
        [CardPoint.POINT_3] = "img/lordsinglexhcg/game/card/lord_card_club_3.png", 
        [CardPoint.POINT_4] = "img/lordsinglexhcg/game/card/lord_card_club_4.png", 
        [CardPoint.POINT_5] = "img/lordsinglexhcg/game/card/lord_card_club_5.png", 
        [CardPoint.POINT_6] = "img/lordsinglexhcg/game/card/lord_card_club_6.png",
        [CardPoint.POINT_7] = "img/lordsinglexhcg/game/card/lord_card_club_7.png", 
        [CardPoint.POINT_8] = "img/lordsinglexhcg/game/card/lord_card_club_8.png", 
        [CardPoint.POINT_9] = "img/lordsinglexhcg/game/card/lord_card_club_9.png", 
        [CardPoint.POINT_10] = "img/lordsinglexhcg/game/card/lord_card_club_10.png",
        [CardPoint.POINT_J] = "img/lordsinglexhcg/game/card/lord_card_club_j.png", 
        [CardPoint.POINT_Q] = "img/lordsinglexhcg/game/card/lord_card_club_q.png", 
        [CardPoint.POINT_K] = "img/lordsinglexhcg/game/card/lord_card_club_k.png", 
        [CardPoint.POINT_A] = "img/lordsinglexhcg/game/card/lord_card_club_1.png",
        [CardPoint.POINT_2] = "img/lordsinglexhcg/game/card/lord_card_club_2.png",
    },

    [CardColor.COLOR_HEART] = {
        [CardPoint.POINT_3] = "img/lordsinglexhcg/game/card/lord_card_heart_3.png", 
        [CardPoint.POINT_4] = "img/lordsinglexhcg/game/card/lord_card_heart_4.png", 
        [CardPoint.POINT_5] = "img/lordsinglexhcg/game/card/lord_card_heart_5.png", 
        [CardPoint.POINT_6] = "img/lordsinglexhcg/game/card/lord_card_heart_6.png",
        [CardPoint.POINT_7] = "img/lordsinglexhcg/game/card/lord_card_heart_7.png", 
        [CardPoint.POINT_8] = "img/lordsinglexhcg/game/card/lord_card_heart_8.png", 
        [CardPoint.POINT_9] = "img/lordsinglexhcg/game/card/lord_card_heart_9.png", 
        [CardPoint.POINT_10] = "img/lordsinglexhcg/game/card/lord_card_heart_10.png",
        [CardPoint.POINT_J] = "img/lordsinglexhcg/game/card/lord_card_heart_j.png", 
        [CardPoint.POINT_Q] = "img/lordsinglexhcg/game/card/lord_card_heart_q.png", 
        [CardPoint.POINT_K] = "img/lordsinglexhcg/game/card/lord_card_heart_k.png", 
        [CardPoint.POINT_A] = "img/lordsinglexhcg/game/card/lord_card_heart_1.png",
        [CardPoint.POINT_2] = "img/lordsinglexhcg/game/card/lord_card_heart_2.png",
    },

    [CardColor.COLOR_SPADE] = {
        [CardPoint.POINT_3] = "img/lordsinglexhcg/game/card/lord_card_spade_3.png", 
        [CardPoint.POINT_4] = "img/lordsinglexhcg/game/card/lord_card_spade_4.png", 
        [CardPoint.POINT_5] = "img/lordsinglexhcg/game/card/lord_card_spade_5.png", 
        [CardPoint.POINT_6] = "img/lordsinglexhcg/game/card/lord_card_spade_6.png",
        [CardPoint.POINT_7] = "img/lordsinglexhcg/game/card/lord_card_spade_7.png", 
        [CardPoint.POINT_8] = "img/lordsinglexhcg/game/card/lord_card_spade_8.png", 
        [CardPoint.POINT_9] = "img/lordsinglexhcg/game/card/lord_card_spade_9.png", 
        [CardPoint.POINT_10] = "img/lordsinglexhcg/game/card/lord_card_spade_10.png",
        [CardPoint.POINT_J] = "img/lordsinglexhcg/game/card/lord_card_spade_j.png", 
        [CardPoint.POINT_Q] = "img/lordsinglexhcg/game/card/lord_card_spade_q.png", 
        [CardPoint.POINT_K] = "img/lordsinglexhcg/game/card/lord_card_spade_k.png", 
        [CardPoint.POINT_A] = "img/lordsinglexhcg/game/card/lord_card_spade_1.png",
        [CardPoint.POINT_2] = "img/lordsinglexhcg/game/card/lord_card_spade_2.png",
    },

    [CardColor.COLOR_JOKER] = {
            [CardPoint.POINT_SMALL_JOKER] = "img/lordsinglexhcg/game/card/lord_card_joker_small_big.png",
            [CardPoint.POINT_BIG_JOKER] = "img/lordsinglexhcg/game/card/lord_card_joker_big_big.png",
    },

    [CardColor.COLOR_SPECIAL] = {
        [CardPoint.POINT_SPECIAL] = "img/lordsinglexhcg/game/card/lord_card_backface_big.png",
    }
}

local cardsResArr_small = {
    [CardColor.COLOR_DIAMOND] = {
        [CardPoint.POINT_3] = "img/lordsinglexhcg/game/card/lord_card_diamond_3_small.png", 
        [CardPoint.POINT_4] = "img/lordsinglexhcg/game/card/lord_card_diamond_4_small.png", 
        [CardPoint.POINT_5] = "img/lordsinglexhcg/game/card/lord_card_diamond_5_small.png", 
        [CardPoint.POINT_6] = "img/lordsinglexhcg/game/card/lord_card_diamond_6_small.png",
        [CardPoint.POINT_7] = "img/lordsinglexhcg/game/card/lord_card_diamond_7_small.png", 
        [CardPoint.POINT_8] = "img/lordsinglexhcg/game/card/lord_card_diamond_8_small.png", 
        [CardPoint.POINT_9] = "img/lordsinglexhcg/game/card/lord_card_diamond_9_small.png", 
        [CardPoint.POINT_10] = "img/lordsinglexhcg/game/card/lord_card_diamond_10_small.png",
        [CardPoint.POINT_J] = "img/lordsinglexhcg/game/card/lord_card_diamond_j_small.png", 
        [CardPoint.POINT_Q] = "img/lordsinglexhcg/game/card/lord_card_diamond_q_small.png", 
        [CardPoint.POINT_K] = "img/lordsinglexhcg/game/card/lord_card_diamond_k_small.png", 
        [CardPoint.POINT_A] = "img/lordsinglexhcg/game/card/lord_card_diamond_1_small.png",
        [CardPoint.POINT_2] = "img/lordsinglexhcg/game/card/lord_card_diamond_2_small.png",
    },

    [CardColor.COLOR_CLUB] = {
       [CardPoint.POINT_3] = "img/lordsinglexhcg/game/card/lord_card_club_3_small.png", 
        [CardPoint.POINT_4] = "img/lordsinglexhcg/game/card/lord_card_club_4_small.png", 
        [CardPoint.POINT_5] = "img/lordsinglexhcg/game/card/lord_card_club_5_small.png", 
        [CardPoint.POINT_6] = "img/lordsinglexhcg/game/card/lord_card_club_6_small.png",
        [CardPoint.POINT_7] = "img/lordsinglexhcg/game/card/lord_card_club_7_small.png", 
        [CardPoint.POINT_8] = "img/lordsinglexhcg/game/card/lord_card_club_8_small.png", 
        [CardPoint.POINT_9] = "img/lordsinglexhcg/game/card/lord_card_club_9_small.png", 
        [CardPoint.POINT_10] = "img/lordsinglexhcg/game/card/lord_card_club_10_small.png",
        [CardPoint.POINT_J] = "img/lordsinglexhcg/game/card/lord_card_club_j_small.png", 
        [CardPoint.POINT_Q] = "img/lordsinglexhcg/game/card/lord_card_club_q_small.png", 
        [CardPoint.POINT_K] = "img/lordsinglexhcg/game/card/lord_card_club_k_small.png", 
        [CardPoint.POINT_A] = "img/lordsinglexhcg/game/card/lord_card_club_1_small.png",
        [CardPoint.POINT_2] = "img/lordsinglexhcg/game/card/lord_card_club_2_small.png",
    },

    [CardColor.COLOR_HEART] = {
        [CardPoint.POINT_3] = "img/lordsinglexhcg/game/card/lord_card_heart_3_small.png", 
        [CardPoint.POINT_4] = "img/lordsinglexhcg/game/card/lord_card_heart_4_small.png", 
        [CardPoint.POINT_5] = "img/lordsinglexhcg/game/card/lord_card_heart_5_small.png", 
        [CardPoint.POINT_6] = "img/lordsinglexhcg/game/card/lord_card_heart_6_small.png",
        [CardPoint.POINT_7] = "img/lordsinglexhcg/game/card/lord_card_heart_7_small.png", 
        [CardPoint.POINT_8] = "img/lordsinglexhcg/game/card/lord_card_heart_8_small.png", 
        [CardPoint.POINT_9] = "img/lordsinglexhcg/game/card/lord_card_heart_9_small.png", 
        [CardPoint.POINT_10] = "img/lordsinglexhcg/game/card/lord_card_heart_10_small.png",
        [CardPoint.POINT_J] = "img/lordsinglexhcg/game/card/lord_card_heart_j_small.png", 
        [CardPoint.POINT_Q] = "img/lordsinglexhcg/game/card/lord_card_heart_q_small.png", 
        [CardPoint.POINT_K] = "img/lordsinglexhcg/game/card/lord_card_heart_k_small.png", 
        [CardPoint.POINT_A] = "img/lordsinglexhcg/game/card/lord_card_heart_1_small.png",
        [CardPoint.POINT_2] = "img/lordsinglexhcg/game/card/lord_card_heart_2_small.png",
    },

    [CardColor.COLOR_SPADE] = {
        [CardPoint.POINT_3] = "img/lordsinglexhcg/game/card/lord_card_spade_3_small.png", 
        [CardPoint.POINT_4] = "img/lordsinglexhcg/game/card/lord_card_spade_4_small.png", 
        [CardPoint.POINT_5] = "img/lordsinglexhcg/game/card/lord_card_spade_5_small.png", 
        [CardPoint.POINT_6] = "img/lordsinglexhcg/game/card/lord_card_spade_6_small.png",
        [CardPoint.POINT_7] = "img/lordsinglexhcg/game/card/lord_card_spade_7_small.png", 
        [CardPoint.POINT_8] = "img/lordsinglexhcg/game/card/lord_card_spade_8_small.png", 
        [CardPoint.POINT_9] = "img/lordsinglexhcg/game/card/lord_card_spade_9_small.png", 
        [CardPoint.POINT_10] = "img/lordsinglexhcg/game/card/lord_card_spade_10_small.png",
        [CardPoint.POINT_J] = "img/lordsinglexhcg/game/card/lord_card_spade_j_small.png", 
        [CardPoint.POINT_Q] = "img/lordsinglexhcg/game/card/lord_card_spade_q_small.png", 
        [CardPoint.POINT_K] = "img/lordsinglexhcg/game/card/lord_card_spade_k_small.png", 
        [CardPoint.POINT_A] = "img/lordsinglexhcg/game/card/lord_card_spade_1_small.png",
        [CardPoint.POINT_2] = "img/lordsinglexhcg/game/card/lord_card_spade_2_small.png",
    },

    [CardColor.COLOR_JOKER] = {
            [CardPoint.POINT_SMALL_JOKER] = "img/lordsinglexhcg/game/card/lord_card_joker_small_small.png",
            [CardPoint.POINT_BIG_JOKER] = "img/lordsinglexhcg/game/card/lord_card_joker_big_small.png",
    },

    [CardColor.COLOR_SPECIAL] = {
        [CardPoint.POINT_SPECIAL] = "img/lordsinglexhcg/game/card/lord_card_backface_small.png",
    },
}


function Card:ctor(orgVal)
    self.upper = false
    self.selected = false
    self.isBottomCard = false

    self.original = 0
    self.color = 0
    self.value = 0
    self.index = 0

    self.cardx = 0 -- card在屏幕上的X坐标
    self.cardy = 0 -- card在屏幕上的Y坐标

    if orgVal then
        self:setOrginal(orgVal)
    end
    --[[
    log_util.i("linxh", "card new orgval=", orgVal, 
                      ",color=", self.color, ", value=", self.value)
    ]]
end

function Card:setOrginal(nOriginal)
    self.original = nOriginal
    if nOriginal == 52 then
        self.color = CardColor.COLOR_JOKER
        self.value = CardPoint.POINT_SMALL_JOKER
    elseif nOriginal == 53 then
        self.color = CardColor.COLOR_JOKER
        self.value = CardPoint.POINT_BIG_JOKER
    elseif nOriginal == CardPoint.POINT_SPECIAL then
        self.color = CardColor.COLOR_SPECIAL
        self.value = CardPoint.POINT_SPECIAL
    else
        self.color = math.modf(nOriginal / 13)
        self.value = nOriginal % 13 + 3
    end
end

--[[--
    for test
]]
function Card.make(color, value)
    local orgVal = 0
    if color == CardColor.COLOR_JOKER then
        if value == CardPoint.POINT_SMALL_JOKER then 
            orgVal = 52
        else
            orgVal = 53
        end
    elseif color == CardColor.COLOR_SPECIAL then
        orgVal = CardPoint.POINT_SPECIAL
    else
        orgVal = color*13 + value - 3
    end
    --log_util.i("linxh", "card make, orgVal=", orgVal, ", color=", color, ", val=", value)
    return Card.new(orgVal)
end

function Card:getCardImg()
    local img = cardsResArr_normal[self.color][self.value]
    if type(img) ~= "string" then
        log_util.i("linxh", "Card:getCardImg", self.color, self.value, ", img=", img)
        log_util.i("linxh", "Card:getCardImg, cards=", self:toString())
        log_util.i("linxh", vardump(self, "card self"))
        log_util.i("linxh", vardump(cardsResArr_normal[self.color], "card color string"))
        log_util.i("linxh", vardump(cardsResArr_normal, "card string"))
        if type(img) == "table" then 
            log_util.i("linxh", vardump(img, "card getimg"))
        end
    end
    return img
end

function Card:getSmallCardImg()
    local img = cardsResArr_small[self.color][self.value]
    if type(img) ~= "string" then
        log_util.i("linxh", "Card:getSmallCardImg", self.color, self.value, ", img=", img)
        log_util.i("linxh", "Card:getSmallCardImg, cards=", self:toString())
        log_util.i("linxh", vardump(self, "card self"))
        log_util.i("linxh", vardump(cardsResArr_normal[self.color], "card color string"))
        log_util.i("linxh", vardump(cardsResArr_normal, "card string"))
        if type(img) == "table" then 
            log_util.i("linxh", vardump(img, "card getimg"))
        end
    end
    return img
end

function Card:equals(other)
    local ret = (self == other)
    if not ret then
        ret = ((self.color == other.color) and (self.value == other.value))
    end
    return ret
end

--[[--
    这个函数比较特殊，用于在添加牌时进行比较
]]
function Card:addEquals(other)
    return self:equals(other)
end

function Card:compareTo(other)
    local ret = self.value - other.value
    if ret == 0 then
        ret = self.color - other.color
    end
    ret = ((ret > 0) and true) or false
    return ret
end

local cardsStr = {
    [CardColor.COLOR_DIAMOND] = {
        [CardPoint.POINT_3] = "d3", [CardPoint.POINT_4] = "d4",   [CardPoint.POINT_5] = "d5", 
        [CardPoint.POINT_6] = "d6", [CardPoint.POINT_7] = "d7",   [CardPoint.POINT_8] = "d8", 
        [CardPoint.POINT_9] = "d9", [CardPoint.POINT_10] = "d10", [CardPoint.POINT_J] = "dj", 
        [CardPoint.POINT_Q] = "dq", [CardPoint.POINT_K] = "dk",   [CardPoint.POINT_A] = "d1",
        [CardPoint.POINT_2] = "d2",
    },

    [CardColor.COLOR_CLUB] = {
        [CardPoint.POINT_3] = "c3", [CardPoint.POINT_4] = "c4",   [CardPoint.POINT_5] = "c5", 
        [CardPoint.POINT_6] = "c6", [CardPoint.POINT_7] = "c7",   [CardPoint.POINT_8] = "c8", 
        [CardPoint.POINT_9] = "c9", [CardPoint.POINT_10] = "c10", [CardPoint.POINT_J] = "cj", 
        [CardPoint.POINT_Q] = "cq", [CardPoint.POINT_K] = "ck",   [CardPoint.POINT_A] = "c1",
        [CardPoint.POINT_2] = "c2",
    },

    [CardColor.COLOR_HEART] = {
        [CardPoint.POINT_3] = "h3", [CardPoint.POINT_4] = "h4",   [CardPoint.POINT_5] = "h5", 
        [CardPoint.POINT_6] = "h6", [CardPoint.POINT_7] = "h7",   [CardPoint.POINT_8] = "h8", 
        [CardPoint.POINT_9] = "h9", [CardPoint.POINT_10] = "h10", [CardPoint.POINT_J] = "hj", 
        [CardPoint.POINT_Q] = "hq", [CardPoint.POINT_K] = "hk",   [CardPoint.POINT_A] = "h1",
        [CardPoint.POINT_2] = "h2",
    },

    [CardColor.COLOR_SPADE] = {
        [CardPoint.POINT_3] = "s3", [CardPoint.POINT_4] = "s4",   [CardPoint.POINT_5] = "s5", 
        [CardPoint.POINT_6] = "s6", [CardPoint.POINT_7] = "s7",   [CardPoint.POINT_8] = "s8", 
        [CardPoint.POINT_9] = "s9", [CardPoint.POINT_10] = "s10", [CardPoint.POINT_J] = "sj", 
        [CardPoint.POINT_Q] = "sq", [CardPoint.POINT_K] = "sk",   [CardPoint.POINT_A] = "s1",
        [CardPoint.POINT_2] = "s2",
    },

    [CardColor.COLOR_JOKER] = {
        [CardPoint.POINT_SMALL_JOKER] = "small joker", [CardPoint.POINT_BIG_JOKER] = "big joker",
    },

    [CardColor.COLOR_SPECIAL] = {
        [CardPoint.POINT_SPECIAL] = "special",
    },
}

function Card:toString()
    if cardsStr[self.color] and cardsStr[self.color][self.value] then
        return cardsStr[self.color][self.value]
    else
        return "invaid card(c=" .. self.color .. ", v=" .. self.value .. ")"
    end
end


return Card